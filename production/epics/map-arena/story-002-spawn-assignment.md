# Story 002: Spawn Point Assignment

> **Epic**: Map / Arena System
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/map-arena.md`
**Requirement**: `TR-map-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop; ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: Spawn points assigned server-side at match init; unique per player; distance constraints enforced; LGU coordinate system (origin bottom-left, Y-axis up).

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-05**: 1v1 on Slag Pit → player 0 and 1 get distinct spawn indices; distance between spawns ≥12 LGU; both within safe boundaries
- [ ] **AC-06**: FFA 8-player on Neon Sprawl → all 8 get distinct spawn indices; no two spawns closer than 10 LGU from each other

---

## Implementation Notes

- `SpawnAssigner.assignSpawns(map, playerCount)`: select `playerCount` spawn points from `map.spawnPoints` array
- Distance constraint: validate all pairs `distance(spawn_i, spawn_j) >= minDistanceLGU` for the mode
- If constraint cannot be satisfied (fewer spawn points than players + distance): log error; assign sequentially (fallback)
- LGU: `distance = sqrt((x2-x1)^2 + (y2-y1)^2)`

---

## QA Test Cases

- **AC-05**: 1v1 spawn distance
  - Given: Slag Pit map with spawn points at known coordinates
  - When: `assignSpawns(map, 2)` called
  - Then: Two distinct spawn indices assigned; `distance(spawn0, spawn1) >= 12`; both within `[safeInset, mapWidth-safeInset] × [safeInset, mapHeight-safeInset]`

- **AC-06**: FFA 8-player unique spawns
  - Given: Neon Sprawl with ≥8 spawn points
  - When: `assignSpawns(map, 8)` called
  - Then: 8 distinct indices; all pairwise distances ≥10 LGU

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/map-arena/spawn-assignment_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (map configs loaded)
- Unlocks: Story 003 (obstacle collision)
