# Story 006: Concurrent Stat Increments

> **Epic**: Player Profile
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/player-profile.md`
**Requirement**: `TR-persist-???`

**ADR Governing Implementation**: ADR-0005: Database Architecture
**ADR Decision Summary**: All stat increments use additive SQL operations (`wins = wins + 1`) — not read-modify-write from application code. PostgreSQL row-level locking serializes concurrent writes.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-PP-12**: Two simultaneous match results for same `userId` → `wins` and `total_matches` each reflect exactly 2 increments; no lost update; no constraint error
- [ ] Stat increments use `UPDATE player_profiles SET wins = wins + 1, total_matches = total_matches + 1 WHERE user_id = $1` (never read-modify-write)
- [ ] `wins` and `total_matches` updated in the same SQL statement (atomic)
- [ ] `mmr` and `peak_mmr` updated with `SELECT ... FOR UPDATE` to serialize concurrent MMR writes

---

## Implementation Notes

- NEVER: `profile = await getProfile(userId); profile.wins++; await updateProfile(userId, profile)` — this loses updates
- ALWAYS: `await db.query('UPDATE player_profiles SET wins = wins + 1, total_matches = total_matches + 1 WHERE user_id = $1', [userId])`
- For MMR (involves Elo calculation): `BEGIN; SELECT ... FOR UPDATE WHERE user_id = $1; compute delta; UPDATE mmr = mmr + $delta; COMMIT`
- After any stat write: invalidate Redis cache (`DEL profile:{userId}`)

---

## QA Test Cases

- **AC-PP-12**: Concurrent stat increment no-loss
  - Given: Player with `wins=0`, `total_matches=0`
  - When: Two match result writes execute concurrently (Promise.all in test)
  - Then: Final state: `wins=2`, `total_matches=2` (both applied atomically, no lost update)

- **AC-atomic-mmr**: MMR concurrent write with FOR UPDATE
  - Given: Player with `mmr=1000`; two matches end simultaneously, each computing `mmrDelta=+15`
  - When: Both MMR writes execute concurrently
  - Then: Final `mmr` is either 1015 (one applied) or 1030 (both applied serially); never 1015 applied twice; no deadlock

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player-profile/concurrent-stat-increments_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Match Server, MMR/Ranked epics (stats writing)
