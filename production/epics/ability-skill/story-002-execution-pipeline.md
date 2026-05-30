# Story 002: Ability Execution Pipeline

> **Epic**: Ability / Skill System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/ability-skill.md`
**Requirement**: `TR-ability-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Ability execution runs in tick simulation phase; cooldown begins after effect resolves (not at cast initiation); `AbilityConfirmed` emitted to caster on success.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-2.1**: Ability on cooldown → `AbilityRejected { reason: "COOLDOWN" }`
- [x] **AC-2.2**: STUNNED player → `AbilityRejected { reason: "INELIGIBLE" }`
- [x] **AC-2.3**: Dead player → `AbilityRejected { reason: "INELIGIBLE" }`
- [x] **AC-2.4**: `castTimeMs > 0` → player move speed -50% during cast duration
- [x] **AC-2.5**: Cannot activate second ability slot while cast in progress
- [x] **AC-2.6**: Cooldown begins at `castCompleteTime + cooldownSec` (not at cast start)
- [x] **AC-2.7**: `AbilityConfirmed { abilityId, cooldownExpiresAt }` sent to caster on success

---

## Implementation Notes

- Execution sequence in simulation phase:
  1. Check player alive → if dead: `AbilityRejected INELIGIBLE`
  2. Check STUNNED status → if stunned: `AbilityRejected INELIGIBLE`
  3. Check cooldown: `currentTick * 50 >= ability.cooldownExpiresAt` → if not: `AbilityRejected COOLDOWN`
  4. Check no active cast in progress → if casting: `AbilityRejected INELIGIBLE`
  5. Begin cast: set `player.castCompleteTick = currentTick + castTimeMs/50`; apply move speed penalty
  6. At `castCompleteTick`: resolve effect; set `ability.cooldownExpiresAt = resolveTimestamp + cooldownSec * 1000`
  7. Emit `AbilityConfirmed { abilityId, cooldownExpiresAt }` to caster socket

---

## QA Test Cases

- **AC-2.1**: Cooldown rejected
  - Given: Ability with `cooldownSec = 3`; player fired it at tick 10; current tick = 50 (2.5s later < 3s)
  - When: `USE_ABILITY` input processed
  - Then: `AbilityRejected { reason: 'COOLDOWN' }` sent to caster; player state unchanged

- **AC-2.6**: Cooldown starts at resolve, not cast
  - Given: Ability with `castTimeMs=400` (8 ticks) and `cooldownSec=3`
  - When: Player casts at tick 0
  - Then: `cooldownExpiresAt = (tick_8_timestamp) + 3000` (not `tick_0_timestamp + 3000`)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ability-skill/execution-pipeline_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (registry loaded), Match Server epic (tick context)
- Unlocks: Story 003 (cooldown enforcement), Story 005 (status effects)
