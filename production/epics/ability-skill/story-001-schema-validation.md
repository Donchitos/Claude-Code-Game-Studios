# Story 001: Ability Schema Validation — 18 Canonical Abilities

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

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: AbilityDefinition sourced from catalog; 18 canonical abilities validated at startup; `ability.get(id)` returns null for unknown IDs.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-1.1**: Every ability has unique canonical ID matching `loadout_item:ability_{slug}`
- [ ] **AC-1.2**: Every active ability has `cooldownSec > 0`
- [ ] **AC-1.3**: Every projectile ability has `range_units > 0`
- [ ] **AC-1.4**: Every ability with `aoeRadius_units > 0` has `range_units >= 0`
- [ ] **AC-1.5**: No ability has `affinityBonus` outside [0, 1]
- [ ] **AC-1.6**: Each `affinityCharacterIds` entry is a valid `character:{slug}` canonical ID

---

## Implementation Notes

- `AbilityRegistry.init(catalog)`: `catalog.getAll('loadout_item')` → filter by `type: 'ability'` → validate each
- Validation failures: log `ABILITY_VALIDATION_FAILED: { abilityId, reason }`; exclude from registry; if count < 18 after validation, log warning (not fatal — may have extras)
- `ability.get(id)`: `map.get(id) ?? null`
- `ability.isValid(id)`: `map.has(id)`

---

## QA Test Cases

- **AC-1.1**: All 18 abilities have unique IDs
  - Given: Catalog with 18 ability records
  - When: `AbilityRegistry.init()` called
  - Then: Registry has exactly 18 entries; no duplicate IDs; `ROSTER_LOADED: 18 abilities validated` logged

- **AC-1.2**: Active ability without cooldown fails validation
  - Given: Ability `ability:broken_shot` has `type: 'active'` and `cooldownSec: 0`
  - When: Validated
  - Then: `ABILITY_VALIDATION_FAILED: ability:broken_shot, reason: active_ability_missing_cooldown`; excluded from registry

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ability-skill/schema-validation_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Content Catalog Story 001
- Unlocks: Story 002 (execution pipeline)
