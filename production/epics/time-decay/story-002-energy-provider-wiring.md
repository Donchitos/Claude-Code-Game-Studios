# Story 002: energyProvider (Firestore-Backed Wiring + Resume Tick)

> **Epic**: Time & Decay
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/time-decay.md`
**Requirement**: `TR-time-decay-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005: Time & Decay Calculation Strategy, Key Interfaces (`energyProvider`, `resumeTickProvider`)

**Engine**: Flutter 3.44.4 / `cloud_firestore ^6.7.1` / `flutter_riverpod ^3.3.2` | **Risk**: LOW — `AppLifecycleListener` is stable since Flutter 3.13 (no post-cutoff drift risk noted by the ADR); the `StreamProvider`/`activeChildProvider` scoping pattern is already established and proven by auth-account's Story 005/008.

**Control Manifest Rules (this layer)**:
- Required: "`energyProvider` needs an explicit `resumeTickProvider` dependency incremented via `AppLifecycleListener(onResume: ...)`" — source: ADR-0005
- Required: "Only `onResume` ticks the resume provider (not pause/inactive)" — source: ADR-0005
- Required: "Child profile/economy fields read via `snapshots()` `StreamProvider` scoped to `activeChildProvider`" — source: ADR-0003 (this is the established, already-proven pattern from auth-account — not new territory)
- Forbidden: "Never route core-loop mutations... through a Cloud Function as the primary path" — N/A here (this story performs zero writes, read-only) — noted for completeness, not because it applies
- Forbidden: this provider must never write to Firestore — it is read + calculate only (ADR-0005 Decision §1, "This system is a reader + calculator")

## Already Established (do not re-derive)

- `activeChildProvider` (a plain `StateProvider<ChildProfile?>`, set once at PIN-verify time by auth-account Story 004/012) holds the **selected child's static profile snapshot** — it is NOT a live Firestore stream and does not contain `storedEnergy`/`lastApprovedAt`/`createdAt`. This story reads those 3 fields via its own dedicated stream, scoped by `activeChildProvider`'s `childId`, not by extending `ChildProfile` (which deliberately excludes economy fields — see that model's own doc comment).
- `FirestorePaths.child(parentId, childId)` already exists (auth-account Story 001/005) — this story's Firestore read uses that same path, it does not add a new path constant.

---

## Acceptance Criteria

*From `design/gdd/time-decay.md`'s Dependencies section and ADR-0005's Key Interfaces:*

- [x] A `resumeTickProvider` (`StateProvider<int>`) exists, incremented by exactly 1 each time the app's `AppLifecycleListener.onResume` callback fires.
- [x] `pause`/`inactive`/other lifecycle callbacks do NOT increment `resumeTickProvider` — only `onResume`.
- [x] The `AppLifecycleListener` is wired once near app root (in `main.dart`, alongside the existing `Firebase.initializeApp`/persistence-settings setup), not per-screen.
- [x] A Firestore-backed read exposes the active child's `storedEnergy` (double), `lastApprovedAt` (nullable DateTime), and `createdAt` (DateTime) — scoped to the currently active child (`activeChildProvider`'s `childId`) and the signed-in parent (`authStateProvider`'s uid), using `snapshots()` (realtime stream), per the established ADR-0003 pattern for active-child economy fields.
- [x] `energyProvider` (`Provider<double>`) watches `resumeTickProvider` (to force recompute on foreground) and the Firestore-backed stream above, then calls Story 001's `computeEnergy(...)` with `now: DateTime.now()` — the one deliberately impure boundary in the whole system.
- [x] `energyProvider` performs zero Firestore writes — verified by inspection/test that no `.set()`/`.update()`/`WriteBatch`/`runTransaction` call exists anywhere in this provider's dependency chain.
- [x] If no child is currently active (`activeChildProvider` is null — e.g. between screens), `energyProvider` does not throw — it returns a sane default (document the chosen default explicitly, e.g. `0` or the last-known value, rather than leaving this undefined) or exposes an `AsyncValue`-style loading/absent state if the provider shape needs to change to accommodate this (flag if so, rather than silently picking one without documenting the reasoning).

---

## Implementation Notes

*From ADR-0005's Key Interfaces section (the exact provider shapes to implement) and Decision §1:*

```dart
final resumeTickProvider = StateProvider<int>((ref) => 0);

// Wired once near app root:
//   AppLifecycleListener(onResume: () => ref.read(resumeTickProvider.notifier).state++)

final energyProvider = Provider<double>((ref) {
  ref.watch(resumeTickProvider);
  final child = ref.watch(activeChildDocProvider); // this story's new StreamProvider
  return computeEnergy(
    storedEnergy: child.storedEnergy,
    lastApprovedAt: child.lastApprovedAt,
    createdAt: child.createdAt,
    now: DateTime.now(),
  );
});
```
- The ADR's sketch shows `activeChildDocProvider` returning a synchronous `child` value directly, but a real `StreamProvider` is `AsyncValue`-wrapped — handle `loading`/`error`/`data` explicitly in `energyProvider` (the ADR's own snippet flags this: "handle loading/error; define a sane default while loading"). Use the safe nullable accessor on the `AsyncValue` (`.value` on this project's pinned `riverpod` 3.x, per `docs/architecture/control-manifest.md`'s dated correction note — NOT `.valueOrNull`, which doesn't exist in this version).
- Define a small internal model (e.g. `_EnergyDoc` or similar, private to this story's file — not a new public model class competing with `ChildProfile`) holding just the 3 fields this story needs (`storedEnergy`, `lastApprovedAt`, `createdAt`), parsed from the raw Firestore document map the same way `ChildProfile.fromFirestore` does it (`data['storedEnergy'] as num).toDouble()`, timestamp fields via `(data['lastApprovedAt'] as Timestamp?)?.toDate()`, etc. — verify the exact `Timestamp` API shape against the installed `cloud_firestore ^6.7.1` source, not assumed.
- `AppLifecycleListener` — confirm its real constructor/callback signature against the installed Flutter 3.44.4 SDK before wiring (the ADR says it's been stable since 3.13 with no drift risk noted, but this project's established practice is to verify post-cutoff-adjacent APIs against real source rather than trust a claim at face value, even a low-risk one).
- If a `storedEnergy` document field is missing/null (a profile that somehow has no economy fields yet — shouldn't normally happen given `initialEnergy = 70` is meant to be set at profile-creation time by whichever future story owns "create child profile," but that story doesn't exist yet either), treat it the same way Story 001 treats `lastApprovedAt == null`: fall back to `initialEnergy = 70` rather than crashing on a null-cast. Document this defensive choice.

---

## Out of Scope

- Story 001 (this epic): `computeEnergy`'s own pure-calculation logic and clock-guard tests — this story only wires real inputs into it.
- Writing `storedEnergy`/`lastApprovedAt` to Firestore at profile-creation time (`initialEnergy = 70` baseline) — no "create child profile" story exists yet anywhere in the project; if a profile is missing these fields, this story's provider must degrade gracefully (see Implementation Notes), not attempt to write a default value itself (this provider performs zero writes, full stop).
- The energy→mood lookup — Pet State Machine's (#6) ownership; this story's `energyProvider` outputs a `double`, nothing else.
- Any UI (energy bar, mood indicator) — Pet Room Screen UI's (#18) responsibility, reading this provider.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from this story's own Acceptance Criteria (ADR-0005's Validation Criteria section focuses on the pure-calculation half, covered by Story 001):*

```
Test: resumeTickProvider increments only on onResume
  Given: a ProviderContainer with resumeTickProvider at its initial value
  When: the AppLifecycleListener's onResume callback is invoked directly (test-simulated,
    not via a real OS lifecycle event)
  Then: resumeTickProvider's value increments by exactly 1

Test: energyProvider recomputes when resumeTickProvider changes
  Given: energyProvider being watched with a fake active-child stream returning a fixed
    storedEnergy/lastApprovedAt
  When: resumeTickProvider is incremented
  Then: energyProvider's value is recomputed (observable via a fresh read, or via a
    listener firing) even if the underlying Firestore data hasn't changed — proving the
    resume-tick dependency actually forces recomputation, not just a coincidental rebuild

Test: energyProvider calls computeEnergy with the real Firestore-backed values
  Given: a fake active-child document stream with known storedEnergy/lastApprovedAt/createdAt
  When: energyProvider is read
  Then: the returned value matches what Story 001's computeEnergy would produce for those
    exact inputs (cross-check against the pure function directly, not a hardcoded expectation)

Test: energyProvider performs zero Firestore writes
  Given: a fake Firestore that would throw/flag if any write method were called
  When: energyProvider is read (including through several resumeTick increments)
  Then: no write method is ever invoked on the fake

Test: no active child does not throw
  Given: activeChildProvider is null
  When: energyProvider is read
  Then: it returns a defined default value without throwing (assert the specific
    documented default, not just "doesn't crash")

Test: missing storedEnergy field on an existing document falls back to initialEnergy=70
  Given: a fake active-child document missing the storedEnergy field entirely
  When: energyProvider is read
  Then: computeEnergy is effectively called with storedEnergy=70 (same fallback as the
    null-lastApprovedAt case), not a crash from an unsafe cast
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/time_decay/energy_provider_test.dart` — must exist and pass

**Status**: [x] Created — `tests/integration/time_decay/energy_provider_test.dart`, 8 tests, all passing.

---

## Dependencies

- Depends on: Story 001 (this epic) — `computeEnergy` must exist first. Also depends on auth-account's `activeChildProvider`/`authStateProvider` (Complete) and Data Persistence Layer's `FirestorePaths.child()` (Complete).
- Unlocks: Pet State Machine (#6) — `petMoodProvider` watches this story's `energyProvider`.

---

## Completion Notes

**Implementation**: `src/lib/providers/time_decay_providers.dart` — `resumeTickProvider` (`StateProvider<int>`), `appLifecycleListenerProvider` (`Provider<void>`, constructs a real `AppLifecycleListener(onResume: ...)` once, disposed via `ref.onDispose`, same "side-effecting singleton kept alive via `ref.watch` at app root" pattern as `fcmTokenRefreshListenerProvider`), private `_EnergyDoc` + `_activeChildEnergyDocProvider` (`StreamProvider`, `snapshots()`-based, scoped to `activeChildProvider` + `authStateProvider`), and `energyProvider` (`Provider<double>`) combining both plus `computeEnergy`. `main.dart` wires `ref.watch(appLifecycleListenerProvider)` at app root alongside the existing FCM listener.

`AppLifecycleListener`'s real constructor/dispose signature was verified directly against the pinned Flutter 3.44.4/3.44.6 SDK source (both this session's direct read and independently by the flame-specialist reviewer) — no drift from the ADR's low-risk claim. `Timestamp`/nullable-cast parsing verified against installed `cloud_firestore ^6.7.1` source (the fake test Firestore's `.snapshots()` override signature had to match the real 3-parameter version — `includeMetadataChanges` + `source: ListenSource`, not just 1 param — caught by a compile error during test-writing, fixed).

**Tests**: `tests/integration/time_decay/energy_provider_test.dart` — 8 tests, all passing:
- `resumeTickProvider` manual-increment sanity check
- **A real `AppLifecycleListener` lifecycle test** (`testWidgets` + `tester.binding.handleAppLifecycleStateChanged`, walking a full realistic `inactive→resumed→inactive→hidden→paused→hidden→inactive→resumed` cycle) proving `onResume` ticks exactly once per genuine resume and pause/inactive/hidden never tick — added after code review flagged the original resumeTick test as only exercising the `StateProvider` directly, never the real `AppLifecycleListener` wiring
- `energyProvider` recompute-across-tick cross-checked against `computeEnergy`'s own output (not just non-null)
- `energyProvider` matches `computeEnergy`'s real output for real Firestore-backed values
- zero Firestore writes across several resumeTick increments
- no-active-child returns the documented `0.0` default
- missing-`storedEnergy` field falls back to `initialEnergy = 70`
- mid-session active-child switch correctly re-subscribes to the new child's own document (added after code review flagged this as an untested edge case)

Uses a hand-rolled minimal Firestore fake (`_FakeFirestore`/`_FakeDocumentReference`/`_FakeDocumentSnapshot`) — first fake in this project to support `.snapshots()` (a live `Stream`, via `Stream.multi`'s replay-then-forward technique, same as `GameEventBus`) rather than only one-shot `.get()`.

**Code review**: `flame-specialist` — **APPROVED WITH SUGGESTIONS**, zero required changes; 3 non-blocking suggestions (all addressed): clarify `createdAt` fallback comment, clarify `energyProvider`'s doc comment re: the `0.0` sentinel also covering the brief loading window, and a note to re-run ADR-0005's own `cloud_firestore` version smoke-check (not required — `.difference()`-based math is zone-safe by construction).

`qa-tester` — **GAPS** (1 flagged as BLOCKING-adjacent, 3 non-blocking): (1) `appLifecycleListenerProvider`'s real `onResume` wiring was untested — **fixed** with the new `testWidgets` lifecycle test described above; (2) the resumeTick-recompute test only asserted non-null, not a real cross-check — **fixed**, now cross-checks against `computeEnergy` directly (a strict before/after inequality assertion was deliberately avoided as it would be a time-dependent assertion, forbidden by `.claude/rules/test-standards.md`); (3) loading-vs-no-active-child `AsyncValue` state ambiguity — addressed via a doc-comment clarification only (flame-specialist independently confirmed this is ADR-sanctioned behavior, not a bug; a deterministic test for the loading-window state isn't feasible with the current fake's synchronous `Stream.multi` emission without contriving an artificial delay); (4) mid-session active-child switch untested — **fixed** with a new test.

**Deviations from scope**: None.
**Manifest version**: 2026-07-16 (current at time of implementation — no drift).
