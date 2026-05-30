# ADR-0003: Server-Side Game Loop (Authoritative Simulation & Tick Budget)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Lead Programmer

## Summary

The server runs a 20Hz authoritative game loop (50ms tick interval) implemented in Node.js. Each tick processes queued player inputs, simulates combat and status effects, evaluates win conditions, and broadcasts the resulting state to all players in the match. This ADR defines the tick budget, input processing pipeline, lag compensation formula, and the `IMatchServer` interface contract.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core / Networking |
| **Knowledge Risk** | LOW — Node.js setInterval-based game loop patterns are within training data |
| **References Consulted** | `design/gdd/match-server.md`, `design/gdd/combat-system.md`, `design/gdd/ability-skill.md`, `docs/architecture/architecture.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Benchmark `setInterval(50)` drift under load on Railway Node.js instance; consider `hrtime`-corrected loop if drift >5ms |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002 (Socket.io broadcast), ADR-0004 (userId injection) |
| **Enables** | ADR-0010 (Match Flow fan-out — reads `endMatch()` output), ADR-0012 (Session lifecycle) |
| **Blocks** | Match Server implementation, Combat Resolver, Bot AI |
| **Ordering Note** | Tick budget and interface defined here must be stable before Match Server, Combat Resolver, or Bot AI are written |

## Context

### Problem Statement

A server-authoritative real-time brawler requires a deterministic game loop that processes inputs, resolves combat, and emits state at a fixed rate. Node.js is single-threaded; the tick function must complete within its budget to avoid frame drops. The budget must be defined and enforced before implementation begins.

### Current State

`server/src/game/GameRoom.ts` exists as a scaffold. No tick loop is implemented.

### Constraints

- Node.js single-threaded event loop — tick function is synchronous; async I/O would block subsequent ticks
- 20Hz target (50ms tick interval) — industry standard for mobile brawlers at this latency tier
- 8 players maximum per match (FFA mode) — worst-case simulation load
- Match Server must never write to PostgreSQL or Redis during a tick (latency spike risk)
- All simulation is deterministic given the same inputs; no `Math.random()` in combat path

### Requirements

- Tick interval: 50ms (20Hz)
- Tick budget breakdown: Input queue 2ms → Validation 3ms → Simulation 20ms → Win condition 3ms → State emit 7ms → 15ms buffer
- Lag compensation: rewind = `floor(min(playerRtt, 200ms) / 50ms)` ticks; applies to hit detection only
- Input queue: all inputs buffered since last tick are processed in order
- State emit: `match_state` broadcast to `match:{matchId}` room via Socket.io

### Tick Budget (50ms)

| Phase | Budget | What Happens |
|-------|--------|-------------|
| Input queue drain | 2ms | Dequeue and validate all buffered inputs since last tick |
| Input validation | 3ms | Range checks, ability ownership, cooldown enforcement |
| Simulation | 20ms | Combat resolution, status effect ticks, passive ticks, cooldown decrements, position updates |
| Win condition | 3ms | Check health = 0, time limit, mode-specific conditions |
| State emit | 7ms | Serialize `MatchSnapshot`, `io.to(room).emit('match_state', ...)` |
| Buffer | 15ms | Node.js event loop overhead, GC pauses, broadcast variation |

## Decision

Implement the game loop using Node.js `setInterval(tick, 50)` with a `hrtime`-corrected tick counter for lag compensation. The tick function is fully synchronous. All I/O (DB writes, Redis reads) is prohibited inside `tick()`; async operations are queued and processed outside the tick loop by `Match Flow` after `endMatch()` is called.

### Architecture

```
Session Manager
  │
  └── creates GameRoom (Match Server instance)
        │
        └── setInterval(tick, 50ms)
              │
              ├── Phase 1: drain inputQueue[]
              │     └── validate each input (ownership, cooldown, bounds)
              │
              ├── Phase 2: simulate(inputs, currentState)
              │     ├── Combat Resolver.resolveHit(attacker, target, ability)
              │     ├── applyStatusEffects(players)
              │     ├── tickPassives(characters, state)
              │     └── decrementCooldowns(players)
              │
              ├── Phase 3: evaluateWinCondition(state, mode)
              │     └── → if done: endMatch(reason) → clearInterval
              │
              └── Phase 4: broadcastState()
                    └── io.to(match:{matchId}).emit('match_state', snapshot)

endMatch(reason):
  → returns MatchResultsPayload
  → Session Manager passes to Match Flow
  → Match Flow handles all async fan-out (MMR, rewards, etc.)
```

### Key Interfaces

```typescript
interface IMatchServer {
  startMatch(config: MatchConfig): void;
  endMatch(reason: 'win' | 'time' | 'forfeit'): MatchResultsPayload;
  processInput(playerId: string, input: PlayerInput): void;  // queued; applied next tick
  getSnapshot(): Readonly<MatchSnapshot>;    // deep-frozen; callers must not mutate
  getPlayerState(id: string): PlayerState | null;
  onPlayerReconnected(playerId: string): void;
  tick(): void;  // called by tick scheduler every 50ms; MUST NOT be async
}

interface PlayerState {
  playerId: string;
  characterId: string;       // e.g. "character:vex"
  hp: number;                // 0–maxHp
  maxHp: number;
  position: Vector2;         // LGU coords; origin bottom-left, Y-axis up
  abilitySlots: [AbilityCooldownState, AbilityCooldownState];
  statusEffects: StatusEffect[];
  isBot: boolean;
  isActive: boolean;         // false = disconnected; bot backfills when isInactive
}

interface MatchSnapshot {
  tick: number;
  timestamp: number;         // server hrtime at emit
  players: readonly PlayerState[];
  projectiles: readonly ProjectileState[];
}

// Lag compensation
function lagCompensateTick(playerRttMs: number): number {
  return Math.floor(Math.min(playerRttMs, 200) / 50);
}
// Applied only to hit detection raycasts; NOT to damage or ability cooldowns
```

### Implementation Guidelines

- `tick()` must never `await` — any async operation inside tick blocks all subsequent ticks
- Input queue is a `PlayerInput[]` array per player; cleared at start of each tick
- `getSnapshot()` returns a `Object.freeze()`-ed deep copy; callers cannot mutate live state
- Tick counter is monotonically incrementing `uint32`; client uses it for interpolation ordering
- Bot AI `tickBot()` is called within the simulation phase — same sync constraint applies
- Win condition short-circuits: once triggered, `endMatch()` is called and `clearInterval` stops the loop
- `isActive` flag on `PlayerState` is set to `false` by Disconnect Handler; Bot AI takes over for that slot

## Alternatives Considered

### Alternative 1: 60Hz Tick Rate

- **Description**: Run simulation at 60Hz (16.6ms tick interval).
- **Pros**: Smoother simulation; lower interpolation lag on client.
- **Cons**: 3× the server CPU budget; 50ms tick already within mobile network latency floor; no perceived quality gain for players on 4G.
- **Rejection Reason**: 20Hz is the mobile brawler standard (Brawl Stars reference); 60Hz would triple server cost with no player-visible benefit.

### Alternative 2: Worker Thread for Simulation

- **Description**: Run simulation on a Node.js Worker Thread to avoid blocking the event loop.
- **Pros**: Simulation can be truly parallel with I/O; GC pauses don't block tick.
- **Cons**: Worker thread communication adds serialization overhead; 15ms buffer already accounts for GC; adds complexity.
- **Rejection Reason**: The 15ms buffer in the tick budget is sufficient headroom. Worker threads can be added later if profiling shows consistent overruns.

## Consequences

### Positive

- Single-threaded synchronous tick is simple to reason about and test
- Deep-frozen snapshot prevents accidental state mutation by upstream callers
- Deterministic simulation (no random in combat path) makes replays and debugging tractable

### Negative

- Node.js GC pauses can occasionally consume the 15ms buffer; tail latency spikes possible
- 20Hz means client interpolates between states; maximum "true" update rate is 20fps

### Neutral

- Lag compensation rewinds apply only to hit detection; damage is applied at server real-time

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Tick overrun (>50ms simulation) | Medium | High | Profile tick under 8-player FFA; shed non-critical simulation (passive ticks) if >35ms |
| setInterval drift over time | Low | Medium | Use `hrtime`-corrected tick counter; resync every 100 ticks |
| Memory leak in match state per tick | Low | High | Verify snapshot deep-clone doesn't retain references; heap profile per match |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Tick function duration (8 players) | — | ≤35ms | 50ms |
| match_state packet size | — | ≤1.5KB | — |
| Matches per Node.js process | — | ≤50 concurrent | — |
| Heap growth per match | — | ≤2MB | — |

## Migration Plan

New project.

**Rollback plan**: Replace `setInterval` with a `worker_threads`-based loop — the `IMatchServer` interface is unchanged; only the scheduler changes.

## Validation Criteria

- [ ] `tick()` completes in ≤35ms under 8-player FFA simulated load (unit test with mocked I/O)
- [ ] `match_state` broadcasts arrive at client at 20Hz ±2Hz (integration test)
- [ ] Lag-compensated hit detection registers within ±1 tick of player visual (manual QA)
- [ ] 100 consecutive ticks with no drift >5ms (performance benchmark)
- [ ] Match Server never writes to PostgreSQL or Redis during match (enforced by code review)

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/match-server.md` | Match Server | 20Hz authoritative tick loop | setInterval(50ms) loop defined with full budget breakdown |
| `design/gdd/match-server.md` | Match Server | Tick budget: Input 2ms / Val 3ms / Sim 20ms / Win 3ms / Emit 7ms / Buffer 15ms | Budget table defined above |
| `design/gdd/combat-system.md` | Combat | BURNING bypasses SHIELDED | Applied in simulation phase's `applyStatusEffects()` |
| `design/gdd/ability-skill.md` | Abilities | Cooldown enforcement server-side | Validation phase checks cooldown state before queueing input |
| `design/gdd/reconnect-resume.md` | Reconnect | Snapshot on reconnect | `getSnapshot()` returns current frozen state for `reconnect_ack` |

## Related

- ADR-0001: Server-authoritative principle that motivates this loop
- ADR-0002: Socket.io broadcast — tick output goes through Socket.io
- ADR-0010: Match Flow fan-out — triggered by `endMatch()` return value
- ADR-0012: Session & Match Lifecycle — Session Manager calls `startMatch()` / `endMatch()`
