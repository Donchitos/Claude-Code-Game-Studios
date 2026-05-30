# XP & Progression — Game Design Document

> **System**: XP & Progression
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

The XP & Progression system is the primary skill-expression and engagement loop for BRAWLZONE. It operates on two parallel, independent tracks: **Account Level** (earned globally from all matches, gates game modes, cosmetic slots, and seasonal rewards) and **Character Level** (earned per-character, gates ability unlocks for that specific character). Both tracks award XP from match performance — kills, assists, survival time, win outcome, and game mode — and both apply multipliers for first-win-of-day, quest completion, and tutorial completion bonuses. XP does not affect any gameplay stat; all characters retain identical base stats with balance overlays applied at match start. The system receives match outcome data via the Model B fan-out event `match_result_for_xp` fired by Match Flow at Step 5 of the match-end sequence (after MMR update, in parallel with the Reward System), applies atomic server-side XP grants with deduplication identical to the reward delivery mechanism, and writes the resulting `xp` and `level` fields to the Player Profile. It also formally defines two fields — `xpAtLevelStart` and `xpToNextLevel` — that are required additions to the `match_results_payload` schema.

---

## 2. Player Fantasy

### Feeling Stronger, Playing Better

Progression in BRAWLZONE is not about becoming mechanically stronger — all characters are stat-equal by design. Instead it is about becoming *strategically richer*. Every level crossed opens a new possibility: a new ability to try, a new game mode to explore, a new cosmetic slot to express identity. The player who has been playing for three weeks looks at the ability palette they have unlocked and sees a vocabulary they have built through play. The player who started yesterday sees a horizon worth moving toward.

The XP bar at the end of every match is the heartbeat of that forward motion. Even a loss should feel productive — the bar moved. The first-win bonus should feel like a celebration: you showed up, you won, the game noticed. The character level track adds a second dimension to this feeling: not just "I got better at the game" but "I got better at *Fen*" — a personal mastery narrative layered on top of the global account story.

### Unlocking New Options, Not Power

The distinction between "more options" and "more power" is the most important design principle this system must communicate. At Tier 1 (6 ability unlocks) a player is not more powerful than a Starter player — they have different tools. At Tier 3 (all 18 abilities unlocked) a player is not unbeatable — they are fluent. The progression system must never create the impression that a lower-level player is doomed against a higher-level player. The matchmaking system handles skill parity; the progression system handles variety and expression.

### Visible, Satisfying, Predictable

Every XP grant is shown to the player on the Match Results screen: the base amount, any bonuses applied, and the resulting bar fill. Level-up moments are celebrated with an animated screen and a clear reward summary. The player never wonders why they got the XP they did. The trajectory to the next unlock is always visible — the XP bar shows `xpAtLevelStart`, current XP, and `xpToNextLevel` — so the player knows exactly how many matches stand between them and their next goal.

---

## 3. Detailed Rules

### 3.1 Two-Track Progression Architecture

BRAWLZONE uses two distinct, independently calculated XP tracks. They are not interchangeable: Account XP contributes only to Account Level; Character XP contributes only to that specific character's Character Level. Both are credited in the same post-match processing step from the same `match_result_for_xp` fan-out event, but they are stored and evaluated in separate data structures.

| Property | Account Level | Character Level |
|---|---|---|
| Scope | Global — earned from every match regardless of character | Per-character — earned only when playing that character |
| Storage | `player_profiles.xp` and `player_profiles.level` | `character_progress.{character_id}.charXp` and `character_progress.{character_id}.charLevel` |
| Maximum Level | 50 (see §3.7) | 30 per character (see §3.7) |
| Grants | Coins, skin unlocks, game mode unlocks, seasonal rewards | Ability unlocks (Tier 1, Tier 2, Tier 3) |
| XP Formula | `accountXp` formula (§4.1) | `charXp` formula (§4.2) |

Both tracks use the same deduplication mechanism as the Match Flow Reward System (§3.8).

---

### 3.2 Account Level

Account Level is the player's global progression rank within BRAWLZONE. It ranges from 1 (new player) to 50 (max level). Fractional levels are not possible — the level is the integer floor of the XP-to-level mapping.

#### 3.2.1 Account Level Gates

Certain features become available only after reaching specific Account Level milestones. These gates are enforced server-side at the point of access (not just hidden client-side).

| Account Level | Gate Unlocked | Design Rationale |
|---|---|---|
| 1 (start) | 1v1 Duel mode available; Vex (Brawler) playable | Default starting state; immediate play |
| 1 (start) | Starter tier abilities (6 total) available in loadout | New player has a usable ability set immediately |
| 3 | 3v3 Squad Brawl mode unlocked | Introduces team coordination after solo fundamentals established |
| 5 | Cosmetic slot: Title equipped to profile card | First cosmetic expression beat |
| 8 | 8-player FFA mode unlocked | Largest mode unlocked after player has a match feel baseline |
| 10 | Cosmetic slot: Emote (in-match emote slot) | Personality expression during combat |
| 15 | Seasonal reward eligibility (end-of-season ranking rewards) | Player has demonstrated sustained engagement |
| 20 | Cosmetic slot: Spray (post-kill spray tag) | Mid-game identity expression |
| 25 | Prestige border unlock (profile card border tier 1) | Long-term engagement milestone marker |
| 30 | Cosmetic slot: Victory pose (post-match animation) | Late-game expression unlock |
| 50 | Max level reached; enter Prestige track (optional, see §3.7) | Capstone for dedicated players |

**Mode gates are hard gates.** A level 2 player attempting to join a 3v3 Squad Brawl queue is rejected by the server with error code `ACCOUNT_LEVEL_GATE`. The client should not allow the mode to be selected at all — mode availability is read from the server-authoritative profile at lobby load — but the server enforces the gate independently of client state.

#### 3.2.2 Cosmetic Slot Unlocks

Cosmetic slots are cumulative — unlocking a higher slot does not replace lower slots. A level 20 player has all four cosmetic slots (Title, Emote, Spray, Victory Pose). Slot unlock events emit the `ACCOUNT_LEVEL_UP` analytics event (see §6.2) with the `gateUnlocked` field populated.

---

### 3.3 Character Level

Character Level is the per-character progression rank. It ranges from 1 to 30. Character XP is only credited when the player completes a match using that character.

#### 3.3.1 Ability Unlock Tiers

Each character has 18 active abilities organized into 3 unlock tiers of 6 abilities each (matching the Deck/Loadout System's pool architecture). The player begins with a subset of abilities and unlocks the rest through Character Level milestones.

| Tier | Abilities | Unlock Condition | Description |
|---|---|---|---|
| Tier 1 (Starting) | 6 abilities (Offensive ×2, Defensive ×2, Utility ×2) | Available from Character Level 1 | The starting loadout; includes the character's default loadout abilities plus two additional options. Designed to be immediately usable with no grinding. |
| Tier 2 | 6 abilities | Character Level 5 | Expands to intermediate options; introduces the character's signature synergy combinations. |
| Tier 3 | 6 abilities | Character Level 12 | Full palette; includes the highest-impact and most mechanically complex abilities for that character. |

**Starting Loadout (Tier 1) Rule:** The 6 Tier 1 abilities for every character include the character's two default loadout abilities. This guarantees a new player can always field a valid, author-intended build from their first match.

**Tier 2 and Tier 3 are character-specific unlocks**, not global. Unlocking Tier 2 for Vex does not unlock Tier 2 for Fen. Each character's ability tiers are tracked independently in the `character_progress` table.

**Note on cross-referencing with Deck/Loadout System:** The Deck/Loadout GDD defines a global XP-gated unlock model (Starter/Tier 1/Tier 2 based on Account XP). The Character Level system described here is the canonical gate for the per-character ability palette. In implementation, the XP & Progression system is the authority; the Deck/Loadout system defers to it for the unlock state it reads from Inventory at loadout edit time.

#### 3.3.2 Character Level Gates Summary (All 8 Characters)

The same tier structure applies to all 8 characters. The ability IDs that populate each tier are defined per-character in the Content Catalog. The gates below are universal:

| Character Level | Gate |
|---|---|
| 1 | Tier 1 (6 abilities) available |
| 5 | Tier 2 (6 additional abilities) unlocked |
| 12 | Tier 3 (6 final abilities) unlocked |
| 20 | Character mastery badge (cosmetic; displayed on character card) |
| 30 | Character max level; mastery border (unique cosmetic border on character card) |

---

### 3.4 XP Earned Per Match

XP is credited after each completed match. A match is "completed" when the Match Flow system emits `match_result_for_xp` — abandoned matches do not grant XP (confirmed in Match Flow GDD §3.5: "No rewards, no XP" for abandoned sessions).

XP is computed separately for each player using their individual performance data from the match result payload.

#### 3.4.1 Base XP by Game Mode

| Game Mode | Account Base XP (`baseXp`) | Character Base XP (`baseCharXp`) | Rationale |
|---|---|---|---|
| `duel_1v1` (1v1) | 80 | 60 | Shorter matches, faster loop; lower absolute grant |
| `squad_3v3` (3v3) | 120 | 90 | Team coordination adds depth; moderate grant |
| `ffa_8` (8-player) | 150 | 110 | Largest mode, most players, longest average duration; highest grant |

#### 3.4.2 Performance Bonus

Performance bonus is a multiplier applied to the base XP. It reflects how active and effective the player was in the match.

```
performanceBonus = 1.0
                 + (KILLS_XP_BONUS × kills)
                 + (ASSISTS_XP_BONUS × assists)
                 + (SURVIVAL_XP_BONUS × min(survivalFraction, 1.0))
```

| Variable | Symbol | Default Value | Notes |
|---|---|---|---|
| Kills bonus per kill | `KILLS_XP_BONUS` | 0.05 | +5% per elimination; uncapped at formula level, tuning cap at §7 |
| Assists bonus per assist | `ASSISTS_XP_BONUS` | 0.02 | +2% per assist (3v3 only; 0 in 1v1 and FFA where assists do not exist) |
| Survival fraction bonus | `SURVIVAL_XP_BONUS` | 0.10 | +10% if player survived the full match duration; interpolated by fraction of match survived |
| Survival fraction | `survivalFraction` | `timeAlive / matchDurationSec` | 1.0 if player was alive at match end; lower if eliminated early |

`performanceBonus` is floored at `1.0` — no negative performance.

#### 3.4.3 Win Multiplier

| Outcome | `winMultiplier` |
|---|---|
| `win` | 1.5 |
| `draw` | 1.1 |
| `loss` | 1.0 |

#### 3.4.4 Multiplier Bonuses (Account XP Only)

The following bonuses apply **only to Account XP**, not to Character XP.

| Bonus | Variable | Value | Trigger Condition |
|---|---|---|---|
| First win of day | `firstWinBonus` | +100 flat XP | Reward System's `first_win_claimed_date` equals today's UTC date (see note below) |
| Tutorial completion | `tutorialBonus` | +200 flat XP (one-time) | Tutorial completion flag set in Player Profile; granted exactly once per account |

> **First-win state coordination note:** The XP System does not maintain independent first-win state. It reads the `first_win_claimed_date` record owned by the Reward System. If `first_win_claimed_date` equals today's UTC date, the first-win XP bonus (+100 XP) has already been granted and must not be re-applied.

`tutorialBonus` is awarded in the same XP grant as the first post-tutorial match; it is applied once and the flag is consumed.

> **Quest XP is a separate, independent credit:** Quest completion XP is NOT included in the match XP grant (which is deduplicated by `matchId`). When a quest completes, the Quest system fires `grantXPBonus(questId, amount)` separately, keyed by `questId`. This is an independent credit from a different idempotency domain. Mixing quest XP into the match grant would cause a double-dedup issue because the two sources use different keys (`matchId` vs. `questId`).

---

### 3.5 Level-Up Reward Table

Level-up rewards are granted at the moment of level-up, atomically with the XP/level write. They are delivered to the player via the Inventory and Currency systems as part of the same atomic PostgreSQL transaction as the level update.

#### 3.5.1 Account Level Rewards

| Account Level | Reward | Type |
|---|---|---|
| 2 | 50 Coins | Currency grant |
| 3 | 3v3 Squad Brawl unlocked | Mode gate (no item grant) |
| 4 | 75 Coins | Currency grant |
| 5 | Title slot unlocked + "Rookie" title | Cosmetic + Entitlement |
| 6 | 100 Coins | Currency grant |
| 7 | 100 Coins | Currency grant |
| 8 | FFA mode unlocked | Mode gate (no item grant) |
| 9 | 150 Coins | Currency grant |
| 10 | Emote slot unlocked + "Wave" emote | Cosmetic + Entitlement |
| 11–14 | 100 Coins each level | Currency grant |
| 15 | 200 Coins + Seasonal reward eligibility | Currency grant + Flag |
| 16–19 | 125 Coins each level | Currency grant |
| 20 | Spray slot unlocked + "BRAWL" spray + Earnable character: Fen | Cosmetic + Character entitlement |
| 21–24 | 150 Coins each level | Currency grant |
| 25 | 300 Coins + Prestige border tier 1 | Currency grant + Cosmetic |
| 26–29 | 175 Coins each level | Currency grant |
| 30 | Victory pose slot unlocked + "Champion's Stand" victory pose | Cosmetic + Entitlement |
| 31–39 | 200 Coins each level | Currency grant |
| 40 | 500 Coins + Earnable character: Dash | Currency grant + Character entitlement |
| 41–49 | 200 Coins each level | Currency grant |
| 50 | 1,000 Coins + "BRAWLZONE Veteran" title + Prestige border tier 2 | Currency grant + Cosmetics |

> **Character grants at levels 20 and 40** (Fen and Dash) are awarded only if the player does not already own that character. If already owned, the character grant is replaced with 250 Coins.

#### 3.5.2 Character Level Rewards

| Character Level | Reward |
|---|---|
| 3 | 25 Coins |
| 5 | **Tier 2 ability unlock** (6 new abilities for this character) |
| 8 | 50 Coins |
| 10 | Character-specific spray tag (unique art per character) |
| 12 | **Tier 3 ability unlock** (6 final abilities for this character) |
| 15 | 75 Coins |
| 20 | Character mastery badge (displayed on character card in all lobbies) |
| 25 | 100 Coins |
| 30 | Character mastery border (unique border cosmetic on character card) |

---

### 3.6 XP Multiplier Stack

All active multipliers and bonuses are applied as defined in §4.1 (Account XP) and §4.2 (Character XP). There is no hard cap on `performanceBonus` in the formula itself, but the practical ceiling imposed by the kill cap tuning knob (`KILLS_XP_CAP`) means a single match cannot yield more than `MATCH_XP_SOFT_CAP` Account XP (see §7).

Multipliers are applied in the following order:
1. Compute `performanceBonus` from match stats.
2. Multiply by `winMultiplier`.
3. Multiply by `baseXp` (Account) or `baseCharXp` (Character).
4. Add flat bonuses (`firstWinBonus`, `tutorialBonus` — Account XP only). Note: `questBonus` is NOT added here; quest completion XP is a separate credit fired by the Quest system keyed by `questId` (see §3.4.4).
5. Floor the result to the nearest integer (no fractional XP stored).

---

### 3.7 Max Level and Prestige

**Account Level cap:** 50. Once a player reaches Account Level 50 and their `totalXp` exceeds the `xpRequired(50)` threshold, all subsequent Account XP grants are stored as **prestige XP** tracked in a separate counter (`prestigeXp` on the player profile). Prestige XP does not advance any level — it is cosmetic evidence of continued play past the cap. Prestige XP is shown on the profile as "XP Beyond Max" and contributes to a Prestige Score leaderboard (future feature, not MVP).

**Character Level cap:** 30 per character. Excess Character XP beyond level 30 is discarded (not stored). The player receives a one-time server log event `CHAR_MAX_LEVEL_REACHED` when the cap is first hit per character, and an in-app notification is surfaced.

**No stat benefit from prestige.** Prestige is purely cosmetic and social.

---

### 3.8 Server-Side XP Grant Atomicity and Deduplication

XP grants are written to the database with the same deduplication guarantee as Match Flow reward delivery.

**Deduplication key:** `xp_grant:{matchId}:{playerId}` stored in Redis with TTL = `XP_DEDUP_TTL_S` (default 86400 seconds / 24 hours).

**Processing sequence:**

```
match_result_for_xp event received
  │
  ├─ [Dedup check] Redis GET xp_grant:{matchId}:{playerId}
  │     If key exists → this grant was already processed
  │       Log INFO: XP_GRANT_DUPLICATE_SKIPPED {matchId, playerId}
  │       Return early — do not write to DB
  │
  ├─ [Compute] Calculate accountXp and charXp per §4.1 and §4.2
  │
  ├─ [Dedup lock] Redis SET xp_grant:{matchId}:{playerId} = "processing"
  │               NX (only set if not exists) EX = XP_DEDUP_TTL_S
  │     If SET returns nil (race condition: another worker beat us)
  │       Return early — do not write to DB
  │
  ├─ [Write] Begin PostgreSQL transaction
  │     UPDATE player_profiles
  │       SET xp = xp + accountXp,
  │           level = computed_new_level(xp + accountXp)
  │       WHERE user_id = playerId
  │
  │     UPDATE character_progress
  │       SET charXp = charXp + charXp_delta,
  │           charLevel = computed_new_char_level(charXp + charXp_delta)
  │       WHERE user_id = playerId AND character_id = matchCharacterId
  │
  │     [If level-up detected for account level]
  │       INSERT level-up rewards via Currency and Inventory systems
  │       (within the same transaction for atomicity)
  │
  │     COMMIT
  │
  ├─ [Dedup finalize] Redis SET xp_grant:{matchId}:{playerId} = "done"
  │   (update from "processing" to "done"; TTL remains unchanged)
  │
  ├─ [Cache invalidate] DELETE Redis key: profile:{playerId}
  │   (forces fresh read on next profile load — per Player Profile GDD §3.4)
  │
  ├─ [Emit analytics]
  │   LEVEL_UP_ACCOUNT event if account level changed
  │   LEVEL_UP_CHARACTER event if character level changed
  │   ABILITY_UNLOCKED event for each new ability tier reached
  │
  └─ [Profile refresh push] NOT emitted for XP/level (non-economy field per Player Profile GDD §3.4)
     Client sees updated values on next profile poll or read.
```

**Level computation is derived in-transaction**, not pre-computed on the application layer, to prevent races between concurrent grants for the same player.

---

### 3.9 match_results_payload — Required New Fields

The Match Flow GDD's `match_results_payload` (§4.1 of match-flow.md) currently lacks two fields required for the XP & Progression system to render the XP bar correctly on the Match Results Screen.

**These two fields MUST be added to `match_results_payload` as required fields:**

```typescript
interface MatchResultsPayload {
  // ... existing fields ...

  playerResults: Array<{
    // ... existing per-player fields ...

    // XP fields — required from Alpha onwards (NOT nullable stubs like diamondsEarned)
    xpEarned: number;              // Total Account XP credited this match (post-multipliers, post-bonuses)
    xpAtLevelStart: number;        // Total accumulated Account XP at the moment this level began
                                   // i.e., xpRequired(playerLevel) at time of grant
    xpToNextLevel: number;         // Total Account XP required to complete the current level
                                   // i.e., xpRequired(playerLevel + 1) - xpRequired(playerLevel)
  }>;
}
```

**Field definitions:**

| Field | Type | Source | Usage |
|---|---|---|---|
| `xpEarned` | `number` | Computed by XP & Progression system from match result | Displayed as "+N XP" on the results screen; drives bar animation |
| `xpAtLevelStart` | `number` | Read from Player Profile at time of XP grant: `xpRequired(currentLevel)` | Defines the left edge (0%) of the XP bar |
| `xpToNextLevel` | `number` | Computed: `xpRequired(currentLevel + 1) − xpRequired(currentLevel)` | Defines the total span (100%) of the XP bar segment |

**Why these fields are required (not optional stubs):** The Match Results Screen cannot render the XP bar fill animation without knowing where the current level started and how wide the level band is. Without `xpAtLevelStart` and `xpToNextLevel`, the client either cannot show the bar or must make a separate profile read — adding latency and complexity. These fields are always computable at grant time and must be included.

**If the XP grant arrives before the payload is sent:** The XP & Progression system writes its result back to Match Flow as part of the fan-out response, matching the pattern of the Reward System. Match Flow includes the XP fields in `match_results_payload` the same way it includes `diamondsEarned`.

**In the Match Flow fan-out event `match_result_for_xp`, the following fields must also be present:**

```typescript
interface MatchResultForXP {
  matchId: string;
  gameMode: GameMode;
  matchDurationSec: number;
  playerResults: Array<{
    playerId: string;
    characterId: string;          // Required — identifies which Character Level track to credit
    outcome: "win" | "loss" | "draw";
    placement: number;
    eliminations: number;
    assists: number;
    timeAliveSec: number;         // Required — used to compute survivalFraction
    // questsCompletedThisMatch is NOT used for XP grant here. Quest completion XP is
    // credited separately by the Quest system via grantXPBonus(questId, amount), keyed
    // by questId — a different idempotency domain from this matchId-keyed grant.
    isTutorialComplete: boolean;  // Whether tutorialBonus should be applied (one-time flag)
    // NOTE: isFirstWinOfDay is intentionally absent. The XP System does not maintain
    // independent first-win state. On XP grant, the XP System reads the Reward System's
    // first_win_claimed_date record directly. If first_win_claimed_date equals today's
    // UTC date, the +100 XP first-win bonus is applied. The Reward System is the single
    // source of truth for whether today's first win has been claimed.
  }>;
}
```

> **Cross-system gap formally closed:** The `xpAtLevelStart` and `xpToNextLevel` fields are hereby defined as required fields in the `match_results_payload`. The Match Flow GDD must be updated to reflect these additions in its §4.1 payload schema. This document is the authoritative source for both field definitions and their computation.

---

## 4. Formulas

### 4.1 Account XP Formula

```
accountXp = floor(
  baseXp(mode) × winMultiplier × performanceBonus
) + tutorialBonus + firstWinBonus
```

> **Quest XP separation:** `questBonus` is intentionally absent from this formula. Quest completion XP is granted separately by the Quest system via `grantXPBonus(questId, amount)`, keyed by `questId`. Including it here (keyed by `matchId`) would create a double-dedup issue because the two idempotency domains are independent.

**Variable definitions:**

| Variable | Symbol | Type | Source | Notes |
|---|---|---|---|---|
| Base XP by mode | `baseXp(mode)` | integer | §3.4.1 table | duel_1v1=80, squad_3v3=120, ffa_8=150 |
| Win multiplier | `winMultiplier` | float | §3.4.3 table | win=1.5, draw=1.1, loss=1.0 |
| Performance bonus | `performanceBonus` | float ≥ 1.0 | §4.1.1 formula | Computed from kills, assists, survival |
| Tutorial bonus | `tutorialBonus` | integer | Player Profile flag | 200 if `isTutorialComplete` and bonus not yet granted; 0 otherwise |
| First win bonus | `firstWinBonus` | integer | Reward System's `first_win_claimed_date` | 100 if `first_win_claimed_date` equals today's UTC date and `outcome == "win"`; 0 otherwise. The XP System does not maintain independent first-win state — it reads from the Reward System (see §3.4.4). |

#### 4.1.1 Performance Bonus Sub-Formula

```
performanceBonus = 1.0
                 + (KILLS_XP_BONUS × min(kills, KILLS_XP_CAP))
                 + (ASSISTS_XP_BONUS × assists)
                 + (SURVIVAL_XP_BONUS × min(timeAliveSec / matchDurationSec, 1.0))
```

| Variable | Default Value | Safe Range | Notes |
|---|---|---|---|
| `KILLS_XP_BONUS` | 0.05 | 0.02–0.15 | Per-kill percentage bonus |
| `KILLS_XP_CAP` | 10 | 5–20 | Max kills counted for bonus; prevents farming |
| `ASSISTS_XP_BONUS` | 0.02 | 0.01–0.05 | Per-assist bonus; only applicable in 3v3 |
| `SURVIVAL_XP_BONUS` | 0.10 | 0.05–0.20 | Bonus for surviving the full match |

#### 4.1.2 Example Calculation — 1v1 Duel Win, 2 Kills

```
Given:
  mode       = "duel_1v1"
  outcome    = "win"
  kills      = 2
  assists    = 0  (N/A in 1v1)
  timeAlive  = 95s
  matchDurationSec = 100s
  isTutorialComplete + bonus not yet granted = false
  Reward System first_win_claimed_date = today's UTC date  (first win has been claimed)
  (quest XP, if any, is credited separately by the Quest system — not part of this grant)

Step 1 — performanceBonus:
  = 1.0
  + (0.05 × min(2, 10))           → +0.10 for 2 kills
  + (0.02 × 0)                    → +0.00 for assists
  + (0.10 × min(95/100, 1.0))     → +0.095 for 95% survival
  = 1.0 + 0.10 + 0.00 + 0.095
  = 1.195

Step 2 — core multiplication:
  baseXp(duel) = 80
  winMultiplier = 1.5
  floor(80 × 1.5 × 1.195) = floor(143.4) = 143

Step 3 — flat bonuses (match XP grant only; quest XP is a separate credit keyed by questId):
  tutorialBonus = 0
  firstWinBonus = 100   (Reward System's first_win_claimed_date == today's UTC date)

Step 4 — total accountXp (match grant, keyed by matchId):
  accountXp = 143 + 0 + 100 = 243 Account XP
  (Any quest completion XP would be credited separately by the Quest system, keyed by questId)
```

---

### 4.2 Character XP Formula

```
charXp = floor(
  baseCharXp(mode) × performanceBonus
)
```

Character XP uses the same `performanceBonus` as Account XP but does not apply `winMultiplier` or any flat bonuses. Rationale: character mastery is about engagement with the character's mechanics (survival, kills, assists), not about winning. Removing the win multiplier makes Character Level gains feel fair even in losing matches.

| Variable | Symbol | Type | Source |
|---|---|---|---|
| Base char XP by mode | `baseCharXp(mode)` | integer | §3.4.1 table | duel_1v1=60, squad_3v3=90, ffa_8=110 |
| Performance bonus | `performanceBonus` | float ≥ 1.0 | Same formula as §4.1.1 | Identical computation |

#### 4.2.1 Example — Same Match (1v1 Duel Win, 2 Kills)

```
Given:
  (same match as §4.1.2)
  performanceBonus = 1.195   (carried from Account XP calculation)

charXp = floor(baseCharXp("duel_1v1") × performanceBonus)
       = floor(60 × 1.195)
       = floor(71.7)
       = 71 Character XP
```

---

### 4.3 XP Required Per Account Level

Account Level uses an **exponential curve** to ensure early levels feel fast and later levels feel like a deeper commitment.

```
xpRequired(L) = LEVEL_XP_BASE × floor(LEVEL_XP_SCALE ^ (L - 1))
```

| Variable | Symbol | Default | Notes |
|---|---|---|---|
| Base XP for level 1→2 | `LEVEL_XP_BASE` | 300 | XP required to advance from level 1 to level 2 |
| Scale exponent | `LEVEL_XP_SCALE` | 1.18 | Compound growth rate per level |
| Level | `L` | integer [1, 50] | Input level (the level being completed) |

**Computed table (selected levels):**

| Level | `xpRequired(L)` | Cumulative XP to reach L+1 |
|---|---|---|
| 1 | 300 | 300 |
| 2 | 354 | 654 |
| 3 | 418 | 1,072 |
| 5 | 582 | 2,170 |
| 10 | 1,326 | 7,046 |
| 15 | 3,020 | 19,854 |
| 20 | 6,878 | 50,984 |
| 25 | 15,665 | 119,580 |
| 30 | 35,676 | 273,186 |
| 40 | 184,974 | ~1.52M cumulative |
| 50 | ~959,000 | — (max level) |

> **Design tuning note:** At default XP rates and typical play patterns (~3 matches/day, mixed outcomes), a new player should reach Account Level 10 within approximately 2 weeks. The scale factor of 1.18 ensures the mid-game (levels 15–30) provides several weeks of content, while the endgame (levels 40–50) is a multi-month commitment. `LEVEL_XP_SCALE` is a Remote Config cold key (§7) — adjust only with data from analytics on progression velocity.

#### 4.3.1 Total Accumulated XP for Level Computation

```
totalXpForLevel(L) = sum of xpRequired(k) for k = 1 to L-1
                   = sum_{k=1}^{L-1} LEVEL_XP_BASE × floor(LEVEL_XP_SCALE ^ (k - 1))
```

Given a player's `totalXp`, their current Account Level is:

```
currentLevel = max { L : totalXpForLevel(L) ≤ totalXp }
```

This is computed at write time in the transaction (§3.8) and stored in `player_profiles.level`.

#### 4.3.2 xpAtLevelStart and xpToNextLevel Computation

```
xpAtLevelStart(L)  = totalXpForLevel(L)
xpToNextLevel(L)   = xpRequired(L)
```

For the results screen XP bar:
- XP fill fraction = `(totalXp − xpAtLevelStart) / xpToNextLevel`
- This fraction is always in [0.0, 1.0] by construction.

---

### 4.4 XP Required Per Character Level

Character Level uses a **linear curve** — simpler because character mastery is about focused play with one character, and the reward beats (Tier 2 at level 5, Tier 3 at level 12) are at fixed, predictable milestones.

```
charXpRequired(CL) = CHAR_LEVEL_XP_BASE + (CHAR_LEVEL_XP_LINEAR × (CL - 1))
```

| Variable | Symbol | Default | Notes |
|---|---|---|---|
| Base Character XP | `CHAR_LEVEL_XP_BASE` | 150 | XP required to advance from character level 1 to 2 |
| Linear increment | `CHAR_LEVEL_XP_LINEAR` | 50 | Additional XP required per subsequent level |

**Selected character level requirements:**

| Character Level | `charXpRequired(CL)` | Cumulative charXP to reach CL+1 |
|---|---|---|
| 1 | 150 | 150 |
| 2 | 200 | 350 |
| 5 | 350 (Tier 2 unlocks) | 1,250 |
| 10 | 600 | 3,750 |
| 12 | 700 (Tier 3 unlocks) | 5,350 |
| 20 | 1,100 (mastery badge) | 13,750 |
| 30 | 1,600 (max) | 26,250 |

> **Design note:** A player focusing primarily on one character (~2–3 matches/day with that character) should reach Character Level 5 (Tier 2 unlock) in approximately one week and Character Level 12 (Tier 3 unlock) in three to four weeks. The linear curve means later levels take predictably longer, not dramatically longer — reinforcing the "grinding is rewarded proportionally" feeling.

#### 4.4.1 Example — Progression to Tier 2 Unlock

```
Player plays Fen in 5 squad_3v3 matches, all losses, 1 assist per match, 80% survival.

Per-match charXp:
  performanceBonus = 1.0 + (0.05 × 0) + (0.02 × 1) + (0.10 × 0.80)
                   = 1.0 + 0 + 0.02 + 0.08 = 1.10
  charXp = floor(baseCharXp("squad_3v3") × 1.10)
         = floor(90 × 1.10)
         = floor(99) = 99

After 5 matches:
  Total charXp = 5 × 99 = 495

Character Level progression:
  charXpRequired(1) = 150  → level 1 complete at 150 charXp
  charXpRequired(2) = 200  → level 2 complete at 350 charXp
  charXpRequired(3) = 250  → level 3 complete at 600 charXp (not yet reached)

Player is Character Level 2 with 495 − 350 = 145 charXp toward the 250 needed for level 3.
Tier 2 requires Character Level 5. Remaining charXp needed:
  To complete CL3: 250 − 145 = 105 charXp remaining
  CL4 requires 300 charXp
  CL5 requires 350 charXp
  Total remaining: 105 + 300 + 350 = 755 charXp → approximately 8 more matches
```

---

## 5. Edge Cases

### 5.1 XP Grant Fires Twice (Deduplication)

**Scenario:** The `match_result_for_xp` event is delivered to the XP service twice for the same `matchId` and `playerId`. This can occur if the event bus delivers the message more than once (at-least-once delivery guarantee) or if a processing worker crashes mid-write after the DB commit but before setting the dedup key to "done".

**Resolution:**

1. Before any computation, the XP service checks Redis for key `xp_grant:{matchId}:{playerId}`.
2. If the key exists with value `"done"`: skip entirely. Log `XP_GRANT_DUPLICATE_SKIPPED`. No DB write occurs.
3. If the key exists with value `"processing"` (crash-recovery scenario): the previous worker crashed after acquiring the lock but before completing. The current worker **waits** `XP_PROCESSING_STALE_TTL_S` (default 10 seconds) and re-checks. If still `"processing"` after the wait, the current worker treats the grant as unprocessed (the previous transaction was likely rolled back), acquires the lock under a new Redis SET NX, and proceeds.
4. If the key does not exist: normal processing path (§3.8).

**Guarantee:** A given `{matchId, playerId}` pair is processed at most once. The dedup key TTL (`XP_DEDUP_TTL_S` = 86400s) provides a 24-hour window, well beyond any realistic retry window.

---

### 5.2 Player Levels Up Mid-Grant (Multiple Level-Up in One Batch)

**Scenario:** A player at Account Level 4 with 270/300 XP (30 XP from level-up) earns 450 Account XP from a single match. This triggers two level-ups in one grant (level 4 → 5 and level 5 → 6).

**Resolution:**

1. The grant computation runs in the PostgreSQL transaction (§3.8).
2. The `computed_new_level` function iterates through levels until the accumulated XP is exhausted, rather than checking only one level boundary.

```typescript
function computedNewLevel(currentXp: number, xpGrant: number): {
  newLevel: number;
  newTotalXp: number;
} {
  let totalXp = currentXp + xpGrant;
  let level = currentLevelFromXp(totalXp);  // find max L s.t. totalXpForLevel(L) <= totalXp
  return { newLevel: level, newTotalXp: totalXp };
}
```

3. All level-up rewards for intermediate levels are granted within the same transaction. If the player crosses level 4 → 5 → 6, rewards for both levels 5 and 6 are included in the atomic write.
4. The `LEVEL_UP_ACCOUNT` analytics event fires once per level crossed. Two level-up analytics events are emitted for the double level-up scenario.
5. The Match Results Screen receives `xpEarned`, `xpAtLevelStart` (based on the level *before* the grant), and `xpToNextLevel` (based on the level *before* the grant). The client-side XP bar animation handles multi-level transitions by filling the bar, resetting, and filling again — this is a client rendering concern, not a server data concern.
6. **No XP is lost** — the total XP applied equals `xpGrant` exactly, distributed across however many levels are crossed.

---

### 5.3 Character Switched Mid-XP Credit Window

**Scenario:** A player selects Fen for character select but somehow (due to a bug or edge case in the character select flow) a different character ID is associated with their session result. Or: a player wonders "what character do I get XP for if I switched loadouts?"

**Resolution:**

The `characterId` in the `match_result_for_xp` event is set to the character the player **confirmed in the character select screen** at match start. This is the character ID recorded in the session object by Session Manager when the player submitted their `confirm_selection` event. It does not change during the match, regardless of any mid-match state.

- Character switched between matches (new character select): XP goes to the new match's confirmed character. Previous match is already finalized.
- The concept of "switching characters mid-match" does not exist in BRAWLZONE — a character is locked for the duration of a match.
- If the `characterId` in the event is null or invalid (defensive case): the XP system skips Character XP credit for that player, credits Account XP normally, and emits a `XP_CHAR_CREDIT_SKIPPED` warning with the `matchId` and `playerId` for ops investigation.

**Rule:** Character XP is always attributed to the `characterId` reported in `match_result_for_xp.playerResults[i].characterId`. The XP service never infers or overrides this value.

---

### 5.4 XP Grant Arrives While Player Is Offline or During Reconnect

**Scenario:** A player completes a match and closes the app (or loses connectivity) before the XP grant is delivered to the client. The Match Flow fan-out fires `match_result_for_xp` server-side regardless of client connection state. The XP service writes the grant to PostgreSQL and invalidates the Redis cache. When the player reconnects, they need to see updated XP and level.

**Resolution:**

1. XP grant processing is entirely server-side (§3.8). No client acknowledgment is required.
2. The XP write completes normally to PostgreSQL while the player is offline.
3. When the player reconnects and the client loads the Player Profile:
   - The Redis cache was invalidated at grant time (§3.8). The next profile read triggers a cache miss and a fresh PostgreSQL read.
   - The profile returned to the client contains the updated `xp` and `level` values.
4. The client does not replay the XP bar fill animation for grants that arrived while offline — it simply shows the current state. Only the Match Results Screen (which is shown in the same session as the match) has the animation context.
5. If the player reconnects while still on the Match Results Screen (reconnect-resume scenario per Reconnect/Resume GDD): the client re-fetches the match result, and `xpEarned`, `xpAtLevelStart`, and `xpToNextLevel` are re-delivered in the reconnect payload, allowing the animation to play.

---

### 5.5 Max Level Reached — Excess XP Handling

**Scenario A — Account Level 50 with excess XP:**
A player at Account Level 49 earns enough XP to advance past level 50 (the cap).

**Resolution:**
1. The `computed_new_level` function caps at level 50. `player_profiles.level` is set to 50 and not incremented further.
2. The excess XP above `totalXpForLevel(50)` is stored in `player_profiles.prestigeXp` (additive integer field, default 0).
3. The level 50 reward (§3.5.1) is granted once, at the moment level 50 is first reached.
4. Subsequent grants: `accountXp` is computed normally and routed entirely to `prestigeXp`. No level-up events fire post-cap.
5. On the Match Results Screen: `xpAtLevelStart` is set to `totalXpForLevel(50)`, `xpToNextLevel` is set to `PRESTIGE_XP_DISPLAY_BAND` (a tuning constant, default 5000), and `xpEarned` fills the prestige bar. This creates a visible "XP beyond max" bar for the player.

**Scenario B — Character Level 30 with excess Character XP:**
1. `charLevel` is capped at 30. `charXp` is not incremented beyond the cap.
2. Excess Character XP is discarded (not stored). The character max level grant (§3.5.2) fires once.
3. A `CHAR_MAX_LEVEL_REACHED` analytics event is emitted the first time the cap is hit per character.
4. On the Match Results Screen: the character XP bar shows a full bar at level 30 with "MAX" displayed in place of the XP fraction.

---

## 6. Dependencies

### 6.1 Upstream — XP & Progression Consumes

| System | What XP & Progression Needs | Interface | Notes |
|---|---|---|---|
| **Match Flow** | `match_result_for_xp` fan-out event at Step 5 of match-end sequence | Async event (internal message queue); fire-and-forget from Match Flow | Carries per-player: `playerId`, `characterId`, `outcome`, `eliminations`, `assists`, `timeAliveSec`, `matchDurationSec`, `gameMode`, `isTutorialComplete`. Does NOT carry `isFirstWinOfDay` (see Reward System row) or quest XP (see Quest system row). |
| **Player Profile** | Current `xp`, `level`, `totalXp` at time of write; `isTutorialComplete` flag | PostgreSQL read within the grant transaction; Redis cache checked first | `player_profiles.xp` and `player_profiles.level` are owned by this system (Player Profile GDD §3.5) |
| **Reward System** | `first_win_claimed_date` record per player | PostgreSQL read within the grant transaction | The XP System does not maintain independent first-win state. It reads `first_win_claimed_date` from the Reward System. If this value equals today's UTC date, the +100 XP first-win bonus is applied. The Reward System is the single source of truth for first-win claim state. |
| **Quest / Mission System** | Quest completion XP is NOT part of the match XP grant | Quest system calls `grantXPBonus(questId, amount)` independently when a quest completes | Quest XP is keyed by `questId` (separate idempotency domain from this `matchId`-keyed grant). The XP service does not include quest XP in the match grant to prevent the double-dedup issue that would arise from mixing the two deduplication domains. |
| **Remote Config** | Live tuning constants: `LEVEL_XP_SCALE`, `LEVEL_XP_BASE`, `CHAR_LEVEL_XP_BASE`, `CHAR_LEVEL_XP_LINEAR`, all bonus constants | Remote Config key read at service startup; hot-reloaded for cold keys (see §7) | Cold keys require a service restart to take effect; warm keys apply immediately |

### 6.2 Downstream — XP & Progression Produces

| System | What XP & Progression Provides | Interface | Notes |
|---|---|---|---|
| **Player Profile** | `xp`, `level` writes; `prestigeXp` writes | PostgreSQL `UPDATE` within atomic transaction | `level` and `xp` must update in same transaction (Player Profile GDD §3.4 atomicity requirement) |
| **Character Progress Store** | `charXp`, `charLevel` writes per character | PostgreSQL `UPDATE` on `character_progress` table | Separate table from `player_profiles`; scoped by `user_id × character_id` |
| **Inventory / Entitlements** | Ability tier unlock grants (Tier 2 at charLevel 5, Tier 3 at charLevel 12) | Inventory system write within the same transaction as `charLevel` update | Required fields: `match_results_payload.xpAtLevelStart`, `match_results_payload.xpToNextLevel` (formally defined in §3.9) |
| **Currency System** | Coin grants at account level milestones and character level milestones (§3.5) | Currency system write within the same transaction as `level` update | The Currency system writes `diamond_balance`; XP & Progression calls it within the level-up transaction |
| **Match Flow / Match Results Screen** | `xpEarned`, `xpAtLevelStart`, `xpToNextLevel` per player for `match_results_payload` | Returned as part of XP grant confirmation response to Match Flow; Match Flow includes in `match_results_payload` | **These three fields are required additions to `match_results_payload` (see §3.9). The match_results_payload schema in match-flow.md must be updated to include them.** |
| **Analytics / Telemetry** | `LEVEL_UP_ACCOUNT`, `LEVEL_UP_CHARACTER`, `ABILITY_UNLOCKED` events | Async event emit after DB commit | Per Analytics GDD; PII policy: no display names in event payloads; use `playerId` only |
| **Logging / Monitoring** | `XP_GRANT_DUPLICATE_SKIPPED`, `XP_PROCESSING_STALE_TTL_EXPIRED`, `XP_CHAR_CREDIT_SKIPPED`, `CHAR_MAX_LEVEL_REACHED` log events | ILogger interface (per Logging/Monitoring GDD) | `playerId` is PII — follow PII policy for log levels |

### 6.3 Formal Payload Gap: `match_results_payload` Cross-Reference

The `match_results_payload` defined in match-flow.md §4.1 currently includes `xpEarned: number | null` as a stub. This document upgrades that field and adds two new required fields:

| Field | Previous State | Required State (from Alpha) |
|---|---|---|
| `xpEarned` | `number \| null` (stub) | `number` (required, never null) |
| `xpAtLevelStart` | **Missing from schema** | `number` (required) |
| `xpToNextLevel` | **Missing from schema** | `number` (required) |

**Action required:** Update match-flow.md §4.1 `MatchResultsPayload` interface to reflect these three required fields.

---

## 7. Tuning Knobs

All constants are stored in server configuration and overridable without a client update. Column "RC Key Type" denotes whether the key is a Remote Config **warm key** (takes effect on next Remote Config fetch, no restart required) or **cold key** (requires a service restart to take effect — treat changes like a deployment, not like a live parameter adjustment).

| Knob | Env Var / RC Key | Default | Safe Range | RC Key Type | Notes |
|---|---|---|---|---|---|
| Account Level XP base | `LEVEL_XP_BASE` | 300 | 150–600 | Cold | XP needed for level 1→2. Changing this reshapes the entire curve. Requires regression on the full level table. Coordinate with analytics for cohort velocity data before changing. |
| Account Level XP scale | `LEVEL_XP_SCALE` | 1.18 | 1.10–1.30 | Cold | Exponential multiplier per level. Lower = faster endgame (1.10 ≈ near-linear); higher = extreme endgame wall (1.30 makes level 50 orders of magnitude harder). Changes above 1.25 require full playtesting. |
| Character Level XP base | `CHAR_LEVEL_XP_BASE` | 150 | 75–300 | Cold | XP needed for character level 1→2. Decrease to make early character mastery faster; coordinate with Tier 2 unlock target timeline. |
| Character Level XP linear increment | `CHAR_LEVEL_XP_LINEAR` | 50 | 25–100 | Cold | Additive per-level increment. Increase to steepen the character mastery curve in later levels. |
| Duel base Account XP | `BASE_XP_DUEL` | 80 | 40–150 | Warm | Decrease if 1v1 is being used to farm Account XP at the expense of other modes. |
| Squad Brawl base Account XP | `BASE_XP_SQUAD_BRAWL` | 120 | 60–200 | Warm | |
| FFA base Account XP | `BASE_XP_FFA` | 150 | 80–250 | Warm | |
| Duel base Character XP | `BASE_CHAR_XP_DUEL` | 60 | 30–120 | Warm | |
| Squad Brawl base Character XP | `BASE_CHAR_XP_SQUAD_BRAWL` | 90 | 45–150 | Warm | |
| FFA base Character XP | `BASE_CHAR_XP_FFA` | 110 | 60–180 | Warm | |
| Win multiplier | `WIN_XP_MULTIPLIER` | 1.5 | 1.2–2.0 | Warm | Below 1.2: wins barely feel more rewarding than losses. Above 2.0: heavily punishes new players in early losses. |
| Draw multiplier | `DRAW_XP_MULTIPLIER` | 1.1 | 1.0–1.3 | Warm | |
| Kills XP bonus (per kill) | `KILLS_XP_BONUS` | 0.05 | 0.02–0.15 | Warm | Coordinate with kill cap to bound total bonus. |
| Kills XP cap | `KILLS_XP_CAP` | 10 | 5–20 | Warm | Prevents kill-farming XP loops in FFA. Maximum per-match kills bonus = `KILLS_XP_BONUS × KILLS_XP_CAP` = 50% at defaults. |
| Assists XP bonus (per assist) | `ASSISTS_XP_BONUS` | 0.02 | 0.01–0.05 | Warm | 3v3 only in practice; zero effect in 1v1/FFA where assists don't exist. |
| Survival XP bonus | `SURVIVAL_XP_BONUS` | 0.10 | 0.05–0.20 | Warm | Rewards staying alive. Values above 0.20 may incentivize passive play. |
| First win of day bonus | `FIRST_WIN_XP_BONUS` | 100 | 50–300 | Warm | Key daily engagement lever. Increase to drive daily active user return; decrease if session length analytics show players logging in solely for the bonus. |
| Quest XP bonus (per quest) | `QUEST_XP_BONUS` | 50 | 25–150 | Warm | Amount passed to `grantXPBonus(questId, amount)` by the Quest system when a quest completes. This is a separate credit from the match XP grant — it is keyed by `questId`, not `matchId`. |
| Tutorial completion bonus | `TUTORIAL_XP_BONUS` | 200 | 100–500 | Cold | One-time; only meaningful for new player funnel. Requires coordinated change with Tutorial/Onboarding GDD. |
| XP dedup TTL | `XP_DEDUP_TTL_S` | 86400 | 3600–604800 | Cold | 24-hour default. Increase if event redelivery windows can exceed 24 hours. Decrease only if Redis memory is constrained and staleness is monitored. |
| XP processing stale TTL | `XP_PROCESSING_STALE_TTL_S` | 10 | 5–30 | Cold | How long to wait before treating a "processing" dedup key as abandoned (crash recovery). |
| Match XP soft cap | `MATCH_XP_SOFT_CAP` | 600 | 300–1500 | Warm | Advisory cap — emits `XP_GRANT_NEAR_CAP` analytics warning if a single grant exceeds this value. Does NOT block the grant. Used for anomaly detection only. |
| Prestige XP display band | `PRESTIGE_XP_DISPLAY_BAND` | 5000 | 1000–20000 | Warm | Width of the prestige bar band shown on results screen after hitting Account Level 50. |
| Character Tier 2 unlock level | `CHAR_TIER2_UNLOCK_LEVEL` | 5 | 3–10 | Cold | Character Level at which Tier 2 abilities unlock. Changing this retroactively affects players who are already above the new threshold — the system must re-evaluate all existing `charLevel` values if decreased. |
| Character Tier 3 unlock level | `CHAR_TIER3_UNLOCK_LEVEL` | 12 | 8–20 | Cold | Same retroactive concern as Tier 2. |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and are independently verifiable by automated test or documented manual QA.

### 8.1 Account XP Grant Correctness

**AC-XP-01 — Account XP Formula: 1v1 Duel Win with 2 Kills, First Win of Day**
- Given: A player wins a 1v1 Duel with 2 kills, 95/100 seconds alive, no quests completed, tutorial already done (bonus consumed), and this is their first win of the calendar day
- When: The XP grant is processed
- Then: `accountXp = 243` (matching §4.1.2 worked example); `firstWinBonus` of 100 is applied; total = 243

**AC-XP-02 — Account XP Formula: Squad Brawl Loss**
- Given: A player loses a 3v3 Squad Brawl with 1 kill, 2 assists, 120/200 seconds alive, no bonuses active
- When: The XP grant is processed
- Then:
  - `performanceBonus = 1.0 + (0.05 × 1) + (0.02 × 2) + (0.10 × 0.60) = 1.0 + 0.05 + 0.04 + 0.06 = 1.15`
  - `accountXp = floor(120 × 1.0 × 1.15) + 0 = floor(138) = 138`

**AC-XP-03 — Win Multiplier Applied**
- Given: Two players with identical match stats; Player A wins, Player B loses; same mode (FFA), same kills/assists/survival
- When: Both grants are processed
- Then: Player A's `accountXp` is 1.5× the value of Player B's `accountXp` (before flat bonuses), rounded to nearest integer

**AC-XP-04 — Tutorial Bonus Applied Exactly Once**
- Given: A player's first post-tutorial match (tutorial flag set, bonus not yet granted)
- When: XP is granted
- Then: `tutorialBonus = 200` is added; the tutorial bonus flag is consumed; on the player's second match, `tutorialBonus = 0`

---

### 8.2 Character XP Grant Correctness

**AC-XP-05 — Character XP Attributed to Confirmed Character**
- Given: A player confirms Fen in character select and plays a 3v3 Squad Brawl match
- When: The `match_result_for_xp` event is processed
- Then: Character XP is credited to `character_progress` row where `character_id = "character:fen"`; no other character's row is modified

**AC-XP-06 — Character XP Does Not Apply Win Multiplier**
- Given: Same match stats as AC-XP-02 (Squad Brawl loss with 1 kill, 2 assists)
- When: Character XP is computed
- Then: `charXp = floor(90 × 1.15) = floor(103.5) = 103`; the win multiplier of 1.0 (loss) does not reduce this because `winMultiplier` is not applied to `charXp`

---

### 8.3 Level-Up Mechanics

**AC-XP-07 — Account Level-Up Triggers Correct Reward**
- Given: A player advances from Account Level 9 to Account Level 10
- When: The level-up transaction commits
- Then: The player receives 150 Coins (level 9 → 10 reward from §3.5.1) AND the Emote slot is unlocked AND the "Wave" emote entitlement is granted; all three are written in the same PostgreSQL transaction

**AC-XP-08 — Double Level-Up in One Grant**
- Given: A player at Account Level 4 with 270/300 Account XP earns 450 Account XP in one match
- When: The grant is processed
- Then:
  - Player advances from Level 4 → Level 5 → Level 6
  - Rewards for Level 5 (Title slot + "Rookie" title) AND Level 6 (100 Coins) are both granted in the same transaction
  - Two `LEVEL_UP_ACCOUNT` analytics events are emitted (one per level crossed)
  - `player_profiles.level = 6` after the transaction

**AC-XP-09 — Character Tier 2 Unlock at Character Level 5**
- Given: A player's Character Level for Vex advances to exactly 5
- When: The character level-up transaction commits
- Then: The 6 Tier 2 abilities for Vex are written to the player's Inventory/Entitlements record; an `ABILITY_UNLOCKED` analytics event is emitted for each of the 6 abilities; the Tier 2 abilities are visible in the Vex loadout editor on the next match

---

### 8.4 Match Results Payload Fields

**AC-XP-10 — xpAtLevelStart and xpToNextLevel Populated Correctly**
- Given: A player at Account Level 7 with `totalXp = 3,200` completes a match and earns 243 Account XP
- When: The `match_results_payload` is assembled
- Then:
  - `xpEarned = 243`
  - `xpAtLevelStart = totalXpForLevel(7)` (the cumulative XP threshold for level 7)
  - `xpToNextLevel = xpRequired(7)` (the width of the level 7 band)
  - `(totalXp + xpEarned - xpAtLevelStart) / xpToNextLevel` is in [0.0, 1.0]

**AC-XP-11 — xpAtLevelStart and xpToNextLevel Present After Level-Up**
- Given: A match grant causes the player to level up (e.g., Level 4 → Level 5)
- When: `match_results_payload` is assembled
- Then:
  - `xpAtLevelStart` reflects the XP at the START of the level before the grant (Level 4's threshold)
  - `xpToNextLevel` reflects the width of the level 4 band
  - The XP bar animation shows overflow into the new level (client rendering concern; the raw values are the source)
  - `player_profiles.level` in the DB is 5 at this point

---

### 8.5 Deduplication and Atomicity

**AC-XP-12 — Duplicate XP Grant Is Rejected**
- Given: The XP service receives `match_result_for_xp` for the same `{matchId, playerId}` twice
- When: Both events are processed (second arrives after dedup key is set to "done")
- Then: The player's `xp` and `charXp` are incremented exactly once; the second event logs `XP_GRANT_DUPLICATE_SKIPPED`; no error is returned to the caller

**AC-XP-13 — XP and Level Update in Same Transaction**
- Given: A match grant causes a level-up
- When: The PostgreSQL transaction commits
- Then: Either both `xp` and `level` are updated (reflecting the new level) or neither is (rollback). There is no state where `xp` reflects the new value but `level` still reflects the old value (or vice versa). Verifiable by simulating a mid-transaction failure.

**AC-XP-14 — Level-Up Reward in Same Transaction as XP Write**
- Given: A level-up occurs that grants Coins (e.g., Level 6 = 100 Coins)
- When: The transaction commits
- Then: `player_profiles.level`, `player_profiles.xp`, and `player_profiles.diamond_balance` are all updated atomically. A failed Currency write rolls back the entire transaction including the XP/level update.

---

### 8.6 Edge Case Verification

**AC-XP-15 — Max Account Level: Prestige XP Routing**
- Given: A player at Account Level 50 (max) earns 300 Account XP from a match
- When: The grant is processed
- Then: `player_profiles.level` remains 50; `player_profiles.prestigeXp` is incremented by 300; no level-up event is emitted; the Match Results Screen shows the prestige bar with `xpToNextLevel = PRESTIGE_XP_DISPLAY_BAND`

**AC-XP-16 — Max Character Level: Excess XP Discarded**
- Given: A player's character (e.g., Fen) is at Character Level 30 (max)
- When: A match grant computes `charXp` for Fen
- Then: `character_progress.charXp` for Fen is not incremented; no level-up event fires; `CHAR_MAX_LEVEL_REACHED` analytics event is emitted on first hit only; Match Results Screen shows full bar with "MAX" indicator

**AC-XP-17 — XP Grant Arrives While Player Is Offline**
- Given: A match ends; Match Flow fires `match_result_for_xp`; the player's client is disconnected
- When: The XP service processes the grant (without client connection)
- Then: The grant writes to PostgreSQL normally; Redis profile cache for this `playerId` is invalidated; when the player reconnects and loads their profile, `xp` and `level` reflect the completed grant; no XP is lost

**AC-XP-18 — Invalid characterId in Payload**
- Given: `match_result_for_xp` arrives with a `characterId` that does not match any known character definition
- When: The XP service processes the grant
- Then: Account XP is credited normally; Character XP credit is skipped; `XP_CHAR_CREDIT_SKIPPED` warning is logged with `{matchId, playerId, characterId}`; no match cancellation or error is returned to Match Flow

---

### 8.7 Mode Gates

**AC-XP-19 — Squad Brawl Locked Below Account Level 3**
- Given: A player at Account Level 2 attempts to queue for 3v3 Squad Brawl
- When: The server processes the queue request
- Then: The request is rejected with error code `ACCOUNT_LEVEL_GATE`; the client does not display the Squad Brawl option as available (mode availability read from server-authoritative profile at lobby load)

**AC-XP-20 — FFA Mode Unlocks at Account Level 8**
- Given: A player advances from Account Level 7 to Account Level 8
- When: The level-up transaction commits
- Then: The FFA mode flag is set in the player's profile; on the player's next lobby load, the FFA mode option is displayed and selectable; the `LEVEL_UP_ACCOUNT` analytics event for Level 8 includes `gateUnlocked: "ffa_8"`

---

*End of Document*
