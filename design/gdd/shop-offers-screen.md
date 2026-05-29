# Shop & Offers Screen — Game Design Document

> **System**: Shop & Offers Screen
> **Priority**: Alpha
> **Layer**: Presentation
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

The Shop & Offers Screen is the primary monetisation surface in BRAWLZONE. It is a full-screen modal layered on top of the main lobby, organised into five navigable sections — **Diamond Packs**, **Characters**, **Skins**, **Play Pass**, and **Featured / Offers** — plus a stub **Battle Pass** section reserved for a future system. The screen reads all purchasable items from the Content Catalog, reflects real-time ownership state from the Inventory / Entitlements system, and routes every real-money transaction through the IAP System while routing every in-game-currency transaction through the Currency System ledger. Wallet balances (Coins and Diamonds) are always visible in the Shop header so players can make informed decisions without leaving the screen. Every purchase requires an explicit confirmation step to prevent accidental spending, and every purchased item is granted atomically — the player's inventory is updated before the UI reports success.

---

## 2. Player Fantasy

### 2.1 Excitement of Browsing

Opening the Shop feels like walking into an arcade gift shop after a great session: bright character art, animated skin previews, and a clear sense of progression. Players can instantly see which characters they are close to unlocking with Coins, tap any skin to see it in action on their chosen fighter, and explore rotating offers that feel hand-picked rather than algorithmic noise.

### 2.2 Genuine Urgency from Limited-Time Offers

Featured and limited-time deals carry live countdown timers that tick in real time. The timer is never manipulative — it reflects a genuine server-authoritative expiry. When an offer expires while the player has the Shop open, it transitions cleanly to an "Expired" state rather than disappearing abruptly, validating the player's sense of having witnessed a real event. Scarcity feels earned, not manufactured.

### 2.3 Trustworthy, Instant Purchase Feel

Every purchase shows a confirmation modal with the item name, the exact price, the current wallet balance, and the projected balance after the purchase — no hidden costs, no surprise deductions. After the player taps **Confirm Purchase**, the transaction completes within one network round-trip, the balance updates instantly in the header, and a brief celebratory animation plays on the newly owned item card. If something goes wrong the error message is plain-language and actionable (e.g., "Not enough Diamonds — get more here").

---

## 3. Detailed Rules

### 3.1 Screen Architecture

The Shop is a React Native modal (`ShopModal`) rendered above the lobby navigator. It is triggered by any "Open Shop" CTA in the game (lobby button, deep-link, Featured Offer notification tap).

On open the screen:
1. Fetches the active Content Catalog snapshot from the server (or returns the cached snapshot if the network is unavailable — see §5.6).
2. Fetches the player's current wallet balances and entitlement state from the Inventory / Entitlements service.
3. Renders the **Featured / Offers** tab as the default landing tab (configurable via Remote Config key `shop_default_tab`).
4. Displays skeleton screens in each tab while data is loading; never shows a blank section.

Navigation between sections is handled by a tab bar fixed at the top of the modal. Tab order (left to right):

| Index | Tab Label       | Remote Config visibility key          |
|-------|-----------------|---------------------------------------|
| 0     | Featured        | `shop_tab_featured_visible`           |
| 1     | Diamond Packs   | `shop_tab_diamond_packs_visible`      |
| 2     | Characters      | `shop_tab_characters_visible`         |
| 3     | Skins           | `shop_tab_skins_visible`              |
| 4     | Play Pass       | `shop_tab_play_pass_visible`          |
| 5     | Battle Pass     | always visible; content is a stub     |

A tab whose visibility key resolves to `false` is hidden entirely (tab button and content).

### 3.2 Header

The Shop header is a persistent strip at the very top of the modal, rendered above the tab bar, containing:

- **Coins balance** (coin icon + formatted integer, e.g. "1,240")
- **Diamonds balance** (diamond icon + formatted integer, e.g. "350")
- **Close button** (top-right X)

Balances are sourced from the Currency System wallet and re-fetched on every `profile:refresh` Socket.io event (see §5.1).

```typescript
interface ShopHeaderProps {
  coins: number;
  diamonds: number;
  onClose: () => void;
}
```

### 3.3 Diamond Packs Section

Displays all IAP Diamond pack tiers available in the current storefront. Pack data originates from the IAP System (which reads from Remote Config for pricing) and is presented in ascending value order.

#### 3.3.1 Pack Card Layout

Each pack card renders:
- Diamond icon + diamond quantity (large)
- USD price (as returned by the platform's IAP SDK, e.g. `$0.99`)
- **"Best Value"** badge on the tier with the highest diamonds-per-dollar ratio (see §4.3)
- **"Buy"** CTA button

Tapping **Buy** on a pack card opens the platform IAP purchase sheet (Apple StoreKit / Google Play Billing) via the IAP System. The Shop does not handle the payment itself — it is a trigger only.

#### 3.3.2 Default Pack Tiers

The following tiers are the design defaults. Actual prices and diamond quantities are Remote Config cold keys (`shop_diamond_packs`) and may differ per region.

| Tier ID         | Diamonds | USD Price (default) | Notes                          |
|-----------------|----------|---------------------|--------------------------------|
| `diamonds_sm`   | 80       | $0.99               |                                |
| `diamonds_md`   | 200      | $1.99               |                                |
| `diamonds_lg`   | 500      | $4.99               | Best Value (default config)    |
| `diamonds_xl`   | 1,100    | $9.99               |                                |
| `diamonds_xxl`  | 2,400    | $19.99              |                                |
| `diamonds_mega` | 6,500    | $49.99              |                                |

#### 3.3.3 IAP Pending State

If a Google Play pending transaction exists for a pack, that pack's card shows a **"Purchase Pending"** badge and the **Buy** button is disabled for that specific pack. Other packs remain purchasable.

### 3.4 Characters Section

Displays all 8 playable characters in a fixed order. Each character card shows:
- Character portrait (static image from asset bundle)
- Character name
- State badge + CTA (see §3.4.1)

#### 3.4.1 Character Card States

| Condition                             | Badge         | CTA                                   |
|---------------------------------------|---------------|---------------------------------------|
| Free character, not owned             | "Free"        | "Unlock" (no cost, calls `grantItem`) |
| Free character, owned                 | "Owned"       | None (card greyed out)                |
| Earnable character (Coin), not owned  | Coin icon + price | "Buy for X Coins"                 |
| Earnable character (Coin), owned      | "Owned"       | None (card greyed out)                |
| Premium character (Diamond), not owned | Diamond icon + price | "Buy for X Diamonds"          |
| Premium character (Diamond), owned    | "Owned"       | None (card greyed out)                |

#### 3.4.2 Character Roster & Costs

| Character | Type      | Currency | Cost  |
|-----------|-----------|----------|-------|
| Vex       | Free      | —        | 0     |
| Zook      | Free      | —        | 0     |
| Sera      | Free      | —        | 0     |
| Fen       | Earnable  | Coins    | 800   |
| Grim      | Earnable  | Coins    | 600   |
| Dash      | Earnable  | Coins    | 1,200 |
| Colt      | Premium   | Diamonds | 500   |
| Nyx       | Premium   | Diamonds | 500   |

Free characters that are not yet owned show an **"Unlock"** CTA. Tapping it calls `grantItem` directly (no currency deduction, no confirmation modal required) because the cost is zero. All other characters require a confirmation modal (§3.8).

#### 3.4.3 Owned Item Tap Behaviour

Tapping any "Owned" character card does not open a purchase flow. Instead it deep-links to the character selection / loadout screen so the player can immediately select or inspect that character.

### 3.5 Skins Section

Displays all skins defined in the Content Catalog, grouped by character. The section renders one collapsible character group per character. By default all groups are expanded.

#### 3.5.1 Filter Bar

A filter pill row at the top of the Skins section:

| Filter Pill | Behaviour                                        |
|-------------|--------------------------------------------------|
| All         | Show all skins (default)                         |
| Unowned     | Hide skins the player already owns               |
| Owned       | Show only skins the player owns                  |

#### 3.5.2 Skin Card

Each skin card renders:
- Thumbnail (small square crop of the character in that skin)
- Skin name
- Tier badge: Common / Rare / Epic / Legendary (coloured)
- Price badge: Diamond icon + price, OR "Owned" if already owned
- **"Preview"** button (always visible, even for owned skins)

Tapping **"Preview"** opens the Skin Detail View (§3.6). Tapping elsewhere on the card for an unowned skin also opens the Skin Detail View.

#### 3.5.3 Skin Pricing Tiers

| Tier       | Diamond Cost |
|------------|--------------|
| Common     | 100          |
| Rare       | 250          |
| Epic       | 500          |
| Legendary  | 1,000        |

### 3.6 Skin Detail View

A full-screen overlay (rendered above the Shop modal) showing:

1. **Character Preview Panel** — full-body character render with the selected skin applied. The asset is loaded from the local asset bundle (`assetBundleKey` from Content Catalog); no network call is made to display the preview.
2. **Skin Name & Tier** — large heading + tier badge.
3. **Price** — Diamond icon + price, or "Owned" badge.
4. **"Buy" CTA** (if unowned) — tapping opens the Purchase Confirmation Modal (§3.8).
5. **"Equip" CTA** (if owned) — tapping equips the skin and closes the overlay, navigating to the character loadout.
6. **"Back" button** — returns to the Skins section without any action.

The preview render is purely client-side. The asset bundle must contain the skin's idle/pose sprite before the skin is listed in the Content Catalog. No skeleton is shown in the preview panel — if the asset bundle key is missing, the preview panel shows the character's default skin with a "Preview unavailable" label.

### 3.7 Play Pass Section

The Play Pass is a recurring subscription purchased through the IAP System.

#### 3.7.1 Unsubscribed State

Displays:
- Monthly price (from Remote Config key `shop_play_pass_price_usd`, formatted as USD)
- Benefits list:
  - No ads
  - X Diamonds per month (Remote Config key `shop_play_pass_monthly_diamonds`, default: 300)
  - 1 exclusive cosmetic per month (details TBD at subscription fulfilment)
- **"Subscribe"** CTA — taps into the IAP subscription flow via the IAP System.

#### 3.7.2 Subscribed State

Displays:
- **"Active — expires [date]"** label, where `[date]` is the subscription's next renewal date pulled from the Inventory / Entitlements `has_play_pass` record (ISO 8601 date formatted as "MMM D, YYYY").
- The same benefits list (read-only, no CTA).
- **"Manage Subscription"** link that opens the platform's native subscription management screen (iOS: Settings → Subscriptions; Android: Google Play Subscriptions).

The **"Subscribe"** button is never shown when the player is already subscribed. There is no in-app cancel flow — subscription cancellation happens on the platform.

### 3.8 Purchase Confirmation Modal

Every currency purchase (Coin or Diamond) requires the player to pass through this modal before any transaction is submitted. It is a bottom sheet rendered above the Shop modal.

#### 3.8.1 Modal Content

```typescript
interface PurchaseConfirmationProps {
  itemName: string;           // e.g. "Nyx", "Grim's Ember Skin"
  itemThumbnail: ImageSource; // small square asset
  currency: 'Coins' | 'Diamonds';
  price: number;              // e.g. 500
  currentBalance: number;     // player's current balance in that currency
  postPurchaseBalance: number; // currentBalance - price
  onConfirm: () => void;
  onCancel: () => void;
}
```

The modal displays:
- Item thumbnail (left)
- Item name (large text)
- Currency icon + price
- "Your balance: X → Y" (current and post-purchase)
- **"Confirm Purchase"** button (primary, full-width)
- **"Cancel"** button (secondary, text only)

The **"Confirm Purchase"** button is disabled and replaced by a spinner while the transaction request is in-flight (preventing double-submission).

#### 3.8.2 Insufficient Funds Guard

Before opening the confirmation modal the client performs a pre-flight balance check:

- **Diamonds insufficient**: the confirmation modal is not opened. Instead, an inline alert appears on the item card with the message "You need X more Diamonds" and a **"Get Diamonds"** CTA that scrolls the tab bar to the Diamond Packs section and highlights it briefly.
- **Coins insufficient**: the confirmation modal is not opened. An inline alert shows "You need X more Coins". No deep-link to a Coin pack section (Coins are earnable, not purchasable); the alert dismisses after 3 seconds.

The pre-flight check uses the client-side cached balance. The server also validates balance atomically; if the server rejects the transaction due to a race-condition balance discrepancy, the failure is handled by the post-purchase error flow (§3.9.2).

### 3.9 Purchase Execution Flow

```
Player taps "Buy" / "Confirm Purchase"
        │
        ▼
Client sends POST /shop/purchase { itemId, currency, price, idempotencyKey }
        │
        ▼
Server: atomic balance deduction via Currency System ledger
        │
        ├─► Success ──► Server calls grantItem(playerId, itemId)
        │                       │
        │                       ▼
        │               Server emits `profile:refresh` on player's Socket.io channel
        │                       │
        │                       ▼
        │               Client re-fetches wallet + inventory
        │                       │
        │                       ▼
        │               UI updates: item card → "Owned", balance decremented
        │                       │
        │                       ▼
        │               Celebratory animation plays on item card
        │
        └─► Failure ──► Error modal shown (§3.9.2)
```

Each purchase request carries a client-generated UUID `idempotencyKey` so duplicate submissions (e.g., double-tap, network retry) are safely de-duplicated by the server.

#### 3.9.1 Analytics Events

| Event                  | Fired When                                                         |
|------------------------|--------------------------------------------------------------------|
| `shop_opened`          | Shop modal mounts                                                  |
| `item_viewed`          | Player views a Skin Detail View or spends ≥2 s on a character card |
| `purchase_initiated`   | Player taps "Buy" and passes insufficient-funds guard              |
| `purchase_completed`   | Server responds 200 to `/shop/purchase`                            |
| `purchase_failed`      | Server responds non-200 or network error on `/shop/purchase`       |

All events follow the schema defined in `analytics-telemetry.md`. PII handling follows `logging-monitoring.md` (no item prices or balance snapshots logged to external analytics in regions subject to privacy regulation).

#### 3.9.2 Purchase Failure Handling

If the server returns a non-200 response or the request times out:

| Error Code / Condition          | User-Facing Message                                               | Action                              |
|---------------------------------|-------------------------------------------------------------------|-------------------------------------|
| `INSUFFICIENT_BALANCE`          | "Not enough [Currency]. Get more here →"                         | CTA deep-links to Diamond Packs     |
| `ITEM_NOT_FOUND`                | "This item is no longer available."                               | Refresh Content Catalog             |
| `ITEM_ALREADY_OWNED`            | "You already own this item."                                      | Refresh inventory; show Owned state |
| `DUPLICATE_TRANSACTION`         | (silent) — idempotency key matched; treat as success              | Re-fetch profile                    |
| `SERVER_ERROR` / timeout        | "Something went wrong. Please try again."                         | Dismiss modal; no retry loop        |

### 3.10 Featured / Offers Section

The Featured section is the default landing tab. It renders up to `shop_featured_slots_max` (Remote Config, default 3) featured offer cards. The set of active featured slots is defined in Remote Config key `shop_featured_offers` as a JSON array.

#### 3.10.1 Offer Types

| Type             | Description                                                                                              |
|------------------|----------------------------------------------------------------------------------------------------------|
| `limited_time`   | Single item (skin or character) at standard or discounted price; carries `expiresAt` timestamp           |
| `bundle`         | Group of items (e.g., character + skin + Diamond bonus) sold as a package; carries `bundlePrice`         |
| `daily_deal`     | Rotates at midnight UTC; 24-hour countdown; single item at a discounted price                            |

#### 3.10.2 Featured Card Layout

Each featured card renders:
- Large hero image (sourced from Content Catalog `assetBundleKey`)
- Offer title (from Content Catalog)
- For `limited_time` and `daily_deal`: countdown timer formatted as "Xd Xh Xm" (see §4.1)
- For `bundle`: itemised contents list + individual prices + bundle price + discount percentage badge (see §4.2)
- Price CTA ("Buy for X Diamonds" or "Buy for X Coins")
- If already owned / expired: non-purchasable state (see §3.10.3)

#### 3.10.3 Offer States

| Condition                        | Display                                                             |
|----------------------------------|---------------------------------------------------------------------|
| Active, not owned                | Countdown (if applicable) + Buy CTA                                 |
| Active, fully owned              | "Owned" badge; no CTA; card slightly greyed                         |
| Expired (detected on resume)     | "Expired" label replaces countdown; card greyed; no CTA             |
| Out of stock (future use)        | "Sold Out" badge; no CTA                                            |

An expired offer card remains visible for the current session as a non-interactive tombstone; it is removed from the Featured section on the next Shop open.

### 3.11 Battle Pass Section (Stub)

The Battle Pass tab renders a single full-width card:

```
┌──────────────────────────────────────┐
│  ⚔  Battle Pass                      │
│                                      │
│  Coming Soon                         │
│  Stay tuned for seasonal rewards,    │
│  exclusive skins, and more.          │
└──────────────────────────────────────┘
```

No interactive elements. No purchase CTAs. This stub is replaced in its entirety when `battle-pass.md` is finalised and implemented.

### 3.12 Loading & Error States

| State                     | Display                                                                  |
|---------------------------|--------------------------------------------------------------------------|
| Initial load in progress  | Skeleton cards in each section; tab bar still interactive                |
| Section load failed       | Inline error banner per section: "Failed to load — Tap to retry"         |
| Full Shop load failed     | Full-screen error state with "Retry" button (Content Catalog unreachable)|
| Network offline, cached   | Content renders from cache; yellow banner: "Prices may be outdated"      |
| Item asset bundle missing | Card renders without image; "Preview unavailable" label in detail view   |

---

## 4. Formulas

### 4.1 Limited-Time Offer Countdown

```typescript
function getTimeRemaining(offerExpiresAt: number): string {
  const timeRemainingMs = offerExpiresAt - Date.now();

  if (timeRemainingMs <= 0) return 'Expired';

  const totalSeconds = Math.floor(timeRemainingMs / 1000);
  const days    = Math.floor(totalSeconds / 86400);
  const hours   = Math.floor((totalSeconds % 86400) / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);

  if (days > 0)  return `${days}d ${hours}h ${minutes}m`;
  if (hours > 0) return `${hours}h ${minutes}m`;
  return `${minutes}m`;
}
```

**Example**: `offerExpiresAt = 1748476800000` (some future epoch), `Date.now() = 1748390400000`  
`timeRemainingMs = 86,400,000` → `totalSeconds = 86,400` → `days = 1, hours = 0, minutes = 0` → display **"1d 0h 0m"**

The countdown re-renders on a 60-second interval (`setInterval`, 60,000 ms). Sub-minute precision is not displayed to avoid visual noise.

### 4.2 Bundle Discount Percentage

```typescript
function getBundleDiscountPct(bundlePrice: number, itemPrices: number[]): number {
  const sumOfIndividualPrices = itemPrices.reduce((acc, p) => acc + p, 0);
  return Math.round((1 - bundlePrice / sumOfIndividualPrices) * 100);
}
```

**Example**: A bundle contains Nyx (500 Diamonds) + Nyx's Legendary skin (1,000 Diamonds) + 200 bonus Diamonds (200 Diamonds face value).  
`sumOfIndividualPrices = 500 + 1,000 + 200 = 1,700`  
`bundlePrice = 1,200`  
`discountPct = Math.round((1 - 1200 / 1700) × 100) = Math.round(29.41) = 29`  
Display: **"Save 29%"** badge.

A bundle discount badge is only shown when `discountPct >= 5`. Bundles with a smaller computed discount show no badge (they may still be valid bundles with non-monetary value e.g., convenience).

### 4.3 Best Value Diamond Pack Detection

```typescript
function getBestValuePack(packs: DiamondPack[]): string {
  // diamondsPerCent = diamonds / (usdCents)
  const rated = packs.map(p => ({
    tierId: p.tierId,
    ratio: p.diamonds / p.usdCents,
  }));
  rated.sort((a, b) => b.ratio - a.ratio);
  return rated[0].tierId;
}
```

**Example** using the default tier table:

| Tier ID         | Diamonds | USD Cents | Diamonds/Cent |
|-----------------|----------|-----------|---------------|
| `diamonds_sm`   | 80       | 99        | 0.808         |
| `diamonds_md`   | 200      | 199       | 1.005         |
| `diamonds_lg`   | 500      | 499       | 1.002         |
| `diamonds_xl`   | 1,100    | 999       | 1.101         |
| `diamonds_xxl`  | 2,400    | 1,999     | 1.201         |
| `diamonds_mega` | 6,500    | 4,999     | 1.300         |

`diamonds_mega` has the highest ratio (1.300) → **"Best Value"** badge applied to `diamonds_mega`.

The "Best Value" badge is computed client-side at render time using IAP SDK-returned prices (converted to cents). Only one pack receives the badge.

---

## 5. Edge Cases

### 5.1 Purchase Succeeds but Client Balance Is Stale

**Scenario**: The server deducts currency and grants the item, but the client's cached wallet does not reflect the deduction (e.g., the socket event was delayed or the app was backgrounded).

**Resolution**: The server emits a `profile:refresh` event on the player's Socket.io channel after every successful `grantItem` call. The Shop's `useWallet` hook subscribes to this event and re-fetches the wallet snapshot from `/profile/wallet` on receipt. The header balance and all item card states are updated from the fresh snapshot. The player cannot end up in a state where an item is marked Owned but the balance still appears as though the deduction has not occurred, because both ownership and balance come from the same re-fetch.

### 5.2 Limited-Time Offer Expires While Shop Is Open

**Scenario**: A player opens the Shop, navigates to another tab, and returns to Featured after the `expiresAt` timestamp has elapsed.

**Resolution**:
- The countdown timer function returns `"Expired"` when `timeRemainingMs <= 0` (§4.1).
- On app foreground resume (`AppState.change` → `'active'`), the Featured section calls `refreshFeaturedOffers()`, which re-fetches the active offer list from Remote Config. Any offer whose `expiresAt` is in the past is returned with `status: 'expired'` by the server.
- The expired card transitions to the "Expired" state (greyed, no CTA, "Expired" label). It is not removed mid-session to avoid a jarring layout shift.
- If the countdown timer hits zero while the player is actively watching it, the card transitions immediately to the Expired state without waiting for the next foreground resume event.

### 5.3 Player Taps Buy on a Skin Their Opponent Is Wearing Mid-Match

**Scenario**: A player opens the Shop from the pause / background state during a match and attempts to purchase a skin that a visible opponent is currently wearing.

**Resolution**: The Shop is an isolated presentation layer. It has no knowledge of the current match state. The purchase proceeds through the normal flow (confirmation modal → server transaction → `grantItem` → `profile:refresh`). The match is unaffected. The purchased skin is available for the player to equip in their next match.

### 5.4 IAP Purchase Pending (Google Play Deferred Transaction)

**Scenario**: A player purchases a Diamond pack on Android via a payment method that results in a Google Play "pending" status (e.g., cash payment at a kiosk, family approval pending).

**Resolution**:
- The IAP System notifies the Shop via callback with status `'pending'`.
- The specific Diamond pack card for that pending purchase shows a **"Purchase Pending"** badge and its **Buy** button is disabled.
- All other Diamond packs remain fully purchasable.
- No Diamonds are credited until the IAP System receives a `PURCHASED` confirmation from Google Play's server-to-server notification.
- If the player re-opens the Shop before the pending transaction resolves, the badge is restored from local IAP state.
- Pending state persists across app restarts.

### 5.5 Content Catalog Item Delisted While Shop Is Open

**Scenario**: An item is removed from the Content Catalog by an operator (e.g., a skin is pulled due to a bug) while a player has the Shop open with that item already rendered on screen.

**Resolution**:
- The already-rendered item card remains visible for the rest of the current Shop session. The client will not crash or blank the section because it is displaying a snapshot taken at Shop open time.
- The item is safe to display because delisting does not retroactively modify asset bundles already present on the device.
- If the player attempts to purchase the delisted item, the server returns `ITEM_NOT_FOUND`. The client shows the error message "This item is no longer available." and refreshes the Content Catalog snapshot, causing the item to disappear from the section on the next render cycle.
- On the next Shop open (after close and reopen), the item will not appear.

### 5.6 Insufficient Network — Shop Fails to Load Content Catalog

**Scenario**: The player opens the Shop with no or degraded network connectivity and the Content Catalog fetch fails.

**Resolution**:
- The client attempts the Content Catalog fetch with a 10-second timeout (Remote Config key `shop_catalog_fetch_timeout_ms`, default 10,000).
- On failure, the client loads the last successfully cached Content Catalog snapshot (stored in AsyncStorage, keyed by `content_catalog_v{version}`).
- A persistent yellow banner at the top of the Shop (below the header) reads: **"Prices may be outdated. Connect to the internet for the latest offers."**
- If no cached snapshot exists (first-ever open, cache cleared), the full-screen error state is shown with a **"Retry"** button. No content is displayed.
- Purchase attempts while offline will fail at the network layer; the server error handler returns a plain-language message prompting the player to check their connection.

---

## 6. Dependencies

### 6.1 Upstream (systems the Shop reads from or triggers)

| System                          | File                          | What Shop Uses                                                                          |
|---------------------------------|-------------------------------|-----------------------------------------------------------------------------------------|
| Content Catalog                 | `content-catalog.md`          | Item ids, types, costs, availability windows, `assetBundleKey`s; source of truth for what to display |
| Currency System                 | `currency-system.md`          | Wallet balances (Coins + Diamonds) displayed in header; atomic spend on purchase        |
| IAP System                      | `iap-system.md`               | Diamond pack tiers + USD prices; triggers platform purchase sheets; Play Pass subscription flow; pending transaction state |
| Cosmetic / Skin System          | `cosmetic-skin.md`            | Skin data model (id, tier, characterId, assetBundleKey); used to render skin cards and preview |
| Inventory / Entitlements        | `inventory-entitlements.md`   | Character + skin ownership (Owned vs. purchasable); `has_play_pass` flag; `grantItem` write path |
| Remote Config                   | `remote-config.md`            | Tab visibility, featured offer slots, offer windows, Diamond pack tiers, Play Pass price, countdown timers |
| Analytics / Telemetry           | `analytics-telemetry.md`      | `shop_opened`, `item_viewed`, `purchase_initiated`, `purchase_completed`, `purchase_failed` events |
| Logging / Monitoring            | `logging-monitoring.md`       | ILogger interface; PII policy for purchase events                                       |

### 6.2 Downstream (systems the Shop writes to or navigates to)

| System / Screen                 | Interaction                                                                              |
|---------------------------------|------------------------------------------------------------------------------------------|
| Inventory / Entitlements        | `grantItem(playerId, itemId)` called by server after successful purchase                 |
| Currency System                 | Balance deduction via ledger on every Coin or Diamond purchase                           |
| IAP System                      | Triggers IAP purchase sheet; receives purchase/pending/failed callbacks                  |
| Character Loadout Screen        | Deep-linked from Owned character card tap and Equip CTA in Skin Detail View              |
| Battle Pass System              | Tab stub; full integration deferred to `battle-pass.md`                                  |

### 6.3 Socket.io Events

| Event            | Direction       | Purpose                                      |
|------------------|-----------------|----------------------------------------------|
| `profile:refresh`| Server → Client | Triggers wallet + inventory re-fetch in Shop |

---

## 7. Tuning Knobs

All Remote Config keys below are **cold keys** (read once at Shop open, not live-updated while Shop is open). Exceptions are noted.

### 7.1 Feature Flags

| Remote Config Key                  | Type    | Default | Safe Range  | Notes                                                         |
|------------------------------------|---------|---------|-------------|---------------------------------------------------------------|
| `shop_tab_featured_visible`        | boolean | `true`  | —           | Hides Featured tab entirely if `false`                        |
| `shop_tab_diamond_packs_visible`   | boolean | `true`  | —           |                                                               |
| `shop_tab_characters_visible`      | boolean | `true`  | —           |                                                               |
| `shop_tab_skins_visible`           | boolean | `true`  | —           |                                                               |
| `shop_tab_play_pass_visible`       | boolean | `true`  | —           |                                                               |
| `shop_default_tab`                 | string  | `"featured"` | One of the tab ids | Tab displayed on Shop open                       |

### 7.2 Diamond Packs

| Remote Config Key       | Type   | Default               | Safe Range    | Notes                                    |
|-------------------------|--------|-----------------------|---------------|------------------------------------------|
| `shop_diamond_packs`    | JSON   | See §3.3.2            | —             | Array of `{ tierId, diamonds, usdCents }` objects |

### 7.3 Featured / Offers

| Remote Config Key              | Type    | Default | Safe Range | Notes                                                |
|--------------------------------|---------|---------|------------|------------------------------------------------------|
| `shop_featured_offers`         | JSON    | `[]`    | —          | Array of offer objects; max length capped at `shop_featured_slots_max` |
| `shop_featured_slots_max`      | integer | `3`     | 1 – 6      | Maximum featured cards rendered                      |
| `shop_bundle_discount_min_pct` | integer | `5`     | 1 – 50     | Minimum computed discount to show a "Save X%" badge  |

### 7.4 Play Pass

| Remote Config Key                   | Type    | Default  | Safe Range     | Notes                                           |
|-------------------------------------|---------|----------|----------------|-------------------------------------------------|
| `shop_play_pass_price_usd`          | string  | `"$4.99"`| Valid USD price| Display string; actual charge comes from IAP SKU|
| `shop_play_pass_monthly_diamonds`   | integer | `300`    | 50 – 2,000     | Diamonds listed in benefits                     |

### 7.5 Networking & UX

| Remote Config Key                   | Type    | Default  | Safe Range      | Notes                                             |
|-------------------------------------|---------|----------|-----------------|---------------------------------------------------|
| `shop_catalog_fetch_timeout_ms`     | integer | `10000`  | 3,000 – 30,000  | Content Catalog HTTP request timeout (ms)         |
| `shop_countdown_refresh_interval_ms`| integer | `60000`  | 10,000 – 60,000 | How often countdown timers re-render (ms)         |
| `shop_insufficient_coin_alert_ttl_ms`| integer | `3000`  | 1,000 – 10,000  | Duration of Coins-insufficient inline alert (ms)  |

### 7.6 Character & Skin Costs

Character and skin costs are defined in the Content Catalog (`content-catalog.md`) and are not duplicated in Remote Config. They are not tunable at runtime without a Content Catalog publish.

| Item         | Currency | Cost (design default) |
|--------------|----------|-----------------------|
| Grim         | Coins    | 600                   |
| Fen          | Coins    | 800                   |
| Dash         | Coins    | 1,200                 |
| Colt         | Diamonds | 500                   |
| Nyx          | Diamonds | 500                   |
| Common Skin  | Diamonds | 100                   |
| Rare Skin    | Diamonds | 250                   |
| Epic Skin    | Diamonds | 500                   |
| Legendary Skin | Diamonds | 1,000               |

---

## 8. Acceptance Criteria

### 8.1 Screen & Navigation

**AC-01** — Tapping the "Shop" button in the lobby opens the Shop modal with the Featured tab selected (or the tab specified by `shop_default_tab`).

**AC-02** — The header displays the player's current Coin and Diamond balances on open, and the values match the Currency System wallet.

**AC-03** — Each tab in the tab bar navigates to its corresponding section without full re-render of sibling tabs.

**AC-04** — A tab whose Remote Config visibility key is `false` is not visible in the tab bar and its content is not accessible.

**AC-05** — Tapping the Close (X) button dismisses the Shop modal and returns focus to the lobby without navigation side effects.

### 8.2 Loading States

**AC-06** — While the Content Catalog is loading, each section renders skeleton placeholder cards. No section is blank.

**AC-07** — If the Content Catalog fetch fails and a cached snapshot exists, the Shop renders cached content with a "Prices may be outdated" banner.

**AC-08** — If the Content Catalog fetch fails and no cached snapshot exists, a full-screen error state with a "Retry" button is shown. No item content is visible.

### 8.3 Diamond Packs

**AC-09** — All Diamond pack tiers defined in `shop_diamond_packs` Remote Config are displayed in ascending diamond-quantity order.

**AC-10** — Exactly one pack card carries the "Best Value" badge, determined by the highest diamonds-per-cent ratio (§4.3).

**AC-11** — Tapping a pack's "Buy" button invokes the platform IAP purchase sheet and does not deduct Diamonds from the wallet (Diamonds are credited by the IAP System on purchase confirmation).

**AC-12** — A pack with a pending Google Play transaction shows a "Purchase Pending" badge and a disabled Buy button; all other packs remain purchasable.

### 8.4 Characters

**AC-13** — All 8 characters appear in the Characters section.

**AC-14** — Vex, Zook, and Sera each show a "Free" badge and an "Unlock" CTA when not owned. Tapping "Unlock" calls `grantItem` immediately, with no confirmation modal.

**AC-15** — Fen (800 Coins), Grim (600 Coins), and Dash (1,200 Coins) show the correct Coin price and "Buy for X Coins" CTA when not owned.

**AC-16** — Colt and Nyx each show 500 Diamonds and a "Buy for X Diamonds" CTA when not owned.

**AC-17** — Any owned character shows an "Owned" badge with no purchase CTA. Tapping the card navigates to character selection / loadout.

**AC-18** — Attempting to buy an earnable character when the player has insufficient Coins shows the inline Coins-insufficient alert (not the confirmation modal).

### 8.5 Skins

**AC-19** — The Skins section renders all skins from the Content Catalog, grouped by character.

**AC-20** — The "All / Unowned / Owned" filter pills correctly show and hide skin cards matching their condition.

**AC-21** — Tapping "Preview" on any skin card opens the Skin Detail View. The preview asset loads from the local bundle (no network spinner is shown for the character render).

**AC-22** — The Skin Detail View shows an "Equip" CTA for owned skins and a "Buy" CTA for unowned skins.

**AC-23** — If the skin's `assetBundleKey` is not present in the local bundle, the preview panel shows the character's default skin art and the label "Preview unavailable".

### 8.6 Play Pass

**AC-24** — An unsubscribed player sees the Play Pass monthly price, the full benefits list, and a "Subscribe" CTA.

**AC-25** — Tapping "Subscribe" invokes the IAP subscription flow via the IAP System.

**AC-26** — A subscribed player (has `has_play_pass = true`) sees "Active — expires [date]", the benefits list (read-only), and a "Manage Subscription" link. The "Subscribe" button is not visible.

**AC-27** — The "Manage Subscription" link opens the platform's native subscription management screen.

### 8.7 Featured / Offers

**AC-28** — The Featured section displays at most `shop_featured_slots_max` cards.

**AC-29** — A limited-time offer card shows a countdown in "Xd Xh Xm" format (§4.1). The timer updates on the `shop_countdown_refresh_interval_ms` interval.

**AC-30** — A bundle offer card displays: all included items, individual prices, bundle price, and the computed "Save X%" badge (only when `discountPct >= shop_bundle_discount_min_pct`).

**AC-31** — When a limited-time offer's countdown reaches zero while the player is viewing it, the card immediately transitions to the Expired state (greyed, "Expired" label, no CTA) without requiring a navigation gesture.

**AC-32** — On app foreground resume, the Featured section re-fetches the active offer list. Offers that have expired server-side display as "Expired".

### 8.8 Purchase Confirmation

**AC-33** — Tapping "Buy" on any item whose cost is > 0 opens the Purchase Confirmation Modal showing the item name, thumbnail, price, current balance, and projected post-purchase balance. The modal does not open for free items (Unlock flow, §3.4.1).

**AC-34** — The "Confirm Purchase" button is disabled and shows a spinner while the transaction request is in-flight.

**AC-35** — After a successful purchase: the wallet balance in the header decrements by the purchase price, the item card transitions to "Owned", and a celebratory animation plays.

**AC-36** — After a failed purchase with error code `INSUFFICIENT_BALANCE` for Diamonds: an inline "Get Diamonds" CTA deep-links to the Diamond Packs section.

**AC-37** — After a failed purchase with server error `ITEM_NOT_FOUND`: the error message "This item is no longer available." is shown, and the Content Catalog is refreshed.

**AC-38** — A purchase request carrying a duplicate `idempotencyKey` (double-tap scenario) is silently de-duplicated by the server; the client treats the response as a success and re-fetches the profile.

### 8.9 Battle Pass

**AC-39** — The Battle Pass tab is always visible in the tab bar.

**AC-40** — The Battle Pass tab content renders only the "Coming Soon" stub card described in §3.11. No purchase CTAs, no interactive elements.

### 8.10 Analytics

**AC-41** — `shop_opened` fires exactly once per Shop modal mount.

**AC-42** — `purchase_initiated` fires when the player taps "Buy" and passes the insufficient-funds guard (i.e., the confirmation modal opens).

**AC-43** — `purchase_completed` fires on server 200 response; `purchase_failed` fires on non-200 or network timeout. Both events are never fired for the same transaction.

### 8.11 Data Integrity

**AC-44** — Wallet balance and item ownership state are always sourced from the same `/profile` re-fetch triggered by `profile:refresh`. They are never stale relative to each other after a successful purchase.

**AC-45** — No purchase is processed without an explicit "Confirm Purchase" tap. Tap-to-buy (bypassing confirmation) is not possible.
