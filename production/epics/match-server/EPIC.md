# Epic: Match Server

> **Layer**: Core
> **GDD**: design/gdd/match-server.md
> **Architecture Module**: Match Server (GameRoom)
> **Status**: Ready
> **Stories**: 3/3 Complete

## Overview

Match Server (implemented as `GameRoom`) is the authoritative 20Hz game loop for a single match. Each tick (50ms) it drains the input queue, validates inputs, runs simulation (combat, status effects, passives, cooldowns), evaluates the win condition, and broadcasts `match_state` to all players in the match room. It holds all `PlayerState` in Node.js heap memory and never writes to PostgreSQL or Redis during a match. `IMatchServer` is the strict interface contract — all external code interacts through it, never directly with internal state.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Server-Side Game Loop | 20Hz tick; budget breakdown; IMatchServer interface; lag compensation formula | LOW |
| ADR-0012: Session & Match Lifecycle | Session Manager owns GameRoom lifecycle; endMatch() returns MatchResultsPayload | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0003 ✅, ADR-0012 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/match-server.md` verified
- `tick()` completes in ≤35ms under 8-player FFA (unit test with mocked I/O)
- `match_state` broadcasts at 20Hz ±2Hz (integration test)
- `getSnapshot()` returns deep-frozen state — mutation attempt throws (unit test)
- Match Server never writes to PostgreSQL or Redis during match (code review gate)

## Next Step

Run `/create-stories match-server` to break this epic into implementable stories.
