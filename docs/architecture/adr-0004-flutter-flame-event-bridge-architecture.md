# ADR-0004: Flutter-Flame Event Bridge Architecture

## Status
Accepted (2026-07-11 — accepted post independent /architecture-review; flame-specialist-validated at authoring)

## Date
2026-07-07

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Core / Rendering (Flame component lifecycle + Flutter↔Flame boundary) |
| **Knowledge Risk** | MEDIUM — Flame component lifecycle idioms changed post-cutoff (`findGame()`/`isMounted` over cached `HasGameRef`; `onRemove()` semantics). The `GameEventBus` itself is pure Dart (`StreamController.broadcast()` — LOW, stable). Spike-validated on the pinned versions. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `current-best-practices.md`, `deprecated-apis.md`; `design/gdd/flutter-flame-state-bridge.md`; `prototypes/flutter-flame-bridge-spike-2026-06-26/`; `prototypes/firebase-multidevice-sync-spike-2026-07-03/`; ADR-0002; flame-specialist validation (2026-07-07) |
| **Post-Cutoff APIs Used** | Flame `Component.isMounted`, `onMount()`/`onRemove()` lifecycle (1.37 idioms — subscribe in `onMount()`, verified against Flame 1.37.0 source `component.dart` on 2026-07-07). `StreamController.broadcast()`, `StreamSubscription` (stable Dart). |
| **Verification Required** | **Background→foreground event-replay path is NOT yet spike-validated.** The bridge spike measured live same-device + multi-device online sync (avg 151ms); it did NOT exercise the case where device B is offline at approve-time then reconnects. Manual verification (~10 min) required during Parent Approval (#11) implementation — this is an open validation criterion, not a proven guarantee. ⚠️ **Additionally (corrected 2026-07-13, see Decision §5 Correction note)**: the replay mechanism's scope was found too narrow during the vertical slice — it must cover any newly-mounted subscriber (bus-level last-event-per-type cache), not just app-background→foreground. Implement and test the bus-level version, not the original app-lifecycle-only version. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Auth & PIN Security) — the bridge scopes its upstream Riverpod providers on `activeChildProvider` and imports from `lib/providers/auth_providers.dart`. NOT dependent on ADR-0003 (the bridge touches no Firestore directly — it reads Riverpod providers, which are downstream of persistence). |
| **Enables** | Pet State Machine (#6), Seed Buffer (#10), Pet Equipment (#15), Pet Interaction (#14), Pet Leveling (#16), Pet Room Screen UI (#18) — every system that produces or consumes a cross-boundary visual event. |
| **Blocks** | Any implementation epic wiring a Flutter state change to a Flame visual response — none may begin until this ADR is Accepted. |
| **Ordering Note** | This ADR owns the bus, the event contract, the adapter rules, and the subscriber lifecycle. It does NOT own the individual event payloads' business meaning (e.g. what `LEVELING_UP` does) — those belong to the respective system ADRs, which cite this bridge as their delivery mechanism. |

## Context

### Problem Statement

PetQuest mixes two runtime models on one screen: Flutter's retained-mode widget/Riverpod world and Flame's game-loop component world. The emotional payoff of the whole game — a parent taps Approve and the child's Mochi bounces "instantly" — depends on a change in Flutter state reaching a Flame component and triggering an animation, without the two layers becoming tightly coupled. Every pet-visual and interaction system needs this path. Before any of them are built, one ADR must fix: what the bridge is, which direction data flows, who is allowed to put events on it, and how Flame subscribers manage their lifecycle so they neither leak nor crash. The `flutter-flame-state-bridge.md` GDD specifies this and it is validated by a working spike; this ADR ratifies it and pins the one-way invariant precisely.

### Constraints
- **One-way is a hard architectural rule**: the Flame layer must never call back into Flutter/Riverpod (no callbacks, no provider writes from a component). Flutter state is the source of truth; Flame is the display layer.
- **Flame lifecycle correctness** (MEDIUM-risk domain): subscribers live and die with components; a missed `cancel()` leaks and can fire into a removed component.
- **App-lifecycle**: while the app is backgrounded the OS may suspend the whole isolate, so the upstream `ref.listen`→`emit()` chain may never run — the miss is "nothing was fired," not "a live subscription dropped it." (A broadcast subscription is driven by the Dart event loop, not Flame's frame ticker; a paused game loop alone would not drop a delivered callback, only stop animating/repainting it.) Either way, a foreground recovery is needed.
- **Latency budget**: local delivery <1ms; end-to-end (parent-device approve → child Mochi) measured avg 151ms / max 439ms, "feels instant."

### Requirements
- A pure-Dart event bus, no Flutter/Flame imports, app-lifetime singleton.
- A typed event contract where each event type owns its own payload shape.
- Exactly two sanctioned ways to put an event on the bus (below); nothing else.
- Mandatory subscriber lifecycle guards so removed components neither crash nor leak.
- A defined background→foreground recovery strategy.

## Decision

**1. `GameEventBus` — pure-Dart broadcast singleton.**
A `StreamController<GameEvent>.broadcast()` behind a factory singleton (`factory GameEventBus() => _instance`). It imports neither Flutter nor Flame — pure Dart, so it is trivially testable and coupled to nothing. Constructed once at app root (ADR: master architecture init order §4), disposed only at app termination — never per-screen. `emit()` guards `!_controller.isClosed` (silent no-op + warning log if called after dispose).

**2. `GameEvent` — typed contract, per-type payload.**
```dart
enum GameEventType { petMoodChanged, seedReceived, itemEquipped, energyChanged,
                     petLeveledUp, petInteracted, taskApproved }
class GameEvent { final GameEventType type; final dynamic data; }
```
Each type owns a documented, distinct payload shape (`petMoodChanged`→`PetMood`, `energyChanged`→`double`, `taskApproved`→`null`, etc.). **Payload types must never be shared across event types** — this is the rule that prevented the real `EXCITED`-as-`PetMood` `TypeError` bug (a Triggered State was being shipped in a Base-Mood payload). Every `_onEvent` handler checks `event.type` before casting `event.data`.

**3. The one-way invariant — precisely: "never Flame→Flutter", NOT "only widgets may emit."**
Data never flows from the Flame layer back into Flutter/Riverpod (no callbacks into widgets, no provider writes from components). There are exactly **two sanctioned adapters** that place events on the bus, and both respect that invariant:
- **(a) Flutter→Flame (the common path)**: a `ref.listen` call inside a `ConsumerWidget` maps a Riverpod state change to `GameEventBus().emit(...)`. `ref.listen` fires only on *change*, not on rebuild. The adapter lives in the widget — never in a Notifier, never in a Flame component. Used by Pet State Machine, Seed Buffer, Pet Equipment, Pet Leveling, Energy.
- **(b) Flame→Bus→Flame (the in-game path)**: Pet Interaction (#14) is a Flame component that, from its `TapCallbacks`/`DragCallbacks` handler, calls `GameEventBus().emit(GameEvent(petInteracted, ...))` directly. This is **compatible with one-way flow** because the event still only flows Flame→Bus→Flame (consumed by the Pet State Machine's in-game logic) — it never reaches back into Flutter. The invariant being enforced is the *direction* (no Flame→Flutter), not *who is allowed to emit*.

No third path is permitted (e.g. a Notifier emitting directly, or a component writing a provider).

**4. Flame subscriber lifecycle — subscribe in `onMount()`, `isMounted` guard, `cancel()` in `onRemove()`, all mandatory.**
```dart
StreamSubscription<GameEvent>? _sub;
@override void onMount() {                 // NOT onLoad() — see rationale below
  super.onMount();
  _sub = GameEventBus().stream.listen(_onEvent);
}
void _onEvent(GameEvent e) {
  if (!isMounted) return;                 // MANDATORY — component may be mid-removal
  switch (e.type) { /* check type, then cast e.data */ }
}
@override void onRemove() {
  _sub?.cancel();                         // MANDATORY — else leak + fire-into-removed
  super.onRemove();
}
```
**Subscribe in `onMount()`, NOT `onLoad()`** (verified against Flame 1.37 source, 2026-07-07). Three reasons:
1. `isMounted` stays `false` for the entire duration of `onLoad()` (the mounted bit is set only *after* `onMount()` returns). Since the handler's mandatory `if (!isMounted) return;` guard is the only gate, an `onLoad()`-based subscription would **silently and permanently drop** any event arriving during the load→mount window (which spans multiple frames when the component `await`s sprite loads) — the event is not queued, it is gone.
2. `onMount()` is documented as **1:1-paired with `onRemove()`** ("for every `onMount` there is a corresponding `onRemove`"); `onLoad()` is not. If a component is removed while still in the pending-load queue (parent still `null`), Flame calls neither `onMount()` nor `onRemove()` — an `onLoad()`-created subscription would then have **no teardown path**, defeating the leak guarantee.
3. `onLoad()` runs **only once ever**; `onMount`/`onRemove` fire on every add/remove cycle. A component removed then re-added (screen nav reusing an instance) would permanently stop receiving events under an `onLoad()` subscribe, but re-subscribes correctly under `onMount()`.

Use `isMounted` (not `parent != null`), consistent with the Flame 1.37 idiom. Subscribing is a cheap synchronous call, so `onMount()` (non-async) is the correct home. A missed `cancel()` is a subscription leak that can fire into a removed component — forbidden.

> Note: the reference spike (`prototypes/flutter-flame-bridge-spike-2026-06-26/`) subscribes in `onLoad()` — it validated latency + routing (which it did correctly), not this lifecycle nuance. Production components must start from the `onMount()` pattern above, not copy the spike verbatim.

**5. Replay last state per type to any new subscriber — never history, and never scoped to app-background only.**

> ⚠️ **Corrected 2026-07-13** (from `/vertical-slice` self-test + `/gate-check` Pre-Production→Production exit-criteria #2). The original wording below scoped this requirement to whole-app background→foreground recovery only, implicitly assuming the Flame component subscribing to a given event type is a single, long-lived subscriber for the entire app session. **That assumption is false.** The vertical slice found the real, more general failure mode: whenever a Flame-canvas-hosting screen is dynamically remounted for any reason — not just app backgrounding, e.g. navigating away and back — a brand-new component instance subscribes fresh in `onMount()`. If the relevant provider had already transitioned to its current value *before* this new instance existed, no NEW `GameEvent` is ever emitted (the emitting `ref.listen` adapter only fires on a *change*, and there was none after remount), so the new component never learns the current state and silently renders a stale or hardcoded default. This is not a corner case — it is the default outcome of the original design's edge-triggered-only replay for any screen using `if/else` widget swapping, `IndexedStack` rebuilding, or any other pattern that disposes and recreates the Flame-hosting widget.
>
> **Corrected requirement**: the replay mechanism must operate at the **bus level**, not rely on `ref.listen` re-evaluating on a specific trigger (app-foreground). Concretely: `GameEventBus` must cache the last-emitted `GameEvent` per `GameEventType`, and immediately deliver that cached event to any newly-subscribing listener at subscription time (a `BehaviorSubject`-like semantics per type — a plain `StreamController.broadcast()` alone does not do this and must be supplemented). This subsumes and generalizes the original app-background→foreground case (which is just one specific reason a subscriber might be "new" relative to the last transition) — a single mechanism now covers both. The originally-implemented one-time app-cold-start seed (used as a stopgap in the vertical slice) is NOT sufficient and must not be carried into production as-is.

Original text, kept for audit trail: "While backgrounded, the isolate may be suspended and the emit chain never runs (see Constraints), so on foreground re-emit the *current* value of each relevant provider (via the existing `ref.listen` adapters re-evaluating), NOT a replay of the missed event history — replaying history would produce an event storm." The "never full history, only last-per-type" principle is unchanged and still correct; only the trigger scope was too narrow. Rapid same-type events are delivered sequentially by the broadcast stream (no race); a component clears its prior effect before applying the next.

The bus's `StreamController.broadcast()` is created **without `sync: true`**, so listener callbacks are scheduled on the microtask queue, not nested inside the emitting call stack. This makes emitting from within a `TapCallbacks`/`DragCallbacks` handler (adapter b) reentrancy-safe — a handler that mutates the component tree cannot corrupt the emit that triggered it.

### Architecture Diagram
```
[Riverpod Notifier] --state change--> [ref.listen in ConsumerWidget]   (adapter a)
                                              │
[Flame component #14] --tap/drag--> emit() ───┤   (adapter b: Flame→Bus→Flame)
                                              ▼
                              GameEventBus  (pure-Dart broadcast singleton, app-lifetime)
                                              │  broadcast stream, <1ms local
                                              ▼
              [Flame components: MochiComponent, SeedBag, EnergyBar, PetEquip, ...]
                 onMount:  stream.listen(_onEvent)     (NOT onLoad — see §4)
                 _onEvent: if(!isMounted) return; switch(type) → animation/visual
                 onRemove: _sub.cancel()

   ✗ NO path from any Flame component back into Flutter/Riverpod (one-way invariant)
```

### Key Interfaces
```dart
class GameEventBus {
  static final GameEventBus _instance = GameEventBus._();
  factory GameEventBus() => _instance;
  final _controller = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get stream => _controller.stream;
  void emit(GameEvent e) { if (!_controller.isClosed) _controller.add(e); /* else warn */ }
  void dispose() => _controller.close();   // app-termination only
}
enum GameEventType { petMoodChanged, seedReceived, itemEquipped, energyChanged,
                     petLeveledUp, petInteracted, taskApproved }
class GameEvent { final GameEventType type; final dynamic data; const GameEvent(this.type, this.data); }
```
Payload contract (each type → exactly one payload type):
`petMoodChanged→PetMood` · `seedReceived→SeedData` · `itemEquipped→String itemId` · `energyChanged→double` · `petLeveledUp→int newLevel` · `petInteracted→InteractionType` · `taskApproved→null`.

## Alternatives Considered

### Alternative A: GameEventBus broadcast-singleton (chosen)
- **Description**: Pure-Dart broadcast `StreamController` singleton; two sanctioned adapters; mandatory subscriber lifecycle.
- **Pros**: Zero coupling (bus imports nothing); spike-validated (avg 151ms end-to-end); trivially unit-testable; supports N subscribers; enforces one-way by construction.
- **Cons**: Background-miss requires an explicit replay strategy (§5); a forgotten `cancel()` leaks (mitigated by the mandatory-lifecycle rule + review).
- **Rejection Reason**: N/A — chosen, spike-proven.

### Alternative B: Flame components watch Riverpod directly (ProviderContainer in the game)
- **Description**: Give Flame components access to the `ProviderContainer` and have them `listen`/`read` providers directly.
- **Pros**: No separate bus; fewer moving parts on paper.
- **Cons**: Couples the Flame layer to Riverpod (breaks the "Flame imports nothing from state mgmt" goal); makes components untestable without a Riverpod harness; blurs the one-way boundary (a component with container access can trivially write a provider).
- **Rejection Reason**: Couples the display layer to the state layer — the exact thing the bridge exists to prevent.

### Alternative C: Bidirectional bus / Flame→Flutter callbacks
- **Description**: Allow Flame components to push events/callbacks back into Flutter.
- **Pros**: Would let in-game actions directly drive Flutter state.
- **Cons**: Destroys the single-source-of-truth model; creates feedback loops and ordering ambiguity between the two runtimes.
- **Rejection Reason**: Directly violates the one-way invariant. Rejected. (The #14 direct-emit case is NOT this — it is Flame→Bus→Flame, §3.)

## Consequences

### Positive
- The game's core emotional moment (approve → instant Mochi reaction) works, spike-proven at "feels instant" latency.
- The two runtimes stay decoupled; the bus is pure Dart and testable in isolation.
- One-way is enforceable by review against a precisely-stated invariant, and the payload-per-type rule prevents an entire class of runtime `TypeError`.

### Negative
- Subscriber correctness is a manual discipline (`isMounted` + `cancel()`), not compiler-enforced — must be a code-review checklist item.
- Background-miss handling adds a foreground-replay responsibility to each adapter.

### Risks
- **Subscribing in `onLoad()` instead of `onMount()`** → dropped events during the load→mount window, no teardown if removal races load, and dead subscription after a re-add. *Mitigation*: §4 mandates `onMount()` (verified against Flame 1.37 source); LP-CODE-REVIEW checklist item; do not copy the spike's `onLoad()` subscribe.
- **Forgotten `cancel()` in `onRemove()`** → subscription leak firing into a removed component. *Mitigation*: mandatory-lifecycle rule (§4); LP-CODE-REVIEW checklist item; `isMounted` guard limits blast radius to a silent early-return.
- **Wrong-type payload cast** (the historical `EXCITED`/`PetMood` bug). *Mitigation*: payload-per-type rule (§2); every handler switches on `type` before casting.
- **Background→foreground replay path not yet spike-validated.** *Mitigation*: Verification Required — manual ~10-min check during Parent Approval (#11) implementation; treat as an open validation criterion, not a proven guarantee. (This is the GDD's own remaining open question.)
- **Emit after dispose** (early screen pop). *Mitigation*: `emit()` guards `!isClosed` — silent no-op + warning log; bus is app-lifetime so this should not occur in normal flow.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| flutter-flame-state-bridge.md | `GameEventBus` pure-Dart broadcast singleton, app-lifetime (TR-bridge-001) | Decision §1 |
| flutter-flame-state-bridge.md | `GameEvent` typed contract, one-way Flutter→Flame (TR-bridge-002) | Decision §2–3 (invariant pinned precisely) |
| flutter-flame-state-bridge.md | `ref.listen` is the sanctioned bridge adapter (TR-bridge-003) | Decision §3(a) |
| flutter-flame-state-bridge.md | Flame subscriber `isMounted` guard + `cancel()` in `onRemove()` (TR-bridge-004) | Decision §4 |
| flutter-flame-state-bridge.md | Replay-last-state-per-type to any new subscriber, not history (TR-bridge-005) | Decision §5 (scope widened 2026-07-13 from app-background-only to any newly-mounted subscriber — see Correction note) |
| flutter-flame-state-bridge.md | Measured latency avg 151ms / max 439ms (TR-bridge-006) | Context + Verification (online path proven; offline-reconnect open) |
| parent-approval.md | `taskApproved` its own type, distinct from `petMoodChanged` (TR-parentapproval-007) | Decision §2 payload-per-type rule; `taskApproved→null` |
| pet-interaction.md | #14 emits `petInteracted` directly from a Flame component | Decision §3(b) — sanctioned Flame→Bus→Flame adapter |

## Performance Implications
- **CPU**: Negligible — broadcast stream dispatch is a synchronous in-isolate call.
- **Memory**: One subscription per subscribing component; freed on `onRemove()` (if `cancel()` is honored).
- **Load Time**: None — bus constructed once at app root.
- **Network**: None directly. End-to-end latency (when the trigger originates from a remote device) is dominated by the Firestore/FCM chain, measured avg 151ms.

## Migration Plan
Greenfield. The spike (`prototypes/flutter-flame-bridge-spike-2026-06-26/`) is the reference for latency/routing only — production components must use the `onMount()` subscribe pattern (§4), not the spike's `onLoad()`. One GDD sync lands alongside this ADR: `flutter-flame-state-bridge.md` Core Rule 5 ("Flame Component — Subscribe Pattern") currently shows the `onLoad()` snippet and must be corrected to `onMount()`, so developers implementing from the GDD don't reproduce the load→mount event-drop bug.

## Validation Criteria
- Unit: `GameEventBus` delivers to N subscribers; `emit()` after `dispose()` is a silent no-op + logs.
- Component test: `MochiComponent` applies the visual on `petMoodChanged` within one frame (<16.6ms); ignores events after `onRemove()` with no exception.
- Component test: two rapid same-type events → only the second effect shows (prior cleared).
- Type-safety test: each `GameEventType` handler rejects/does-not-cast a mismatched payload (guards against the `TypeError` class).
- **Open (manual, during #11 impl)**: background→foreground replay restores correct Mochi state after an offline approve + reconnect.

## Related Decisions
- ADR-0002 (Auth) — upstream; bridge adapters scope on `activeChildProvider`.
- Pet State Machine ADR (upcoming) — primary consumer of `petMoodChanged`/`petInteracted`/`taskApproved`/`petLeveledUp`.
- Parent Approval ADR (upcoming) — emits `taskApproved`; owns the offline-reconnect path this ADR flags as unvalidated.
- `design/gdd/flutter-flame-state-bridge.md` — the ratified, spike-validated design.
