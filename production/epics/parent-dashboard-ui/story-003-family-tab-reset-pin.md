# Story 003: Gia đình Tab — Child List & Reset PIN Dialog

> **Epic**: Parent Dashboard UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: 2.5h
> **Manifest Version**: 2026-07-16
> **Last Updated**: —

## Context

**GDD**: `design/gdd/parent-dashboard-ui.md`
**Requirement**: `TR-parentdash-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: N/A — pure UI wiring to Auth & Account (#1)'s already-defined `resetChildPin(childId, newPin)` mechanism (Auth #1 Core Rule 6).
**ADR Decision Summary**: N/A.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 — pure Flutter widget layer, no Flame | **Risk**: LOW
**Engine Notes**: None.

**Control Manifest Rules (this layer)**:
- Required: single-flight guard (**P1**) on the Xác nhận button, same convention as Approve/Reject/Save.
- Required: no pure red/black in primary UI — Reset PIN's confirm action uses Lavender Soft accent, not red, despite being a "sensitive" action (source: Art Bible §4, reaffirmed accessibility-requirements.md item 7).

**Performance Budget**: No dedicated latency contract — simple list render + a single credential-sub-document write. No performance impact expected.

---

## Acceptance Criteria

*From GDD Core Rules 1 (Gia đình tab portion), 4, 5 (reused) and Edge Cases 6, 7:*

- [ ] **Screen structure — Gia đình tab**: GIVEN bố mẹ ở `/parent/family`, THEN nội dung hiển thị đúng child profile list — không lẫn nội dung Tab Nhiệm vụ.
- [ ] **Child list rendering**: GIVEN family có N bé (1 ≤ N ≤ 4), WHEN Gia đình tab mở, THEN đúng N row hiển thị với avatar+tên.
- [ ] **Reset PIN dialog open**: GIVEN tap "Reset PIN" trên row của bé X, THEN dialog hiện đúng title "Đặt lại PIN cho [tên X]" kèm 1 PIN input field 4 số (**P10** — reused PIN-entry UI, this time for entering a new PIN, not verifying one).
- [ ] **Xác nhận disabled until complete**: GIVEN PIN input chưa đủ 4 số, THEN nút Xác nhận disabled.
- [ ] **Correct childId/newPin passed**: GIVEN đã nhập đủ 4 số, WHEN tap Xác nhận, THEN `resetChildPin(childId, newPin)` được gọi với đúng `childId` của bé X (không phải bé khác trong list) và `newPin` đúng giá trị đã nhập.
- [ ] **Cancel — no side effect**: GIVEN confirm dialog mở, WHEN tap Cancel/Hủy, THEN dialog đóng, KHÔNG gọi `resetChildPin()`, PIN không đổi (Edge Case 6).
- [ ] **Active session not kicked**: GIVEN bé X đang có active session đang chơi, WHEN bố mẹ reset PIN của bé X, THEN session hiện tại KHÔNG bị kick — PIN mới chỉ áp dụng ở lần login tiếp theo (Edge Case 7 — this is Auth #1's own guarantee; this story only verifies it isn't broken by the UI trigger).
- [ ] **"Chọn bé" reused**: GIVEN bố mẹ ở Gia đình tab, THEN app bar hiển thị action "Chọn bé" giống Tab Nhiệm vụ (Core Rule 5, same implementation as Story 001 — do not reimplement).
- [ ] **Reset PIN error state**: GIVEN `resetChildPin()` throw, THEN inline error "Đặt lại PIN thất bại — thử lại" hiển thị, dialog KHÔNG tự đóng, Xác nhận re-enable (UX spec States & Variants — gap the GDD didn't cover, added during `/ux-design`).
- [ ] **Defensive empty state** *(added during `/ux-review`, not a GDD-designed case)*: GIVEN 0 child profile (GDD assumes 1 ≤ N ≤ 4 and does not design for 0, but no `createChildProfile()` write path currently exists in the codebase — a separately-flagged gap), THEN show "Chưa có hồ sơ con nào" rather than a silent blank list or a crash.

---

## Implementation Notes

*Derived from `design/ux/parent-dashboard-ui.md`'s Component Inventory/Interaction Map and GDD Core Rule 4:*

1. Render inside Main Navigation Shell (#17)'s already-existing `/parent/family` route slot — no new routes.
2. Child list: read from the same child-profile source already used elsewhere (Auth #1's `childProfilesProvider` or equivalent) — do not create a second read path.
3. Reset PIN dialog: standard Material 3 `AlertDialog`, no custom art (per GDD Visual Requirements item 5) — the PIN-entry field itself reuses **P10**'s numpad/dot-display convention, but this dialog is entering a NEW PIN, not verifying an existing one, so there's no lockout logic here (lockout is P10's child-auth-verification behavior, not applicable to this admin-side entry).
4. Xác nhận button: single-flight guard (**P1**), calls `resetChildPin(childId, newPin)` — `childId` must come from the specific row that opened the dialog, not any ambient/global state, to avoid the "wrong child" bug class this criterion explicitly guards against.
5. "Chọn bé" app bar action: identical implementation to Story 001's — if Story 001 is done first, this is literally the same widget/action reused, not reimplemented.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 001 (this epic)**: Tab Nhiệm vụ content, "Chọn bé" action's first implementation (this story reuses it).
- **Auth & Account (#1)**: `resetChildPin()`'s own mechanism, credential storage, PIN hashing — already built and Complete.
- **Add/remove child profile**: explicitly out of scope per GDD Core Rule 4 — that's Auth & Account's onboarding flow (currently a separately-flagged gap — no `createChildProfile()` exists yet — not this story's job to build).

---

## QA Test Cases

*Transcribed from GDD's own Acceptance Criteria — QL-STORY-READY gate skipped (Solo mode).*

- **AC-1 (Child list rendering)**
  - Given: family with N children (N=1, N=4)
  - When: tab opens
  - Then: exactly N rows with avatar+name

- **AC-2 (Reset PIN dialog — correct child)**
  - Given: 2+ children in the list
  - When: "Reset PIN" tapped on a specific row (not the first)
  - Then: dialog title shows that exact child's name, and on confirm, `resetChildPin()` receives that exact child's ID — not the first child's or any other

- **AC-3 (Xác nhận gating)**
  - Given: PIN input with 0-3 digits entered
  - When: checking button state
  - Then: disabled; at 4 digits, enabled

- **AC-4 (Cancel — no side effect)**
  - Given: dialog open, some digits entered
  - When: Cancel tapped
  - Then: dialog closes, `resetChildPin()` never called, no state mutation

- **AC-5 (Reset PIN error)**
  - Given: mocked `resetChildPin()` failure
  - When: Xác nhận tapped
  - Then: inline error shown, dialog stays open, button re-enabled

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- `production/qa/evidence/reset-pin-dialog-evidence.md` — manual walkthrough OR interaction test at `tests/integration/parent-dashboard-ui/family_tab_reset_pin_test.dart`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Auth & Account epic Complete).
- Unlocks: None further within this epic.
