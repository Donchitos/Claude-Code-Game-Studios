# Epic: XP & Progression

> **Layer**: Feature
> **GDD**: design/gdd/xp-progression.md
> **Architecture Module**: XP System
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

XP & Progression manages two parallel XP tracks: Player XP (gates account level 1–50+, awards cosmetic rewards and coins at level-up) and Character XP (per-character, gates ability slot 2 unlock). Both are granted via `XPSystem.grantXP()` as part of the Match Flow fan-out. Level thresholds are catalog-defined. The `slot2_unlocked` flag is set permanently in the `character_xp` table when the threshold is crossed — never recalculated from XP total. Player XP is stored in `player_profiles.xp`; character XP in the `character_xp` table.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0013: Progression & Ability Unlock Gating | Dual XP tracks; slot2_unlocked flag; xpToUnlock from catalog; DeckLoadoutValidator | LOW |
| ADR-0008: Economy Transaction Safety | XP grant idempotent; idempotency key from matchId+userId | LOW |
| ADR-0010: Match Flow Fan-Out Pattern | XPSystem.grantXP fires in allSettled fan-out | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0013 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/xp-progression.md` verified
- Level-up triggers correctly at XP threshold boundary (unit test)
- Character XP crosses threshold → `slot2_unlocked = true` (unit test)
- XP grant idempotent: same matchId+userId → second grant is no-op
- `slot2_unlocked` never resets to false after being set (invariant test)

## Next Step

Run `/create-stories xp-progression` to break this epic into implementable stories.
