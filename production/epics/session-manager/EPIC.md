# Epic: Session Manager

> **Layer**: Core
> **GDD**: design/gdd/session-manager.md
> **Architecture Module**: Session Manager
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories session-manager`

## Overview

Session Manager is the orchestrator of the match lifecycle. It maintains a `Map<matchId, GameSession>` and drives each session through a five-state machine: `forming → character_select → active → ended → destroyed`. It receives match formations from the Matchmaking Engine, coordinates character selection (30-second timeout with default assignment), instantiates `GameRoom` (Match Server) for active matches, delegates disconnects to the Disconnect Handler, and passes `endMatch()` output to Match Flow. Session Manager also manages Socket.io room membership for each match.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0012: Session & Match Lifecycle | Full state machine, createSession/destroySession, bot backfill, reconnect flow | LOW |
| ADR-0002: Real-Time Transport Protocol | Socket room management (match:{matchId}) done by Session Manager | LOW |
| ADR-0003: Server-Side Game Loop | Session Manager instantiates GameRoom and starts tick loop | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0012 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/session-manager.md` verified
- Session transitions through all 5 states in order (no skips) — unit test
- Character select timeout assigns default character and starts match
- Session destroyed after match end; no memory leak after 100 matches (heap profile)
- `RECONNECT_GRACE_PERIOD_S` = `RECONNECT_WINDOW_S` invariant enforced in code

## Next Step

Run `/create-stories session-manager` to break this epic into implementable stories.
