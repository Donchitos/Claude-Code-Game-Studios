# Epic: Matchmaking Engine

> **Layer**: Core
> **GDD**: design/gdd/matchmaking-engine.md
> **Architecture Module**: Matchmaking Engine
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories matchmaking-engine`

## Overview

The Matchmaking Engine manages player queues for all three game modes using dual Redis sorted sets per mode (one by `queuedAt` for FIFO ordering, one by MMR for skill filtering). A bracket algorithm runs every 2 seconds, finding player clusters within `maxSkillSpreadMMR` (300, remote-configurable). Wait time widens the bracket by 50 MMR per 15 seconds. Bot backfill triggers after 45 seconds when a full human bracket cannot be formed. Atomic Lua scripts prevent double-matching. At MVP, solo queue only; party queue extends in VS when Party/Presence ships.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0009: Matchmaking Architecture | Dual Redis sorted sets; bracket algorithm; bot backfill; atomic Lua dequeue | LOW |
| ADR-0005: Database Architecture | Redis sorted set key conventions: `mm:queue:{mode}:time` and `mm:queue:{mode}:mmr` | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0009 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/matchmaking-engine.md` verified
- Two players within 300 MMR are matched within 4 seconds
- `queue_cancel` after `match_found` → player enters match (race condition test)
- Player disconnect while queuing → removed from both sorted sets
- Bot backfill triggers after 45s for FFA with <8 humans
- Lua dequeue is atomic: concurrent polls cannot double-match the same player

## Next Step

Run `/create-stories matchmaking-engine` to break this epic into implementable stories.
