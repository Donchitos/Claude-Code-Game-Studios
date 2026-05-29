# Story 003: Mode Availability Gating & Hot Config

> **Epic**: Game Mode System
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/game-mode.md`
**Requirement**: `TR-mode-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture; ADR-0009: Matchmaking Architecture
**ADR Decision Summary**: `availableModes` list from Remote Config; hot push removes mode → dequeues all players in that mode; active matches in disabled mode continue.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **MA-01**: Queue attempt for mode not in `availableModes` → rejected with `MODE_UNAVAILABLE`
- [ ] **MA-02**: Hot push removes a mode → all queued players for that mode dequeued
- [ ] **MA-03**: Dequeued players receive `MODE_DISABLED` notification
- [ ] **MA-04**: Active matches in a disabled mode continue to completion
- [ ] **MA-05**: Event mode added to pool when `eventModeActive=true` and config exists
- [ ] **MA-06**: Event mode config missing → ERROR logged; standard modes unaffected
- [ ] **MA-07**: `matchDurationCapSec` (600) applied as hard cap on all mode durations

---

## Implementation Notes

- `GameModeService.getAvailableModes()`: reads from Remote Config `availableModes` key; defaults to all 3 modes
- On mode removal via hot push: `MatchmakingEngine.dequeueAllForMode(mode, reason: 'mode_disabled')`
- Active match not affected: `GameRoom` holds frozen config from match start; does not re-read Remote Config mid-match
- Duration cap: `effectiveMaxDurationSec = Math.min(mode.maxDurationSec, matchDurationCapSec)`

---

## QA Test Cases

- **MA-01**: Unavailable mode queue rejected
  - Given: `availableModes = ['duel_1v1']`
  - When: `POST /v1/matchmaking/queue { mode: 'squad_3v3' }`
  - Then: HTTP 400, `{ code: 'MODE_UNAVAILABLE' }`; queue not modified

- **MA-04**: Active match continues after mode disabled
  - Given: Squad 3v3 match in progress
  - When: Remote Config removes `squad_3v3` from `availableModes`
  - Then: In-progress match continues; players not disconnected; match resolves normally

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/game-mode/mode-availability-gating_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Content Catalog Story 002 (overlay/config), Matchmaking Engine epic
- Unlocks: Story 004 (timer management)
