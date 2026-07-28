# ADR-0011: UI Timer/Expiry Management Pattern

## Status
Accepted (2026-07-11 — per architecture-review-2026-07-11 recommendation; user-delegated decision. Not spike-gated and no dependency on a spike-gated ADR.)

## Date
2026-07-11

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7-stable |
| **Domain** | UI / Core (Timer/Tween pause semantics) |
| **Knowledge Risk** | MEDIUM — no dedicated engine-reference module for this specific question |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirmed via `godot-specialist` validation (2026-07-11) — Timer.paused/Tween.pause() semantics and the manual-process-drive pattern all verified accurate for 4.7, unchanged 4.4→4.7. See Engine Specialist Validation note in Consequences. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (reuses the Suspended-signal pattern already established by ADR-0001/ADR-0005, but doesn't require either to be Accepted first) |
| **Enables** | Building UI `/dev-story` implementation, specifically its toast/anchor grace, debounce, and invalid-cue timing logic |
| **Blocks** | Building UI's timer-dependent code paths |
| **Ordering Note** | None |

## Context

### Problem Statement
`building-ui.md` requires several kinds of UI-local wall-clock timers (first-appearance grace per subject, per-key dismissal debounce, invalid-cue auto-fade) that must: run independent of game pause (Building UI is pause-immune by its own established contract), pause and resume-with-remaining-time only on the Suspended scene-transition state (never on ordinary pause, and decoupled from a Control's visibility — hiding a Control does not pause a Godot `Timer`/`Tween`), and scale to potentially dozens of simultaneously active timers as warnings/toasts accumulate. TR-building-ui-040 explicitly defers the architecture choice — centralized expiry-timestamp manager vs. N per-issue Godot `Timer` nodes — to this ADR.

### Constraints
- Building UI updates on raw (unscaled) delta, pause-immune (TR-building-ui-005, an already-established contract) — these timers must be equally pause-immune
- Suspended-pause is an explicit, signal-tied concern, decoupled from Control visibility (TR-building-ui-015) — hiding the HUD does not automatically pause anything
- Potentially dozens of simultaneous timers at scale (one grace timer per active warning subject, one debounce window per recently-dismissed key, plus invalid-cue fades)
- Time & Tick System's own GDD already states a directly relevant precedent: "a single global broadcast shared by all subscribers — no per-consumer timers anywhere" (TR-time-tick-system-007)

### Requirements
- All timer kinds (grace, debounce, invalid-cue) must run on raw delta, unaffected by game pause
- Pausing on Suspended must preserve exact remaining time and resume from it — no drift, no reset
- The mechanism must not require O(N) Node instantiation/destruction churn as toasts appear and disappear at potentially high turnover
- Consistent with this project's already-stated preference for shared clock-checking over per-consumer timer proliferation

## Decision

**A centralized expiry-timestamp manager — a `Dictionary[key, TimerRecord]` plus one shared `_process(delta)` loop — not N per-issue Godot `Timer` nodes. Pausing on Suspended is a single guard flag on the shared loop; resuming is automatic since remaining time was never touched while suspended.**

**1. Centralized manager, not per-instance Timer nodes.** `UITimerManager` (a plain class Building UI owns and instantiates, not a new Autoload or architecture-level module) maintains one dictionary of active timer records, keyed by whatever identity the caller supplies (a subject id for grace timers, a dismissal key for debounce windows, a single fixed key for the invalid-cue fade):
```gdscript
class_name UITimerManager

class TimerRecord:
    var remaining: float
    var callback: Callable

var _records: Dictionary[StringName, TimerRecord] = {}
var _suspended: bool = false

func start_timer(key: StringName, duration: float, on_expire: Callable) -> void:
    _records[key] = TimerRecord.new()
    _records[key].remaining = duration
    _records[key].callback = on_expire

func cancel_timer(key: StringName) -> void:
    _records.erase(key)

func has_timer(key: StringName) -> bool:
    return _records.has(key)

func get_remaining(key: StringName) -> float:
    return _records[key].remaining if _records.has(key) else 0.0

func _process(delta: float) -> void:
    if _suspended:
        return  # the guard IS the pause — remaining stays untouched
    var expired: Array[StringName] = []
    for key in _records:
        _records[key].remaining -= delta  # raw delta — pause-immune by construction
        if _records[key].remaining <= 0.0:
            expired.append(key)
    for key in expired:
        var callback: Callable = _records[key].callback
        _records.erase(key)
        callback.call()  # e.g. re-query Build Validation's current state, per TR-014

func on_suspended_begin() -> void:
    _suspended = true   # remaining values simply stop being touched — no per-record action

func on_suspended_end() -> void:
    _suspended = false  # decrementing resumes from whatever remaining already held
```

**2. This is a direct application of an already-accepted project precedent**, not a new pattern invented for this ADR: Time & Tick System's own GDD explicitly favors one shared broadcast over N per-consumer timers (TR-time-tick-system-007). This ADR applies the identical reasoning to Building UI's presentation-layer timers.

**3. Pausing is free — no per-timer bookkeeping.** Because the manager only decrements `remaining` inside its own `_process`, gating the WHOLE loop with one `_suspended` boolean is equivalent to pausing every active record simultaneously, with exact remaining-time preservation, at zero additional cost — there is no separate "capture remaining time on pause, restore on resume" step to get wrong, because the value was never touched while paused in the first place.

**4. Visual fade animations (e.g., the invalid-cue's fade-out) may still use a `Tween`** for the actual smooth opacity transition — a `Tween` is not a duration-tracking mechanism in the same sense as the manager above, it's an interpolation driver. Any `Tween` used for a visual transition must ALSO be explicitly paused/resumed via `tween.pause()`/`tween.play()` tied to the same Suspended signal, following the identical "explicit, signal-tied, not implicit" discipline this ADR establishes for the logical timers — not a separate architecture decision, an extension of the same rule.

### Architecture Diagram
```
Scene/World Management's Suspended transition (ADR-0001/0005's signals)
        │
        ├─► UITimerManager.on_suspended_begin() / on_suspended_end()
        │   (one call each way, gates the WHOLE shared _process loop)
        │
        └─► any active visual Tween.pause() / .play() (same discipline,
             applied per-Tween since Tween doesn't share the manager's
             dictionary — but same signal, same "explicit not implicit" rule)

UITimerManager (owned by Building UI):
  _records: Dictionary[key, TimerRecord]  — grace timers, debounce windows,
                                             invalid-cue fade, all in ONE dict
  _process(delta):  # raw delta, pause-immune, gated only by _suspended
    if _suspended: return
    decrement all records; fire callbacks + erase on expiry
      (grace expiry callback RE-QUERIES Build Validation's current state,
       per TR-014 — never trusts the original triggering event)
```

### Key Interfaces
```gdscript
# UITimerManager's public API (Building UI's internal utility, not a
# cross-system contract — no other module calls into this):
func start_timer(key: StringName, duration: float, on_expire: Callable) -> void
func cancel_timer(key: StringName) -> void
func has_timer(key: StringName) -> bool
func get_remaining(key: StringName) -> float
func on_suspended_begin() -> void
func on_suspended_end() -> void
```

## Alternatives Considered

### Alternative A: Centralized expiry-timestamp manager (shared dictionary + one `_process` loop) — CHOSEN
- **Description**: as detailed in Decision above.
- **Pros**: zero per-timer Node overhead (no Timer instantiation/destruction churn as toasts appear/disappear); pausing is a single boolean guard rather than N individual pause calls; directly consistent with Time & Tick's own "no per-consumer timers" precedent; trivially introspectable (`_records.size()` is literally "how many timers are active").
- **Cons**: one hand-rolled decrement loop instead of relying on engine-native Timer behavior; if a future consumer outside Building UI needs the same pattern, the class needs to be promoted to a shared utility (not currently needed, since no other MVP system has this requirement).
- **Rejection Reason**: N/A — chosen.

### Alternative B: N per-issue Godot `Timer` nodes
- **Description**: instantiate one `Timer` node per active grace/debounce/invalid-cue window, using `autostart`, `wait_time`, and the `timeout` signal; pause via `timer.paused = true` per instance (Godot's `Timer.paused` natively preserves `time_left`).
- **Pros**: `Timer.paused` genuinely does preserve remaining time automatically (a real engine feature, not something Alternative A gets "for free" that Alternative B lacks) — this alternative is not weaker on the pause-preservation requirement specifically.
- **Cons**: requires tracking every live `Timer` node in a list/dictionary anyway (to pause them all on Suspended, and to look one up by key for cancellation) — so the bookkeeping cost isn't actually avoided, it's just spent on managing Node instances instead of plain data records; real Node instantiation/destruction overhead at potentially high toast turnover; contradicts the project's own stated "no per-consumer timers anywhere" precedent for no compensating benefit.
- **Rejection Reason**: doesn't avoid the bookkeeping this ADR needs anyway, adds Node-lifecycle overhead for it, and works against an already-established project preference.

## Consequences

### Positive
- Directly consistent with Time & Tick's own already-accepted architectural taste — not a one-off pattern invented for Building UI alone.
- Pausing/resuming dozens of active timers simultaneously costs exactly one boolean flip, not N individual calls.
- No Node-lifecycle churn as toasts/warnings appear and disappear at runtime.

### Negative
- Building UI must own and drive this manager's `_process` call itself (it's not a Node with its own automatic `_process`, unless `UITimerManager` extends `RefCounted` and Building UI calls its update method from Building UI's own `_process` — an implementation detail to settle in `/dev-story`, not architecturally significant either way).
- A future consumer outside Building UI wanting the same pattern requires promoting this class to a shared location — not a current need, noted for awareness.

### Risks
- **Risk**: none identified — engine-specialist validation confirmed both the chosen design and the rejected alternative's comparison claim are accurate, with no reentrancy or typing gotcha in the manual `_process`-drive pattern.

**Engine Specialist Validation** (2026-07-11, `godot-specialist`, run before finalizing this ADR): confirmed `Timer.paused` genuinely preserves and resumes from `time_left` automatically with no manual bookkeeping (unchanged 4.4→4.7) — validating the Alternatives section's comparison claim about the rejected alternative is accurate, not just the chosen design. Confirmed `Tween.pause()`/`Tween.play()` remains the correct, current API for the visual-fade extension noted in Decision §4. Confirmed the manual `_process`-drive pattern (a plain `RefCounted`-style manager updated from Building UI's own `_process`, typed `Dictionary[StringName, TimerRecord]`, two-pass expiry collection then callback firing) has no reentrancy bug — a callback that calls `start_timer()` only mutates `_records`, never the separately-collected `expired` array being iterated — and no 4.7-specific typing gotcha. Verdict: "safe to accept as written." No corrections were needed.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|----------------------------|
| building-ui.md | TR-building-ui-014: "First-appearance grace... on expiry must re-query Build Validation's queryable state (not the triggering event)" | The manager's expiry callback contract supports arbitrary re-query logic at expiry, Decision §1 |
| building-ui.md | TR-building-ui-015: "Grace/debounce/invalid-cue timers pause and resume-with-remaining-time only on the Suspended transition... decoupled from Control visibility" | Single `_suspended` guard on the shared loop, Decision §1/§3 |
| building-ui.md | TR-building-ui-018: "Dismissal debounce: per-key wall-clock suppression window" | Same manager, keyed by dismissal key |
| building-ui.md | TR-building-ui-040: "Timer-architecture decision required: centralized expiry-timestamp manager vs. N per-issue Godot Timer nodes" | This ADR — centralized manager chosen |

## Performance Implications
- **CPU**: One `_process` loop iterating active records (expected dozens at most) — negligible against the 16.6ms frame budget.
- **Memory**: One dictionary of small records, no Node instantiation overhead.
- **Load Time**: N/A.
- **Network**: N/A — single-player project.

## Migration Plan
N/A — no existing code.

## Validation Criteria
- A unit test starts several timers with different durations, advances simulated time, and asserts each fires its callback exactly once at the correct elapsed time.
- A unit test starts a timer, calls `on_suspended_begin()`, advances simulated time, calls `on_suspended_end()`, and asserts the timer's remaining time reflects only the time elapsed OUTSIDE the suspended window — proving exact pause/resume fidelity.
- A unit test confirms hiding the owning Control does NOT pause any active timer (decoupling from visibility, per TR-015).

## Related Decisions
- Applies Time & Tick System's own "no per-consumer timers anywhere" precedent to the Presentation layer.
- Reuses the Suspended-signal pattern established across ADR-0001/ADR-0005 as its pause/resume trigger.
