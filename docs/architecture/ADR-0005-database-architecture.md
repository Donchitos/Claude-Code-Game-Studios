# ADR-0005: Database Architecture (PostgreSQL + Redis Patterns)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Lead Programmer

## Summary

BRAWLZONE uses PostgreSQL (via Supabase) as the persistent system of record for all player data and economy, with Redis as a cache and queue layer for hot-path reads and matchmaking state. This ADR defines which data lives where, the read/write patterns, and the cache invalidation strategy.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core / Networking |
| **Knowledge Risk** | LOW — PostgreSQL, Redis, and Supabase JS are well within training data |
| **References Consulted** | `design/gdd/player-profile.md`, `design/gdd/inventory-entitlements.md`, `design/gdd/currency-system.md`, `design/gdd/matchmaking-engine.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm Supabase PostgreSQL connection pooling limits on selected plan |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (server-side data principle), ADR-0004 (userId as FK) |
| **Enables** | ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0013 |
| **Blocks** | Player Profile Service, Currency System, Inventory, Matchmaking Engine |
| **Ordering Note** | Schema must be finalized before any Feature-layer system is implemented |

## Context

### Problem Statement

A mobile competitive game requires low-latency reads for match-critical data (profile, loadout, character ownership) while also maintaining a durable, consistent record for economy transactions that are financially sensitive (IAP, coin balances, entitlements). These two requirements pull in opposite directions — speed vs. consistency.

### Current State

`server/src/db/schema.sql` exists as a skeleton. No connection pooling or Redis integration is implemented.

### Constraints

- Economy writes must be ACID-compliant — no eventual consistency for coin balances or item grants
- Matchmaking queue state is ephemeral — Redis is appropriate; no durability required
- Profile reads happen on every socket connection and match start — must be sub-10ms
- Redis is a cache; PostgreSQL is the system of record — Redis loss is recoverable

### Requirements

- PostgreSQL for: `player_profiles`, `entitlements`, `transactions`, `match_records`, `quest_progress`, `battle_pass_progress`
- Redis for: profile cache (TTL 60s), inventory cache (TTL 60s), matchmaking queues (no TTL — managed by Matchmaking Engine), session state (TTL = match duration + 5min)
- All economy writes use transactions with idempotency key uniqueness constraint
- `profile:refresh` socket event triggers client cache invalidation (see ADR-0006)

## Decision

**PostgreSQL is the system of record. Redis is a cache and queue layer.** Reads go to Redis first; PostgreSQL is the fallback. Writes always go to PostgreSQL first, then update or invalidate Redis.

### Architecture

```
SERVER (Node.js)
  │
  ├── Player Profile Service
  │     ├── READ:  Redis GET profile:{userId}  (TTL 60s)
  │     │          → miss → PostgreSQL SELECT → Redis SET
  │     └── WRITE: PostgreSQL UPDATE → Redis DEL profile:{userId}
  │                → emit profile:refresh on socket
  │
  ├── Inventory / Entitlements
  │     ├── READ:  Redis SMEMBERS inv:{userId}  (TTL 60s)
  │     │          → miss → PostgreSQL SELECT entitlements → Redis SET
  │     └── WRITE: PostgreSQL INSERT (idempotency_key UNIQUE)
  │                → Redis DEL inv:{userId}
  │                → emit inventory:updated on socket
  │
  ├── Currency System
  │     ├── READ:  PostgreSQL (no Redis cache — financial data)
  │     └── WRITE: PostgreSQL UPDATE coin_balance / diamond_balance
  │                (idempotency_key UNIQUE constraint)
  │
  ├── Matchmaking Engine
  │     ├── QUEUE: Redis ZADD mm:queue:{mode}:time {score=queuedAt} {userId}
  │     │          Redis ZADD mm:queue:{mode}:mmr  {score=mmr}       {userId}
  │     └── DEQUEUE: Redis ZREM (atomic via Lua script)
  │
  └── Match Server (in-memory only — never writes to DB or Redis)
        └── Match Flow reads Match Server output → writes match_records to PostgreSQL

POSTGRESQL SCHEMA (key tables):
  player_profiles     — 26 fields: userId, mmr, coins, diamonds, xp, level, ...
  entitlements        — userId, itemId, grantedAt, idempotency_key UNIQUE
  transactions        — userId, type, amount, source, idempotency_key UNIQUE, createdAt
  match_records       — matchId, mode, players, results, startedAt, endedAt
  quest_progress      — userId, questId, progress, completedAt
  battle_pass_progress — userId, season, xp, tier, rewards_claimed[]
```

### Key Interfaces

```typescript
// Player Profile Service
interface IPlayerProfileService {
  getProfile(userId: string): Promise<PlayerProfile>;          // Redis-first
  updateProfile(userId: string, delta: Partial<PlayerProfile>): Promise<PlayerProfile>;
  // Invalidates Redis cache; emits profile:refresh via socket
}

// Economy write — always PostgreSQL with idempotency key
interface IEconomyWrite {
  idempotencyKey: string;  // UUID v4; caller generates; UNIQUE in DB
  userId: string;
  amount: number;
  source: string;
}

// Redis key conventions
const KEYS = {
  profile: (userId: string) => `profile:${userId}`,
  inventory: (userId: string) => `inv:${userId}`,
  mmQueueTime: (mode: GameMode) => `mm:queue:${mode}:time`,
  mmQueueMMR: (mode: GameMode) => `mm:queue:${mode}:mmr`,
  session: (matchId: string) => `session:${matchId}`,
} as const;
```

### Implementation Guidelines

- Never cache coin/diamond balances in Redis — financial data always reads from PostgreSQL to prevent stale-balance exploits
- All `idempotency_key` columns have a `UNIQUE` constraint in PostgreSQL — duplicate insert returns the existing row (use `ON CONFLICT DO NOTHING RETURNING *`)
- Match Server holds all match state in Node.js heap memory; it never touches PostgreSQL or Redis during a match
- Connection pool: use `pg` with `max: 20` connections; Redis with `ioredis` single client (no cluster needed at MVP scale)
- All DB migrations live in `server/src/db/migrations/`; run with a custom migration script (no ORM migration runner)

## Alternatives Considered

### Alternative 1: Single Database (PostgreSQL Only)

- **Description**: Use PostgreSQL for everything including matchmaking queues and session state.
- **Pros**: Simpler architecture; no Redis dependency; ACID for everything.
- **Cons**: PostgreSQL is not optimized for sorted set queue operations; matchmaking bracket algorithm needs atomic score-range queries that are awkward in SQL.
- **Rejection Reason**: Redis sorted sets are the idiomatic data structure for matchmaking queues; ZADD/ZRANGEBYSCORE are 1–2 orders of magnitude faster than equivalent SQL for this use case.

### Alternative 2: ORM (Prisma / TypeORM)

- **Description**: Use an ORM for all PostgreSQL access.
- **Pros**: Type-safe queries; migrations built-in; less boilerplate.
- **Cons**: ORMs abstract away idempotency patterns; `ON CONFLICT DO NOTHING RETURNING *` is awkward through most ORMs; ORM queries are harder to audit for N+1s in economy paths.
- **Rejection Reason**: Economy paths require exact control over transaction boundaries and idempotency; raw `pg` queries with typed results are safer here.

## Consequences

### Positive

- Profile and inventory reads served from Redis at sub-1ms
- Economy writes are provably idempotent via DB constraint — not just application-layer logic
- Redis loss is non-catastrophic — system recovers by reading PostgreSQL

### Negative

- Two database systems to operate and monitor
- Cache invalidation logic must be correct on every profile-mutating code path (miss = stale UI)
- No ORM means more boilerplate for query construction

### Neutral

- Match Server's in-memory-only policy means match state is lost on server crash; disconnect handler and reconnect resume mitigate this for in-progress matches

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Cache-DB inconsistency after Redis failure | Low | Medium | TTL-based expiry ensures eventual consistency; profile:refresh forces re-fetch |
| idempotency_key collision (duplicate grants) | Very Low | High | UNIQUE constraint is the backstop; application must generate cryptographically random keys |
| PostgreSQL connection pool exhaustion under load | Medium | High | Pool `max: 20`; add connection wait queue; alert on pool saturation |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Profile read (cache hit) | — | ≤1ms | 5ms |
| Profile read (cache miss) | — | ≤10ms | 20ms |
| Economy write (idempotent) | — | ≤20ms | 50ms |
| Matchmaking enqueue | — | ≤2ms (Redis ZADD) | 5ms |

## Migration Plan

New project. Schema in `server/src/db/schema.sql` will be applied to Supabase via `psql`.

**Rollback plan**: PostgreSQL schema migrations are versioned; rollback by running the inverse migration file.

## Validation Criteria

- [ ] Profile read with Redis warm: ≤1ms p99
- [ ] Profile read with Redis cold: ≤20ms p99
- [ ] Duplicate idempotency_key insert returns existing row without error
- [ ] Economy balance remains correct across 1000 concurrent grant requests (load test)
- [ ] Redis flush → system recovers without manual intervention within 60s

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/player-profile.md` | Player Profile | 26-field profile with Redis cache | `player_profiles` table + Redis `profile:{userId}` cache defined |
| `design/gdd/currency-system.md` | Currency | Idempotent coin/diamond writes | `idempotency_key UNIQUE` on `transactions` table |
| `design/gdd/inventory-entitlements.md` | Inventory | Idempotent item grants | `idempotency_key UNIQUE` on `entitlements` table |
| `design/gdd/matchmaking-engine.md` | Matchmaking | Dual Redis sorted sets per mode | `mm:queue:{mode}:time` and `mm:queue:{mode}:mmr` ZADD pattern defined |

## Related

- ADR-0001: Server-only data write principle
- ADR-0004: `userId` (Supabase UUID) is the primary key on all tables
- ADR-0008: Economy Transaction Safety — depends on idempotency constraint defined here
- ADR-0009: Matchmaking Architecture — depends on Redis sorted set structure defined here
