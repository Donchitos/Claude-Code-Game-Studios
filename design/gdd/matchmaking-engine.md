# Matchmaking Engine — Game Design Document
> **System**: Matchmaking Engine
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

The Matchmaking Engine is the central coordination layer that takes players from the "ready to play" state to the threshold of a live session. It owns exactly four responsibilities:

**Queue Management** — Each of the three game modes (1v1 Duel, 3v3 Squad Brawl, 8-player FFA) has its own dedicated Redis sorted-set queue. The engine handles enqueue, dequeue, expiry, and all concurrent-access guards. It is the single source of truth for who is waiting and since when.

**Skill-Based Matching Algorithm** — Given players in a queue, the engine evaluates all candidates in each tick and forms the best available match within the current skill bracket. The bracket widens over time to trade quality for speed, with a hard ceiling that prevents extreme mismatches regardless of wait time.

**Match Composition** — Once a candidate group is selected, the engine applies mode-specific composition rules: closest-MMR pairing for 1v1, interleaved MMR team assignment for 3v3, and sort-by-wait-time grouping (with optional bot fill) for FFA.

**Mode Routing** — After composition, the engine selects a map from the eligible pool for the mode, assembles the final `createSession` call arguments, and hands off to Session Manager. It does not manage the session itself after that point.

### What the Matchmaking Engine Does NOT Own

- MMR calculation and rank tier assignment → MMR/Ranked System
- Session lifecycle (start, tick, end) → Session Manager
- Lobby UI state and visual queue position display → Lobby & Team Formation UI
- Match flow transitions post-match-found → Match Flow
- Bot AI behavior → Bot System (future tier)
- Party formation and party queue → VS-tier (post-MVP)

### MVP Scope

Solo queue only. All three game modes are in scope. Party queue, cross-region matchmaking, and ranked-vs-casual queue splits are explicitly deferred to post-MVP.

---

## 2. Player Fantasy

### The Promise

Players want to feel that every match was earned — that they landed in a lobby of roughly equal skill, that the wait was short enough to stay engaged, and that the system respected their time. A great matchmaking experience is invisible: the player clicks "Play," counts down from ten, and finds themselves in a fair fight. They should never have to think about the system that made it happen.

### The Tension

There is a fundamental conflict at the heart of matchmaking: **quality versus speed**. A perfectly fair match requires a large player pool and patient waiting. A fast match requires accepting whoever is available right now. On mobile, where sessions run 3–10 minutes and players queue in spare moments (commute, break, between tasks), waiting longer than 60 seconds breaks the context that made them want to play in the first place.

Players tolerate a moderate skill mismatch far better than they tolerate staring at a "Searching…" spinner. The frustration tipping point is asymmetric: a 15% MMR mismatch is noticed but forgiven; a 90-second queue with no feedback feels broken.

### Design Responses

- **Transparency over ambiguity**: Push live queue position and estimated wait time so players feel the system is working for them, not silently failing.
- **Graceful degradation**: When the queue is shallow, widen the bracket progressively rather than abruptly. Players should feel the system tried before giving up.
- **Clear exit contract**: A queue timeout is not a failure — it is the system being honest. The `queue_timeout` event tells the player exactly what happened, and re-queuing is immediate with zero friction.
- **Bot fill as explicit fallback**: When enabled, bot fill is visible in the FFA lobby as named bot slots. Players should know they are facing bots; hidden bot opponents erode trust.

---

## 3. Detailed Rules

### 3.1 Queue Model

Each game mode has exactly one Redis sorted set. Key schema:

| Mode | Redis Key |
|------|-----------|
| 1v1 Duel | `mm:queue:duel` |
| 3v3 Squad Brawl | `mm:queue:squad` |
| 8-player FFA | `mm:queue:ffa` |

**Queue Entry Schema** (stored as JSON string in the sorted set value field; score = `queuedAt` Unix timestamp in milliseconds):

```json
{
  "playerId": "uuid",
  "mmr": 1150,
  "queuedAt": 1748300000000,
  "provisional": false
}
```

The sorted-set score is `queuedAt` so iteration by wait time is O(log N). MMR-range queries use `ZRANGEBYSCORE` on a secondary index (see §3.4).

**Secondary MMR Index** (parallel sorted set for MMR-ordered lookups):

| Mode | Redis Key |
|------|-----------|
| 1v1 Duel | `mm:mmr:duel` |
| 3v3 Squad Brawl | `mm:mmr:squad` |
| 8-player FFA | `mm:mmr:ffa` |

Score in the MMR index = player MMR (integer). Both sets are written atomically on queue entry and removed atomically on dequeue using a Lua script.

---

### 3.2 Skill Bracket Expansion

The skill bracket controls the MMR range within which two players are considered eligible to be matched.

**Initial bracket** (at queue entry, t = 0):
```
bracket(t=0) = ± maxSkillSpreadMMR  (default ±300 MMR)
```

**Expansion** begins after `BRACKET_EXPANSION_START_SEC` seconds of waiting. Before that point the bracket stays fixed at the initial value, prioritizing match quality.

**Expanded bracket** (for t > `BRACKET_EXPANSION_START_SEC`):
```
bracket(t) = ± (maxSkillSpreadMMR + BRACKET_EXPANSION_RATE × (t − BRACKET_EXPANSION_START_SEC))
```

**Hard ceiling** regardless of wait time:
```
bracket(t) ≤ ± 600 MMR
```

The ceiling is reached when:
```
t_ceiling = BRACKET_EXPANSION_START_SEC + (600 − maxSkillSpreadMMR) / BRACKET_EXPANSION_RATE
```

At `queueTimeoutSec` (default 60s), the player is dequeued whether or not a match was found. The bracket at timeout equals:
```
bracket(queueTimeoutSec) = min(600, maxSkillSpreadMMR + BRACKET_EXPANSION_RATE × (queueTimeoutSec − BRACKET_EXPANSION_START_SEC))
```

**Provisional player handling**: Players with fewer than 30 career matches are flagged `provisional: true` in their queue entry. The bracket for provisional players is expanded by an additional multiplier of 1.5× on the computed bracket (before applying the hard ceiling). This prevents provisional players from experiencing excessive queue times due to an unreliable initial MMR.

---

### 3.3 Match Composition Rules

#### 3.3.1 1v1 Duel

- Required players: exactly 2.
- Algorithm: Identify the player in the queue with the longest wait time (`oldest_player`). Compute their current bracket. Find the player in `mm:mmr:duel` with the closest MMR to `oldest_player.mmr` who falls within the bracket (excluding `oldest_player` themselves). If found, form the match with those two players.
- Tiebreak (equal MMR distance): prefer the player with the longer wait time.

#### 3.3.2 3v3 Squad Brawl

- Required players: exactly 6 (balanced teams of 3). Partial fills are not allowed at MVP (no bot fill for Squad).
- Algorithm: Collect all players within the queue whose MMR falls within the bracket of the oldest waiting player, up to a maximum candidate pool of 12. Sort the candidate pool by MMR ascending. Select the 6 best-balanced players using the interleave assignment:
  - Position 1 (highest MMR) → Team A
  - Position 2 → Team B
  - Position 3 → Team A
  - Position 4 → Team B
  - Position 5 → Team A
  - Position 6 (lowest MMR of the 6) → Team B
- This snake-draft interleave minimizes the sum-of-MMR delta between the two teams.
- If the candidate pool has fewer than 6 eligible players: hold. Do not form a partial match. Continue waiting.
- Odd-number hold rule: if exactly 5 eligible candidates exist (a balanced 6-player group is impossible), the engine holds and waits for additional players or bracket expansion to bring in a 6th.

#### 3.3.3 8-Player FFA

- Required players: 8 (or ≥ 3 humans if `botFillEnabled = true` and the queue times out).
- Normal path: Collect the 8 players in the queue who have waited the longest (primary sort: `queuedAt` ascending; secondary sort: MMR descending as a tiebreak for simultaneous entries). The skill bracket is not enforced as a hard gate for FFA — it is used as a soft preference. If 8 players are available within bracket, prefer them. If not, expand to the full queue.
- Bot fill path: Triggered only when ALL of the following are true:
  1. `botFillEnabled = true` (Remote Config)
  2. The queue has ≥ 3 human players
  3. The oldest queued player has been waiting ≥ `queueTimeoutSec` seconds
  4. Total human count in the queue is < 8
  - Under these conditions, fill remaining slots (up to 8 total) with bot stubs. A bot stub is a synthetic player entry: `{ playerId: "bot-<uuid>", mmr: <avg_human_mmr>, isBot: true }`. Bot MMR is set to the average MMR of the human players to maintain approximate fairness.
- If `botFillEnabled = false` and the queue has fewer than 8 players at any given tick: hold.
- Minimum FFA (no bot fill, exactly 3 players, no 4th arriving): hold until timeout, then dequeue all three with `queue_timeout`. They are not force-matched into a 3-player FFA.

---

### 3.4 Matchmaking Loop

The server runs a single-threaded (per Node.js process) polling loop on a fixed interval:

```
MATCHMAKING_TICK_MS = 500  (default; see §7)
```

**Per-tick execution order:**

1. **Read Remote Config snapshot** — fetch current values of `queueTimeoutSec`, `maxSkillSpreadMMR`, `botFillEnabled`, `soloQueueEnabled`. If `soloQueueEnabled = false`, skip all queue processing and return early.
2. **Expire timed-out entries** — for each queue, find all entries where `(now - queuedAt) >= queueTimeoutSec * 1000`. Dequeue them atomically (Lua script removes from both sorted sets). Emit `queue_timeout` Socket.io event to each affected player's socket room.
3. **Evaluate 1v1 queue** — attempt to form as many 1v1 matches as possible in a single tick (greedy: keep forming matches until no eligible pair remains).
4. **Evaluate 3v3 queue** — attempt to form as many 3v3 matches as possible.
5. **Evaluate FFA queue** — attempt to form as many FFA matches as possible (including bot fill check).
6. **For each formed match** — run map selection, call `Session Manager.createSession(players, mode, mapId)`, emit `match_found` Socket.io event to all matched players.
7. **Push queue status updates** — for all remaining (unmatched) players, emit `queue_status` events with updated estimated wait time and position.

The loop is greedy within a tick: it does not reserve players across ticks. A player not matched in tick N is re-evaluated in tick N+1 with an updated (potentially wider) bracket.

---

### 3.5 Queue Entry and Exit

#### Entering the Queue

**Endpoint**: `POST /v1/matchmaking/queue`

**Request body**:
```json
{
  "mode": "duel_1v1" | "squad_3v3" | "ffa_8"
}
```

**Server-side validation (in order)**:
1. Authenticate player (JWT).
2. Fetch player profile (MMR, career match count, provisional status).
3. Check `soloQueueEnabled` Remote Config flag — reject with HTTP 403 if false.
4. Check if player is already in any queue (atomic Redis check across all three queue keys) — reject with HTTP 409 `"already_in_queue"` if true.
5. Check if player has an active session (Redis key `session:player:<playerId>`) — reject with HTTP 409 `"active_session_exists"` if true.
6. Write queue entry atomically to both sorted sets (Lua script).
7. Return HTTP 200 with `{ queueId, estimatedWaitSec }`.

#### Leaving the Queue

**Endpoint**: `DELETE /v1/matchmaking/queue`

**Behavior**: Remove the calling player from whichever queue they occupy (if any). No-op if not in queue. Returns HTTP 200 regardless.

#### Socket.io Events (server → client)

| Event | Payload | Trigger |
|-------|---------|---------|
| `queue_status` | `{ position, estimatedWaitSec, queueDepth }` | Every tick for all queued players |
| `match_found` | `{ sessionId, mode, mapId, players[], yourTeam }` | When match is formed |
| `queue_timeout` | `{ reason: "timeout", canRequeue: true }` | When player is dequeued after `queueTimeoutSec` |
| `dequeued` | `{ reason: "match_found" \| "player_cancelled" \| "timeout" \| "queue_error" }` | Emitted whenever a player is removed from the queue for any reason; `lobby.md §3.10/§5.5` depends on this event to update lobby UI state |

The `position` field in `queue_status` is the player's rank in the queue by wait time (1 = longest waiting). This is their priority position, not a guarantee of match order.

---

### 3.6 Map Selection

Map selection is internal to the Matchmaking Engine (not a separate system at MVP). Each mode has an eligible map pool defined in a static configuration table (seeded from Remote Config or a hardcoded default list at MVP).

**Selection algorithm**: uniform random draw from the eligible pool for the matched mode. No recent-map exclusion at MVP. The selected `mapId` is passed directly to `Session Manager.createSession()`.

---

## 4. Formulas

### 4.1 Bracket Expansion Formula

```
let t = seconds since player entered queue

if t <= BRACKET_EXPANSION_START_SEC:
    spread(t) = maxSkillSpreadMMR

else:
    expanded = maxSkillSpreadMMR + BRACKET_EXPANSION_RATE * (t - BRACKET_EXPANSION_START_SEC)
    spread(t) = min(expanded, 600)

For provisional players:
    spread(t) = min(spread(t) * 1.5, 600)
```

**Default constants** (tunable; see §7):
- `maxSkillSpreadMMR` = 300 (Remote Config, Cold)
- `BRACKET_EXPANSION_START_SEC` = 15
- `BRACKET_EXPANSION_RATE` = 10 MMR/sec
- Hard ceiling = 600 MMR

**Example progression** (default values, non-provisional):

| Wait Time (s) | Bracket Spread |
|---------------|----------------|
| 0–15          | ±300 MMR       |
| 20            | ±350 MMR       |
| 30            | ±450 MMR       |
| 45            | ±600 MMR       |
| 60 (timeout)  | ±600 MMR       |

---

### 4.2 Estimated Wait Time Formula

Estimated wait time is a smoothed rolling estimate, updated each tick:

```
raw_wait = (TARGET_QUEUE_DEPTH / max(1, current_queue_depth)) * historical_avg_match_interval_sec

smoothed_wait(t) = α * raw_wait + (1 - α) * smoothed_wait(t-1)
```

Where:
- `TARGET_QUEUE_DEPTH` = mode-specific minimum player count (2 for duel, 6 for squad, 8 for ffa)
- `current_queue_depth` = current number of players in the mode's queue
- `historical_avg_match_interval_sec` = rolling 5-minute average of seconds between successful match formations for this mode (stored in Redis as a rolling counter; initialized to 30s at cold start)
- `α` = `WAIT_SMOOTHING_ALPHA` (default 0.2; see §7) — lower values produce more stable but slower-reacting estimates

**Clamp**: `smoothed_wait` is clamped to `[1, queueTimeoutSec]` before being returned to the client.

---

### 4.3 3v3 Team Balance Score

Used to validate (and optionally optimize) the final team assignment:

```
Team A MMR sum = Σ mmr(player) for players in Team A
Team B MMR sum = Σ mmr(player) for players in Team B

balance_delta = |Team A MMR sum - Team B MMR sum|

balance_score = 1 - (balance_delta / (6 * maxSkillSpreadMMR))
```

A `balance_score` of 1.0 indicates perfectly equal teams. A score ≥ 0.85 is considered acceptable. The snake-draft interleave algorithm (§3.3.2) is designed to consistently produce balance scores above 0.90 for players within the same MMR bracket.

This formula is computed after match formation and logged for telemetry. It is not used as a gate to reject matches at MVP.

---

### 4.4 FFA Bot Fill Threshold

```
bot_fill_triggered = (
    botFillEnabled == true
    AND human_count_in_queue >= 3
    AND oldest_player_wait_sec >= queueTimeoutSec
    AND human_count_in_queue < 8
)

bots_to_add = 8 - human_count_in_queue  (if bot_fill_triggered)

bot_mmr = round(mean(mmr(p) for p in human_players))
```

Bot player stubs created with `isBot: true` are passed to `Session Manager.createSession()` in the players array. Session Manager is expected to handle bot entries distinctly from human players (routing to AI controllers rather than socket connections).

---

## 5. Edge Cases

### EC-01: Player Disconnects While in Queue

**Scenario**: Player's Socket.io connection drops after successfully entering a queue.

**Handling**: The server's Socket.io `disconnect` event handler checks if the disconnecting socket's `playerId` exists in any queue. If found, it dequeues the player atomically (Lua script). No `queue_timeout` event is emitted (socket is gone). The player's queue entry is cleaned up within one Socket.io heartbeat interval (default 10s). If the player reconnects before the heartbeat fires and the entry was not yet cleaned, the reconnection handshake re-associates their socket to the existing queue entry and resumes status events.

**Risk**: A very brief disconnect-reconnect cycle (< heartbeat window) may result in the player being dequeued and needing to re-queue manually. This is acceptable at MVP.

---

### EC-02: Player Already in an Active Session Tries to Queue

**Scenario**: Player has session key `session:player:<playerId>` in Redis (set by Session Manager) and calls `POST /v1/matchmaking/queue`.

**Handling**: Queue entry validation step 5 (§3.5) reads the Redis key. If it exists, return HTTP 409 with body `{ error: "active_session_exists", message: "You are already in a match." }`. The client Lobby UI should suppress the queue button when an active session is detected, but this server-side check is the authoritative guard.

---

### EC-03: Queue Entry While `soloQueueEnabled = false`

**Scenario**: Remote Config flag `matchmaking.soloQueueEnabled` is set to `false` (e.g., during maintenance or a live-ops event).

**Handling**: Queue entry validation step 3 (§3.5) rejects with HTTP 403 `{ error: "queue_disabled", message: "Matchmaking is currently unavailable." }`. Players already in the queue at the time the flag flips are NOT dequeued mid-wait — the flag only gates new entries. On the next matchmaking loop tick, the loop reads the flag, skips all queue evaluation, and does not form new matches. Already-queued players will eventually time out and receive `queue_timeout`. This creates a clean, gradual drain rather than a hard flush.

**Alternative considered**: Flush all queues immediately on flag flip. Rejected — aggressive and could cause thundering-herd re-queue attempts when the flag re-enables.

---

### EC-04: Odd Number of Players in 3v3 Queue (Cannot Form Balanced 6)

**Scenario**: Squad queue has exactly 5 eligible players within bracket.

**Handling**: The engine cannot form a balanced 6-player match. It holds all 5 players in queue. On the next tick, the bracket may have expanded to include a 6th player from outside the current bracket. Alternatively, a new player entering the queue may bring the count to 6. No partial match is formed, and no special event is sent to players — their `queue_status` events continue normally with updated estimated wait times.

**Risk**: If the queue stabilizes at exactly 5 players with no new entries and all 5 time out simultaneously, all 5 receive `queue_timeout`. This is correct behavior.

---

### EC-05: Exactly 3 FFA Players, Bot Fill Disabled, No 4th Arrives

**Scenario**: FFA queue has exactly 3 human players. `botFillEnabled = false`. No 4th player joins before all three time out.

**Handling**: The engine holds. No 3-player FFA match is created (minimum is 8 without bots, or ≥ 3 with bots when bot fill is enabled). When the oldest player's wait time hits `queueTimeoutSec`, all three are dequeued and receive `queue_timeout` with `{ canRequeue: true }`. The engine does not batch-dequeue all three simultaneously — each is evaluated independently per their own `queuedAt`. However, in practice three players who queued at similar times will time out within the same few ticks of each other.

---

### EC-06: Race Condition — Two Ticks Both Try to Match the Same Player

**Scenario**: Due to clock drift or a future multi-process deployment, two matchmaking loop ticks (or two server instances) simultaneously select the same player for different matches.

**Handling**: The Matchmaking Engine's dequeue operation uses a Redis Lua script that performs an atomic `ZREM` on both the time-sorted and MMR-sorted sets in a single script. If `ZREM` returns 0 (player not present), the match formation is aborted for that player. The match may be re-attempted in the next tick with the remaining players.

At MVP (single Node.js process), this race is not possible within a single event loop tick. For multi-process deployments (future), the Lua script is the correct backstop. Additionally, Session Manager's `createSession` uses a Redis `NX` (set-if-not-exists) Lua script keyed to `session:player:<playerId>` — even if two match formations slip through, only one session is created per player.

---

### EC-07: Matchmaking Tick Overlap

**Scenario**: A matchmaking tick takes longer than `MATCHMAKING_TICK_MS` to execute (e.g., Redis latency spike), causing the next tick to fire before the previous completes.

**Handling**: The loop is implemented with `setTimeout` (not `setInterval`). The next tick is scheduled only after the current tick's async work fully resolves. This prevents overlapping tick execution. If a tick takes 3× the normal duration, the effective tick rate degrades gracefully rather than spawning concurrent tick evaluations.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (Matchmaking Engine Consumes)

| System | Data / API Used | Coupling Notes |
|--------|----------------|----------------|
| **MMR / Ranked System** | Player MMR value, provisional flag (career match count < 30), rank tier | Read at queue entry from Player Profile cache. Matchmaking does not call MMR system directly; it reads the MMR value stored on the player profile. MMR is authoritative in the MMR system; Matchmaking treats it as read-only input. |
| **Player Profile** | `GET /v1/players/:id/profile` — returns `{ mmr, careerMatchCount, ... }` | Called once per queue entry. Must be available; queue entry is rejected with HTTP 503 if unavailable. |
| **Remote Config** | `matchmaking.soloQueueEnabled`, `matchmaking.queueTimeoutSec`, `matchmaking.maxSkillSpreadMMR`, `matchmaking.botFillEnabled` | Hot keys (`queueTimeoutSec`) re-read every tick. Cold keys read at service startup and cached until service restart. |
| **Session Manager** | `createSession(players: PlayerStub[], mode: string, mapId: string): Promise<{ sessionId }>` | Called once per formed match. Failure (e.g., player already has session) causes Matchmaking to discard the match attempt and return affected non-conflicting players to queue. |

### 6.2 Downstream Dependents (Consume Matchmaking Engine)

| System | How It Consumes Matchmaking | Notes |
|--------|---------------------------|-------|
| **Lobby & Team Formation UI** | Calls `POST /v1/matchmaking/queue` to enter; `DELETE` to leave. Receives `queue_status`, `match_found`, `queue_timeout`, `dequeued` Socket.io events. | UI is responsible for rendering queue spinner, position, and estimated wait. Matchmaking pushes data; UI does not poll. The `dequeued` event is the authoritative signal for all queue-exit transitions (see `lobby.md §3.10/§5.5`). |
| **Match Flow** | Listens for `match_found` event (relayed from Matchmaking via Session Manager's session-created event). Uses `sessionId` to transition player into match experience. | Match Flow does not call Matchmaking directly. The session creation by Session Manager is the trigger for Match Flow. |
| **Session Manager** | Receives `createSession` call from Matchmaking. | Session Manager is both a dependency (Matchmaking calls it) and an indirect downstream consumer (its created sessions trigger Match Flow). |

---

## 7. Tuning Knobs

All constants below are tunable without a code deploy unless marked "Code constant." Remote Config keys use the `matchmaking.*` namespace.

| Knob | Location | Default | Description | Notes |
|------|----------|---------|-------------|-------|
| `maxSkillSpreadMMR` | Remote Config (Cold) | 300 | Initial MMR bracket half-width. Smaller = fairer matches but longer waits. | Changing this is a Cold config change; requires service restart to take effect. |
| `BRACKET_EXPANSION_START_SEC` | Code constant | 15 | Seconds of waiting before bracket begins to widen. | Increase to prioritize match quality for the first N seconds. |
| `BRACKET_EXPANSION_RATE` | Code constant | 10 MMR/sec | How fast the bracket grows after expansion starts. | At 10 MMR/sec with a 300 base and 15s start, the cap of 600 is hit at t=45s. |
| `BRACKET_HARD_CEILING_MMR` | Code constant | 600 | Maximum bracket half-width regardless of wait time. | Should not exceed one full rank tier gap (~300 MMR) above the initial spread. |
| `queueTimeoutSec` | Remote Config (Hot) | 60 | Seconds before a queued player is dequeued and notified. | Hot key; takes effect on the next tick after config refresh without restart. |
| `botFillEnabled` | Remote Config (Cold) | false | Enables bot fill for FFA when queue is shallow. | Only affects FFA at MVP. Requires restart to activate. |
| `MATCHMAKING_TICK_MS` | Code constant | 500 | Polling interval of the matchmaking loop (milliseconds). | Lower values = more responsive matching but higher Redis load. Minimum recommended: 200ms. |
| `BOT_FILL_MIN_HUMANS` | Code constant | 3 | Minimum human players needed in FFA queue to trigger bot fill. | Raising this (e.g., to 5) produces more human-dominant lobbies at the cost of more timeouts. |
| `WAIT_SMOOTHING_ALPHA` | Code constant | 0.2 | EMA weight for estimated wait time (0 = fully smoothed, 1 = raw). | Lower values reduce jitter in displayed wait time; higher values react faster to queue depth changes. |
| `PROVISIONAL_BRACKET_MULTIPLIER` | Code constant | 1.5 | Bracket expansion multiplier for provisional players. | Higher values give provisional players faster matches at the cost of wider MMR spreads. |

---

## 8. Acceptance Criteria

### AC-01: Bracket Logic — Initial Spread Respected

```
GIVEN a player with MMR 1000 enters the duel queue
AND maxSkillSpreadMMR is 300
AND the player has been waiting for 0 seconds

WHEN the matchmaking loop evaluates the queue

THEN the player is only eligible to be matched with players in MMR range [700, 1300]
AND no match is formed with a player outside that range
```

---

### AC-02: Bracket Logic — Expansion After Start Delay

```
GIVEN a player with MMR 1000 enters the duel queue
AND maxSkillSpreadMMR is 300
AND BRACKET_EXPANSION_START_SEC is 15
AND BRACKET_EXPANSION_RATE is 10

WHEN the player has been waiting for 25 seconds (10 seconds past expansion start)

THEN the computed bracket is ±(300 + 10*10) = ±400 MMR
AND the player is eligible to be matched with players in MMR range [600, 1400]
```

---

### AC-03: Bracket Logic — Hard Ceiling Enforced

```
GIVEN a player with MMR 1000 has been waiting for 60 seconds
AND the computed expanded bracket would be ±600 MMR or greater

WHEN the matchmaking loop evaluates the queue

THEN the bracket is clamped to ±600 MMR
AND a player with MMR 400 (600 MMR below) is NOT eligible
AND a player with MMR 401 IS eligible
```

---

### AC-04: Bracket Logic — Provisional Player Wider Bracket

```
GIVEN a player with MMR 1000 and careerMatchCount = 10 (provisional) enters the duel queue
AND the player has been waiting 20 seconds
AND non-provisional bracket at t=20s is ±350 MMR
AND PROVISIONAL_BRACKET_MULTIPLIER is 1.5

WHEN the matchmaking loop evaluates the queue

THEN the provisional player's bracket is ±min(350*1.5, 600) = ±525 MMR
AND the player is eligible to match with players in MMR range [475, 1525]
```

---

### AC-05: Team Balancing — Snake-Draft Produces Balanced Teams

```
GIVEN 6 players with MMRs [1200, 1150, 1100, 1050, 1000, 950] enter the squad queue
AND all are within each other's bracket

WHEN a 3v3 match is formed using snake-draft interleave

THEN Team A receives players with MMR [1200, 1100, 1000] (positions 1, 3, 5) → sum = 3300
AND Team B receives players with MMR [1150, 1050, 950] (positions 2, 4, 6) → sum = 3150
AND balance_delta = |3300 - 3150| = 150
AND balance_score = 1 - (150 / (6 * 300)) = 1 - 0.0833 = 0.917 (above 0.85 threshold)
```

---

### AC-06: Timeout — Player Dequeued and Notified at queueTimeoutSec

```
GIVEN a player enters the duel queue
AND queueTimeoutSec is 60

WHEN 60 seconds elapse without a match being formed

THEN the player is removed from the Redis queue (both sorted sets)
AND a queue_timeout Socket.io event is emitted to the player with { canRequeue: true }
AND the player is NOT matched in any subsequent tick
AND the player MAY immediately re-queue with a fresh POST /v1/matchmaking/queue
```

---

### AC-07: Bot Fill — Triggered Correctly for FFA

```
GIVEN botFillEnabled is true
AND the FFA queue contains exactly 4 human players
AND the oldest player has been waiting >= queueTimeoutSec seconds

WHEN the matchmaking loop evaluates the FFA queue

THEN a match is formed with the 4 human players
AND 4 bot stubs are generated with isBot: true
AND bot_mmr = round(mean MMR of the 4 human players)
AND Session Manager.createSession is called with 8 total players (4 human + 4 bot)
AND all 4 human players receive a match_found event
```

---

### AC-08: Bot Fill — NOT Triggered When Below Minimum Humans

```
GIVEN botFillEnabled is true
AND the FFA queue contains exactly 2 human players
AND the oldest player has been waiting >= queueTimeoutSec seconds

WHEN the matchmaking loop evaluates the FFA queue

THEN NO match is formed
AND NO bot stubs are generated
AND both players receive queue_timeout events (dequeued after timeout)
```

---

### AC-09: Race Condition — Duplicate Session Prevented

```
GIVEN player A is in the duel queue
AND player A is simultaneously selected for matches M1 and M2 (simulated race)

WHEN Session Manager.createSession is called for M1 (succeeds, NX key set)
AND Session Manager.createSession is called for M2 (NX key already exists, returns error)

THEN only session M1 is created
AND player A appears in only one match
AND the other player in M2 (player B) is returned to the queue for re-matching
```

---

### AC-10: Concurrent Queue Guard — Player Cannot Enter Two Queues

```
GIVEN player A is already in the duel_1v1 queue

WHEN player A calls POST /v1/matchmaking/queue with mode "ffa_8"

THEN the server returns HTTP 409 with error "already_in_queue"
AND player A's duel queue entry is unaffected
AND player A is NOT added to the FFA queue
```

---

### AC-11: Queue Disabled — Entry Rejected

```
GIVEN soloQueueEnabled Remote Config flag is false

WHEN any player calls POST /v1/matchmaking/queue for any mode

THEN the server returns HTTP 403 with error "queue_disabled"
AND no queue entry is created
AND players already in queue at the time of the flag change are NOT dequeued immediately
AND those existing queue entries will eventually expire via normal timeout
```

---

### AC-12: Active Session Guard — Re-queue Rejected

```
GIVEN player A has an active session (Redis key session:player:<playerId> exists)

WHEN player A calls POST /v1/matchmaking/queue

THEN the server returns HTTP 409 with error "active_session_exists"
AND no queue entry is created
```

---

### AC-13: Disconnect Cleanup — Queue Entry Removed on Socket Disconnect

```
GIVEN player A is in the squad queue
AND player A's Socket.io connection disconnects

WHEN the server processes the disconnect event for player A's socket

THEN player A's entry is atomically removed from mm:queue:squad and mm:mmr:squad
AND player A does not appear in subsequent tick evaluations
AND no match_found event is emitted for player A
```

---

*End of Document*
