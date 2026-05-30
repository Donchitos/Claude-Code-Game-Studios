# Story 005: Periodic Background Refresh

> **Epic**: Content Catalog
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/content-catalog.md`
**Requirement**: `TR-catalog-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: After the refresh interval elapses during an active session, client initiates background overlay fetch without blocking UI or ongoing match.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] After refresh interval elapses during active session → background overlay fetch triggered; no UI blocking; no match interruption
- [x] If background refresh succeeds with higher `overlay_version` → in-memory catalog and cached overlay both updated; downstream reads after refresh receive new values
- [x] Background refresh failures logged; game continues with current overlay; no player-facing error

---

## Implementation Notes

- `setInterval(() => catalogService.refresh(), CATALOG_REFRESH_INTERVAL_MS)` where default = 300000 (5 minutes)
- Refresh is fire-and-forget: no `await`; errors caught and logged
- `refreshInProgress` flag: if a refresh is already in progress when the interval fires, skip (same as fetch deduplication)
- After successful refresh: `applyOverlay()` called with new data; Story 002's versioning logic handles whether to apply

---

## QA Test Cases

- **AC-background-refresh**: Refresh during active session
  - Given: Match in progress; 5 minutes elapsed since last refresh
  - When: Background refresh interval fires
  - Then: `catalog.applyOverlay()` called; no impact on match state (match server snapshot frozen at match start); no client-visible interruption

- **AC-refresh-failure**: Refresh failure is silent
  - Given: Remote overlay endpoint returns 500
  - When: Background refresh fires
  - Then: Error logged; existing overlay values unchanged; game continues; no player-facing error message

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/content-catalog/background-refresh_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (overlay application)
- Unlocks: No remaining content-catalog stories
