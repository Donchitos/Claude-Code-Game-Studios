# Epic: Task Library

> **Layer**: Core
> **GDD**: design/gdd/task-library.md
> **Architecture Module**: Task Library (#8)
> **Status**: Complete
> **Stories**: 4/4 stories complete (2026-07-16) — see table below

## Overview

This epic implements the real-world task lifecycle (pending → approved/rejected,
no cancel or withdrawal) and the authoritative category→reward lookup table
(study/arts 25xu·20energy, chores/sport/custom 15xu·25energy, helping
10xu·30energy). Rewards are never client-settable in the security model: a
Firestore Security Rule validates `xuReward`/`energyReward` against the category
table synchronously at task-create time (the primary, load-bearing defense — see
ADR-0009's OR-semantics finding on why a blanket wildcard rule would make this
inert), with `onTaskApproved`'s energy cap serving as a defense-in-depth backstop.
This module also owns `customTasks` templates (parent-authored, reward-free —
the real instance is only created when the child submits), and the composite-
indexed `pendingTasksProvider`/`taskHistoryProvider` queries.

**Exit-criteria note (from `/gate-check` 2026-07-13 Pre-Production→Production)**:
`data-persistence-layer.md`'s Security Rules block was found stale (still had a
blanket wildcard, making this epic's reward-integrity rule inert) and was fixed
in-GDD on 2026-07-13. **Before deploying rules for this epic, verify the actual
deployed `firestore.rules` matches the corrected nested-match structure — do not
deploy from an older cached copy of the rules file.**

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0009: Task Lifecycle & Reward Integrity | Security Rule (create-time, synchronous) validates reward against category table — the primary defense; reward/category fields immutable on update; `customTasks` are reward-free templates; composite-indexed pending/history queries; amends ADR-0003 §5 from blanket wildcard to explicit nested matches | LOW — the rules-composition OR-semantics lesson (why the blanket wildcard was dangerous) is now well-understood and documented; composite index setup is the main implementation-order risk |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-tasklib-001 | Lifecycle is pending to approved/rejected; no cancelled state | ADR-0009 ✅ |
| TR-tasklib-002 | Reward-integrity guard: Security Rule validates reward fields against the category table at create-time | ADR-0009 ✅ |
| TR-tasklib-003 | `customTasks` templates are structurally distinct from task instances | ADR-0009 ✅ |
| TR-tasklib-004 | `pendingTasksProvider` and `taskHistoryProvider` are composite-indexed queries | ADR-0009 ✅ |
| TR-tasklib-005 | Reward values are data-driven and never client-settable | ADR-0009 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/task-library.md` are verified
- All Logic and Integration stories have passing test files in `tests/` — a rules-emulator test explicitly covering "task create with mismatched reward is denied" and "unknown categoryId falls back to custom tier, not exploitable" is mandatory (this is the security-critical path of the whole economy)
- The deployed `firestore.rules` file is verified against the corrected structure per the exit-criteria note above
- Composite indexes (`status` + `submittedAt`, both ascending and descending as needed) are confirmed deployed before the query-dependent stories are tested

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | TaskModel + Authoritative Reward Lookup Table | Logic | Complete | ADR-0009 |
| 002 | pendingTasksProvider + taskHistoryProvider (Composite-Indexed) | Integration | Complete | ADR-0009 |
| 003 | customTasks Template Write | Integration | Complete | ADR-0009 |
| 004 | onTaskApproved Reward Reconciliation (Defense-in-Depth) | Integration | Complete | ADR-0009 |

**Dependency note**: TR-tasklib-002's primary Security Rule half is already deployed and `security-engineer`-reviewed (Data Persistence Layer Story 002, `firestore.rules`' `tasks/{taskId}` block). Story 004 completes the defense-in-depth half only. `FirestorePaths.tasks/task/customTasks/customTask` already exist (Data Persistence Layer Story 001).

**Recommended build order**: 001 → 002/003 (both depend only on 001, can build in either order) → 004 (extends the existing `onTaskApproved` function, no dependency on 002/003).

## Epic Completion Notes

**Closed**: 2026-07-16

All 4 stories implemented, code-reviewed (flame-specialist + qa-tester on Stories 001-003; security-engineer + qa-tester on Story 004, given its Cloud Functions/security-adjacent nature), and closed with full Completion Notes on their respective story files.

**Definition of Done status**:
- All stories implemented, reviewed, closed. ✅
- All acceptance criteria verified per story. ✅
- Logic/Integration stories have passing test files: `tests/unit/task_library/task_model_test.dart` (7), `tests/unit/task_library/task_providers_test.dart` (6), `tests/unit/task_library/custom_task_test.dart` (7), `functions/test/index.test.ts` (40, including pre-existing). ✅
- Deployed `firestore.rules` verified against the corrected structure — already confirmed in Data Persistence Layer Story 002 (this epic only reads that already-deployed rule, does not modify `firestore.rules`). ✅
- Composite indexes (`firestore.indexes.json`, `status ASC, submittedAt DESC`) validated via `firebase deploy --only firestore:indexes --dry-run` against the live pinned project — confirmed no schema errors. ⚠️ **Known gap, matches this epic's own DoD wording and an already-established environment constraint**: the DoD's "rules-emulator test explicitly covering 'task create with mismatched reward is denied' and 'unknown categoryId falls back to custom tier'" is NOT satisfied — no Java Runtime is available in this environment, so the Firestore emulator cannot run here (the same constraint already documented for Data Persistence Layer Story 002, which deployed the underlying rule using `--dry-run` validation instead of an emulator test for the same reason). A `--dry-run` deploy validates rule *syntax*, not rule *behavior* — this remains unverified beyond the CEL logic being read and independently reasoned through by two reviewers (flame-specialist on Story 002's index-sufficiency question; security-engineer on Story 004, who additionally confirmed the CEL `rewardTable()`/`in` lookup is NOT vulnerable to the prototype-chain class of bug found in this epic's TypeScript mirror). Closing the epic despite this gap since it is a pre-existing, already-accepted environment limitation, not new to this epic — flagging here for visibility rather than silently treating it as resolved.

A genuine security finding surfaced in Story 004's review: the TypeScript `REWARD_TABLE` mirror (Cloud Functions defense-in-depth) had a JS-prototype-chain lookup bypass (`categoryId: 'constructor'` resolving to a truthy built-in instead of `undefined`) that would have silently defeated the exact "unknown categoryId always flagged" backstop it exists to provide. Fixed with an `Object.hasOwn` guard; the primary Security Rule (CEL) was confirmed independently immune to this class of bug.

## Post-Closure Fix — 2026-07-22 (found blocking Parent Dashboard UI Story 001)

Two real gaps were found during Parent Dashboard UI Story 001's `/dev-story` attempt (2026-07-18) and fixed here directly rather than as a new numbered story, since both are small, additive corrections to already-Complete Story 001/002's own files, not new scope:

1. **`TaskModel` gained `id`/`childId` fields** (`src/lib/core/models/task_model.dart`). `id` = `doc.id`; `childId` is derived from `doc.reference.parent.parent!.id` (never a document field — `tasks` always lives at `families/{parentId}/children/{childId}/tasks/{taskId}`, so `childId` only ever appears in the PATH). Works identically for a single-child subcollection query or a merged multi-child stream, since a `QueryDocumentSnapshot.reference` always carries its true full path regardless of which query produced it. Both fields are required for Story 001 to call `approveTask()`/`rejectTask()` (which take `childId`/`taskId`) and to resolve per-card avatar/name.
2. **`familyPendingTasksProvider` added** (`src/lib/providers/task_providers.dart`, alongside the pre-existing single-child `pendingTasksProvider`, left unmodified for any other caller). Awaits `childProfilesProvider` for the child list, opens one composite-indexed per-child `tasks` stream per child (same query shape `pendingTasksProvider` already used — no new index needed), and combines them with a hand-rolled combineLatest (`_mergeLatestLists` — no `rxdart` dependency in this project). A `collectionGroup('tasks')` query was considered instead but would require deploying a NEW `COLLECTION_GROUP`-scoped composite index (the existing `firestore.indexes.json` entry is `COLLECTION`-scoped only) — given this project's environment cannot run the Firestore emulator to verify an index/rules deploy (the same already-documented gap above), the per-child merge was chosen since it needs no Firestore infra change and stays correct at the 4-child cap.

**Test evidence**: `tests/unit/task_library/task_model_test.dart` grew from 7 to 8 tests (added `test_fromFirestore_derives_id_and_childId_from_the_document_reference_path`); `tests/unit/task_library/task_providers_test.dart` grew from 6 to 9 tests (added a `familyPendingTasksProvider` group: multi-child merge/re-sort/childId-attribution, signed-out empty, zero-children empty). Both existing test files' hand-rolled Firestore fakes were extended with a generic path-based `DocumentReference`/`CollectionReference` pair supporting the `.reference.parent.parent!.id` chain — full suite re-verified at 450/450 (1 pre-existing unrelated skip), `flutter analyze` clean.

Parent Dashboard UI Story 001 is unblocked by this fix (its other blocker — Main Navigation Shell not existing — was separately resolved when that epic was built and completed).
