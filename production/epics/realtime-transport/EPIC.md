# Epic: Real-time Transport

> **Layer**: Foundation
> **GDD**: design/gdd/realtime-transport.md
> **Architecture Module**: Socket.io Server (Foundation) + Socket.io Client (Core)
> **Status**: Ready
> **Stories**: 9 stories created

## Overview

Real-time Transport implements the Socket.io v4 connection layer between the React Native client and the Node.js game server. This includes the server-side Socket.io initialization (WebSocket-only, no polling), JWT authentication middleware on connect, per-user and per-match room management, the 5-second unauthenticated disconnect timer, and the client-side connection lifecycle (connect, reconnect, event routing). All real-time events — match state, matchmaking signals, economy push notifications — flow through this transport layer.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Real-Time Transport Protocol | Socket.io v4; WebSocket-only; fire-and-forget match_state; full event contract defined | LOW |
| ADR-0004: Authentication Architecture | JWT middleware on socket connect; userId attached to socket.data | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0002 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/realtime-transport.md` verified
- Unauthenticated socket disconnected within 5 seconds
- `match_state` delivered at 20Hz ±2Hz in 8-player match
- `match_found` + immediate `queue_cancel` → player enters match (race condition prevented)
- Player reconnects within 30s → `reconnect_ack` received with snapshot

## Next Step

Run `/create-stories realtime-transport` to break this epic into implementable stories.
