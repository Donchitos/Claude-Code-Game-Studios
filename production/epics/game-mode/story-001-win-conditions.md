# Story 001: Win Conditions — All Three Modes

> **Epic**: Game Mode System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/game-mode.md`
**Requirement**: `TR-mode-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop; ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: Win condition evaluated in tick Phase 3; mode config from catalog defines win conditions; `endMatch(reason)` called when triggered.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **WC-01**: 1v1 Duel — one player eliminated → alive player wins immediately
- [x] **WC-02**: 1v1 Duel — both eliminated same tick → draw
- [x] **WC-03**: 1v1 Duel timer expiry → player with higher HP% wins
- [x] **WC-04**: 1v1 Duel timer expiry, equal HP% (2dp) → draw
- [x] **WC-05**: 3v3 Squad Brawl — all 3 players on one team eliminated → other team wins
- [x] **WC-06**: 3v3 timer expiry → team with more survivors wins
- [x] **WC-07**: 3v3 timer expiry, equal survivors → team with higher total HP% wins
- [x] **WC-08**: 3v3 timer expiry, equal survivors and equal HP% → draw
- [x] **WC-09**: FFA — only one player remaining → winner declared immediately
- [x] **WC-10**: FFA timer expiry, multiple alive → highest total score wins
- [x] **WC-11**: FFA timer expiry, tied scores among alive → draw

---

## Implementation Notes

- `WinConditionEvaluator.evaluate(matchState, mode)` called in tick Phase 3
- Returns `WinResult | null`; null = match continues
- HP percentage comparison: `Math.round(player.hp / player.maxHp * 100) / 100` (2dp)
- FFA score: `kills * 10 + assists * 3 + survivalBonus`; computed from match state
- Both-eliminated same tick: `mode === 'duel_1v1'` and `alivePlayers.length === 0` → draw

---

## QA Test Cases

- **WC-01**: 1v1 — elimination win
  - Given: `mode = 'duel_1v1'`; player B hp → 0
  - When: `evaluate()` called
  - Then: Returns `WinResult { winner: playerA, reason: 'elimination' }`

- **WC-03**: 1v1 — timer expiry HP comparison
  - Given: `timerRemainingMs = 0`; playerA `hp = 60/100`; playerB `hp = 40/100`
  - When: `evaluate()` called
  - Then: Returns `WinResult { winner: playerA, reason: 'timeout' }`

- **WC-09**: FFA — last standing
  - Given: `mode = 'ffa_8'`; 7 players eliminated; 1 alive
  - When: `evaluate()` called
  - Then: Returns `WinResult { winner: lastAlivePlayer, reason: 'last_standing' }`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/game-mode/win-conditions_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Content Catalog Story 001 (mode configs), Match Server epic
- Unlocks: Story 002 (scoring)
