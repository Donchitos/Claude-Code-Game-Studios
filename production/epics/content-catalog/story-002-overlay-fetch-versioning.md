# Story 002: Overlay Fetch, Application & Versioning

> **Epic**: Content Catalog
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/content-catalog.md`
**Requirement**: `TR-catalog-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: Remote Config pushes numeric overlay via `catalog.applyOverlay(map)`; higher `overlay_version` wins; bundled-only fields silently ignored in overlay; remote overlay does not change IDs or structural fields.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] Remote overlay with higher `overlay_version` → applied; cached version updated
- [x] Remote overlay with equal or lower `overlay_version` → not applied (no-op)
- [x] Remote overlay field targeting a bundled-only field → silently discarded; bundled value served
- [x] `applyOverlay({ 'mm:maxSkillSpreadMMR': 300 })` → live value updates within 100ms
- [x] Malformed or partial overlay payload → discarded as a whole; cached/bundled used; no partial merge
- [x] `CATALOG_FORCE_REFRESH_ON_START = true` → startup fetch before home screen renders

---

## Implementation Notes

- `applyOverlay(map: Record<string, number | string>)`: for each key in map, look up the record by path; update only if field is in the allowed-list of remotely tunable fields; log `OVERLAY_UNKNOWN_KEY` for any key that doesn't match a known path
- Overlay application modifies in-memory values; does NOT modify the source JSON; on restart, bundle reloads and overlay re-applied from cache
- `overlay_version` comparison: `if (incomingVersion <= cachedVersion) return;`
- Fetch deduplication: if a fetch is in flight for this `overlay_version`, new triggers wait for the same Promise (not a second request)

---

## QA Test Cases

- **AC-version-update**: Higher version applied
  - Given: Cached overlay_version=1; incoming overlay has version=2
  - When: `applyOverlay()` called
  - Then: Numeric field updated in memory; `catalog.get('mode:duel_1v1').maxDurationSec` reflects new value

- **AC-version-skip**: Same or lower version skipped
  - Given: Cached overlay_version=3; incoming overlay has version=2
  - When: `applyOverlay()` called
  - Then: In-memory values unchanged; no WARN logged

- **AC-bundled-only-ignored**: Structural field in overlay discarded
  - Given: Overlay contains `{ 'character:vex.maxHp': 200 }` where maxHp is bundled-only
  - When: Applied
  - Then: `catalog.get('character:vex').maxHp` unchanged (base value); `OVERLAY_UNKNOWN_KEY` warn logged

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content-catalog/overlay-fetch-versioning_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (catalog initialized)
- Unlocks: Story 003 (record contract), Remote Config epic
