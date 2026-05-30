# Story 003: Balance Overlay Application & Clamping

> **Epic**: Character System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/character-system.md`
**Requirement**: `TR-char-???`

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: Remote Config overlay can tune character stats as multipliers; clamped to [0.5, 1.5] (OVERLAY_MIN/MAX); unknown character IDs in overlay ignored; overlays not re-applied mid-match.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-OVERLAY-001**: Vex `attack_damage` overlay = 1.10; base = 10 → `effective_attack_damage = 11.0` at match init
- [x] **AC-OVERLAY-002**: No overlay for Grim → all effective_stats equal base values exactly
- [x] **AC-OVERLAY-003**: Dash `move_speed` overlay = 2.0 (exceeds OVERLAY_MAX 1.5) → clamped to 1.5; `effective_move_speed = base * 1.5`; `OVERLAY_CLAMP_WARNING` logged
- [x] **AC-OVERLAY-004**: Colt `attack_damage` overlay = 0.0 (below OVERLAY_MIN 0.5) → clamped to 0.5; `OVERLAY_CLAMP_WARNING` logged
- [x] **AC-OVERLAY-005**: Overlay for unknown `character:ghost` → silently dropped; `OVERLAY_UNKNOWN_CHARACTER` warning logged; no existing character affected
- [x] **AC-OVERLAY-006**: Overlay updated mid-match → existing match's stats unchanged; new overlay applies only to subsequently initialized matches

---

## Implementation Notes

- `CharacterRuntimeInstance` created at match init by applying `effectiveStats = baseStat * clamp(overlay_multiplier, OVERLAY_MIN, OVERLAY_MAX)` for each overlayable stat
- Match Server holds `CharacterRuntimeInstance`s frozen at match start; Remote Config updates cannot mutate live match state
- `clamp(v, min, max)`: `Math.max(min, Math.min(max, v))`
- `OVERLAY_MIN = 0.5`, `OVERLAY_MAX = 1.5` constants

---

## QA Test Cases

- **AC-OVERLAY-001**: Correct multiplier applied
  - Given: `catalog.applyOverlay({ 'character:vex.attack_damage': 1.10 })`; Vex base `attack_damage = 10`
  - When: Match initialized with Vex
  - Then: `CharacterRuntimeInstance.effectiveStats.attack_damage === 11.0`

- **AC-OVERLAY-003**: Over-max clamped
  - Given: Overlay `{ 'character:dash.move_speed': 2.0 }`; base `move_speed = 5.0`; `OVERLAY_MAX = 1.5`
  - When: Match initialized with Dash
  - Then: `effectiveStats.move_speed === 7.5` (5.0 * 1.5); `OVERLAY_CLAMP_WARNING` in logs

- **AC-OVERLAY-006**: Mid-match overlay update doesn't affect live match
  - Given: Match active; Vex has `effectiveStats.attack_damage = 11.0`
  - When: Remote Config pushes new overlay with Vex damage 0.9
  - Then: Live match still uses 11.0; next match initialization uses new overlay

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/character-system/balance-overlay_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (roster), Content Catalog Story 002 (overlay mechanism)
- Unlocks: Story 004 (selection validation)
