# Story 001: TaskModel + Authoritative Reward Lookup Table

> **Epic**: Task Library
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/task-library.md`
**Requirement**: `TR-tasklib-001`, `TR-tasklib-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Task Lifecycle & Reward Integrity, Decision §1 (lifecycle), §2 (authoritative reward table)

**Engine**: Dart / `cloud_firestore ^6.7.1` | **Risk**: LOW — a data model + a pure lookup function, following the exact same pattern already proven twice this session (`ItemModel`/`fromFirestore`, Item Database Story 001; `MoodState`/`moodForEnergy`, Pet State Machine Story 001).

**Control Manifest Rules (this layer)**:
- Required: "Task lifecycle: `pending → approved | rejected`, one doc per submission, no `cancelled`, no withdrawal" — source: ADR-0009
- Required: "Authoritative reward table (owned here): study 25/20, arts 25/20, chores 15/25, sport 15/25, helping 10/30, custom 15/25 (fallback)" — source: ADR-0009
- Forbidden: "Never let a parent set reward values directly on `customTasks` templates" — source: ADR-0009 (relevant context for this story's `rewardFor()`, even though the template write itself is Story 003's scope)

## Already Established (do not re-derive)

- The reward-integrity Security Rule (the SYNCHRONOUS enforcement mechanism) is ALREADY deployed and `security-engineer`-reviewed — `firestore.rules`' `tasks/{taskId}` block, dry-run compiled against the live Firebase project (Data Persistence Layer Story 002). This story does NOT touch `firestore.rules` — it builds the Dart-side mirror of the SAME table the rule already enforces.
- `design/registry/entities.yaml` already contains the reward constants (`task_xu_reward_study`, `task_energy_reward_helping`, etc.) — this is the canonical source ADR-0009's own Validation Criteria requires a drift-guard test against.
- `FirestorePaths.tasks(parentId, childId)`/`task(parentId, childId, taskId)` already exist (Data Persistence Layer Story 001).

---

## Acceptance Criteria

*From `design/gdd/task-library.md`'s Core Rules §1/§3 and ADR-0009 Decision §1, §2, Validation Criteria:*

- [x] `TaskModel` represents a `tasks/{taskId}` document: `title, flavorText, categoryId, xuReward, energyReward, status, submittedAt, approvedAt` (nullable), `rejectedAt` (nullable).
- [x] `status` is one of `'pending' | 'approved' | 'rejected'` — the schema has NO `cancelled` value anywhere (no enum case, no string constant) — TR-tasklib-001's "no cancelled state, no withdrawal" is enforced by absence, not by a guard that could be bypassed.
- [x] `rewardFor(String categoryId) -> ({int xu, int energy})` returns the exact authoritative table: `study: (25, 20)`, `arts: (25, 20)`, `chores: (15, 25)`, `sport: (15, 25)`, `helping: (10, 30)`, `custom: (15, 25)`.
- [x] `rewardFor` on an unknown/invalid `categoryId` falls back to the `custom` tier `(15, 25)` — matching ADR-0009's explicit "not exploitable, mid-tier not max" design, and matching the ALREADY-deployed Security Rule's own `rewardOk()` behavior (an unknown key fails the rule's `in rewardTable()` check, so an unknown-category task is rejected at write time regardless — this Dart-side fallback is for callers computing a reward BEFORE attempting the write, e.g. UI preview, not a security boundary itself).
- [x] A test asserts the Dart `rewardFor()` table's values exactly match `design/registry/entities.yaml`'s `task_xu_reward_*`/`task_energy_reward_*` constants for all 6 categories — the drift-guard ADR-0009's own Validation Criteria requires ("app reward table == registry `entities.yaml` values").
- [x] `TaskModel.fromFirestore` follows this project's established defensive-parsing conventions (`QueryDocumentSnapshot<Map<String, dynamic>>` param, `(x as num).toInt()` for `xuReward`/`energyReward`, nullable casts for `approvedAt`/`rejectedAt`).

---

## Implementation Notes

*From ADR-0009 Decision §1-§2 and Key Interfaces:*

```dart
// Reward lookup — the authoritative table (mirrors rules + registry).
({int xu, int energy}) rewardFor(String categoryId); // unknown → custom (15,25)
```
- File location: follow this project's established convention — `src/lib/core/models/task_model.dart` for `TaskModel`, and either the same file or a small `src/lib/core/reward_table.dart` for `rewardFor()` (matching the `pet_mood.dart`/`triggered_state.dart` precedent of keeping a pure lookup table in its own small file when it has independent test/reuse value — `rewardFor` will be reused by Story 004's Cloud Function reconciliation logic conceptually, though that's TypeScript, not shared code; keep it Dart-only here).
- Use Dart records (`({int xu, int energy})`) for the return type, matching the ADR's own Key Interfaces signature exactly — do not invent a separate class for this unless there's a clear reason to.
- `energyReward` in the actual Firestore schema is stored as a `double` per ADR-0009's Migration Plan note ("confirm int/float auto-widening... the schema stores `energyReward` as double") — but `rewardFor()`'s return and the GDD's own reward table are always whole numbers (20, 25, 30, etc.). Store `TaskModel.energyReward` as `int` in the Dart model (matching `xuReward`, matching how `computeEnergy`/`ItemModel` handle the same num/int Firestore ambiguity) — parse via `(data['energyReward'] as num).toInt()`, same defensive pattern as `xuReward`.
- `categoryId` is stored as a plain `String` on `TaskModel` (not an enum) — matching `ItemModel.category`'s precedent (Item Database Story 001) for consistency across this codebase's Firestore-backed string-enum fields.

---

## Out of Scope

- The Security Rule itself — already deployed (Data Persistence Layer Story 002); this story does not touch `firestore.rules`.
- `pendingTasksProvider`/`taskHistoryProvider` — Story 002 (this epic).
- `customTasks` template model/write — Story 003 (this epic).
- `onTaskApproved`'s reward reconciliation — Story 004 (this epic).
- Any task CREATION/submission code (the actual `tasks/{taskId}.set(...)` call) — that belongs to a future Task Submission Screen epic (Task Management UI #19); this story only defines the model and the pure reward lookup, not the write path.
- The approve/reject transaction itself — Parent Approval (#11), a future epic.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0009's Validation Criteria and this story's own Acceptance Criteria:*

```
Test: rewardFor returns the exact authoritative table for all 6 known categories
  Given: categoryId in {study, arts, chores, sport, helping, custom}
  When: rewardFor(categoryId) is called for each
  Then: returns exactly (25,20), (25,20), (15,25), (15,25), (10,30), (15,25) respectively

Test: rewardFor falls back to custom tier for an unknown categoryId
  Given: categoryId = 'bogus_category'
  When: rewardFor(categoryId) is called
  Then: returns (15, 25) — the same as 'custom', not an exception, not (0,0)

Test: rewardFor table matches design/registry/entities.yaml exactly (drift guard)
  Given: the registry file's task_xu_reward_*/task_energy_reward_* constants, read directly
  When: compared against rewardFor()'s output for each of the 6 categories
  Then: every value matches exactly — this test fails loudly if either the app table or the
    registry drifts out of sync with the other

Test: TaskModel has no cancelled status value anywhere in its schema
  Given: TaskModel's status type/constants
  When: inspected
  Then: only 'pending', 'approved', 'rejected' are representable — no 'cancelled' case exists

Test: TaskModel.fromFirestore parses a complete pending task correctly
  Given: a QueryDocumentSnapshot with title, flavorText, categoryId='chores', xuReward=15,
    energyReward=25, status='pending', submittedAt=<timestamp>, approvedAt=null, rejectedAt=null
  When: TaskModel.fromFirestore(doc) is called
  Then: every field matches exactly, approvedAt/rejectedAt are null

Test: TaskModel.fromFirestore handles xuReward/energyReward stored as doubles
  Given: a QueryDocumentSnapshot with xuReward=15.0, energyReward=25.0 (doubles)
  When: TaskModel.fromFirestore(doc) is called
  Then: does not throw; both fields parse as int
```

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/task_library/task_model_test.dart` — must exist and pass

**Status**: [x] Created — `tests/unit/task_library/task_model_test.dart`, 7/7 passing.

---

## Dependencies

- Depends on: None (pure Dart, no dependency on any other epic's code beyond the already-Complete `FirestorePaths` — not even used directly by this story's model/lookup code).
- Unlocks: Story 002 (this epic) — `pendingTasksProvider`/`taskHistoryProvider` map through `TaskModel.fromFirestore`. Story 004 (this epic) — the reward table's Dart-side values inform what the Cloud Function reconciliation logic must match (conceptually; the CF itself is TypeScript, not shared code).

---

## Completion Notes

**Closed**: 2026-07-16

Implemented `TaskModel`/`TaskModel.fromFirestore` (`src/lib/core/models/task_model.dart`) and the authoritative `rewardFor()` lookup (`src/lib/core/reward_table.dart`), mirroring the already-deployed Security Rule's `rewardTable()`/`rewardOk()` CEL functions (Data Persistence Layer Story 002).

**Code review**: flame-specialist — APPROVED WITH SUGGESTIONS. Both suggestions actioned:
1. Comment-filter style in the drift-guard test aligned to `//`-prefix filtering (matching sibling test files).
2. `entities.yaml` gap flagged: no `task_xu_reward_custom`/`task_energy_reward_custom` registry entries exist. GDD's own Tuning Knobs table states custom's reward is "same as chores/sport" by design, so the drift-guard validates `custom` against the `chores` registry entries instead. Filed as an out-of-scope cross-epic registry gap via `spawn_task` (`task_fe9939b6`) rather than editing `entities.yaml` directly from this story.

**Test evidence**: `tests/unit/task_library/task_model_test.dart` — 7/7 passing, including the `entities.yaml` drift-guard (parses the registry's `constants:` key) and the comment-filtered "no cancelled" check. Full analyzer clean.
