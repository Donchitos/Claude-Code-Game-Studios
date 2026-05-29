# Story 004: Downstream System Isolation & Performance

> **Epic**: Remote Config
> **Status**: Ready
> **Layer**: Foundation (Ops)
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/remote-config.md`
**Requirement**: `TR-ops-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: All config keys have hardcoded defaults; `configService.get(key)` is synchronous and sub-1ms; unlisted keys are a build-time lint error.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] All config keys in registry have hardcoded default values; no key has `undefined` or `null` default
- [ ] Every downstream system in GDD §6.2 initializes successfully using hardcoded defaults alone (config server blocked, no cache)
- [ ] No downstream system reads a config key not listed in registry; unlisted keys = build-time lint error
- [ ] Config fetch, parse, and AsyncStorage write completes within 200ms on fast connection
- [ ] `configService.get(key)` completes in under 1ms (synchronous in-memory read)

---

## Implementation Notes

- Registry: `src/config/registry.ts` — typed map of `key → { type, default, tier: 'Hot'|'Cold', description }`
- Lint rule (ESLint custom rule or build-time check): scan all `configService.get('...')` calls; fail build if key not in registry
- `configService.get(key)`: synchronous `Map.get(key)` from in-memory config; falls back to registry default if not in active config
- Performance test: `configService.get()` called 10,000 times in a loop; total must be <10,000ms (1ms per call)

---

## QA Test Cases

- **AC-defaults**: All downstream systems initialize with hardcoded defaults
  - Given: Config server unreachable; no AsyncStorage cache
  - When: App starts and all services initialize
  - Then: No `undefined` or `null` values returned from `configService.get()` for any registered key; no runtime errors during init

- **AC-performance**: Sub-1ms get()
  - Given: Config service initialized (warm)
  - When: `configService.get('matchmaking.maxSkillSpreadMMR')` called 1000 times
  - Then: Total time < 1000ms (1ms per call ceiling); verified via `performance.now()` in benchmark test

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/remote-config/isolation-performance_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (config service infrastructure)
- Unlocks: No remaining remote-config stories
