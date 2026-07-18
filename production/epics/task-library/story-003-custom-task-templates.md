# Story 003: customTasks Template Write

> **Epic**: Task Library
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/task-library.md`
**Requirement**: `TR-tasklib-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Task Lifecycle & Reward Integrity, Decision §4 (`customTasks` templates, structurally distinct from task instances)

**Engine**: Flutter 3.44.4 / `cloud_firestore ^6.7.1` | **Risk**: LOW — a simple document write with no reward fields at all, structurally the SIMPLEST write in this epic (no Security Rule complexity to reason about, since `customTasks` has no reward-integrity gate — it can't, because it has no reward fields).

**Control Manifest Rules (this layer)**:
- Required: "`customTasks` are templates (`title, categoryId, targetChildId, createdAt` only) — NO `status`/`xuReward`/`energyReward` fields" — source: ADR-0009
- Forbidden: "Never let a parent set reward values directly on `customTasks` templates" — source: ADR-0009

## Already Established (do not re-derive)

- `FirestorePaths.customTasks(parentId)`/`customTask(parentId, customTaskId)` already exist (Data Persistence Layer Story 001).
- `TaskModel`/`rewardFor()` already exist (Story 001, this epic) — reward values are NEVER written into a `customTasks` document; they are re-derived from `categoryId` only when a child later picks the template and submits a real `tasks/{taskId}` instance (a future Task Submission Screen epic's concern, not this story's).
- The Security Rules for `families/{parentId}/customTasks/{customTaskId}` already exist in the deployed `firestore.rules` (`allow read, write: if request.auth.uid == parentId` — the same parent-scoped permissiveness as the rest of the family tree; `customTasks` has no reward fields to gate, so it needs no special rule beyond ownership).

---

## Acceptance Criteria

*From `design/gdd/task-library.md`'s Core Rule 4 and ADR-0009 Decision §4, Key Interfaces:*

- [x] `CustomTaskTemplate` model represents `{ title, categoryId, targetChildId, createdAt }` — exactly these 4 fields, no `status`, no `xuReward`, no `energyReward`. The absence of reward fields is structural (not present in the model at all), not just "unused."
- [x] `createCustomTaskTemplate({required String parentId, required String childId, required String title, required String categoryId})` writes a new `families/{parentId}/customTasks/{customTaskId}` document via `.add(...)` (auto-generated ID) with exactly the 4 template fields — `createdAt` via `FieldValue.serverTimestamp()`.
- [x] The write function signature makes it structurally impossible to pass a reward value in — no `xuReward`/`energyReward` parameter exists on the function at all (not merely "ignored if passed").
- [x] `title` is validated non-empty before the write is attempted (client-side; matches the GDD's edge case "Task Library không nhận task không có title" — though the GDD frames this for the real task submission, the SAME non-empty-title discipline applies here since a template with an empty title would propagate the same problem downstream). Whitespace-only titles are rejected too (`.trim().isEmpty`), and a padded-but-non-empty title is trimmed before write.
- [x] `categoryId` accepted by this function is one of the 6 known categories (`study`, `arts`, `chores`, `sport`, `helping`, `custom`) — validated client-side before the write (defense-in-depth; there is no Security Rule gate on `customTasks.categoryId` since it has no reward fields to protect, so this is a UX/data-quality guard, not a security boundary).

---

## Implementation Notes

*From ADR-0009 Decision §4 and Key Interfaces:*

```dart
// customTasks template write (Parent Dashboard #21) — no reward fields.
Future<void> createCustomTaskTemplate({required String childId, required String title, required String categoryId});
```
- Per the GDD's own explicit rationale (Core Rule 4): "Tại sao không tạo `tasks/{taskId}` với status='pending' ngay khi bố mẹ nhập" — a parent creating a template is NOT "the child completed something in real life." The real `tasks/{taskId}` instance is created later, when the child picks the template and submits — that instance-creation code is explicitly out of scope here (a future Task Submission Screen epic).
- File location: follow this project's established convention — `src/lib/core/models/custom_task_template.dart` for the model, and either `src/lib/core/custom_task_repository.dart` or a function in an existing repository-shaped file for `createCustomTaskTemplate`. Given ADR-0006's precedent (Item Database) of NOT routing global/structurally-distinct writes through `PersistenceRepository`'s existing mutation methods when the write shape doesn't fit that repository's family-tree-mutation pattern, evaluate whether this write belongs in a small dedicated function/class rather than forcing it into the existing repository — but note `customTasks` IS family-scoped (unlike the global item catalog), so check whether `PersistenceRepository` (if it has a generic "write to a family-scoped path" method already) is actually the better fit before deciding to build something new. Consult the existing `src/lib/core/` files for the established repository shape before choosing.
- `parentId` should be read from `authStateProvider` inside the calling code (a future Parent Dashboard UI story), not passed as a raw string by an untrusted caller — but for THIS story's own function signature and tests, accept it as an explicit parameter (matching the ADR's own Key Interfaces signature, which takes `childId` explicitly) to keep the function itself pure/testable without a live Riverpod container.

---

## Out of Scope

- `TaskModel`/`rewardFor()` — Story 001 (this epic).
- The REAL `tasks/{taskId}` instance creation when a child picks a template and submits — a future Task Submission Screen epic (Task Management UI #19)'s concern; this story only writes the template.
- Any UI (the "Thêm nhiệm vụ mới" form) — Parent Dashboard UI (#21)'s concern.
- Reading/listing existing `customTasks` templates (e.g. for the child's task picker to show them as options) — not explicitly required by TR-tasklib-003's own wording ("customTasks templates are structurally distinct from task instances" — a schema/write requirement, not a read requirement); flag this as a likely near-future need for Task Management UI (#19) rather than building it speculatively now.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0009 Decision §4 and this story's own Acceptance Criteria:*

```
Test: createCustomTaskTemplate writes exactly the 4 template fields, no reward fields
  Given: a fake Firestore, parentId, childId, title='Đọc sách', categoryId='study'
  When: createCustomTaskTemplate(...) is called
  Then: a new document is written to families/{parentId}/customTasks/ containing exactly
    title, categoryId, targetChildId, createdAt — no xuReward, no energyReward, no status field
    present in the written data at all

Test: createCustomTaskTemplate uses FieldValue.serverTimestamp() for createdAt
  Given: the same setup as above
  When: createCustomTaskTemplate(...) is called
  Then: the createdAt field in the write payload is a FieldValue.serverTimestamp() sentinel,
    not a client-computed DateTime.now()

Test: the function signature has no reward parameter at all
  Given: createCustomTaskTemplate's declared parameter list
  When: inspected
  Then: no xuReward/energyReward parameter exists — structurally impossible to pass one in

Test: createCustomTaskTemplate rejects an empty title before writing
  Given: title = '' (empty string)
  When: createCustomTaskTemplate(...) is called
  Then: throws/returns an error before any Firestore write is attempted — the fake records
    zero write calls

Test: createCustomTaskTemplate rejects an unknown categoryId before writing
  Given: categoryId = 'not_a_real_category'
  When: createCustomTaskTemplate(...) is called
  Then: throws/returns an error before any Firestore write is attempted
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/task_library/custom_task_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/task_library/custom_task_test.dart`, 7/7 passing.

---

## Dependencies

- Depends on: Story 001 (this epic) — reuses the same 6-category validation the reward table defines. Also depends on Data Persistence Layer (Complete) — `FirestorePaths.customTasks()`.
- Unlocks: Parent Dashboard UI (#21) — a future epic that calls `createCustomTaskTemplate` from its "Thêm nhiệm vụ mới" form.

---

## Completion Notes

**Closed**: 2026-07-16

Implemented `CustomTaskTemplate` (`src/lib/core/models/custom_task_template.dart`) and `CustomTaskRepository.createCustomTaskTemplate` (`src/lib/core/custom_task_repository.dart`), following the `ChildProfileRepository` constructor-injection pattern.

**Code review**: flame-specialist (CHANGES REQUIRED — 1 blocking) + qa-tester (GAPS) run in parallel. Both independently flagged the same rule violation; qa-tester additionally caught a real bug. All findings fixed:

1. **Blocking (both reviewers)**: a test performed filesystem I/O (`File(...).readAsLinesSync()`) to prove no reward parameter exists, violating `.claude/rules/test-standards.md`'s "unit tests must not depend on external state (filesystem, network, database)" rule. Verified the check was fully redundant with the existing behavioral assertion (`write.data.containsKey('xuReward')` etc. in test 1) — removed the file-scanning test entirely rather than reworking it, since the compile-time guarantee (no such parameter exists on the function signature at all) plus the behavioral write-shape assertion already cover the AC without touching disk.
2. **Bug (qa-tester)**: `CustomTaskTemplate` was missing the `createdAt` field the story's own AC #1 requires, and was dead code — the repository built a raw `Map` literal instead of constructing the model, so the "exactly 4 fields" invariant lived in two unlinked places. Fixed: added `createdAt` (nullable, defaults to `FieldValue.serverTimestamp()` via a new `toFirestoreMap()` method), and routed the repository write through the model instead of a raw map. This also resolves flame-specialist's separate "two sources of truth" suggestion.
3. **Minor (flame-specialist)**: title was validated non-empty but written untrimmed, allowing whitespace-padded titles to persist. Fixed: `title.trim()` on write.
4. **Advisory (qa-tester)**: added a whitespace-only-title regression test (`'   '`) to lock in the `.trim().isEmpty` guard, and strengthened the `createdAt` sentinel assertion to compare against `FieldValue.serverTimestamp()` directly (and assert inequality with `FieldValue.delete()`) rather than only checking the runtime type — closes the gap where any `FieldValue` subtype would have passed silently.

**Test evidence**: `tests/unit/task_library/custom_task_test.dart` — 7/7 passing (5 repository-level + 1 model-level `toFirestoreMap()` test + 1 new whitespace-title test; net of removing 1 filesystem test and adding 3). Full analyzer clean (baseline 11 pre-accepted `prefer_initializing_formals` lints unchanged). Full project suite: 247/247 passing.
