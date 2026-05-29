# Story 001: Cold Start & Bundled Baseline

> **Epic**: Content Catalog
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/content-catalog.md`
**Requirement**: `TR-catalog-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: In-memory singleton loaded from static JSON bundle at server startup (step 4 of init order); startup throws on missing required records; `catalog.get('unknown')` returns null.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] On clean install with no cached overlay → game boots to playable state using bundled baseline; no network required
- [ ] Server startup throws (fail-fast) if any required character, ability, or mode record is missing from `content-catalog.json`
- [ ] `catalog.get('unknown:id')` returns null; does not throw
- [ ] Server init step 4 (`ContentCatalogService.init()`) completes before step 9 (REST API + Socket.io accepts connections)
- [ ] All 8 characters, 18 abilities, 3 modes, 6 maps present in initial catalog JSON

---

## Implementation Notes

- `server/src/data/content-catalog.json`: static file bundled with server binary
- `ContentCatalogService.init()`: load JSON → validate required record types → build `Map<string, CatalogRecord>` → freeze map
- Validation: fail-fast (`throw new Error('CATALOG_MISSING_REQUIRED_RECORDS: ...')`) if character count < 8, ability count < 18, mode count < 3
- `catalog.get(id)`: return `map.get(id) ?? null`; never throw
- Server init order: enforce by making dependent services wait for `catalogService.ready` Promise

---

## QA Test Cases

- **AC-cold-start**: Boots without network
  - Given: Server started with no network access; valid `content-catalog.json`
  - When: Server startup sequence runs
  - Then: ContentCatalogService initialized; `catalog.get('character:vex')` returns non-null CharacterDefinition; no network calls made

- **AC-fail-fast**: Missing required record
  - Given: `content-catalog.json` has only 7 character records (missing one)
  - When: `ContentCatalogService.init()` called
  - Then: `Error` thrown with `CATALOG_MISSING_REQUIRED_RECORDS`; server exits with non-zero code; no connections accepted

- **AC-null-miss**: Unknown ID returns null
  - Given: Catalog initialized successfully
  - When: `catalog.get('character:ghost')` called (ghost not in catalog)
  - Then: Returns `null`; does not throw

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content-catalog/cold-start-bundled_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `content-catalog.json` authored with all required records
- Unlocks: Story 002 (overlay), Character System, Ability, Game Mode, Map/Arena epics
