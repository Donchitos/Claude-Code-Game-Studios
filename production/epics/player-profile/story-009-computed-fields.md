# Story 009: Computed Fields, Provisional Status & Public Payload

> **Epic**: Player Profile
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/player-profile.md`
**Requirement**: `TR-persist-???`

**ADR Governing Implementation**: ADR-0005: Database Architecture
**ADR Decision Summary**: `win_rate` computed at read time (not stored); `is_provisional` derived from `provisional_match_count < 30` (stored but updated atomically); public profile payload excludes economy fields.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-PP-15**: Player `wins=37`, `total_matches=63` → `win_rate = 0.587` in profile response; no `win_rate` column in DB
- [ ] **AC-PP-16**: Player `provisional_match_count=29`; one match processed → `provisional_match_count=30`, `is_provisional=false`; both in same transaction
- [ ] **AC-PP-17**: `GET /profile/{player_b}/public` → includes `user_id, display_name, avatar_id, level, mmr, peak_mmr, total_matches, wins, losses, kills, preferred_character_id`; excludes `diamond_balance, has_no_ads, has_play_pass, analytics_consent, region, created_at, last_seen_at, is_provisional, unlocked_character_ids`

---

## Implementation Notes

- `win_rate`: computed in the API response serializer: `profile.win_rate = profile.total_matches > 0 ? profile.wins / profile.total_matches : 0.0`
- `is_provisional`: stored boolean updated atomically with `provisional_match_count` in each match result write
- Public payload: separate serializer function `toPublicPayload(profile)` that picks only the allowed fields; used for `GET /v1/profile/:userId/public`
- `provisional_match_count` field is server-only; strip from all client responses

---

## QA Test Cases

- **AC-PP-15**: Win rate computed, not stored
  - Given: `wins=37`, `total_matches=63`
  - When: `GET /v1/profile`
  - Then: Response contains `win_rate: 0.587` (or `58.7%`); `SELECT column_name FROM information_schema.columns WHERE table_name='player_profiles'` does NOT contain `win_rate`

- **AC-PP-16**: Provisional transition atomicity
  - Given: `provisional_match_count=29`, `is_provisional=true`
  - When: Match Server increments provisional_match_count to 30
  - Then: Single transaction; both `provisional_match_count=30` and `is_provisional=false` committed together; no state where count=30 and `is_provisional=true` is visible

- **AC-PP-17**: Public payload exclusions
  - Given: Player A requests public profile of Player B (who has all fields populated)
  - When: `GET /v1/profile/{playerB_userId}/public`
  - Then: Response has all 11 allowed fields; `diamond_balance`, `analytics_consent`, `region`, etc. are completely absent from JSON

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player-profile/computed-fields_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (profile data), Story 002 (read path serialization)
- Unlocks: No remaining player-profile stories
