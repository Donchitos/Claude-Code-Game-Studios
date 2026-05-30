# Story 003: Session Persistence & Cold Start

> **Epic**: Authentication
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/authentication.md`
**Requirement**: `TR-auth-???`

**ADR Governing Implementation**: ADR-0004: Authentication Architecture
**ADR Decision Summary**: Supabase client SDK reads stored refresh token on cold start; silently exchanges for new access token before home screen renders.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] Closing and reopening the app while a valid session exists returns the player to the home screen without re-entering credentials
- [x] After a session has been revoked (logout or server-side revocation), reopening the app does not restore gameplay access and redirects to the unauthenticated flow
- [x] If secure on-device auth state is corrupted or unreadable on launch, the app clears local auth state safely and enters the unauthenticated flow without crashing
- [x] Cold start reads stored refresh token via `supabase.auth.getSession()` before any authenticated API call is made

---

## Implementation Notes

- Call `supabase.auth.getSession()` on app startup inside the root layout's `useEffect`
- If `session` is null or expired → navigate to login screen
- If `session` is valid → proceed to home; access token is already refreshed by Supabase SDK automatically
- Wrap `getSession()` in try/catch; on `SecureStore` read failure → `supabase.auth.signOut()` to clear state → navigate to login
- Show a loading splash screen while `getSession()` resolves; never show a blank/broken home screen
- `onAuthStateChange` listener should be registered to handle mid-session expiry transitions

---

## Out of Scope

- Token refresh lifecycle (handled by Story 004)
- Session Expired modal UX (handled by Story 004)

---

## QA Test Cases

- **AC-1**: Valid session → home screen on cold start
  - Given: Previous login stored refresh token in SecureStore
  - When: App cold-starts
  - Then: `getSession()` returns valid session; home screen renders within 2s; no login prompt
  - Edge cases: Device locked between sessions (SecureStore accessible after unlock)

- **AC-2**: Revoked session → login screen
  - Given: Session revoked server-side (user logged out from another device)
  - When: App cold-starts
  - Then: `getSession()` returns null or throws; login screen shown; no home screen flash

- **AC-3**: Corrupted SecureStore → safe recovery
  - Given: SecureStore data is corrupted (simulated by wiping the key)
  - When: App cold-starts
  - Then: `getSession()` returns null; app navigates to login screen without crashing; no error dialog (or a generic "please log in again" if needed)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/authentication/session-persistence_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (session creation)
- Unlocks: Story 004 (token refresh lifecycle)
