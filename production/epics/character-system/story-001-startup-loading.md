# Story 001: Character Startup Loading & Validation

> **Epic**: Character System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/character-system.md`
**Requirement**: `TR-char-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: CharacterDefinition sourced from catalog at startup; invalid definitions excluded with error log; `ROSTER_LOADED: N characters validated` log on success.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-CHAR-001**: Content Catalog has valid definitions for all 8 characters → startup log `ROSTER_LOADED: 8 characters validated`
- [x] **AC-CHAR-002**: Character with `passive_ability_id` that doesn't resolve → excluded from roster; `CHAR_VALIDATION_FAILED` logged with character ID and reason; remaining valid characters load normally
- [x] **AC-CHAR-003**: Character with `ability_slot_count: 3` → validation fails; excluded from roster; error logged
- [x] `CharacterSystem.getAvailableRoster()` returns only valid characters

---

## Implementation Notes

- `CharacterSystem.init(catalog)`: `catalog.getAll('character')` → validate each definition:
  - `passive_ability_id` must resolve in ability registry
  - `ability_slot_count` must equal 2
  - `id` must match `character:{slug}` format
- Invalid characters: log `CHAR_VALIDATION_FAILED: { characterId, reason }`; push to excluded list; continue
- If all 8 required characters fail validation: server startup failure

---

## QA Test Cases

- **AC-CHAR-001**: All 8 load successfully
  - Given: Catalog with all 8 valid character definitions
  - When: `CharacterSystem.init(catalog)` called
  - Then: `getAvailableRoster().length === 8`; `ROSTER_LOADED: 8 characters validated` in logs

- **AC-CHAR-002**: Invalid passive ability → character excluded
  - Given: `character:vex` has `passive_ability_id: 'ability:nonexistent'`
  - When: Init called
  - Then: `getAvailableRoster()` has 7 characters; `CHAR_VALIDATION_FAILED: character:vex, reason: passive_ability_id_not_found` in logs; other 7 characters unaffected

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/character-system/startup-loading_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Content Catalog Story 001 (catalog initialized with character records)
- Unlocks: Story 002 (availability check)
