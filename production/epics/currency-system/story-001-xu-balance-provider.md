# Story 001: xuBalanceProvider (Realtime Balance Read)

> **Epic**: Currency System
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/currency-system.md`
**Requirement**: `TR-currency-004` (fully); `TR-currency-001`, `TR-currency-002`, `TR-currency-003` (documented as binding constraints, not independently implementable here — see Dependency Note below)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008: Currency & Balance Mutation Rules, Decision §4 (`xuBalanceProvider`), §5 (negative-balance defense)

**Engine**: Flutter 3.44.4 / `cloud_firestore ^6.7.1` / `flutter_riverpod ^3.3.2` | **Risk**: LOW — a realtime `StreamProvider` over `.doc().snapshots()` is a stable, pre-cutoff pattern already proven in this codebase (`_activeChildEnergyDocProvider`, Time & Decay Story 002).

**Control Manifest Rules (this layer)**:
- Required: "Single currency (xu) only; all balance changes via `FieldValue.increment(±N)`, never absolute `set()`" — source: ADR-0008
- Required: "`xuBalanceProvider` is a realtime `StreamProvider<int>` scoped to active child, via `FirestorePaths` constant, using the safe nullable AsyncValue accessor (`.value` on `riverpod` 3.x)" — source: ADR-0008
- Required: "`xuBalanceProvider` must NOT be `.autoDispose`" — source: ADR-0008
- Required: "Negative-balance defense: UI displays 0, disables purchases, logs the value; never crash/render negative" — source: ADR-0008
- Required: "Read `xuBalance` as `(x as num?)?.toInt()`, never `as int`" — source: ADR-0008
- Forbidden: "Sources closed to: task approval (+xuReward) and Gacha chest reward only" — source: ADR-0008
- Forbidden: "Sinks closed to: Shop item purchase (−price) and Paid Chest purchase (−50) only" — source: ADR-0008
- Forbidden: "Never expose a Currency-owned guarded-decrement method / centralize the ≥0 floor in Currency or Security Rules" — source: ADR-0008
- Forbidden: "Never implement dual currency / premium coin" — source: ADR-0008
- Forbidden: "Never use absolute `set()` on `xuBalance`" — source: ADR-0008
- Forbidden: "Never use inline Firestore path strings in `xuBalanceProvider`" — source: ADR-0008

## Dependency Note — Why This Epic Is a Single Story

ADR-0008's own Key Interfaces section states plainly: **"there is NO Currency-owned mutation method"** — balance changes happen inside the *earning/spending* systems' own atomic operations:
- Parent Approval (#11): `runTransaction → increment(xuBalance, +task.xuReward)`
- Gacha (#12): `WriteBatch → increment(xuBalance, +xuBonus)`
- Shop (#13): affordability check, then `WriteBatch → increment(xuBalance, -cost)`

**None of these three epics exist yet** (no stories, and Parent Approval/Gacha/Shop don't even have EPIC.md files created in this project as of this session). This means:
- TR-currency-001 (single currency, no dual) and TR-currency-002 (increment-only mutation) have no mutation code in this codebase to write OR to violate yet — they are architectural constraints this ADR imposes on those three future epics, not something buildable now.
- TR-currency-003 (≥0 floor + single-flight guard) is explicitly Shop's (#13) responsibility per Decision §3 — "Currency does not expose a guarded-decrement method."

The ONLY piece of Currency System that is independently buildable today is the **read side**: `xuBalanceProvider`, which this story implements in full. When Parent Approval/Gacha/Shop are eventually built, their own stories must satisfy TR-currency-001/002/003 as constraints — cross-reference this ADR at that time; do not re-derive.

## Real GDD/ADR Drift Found and Corrected

Both the GDD's and the ADR's own `xuBalanceProvider` code sketch use `ref.watch(activeChildProvider)?.id` — but this codebase's actual `ChildProfile` model (auth-account epic, Complete; `src/lib/core/models/child_profile.dart`) has no `.id` field. The field is `.childId`. This story implements the CORRECT field name (`.childId`), not the sketch's stale `.id`. (Separately, the GDD's own snippet was already superseded by the ADR's Migration Plan note about a `QuerySnapshot`/`.data()` compile error — that correction is also already applied below.)

---

## Acceptance Criteria

*From `design/gdd/currency-system.md`'s Acceptance Criteria section and ADR-0008 Decision §4, §5:*

- [x] `xuBalanceProvider` (`StreamProvider<int>`) reads `children/{childId}.xuBalance` via `.doc(FirestorePaths.child(parentId, childId)).snapshots()` — NOT `.collection(...).snapshots()` (which returns a `QuerySnapshot` with no `.data()` — the ADR's own documented compile-error correction).
- [x] Scoped to the active child: uses `ref.watch(activeChildProvider)?.childId` (corrected field name) and `ref.watch(authStateProvider).value?.uid`.
- [x] If no child is active OR no parent is signed in, resolves to `Stream.value(0)` — does not throw, does not hang in a loading state indefinitely.
- [x] Maps the raw Firestore value via `(doc.data()?['xuBalance'] as num?)?.toInt() ?? 0` — handles a missing field (new profile, economy fields not yet initialized) by defaulting to `0`, and handles the int/double Firestore-wire-format ambiguity.
- [x] A negative stored value (bug/rule-bypass scenario) is clamped to `0` at the read/display boundary — never surfaces a negative int to consumers.
- [x] `xuBalanceProvider` is NOT `.autoDispose` — the wallet is always visible; a session-lifetime shared listener is correct, not a per-widget one.
- [x] Uses the centralized `FirestorePaths.child(parentId, childId)` constant — no inline path string.
- [x] Given two rapid `xuBalance` document updates (simulating two concurrent approvals both landing), the stream emits both resulting values in order — no update is silently dropped by the provider's own mapping layer (the underlying atomicity guarantee is Firestore's, per ADR-0003; this story's job is only to prove its own `snapshots()`-to-`int` mapping doesn't introduce its own loss).

---

## Implementation Notes

*From ADR-0008 Decision §4 (the exact provider shape, corrected for the real `ChildProfile.childId` field name):*

```dart
final xuBalanceProvider = StreamProvider<int>((ref) {
  final childId = ref.watch(activeChildProvider)?.childId; // NOT .id — see Drift note above
  final parentId = ref.watch(authStateProvider).value?.uid; // riverpod 3.x safe accessor
  if (childId == null || parentId == null) return Stream.value(0);
  return ref.watch(firebaseFirestoreProvider)
      .doc(FirestorePaths.child(parentId, childId))
      .snapshots()
      .map((doc) => (doc.data()?['xuBalance'] as num?)?.toInt() ?? 0);
});
```
- Use `ref.watch(firebaseFirestoreProvider)` (this project's established DI seam, see `time_decay_providers.dart`) rather than a bare `FirebaseFirestore.instance` static reference — the ADR's own sketch uses the static reference for brevity, but this codebase's established pattern injects it (already deviated correctly for `itemCatalogProvider`, Item Database Story 002 — follow that precedent here too).
- The "negative value clamps to 0" requirement can be satisfied by the SAME `?? 0` fallback style, but note it's a DIFFERENT case from "field missing" — a genuinely negative stored int must ALSO clamp to 0, not pass through. Consider `((doc.data()?['xuBalance'] as num?)?.toInt() ?? 0).clamp(0, ...)`-style logic, or an explicit `final raw = ...; return raw < 0 ? 0 : raw;` — either is acceptable as long as the negative case is provably covered by a test, not just the missing-field case.
- File location: follow this project's established `lib/providers/` convention — `src/lib/providers/currency_providers.dart`.
- This story does NOT implement any write/mutation path — no `spend()`, no `earn()`, nothing that calls `FieldValue.increment()`. Per ADR-0008 Decision §3/Key Interfaces, Currency owns no mutation method at all.

---

## Out of Scope

- Any balance MUTATION (increment/decrement) — owned by Parent Approval (#11), Gacha (#12), Shop (#13), none of which exist yet as epics. This story is read-only.
- The ≥0 floor enforcement / single-flight purchase guard — explicitly Shop's (#13) responsibility per ADR-0008 Decision §3.
- Any UI (wallet display, earn/spend animations, "Còn thiếu X xu" messaging) — Main Nav Shell (#17) and Shop & Reward UI (#20)'s concern.
- Security Rules for `xuBalance` writes — already covered by the existing `children/{childId}` block in `firestore.rules` (client-writable, an accepted MVP tradeoff per ADR-0003 §5 Non-Goals — not this story's concern to revisit).

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0008's Validation Criteria (the subset applicable to the read-only provider; the mutation/race-condition criteria belong to the future Shop/Parent-Approval stories) and this story's own Acceptance Criteria:*

```
Test: xuBalanceProvider reads via .doc().snapshots(), not .collection().snapshots()
  Given: a fake Firestore document at FirestorePaths.child(parentId, childId) with xuBalance=42
  When: xuBalanceProvider is read (with activeChildProvider and authStateProvider both set)
  Then: resolves to 42

Test: xuBalanceProvider resolves to 0 when no child is active
  Given: authStateProvider signed in, activeChildProvider is null
  When: xuBalanceProvider is read
  Then: resolves to 0 (Stream.value(0)) — does not throw, does not hang

Test: xuBalanceProvider resolves to 0 when no parent is signed in
  Given: authStateProvider has no signed-in user, activeChildProvider set to some child
  When: xuBalanceProvider is read
  Then: resolves to 0

Test: xuBalanceProvider defaults to 0 when the xuBalance field is missing
  Given: a fake Firestore document with no xuBalance field at all (new profile)
  When: xuBalanceProvider is read
  Then: resolves to 0

Test: xuBalanceProvider handles xuBalance stored as a double
  Given: a fake Firestore document with xuBalance=42.0 (double, not int)
  When: xuBalanceProvider is read
  Then: resolves to 42 (as an int), does not throw

Test: xuBalanceProvider clamps a negative stored value to 0
  Given: a fake Firestore document with xuBalance=-15 (bug/rule-bypass scenario)
  When: xuBalanceProvider is read
  Then: resolves to 0, never emits a negative value

Test: xuBalanceProvider is not .autoDispose
  Given: a fake Firestore document with xuBalance=10
  When: the provider is read, a listener subscribes and unsubscribes (simulating widget
    unmount), then read again
  Then: the underlying document stream is not re-subscribed from scratch in a way that
    would indicate .autoDispose teardown (verify via a call/subscription counter on the fake)

Test: two rapid document updates both emit through the provider's own mapping, in order
  Given: xuBalanceProvider subscribed with an initial xuBalance=20
  When: the fake document emits two successive snapshot updates, xuBalance=40 then xuBalance=60
    (simulating two approvals both landing)
  Then: the provider's stream emits 20, then 40, then 60 in order — no update silently dropped
    by this provider's own snapshot-to-int mapping layer

Test: uses the centralized FirestorePaths.child constant, no inline path string
  Given: the provider implementation file's source
  When: inspected (static check)
  Then: no inline 'families/' string literal appears — FirestorePaths.child(...) is used
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/currency_system/xu_balance_provider_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/currency_system/xu_balance_provider_test.dart`, 12 tests, all passing.

---

## Dependencies

- Depends on: Auth & Account (Complete) — `activeChildProvider`, `authStateProvider`. Also depends on Data Persistence Layer (Complete) — `FirestorePaths.child()`.
- Unlocks: Main Nav Shell (#17), Shop & Reward UI (#20) — future Presentation-layer epics that display `xuBalanceProvider`. Documents (but does not implement) the constraints Parent Approval (#11), Gacha (#12), and Shop (#13) must satisfy when they eventually mutate `xuBalance`.

---

## Completion Notes

**Implementation**: `src/lib/providers/currency_providers.dart` — `xuBalanceProvider` (`StreamProvider<int>`), scoped to `activeChildProvider`/`authStateProvider`, reads via `.doc(FirestorePaths.child(...)).snapshots()`, injects `firebaseFirestoreProvider` per this project's established DI convention. Two DISTINCT clamp cases correctly separated: `?? 0` for a missing field, then a separate `raw < 0 ? 0 : raw` for a genuinely negative stored value — not conflated into a single expression.

**Real GDD/ADR drift found and corrected before writing any code**: both the GDD's and ADR-0008's own `xuBalanceProvider` code sketch use `ref.watch(activeChildProvider)?.id` — verified directly against `src/lib/core/models/child_profile.dart` that no `.id` field exists on `ChildProfile` (the field is `.childId`). Implemented with the correct field name; `flame-specialist` independently re-confirmed this against the same source file.

**Scoping decision, documented in the story itself before implementation began**: ADR-0008 states plainly there is no Currency-owned mutation method — balance writes belong to Parent Approval (#11)/Gacha (#12)/Shop (#13), none of which exist as epics yet. This made Currency System a single-story epic (the read side only), rather than attempting to build write paths with no real caller.

**Tests**: `tests/unit/currency_system/xu_balance_provider_test.dart` — 12 tests, all passing. Initial 9 covered: correct `.doc()`-not-`.collection()` read, no-active-child→0, no-signed-in-parent→0, missing-field→0, double-typed value coercion, negative-value clamp, not-`.autoDispose` (a subscribe-count fake), two rapid document updates both emit in order (proving the provider's own `.map()` doesn't drop events — explicitly scoped narrower than Firestore's own concurrent-write guarantee, which is ADR-0003's territory, not testable without a live backend), and a static no-inline-path-string check. 3 more added after qa-tester's non-blocking suggestions: a genuine query failure (`FirebaseException`) surfaces as `AsyncError` without crashing (ADR-0008 §5's "never crash" half, for a real failure not just a missing/negative value), switching the active child mid-subscription correctly re-scopes to the new child's own document (not stale-reading the previous one), and signing out mid-subscription resolves to `0`.

**Code review**: `flame-specialist` — **APPROVED**, zero required changes. Independently re-verified the `.childId` correction, the two-distinct-clamp-cases design, DI convention, `.doc()`-not-`.collection()`, no Riverpod anti-patterns, and confirmed the provider is appropriately minimal (no premature `spend()`/`earn()` stub) despite having no live UI consumer yet. `qa-tester` — **TESTABLE**, no blocking gaps; confirmed the race-condition scope boundary (double-tap over-spend, truly-concurrent over-spend) is correctly Shop's (#13) responsibility and correctly untested here since Shop doesn't exist yet — not a gap. Two non-blocking suggestions (query-error surfacing, active-child-switch mid-subscription) — both implemented anyway since they were cheap and meaningful for a Foundation-level provider other epics will depend on.

**Deviations from scope**: None.
**Manifest version**: 2026-07-16 (current at time of implementation — no drift).
