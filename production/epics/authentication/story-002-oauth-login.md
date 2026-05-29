# Story 002: OAuth Login (Google + Sign in with Apple)

> **Epic**: Authentication
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/authentication.md`
**Requirement**: `TR-auth-???`

**ADR Governing Implementation**: ADR-0004: Authentication Architecture
**ADR Decision Summary**: Supabase Auth handles OAuth broker for Google and Apple; `signInWithOAuth()` delegates the flow; JWT issued by Supabase on success.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: Sign in with Apple requires `expo-apple-authentication`; Google OAuth uses `expo-auth-session`. Both require native module setup in Expo config.

---

## Acceptance Criteria

- [ ] Google OAuth login successfully authenticates the player on first use and returns them to the authenticated home flow
- [ ] Sign in with Apple login successfully authenticates the player on first use and returns them to the authenticated home flow
- [ ] Cancelling an OAuth flow mid-redirect returns the player to the login screen with no error shown
- [ ] Sign in with Apple button uses Apple-compliant styling and is at least as prominent as the Google button on iOS
- [ ] During the OAuth Authenticating state, login buttons are disabled to prevent duplicate submissions
- [ ] OAuth email matching an existing account from a different provider does not auto-merge; player is prompted to use their original method

---

## Implementation Notes

- Use `supabase.auth.signInWithOAuth({ provider: 'google' })` and Apple's native flow via `expo-apple-authentication`
- On OAuth cancel: the promise rejects silently; return to login screen; do NOT show an error toast
- Sign in with Apple: iOS App Store **requires** Apple login to be offered if any third-party login is offered; use `expo-apple-authentication` for native Apple button
- OAuth session links to an existing `auth.users` row if email matches same provider; cross-provider merging requires explicit account-link flow (out of scope for MVP)
- Store JWT in SecureStore identically to email/password flow on OAuth success

---

## Out of Scope

- Account linking flow (explicit link of Google to existing email account)
- Email verification UX for unverified OAuth accounts

---

## QA Test Cases

- **AC-1**: Google OAuth sign-in succeeds
  - Given: Google OAuth configured in Supabase; valid Google account
  - When: `signInWithOAuth({ provider: 'google' })` completes
  - Then: Session returned with `access_token`; player navigates to home flow
  - Edge cases: OAuth popup closed by OS (background app kill)

- **AC-2**: OAuth cancel — no error shown
  - Given: Google OAuth flow initiated
  - When: User closes OAuth popup/sheet without completing
  - Then: App returns to login screen; no error message displayed; auth state = Unauthenticated

- **AC-3**: Sign in with Apple button compliance
  - Given: App running on iOS
  - When: Login screen renders
  - Then: Apple button uses `AppleAuthenticationButton`; is visually at least as large as Google button
  - Edge cases: Dark mode styling; accessibility contrast

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/authentication/oauth-login_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (email/password flow establishes auth patterns)
- Unlocks: None directly
