# Story 004: Parent Override — Switch To/From Parent Mode

> **Epic**: Main Navigation Shell
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 3.5h
> **Manifest Version**: 2026-07-16
> **Last Updated**: —

## Context

**GDD**: `design/gdd/main-navigation-shell.md`
**Requirement**: `TR-navshell-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: Navigation Shell & Route Guard Architecture (Accepted), Decision §5 (and §6 for the override-exit-via-back-press half)
**ADR Decision Summary**: Long-press ≥600ms on the Profile chip opens a switch-mode bottom sheet; on password confirm, `parentOverrideProvider.notifier.state = true` then `context.go('/parent/dashboard')` — the root redirect (Story 001) picks up the resulting `parentView` transition automatically via the `ref.listen` bridge, no manual navigation-plus-guard duplication. Override-exit (via "Xong"/"Quay lại" or back-press while in override) is the same in reverse, landing directly on `/child/pet-room` with no re-PIN since the child branch was never disposed (Story 002's preservation guarantee).

**Engine**: Flutter 3.44.4 / `go_router 17.3.0` / Riverpod `3.3.2` | **Risk**: MEDIUM (relies on Story 001's redirect bridge and Story 002's branch-preservation both being correct — this story is where their correctness becomes user-observable together for the first time)
**Engine Notes**: `parentOverrideProvider` is owned by `auth-account` (ADR-0002) — this story writes to it (that write access is already granted per the registry) but never redefines its shape.

**Control Manifest Rules (this layer)**:
- Required: long-press duration `long_press_duration` tuning knob, default 600ms (GDD Tuning Knobs, range 400-1000ms)
- Required: `PopScope.onPopInvokedWithResult` (never `WillPopScope`, registered forbidden pattern) for the override-exit-via-back-press case
- Required: `switch_mode_confirm_timeout = 0` — no auto-dismiss on the confirm sheet (GDD Tuning Knob, a parent is never rushed through re-entering their password)

**Performance Budget**: Switch-mode bottom sheet slide-up 250ms ease-out, overlay dim 40% (GDD Visual/Audio Requirements) — no numeric latency budget for the override transition itself beyond standard navigation timing.

---

## Acceptance Criteria

*From GDD Acceptance Criteria AC-8, 9, 13, 14:*

- [ ] **AC-8**: GIVEN bé long-press avatar ≥600ms trên Profile chip, THEN bottom sheet "Chuyển sang tài khoản bố/mẹ?" hiện ra.
- [ ] **AC-9**: GIVEN bố mẹ nhập đúng password trong switch mode flow, THEN `parentOverrideProvider = true`, navigate về `/parent/dashboard`, Parent bottom nav (2 tabs) hiển thị, VÀ child session không bị logout (verify `activeChildProvider` vẫn giữ giá trị cũ).
- [ ] **AC-13**: GIVEN `sessionState == parentView` (bố mẹ đang override), WHEN bố mẹ back-press trên `/parent/dashboard`, THEN quay về `/child/pet-room` (`parentOverrideProvider = false`) — KHÔNG exit app, KHÔNG hiện dialog "Thoát PetQuest?" kid-styled.
- [ ] **AC-14**: GIVEN bố mẹ ở `/parent/dashboard` sau khi override, WHEN tap "Xong"/"Quay lại", THEN quay thẳng về `/child/pet-room` KHÔNG qua `/select-child`, bé KHÔNG cần nhập lại PIN — session vẫn nguyên.
- [ ] **Wrong password**: GIVEN bố mẹ nhập sai password trong switch mode flow, THEN inline error "Mật khẩu không đúng" hiển thị; sheet KHÔNG đóng, KHÔNG navigate, KHÔNG logout (GDD Edge Case).
- [ ] **Sub-screen discard warning**: GIVEN long-press trigger khi bé đang ở sub-screen (ví dụ `/child/tasks/new`), THEN bottom sheet vẫn hiện, kèm cảnh báo "Dữ liệu chưa lưu sẽ bị mất" (GDD Edge Case).

---

## Implementation Notes

*Derived from ADR-0014 Decision §5 and §6:*

1. Profile chip's long-press gesture itself is Story 006's widget (Floating Chip Cluster) — this story owns the *interaction logic* the long-press triggers (bottom sheet, password flow, provider writes), per GDD Rule 6's explicit ownership split ("Profile chip's long-press-to-parent-override interaction logic" stays with this GDD/epic even though the chip's rendering is HUD-spec-owned/Story 006).
2. Switch-mode bottom sheet: **P3** (Inline bottom sheet) for the mechanic; the password-confirm flow content is this story's own.
3. On confirmed correct password: `ref.read(parentOverrideProvider.notifier).state = true` then `context.go(AppRoutes.parentDashboard)` — **do not** manually navigate AND separately re-check the guard; Story 001's `ref.listen` bridge already re-runs the redirect automatically once the provider write lands. Duplicating the guard check here would be redundant and a maintenance hazard.
4. On wrong password: inline error text "Mật khẩu không đúng", sheet stays open, no provider write, no navigation.
5. Override-exit via back-press: `PopScope(canPop: false, onPopInvokedWithResult: (didPop, result) { if (didPop) return; ref.read(parentOverrideProvider.notifier).state = false; context.go(AppRoutes.childPetRoom); })` — exact pattern from ADR-0014 Decision §6's third code sample. This is a DIFFERENT `PopScope` configuration from Story 005's Child-tab-root exit dialog and from the plain Parent-tab-root-not-in-override case (`canPop: true`, no dialog) — three distinct back-button behaviors this epic implements across Stories 004/005, do not conflate them.
6. "Xong"/"Quay lại" button (owned by Parent Dashboard UI per cross-spec agreement, but its *trigger logic* is this story's — the button itself doesn't exist until Parent Dashboard UI's epic builds it, so this story should expose the override-exit logic as a callable function/provider action Parent Dashboard UI's future button will call, not a rendered button this story owns).
7. Verify AC-9's "child session not logged out" by asserting `activeChildProvider`'s value is byte-for-byte unchanged before/after the override transition — not just "the child screen still shows the right name," which could pass even if the underlying provider were subtly re-fetched.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 002**: Pet Room's Flame-state-preservation itself (this story depends on it working correctly, per AC-14's "session vẫn nguyên," but doesn't re-implement it).
- **Story 003**: Parent Shell's own branch structure (this story navigates INTO it).
- **Story 006**: Profile chip's visual rendering and the long-press gesture DETECTION itself (this story owns what happens AFTER the gesture fires).
- **Parent Dashboard UI (#21), Blocked pending this epic**: the actual "Xong"/"Quay lại" button widget — this story only exposes the callable action it will invoke.
- Parent password lockout/rate-limiting — explicitly flagged as an open question in the GDD/UX spec, not resolved by this story (no lockout policy exists for repeated wrong-password attempts here, unlike the child PIN's 3-strikes/60s).

---

## QA Test Cases

*Transcribed from GDD's own Acceptance Criteria — QL-STORY-READY gate skipped (Solo mode).*

- **AC-8**
  - Given: on Child Shell, Profile chip visible
  - When: long-press ≥600ms
  - Then: bottom sheet appears with "Chuyển sang tài khoản bố/mẹ?"
  - Edge cases: press held <600ms — sheet does NOT appear (verify the threshold, not just "long press works")

- **AC-9**
  - Given: switch-mode sheet open, correct password entered
  - When: confirm tapped
  - Then: `parentOverrideProvider == true`, route is `/parent/dashboard`, `activeChildProvider`'s value identical to its pre-override value (same child ID, same object equality if applicable)

- **AC-13**
  - Given: `sessionState == parentView`, on `/parent/dashboard`
  - When: back-press
  - Then: route is `/child/pet-room`, `parentOverrideProvider == false`, no exit dialog shown, app does not exit

- **AC-14**
  - Given: `sessionState == parentView`, on `/parent/dashboard`
  - When: override-exit action invoked (simulating the future "Xong" button tap)
  - Then: route is `/child/pet-room` directly (no intermediate `/select-child` or PIN entry route observed), no re-PIN prompt

- **Wrong password**
  - Given: switch-mode sheet open, wrong password entered
  - When: confirm tapped
  - Then: inline error shown, sheet still open, `parentOverrideProvider` unchanged, no navigation

- **Sub-screen discard warning**
  - Given: on `/child/tasks/new`
  - When: long-press Profile chip
  - Then: sheet appears with the discard warning text, distinct from the normal sheet copy

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/main-navigation-shell/parent_override_test.dart` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (Root Redirect), Story 002 (Child Shell — for the return-trip preservation guarantee), Story 003 (Parent Shell — the transition's destination) must all be Complete.
- Unlocks: None further within this epic.
