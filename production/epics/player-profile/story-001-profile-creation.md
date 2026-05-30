# Story 001: Profile Creation on First Login

> **Epic**: Player Profile
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/player-profile.md`
**Requirement**: `TR-persist-???`

**ADR Governing Implementation**: ADR-0005: Database Architecture; ADR-0004: Authentication Architecture
**ADR Decision Summary**: On first `GET /v1/profile` for a new `userId`, profile row inserted with defaults using `ON CONFLICT (user_id) DO NOTHING`; cached in Redis after creation.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-PP-01**: New Supabase Auth user; no existing profile → `GET /profile` → new row with all defaults; `unlocked_character_ids = ["character:vex","character:zook","character:sera"]`; `display_name` matches `"Player_[A-Z0-9]{6}"`; `diamond_balance = 0`, `mmr = 1000`, `level = 1`, `xp = 0`, `is_provisional = true`; HTTP 200; profile cached in Redis
- [x] **AC-PP-02**: Two simultaneous first-login requests for same `userId` → exactly one `player_profiles` row; both requests return HTTP 200 with same profile data; no error to either client

---

## Implementation Notes

- `INSERT INTO player_profiles ... ON CONFLICT (user_id) DO NOTHING` — do not use `UPSERT` (it would overwrite)
- Default display name: `"Player_" + randomBytes(3).toString('hex').toUpperCase()` → 6 hex chars → check `LOWER(display_name)` uniqueness; retry up to 5 times on collision; fallback to `user_id` first 8 chars
- Free characters pre-populated in `unlocked_character_ids` text array at INSERT time
- After INSERT: `Redis.set(`profile:${userId}`, serialize(profile), { EX: 300 })`
- Profile creation triggered by: Supabase DB trigger on `auth.users` insert (preferred) OR server-side check on `GET /v1/profile` miss

---

## QA Test Cases

- **AC-PP-01**: Profile creation on first login
  - Given: `userId = 'uuid-abc'` with no row in `player_profiles`
  - When: `GET /v1/profile` called with valid JWT for that userId
  - Then: Row inserted; `SELECT * WHERE user_id = 'uuid-abc'` returns row with defaults; Redis key `profile:uuid-abc` exists; HTTP 200 returned with client-visible fields

- **AC-PP-02**: Concurrent creation idempotency
  - Given: Two simultaneous requests for same userId (test with Promise.all)
  - When: Both complete
  - Then: `SELECT COUNT(*) WHERE user_id = 'uuid-abc'` = 1; both responses are HTTP 200 with identical profile data

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/player-profile/profile-creation_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Authentication Story 006 (JWT validation), real Supabase PostgreSQL schema deployed
- Unlocks: Story 002 (read path)
