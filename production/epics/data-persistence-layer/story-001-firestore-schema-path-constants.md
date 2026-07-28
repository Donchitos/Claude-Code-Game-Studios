# Story 001: Complete Firestore Schema & Path Constants

> **Epic**: Data Persistence Layer
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/data-persistence-layer.md`
**Requirement**: `TR-data-persistence-002` (complete schema), `TR-data-persistence-008` (document size budget, verified by inspection within this story — not a separate deliverable)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Firestore Schema & Persistence Strategy, Decision §2

**Engine**: Flutter 3.44.4 / `cloud_firestore` (resolved `^6.7.1`, per `src/pubspec.yaml`) | **Risk**: LOW — pure path-string construction, no persistence-settings API surface (that part is TR-001, already done — see Already Satisfied note below)

**Control Manifest Rules (this layer)**:
- Required: "No system builds Firestore paths by hand" / "`FirestorePaths`... path constants centralized there" — source: ADR-0003
- Required: Document size must stay under Firestore's 1MB hard limit — source: ADR-0003

## Already Satisfied (do not re-implement)

- **TR-data-persistence-001** (offline persistence + unlimited cache set once in `main()`): already correct in `src/lib/main.dart` — built during auth-account Story 001, before this epic existed. Uses the corrected `Settings(persistenceEnabled:, cacheSizeBytes:)` pair (verified against the actually-resolved `cloud_firestore ^6.7.1`, not the ADR's original wrong `cacheSettings`/`PersistentCacheSettings` claim — see ADR-0003's 2026-07-13 Correction note). No action needed.
- **TR-data-persistence-006** (`onChildProfileDelete` recursive delete): already deployed in `functions/src/index.ts`, built during auth-account Story 009. No action needed.
- `src/lib/core/firestore_paths.dart` already exists with `family()`, `children()`, `child()`, `childCredentials()` — built during auth-account Stories 001/005, ahead of this epic. **This story extends that file** (add missing paths), it does not create it.

---

## Acceptance Criteria

*From `design/gdd/data-persistence-layer.md`'s Detailed Design §2 schema and ADR-0003 Decision §2:*

- [x] `FirestorePaths` exposes path constants for `tasks` (collection) and a single `task` (document), scoped to `families/{parentId}/children/{childId}/tasks[/{taskId}]`.
- [x] `FirestorePaths` exposes path constants for `customTasks` (collection) and a single `customTask` (document), scoped to `families/{parentId}/customTasks[/{customTaskId}]` — family-scoped, NOT child-scoped (per the GDD's explicit note: a parent picks `targetChildId` at creation time, so the template collection itself doesn't nest under a child).
- [x] `FirestorePaths` exposes path constants for `inventory` (collection) and a single `inventoryItem` (document), scoped to `families/{parentId}/children/{childId}/inventory[/{itemId}]`.
- [x] Every new path-building method has a doc comment stating which fields the document at that path holds (matching the existing `childCredentials` doc comment's style) — this doc comment is this story's way of ratifying the complete schema in code, not just in the GDD/ADR prose.
- [x] A unit test asserts each new path constant produces the exact string shape specified in ADR-0003 Decision §2 (e.g. `FirestorePaths.tasks('p1', 'c1') == 'families/p1/children/c1/tasks'`).
- [x] Doc comments note the ~500/200/100-byte estimated actual sizes from the GDD's Document size budget table (all far under Firestore's 1MB hard limit — TR-008 is satisfied by construction, this AC just makes that traceable in code rather than only in the GDD).

---

## Implementation Notes

*From ADR-0003 Decision §2 (schema) and Decision §3 (write contracts, referenced for context only — not implemented by this story):*

- Mirror the existing `child()`/`childCredentials()` pattern exactly: a collection-path method and a document-path method per resource, both pure functions of `parentId`/`childId`/(optional resource ID).
- `customTasks`/`customTask` do NOT take a `childId` parameter — they're family-scoped (`families/{parentId}/customTasks/{customTaskId}`), per the GDD's explicit note that this differs from `tasks` (child-scoped). Getting this scoping wrong would misplace every custom-task read/write for whichever epic (Parent Dashboard UI #21) eventually implements it — this story exists specifically so that mistake can't happen later.
- Do NOT add methods for fields owned by other systems (e.g. no `xuBalance`-specific path — that's just a field on the `child()` document, not a separate path). `FirestorePaths` only grows a new method when a new **document or collection root** is added to the schema, never per-field.
- Do NOT implement `PersistenceRepository` or any read/write logic in this story — ADR-0003's own Ordering Note is explicit that per-system business logic (submitTask, buyItem, approveTask, equipItem) belongs to the epic that owns that behavior (Task Library, Shop, Parent Approval, Pet Equipment respectively), not this one. This story is path constants and schema documentation only.

---

## Out of Scope

- TR-001 (Firestore init) — already done, see Already Satisfied above.
- TR-006 (`onChildProfileDelete`) — already done, see Already Satisfied above.
- TR-003/004 (write contracts, `FieldValue.increment()` rule) — these are patterns enforced when downstream epics (Currency #7, Task Library #8, Parent Approval #11, Pet Equipment #15) implement their own repository methods against this schema; not a standalone deliverable of this story. Already documented in `docs/architecture/control-manifest.md`'s Core Layer Rules.
- Story 002 (this epic): Security Rules deployment — reads the same schema this story defines, but is a separate `firestore.rules` file, not Dart code.
- Story 003 (this epic): `onTaskApproved` Cloud Function.
- Any actual read/write logic — that belongs to whichever epic owns the behavior touching a given path.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0003 has no dedicated Validation Criteria line for path-constant correctness specifically (its Validation Criteria section focuses on write-contract/rules behavior, covered by Stories 002/003) — test cases below are derived directly from this story's own Acceptance Criteria, each of which is independently a concrete, testable string-equality assertion:*

```
Test: FirestorePaths exposes correct tasks/task paths
  Given: parentId='p1', childId='c1' (and taskId='t1' for the document variant)
  When: FirestorePaths.tasks('p1', 'c1') / FirestorePaths.task('p1', 'c1', 't1') are called
  Then: returns 'families/p1/children/c1/tasks' / 'families/p1/children/c1/tasks/t1' exactly
  Edge cases: none — pure string interpolation, no branching

Test: FirestorePaths exposes correct customTasks/customTask paths (family-scoped, no childId)
  Given: parentId='p1' (and customTaskId='ct1' for the document variant)
  When: FirestorePaths.customTasks('p1') / FirestorePaths.customTask('p1', 'ct1') are called
  Then: returns 'families/p1/customTasks' / 'families/p1/customTasks/ct1' exactly — no childId segment anywhere in the path
  Edge cases: none

Test: FirestorePaths exposes correct inventory/inventoryItem paths
  Given: parentId='p1', childId='c1' (and itemId='i1' for the document variant)
  When: FirestorePaths.inventory('p1', 'c1') / FirestorePaths.inventoryItem('p1', 'c1', 'i1') are called
  Then: returns 'families/p1/children/c1/inventory' / 'families/p1/children/c1/inventory/i1' exactly
  Edge cases: none
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/data_persistence/firestore_paths_test.dart` — must exist and pass

**Status**: Created, 6/6 passing

---

## Dependencies

- Depends on: None (auth-account epic, already Complete, established the `FirestorePaths` file this story extends)
- Unlocks: Story 002 (Security Rules reference these same paths), and indirectly every downstream epic that reads/writes `tasks`/`customTasks`/`inventory` (Task Library #8, Parent Dashboard UI #21, Shop #13, Gacha/Loot #12)

---

## Completion Notes

**Completed**: 2026-07-16

**Files changed**:
- `src/lib/core/firestore_paths.dart` — added `tasks()`/`task()`, `customTasks()`/`customTask()`, `inventory()`/`inventoryItem()`, each with a doc comment listing fields and estimated document size.
- `tests/unit/data_persistence/firestore_paths_test.dart` — new, 6 tests.

**Criteria**: 6/6 passing, all covered by automated tests.

**Deviations**: None. Confirmed during epic decomposition that `TR-data-persistence-001` and `TR-data-persistence-006` were already satisfied by auth-account Stories 001/009 respectively — no new work needed for those, documented in EPIC.md rather than silently re-implemented or silently skipped.

**Code Review**: Complete — `flame-specialist` (single reviewer; this is the smallest, lowest-risk story in the epic — pure static string-building functions, no I/O). Verdict: zero required changes. Path shapes, family-vs-child scoping (`customTasks` correctly has no `childId` param), and scope discipline (no `PersistenceRepository`, no per-field methods) all confirmed correct. One suggestion applied: added a byte-size estimate to the `customTasks` doc comment for consistency with `tasks`/`inventory`.

**Test Evidence**: `tests/unit/data_persistence/firestore_paths_test.dart` (6/6 passing). Full Dart suite: 120/120 passing (+1 pre-existing skip). `flutter analyze`: clean (10 pre-accepted cosmetic lints, unchanged pattern).
