# IAP System — Game Design Document

> **System**: IAP System
> **Priority**: Alpha
> **Layer**: Economy
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-28
> **Last Updated**: 2026-05-28

---

## 1. Overview

The IAP System is the end-to-end in-app purchase pipeline for BRAWLZONE. It governs every real-money transaction: Diamond packs (hard currency top-ups), character bundles (premium character + skin), the Play Pass subscription (ad removal + monthly Diamond grant), and the first-purchase Starter Pack. The system uses RevenueCat (`react-native-purchases`) as the sole IAP abstraction layer — no direct StoreKit (iOS) or Google Play Billing (Android) calls are made anywhere in the client codebase. Receipt validation and entitlement fulfillment happen exclusively server-side: RevenueCat validates receipts with Apple/Google and notifies the BRAWLZONE server via webhook; the server grants currency or entitlements inside an atomic PostgreSQL transaction after deduplication. The system ensures that every purchase either fully completes or fully rolls back, that no player can lose money without receiving goods, and that no player can exploit duplicate webhooks or network retries to receive goods twice. All financial audit trails are persisted in the `iap_transactions` table. PII policy: payment tokens are never written to logs; only the RevenueCat `transaction_id` (a non-PII identifier) is logged or stored.

---

## 2. Player Fantasy

A purchase must feel as safe and immediate as tapping a vending machine button. The player taps "Buy," is presented a familiar native payment sheet from Apple or Google — one they already trust — confirms with Face ID, Touch ID, or their saved payment method, and within two seconds their Diamond balance updates on screen. There is no anxiety about whether the money left their account and the Diamonds never arrived. There is no fear of double-charges. If anything goes wrong mid-purchase — app killed, network dropped, phone died — the game recovers the purchase silently the next time it opens, as if nothing bad ever happened.

For subscription players, the Play Pass badge on their profile is a quiet symbol of commitment. Ads are simply gone. Monthly Diamonds arrive on schedule without the player having to do anything. If a payment fails, the game gives grace rather than immediately stripping benefits — nobody loses their ad-free experience over a temporary card issue.

The Starter Pack is presented exactly once, feels like a genuine deal (it is — 50% off equivalent à la carte price), and disappears forever after it is claimed. That scarcity makes it feel special, not predatory.

**User Story:** As a player, I want to buy Diamonds and know they will arrive in my wallet immediately, that I will never pay twice for the same pack, and that if the app crashes mid-purchase my purchase is not lost.

---

## 3. Detailed Rules

### 3.1 IAP Abstraction Layer

RevenueCat (`react-native-purchases`) is the single, exclusive IAP abstraction layer. The following rules are non-negotiable:

- **No direct StoreKit calls.** No `SKPaymentQueue`, no `SKProduct`, no `StoreKit` imports anywhere in the client codebase.
- **No direct Google Play Billing calls.** No `BillingClient`, no `PurchasesUpdatedListener`, no `com.android.billingclient` imports.
- All product metadata (price, title, description) is fetched from RevenueCat offerings via `Purchases.getOfferings()`.
- All purchase initiation goes through `Purchases.purchasePackage()` or `Purchases.purchaseStoreProduct()`.
- All restore operations go through `Purchases.restorePurchases()`.
- RevenueCat is configured with the BRAWLZONE API key at app startup, before any IAP flow is triggered (see §3.2 initialization).

### 3.2 RevenueCat Initialization

RevenueCat is initialized in the app entry point after Authentication resolves (a valid Supabase `userId` must be available):

```typescript
interface IAPInitConfig {
  revenueCatApiKey: string;  // platform-specific; injected from Remote Config or env
  userId: string;            // Supabase UUID — links RevenueCat customer to BRAWLZONE account
  observerMode: false;       // BRAWLZONE always uses full RevenueCat purchase flow
}
```

1. Call `Purchases.configure({ apiKey, appUserID: userId })` on app launch after Authentication resolves.
2. If the user was previously anonymous (guest) and logs into their account, call `Purchases.logIn(userId)` to merge purchase history.
3. On logout, call `Purchases.logOut()` to prevent purchase history leaking to a subsequent user on the same device.

### 3.3 Purchase Flow

The complete purchase flow for a one-time product (Diamond pack, character bundle, Starter Pack):

```
Player taps "Buy" on a product
    │
    ▼
[1] Client: fire IAP_PURCHASE_INITIATED analytics event
    │   properties: { productId, priceUsd, currencyCode }
    │
    ▼
[2] Client: Purchases.purchasePackage(package)
    │   — native payment sheet shown (Apple Pay sheet / Google Play payment)
    │   — player authenticates (Face ID / fingerprint / password)
    │
    ├── User cancels → fire IAP_PURCHASE_FAILED { failureReason: "user_cancelled" }
    │                  return to shop screen; no server call
    │
    ├── Purchase error (network, card declined) →
    │       fire IAP_PURCHASE_FAILED { failureReason: error.code }
    │       show error toast; return to shop screen; no server call
    │
    └── Purchase success: RevenueCat returns PurchasesStoreTransaction
            │
            ▼
[3] Client: POST /v1/iap/fulfil
    │   body: { productId, revenueCatTransactionId }
    │   Authorization: Bearer {jwt}
    │   (via API Client — retried on 5xx per API Client GDD §3.x)
    │
    ├── Server responds 200 { fulfilled: true, newBalance: N, entitlementsGranted: [...] }
    │       │
    │       ▼
    │   [4] Client: update wallet UI from server response
    │       fire IAP_PURCHASE_COMPLETED analytics event
    │       { productId, transactionId (hashed), priceUsd }
    │       show success animation / modal
    │
    └── Server responds 4xx / retries exhausted →
            see Edge Case §5.3 (app-side recovery path)
```

**Note on client-side fulfillment call:** The `POST /v1/iap/fulfil` call is an optimistic UX shortcut — the server also receives the RevenueCat webhook independently (§3.4). If the client call succeeds first, the player sees their balance update immediately. If the webhook arrives first (rare), the client call is a no-op (idempotent). Both paths converge to the same final state.

### 3.4 Server-Side Receipt Validation and Fulfillment via RevenueCat Webhooks

BRAWLZONE uses **RevenueCat server-side webhooks** as the authoritative fulfillment trigger. Client-initiated `POST /v1/iap/fulfil` calls provide fast UI feedback, but the webhook is the ground truth.

#### Webhook Endpoint

`POST /v1/iap/webhook/revenuecat`

- Protected by RevenueCat's shared webhook secret (verified in `X-RevenueCat-Signature` header on every incoming webhook request).
- Responds `200 OK` immediately upon receipt, before fulfillment processing (prevents RevenueCat retry storms).
- Fulfillment happens asynchronously after the 200 response, within the same server process via an internal job queue.

#### Supported Event Types

| RevenueCat Event | BRAWLZONE Action |
|-----------------|-----------------|
| `INITIAL_PURCHASE` | Grant currency / entitlement (§3.6) |
| `RENEWAL` | Extend Play Pass entitlement; grant monthly Diamonds |
| `CANCELLATION` | Mark subscription cancelled; start grace period countdown |
| `EXPIRATION` | Revoke Play Pass entitlement if not renewed within grace period |
| `REFUND` | Revoke entitlement; deduct Diamonds if unspent (§3.9) |
| `PRODUCT_CHANGE` | Log; no fulfillment action (tier changes not supported in v1) |
| `BILLING_ISSUE` | Start grace period; do not revoke immediately (§3.7) |
| `SUBSCRIBER_ALIAS` | Log; update RevenueCat userId mapping in `iap_customers` table |

#### Webhook Fulfillment Sequence

```
RevenueCat webhook arrives at POST /v1/iap/webhook/revenuecat
    │
    ▼
[1] Verify X-RevenueCat-Signature against WEBHOOK_SECRET
    │   FAIL → return 401; log WARN with masked signature; no processing
    │
    ▼
[2] Respond 200 OK immediately
    │
    ▼
[3] Enqueue fulfillment job { event_type, transaction_id, product_id, user_id, timestamp }
    │
    ▼
[4] Worker picks up job:
    │   Check iap_transactions table for existing row with same transaction_id
    │   FOUND (status = 'fulfilled') → no-op; log INFO "duplicate_webhook_ignored"
    │   NOT FOUND → proceed
    │
    ▼
[5] BEGIN PostgreSQL transaction
    │   a. INSERT INTO iap_transactions (transaction_id, product_id, user_id,
    │      event_type, raw_event_type, received_at, fulfilled_at, status)
    │      VALUES (..., 'pending')
    │      ON CONFLICT (transaction_id) DO NOTHING
    │      — if 0 rows inserted: another worker beat this one; abort transaction; no-op
    │
    │   b. Grant currency OR entitlement per product definition (§3.6)
    │      — calls Currency System grant function (atomic balance update)
    │      — OR calls Inventory/Entitlements grant function (idempotent)
    │
    │   c. UPDATE iap_transactions SET status = 'fulfilled', fulfilled_at = NOW()
    │      WHERE transaction_id = $1
    │
    │   d. COMMIT
    │
    └── On DB error → ROLLBACK; re-enqueue job with backoff (up to MAX_FULFILLMENT_RETRIES)
```

### 3.5 Product Catalog

All product IDs are defined in Remote Config cold keys (allowing A/B price testing without an app update). The following are the v1 products:

#### Diamond Packs (Consumable, One-Time Purchase)

| Canonical ID | Display Name | Diamonds Granted |
|-------------|-------------|-----------------|
| `shop_offer:diamonds_starter` | Starter Pack | 80 |
| `shop_offer:diamonds_small` | Small Pack | 200 |
| `shop_offer:diamonds_medium` | Medium Pack | 500 |
| `shop_offer:diamonds_large` | Large Pack | 1,100 |
| `shop_offer:diamonds_xlarge` | XL Pack | 2,400 |
| `shop_offer:diamonds_mega` | Mega Pack | 6,500 |

> **Note:** Actual USD prices are owned by the store/platform layer (RevenueCat, App Store, Google Play). Dollar amounts in this GDD are design-intent anchors only.

#### Character Bundles (Non-Consumable, One-Time Purchase)

| Product ID | Contents | Price |
|-----------|---------|-------|
| `bundle_character_{characterId}` | 1 character unlock + 1 exclusive skin | Varies by character (see Content Catalog) |

Character bundles are idempotent: if a player already owns the character, purchasing the bundle still grants the exclusive skin only (no duplicate character grant). Eligibility is checked server-side before fulfillment.

#### Play Pass (Auto-Renewable Subscription)

| Product ID | Period | Entitlements Granted | Monthly Diamonds |
|-----------|--------|---------------------|-----------------|
| `play_pass_weekly` | 7 days | `has_no_ads = true`, `has_play_pass = true` | 80 (prorated from monthly) |
| `play_pass_monthly` | 30 days | `has_no_ads = true`, `has_play_pass = true` | 300 |

Play Pass is checked via `Purchases.getCustomerInfo()` on every app foreground resume (see §3.7).

#### Starter Pack (Non-Consumable, One-Time Purchase, First-Purchase Only)

| Product ID | Contents | Price | Eligibility |
|-----------|---------|-------|-------------|
| `starter_pack_v1` | 400 Diamonds + exclusive starter skin | $1.99 | Only shown and purchasable when `starterPackPurchased = false` |

Eligibility rule: the Starter Pack purchase button is only shown in the Shop UI when the player's profile has `starterPackPurchased = false`. The server enforces this at fulfillment: if a `INITIAL_PURCHASE` webhook arrives for `starter_pack_v1` and `starterPackPurchased = true`, the server rejects the webhook fulfillment with a `409 Conflict` (the store purchase must be refunded via support). In practice, this scenario cannot happen if the client hides the purchase button correctly.

### 3.6 Fulfillment Actions by Product Type

| Product Type | Server Fulfillment Action |
|-------------|--------------------------|
| Diamond pack | `currencyService.grantDiamonds(userId, amount, source: "iap", transactionId)` — atomic; audit-logged by Currency System |
| Character bundle | `inventoryService.grantEntitlement(userId, characterId)` + `inventoryService.grantItem(userId, skinId)` — idempotent per Inventory GDD |
| Play Pass (new / renewal) | `profileService.setEntitlement(userId, { has_no_ads: true, has_play_pass: true })` + `currencyService.grantDiamonds(userId, PLAY_PASS_MONTHLY_DIAMONDS, source: "play_pass_renewal", transactionId)` |
| Play Pass (expiration) | `profileService.setEntitlement(userId, { has_no_ads: false, has_play_pass: false })` |
| Starter pack | `currencyService.grantDiamonds(userId, 400, source: "starter_pack", transactionId)` + `inventoryService.grantItem(userId, "skin_starter_exclusive")` + `profileService.setFlag(userId, { starterPackPurchased: true })` |

All currency grants call through the Currency System's `grantDiamonds` function, which enforces wallet cap, creates an audit trail entry, and invalidates the Redis profile cache + pushes `profile:refresh` Socket.io event per the Player Profile GDD.

### 3.7 Play Pass — Subscription State Management

#### Foreground Resume Check

On every `AppState` change from `"background"` to `"active"`, the client calls:

```typescript
const customerInfo = await Purchases.getCustomerInfo();
const hasPlayPass = customerInfo.entitlements.active["play_pass"] !== undefined;
```

If `hasPlayPass` differs from the locally cached value (from the last profile fetch), the client calls `GET /profile` to re-fetch the authoritative profile. The server's `has_play_pass` field is the source of truth; the RevenueCat entitlement check is a fast client-side heuristic only.

#### Grace Period

When RevenueCat sends a `BILLING_ISSUE` event (payment failure on renewal):

1. Server records the billing issue timestamp on the `iap_subscriptions` table row.
2. `has_play_pass` and `has_no_ads` remain `true` for `PLAY_PASS_GRACE_PERIOD_DAYS` (default: 7 days).
3. A push notification is sent at day 1, day 3, and day 6 of the grace period reminding the player to update their payment method.
4. If a `RENEWAL` webhook arrives before grace period expires: clear the billing issue; continue subscription normally.
5. If grace period expires without renewal: server sets `has_play_pass = false`, `has_no_ads = false`, pushes `profile:refresh`. An `IAP_SUBSCRIPTION_CHANGED` analytics event fires with `eventType: "lapsed"`.

#### Subscription State Machine

```
States: ACTIVE → BILLING_ISSUE → EXPIRED
                             └──→ ACTIVE (renewed before expiry)
        ACTIVE → CANCELLED (user cancelled; access continues until period end)
        CANCELLED → EXPIRED (period ends)
```

### 3.8 Restore Purchases (iOS Requirement)

A "Restore Purchases" button MUST appear in the Settings screen (required by App Store Review Guidelines §3.1.1).

Flow:
1. Player taps "Restore Purchases" in Settings → Accessibility screen.
2. Client calls `Purchases.restorePurchases()`.
3. RevenueCat re-validates all historical receipts for the current App Store account.
4. If active entitlements are found, RevenueCat fires `INITIAL_PURCHASE` webhooks for non-consumable products that are not yet recorded in `iap_transactions` for this `userId`.
5. Server processes webhooks normally (idempotent fulfillment — already-fulfilled transactions are no-ops).
6. Client then calls `GET /profile` to pick up any newly granted entitlements.
7. Show toast: "Purchases restored" if any new entitlements were found, or "No purchases to restore" if none.

**Note:** Diamond packs (consumables) are not restored — this is correct per Apple/Google policy. Only non-consumable products (character bundles, Starter Pack) and active subscriptions (Play Pass) are restored.

### 3.9 Refund Handling

RevenueCat fires a `REFUND` (for non-subscriptions) or `CANCELLATION` (for subscriptions) webhook when Apple or Google processes a refund.

#### Server-Side Refund Logic

```typescript
async function handleRefund(event: RevenueCatRefundEvent): Promise<void> {
  const tx = await db.findTransaction(event.transaction_id);
  if (!tx || tx.status !== 'fulfilled') return; // nothing to revoke

  await db.beginTransaction(async (trx) => {
    // 1. Mark transaction as refunded
    await trx.updateTransaction(event.transaction_id, { status: 'refunded', refunded_at: now() });

    // 2. Revoke entitlements (non-consumables)
    if (tx.product_type === 'entitlement') {
      await inventoryService.revokeEntitlement(tx.user_id, tx.item_id, { trx });
    }

    // 3. For Diamond packs: deduct Diamonds if unspent
    if (tx.product_type === 'currency') {
      const diamondsToRevoke = tx.diamonds_granted;
      const profile = await profileService.getProfile(tx.user_id, { trx, lock: true });
      const deductible = Math.min(profile.diamond_balance, diamondsToRevoke);
      const debt = diamondsToRevoke - deductible;

      if (deductible > 0) {
        await currencyService.deductDiamonds(tx.user_id, deductible,
          { source: 'refund', transactionId: event.transaction_id, trx });
      }

      if (debt > 0) {
        // Diamonds already spent; log debt for review — do NOT go below 0
        await debtLedger.record(tx.user_id, debt, event.transaction_id);
        logger.warn('refund_debt_logged', {
          userId: tx.user_id,
          transactionId: event.transaction_id,
          debtDiamonds: debt
        });
      }
    }

    // 4. Revoke Play Pass if subscription refund
    if (tx.product_type === 'subscription') {
      await profileService.setEntitlement(tx.user_id,
        { has_no_ads: false, has_play_pass: false }, { trx });
    }
  });
}
```

**Debt rule:** A player's Diamond balance NEVER goes below 0. If the player spent some or all of their refunded Diamonds before the refund was processed, only the remaining unspent portion is deducted. The spent portion is logged in the `iap_debt_ledger` table for fraud review; no automated punitive action is taken (manual review by support). This is a business decision: automated account suspensions for debt would create false-positive bans.

### 3.10 Receipt Storage

Every IAP transaction is persisted in the `iap_transactions` PostgreSQL table before any fulfillment action:

```typescript
interface IapTransaction {
  transaction_id: string;       // RevenueCat transaction ID — PRIMARY KEY
  user_id: string;              // Supabase UUID
  product_id: string;           // e.g., "shop_offer:diamonds_medium"
  product_type: 'currency' | 'entitlement' | 'subscription' | 'bundle';
  event_type: string;           // RevenueCat event type (e.g., "INITIAL_PURCHASE")
  store: 'app_store' | 'play_store';
  diamonds_granted: number;     // 0 for non-currency products
  received_at: string;          // ISO 8601 — when webhook arrived
  fulfilled_at: string | null;  // ISO 8601 — when fulfillment completed; null if pending
  status: 'pending' | 'fulfilled' | 'failed' | 'refunded';
  refunded_at: string | null;   // ISO 8601 — when refund was processed
  // PII NOTE: NO payment tokens, NO purchase tokens, NO card data stored here.
  // Only RevenueCat's transaction_id (a non-PII identifier) is stored.
}
```

**Index:** `CREATE UNIQUE INDEX ON iap_transactions(transaction_id)` — enforces idempotency at the DB level in addition to the application-level check.

**Retention:** `iap_transactions` rows are retained indefinitely for financial audit compliance. The `user_id` is pseudonymized to `"deleted_user"` on GDPR right-to-erasure, but the transaction record is preserved for accounting.

### 3.11 Pending Purchases (Google Play)

Google Play supports "pending transactions" — a purchase is initiated but payment is not immediately captured (e.g., cash payment at a kiosk). RevenueCat represents this as a `PENDING` state.

Rules:
1. When RevenueCat sends a `PENDING` event: insert a row in `iap_transactions` with `status = 'pending'`; do NOT grant currency or entitlements.
2. When RevenueCat subsequently sends `INITIAL_PURCHASE` for the same `transaction_id`: update the row's `event_type` and run normal fulfillment (§3.4 step 4+).
3. If no `INITIAL_PURCHASE` arrives within `PENDING_PURCHASE_EXPIRY_HOURS` (default: 72 hours): update row to `status = 'expired'`; no fulfillment.
4. The client polls `GET /v1/iap/pending` on foreground resume to check for newly-fulfilled pending purchases and update the UI if any have been fulfilled since the last check.

---

## 4. Formulas

### 4.1 Diamond Package Value Table

| Canonical ID | Display Name | Diamonds | Diamonds per $1 (design intent) | Premium vs. Base |
|-------------|-------------|---------|----------------------------------|-----------------|
| `shop_offer:diamonds_starter` | Starter Pack | 80 | ~80/$ | — (base tier) |
| `shop_offer:diamonds_small` | Small Pack | 200 | ~100/$ | ~+25% value vs. base |
| `shop_offer:diamonds_medium` | Medium Pack | 500 | ~100/$ | ~+25% value vs. base |
| `shop_offer:diamonds_large` | Large Pack | 1,100 | ~117/$ | ~+46% value vs. base |
| `shop_offer:diamonds_xlarge` | XL Pack | 2,400 | ~120/$ | ~+50% value vs. base |
| `shop_offer:diamonds_mega` | Mega Pack | 6,500 | ~130/$ | ~+63% value vs. base |

> **Note:** USD prices are design-intent anchors only; actual prices are set in App Store Connect / Google Play Console via RevenueCat.

**Value per dollar formula:**
```
value_per_dollar = diamonds_granted / usd_price
```

**Example:** `shop_offer:diamonds_large` tier (design intent $9.99): `1100 / 9.99 = 110.1 Diamonds per dollar`

**Premium percentage formula:**
```
premium_pct = ((value_per_dollar_tier / value_per_dollar_base) - 1) × 100
```

**Example:** `shop_offer:diamonds_mega` (design intent): `((130 / 80) - 1) × 100 = 62.5%` more value than the base tier.

**Design intent:** The value curve rises across tiers to reward larger purchases without making the entry price point feel predatory. The goal is convenience at the base tier and clear value escalation at higher tiers.

### 4.2 Play Pass Monthly Diamond Grant Value

| Tier | Period | Price | Diamonds Granted | Equivalent Diamond Pack | Effective Diamond Cost |
|------|--------|-------|-----------------|------------------------|----------------------|
| `play_pass_weekly` | 7 days | TBD (store-set) | 80 | ~1× `shop_offer:diamonds_starter` (80 Diamonds) | Diamonds are "bonus" on top of ad removal |
| `play_pass_monthly` | 30 days | TBD (store-set) | 300 | ~1.5× `shop_offer:diamonds_small` (200 Diamonds) | Diamonds are "bonus" on top of ad removal |

**Monthly Diamond grant value formula:**
```
diamond_value_usd = monthly_diamonds_granted / (value_per_dollar_base)
```

**Example (monthly):** `300 / 80.8 = $3.71 equivalent Diamond value` included in the monthly subscription, plus ad removal.

**Design intent:** Play Pass Diamonds are positioned as a value-add bonus, not the primary reason to subscribe. The core value proposition is the ad-free experience. This prevents "subscribe for Diamonds, then cancel" churn behavior.

### 4.3 Starter Pack Discount

```
starter_pack_savings_pct = (1 - (starter_pack_price / equivalent_ala_carte_price)) × 100
```

**Equivalent à la carte price calculation:**

| Item | À La Carte Price |
|------|----------------|
| 400 Diamonds (design-intent fraction of `shop_offer:diamonds_medium`, 500 Diamonds) | ~$3.99 (design-intent anchor) |
| Exclusive starter skin | Equivalent to a standard skin = $1.99 (store price) |
| **Total à la carte** | **~$5.98** |

**Starter Pack price:** $1.99

**Discount:** `(1 - (1.99 / 5.98)) × 100 ≈ 66.7% discount`

**Example:** A new player's first purchase of the Starter Pack at $1.99 gets ~$5.98 worth of goods — roughly a 67% saving vs. buying the same items individually. This is intentionally aggressive because the Starter Pack's business purpose is to convert free-to-play players into paying players (the most important single conversion in a free-to-play game's revenue funnel). The discount is a one-time cost of acquisition.

---

## 5. Edge Cases

**5.1 Duplicate RevenueCat Webhook (Same transactionId Received Twice)**

RevenueCat guarantees at-least-once delivery; duplicate webhooks are expected behavior.

Exact handling: When the fulfillment worker picks up a job for `transaction_id = X`, it performs a `SELECT FOR UPDATE` on the `iap_transactions` row with `transaction_id = X`. If the row exists and `status = 'fulfilled'`, the worker logs `INFO "duplicate_webhook_ignored"` with `{ transaction_id, user_id, product_id }` and exits without modifying any balance or entitlement. No error is surfaced to the player; no retry is issued. The webhook endpoint already returned 200 OK; RevenueCat will not retry further. The `ON CONFLICT (transaction_id) DO NOTHING` in step 5a of §3.4 acts as a secondary guard if two workers race on the same event simultaneously.

**5.2 Payment Captured but Fulfillment Webhook Never Arrives**

Cause: RevenueCat webhook delivery failure (their infrastructure outage or misconfigured endpoint).

Detection: A nightly reconciliation job runs at 02:00 UTC. It calls RevenueCat's server-side `GET /v1/subscribers/{userId}` for any `iap_transactions` row with `status = 'pending'` and `received_at < NOW() - RECONCILIATION_LAG_HOURS` (default: 24 hours). If RevenueCat returns `INITIAL_PURCHASE` for a transaction that BRAWLZONE has not fulfilled, the job triggers the same fulfillment pipeline as a normal webhook.

Fallback: If the reconciliation job itself fails or the RevenueCat API is unreachable, the job logs `ERROR "reconciliation_failed"` and the on-call engineer is paged. Affected players can manually trigger recovery by tapping "Restore Purchases" in Settings (§3.8), which forces a fresh `getCustomerInfo()` call that re-triggers the entitlement sync.

**5.3 App Killed Immediately After Purchase Confirmation Before Fulfillment UI Shown**

Cause: Player's phone dies, OS kills the app, or player force-quits between RevenueCat's `purchasePackage()` returning success and the client receiving the fulfillment API response.

Exact handling:
1. RevenueCat already has the successful purchase recorded server-side — the receipt was validated by Apple/Google before the native SDK returned success.
2. The RevenueCat webhook fires independently of the client, so fulfillment proceeds even though the client never saw the success response.
3. On the next app launch, `Purchases.getCustomerInfo()` is called during the foreground resume check. If active entitlements are present that are not reflected in the player profile, the client calls `GET /profile` to re-fetch. The balance/entitlement is already correct server-side.
4. If the client-side `POST /v1/iap/fulfil` call is also pending in the API Client's offline queue (FIFO 50 entries, 60s TTL per API Client GDD), it will be delivered on reconnect. The server fulfillment is idempotent — the second fulfillment attempt for the same `transaction_id` is a no-op.
5. No player action is required; the purchase recovery is silent and automatic. If 30 seconds elapse after launch without balance reflecting the expected purchase, the player is shown a soft toast: "Purchase found — restoring…" and the restore path is triggered automatically.

**5.4 User Changes Apple ID or Google Account Mid-Session**

Cause: Player signs into a different App Store / Google Play account on the device while BRAWLZONE is running.

Exact handling: RevenueCat does not automatically reattach purchase history when the store account changes. BRAWLZONE does not support store account switching mid-session. If a purchase is attempted after the store account changes:
1. The native payment sheet will succeed under the new store account.
2. RevenueCat will create a new anonymous RevenueCat user for the new store account.
3. The `purchasePackage()` response on the client will still link to the BRAWLZONE `userId` currently logged in (because RevenueCat was initialized with that `userId`).
4. The fulfillment webhook fires with the BRAWLZONE `userId`, so fulfillment succeeds for the current account.
5. The new store account's purchase history is not lost — it is recorded in RevenueCat under that store account's identity and can be recovered via "Restore Purchases" if the player ever logs into that store account again on a BRAWLZONE account that was previously linked.

Account-switching is a support edge case. Players who believe purchases are on the wrong account must contact support; no automated resolution flow is in scope for v1.

**5.5 Refund After Diamonds Partially Spent**

See §3.9 full logic. Summary: only the remaining unspent Diamond balance is deducted, down to a floor of 0. The shortfall is logged in `iap_debt_ledger` as an informational record for fraud review. The player's account is not suspended, not flagged, and does not receive any UI notification about the debt. The debt record is used by the fraud team to identify patterns of repeat refund abuse; individual accounts showing three or more debt events within 90 days are flagged for manual review.

**5.6 Subscription Lapses (Grace Period, Then Entitlement Revoked)**

When `BILLING_ISSUE` fires: `has_play_pass` and `has_no_ads` remain `true`. Push notifications are sent at day 1, 3, 6. If `RENEWAL` fires before day 7: subscription continues, grace period record is cleared. If no `RENEWAL` arrives by day 7: `EXPIRATION` or a server-side grace expiry job fires. Server sets `has_play_pass = false`, `has_no_ads = false`, invalidates Redis cache, pushes `profile:refresh` Socket.io event. Analytics event `IAP_SUBSCRIPTION_CHANGED` fires with `{ eventType: "lapsed", productId }`. The player sees ads again on the next ad-eligible screen. No data is lost; earned Diamonds from prior Play Pass grants are not revoked.

**5.7 Jailbroken Device / Receipt Tampering**

RevenueCat performs server-side receipt validation with Apple's and Google's servers — client-provided receipts are validated before any webhook fires. BRAWLZONE never validates receipts client-side. What BRAWLZONE does on RevenueCat validation failure:

1. RevenueCat does not fire an `INITIAL_PURCHASE` webhook for a receipt that fails store-side validation.
2. If a tampered `POST /v1/iap/fulfil` request arrives directly (bypassing the client SDK), the server looks up the `transaction_id` in `iap_transactions`. If no matching row with `status = 'fulfilled'` exists (because no valid webhook preceded the call), the server returns `402 Payment Required` with body `{ error: "purchase_not_validated" }`.
3. No currency or entitlement is granted.
4. The attempt is logged at WARN level: `{ event: "fulfil_without_valid_webhook", userId, productId, transactionId }`.
5. Three or more `fulfil_without_valid_webhook` events from the same `userId` within 24 hours trigger an automated flag on the account for security review.
6. No client-side jailbreak detection is implemented in v1 (RevenueCat's server-side validation makes client-side detection unnecessary for purchase protection).

---

## 6. Dependencies

### 6.1 Upstream Dependencies (What IAP System Requires)

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| RevenueCat (`react-native-purchases`) | IAP depends on RevenueCat | Sole IAP abstraction layer; purchase initiation, receipt validation, subscription management, restore |
| Authentication (Supabase) | IAP depends on Auth | `userId` UUID required to initialize RevenueCat and link purchases to accounts; JWT required on all server IAP endpoints |
| API Client | IAP depends on API Client | `POST /v1/iap/fulfil` and `GET /v1/iap/pending` calls; offline queue and retry handled by API Client |
| Currency System (`currency-system.md`) | IAP depends on Currency | `grantDiamonds()` and `deductDiamonds()` called during fulfillment and refund handling; atomicity and audit trail owned by Currency System |
| Inventory / Entitlements (`inventory-entitlements.md`) | IAP depends on Inventory | `grantEntitlement()` and `grantItem()` called for character bundles and Starter Pack skin; idempotency guaranteed by Inventory System |
| Player Profile (`player-profile.md`) | IAP depends on Player Profile | `setEntitlement()` (Play Pass flags), `setFlag()` (starterPackPurchased), Redis invalidation + `profile:refresh` event |
| Remote Config (`remote-config.md`) | IAP depends on Remote Config | IAP product IDs and pricing display labels read from cold config keys for A/B price testing |
| Analytics / Telemetry (`analytics-telemetry.md`) | IAP emits to Analytics | `IAP_PURCHASE_INITIATED`, `IAP_PURCHASE_COMPLETED`, `IAP_PURCHASE_FAILED`, `IAP_SUBSCRIPTION_CHANGED` events |
| Logging / Monitoring (`logging-monitoring.md`) | IAP emits to Logging | All fulfillment lifecycle events logged via ILogger; PII policy enforced (transaction_id only, no payment tokens) |
| Push Notifications (APNs/FCM) | IAP depends on Push | Grace period reminder notifications at day 1, 3, 6 of billing issue |

### 6.2 Downstream Dependencies (What IAP System Feeds)

| System | Nature of Dependency |
|--------|---------------------|
| Currency System | Receives `grantDiamonds()` calls on purchase fulfillment; receives `deductDiamonds()` calls on refund |
| Inventory / Entitlements | Receives `grantEntitlement()` / `grantItem()` calls on character bundle / Starter Pack fulfillment |
| Player Profile | Receives `setEntitlement()` (Play Pass) and `setFlag()` (starterPackPurchased) mutations; triggers Redis invalidation and profile refresh |
| Shop UI | Reads `starterPackPurchased` from profile to determine Starter Pack visibility; reads `has_play_pass` for Play Pass state indicator |
| Ad System | Reads `has_no_ads` from profile; IAP is the only source of truth for this flag |
| Analytics | Receives IAP purchase funnel events for conversion and revenue analysis |
| Fraud / Support | Reads `iap_transactions`, `iap_debt_ledger` for refund abuse review |

### 6.3 Remote Config Keys Owned by IAP System

| Key | Type | Default | Hot/Cold | Description |
|-----|------|---------|---------|-------------|
| `iap.diamondPackStarterProductId` | `string` | `"com.brawlzone.diamonds_starter"` | Cold | Store SKU for Starter Pack (80 Diamonds) |
| `iap.diamondPackSmallProductId` | `string` | `"com.brawlzone.diamonds_small"` | Cold | Store SKU for Small Pack (200 Diamonds) |
| `iap.diamondPackMediumProductId` | `string` | `"com.brawlzone.diamonds_medium"` | Cold | Store SKU for Medium Pack (500 Diamonds) |
| `iap.diamondPackLargeProductId` | `string` | `"com.brawlzone.diamonds_large"` | Cold | Store SKU for Large Pack (1,100 Diamonds) |
| `iap.diamondPackXlargeProductId` | `string` | `"com.brawlzone.diamonds_xlarge"` | Cold | Store SKU for XL Pack (2,400 Diamonds) |
| `iap.diamondPackMegaProductId` | `string` | `"com.brawlzone.diamonds_mega"` | Cold | Store SKU for Mega Pack (6,500 Diamonds) |
| `iap.playPassMonthlyProductId` | `string` | `"play_pass_monthly"` | Cold | Store SKU for monthly Play Pass |
| `iap.playPassWeeklyProductId` | `string` | `"play_pass_weekly"` | Cold | Store SKU for weekly Play Pass |
| `iap.starterPackProductId` | `string` | `"starter_pack_v1"` | Cold | Store SKU for Starter Pack |
| `iap.shopEnabled` | `boolean` | `false` | Cold | Master switch for IAP shop UI (gates entire shop tab) |

---

## 7. Tuning Knobs

All server-side constants live in `server/src/config/iap.ts`. All client-side constants live in `mobile/src/config/iap.ts`.

| Constant | Location | Default | Safe Range | Description |
|----------|----------|---------|------------|-------------|
| `PLAY_PASS_GRACE_PERIOD_DAYS` | server | `7` | `3` – `14` | Days of continued Play Pass access after a billing failure before entitlement is revoked. Increasing gives more recovery time but extends potential free access after non-payment. |
| `PLAY_PASS_MONTHLY_DIAMONDS` | server | `300` | `100` – `600` | Diamonds granted on each Play Pass monthly renewal. Increasing raises subscription value; decreasing may hurt retention. Changing this does not affect already-fulfilled renewals — only future renewals. |
| `PLAY_PASS_WEEKLY_DIAMONDS` | server | `80` | `25` – `150` | Diamonds granted on each Play Pass weekly renewal. |
| `PENDING_PURCHASE_EXPIRY_HOURS` | server | `72` | `24` – `168` | Hours before a Google Play pending transaction is marked `expired` without a follow-up `INITIAL_PURCHASE`. |
| `RECONCILIATION_LAG_HOURS` | server | `24` | `6` – `48` | Age of a `pending` transaction before the nightly reconciliation job re-checks it with RevenueCat. Lower values catch missed webhooks sooner but increase RevenueCat API load. |
| `MAX_FULFILLMENT_RETRIES` | server | `5` | `3` – `10` | Maximum job re-enqueue attempts for a failed fulfillment DB transaction before the job is dead-lettered. |
| `FULFILLMENT_RETRY_BASE_DELAY_MS` | server | `2000` | `500` – `10000` | Base delay (ms) for fulfillment retry backoff. Doubles on each attempt. |
| `FRAUD_FULFIL_WITHOUT_WEBHOOK_THRESHOLD` | server | `3` | `2` – `10` | Number of `fulfil_without_valid_webhook` events within 24 hours that triggers an account security flag. |
| `DEBT_REVIEW_THRESHOLD` | server | `3` | `2` – `10` | Number of `iap_debt_ledger` entries within 90 days that triggers a manual fraud review flag. |
| `FOREGROUND_ENTITLEMENT_CHECK_MS` | client | `300000` | `60000` – `1800000` | Minimum time (ms) between foreground resume Play Pass entitlement checks via `getCustomerInfo()`. Prevents hammering RevenueCat on rapid background/foreground switches. |
| `STARTER_PACK_DIAMONDS` | server | `400` | `100` – `800` | Diamonds included in the Starter Pack. Changing requires a corresponding store product update. |
| `STARTER_PACK_PRICE_USD` | remote config (display label only) | `"$1.99"` | — | Display label only; actual price is set in App Store Connect / Google Play Console. |

---

## 8. Acceptance Criteria

**AC-01: RevenueCat Sole IAP Layer**
Given any IAP-related file in `mobile/src/`. When a static analysis linter runs. Then zero imports of `StoreKit`, `SKPaymentQueue`, `SKProduct`, `BillingClient`, `PurchasesUpdatedListener`, or `com.android.billingclient` are found. All purchase calls go through `Purchases.*` from `react-native-purchases`.

**AC-02: RevenueCat Initialized With userId**
Given a player who has completed Authentication. When the app reaches the main menu. Then `Purchases.configure()` has been called with `appUserID` equal to the player's Supabase UUID. Calling `Purchases.getAppUserID()` returns the UUID.

**AC-03: Purchase Flow Fires Analytics Events**
Given a player who taps "Buy" on `shop_offer:diamonds_small`. When the purchase succeeds. Then three analytics events have been emitted in order: `IAP_PURCHASE_INITIATED` (before payment sheet), `IAP_PURCHASE_COMPLETED` (after server confirms fulfillment). If the purchase is cancelled, `IAP_PURCHASE_FAILED` is emitted with `failureReason: "user_cancelled"`.

**AC-04: Diamond Balance Updates After Purchase**
Given a player with `diamond_balance = 0`. When a `shop_offer:diamonds_small` purchase completes and the server fulfillment webhook is processed. Then `diamond_balance = 200` in the `player_profiles` table. The client UI reflects the new balance within 5 seconds of purchase confirmation without requiring a manual refresh.

**AC-05: Duplicate Webhook Is a No-Op**
Given a `INITIAL_PURCHASE` webhook for `transaction_id = "T1"` has already been fulfilled (`iap_transactions.status = 'fulfilled'`). When a second identical webhook with `transaction_id = "T1"` arrives. Then `diamond_balance` is not changed a second time. The `iap_transactions` row is unchanged. A log entry `"duplicate_webhook_ignored"` is present.

**AC-06: Starter Pack Shown Only Once**
Given a player with `starterPackPurchased = false`. When the Shop screen loads. Then the Starter Pack offer is displayed. Given a player with `starterPackPurchased = true`. When the Shop screen loads. Then the Starter Pack offer is not displayed. After a `starter_pack_v1` purchase is fulfilled server-side, `starterPackPurchased = true` in the player profile and the offer disappears immediately on next Shop screen load.

**AC-07: Play Pass Entitlement on Foreground Resume**
Given a player whose Play Pass subscription is active. When the app is backgrounded for more than `FOREGROUND_ENTITLEMENT_CHECK_MS` and then brought to the foreground. Then `Purchases.getCustomerInfo()` is called within 2 seconds of the foreground event. If `has_play_pass` status differs from the cached profile value, `GET /profile` is called and the UI is updated.

**AC-08: Play Pass Grace Period**
Given a Play Pass subscriber who receives a `BILLING_ISSUE` webhook. When 6 days have elapsed without a `RENEWAL`. Then `has_play_pass = true` and `has_no_ads = true` still hold in the player profile (grace period not yet expired). When 7 days have elapsed without renewal. Then `has_play_pass = false` and `has_no_ads = false`. An `IAP_SUBSCRIPTION_CHANGED` event with `eventType: "lapsed"` has been emitted.

**AC-09: Restore Purchases Shows Correct Toast**
Given a player with an active non-consumable character bundle previously purchased. When the player taps "Restore Purchases" in Settings on a new device. Then the character bundle entitlement is present in the player profile after restore completes. The toast "Purchases restored" is shown. If no purchaseable non-consumables are found, the toast "No purchases to restore" is shown.

**AC-10: Refund Does Not Drop Balance Below Zero**
Given a player who purchased `shop_offer:diamonds_small` (200 Diamonds granted) and has since spent 180 Diamonds (`diamond_balance = 20`). When a `REFUND` webhook arrives for that transaction. Then `diamond_balance = 0` (20 deducted; cannot go below 0). A `iap_debt_ledger` row records `debtDiamonds = 180` for that transaction. No error is surfaced to the player.

**AC-11: Server Rejects Fulfillment Without Valid Webhook**
Given a tampered `POST /v1/iap/fulfil` request for `transaction_id = "FAKE1"` arrives with a valid JWT but no corresponding fulfilled webhook. When the server processes the request. Then it returns `402 Payment Required` with `{ error: "purchase_not_validated" }`. No currency or entitlement is granted. A WARN log entry with `event: "fulfil_without_valid_webhook"` is present.

**AC-12: Webhook Signature Verification**
Given a POST arrives at `/v1/iap/webhook/revenuecat` with an invalid or missing `X-RevenueCat-Signature` header. When the server processes the request. Then it returns `401 Unauthorized`. No fulfillment processing occurs. No currency or entitlement is granted.

**AC-13: Google Play Pending Purchase Not Fulfilled Until Confirmed**
Given a `PENDING` RevenueCat event arrives for `transaction_id = "GP1"`. When the fulfillment worker processes it. Then an `iap_transactions` row with `status = 'pending'` is created. No Diamonds are granted. No entitlements are granted. When a subsequent `INITIAL_PURCHASE` event arrives for `transaction_id = "GP1"`. Then the row is updated to `status = 'fulfilled'` and currency/entitlement is granted.

**AC-14: Reconciliation Job Recovers Missed Webhooks**
Given a `iap_transactions` row with `status = 'pending'` and `received_at > 24 hours ago`. When the nightly reconciliation job runs at 02:00 UTC. Then the job calls RevenueCat's subscriber API for the associated `userId`. If RevenueCat reports the transaction as `INITIAL_PURCHASE` completed, the fulfillment pipeline runs and `status` becomes `'fulfilled'`. If RevenueCat still shows `PENDING`, the row remains `'pending'`.

**AC-15: PII Policy — No Payment Tokens in Logs**
Given any fulfillment, refund, or webhook processing event. When log output is captured across all log levels (DEBUG through FATAL). Then no log line contains a RevenueCat purchase token, an Apple receipt string, a Google Play purchase token, card number, or any string matching the pattern of a base64-encoded receipt. Only `transaction_id` (a non-PII string) appears in logs.

**AC-16: iap_transactions Audit Trail Completeness**
Given any successfully fulfilled purchase. When the `iap_transactions` table is queried for that `transaction_id`. Then a row exists with non-null values for: `transaction_id`, `user_id`, `product_id`, `product_type`, `event_type`, `store`, `received_at`, `fulfilled_at`, `status = 'fulfilled'`. No row has null `fulfilled_at` when `status = 'fulfilled'`.

**AC-17: Character Bundle Idempotent Grant**
Given a player who already owns `characterId = "character:colt"`. When a character bundle purchase for `character:colt` is fulfilled. Then the character is not duplicated in `unlocked_character_ids`. The exclusive skin is granted if not already owned. If the exclusive skin is already owned (restore scenario), the skin grant is also a no-op. No error is surfaced to the player.
