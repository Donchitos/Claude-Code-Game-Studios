# Story 002: Reject Transaction — Idempotent Status-Only Write

> **Epic**: Parent Approval System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 1.5h
> **Manifest Version**: 2026-07-16 (control-manifest predates ADR-0012/0013 — this story's rules are sourced directly from ADR-0013/ADR-0003 below, not the manifest body)
> **Last Updated**: 2026-07-18

## Context

**GDD**: `design/gdd/parent-approval.md`
**Requirement**: `TR-parentapproval-006`, `TR-parentapproval-008` (shared with Story 001 — unified error handling)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Parent Approval Transaction Architecture (Decision §3)
**ADR Decision Summary**: `rejectTask()` reuses the exact same idempotency shape as `approveTask()` (first read inside the transaction gates on `task.status == 'pending'`) but writes only `status`/`rejectedAt`/`seedCount` — no economy fields, no `GameEvent`.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 (Platform-layer Dart, no Flame) | **Risk**: LOW
**Engine Notes**: None new — reuses the same `runTransaction` primitives as Story 001.

**Control Manifest Rules (this layer)**:
- Required: Same idempotency-read-first rule as Story 001 (source: ADR-0003, reaffirmed ADR-0013)
- Required: `seedCount -= 1` via `FieldValue.increment(-1)` — never absolute `set()` (source: ADR-0003, ADR-0012, ADR-0013)
- Forbidden: No `GameEventBus` call anywhere in this method — GDD Core Rule 3 is explicit that reject's "wither" animation is UI-local (owned by Task Management UI #19 off the task-list transition), not a Pet State Machine trigger. This is a stronger constraint than Story 001's (which at least returns a result a future caller can act on) — reject has no analogous result at all.

**Performance Budget**: No dedicated latency contract exists for Reject in the GDD (Formulas Contract 2 covers Approve only) — reject is a smaller write (2 fields vs. approve's 6+) with no formula computation, so no separate budget is defined. "No performance impact expected beyond the same `runTransaction` local commit-ack cost already budgeted for Story 001."

---

## Acceptance Criteria

*From GDD `design/gdd/parent-approval.md`, scoped to this story (Reject path only):*

- [x] **Normal reject**: GIVEN 1 pending task, WHEN `rejectTask()` is called, THEN `task.status='rejected'`, `rejectedAt` set, `seedCount -= 1`; `xuBalance`, `storedEnergy`, `totalXuEarned`, `approvedTaskCount` are all unchanged.
- [x] **No event emission**: WHEN reject commits, THEN no `GameEvent` of any kind is emitted (verify the fake `GameEventBus`, if wired into the test at all, receives zero calls — or simpler: assert the method's return type is `void`/`Future<void>` and no bus reference exists in the implementation).
- [x] **Idempotency**: GIVEN a task with `status` already `'approved'` or `'rejected'`, WHEN `rejectTask()` runs, THEN the transaction aborts at the first read, no field is written.
- [x] **No un-reject**: GIVEN a task already `status='rejected'`, WHEN `rejectTask()` is called again, THEN it is a no-op (covered by the Idempotency case above — there is no separate "un-reject" code path to test because none exists, per GDD Edge Case 8).
- [x] **Transaction failure**: GIVEN a mocked `runTransaction` that throws, WHEN `rejectTask()` is called, THEN the exception propagates uncaught, no partial write occurs.

---

## Implementation Notes

*Derived from ADR-0013 Decision §3:*

1. Add `rejectTask({required String parentId, required String childId, required String taskId})` to the same `ParentApprovalRepository` class Story 001 creates — returns `Future<void>` (not `Future<ApproveResult?>`; there's no result to return, per the ADR's own asymmetry note in Key Interfaces).
2. **Copy the transaction body from ADR-0013 Decision §3 exactly** — first read gates on `status == 'pending'`, early-return (no-op) if not; otherwise writes `taskRef` (`status: 'rejected'`, `rejectedAt: FieldValue.serverTimestamp()`) and `childRef` (`seedCount: FieldValue.increment(-1)`) in the same transaction.
3. If Story 001 is not yet done when this story starts, this story creates `ParentApprovalRepository` itself with only this method — Story 001's `approveTask()` gets added alongside it later. Either order works; whichever story lands first creates the file.
4. Reuse the fake-transaction test harness from Story 001 if it already exists (same fake `Transaction`/`DocumentReference` shapes) — do not build a second, divergent fake.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 001 (this epic)**: `approveTask()` — separate story, separate test file.
- **Task Management UI (#19), no epic yet**: the actual "wither" animation UI-local trigger off the task-list transition.
- **Parent Dashboard UI (#21), no epic yet**: UI button states, offline pre-check, "already processed by someone else" toast.

---

## QA Test Cases

*Transcribed directly from `design/gdd/parent-approval.md`'s own Acceptance Criteria section — QL-STORY-READY gate skipped (Solo mode).*

- **AC-1 (Normal reject)**
  - Given: 1 pending task
  - When: `rejectTask()` called
  - Then: `status='rejected'`, `rejectedAt` set, `seedCount-=1`; all economy fields unchanged
  - Edge cases: `seedCount` already at 0 before reject — this story's own write is a raw `increment(-1)` with no clamp (clamping to 0 is `seedCountProvider`'s job on read, per ADR-0012 §3, not this write's job — matches the `-1` write already established for approve)

- **AC-2 (Idempotency)**
  - Given: task `status` already `'approved'` or `'rejected'`
  - When: `rejectTask()` called
  - Then: no writes recorded
  - Edge cases: test both prior states (`'approved'` and `'rejected'`) separately — both must short-circuit identically

- **AC-3 (Transaction failure)**
  - Given: fake transaction configured to throw
  - When: `rejectTask()` called
  - Then: exception propagates, no writes recorded

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/parent_approval/reject_task_test.dart` — 8 tests, all passing (plus 2 hardening tests beyond the 5 story ACs: seedCount-already-0 no-clamp, missing-task-doc defensive case)

**Status**: [x] Created — 8/8 tests passing, independently re-verified. Full suite: 354 passed / 1 pre-existing skip / 0 failures. `flutter analyze` clean (1 pre-existing lint pattern, matches sibling repositories).

## Completion Notes

**Completed**: 2026-07-18
**Criteria**: 5/5 passing (0 deferred)
**Deviations**: None (ADR-0013 §3 COMPLIANT, zero drift per flame-specialist; confirmed `approveTask()` untouched)
**Test Evidence**: Integration — `tests/integration/parent_approval/reject_task_test.dart`, 8/8 passing
**Code Review**: Complete — `flame-specialist` + `qa-tester`, APPROVED WITH SUGGESTIONS. qa-tester found a real non-blocking gap: `rejectTask()` writes to the child doc without an existence check (unlike `approveTask()`) — closed by adding a doc comment stating the same child-doc-exists invariant ADR-0012 already documents for Seed Buffer, rather than changing behavior (matches Story 001's precedent of documenting rather than defending against out-of-contract states).

---

## Dependencies

- Depends on: None (independent of Story 001's `approveTask()`, though both live in the same repository class).
- Unlocks: None further within this epic.
