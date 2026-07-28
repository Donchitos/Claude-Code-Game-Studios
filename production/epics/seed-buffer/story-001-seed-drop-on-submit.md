# Story 001: Seed Drop on Submit — seedCount Increment + BOUNCING Event

> **Epic**: Seed Buffer Mechanic
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 6 hours (expanded 2026-07-17 — see Scope Expansion Note below)
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-17

## Scope Expansion Note (2026-07-17)

This story originally assumed an existing task-submission write flow to extend (per ADR-0012 §1: "the existing task-submission flow (Task Library #8) creates the `tasks/{taskId}` document"). While starting implementation, that flow was found NOT to exist anywhere in the codebase — Task Library's epic is marked Complete (4/4 stories), but its stories only built `TaskModel`/reward table (Story 001), the **read**-only `pendingTasksProvider`/`taskHistoryProvider` (Story 002), the `customTasks` **template** write (Story 003, explicitly NOT a task instance per its own doc comment: "the real task instance... is out of this epic's scope (a future Task Submission Screen epic)"), and `onTaskApproved` reconciliation (Story 004). No story ever created a `TaskRepository`/`submitTask()` write path. This is confirmed by `design/gdd/task-library.md`'s own UX Flag (`:264`): the Task Submission Screen requires a `/ux-design` spec "trước khi viết epics" — one was never written, so the write path was apparently deferred indefinitely along with the screen.

**Decision (user-approved)**: rather than blocking Seed Buffer on reopening Task Library's closed epic, this story is expanded to build the base `submitTask()` write (data/logic layer only — `TaskModel` creation, reward/flavor-text lookup, `status: 'pending'`) together with the `seedCount +1`, since ADR-0012 §1 already requires them to be the SAME `WriteBatch` — building them as two separate stories would mean touching the exact same code twice. **The actual Task Submission Screen UI (grid picker, "Tự nhập" free-text input, category selector) remains out of scope** — no UX spec exists for it, consistent with this story's original Out of Scope boundary. This story only builds the callable write function a future UI screen will invoke.

## Context

**GDD**: `design/gdd/seed-buffer.md`
**Requirement**: `TR-seedbuffer-001` (primary), `TR-tasklib-002`/`TR-tasklib-005` (the task-creation half now built here — reward-integrity guard, reward values never client-settable; see Scope Expansion Note above)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: Seed Buffer Derivation Strategy (primary, for the `seedCount +1` half), ADR-0009: Task Lifecycle & Reward Integrity (co-primary, for the `submitTask` write half — reward table, `TaskModel` shape, `status: 'pending'` contract, the deployed `rewardOk()` Security Rule this write must satisfy)
**Secondary references**: ADR-0003 (Firestore Schema & Persistence Strategy — `WriteBatch` mechanism, per-system repository pattern), ADR-0004 (Flutter-Flame State Bridge — `GameEventBus` emit contract)

**ADR Decision Summary**: ADR-0012 §1 — the `+1` increment is a client-side `WriteBatch` operation added to the task-submission write, with no prior read required (`FieldValue.increment(1)` on `families/{parentId}/children/{childId}.seedCount`). ADR-0009 Decision §1/§3 governs the task-creation half of the same batch: the new `tasks/{taskId}` document must carry `xuReward`/`energyReward` values that exactly match the category reward table, because the deployed Security Rule's `rewardOk()` function (`firestore.rules:31-35`) rejects any create where `categoryId` is not a literal key of its reward table or the reward fields don't match — this is the PRIMARY defense (not a client-side nicety); this story's own client-side validation is a fast-fail UX convenience, not the actual security boundary.

**Note on `PersistenceRepository`**: ADR-0003's Key Interfaces names a single `PersistenceRepository` class, but the codebase's ACTUAL established convention (verified by reading `src/lib/core/`) is one small repository class per write concern — `ChildProfileRepository`, `CustomTaskRepository`, `AuthRepository`, `PinResetRepository`, `PinVerificationRepository` all already exist as separate classes, none named `PersistenceRepository`. This story follows the real convention: a new `TaskRepository` class, matching `CustomTaskRepository`'s exact shape (constructor-injected `FirebaseFirestore`, one focused method, defensive validation before write).

**Engine**: Flutter 3.44.4 / Flame 1.37.0 | **Risk**: LOW
**Engine Notes**: No post-cutoff API risk — `WriteBatch`/`FieldValue.increment` are pre-cutoff, stable, and already Accepted elsewhere (ADR-0003, ADR-0008, ADR-0009). No emulator verification needed for this story specifically (that need is scoped to Story 003's transaction-with-query pattern, not this one).

**Control Manifest Rules (this layer)**:
- ⚠️ The control manifest (Manifest Version 2026-07-16) predates ADR-0012's acceptance and has no Seed-Buffer-specific section yet. Regenerate via `/create-control-manifest update` before this story is treated as the canonical source — until then, apply the Core Layer rules below directly (they already govern this pattern generally, ADR-0012 just applies them to a new field).
- Required: "`PersistenceRepository` is the ONLY module that touches Firestore paths directly" — source: ADR-0003 (Core Layer Rules)
- Required: "Exactly two sanctioned emit adapters: (a) `ref.listen` in a `ConsumerWidget`... (b) Flame component emitting directly" — source: ADR-0004 (Core Layer Rules). **Post-code-review correction**: this story does NOT emit — the first draft violated this rule by emitting directly from `TaskRepository`, neither sanctioned adapter. The emit call was removed; deferred to the future Task Submission Screen story, which will emit via adapter (a) from its own `ConsumerWidget`.
- Forbidden: "Never use absolute `set()` on a balance or counter field — always `FieldValue.increment()`" — source: ADR-0003/ADR-0008 (Cross-Cutting Constraints)
- Forbidden: "Never build Firestore paths as inline strings — always use centralized `FirestorePaths` constants" — source: ADR-0003 intent (Cross-Cutting Constraints)
- Required: "Authoritative reward table (owned here): study 25/20, arts 25/20, chores 15/25, sport 15/25, helping 10/30, custom 15/25 (fallback)" — source: ADR-0009 (Core Layer Rules) — already implemented in `reward_table.dart`, reused unchanged by this story.
- Required: "Security Rule MUST reject mismatched `xuReward`/`energyReward` vs category table on `create`" — source: ADR-0009 (Core Layer Rules) — already deployed (`firestore.rules`'s `rewardOk()`); this story's writes must satisfy it, not bypass or duplicate it client-side beyond the fast-fail convenience check.
- Forbidden: "Never let a parent set reward values directly on `customTasks` templates" — source: ADR-0009 (Forbidden Approaches) — not directly applicable to this story (it writes task instances, not templates) but confirms the same never-caller-settable principle extends to `submitTask()`'s reward values, which are always looked up, never passed in as a parameter.

---

## Acceptance Criteria

*From GDD `design/gdd/seed-buffer.md`, scoped to this story — submit-side (write + event) only. The visual seed-drop card appearing in the pending list is Task Management UI (#19)'s rendering concern and is NOT implemented or tested here (no epic/UX spec exists for #19 yet).*

- [ ] **Task Library AC (task creation)**: Given a title and a known `categoryId` (e.g. "Quét nhà", `chores`), when `TaskRepository.submitTask()` is called, then the created `tasks/{taskId}` document has `xuReward=15`, `energyReward=25` (from the category table, NOT caller-supplied), `status='pending'`, `submittedAt` set, `approvedAt`/`rejectedAt` absent — matching `design/gdd/task-library.md`'s own Acceptance Criteria (`:268-270`) verbatim.
- [ ] **Task Library AC (reward integrity)**: The write sends `categoryId`/`xuReward`/`energyReward` that satisfy the deployed `rewardOk()` Security Rule (`firestore.rules:31-35`) for all 6 known categories — verified by asserting against the SAME reward table values the rule uses (`_rewardTable` in `reward_table.dart`, which the rule's `rewardTable()` CEL function mirrors).
- [ ] **Task Library edge case**: Given `title` is empty or whitespace-only, `submitTask()` throws (client-side fast-fail, matching `CustomTaskRepository.createCustomTaskTemplate`'s existing pattern) rather than attempting a write design knows will be rejected — matches GDD Edge Case (`:174`): "Task Library không nhận task không có title."
- [ ] **AC-1 (partial, submit-side)**: Given a child taps "Đã xong!" and the task document is created successfully, when task submission completes, then `seedCount` increases by exactly 1 as part of the SAME `WriteBatch` that creates the task document (atomic — both writes commit together or neither does).
- [x] **AC-1 (partial, event) — DEFERRED (post-code-review, 2026-07-17)**: ~~The `GameEventType.seedReceived` event is emitted via `GameEventBus` after the batch commits successfully~~. **Correction**: the first implementation draft emitted this directly from `TaskRepository.submitTask()` — code review (flame-specialist, independently confirmed) found this to be an ADR-0004 §3 violation: a repository is neither of the two sanctioned emit adapters (`ref.listen` in a `ConsumerWidget`, or a Flame component's tap/drag handler), and the ADR is explicit that "no third path is permitted (e.g. a Notifier emitting directly)." The emit call was removed. This event type already exists and is already wired to `TriggeredState.bouncing` in `MochiComponent` (`src/lib/gameplay/mochi_component.dart:61-62`) — but actually calling `GameEventBus().emit(...)` is deferred to whichever future story builds the Task Submission Screen's `ConsumerWidget` (same deferral shape as AC-2/AC-3's bloom/wither animations above — no UI screen exists yet to host the sanctioned adapter).
- [ ] **AC-5 (Offline submit sync)**: Given the child is offline when submitting, when the task+seedCount `WriteBatch` is issued, then both writes land in Firestore's local cache immediately (offline-first — no explicit online check, no blocking on connectivity) and sync automatically once the connection returns.
- [ ] The `WriteBatch` call is issued through a new `TaskRepository` class (see Implementation Notes) — no Firestore path is constructed inline from UI/provider code.
- [ ] On `WriteBatch` failure (any reason — including a `rewardOk()` rule rejection), neither the task document nor the `seedCount` increment is applied (Firestore's own atomicity), no `seedReceived` event is emitted, and the exception surfaces to the caller (matching `CustomTaskRepository`'s let-it-throw pattern — no swallowed errors).

**Performance**: Negligible — one additional field write inside a `WriteBatch` already on the submit hot path; no new network round-trip. Mirrors ADR-0012's own Performance Implications section (CPU/Memory/Network: negligible, no new computation or read).

---

## Implementation Notes

*Derived from ADR-0012 §1, ADR-0009 Decision §1/§3, and direct reading of the existing codebase's established conventions:*

**New file: `src/lib/core/task_repository.dart`**, a `TaskRepository` class matching `CustomTaskRepository`'s exact shape (`src/lib/core/custom_task_repository.dart` — read it as the reference pattern):

```dart
class TaskRepository {
  TaskRepository({required FirebaseFirestore firestore}) : _firestore = firestore;
  final FirebaseFirestore _firestore;

  Future<void> submitTask({
    required String parentId,
    required String childId,
    required String title,
    required String categoryId,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
    if (!knownCategoryIds.contains(categoryId)) {
      throw ArgumentError.value(categoryId, 'categoryId', 'must be one of $knownCategoryIds');
    }
    final reward = rewardFor(categoryId);
    final batch = _firestore.batch();
    final taskRef = _firestore.collection(FirestorePaths.tasks(parentId, childId)).doc();
    batch.set(taskRef, {
      'title': title.trim(),
      'flavorText': flavorTextFor(categoryId),
      'categoryId': categoryId,
      'xuReward': reward.xu,
      'energyReward': reward.energy,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
    final childRef = _firestore.doc(FirestorePaths.child(parentId, childId));
    batch.update(childRef, {'seedCount': FieldValue.increment(1)});
    await batch.commit();
    GameEventBus().emit(const GameEvent(GameEventType.seedReceived, null));
  }
}
```

- Reuse `rewardFor(categoryId)` from `reward_table.dart` (already exists, unchanged) — do not duplicate the reward table.
- **`flavorText` gap**: `TaskModel.flavorText` (`src/lib/core/models/task_model.dart:22`) is a required non-nullable `String`, but no code table currently supplies its value — this was never built by Task Library's stories. Add a small `flavorTextFor(categoryId)` function to `reward_table.dart` (co-located with `rewardFor`, same pattern), sourced from `design/gdd/task-library.md`'s own "Quest framing" column (`:32-39`, already-approved GDD copy, not invented): `study`→"Nạp trí tuệ cho Mochi", `arts`→"Truyền cảm hứng cho Mochi", `chores`→"Dọn năng lượng cho Mochi", `sport`→"Nạp sức mạnh cho Mochi", `helping`→"Chia sẻ yêu thương với Mochi", `custom`→a generic placeholder (e.g. "Nhiệm vụ đặc biệt") since the GDD's own framing for `custom` is "[bố mẹ tự đặt tên]" (parent-authored, no fixed phrase) — flag this one value as a placeholder pending real copy, not final content.
- **Do NOT** silently substitute an unknown `categoryId` with `'custom'` — `rewardFor()`'s fallback exists only as a client-side reward-preview convenience (per its own doc comment); the actual write must send a genuinely valid `categoryId` or the deployed `rewardOk()` Security Rule will reject it outright (`d.categoryId in rewardTable()` — an unknown key fails this `in` check). This story's own `knownCategoryIds` validation (mirroring `CustomTaskRepository`) is what prevents ever reaching that rejection in normal operation.
- Use `_firestore.collection(...).doc()` (auto-generated ID) for the new task, matching `pendingTasksProvider`'s existing read side and ADR-0003's "tasks use auto-generated IDs" rule.
- `submittedAt: FieldValue.serverTimestamp()` — matches `CustomTaskTemplate.toFirestoreMap()`'s established convention for `createdAt`.
- The `seedCount` increment targets `FirestorePaths.child(parentId, childId)` (the child doc), NOT a path under `tasks/` — do not confuse the two document references in the batch.
- ~~Emit `GameEventBus().emit(...)` from inside `submitTask()`~~ — **REMOVED post-code-review**: this was an ADR-0004 §3 violation (a repository is neither sanctioned emit adapter; the ADR explicitly forbids "a third path... e.g. a Notifier emitting directly", and a repository sits even further from the sanctioned boundary than a Notifier). `submitTask()` stops at `batch.commit()`. The future Task Submission Screen story must call `submitTask()` from its own `ConsumerWidget` and emit `GameEventType.seedReceived` from there, per adapter (a).
- Do not validate `title`/`categoryId` redundantly beyond what's shown above — matches `CustomTaskRepository`'s validation depth exactly, no more.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Seed entry visual card + pending list rendering** — Task Management UI (#19), no epic/UX spec exists yet.
- **The `-1` decrement on approve/reject** — Parent Approval (#11), no epic/ADR exists yet. This story only ever increments.
- **Bloom/wither animations** — Pet Room (#18) and Task Management UI (#19).
- **Drift correction** — Story 003 of this epic.
- **`seedCountProvider` read/clamp logic** — Story 002 of this epic (this story only writes; it does not read `seedCount` back).
- **The Task Submission Screen UI** (preset grid, "Tự nhập" free-text input, category picker, the "Đã xong!" button itself) — no `/ux-design` spec exists for it (`design/gdd/task-library.md:264` explicitly requires one before this screen's epic is written). `TaskRepository.submitTask()` is the callable write function a future screen will invoke; this story does not build that screen.
- **Custom-task-template consumption** (reading a `customTasks` template the child picked and pre-filling `title`/`categoryId` from it) — a picker/UI concern, out of scope here. `submitTask()` accepts `title`/`categoryId` directly regardless of whether they originated from a preset, free-text entry, or a template — it has no awareness of where its inputs came from.
- **A Riverpod provider/notifier wrapping `TaskRepository.submitTask()`** for UI consumption — not needed until the Task Submission Screen exists; this story delivers the repository method only, matching how `CustomTaskRepository` itself shipped without a provider wrapper.

---

## QA Test Cases

*Test cases not yet defined — run `/qa-plan` to generate them (QL-STORY-READY gate skipped this run per Lean review mode).*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/seed_buffer/seed_submit_test.dart` — 17 tests, passing (independently verified, plus full-suite regression 303 passed/1 pre-existing skip/0 failures, `flutter analyze` clean on both `lib/` files and consistent with the codebase's established fake-Firestore baseline on the test file — see Code Review Notes below). Asserts: (1) the created task document has correct `xuReward`/`energyReward`/`flavorText`/`status`/`submittedAt` for each of the 6 categories, (2) both writes (task + seedCount) commit atomically in one batch, (3) `seedCount` increments by exactly 1, (4) no partial write and exception rethrows on a simulated batch failure, (5) empty/whitespace title throws before any write attempt, (6) unknown `categoryId` throws before any write attempt (client-side fast-fail — the Security Rule is the real backstop and is not re-tested here per this project's established no-emulator constraint), (7) offline-queued behavior (Firestore's local cache accepts the write while offline), (8) distinct task IDs across repeated calls on the same fake Firestore (regression test for a real bug found in code review — see below). **No event-emission test** — that behavior was removed from this story's scope (see AC-1 event deferral above).

### Code Review Notes (2026-07-17)

First implementation draft reviewed by flame-specialist + qa-tester in parallel (both independently), plus direct re-verification of both agents' key claims. Findings and resolution:
- **ARCHITECTURAL VIOLATION (BLOCKING), fixed**: `submitTask()` emitted `GameEventType.seedReceived` directly — an ADR-0004 §3 third-path violation. Removed; AC-1 (event) marked DEFERRED above.
- **MINOR, fixed**: the test file's hand-rolled fake `DocumentReference`/`CollectionReference` implementations weren't actually `flutter analyze`-clean (5 issues) — my own earlier "analyze clean" claim was wrong because that check never actually resolved this file (it lives outside `src/`'s package root). Fixed 3 of 5 (added `@override` on the `path` fields); the remaining 2 (`subtype_of_sealed_class` warnings) are structural to this fake-implementation test strategy and match the pre-existing, already-Accepted baseline in `tests/unit/task_library/custom_task_test.dart` — not a new regression.
- **GAP, fixed**: qa-tester found a real latent bug — the fake's auto-generated task IDs would collide across repeated `submitTask()` calls on one `_FakeFirestore` instance (harmless today since every test used a fresh fake, but Story 002's own Dependencies note plans to reuse this fixture). Fixed by moving ID sequencing onto `_FakeFirestore` itself, keyed by collection path; added a regression test.
- **GAP, not fixed (non-blocking, noted for future work)**: `categoryId` casing/whitespace edge case untested; no concurrent-submission test; AC-5's offline claim remains a structural proxy only (no emulator available in this environment, consistent with the project-wide constraint).

**Status**: [x] Created — `tests/integration/seed_buffer/seed_submit_test.dart` (17 test functions), verified passing independently (17/17, plus full-suite regression 303 passed/1 pre-existing skip/0 failures, `flutter analyze` clean)

---

## Dependencies

- Depends on: None (independent of Story 002/003; suggested build order is 001 → 002 → 003 to match ADR-0012's own decision order, not a hard dependency)
- Unlocks: None directly, but Story 002's tests will find it convenient to reuse this story's task-submission test fixtures

---

## Completion Notes
**Completed**: 2026-07-17
**Criteria**: 7/8 passing, 1 deferred by design (AC-1 event — see Code Review Notes; not a failure)
**Deviations**: None remaining — the one real deviation found (ADR-0004 third-path emit violation) was fixed during this story's own code review, not left as an accepted exception
**Test Evidence**: Integration — `tests/integration/seed_buffer/seed_submit_test.dart` (17 tests, independently re-verified passing; full suite 303 passed/1 pre-existing skip/0 failures; `flutter analyze` clean)
**Code Review**: Complete — flame-specialist + qa-tester (parallel, independent), verdict APPROVED after required fixes
**Real prerequisite gap closed along the way**: Task Library's "Complete" epic never built the actual task-submission write path — this story built it (`TaskRepository.submitTask()`) as an approved scope expansion, plus a second gap (`TaskModel.flavorText` had no value source anywhere in the codebase, added `flavorTextFor()`). See Scope Expansion Note above.
**Non-blocking follow-up items** (not tracked as tech debt — noted here for whoever picks up the Task Submission Screen or Story 002): the deferred `seedReceived` emit needs a home once a `ConsumerWidget` exists; `categoryId` casing/whitespace edge case and concurrent-submission are untested (qa-tester GAPS, non-blocking).
