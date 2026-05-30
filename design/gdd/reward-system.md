# Reward System — Game Design Document

> **System**: Reward System
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

The Reward System is the canonical authority for what a player earns per match in BRAWLZONE. It operates as a pure grant engine: it receives a match result from the Match Flow fan-out (Model B, Step 5), calculates the correct Coin reward for each player based on game mode, win/loss outcome, in-match performance metrics, first-win-of-day status, and any active event multiplier, then issues atomic grants through the Currency System. Reward calculation is server-authoritative, deduplicated via a Redis lock keyed on `matchId + userId` (first-one-wins), and protected against timeout by a minimum fallback grant. The Reward System does not know about the Battle Pass, the XP system, or the Quest system — it fires a `MATCH_REWARD_GRANTED` internal event after each successful delivery and lets those systems subscribe as observers. The Reward System is also the single grant authority for Coins earned through quest completions: when the Quest System marks a quest complete, it calls the Reward System's grant function directly rather than routing through Match Flow. All Coin earn rates and multipliers are Remote Config cold keys so they can be adjusted between server restarts without a code deploy.

---

## 2. Player Fantasy

### "Every Match Pays Off"

The Reward System's central promise is that no match feels wasted. Win or lose, a number goes up — always. The results screen must communicate this concretely: "You earned 45 Coins" is satisfying; "Rewards pending..." is a broken experience. Every number on that screen is earned, honest, and arrives before the player taps "Play Again."

**What winning feels like:** The win bonus is large enough to be meaningful but not so large that it makes losses feel pointless. A player who wins five in a row feels the momentum in their Coin balance ticking toward something — a character unlock, a cosmetic. The performance bonuses (kills, assists, survival) give players something to optimize even in a stomp: you might have lost, but those three kills were still worth something.

**What losing feels like:** The loss reward is never zero and never trivially small. A 3v3 Squad Brawl loss still puts Coins in your pocket. The player looks at the results screen and sees a number, not a punishment. The grind to the next unlock is visible from both the win column and the loss column — it just moves faster when you win.

**What the first win of the day feels like:** The first win bonus is a designed celebration. It is a visible number spike on the results screen, clearly labeled, that rewards the player for showing up. It makes the first session of each day feel special without making subsequent sessions feel unrewarding. The bonus is day-gated (UTC midnight reset) so it happens once — making it feel earned, not routine.

**What every player sees:** The results screen shows exact Coin amounts. Not ranges. Not "some rewards." If the first-win bonus applied, it is itemized separately. If a performance bonus fired, it is visible. Transparency builds trust in the economy loop.

---

## 3. Detailed Rules

### 3.1 Reward Types Per Match

At the conclusion of every match (all modes, all outcomes), each player receives:

| Reward Type | Always Granted | Notes |
|---|---|---|
| **Coins** | Yes — every player, every match | Calculated by formula in §4.1 |
| **Chest / item drops** | No — not at Alpha | Direct Coin grants only at Alpha; no chest mechanic. Chest system deferred to post-Alpha. All rewards are direct grants: no loot box, no RNG item drop at match end. |

**Design rationale — no chests at Alpha:** Chest systems require a chest-open flow, chest inventory, and loot table management. At Alpha, the economy loop is Coins → unlock/purchase. Introducing chests before the core loop is validated adds friction and complexity without a validated payoff. If retention data after Alpha shows players need more reward variety, chests can be layered in as a separate content update without modifying the Reward System's grant pipeline.

### 3.2 Server-Side Delivery and Deduplication

All reward calculation and Currency System grants execute on the server. The client never calculates or self-reports reward amounts. The delivery sequence per player is:

```
1. Receive match_result_for_rewards event from Match Flow (Step 5 fan-out)
   Contains: matchId, playerId, gameMode, outcome, kills, assists,
             matchDurationMs, placement

2. Acquire Redis deduplication lock:
   Key:  "reward_lock:{matchId}:{playerId}"
   TTL:  REWARD_LOCK_TTL_MS (default 30000ms)
   Mode: SET NX (first-one-wins; second caller finds key present and aborts)

   If lock already present → this is a duplicate delivery.
     Log WARN: reward_dedup_hit { matchId, playerId }
     Return previously committed result (idempotent response)
     Exit without re-granting.

3. Read player profile: first_win_claimed_date, has_play_pass
   (Needed for first-win bonus check and future Play Pass hook)

4. Calculate coinReward using formula §4.1

5. Check REWARD_CALCULATION_TIMEOUT_MS budget:
   If calculation + profile read has exceeded REWARD_CALCULATION_TIMEOUT_MS →
     grant BASE_COINS[mode] as minimum fallback (see Edge Case §5.2)

6. Call Currency System grantCurrency:
   { playerId, currency: "coins", amount: coinReward,
     source: "match_reward",
     idempotency_key: "match_reward:{matchId}:{playerId}" }
   The Currency System executes atomically with ledger entry.

7. If firstWinBonus was applied:
   Update player profile: first_win_claimed_date = today (UTC date string)

8. Emit internal event: MATCH_REWARD_GRANTED
   { matchId, playerId, coinReward, firstWinApplied, gameMode, outcome }
   Observers (Battle Pass, analytics) subscribe to this event.
   Reward System does NOT call observers directly.

9. Fire analytics events:
   reward_granted { matchId, playerId, coinReward, gameMode, outcome,
                    firstWinApplied, kills, assists, survivalTimeSec }
   If firstWinBonus > 0: first_win_bonus_applied { matchId, playerId, bonusAmount }

10. Return reward_grants_confirmed { matchId, playerId, coinReward }
    to Match Flow (Step 7 of match end sequence)
```

### 3.3 Two-Pass Results Payload

The Reward System integrates with Match Flow's two-pass delivery model:

**Pass 1 — Immediate (rewardsReady: false):**
Match Flow sends the initial `match_results_payload` to clients immediately after MMR completes (match-flow.md §3.4 Step 6), before Reward System has confirmed. This payload contains stub coin amounts (`coinsEarned: null`). The results screen displays a loading state for the reward row.

**Pass 2 — Reward update (rewardsReady: true):**
When the Reward System returns `reward_grants_confirmed` to Match Flow within `REWARD_CALCULATION_TIMEOUT_MS`, Match Flow sends `match_results_reward_update` to all players still on the results screen. This payload carries the real `coinsEarned` value. The results screen replaces the loading state with the confirmed amount and animates the Coin counter.

If `REWARD_CALCULATION_TIMEOUT_MS` is exceeded before the Reward System responds, Match Flow transitions to the timeout fallback (see Edge Case §5.2 and match-flow.md §3.4 Step 7). The minimum fallback grant still fires server-side; the client receives an updated balance on next profile load.

### 3.4 Reward Calculation Inputs

The following fields are required in the `match_result_for_rewards` event payload. All values are provided by Match Flow from the session record:

```typescript
interface MatchResultForRewards {
  matchId: string;
  gameMode: "duel_1v1" | "squad_3v3" | "ffa_8";
  playerResults: Array<{
    playerId: string;
    outcome: "win" | "loss" | "draw";
    placement: number;           // 1-based
    kills: number;               // eliminations this match
    assists: number;
    matchDurationMs: number;     // total match wall-clock time in milliseconds
                                 // used for survival time proxy (see §4.1 note)
  }>;
}
```

> **Survival time proxy:** The Reward System uses `matchDurationMs` as a proxy for survival time at Alpha. A more precise per-player survival time (time from match start to player's last death) is a post-Alpha enhancement. At Alpha, all players in a completed match receive `survivalTimeMs = matchDurationMs`. Players eliminated early in FFA modes may receive a slightly inflated survival bonus as a result; this is an acceptable approximation at Alpha given the small SURVIVAL_BONUS_COINS_PER_SEC value.

### 3.5 Win/Loss Asymmetry

Winners earn meaningfully more than losers, but losers always earn a non-trivial amount:

| Outcome | WIN_MULTIPLIER | Design Intent |
|---|---|---|
| Win | 1.5 | Win bonus rewards skill and effort |
| Loss / Draw | 1.0 | Loss baseline retains casual players; no punishment for losing |

The multiplier is applied to the mode's BASE_COINS value (§7 Tuning Knobs), not to the total reward. Performance bonuses (kills, assists, survival) apply equally regardless of outcome — a player can have a great losing performance and earn more than a passive winner.

### 3.6 First Win of Day Bonus

**Trigger:** The first match of each UTC calendar day that a player wins.

**Bonus amount:** `FIRST_WIN_BONUS_COINS` Coins (default 150), added on top of all other reward components.

**Reset:** UTC midnight. The bonus is available once per UTC calendar day per player.

**Tracking field:** `first_win_claimed_date` — a date string (`"YYYY-MM-DD"`) stored in the Player Profile (server-only field). The Reward System compares this to the current UTC date to determine if the bonus is available. This record is the project-wide authority for "first win of day" state. The XP System's first-win XP bonus (+100 XP) must read from this same `first_win_claimed_date` record rather than maintaining a separate flag, to prevent split-brain state under Model B fan-out.

**Application rules:**
- Bonus applies only to match outcomes of `"win"`.
- Bonus does not apply to losses or draws, regardless of how long since the player last claimed it.
- If `first_win_claimed_date` is null (new player) or does not match today's UTC date (`new Date().toISOString().slice(0, 10)`), the bonus is available.
- If `first_win_claimed_date` equals today's UTC date, the bonus has already been claimed; do not apply.
- After applying the bonus, the Reward System writes `first_win_claimed_date = today` to the Player Profile in the same transaction as the Currency System grant. If the Currency System grant fails, the profile write is not committed (transactional atomicity via the Currency System's transaction scope).

**Analytics:** When the first-win bonus fires, emit both `reward_granted` (with `firstWinApplied: true`) and a dedicated `first_win_bonus_applied` event with `bonusAmount`.

### 3.7 Active Event Multiplier

During special events (holidays, launch week, weekends), a server-side `ACTIVE_EVENT_COIN_MULTIPLIER` Remote Config cold key can be set to a value greater than 1.0. This multiplier is applied to the entire `coinReward` (after all additive components are summed) using `floor()`:

```
finalCoinReward = floor(coinReward × ACTIVE_EVENT_COIN_MULTIPLIER)
```

When no event is active, `ACTIVE_EVENT_COIN_MULTIPLIER = 1.0` (no effect). This key is read fresh at calculation time (it is a cold key so it is read at server startup into memory, not per-request). Changing the multiplier requires a server restart. Event multipliers must not exceed 3.0 (see §7 safe range).

### 3.8 Battle Pass Observer Hook

The Reward System emits the `MATCH_REWARD_GRANTED` internal event (via the server's event bus) after every successful reward delivery. The Battle Pass system subscribes to this event to advance its match-completion progress track. **The Reward System does not import, reference, or call the Battle Pass system in any code path.** The observer pattern is enforced architecturally: Reward System emits; Battle Pass subscribes. If the Battle Pass system is not initialized (e.g., pre-Alpha stub), the event is emitted and ignored with no error.

```typescript
// Internal event schema emitted by Reward System after successful grant
interface MatchRewardGrantedEvent {
  event: "MATCH_REWARD_GRANTED";
  matchId: string;
  playerId: string;
  gameMode: "duel_1v1" | "squad_3v3" | "ffa_8";
  outcome: "win" | "loss" | "draw";
  coinReward: number;           // Total Coins granted including all bonuses
  firstWinApplied: boolean;
  matchStartedAt: string;       // ISO 8601 UTC — when the match began; required by
                                // battle-pass.md for season-boundary attribution
                                // (attributes reward to correct season when a match
                                // straddles a season reset)
  serverTimestamp: string;      // ISO 8601 UTC
}
```

### 3.9 Quest Completion Rewards — Grant Authority

When the Quest System marks a quest complete, it calls the Reward System's `grantQuestReward` function directly. It does **not** route through Match Flow. The Reward System is the single grant authority for Coin grants in BRAWLZONE.

```typescript
// Called by Quest System on quest completion
async function grantQuestReward(params: {
  playerId: string;
  questId: string;
  coinAmount: number;
  source: "quest_reward";
}): Promise<{ granted: boolean; newCoinBalance: number }>
```

The Reward System calls the Currency System's `grantCurrency` with `source: "quest_reward"` and `idempotency_key: "quest_reward:{questId}:{playerId}"`. It then emits a `QUEST_REWARD_GRANTED` internal event (separate from `MATCH_REWARD_GRANTED`) for any observers. Quest reward amounts are defined by the Quest System GDD; the Reward System does not own quest reward values — it only executes the grant.

---

## 4. Formulas

### 4.1 Coin Reward Formula

```
coinReward = floor(
  (BASE_COINS[mode] × WIN_MULTIPLIER[outcome])
  + (kills × KILL_BONUS_COINS)
  + (assists × ASSIST_BONUS_COINS)
  + (survivalTimeMs / 1000 × SURVIVAL_BONUS_COINS_PER_SEC)
  + firstWinBonus
) × ACTIVE_EVENT_COIN_MULTIPLIER
```

> **Operator precedence note:** The `floor()` wraps all additive components before the event multiplier is applied. The event multiplier then receives a floored integer, and a second `floor()` is applied to the multiplier result:
> `finalCoinReward = floor(floor(additiveSum) × ACTIVE_EVENT_COIN_MULTIPLIER)`

#### Variable Definitions

| Variable | Description | Default Value |
|---|---|---|
| `BASE_COINS["duel_1v1"]` | Base Coins for 1v1 Duel mode | `40` |
| `BASE_COINS["squad_3v3"]` | Base Coins for 3v3 Squad Brawl mode | `50` |
| `BASE_COINS["ffa_8"]` | Base Coins for 8-player FFA mode | `45` |
| `WIN_MULTIPLIER["win"]` | Multiplier applied on a win outcome | `1.5` |
| `WIN_MULTIPLIER["loss"]` | Multiplier applied on a loss outcome | `1.0` |
| `WIN_MULTIPLIER["draw"]` | Multiplier applied on a draw outcome | `1.0` |
| `KILL_BONUS_COINS` | Bonus Coins per elimination (kill) | `5` |
| `ASSIST_BONUS_COINS` | Bonus Coins per assist | `3` |
| `SURVIVAL_BONUS_COINS_PER_SEC` | Bonus Coins per second of survival time | `0.1` |
| `FIRST_WIN_BONUS_COINS` | Additional Coins for first win of the UTC day | `150` |
| `ACTIVE_EVENT_COIN_MULTIPLIER` | Global multiplier during special events | `1.0` (no event) |
| `kills` | Number of eliminations this player recorded this match | From session record |
| `assists` | Number of assists this player recorded this match | From session record |
| `survivalTimeMs` | Milliseconds player was alive (Alpha: equals matchDurationMs) | From session record |
| `firstWinBonus` | `FIRST_WIN_BONUS_COINS` if eligible; `0` otherwise | Determined per §3.6 |

#### Step-by-Step Evaluation Order

```
Step 1: baseComponent  = BASE_COINS[mode] × WIN_MULTIPLIER[outcome]
Step 2: killComponent  = kills × KILL_BONUS_COINS
Step 3: assistComponent = assists × ASSIST_BONUS_COINS
Step 4: survivalComponent = (survivalTimeMs / 1000) × SURVIVAL_BONUS_COINS_PER_SEC
Step 5: additiveSum    = baseComponent + killComponent + assistComponent
                         + survivalComponent + firstWinBonus
Step 6: floored        = floor(additiveSum)
Step 7: finalCoinReward = floor(floored × ACTIVE_EVENT_COIN_MULTIPLIER)
```

---

### 4.2 Example Calculation 1 — 1v1 Duel Win with First Win of Day

**Inputs:**
- `gameMode`: `"duel_1v1"`
- `outcome`: `"win"`
- `kills`: `3`
- `assists`: `0`
- `matchDurationMs`: `90000` (90 seconds)
- `firstWinBonusEligible`: `true` (no prior win today)
- `ACTIVE_EVENT_COIN_MULTIPLIER`: `1.0` (no event)

**Calculation:**

```
Step 1: baseComponent   = 40 × 1.5           = 60.0
Step 2: killComponent   = 3 × 5              = 15.0
Step 3: assistComponent = 0 × 3              = 0.0
Step 4: survivalComponent = (90000 / 1000) × 0.1
                          = 90 × 0.1          = 9.0
Step 5: firstWinBonus   = 150
        additiveSum     = 60.0 + 15.0 + 0.0 + 9.0 + 150.0
                        = 234.0
Step 6: floored         = floor(234.0)        = 234
Step 7: finalCoinReward = floor(234 × 1.0)    = 234 Coins
```

**Result: 234 Coins**

Breakdown visible to player: Base win (60) + Kills ×3 (15) + Survival 90s (9) + First Win Bonus (150) = **234 Coins**

---

### 4.3 Example Calculation 2 — 3v3 Squad Brawl Loss

**Inputs:**
- `gameMode`: `"squad_3v3"`
- `outcome`: `"loss"`
- `kills`: `1`
- `assists`: `2`
- `matchDurationMs`: `180000` (180 seconds / 3 minutes)
- `firstWinBonusEligible`: `false` (outcome is loss, so bonus does not apply regardless)
- `ACTIVE_EVENT_COIN_MULTIPLIER`: `1.0` (no event)

**Calculation:**

```
Step 1: baseComponent   = 50 × 1.0           = 50.0
Step 2: killComponent   = 1 × 5              = 5.0
Step 3: assistComponent = 2 × 3              = 6.0
Step 4: survivalComponent = (180000 / 1000) × 0.1
                          = 180 × 0.1         = 18.0
Step 5: firstWinBonus   = 0 (loss outcome)
        additiveSum     = 50.0 + 5.0 + 6.0 + 18.0 + 0
                        = 79.0
Step 6: floored         = floor(79.0)         = 79
Step 7: finalCoinReward = floor(79 × 1.0)     = 79 Coins
```

**Result: 79 Coins**

Breakdown visible to player: Base (50) + Kill ×1 (5) + Assists ×2 (6) + Survival 180s (18) = **79 Coins**

---

### 4.4 Example Calculation 3 — 8-Player FFA Win During Double-Coin Event

**Inputs:**
- `gameMode`: `"ffa_8"`
- `outcome`: `"win"`
- `kills`: `5`
- `assists`: `1`
- `matchDurationMs`: `240000` (4 minutes)
- `firstWinBonusEligible`: `false` (first win of day already claimed earlier)
- `ACTIVE_EVENT_COIN_MULTIPLIER`: `2.0` (double-coin weekend event)

**Calculation:**

```
Step 1: baseComponent   = 45 × 1.5           = 67.5
Step 2: killComponent   = 5 × 5              = 25.0
Step 3: assistComponent = 1 × 3              = 3.0
Step 4: survivalComponent = (240000 / 1000) × 0.1
                          = 240 × 0.1         = 24.0
Step 5: firstWinBonus   = 0 (already claimed today)
        additiveSum     = 67.5 + 25.0 + 3.0 + 24.0 + 0
                        = 119.5
Step 6: floored         = floor(119.5)        = 119
Step 7: finalCoinReward = floor(119 × 2.0)    = 238 Coins
```

**Result: 238 Coins**

Breakdown visible to player: Base win (67, floored) + Kills ×5 (25) + Assist ×1 (3) + Survival 240s (24) × 2× event = **238 Coins**

---

### 4.5 Minimum Fallback Grant

If the reward calculation exceeds `REWARD_CALCULATION_TIMEOUT_MS` (see Edge Case §5.2), the Reward System grants the bare base Coin amount with no bonuses:

```
fallbackCoinReward = BASE_COINS[mode]
```

Examples:
- Duel timeout fallback: `40 Coins`
- Squad Brawl timeout fallback: `50 Coins`
- FFA timeout fallback: `45 Coins`

The fallback is always a win or loss neutral amount (uses the raw BASE_COINS, not multiplied by WIN_MULTIPLIER). This ensures every completed match delivers some reward even under server stress, while not requiring the full profile read needed for the win multiplier or first-win check.

---

### 4.6 Player Profile Schema Additions

The Reward System requires one additional field on the Player Profile beyond the existing schema:

```typescript
interface PlayerProfileRewardFields {
  first_win_claimed_date: string | null;
  // ISO 8601 UTC date string, e.g. "2026-05-28"
  // null = player has never claimed a first-win bonus
  // Set by Reward System on first win claim each UTC day
  // Server-only field; never exposed to client directly
  // Reset is implicit: if value != today's UTC date, bonus is available
  // Project-wide authority for "first win of day" state: this record is the
  // single source of truth across all systems. The XP System's first-win XP
  // bonus (+100 XP) must read from this same `first_win_claimed_date` record
  // rather than maintaining a separate flag, to prevent split-brain state
  // under Model B fan-out.
}
```

This field is written by the Reward System within the Currency System's grant transaction (via `source_ref` carrying the date). It is read at reward calculation time (Step 3 of §3.2). The Currency System's transaction atomicity ensures `first_win_claimed_date` and the Coin grant are committed together or both roll back.

---

## 5. Edge Cases

### 5.1 Reward Grant Fires Twice (Deduplication)

**Scenario:** The `match_result_for_rewards` event is delivered twice for the same `matchId` + `playerId` combination. This can occur when Match Flow's event bus retries delivery after a timeout or network interruption.

**Resolution:**

1. The Reward System attempts `SET NX` on Redis key `"reward_lock:{matchId}:{playerId}"` with TTL `REWARD_LOCK_TTL_MS` (default 30,000ms).
2. The first delivery acquires the lock (Redis returns `OK`) and proceeds through full calculation and grant.
3. The second delivery finds the key already present (Redis returns `nil`). The Reward System logs `WARN: reward_dedup_hit { matchId, playerId }` and returns `{ status: "duplicate", alreadyGranted: true }` to the caller without re-executing any grant.
4. Even if the Redis lock expires before the second delivery (e.g., lock TTL elapsed after 30 seconds), the Currency System's idempotency key `"match_reward:{matchId}:{playerId}"` is a second independent dedup layer. The Currency System will detect the existing ledger row and return the original committed result without a second grant.
5. The Analytics event `reward_dedup_hit` is emitted for monitoring; a spike in this metric indicates Match Flow retry behavior and should be investigated.

**Result:** The player's Coin balance is incremented exactly once per match, regardless of event delivery retries.

---

### 5.2 Reward Calculation Timeout

**Scenario:** The Reward System receives the `match_result_for_rewards` event but the profile read (first_win check) or Redis operations take longer than `REWARD_CALCULATION_TIMEOUT_MS`.

**Resolution:**

1. The Reward System sets a deadline at calculation start: `deadline = Date.now() + REWARD_CALCULATION_TIMEOUT_MS`.
2. After each async operation (Redis lock acquire, profile read), it checks `Date.now() > deadline`.
3. If the deadline is exceeded, the Reward System:
   a. Logs `ERROR: reward_calculation_timeout { matchId, playerId, elapsedMs }` via the ILogger interface (PII policy: log playerId UUID only, no display name).
   b. Calculates the fallback grant: `fallbackCoinReward = BASE_COINS[mode]` (§4.5).
   c. Calls Currency System `grantCurrency` with the fallback amount and the same idempotency key `"match_reward:{matchId}:{playerId}"`.
   d. Does NOT apply first-win bonus (profile read incomplete).
   e. Does NOT write `first_win_claimed_date` (first win was not confirmed).
   f. Emits `MATCH_REWARD_GRANTED` event with `coinReward = fallbackCoinReward`, `firstWinApplied: false`.
   g. Returns confirmation to Match Flow.
4. The player receives the minimum base reward. The first-win bonus for this day is preserved — it was not claimed, so it remains available for the player's next win today.
5. Analytics event `reward_timeout_fallback { matchId, playerId, gameMode, fallbackAmount, elapsedMs }` is emitted.

**Result:** The player always receives at least the base mode reward. No match produces zero Coins due to internal timeouts.

---

### 5.3 Player Disconnects Before Reward Delivery

**Scenario:** A match ends. Match Flow fires the fan-out to the Reward System. Before the Reward System completes the grant, the player closes the app or loses network connectivity.

**Resolution:**

1. Reward calculation and Currency System grants are entirely server-side. Client connection state does not affect grant execution.
2. The Redis lock and Currency System grant execute normally whether the player is connected or not.
3. The `profile:refresh` Socket.io event (fired by the Currency System after grant commit) is emitted server-side. If the player is disconnected, this event is not delivered — but that is acceptable.
4. On the player's next authenticated session, the client calls `GET /profile`. The Redis profile cache was invalidated by the Currency System grant. The API server returns the PostgreSQL value, which includes the match reward.
5. The player sees their updated Coin balance on profile load post-reconnect. No special reconnect flow is required by the Reward System.
6. If the Reward System has not yet committed the grant when the player reconnects (e.g., the event is still queued), the balance temporarily reflects the pre-reward state. When the grant commits, `profile:refresh` fires if the player is connected; otherwise, the next profile read returns the correct value.

**Result:** No Coins are lost due to player disconnection. Delivery is guaranteed by server-side execution.

---

### 5.4 Coin Wallet Cap Reached During Grant

**Scenario:** A player has `coin_balance = 49,980`. The calculated `coinReward` is `234 Coins`. Applying the full grant would exceed the 50,000 Coin wallet cap.

**Resolution:**

1. The Reward System passes the full calculated `coinReward` (234) to the Currency System.
2. The Currency System handles cap enforcement internally (per currency-system.md §3.5): it computes `available_headroom = 50,000 - 49,980 = 20` and grants exactly 20 Coins.
3. The Currency System ledger row records `requested_amount: 234`, `actual_amount: 20`.
4. The Currency System emits `CURRENCY_GRANT_CAPPED` analytics event with `dropped_amount: 214`.
5. The Reward System receives confirmation with `actual_amount: 20` and includes this in `reward_grants_confirmed` returned to Match Flow.
6. Match Flow's `match_results_reward_update` payload sends `coinsEarned: 20` to the client (actual amount, not formula amount).
7. The Reward System does not independently log the cap — that is the Currency System's responsibility. The Reward System's own analytics `reward_granted` event carries the `coinReward` as calculated (234), which allows analysis of how often cap truncation occurs versus how much was earned.

**Result:** The player's balance is capped at 50,000. Excess Coins are dropped. The player is not punished beyond the cap — the results screen shows the actual coins received (20), not the formula output (234).

---

### 5.5 First Win Bonus Applied During Midnight Reset Race Condition

**Scenario:** A player's match ends at 23:59:58 UTC. The Reward System begins processing at 23:59:59 UTC and reads `first_win_claimed_date = null` (bonus available). The UTC date rolls to the next day (00:00:00 UTC) while the Reward System is mid-calculation, before it writes `first_win_claimed_date`. A second match result arrives for a different match that the player won 10 minutes earlier (delayed fan-out retry) at 00:00:01 UTC, also with a null `first_win_claimed_date` because no write has committed yet.

**Resolution:**

1. The Redis deduplication lock (`"reward_lock:{matchId}:{playerId}"`) is per-match, so two different matches are not deduplicated against each other.
2. The first delivery's Currency System grant includes `idempotency_key: "match_reward:{matchId1}:{playerId}"` and writes `first_win_claimed_date = "2026-05-28"` (yesterday) within the grant transaction.
3. The second delivery's profile read occurs after the first transaction commits. If `first_win_claimed_date = "2026-05-28"` (yesterday), and today is now `"2026-05-29"`, the second delivery will see `first_win_claimed_date ≠ today ("2026-05-29")` and award the first-win bonus for the new day.
4. This is the correct behavior: the player earns the first-win bonus for the new UTC day on their first qualifying win of that day.
5. In the edge case where both profile reads happen simultaneously before either write commits (concurrent transactions reading the same stale profile), the Currency System's `SELECT ... FOR UPDATE` row lock serializes the two transactions. The second transaction to acquire the row lock will re-read the committed `first_win_claimed_date` before writing, because the profile read is inside the Currency System transaction that holds the row lock. The `first_win_claimed_date` write is part of the Reward System's instruction to the Currency System; if the second transaction re-reads and finds the date already written, it skips the first-win bonus write for that transaction.

> **Implementation note:** The Reward System must pass `first_win_claimed_date` as a conditional write to the Currency System: "write this date only if `first_win_claimed_date` is still null or less than today at commit time." This is enforced via a conditional UPDATE inside the Currency System transaction: `UPDATE player_profiles SET first_win_claimed_date = $date WHERE user_id = $id AND (first_win_claimed_date IS NULL OR first_win_claimed_date < $date)`. If this UPDATE affects 0 rows (another transaction already wrote a same-or-newer date), the Reward System accepts this as correct and does not re-apply the first-win bonus amount. The `coinReward` calculation at this point has already included the bonus — if the conditional write misses, the Coin grant still commits (the idempotency key is for the full amount including bonus). This is the accepted trade-off: in the rare race, one of the two matches on the exact midnight boundary may receive a bonus that was claimed by the other. The total exposure is one `FIRST_WIN_BONUS_COINS` grant (150 Coins) per player per day boundary race — considered acceptable over correcting with a second grant round-trip.

**Result:** The first-win bonus is applied at most once per UTC day per player in the normal case. In the exact midnight boundary race, at most one extra bonus (150 Coins) may be granted. This is logged and monitored; it is not a blocking correctness issue.

---

## 6. Dependencies

### 6.1 Upstream — Reward System Consumes

| System | What Reward System Needs | Interface | Notes |
|---|---|---|---|
| **Match Flow** (`match-flow.md`) | `match_result_for_rewards` async event at Step 5 fan-out | Internal event bus subscription; event carries matchId, gameMode, per-player outcome, kills, assists, matchDurationMs | Source of all match-based reward triggers. MMR has already committed before this event fires (match-flow.md §3.4 Step 4). |
| **Player Profile** (`player-profile.md`) | Read `first_win_claimed_date`, `has_play_pass` at reward calculation time; write `first_win_claimed_date` after first-win grant | PostgreSQL `SELECT` (via Currency System transaction scope for the write) | `first_win_claimed_date` is a new field added by Reward System (§4.6). Economy writes invalidate Redis AND push `profile:refresh` Socket.io event per player-profile.md §3.4. |
| **Currency System** (`currency-system.md`) | `grantCurrency` API — Coin grants for match rewards and quest rewards | Synchronous server-to-server internal call; Currency System executes grant atomically with ledger entry | Reward System is a caller; Currency System owns atomicity, ledger, dedup, cap enforcement. Reward System provides idempotency key. |
| **Remote Config** (`remote-config.md`) | All earn rate constants: `BASE_COINS.*`, `WIN_MULTIPLIER.*`, `KILL_BONUS_COINS`, `ASSIST_BONUS_COINS`, `SURVIVAL_BONUS_COINS_PER_SEC`, `FIRST_WIN_BONUS_COINS`, `ACTIVE_EVENT_COIN_MULTIPLIER` | Remote Config cold keys — read at server startup, held in memory | Cold key classification is intentional: earn rates must not change mid-session. Server restart required to apply changes. |
| **Redis** | Deduplication lock `"reward_lock:{matchId}:{playerId}"` with SET NX | Redis client; standard Redis SET NX command with TTL | First-one-wins dedup layer. Secondary dedup is Currency System idempotency key. |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | Emit `reward_granted`, `first_win_bonus_applied`, `reward_timeout_fallback`, `reward_dedup_hit` events | Async fire-and-forget via analytics event emitter | PII policy: `playerId` UUID is allowed; no display names in event payloads or logs. |
| **Logging / Monitoring** (`logging-monitoring.md`) | ILogger interface for WARN and ERROR logs | Standard ILogger interface | Log `reward_calculation_timeout` at ERROR level; `reward_dedup_hit` at WARN level. |

### 6.2 Downstream — Reward System Produces / Notifies

| System | What Reward System Provides | Interface | Notes |
|---|---|---|---|
| **Match Flow** (`match-flow.md`) | `reward_grants_confirmed { matchId, playerGrants[{ playerId, coinReward }] }` response within `REWARD_CALCULATION_TIMEOUT_MS` | Async response to event; Match Flow tracks with REWARD_TIMEOUT_MS promise | Match Flow uses this to send `match_results_reward_update` to clients (Step 8). |
| **Player Profile** (`player-profile.md`) | Writes `first_win_claimed_date`; triggers Redis cache invalidation and `profile:refresh` Socket.io event (via Currency System) | PostgreSQL update within Currency System transaction; cache/event handling by Currency System | Reward System does not call Socket.io directly; Currency System handles cache and push notification on grant commit. |
| **Battle Pass** (`battle-pass.md` — future) | `MATCH_REWARD_GRANTED` internal event after every successful match reward delivery | Internal event bus emit; Battle Pass subscribes as observer | Reward System has zero coupling to Battle Pass. Observer pattern enforced by architecture: Reward System only emits. |
| **Currency System** (`currency-system.md`) | Initiates `grantCurrency` calls with `source: "match_reward"` or `"quest_reward"` | Synchronous call; Currency System returns confirmed new balance | Currency System is the execution layer; Reward System is the calculation and authorization layer. |
| **Analytics / Telemetry** (`analytics-telemetry.md`) | `reward_granted { matchId, playerId, coinReward, gameMode, outcome, firstWinApplied, kills, assists, survivalTimeSec }` and `first_win_bonus_applied { matchId, playerId, bonusAmount }` | Async fire-and-forget | Required events for economy telemetry and balance monitoring. |

### 6.3 Future Observers (Not Yet Implemented)

The following systems will subscribe to `MATCH_REWARD_GRANTED` when implemented. The Reward System requires no modifications to support them:

| System | Event They Subscribe To | Purpose |
|---|---|---|
| **Battle Pass** | `MATCH_REWARD_GRANTED` | Advance match-completion progress on the Battle Pass track |
| **Achievement System** (post-Alpha) | `MATCH_REWARD_GRANTED` | Check "earn X Coins in a single match" achievement triggers |

---

## 7. Tuning Knobs

All values listed are Remote Config **cold keys** unless explicitly marked otherwise. Cold keys are read at server startup and held in memory; changing them requires a server restart. Earn rates are cold keys intentionally — changing reward rates mid-session would create inconsistent expectations within active play sessions.

| Parameter | Remote Config Key | Default | Safe Range | What Breaks Outside Range |
|---|---|---|---|---|
| Base Coins — 1v1 Duel | `reward.baseCoins.duel` | `40` | 20–80 | Below 20: Duel feels economically punishing vs. other modes. Above 80: Duel Coin-per-minute significantly outpaces Squad Brawl, creating mode imbalance. |
| Base Coins — 3v3 Squad Brawl | `reward.baseCoins.squadBrawl` | `50` | 25–100 | Below 25: Squad mode underrewarded relative to its cooperation complexity. Above 100: squad grinding dominates all other Coin sources. |
| Base Coins — 8-player FFA | `reward.baseCoins.ffa` | `45` | 20–90 | Below 20: FFA feels underrewarding given its longer match duration. Above 90: FFA becomes primary Coin-farming mode; mode balance skewed. |
| Win multiplier | `reward.winMultiplier` | `1.5` | 1.1–2.0 | Below 1.1: win and loss rewards nearly identical; competitive incentive erodes. Above 2.0: win/loss gap too large; losing sessions feel significantly punishing. Must be > 1.0. |
| Kill bonus Coins | `reward.killBonusCoins` | `5` | 0–15 | 0: no performance bonus; rewards purely outcome-based. Above 15: high-kill players in FFA can earn 2–3× more than low-kill winners; unintended economy gap. |
| Assist bonus Coins | `reward.assistBonusCoins` | `3` | 0–10 | 0: no assist incentive; reduces team-play reward. Above 10: assists approach kill value; may encourage passive play styles. Must be ≤ `killBonusCoins`. |
| Survival bonus Coins per second | `reward.survivalBonusCoinsPerSec` | `0.1` | 0–0.5 | 0: no survival incentive. Above 0.5: 4-minute match survival bonus (~24 Coins at 0.1) becomes ~120 Coins, dominating kill performance as a Coin source. |
| First-win bonus Coins | `reward.firstWinBonusCoins` | `150` | 50–300 | Below 50: first-win bonus not motivating; daily engagement boost lost. Above 300: first win of the day becomes nearly 50% of daily Coin earnings in a short session; distorts daily habit economics. |
| Active event coin multiplier | `reward.activeEventCoinMultiplier` | `1.0` | 1.0–3.0 | Below 1.0: invalid (cannot reduce rewards via this key; use earn rates instead). Above 3.0: economy over-inflated during events; character unlocks trivially fast; undermines long-term progression. |
| Reward calculation timeout | `reward.calculationTimeoutMs` | `3000` | 500–10000 | Below 500ms: false timeouts on congested servers; frequent fallback grants. Above 10000ms: budget exceeds Match Flow's `REWARD_TIMEOUT_MS` (5000ms); Reward System will always appear to time out from Match Flow's perspective. Must be < `REWARD_TIMEOUT_MS`. |
| Reward deduplication lock TTL | `reward.lockTtlMs` | `30000` | 10000–120000 | Below 10000ms: lock may expire before a slow grant commits, allowing duplicate processing. Above 120000ms: locks from failed events block the same player/match key for too long; marginal risk in practice. |

### Remote Config Key Summary

The following keys are the canonical Remote Config cold keys owned by the Reward System:

```
reward.baseCoins.duel
reward.baseCoins.squadBrawl
reward.baseCoins.ffa
reward.winMultiplier
reward.killBonusCoins
reward.assistBonusCoins
reward.survivalBonusCoinsPerSec
reward.firstWinBonusCoins
reward.activeEventCoinMultiplier
reward.calculationTimeoutMs
reward.lockTtlMs
```

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and are independently verifiable by automated test or documented manual QA.

### 8.1 Core Match Reward Calculation

**AC-RS-01 — Correct Coin reward on Duel win with first-win bonus**
- Given: A player with `first_win_claimed_date: null` wins a 1v1 Duel with 3 kills, 0 assists, 90,000ms match duration; no active event; all defaults per §7
- When: Reward System processes `match_result_for_rewards`
- Then: `coinReward = 234` (calculation per §4.2); Currency System `grantCurrency` is called with `amount: 234`, `source: "match_reward"`; `first_win_claimed_date` is written to today's UTC date; `first_win_bonus_applied` analytics event emitted with `bonusAmount: 150`; `reward_granted` analytics event emitted with `firstWinApplied: true`

**AC-RS-02 — Correct Coin reward on Squad Brawl loss**
- Given: A player loses a 3v3 Squad Brawl with 1 kill, 2 assists, 180,000ms match duration; no active event; all defaults
- When: Reward System processes `match_result_for_rewards`
- Then: `coinReward = 79` (calculation per §4.3); Currency System `grantCurrency` called with `amount: 79`; `firstWinApplied: false` in analytics event; `first_win_claimed_date` is NOT updated (outcome was loss)

**AC-RS-03 — Correct Coin reward on FFA win during event multiplier**
- Given: A player wins FFA with 5 kills, 1 assist, 240,000ms match duration; `ACTIVE_EVENT_COIN_MULTIPLIER = 2.0`; first-win bonus already claimed today
- When: Reward System processes `match_result_for_rewards`
- Then: `coinReward = 238` (calculation per §4.4); multiplier applied as final step after floor; `reward_granted` analytics event emitted

**AC-RS-04 — Loss outcome: WIN_MULTIPLIER 1.0 applied**
- Given: A player with `first_win_claimed_date: null` loses any match
- When: Reward System calculates reward
- Then: `baseComponent = BASE_COINS[mode] × 1.0` (not 1.5); `firstWinBonus = 0` (outcome is loss, bonus not applied regardless of eligibility); `first_win_claimed_date` remains unchanged

**AC-RS-05 — Draw outcome treated same as loss**
- Given: A player receives `outcome: "draw"`
- When: Reward System calculates reward
- Then: `WIN_MULTIPLIER["draw"] = 1.0` is applied; `firstWinBonus = 0`; calculation proceeds identically to a loss

---

### 8.2 First Win of Day

**AC-RS-06 — First win bonus applied once per UTC day**
- Given: A player with `first_win_claimed_date = null` wins two matches in the same UTC calendar day
- When: Both match rewards are processed sequentially
- Then: First match reward includes `FIRST_WIN_BONUS_COINS = 150`; `first_win_claimed_date` is set to today's UTC date after first grant; second match reward does NOT include first-win bonus; second match's `reward_granted` event has `firstWinApplied: false`

**AC-RS-07 — First win bonus resets at UTC midnight**
- Given: A player's `first_win_claimed_date = "2026-05-28"` (yesterday); the player wins a match today (`"2026-05-29"`)
- When: Reward System compares `first_win_claimed_date` to today's UTC date
- Then: Bonus is treated as available (date does not match today); `FIRST_WIN_BONUS_COINS` is included in `coinReward`; `first_win_claimed_date` updated to `"2026-05-29"`

**AC-RS-08 — First win bonus not applied on loss even if unclaimed**
- Given: A player with `first_win_claimed_date = null` (has never claimed) loses a match
- When: Reward System processes the loss result
- Then: `firstWinBonus = 0`; `first_win_claimed_date` remains null; bonus is preserved for the player's next win this UTC day

---

### 8.3 Deduplication

**AC-RS-09 — Duplicate event delivery: grant fires exactly once**
- Given: The `match_result_for_rewards` event for `matchId: "m-001"`, `playerId: "p-123"` is delivered twice to the Reward System (simulating a retry)
- When: Both deliveries are processed
- Then: Redis key `"reward_lock:m-001:p-123"` is SET NX on first delivery (succeeds); second delivery finds key present and exits without granting; Currency System `grantCurrency` is called exactly once; `coin_balance` incremented exactly once; second delivery emits `reward_dedup_hit` analytics event

**AC-RS-10 — Idempotency via Currency System key as backup layer**
- Given: Redis lock has expired (TTL elapsed) before a second identical event delivery arrives; the first grant has already committed in Currency System
- When: Second delivery proceeds past the Redis lock check
- Then: Currency System detects existing ledger row with `idempotency_key: "match_reward:m-001:p-123"` and returns original committed result; no second grant; `coin_balance` incremented exactly once in total

---

### 8.4 Timeout and Fallback

**AC-RS-11 — Calculation timeout triggers minimum fallback grant**
- Given: `REWARD_CALCULATION_TIMEOUT_MS = 3000`; the profile read step exceeds the deadline (simulated by injecting a delay > 3000ms)
- When: Reward System detects deadline exceeded
- Then: `fallbackCoinReward = BASE_COINS[mode]` is granted (e.g., 40 for Duel); `reward_calculation_timeout` logged at ERROR level; `reward_timeout_fallback` analytics event emitted; `first_win_claimed_date` NOT updated; Currency System `grantCurrency` called with fallback amount and correct idempotency key; `reward_grants_confirmed` returned to Match Flow

**AC-RS-12 — Timeout fallback does not consume first-win bonus**
- Given: A player's first win of the day triggers a timeout fallback (§5.2)
- When: Fallback grant is applied
- Then: `first_win_claimed_date` is NOT written; player's first-win bonus remains available for their next win today; a subsequent successful win reward for a different match later that day correctly includes the first-win bonus

---

### 8.5 Disconnect and Offline Delivery

**AC-RS-13 — Reward grants without client connection**
- Given: A player closes the app (simulated by disconnecting socket) before `match_result_for_rewards` is processed by the Reward System
- When: Reward System processes the event server-side
- Then: Currency System grant executes successfully; `coin_balance` in PostgreSQL reflects the grant; when the player reconnects and loads their profile, the updated balance is returned from the server; no manual intervention required

---

### 8.6 Wallet Cap Interaction

**AC-RS-14 — Reward delivery succeeds when Currency System caps the grant**
- Given: A player has `coin_balance = 49,980`; calculated `coinReward = 234`
- When: Reward System calls Currency System `grantCurrency(234)`
- Then: Currency System grants only 20 Coins (cap enforcement); returns `actual_amount: 20`; `reward_grants_confirmed` carries `coinReward: 20` (actual, not formula amount); Match Flow `match_results_reward_update` payload shows `coinsEarned: 20`; Reward System does NOT retry with the uncapped amount; no error is raised to the player

---

### 8.7 Battle Pass Observer

**AC-RS-15 — MATCH_REWARD_GRANTED event emitted after every successful grant**
- Given: Any match reward grant completes successfully (win or loss, any mode)
- When: Currency System confirms the grant
- Then: Reward System emits `MATCH_REWARD_GRANTED` on the internal event bus with correct `matchId`, `playerId`, `gameMode`, `outcome`, `coinReward`, `firstWinApplied`, `serverTimestamp`; event is emitted regardless of whether Battle Pass is subscribed; Reward System code contains zero direct references to the Battle Pass system

**AC-RS-16 — No Battle Pass coupling in Reward System code**
- Given: A code review of the Reward System module
- When: Reviewing all imports, function calls, and event emissions
- Then: No import of Battle Pass module; no direct call to Battle Pass API; all Battle Pass interaction is one-directional (Reward System emits event; Battle Pass subscribes externally)

---

### 8.8 Quest Reward Grant Authority

**AC-RS-17 — Quest reward grant executed by Reward System**
- Given: Quest System calls `grantQuestReward({ playerId: "p-123", questId: "q-daily-01", coinAmount: 100, source: "quest_reward" })`
- When: Reward System processes the call
- Then: Currency System `grantCurrency` called with `amount: 100`, `source: "quest_reward"`, `idempotency_key: "quest_reward:q-daily-01:p-123"`; `coin_balance` increases by 100; `QUEST_REWARD_GRANTED` internal event emitted; `reward_granted` analytics event emitted

**AC-RS-18 — Quest reward idempotency**
- Given: Quest System calls `grantQuestReward` for `questId: "q-daily-01"`, `playerId: "p-123"` twice (duplicate delivery)
- When: Both calls are processed
- Then: Currency System detects duplicate `idempotency_key: "quest_reward:q-daily-01:p-123"` on second call and returns original result; `coin_balance` incremented exactly once

---

### 8.9 Analytics Events

**AC-RS-19 — reward_granted event contains all required fields**
- Given: Any match reward grant completes
- When: Analytics event fires
- Then: `reward_granted` event payload contains: `matchId`, `playerId` (UUID only — no display name per PII policy), `coinReward` (actual amount granted), `gameMode`, `outcome`, `firstWinApplied` (boolean), `kills`, `assists`, `survivalTimeSec`; event is emitted via the Analytics/Telemetry system's async emitter

**AC-RS-20 — first_win_bonus_applied event fires only when bonus applied**
- Given: A player wins and the first-win bonus is included in the reward
- When: Grant completes
- Then: `first_win_bonus_applied` event is emitted with `matchId`, `playerId`, `bonusAmount = FIRST_WIN_BONUS_COINS`; this event is NOT emitted on matches where `firstWinApplied = false`

---

*End of Document*
