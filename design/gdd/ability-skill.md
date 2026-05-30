# Ability / Skill System — Game Design Document
> **System**: Ability / Skill System
> **Priority**: MVP
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

The Ability / Skill System is the authoritative source for everything an ability *is* and how it *executes*. It sits at the intersection of character identity and combat resolution: the Character System defines which slots a character owns; the Deck/Loadout System populates those slots with choices from the shared pool; the Combat System calls the Ability System to resolve damage, healing, and status effects; and the Match Server enforces all state.

### What This System Owns

| Concern | Owner |
|---|---|
| Ability data schema | Ability System |
| Shared ability pool definition (all MVP abilities) | Ability System |
| Ability execution pipeline (cast → resolve → cooldown) | Ability System + Match Server |
| Cooldown tracking (per-player, per-ability, server-authoritative) | Ability System (data) + Match Server (runtime) |
| Passive ability logic (state-machine definitions, tick evaluation rules) | Ability System |
| Status effect type registry (STUNNED, SLOWED, SHIELDED, INVISIBLE, BURNING) | Ability System |
| Affinity bonus application | Ability System |
| Targeting model classification (projectile, targeted, AoE) | Ability System |

### What This System Does NOT Own

- Which abilities a character currently has equipped (Deck/Loadout System)
- Raw damage calculation beyond ability-specific modifiers (Combat System)
- Network transport / input serialisation (Match Server)
- UI rendering of cooldown timers (In-Match HUD)
- Character base stats (Character System)

---

## 2. Player Fantasy

### The Precision of a Well-Timed Ability

BRAWLZONE is a mobile brawler played in short, intense sessions. Abilities are the moments players remember. The fantasy has three layers:

**Layer 1 — Execution Satisfaction.** Every active ability fires in response to deliberate player intent. Instant-cast abilities feel snappy and responsive — a tap becomes immediate aggression. Heavy abilities (300–500ms cast) create a micro-drama: the player commits, the opponent reacts, and the resolution feels earned. The ability fires because the player *chose right*, not because RNG smiled at them.

**Layer 2 — Cooldown Chess.** With two active ability slots, players are always managing a small economy. Burning both abilities into a fight wins it faster but leaves a window of vulnerability. Saving one ability as an escape option is viable but sacrifices pressure. Watching an opponent's ability icons go dark on their HUD is actionable information — *now* is the moment to push. This creates a rhythm of aggression and caution that distinguishes skilled play from button-mashing within 90 seconds of a session.

**Layer 3 — Passive Payoff.** Passives are the system telling a character's story through mechanics. Vex's stacking damage bonus rewards disciplined target focus. Zook's long-shot bonus rewards positioning discipline. Sera's self-heal on ability use creates the feeling that her abilities are simultaneously offensive and restorative. When a passive synergy clicks with an equipped active ability — for example, Fen using a Utility ability to trigger Trick Shot into a charged Offensive ability — the combination feels like a skill expression the player *discovered*, not one the game handed them.

### The Fear of Being Wrong

The flip side of the fantasy is meaningful consequence. Using an ability at the wrong moment — wasting a shield while the opponent holds a stun — feels bad in a way that teaches. The system earns player respect by being consistent and readable: cooldowns are never hidden, status effect durations are always visible, and the server never lies. Players who lose to ability timing know exactly what they did wrong.

---

## 3. Detailed Rules

### 3.1 Ability Data Schema

All abilities in the shared pool conform to the following schema. This is the canonical record stored in the ability registry and consumed by the Match Server, Deck/Loadout System, and HUD.

```typescript
interface AbilityDefinition {
  id: string;                        // Unique identifier, e.g. "loadout_item:ability_burstsurge"
  name: string;                      // Display name, e.g. "Burst Surge"
  type: "passive" | "active";        // Passive abilities are not slottable by players
  archetype: "offensive" | "defensive" | "utility";
  description: string;               // Player-facing text (used in UI)
  cooldownSec: number;               // Seconds; 0 for passive (no cooldown)
  castTimeMs: number;                // Milliseconds; 0 = instant
  range_units: number;               // Maximum effective range; 0 = self-only
  effectDuration_ms: number;         // Duration of the applied effect; 0 = instantaneous
  effectMagnitude: number;           // Primary numeric value (damage, heal amount, slow %)
  projectile: boolean;               // True if the effect travels as a projectile
  aoeRadius_units: number;           // 0 for single-target abilities
  affinityCharacterIds: string[];    // Character IDs that receive the affinity bonus
  affinityBonus: number;             // Multiplier added to effectMagnitude; always 0.10 at MVP
}
```

**Notes on schema fields:**

- `cooldownSec` is stored as a float to support future fractional-second values without schema migration.
- `effectMagnitude` is the *base* value before all runtime multipliers. The Combat System always reads the base value from the definition and applies modifiers at resolution time — the definition is never mutated at runtime.
- `aoeRadius_units` of 0 explicitly marks a single-target ability. The targeting code uses this check — do not omit it.
- `affinityBonus` is fixed at `0.10` for all MVP abilities. The field exists in the schema to allow per-ability override in future seasons without a breaking change.

---

### 3.2 Passive Ability Execution Model

Passives are **not** player-activated. They are state machines evaluated by the Match Server on every server tick (every 50ms at 20Hz).

**Passive Execution Contract:**

1. Each character has exactly one passive. The passive definition is looked up from the ability registry using the character's `passiveAbilityId` field.
2. The Match Server maintains a `passive_state` object per player instance. This object is owned by the Ability System schema and written/read exclusively by the passive's evaluation function.
3. On each tick, for each live player, the server calls `evaluatePassive(playerId, gameState, passive_state)` → returns an updated `passive_state` and optionally a list of `PassiveEffect` events to dispatch to the Combat System.
4. Passives have **no cast time** and **no cooldown** as visible to the player. Internal state (e.g., stack counts, cooldown flags, elapsed timers) is managed within `passive_state`.
5. Passives are **not selectable or replaceable** — they are fixed to the character.

**`passive_state` Schema (base):**

```typescript
interface PassiveState {
  characterId: string;
  [key: string]: unknown; // Per-passive fields, defined below per character
}
```

**Per-character `passive_state` fields:**

| Character | Passive State Fields | Notes |
|---|---|---|
| Vex | `hitStreakTarget: string \| null`, `hitStreakCount: number (0–3)` | Resets to 0 and clears target on target switch |
| Zook | *(stateless — evaluated purely from shot distance at moment of hit)* | No persistent state needed |
| Sera | *(stateless — triggered by active ability use event)* | Listens for `ABILITY_USED` event |
| Fen | `trickShotActiveUntil: number \| null` (server timestamp ms) | Set on ability use; cleared after 2s or on proc |
| Grim | `stoneSkinUsed: boolean`, `stoneSkinActiveUntil: number \| null` | `stoneSkinUsed` never resets within a match |
| Dash | `afterburnActiveUntil: number \| null` (server timestamp ms) | Set on ability use; cleared after 2s |
| Colt | *(stateless — applied at ability resolution time as duration multiplier)* | No persistent state needed |
| Nyx | `openerUsed: boolean` | Set to true after first active ability use; never resets |

---

### 3.3 Active Ability Execution Pipeline

The pipeline is strictly linear and server-authoritative. The client may *predict* ability use locally for responsive feel, but the server's resolution is canonical.

```
PLAYER INPUT (touch)
      │
      ▼
CLIENT: Sends AbilityUseRequest { playerId, abilityId, targetPos, timestamp }
      │
      ▼
MATCH SERVER: Receives request on next tick
      │
      ├─ [CHECK 1] Cooldown validation
      │    Is currentTime >= cooldownExpiresAt[playerId][abilityId]?
      │    NO  → Reject: send AbilityRejected { reason: "COOLDOWN" } to client
      │    YES → Continue
      │
      ├─ [CHECK 2] Cast eligibility validation
      │    Is player alive? Is player NOT STUNNED?
      │    NO  → Reject: send AbilityRejected { reason: "INELIGIBLE" } to client
      │    YES → Continue
      │
      ├─ [CHECK 3] Nyx opener CDR application (pre-cast)
      │    If character is Nyx AND openerUsed == false:
      │      effectiveCooldown = ability.cooldownSec * 0.50
      │      passive_state.openerUsed = true
      │    Else:
      │      effectiveCooldown = ability.cooldownSec
      │
      ├─ CAST TIME PHASE (if ability.castTimeMs > 0)
      │    Set player move speed multiplier = 0.50 for castTimeMs duration
      │    Register CastCompleteAt = currentTime + castTimeMs
      │    If player is stunned or dies during cast → cancel cast (no cooldown consumed)
      │    On CastCompleteAt: proceed to effect resolution
      │
      ├─ EFFECT RESOLUTION
      │    Determine targeting model (see §3.6)
      │    Collect target(s) within range / AoE radius
      │    Apply affinity bonus to effectMagnitude if applicable (see §3.5)
      │    Apply Colt duration bonus to effectDuration_ms if applicable
      │    Dispatch effect events to Combat System
      │    If Sera: dispatch 5% max HP self-heal event
      │    If Fen: check trickShotActiveUntil; if within window, apply +15% to next attack damage
      │    If Colt and ability creates an object: extend object lifetime by 20%
      │
      └─ COOLDOWN START
           cooldownExpiresAt[playerId][abilityId] = currentTime + effectiveCooldown
           Send AbilityConfirmed { abilityId, cooldownExpiresAt } to client
```

**Key rule:** Cooldown begins *after* effect resolves, not at cast initiation.

---

### 3.4 Cast Time Model

| Cast Time Category | Duration | Applies To |
|---|---|---|
| Instant | 0ms | The majority of MVP active abilities |
| Heavy | 300–500ms | High-damage burst, large AoE, long-duration control abilities |

**During Cast:**
- Player move speed is reduced to 50% of their current effective speed.
- Player can still rotate / aim.
- Player cannot use a second ability (second slot is locked during cast).
- If the player is STUNNED during cast: cast is cancelled, no cooldown is consumed, and the cast-time speed penalty is removed immediately.
- If the player disconnects during cast: cast is cancelled, no cooldown consumed (see §5).

**Design rationale for cast time:** On a mobile touch interface, heavy abilities would feel unavoidable at instant cast. The 300–500ms window is both a counterplay signal (experienced players will recognize the cast animation) and an accessibility aid (new players have time to react). The movement penalty during cast prevents a tap-and-dodge loop that would trivialise heavy abilities.

---

### 3.5 Cooldown Model

- Cooldowns are tracked **per-player, per-ability** in the Match Server's `CooldownRegistry`.
- `CooldownRegistry[playerId][abilityId] = expiresAtTimestampMs`
- The server tick reads `Date.now()` (or the simulation clock) and compares against the registry entry.
- Cooldown starts **after effect resolution** (not at cast start, not at cast end pre-effect).
- The client receives `AbilityConfirmed` messages with the authoritative `cooldownExpiresAt` timestamp and renders a countdown from that value.
- If the client's prediction shows an ability as ready but the server's `CooldownRegistry` says it is not, the server **rejects** the attempt and the client corrects its display on the next snapshot (see §5, edge case 5).

**Cooldown Reduction (CDR):**
- Nyx's opener passive: `effectiveCooldown = baseCooldown × (1 − 0.50)` applied once per match to the first ability used.
- Future CDR items/effects will use the same formula with a different CDR coefficient (see §4.3).

---

### 3.6 Affinity Bonus Application

When an ability is cast, the Match Server checks:

```
if (ability.affinityCharacterIds.includes(castingCharacter.id)) {
  resolvedMagnitude = ability.effectMagnitude × (1 + ability.affinityBonus)
} else {
  resolvedMagnitude = ability.effectMagnitude
}
```

- This multiplication is applied at resolution time, not stored in the ability definition.
- `affinityBonus` is `0.10` for all MVP abilities, resulting in a 10% increase to the primary effect magnitude.
- Affinity applies to the *primary* `effectMagnitude` only. It does not independently affect `effectDuration_ms`, `aoeRadius_units`, or `range_units` at MVP. (Duration extension for Colt is handled separately by the passive, not affinity.)
- If an ability has no entries in `affinityCharacterIds`, affinity logic is skipped entirely for that ability.

---

### 3.7 Status Effects

All status effects are registered in the Status Effect Registry. Each active instance on a player is tracked in `statusEffects[playerId]` as an array of active `StatusEffectInstance` objects.

**Status Effect Instance Schema:**

```typescript
interface StatusEffectInstance {
  type: StatusEffectType;
  magnitude: number;          // Percent or absolute value, type-specific
  expiresAtMs: number;        // Server timestamp
  sourcePlayerId: string;     // For attribution (kill feed, Combat System)
  sourceAbilityId: string;
}
```

**MVP Status Effect Types:**

| Type | Effect | Magnitude Meaning | Stacking Rule |
|---|---|---|---|
| `STUNNED` | Player cannot move or use abilities | N/A (binary) | Not stackable; re-application refreshes duration |
| `SLOWED` | Move speed reduced by magnitude % | Percentage (e.g., 30 = 30% slow) | Not stackable; highest magnitude wins |
| `SHIELDED` | Absorbs incoming damage up to magnitude HP | HP value (absolute) | Not stackable; higher shield overwrites lower |
| `INVISIBLE` | Player model not rendered to opponents (server still simulates) | N/A (binary) | Not stackable; re-application refreshes duration |
| `BURNING` | Deals damage equal to magnitude HP per tick (tick interval: 500ms) | HP per tick | Not stackable; re-application refreshes duration and replaces magnitude |

**Status Effect Resolution Rules:**
- Status effects are applied immediately upon ability effect resolution.
- The Match Server evaluates active status effects every tick before processing player actions (status gates movement and ability use).
- On STUNNED: the server skips that player's ability and movement processing for the tick.
- On SLOWED: the effective move speed = `baseMoveSpeed × (1 − magnitude/100)`, floored at 10% of base speed.
- On SHIELDED: incoming damage is first subtracted from the shield's remaining HP. When the shield is depleted, overflow damage applies to HP. Shield HP does not regenerate.
- On INVISIBLE: the player's position and model are excluded from the state snapshot sent to opponent clients. The server continues to process all interactions normally (the player can still be hit by AoE that covers their actual position).
- On BURNING: every 500ms, `magnitude` damage is dealt to the player. BURNING damage bypasses shields (it is internal damage, not an incoming attack).

---

### 3.8 Targeting Models

All abilities use exactly one targeting model, declared implicitly by their schema fields:

**Model A — Projectile (`projectile: true`, `aoeRadius_units == 0`)**
- A physics-simulated object is spawned at the caster's position and travels in the aimed direction.
- Resolves on first collision with an enemy player or terrain boundary.
- Maximum travel distance is `range_units`. If no collision occurs by that distance, the projectile despawns with no effect.
- Server-side: the Match Server simulates projectile position each tick. Hit detection uses a capsule vs. player hitbox test.
- Client-side: the projectile is rendered locally with interpolation for visual smoothness; the authoritative hit is the server's determination.

**Model B — Targeted (`projectile: false`, `aoeRadius_units == 0`)**
- Effect is applied instantaneously to a single valid target within `range_units`.
- Valid target selection: the ability is aimed at a specific player (touch target or locked target); the server validates that the target is within `range_units` at the moment of resolution.
- If the target is out of range at server resolution time (they moved during cast): the ability **misses** and the cooldown is still consumed.

**Model C — AoE (`aoeRadius_units > 0`)**
- A circular area is placed at a chosen location (or the caster's position for self-centred AoEs).
- All valid targets within `aoeRadius_units` of the placement point at the moment of resolution are affected.
- Maximum placement distance from caster: `range_units`. If `range_units == 0`, AoE is always caster-centred.
- The area resolves simultaneously for all targets (no priority order).
- AoE abilities with `projectile: true` travel to their placement point before detonating (e.g., a grenade). The travel is treated as a projectile; AoE resolution happens on arrival.

---

### 3.9 Canonical Ability Pool

> **The canonical ability pool is defined in `content-catalog.md §Canonical Record Definitions — Loadout Item Records`.** The deprecated 14-ability UPPER_SNAKE_CASE registry that previously appeared here has been removed. All ability IDs, display names, effect summaries, cooldowns, and affinity character assignments are authoritative only in that section.

The pool consists of **18 abilities** in three archetypes × six abilities each. Affinity character IDs use the canonical `character:{slug}` format. The affinity bonus (+10% `effectMagnitude`) is applied at resolution time as described in §3.6.

For quick reference, the affinity and archetype groupings are reproduced below. **For authoritative values, always consult `content-catalog.md §Canonical Record Definitions — Loadout Item Records`.**

### 3.10 Complete Ability Pool Reference

> **Authoritative source**: `content-catalog.md §Canonical Record Definitions — Loadout Item Records`. The table below is a read-only summary. Discrepancies between this table and the Content Catalog are errors to be corrected against the Content Catalog.

**Offensive (6):**

| Canonical ID | Display Name | Effect Summary | Cooldown | Affinity |
|-------------|-------------|----------------|----------|----------|
| `loadout_item:ability_burstsurge` | Burst Surge | Directional shockwave; 30 damage in cone | 8s | `character:vex` |
| `loadout_item:ability_ragepulse` | Rage Pulse | +30% attack damage for 4s | 11s | `character:vex` |
| `loadout_item:ability_flashstrike` | Flash Strike | Teleport to and strike target ≤5 LGU for 25 damage | 9s | `character:nyx` |
| `loadout_item:ability_grenadebarrage` | Grenade Barrage | 3 grenades in spread; 12 damage each on impact | 12s | `character:zook` |
| `loadout_item:ability_overload` | Overload | Next attack within 3s deals ×2 damage + 0.5s stun | 10s | `character:colt` |
| `loadout_item:ability_pindownshot` | Pin-Down Shot | 20 damage + roots target for 1s | 13s | `character:sera` |

**Defensive (6):**

| Canonical ID | Display Name | Effect Summary | Cooldown | Affinity |
|-------------|-------------|----------------|----------|----------|
| `loadout_item:ability_ironwall` | Iron Wall | Shield absorbing up to 30 damage for 3s; stationary | 10s | `character:grim` |
| `loadout_item:ability_thornbarrier` | Thorn Barrier | 2s barrier; melee attackers receive 10 reflect damage | 11s | `character:grim` |
| `loadout_item:ability_rollaway` | Roll Away | Rapid dodge roll; 0.5s invulnerability frames | 7s | `character:dash` |
| `loadout_item:ability_phasestep` | Phase Step | Instant teleport 4 LGU in facing direction; no i-frames | 8s | `character:dash` |
| `loadout_item:ability_healfield` | Heal Field | +20 HP immediately; +5 HP/s for 3s | 15s | `character:fen` |
| `loadout_item:ability_smokecover` | Smoke Cover | 3-LGU smoke cloud for 4s; blocks auto-attack targeting | 14s | `character:nyx` |

**Utility (6):**

| Canonical ID | Display Name | Effect Summary | Cooldown | Affinity |
|-------------|-------------|----------------|----------|----------|
| `loadout_item:ability_slowfield` | Slow Field | 3-LGU zone; 40% speed reduction for enemies inside for 4s | 12s | `character:zook` |
| `loadout_item:ability_trapmine` | Trap Mine | Invisible mine; 15 damage + knockback on first trigger | 11s | `character:zook` |
| `loadout_item:ability_disruptpulse` | Disrupt Pulse | Silence all enemy abilities within 4 LGU for 2s | 14s | `character:colt` |
| `loadout_item:ability_pullgravity` | Gravity Pull | Pull target within 6 LGU exactly 3 LGU toward caster | 10s | `character:colt` |
| `loadout_item:ability_debuffstrike` | Debuff Strike | Next attack applies −20% attack speed to target for 4s | 9s | `character:fen` |
| `loadout_item:ability_rallycry` | Rally Cry | 3v3: nearest ally +10 HP + 10% damage for 5s. 1v1/FFA: self +5 HP + 10% damage for 3s | 13s | `character:fen` |

---

## 4. Formulas

### 4.1 Affinity Bonus Formula

```
resolvedMagnitude = baseMagnitude × (1 + affinityBonus)
```

Where `affinityBonus = 0.10` for all MVP abilities.

Example: `character:zook` fires Burst Surge (`loadout_item:ability_burstsurge`, base 30 damage). `character:zook` is not in `ability_burstsurge`'s `affinityCharacterIds` (affinity is `character:vex`). For a character that does match — `character:vex` firing Burst Surge:
```
resolvedMagnitude = 30 × (1 + 0.10) = 30 × 1.10 = 33 damage
```

---

### 4.2 Damage Calculation with Status Effect Modifiers

The Combat System resolves final damage in the following order. The Ability System provides `resolvedMagnitude` and the Combat System applies all subsequent multipliers:

```
Step 1:  abilityDamage = resolvedMagnitude  (post-affinity, from Ability System)

Step 2:  Apply attacker passive bonuses (evaluated prior to this step in passive tick):
           if Vex hitStreakCount == 1: abilityDamage × 1.05
           if Vex hitStreakCount == 2: abilityDamage × 1.10
           if Vex hitStreakCount == 3: abilityDamage × 1.15
           if Zook long-shot condition met: abilityDamage × 1.20
           if Fen trickShotActive (and this is an attack, not ability): abilityDamage × 1.15
           (Note: Vex passive and Zook passive do not stack simultaneously in normal play;
            characters are distinct. Passives only apply for the character with that passive.)

Step 3:  Apply incoming modifiers on target:
           if target has SHIELDED:
             shieldAbsorb = min(shield.remainingHP, abilityDamage)
             shield.remainingHP -= shieldAbsorb
             abilityDamage -= shieldAbsorb
           if target has Grim Stone Skin active:
             abilityDamage = abilityDamage × (1 - 0.20)
             (Stone Skin applies after shield absorption)

Step 4:  finalDamage = floor(abilityDamage)
         target.currentHP -= finalDamage
```

**Note on BURNING:** DoT damage (from BURNING) bypasses the shield check entirely and is applied directly to `currentHP` after step 4 processing per tick.

---

### 4.3 Cooldown Reduction Formula

```
effectiveCooldown = baseCooldown × (1 − CDR)
```

Where `CDR` is a coefficient in [0, 1].

- **Nyx opener passive:** `CDR = 0.50` (applied once, first active ability only).
- **Future CDR effects:** Additional CDR sources should be applied multiplicatively, not additively, to avoid stacking to zero:
  ```
  effectiveCooldown = baseCooldown × (1 − CDR_1) × (1 − CDR_2) × ...
  ```
- **Minimum cooldown floor:** No ability's effective cooldown may be reduced below `1.0s` regardless of CDR stacking. This floor prevents degenerate infinite-cast scenarios.

---

### 4.4 Damage-over-Time Tick Formula

DoT effects (any ability that applies a BURNING or similar recurring damage status) tick every 500ms:

```
tickDamage = dotMagnitude  (HP per tick, from status effect instance)
tickCount  = floor(remainingDurationMs / 500)
totalDoT   = tickDamage × tickCount
```

Each tick:
```
target.currentHP -= tickDamage
(bypass shields; apply immediately)
```

Example with a 2000ms DoT at 5 damage/tick (hypothetical ability):
```
tickCount = floor(2000 / 500) = 4 ticks
totalDoT  = 5 × 4 = 20 damage
```
(The partial tick at any remaining sub-500ms window is *not* applied — only whole ticks execute. The `floor()` is intentional to avoid fractional damage.)

With Colt's passive extending object/effect duration by 20% (2000ms → 2400ms):
```
tickCount = floor(2400 / 500) = floor(4.8) = 4 ticks
```
In practice the 20% extension does not add a full 5th tick at this base duration. **Design note for tuning:** If this is unsatisfying, the DoT tick interval can be tuned to 400ms so Colt's extension meaningfully adds a full 5th tick.

---

## 5. Edge Cases

### EC-1: Ability Used at Exact Cooldown Expiry (Race Condition)

**Scenario:** The client's local clock shows the cooldown as expired. The player taps the ability. The input packet arrives at the Match Server on a tick where `currentTime == cooldownExpiresAt` exactly.

**Resolution:** The cooldown check is `currentTime >= cooldownExpiresAt`. Equal timestamps are treated as expired (ability is ready). This is the client-favourable resolution and prevents frustrating "expired but rejected" moments caused by sub-tick timing jitter.

**Implementation note:** The Match Server uses its own simulation clock, not wall-clock time, for cooldown checks. Input packets are timestamped by the server at receive time. Client-side prediction is allowed to show the ability as ready one tick early (50ms tolerance window) without correction.

---

### EC-2: Player Disconnects Mid-Cast

**Scenario:** A player begins a 400ms cast. Between cast start and `CastCompleteAt`, their network connection drops.

**Resolution:**
1. The Match Server detects the disconnect via missed heartbeats (typically within 1–3 ticks).
2. The in-progress cast entry is cancelled: `CastCompleteAt` is removed, move speed penalty is reverted.
3. **No cooldown is consumed.** The ability's `cooldownExpiresAt` remains at its prior value (either already on cooldown from a previous use, or `0` meaning ready).
4. The player is removed from the match per the disconnect handling rules in the Match Server specification.

**Rationale:** Penalising players with a consumed cooldown for a disconnect they did not control is anti-player. The cast was never confirmed or resolved.

---

### EC-3: Grim's Stone Skin Triggered Twice in One Match

**Scenario:** Grim's HP drops below 30% twice in one match (e.g., healed back above 30% by Heal Field (`ability_healfield`), then drops below again).

**Resolution:** The `passive_state.stoneSkinUsed` flag is set to `true` on first activation and is **never reset within a match**. The passive evaluation function checks `stoneSkinUsed` before checking the HP threshold:

```
if (!stoneSkinUsed && currentHP / maxHP < 0.30) {
  activateStoneSkin();
  passive_state.stoneSkinUsed = true;
}
```

On the second HP drop: `stoneSkinUsed == true` → condition false → Stone Skin does not activate.

**Exploitation attempt — Intentional HP dip:** A player cannot deliberately trigger Stone Skin early to cycle it. The once-per-match flag makes this a resource to protect, not to exploit.

---

### EC-4: Ability Target Dies Mid-Cast

**Scenario:** A player begins casting a targeted ability (e.g., Pin-Down Shot (`ability_pindownshot`) with 0ms cast time — this scenario is more relevant to a hypothetical future targeted heavy ability, but for completeness) targeting an enemy. The enemy dies between when the cast begins and when the effect resolves.

**Resolution:**
- At effect resolution, the server checks whether the target is alive.
- If the target's `isAlive == false`: the effect **does not apply**. No damage, no status effects.
- **Cooldown is still consumed.** The player committed to the ability; the target dying is a valid game outcome that rewards the opponent.
- The client receives `AbilityResolved { abilityId, result: "TARGET_DEAD" }` and shows the cooldown timer without a hit confirmation.

**Note for 0ms cast abilities:** For instant abilities, there is effectively zero window for the target to die "mid-cast." This edge case is most relevant to any ability with cast time > 0ms. AoE abilities follow the same rule: targets who die before the AoE resolution timestamp are not hit.

---

### EC-5: Client Shows Ability as Ready, Server Has It on Cooldown

**Scenario:** Due to clock drift, packet loss, or client misprediction, the client renders an ability icon as ready (no cooldown overlay). The player taps it. The server's authoritative `CooldownRegistry` shows it is still on cooldown.

**Resolution:**
1. The server rejects the `AbilityUseRequest` with `AbilityRejected { reason: "COOLDOWN", cooldownRemainingMs: N }`.
2. The client receives the rejection and immediately corrects its displayed cooldown to `cooldownRemainingMs`.
3. No ability fires. No cooldown is extended or reset.
4. On the next full state snapshot, the client's cooldown timer is re-synchronised against the server's authoritative timestamp.

**Client implementation guidance:** Clients should treat server `AbilityRejected { reason: "COOLDOWN" }` messages as authoritative corrections, not as errors to surface to the player. The UI correction should be seamless (the timer snaps to the correct remaining value). An audio/visual "unavailable" indicator is acceptable but should not block future input attempts.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (what Ability System reads)

| System | Data Consumed | Usage |
|---|---|---|
| **Character System** | `character.id`, `character.passiveAbilityId`, `character.abilitySlots[2]`, `character.passive_state` schema | Ability execution references character identity; passive evaluation reads/writes `passive_state`; affinity check uses `character.id` |
| **Character System** | `character.baseStats.maxHP` | Required for Sera's 5% max HP heal calculation and Heal Field (`ability_healfield`) targeting in 3v3 |

### 6.2 Downstream Dependencies (what consumes Ability System)

| System | Data / Events Consumed | Usage |
|---|---|---|
| **Combat System** | `AbilityEffect` events dispatched by pipeline | Applies damage, heals, status effects to player HP/state |
| **Deck / Loadout System** | `AbilityDefinition` records (full ability pool) | Populates available ability choices; enforces no-duplicate rule; displays archetype categories |
| **Match Server** | Execution pipeline, `CooldownRegistry`, `passive_state` tick evaluation | Validates and executes all ability use; owns runtime cooldown state |
| **In-Match HUD** | `AbilityConfirmed { cooldownExpiresAt }`, `AbilityRejected { cooldownRemainingMs }`, `passive_state` (for passive indicators) | Renders cooldown countdowns, passive state indicators (e.g., Vex stack count, Grim Stone Skin available indicator) |

### 6.3 Interface Contracts

**Ability System → Match Server:**
- Provides: `AbilityDefinition[]` (static registry loaded at server start)
- Provides: `evaluatePassive(playerId, gameState, passive_state): { updatedState, effects[] }` (called each tick)
- Provides: `resolveAbilityEffect(abilityId, casterId, targetData): AbilityEffect[]` (called at resolution step)

**Match Server → Ability System:**
- The Match Server owns the runtime `CooldownRegistry` and `passive_state` objects. The Ability System defines their schemas and the evaluation/resolution functions that operate on them.

---

## 7. Tuning Knobs

These values are the primary levers for balance iteration. All are defined in a single `abilityConfig.json` file (or equivalent server-side config) to enable live tuning without redeployment.

### 7.1 Per-Ability Cooldown Values

Canonical ability IDs use the `loadout_item:ability_{slug}` format defined in `content-catalog.md §Canonical Record Definitions — Loadout Item Records`.

| Ability (canonical ID slug) | Current CD (s) | Min (s) | Max (s) | Notes |
|---|---|---|---|---|
| `ability_burstsurge` | 8 | 5 | 12 | Core offensive spam-prevention |
| `ability_ragepulse` | 11 | 7 | 15 | Damage amplifier; floor guards against spam |
| `ability_flashstrike` | 9 | 6 | 13 | |
| `ability_grenadebarrage` | 12 | 8 | 16 | Multi-hit; higher floor expected |
| `ability_overload` | 10 | 6 | 14 | |
| `ability_pindownshot` | 13 | 9 | 18 | Root effect; high floor expected |
| `ability_ironwall` | 10 | 7 | 15 | Shield ability |
| `ability_thornbarrier` | 11 | 7 | 16 | Reflect; watch for aggressive low floors |
| `ability_rollaway` | 7 | 4 | 10 | Dodge; among lowest CDs in pool |
| `ability_phasestep` | 8 | 5 | 12 | Mobility teleport |
| `ability_healfield` | 15 | 10 | 20 | Heal-over-time |
| `ability_smokecover` | 14 | 9 | 20 | Concealment; invisibility-adjacent floor |
| `ability_slowfield` | 12 | 8 | 17 | Zone control; object-creating |
| `ability_trapmine` | 11 | 7 | 15 | Trap; stealth object |
| `ability_disruptpulse` | 14 | 9 | 19 | Silence; high floor expected |
| `ability_pullgravity` | 10 | 6 | 14 | Pull; CC meta sensitive |
| `ability_debuffstrike` | 9 | 6 | 13 | |
| `ability_rallycry` | 13 | 8 | 18 | Team buff |

### 7.2 Cast Time Values

Only abilities with non-zero cast times are listed. All others are instant (0ms).

| Ability (canonical ID slug) | Current (ms) | Range | Notes |
|---|---|---|---|
| `ability_grenadebarrage` | 200 | 100–350 | Projectile arc; cast time aids counterplay |
| `ability_slowfield` | 300 | 200–450 | Zone placement; object-creating |
| `ability_disruptpulse` | 200 | 150–350 | Silence AoE; cast window for counterplay |

### 7.3 Effect Magnitudes

Damage values reflect the canonical 12–30 damage range defined in `content-catalog.md §Canonical Record Definitions — Loadout Item Records`. The deprecated 80–220 damage range from the prior ability registry is no longer valid.

| Ability (canonical ID slug) | Current Magnitude | Notes |
|---|---|---|
| `ability_burstsurge` | 30 damage (cone) | Primary offensive benchmark in the canonical pool |
| `ability_flashstrike` | 25 damage | Teleport strike; value includes repositioning |
| `ability_grenadebarrage` | 12 damage per grenade (×3) | Spread; 36 total if all hit; balanced by spread variance |
| `ability_pindownshot` | 20 damage + 1s root | Root has high utility value |
| `ability_ironwall` | 30 damage absorbed (shield) | Shield cap matches top single-hit in pool |
| `ability_thornbarrier` | 10 reflect damage | Reflect; intentionally lower than direct damage |
| `ability_healfield` | +20 HP immediate, +5 HP/s for 3s | Burst + HoT; watch vs. damage output per second |
| `ability_trapmine` | 15 damage + knockback | Trap; delayed application lowers effective value |
| `ability_pullgravity` | 3 LGU pull distance | Increase = more dangerous; watch engage/disengage combos |
| `ability_debuffstrike` | −20% attack speed for 4s | Debuff; no direct damage |
| `ability_rallycry` | +10 HP ally / +5 HP self, +10% damage for 3–5s | Buff; magnitude doubles as HP and damage boost |

### 7.4 Affinity Bonus Magnitude

| Parameter | Current | Range | Notes |
|---|---|---|---|
| `affinityBonus` (all abilities) | 0.10 | 0.05–0.20 | Raising above 0.15 may make affinity-matched loadouts mandatory |

### 7.5 Status Effect Durations

| Status | Source Ability (canonical slug) | Current Duration | Range | Notes |
|---|---|---|---|---|
| STUNNED | `ability_overload` (0.5s) | 500ms | 300–800ms | Brief stun from attack amplifier |
| SLOWED | `ability_slowfield` (zone) | 4000ms | 2000–6000ms | Applies to zone; object lifetime tracked separately |
| SHIELDED | `ability_ironwall` | 3000ms | 2000–4000ms | Stationary; shield HP 30 |
| INVISIBLE (smoke / concealment) | `ability_smokecover` | 4000ms | 2000–6000ms | Blocks auto-attack targeting; above 5s risks oppressive impact |

### 7.6 DoT Tick Interval

| Parameter | Current | Range | Notes |
|---|---|---|---|
| BURNING tick interval | 500ms | 200–1000ms | Shorter = more responsive damage readout; longer = fewer UI updates |

---

## 8. Acceptance Criteria

All criteria below must be satisfied before the Ability System is considered complete for MVP. Each criterion maps to at least one automated integration test.

### AC-1: Ability Schema Validation

- [ ] **AC-1.1** Every ability in the canonical 18-ability pool (defined in `content-catalog.md §Canonical Record Definitions — Loadout Item Records`) has a unique canonical ID of the form `loadout_item:ability_{slug}`.
- [ ] **AC-1.2** Every ability with `type: "active"` has `cooldownSec > 0`.
- [ ] **AC-1.3** Every ability with `projectile: true` has `range_units > 0`.
- [ ] **AC-1.4** Every ability with `aoeRadius_units > 0` has `range_units >= 0`.
- [ ] **AC-1.5** No ability has `affinityBonus` outside the range [0, 1].
- [ ] **AC-1.6** Each character listed in `affinityCharacterIds` corresponds to a valid canonical character ID of the form `character:{slug}` as defined in `content-catalog.md §Canonical Record Definitions — Character Records`.

### AC-2: Execution Pipeline

- [ ] **AC-2.1** An ability cannot be executed when its `cooldownExpiresAt > currentTime`. A `AbilityRejected { reason: "COOLDOWN" }` message is sent.
- [ ] **AC-2.2** An ability cannot be executed when the player is STUNNED. A `AbilityRejected { reason: "INELIGIBLE" }` message is sent.
- [ ] **AC-2.3** An ability cannot be executed when the player is dead. A `AbilityRejected { reason: "INELIGIBLE" }` message is sent.
- [ ] **AC-2.4** Player move speed is reduced by 50% for the duration of `castTimeMs` when `castTimeMs > 0`.
- [ ] **AC-2.5** Player cannot activate a second ability slot while a cast is in progress.
- [ ] **AC-2.6** Cooldown begins only after effect resolves, not at cast initiation. Verified by: cast a 400ms ability, confirm `cooldownExpiresAt` is set at `castCompleteTime + cooldownSec`, not at `castStartTime + cooldownSec`.
- [ ] **AC-2.7** `AbilityConfirmed { abilityId, cooldownExpiresAt }` is sent to the casting client on successful execution.

### AC-3: Cooldown Enforcement

- [ ] **AC-3.1** After firing an ability, it cannot be fired again until `currentTime >= cooldownExpiresAt`.
- [ ] **AC-3.2** Cooldown state persists across network interruptions (brief packet loss does not reset cooldowns).
- [ ] **AC-3.3** A client with a stale-ready cooldown display receives `AbilityRejected { reason: "COOLDOWN" }` and a `cooldownRemainingMs` correction value.

### AC-4: Affinity Bonus

- [ ] **AC-4.1** When a character in `affinityCharacterIds` fires an ability, `resolvedMagnitude == baseMagnitude × 1.10`.
- [ ] **AC-4.2** When a character NOT in `affinityCharacterIds` fires the same ability, `resolvedMagnitude == baseMagnitude`.
- [ ] **AC-4.3** Affinity bonus applies only to `effectMagnitude`, not to `effectDuration_ms` or `aoeRadius_units`.

### AC-5: Status Effects

- [ ] **AC-5.1** STUNNED player receives `AbilityRejected { reason: "INELIGIBLE" }` for both ability slots for the stun's duration.
- [ ] **AC-5.2** STUNNED player's movement inputs are ignored for the stun's duration.
- [ ] **AC-5.3** SLOWED player's effective move speed is `baseMoveSpeed × (1 − magnitudePct/100)`, floored at 10% of base speed.
- [ ] **AC-5.4** SHIELDED player: incoming ability damage is reduced by the shield's remaining HP; shield HP depletes accordingly; overflow damage is applied to HP.
- [ ] **AC-5.5** SHIELDED player: BURNING damage bypasses the shield and applies directly to HP.
- [ ] **AC-5.6** INVISIBLE player is absent from opponent state snapshots for the invisibility duration.
- [ ] **AC-5.7** INVISIBLE player: using any active ability immediately removes INVISIBLE status.
- [ ] **AC-5.8** BURNING applies `magnitude` HP damage every 500ms for `effectDuration_ms` (floor(duration/500) ticks).
- [ ] **AC-5.9** Status effects do not stack (e.g., two SLOWED sources: highest magnitude wins; re-application refreshes duration only).

### AC-6: Passive Abilities

- [ ] **AC-6.1** Vex: `hitStreakCount` increments on each consecutive hit to the same target (max 3). Switching targets resets to 0. Damage multiplier is 1.00 / 1.05 / 1.10 / 1.15 at stacks 0/1/2/3.
- [ ] **AC-6.2** Zook: Attacks from beyond 60% of `maxRange` deal `baseDamage × 1.20`. Attacks at or below 60% deal `baseDamage × 1.00`.
- [ ] **AC-6.3** Sera: On any active ability use, Sera heals `0.05 × maxHP` immediately.
- [ ] **AC-6.4** Fen: On any active ability use, `trickShotActiveUntil = currentTime + 2000`. The next basic attack within this window deals `baseDamage × 1.15`; after the attack procs, the window closes.
- [ ] **AC-6.5** Grim: Stone Skin activates exactly once per match when `currentHP / maxHP < 0.30`. Activates for exactly 5s. Does not activate again even if HP rises above 30% and drops again.
- [ ] **AC-6.6** Dash: On any active ability use, `afterburnActiveUntil = currentTime + 2000`. Move speed is `baseMoveSpeed × 1.15` during this window.
- [ ] **AC-6.7** Colt: Any ability with `effectDuration_ms > 0` that creates an object has its object lifetime = `effectDuration_ms × 1.20` when cast by Colt.
- [ ] **AC-6.8** Nyx: First active ability cast in a match applies `effectiveCooldown = baseCooldown × 0.50`. Subsequent abilities use `baseCooldown`. `openerUsed` flag is not reset within a match.

### AC-7: Edge Cases

- [ ] **AC-7.1** Ability request at exact `currentTime == cooldownExpiresAt` is accepted (not rejected).
- [ ] **AC-7.2** Player disconnect during cast: cast is cancelled, no cooldown consumed, move speed penalty removed.
- [ ] **AC-7.3** Grim's Stone Skin does not activate more than once per match regardless of HP fluctuations.
- [ ] **AC-7.4** Ability resolves against a target who dies before `CastCompleteAt`: effect does not apply; cooldown is consumed.
- [ ] **AC-7.5** Client receives `AbilityRejected { reason: "COOLDOWN" }` with valid `cooldownRemainingMs` when server determines ability is on cooldown despite client prediction.

### AC-8: Targeting Models

- [ ] **AC-8.1** Projectile ability (`projectile: true`, `aoeRadius_units == 0`) resolves on first enemy collision or at `range_units` (despawn with no effect).
- [ ] **AC-8.2** Targeted ability (`projectile: false`, `aoeRadius_units == 0`) misses and consumes cooldown if target moved out of `range_units` by resolution time.
- [ ] **AC-8.3** AoE ability (`aoeRadius_units > 0`) affects all valid targets within radius at resolution time simultaneously.
- [ ] **AC-8.4** AoE projectile travels to placement point and then resolves AoE; all targets in radius at arrival time are affected.

### AC-9: Cooldown Reduction

- [ ] **AC-9.1** Nyx opener CDR: `effectiveCooldown = baseCooldown × 0.50` for first ability only.
- [ ] **AC-9.2** No ability's effective cooldown is reduced below `1.0s` regardless of CDR sources.
- [ ] **AC-9.3** Future CDR sources (when added) are applied multiplicatively per §4.3.

---

*End of Document*
