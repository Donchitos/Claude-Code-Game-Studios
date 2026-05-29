# Quest / Mission System — Game Design Document

> **System**: Quest / Mission System
> **Priority**: Alpha
> **Layer**: Feature
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

The Quest / Mission System gives every BRAWLZONE session a daily purpose beyond the raw ranked grind. It presents players with a set of tiered objectives — Daily (3 slots, reset UTC midnight), Weekly (2 slots, reset UTC midnight Monday), and permanent Milestone achievements — each tracking specific in-match actions drawn from the full `match_result_for_quests` fan-out event emitted by Match Flow. Progress is tracked server-side with atomic counters stored in PostgreSQL and cached in Redis; completion triggers a reward grant bundled atomically through the Currency System (Coins) and a bonus XP grant through XP & Progression. Quest content (available pools, reset schedules, reward amounts) lives in Remote Config cold keys so the live team can tune without a server deploy. At Alpha launch, quest assignment is fully server-side with no player choice; re-roll is deferred to post-Alpha.

---

## 2. Player Fantasy

### The Daily Ritual

The intended feeling is: "I open the app and already know what I'm doing today."

Before a player even chooses a mode or character, the quest panel tells them which specific things are worth doing in their next few matches. That framing transforms a session from "play until I feel like stopping" into "I have three things to knock out." The player commits to a session with purpose, not inertia.

The emotional arc is **Check → Hunt → Cross Off**:

> You glance at your quests. One says "Deal 5,000 damage." You're 3,200 in. You queue for Squad Brawl because you know you can deal damage freely in 3v3. You play two matches. You check back and the progress bar is full. The reward populates. You feel the click of completing something.

That "click" is the core satisfaction this system must deliver. It is not about the Coin reward amount — it is about the closure of having finished what you set out to do.

### Progress Visibility Creates Momentum

Players must be able to see their progress between matches. A quest with no visible counter is not motivating — it is a mystery. A quest that shows "3,200 / 5,000 damage dealt" turns every match into measurable progress. The gap between the current value and the target should feel closable. Quest targets are sized so that a player can realistically finish a Daily quest in 2–5 matches and a Weekly quest in 8–20 matches.

### Milestones as Long-Arc Pride

Milestone quests are permanent. They never reset. They are the evidence of sustained play — the things you have done over the whole lifetime of your account. When a Milestone finally completes after weeks of accumulation, the reward weight should feel commensurate: it is not a daily coffee, it is an achievement.

Players should feel that their Milestone progress is never lost, never at risk, and always accumulating in the background even when they are not thinking about it.

### Quests That Explore the Roster

Quest types that require a specific character or a specific ability are by design. They push players toward the breadth of the roster and the depth of the ability pool. A player who has used only Vex for 50 matches and gets a "Play 5 matches with Grim" quest is nudged toward experiencing a new playstyle. Done right, this generates pleasant discovery — "I actually like Grim" — rather than punitive detours. Quest targets for character-specific objectives are set low enough that they do not feel coercive (2–5 matches, not 20).

---

## 3. Detailed Rules

### 3.1 Quest Tiers

| Tier | Slots | Reset Schedule | Persistence | Reward Scale |
|---|---|---|---|---|
| **Daily** | 3 | UTC midnight every day | Resets to 3 new quests at reset; incomplete quests are discarded | Low |
| **Weekly** | 2 | UTC midnight every Monday | Resets to 2 new quests at weekly reset; incomplete quests are discarded | Medium |
| **Milestone** | Uncapped (pool-limited) | Never resets | Permanent; completion is recorded in player profile; new milestones unlock from the pool as prior ones complete | High |

**Slot behavior:** A player always has exactly 3 active Daily quests and exactly 2 active Weekly quests (assuming the pool contains enough distinct quests). Milestone quests are assigned as a running list: when a player completes a Milestone, the system automatically assigns the next uncompleted Milestone from the pool in pool-defined order. The number of simultaneously visible Milestone quests is capped at `MILESTONE_ACTIVE_DISPLAY_CAP` (default: 5).

---

### 3.2 Quest Assignment

#### Daily and Weekly Assignment

At the moment of daily or weekly reset (UTC midnight and UTC midnight Monday respectively), the system runs the **Quest Assignment Job** for every active player who has logged in within the last `QUEST_ASSIGNMENT_LOOKBACK_DAYS` (default: 14 days). For players outside this window, assignment is deferred and runs lazily on their next login.

**Assignment algorithm (MVP — no player choice):**

1. Retrieve the current active quest pool for the tier from Remote Config (`quest.dailyPool` / `quest.weeklyPool`). The pool is a JSON array of quest definition IDs.
2. Exclude quest definitions that the player already completed in the immediately preceding period (to avoid immediate repeats where pool size permits). If pool size after exclusion is less than the slot count, allow repeats.
3. Shuffle the remaining eligible definitions using server-side CSPRNG.
4. Select the first N definitions where N equals the slot count for the tier.
5. Write `quest_progress` records for each selected quest (see §3.5 schema).

**Lazy assignment (player logs in after reset):** If a player logs in and their quest slots are empty for the current period (assignment job did not run for them, or they are a new player), assignment runs immediately on login before the profile payload is returned to the client.

**New player first-login assignment:** On first login, all three tiers are assigned simultaneously. Milestones are assigned in pool-defined order from position 0.

---

### 3.3 Quest Types and Progress Tracking

Each quest definition has a `questType`, a `target` value (the count required for completion), and optional `parameters` (character ID, mode ID, ability ID). The `current` counter is incremented server-side atomically when a matching match completion event arrives.

| Quest Type | `questType` enum | Tracked Stat | Parameters |
|---|---|---|---|
| Win N matches (any mode) | `WIN_MATCHES_ANY` | `outcome = "win"` | None |
| Win N matches in specific mode | `WIN_MATCHES_MODE` | `outcome = "win"` AND `gameMode = param.modeId` | `modeId: string` |
| Play N matches with character | `PLAY_MATCHES_CHARACTER` | `characterId = param.characterId` | `characterId: string` |
| Deal N total damage | `DEAL_DAMAGE_TOTAL` | `damageDealt` (sum per match) | None |
| Use ability N times | `USE_ABILITY_N_TIMES` | `abilityUsed` events count per match for `param.abilityId` | `abilityId: string` |
| Get N kills | `GET_KILLS` | `eliminations` (sum per match) | None |
| Get N assists | `GET_ASSISTS` | `assists` (sum per match) | None |
| Survive N minutes total | `SURVIVE_MINUTES` | `matchDurationSec / 60` (per match the player survived, i.e., did not finish in last place in FFA, or did not lose in Duel) | None |
| Play N matches of mode | `PLAY_MATCHES_MODE` | `gameMode = param.modeId` | `modeId: string` |

**Damage tracking note:** The `match_result_for_quests` event from Match Flow does not currently include `damageDealt` per player. The Quest System requires Match Flow to include `damageDealt` in the `MatchResultForQuests` payload. This is a **required addition** to the interface defined in Match Flow §4.4 before this quest type can be supported at Alpha. See §6.2 for the updated interface.

**Ability use tracking note:** Match events include `abilityUsed` at a per-match summary level. The Quest System requires the `match_result_for_quests` payload to include a per-player map of `{ [abilityId: string]: number }` representing how many times each ability was used in the match. This is also a **required addition** to the Match Flow interface. See §6.2.

**Survive minutes tracking:** A player is considered to have "survived" a match if `outcome !== "loss"` in Duel, or `placement <= 4` in 8-player FFA (top half), or `outcome !== "loss"` in Squad Brawl. The duration added is the full `matchDurationSec` converted to decimal minutes.

---

### 3.4 Progress Tracking — Atomic Increment

Progress is updated by the Quest Progress Worker, a server-side process that:

1. Receives the `match_result_for_quests` event from Match Flow (fire-and-forget fan-out, Step 5).
2. For each player in the event's `playerResults`, fetches the player's active quest records from Redis (falls back to PostgreSQL if cache miss).
3. For each active quest, evaluates whether the match contributes progress using the quest type logic in §3.3.
4. For each contributing quest, increments the `current` counter atomically using a PostgreSQL `UPDATE ... SET current = LEAST(current + delta, target) WHERE quest_id = $1 AND matchId NOT IN (SELECT matchId FROM quest_match_dedup WHERE quest_id = $1)` pattern combined with a dedup entry insert (see Edge Case §5.2).
5. If `current >= target` after increment: marks quest as `status = "completed"`, records `completed_at = NOW()`, and fires the quest reward grant (see §3.6).
6. Updates the Redis cache entry for the player's quest state.

**Atomicity:** Each quest increment is a single `UPDATE` in a PostgreSQL transaction. The dedup insert and the counter increment share the same transaction. If the transaction fails, no increment occurs and no dedup entry is written, making the operation safely retryable.

---

### 3.5 Quest State Storage

#### PostgreSQL Schema

```sql
-- Quest definitions (authored by live team, loaded from Remote Config)
-- These are managed as Remote Config content, not as a database table at MVP.
-- The pool JSON is stored in Remote Config under quest.dailyPool, quest.weeklyPool,
-- quest.milestonePool keys. See §7 for Remote Config key definitions.

-- Active quest progress per player
CREATE TABLE quest_progress (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id       uuid          NOT NULL REFERENCES player_profiles(user_id),
  quest_def_id    varchar(64)   NOT NULL,   -- References a quest definition in Remote Config pool
  tier            varchar(16)   NOT NULL,   -- 'daily' | 'weekly' | 'milestone'
  status          varchar(16)   NOT NULL DEFAULT 'active',  -- 'active' | 'completed' | 'expired'
  current         integer       NOT NULL DEFAULT 0,
  target          integer       NOT NULL,
  quest_type      varchar(32)   NOT NULL,
  parameters      jsonb         NOT NULL DEFAULT '{}',
  assigned_at     timestamptz   NOT NULL DEFAULT NOW(),
  period_start    timestamptz   NOT NULL,   -- Start of the reset period this quest was assigned in
  completed_at    timestamptz   NULL,
  reward_granted  boolean       NOT NULL DEFAULT false,
  created_at      timestamptz   NOT NULL DEFAULT NOW(),
  updated_at      timestamptz   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quest_progress_player_status
  ON quest_progress(player_id, status, tier);

CREATE INDEX idx_quest_progress_period
  ON quest_progress(player_id, tier, period_start);

-- Dedup log: one row per (quest_id, match_id) pair, prevents double-counting
CREATE TABLE quest_match_dedup (
  quest_id        uuid          NOT NULL REFERENCES quest_progress(id),
  match_id        varchar(64)   NOT NULL,
  processed_at    timestamptz   NOT NULL DEFAULT NOW(),
  PRIMARY KEY (quest_id, match_id)
);
```

#### TypeScript Interface

```typescript
interface QuestProgress {
  id: string;                        // UUID
  playerId: string;                  // UUID — FK to player_profiles
  questDefId: string;                // Quest definition ID from Remote Config pool
  tier: "daily" | "weekly" | "milestone";
  status: "active" | "completed" | "expired";
  current: number;                   // Current progress counter (0 ≤ current ≤ target)
  target: number;                    // Required count for completion
  questType: QuestType;              // Enum: see §3.3
  parameters: QuestParameters;       // { characterId?, modeId?, abilityId? }
  assignedAt: string;                // ISO 8601
  periodStart: string;               // ISO 8601 — start of the reset period
  completedAt: string | null;        // ISO 8601 or null if not yet completed
  rewardGranted: boolean;            // true after reward has been atomically delivered
}

type QuestType =
  | "WIN_MATCHES_ANY"
  | "WIN_MATCHES_MODE"
  | "PLAY_MATCHES_CHARACTER"
  | "DEAL_DAMAGE_TOTAL"
  | "USE_ABILITY_N_TIMES"
  | "GET_KILLS"
  | "GET_ASSISTS"
  | "SURVIVE_MINUTES"
  | "PLAY_MATCHES_MODE";

interface QuestParameters {
  characterId?: string;   // Used by PLAY_MATCHES_CHARACTER
  modeId?: string;        // Used by WIN_MATCHES_MODE, PLAY_MATCHES_MODE
  abilityId?: string;     // Used by USE_ABILITY_N_TIMES
}
```

#### Redis Cache

Each player's active quest state is cached under `quest_state:{playerId}` as a JSON-serialized `QuestProgress[]` array with a TTL of `QUEST_CACHE_TTL_SECONDS` (default: 300s). The cache is invalidated and rebuilt from PostgreSQL on:

- Quest assignment (reset or lazy)
- Any quest completion event
- Any progress increment that crosses a 10% completion threshold (to ensure client-visible progress updates are prompt)
- Explicit cache invalidation call from the Quest Progress Worker after each match event processed

---

### 3.6 Quest Completion and Reward Grant

When a quest's `current` counter reaches `target`, the Quest Progress Worker executes the completion sequence within the same PostgreSQL transaction as the final increment:

```
quest_progress.status     → 'completed'
quest_progress.completed_at → NOW()
quest_progress.reward_granted → false  (will be set true after grant)
```

After the transaction commits, the worker fires the reward grant:

1. **Coin grant** — calls Currency System with `grantCoins({ playerId, amount: quest.coinReward, reason: "quest_complete", questId: quest.id })`. The Currency System applies its own atomic idempotency guard using `questId` as the idempotency key.
2. **XP bonus grant** — calls XP & Progression with `grantXPBonus({ playerId, amount: quest.xpBonus, reason: "quest_complete", questId: quest.id })`. Same idempotency guard pattern.
3. **BPXP grant** — emits `quest_completed_bpxp { questId: quest.id, bpxpAwarded: quest.bpxpBonus }` to the Battle Pass system so it can credit Battle Pass XP from quest completion. `bpxpAwarded` is `0` for quests that do not award Battle Pass XP. Same idempotency guard pattern using `questId`.
4. Upon confirmation from all systems, sets `quest_progress.reward_granted = true`.

If either grant call fails, `reward_granted` remains `false`. A background reconciliation job runs every `QUEST_REWARD_RECONCILE_INTERVAL_MIN` (default: 15 minutes) scanning for completed quests with `reward_granted = false` and retrying the grant. This ensures no reward is permanently lost due to a transient downstream failure.

The reward grant fires whether or not the player is currently online. There is no client-triggered reward collection step — the Currency System and XP & Progression systems update the player's balance directly on the server.

**Client notification:** When the player is online, the Quest Progress Worker emits `quest_completed { questId, tier, coinReward, xpBonus, bpxpAwarded, newCoinBalance, newXP }` via Socket.io to the player's connection. If the player is offline, the notification is delivered on next login as part of the profile payload (`pendingQuestRewards[]` array).

---

### 3.7 Daily Reset

**Reset time:** UTC 00:00:00 every day (not rolling 24 hours from first login).

**Reset sequence:**

1. A scheduled server job fires at UTC 00:00:00.
2. For all active players (within `QUEST_ASSIGNMENT_LOOKBACK_DAYS`): all `quest_progress` rows with `tier = 'daily'` and `status = 'active'` for the expiring period are set to `status = 'expired'`.
3. New Daily quest rows are assigned per §3.2.
4. Redis cache for affected players is invalidated.

**Partial-progress discard:** When Daily quests reset, incomplete quests (status `active`) are expired. Partial progress is not carried over to the next day's quests. This is intentional: daily quests are meant to be completable within a single day. The new day's quests are independent fresh objectives.

**Uncompleted completed quests:** Quests with `status = 'completed'` and `reward_granted = true` are retained in PostgreSQL for history (not expired). Quests with `status = 'completed'` and `reward_granted = false` are retained and the reconciliation job continues retrying the reward grant — expiry does not strip a deserved reward.

---

### 3.8 Weekly Reset

**Reset time:** UTC 00:00:00 every Monday.

**Reset sequence:** Identical to Daily reset but scoped to `tier = 'weekly'`. The same expiry and assignment logic applies. Weekly quests that were in progress at the reset cutoff are expired without carry-over.

---

### 3.9 Milestone Quests

Milestone quests never reset. They represent cumulative lifetime achievements.

**Assignment:** On first login, the player is assigned up to `MILESTONE_ACTIVE_DISPLAY_CAP` (default: 5) milestone quests in pool-order. When a milestone completes, the next uncompleted milestone in the pool is assigned to fill the display cap, up to the cap limit. If the pool is exhausted, the display count decreases naturally.

**Completion:** Milestone completion triggers a reward grant (see §3.6) with a higher reward scale than Daily or Weekly (see §4.1). The quest is marked `status = 'completed'` permanently — it does not expire.

**Re-assignment:** Milestones are never re-assigned after completion. Each milestone definition is completed at most once per player.

---

### 3.10 Re-Roll Mechanic

**Decision: Not at MVP (Alpha).**

Re-rolling daily quests (spending Diamonds to discard and replace a quest) is a player-quality-of-life feature that also has monetization implications. It is deferred to post-Alpha because:

1. At MVP the quest pool may be small; re-roll value is minimal when the replacement draw could easily be similar to the discarded quest.
2. The Diamond currency system is also being finalized in parallel; adding Diamond spending vectors before the economy is balanced creates risk.
3. Re-roll data from similar games (Brawl Stars, Clash Royale) shows the mechanic is most engaging when the player has a large pool of quests to draw from and a meaningful reason to avoid certain quest types (e.g., quests requiring unowned characters).

**Reserved tuning knob:** `QUEST_REROLL_COST_DIAMONDS` is defined in §7 with value `null` (not at MVP). The server-side data model supports re-roll without schema changes (a re-roll simply expires the current active quest and triggers the assignment job for one new quest in that slot). When the feature is enabled post-Alpha, only the business logic layer and Remote Config need to change.

---

## 4. Formulas

### 4.1 Reward Scale by Tier

Reward amounts are data-driven and stored in the quest definition objects in Remote Config (see §7). The following defines the **default launch values** and the scale relationships that must be maintained.

| Tier | Coin Reward | XP Bonus | Design Rationale |
|---|---|---|---|
| Daily | 75 Coins | 50 XP | Completable in a session; reward feels like a small bonus per play day |
| Weekly | 250 Coins | 150 XP | Requires sustained play across the week; reward is ~3× daily but requires ~5× the effort |
| Milestone | 600 Coins | 400 XP | One-time permanent achievement; highest single reward; felt as a milestone, not routine income |

**Scaling invariant:** The following inequalities must hold at all times to avoid incentive distortions:

```
daily_coin_reward < weekly_coin_reward < milestone_coin_reward
daily_xp_bonus   < weekly_xp_bonus   < milestone_xp_bonus

weekly_coin_reward >= 3 × daily_coin_reward        (weekly should feel worth waiting for)
milestone_coin_reward >= 2 × weekly_coin_reward    (milestone should feel clearly special)
```

**Example — violation detection:**
If a live-ops tuning change sets `daily_coin_reward = 150` and `weekly_coin_reward = 300`, the ratio 300/150 = 2× is below the required 3×. This is a policy violation; the Remote Config change should be rejected or adjusted.

---

### 4.2 Progress Normalization

Used for client-side progress bar rendering and analytics.

```
completionPct = (current / target) × 100

where:
  current  = quest_progress.current  (integer, 0 ≤ current ≤ target)
  target   = quest_progress.target   (integer, > 0)
  result   = float, clamped to [0.0, 100.0]

completionPct is clamped: completionPct = MIN(100.0, (current / target) × 100)
```

**Example — Deal Damage quest, halfway:**
```
current  = 2,500
target   = 5,000
completionPct = (2,500 / 5,000) × 100 = 50.0%
```

**Example — Win Matches quest, just completed:**
```
current  = 3
target   = 3
completionPct = (3 / 3) × 100 = 100.0%
```

**Rendering rule:** The client renders a progress bar as a fill from 0% to 100%. At 100%, the bar shows a "Complete" state and the reward claim animation plays. The bar never renders above 100% even if `current` somehow exceeds `target` (which the `LEAST(current + delta, target)` SQL constraint prevents at the database layer).

---

### 4.3 Quest Target Sizing Guidelines

Quest targets are authored in the Remote Config pool definitions. The following guidelines define the intended effort-per-tier (not enforced by the engine, but enforced by content authoring review):

| Quest Type | Daily Target Range | Weekly Target Range | Milestone Target Range |
|---|---|---|---|
| Win N matches | 2–3 | 8–12 | 50–200 |
| Play N matches with character | 3–5 | 10–15 | 50–150 |
| Deal N damage | 3,000–8,000 | 15,000–40,000 | 200,000–500,000 |
| Use ability N times | 5–10 | 20–40 | 200–500 |
| Get N kills | 3–8 | 15–30 | 100–300 |
| Get N assists | 3–8 | 15–30 | 100–300 |
| Survive N minutes | 10–20 | 40–80 | 500–1,500 |
| Play N matches of mode | 3–5 | 10–15 | 50–150 |

**Calibration basis:** A typical Duel match lasts 3–5 minutes and produces ~1,500–3,000 damage per player. A typical 3v3 Squad Brawl match lasts 5–8 minutes and produces ~2,000–5,000 damage per active player. These baselines inform the damage target ranges above.

**Example — Daily "Deal 5,000 damage" target sizing check:**
```
Average damage per Duel match: ~2,000
Matches needed: CEIL(5,000 / 2,000) = 3 matches
3 matches × ~4 min/match = ~12 minutes of play
Assessment: within the 2–5 match guideline → VALID target
```

---

### 4.4 Re-Roll Cost Formula

**Not at MVP.** Reserved for post-Alpha.

```
QUEST_REROLL_COST_DIAMONDS = null  (feature disabled at MVP)

Post-Alpha formula (placeholder, not yet approved):
  reroll_cost = QUEST_REROLL_BASE_COST_DIAMONDS
  (flat cost per re-roll, no per-day limit defined yet)
```

When the feature is enabled, the cost will be authored in Remote Config as `quest.rerollCostDiamonds`.

---

## 5. Edge Cases

### 5.1 Match Progress Event Arrives After Daily Reset

**Scenario:** A player completes a match at 23:59:58 UTC. The match end sequence completes and the `match_result_for_quests` event arrives at the Quest Progress Worker at 00:00:03 UTC — after the daily reset has run.

**Ruling:** Progress is attributed to the quest period active at **match start time**, not at event receipt time. The Match Flow `match_result_for_quests` event includes `matchStartedAt` (ISO 8601 timestamp). The Quest Progress Worker compares `matchStartedAt` to the current `period_start` values on the player's active quest records.

**Resolution:**
- If `matchStartedAt < period_start` (the match started before the current period): the worker looks up the player's **expired** quest records for the previous period (where `status = 'expired'` and the `period_start` matches the prior period).
- If the expired quest has `status = 'expired'` and `reward_granted = false` (i.e., it expired before completion), the progress is applied to the expired record — the counter increments, and if it reaches `target`, completion and reward fire as normal.
- If the expired quest is already `completed` or already at `target`, the event is a no-op for that quest.
- The player's current-period quests (just assigned at reset) are **not** credited for this late-arriving event — the match predates them.

**Why this rule:** Players should not lose progress for a match they genuinely played before reset. Attributing progress to the correct period preserves fairness. The window for late events is bounded by `MATCH_RESULT_MAX_DELAY_S` (default: 30s), beyond which a match event is treated as anomalous and logged for ops review.

---

### 5.2 Duplicate Match Completion Event

**Scenario:** Due to a retry in the Match Flow fan-out or a network-level duplicate delivery, the Quest Progress Worker receives the same `match_result_for_quests` event for the same `matchId` twice for the same player.

**Resolution:** The `quest_match_dedup` table (see §3.5) stores `(quest_id, match_id)` pairs. Before processing any progress increment, the worker inserts into `quest_match_dedup`. The `PRIMARY KEY (quest_id, match_id)` constraint causes the second insert to fail with a unique violation.

```sql
-- Dedup check (within the same transaction as the counter increment)
INSERT INTO quest_match_dedup (quest_id, match_id)
VALUES ($1, $2)
ON CONFLICT (quest_id, match_id) DO NOTHING
RETURNING quest_id;
-- If no row returned: this (quest_id, match_id) pair was already processed.
-- Skip the counter increment entirely.
```

If the dedup insert returns no rows (conflict), the increment is skipped and the transaction commits harmlessly. No double-counting occurs. The event is logged at DEBUG level: `QUEST_DEDUP_SKIP { questId, matchId, playerId }`.

---

### 5.3 Player Completes Quest While Offline

**Scenario:** A player is disconnected when the `quest_completed` notification fires (e.g., they quit the app between submitting to the match and receiving results).

**Resolution:** Reward delivery (§3.6) is entirely server-side. The Currency System and XP & Progression systems write grants directly to the player's profile in PostgreSQL. The player's balances are updated regardless of connection state. No reward is held pending a client acknowledgment.

When the player reconnects and loads their profile, the updated Coin balance and XP total reflect the completed quest. The pending quest reward is surfaced to the client via the `pendingQuestRewards[]` array in the profile payload returned on login:

```typescript
// Included in the profile payload on login if pending rewards exist
pendingQuestRewards: Array<{
  questId: string;
  tier: "daily" | "weekly" | "milestone";
  coinReward: number;
  xpBonus: number;
  bpxpAwarded: number;   // Battle Pass XP credited from this quest; 0 if quest awards no BPXP
  completedAt: string;   // ISO 8601
}>
```

The client shows a "Quest Complete" notification for each entry in `pendingQuestRewards` on the first screen load after login. After displaying, the client sends `ack_pending_rewards { questIds: string[] }` and the server clears those entries from the pending list.

---

### 5.4 All 3 Daily Quests Completed Before Midnight

**Scenario:** A highly active player completes all 3 Daily quests before UTC midnight. They want more quests.

**Resolution:** No new Daily quests are assigned until the next UTC midnight reset. The quest panel shows all 3 slots in "Complete" state with a countdown to the next reset. The player is not penalized and is not blocked from playing — they simply have no Daily quest progress to track until reset. Weekly and Milestone quests continue accumulating.

**No overflow to bonus quests at MVP.** A "bonus quest" mechanic (earning extra quests by completing the daily set) is a post-Alpha stretch feature, noted as a future tuning option under `QUEST_DAILY_OVERFLOW_ENABLED` in §7.

---

### 5.5 Character Required for Quest Is Unlocked Mid-Quest

**Scenario:** A player is assigned a "Play 3 matches with Grim" Daily quest before they have unlocked Grim. Mid-day, they unlock Grim via the progression system. Matches played with Grim after unlocking should count toward the quest.

**Resolution:** Quest progress evaluation is always based on the **current match event**, not on ownership state at assignment time. If a match is played with Grim and Grim's `characterId` matches the quest parameter, the counter increments regardless of when Grim was unlocked.

**Matches played before unlocking:** Matches played before Grim was unlocked cannot have Grim's `characterId` in the event (the player could not have selected Grim), so no retroactive crediting is needed — the system naturally handles this correctly without special-casing.

**Partial progress is valid:** If the player completes 1 match with Grim after unlocking (quest progress: 1/3), then the quest resets at midnight with progress 1/3 unfinished, the incomplete quest expires as normal. Partial credit from the unlock-day match is not carried over — this follows the standard daily expiry behavior (§3.7).

---

### 5.6 Quest Pool Is Exhausted (Fewer Definitions Than Slots)

**Scenario:** The live team has authored only 2 quest definitions in `quest.dailyPool` but the Daily tier requires 3 slots.

**Resolution:** The assignment algorithm (§3.2) assigns all available definitions first. If the pool is smaller than the slot count after excluding recently completed quests, the repeat-exclusion rule is relaxed and repeats are allowed. If the raw pool size is smaller than the slot count (e.g., only 2 definitions exist for 3 slots), the player is assigned 2 quests and the third slot remains empty.

**Empty slot behavior:** An empty quest slot is rendered in the UI as a "Quest coming soon" placeholder. The player is not penalized. The ops team is alerted via an automated pool-size check that runs at each assignment cycle: if `pool_size < slot_count`, a `QUEST_POOL_UNDERSIZED { tier, poolSize, slotCount }` warning event is emitted to the logging system.

**Never crash on empty pool:** If the pool is completely empty (0 definitions), all slots are assigned as empty. The system continues operating normally. Only the warning event is emitted.

---

### 5.7 Quest Reward Grant Fails After Completion

**Scenario:** The Currency System is temporarily unavailable when the Quest Progress Worker attempts the Coin grant after a quest completes.

**Resolution:** The `reward_granted` flag remains `false` on the `quest_progress` row. The background reconciliation job (§3.6) scans for `status = 'completed'` AND `reward_granted = false` every `QUEST_REWARD_RECONCILE_INTERVAL_MIN` (default: 15 minutes) and retries both the Coin and XP grants. Grants use the `questId` as an idempotency key in the Currency System and XP & Progression, ensuring that a successful retry does not double-grant even if both systems recorded a partial state on the failed attempt.

The player is not notified of the failure. They receive the `quest_completed` notification (with reward amounts shown) optimistically; if the grant is delayed, the balances on their profile will update when the reconciliation job succeeds. If the grant is still pending when the player loads their profile, the balance shown is the pre-grant balance (no optimistic update on the client — consistency over speed).

---

## 6. Dependencies

### 6.1 Upstream — Quest System Consumes

| System | What the Quest System Needs | Interface | Notes |
|---|---|---|---|
| **Match Flow** | `match_result_for_quests` event after each match end | Async fan-out event (fire-and-forget from Match Flow Step 5); see §6.2 for extended interface | Primary trigger for all progress updates |
| **Player Profile** | Player's active quest state at login; `user_id` for all operations | Profile payload includes `activeQuests[]`; Quest System writes back via `quest_progress` table | Quest state is NOT stored in Player Profile directly — it lives in `quest_progress` table, but Profile is the identity anchor |
| **Remote Config** | `quest.dailyPool`, `quest.weeklyPool`, `quest.milestonePool` (quest definition JSON arrays); `quest.dailyResetEnabled`, `quest.weeklyResetEnabled` feature flags; reward amount overrides | Cold keys read at server startup and re-fetched after config push | Quest pool and reward amounts must be tunable without server deploy |
| **Analytics / Telemetry** | `MATCH_ENDED` event context for correlation | Telemetry emits structured events; Quest System emits its own `QUEST_PROGRESS_UPDATED` and `QUEST_COMPLETED` events into the same pipeline | ILogger interface; PII policy: `playerId` is a pseudonymous UUID, not PII |
| **Authentication** | `user_id` validation for all API endpoints | JWT validated by Supabase Auth middleware before any quest endpoint is reached | No direct dependency — auth is middleware |

### 6.2 Required Extension to Match Flow Interface

The `MatchResultForQuests` interface defined in Match Flow §4.4 must be extended to support the `DEAL_DAMAGE_TOTAL` and `USE_ABILITY_N_TIMES` quest types. The following replaces the MVP interface:

```typescript
// Sent to Quest/Mission System (Match Flow Step 5) — EXTENDED from match-flow.md §4.4
interface MatchResultForQuests {
  matchId: string;
  gameMode: GameMode;
  matchDurationSec: number;
  matchStartedAt: string;            // ISO 8601 — needed for late-event period attribution (§5.1)
  playerResults: Array<{
    playerId: string;
    characterId: string;
    outcome: "win" | "loss" | "draw";
    placement: number;
    eliminations: number;
    assists: number;
    score: number;
    damageDealt: number;             // NEW: total damage dealt by this player this match
    abilityUseCounts: {              // NEW: map of abilityId → use count this match
      [abilityId: string]: number;
    };
    survived: boolean;               // NEW: true if player meets survival criteria (§3.3)
  }>;
}
```

This interface extension is a **blocking dependency** for the `DEAL_DAMAGE_TOTAL` and `USE_ABILITY_N_TIMES` quest types. All other quest types can be supported with the existing match-flow.md §4.4 fields.

### 6.3 Downstream — Quest System Produces / Notifies

| System | What the Quest System Provides | Interface | Notes |
|---|---|---|---|
| **Currency System** | `grantCoins` call on quest completion | Synchronous RPC with idempotency key (`questId`) | Quest completion is the trigger; Currency System owns the balance |
| **XP & Progression** | `grantXPBonus` call on quest completion | Synchronous RPC with idempotency key (`questId`) | Bonus XP on top of match XP; both fire from quest completion |
| **Battle Pass** | `quest_completed_bpxp { questId, bpxpAwarded }` event on quest completion | Same event/callback pattern as other grant calls; idempotency key is `questId` | Battle Pass credits BPXP from quest completion; `bpxpAwarded` is 0 for quests with no BPXP reward |
| **Client (Socket.io)** | `quest_completed` and `quest_progress_updated` events | Socket.io emit to the player's connection room | Real-time progress updates; pending rewards on reconnect |
| **Player Profile** | Reads `user_id`; does not write directly to `player_profiles` table | Profile reads `quest_progress` via join or Quest API | Profile queries quest state on-demand; Quest System is the authoritative store |
| **Analytics / Telemetry** | `QUEST_PROGRESS_UPDATED { playerId, questId, tier, current, target, completionPct }` and `QUEST_COMPLETED { playerId, questId, tier, coinReward, xpBonus, bpxpAwarded }` | Async fire-and-forget to telemetry pipeline | Enables funnel analysis: how many players complete their daily quests? |

---

## 7. Tuning Knobs

All values are configurable without a code change. Values marked **RC** are Remote Config cold keys (`quest.*` namespace) tunable by the live team. Values marked **ENV** are server environment variables.

| Knob | Key / Env Var | Default | Safe Range | Gameplay Effect | RC / ENV |
|---|---|---|---|---|---|
| Daily quest slot count | `quest.dailySlotCount` | `3` | 1–5 | Number of Daily quests the player sees per day. Increasing adds variety but increases reward throughput — adjust reward amounts if changed. | RC |
| Weekly quest slot count | `quest.weeklySlotCount` | `2` | 1–4 | Number of Weekly quests per week. Same caution as daily slot count. | RC |
| Milestone active display cap | `quest.milestoneActiveCap` | `5` | 3–10 | Max milestone quests shown simultaneously. Higher values give more tracking visibility; lower values create focus. | RC |
| Daily coin reward | `quest.dailyCoinReward` | `75` | 25–300 | Coin reward per completed Daily quest. Must stay below weekly. See §4.1 scaling invariant. | RC |
| Weekly coin reward | `quest.weeklyCoinReward` | `250` | 75–1,000 | Coin reward per completed Weekly quest. Must be ≥ 3× daily. | RC |
| Milestone coin reward | `quest.milestoneCoinReward` | `600` | 200–2,500 | Coin reward per completed Milestone. Must be ≥ 2× weekly. | RC |
| Daily XP bonus | `quest.dailyXpBonus` | `50` | 10–200 | XP bonus per completed Daily quest. Must stay below weekly. | RC |
| Weekly XP bonus | `quest.weeklyXpBonus` | `150` | 30–600 | XP bonus per completed Weekly quest. Must be ≥ 3× daily. | RC |
| Milestone XP bonus | `quest.milestoneXpBonus` | `400` | 100–2,000 | XP bonus per completed Milestone. Must be ≥ 2× weekly. | RC |
| Quest assignment lookback window | `quest.assignmentLookbackDays` | `14` | 3–30 | Days of inactivity before a player is excluded from the proactive assignment job (assignment runs lazily at login instead). Lower = less background work; higher = fewer login-time delays. | RC |
| Quest cache TTL | `QUEST_CACHE_TTL_SECONDS` | `300` | 60–900 | Redis TTL for `quest_state:{playerId}` cache key. Lower = fresher data, more DB reads; higher = stale risk after progress update. | ENV |
| Reward reconcile interval | `QUEST_REWARD_RECONCILE_INTERVAL_MIN` | `15` | 5–60 | Minutes between background scans for `reward_granted = false` completed quests. Lower = faster recovery from grant failures; higher = less DB polling. | ENV |
| Re-roll cost (disabled at MVP) | `quest.rerollCostDiamonds` | `null` (disabled) | 5–50 Diamonds | Cost in Diamonds to re-roll one Daily quest slot. `null` disables the feature entirely. Do not enable without Economy team sign-off. | RC |
| Match result max delay | `MATCH_RESULT_MAX_DELAY_S` | `30` | 10–120 | Seconds after match start time beyond which a late-arriving quest event is treated as anomalous and logged. Events within this window are attributed to the correct period (§5.1). | ENV |
| Daily overflow enabled (future) | `quest.dailyOverflowEnabled` | `false` | boolean | When `true`, completing all daily quests before reset unlocks a bonus quest slot. Not at MVP. | RC |
| Quest daily pool | `quest.dailyPool` | (authored by live team) | Array of quest def IDs | The set of quest definitions the daily assignment algorithm draws from. Must contain ≥ `quest.dailySlotCount` definitions. | RC |
| Quest weekly pool | `quest.weeklyPool` | (authored by live team) | Array of quest def IDs | The set of quest definitions the weekly assignment algorithm draws from. Must contain ≥ `quest.weeklySlotCount` definitions. | RC |
| Quest milestone pool | `quest.milestonePool` | (authored by live team) | Ordered array of quest def IDs | The ordered list of milestone definitions. Assignment follows pool order. | RC |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and are independently verifiable by automated test or documented manual QA.

---

### 8.1 Quest Assignment

**AC-01 — Daily quests assigned at UTC midnight reset**
- Given: A player has been active within the last 14 days
- When: UTC 00:00:00 fires
- Then: All previous Daily quests with `status = 'active'` are set to `status = 'expired'`; exactly 3 new `quest_progress` rows are created for the player with `tier = 'daily'` and `status = 'active'`; `period_start` equals the current UTC date at 00:00:00

**AC-02 — Weekly quests assigned at UTC midnight Monday**
- Given: A player has been active within the last 14 days
- When: UTC 00:00:00 Monday fires
- Then: All previous Weekly quests with `status = 'active'` are set to `status = 'expired'`; exactly 2 new `quest_progress` rows are created with `tier = 'weekly'` and `status = 'active'`

**AC-03 — Lazy assignment on login for inactive player**
- Given: A player last logged in 15 days ago (outside the 14-day lookback window); daily and weekly resets have occurred since their last login
- When: The player logs in
- Then: Quest assignment runs immediately before the profile payload is returned; the player receives 3 active Daily quests and 2 active Weekly quests in the current period; no error is returned to the client

**AC-04 — First login assigns all tiers**
- Given: A brand-new player account with no quest history
- When: The player logs in for the first time
- Then: 3 Daily quests, 2 Weekly quests, and up to 5 Milestone quests are assigned in the same login response; all have `status = 'active'`

**AC-05 — Assignment draws from Remote Config pool**
- Given: `quest.dailyPool` contains exactly 5 quest definition IDs
- When: Daily assignment runs
- Then: The 3 assigned quests are drawn from those 5 IDs; no quest ID outside the pool is assigned

**AC-06 — Repeat exclusion respects pool size**
- Given: `quest.dailyPool` contains exactly 3 quest definition IDs; the player completed all 3 in the previous day
- When: Daily assignment runs
- Then: All 3 quests are re-assigned (repeat allowed when pool is too small to avoid repeats); no assignment error; no empty slots

---

### 8.2 Progress Tracking

**AC-07 — Win Matches quest increments on win**
- Given: A player has an active `WIN_MATCHES_ANY` quest with `target = 3`, `current = 1`
- When: The player wins a match and the `match_result_for_quests` event is received
- Then: `quest_progress.current` becomes 2 within 5 seconds of the event receipt; Redis cache is updated

**AC-08 — Win Matches quest does not increment on loss**
- Given: A player has an active `WIN_MATCHES_ANY` quest
- When: The player loses a match
- Then: `quest_progress.current` is unchanged

**AC-09 — Mode-specific quest only counts the specified mode**
- Given: A player has an active `WIN_MATCHES_MODE` quest with `parameters.modeId = "duel_1v1"` and `current = 0`
- When: The player wins a Squad Brawl match
- Then: `quest_progress.current` remains 0 (wrong mode, no increment)

**AC-10 — Character-specific quest counts only the specified character**
- Given: A player has an active `PLAY_MATCHES_CHARACTER` quest with `parameters.characterId = "character:grim"` and `current = 0`
- When: The player plays a match with Vex
- Then: `quest_progress.current` remains 0; when the player plays a match with Grim, `current` becomes 1

**AC-11 — Damage quest accumulates across matches**
- Given: A player has an active `DEAL_DAMAGE_TOTAL` quest with `target = 5,000`, `current = 0`
- When: The player deals 2,200 damage in Match A and 2,100 damage in Match B
- Then: After Match A: `current = 2,200`; after Match B: `current = 4,300`; quest is not yet complete

**AC-12 — Ability use quest counts correctly**
- Given: A player has an active `USE_ABILITY_N_TIMES` quest with `parameters.abilityId = "ability_burstsurge"`, `target = 10`, `current = 3`
- When: The player uses `ability_burstsurge` 4 times in a match
- Then: `quest_progress.current` becomes 7; `abilityUseCounts["ability_burstsurge"]` in the event payload drives the increment

**AC-13 — Counter is capped at target (no overflow)**
- Given: A player has an active `GET_KILLS` quest with `target = 5`, `current = 4`
- When: The player gets 3 kills in a match (which would push to 7)
- Then: `quest_progress.current` is set to exactly 5 (not 7); `LEAST(current + delta, target)` SQL constraint is enforced

---

### 8.3 Quest Completion and Reward

**AC-14 — Quest completion fires within 10 seconds of final increment**
- Given: A player's `WIN_MATCHES_ANY` quest has `target = 3` and `current = 2`
- When: The player wins a match
- Then: Within 10 seconds of the `match_result_for_quests` event receipt, `quest_progress.status = 'completed'`, `completed_at` is set, `reward_granted` transitions to `true`, and the Currency System reflects the Coin grant

**AC-15 — Coin reward matches tier default**
- Given: A player completes a Daily quest
- When: The reward grant fires
- Then: The Currency System grants exactly `quest.dailyCoinReward` (default: 75) Coins to the player; `grantCoins` is called with `reason = "quest_complete"` and the correct `questId` as idempotency key

**AC-16 — XP bonus granted alongside Coin reward**
- Given: A player completes a Weekly quest
- When: The reward grant fires
- Then: XP & Progression system grants exactly `quest.weeklyXpBonus` (default: 150) bonus XP; both grants fire within the same completion event handling (not sequentially gated on each other's confirmation)

**AC-17 — quest_completed socket event sent to online player**
- Given: A player is connected via Socket.io when their quest completes
- When: The Quest Progress Worker processes the final increment
- Then: A `quest_completed { questId, tier, coinReward, xpBonus, bpxpAwarded, newCoinBalance, newXP }` event is emitted to the player's Socket.io room within 10 seconds of completion

**AC-18 — Pending reward surfaced at login for offline player**
- Given: A player was offline when their quest completed
- When: The player logs in
- Then: The profile payload includes the completed quest in `pendingQuestRewards[]` with correct `questId`, `tier`, `coinReward`, `xpBonus`, and `bpxpAwarded`; the player's Coin balance already reflects the grant (server-side delivery did not require the client)

---

### 8.4 Reset Behavior

**AC-19 — Incomplete Daily quest expires at midnight**
- Given: A player has an active Daily quest with `current = 1`, `target = 3` at 23:59:59 UTC
- When: UTC 00:00:00 fires
- Then: That quest row transitions to `status = 'expired'`; the player's next session shows 3 fresh Daily quests with `current = 0`

**AC-20 — Completed quests with pending rewards are not expired**
- Given: A player's Daily quest has `status = 'completed'` and `reward_granted = false` at midnight
- When: UTC 00:00:00 reset fires
- Then: That quest row is NOT set to `status = 'expired'`; the reconciliation job continues retrying the reward grant; the player receives their reward when the Currency System recovers

**AC-21 — Weekly reset does not reset Daily quests**
- Given: A player has 1 active Daily quest and 2 active Weekly quests on a Monday
- When: UTC 00:00:00 Monday fires (weekly reset)
- Then: Only the 2 Weekly quests are expired and re-assigned; the Daily quest is unchanged; the Daily quest will reset at UTC midnight (same day)

**AC-22 — No new Daily quests assigned before next midnight after all 3 completed**
- Given: A player completes all 3 Daily quests at 14:00 UTC
- When: The player opens the quest panel at 15:00 UTC
- Then: All 3 slots show "Complete" state; no new quests are assigned; the UI shows a countdown to next UTC midnight

---

### 8.5 Deduplication

**AC-23 — Duplicate match event does not double-increment counter**
- Given: A player has an active `WIN_MATCHES_ANY` quest with `current = 1`, `target = 3`
- When: The same `match_result_for_quests` event with `matchId = "match_123"` is delivered twice
- Then: `quest_progress.current` is 2 after the first delivery; it remains 2 after the second delivery; exactly one row exists in `quest_match_dedup` for `(questId, "match_123")`

---

### 8.6 Edge Case Handling

**AC-24 — Late event attributed to prior period**
- Given: A match started at 23:59:50 UTC; the `match_result_for_quests` event arrives at 00:00:05 UTC after reset
- When: The Quest Progress Worker processes the event
- Then: Progress is applied to the expired quest record from the prior period (not the current-period quest); if the prior-period quest thereby reaches `target`, completion and reward fire; the current-period quest `current` value is unchanged

**AC-25 — Character unlocked mid-quest counts new matches**
- Given: A player has a `PLAY_MATCHES_CHARACTER` quest for Grim but has not yet unlocked Grim; they unlock Grim during the day
- When: The player plays 2 matches with Grim after unlocking
- Then: `quest_progress.current` increments to 2 for those matches; no error or special case handling is required (the event naturally contains `characterId = "character:grim"` only when Grim is selected)

**AC-26 — Quest pool undersized warning emitted**
- Given: `quest.dailyPool` contains 2 quest definition IDs and `quest.dailySlotCount = 3`
- When: Daily assignment runs
- Then: A `QUEST_POOL_UNDERSIZED { tier: "daily", poolSize: 2, slotCount: 3 }` warning event is emitted to the logging system; 2 quests are assigned (not 3); no server error or crash

**AC-27 — Reward grant retry succeeds after transient failure**
- Given: A player completes a quest; the Currency System is unavailable at grant time; `reward_granted = false`
- When: The reconciliation job runs 15 minutes later and the Currency System is now available
- Then: `grantCoins` is called with the original `questId` as idempotency key; the Coin balance is updated once; `reward_granted` is set to `true`; no duplicate grant occurs

---

### 8.7 Milestone Quests

**AC-28 — Next milestone auto-assigned on completion**
- Given: A player completes their first Milestone quest; they had 4 other Milestone quests active (`MILESTONE_ACTIVE_DISPLAY_CAP = 5`)
- When: The completion is recorded
- Then: The next milestone definition in `quest.milestonePool` order is assigned to fill the 5th slot; the player now has 5 active Milestone quests again

**AC-29 — Milestone never re-assigned after completion**
- Given: A player has completed Milestone quest with `questDefId = "milestone_001"`
- When: Any future assignment run or pool shuffle occurs
- Then: `milestone_001` is never assigned again to this player; it is permanently excluded from the player's milestone assignment candidate set

---

*End of Document*
