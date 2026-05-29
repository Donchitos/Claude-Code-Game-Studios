# Epic: Character / Deck Select

> **Layer**: Presentation
> **GDD**: design/gdd/character-deck-select.md
> **Architecture Module**: Character / Deck Select (Presentation) + Loadout Builder UI (Feature client)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories character-deck-select`

## Overview

Character / Deck Select is the pre-match screen where players choose their character and configure their 2-ability deck. It shows all owned characters, the equipped skin, available abilities per character (with slot 2 locked if XP threshold not met), and the current deck configuration. Players tap to confirm with `character_confirmed` socket event. A 30-second countdown timer is displayed; expired → server assigns default character. The screen subscribes to `character_selected` events from other players to show their selections in real time (in squad modes). `validation_error` responses update the UI immediately.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0013: Progression & Ability Unlock Gating | Slot 2 locked display based on character_xp; validation_error codes | LOW |
| ADR-0006: Client State Management | InventoryStore provides owned characters; ProfileStore provides character XP | LOW |
| ADR-0012: Session & Match Lifecycle | 30-second character select timeout; default character on expiry | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0013 ✅, ADR-0006 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/character-deck-select.md` verified
- Slot 2 shows lock icon for characters below XP threshold (visual QA)
- `character_confirmed` with locked slot 2 → `SLOT2_LOCKED` validation error shown
- 30-second timer counts down correctly; default assignment happens server-side on expiry
- Other players' selections update in real time via `character_selected` events
- Screen handles safe area insets on iOS and Android

## Next Step

Run `/create-stories character-deck-select` to break this epic into implementable stories.
