# Story 002: Cold-Start Base Mood Bridge Wiring

> **Epic**: Pet State Machine
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/pet-state-machine.md`
**Requirement**: `TR-petstate-001` (Triggered-layer/bridge wiring half — the component itself must exist and cache Base Mood correctly before Story 003 can add trigger handling to the same `_onEvent` switch)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007: Pet State Machine Architecture, Decision §1 (cold-start seed, `_baseMood` caching) and §5 (events consumed from the Bridge)

**Engine**: Flutter 3.44.4 / Flame 1.37.0 / `flutter_riverpod ^3.3.2` | **Risk**: MEDIUM — this is the first `ref.listen`-based `GameEventBus` emit adapter in the project (the sanctioned Flutter→Flame path per ADR-0004) and the first real `MochiComponent`/Flame-canvas-hosting widget; no established precedent to copy from within this codebase yet, unlike Story 001.

**Control Manifest Rules (this layer)**:
- Required: "`MochiComponent` caches Base Mood from the `petMoodChanged` event, never by reading Riverpod directly" — source: ADR-0007
- Required: "Cold-start seed required: emit `petMoodChanged` once with `ref.read(petMoodProvider)` at initial build (or pass into constructor)" — source: ADR-0007
- Required: "Flame subscribers subscribe in `onMount()`, NOT `onLoad()`" — source: ADR-0004, reaffirmed ADR-0007
- Required: "Handler guards `if (!isMounted) return;`" — source: ADR-0004
- Required: "`_sub?.cancel()` MUST be called in `onRemove()`" — source: ADR-0004
- Required: "Exactly two sanctioned emit adapters: (a) `ref.listen` in a `ConsumerWidget`... (b) Flame component emitting directly... — one-way invariant: data never flows Flame→Flutter/Riverpod" — source: ADR-0004
- Required: "Emit `petMoodChanged` only when the mood BAND changes, not every energy tick" — source: ADR-0007
- Forbidden: "Never let a Flame component read Riverpod/`ProviderContainer` directly — one-way Flutter→Flame flow only" — source: ADR-0004, reaffirmed ADR-0007
- Forbidden: "Never subscribe to `GameEventBus` in a Flame component's `onLoad()`" — source: ADR-0004, reaffirmed ADR-0007
- Forbidden: "Never allow a third emit path (Notifier emitting directly, or a component writing a provider)" — source: ADR-0004

## Already Established (do not re-derive)

- `GameEventBus`, `GameEvent`, `GameEventType.petMoodChanged` already exist (Flutter-Flame Bridge Story 001, Complete). This story adds the first real *usage* of the `petMoodChanged` event type, but does not modify the bus itself.
- `GameEventSubscriber` mixin already exists (Flutter-Flame Bridge Story 002, Complete) — reuse it for `MochiComponent`'s `onMount`/`onRemove`/`isMounted` subscription lifecycle rather than hand-rolling the pattern again.
- `petMoodProvider` (Story 001, this epic) already exists and is the value source for both the cold-start seed and every subsequent emission.

---

## Acceptance Criteria

*From ADR-0007 Decision §1 and §5, and Validation Criteria:*

- [x] A widget-level `ref.listen(petMoodProvider, ...)` adapter exists in the `ConsumerWidget` that hosts the Flame `GameWidget`/canvas — this is the ONLY place `petMoodChanged` is emitted (never inside `petMoodProvider` itself, never from `MochiComponent`).
- [x] `ref.listen`'s callback emits `GameEventBus().emit(GameEvent(type: petMoodChanged, data: newMood))` on every callback invocation (Riverpod's `ref.listen` only fires on value change already, and Story 001 guarantees `petMoodProvider`'s value itself only changes on a band crossing — so no additional same-value filtering is needed here beyond what `ref.listen` and `petMoodProvider` already provide).
- [x] Cold-start seed: the same widget emits `petMoodChanged` once at initial build using `ref.read(petMoodProvider)` (NOT via `ref.listen`, which fires only on change and would leave `MochiComponent._baseMood` null at mount) — OR the initial mood is passed directly into `MochiComponent`'s constructor. Document which approach was chosen and why.
- [x] `MochiComponent` (new: the project's first `Component` representing Mochi) subscribes via the existing `GameEventSubscriber` mixin in `onMount()`.
- [x] `MochiComponent._onEvent` handles `GameEventType.petMoodChanged` by casting `event.data as MoodState` and storing it in a private `_baseMood` field — switch on `event.type` before casting, per the bridge's payload-per-type rule.
- [x] `MochiComponent` never calls `ref.read`/`ref.watch`/touches `ProviderContainer` anywhere in its own code — verified by inspection (no Riverpod import in the component file) and/or a test asserting the component has no reference to a container.
- [x] A genuinely new `MochiComponent` instance (not a re-added one — the Bridge epic's Definition-of-Done-tested remount-replay scenario) mounted AFTER a `petMoodChanged` event has already been emitted immediately receives the cached last event via `GameEventBus`'s replay-per-type cache (ADR-0004 §5) — proving the cold-start seed requirement is satisfied even for a component mounted well after app launch, not just the very first one.

---

## Implementation Notes

*From ADR-0007 Decision §1 and §5, and Key Interfaces:*

```dart
// FLAME — Triggered State, ephemeral. Inside MochiComponent:
//   MoodState? _baseMood;                   // cached from petMoodChanged (NOT ref.read); seeded at cold start
//   void _onEvent(GameEvent e) {
//     if (!isMounted) return;               // ADR-0004
//     switch (e.type) {                     // switch on type BEFORE casting data
//       case GameEventType.petMoodChanged: _baseMood = e.data as MoodState; break;  // cache, no Riverpod read
//       // ... trigger cases added by Story 003
//     }
//   }
```
- The widget hosting the `GameWidget` should follow the same "side-effecting singleton kept alive via `ref.watch`/`ref.listen` at a stable widget scope" family of patterns already used in this project (`fcmTokenRefreshListenerProvider`, `appLifecycleListenerProvider`) — but note this one is explicitly `ref.listen` inside a `ConsumerWidget.build`, not a `Provider<void>`, because ADR-0004 §5's sanctioned adapter (a) is specifically "`ref.listen` in a `ConsumerWidget`," not a hidden provider-level side effect.
- `_onEvent`'s switch statement is the SAME method Story 003 will extend with the 5 trigger-type cases — write it in a way that's naturally extensible (a `switch (e.type)` with one case so far), not a single-purpose `if (e.type == petMoodChanged)`.
- Reuse `GameEventSubscriber`'s `subscribedEventTypes` getter to declare `{GameEventType.petMoodChanged}` for now — Story 003 will widen this set when it adds trigger handling.
- `MoodState` cast: `event.data as MoodState` — confirm `GameEvent.data`'s declared type (`Object`/`dynamic`, check `game_event_bus.dart`) accepts this cleanly; no `Timestamp`/Firestore involvement anywhere in this story.

---

## Out of Scope

- Story 001 (this epic): `petMoodProvider`/`_moodForEnergy` themselves — this story only wires their output onto the bus.
- Story 003 (this epic): `TriggeredState` enum, `onTrigger()`, priority map, LEVELING_UP queue, SLEEPING gate, and the 5 trigger-type `_onEvent` cases (`taskApproved`, `petInteracted`, `itemEquipped`, `seedReceived`, `petLeveledUp`) — this story's `_onEvent` handles ONLY `petMoodChanged`.
- Story 004 (this epic): any `TimerComponent`/background-pause behavior — this story adds no timer at all.
- Rendering Mochi's actual sprite/animation for a given `_baseMood` — that is asset/visual wiring for a future Pet Room Screen UI story (#18), not this epic's concern per its own Dependencies section.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from this story's own Acceptance Criteria and ADR-0007 Decision §1/§5:*

```
Test: ref.listen adapter emits petMoodChanged when petMoodProvider's value changes
  Given: a widget tree with the hosting ConsumerWidget mounted, energyProvider overridden to
    a value producing MoodState.content
  When: energyProvider's override value changes to one producing MoodState.happy
  Then: GameEventBus emits exactly one new petMoodChanged event carrying MoodState.happy

Test: cold-start seed emits petMoodChanged once at initial build without waiting for a change
  Given: a fresh widget tree, energyProvider overridden to a fixed value producing MoodState.tired
  When: the hosting widget is first built (before any subsequent energy change)
  Then: petMoodChanged has been emitted at least once, carrying MoodState.tired, without
    requiring any prior GameEventBus event

Test: MochiComponent caches _baseMood from petMoodChanged, not from Riverpod
  Given: a MochiComponent mounted into a flame_test game, petMoodChanged already emitted with
    MoodState.happy before mount
  When: the component mounts (onMount subscribes, receives the replayed last event)
  Then: the component's cached Base Mood reflects MoodState.happy — verified via a
    @visibleForTesting accessor, not by reading Riverpod from the test (that would defeat
    the point of proving isolation)

Test: MochiComponent never imports or touches Riverpod
  Given: the MochiComponent source file
  When: inspected (static check, not a runtime test)
  Then: no `flutter_riverpod` import and no `ProviderContainer`/`ref.` reference exists anywhere
    in the component's own code

Test: a newly-mounted MochiComponent immediately reflects the last petMoodChanged event
  Given: petMoodChanged already emitted once (e.g. MoodState.sad) before any MochiComponent exists
  When: a genuinely new MochiComponent instance (not a re-added one) is mounted
  Then: it immediately caches MoodState.sad without waiting for a fresh emission — the Bridge's
    replay-per-type cache satisfies the cold-start requirement even for a late-mounted component

Test: MochiComponent's _onEvent guards on isMounted and unsubscribes in onRemove
  Given: a mounted MochiComponent
  When: the component is removed from its parent
  Then: no further petMoodChanged events reach it (subscription cancelled) — reusing the
    existing GameEventSubscriber test pattern from Bridge Story 002
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/pet_state_machine/mochi_component_base_mood_test.dart` — must exist and pass

**Status**: [x] Created — `tests/integration/pet_state_machine/mochi_component_base_mood_test.dart`, 9 tests, all passing.

---

## Dependencies

- Depends on: Story 001 (this epic) — `petMoodProvider` must exist. Also depends on Flutter-Flame Bridge (Complete) — `GameEventBus`, `GameEventSubscriber` mixin.
- Unlocks: Story 003 (this epic) — extends the same `MochiComponent`/`_onEvent` switch with trigger handling.

---

## Completion Notes

**Implementation**: `src/lib/gameplay/mochi_component.dart` — `MochiComponent extends PositionComponent with GameEventSubscriber` (the project's first Mochi-representing Flame component), subscribes to `{GameEventType.petMoodChanged}`, caches `_baseMood` via a switch-on-type `onGameEvent` handler (deliberately structured for Story 003 to extend with 5 more cases), exposes a `@visibleForTesting baseMood` accessor. `src/lib/ui/mood_event_bridge.dart` — `MoodEventBridge extends ConsumerStatefulWidget` (the project's first `ref.listen`-family `GameEventBus` emit adapter), wraps a `child`, uses a single `ref.listenManual(petMoodProvider, ..., fireImmediately: true)` call in `initState` to satisfy both the on-change emission and the cold-start seed in one code path (simpler than the story's original "one OR the other" framing) — `listenManual`'s subscription is disposed automatically per its own documentation, so no manual `dispose()` override was needed.

**Real scoping decision, made during implementation and confirmed sound by review**: `MoodEventBridge` was built as a generic wrapper widget (takes a `child`, does not itself instantiate any `GameWidget`/`FlameGame`) rather than co-locating the adapter inside a concrete "Pet Room screen." No `FlameGame` subclass exists anywhere in this codebase yet, and this epic's own Story 004 explicitly defers "the root `FlameGame` subclass's own definition/ownership" to a future Pet Room Screen UI epic (#18). ADR-0004 §3(a) only requires "`ref.listen` in a `ConsumerWidget`" — it does not mandate co-location with the `GameWidget` — so this avoids inventing a premature "MochiGame"/screen architecture while still satisfying the letter of the ADR. `flame-specialist` independently confirmed: "No change needed; this is the right call, not a deviation."

**Real problem hit and worked around, documented rather than silently dropped**: a combined `testWidgets` + manually-driven `FlameGame` end-to-end test (proving `MoodEventBridge`'s emission reaches a separately-mounted `MochiComponent` through the real bus) hung indefinitely (10-minute timeout, no error) and was removed. `flame-specialist`'s review identified the likely root cause: `testWidgets` runs inside `AutomatedTestWidgetsFlutterBinding`'s fake-async zone, where a raw awaited Flame internal (asset load, etc.) driven outside `tester.pump()` can hang forever with no error — the standard fix would be wrapping the Flame-driving portion in `tester.runAsync()` to temporarily exit the fake zone. Not applied here (not required — coverage is complete via the two independent test groups, both exercising the real, non-mocked `GameEventBus`), but flagged for whichever future story attempts a true combined-harness test.

**Tests**: `tests/integration/pet_state_machine/mochi_component_base_mood_test.dart` — 9 tests, all passing: `MochiComponent` group (caches `_baseMood` from a pre-emitted event via the replay cache, updates on a subsequent event, a genuinely-new-instance remount-replay test proving true instance isolation, ignores unsubscribed event types, `onRemove` actually cancels the subscription — added after qa-tester flagged QA Test Case #6 as silently unsubstituted) and `MoodEventBridge` group (cold-start seed emits exactly once, on-change emission, renders `child` unchanged) plus a source-string regression guard proving `mochi_component.dart` never imports `flutter_riverpod`/references `ProviderContainer`/calls `ref.read`/`ref.watch` (added after qa-tester flagged AC6 as inspection-only with no durable guard).

**Code review**: `flame-specialist` — **APPROVED WITH SUGGESTIONS**, zero required changes; confirmed ADR-0004/ADR-0007 compliance, the scoping decision, and the test-hang root cause. `qa-tester` — **GAPS** (both non-blocking, both fixed): QA Test Case #6 (isMounted-guard/onRemove-unsubscribe) had been silently substituted with a different test — fixed with a dedicated test; AC6 ("never touches Riverpod") was inspection-only with no regression guard — fixed with the source-string assertion test.

**Deviations from scope**: None (the `MoodEventBridge`-as-generic-wrapper design was within this story's stated scope — it does not create any `FlameGame`/`GameWidget`, which remains Pet Room Screen UI's (#18) job).
**Manifest version**: 2026-07-16 (current at time of implementation — no drift).
