# Story 001: Map Schema Validation & Mode-Based Selection

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

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: MapConfig sourced from catalog; mode-compatible maps selected; recent map repeat suppression via weight system.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-01**: Map with missing required field, invalid spawn distances, or obstacle outside safe boundary → rejected by schema validator; structured error listing each violation
- [ ] **AC-02**: Duel match → only maps with `"duel_1v1"` in `mode_compatibility` considered; selected within 50ms
- [ ] **AC-03**: Most-recently-played Squad Brawl map → weight 0 (not selected) when other eligible maps exist
- [ ] **AC-04**: Single-map pool → server logs warning and selects that map anyway (weight suppression lifted)

---

## Implementation Notes

- `MapSelector.selectForMode(mode, recentMaps[])`: filter catalog by mode compatibility; apply weight 0 to most-recent map; weighted random selection
- Schema validator: Zod schema for `MapConfig`; run at catalog load time; fail-fast on invalid maps
- `recentMaps[]`: ring buffer of last N maps played per mode; stored in-memory by `MapSelector`

---

## QA Test Cases

- **AC-01**: Schema validation rejects invalid map
  - Given: Map JSON missing `spawn_points` field
  - When: `validateMapSchema(mapJson)` called
  - Then: Returns structured error `{ violations: [{ field: 'spawn_points', reason: 'missing' }] }`; map not added to catalog

- **AC-02**: Mode-specific map selection
  - Given: 3 maps total; 2 with `duel_1v1` in compatibility; 1 squad_3v3 only
  - When: `selectForMode('duel_1v1', [])` called
  - Then: Only 2 duel-compatible maps are candidates; selection completes within 50ms

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/map-arena/schema-validation-selection_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Content Catalog Story 001
- Unlocks: Story 002 (spawn assignment)
