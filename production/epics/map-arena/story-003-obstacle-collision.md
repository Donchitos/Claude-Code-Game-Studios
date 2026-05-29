# Story 003: Obstacle Collision — Static & Destructible

> **Epic**: Map / Arena System
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/map-arena.md`
**Requirement**: `TR-map-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Obstacle collision resolved server-side in simulation phase; destructible obstacles have HP; destroyed obstacles excluded from future collision checks and included in reconnect snapshot.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-07**: Player moves through static obstacle → server corrects position to nearest point outside boundary; position correction event sent to client
- [ ] **AC-08**: Destructible obstacle (100 HP); ability with `obstacle_damage=50` hits twice → HP=0 after second hit; `obstacle_destroyed` broadcast; excluded from future collision checks
- [ ] **AC-09**: Player reconnects after obstacle destroyed → `match_state_snapshot` includes destroyed obstacle ID in `destroyed_obstacles[]`; client renders as destroyed within one render frame

---

## Implementation Notes

- `ObstacleManager.resolveCollision(playerPos, obstacles[])`: for each static + living destructible obstacle, check if player bounding box overlaps; if so, find nearest outside point and clamp
- `destructibleObstacles: Map<obstacleId, { hp, isDestroyed }>` — maintained in match state
- `processObstacleDamage(obstacleId, damage)`: decrement HP; if `hp <= 0`: set `isDestroyed = true`; broadcast `obstacle_destroyed { id }` to room; remove from collision checks
- Reconnect snapshot: `getSnapshot().destroyedObstacles = [...destroyedObstacleIds]`

---

## QA Test Cases

- **AC-07**: Static obstacle collision correction
  - Given: Player at position that overlaps static obstacle
  - When: Server processes movement tick
  - Then: Player position moved to nearest point outside obstacle; `position_correction` event emitted to player socket

- **AC-08**: Destructible obstacle destruction
  - Given: Obstacle HP=100; player hits with obstacle_damage=50 twice
  - When: Second hit processed
  - Then: `isDestroyed = true`; `obstacle_destroyed { id: 'obs_1' }` broadcast to all in room; `ObstacleManager.getActive()` excludes `obs_1`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/map-arena/obstacle-collision_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (map configs), Match Server epic (simulation phase)
- Unlocks: Story 004 (zone shrink)
