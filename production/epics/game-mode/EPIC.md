# Epic: Game Mode System

> **Layer**: Foundation
> **GDD**: design/gdd/game-mode.md
> **Architecture Module**: Game Mode Config
> **Status**: Ready
> **Stories**: 5 stories created

## Overview

The Game Mode System defines the rules and configuration for BRAWLZONE's three game modes: `duel_1v1` (2 players, last standing wins), `squad_3v3` (6 players in 2 teams, team elimination), and `ffa_8` (8 players, last standing wins). Mode configs are loaded from the Content Catalog and expose `mode.getConfig(modeId)` to the Session Manager (for MatchConfig construction) and the Match Server (for win condition evaluation). All mode-specific rules (player count, max duration, win condition type) live here.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Content Catalog Architecture | GameModeConfig sourced from catalog; `catalog.get('mode:{id}')` | LOW |
| ADR-0003: Server-Side Game Loop | Win condition evaluated in tick Phase 3 using mode config | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0007 ✅, ADR-0003 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/game-mode.md` verified
- All 3 mode configs present and validated at startup
- Win condition triggers correctly for each mode (unit tests)
- `mode.getConfig('mode:invalid')` returns null; does not crash

## Next Step

Run `/create-stories game-mode` to break this epic into implementable stories.
