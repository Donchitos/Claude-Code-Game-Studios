# Story 002: Scoring System

> **Epic**: Game Mode System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/game-mode.md`
**Requirement**: `TR-mode-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Kill points, assist points, and survival bonus computed in simulation phase; survival bonus at match end only.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **SC-01**: Killer receives `eliminationPoints` (10) when elimination fires
- [x] **SC-02**: Each eligible assisting player receives `assistPoints` (3) on elimination
- [x] **SC-03**: Dead players do not receive assist credit
- [x] **SC-04**: Survival bonus applied at match end, not incrementally during play
- [x] **SC-05**: Survival bonus = `floor(survivalTimeSec / 10) × 1` (default settings); player alive 73s → bonus = 7
- [x] **SC-06**: Eliminated player's survival time stops at time of elimination

---

## Implementation Notes

- `ScoreTracker` per match: `Map<playerId, { kills, assists, survivalStartTime, eliminatedAt }>`
- On elimination event: add kill to eliminator; add assist to each player in `assistantIds[]` who is alive
- Survival bonus: computed in `endMatch()`: `floor((eliminatedAt ?? matchEndTime - survivalStartTime) / 10)`
- Scores in `PlayerState` for HUD display; final scores in `MatchResultsPayload`

---

## QA Test Cases

- **SC-05**: Survival bonus formula
  - Given: Player alive for 73 seconds; survivalBonus tuning = 1 per 10s
  - When: `endMatch()` called
  - Then: `survivalBonus = floor(73/10) * 1 = 7`

- **SC-06**: Eliminated player survival time frozen
  - Given: Player eliminated at T=45s; match ends at T=300s
  - When: Survival bonus computed
  - Then: Survival time = 45s; bonus = `floor(45/10) = 4` (not `floor(300/10) = 30`)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/game-mode/scoring_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (win condition triggers scoring finalization)
- Unlocks: Story 003 (mode availability gating)
