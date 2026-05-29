# Story 005: Game Mode Edge Cases

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

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop; ADR-0012: Session & Match Lifecycle
**ADR Decision Summary**: Simultaneous FFA elimination → draw; disconnects don't force-balance; missing event mode config → no server error propagation.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **EC-01**: FFA simultaneous final elimination → draw result; all players get draw MMR delta
- [ ] **EC-02**: 3v3 with 2 disconnects on one team → match continues; no force-balance
- [ ] **EC-03**: FFA timer expiry with exactly 1 alive → winner (not draw); `result = 'timeout'`
- [ ] **EC-04**: Event mode config missing → mode unavailable; ERROR logged; no exception propagates to callers

---

## Implementation Notes

- Simultaneous elimination: both players reach `hp = 0` in same tick → `alivePlayers.length === 0` → draw result
- 3v3 disconnects: disconnected players have `isActive = false`; match engine counts them as alive (bot takes over); no re-balancing
- EC-03: `aliveCount = 1` at `timerRemainingMs = 0` → single winner declared, `reason = 'timeout'` (not `last_standing`)
- EC-04: `try { catalog.get('mode:event_mode') } catch(e) { logger.error(...); return null }` — callers handle null gracefully

---

## QA Test Cases

- **EC-01**: Simultaneous FFA elimination
  - Given: FFA; 2 players remain; both `hp` hit 0 in same tick
  - When: `WinConditionEvaluator.evaluate()` called
  - Then: Returns `WinResult { winner: null, reason: 'draw' }`; MMR delta = 0 for all

- **EC-04**: Missing event mode config — no crash
  - Given: `eventModeActive = true`; `catalog.get('mode:seasonal_event')` returns null
  - When: Mode availability computed
  - Then: Event mode absent from pool; `ERROR` log with mode ID; standard modes unaffected; no uncaught exception

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/game-mode/edge-cases_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (win conditions), Story 002 (scoring)
- Unlocks: No remaining game-mode stories
