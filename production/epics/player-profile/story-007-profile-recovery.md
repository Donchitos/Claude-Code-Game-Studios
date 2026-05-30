# Story 007: Profile Not Found Recovery

> **Epic**: Player Profile
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/player-profile.md`
**Requirement**: `TR-persist-???`

**ADR Governing Implementation**: ADR-0005: Database Architecture; ADR-0004: Authentication Architecture
**ADR Decision Summary**: Valid JWT but no profile row → confirm userId in Supabase Auth → trigger profile creation recovery → return new default profile. Unknown userId → 401.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-PP-13**: Valid JWT + missing profile row → server confirms userId in Supabase Auth → triggers profile creation recovery → HTTP 200 with new default profile; `WARN: Profile missing for valid auth user` log emitted
- [x] Supabase Auth confirms user exists but profile creation fails → HTTP 503, `PROFILE_CREATION_FAILED`
- [x] Supabase Auth cannot confirm user → HTTP 401, `AUTH_USER_NOT_FOUND`

---

## Implementation Notes

- In `GET /v1/profile` handler: after PostgreSQL miss (no row), call `supabase.auth.admin.getUserById(userId)` to confirm user exists
- If user confirmed: run profile creation flow (Story 001's `createDefaultProfile(userId)` function); log warn; return new profile
- If user not found in Supabase Auth: return 401 `AUTH_USER_NOT_FOUND`; do not create a ghost profile
- Recovery path should be rare; log at WARN level for monitoring

---

## QA Test Cases

- **AC-PP-13**: Profile recovery for valid user
  - Given: `userId = 'uuid-xyz'` exists in Supabase Auth; no row in `player_profiles`
  - When: `GET /v1/profile` with valid JWT for `uuid-xyz`
  - Then: Profile row created; HTTP 200 with default profile; `WARN` log contains `uuid-xyz`

- **AC-unknown-user**: No Supabase Auth user
  - Given: JWT is valid format but `userId` not in Supabase Auth (e.g., deleted user)
  - When: `GET /v1/profile`
  - Then: HTTP 401, `{ code: 'AUTH_USER_NOT_FOUND' }`; no profile row created

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player-profile/profile-recovery_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (profile creation function reused), Story 002 (read path)
- Unlocks: Story 008 (GDPR delete)
