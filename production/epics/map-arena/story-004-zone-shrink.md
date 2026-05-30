# Story 004: Zone Shrink Mechanics (FFA)

> **Epic**: Map / Arena System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/map-arena.md`
**Requirement**: `TR-map-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: FFA zone shrinks in phases on a time schedule; zone damage applied per tick for players outside boundary; zone radius included in match state.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-10**: FFA; `start_delay_sec=60`; at T=59s → zone radius = `initial_radius` (no shrink)
- [x] **AC-11**: FFA phase 1 begins T=60s; `initial_radius=60`, `end_radius=36` over 60s → at T=90s (30s into phase): `radius = 48.0 LGU (±0.1)`
- [x] **AC-12**: Player 5 LGU outside zone; `damage_per_sec=15`; tick 50ms → `0.75 HP damage` (15 × 0.05)
- [x] **AC-13**: Player inside zone → zero zone damage that tick
- [x] **AC-16**: FFA zone boundary visible on minimap as circle overlay updating in real time

---

## Implementation Notes

- `ZoneManager.getRadius(matchTimeSec, phaseSchedule[])`: piecewise linear interpolation per phase
- `alpha = (matchTimeSec - phaseStart) / (phaseEnd - phaseStart)`; `radius = lerp(initialRadius, endRadius, alpha)`
- Zone damage per tick: `if distance(player, center) > currentRadius: player.hp -= damagePerSec * 0.050`
- Zone state in `matchState`: `{ zoneRadius, zoneCenter }` included in every `state_snapshot` and `state_delta`
- HUD minimap: client reads `zoneRadius` from match state and renders circle overlay

---

## QA Test Cases

- **AC-11**: Linear interpolation correctness
  - Given: Phase starts at T=60s; initialRadius=60; endRadius=36; duration=60s
  - When: `getRadius(90)` called (30s into phase)
  - Then: `60 + (36-60) * (30/60) = 60 - 12 = 48.0 LGU`

- **AC-12**: Zone damage per tick
  - Given: Player at `distance = currentRadius + 5`; `damage_per_sec = 15`; tick = 50ms
  - When: Damage tick applied
  - Then: `player.hp -= 0.75` (15 × 0.050); no damage if `distance <= currentRadius`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/map-arena/zone-shrink_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (map configs with zone phase schedules)
- Unlocks: Story 005 (load failure)
