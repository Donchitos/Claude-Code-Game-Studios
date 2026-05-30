# Character System — Game Design Document
> **System**: Character System
> **Priority**: MVP
> **Layer**: Core Data
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

### What This System Owns

The Character System is the single source of truth for everything that defines a character in BRAWLZONE. It owns two distinct concerns that must never be conflated:

**Static Character Definitions** — the immutable, data-driven record of what a character is. This includes identity (id, name, lore), unlock type, base stat values, ability slot configuration, passive ability reference, and visual asset identifiers. Static definitions are authored in the Content Catalog and are never hardcoded in game logic. The Character System reads them, validates them, and exposes them to all downstream consumers.

**Runtime Character Instances** — the ephemeral, server-side representation of a character during an active match. A runtime instance is created from a static definition at match start, then mutated by the Combat System as the match progresses. It holds current HP, active status effects, ability cooldowns, and positional state. Runtime instances are owned and authoritative on the Match Server; they are destroyed when the match ends and are never persisted.

### Balance-by-Design Principle

All 8 MVP characters share identical base stat values. Mechanical differentiation is achieved entirely through ability design — the passive ability baked into the character definition and the two active ability slots populated by the Deck/Loadout System. This means that at any given point in a match, two characters with no abilities would be perfectly interchangeable. Premium characters are cosmetically distinct (unique 3D model, particle effects, sound skin) but carry the same stat profile as earnable characters. This is a hard design constraint: the Character System enforces it, and no downstream system may apply permanent stat offsets based on character identity alone. Only the balance overlay mechanism (see below) may adjust per-character stats, and that mechanism exists for live tuning, not for introducing pay-to-win advantages.

### Remote Config Balance Overlays

The balance overlay system allows the live operations team to push per-character stat multipliers without a client update. Overlays are delivered via Remote Config as a JSON payload keyed by character ID and stat name. The Match Server reads the current overlay at match initialization and applies multipliers to base stats once, producing effective stats for the match. Overlays are not re-applied mid-match; a match runs to completion on the stats established at its start. This prevents mid-match stat shifts that would be unfair to players already in a session.

Overlay delivery format:

```json
{
  "characterBalanceOverlays": {
    "character:vex": {
      "move_speed": 0.95,
      "attack_damage": 1.05
    },
    "character:grim": {
      "attack_speed": 0.90
    }
  }
}
```

If no overlay exists for a character, all multipliers default to `1.0` (identity). Multipliers are bounded by the system to `[0.5, 1.5]` — any value outside this range is clamped and a server-side warning is logged (see Edge Cases, Section 5).

---

## 2. Player Fantasy

### Character Identity

A character in BRAWLZONE is a persona — a visual and mechanical promise to the player. When a player picks a character, they are choosing a playstyle, an aesthetic identity, and a set of strategic affordances. The character's passive ability is intrinsic to that identity and is always active; it defines the character's "floor" behavior. The two active ability slots are where the player expresses their own strategic voice on top of the character's identity. The feeling this creates is: "This character is who I am; my ability choices are how I play."

### The Unlock Journey

Free characters (3) are immediately accessible to every player at first launch. They are designed to represent approachable archetypes — easy to understand, with passives that telegraph their playstyle clearly. The goal is to give new players traction from minute one.

Earnable characters (3) are unlocked by spending Coins in the Shop, or by reaching Battle Pass free-track reward tiers. Each Coin cost is designed to feel earned but not prohibitive — a player who plays consistently for one to two weeks should be able to afford all three. The discovery moment of purchasing or earning a new character ("You've unlocked Grim!") is a designed reward beat that the UI should celebrate.

Premium characters (2) are aspirational. They are purchased via the Diamond IAP currency. Their mechanical parity with earnable characters is communicated explicitly at the point of purchase: the player is buying a look and a vibe, not an edge. The premium character roster is the cosmetic expression of BRAWLZONE's art direction at its highest fidelity.

### Ability Composition Preview

The Character System surfaces `passive_ability_id` and `ability_slot_count` to the Deck/Loadout System. During character selection, players see the passive ability description and two empty ability slots, creating a mental model of "this character + my deck" before they commit. This preview creates the strategic satisfaction of composition — the character is the chassis, and the deck is the build.

---

## 3. Detailed Rules

### 3.1 Character Data Schema

Every character in the Content Catalog conforms to the following schema. All fields are required unless marked optional.

```typescript
interface CharacterDefinition {
  // Identity
  id: string;                    // Unique stable identifier, e.g. "character:vex". Never changes post-ship.
  name: string;                  // Display name, e.g. "Vex". May be localized.
  lore_tagline: string;          // One-line flavor text shown on character select. Max 80 chars.

  // Unlock
  unlock_type: "free" | "earnable" | "premium";
  unlock_cost_coins?: number;  // Required when unlock_type === "earnable". Coin price for Shop purchase. Absent otherwise.
  unlock_cost_diamonds?: number; // Required when unlock_type === "premium". Diamond price for IAP purchase. Absent otherwise.

  // Stats — all numeric values; must be positive non-zero floats
  base_stats: {
    max_hp: number;              // Maximum hit points
    move_speed: number;          // Units per second
    attack_damage: number;       // Damage per hit before ability modifiers
    attack_range: number;        // Default attack reach in world units; overridden per-ability for ranged characters (see Section 3.3 note)
    attack_speed: number;        // Attacks per second
  };

  // Abilities
  passive_ability_id: string;    // References an ability record in Content Catalog
  ability_slot_count: 2;         // Fixed at 2 for all MVP characters. Typed as literal for enforcement.

  // Visuals
  visual_asset_ids: {
    model_id: string;            // 3D model asset reference
    portrait_id: string;         // 2D portrait for character select UI
    thumbnail_id: string;        // Small icon for HUD / roster lists
    vfx_hit_id: string;          // Hit effect particle system reference
    sfx_skin_id: string;         // Sound skin bundle reference
  };
}

```

**Schema validation rules enforced by the Character System at startup:**
- `id` must be globally unique across all character definitions.
- `base_stats` values must all be `> 0`.
- `passive_ability_id` must resolve to an existing ability record in the Content Catalog. If it does not, the character fails validation and is excluded from the available roster (logged as a critical server error).
- `ability_slot_count` is always `2`; any other value is a validation error.
- `unlock_cost_coins` must be present if and only if `unlock_type === "earnable"`.
- `unlock_cost_diamonds` must be present if and only if `unlock_type === "premium"`.

---

### 3.2 The 8 MVP Characters

All characters share identical base stats (see Section 3.3). The table below defines identity and playstyle differentiation through passive ability concepts.

| # | ID | Name | Unlock Type | Archetype | Passive Ability Concept |
|---|---|---|---|---|---|
| 1 | `character:vex` | Vex | Free | Brawler (offensive) | "Momentum" — Every 3rd consecutive melee hit deals 25% bonus damage and knocks the target back slightly. |
| 2 | `character:zook` | Zook | Free | Sniper (offensive) | "Residue" — When Zook places a trap or area-denial ability, the affected tiles leave a slowing residue for 2 seconds after the primary effect ends. |
| 3 | `character:sera` | Sera | Free | Support (defensive) | "Long Shot" — Attacks that hit a target more than 6 units away deal 15% bonus damage; attacks closer than 3 units deal 15% less damage. |
| 4 | `character:fen` | Fen | Earnable (800 Coins) | Trickster (utility) | "Mend Aura" — Fen passively restores 1 HP per second to the nearest ally within 5 units (in 3v3 Squad Brawl); in 1v1 and FFA modes, the heal applies to Fen's own lowest-HP threshold band. |
| 5 | `character:grim` | Grim | Earnable (600 Coins) | Tank (defensive) | "Stone Skin" — Incoming damage is reduced by a flat 2 points while Grim has not used any active abilities in the last 3 seconds (a "patience" reward for deliberate play). |
| 6 | `character:dash` | Dash | Earnable (1,200 Coins) | Speedster (offensive) | "Afterburn" — After dashing or using a movement ability, Dash's move speed increases by 20% for 1.5 seconds. |
| 7 | `character:colt` | Colt | Premium (500 Diamonds) | Trapper (utility) | "Static Field" — Colt's attacks apply a "charged" stack (max 3) to targets; the 3rd stack discharges, briefly rooting the target for 0.6 seconds and clearing all stacks. |
| 8 | `character:nyx` | Nyx | Premium (500 Diamonds) | Controller (utility) | "Opener" — On taking damage that would reduce HP below 40% for the first time per match, Nyx briefly flickers (0.4s invulnerability frame and visual decoy on-screen), causing the next auto-attack against Nyx to miss. |

**Lore Taglines (for character select display):**

| Name | Lore Tagline |
|---|---|
| Vex | "Hit first. Hit harder. Hit again." |
| Dash | "Standing still is just another way to lose." |
| Grim | "They haven't made a hit that slows me down yet." |
| Sera | "Precision is patience with a purpose." |
| Zook | "Don't step there. Don't step there either." |
| Fen | "Everyone makes it out. That's the deal." |
| Nyx | "You saw me? Sure you did." |
| Colt | "One. Two. Three. Goodnight." |

---

### 3.3 Base Stat Table

All 8 characters share the following base stats. These values are authored in the Content Catalog and read by the Character System at startup. They are never hardcoded.

| Stat | Value | Unit | Notes |
|---|---|---|---|
| `max_hp` | 100 | HP | All characters start at full HP each match |
| `move_speed` | 5.0 | units/sec | Normalized to arena scale |
| `attack_damage` | 10 | HP | Per hit, before ability modifiers |
| `attack_range` | 2.5 | units | Default reach for auto-attacks. **Note: effective attack range is determined by the equipped ability, not by character identity.** Melee abilities (e.g., close-range brawlers like Vex, Grim) use the base value; ranged/projectile abilities override this with their own range stat. Characters with no ability equipped fall back to this value. |
| `attack_speed` | 1.2 | attacks/sec | ~0.83 second attack interval |

**Design note:** Differentiation is entirely through passive ability effects and active ability loadouts. A character without abilities equipped is mechanically identical to every other character. The Content Catalog enforces this by using a single base stats record that is referenced by all 8 character definitions (the `base_stats` object may be stored as a shared constant in the catalog with each character referencing it, or as a duplicated record — either is valid; the Character System validates that all values match the canonical set at startup and emits a warning if drift is detected).

---

### 3.4 Balance Overlay Specification

**Purpose:** Allow live operations to adjust per-character effective stats post-ship without a client update, for balance tuning only (not for introducing asymmetry between characters of the same tier).

**Delivery mechanism:** Remote Config (Firebase Remote Config or equivalent). The key `characterBalanceOverlays` holds a JSON object.

**Full overlay payload schema:**

```json
{
  "characterBalanceOverlays": {
    "<characterId>": {
      "max_hp":        "<float multiplier, default 1.0>",
      "move_speed":    "<float multiplier, default 1.0>",
      "attack_damage": "<float multiplier, default 1.0>",
      "attack_range":  "<float multiplier, default 1.0>",
      "attack_speed":  "<float multiplier, default 1.0>"
    }
  }
}
```

Only stats that need adjustment need be present; omitted stats default to `1.0`.

**Server application process (at match initialization, once per match):**

1. Match Server fetches current `characterBalanceOverlays` from the Remote Config cache (the cache is refreshed server-side on a configurable interval; see Tuning Knobs).
2. For each character selected in the match, the server resolves effective stats:
   ```
   effective_stat = base_stat * overlay_multiplier (clamped to [0.5, 1.5])
   ```
3. Effective stats are written into the runtime character instance (see Section 3.6). The base stat record is not mutated.
4. The overlay is not re-fetched or re-applied during the match. The match runs to completion on the effective stats established at initialization.
5. All overlay applications are logged server-side with: `matchId`, `characterId`, `stat`, `base_value`, `multiplier`, `effective_value`.

**Constraint:** Overlays may only adjust stats within the multiplier bounds defined in Tuning Knobs (Section 7). The Character System clamps out-of-bounds values and logs a warning; it does not reject the overlay entirely, to avoid cascading failures if a misconfiguration is pushed.

---

### 3.5 Character Availability Rules

Character availability is computed by the Character System from three inputs: the character's `unlock_type`, the player's inventory/entitlement record (from the Inventory System), and the unlock threshold definitions.

**Free Characters (3 — Vex, Zook, Sera)**
- Always available to all players.
- No ownership record required in Inventory.
- Availability check: `unlock_type === "free"` → always return `true`.

**Earnable Characters (3 — Fen, Grim, Dash)**

Purchasable with Coins via the Shop. Coin prices (defined in Content Catalog, not hardcoded):

| Character | Coin Cost | Also Earnable Via | Design Intent |
|---|---|---|---|
| Grim | 600 Coins | Battle Pass free-track Tier 15 | Lowest barrier; accessible within ~1 week of casual play |
| Fen | 800 Coins | Battle Pass free-track Tier 6 | Mid-barrier; ~1–2 weeks of casual play |
| Dash | 1,200 Coins | Battle Pass free-track Tier 24 | Highest barrier; final earnable unlock; ~2–3 weeks of engaged play |

Availability check:
1. Check the player's Inventory for a `{ entitlement_type: "earnable_character", character_id: string, active: boolean }` record granted by Shop purchase or Battle Pass reward.
2. If the entitlement record exists and `active === true`, character is available.
3. Once unlocked, earnable characters are permanently available.

**Premium Characters (2 — Colt, Nyx)**
- Require a Diamond IAP entitlement in the player's Inventory. Colt costs 500 Diamonds; Nyx costs 500 Diamonds.
- Inventory holds a record of type `{ entitlement_type: "premium_character", character_id: string, active: boolean }`.
- Availability check: entitlement record exists for character ID **and** `active === true`.
- If `active === false` (e.g., refund or reversal), character is not available (see Edge Cases, Section 5.1).

**Availability check is always server-validated.** The client may cache availability state for UX purposes (to avoid per-tap latency), but the canonical check occurs server-side at match start (see Section 3.7).

---

### 3.6 Runtime Character Instance Schema

A runtime instance is created by the Match Server at match initialization from a character's static definition and effective stats. It exists only in server memory for the duration of the match.

```typescript
interface CharacterRuntimeInstance {
  // Identity (copied from static definition at match creation)
  character_id: string;
  player_id: string;
  team_id: string | null;          // null in FFA

  // Effective stats (base_stat * overlay_multiplier, computed once at match start)
  effective_stats: {
    max_hp: number;
    move_speed: number;
    attack_damage: number;
    attack_range: number;
    attack_speed: number;
  };

  // Mutable match state — mutated by Combat System
  current_hp: number;              // Initialized to effective_stats.max_hp
  is_alive: boolean;               // false when current_hp reaches 0

  // Status effects — applied and removed by Combat/Ability Systems
  active_status_effects: StatusEffect[];

  // Ability cooldowns — keyed by ability_id
  ability_cooldowns: Record<string, number>; // value = server timestamp (ms) when ability becomes available

  // Positional state — updated by Movement System at 20Hz
  position: {
    x: number;
    y: number;
  };
  facing_angle: number;            // Radians, for directional passive/ability resolution

  // Passive ability tracking — used by passive ability logic
  passive_state: Record<string, unknown>; // Typed per-passive (e.g., Vex: { consecutive_hits: number })
}

interface StatusEffect {
  effect_id: string;
  source_player_id: string;
  applied_at: number;              // Server timestamp (ms)
  expires_at: number;              // Server timestamp (ms); -1 = permanent until cleared
  stat_modifiers?: Partial<Record<keyof EffectiveStats, number>>; // Additive modifiers during effect
}
```

**Ownership boundary:** The `CharacterRuntimeInstance` type is defined here in the Character System GDD because it originates from character data, but its mutation authority belongs to the Match Server (Combat System, Ability System, Movement System). The Character System provides the initialization logic; all mid-match mutations are the Combat System's responsibility.

---

### 3.7 Character Selection Validation

Client-side character selection is treated as untrusted input. The Match Server performs a full re-validation of character ownership at match start, before the `CharacterRuntimeInstance` is created.

**Validation sequence (server-side, per selected character per player):**

1. Receive `{ player_id, character_id }` from the match lobby service.
2. Fetch character definition from Content Catalog. If not found → reject match start for this player, return error `CHAR_DEFINITION_NOT_FOUND`.
3. Check `unlock_type`:
   - `"free"` → pass.
   - `"earnable"` → fetch entitlement from Inventory; verify `{ entitlement_type: "earnable_character", character_id, active: true }` exists → if not, return `CHAR_NOT_UNLOCKED`.
   - `"premium"` → fetch entitlement from Inventory; verify `active === true` for this character_id → if not, return `CHAR_ENTITLEMENT_INVALID`.
4. If validation passes, proceed to create `CharacterRuntimeInstance`.
5. All validation outcomes are logged with `player_id`, `character_id`, `outcome`, and `timestamp`.

**Validation failure handling:** If a player's character fails validation at match start, the match is cancelled for all participants and players are returned to the lobby. An error is surfaced to the affected player. This is preferable to starting an unbalanced match.

---

## 4. Formulas

### 4.1 Effective Stat After Balance Overlay

```
effective_stat(character, stat) =
  clamp(
    base_stats[stat] * overlay_multiplier(character, stat),
    base_stats[stat] * OVERLAY_MIN,   // floor: 0.5 * base
    base_stats[stat] * OVERLAY_MAX    // ceiling: 1.5 * base
  )

overlay_multiplier(character, stat) =
  characterBalanceOverlays[character.id]?.[stat] ?? 1.0
```

Where `OVERLAY_MIN = 0.5` and `OVERLAY_MAX = 1.5` (see Tuning Knobs, Section 7).

**Example:**

Vex receives an overlay of `{ "attack_damage": 1.10 }`:
```
effective_attack_damage = clamp(10 * 1.10, 10 * 0.5, 10 * 1.5)
                        = clamp(11.0, 5.0, 15.0)
                        = 11.0
```

If a misconfigured overlay pushes `{ "attack_damage": 2.0 }`:
```
effective_attack_damage = clamp(10 * 2.0, 5.0, 15.0)
                        = clamp(20.0, 5.0, 15.0)
                        = 15.0   (clamped, warning logged)
```

---

### 4.2 Earnable Character Coin Costs

Earnable characters are purchased with Coins via the Shop. Coin costs are defined in the Content Catalog and read by the Shop system at runtime; they are not hardcoded. The costs are tiered to create a perceived progression: the cheapest earnable character is accessible to a player who has accumulated modest Coin wealth, while the most expensive requires meaningful engagement.

```
coin_cost(character) = Content Catalog record field: character.unlock_cost_coins
```

| Character | Canonical ID | Coin Cost | Relative Accessibility |
|---|---|---|---|
| Grim | `character:grim` | 600 | Lowest barrier — first earnable most players will unlock |
| Fen | `character:fen` | 800 | Mid-tier — ~33% more expensive than Grim |
| Dash | `character:dash` | 1,200 | Highest barrier — ~100% more expensive than Grim; final earnable |

Earnable characters are also grantable as Battle Pass free-track rewards (Tiers 6, 15, and 24), providing a parallel path for players who prefer engagement-based progression over direct Coin purchase.

---

### 4.3 HP Percentage Thresholds for Visual Feedback

Visual feedback states are derived from `current_hp / effective_stats.max_hp`:

| HP % Range | State Name | Visual Signal | Audio Signal |
|---|---|---|---|
| 100% | `full` | No indicator | None |
| 60–99% | `healthy` | Green HP bar | None |
| 30–59% | `injured` | Yellow HP bar; slight character limp/tilt anim | Low-health ambient sound begins |
| 10–29% | `critical` | Red HP bar; screen vignette pulse | Heartbeat SFX loop |
| 1–9% | `near_death` | Red bar + flashing; character visual desperation | Urgent heartbeat SFX; screen desaturation |
| 0% | `eliminated` | Elimination VFX | Elimination SFX |

```
hp_state(current_hp, max_hp):
  ratio = current_hp / max_hp
  if ratio == 0:     return "eliminated"
  if ratio < 0.10:   return "near_death"
  if ratio < 0.30:   return "critical"
  if ratio < 0.60:   return "injured"
  if ratio < 1.00:   return "healthy"
  return "full"
```

These thresholds are Tuning Knobs (Section 7) and must not be hardcoded.

---

## 5. Edge Cases

### 5.1 Premium Entitlement Lapses Between Selection and Match Start

**Scenario:** A player selects a premium character (Colt or Nyx) in the lobby. Before the match starts, their Diamond IAP is refunded or their entitlement is revoked (e.g., fraud reversal by the payment provider).

**Handling:**
- The server re-validates entitlements at match start (Section 3.7). It will detect `active === false` for the character.
- The match is cancelled. The player is returned to the lobby with error `CHAR_ENTITLEMENT_INVALID`.
- The client displays a message: "Your access to [Character Name] is no longer active. Please select another character."
- Other players in the lobby are notified that the match has been cancelled and are returned to queue.
- The IAP/Inventory System is responsible for the entitlement reversal; the Character System only reads the entitlement state.

**Prevention:** The client should poll or subscribe to entitlement state changes and proactively de-select characters that become unavailable during lobby wait.

---

### 5.2 Remote Config Pushes a 0.0 Multiplier for a Stat

**Scenario:** A misconfiguration in Remote Config sets `{ "character:grim": { "move_speed": 0.0 } }`, which would result in an immobile character.

**Handling:**
- The clamp formula (Section 4.1) catches this: `clamp(5.0 * 0.0, 2.5, 7.5) = 2.5`.
- `move_speed` is floored at `OVERLAY_MIN * base_stat = 0.5 * 5.0 = 2.5`.
- A server-side warning is logged: `OVERLAY_CLAMP_WARNING: character:grim.move_speed overlay 0.0 clamped to 0.5 (floor)`.
- The match proceeds with the clamped value.
- The live ops team is alerted via the server monitoring dashboard; they can push a corrected overlay without a deployment.

**A 0.0 multiplier is never allowed to reach the runtime instance.** The clamp is enforced before the `CharacterRuntimeInstance` is created.

---

### 5.3 Two Players on the Same Team Select the Same Character

**Scenario:** In 3v3 Squad Brawl, two teammates both select Vex.

**Decision: ALLOWED.** Duplicate character selection within a team or across the match is permitted. The game does not enforce unique character selection. Two Vex players on the same team creates a valid "double brawler" composition and is a legitimate strategic choice.

**Implementation note:** The Character System makes no uniqueness check on character selection. The Matchmaking and Lobby systems do not enforce uniqueness either. Each player's `CharacterRuntimeInstance` is independently initialized from the same static definition but is a separate object in server memory.

**Visual disambiguation:** When two players in the same match use the same character, the HUD and in-world nameplate must display player name (not character name) as the primary identifier. The Character/UI system is responsible for this disambiguation rule; the Character System communicates it via the `player_id` field on `CharacterRuntimeInstance`.

---

### 5.4 Character Data Missing from Content Catalog

**Scenario:** A character ID exists in a player's unlock record (Inventory) but the corresponding definition is absent from the Content Catalog (e.g., a catalog deployment failure or data corruption).

**Handling:**
- At server startup, the Character System performs a full validation pass on all character definitions in the Content Catalog.
- Any character whose definition fails validation (missing, malformed, broken `passive_ability_id` reference) is excluded from the available roster and logged as a critical error: `CHAR_VALIDATION_FAILED: char_id=[id] reason=[reason]`.
- If a player attempts to select a character that failed validation, the server returns `CHAR_DEFINITION_NOT_FOUND` (Section 3.7).
- The player is not penalized for owning a broken character; their unlock record is preserved.
- A server alert is triggered for the engineering team. The catalog must be repaired and the server's character cache refreshed (via a cache invalidation endpoint, no restart required for this case).

---

### 5.5 Balance Overlay References a Non-Existent Character ID

**Scenario:** Remote Config contains `{ "characterBalanceOverlays": { "character:oldcharacter": { "attack_damage": 1.2 } } }` where `character:oldcharacter` does not exist in the current Content Catalog.

**Handling:**
- The server logs a warning: `OVERLAY_UNKNOWN_CHARACTER: character:oldcharacter not found in roster — overlay ignored`.
- The overlay entry is silently dropped; it does not cause a server error or affect any existing character.
- This is a no-op from the game's perspective. Live ops should be alerted to clean up stale overlay entries, but the system continues operating normally.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (what Character System reads)

| System | What Is Read | When Read | If Unavailable |
|---|---|---|---|
| **Content Catalog** | All `CharacterDefinition` records; base stats canonical constant; passive ability references | Server startup (full load); per-match (character definition lookup) | Server fails to start if catalog is unreachable at startup. Mid-match: uses in-memory cache; logs error if cache is stale beyond configurable TTL. |
| **Inventory** | Earnable character entitlements `{ entitlement_type: "earnable_character", character_id, active }` (for earnable availability check); premium character entitlements (for premium availability check) | Per character availability check (lobby); per match start (server-side re-validation) | If Inventory is unreachable at match start validation, match start is blocked and players are returned to lobby with `INVENTORY_SERVICE_UNAVAILABLE`. Free characters bypass this dependency. |
| **Remote Config** | `characterBalanceOverlays` JSON payload | Server-side cache refresh on configurable interval; read at match initialization | If Remote Config is unreachable, all overlays default to `1.0` (no adjustment). A warning is logged. Matches proceed normally with base stats. |

### 6.2 Downstream Consumers (what reads from Character System)

| System | What It Reads | How It Uses It |
|---|---|---|
| **Deck / Loadout System** | `passive_ability_id`, `ability_slot_count`, character ID | Builds the ability loadout for a character; enforces slot count; displays passive in loadout UI |
| **Ability / Skill System** | `passive_ability_id`, `passive_state` from runtime instance | Evaluates passive ability triggers and effects during combat |
| **Combat System** | `CharacterRuntimeInstance` (all fields) | Reads and mutates `current_hp`, `active_status_effects`, `ability_cooldowns`; applies effective stats |
| **Character / Deck Select UI** | `CharacterDefinition` (full); availability result per player | Renders character roster; locks unavailable characters; shows passive preview; shows unlock progress |
| **Matchmaking** | Character availability per player | Validates selected characters are available before placing players in a match |
| **Match Server** | `CharacterDefinition`, effective stats (post-overlay), runtime instance initialization | Creates and manages `CharacterRuntimeInstance` for all players in a match |
| **Movement System** | `effective_stats.move_speed`, `position`, `facing_angle` from runtime instance | Applies movement physics; updates position at 20Hz |
| **Analytics / Telemetry** | Character ID, unlock type, match outcomes per character | Win rate per character tracking; balance health monitoring; funnel analysis for earnable unlocks |

---

## 7. Tuning Knobs

All values in this section are data-driven and configurable without a code change. Starred values (*) can be adjusted via Remote Config; unstarred values require a Content Catalog or server config update.

| Knob | Current Value | Range / Constraints | Notes |
|---|---|---|---|
| `base_stats.max_hp` | 100 | 50–200 | Affects all characters equally |
| `base_stats.move_speed` | 5.0 units/sec | 3.0–8.0 | Affects arena feel significantly; test with arena size |
| `base_stats.attack_damage` | 10 | 5–20 | Interacts with TTK (time-to-kill); see Combat System GDD |
| `base_stats.attack_range` | 2.5 units | 1.5–5.0 | Default fallback reach; effective range is determined by the equipped ability, not character identity |
| `base_stats.attack_speed` | 1.2 attacks/sec | 0.5–3.0 | Lower = heavier hits; higher = rapid fire |
| `earnable_coin_cost_grim` | 600 Coins | 200–2,000 | Lowest earnable barrier; adjust based on Coin earn rate |
| `earnable_coin_cost_fen` | 800 Coins | 200–2,500 | Mid-tier earnable; ~33% more than Grim |
| `earnable_coin_cost_dash` | 1,200 Coins | 500–3,000 | Highest earnable barrier; final earnable unlock |
| `OVERLAY_MIN` * | 0.5 | 0.1–0.9 | Floor multiplier for balance overlays; prevents stat deletion |
| `OVERLAY_MAX` * | 1.5 | 1.1–2.0 | Ceiling multiplier; prevents pay-to-win-style creep |
| `remote_config_cache_ttl` | 300 seconds | 60–3600 | How often Match Server refreshes overlay cache |
| `hp_threshold_injured` | 0.60 | 0.40–0.80 | HP % where injured visual begins |
| `hp_threshold_critical` | 0.30 | 0.15–0.50 | HP % where critical visual begins |
| `hp_threshold_near_death` | 0.10 | 0.05–0.20 | HP % where near_death visual begins |
| `ability_slot_count` | 2 | 1–3 (post-MVP) | Fixed at 2 for MVP; 3 slots is a post-MVP expansion |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then and must pass before the Character System is considered ship-ready for MVP.

---

### 8.1 Static Character Definitions

**AC-CHAR-001: All 8 characters load at startup**
- Given: The Content Catalog contains valid definitions for all 8 MVP characters
- When: The Match Server starts up
- Then: All 8 characters pass validation, are added to the available roster, and a startup log entry confirms `ROSTER_LOADED: 8 characters validated`

**AC-CHAR-002: Invalid character definition is excluded from roster**
- Given: A character definition in the Content Catalog has a `passive_ability_id` that does not resolve to any ability record
- When: The Match Server starts up
- Then: That character is excluded from the roster, a `CHAR_VALIDATION_FAILED` error is logged with the character ID and reason, and remaining valid characters are loaded normally

**AC-CHAR-003: Character schema enforces ability_slot_count = 2**
- Given: A character definition has `ability_slot_count: 3` in the Content Catalog
- When: The Character System validates the definition at startup
- Then: Validation fails for that character, it is excluded from the roster, and the error is logged

---

### 8.2 Character Availability

**AC-AVAIL-001: Free characters are available to all players**
- Given: A new player account with zero XP and zero wins
- When: The Character System evaluates availability for Vex, Zook, and Sera
- Then: All three return `available: true`

**AC-AVAIL-002: Earnable character locked without Coin purchase**
- Given: A player has no Inventory entitlement record for Grim (600 Coins, unpurchased)
- When: Availability is checked for Grim
- Then: Returns `available: false`

**AC-AVAIL-003: Earnable character available after Coin purchase**
- Given: A player has purchased Grim via the Shop and holds an Inventory record `{ entitlement_type: "earnable_character", character_id: "character:grim", active: true }`
- When: Availability is checked for Grim
- Then: Returns `available: true`

**AC-AVAIL-004: Multiple earnable characters available independently**
- Given: A player holds active entitlement records for both Fen and Grim but not Dash
- When: Availability is checked for Fen, Grim, and Dash
- Then: Fen and Grim return `available: true`; Dash returns `available: false`

**AC-AVAIL-005: Premium character available with active entitlement**
- Given: A player has an Inventory record `{ entitlement_type: "premium_character", character_id: "character:nyx", active: true }`
- When: Availability is checked for Nyx
- Then: Returns `available: true`

**AC-AVAIL-006: Premium character unavailable with inactive entitlement**
- Given: A player has an Inventory record `{ character_id: "character:nyx", active: false }`
- When: Availability is checked for Nyx
- Then: Returns `available: false`

**AC-AVAIL-007: Premium character unavailable with no entitlement record**
- Given: A player has no Inventory record for Nyx
- When: Availability is checked for Nyx
- Then: Returns `available: false`

---

### 8.3 Balance Overlays

**AC-OVERLAY-001: Overlay multiplier applied correctly at match start**
- Given: Remote Config has `{ "character:vex": { "attack_damage": 1.10 } }` and Vex's base `attack_damage = 10`
- When: A match is initialized with Vex selected
- Then: Vex's `CharacterRuntimeInstance.effective_stats.attack_damage = 11.0`

**AC-OVERLAY-002: Missing overlay defaults to 1.0**
- Given: Remote Config has no overlay entry for Grim
- When: A match is initialized with Grim selected
- Then: All of Grim's `effective_stats` equal the base stat values exactly

**AC-OVERLAY-003: Overlay clamped at maximum**
- Given: Remote Config has `{ "character:dash": { "move_speed": 2.0 } }` (exceeds OVERLAY_MAX of 1.5)
- When: A match is initialized with Dash selected
- Then: `effective_stats.move_speed = 7.5` (base 5.0 * 1.5 ceiling), a `OVERLAY_CLAMP_WARNING` is logged

**AC-OVERLAY-004: Overlay clamped at minimum (floor enforcement)**
- Given: Remote Config has `{ "character:colt": { "attack_damage": 0.0 } }`
- When: A match is initialized with Colt selected
- Then: `effective_stats.attack_damage = 5.0` (base 10 * 0.5 floor), a `OVERLAY_CLAMP_WARNING` is logged

**AC-OVERLAY-005: Overlay for unknown character is ignored**
- Given: Remote Config has `{ "character:ghost": { "max_hp": 1.2 } }` and `character:ghost` does not exist in the roster
- When: The Match Server processes the overlay at match initialization
- Then: The unknown entry is silently dropped, `OVERLAY_UNKNOWN_CHARACTER` warning is logged, and no existing character is affected

**AC-OVERLAY-006: Overlays are not re-applied mid-match**
- Given: A match is in progress with Vex having `effective_attack_damage = 11.0`
- When: Remote Config is updated to change Vex's `attack_damage` overlay to `0.9`
- Then: Vex's `effective_attack_damage` remains `11.0` for the duration of the current match; the new overlay takes effect only in subsequently initialized matches

---

### 8.4 Server-Side Selection Validation

**AC-VALIDATE-001: Server rejects unowned earnable character**
- Given: A player with no Inventory entitlement for Dash (1,200 Coins, unpurchased) attempts to select Dash at match start
- When: The Match Server performs character ownership validation
- Then: Validation returns `CHAR_NOT_UNLOCKED`, the match is cancelled, the player is returned to lobby, and other lobby participants are notified

**AC-VALIDATE-002: Server rejects premium character with lapsed entitlement**
- Given: A player selected Nyx in the lobby, but their entitlement is revoked before match start (`active: false`)
- When: The Match Server performs character ownership validation
- Then: Validation returns `CHAR_ENTITLEMENT_INVALID`, the match is cancelled

**AC-VALIDATE-003: Free characters always pass server validation**
- Given: Any player account, regardless of stats or entitlements
- When: The Match Server validates a selection of Vex, Zook, or Sera
- Then: Validation passes for all three without querying Inventory

**AC-VALIDATE-004: Missing character definition fails validation**
- Given: A player sends `character_id: "character:undefined"` which does not exist in the Content Catalog
- When: The Match Server validates the selection
- Then: Returns `CHAR_DEFINITION_NOT_FOUND`, match is cancelled

---

### 8.5 Runtime Instance Initialization

**AC-RUNTIME-001: Runtime instance initialized with full HP**
- Given: A valid character is selected and passes validation
- When: The `CharacterRuntimeInstance` is created at match start
- Then: `current_hp === effective_stats.max_hp`, `is_alive === true`, `active_status_effects` is empty, `ability_cooldowns` is empty

**AC-RUNTIME-002: Duplicate character selection creates independent instances**
- Given: Two players in a 3v3 match both select Vex
- When: Match instances are created
- Then: Two separate `CharacterRuntimeInstance` objects exist in server memory, each with their own `player_id`, `current_hp`, and `passive_state`; modifying one does not affect the other

---

### 8.6 Visual Feedback Thresholds

**AC-VFX-001: HP state transitions at correct thresholds**
- Given: A character's `max_hp = 100`
- When: `current_hp` is checked at values 100, 59, 29, 9, 0
- Then: `hp_state` returns `"full"`, `"injured"`, `"critical"`, `"near_death"`, `"eliminated"` respectively

**AC-VFX-002: Thresholds respect effective max_hp after overlay**
- Given: A character has `effective_stats.max_hp = 90` (after a 0.9 overlay)
- When: `current_hp = 27`
- Then: `hp_state = "critical"` (27/90 = 30% — exactly at threshold boundary)

---

*End of Character System GDD — Version 1.0 Draft*
