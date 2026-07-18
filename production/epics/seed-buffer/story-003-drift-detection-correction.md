# Story 003: Drift Detection & Correction — onTaskApproved Extension

> **Epic**: Seed Buffer Mechanic
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 4 hours
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-17

## Context

**GDD**: `design/gdd/seed-buffer.md`
**Requirement**: `TR-seedbuffer-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: Seed Buffer Derivation Strategy (primary)
**Secondary references**: ADR-0003 §6 (Firestore Schema & Persistence Strategy — owns the `onTaskApproved` Cloud Function this story extends), ADR-0009 (Task Lifecycle & Reward Integrity — established the precedent of reusing `onTaskApproved` for a second, unrelated reconciliation concern)

**ADR Decision Summary**: ADR-0012 §4 — drift correction is a `runTransaction`-based reconciliation that runs ONLY inside the existing `onTaskApproved` Cloud Function (ADR-0003 §6 — an `onDocumentUpdated` trigger on the child document; never client-triggered). It reads the actual pending count (`tasks` where `status == 'pending'`) and the current `seedCount` in the same transaction; if they differ, it writes the corrected value within that transaction. This is a scoped, registered exception to the `absolute_set_on_balance_or_counters` forbidden pattern (see `docs/registry/architecture.yaml`, `api_decisions.seedcount_drift_correction`) — justified because the forbidden pattern's rationale is multi-device CLIENT races, which do not apply to a server-only, transactional, idempotent correction that recomputes from source of truth rather than blind-decrementing.

**Engine**: Node.js/TypeScript (Cloud Functions runtime — `functions/`, NOT the Flutter/Dart runtime; see `docs/architecture/adr-0002-auth-pin-security-architecture.md` §8 for why this is a separate stack) | **Risk**: LOW, with one open verification item
**Engine Notes**: `firebase-functions ^7.2.5` / `firebase-admin ^13.10.0` per the project's pinned Cloud Functions dependencies. This story's transaction reads a **collection query** (`tasks where status == 'pending'`) inside `runTransaction` — this is supported server-side via the Admin SDK but has not been independently emulator-verified on this project. Given this project's own prior history of an unverified Firestore-API assumption being wrong (ADR-0003's 2026-07-13 correction, `Settings`/`PersistentCacheSettings`), confirm this specific pattern (query-inside-transaction via Admin SDK) works as expected before considering this story done — via the Firestore emulator if available, or the project's established `jest.mock`-against-`firebase-admin` substitute if not (per `functions/test/*.test.ts` header comments — no Java runtime is available in this dev environment, so the emulator suite cannot run here).

**Control Manifest Rules (this layer)**:
- ⚠️ The control manifest (Manifest Version 2026-07-16) predates ADR-0012's acceptance and has no Seed-Buffer-specific section yet. Regenerate via `/create-control-manifest update` before this story is treated as the canonical source — until then, apply the Core Layer rules below directly.
- Required: "`onTaskApproved` Cloud Function (2nd-gen `onDocumentUpdated`) caps `storedEnergy` at 100 post-commit" — source: ADR-0003 (Core Layer Rules) — this story adds a SECOND concern to the same function, following the precedent ADR-0009 already set by adding reward reconciliation to it.
- Required: "`runTransaction` for read-before-write mutations... idempotency read must be the FIRST read inside the transaction" — source: ADR-0003 (Core Layer Rules).
- Forbidden: "Never use absolute `set()` on a balance or counter field — always `FieldValue.increment()`" — source: ADR-0003/ADR-0008 (Cross-Cutting Constraints). **This story is the one place in the codebase where a scoped exception applies**: the drift-correction write IS an absolute `set()` on `seedCount`, and that is deliberate and registered (`seedcount_drift_correction` in `docs/registry/architecture.yaml`) — do not "fix" this to an increment; recomputing from source of truth is the entire point.
- Note (`onTaskApproved` triggers on ANY child-doc update — buy, equip, level-up, approve, reject all touch it): the existing function is self-limiting/idempotent by design (ADR-0003 §9). This story's addition must preserve that — the drift check should be cheap to no-op when there's no actual drift, so it doesn't meaningfully add cost to the many non-approval writes that also trigger this function.

---

## Acceptance Criteria

*From GDD `design/gdd/seed-buffer.md`, scoped to this story:*

- [ ] **AC-8 (Drift recalculation)**: Given `seedCount` has drifted from the actual pending-task count (worked example from the GDD: `seedCount` stored as 5, actual pending count = 3), when `onTaskApproved` next processes an update, then `seedCount` is recalculated and corrected to the actual pending count (3) — NOT just decremented from the wrong stored value (i.e. the fix must be a fresh recompute, not `5 - 1 = 4`).
- [ ] The pending-count query and the `seedCount` read both happen INSIDE the same `runTransaction` (not read separately before the transaction opens) — this is what makes the correction safe under concurrent client increments (a concurrent write forces Firestore's automatic contention-retry, so the idempotent recompute cannot lose a write).
- [ ] When `seedCount` already equals the actual pending count (the common case — no drift), the transaction performs no write (or the equivalent no-op) — this must not become an unconditional `set()` on every single trigger invocation, which would defeat the "scoped, narrow exception" justification and add needless write cost to a function that fires on nearly every child-doc update.
- [ ] The correction is idempotent — running it twice in a row (e.g. due to Cloud Functions' at-least-once/retry semantics) produces the same correct result both times, with no double-application artifact.

**Performance**: The drift check must be a no-op write when `seedCount` already matches (per the AC above) — this keeps added cost negligible on the many non-approval writes that also trigger `onTaskApproved` (buy, equip, level-up). The one added cost is the pending-task query read inside the transaction, bounded by the child's own pending-task count (already a small, capped set per the GDD's own `seed_pending_list_max`-adjacent bounds). No new network round-trip — this runs inside the already-firing `onTaskApproved` invocation, not as a separate call (ADR-0012 Performance Implications).

---

## Implementation Notes

*Derived from ADR-0012 §4, corrected against the actual current state of `functions/src/index.ts` (2026-07-17) — the original plan below assumed `onTaskApproved` already used a transaction. It does not:*

**Real discrepancy found before implementation**: `onTaskApproved` (`functions/src/index.ts:93-98`) is a thin `onDocumentUpdated` wrapper that calls `enforceStoredEnergyCap(event.data?.after)` — a plain, non-transactional `afterSnapshot.ref.update(...)` (`:76-91`). There is no existing `runTransaction` anywhere in this file to "reuse" — **this story adds the first one in this codebase's Cloud Functions**. This does NOT change the design: ADR-0012 §4's safety argument (the transaction is what forces Firestore's contention-retry against a concurrent client `increment`, making the recompute-and-correct safe) genuinely requires a real transaction — it cannot be weakened to match `enforceStoredEnergyCap`'s simpler non-transactional style just for consistency. The two checks (energy cap, drift correction) will simply be two independent operations inside the same trigger invocation: `enforceStoredEnergyCap` (unchanged, direct update) and a new `reconcileSeedCountDrift` (its own `runTransaction`).

- Locate the existing `onTaskApproved` handler in `functions/src/index.ts:93-98`. Add a second call inside its body: `await reconcileSeedCountDrift(event.data?.after);` alongside the existing `enforceStoredEnergyCap` call — do not remove or alter that call.
- New helper `reconcileSeedCountDrift`, extracted as a plain, directly unit-testable function (same split as `enforceStoredEnergyCap`/`reconcileTaskReward` — accepts the already-read `afterSnapshot`, no-ops on `undefined`, matching the established no-op-on-common-case discipline):
  1. Call `getFirestore().runTransaction(async (transaction) => { ... })` — `getFirestore()` is imported inline per-call already (`import { getFirestore } from "firebase-admin/firestore"`), matching this file's existing convention (no cached `db` singleton exists here — don't introduce one).
  2. Inside the transaction: query the pending-task count via `transaction.get(getFirestore().collection(\`families/${parentId}/children/${childId}/tasks\`).where("status", "==", "pending"))` — there is no Node-side path-constants module (unlike Dart's `FirestorePaths`); this file builds paths as inline template literals everywhere (see `:323-324`), so match that convention, don't invent a new one.
  3. Also inside the transaction: read the current `seedCount` from `afterSnapshot.data().seedCount` (already available from the trigger's own `after` snapshot — no extra read needed for this half, since the trigger already delivers the full post-write child document).
  4. If `actualPendingCount !== seedCount`, `transaction.update(afterSnapshot.ref, { seedCount: actualPendingCount })` — an intentional absolute value, not an increment, per the registered exception (`docs/registry/architecture.yaml`'s `seedcount_drift_correction`).
  5. If they match, no write.
- `parentId`/`childId` for the query path: available from the Cloud Function's own path params (`event.params.parentId`/`event.params.childId`) in the `onTaskApproved` wrapper — pass them into `reconcileSeedCountDrift` alongside the snapshot, since the extracted function itself has no access to `event.params`.
- This is server-only and never client-triggered — do not add any client-side code that attempts to invoke or simulate this correction.
- **Test scaffolding note**: `functions/test/index.test.ts`'s current `jest.mock("firebase-admin/firestore", ...)` only provides `recursiveDelete` and `doc` mocks (`:52-57`) — it has no `runTransaction` or `collection`/`where` mock yet, since no prior story needed one. This story must add that scaffolding: a `runTransactionMock` that invokes the callback with a fake `transaction` object exposing `.get()` (returning a mock query snapshot with a controllable `.size`/`.docs.length`) and `.update()` (recorded, assertable). Since no Firestore emulator is available in this dev environment, this mocked-transaction approach is the only feasible test strategy — follow the existing pattern's spirit (plain-function extraction + `jest.mock`) rather than inventing an emulator-dependent test.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **The `seedCount` write side** (+1 on submit) — Story 001 of this epic.
- **`seedCountProvider`'s read/clamp logic** — Story 002 of this epic (this story corrects the underlying document; it does not touch the client-side read path).
- **The `-1` decrement write on approve/reject** — Parent Approval (#11), no epic/ADR exists yet. This story only corrects drift; it does not implement the primary decrement.
- **Real-device/emulator verification of the transaction-with-query pattern** beyond what `jest.mock` can substitute for — flagged as an open item in Engine Notes above; do not claim this is fully verified if only mocked.

---

## QA Test Cases

*Test cases not yet defined — run `/qa-plan` to generate them (QL-STORY-READY gate skipped this run per Lean review mode).*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `functions/test/index.test.ts` (extends the existing suite) — must exist and pass. Must assert: (1) drift is detected and corrected to the true recomputed pending count, not a naive decrement, (2) no write occurs when `seedCount` already matches, (3) the transaction reads both values before any write (ordering), (4) idempotent on repeated invocation, (5) does not interfere with the existing storedEnergy-cap / reward-reconciliation logic already in `onTaskApproved`.

**Status**: [x] Created — extends `functions/test/index.test.ts` (12 test functions total for this story: 9 from initial implementation + 3 added during code review — a regression test for the transactional-read fix, an `undefined`-seedCount edge case, and a failed-transaction propagation test — plus 5 pre-existing `onTaskApproved.run`/`enforceStoredEnergyCap` tests updated for the corrected two-read mock sequence), independently re-verified passing (72/72 full suite; `npx tsc --noEmit` clean). New `runTransaction`/`collection`/`where`/`get` mock scaffolding added — the first story needing transaction mocking in this codebase's Cloud Functions test suite.

### Code Notes (2026-07-17)

**Real discrepancy found before implementation**: the story originally assumed `onTaskApproved` already used a `runTransaction` to reuse — it didn't (a plain `.update()` via `enforceStoredEnergyCap`). This is the FIRST `runTransaction` in this codebase's Cloud Functions. Corrected in the Implementation Notes above before implementation began; the design itself (a real transaction is required for ADR-0012 §4's safety argument) was not weakened to match the simpler existing style.

**Second discrepancy found during implementation, handled transparently**: Test Evidence item (5) ("does not interfere with the existing... reward-reconciliation logic already in `onTaskApproved`") doesn't match the actual code — `reconcileTaskReward` was never in `onTaskApproved`; it lives on a separate trigger (`onTaskRewardReconciliation`, watching `tasks/{taskId}`, not the child document). Since this story's change cannot touch a different trigger's code path by construction, non-interference with that suite is evidenced by its own tests continuing to pass unmodified — documented explicitly in a test-file comment rather than writing a misleading test pretending to exercise a trigger this story never touches.

### Code Review Notes (2026-07-17) — real correctness bug found and fixed

security-engineer + qa-tester (parallel, independent) both converged on the same root finding from different angles — strong corroboration, not a false alarm: **`reconcileSeedCountDrift` read `seedCount` from `afterSnapshot.data().seedCount`, a snapshot captured by the Cloud Functions trigger BEFORE the transaction opened, not via a real `transaction.get()` inside the transaction.** Only the pending-count query was a genuine transactional read. Firestore's optimistic-concurrency contention-retry only protects documents actually `.get()`'d *inside* the transaction — a `transaction.update()` on a document never read inside that same transaction carries no precondition and is effectively an unconditional write. This directly undermines ADR-0012 §4's own safety argument (and its own Key Interfaces, which explicitly list "read current seedCount" as its own transactional step) and the Control Manifest's "idempotency read must be the FIRST read inside the transaction" rule the story itself quotes.

security-engineer's more nuanced framing: this happened to still be safe *today* only by an unenforced convention — every current legitimate `seedCount` writer also touches a `tasks/{taskId}` document, which the pending-count query's own contention-retry would indirectly catch. But that's accidental, not structural, and would silently break the moment any future write path (a migration, an admin tool, Parent Approval #11's not-yet-written implementation) touched `seedCount` without a coupled `tasks` write.

**Fixed**: `reconcileSeedCountDrift` now does `const childSnapshot = await transaction.get(afterSnapshot.ref); const seedCount = childSnapshot.data()?.seedCount;` as its first transactional read (before the pending-count query), matching ADR-0012 §4's literal two-read design. Doc comments corrected to describe the actual (now real) safety mechanism instead of the aspirational one. Also fixed, per the same reviewers' secondary findings: the doc comment overclaiming the no-op guard is "free" (the query read itself is a billed cost on every invocation, drift or not); the idempotency test previously used two different hand-built snapshots rather than the same stale object Cloud Functions' real at-least-once redelivery would present (now uses the SAME `afterSnapshot` object across both invocations); added an `undefined`-seedCount edge case test and a failed-transaction-propagation test (qa-tester GAPs). 3 new tests, 2 existing tests rewritten to match the corrected two-read mock sequence. Full suite re-verified: 72/72 passing, `npx tsc --noEmit` clean.

**Not fixed, explicitly still open** (flagged by both reviewers, pre-existing, not introduced by this story): the query-inside-`runTransaction` contention-detection behavior (does Firestore's real backend correctly treat a *newly matching* document entering a query's result set as a conflict, not just modifications to already-read documents) remains unverified against a real Firestore backend — no Java runtime in this environment, only mocked. Both reviewers recommend this be a hard pre-production gate (an emulator run or staging concurrency test) rather than something deferred indefinitely on trust alone, now that it's the sole protection for `seedCount` specifically, not just an ancillary check.

---

## Dependencies

- Depends on: None (independent of Story 001/002; suggested build order is 001 → 002 → 003 to match ADR-0012's own decision order, not a hard dependency)
- Unlocks: None — this closes the epic's data-layer contract; downstream consumption (real approve/reject writes) belongs to Parent Approval (#11), not yet epic'd

---

## Completion Notes
**Completed**: 2026-07-17
**Criteria**: 4/4 passing
**Deviations**: None remaining — the one real deviation found (ADR-0012 §4 transactional-read violation) was fixed during this story's own code review, not left as an accepted exception
**Test Evidence**: Integration — `functions/test/index.test.ts` (12 tests for this story, independently re-verified passing; full suite 72 passed/0 failures; `npx tsc --noEmit` clean)
**Code Review**: Complete — security-engineer + qa-tester (parallel, independent), verdict APPROVED after fixing the transactional-read bug both converged on. See Code Review Notes above for full detail.
**Real correctness bug found and fixed along the way**: `reconcileSeedCountDrift` originally read `seedCount` from the trigger's pre-transaction snapshot instead of a real `transaction.get()`, undermining ADR-0012 §4's own explicit safety design. Two independent reviewers (security lens + testability lens) converged on the same root cause — strong corroboration. Fixed before this story closed.
**Non-blocking follow-up item** (not tracked as tech debt — noted here): real-Firestore-emulator verification of the query-inside-transaction contention-detection behavior remains open (no Java runtime in this environment). Both reviewers recommend treating this as a hard pre-production gate now that it's load-bearing for `seedCount` specifically, not deferring it indefinitely.

**Epic status**: This closes Seed Buffer's 3rd and final story — epic is now 3/3 stories Complete.
