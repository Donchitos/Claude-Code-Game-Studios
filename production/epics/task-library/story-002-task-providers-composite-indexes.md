# Story 002: pendingTasksProvider + taskHistoryProvider (Composite-Indexed)

> **Epic**: Task Library
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/task-library.md`
**Requirement**: `TR-tasklib-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Task Lifecycle & Reward Integrity, Decision §5 (query providers), Migration Plan §2 (GDD sync corrections)

**Engine**: Flutter 3.44.4 / `cloud_firestore ^6.7.1` / `flutter_riverpod ^3.3.2` | **Risk**: LOW — the StreamProvider-over-composite-query pattern is stable and pre-cutoff; the only real risk is the composite index DEFINITION itself, which this story must get right or the queries fail loudly at runtime (a missing-index Firestore error, not a silent bug — low risk of going unnoticed).

**Control Manifest Rules (this layer)**:
- Required: "`pendingTasksProvider`: `where(status=='pending').orderBy(submittedAt desc)` — 1 composite index" — source: ADR-0009
- Required: "`taskHistoryProvider`: `where(status, whereIn:[...]).where(submittedAt range).orderBy(submittedAt desc)`, index DESCENDING; use `whereIn`, NOT `not-in`" — source: ADR-0009
- Required: "Both task providers scoped via `FirestorePaths` + the safe nullable AsyncValue accessor (`.value` on `riverpod` 3.x) + null-guard returning `Stream.value([])`" — source: ADR-0009
- Forbidden: "Do not 'simplify' the history query to `not-in`" — source: ADR-0009

## Already Established (do not re-derive)

- `TaskModel`/`TaskModel.fromFirestore` already exist from Story 001 (this epic) — this story maps query results through them, does not re-implement parsing.
- `FirestorePaths.tasks(parentId, childId)` already exists (Data Persistence Layer Story 001).
- The GDD's OWN code sketch has 2 real, ADR-documented bugs to NOT copy: (1) `pendingTasksProvider` in the GDD lacks even the null-guard `taskHistoryProvider` has — both need it; (2) both use `ref.watch(activeChildProvider)?.id`, which does not compile against this codebase's actual `ChildProfile` model (the field is `.childId`, not `.id` — the SAME drift already found and fixed twice this session, Currency System Story 001 and Time & Decay).
- The composite indexes this story requires do NOT exist yet — `firestore.indexes.json` has never been created in this project. `firebase.json` also has no `"indexes"` key yet.

---

## Acceptance Criteria

*From ADR-0009 Decision §5 and Migration Plan:*

- [x] `pendingTasksProvider` (`StreamProvider<List<TaskModel>>`): `.collection(FirestorePaths.tasks(parentId, childId)).where('status', isEqualTo: 'pending').orderBy('submittedAt', descending: true).snapshots()`, mapped through `TaskModel.fromFirestore`.
- [x] `taskHistoryProvider` (`StreamProvider<List<TaskModel>>`): `.where('status', whereIn: ['approved', 'rejected']).where('submittedAt', isGreaterThanOrEqualTo: <30-days-ago>).orderBy('submittedAt', descending: true)` — uses `whereIn`, NEVER `not-in`.
- [x] Both providers use `ref.watch(activeChildProvider)?.childId` (corrected field name, per the Already Established drift note) and `ref.watch(authStateProvider).value?.uid`.
- [x] Both providers null-guard: if `parentId` or `childId` is null, resolves to `Stream.value(const [])` — never issues a Firestore query against a `families/null/children/null/tasks` path (matching the GDD's own edge case: "tránh path `families/null/children/null/tasks`"). `pendingTasksProvider` specifically must have this guard even though the GDD's OWN sketch omits it there.
- [x] `firestore.indexes.json` (new file) defines the composite index(es) ADR-0009 requires — resolved to ONE `(status ASC, submittedAt DESC)` entry serving both providers (verified: `whereIn` reduces to equality-class filtering for index purposes, so both query shapes need the identical field/order sequence).
- [x] `firebase.json` gains an `"indexes": "firestore.indexes.json"` key so `firebase deploy --only firestore:indexes` (or the combined `firestore` target) would pick it up.
- [x] A non-destructive validation of the indexes file is performed — `firebase deploy --only firestore:indexes --dry-run` against the live pinned project (`pet-quest-39d38`) completed with no errors. Documented evidence gap (flame-specialist review, 2026-07-16): a dry-run validates JSON schema only, not index sufficiency — that can only be proven by the query actually running against production Firestore without a `failed-precondition` error, which remains unverified until first real deploy.

---

## Implementation Notes

*From ADR-0009 Decision §5 and Key Interfaces (corrected for the real `.childId` field name):*

```dart
final pendingTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final childId = ref.watch(activeChildProvider)?.childId; // NOT .id
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return Stream.value(const []);
  return ref.watch(firebaseFirestoreProvider)
    .collection(FirestorePaths.tasks(parentId, childId))
    .where('status', isEqualTo: 'pending')
    .orderBy('submittedAt', descending: true)
    .snapshots()
    .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
});

final taskHistoryProvider = StreamProvider<List<TaskModel>>((ref) {
  final childId = ref.watch(activeChildProvider)?.childId; // NOT .id
  final parentId = ref.watch(authStateProvider).value?.uid;
  if (parentId == null || childId == null) return Stream.value(const []);
  final cutoff = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
  return ref.watch(firebaseFirestoreProvider)
    .collection(FirestorePaths.tasks(parentId, childId))
    .where('status', whereIn: ['approved', 'rejected'])
    .where('submittedAt', isGreaterThanOrEqualTo: cutoff)
    .orderBy('submittedAt', descending: true)
    .snapshots()
    .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
});
```
- Use `ref.watch(firebaseFirestoreProvider)` per this project's established DI convention (the ADR's own sketch uses the static `FirebaseFirestore.instance`; deviate correctly per precedent, matching Time & Decay/Item Database/Currency System).
- `firestore.indexes.json` shape (standard Firestore CLI format):
  ```json
  {
    "indexes": [
      {
        "collectionGroup": "tasks",
        "queryScope": "COLLECTION",
        "fields": [
          {"fieldPath": "status", "order": "ASCENDING"},
          {"fieldPath": "submittedAt", "order": "DESCENDING"}
        ]
      }
    ]
  }
  ```
  Note both providers' composite index requirement resolves to the SAME `(status, submittedAt DESC)` shape — `pendingTasksProvider`'s `where(status==) + orderBy` and `taskHistoryProvider`'s `where(status whereIn) + where(submittedAt range) + orderBy` both need `status` and `submittedAt` indexed together; verify whether Firestore actually requires TWO distinct index entries here (one per query shape) or whether ONE composite index serves both — check the Firebase CLI's own error output/documentation for the `whereIn` + range-on-different-field + orderBy combination specifically, since ADR-0009 says "1 composite index" per provider (implying 2 total, not necessarily identical entries) — do not assume without verifying.
- The index JSON's `"collectionGroup": "tasks"` field is just the field name the Firestore CLI schema uses to identify which collection an index applies to — it is NOT the same thing as issuing a `.collectionGroup('tasks')` *query*. The actual providers call `.collection(FirestorePaths.tasks(parentId, childId))` (an exact, single-path query), and `"queryScope": "COLLECTION"` in `firestore.indexes.json` is what correctly matches that — it applies to every `families/{X}/children/{Y}/tasks` instance project-wide because Firestore composite indexes are defined per collection ID, not per exact path, regardless of query scope. A future `.collectionGroup('tasks')` query would need a separate `COLLECTION_GROUP`-scoped index entry.

---

## Out of Scope

- `TaskModel` itself — Story 001 (this epic).
- `customTasks` — Story 003 (this epic).
- Actually deploying the indexes for real (`firebase deploy --only firestore:indexes`, without dry-run) — per this project's established side-effects-outside-the-repo boundary, this remains a manual step for the user, same as the Security Rules deployment in Data Persistence Layer Story 002.
- Task Management UI (#19)'s own client-side reversal of `pending`'s ordering to oldest-first — explicitly that UI's concern per ADR-0009 Decision §5, not this provider's.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0009's Validation Criteria and this story's own Acceptance Criteria:*

```
Test: pendingTasksProvider returns only pending tasks, newest-first
  Given: a fake Firestore tasks collection with a mix of pending/approved/rejected tasks,
    various submittedAt timestamps
  When: pendingTasksProvider is read
  Then: only status='pending' tasks are returned, ordered by submittedAt descending

Test: taskHistoryProvider returns only approved/rejected tasks within 30 days
  Given: a fake Firestore tasks collection with pending/approved/rejected tasks, some
    submittedAt within 30 days, some older
  When: taskHistoryProvider is read
  Then: only approved/rejected tasks with submittedAt >= 30 days ago are returned, newest-first;
    a pending task and an approved-but-31-days-old task are both excluded

Test: pendingTasksProvider resolves to [] (not erroring) when signed out
  Given: authStateProvider has no signed-in user
  When: pendingTasksProvider is read
  Then: resolves to [] — does not throw, does not issue a Firestore query

Test: taskHistoryProvider resolves to [] (not erroring) when no active child
  Given: authStateProvider signed in, activeChildProvider is null
  When: taskHistoryProvider is read
  Then: resolves to []

Test: taskHistoryProvider uses whereIn, never not-in
  Given: the provider implementation file's source
  When: inspected (static check)
  Then: 'not-in' does not appear anywhere in the file; 'whereIn' does

Test: firestore.indexes.json is valid JSON defining the required composite indexes
  Given: the firestore.indexes.json file
  When: parsed
  Then: it is valid JSON with an "indexes" array containing at least one entry covering
    (status, submittedAt) for the tasks collectionGroup
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/task_library/task_providers_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/task_library/task_providers_test.dart`, 6/6 passing.

---

## Dependencies

- Depends on: Story 001 (this epic) — `TaskModel`/`fromFirestore`. Also depends on Data Persistence Layer (Complete) — `FirestorePaths.tasks()`.
- Unlocks: Task Management UI (#19) — a future epic that displays `pendingTasksProvider`/`taskHistoryProvider`.

---

## Completion Notes

**Closed**: 2026-07-16

Implemented `pendingTasksProvider`/`taskHistoryProvider` in `src/lib/providers/task_providers.dart`, both corrected against the GDD's own code-sketch drift (`.id` → `.childId`, missing null-guard on `pendingTasksProvider`). Added `firestore.indexes.json` (single `(status ASC, submittedAt DESC)` composite index entry serving both providers) and wired `"indexes"` into `firebase.json`.

**Code review**: flame-specialist — APPROVED WITH SUGGESTIONS. Both findings actioned:
1. Story's `collectionGroup`/`.collectionGroup()` conflation corrected above (documentation-only fix).
2. Composite-index sufficiency evidence gap kept explicit in the acceptance criteria above — `--dry-run` proves JSON schema validity, not query-shape sufficiency; that requires an eventual real deploy + live query.

Fake `_FakeQuery`/`_FakeCollectionReference` in the test file reviewed as structurally sound (correct immutable builder chaining, correct filter/sort semantics) with an acknowledged, inherent gap: it cannot simulate a missing/wrong Firestore index, since neither the fake nor the local emulator enforces index requirements.

**Test evidence**: `tests/unit/task_library/task_providers_test.dart` — 6/6 passing. Full analyzer clean (baseline 11 pre-accepted `prefer_initializing_formals` lints unchanged). Full project suite: 245/245 passing (0 skipped, 1 previously-known suite-count discrepancy note not applicable here).
