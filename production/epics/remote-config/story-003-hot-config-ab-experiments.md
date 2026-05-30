# Story 003: Hot Config Push & A/B Experiments

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

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol; ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: `config_update` Socket.io event triggers hot update for Hot keys within `hotPushDebounceMs`; Cold keys ignored; A/B bucket assignments stable across sessions.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure TypeScript with injected adapters. No game engine API involved.

---

## Acceptance Criteria

- [x] `config_update` event with valid Hot keys → active config updated within `hotPushDebounceMs + 50ms`
- [x] `config_update` includes a Cold key → that key's value not updated; `hot_push_cold_key_ignored` warn logged
- [x] `config_update` includes type-mismatched value → key not updated; `hot_push_type_mismatch` warn logged
- [x] `server.maintenanceModeEnabled=true` via hot push → maintenance banner appears within `hotPushDebounceMs + 50ms`; queue entry points disabled
- [x] A/B experiment bucket stable: same `userId` gets same bucket across 10 consecutive app launches
- [x] A/B assignment doesn't change mid-session even if server allocation changes

---

## Implementation Notes

- Hot push handler: `socket.on('config_update', (updates) => { debounce(applyHotUpdates, hotPushDebounceMs)(updates) })`
- Cold key detection: check against key registry for `Hot` vs `Cold` classification; if Cold: log warn, skip
- Type mismatch: validate type of incoming value against expected type from registry; if mismatch: log warn, skip
- A/B bucket assignment: `userId` hashed to consistent bucket; stored in AsyncStorage; not re-randomized per session
- Experiment assignment read by `configService.get()` with userId context

---

## QA Test Cases

- **AC-hot-cold**: Cold key ignored in hot push
  - Given: `config_update { 'system.coldStartSetting': 'new_value' }` where `coldStartSetting` is Cold
  - When: Handler processes
  - Then: `configService.get('system.coldStartSetting')` unchanged; `WARN hot_push_cold_key_ignored` logged

- **AC-ab-stable**: A/B bucket stable across launches
  - Given: `userId = 'abc123'` enrolled in `mmrKFactor` experiment
  - When: App launched 10 consecutive times (tested via config mock)
  - Then: `configService.get('matchmaking.mmrKFactorProvisional', { userId })` returns same value each launch

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/remote-config/hot-config-ab_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Real-time Transport Story 001 (socket connection for config_update event)
- Unlocks: Story 004 (isolation & performance)
