# Epic: Reconnect / Resume System

> **Layer**: Core
> **GDD**: design/gdd/reconnect-resume.md
> **Architecture Module**: Reconnect / Resume
> **Status**: Ready
> **Stories**: 2/2 Complete

## Overview

The Reconnect / Resume System handles the re-entry of a previously-disconnected player into an active match. When a player reconnects within the grace period, the server joins their new socket to the match room, calls `matchServer.onPlayerReconnected(playerId)` to restore `isActive = true`, and emits `reconnect_ack` with the current frozen `MatchSnapshot` and `isConfirmed: boolean` (true if character selection is complete). The client uses the snapshot to restore its match state buffer and resumes rendering immediately. No event replay — snapshot-only restore.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0012: Session & Match Lifecycle | onPlayerReconnect flow; reconnect_ack with isConfirmed; socket room re-join | LOW |
| ADR-0002: Real-Time Transport Protocol | reconnect_ack socket event; snapshot payload | LOW |
| ADR-0003: Server-Side Game Loop | getSnapshot() provides frozen state for reconnect_ack | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0012 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/reconnect-resume.md` verified
- Player reconnects at any point in match → receives `reconnect_ack` within 500ms
- `isConfirmed: true` sent when match is in `active` state; `false` in `character_select`
- Snapshot restores correct player positions, HP, and status effects (integration test)
- No event replay — only snapshot (architecture invariant, code review gate)

## Next Step

Run `/create-stories reconnect-resume` to break this epic into implementable stories.
