# Story 007: Targeting Models & Edge Cases

> **Epic**: Ability / Skill System
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/ability-skill.md`
**Requirement**: `TR-ability-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Projectile, targeted, and AoE targeting models; cooldown boundary at exact expiry is accepted; disconnect during cast cancels cast without consuming cooldown.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-8.1**: Projectile ability resolves on first enemy collision OR at `range_units` (despawn, no effect)
- [ ] **AC-8.2**: Targeted ability misses and consumes cooldown if target moved outside `range_units` by resolution time
- [ ] **AC-8.3**: AoE ability affects ALL valid targets within radius at resolution time simultaneously
- [ ] **AC-8.4**: AoE projectile travels to placement point then resolves AoE; all targets in radius at arrival affected
- [ ] **AC-7.1**: Ability request at exactly `currentTime == cooldownExpiresAt` → accepted (boundary inclusive)
- [ ] **AC-7.2**: Player disconnects during cast → cast cancelled; cooldown NOT consumed; move speed penalty removed
- [ ] **AC-7.4**: Target dies before `castCompleteAt` → effect doesn't apply; cooldown IS consumed

---

## Implementation Notes

- Targeting type determined by `ability.projectile` + `ability.aoeRadius_units` fields
- Projectile: maintain `ProjectileState` in match state; advance position each tick; check collision
- AoE: `Math.sqrt((tx-px)^2 + (ty-py)^2) <= aoeRadius_units` for each player at resolution
- Disconnect during cast: `Disconnect Handler` sets `player.isActive = false`; simulation phase cancels in-progress cast for inactive players

---

## QA Test Cases

- **AC-8.1**: Projectile despawns at range
  - Given: Projectile fired; no enemy in `range_units`; projectile reaches max range
  - When: Collision checked
  - Then: Projectile removed from `ProjectileState[]`; no damage applied; cooldown consumed

- **AC-7.2**: Disconnect during cast
  - Given: Player begins cast of 400ms ability at tick 0; disconnects at tick 5 (250ms into cast)
  - When: `onPlayerDisconnect()` processes
  - Then: Cast cancelled; `cooldownExpiresAt` unchanged (not set); `player.castCompleteTick` cleared; move speed penalty removed

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ability-skill/targeting-edge-cases_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (execution pipeline), Story 003 (cooldown)
- Unlocks: No remaining ability-skill stories
