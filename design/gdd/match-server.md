# Match Server — Game Design Document
> **System**: Match Server
> **Priority**: MVP
> **Layer**: Game Infrastructure
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

### What the Match Server Is

The Match Server is the **authoritative simulation engine** for one active match. It receives a `MatchConfig` struct from the Session Manager, runs the game loop from first tick to match end, and emits all authoritative state to connected clients via the Real-time Transport layer (Socket.io). It is the sole source of truth for in-match game state: player positions, HP, cooldowns, status effects, projectile positions, zone state, and match timer.

The Match Server does not know it is part of a session. It receives a configuration record, runs the simulation, and signals when the match is over. All session-layer concerns — player identity, MMR, pre-match flow — are invisible to it. It communicates upward only to report its heartbeat and to fire the `match_ended` signal when a win condition is satisfied.

### What the Match Server Owns

- **The authoritative game loop**: a fixed-timestep loop running at 20 Hz (one tick every 50 ms). Each tick processes inputs, advances the simulation, evaluates win conditions, and emits state.
- **Authoritative match state**: all player positions, HP, ability cooldowns, status effects, passive state, projectile positions, zone state, match timer, and current match phase.
- **Input processing pipeline**: receives client input events via Socket.io, validates them (staleness, rate, bounds, ownership), and queues them for the current tick.
- **State snapshot**: the full match state serialized and sent to all clients on demand (reconnect, periodic resync) or on every tick at the configured rate.
- **State delta**: a compressed diff between the current and previous tick's state, sent at 20 Hz to minimize per-packet byte size.
- **Win condition evaluation**: delegates to the Game Mode System's registered evaluator function; fires `match_ended` when the evaluator returns `true`.
- **Heartbeat to Session Manager**: a periodic signal confirming the Match Server is alive and progressing. If the Session Manager stops receiving heartbeats, it declares the Match Server crashed.
- **State checkpointing to Redis**: a full state snapshot written every `CHECKPOINT_INTERVAL_SEC` seconds, used to restore state for reconnecting clients.

### Relationship with the Session Manager

The Session Manager **orchestrates** the Match Server; the Match Server does not orchestrate anything. The lifecycle flow is:

```
Session Manager
  │
  ├─ Allocates Match Server instance
  ├─ Sends POST /match/start { MatchConfig }
  │
  └─ [Monitoring role]
       ├─ Receives heartbeats from Match Server
       └─ Receives match_ended signal when done

Match Server (from its own perspective)
  ├─ Receives MatchConfig → starts game loop
  ├─ Emits heartbeat every HEARTBEAT_INTERVAL_MS
  ├─ Runs simulation for up to maxDurationS
  └─ Fires match_ended → stops game loop
```

The Match Server is **not** aware that a session object exists. It uses `matchId` and `sessionId` (from `MatchConfig`) for logging and correlation only. It does not write to PostgreSQL. It does not manage player identity beyond the slot assignments provided in `MatchConfig`.

### The Authoritative Simulation Model

BRAWLZONE uses a **server-authoritative, client-predictive** model. The Match Server's state is always correct. Clients predict locally for responsiveness but reconcile against every incoming server delta. The Match Server never trusts client-reported positions; it only accepts client-issued **inputs** (move direction, ability activations) and computes all consequences itself.

This model enables:
- Fair hit registration (server computes all collisions).
- Cheat resistance (position cannot be spoofed).
- Deterministic win condition evaluation (no ambiguity about who won).

---

## 2. Player Fantasy

### The Feel: "I Hit That — and It Counted"

Server authority is invisible when it works perfectly. The ideal experience for the player is:

> You tap an ability. Your character responds instantly (client prediction). The server confirms the hit 50–100 ms later and the enemy's HP bar ticks down. You never notice the two-step; it feels like one seamless action.

The Match Server is the infrastructure that makes this possible. Specifically:

- **Lag-compensated hit registration**: a player on a 100 ms connection who aims correctly should land the hit. The server rewinds to the player's perceived moment of impact and evaluates collision there. The player is rewarded for skill, not punished for network conditions.
- **Responsive but fair**: because inputs are server-authoritative, no client can cheat position. Every player's movement result is calculated by the same simulation on the same tick. The outcome is provably fair.
- **Seamless reconnect**: a player who drops for 5–15 seconds and reconnects receives a full state snapshot and steps back in as if they were briefly invisible. The match does not wait for them, but their progress is preserved.
- **No mid-match surprises from balance changes**: stat overlays are applied once at match initialization and locked in for the duration. A balance patch during a live match has no effect on that match. The rules the player started with are the rules they finish with.
- **Predictable session length**: the match timer is ticking on the server. When 600 seconds expire with no winner, the server forces resolution. Players always know a match will end.

The player's mental model should be: "The server is a neutral referee running the same physics for everyone. I fight the opponent, not the lag."

---

## 3. Detailed Rules

### 3.1 MatchConfig Struct

The Match Server is initialized via a single `MatchConfig` struct sent by the Session Manager. After receiving this struct, the Match Server performs all setup synchronously before starting the game loop.

```typescript
interface MatchConfig {
  matchId: string;          // UUID v4; used for Redis keys and logging
  sessionId: string;        // UUID v4; passed for correlation/logging only; not used in simulation
  gameMode: "duel_1v1" | "squad_3v3" | "ffa_8";
  mapId: string;            // Resolved map definition key in Content Catalog
  players: MatchPlayer[];   // Ordered player slots; indices must be contiguous from 0
  tickRateHz: number;       // Authoritative tick rate (default: 20); determines tick interval
  maxDurationS: number;     // Hard cap on match duration in seconds (default: 600)
}

interface MatchPlayer {
  slotIndex: number;        // 0-based slot; used as positional identity within Match Server
  playerId: string;         // Auth-layer player UUID; used for input ownership validation
  characterId: string;      // Resolved character definition key
  deckId: string;           // Resolved deck configuration key
}
```

**Initialization steps on receipt of `MatchConfig`:**

1. Validate all `characterId` and `deckId` values against the Character System's runtime schema registry. If any fail: respond to Session Manager with `HTTP 400 { error: "INVALID_CHARACTER_OR_DECK" }` and halt startup.
2. Fetch the map definition for `mapId` from the Content Catalog cache. If not found: respond `HTTP 400 { error: "MAP_NOT_FOUND" }` and halt.
3. Fetch current balance overlays from Remote Config cache. Apply overlays to character base stats (once; see Character System GDD §3.4). Log all overlay applications.
4. Initialize the authoritative match state (see §3.3).
5. Assign spawn points (seeded random from `matchId XOR unix_timestamp_ms`; see Map/Arena GDD §3.3).
6. Register the Game Mode System's win condition evaluator for `gameMode`.
7. Start the heartbeat timer.
8. Emit `HTTP 200 { matchId, status: "started" }` to Session Manager.
9. Start the game loop (§3.2).

---

### 3.2 The Game Loop — Tick Structure

The game loop runs at a fixed timestep of `1000 / TICK_RATE_HZ` milliseconds (default: 50 ms per tick). Each tick executes the following phases **in order**. All phases must complete within the 50 ms tick budget (see §3.2.1 for budget allocation).

```
┌─────────────────────────────────────────────────────────┐
│  TICK N (50ms budget)                                   │
│                                                         │
│  Phase 1: Input Collection        [~2ms]                │
│  Phase 2: Input Validation        [~3ms]                │
│  Phase 3: Simulation              [~20ms]               │
│  Phase 4: Win Condition Check     [~3ms]                │
│  Phase 5: State Emit              [~7ms]                │
│  Buffer                           [~15ms]               │
└─────────────────────────────────────────────────────────┘
```

**Phase 1 — Input Collection (target: ≤ 2ms)**

Drain the per-player input queues. For each player slot, move all queued input events into a local processing buffer for this tick. The input queue itself continues to accept new arrivals from the Socket.io layer during this phase (the queue is not locked during collection; a snapshot is taken using a copy-swap or read-lock pattern).

- Each player may contribute at most `MAX_INPUTS_PER_TICK` inputs per tick (default: 1 move input + 1 ability input = 2 total). If more are queued, take the most recent of each type and discard the rest.
- Order within the tick: move inputs are applied before ability inputs.

**Phase 2 — Input Validation (target: ≤ 3ms)**

Validate each collected input event before simulation. Validation rules (detailed in §3.4):
- Staleness check: discard inputs with `clientTimestamp < tick_start_time - INPUT_STALE_THRESHOLD_TICKS * TICK_INTERVAL_MS`.
- Bounds check: discard move inputs where the resulting position would be outside map boundaries.
- Ownership check: discard any input where `playerId` does not match the socket's authenticated identity (basic anti-cheat).
- Rate check: if a player has exceeded `MAX_INPUTS_PER_SEC` in the rolling 1-second window, log a warning and discard all inputs from that player for this tick.

Discarded inputs are logged for diagnostics. Validated inputs are passed to Phase 3.

**Phase 3 — Simulation (target: ≤ 20ms)**

Apply all validated inputs to the authoritative match state and advance the physics simulation by one tick interval (`TICK_INTERVAL_MS`). Sub-steps:

1. Apply move inputs: update each player's velocity vector from their move input `{dx, dy}` (normalized to `[-1, 1]`). Scale by `effective_move_speed * TICK_INTERVAL_MS / 1000`. Clamp resulting positions to map bounds.
2. Apply ability inputs: pass to the Combat System's ability resolver. The Combat System computes ability effects (damage, knockback, status effects, projectile spawns) and mutates the authoritative state.
3. Advance projectiles: update all active projectile positions by their velocity * TICK_INTERVAL_MS. Check projectile-obstacle and projectile-player collisions.
4. Apply zone damage: for FFA mode, compute player distance from zone center. Players outside the zone take `zone_damage_per_sec * TICK_INTERVAL_MS / 1000` damage. Zone radius advances according to shrink phase elapsed time.
5. Apply passive state: for each player, invoke the Character System's passive ability tick handler with the player's `passive_state` and the current tick context. Passive state mutations (e.g., stack counters, timer decrements) are written back to the player's `passive_state` field.
6. Advance match timer: decrement `matchTimer` by `TICK_INTERVAL_MS`. If `matchTimer <= 0`, set phase to `"overtime"` or force-end (see §3.8).
7. Update `zone_elapsed_ms`: increment by `TICK_INTERVAL_MS` regardless of phase, so clients can recompute zone state independently on high-latency connections.
8. Apply dead player cleanup: remove entities with `hp <= 0` according to game mode rules (elimination in FFA/Duel; respawn timer in Squad Brawl).

**Phase 4 — Win Condition Check (target: ≤ 3ms)**

Invoke the Game Mode System's registered win condition evaluator:

```typescript
type WinConditionEvaluator = (state: MatchState) => WinConditionResult | null;

interface WinConditionResult {
  winnerId: string | null;    // playerId or teamId; null if draw
  reason: string;             // e.g. "last_standing", "time_limit", "zone_force_end"
  finalTick: number;
}
```

If the evaluator returns a non-null result: immediately proceed to match end (§3.8). Do not emit a state delta for this tick first — emit `match_ended` instead.

If the evaluator throws an exception: log the error and continue simulation (see Edge Cases §5.4). The evaluator is wrapped in a try-catch; a failing evaluator does not crash the Match Server.

**Phase 5 — State Emit (target: ≤ 7ms)**

Serialize and emit the current tick's state to all connected clients. Two possible emissions:

- **State delta** (default): compute the diff between `currentState` and `previousState` (§3.5). Emit `state_delta` to the match Socket.io room. Update `previousState = currentState`.
- **Full state snapshot** (triggers): emit `state_snapshot` when:
  - A player rejoins (targeted at the rejoining socket only).
  - `tick % FULL_SNAPSHOT_INTERVAL_TICKS === 0` (periodic resync; default every 100 ticks = 5s).
  - Immediately on match start (tick 0).

After emit, check if a Redis checkpoint write is due: if `tick % CHECKPOINT_TICKS === 0`, write the full state snapshot to Redis (§3.7). The checkpoint write is **non-blocking** (async/fire-and-forget with error logging); it must not delay the tick.

Check if `force_end_countdown` event must be emitted: if the zone has reached its minimum radius and the `final_hold_sec` countdown is active, emit `force_end_countdown { secondsRemaining }` once at the start of each second of the countdown (see §3.8 and Map/Arena GDD §3.5).

---

#### 3.2.1 Tick Budget Breakdown

| Phase | Budget Allocation | Worst-Case Estimate | Rationale |
|---|---|---|---|
| Input Collection | 2ms | 2ms | Copying at most 16 queued inputs (8 players × 2 per tick) from lock-free queue |
| Input Validation | 3ms | 3ms | Timestamp comparison + bounds check per input; O(n) on input count |
| Simulation | 20ms | 18ms typical / 22ms spike | Physics + collision + ability resolution; Combat System worst case on full FFA with all abilities active |
| Win Condition Check | 3ms | 2ms | Single pass over player HP and alive-count; no heavy computation |
| State Emit (serialize + send) | 7ms | 6ms typical / 9ms spike | JSON serialization of delta (full snapshot reserved for non-tick paths) |
| Buffer | 15ms | — | Absorbs spike overruns; protects tick boundary |
| **Total** | **50ms** | **31ms typical / 38ms spike** | **12ms headroom under typical load** |

If Phase 3 (Simulation) consistently exceeds 22ms, this is a signal to profile the Combat System and optimize the worst-case ability resolution path. See Edge Cases §5.1 for tick overrun handling.

---

### 3.3 Authoritative Match State Schema

The complete authoritative match state is defined by the `MatchState` interface. All simulation reads and writes go through this structure on the server.

```typescript
interface MatchState {
  // Identity
  matchId: string;
  tick: number;             // Monotonically increasing; starts at 0
  timestamp: number;        // Unix epoch ms at start of this tick (server clock)

  // Players
  players: PlayerState[];

  // Projectiles
  projectiles: ProjectileState[];

  // Zone (FFA only; other modes set zone.currentRadius = zone.targetRadius = Infinity)
  zone: ZoneState;

  // Match timing and phase
  matchTimer: number;       // Remaining match duration in milliseconds; counts down from maxDurationS * 1000
  zone_elapsed_ms: number;  // Monotonically increasing; ms since match start; client uses this to recompute zone state
  phase: MatchPhase;
}

interface PlayerState {
  playerId: string;          // Auth-layer player UUID
  slotIndex: number;         // 0-based slot index from MatchConfig
  position: { x: number; y: number };  // World position in Logical Game Units (LGU)
  velocity: { x: number; y: number };  // Current velocity in LGU/sec
  hp: number;                // Current hit points; 0 = eliminated
  maxHp: number;             // Effective max HP (post-overlay); initialized from Character System
  statusEffects: StatusEffect[];   // Active modifiers (e.g., slowed, rooted, invulnerable)
  abilityCooldowns: {        // Key = abilityId; value = remaining cooldown in ms
    [abilityId: string]: number;
  };
  passiveState: PassiveState;      // Per-character typed state for passive ability tracking
  isAlive: boolean;          // Derived from hp > 0; denormalized for fast win-condition evaluation
  isInactive: boolean;       // true when the player has been disconnected long enough for the bot-ai system to take over their inputs (default: false). Set to true by the Disconnect Handler when RECONNECT_GRACE_PERIOD_S expires; set back to false by the Reconnect/Resume system when the player reconnects. Checked by bot-ai.md §3.2 to determine whether to activate bot control.
  respawnTimer: number | null;     // ms until respawn; null if not eliminated or not in respawn-eligible mode
}

interface PassiveState {
  // Per-character typed passive state. Examples (not exhaustive):
  // character:vex:  { consecutiveHitCount: number }
  // character:dash: { speedBoostRemainingMs: number }
  // character:grim: { lastAbilityUsedMs: number }
  // character:sera: (stateless — evaluated each hit)
  // character:zook: (managed by ability system; no per-tick passive state)
  // character:fen:  { lastHealTickMs: number }
  // character:nyx:  { mirrorImageTriggered: boolean }
  // character:colt: { chargedStacks: { [targetPlayerId: string]: number } }
  [key: string]: unknown;    // Typed per-character by Character System runtime schema
}

interface StatusEffect {
  effectId: string;          // e.g. "slowed", "rooted", "burning", "invulnerable"
  sourcePlayerId: string;    // Who applied this effect
  remainingMs: number;       // Duration remaining in ms
  magnitude?: number;        // Optional magnitude (e.g., slow percentage)
}

interface ProjectileState {
  id: string;                // UUID v4; unique within match
  ownerId: string;           // playerId who fired this projectile
  position: { x: number; y: number };
  velocity: { x: number; y: number };  // LGU/sec; constant unless ability modifies trajectory
  type: string;              // Ability-defined projectile type ID (e.g. "fireball", "bullet")
  remainingLifetimeMs: number;  // Projectile self-destructs when this reaches 0
  damage: number;            // Damage on impact; set at spawn from ability definition
}

interface ZoneState {
  centerX: number;           // Zone center X in LGU (fixed at map's initial_center_x for MVP)
  centerY: number;           // Zone center Y in LGU
  currentRadius: number;     // Current zone radius in LGU (interpolated each tick during shrink)
  targetRadius: number;      // End radius for current shrink phase
  damagePerSec: number;      // Current out-of-zone DPS; 0 before shrink starts
  phaseIndex: number;        // 0-based current shrink phase index; -1 if not yet started
  finalHoldActive: boolean;  // True when zone has reached minimum and countdown is running
  finalHoldRemainingMs: number;  // ms remaining in final hold; 0 if not active
}

type MatchPhase = "active" | "overtime" | "force_end_pending" | "ended";
```

**Schema constraints (enforced at state initialization and each tick):**

- `hp` is clamped to `[0, maxHp]` after every simulation step.
- `position.x` and `position.y` are clamped to map safe boundaries every tick.
- `projectiles` array must not exceed `MAX_PROJECTILES_CONCURRENT` (default: 64). New projectile spawns are rejected and logged if the limit is reached.
- `abilityCooldowns` entries with `value <= 0` are removed from the map each tick (cooldown expired).
- `statusEffects` entries with `remainingMs <= 0` are removed each tick.
- `passiveState` is initialized from the Character System's `getInitialPassiveState(characterId)` function at match start and is read/written by the Character System's passive tick handler each simulation step.

---

### 3.4 Input Validation Rules

All input events pass through the validation pipeline before entering simulation. Invalid inputs are **silently discarded** (no error response to client) except where noted.

#### Input Event Schema

```typescript
interface InputMove {
  playerId: string;
  seq: number;              // Client-side monotonically increasing sequence number
  dx: number;               // Normalized direction [-1.0, 1.0]
  dy: number;               // Normalized direction [-1.0, 1.0]
  timestamp: number;        // Client clock at time of input (Unix epoch ms)
}

interface InputAbility {
  playerId: string;
  seq: number;
  abilityId: string;        // Must be in the player's deck
  targetX?: number;         // Optional world-space target position (for targeted abilities)
  targetY?: number;
  timestamp: number;        // Client clock at time of input (Unix epoch ms)
}
```

#### Validation Rules

| Rule | Check | Failure Action |
|---|---|---|
| **Staleness** | `serverTickStartTime - input.timestamp > INPUT_STALE_THRESHOLD_TICKS * TICK_INTERVAL_MS` | Discard; increment `staleness_discard_count` metric |
| **Rate limiting** | Player's input count in rolling 1000ms window exceeds `MAX_INPUTS_PER_SEC` | Discard all inputs from this player for this tick; log warning with `playerId` and count |
| **Max inputs per tick** | Player has submitted more than `MAX_INPUTS_PER_TICK` inputs in one tick buffer | Keep most-recent of each input type; discard remainder |
| **Ownership** | `input.playerId` does not match the socket's authenticated `userId` | Discard; log security event with socket ID and claimed `playerId` |
| **Deck membership** | For `InputAbility`: `abilityId` not present in this player's loaded deck | Discard; log anti-cheat event |
| **Cooldown** | For `InputAbility`: `abilityCooldowns[abilityId] > 0` | Discard; this is expected behavior (client prediction optimism), not an error |
| **Map bounds** | Resulting position from move input is outside `[safe_boundary_inset, width - safe_boundary_inset]` on X or Y | Clamp position to boundary; do not discard the move input |
| **Dead player** | Input from a player where `isAlive === false` and mode does not allow post-death input | Discard |

**Staleness threshold:** `INPUT_STALE_THRESHOLD_TICKS = 3` ticks. At 20 Hz (50ms/tick), inputs older than 3 × 50ms = **150ms** are discarded. This aligns with the Real-time Transport GDD (§3.6) which specifies the same threshold.

**Rate limit threshold:** `MAX_INPUTS_PER_SEC = 60` (default). This is 3× the tick rate, providing tolerance for burst sends without permitting flood attacks. The rolling window resets every 1000ms.

---

### 3.5 State Snapshot vs. State Delta

The Match Server sends two types of state updates:

#### State Delta (`state_delta`)

- **When**: emitted every tick (20 Hz default).
- **Content**: only fields that changed since the previous tick. Uses structural diffing across `MatchState`. Fields with identical values to the previous tick are omitted entirely.
- **Format**: same schema as `MatchState` but all fields optional. Clients merge the delta into their local copy using the `tick` field as the version marker.
- **Required delta fields** (always present even if unchanged): `matchId`, `tick`, `timestamp`.
- **Optimization note**: in ticks where no entities moved and no abilities fired, the delta may contain only `matchId`, `tick`, `timestamp`, and `matchTimer` (decrement). This is the zero-activity delta — it is still emitted to confirm server liveness and advance the client clock.

#### Full State Snapshot (`state_snapshot`)

- **When sent**:
  1. Tick 0 (match start) — sent to all players.
  2. Player reconnects — sent to that socket only (targeted emit, not room broadcast).
  3. Every `FULL_SNAPSHOT_INTERVAL_TICKS` ticks (default: 100 ticks = 5s) — sent to entire room.
  4. Client requests resync via `state_resync_request` after ≥ 3 consecutive missed ticks.
- **Content**: the complete `MatchState` with all fields populated.
- **Reconnect guarantee**: the full snapshot sent on reconnect MUST include `zone_elapsed_ms` (per Map/Arena GDD constraint) and the current state of all destructible obstacles (alive/destroyed). This is critical for clients to recompute zone boundaries and render correct obstacle state.

#### Delta Compression Rules

When computing the state delta:

- Omit any `PlayerState` field that is bitwise-equal to its value in the previous tick.
- If a player's entire `PlayerState` is unchanged (no movement, no HP change, no cooldown changes), omit that player entry from the delta entirely.
- If a projectile was created this tick, include it with all fields. If a projectile was destroyed, include `{ id, destroyed: true }`. If a projectile moved (every tick it is alive), include `{ id, position }` only.
- If `zone.currentRadius` did not change (no shrink active), omit the zone fields.
- `matchTimer` is always included (clients use it for the HUD countdown).
- `zone_elapsed_ms` is always included (clients use it to recompute zone state on high-latency connections — Map/Arena GDD constraint).

---

### 3.6 Lag Compensation

The Match Server implements **server-side rewind** for hit registration. When an ability or projectile hit is evaluated, the server does not evaluate it against the current tick's positions — it evaluates it against a **rewound snapshot** that corresponds to the moment the attacking player perceived the hit.

#### Rewind Procedure

```
1. Server receives InputAbility from player P at server tick T.
2. Retrieve player P's estimated RTT from the Real-time Transport layer:
     estimatedRTT = transport.getPlayerRtt(playerId)
3. Compute rewind offset:
     rewindTicks = floor(min(estimatedRTT, LAG_COMP_REWIND_LIMIT_MS) / TICK_INTERVAL_MS)
4. Retrieve the archived state snapshot for tick (T - rewindTicks) from the rewind buffer.
5. Evaluate hit collision against positions in the rewound snapshot.
6. If hit confirmed: apply damage to target's CURRENT hp (not the rewound hp).
   Rationale: rewound positions are only for geometry/collision lookup, not for
   doubling-up on already-applied damage.
7. Discard rewound snapshot (do not mutate the rewind buffer).
```

#### Rewind Buffer

The Match Server maintains a **circular rewind buffer** of the last `REWIND_BUFFER_TICKS` archived state snapshots (default: 10 ticks = 500ms at 20 Hz). Each archived snapshot stores only player positions and alive status (not full state) to keep memory bounded.

Buffer memory estimate:
```
8 players × { x: 4 bytes, y: 4 bytes, isAlive: 1 byte } = 72 bytes per snapshot
10 snapshots × 72 bytes = 720 bytes rewind buffer (negligible)
```

#### Rewind Window Limit

`LAG_COMP_REWIND_LIMIT_MS` caps the rewind depth to prevent players on extremely high-latency connections from looking back so far that their compensated hits become unfair to low-latency players.

Default: `LAG_COMP_REWIND_LIMIT_MS = 200ms` (4 ticks at 20 Hz). Players with RTT > 200ms receive compensation capped at 200ms. Their inputs are still processed; they simply get less rewind than their full RTT would warrant.

#### Per-Player RTT Exposure

The Real-time Transport layer must expose a `getPlayerRtt(playerId): number` function that the Match Server can call. This returns the most recent moving-average RTT for that player's socket (see Real-time Transport GDD §3.8). If no RTT is available (player just connected), default to `DEFAULT_ASSUMED_RTT_MS = 80ms`.

---

### 3.7 State Checkpointing to Redis

#### Purpose

State checkpoints serve two use cases:
1. **Reconnect recovery**: when a player reconnects, the server reads the most recent checkpoint to populate the full `state_snapshot` it sends the rejoining client.
2. **Crash recovery context**: if the Match Server process crashes, the last checkpoint gives the Session Manager evidence of how far the match progressed (for post-mortem analysis and potential partial-result adjudication).

#### Checkpoint Schedule

- Checkpoints are written every `CHECKPOINT_INTERVAL_SEC` seconds (default: 5s = 100 ticks).
- Checkpoint write is triggered at the end of Phase 5 (State Emit) of the qualifying tick.
- The write is **non-blocking**: the Match Server serializes the checkpoint and dispatches the Redis write asynchronously. If the write is still pending when the next checkpoint is due, the in-flight write is abandoned (the pending data is stale by the time the next tick fires anyway) and a fresh write is dispatched.

#### What Is Checkpointed

The checkpoint stores the full `MatchState` (as defined in §3.3), serialized to JSON.

Redis key structure:
```
match_checkpoint:{matchId}
```

TTL: `CHECKPOINT_TTL_SEC = maxDurationS + CHECKPOINT_TTL_BUFFER_SEC` (default: 600 + 60 = 660s). This ensures the checkpoint survives the full match duration plus a buffer for reconnect queries just after match end.

#### Reconnect Recovery Flow

```
Player reconnects → emits session_join_request { matchId, playerId }
  │
  ├─ Match Server checks if match is still active
  │     If active: proceed
  │     If not active: respond with match_ended (player missed the result)
  │
  ├─ Retrieve current MatchState (live state, not checkpoint)
  │     Note: use live state, not Redis checkpoint, if process is running.
  │     Redis checkpoint is only used if the Match Server process restarted.
  │
  ├─ Emit state_snapshot to reconnecting socket (targeted, not room broadcast)
  │     MUST include zone_elapsed_ms and all obstacle states
  │
  └─ Resume processing inputs from this player
```

On Match Server process restart from checkpoint:
```
1. Read match_checkpoint:{matchId} from Redis
2. Deserialize MatchState
3. Resume game loop from checkpointed tick
4. Note: reconnecting clients who arrive before the restarted server is ready
   will receive auth_error or connection refused — their reconnect backoff
   (Real-time Transport GDD §3.9) will retry within RECONNECT_GRACE_PERIOD_S (30s)
```

---

### 3.8 Match End

#### Normal Win Condition

Each tick, Phase 4 invokes the Game Mode System's win condition evaluator. The evaluator inspects the current `MatchState` and returns a `WinConditionResult` or `null`. When a non-null result is returned:

1. Set `matchState.phase = "ended"`.
2. Stop the game loop (do not begin the next tick).
3. Emit `match_ended` to Session Manager (HTTP POST or Socket.io server-to-server callback):
   ```typescript
   interface MatchEndedSignal {
     matchId: string;
     sessionId: string;            // For correlation only
     result: WinConditionResult;
     finalState: MatchState;       // Full final state; Session Manager uses for records
     finalTick: number;
     lastSnapshotAt: string;       // ISO 8601
   }
   ```
4. Emit `match_end` event to all clients via Socket.io room broadcast (this is the Real-time Transport GDD's `match_end` event).
5. Flush any pending Redis checkpoint write (synchronous flush at match end, unlike the async mid-match writes).
6. Delete the `match_checkpoint:{matchId}` Redis key (cleanup; match is resolved).
7. Shut down the game loop process cleanly.

#### Max Duration Timeout

When `matchState.matchTimer <= 0`:
- Set `matchState.phase = "overtime"`.
- Continue simulation for one additional resolution tick.
- Invoke the win condition evaluator a final time with `forceResolve: true` flag. The evaluator must return a result (it may return `{ winnerId: null, reason: "time_limit_draw" }` for a draw).
- Proceed to the normal match end flow with the evaluator's forced result.

#### Zone Force-End

For FFA mode: when the zone reaches its minimum radius (`final_hold_sec` countdown begins):
- Set `matchState.zone.finalHoldActive = true`.
- Emit `force_end_countdown { secondsRemaining }` once at the start of each second of the countdown (per Map/Arena GDD constraint).
- When `finalHoldRemainingMs <= 0`: invoke the win condition evaluator with `forceResolve: true`. Proceed to normal match end.

#### Graceful Shutdown vs. Crash Recovery

**Graceful shutdown** (normal path):
- Match Server completes current tick → emits `match_ended` → syncs Redis → signals Session Manager → process exits cleanly.
- All in-flight Redis writes are flushed before process exit.
- Socket.io room is left by calling `io.socketsLeave(matchRoomId)` before the event loop drains.

**Crash recovery** (abnormal path):
- The Match Server process exits unexpectedly (OOM, unhandled exception, SIGKILL).
- The Session Manager detects the crash via heartbeat timeout (`HEARTBEAT_TIMEOUT_MS = 15000ms`).
- The Session Manager transitions the session to `abandoned` (reason: `match_server_crash`). See Session Manager GDD §3.9.
- No `match_ended` signal is emitted. No MMR update occurs.
- The last Redis checkpoint (`match_checkpoint:{matchId}`) survives for `CHECKPOINT_TTL_SEC` for post-mortem inspection. It is not used to resume the match (reconnecting a crashed match is not supported at MVP — the session is abandoned).

---

### 3.9 Heartbeat to Session Manager

The Match Server emits a heartbeat to the Session Manager every `HEARTBEAT_INTERVAL_MS` (default: 5000ms).

#### Heartbeat Payload

```typescript
interface MatchHeartbeat {
  matchId: string;
  sessionId: string;
  tick: number;             // Current tick number
  timestamp: string;        // ISO 8601 server time
  playerCount: number;      // Number of currently connected (alive + alive/disconnected) players
}
```

#### Delivery Mechanism

The heartbeat is sent via HTTP POST to the Session Manager's `/sessions/{sessionId}/heartbeat` endpoint. The Session Manager updates `session.tickCount` and `session.lastSnapshotAt` on receipt.

If the Session Manager returns a non-2xx response:
- Log the failure with the response code.
- Retry once after `HEARTBEAT_RETRY_DELAY_MS` (default: 1000ms).
- If the retry also fails: log a critical error. **Do not stop the game loop.** The Match Server continues running — it is the Session Manager's job to detect and react to missed heartbeats, not the Match Server's job to self-terminate on heartbeat failure.

The Match Server does not depend on Session Manager acknowledgement to continue simulation. The heartbeat is a signal, not a handshake.

---

## 4. Formulas

### 4.1 Tick Budget Formula

The maximum safe work per tick is bounded by the tick interval:

```
TICK_INTERVAL_MS = 1000 / TICK_RATE_HZ

At default TICK_RATE_HZ = 20:
  TICK_INTERVAL_MS = 50ms

Tick budget allocation:
  TICK_BUDGET_INPUT_MS    = 2ms
  TICK_BUDGET_VALIDATE_MS = 3ms
  TICK_BUDGET_SIM_MS      = 20ms
  TICK_BUDGET_WINCON_MS   = 3ms
  TICK_BUDGET_EMIT_MS     = 7ms
  TICK_BUDGET_BUFFER_MS   = 15ms
  ─────────────────────────────
  Total                   = 50ms

Overrun threshold: if (phase_duration > phase_budget * OVERRUN_WARN_FACTOR):
  emit warning log; OVERRUN_WARN_FACTOR = 1.5 (warn at 150% of budget)

Tick drift tolerance:
  A tick that finishes in < TICK_INTERVAL_MS sleeps for the remainder.
  A tick that overruns uses 0ms sleep; the next tick starts immediately.
  Consecutive overruns of > 3 ticks trigger a TICK_OVERRUN_ALERT metric.
```

### 4.2 Lag Compensation Rewind Window Formula

```
rewindTicks = floor(min(playerRtt_ms, LAG_COMP_REWIND_LIMIT_MS) / TICK_INTERVAL_MS)

Variables:
  playerRtt_ms             = current moving-average RTT for the player's socket (ms)
  LAG_COMP_REWIND_LIMIT_MS = 200ms (default; tunable)
  TICK_INTERVAL_MS         = 50ms (at 20 Hz)

Examples:
  RTT = 80ms  → rewindTicks = floor(80 / 50)  = 1 tick
  RTT = 120ms → rewindTicks = floor(120 / 50) = 2 ticks
  RTT = 200ms → rewindTicks = floor(200 / 50) = 4 ticks
  RTT = 350ms → rewindTicks = floor(200 / 50) = 4 ticks  [capped at limit]

Rewind buffer requirement:
  REWIND_BUFFER_TICKS ≥ ceil(LAG_COMP_REWIND_LIMIT_MS / TICK_INTERVAL_MS)
  At defaults: REWIND_BUFFER_TICKS ≥ 4 (set to 10 for headroom)
```

### 4.3 Delta Compression Ratio Estimate

```
Full MatchState size (8-player FFA, worst case):
  PlayerState × 8:
    position (8 bytes) + velocity (8 bytes) + hp/maxHp (8 bytes)
    + statusEffects (avg 2 × 16 bytes = 32 bytes) + abilityCooldowns (avg 2 × 12 bytes = 24 bytes)
    + passiveState (avg 24 bytes) + flags (4 bytes)
    ≈ 108 bytes per player → 864 bytes for 8 players

  ProjectileState × avg 8:
    id (16 bytes) + ownerId (16 bytes) + position (8 bytes) + velocity (8 bytes)
    + type (8 bytes) + damage + lifetime (8 bytes)
    ≈ 64 bytes per projectile → 512 bytes for 8 projectiles

  ZoneState: ~48 bytes
  Header (matchId, tick, timestamp, matchTimer, zone_elapsed_ms): ~48 bytes
  ─────────────────────────────────────────────────────
  Full snapshot ≈ 1,472 bytes (JSON; ~2,000 bytes with key names)

Typical delta (idle tick, 4 players moving, 2 projectiles):
  4 players × ~24 bytes (position + velocity only) = 96 bytes
  2 projectiles × ~20 bytes (id + position) = 40 bytes
  Header: 48 bytes
  matchTimer + zone_elapsed_ms: ~20 bytes
  ─────────────────────────────────────────────────────
  Typical delta ≈ 204 bytes (JSON)

Compression ratio:
  ratio = delta_size / full_snapshot_size
        = 204 / 2000 ≈ 0.10

Expected compression: 85–92% reduction vs. full snapshot per tick.
At 20 Hz: delta traffic ≈ 204 × 20 = 4,080 bytes/sec per player
          Full snapshot traffic = 2,000 × 20 = 40,000 bytes/sec per player (if no delta)
```

### 4.4 Checkpoint TTL Formula

```
CHECKPOINT_TTL_SEC = maxDurationS + CHECKPOINT_TTL_BUFFER_SEC

Default values:
  maxDurationS             = 600s
  CHECKPOINT_TTL_BUFFER_SEC = 60s
  CHECKPOINT_TTL_SEC        = 660s

Rationale: the checkpoint must survive the full match duration in case the
Match Server restarts near the end. The 60s buffer allows post-match queries
for results/replays to read the last checkpoint before it expires.

Checkpoint write interval:
  CHECKPOINT_TICKS = CHECKPOINT_INTERVAL_SEC * TICK_RATE_HZ
  At defaults: CHECKPOINT_TICKS = 5 * 20 = 100 ticks

Total checkpoints over a max-duration match:
  maxDurationS / CHECKPOINT_INTERVAL_SEC = 600 / 5 = 120 checkpoint writes
  At ~2,000 bytes per write: 240 KB total Redis writes per match (negligible)
```

### 4.5 Input Staleness Threshold Formula

```
INPUT_STALE_THRESHOLD_MS = INPUT_STALE_THRESHOLD_TICKS * TICK_INTERVAL_MS

At defaults:
  INPUT_STALE_THRESHOLD_TICKS = 3
  TICK_INTERVAL_MS            = 50ms
  INPUT_STALE_THRESHOLD_MS    = 150ms

An input is stale if:
  (server_tick_start_time - input.timestamp) > INPUT_STALE_THRESHOLD_MS

Design note: this matches the Real-time Transport GDD §3.6 which specifies
"inputs older than 3 ticks (150ms) when they arrive at the server are discarded."
The Match Server and Real-time Transport layer use the same threshold value.
```

---

## 5. Edge Cases

### 5.1 Tick Overrun — Simulation Takes Longer Than 50ms

**Trigger**: Phase 3 (Simulation) or Phase 5 (State Emit) exceeds its budget, causing the total tick to exceed `TICK_INTERVAL_MS = 50ms`.

**Behavior**:
1. The tick completes its full execution regardless of overrun. Work is never cut short mid-tick.
2. The next tick's sleep is set to `max(0, TICK_INTERVAL_MS - actual_tick_duration)`. If `actual_tick_duration >= TICK_INTERVAL_MS`, the next tick starts with 0 sleep (immediately).
3. The server does NOT skip ticks to "catch up". Every tick is executed in sequence. This means a persistent overrun causes the game clock to run slower than wall clock time — perceptible as server-side lag.
4. If overruns on 3 or more consecutive ticks are detected:
   - Emit a `TICK_OVERRUN_CONSECUTIVE` metric alert to the Logging/Monitoring system.
   - Log a warning with the average tick duration and the phase breakdown.
   - Do NOT terminate the match or the process. The game loop continues.
5. If the average tick duration over a 5-second window exceeds `TICK_INTERVAL_MS * 2 = 100ms`, emit a `TICK_CRITICAL_OVERRUN` alert. At this point, operator intervention (process restart, server scale-up) is needed.

**Design note**: Tick overruns during full FFA (8 players, all abilities firing) are the highest-risk scenario for simulation budget. The Combat System must be designed to complete in ≤ 18ms worst-case for Phase 3 to stay within budget.

### 5.2 All Players Disconnect Simultaneously

**Trigger**: All connected player sockets close within the same heartbeat interval (e.g., a regional network outage, server-side forced disconnect).

**Behavior**:
1. The Match Server detects the final disconnect (via Socket.io `disconnect` events).
2. The game loop continues running for up to `ALL_PLAYERS_DISCONNECTED_GRACE_MS` (default: 5000ms) to allow reconnects.
3. If no player reconnects within the grace period:
   - The Match Server does NOT emit `match_ended` (there is no meaningful result to report).
   - The Match Server stops the game loop.
   - A `match_abandoned { matchId, reason: "all_players_disconnected" }` signal is sent to the Session Manager.
4. The Session Manager transitions the session to `abandoned` (see Session Manager GDD §3.9).
5. The last Redis checkpoint is retained for `CHECKPOINT_TTL_SEC` for diagnostics.

**Note**: the Session Manager also detects this path independently via heartbeat timeout. If the Match Server's abandonment signal races with the Session Manager's timeout detection, the first one to fire wins; the second is ignored (state machine idempotency in Session Manager GDD §5.7).

### 5.3 Input Flood from a Single Client

**Trigger**: A client sends input events at a rate far exceeding the tick rate (e.g., a modified client sending 500 `input_move` events per second).

**Behavior**:
1. The Real-time Transport layer accepts incoming Socket.io events and places them in the per-player input queue. The queue is bounded by `INPUT_QUEUE_MAX_DEPTH` (default: 32 events per player) — events beyond this are dropped at the transport layer before reaching the Match Server.
2. During Phase 2 (Input Validation), the rate limit check fires: if a player has submitted more than `MAX_INPUTS_PER_SEC` inputs in the rolling 1-second window:
   - All inputs from that player are discarded for this tick.
   - A warning is logged with `playerId`, socket ID, and input count.
3. If the flood continues for 3 or more consecutive seconds:
   - Emit an `INPUT_FLOOD_ALERT` metric to Logging/Monitoring.
   - Optionally (configurable): disconnect the player's socket and notify the Session Manager.
4. The game loop itself is **never delayed** by input flood — Phase 2 reads from the input queue snapshot taken in Phase 1, and Phase 2's budget is `≤ 3ms` even at maximum queue depth.

### 5.4 Win Condition Evaluator Throws an Exception

**Trigger**: The Game Mode System's registered `WinConditionEvaluator` function throws an uncaught exception during Phase 4.

**Behavior**:
1. The Match Server catches the exception in the Phase 4 try-catch wrapper.
2. The exception is logged as a critical error: `{ matchId, tick, error: exception.message, stack }`.
3. The Match Server emits a `WIN_CONDITION_EVALUATOR_ERROR` metric alert.
4. The game loop continues. The win condition will be retried on the next tick.
5. If the evaluator throws on 10 consecutive ticks (default: `WIN_CONDITION_MAX_CONSECUTIVE_ERRORS = 10`), the Match Server force-ends the match:
   - Result: `{ winnerId: null, reason: "evaluator_failure_force_end" }`.
   - Emit `match_ended` to Session Manager with this result.
   - Log the force-end as a critical error requiring a postmortem.

**Rationale**: a failing win condition evaluator should never prevent the match from eventually concluding. The 10-tick threshold (500ms at 20 Hz) gives transient errors time to resolve without permanently soft-locking the match.

### 5.5 Redis Checkpoint Write Fails

**Trigger**: The async Redis write for a state checkpoint fails (Redis unavailable, write timeout, serialization error).

**Behavior**:
1. The failed write is logged with the error and tick number.
2. A `CHECKPOINT_WRITE_FAILURE` metric is incremented.
3. The Match Server continues running. The game loop is **never interrupted** by a checkpoint failure.
4. The next scheduled checkpoint write (in `CHECKPOINT_INTERVAL_SEC`) will attempt a fresh write. No retry of the failed checkpoint is performed (the data is stale).
5. If checkpoint writes fail for 3 or more consecutive intervals, emit a `CHECKPOINT_CONSECUTIVE_FAILURES` alert.

**Impact**: if the Match Server crashes while checkpoints are failing, reconnecting players cannot restore state from Redis. They will receive a connection error and the match will be abandoned. This is an acceptable degradation — data durability is best-effort for an ephemeral real-time match.

### 5.6 Match Server Process Out of Memory (OOM)

**Trigger**: The Match Server process is killed by the OS OOM killer (typically due to a memory leak or runaway state accumulation).

**Behavior**: identical to the crash recovery path (§3.8 Graceful Shutdown vs. Crash Recovery):
1. The process exits with no opportunity to send `match_ended` or flush Redis.
2. The Session Manager detects the missed heartbeat after `HEARTBEAT_TIMEOUT_MS = 15000ms`.
3. Session transitions to `abandoned` (reason: `match_server_crash`).
4. The last successful Redis checkpoint (up to 5s stale) persists for diagnostics.

**Prevention mitigations**:
- The projectile array is capped at `MAX_PROJECTILES_CONCURRENT = 64`. New spawns are rejected if the cap is reached.
- The rewind buffer is bounded at `REWIND_BUFFER_TICKS * per-snapshot size` (≈720 bytes; negligible).
- Status effects are capped at `MAX_STATUS_EFFECTS_PER_PLAYER = 8`. Application of additional effects is rejected.
- The Match Server process should be deployed with an explicit memory limit (e.g., Node.js `--max-old-space-size=512` for 512MB ceiling) so OOM is deterministic and fast rather than swapping.

### 5.7 Player Sends Inputs for a Character They Don't Own (Anti-Cheat)

**Trigger**: A client emits an `InputAbility` with an `abilityId` that is not in the player's loaded deck, or emits inputs claiming to be a `playerId` that does not match the authenticated socket's `userId`.

**Behavior**:

For `abilityId` not in deck:
1. Discard the input silently.
2. Log a security event: `{ event: "INVALID_ABILITY_ID", playerId, abilityId, matchId, tick }`.
3. Increment `invalid_ability_attempt_count[playerId]`.
4. If count exceeds `ANTI_CHEAT_ABILITY_THRESHOLD = 5` in one match: emit `ANTI_CHEAT_ALERT` to Logging/Monitoring. The alert is informational at MVP; no automatic kick is implemented until Anti-Cheat system (Block 9) ships.

For `playerId` mismatch (input claims to be a different player):
1. Discard the input.
2. Log a security event: `{ event: "PLAYER_ID_SPOOFING_ATTEMPT", claimedPlayerId, authenticatedUserId, matchId }`.
3. Immediately emit a `SPOOFING_ALERT` metric. This is the highest-severity anti-cheat signal at MVP.

Both cases are non-terminating at the Match Server level — the server does not disconnect the socket. The Anti-Cheat system (post-MVP) will consume these alerts and act on them.

---

## 6. Dependencies

### 6.1 Upstream — Systems the Match Server Consumes

| System | What Match Server Needs | Interface | Failure Mode |
|---|---|---|---|
| **Session Manager** | `MatchConfig` struct delivered via `POST /match/start`; heartbeat ACK | HTTP; `POST /sessions/{sessionId}/heartbeat` | If Session Manager is unreachable, Match Server continues running and retries heartbeat (§3.9) |
| **Real-time Transport (Socket.io)** | Inbound input events (`input_move`, `input_ability`); outbound state delivery (`state_delta`, `state_snapshot`, `match_end`, `force_end_countdown`); per-player RTT via `getPlayerRtt(playerId)` | `transport.registerInputHandler(...)` and `transport.emitToRoom(...)` | If transport layer drops, clients lose updates but Match Server continues ticking; deltas are buffered or lost |
| **Character System** | Character static definitions (`CharacterDefinition`); runtime schema for `PassiveState` initialization; `getInitialPassiveState(characterId)`; passive tick handler `tickPassive(passiveState, tickContext)` | In-process module call (server-side) | If character definition not found at initialization: `HTTP 400` and startup halt |
| **Content Catalog** | Map definition for `mapId`; ability definitions for all abilities in all decks; balance overlay from Remote Config cache | In-process cache lookup | If map not found at initialization: `HTTP 400` and startup halt; missing ability definition: log error and skip ability processing for that ability |

### 6.2 Downstream — Systems That Consume the Match Server

| System | What They Receive | Interface | Dependency Notes |
|---|---|---|---|
| **Game Mode System** | Registers its `WinConditionEvaluator` function with the Match Server at initialization; receives `MatchState` on each Phase 4 invocation | Callback registration: `matchServer.registerWinConditionEvaluator(gameMode, fn)` | Must be registered before game loop starts; if not registered, Match Server falls back to a no-op evaluator and logs a critical error |
| **Combat System** | Runs within Phase 3 (Simulation); receives validated ability inputs and current `MatchState`; returns state mutations | In-process function call: `combatSystem.resolveAbilityInput(input, state) → StateMutation[]` | Combat System is a stateless resolver; it does not own state — Match Server applies the returned mutations |
| **Match Flow** | Receives `match_ended` signal (via Session Manager relay); drives post-match UI | Indirect: Match Server → Session Manager → Match Flow event bus | Match Server does not communicate directly with Match Flow |
| **Disconnect Handler** | Notified of player disconnects within the match (socket disconnects that occur after the match has started) | `transport.onPlayerDisconnect(cb)` callback; Match Server calls `disconnectHandler.onPlayerDisconnect(playerId, matchId)` | Disconnect Handler decides whether to freeze the player entity or start a respawn timer based on game mode rules |
| **Session Manager (feedback)** | `match_ended` signal with final state and result; `match_abandoned` signal; periodic heartbeats | HTTP POST to Session Manager; heartbeat endpoint | Session Manager is the ultimate consumer of match results |

---

## 7. Tuning Knobs

All values are environment-variable configurable. Defaults shown. Ranges indicate the safe operational envelope; values outside the range require explicit sign-off from the technical director.

| Parameter | Env Var | Default | Safe Range | Effect on Gameplay |
|---|---|---|---|---|
| Tick rate | `TICK_RATE_HZ` | `20` | `10–30` | Higher = smoother, more bandwidth and CPU. 20 Hz is the MVP target. Do not exceed 30 Hz without profiling Combat System first. |
| Tick interval (derived) | — | `50ms` | — | Derived from `1000 / TICK_RATE_HZ`. Do not set directly. |
| Checkpoint interval | `CHECKPOINT_INTERVAL_SEC` | `5` | `2–30` | Lower = more Redis writes but better reconnect fidelity. Higher = fewer writes but state can be more stale on reconnect. |
| Checkpoint TTL buffer | `CHECKPOINT_TTL_BUFFER_SEC` | `60` | `30–300` | Extra seconds beyond `maxDurationS` for checkpoint survival. Must be > `RECONNECT_GRACE_PERIOD_S`. |
| Heartbeat interval | `HEARTBEAT_INTERVAL_MS` | `5000` | `1000–10000` | Lower = faster crash detection by Session Manager but more traffic. Must be less than `HEARTBEAT_TIMEOUT_MS / 3` (Session Manager GDD §4.4). |
| Lag compensation limit | `LAG_COMP_REWIND_LIMIT_MS` | `200` | `50–400` | Higher = fairer for high-latency players but can feel wrong to low-latency players (hits from behind cover). 200ms is the competitive fairness sweet spot. |
| Rewind buffer depth | `REWIND_BUFFER_TICKS` | `10` | `4–20` | Must be ≥ `ceil(LAG_COMP_REWIND_LIMIT_MS / TICK_INTERVAL_MS)`. Extra depth adds negligible memory. |
| Input staleness threshold | `INPUT_STALE_THRESHOLD_TICKS` | `3` | `1–10` | Lower = stricter (more input discards on high-latency connections). Higher = looser (stale inputs accepted, simulation less accurate). 3 ticks = 150ms, matching Real-time Transport GDD. |
| Max inputs per player per tick | `MAX_INPUTS_PER_TICK` | `2` | `1–4` | 1 move + 1 ability is the intended value. Increasing allows burst inputs; decreasing may feel unresponsive. |
| Max inputs per second per player | `MAX_INPUTS_PER_SEC` | `60` | `20–200` | Anti-flood threshold. 60 is 3× tick rate. Do not lower below `TICK_RATE_HZ * 2` (would discard legitimate inputs). |
| Full snapshot interval | `FULL_SNAPSHOT_INTERVAL_TICKS` | `100` | `20–400` | How often the server sends a full state snapshot for periodic resync. Lower = more bandwidth but faster error recovery. |
| Max concurrent projectiles | `MAX_PROJECTILES_CONCURRENT` | `64` | `16–256` | Cap on active projectiles across all players. Prevents memory runaway from rapid-fire abilities. |
| Max status effects per player | `MAX_STATUS_EFFECTS_PER_PLAYER` | `8` | `4–16` | Cap per player. Prevents pathological status stack accumulation. |
| Win condition error threshold | `WIN_CONDITION_MAX_CONSECUTIVE_ERRORS` | `10` | `3–50` | Consecutive tick failures before force-end. Lower = faster recovery from broken evaluator; higher = more tolerance for transient errors. |
| Input queue max depth | `INPUT_QUEUE_MAX_DEPTH` | `32` | `8–128` | Per-player queue depth at the transport layer. Overflow is dropped before Match Server processing. |
| All-players-disconnected grace | `ALL_PLAYERS_DISCONNECTED_GRACE_MS` | `5000` | `1000–30000` | How long Match Server waits for reconnects before signaling abandonment. Should be less than `RECONNECT_GRACE_PERIOD_S` (30s). |
| Default assumed RTT | `DEFAULT_ASSUMED_RTT_MS` | `80` | `20–200` | Assumed RTT for lag compensation when no RTT sample exists yet (new connection). |

**Tuning guidance:**

- `TICK_RATE_HZ` and `LAG_COMP_REWIND_LIMIT_MS` are the two knobs with the highest gameplay impact. Change only after profiling on target hardware and evaluating in controlled playtests.
- `CHECKPOINT_INTERVAL_SEC` at 5s means a reconnecting player may see state up to 5 seconds stale if the Match Server restarted. Reducing to 2s halves this gap at the cost of double the Redis writes.
- `INPUT_STALE_THRESHOLD_TICKS` at 3 means players on > 150ms RTT will have some inputs discarded. The lag compensation (§3.6) mitigates this for hit registration, but movement discards on high-latency connections are unavoidable. Do not raise this above 6 without testing for simulation accuracy degradation.

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then. Each maps to an automated or manual test. Test type is noted.

### 8.1 Game Loop — Tick Rate and Budget

**AC-MS-01 — Tick Rate Accuracy [automated]**
- Given: A match is active with 2 connected players
- When: The server runs for 10 seconds (200 ticks at 20 Hz)
- Then: Exactly 200 `state_delta` events are emitted to the match room (±2 ticks tolerance for timer precision); the average tick interval is between 48ms and 52ms

**AC-MS-02 — Tick Budget Not Violated Under Normal Load [automated]**
- Given: A 3v3 match with all 6 players sending inputs every tick and 8 projectiles active
- When: The server runs for 60 seconds
- Then: No individual tick exceeds `TICK_INTERVAL_MS * 1.5 = 75ms`; the `TICK_OVERRUN_CONSECUTIVE` metric is never emitted

**AC-MS-03 — Input Processing Order [automated]**
- Given: A player sends both `input_move` and `input_ability` in the same tick window
- When: The tick resolves
- Then: The move input is applied before the ability input; the player's position after the tick reflects the move-first, ability-second order

**AC-MS-04 — State Delta Emitted Every Tick [automated]**
- Given: A match is active with at least one connected player
- When: 5 seconds elapse (100 ticks)
- Then: 100 `state_delta` events are received by the connected client; each delta contains `matchId`, `tick`, `timestamp`, `matchTimer`, and `zone_elapsed_ms`

### 8.2 Input Validation

**AC-MS-05 — Stale Input Discarded [automated]**
- Given: A player submits an `input_move` with `timestamp = serverTime - 200ms` (4 ticks stale; threshold is 150ms)
- When: The tick's Phase 2 runs
- Then: The input is discarded; the player's position does not change due to this input; `staleness_discard_count` metric increments by 1

**AC-MS-06 — Input Rate Limit Enforced [automated]**
- Given: A player submits 120 input events within a 1-second window (2× the `MAX_INPUTS_PER_SEC = 60` default)
- When: Phase 2 processes inputs for any tick within that window
- Then: All inputs from that player are discarded for those ticks; a rate-limit warning log is emitted with the player's ID and input count; the player's position does not change due to those discarded inputs

**AC-MS-07 — Ownership Validation [automated]**
- Given: A client authenticated as player A sends an `input_move` claiming `playerId = player_B`
- When: Phase 2 validates the input
- Then: The input is discarded; a security event log entry is written with `event: "PLAYER_ID_SPOOFING_ATTEMPT"`; no state change occurs for player B

**AC-MS-08 — Invalid Ability ID Rejected [automated]**
- Given: A player sends `input_ability { abilityId: "not_in_my_deck" }`
- When: Phase 2 validates the input
- Then: The input is discarded; a security event log entry is written with `event: "INVALID_ABILITY_ID"`; no ability effect is applied

### 8.3 Authoritative State Schema

**AC-MS-09 — HP Clamped to [0, maxHp] [automated]**
- Given: A player with 5 HP receives 10 damage
- When: The simulation step resolves
- Then: `player.hp === 0`; `player.isAlive === false`; HP is never negative

**AC-MS-10 — Position Clamped to Map Bounds [automated]**
- Given: A player at position (1.0, 50.0) with `safe_boundary_inset = 0.5` and `map.width = 40.0` sends a move input that would push them to x = 41.0
- When: The simulation step resolves
- Then: `player.position.x === 39.5` (clamped to `width - safe_boundary_inset`); no tick overrun from the clamp

**AC-MS-11 — Expired Status Effects Removed [automated]**
- Given: A player has a `{ effectId: "slowed", remainingMs: 50 }` status effect
- When: One tick (50ms) passes
- Then: The status effect is removed from `player.statusEffects`; the array does not contain the expired effect

**AC-MS-12 — Passive State Initialized Correctly [automated]**
- Given: A match is initialized with player using `character:colt`
- When: The match starts (tick 0)
- Then: `player.passiveState.chargedStacks` exists as an empty object `{}`; no null reference errors occur when the passive tick handler runs on tick 1

### 8.4 State Snapshot and Delta

**AC-MS-13 — Full Snapshot Contains Required Fields [automated]**
- Given: A match is active in FFA mode with a shrinking zone
- When: A `state_snapshot` is emitted (either periodic or on reconnect)
- Then: The payload includes `zone_elapsed_ms`, `zone.currentRadius`, `zone.targetRadius`, and the current state of all destructible obstacles; no required field is absent

**AC-MS-14 — Delta Contains Only Changed Fields [automated]**
- Given: In a given tick, only player A moves and no abilities fire
- When: The `state_delta` is emitted for that tick
- Then: The delta contains player A's updated `position`; all other player entries are absent; `matchTimer` and `zone_elapsed_ms` are present; the delta byte size is less than 20% of the equivalent full snapshot size

**AC-MS-15 — Full Snapshot on Reconnect [automated / manual]**
- Given: A player disconnects and reconnects within `RECONNECT_GRACE_PERIOD_S`
- When: The reconnecting socket emits `session_join_request`
- Then: The Match Server emits a full `state_snapshot` (not a delta) to that socket within 2 ticks (100ms); the snapshot includes `zone_elapsed_ms` and all obstacle states; the player's game client re-renders the correct state

### 8.5 Lag Compensation

**AC-MS-16 — Rewind Depth Correct for Player RTT [automated]**
- Given: Player A has `avgRTT = 120ms`; `TICK_INTERVAL_MS = 50ms`; `LAG_COMP_REWIND_LIMIT_MS = 200ms`
- When: Player A fires an ability and the server evaluates hit registration
- Then: The server rewinds exactly `floor(120 / 50) = 2` ticks; the collision check uses positions from tick `T - 2`

**AC-MS-17 — Rewind Capped at LAG_COMP_REWIND_LIMIT_MS [automated]**
- Given: Player A has `avgRTT = 350ms`; `LAG_COMP_REWIND_LIMIT_MS = 200ms`
- When: Player A fires an ability
- Then: The server rewinds `floor(200 / 50) = 4` ticks (not 7 ticks); the rewind does not exceed the limit

**AC-MS-18 — Hit Registered on Rewound Position [automated]**
- Given: Player B was at position (10, 10) at tick T-2 and moved to (15, 10) by tick T; player A fires an ability aimed at (10, 10) at tick T with RTT corresponding to a 2-tick rewind
- When: Hit registration runs
- Then: A hit is registered against player B (rewound position was in range); player B's current HP (at tick T) is decremented; player B's rewound HP is not used

### 8.6 Reconnect Recovery

**AC-MS-19 — Checkpoint Written Every 5 Seconds [automated]**
- Given: A match is running
- When: 15 seconds elapse (3 checkpoint intervals)
- Then: Redis key `match_checkpoint:{matchId}` has been written at least 3 times; the final write contains a `MatchState` with `tick >= 300` (15s × 20 ticks/s); the Redis key has TTL between 645s and 660s

**AC-MS-20 — Checkpoint Failure Does Not Stop Game Loop [automated]**
- Given: Redis is unavailable (simulated failure)
- When: A checkpoint write is attempted
- Then: The checkpoint failure is logged; the `CHECKPOINT_WRITE_FAILURE` metric increments; the game loop continues without interruption; the next tick fires within `TICK_INTERVAL_MS + 5ms` of the expected time

### 8.7 Match End

**AC-MS-21 — match_ended Signal on Win Condition [automated]**
- Given: A 1v1 Duel match where player A's HP reaches 0
- When: Phase 4 win condition evaluation runs
- Then: The evaluator returns `{ winnerId: player_B_id, reason: "last_standing" }`; `match_ended` is emitted to the Session Manager within the same tick; the game loop stops; no further `state_delta` events are emitted after `match_ended`

**AC-MS-22 — Max Duration Force-End [automated]**
- Given: `maxDurationS = 60` (test override); no player eliminated
- When: 60 seconds elapse
- Then: `matchState.matchTimer <= 0`; phase transitions to `"overtime"`; the evaluator is invoked with `forceResolve: true`; a `match_ended` signal is emitted with a valid result (including draw if no winner); the match ends within 2 ticks of the timer expiry

**AC-MS-23 — Zone Force-End Countdown Emitted [automated]**
- Given: FFA mode; the zone has reached its minimum radius; `final_hold_sec = 10`
- When: The countdown begins
- Then: `force_end_countdown { secondsRemaining: N }` is emitted exactly once per second for N = 10, 9, 8 ... 1; after `secondsRemaining = 0`, `match_ended` is emitted; the total number of `force_end_countdown` events is exactly 10

**AC-MS-24 — Graceful Redis Flush on Match End [automated]**
- Given: A match ends normally via win condition
- When: `match_ended` processing runs
- Then: The final `MatchState` is synchronously written to `match_checkpoint:{matchId}` (or the async write is awaited); the Redis key exists with correct content immediately after `match_ended` is sent to Session Manager

### 8.8 Edge Cases

**AC-MS-25 — All Players Disconnect — Match Abandoned [automated]**
- Given: All players disconnect simultaneously; `ALL_PLAYERS_DISCONNECTED_GRACE_MS = 5000ms`
- When: 5 seconds pass with no reconnect
- Then: The Match Server emits `match_abandoned { matchId, reason: "all_players_disconnected" }` to the Session Manager; the game loop stops; no `match_ended` signal is emitted

**AC-MS-26 — Win Condition Evaluator Exception — Retry and Force-End [automated]**
- Given: The registered `WinConditionEvaluator` throws an exception every time it is called
- When: `WIN_CONDITION_MAX_CONSECUTIVE_ERRORS = 10` consecutive tick failures occur
- Then: The Match Server force-ends the match with `result.reason = "evaluator_failure_force_end"`; the `WIN_CONDITION_EVALUATOR_ERROR` metric has been incremented 10 times; no unhandled exception propagates to the game loop

**AC-MS-27 — Heartbeat Continues on Session Manager Unavailability [automated]**
- Given: The Session Manager endpoint returns HTTP 503
- When: A heartbeat attempt is made
- Then: The failure is logged; a retry fires after `HEARTBEAT_RETRY_DELAY_MS`; the game loop continues without interruption; the next `state_delta` is emitted within normal tick timing

**AC-MS-28 — Input Flood Does Not Delay Tick [automated]**
- Given: One player sends 500 input events within a single tick window (200ms)
- When: Phase 1 drains the input queue and Phase 2 runs
- Then: The total tick duration does not exceed `TICK_INTERVAL_MS * 1.5 = 75ms`; the rate limit warning is logged; the flooding player's position does not change; other players are unaffected

---

*End of Document*
