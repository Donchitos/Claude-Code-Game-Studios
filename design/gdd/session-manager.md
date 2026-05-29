# Session Manager — Game Design Document
> **System**: Session Manager
> **Priority**: MVP
> **Layer**: Core Data
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

---

## Table of Contents

1. [Overview](#1-overview)
2. [Player Fantasy](#2-player-fantasy)
3. [Detailed Rules](#3-detailed-rules)
4. [Formulas](#4-formulas)
5. [Edge Cases](#5-edge-cases)
6. [Dependencies](#6-dependencies)
7. [Tuning Knobs](#7-tuning-knobs)
8. [Acceptance Criteria](#8-acceptance-criteria)

---

## 1. Overview

### What a Session Is

A **session** is the server-side object that represents one active match from the moment Matchmaking declares a match found until the Match Server reports match end (or all players disconnect). It is the authoritative record of a match's lifecycle: who is in it, what state it is in, and when key transitions occurred.

Sessions are distinct from matches. A session is the **coordination layer** — it knows about players, game modes, readiness, and lifecycle states. A match is the **simulation layer** — it knows about game state, physics, and frame ticks. Sessions outlive Match Server instances from an orchestration perspective: the Session Manager creates and destroys Match Server instances; Match Servers do not know sessions exist.

### The Orchestrator Role

The Session Manager is the **single source of truth** for whether a match is happening and who is in it. Its responsibilities are:

- Accepting session creation requests from the Matchmaking Engine.
- Allocating Match Server capacity and spinning up a Match Server instance with the session's configuration.
- Tracking player readiness through the pre-match lobby and character select phases.
- Detecting when a session has stalled (init timeout, heartbeat failure) and cleaning up gracefully.
- Writing the final session record to PostgreSQL and expiring Redis hot data on termination.
- Emitting lifecycle events consumed by Match Flow, MMR, and Disconnect Handler.

### How It Differs from the Match Server

| Concern | Session Manager | Match Server |
|---|---|---|
| Knows about sessions | Yes — owns the session object | No — receives a config struct |
| Knows about players | Yes — by playerId and auth | No — by slot index only |
| Runs game simulation | No | Yes — at 20 Hz |
| Persists state to DB | Yes — creation and termination | No |
| Communicates with players | Yes — lobby/lifecycle events | Yes — in-match game events |
| Lifecycle | Across entire match lifespan | Active phase only |
| Deployed independently | Yes | Yes |

This separation means the Session Manager can be tested without any simulation logic, and a crashed Match Server is a recoverable event from the Session Manager's perspective (it does not crash the session record).

---

## 2. Player Fantasy

### The Feel: "Match Found → Fighting"

From a player's perspective, the session layer is **invisible infrastructure**. The ideal experience is:

> You tap "Play", wait a few seconds in matchmaking, see "Match Found", pick your character, and then you're in the fight — with no dropped connections, no waiting for slow teammates, and no mysterious errors.

The Session Manager is what makes that feel instantaneous and reliable. Specifically:

- **No dead air after "Match Found"**: the session is created and the Socket.io `session_created` event reaches players within 200ms of Matchmaking's `createSession` call.
- **Character select feels snappy**: selections are validated and confirmed server-side before showing the opponent's pick, so players never load into a match to find their selection was rejected.
- **Late connections don't block everyone**: the grace period (`SESSION_READY_GRACE_MS`) means a player who takes 6 seconds to load doesn't force the other 7 players to wait indefinitely. Players who make it to the fight on time are not penalized by stragglers.
- **Disconnects during setup don't erase the session**: if a player drops during character select, the session doesn't simply vanish — it waits, handles the disconnect, and resolves cleanly (either the match starts short, or the session is abandoned, depending on mode rules). Other players get an informative event, not a silent error.
- **Crashes are silent from the player side**: if the Match Server crashes mid-match, the Session Manager detects it via heartbeat timeout and transitions to `abandoned`. Players receive a clean "match ended" notification rather than an indefinitely hanging connection.

The player should never feel the machinery. Sessions are scaffolding that must hold up silently.

---

## 3. Detailed Rules

### 3.1 Session Data Schema

```typescript
interface Session {
  // Identity
  sessionId: string;          // UUID v4, generated at creation; immutable
  matchId: string;            // UUID v4, generated at activation (Match Server ID); null until active
  gameMode: GameMode;         // "duel_1v1" | "squad_3v3" | "ffa_8"

  // Players
  playerIds: string[];        // Ordered array of authenticated player UUIDs
  characterSelections: {      // Keyed by playerId; populated during character_select phase
    [playerId: string]: {
      characterId: string;    // Must be owned by player (validated server-side)
      deckId: string;         // Must be a valid deck for that character
    } | null;                 // null = not yet selected
  };

  // Map
  mapId: string;              // Selected by Matchmaking Engine; validated at creation

  // Timing
  startedAt: string;          // ISO 8601, set when state → active
  createdAt: string;          // ISO 8601, set at creation
  endedAt: string | null;     // ISO 8601, set on terminal state; null during active match

  // State machine
  state: SessionState;        // See §3.2

  // Simulation bookkeeping
  tickCount: number;          // Default 0; incremented by Match Server heartbeat signal
  lastSnapshotAt: string | null; // ISO 8601; last time Match Server sent a state snapshot

  // Readiness
  readyPlayers: string[];     // playerIds who have confirmed ready (connected + assets loaded)
  readyDeadline: string | null; // ISO 8601; set when first player confirms ready; grace period end

  // Internal
  matchServerUrl: string | null; // Allocated Match Server instance endpoint; null until active
  abandonReason: AbandonReason | null; // Populated if state === "abandoned"
}

type SessionState =
  | "waiting_for_players"
  | "character_select"
  | "active"
  | "ended"
  | "abandoned";

type GameMode = "duel_1v1" | "squad_3v3" | "ffa_8";

type AbandonReason =
  | "all_players_disconnected"
  | "init_timeout"
  | "match_server_crash"
  | "no_server_capacity"
  | "insufficient_players";
```

**Defaults at creation:**

| Field | Default |
|---|---|
| `matchId` | `null` |
| `startedAt` | `null` |
| `endedAt` | `null` |
| `state` | `"waiting_for_players"` |
| `tickCount` | `0` |
| `lastSnapshotAt` | `null` |
| `readyPlayers` | `[]` |
| `readyDeadline` | `null` |
| `matchServerUrl` | `null` |
| `abandonReason` | `null` |
| `characterSelections` | `{ [playerId]: null }` for each player |

---

### 3.2 Session State Machine

#### States

| State | Meaning |
|---|---|
| `waiting_for_players` | Session created; waiting for all players to connect and confirm ready |
| `character_select` | All players (or grace-period survivors) are ready; collecting character + deck selections |
| `active` | All selections validated; Match Server instance running; match in progress |
| `ended` | Match Server reported `match_ended`; normal termination |
| `abandoned` | Session terminated without a valid match result; no MMR change |

#### Valid Transitions

```
waiting_for_players ──► character_select
waiting_for_players ──► abandoned

character_select    ──► active
character_select    ──► abandoned

active              ──► ended
active              ──► abandoned
```

No backward transitions are permitted. `ended` and `abandoned` are terminal states.

#### Transition Triggers

| From | To | Trigger |
|---|---|---|
| `waiting_for_players` | `character_select` | All required players confirmed ready, OR `readyDeadline` expired with ≥ minimum players present |
| `waiting_for_players` | `abandoned` | `SESSION_INIT_TIMEOUT_MS` elapsed with 0 players ready, OR fewer than minimum players at `readyDeadline`, OR explicit cancel |
| `character_select` | `active` | All present players submitted valid character+deck selections AND Match Server instance successfully allocated |
| `character_select` | `abandoned` | `SESSION_INIT_TIMEOUT_MS` elapsed, OR all players disconnected, OR Match Server allocation fails with no retry capacity |
| `active` | `ended` | Match Server emits `match_ended` signal with a result payload |
| `active` | `abandoned` | Match Server heartbeat timeout exceeded (`HEARTBEAT_TIMEOUT_MS`), OR all players disconnect simultaneously |

#### Transition Invariants

- A session may only be in one state at a time. State transitions are atomic writes to Redis (using Redis transactions / MULTI-EXEC) with the PostgreSQL record updated asynchronously.
- Once a session reaches `ended` or `abandoned`, no further transitions are processed. Stale events (e.g., a delayed `match_ended` from a crashed server) are ignored.
- Every transition emits a lifecycle event on the Socket.io session room: `session_state_changed { sessionId, prevState, newState, ts }`.

---

### 3.3 Session Creation Flow

```
Matchmaking Engine
  │
  ▼
createSession(players: string[], mode: GameMode, mapId: string)
  │
  ├─ [Validate] Check no player already has an active session (one active session per player rule)
  ├─ [Validate] Verify mapId exists and is eligible for mode
  ├─ [Validate] Authenticate caller (internal service JWT)
  │
  ├─ Generate sessionId (UUID v4)
  ├─ Build Session object (state: "waiting_for_players")
  ├─ WRITE session to PostgreSQL (INSERT)
  ├─ WRITE session to Redis key `session:{sessionId}` (TTL = SESSION_REDIS_TTL_S)
  ├─ INDEX player→session mapping in Redis: `player_session:{playerId}` = sessionId (one per player)
  │
  ├─ Emit Socket.io event to each playerId room:
  │     session_created {
  │       sessionId,
  │       gameMode,
  │       mapId,
  │       playerIds,
  │       readyGracePeriodMs: SESSION_READY_GRACE_MS
  │     }
  │
  └─ Return { sessionId, state: "waiting_for_players" }
```

The `createSession` call is **synchronous up to the DB write**. The Socket.io emit is fire-and-forget from the caller's perspective; Socket.io delivery confirmation is handled by the transport layer.

---

### 3.4 Player Readiness Tracking

A player confirms ready by emitting `player_ready { sessionId, playerId }` over their Socket.io connection. The Session Manager validates:

1. The `playerId` is in `session.playerIds`.
2. The `sessionId` matches the player's active session index.
3. The player is not already in `readyPlayers`.

On first `player_ready` received:
- Set `session.readyDeadline = now + SESSION_READY_GRACE_MS`.
- Schedule a deadline timer.

On each subsequent `player_ready`:
- Append to `session.readyPlayers`.
- If `readyPlayers.length === playerIds.length`: cancel timer, transition immediately to `character_select`.

On deadline expiry:
- Evaluate `readyPlayers` against minimum player requirements (see §3.7).
- If minimum met: transition to `character_select` with the confirmed players only. Players in `playerIds` but not in `readyPlayers` are treated as disconnected: Disconnect Handler is notified, their slots are marked inactive.
- If minimum not met: transition to `abandoned` with `abandonReason: "insufficient_players"`.

**A player who does not ready up within `SESSION_READY_GRACE_MS` of the first ready signal is treated as disconnected from session start.** They receive no MMR penalty (since the match did not start from their perspective), but the Disconnect Handler is notified to update their online presence.

---

### 3.5 Character Select Phase

During `character_select`, each present player must submit:

```typescript
player_select_character {
  sessionId: string;
  playerId: string;
  characterId: string;
  deckId: string;
}
```

Session Manager validates (server-side, before accepting):

1. `playerId` is in `readyPlayers` (late-connected player slots are already removed).
2. `characterId` exists in the player's profile and is unlocked.
3. `deckId` is a valid deck for that `characterId` and belongs to that player.
4. No other present player has already locked in the same `characterId` (if duplicate-character restriction is enabled by mode config).

On valid submission:
- Store `session.characterSelections[playerId] = { characterId, deckId }`.
- Emit `character_selected { sessionId, playerId }` to all players in the session room (character/deck is not broadcast — only the confirmation that a player has selected).

When all `readyPlayers` have submitted valid selections:
- Transition to `active` (see §3.6).

If `SESSION_INIT_TIMEOUT_MS` elapses since entering `character_select` without all selections:
- Any player with `characterSelections[playerId] === null` is treated as timed-out (Disconnect Handler notified).
- Re-evaluate minimum player requirements with remaining selectors.
- If minimum met, proceed to activation with those players.
- If minimum not met, transition to `abandoned`.

---

### 3.6 Session Activation

Triggered when all present players have confirmed selections (or the timeout path above resolves with enough players).

```
Session Manager
  │
  ├─ Allocate Match Server instance (from server pool or spawn new)
  │     On failure: transition to abandoned (abandonReason: "no_server_capacity")
  │
  ├─ Generate matchId (UUID v4)
  ├─ Build MatchConfig:
  │     {
  │       matchId,
  │       sessionId,        // passed for logging/correlation only; Match Server does not use it
  │       gameMode,
  │       mapId,
  │       players: [        // ordered by playerIds, inactive slots omitted
  │         { slotIndex, playerId, characterId, deckId }
  │       ],
  │       tickRateHz: 20,
  │       maxDurationS: GameModeConfig.lookup(gameModeId).maxDurationSec
  │       // Session Manager reads maxDurationSec from the Game Mode config record for the
  │       // requested game_mode_id (e.g. 180s for duel_1v1, 300s for squad_3v3, 480s for ffa_8).
  │       // The Match Server enforces a separate absolute safety timeout of MAX_MATCH_DURATION_S
  │       // (600s) server-side; the per-mode value above is the intended match time limit.
  │     }
  │
  ├─ Call Match Server: POST /match/start { MatchConfig }
  │     On failure: transition to abandoned
  │
  ├─ Update session:
  │     state: "active"
  │     matchId: <generated>
  │     matchServerUrl: <allocated URL>
  │     startedAt: <now ISO 8601>
  │
  ├─ WRITE state update to Redis (atomic)
  ├─ UPDATE PostgreSQL record (async)
  │
  └─ Emit to all players in session room:
        match_started {
          sessionId,
          matchId,
          matchServerUrl,   // players connect their game socket here
          playerSlots: [...],
          mapId
        }
```

From this point, the Match Server is the authoritative source for in-match game state. The Session Manager shifts to a monitoring role: it listens for heartbeats and the `match_ended` signal.

---

### 3.7 Minimum Players to Start

| Mode | Minimum Players to Start | Bot Fill Behaviour |
|---|---|---|
| `duel_1v1` (1v1) | 2 (both players required) | No bot fill; if either player missing → abandon |
| `squad_3v3` (3v3) | 4 (≥ 2 per team) | Bot fill for missing slots if `BOT_FILL_ENABLED=true`; otherwise abandon if < 4 |
| `ffa_8` (8-player) | 3 | Bot fill remaining slots if `BOT_FILL_ENABLED=true`; otherwise abandon if < 3 |

Bot fill is evaluated at the `waiting_for_players → character_select` transition only. A bot slot is assigned a system-generated `playerId` prefixed `bot:` and auto-selects a random owned character. Bot players are always considered "ready" immediately.

---

### 3.8 Session Termination (Normal End)

```
Match Server
  │  match_ended { matchId, result: MatchResult }
  ▼
Session Manager
  ├─ Verify matchId matches session.matchId (reject stale signals)
  ├─ Update session:
  │     state: "ended"
  │     endedAt: <now ISO 8601>
  │     tickCount: result.finalTick
  │     lastSnapshotAt: result.lastSnapshotAt
  │
  ├─ WRITE final state to PostgreSQL (synchronous — must complete before cleanup)
  ├─ DELETE `player_session:{playerId}` Redis keys for all playerIds
  ├─ SET Redis key `session:{sessionId}` TTL to 300s (keep for short post-match queries)
  ├─ Deallocate Match Server instance (return to pool or terminate)
  │
  ├─ Emit `session_ended { sessionId, result }` to Match Flow
  └─ Emit `session_ended { sessionId, result }` to MMR system (triggers rating update)
```

---

### 3.9 Session Abandonment

An abandonment is any terminal path that does not produce a valid match result.

**Abandonment paths:**
- All players disconnected before match starts (`waiting_for_players` or `character_select`).
- All players disconnect simultaneously during `active` phase.
- Match Server heartbeat timeout during `active` phase.
- Init timeout (`SESSION_INIT_TIMEOUT_MS`) in `waiting_for_players` or `character_select`.
- No Match Server capacity on activation.
- Explicit cancel (admin or anti-cheat override).

```
Session Manager (abandonment path)
  ├─ Update session:
  │     state: "abandoned"
  │     endedAt: <now ISO 8601>
  │     abandonReason: <reason>
  │
  ├─ WRITE final state to PostgreSQL
  ├─ DELETE `player_session:{playerId}` Redis keys for all playerIds
  ├─ EXPIRE `session:{sessionId}` Redis key (immediate — no post-match grace needed)
  ├─ Deallocate Match Server instance if one was allocated
  │
  ├─ Emit `session_abandoned { sessionId, reason }` to Match Flow
  ├─ Emit `session_abandoned { sessionId, reason }` to Disconnect Handler
  └─ No MMR event emitted (abandoned sessions do not affect ratings)
```

---

### 3.10 Session Timeout (Init)

A scheduled timer is set at session creation with duration `SESSION_INIT_TIMEOUT_MS` (default 30,000ms). If the session is still in `waiting_for_players` or `character_select` when this timer fires:

1. Log the timeout event with current `readyPlayers` count and `characterSelections` state.
2. Evaluate partial readiness against minimum player rules.
3. If minimum met (character select phase only — see §3.5): proceed to activation with present players.
4. Otherwise: transition to `abandoned` with `abandonReason: "init_timeout"`.

The `SESSION_INIT_TIMEOUT_MS` timer is an absolute deadline from session creation, not a rolling timer. It is cancelled when the session transitions to `active`.

---

### 3.11 Redis Key Structure

| Key | Value | TTL |
|---|---|---|
| `session:{sessionId}` | Serialized `Session` object (JSON) | `SESSION_REDIS_TTL_S` = `maxDurationS + SESSION_REDIS_BUFFER_S` (default: 660s) |
| `player_session:{playerId}` | `sessionId` string | Same TTL as corresponding session key |

TTL is set at creation and refreshed on transition to `active` (reset to `maxDurationS + SESSION_REDIS_BUFFER_S` from activation time). After `ended` or `abandoned`, TTL is set to `SESSION_ENDED_TTL_S` (300s) or expired immediately, respectively (see §3.8 and §3.9).

---

## 4. Formulas

### 4.1 Minimum Players Formula

```
minPlayers(mode) =
  mode === "duel_1v1"        → 2
  mode === "squad_3v3" → 4   (2 per team of 3; bots fill remaining 2 if enabled)
  mode === "ffa_8"         → 3   (out of 8; bots fill remaining 5 if enabled)
```

A session proceeds to `active` only if `readyPlayers.length >= minPlayers(session.gameMode)`.

Bot-fill applies after the minimum is met:
```
botsNeeded(mode, readyCount) =
  mode === "duel_1v1"        → 0   (no bot fill)
  mode === "squad_3v3" → max(0, 6 - readyCount)   (fill to full 6; capped by BOT_FILL_ENABLED)
  mode === "ffa_8"         → max(0, 8 - readyCount)   (fill to full 8; capped by BOT_FILL_ENABLED)
```

### 4.2 Session TTL Formula

```
SESSION_REDIS_TTL_S = maxDurationS + SESSION_REDIS_BUFFER_S

Where maxDurationS is read from the Game Mode config record for the session's game_mode_id:
  game_mode:duel_1v1   → maxDurationSec = 180s
  game_mode:squad_3v3  → maxDurationSec = 300s
  game_mode:ffa_8      → maxDurationSec = 480s

The Match Server enforces an absolute hard cap of MAX_MATCH_DURATION_S = 600s
server-side regardless of mode; this is a safety timeout, not the per-mode limit.

Example (duel_1v1):
  maxDurationS           = 180   (3 minutes, from Game Mode config)
  SESSION_REDIS_BUFFER_S = 60    (1 minute)
  SESSION_REDIS_TTL_S    = 240   (4 minutes)

Post-ended TTL:
  SESSION_ENDED_TTL_S    = 300   (5 minutes; allows post-match queries)

Abandoned TTL:
  Expire immediately (TTL = 0 on Redis key; key deleted)
```

TTL is re-stamped when the session transitions to `active`:
```
activeTTL = (maxDurationS - elapsedSinceCreation) + SESSION_REDIS_BUFFER_S
```

This prevents over-long TTLs if character select ran close to `SESSION_INIT_TIMEOUT_MS`.

### 4.3 Grace Period Expiry Formula

```
readyDeadline = firstReadyTimestamp + SESSION_READY_GRACE_MS

Default: SESSION_READY_GRACE_MS = 5000ms

Evaluation at readyDeadline:
  presentCount = readyPlayers.length

  if presentCount >= minPlayers(mode):
    → transition to character_select
  else:
    → transition to abandoned (abandonReason: "insufficient_players")
```

### 4.4 Heartbeat Timeout Formula

```
Match Server heartbeat interval: HEARTBEAT_INTERVAL_MS (default 5000ms)
Heartbeat timeout threshold:     HEARTBEAT_TIMEOUT_MS  (default 15000ms)

missedBeats = floor(HEARTBEAT_TIMEOUT_MS / HEARTBEAT_INTERVAL_MS) = 3

If no heartbeat received for HEARTBEAT_TIMEOUT_MS:
  → session transitions to abandoned (abandonReason: "match_server_crash")
```

---

## 5. Edge Cases

### 5.1 Duplicate `createSession` for the Same Players (Idempotency)

**Scenario**: Matchmaking Engine sends `createSession` twice for the same player set (retry after transient network error).

**Resolution**:
- On `createSession`, before writing, check Redis index `player_session:{playerId}` for each player.
- If any player already has an active session, and the existing session contains the same player set and mode, return the existing `sessionId` with HTTP 200 (idempotent response).
- If the existing session contains a *different* player set (genuine conflict), return HTTP 409. Matchmaking must resolve.
- Idempotency window: any session in state `waiting_for_players` or `character_select` is eligible for idempotent match. Sessions in `active`, `ended`, or `abandoned` are not matched (a new session would be a new match).

### 5.2 Match Server Crashes Mid-Match

**Scenario**: Match Server process exits unexpectedly during `active` phase; no `match_ended` signal is emitted.

**Detection**: Session Manager runs a heartbeat monitor. If `lastSnapshotAt` age exceeds `HEARTBEAT_TIMEOUT_MS`, the session is considered orphaned.

**Resolution**:
1. Log the orphaned session with last known `tickCount` and `lastSnapshotAt`.
2. Transition session to `abandoned` (abandonReason: `"match_server_crash"`).
3. Write final state to PostgreSQL.
4. Attempt to terminate the Match Server instance (fire-and-forget; already likely dead).
5. Emit `session_abandoned` to Match Flow and Disconnect Handler.
6. No MMR update. Players may be eligible for a rematch offer (Match Flow decision, not Session Manager).

### 5.3 Player Disconnects During Character Select

**Scenario**: A player successfully readied up and entered `character_select`, then disconnects before submitting a character selection.

**Resolution**:
1. Disconnect Handler notifies Session Manager: `player_disconnected { playerId, sessionId }`.
2. Session Manager checks session state: if `character_select`, mark the player's slot as inactive.
3. Re-evaluate minimum players: if remaining `readyPlayers.length >= minPlayers(mode)`, continue character select with remaining players (the disconnected slot is removed; bot-fill rules apply if `BOT_FILL_ENABLED`).
4. If minimum no longer met, transition to `abandoned`.
5. Emit `player_left { sessionId, playerId }` to remaining players in the session room.

The disconnected player receives no MMR penalty (match never started).

### 5.4 Session Creation Fails — No Match Server Capacity

**Scenario**: Session Manager attempts to allocate a Match Server instance during activation; no capacity is available (pool exhausted, no new instances can be spawned within timeout).

**Resolution**:
1. Transition session to `abandoned` (abandonReason: `"no_server_capacity"`).
2. Emit `session_abandoned { sessionId, reason: "no_server_capacity" }` to Matchmaking Engine.
3. Matchmaking Engine is responsible for re-queuing the players (this is outside Session Manager's scope).
4. Log a capacity alert (instrumentation hook for ops team).
5. No MMR penalty for any player.

### 5.5 Two Sessions Created for the Same Player Simultaneously (One Active Session Per Player Rule)

**Scenario**: Race condition — two Matchmaking Engine calls with overlapping player sets arrive within milliseconds of each other.

**Resolution**:
- The `player_session:{playerId}` Redis key is set using a Redis `SET ... NX` (set-if-not-exists) operation during session creation.
- The first call to succeed wins; the second call finds the key already set and returns HTTP 409 for the conflicting player.
- The losing call must abandon its partial session creation (if a sessionId was already generated, write it to DB as `abandoned` immediately to avoid orphaned records).
- Use a Redis Lua script or pipeline to make the multi-player NX check atomic across all `playerIds` in the session.

**Implementation note**: The atomic NX check must span all players in the session atomically. A Lua script is preferred:
```lua
for i, playerId in ipairs(KEYS) do
  if redis.call("EXISTS", "player_session:" .. playerId) == 1 then
    return redis.error_reply("PLAYER_ALREADY_IN_SESSION:" .. playerId)
  end
end
for i, playerId in ipairs(KEYS) do
  redis.call("SET", "player_session:" .. playerId, ARGV[1], "EX", ARGV[2])
end
return "OK"
```

### 5.6 Character Selection Ownership Validation Fails

**Scenario**: Player submits a `characterId` they do not own (e.g., stale client cache, tampered request).

**Resolution**:
1. Reject the selection silently server-side; do not update `characterSelections`.
2. Emit `selection_rejected { sessionId, playerId, reason: "not_owned" }` to that player only.
3. Player may re-submit a valid selection. Their `CHARACTER_SELECT_TIMEOUT_MS` window is not reset.
4. If the player exhausts retries or `SESSION_INIT_TIMEOUT_MS` elapses, treat them as timed-out (§3.5).

### 5.7 `match_ended` Signal Arrives After Session Already Abandoned

**Scenario**: Match Server was declared crashed (heartbeat timeout → abandoned), but it was actually just slow and sends `match_ended` after the session was finalized.

**Resolution**:
- Session Manager checks session state before processing any signal. If state is `abandoned` or `ended`, the `match_ended` signal is ignored with a warning log.
- No state transition is attempted. The late `match_ended` payload is logged for post-mortem analysis.

---

## 6. Dependencies

### 6.1 Upstream (Session Manager Consumes)

| System | What Session Manager Needs | Interface |
|---|---|---|
| **Real-time Transport (Socket.io)** | Emit events to player rooms (`session_created`, `match_started`, `session_state_changed`, etc.); receive `player_ready` and `player_select_character` events | Socket.io server API; player rooms keyed by `playerId` |
| **Authentication (JWT Validation)** | Validate JWT on incoming `player_ready` and `player_select_character` events; validate internal service JWT on `createSession` call | Auth middleware on all Session Manager endpoints |
| **Player Profile** | Verify character ownership and deck validity during character select; read player data at session start for Match Server config | Internal RPC / Supabase query: `getPlayerProfile(playerId)` |
| **Matchmaking Engine** | Sends `createSession` requests when a match is found; receives idempotency/conflict responses | REST: `POST /sessions` |

### 6.2 Downstream (Session Manager Produces)

| System | What Session Manager Provides | Interface |
|---|---|---|
| **Match Server** | Session Manager creates Match Server instances and passes `MatchConfig`; receives heartbeats and `match_ended` signal | REST: `POST /match/start`; WebSocket/HTTP heartbeat; `match_ended` callback |
| **Disconnect Handler** | Notified when a player is evicted from session (timeout/missing ready); notified when session abandons | Event: `player_evicted_from_session { playerId, sessionId, reason }` |
| **Match Flow** | Receives `session_ended` and `session_abandoned` events; drives post-match UI flow | Event bus / Socket.io server-to-server event |
| **MMR System** | Receives `session_ended { sessionId, result }` to trigger rating update; does NOT receive `session_abandoned` | Event bus |

---

## 7. Tuning Knobs

All values are environment-variable configurable. Defaults shown.

| Parameter | Env Var | Default | Description |
|---|---|---|---|
| Ready grace period | `SESSION_READY_GRACE_MS` | `5000` ms | Time after first `player_ready` before deadline fires |
| Session init timeout | `SESSION_INIT_TIMEOUT_MS` | `30000` ms | Absolute deadline from creation to reach `active`; fires abandonment if exceeded |
| Match Server heartbeat interval | `HEARTBEAT_INTERVAL_MS` | `5000` ms | How often Match Server pings Session Manager with `tick_heartbeat` |
| Heartbeat timeout threshold | `HEARTBEAT_TIMEOUT_MS` | `15000` ms | Time since last heartbeat before Session Manager declares Match Server dead |
| Redis session TTL buffer | `SESSION_REDIS_BUFFER_S` | `60` s | Extra seconds added to `maxDurationS` for Redis TTL; prevents premature key expiry |
| Redis ended TTL | `SESSION_ENDED_TTL_S` | `300` s | How long ended session stays in Redis for post-match queries |
| Min players — Duel | `MIN_PLAYERS_DUEL` | `2` | Both players required; no bot fill |
| Min players — Squad Brawl | `MIN_PLAYERS_SQUAD_BRAWL` | `4` | 2 per team minimum; bot fill if enabled |
| Min players — FFA | `MIN_PLAYERS_FFA` | `3` | Out of 8; bot fill remaining if enabled |
| Bot fill enabled | `BOT_FILL_ENABLED` | `false` | Whether missing player slots are filled with bots at activation |
| Max match duration | `MAX_MATCH_DURATION_S` | `600` s | Passed to Match Server as hard cap; also used for Redis TTL base |

**Tuning guidance:**
- `SESSION_READY_GRACE_MS`: Lowering below 3000ms causes frequent abandons on slow mobile connections. Raising above 10000ms creates unacceptable lobby wait times. 5000ms balances network reality vs. UX.
- `SESSION_INIT_TIMEOUT_MS`: Should be at least 2× `SESSION_READY_GRACE_MS` + typical asset load time. 30s is conservative; can be lowered to 20s for fast-connection player bases.
- `HEARTBEAT_TIMEOUT_MS`: Should be 3× `HEARTBEAT_INTERVAL_MS` minimum to tolerate transient lag spikes. Below 3 missed beats risks false-positive crash detection.
- `BOT_FILL_ENABLED`: Disabled by default for MVP (adds complexity to Match Server config and anti-cheat surface). Enable in a staged rollout for FFA and Squad modes to improve match quality at low player counts.

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then. Each maps to an integration or unit test.

### 8.1 Session Creation

**AC-SM-01 — Happy Path Creation**
- Given: Matchmaking sends `createSession` with 2 valid player IDs, mode `"duel_1v1"`, and a valid `mapId`
- When: `createSession` is called
- Then: A session record is written to PostgreSQL with `state: "waiting_for_players"`; both players receive `session_created` via Socket.io within 200ms; Redis key `session:{sessionId}` exists with TTL > 240s (180s Duel mode duration + 60s buffer, per the Duel mode config)

**AC-SM-02 — Idempotent Creation**
- Given: A session already exists in state `waiting_for_players` for players A and B
- When: Matchmaking calls `createSession` again with the same player IDs and mode
- Then: The existing `sessionId` is returned with HTTP 200; no new session is created; Redis and DB record counts are unchanged

**AC-SM-03 — One Active Session Per Player**
- Given: Player A is in an active session
- When: Matchmaking calls `createSession` with player A in a new player set
- Then: HTTP 409 is returned; no session is created; no Socket.io events are emitted

### 8.2 Player Readiness

**AC-SM-04 — All Players Ready Before Grace Period**
- Given: Session in `waiting_for_players`; both players emit `player_ready` within 2s
- When: Second `player_ready` is received
- Then: Session transitions to `character_select`; both players receive `session_state_changed` event; no grace timer fires

**AC-SM-05 — Grace Period Fires with Minimum Players**
- Given: Duel session; player A emits `player_ready`; player B does not respond within `SESSION_READY_GRACE_MS`
- When: Grace period expires
- Then: Session transitions to `abandoned` (reason: `insufficient_players`); both players receive `session_abandoned`; no Match Server is allocated; no MMR change

**AC-SM-06 — Grace Period Fires with Sufficient Players (FFA)**
- Given: FFA session with 8 players; 5 players emit `player_ready` before grace period; `BOT_FILL_ENABLED=false`
- When: Grace period expires with 5 ready players (≥ `MIN_PLAYERS_FFA = 3`)
- Then: Session transitions to `character_select` with only the 5 ready players; 3 non-ready players are evicted and Disconnect Handler is notified; no MMR impact for evicted players

### 8.3 Character Select Phase

**AC-SM-07 — Valid Character Selection**
- Given: Session in `character_select`; player submits a `characterId` they own and a valid `deckId`
- When: `player_select_character` is received
- Then: `characterSelections[playerId]` is set; `character_selected` confirmation is emitted to all session members; selection is not broadcast (only confirmation)

**AC-SM-08 — Invalid Character Selection (Not Owned)**
- Given: Session in `character_select`; player submits a `characterId` they do not own
- When: `player_select_character` is received
- Then: `selection_rejected` is emitted to that player only; `characterSelections[playerId]` remains null; other players are not notified

**AC-SM-09 — Player Disconnects During Character Select**
- Given: Session in `character_select` with 3v3 mode; one player disconnects before selecting
- When: Disconnect Handler notifies Session Manager
- Then: Disconnected player's slot is removed from active players; if remaining players ≥ `MIN_PLAYERS_SQUAD_BRAWL (4)`, character select continues; `player_left` is emitted to remaining players; disconnected player receives no MMR penalty

### 8.4 Session Activation

**AC-SM-10 — Happy Path Activation**
- Given: All players in `character_select` have submitted valid selections; Match Server capacity is available
- When: Last `player_select_character` is received and validated
- Then: Session transitions to `active`; `matchId` is generated; Match Server receives `MatchConfig` via `POST /match/start`; all players receive `match_started` with `matchServerUrl`; `startedAt` is set in DB and Redis

**AC-SM-11 — No Match Server Capacity on Activation**
- Given: All character selections are valid; no Match Server capacity is available
- When: Activation is attempted
- Then: Session transitions to `abandoned` (reason: `no_server_capacity`); `session_abandoned` is emitted to Matchmaking, Match Flow, and Disconnect Handler; no MMR change; capacity alert is logged

### 8.5 Session Termination

**AC-SM-12 — Normal Match End**
- Given: Session in `active`; Match Server emits `match_ended` with a valid result payload
- When: Session Manager receives the signal
- Then: Session transitions to `ended`; `endedAt` is set; final state written to PostgreSQL; `player_session:{playerId}` Redis keys deleted; `session:{sessionId}` TTL reduced to `SESSION_ENDED_TTL_S`; `session_ended` emitted to Match Flow and MMR; Match Server instance deallocated

**AC-SM-13 — Late `match_ended` After Abandonment**
- Given: Session already in `abandoned` state; Match Server sends a delayed `match_ended`
- When: Session Manager receives the signal
- Then: Signal is ignored; no state transition; warning log entry written; no MMR event emitted

### 8.6 Session Abandonment

**AC-SM-14 — All Players Disconnect During Active Match**
- Given: Session in `active`; all players disconnect simultaneously (e.g., server-side forced disconnect)
- When: Disconnect Handler reports all players gone
- Then: Session transitions to `abandoned`; Match Server instance is terminated; no MMR update; `session_abandoned` emitted to Match Flow

**AC-SM-15 — Match Server Heartbeat Timeout**
- Given: Session in `active`; no heartbeat received from Match Server for `HEARTBEAT_TIMEOUT_MS = 15000ms`
- When: Heartbeat timer fires
- Then: Session transitions to `abandoned` (reason: `match_server_crash`); termination attempt sent to Match Server (fire-and-forget); `session_abandoned` emitted; no MMR change; incident logged

**AC-SM-16 — Init Timeout in `waiting_for_players`**
- Given: Session in `waiting_for_players`; no players emit `player_ready` for `SESSION_INIT_TIMEOUT_MS = 30000ms`
- When: Init timeout fires
- Then: Session transitions to `abandoned` (reason: `init_timeout`); both players notified; no Match Server allocated; no MMR change

**AC-SM-17 — Init Timeout in `character_select`**
- Given: Session in `character_select`; one player never submits a selection; `SESSION_INIT_TIMEOUT_MS` elapses
- When: Init timeout fires
- Then: Non-selecting player is evicted; if remaining players meet minimum, session proceeds to activation; otherwise transitions to `abandoned`

### 8.7 Redis and Persistence

**AC-SM-18 — Redis TTL Correct at Creation**
- Given: A Duel (`duel_1v1`) session is created; Game Mode config record specifies `maxDurationSec = 180`; `SESSION_REDIS_BUFFER_S = 60`
- When: Session is created
- Then: Redis key `session:{sessionId}` TTL is 240 seconds (± 2s tolerance for processing time); for squad_3v3 (300s mode) TTL is 360s; for ffa_8 (480s mode) TTL is 540s

**AC-SM-19 — Redis Cleanup on Abandonment**
- Given: Session transitions to `abandoned`
- When: Abandonment cleanup runs
- Then: `session:{sessionId}` is immediately expired (TTL = 0 or key deleted); `player_session:{playerId}` keys for all players are deleted; no Redis keys remain for this session

### 8.8 Race Conditions

**AC-SM-20 — Concurrent Session Creation (Same Player)**
- Given: Two concurrent `createSession` calls arrive with overlapping player sets within 10ms of each other
- When: Both calls attempt to write `player_session:{playerId}` using NX
- Then: Exactly one call succeeds; the other receives HTTP 409; only one session record exists in PostgreSQL; only one set of `session_created` events is emitted to players

---

*End of Document*
