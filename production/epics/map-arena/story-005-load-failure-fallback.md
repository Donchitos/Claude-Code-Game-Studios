# Story 005: Map Load Failure & Fallback

> **Epic**: Map / Arena System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/map-arena.md`
**Requirement**: `TR-map-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture; ADR-0012: Session & Match Lifecycle
**ADR Decision Summary**: Catalog fetch failure → 3 retries → bundled fallback map for mode → proceed; total catalog + fallback failure → match aborted, no loss recorded.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-14**: Catalog returns 500 for map fetch → server retries 3 times → fallback bundled map loaded; ERROR logged; match proceeds normally; no player notification
- [x] **AC-15**: Both catalog fetch AND bundled fallback fail → match aborted; all clients receive `match_error { code: 'MAP_LOAD_FAILURE' }`; no loss recorded; players returned to lobby
- [x] **AC-17**: Player position computed 0.3 LGU from edge; `safe_boundary_inset=0.5 LGU` → position clamped to 0.5 LGU from edge

---

## Implementation Notes

- Map fetch with retry: `fetchWithRetry(mapId, maxRetries=3)` — exponential backoff; on exhaustion: load from `server/src/data/maps/{mapId}.json` (bundled fallback)
- If bundled fallback also fails: `sessionManager.onMatchLoadFailure(matchId)`; emit `match_error` to all players in room; destroy session; no Match Server started
- Boundary clamping: `clampToBoundary(pos, mapBounds, safeInset)` in collision resolution: `x = clamp(pos.x, safeInset, mapWidth - safeInset)`

---

## QA Test Cases

- **AC-14**: Catalog failure + successful fallback
  - Given: Catalog mock returns 500 for map fetch; bundled fallback exists
  - When: 3 retry attempts fail; fallback loaded
  - Then: Match starts with fallback map; `ERROR` log with map ID; no `match_error` sent to clients

- **AC-15**: Total failure → match aborted
  - Given: Catalog fails (3 retries); bundled fallback also fails (simulated)
  - When: Map load attempted
  - Then: All players receive `match_error { code: 'MAP_LOAD_FAILURE' }`; session destroyed; no `wins/losses` recorded in player_profiles

- **AC-17**: Safe boundary clamping
  - Given: Player computed at x=0.3 LGU; `safeInset=0.5`
  - When: Position processed
  - Then: Player clamped to x=0.5 LGU

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/map-arena/load-failure-fallback_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (map config structure), Session Manager epic
- Unlocks: No remaining map-arena stories
