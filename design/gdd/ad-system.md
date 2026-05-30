# Ad System — Game Design Document

> **System**: Ad System
> **Priority**: Alpha
> **Layer**: Monetization
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

The Ad System manages AdMob ad delivery for BRAWLZONE's free player base. It presents exactly two ad formats — **Rewarded Video** (player-initiated; grants Coins on completion) and **Interstitial** (automatic; shown at natural break points between matches) — and enforces a strict suppression contract: any player with an active Play Pass subscription (`has_play_pass = true`) or a one-time "Remove Ads" entitlement (`has_no_ads = true`) generates zero ad impressions, zero ad requests, and sees no ad-related UI. Eligibility is checked server-side at each ad trigger point; the client reads the fast-path denormalized flag from Player Profile before making any AdMob SDK call, ensuring no ad is ever initialized for a subscriber. Rewarded ad coin grants flow through the Currency System's `REWARDED_AD_COIN_GRANT` ledger source, are subject to a daily per-player cap enforced server-side, and reset at UTC midnight. Interstitial frequency is governed by a match-count cooldown from Remote Config. GDPR/consent is handled by the AdMob User Messaging Platform (UMP) SDK — a consent layer entirely separate from the game's analytics consent. All ad lifecycle events (`ad_shown`, `ad_completed`, `ad_reward_granted`, `ad_skipped`, `ad_failed`) are emitted as Tier 0 analytics events for monetization reporting.

---

## 2. Player Fantasy

### Free Players: Ads as a Fair Trade

A free player who has been playing for ten minutes knows the deal: BRAWLZONE is free because ads exist. The contract feels fair when ads are confined to natural pauses — the dead air between leaving a results screen and arriving back at the main menu — and never interrupt the match itself or the moment of choosing a new character. When an interstitial appears, it is brief and skippable; the player is not punished for dismissing it. The trade feels like: *I watched a short ad, and I kept playing.*

Rewarded ads feel like discovering a bonus, not enduring a tax. The "Watch Ad" button sits in a visible but non-intrusive spot on the results screen and on the main menu. A player who wants to grind Coins faster has the option. A player who never wants to see another ad can buy Play Pass. Both paths are clearly available, and neither path blocks the other.

### Rewarded Ads: A Bonus, Not a Forced Gate

When a player taps "Watch Ad," they have made an active choice. The reward — a flat Coin grant — is shown before they commit: "Watch a short ad for 15 Coins." There is no ambiguity about what they will receive. After completion, the Coin animation fires on the results screen immediately, tied to the same satisfying feedback beat as match rewards. The reward feels earned, not like a grudging payout for enduring an interruption.

The daily cap on rewarded ads is communicated through the UI: once a player has reached the cap, the "Watch Ad" button is replaced by a "Come back tomorrow" message. The player is never left wondering why the button disappeared.

### Play Pass Subscribers: Ads Cease to Exist

A subscriber who purchases Play Pass and immediately queues for their next match will never see an interstitial again — not during that session, not on any future session, not unless they cancel and their entitlement expires. The suppression is total: no ad is loaded, no ad request is made, no ad-related UI element is rendered. Play Pass subscribers should forget that ads are a thing. The transition from free to subscribed should feel like lifting a gentle weight they had stopped noticing — an absence of something that was always slightly there.

---

## 3. Detailed Rules

### 3.1 Ad Eligibility Check

Before any ad request is made — whether for an interstitial or a rewarded video — the system performs a **dual-layer eligibility check**:

**Client-side fast path (before SDK call):**

1. Read `has_play_pass` from the denormalized Player Profile field (in-memory, loaded at session start).
2. Read `has_no_ads` from the same Player Profile.
3. If either flag is `true` → abort immediately. No AdMob SDK call is made. No ad request is issued. No ad-related UI is rendered.

**Server-side enforcement (at reward grant time for rewarded ads; at match end for interstitials):**

1. Re-read `has_play_pass` from `player_profiles` PostgreSQL table (not the Redis cache, for accuracy) before processing any reward grant or recording an ad impression event.
2. If `has_play_pass = true` → reject the request; return HTTP 403 with error code `PLAY_PASS_AD_SUPPRESSED`. No Coin grant is issued. The event is not logged to the ad impression ledger.

The server re-check protects against a race condition where a player purchases Play Pass mid-session while a rewarded ad reward callback is in flight.

**Eligibility check pseudocode:**

```typescript
function isAdEligible(profile: PlayerProfile): boolean {
  return !profile.has_play_pass && !profile.has_no_ads;
}
```

Both flags are checked. The `has_no_ads` flag may be set by a one-time "Remove Ads" IAP without a Play Pass subscription. Either flag independently suppresses all ads.

---

### 3.2 Interstitial Ad

An interstitial ad is a full-screen ad shown automatically at a defined break point, requiring no player action to trigger. It has no reward.

**Trigger point:** After the player dismisses the results screen (taps "Continue" or equivalent), before the main menu fully loads. The interstitial occupies the transition gap — the 1–2 seconds that would otherwise be blank while the main menu React component mounts. This is the only valid trigger point for interstitials. Interstitials must never be shown:
- Before, during, or immediately after a match starts.
- While character select is open.
- While the player is in a queue.
- During any tutorial or onboarding flow.
- While a rewarded ad is already loaded or playing.

**Frequency cap:**

The system tracks `matchesSinceLastInterstitial` per player session (in-memory; resets to 0 on app restart or on session end). An interstitial is eligible only when:

```
matchesSinceLastInterstitial >= INTERSTITIAL_COOLDOWN_MATCHES
```

When an interstitial is shown, `matchesSinceLastInterstitial` resets to 0. When a match completes without triggering an interstitial (because the cooldown has not elapsed), `matchesSinceLastInterstitial` increments by 1.

The cooldown counter is per-session and in-memory only — it does not persist to PostgreSQL or Redis. If the app is killed and restarted, the counter resets to 0, meaning an interstitial may appear on the first match of the new session (if `INTERSTITIAL_COOLDOWN_MATCHES = 1`). This is acceptable and is the intended behavior.

**Skip delay:** The interstitial displays a countdown UI element. After `INTERSTITIAL_SKIP_DELAY_SEC` seconds, a dismiss button becomes tappable. The player may then close the ad and continue to the main menu. The dismiss button must be visually clear and not misleading (e.g., no dark-pattern close button placements).

**Ad loading:** The interstitial ad is pre-loaded in the background by `AdMobInterstitial.requestAdAsync()` after the previous match result is confirmed (i.e., at the moment the results screen renders, before the player has dismissed it). If no ad is loaded by the time the player taps "Continue," the interstitial is silently skipped — the main menu loads normally with no error shown and no delay added.

**Analytics events emitted:**
- `ad_shown` with `{ adType: "interstitial", matchesSinceLastInterstitial }` — when the ad is displayed.
- `ad_skipped` with `{ adType: "interstitial", displayedDurationSec }` — when the player taps the skip/dismiss button.
- `ad_failed` with `{ adType: "interstitial", errorCode }` — if AdMob returns an error on load (never shown to player).

---

### 3.3 Rewarded Video Ad

A rewarded video ad is player-initiated. The player explicitly taps a "Watch Ad" button to opt in.

**Entry points:**
1. **Results screen:** A "Watch Ad — +15 Coins" button appears on the results screen for eligible free players, below the match reward summary.
2. **Main menu:** A dedicated "Watch Ad for Coins" button in the economy panel (near the Coin balance display).

Neither entry point is shown if `has_play_pass = true` or `has_no_ads = true`. The buttons are absent from the component tree entirely, not merely hidden with `opacity: 0`.

**Daily cap enforcement (client-side display):**

Before rendering the "Watch Ad" button, the client reads `ad_reward_grants_today` from the cached Player Profile. If `ad_reward_grants_today >= REWARDED_AD_DAILY_CAP`, the button is replaced with a "Come back tomorrow" message (or a timer showing time until UTC midnight reset). The button does not appear at all once the cap is reached.

**Flow on tap:**

```
1. Player taps "Watch Ad — +15 Coins"
2. Client checks eligibility (has_play_pass, has_no_ads, daily cap from profile cache)
3. If ineligible → no-op (button should not have been visible; defensive check)
4. If eligible → AdMob.showRewardedAd()
5. AdMob SDK plays the rewarded video
6. On ad completion → client fires POST /ads/rewarded/complete { adImpressionId, userId }
7. Server validates: re-check has_play_pass (PostgreSQL read), check daily cap (ad_reward_grants_today)
8. If valid → grant REWARDED_AD_COIN_GRANT Coins via Currency System (source: "REWARDED_AD_COIN_GRANT")
9. Server returns { status: "granted", coinsGranted: N, newCoinBalance: M }
10. Client shows Coin grant animation on results screen or main menu
11. Server increments ad_reward_grants_today on Player Profile
12. profile:refresh Socket.io event fires → client updates Coin balance display
```

**If the player closes the app or dismisses the ad before completion:** AdMob SDK fires the `onAdDismissed` callback without the reward callback. The client does not fire the `/ads/rewarded/complete` endpoint. No Coin grant is issued. The `ad_reward_grants_today` counter is not incremented.

**Analytics events emitted:**
- `ad_shown` with `{ adType: "rewarded", entryPoint: "results_screen" | "main_menu" }` — when the rewarded ad begins playing.
- `ad_completed` with `{ adType: "rewarded", adImpressionId }` — when the player watches to full completion.
- `ad_reward_granted` with `{ adType: "rewarded", coinsGranted, adImpressionId }` — when the server confirms the Coin grant.
- `ad_skipped` with `{ adType: "rewarded", displayedDurationSec }` — if the ad is dismissed before completion (only for skippable formats).
- `ad_failed` with `{ adType: "rewarded", errorCode, entryPoint }` — if AdMob returns an error on load or play.

---

### 3.4 Ad Loading

AdMob ads are **pre-loaded in the background** and cached client-side by the AdMob SDK. The loading strategy is:

| Ad Type | When Loaded | Reload Trigger |
|---|---|---|
| Interstitial | When results screen mounts (during the period the player is reading match results) | After each interstitial is shown (load next one immediately) |
| Rewarded Video | On app foreground / session start (both entry points pre-load one ad) | After each rewarded ad is shown or dismissed |

**Rules:**
- Ad loading is fire-and-forget. The game never `await`s an ad load before proceeding.
- If an ad load fails (network unavailable, AdMob error), the failure is logged to `ad_failed` analytics and the ad slot remains empty. No retry is attempted in that session for that slot — the SDK's internal retry handles it.
- If an ad is not loaded when a trigger fires, the trigger is silently skipped. The player proceeds to the main menu normally (interstitial case) or sees the "Watch Ad" button remain tappable for the next attempt (rewarded case — but the ad load is retried in the background).
- **Gameplay is never blocked by ad loading.** There is no loading spinner, no hold screen, and no delay added anywhere in the game flow that is caused by ad loading state.

---

### 3.5 GDPR / Consent (UMP SDK)

AdMob consent is managed by the **AdMob User Messaging Platform (UMP) SDK** (`@react-native-google-mobile-ads/UMP`). This consent layer governs whether personalized (interest-based) or non-personalized ads are served by AdMob. It is **entirely separate** from the game's own analytics consent (see analytics-telemetry.md §3.3).

**Consent flow:**

1. On first app launch (or on first eligible session after a region-based UMP trigger), `UMP.requestConsentInfoUpdate()` is called.
2. If a consent form is required (UMP determines the player is in a GDPR-applicable region or California), `UMP.showConsentFormIfRequired()` presents the standard Google consent form.
3. The consent form is shown **before** any AdMob ad request is made. No ad is loaded or requested until UMP reports `consentStatus = "OBTAINED"` or `consentStatus = "NOT_REQUIRED"`.
4. If the player is in a non-applicable region (`consentStatus = "NOT_REQUIRED"`), personalized ads proceed immediately.
5. If the player declines personalized ads, AdMob serves non-personalized ads. The game does not change behavior based on personalized vs. non-personalized — the distinction is internal to AdMob.
6. The UMP SDK persists the consent decision. It is not re-prompted on every launch — only when the consent status has expired or changed (Google-managed lifecycle).

**Consent and Play Pass:** UMP consent is only relevant to ad delivery. If `has_play_pass = true`, no AdMob calls are made at all, and the UMP flow is never triggered. There is no need to collect AdMob consent from a Play Pass subscriber.

**COPPA:** If the player is flagged for COPPA (child account — determined by platform-level parental controls, not by age gate in-game), AdMob is initialized with `RequestConfiguration.setTagForChildDirectedTreatment(true)` and only child-directed ads are served. COPPA-mode players always receive non-personalized ads regardless of UMP consent status.

**Analytics consent is separate:** The player's analytics consent (Tier 0/Tier 1, stored in `player_profiles.analyticsConsent`) has no effect on AdMob ad serving. A player may consent to analytics but decline personalized ads, or vice versa. The two consent decisions are stored and evaluated independently.

---

### 3.6 Play Pass Suppression

Play Pass suppression is the most critical correctness requirement of the Ad System. The contract is absolute: **Play Pass subscribers see zero ads.**

Implementation requirements (all must be satisfied simultaneously):

1. **Pre-SDK initialization gate:** Before calling `MobileAds.initialize()` or loading any ad, check `playerProfile.has_play_pass`. If `true`, skip SDK initialization entirely. Do not call `MobileAds.initialize()` at all for Play Pass subscribers.

2. **Per-trigger check:** Even if the SDK was initialized during a free session (e.g., player upgraded mid-session), check `has_play_pass` before every individual ad request: `InterstitialAd.load()`, `RewardedAd.load()`, or `UMP.requestConsentInfoUpdate()`. If `has_play_pass = true` at the time of the call → skip.

3. **Server-side re-validation:** The server re-checks `has_play_pass` from PostgreSQL before processing any ad reward grant endpoint. If the player upgraded during the session, the server rejects the grant with `PLAY_PASS_AD_SUPPRESSED` (HTTP 403).

4. **UI suppression:** All ad-related UI components (rewarded ad buttons, "Watch Ad" text) check `has_play_pass` from the in-memory profile before rendering. Components return `null` if the flag is `true`.

5. **Profile refresh propagation:** When a player purchases Play Pass, the Inventory / Entitlements system updates `player_profiles.has_play_pass = true` within the same DB transaction and emits `profile:refresh` via Socket.io. The client's in-memory profile is updated immediately on receipt of this event. Any ad that was pre-loaded but not yet shown must be discarded — call `interstitialAd.destroy()` on any loaded ad object after a Play Pass purchase is confirmed.

**`has_no_ads` flag:** The `has_no_ads` boolean (set by a one-time "Remove Ads" IAP, if that product is offered) follows the exact same suppression path. All five requirements above apply equally when `has_no_ads = true`.

---

### 3.7 Test Mode

Development and staging environments must never serve real AdMob ads.

**Test ad unit IDs:** The AdMob SDK provides official test ad unit IDs that always return a test ad, never charge impressions, and are safe for automated testing:

```typescript
const TEST_AD_UNIT_IDS = {
  interstitial: "ca-app-pub-3940256099942544/1033173712",
  rewarded:     "ca-app-pub-3940256099942544/5224354917",
};
```

**Production ad unit IDs** are fetched from Remote Config cold keys (`ads.adUnitIdInterstitial`, `ads.adUnitIdRewarded`) at app launch. They are never hardcoded in the client bundle.

**Environment detection:**

```typescript
function getAdUnitId(adType: "interstitial" | "rewarded"): string {
  if (__DEV__ || config.environment === "staging") {
    return TEST_AD_UNIT_IDS[adType];
  }
  return remoteConfig.get(`ads.adUnitId${capitalize(adType)}`);
}
```

The `__DEV__` global (set by Metro bundler) ensures test IDs are always used in local development. The `config.environment` check covers staging builds where `__DEV__` may be `false`.

**Device test ID registration:** During development, each developer's physical device IDFA/GAID is registered with AdMob's test device list via `MobileAds.setRequestConfiguration({ testDeviceIdentifiers: [...] })`. This is configured in the app's dev-only setup module and is never shipped to production.

---

### 3.8 TypeScript Interfaces

```typescript
/** Configuration loaded from Remote Config at app launch. */
interface AdConfig {
  interstitialCooldownMatches: number;  // INTERSTITIAL_COOLDOWN_MATCHES
  interstitialSkipDelaySec: number;     // INTERSTITIAL_SKIP_DELAY_SEC
  rewardedAdCoinGrant: number;          // REWARDED_AD_COIN_GRANT (Coins per view)
  rewardedAdDailyCap: number;           // REWARDED_AD_DAILY_CAP (views per UTC day)
  rewardedAdEnabled: boolean;           // Remote Config kill-switch
  adUnitIdInterstitial: string;         // Production AdMob unit ID
  adUnitIdRewarded: string;             // Production AdMob unit ID
}

/** In-session state tracked per player; in-memory only. */
interface AdSessionState {
  matchesSinceLastInterstitial: number;  // Resets to 0 after each interstitial shown
  interstitialAdLoaded: boolean;         // True when AdMob has a loaded interstitial ready
  rewardedAdLoaded: boolean;             // True when AdMob has a loaded rewarded ad ready
}

/** Payload sent to POST /ads/rewarded/complete */
interface RewardedAdCompleteRequest {
  adImpressionId: string;   // AdMob-provided impression ID from onAdLoaded callback
  userId: string;           // Supabase user UUID
  entryPoint: "results_screen" | "main_menu";
}

/** Response from POST /ads/rewarded/complete */
interface RewardedAdCompleteResponse {
  status: "granted" | "cap_reached" | "ineligible" | "duplicate";
  coinsGranted: number;     // 0 if not granted
  newCoinBalance: number;   // Updated Coin balance after grant
  adsWatchedToday: number;  // Updated daily counter
}

/** Analytics event shape for all ad events (see §3.3 of analytics-telemetry.md for base fields). */
interface AdAnalyticsEvent {
  adType: "interstitial" | "rewarded";
  adImpressionId?: string;
  entryPoint?: "results_screen" | "main_menu";
  displayedDurationSec?: number;
  errorCode?: string;
  coinsGranted?: number;
  matchesSinceLastInterstitial?: number;
}
```

---

## 4. Formulas

### 4.1 Daily Rewarded Ad Cap Enforcement

The server enforces a per-player, per-UTC-day cap on rewarded ad Coin grants. The cap prevents ad revenue maximization from replacing play-based progression as the primary Coin source.

**Variables:**

| Variable | Description | Default |
|---|---|---|
| `adsWatchedToday` | Count of rewarded ads completed today (UTC) for this player, stored in `player_profiles.ad_reward_grants_today` | — |
| `REWARDED_AD_DAILY_CAP` | Maximum rewarded ad completions per player per UTC day (Remote Config key: `ads.rewardedAdDailyCap`) | 5 |

**Cap check formula:**

```
if adsWatchedToday >= REWARDED_AD_DAILY_CAP:
    → reject grant; return { status: "cap_reached" }
    → display "Come back tomorrow" message in client UI
else:
    → proceed with grant; increment adsWatchedToday by 1
```

**Example — cap not reached:**
```
adsWatchedToday = 3, REWARDED_AD_DAILY_CAP = 5
3 >= 5 → FALSE → grant proceeds
adsWatchedToday becomes 4
```

**Example — cap reached:**
```
adsWatchedToday = 5, REWARDED_AD_DAILY_CAP = 5
5 >= 5 → TRUE → grant rejected; "Come back tomorrow" shown
adsWatchedToday remains 5
```

**Daily reset:** `ad_reward_grants_today` resets to 0 at UTC midnight. The reset is implemented as a per-player lazy reset: when the server processes a rewarded ad grant, it compares the UTC date string of `ad_reward_last_reset_at` to today's UTC date string. If they differ, the counter is reset to 0 before the cap check. This avoids a scheduled batch job and is safe against clock drift.

```
today_utc = new Date().toISOString().slice(0, 10)  // e.g., "2026-05-28"
if ad_reward_last_reset_at != today_utc:
    ad_reward_grants_today = 0
    ad_reward_last_reset_at = today_utc
// then proceed with cap check
```

---

### 4.2 Interstitial Cooldown

The cooldown prevents consecutive-match interstitial fatigue by requiring a minimum number of completed matches between impressions.

**Variables:**

| Variable | Description | Default |
|---|---|---|
| `matchesSinceLastInterstitial` | In-session counter; increments on each match completion without an interstitial | — |
| `INTERSTITIAL_COOLDOWN_MATCHES` | Minimum completed matches before next interstitial is eligible (Remote Config key: `ads.interstitialFrequencyCap`) | 3 |

**Eligibility formula:**

```
if matchesSinceLastInterstitial >= INTERSTITIAL_COOLDOWN_MATCHES AND adLoaded:
    → show interstitial; reset matchesSinceLastInterstitial = 0
else:
    → skip interstitial; matchesSinceLastInterstitial += 1
```

**Example — cooldown elapsed, ad loaded:**
```
matchesSinceLastInterstitial = 3, INTERSTITIAL_COOLDOWN_MATCHES = 3, adLoaded = true
3 >= 3 → TRUE AND true → interstitial shown; counter resets to 0
```

**Example — cooldown not elapsed:**
```
matchesSinceLastInterstitial = 2, INTERSTITIAL_COOLDOWN_MATCHES = 3
2 >= 3 → FALSE → interstitial skipped; counter becomes 3
Next match: 3 >= 3 → TRUE → interstitial eligible
```

**Example — cooldown elapsed but ad not loaded:**
```
matchesSinceLastInterstitial = 3, INTERSTITIAL_COOLDOWN_MATCHES = 3, adLoaded = false
3 >= 3 AND false → FALSE → interstitial silently skipped; counter does NOT reset (still 3)
Next match: 3 >= 3 → TRUE → still eligible; will show if ad loads before that match ends
```

> **Note:** The counter does not reset when the ad is skipped due to failed load. Eligibility is preserved so the ad shows as soon as one is available.

---

### 4.3 Rewarded Coin Grant

The Coin grant per completed rewarded ad is a flat constant. There is no multiplicative formula.

**Variables:**

| Variable | Description | Default |
|---|---|---|
| `REWARDED_AD_COIN_GRANT` | Coins granted per completed rewarded ad view (Remote Config key: `ads.rewardedAdCoinGrant`) | 15 |

**Grant formula:**

```
coins_granted = REWARDED_AD_COIN_GRANT  (flat; no multipliers)
```

No Play Pass multiplier applies to rewarded ad Coin grants — Play Pass subscribers do not see rewarded ads at all. No win/loss modifier applies. The grant is the same regardless of how the player's preceding match ended.

**Example:**
```
REWARDED_AD_COIN_GRANT = 15
Player completes rewarded ad → coin_balance += 15
```

**Maximum daily Coin earn from rewarded ads:**

```
max_daily_ad_coins = REWARDED_AD_COIN_GRANT × REWARDED_AD_DAILY_CAP
                   = 15 × 5
                   = 75 Coins/day (at default settings)
```

This represents a modest supplement to match-based Coin earn (`COIN_BASE_WIN = 45`). A player grinding only rewarded ads earns the equivalent of ~1.7 wins per day from ads — a meaningful but non-dominant income source.

---

## 5. Edge Cases

### 5.1 Ad Fails to Load (AdMob Error)

**Scenario:** AdMob returns a non-zero error code on `InterstitialAd.load()` or `RewardedAd.load()` — e.g., network unavailable, no fill (no ad available to serve in this region), or SDK initialization failure.

**Resolution:**
- The error is caught silently by the ad loading module.
- An `ad_failed` analytics event is emitted with `{ adType, errorCode }` for monitoring purposes.
- No error message, modal, toast, or any indication is shown to the player. The failure is invisible.
- For **interstitial:** The main menu loads normally. The interstitial slot remains empty. The `matchesSinceLastInterstitial` counter does NOT reset (the cooldown is not consumed by a failed load).
- For **rewarded ad:** The "Watch Ad" button remains visible in the UI (the button's state is tied to ad load state). If the ad fails to load, the button either shows a loading state briefly, then disappears, or (if pre-load failed before the player navigated to the screen) is absent. The player is never shown a broken ad experience.
- No fallback ad (banner, different network) is ever shown as a substitute. The slot is simply empty.

---

### 5.2 Player Watches Ad, Then Immediately Purchases Play Pass

**Scenario:** A free player completes a rewarded ad (fires `/ads/rewarded/complete`) and simultaneously, in a different in-app screen or through a background IAP flow, purchases Play Pass. The ad completion callback and the Play Pass grant are in flight at the same time.

**Resolution:**
- Both the ad completion endpoint and the Play Pass grant (Inventory/Entitlements system) interact with `player_profiles`, but at different fields.
- The ad completion endpoint re-reads `has_play_pass` from PostgreSQL (not Redis cache) as part of its server-side validation (see §3.1). If the Play Pass grant committed first and `has_play_pass` is now `true`, the ad endpoint returns HTTP 403 (`PLAY_PASS_AD_SUPPRESSED`). No Coin grant is issued. The player does not receive double benefit.
- If the ad completion committed first (Coins granted, `ad_reward_grants_today` incremented), the Play Pass grant then sets `has_play_pass = true`. The Coin grant stands — there is no rollback of a legitimate Coin earn that occurred before Play Pass was active.
- After the Play Pass grant commits and `profile:refresh` fires, the client receives the updated `has_play_pass = true` flag. All ad-related UI is hidden immediately. Any loaded AdMob ad objects are destroyed (`.destroy()` called). No subsequent ad requests are made.

---

### 5.3 Daily Cap Counter Race at UTC Midnight

**Scenario:** Two rewarded ad completion requests arrive at the server within milliseconds of each other, both straddling UTC midnight. Player's `ad_reward_grants_today = 5` (at cap), `ad_reward_last_reset_at = "2026-05-27"`. Server time is `00:00:00.050 UTC on 2026-05-28`. Both requests trigger the lazy reset.

**Resolution:**
- The lazy reset is performed inside the same database row lock acquired by the Currency System's `SELECT ... FOR UPDATE` on `player_profiles` (per currency-system.md §3.6, step 3).
- Request A acquires the row lock, detects `ad_reward_last_reset_at != "2026-05-28"`, resets `ad_reward_grants_today = 0`, sets `ad_reward_last_reset_at = "2026-05-28"`, increments counter to 1, and commits. Lock released.
- Request B acquires the row lock, detects `ad_reward_last_reset_at == "2026-05-28"` (already reset by A), proceeds with `ad_reward_grants_today = 1`, increments to 2. No double-reset.
- Both grants succeed correctly. No race condition in the counter. The bucket is per UTC date string (`"2026-05-28"`), not a clock comparison, so the reset is idempotent within a day.

---

### 5.4 Player Closes App During Rewarded Ad

**Scenario:** A rewarded ad is playing. The player backgrounds or force-quits the app before the ad finishes.

**Resolution:**
- The AdMob SDK fires the `onAdDismissed` callback (or the app process is killed before any callback fires).
- In either case, the `/ads/rewarded/complete` endpoint is never called by the client.
- No Coin grant is issued. The `ad_reward_grants_today` counter is not incremented.
- When the player relaunches the app, the session reloads the Player Profile normally. The rewarded ad button is available again (assuming the daily cap has not been reached by other completed views).
- There is no partial-view credit or apology mechanism. The contract is clear: ad must be watched to completion for the grant to fire.

---

### 5.5 AdMob SDK Fails to Initialize

**Scenario:** `MobileAds.initialize()` throws or does not call its callback (e.g., the Google Mobile Ads SDK binary is corrupted, or a cold-start SDK load failure occurs on a specific device).

**Resolution:**
- `MobileAds.initialize()` is wrapped in a `try/catch`. Initialization failure is caught and logged as an `ad_failed` analytics event with `{ errorCode: "SDK_INIT_FAILURE" }`.
- A module-level flag `adSdkInitialized = false` is set. Every subsequent ad call (`load()`, `show()`, `UMP.requestConsentInfoUpdate()`) checks this flag first and returns a no-op if `false`.
- The game continues to function normally. No crash. No error shown to the player. No ad is ever loaded or shown.
- On the next app launch, initialization is retried from cold start.

---

### 5.6 Rewarded Ad Shown but Server Grant Fails (Network Error)

**Scenario:** The player completes a rewarded ad. The client fires `POST /ads/rewarded/complete`. The HTTP request fails (connection timeout, server 500) before a response is received.

**Resolution:**
- The client retries the request up to 3 times with exponential backoff: 1s, 3s, 9s.
- Each retry uses the same `adImpressionId` as the `idempotency_key` for the Currency System grant (`"ad_reward:{adImpressionId}:{playerId}"`). If the first request actually committed but the response was lost, the retry receives `{ status: "duplicate" }` and the original committed balance — no double grant.
- If all 3 retries fail, the client shows a brief "Reward pending — your Coins will arrive shortly" toast. The Coin grant is not credited in this session.
- The client does not grant Coins locally/optimistically. Balances are always server-confirmed before display.
- If the server later processes a delayed request (e.g., the player reconnects), the idempotency key prevents double-granting. The `profile:refresh` event delivers the updated balance when connectivity is restored.

---

### 5.7 Interstitial Shown During App Transition (Incorrect Trigger)

**Scenario:** Due to a navigation race condition, an interstitial attempts to show while the character select screen or match lobby is already rendering (i.e., the trigger fires too late in the navigation stack).

**Resolution:**
- The interstitial trigger checks the current navigation route before calling `interstitialAd.show()`. If the current route is not `"MainMenu"` (or equivalent transition screen), the show call is cancelled.
- Specifically, if the React Navigation state indicates the user has navigated past the transition point (e.g., is already at `"CharacterSelect"` or `"Lobby"`), the loaded ad is discarded (`.destroy()` called) without being shown.
- The `matchesSinceLastInterstitial` counter does not reset in this case — the cooldown is not consumed.
- No error is shown to the player.

---

## 6. Dependencies

### 6.1 Upstream — Ad System Reads From

| System | What Ad System Needs | Interface | Notes |
|---|---|---|---|
| **Player Profile** (`player-profile.md`) | `has_play_pass` and `has_no_ads` denormalized flags | In-memory profile object (loaded at session start); `profile:refresh` Socket.io event for mid-session updates | Fast-path eligibility check. Server-side re-reads `has_play_pass` from PostgreSQL on each reward grant endpoint call |
| **Inventory / Entitlements** (`inventory-entitlements.md`) | Write authority for `has_play_pass` and `has_no_ads` flags; emits `profile:refresh` on change | Socket.io `profile:refresh` event received by client | Ad System consumes these flag changes; it does not write them |
| **Currency System** (`currency-system.md`) | `grantCurrency` API for rewarded Coin grant; `REWARDED_AD_COIN_GRANT` ledger source; daily cap counter fields on Player Profile | Server-side internal function call; `ad_reward_grants_today` field on `player_profiles` | Coin grant is atomic and subject to Currency System's standard ledger/idempotency pipeline |
| **Remote Config** (`remote-config.md`) | `ads.*` config keys: `interstitialFrequencyCap`, `rewardedAdDailyCap`, `rewardedAdCoinGrant`, `rewardedAdEnabled`, `adUnitIdInterstitial`, `adUnitIdRewarded`, `adsEnabledForNewAccounts`, `newAccountGraceDays` | `GET /v1/config` at app launch (cold keys); hot keys updatable mid-session via Socket.io `config_update` | Ad unit IDs and most parameters are cold keys. `rewardedAdEnabled` and `interstitialFrequencyCap` are hot keys |
| **Authentication** (`authentication.md`) | Supabase JWT validation on `POST /ads/rewarded/complete` | Standard Auth middleware on every server request | `userId` extracted from JWT; not from request body |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | Accepts `ad_shown`, `ad_completed`, `ad_reward_granted`, `ad_skipped`, `ad_failed` events | Async fire-and-forget via analytics event emitter | All ad events are Tier 0 (operational); collected regardless of analytics consent tier |

### 6.2 Downstream — Ad System Produces / Notifies

| System | What Ad System Provides | Interface | Notes |
|---|---|---|---|
| **Currency System** (`currency-system.md`) | Triggers Coin grant on rewarded ad completion | `POST /ads/rewarded/complete` → server calls `grantCurrency({ source: "REWARDED_AD_COIN_GRANT" })` | Currency System owns the grant execution; Ad System is the trigger |
| **Player Profile** (`player-profile.md`) | Increments `ad_reward_grants_today` and updates `ad_reward_last_reset_at` after each grant | PostgreSQL `UPDATE player_profiles` within grant transaction | Written in the same transaction as the Currency System Coin grant |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | `ad_shown`, `ad_completed`, `ad_reward_granted`, `ad_skipped`, `ad_failed` events | Async event emitter (Tier 0) | Events carry `adImpressionId`, `adType`, `entryPoint`, `errorCode` as applicable |
| **Logging / Monitoring** (`logging-monitoring.md`) | Ad lifecycle logs (load, show, complete, fail) | `ILogger` interface; server-side and client-side | No PII beyond `userId` UUID. Ad unit IDs and impression IDs are not PII |

### 6.3 External Dependencies

| Dependency | Role | Notes |
|---|---|---|
| **AdMob SDK** (`react-native-google-mobile-ads`) | Ad delivery, UMP consent, rewarded ad callbacks | Version pinned in `mobile/package.json`. Server-side impression validation not used — client fires the completion endpoint |
| **Google UMP SDK** (bundled with `react-native-google-mobile-ads`) | GDPR/CCPA consent form management | Consent decisions persisted by SDK. Not integrated with game's analytics consent storage |
| **RevenueCat** | Play Pass subscription state, which drives `has_play_pass` entitlement | Ad System reads the entitlement outcome; it does not call RevenueCat directly |

---

## 7. Tuning Knobs

All constants are Remote Config keys. Cold keys require a server restart to take effect. Hot keys may be pushed to connected clients mid-session via Socket.io `config_update`.

| Parameter | Remote Config Key | Default | Hot/Cold | Safe Range | What Breaks Outside Range |
|---|---|---|---|---|---|
| Interstitial frequency (matches between ads) | `ads.interstitialFrequencyCap` | `3` | Hot | 1–10 | Below 1: invalid (every match would trigger). At 1: every completed match triggers an interstitial — high churn risk. Above 10: near-zero interstitial impressions; ad revenue negligible from this format. Recommended floor: 2. |
| Interstitial skip delay | `ads.interstitialSkipDelaySec` | `5` | Cold | 3–15 | Below 3: too brief to register an impression with most ad networks. Above 15: exceeds GDPR/platform guidelines for forced-view duration; risk of app store policy violations. |
| Rewarded ad coin grant | `ads.rewardedAdCoinGrant` | `15` | Cold | 5–30 | Below 5: reward not worth player time (a single match loss grants 25 Coins). Above 30: ad-watching approaches match-play Coin efficiency; incentivizes watch-over-play behavior and reduces session engagement. |
| Rewarded ad daily cap | `ads.rewardedAdDailyCap` | `5` | Cold | 1–10 | Below 1: invalid. At 1: minimal ad income for committed grinders; reduces friction but also revenue. Above 10: increases AdMob impressions short-term; risks rewarded ad fatigue and daily cap frustration. Maximum daily Coin earn from ads at cap 10: 150 Coins (equals Play Pass loss-match grant × ~4 matches). |
| Rewarded ad kill-switch | `ads.rewardedAdEnabled` | `true` | Hot | `true`/`false` | Set `false` during AdMob outages or network fill issues to suppress rewarded UI globally without a deploy. |
| New account ad grace period | `ads.newAccountGraceDays` | `3` | Cold | 0–14 | 0: ads shown from first session. Above 14: significant new-user revenue window lost; grace period should not outlast the tutorial onboarding window. |
| Interstitial ad unit ID (production) | `ads.adUnitIdInterstitial` | `""` (must be set for production) | Cold | Valid AdMob unit ID string | Empty string in production causes AdMob SDK initialization failure. Always paired with test ID in `__DEV__`. |
| Rewarded ad unit ID (production) | `ads.adUnitIdRewarded` | `""` (must be set for production) | Cold | Valid AdMob unit ID string | Same as above. |
| New account ad gate | `ads.adsEnabledForNewAccounts` | `true` | Cold | `true`/`false` | Set `false` to suppress ads entirely for all new accounts (for soft-launch periods or A/B testing on new-user experience). |

**Note on `INTERSTITIAL_COOLDOWN_MATCHES` vs. `INTERSTITIAL_SKIP_DELAY_SEC`:** These two parameters control different dimensions of interstitial experience. `INTERSTITIAL_COOLDOWN_MATCHES` controls how *often* interstitials appear (session-level frequency). `INTERSTITIAL_SKIP_DELAY_SEC` controls how *long* each impression lasts. Both should be tuned in tandem: high frequency (low cooldown) warrants a short skip delay to maintain acceptable UX. Low frequency (high cooldown) can tolerate a slightly longer skip delay.

**Session counter note:** `matchesSinceLastInterstitial` is an in-memory session counter, not a Remote Config key. It is not tunable at runtime and resets on each app launch. This is intentional — the frequency cap is defined per-session, not per lifetime.

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and are independently verifiable by automated test or documented manual QA.

**AC-AD-01 — Play Pass subscriber sees zero ads (client suppression)**
- Given: A player with `has_play_pass: true` opens the app
- When: Any code path attempts to call `MobileAds.initialize()`, `InterstitialAd.load()`, or `RewardedAd.load()`
- Then: The call is never made; no AdMob SDK function is invoked; the rewarded ad button is absent from the results screen and main menu DOM tree (not hidden, not `opacity: 0` — `null` returned from component)

**AC-AD-02 — `has_no_ads` player sees zero ads (client suppression)**
- Given: A player with `has_no_ads: true` and `has_play_pass: false` opens the app
- When: Any code path attempts to load or show an ad
- Then: Same suppression as AC-AD-01; the `has_no_ads` flag independently gates all ad calls

**AC-AD-03 — Interstitial shows after cooldown**
- Given: A free player (`has_play_pass: false`, `has_no_ads: false`) has completed `INTERSTITIAL_COOLDOWN_MATCHES` (default: 3) matches since the last interstitial; an ad is pre-loaded
- When: The player dismisses the results screen after their third match
- Then: The interstitial ad is shown during the main menu transition; `matchesSinceLastInterstitial` resets to 0; `ad_shown` analytics event emitted with `adType: "interstitial"`

**AC-AD-04 — Interstitial not shown before cooldown**
- Given: A free player has completed `INTERSTITIAL_COOLDOWN_MATCHES - 1` matches since the last interstitial
- When: The player dismisses the results screen
- Then: No interstitial is shown; the main menu loads immediately; `matchesSinceLastInterstitial` increments by 1; no `ad_shown` event emitted for this transition

**AC-AD-05 — Interstitial gracefully skipped when no ad loaded**
- Given: A free player is eligible for an interstitial (cooldown elapsed) but AdMob has no loaded ad (load failed or not yet returned)
- When: The player dismisses the results screen
- Then: Main menu loads with no delay; no error message shown to player; `matchesSinceLastInterstitial` does NOT reset (eligibility preserved for next match); `ad_failed` analytics event was previously emitted when the load failed

**AC-AD-06 — Rewarded ad button visible for eligible free player**
- Given: A free player with `has_play_pass: false`, `has_no_ads: false`, and `ad_reward_grants_today < REWARDED_AD_DAILY_CAP`
- When: The results screen renders
- Then: The "Watch Ad" button is visible and tappable; it displays the exact Coin reward (`REWARDED_AD_COIN_GRANT`) in its label

**AC-AD-07 — Rewarded ad Coin grant committed on completion**
- Given: An eligible free player taps "Watch Ad" and the AdMob rewarded ad plays to completion
- When: The ad completion callback fires and `POST /ads/rewarded/complete` is called with a valid `adImpressionId`
- Then: `coin_balance` increases by exactly `REWARDED_AD_COIN_GRANT`; a Currency System ledger row is created with `source: "REWARDED_AD_COIN_GRANT"`; `ad_reward_grants_today` increments by 1; `profile:refresh` Socket.io event fires; `ad_completed` and `ad_reward_granted` analytics events emitted

**AC-AD-08 — Rewarded ad daily cap enforced (client)**
- Given: A free player has `ad_reward_grants_today == REWARDED_AD_DAILY_CAP`
- When: The results screen renders
- Then: The "Watch Ad" button is replaced by a "Come back tomorrow" message; no AdMob SDK call is made for this player during this session

**AC-AD-09 — Rewarded ad daily cap enforced (server)**
- Given: A free player's `ad_reward_grants_today == REWARDED_AD_DAILY_CAP` at the time of the server request (client may have had stale data)
- When: `POST /ads/rewarded/complete` is received by the server
- Then: Server returns `{ status: "cap_reached", coinsGranted: 0 }`; no Currency System grant is called; `coin_balance` unchanged; no ledger row created

**AC-AD-10 — No reward issued if player closes app during rewarded ad**
- Given: A rewarded ad is playing for a free player
- When: The player backgrounds or force-quits the app before the ad completes
- Then: No `POST /ads/rewarded/complete` call is made; `coin_balance` unchanged; `ad_reward_grants_today` unchanged; no Currency System ledger row for this impression

**AC-AD-11 — Rewarded ad grant idempotency**
- Given: `POST /ads/rewarded/complete` with `adImpressionId: "imp-001"` succeeds but the HTTP response is lost; the client retries with the same `adImpressionId`
- When: The retry is processed by the server
- Then: No second Coin grant is issued; Currency System returns the original committed balance (idempotency key `"ad_reward:imp-001:{playerId}"`); `ad_reward_grants_today` is not double-incremented; server returns `{ status: "duplicate" }`

**AC-AD-12 — Play Pass grant mid-session suppresses subsequent ads immediately**
- Given: A free player has a pre-loaded interstitial ad and is eligible for it; they purchase Play Pass mid-session
- When: The Play Pass entitlement commits and `profile:refresh` fires on the client
- Then: The loaded interstitial ad is destroyed (`.destroy()` called); no subsequent ad is loaded or shown; the "Watch Ad" button disappears from results screen and main menu on next render; `has_play_pass` is `true` in in-memory profile

**AC-AD-13 — Server rejects ad reward grant for Play Pass subscriber**
- Given: A player has `has_play_pass: true` in PostgreSQL (subscription purchased or restored server-side)
- When: `POST /ads/rewarded/complete` is received by the server for this player (e.g., a stale client request)
- Then: Server returns HTTP 403 with error code `PLAY_PASS_AD_SUPPRESSED`; no Coin grant; no ledger row; `coin_balance` unchanged

**AC-AD-14 — Test ad unit IDs used in dev/staging**
- Given: The app is running in `__DEV__ = true` or `config.environment === "staging"`
- When: Any ad is requested or displayed
- Then: The AdMob SDK is initialized with the Google-provided test ad unit IDs; the production unit IDs from Remote Config are not used; impressions do not count against the production AdMob account

**AC-AD-15 — AdMob SDK initialization failure is non-fatal**
- Given: `MobileAds.initialize()` throws an error on app launch
- When: The app continues to load
- Then: The error is caught; `adSdkInitialized = false`; all subsequent ad calls return no-ops; no crash occurs; no error is shown to the player; an `ad_failed` analytics event is emitted with `errorCode: "SDK_INIT_FAILURE"`

**AC-AD-16 — UMP consent form shown before first ad in applicable region**
- Given: A free player launches the app for the first time in a GDPR-applicable region
- When: The app initializes the Ad System
- Then: `UMP.requestConsentInfoUpdate()` is called; if the UMP SDK requires a form, `UMP.showConsentFormIfRequired()` presents the consent form; no AdMob ad is requested or loaded until the consent form is dismissed; the analytics consent state in `player_profiles` is not modified by this flow

**AC-AD-17 — Daily cap counter resets at UTC midnight (lazy reset)**
- Given: A player has `ad_reward_grants_today: 5` and `ad_reward_last_reset_at: "2026-05-27"` (yesterday); the server clock reads `2026-05-28 00:01:00 UTC`
- When: `POST /ads/rewarded/complete` is received for this player
- Then: Server detects `ad_reward_last_reset_at != "2026-05-28"`; resets `ad_reward_grants_today` to 0; sets `ad_reward_last_reset_at` to `"2026-05-28"`; processes the grant (counter becomes 1); Coin grant is issued normally

**AC-AD-18 — All ad analytics events are Tier 0**
- Given: Any ad event (`ad_shown`, `ad_completed`, `ad_reward_granted`, `ad_skipped`, `ad_failed`) is emitted
- When: The analytics pipeline evaluates consent tier for this event
- Then: The event is processed regardless of the player's analytics consent setting (`analyticsConsent: false` does not suppress ad events); the event carries `consentTier: 0` in its base fields

**AC-AD-19 — Interstitial skip button is available after skip delay**
- Given: An interstitial ad is showing for a free player
- When: `INTERSTITIAL_SKIP_DELAY_SEC` seconds have elapsed since the ad began displaying
- Then: The dismiss/skip button becomes visibly tappable; tapping it dismisses the ad and completes the main menu transition; `ad_skipped` analytics event emitted with `displayedDurationSec >= INTERSTITIAL_SKIP_DELAY_SEC`

**AC-AD-20 — Rewarded ad button absent during active rewarded ad session**
- Given: A rewarded ad is currently playing
- When: The player navigates (or the UI re-renders) to a screen containing a rewarded ad button
- Then: The button is not interactive while an ad is in progress; it does not trigger a second simultaneous ad load or show; the AdMob SDK is not called twice for the same slot concurrently

---

*End of Document*
