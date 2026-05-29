# Story 006: All 8 Passive Ability Implementations

> **Epic**: Ability / Skill System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: L
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/ability-skill.md`
**Requirement**: `TR-ability-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: `tickPassive(state, ctx)` called in simulation phase for each player; must complete within the 20ms simulation budget.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

All from GDD AC-6:
- [x] **Vex (AC-6.1)**: Hit streak (same target) increments up to 3; switch target resets; damage × 1.00/1.05/1.10/1.15 at 0/1/2/3 stacks
- [x] **Zook (AC-6.2)**: Attack from >60% of maxRange → `baseDamage × 1.20`; at/below 60% → `baseDamage × 1.00`
- [x] **Sera (AC-6.3)**: On any active ability use → heal `0.05 × maxHP`
- [x] **Fen (AC-6.4)**: On active ability use → `trickShotActiveUntil = now + 2000ms`; next basic attack in window → `baseDamage × 1.15`; proc closes window
- [x] **Grim (AC-6.5)**: Stone Skin activates once per match when `hp < 30% maxHP`; active 5s; never activates again even if HP recovers
- [x] **Dash (AC-6.6)**: On active ability use → `afterburnActiveUntil = now + 2000ms`; move speed × 1.15 in window
- [x] **Colt (AC-6.7)**: Active ability objects have lifetime × 1.20 when cast by Colt
- [x] **Nyx (AC-6.8)**: First ability cast this match → `effectiveCooldown = baseCooldown × 0.50`; subsequent: base cooldown; `openerUsed` flag not reset within match

---

## Implementation Notes

- Each character gets a `PassiveHandler` class implementing `tickPassive(playerState, matchState, ctx): void`
- `PassiveHandlerFactory`: maps `characterId` to handler; called in simulation phase
- All passive handlers must be synchronous; if computation needed: O(1) or O(players) max
- Passive state stored in `PlayerState.passiveState: Record<string, unknown>` (character-specific)
- Unit test each passive independently with mocked `PlayerState` and `MatchState`

---

## QA Test Cases

- **Vex**: Hit streak tracking
  - Given: Vex attacks same target 3 times consecutively
  - When: Damage computed on 4th hit
  - Then: Stack = 3 (capped); multiplier = 1.15; attack 5th: stack resets to 1 if target switches

- **Grim**: Stone Skin once per match
  - Given: Grim at 40% HP; drops to 25% HP
  - When: `tickPassive()` runs
  - Then: Stone Skin activates; `stoneSkinUsed = true`; HP drops to 10% later → Stone Skin does NOT activate again

- **Nyx**: Opener CDR applies once
  - Given: Nyx at match start; `openerUsed = false`
  - When: First ability cast
  - Then: `effectiveCooldown = baseCooldown * 0.50`; `openerUsed = true`; second cast uses `baseCooldown`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ability-skill/passive-abilities_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (execution pipeline), Character System Story 001 (roster)
- Unlocks: Story 007 (edge cases)
