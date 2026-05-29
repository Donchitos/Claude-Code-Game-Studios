# Story 003: Record Contract — Lookup, Inactive, Not-Found

> **Epic**: Content Catalog
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/content-catalog.md`
**Requirement**: `TR-catalog-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: Canonical IDs use `{type}:{slug}` format; `catalog.get(id)` returns merged record or null; inactive records not surfaced in gameplay/shop flows but returned for entitlement checks.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Every active record has a canonical ID matching `{type}:{slug}` format (validated at startup)
- [ ] `catalog.get('character:vex')` for an active record → returns the merged record (bundled + overlay)
- [ ] `catalog.get('character:limited_skin')` for an inactive record → returns the record for history/entitlement, but it is excluded from gameplay selection, shop display, and tutorial flows
- [ ] `catalog.get('character:ghost')` (not found) → returns null; no error
- [ ] `catalog.getAll('character')` → returns all active character records as typed array
- [ ] `GET /v1/catalog` → client receives full snapshot of all records (for display)

---

## Implementation Notes

- ID format validation at startup: each record's `id` must match `/^[a-z_]+:[a-z0-9_-]+$/`; fail-fast on invalid ID
- Inactive record behavior: `catalog.get()` returns it; callers are responsible for filtering by `record.status === 'active'` for display/selection contexts
- `getAll(type)` returns `records.filter(r => r.type === type)` — includes inactive for backward compatibility; callers filter by `status` as needed
- `GET /v1/catalog` handler: return serialized map of all records with current overlay applied

---

## QA Test Cases

- **AC-id-format**: All IDs match canonical format
  - Given: Catalog initialized with 8 characters, 18 abilities, etc.
  - When: All record IDs extracted
  - Then: Every ID matches `/^[a-z_]+:[a-z0-9_-]+$/`; no spaces, no uppercase, no `brawler_*` style IDs

- **AC-inactive-excluded**: Inactive record excluded from gameplay context
  - Given: Record `character:limited` has `status: "inactive"`
  - When: Character selection screen queries available characters
  - Then: `character:limited` not in the selectable list; but `catalog.get('character:limited')` returns the record (for inventory check)

- **AC-null-miss**: Not found returns null
  - Given: Catalog fully initialized
  - When: `catalog.get('ability:nonexistent')` called
  - Then: Returns null (not undefined, not Error)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content-catalog/record-contract_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (catalog initialized)
- Unlocks: Story 004 (build validation)
