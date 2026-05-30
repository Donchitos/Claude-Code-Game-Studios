# Real-time Transport — Game Design Document

> **System**: Real-time Transport
> **Priority**: MVP
> **Layer**: Infrastructure
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

---

## 1. Overview

The Real-time Transport system owns the bidirectional WebSocket channel between game clients and the game server during an active match. It is built on Socket.io v4 and is the sole delivery mechanism for all time-critical, in-match data.

### What This System Owns

- The Socket.io connection lifecycle: connect, authenticate, join room, active session, disconnect, and reconnect.
- Inbound event routing: validated events from the client are dispatched to the correct server-side handler.
- Outbound event routing: server-computed state and game events are pushed to the correct Socket.io room or individual socket.
- The typed event registry: a single source of truth that names every event, declares its direction, and specifies its payload shape.
- Connection quality monitoring: round-trip time (RTT) measurement via ping/pong, moving-average jitter tracking, and exposure of those metrics to the HUD system.
- Client-side reconnection logic: automatic re-establishment with exponential backoff, capped at 5 attempts within a 30-second window.
- Message serialization: JSON by default; the architecture reserves a configuration flag to switch to MessagePack for binary compaction in a post-MVP pass.

### What This System Does NOT Own

- Non-match API calls (player profile, shop, leaderboard, matchmaking queueing). Those travel over HTTP REST via the API Client system.
- Match business logic. The server is authoritative; this system is the delivery channel, not the rules engine.
- Session lifecycle decisions (e.g., penalizing early leavers). Those are owned by Session Manager.
- Authentication credential storage or token issuance. JWT issuance is owned by the Authentication system; Real-time Transport only validates the token on connection.

### Boundary Diagram

```
Mobile Client                       Node.js Game Server
─────────────────                   ───────────────────────────────────
API Client (HTTP REST)  ──────────> REST endpoints (non-match)

Socket.io Client        <────────>  Socket.io Server
 └─ connect/auth                     └─ JWT validation middleware
 └─ join room                        └─ Room manager (1 room / match)
 └─ input events (C→S)               └─ Tick loop (20 Hz)
 └─ state snapshots (S→C)            └─ Authoritative state engine
 └─ ping/pong                        └─ Connection quality tracker
 └─ reconnect logic                  └─ Disconnect / rejoin handler
```

---

## 2. Player Fantasy

A brawler lives or dies by responsiveness. When a player slides their thumb to dodge and the character responds before the animation frame changes, the game feels like an extension of their body. When there is perceptible lag between input and reaction, the illusion collapses — the player stops playing the game and starts fighting the network.

BRAWLZONE targets a mobile audience on cellular connections. A 4G link to a regional server commonly sits at 40–80 ms RTT; the system is designed so that this range is invisible to gameplay. Even at 150–200 ms RTT, client-side prediction keeps the local character snappy while reconciliation quietly corrects any divergence in the background. The player feels in control; the server remains authoritative; neither goal compromises the other.

The connection quality indicator in the HUD (owned by In-Match HUD, fed by this system) turns a technical metric into a legible signal. A green bar means "play aggressively." An orange bar means "play safely." A red bar is an honest heads-up — the match may stutter, but it will not silently cheat the player. Transparency about network state is part of the game feel.

Reconnection is the other pillar of the fantasy. Dropping out of a match should feel like a stumble, not a fall. Within the 30-second reconnection window the player's avatar remains in the match (frozen by the server), the client retries silently, and if connection is restored the client re-syncs from the latest authoritative snapshot and play continues. The player perceives a brief hitch, not a failed session.

---

## 3. Detailed Rules

### 3.1 Connection Lifecycle

The lifecycle has five named phases. Each phase transition is explicit; undefined transitions are rejected.

```
DISCONNECTED
     │
     │  socket.connect()
     ▼
CONNECTING
     │
     │  TCP/WebSocket handshake complete
     ▼
AUTHENTICATING  ──── auth_error ────> DISCONNECTED
     │
     │  JWT validated + session check passed
     ▼
IN_LOBBY  (connected, not yet in a match room)
     │
     │  session_join (match found, room assigned)
     ▼
IN_MATCH  ──── disconnect ──────────> RECONNECTING (up to 5 attempts / 30s)
     │                                      │
     │                                      │  max attempts exhausted
     │                                      ▼
     │                                 DISCONNECTED (Session Manager notified)
     │
     │  session_leave or match_end
     ▼
IN_LOBBY
```

**Phase: CONNECTING**

The client calls `socket.connect()` with the server URL. Socket.io performs the HTTP upgrade to WebSocket. No game-level data is exchanged yet.

**Phase: AUTHENTICATING**

Immediately after the low-level connection is established, the client emits an `auth` payload (handled by the Socket.io `auth` option before any user-space events). The server-side middleware intercepts this before any event listener fires.

The server:
1. Extracts the JWT from `socket.handshake.auth.token`.
2. Verifies the signature against the application's JWT secret (HS256 or RS256 — determined by Authentication system).
3. Checks the `exp` claim against the current server clock.
4. Queries the Redis session cache to confirm the token has not been revoked (blacklist check).
5. If all checks pass: attaches `socket.data.userId` and `socket.data.sessionId`; emits nothing — connection proceeds silently.
6. If any check fails: emits `auth_error` with a reason code, then calls `socket.disconnect(true)`. The reason codes are: `TOKEN_MISSING`, `TOKEN_INVALID`, `TOKEN_EXPIRED`, `SESSION_REVOKED`.

**Expired token on connect**: if the JWT is expired at connection time, the server emits `auth_error { reason: "TOKEN_EXPIRED" }` and closes the socket. The client must obtain a refreshed token via the API Client (HTTP refresh endpoint) and retry the connection. The Real-time Transport system does not perform token refresh itself.

**Phase: IN_LOBBY**

The socket is authenticated and idle. The client holds the connection open. The server does nothing except respond to ping/pong. The session manager may emit a `session_join` when a match is ready.

**Phase: IN_MATCH**

The server emits `session_join` carrying the `matchId` and `roomId`. The server simultaneously calls `socket.join(roomId)`. From this point:
- The client sends `input_move` and `input_ability` events.
- The server emits `state_delta` at 20 Hz to the room and periodic `state_snapshot` (full state) at a lower frequency (default: every 5 seconds or on player join/rejoin).
- The server emits `game_event` for discrete events (ability fired, player eliminated, score change).
- Ping/pong heartbeat runs independently on a configurable interval (default: 2000 ms).

**Phase: RECONNECTING**

On an unexpected disconnect (network drop, server timeout, app backgrounding), the client enters reconnection. See Section 3.6.

**Match end**: the server emits `match_end`, then calls `socket.leave(roomId)` for all players in the room. The client receives `match_end` and transitions back to IN_LOBBY. The server emits `session_leave` to confirm the room exit. Room is destroyed server-side after all players leave or after a 10-second grace period.

---

### 3.2 JWT Validation on Connection

| Step | Action | Failure Response |
|------|--------|-----------------|
| 1 | Extract `socket.handshake.auth.token` | `auth_error { reason: "TOKEN_MISSING" }` + disconnect |
| 2 | Verify JWT signature (HMAC-SHA256 or RSA-SHA256) | `auth_error { reason: "TOKEN_INVALID" }` + disconnect |
| 3 | Check `exp` claim (server clock, allow ±30s clock skew) | `auth_error { reason: "TOKEN_EXPIRED" }` + disconnect |
| 4 | Redis blacklist check (revoked session IDs) | `auth_error { reason: "SESSION_REVOKED" }` + disconnect |
| 5 | Duplicate socket check (same userId already connected) | Existing socket receives `auth_error { reason: "DUPLICATE_SESSION" }` + disconnect; new socket proceeds |

Step 5 enforces a one-socket-per-user policy. If a second socket authenticates with the same `userId`, the **older** socket is disconnected and the newer socket is accepted. This handles the scenario where a client reconnected without the server detecting the previous socket's close (zombie socket).

---

### 3.3 Socket.io Room Model

- Each active match maps to exactly one Socket.io room, named `match:<matchId>`.
- A player's socket is added to the room by the server (via `socket.join`) after successful auth and session_join. Clients cannot self-join rooms.
- A player's socket is removed from the room by the server (`socket.leave`) when:
  - `match_end` is emitted (all players removed).
  - The player voluntarily leaves (`session_leave`).
  - The player disconnects and exhausts reconnection attempts.
- Spectators (future feature): will use a separate read-only room `spectate:<matchId>`. Not in MVP.
- Room size limits: 1v1 = 2 sockets, 3v3 = 6 sockets, FFA = 8 sockets.
- The server NEVER emits match state to individual sockets; all in-match emissions use `io.to(roomId).emit(...)` or `socket.to(roomId).emit(...)`. This prevents a client from receiving state for a match they are not in.

---

### 3.4 Typed Event Registry

Direction key: **C→S** = client emits, server receives. **S→C** = server emits, client receives. **BOTH** = emitted in both directions at the application level.

| Event Name | Direction | Trigger | Payload Fields |
|---|---|---|---|
| `connect` | C→S (Socket.io built-in) | Client opens socket | `auth: { token: string }` (via `socket.handshake.auth`) |
| `disconnect` | S→C (Socket.io built-in) | Socket closes (any reason) | `reason: string` (Socket.io disconnect reason) |
| `reconnect_attempt` | Client-internal | Client attempts reconnect | `attemptNumber: number` — fired locally, not sent to server |
| `auth_error` | S→C | JWT validation fails at any step | `reason: "TOKEN_MISSING" \| "TOKEN_INVALID" \| "TOKEN_EXPIRED" \| "SESSION_REVOKED" \| "DUPLICATE_SESSION"` |
| `session_join` | S→C | Match found; player admitted to room | `matchId: string, roomId: string, matchType: "duel_1v1" \| "squad_3v3" \| "ffa_8", players: PlayerStub[], serverTimestamp: number` |
| `session_leave` | S→C | Player removed from room (match end or kick) | `matchId: string, reason: "match_end" \| "disconnect_timeout" \| "kicked"` |
| `input_move` | C→S | Player thumb input changes move direction | `seq: number, dx: number, dy: number, timestamp: number` — `dx`/`dy` normalized [-1, 1]; `seq` monotonically increasing per client |
| `input_ability` | C→S | Player activates an ability | `seq: number, abilityId: string, targetX?: number, targetY?: number, timestamp: number` |
| `state_snapshot` | S→C | Full authoritative state (on join/rejoin or every N ticks) | `tick: number, serverTimestamp: number, entities: EntityState[]` — complete world state |
| `state_delta` | S→C | Incremental authoritative state at 20 Hz | `tick: number, serverTimestamp: number, baseTick: number, changes: EntityDelta[]` — only changed fields since `baseTick` |
| `game_event` | S→C | Discrete in-match event | `tick: number, eventType: GameEventType, payload: object` — see GameEventType enum below |
| `match_end` | S→C | Match concludes (time limit, score limit, forfeit) | `matchId: string, result: MatchResult, playerStats: PlayerEndStats[], serverTimestamp: number` |
| `ping` | C→S | Client heartbeat / RTT probe | `clientTimestamp: number` — milliseconds since epoch (client clock) |
| `pong` | S→C | Server response to ping | `clientTimestamp: number` (echoed), `serverTimestamp: number` |

**GameEventType enum** (minimum set for MVP):

| Value | Meaning |
|---|---|
| `ABILITY_FIRED` | A player used an ability; `payload: { userId, abilityId, originX, originY }` |
| `PLAYER_HIT` | A player took damage; `payload: { targetId, sourceId, damage, remainingHp }` |
| `PLAYER_ELIMINATED` | A player's HP reached 0; `payload: { userId, eliminatedBy }` |
| `RESPAWN` | A player respawned (modes with respawn); `payload: { userId, spawnX, spawnY }` |
| `SCORE_UPDATE` | Score/objective changed; `payload: { scores: Record<string, number> }` |
| `MATCH_PHASE_CHANGE` | Match transitions phases (e.g., sudden death); `payload: { phase: string }` |

**EntityState schema** (used in `state_snapshot`):

```typescript
interface EntityState {
  id: string;         // entity UUID
  type: "player" | "projectile" | "pickup";
  x: number;         // world X (fixed-point, cm)
  y: number;         // world Y (fixed-point, cm)
  vx: number;        // velocity X (cm/s)
  vy: number;        // velocity Y (cm/s)
  hp: number;        // current hit points
  facing: number;    // angle in radians
  state: string;     // animation/AI state name
}
```

**EntityDelta schema** (used in `state_delta`):

```typescript
interface EntityDelta {
  id: string;
  // Only fields that changed since baseTick are included:
  x?: number; y?: number; vx?: number; vy?: number;
  hp?: number; facing?: number; state?: string;
  destroyed?: true;  // entity removed from world
}
```

---

### 3.5 Tick Model

The server runs a fixed-timestep game loop at **20 Hz** (one tick every 50 ms).

```
Server tick loop (50ms budget):
  1. Drain inbound input queue for this tick window
  2. Apply inputs to authoritative state
  3. Run physics + collision + ability resolution
  4. Compute EntityDelta vs. previous tick
  5. Emit state_delta to room (via Socket.io)
  6. Increment tick counter
  7. Every 100 ticks (5s): emit state_snapshot (full state resync)
  8. Sleep until next tick boundary
```

The client runs its rendering loop at 60 fps (one frame every ~16.67 ms). Because server updates arrive every 50 ms, the client maintains an **interpolation buffer**: a small queue of the last two received state ticks. Each rendered frame interpolates entity positions between the two most-recent buffered ticks using the formula in Section 4.

**Why 20 Hz**: 20 Hz provides 50 ms of data per packet. At a target RTT of 100 ms, this means the client is always rendering state that is at most 100 ms + 25 ms (half-tick jitter) = ~125 ms behind real time. This is imperceptible for a mobile brawler. Increasing to 30 Hz would reduce this by ~17 ms at the cost of 50% more outbound bandwidth — a post-MVP tuning option.

---

### 3.6 Input Handling

1. **Client captures input**: on every touch event (move joystick drag, ability tap), the client constructs an input event immediately — without waiting for the server's acknowledgement.
2. **Client queues locally**: the input is stored in a client-side pending-inputs buffer, tagged with a monotonically increasing `seq` number and a client `timestamp`.
3. **Client emits to server**: `input_move` or `input_ability` is sent over the WebSocket immediately.
4. **Server receives and queues**: the server places the input in the per-player input queue. Inputs received after the tick boundary for their timestamp are processed in the next tick (late inputs do not cause tick budget overrun).
5. **Server processes on next tick**: the authoritative game loop applies all queued inputs at the start of the tick, computes new state, emits `state_delta`.
6. **Client receives state_delta**: the client updates its interpolation buffer.

Inputs older than 3 ticks (150 ms) when they arrive at the server are **discarded** — this prevents a laggy client from injecting stale inputs into the authoritative state. The server logs discarded inputs for connection-quality diagnostics.

---

### 3.7 Client-Side Prediction and Reconciliation

Client-side prediction allows the local player's avatar to respond immediately to input without waiting for server confirmation. This is purely a visual aid — the server state remains authoritative.

**Prediction loop (per input)**:

```
1. Input captured (touch event)
2. Client applies input to LOCAL simulation state (immediate visual response)
3. Client stores { seq, inputSnapshot, localStateAfterInput } in pending-inputs buffer
4. Client emits input event to server
```

**Reconciliation loop (per state_delta received)**:

```
1. Client receives state_delta (tick T, authoritative)
2. Client updates interpolation buffer from delta
3. Client finds the local state it predicted for tick T
4. Compute error: |predictedPosition - authoritativePosition|
5. If error < PREDICTION_CORRECTION_THRESHOLD (default: 50cm world units):
     Silently blend local state toward authoritative over next 3 frames (smooth correction)
6. If error >= PREDICTION_CORRECTION_THRESHOLD:
     Hard-snap local state to authoritative state
     Re-simulate all pending inputs (seq > T) on top of snapped state
7. Discard all pending inputs with seq covered by this tick
```

Re-simulation in step 6 uses the same deterministic physics functions as the server. The client must implement a lightweight copy of the server's input-application and physics functions for this purpose.

Ability prediction: ability activations are predicted locally for visual feedback (animation start, sound cue) but the authoritative effect (damage, knockback) is applied only when confirmed by a `game_event { eventType: "PLAYER_HIT" }` from the server.

---

### 3.8 Connection Quality Monitoring

**Ping measurement**:

The client emits a `ping` event every `PING_INTERVAL` ms (default: 2000 ms) carrying the current client timestamp. The server immediately echoes a `pong` carrying the client's original timestamp plus the server's own timestamp. On receipt of `pong`:

```
RTT = Date.now() - clientTimestamp   // full round-trip
```

**Moving average RTT** (last 5 samples):

```
avgRTT = (rtt[n] + rtt[n-1] + rtt[n-2] + rtt[n-3] + rtt[n-4]) / 5
```

**Jitter** (see Section 4 for formula).

**HUD exposure**: the system exposes a reactive `connectionQuality` object to the HUD system:

```typescript
interface ConnectionQuality {
  avgRttMs: number;       // moving-average RTT
  jitterMs: number;       // moving-average jitter
  quality: "good" | "fair" | "poor" | "critical";
  packetLossEstimate: number;  // fraction [0, 1], derived from missed state_delta seq gaps
}
```

**Quality thresholds**:

| Quality | avgRTT | Jitter |
|---|---|---|
| `good` | < 100ms | < 20ms |
| `fair` | 100–150ms | 20–40ms |
| `poor` | 150–200ms | 40–80ms |
| `critical` | > 200ms | > 80ms |

---

### 3.9 Reconnection Logic

On an unexpected socket close (any reason other than intentional `session_leave` or `match_end`), the client enters the reconnection state machine:

```
attempt = 1
reconnected = false

while attempt <= MAX_RECONNECT_ATTEMPTS and elapsed < RECONNECT_WINDOW_S:
    fire reconnect_attempt (local event, not sent to server)
    delay = BASE_RECONNECT_DELAY_MS * 2^(attempt - 1) + jitter(0..200ms)
    wait(delay)
    try socket.connect() with same auth token
    if connected:
        emit session_join_request { matchId, userId }   // ask to rejoin room
        reconnected = true
        break
    attempt += 1

if not reconnected:
    fire reconnect_failed (local event)
    notify Session Manager (via callback) → handled by Disconnect Handler
    show disconnect UI to player
```

**Server-side behavior during client disconnect**: when a player socket disconnects, the server does NOT immediately remove the player from the match. Instead:
- The player entity is frozen (inputs ignored, no movement).
- A `RECONNECT_GRACE_PERIOD` timer (default: 30s) starts.
- If the player reconnects within the grace period, the server re-adds their socket to the room and emits a full `state_snapshot` (not delta) to resync.
- If the grace period expires, the server emits `session_leave { reason: "disconnect_timeout" }` to the room and notifies Session Manager to handle the forfeit/scoring adjustment.

**Token expiry during reconnect**: if the JWT expires while the player is disconnected (possible for long disconnects), the reconnect attempt will fail with `auth_error { reason: "TOKEN_EXPIRED" }`. The client catches this specific error and attempts a silent token refresh via the API Client before retrying the socket connection. This refresh attempt counts against the elapsed time in `RECONNECT_WINDOW_S`.

---

## 4. Formulas

### 4.1 Round-Trip Time (RTT)

```
RTT_n = T_pong_received - T_ping_sent

where:
  T_pong_received = client clock at moment pong event is processed
  T_ping_sent     = clientTimestamp field echoed in the pong payload
```

Both timestamps are in milliseconds since Unix epoch on the **client clock**. The server clock is not used in the RTT calculation, avoiding clock-skew issues.

### 4.2 Moving-Average RTT (Window = 5)

```
avgRTT = (1/5) * Σ RTT_i   for i in {n, n-1, n-2, n-3, n-4}
```

On startup, before 5 samples are collected, compute the average over however many samples exist.

### 4.3 Jitter

Jitter is the mean absolute deviation of RTT from the moving average:

```
jitter_n = |RTT_n - avgRTT_{n-1}|

movingJitter = (1/5) * Σ jitter_i   for i in {n, n-1, n-2, n-3, n-4}
```

### 4.4 State Interpolation (Client Rendering)

The client maintains a buffer of the two most recently received authoritative ticks: `tick_A` (older) and `tick_B` (newer).

```
renderTime  = now() - INTERPOLATION_BUFFER_DELAY_MS
alpha       = (renderTime - tick_A.serverTimestamp) /
              (tick_B.serverTimestamp - tick_A.serverTimestamp)
alpha       = clamp(alpha, 0.0, 1.0)

position_rendered.x = lerp(tick_A.entity.x, tick_B.entity.x, alpha)
position_rendered.y = lerp(tick_A.entity.y, tick_B.entity.y, alpha)

where:
  lerp(a, b, t) = a + t * (b - a)
  INTERPOLATION_BUFFER_DELAY_MS = 100  (default; 2 × tick interval)
```

`INTERPOLATION_BUFFER_DELAY_MS` is intentionally set to 2 tick intervals (100 ms at 20 Hz). This ensures that at the time of rendering, `tick_B` has already arrived with very high probability even under moderate jitter. At the cost of an additional 100 ms of visual latency behind real-time, the rendering is smooth and stutter-free.

### 4.5 Reconnection Backoff Delay

```
delay_n = min(BASE_RECONNECT_DELAY_MS * 2^(n-1) + rand(0, JITTER_CAP_MS),
              MAX_RECONNECT_DELAY_MS)

where:
  n                     = attempt number (1-indexed)
  BASE_RECONNECT_DELAY_MS = 500    (default)
  JITTER_CAP_MS           = 200    (random jitter cap, uniform distribution)
  MAX_RECONNECT_DELAY_MS  = 8000   (cap; prevents > 8s gap between attempts)
```

Attempt schedule (no jitter, for illustration):

| Attempt | Base Delay |
|---|---|
| 1 | 500ms |
| 2 | 1000ms |
| 3 | 2000ms |
| 4 | 4000ms |
| 5 | 8000ms |

Total max elapsed (no jitter): 500+1000+2000+4000+8000 = 15.5s, well within the 30s reconnect window.

### 4.6 Packet Loss Estimate

The server increments a monotonic `tick` counter in every `state_delta`. The client can detect gaps:

```
packetLoss = (receivedDeltas_last100 - expectedDeltas_last100) / expectedDeltas_last100

where expectedDeltas = 100  (100 ticks in 5 seconds at 20Hz)
```

This is an estimate; out-of-order delivery may briefly inflate the loss figure. It is used for HUD quality display only, not for gameplay decisions.

---

## 5. Edge Cases

### 5.1 Expired JWT on Connect

**Trigger**: client presents a token whose `exp` is in the past.

**Server behavior**: emits `auth_error { reason: "TOKEN_EXPIRED" }`, disconnects the socket.

**Client behavior**: catches `auth_error` with reason `TOKEN_EXPIRED`; calls the API Client's token-refresh endpoint (HTTP POST `/auth/refresh`); on success, retries `socket.connect()` with the new token; on refresh failure (refresh token also expired), navigates to the login screen.

**Risk**: if refresh is slow (>2s), a player queued for a match may miss the match start. Mitigation: the client should proactively refresh the JWT when it has <60 seconds remaining, before connecting to the transport.

---

### 5.2 Server Restart Mid-Match

**Trigger**: the game server process restarts (crash, deploy) while a match is active.

**Server behavior on restart**: all Socket.io rooms are lost. Room state is not persisted to Redis in MVP (stateless restart). Match state IS checkpointed to Redis every 5 seconds by the Match Server. On restart, the server can restore match state from the Redis checkpoint but cannot restore Socket.io room membership.

**Client behavior**: clients receive a disconnect event. They enter the reconnection flow (Section 3.9). On reconnect, clients send `session_join_request`; the server re-creates the room from the Redis checkpoint and emits a full `state_snapshot`.

**Risk**: if restart takes longer than `RECONNECT_WINDOW_S` (30s), all clients exhaust reconnect attempts and the match is abandoned. The Session Manager must detect this (via absence of any socket in the room after the grace period) and issue forfeiture compensation to all affected players.

**Flag for architecture review**: server restart during match is a data-loss scenario in MVP because room state is not replicated. A future hardening pass should consider Socket.io sticky sessions behind a load balancer and Redis-backed room persistence.

---

### 5.3 Packet Loss (Missed state_delta)

**Trigger**: one or more `state_delta` packets are lost or arrive out of order.

**Detection**: the client notices a gap in the `tick` sequence (e.g., receives tick 40 after tick 38, missing tick 39).

**Client behavior**:
1. The interpolation buffer extrapolates: hold the last known velocity (`vx`, `vy`) and advance position linearly for the missing tick duration. This is dead-reckoning.
2. On receipt of the next valid delta, apply it; any dead-reckoning error is corrected via the standard interpolation blend.
3. If 3 or more consecutive ticks are missing, the client requests a full resync by emitting a `state_resync_request { matchId, lastReceivedTick }` to the server. The server responds with a `state_snapshot`.

**Risk**: dead-reckoning over multiple missing ticks accumulates error proportional to velocity. For a fast-moving entity, 3 missing ticks (150ms) at max speed could produce ~0.5m of position error. The reconciliation blend must clamp this visually to avoid teleporting. The `PREDICTION_CORRECTION_THRESHOLD` (Section 3.7) governs whether a snap or blend is used.

---

### 5.4 Client Prediction Mismatch Exceeds Threshold

**Trigger**: the difference between the client's predicted position and the server's authoritative position for a given tick exceeds `PREDICTION_CORRECTION_THRESHOLD` (default: 50cm).

**Cause**: typically lag-induced missed inputs, physics non-determinism, or an ability effect that the client did not predict correctly.

**Client behavior**: hard-snap to authoritative state, then re-simulate all pending (unacknowledged) inputs. The snap will be visible as a brief teleport if it is large.

**Design note**: large mismatch events should be logged (client-side telemetry) and monitored in aggregate. A frequency of >1 snap per match per player suggests either a prediction bug or a systemic network issue. The threshold should be tuned upward if false snaps are frequent (players on good connections seeing unnecessary corrections).

---

### 5.5 Max Reconnect Attempts Exhausted

**Trigger**: client makes 5 reconnect attempts within 30s and all fail.

**Client behavior**:
1. Stops attempting reconnection.
2. Fires a local `reconnect_failed` event.
3. Notifies the Session Manager via a registered callback.
4. Displays a "Connection Lost" overlay to the player with options: Retry (starts a fresh connection, not counted against the reconnect-attempt window) and Return to Menu (forfeits the match).

**Server behavior**: if the reconnect grace timer (30s) expires with the player still absent, the server calls `socket.leave(roomId)` for the ghost socket entry, notifies Session Manager, and the player is marked as disconnected. The match continues without the disconnected player (their entity is removed or frozen depending on game mode rules).

**Downstream impact**: Session Manager receives a `PLAYER_DISCONNECT_FINAL` signal and applies forfeit logic. For 1v1 Duel, the remaining player wins. For 3v3 and FFA, the match continues with one fewer player.

---

### 5.6 Duplicate userId — Two Clients Connecting Simultaneously

**Trigger**: the same player account opens two connections (e.g., app foregrounded on a second device, or a zombie socket from a previous session that the server has not yet cleaned up).

**Server behavior**: on the second connection's JWT validation, the server detects that `userId` already has an active socket in the `sockets` map.
1. The existing (older) socket receives `auth_error { reason: "DUPLICATE_SESSION" }` and is force-disconnected.
2. The new socket is accepted and proceeds normally.
3. If the older socket was in a match room, the server transfers room membership to the new socket and emits a `state_snapshot` to resync.

**Client behavior on receiving DUPLICATE_SESSION**: the evicted client displays a "You have connected from another device" message and returns to the login screen.

**Risk**: if both connections arrive within the same TCP handshake window (race condition), the server's dedup check may see neither socket as "active" yet. The socket registration must use a Redis lock (keyed by userId) during the authentication middleware to serialize concurrent auth attempts.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | Dependency Type | What Is Required |
|---|---|---|
| **Authentication** | Hard / blocking | JWT issued to the player before any socket connection is attempted. The Real-time Transport validates but does not issue tokens. The JWT secret (or public key for RS256) must be available to the server at startup via environment variable. |

### 6.2 Downstream Dependencies (Systems That Depend on This System)

| System | What They Consume | Interface |
|---|---|---|
| **Session Manager** | Socket lifecycle events: player connected, player disconnected (final), player rejoined. Room membership changes. | Callback registration API: `transport.onPlayerConnect(cb)`, `transport.onPlayerDisconnect(cb)`, `transport.onPlayerRejoin(cb)` |
| **Match Server** | Inbound input events (`input_move`, `input_ability`) routed from the transport layer. Outbound state emitter: the Match Server calls `transport.emitToRoom(roomId, 'state_delta', payload)` | `transport.registerInputHandler(eventName, handler)` and `transport.emitToRoom(roomId, event, payload)` |
| **In-Match HUD** | `connectionQuality` reactive object (avgRttMs, jitterMs, quality, packetLossEstimate) updated after each pong | Reactive store or event emitter: `transport.quality` (observable) |
| **Party / Presence System** | Online/offline status signals derived from socket connect/disconnect events for friends-list presence. NOT match-state data. | `transport.onAnyConnect(userId, cb)` and `transport.onAnyDisconnect(userId, cb)` — fires for all sockets, not just in-match |

### 6.3 Shared Infrastructure

| Resource | Usage |
|---|---|
| **Redis** | JWT blacklist check during auth; match state checkpoint (read on rejoin, write by Match Server); userId-to-socketId lookup for dedup |
| **Node.js Event Loop** | Socket.io v4 runs on Node.js; the tick loop must not block the event loop — game logic runs in a setInterval or a dedicated worker thread |

---

## 7. Tuning Knobs

All values below are server-side environment variables (or a runtime config object) unless marked `[client]`.

| Knob | Default | Range | Effect |
|---|---|---|---|
| `TICK_RATE_HZ` | `20` | 10–60 | Server update frequency. Higher = smoother but more CPU and bandwidth. |
| `FULL_SNAPSHOT_INTERVAL_TICKS` | `100` | 20–400 | How often the server sends a full `state_snapshot` (in addition to deltas). Lower = more bandwidth, faster resync after packet loss. |
| `PING_INTERVAL_MS` | `2000` | 500–5000 | How often the client sends a `ping`. Lower = faster RTT detection but more traffic. |
| `RTT_WINDOW_SIZE` | `5` | 3–20 | Number of ping samples in the moving average. Larger = more stable but slower to react to sudden changes. |
| `MAX_RECONNECT_ATTEMPTS` | `5` | 1–10 | Maximum reconnect attempts before the session is considered permanently disconnected. |
| `RECONNECT_WINDOW_S` | `30` | 10–120 | Maximum wall-clock time the client will spend attempting reconnection. |
| `BASE_RECONNECT_DELAY_MS` | `500` | 100–2000 | Base delay for the first reconnect attempt. |
| `MAX_RECONNECT_DELAY_MS` | `8000` | 1000–30000 | Cap on exponential backoff delay per attempt. |
| `RECONNECT_GRACE_PERIOD_S` | `30` | 10–120 | How long the server keeps a disconnected player's slot before forfeiting. Should equal `RECONNECT_WINDOW_S`. |
| `INTERPOLATION_BUFFER_DELAY_MS` [client] | `100` | 50–200 | How far behind real-time the client renders. Higher = smoother under jitter; lower = less visual latency. |
| `PREDICTION_CORRECTION_THRESHOLD` [client] | `50` | 10–200 | World-unit distance (cm) at which client snaps to server state instead of blending. |
| `INPUT_STALE_THRESHOLD_TICKS` | `3` | 1–10 | Server discards inputs older than this many ticks. |
| `DUPLICATE_SOCKET_DEDUP_LOCK_TTL_MS` | `3000` | 500–10000 | TTL for the Redis lock used to serialize concurrent auth from the same userId. |
| `QUALITY_GOOD_RTT_MS` | `100` | — | RTT threshold for "good" quality indicator shown on HUD. |
| `QUALITY_FAIR_RTT_MS` | `150` | — | RTT threshold for "fair". |
| `QUALITY_POOR_RTT_MS` | `200` | — | RTT threshold for "poor". Above this = "critical". |

---

## 8. Acceptance Criteria

All criteria are pass/fail. Criteria marked [automated] must have a corresponding automated test. Criteria marked [manual] require QA verification.

### AC-RT-01 — Successful Connection and Auth [automated]
**Given** a client presents a valid, non-expired JWT  
**When** the client opens a socket connection  
**Then** the connection reaches IN_LOBBY state within 500ms and no `auth_error` is emitted.

### AC-RT-02 — Invalid JWT Rejection [automated]
**Given** a client presents a tampered or invalid JWT  
**When** the client opens a socket connection  
**Then** the server emits `auth_error { reason: "TOKEN_INVALID" }` and closes the socket within 200ms.

### AC-RT-03 — Expired JWT Rejection [automated]
**Given** a client presents a JWT with `exp` in the past (more than 30s clock skew)  
**When** the client opens a socket connection  
**Then** the server emits `auth_error { reason: "TOKEN_EXPIRED" }` and closes the socket.

### AC-RT-04 — Room Join on Match Start [automated]
**Given** a match is created and two authenticated sockets are assigned to it  
**When** the server emits `session_join` to both sockets  
**Then** both sockets are members of `match:<matchId>` room; subsequent `state_delta` emissions are received by both and only both sockets.

### AC-RT-05 — State Delta at 20Hz [automated]
**Given** a match is active with at least one player in the room  
**When** the server tick loop runs for 1 second  
**Then** exactly 20 `state_delta` events are emitted to the room (±1 for timing tolerance).

### AC-RT-06 — Input Received and Applied [automated]
**Given** a player in an active match  
**When** the client emits `input_move { seq: 1, dx: 1.0, dy: 0.0 }`  
**Then** the next `state_delta` reflects a change in the player entity's position consistent with rightward movement.

### AC-RT-07 — Ping/Pong RTT Measurement [automated]
**Given** a connected client  
**When** the client emits `ping { clientTimestamp: T }`  
**Then** the server responds with `pong { clientTimestamp: T, serverTimestamp: S }` within one tick (50ms); client computes RTT = `now() - T`.

### AC-RT-08 — RTT Moving Average [automated]
**Given** 5 consecutive ping/pong exchanges with RTTs: [80, 90, 100, 110, 120]ms  
**When** the client computes the moving average  
**Then** `avgRTT = 100ms` (exact).

### AC-RT-09 — Reconnection Within Window [manual]
**Given** a player in an active match  
**When** the network is interrupted for 10 seconds and then restored  
**Then** the client reconnects, receives a `state_snapshot`, and gameplay resumes without manual intervention.

### AC-RT-10 — Reconnection Exhaustion [manual]
**Given** a player in an active match  
**When** the network is interrupted for longer than `RECONNECT_WINDOW_S` (30s)  
**Then** the client shows a "Connection Lost" overlay, stops reconnecting, and the server removes the player from the match after `RECONNECT_GRACE_PERIOD_S`.

### AC-RT-11 — Duplicate Socket Dedup [automated]
**Given** a player has an active socket in IN_LOBBY  
**When** the same player opens a second socket with the same JWT  
**Then** the first socket receives `auth_error { reason: "DUPLICATE_SESSION" }` and is disconnected; the second socket proceeds to IN_LOBBY.

### AC-RT-12 — Client Interpolation Smoothness [manual]
**Given** a match running at 20Hz server tick rate  
**When** a player watches an opponent moving at constant velocity  
**Then** the opponent's rendered position is visually smooth at 60fps with no visible stutter under network conditions below `QUALITY_GOOD_RTT_MS`.

### AC-RT-13 — Prediction Correction Snap [automated]
**Given** the client has a predicted position diverging from the server authoritative position by more than `PREDICTION_CORRECTION_THRESHOLD`  
**When** the next `state_delta` is received  
**Then** the client hard-snaps to the authoritative position and re-simulates pending inputs; no inputs with `seq` <= the delta's `tick` remain in the pending-inputs buffer.

### AC-RT-14 — Missed Delta Recovery [automated]
**Given** the client receives ticks 38 and 40 but not tick 39 (simulated via drop)  
**When** tick 40 arrives  
**Then** the client applies dead-reckoning for the missing tick and smoothly transitions to tick 40 state; no error is thrown; the client does not request a full resync for a single missed tick.

### AC-RT-15 — Match End Room Cleanup [automated]
**Given** a match has ended and `match_end` has been emitted  
**When** 10 seconds have elapsed  
**Then** the Socket.io room `match:<matchId>` has zero members and no further events are emitted to it.

### AC-RT-16 — HUD Quality Exposure [automated]
**Given** ping samples produce an `avgRTT` of 160ms  
**When** `connectionQuality` is read by the HUD system  
**Then** `quality === "poor"` and `avgRttMs === 160`.

### AC-RT-17 — Serialization Integrity [automated]
**Given** any event payload is emitted from server to client  
**When** the client deserializes the JSON payload  
**Then** all declared fields are present with correct types; no extra undeclared fields are present; no `undefined` values are serialized.

---

*End of Document*
