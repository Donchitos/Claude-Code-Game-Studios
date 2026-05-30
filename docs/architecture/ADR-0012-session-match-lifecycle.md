# ADR-0012: Session & Match Lifecycle (createSession → startMatch → endMatch)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Lead Programmer

## Summary

Session Manager is the orchestrator for the match lifecycle: it creates a `GameSession` after matchmaking forms a group, coordinates character selection, instantiates the Match Server (GameRoom), manages bot backfill, handles disconnects via Disconnect Handler, and tears down the session after Match Flow completes. This ADR defines the state machine, lifecycle events, and ownership boundaries.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core / Networking |
| **Knowledge Risk** | LOW |
| **References Consulted** | `design/gdd/session-manager.md`, `design/gdd/match-server.md`, `design/gdd/disconnect-handler.md`, `design/gdd/bot-ai.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002 (socket events), ADR-0003 (IMatchServer), ADR-0004 (userId), ADR-0007 (mode config) |
| **Enables** | ADR-0010 (Match Flow reads endMatch output), ADR-0003 (instantiated here) |
| **Blocks** | Session Manager implementation, Disconnect Handler, Bot AI integration |
| **Ordering Note** | Must be Accepted before Session Manager or Disconnect Handler are implemented |

## Context

### Problem Statement

Match lifecycle spans multiple systems: matchmaking hands off player IDs, character selection must be coordinated, the game loop must run, disconnects must be handled gracefully, and economy fan-out must trigger exactly once at match end. Without a clear orchestrator, these responsibilities would scatter across systems.

### Current State

`server/src/game/GameRoomManager.ts` is scaffolded. No session lifecycle is implemented.

### Constraints

- Session Manager owns the lifecycle; Match Server owns simulation — they must not cross-call
- Character selection has a 30-second timeout; no-selection → default character assigned
- Bot backfill applies both pre-match (unfilled slots) and mid-match (disconnected player > grace period)
- Session must be destroyed after Match Flow completes economy fan-out
- `RECONNECT_GRACE_PERIOD_S` must equal `RECONNECT_WINDOW_S` (invariant enforced in code comments)

### Requirements

- State machine: `forming` → `character_select` → `active` → `ended` → `destroyed`
- Session Manager creates the Match Server on transition to `active`
- Disconnect Handler is instantiated per-session, per-player
- Session is destroyed and removed from GameRoomManager after Match Flow calls back
- Bot AI is assigned when: (a) match forms with fewer than required humans, or (b) human disconnects beyond grace period

## Decision

`SessionManager` (wrapping `GameRoomManager`) implements a per-session state machine. Each session is a `GameSession` object held in a `Map<matchId, GameSession>`. Session Manager transitions states, delegates simulation to Match Server, and coordinates with Disconnect Handler and Bot AI.

### Architecture

```
MATCHMAKING → match formed → SessionManager.createSession(playerIds, mode)

SessionManager:
  Map<matchId, GameSession>

  createSession(playerIds, mode):
    session = new GameSession(matchId, playerIds, mode)
    session.state = 'forming'
    emit match_found to all playerIds via socket
    transition → 'character_select'
    setTimeout(onCharSelectTimeout, 30_000)

  onCharacterConfirmed(matchId, playerId, characterId, deckSlots):
    session.playerCharacters[playerId] = { characterId, deckSlots }
    if all players confirmed:
      clearTimeout(charSelectTimeout)
      transition → 'active'
      startMatch(session)

  onCharSelectTimeout(matchId):
    for each player who hasn't confirmed:
      assign default character (catalog.get('character:vex'))
    transition → 'active'
    startMatch(session)

  startMatch(session):
    config = buildMatchConfig(session, catalog)
    session.matchServer = new GameRoom(config, io)
    session.matchServer.startMatch(config)
    // GameRoom runs its own setInterval tick loop

  onMatchEnd(matchId, results):  // called by GameRoom on endMatch()
    clearInterval(session.tickInterval)
    session.state = 'ended'
    MatchFlow.processMatchEnd(session.matchId, results)
    // MatchFlow handles MMR, economy fan-out, then calls destroySession

  destroySession(matchId):
    io.socketsLeave(`match:${matchId}`)
    sessions.delete(matchId)
    session.state = 'destroyed'

DISCONNECT HANDLER (per player per session):
  onPlayerDisconnect(playerId, matchId):
    session.disconnectTimers[playerId] = setTimeout(() => {
      BotAI.assignBot(playerId, session)  // replace player with bot
    }, RECONNECT_GRACE_PERIOD_S * 1000)
    session.matchServer.getPlayerState(playerId).isActive = false

  onPlayerReconnect(playerId, matchId):
    clearTimeout(session.disconnectTimers[playerId])
    session.matchServer.onPlayerReconnected(playerId)
    socket.join(`match:${matchId}`)
    socket.emit('reconnect_ack', { snapshot: session.matchServer.getSnapshot(), isConfirmed: true })
```

### Key Interfaces

```typescript
type SessionState = 'forming' | 'character_select' | 'active' | 'ended' | 'destroyed';

interface GameSession {
  matchId: string;
  mode: GameMode;
  state: SessionState;
  playerIds: string[];  // human + bot IDs
  playerCharacters: Record<string, { characterId: string; deckSlots: [string, string] }>;
  matchServer: IMatchServer | null;  // null until 'active'
  disconnectTimers: Record<string, NodeJS.Timeout>;
}

interface ISessionManager {
  createSession(playerIds: string[], mode: GameMode): string;  // returns matchId
  onCharacterConfirmed(matchId: string, playerId: string, characterId: string, deckSlots: [string, string]): void;
  onPlayerDisconnect(playerId: string, matchId: string): void;
  onPlayerReconnect(playerId: string, matchId: string): void;
  destroySession(matchId: string): void;
}

// Invariant:
const RECONNECT_GRACE_PERIOD_S = 30;  // must equal RECONNECT_WINDOW_S in reconnect-resume
```

### Implementation Guidelines

- `GameSession` is a plain object in a `Map`; no class hierarchy needed
- Bot IDs are `bot:{uuid}` format; generated at session creation for pre-match bots, at grace period expiry for mid-match replacements
- `startMatch()` is the only place a `GameRoom` is instantiated; Session Manager owns the reference
- Session Manager listens for the GameRoom's `match_ended` internal event to call `onMatchEnd()`
- Socket room `match:{matchId}` is joined by all player sockets at `createSession` time; Session Manager calls `io.socketsLeave()` at `destroySession`
- `isConfirmed: true` in `reconnect_ack` means the character selection phase is complete and the match is active; `isConfirmed: false` means still in character select (rare edge case)

## Alternatives Considered

### Alternative 1: Match Server Owns Lifecycle

- **Description**: Match Server creates/destroys sessions and orchestrates character selection.
- **Pros**: Fewer objects to coordinate.
- **Cons**: Match Server is designed to own simulation only; adding lifecycle to it violates single-responsibility and makes the simulation harder to test.
- **Rejection Reason**: GDD explicitly states "Session Manager orchestrates Match Server, not the reverse."

### Alternative 2: Stateless Sessions (Redis-Backed)

- **Description**: All session state in Redis; no in-memory session object.
- **Pros**: Survives Node.js crashes; enables horizontal scaling.
- **Cons**: Match Server simulation state cannot live in Redis (not serializable at 20Hz); in-memory is required for the tick loop.
- **Rejection Reason**: Match simulation state is inherently in-memory; hybrid is more complex than pure in-memory with reconnect snapshot.

## Consequences

### Positive

- Clear state machine makes lifecycle bugs visible at transition points
- Session Manager owns all coordination; Match Server stays pure simulation
- `destroySession()` guarantees socket room cleanup and map entry removal

### Negative

- Session state is lost on server crash; players in active matches cannot reconnect after a crash
- Character select timeout (30s) adds latency to match start if slow players don't confirm

### Neutral

- Bot replacement mid-match is seamless from the Match Server's perspective — it just sees a `playerId` whose inputs come from Bot AI

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Session not destroyed after match_end | Low | Medium | `destroySession()` is called in a finally block; leaked sessions monitored by session count metric |
| Character select timeout races with player confirm | Low | Low | `clearTimeout` on first valid confirm; last-writer-wins on simultaneous confirms |
| Mid-match crash loses all session state | Medium | High | Disconnect Handler grace period covers brief restarts; multi-instance deployment reduces crash impact |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Session creation latency | — | ≤50ms | — |
| Concurrent active sessions per process | — | ≤50 | — |
| Session destroy time | — | ≤10ms | — |

## Migration Plan

New project.

**Rollback plan**: N/A — no prior implementation.

## Validation Criteria

- [ ] Session transitions through all states in order; no skipped transitions
- [ ] Character select timeout assigns default character and starts match
- [ ] Player disconnect → bot replaces after 30s → match continues
- [ ] Player reconnects within 30s → receives `reconnect_ack` with current snapshot
- [ ] Session destroyed after Match Flow calls destroySession; no memory leak after 100 matches (heap profile)

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/session-manager.md` | Session Manager | Orchestrates match lifecycle | State machine + createSession/destroySession defined |
| `design/gdd/session-manager.md` | Session Manager | Session Manager orchestrates Match Server | Session Manager instantiates GameRoom; Match Server has no reference back |
| `design/gdd/disconnect-handler.md` | Disconnect | Grace period timer per player | `disconnectTimers` map + RECONNECT_GRACE_PERIOD_S constant |
| `design/gdd/bot-ai.md` | Bot AI | Bot assigned when player disconnects beyond grace period | `BotAI.assignBot(playerId, session)` called after timer expires |
| `design/gdd/reconnect-resume.md` | Reconnect | isConfirmed in reconnect_ack | `isConfirmed: true` when match is active; `false` when in char select |

## Related

- ADR-0003: Match Server (GameRoom) is the simulation component instantiated by Session Manager
- ADR-0009: Matchmaking Engine hands player IDs to Session Manager after match formation
- ADR-0010: Match Flow is called by Session Manager with endMatch results
- ADR-0002: Socket room management (`match:{matchId}`) done by Session Manager
