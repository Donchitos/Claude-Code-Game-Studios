# Deck / Loadout System — Game Design Document
> **System**: Deck / Loadout System
> **Priority**: MVP ⚠️
> **Layer**: Game Infrastructure
> **Status**: Draft
> **Author**: game-designer
> **Created**: 2026-05-27
> **Last Updated**: 2026-05-27

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

### What a Deck / Loadout Is

A **loadout** is a player-authored configuration of two active abilities attached to a specific character. Every character in BRAWLZONE has a fixed passive ability (defined by the Character System and not editable by the player) and exactly two active ability slots. The loadout fills those two active slots from a shared pool of unlockable abilities. Before each match, the player confirms their loadout for the character they have selected; that configuration is then transmitted to the Match Server and becomes the ability set available to them for the duration of that match.

A loadout is stored per-character in the player's server-side profile. It persists between sessions, and the last-used loadout for each character is automatically restored the next time that character is selected.

### The Strategic Layer

All 8 BRAWLZONE characters share identical base stats (see Character System GDD, Section 3.3). Mechanical differentiation comes entirely from ability composition: the character's fixed passive plus the two active abilities the player chooses. This means that no character is inherently stronger or weaker than another at the start — what matters is what the player brings into the match.

The Deck/Loadout System is the mechanism through which this differentiation is expressed and owned by the player. It converts an otherwise flat roster into a combinatorial design space. A player who has developed an understanding of how abilities interact — which pairings create pressure, which create survival, which deny the opponent's win condition — has a structural advantage over a player who uses the default loadout without thought. That advantage comes from knowledge and mastery, not from spending money or time grinding.

### Why This Is the Differentiator

BRAWLZONE is explicitly designed as a hybrid of fast Brawl Stars-style combat and Ludus-style strategic pre-match composition. Without meaningful loadout decisions, BRAWLZONE becomes a Brawl Stars clone with a thin cosmetic skin over the strategic layer. **The loadout system is the Ludus half of the game's identity.** If a player can win at the same rate by selecting the default loadout as by studying the ability pool and building a counter-composition, the strategic layer has failed.

This system is classified ⚠️ HIGH RISK precisely because the failure mode is invisible: a game where loadouts do not matter will feel exactly like a Brawl Stars clone from the outside, but with an additional friction step before each match. Every design decision in this document — pool breadth, affinity bonuses, ability archetypes, counter-preview rules, unlock pacing — is in service of making the loadout decision meaningful without making it overwhelming.

---

## 2. Player Fantasy

### Pre-Match Preparation

The emotional core of the loadout system is the moment before the match, not during it. When a player sits in character select and opens their loadout editor, the intended feeling is:

> "I know who I'm playing. Now, what do I need to bring?"

For new players, this is discovery: they try different combinations and notice effects in combat. For experienced players, this is anticipation: they have a read on what the meta looks like, they have hypotheses about what the opponent might bring, and they are constructing a configuration designed to beat a specific type of threat. The difference between these two emotional states is depth — the system should support both without making the newcomer feel locked out and without boring the expert.

This is a mobile game. Loadout editing must take less than 60 seconds on average. The pre-match preparation fantasy is not "deckbuilding session" — it is "pregame ritual." The player should feel *ready*, not exhausted.

### Synergy Working in Combat

The deepest satisfaction the loadout system provides is the in-match moment where a synergy the player deliberately built functions exactly as intended. The two active abilities work together — one sets up the other, or one creates a condition the other exploits — and the player feels the reward of having thought ahead.

This moment is only meaningful if it was possible not to build for it. The synergy must have been a choice, not a default. This is why the ability pool must be broad enough that non-synergistic combinations are possible, and why default loadouts (while serviceable) are not optimal for all situations.

### "I Brought Exactly the Right Counters"

In counterplay moments — when a player's loadout was specifically effective against the opponent's configuration — the satisfaction has a different flavor: not just "my plan worked" but "I predicted this." The stretch feature of seeing the opponent's character (not ability) choice before confirming the loadout creates the conditions for this moment. A player who sees their opponent has picked a Support character and swaps to an ability that interrupts heals, then wins the engagement because of that choice, has experienced the highest expression of the loadout system's design intent.

This moment cannot be engineered; it can only be made possible. The design job is to ensure the ability pool contains enough targeted options that counter-selection is a real choice, and to surface enough pre-match information that the player has something to reason about.

---

## 3. Detailed Rules

### 3.1 Loadout Schema

A loadout is the atomic unit of this system. Every character owned by a player has exactly one stored loadout in the Player Profile.

```typescript
interface Loadout {
  character_id: string;        // References a CharacterDefinition. Immutable per loadout record.
  slot1_ability_id: string;    // References an ability record in Content Catalog.
  slot2_ability_id: string;    // References an ability record in Content Catalog.
  last_modified: number;       // Server timestamp (ms) of the last edit. Used for conflict resolution.
}
```

**Constraints enforced at save time (server-side):**
- `slot1_ability_id !== slot2_ability_id` — the same ability cannot occupy both slots. Prevented at the UI layer and re-validated server-side.
- Both ability IDs must resolve to active `loadout_item` records in the Content Catalog.
- Both ability IDs must be in the player's unlocked ability set (see Section 3.5).
- `character_id` must be a valid, player-accessible character.

**Constraints NOT enforced:**
- No slot type restriction — any ability may go in Slot 1 or Slot 2. Order matters only for presentation and player muscle memory, not for game mechanics.
- No archetype restrictions — a player may equip two Offensive, two Defensive, or any cross-archetype pairing.
- Duplicate abilities across team members in Squad Brawl — two teammates with identical loadouts is valid.

---

### 3.2 Ability Pool Design

The ability pool is the set of abilities a player can choose from when building a loadout. All abilities in the pool are `loadout_item` records in the Content Catalog with `item_class: "active_ability"`.

#### 3.2.1 Ability Pool Size at MVP

The MVP pool contains **18 active abilities**, organized into 3 archetypes of 6 abilities each. This yields a manageable decision space (selecting 2 from 18 = 153 unique combinations) that is legible on mobile without being trivially narrow.

#### 3.2.2 Ability Archetypes

| Archetype | Role in Combat | Design Goal |
|---|---|---|
| **Offensive** | Deals burst damage, pressures opponents, creates kill windows | Reward aggression and mechanical precision |
| **Defensive** | Shields, heals, escapes, sustains — prevents death | Reward patience and game-sense |
| **Utility** | Crowd control, debuffs, movement disruption, team support | Reward strategic positioning and opponent reading |

An ability belongs to exactly one archetype. Archetype is a content-authoring classification that is surfaced in the loadout editor UI to help players organize their thinking. It does not restrict slot placement.

#### 3.2.3 MVP Ability Pool — Complete List

The following 18 abilities form the MVP active ability pool. All are `loadout_item` records in the Content Catalog. Cooldown base values are defined here as content data; the Formulas section (Section 4) defines how cooldowns are computed at runtime.

**Offensive Abilities (6)**

| ID | Name | Description | Cooldown (base) | Affinity Characters |
|---|---|---|---|---|
| `ability_burstsurge` | Burst Surge | Unleash a directional shockwave dealing 30 damage to all enemies in a cone. | 8s | `character:vex` |
| `ability_overload` | Overload | Your next attack within 3s deals 2× damage and applies a 0.5s stun. | 10s | `character:colt` |
| `ability_flashstrike` | Flash Strike | Instantly teleport to and strike a target within 5 units for 25 damage. | 9s | `character:nyx` |
| `ability_grenadebarrage` | Grenade Barrage | Launch 3 grenades in a spread; each deals 12 damage on impact. | 12s | `character:zook` |
| `ability_ragepulse` | Rage Pulse | Gain +30% attack damage for 4s. Stacks once with Burst Surge. | 11s | `character:vex` |
| `ability_pindownshot` | Pin-Down Shot | Fire a piercing round that deals 20 damage and roots the target for 1s. | 13s | `character:sera` |

**Defensive Abilities (6)**

| ID | Name | Description | Cooldown (base) | Affinity Characters |
|---|---|---|---|---|
| `ability_ironwall` | Iron Wall | Project a shield absorbing up to 30 damage for 3s. Shield does not move with you. | 10s | `character:grim` |
| `ability_rollaway` | Roll Away | Perform a rapid dodge roll in the facing direction, granting 0.5s of invulnerability. | 7s | `character:dash` |
| `ability_smokecover` | Smoke Cover | Deploy a smoke cloud (3-unit radius, 4s) that makes you untargetable by auto-attacks from outside it. | 14s | `character:nyx` |
| `ability_healfield` | Heal Field | Restore 20 HP immediately and 5 HP/s for 3s. | 15s | `character:fen` |
| `ability_thornbarrier` | Thorn Barrier | Erect a 2s barrier around yourself; any melee attacker takes 10 reflect damage. | 11s | `character:grim` |
| `ability_phasestep` | Phase Step | Teleport 4 units in any direction instantly. No damage; no invulnerability. | 8s | `character:dash` |

**Utility Abilities (6)**

| ID | Name | Description | Cooldown (base) | Affinity Characters |
|---|---|---|---|---|
| `ability_slowfield` | Slow Field | Place a 3-unit zone that slows all enemies inside by 40% for 4s. | 12s | `character:zook` |
| `ability_disruptpulse` | Disrupt Pulse | Emit a burst that silences all enemy active abilities within 4 units for 2s. | 14s | `character:colt` |
| `ability_pullgravity` | Gravity Pull | Yank a target within 6 units 3 units toward you. | 10s | `character:colt` |
| `ability_debuffstrike` | Debuff Strike | Your next attack applies a 20% attack speed reduction to the target for 4s. | 9s | `character:fen` |
| `ability_trapmine` | Trap Mine | Place an invisible mine; first enemy to step on it takes 15 damage and is knocked back. | 11s | `character:zook` |
| `ability_rallycry` | Rally Cry | In 3v3 only: grant 10 HP and a 10% damage boost to the nearest ally for 5s. In 1v1/FFA: grant self 5 HP and +10% damage for 3s. | 13s | `character:fen` |

---

### 3.3 Affinity System

An affinity is a declared relationship between an ability and one or more characters. When a player uses an ability with an affinity for the character they are playing, the ability's primary effect magnitude is increased by the **Affinity Bonus Multiplier** (default: +10%).

**What affinity is:**
- A small multiplier applied to the primary effect of the ability (damage dealt, HP restored, shield HP, duration, range — whichever is the "main effect" as defined in the ability's Content Catalog record).
- A signal to the player that this ability has a special resonance with this character, rewarding character mastery.
- A reward for specialization without creating hard locks.

**What affinity is not:**
- A new mechanic. There is no "affinity resource" or "affinity state." The bonus is computed once at the moment the ability is resolved on the server.
- A reason to never use an ability on a non-affinity character. A non-affinity ability is 100% effective; an affinity ability is 110% effective. Non-affinity ability selection is always valid and frequently correct.
- A gatekeeping mechanism. There are no abilities restricted to specific characters. Any player can select any unlocked ability for any character.

**Affinity determination:**
- Affinity characters are listed per ability in the Content Catalog (`loadout_item` record field: `affinity_character_ids: string[]`).
- At ability resolution, the Match Server checks `ability.affinity_character_ids.includes(player.character_id)`. If true, the affinity multiplier is applied.
- If an ability has no affinity characters listed, it has universal effectiveness (no bonus, no penalty) for all characters.

**Affinity characters — complete mapping (MVP):**

| Ability ID | Affinity Characters | Design Rationale |
|---|---|---|
| `ability_burstsurge` | Vex | Melee AoE rewards Vex's close-range brawler passive momentum |
| `ability_ragepulse` | Vex | Double-down on Vex's damage identity; rewards leaning in |
| `ability_overload` | Colt | Synergizes with Colt's Static Field passive (3-stack stun overlap) |
| `ability_disruptpulse` | Colt | Colt's Controller identity: crowd control amplification |
| `ability_pullgravity` | Colt | Colt can force the 3rd stack discharge on demand |
| `ability_flashstrike` | Nyx | Rewards Nyx's hit-and-fade playstyle |
| `ability_smokecover` | Nyx | Deep defensive identity for the Trickster |
| `ability_grenadebarrage` | Zook | Zook's area-denial identity extended into offensive pressure |
| `ability_slowfield` | Zook | Stacks with Zook's Residue passive for layered slow |
| `ability_trapmine` | Zook | Core Trapper identity consolidation |
| `ability_pindownshot` | Sera | Root + Long Shot passive = high-damage combo at range |
| `ability_ironwall` | Grim | Tank sustain; pairs with Stone Skin passive patience window |
| `ability_thornbarrier` | Grim | Full defensive wall identity for the Tank |
| `ability_rollaway` | Dash | Dash's Afterburn passive activates on Roll Away usage |
| `ability_phasestep` | Dash | Both movement abilities trigger Afterburn; Dash-only double-movement build |
| `ability_healfield` | Fen | Fen's heal identity deepened; pairs with Mend Aura passive |
| `ability_debuffstrike` | Fen | Support control: slow + attack reduction layers |
| `ability_rallycry` | Fen | Fen's team identity; strongest in Squad Brawl |

---

### 3.4 Default Loadouts

Every character ships with a recommended default loadout. Default loadouts are authored in the Content Catalog as part of the character's record and are used in two cases: (a) when a new player selects a character for the first time and has no stored loadout for it, and (b) as the fallback when a stored loadout contains an invalid ability reference (see Edge Cases, Section 5).

Default loadouts are designed to be **immediately understandable**, not optimal. They pair abilities that reinforce the character's archetype in obvious ways. Experienced players are expected to diverge from defaults; new players are expected to start there and learn from them.

| Character | Default Slot 1 | Default Slot 2 | Design Intent |
|---|---|---|---|
| Vex | `ability_burstsurge` | `ability_rollaway` | Aggressive forward pressure + one escape valve; both abilities are affinity matches |
| Dash | `ability_phasestep` | `ability_rollaway` | Double movement; both trigger Afterburn passive; telegraphs Dash's identity clearly |
| Grim | `ability_ironwall` | `ability_thornbarrier` | Maximum defense; pairs with Stone Skin patience passive; both affinity matches |
| Sera | `ability_pindownshot` | `ability_smokecover` | Root for Long Shot combos; Smoke for retreat when enemies close range |
| Zook | `ability_trapmine` | `ability_slowfield` | Full trapper identity; both affinity matches; zone control from day one |
| Fen | `ability_healfield` | `ability_rallycry` | Support-first; both affinity matches; shows the squad-support identity |
| Nyx | `ability_flashstrike` | `ability_smokecover` | Attack and escape; both affinity matches; Trickster loop made visible |
| Colt | `ability_overload` | `ability_disruptpulse` | Combo setup (Overload) + silence for clean discharge; both affinity matches |

---

### 3.5 Ability Unlock Model

At MVP launch, the ability pool uses a **progression-gated unlock model**. Not all 18 abilities are available to all players from day one. This serves two purposes: it controls the cognitive load on new players (they learn the ability space gradually), and it creates progression milestones that the game's retention loop can reward.

**Unlock structure:**

| Unlock Tier | Abilities Included | Unlock Condition | Player State |
|---|---|---|---|
| **Starter (6 abilities)** | One per archetype per character archetype group: `ability_burstsurge`, `ability_rollaway`, `ability_ironwall`, `ability_slowfield`, `ability_pindownshot`, `ability_healfield` | Available to all players from first launch | New player |
| **Tier 1 (6 abilities)** | `ability_overload`, `ability_phasestep`, `ability_thornbarrier`, `ability_grenadebarrage`, `ability_disruptpulse`, `ability_debuffstrike` | 500 lifetime XP | Early engagement |
| **Tier 2 (6 abilities)** | `ability_flashstrike`, `ability_ragepulse`, `ability_smokecover`, `ability_trapmine`, `ability_pullgravity`, `ability_rallycry` | 1,500 lifetime XP | Established player |

**Notes:**
- Unlock thresholds are Tuning Knobs (Section 7) and must not be hardcoded.
- Unlocks are global — an ability unlocked by reaching a threshold is available for use with any character.
- Default loadouts for all characters are constructed exclusively from **Starter tier** abilities, ensuring new players can always have a valid default loadout with zero unlocked abilities.
- The Inventory System tracks which abilities a player has unlocked. The Deck/Loadout System queries Inventory to determine the selectable ability set at loadout edit time.

---

### 3.6 Slot Restriction Rules

The following restrictions define what is and is not permitted when constructing a loadout:

| Rule | Enforced? | Notes |
|---|---|---|
| Slot 1 and Slot 2 are unrestricted by archetype | Yes (no restriction) | Any ability may go in either slot |
| Same ability in both slots | Prohibited | `slot1_ability_id !== slot2_ability_id` enforced at save and at match start |
| Using an unowned/locked ability | Prohibited | Server validates against player's Inventory at save and at match start |
| Using an inactive/disabled ability | Prohibited | Server checks Content Catalog status at match start (see Edge Cases 5.4) |
| Duplicate loadouts across teammates | Allowed | No restriction; two players on the same team may have identical loadouts |
| Using a non-affinity ability | Allowed | Always valid; affinity provides a bonus, not a gate |

---

### 3.7 Loadout Editing

**Where editing is available:**
- Main Menu → Character Roster → Select Character → Edit Loadout
- Lobby (pre-match, before confirming character selection)
- Character Select screen (before tapping "Confirm")

**Where editing is NOT available:**
- During an active match
- After tapping "Confirm" in Character Select (see loadout lock rules below)

**Loadout lock behavior:**
- Once a player taps "Confirm" on the Character Select screen, their loadout is locked for that match.
- The lock is enforced by the Session Manager: after the player sends their `confirm_selection` event (which includes `{ character_id, loadout }` as a payload), the Session Manager records the loadout and marks the player's selection as confirmed.
- A confirmed selection cannot be changed for the duration of the session's `character_select` phase.
- If the lobby countdown reaches zero before the player has confirmed, the server uses the player's last saved loadout for the selected character (or the character's default loadout if no saved loadout exists).

**Editing in the lobby countdown:**
- The loadout editor remains available until the player taps Confirm.
- The lobby countdown does not auto-lock the loadout — the player may continue editing up until they confirm or the countdown forces a confirm (see above).
- This behavior is explicit: the player controls when they are done preparing. Forcing a lock before Confirm would punish deliberation.

**Persistence:**
- Every loadout save is written server-side to the Player Profile immediately.
- The save is not batched or deferred. Network failure at save time is surfaced to the player with an error message; the loadout editor does not close until a successful write confirmation is received.
- The `last_modified` timestamp is updated on every save.

---

### 3.8 Counter-Loadout Preview (Stretch)

This feature is classified as **Stretch** for MVP. It may be implemented post-launch based on player retention and engagement data.

**What it is:**
During the Character Select phase, each player can see which character(s) the opponent(s) have selected. Ability selections are not revealed — only the character choice is visible.

**Why abilities are hidden:**
This is an explicit design decision documented in the Session Manager GDD. Revealing ability selections before match start would reduce the in-match discovery and bluffing dimensions of the game. The character-only reveal creates enough information for counter-selection reasoning without fully eliminating surprise.

**Design intent:**
The partial information reveal (character visible, abilities hidden) creates the "I brought exactly the right counters" fantasy (see Section 2) without enabling full counter-building. A player who sees the opponent picked Colt can reasonably expect crowd control and bring a Defensive escape ability — but they cannot see whether the opponent built aggression (`ability_overload`) or control (`ability_disruptpulse`), so they must still make a judgment call about what to prioritize.

**When this feature is absent (MVP):**
In the base MVP with no counter-preview, players select their loadout without knowledge of the opponent's character. This defaults to meta-game reasoning ("what is commonly played?") rather than in-session counter-play. This is acceptable at launch; the counter-preview feature deepens the strategic layer when added.

---

### 3.9 Loadout Diversity Metric

**Definition:** The percentage of matches, within a rolling 30-day window, where the player used a loadout that differs from the character's **default loadout** in at least one ability slot.

**Target:** > 40% of matches use a non-default loadout within 30 days of launch.

**Measurement:**
- At match start, the Match Server logs the confirmed loadout composition alongside the character's `default_loadout` (read from Content Catalog).
- A match is flagged as "non-default" if `slot1_ability_id !== default.slot1_ability_id OR slot2_ability_id !== default.slot2_ability_id`.
- The Analytics/Telemetry system aggregates this flag into the diversity metric on a per-day rollup.

**Advisory vs. blocking:**
This metric is **advisory**. It does not gate any feature or trigger automatic tuning. It is a health indicator for the strategic layer's engagement. If the metric falls below 40% after 30 days, the live operations team should investigate whether:
1. Default loadouts are too strong and not being improved upon (dominant strategy risk)
2. The ability unlock pacing is too slow and players don't yet have alternatives (progression friction)
3. The loadout editor is not discoverable enough (UI/UX issue)

**Per-character breakdown:**
The diversity metric should also be tracked per-character. A character with < 20% non-default usage may indicate that character's default loadout is a dominant strategy for that character specifically.

---

## 4. Formulas

### 4.1 Affinity Bonus Formula

The affinity bonus is applied to the **primary effect magnitude** of an ability when the using player's character is listed in the ability's `affinity_character_ids`.

```
effect_magnitude_final = effect_magnitude_base * (1.0 + affinity_bonus)

where:
  affinity_bonus = AFFINITY_BONUS_MAGNITUDE   if character_id ∈ ability.affinity_character_ids
                 = 0.0                         otherwise
```

| Variable | Symbol | Type | Value at Launch | Notes |
|---|---|---|---|---|
| Base effect magnitude | `effect_magnitude_base` | float | Per-ability (Content Catalog) | Damage, heal, shield HP, duration, range — defined per-ability |
| Affinity bonus magnitude | `AFFINITY_BONUS_MAGNITUDE` | float | 0.10 | +10% effect; Tuning Knob (Section 7) |
| Final effect magnitude | `effect_magnitude_final` | float | Computed at resolution | Rounded to nearest integer for HP values |

**Example — Burst Surge used by Vex (affinity match):**
```
effect_magnitude_base   = 30 (damage)
affinity_bonus          = 0.10
effect_magnitude_final  = 30 * (1.0 + 0.10) = 30 * 1.10 = 33 damage
```

**Example — Burst Surge used by Sera (no affinity):**
```
effect_magnitude_base   = 30 (damage)
affinity_bonus          = 0.0
effect_magnitude_final  = 30 * (1.0 + 0.0) = 30 damage
```

**Multi-effect abilities:** Some abilities have secondary effects (e.g., Grenade Barrage: 3 grenades × 12 damage each). The affinity bonus applies to the **primary magnitude only**. For Grenade Barrage, the primary magnitude is per-grenade damage (12). If used by Zook: 12 × 1.10 = 13.2 → rounded to 13 per grenade. The count (3 grenades) is not affected.

**Duration and range effects:** For abilities where the primary effect is a duration or range (e.g., Slow Field: 4s duration), the affinity bonus applies to that value: 4s × 1.10 = 4.4s.

---

### 4.2 Ability Cooldown Computation

Ability cooldowns are resolved server-side. The base cooldown is defined in the Content Catalog per-ability. At MVP, there are no cooldown reduction modifiers — the effective cooldown equals the base cooldown.

```
cooldown_effective(ability, character) = cooldown_base(ability)
```

Post-MVP, cooldown reduction modifiers (from status effects, future passive abilities, or game mode rules) will be applied as multipliers to `cooldown_base`. The formula is defined now for forward compatibility:

```
cooldown_effective(ability, character) =
  max(
    cooldown_base(ability) * (1.0 - CDR_sum),
    COOLDOWN_MINIMUM
  )

where:
  CDR_sum        = sum of all active cooldown reduction modifiers (0.0 at MVP; no sources)
  COOLDOWN_MINIMUM = 1.0s   (floor; prevents ability spam regardless of future CDR sources)
```

**Base cooldown table (MVP ability pool):**

| Ability ID | Archetype | Cooldown Base (s) |
|---|---|---|
| `ability_burstsurge` | Offensive | 8 |
| `ability_overload` | Offensive | 10 |
| `ability_flashstrike` | Offensive | 9 |
| `ability_grenadebarrage` | Offensive | 12 |
| `ability_ragepulse` | Offensive | 11 |
| `ability_pindownshot` | Offensive | 13 |
| `ability_ironwall` | Defensive | 10 |
| `ability_rollaway` | Defensive | 7 |
| `ability_smokecover` | Defensive | 14 |
| `ability_healfield` | Defensive | 15 |
| `ability_thornbarrier` | Defensive | 11 |
| `ability_phasestep` | Defensive | 8 |
| `ability_slowfield` | Utility | 12 |
| `ability_disruptpulse` | Utility | 14 |
| `ability_pullgravity` | Utility | 10 |
| `ability_debuffstrike` | Utility | 9 |
| `ability_trapmine` | Utility | 11 |
| `ability_rallycry` | Utility | 13 |

---

### 4.3 Loadout Diversity Score

The loadout diversity score is a fleet-wide health metric computed by the Analytics system. It is not exposed to players.

```
diversity_score(window_days) =
  matches_with_nondefault_loadout(window_days)
  ─────────────────────────────────────────────
  total_matches(window_days)

where:
  A match is "non-default" if any confirmed ability slot differs from the character's
  Content Catalog default loadout for that slot.
```

| Variable | Symbol | Type | Notes |
|---|---|---|---|
| Non-default match count | `M_nd` | integer | Matches where ≥ 1 loadout slot differs from default |
| Total match count | `M_total` | integer | All completed matches in window |
| Window | `window_days` | integer | Rolling days; default 30 |
| Diversity score | `D` | float [0.0, 1.0] | Advisory health target: D > 0.40 |

**Per-character variant:**
```
diversity_score_character(char_id, window_days) =
  matches_with_nondefault_loadout WHERE character_id = char_id
  ───────────────────────────────────────────────────────────
  total_matches WHERE character_id = char_id
```

Per-character advisory threshold: D_char > 0.20 (concern trigger for per-character dominant strategy investigation).

---

## 5. Edge Cases

### 5.1 Player Has No Loadout Configured

**Scenario:** A player selects a character they have never configured a loadout for (e.g., just unlocked a new earnable character, or has never edited the loadout for a character they have played before).

**Handling:**
1. The loadout editor initializes with the character's default loadout (from the Content Catalog `default_loadout` field).
2. The player sees the default loadout pre-filled and may edit it or confirm as-is.
3. If the player confirms without editing, the default loadout is used for the match. A saved loadout record is written to their Player Profile at this point (persisting the default as their explicit selection).
4. No error, no empty slots, no "loadout incomplete" state. The default loadout guarantees the player always has a functional configuration.

**Design note:** Default loadouts are constructed entirely from Starter tier abilities (see Section 3.5). This guarantees the default is always valid for every player regardless of unlock state.

---

### 5.2 Saved Loadout Contains an Ability Removed from the Pool

**Scenario:** A player has a saved loadout with `slot1_ability_id: "ability_burstsurge"`. Between sessions, this ability has been set to `status: "inactive"` in the Content Catalog (e.g., removed from the pool via Remote Config during a balance intervention).

**Handling:**
1. When the loadout editor loads (on character select or main menu), the server validates the saved loadout against the current Content Catalog.
2. If either ability resolves to an inactive or missing record, the affected slot is replaced with the character's default ability for that slot (from the Content Catalog `default_loadout`).
3. The player is notified with a message: "[Ability Name] is no longer available and has been replaced with [Default Ability Name] in your loadout. Review your loadout before confirming."
4. The replacement is not written back to the Player Profile automatically — the player must confirm the loadout (with the replaced ability or a new selection) for the save to occur. This prevents silent permanent overwrites.
5. The match start server validation also checks for inactive abilities. If a player bypasses the client and submits a loadout containing an inactive ability, the Match Server rejects the loadout and applies the default for the affected slot before proceeding (a silent server-side correction; no match cancellation).

---

### 5.3 Player Edits Loadout During Match Lobby Countdown

**Scenario:** The match lobby countdown is running (T minus 10 seconds). The player opens the loadout editor and makes a change.

**Handling:**
- Loadout editing is permitted until the player taps "Confirm" on the Character Select screen.
- The countdown reaching zero triggers an automatic confirm: the server sends a `force_confirm` event, locking the player's current loadout selection.
- If the player is mid-edit when `force_confirm` arrives, the in-progress unsaved edit is discarded; the last saved loadout for the character is used.
- The UI must surface the countdown timer prominently in the loadout editor view so players understand the time pressure.
- This behavior is consistent with the Session Manager GDD's handling of the `character_select_timeout` state.

---

### 5.4 An Ability Is Disabled Mid-Season via Remote Config

**Scenario:** During a live season, an ability (e.g., `ability_disruptpulse`) is identified as causing a balance issue and needs to be disabled immediately. The live ops team sets its Content Catalog status to `inactive` via the Remote Config overlay.

**Handling — In-Progress Matches:**
- Active matches that began before the ability was disabled are not affected. The match runs to completion using the abilities that were confirmed at match start.
- This is consistent with the Character System GDD's precedent for balance overlays: a match runs on the configuration established at initialization.
- The ability's effects during the active match are resolved normally (no mid-match ability disabling).

**Handling — New Matches:**
- After the Content Catalog overlay propagates to the Match Server cache (within `CATALOG_REFRESH_INTERVAL_S` seconds), new match starts will reject loadouts containing the disabled ability (applying the default for that slot, per Edge Case 5.2).
- The loadout editor will no longer display the disabled ability as a selectable option (gray out or hide, per UI implementation).

**Handling — Saved Loadouts:**
- Players with saved loadouts containing the disabled ability will encounter the Edge Case 5.2 flow at their next loadout load.

**Communication:** The live ops team should accompany any mid-season ability disable with a player-facing notification (push notification and/or in-game banner) explaining the temporary change and the expected timeline for re-enablement or removal.

---

### 5.5 Two Players Have Identical Loadouts on the Same Team

**Scenario:** In 3v3 Squad Brawl, two or three teammates all confirm the same character and loadout (e.g., three Vex players all running `ability_burstsurge` + `ability_rollaway`).

**Handling:** This is explicitly **allowed**. There is no restriction on duplicate loadouts within a team. This is a valid, if likely suboptimal, strategic choice (an all-aggression composition is a real composition). The system must not prevent it.

**Implementation note:** The Match Server creates independent `CharacterRuntimeInstance` objects for each player. Duplicate ability slots in multiple instances are completely independent in memory and in cooldown tracking.

---

### 5.6 Inventory Service Unavailable at Loadout Save Time

**Scenario:** A player attempts to save a loadout edit, but the Inventory service (which validates ability ownership) is temporarily unavailable.

**Handling:**
- The save request fails with a server error.
- The client surfaces: "Could not save loadout — please check your connection and try again."
- The loadout editor remains open with the unsaved edit intact so the player can retry.
- The player's previously saved loadout remains unchanged on the server (no partial write occurred).
- If the player is in a lobby countdown and cannot save before `force_confirm`, the last successfully saved loadout is used. The player may lose their in-progress edit for that match.

---

### 5.7 Ability Unlock Threshold Changes Post-Launch

**Scenario:** The live ops team decides to lower Tier 1 unlock from 500 XP to 300 XP to improve new player progression.

**Handling:**
- Unlock thresholds are authored in the Content Catalog and overridable via the Remote Config overlay (they are on the `loadout_item` allow-list for `availability`).
- After the overlay propagates, any player who now meets the new threshold has their Inventory updated to include the newly accessible abilities.
- Players whose loadouts did not use the newly unlocked abilities are unaffected.
- No rollback is needed if the threshold is subsequently raised — players who unlocked abilities under the lower threshold retain those unlocks permanently. Unlock events are one-way.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | What the Deck/Loadout System Reads | When It Is Read | If Unavailable |
|---|---|---|---|
| **Character System** | `character_id`, `passive_ability_id`, `ability_slot_count` (always 2) | At loadout editor open (to display character context); at match start (to confirm character-loadout pairing) | If Character System validation fails for the selected character, the match start is blocked by the Character System's own error handling. Deck/Loadout is not separately responsible for character validation. |
| **Content Catalog** | All active `loadout_item` records (ability pool); `default_loadout` per character; ability `affinity_character_ids` and `cooldown_base` per record | Loadout editor open (builds selectable pool); match start (validates ability status); ability resolution (reads base values) | If Content Catalog is unavailable at match start, the Match Server uses its last cached catalog state. If no cache exists, match start fails. Deck/Loadout falls back to default loadouts when specific ability records are unreachable. |
| **Inventory** | Player's unlocked ability set (which abilities the player can select from the pool) | Loadout editor open (filters selectable pool); loadout save (validates ownership); match start (re-validates ownership server-side) | If Inventory is unavailable at match start, match start is blocked (consistent with Character System GDD Section 6.1). If unavailable at loadout save, save fails with user-visible error (see Edge Case 5.6). |
| **Player Profile** | Stored loadout records per character | Loadout editor open (loads last saved loadout); match start (retrieves confirmed loadout if player did not re-confirm) | If Player Profile is unavailable at match start, the server falls back to the character's default loadout for the affected player. A warning is logged. The match is not cancelled solely due to Profile unavailability. |

### 6.2 Downstream Consumers

| System | What It Reads from Deck/Loadout | How It Uses It |
|---|---|---|
| **Character/Deck Select UI** | Loadout per character (slot1, slot2 ability IDs and display data); default loadouts; ability pool (filtered by player unlock state) | Renders the loadout editor; displays current loadout on character select card; enforces same-ability-twice prevention at the UI layer |
| **Match Server** | Confirmed loadout at match start `{ character_id, slot1_ability_id, slot2_ability_id }` | Creates the `CharacterRuntimeInstance` with ability references; initializes cooldown state; provides ability data to Combat System |
| **Combat System** | Active ability IDs from the runtime instance (sourced from confirmed loadout) | Fires ability logic at trigger time; applies affinity bonus during effect resolution; manages cooldown state |
| **Session Manager** | Confirmed loadout as part of the `confirm_selection` payload | Records the confirmed loadout for the match; locks selection after player confirms; applies `force_confirm` at countdown expiry |
| **Analytics / Telemetry** | Confirmed loadout composition per match; character default loadout (from Content Catalog) | Computes per-match diversity flag; rolls up into 30-day diversity score; per-character diversity breakdown |

---

## 7. Tuning Knobs

All values are data-driven and configurable without a code change. Values marked (*) can be adjusted via Remote Config overlay; others require a Content Catalog update or server config change.

| Knob | Symbol | Current Value | Safe Range | Gameplay Effect |
|---|---|---|---|---|
| **Affinity bonus magnitude** * | `AFFINITY_BONUS_MAGNITUDE` | 0.10 | 0.05–0.25 | Lower: affinity is barely noticeable; higher: affinity creates significant power gaps. Do not exceed 0.25 without testing for dominant strategy formation. |
| **Ability pool size** | `ABILITY_POOL_SIZE` | 18 | 12–36 | Smaller pool = clearer choices, less depth; larger pool = more depth, higher cognitive load on mobile. Changes require UI/catalog work, not just a config change. |
| **Abilities per archetype** | `ABILITIES_PER_ARCHETYPE` | 6 | 4–12 | Must be equal across archetypes to avoid archetype dominance. |
| **Starter tier unlock count** | `STARTER_ABILITY_COUNT` | 6 | 4–8 | Too few: new players feel restricted; too many: removes early progression reward beats. Default loadouts must remain constructable from this tier. |
| **Tier 1 XP threshold** * | `UNLOCK_TIER1_XP` | 500 | 200–1,500 | Controls time-to-first-expanded-pool for new players. |
| **Tier 2 XP threshold** * | `UNLOCK_TIER2_XP` | 1,500 | 800–5,000 | Controls time-to-full-pool. Should be reachable within 2–3 weeks of regular play. |
| **Loadout lock timer** | `LOADOUT_LOCK_TIMEOUT_MS` | Session Manager `SESSION_READY_GRACE_MS` | — | The window after `force_confirm` is determined by the Session Manager GDD's `SESSION_READY_GRACE_MS`. Deck/Loadout does not own this knob independently; defers to Session Manager. |
| **Cooldown minimum** | `COOLDOWN_MINIMUM` | 1.0s | 0.5–3.0s | Hard floor on all ability cooldowns regardless of future CDR modifiers. Prevents ability spam. |
| **Per-ability cooldown base** | `cooldown_base` (per ability) | See Section 4.2 table | ±30% of listed values | Adjust per-ability in Content Catalog. Shorter cooldowns = more ability-driven gameplay; longer = more auto-attack-driven. |
| **Diversity monitoring window** * | `DIVERSITY_WINDOW_DAYS` | 30 | 7–90 | Rolling window for the diversity metric. 7-day window is more sensitive to short-term changes; 90-day smooths out noise. |
| **Diversity advisory threshold** * | `DIVERSITY_ADVISORY_THRESHOLD` | 0.40 | 0.25–0.60 | Value below which the live ops team should investigate strategic layer health. Not a blocking gate. |
| **Per-character diversity concern threshold** * | `DIVERSITY_CHAR_CONCERN_THRESHOLD` | 0.20 | 0.10–0.40 | Per-character diversity below this value triggers investigation of that character's default loadout as a potential dominant strategy. |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and must pass before the Deck/Loadout System is considered ship-ready for MVP.

---

### 8.1 Loadout Schema and Storage

**AC-DECK-001: Loadout is stored per-character in Player Profile**
- Given: A player edits and saves a loadout for Vex
- When: The player closes the app and reopens it, then selects Vex
- Then: The loadout editor displays the previously saved `slot1_ability_id` and `slot2_ability_id` for Vex

**AC-DECK-002: Same ability in both slots is rejected**
- Given: A player attempts to save a loadout with `slot1_ability_id === slot2_ability_id`
- When: The save is submitted (client or server)
- Then: The save is rejected at the UI layer before submission; if bypassed to the server, the server returns a validation error and no save occurs

**AC-DECK-003: Loadout save is rejected for unowned ability**
- Given: A player has not reached the Tier 1 XP threshold (500 XP) and attempts to save a loadout using a Tier 1 ability
- When: The save request reaches the server
- Then: The server rejects the save with an ownership validation error; the player's stored loadout is not changed

**AC-DECK-004: Each character's loadout is independent**
- Given: A player saves a loadout for Vex with `ability_burstsurge` in Slot 1
- When: The player opens the loadout editor for Grim
- Then: Grim's loadout is unchanged and reflects Grim's own saved loadout (or default), not Vex's

---

### 8.2 Default Loadouts

**AC-DECK-005: New character has default loadout pre-populated**
- Given: A player unlocks Fen (an earnable character) for the first time
- When: The player opens the loadout editor for Fen
- Then: Slot 1 shows `ability_healfield` and Slot 2 shows `ability_rallycry` (Fen's defaults)

**AC-DECK-006: Default loadout abilities are always in the Starter unlock tier**
- Given: A player with 0 lifetime XP (no tier unlocks beyond Starter)
- When: The server validates any character's default loadout against the player's unlock state
- Then: All default loadout abilities resolve as owned/unlocked for this player

---

### 8.3 Ability Pool and Unlock

**AC-DECK-007: Starter abilities available at first launch**
- Given: A brand-new player account with 0 lifetime XP
- When: The player opens any character's loadout editor
- Then: The 6 Starter tier abilities are displayed as selectable; Tier 1 and Tier 2 abilities are displayed as locked or hidden

**AC-DECK-008: Tier 1 abilities unlock at threshold**
- Given: A player reaches exactly 500 lifetime XP
- When: The player opens any character's loadout editor
- Then: The 6 Tier 1 abilities are now selectable in addition to the 6 Starter abilities

**AC-DECK-009: Tier 2 abilities unlock at threshold**
- Given: A player reaches exactly 1,500 lifetime XP
- When: The player opens any character's loadout editor
- Then: All 18 abilities (Starter + Tier 1 + Tier 2) are selectable

**AC-DECK-010: Ability pool is read from Content Catalog, not hardcoded**
- Given: A new `loadout_item` record with `status: "active"` and an appropriate unlock tier is added to the Content Catalog
- When: A player who meets the unlock condition opens the loadout editor
- Then: The new ability appears in the selectable pool without a client update

---

### 8.4 Affinity System

**AC-DECK-011: Affinity bonus applied for affinity character**
- Given: Vex uses `ability_burstsurge` (affinity match; base damage 30)
- When: The ability resolves on the Match Server
- Then: The damage dealt is 33 (30 × 1.10, rounded)

**AC-DECK-012: No affinity bonus for non-affinity character**
- Given: Grim uses `ability_burstsurge` (no affinity; base damage 30)
- When: The ability resolves on the Match Server
- Then: The damage dealt is 30 (no multiplier applied)

**AC-DECK-013: Affinity determination is character-based, not player-based**
- Given: Two players both use Vex (identical character)
- When: Both use `ability_burstsurge`
- Then: Both receive the affinity bonus (33 damage each)

---

### 8.5 Loadout Editing and Locking

**AC-DECK-014: Loadout editable from main menu, lobby, and character select**
- Given: A player is on any of the three supported edit surfaces
- When: The player opens the loadout editor
- Then: The editor opens, shows the current saved loadout, and allows modification

**AC-DECK-015: Loadout not editable after Confirm**
- Given: A player has confirmed their character and loadout on the Character Select screen
- When: The player attempts to open the loadout editor
- Then: The editor is disabled; a message indicates "Loadout locked for this match"

**AC-DECK-016: Force-confirm at countdown expiry uses last saved loadout**
- Given: The lobby countdown reaches zero before the player has tapped Confirm
- When: The Session Manager sends a `force_confirm` event
- Then: The Match Server uses the player's last saved loadout for the selected character (or the character's default if no save exists); no match cancellation occurs

**AC-DECK-017: In-progress edit discarded at force-confirm**
- Given: A player is mid-edit in the loadout editor when `force_confirm` arrives
- When: The `force_confirm` event is processed
- Then: The unsaved edit is discarded; the last saved (or default) loadout is used; the player sees a notification that their loadout was auto-confirmed

---

### 8.6 Edge Case Handling

**AC-DECK-018: Inactive ability in saved loadout is replaced at load time**
- Given: A player's saved loadout contains `ability_disruptpulse` which has been set to `status: "inactive"` in the Content Catalog
- When: The player opens the loadout editor for Colt
- Then: The inactive ability slot is replaced with Colt's default ability for that slot; the player sees a notification naming the replaced ability; the replacement is not auto-saved until the player confirms

**AC-DECK-019: Match Server rejects loadout with inactive ability**
- Given: A player submits a loadout containing an inactive ability at match start (bypassing client validation)
- When: The Match Server validates the loadout
- Then: The inactive ability slot is silently replaced with the character's default for that slot; the match proceeds; no match cancellation

**AC-DECK-020: No-loadout player uses default at match start**
- Given: A player has no stored loadout for their selected character and does not edit one before the lobby expires
- When: The match starts
- Then: The character's default loadout is used; the match proceeds normally

---

### 8.7 Diversity Metric (Advisory)

**AC-DECK-021: Diversity metric is computed and logged per match**
- Given: A match completes
- When: The Analytics system processes the match record
- Then: Each player's confirmed loadout is compared to the character's default; a `loadout_is_nondefault` boolean flag is recorded per player per match

**AC-DECK-022: 30-day diversity score is queryable**
- Given: 30 days have elapsed since launch with sufficient match volume
- When: The Analytics dashboard queries the diversity score for the 30-day rolling window
- Then: A value in [0.0, 1.0] is returned; a value > 0.40 indicates the advisory target is met

> **Note:** AC-DECK-022 is an advisory criterion only. Failure to meet the 0.40 target does not block ship — it triggers a design investigation. The investigation workflow is owned by the live operations team.

---

### 8.8 Match Server Integration

**AC-DECK-023: Confirmed loadout transmitted to Match Server at match start**
- Given: A player confirms their character selection with a valid loadout
- When: The Session Manager creates the match and the Match Server initializes the `CharacterRuntimeInstance`
- Then: The runtime instance's ability slots are populated with the confirmed `slot1_ability_id` and `slot2_ability_id`; cooldowns are initialized to 0 (ready to use)

**AC-DECK-024: Duplicate team loadouts create independent runtime instances**
- Given: Two players on the same 3v3 team confirm identical loadouts (same character and same two abilities)
- When: The Match Server creates their runtime instances
- Then: Two separate instances exist in server memory with independent cooldown state; activating an ability for one player does not affect the other's cooldown

---

*End of Deck / Loadout System GDD — Version 1.0 Draft*
