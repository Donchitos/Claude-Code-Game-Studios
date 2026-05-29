# MMR / Ranked System — Game Design Document

> **System**: MMR / Ranked System
> **Priority**: MVP
> **Layer**: Core Data
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

---

## 1. Overview

The MMR / Ranked System provides a single, server-authoritative Elo-style numerical rating for every player across all three game modes: 1v1 Duel, 3v3 Squad Brawl, and 8-player FFA. The rating is the backbone of BRAWLZONE's competitive experience — it powers matchmaking queue bucketing, drives the rank tier displayed on the player's profile and match results screen, and determines seasonal rewards at the end of each ranked season.

**Rating architecture decision — Unified rating:** All three modes share a single `mmr` value stored on the Player Profile. This is an explicit design choice justified below in Section 3.1. Separate per-mode ratings are not used at launch.

**Provisional vs. Established:** New accounts enter a provisional period for their first 30 career matches (across all modes combined). During this period, the K-factor is doubled (32 vs. 16) and the matchmaking bracket is widened, accelerating initial placement accuracy. Once a player completes 30 matches they become established and remain so permanently.

**What MMR is used for:**
- **Matchmaking quality** — the Matchmaking Engine reads `mmr` and `is_provisional` to assign players to queue buckets; provisional players are matched in a wider ±MMR band.
- **Match Results display** — the Match Results Screen reads the pre-match and post-match `mmr` to compute and display the delta (e.g., +18 or −12).
- **Rank tier** — a player's rank tier label (Bronze through Champion) is derived directly from their `mmr` value against fixed boundary thresholds; no separate tier progression track exists.
- **Seasonal rewards** — at season end, the highest rank tier a player achieved during the season (tracked via `peak_mmr` and `season_mmr_snapshot`) determines which reward tier they receive.

---

## 2. Player Fantasy

The core feeling of the MMR system is **visible, meaningful progress under fair conditions**.

Every point matters. When a player sees +24 flash on the Match Results Screen after a hard-won duel against a higher-rated opponent, they feel the game acknowledged the difficulty of that victory. When they lose 8 points to a lower-rated player after a lucky upset, the small deduction stings just enough to be honest. Neither number feels arbitrary.

The rank tier names — Bronze, Silver, Gold, Platinum, Diamond, Champion — carry real weight. Reaching Gold feels like leaving beginner territory behind. Cracking Platinum means you have beaten more opponents than have beaten you at a meaningful sample size. Diamond is rare enough to feel elite. Champion exists for the top of the ladder, visible to everyone on leaderboards.

The provisional period creates a specific early-game arc: placement uncertainty. A new player does not know where they truly belong. Their rating moves fast in both directions, and every win or loss feels more consequential than it will later. This accelerated volatility converts the onboarding grind into a satisfying skill-reveal experience — the game is figuring them out, and they are figuring themselves out at the same time.

Seasonal resets create a recurring fresh-start ritual. The soft reset at the top of each season compresses high ratings toward the median, giving every established player a reason to climb again. The player who reached Platinum last season starts Silver and feels the season is new, not a repetition. The climb back — and hopefully further — is the loop that retains competitive players across seasons.

Losing streaks are painful but bounded by the rating floor; no player can fall below Bronze. Winning streaks are bounded by arithmetic rather than an artificial ceiling — Champion players are simply the ones with the highest MMR above 2200, ranked among themselves. Progress always reflects real performance.

---

## 3. Detailed Rules

### 3.1 Per-Mode vs. Unified Rating — Decision and Justification

**Decision: Unified single MMR across all modes.**

At launch, one `mmr` value on the Player Profile covers 1v1 Duel, 3v3 Squad Brawl, and 8-player FFA. This decision is justified by the following:

1. **Player base size:** BRAWLZONE is launching into a cold-start environment. Splitting MMR into three independent queues would mean three separate matchmaking pools, each one-third the size of the total player base. Thin pools produce long queue times and poor match quality — both kill early retention. A unified pool maximizes match quality at low total player counts.

2. **Cognitive simplicity:** A single visible rating on the profile is easier for new players to understand and care about. Multiple ratings (one per mode) would require the player to optimize across three numbers, which dilutes the focus of the competitive climb.

3. **Cross-mode identity:** The game encourages players to try all three modes. A unified rating means that playing Squad Brawl does not feel like "wasted progress" on your Duel rating. Every match contributes to a single number.

4. **Mode-specific formulas preserve fairness within unity:** The FFA placement-based outcome formula (Section 4) distributes Elo outcomes across placements rather than treating all non-winners as losers, so the unified rating still reflects per-mode skill fairly.

**Revisit condition:** If the player base reaches a level where each mode can sustain its own matchmaking pool (estimated at 10,000 concurrent active players per mode, measured after launch), per-mode ratings may be introduced in a future season as a seasonal feature. This would require adding `mmr_duel`, `mmr_squad`, `mmr_ffa` columns to the Player Profile schema and migrating the unified `mmr` as the seed for all three.

---

### 3.2 Starting MMR for New Accounts

All new accounts start at **MMR 1000**.

This places new players at the Silver–Gold boundary, which is the designed midpoint of the ladder. Starting at the midpoint rather than the floor (Bronze) means:
- A new player who is genuinely average will hover near their starting value, experiencing roughly balanced wins and losses.
- A skilled new player (e.g., experienced in similar brawler games) will rapidly climb through their provisional period without being stuck at the floor for many matches.
- A novice will fall below 1000 into Bronze/Silver, which accurately reflects their current skill level.

Starting MMR is defined in the Player Profile as the default value of the `mmr` field (`1000`). It is not hard-coded in the MMR/Ranked System — the system reads the current `mmr` from the Player Profile and applies the Elo delta; the starting value is a concern of profile creation only.

---

### 3.3 Provisional Period

**Definition:** A player is provisional when `provisional_match_count < 30`. This count increments by 1 after each completed ranked match (any mode), up to a maximum of 30, after which it stops incrementing and the player is permanently established.

The `provisional_match_count` field is server-only (never sent to the client). The derived boolean `is_provisional` IS sent to the client (used to display provisional indicators in the UI).

**How provisional differs from established:**

| Attribute | Provisional (`count < 30`) | Established (`count ≥ 30`) |
|---|---|---|
| K-factor | 32 | 16 |
| MMR volatility per match | Higher (up to ±32) | Lower (up to ±16) |
| Matchmaking bracket width | ±300 MMR | ±300 MMR (standard) |
| Rank tier displayed | Shows rank as "Placement" or current tier | Shows full rank tier label |
| Peak MMR tracked | Yes (provisionally) | Yes |

**Bracket width values** are tuning knobs owned by the Matchmaking Engine GDD. The ±300 (provisional) / ±300 (standard) split listed here is the MMR system's design intent, but the Matchmaking Engine implements and may tune these independently.

---

### 3.4 Rating Floor and Ceiling

| Boundary | Value | Behavior |
|---|---|---|
| **Floor** | 100 | `mmr` cannot drop below 100. If a loss would take MMR below 100, it is clamped to 100. |
| **Ceiling** | None | There is no upper MMR ceiling. Champion players accumulate MMR above 2200 without limit. |

**Floor rationale:** A floor of 100 prevents degenerate situations where a player's MMR falls so low that they become unmatchable (no opponents near 0 MMR), and it preserves the player's dignity — even the worst player on the ladder is not rated at zero. The floor is set well below Bronze (500–800) so it has no practical effect on engaged players; it only catches extreme cases like abandonment-farmers.

**No ceiling rationale:** An artificial cap on Champion-tier ratings would compress the leaderboard and make it impossible to distinguish the best players from each other. Unbounded upward growth allows the leaderboard to naturally separate elite players by skill.

---

### 3.5 Rank Tiers

Six named tiers, defined by MMR lower bound (inclusive). A player's tier is derived by finding the highest tier whose threshold they meet or exceed.

| Tier | MMR Range | Description |
|---|---|---|
| **Bronze** | 100 – 799 | Entry level. Placement and learning matches. |
| **Silver** | 800 – 1199 | Developing fundamentals. Near starting MMR. |
| **Gold** | 1200 – 1599 | Consistent play, above average. |
| **Platinum** | 1600 – 1999 | Strong player, top third of active ladder. |
| **Diamond** | 2000 – 2199 | Elite. Access to Diamond-only premium characters is visible as aspirational social proof here. |
| **Champion** | 2200+ | Top of ladder. No upper bound. |

**Tier derivation rule:** `rank_tier` is a computed field derived from `mmr` at read time. It is also stored as a denormalized column `rank_tier` (varchar, e.g., `"gold"`) on the Player Profile for fast Matchmaking queries and leaderboard filtering, updated atomically whenever `mmr` changes.

**Diamond character unlock note:** Premium Diamond-only characters are unlocked via IAP (Diamonds currency), not by reaching Diamond tier. The Diamond rank tier and Diamond characters share a name for thematic cohesion, but the rank has no mechanical gate on the characters.

---

### 3.6 3v3 Squad Brawl MMR Calculation

**Decision: Individual player MMR updates, using team average as the opponent rating.**

In a 3v3 match, each player on the winning team and each player on the losing team receives an individual MMR update. The "opponent rating" used in the Elo formula for each player is the **average MMR of all players on the opposing team**.

```
opposing_team_avg_mmr = (mmr_opponent_1 + mmr_opponent_2 + mmr_opponent_3) / 3
```

Each player on Team A calculates their update using `opposing_team_avg_mmr` from Team B, and vice versa.

**Rationale:**
- Individual MMR updates ensure that a low-MMR player carried by high-MMR teammates still gains MMR that reflects the quality of opposition they faced, not just a win bonus.
- Using team average rather than per-opponent calculations avoids giving a player outsized MMR gains simply because one weak opponent happened to be on the other team; the average smooths this effect.
- This approach is used by major team-ranked games (e.g., League of Legends before per-position ratings) and is the simplest correct implementation that does not require tracking individual in-match performance metrics (which creates anti-fun pressure to optimize for stats over team play).

**No draw in 3v3:** Squad Brawl has a team eliminations win condition. In the event of a time-out tie (equal eliminations at match end), both teams receive `outcome = 0.5`. This is handled identically to the 1v1 draw case.

---

### 3.7 8-Player FFA MMR Calculation

**Placement-based outcome formula:**

In an 8-player FFA, each player's outcome is derived linearly from their placement:

```
outcome = (8 - placement) / (8 - 1)
        = (8 - placement) / 7
```

Where `placement` is an integer from 1 (1st place) to 8 (8th place).

| Placement | Outcome |
|---|---|
| 1st | 1.000 |
| 2nd | 0.857 |
| 3rd | 0.714 |
| 4th | 0.571 |
| 5th | 0.429 |
| 6th | 0.286 |
| 7th | 0.143 |
| 8th | 0.000 |

**Opponent rating in FFA:** Each player's Elo expected outcome is calculated against the **average MMR of all other 7 players in the match**:

```
ffa_opponent_avg_mmr = (sum of all other players' MMR) / 7
```

This gives each player a single expected outcome value, and their placement-based actual outcome is compared against it using the standard Elo formula.

**Rationale:** A linear placement-to-outcome mapping ensures that every improvement in placement produces an equal Elo reward, creating an incentive to always play for a better finish rather than accepting any non-last place as equally good. The average-MMR opponent model is the simplest statistically valid approach for multi-player Elo without requiring pairwise comparison across all 28 possible player pairs.

---

### 3.8 Seasonal Resets

**Reset type: Soft reset (compression toward median).**

At the start of each new season, all players' MMR is compressed toward the median MMR value (1000) by 50%.

```
new_season_mmr = floor(mmr + (median_mmr - mmr) × compression_ratio)
median_mmr     = 1000   (fixed anchor; not the actual ladder median)
compression_ratio = 0.50
```

Example: A Diamond player at 2100 MMR resets to `floor(2100 + (1000 - 2100) × 0.50) = floor(2100 - 550) = 1550` (Platinum range). A Bronze player at 650 MMR resets to `floor(650 + (1000 - 650) × 0.50) = floor(650 + 175) = 825` (Silver range).

**Season timing:** Seasons last approximately 8 weeks. Season transitions occur at 00:00 UTC on the scheduled reset date. The season schedule is published in-game 2 weeks before the end of each season.

**season_mmr_snapshot:** At the moment the season ends (before the reset is applied), each player's `mmr` value is written to `season_mmr_snapshot`. This snapshot is used to calculate seasonal rewards and is preserved as a read-only historical record.

**Provisional reset:** The `provisional_match_count` and `is_provisional` flag are NOT reset at season start. A player who completed their provisional period in Season 1 remains established in Season 2.

**Hard reset is explicitly rejected:** A full reset to 1000 for all players was considered and rejected because it erases all differentiation gained during the season, creating a "everyone is equal at day one" experience that makes the first week of each season feel chaotic and unfun. Soft reset preserves relative skill ordering while creating genuine climb room.

---

### 3.9 MMR Update Timing

**When the update fires:** MMR is calculated and written to the Player Profile **after match end**. The sequence is:

1. Match server detects end condition (win/loss/draw/placement determined).
2. Match server emits `match_ended` event to the MMR/Ranked System.
3. MMR/Ranked System reads current `mmr` for all affected players from PostgreSQL (`SELECT ... FOR UPDATE` to serialize concurrent updates).
4. MMR deltas are calculated for all players.
5. MMR writes committed to PostgreSQL (atomic per player: `mmr`, `peak_mmr`, `is_provisional`, `provisional_match_count`, `rank_tier`).
6. Match Flow calls MMR synchronously via RPC and waits up to 3000 ms for the result. If MMR update times out or fails, `mmrDelta` is set to `0` and processing continues regardless.
7. Match Flow fans out directly to the Reward System (Model B parallel fan-out). MMR does not trigger Reward — Match Flow calls both systems independently.
8. Match Results Screen reads the delta values from the MMR RPC response payload.

---

### 3.10 Minimum Match Duration for MMR Award

**Minimum duration: 60 seconds.**

A match must have been active for at least 60 seconds before MMR is awarded to any participant. If a match ends (by any mechanism including disconnect) before 60 seconds of active play have elapsed, no MMR changes are applied to any player.

**Active play time** is measured from the moment the match countdown completes (the 3-second countdown is excluded) to the moment the match ends.

**Rationale:** Prevents exploitation via intentional early disconnect ("smurf farming") where a high-skill player queues, confirms their opponent is weaker, disconnects immediately, and forces a win without the match recording a real performance sample.

**Edge case: sub-60-second matches that are legitimate:** In 1v1, it is theoretically possible to eliminate an opponent within 60 seconds through normal gameplay. If the match ends legitimately before 60 seconds (e.g., player KO'd at 45 seconds), MMR is still withheld for that match. This is a rare case accepted as a design tradeoff — the anti-abuse value of a simple time threshold outweighs the edge case of an unusually fast legitimate win failing to award MMR. Players will see a "Match too short — no MMR awarded" message on the results screen in this scenario.

---

## 4. Formulas

### 4.1 Core Elo Formula (from game-concept.md — authoritative)

```
new_rating = old_rating + K × (outcome - expected_outcome)

expected_outcome = 1 / (1 + 10^((opponent_rating - player_rating) / 400))

K = 32    when provisional_match_count < 30
K = 16    when provisional_match_count ≥ 30

outcome = 1.0   (win)
outcome = 0.5   (draw)
outcome = 0.0   (loss)
```

All intermediate values use floating-point arithmetic. The final `new_rating` is rounded to the nearest integer before writing to the database. `mmr` is stored as a PostgreSQL `integer`.

---

### 4.2 Rank Tier Boundary Table

| Tier | Lower Bound (inclusive) | Upper Bound (inclusive) |
|---|---|---|
| Bronze | 100 | 799 |
| Silver | 800 | 1199 |
| Gold | 1200 | 1599 |
| Platinum | 1600 | 1999 |
| Diamond | 2000 | 2199 |
| Champion | 2200 | ∞ (no cap) |

**Derivation pseudocode:**
```
function get_rank_tier(mmr):
    if mmr >= 2200: return "champion"
    if mmr >= 2000: return "diamond"
    if mmr >= 1600: return "platinum"
    if mmr >= 1200: return "gold"
    if mmr >= 800:  return "silver"
    return "bronze"   // floor is 100; below 800 is always bronze
```

---

### 4.3 FFA Placement-to-Outcome Formula

```
outcome_ffa(placement, total_players) = (total_players - placement) / (total_players - 1)
```

For a full 8-player lobby (`total_players = 8`):

```
outcome_ffa(placement) = (8 - placement) / 7
```

For a reduced lobby due to disconnects, `total_players` is the number of players who were present at match start (not the number still connected at match end). This preserves outcome consistency — a 1st place finish in a lobby that started with 8 players is always worth `outcome = 1.0` regardless of how many players disconnected mid-match.

---

### 4.4 3v3 Team Average Opponent Rating Formula

```
opposing_team_avg_mmr = (mmr_A + mmr_B + mmr_C) / 3
```

where A, B, C are the three players on the opposing team.

This value is used as `opponent_rating` in the core Elo formula for each player on the winning/losing team.

---

### 4.5 Soft-Reset Formula

```
new_season_mmr = floor(current_mmr + (MEDIAN_ANCHOR - current_mmr) × COMPRESSION_RATIO)

MEDIAN_ANCHOR      = 1000  (tuning knob — fixed anchor, not actual ladder median)
COMPRESSION_RATIO  = 0.50  (tuning knob — proportion of gap collapsed toward anchor)
```

The floor of 100 is applied after reset: `new_season_mmr = max(100, new_season_mmr)`.

---

### 4.6 Worked Examples

#### Example A — 1v1 Duel, Established Player Wins Against Lower-Rated Opponent

- Player A (established): MMR = 1500
- Player B (established): MMR = 1200
- Player A wins (`outcome = 1.0`)

```
expected_A = 1 / (1 + 10^((1200 - 1500) / 400))
           = 1 / (1 + 10^(-0.75))
           = 1 / (1 + 0.1778)
           = 1 / 1.1778
           = 0.8490

K_A = 16 (established)
delta_A = 16 × (1.0 - 0.8490) = 16 × 0.1510 = 2.42  →  +2 MMR

expected_B = 1 - expected_A = 1 - 0.8490 = 0.1510

K_B = 16 (established)
delta_B = 16 × (0.0 - 0.1510) = 16 × (-0.1510) = -2.42  →  -2 MMR

Player A: 1500 + 2 = 1502
Player B: 1200 - 2 = 1198
```

**Interpretation:** Winning as a heavy favorite earns almost no MMR; losing as a heavy favorite costs almost nothing. The system correctly treats this as an expected outcome.

---

#### Example B — 1v1 Duel, Provisional Player Upsets Higher-Rated Established Player

- Player A (provisional, count = 15): MMR = 1000
- Player B (established): MMR = 1600
- Player A wins (`outcome = 1.0`)

```
expected_A = 1 / (1 + 10^((1600 - 1000) / 400))
           = 1 / (1 + 10^(1.50))
           = 1 / (1 + 31.623)
           = 1 / 32.623
           = 0.0307

K_A = 32 (provisional)
delta_A = 32 × (1.0 - 0.0307) = 32 × 0.9693 = 31.02  →  +31 MMR

expected_B = 1 - expected_A = 1 - 0.0307 = 0.9693

K_B = 16 (established)
delta_B = 16 × (0.0 - 0.9693) = 16 × (-0.9693) = -15.51  →  -16 MMR

Player A: 1000 + 31 = 1031
Player B: 1600 - 16 = 1584
```

**Interpretation:** The upset earns the provisional player a large MMR jump (+31), rapidly moving them toward their true rating. The established player loses a moderate amount (-16) for losing to a heavy underdog.

---

#### Example C — 3v3 Squad Brawl, Team A Wins

- Team A: Player 1 (1400), Player 2 (1600), Player 3 (1200) — all established
- Team B: Player 4 (1300), Player 5 (1500), Player 6 (1100) — all established
- Team A wins.

```
opposing_team_avg_mmr for Team A players = (1300 + 1500 + 1100) / 3 = 1300

For Player 1 (1400 vs 1300 avg):
  expected_1 = 1 / (1 + 10^((1300-1400)/400)) = 1 / (1 + 10^(-0.25)) = 1 / 1.5623 = 0.6402
  delta_1 = 16 × (1.0 - 0.6402) = 16 × 0.3598 = 5.76  →  +6 MMR

For Player 2 (1600 vs 1300 avg):
  expected_2 = 1 / (1 + 10^((1300-1600)/400)) = 1 / (1 + 10^(-0.75)) = 1 / 1.1778 = 0.8490
  delta_2 = 16 × (1.0 - 0.8490) = 16 × 0.1510 = 2.42  →  +2 MMR

For Player 3 (1200 vs 1300 avg):
  expected_3 = 1 / (1 + 10^((1300-1200)/400)) = 1 / (1 + 10^(0.25)) = 1 / 2.7783 = 0.3601
  delta_3 = 16 × (1.0 - 0.3601) = 16 × 0.6399 = 10.24  →  +10 MMR

opposing_team_avg_mmr for Team B players = (1400 + 1600 + 1200) / 3 = 1400

For Player 4 (1300 vs 1400 avg):
  expected_4 = 1 / (1 + 10^((1400-1300)/400)) = 1 / (1 + 10^(0.25)) = 0.3601
  delta_4 = 16 × (0.0 - 0.3601) = -5.76  →  -6 MMR

For Player 5 (1500 vs 1400 avg):
  expected_5 = 1 / (1 + 10^((1400-1500)/400)) = 1 / (1 + 10^(-0.25)) = 0.6402
  delta_5 = 16 × (0.0 - 0.6402) = -10.24  →  -10 MMR

For Player 6 (1100 vs 1400 avg):
  expected_6 = 1 / (1 + 10^((1400-1100)/400)) = 1 / (1 + 10^(0.75)) = 1 / 6.6228 = 0.1510
  delta_6 = 16 × (0.0 - 0.1510) = -2.42  →  -2 MMR
```

**Interpretation:** The lower-rated player on the winning team (Player 3) gains the most MMR (+10) because their team's win was against a stronger opposing average than their individual rating. The strongest player on the losing team (Player 5, 1500 rating) loses the most (-10) because their team was expected to perform well and did not.

---

#### Example D — 8-Player FFA

All 8 players are established. Ratings (sorted by placement order): P1=1800, P2=1600, P3=1400, P4=1200, P5=1000, P6=900, P7=800, P8=700.

```
ffa_avg_mmr_for_P1 = (1600+1400+1200+1000+900+800+700) / 7 = 7600 / 7 = 1085.7

expected_P1 = 1 / (1 + 10^((1085.7-1800)/400)) = 1 / (1 + 10^(-1.786)) = 1 / (1 + 0.01637) = 0.9839

outcome_P1  = (8-1)/7 = 1.000
delta_P1    = 16 × (1.000 - 0.9839) = 16 × 0.0161 = 0.26  →  +0 MMR (rounds to 0)
```

**Note on rounding:** Due to P1's high rating and strong expected outcome, the actual delta rounds to 0 for 1st place — the system correctly gives minimal reward to a heavy favorite winning as expected. An upset (high-MMR player placing poorly) would yield a larger negative delta.

```
ffa_avg_mmr_for_P8 = (1800+1600+1400+1200+1000+900+800) / 7 = 8700 / 7 = 1242.9

expected_P8 = 1 / (1 + 10^((1242.9-700)/400)) = 1 / (1 + 10^(1.357)) = 1 / (1 + 22.73) = 0.0421

outcome_P8  = (8-8)/7 = 0.000
delta_P8    = 16 × (0.000 - 0.0421) = -0.67  →  -1 MMR
```

**Interpretation:** P8 (700 MMR) is expected to finish last and does; they lose only 1 MMR. This is correct behavior: the system does not punish a weak player heavily for losing to 7 stronger opponents.

---

#### Example E — Soft Reset at Season End

- Player at 2100 MMR (Diamond): `floor(2100 + (1000 - 2100) × 0.50) = floor(2100 - 550) = 1550` → Platinum (1550)
- Player at 1000 MMR (Silver/boundary): `floor(1000 + (1000 - 1000) × 0.50) = 1000` → Silver (1000, unchanged)
- Player at 650 MMR (Bronze): `floor(650 + (1000 - 650) × 0.50) = floor(650 + 175) = 825` → Silver (825)
- Player at 100 MMR (floor): `floor(100 + (1000 - 100) × 0.50) = floor(100 + 450) = 550` → Bronze (550) — floor player always moves up on reset

---

## 5. Edge Cases

### 5.1 Disconnected Player

**1v1 Duel disconnect:**
- If a player disconnects, the connected player is declared the winner after a 30-second reconnection window (owned by the Disconnect Handler / Reconnect system). The winner receives `outcome = 1.0`. The disconnected player receives `outcome = 0.0`. **MMR IS updated for both players**, provided the match lasted at least 60 seconds before the disconnect (Section 3.10).
- If the disconnect occurs before 60 seconds of active play, MMR is withheld for both players.
- The disconnected player cannot appeal the loss — the system treats intentional and accidental disconnects identically.

**3v3 Squad Brawl disconnect:**
- If a player disconnects mid-match, their character is marked inactive and the match continues.
- At match end, all 6 players (including the disconnected player) receive individual MMR updates based on the team outcome and their personal MMR vs. opposing team average. The disconnected player receives the same outcome (win or loss) as their team.
- **Exception:** If the disconnected player disconnects before the 60-second minimum match duration, they receive `outcome = null` (no MMR update). Their 5 teammates are unaffected — if the match reaches 60 seconds and eventually ends, the 5 participants receive MMR updates.

**8-player FFA disconnect:**
- If a player disconnects, they are assigned the last-occupied placement at the moment of disconnect. Example: If 6 players are still alive when a player disconnects, they are assigned placement 7 (one above the last place reserved for future eliminations). All disconnected players are assigned placements in disconnect-time order before the final survivor placement.
- The disconnected player receives the outcome calculated from their assigned placement.
- Minimum match duration rule applies: if disconnect occurs before 60 seconds, no MMR is awarded to the disconnecting player.

---

### 5.2 Draw in 1v1

A draw in 1v1 Duel occurs when the time limit expires with both players alive and equal health (see game-concept.md edge cases for time-out draw handling).

Both players receive `outcome = 0.5`. The Elo formula produces a small adjustment pushing each player's MMR slightly toward convergence:
- If Player A is rated higher: A loses a small amount, B gains a small amount.
- If both players are equal rated: neither gains nor loses (delta = 0).

Draw is a valid `outcome` value in the formula and requires no special handling beyond using `outcome = 0.5`.

---

### 5.3 FFA with Fewer Than 8 Players Due to Disconnect

If the match started with 8 players and some disconnect mid-match, the `total_players` used in the placement formula is **always 8** (the count at match start, not the count at match end).

```
outcome_ffa(placement) = (8 - placement) / 7
```

The placements are still assigned using the full 1–8 range (disconnected players receive their assigned placement as described in 5.1). The formula remains consistent and is not recalculated based on remaining players.

**Rationale:** Recalculating the formula based on surviving player count would mean that finishing 1st in a 3-person match (after 5 disconnects) yields the same MMR gain as finishing 1st in a full 8-person match. This would create an exploit where players coordinate mass disconnects to boost a friend. Anchoring to 8 prevents this.

---

### 5.4 Both Players at Rating Floor (1v1)

If both players have MMR = 100 (the floor) and one loses:

```
delta = K × (0.0 - 0.5) = K × (-0.5)  [equal ratings: expected = 0.5]
```

The calculated new rating would be below 100. The floor clamp is applied:

```
new_mmr = max(100, 100 + delta)  →  max(100, 100 - 8) = max(100, 92) = 100
```

The loser stays at 100 (floor-clamped). The winner gains normally:

```
delta_winner = K × (1.0 - 0.5) = K × 0.5 = +8 MMR  →  100 + 8 = 108
```

**Important:** The winner's gain is calculated using the opponent's nominal MMR (100), not a reduced value. The floor only affects the loser's clamped outcome. The winner earns their full deserved delta.

---

### 5.5 Player at Provisional vs. Established Opponents (1v1)

The K-factor used in the formula is **each player's own K-factor**, applied to their own delta calculation. The opponent's K-factor is irrelevant to the player's own delta.

If Player A is provisional (K=32) and Player B is established (K=16):
- Player A's delta = 32 × (outcome_A - expected_A)
- Player B's delta = 16 × (outcome_B - expected_B)

This means A's rating moves twice as fast as B's, which is intended — the provisional player is still seeking their equilibrium rating. The asymmetry in K-factors means the match may produce a larger absolute swing for A than B even from the same outcome.

**Starting MMR mismatch:** A newly created account (MMR 1000) playing against an established Platinum player (MMR 1700) will face a very low expected outcome (~0.07). If the new player wins, they gain approximately 31 × 0.93 = +29 MMR (provisional K=32). If they lose, they lose approximately 32 × 0.07 = -2 MMR. The provisional K-factor and asymmetric loss protection ensures new players are not punished heavily for losing to established players while being appropriately rewarded for upsets.

---

### 5.6 Season End While Match Is In Progress

If a season ends (at 00:00 UTC on the scheduled reset date) while a match is actively in progress:

1. The match continues to completion using the pre-season-end MMR values for all calculations.
2. When the match ends, the MMR deltas are applied to the player's current `mmr` value in the database. **If the soft reset has already been applied** (the season reset job ran during the match), the delta is applied to the post-reset value.
3. The `season_mmr_snapshot` that was saved at season end reflects the MMR at the moment of the season boundary, before the post-match delta. This is the value used for seasonal reward determination.

**Implementation note:** The season reset job must apply the `season_mmr_snapshot` write and the soft reset in a single database transaction. The MMR write after a mid-boundary match applies a delta on top of whatever value exists at write time — this is safe because the delta calculation uses pre-match MMR (snapshotted at match start), not the current database value, preventing the soft reset from being double-applied to the delta.

---

### 5.7 Tied Placements in FFA

If two or more players are eliminated simultaneously in FFA (e.g., they kill each other in the same server tick), they receive tied placements. Tied players receive the average of the placements they would occupy:

```
tied_outcome = average(outcome_ffa(p) for p in tied_placements)
```

Example: Players A and B both eliminated in the same tick, occupying what would be 5th and 6th place:
```
outcome_A = outcome_B = average((8-5)/7, (8-6)/7) = average(3/7, 2/7) = average(0.429, 0.286) = 0.357
```

Both receive `outcome = 0.357` for MMR calculation. The next living player is ranked 7th (not 6th).

---

## 6. Dependencies

### 6.1 Fields Owned by This System (on Player Profile)

The MMR/Ranked System is the exclusive writer of the following Player Profile fields:

| Field | Type | Owned By | Notes |
|---|---|---|---|
| `mmr` | `integer` | MMR/Ranked System | Current rating. Written post-match. Floor = 100. |
| `peak_mmr` | `integer` | MMR/Ranked System | Highest `mmr` ever recorded. Updated atomically with `mmr` when `new_mmr > peak_mmr`. Never decreases. |
| `rank_tier` | `varchar` | MMR/Ranked System | Denormalized tier label (`"bronze"` through `"champion"`). Updated atomically with `mmr`. |
| `season_mmr_snapshot` | `integer` | MMR/Ranked System | Snapshot of `mmr` at the moment the most recent season ended. Written by the season reset job. Read-only after write until next season end. |

**Fields the MMR/Ranked System reads but does not own:**

| Field | Owner | Why MMR Reads It |
|---|---|---|
| `is_provisional` | MMR/Ranked System (derived) | Used to select K-factor |
| `provisional_match_count` | Match Server | Read to determine K-factor; MMR does not write this field |

**Note on `is_provisional`:** The Player Profile GDD lists `is_provisional` as owned by the MMR/Ranked System for the `is_provisional` boolean and by Match Server for `provisional_match_count`. The MMR/Ranked System writes `is_provisional` as a derived boolean in the same transaction as `mmr` (whenever `provisional_match_count` crosses 30). In practice, Match Server increments `provisional_match_count` first, then MMR/Ranked System updates `is_provisional` — both within the same post-match processing transaction.

---

### 6.2 Upstream Dependencies

| System | Dependency Type | What MMR Consumes |
|---|---|---|
| **Player Profile** | Hard — must exist before MMR can function | `mmr`, `peak_mmr`, `is_provisional`, `provisional_match_count` (read); `mmr`, `peak_mmr`, `rank_tier`, `season_mmr_snapshot` (write). Schema managed by Player Profile system. |
| **Match Flow** | Hard — triggers the MMR update | `match_ended` event payload: match mode, player list with pre-match MMR snapshot, outcome / placement for each player. MMR does not self-trigger; it always waits for Match Flow to fire. |

---

### 6.3 Downstream Consumers

| System | Consumes From MMR | How |
|---|---|---|
| **Matchmaking Engine** | Reads `mmr`, `is_provisional`, `rank_tier` | Buckets players into MMR-range queues; provisional flag widens the bracket. Matchmaking reads these fields from Redis-cached Player Profile. |
| **Match Results Screen** | Reads MMR delta from `mmr_updated` event | Displays `+N` or `−N` next to the player's rank tier icon. Also shows new tier if a tier boundary was crossed. |
| **Leaderboard System** | Reads `mmr`, `peak_mmr`, `rank_tier` | Renders ranked leaderboard sorted by `mmr` descending; segments by `rank_tier`. |
| **Reward System** | Reads `season_mmr_snapshot`, `rank_tier` | Determines which seasonal reward tier the player receives at season end. |

---

## 7. Tuning Knobs

All knobs are stored in the Remote Config / Live Tuning system and can be changed without a code deploy. Ranges listed indicate values that have been considered safe; going outside these ranges requires a design review.

| Knob | Default | Safe Range | Effect of Change |
|---|---|---|---|
| `MMR_K_PROVISIONAL` | `32` | 16 – 64 | Higher K = faster placement convergence for new players but more volatility. Lower K slows placement. Should always be ≥ `MMR_K_ESTABLISHED`. |
| `MMR_K_ESTABLISHED` | `16` | 8 – 32 | Higher K = more volatile established ladder (more match-to-match swings). Lower K = stickier ladder (ratings move slowly, can feel unrewarding). |
| `MMR_PROVISIONAL_THRESHOLD` | `30` | 10 – 50 | Lower = shorter provisional period (faster settle, less accurate). Higher = longer provisional period (slower settle, more accurate initial placement). Changing mid-season does not retroactively alter existing provisional counts. |
| `MMR_FLOOR` | `100` | 0 – 500 | Setting floor higher (e.g., 500) makes Bronze shrink and compresses the lower ladder. Setting floor to 0 allows theoretically zero-MMR accounts (not recommended). |
| `MMR_STARTING_VALUE` | `1000` | 800 – 1200 | Must match Player Profile default. Changes to this knob only affect future new account creation — it is a profile creation concern, not an MMR system concern. These two values must be kept in sync via config review. |
| `MMR_SEASON_COMPRESSION_RATIO` | `0.50` | 0.25 – 0.75 | Lower ratio = gentler reset (less climb room at season start). Higher ratio = more aggressive reset (Diamond players reset closer to Silver). At 1.0, all players reset to 1000 (equivalent to hard reset). |
| `MMR_SEASON_MEDIAN_ANCHOR` | `1000` | 800 – 1200 | The target value that all players compress toward. Raising this slightly (e.g., 1100) shifts the post-reset ladder upward, useful if the ladder median has drifted below the starting MMR due to inflation/deflation. |
| `MMR_MIN_MATCH_DURATION_SECONDS` | `60` | 30 – 180 | Lower = more fast matches qualify for MMR but increases abuse potential. Higher = more protection against disconnect abuse but occasional frustration for legitimately fast matches. |
| `MMR_RANK_TIER_BRONZE_MIN` | `100` | 100 – 200 | Effectively the floor; changing this changes where Bronze starts and where the gap between floor and Bronze bottom is. |
| `MMR_RANK_TIER_SILVER_MIN` | `800` | 700 – 900 | Adjusting tier boundaries changes how many players occupy each tier. Use with ladder population data from analytics. |
| `MMR_RANK_TIER_GOLD_MIN` | `1200` | 1100 – 1300 | See Silver note. |
| `MMR_RANK_TIER_PLATINUM_MIN` | `1600` | 1500 – 1700 | See Silver note. |
| `MMR_RANK_TIER_DIAMOND_MIN` | `2000` | 1900 – 2100 | See Silver note. |
| `MMR_RANK_TIER_CHAMPION_MIN` | `2200` | 2100 – 2400 | Raising this makes Champion rarer; lowering it makes Champion more accessible. Should be set so top 1–3% of active players qualify. |

**Tier boundary change protocol:** Changing any `MMR_RANK_TIER_*_MIN` knob must be announced to players before it takes effect, as it may immediately promote or demote players without any matches played. A minimum 48-hour notice in-game is required. `rank_tier` fields on all affected profiles must be recomputed by a server-side migration job after the boundary change takes effect.

---

## 8. Acceptance Criteria

All criteria are verifiable by QA against a test environment with a real PostgreSQL + Redis stack and a Node.js match server running in test mode.

---

### AC-MMR-01: Starting MMR on New Account

**Given** a new player account is created  
**When** the first profile read occurs after creation  
**Then**:
- `mmr = 1000`
- `peak_mmr = 1000`
- `is_provisional = true`
- `provisional_match_count = 0`
- `rank_tier = "silver"`

---

### AC-MMR-02: Elo Formula — Established Win Against Equal Opponent

**Given** Player A (established, MMR 1000) vs Player B (established, MMR 1000) in 1v1 Duel  
**When** Player A wins  
**Then**:
- `expected_outcome ≈ 0.500` (equal ratings)
- `delta_A = round(16 × (1.0 - 0.500)) = round(8.0) = +8`
- `delta_B = round(16 × (0.0 - 0.500)) = round(-8.0) = -8`
- Player A `mmr = 1008`
- Player B `mmr = 992`

---

### AC-MMR-03: Elo Formula — Provisional K-Factor

**Given** Player A (provisional, count=10, MMR 1000) vs Player B (established, MMR 1000) in 1v1 Duel  
**When** Player A wins  
**Then**:
- Player A's delta uses K=32: `delta_A = +16`
- Player B's delta uses K=16: `delta_B = -8`
- Player A `mmr = 1016`
- Player B `mmr = 992`
- The deltas are asymmetric because K-factors differ.

---

### AC-MMR-04: Elo Formula — Draw

**Given** Player A (established, MMR 1200) vs Player B (established, MMR 1000) in 1v1 Duel  
**When** the match ends in a draw  
**Then**:
- `outcome = 0.5` for both players
- `expected_A > 0.5` (A is rated higher)
- Player A's `mmr` decreases by at least 1 (A was expected to win; draw is below expectation)
- Player B's `mmr` increases by at least 1 (B was expected to lose; draw exceeds expectation)

---

### AC-MMR-05: Rating Floor Clamp

**Given** Player A (established, MMR 100) loses to Player B (established, MMR 100) in 1v1 Duel  
**When** the MMR update is applied  
**Then**:
- Player A's calculated delta would be negative
- Player A's `mmr` is clamped to `100` (not less)
- Player B's `mmr` increases by the full calculated delta (not clamped)

---

### AC-MMR-06: Rank Tier Derivation

**Given** the following MMR values  
**When** `rank_tier` is derived  
**Then** (one assertion per row):

| MMR | Expected Tier |
|---|---|
| 100 | `"bronze"` |
| 799 | `"bronze"` |
| 800 | `"silver"` |
| 1199 | `"silver"` |
| 1200 | `"gold"` |
| 1599 | `"gold"` |
| 1600 | `"platinum"` |
| 1999 | `"platinum"` |
| 2000 | `"diamond"` |
| 2199 | `"diamond"` |
| 2200 | `"champion"` |
| 5000 | `"champion"` |

---

### AC-MMR-07: Rank Tier Boundary Crossing Updates Stored Tier

**Given** Player A is established with `mmr = 1198` and `rank_tier = "silver"`  
**When** a match results in `delta = +4` (bringing mmr to 1202)  
**Then**:
- `mmr = 1202`
- `rank_tier = "gold"` (updated atomically with mmr)
- The Match Results Screen event payload contains `tier_changed = true`, `old_tier = "silver"`, `new_tier = "gold"`

---

### AC-MMR-08: Provisional Transition

**Given** Player A has `provisional_match_count = 29` and `is_provisional = true`  
**When** Player A completes one more ranked match (any mode)  
**Then**:
- `provisional_match_count = 30`
- `is_provisional = false`
- Both field updates occur in the same PostgreSQL transaction
- Future matches use K=16 for Player A

---

### AC-MMR-09: Peak MMR Update

**Given** Player A has `mmr = 1400` and `peak_mmr = 1500`  
**When** Player A wins and `mmr` increases to `1501`  
**Then**:
- `mmr = 1501`
- `peak_mmr = 1501`
- Both updates occur in the same transaction

**Given** Player A has `mmr = 1400` and `peak_mmr = 1500`  
**When** Player A wins and `mmr` increases to `1450`  
**Then**:
- `mmr = 1450`
- `peak_mmr = 1500` (unchanged — new mmr does not exceed peak)

---

### AC-MMR-10: 3v3 MMR Update — Team Average Opponent

**Given** a completed 3v3 match where Team A wins  
**When** MMR updates are applied  
**Then**:
- Each player on Team A uses the average MMR of Team B's three players as `opponent_rating`
- Each player on Team B uses the average MMR of Team A's three players as `opponent_rating`
- All 6 players receive individual MMR updates
- A lower-rated winning player gains more MMR than a higher-rated winning player (when facing the same average opposition)

---

### AC-MMR-11: FFA Placement Outcome Formula

**Given** an 8-player FFA match that completes normally  
**When** MMR updates are applied  
**Then**:
- 1st place player receives `outcome = 1.000`
- 8th place player receives `outcome = 0.000`
- Each intermediate placement receives `outcome = (8 - placement) / 7`, verified to 3 decimal places
- All 8 players' `mmr` values are updated in the same batch commit

---

### AC-MMR-12: FFA Disconnect — Placement Preserved at 8-Player Denominator

**Given** an 8-player FFA match where 2 players disconnect during play, leaving 6 active players at match end  
**When** MMR updates are applied  
**Then**:
- Disconnected players receive placements based on their elimination order during the match
- All outcomes use `(8 - placement) / 7` — denominator is 7 (based on 8-player start), not 5
- The 6 players who completed the match receive correct placements 1–6 (disconnected players hold 7th and 8th)

---

### AC-MMR-13: Minimum Match Duration — Below Threshold

**Given** a 1v1 match where one player disconnects at T=45 seconds  
**When** the match ends with a winner declared  
**Then**:
- MMR is NOT updated for either player
- `provisional_match_count` is NOT incremented for either player
- The Match Results Screen shows a "Match too short — no MMR awarded" message
- Match rewards (diamonds, XP) are still evaluated per the Reward System's rules (MMR suppression does not suppress all rewards)

---

### AC-MMR-14: Minimum Match Duration — Above Threshold

**Given** a 1v1 match that runs for 90 seconds before a winner is determined  
**When** the match ends  
**Then**:
- MMR IS updated for both players
- `provisional_match_count` IS incremented for both players (if applicable)

---

### AC-MMR-15: Season Soft Reset Formula

**Given** a season ends and the following player MMRs exist: 2100, 1600, 1000, 650, 100  
**When** the season soft reset is applied (`COMPRESSION_RATIO = 0.50`, `MEDIAN_ANCHOR = 1000`)  
**Then**:
- 2100 → `floor(2100 + (1000-2100) × 0.50)` = 1550
- 1600 → `floor(1600 + (1000-1600) × 0.50)` = 1300
- 1000 → `floor(1000 + (1000-1000) × 0.50)` = 1000
- 650  → `floor(650 + (1000-650) × 0.50)` = 825
- 100  → `floor(100 + (1000-100) × 0.50)` = 550
- All new MMR values satisfy `mmr ≥ 100` (floor)

---

### AC-MMR-16: Season Snapshot Written Before Reset

**Given** a player with `mmr = 1850` at season end  
**When** the season transition job runs  
**Then**:
- `season_mmr_snapshot = 1850` is written BEFORE the soft reset is applied
- After soft reset, `mmr = floor(1850 + (1000-1850) × 0.50) = 1425`
- `season_mmr_snapshot` remains `1850` (not overwritten by the post-reset value)

---

### AC-MMR-17: Match In Progress at Season End

**Given** Player A has `mmr = 1800` and a match starts  
**When** the season end job runs mid-match (applying soft reset to `mmr = 1400`) and the match then ends with Player A winning (+18 calculated delta based on pre-match MMR snapshot of 1800)  
**Then**:
- Delta is applied to the current database value at write time: `1400 + 18 = 1418`
- `season_mmr_snapshot = 1800` (pre-reset value, captured at season end)
- No double-application of the reset occurs

---

### AC-MMR-18: Disconnected Player in 1v1 — MMR Applied After Minimum Duration

**Given** a 1v1 match where the active duration exceeds 60 seconds and one player disconnects  
**When** the remaining player is declared the winner  
**Then**:
- Winner receives `outcome = 1.0`, MMR updated normally
- Disconnected player receives `outcome = 0.0`, MMR updated normally
- `provisional_match_count` incremented for both players

---

### AC-MMR-19: Concurrent MMR Writes Are Serialized

**Given** two separate match results are processed simultaneously for the same player (simulated in test via concurrent API calls)  
**When** both MMR update transactions execute  
**Then**:
- Only one transaction holds `SELECT ... FOR UPDATE` lock at a time
- Both deltas are applied sequentially; neither delta is lost
- Final `mmr` reflects exactly both deltas (no lost update)
- No deadlock or lock timeout error is returned to either caller

---

*End of MMR / Ranked System — Game Design Document*
