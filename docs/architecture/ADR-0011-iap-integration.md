# ADR-0011: IAP Integration (RevenueCat Webhooks + Fulfillment Chain)

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Security Engineer

## Summary

BRAWLZONE uses RevenueCat as the IAP abstraction layer for both iOS App Store and Google Play. The client initiates purchases via `react-native-purchases`; RevenueCat validates receipts and delivers server-to-server webhook events to `POST /v1/iap/webhook`. The server fulfills entitlements atomically using the idempotency pattern from ADR-0008. Clients never self-grant; all fulfillment is server-authoritative.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core / Networking |
| **Knowledge Risk** | LOW — RevenueCat SDK and webhook patterns are within training data |
| **References Consulted** | `design/gdd/iap-system.md`, `design/gdd/purchase-fulfillment.md`, `design/gdd/inventory-entitlements.md`, `design/gdd/currency-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm RevenueCat webhook signature header name and HMAC algorithm (currently `X-RevenueCat-Signature` with SHA-256 HMAC) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0004 (userId linking), ADR-0005 (PostgreSQL), ADR-0008 (idempotency + atomic grants) |
| **Enables** | Shop Offers Screen implementation, Play Pass subscription gating |
| **Blocks** | IAP system, Purchase Fulfillment, Cosmetic/Skin unlock via purchase |
| **Ordering Note** | Must be Accepted before any IAP-related server handler is written |

## Context

### Problem Statement

Mobile IAP is complex: two storefronts (App Store + Play), different receipt formats, potential duplicate webhook delivery from RevenueCat, and the risk that a client grant (client-side trust) would be exploitable. All fulfillment must be server-authoritative and idempotent.

### Current State

No IAP implementation. `react-native-purchases` is listed as a dependency in the engine reference.

### Constraints

- Client never grants itself diamonds or items — RevenueCat webhook is the only fulfillment trigger
- RevenueCat may retry webhook delivery if the server returns a non-2xx response
- Webhook signature must be validated before processing (prevents unauthorized grants)
- UserId must be set as the RevenueCat App User ID at purchase time for server-side user identification
- Play Pass (subscription) and Diamond packs (consumables) require different fulfillment paths

### Requirements

- Client: `Purchases.purchase(packageIdentifier)` → RevenueCat receipt validation
- Server: `POST /v1/iap/webhook` receives `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION` events
- Webhook signature validation: HMAC-SHA256 against webhook body using RevenueCat webhook secret
- `INITIAL_PURCHASE` / `RENEWAL`: fulfill entitlements atomically
- `CANCELLATION` (Play Pass): set `has_play_pass = false`; suppress ads on client via `profile:refresh`
- All fulfillment uses idempotency key = RevenueCat `event_id`

## Decision

RevenueCat handles all receipt validation. The server receives webhook events, validates the signature, and calls `PurchaseFulfillment.fulfill(event)` which runs an atomic PostgreSQL transaction using the event's `id` as idempotency key.

### Architecture

```
CLIENT                   REVENUE_CAT SDK         REVENUECAT CLOUD         SERVER
  │ tap "Buy Diamonds"       │                          │                    │
  ├──Purchases.purchase()───→│                          │                    │
  │                          │←── receipt validated ────│                    │
  │ (client shows loading)   │                          │                    │
  │                          │                          ├── INITIAL_PURCHASE─→│
  │                          │                          │   webhook (HMAC)    │
  │                          │                          │                    │ 1. Validate HMAC
  │                          │                          │                    │ 2. Parse event_id, userId, productId
  │                          │                          │                    │ 3. PurchaseFulfillment.fulfill()
  │                          │                          │                    │    BEGIN
  │                          │                          │                    │    creditDiamonds(+50, key=event_id+':d')
  │                          │                          │                    │    grantItem('character:colt', key=event_id+':c')
  │                          │                          │                    │    COMMIT
  │                          │                          │                    │ 4. Redis DEL profile:userId
  │                          │                          │                    │ 5. emit profile:refresh
  │←── profile:refresh (socket) ───────────────────────────────────────────│
  │ Profile Store invalidated → UI shows new diamond count + character
  │
  │ [RevenueCat retries webhook if server returned error]
  │                          │                          ├── INITIAL_PURCHASE─→│ (duplicate)
  │                          │                          │   (same event_id)   │ ON CONFLICT DO NOTHING → return 200
```

### Key Interfaces

```typescript
// Server: Webhook handler
app.post('/v1/iap/webhook', rawBodyMiddleware, async (req, res) => {
  const signature = req.headers['x-revenuecat-signature'];
  if (!verifyRevenueCatSignature(req.rawBody, signature, WEBHOOK_SECRET)) {
    return res.status(401).end();
  }
  const event = req.body as RevenueCatWebhookEvent;
  await PurchaseFulfillment.fulfill(event);
  res.status(200).end();
  // Always return 200 on successful processing (even if idempotent no-op)
  // Return 5xx to trigger RevenueCat retry
});

interface PurchaseFulfillment {
  fulfill(event: RevenueCatWebhookEvent): Promise<void>;
}

interface RevenueCatWebhookEvent {
  type: 'INITIAL_PURCHASE' | 'RENEWAL' | 'CANCELLATION' | 'EXPIRATION' | ...;
  id: string;           // idempotency key
  app_user_id: string;  // = userId (set at SDK init time)
  product_id: string;   // e.g. 'diamond_pack_sm', 'play_pass_monthly'
  store: 'APP_STORE' | 'PLAY_STORE';
}

// Client: SDK initialization (must run before any purchase attempt)
await Purchases.configure({ apiKey: REVENUECAT_PUBLIC_KEY });
await Purchases.logIn(userId);  // links RevenueCat app_user_id to our userId
```

### Implementation Guidelines

- `rawBodyMiddleware`: must capture raw request body before JSON parsing — HMAC validation requires raw bytes
- `app_user_id` in the webhook event is the player's `userId` (UUID) — set via `Purchases.logIn(userId)` at app startup after auth
- Product ID → fulfillment mapping is in `content-catalog.json` under `type: 'iap_pack'`; lookup via `catalog.get('iap_pack:{slug}')`
- Play Pass: `grantItem('entitlement:play_pass', ...)` + `UPDATE player_profiles SET has_play_pass=true`; on CANCELLATION: `UPDATE SET has_play_pass=false`
- Consumable diamond packs: credit diamonds + grant any included character/skin items
- RevenueCat `RENEWAL` for subscriptions: same as `INITIAL_PURCHASE` — idempotency key prevents double-grant on overlapping events
- Never trust client-supplied purchase confirmation — always wait for the webhook

## Alternatives Considered

### Alternative 1: Direct Receipt Validation (No RevenueCat)

- **Description**: Server calls Apple/Google receipt validation APIs directly.
- **Pros**: No RevenueCat vendor dependency; lower ongoing cost.
- **Cons**: Two separate validation APIs (App Store + Play) with different response formats; server-side subscription status tracking; webhook handling still required for renewals.
- **Rejection Reason**: RevenueCat normalizes both storefronts and provides reliable webhook delivery; the engineering cost of direct validation exceeds RevenueCat fees at MVP scale.

### Alternative 2: Client-Side Fulfillment (Trust Client)

- **Description**: Client receives RevenueCat entitlement confirmation and calls a server endpoint to self-grant.
- **Pros**: Simpler — no webhook infrastructure needed.
- **Cons**: Trivially exploitable — any player could fake a self-grant call.
- **Rejection Reason**: Architecture Principle 1 (server authoritative) eliminates client self-grant.

## Consequences

### Positive

- RevenueCat handles App Store + Play Store differences; server only sees normalized events
- Webhook idempotency via `event_id` means RevenueCat retries are safe
- Client never holds entitlement trust — no grant exploit surface

### Negative

- RevenueCat is a vendor dependency; if RevenueCat is down, new purchases cannot be fulfilled (purchases succeed on the store side, but entitlements are delayed until webhook delivery resumes)
- `rawBodyMiddleware` must come before Express JSON middleware on this route specifically

### Neutral

- Play Pass cancellation is handled via `CANCELLATION` event; AdMob re-enables transparently via `profile:refresh` → client checks `has_play_pass` flag

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| RevenueCat webhook delivery outage | Low | High | RevenueCat queues webhooks and retries; monitor RevenueCat status page |
| Wrong userId in `app_user_id` | Low | High | Call `Purchases.logIn(userId)` immediately after auth; verify `app_user_id` in webhook matches expected UUID format |
| Signature validation rejects valid webhook | Low | Medium | Log raw body + signature on validation failure; test in staging with RevenueCat sandbox |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Webhook processing time | — | ≤200ms | 500ms |
| Time from purchase to entitlement (client visible) | — | 2–10s (RevenueCat delivery latency) | — |

## Migration Plan

New project.

**Rollback plan**: Replace RevenueCat with direct App Store/Play validation — requires implementing two receipt validation APIs but the `PurchaseFulfillment.fulfill()` interface is unchanged.

## Validation Criteria

- [ ] Purchase with `diamond_pack_sm` → `profile:refresh` shows +50 diamonds within 10 seconds
- [ ] Duplicate webhook event (same `event_id`) → balance unchanged; server returns 200
- [ ] Invalid HMAC signature → server returns 401; nothing fulfilled
- [ ] Play Pass `CANCELLATION` → `has_play_pass = false`; AdMob shows on next app open
- [ ] `Purchases.logIn(userId)` called before any purchase; `app_user_id` in webhook matches userId

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/iap-system.md` | IAP | RevenueCat for both storefronts | RevenueCat SDK + webhook receiver defined |
| `design/gdd/purchase-fulfillment.md` | Fulfillment | Atomic fulfillment chain | Single pg transaction using event_id as idempotency key |
| `design/gdd/currency-system.md` | Currency | Diamonds credited server-side | `creditDiamonds()` called in webhook handler |
| `design/gdd/inventory-entitlements.md` | Inventory | Character/skin grants on purchase | `grantItem()` called with idempotency key |

## Related

- ADR-0004: `userId` = RevenueCat `app_user_id`; set via `Purchases.logIn(userId)`
- ADR-0008: Idempotency pattern used for all fulfillment writes
- ADR-0005: `entitlements` and `transactions` tables store fulfillment records
