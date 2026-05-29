# Story 004: Match Timer Management

> **Epic**: Game Mode System
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/game-mode.md`
**Requirement**: `TR-mode-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Timer counts down from `effectiveMaxDurationSec` at 20Hz; present in every `state_snapshot`; triggers win condition evaluation at `timerRemainingMs = 0`.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **TM-01**: Timer state present in every `state_snapshot` payload as `timerRemainingMs`
- [ ] **TM-02**: Timer counts down from `effectiveMaxDurationSec` at 20Hz (−50ms per tick)
- [ ] **TM-03**: At `timerRemainingMs = 0` → `WinConditionEvaluator` called with timeout trigger
- [ ] **TM-04**: Timer does NOT pause when a player disconnects

---

## Implementation Notes

- `matchState.timerRemainingMs` initialized to `effectiveMaxDurationSec * 1000` at match start
- Each tick: `timerRemainingMs -= 50`; included in every `state_snapshot` and `state_delta`
- At `timerRemainingMs <= 0`: call `winConditionEvaluator.evaluate(state, 'timeout')` → if result: `endMatch()`
- Disconnect: `timerRemainingMs` countdown continues regardless of player connection status

---

## QA Test Cases

- **TM-02**: 1s countdown
  - Given: Match initialized with `effectiveMaxDurationSec = 10` (10000ms); 20 ticks advanced (1 second)
  - When: Tick 20 processed
  - Then: `timerRemainingMs === 9000` (started at 10000, decremented 20 × 50ms)

- **TM-03**: Win condition called at zero
  - Given: `timerRemainingMs = 50` (1 tick remaining)
  - When: Next tick processed
  - Then: `timerRemainingMs = 0`; `WinConditionEvaluator.evaluate()` called; if result non-null: `endMatch('timeout')`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/game-mode/timer-management_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (win condition evaluator)
- Unlocks: Story 005 (edge cases)
