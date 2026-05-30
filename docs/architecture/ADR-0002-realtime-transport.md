# ADR-0002: Real-Time Transport Protocol (Socket.io v4)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Network Programmer

## Summary

BRAWLZONE uses Socket.io v4 for all real-time client-server communication, including matchmaking events, match state broadcasts, and economy push notifications. Match state is sent fire-and-forget at 20Hz; no per-packet acknowledgment is used in the hot path. This ADR defines the connection lifecycle, room model, authentication middleware, and all event contracts.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Networking |
| **Knowledge Risk** | LOW — Socket.io v4 is within training data |
| **References Consulted** | `design/gdd/realtime-transport.md`, `design/gdd/disconnect-handler.md`, `design/gdd/reconnect-resume.md`, `docs/engine-reference/react-native/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm socket.io-client v4 React Native compatibility with current Expo SDK |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (client-server architecture), ADR-0004 (JWT validation middleware) |
| **Enables** | ADR-0003, ADR-0006, ADR-0009, ADR-0012 |
| **Blocks** | Match Server broadcast, Matchmaking event delivery, profile:refresh push |
| **Ordering Note** | Socket event contracts defined here are the interface between all server-side systems and the client; must be Accepted before any socket handler is written |

## Context

### Problem Statement

A 20Hz server-authoritative match loop needs to push state to 8 simultaneous players with ≤200ms perceived latency. Additionally, out-of-match events (matchmaking, economy updates, push notifications) must be delivered reliably over the same connection to avoid maintaining multiple persistent connections on a mobile device.

### Current State

`server/src/socket/index.ts` and `mobile/services/socket.ts` are scaffolded. No event handlers are implemented.

### Constraints

- React Native requires WebSocket transport (no long-polling fallback at production scale)
- Mobile connections are unreliable — disconnect/reconnect handling is mandatory
- Single persistent connection per player (battery/network efficiency)
- JWT authentication required before any game event is processed

### Requirements

- 20Hz match state broadcast to all players in a match room
- Fire-and-forget for `match_state` (UDP semantics over WebSocket) — no ack in hot path
- Reliable delivery for `match_end`, `match_found`, `profile:refresh` (acknowledgment or retry)
- `authenticate` event must be the first event; unauthenticated sockets disconnected at 5s
- Server emits `reconnect_ack` with snapshot on player reconnect within grace period
- `match_found` always beats `queue_cancel` — race condition prevention

## Decision

Use **Socket.io v4** with WebSocket transport only (polling disabled). One server-side Socket.io namespace (`/`). Rooms used for match isolation. JWT validation via Socket.io middleware on connection.

### Architecture

```
MOBILE CLIENT                    SOCKET.IO SERVER (Node.js)
  │                                     │
  │ connect({ auth: { token: jwt } })   │
  ├────────────────────────────────────→│ middleware: validateToken(jwt)
  │                                     │ socket.data.userId = userId
  │                                     │ setTimeout(disconnect, 5000) if no authenticate
  │←── connected ───────────────────────│
  │                                     │
  │ MATCH LOOP (every 50ms):            │
  │ emit BASIC_ATTACK / USE_ABILITY ────→│ Match Server: queue input
  │←── match_state (tick, players[]) ───│ Match Server: broadcast tick
  │                                     │
  │ MATCH END:                          │
  │←── match_end ({ results, deltas }) ─│ Match Flow: after fan-out initiated
  │                                     │
  │ ECONOMY PUSH:                       │
  │←── profile:refresh ({ profile }) ───│ Any profile-mutating system
  │←── inventory:updated ({ items }) ───│ Inventory Service
  │                                     │
  │ DISCONNECT:                         │
  │ [connection dropped]                │ Disconnect Handler: RECONNECT_GRACE_PERIOD_S timer
  │ [reconnects within grace period]    │
  │ emit authenticate { jwt }           │
  │←── reconnect_ack ({ snapshot, isConfirmed }) │

ROOMS:
  match:{matchId}   — all players in an active match; broadcast match_state here
  user:{userId}     — single-player room for push notifications; player joins on authenticate
```

### Key Interfaces

```typescript
// All Socket.io events (canonical contract)
// CLIENT → SERVER
interface ClientEvents {
  authenticate:        (data: { jwt: string }) => void;
  queue_join:          (data: { mode: 'duel_1v1' | 'squad_3v3' | 'ffa_8' }) => void;
  queue_cancel:        () => void;
  character_confirmed: (data: { characterId: string; deckSlots: [string, string] }) => void;
  BASIC_ATTACK:        (data: { targetPlayerId?: string; aimVector?: Vector2 }) => void;
  USE_ABILITY:         (data: { slotIndex: 0 | 1; targetPlayerId?: string; aimVector?: Vector2 }) => void;
}

// SERVER → CLIENT
interface ServerEvents {
  match_found:        (data: { matchId: string; gameMode: GameMode; players: PlayerStub[]; expiresAt: number }) => void;
  dequeued:           (data: { reason: 'match_found' | 'player_cancelled' | 'timeout' | 'queue_error' }) => void;
  match_state:        (data: { tick: number; timestamp: number; players: PlayerState[]; projectiles: ProjectileState[] }) => void;
  match_end:          (data: { matchId: string; results: PlayerResult[]; mmrDeltas: MMRDelta[] }) => void;
  character_selected: (data: { playerId: string; characterId: string }) => void;
  'profile:refresh':  (data: { profile: PlayerProfile }) => void;
  'inventory:updated':(data: { entitlements: EntitlementList }) => void;
  auth_error:         (data: { reason: TokenErrorReason }) => void;
  reconnect_ack:      (data: { snapshot: MatchSnapshot; isConfirmed: boolean }) => void;
}
```

### Implementation Guidelines

- Disable polling transport: `transports: ['websocket']` on both client and server
- `match_state` uses `io.to(matchRoomId).emit()` — no individual ack; stale frames dropped by client
- `match_end` and `profile:refresh` use `socket.to(userRoomId).emit()` targeting the per-user room
- `match_found` sets a boolean flag `matchFoundSent: true` on the socket; `queue_cancel` handler checks this flag and no-ops if set — prevents race condition
- Lag compensation: client timestamps all inputs; server rewinds up to `floor(min(rtt, 200) / 50)` ticks for hit detection

## Alternatives Considered

### Alternative 1: Raw WebSocket + Custom Protocol

- **Description**: Use Node.js `ws` library with a custom binary protocol.
- **Pros**: Lower overhead; full control over serialization; slightly lower latency.
- **Cons**: No room abstractions, no reconnect handling, no transport fallback negotiation; everything must be reimplemented.
- **Rejection Reason**: Socket.io's room model maps exactly to the match room architecture; the reconnect and multiplexing features save significant implementation work.

### Alternative 2: WebRTC Data Channels

- **Description**: Peer-to-peer data channels for match state.
- **Pros**: True UDP semantics; lowest possible latency.
- **Cons**: NAT traversal on mobile is unreliable; no server authority over game state; TURN server cost.
- **Rejection Reason**: Server-authoritative requirement eliminates P2P approaches.

## Consequences

### Positive

- Socket.io rooms provide clean match isolation with one-line broadcast
- Built-in connection state machine simplifies disconnect/reconnect handling
- Same connection carries both match and economy events — no second persistent connection

### Negative

- Socket.io adds ~30KB to client bundle
- WebSocket-only disables long-polling fallback — players on very restrictive networks (some corporate WiFi) cannot play
- Fire-and-forget `match_state` means clients must tolerate occasional dropped frames

### Neutral

- All events are JSON-serialized; binary serialization (msgpack) can be added later if bandwidth becomes a concern

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Socket.io v4 incompatibility with future Expo SDK | Low | Medium | Pin `socket.io-client` version; test on upgrade |
| match_state broadcast exceeds 50ms frame budget | Medium | High | Profile broadcast size; cap at 8 players; profile packet size per tick |
| Mobile background app → socket disconnect | High | Low | Disconnect Handler grace period (30s) covers normal app-switch scenarios |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| match_state packet size | — | ≤1.5KB/tick | — |
| Broadcast latency (server emit → client receive) | — | ≤50ms p95 | — |
| Socket connect time | — | ≤200ms | — |
| Concurrent sockets per server | — | ≤500 | — |

## Migration Plan

New project. `server/src/socket/index.ts` will be the single Socket.io bootstrap file.

**Rollback plan**: Replace Socket.io with raw `ws` — requires rewriting all event handlers but the server-authoritative pattern is unchanged.

## Validation Criteria

- [ ] Unauthenticated socket disconnected within 5 seconds
- [ ] `match_state` delivered at 20Hz (±2Hz) to all players in an 8-player match
- [ ] `match_found` + immediate `queue_cancel` → client receives `match_found` (not cancelled)
- [ ] Player reconnects within 30s → receives `reconnect_ack` with current snapshot
- [ ] `profile:refresh` delivered within 500ms of any economy mutation

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/realtime-transport.md` | Transport | Socket.io v4 with WebSocket-only transport | Defined above; polling disabled |
| `design/gdd/match-server.md` | Match Server | 20Hz broadcast to all match players | `io.to(match:{matchId}).emit('match_state')` at tick end |
| `design/gdd/disconnect-handler.md` | Disconnect | Grace period timer on disconnect | Socket `disconnect` event → Disconnect Handler timer |
| `design/gdd/reconnect-resume.md` | Reconnect | Snapshot push on reconnect_ack | `reconnect_ack` event with `isConfirmed` field defined |
| `design/gdd/match-flow.md` | Match Flow | match_end sent immediately after fan-out starts | `match_end` emitted before `Promise.allSettled()` settles |

## Related

- ADR-0001: Client-server architecture — event contract defined by this ADR
- ADR-0003: Server-Side Game Loop — `match_state` broadcast is the tick output
- ADR-0004: Authentication Architecture — JWT middleware on socket connect
- ADR-0012: Session & Match Lifecycle — socket room management per match
