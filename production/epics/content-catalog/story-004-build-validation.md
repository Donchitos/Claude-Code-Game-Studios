# Story 004: Build-Time Catalog Validation

> **Epic**: Content Catalog
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/content-catalog.md`
**Requirement**: `TR-catalog-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: `content-catalog.json` build fails if any two records share the same canonical ID, or if any record field violates the allow-list schema.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] Bundled catalog build fails if any two records share the same canonical ID
- [x] Bundled catalog build fails if any record field violates the allow-list schema
- [x] CI script confirms all GDD-referenced IDs exist in `content-catalog.json`
- [x] A fetched overlay with malformed or partial payload is discarded as a whole; no partial merge applied

---

## Implementation Notes

- Build validation script: `tools/validate-catalog.ts` — run as npm script `npm run validate:catalog` and in CI
- Duplicate ID check: load all records into a `Set`; if any ID appears twice → exit 1 with error message listing duplicates
- Schema validation: use Zod schemas for each record type; validate every record in the JSON
- CI integration: add `validate:catalog` to the CI pipeline before server build

---

## QA Test Cases

- **AC-duplicate-id**: Duplicate ID build failure
  - Given: `content-catalog.json` has two entries with `id: "character:vex"`
  - When: `npm run validate:catalog`
  - Then: Exit code 1; error message lists `character:vex` as duplicate; CI build fails

- **AC-schema-violation**: Invalid field fails build
  - Given: `content-catalog.json` has a character with `maxHp: "one hundred"` (string instead of number)
  - When: `npm run validate:catalog`
  - Then: Exit code 1; Zod error message identifies field and type mismatch

- **AC-malformed-overlay**: Partial overlay discarded
  - Given: Overlay JSON is truncated (invalid JSON)
  - When: Server attempts to apply overlay
  - Then: `JSON.parse()` throws; entire overlay discarded; bundled/cached values used; `OVERLAY_PARSE_ERROR` logged

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: `production/qa/smoke-2026-05-29.md` — pass on `npm run validate:catalog`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (catalog JSON exists), Story 002 (overlay apply mechanism)
- Unlocks: Story 005 (background refresh)
