# Cross-GDD Review Report

> **Date**: 2026-05-28
> **GDDs Reviewed**: 44 system GDDs + game-concept.md + systems-index.md
> **Scope**: Full — Consistency (2a–2f) + Design Holism (3a–3g) + Scenario Walkthroughs (4 scenarios)
> **Entity Registry**: Empty at time of review — consistency checks relied on full GDD reads
> **Verdict**: ❌ FAIL — 10 blocking issues; architecture cannot begin until resolved

---

## Consistency Issues (Phase 2)

### 🔴 Blocking — Must Resolve Before Architecture

#### C-01: Character Roster Identity Crisis
Three incompatible 8-character rosters exist simultaneously:
- `character-system.md` + `deck-loadout.md`: Free = {Vex, Syla, Grim}; Earnable = {Sera, Zook, Fen}; Premium = {Nyx, Volt}
- `inventory-entitlements.md` + `ability-skill.md` + `battle-pass.md`: Free = {Vex, Zook, Sera}; Earnable = {Fen, Grim, Dash}; Premium = {Colt, Nyx}
- `player-profile.md` AC-PP-01: Free = {brawler_maya, brawler_rex, brawler_zara} (names no other GDD uses)

Premium character prices conflict: 500 Diamonds (`inventory-entitlements.md §4.2`) vs 800 Diamonds (`currency-system.md §3.3.2`). Earnable prices: 600/800/1200 Coins (inventory) vs 2500 Coins flat (currency). `inventory-entitlements.md §4.1` self-flags this as "a consistency review action item." Breaks Character System validation, Inventory grants, Ability affinity resolution, Purchase Fulfillment bundle mapping, and Battle Pass free-track character rewards simultaneously.

**Resolution**: Designate `content-catalog.md` as the single source of truth for all 8 character IDs, categories, and prices. All other GDDs reference it.

#### C-02: Ability Pool Identity Crisis
Two incompatible ability registries:
- `ability-skill.md §3.9/3.10`: 14 abilities, UPPER_SNAKE_CASE IDs (`BURST_SHOT`, `POWER_SLAM`), damage values 80–220
- `deck-loadout.md §3.2`: 18 abilities, snake_case IDs (`ability_burstsurge`, `ability_rollaway`), damage values 12–30
- `bot-ai.md` ACs reference a third set (`ability_dash`, `ability_shockwave`)

`ability-skill.md` `POWER_SLAM` deals 220 damage against 100 HP baseline — an instant one-shot that violates `combat-system.md §3.3` anti-pattern ("no kill from full HP in one ability") and pillar P1. `xp-progression.md §3.3.1` says each character has 18 abilities in 3 per-character tiers; `deck-loadout.md` defines 18 as a global shared pool. The runtime ability layer and the loadout/select layer reference disjoint registries.

**Resolution**: Merge into one canonical 18-ability shared pool in `deck-loadout.md`. Deprecate `ability-skill.md`'s parallel registry. Rebalance magnitudes (no single hit > ~40% max HP).

#### C-03: Match Duration Override
`session-manager.md §3.6` hardcodes `maxDurationS: 600` in the MatchConfig it builds. `game-mode.md §3.1` sets per-mode durations: Duel 180s, Squad Brawl 300s, FFA 480s. Session Manager's hardcoded 600 overrides all per-mode limits — a Duel would run to 600s.

**Resolution**: Session Manager must read `maxDurationSec` from the Game Mode config when building MatchConfig.

#### C-04: Coin Reward Formula — Dual Ownership
`currency-system.md §4.1`: `COIN_BASE_WIN=45 / COIN_BASE_LOSS=25`, Play Pass ×1.5. States: "The Currency System owns the calculation."
`reward-system.md §4.1`: `BASE_COINS{duel:40, squad:50, ffa:45} × WIN_MULTIPLIER + kill/assist/survival bonuses + FIRST_WIN_BONUS(150)`. States: "The Reward System is the canonical authority."
`game-concept.md`: Diamond grants 3 (loss) / 5 (win); `currency-system.md`: Diamonds only on wins at 5 flat.

**Resolution**: Reward System owns match Coin calculation. Currency System owns transaction mechanics only. Remove the formula from `currency-system.md §4.1`.

#### C-05: Diamond IAP Pack Catalog Conflict
`iap-system.md §3.5`: 4 packs (80/$0.99, 400/$4.99, 900/$9.99, 2000/$19.99)
`currency-system.md §4.2` + `purchase-fulfillment.md §4.1`: 6 packs (80/200/500/1100/2400/6500 Diamonds, different amounts and product IDs)

**Resolution**: Align `iap-system.md` to the 6-pack table in currency-system/purchase-fulfillment.

#### C-06: MMR Trigger / Ordering AC Contradiction
`match-flow.md AC-MF-06/07`: MMR is a synchronous `updateRatings()` RPC; on timeout, set `mmrDelta=0` and **proceed** with fan-out.
`mmr-ranked.md AC-MMR-20`: "If MMR update fails, reward distribution does **not** proceed."
`session-manager.md §3.8`: emits `session_ended` directly to MMR (a third trigger model).
AC-MF-07 and AC-MMR-20 cannot both pass.

**Resolution**: Match Flow owns the trigger (synchronous RPC). Timeout → mmrDelta=0, fan-out proceeds. Remove AC-MMR-20's "block rewards on MMR failure." Session Manager does not emit to MMR directly.

#### C-07: Free-Character AC Trilemma
`inventory-entitlements.md AC-01/15`: free = `{char_vex, char_zook, char_sera}`
`player-profile.md AC-PP-01`: free = `{brawler_maya, brawler_rex, brawler_zara}`
`character-system.md`: free = `{char_vex, char_syla, char_grim}`
All three are "new account initialization" ACs. A single test suite cannot satisfy all three. Resolves with C-01.

---

### ⚠️ Warnings (Consistency)

| # | Issue | GDDs |
|---|-------|------|
| W-C-01 | `xpAtLevelStart`/`xpToNextLevel`/`timeAliveSec` missing from `MatchResultsPayload` — one-directional claims from `xp-progression.md §3.9` unreconciled in `match-flow.md §4.1` | match-flow, xp-progression |
| W-C-02 | `PlayerState` lacks `isInactive: boolean` flag required by `bot-ai.md §3.2` | match-server, bot-ai |
| W-C-03 | `MatchResultForQuests` missing `damageDealt`, `abilityUseCounts`, `survived`, `matchStartedAt` (required by `quest-mission.md §6.2`). DEAL_DAMAGE and USE_ABILITY quest types cannot function without them. | match-flow, quest-mission |
| W-C-04 | No `dequeued` event with `reason` field in `matchmaking-engine.md` — required by `lobby.md §3.10/§5.5` | matchmaking-engine, lobby |
| W-C-05 | `MATCH_REWARD_GRANTED` event missing `matchStartedAt` field — required by `battle-pass.md §5.5` for season-boundary attribution | reward-system, battle-pass |
| W-C-06 | `maxSkillSpreadMMR` default: 300 (matchmaking-engine §7) vs 200 (remote-config §3.1) vs 150–300 (mmr-ranked §3.3) | matchmaking-engine, mmr-ranked, remote-config |
| W-C-07 | `remote-config.md` `character.maxAbilitySlots` default = 3 vs `character-system.md` hard-typed `ability_slot_count: 2` | remote-config, character-system |
| W-C-08 | Mode ID strings have 3 vocabularies: `"duel"` / `"duel_1v1"` / `"ffa_8p"` vs `"ffa_8"` vs `"ffa"`. String-keyed lookups will silently miss. | game-mode, match-flow, remote-config |
| W-C-09 | `currency-system.md §3.3.4` writes `has_play_pass=true` on Battle Pass purchase (conflates BP and Play Pass) at 800 Diamonds; `battle-pass.md §3.5` writes `isPremium=true` at 950 Diamonds — wrong target + wrong price | currency-system, battle-pass |
| W-C-10 | Two "first win of day" subsystems with independent state: Reward System (`first_win_claimed_date`, +150 Coins) and XP System (`isFirstWinOfDay`, +100 XP) — no shared claim record | reward-system, xp-progression |

---

## Game Design Issues (Phase 3)

### 🔴 Blocking

#### D-01: Ability Magnitudes Produce One-Shot TTK — Pillar P1 Violation
`ability-skill.md` pool has `POWER_SLAM` at 220 damage against 100 HP base. A single ability one-shots from full HP, violating `combat-system.md §3.3` anti-pattern ("no kill from full HP in one ability") and pillar P1 ("tight, readable, fair combat"). Resolves automatically if `ability-skill.md`'s pool is deprecated in favour of `deck-loadout.md`'s 12–30 damage values (C-02 resolution).

#### D-02: No Designated Dominant Progression Loop (Retention Risk)
Five progression loops (Account Level, Character Level, MMR, Battle Pass, Quests) each pay Coins and each frame themselves as a primary activity. No document designates an anchor meta-loop. With no `game-pillars.md` and 6+ Coin faucets vs 1 real sink (3 earnable characters), players who unlock all earnable characters lose progression direction. Recommend `game-pillars.md` authored before architecture.

---

### ⚠️ Warnings (Design)

| # | Issue | Affected Systems |
|---|-------|-----------------|
| W-D-01 | **Coin endgame surplus**: 6+ faucets vs 1 real sink (3 earnable chars + cheap cosmetics). Once Fen/Grim/Dash are unlocked, Coins accumulate to cap and become meaningless. No conversion valve. | currency-system, reward-system, xp-progression, battle-pass, quest-mission |
| W-D-02 | **FFA cognitive overload**: 5–6 simultaneously active in-combat decision systems (movement, aim, 2 ability slots, opponent-cooldown reading, zone/map awareness, 7-player target selection) — exceeds >4 threshold for mobile touchscreen. Recommend explicit playtest gate for FFA. | combat-system, ability-skill, map-arena, game-mode |
| W-D-03 | **"Options ≠ Power" pillar tension**: new player at MMR 1000 can face an established player with full 18-ability palette while newcomer has only 6. In a deckbuilding game, loadout breadth is a real strategic edge — soft-contradicts P4 pillar. | xp-progression, deck-loadout, mmr-ranked |
| W-D-04 | **Battle Pass edge case**: 0–30% win-rate Duel players cannot complete 30 tiers in 42 days without quest BPXP buffer. Quest→BP BPXP signal not emitted by `quest-mission.md`. | battle-pass, quest-mission |
| W-D-05 | **Play Pass earn multiplier fragility**: Coin ×1.5 / Diamond ×1.25 is safe while ability unlocks are XP-gated. If any Coin-purchasable ability slot is added later, the multiplier becomes a competitive advantage. Document as explicit guardrail. | currency-system, iap-system |

---

## Cross-System Scenario Issues (Phase 4)

**Scenarios walked**: (1) Match-end Model B fan-out chain; (2) Disconnect→reconnect→reward crediting; (3) First-win + quest + BP tier from one match; (4) IAP bundle mid-session → usable at character select; (5) Multi-source grant vs wallet cap

### 🔴 Blockers

**S-01 (Scenarios 1+3): "First Win of Day" — Triple Ownership, No Shared State**
Reward System: `first_win_claimed_date` → +150 Coins. XP System: `isFirstWinOfDay` cached flag → +100 XP. No shared claim record. Under Model B parallel fan-out, a stale cache can produce the XP bonus without the Coin bonus (or vice versa). Contradictory player-visible itemization on results screen. Undefined behavior.

**Resolution**: Assign single first-win authority (Reward System) and single claim record (`first_win_claimed_date`). XP System reads the same record.

**S-02 (Scenario 1): `match_results_payload` Schema — Three Incompatible Shapes**
`match-flow.md §4.1`: `xpEarned: number | null` (nullable stub); no `xpAtLevelStart`/`xpToNextLevel`.
`xp-progression.md §3.9`: these fields required, never-null.
`match-results.md §3.1`: flattened single-player shape, not `playerResults[]` array.
The results screen cannot be built against three contradictory contracts.

**S-03 (Scenario 4): IAP Bundle→Character Select Chain Broken by Roster Conflict**
`purchase-fulfillment.md` maps `character_bundle_colt` → Colt entitlement. `character-system.md` roster has no Colt (has Volt). Purchased bundle fails character-select validation. Resolves with C-01.

**S-04 (Scenario 2): Match Flow Scopes Out Reconnect, Reconnect Depends on Match Flow**
`match-flow.md §1` explicitly excludes reconnect ("deferred to Vertical Slice"). `reconnect-resume.md §6.2` requires `matchFlow.onPlayerReconnected()`. Note: reward/XP/BPXP crediting itself is correct (server-side, fires regardless of client state). The blocker is the missing API contract in Match Flow.

### ⚠️ Warnings (Scenarios)

**S-W-01: Quest XP Double-Grant Risk**
`xp-progression.md §3.4.4` folds `questBonus = +50 XP per quest` into match XP grant (keyed by matchId). `quest-mission.md §3.6` also grants XP via direct `grantXPBonus()` (keyed by questId). Different idempotency domains — dedup misses cross-system double XP.

**S-W-02: BPXP Has No Idempotency Key**
`battle-pass.md §3.3` credits BPXP from `MATCH_REWARD_GRANTED` events with no dedup key on the BPXP write. At-least-once event bus → re-emitted event double-counts BPXP.

**S-W-03: Multi-Source Wallet-Cap Ordering Undefined**
Up to 5 independent Coin grants (match reward, quest completion, first-win bonus, Account level-up, Character level-up) can race the 50,000 cap in one match session with no defined ordering. Which grant gets truncated is nondeterministic and un-reproducible for player support.

**S-W-04: Reward/MMR Trigger Authority Ambiguous**
Match Flow calls MMR via synchronous RPC. MMR GDD separately describes Reward as downstream of an `mmr_updated` event. Two models will produce race conditions when implemented.

---

## GDDs Requiring Revision

| GDD | Reason | Priority |
|-----|--------|----------|
| `character-system.md` | Wrong roster (Syla/Volt vs Dash/Colt); wrong earnable/free split; single attack_range vs melee/ranged split | 🔴 Needs Revision |
| `player-profile.md` | `FREE_CHARACTER_IDS` / AC-PP-01 uses unknown character names (brawler_maya/rex/zara) | 🔴 Needs Revision |
| `ability-skill.md` | 14-ability UPPER_SNAKE pool incompatible with deck-loadout 18-ability pool; one-shot damage values; wrong roster affinity | 🔴 Needs Revision |
| `deck-loadout.md` | Affinity roster references Syla/Volt (wrong); ability pool must be reconciled with ability-skill | 🔴 Needs Revision |
| `currency-system.md` | Remove duplicate Coin formula; fix BP price (950 not 800); fix BP entitlement target; fix earnable char prices | 🔴 Needs Revision |
| `reward-system.md` | Remove dual-ownership claim; add `matchStartedAt` to `MATCH_REWARD_GRANTED` event | 🔴 Needs Revision |
| `session-manager.md` | Read `maxDurationSec` from Game Mode config, don't hardcode 600 | 🔴 Needs Revision |
| `match-flow.md` | Add payload fields; add `matchStartedAt` to fan-out events; resolve AC ordering; add `onPlayerReconnected` stub; unify mode ID strings | 🔴 Needs Revision |
| `mmr-ranked.md` | Remove AC-MMR-20 "block rewards on MMR fail"; remove independent event-based Reward trigger; align `maxSkillSpreadMMR` default | 🔴 Needs Revision |
| `iap-system.md` | Align Diamond pack catalog to currency-system/purchase-fulfillment 6-pack table | 🔴 Needs Revision |
| `match-server.md` | Add `isInactive: boolean` to `PlayerState` | ⚠️ Needs Revision |
| `matchmaking-engine.md` | Add `dequeued` event with `reason` field; align `maxSkillSpreadMMR` default | ⚠️ Needs Revision |
| `quest-mission.md` | Extend `MatchResultForQuests` with 4 required fields; emit BPXP signal to Battle Pass | ⚠️ Needs Revision |
| `battle-pass.md` | Add BPXP idempotency key; align `matchStartedAt` source; resolve price ambiguity | ⚠️ Needs Revision |
| `xp-progression.md` | Reconcile quest XP double-grant; coordinate first-win state with Reward System | ⚠️ Needs Revision |
| `remote-config.md` | Fix `maxAbilitySlots` (2); fix `balanceMultipliers` shape; fix `mmrKFactor` split; fix `ffa_8p` mode ID | ⚠️ Needs Revision |
| `game-mode.md` | Standardize mode ID strings; confirm Session Manager reads per-mode `maxDurationSec` | ⚠️ Needs Revision |

---

## Verdict: ❌ FAIL

10 blocking issues must be resolved before architecture begins. They cluster into 5 themes:

1. **Character + Ability Registry** (C-01, C-02, C-07, D-01, S-03): Establish canonical 8-character roster and 18-ability pool in Content Catalog. Highest-leverage single fix — unblocks 7+ GDDs.
2. **Economy Ownership** (C-04, C-05, C-09, W-C-10, S-01): Reward System owns match Coin formula. Single first-win authority. Align IAP pack tables.
3. **Match Flow Contract** (W-C-01, W-C-03, W-C-05, S-02): Freeze `match_results_payload` with all required fields. Add `matchStartedAt` everywhere.
4. **Session/Match Duration** (C-03): Session Manager reads game-mode `maxDurationSec`.
5. **MMR Trigger Model** (C-06, S-W-04): Single synchronous RPC path; remove event-based Reward trigger; fix blocking AC pair.

### Required Actions Before Re-Running

1. Author `game-pillars.md` to document the canonical 8-character roster, 18-ability pool, dominant progression loop, and F2P guardrails
2. Revise `content-catalog.md` to be the single source of truth for all character IDs/categories/prices and the ability registry
3. Update all 10 blocking GDDs to align to the Content Catalog definitions
4. Add missing payload fields to `match-flow.md` (xpAtLevelStart, xpToNextLevel, timeAliveSec, matchStartedAt, damageDealt, abilityUseCounts, survived)
5. Re-run `/review-all-gdds consistency` after revisions
6. Re-run `/gate-check systems-design` when verdict changes to PASS or CONCERNS
