# Story 001: Approve Transaction — Reward Assembly, Level-Up & Chest Milestone

> **Epic**: Parent Approval System
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 4h
> **Manifest Version**: 2026-07-16 (control-manifest predates ADR-0012/0013 — this story's rules are sourced directly from ADR-0013/ADR-0003/ADR-0004 below, not the manifest body)
> **Last Updated**: 2026-07-18

## Context

**GDD**: `design/gdd/parent-approval.md`
**Requirement**: `TR-parentapproval-001`, `TR-parentapproval-002`, `TR-parentapproval-003`, `TR-parentapproval-004`, `TR-parentapproval-005`, `TR-parentapproval-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0013: Parent Approval Transaction Architecture (primary)
**Secondary references**: ADR-0003 (Firestore Schema — `runTransaction`/`FieldValue.increment` conventions), ADR-0004 (Event Bridge — `taskApproved`/`petLeveledUp` type contracts exist, but emission is explicitly OUT of this story's scope)
**ADR Decision Summary**: Single client-side `runTransaction` gated on `task.status == 'pending'` as the FIRST read (not a separate pre-check). Reads `xuReward`/`energyReward`/`totalXuEarned`/`petLevel`/`approvedTaskCount`, computes `leveledUp`/`hitChestMilestone`/`chestDelta` in pure in-memory arithmetic, writes all fields atomically via `FieldValue.increment`, returns `ApproveResult?` (null = idempotent no-op). The repository never touches `GameEventBus` — that is a future caller's job (ADR-0004 §3).

**Engine**: Flutter 3.44.4 / Flame 1.37.0 (this story is pure Platform-layer Dart — no Flame) | **Risk**: LOW (ADR-0013's own assessment — composes already-verified `runTransaction`/`FieldValue.increment`/`FieldValue.serverTimestamp` primitives from ADR-0003/0009/0011, no new post-cutoff API surface)
**Engine Notes**: None new. `cloud_firestore` version already pinned and stable per ADR-0003's 2026-07-13 correction.

**Control Manifest Rules (this layer)**:
- Required: `runTransaction` for read-before-write mutations; idempotency read must be the FIRST read inside the transaction (source: ADR-0003, reaffirmed ADR-0013)
- Required: ALL balance/counter mutation uses `FieldValue.increment()`, never absolute `set()` — except `petLevel`, which is also expressed as `FieldValue.increment(1)`, not a literal `set()` (source: ADR-0003, ADR-0013)
- Required: Increment literal type MUST match the target field's stored type — `storedEnergy` is a `double` field, so its increment must be `energyReward.toDouble()`, not the raw `int` (source: ADR-0003; explicit fix already captured in ADR-0013 Decision §2's code)
- Required: Cast Firestore numeric fields as `(x as num?)?.toInt()`, never a direct `as int` — every read in this story's transaction must default safely (`totalXuEarned ?? 0`, `petLevel ?? 1`, `approvedTaskCount ?? 0`) (source: ADR-0006/ADR-0008, reaffirmed ADR-0013)
- Required: Never build Firestore paths as inline strings — use `FirestorePaths.task()`/`FirestorePaths.child()` (source: ADR-0003/0006/0008/0009/0011)
- **Superseded note**: the manifest's "`PersistenceRepository` is the ONLY module that touches Firestore paths" line (source: ADR-0003) is explicitly superseded by ADR-0013 Decision §1 — the actual established convention is one small repository per write concern (`TaskRepository`, `CustomTaskRepository`, and now `ParentApprovalRepository`), matching precedent, not a monolithic `PersistenceRepository`.
- Forbidden: Repository code must NEVER call `GameEventBus().emit()` — exactly two sanctioned adapters exist (`ref.listen` in a `ConsumerWidget`, or a Flame tap/drag handler), a repository is neither (source: ADR-0004 §3; this exact mistake was already made and fixed once in this codebase, Seed Buffer Story 001 — do not repeat it)

**Performance Budget**: GDD Formulas Contract 2 defines an end-to-end latency contract for this operation (`runTransaction` local commit ack <100ms; parent-tap→child-bloom-animation <200ms avg / <500ms worst-case, spike-validated in `prototypes/firebase-multidevice-sync-spike-2026-07-03/`). Only the local commit-ack portion (<100ms) is measurable within this story's scope — the end-to-end animation observation requires a real caller (Parent Dashboard UI #21, no epic yet) and is ADVISORY, not a blocking gate for this story per `.claude/docs/coding-standards.md` Testing Standards.

---

## Acceptance Criteria

*From GDD `design/gdd/parent-approval.md`, scoped to this story (Approve path only):*

- [x] **Normal path**: GIVEN 1 pending task with `xuReward=X`, `energyReward=Y`, child below next level threshold and not at a milestone, WHEN `approveTask()` is called, THEN `task.status='approved'`, `approvedAt` set, `xuBalance += X`, `storedEnergy += Y`, `lastApprovedAt = serverTimestamp()`, `seedCount -= 1`, `totalXuEarned += X`, `approvedTaskCount += 1` — no other `children/{childId}` field changes.
- [x] **Normal path result**: WHEN the transaction commits, THEN `approveTask()` returns `ApproveResult(leveledUp: false, newPetLevel: null)`.
- [x] **Level-up only**: GIVEN `newTotalXuEarned >= nextLevelThreshold(petLevel)` AND `petLevel < 5` AND `newApprovedTaskCount % 5 != 0`, WHEN approve, THEN `leveledUp=true`, `chestDelta=1`, `petLevel += 1`, `xuBalance` credited with BOTH `task.xuReward` AND `xuBonus(newLevel)`, result has `leveledUp: true, newPetLevel: <incremented>`.
- [x] **Chest milestone only**: GIVEN `newApprovedTaskCount % 5 == 0` but `newTotalXuEarned < nextLevelThreshold(petLevel)`, WHEN approve, THEN `hitChestMilestone=true`, `leveledUp=false`, `chestDelta=1`, `chestCount += 1`, result has `leveledUp: false`.
- [x] **Both triggers combo**: GIVEN `petLevel=2`, `totalXuEarned=380`, `nextLevelThreshold(2)=400`, task `xuReward=20`, `approvedTaskCount=24` (worked example from GDD Formulas Contract 1), WHEN approve, THEN `chestDelta=2`, `chestCount += 2`, `petLevel` increments only once (not double-counted), result `leveledUp: true`.
- [x] **Neither trigger**: GIVEN both `leveledUp` and `hitChestMilestone` are false, WHEN approve, THEN `chestDelta=0`, `chestCount` field is not written at all (not written-as-zero — `FieldValue.increment` is conditionally included only `if (chestDelta > 0)`).
- [x] **Idempotency**: GIVEN a task with `status` already `'approved'` or `'rejected'`, WHEN `approveTask()` runs again, THEN the transaction aborts at the first read, no field is written, `approveTask()` returns `null`.
- [x] **Double-tap**: GIVEN two sequential `approveTask()` calls on the same task (simulating a double-tap that got past the UI-layer disable), WHEN both execute, THEN the second reads `status != 'pending'` and returns `null` — the task is credited exactly once.
- [x] **Two-device race (testable portion only)**: GIVEN the SAME idempotency mechanism as double-tap — this codebase has no live Firestore emulator (no Java runtime), so this AC is verified via the mocked idempotency gate only, not a real concurrent two-client test (per ADR-0013's own Validation Criteria, matching Seed Buffer Story 003's precedent for this class of gap).
- [x] **Max level + milestone**: GIVEN `petLevel=5` (max) and `newApprovedTaskCount % 5 == 0`, WHEN approve, THEN `leveledUp=false` regardless of `newTotalXuEarned` (guarded by `petLevel < 5` in the `leveledUp` computation), `chestDelta=1`, `petLevel` unchanged, result `leveledUp: false`.
- [x] **Transaction failure**: GIVEN a mocked `runTransaction` that throws (any `FirebaseException` or other), WHEN `approveTask()` is called, THEN the exception propagates uncaught (let-it-throw, matching `CustomTaskRepository`'s established pattern) — no partial write occurs (verify via the fake transaction's write-call assertions), `task.status` is untouched.
- [x] **nextLevelThreshold cache sync**: GIVEN a level-up occurs, WHEN the transaction writes `petLevel`, THEN it also writes `nextLevelThreshold` to the new level's threshold (or `null` if the new level is 5, the max) — this keeps the cache field in sync for any future consumer, per ADR-0013 Decision §2's explicit fix.

---

## Implementation Notes

*Derived from ADR-0013 Decision §1, §2, §4:*

1. Create `ParentApprovalRepository` in `src/lib/core/parent_approval_repository.dart`, constructor-injected `FirebaseFirestore` (matching `ref.watch(firebaseFirestoreProvider)` convention, same shape as `TaskRepository`/`CustomTaskRepository`).
2. Implement `approveTask({required String parentId, required String childId, required String taskId})` returning `Future<ApproveResult?>` — **copy the transaction body from ADR-0013 Decision §2 exactly**; it is already fully specified and was independently validated by `flame-specialist` during the ADR's own review pass. Do not deviate from the read order (task first, then child) or the increment-vs-set choices.
3. Also implement in the same file (or an adjacent `pet_leveling_lookup.dart` if that reads cleaner — implementer's call): `nextLevelThreshold(int currentLevel)` (throws outside 1–4, by design — every call site here guards `petLevel < 5`/`newPetLevel < 5` first), `xuBonus(int newLevel)`, and `const gachaFreeChestMilestone = 5`. Source values from `design/registry/entities.yaml` (`pet_level_threshold_l2..l5` = 150/400/900/1800, `pet_levelup_xu_bonus` = `level*25+25`) — do not invent or re-derive these; they are already registered.
4. Define `ApproveResult` exactly as ADR-0013 Decision §2/§Key Interfaces specifies — `leveledUp: bool`, `newPetLevel: int?` (non-null iff `leveledUp`).
5. `approveTask()` returns the result — it does **not** call `GameEventBus` at any point. There is no caller yet (Parent Dashboard UI #21 doesn't exist) — that's fine; this story does not need to wire emission, only return a correct result a future caller can react to.
6. For the fake-Firestore-transaction test harness: follow the hand-rolled fake pattern already established in `tests/integration/seed_buffer/seed_submit_test.dart` (fake `WriteBatch`) and Task Library's `_FakeQuery`/`_FakeCollectionReference` — this story needs a fake `Transaction` (`get()` returning pre-seeded snapshots, `update()` recording calls for assertion). Match the installed `cloud_firestore` version's full `Transaction` interface surface for explicit-override conformance (same lesson already learned in Task Library Story 002).

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 002 (this epic)**: `rejectTask()` — separate story, separate test file.
- **Parent Dashboard UI (#21), no epic yet**: emitting `GameEvent(taskApproved)`/`(petLeveledUp)` off the `ApproveResult`; UI button disable/re-enable states; `connectivity_plus` offline pre-check; the "someone else already processed this" toast (GDD Open Questions).
- **Pet Leveling & Evolution (#16), no epic yet**: any UI that reads the cached `nextLevelThreshold` field directly (e.g. a progress bar) — this story only guarantees the field stays correctly in sync, not that anything consumes it yet.
- **Live two-device Firestore emulator verification**: no Java runtime in this environment (established project-wide constraint) — covered via mocked idempotency gate only.
- **GameEventBus replay risk** (flagged in EPIC.md's Known Risks): not resolved here — this story returns a result but never emits, so the replay risk is not yet reachable by this story's own code. It becomes live once a future Parent Dashboard story starts emitting off this result.

---

## QA Test Cases

*Transcribed directly from `design/gdd/parent-approval.md`'s own Acceptance Criteria section (already in Given/When/Then form) — QL-STORY-READY gate skipped (Solo mode), so these are sourced from the GDD directly rather than qa-lead-generated.*

- **AC-1 (Normal path)**
  - Given: 1 pending task, `xuReward=X`, `energyReward=Y`, child below level threshold, not at milestone
  - When: `approveTask()` called
  - Then: exact field deltas listed above; no other field changes
  - Edge cases: `X=0`, `Y=0` (zero-reward task — still a valid commit)

- **AC-2 (Level-up only)**
  - Given: `petLevel<5`, `newTotalXuEarned >= nextLevelThreshold(petLevel)`, milestone not hit
  - When: approve
  - Then: `chestDelta=1`, `petLevel+=1`, `xuBalance` gets task reward + level bonus
  - Edge cases: exact-boundary `newTotalXuEarned == nextLevelThreshold(petLevel)` (must count as leveled up, not just `>`)

- **AC-3 (Chest milestone only)**
  - Given: `newApprovedTaskCount % 5 == 0`, level threshold not reached
  - When: approve
  - Then: `chestDelta=1`, `chestCount+=1`, no level change
  - Edge cases: `approvedTaskCount` starting at 0 → first milestone at exactly 5

- **AC-4 (Both triggers combo)**
  - Given: GDD's exact worked example (`petLevel=2`, `totalXuEarned=380`, task `xuReward=20`, `approvedTaskCount=24`)
  - When: approve
  - Then: `chestDelta=2`, `chestCount+=2`, `petLevel` increments exactly once
  - Edge cases: verify no double-count of `petLevel`

- **AC-5 (Neither trigger)**
  - Given: both conditions false
  - When: approve
  - Then: `chestDelta=0`, `chestCount` field absent from the write map entirely

- **AC-6 (Idempotency / double-tap)**
  - Given: task `status` already `'approved'` or `'rejected'`
  - When: `approveTask()` called
  - Then: returns `null`, zero writes recorded
  - Edge cases: run two sequential calls in the same test to simulate double-tap directly

- **AC-7 (Max level + milestone)**
  - Given: `petLevel=5`, milestone hit
  - When: approve
  - Then: `leveledUp=false` unconditionally, `chestDelta=1` only
  - Edge cases: `newTotalXuEarned` deliberately set far above any threshold to prove the guard, not the value, controls this

- **AC-8 (Transaction failure)**
  - Given: fake transaction configured to throw
  - When: `approveTask()` called
  - Then: exception propagates, no writes recorded
  - Edge cases: throw at the read step vs. throw at the write step — both must leave zero recorded writes

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/parent_approval/approve_task_test.dart` — 19 tests, all passing (17 original + 2 added during code review: corrupted-petLevel regression, malformed-task-doc documentation)
- `tests/unit/parent_approval/pet_leveling_lookup_test.dart` — 12 tests, all passing (added during code review to directly cover the pure `nextLevelThreshold()`/`xuBonus()` formulas per coding-standards.md's BLOCKING Logic-story requirement)

**Status**: [x] Created — 31/31 tests passing, independently re-verified. Full suite: 346 passed / 1 pre-existing skip / 0 failures. `flutter analyze` clean (1 pre-existing lint pattern, matches sibling repositories).

## Completion Notes

Code review (`flame-specialist` + `qa-tester`, parallel) verdict: **APPROVED WITH SUGGESTIONS**. `flame-specialist` confirmed COMPLIANT against ADR-0013 with no drift. `qa-tester` found two real untested edge cases, both fixed before close:
1. `petLevel` corrupted to 0/negative (not absent) reached `nextLevelThreshold()`'s throwing branch — the code's own doc comment claimed the guard was safe but it wasn't for this direction. Fixed with a clamp mirroring Currency's established missing-vs-invalid-value dual-clamp precedent.
2. Pure `nextLevelThreshold()`/`xuBonus()` functions had no dedicated unit test (BLOCKING per coding-standards.md Logic-story rule) — added `pet_leveling_lookup_test.dart`.

A third finding — direct non-nullable `as num` casts on `taskData['xuReward']`/`energyReward` — was confirmed to match ADR-0013's own reference code exactly (not an implementer deviation) and is consistent with GDD Edge Case 6's explicit scoping (tampered/missing reward values are Task Library's Reward Integrity Guard responsibility, not this transaction's). Documented rather than changed, via a test asserting the current (crash) behavior so it can't silently change unnoticed.

**Completed**: 2026-07-18
**Criteria**: 12/12 passing (0 deferred)
**Deviations**: None (ADR-0013 COMPLIANT, zero drift per flame-specialist)
**Test Evidence**: Integration — `tests/integration/parent_approval/approve_task_test.dart` (19 tests) + `tests/unit/parent_approval/pet_leveling_lookup_test.dart` (12 tests), 31/31 passing
**Code Review**: Complete — `flame-specialist` + `qa-tester`, APPROVED WITH SUGGESTIONS, all 3 suggestions closed before this close-out

---

## Dependencies

- Depends on: None — all upstream systems (Task Library, Currency, Time & Decay, Seed Buffer) are already Complete; Pet Leveling/Gacha have no epic yet but their pure lookup functions are defined inline per ADR-0013 §4, not blocked on those epics existing.
- Unlocks: Story 002 (shares `ParentApprovalRepository` class, but `rejectTask()` is independent logic — implementable in either order).
