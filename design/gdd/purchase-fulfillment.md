# Purchase Fulfillment — Game Design Document

> **System**: Purchase Fulfillment
> **Priority**: Alpha
> **Layer**: Economy
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-28
> **Last Updated**: 2026-05-28

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

The Purchase Fulfillment system is the server-side orchestration pipeline that bridges the IAP System (which validates payments and receives RevenueCat webhooks) and the Currency/Inventory systems (which hold economy state). It is the single point of authority for translating a RevenueCat event — `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, or `REFUND` — into concrete game-state changes: Diamond grants, entitlement grants, subscription expiry updates, and refund reversals. The system's defining contract is **exactly-once delivery**: no purchase is ever fulfilled twice, no purchase is ever silently dropped, and any failure is retried until success or escalated to on-call operations. It owns the `iap_transactions` table's fulfillment lifecycle, the product-to-grant mapping table, the reconciliation background job, and all subscription lapse/renewal logic. It calls the Currency System and Inventory/Entitlements System as downstream grant targets and never holds any economy state itself.

---

## 2. Player Fantasy

### "It Was There When I Opened the App"

A player spends real money and expects the game to immediately reflect it — not after an email, not after a support ticket, and not after a reload. The central promise of Purchase Fulfillment is that a player should never have to wonder whether their purchase went through.

**What the player experiences:** They tap "Buy", the store native prompt appears, they confirm payment, and within seconds their Diamond balance ticks up, a new character appears in their roster, or the Play Pass badge lights up. The transition from "I just paid" to "I have it" feels like one moment, not two.

**What the player should never experience:** A grey "purchase pending" spinner that lingers for 30 seconds. A session restart to "refresh" their inventory. A need to screenshot their purchase receipt or contact support for a routine transaction. A purchase that charged their card but delivered nothing, even temporarily.

**The reliability contract:** If fulfillment is delayed due to a server fault (not the player's connection), the player will receive their purchase the next time they open the app — silently, automatically, without any action on their part. The system retries in the background and delivers at the next reconnect. The player never has to know a retry happened.

**The refund experience:** If a player initiates a platform refund, the system handles it gracefully. If they have not spent the Diamonds, they are cleanly reversed. If they have spent them, the account is flagged for human review — the system does not punish a player by deducting below zero or corrupting their account. Every edge case resolves to a defined state, not an undefined one.

---

## 3. Detailed Rules

### 3.1 Fulfillment Pipeline

Every IAP event follows this exact sequence. No step may be skipped.

```
1. RevenueCat webhook arrives at POST /webhooks/revenuecat
   │
   ▼
2. Request authentication
   - Validate RevenueCat webhook HMAC signature
   - Reject with HTTP 401 if signature invalid; log WARN
   │
   ▼
3. Idempotency check
   - Look up iap_transactions WHERE transaction_id = event.transactionId
   - If row exists AND fulfilled = true AND event.type = 'INITIAL_PURCHASE':
       → Return HTTP 200 immediately (already fulfilled; no-op)
   - If row exists AND refunded = true AND event.type = 'REFUND':
       → Return HTTP 200 immediately (already refunded; no-op)
   - If row does not exist:
       → INSERT into iap_transactions with fulfilled = false, refunded = false
       (ON CONFLICT (transaction_id) DO NOTHING — race condition guard)
   │
   ▼
4. Determine grant
   - Look up productId in the Product Grant Table (§3.3)
   - If productId not found → log ERROR, emit purchase_fulfillment_failed, return HTTP 200
     (RevenueCat must not retry unknown products; ack receipt and alert ops)
   - Resolve the full grant payload: currency amounts + entitlement item IDs
   │
   ▼
5. Atomic grant execution
   - Open a single PostgreSQL transaction
   - Call Currency System grantCurrency() for each currency grant (within same txContext)
   - Call Inventory/Entitlements grantItem() for each entitlement (within same txContext)
   - If any call fails → ROLLBACK entire transaction; do not mark fulfilled
   - If all calls succeed → COMMIT
   │
   ▼
6. Mark fulfilled
   - UPDATE iap_transactions SET fulfilled = true, fulfilled_at = NOW()
     WHERE transaction_id = $1 AND fulfilled = false
   - This UPDATE is outside the grant transaction intentionally:
     the grant is the irreversible step; the flag is the audit marker.
     If this UPDATE fails, the reconciliation job re-reads fulfilled state
     from Currency/Inventory systems and corrects the flag.
   │
   ▼
7. Notify client
   - Emit Socket.io event purchase_fulfilled to the player's authenticated socket
     payload: { transactionId, productId, grantsApplied: [...] }
   - If player is offline: client polls on next app foreground via GET /profile
     (profile:refresh cache invalidation already fired from Currency/Inventory writes)
   │
   ▼
8. Emit analytics
   - Fire Tier 0 event purchase_fulfilled (see §3.8)
   - Return HTTP 200 to RevenueCat
```

---

### 3.2 Idempotency

Idempotency is enforced at the database layer, not only the application layer.

The `iap_transactions` table has a `UNIQUE` constraint on `transaction_id`. When a webhook arrives:

1. The Fulfillment system attempts `INSERT INTO iap_transactions (transaction_id, ...) ON CONFLICT (transaction_id) DO NOTHING`.
2. If the INSERT inserts 0 rows (conflict), a row already exists. The system reads the existing row.
3. If `fulfilled = true`: this is a duplicate webhook for an already-fulfilled transaction. Return HTTP 200 immediately. No grant is executed.
4. If `fulfilled = false`: a prior attempt started but did not complete. Treat this as a retry: re-run steps 4–8 of the pipeline. The Currency System and Inventory System's own idempotency keys (keyed on `transaction_id`) ensure grants are not doubled even if they already committed in a prior attempt.
5. If a `RENEWAL` webhook arrives with a new `transactionId` distinct from prior transactions: this is a new row; proceed through the full pipeline.

**Idempotency key format for downstream grant calls:**

| Grant Type | Key |
|---|---|
| Diamond grant from IAP | `iap:{transactionId}` |
| Entitlement grant from IAP | `iap:{transactionId}:{itemId}` |
| Play Pass renewal Diamond grant | `iap:renewal:{transactionId}` |
| Play Pass renewal profile extension | `iap:renewal:profile:{transactionId}` |

---

### 3.3 Product → Grant Mapping

The grant mapping table is the canonical definition of what each RevenueCat `productId` delivers. It is maintained server-side in Remote Config (cold key: `fulfillment.productGrantMap`) and mirrored in the PostgreSQL `product_grant_definitions` table as a backup. The server reads from Remote Config on startup and falls back to the DB table if Remote Config is unreachable.

#### Diamond Packages

| productId | Currency Grant | Entitlement Grants | Notes |
|---|---|---|---|
| `diamonds_starter` | +80 Diamonds | — | Lowest entry IAP |
| `diamonds_small` | +200 Diamonds | — | |
| `diamonds_medium` | +500 Diamonds | — | |
| `diamonds_large` | +1,100 Diamonds | — | |
| `diamonds_xlarge` | +2,400 Diamonds | — | |
| `diamonds_mega` | +6,500 Diamonds | — | Highest value |

#### Character Bundles

| productId | Currency Grant | Entitlement Grants | Notes |
|---|---|---|---|
| `character_bundle_colt` | +50 Diamonds | `character:colt`, `skin:colt_default` | Colt + default skin + bonus Diamonds |
| `character_bundle_nyx` | +50 Diamonds | `character:nyx`, `skin:nyx_default` | Nyx + default skin + bonus Diamonds |

> **Note on default skins:** Default skins are entitlement records distinct from the character entitlement. They follow the same idempotent grant rules: if the player already owns the default skin (e.g., acquired it separately), the skin grant is a no-op with `duplicate: true`. The character grant and Diamond grant still apply.

#### Play Pass Subscription

| productId | Currency Grant | Entitlement Grants | Profile Mutations | Notes |
|---|---|---|---|---|
| `play_pass_monthly` | +`PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE` Diamonds (see §4.2) | `entitlement_flag:has_play_pass` | `playPassExpiresAt = NOW() + 31 days` | Initial purchase only |

#### Subscription Renewal (RENEWAL event, same productId)

| productId | Currency Grant | Entitlement Grants | Profile Mutations | Notes |
|---|---|---|---|---|
| `play_pass_monthly` | +`PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE` Diamonds | — (already held) | `playPassExpiresAt = NOW() + 31 days` | Re-grant Diamond allowance; extend expiry |

---

### 3.4 Atomic Grant Execution

Currency grants and entitlement grants from a single fulfillment event execute within **one PostgreSQL transaction**. This is non-negotiable.

```typescript
// Pseudocode for atomic multi-grant execution
async function executeGrants(
  txContext: PostgresTransaction,
  userId: string,
  transactionId: string,
  grantPayload: GrantPayload
): Promise<void> {
  // All calls share txContext — they are in the same DB transaction

  for (const currencyGrant of grantPayload.currencyGrants) {
    await currencySystem.grantCurrency(txContext, {
      userId,
      currency: currencyGrant.currency,
      amount: currencyGrant.amount,
      source: 'iap',
      idempotencyKey: `iap:${transactionId}`,
    });
  }

  for (const entitlementGrant of grantPayload.entitlementGrants) {
    await inventorySystem.grantItem(txContext, {
      userId,
      itemId: entitlementGrant.itemId,
      grantSource: 'iap',
      idempotencyKey: `iap:${transactionId}:${entitlementGrant.itemId}`,
    });
  }
  // txContext.commit() called by the caller after this function returns
}
```

**Failure behavior:** If any single grant call throws or returns an error code, the entire `txContext` is rolled back. The player receives nothing. The `iap_transactions` row remains with `fulfilled = false`. The Fulfillment system schedules a retry.

**No partial delivery is acceptable.** A character bundle that grants the character but not the Diamonds is a broken state. The transaction must be atomic.

---

### 3.5 Client Notification

After a successful commit, the Fulfillment system notifies the client through two channels:

**Channel 1 — Socket.io (immediate, if connected):**

```
Server → Client:
Event: "purchase_fulfilled"
Payload: {
  transactionId: string,
  productId: string,
  grantsApplied: Array<{
    type: "currency" | "entitlement",
    currency?: "diamonds" | "coins",
    amount?: number,
    itemId?: string
  }>
}
```

The client, on receiving `purchase_fulfilled`, dismisses any "purchase in progress" spinner, plays the appropriate grant animation (Diamond shower, character unlock celebration, Play Pass activation), and refreshes the profile via `profile:refresh` (which was already emitted by the Currency/Inventory writes).

**Channel 2 — Poll on foreground (if offline during fulfillment):**

If the player is offline when fulfillment completes, the `profile:refresh` cache invalidation ensures the next `GET /profile` call returns the updated state. The client must call `GET /profile` on every app foreground event (from background) and on every reconnect. No special "pending purchase" endpoint is required; the fresh profile state is the confirmation.

---

### 3.6 Reconciliation Job

A background job runs on a 24-hour cron schedule (configurable via `RECONCILIATION_INTERVAL_MS`).

**Algorithm:**

```
1. SELECT * FROM iap_transactions
   WHERE fulfilled = false
     AND refunded = false
     AND created_at < NOW() - INTERVAL '1 hour'
   ORDER BY created_at ASC

2. For each unfulfilled transaction:
   a. Re-run the full pipeline (steps 4–8 of §3.1)
   b. Use the same idempotency keys — Currency and Inventory systems will
      return duplicate:true if grants already applied (e.g., DB flag failed
      to update but grants committed)
   c. After a confirmed successful grant (or confirmed duplicate), mark
      iap_transactions.fulfilled = true

3. After processing all rows:
   - If any transaction.created_at < NOW() - INTERVAL '6 hours' AND still not fulfilled:
     → Trigger on-call alert via logging/monitoring system (ERROR severity)
     → Include: transactionId, userId, productId, age in hours
     → Do not block further reconciliation attempts
```

**Idempotency safety during reconciliation:** The reconciliation job does not need special handling for already-fulfilled transactions. Every step in the pipeline is idempotent. Calling the pipeline on a row where grants already committed but the fulfilled flag was not set results in duplicate-safe no-ops from Currency and Inventory, then sets the flag. No double-grant occurs.

---

### 3.7 Refund Flow

Triggered by a RevenueCat `REFUND` webhook event.

```
1. Receive REFUND event (transactionId, productId, userId)

2. Idempotency check
   - SELECT * FROM iap_transactions WHERE transaction_id = $1
   - If refunded = true → return HTTP 200 (already processed)

3. Resolve original grant from product grant table
   - Determine: original Diamond amount, original entitlements granted

4. Check Diamond spending state
   - Query currency_ledger for entries where source_ref = transactionId
     and delta > 0 (original grant rows)
   - Query current diamond_balance for userId
   - Compare: if diamond_balance >= original_diamond_amount → "unspent"
     (conservative check: balance has enough headroom to absorb the deduction)
   - If diamond_balance < original_diamond_amount → "spent"

5a. Unspent path:
   - BEGIN PostgreSQL transaction
   - Call currencySystem.spendCurrency(txContext, {
       userId, currency: 'diamonds', amount: original_diamond_amount,
       source: 'refund', idempotencyKey: `refund:${transactionId}`
     })
   - For each original entitlement:
       Call inventorySystem.revokeEntitlement(txContext, {
         userId, itemId, revokedBy: 'platform_refund',
         revocationNotes: `RevenueCat REFUND for ${transactionId}`
       })
   - UPDATE iap_transactions SET refunded = true, refunded_at = NOW()
   - COMMIT
   - Emit analytics event purchase_refund_processed with { status: 'reversed' }
   - Emit Socket.io 'purchase_refunded' to client if connected

5b. Spent path:
   - Do NOT deduct Diamonds or revoke entitlements
   - INSERT into iap_refund_flags (userId, transactionId, productId,
       original_diamond_amount, created_at, status = 'pending_review')
   - Log at ERROR: "fulfilled_but_refunded: diamonds already spent"
     fields: { userId, transactionId, productId, originalAmount, currentBalance }
   - Emit analytics event purchase_refund_processed with { status: 'fulfilled_but_refunded' }
   - UPDATE iap_transactions SET refunded = true, refunded_at = NOW(),
       refund_status = 'pending_review'
   - Do NOT deduct below zero. Do NOT corrupt account state.

6. Return HTTP 200 to RevenueCat in both paths
```

**Key invariants:**
- `diamond_balance` can never go below zero as a result of refund processing.
- Entitlement revocations on the spent path require human review — the system cannot automatically determine which Diamonds were "from this purchase" after a spend.
- The `iap_refund_flags` table surfaces to the operations team for manual review.

---

### 3.8 Subscription Renewal

Triggered by a RevenueCat `RENEWAL` webhook event.

```
1. Receive RENEWAL event (transactionId, productId = 'play_pass_monthly', userId)

2. Idempotency check on new transactionId (renewals have distinct transaction IDs)
   - If row exists and fulfilled = true → return HTTP 200

3. Begin PostgreSQL transaction

4. Grant monthly Diamond allowance
   - currencySystem.grantCurrency(txContext, {
       userId, currency: 'diamonds',
       amount: PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE,
       source: 'iap',
       idempotencyKey: `iap:renewal:${transactionId}`
     })

5. Extend Play Pass expiry
   - UPDATE player_profiles
     SET play_pass_expires_at = NOW() + INTERVAL '31 days'
     WHERE user_id = $1
   - (Idempotency: if already extended for this transactionId, the expiry
     is simply set again — idempotent write, same result)

6. INSERT iap_transactions row with fulfilled = true (RENEWAL is fulfilled in one step)

7. COMMIT

8. Emit Socket.io 'subscription_renewed' if connected
9. Emit analytics event purchase_fulfilled with { event: 'renewal' }
10. Return HTTP 200
```

---

### 3.9 Subscription Lapse

Triggered by a RevenueCat `CANCELLATION` event or a payment failure event.

```
1. Receive CANCELLATION event (productId = 'play_pass_monthly', userId)

2. Read current play_pass_expires_at from player_profiles

3. Set grace period expiry
   - grace_expiry = MAX(play_pass_expires_at, NOW()) + PLAY_PASS_GRACE_PERIOD_MS
     (If already expired, grace starts from now; if current, grace extends from it)
   - UPDATE player_profiles
     SET play_pass_expires_at = grace_expiry,
         play_pass_lapsing = true
     WHERE user_id = $1

4. Schedule expiry job
   - Enqueue a delayed job (Redis-backed queue) to fire at grace_expiry:
     payload: { userId, action: 'revoke_play_pass' }

5. On expiry job execution:
   a. Check if player re-subscribed (play_pass_lapsing = false → skip)
   b. If still lapsing:
      - BEGIN transaction
      - inventorySystem.revokeEntitlement(txContext, {
          userId, itemId: 'entitlement_flag:has_play_pass',
          revokedBy: 'subscription_lapse'
        })
      - UPDATE player_profiles SET has_play_pass = false, play_pass_lapsing = false
      - COMMIT
      - Emit Socket.io 'play_pass_expired' if connected
      - Emit analytics event subscription_lapsed

6. Return HTTP 200 to RevenueCat immediately (do not block on delayed job)
```

**Re-subscription during grace period:** If the player re-subscribes before `grace_expiry`, a new `RENEWAL` or `INITIAL_PURCHASE` event arrives. The pipeline sets `play_pass_lapsing = false` and updates `play_pass_expires_at`. The delayed expiry job checks `play_pass_lapsing` before acting and aborts if it is `false`. No double-revocation occurs.

---

### 3.10 TypeScript Interfaces

```typescript
/** Row in iap_transactions table — lifecycle record for each RevenueCat event */
interface IapTransaction {
  id: string;                       // UUID primary key
  transactionId: string;            // RevenueCat transaction_id (UNIQUE)
  userId: string;                   // Supabase user_id
  productId: string;                // RevenueCat product_id
  eventType: IapEventType;          // Type of RevenueCat event
  rawWebhookPayload: object;        // Full webhook JSON (PII-safe: no payment tokens)
  fulfilled: boolean;               // True once all grants committed
  fulfilledAt: string | null;       // ISO 8601 UTC
  refunded: boolean;                // True if REFUND processed
  refundedAt: string | null;        // ISO 8601 UTC
  refundStatus: RefundStatus | null; // 'reversed' | 'pending_review' | null
  createdAt: string;                // ISO 8601 UTC
}

type IapEventType =
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'CANCELLATION'
  | 'REFUND';

type RefundStatus = 'reversed' | 'pending_review';

/** A single item to be granted as part of fulfillment */
interface FulfillmentGrantItem {
  type: 'currency' | 'entitlement' | 'profile_mutation';
  currency?: 'diamonds' | 'coins';
  amount?: number;
  itemId?: string;                  // For entitlement grants
  profileField?: string;            // For profile mutations (e.g., 'playPassExpiresAt')
  profileValue?: string | boolean | number;
}

/** Resolved grant payload for a productId */
interface GrantPayload {
  productId: string;
  grants: FulfillmentGrantItem[];
}

/** Refund flag row for the manual review queue */
interface IapRefundFlag {
  id: string;
  userId: string;
  transactionId: string;
  productId: string;
  originalDiamondAmount: number;
  currentBalanceAtRefund: number;
  status: 'pending_review' | 'reviewed' | 'waived';
  reviewedBy: string | null;        // Admin user ID
  reviewNotes: string | null;
  createdAt: string;
  reviewedAt: string | null;
}

/** Analytics events emitted by the Fulfillment system */
interface PurchaseFulfilledEvent {
  eventName: 'purchase_fulfilled';
  transactionId: string;            // Not a payment token — RevenueCat transaction ID only
  userId: string;
  productId: string;
  eventSubtype: 'initial_purchase' | 'renewal';
  grantsApplied: FulfillmentGrantItem[];
  fulfilledAt: string;
}

interface PurchaseFulfillmentFailedEvent {
  eventName: 'purchase_fulfillment_failed';
  transactionId: string;
  userId: string;
  productId: string;
  failureReason: string;
  attemptNumber: number;
}

interface PurchaseRefundProcessedEvent {
  eventName: 'purchase_refund_processed';
  transactionId: string;
  userId: string;
  productId: string;
  status: 'reversed' | 'fulfilled_but_refunded';
}
```

---

### 3.11 PostgreSQL Schema

```sql
CREATE TABLE iap_transactions (
  id                    uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id        varchar(256)  NOT NULL,
  user_id               uuid          NOT NULL REFERENCES player_profiles(user_id) ON DELETE SET NULL,
  product_id            varchar(128)  NOT NULL,
  event_type            varchar(32)   NOT NULL,   -- 'INITIAL_PURCHASE' | 'RENEWAL' | 'CANCELLATION' | 'REFUND'
  raw_webhook_payload   jsonb         NOT NULL,
  fulfilled             boolean       NOT NULL DEFAULT false,
  fulfilled_at          timestamptz,
  refunded              boolean       NOT NULL DEFAULT false,
  refunded_at           timestamptz,
  refund_status         varchar(32),              -- 'reversed' | 'pending_review' | NULL
  created_at            timestamptz   NOT NULL DEFAULT NOW(),

  CONSTRAINT iap_transactions_transaction_id_unique UNIQUE (transaction_id)
);

CREATE INDEX idx_iap_txn_user_id       ON iap_transactions (user_id);
CREATE INDEX idx_iap_txn_fulfilled     ON iap_transactions (fulfilled, created_at)
  WHERE fulfilled = false;            -- Partial index: only unfulfilled rows; supports reconciliation job
CREATE INDEX idx_iap_txn_product_id    ON iap_transactions (product_id);

CREATE TABLE iap_refund_flags (
  id                       uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  uuid          NOT NULL REFERENCES player_profiles(user_id) ON DELETE SET NULL,
  transaction_id           varchar(256)  NOT NULL,
  product_id               varchar(128)  NOT NULL,
  original_diamond_amount  integer       NOT NULL,
  current_balance_at_refund integer      NOT NULL,
  status                   varchar(32)   NOT NULL DEFAULT 'pending_review',
  reviewed_by              varchar(64),
  review_notes             text,
  created_at               timestamptz   NOT NULL DEFAULT NOW(),
  reviewed_at              timestamptz
);

CREATE INDEX idx_refund_flags_status ON iap_refund_flags (status) WHERE status = 'pending_review';
CREATE INDEX idx_refund_flags_user   ON iap_refund_flags (user_id);

CREATE TABLE product_grant_definitions (
  product_id      varchar(128)  PRIMARY KEY,
  grant_payload   jsonb         NOT NULL,    -- Serialized GrantPayload[]
  is_active       boolean       NOT NULL DEFAULT true,
  updated_at      timestamptz   NOT NULL DEFAULT NOW()
);
```

---

### 3.12 Logging and PII Policy

All Fulfillment log entries use the `ILogger` interface from `logging-monitoring.md`.

| Log Level | When | Fields Logged |
|---|---|---|
| `INFO` | Webhook received | `transactionId`, `productId`, `eventType` |
| `INFO` | Fulfillment succeeded | `transactionId`, `productId`, `userId` (UUID), `grantsApplied` (type + amount, not raw payment data) |
| `WARN` | Duplicate webhook received | `transactionId`, `eventType` |
| `WARN` | Product ID not found in grant map | `productId`, `transactionId` |
| `ERROR` | Fulfillment failed after grant attempt | `transactionId`, `userId`, `failureReason`, `attemptNumber` |
| `ERROR` | Transaction unfulfilled > 6h | `transactionId`, `userId`, `productId`, `ageHours` |
| `ERROR` | fulfilled_but_refunded flag set | `transactionId`, `userId`, `productId`, `originalAmount` |

**PII policy:** No payment tokens, store receipt data, or billing information may appear in any log entry. The `raw_webhook_payload` is stored in the database (for audit) but never written to logs. Log entries reference only `transactionId` (RevenueCat's opaque ID), `userId` (UUID pseudonym), and `productId`. This policy is enforced by logging only the fields listed above — no spread of the full webhook payload object.

---

### 3.13 Analytics Events

Per `analytics-telemetry.md`, the following are Tier 0 events (highest priority, never sampled away):

| Event Name | Trigger | Tier |
|---|---|---|
| `purchase_fulfilled` | Successful fulfillment committed | 0 |
| `purchase_fulfillment_failed` | Fulfillment failed after max retries or on unknown product | 0 |
| `purchase_refund_processed` | REFUND webhook fully processed (either path) | 0 |

---

## 4. Formulas

### 4.1 Product Grant Table (Complete)

The authoritative mapping of `productId` to items granted. All values are in-game units.

| productId | Diamonds Granted | Entitlements Granted | Play Pass Extension |
|---|---|---|---|
| `diamonds_starter` | 80 | — | — |
| `diamonds_small` | 200 | — | — |
| `diamonds_medium` | 500 | — | — |
| `diamonds_large` | 1,100 | — | — |
| `diamonds_xlarge` | 2,400 | — | — |
| `diamonds_mega` | 6,500 | — | — |
| `character_bundle_colt` | 50 | `character:colt`, `skin:colt_default` | — |
| `character_bundle_nyx` | 50 | `character:nyx`, `skin:nyx_default` | — |
| `play_pass_monthly` (initial) | `PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE` | `entitlement_flag:has_play_pass` | +31 days from NOW() |
| `play_pass_monthly` (renewal) | `PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE` | — (idempotent no-op) | +31 days from NOW() |

**Example — `character_bundle_colt`:**

A player purchases `character_bundle_colt`. The grant payload resolves to:
- `grantCurrency({ currency: 'diamonds', amount: 50, idempotencyKey: 'iap:rc-txn-99' })`
- `grantItem({ itemId: 'character:colt', idempotencyKey: 'iap:rc-txn-99:character:colt' })`
- `grantItem({ itemId: 'skin:colt_default', idempotencyKey: 'iap:rc-txn-99:skin:colt_default' })`

All three execute in one PostgreSQL transaction. If the player already owned `character:colt`, the `grantItem` for the character returns `{ duplicate: true }` and the transaction proceeds to completion — the player still receives the 50 Diamonds and the default skin.

---

### 4.2 Play Pass Monthly Diamond Allowance

```
PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE = 300 Diamonds (default)
```

This is a Remote Config cold key (`fulfillment.playPassMonthlyDiamondAllowance`). It applies on both the initial purchase and on every renewal. The allowance is subject to the Diamond wallet cap (100,000 Diamonds) enforced by the Currency System.

**Example — initial purchase:**
Player with `diamond_balance: 150` purchases `play_pass_monthly`.
- Diamond grant: +300 → `diamond_balance` becomes 450
- `has_play_pass` entitlement granted
- `playPassExpiresAt` set to 31 days from now

**Example — renewal:**
Player with `diamond_balance: 1200` and `playPassExpiresAt` = tomorrow:
- Diamond grant: +300 → `diamond_balance` becomes 1500
- `playPassExpiresAt` extended to 31 days from now
- No new `has_play_pass` entitlement row (already held; `duplicate: true`)

---

### 4.3 Grace Period for Subscription Lapse

```
lapseGracePeriodMs = PLAY_PASS_GRACE_PERIOD_DAYS × 86400000

where:
  PLAY_PASS_GRACE_PERIOD_DAYS = 3 (default)
  86400000 = milliseconds per day

lapseGracePeriodMs = 3 × 86400000 = 259200000 ms (3 days)
```

**Grace expiry calculation:**

```
graceExpiry = MAX(currentPlayPassExpiresAt, NOW()) + lapseGracePeriodMs
```

**Example — cancellation while subscription is active:**
- Current `playPassExpiresAt` = 2026-06-10T12:00:00Z
- NOW() = 2026-06-05T09:00:00Z
- `MAX(2026-06-10, 2026-06-05)` = 2026-06-10
- `graceExpiry` = 2026-06-10T12:00:00Z + 259200000 ms = 2026-06-13T12:00:00Z

The player retains Play Pass access until June 13 despite cancelling on June 5. If they re-subscribe before June 13, `play_pass_lapsing` is cleared and expiry is extended normally.

**Example — cancellation after subscription already expired:**
- Current `playPassExpiresAt` = 2026-05-20T00:00:00Z (10 days ago)
- NOW() = 2026-05-30T00:00:00Z
- `MAX(2026-05-20, 2026-05-30)` = 2026-05-30
- `graceExpiry` = 2026-05-30T00:00:00Z + 259200000 ms = 2026-06-02T00:00:00Z

The 3-day grace still applies from the current moment, even if the original subscription period had already elapsed.

---

### 4.4 Reconciliation Age Thresholds

```
RECONCILIATION_RETRY_MIN_AGE_MS = 3600000        (1 hour = 60 × 60 × 1000)
RECONCILIATION_ALERT_THRESHOLD_MS = 21600000     (6 hours = 6 × 60 × 60 × 1000)
```

A transaction qualifies for reconciliation if:

```
ageMs = NOW() - transaction.created_at (in milliseconds)
eligible = ageMs >= RECONCILIATION_RETRY_MIN_AGE_MS AND fulfilled = false AND refunded = false
alert    = ageMs >= RECONCILIATION_ALERT_THRESHOLD_MS AND fulfilled = false AND refunded = false
```

**Example:**
Transaction created at 08:00 UTC. Reconciliation job runs at 10:00 UTC.
- `ageMs = 7200000` (2 hours)
- `eligible: 7200000 >= 3600000 → true` — will be retried
- `alert: 7200000 >= 21600000 → false` — no alert yet

Same transaction at next run at 16:00 UTC:
- `ageMs = 28800000` (8 hours)
- `alert: 28800000 >= 21600000 → true` — on-call alert fires

---

### 4.5 Retry Backoff for Webhook Failures

When a fulfillment attempt fails (grant transaction rolled back), the system schedules retries with exponential backoff before the reconciliation job covers it:

```
retryDelayMs(attempt) = RETRY_BASE_DELAY_MS × (2 ^ (attempt - 1))

where:
  RETRY_BASE_DELAY_MS = 30000 (30 seconds, default)
  attempt: integer starting at 1
  cap: RETRY_MAX_DELAY_MS = 1800000 (30 minutes, default)

retryDelayMs(1) = 30000 × 2^0 = 30,000 ms  (30 seconds)
retryDelayMs(2) = 30000 × 2^1 = 60,000 ms  (1 minute)
retryDelayMs(3) = 30000 × 2^2 = 120,000 ms (2 minutes)
retryDelayMs(4) = 30000 × 2^3 = 240,000 ms (4 minutes)
retryDelayMs(5) = min(30000 × 2^4, 1800000) = min(480000, 1800000) = 480,000 ms (8 minutes)
retryDelayMs(6) = min(30000 × 2^5, 1800000) = min(960000, 1800000) = 960,000 ms (16 minutes)
retryDelayMs(7+) = 1,800,000 ms (30 minutes, capped)
```

After `RETRY_MAX_ATTEMPTS` (default 7) inline retries without success, the system relies on the reconciliation job for further recovery.

---

## 5. Edge Cases

### 5.1 Out-of-Order Webhooks: RENEWAL Before INITIAL_PURCHASE

**Scenario:** Due to RevenueCat or network timing, a `RENEWAL` webhook arrives before the `INITIAL_PURCHASE` webhook for the same subscription. No row exists in `iap_transactions` for the user's initial purchase yet.

**Resolution:**

1. The `RENEWAL` webhook arrives. The Fulfillment system attempts `INSERT INTO iap_transactions (transaction_id: 'rc-renewal-99', event_type: 'RENEWAL', ...)`. This succeeds — the renewal has its own distinct `transactionId`.
2. The system proceeds to determine the grant for `play_pass_monthly` on a `RENEWAL` event: +`PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE` Diamonds + extend `playPassExpiresAt`.
3. It also checks whether the player already holds the `entitlement_flag:has_play_pass` entitlement. They do not (INITIAL_PURCHASE not yet processed). The renewal pipeline grants the Diamond allowance and extends expiry but does not include the `has_play_pass` entitlement in the renewal grant payload.
4. When the `INITIAL_PURCHASE` webhook arrives later (possibly minutes or hours late), it processes normally: grants the Diamond allowance with its own `idempotencyKey`, grants `has_play_pass` entitlement, and sets `playPassExpiresAt`. The Diamond allowance from step 3 was already granted, but the INITIAL_PURCHASE uses a different `idempotencyKey` (`iap:rc-txn-initial-88` vs. `iap:renewal:rc-renewal-99`) — both grants apply independently.

**Net result:** The player receives the allowance twice (once from the out-of-order RENEWAL, once from the INITIAL_PURCHASE), which may grant them 2× the monthly allowance in this edge case. This is the correct behavior: each webhook event is an independent fulfillment obligation. RevenueCat does not send a RENEWAL for a subscription that has no INITIAL_PURCHASE; if this occurs, it indicates a RevenueCat delivery anomaly rather than a normal billing cycle, and the double-grant is acceptable given the rarity.

If this edge case becomes frequent (tracked via analytics on `purchase_fulfilled` events with `eventSubtype: 'renewal'` for accounts with no prior `INITIAL_PURCHASE`), the mitigation is to defer RENEWAL fulfillment by 60 seconds to allow INITIAL_PURCHASE to arrive first (configurable via `RENEWAL_DEFER_IF_NO_INITIAL_PURCHASE_MS`). This tuning knob defaults to 0 (no deferral) at launch.

---

### 5.2 Partial Grant: Currency Deducted But Entitlement Not Written

**Scenario:** The `character_bundle_colt` fulfillment begins. The Diamond grant (`+50`) commits to the Currency System within the shared transaction. Then the `grantItem` call for `character:colt` throws a database timeout error before committing.

**Resolution:**

Because all grants execute within a single PostgreSQL transaction (§3.4), the Diamond grant has not yet committed at the point of failure — it is inside an open, uncommitted transaction. The exception from `grantItem` causes the caller to issue a `ROLLBACK` on the shared `txContext`. The Diamond grant is rolled back along with the entitlement write.

No partial state is written. The player's `diamond_balance` is unchanged. No entitlement row exists for `character:colt`. The `iap_transactions` row remains with `fulfilled = false`. The retry schedule activates.

**The key invariant:** The Currency System's `grantCurrency` and the Inventory System's `grantItem` must accept an external `txContext` parameter and must not internally commit that transaction. The Fulfillment system is the transaction owner. Any implementation that auto-commits internally violates this contract and must be corrected before the first IAP integration test.

---

### 5.3 Player Account Deleted Before Fulfillment Completes

**Scenario:** A player completes a purchase. Before the webhook is processed, the player account is soft-deleted (or hard-deleted via GDPR request). The webhook arrives and the Fulfillment system attempts to grant items to a non-existent `user_id`.

**Resolution:**

1. The Fulfillment system's pipeline attempts `INSERT INTO iap_transactions (user_id: $1, ...)`. If the `player_profiles` row has been hard-deleted, the foreign key constraint (`REFERENCES player_profiles(user_id) ON DELETE SET NULL`) sets `user_id = NULL` on the `iap_transactions` row (if the profile is deleted after the row is inserted) or the INSERT fails with a FK violation (if deleted before).
2. The Currency System's `grantCurrency` with a non-existent or NULL `userId` returns an error code `USER_NOT_FOUND`.
3. The Fulfillment system logs the error at `WARN` (not `ERROR`, since a deleted account is an expected state) with `transactionId` and `productId`, marks the transaction with `fulfilled = false, skip_reason = 'account_deleted'`, and does not retry.
4. The reconciliation job skips rows with `skip_reason IS NOT NULL`.
5. If the account deletion was a GDPR hard-delete, the `iap_transactions` row is purged as part of the GDPR delete cascade (per `ON DELETE CASCADE` or GDPR delete procedure). No fulfillment obligation remains.
6. If the account deletion was erroneous (admin action corrected), operations can re-trigger fulfillment manually via the admin API after restoring the account.

The player cannot receive items they purchased if their account is deleted. No refund is automatically issued — the payment is a platform concern. Operations must handle any payment dispute through RevenueCat's dashboard.

---

### 5.4 Race Condition: Two Webhooks for Same transactionId Within 100ms

**Scenario:** RevenueCat delivers a webhook twice in extremely rapid succession (< 100ms apart) due to a delivery retry triggered by a brief network hiccup. Both webhook invocations reach the server essentially simultaneously and both attempt to process the same `transactionId`.

**Resolution:**

The `UNIQUE` constraint on `iap_transactions.transaction_id` is the primary guard:

1. Both requests attempt `INSERT INTO iap_transactions (transaction_id: 'rc-txn-77', ...) ON CONFLICT (transaction_id) DO NOTHING`.
2. PostgreSQL serializes concurrent INSERTs on the same unique key. Exactly one INSERT succeeds (inserts 1 row). The other returns 0 rows affected.
3. The request whose INSERT returned 0 rows reads the existing row. If `fulfilled = false` (the first request hasn't completed yet), both requests may attempt to proceed with the grant.
4. To prevent double-grant in this window: the pipeline uses `UPDATE iap_transactions SET processing = true WHERE transaction_id = $1 AND processing = false RETURNING id`. This `UPDATE ... RETURNING` is atomic in PostgreSQL — only one of the two concurrent requests will receive a returned row. The other receives 0 rows and exits immediately with HTTP 200.
5. The winning request completes the full pipeline and sets `fulfilled = true, processing = false`.

**Net result:** Exactly one fulfillment execution, even under sub-100ms concurrent delivery. The second webhook receives HTTP 200 (not an error), preventing RevenueCat from retrying further.

**`processing` column addition to `iap_transactions`:**

```sql
ALTER TABLE iap_transactions ADD COLUMN processing boolean NOT NULL DEFAULT false;
CREATE INDEX idx_iap_txn_processing ON iap_transactions (processing) WHERE processing = true;
```

The `processing` flag is reset to `false` on commit or rollback (via application logic or a cleanup job for orphaned rows where `processing = true AND created_at < NOW() - INTERVAL '10 minutes'`).

---

### 5.5 Diamond Wallet Cap Reached During Grant

**Scenario:** A player has `diamond_balance: 99,980`. They purchase `diamonds_mega` (+6,500 Diamonds). The grant would result in 106,480 Diamonds, exceeding the 100,000 cap.

**Resolution:**

The Currency System (not the Fulfillment system) enforces the wallet cap per `currency-system.md §3.5`. The Fulfillment system calls `grantCurrency({ amount: 6500, ... })` and receives back:

```json
{
  "success": true,
  "actualAmount": 20,
  "requestedAmount": 6500,
  "newBalance": 100000,
  "capped": true,
  "droppedAmount": 6480
}
```

The Fulfillment system:
1. Treats this as a successful grant (the Currency System returned success).
2. Marks `iap_transactions.fulfilled = true`.
3. Logs at `WARN`: `"diamond_grant_capped: transactionId, requestedAmount: 6500, actualAmount: 20, droppedAmount: 6480"`.
4. Emits `purchase_fulfilled` analytics event with `grantsApplied[0].amount = 20` (the actual amount applied).
5. Sends `purchase_fulfilled` Socket.io event to the client with `actualAmount: 20`.

**The player receives only 20 Diamonds** (cap headroom). The remaining 6,480 Diamonds are lost. This is the correct behavior per the wallet cap design: the cap is a hard limit, not a deferral queue. The player is responsible for spending down their balance before purchasing additional Diamonds. The UI layer (store screen) should display a warning when the player's balance is within one package size of the cap (`diamond_balance > DIAMOND_CAP - SMALLEST_PACKAGE_AMOUNT`).

No refund is automatically triggered. If the player disputes this, operations can verify via the `currency_ledger` that `requested_amount: 6500, actual_amount: 20, balance_after: 100000` and use their judgment on a manual Diamond grant up to the cap shortfall.

---

## 6. Dependencies

### 6.1 Upstream — Fulfillment Consumes

| System | What Fulfillment Needs | Interface | Failure Mode |
|---|---|---|---|
| **IAP System** (`iap-system.md`) | RevenueCat webhook events (`INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `REFUND`); each event carries `transactionId`, `productId`, `userId` (mapped from RevenueCat's `app_user_id`), and `eventType`. The IAP System validates HMAC signatures before handing to Fulfillment. | RevenueCat webhook → internal fan-out | Fulfillment must not process unsigned webhooks. If IAP System is bypassed, Fulfillment rejects. |
| **Authentication** (`authentication.md`) | `userId` UUID must be validated as an existing Supabase account before any grant is executed. Webhooks carry `app_user_id` (RevenueCat's field), which must be the player's Supabase UUID. | `auth.getUser(userId)` before pipeline step 4 | If user lookup fails, defer the transaction with `skip_reason = 'user_lookup_failed'`; retry via reconciliation. |
| **Remote Config** (`remote-config.md`) | `fulfillment.productGrantMap` cold key (product → grant payload map); `fulfillment.playPassGracePeriodDays`; `fulfillment.playPassMonthlyDiamondAllowance`; `fulfillment.retryBasedelayMs`; `fulfillment.reconciliationIntervalMs`. | Loaded at server startup; fallback to `product_grant_definitions` DB table. | If Remote Config unreachable at startup, DB table serves as fallback. Both must be kept in sync. |
| **Player Profile** (`player-profile.md`) | Reads and writes `playPassExpiresAt`, `hasPlayPass`, `playPassLapsing` fields during subscription events. Profile invalidation (`profile:refresh` Socket.io + Redis DELETE) is triggered by Currency/Inventory write calls, not by Fulfillment directly. | PostgreSQL `player_profiles` table; writes within shared `txContext`. | If profile write fails, transaction rolls back. |

### 6.2 Downstream — Fulfillment Produces / Notifies

| System | What Fulfillment Calls | Interface | Guarantee Required |
|---|---|---|---|
| **Currency System** (`currency-system.md`) | `grantCurrency(txContext, { userId, currency, amount, source: 'iap', idempotencyKey })` | Synchronous DB call within shared transaction | Idempotent by `idempotencyKey`. Must accept external `txContext`. Must not auto-commit. |
| **Inventory / Entitlements** (`inventory-entitlements.md`) | `grantItem(txContext, { userId, itemId, grantSource: 'iap', idempotencyKey })` and `revokeEntitlement(txContext, { userId, itemId, revokedBy })` | Synchronous DB call within shared transaction | Idempotent grant. Revocation within same transaction on refund path. Must accept external `txContext`. |
| **Player Profile** (`player-profile.md`) | Writes `playPassExpiresAt`, `playPassLapsing` within transaction; indirectly triggers `profile:refresh` via Currency/Inventory Redis invalidation. | PostgreSQL UPDATE within shared `txContext` | Profile field writes are part of the atomic transaction. |
| **Realtime Transport** (`realtime-transport.md`) | Emits `purchase_fulfilled`, `purchase_refunded`, `subscription_renewed`, `play_pass_expired` Socket.io events to the player's socket after commit. | `io.to(userId).emit(event, payload)` | Fire-and-forget after commit. Missed events are recovered by client polling on foreground. |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | Emits Tier 0 events: `purchase_fulfilled`, `purchase_fulfillment_failed`, `purchase_refund_processed`. | Async fire-and-forget after commit | Events must not be emitted before transaction commit (no false positives on failed grants). |
| **Logging / Monitoring** (`logging-monitoring.md`) | `ILogger` for all pipeline steps. On-call alerts on `ageMs >= RECONCILIATION_ALERT_THRESHOLD_MS`. | `logger.error(...)` for failures; `logger.info(...)` for success | PII policy enforced: no payment tokens, no receipt data in logs. |

### 6.3 Architectural Note: Fulfillment Owns Nothing Permanently

The Fulfillment system is stateless except for the `iap_transactions` and `iap_refund_flags` tables it manages. It does not cache product grants in Redis, does not hold balances, and does not serve read endpoints. Any system needing to know if a player made a purchase queries `iap_transactions` (for audit) or queries the Currency/Inventory systems (for current state). Fulfillment's scope is the pipeline — not the state the pipeline produces.

---

## 7. Tuning Knobs

All values are Remote Config **cold keys** (require server restart) unless marked **Hot**. Cold-key classification is intentional: mid-flight changes to fulfillment logic can produce inconsistent states if webhooks are being processed during the change.

| Parameter | Remote Config Key | Default | Safe Range | Notes |
|---|---|---|---|---|
| Play Pass monthly Diamond allowance | `fulfillment.playPassMonthlyDiamondAllowance` | `300` | 100–1000 | Below 100: Play Pass Diamond perk feels negligible vs. IAP packages. Above 1000: monthly grant approaches a paid Diamond package in value, reducing standalone Diamond IAP appeal. |
| Play Pass grace period (days) | `fulfillment.playPassGracePeriodDays` | `3` | 1–7 | Below 1: too short for payment retry cycles on some platforms (Apple may retry up to 3 days). Above 7: grace period approaches next billing cycle; player retains premium access for almost a full billing period after cancellation. |
| Reconciliation job interval | `fulfillment.reconciliationIntervalMs` | `86400000` (24h) | 3600000–86400000 | Lower bound (1 hour) reduces max delay for unfulfilled transactions but increases DB scan frequency. Default 24h is safe for most traffic volumes. |
| Reconciliation retry min age | `fulfillment.reconciliationRetryMinAgeMs` | `3600000` (1h) | 300000–7200000 | Below 5 minutes: reconciliation may re-attempt transactions still being processed in the inline retry window. Above 2 hours: transactions can sit unfulfilled for 2+ hours before reconciliation picks them up. |
| On-call alert threshold | `fulfillment.reconciliationAlertThresholdMs` | `21600000` (6h) | 3600000–86400000 | Should be > reconciliation interval to allow at least one reconciliation pass before alerting. Must be < 24h to catch issues within the same business day. |
| Webhook inline retry base delay | `fulfillment.retryBaseDelayMs` | `30000` | 5000–120000 | Below 5s: too aggressive; may overwhelm a degraded DB during recovery. Above 120s: combined retry window extends past 30 minutes, reducing benefit over reconciliation-only recovery. |
| Max inline retry attempts | `fulfillment.retryMaxAttempts` | `7` | 3–10 | Below 3: insufficient for transient failures. Above 10: extends total inline retry window beyond 1 hour; reconciliation job is a more reliable recovery path for persistent failures. |
| Max inline retry delay cap | `fulfillment.retryMaxDelayMs` | `1800000` (30m) | 300000–3600000 | Cap prevents infinite delay growth. At 30 minutes, 7 attempts span ~60 minutes total before reconciliation takes over. |
| Renewal deferral (out-of-order guard) | `fulfillment.renewalDeferIfNoInitialPurchaseMs` | `0` (disabled) | 0–60000 | 0 = no deferral (default). Set to 30000–60000 if out-of-order RENEWAL-before-INITIAL_PURCHASE is observed in production analytics. |
| Processing lock cleanup age | `fulfillment.processingLockCleanupMinutes` | `10` | 5–30 | Orphaned `processing = true` rows older than this threshold are reset to `processing = false` by a cleanup sweep. Below 5 minutes risks resetting legitimately in-progress slow transactions. Above 30 minutes leaves stale locks blocking the race-condition guard for too long. |
| Character bundle bonus Diamonds — Colt | `fulfillment.bundleBonusDiamondsCharColt` | `50` | 0–500 | Diamonds included in character_bundle_colt. Set to 0 to make bundles a character + skin only, no currency. Above 500 approaches the value of a standalone Diamond package. |
| Character bundle bonus Diamonds — Nyx | `fulfillment.bundleBonusDiamondsCharNyx` | `50` | 0–500 | Same as above for Nyx bundle. |

---

## 8. Acceptance Criteria

### 8.1 Core Pipeline

**AC-PF-01 — Successful initial purchase: Diamond package**
- Given: RevenueCat sends a valid HMAC-signed `INITIAL_PURCHASE` webhook for `diamonds_medium` (`+500 Diamonds`) for `userId: "player-abc"`
- When: The Fulfillment pipeline processes the webhook
- Then: Within 5 seconds: (a) `iap_transactions` row exists with `fulfilled = true`; (b) `diamond_balance` for `player-abc` increased by 500; (c) `currency_ledger` row exists with `source: 'iap'`, `delta: 500`, `source_ref: transactionId`; (d) Socket.io `purchase_fulfilled` event emitted to `player-abc` (if connected); (e) `purchase_fulfilled` analytics Tier 0 event emitted; (f) HTTP 200 returned to RevenueCat

**AC-PF-02 — Successful initial purchase: character bundle**
- Given: RevenueCat sends a valid `INITIAL_PURCHASE` webhook for `character_bundle_colt` for `userId: "player-xyz"` who does not own `character:colt`
- When: The Fulfillment pipeline processes the webhook
- Then: (a) `iap_transactions.fulfilled = true`; (b) `diamond_balance` increased by 50; (c) `entitlements` row exists for `(player-xyz, character:colt)` with `is_revoked = false`; (d) `entitlements` row exists for `(player-xyz, skin:colt_default)`; (e) all three grants share the same `txContext` and committed atomically; (f) `purchase_fulfilled` analytics event includes all three grants in `grantsApplied`

**AC-PF-03 — Unsigned webhook rejected**
- Given: A webhook arrives at `POST /webhooks/revenuecat` without a valid HMAC signature
- When: The Fulfillment system validates the request
- Then: HTTP 401 returned; no row inserted in `iap_transactions`; `WARN` log entry written; no grant executed

---

### 8.2 Idempotency

**AC-PF-04 — Duplicate webhook: already fulfilled**
- Given: A `INITIAL_PURCHASE` webhook for `transactionId: "rc-txn-55"` was already processed and `iap_transactions.fulfilled = true`
- When: An identical webhook for `rc-txn-55` arrives
- Then: HTTP 200 returned immediately; no second grant executed; `iap_transactions` row unchanged (still `fulfilled = true`); no duplicate `currency_ledger` row; no duplicate `entitlements` row; no analytics event re-emitted

**AC-PF-05 — Duplicate webhook: race condition within 100ms**
- Given: Two identical webhooks for `transactionId: "rc-txn-66"` arrive within 100ms of each other
- When: Both are processed concurrently
- Then: Exactly one fulfillment completes (grants applied once); the other request returns HTTP 200 without executing grants; `iap_transactions` contains exactly one row for `rc-txn-66`; Currency and Inventory systems contain no duplicate ledger/grant entries; no error logged

---

### 8.3 Atomicity

**AC-PF-06 — Partial grant failure rolls back entirely**
- Given: A `character_bundle_colt` fulfillment begins; the Diamond grant (`+50`) is queued in an open transaction; then `grantItem` for `character:colt` throws a simulated DB error
- When: The transaction attempts to commit
- Then: The entire transaction rolls back; `diamond_balance` unchanged; no `entitlements` row for `character:colt`; `iap_transactions.fulfilled` remains `false`; retry is scheduled; `purchase_fulfillment_failed` analytics event emitted

**AC-PF-07 — Unknown productId handled without retry loop**
- Given: RevenueCat sends a webhook with `productId: "unknown_product_xyz"`
- When: The Fulfillment system processes the webhook
- Then: HTTP 200 returned to RevenueCat (no retry requested); `iap_transactions` row inserted with `fulfilled = false, skip_reason = 'unknown_product'`; `WARN` log written; ops alerted; reconciliation job skips this row

---

### 8.4 Reconciliation

**AC-PF-08 — Reconciliation retries unfulfilled transactions**
- Given: An `iap_transactions` row with `fulfilled = false` and `created_at = NOW() - 2 hours`
- When: The reconciliation job runs
- Then: The pipeline re-executes for this transaction; if grants succeed, `fulfilled` is set to `true`; if grants were already applied (idempotent), `fulfilled` is corrected to `true`; no double-grant occurs regardless of prior state

**AC-PF-09 — On-call alert fires for transactions unfulfilled > 6 hours**
- Given: An `iap_transactions` row with `fulfilled = false` and `created_at = NOW() - 7 hours`
- When: The reconciliation job runs
- Then: An on-call alert is triggered at `ERROR` log level with `transactionId`, `userId`, `productId`, and `ageHours`; the reconciliation job still attempts fulfillment for this row; the alert fires once per reconciliation pass (not per row repeatedly without debounce)

---

### 8.5 Subscription Flows

**AC-PF-10 — Play Pass initial purchase grants entitlement and Diamonds**
- Given: RevenueCat sends `INITIAL_PURCHASE` for `play_pass_monthly` for `userId: "player-sub"`
- When: Fulfillment processes the webhook
- Then: (a) `diamond_balance` increased by `PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE` (default 300); (b) `entitlements` row exists for `entitlement_flag:has_play_pass`; (c) `player_profiles.has_play_pass = true`; (d) `player_profiles.play_pass_expires_at` set to approximately `NOW() + 31 days` (within 60 seconds of actual webhook processing time); (e) all writes in one committed transaction

**AC-PF-11 — Play Pass renewal re-grants Diamond allowance and extends expiry**
- Given: Player holds active `has_play_pass` entitlement; RevenueCat sends `RENEWAL` for `play_pass_monthly` with a new `transactionId`
- When: Fulfillment processes the webhook
- Then: (a) `diamond_balance` increased by `PLAY_PASS_MONTHLY_DIAMOND_ALLOWANCE`; (b) no second `entitlements` row for `has_play_pass` (idempotent no-op with `duplicate: true`); (c) `play_pass_expires_at` extended by 31 days from renewal processing time; (d) new `iap_transactions` row with `fulfilled = true` for the renewal `transactionId`

**AC-PF-12 — Play Pass cancellation sets grace period and does not immediately revoke**
- Given: Player holds active `has_play_pass`; RevenueCat sends `CANCELLATION` for `play_pass_monthly`
- When: Fulfillment processes the webhook
- Then: (a) `player_profiles.play_pass_lapsing = true`; (b) `play_pass_expires_at` set to `MAX(current_expiry, NOW()) + 3 days`; (c) `has_play_pass` entitlement NOT yet revoked; (d) a delayed job is enqueued to fire at the new `play_pass_expires_at`

**AC-PF-13 — Play Pass revocation fires at grace period expiry**
- Given: `play_pass_lapsing = true` and grace period expires (delayed job fires)
- When: The expiry job executes
- Then: (a) `entitlements` row for `has_play_pass` has `is_revoked = true`; (b) `player_profiles.has_play_pass = false, play_pass_lapsing = false`; (c) Socket.io `play_pass_expired` event emitted; (d) analytics event `subscription_lapsed` emitted

**AC-PF-14 — Re-subscription during grace period cancels revocation**
- Given: Player is in grace period (`play_pass_lapsing = true`); they re-subscribe and RevenueCat sends `INITIAL_PURCHASE` or `RENEWAL` before grace expiry
- When: Fulfillment processes the re-subscription
- Then: `play_pass_lapsing` set to `false`; `play_pass_expires_at` updated to 31 days from now; the pending expiry job finds `play_pass_lapsing = false` and exits without revoking; player retains continuous `has_play_pass` access

---

### 8.6 Refund Flow

**AC-PF-15 — Refund reversed: Diamonds not yet spent**
- Given: Player purchased `diamonds_medium` (`+500 Diamonds`); `diamond_balance` is still ≥ 500; RevenueCat sends `REFUND` for that `transactionId`
- When: Fulfillment processes the refund
- Then: (a) `diamond_balance` reduced by 500; (b) `currency_ledger` row with `source: 'refund'`, `delta: -500`, `source_ref: transactionId`; (c) `iap_transactions.refunded = true, refund_status = 'reversed'`; (d) `purchase_refund_processed` analytics event with `status: 'reversed'`; (e) balance never goes below zero

**AC-PF-16 — Refund flagged: Diamonds already spent**
- Given: Player purchased `diamonds_medium` (`+500 Diamonds`); `diamond_balance` is 50 (Diamonds were spent); RevenueCat sends `REFUND`
- When: Fulfillment processes the refund
- Then: (a) `diamond_balance` NOT modified (no deduction); (b) `iap_refund_flags` row created with `status: 'pending_review'`; (c) `iap_transactions.refunded = true, refund_status = 'pending_review'`; (d) ERROR log written: `fulfilled_but_refunded`; (e) `purchase_refund_processed` analytics event with `status: 'fulfilled_but_refunded'`; (f) `diamond_balance` never goes below 0

**AC-PF-17 — Duplicate REFUND webhook is no-op**
- Given: A REFUND for `transactionId: "rc-txn-77"` was already processed (`iap_transactions.refunded = true`)
- When: An identical REFUND webhook arrives
- Then: HTTP 200 returned immediately; no second Diamond deduction; no second `iap_refund_flags` row; `iap_transactions` row unchanged

---

### 8.7 Edge Cases

**AC-PF-18 — Diamond wallet cap during IAP grant**
- Given: Player has `diamond_balance: 99,980`; they purchase `diamonds_mega` (+6,500 Diamonds)
- When: Fulfillment calls `grantCurrency({ amount: 6500 })`
- Then: (a) Currency System returns `{ actualAmount: 20, capped: true, droppedAmount: 6480 }`; (b) Fulfillment marks `iap_transactions.fulfilled = true`; (c) `WARN` log records `droppedAmount: 6480`; (d) Socket.io `purchase_fulfilled` payload shows `actualAmount: 20`; (e) `purchase_fulfilled` analytics event records actual amount granted; (f) no error returned to RevenueCat

**AC-PF-19 — Deleted account does not block RevenueCat webhook**
- Given: Player account `user_id: "deleted-player"` has been hard-deleted; RevenueCat sends `INITIAL_PURCHASE` for this user
- When: Fulfillment processes the webhook
- Then: HTTP 200 returned to RevenueCat (no retry requested); `iap_transactions` row inserted with `user_id = NULL` (FK SET NULL), `fulfilled = false, skip_reason = 'account_deleted'`; `WARN` log written with `transactionId`; no grant attempted; reconciliation job skips rows with `skip_reason IS NOT NULL`

**AC-PF-20 — PII policy: no payment tokens in logs**
- Given: Any Fulfillment pipeline step executes (success or failure)
- When: Log entries are written to the logging system
- Then: No log entry contains raw RevenueCat receipt data, Apple/Google payment tokens, or billing information; log entries contain only `transactionId` (RevenueCat opaque ID), `userId` (UUID), `productId`, and structured metadata fields as defined in §3.12

---

*End of Document*
