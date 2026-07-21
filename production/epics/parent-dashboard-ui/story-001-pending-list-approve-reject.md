# Story 001: Nhiệm vụ Tab — Pending List, Approve/Reject Wiring & Event Emission

> **Epic**: Parent Dashboard UI
> **Status**: **Blocked**
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-18

## ⚠️ BLOCKED (found during `/dev-story`, 2026-07-18)

`ui-programmer` stopped before writing code and found 3 real architectural gaps, independently verified:

1. **Main Navigation Shell (#17) has no real implementation** — `src/lib/providers/router_provider.dart` only has flat placeholder routes (`/parent-dashboard` → a bare placeholder screen). No `StatefulShellRoute`, no tab branches, no `/parent/dashboard`/`/parent/family` routes, no `/select-child` route. No epic for it exists in `production/epics/index.md` despite its own Approved UX spec (`design/ux/main-navigation-shell.md`). **This is the blocker** — there is no real shell to render this story's content into.
2. `pendingTasksProvider` (Task Library #8) is scoped to `activeChildProvider` (one child at a time), not family-wide — breaks AC-2 (multi-child correctness) and returns empty for the primary "parent logs in directly, no active child session" flow. Needs a `familyPendingTasksProvider` or `collectionGroup` query — Task Library's domain, not this story's.
3. `TaskModel.fromFirestore` captures neither the document `id` nor `childId` — both required to call `approveTask()`/`rejectTask()` and to resolve per-card avatar/name. Small, additive fix, but still Task Library's file.

User decision: pause this story, build Main Navigation Shell as its own epic first (`/create-epics main-navigation-shell` → `/create-stories` → implement), then return here once a real route exists to render into. Gaps 2–3 are flagged separately for Task Library's owner.

## Context

**GDD**: `design/gdd/parent-dashboard-ui.md`
**Requirement**: `TR-parentdash-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: N/A — no dedicated ADR exists for this screen. Implementation must follow **ADR-0013** (Parent Approval Transaction Architecture, Accepted) for `approveTask()`/`rejectTask()`'s contract, and **ADR-0004** (Flutter-Flame Event Bridge Architecture, Accepted) for the event-emission rule below.
**ADR Decision Summary**: This story is the **first real caller** of `ParentApprovalRepository.approveTask()`/`rejectTask()` in the whole app. Per ADR-0013 §2, the repository returns a result and emits nothing — event emission is explicitly the caller's job, described there as "a future Parent Dashboard ConsumerWidget." This story IS that caller.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 — pure Flutter widget layer, no Flame in this story | **Risk**: MEDIUM (carried from ADR-0004's Flame lifecycle risk — the events this story emits are consumed by a Flame component elsewhere, so correctness here has downstream impact even though this story never touches Flame directly)
**Engine Notes**: This story is the trigger point for the **GameEventBus replay risk** documented in ADR-0013's Consequences and carried into Parent Approval epic's Known Risks (`production/epics/parent-approval/EPIC.md`) — once this story emits a real `taskApproved`/`petLeveledUp` event, any Flame component that remounts (e.g. Pet Room navigated away and back) will receive a spurious replay. The risk lives on the *consumer* side (Pet Room's `MochiComponent`), not here — this story's obligation is to emit correctly and explicitly acknowledge the risk in its Completion Notes, per Parent Approval epic's DoD item 5, which transfers to this story.

**Control Manifest Rules (this layer)**:
- Required: Exactly two sanctioned `GameEventBus` emit adapters exist — a `ConsumerWidget` reacting to a completed user-initiated action (via `ref.listen` or a direct post-await emit in a tap handler) is adapter (a). This story's Approve button handler IS that adapter — source: ADR-0004 §3
- Required: Overlay/screen widgets use targeted `Consumer`/`Selector` rebuild scoping (Riverpod `select`), not rebuilding large subtrees on every tick — source: ADR-0001 (general Flutter performance rule, cross-cutting)
- Required: Use the safe nullable `AsyncValue` accessor `.value` (riverpod 3.x), never `.valueOrNull` — source: ADR-0002/0003/0008/0009
- Forbidden: This screen must NEVER call `GameEventBus` directly from a repository — it already isn't (`ParentApprovalRepository` has no bus reference, confirmed in Parent Approval epic's code review). This story's `ConsumerWidget` is the correct, sanctioned emission point.

**Performance Budget**: Tab loads pending list in <500ms; skeleton/shimmer (P5) shown if load exceeds 200ms (UX spec `design/ux/parent-dashboard-ui.md` Acceptance Criteria).

---

## Acceptance Criteria

*From GDD `design/gdd/parent-dashboard-ui.md` Core Rules 1, 2, 5 and Edge Cases 1, 9, plus `design/ux/parent-dashboard-ui.md`'s Events Fired and States & Variants sections:*

- [ ] **Screen structure**: GIVEN bố mẹ đã xác thực, WHEN họ ở `/parent/dashboard`, THEN nội dung hiển thị đúng Tab Nhiệm vụ (pending list + FAB) — tab chrome (icon/label/switching) không thuộc story này (Main Navigation Shell #17).
- [ ] **Pending list rendering**: GIVEN `pendingTasksProvider` trả về N pending tasks (test N=1 và N=15+), WHEN Tab Nhiệm vụ mở, THEN đúng N card hiển thị, không pagination/cap, mỗi card có avatar+tên bé, category icon+label, task title, "submitted X phút/giờ trước", 2 nút Approve/Reject.
- [ ] **Multi-child correctness**: GIVEN family có ≥2 bé, WHEN 2 bé cùng có pending task, THEN mỗi card hiển thị avatar+tên đúng bé tương ứng — không nhầm bé.
- [ ] **Offline pre-check wiring**: GIVEN thiết bị offline, WHEN tap Approve, THEN `connectivity_plus` pre-check chặn trước khi gọi `approveTask()` — hành vi nút cụ thể (disable/re-enable/error text) là AC của Parent Approval (#11)/ADR-0013, story này chỉ verify wiring đúng.
- [ ] **"Chọn bé" always visible**: GIVEN bố mẹ ở Tab Nhiệm vụ, THEN app bar hiển thị action "Chọn bé"; WHEN tap, THEN navigate đúng `/select-child` (không redefine hành vi ở đây — Main Navigation Shell #17 Rule 7).
- [ ] **Empty state**: GIVEN 0 pending task, THEN empty state "Chưa có nhiệm vụ nào chờ duyệt" hiển thị, FAB "+" vẫn tap được.
- [ ] **Tab switch during in-flight transaction**: GIVEN Approve/Reject transaction đang chạy, WHEN chuyển tab đi rồi quay lại Tab Nhiệm vụ sau khi transaction hoàn tất, THEN `pendingTasksProvider` phản ánh đúng kết quả — transaction không bị cancel bởi navigation.
- [ ] **Event emission on Approve**: GIVEN `approveTask()` trả về non-null `ApproveResult`, WHEN kết quả nhận được, THEN `GameEvent(taskApproved)` emit đúng 1 lần LUÔN; `GameEvent(petLeveledUp, result.newPetLevel)` emit đúng 1 lần CHỈ KHI `result.leveledUp == true`.
- [ ] **No event emission on Reject**: GIVEN `rejectTask()` hoàn tất, THEN không `GameEvent` nào được emit (GDD Core Rule 3 — wither animation là UI-local, thuộc Task Management UI #19, không phải trách nhiệm của story này).
- [ ] **List load error state**: GIVEN `pendingTasksProvider` throw, THEN inline error "Không tải được danh sách — thử lại" + nút Thử lại hiển thị, KHÔNG crash toàn màn hình (UX spec States & Variants — gap the GDD didn't cover, added during `/ux-design`).

---

## Implementation Notes

*Derived from `design/ux/parent-dashboard-ui.md` (Layout Zones, Component Inventory, Interaction Map, Events Fired) and GDD Core Rules 1/2/5:*

1. Render inside Main Navigation Shell (#17)'s already-existing `/parent/dashboard` route slot — this story creates NO new routes, only content.
2. Data source: `pendingTasksProvider` (Task Library #8, already built and Complete) — a `StreamProvider`, uncapped.
3. App bar: title "Nhiệm vụ" + "Chọn bé" action calling the existing navigation to `/select-child` — do not reimplement that navigation's internals.
4. **Banner slot**: the UX spec reserves a zone directly below the app bar for the FCM/reminder banner (shared slot, P7) — this story builds the layout with that slot present but EMPTY (a placeholder `SizedBox.shrink()` or equivalent) since actual banner rendering/logic is Story 004's scope (currently Blocked on a missing ADR). Do not implement banner behavior here.
5. Pending task card: avatar+name, category icon+label, title, relative-time text (display only), 2 buttons.
6. Approve/Reject buttons: use **P1** (single-flight guard — screen-scoped Riverpod in-flight state per card, not local `State`, so it survives rebuilds) + **P8** (✓/✕ icon, never color-alone). Disable immediately on tap; re-enable on completion or failure per Parent Approval's own unified error handling (ADR-0013 §5) — this story does not reinvent that error UX, just wires to it.
7. **Approve tap handler** (the critical piece): `await approveTaskRepo.approveTask(...)`; if the result is non-null, emit `GameEvent(taskApproved)` unconditionally, then `GameEvent(petLeveledUp, result.newPetLevel)` only if `result.leveledUp`. This is the sanctioned adapter (a) usage ADR-0004 §3 and ADR-0013 §2 both anticipate — emission happens directly in this `ConsumerWidget`'s tap-handler continuation, not inside the repository.
8. **Reject tap handler**: call `rejectTask(...)`, do not emit anything.
9. Offline pre-check: `connectivity_plus` disables Approve/Reject preemptively when offline, per GDD Core Rule 2 — this is a UX optimization layered on top of Parent Approval's own unified error handling, not a replacement for it.
10. Loading: skeleton/shimmer (**P5**) while `pendingTasksProvider` is `AsyncLoading`. Error: inline retry per the new Acceptance Criteria above (`AsyncValue.value` safe accessor, not `.valueOrNull`).
11. **GameEventBus replay risk**: do not attempt to fix it here (out of this story's scope — it requires an ADR-0004 revision). In Completion Notes, explicitly state the risk is now live (this story is the first real emitter) and confirm it is being carried forward as documented tech debt, matching Parent Approval epic's own framing — do not silently ship without this acknowledgment.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 002 (this epic)**: create-custom-task bottom sheet, FAB tap target's sheet content (FAB itself renders in this story, but tapping it opens Story 002's sheet — if Story 002 isn't done yet, FAB can open a stub/TODO sheet, or this story can be sequenced after Story 002).
- **Story 003 (this epic)**: Gia đình tab content.
- **Story 004 (this epic, Blocked)**: actual FCM banner rendering and defer/coalesce logic — this story only reserves the layout slot.
- **Main Navigation Shell (#17)**: tab chrome, `/select-child` screen itself, route definitions.
- **Task Management UI (#19)**: reject's "wither" animation (renders on the child's device, not here).
- **GameEventBus replay risk mitigation**: requires an ADR-0004 revision, a cross-cutting change out of this story's scope.

---

## QA Test Cases

*Transcribed from GDD's own Acceptance Criteria (Given/When/Then) and the UX spec's Events Fired section — QL-STORY-READY gate skipped (Solo mode).*

- **AC-1 (Pending list rendering)**
  - Given: `pendingTasksProvider` returns N tasks (N=1, N=15)
  - When: tab opens
  - Then: exactly N cards render, each with avatar+name, category, title, relative time, 2 buttons
  - Edge cases: N=0 → empty state instead

- **AC-2 (Multi-child correctness)**
  - Given: 2 children each with a pending task
  - When: both cards render
  - Then: each card's avatar+name matches its own task's child, no cross-contamination

- **AC-3 (Event emission — normal approve)**
  - Given: `approveTask()` resolves with `ApproveResult(leveledUp: false, newPetLevel: null)`
  - When: result received
  - Then: exactly 1 `taskApproved` event emitted, 0 `petLeveledUp` events
  - Edge cases: `approveTask()` returns `null` (idempotent no-op) → 0 events emitted at all

- **AC-4 (Event emission — level-up)**
  - Given: `approveTask()` resolves with `ApproveResult(leveledUp: true, newPetLevel: 3)`
  - When: result received
  - Then: 1 `taskApproved` + 1 `petLeveledUp(3)` emitted, in that order

- **AC-5 (Reject — no emission)**
  - Given: `rejectTask()` completes
  - When: completion observed
  - Then: 0 `GameEvent`s of any kind emitted

- **AC-6 (Tab switch during in-flight transaction)**
  - Given: Approve tap in progress (transaction not yet resolved)
  - When: user switches to Gia đình tab and back before resolution
  - Then: transaction completes normally, list reflects the result on return — no cancellation, no duplicate credit

- **AC-7 (List load error)**
  - Given: `pendingTasksProvider` throws
  - When: tab renders
  - Then: inline error + retry button shown, no full-screen crash

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/parent-dashboard-ui/pending_list_approve_reject_test.dart` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Main Navigation Shell (#17) epic — no epic exists yet, must be created and at least minimally implemented first** (found during `/dev-story`, 2026-07-18 — see Blocked note above). Also needs Task Library (#8) fixes: `familyPendingTasksProvider` (or equivalent) and `TaskModel.id`/`childId` fields.
- Unlocks: Closes Parent Approval epic's Definition of Done items 5–6 (background→foreground replay verification, GameEventBus replay-risk acknowledgment) once this story's Completion Notes address them.
