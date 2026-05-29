# Game Pillars — BRAWLZONE

> **Status**: Draft
> **Created**: 2026-05-29
> **Last Updated**: 2026-05-29
> **Category**: Foundation
> **Priority**: MVP
> **Canonical Role**: This document is the authoritative reference that resolves design conflicts
> when two systems disagree on the player's meta-journey. All 44 system GDDs must align their
> "Player Fantasy" section to the pillars and dominant progression loop defined here.

---

## 1. Overview

BRAWLZONE is a mobile-first PvP brawler that fuses the fast, readable combat of Brawl Stars with the
pre-match strategic depth of Ludus. Eight playable characters compete across three modes — 1v1 Duel,
3v3 Squad Brawl, and 8-player FFA — using a shared pool of 18 abilities organized into loadouts
assembled before each match. The server is authoritative at 20Hz; the client is React Native / Expo
with a Node.js back end.

This document defines BRAWLZONE's four design pillars (P1–P4), the dominant progression loop that
binds every system together, the Coin faucet hierarchy, F2P guardrails, and the known Alpha gap in
Coin endgame. Every system GDD in this project should open its "Player Fantasy" section with a
statement connecting that system's purpose to the dominant progression loop and at least one pillar
defined here. When a design decision in any system conflicts with another, the pillar and loop
definitions below take precedence.

---

## 2. Player Fantasy

> **The feeling BRAWLZONE must deliver:**
> "I got better at composing a powerful deck AND at executing it in a match — and the win feels earned."

Both halves of that sentence must be present. A win that comes from a lucky loadout the player did
not consciously assemble feels hollow. A loss that feels unfair or unreadable destroys trust.
BRAWLZONE earns long-term retention only when the player can credit both their strategic choices and
their in-match skill.

### P1 — Tight, Readable, Fair Combat

Every death must be understandable. The player who dies should be able to replay the last five
seconds in their head and identify the mistake or the opponent's superior play — not chalk it up to
luck, hidden information, or an ability that "came out of nowhere." This pillar governs Combat,
Ability / Skill, Map / Arena, Match Server, and HUD.

Implication: damage numbers must be visible, ability animations must telegraph intent, and no single
hit from full HP can result in elimination at any tier of ability.

### P2 — Meaningful Pre-Match Decisions

The loadout screen is not a formality. The six abilities a player selects before a match should
produce a coherent strategy — a plan they intend to execute. Choosing abilities for a specific
character on a specific map against a likely opponent composition should produce measurable
win-rate differentiation when executed correctly. This pillar governs Deck / Loadout, Character /
Deck Select, Ability / Skill, and Character System.

Implication: no loadout configuration should be so dominant that match diversity collapses. If
>60% of players at any rank tier run the same two loadout configurations, P2 has failed and Tier 2
ability tuning must be revisited.

### P3 — Clear Progression Path Always Visible

At every moment in the player journey — after their first match, after their tenth, after they have
played for thirty days — there is at least one visible goal the player is actively progressing
toward: Account Level, Character Level, Coin balance toward an earnable character, an active Quest,
or MMR rank movement. The player should never open the game and think "I've done everything."
This pillar governs XP & Progression, Quest / Mission, Reward System, Battle Pass, Main Menu,
and Player Profile.

Implication: UI surfaces must always render at least one progress indicator with a concrete target
and current distance. P3 is violated if all progression tracks simultaneously stall.

### P4 — Options ≠ Power

Unlocking abilities expands the player's strategic vocabulary; it does not give them a raw damage or
survivability advantage over players with fewer unlocked abilities. The six Tier 2 abilities have
higher situational upside and higher execution risk compared to their Tier 1 counterparts — not
higher base output. A new player at Tier 1 facing a veteran with all 18 abilities should lose
primarily because the veteran is more skilled at reading the situation and assembling a matching
loadout, not because the veteran's numbers are higher. This pillar governs Ability / Skill, Deck /
Loadout, IAP System, Battle Pass, and all Economy systems.

Implication: no ability gated behind Diamonds, Coins, or premium purchase. No Tier 2 ability
exceeds the base damage cap defined in Acceptance Criteria.

---

## 3. Detailed Rules — Dominant Progression Loop

The dominant progression loop is the anchor meta-structure of BRAWLZONE. Every reward system, every
unlock gate, and every engagement hook must reinforce this loop. Systems that are not directly part
of the loop must at minimum not interrupt it. The loop is ordered from highest retention weight
(most critical to maintain) to lowest:

### Step 1 — Play Match → Earn Account XP (primary) + Match Coins (secondary)

Every completed match, win or loss, awards Account XP and Match Coins. The XP amount is the primary
progression vector and is not purchasable. Match Coins are a secondary reward used for earnable
character unlocks. Neither resource can be skipped or gated behind a paywall.

### Step 2 — Account XP → Level Up → Unlock Abilities

Account XP accumulates lifetime. At 500 XP the player unlocks all six Tier 1 abilities (expanding
their pool from Starter 6 to 12). At 1,500 XP the player unlocks all six Tier 2 abilities
(expanding their pool to the full 18). These gates are XP-only — no Diamond spend, no Coin spend,
no premium requirement of any kind.

### Step 3 — More Abilities → Richer Deck Options → More Interesting Pre-Match Decisions

Each ability unlock broadens the strategic space at the loadout screen. Early-game players operate
with a simpler deck (12 abilities, shallower niche combinations). Late-game players have a richer
palette (18 abilities, niche applications and higher-skill-ceiling interactions). This expanding
decision space is the primary reason players continue playing past the first week.

### Step 4 — Better Decisions → Better Match Performance → Faster Progression

Mastery of loadout composition translates directly into match results. Better match results increase
Account XP accrual rate (through win bonuses and kill/assist bonuses), which accelerates the ability
unlock cycle in Steps 2–3. The loop is self-reinforcing for engaged players.

### Step 5 — Secondary: Earn Coins → Unlock Earnable Characters

Match Coins accumulate across the primary loop. Three characters (Grim at 600 Coins, Fen at 800
Coins, Dash at 1,200 Coins) are unlockable through sustained match play. Unlocking an earnable
character grants affinity bonuses for abilities matching that character's archetype. This adds a
parallel strategic layer — not a power advantage — to the P4-safe ability pool.

### Step 6 — Tertiary: MMR Rank + Quest Completion

Seasonal MMR rank provides prestige and matchmaking quality. Daily and weekly Quest completion
provides targeted engagement hooks that reward specific playstyle goals (e.g., "win 2 Duels",
"deal 500 damage with Grim"). Both systems fan off the primary loop without replacing it — they
accelerate Coin and XP gain for engaged players.

### Step 7 — Battle Pass: Parallel Acceleration Track

The Battle Pass (950 Diamonds, 30 tiers, 6-week seasons) provides a time-limited acceleration
layer. It speeds up earnable character Coin unlocks and delivers cosmetics. It never grants ability
access, stat improvements, or combat advantage. The Battle Pass must not interrupt or short-circuit
any step of the dominant loop above. Play Pass subscribers receive a Coin ×1.5 multiplier — this
is safe under P4 because no ability is purchasable with Coins.

### Coin Faucet Hierarchy

The following sources produce Coins, ordered from highest expected volume to lowest:

1. **Match rewards** (win/loss base + kill/assist/survival bonuses) — PRIMARY
2. **Quest completions** (daily, weekly, and milestone quests) — SECONDARY
3. **Account level-up grants** — TERTIARY
4. **Character level-up grants** — QUATERNARY
5. **First-win-of-day bonus** — ENGAGEMENT HOOK

Each system GDD that produces Coins must reference this hierarchy and specify which faucet tier its
Coin outputs belong to. The Match reward faucet must always outpace all other faucets combined on a
per-day basis to keep match engagement as the dominant behavior.

---

## 4. Formulas

None. Game Pillars are a qualitative design foundation. There are no numerical formulas in this
document. All quantitative formulas (XP per match, Coins per match, MMR delta, ability damage
values, etc.) are defined in their respective system GDDs:

- XP and level-up formula: see `design/gdd/xp-progression.md`
- Coin per-match formula: see `design/gdd/reward-system.md`
- MMR delta formula: see `design/gdd/mmr-ranked.md`
- Ability damage values and tier limits: see `design/gdd/ability-skill.md`
- Battle Pass tier structure: see `design/gdd/battle-pass.md`
- Earnable character Coin prices: see `design/gdd/currency-system.md` and `design/gdd/character-system.md`

---

## 5. Edge Cases

### Coin Endgame (Alpha Gap — Known)

**Scenario**: A player has unlocked all three earnable characters (Grim + Fen + Dash, total
2,600 Coins spent) and has no Coin sink remaining.

**Current behavior at Alpha launch**: Coins continue accumulating from match rewards, quests, and
level-up grants with no meaningful spend target. The balance cap is 50,000 Coins. Surplus Coins
above all earnable character costs are accepted as a known Alpha limitation.

**Player impact**: Highly engaged players who hit this state should be directed toward Diamond
cosmetics as an aspirational goal. UI must surface this redirect clearly (e.g., "You've unlocked all
earnable characters! Check out Diamond skins.").

**Guardrail**: Coin surplus must never block the XP-driven ability unlock path (Steps 1–4 of the
dominant loop). Coin accumulation ceiling and path redirect are a UI and messaging concern, not an
ability access concern.

**Resolution (post-Alpha)**: A Coin→skin-fragment conversion valve will be added in a future
update, providing a perpetual Coin sink for endgame players. This is out of scope for Alpha launch.

### All Abilities Unlocked (XP Ceiling)

**Scenario**: A player has reached 1,500+ lifetime Account XP and unlocked all 18 abilities. The XP
unlock loop (Steps 2–3) has fully resolved.

**Current behavior**: XP continues accumulating and feeds Account Level prestige, Character Level
milestones, and MMR refinement. P3 (Clear Progression Path) is maintained through ongoing MMR rank
movement, seasonal Battle Pass tiers, and Quest completion. No dead-end state exists.

### New Player with Zero Abilities Beyond Starter

**Scenario**: A brand-new player logs in, has 0 Account XP, and has access only to the Starter 6
abilities.

**Guardrail**: A Starter 6 loadout must produce a functional, winnable, understandable match
experience. The Starter abilities must cover at least two distinct playstyle archetypes (e.g.,
aggressive and defensive) so the player has a meaningful pre-match choice. P2 and P4 must hold at
the Starter level.

### Battle Pass Expiry While Earning Characters

**Scenario**: A player is partway through earning Fen (800 Coins) when their Battle Pass season
ends mid-progress.

**Resolution**: Coin balance persists across seasons. Battle Pass expiry removes the ×1.5 Coin
multiplier going forward but does not reset or reduce the player's accumulated Coins. The earnable
character unlock is purely Coin-gated, not season-gated.

### P4 Violation Attempt via Future Ability Design

**Scenario**: A future designer proposes a Tier 2 ability with 45 base damage to justify
its high skill floor.

**Resolution**: AC-GP-04 is a hard cap enforced in code review and QA: no Tier 2 ability may deal
more than 30 base damage. If a niche ability requires higher upside, the upside must be
expressed through utility (crowd control, mobility, zone denial) rather than raw damage numbers.
Reject any ability design that violates AC-GP-04 regardless of claimed "skill floor."

---

## 6. Dependencies

### Upstream (what this document depends on)

- `design/gdd/content-catalog.md` — canonical roster of 8 characters, 18 abilities (Starter 6 +
  Tier 1 6 + Tier 2 6), and 3 game modes. Any change to the ability roster or tier structure must
  be reflected here.

### Downstream (what depends on this document)

Every system GDD in this project. The following are the highest-priority alignment targets:

| System GDD | P1–P4 Alignment Required | Loop Alignment Required |
|---|---|---|
| `ability-skill.md` | P1 (readable), P4 (no tier power inflation) | Step 2 (XP → ability unlock), Step 3 (deck breadth) |
| `deck-loadout.md` | P2 (meaningful decisions), P4 (options ≠ power) | Step 3 (richer options), Step 4 (better decisions) |
| `character-system.md` | P4 (affinity bonuses are strategic, not raw power) | Step 5 (earnable characters) |
| `xp-progression.md` | P3 (visible path) | Steps 1–2 (match → XP → unlock) |
| `reward-system.md` | P3 (visible path) | Step 1 (match → Coins), Coin faucet tier 1 |
| `quest-mission.md` | P3 (visible path) | Step 6 (tertiary engagement), Coin faucet tier 2 |
| `battle-pass.md` | P4 (never combat advantage) | Step 7 (acceleration, not replacement) |
| `iap-system.md` | P4 (cosmetics/speed only) | Step 7 (premium track) |
| `currency-system.md` | P4 (Coins cannot buy abilities) | Step 5 (earnable characters), Coin endgame edge case |
| `combat-system.md` | P1 (readable, fair), P4 (no ability power gap) | Step 4 (better execution → better results) |
| `mmr-ranked.md` | P3 (visible rank movement) | Step 6 (tertiary prestige) |
| `match-flow.md` | P1 (death understandable), P3 (post-match summary visible) | Step 1 (XP + Coin emission) |
| `tutorial-onboarding.md` | P1, P2, P3 (introduces all pillars) | Full loop introduction |
| `main-menu.md` | P3 (always shows a progression goal) | Loop entry point |
| `shop-offers-screen.md` | P4 (no ability sales) | Step 7 (cosmetics, BP) |

All 44 system GDDs listed in `design/gdd/systems-index.md` must align to these pillars. GDDs that
do not reference at least one pillar and the dominant loop in their "Player Fantasy" section are
considered non-compliant and should be flagged in the next cross-review pass.

---

## 7. Tuning Knobs

The following values are configurable and governed by Remote Config / Live Tuning after Alpha launch.
Changes to any of these values require a design review against the P1–P4 pillars before shipping.

| Knob | Current Value | Safe Range | What It Affects |
|---|---|---|---|
| Tier 1 ability XP gate | 500 lifetime Account XP | 300–800 XP | Speed of Starter→Tier 1 transition; too low trivializes early game, too high frustrates new players |
| Tier 2 ability XP gate | 1,500 lifetime Account XP | 1,000–2,500 XP | Speed of Tier 1→full roster transition; governs "veteran feel" onset |
| Grim unlock price | 600 Coins | 400–900 Coins | First earnable character accessibility; lower = faster gratification, higher = more sustained goal |
| Fen unlock price | 800 Coins | 600–1,200 Coins | Mid earnable character; should be noticeably harder than Grim |
| Dash unlock price | 1,200 Coins | 900–1,800 Coins | Final earnable character; long-term goal anchor |
| Battle Pass price | 950 Diamonds | 750–1,200 Diamonds | Conversion cost for premium track; must not feel mandatory for F2P progress |
| Battle Pass duration | 6 weeks (30 tiers) | 4–8 weeks | Season cadence; too short = FOMO pressure, too long = content fatigue |
| Play Pass Coin multiplier | ×1.5 | ×1.25–×2.0 | F2P/payer parity; must never reach multiplier that lets payers unlock abilities faster via Coin→character shortcuts (P4 guardrail) |
| Coin balance cap | 50,000 Coins | 20,000–100,000 Coins | Endgame surplus ceiling; lower = earlier redirect to cosmetics, higher = more accumulation runway |
| Max base damage (any Tier 2 ability) | 30 | Hard cap — do not raise | P4 guardrail; raising this is a pillar violation |

Each system GDD that references one of these knobs must cite the current value and safe range from
this table. Conflicts between a system GDD's stated value and this table must be escalated to the
game designer before implementation.

---

## 8. Acceptance Criteria

| ID | Criterion | Verification Method |
|---|---|---|
| AC-GP-01 | A new player who logs in for the first time can enter and complete a 1v1 Duel match within 2 minutes of app open — no paywall, no mandatory tutorial gate, no required IAP. | QA manual walkthrough: fresh install → match completed; timer recorded. |
| AC-GP-02 | After earning exactly 500 lifetime Account XP, the player's ability pool contains exactly 12 abilities (Starter 6 + Tier 1 6). No Tier 2 ability is accessible at this threshold. | Automated unit test against XP progression unlock logic; QA verification in loadout screen. |
| AC-GP-03 | After earning exactly 1,500 lifetime Account XP, the player's ability pool contains all 18 abilities (Starter 6 + Tier 1 6 + Tier 2 6). | Automated unit test against XP progression unlock logic; QA verification in loadout screen. |
| AC-GP-04 | No Tier 2 ability has a base damage value exceeding 30. This cap is enforced for all ability types (projectile, melee, AoE, DoT per tick). | Automated data validation test scanning content-catalog.md ability entries for base_damage > 30; fails CI if any ability violates. |
| AC-GP-05 | A free player (zero IAP, no Battle Pass) who completes their daily First-Win-of-Day bonus and at least 5 matches per day can unlock all 3 earnable characters (Grim, Fen, Dash) within 30 calendar days. | Economy simulation: run 30-day match schedule at minimum engagement level, verify Coin accumulation reaches 2,600 (total unlock cost) within the period. |
| AC-GP-06 | In any match, a player who has spent real money has zero stat, ability-count, cooldown, or damage advantage over a player who has spent nothing. Premium purchases are limited to cosmetics, earnable characters (acceleration), and Diamonds for premium characters. | QA comparative test: create two accounts — one with full IAP history, one F2P — load both into the same match and verify all combat-relevant stats are identical. |
| AC-GP-07 | At any point in the player journey after their first match, the Main Menu displays at least one active Quest and at least one visible progression goal (Account Level progress, Character Level progress, or Coin balance progress toward the next earnable character unlock). | QA walkthrough at Day 1, Day 7, Day 30, and endgame (all characters unlocked) states; verify at least one non-zero progress indicator with a visible target is always rendered. |
| AC-GP-08 | Reaching the Coin balance cap (50,000 Coins) does not prevent Account XP accrual, ability unlocks, Quest completion, or MMR progression. The XP-driven ability unlock path (Steps 1–4 of the dominant loop) must function identically regardless of Coin balance. | Automated integration test: set Coin balance to cap, complete a match, verify XP is awarded and ability unlock gates are evaluated correctly. |
| AC-GP-09 | The Dominant Progression Loop (Play→XP→Abilities→Better Deck) is surfaced in the post-match results screen: XP earned, total lifetime XP, next ability unlock threshold (if not yet unlocked), and Coins earned must all be visible after every match. | QA match results screen inspection at each unlock threshold (0–499 XP, 500–1499 XP, 1500+ XP); verify all four values are present. |
| AC-GP-10 | No ability in the game is sold for Diamonds, Coins, or any real-money currency. Ability access is governed exclusively by Account XP thresholds (AC-GP-02 and AC-GP-03). | Automated scan of shop-offers-screen data and IAP product catalog; reject any entry with ability_id in the purchase payload. |
