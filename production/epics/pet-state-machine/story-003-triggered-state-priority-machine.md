# Story 003: Triggered-State Priority Machine

> **Epic**: Pet State Machine
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/pet-state-machine.md`
**Requirement**: `TR-petstate-001` (Triggered-state layer), `TR-petstate-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Pet State Machine Architecture, Decision §1 (Triggered State home), §3 (priority + non-interruptible LEVELING_UP), §5 (trigger events consumed)

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM — bespoke priority/queue logic (small but must be tested per the ADR's own Consequences §Negative), and this project's first use of Flame `Effect`s (`ScaleEffect`/`Transform2DEffect`-family) whose compounding behavior the ADR explicitly flags as a risk requiring `_clearEffects()`.

**Control Manifest Rules (this layer)**:
- Required: "Triggered-state priority: LEVELING_UP > EXCITED > SHOWING_OFF > PLEASED > BOUNCING" — source: ADR-0007
- Required: "LEVELING_UP non-interruptible: other triggers queue (single highest-priority) and replay after 3s" — source: ADR-0007
- Required: "SLEEPING accepts only EXCITED and LEVELING_UP, ignores other triggers" — source: ADR-0007
- Required: "Use explicit priority map (`levelingUp:5,...,bouncing:1`) — NEVER `TriggeredState.index`" — source: ADR-0007
- Required: "`_clearEffects()` before adding the next effect — required correctness, not polish, for transform-based states" — source: ADR-0007
- Required: "'Prior effect cleared' validation must assert after a subsequent tick, not synchronously" — source: ADR-0007
- Forbidden: "Never model triggered states as Riverpod state — wall-clock timer wouldn't pause with the loop, breaking the background-pause requirement" — source: ADR-0007

## Already Established (do not re-derive)

- `MochiComponent` already exists from Story 002 with a working `_onEvent` switch handling `GameEventType.petMoodChanged` and a cached `_baseMood` field — this story ADDS cases to that same switch, does not create a new component or a new subscription.
- `GameEventSubscriber`'s `subscribedEventTypes` getter needs widening from `{petMoodChanged}` (Story 002) to include the 5 trigger types this story handles.

---

## Acceptance Criteria

*From `design/gdd/pet-state-machine.md`'s Core Rules #3-4 and Edge Cases, and ADR-0007 Decision §3 + Validation Criteria:*

- [x] `TriggeredState` enum matches ADR-0007 exactly: `{ levelingUp, excited, showingOff, pleased, bouncing }` — declared in this order (the ADR is explicit that this declaration order is the OPPOSITE of priority order, which is why `.index` must never be used for priority).
- [x] An explicit priority map exists (`{levelingUp: 5, excited: 4, showingOff: 3, pleased: 2, bouncing: 1}` or equivalent) and is the ONLY thing priority comparisons use — no code path uses `TriggeredState.index`.
- [x] `MochiComponent._onEvent` gains 5 new cases mapping the Bridge's trigger `GameEventType`s to `onTrigger(TriggeredState)` calls: `taskApproved → excited`, `petInteracted → pleased`, `itemEquipped → showingOff`, `seedReceived → bouncing`, `petLeveledUp → levelingUp`.
- [x] `onTrigger(TriggeredState t)`: if a higher-priority trigger than the current one arrives, reset the timer and play the new animation; if lower-or-equal priority, ignore it entirely (no timer reset, no re-render).
- [x] LEVELING_UP is non-interruptible: while it is the current triggered state, ANY other incoming trigger (including EXCITED) is queued rather than applied — it does not reset LEVELING_UP's timer and does not play immediately.
- [x] The trigger queue holds only the single highest-priority pending trigger received while LEVELING_UP is playing (a burst of multiple triggers during LEVELING_UP does not queue all of them — only the best one survives, per the ADR's own queue-correctness risk note).
- [x] After LEVELING_UP's 3.0s completes, the queued trigger (if any) plays immediately; if none was queued, the component returns to Base Mood.
- [x] SLEEPING gate: when `_baseMood == MoodState.sleeping`, ordinary triggers (`pleased`, `showingOff`, `bouncing`) are ignored entirely — only `excited` and `levelingUp` are still accepted.
- [x] `_clearEffects()` (removing any currently-attached `Effect` components) is called before adding the next triggered-state's effect, for every transform-based triggered state — verified by a test asserting after a subsequent tick (not synchronously) that only one effect is active at a time, even under rapid same-type or different-type re-triggering.
- [x] Each `TriggeredState`'s duration matches the GDD's Formulas table exactly: LEVELING_UP 3.0s, EXCITED 1.5s, PLEASED 2.0s, SHOWING_OFF 2.0s, BOUNCING 1.0s.
- [x] A fresh `TimerComponent` (or `.start()` on retrigger, never a bare `.limit` mutation on a stopped timer) is used per activation, per ADR-0007's explicit guidance.

---

## Implementation Notes

*From ADR-0007 Decision §3-§5 and Key Interfaces:*

```dart
enum TriggeredState { levelingUp, excited, showingOff, pleased, bouncing }

// priority: levelingUp:5, excited:4, showingOff:3, pleased:2, bouncing:1
// Use this explicit map — never TriggeredState.index (the enum is declared in
// the opposite order of priority; .index would invert it).

// Inside MochiComponent:
//   TriggeredState? _current;               // null = showing Base Mood (_baseMood)
//   TimerComponent? _timer;                 // frame-ticked; pauses with loop (Story 004 verifies this)
//   TriggeredState? _queued;                // single highest-priority pending trigger during LEVELING_UP
//
//   void onTrigger(TriggeredState t) {
//     if (_current == TriggeredState.levelingUp) { _queueHighest(t); return; }       // non-interruptible
//     if (_baseMood == MoodState.sleeping && t != TriggeredState.excited && t != TriggeredState.levelingUp) return; // SLEEPING gate
//     if (_current == null || priority(t) > priority(_current!)) { _play(t); }        // else ignore
//   }
```
- "Prefer one clock per triggered state": for EXCITED (scale-bounce) and SHOWING_OFF (360° spin), drive the state's lifecycle off the `Effect`'s own `onComplete` rather than a parallel `TimerComponent`, per the ADR's explicit preference — reduces drift risk if a duration is ever edited in only one place. Where a `TimerComponent` is used directly (e.g. PLEASED/BOUNCING with no natural `Effect.onComplete` hook), construct a fresh one per activation.
- `_queueHighest(TriggeredState t)`: compare `t` against whatever is already queued (if anything) using the priority map; keep only the higher of the two. This must be tested with a burst of 2+ different-priority triggers arriving while LEVELING_UP plays.
- SHOWING_OFF's particle spec is explicitly out of scope here (owned by Pet Equipment #15 per ADR-0007's Ordering Note) — this story implements the spin/priority/timing mechanics only, not the particle visuals.
- Component removal (`_clearEffects`'s `removeWhere`) is next-tick, not synchronous, per the ADR's Risks section — write the "effect cleared" test to assert after a subsequent `update()`/tick call in `flame_test`, not immediately after triggering.

---

## Out of Scope

- Story 001/002 (this epic): Base Mood lookup and the `petMoodChanged` cold-start/caching wiring — already done, this story only extends the same `_onEvent` switch.
- Story 004 (this epic): explicit background pause/resume verification of the `TimerComponent` — this story implements the timer mechanism per ADR guidance but the dedicated backgrounding test is Story 004's scope.
- SHOWING_OFF's particle visuals — Pet Equipment (#15)'s ownership.
- The actual sprite/animation assets played per triggered state — asset production, not this epic's code concern.
- Emission of the 5 trigger `GameEventType`s themselves (`taskApproved`, `petInteracted`, `itemEquipped`, `seedReceived`, `petLeveledUp`) — owned by their respective emitting systems' future epics (Parent Approval #11, Pet Interaction #14, Pet Equipment #15, Seed Buffer #10, Pet Leveling #16); this story only consumes them.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0007's Validation Criteria and the GDD's own Acceptance Criteria/Edge Cases:*

```
Test: higher-priority trigger replaces and resets the timer
  Given: MochiComponent with _current = TriggeredState.pleased (priority 2), timer partway through 2.0s
  When: a showingOff trigger (priority 3) arrives
  Then: _current becomes showingOff, a fresh 2.0s timer starts (not continuing pleased's remaining time)

Test: lower-or-equal priority trigger is ignored
  Given: MochiComponent with _current = TriggeredState.excited (priority 4)
  When: a bouncing trigger (priority 1) arrives
  Then: _current remains excited, no timer reset, no new effect added

Test: LEVELING_UP is non-interruptible by a higher-priority-looking trigger
  Given: MochiComponent with _current = TriggeredState.levelingUp, timer partway through 3.0s
  When: an excited trigger arrives (normally priority 4, would out-rank most states)
  Then: _current remains levelingUp, unchanged, unreset; excited is queued instead

Test: only the single highest-priority trigger survives the LEVELING_UP queue
  Given: MochiComponent with _current = levelingUp
  When: a bouncing trigger arrives, then a showingOff trigger arrives, then a pleased trigger arrives
    (all while levelingUp is still playing)
  Then: after LEVELING_UP completes, showingOff plays next (the highest-priority of the 3 queued
    attempts), not bouncing (first-arrived) or pleased (last-arrived)

Test: queued trigger replays immediately after LEVELING_UP completes
  Given: MochiComponent with _current = levelingUp and excited queued
  When: LEVELING_UP's 3.0s timer completes (advance via repeated update(dt) ticks in flame_test)
  Then: _current becomes excited immediately, with its own fresh 1.5s timer

Test: no queued trigger after LEVELING_UP returns to Base Mood
  Given: MochiComponent with _current = levelingUp, nothing triggered during its 3.0s
  When: LEVELING_UP's timer completes
  Then: _current becomes null (showing _baseMood's idle animation)

Test: SLEEPING gate rejects ordinary triggers
  Given: MochiComponent with _baseMood = MoodState.sleeping, _current = null
  When: a pleased trigger arrives
  Then: _current remains null — the trigger is silently ignored (SLEEPING-exception rule)

Test: SLEEPING gate still accepts EXCITED (wake) and LEVELING_UP
  Given: MochiComponent with _baseMood = MoodState.sleeping, _current = null
  When: an excited trigger arrives
  Then: _current becomes excited (Mochi "wakes")
  Edge cases: repeat with a levelingUp trigger instead — also accepted

Test: rapid same-type retrigger clears the prior effect before the next (async, next-tick)
  Given: MochiComponent with _current = excited and its ScaleEffect attached
  When: a second excited-triggering event arrives immediately, then a subsequent update(dt) tick runs
  Then: after the tick, exactly one Effect component is attached to MochiComponent (the old one was
    removed via _clearEffects, not left compounding) — assert this AFTER a tick, not synchronously

Test: exact triggered-state durations match the GDD's Formulas table
  Given: each TriggeredState triggered in turn from a clean state
  When: its TimerComponent/Effect completes
  Then: the elapsed simulated time (summed update(dt) calls) matches: levelingUp=3.0s, excited=1.5s,
    pleased=2.0s, showingOff=2.0s, bouncing=1.0s (within a small dt-step tolerance)

Test: priority comparisons never use TriggeredState.index
  Given: the component's source code
  When: inspected (static check)
  Then: no code path compares `.index` values of TriggeredState for priority purposes — only the
    explicit priority map is used
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pet_state_machine/mochi_component_triggered_state_test.dart` — must exist and pass

**Status**: [x] Created — `tests/integration/pet_state_machine/mochi_component_triggered_state_test.dart`, 15 tests, all passing.

---

## Dependencies

- Depends on: Story 002 (this epic) — `MochiComponent` and its `_onEvent` switch must exist first.
- Unlocks: Story 004 (this epic) — needs an active triggered-state timer to verify pause/resume against. Also unlocks Pet Interaction (#14), Pet Equipment (#15), Pet Leveling (#16), Seed Buffer (#10) — all of which emit the trigger events this story consumes.

---

## Completion Notes

**Implementation**: `src/lib/core/triggered_state.dart` — `TriggeredState` enum (declared in non-priority order per ADR-0007) plus explicit `triggeredStatePriority()`/`triggeredStateDuration()` maps (never `.index`). `src/lib/gameplay/mochi_component.dart` — extended with `onTrigger()`, `_queueHighest()`, `_play()`, `_onTriggerComplete()`, `_clearEffects()`, and a private `_TriggerTimer`. Mixed completion mechanism per ADR-0007 Decision §4's explicit preference: EXCITED/SHOWING_OFF drive completion off a real `ScaleEffect`/`RotateEffect`'s own `onComplete` (this project's first use of Flame Effects); LEVELING_UP/PLEASED/BOUNCING (no natural Effect hook at this story's scope — visual choreography is a future epic's job) use `_TriggerTimer`, a thin `TimerComponent` subclass. `_clearEffects()` sweeps both `Effect` and `_TriggerTimer` children (broader than the ADR's own literal `Effect`-only snippet, necessary since this implementation uses two mechanisms) — `flame-specialist` confirmed this sweep is complete and not over-broad, since these are the only two child types this component ever attaches.

**Real bug found and fixed in the TEST HARNESS (not production code)**: `TimerComponent.onLoad()` is `async` in Flame 1.37.0 (verified against installed source), so a newly-`add()`-ed `_TriggerTimer` needs one microtask turn to leave the "loading/blocked" lifecycle state before it starts receiving `update(dt)` ticks. A tight synchronous test loop of `game.update(dt)` calls with no yields between them "loses" the first tick's dt entirely — this made LEVELING_UP/PLEASED-driven tests fail while Effect-driven tests (synchronous `onLoad()`) passed, exposing the bug. Fixed via a `_settle(game)` helper (`FlameGame.ready()`, which drains pending mount/load lifecycle events without advancing simulated time) called after every `onTrigger()` before the timed `_advance()` countdown starts. `flame-specialist` independently confirmed this is a real Flame async-`onLoad()` mounting property, NOT a production timing defect — real gameplay's frame-to-frame gap (~16ms) is far longer than the trivial `onLoad()`'s resolution time, so this only ever costs one real frame in production, never accumulates.

**Second, smaller test-harness fix**: a `_tolerance = 0.02` epsilon was added to two exact-boundary assertions after discovering `_advance`'s dt-summed total can fall a hair short of an exact nominal duration due to ordinary floating-point summation across ~90 small (1/60s) steps. `flame-specialist` confirmed this is standard test engineering (`Timer.finished` uses a strict `>=` comparison with no inherent lag) and not masking a real gameplay bug — real dt is never exactly `1/60` repeating.

**Tests**: `tests/integration/pet_state_machine/mochi_component_triggered_state_test.dart` — 15 tests, all passing: higher-priority replace+reset, lower-priority ignored, LEVELING_UP non-interruptible (queues), only the single highest-priority trigger survives the queue, queued trigger replays after LEVELING_UP completes, no queued trigger returns to Base Mood, SLEEPING gate rejects/still-accepts, rapid retrigger clears the prior Effect (corrected mid-implementation — SHOWING_OFF's priority 3 is LOWER than EXCITED's 4, so it can't force a replace; LEVELING_UP is used instead, per `flame-specialist`'s independent confirmation this substitution is the ADR-faithful choice), exact durations for all 5 states, priority-never-uses-index (both a values check and a source-string sweep), equal-priority retrigger does not reset the timer, LEVELING_UP retriggering itself while already current queues and replays (documents the GDD's literal "mọi trigger khác... bị queue" as including a second LEVELING_UP, not just other trigger types), and a real-bus event→`TriggeredState` mapping test for all 5 trigger event types (closes a gap qa-tester found: every other test called `onTrigger()` directly, never proving the actual `GameEventBus → onGameEvent → onTrigger()` wiring itself).

**Code review**: `flame-specialist` — **APPROVED WITH SUGGESTIONS**, zero required changes; one suggestion applied — a clarifying footnote added to ADR-0007 Decision §5 (2026-07-16) since "rapid same-type events clear the prior effect" is literally unsatisfiable under this ADR's own strict priority comparison for a true same-type-same-priority retrigger. `qa-tester` — **GAPS** (4 findings, all fixed): the real bus-wiring test (added), the equal-priority test (added), the LEVELING_UP-retriggers-itself test (added, with documented expected behavior rather than escalating as ambiguous), and a weak `.index` guard (strengthened to a real source-string sweep, itself needing one follow-up fix after it false-flagged the doc comments' own explanatory mentions of `.index`).

**Deviations from scope**: None.
**Manifest version**: 2026-07-16 (current at time of implementation — no drift).
