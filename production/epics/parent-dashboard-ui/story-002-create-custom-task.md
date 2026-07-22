# Story 002: Create Custom Task Bottom Sheet

> **Epic**: Parent Dashboard UI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-22

## Context

**GDD**: `design/gdd/parent-dashboard-ui.md`
**Requirement**: `TR-parentdash-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: N/A — pure UI/write wiring to Task Library (#8)'s already-propagated `customTasks` collection. No architectural pattern beyond existing Firestore write conventions is required.
**ADR Decision Summary**: N/A.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 — pure Flutter widget layer, no Flame | **Risk**: LOW
**Engine Notes**: None — standard Firestore document write, no post-cutoff API surface.

**Control Manifest Rules (this layer)**:
- Required: Never build Firestore paths as inline strings — use `FirestorePaths` constants (source: ADR-0003/0006/0008/0009/0011)
- Required: `customTasks/{id}` write is a `set()` (predictable-ID or auto-ID, matches Task Library's own established convention) — `{title, categoryId, targetChildId, createdAt}`, no `status` field
- Required: single-flight guard (**P1**) on Save, same as Approve/Reject

**Performance Budget**: No dedicated latency contract — this is a simple document write, no formula computation. No performance impact expected beyond standard Firestore write latency.

---

## Acceptance Criteria

*From GDD Core Rule 3 and Edge Cases 2, 3; includes the GDD's own explicitly-tagged BLOCKING criterion (carried into `design/ux/parent-dashboard-ui.md`'s Acceptance Criteria during `/ux-review`):*

- [x] **Conditional child selector — 1 child**: GIVEN family có đúng 1 bé, WHEN bottom sheet tạo task mở, THEN child selector KHÔNG hiển thị (**P18** — Conditional selector pattern).
- [x] **Conditional child selector — ≥2 children**: GIVEN family có ≥2 bé, WHEN bottom sheet mở, THEN child selector hiển thị đầy đủ tất cả bé trong gia đình.
- [x] **Category dropdown**: GIVEN dropdown mở, THEN đúng 5 giá trị hiển thị (`study`/`arts`/`chores`/`sport`/`helping`); tag `custom` KHÔNG xuất hiện như option chọn được.
- [x] **Empty title validation**: GIVEN title trống hoặc chỉ whitespace, THEN nút Save disabled (Edge Case 2); GIVEN ≥1 ký tự non-whitespace, THEN Save enabled.
- [x] **Save writes correct document**: GIVEN title, category, child đã chọn hợp lệ, WHEN tap Save, THEN document mới tạo tại `families/{parentId}/customTasks/{customTaskId}` với đúng 4 field `{title, categoryId, targetChildId, createdAt}`, KHÔNG có field `status`; sheet đóng; snackbar "Đã thêm nhiệm vụ" hiển thị.
- [x] **BLOCKING — `targetChildId` read-back verification** (GDD Core Rule 3's own tagged requirement, carried into UX spec at `/ux-review`): GIVEN gia đình có đúng 1 bé, WHEN Save được gọi, THEN `targetChildId` trong document vừa ghi khớp đúng ID của bé đó — verify bằng cách **đọc lại document sau khi ghi** (không chỉ quan sát UI). Sai ID silently corrupt data mà không có triệu chứng UI nào quan sát được — cần automated integration test, không phải chỉ manual walkthrough.
- [x] **Duplicate title allowed**: GIVEN 2 custom task templates cùng title được tạo, THEN cả 2 đều tồn tại trong `customTasks`, không lỗi dedup (Edge Case 3).
- [x] **Save error state**: GIVEN write thất bại, THEN inline error "Không thêm được nhiệm vụ — thử lại" hiển thị, sheet KHÔNG tự đóng, Save re-enable (UX spec States & Variants — gap the GDD didn't cover, added during `/ux-design`).

---

## Implementation Notes

*Derived from GDD Core Rule 3 and `design/ux/parent-dashboard-ui.md`'s Component Inventory/Interaction Map:*

1. Sheet uses **P3** (Inline bottom sheet — slide-up 250ms ease-out, scrim dim 40%, reused verbatim from Main Navigation Shell #17's motion spec, not redefined here).
2. Child selector: implement **P18** (Conditional selector, newly added to `design/ux/interaction-patterns.md` during this epic's UX pass) — compute `childProfiles.length` first; if `== 1`, hide the selector entirely and auto-assign that single child's ID at Save time; if `> 1`, render the full selector with no default pre-selection.
3. Category dropdown: exactly 5 real category values, sourced from Task Library (#8)'s already-registered constants — do not hardcode a duplicate list; the `custom` tag is Task Library's fallback-only tag and must never appear as a selectable option here.
4. Save button: single-flight guard (**P1**) — disable on tap, re-enable on completion/failure.
5. Write target: `FirestorePaths.customTasks(parentId)` (or equivalent constant — confirm exact name against `firestore_paths.dart`) with `{title, categoryId, targetChildId, createdAt: FieldValue.serverTimestamp()}` — exactly these 4 fields, no `status`.
6. **The BLOCKING read-back test** is the highest-priority test in this story — write it first. A wrong `targetChildId` corrupts data with zero UI symptom (the sheet closes, the snackbar shows, everything LOOKS fine) — only a read-back assertion catches it.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 001 (this epic)**: the FAB that opens this sheet, and the pending list this sheet's created tasks eventually feed into (indirectly, via Task Management UI).
- **Task Management UI (#19)**: the picker that displays `customTasks` as an option — already built and confirmed against this exact assumption (task-management-ui.md Core Rule 5).

---

## QA Test Cases

*Transcribed from GDD's own Acceptance Criteria — QL-STORY-READY gate skipped (Solo mode).*

- **AC-1 (Conditional selector)**
  - Given: family with exactly 1 child vs. family with 2+ children
  - When: sheet opens
  - Then: selector hidden (1 child) or shown with all children (2+)
  - Edge cases: family with exactly 4 children (Auth #1's max cap) — selector still renders correctly

- **AC-2 (targetChildId read-back — BLOCKING)**
  - Given: family with exactly 1 child, child ID known ahead of time
  - When: Save called with valid title/category
  - Then: read the just-written document back from Firestore, assert `targetChildId` field equals the known child ID exactly
  - Edge cases: none — this is a single deterministic assertion, but it must be a real read, not a mocked assumption

- **AC-3 (Empty title validation)**
  - Given: title field empty or whitespace-only
  - When: checking Save button state
  - Then: disabled; given ≥1 non-whitespace char, enabled
  - Edge cases: title with only whitespace characters (spaces, tabs) must also disable Save

- **AC-4 (Save writes exactly 4 fields)**
  - Given: valid form state
  - When: Save tapped
  - Then: written document has exactly `title`, `categoryId`, `targetChildId`, `createdAt` — no `status` field present at all

- **AC-5 (Duplicate title)**
  - Given: 2 Save calls with identical title
  - When: both complete
  - Then: 2 separate documents exist, no error, no merge

- **AC-6 (Save error)**
  - Given: mocked write failure
  - When: Save tapped
  - Then: inline error shown, sheet stays open, Save button re-enabled

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/parent-dashboard-ui/create_custom_task_test.dart` — must exist and pass, MUST include the BLOCKING read-back test (AC-2)

**Status**: [x] Created — 13/13 tests passing (`create_custom_task_test.dart`), including the mutation-tested BLOCKING read-back test

---

## Dependencies

- Depends on: None (Task Library epic Complete, `customTasks` collection already propagated).
- Unlocks: None further within this epic.

---

## Completion Notes
**Completed**: 2026-07-22
**Criteria**: 8/8 passing (all auto-verified via tests; no manual/deferred criteria)
**Deviations**:
- ADVISORY: `task_providers.dart`'s `customTaskRepositoryProvider` addition — necessary Riverpod wiring, matches sibling provider convention exactly, not explicitly listed in the story's scope bullets.
- ADVISORY (documented, not a defect): `parent_dashboard_tasks_tab.dart` gained a provisional FAB trigger since Story 001 (owns the real FAB) is separately Blocked on unrelated Task Library gaps — same "placeholder for a blocked neighbor" pattern established in the Main Navigation Shell epic.
- ADVISORY: invented a local Vietnamese category-label table (no existing table found codebase-wide); 2/5 labels turned out to have partial precedent in the UX doc's wireframe, corrected in the doc comment during review. Flagged for localization-lead confirmation.
**Test Evidence**: Integration — `tests/integration/parent-dashboard-ui/create_custom_task_test.dart` (13/13 passing, 5 beyond the story's own 8 stated ACs — the BLOCKING test was mutation-tested during code review to confirm it genuinely catches the fault it claims to)
**Code Review**: Complete — `/code-review`, flame-specialist + qa-tester, verdict APPROVED WITH SUGGESTIONS, all findings applied and re-verified same session (433/433 full suite, `flutter analyze` clean)
