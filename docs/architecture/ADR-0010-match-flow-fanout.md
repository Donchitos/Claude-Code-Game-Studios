# ADR-0010: Match Flow Fan-Out Pattern (Model B, Promise.allSettled)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Lead Programmer

## Summary

When a match ends, Match Flow first calls MMR synchronously with a 3000ms timeout (timeout → mmrDelta=0 → proceed), then fires Reward, XP, Quest, and Battle Pass in parallel via `Promise.allSettled()`. The `match_end` socket event is emitted to the client immediately after the fan-out is initiated — the client does not wait for economy settlement. This is Architecture Principle 5 (Model B). This ADR defines the fan-out implementation, idempotency key derivation, and failure handling.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core |
| **Knowledge Risk** | LOW — Promise.allSettled and Node.js async patterns are within training data |
| **References Consulted** | `design/gdd/match-flow.md`, `design/gdd/reward-system.md`, `design/gdd/xp-progression.md`, `design/gdd/quest-mission.md`, `design/gdd/battle-pass.md`, `design/gdd/mmr-ranked.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0003 (endMatch return), ADR-0005 (PostgreSQL), ADR-0008 (idempotency), ADR-0012 (Session Manager calls Match Flow) |
| **Enables** | All economy system implementations (Reward, XP, Quest, Battle Pass) |
| **Blocks** | Match Flow implementation |
| **Ordering Note** | Must be Accepted before any economy fan-out handler is written |

## Context

### Problem Statement

When a match ends, multiple economy systems must be updated (MMR, rewards, XP, quest progress, battle pass). If these run sequentially, a slow system delays the `match_end` delivery to the client. If any system fails, it must not prevent others from running or block the client from seeing results.

### Current State

No Match Flow implementation exists.

### Constraints

- `match_end` must reach the client within 3000ms of match end (MMR timeout is the longest blocking operation)
- Economy systems (Reward, XP, Quest, Battle Pass) must not block each other
- A failure in any one economy system must not prevent others from running
- All economy writes must use idempotency keys derived from `matchId + userId` to survive retries
- MMR fires first and synchronously; its result (mmrDelta) is included in `match_end`

### Requirements

- MMR: synchronous with 3000ms timeout; result included in `match_end` payload
- After MMR: `Promise.allSettled([Reward, XP, Quest, BattlePass])` — all fire in parallel
- `match_end` socket event emitted immediately after fan-out is initiated (before allSettled resolves)
- Partial failure: log failed systems; do not retry immediately (next match or scheduled job handles retries)
- Session Manager destroys session after Match Flow confirms all fan-out initiated

## Decision

Match Flow uses a **two-phase fan-out**: (1) MMR sync with timeout, (2) `Promise.allSettled()` for economy. `match_end` fires to client after phase 1 completes and phase 2 is initiated. Phase 2 failures are logged and queued for retry — they never block the client.

### Architecture

```
Session Manager
  │ match ended (via GameRoom 'match_ended' event)
  ├── MatchFlow.processMatchEnd(matchId, results)

MatchFlow.processMatchEnd(matchId, results):
  // Phase 1: MMR (blocking, with timeout)
  mmrDeltas = await Promise.race([
    MMRSystem.updateRatings(matchId, results),
    delay(3000).then(() => results.map(r => ({ playerId: r.playerId, mmrDelta: 0 })))
  ])

  // Emit match_end IMMEDIATELY (client does not wait for economy)
  for each playerId in results:
    io.to(`user:${playerId}`).emit('match_end', {
      matchId,
      results,
      mmrDeltas,
    })

  // Phase 2: Economy fan-out (non-blocking for client)
  const idempotencyBase = `match:${matchId}`;
  await Promise.allSettled([
    RewardSystem.calculateAndGrant(matchId, results, `${idempotencyBase}:reward`),
    XPSystem.grantXP(matchId, results, `${idempotencyBase}:xp`),
    QuestSystem.processMatchResult(matchId, results, `${idempotencyBase}:quest`),
    BattlePassSystem.creditBPXP(matchId, results, `${idempotencyBase}:bp`),
  ]).then(outcomes => {
    for (const outcome of outcomes) {
      if (outcome.status === 'rejected') {
        logger.error('match_flow_fanout_failure', { matchId, reason: outcome.reason });
        // TODO: enqueue for retry in background job
      }
    }
  })

  // Profile refresh emitted by each economy system after its writes
  // Session Manager may destroy session here
  SessionManager.destroySession(matchId)
```

### Key Interfaces

```typescript
interface IMatchFlow {
  processMatchEnd(matchId: string, results: MatchResultsPayload): Promise<void>;
}

interface MatchResultsPayload {
  matchId: string;
  mode: GameMode;
  players: PlayerResult[];
  durationSec: number;
  endReason: 'win' | 'time' | 'forfeit';
}

interface PlayerResult {
  playerId: string;
  characterId: string;
  placement: number;       // 1 = winner; ties share placement
  kills: number;
  damageDealt: number;
  isBot: boolean;
}

// Idempotency key derivation
function deriveKey(matchId: string, system: string): string {
  return `${matchId}:${system}`;  // e.g. 'match:uuid123:reward'
}
```

### Implementation Guidelines

- `mmrDeltas` must always be present in `match_end` — use `mmrDelta: 0` for bots and timeout cases
- Never `await` the `Promise.allSettled()` before emitting `match_end` — the emit must fire first
- Each economy system is responsible for emitting its own `profile:refresh` after writing — Match Flow does not do it globally
- Idempotency keys are derived from `matchId` — safe to retry the entire `processMatchEnd` if it crashes (all writes are idempotent)
- Bot `PlayerResult` entries are included in `results` for MMR calculation but bots have no economy effects — check `isBot` before writing to DB

## Alternatives Considered

### Alternative 1: Model A (Sequential Economy)

- **Description**: Run MMR → Reward → XP → Quest → Battle Pass sequentially; emit `match_end` after all complete.
- **Pros**: Simpler; all data available before client sees results.
- **Cons**: Sequential time = sum of all system latencies (potentially 500–2000ms); client waits; one system failure blocks all downstream.
- **Rejection Reason**: Client UX unacceptable; Architecture Principle 5 explicitly defines Model B.

### Alternative 2: Async Queue (Bull/BullMQ)

- **Description**: Enqueue match_end jobs in a Redis queue; workers process them asynchronously.
- **Pros**: Reliable retry; backpressure handling; decoupled from match server.
- **Cons**: Adds a job queue dependency; `match_end` emission would need to happen before queue processing (adding complexity); retry latency could leave player profile stale for seconds.
- **Rejection Reason**: `Promise.allSettled` with logging is sufficient at MVP scale; BullMQ can be added if retry failures become a problem post-launch.

## Consequences

### Positive

- `match_end` reaches client within 3000ms (MMR timeout) regardless of economy system health
- Economy system failures are isolated — a broken Quest system doesn't prevent rewards
- Idempotency keys enable safe retry of the entire fan-out

### Negative

- Economy data may not be reflected in profile immediately after `match_end` — there's a brief window where the client shows the match results screen before the profile updates arrive via `profile:refresh`
- Failed economy grants require a background retry mechanism (not implemented at MVP; logged for now)

### Neutral

- MMR timeout (→ mmrDelta=0) means a player can win a match but not gain MMR if the MMR system is slow; acceptable at launch frequency

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| MMR system consistently hits 3000ms timeout | Low | Medium | Profile MMR system; optimize DB query; consider Redis-backed MMR cache |
| Economy fan-out failures accumulate (no retry) | Medium | Medium | Log all failures; add dead-letter queue or admin retry endpoint before public launch |
| match_end emitted but session not destroyed | Low | Low | `destroySession` called in `finally` block after fan-out |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Time to match_end delivery (client) | — | ≤3000ms | 3000ms |
| Economy fan-out total time | — | ≤500ms (parallel) | — |
| processMatchEnd total duration | — | ≤3500ms | — |

## Migration Plan

New project.

**Rollback plan**: Switch to sequential economy (Model A) by replacing `Promise.allSettled` with sequential awaits — `match_end` emission point moves to after all awaits.

## Validation Criteria

- [ ] `match_end` received by client within 3000ms of match end (including MMR timeout case)
- [ ] `match_end.mmrDeltas` always present — no undefined entries
- [ ] Reward, XP, Quest, Battle Pass all complete within 2000ms of fan-out initiation (p95)
- [ ] Failure in Reward system does not prevent XP grant
- [ ] Retry of `processMatchEnd` with same `matchId` → all writes are no-ops (idempotent); no double-grant

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/match-flow.md` | Match Flow | MMR fires before economy; fan-out is parallel | Phase 1 (MMR sync) → Phase 2 (allSettled) |
| `design/gdd/match-flow.md` | Match Flow | match_end sent immediately after fan-out initiated | `io.emit('match_end')` fires before `allSettled` resolves |
| `design/gdd/mmr-ranked.md` | MMR | MMR fires synchronously with 3000ms timeout | `Promise.race([MMR, delay(3000)])` |
| `design/gdd/reward-system.md` | Rewards | Rewards must not block match_end | `Promise.allSettled` — non-blocking for client |

## Related

- ADR-0001: Architecture Principle 5 (fan-out never blocks match end) is codified here
- ADR-0003: `endMatch()` returns `MatchResultsPayload`; passed to Match Flow
- ADR-0008: All economy calls use idempotency keys derived from matchId
- ADR-0012: Session Manager initiates Match Flow; receives `destroySession` callback
