# Battle Pass — Game Design Document

> **System**: Battle Pass
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

The Battle Pass is a seasonal, purchasable progression track that runs alongside BRAWLZONE's core gameplay loop for approximately six weeks per season. Players advance through 30 tiers by earning Battle Pass XP (BPXP) from match completions — every match, regardless of outcome, advances the track. Each tier has a Free Reward claimable by all players and a Premium Reward unlocked only by players who have purchased the Battle Pass with Diamonds. The Battle Pass costs `BATTLE_PASS_DIAMOND_COST` Diamonds (default 950D) and can be purchased at any point during the active season; purchasing retroactively makes all Premium Rewards from Tier 1 through the player's current tier immediately claimable. Rewards are never auto-granted — the player must tap "Claim" in the Battle Pass UI for each tier. At season end, all progress resets; any unclaimed rewards are permanently forfeited after a 72-hour warning window. The Battle Pass is entirely distinct from the Play Pass subscription: Play Pass removes ads and grants a Diamond allowance; Battle Pass is a seasonal content track. Season configuration (start/end dates, the reward table) lives in Remote Config cold keys, enabling the live team to define new seasons without a code deploy.

---

## 2. Player Fantasy

### 2.1 The Anticipation of a New Season

A new season is an event. The season splash screen arrives with a trailer-style animated reveal of the new Legendary skin waiting at Tier 30 Premium. The track refreshes to zero — equal footing for every player, regardless of how they performed last season. The player opens the Battle Pass screen for the first time each season and sees 30 locked tiers stretching ahead, each one a visible promise: character unlocks, Coin bundles, exclusive cosmetics, and at the very end, a Legendary skin nobody outside this season will ever own again. The decision to "get the Pass" happens in this moment of anticipation, when the player can see exactly what they are buying — no mystery boxes, no hidden contents.

### 2.2 The Satisfaction of Climbing the Track

Climbing the Battle Pass is a parallel progression channel that runs beneath every match. Win or lose, a match moves the BPXP counter. The player finishes a 3v3 Squad Brawl, taps to the results screen, and sees the Battle Pass progress bar tick forward. Reaching a new tier creates a "Claim!" callout in the Battle Pass tab that catches the eye on return to the main menu. Tapping "Claim" and watching the reward animate into the player's inventory is the designed micro-celebration — it is tactile, immediate, and concrete. The player can see exactly how many more matches they need to reach the next reward. Progress is never vague.

The free track rewards are not consolation prizes. They are designed to feel genuinely valuable — Coins, earnable characters (Fen, Grim, Dash), and exclusive cosmetics that cannot be obtained anywhere else in the game. The premium track adds a second column of rewards that feels additive, not withheld: the player on the free track still earns real things; the player on the premium track earns real things faster and in greater variety.

### 2.3 The Urgency of the End-of-Season Deadline

Six weeks is long enough to complete the track casually (approximately 4 matches per day) but short enough that skipping a week creates genuine pressure. The 72-hour expiry warning before season end is a push notification and an in-app banner: "Season ends in 3 days — claim your rewards now." Unclaimed rewards are genuinely forfeited. This is not a dark pattern — it is the honest contract of a limited-time track, stated clearly at purchase and at season launch. Players who understand the deadline feel urgency; players who do not notice lose some Coins and an emote, not a character or a Legendary skin (those are claimable the moment the tier is reached, not at season end).

The season end itself is clean. At the exact `endAt` timestamp, progress resets. The new season's splash screen is ready. The cycle begins again.

### 2.4 The Pride in Exclusive Rewards

Rewards on the Battle Pass track — particularly the exclusive cosmetics and the Tier 30 Legendary skin — are permanent exclusives. They do not return to the shop. They do not appear in future seasons. A player wearing the Season 1 Legendary on Nyx signals that they played during Season 1 and climbed to Tier 30 Premium. That signal has social value that a purchasable skin does not. The exclusivity is the point. The Battle Pass economy depends on players feeling that completing the track is an achievement worth displaying, not just a transaction.

---

## 3. Detailed Rules

### 3.1 Season Structure

- **Duration**: Each season runs for exactly **42 days (6 weeks)**.
- **Dates**: `startAt` and `endAt` are Remote Config **cold keys** set before each season. They are ISO 8601 UTC timestamps.
- **No extensions**: Season end dates are never extended mid-season. The 42-day window is final at season launch.
- **Season ID**: Each season has a unique `seasonId` string (e.g., `"s1-2026"`, `"s2-2026"`). The `seasonId` is set in `battle_pass_seasons` and in Remote Config cold key `battlePass.currentSeasonId`.
- **Season state transitions**:
  - `UPCOMING`: `startAt` is in the future. Battle Pass tab shows countdown.
  - `ACTIVE`: `now >= startAt && now < endAt`. Normal gameplay. Battle Pass purchasable.
  - `ENDING_SOON`: `endAt - now <= 72 hours`. Push notification + in-app banner triggered.
  - `ENDED`: `now >= endAt`. All progress reset. No BPXP granted. Battle Pass not purchasable.

### 3.2 Track Structure

The Battle Pass track has **30 tiers**. Each tier contains two reward slots:

| Column | Description |
|---|---|
| **Free Reward** | Available to every player who reaches the tier, regardless of Battle Pass ownership |
| **Premium Reward** | Available only to players who have purchased the Battle Pass (`isPremium = true`) |

Owning the Battle Pass unlocks the Premium Reward column for all tiers simultaneously. If a player purchases the Battle Pass after reaching Tier 15, Premium Rewards for Tiers 1–15 become immediately claimable.

### 3.3 Progress Mechanic

#### BPXP Earn

Players earn **Battle Pass XP (BPXP)** upon match completion. BPXP is granted by the Battle Pass system when it receives the `MATCH_REWARD_GRANTED` internal event emitted by the Reward System. The Battle Pass system is a **subscriber/observer** — it hooks into the event bus; it does not modify, call, or import the Reward System.

BPXP is earned for every completed match:
- Win outcomes apply `WIN_BPXP_MULTIPLIER` to the mode's base BPXP.
- Loss/draw outcomes apply no multiplier (multiplier = 1.0).

**Idempotency**: Every BPXP credit from a match is keyed by `matchId` (from the `MATCH_REWARD_GRANTED` event payload). Before applying a BPXP credit the server checks whether a credit for this `matchId` already exists for the player:

```sql
INSERT INTO battle_pass_bpxp_credits (user_id, season_id, match_id, source, bpxp_amount, created_at)
VALUES ($userId, $seasonId, $matchId, 'match', $bpxpAmount, NOW())
ON CONFLICT (user_id, match_id, source) DO NOTHING;
```

If the INSERT is a no-op (conflict on `(user_id, match_id, source: 'match')`), the BPXP grant is skipped entirely. This prevents a re-emitted `MATCH_REWARD_GRANTED` event from double-counting BPXP.

See §4 for exact formulas.

#### Quest Bonus BPXP (Alpha Scope: Included)

Quest completion may grant bonus BPXP. When a quest completes, the Quest System calls `battlePassService.grantBonusBpxp({ playerId, questId, bpxpAmount })`. This is a direct call from Quest System to Battle Pass Service, not via the `MATCH_REWARD_GRANTED` event. Bonus BPXP amounts are defined in the Quest System GDD; the Battle Pass Service executes the grant and idempotency-checks it by `questId`.

#### Tier Unlock

When a player's cumulative `bpxpTotal` crosses a tier threshold, that tier is **automatically unlocked** (`currentTier` advances). Tier unlock is computed server-side when BPXP is added. There is no separate "unlock" player action — reaching the threshold is sufficient. The Battle Pass UI shows newly unlocked tiers with a "Claim!" CTA.

#### Tier Reward Claiming

Unlocking a tier does NOT auto-grant the reward. The player must explicitly tap **"Claim"** on each tier in the Battle Pass UI. The client calls `POST /battle-pass/claim` with `{ seasonId, tier }`. The server validates:
1. `currentTier >= tier` (player has reached this tier)
2. Tier is not already in `claimedTiers[]`
3. If premium reward: `isPremium = true`
4. Season is `ACTIVE` or `ENDING_SOON` (cannot claim in `ENDED` season)

On successful validation, the server grants the reward through the appropriate authority (Coins via Reward System's grant function; items/characters via Inventory System's `grantItem`; exclusive cosmetics via Inventory System) and appends the tier to `claimedTiers[]` atomically. The client receives confirmation and the reward animates into the player's inventory.

### 3.4 Tier Reward Table

All BPXP values shown are **cumulative** (total BPXP required from season start to unlock that tier). Tier 1 requires 200 BPXP; each subsequent tier requires 200 BPXP more (flat rate). See §4 for tuning rationale.

`BP-EXCL` prefix = Battle Pass exclusive cosmetic, not obtainable elsewhere.

| Tier | Cumulative BPXP | Free Reward | Premium Reward |
|---|---|---|---|
| 1 | 200 | 100 Coins | BP-EXCL Spray: "BRAWL!" |
| 2 | 400 | BP-EXCL Avatar Border: Season Bronze | 50 Diamonds |
| 3 | 600 | 150 Coins | BP-EXCL Emote: Victory Dance |
| 4 | 800 | Common Skin: Vex "Street Punk" (100D value) | 100 Coins |
| 5 | 1,000 | 200 Coins | 50 Diamonds |
| 6 | 1,200 | **Fen** (Trickster — earnable character unlock) | BP-EXCL Spray: "GG" |
| 7 | 1,400 | 150 Coins | Rare Skin: Zook "Nightwatch" (250D value) |
| 8 | 1,600 | BP-EXCL Emote: Taunt | 200 Coins |
| 9 | 1,800 | 200 Coins | 100 Diamonds |
| 10 | 2,000 | Common Skin: Sera "Healer Blue" (100D value) | BP-EXCL Avatar Border: Season Silver |
| 11 | 2,200 | 250 Coins | 150 Coins |
| 12 | 2,400 | BP-EXCL Spray: "Headshot" | 50 Diamonds |
| 13 | 2,600 | 200 Coins | BP-EXCL Emote: Stunned |
| 14 | 2,800 | **Grim** (Tank — earnable character unlock) | Rare Skin: Fen "Shadow Step" (250D value) |
| 15 | 3,000 | 300 Coins | 100 Diamonds |
| 16 | 3,200 | BP-EXCL Emote: Celebration | 200 Coins |
| 17 | 3,400 | 250 Coins | BP-EXCL Avatar Border: Season Gold |
| 18 | 3,600 | Common Skin: Grim "Iron Brute" (100D value) | 100 Diamonds |
| 19 | 3,800 | 300 Coins | BP-EXCL Spray: "Season Champion" |
| 20 | 4,000 | **Dash** (Speedster — earnable character unlock) | Epic Skin: Dash "Afterburn" (500D value) |
| 21 | 4,200 | 250 Coins | 150 Diamonds |
| 22 | 4,400 | BP-EXCL Emote: Air Guitar | 300 Coins |
| 23 | 4,600 | 300 Coins | BP-EXCL Spray: "Unstoppable" |
| 24 | 4,800 | Rare Skin: Vex "Neon Brawler" (250D value) | 150 Diamonds |
| 25 | 5,000 | 350 Coins | BP-EXCL Avatar Border: Season Platinum |
| 26 | 5,200 | 300 Coins | 200 Diamonds |
| 27 | 5,400 | BP-EXCL Emote: Crown Flex | Epic Skin: Sera "Arcane Medic" (500D value) |
| 28 | 5,600 | 350 Coins | 200 Diamonds |
| 29 | 5,800 | BP-EXCL Spray: "Legend" | BP-EXCL Avatar Border: Season Diamond |
| 30 | 6,000 | Epic Skin: Nyx "Void Walker" (500D value) | **Legendary Skin: Nyx "Eternal Shadow"** (BP-EXCL, 1000D tier) |

**Free track total value (Coins only):** 100+150+200+200+150+200+300+250+300+350+350 = 2,550 Coins + 3 earnable characters (Fen, Grim, Dash) + 5 skins + 5 exclusive cosmetics.

**Premium track additional value:** ~1,350 Diamonds + 4 skins (including 2 Epic, 1 Legendary) + 10 exclusive cosmetics.

> **Design note — earnable characters on free track:** Fen (Tier 6), Grim (Tier 14), and Dash (Tier 20) appear as free track rewards. Players who have already purchased these characters via Coins receive the equivalent Coin value as compensation: Fen → 800 Coins, Grim → 600 Coins, Dash → 1,200 Coins. The server's `grantItem` pipeline handles this via the duplicate-grant compensation path in the Inventory System.

### 3.5 Battle Pass Purchase

- **Cost**: `BATTLE_PASS_DIAMOND_COST` Diamonds (default: **950 Diamonds**).
- **Timing**: Purchasable at any point while the season is `ACTIVE` or `ENDING_SOON`. Not purchasable once the season is `ENDED`.
- **Purchase flow**:
  1. Player taps "Get Battle Pass" in the Battle Pass UI tab.
  2. Client calls `POST /battle-pass/purchase` with `{ seasonId }`.
  3. Server validates: season is `ACTIVE` or `ENDING_SOON`; player does not already own the pass (`isPremium = false`).
  4. Server calls Currency System `spendCurrency` with `{ playerId, currency: "diamonds", amount: BATTLE_PASS_DIAMOND_COST, source: "battle_pass_purchase", idempotency_key: "bp_purchase:{seasonId}:{playerId}" }`.
  5. On successful spend, server sets `isPremium = true` in `battle_pass_progress` within the same DB transaction.
  6. Server returns `{ success: true, currentTier, retroactiveClaimableTiers: [...] }`.
  7. Client navigates to Battle Pass screen; all premium reward slots for Tier 1 through `currentTier` show "Claim!" CTA.
- **Retroactive unlock**: If a player purchases the Battle Pass at Tier 12, Premium Rewards for Tiers 1–12 become immediately claimable. The server returns `retroactiveClaimableTiers: [1,2,...,12]` in the purchase response. The client highlights all retroactively unlocked tiers.
- **RevenueCat integration**: The Battle Pass is a non-consumable in-app purchase product registered in RevenueCat (`product_id: "battle_pass_s{N}"` where N = season number). Purchase fulfillment follows the IAP System's 8-step exactly-once pipeline via the Purchase Fulfillment system. The Diamond spend for the Battle Pass is executed by Purchase Fulfillment after webhook validation — not by the client directly.

> **Clarification on purchase path**: There are two ways a player acquires the Battle Pass:
> 1. **IAP (real money)**: Player pays a real-money price for the Battle Pass bundle (e.g., $9.99 for 950D equivalent + Battle Pass). Revenue flows through RevenueCat → IAP System → Purchase Fulfillment, which calls `battlePassService.activatePremium()` directly from the `product_grant_definitions` table. No Diamond spend occurs in this path.
> 2. **Diamond spend (in-wallet)**: Player has 950D already in their wallet (from a prior pack purchase) and taps "Get Battle Pass." This calls `POST /battle-pass/purchase` and deducts Diamonds via Currency System. This path does NOT go through RevenueCat.
>
> Both paths set `isPremium = true`. Both are idempotent. The `product_grant_definitions` table covers the IAP path; `POST /battle-pass/purchase` covers the Diamond-spend path.

### 3.6 Season End and Progress Reset

At `endAt`:
1. The server sets season state to `ENDED` in Remote Config (or the `endAt` timestamp comparison makes this implicit in all server logic).
2. No further BPXP grants are accepted for this season.
3. No further Battle Pass purchases are accepted for this season.
4. No further tier claims are accepted for this season.
5. 72 hours before `endAt` (i.e., at `endAt - 259200000ms`), a scheduled job fires:
   - Push notification to all players with unclaimed tiers: "Season ends in 3 days! Claim your Battle Pass rewards before they expire."
   - In-app banner state set via Remote Config hot key `battlePass.showEndingSoonBanner = true`.
6. At `endAt`, a season-reset job runs for all players with `battle_pass_progress.seasonId = currentSeasonId`:
   - `currentTier` reset to 0
   - `bpxpTotal` reset to 0
   - `isPremium` reset to `false`
   - `claimedTiers[]` cleared
   - `seasonId` updated to the new season's ID
7. Claimed rewards are permanent. They remain in the player's Inventory/Entitlements and are not affected by season reset.
8. Unclaimed rewards are forfeited. No compensation is issued for unclaimed rewards.
9. Player Profile `battlePassTier` and `battlePassSeasonId` fields are updated to the new season's starting values (tier 0, new seasonId) as part of the reset job.

### 3.7 PostgreSQL Schema

```sql
-- Tracks each player's progress within a season
CREATE TABLE battle_pass_progress (
  user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  season_id       TEXT        NOT NULL,  -- e.g. "s1-2026"
  current_tier    SMALLINT    NOT NULL DEFAULT 0,
  bpxp_total      INTEGER     NOT NULL DEFAULT 0,
  is_premium      BOOLEAN     NOT NULL DEFAULT FALSE,
  claimed_tiers   SMALLINT[]  NOT NULL DEFAULT '{}',
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, season_id)
);

CREATE INDEX idx_bpp_season_id ON battle_pass_progress (season_id);
CREATE INDEX idx_bpp_user_id   ON battle_pass_progress (user_id);

-- Season definitions — one row per season
CREATE TABLE battle_pass_seasons (
  season_id    TEXT        PRIMARY KEY,     -- e.g. "s1-2026"
  start_at     TIMESTAMPTZ NOT NULL,
  end_at       TIMESTAMPTZ NOT NULL,
  reward_table JSONB       NOT NULL,        -- Array of 30 tier objects (see §3.4)
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_season_dates CHECK (end_at > start_at)
);
```

**Reward table JSONB schema** (one element per tier):

```typescript
interface BattlePassTierReward {
  tier: number;               // 1–30
  bpxpCumulative: number;     // Cumulative BPXP required to unlock
  freeReward: RewardItem;
  premiumReward: RewardItem;
}

interface RewardItem {
  type: "coins" | "diamonds" | "character" | "skin" | "cosmetic";
  itemId: string;             // e.g. "coins", "diamonds", "character:fen", "skin_nyx_eternal_shadow"
  amount?: number;            // For coins/diamonds
  displayName: string;        // e.g. "100 Coins", "Nyx — Eternal Shadow"
  isExclusive: boolean;       // true = BP-EXCL; cannot be purchased in shop
  compensationCoins?: number; // If type="character" and player already owns it
}
```

### 3.8 BPXP Earn Rates by Mode

| Game Mode | `BASE_BPXP` | Win BPXP (× `WIN_BPXP_MULTIPLIER`) | Loss/Draw BPXP |
|---|---|---|---|
| 1v1 Duel | 30 | 45 | 30 |
| 3v3 Squad Brawl | 40 | 60 | 40 |
| 8-Player FFA | 35 | 53 (floor) | 35 |

`WIN_BPXP_MULTIPLIER` default: **1.5**

> **Design rationale**: Squad Brawl has the highest base earn rate because it has the longest average match duration. FFA is intermediate. Duel is lowest because matches are short. Win bonus at 1.5× rewards competitive engagement without making losses feel unrewarding.

### 3.9 Tier Unlock vs. Tier Claim Distinction

These are two separate concepts and must never be conflated in server logic or UI:

| Concept | Definition | When It Happens | Player Action Required |
|---|---|---|---|
| **Tier Unlock** | `currentTier` advances to N; the rewards for tier N are now eligible to claim | Automatically, when `bpxpTotal >= bpxpCumulative[N]` | None — server-side automatic |
| **Tier Claim** | The reward for tier N is granted to the player's inventory | When player taps "Claim" on tier N in the Battle Pass UI | Yes — explicit tap required |

The Battle Pass UI displays:
- **Locked** (grey, padlock icon): Tier not yet unlocked (`currentTier < tier`)
- **Claim!** (highlighted, animated CTA): Tier unlocked, reward not yet claimed (`currentTier >= tier && tier not in claimedTiers[]`)
- **Claimed** (greyed out, checkmark): Reward already claimed (`tier in claimedTiers[]`)

---

## 4. Formulas

### 4.1 BPXP Earned Per Match

```
bpxpEarned(mode, outcome) = floor(BASE_BPXP[mode] × (outcome == "win" ? WIN_BPXP_MULTIPLIER : 1.0))
```

#### Variable Definitions

| Variable | Description | Default Value |
|---|---|---|
| `BASE_BPXP["duel_1v1"]` | Base BPXP for completing a 1v1 Duel | `30` |
| `BASE_BPXP["squad_3v3"]` | Base BPXP for completing a 3v3 Squad Brawl | `40` |
| `BASE_BPXP["ffa_8"]` | Base BPXP for completing an 8-Player FFA | `35` |
| `WIN_BPXP_MULTIPLIER` | Multiplier applied to BPXP on a win outcome | `1.5` |
| `outcome` | Match result: `"win"`, `"loss"`, or `"draw"` | From `MATCH_REWARD_GRANTED` event |

**Example — 1v1 Duel win:**
```
bpxpEarned("duel_1v1", "win") = floor(30 × 1.5) = floor(45.0) = 45 BPXP
```

**Example — 3v3 Squad Brawl loss:**
```
bpxpEarned("squad_3v3", "loss") = floor(40 × 1.0) = 40 BPXP
```

**Example — 8-Player FFA win:**
```
bpxpEarned("ffa_8", "win") = floor(35 × 1.5) = floor(52.5) = 52 BPXP
```

> **Note on draw outcome**: Draws apply the loss multiplier (1.0), same as a loss. `bpxpEarned("duel_1v1", "draw") = 30 BPXP`.

---

### 4.2 Tier Unlock Formula

```
tiersUnlocked(bpxpTotal) = floor(bpxpTotal / TIER_BPXP_REQUIRED)
```

| Variable | Description | Default Value |
|---|---|---|
| `TIER_BPXP_REQUIRED` | BPXP required per tier (flat rate — all 30 tiers cost the same) | `200` |
| `bpxpTotal` | Player's cumulative BPXP this season | From `battle_pass_progress.bpxp_total` |

The flat rate of 200 BPXP per tier was chosen over a linear ramp because:
1. It is simple to communicate to players ("200 BPXP per tier, always").
2. It makes late-season progress feel as fast as early-season progress.
3. Tuning a single constant is safer than tuning a ramp table.

**Example:**
```
Player has bpxpTotal = 850.
tiersUnlocked(850) = floor(850 / 200) = floor(4.25) = 4 tiers unlocked (Tier 4 reached, working toward Tier 5).
```

---

### 4.3 Total BPXP to Complete Season

```
BPXP_TO_COMPLETE_SEASON = TIER_BPXP_REQUIRED × 30 = 200 × 30 = 6,000 BPXP
```

#### Tuning Constraint — Completable at ~4 matches/day over 6 weeks

A casual player who plays 4 matches per day, 7 days per week, over 42 days plays:
```
totalMatches = 4 × 42 = 168 matches
```

For the track to be completable at this pace, the average BPXP per match must be at least:
```
minAverageBpxpPerMatch = 6,000 / 168 = 35.71 BPXP/match
```

A player who plays exclusively 1v1 Duels (lowest mode), with a 50/50 win rate, earns on average:
```
avgBpxp_duel = (45 + 30) / 2 = 37.5 BPXP/match
```

Since 37.5 > 35.71, even the lowest-BPXP mode with a 50% win rate supports season completion at 4 matches/day. The track is achievable by casual players; it is not a hardcore grind.

---

### 4.4 Session-Count-to-Completion Validation

**Target**: Complete all 30 tiers in 42 days playing 4 matches/day.

| Mode | Win Rate | Avg BPXP/Match | Matches to Tier 30 (6,000 BPXP) | Days at 4 Matches/Day |
|---|---|---|---|---|
| 1v1 Duel (50% win) | 50% | (45+30)/2 = 37.5 | ceil(6000/37.5) = 160 | 160/4 = **40 days** |
| 1v1 Duel (0% win) | 0% | 30 | ceil(6000/30) = 200 | 200/4 = **50 days** ⚠ |
| 3v3 Squad Brawl (50% win) | 50% | (60+40)/2 = 50 | ceil(6000/50) = 120 | 120/4 = **30 days** |
| 8-Player FFA (50% win) | 50% | (52+35)/2 = 43.5 | ceil(6000/43.5) = 138 | 138/4 = **34.5 days** |

> **0% win rate in Duel is an out-of-range edge case**: A player with 0% win rate who plays exclusively Duels requires 50 days, which slightly exceeds the 42-day season. This is acceptable — the system is tuned for players with at least some wins. Players with 0% win rates in competitive matchmaking is not a design-supported steady state; such players would be served by better mode selection (Squad Brawl or FFA have higher loss BPXP). The minimum-win-rate design intent is: "a player winning at least 30% of their Duel matches can complete the track in 42 days at 4 matches/day."

**30% win rate in Duel validation:**
```
avgBpxp_duel_30pct = (0.30 × 45) + (0.70 × 30) = 13.5 + 21 = 34.5 BPXP/match
daysToComplete = ceil(6000 / 34.5) / 4 = ceil(173.9) / 4 = 174 / 4 = 43.5 days
```
Just over 42 days — slightly above target. To ensure this edge case is covered, Quest System bonus BPXP (§3.3) provides the buffer: a player completing daily quests earns bonus BPXP that covers the shortfall. The design intent is that the core match BPXP rate handles 50%+ win-rate players; quests provide the buffer for lower win-rate players.

---

### 4.5 Example Calculation — 4 Duels/Day, 2 Wins + 2 Losses

**Setup:**
- Player plays 4 × 1v1 Duels per day (2 wins, 2 losses)
- Season duration: 42 days
- No quest BPXP bonus (conservative estimate)

**Daily BPXP:**
```
dailyBpxp = (2 × 45) + (2 × 30)
           = 90 + 60
           = 150 BPXP/day
```

**Season total BPXP:**
```
seasonBpxp = 150 × 42 = 6,300 BPXP
```

**Tiers reached:**
```
tiersUnlocked(6,300) = floor(6,300 / 200) = floor(31.5) = 31
```
→ But the track caps at 30 tiers, so the player reaches **Tier 30 (all tiers complete)** with 300 BPXP to spare.

**Day on which Tier 30 is reached:**
```
bpxpForTier30 = 6,000 BPXP
daysRequired  = ceil(6,000 / 150) = ceil(40) = 40 days
```
The player completes the track on **Day 40 of 42** — 2 days before season end. Comfortable completion window.

---

### 4.6 Retroactive Premium Unlock Value Formula

When a player purchases the Battle Pass at Tier N (already having earned N tiers), the number of Premium Rewards immediately claimable is:

```
retroactiveClaimable = N  (tiers 1 through N are all immediately claimable)
```

No additional BPXP formula is needed — tier unlock is already computed from `bpxpTotal`. The retroactive unlock simply sets `isPremium = true`, which makes the already-unlocked premium tiers eligible for claiming.

---

## 5. Edge Cases

### 5.1 Battle Pass Purchased After Season Ends

**Scenario:** A player attempts to purchase the Battle Pass after the season `endAt` timestamp has passed.

**Resolution:**
1. Server receives `POST /battle-pass/purchase` with `{ seasonId }`.
2. Server loads `battle_pass_seasons` row for `seasonId` and checks `end_at < NOW()`.
3. If `end_at < NOW()`: server rejects with HTTP 400 and error code `SEASON_ENDED`.
4. Response body: `{ error: "SEASON_ENDED", message: "This season has ended. The Battle Pass is no longer available for purchase." }`.
5. Client displays a toast: "Season has ended — the Battle Pass is no longer available." Battle Pass tab shows the "Season Ended" state with a "New season coming soon" message.
6. No Diamond deduction occurs. No state changes. The rejection is idempotent.

---

### 5.2 Claim Attempted for Un-Reached Tier

**Scenario:** A player sends `POST /battle-pass/claim` with `{ seasonId, tier: 15 }` but their `currentTier = 10`.

**Resolution:**
1. Server loads `battle_pass_progress` for `(userId, seasonId)`.
2. Server checks `current_tier >= tier` → `10 >= 15` is false.
3. Server rejects with HTTP 403 and error code `TIER_NOT_REACHED`.
4. Response body: `{ error: "TIER_NOT_REACHED", message: "You have not yet reached Tier 15." }`.
5. Client treats this as a no-op — the Claim button for unreached tiers should be disabled in the UI, so this server-side rejection is a defense-in-depth check against tampered requests.
6. No reward is granted. No `claimedTiers` mutation occurs.

---

### 5.3 Claim Attempted for Premium Reward Without Battle Pass Ownership

**Scenario:** A player sends `POST /battle-pass/claim` with `{ seasonId, tier: 7, track: "premium" }` but `isPremium = false`.

**Resolution:**
1. Server loads `battle_pass_progress` for `(userId, seasonId)`.
2. Server checks `is_premium = true` for a premium track claim → `false` fails the check.
3. Server rejects with HTTP 403 and error code `PREMIUM_REQUIRED`.
4. Response body: `{ error: "PREMIUM_REQUIRED", message: "Purchase the Battle Pass to claim Premium rewards." }`.
5. Client shows a "Get the Battle Pass" prompt modal with the purchase CTA.
6. No reward is granted. No `claimedTiers` mutation occurs.

---

### 5.4 Reward Grant Fails During Claim

**Scenario:** The server validates a claim request (tier reached, not yet claimed, premium if needed), begins the grant, but the downstream grant call fails (e.g., Currency System returns a transient error for a Coin grant, or Inventory System `grantItem` fails).

**Resolution:**
1. The server begins a PostgreSQL transaction that includes both:
   a. Calling the grant function (Coins via Reward System's grant; items via `grantItem`).
   b. Appending `tier` to `battle_pass_progress.claimed_tiers[]`.
2. If step (a) fails with a transient error, the entire transaction is rolled back.
3. `claimed_tiers[]` is NOT updated. The tier remains in "Claim!" state.
4. Server returns HTTP 500 with error code `GRANT_FAILED`.
5. Response body: `{ error: "GRANT_FAILED", message: "Reward delivery failed. Please try again." }`.
6. Client shows a retry-able error toast: "Could not claim reward — tap to retry."
7. The player can retry the claim; the server will re-validate (tier is still not in `claimedTiers[]`) and attempt the grant again.
8. If the grant call is idempotent (Inventory `grantItem` uses idempotency keys), a retry will either complete the grant or detect the prior successful grant and return success. The `claimedTiers[]` append is then committed in the second attempt.

> **Idempotency key for claim grants**: `"bp_claim:{seasonId}:{userId}:{tier}:{track}"` (e.g., `"bp_claim:s1-2026:uuid:7:premium"`). This ensures that even if a network error causes the client to retry after a successful server-side grant, the grant function is not executed twice.

---

### 5.5 Season Boundary Mid-Match

**Scenario:** A player starts a match in Season 1 (`seasonId = "s1-2026"`). Mid-match, the `endAt` timestamp for Season 1 passes. The match ends and the `MATCH_REWARD_GRANTED` event fires — which season receives the BPXP?

**Resolution:**
1. When the Battle Pass system's event observer receives `MATCH_REWARD_GRANTED`, it reads the `matchStartedAt` field directly from the `MATCH_REWARD_GRANTED` event payload. **The authoritative source for season-boundary attribution is `MATCH_REWARD_GRANTED.matchStartedAt`** — not `match_result.completedAt`, not the Match Server session record, and not any other field.
2. BPXP is attributed to the season that was **ACTIVE when the match started** — not when it ended.
3. Specifically: the observer looks up the `battle_pass_seasons` row where `start_at <= MATCH_REWARD_GRANTED.matchStartedAt < end_at`. If `MATCH_REWARD_GRANTED.matchStartedAt` falls within Season 1's window, BPXP goes to Season 1 progress.
4. If Season 1 is `ENDED` at attribution time (i.e., the reset job has already run), the BPXP grant for Season 1 is silently dropped (the old season row's progress cannot be incremented post-reset; Season 2 should not receive Season 1 match BPXP). A `WARN` log is emitted: `battle_pass_season_boundary_drop { matchId, playerId, matchStartedAt, seasonId }`.
5. In practice, the season-reset job is designed to run at `endAt + 5 minutes` to provide a grace buffer for in-flight matches. Matches that last longer than 5 minutes after season end are exceedingly rare and are acceptable to drop.

---

### 5.6 Duplicate Claim Request

**Scenario:** A player taps "Claim" rapidly twice, or a network retry causes the same `POST /battle-pass/claim` request to reach the server twice for the same `{ seasonId, tier, track }`.

**Resolution:**
1. The server's claim endpoint performs an atomic check-and-set:
   ```sql
   UPDATE battle_pass_progress
   SET claimed_tiers = array_append(claimed_tiers, $tier),
       updated_at = NOW()
   WHERE user_id = $userId
     AND season_id = $seasonId
     AND NOT ($tier = ANY(claimed_tiers))
   RETURNING *;
   ```
2. If the `WHERE` clause matches (tier not yet in `claimedTiers[]`), the UPDATE succeeds and the grant proceeds.
3. If the `WHERE` clause matches zero rows (tier is already in `claimedTiers[]`), the UPDATE returns 0 rows. The server detects this and returns HTTP 200 with `{ status: "already_claimed" }` — treating it as an idempotent success (the player already has the reward; no error needed).
4. The grant function's idempotency key (§5.4) provides a second layer: even if two concurrent requests both pass the `claimedTiers[]` check before either commits (due to a race between two simultaneous requests), the grant function's idempotency key ensures the reward is granted only once.
5. The client on receiving `already_claimed` updates the tier's UI state to "Claimed" without showing an error.

---

### 5.7 Battle Pass Refunded via IAP

**Scenario:** A player purchased the Battle Pass as a real-money IAP product. The player subsequently files a refund with Apple/Google and receives approval. RevenueCat fires a refund webhook.

**Resolution:**
1. RevenueCat fires `CANCELLATION` (refund) webhook event to the BRAWLZONE server.
2. The IAP System processes the webhook and identifies the product as a Battle Pass purchase.
3. The server calls `battlePassService.revokePremium({ userId, seasonId, reason: "refund" })`.
4. `battle_pass_progress.is_premium` is set to `false` for `(userId, seasonId)`.
5. **Already-claimed Premium Rewards are NOT revoked.** Items granted to inventory are permanent (idempotency and fraud prevention — reversing inventory is complex and the value at risk is low).
6. Unclaimed Premium Rewards for all tiers become inaccessible: the UI shows premium slots as "locked" again since `isPremium = false`.
7. The `iap_refund_flags` table records the refund (per Purchase Fulfillment GDD §3.x).
8. Analytics event fired: `battle_pass_refund { userId, seasonId, tiersAlreadyClaimed, premiumRewardsAlreadyClaimed }` for fraud monitoring.
9. If the same player attempts to repurchase the Battle Pass for the same season, the server allows it (refund does not permanently block repurchase for the active season).

---

## 6. Dependencies

### 6.1 Upstream — Battle Pass Consumes

| System | What Battle Pass Needs | Interface | Notes |
|---|---|---|---|
| **Reward System** (`reward-system.md`) | `MATCH_REWARD_GRANTED` internal event: `{ matchId, playerId, gameMode, outcome, coinReward, serverTimestamp }` | Internal event bus subscription (observer pattern — Reward System emits, Battle Pass subscribes; zero coupling in Reward System code) | Sole trigger for BPXP earn per match. Battle Pass MUST NOT modify Reward System code. |
| **Reward System** (`reward-system.md`) | `grantQuestReward`-style Coin grant function for Battle Pass tier Coin rewards | Direct server-to-server call: `rewardService.grantBattlePassReward({ playerId, coinAmount, source: "battle_pass_tier", idempotency_key })` | Reward System is the canonical Coin grant authority. Battle Pass calls it for Coin tier rewards; does not call Currency System directly for Coins. |
| **Inventory / Entitlements** (`inventory-entitlements.md`) | `grantItem` — the strict 11-step idempotent grant pipeline | `inventoryService.grantItem({ userId, itemId, source: "battle_pass_tier", idempotency_key })` | Used for skin, character, cosmetic tier rewards. Handles duplicate-ownership compensation automatically. |
| **Currency System** (`currency-system.md`) | `spendCurrency` — Diamond deduction for Battle Pass purchase (Diamond-spend path only) | `currencyService.spendCurrency({ playerId, currency: "diamonds", amount: BATTLE_PASS_DIAMOND_COST, ... })` | Used only for the in-wallet Diamond purchase path, not the IAP path. |
| **IAP System + Purchase Fulfillment** (`iap-system.md`, `purchase-fulfillment.md`) | RevenueCat webhook fulfillment for real-money Battle Pass product; `product_grant_definitions` entry for Battle Pass | `battlePassService.activatePremium()` called by Purchase Fulfillment's grant pipeline | IAP path for Battle Pass acquisition. `product_grant_definitions` maps `"battle_pass_s{N}"` → `activatePremium`. |
| **Remote Config** (`remote-config.md`) | Cold keys: `battlePass.currentSeasonId`, `battlePass.startAt`, `battlePass.endAt`, `battlePass.rewardTable`; Hot key: `battlePass.showEndingSoonBanner` | Remote Config read at server startup (cold) or on next read cycle (hot) | Season definition and reward table loaded at startup. Banner flag can be pushed mid-session. |
| **Quest / Mission System** (`quest-mission.md`) | Optional: Quest System calls `battlePassService.grantBonusBpxp()` on quest completion | Direct server-to-server call from Quest System to Battle Pass Service | Quest bonus BPXP is in Alpha scope (§3.3). Battle Pass does not call Quest System. |
| **Player Profile** (`player-profile.md`) | `battlePassTier` and `battlePassSeasonId` fields; Redis cache; `profile:refresh` event | PostgreSQL read/write; `battle_pass_progress` table; Redis cache invalidation on any progress write | Profile fields are updated when tier advances or season resets. |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | Emit Tier 0 events: `battle_pass_purchased`, `battle_pass_tier_claimed`; Tier 1 event: `battle_pass_progress_viewed` | Async fire-and-forget via analytics emitter | PII policy: `playerId` UUID only; no display names in event payloads. |
| **Logging / Monitoring** (`logging-monitoring.md`) | ILogger interface for WARN and ERROR logs | Standard ILogger interface | Key logs: `battle_pass_season_boundary_drop` (WARN), `battle_pass_grant_failed` (ERROR), `battle_pass_refund` (INFO). |
| **Push Notifications** (`push-notification.md`) | 72-hour end-of-season expiry warning push notification | Push notification service called by the ending-soon scheduled job | Notification copy: "Season ends in 3 days — claim your Battle Pass rewards!" |

### 6.2 Downstream — Battle Pass Produces / Notifies

| System | What Battle Pass Provides | Interface | Notes |
|---|---|---|---|
| **Player Profile** (`player-profile.md`) | Updates `battlePassTier`, `battlePassSeasonId` on tier advancement; triggers `profile:refresh` Socket.io event | PostgreSQL write to `battle_pass_progress`; cache invalidation causes `profile:refresh` | Client receives updated tier number in profile push. |
| **Shop & Offers Screen** (`shop-offers-screen.md`) | Battle Pass tab content: current season data, player tier, `isPremium` status, 30-tier reward table, purchase CTA | `GET /battle-pass/status` API endpoint; returns `BattlePassStatusResponse` | Replaces the "Coming Soon" stub in the Battle Pass tab. |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | `battle_pass_purchased { userId, seasonId, purchasePath }`, `battle_pass_tier_claimed { userId, seasonId, tier, track, rewardType }`, `battle_pass_progress_viewed { userId, seasonId, currentTier }` | Async fire-and-forget | Tier 0 events are unconsented; Tier 1 requires consent per analytics-telemetry.md §3.x. |
| **IAP / Purchase Fulfillment** | Provides `activatePremium` endpoint for Purchase Fulfillment to call after webhook validation | `POST /internal/battle-pass/activate-premium` — internal route, not exposed to client | Purchase Fulfillment calls this after verifying the RevenueCat webhook. |

### 6.3 API Endpoints

```typescript
// Public endpoints (authenticated, rate-limited)
GET    /battle-pass/status              // Player's current season status
POST   /battle-pass/purchase            // Diamond-spend path: deduct Diamonds, set isPremium
POST   /battle-pass/claim               // Claim a tier reward
GET    /battle-pass/seasons/:seasonId   // Season metadata + reward table

// Internal endpoints (server-to-server only; not exposed to client)
POST   /internal/battle-pass/activate-premium  // Called by Purchase Fulfillment after IAP webhook
POST   /internal/battle-pass/grant-bonus-bpxp  // Called by Quest System on quest completion
POST   /internal/battle-pass/season-reset       // Called by the season-end scheduled job
```

```typescript
// BattlePassStatusResponse
interface BattlePassStatusResponse {
  seasonId: string;
  seasonStartAt: string;           // ISO 8601
  seasonEndAt: string;             // ISO 8601
  currentTier: number;             // 0–30
  bpxpTotal: number;
  bpxpToNextTier: number;          // TIER_BPXP_REQUIRED - (bpxpTotal % TIER_BPXP_REQUIRED)
  isPremium: boolean;
  claimedTiers: number[];          // tiers already claimed (free + premium combined)
  seasonState: "UPCOMING" | "ACTIVE" | "ENDING_SOON" | "ENDED";
  rewardTable: BattlePassTierReward[];
}
```

---

## 7. Tuning Knobs

All values are **Remote Config cold keys** unless explicitly marked as **hot**.

| Parameter | Remote Config Key | Default | Safe Range | Hot/Cold | What Breaks Outside Range |
|---|---|---|---|---|---|
| Diamond cost of Battle Pass | `battlePass.diamondCost` | `950` | 500–1500 | Cold | Below 500D: below two IAP packs — perceived as too cheap, revenue risk. Above 1500D: exceeds a single $9.99 pack; blocks casual spenders. Should align with an IAP pack price point. |
| BPXP per tier (flat) | `battlePass.tierBpxpRequired` | `200` | 100–400 | Cold | Below 100: track completes in ~18 days at 4 matches/day — too fast, reduced seasonal longevity. Above 400: track requires ~8 matches/day to complete — becomes a hardcore grind, alienates casual players. |
| Base BPXP — 1v1 Duel | `battlePass.baseBpxp.duel` | `30` | 15–60 | Cold | Below 15: Duel economy lags other modes significantly. Above 60: exceeds Squad Brawl base rate despite shorter match duration; Duel becomes primary farm mode. |
| Base BPXP — 3v3 Squad Brawl | `battlePass.baseBpxp.squadBrawl` | `40` | 20–80 | Cold | Below 20: Squad Brawl punished for its cooperation overhead. Above 80: Squad Brawl trivialises the track; other modes unplayed. |
| Base BPXP — 8-Player FFA | `battlePass.baseBpxp.ffa` | `35` | 15–70 | Cold | Below 15: FFA underrewarded given its longer duration. Above 70: FFA dominates economy; mode balance skewed. |
| Win BPXP multiplier | `battlePass.winBpxpMultiplier` | `1.5` | 1.1–2.0 | Cold | Below 1.1: win incentive negligible — defeats the purpose of competitive play. Above 2.0: losses feel punishingly slow; casual players churned. Must be > 1.0. |
| Season duration (days) | `battlePass.seasonDurationDays` | `42` | 28–56 | Cold (new season config) | Below 28: season too short for casual completion; pressure becomes anxiety. Above 56: season too long; players disengage mid-season ("I have plenty of time"). |
| End-of-season warning hours | `battlePass.endingSoonWarningHours` | `72` | 24–168 | Cold | Below 24: insufficient warning for infrequent players. Above 168 (1 week): warning fatigue; urgency diminished. |
| End-of-season banner flag | `battlePass.showEndingSoonBanner` | `false` | `true/false` | **Hot** | N/A — this is a display flag only. Set to `true` 72h before season end by the expiry job. |
| Max claimable tiers per request | `battlePass.maxClaimBatchSize` | `1` | 1–5 | Cold | Above 5: single claim request could trigger 5 inventory grants; server load risk. At 1, each tier is a separate tap — intentional for individual reward celebrations. |
| Quest bonus BPXP per daily quest | `battlePass.questBonusBpxp.daily` | `50` | 0–150 | Cold | 0: disables quest BPXP (quests no longer help Battle Pass). Above 150: 3 daily quests = 450 BPXP — comparable to 10+ match sessions from quests alone; undermines match-play incentive. |
| Quest bonus BPXP per weekly quest | `battlePass.questBonusBpxp.weekly` | `150` | 0–400 | Cold | Above 400: two weekly quests = 800 BPXP — over a full day's match BPXP. Weekly quests should supplement, not substitute, match play. |
| Current season ID | `battlePass.currentSeasonId` | `"s1-2026"` | Any valid season string | Cold | Wrong value causes all progress writes to an incorrect season; catastrophic. Must be updated atomically with `startAt`/`endAt`. |
| Season start timestamp | `battlePass.startAt` | Season-specific | Must be a valid ISO 8601 UTC timestamp in the future at config push time | Cold | Wrong value causes season to start early or late. Never modify mid-season. |
| Season end timestamp | `battlePass.endAt` | Season-specific | Must be `startAt + seasonDurationDays`; never shorten a live season | Cold | Shortening a live season forfeits player rewards without warning — never do this. Extensions are also prohibited by design (§3.1). |

### Remote Config Key Summary

```
battlePass.diamondCost               (cold)
battlePass.tierBpxpRequired          (cold)
battlePass.baseBpxp.duel             (cold)
battlePass.baseBpxp.squadBrawl       (cold)
battlePass.baseBpxp.ffa              (cold)
battlePass.winBpxpMultiplier         (cold)
battlePass.seasonDurationDays        (cold)
battlePass.endingSoonWarningHours    (cold)
battlePass.showEndingSoonBanner      (HOT — pushable mid-session)
battlePass.maxClaimBatchSize         (cold)
battlePass.questBonusBpxp.daily      (cold)
battlePass.questBonusBpxp.weekly     (cold)
battlePass.currentSeasonId           (cold)
battlePass.startAt                   (cold)
battlePass.endAt                     (cold)
```

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and are independently verifiable by automated test or documented manual QA.

### 8.1 Season Lifecycle

**AC-BP-01 — Season state transitions correctly**
- Given: Remote Config cold keys set with `startAt` = future timestamp, `endAt` = `startAt + 42 days`
- When: `GET /battle-pass/status` is called at various times (before `startAt`, after `startAt`, within 72h of `endAt`, after `endAt`)
- Then: Response `seasonState` equals `UPCOMING`, `ACTIVE`, `ENDING_SOON`, and `ENDED` respectively; no mid-season state anomalies observed

**AC-BP-02 — No BPXP granted after season ends**
- Given: Season state is `ENDED`; a `MATCH_REWARD_GRANTED` event arrives for a player
- When: Battle Pass event observer processes the event
- Then: `battle_pass_progress.bpxp_total` is NOT incremented; `WARN` log emitted with `battle_pass_bpxp_dropped_season_ended`; player's tier is unchanged

**AC-BP-03 — Season reset clears all progress fields**
- Given: Season end job runs at `endAt`; a player has `current_tier = 20`, `bpxp_total = 4,200`, `is_premium = true`, `claimed_tiers = [1,2,3,4,5,6,7,8,9,10]`
- When: Season reset job completes for this player
- Then: `current_tier = 0`, `bpxp_total = 0`, `is_premium = false`, `claimed_tiers = []`, `season_id` updated to new season's ID; claimed inventory items remain in player's Inventory/Entitlements unaffected

---

### 8.2 BPXP Earn

**AC-BP-04 — BPXP earned on Duel win**
- Given: A player wins a 1v1 Duel; Battle Pass is in `ACTIVE` season; default config values
- When: `MATCH_REWARD_GRANTED` event fires with `gameMode: "duel_1v1"`, `outcome: "win"`
- Then: `bpxp_total` increases by exactly `floor(30 × 1.5) = 45`; `current_tier` advances if threshold crossed; `updated_at` refreshed

**AC-BP-05 — BPXP earned on Squad Brawl loss**
- Given: A player loses a 3v3 Squad Brawl; `ACTIVE` season
- When: `MATCH_REWARD_GRANTED` event fires with `gameMode: "squad_3v3"`, `outcome: "loss"`
- Then: `bpxp_total` increases by exactly `40` (no win multiplier); `current_tier` advances if threshold crossed

**AC-BP-06 — BPXP earned on FFA win**
- Given: A player wins an 8-Player FFA; `ACTIVE` season
- When: `MATCH_REWARD_GRANTED` event fires with `gameMode: "ffa_8"`, `outcome: "win"`
- Then: `bpxp_total` increases by exactly `floor(35 × 1.5) = 52` (floor of 52.5)

**AC-BP-07 — Draw outcome treated as loss for BPXP**
- Given: A player draws a 1v1 Duel; `ACTIVE` season
- When: `MATCH_REWARD_GRANTED` event fires with `outcome: "draw"`
- Then: `bpxp_total` increases by exactly `30` (base rate, no multiplier)

**AC-BP-08 — Tier auto-unlocks when threshold crossed**
- Given: Player has `bpxp_total = 190`, `current_tier = 0`; wins a Duel (earns 45 BPXP)
- When: BPXP grant is applied (`bpxp_total` becomes 235)
- Then: `tiersUnlocked(235) = floor(235/200) = 1`; `current_tier` advances to 1; `profile:refresh` event emitted; Battle Pass tab shows "Claim!" on Tier 1

**AC-BP-09 — Multiple tiers unlock in single BPXP grant**
- Given: Player has `bpxp_total = 190`, `current_tier = 0`; receives a quest bonus BPXP of 500
- When: Quest bonus BPXP is applied (`bpxp_total` becomes 690)
- Then: `tiersUnlocked(690) = floor(690/200) = 3`; `current_tier` advances to 3; all three tiers show "Claim!" in UI

---

### 8.3 Battle Pass Purchase

**AC-BP-10 — Diamond-spend purchase succeeds during active season**
- Given: Player has `diamond_balance >= BATTLE_PASS_DIAMOND_COST = 950`; season is `ACTIVE`; player's `isPremium = false`
- When: Player calls `POST /battle-pass/purchase`
- Then: `spendCurrency` called with `amount: 950`, `currency: "diamonds"`, `source: "battle_pass_purchase"`; `is_premium` set to `true` in `battle_pass_progress`; response includes `retroactiveClaimableTiers` for all currently unlocked tiers; `battle_pass_purchased` analytics event fired; Diamond balance reduced by 950

**AC-BP-11 — Purchase rejected after season ends**
- Given: Season `endAt` has passed; player attempts `POST /battle-pass/purchase`
- When: Server validates season state
- Then: HTTP 400 returned with `error: "SEASON_ENDED"`; no Diamond deduction; `is_premium` unchanged

**AC-BP-12 — Purchase idempotent for already-premium player**
- Given: Player already has `is_premium = true` for the current season
- When: Player calls `POST /battle-pass/purchase` again (duplicate or retry)
- Then: HTTP 200 returned with `status: "already_premium"`; no second Diamond deduction; no state change; no duplicate analytics event

**AC-BP-13 — Retroactive premium unlock claimable immediately after purchase**
- Given: Player is at `current_tier = 12`, `is_premium = false`; player purchases Battle Pass
- When: Purchase completes (`is_premium` set to `true`)
- Then: Response includes `retroactiveClaimableTiers: [1,2,3,4,5,6,7,8,9,10,11,12]`; `POST /battle-pass/claim` for any tier 1–12 premium reward succeeds immediately; no further BPXP needed

---

### 8.4 Tier Claiming

**AC-BP-14 — Free reward claimed successfully**
- Given: Player has `current_tier = 5`, `is_premium = false`; Tier 5 free reward is 200 Coins; Tier 5 not in `claimed_tiers[]`
- When: Player calls `POST /battle-pass/claim` with `{ seasonId, tier: 5, track: "free" }`
- Then: `rewardService.grantBattlePassReward` called with `coinAmount: 200`; `5` appended to `claimed_tiers[]`; Tier 5 free reward shows "Claimed" in UI; `battle_pass_tier_claimed` analytics event fired; HTTP 200 returned

**AC-BP-15 — Premium reward claimed when isPremium = true**
- Given: Player has `current_tier = 7`, `is_premium = true`; Tier 7 premium reward is a Rare Skin
- When: Player calls `POST /battle-pass/claim` with `{ seasonId, tier: 7, track: "premium" }`
- Then: `inventoryService.grantItem` called for the skin; `7` appended to `claimed_tiers[]` (if not already there for free reward — free and premium claiming are independent per tier); `battle_pass_tier_claimed` analytics event fired

**AC-BP-16 — Claim rejected for un-reached tier (server-side)**
- Given: Player has `current_tier = 5`; calls `POST /battle-pass/claim` with `{ tier: 10 }`
- When: Server validates tier eligibility
- Then: HTTP 403 returned with `error: "TIER_NOT_REACHED"`; no grant executed; `claimed_tiers[]` unchanged

**AC-BP-17 — Claim rejected for premium reward without Battle Pass**
- Given: Player has `current_tier = 10`, `is_premium = false`; calls claim for a premium reward
- When: Server validates `isPremium`
- Then: HTTP 403 returned with `error: "PREMIUM_REQUIRED"`; no grant executed; `claimed_tiers[]` unchanged

**AC-BP-18 — Duplicate claim is idempotent**
- Given: Player has already claimed Tier 5 free reward (`5 in claimed_tiers[]`); sends another `POST /battle-pass/claim` for tier 5 free
- When: Server checks `NOT (5 = ANY(claimed_tiers))`
- Then: UPDATE affects 0 rows; server returns HTTP 200 with `{ status: "already_claimed" }`; no duplicate grant; client shows tier as "Claimed"

**AC-BP-19 — Claim rolls back on grant failure; player can retry**
- Given: Tier reward grant (e.g., Currency System) throws a transient error during claim
- When: Server transaction rolls back
- Then: `claimed_tiers[]` NOT updated (tier remains claimable); HTTP 500 returned with `error: "GRANT_FAILED"`; client shows retry-able toast; subsequent retry with same request succeeds (grant idempotency key prevents double-grant)

---

### 8.5 Season Boundary

**AC-BP-20 — BPXP from match starting in old season attributed to old season**
- Given: Match starts at 23:58:00 UTC (Season 1 active); season ends at 00:00:00 UTC; match ends at 00:02:00 UTC (Season 2 active); `MATCH_REWARD_GRANTED` event fires
- When: Battle Pass observer attributes BPXP
- Then: BPXP attributed to Season 1 (match `startedAt` is in Season 1 window); if Season 1 reset has already run, BPXP is dropped with a WARN log; Season 2 BPXP is NOT incremented

---

### 8.6 IAP Refund

**AC-BP-21 — Battle Pass premium revoked on IAP refund; claimed rewards retained**
- Given: Player purchased Battle Pass via IAP; claimed Premium Rewards for Tiers 1–8; refund approved by Apple/Google; RevenueCat fires `CANCELLATION` webhook
- When: IAP System processes webhook and calls `battlePassService.revokePremium`
- Then: `is_premium` set to `false`; Premium Reward slots for Tiers 9–30 locked in UI; Tiers 1–8 claimed items remain in player's Inventory/Entitlements; `iap_refund_flags` entry created; `battle_pass_refund` analytics event fired

---

### 8.7 Reward Table Integrity

**AC-BP-22 — All 30 tiers have valid free and premium reward definitions**
- Given: Season reward table loaded from `battle_pass_seasons.reward_table`
- When: Server validates the reward table at season startup
- Then: Exactly 30 tier objects present; each tier has `freeReward` and `premiumReward` with valid `type`, `itemId`, and `displayName`; Tier 30 Premium reward `itemId` matches the Legendary skin ID; no null or missing reward slots; server throws `CONFIG_ERROR` and refuses to start if validation fails

**AC-BP-23 — Character compensation Coins granted for already-owned characters**
- Given: A player already owns Fen (purchased for 800 Coins); claims Tier 6 Free Reward (Fen character unlock)
- When: `inventoryService.grantItem` detects duplicate ownership
- Then: 800 Coins granted as compensation (per Inventory System duplicate-grant compensation path); `battle_pass_tier_claimed` analytics event includes `compensated: true, compensationCoins: 800`

---

### 8.8 Analytics Events

**AC-BP-24 — battle_pass_purchased event fires on successful purchase**
- Given: Player successfully purchases Battle Pass (either IAP or Diamond-spend path)
- When: `is_premium` is set to `true`
- Then: `battle_pass_purchased` Tier 0 analytics event emitted with `{ userId, seasonId, purchasePath: "iap" | "diamonds", tierAtPurchase: N }`; event fires exactly once per purchase; no PII beyond UUID

**AC-BP-25 — battle_pass_tier_claimed event fires on each successful claim**
- Given: Player successfully claims a tier reward
- When: Claim completes and grant is confirmed
- Then: `battle_pass_tier_claimed` Tier 0 analytics event emitted with `{ userId, seasonId, tier, track: "free" | "premium", rewardType, rewardItemId }`; event fires exactly once per claim; fires for both free and premium track claims independently

---

*End of Document*
