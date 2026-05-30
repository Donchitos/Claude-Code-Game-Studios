# Currency System — Game Design Document

> **System**: Currency System
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

The Currency System is the economy layer of BRAWLZONE, managing two persistent currencies — **Coins** (soft currency, earned through play) and **Diamonds** (hard currency, purchased via IAP or earned sparingly) — and enforcing all balance mutations with server-authoritative atomicity, audit trails, and double-spend prevention. Tickets as a third currency are explicitly **not used** at this time (see §3.1 for rationale). Coins are spent on cosmetics and earnable-character unlocks; Diamonds are spent on premium characters, cosmetic bundles, and the Battle Pass. Both balances live in the Player Profile (PostgreSQL source of truth, Redis cache) and are mutated exclusively by the Currency System through a transactional ledger that makes every grant or spend traceable, reversible by ops, and protected against race conditions at the database level.

---

## 2. Player Fantasy

### "Every Match Pays Off"

The currency system's central promise is that no match feels wasted. Win or lose, a number goes up. A player who grinds five consecutive losses still sees their Coin balance tick upward on the results screen — small, honest, earned. Over a session that number accumulates into something visible: a character unlock, a new emote, one step closer to a cosmetic they picked out a week ago.

**What the free player feels:** The path to every earnable character — Fen, Grim, Dash — is visible from day one. A returning player can eyeball their Coin balance, look at the unlock price, and feel the gap close with every session. The grind is transparent. There is no random gate, no loot box friction standing between their effort and the thing they want.

**What the premium player feels:** Diamonds accelerate things that take time, not things that take skill. Spending Diamonds to unlock Colt or Nyx does not buy a competitive advantage — it buys the option to play those characters now instead of later. That distinction should feel honest. Premium spending is convenience, not power.

**What every player feels after a match:** The results screen shows exactly what they earned: Coins first (always), Diamonds second (on wins and with Play Pass). The numbers are concrete, not opaque. "You earned 45 Coins and 5 Diamonds" is satisfying. "You earned some rewards" is not a valid spec.

---

## 3. Detailed Rules

### 3.1 Currency Types

BRAWLZONE uses exactly two currencies: **Coins** and **Diamonds**.

**Tickets are not implemented.** The design considered Tickets (earned by playing, spent on ranked/special mode entry) but rejected them for the following reasons: (1) they add a friction gate to modes without increasing strategic depth; (2) BRAWLZONE's session loop is designed for rapid re-queuing — a Ticket gate interrupts that loop; (3) ranked access is controlled by MMR brackets, not currency gates. If a special event mode requires a gate in a future season, Tickets can be introduced as a Remote Config–driven feature without redesigning the core economy.

#### Coin (Soft Currency)

| Property | Value |
|---|---|
| Symbol | `coin_balance` (Player Profile field) |
| Earn source | Match completion, daily quests, daily login bonus |
| Spend target | Cosmetics (cheap tier), earnable character unlocks |
| IAP purchasable | No |
| Wallet cap | 50,000 Coins |
| Starting balance | 0 |
| Negative balance | Impossible — `CHECK (coin_balance >= 0)` at DB level |

#### Diamond (Hard Currency)

| Property | Value |
|---|---|
| Symbol | `diamond_balance` (Player Profile field) |
| Earn source | Match wins (small amount), IAP packages, milestone rewards, rare quest completion |
| Spend target | Premium characters (Colt, Nyx), cosmetic bundles, Battle Pass activation |
| IAP purchasable | Yes — via RevenueCat |
| Wallet cap | 100,000 Diamonds |
| Starting balance | 0 |
| Negative balance | Impossible — `CHECK (diamond_balance >= 0)` at DB level |

---

### 3.2 Earning Methods

#### 3.2.1 Match Completion (Coins + Diamonds)

Coins and Diamonds are awarded automatically by the Currency System when it receives the `match_result_for_rewards` fan-out event from Match Flow (Step 5 of the Match End Sequence, per match-flow.md §3.4). MMR update has already committed before this event fires.

**Coins — all players, all outcomes:**

| Condition | Coin Grant |
|---|---|
| Any mode, loss or draw | `COIN_BASE_LOSS` (default 25) |
| Any mode, win | `COIN_BASE_WIN` (default 45) |
| Play Pass active (any outcome) | × `PLAY_PASS_COIN_MULTIPLIER` (default 1.5) |

**Diamonds — wins only:**

| Condition | Diamond Grant |
|---|---|
| Win, no Play Pass | `DIAMOND_BASE_WIN` (default 5) |
| Win, Play Pass active | `floor(DIAMOND_BASE_WIN × PLAY_PASS_DIAMOND_MULTIPLIER)` (default `floor(5 × 1.25)` = 6) |
| Loss or draw | 0 Diamonds |

See the Reward System GDD for complete formulas with examples.

#### 3.2.2 Daily Login Bonus (Coins)

Each calendar day (UTC) on first authenticated login, the Currency System checks the `daily_login_last_claimed_at` field on the Player Profile. If the last claim date is not today (UTC), the daily bonus fires.

| Day streak | Coin grant |
|---|---|
| Day 1 | `DAILY_BONUS_BASE` = 50 |
| Day 2 | 75 |
| Day 3 | 100 |
| Day 4 | 125 |
| Day 5+ (cap) | 150 |

Streak increments only if the player logs in on consecutive calendar days (UTC). Missing a day resets the streak to 1. The streak counter is stored in `daily_login_streak` on the Player Profile (server-only field; added to profile schema per §3.4 below). The grant fires server-side at login, not client-side.

#### 3.2.3 Quest / Mission Rewards (Coins + Diamonds)

The Quest System (future system, out of scope for this GDD) issues currency grants by calling the Currency System's `grantCurrency` API with `source: "quest"`. The Currency System executes the grant identically to any other source — atomically, with ledger entry, with Redis invalidation. Quest reward amounts are defined in the Quest System GDD and are Remote Config cold keys there. This GDD defines only that the Currency System accepts and executes quest grants; it does not own quest reward values.

#### 3.2.4 Rewarded Ads (Coins)

When a free player (without `has_no_ads`) watches a rewarded ad to completion, AdMob fires a server-side callback to the game server. The Currency System grants `AD_REWARD_COINS` (default 15) Coins per viewed rewarded ad. The grant is subject to a per-session cap: a player may claim at most `AD_REWARD_MAX_GRANTS_PER_SESSION` (default 5) rewarded ad grants per 24-hour window. The window resets at UTC midnight. Grants beyond the cap are silently dropped server-side; the client is informed via a `{ status: "cap_reached" }` response so it can suppress the ad offer.

Players with `has_no_ads = true` do not receive rewarded ad prompts. The Currency System rejects rewarded ad grant calls for `has_no_ads` users with error code `NO_ADS_ENTITLEMENT`.

#### 3.2.5 IAP Diamond Packages

When a player completes a Diamond purchase through RevenueCat, the Purchase Fulfillment system (which owns the RevenueCat webhook) calls the Currency System's `grantCurrency` API with `source: "iap"` and the Diamond amount from the package table (§4.2). The Currency System executes the grant atomically. See Edge Case §5.2 for IAP-grant failure handling.

The Currency System does **not** call RevenueCat directly. It is a grant target, not a payment processor.

#### 3.2.6 Admin Grants

Server operators may issue manual currency grants via an admin API endpoint (`POST /admin/currency/grant`). This endpoint requires an admin-scoped JWT (not a player JWT). Admin grants are subject to per-player daily limits enforced by the Currency System (`ADMIN_GRANT_MAX_COINS_PER_DAY` = 5,000 Coins; `ADMIN_GRANT_MAX_DIAMONDS_PER_DAY` = 500 Diamonds) to prevent accidental mass grants. Grants exceeding limits return HTTP 422 and must be split into multiple requests or escalated via a superadmin override. Every admin grant writes a ledger entry with `source: "admin"` and the operator's `admin_user_id`.

---

### 3.3 Spending Methods

All spend operations are server-authoritative. The client sends a spend request; the server validates balance, applies the deduction atomically with the entitlement grant, and confirms. The client never optimistically decrements balance.

#### 3.3.1 Earnable Character Unlocks (Coins)

| Character | Unlock Cost |
|---|---|
| Grim (Tank) | 600 Coins |
| Fen (Trickster) | 800 Coins |
| Dash (Speedster) | 1,200 Coins |

The spend and the Character Unlock System's `appendUnlock` call execute in the same PostgreSQL transaction. If either fails, both roll back. The player never loses Coins without receiving the character, and never receives the character without losing Coins.

#### 3.3.2 Premium Character Unlocks (Diamonds)

| Character | Unlock Cost |
|---|---|
| Colt (Trapper) | 800 Diamonds |
| Nyx (Controller) | 800 Diamonds |

Same atomic transaction guarantee as §3.3.1, but against `diamond_balance`.

#### 3.3.3 Cosmetic Purchases (Coins or Diamonds)

Cosmetic items (skins, emotes, sprays) are defined in the Content Catalog. Each item carries a `currencyType` (`"coins"` or `"diamonds"`) and a `price` field. The Currency System deducts the specified amount and confirms to the Inventory System in the same transaction. Cosmetic pricing is owned by the Content Catalog GDD; the Currency System enforces atomic spend regardless of price.

#### 3.3.4 Battle Pass Activation (Diamonds)

Activating the Battle Pass costs `BATTLE_PASS_PRICE_DIAMONDS` (default 950 Diamonds). The spend and the `isPremium = true` write to the `battle_pass` entitlement record on the Player Profile execute in the same transaction. The Battle Pass system (future GDD) does not own this spend path; it reads `battle_pass.isPremium` as its entitlement signal.

---

### 3.4 Player Profile Schema Additions

The Currency System requires two additional fields on the Player Profile beyond the 26-field schema in player-profile.md. These must be added in the next profile schema revision:

```typescript
interface PlayerProfileCurrencyFields {
  coin_balance: number;               // >= 0; CHECK constraint; mutated by Currency System only
  daily_login_streak: number;         // 1–5 cap; server-only
  daily_login_last_claimed_at: string | null;  // ISO 8601 UTC; server-only
  ad_reward_grants_today: number;     // count of rewarded ad grants claimed today (resets UTC midnight); server-only
  ad_reward_last_reset_at: string;    // ISO 8601 UTC date of last ad_reward_grants_today reset; server-only
}
```

`diamond_balance` already exists in player-profile.md §3.1. `coin_balance` does not yet exist and must be added. The existing `CHECK (diamond_balance >= 0)` DB constraint must be mirrored for `coin_balance`.

---

### 3.5 Wallet Caps

| Currency | Cap | Behavior at cap |
|---|---|---|
| Coins | 50,000 | Grant is truncated to `cap - current_balance`. Excess Coins are silently dropped. Analytics event `CURRENCY_GRANT_CAPPED` is emitted with `dropped_amount`. |
| Diamonds | 100,000 | Same truncation and analytics event. |

The cap is checked inside the grant transaction before committing. A player with 49,990 Coins who earns 45 Coins receives exactly 10 Coins (not 45), bringing them to the cap. No error is returned to the caller — the truncated amount is silently applied. The ledger entry records both `requested_amount` and `actual_amount` for auditability.

---

### 3.6 Transaction Atomicity and Double-Spend Prevention

Every currency mutation (grant or spend) follows this sequence:

```
1. Acquire Redis distributed lock: currency_lock:{playerId}
   TTL = 5000ms
   If lock not acquired within 200ms → return HTTP 429 (retry later)

2. Begin PostgreSQL transaction (SERIALIZABLE isolation)

3. SELECT ... FOR UPDATE on player_profiles row for this playerId
   (row-level lock; concurrent mutations queue, not interleave)

4. Validate:
   - For spend: current_balance >= requested_amount
   - For grant: current_balance + amount <= wallet_cap (clamp if needed)
   - For spend: check idempotency key has not been processed
     (SELECT 1 FROM currency_ledger WHERE idempotency_key = $1)

5. Apply mutation:
   - UPDATE player_profiles SET coin_balance = coin_balance + $delta
     WHERE user_id = $1
   (delta is negative for spends; PostgreSQL CHECK constraint rejects if result < 0)

6. INSERT into currency_ledger (see §3.7)

7. COMMIT

8. On SUCCESS:
   - Release Redis lock
   - DELETE Redis key: profile:{playerId}  (invalidate cache)
   - Emit Socket.io profile:refresh to player's socket
   - Return confirmed new balance to caller

9. On FAILURE (any step):
   - ROLLBACK
   - Release Redis lock
   - Return error code to caller; do not touch Redis
```

The `SELECT ... FOR UPDATE` at step 3 serializes concurrent mutations at the database row level. The Redis lock at step 1 provides a fast-fail layer that prevents concurrent requests from even entering the PostgreSQL transaction, reducing lock contention under burst load.

**Negative balance prevention** is enforced at two layers:
1. **Application layer (step 4):** Explicit balance check before the UPDATE. Returns `INSUFFICIENT_BALANCE` error if `current_balance < requested_amount`.
2. **Database layer (step 5):** `CHECK (coin_balance >= 0)` and `CHECK (diamond_balance >= 0)` constraints will cause the transaction to fail even if the application check is bypassed. This is the last line of defense.

---

### 3.7 Audit Trail — Currency Ledger

Every currency mutation writes one row to `currency_ledger`. This table is append-only; no rows are ever updated or deleted (except as part of GDPR hard-delete, which deletes the entire player's data).

```typescript
interface CurrencyLedgerRow {
  id: string;                     // UUID, primary key
  player_id: string;              // Foreign key → player_profiles.user_id
  currency: "coins" | "diamonds";
  delta: number;                  // Positive = grant; negative = spend
  balance_before: number;         // Balance at start of transaction
  balance_after: number;          // Balance after commit (may differ from balance_before + delta if capped)
  requested_amount: number;       // Amount requested before cap truncation
  actual_amount: number;          // Amount actually applied (equals |delta|)
  source: LedgerSource;           // See LedgerSource below
  source_ref: string | null;      // Contextual reference: matchId, questId, iap_transaction_id, admin_user_id, etc.
  idempotency_key: string;        // Unique per mutation attempt; prevents double-processing
  created_at: string;             // ISO 8601 UTC timestamp (set by PostgreSQL NOW())
}

type LedgerSource =
  | "match_reward"       // Match Flow fan-out
  | "daily_login"        // Daily login bonus
  | "quest_reward"       // Quest System grant
  | "ad_reward"          // Rewarded ad completion
  | "iap"                // IAP Diamond package via Purchase Fulfillment
  | "admin"              // Manual admin grant
  | "spend_character"    // Character unlock spend
  | "spend_cosmetic"     // Cosmetic purchase spend
  | "spend_battle_pass"; // Battle Pass activation spend
```

**Idempotency key format:**

```
match_reward:   "match_reward:{matchId}:{playerId}"
daily_login:    "daily_login:{playerId}:{UTC_date}"       // e.g., "daily_login:abc123:2026-05-28"
quest_reward:   "quest_reward:{questId}:{playerId}"
ad_reward:      "ad_reward:{adImpressionId}:{playerId}"
iap:            "iap:{revenuecat_transaction_id}"
admin:          "admin:{admin_user_id}:{playerId}:{UUID}"
spend:          "spend:{requestId}"                       // requestId from client request body
```

The Currency System checks for an existing ledger row with this `idempotency_key` before processing. If found, it returns the original result (HTTP 200 with the committed balance) without re-executing. This makes every mutation safe to retry.

---

### 3.8 Currency Grant Authority Table

Only the listed callers may trigger currency grants. Any other caller is rejected with HTTP 403.

| Source | Caller | Currencies Grantable | Notes |
|---|---|---|---|
| Match reward | Currency System (internal, triggered by Match Flow fan-out) | Coins + Diamonds | Fired from `match_result_for_rewards` event handler |
| Daily login | Auth middleware / login handler (internal) | Coins only | Fires on first login of UTC day |
| Quest reward | Quest System (server-to-server internal call) | Coins + Diamonds | Amounts defined by Quest System GDD |
| Rewarded ad | Ad callback handler (server-side AdMob callback) | Coins only | Cap enforced per §3.2.4 |
| IAP fulfillment | Purchase Fulfillment System (RevenueCat webhook handler) | Diamonds only | Amounts from package table §4.2 |
| Admin grant | Admin API (admin-scoped JWT required) | Coins + Diamonds | Per-day limits enforced §3.2.6 |

Spend operations are initiated by the client (via authenticated player JWT) and validated server-side. The client never directly writes balance fields.

---

## 4. Formulas

### 4.1 Coin and Diamond Earn Per Match

Match Coin rewards are calculated and disbursed by the Reward System. Currency System handles transaction recording and balance enforcement only.

---

### 4.2 Diamond IAP Packages

All prices are in USD. RevenueCat handles local currency conversion and store pricing. The game server receives a `diamonds_to_grant` value from the Purchase Fulfillment system; the Currency System does not inspect price or currency.

| Package ID | Diamonds | USD Price | Effective ¢/Diamond | Notes |
|---|---|---|---|---|
| `diamonds_starter` | 80 | $0.99 | 1.24¢ | Lowest entry point; first-purchase candidate |
| `diamonds_small` | 200 | $1.99 | 0.995¢ | ~2× starter value |
| `diamonds_medium` | 500 | $4.99 | 0.998¢ | Approximate 1 ¢/Diamond baseline |
| `diamonds_large` | 1,100 | $9.99 | 0.908¢ | ~10% bonus vs. medium |
| `diamonds_xlarge` | 2,400 | $19.99 | 0.833¢ | ~17% bonus vs. medium |
| `diamonds_mega` | 6,500 | $49.99 | 0.769¢ | ~23% bonus vs. medium; highest value/$ |

**Bonus calculation (for reference):**

```
bonus_pct = (actual_diamonds / (price_usd × base_rate_per_dollar)) - 1

Base reference rate: 100 Diamonds / $1.00 (1¢ per Diamond)

Example — diamonds_large:
  bonus_pct = (1100 / (9.99 × 100)) - 1
            = (1100 / 999) - 1
            = 1.101 - 1
            = 10.1% bonus vs. base rate
```

---

### 4.3 Daily Login Streak Formula

```
day_streak = consecutive_login_days (capped at 5)

coin_grant = DAILY_BONUS_BASE + (day_streak - 1) × DAILY_BONUS_INCREMENT

where:
  DAILY_BONUS_BASE      = 50
  DAILY_BONUS_INCREMENT = 25
  cap at day_streak = 5 → max grant = 50 + (5-1) × 25 = 50 + 100 = 150 Coins
```

**Example calculations:**

```
Day 1: 50 + (1-1) × 25 = 50 Coins
Day 2: 50 + (2-1) × 25 = 75 Coins
Day 3: 50 + (3-1) × 25 = 100 Coins
Day 4: 50 + (4-1) × 25 = 125 Coins
Day 5: 50 + (5-1) × 25 = 150 Coins  ← cap; all days 5+ grant 150
```

---

### 4.4 Currency Conversion

**There is no conversion between Coins and Diamonds.** Coins cannot be exchanged for Diamonds. Diamonds cannot be exchanged for Coins. This is an explicit design decision to preserve the distinct value of the hard currency and ensure IAP is never "replaced" by grinding. Any future conversion mechanic must go through a design review and requires a GDD revision.

---

### 4.5 Earnable Character Unlock Coin Cost Justification

Earnable characters carry individual Coin prices (Grim 600, Fen 800, Dash 1,200) that tier the unlock progression. At `C_base_loss` = 25 Coins per match (worst case, no Play Pass):

```
Grim  (600 Coins):   ceil(600  / 25) = 24 matches (loss-only) | ceil(600  / 45) = 14 matches (win-only)
Fen   (800 Coins):   ceil(800  / 25) = 32 matches (loss-only) | ceil(800  / 45) = 18 matches (win-only)
Dash (1200 Coins):   ceil(1200 / 25) = 48 matches (loss-only) | ceil(1200 / 45) = 27 matches (win-only)
```

At approximately 5 minutes per match, Grim is reachable in under 2 hours of play (loss-only), making the first unlock accessible to casual players. Dash at 48 loss-only matches (~4 hours) represents a genuine mid-term goal. With Play Pass loss grants (37 Coins), the ceilings drop to 17, 22, and 33 matches respectively. These ranges tier engagement: new players unlock Grim quickly, intermediate players grind toward Fen, and committed players earn Dash — before branching into premium content.

---

## 5. Edge Cases

### 5.1 Double-Spend Race Condition

**Scenario:** A player has 800 Diamonds. They tap "Buy Colt" (800 Diamonds) twice in rapid succession. Two spend requests arrive at the server within milliseconds of each other.

**Resolution:**
1. Both requests attempt to acquire `currency_lock:{playerId}` (Redis distributed lock, TTL 5s).
2. Request A acquires the lock first.
3. Request B attempts to acquire and waits up to 200ms. If Request A completes within 200ms, Request B then proceeds and reaches step 4 (balance validation). At this point `diamond_balance = 0`, which is less than 800. The system returns HTTP 422 with error code `INSUFFICIENT_BALANCE`. No duplicate spend.
4. If Request B gives up waiting (200ms elapsed, A still holds the lock), Request B returns HTTP 429 (`LOCK_CONTENTION`). The client may retry after a brief delay, at which point A has completed and B will reach the balance check and fail cleanly.
5. Additionally, if the client includes a `requestId` in its spend payload (required), the idempotency check at step 4 of §3.6 catches any duplicate that slipped through the lock (e.g., a network retry of Request A itself). The second identical `idempotency_key` returns the original result without re-executing.

**Result:** Only one of the two spend requests succeeds. The player's balance reaches 0, not -800. The character is unlocked exactly once.

---

### 5.2 IAP Grant Fails After Payment Captured

**Scenario:** RevenueCat confirms a payment and fires the webhook. The Purchase Fulfillment system calls `grantCurrency` on the Currency System. The Currency System's grant transaction fails (PostgreSQL timeout, connection drop, Redis unavailable) after the payment has been captured by the store.

**Resolution:**
1. The Purchase Fulfillment system treats a non-200 response from `grantCurrency` as a failed grant. It does not retry immediately.
2. Purchase Fulfillment marks the transaction `grant_status: "pending"` in its own ledger and schedules a retry with exponential backoff: 30s → 2min → 10min → 30min → manual ops alert.
3. Each retry calls `grantCurrency` with the same `idempotency_key` (`"iap:{revenuecat_transaction_id}"`). If the first attempt actually committed but returned a network error to the caller, the idempotency check at step 4 of §3.6 returns the original success result without re-granting. No double-grant occurs.
4. If all retries exhaust (`grant_status: "failed"` after 30 minutes), an ops alert fires. The ops team can manually trigger the grant via the admin API. The player's RevenueCat receipt is preserved as proof.
5. The player is not notified of internal retry attempts. If the grant arrives late (after the player has navigated away from the results screen), the `profile:refresh` Socket.io event updates their Diamond balance the next time they are connected.

**The player is never charged without receiving their Diamonds.** They may experience a delay, but eventual delivery is guaranteed by the retry chain.

---

### 5.3 Client Shows Wrong Balance (Stale Cache)

**Scenario:** The Currency System writes a new Diamond balance after a match reward. The Socket.io `profile:refresh` event fails to reach the client (player disconnected briefly). The client continues displaying the old cached balance.

**Resolution:**
1. The currency write always invalidates the Redis cache (`DELETE profile:{playerId}`) and fires `profile:refresh` via Socket.io as defined in player-profile.md §3.4.
2. If the Socket.io event is not delivered (player disconnected), the client will display the stale value until the next profile read. On reconnect, the client's socket reconnection handler requests a fresh profile (`GET /profile`). The Redis cache has been invalidated, so the API server queries PostgreSQL and returns the confirmed balance.
3. The client must never display a currency balance without server confirmation. There is no client-side speculative balance update. If the client UI animates a "+67 Coins" on the results screen, that animation is driven by the `match_results_reward_update` payload from Match Flow — which carries the confirmed server values, not a client-computed delta.
4. If a player opens a second device while the first device has a stale balance, the second device will load a fresh profile from PostgreSQL (cache invalidated) and show the correct balance. The first device will display the correct balance on its next profile refresh.

---

### 5.4 Player Hits Wallet Cap During Grant

**Scenario:** A player has 49,980 Coins. A match reward would grant 45 Coins (win, no Play Pass). Applying the full grant would result in 50,025 Coins, which exceeds the 50,000 cap.

**Resolution:**
1. Inside the grant transaction (step 4 of §3.6), the Currency System computes `available_headroom = cap - current_balance = 50,000 - 49,980 = 20`.
2. `actual_amount = min(requested_amount, available_headroom) = min(45, 20) = 20`.
3. The ledger row records `requested_amount: 45`, `actual_amount: 20`, `balance_before: 49980`, `balance_after: 50000`.
4. Analytics event `CURRENCY_GRANT_CAPPED` is emitted: `{ playerId, currency: "coins", requested: 45, actual: 20, cap: 50000 }`.
5. No error is returned to the caller. The grant is considered successful with the truncated amount.
6. The caller (Match Flow's Currency System handler) receives the new confirmed balance (50,000). The `match_results_reward_update` payload sent to the client reflects the actual 20 Coins granted, not the formula's 45 — the payload is built from the Currency System's confirmed ledger entry, not the formula output.

---

### 5.5 Grant During Offline / Reconnect

**Scenario:** A match ends. Match Flow fires `match_result_for_rewards`. The Currency System processes and commits the grant to PostgreSQL. The player is offline and never receives the `profile:refresh` Socket.io event. The player reconnects 10 minutes later.

**Resolution:**
1. Currency grants are entirely server-side. The player does not need to be online for the grant to execute. The grant is committed to PostgreSQL and the ledger during the match-end fan-out (or its retry window), independent of client connectivity.
2. On reconnect, the client authenticates and calls `GET /profile`. The Redis cache for this player was invalidated when the grant committed. The API server queries PostgreSQL and returns the balance including the match reward.
3. The player sees their updated balance immediately on profile load post-reconnect. No UI reconciliation or special reconnect-flow handling is required by the Currency System. The standard profile read path handles this.
4. If the Currency System's match-reward grant had not yet committed when the player reconnected (e.g., the Reward System was still in its retry window), the player temporarily sees a balance without the pending reward. When the grant eventually commits, the `profile:refresh` event fires (if the player is connected) or the balance updates on the next profile read.

---

## 6. Dependencies

### 6.1 Upstream — Currency System Consumes

| System | What Currency System Needs | Interface | Notes |
|---|---|---|---|
| **Match Flow** | `match_result_for_rewards` event at match end (Step 5 fan-out) | Async internal event; Currency System subscribes | Contains per-player outcome, `has_play_pass` flag for reward calculation |
| **Player Profile** | Read `coin_balance`, `diamond_balance`, `has_play_pass`, `daily_login_last_claimed_at`, `daily_login_streak`, `ad_reward_grants_today` before mutations | PostgreSQL `SELECT ... FOR UPDATE` within transaction | Profile is the source of truth; Currency System reads and writes profile fields |
| **Authentication** | Supabase JWT validation for all API endpoints | Every request validated via Auth middleware | Admin endpoints require admin-scoped JWT |
| **Remote Config** | `currency.*` cold keys for earn rates, caps, IAP prices | `GET /v1/config` at app launch; Cold keys require server restart to take effect | Earn rates must not be changed mid-session; cold-key classification is intentional |
| **Analytics / Telemetry** | Accepts `CURRENCY_GRANT`, `CURRENCY_SPEND`, `CURRENCY_GRANT_CAPPED` events | Async fire-and-forget via analytics event emitter | PII policy: `playerId` (UUID) is allowed; no display names in logs |

### 6.2 Downstream — Currency System Produces / Notifies

| System | What Currency System Provides | Interface | Notes |
|---|---|---|---|
| **Player Profile** | Writes `coin_balance`, `diamond_balance`, `daily_login_streak`, `daily_login_last_claimed_at`, `ad_reward_grants_today`; invalidates Redis cache; emits `profile:refresh` | PostgreSQL transaction + Redis DELETE + Socket.io emit | Economy fields always trigger forced client refresh (per player-profile.md §3.4) |
| **Character Unlock System** | Coin-spend confirmation in the same transaction as character grant | PostgreSQL transaction (both writes atomic) | Currency System initiates; Character Unlock System's `appendUnlock` is called within the same transaction scope |
| **Match Flow** | `reward_grants_confirmed { matchId, playerGrants[] }` response | Async response to `match_result_for_rewards` event | Match Flow tracks this with `REWARD_TIMEOUT_MS` per match-flow.md §3.4 Step 7 |
| **Purchase Fulfillment** | Diamond grant confirmation (HTTP 200 + new balance, or error code for retry) | Synchronous HTTP response to `grantCurrency` call | Purchase Fulfillment owns retry logic for IAP grants |
| **Analytics / Telemetry** | `CURRENCY_GRANT`, `CURRENCY_SPEND`, `CURRENCY_GRANT_CAPPED` events | Async fire-and-forget | Emitted after every committed ledger row |

### 6.3 Architectural Note: No Cross-Currency Conversion Path

The Currency System has no conversion endpoint. Coins and Diamonds are separate economies. Any system that attempts to call a coin-to-diamond or diamond-to-coin conversion will receive HTTP 404 (endpoint does not exist). This is enforced architecturally, not by a flag.

---

## 7. Tuning Knobs

All values are Remote Config **cold keys** unless marked Hot. Cold keys require a server restart to take effect; changes must be deployed during maintenance windows or low-traffic periods. Earn rates are cold keys intentionally — mid-session economy changes would create inconsistent reward expectations within a session.

| Parameter | Remote Config Key | Default | Safe Range | What Breaks Outside Range |
|---|---|---|---|---|
| Coin grant — win | `currency.coinBaseWin` | `45` | 20–100 | Below 20: feels unrewarding; player progression to character unlocks takes 140+ sessions. Above 100: earnable characters unlock within 25 matches, eliminating mid-term goal. |
| Coin grant — loss/draw | `currency.coinBaseLoss` | `25` | 10–60 | Below 10: loss sessions feel punishing; play-to-earn loop breaks for casual players. Above 60: approaches win value, removing win incentive. Must be < `coinBaseWin`. |
| Diamond grant — win | `currency.diamondBaseWin` | `5` | 1–15 | Below 1: Diamond earn feels negligible; premium character grind via play is impossible. Above 15: free-to-play Diamond accrual too fast; undermines IAP value proposition. |
| Play Pass Coin multiplier | `currency.playPassCoinMult` | `1.5` | 1.0–2.5 | Below 1.0: invalid (Play Pass must be at least neutral). Above 2.5: Play Pass Coin advantage makes free players feel economically locked out. |
| Play Pass Diamond multiplier | `currency.playPassDiamondMult` | `1.25` | 1.0–2.0 | Below 1.0: invalid. Above 2.0: Play Pass Diamond earn rate approaches IAP value, reducing Diamond purchase incentive. |
| Coin wallet cap | `currency.coinCap` | `50000` | 10000–200000 | Below 10000: high-engagement players hit cap frequently; rewards feel meaningless. Above 200000: no practical effect but inflates economy tracking noise. |
| Diamond wallet cap | `currency.diamondCap` | `100000` | 10000–500000 | Below 10000: cap would affect whale IAP behavior. Above 500000: no practical effect. |
| Daily login base coins | `currency.dailyBonusBase` | `50` | 20–100 | Below 20: daily login bonus is not motivating. Above 100: daily bonus competes with match earning as primary Coin source, reducing play session engagement. |
| Daily login increment | `currency.dailyBonusIncrement` | `25` | 0–50 | 0: flat bonus every day (no streak incentive). Above 50: Day 5 bonus (200) would be 4× Day 1, which may incentivize session skipping to "save" for streaks — perverse behavior. |
| Ad reward coins | `currency.adRewardCoins` | `15` | 5–30 | Below 5: rewarded ads not worth player time. Above 30: ad-watching approaches match-play efficiency; incentivizes watch-over-play behavior. |
| Ad reward daily cap | `currency.adRewardMaxGrantsPerSession` | `5` | 1–10 | Below 1: invalid. Above 10: increases AdMob impression revenue short-term but risks rewarded ad fatigue and churn. |
| Currency lock TTL | `currency.lockTtlMs` | `5000` | 2000–15000 | Below 2000ms: lock may expire during a slow PostgreSQL write under load, enabling race conditions. Above 15000ms: failed requests hold the lock too long, blocking subsequent legitimate requests. |
| Lock acquisition timeout | `currency.lockAcquireTimeoutMs` | `200` | 50–1000 | Below 50ms: too many false-429s on congested servers. Above 1000ms: spend requests feel slow to users; exploit window for manual double-tap. |
| Battle Pass price | `currency.battlePassPriceDiamonds` | `950` | 400–1200 | Below 400: Battle Pass undervalued; undermines IAP premium perception. Above 1200: above psychological price ceiling for mobile subscription-adjacent purchase. |
| Earnable character price (Grim) | `currency.earnableCharacterPriceCoins.grim` | `600` | 200–2000 | Below 200: unlocks within 8 matches; no meaningful short-term goal. Above 2000: first unlock takes 80+ matches; too high for early engagement. |
| Earnable character price (Fen) | `currency.earnableCharacterPriceCoins.fen` | `800` | 300–2500 | Must be > Grim price to preserve tier progression. Above 2500: approaches old flat price; 100+ match grind for casual players. |
| Earnable character price (Dash) | `currency.earnableCharacterPriceCoins.dash` | `1200` | 500–4000 | Must be > Fen price. Below 500: collapses with Fen tier. Above 4000: 160+ loss-only matches; casual players never reach it. |
| Premium character price | `currency.premiumCharacterPriceDiamonds` | `800` | 400–1500 | Below 400: premium characters feel underpriced vs. Battle Pass. Above 1500: above single-package IAP cost at starter tier; requires combo purchase. |
| Admin grant daily Coin cap | `currency.adminGrantMaxCoinsPerDay` | `5000` | 1000–50000 | Below 1000: too restrictive for legitimate support grants. Above 50000: single admin action can materially distort a player's economy. |
| Admin grant daily Diamond cap | `currency.adminGrantMaxDiamondsPerDay` | `500` | 100–5000 | Below 100: insufficient for support resolution of failed IAP grants. Above 5000: exceeds largest IAP package; requires audit justification. |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and are independently verifiable by automated test or documented manual QA.

### 8.1 Grant Path — Match Reward

**AC-CS-01 — Coin grant on win, no Play Pass**
- Given: A player with `coin_balance: 100`, `has_play_pass: false` wins a match
- When: Currency System receives `match_result_for_rewards` with `outcome: "win"`
- Then: `coin_balance` becomes `145`; ledger row has `delta: 45`, `source: "match_reward"`, `actual_amount: 45`; `profile:refresh` Socket.io event fires; `CURRENCY_GRANT` analytics event emitted

**AC-CS-02 — Coin + Diamond grant on win, Play Pass active**
- Given: A player with `coin_balance: 100`, `diamond_balance: 50`, `has_play_pass: true` wins a match
- When: Currency System receives `match_result_for_rewards` with `outcome: "win"`
- Then: `coin_balance` becomes `167` (100 + floor(45 × 1.5) = 100 + 67); `diamond_balance` becomes `56` (50 + floor(5 × 1.25) = 50 + 6); two ledger rows created (one Coin, one Diamond); both `profile:refresh` events fire

**AC-CS-03 — Coin grant on loss; zero Diamond grant**
- Given: A player with `coin_balance: 200`, `diamond_balance: 30`, `has_play_pass: false` loses a match
- When: Currency System receives `match_result_for_rewards` with `outcome: "loss"`
- Then: `coin_balance` becomes `225`; `diamond_balance` remains `30`; exactly one ledger row created (Coins); no Diamond ledger row created for this event

**AC-CS-04 — Match reward idempotency**
- Given: The `match_result_for_rewards` event for `matchId: "abc"` and `playerId: "xyz"` is delivered twice (duplicate due to retry)
- When: Both deliveries are processed by the Currency System
- Then: The ledger contains exactly one row with `idempotency_key: "match_reward:abc:xyz"`; `coin_balance` is incremented exactly once; second call returns HTTP 200 with the original committed result

---

### 8.2 Spend Path

**AC-CS-05 — Earnable character unlock: successful spend**
- Given: A player with `coin_balance: 1000` requests to unlock Fen (800 Coins)
- When: Spend request is processed
- Then: `coin_balance` becomes `200`; Character Unlock System receives `appendUnlock("fen")` in the same transaction; ledger row has `delta: -800`, `source: "spend_character"`; `profile:refresh` fires

**AC-CS-06 — Insufficient balance rejection**
- Given: A player with `coin_balance: 500` requests to unlock Fen (800 Coins)
- When: Spend request is processed
- Then: HTTP 422 returned with error code `INSUFFICIENT_BALANCE`; `coin_balance` remains `500`; no ledger row created; Character Unlock System is NOT called; Redis cache NOT invalidated

**AC-CS-07 — Spend and character grant atomicity**
- Given: A player with `coin_balance: 1000` requests Fen unlock; the Character Unlock System's `appendUnlock` call throws an error mid-transaction
- When: The transaction attempts to commit
- Then: The entire transaction rolls back; `coin_balance` remains `1000`; Fen is NOT added to `unlocked_character_ids`; no ledger row exists for this attempt

---

### 8.3 Double-Spend Prevention

**AC-CS-08 — Concurrent spend requests: only one succeeds**
- Given: A player with `diamond_balance: 800` submits two simultaneous "Buy Colt" requests (800 Diamonds each)
- When: Both requests are processed concurrently
- Then: Exactly one request returns HTTP 200 (spend committed, `diamond_balance = 0`, Colt unlocked); the other returns HTTP 422 (`INSUFFICIENT_BALANCE`) or HTTP 429 (`LOCK_CONTENTION`); `diamond_balance` is 0, not -800; exactly one ledger row with `source: "spend_character"` exists for this event; Colt appears in `unlocked_character_ids` exactly once

**AC-CS-09 — Idempotent spend via requestId**
- Given: A spend request with `requestId: "req-001"` succeeds; the client retries with the same `requestId: "req-001"` due to a network timeout
- When: The retry is processed
- Then: The second request returns HTTP 200 with the original committed balance (idempotency); no second deduction occurs; the ledger contains exactly one row with `idempotency_key: "spend:req-001"`

---

### 8.4 Wallet Cap

**AC-CS-10 — Coin grant truncated at cap**
- Given: A player with `coin_balance: 49,990` earns a 45-Coin match reward
- When: The grant is processed
- Then: `coin_balance` becomes `50,000` (not `50,035`); ledger row has `requested_amount: 45`, `actual_amount: 10`; `CURRENCY_GRANT_CAPPED` analytics event emitted with `dropped_amount: 35`; HTTP 200 returned to caller (not an error)

**AC-CS-11 — Grant at exact cap: zero amount applied**
- Given: A player with `coin_balance: 50,000` earns a 25-Coin match reward
- When: The grant is processed
- Then: `coin_balance` remains `50,000`; ledger row has `requested_amount: 25`, `actual_amount: 0`; `CURRENCY_GRANT_CAPPED` analytics event emitted; HTTP 200 returned

---

### 8.5 IAP Grant

**AC-CS-12 — Diamond IAP grant committed**
- Given: Purchase Fulfillment calls `grantCurrency` with `source: "iap"`, `amount: 500`, `idempotency_key: "iap:rc-txn-42"`
- When: The grant is processed
- Then: `diamond_balance` increases by 500; ledger row has `source: "iap"`, `source_ref: "rc-txn-42"`; `profile:refresh` fires; HTTP 200 returned with new balance

**AC-CS-13 — IAP grant idempotency after retry**
- Given: An IAP grant with `idempotency_key: "iap:rc-txn-42"` succeeded but the HTTP response was lost; Purchase Fulfillment retries with the same key
- When: The retry is processed
- Then: No second Diamond grant occurs; HTTP 200 returned with the original committed balance; ledger contains exactly one row for `"iap:rc-txn-42"`

---

### 8.6 Daily Login Bonus

**AC-CS-14 — Day 1 login bonus**
- Given: A player logs in for the first time today (UTC); `daily_login_last_claimed_at` is null or yesterday's date
- When: Login is processed
- Then: `coin_balance` increases by 50; `daily_login_streak` becomes 1; `daily_login_last_claimed_at` set to today's UTC date; ledger row has `source: "daily_login"`, `idempotency_key: "daily_login:{playerId}:{date}"`

**AC-CS-15 — Day 5+ login bonus (cap)**
- Given: A player has logged in on 4 consecutive prior days (`daily_login_streak: 4`) and logs in today
- When: Login is processed
- Then: `coin_balance` increases by 150; `daily_login_streak` becomes 5

**AC-CS-16 — Streak reset after missed day**
- Given: A player's `daily_login_last_claimed_at` is two days ago (one day missed)
- When: Player logs in today
- Then: `coin_balance` increases by 50 (Day 1 grant); `daily_login_streak` resets to 1; `daily_login_last_claimed_at` set to today

**AC-CS-17 — Daily bonus claimed only once per UTC day**
- Given: A player logs in twice in the same UTC calendar day
- When: Both logins are processed
- Then: The daily bonus fires only on the first login; the second login produces no Coin grant; no duplicate ledger row for the same `idempotency_key` date

---

### 8.7 Rewarded Ad Cap

**AC-CS-18 — Rewarded ad grant within daily cap**
- Given: A player with `ad_reward_grants_today: 4`, `has_no_ads: false` watches a rewarded ad to completion
- When: The ad callback fires
- Then: `coin_balance` increases by 15 (`AD_REWARD_COINS`); `ad_reward_grants_today` becomes 5; ledger row created with `source: "ad_reward"`

**AC-CS-19 — Rewarded ad grant rejected at daily cap**
- Given: A player with `ad_reward_grants_today: 5` requests another rewarded ad grant
- When: The ad callback fires
- Then: No Coin grant occurs; no ledger row created; HTTP 200 returned with `{ status: "cap_reached" }`; `coin_balance` unchanged

**AC-CS-20 — Rewarded ad rejected for no-ads entitlement player**
- Given: A player with `has_no_ads: true` triggers an ad reward callback
- When: The Currency System processes the request
- Then: HTTP 403 returned with error code `NO_ADS_ENTITLEMENT`; no Coin grant; no ledger row

---

### 8.8 Negative Balance Prevention

**AC-CS-21 — Database CHECK constraint prevents negative balance**
- Given: A spend transaction would result in `coin_balance = -1` (application-layer balance check bypassed in test)
- When: The PostgreSQL transaction attempts to commit
- Then: PostgreSQL `CHECK (coin_balance >= 0)` constraint violation fires; transaction rolls back; `coin_balance` unchanged; error logged as `CRITICAL: balance_constraint_violation`

---

### 8.9 Audit Trail

**AC-CS-22 — Every committed mutation has a ledger row**
- Given: Any successful currency grant or spend (from any source)
- When: The transaction commits
- Then: Exactly one row exists in `currency_ledger` with the correct `source`, `delta`, `balance_before`, `balance_after`, `actual_amount`, `idempotency_key`, and `created_at`; the row was written in the same transaction as the `player_profiles` update

**AC-CS-23 — Ledger rows are immutable after creation**
- Given: An existing ledger row
- When: Any system attempts to UPDATE or DELETE the row (other than GDPR hard-delete)
- Then: The operation is rejected (table-level permissions; only INSERT and SELECT are granted to the Currency System's database role)

---

*End of Document*
