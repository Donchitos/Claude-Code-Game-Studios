# Epic: Bot / Fallback AI

> **Layer**: Core
> **GDD**: design/gdd/bot-ai.md
> **Architecture Module**: Bot AI
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

Bot AI provides fallback player slots when human matchmaking cannot fill a bracket (pre-match) or when a human player disconnects beyond the grace period (mid-match). Bots use probabilistic ability usage (not cooldown-snapping) and target the nearest or most-damaged player. Each bot's `tickBot(playerId, matchState)` is called synchronously within the Match Server's simulation phase. Bot decisions are intentionally imperfect to avoid overwhelming new players. Bot IDs use the `bot:{uuid}` format and are excluded from economy fan-out at match end.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0012: Session & Match Lifecycle | Bot assignment: `BotAI.assignBot(slot, session)` at match formation or grace period expiry | LOW |
| ADR-0003: Server-Side Game Loop | `tickBot()` called in simulation phase; must be synchronous and complete within 20ms budget | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0012 ✅, ADR-0003 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/bot-ai.md` verified
- `tickBot()` completes within 5ms per bot per tick (unit test)
- Bots use abilities probabilistically — not every frame, not never (manual QA)
- Bot players excluded from economy grant at match end (isBot flag check test)
- Bot replaces disconnected human within 30s (integration test with Disconnect Handler)

## Next Step

Run `/create-stories bot-ai` to break this epic into implementable stories.
