# Epic: Deck / Loadout System

> **Layer**: Core
> **GDD**: design/gdd/deck-loadout.md
> **Architecture Module**: Deck / Loadout Validator (server) + Loadout Builder UI (client)
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

The Deck / Loadout System is BRAWLZONE's primary strategic differentiator — the "Ludus" in the Brawl Stars × Ludus hybrid identity. Players construct a 2-ability deck per character before each match. Server-side, the Deck/Loadout Validator enforces: character ownership, ability existence in catalog, slot 2 XP unlock gate, and correct slot count (exactly 2). Invalid loadouts are rejected at `character_confirmed` with a typed error code. Client-side, the Loadout Builder UI shows owned characters, their available abilities, and the unlock state for each slot. Decks are saved per-character via `POST /v1/loadout/:characterId`.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0013: Progression & Ability Unlock Gating | Slot 2 locked until character XP threshold; DeckLoadoutValidator enforces at character_confirmed | LOW |
| ADR-0007: Content Catalog Architecture | Ability IDs validated against catalog; `catalog.get(abilityId)` | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0013 ✅, ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/deck-loadout.md` verified
- Player with 0 char XP cannot equip slot 2 ability — `SLOT2_LOCKED` returned
- Player with sufficient char XP can equip slot 2 ability — accepted
- Unknown ability ID in slot → `ABILITY_NOT_FOUND` returned
- Saved loadouts persist across sessions (integration test)
- Client shows lock icon on slot 2 for characters below XP threshold

## Next Step

Run `/create-stories deck-loadout` to break this epic into implementable stories.
