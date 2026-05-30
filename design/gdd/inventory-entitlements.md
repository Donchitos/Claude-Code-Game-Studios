# Inventory / Entitlements — Game Design Document

> **System**: Inventory / Entitlements
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

The Inventory / Entitlements system is the server-authoritative record of everything a player owns in BRAWLZONE. It manages two distinct ownership concepts that must never be conflated: **entitlements** (boolean, non-stackable ownership records — you either own a character or you do not) and **inventory items** (quantity-tracked, stackable items such as chests or event tickets). The Content Catalog is the source of truth for what items can exist; this system is the source of truth for which of those items a given player currently owns and in what quantity. Every grant — whether from IAP fulfillment via RevenueCat, a Coin or Diamond spend, a progression milestone, an admin action, or a promotional code — flows through a single, server-side grant pipeline that enforces idempotency, atomicity, and audit logging. Every ownership check — whether at character select, in the loadout screen, or at match-start server validation — is answered by this system from a Redis-cached hot path backed by PostgreSQL. Entitlements are permanent and non-expiring unless revoked through the defined revocation flow. No client may assert ownership; all ownership decisions are server-authoritative.

---

## 2. Player Fantasy

### Ownership Feels Permanent and Trustworthy

When a player unlocks Grim after grinding to the Coins threshold, or purchases Nyx as a premium character, the game must immediately and durably reflect that ownership everywhere: in the character roster, in the character select screen, and in any future match. Players should never experience a state where they "own" something on one screen but cannot select it on another. Ownership is permanent from the player's perspective — once you have a character, it is yours.

### Unlocking Feels Like a Reward Beat

The moment a character entitlement is granted — whether from a purchase or a progression milestone — is a designed celebration. The system delivers the grant reliably and immediately, so the UI system can fire the unlock animation, the roster snaps the character into the available slot, and the player can immediately navigate to the new character and try it. The backend's job is to make the unlock feel instantaneous and permanent, not to introduce loading states or ambiguity.

### Skins and Cosmetics Are Expressions, Not Advantages

Players who buy or earn cosmetic items — skins, emotes, avatar frames — are expressing their identity, not buying power. The entitlement system tracks skin ownership identically to character ownership (a boolean record) but the Character System and Combat System are explicitly prohibited from reading skin entitlements. A player with every legendary skin and a player with default visuals have identical win conditions. The entitlement system enforces this by design: cosmetic entitlements are isolated in their own record type and are never consulted by gameplay-authoritative systems.

### Battle Pass Status Is Visible and Persistent

If a player holds an active Play Pass (equivalent to a seasonal battle pass subscription), that status is visible throughout the session: in the main menu header, on the battle pass track, and on any screen where premium pass rewards are available. The entitlement system exposes `has_play_pass` as a simple boolean derived from the `player_profiles` table, so no screen needs to query entitlement records directly for this common case.

---

## 3. Detailed Rules

### 3.1 Core Concepts: Entitlement vs. Inventory

These two concepts are stored in separate tables and must not be conflated.

| Property | Entitlement | Inventory Item |
|---|---|---|
| Semantics | Boolean: own / don't own | Integer quantity: how many of this item |
| Examples | Character ownership, skin ownership, ability slot unlock, `has_no_ads`, `has_play_pass` | Event tickets, chests, promotional claim tokens |
| Stackability | Non-stackable — granting a second copy is a no-op (idempotent) | Stackable — granting a second copy increments quantity |
| Expiry | Permanent unless revoked | May carry an optional `expires_at` timestamp |
| Quantity tracking | None — the row's existence represents ownership | `quantity` column; row is deleted (or set to 0) when depleted |

### 3.2 Entitlement Types

| Entitlement Type | `item_type` value | Description | Source Systems |
|---|---|---|---|
| Character ownership | `character` | Grants the right to select and play as this character | IAP, currency spend, progression milestone, admin grant |
| Skin ownership | `skin` | Grants the right to equip this cosmetic skin on a character | IAP, currency spend, admin grant |
| Ability slot unlock | `ability_slot` | Unlocks a numbered ability slot for a specific character (future use — see note) | Progression milestone, admin grant |
| `has_no_ads` | `entitlement_flag` | Suppresses AdMob ads globally for this player | IAP, admin grant |
| `has_play_pass` | `entitlement_flag` | Marks the player as an active Play Pass subscriber | RevenueCat subscription state sync |

> **Note on ability slots:** All MVP characters ship with `ability_slot_count = 2` (fixed). The `ability_slot` entitlement type is reserved for a post-MVP feature where additional slots may be unlocked through deep progression. No ability slot entitlements are granted during MVP. The schema supports them to avoid a future migration.

> **`has_no_ads` and `has_play_pass` dual-location:** These flags also live on `player_profiles` (26-field schema) as denormalized booleans for fast access by the ad suppression and UI systems. The Inventory / Entitlements system is the **write authority** for these flags. When it grants or revokes an `entitlement_flag`, it must update both the `entitlements` table and the corresponding field on `player_profiles` within the same PostgreSQL transaction.

### 3.3 Inventory Item Types

During MVP, no consumable inventory items (chests, tickets) are designed. The `inventory_items` table is created and the schema is production-ready, but no grant sources populate it. This ensures a future feature (event tickets, loot chests) can be added without a schema migration.

| Item Type (future) | `item_type` value | Notes |
|---|---|---|
| Event ticket | `event_ticket` | Grants entry to a limited-time mode |
| Chest | `chest` | Opened for a random reward drop |
| Promo token | `promo_token` | Single-use claim token from a promotional code |

### 3.4 Grant Sources

Every grant, regardless of source, enters the same server-side grant pipeline (see Section 3.7). The source is recorded in the `grant_source` field for auditing.

| Source | `grant_source` value | Description | Idempotency Key |
|---|---|---|---|
| IAP fulfillment (RevenueCat) | `iap` | RevenueCat webhook fires on successful purchase; server validates the transaction and grants the item(s) in the associated `grant_payload` from the Content Catalog | RevenueCat `transaction_id` |
| Coin spend | `currency_spend` | Player spends Coins to unlock an earnable character; Currency System deducts Coins atomically, then calls the grant pipeline | Client-generated `idempotency_key` (UUID v4) |
| Diamond spend | `currency_spend` | Player spends Diamonds to unlock a premium character or skin; same flow as Coin spend | Client-generated `idempotency_key` (UUID v4) |
| Progression milestone | `progression_milestone` | XP & Progression System triggers a grant when a player crosses a defined milestone (e.g., XP 5,000 for Fen) | `{user_id}:{milestone_id}` composite key |
| Admin grant | `admin_grant` | Internal tool action by a support agent; used for compensation, testing, or error correction | Admin tool generates a UUID `idempotency_key` |
| Promotional code | `promo_code` | Player redeems a code in the client; server validates the code, marks it claimed (or decrements uses), then calls the grant pipeline | `{user_id}:{promo_code_id}` composite key |

### 3.5 Revocation Rules

Entitlements are designed to be permanent. Revocation is exceptional and must be explicitly authorized. The following conditions are the only valid triggers for revocation:

| Trigger | Scope | Who May Authorize | Behavior |
|---|---|---|---|
| Platform refund (App Store / Google Play) | Single entitlement tied to a specific IAP transaction | RevenueCat webhook (`CANCELLATION` or `REFUND` event) | Entitlement row is soft-deleted (`revoked_at` set, `is_revoked = true`). Character becomes unselectable immediately. If player is in an active match at time of revocation, the match completes; the character is locked from the next session (see Edge Case 5.3). |
| Confirmed fraud / chargeback | All entitlements for the user, or specific flagged items | Admin action only (two-factor confirmation required) | Same soft-delete mechanism as platform refund; additionally, `player_profiles.is_deleted` may be set if full account action is taken. |
| Admin correction | Specific entitlement(s) | Admin action (support tooling) | Soft-delete with admin note recorded in `revocation_notes`. |
| Promotional code expiry | Inventory items only | Automatic (scheduled job checks `expires_at`) | Inventory item row deleted if `expires_at < NOW()` and `quantity > 0`. Permanent entitlements are never expired automatically. |

**Revocation is never automatic for character or skin ownership.** Only the four triggers above may revoke an entitlement. A player cannot lose a character they legitimately earned through progression or Coin spend; only items acquired through a reversible payment transaction are subject to payment-driven revocation.

**Free characters (Vex, Zook, Sera) cannot be revoked under any circumstances.** They are pre-populated at account creation and are not associated with any purchase transaction.

### 3.6 Server-Authoritative Ownership Check

The Character System re-validates ownership at match start. The ownership check flow is:

```
Match Server receives match-start payload (user_id, character_id)
    │
    ▼
Check Redis ownership cache: key = entitlements:{user_id}:characters
    │
    ├── HIT → set of owned character_ids → verify character_id is in set
    │              │
    │              ├── OWNED → proceed with match initialization
    │              └── NOT OWNED → reject with OWNERSHIP_DENIED; do not start match; log incident
    │
    └── MISS → Query PostgreSQL:
                  SELECT item_id FROM entitlements
                  WHERE user_id = $1
                    AND item_type = 'character'
                    AND is_revoked = false
                │
                ├── Write result set to Redis (TTL = OWNERSHIP_CACHE_TTL_SECONDS)
                └── Verify character_id is in result → proceed or reject as above
```

**The server does not trust any client assertion of ownership.** A client sending `character_id = "character:nyx"` is making a request, not asserting a fact. The server's answer is always derived from the entitlements table.

### 3.7 The Grant Pipeline

All grants enter through a single server-side function. Calling it is the only way to create an entitlement or increment an inventory item quantity. No system may write to `entitlements` or `inventory_items` directly.

```
grantItem(userId, itemId, grantSource, idempotencyKey, quantity?) → GrantResult
```

**Pipeline steps (in order):**

1. **Idempotency check** — Query `grant_log` for an existing row with `(user_id, idempotency_key)`. If found, return the original `GrantResult` immediately without repeating any action. This is a fast key-value lookup; the `grant_log` table has a unique index on `(user_id, idempotency_key)`.

2. **Item resolution** — Fetch the item definition from the Content Catalog by `itemId`. If the item does not exist in the catalog or has `status = 'deprecated'`, reject with `ITEM_NOT_FOUND`. If the item has `status = 'inactive'`, reject with `ITEM_UNAVAILABLE` (item exists but is not currently grantable — e.g., a seasonal item outside its availability window).

3. **Ownership pre-check (entitlements only)** — For items with `is_stackable = false`, query the `entitlements` table for an existing non-revoked row with `(user_id, item_id)`. If one exists, this is a duplicate grant. Record the attempt in `grant_log` with `outcome = 'duplicate_noop'` and return `GrantResult { success: true, duplicate: true }`. Do not create a second row.

4. **Open transaction** — Begin a PostgreSQL transaction.

5. **Write entitlement or increment inventory** —
   - For entitlements: `INSERT INTO entitlements (user_id, item_id, item_type, grant_source, idempotency_key, granted_at) VALUES (...)`
   - For inventory items: `INSERT INTO inventory_items ... ON CONFLICT (user_id, item_id) DO UPDATE SET quantity = inventory_items.quantity + EXCLUDED.quantity`

6. **Sync `player_profiles` flags** (if `item_type = 'entitlement_flag'`) — Within the same transaction, update the corresponding boolean field on `player_profiles` (e.g., `has_no_ads = true`).

7. **Write to `grant_log`** — Insert a row recording: `user_id`, `item_id`, `item_type`, `grant_source`, `idempotency_key`, `quantity_granted`, `outcome = 'success'`, `granted_at`.

8. **Commit transaction** — If any step fails, roll back and return a structured error. Do not partially apply the grant.

9. **Invalidate Redis** — Delete `entitlements:{user_id}:characters` (and any other relevant ownership cache keys) after commit.

10. **Emit analytics event** — Asynchronously fire `ECONOMY_ITEM_GRANTED` event (see Section 3.10).

11. **Push Socket.io event** — Emit `inventory:updated` to the player's authenticated socket so the client can refresh its local ownership state without polling.

### 3.8 PostgreSQL Schema

#### `entitlements` Table

```sql
CREATE TABLE entitlements (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid          NOT NULL REFERENCES player_profiles(user_id) ON DELETE CASCADE,
  item_id         varchar(128)  NOT NULL,   -- Catalog canonical ID (e.g., "character:nyx")
  item_type       varchar(32)   NOT NULL,   -- 'character' | 'skin' | 'ability_slot' | 'entitlement_flag'
  grant_source    varchar(32)   NOT NULL,   -- 'iap' | 'currency_spend' | 'progression_milestone' | 'admin_grant' | 'promo_code'
  idempotency_key varchar(256)  NOT NULL,
  granted_at      timestamptz   NOT NULL DEFAULT NOW(),
  is_revoked      boolean       NOT NULL DEFAULT false,
  revoked_at      timestamptz,
  revoked_by      varchar(64),              -- 'platform_refund' | 'admin:{admin_user_id}' | 'fraud_detection'
  revocation_notes text,

  CONSTRAINT entitlements_user_item_unique UNIQUE (user_id, item_id),  -- Prevents duplicate entitlements
  CONSTRAINT entitlements_revocation_consistency CHECK (
    (is_revoked = false AND revoked_at IS NULL) OR
    (is_revoked = true  AND revoked_at IS NOT NULL)
  )
);

CREATE INDEX idx_entitlements_user_id        ON entitlements (user_id);
CREATE INDEX idx_entitlements_user_item_type ON entitlements (user_id, item_type) WHERE is_revoked = false;
CREATE UNIQUE INDEX idx_entitlements_idempotency ON entitlements (user_id, idempotency_key);
```

> **Note on the unique constraint:** `UNIQUE (user_id, item_id)` enforces the idempotency guarantee at the database level. A race condition where two concurrent grants for the same `(user_id, item_id)` reach the DB simultaneously will result in one succeeding and one receiving a unique constraint violation, which the application layer catches and treats as a duplicate grant (step 3 of the pipeline).

#### `inventory_items` Table

```sql
CREATE TABLE inventory_items (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid          NOT NULL REFERENCES player_profiles(user_id) ON DELETE CASCADE,
  item_id         varchar(128)  NOT NULL,   -- Catalog canonical ID
  item_type       varchar(32)   NOT NULL,   -- 'event_ticket' | 'chest' | 'promo_token'
  quantity        integer       NOT NULL DEFAULT 1,
  grant_source    varchar(32)   NOT NULL,
  first_granted_at timestamptz  NOT NULL DEFAULT NOW(),
  last_modified_at timestamptz  NOT NULL DEFAULT NOW(),
  expires_at      timestamptz,              -- NULL = never expires

  CONSTRAINT inventory_items_user_item_unique UNIQUE (user_id, item_id),
  CONSTRAINT inventory_items_quantity_nonneg  CHECK (quantity >= 0)
);

CREATE INDEX idx_inventory_items_user_id ON inventory_items (user_id);
CREATE INDEX idx_inventory_items_expires ON inventory_items (expires_at) WHERE expires_at IS NOT NULL;
```

#### `grant_log` Table

```sql
CREATE TABLE grant_log (
  id               uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid          NOT NULL,
  item_id          varchar(128)  NOT NULL,
  item_type        varchar(32)   NOT NULL,
  grant_source     varchar(32)   NOT NULL,
  idempotency_key  varchar(256)  NOT NULL,
  quantity_granted integer       NOT NULL DEFAULT 1,
  outcome          varchar(32)   NOT NULL,  -- 'success' | 'duplicate_noop' | 'item_not_found' | 'item_unavailable' | 'error'
  error_detail     text,
  granted_at       timestamptz   NOT NULL DEFAULT NOW(),

  CONSTRAINT grant_log_user_idem_unique UNIQUE (user_id, idempotency_key)
);

CREATE INDEX idx_grant_log_user_id    ON grant_log (user_id);
CREATE INDEX idx_grant_log_granted_at ON grant_log (granted_at);
```

### 3.9 Redis Caching Strategy

#### Ownership Cache Keys

| Key Pattern | Value | TTL | Populated When | Invalidated When |
|---|---|---|---|---|
| `entitlements:{user_id}:characters` | JSON array of owned `item_id` strings for characters | `OWNERSHIP_CACHE_TTL_SECONDS` (default: 300s) | First ownership check after a cache miss | Any grant or revocation that affects character entitlements for this user |
| `entitlements:{user_id}:skins` | JSON array of owned skin `item_id` strings | 300s | First ownership check | Grant or revocation of a skin entitlement |
| `entitlements:{user_id}:flags` | JSON object: `{ has_no_ads: bool, has_play_pass: bool }` | 300s | First flag check | Any flag entitlement change |

#### Caching Rules

1. **Cache-aside pattern.** The server does not write to the cache proactively. Caches are populated on the first cache-miss read and evicted on any write that could change the cached set.
2. **Hot-path priority: character ownership.** The `entitlements:{user_id}:characters` key is the most frequently accessed. It is consulted at character select (client-side display) and at match start (server-side enforcement). The TTL must be short enough that a revocation takes effect within one session (300 seconds is the maximum staleness window).
3. **Active match exception.** Once a match starts, ownership is frozen for the duration of that match. The Match Server records the validated character_id at match initialization and does not re-check Redis during the match. This prevents a mid-match revocation from crashing a live game session. See Edge Case 5.3.
4. **Serialization format:** JSON arrays/objects (not MessagePack) for ownership caches — the sets are small and JSON readability aids debugging. Profile cache (in Player Profile system) uses MessagePack.
5. **Cache warm on login.** When a player successfully authenticates, the API server pre-warms `entitlements:{user_id}:characters` to reduce latency on the first character select screen load.

### 3.10 Analytics Events

| Event Name | Trigger | Key Properties |
|---|---|---|
| `ECONOMY_ITEM_GRANTED` | Entitlement or inventory item successfully granted | `userId`, `itemId`, `itemType`, `grantSource`, `idempotencyKey`, `isDuplicate` |
| `ECONOMY_ITEM_REVOKED` | Entitlement revoked | `userId`, `itemId`, `itemType`, `revokedBy`, `revocationReason` |
| `ECONOMY_CHARACTER_UNLOCKED` | Character entitlement specifically granted | `userId`, `characterId`, `unlockType` (`'earnable'`/`'premium'`), `grantSource`, `coinCostPaid`, `diamondCostPaid` |

All events conform to the base event schema defined in `analytics-telemetry.md` (Section 3.2), including `eventId` for deduplication.

### 3.11 TypeScript Interfaces

```typescript
/** Represents a non-stackable, permanent ownership record. */
interface Entitlement {
  id: string;              // UUID primary key
  userId: string;          // Supabase user_id
  itemId: string;          // Catalog canonical ID (e.g., "character:nyx")
  itemType: EntitlementType;
  grantSource: GrantSource;
  idempotencyKey: string;
  grantedAt: string;       // ISO 8601
  isRevoked: boolean;
  revokedAt: string | null;
  revokedBy: string | null;
  revocationNotes: string | null;
}

type EntitlementType = 'character' | 'skin' | 'ability_slot' | 'entitlement_flag';

type GrantSource = 'iap' | 'currency_spend' | 'progression_milestone' | 'admin_grant' | 'promo_code';

/** Represents a quantity-tracked, stackable owned item. */
interface InventoryItem {
  id: string;
  userId: string;
  itemId: string;          // Catalog canonical ID
  itemType: InventoryItemType;
  quantity: number;        // Always >= 0
  grantSource: GrantSource;
  firstGrantedAt: string;
  lastModifiedAt: string;
  expiresAt: string | null;
}

type InventoryItemType = 'event_ticket' | 'chest' | 'promo_token';

/** Return value from the grant pipeline. */
interface GrantResult {
  success: boolean;
  duplicate: boolean;      // true if idempotency key was already processed
  entitlement?: Entitlement;
  inventoryItem?: InventoryItem;
  errorCode?: string;      // 'ITEM_NOT_FOUND' | 'ITEM_UNAVAILABLE' | 'INTERNAL_ERROR'
}

/** Ownership summary returned to character select and match server. */
interface PlayerOwnershipSummary {
  userId: string;
  ownedCharacterIds: string[];    // All non-revoked character item_ids
  ownedSkinIds: string[];
  flags: {
    hasNoAds: boolean;
    hasPlayPass: boolean;
  };
}
```

---

## 4. Formulas

### 4.1 Earnable Character Unlock Costs (Coin Purchase)

Earnable characters can be purchased with Coins (soft currency) as an alternative to reaching their progression milestone. The Coin cost is designed to feel reachable for a consistent player — roughly equivalent to 2–3 days of normal play earnings — but not trivially cheap.

| Character | ID | Unlock Type | Progression Milestone | Coin Purchase Cost |
|---|---|---|---|---|
| Fen | `character:fen` | Earnable | XP 2,000 | 800 Coins |
| Grim | `character:grim` | Earnable | Wins 15 | 600 Coins |
| Dash | `character:dash` | Earnable | XP 5,000 | 1,200 Coins |

> **Note:** Canonical character IDs, display names, categories, and prices are defined in `content-catalog.md §Character Records`. The earnable set (Fen, Grim, Dash) and every ID in this section reference that catalog as the single source of truth.

**Coin cost formula:**

```
coin_cost = BASE_EARNABLE_COIN_COST × rarity_multiplier
```

| Variable | Value | Notes |
|---|---|---|
| `BASE_EARNABLE_COIN_COST` | 600 Coins | Baseline for the cheapest earnable character (Grim, quickest to milestone) |
| `rarity_multiplier` | 1.0 (Grim), 1.33 (Fen), 2.0 (Dash) | Reflects relative depth of the progression milestone |

**Example:** Dash has a milestone of XP 5,000 — the deepest earnable threshold. `600 × 2.0 = 1,200 Coins`.

### 4.2 Premium Character Unlock Costs (Diamond Purchase)

Premium characters are purchased exclusively with Diamonds (hard currency). Diamonds are obtained through IAP or earned in limited quantities from high-tier progression rewards.

| Character | ID | Diamond Cost | Approximate USD Equivalent |
|---|---|---|---|
| Colt | `character:colt` | 500 Diamonds | ~$4.99 (based on standard Diamond pack pricing) |
| Nyx | `character:nyx` | 500 Diamonds | ~$4.99 |

Both premium characters are priced identically at launch. Post-launch, limited-time discounts may be applied via the Content Catalog overlay mechanism (reducing the `shop_offer` display cost) without requiring a schema change to entitlements.

**Diamond cost formula:**

```
diamond_cost = PREMIUM_CHARACTER_BASE_DIAMOND_COST × prestige_multiplier
```

| Variable | Value | Notes |
|---|---|---|
| `PREMIUM_CHARACTER_BASE_DIAMOND_COST` | 500 Diamonds | Launch price for all MVP premium characters |
| `prestige_multiplier` | 1.0 (all MVP characters) | Future hook: limited-edition or collab characters may use > 1.0 |

**Example:** Nyx costs `500 × 1.0 = 500 Diamonds`. At the standard Diamond pack of 100 Diamonds for $0.99, 500 Diamonds ≈ $4.95 effective purchase cost.

### 4.3 Skin Tier Pricing

Skins are purely cosmetic. Pricing reflects art production quality. All skin purchases create a `skin` entitlement.

| Tier | Description | Diamond Cost | USD Equivalent | Example |
|---|---|---|---|---|
| Common | Recolor; no new geometry or VFX | 100 Diamonds | ~$0.99 | Vex "Shadow" (dark palette swap) |
| Rare | New outfit layer; minor VFX change | 250 Diamonds | ~$2.49 | Grim "Arctic" (ice texture + frost hit VFX) |
| Epic | New model silhouette variation + VFX set | 500 Diamonds | ~$4.99 | Nyx "Void Form" (alternate silhouette, purple particle trails) |
| Legendary | Full re-model, new animation set, unique audio | 1,000 Diamonds | ~$9.99 | Colt "Gilded" (gold model, unique reload SFX, victory animation) |
| Bundle (USD) | Skin + character (if not owned) in a single IAP | Fixed USD price (e.g., $6.99) | Direct IAP via RevenueCat | "Nyx Void Bundle": Nyx (if unowned) + Nyx Void Form skin |

**Skin cost formula:**

```
skin_diamond_cost = SKIN_TIER_BASE_COST[tier]
```

Where `SKIN_TIER_BASE_COST` is a server-side config map:

```
SKIN_TIER_BASE_COST = {
  common:    100,
  rare:      250,
  epic:      500,
  legendary: 1000
}
```

**Example:** A player buys "Arctic" (Rare) for Grim. The server receives a Diamond spend request for 250 Diamonds. The Currency System deducts 250 Diamonds from `diamond_balance` and calls `grantItem(userId, 'skin:grim_arctic', 'currency_spend', idempotencyKey)`. The `entitlements` table gains one row; the player's character select screen immediately reflects the new skin option.

### 4.4 Bundle IAP Grant Payload

Bundles are defined in the Content Catalog as `shop_offer` records with a `grant_payload` array. Each element in the array is an independent grant call. The grant pipeline processes them sequentially within a single transaction; if any element fails, the entire bundle is rolled back.

```
grant_payload = [
  { itemId: "character:nyx",    idempotencyKeySuffix: "char" },
  { itemId: "skin:nyx_void_form",    idempotencyKeySuffix: "skin" }
]
```

The idempotency key for each element is `{transaction_id}:{idempotencyKeySuffix}`, ensuring each item in the bundle is independently deduplicated.

---

## 5. Edge Cases

### 5.1 IAP Grant Fires Twice (Receipt Validated Twice)

**Scenario:** RevenueCat fires a webhook for the same purchase transaction twice (e.g., due to network retry on webhook delivery failure). Both webhook invocations reach the server with the same RevenueCat `transaction_id`.

**Resolution:** The `transaction_id` is used as the `idempotency_key` for the grant. The grant pipeline's step 1 checks `grant_log` for `(user_id, idempotency_key)`. The first invocation succeeds and writes the entitlement. The second invocation finds the existing `grant_log` row and returns `GrantResult { success: true, duplicate: true }` immediately, without creating a second entitlement row or charging any currency. The `UNIQUE (user_id, item_id)` constraint on the `entitlements` table also provides a hard database-level safety net: even if the idempotency check has a race condition, the constraint ensures only one row can exist.

### 5.2 Currency Deducted But Grant Record Fails to Write

**Scenario:** A player spends 1,200 Coins to unlock Dash. The Currency System successfully deducts 1,200 Coins and commits the `coin_transactions` ledger entry. Then the `entitlements` INSERT fails (e.g., a transient DB error).

**Resolution:** The Coin deduction and the entitlement grant must be executed in the **same PostgreSQL transaction**. This is a hard requirement: the Currency System's deduction call and the `grantItem` call share a transaction context. If `grantItem` throws, the Coin deduction is rolled back. The player retains their Coins and the character is not granted. The client receives a 500 error and is instructed to retry (the client-generated `idempotency_key` ensures the retry is safe). This design means the Currency System must call the grant pipeline within an open transaction, passing the transaction context, rather than calling it as a separate sequential operation.

**Implementation note:** The grant pipeline's `grantItem` function accepts an optional `txContext` parameter. When called with a transaction context, it participates in that transaction rather than opening its own. This is the required pattern for currency-backed unlocks.

### 5.3 Player Uses Character in Match, Then Refund Is Processed

**Scenario:** A player purchases Nyx, enters a match as Nyx, and then a refund is processed (by the platform or by admin action) while the match is still in progress.

**Resolution:** The revocation is applied to the `entitlements` table immediately and the Redis cache is invalidated. However, the Match Server records the validated character_id at match initialization and does not re-check ownership during the match. The current match completes with Nyx as the player's character — this is acceptable because interrupting an active match mid-play would degrade experience for all participants, not just the refunding player.

After the match ends, the player's ownership cache reflects the revoked state. On the next character select screen load, Nyx is no longer available. If the player attempts to queue with Nyx (e.g., through a stale client state), the match start ownership check rejects the request with `OWNERSHIP_DENIED`.

The match result (win/loss, stats, XP, Coins reward) is processed normally — the system does not claw back rewards earned in a match that was started with a valid, server-verified character selection.

### 5.4 Content Catalog Item Removed Post-Grant (Legacy Entitlement Handling)

**Scenario:** A skin (`skin:vex_promo_2026`) was available during a limited-time event. Players who purchased it hold a `skin` entitlement. The Content Catalog item is later set to `status = 'deprecated'`.

**Resolution:** The `entitlements` table row is the ownership record. It is not deleted when a catalog item is deprecated. The skin remains in the player's possession and can be equipped. The Content Catalog lookup for display metadata (name, description, preview image) returns the bundled baseline record (which persists even when `status = 'deprecated'`), so the client can render the skin correctly.

The grant pipeline's step 2 rejects new grants for deprecated items (`ITEM_NOT_FOUND`). Existing owners are unaffected.

If the art or asset for a deprecated item is removed from the client build, the client falls back to a `default_skin_asset` placeholder. The entitlement is preserved; the rendering degrades gracefully.

### 5.5 Ownership Check During Active Match (Cached vs. Live)

**Scenario:** A player's Redis ownership cache (`entitlements:{user_id}:characters`) expires mid-match (TTL lapses during a long game).

**Resolution:** The Match Server does not consult Redis during an active match. Ownership is validated exactly once, at match start (step 6 of the Match Server's initialization sequence). The result is stored in the in-memory match state object for that session's lifetime. Mid-match, the Match Server reads from the in-memory state, not Redis. Cache expiry during a match has zero effect on the running game.

If the Match Server restarts (crash recovery), the reconnect-resume system re-validates ownership from PostgreSQL directly (bypassing Redis) as part of the session reconstruction flow, since the in-memory state is lost.

### 5.6 Concurrent Grant Requests for the Same Item

**Scenario:** A player double-taps the "Unlock" button and two identical `grantItem` requests reach the server concurrently, with the same `idempotency_key`.

**Resolution:** Both requests attempt to `INSERT` into `grant_log` with the same `(user_id, idempotency_key)`. The `UNIQUE` constraint on `grant_log(user_id, idempotency_key)` ensures only one INSERT succeeds. The losing request receives a unique constraint violation, which the application layer interprets as a duplicate in-flight request and returns `GrantResult { success: true, duplicate: true }` after reading the original outcome from `grant_log`. The `UNIQUE (user_id, item_id)` constraint on `entitlements` provides a second safety layer.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (Systems This System Reads From)

| System | Dependency | What We Need |
|---|---|---|
| **Content Catalog** (`content-catalog.md`) | Hard upstream | Item definitions, `status`, `grant_payload`, `item_type`. All item existence checks go through the catalog. If the catalog is unreachable, the grant pipeline rejects all grants with `ITEM_NOT_FOUND` rather than bypassing the check. |
| **Authentication** (`authentication.md`) | Hard upstream | Supabase JWT validation on every API endpoint. The grant pipeline rejects requests without a valid JWT. |
| **Player Profile** (`player-profile.md`) | Hard upstream (write) | `player_profiles` table — referenced by FK in `entitlements`. Also the write target for `has_no_ads` and `has_play_pass` denormalized flags. |
| **Currency System** (`currency-system.md`) | Peer (transactional) | Coin and Diamond deductions must share a DB transaction with the grant pipeline for currency-backed unlocks. The Currency System calls `grantItem(txContext)`. |
| **RevenueCat** (IAP) | Hard upstream | Webhook events (`INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `REFUND`) drive IAP-backed grants and revocations. |

### 6.2 Downstream Dependencies (Systems That Read From This System)

| System | Dependency | What They Need |
|---|---|---|
| **Character System** (`character-system.md`) | Hard downstream | Calls `getOwnedCharacterIds(userId)` at match start for server-authoritative ownership validation. |
| **Character/Deck Select** (`character-deck-select.md`) | Hard downstream | Reads `PlayerOwnershipSummary` to render the available character roster and lock unavailable characters. |
| **Main Menu** (`main-menu.md`) | Soft downstream | Reads `has_play_pass` and `has_no_ads` flags to configure UI (battle pass track visibility, ad suppression). |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | Observational | Receives `ECONOMY_ITEM_GRANTED`, `ECONOMY_ITEM_REVOKED`, `ECONOMY_CHARACTER_UNLOCKED` events. |
| **Logging / Monitoring** (`logging-monitoring.md`) | Observational | All grant, revocation, and cache operations must log through `ILogger`. PII policy applies: `user_id` is pseudonymous (UUID); item names are not PII. |
| **Ad System** (AdMob) | Soft downstream | Reads `has_no_ads` from the profile (denormalized from entitlements) to decide whether to show ads. |
| **Shop / Store UI** (future) | Soft downstream | Reads ownership state to mark already-owned items in the shop display. |

---

## 7. Tuning Knobs

All configurable constants are defined in server-side Remote Config (same delivery mechanism as balance overlays). Safe ranges reflect values that preserve the system's integrity contracts.

| Constant | Default | Safe Range | Unit | Effect |
|---|---|---|---|---|
| `OWNERSHIP_CACHE_TTL_SECONDS` | 300 | 60 – 600 | Seconds | Controls staleness of the Redis ownership cache. Lower values mean revocations take effect sooner; higher values reduce DB load under heavy character-select traffic. Below 60s causes excessive DB fan-out; above 600s means a revocation may be invisible for up to 10 minutes. |
| `GRANT_LOG_RETENTION_DAYS` | 365 | 90 – 730 | Days | How long `grant_log` rows are retained before archival or deletion. Affects storage cost and audit trail depth. Below 90 days may violate platform store dispute windows (Apple/Google allow 90-day refund windows). |
| `INVENTORY_EXPIRY_CHECK_INTERVAL_MINUTES` | 60 | 15 – 1440 | Minutes | How often the scheduled job scans `inventory_items` for expired rows. MVP has no expirable items, so this only affects future feature latency. |
| `CACHE_WARM_ON_LOGIN` | `true` | `true` / `false` | Boolean | Whether character ownership cache is pre-warmed at login. Disable only under severe Redis memory pressure; disabling increases character select screen latency for the first load. |
| `BASE_EARNABLE_COIN_COST` | 600 | 300 – 2000 | Coins | Baseline Coin cost for the cheapest earnable character. Affects soft-currency economy balance. Changes here must be coordinated with the Currency System tuning knobs to remain within weekly earn rate expectations. |
| `PREMIUM_CHARACTER_BASE_DIAMOND_COST` | 500 | 200 – 1000 | Diamonds | Base Diamond cost for premium characters. Directly affects IAP revenue and perceived value. Changes below 200 undercut bundle pricing; above 1000 significantly reduces conversion. |
| `SKIN_TIER_BASE_COST[common]` | 100 | 50 – 200 | Diamonds | Common skin price floor. |
| `SKIN_TIER_BASE_COST[rare]` | 250 | 150 – 400 | Diamonds | Rare skin price. |
| `SKIN_TIER_BASE_COST[epic]` | 500 | 300 – 750 | Diamonds | Epic skin price. |
| `SKIN_TIER_BASE_COST[legendary]` | 1000 | 700 – 1500 | Diamonds | Legendary skin price ceiling is set by perceived value relative to premium character cost (should not exceed 3× `PREMIUM_CHARACTER_BASE_DIAMOND_COST`). |
| `MAX_IDEMPOTENCY_KEY_AGE_DAYS` | 30 | 7 – 90 | Days | How old an `idempotency_key` may be before it is no longer treated as a valid duplicate guard (old keys are purged from `grant_log`). Must be ≥ platform refund window. |
| `DUPLICATE_GRANT_LOG_LEVEL` | `warn` | `debug` / `warn` / `info` | Log level | Log level for duplicate grant attempts. `warn` catches unexpected duplicates without flooding logs during expected retry scenarios. |

---

## 8. Acceptance Criteria

**AC-01** — Given a new player account is created, when the profile creation flow completes, then `entitlements` rows for `character:vex`, `character:zook`, and `character:sera` exist in the database for that `user_id`, all with `grant_source = 'progression_milestone'` and `is_revoked = false`.

**AC-02** — Given a player does not own `character:nyx`, when the Match Server's ownership check runs for that player selecting `character:nyx`, then the server returns `OWNERSHIP_DENIED`, the match does not start, and the incident is logged with `user_id` and `character_id`.

**AC-03** — Given a player purchases Nyx via IAP, when RevenueCat fires the `INITIAL_PURCHASE` webhook, then within 5 seconds: (a) an entitlement row exists in `entitlements` for `(user_id, 'character:nyx')`, (b) the Redis cache `entitlements:{user_id}:characters` is invalidated, and (c) the client receives an `inventory:updated` Socket.io event.

**AC-04** — Given RevenueCat fires the same purchase webhook twice with the same `transaction_id`, when both webhook calls are processed, then exactly one entitlement row exists in `entitlements` for the purchased item, the `grant_log` contains one row with `outcome = 'success'` and no row with `outcome = 'error'`, and no error is returned to RevenueCat (both calls return HTTP 200).

**AC-05** — Given a player has 1,200 Coins and attempts to unlock Dash for 1,200 Coins, when the request is processed, then: (a) `coin_balance` decreases by exactly 1,200 within the same DB transaction as the entitlement insert, (b) an entitlement row exists for `character:dash`, and (c) if the entitlement insert fails, the Coin deduction is rolled back and the player retains 1,200 Coins.

**AC-06** — Given a player owns a character and a refund is processed (revocation call), when the revocation completes, then: (a) `is_revoked = true` and `revoked_at` are set on the entitlement row, (b) the Redis ownership cache for that user is invalidated immediately, (c) if the player is in an active match, that match completes normally, and (d) the player cannot select the revoked character in the next character select screen.

**AC-07** — Given the `entitlements:{user_id}:characters` cache key does not exist (cold cache), when the character select screen loads, then the system queries PostgreSQL, populates the Redis cache, and returns the correct owned character list within 500ms (P95 target under normal load).

**AC-08** — Given a catalog item has `status = 'deprecated'`, when `grantItem` is called for that item ID, then `grantItem` returns `GrantResult { success: false, errorCode: 'ITEM_NOT_FOUND' }` and no row is written to `entitlements` or `grant_log`.

**AC-09** — Given a player already owns a skin and a duplicate `grantItem` call is made for the same skin with the same `idempotency_key`, then: (a) no second entitlement row is inserted, (b) `grant_log` contains one row for the key, (c) `grantItem` returns `GrantResult { success: true, duplicate: true }`.

**AC-10** — Given a player's ownership cache expires during an active match, when the Match Server references ownership mid-match, then the match continues using the in-memory ownership state recorded at match initialization without querying Redis or PostgreSQL.

**AC-11** — Given a bundle IAP (`grant_payload` with 2 items: character + skin), when the purchase webhook is processed and the skin INSERT fails, then the character entitlement insert is also rolled back, the player is not partially granted the bundle, and the `grant_log` records `outcome = 'error'` for the transaction.

**AC-12** — Given a player has `has_play_pass = false` and an `entitlement_flag` grant for `has_play_pass` is processed, when the grant pipeline commits, then `player_profiles.has_play_pass` is set to `true` within the same DB transaction as the `entitlements` row insert, and the client receives a `profile:refresh` Socket.io event.

**AC-13** — Given the `OWNERSHIP_CACHE_TTL_SECONDS` tuning knob is set to 60, when a player unlocks a character, then within 60 seconds a second player querying the same user's ownership from Redis receives the updated character list (old cache has expired and is re-populated from PostgreSQL).

**AC-14** — Given a player redeems a promotional code that has already been redeemed by the same player, when the redemption is attempted again, then the server returns HTTP 409 with error code `PROMO_ALREADY_CLAIMED`, no entitlement or inventory row is created, and the `grant_log` records `outcome = 'duplicate_noop'`.

**AC-15** — Given a free character (`character:vex`, `character:zook`, or `character:sera`) and an admin revocation action targets that character, then the system rejects the revocation with error `CANNOT_REVOKE_FREE_CHARACTER` and the entitlement row remains with `is_revoked = false`.

**AC-16** — Given a `ECONOMY_ITEM_GRANTED` analytics event is emitted after a successful grant, when the event reaches the analytics pipeline, then it carries all required base fields from `analytics-telemetry.md` Section 3.2, plus `itemId`, `itemType`, `grantSource`, and `isDuplicate`.
