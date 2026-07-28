# Story 010: Login Screen UI

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: 3h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: covers the UI portion of `TR-auth-account-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture (backend contract only — this story's UI layer is governed by the not-yet-written UX spec, not the ADR)

**Control Manifest Rules (this layer)**: none UI-specific yet — will come from the UX spec once written; the underlying auth calls this screen triggers are already governed by Story 001's manifest rules.

---

## Acceptance Criteria

*From `design/ux/login-screen.md`'s Acceptance Criteria section (supersedes the GDD-only draft list):*

- [x] Bố mẹ nhập email + password hợp lệ, tap "Đăng nhập" → navigate đến Child Profile Selection screen trong <3 giây.
- [x] Bố mẹ nhập sai password, tap "Đăng nhập" → hiển thị "Sai email hoặc mật khẩu" — không lộ thông tin email có tồn tại hay không.
- [x] Mất kết nối mạng khi tap "Đăng nhập" → hiển thị thông báo lỗi mạng riêng biệt, không nhầm với sai mật khẩu.
- [x] Double-tap nhanh vào "Đăng nhập" chỉ kích hoạt 1 lần gọi Firebase Auth (P1 single-flight guard) — không double-submit.
- [x] Mọi element tương tác (2 field, CTA, link, icon con mắt) đạt tối thiểu 48×48dp tap target.
- [x] Error message dùng icon ⚠️ kèm text, không dựa màu đỏ (WCAG 1.4.1).

---

## Implementation Notes

*From `design/ux/login-screen.md`:*

- Layout: centered vertical stack (logo → email field → password field → error zone → CTA → "Quên mật khẩu" link). Full component inventory + ASCII wireframe in the spec.
- Wire to Story 001's `AuthRepository.signIn()` via `authRepositoryProvider` — catch `AuthSignInFailure`, display its generic message in the error zone (spec's "Error — sai thông tin" state).
- Distinguish network errors from auth errors — separate error copy (spec's "Error — mất mạng" state); `AuthSignInFailure` vs. other thrown exceptions.
- Apply P1 (single-flight guard): disable CTA + both fields on submit, re-enable on resolve/error.
- Apply P8 (icon+color feedback): error zone uses ⚠️ icon, Primary text color — never red.
- No navigate() call needed on success — Story 003's route guard reacts to `sessionStateProvider` becoming `parentAuthed` automatically.
- Transitions: 200ms fade in/out (screen enter/exit), 150ms fade for error zone appear/disappear. Reduced-motion: near-instant cross-fade.
- "Quên mật khẩu" link is present but its destination is out of scope (spec's Open Questions) — wire it to a no-op or a placeholder route for this story; do not build the forgot-password flow itself.

---

## Out of Scope

- Story 001: the actual Firebase Auth sign-in logic (this story only calls it)
- Story 003: the redirect mechanism itself

---

## QA Test Cases

*UI story — manual verification against the UX spec's States & Variants:*

```
Manual check: Login success
  Setup: valid parent account, app at Login Screen
  Verify: enter valid email+password, tap "Đăng nhập"
  Pass condition: navigates to Child Profile Selection within 3s

Manual check: Wrong password
  Setup: valid email, wrong password
  Verify: tap "Đăng nhập" — error zone shows "Sai email hoặc mật khẩu" with ⚠️ icon
  Pass condition: no navigation occurs, password field clears, email field retains value

Manual check: Single-flight guard
  Setup: app at Login Screen, valid credentials entered
  Verify: rapidly double-tap "Đăng nhập"
  Pass condition: only one sign-in call fires (check network/logs), CTA visibly disabled after first tap
```

---

## Test Evidence

**Story Type**: UI
**Required evidence**: automated widget test (substitutes for the manual walkthrough — ADVISORY gate level per `coding-standards.md`)

**Status**: [x] `tests/integration/auth_account/login_screen_test.dart` — 13 tests, all passing

---

## Dependencies

- Depends on: Story 001 (Complete), Story 003 (Complete), `design/ux/login-screen.md` (Complete)
- Unlocks: None

---

## Completion Notes
**Completed**: 2026-07-16
**Criteria**: 6/6 passing
**Deviations**:
- ADVISORY: `AuthRepository.signIn()` (Story 001) extended with a new `AuthNetworkFailure` exception, distinguishing `network-request-failed` from other `FirebaseAuthException`s — required by the UX spec's distinct "no connection" error state, verified as a category distinction (transport failure vs. credential rejection) that does not reintroduce the per-credential-error-code branching ADR-0002 forbids. Closed ADR-0002's long-open "re-verify invalid-credential consolidation on ^6.5.6" action item as part of this verification.
- ADVISORY: new shared `lib/ui/app_colors.dart` (Art Bible §4 constants) and a shared `fadeTransitionPage` helper in `router_provider.dart` (200ms fade, reduced-motion aware) — both introduced here as the first UI story, intended for direct reuse by Story 011/012 rather than re-implementing per screen.
**Test Evidence**: UI (ADVISORY) — `tests/integration/auth_account/login_screen_test.dart`, 13 tests, all passing; full suite 86/86 (+1 skipped)
**Code Review**: Complete — `/code-review` run this session, using `flame-widget-specialist` (Flutter UI/overlay routing per technical-preferences.md) + qa-tester in parallel. flame-widget-specialist: ISSUES FOUND — layout/P1/P8/accessibility/color-constants all verified correct, but found a real `mounted`-check asymmetry (setState/controller access after potential dispose), a silent gap against the UX spec's Transitions & Animations section, and a password-cleared-on-network-failure inconsistency. qa-tester: GAPS — found AC1/AC5/AC6 had no or only partial test coverage, and a genuine implementation gap (the UX spec's inline email-format validation was never built). All findings fixed: added the missing `mounted` guard (which a newly-added dispose-while-pending test then caught as a real remaining bug on first attempt — fixed and reverified), implemented email-format hint + error-clear-on-retype + shared fade transitions, stopped clearing the password field on network failure, added a catch-all for non-`FirebaseAuthException` errors, and added 8 new tests (success path, unexpected-error fallback, retype-clears-error, email-hint, disposed-while-pending, forgot-password no-op, tap-target sizes, strengthened double-tap). Verdict: APPROVED (post-fix).
