# Story 001: GameEventBus Core (Bus, Event Contract, Replay Cache)

> **Epic**: Flutter-Flame State Bridge
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/flutter-flame-state-bridge.md`
**Requirement**: `TR-bridge-001`, `TR-bridge-002`, `TR-bridge-005`, partial `TR-bridge-006` (local delivery latency only — the end-to-end multi-device latency figure is already spike-validated, see Already Satisfied below)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Flutter-Flame Event Bridge Architecture, Decision §1, §2, §5

**Engine**: Dart (pure — this story imports neither `flutter` nor `flame`) | **Risk**: LOW — `StreamController.broadcast()` is stable, well-understood Dart. The one real design risk (bus-level last-event-per-type replay, not the originally-too-narrow app-background-only version) is already corrected and fully specified in ADR-0004 §5's 2026-07-13 Correction note — this story implements the corrected version directly, not the original.

**Control Manifest Rules (this layer)**:
- Required: "`GameEventBus` is a pure-Dart `StreamController<GameEvent>.broadcast()` singleton, app-lifetime, importing neither Flutter nor Flame" — source: ADR-0004
- Required: "Constructed once at app root; disposed only at app termination, never per-screen" — source: ADR-0004
- Required: "`emit()` guards `!_controller.isClosed` (silent no-op + warning log if called after dispose)" — source: ADR-0004
- Required: "Each `GameEventType` owns a distinct payload shape; payload types must never be shared across event types" — source: ADR-0004
- Required: "`GameEventBus` replays the LAST event per type to any newly-subscribing listener (never full event history)" — source: ADR-0004 (2026-07-13 scope-widened version — see below)
- Required: "`StreamController.broadcast()` created WITHOUT `sync: true`" — source: ADR-0004
- Forbidden: "Never allow a third emit path" — source: ADR-0004 (this story provides only the bus itself; it does not build any adapter — adapters are downstream epics' concern, see Out of Scope)

## Already Satisfied (do not re-derive)

- **TR-bridge-006's end-to-end figure** (avg 151ms / max 439ms, parent-device-approve → child-Mochi-reaction across the full Firestore/FCM chain): already spike-validated in `prototypes/firebase-multidevice-sync-spike-2026-07-03/` (n=8 real trials). Not re-measured by this story — this story only implements and tests the **local** delivery-latency claim (<1ms), which is the part actually exercised by the bus's own code.
- **The replay-scope correction itself**: ADR-0004 §5 already contains the 2026-07-13 "Corrected" note widening the replay requirement from app-background-only to a true bus-level last-event-per-type cache. This story implements that corrected version directly — there is no separate "fix the ADR first" step needed (the epic's own exit-criteria note about this has already been resolved at the ADR level; confirmed by direct read before writing this story).

---

## Acceptance Criteria

*From `design/gdd/flutter-flame-state-bridge.md`'s Acceptance Criteria and Edge Cases, and ADR-0004 Decision §1/§2/§5:*

- [x] `GameEventBus` is a singleton (`factory GameEventBus() => _instance`), backed by a single `StreamController<GameEvent>.broadcast()` instance shared across all calls to the factory.
- [x] `GameEventType` enum has exactly the 7 values from the ADR: `petMoodChanged, seedReceived, itemEquipped, energyChanged, petLeveledUp, petInteracted, taskApproved`.
- [x] `GameEvent` is an immutable class (`type`, `data`) — `const` constructor.
- [x] `emit()` delivers to all current subscribers (test with ≥2 simultaneous subscribers on the same stream).
- [x] `emit()` after `dispose()` is a silent no-op (does not throw) and logs a warning (e.g. via `debugPrint` or a comparable mechanism — no exception surfaces to the caller).
- [x] **Replay cache (the corrected §5 requirement)**: `GameEventBus` caches the most recently emitted `GameEvent` **per `GameEventType`** (not a single global "last event"). A **new** subscriber that starts listening *after* an event of a given type has already been emitted immediately receives that cached event upon subscribing — without any new `emit()` call being made. This must work for a subscriber that starts listening at any point, not just at app cold-start.
- [x] The replay cache holds **only the single most recent event per type**, never a history — emitting 3 `petMoodChanged` events in sequence and then subscribing must deliver only the 3rd (most recent) one, not all 3.
- [x] A type with no cached event yet delivers nothing extra to a new subscriber (no default/placeholder event invented) — the subscriber simply waits for the first real `emit()` of that type, same as today's plain broadcast behavior.
- [x] Local (same-isolate) delivery latency from `emit()` to a subscriber's callback firing is well under 1ms (assert a generous but meaningful bound, e.g. <5ms, in the test — real-world CI timing noise makes asserting the literal "<1ms" figure from the GDD too tight to be a reliable automated assertion; document this reasoning in the test file rather than silently picking an arbitrary number).
- [x] `dispose()` closes the underlying `StreamController` and is intended for app-termination only — no automatic per-screen disposal logic exists anywhere in this story's code (there is nothing in this story that disposes the bus; that's a statement of what does NOT happen, verified by there being no such call site).

---

## Implementation Notes

*From ADR-0004 Decision §1, §2, §5 (Key Interfaces section has the literal starting shape — this story extends it with the replay cache, which the base Key Interfaces snippet does not show):*

- Start from the ADR's Key Interfaces `GameEventBus`/`GameEvent`/`GameEventType` shape, then add the replay-cache map (`Map<GameEventType, GameEvent>`) that `emit()` updates on every call and a new-subscriber path consults.
- The "deliver the cached event to a new subscriber at subscribe time" behavior is naturally expressed as: `stream` should not simply return `_controller.stream` directly if a synchronous replay-on-subscribe is needed — consider whether `Stream.multi()` or a wrapper that emits the cached value before forwarding the broadcast stream is the right shape. Whatever mechanism is chosen, it must preserve the "broadcast, N subscribers, no `sync: true`" requirement from ADR-0004 §5's reentrancy-safety note — do not introduce a synchronous re-entrant callback path while solving the replay-cache requirement.
- `emit()` must update the replay cache **before** or as part of the same call that pushes to `_controller` — a race where a subscriber joins between the `add()` and the cache update must not be possible (this is single-isolate synchronous Dart code, so this is a matter of statement ordering, not real concurrency, but get the order right: update cache, then notify, or ensure both happen atomically within the synchronous `emit()` call).
- This story does NOT build any Flame-side consumption (no `Component`, no `onMount`/`onRemove` pattern) — that is Story 002, and needs `flame_test` as a new dev dependency this story does not add.
- This story does NOT build any Flutter-side `ref.listen` adapter — per ADR-0004 §3(a), that adapter code lives in whichever Riverpod-consuming widget needs to bridge a specific provider, which doesn't exist yet (no downstream system — Pet State Machine, Seed Buffer, etc. — has been implemented). Already documented as a pattern rule in `docs/architecture/control-manifest.md`, applied when those epics build their own widgets.

---

## Out of Scope

- Story 002 (this epic): Flame component subscriber lifecycle (`onMount`/`isMounted`/`onRemove`, the reusable mixin, and the remount-replay integration test using an actual Flame `Component`).
- `TR-bridge-003` (`ref.listen` adapter) — a pattern applied by downstream epics in their own widgets, not a standalone deliverable of this bus-only story.
- Any specific event's payload class beyond the `dynamic data` field on `GameEvent` itself (e.g. `PetMood`, `SeedData`, `InteractionType`) — those types are owned by the systems that produce them (Pet State Machine, Seed Buffer, Pet Interaction respectively), not this bridge story.
- Multi-device / Firestore / FCM latency — already spike-validated, see Already Satisfied above.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0004's Validation Criteria specifies the required coverage:*

> "Unit: `GameEventBus` delivers to N subscribers; `emit()` after `dispose()` is a silent no-op + logs."

```
Test: GameEventBus is a true singleton
  Given: two separate calls to GameEventBus()
  When: compared for identity
  Then: both calls return the exact same instance

Test: emit delivers to multiple simultaneous subscribers
  Given: 2+ active listeners on GameEventBus().stream
  When: emit(GameEvent(petMoodChanged, someValue)) is called
  Then: every listener's callback fires with that exact event

Test: emit after dispose is a silent no-op
  Given: a GameEventBus instance whose controller has been disposed/closed
  When: emit() is called again
  Then: no exception is thrown, and no event reaches any listener
  Edge cases: verify dispose() itself does not throw when called on an
    already-open bus, and that a second dispose() call (double-dispose) also
    does not throw

Test: a new subscriber immediately receives the last cached event of that type
  Given: GameEvent(petMoodChanged, moodA) was already emitted, no active
    listener yet
  When: a new listener subscribes to the stream afterward
  Then: that new listener's callback fires with moodA, without any new
    emit() call being made

Test: the replay cache holds only the most recent event per type, not history
  Given: petMoodChanged emitted 3 times in sequence with different payloads
    (moodA, moodB, moodC), no listener active during any of the 3 emits
  When: a new listener subscribes afterward
  Then: that listener receives only moodC (the most recent) — never all 3,
    never moodA or moodB

Test: a type with no prior emission delivers nothing extra to a new subscriber
  Given: no petLeveledUp event has ever been emitted
  When: a new listener subscribes to the stream
  Then: no event fires for that listener until a real emit(petLeveledUp, ...)
    happens — no synthetic/default event is invented

Test: the replay cache is per-type, not global
  Given: petMoodChanged emitted with moodA, then energyChanged emitted with
    75.0
  When: a new listener subscribes afterward
  Then: it receives BOTH cached events (one per type) — the two types'
    caches do not overwrite or interfere with each other

Test: local delivery latency is well under a documented bound
  Given: a single active listener
  When: emit() is called and a Stopwatch measures time until the listener
    callback fires
  Then: elapsed time is under the documented bound (e.g. 5ms) — comment in
    the test explains why a looser bound than the GDD's literal "<1ms" is
    used for CI-timing-noise reliability
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/bridge/game_event_bus_test.dart` — must exist and pass

**Status**: Created (plus a dedicated `game_event_bus_dispose_test.dart`, split out during code review — see Completion Notes), 11/11 passing across both files

---

## Dependencies

- Depends on: None (pure Dart, no dependency on any other epic's code)
- Unlocks: Story 002 (this epic) — the Flame subscriber lifecycle pattern consumes this bus. Also unlocks every future epic producing or consuming a `GameEvent` (Pet State Machine #6, Seed Buffer #10, Pet Equipment #15, Pet Interaction #14, Pet Leveling #16, Pet Room Screen UI #18).

---

## Completion Notes

**Completed**: 2026-07-16

**Files changed**:
- `src/lib/core/game_event_bus.dart` — new. `GameEventBus` singleton, `GameEvent`/`GameEventType`, per-type replay cache implemented via `Stream.multi()` (verified against the pinned Dart 3.44.4 SDK source before use — its own doc comment includes a near-identical "repeatLatest" reference implementation), `logWarning` test seam for the emit-after-dispose diagnostic.
- `tests/unit/bridge/game_event_bus_test.dart` — new, 9 tests.
- `tests/unit/bridge/game_event_bus_dispose_test.dart` — new, 2 tests, split into its own file during code review (see below) so the singleton's one-way `dispose()` can't poison other tests via file-isolate isolation.

**Criteria**: 10/10 passing, all covered by automated tests.

**Deviations**: None from scope. `Stream.multi()` was used to implement the replay cache rather than the bare `StreamController.broadcast()` shown in the ADR's Key Interfaces snippet — that snippet predates the 2026-07-13 replay-cache correction and doesn't attempt to show the replay mechanism; `Stream.multi()` is the correct tool for per-listener replay-then-forward semantics, not a deviation from the ADR's actual (corrected) requirement.

**Code Review**: Complete — `flame-specialist` + `qa-tester` run in parallel, given the stakes (first-ever code for the project's highest-engine-risk Core system). flame-specialist: **zero required changes** — independently traced the `Stream.multi` mechanics (per-listener independent `onListen`, correct fan-out over the underlying broadcast controller, correct `onCancel` teardown) and confirmed reentrancy safety survives the wrapper. 3 suggestions applied: added `isBroadcast: true` to `Stream.multi()` (was previously reporting `stream.isBroadcast == false`, a latent footgun for any `.where()`/`.map()` derivation listened to more than once); added a reentrancy test proving the class doc comment's claim rather than leaving it unverified; moved the dispose test to its own file. qa-tester: 2 BLOCKING gaps (this is a Logic story), both fixed — added a test proving an already-mounted listener receives BOTH of two rapid same-type events in order (distinct from the replay-cache tests, which only cover a *new* subscriber joining after the fact); added an injectable `logWarning` static seam plus a real test asserting `emit()` actually invokes it after dispose (previously only "does not throw" was tested, not the log itself). Writing these two new tests surfaced a real self-caught bug: both initially failed because the singleton's replay cache — correctly — delivered a stale cached event from an *earlier test in the same file* to the new subscription, which the tests hadn't accounted for; fixed by draining/filtering the replay before asserting on live delivery, not by changing the (correct) production behavior.

**Test Evidence**: `tests/unit/bridge/game_event_bus_test.dart` (9/9) + `tests/unit/bridge/game_event_bus_dispose_test.dart` (2/2) = 11/11 passing. Full suite: 131/131 passing (+1 pre-existing skip, up from 120). `flutter analyze`: clean (10 pre-accepted cosmetic lints, unchanged pattern).

**Retroactive addition (during Story 002's code review, 2026-07-16)**: `resetForTesting()` (a `@visibleForTesting` seam clearing the per-type replay cache) was added to `GameEventBus` after qa-tester flagged that this story's replay-pollution bug (see above) was not a one-off — the same class of bug recurred in Story 002's test suite too, both times only avoided by the implicit, fragile invariant of "each test uses a never-before-emitted `GameEventType`." `game_event_bus_test.dart` now calls `resetForTesting()` in `setUp()` for real per-test isolation. See Story 002's Completion Notes for the full account.
