# Story 004: Affinity Bonus Calculation

> **Epic**: Ability / Skill System
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/ability-skill.md`
**Requirement**: `TR-ability-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Affinity bonus = +10% to `effectMagnitude` only when caster is in `affinityCharacterIds`; does not affect duration or AoE radius.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-4.1**: Character in `affinityCharacterIds` fires ability → `resolvedMagnitude = baseMagnitude × 1.10`
- [ ] **AC-4.2**: Character NOT in `affinityCharacterIds` fires same ability → `resolvedMagnitude = baseMagnitude`
- [ ] **AC-4.3**: Affinity bonus applies ONLY to `effectMagnitude`; `effectDuration_ms` and `aoeRadius_units` unchanged

---

## Implementation Notes

- In Combat Resolver `resolveAbilityEffect()`: `const hasAffinity = ability.affinityCharacterIds.includes(caster.characterId)`
- `resolvedMagnitude = ability.effectMagnitude * (hasAffinity ? 1.10 : 1.00)`
- Duration and AoE: always use base values regardless of affinity

---

## QA Test Cases

- **AC-4.1**: Affinity bonus applied
  - Given: `ability:fireball` has `affinityCharacterIds: ['character:vex']`; caster = Vex; `baseMagnitude = 20`
  - When: Ability resolves
  - Then: `resolvedMagnitude = 22.0` (20 × 1.10)

- **AC-4.2**: No bonus for non-affinity character
  - Given: Same ability; caster = Zook (not in affinityCharacterIds)
  - When: Ability resolves
  - Then: `resolvedMagnitude = 20.0` (exact base, no bonus)

- **AC-4.3**: Duration unchanged by affinity
  - Given: Affinity caster; ability with `effectDuration_ms = 2000`
  - When: Ability resolves
  - Then: Applied status effect duration = 2000ms (not 2200ms)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ability-skill/affinity-bonus_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (execution pipeline), Combat System epic
- Unlocks: Story 005 (status effects)
