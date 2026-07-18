# Story 002: Flame Component Subscriber Lifecycle Pattern

> **Epic**: Flutter-Flame State Bridge
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/flutter-flame-state-bridge.md`
**Requirement**: `TR-bridge-004`, and the Definition of Done's explicit remount-replay test requirement (which spans `TR-bridge-004` + `TR-bridge-005`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Flutter-Flame Event Bridge Architecture, Decision §4 (subscriber lifecycle) + §5 (replay, consumed here for the remount integration test)

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: MEDIUM — Flame component lifecycle idioms are post-cutoff (`Component.isMounted`, `onMount()`/`onRemove()` semantics). ADR-0004 already source-verified the `onMount()`-not-`onLoad()` requirement against real Flame 1.37 source (2026-07-07) — this story implements against that already-verified finding, it does not need to re-derive it, but the implementation itself (a reusable mixin) is new code that has not been built or tested against a real `FlameGame` harness yet in this project.

**Control Manifest Rules (this layer)**:
- Required: "Flame subscribers subscribe in `onMount()`, NOT `onLoad()`" — source: ADR-0004
- Required: "Handler guards `if (!isMounted) return;`" — source: ADR-0004
- Required: "`_sub?.cancel()` MUST be called in `onRemove()`" — source: ADR-0004
- Required: "Use `isMounted` (not `parent != null`)" — source: ADR-0004
- Forbidden: "Never subscribe in `onLoad()`" — source: ADR-0004
- Forbidden: "Do not copy the reference spike's `onLoad()` subscribe pattern into production" — source: ADR-0004

## Already Established (do not re-derive)

- This is the **first** story in the project to write real Flame `Component` code — no `FlameGame`/`Component` subclass exists anywhere in `src/lib` yet. There is no prior in-repo pattern to match against (unlike, say, the Cloud Functions toolchain, which auth-account Story 009 already established).
- `flame_test` is **not yet a dependency** of this project (`src/pubspec.yaml` has `flame: ^1.37.0` as a runtime dependency but no `flame_test` dev dependency). This story adds it — flagged here rather than discovered mid-implementation.

## Design Decision (user-approved, 2026-07-16)

Rather than requiring every future Flame component (`MochiComponent`, `SeedBagComponent`, `EnergyBarComponent`, etc.) to hand-roll the `onMount`/`isMounted`/`onRemove` boilerplate from ADR-0004 §4's raw code snippet, this story builds a **reusable mixin** that encapsulates the correct lifecycle once. This is in-scope for this epic specifically because ADR-0004's own Ordering Note says this ADR "owns... the subscriber lifecycle" (unlike, e.g., Data Persistence Layer's ADR-0003, which explicitly does NOT own per-system write logic) — the lifecycle pattern itself, not just its documentation, is this epic's responsibility. A shared mixin converts the ADR's own stated risk ("Subscriber correctness is a manual discipline... not compiler-enforced") into something closer to compiler-enforced-by-reuse for every future consumer.

---

## Acceptance Criteria

*From `design/gdd/flutter-flame-state-bridge.md`'s Core Rule 5, Edge Cases, and Acceptance Criteria; ADR-0004 Decision §4:*

- [x] A reusable mixin (applied to a `Component`) subscribes to `GameEventBus().stream` in `onMount()`, never in `onLoad()`.
- [x] The mixin's event-handling path checks `isMounted` before processing an event and silently returns (no exception, no side effect) if the component is not mounted.
- [x] The mixin cancels its `StreamSubscription` in `onRemove()` — verified by a test that removes a component and then confirms no further processing occurs even if the bus is holding a reference to a callback that would otherwise still fire.
- [x] A component using the mixin, when removed from the game tree while an event is "in flight" conceptually (i.e. the component becomes unmounted), does not throw and does not apply any visual/state effect.
- [x] **Remount-replay integration test (the Definition of Done's explicit requirement)**: a test that (a) mounts a component instance using the mixin, (b) removes it from the game tree, (c) emits a `GameEvent` of some type while no component of that type is mounted, (d) mounts a **brand-new** component instance (not the same instance re-added — a genuinely new instance, matching the real bug class the vertical slice found: navigation recreating a widget/component), and (e) asserts the new instance receives that event's cached value immediately upon its own `onMount()`, without requiring a fresh `emit()` call after step (d).
- [x] Two rapid same-type events delivered to a mounted component are processed in order, and the component's applied state reflects only the second (most recent) one — matching the GDD's "prior effect cleared" edge case (this test can use a minimal test double for "effect" — e.g. a component that just records the last event's data — it does not need real animation/effect code, which belongs to the systems that actually consume events).
- [x] A component's `_onEvent`-equivalent handler in the mixin (or the pattern it enforces for subclasses) checks `event.type` before doing anything with `event.data` — demonstrated via a test double component that only reacts to one specific `GameEventType` and ignores all others without attempting to cast their payloads.

---

## Implementation Notes

*From ADR-0004 Decision §4 (the literal pattern to generalize into a mixin) and the GDD's Core Rule 5 code block (same pattern, GDD-side):*

- Add `flame_test` as a dev dependency in `src/pubspec.yaml`, matching the already-pinned `flame: ^1.37.0` version line (resolve whatever compatible `flame_test` version `flutter pub add --dev flame_test` picks — do not hand-guess a version).
- Use `flame_test`'s `testWithFlameGame`/`FlameTester` (or whatever the actually-resolved package version's real API surface is — verify via the installed package source, not from training-data assumptions, per this project's established practice for any post-cutoff API) to mount components against a minimal `FlameGame` harness — this story does not need a real `PetRoomScreen`/`GameWidget`, just enough of a game harness for `onMount`/`onRemove` to fire realistically.
- The mixin's exact shape (a `mixin GameEventSubscriber on Component` or similar) is an implementation-agnostic detail per the ADR — the ADR only fixes the *behavior* (subscribe in onMount, guard, cancel in onRemove), not a specific abstraction shape. Design the mixin so a concrete component can specify which `GameEventType`(s) it cares about and provide a callback, without needing to re-derive the subscription/guard/cancel mechanics itself.
- The remount-replay test is the single most important test in this story — it is the exact bug class the vertical slice found in production-adjacent conditions (a Flame-canvas-hosting screen dynamically remounted, e.g. by navigation) and is explicitly called out in this epic's Definition of Done as a required, named test — do not treat it as "just another edge case."
- This story consumes Story 001's `GameEventBus` replay-cache behavior as a black box — it should not need to re-implement or duplicate that caching logic, only prove that a Flame component correctly benefits from it when it subscribes.

---

## Out of Scope

- Story 001 (this epic): the bus's own replay-cache mechanism — this story tests that a Flame component *benefits* from it, not the cache's own internal correctness (already covered by Story 001's tests).
- Any real event-payload type or real visual effect (`PetMood`, `ScaleEffect`, sprite swaps, etc.) — this story's test components are minimal test doubles that just record what they received, not real game-visual components. Those belong to the systems that actually implement them (Pet State Machine #6 and later).
- The `ref.listen` Flutter-side adapter (`TR-bridge-003`) — still not independently implementable, same reasoning as Story 001's Out of Scope.
- Building any actual `PetRoomScreen`/`GameWidget`/real `FlameGame` subclass for the app — this story only needs `flame_test`'s minimal test harness, not production game-screen scaffolding (that belongs to Pet Room Screen UI #18).

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0004's Validation Criteria specifies the required coverage:*

> "Component test: `MochiComponent` applies the visual on `petMoodChanged` within one frame (<16.6ms); ignores events after `onRemove()` with no exception."
> "Component test: two rapid same-type events → only the second effect shows (prior cleared)."
> "Type-safety test: each `GameEventType` handler rejects/does-not-cast a mismatched payload (guards against the `TypeError` class)."

*(These reference `MochiComponent` specifically, which doesn't exist yet — the test cases below apply the same required coverage to this story's minimal test-double component instead, since `MochiComponent` itself belongs to a future Pet State Machine story.)*

```
Test: mixin subscribes in onMount, not onLoad
  Given: a test-double component using the subscriber mixin, mounted into a
    minimal FlameGame harness via flame_test
  When: an event of the subscribed type is emitted after onMount has run
  Then: the component's handler fires and records the event

Test: handler no-ops silently after the component is removed
  Given: a mounted test-double component, then removed from the game tree
  When: an event of the subscribed type is emitted after removal
  Then: no exception is thrown, and the component's recorded-event state is
    unchanged from before removal (proves the isMounted guard AND the
    cancelled subscription both work — either alone would prevent this)

Test: onRemove cancels the subscription (not just relying on isMounted)
  Given: a mounted test-double component
  When: it is removed, and then a way is found to prove the underlying
    StreamSubscription is actually cancelled (not just that the guard
    happens to catch it) — e.g. inspect subscription state if the mixin
    exposes it for testing, or count callback invocations before/after
  Then: the subscription is confirmed cancelled, not merely guarded

Test: two rapid same-type events — only the second is reflected
  Given: a mounted test-double component
  When: two events of the same type are emitted in quick succession with
    different payloads
  Then: the component's final recorded state reflects only the second
    event's payload

Test: a mismatched-type event is ignored without a cast error
  Given: a mounted test-double component subscribed only to petMoodChanged
  When: an energyChanged event is emitted
  Then: no exception occurs, and the component's recorded state is
    unaffected (proves the type-check-before-cast discipline holds even in
    a minimal test double)

Test: remount replay — the Definition of Done's required scenario
  Given: component instance A mounted, then removed; an event emitted while
    no component of that type is mounted; component instance B (a genuinely
    new instance, not A re-added) then mounted
  When: B's onMount runs and it subscribes
  Then: B immediately reflects the cached event's payload, without any new
    emit() call after B was created
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/bridge/game_event_subscriber_test.dart` — must exist and pass

**Status**: Created, 7/7 passing

---

## Dependencies

- Depends on: Story 001 (this epic) — the `GameEventBus` and its replay cache must exist first.
- Unlocks: Every future Flame component that needs to react to a `GameEvent` (Pet State Machine #6's `MochiComponent`, Seed Buffer #10's `SeedBagComponent`, Pet Equipment #15's `PetEquipComponent`, etc.) — they can use this story's mixin instead of re-deriving the lifecycle pattern.

---

## Completion Notes

**Completed**: 2026-07-16

**Files changed**:
- `src/pubspec.yaml` — added `flame_test: ^2.2.4` (dev dependency) and `meta` (promoted from transitive to direct — needed for `@visibleForTesting`).
- `src/lib/core/game_event_subscriber.dart` — new. `mixin GameEventSubscriber on Component`: subscribes in `onMount()`, `isMounted`-guards, cancels in `onRemove()`; `subscribedEventTypes` (a `Set<GameEventType>` getter) structurally enforces "check type before casting data" — only subscribed types ever reach `onGameEvent`; `hasActiveGameEventSubscription` test-only seam proving `onRemove` genuinely nulls the subscription, not just that `isMounted` masks delivery.
- `tests/integration/bridge/game_event_subscriber_test.dart` — new, 7 tests (6 original + 1 cross-contamination test added in code review), using `flame_test`'s `testWithFlameGame`/`ensureAdd`/`ensureRemove`/`ensureAddAll` (verified against the installed `flame_test-2.2.4` source before use, not assumed).
- `src/lib/core/game_event_bus.dart` — added `resetForTesting()` (see Story 001's Completion Notes — added retroactively during this story's review, and Story 001's own test files were updated to use it too).

**Criteria**: 7/7 passing, all covered by automated tests. The remount-replay test (`test_remount_replay_a_brand_new_component_instance_immediately_reflects_the_cached_event`) — the Definition of Done's explicitly required scenario — uses a genuinely new `_RecordingComponent` instance (`componentB`), not `componentA` re-added, matching the real bug class the vertical slice found (navigation recreating a component/widget), confirmed independently by flame-specialist's review.

**Deviations**: None from scope. `flame_test` version resolved to `2.2.4` via `flutter pub add --dev flame_test` (not hand-picked). The mixin's API shape (`Set<GameEventType> subscribedEventTypes` + `onGameEvent(GameEvent)`) was designed during implementation, not specified verbatim by the ADR — consistent with the story's own note that the ADR fixes behavior, not a specific abstraction shape.

**Code Review**: Complete — `flame-specialist` + `qa-tester` run in parallel, given this is the first-ever Flame component code in the project. flame-specialist confirmed exact ADR-0004 §4 compliance (call order matches the ADR's snippet line-for-line), confirmed the remount test's rigor, confirmed correct `flame_test` API usage against the installed source, and confirmed scope discipline. flame-specialist also flagged one "Required Change" (an `invalid_use_of_visible_for_testing_member` warning on `hasActiveGameEventSubscription`, attributed to this project's `tests/` (plural) directory naming not being recognized by the analyzer's test-path heuristic) — **independently investigated and found to be a false positive**: it was produced by running `dart analyze` on a single file outside proper package-resolution context (the same class of working-directory/invocation problem this session has hit before), not reproducible via this project's actual, reliable `flutter analyze` (full project, run from `src/`), which shows zero issues related to this member both before and after the investigation. Not acted on; documented here rather than silently dismissed. qa-tester found 2 real gaps, both fixed: (1) a systemic issue — `GameEventBus` had no test-only reset mechanism, and this was the 3rd occurrence across Story 001+002's test suites of a bug where the singleton's replay cache correctly delivered a stale event from an earlier test to a new one — fixed by adding `resetForTesting()` (a `@visibleForTesting` seam) and wiring it into `setUp()` across all 3 bridge test files, removing the fragile "each test must use a never-before-used `GameEventType`" implicit invariant; (2) added the missing two-simultaneous-components-different-types cross-contamination test.

**Test Evidence**: `tests/integration/bridge/game_event_subscriber_test.dart` (7/7 passing). Full suite: 138/138 passing (+1 pre-existing skip, up from 131). `flutter analyze`: clean (10 pre-accepted cosmetic lints, unchanged pattern).
