# Story 002: Profile Read Path — Cache Hit / Miss / Redis Down

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

**ADR Governing Implementation**: ADR-0005: Database Architecture
**ADR Decision Summary**: Redis-first reads (TTL 300s); PostgreSQL fallback on miss; graceful degradation when Redis unavailable. Server-only fields excluded from client response.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-PP-03**: Cache hit → served from Redis; no PostgreSQL query; response <50ms p95; server-only fields absent from response
- [x] **AC-PP-04**: Cache miss → PostgreSQL queried; profile re-cached in Redis (TTL=300s); HTTP 200 with correct data
- [x] **AC-PP-05**: Redis unreachable → served from PostgreSQL; HTTP 200 (no error to client); `WARN: Redis unavailable` log entry

---

## Implementation Notes

- Read flow: `Redis.get(`profile:${userId}`)` → if hit: deserialize + return filtered payload; if miss: `SELECT * FROM player_profiles WHERE user_id=$1 AND is_deleted=false` → cache → return
- Redis unavailable detection: catch `Error` from `Redis.get()`; proceed to PostgreSQL fallback; log warn
- Server-only fields excluded: `display_name_last_changed_at`, `provisional_match_count`, `is_deleted`, `deleted_at`, `deletion_scheduled_at`, `schema_version`
- Win rate: computed at read time `wins / total_matches` (never stored)
- Economy fields (`diamond_balance`, `has_play_pass`, `has_no_ads`): always re-fetched from PostgreSQL after any economy write (cache invalidated on write)

---

## QA Test Cases

- **AC-PP-03**: Cache hit — no DB query
  - Given: `profile:uuid-abc` exists in Redis
  - When: `GET /v1/profile`
  - Then: Redis `GET` succeeds; PostgreSQL query NOT executed (verify via query log/mock); response time <50ms; `provisional_match_count` absent from response

- **AC-PP-04**: Cache miss — fallback and re-cache
  - Given: `profile:uuid-abc` does NOT exist in Redis (deleted or TTL expired)
  - When: `GET /v1/profile`
  - Then: PostgreSQL `SELECT` executed; Redis `SET` called with TTL=300; HTTP 200 with correct profile data

- **AC-PP-05**: Redis unavailable — graceful degradation
  - Given: Redis connection returns `ECONNREFUSED`
  - When: `GET /v1/profile`
  - Then: HTTP 200 with profile from PostgreSQL; `WARN: Redis unavailable` in logs; no error surfaced to client

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/player-profile/read-path-cache_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (profile exists in DB)
- Unlocks: Story 003 (display name), Story 005 (economy writes)
