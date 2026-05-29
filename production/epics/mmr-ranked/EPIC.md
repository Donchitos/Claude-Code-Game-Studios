# Epic: MMR / Ranked System

> **Layer**: Feature
> **GDD**: design/gdd/mmr-ranked.md
> **Architecture Module**: MMR / Ranked
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories mmr-ranked`

## Overview

The MMR / Ranked System updates player skill ratings after every match using an Elo-variant formula. It fires synchronously as the first phase of the Match Flow fan-out with a 3000ms timeout (timeout → mmrDelta=0 for all players → proceed). `mmrDeltas` are included in the `match_end` payload so the client can display rank changes immediately. MMR is stored in `player_profiles.mmr`. The matchmaking engine reads MMR at queue time for bracket formation. Separate MMR per game mode is a post-MVP consideration; at MVP, a single global MMR is used.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0010: Match Flow Fan-Out Pattern | MMR fires as synchronous Phase 1 of fan-out; 3000ms timeout | LOW |
| ADR-0005: Database Architecture | MMR stored in player_profiles; no separate table at MVP | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0010 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/mmr-ranked.md` verified
- MMR update formula unit tested for win/loss/draw scenarios
- MMR timeout (>3000ms) → all mmrDeltas = 0, match_end still fires (integration test)
- `mmrDeltas` present in match_end for all players including bots (bots always delta=0)
- Matchmaking engine reads updated MMR correctly after first match

## Next Step

Run `/create-stories mmr-ranked` to break this epic into implementable stories.
