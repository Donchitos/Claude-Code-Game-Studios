# ADR-0008: Economy Transaction Safety (Idempotency + Atomic Grants)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Security Engineer

## Summary

All economy writes (coin credits/debits, diamond credits, item grants) use caller-supplied idempotency keys with a UNIQUE database constraint as the backstop against double-grants. Multi-step fulfillment (IAP purchase → diamonds + item + flags) uses a single PostgreSQL transaction. Coin balance is capped at 50,000; debits that would go negative throw `InsufficientFundsError`. This ADR defines the economy write contracts and the idempotency pattern.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core / Networking |
| **Knowledge Risk** | LOW — PostgreSQL UNIQUE constraints and Node.js async patterns are within training data |
| **References Consulted** | `design/gdd/currency-system.md`, `design/gdd/inventory-entitlements.md`, `design/gdd/reward-system.md`, `design/gdd/purchase-fulfillment.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm Supabase PostgreSQL supports `ON CONFLICT DO NOTHING RETURNING *` (standard PostgreSQL — yes) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0005 (PostgreSQL schema with idempotency_key UNIQUE) |
| **Enables** | ADR-0010, ADR-0011, ADR-0013 |
| **Blocks** | Currency System, Inventory/Entitlements, Reward System, Purchase Fulfillment implementations |
| **Ordering Note** | All economy systems must use this pattern; must be Accepted before any economy handler is written |

## Context

### Problem Statement

An IAP purchase, match reward, or quest completion may be processed multiple times due to network retries, webhook replays, or server restarts mid-transaction. Without idempotency, players could receive double coins, double items, or see corrupted balances. This is a financial integrity requirement.

### Current State

`server/src/db/schema.sql` exists with `transactions` and `entitlements` tables. Idempotency columns are defined but the application-layer pattern is not yet implemented.

### Constraints

- Coin ceiling: 50,000 (hardcoded; not configurable at MVP)
- Diamond balance cannot go negative; coin balance cannot go negative
- Free characters (`character:vex`, `character:zook`, etc.) cannot be revoked
- All economy writes are server-side; client has no write access to balances
- RevenueCat webhooks may be delivered multiple times (network retries from RevenueCat side)

### Requirements

- Idempotency key: caller-supplied UUID v4; UNIQUE constraint in `transactions` and `entitlements` tables
- Duplicate key → `ON CONFLICT DO NOTHING RETURNING *` → return existing result silently
- Multi-step fulfillment (IAP) → single PostgreSQL transaction; partial fulfillment on crash → full idempotent retry
- `creditCoins` clamps to 50,000 ceiling (excess is silently dropped with a log warning)
- `debitCoins` throws `InsufficientFundsError` if result < 0
- All economy writes emit `profile:refresh` after committing

## Decision

Every economy write function accepts a caller-supplied `idempotencyKey`. The UNIQUE constraint on the `transactions`/`entitlements` table is the safety backstop — not application-level deduplication. Multi-step operations (IAP fulfillment) run in a single `pg` transaction. After commit, `profile:refresh` is pushed to the player's socket.

### Architecture

```
CALLER                     ECONOMY LAYER              POSTGRESQL
  │                              │                         │
  │ creditCoins(userId,          │                         │
  │   amount=50, source,         │                         │
  │   idempotencyKey=UUID)       │                         │
  ├─────────────────────────────→│                         │
  │                              │ BEGIN                   │
  │                              ├────────────────────────→│
  │                              │ INSERT INTO transactions │
  │                              │   (userId, type, amount,│
  │                              │    source, idempotency_ │
  │                              │    key)                 │
  │                              │ ON CONFLICT (idempotency│
  │                              │ _key) DO NOTHING        │
  │                              │ RETURNING *             │
  │                              ├────────────────────────→│
  │                              │←─ { row } or empty ─────│
  │                              │                         │
  │                              │ UPDATE player_profiles   │
  │                              │ SET coin_balance =       │
  │                              │   LEAST(coin_balance +  │
  │                              │   amount, 50000)        │
  │                              │   WHERE userId=...      │
  │                              ├────────────────────────→│
  │                              │ COMMIT                  │
  │                              ├────────────────────────→│
  │                              │                         │
  │                              │ Redis DEL profile:userId│
  │                              │ emit profile:refresh     │
  │←─ Balance ───────────────────│

IAP FULFILLMENT (single transaction):
  BEGIN
    creditDiamonds(userId, +50, 'iap:diamond_pack_sm', key)
    grantItem(userId, 'character:colt', key+':char')
    grantItem(userId, 'skin:colt_default', key+':skin')
    UPDATE player_profiles SET has_play_pass=true (if applicable)
  COMMIT
  → Redis invalidation
  → profile:refresh
  → inventory:updated
```

### Key Interfaces

```typescript
interface ICurrencySystem {
  creditCoins(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance>;
  debitCoins(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance>;
  creditDiamonds(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance>;
  // Invariant: duplicate idempotencyKey → returns existing Balance silently (no error)
  // Invariant: creditCoins clamps to 50,000 ceiling; excess is dropped with log
  // Invariant: debitCoins throws InsufficientFundsError if result < 0
}

interface IInventory {
  grantItem(userId: string, itemId: string, idempotencyKey: string): Promise<GrantResult>;
  hasItem(userId: string, itemId: string): Promise<boolean>;  // Redis-first
  revokeItem(userId: string, itemId: string): Promise<void>;
  // Invariant: grantItem is idempotent — duplicate key returns { duplicate: true }
  // Invariant: revokeItem on free-character items throws CANNOT_REVOKE_FREE_CHARACTER
  // Invariant: grantItem writes to both entitlements AND player_profiles in same transaction
}

class InsufficientFundsError extends Error {
  readonly userId: string;
  readonly requestedDebit: number;
  readonly currentBalance: number;
}

// Idempotency key generation (caller responsibility)
import { randomUUID } from 'crypto';
const idempotencyKey = randomUUID();  // UUID v4; cryptographically random
```

### Implementation Guidelines

- Never generate idempotency keys inside the economy functions — callers own key generation so they can retry with the same key
- For IAP fulfillment, derive sub-keys from the webhook `event_id`: `{eventId}:diamonds`, `{eventId}:char`, `{eventId}:skin` — ensures atomicity across partial retries
- `ON CONFLICT DO NOTHING RETURNING *` — if `RETURNING *` returns no rows, the insert was a duplicate; return the original result by querying by idempotency key
- Profile cache (Redis `profile:{userId}`) must be DEL'd after every successful economy write — even if the write was a duplicate (no-op)
- `profile:refresh` is emitted on every successful economy write completion — whether it was a new write or a no-op duplicate
- Coin ceiling of 50,000 is enforced via `LEAST()` in the SQL UPDATE — not in application code — to prevent race conditions

## Alternatives Considered

### Alternative 1: Application-Level Deduplication Cache

- **Description**: Keep an in-memory or Redis set of processed idempotency keys; reject duplicates before hitting the DB.
- **Pros**: Faster (no DB write attempt on duplicate).
- **Cons**: Cache can be lost on server restart; idempotency keys must be persisted durably.
- **Rejection Reason**: The UNIQUE constraint in PostgreSQL is durable and requires no separate cache; the DB is the source of truth.

### Alternative 2: Event Sourcing

- **Description**: Record every economy event as an immutable log; derive current balance from the log.
- **Pros**: Perfect audit trail; replay capability.
- **Cons**: Significant implementation complexity; balance queries require aggregation.
- **Rejection Reason**: The `transactions` table already provides an audit trail; full event sourcing is over-engineering for MVP scope.

## Consequences

### Positive

- Double-grant is structurally impossible — DB UNIQUE constraint is the backstop
- IAP webhook replays are safely handled by idempotent fulfillment
- Coin ceiling is enforced in the DB layer — impossible to bypass via concurrent requests

### Negative

- Idempotency key generation is the caller's responsibility — if callers generate the same key for different operations, it would cause a missed write (mitigated by UUID v4 randomness)
- Multi-step fulfillment in a single transaction means any step failure rolls back all steps — requires full retry from the caller

### Neutral

- `profile:refresh` is emitted even on duplicate no-op writes — this is harmless (client re-reads the same profile) but adds a socket event

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Caller reuses idempotency key across different operations | Very Low | High | UUID v4 uniqueness; document caller responsibility explicitly |
| PostgreSQL transaction deadlock on concurrent balance updates | Low | Medium | Use `SELECT ... FOR UPDATE` on player_profiles row to serialize balance writes |
| profile:refresh storm (many players rewarded simultaneously) | Low | Low | Socket emits are async; no back-pressure at Socket.io level for this volume |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| creditCoins (new key) | — | ≤20ms | 50ms |
| creditCoins (duplicate key) | — | ≤10ms | 20ms |
| IAP fulfillment transaction | — | ≤50ms | 200ms |

## Migration Plan

New project. `idempotency_key UNIQUE` constraints added in initial schema.

**Rollback plan**: If UNIQUE constraint causes unexpected conflicts, add an application-layer dedup check — but this should not be necessary given UUID v4 generation.

## Validation Criteria

- [ ] Sending the same `creditCoins` request with the same idempotency key twice → second call returns first result, balance unchanged
- [ ] `debitCoins` with insufficient balance → `InsufficientFundsError` thrown; balance unchanged
- [ ] `creditCoins` that would exceed 50,000 → balance clamped to 50,000; no error
- [ ] IAP fulfillment with webhook replay (same `event_id`) → all sub-operations return duplicate result; profile unchanged
- [ ] `grantItem` on a free character → `CANNOT_REVOKE_FREE_CHARACTER` thrown on revoke attempt

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/currency-system.md` | Currency | Idempotent coin/diamond writes; 50k ceiling | `ON CONFLICT DO NOTHING`; `LEAST(balance + amount, 50000)` |
| `design/gdd/inventory-entitlements.md` | Inventory | Idempotent item grants | `grantItem` idempotency key UNIQUE on entitlements |
| `design/gdd/reward-system.md` | Rewards | Match rewards cannot double-grant | Reward System generates idempotency key from matchId+userId |
| `design/gdd/purchase-fulfillment.md` | IAP Fulfillment | Atomic multi-step fulfillment | Single pg transaction for diamonds + item + flags |

## Related

- ADR-0005: PostgreSQL UNIQUE constraint on idempotency_key defined in schema
- ADR-0010: Match Flow fan-out calls economy functions; each call must carry an idempotency key derived from matchId
- ADR-0011: IAP Integration uses this pattern for webhook-triggered fulfillment
