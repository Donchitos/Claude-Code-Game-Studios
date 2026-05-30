# Combat System — Game Design Document
> **System**: Combat System
> **Priority**: MVP ⚠️
> **Layer**: Core Gameplay
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

### What the Combat System Owns

The Combat System is the authoritative simulation layer that resolves all physical interactions between characters during a match. It runs inside Phase 3 (Simulation) of the 20Hz Match Server game loop. Every tick (50ms) it consumes validated player inputs and the current world state, then emits a new authoritative world state.

The Combat System specifically owns:

- **Movement resolution** — consuming analog joystick input vectors, resolving velocity, advancing player positions, and handling all collision responses (static obstacle wall-slide, soft cover slowdown, player-to-player passthrough).
- **Basic attack model** — the timing, targeting, range check, and classification of a character's standard attack (the non-ability damage source available every tick outside of cooldown). Supports melee (instant hit) and ranged (projectile) attack types at MVP.
- **Hit detection** — server-side circular hitbox overlap evaluation for melee attacks; server-side projectile path tracing each tick for ranged attacks; lag-compensated position rewind so hits registered by the attacking client are evaluated against a reconstructed past state.
- **Damage calculation pipeline** — the ordered sequence of modifiers that transforms raw attack damage into a final HP delta applied to the defender's runtime instance, including SHIELDED absorption, soft cover reduction, and BURNING bypass rules.
- **Assist tracking** — maintaining a per-player rolling damage contribution log for the last 5 seconds, and computing `assistantIds[]` on each elimination event.
- **Elimination** — detecting when a character's current HP reaches 0 or below, emitting the `elimination_event`, and removing the character from active simulation.
- **Zone damage** — applying per-tick damage to characters whose position lies outside the active safe zone boundary; zone damage bypasses SHIELDED and soft cover reduction.
- **Destructible obstacle damage and removal** — tracking obstacle HP as the Ability System delivers damage, removing the obstacle from the collision map when HP reaches 0, and emitting `obstacle_destroyed`.

### What the Combat System Does NOT Own

| Concern | Owning System |
|---|---|
| Ability execution (cast time, cooldown management, status effect application) | Ability / Skill System |
| Win condition checks (last player standing, score thresholds) | Game Mode System |
| Match start / end lifecycle | Match Flow System |
| Map loading, spawn point assignment | Map / Arena System |
| Character stat definitions and balance overlays | Character System |
| HP bar rendering, damage number display, hit VFX | In-Match HUD |
| `elimination_event` consumer logic (score increment, camera transition, kill feed) | Game Mode System + Match Flow |

### Positioning Within the Game Loop

```
Tick N (50ms budget):
  [1] Input collection         — network layer gathers all queued inputs
  [2] Input validation         — discard inputs older than 3 ticks (150ms);
                                 discard inputs for eliminated players
  [3] Simulation phase         ← COMBAT SYSTEM EXECUTES HERE (target ≤ 18ms)
      [3a] Movement resolution
      [3b] Basic attack evaluation + hit detection (with lag compensation rewind)
      [3c] Damage pipeline execution (basic attacks + Ability System hand-offs)
      [3d] Assist log update
      [3e] Elimination checks — ALL eliminations flushed here
      [3f] Zone damage application
      [3g] Destructible obstacle HP checks + collision map deferred update
  [4] Win condition check      — Game Mode evaluator reads elimination/HP state
                                 (elimination_events from 3e are already flushed)
  [5] State emit               — authoritative snapshot broadcast to all clients
```

**Tick budget contract**: The Simulation phase (Step 3) has a worst-case budget of 18ms within the 50ms tick period. This provides a 2ms buffer for variance. Steps 3a–3g must collectively complete within 18ms.

---

## 2. Player Fantasy

### The Core Promise

Combat in BRAWLZONE must feel **tight, readable, and fair** on a touchscreen. Every design decision in this document serves that single promise. A player on a 4G connection who taps their attack button must trust that if they aimed correctly, the hit registered — and if they took damage, they understand why.

### The Feeling of Landing a Hit

A successful hit is a micro-transaction of skill and intention. The player aimed the joystick, timed the attack, and the feedback loop closes immediately: the opponent's HP bar drops, a damage number floats, and the hit VFX fires. The feedback is **instant from the player's perspective** — client-side prediction shows the damage number and hit flash before the server confirmation arrives, so there is no perceived delay. When the server reconciles and the hit was valid, nothing changes visually. When the server reconciles and the hit was invalid (rare — a near-miss at max lag), the number disappears: a momentary ghost that teaches the player about range or timing without harshly punishing them.

What makes this feel good on mobile specifically: **the hitbox is generous enough that near-misses don't feel stolen, but precise enough that clever positioning is rewarded**. A circular hitbox with radius `HITBOX_RADIUS_LGU = 0.6` (see Section 3.3) is larger than a pixel-perfect sprite boundary but smaller than "I was clearly across the arena." Players learn to read the hitbox through repeated play without needing a tutorial.

### The Weight of Taking Damage

Taking damage must feel like a meaningful event, not noise. The HUD's HP bar depletes with a short ease-out animation (handled by HUD, not Combat System). Damage numbers are color-coded: white for standard, orange for BURNING DoT, yellow for zone damage (HUD-owned semantics). Screen-edge vignette activates below 30% HP (HUD-owned).

The Combat System's role is to make damage feel **fair**: because damage is resolved server-side with lag compensation, a player who dodged behind cover should not take a hit that visually missed. Soft cover reducing incoming damage by 20% creates a tangible tactical reward for positioning — the player feels safer inside cover without becoming invulnerable.

### The Tension of a Low-HP Clutch Play

When a player is below 30% HP they are operating in a different emotional register: every decision costs more, every mistake is terminal. This tension is entirely produced by the no-respawn elimination rule and the zone damage system. The shrinking zone compresses available safe space exactly when the player is least equipped to fight through it. The best clutch plays — a melee character baiting a heavy-cast ability then closing to burst — are only possible because the combat model is **legible enough that both players know what just happened**.

BURNING status at low HP creates a specific texture of danger. A player on 8 HP who is BURNING knows they have at most one BURNING tick before death. This creates forced decision points that feel dramatic rather than arbitrary, because the rules are visible and consistent.

### The Satisfaction of an Elimination

Elimination is a permanent, match-defining event. No respawn means the `elimination_event` carries full weight. The Combat System emits it cleanly — the character is removed from simulation, collisions cease — and downstream systems (HUD, Game Mode, Match Flow) produce the ceremony: death animation, kill-feed entry, score increment. The Combat System does not do ceremony; it does **clean state transition**.

Assist credit ensures that players who contributed meaningful damage feel rewarded even when they do not land the final hit. This is especially important in 3v3 Squad Brawl and FFA modes where cooperation matters.

### What Breaks the Feel (Anti-Patterns to Avoid)

| Anti-Pattern | Why It Breaks Mobile PvP Feel |
|---|---|
| Hit registration that depends entirely on the attacker's client perspective | Creates "I definitely hit them" disputes — always resolve server-side |
| Rubber-banding that visibly snaps the player's position | Destroys trust in the control model; prefer smooth client reconciliation |
| Damage spikes that kill from full health in a single basic attack tick | Eliminates counterplay; even burst combos must take > 1 tick |
| Zone damage that silently kills | Zone damage must be communicated by HUD warning before it kills |
| Attacks that physically block player movement | No positional locking; players must always be able to disengage |
| SHIELDED blocking zone damage | Breaks zone's role as an environmental forcing function |

---

## 3. Detailed Rules

### 3.1 Movement Model

#### Input Model

Movement input arrives as a 2D joystick vector `(jx, jy)` where each axis is in `[-1.0, 1.0]`. The input is fully analog — not quantized to 8 directions. The client samples joystick state each frame and includes the current vector in the input payload sent to the server.

**Touch-to-joystick mapping** (client implementation, documented here for dependency clarity): a virtual joystick rendered as a floating control zone in the left 40% of the screen. The vector origin is set at the touch-down point; the vector magnitude is clamped to `1.0` at a radius of 40 dp from origin. Players can reposition the joystick origin by lifting and re-placing their thumb.

#### Velocity Resolution

```
raw_vector    = (jx, jy)
magnitude     = sqrt(jx² + jy²)

if magnitude < DEADZONE_THRESHOLD (0.15):
    velocity_vector = (0, 0)
else:
    unit_vector     = (jx / magnitude, jy / magnitude)
    speed           = effective_move_speed * speed_modifier
    velocity_vector = unit_vector * speed

delta_position  = velocity_vector * TICK_DURATION_S
new_position    = old_position + delta_position  [before collision response]

Where:
  TICK_DURATION_S  = 0.05   (50ms at 20Hz)
  DEADZONE_THRESHOLD = 0.15 (prevents drift from imprecise thumb release)
```

`effective_move_speed` is the character's post-overlay move speed from the Character System runtime instance, modified by any active speed multipliers (see speed_modifier below).

#### Speed Modifier Stack

```
speed_modifier = soft_cover_multiplier * slowed_multiplier * cast_penalty_multiplier

Where:
  soft_cover_multiplier  = SOFT_COVER_SPEED_MULTIPLIER (0.65)  if character center
                           is inside a soft cover region, else 1.0
  slowed_multiplier      = value from SLOWED status effect (e.g. 0.60), else 1.0
  cast_penalty_multiplier = 0.50  if character is in cast time for an ability,
                            else 1.0

speed_modifier is clamped to [0.30, 1.0] after multiplication.
```

**Stacking note**: All three multipliers compose multiplicatively. A character SLOWED to 0.60 and inside soft cover (0.65): `0.60 * 0.65 = 0.39`, above the floor of 0.30. A character in all three simultaneously: `0.65 * 0.60 * 0.50 = 0.195` → clamped to `0.30`.

#### Collision Response — Static Obstacles (Impassable)

The server evaluates `new_position` against all static obstacle bounding regions using the character's collision circle (radius = `COLLISION_RADIUS_LGU = 0.4 LGU`).

If `new_position` would place the collision circle overlapping a static obstacle, apply wall-slide:

1. Compute the penetration vector `n` — the shortest vector from the obstacle boundary to the circle center (the direction to push the circle clear of the wall).
2. Decompose `delta_position` into two components:
   - `perp_component = (delta_position · n̂) * n̂` — the component parallel to `n` (into the wall).
   - `slide_component = delta_position − perp_component` — the component perpendicular to `n` (along the wall face).
3. Zero out `perp_component`. Apply `slide_component` to `old_position` to compute `slid_position`.
4. Re-evaluate `slid_position` against all other obstacles (second-pass corner check). If still penetrating, revert to `old_position` (full stop).
5. If `|slide_component| < SLIDE_STOP_THRESHOLD (0.01 LGU/tick)`, treat as full stop (prevents micro-vibration).

This produces smooth slide-along-wall movement without sticking. Players approaching a wall at a shallow angle will glide along it naturally.

#### Collision Response — Soft Cover (Slows, Blocks Projectiles)

Soft cover regions do **not** block movement. While a character's position center is inside a soft cover region:
- Move speed is multiplied by `SOFT_COVER_SPEED_MULTIPLIER = 0.65`.
- Incoming damage is reduced by `SOFT_COVER_DAMAGE_REDUCTION = 0.20` (see Section 3.4, Step 4).
- Projectiles are blocked when their path enters the soft cover region (see Section 3.3).

Soft cover membership is evaluated at the character's **center position** each tick.

#### Collision Response — Other Players

Players do not physically block each other. There is no collision response between two player collision circles. Players may fully overlap in position. This eliminates a class of griefing behaviors and is correct for a mobile brawler where precise physical separations cannot be read on small screens.

#### STUNNED Movement

A character with the STUNNED status effect has their velocity forced to `(0, 0)` regardless of joystick input. The STUNNED flag is read from the Character runtime instance (set by the Ability System). Movement resolution skips velocity calculation for STUNNED characters but still processes the tick (so their position is present in the state snapshot).

---

### 3.2 Basic Attack Model

#### Attack Types at MVP

At MVP, BRAWLZONE supports two basic attack types: **melee** (instant hit within range) and **ranged** (projectile). Every character is assigned exactly one type in their static definition in the Content Catalog. This is a fixed design constraint, not a runtime mode.

| Attack Type | Characters | Targeting | Server Behavior |
|---|---|---|---|
| **Melee** | Vex, Grim, Zook | Tap-target: client sends `BASIC_ATTACK { target_player_id }` | Server evaluates distance at compensated tick; instant hit if within range |
| **Ranged** | Sera, Dash, Fen, Nyx, Colt | Manual aim: client sends `BASIC_ATTACK { aim_vector: (ax, ay) }` | Server spawns projectile entity traveling in aim direction |

**No aim-assist at MVP.** The server does not bend projectile directions toward targets. The client UI may apply a visual snap indicator when an enemy is within 15° of the aim vector, but the server receives the raw aim vector. Server-side magnetism is deferred to post-MVP accessibility tuning.

#### Attack Speed and Cooldown Enforcement

`effective_attack_speed` (attacks per second) is stored on the character's runtime instance. The server tracks `last_attack_tick` per character. A `BASIC_ATTACK` input is accepted only if:

```
current_tick >= last_attack_tick + floor(TICK_RATE_HZ / effective_attack_speed)

Where:
  TICK_RATE_HZ = 20
  floor(20 / 1.5) = 13 ticks (≈ 0.65s interval at default 1.5 attacks/sec)
```

If the cooldown has not elapsed, the input is silently dropped. The client's local prediction will have shown the attack; reconciliation will correct it. `last_attack_tick` is updated to `current_tick` on every valid basic attack regardless of whether it hits.

A STUNNED character cannot initiate a basic attack. `BASIC_ATTACK` inputs are discarded for STUNNED players in the Input Validation phase (Phase 2) before the Combat System runs.

#### Attack Range Check

**Melee**: server computes Euclidean distance between attacker and target at the lag-compensated tick. Attack is valid if:
```
distance(attacker_pos, target_pos) <= effective_attack_range + HITBOX_RADIUS_LGU
```
This check is **inclusive** (see Edge Case 5.2).

**Ranged**: no pre-launch range check. A projectile is spawned at the attacker's position and travels up to `effective_attack_range` LGU before despawning (the same stat serves as max projectile travel distance for ranged characters).

---

### 3.3 Hit Detection

#### Hitbox Model

Every character uses a **circular hitbox** centered on their position with radius `HITBOX_RADIUS_LGU = 0.6 LGU`. This is intentionally larger than the collision circle (`COLLISION_RADIUS_LGU = 0.4 LGU`): collision is tighter (fair movement) while the hitbox is more generous (satisfying hits).

Hitbox radius is uniform across all 8 characters at MVP.

#### Melee Hit Detection

1. Server rewinds authoritative state to the lag-compensated tick (see Section 3.3.3).
2. Retrieves the target's rewound position.
3. Computes Euclidean distance between attacker's rewound position and target's rewound position.
4. Hit registers if: `distance <= effective_attack_range + HITBOX_RADIUS_LGU`

The `+ HITBOX_RADIUS_LGU` term accounts for the target's hitbox extent: the attack range stat represents the attacker's weapon reach, so the total valid interaction distance includes the target's hitbox radius.

#### Projectile Hit Detection

Projectiles are **server-owned entities**, independent of their owner's alive state. Each projectile record holds:

```
{
  projectile_id   : string        // unique per-tick spawn ID
  owner_id        : string        // attacker player ID (used for kill attribution)
  origin          : (x, y)        // spawn position
  direction       : (dx, dy)      // normalized unit vector (from aim_vector input)
  speed_lgu_s     : number        // PROJECTILE_SPEED_LGU_S tuning knob
  spawn_tick      : number
  max_range_lgu   : number        // = effective_attack_range at spawn time
  raw_damage      : number        // = effective_attack_damage at spawn time (frozen)
}
```

**Each tick**, the server advances each live projectile:
```
new_proj_pos       = proj_pos + direction * speed_lgu_s * TICK_DURATION_S
distance_traveled  = distance(origin, new_proj_pos)

if distance_traveled >= max_range_lgu:
    despawn projectile  (no hit)
    continue

if new_proj_pos is inside any soft cover region:
    despawn projectile  (blocked by soft cover; no hit)
    continue

for each active (non-eliminated) player P where P.player_id != owner_id:
    if distance(new_proj_pos, P.position) <= HITBOX_RADIUS_LGU:
        register hit on P
        despawn projectile
        break  (projectile hits at most one target)
```

Projectile hit detection uses the **current-tick player positions**, not rewound positions. Rationale: the projectile's server-authoritative position advances each tick; rewinding the targets would mean the projectile "passes through" positions that already changed while it was in flight. The lag compensation rewind was applied at projectile spawn (when the attack input was validated) — the projectile itself is ground truth from that point on.

#### Lag Compensation (Rewind-Based Hit Validation)

Applies to **melee** basic attack hit detection and ability melee hits routed through this pipeline.

When the server receives a `BASIC_ATTACK` input carrying a `clientTimestamp`, the server computes:

```
rewind_ms = clamp(server_time_ms - clientTimestamp, 0, MAX_REWIND_MS)

rewind_ticks = floor(rewind_ms / TICK_DURATION_MS)

Where:
  TICK_DURATION_MS = 50
  MAX_REWIND_MS    = 150  (3 ticks — matches the 3-tick input discard threshold)
```

The server reconstructs a **partial state snapshot** from its tick-history ring buffer (10 ticks of history maintained):
- Only **positions** of all characters are rewound.
- HP, status effects, obstacle state, and zone state are NOT rewound.
- The rewound snapshot is used **exclusively** for hit/miss determination.
- Damage is calculated and applied against the **current tick's HP and status state**.

This design means a player who used a shield in the past 150ms still benefits from it in the present — the rewind does not undo their defensive play.

**Rewind boundary guard**: If `clientTimestamp` predates `match_start_time_ms`, rewind is capped at match start (tick 0). If `clientTimestamp` is in the future relative to `server_time_ms`, `rewind_ms` is clamped to `0` (evaluate at current state). See Edge Case 5.6.

---

### 3.4 Damage Calculation Pipeline

All damage — basic attack, ability damage routed from the Ability System, and zone damage — passes through this pipeline. Steps are applied in fixed order; each step's output is the next step's input.

```
PIPELINE INPUT:
  raw_damage       — source value (see Step 1 below)
  attacker_id      — player ID of the damage source (null for zone damage)
  defender         — the CharacterRuntimeInstance receiving damage
  damage_flags     — set of flags: { IS_ZONE, IS_BURNING, IS_BASIC_ATTACK, IS_ABILITY }
```

#### Step 1 — Establish raw_damage

```
  Basic attack:     raw_damage = attacker.effective_attack_damage
  Ability damage:   raw_damage = ability.effectMagnitude
                                 * affinity_bonus (1.10 if character has affinity, else 1.0)
  Zone damage:      raw_damage = zone_damage_per_tick
  BURNING DoT:      raw_damage = burning_dot_damage_per_tick (from status effect record)
```

#### Step 2 — Attacker Outgoing Modifier

```
  attacker_modified_damage = raw_damage * 1.0   // identity at MVP
  // Reserved for post-MVP: outgoing damage buff status effects
```

#### Step 3 — Defender SHIELDED Absorption

```
  IF IS_ZONE flag is set:
      SKIP this step entirely — zone damage bypasses SHIELDED
  ELSE IF IS_BURNING flag is set:
      SKIP this step entirely — BURNING damage bypasses SHIELDED
  ELSE IF defender has SHIELDED status:
      shield_absorbs      = min(attacker_modified_damage, defender.shield_hp)
      damage_after_shield = attacker_modified_damage - shield_absorbs
      defender.shield_hp -= shield_absorbs
      if defender.shield_hp <= 0:
          remove SHIELDED status from defender
  ELSE:
      damage_after_shield = attacker_modified_damage
```

**Critical rule**: Both zone damage (`IS_ZONE`) and BURNING DoT (`IS_BURNING`) bypass SHIELDED absorption. Zone damage bypasses SHIELDED because it is an environmental forcing function. BURNING bypasses SHIELDED because fire burns through defenses by design — this is a defining characteristic of the BURNING status effect.

#### Step 4 — Soft Cover Damage Reduction

```
  IF IS_ZONE flag is set:
      SKIP this step — zone damage bypasses soft cover reduction
  ELSE IF defender's position center is inside a soft cover region at current tick:
      damage_after_cover = damage_after_shield * (1.0 - SOFT_COVER_DAMAGE_REDUCTION)
      // SOFT_COVER_DAMAGE_REDUCTION = 0.20
  ELSE:
      damage_after_cover = damage_after_shield
```

Soft cover reduction applies to BURNING damage (BURNING is not zone damage; it passes through this step normally).

#### Step 5 — Apply HP Delta

```
  defender.current_hp -= damage_after_cover
  defender.current_hp  = max(0, defender.current_hp)
  // HP floor at 0; over-damage is discarded
```

After Step 5, if `defender.current_hp <= 0`, the elimination procedure is invoked (Section 3.6).

#### SLOWED Status Note

SLOWED does not affect the damage pipeline. It only affects movement speed (see Section 3.1). A SLOWED defender receives full damage.

#### Pipeline Summary Table

| Source | Step 2 | Step 3 SHIELDED | Step 4 Cover | Notes |
|---|---|---|---|---|
| Basic attack | Identity | Full absorption | Full reduction | Standard path |
| Ability damage | Identity | Full absorption | Full reduction | Affinity bonus applied in Step 1 |
| BURNING DoT | Identity | **Bypassed** | Full reduction | Bypasses shield by design |
| Zone damage | Identity | **Bypassed** | **Bypassed** | Bypasses both; environmental |

---

### 3.5 Assist Tracking

#### Damage Contribution Log

The server maintains a **rolling damage contribution log** per player (as attacker). Each entry records:
```
{
  attacker_id  : string   // player who dealt the damage
  victim_id    : string   // player who received the damage
  damage_dealt : number   // final HP delta (after pipeline) applied to victim
  tick         : number   // match tick when the damage was applied
}
```

The log retains entries for the last `ASSIST_WINDOW_SEC * TICK_RATE_HZ` ticks (`5 * 20 = 100 ticks`). Older entries are discarded each tick (rolling window). The log is append-only; entries are never modified after insertion.

All damage sources that reduce a character's HP generate a log entry: basic attacks, ability damage, and BURNING DoT. Zone damage does **not** generate assist log entries — zone damage cannot produce an assist (the zone has no owner).

#### Assist Computation on Elimination

Immediately before emitting `elimination_event`, the Combat System computes `assistantIds[]`:

```
ASSIST_WINDOW_MS      = ASSIST_WINDOW_SEC * 1000   (5,000ms)
ASSIST_MIN_DAMAGE_PCT = 10   // percent of victim's max_hp

eligible_window_start = elimination_tick - (ASSIST_WINDOW_SEC * TICK_RATE_HZ)

for each player P (excluding killer and victim):
    recent_damage = Σ damage_dealt in log
                    WHERE attacker_id = P.player_id
                    AND   victim_id   = victim.player_id
                    AND   tick        >= eligible_window_start

    threshold = victim.effective_stats.max_hp * (ASSIST_MIN_DAMAGE_PCT / 100)

    if recent_damage >= threshold AND P.is_alive:
        add P.player_id to assistantIds[]
```

**Alive requirement**: Only players alive at the moment of elimination can earn an assist (consistent with Game Mode GDD).

**Killer exclusion**: The killer is never included in `assistantIds[]`, even if they dealt damage in the assist window before the killing blow.

**Assists on zone eliminations**: Zone damage does not generate assist log entries, so a zone kill cannot produce assists (intentional — the zone is not an agent).

---

### 3.6 Elimination

#### Trigger

At the end of the damage pipeline (Step 5), after applying the HP delta:

```
if defender.current_hp <= 0:
    compute_assists(defender)
    eliminate(defender)
```

`compute_assists` must complete before `eliminate` so that `assistantIds[]` is populated in the event payload.

#### Elimination Procedure

1. Set `defender.eliminated = true` and `defender.elimination_tick = current_tick`.
2. Compute `assistantIds[]` using the assist formula (Section 3.5).
3. Record `eliminated_by_player_id` and `elimination_cause` (`BASIC_ATTACK` | `ABILITY` | `ZONE` | `BURNING_DOT`) for the kill feed.
4. Emit `elimination_event` with payload:
   ```
   {
     victimId      : string      // eliminated player ID
     killerId      : string      // player who delivered the final HP delta (null for zone)
     assistantIds  : string[]    // players earning assist credit (may be empty)
     cause         : string      // elimination cause code
     matchTick     : number      // current tick
     victimPosition: { x, y }   // position at time of elimination
   }
   ```
5. Remove the character from the **active simulation list**: excluded from movement, excluded from hit detection as a target, collision circle removed from the collision map.
6. In-flight projectiles owned by the eliminated character **continue** to resolve normally (see Edge Case 5.4).

#### Flush Guarantee

All `elimination_event`s generated in Simulation Step 3e must be fully emitted **before** the Win Condition Evaluator runs in Step 4. This is the contractual guarantee to the Game Mode System: when the evaluator fires, it sees the complete elimination state for the current tick.

Mutual kills (two eliminations in the same tick) produce two separate `elimination_event` payloads emitted in ascending `player_id` sort order (arbitrary but deterministic for kill-feed display).

#### No Respawn at MVP

Eliminated characters do not re-enter the match. The combat simulation treats them as permanently absent. Match Flow handles spectator camera transition; that concern is outside Combat System scope.

---

### 3.7 Zone Damage

The zone boundary is managed by the Map/Arena System and shrinks over time in FFA mode. The current zone state is available to the Combat System each tick as `zone_center (x, y)` and `zone_radius_lgu` from the shared match state. The `zone_elapsed_ms` field in the state snapshot is owned by Map/Arena and is read-only to Combat System.

**Each tick**, for each active (non-eliminated) character:
```
dist_from_center = distance(character.position, zone_center)
if dist_from_center > zone_radius_lgu:
    apply zone_damage_per_tick (IS_ZONE flag set — bypasses SHIELDED and soft cover)
```

`zone_damage_per_tick` is derived from `ZONE_DAMAGE_PER_SEC / TICK_RATE_HZ` at server startup and stored as a constant for the match (not re-derived each tick).

Zone damage is **uniform** regardless of distance outside the boundary at MVP. A character 0.1 LGU outside takes the same per-tick damage as one 20 LGU outside. (Post-MVP consideration: graduated distance-based scaling.)

`force_end_countdown` is emitted by Map/Arena System when the zone reaches its minimum radius. Combat System reads this as a signal that zone pressure will not increase further; it does not alter Combat System behavior.

---

### 3.8 Destructible Obstacle Damage

Destructible obstacles have `current_hp` tracked in match state, initialized from `obstacle_base_hp` in the map definition.

Damage to obstacles is delivered by the Ability System calling the Combat System's damage pipeline with the obstacle as the target. Obstacle damage skips Steps 2, 3, and 4 (obstacles have no status effects and are not inside soft cover):

```
obstacle.current_hp -= raw_damage   // direct application, no modifiers
obstacle.current_hp  = max(0, obstacle.current_hp)

if obstacle.current_hp <= 0:
    mark obstacle.destroyed = true
    queue collision_map removal for next tick  // deferred update
    emit obstacle_destroyed: { obstacleId, matchId, matchTick }
```

**Deferred collision map update**: The removal from the active collision map takes effect at the **start of the next tick**. All collision resolution within the current tick uses the pre-destruction layout. See Edge Case 5.5.

---

## 4. Formulas

### 4.1 Full Damage Pipeline Formula

The sequential pipeline formula for non-zone, non-BURNING damage:

```
Step 1:  damage_1 = raw_damage

Step 2:  damage_2 = damage_1 * 1.0               (attacker multiplier — identity at MVP)

Step 3:  IF SHIELDED and NOT IS_ZONE and NOT IS_BURNING:
             shield_absorb  = min(damage_2, defender.shield_hp)
             damage_3       = damage_2 - shield_absorb
             defender.shield_hp -= shield_absorb
         ELSE:
             damage_3       = damage_2

Step 4:  IF defender in soft cover AND NOT IS_ZONE:
             damage_4 = damage_3 * (1 - SOFT_COVER_DAMAGE_REDUCTION)
                      = damage_3 * 0.80
         ELSE:
             damage_4 = damage_3

Step 5:  defender.current_hp -= damage_4
         defender.current_hp  = max(0, defender.current_hp)
```

**Worked Example — Basic Attack Through Shield Into Cover:**
- raw_damage = 50
- Defender: shield_hp = 30 (SHIELDED), in soft cover
- Step 3: absorb 30 → damage_3 = 20, shield_hp = 0, SHIELDED removed
- Step 4: 20 * 0.80 = 16
- Step 5: current_hp -= 16

**Worked Example — BURNING DoT Through Shield Into Cover:**
- BURNING dot_damage_per_tick = 5
- Defender: shield_hp = 50 (SHIELDED), in soft cover, current_hp = 30
- Step 3: IS_BURNING → skip SHIELDED. damage_3 = 5
- Step 4: 5 * 0.80 = 4  (BURNING passes through soft cover reduction)
- Step 5: current_hp = 30 - 4 = 26, shield_hp unchanged at 50

**Worked Example — Zone Damage:**
- zone_damage_per_tick = 0.75
- Defender: shield_hp = 50 (SHIELDED), in soft cover (hypothetical — cover inside zone)
- Step 3: IS_ZONE → skip. Step 4: IS_ZONE → skip.
- Step 5: current_hp -= 0.75 (full zone damage, no modifiers)

---

### 4.2 Zone Damage Per Tick Formula

```
zone_damage_per_tick = ZONE_DAMAGE_PER_SEC / TICK_RATE_HZ
                     = 15 / 20
                     = 0.75 HP per tick

Time-to-eliminate from full health (zone only):
  ticks = max_hp / zone_damage_per_tick = 100 / 0.75 ≈ 133 ticks ≈ 6.7 seconds

Where:
  ZONE_DAMAGE_PER_SEC = 15   (tuning knob, Section 7)
  TICK_RATE_HZ        = 20
  max_hp              = 100  (base; may be modified by balance overlay)
```

This gives players approximately 6–7 seconds at full health to re-enter the zone before dying from zone damage alone — enough time to make a deliberate re-engagement decision, not enough to camp the boundary indefinitely.

---

### 4.3 Lag Compensation Rewind Formula

```
rewind_ms = clamp(server_time_ms - clientTimestamp, 0,
                  min(MAX_REWIND_MS, server_time_ms - match_start_time_ms))

rewind_ticks = floor(rewind_ms / TICK_DURATION_MS)

Where:
  MAX_REWIND_MS    = 150 ms   (3 ticks at 20Hz)
  TICK_DURATION_MS = 50 ms
  rewind_ticks ∈   [0, 3]
```

The server maintains a ring buffer of the last **10 position snapshots** (500ms history). At most 3 ticks are used for rewind; the extra buffer provides margin for server processing jitter.

---

### 4.4 Circular Hitbox Overlap Formula

**Melee attack reach check:**
```
hit = distance(attacker_pos, target_pos)  <=  (effective_attack_range + HITBOX_RADIUS_LGU)

distance(A, B) = sqrt((Ax - Bx)² + (Ay - By)²)

Where:
  effective_attack_range  = base_attack_range * balance_overlay_multiplier
  HITBOX_RADIUS_LGU       = 0.6 LGU
```

**Projectile-to-player hit check:**
```
hit = distance(projectile_pos, player_pos)  <=  HITBOX_RADIUS_LGU

Where:
  HITBOX_RADIUS_LGU = 0.6 LGU
```

**Boundary example (melee at exact range):**
```
effective_attack_range = 1.5, HITBOX_RADIUS_LGU = 0.6 → total reach = 2.1 LGU
Attacker at (0, 0), target at (2.1, 0):   distance = 2.1 → 2.1 ≤ 2.1 → HIT  (inclusive)
Attacker at (0, 0), target at (2.101, 0): distance = 2.101 > 2.1   → MISS
```

---

### 4.5 Movement Vector Wall-Slide Decomposition Formula

```
Given:
  delta_pos = velocity_vector * TICK_DURATION_S      // intended movement
  n̂         = unit penetration normal (wall outward normal at contact point)

Decompose:
  perp_component  = (delta_pos · n̂) * n̂             // movement into the wall
  slide_component = delta_pos - perp_component       // movement along the wall

Apply:
  slid_position = old_position + slide_component

If |slide_component| < SLIDE_STOP_THRESHOLD (0.01 LGU):
    slid_position = old_position                      // full stop; prevent micro-vibration
```

**Worked Example:**
- `delta_pos = (-0.2, 0.1)` (moving left-up toward a vertical wall)
- Wall outward normal `n̂ = (-1, 0)` (wall face is vertical, normal points left)
- `perp_component = ((-0.2 * -1) + (0.1 * 0)) * (-1, 0) = 0.2 * (-1, 0) = (-0.2, 0)`
- `slide_component = (-0.2, 0.1) - (-0.2, 0) = (0, 0.1)`
- Character slides upward along the wall; does not penetrate.

---

### 4.6 Assist Eligibility Formula

```
assistEligible(attacker P, victim V, elimination_tick T) =
    LET window_start = T - (ASSIST_WINDOW_SEC * TICK_RATE_HZ)
        recent_damage = Σ { entry.damage_dealt
                             | entry.attacker_id = P.player_id
                             AND entry.victim_id = V.player_id
                             AND entry.tick >= window_start }
        threshold = V.effective_stats.max_hp * (ASSIST_MIN_DAMAGE_PCT / 100)
    IN  recent_damage >= threshold
        AND P.player_id ≠ killer_id
        AND P.is_alive = true

Where:
  ASSIST_WINDOW_SEC      = 5    (tuning knob)
  ASSIST_MIN_DAMAGE_PCT  = 10   (% of victim's max_hp)
  TICK_RATE_HZ           = 20
```

**Worked Example:**
- Victim max_hp = 100; threshold = 10% × 100 = 10 HP
- Player A dealt 25 HP to victim in the last 5s → 25 ≥ 10 → **eligible**
- Player B dealt 8 HP to victim in the last 5s → 8 < 10 → **not eligible**
- Player A is alive, is not the killer → A is in `assistantIds[]`

---

### 4.7 BURNING DoT Tick Formula

```
burning_dot_damage_per_tick = ability.effectMagnitude * affinity_bonus_mult
                              // Note: effectMagnitude for a BURNING ability is the
                              // total damage per 500ms BURNING tick (set in ability schema)

BURNING tick interval = 500ms = BURNING_TICK_INTERVAL_MS

Number of BURNING ticks per second = 1000 / BURNING_TICK_INTERVAL_MS = 2

The Ability System fires one pipeline call per BURNING tick, passing:
  raw_damage    = burning_dot_damage_per_tick
  IS_BURNING    = true   (bypasses SHIELDED, passes through soft cover reduction)
  attacker_id   = original BURNING applier's player_id

Damage log entry IS generated for each BURNING tick (for assist tracking).

Where:
  BURNING_TICK_INTERVAL_MS = 500   (from Ability System specification)
  affinity_bonus_mult      = 1.10 if applier has affinity, else 1.0
```

---

## 5. Edge Cases

### 5.1 Simultaneous Mutual Kill (Both Players at ≤1 HP Same Tick)

**Scenario**: Player A and Player B each have 1 HP. In the same simulation tick, Player A's attack resolves and takes Player B to 0 HP, and Player B's attack resolves and takes Player A to 0 HP.

**Resolution**: Both players are eliminated in the same tick. The Combat System processes all damage applications in Step 3c before running elimination checks in Step 3e. After all damage is applied, both HP values are at 0. Both are eliminated. Two `elimination_event`s are emitted from Step 3e, in ascending `player_id` sort order (deterministic, arbitrary for display purposes only).

**Game Mode impact**: The Game Mode System receives both events in the same tick. For 1v1 Duel, this is a draw condition. Combat System does not determine match outcome — the Game Mode System handles the no-winner case.

---

### 5.2 Attack at Exact Range Boundary

**Resolution**: The range check is **inclusive**: `distance <= (effective_attack_range + HITBOX_RADIUS_LGU)`. A character exactly at the threshold distance is a valid hit target.

**Rationale**: A strict `<` boundary would make the range stat feel slightly shorter than advertised, creating frustration at the edge. Inclusive boundary matches player expectation: "if I'm at my attack range, I can hit."

---

### 5.3 SHIELDED Player Takes Zone Damage

**Resolution**: Zone damage bypasses SHIELDED entirely (Step 3 is skipped when `IS_ZONE` is set). A player at full shield HP still takes full `zone_damage_per_tick` each tick they are outside the zone boundary. Shield HP is not modified.

**Rationale**: Zone damage is an environmental forcing function. Allowing shields to block zone damage would enable a SHIELDED ability to trivially extend safe-zone immunity, breaking the core tension of zone shrink.

---

### 5.4 Projectile In-Flight When Owner Is Eliminated

**Resolution**: The projectile continues. Projectiles are server-owned entities. When a character is eliminated:
- They are removed from the active character list (cannot be targeted, cannot receive inputs).
- Their owned projectiles remain in `active_projectiles` and continue advancing each tick.
- If the projectile hits a player after the owner is eliminated, damage is applied normally.
- Kill attribution uses the `owner_id` on the projectile: `killerId` in the resulting `elimination_event` is the eliminated player's ID (posthumous kill).

**Rationale**: Removing in-flight projectiles on owner death would create exploitable "self-destruct to cancel shots" behavior and would feel wrong visually. The projectile is already in the world.

---

### 5.5 Obstacle Destroyed Mid-Tick

**Resolution**: Obstacle destruction (detected in Step 3g) is a **deferred collision map update**. The collision map used for all movement resolution in Step 3a of the current tick is the pre-destruction layout. The destruction takes effect in the collision map at the start of the next tick.

**Effect**: A character slide-stopping against an obstacle that is destroyed in the same tick will pass through that obstacle starting from the next tick. One tick of "ghost wall" behavior (50ms) is acceptable and unnoticeable at 20Hz. The same deferred rule applies to projectile vs. obstacle blocking for the current tick.

---

### 5.6 Lag Compensation Rewind Past Match Start

**Resolution**: If `server_time_ms - clientTimestamp` would exceed the time since match start, the rewind is capped at `match_start_time_ms`. Formula:

```
rewind_ms = clamp(server_time_ms - clientTimestamp, 0,
                  min(MAX_REWIND_MS, server_time_ms - match_start_time_ms))
```

Under normal operation (match running for > 150ms) this cap is never reached. It guards against malformed packets with forged `clientTimestamp` values predating the match. The server uses its own clock for `server_time_ms`; a client cannot manipulate `server_time_ms`.

---

### 5.7 Balance Overlay Value Out of Bounds

The Character System clamps all balance overlay multipliers to `[0.5, 1.5]` and emits a server warning before the runtime instance is created. The Combat System only ever reads the already-clamped `effective_stats` from the `CharacterRuntimeInstance` — it never performs its own bounds check on character stats. This is entirely a Character System responsibility.

---

### 5.8 Input Received for Eliminated Player

If the server receives a `BASIC_ATTACK` or movement input for a player whose `eliminated = true`, the input is discarded in Phase 2 (Input Validation) before the Combat System runs. The Combat System never processes inputs for eliminated players.

---

### 5.9 BURNING Applier Is Eliminated Before BURNING Resolves

**Resolution**: The BURNING status effect on the victim continues resolving tick-by-tick through the Ability System even after the applier is eliminated. Each BURNING tick calls the Combat System damage pipeline with `attacker_id = eliminated_applier_id`. If a BURNING tick eliminates the victim, the `killerId` in the `elimination_event` is the eliminated applier's ID (posthumous kill via DoT, consistent with Edge Case 5.4). Assist log entries for the BURNING damage are still generated.

---

## 6. Dependencies

### 6.1 Upstream Dependencies

| System | What Combat System Consumes | Coupling Type |
|---|---|---|
| **Character System** | `effective_attack_damage`, `effective_attack_range`, `effective_attack_speed`, `effective_move_speed`, `max_hp` (all post-overlay) from `CharacterRuntimeInstance`; `attack_type` (MELEE/RANGED) from static definition | Read — Combat System does not write to character stat definitions |
| **Ability / Skill System** | Routes ability damage calls into Combat System's damage pipeline; delivers status effect state on the `CharacterRuntimeInstance` (SHIELDED `shield_hp`, SLOWED multiplier, STUNNED flag, BURNING records) that Combat System reads each tick; applies BURNING DoT as per-tick damage pipeline calls | Bidirectional — Ability System pushes damage calls and status state; Combat System reads status state each tick |
| **Map / Arena System** | `collision_map` (static obstacle regions, destructible obstacle regions, soft cover regions); `zone_center`, `zone_radius_lgu` per tick; `zone_elapsed_ms` (read-only); `obstacle_base_hp` per obstacle; `force_end_countdown` signal | Read — Combat System mutates `obstacle.current_hp` in match state only, not the map definition |
| **Match Server** | Orchestrates the game loop; invokes Combat System phases in order each tick; provides `current_tick`, `server_time_ms`, `match_start_time_ms`; provides the ring buffer of historical position snapshots; enforces tick budget | Owned by Match Server — Combat System is a module within the Match Server simulation phase |

### 6.2 Downstream Dependencies

| System | What It Consumes from Combat System | Interface |
|---|---|---|
| **Game Mode System** | `elimination_event` payload (pre-computed `assistantIds[]`); current HP/alive state of all players for win condition evaluation. **Guarantee**: all elimination events for tick N are flushed before the Game Mode evaluator runs on tick N. | `elimination_event { victimId, killerId, assistantIds[], cause, matchTick, victimPosition }` |
| **In-Match HUD** | Current HP, shield HP, active status effects, damage events — delivered via the authoritative state snapshot emitted by Match Server Step 5 | State snapshot: `character.current_hp`, `character.shield_hp`, `damage_events[]` per tick |
| **Match Flow System** | `elimination_event` to trigger death camera, spectator mode, kill feed | `elimination_event` (same payload as above) |
| **Ability / Skill System** (downstream read) | Reads `obstacle.current_hp` (is obstacle still a valid target?); reads `character.current_hp` for conditional ability effects | Match state fields — not a direct API call |

---

## 7. Tuning Knobs

All tuning knobs are data-driven. No combat values are hardcoded in game logic. Values marked `(Remote Config)` can be adjusted without a server deployment; others require a Content Catalog or server config update and a deploy.

| Knob | Default Value | Safe Range | What It Affects |
|---|---|---|---|
| `base_attack_damage` | 10 HP | [5, 50] | Baseline damage per basic attack; primary time-to-kill driver. Defined in Character System, consumed by Combat System. |
| `effective_attack_speed` | 1.5 attacks/sec | [0.5, 3.0] | Attack frequency; interacts with `attack_damage` to produce DPS. Too fast → button-spam wins; too slow → attacks feel sluggish on touch. Defined in Character System. |
| `base_attack_range` | 2.5 LGU (melee) | Melee: [1.0, 3.5] | Melee reach. Determines whether close-combat requires tight positioning. Defined in Character System. |
| `base_attack_range` | 6.0 LGU (ranged) | Ranged: [4.0, 10.0] | Max projectile travel distance. Determines safe engagement distance in skirmishes. Defined in Character System. |
| `effective_move_speed` | 5.0 LGU/s | [4.0, 9.0] | Movement speed. Too slow → laggy on touch; too fast → positioning too chaotic. Defined in Character System. |
| `HITBOX_RADIUS_LGU` | 0.6 LGU | [0.3, 1.0] | Hit target size. Larger = more forgiving (casual); smaller = demands precise aim. Affects melee and projectile detection. |
| `COLLISION_RADIUS_LGU` | 0.4 LGU | [0.2, 0.6] | Player movement collision circle. Must be < `HITBOX_RADIUS_LGU`. Smaller = fits through tighter gaps. |
| `PROJECTILE_SPEED_LGU_S` | 12.0 LGU/s | [8.0, 20.0] | Ranged projectile travel speed. Too slow = easily dodged to frustration; too fast = feels like hitscan. |
| `SOFT_COVER_SPEED_MULTIPLIER` | 0.65 | [0.45, 0.85] | Movement speed inside soft cover. Lower = stronger positional deterrent; higher = nearly irrelevant. |
| `SOFT_COVER_DAMAGE_REDUCTION` | 0.20 (20%) | [0.10, 0.35] | Damage reduction inside soft cover. Low enough that cover is not a hard counter; high enough to be a meaningful tactical choice. |
| `ZONE_DAMAGE_PER_SEC` | 15 HP/s | [5, 40] | (Remote Config) Zone damage rate. Controls how aggressively zone collapse forces engagement. Must not one-shot a full-health character in < 5 seconds. |
| `MAX_REWIND_MS` | 150 ms | [50, 200] | Lag compensation cap. Higher values favor high-latency players (fewer missed hits) but allow larger positional discrepancy. Must not exceed the input discard threshold (150ms). |
| `OBSTACLE_BASE_HP` | 80 HP | [40, 200] | HP of destructible obstacles (per-obstacle override in map definition). Too low → disappear before affecting play; too high → never destroyed. |
| `DEADZONE_THRESHOLD` | 0.15 | [0.05, 0.25] | Joystick deadzone magnitude below which no movement is applied. Prevents idle drift; tune based on device testing. |
| `SLIDE_STOP_THRESHOLD` | 0.01 LGU/tick | [0.005, 0.02] | Minimum slide velocity; below this the character fully stops against a wall instead of micro-sliding. |
| `ASSIST_WINDOW_SEC` | 5 s | [3, 10] | (Remote Config) Rolling window for assist damage tracking. Shorter rewards finishing; longer rewards sustained pressure. |
| `ASSIST_MIN_DAMAGE_PCT` | 10 % | [5, 25] | (Remote Config) Minimum % of victim's max_hp dealt within the window to earn assist credit. Lower = assists distributed broadly; higher = assists reserved for significant contributors. |

---

## 8. Acceptance Criteria

All criteria must produce a definitive pass/fail result from an automated test or a reproducible manual test procedure.

---

### AC-1: Melee Hit Detection — Positive Case (Exact Boundary)

**Given** a stationary target at position (2.1, 0.0) with HITBOX_RADIUS_LGU = 0.6
**And** an attacker at position (0.0, 0.0) with effective_attack_range = 1.5
**And** lag compensation rewind = 0ms (identical to current tick)
**When** the attacker sends a BASIC_ATTACK targeting the target
**Then** the attack registers as a HIT (distance = 2.1 ≤ 2.1 — inclusive check)
**And** the damage pipeline is invoked with raw_damage = attacker's effective_attack_damage

**Pass**: damage is applied to target; HP decreases by the expected value.

---

### AC-2: Melee Hit Detection — Negative Case (One Millimeter Past Boundary)

**Given** a stationary target at position (2.101, 0.0) with HITBOX_RADIUS_LGU = 0.6
**And** an attacker at position (0.0, 0.0) with effective_attack_range = 1.5
**When** the attacker sends a BASIC_ATTACK
**Then** the attack registers as a MISS (distance = 2.101 > 2.1)

**Pass**: no damage is applied; target HP is unchanged.

---

### AC-3: Damage Pipeline — SHIELDED Absorption, Then Soft Cover Reduction

**Given** a defender with current_hp = 100, shield_hp = 30 (SHIELDED active), inside soft cover
**And** SOFT_COVER_DAMAGE_REDUCTION = 0.20
**When** 50 raw damage (basic attack) is applied through the pipeline
**Then**:
- Step 3: shield absorbs min(50, 30) = 30 → damage_after_shield = 20, shield_hp = 0, SHIELDED removed
- Step 4: 20 * 0.80 = 16
- Step 5: current_hp = 100 - 16 = 84

**Pass**: current_hp == 84; shield_hp == 0; SHIELDED status is absent from the runtime instance.

---

### AC-4: BURNING Bypasses SHIELDED

**Given** a defender with current_hp = 60, shield_hp = 50 (SHIELDED active), NOT in soft cover
**And** a BURNING DoT tick with burning_dot_damage_per_tick = 8
**When** the BURNING tick pipeline is invoked (IS_BURNING = true)
**Then**:
- Step 3: IS_BURNING → skip SHIELDED absorption; damage_after_shield = 8
- Step 4: not in soft cover; damage_after_cover = 8
- Step 5: current_hp = 60 - 8 = 52; shield_hp remains 50 (unchanged)

**Pass**: current_hp == 52; shield_hp == 50; SHIELDED status still active.

---

### AC-5: Zone Damage Bypasses SHIELDED

**Given** a defender with current_hp = 100, shield_hp = 50 (SHIELDED active)
**And** the defender is outside the zone boundary
**And** ZONE_DAMAGE_PER_SEC = 15 → zone_damage_per_tick = 0.75
**When** one tick of zone damage is applied (IS_ZONE = true)
**Then** current_hp = 100 - 0.75 = 99.25; shield_hp remains 50 (unchanged)

**Pass**: current_hp == 99.25; shield_hp == 50.

---

### AC-6: Zone Damage Bypasses Soft Cover Reduction

**Given** a defender outside the zone boundary, whose position is inside a soft cover region
**And** ZONE_DAMAGE_PER_SEC = 15 → zone_damage_per_tick = 0.75
**When** one tick of zone damage is applied
**Then** current_hp decreases by exactly 0.75 (soft cover reduction NOT applied)

**Pass**: HP delta == -0.75.

---

### AC-7: Elimination — Event Emitted and Character Removed From Simulation

**Given** an active character with current_hp = 5, no status effects
**When** 10 raw damage (basic attack) is applied
**Then**:
- current_hp is set to 0 (not -5 — floored at 0)
- `elimination_event` is emitted with the correct `victimId`, `killerId`, `matchTick`, `victimPosition`
- The character is removed from the active simulation list
- Subsequent ticks do not process movement or attack inputs for this character

**Pass**: event emitted; `eliminated = true`; character absent from active list.

---

### AC-8: Assist Computation — Correct Threshold and Exclusions

**Given** a victim with max_hp = 100 (current_hp at kill = 0)
**And** Player A dealt 25 HP to victim within the last 5 seconds (≥ 10% threshold)
**And** Player B dealt 8 HP to victim within the last 5 seconds (< 10% threshold)
**And** Player C dealt 12 HP to victim within the last 5 seconds but was eliminated before the kill tick (is_alive = false)
**And** Player D is the killer
**When** the elimination is processed and `elimination_event` is emitted
**Then** `assistantIds = [Player A]` (B below threshold, C not alive, D is killer)

**Pass**: exactly `[Player A]` in `assistantIds[]`.

---

### AC-9: Mutual Kill — Same Tick Produces Two Events

**Given** Player A and Player B each have current_hp = 1
**And** both exchange attacks that resolve in the same simulation tick N
**When** tick N simulation phase completes
**Then**:
- Both Player A and Player B have current_hp = 0
- Two `elimination_event`s are emitted in tick N (one for A, one for B)
- Both players are removed from the active simulation list

**Pass**: exactly 2 elimination events emitted in tick N; both players eliminated.

---

### AC-10: Lag Compensation — Rewind Capped at MAX_REWIND_MS

**Given** MAX_REWIND_MS = 150, TICK_DURATION_MS = 50
**And** server_time_ms = 10000, clientTimestamp = 9700 (300ms ago — exceeds cap)
**When** rewind is computed: `clamp(10000 - 9700, 0, 150) = clamp(300, 0, 150) = 150ms`
**Then** rewind_ticks = floor(150 / 50) = 3; hit detection uses the position snapshot 3 ticks ago

**Pass**: rewind_ms == 150; correct historical snapshot used.

---

### AC-11: Lag Compensation — No Rewind Past Match Start

**Given** match_start_time_ms = 5000, server_time_ms = 5100, MAX_REWIND_MS = 150
**And** clientTimestamp = 4500 (forged — predates match start)
**When** rewind is computed: `clamp(5100 - 4500, 0, min(150, 5100 - 5000))`
        `= clamp(600, 0, min(150, 100)) = clamp(600, 0, 100) = 100ms`
**Then** rewind_ms == 100 (not 600; capped at elapsed match time)

**Pass**: rewind_ms == 100.

---

### AC-12: Projectile Continues After Owner Elimination — Posthumous Kill Attribution

**Given** Player A fires a projectile at tick T
**And** Player A is eliminated at tick T+1
**And** the projectile has not yet hit its target or traveled max range
**When** tick T+2 simulation runs
**Then** the projectile is still in `active_projectiles`
**And** if the projectile hits Player B at tick T+2, damage is applied
**And** the resulting `elimination_event` (if Player B is eliminated) has `killerId = Player A`

**Pass**: projectile survives owner elimination; posthumous kill correctly attributed.

---

### AC-13: Obstacle Destroyed Mid-Tick — Collision Boundary Update Deferred

**Given** a destructible obstacle at (5.0, 0.0) with current_hp = 1
**And** a character moving toward the obstacle in tick T (movement resolved in step 3a)
**And** an ability hits the obstacle in step 3g of tick T, reducing its HP to 0
**When** tick T simulation completes
**Then** the character's movement in tick T was blocked by the obstacle (pre-destruction layout)
**And** `obstacle_destroyed` event is emitted for tick T
**And** at tick T+1, the obstacle is absent from the collision map; the character can pass through

**Pass**: obstacle collision active in tick T; absent in tick T+1.

---

### AC-14: Basic Attack Cooldown Enforcement

**Given** a character with effective_attack_speed = 1.5 attacks/sec
**And** cooldown interval = floor(20 / 1.5) = 13 ticks
**And** last_attack_tick = 100
**When** a BASIC_ATTACK arrives at tick 112 (100 + 12 — one tick early)
**Then** the attack is rejected (112 < 113)
**When** a BASIC_ATTACK arrives at tick 113 (100 + 13 — exactly on cooldown expiry)
**Then** the attack is accepted (113 ≥ 113)

**Pass**: tick 112 rejected; tick 113 accepted.

---

### AC-15: Soft Cover Speed Reduction

**Given** a character with effective_move_speed = 5.0 LGU/s, no status effects, no cast in progress
**And** the character's position center is inside a soft cover region
**And** joystick input is (1.0, 0.0) (full right)
**When** movement is resolved for one tick
**Then** delta_position.x = 1.0 * 5.0 * 0.65 * 0.05 = 0.1625 LGU
        (not 0.25 LGU which would be without soft cover)

**Pass**: position delta.x == 0.1625.

---

### AC-16: Wall-Slide — Character Slides Along Vertical Wall

**Given** a character with delta_pos = (0.3, 0.2) attempting to move into a vertical wall at their right
**And** the wall's outward normal is (-1, 0) (wall face is vertical, blocking rightward movement)
**When** wall-slide decomposition is applied
**Then** perp_component = (0.3, 0) (rightward motion, cancelled)
**And** slide_component = (0, 0.2) (upward motion, preserved)
**And** the character's position updates by (0, 0.2) — slides along the wall

**Pass**: new position = old_position + (0, 0.2); no penetration of obstacle.

---

### AC-17: Zone Damage Can Eliminate a Player

**Given** a player outside the zone boundary with current_hp = 0.5
**And** zone_damage_per_tick = 0.75 (no SHIELDED, not in soft cover)
**When** one tick of zone damage is applied
**Then** current_hp = max(0, 0.5 - 0.75) = 0
**And** `elimination_event` is emitted with `killerId = null` and `cause = "ZONE"`
**And** the player is removed from the active simulation list

**Pass**: zone damage kills player; elimination event emitted; `killerId` is null.

---

*End of Combat System GDD — Version 1.1 Draft*
