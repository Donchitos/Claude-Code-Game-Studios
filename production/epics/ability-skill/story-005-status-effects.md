# Story 005: Status Effects — Interactions & Stacking Rules

> **Epic**: Ability / Skill System
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/ability-skill.md`
**Requirement**: `TR-ability-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Status effects: BURNING, SHIELDED, STUNNED, SLOWED, INVISIBLE. BURNING bypasses SHIELDED. No stacking — re-application refreshes duration; highest magnitude wins.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-5.1**: STUNNED → `AbilityRejected INELIGIBLE` for both slots for stun duration
- [ ] **AC-5.2**: STUNNED → movement inputs ignored for stun duration
- [ ] **AC-5.3**: SLOWED → `effectiveMoveSpeed = baseMoveSpeed × (1 - magnitudePct/100)`, floored at 10% of base
- [ ] **AC-5.4**: SHIELDED → incoming damage depletes shield HP; overflow to player HP
- [ ] **AC-5.5**: BURNING damage bypasses SHIELDED → applies directly to player HP
- [ ] **AC-5.6**: INVISIBLE → absent from opponent state snapshots for duration
- [ ] **AC-5.7**: INVISIBLE → using any active ability removes INVISIBLE immediately
- [ ] **AC-5.8**: BURNING → `magnitude` HP damage every 500ms for duration
- [ ] **AC-5.9**: No stacking — re-application refreshes duration; highest magnitude wins

---

## Implementation Notes

- `PlayerState.statusEffects: StatusEffect[]` — list of active effects
- Each tick: check active status effects, apply/decrement
- BURNING implementation: `ticksRemaining = ceil(effectDuration_ms / 50)`; every 10th tick (500ms): `player.hp -= burning.magnitude`
- SHIELDED: absorb incoming damage in `resolveHit()`; BURNING exception: skip shield check for BURNING damage type
- No stacking: `applyStatusEffect()`: if effect of same type exists, refresh duration; if new magnitude > existing: replace magnitude

---

## QA Test Cases

- **AC-5.5**: BURNING bypasses SHIELDED
  - Given: Player SHIELDED with 50 shield HP; player then hit by BURNING (10 damage/tick)
  - When: BURNING tick fires
  - Then: Player HP reduced by 10; shield HP unchanged

- **AC-5.9**: No stacking — duration refresh
  - Given: Player SLOWED (magnitude 30%, duration 2000ms remaining)
  - When: Same player hit by SLOWED (magnitude 20%, duration 3000ms)
  - Then: Active SLOWED has magnitude 30% (higher wins); duration refreshed to 3000ms

- **AC-5.3**: SLOWED move speed floor
  - Given: `baseMoveSpeed = 5.0`; SLOWED `magnitudePct = 95`
  - When: Speed computed
  - Then: `effectiveMoveSpeed = max(5.0 * (1 - 0.95), 5.0 * 0.10) = 0.5` (10% floor applied)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ability-skill/status-effects_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (execution pipeline), Combat System epic
- Unlocks: Story 006 (passive abilities)
