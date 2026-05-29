# ADR-0009: Matchmaking Architecture (Redis Queues + Bracket Algorithm)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Network Programmer

## Summary

The Matchmaking Engine maintains two Redis sorted sets per game mode (one by `queuedAt`, one by MMR). A bracket algorithm runs every 2 seconds, scanning for player clusters within `maxSkillSpreadMMR` (300). When spread cannot be achieved, wait time widens the bracket by 50 MMR per 15 seconds. Bots backfill when a match cannot be formed within 45 seconds. This ADR defines the queue data structures, bracket algorithm, and match formation flow.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Networking / Core |
| **Knowledge Risk** | LOW — Redis sorted sets and Node.js setInterval patterns are within training data |
| **References Consulted** | `design/gdd/matchmaking-engine.md`, `design/gdd/session-manager.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm ioredis v5 API for ZRANGEBYSCORE atomic Lua script execution |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0004 (userId auth), ADR-0005 (Redis sorted set structure) |
| **Enables** | ADR-0012 (Session creation after match is formed) |
| **Blocks** | Matchmaking Engine implementation |
| **Ordering Note** | Must be Accepted before MatchmakingQueue.ts is written beyond scaffold |

## Context

### Problem Statement

Players queue for one of three game modes (1v1, 3v3, 8-player FFA) with different player counts and MMR requirements. Skill-based matchmaking must balance match quality (skill spread) against wait time. Bot backfill prevents infinite waits.

### Current State

`server/src/matchmaking/MatchmakingQueue.ts` is scaffolded. Redis connection exists in config.

### Constraints

- Three game modes: `duel_1v1` (2 players), `squad_3v3` (6 players), `ffa_8` (8 players)
- `maxSkillSpreadMMR` = 300 (remote-configurable via Content Catalog overlay)
- Solo queue at MVP; party queue requires party-presence system (VS milestone)
- Matchmaking runs as a `setInterval(pollMatches, 2000)` loop — not per-join
- Atomic dequeue via Redis Lua script to prevent duplicate match formation
- Players can cancel queue; `queue_cancel` after `match_found` is a no-op

### Requirements

- Dual sorted sets per mode: score = `queuedAt` (FIFO tiebreak) and score = MMR (skill filter)
- Bracket algorithm: find N players within `maxSkillSpreadMMR`; prefer earliest-queued
- Wait time escalation: widen bracket by 50 MMR per 15 seconds of wait
- Bot backfill: if wait > 45s and partial bracket, fill remaining slots with bots
- `dequeued` socket event emitted on cancel, timeout, or error with `reason` field
- Match formation is atomic — player cannot be double-matched

## Decision

Dual Redis sorted sets per mode, polled every 2 seconds. Bracket algorithm selects candidates by MMR range, then applies FIFO ordering for tiebreaks. Lua script atomically dequeues selected players and returns their IDs. Session Manager then creates the match.

### Architecture

```
REDIS:
  mm:queue:duel_1v1:time   ZADD score=unixMs  member=userId
  mm:queue:duel_1v1:mmr    ZADD score=mmr     member=userId
  (same pattern for squad_3v3, ffa_8)

MATCHMAKING ENGINE (setInterval every 2s):
  for each mode:
    candidates = ZRANGEBYSCORE mm:queue:{mode}:mmr (pivot - spread/2) (pivot + spread/2)
    if len(candidates) >= requiredPlayerCount:
      selected = pickOldest(candidates, requiredPlayerCount)  // sort by queuedAt score
      atomicDequeue(selected, mode)  // Lua script: ZREM both sets
      emit match_found to each player
      sessionManager.createSession(selected, mode)
    else if anyWaiting > 45s:
      botFill(candidates, requiredPlayerCount)
      → same path as above with bot IDs filling gaps

WAIT ESCALATION:
  spread = maxSkillSpreadMMR + floor(waitSeconds / 15) * 50
  applied per-candidate based on their own queue entry time

PLAYER ENQUEUE:
  ZADD mm:queue:{mode}:time score=Date.now() member=userId
  ZADD mm:queue:{mode}:mmr  score=playerMMR  member=userId
  emit dequeued with reason='match_found' suppressed until match_found actually sent

PLAYER CANCEL:
  ZREM mm:queue:{mode}:time userId
  ZREM mm:queue:{mode}:mmr  userId
  emit dequeued { reason: 'player_cancelled' }
  // if match_found already sent: no-op (boolean flag on socket)
```

### Key Interfaces

```typescript
interface IMatchmakingQueue {
  enqueue(userId: string, mode: GameMode, mmr: number): Promise<void>;
  dequeue(userId: string, reason: DequeueReason): Promise<void>;
  pollMatches(): Promise<void>;  // called by setInterval every 2000ms
}

type DequeueReason = 'match_found' | 'player_cancelled' | 'timeout' | 'queue_error';
type GameMode = 'duel_1v1' | 'squad_3v3' | 'ffa_8';

const REQUIRED_PLAYERS: Record<GameMode, number> = {
  duel_1v1: 2,
  squad_3v3: 6,
  ffa_8: 8,
};

const MAX_WAIT_BEFORE_BOTFILL_MS = 45_000;
const MMR_WIDEN_PER_15S = 50;
const POLL_INTERVAL_MS = 2_000;
```

### Implementation Guidelines

- Lua script for atomic dequeue: `ZREM mm:queue:{mode}:time {userIds...}` + `ZREM mm:queue:{mode}:mmr {userIds...}` in a single script — prevents partial dequeue if server crashes mid-match-formation
- `pivot` MMR for bracket: median of all candidates in the MMR sorted set scan range
- Bot IDs are generated as `bot:{uuid}` — never stored in Redis queue; injected at match formation time
- `pollMatches()` must complete within 2000ms — if Redis is slow, skip this poll cycle and log a warning
- `dequeued` event with `reason: 'match_found'` is emitted at the same time as `match_found` — client uses `match_found` to transition screen; `dequeued` is for cleanup

## Alternatives Considered

### Alternative 1: Single Sorted Set (MMR only)

- **Description**: One sorted set per mode, keyed by MMR. Scan for clusters.
- **Pros**: Simpler data structure.
- **Cons**: No FIFO tiebreaking — equal-MMR players have no ordering guarantee; a player could wait indefinitely while newer players queue with better MMR luck.
- **Rejection Reason**: Dual sorted sets give both MMR filtering (via `mm:{mode}:mmr`) and FIFO ordering (via `mm:{mode}:time`).

### Alternative 2: In-Memory Queue (No Redis)

- **Description**: Hold queues in Node.js memory.
- **Pros**: No Redis round-trip; simpler implementation.
- **Cons**: Queue lost on server restart; cannot scale to multiple Node.js instances.
- **Rejection Reason**: Redis queues survive server restarts and support horizontal scaling (future requirement).

## Consequences

### Positive

- Atomic Lua dequeue prevents double-matching
- Wait escalation ensures players never wait indefinitely
- Bot backfill means match always forms within 45s regardless of player count

### Negative

- Two Redis sorted sets per mode → 6 sorted sets total; must be managed as a pair (dequeue from both atomically)
- Bot players reduce competitive experience; acceptable at MVP; monitored by DAU/match metrics

### Neutral

- `pollMatches()` fires every 2s; worst-case wait before being matched is queue time + 2s

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Redis Lua script failure leaves player in queue | Low | Medium | Heartbeat check: any player in queue >120s without match_found → dequeue with reason='queue_error' |
| Queue corruption (player disconnect before dequeue) | Medium | Low | Socket disconnect handler calls `dequeue(userId, 'player_cancelled')` |
| Bracket algorithm too slow under high queue volume | Low | Medium | ZRANGEBYSCORE is O(log N + M); acceptable for expected queue sizes at MVP |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Match formation latency | — | ≤2s (one poll cycle) | 4s |
| Redis ZADD (enqueue) | — | ≤2ms | 5ms |
| Redis ZRANGEBYSCORE (bracket scan) | — | ≤5ms | 20ms |

## Migration Plan

New project.

**Rollback plan**: Replace Redis queues with in-memory arrays (MVP only) if Redis becomes unavailable.

## Validation Criteria

- [ ] Two players with MMR within 300 are matched within 4 seconds
- [ ] `queue_cancel` after `match_found` → player still enters match (no-op cancel)
- [ ] Player disconnects while queuing → removed from both sorted sets
- [ ] Bot backfill triggers after 45s for FFA with <8 human players
- [ ] Lua dequeue script is atomic: two simultaneous polls cannot select the same player

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/matchmaking-engine.md` | Matchmaking | Dual Redis sorted sets per mode | `mm:queue:{mode}:time` + `mm:queue:{mode}:mmr` defined |
| `design/gdd/matchmaking-engine.md` | Matchmaking | maxSkillSpreadMMR = 300 | Bracket algorithm uses this value; remote-configurable via catalog overlay |
| `design/gdd/matchmaking-engine.md` | Matchmaking | Bot backfill after 45s | `MAX_WAIT_BEFORE_BOTFILL_MS = 45_000` |
| `design/gdd/lobby.md` | Lobby | dequeued event with reason field | `DequeueReason` enum defined; emitted in all cancel/timeout/error paths |

## Related

- ADR-0005: Redis sorted set infrastructure defined here
- ADR-0012: Session Manager creates the match session after match formation
- ADR-0002: `match_found` and `dequeued` socket events defined in transport ADR
