# Story 005: Logout & Session Revocation

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
**ADR Decision Summary**: Logout calls `supabase.auth.signOut()` (server-side session revocation); client clears JWT from SecureStore; socket connection closed; all stores invalidated.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] Tapping logout revokes the session server-side, clears all local tokens, and returns the player to the login screen
- [x] After logout, back gesture / Android back button cannot navigate to the home screen — player is blocked at the login screen
- [x] All Zustand stores (ProfileStore, InventoryStore) are cleared on logout
- [x] Active Socket.io connection is closed on logout
- [x] Logout while a match is active: session revoked immediately; match treated as disconnect server-side

---

## Implementation Notes

- Call `supabase.auth.signOut()` which revokes session server-side and clears local Supabase session state
- Additionally: `await SecureStore.deleteItemAsync('jwt')` to ensure no stale token on next cold start
- After signOut: `ProfileStore.getState().invalidate()`; `InventoryStore.getState().setInventory(null)`
- After signOut: `socket.disconnect()` — the socket middleware will handle graceful close
- Navigation: use `router.replace('/login')` (not `router.push`) to replace the history stack; back gesture cannot return to protected routes
- If logout fails server-side (network error): still clear local state; log the failure; navigate to login anyway

---

## Out of Scope

- Match disconnect handling on mid-game logout (handled by Session Manager / Disconnect Handler epic)

---

## QA Test Cases

- **AC-1**: Logout clears state and navigates to login
  - Given: Authenticated player on home screen
  - When: Logout tapped
  - Then: `supabase.auth.signOut()` called; SecureStore cleared; ProfileStore = null; socket disconnected; login screen shown
  - Edge cases: Logout on slow network (server 500 → still clear local state)

- **AC-2**: Back gesture blocked after logout
  - Given: Player logged out and on login screen
  - When: Back gesture or Android back button pressed
  - Then: Navigation does not go to home screen; player remains on login screen or exits app (OS default)

- **AC-3**: All stores cleared
  - Given: ProfileStore has `profile = {...}`; InventoryStore has entitlements
  - When: Logout
  - Then: Both stores return null on next read; no stale data rendered if user logs in again with different account

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/authentication/logout_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 003 (session exists before logout)
- Unlocks: None directly (logout is the end state)
