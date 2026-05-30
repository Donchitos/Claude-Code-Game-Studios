# Epic: Character System

> **Layer**: Foundation
> **GDD**: design/gdd/character-system.md
> **Architecture Module**: Character System (server data + client display)
> **Status**: Ready
> **Stories**: 4/4 Complete

## Overview

The Character System owns `CharacterDefinition` validation, passive-state initialization, and per-tick passive execution. The 8 launch characters (Vex, Zook, Sera, Fen, Grim, Dash, Colt, Nyx) all have identical base stats — differentiation comes from passive abilities and ability compositions. Server-side, the Character System reads definitions from the Content Catalog and provides `char.getDefinition(id)`, `char.getInitialPassiveState(id)`, and `char.tickPassive(state, ctx)` to the Match Server. Client-side, it provides character display data (names, portraits, descriptions) for the Character Select screen and HUD.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Content Catalog Architecture | CharacterDefinition sourced from catalog; `catalog.get('character:{slug}')` | LOW |
| ADR-0013: Progression & Ability Unlock Gating | Character XP unlocks slot 2; per-character XP stored in `character_xp` table | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0007 ✅, ADR-0013 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/character-system.md` verified
- All 8 characters have valid `CharacterDefinition` in content-catalog.json
- Server startup validates all character IDs; throws on missing definition
- `tickPassive()` executes within the 20ms simulation budget for all 8 characters
- Unit tests for each character's passive ability logic

## Next Step

Run `/create-stories character-system` to break this epic into implementable stories.
