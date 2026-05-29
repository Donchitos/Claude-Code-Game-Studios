# Epic: Cosmetic / Skin System

> **Layer**: Feature
> **GDD**: design/gdd/cosmetic-skin.md
> **Architecture Module**: Cosmetic / Skin System
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories cosmetic-skin`

## Overview

The Cosmetic / Skin System manages visual customization for characters. Each character has a default skin (free) and optional premium skins (purchased via diamonds). Equipped skins are stored in `player_profiles.equipped_skins` as a map of `characterId → skinId`. Players change equipped skins via `PATCH /v1/profile/equipped-skins`. Skin ownership is enforced by the Inventory system — the server validates the player owns the skin before saving the equipped selection. The client renders the equipped skin in the character select screen and match HUD.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Economy Transaction Safety | Skin grants via grantItem (idempotent) | LOW |
| ADR-0007: Content Catalog Architecture | Skin definitions in catalog (`type: 'cosmetic'`) | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0008 ✅, ADR-0007 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/cosmetic-skin.md` verified
- Player can equip owned skin; equipped skin persists across sessions
- Equipping unowned skin → 403 returned; no DB write
- Default skin pre-equipped for all characters on new account
- Equipped skin renders correctly in character select and HUD (visual QA)

## Next Step

Run `/create-stories cosmetic-skin` to break this epic into implementable stories.
