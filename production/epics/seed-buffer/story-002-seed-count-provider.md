# Story 002: seedCountProvider — Realtime Read with Negative Clamp

> **Epic**: Seed Buffer Mechanic
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: 2 hours
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-17

## Context

**GDD**: `design/gdd/seed-buffer.md`
**Requirement**: `TR-seedbuffer-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: Seed Buffer Derivation Strategy (primary)
**Secondary references**: ADR-0008 (Currency & Balance Mutation Rules — `num?` cast precedent, negative-clamp `StreamProvider` pattern this story mirrors exactly)

**ADR Decision Summary**: ADR-0012 §3 — `seedCountProvider` is a `StreamProvider<int>` that reads `families/{parentId}/children/{childId}` via the centralized `FirestorePaths.child()` constant, casts the raw field as `(x as num?)?.toInt() ?? 0` (Firestore can round-trip a numeric field as either `int` or `double`), and clamps any negative value to `0` before exposing it. This is a pure, directly unit-testable mapping — no Firestore integration required to test the clamp logic itself.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: LOW
**Engine Notes**: No post-cutoff API risk. The `num?` cast and `.value`-not-`.valueOrNull` `AsyncValue` accessor rule (riverpod 3.x, corrected 2026-07-13 per ADR-0002/control-manifest) both apply here exactly as they do to `xuBalanceProvider`.

**Control Manifest Rules (this layer)**:
- ⚠️ The control manifest (Manifest Version 2026-07-16) predates ADR-0012's acceptance and has no Seed-Buffer-specific section yet. Regenerate via `/create-control-manifest update` before this story is treated as the canonical source — until then, apply the Core Layer / Cross-Cutting rules below directly.
- Required: "`xuBalanceProvider` is a realtime `StreamProvider<int>` scoped to active child, via a `FirestorePaths` constant, using the safe nullable AsyncValue accessor (`.value` on riverpod 3.x)" — source: ADR-0008 (Core Layer Rules) — `seedCountProvider` follows the identical shape.
- Required: "`xuBalanceProvider` must NOT be `.autoDispose`" — source: ADR-0008 (Core Layer Rules) — same rule applies here (the Seed Badge is a persistent, frequently-rendered UI element per the GDD's own Visual Requirements).
- Forbidden: "Never use inline Firestore path strings in `xuBalanceProvider`" — source: ADR-0008 (Forbidden Approaches) — `seedCountProvider` must use `FirestorePaths.child(parentId, childId)`, not an inline string (this was the exact defect found and fixed in ADR-0012 during its architecture review).
- Cross-cutting: "Cast Firestore numeric fields as `(x as num?)?.toInt()`/`.toDouble()`, never a direct `as int`" — source: ADR-0006, ADR-0008.

---

## Acceptance Criteria

*From GDD `design/gdd/seed-buffer.md`, scoped to this story:*

- [ ] **AC-4 (Clamp at zero)**: Given `seedCount = 0` in Firestore and a hypothetical double-decrement bug drives the raw stored value negative, when `seedCountProvider` reads the document, then the exposed value clamps at `0` — never negative, never a crash.
- [ ] **AC-6 (partial — read-side data consistency only)**: Given the underlying Firestore document's `seedCount` field reflects a state consistent with 3 already-completed decrements (simulated directly in the test, NOT via a real approve flow — Parent Approval #11 does not exist yet), when `seedCountProvider` reads the document, then it exposes the correct decremented value. **This story does NOT verify**: the xu/energy crediting side of AC-6, the actual `-1` write mechanics, or `pendingTasksProvider`'s entry-removal behavior (owned by Task Library #8, already Accepted and tested in its own epic) — those require Parent Approval (#11) to exist and are out of scope here. Full AC-6 closure is deferred until that epic is written.
- [ ] The provider reads via `FirestorePaths.child(parentId, childId)` — not an inline path string.
- [ ] The provider casts the raw field as `(doc.data()?['seedCount'] as num?)?.toInt() ?? 0`, not `as int?`.
- [ ] The provider returns `Stream.value(0)` when `parentId`/`childId` is null (signed out / no active child) — **corrected from `Stream.empty()`** (ADR-0012 §3's own illustrative snippet used `Stream.empty()`, but the actually-built sibling `xuBalanceProvider` (`src/lib/providers/currency_providers.dart:27`) and `pendingTasksProvider`/`taskHistoryProvider` (`task_providers.dart`) all use `Stream.value(<default>)` — a `StreamProvider` fed `Stream.empty()` never emits, so its `AsyncValue` stays perpetually loading rather than resolving to a usable default; `Stream.value(0)` is what actually matches this story's own "matching the null-guard pattern already established by `xuBalanceProvider`" intent).
- [ ] The provider is NOT `.autoDispose`.

**Performance**: Negligible — one additional realtime `StreamProvider` listener, identical shape to the already-Accepted `xuBalanceProvider` (ADR-0008). One Firestore read per document-change event (the badge's own document, not a query); no new query cost. Mirrors ADR-0012's own Performance Implications (Memory: "no new client-side state beyond the existing `StreamProvider` pattern").

---

## Implementation Notes

*Derived from ADR-0012 §3, mirroring ADR-0008's `xuBalanceProvider` pattern:*

```dart
final seedCountProvider = StreamProvider<int>((ref) {
  final childId = ref.watch(activeChildProvider)?.childId;
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return Stream.value(0);
  return ref
    .watch(firebaseFirestoreProvider)
    .doc(FirestorePaths.child(parentId, childId))
    .snapshots()
    .map((doc) {
      final raw = (doc.data()?['seedCount'] as num?)?.toInt() ?? 0;
      return raw < 0 ? 0 : raw;
    });
});
```

- **Corrected from ADR-0012 §3's illustrative snippet in two ways, found by checking the actually-built sibling `xuBalanceProvider` (`src/lib/providers/currency_providers.dart`) rather than copying the ADR verbatim**: (1) `FirebaseFirestore.instance` → `ref.watch(firebaseFirestoreProvider)` — `src/lib/core/firebase_providers.dart`'s own doc comment mandates this injectable seam for testability ("Every story that touches Firebase Auth, Firestore, or Messaging should depend on these providers rather than reaching for `FirebaseFirestore.instance` directly"); (2) `const Stream.empty()` → `Stream.value(0)` on the null-guard, per the AC correction above. This is also the exact contract from ADR-0012 §3 for the path-constant fix (post-review-fix — the ADR's own snippet originally had an inline path string, corrected during its independent architecture review on 2026-07-17 to use `FirestorePaths.child(...)`).
- Place this alongside the other economy/counter providers (wherever `xuBalanceProvider` and the task providers live) rather than in a new file, unless the project's provider file already has an established per-system split — check `src/lib/providers/` for the current convention before deciding.
- The clamp is intentionally display-only: it does not correct the underlying Firestore document. A transient negative value self-heals via Story 003's drift correction, not via this provider.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **The `seedCount` write side** (+1 on submit) — Story 001 of this epic.
- **Drift correction** (the actual document-level fix for a persistent negative/incorrect value) — Story 003 of this epic.
- **xu/energy crediting and the real `-1` decrement write** — Parent Approval (#11), no epic/ADR exists yet.
- **`pendingTasksProvider` behavior** — Task Library (#8), already Accepted and tested elsewhere; do not re-test it here.
- **Seed Badge UI rendering** (the 🌱 icon, pulse animation, count label) — Main Navigation Shell (#17), no epic exists yet. This story only produces the data the badge will eventually consume.

---

## QA Test Cases

*Test cases not yet defined — run `/qa-plan` to generate them (QL-STORY-READY gate skipped this run per Lean review mode).*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/seed_buffer/seed_count_provider_test.dart` — must exist and pass. Must assert: (1) positive value passes through unchanged, (2) negative raw value clamps to 0, (3) `int`-stored and `double`-stored Firestore values both cast correctly, (4) null/absent field defaults to 0, (5) null parentId/childId resolves to `0` via `Stream.value(0)` rather than throwing or hanging in perpetual loading, (6) a simulated post-3-decrement state reads back the correct value (AC-6 partial, per the explicit scope note above).

**Status**: [x] Created — `tests/unit/seed_buffer/seed_count_provider_test.dart` (12 test functions — 6 required + 3 extra AC checks + 3 covering the FirestorePaths/num?-cast/not-autoDispose criteria), independently re-verified passing (12/12, plus full-suite regression 315 passed/1 pre-existing skip/0 failures, `flutter analyze` clean on `lib/`, test file's lint profile confirmed byte-for-byte identical to the already-Accepted `xu_balance_provider_test.dart` — not a new regression)

### Code Review Notes (2026-07-17)

Reviewed by flame-specialist + qa-tester in parallel. Verdict: **APPROVED WITH SUGGESTIONS**, no blocking issues.
- flame-specialist independently verified (via mutation testing, not just code reading) that both of this story's pre-implementation corrections to ADR-0012 §3's illustrative snippet are real fixes: reverting the injectable Firestore seam broke 7/12 tests; `Stream.empty()` on a `StreamProvider` genuinely leaves it in perpetual `AsyncLoading` (confirmed against installed `riverpod-3.3.2` source).
- qa-tester initially reported `test_seedCountProvider_is_not_autoDispose` as empirically flaky (BLOCKING, ~20% failure rate observed). **Could not reproduce** — 23 independent isolated runs + full-file runs, 0 failures. Most likely explanation: cross-agent interference, since flame-specialist ran in parallel and explicitly reverted this same file mid-review as part of its own mutation test; qa-tester's failure signature (`subscribeCount` stuck at `0`) is exactly what running against a mid-mutation file would produce. Downgraded to non-blocking; noted as a Suggestion to harden the `Future.delayed(Duration.zero)` settle idiom regardless (same pattern pre-exists in the already-Accepted `xu_balance_provider_test.dart`).
- **Suggestions (non-blocking, not applied)**: assert intermediate emitted values in the AC-6 decrement test (currently only start/end); add a negative-double test case; add a non-existent-document (`exists: false`) test case; add the 3 tests present in the sibling but absent here (stream-error→AsyncError, active-child-switch, sign-out-mid-subscription) — none are named ACs in this story, all cheap given working templates already exist in the sibling.

---

## Dependencies

- Depends on: None (independent of Story 001/003; suggested build order is 001 → 002 → 003 to match ADR-0012's own decision order, not a hard dependency)
- Unlocks: None directly — this provider is a leaf read consumed by future Main Navigation Shell (#17) and Task Management UI (#19) work, neither of which is epic'd yet

---

## Completion Notes
**Completed**: 2026-07-17
**Criteria**: 6/6 passing
**Deviations**: None — both real discrepancies found (injectable Firestore seam, `Stream.value(0)` vs `Stream.empty()`) were caught and corrected before implementation, not after
**Test Evidence**: Logic — `tests/unit/seed_buffer/seed_count_provider_test.dart` (12 tests, independently re-verified passing; full suite 315 passed/1 pre-existing skip/0 failures; `flutter analyze` clean)
**Code Review**: Complete — flame-specialist + qa-tester (parallel), verdict APPROVED WITH SUGGESTIONS. See Code Review Notes above for the investigated-but-not-reproduced flakiness claim.
**Non-blocking follow-up items** (not tracked as tech debt — noted here): AC-6 test could assert intermediate decrement values; negative-double and non-existent-document edge cases untested; 3 tests present in the sibling `xu_balance_provider_test.dart` (stream-error, child-switch, sign-out-mid-subscription) have no counterpart here; the `Future.delayed(Duration.zero)` settle idiom (shared with the sibling) could be hardened.
