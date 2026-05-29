# Story 001: Launch Behavior — Cold/Warm Start

> **Epic**: Remote Config
> **Status**: Complete
> **Layer**: Foundation (Ops)
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/remote-config.md`
**Requirement**: `TR-ops-???` *(pending `/architecture-review`)*

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: `CATALOG_FORCE_REFRESH_ON_START=true` blocks home screen until fetch resolves; fallback to cached values; hardcoded defaults if no cache.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure TypeScript with injected adapters. No game engine API involved.

---

## Acceptance Criteria

- [x] `CATALOG_FORCE_REFRESH_ON_START=true` + reachable config server → main menu does not render until successful config response parsed and stored
- [x] First launch with unreachable server + no cache → falls back to hardcoded defaults; renders main menu without crashing; all gameplay systems initialize without runtime errors
- [x] Launch with existing AsyncStorage cache + unreachable server → uses cached values; main menu renders; cached values are active config values read by downstream systems
- [x] Existing cache with `schema_version` lower than `CLIENT_SCHEMA_VERSION` → cache discarded; hardcoded defaults used

---

## Implementation Notes

- `RemoteConfigService.init()`: called at app startup (before Main Menu renders)
  - If `FORCE_REFRESH`: await fetch with timeout; on success: update cache + apply; on failure: use cache or defaults
  - If no FORCE_REFRESH: apply cached values immediately; fetch in background
- `AsyncStorage.getItem('remote_config')` for cache; schema_version comparison before applying
- Hardcoded defaults: TypeScript constants in `src/config/defaults.ts`; all keys must have non-null defaults

---

## QA Test Cases

- **AC-cold-start**: First launch, no network, no cache
  - Given: Clean install; network blocked; no AsyncStorage cache
  - When: App starts
  - Then: `RemoteConfigService.init()` completes using hardcoded defaults; main menu renders; no crash; `configService.get('matchmaking.maxSkillSpreadMMR')` returns hardcoded value (300)

- **AC-cache-schema-version**: Stale cache discarded
  - Given: AsyncStorage has config with `schema_version: 1`; `CLIENT_SCHEMA_VERSION = 2`
  - When: App starts
  - Then: Cache discarded; hardcoded defaults used; stale cache not applied

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/remote-config/launch-behavior_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Content Catalog Story 002 (applyOverlay uses remote config data)
- Unlocks: Story 002 (version compatibility)
