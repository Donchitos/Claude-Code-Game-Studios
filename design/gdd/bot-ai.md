# Bot / Fallback AI — Game Design Document
> **System**: Bot / Fallback AI
> **Priority**: VS
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

### What This System Owns

The Bot / Fallback AI system provides server-side artificial opponents that fill empty player slots in 8-player FFA matches. It owns exactly three concerns:

**Bot Agent Execution** — Each bot is an autonomous server-side agent that runs a deterministic state machine each game tick. The bot reads the authoritative `MatchState`, computes a desired action (move direction, ability activation, or no action), and submits that action through the same input pipeline that human players use. From the Match Server's perspective, a bot input is structurally identical to a human input — the same validation rules, ownership checks, and rate limits apply.

**Bot Identity and Fill Trigger** — Bots have display names in the format `BOT_{CharacterName}` (e.g., `BOT_Vex`, `BOT_Zook`). They are never disguised as human players. The fill trigger is invoked by two callers: the Matchmaking Engine (thin FFA queue at timeout with `botFillEnabled = true`) and the Disconnect Handler (FFA player disconnects mid-match with `botFillEnabled = true`). In both cases the caller creates a bot stub entry and the Bot AI system attaches an agent to that entry when the match session initializes.

**Bot Difficulty Profiles** — Two difficulty tiers exist at MVP: Easy and Medium. Hard bots are explicitly out of scope to avoid frustrating new players in their first bot-padded matches. The difficulty tier for a given match is selected by Remote Config and applies uniformly to all bots in that match.

### Execution Model

Bot agents run on the game server process, not in a separate service. Each bot instance is created at match initialization (immediately after the Session Manager calls `MatchConfig`), lives for the duration of the match, and is discarded when `match_ended` fires. No bot state is persisted. Bots receive the same `MatchState` reference the Match Server advances each tick; no separate AI tick loop exists — the bot agent is called once per game tick inside the simulation phase after all human inputs are processed.

### Scope at VS

**FFA only.** Bot fill for 1v1 Duel and 3v3 Squad Brawl is explicitly deferred to post-VS. Squad Brawl requires team-aware AI (target priority that considers ally positioning, coordinated pushes, role-based behavior). Duel bots require near-human skill calibration to avoid being trivially exploitable or oppressively difficult in a 1v1 skill test context. Neither is appropriate for the VS milestone.

---

## 2. Player Fantasy

### The Promise

When a player queues for FFA on a quiet evening and the lobby fills to only five humans, bot fill means they get to play their match. The bots make the lobby feel alive — they move, they fight, they get eliminated and appear in the kill feed, they die to the zone like everyone else. The player's core question — "Am I good enough to win this?" — is still answerable, because bots are beatable but not passive targets.

### What Good Bots Feel Like

A well-designed Easy bot feels like a newer player: it reacts a half-second late, it occasionally misses with an ability, it does not perfectly kite the zone. A Medium bot feels like a competent-but-predictable casual player: present, accurate, aware of danger, but readable. Neither tier should feel like a script — small random variations in waypoint selection and ability timing prevent bots from following perfectly telegraphable patterns.

The critical success condition: a player who wins a bot-padded FFA should feel they earned the win through skill, not that they simply farmed AI. A player who loses to a bot should feel embarrassed, not robbed — because losing to a bot should only happen if the human player made significantly worse decisions.

### What Bots Are NOT

Bots are not hidden fake humans. The `(Bot)` indicator appears next to every bot's name in the HUD and elimination feed. Players have the right to know when they are facing AI. Trust is more important than the illusion of a full human lobby.

Bots are not punching bags. An Easy bot that stands still and takes damage would inflate kill stats without providing meaningful opposition. Bots must close to combat range and use abilities — the challenge target is "a human who is not trying very hard," not "a stationary dummy."

Bots are not in 1v1 or Squad Brawl. The scope boundary is firm at VS. Any pressure to extend bot fill to Duel or Squad must be evaluated as a separate design decision in a future GDD revision.

---

## 3. Detailed Rules

### 3.1 Bot Architecture

Each bot is represented by a `BotAgent` instance created during match initialization. It is associated with one `PlayerState` slot in `MatchState` (the slot whose `playerId` begins with `"bot-"`).

```typescript
interface BotAgent {
  playerId: string;             // "bot-<uuid>"; matches the MatchConfig player entry
  slotIndex: number;            // Matches the MatchConfig slot
  characterId: string;          // Assigned at fill time
  difficultyTier: "easy" | "medium";
  currentState: BotStateId;
  waypointX: number;            // Current movement target in LGU
  waypointY: number;
  waypointUpdatedAtMs: number;  // Server clock ms when current waypoint was set
  reactionCooldownRemainingMs: number;  // Counts down; bot ignores new threats while > 0
  lastEnemySeenPlayerId: string | null; // Target currently tracked in ENGAGING
  pendingInputs: {              // Queued inputs to be submitted this tick
    move: InputMove | null;
    ability: InputAbility | null;
  };
}

type BotStateId = "ROAMING" | "ENGAGING" | "RETREATING" | "USING_ABILITY" | "DEAD";
```

The `BotAgent` is owned by the Match Server process. It does not exist outside of an active match. On `match_ended`, all `BotAgent` instances in that match are garbage-collected.

---

### 3.2 Bot State Machine

The bot operates as a five-state machine. States are evaluated and potentially transitioned once per game tick (20 Hz, 50ms/tick).

```
                     ┌──────────────────────────────────────┐
                     │         Any State → DEAD             │
                     │     (hp reaches 0)                   │
                     └──────────────────────────────────────┘

  ┌───────────┐    enemy within      ┌──────────────┐
  │  ROAMING  │ ──ENGAGE_RANGE──────▶│   ENGAGING   │
  │           │◀── no enemies nearby─│              │
  └───────────┘    AND hp recovered  └──────┬───────┘
                                            │
                          hp < RETREAT_HP   │  ability ready AND
                          _THRESHOLD        │  target in range AND
                                 │          │  probability check passes
                                 ▼          ▼
                          ┌─────────────────────────┐
                          │      RETREATING         │
                          └─────────────────────────┘
                                       │
                          hp recovered OR no enemies nearby
                                       │
                                       ▼
                                  ROAMING

                          ┌─────────────────────────┐
                          │      USING_ABILITY       │
                          │  (single-tick state;     │
                          │   returns to ENGAGING    │
                          │   after ability fired)   │
                          └─────────────────────────┘
```

#### State: ROAMING

The bot has no active threat target. It moves toward the zone center with randomized waypoint variation to avoid perfectly predictable circular paths.

**Behavior each tick:**
1. If outside zone: set waypoint to zone center (overrides random waypoint). Move at full speed toward center.
2. If inside zone: check if `(serverNow - waypointUpdatedAtMs) >= WAYPOINT_UPDATE_MS`. If so, compute a new random waypoint (see §4.2 Waypoint Selection Formula). Move toward current waypoint.
3. Submit `InputMove` toward waypoint direction.
4. Do not submit any ability input while ROAMING.

**State transition check (evaluated after behavior):**
- Scan all `PlayerState` entries in `MatchState` where `isAlive === true` and `playerId` does not match this bot's `playerId`.
- Exclude any `PlayerState` where the player is in INACTIVE status (disconnected slot awaiting bot fill — detected via a dedicated flag on `PlayerState`: `isInactive: boolean`).
- If any eligible enemy's `position` is within `ENGAGE_RANGE_LGU` of this bot's `position` AND `reactionCooldownRemainingMs <= 0` → transition to ENGAGING, set `lastEnemySeenPlayerId` to the nearest eligible enemy.
- Decrement `reactionCooldownRemainingMs` by `TICK_INTERVAL_MS` each tick (clamp to 0).

---

#### State: ENGAGING

The bot has a target enemy and is closing to attack range.

**Behavior each tick:**
1. Verify `lastEnemySeenPlayerId` is still alive (`isAlive === true`) in `MatchState`. If not, find the next nearest alive enemy within `ENGAGE_RANGE_LGU`. If none found, transition to ROAMING.
2. Compute direction vector from bot position to target enemy position.
3. Submit `InputMove` toward target enemy.
4. If target is within `attackRange` (from this bot's character definition): submit an implicit auto-attack by orienting the move input toward the target. (Note: auto-attack is a Move input aligned to the enemy — Combat System evaluates melee range as part of simulation. The bot does not submit a separate "attack" input; it closes distance and lets the Combat System resolve contact damage at the correct range.)
5. Run ability check: if `reactionCooldownRemainingMs <= 0` AND any ability in bot's deck has `abilityCooldowns[abilityId] === 0` (or absent, meaning not on cooldown) AND target is within ability's effective range AND `Math.random() < ABILITY_USE_PROBABILITY` → transition to USING_ABILITY for this tick.

**State transition checks:**
- If bot HP < `RETREAT_HP_THRESHOLD_PCT * maxHp` → transition to RETREATING.
- If ability check above passes → transition to USING_ABILITY.
- If target moves outside `ENGAGE_RANGE_LGU * 1.5` (extended disengage range to prevent ping-pong between states) AND no other enemy within `ENGAGE_RANGE_LGU` → transition to ROAMING.

---

#### State: RETREATING

The bot is damaged and is fleeing toward zone center to recover.

**Behavior each tick:**
1. Compute direction vector from bot position toward zone center.
2. Submit `InputMove` toward zone center (away from threat).
3. Ability check for defensive abilities: if any ability in deck has `type === "defensive"` OR `type === "utility"` (heal, shield, movement) AND `abilityCooldowns[abilityId] === 0` AND `Math.random() < ABILITY_USE_PROBABILITY * 2` (doubled probability for defensive use while retreating) → transition to USING_ABILITY for this tick targeting self or safe direction.

**State transition checks:**
- If bot HP recovered above `RETREAT_HP_THRESHOLD_PCT * maxHp` via a defensive ability that ticked → transition to ROAMING.
- If no enemy within `ENGAGE_RANGE_LGU * 2` (enemies have disengaged) → transition to ROAMING.
- If outside zone while retreating: zone center waypoint already overrides.

---

#### State: USING_ABILITY

A single-tick state. The bot fires a chosen ability then immediately returns to its prior state.

**Behavior this tick:**
1. Select ability using priority rules (see §3.4 Ability Selection Logic).
2. Submit `InputAbility { abilityId, targetX, targetY }`.
   - Offensive ability: `targetX/Y` = current enemy position (`lastEnemySeenPlayerId`'s position from `MatchState`).
   - Defensive ability: `targetX/Y` = bot's own position (for self-targeted abilities) or zone center direction.
3. Immediately transition back to:
   - ENGAGING if bot HP >= `RETREAT_HP_THRESHOLD_PCT * maxHp` and a target enemy is alive and nearby.
   - RETREATING otherwise.

USING_ABILITY does not block the move input for this tick — both `InputAbility` and `InputMove` can be submitted in the same tick (one of each, which is within `MAX_INPUTS_PER_TICK = 2`).

---

#### State: DEAD

The bot HP has reached 0. The bot's `PlayerState.isAlive` is `false`.

**Behavior:**
- No inputs are submitted while DEAD.
- The `BotAgent` state machine stops evaluating entirely.
- In FFA mode, eliminated players (human or bot) are not respawned. The bot remains in DEAD state until the match ends.
- The bot's elimination is processed by the Match Server's win condition evaluator identically to a human player elimination.

---

### 3.3 Difficulty Tiers

Two tiers are supported at VS MVP. The difficulty tier is set per-match via Remote Config key `botAI.difficultyTier` (default: `"easy"`). All bots in a match share the same tier.

#### Easy

| Parameter | Value | Effect |
|---|---|---|
| `REACTION_DELAY_MS` | 500ms | Bot ignores new threat arrivals for 500ms after entering ROAMING or after a state transition resets the cooldown. Implemented via `reactionCooldownRemainingMs` initialized to 500ms at each reset. |
| `ACCURACY_MISS_RATE` | 0.20 | 20% chance per attack tick that the bot's move input is deflected by a random offset angle (see §4.3 Miss Calculation). Applied only in ENGAGING state when within attack range. |
| `ABILITY_USE_PROBABILITY` | 0.05 | Per-tick probability check when ability is off cooldown and target is in range. |

#### Medium

| Parameter | Value | Effect |
|---|---|---|
| `REACTION_DELAY_MS` | 200ms | Bot is quicker to recognize and respond to nearby threats. |
| `ACCURACY_MISS_RATE` | 0.00 | No accuracy reduction. Bot faces the enemy precisely. |
| `ABILITY_USE_PROBABILITY` | 0.15 | Higher probability; bots use abilities more decisively. |

---

### 3.4 Ability Selection Logic

When the bot enters USING_ABILITY, it selects which ability to fire using the following priority:

1. **Defensive priority**: If `bot.hp < 0.5 * bot.maxHp` AND any ability in the deck has `type === "defensive"` AND its `abilityCooldowns[abilityId] === 0` → select that defensive ability.
2. **Offensive/utility priority**: Else, select the ability with the shortest `abilityId` sort order (deterministic tiebreak) that is:
   - Off cooldown (`abilityCooldowns[abilityId] === 0` or absent), AND
   - Has a range >= distance to target enemy (sourced from the ability definition's `effectRange` field in the Content Catalog).
3. **No eligible ability**: If no ability passes the checks, do not submit `InputAbility` and transition back to the previous state without entering USING_ABILITY.

The bot never attempts to use an ability that is on cooldown. The `ABILITY_USE_PROBABILITY` check gate (§3.2 ENGAGING behavior) prevents the bot from instantly firing the moment an ability comes off cooldown — the probabilistic gate distributes ability use naturally across ticks rather than snapping to cooldown expiry.

---

### 3.5 Bot Character Assignment

At fill time (Matchmaking Engine or Disconnect Handler), the bot is assigned a character using the following rules:

1. Collect all character IDs from the Character System's runtime schema registry.
2. Exclude characters already assigned to other players (human or bot) in the same match — no two participants share the same character.
3. From the remaining available characters, select one uniformly at random.
4. Assign the default loadout for that character (the `default_deck_id` defined in the Character System's content catalog entry). The bot does not use a custom deck.
5. If no characters remain after exclusion (all 8 characters assigned, and this bot would be the 9th participant — impossible in an 8-player FFA, but guarded defensively): log `WARNING: bot_character_assignment_failed — no available characters` and assign the first character in the registry regardless of duplication. This scenario should never occur in production and indicates a configuration error.

The assigned `characterId` and `deckId` are written into the bot's `MatchPlayer` entry in `MatchConfig` and passed to the Match Server identically to a human player's entry.

---

### 3.6 Bot Identity and Visibility

**Display name format**: `BOT_{CharacterName}` where `{CharacterName}` is the character's display name from the Character System (e.g., `BOT_Vex`, `BOT_Zook`, `BOT_Grim`).

**Client-side bot indicator**: The `isBot: true` flag on the player stub propagates into the `MatchState.players` entry as `isBot: boolean`. The In-Match HUD and elimination feed render a `(Bot)` suffix next to the name wherever a player name appears. Bots are never displayed without this indicator.

**Minimap visibility**: Bots appear on the minimap identically to human players — same icon, same color coding by team/free-for-all slot. There is no special minimap treatment for bots.

**Elimination feed**: When a bot is eliminated, the elimination feed entry reads:
- `"[PlayerName] eliminated BOT_{CharacterName}"` — identical to a human elimination.
- `"BOT_{CharacterName} eliminated [PlayerName]"` — if a bot kills a human.
- `"BOT_{CharacterName} eliminated BOT_{CharacterName2}"` — bot vs bot.

The `(Bot)` indicator is appended to the bot name in the elimination feed entry as well.

---

### 3.7 Bot Kill Credit

Killing a bot awards kill credit identically to killing a human player:
- The killing player receives +1 elimination (score increment in Game Mode System scoring).
- Any player who dealt damage to the bot within the assist window (`ASSIST_WINDOW_MS` from Game Mode System GDD) receives an assist credit.
- The elimination event fires through the normal `match_ended` / win condition evaluation path — bot deaths count toward FFA last-standing win condition.
- A bot kill awards the same MMR delta to human players as a human kill (see MMR/Ranked GDD §3.X). Rationale: in a bot-padded match, human players should not be penalized for their lobby composition.

---

### 3.8 Zone Awareness

Bots are subject to zone damage identically to human players — the same `zone_damage_per_sec` applies when a bot's position is outside `zone.currentRadius`.

Bot behavior while outside zone:
- In ANY state (ROAMING, ENGAGING, RETREATING): if `distance(bot.position, zone.center) > zone.currentRadius` → immediately override the current movement decision and move toward zone center at full speed. Zone avoidance overrides all other movement decisions with the sole exception: if bot is in USING_ABILITY this tick, the ability input fires and the zone-correcting move input is submitted simultaneously (both fit within `MAX_INPUTS_PER_TICK = 2`).
- The zone check is evaluated at the start of each tick's bot processing, before state logic runs.

---

### 3.9 Anti-Cheat Compliance for Bots

Bots submit inputs through the same validation pipeline as human players. The following anti-cheat rules apply to bot inputs and are enforced identically:

- **Ownership check**: bot input `playerId` must match the bot's assigned `playerId`. The bot agent always uses its assigned `playerId`; no cross-slot input is possible by design.
- **Deck membership check**: bot ability inputs only use `abilityId` values present in the bot's assigned default deck. The ability selection logic (§3.4) only selects from the bot's loaded deck by construction.
- **Rate limit**: bots submit at most 2 inputs per tick (1 move + 1 ability). They are incapable of exceeding `MAX_INPUTS_PER_SEC` by construction since they only generate one input set per game tick.
- **Staleness check**: bot inputs are generated during the tick they are applied; `timestamp` is set to `serverNow` at generation. These inputs are never stale.

No special bypass or exemption exists for bot inputs. The bot runs as a first-class participant, not a privileged internal process.

---

## 4. Formulas

### 4.1 Ability Use Probability per Tick

The probability that a bot fires an available ability in a given tick, given that all other preconditions (ability off cooldown, target in range) are satisfied:

```
P(fire_this_tick) = ABILITY_USE_PROBABILITY

Where ABILITY_USE_PROBABILITY:
  Easy tier:   0.05
  Medium tier: 0.15

Implementation:
  if (Math.random() < ABILITY_USE_PROBABILITY) → transition to USING_ABILITY

Expected ticks until ability fires (geometric distribution):
  E[ticks] = 1 / ABILITY_USE_PROBABILITY

  Easy tier:   E[ticks] = 1 / 0.05  = 20 ticks = 1000ms expected delay
  Medium tier: E[ticks] = 1 / 0.15  ≈ 6.7 ticks ≈ 333ms expected delay

At 20Hz (50ms/tick):
  Easy bot fires an available ability approximately every 1 second of target engagement.
  Medium bot fires an available ability approximately every 333ms of target engagement.
```

This models natural hesitation. It does not mean the bot waits exactly `E[ticks]` — the geometric distribution produces variance, which makes ability timing feel less scripted.

---

### 4.2 Reaction Delay Implementation

The reaction delay is implemented as a countdown variable `reactionCooldownRemainingMs` on the `BotAgent`.

```
On state reset or match start:
  reactionCooldownRemainingMs = REACTION_DELAY_MS

Per tick decrement:
  reactionCooldownRemainingMs = max(0, reactionCooldownRemainingMs - TICK_INTERVAL_MS)

Threat detection guard:
  if (reactionCooldownRemainingMs > 0):
    skip enemy detection scan; remain in ROAMING
  else:
    perform enemy detection scan as normal

REACTION_DELAY_MS:
  Easy tier:   500ms → cooldown ticks from 500ms to 0 over 10 ticks before bot can react
  Medium tier: 200ms → cooldown ticks from 200ms to 0 over 4 ticks before bot can react

The reaction delay is reset to REACTION_DELAY_MS:
  1. On bot initialization (match start).
  2. When the bot transitions FROM ENGAGING or RETREATING back to ROAMING.
  3. On respawn — not applicable in FFA (no respawn); included for future mode compatibility.
```

---

### 4.3 Accuracy Miss Calculation (Easy Tier Only)

When the Easy bot is in ENGAGING state and within `attackRange` of its target, a miss check is applied to its move input direction:

```
Variables:
  dx_true, dy_true = normalized direction vector from bot position to enemy position
  ACCURACY_MISS_RATE = 0.20 (Easy only; Medium = 0.00)

Per-attack-tick miss check:
  if (Math.random() < ACCURACY_MISS_RATE):
    missAngleDeg = random_element([-45, -30, -20, 20, 30, 45])  // six fixed deviation options
    dx_submitted = dx_true * cos(missAngleDeg) - dy_true * sin(missAngleDeg)
    dy_submitted = dx_true * sin(missAngleDeg) + dy_true * cos(missAngleDeg)
    Normalize (dx_submitted, dy_submitted) to unit vector
  else:
    dx_submitted = dx_true
    dy_submitted = dy_true

Submit InputMove { dx: dx_submitted, dy: dy_submitted, ... }

Notes:
  - missAngleDeg is drawn uniformly from the fixed set; this avoids continuous random drift
    and keeps miss behavior predictable for design tuning.
  - The miss is a direction deflection only — the bot still moves, just not perfectly at the target.
  - Medium bots always submit dx_true/dy_true (ACCURACY_MISS_RATE = 0.00; no miss check needed).
```

---

### 4.4 Waypoint Selection Formula

Used in ROAMING state when `(serverNow - waypointUpdatedAtMs) >= WAYPOINT_UPDATE_MS`:

```
Variables:
  zoneCenter     = { x: zone.centerX, y: zone.centerY }
  zone.currentR  = zone.currentRadius (in LGU)
  WAYPOINT_INSET = 0.15  // fraction of current zone radius to stay away from boundary
  safeR          = zone.currentR * (1.0 - WAYPOINT_INSET)

Waypoint generation:
  angle  = Math.random() * 2 * Math.PI                   // uniform random angle
  radius = Math.random() * safeR                         // uniform random radius up to safeR

  waypointX = zoneCenter.x + radius * Math.cos(angle)
  waypointY = zoneCenter.y + radius * Math.sin(angle)

  waypointUpdatedAtMs = serverNow

Notes:
  - safeR uses the current zone radius minus inset, so bots automatically roam
    in a shrinking area as the zone collapses. No separate zone-tracking logic needed
    for roaming — the waypoint formula inherits zone state naturally.
  - A uniform random angle + radius generates a uniform distribution across the
    circular zone area (no pole-clustering artifact because radius is drawn uniformly,
    not from a Gaussian).
  - WAYPOINT_INSET prevents bots from being assigned a waypoint exactly at the zone edge
    where any minor zone movement would immediately put them outside.
  - If the bot is currently outside the zone, the zone-override behavior in §3.8 takes
    precedence; the random waypoint is not used.
```

---

### 4.5 Bot Fill Count

The number of bots added to fill a match:

```
bots_to_add = MATCH_SIZE - human_count_in_match

Where MATCH_SIZE = 8 (FFA)

Called by:
  Matchmaking Engine (pre-match):
    human_count_in_match = number of humans in FFA queue at bot-fill trigger

  Disconnect Handler (mid-match):
    human_count_in_match = current live (non-DEAD, non-INACTIVE) human slots
    bots_to_add = 1 per disconnect event (one bot per departed player slot,
                  capped so total participants never exceed MATCH_SIZE)
```

---

## 5. Edge Cases

### EC-01: Human Player Reconnects Within Grace Period After Bot Fill

**Scenario**: A human player disconnects mid-FFA, `botFillEnabled = true`, and a bot fills their slot after `BOT_FILL_DELAY_MS`. Before the match ends, the human player reconnects within the Reconnect Handler's grace period (`RECONNECT_GRACE_PERIOD_S = 30s`).

**Handling**:
1. The Disconnect Handler detects the reconnect (see Disconnect Handler GDD §EC-X).
2. The bot occupying the reconnecting player's logical slot is immediately eliminated with `hp = 0`. This triggers the normal elimination path in the Match Server simulation.
3. The elimination is marked with `reason: "bot_replaced_by_human"` in the match event log.
4. **No kill credit is awarded** for this elimination. The bot's death does not increment any human player's kill count. The Match Server emits the elimination event with `killCredit: false`.
5. The human player's `PlayerState` slot is restored: HP is reset to `maxHp * BOT_REPLACED_HP_FRACTION` (default: 0.50 — the player returns at half health as a penalty for the disconnect). Cooldowns are cleared.
6. The Bot AI system destroys the `BotAgent` instance for that slot.
7. The human player receives a full `state_snapshot` on reconnect (per Match Server GDD §3.7).

**Key constraint**: the bot's elimination must generate no kill credit. If the bot were in the process of attacking an enemy when the reconnect fires, the ongoing `ENGAGING` tick that the bot started must be completed before the bot is removed (within the same server tick — the removal is processed as a post-tick cleanup, not mid-tick).

---

### EC-02: All Human Players Disconnect — Only Bots Remain

**Scenario**: All human players disconnect from an FFA match that contains bots. The bots continue running but there are no human observers.

**Handling**:
1. The Match Server detects all human player sockets as disconnected.
2. After `ALL_PLAYERS_DISCONNECTED_GRACE_MS` (5000ms) with no human reconnects, the Match Server emits `match_abandoned { reason: "all_players_disconnected" }` to the Session Manager (per Match Server GDD §5.2).
3. **The match is abandoned. No winner is declared.** Bots do not generate a match result.
4. No MMR delta is applied (abandoned match rule — Match Flow GDD).
5. All `BotAgent` instances are discarded.

**Rationale**: Bots exist to serve human players, not to play matches in their absence. A bot-only match result is meaningless and must not be treated as a valid outcome.

---

### EC-03: Bot Assigned a Character With Complex Passive State Tracking

**Scenario**: The randomly assigned character (e.g., `character:colt` with `chargedStacks` passive state) has a passive ability that requires per-tick state tracking.

**Handling**:
1. At match initialization, the Match Server calls `Character System.getInitialPassiveState(characterId)` for the bot's slot identically to a human player slot.
2. The bot's `PlayerState.passiveState` is initialized with the correct initial structure.
3. Each tick, Phase 3 (Simulation) calls `Character System.tickPassive(passiveState, tickContext)` for all alive players including the bot — no distinction is made.
4. The bot benefits from (or is subject to) its passive ability exactly as a human player would be. The bot AI is not aware of passive state — it only reads `hp`, `abilityCooldowns`, and enemy positions when making decisions. Passive effects that alter HP or cooldowns are naturally observed by the bot on the next tick.

**No special handling is needed.** The passive state machine runs identically for bots and humans.

---

### EC-04: Bot Fill Triggered But No Unoccupied Characters Available

**Scenario**: All 8 characters are already assigned to players in the match, and the Disconnect Handler triggers a new bot fill (theoretically impossible in an 8-player FFA, but guarded defensively).

**Handling**:
1. The character assignment routine (§3.5) exhausts all exclusion-filtered options and finds no available character.
2. Log `WARNING: bot_character_assignment_failed — all characters assigned; assigning duplicate` with `{ matchId, slotIndex }`.
3. Assign the first character in the registry as a fallback. The bot will share a character identity with another player — this is a known visual oddity but is preferable to a failed match.
4. This scenario is architecturally impossible in a correctly configured 8-player FFA (8 players, 8 characters) and indicates a configuration error. The warning log should trigger an operational alert for investigation.

---

### EC-05: `botFillEnabled` Remote Config Pushed to `false` Mid-Match

**Scenario**: While a bot-padded FFA match is in progress, the Remote Config value `matchmaking.botFillEnabled` is updated from `true` to `false` via a live push.

**Handling**:
1. Bots already in the match continue to run for the duration of the match. The config change does not remove or disable in-flight bots.
2. `botFillEnabled` is a Cold Remote Config key — it is not re-read during an active match session. Even if it were Hot, the design intent is that config changes affect new matches only.
3. The Disconnect Handler reads `botFillEnabled` at the time a disconnect event fires. If the flag has been pushed to `false` by then, a new bot fill will NOT be triggered for that disconnect — the slot remains empty (INACTIVE) rather than receiving a bot.
4. No in-match notification is sent to players when `botFillEnabled` changes. This is invisible to players in a running match.

---

### EC-06: Bot Receives a Stale Waypoint Outside the Shrunken Zone

**Scenario**: A bot in ROAMING state has a waypoint computed inside the zone when the waypoint was last set. By the time the bot reaches the waypoint or the next `WAYPOINT_UPDATE_MS` interval fires, the zone has shrunk and the waypoint is now outside the current zone boundary.

**Handling**:
1. The zone check in §3.8 runs at the start of each tick, before state logic. If the bot's current position is outside the zone, it immediately redirects to zone center.
2. The stale waypoint is effectively ignored until the next `WAYPOINT_UPDATE_MS` interval triggers a fresh waypoint draw using the current `zone.currentRadius` (which incorporates the shrinkage).
3. The new waypoint will be drawn within `safeR = zone.currentRadius * (1.0 - WAYPOINT_INSET)` which correctly reflects the shrunken zone.
4. No special recovery is needed — the zone override in step 1 handles the transition gracefully.

---

### EC-07: Two Bots Target the Same Enemy Simultaneously

**Scenario**: Multiple bots in a match all transition to ENGAGING against the same human player target, creating a converging pile-on.

**Handling**:
This is intentional behavior at the current AI fidelity level. Bots each independently select the nearest visible enemy, which can result in multiple bots targeting the same human. The following mitigations are in place:

1. The `ENGAGE_RANGE_LGU` limits how far away bots scan for enemies — bots that are far apart will typically not share the same nearest enemy.
2. Easy bots' `REACTION_DELAY_MS = 500ms` staggers initial engagement timing, naturally distributing attack timing.
3. Post-VS hardening (not in scope for MVP): a bot coordination system that distributes targets using match-global state. Deferred to post-VS.

The pile-on behavior is acceptable at VS fidelity — in FFA, humans frequently focus one opponent anyway. The bot behavior mirrors natural human patterns.

---

## 6. Dependencies

### 6.1 Upstream Dependencies (Bot AI Consumes)

| System | Data / Interface Used | Coupling Notes |
|---|---|---|
| **Character System** | `CharacterDefinition` (base stats, attack range, passive ability); `getInitialPassiveState(characterId)`; default deck loading via `deckId`; all ability definitions via Content Catalog. | Read at match initialization. Bot uses the same character data path as human players. No special bot-specific character API. |
| **Match Server** | Authoritative `MatchState` read each tick (player positions, HP, cooldowns, zone state); input submission pipeline (`InputMove`, `InputAbility`); tick scheduling (bot agent called once per simulation tick). | Bot agent is an in-process module of the Match Server. It reads `MatchState` by reference — no copy or serialization overhead. Input submission calls the same `enqueueInput(playerId, input)` function as the Socket.io handler. |
| **Disconnect Handler** | Triggers `BotAgent` creation for a disconnected FFA slot after `BOT_FILL_DELAY_MS`. Passes the bot's `playerId`, `slotIndex`, `characterId`, `deckId` to the Session Manager's match update path. | The Disconnect Handler creates the bot stub; the Bot AI system instantiates the `BotAgent` from that stub. |
| **Remote Config** | `botAI.difficultyTier` (Cold — read at match start, locked for match duration). `matchmaking.botFillEnabled` (Cold — read by Matchmaking Engine and Disconnect Handler before triggering bot fill; not re-read by Bot AI system mid-match). | Bot AI reads difficulty tier once at match initialization and caches it on all `BotAgent` instances for that match. |
| **Content Catalog** | Ability definitions (effect type, effective range, `type` field for defensive vs. offensive classification). Read via Character System's data path. | Required for ability selection logic (§3.4). The `type` and `effectRange` fields on ability definitions must be populated for bot ability selection to work. |

### 6.2 Downstream Dependents (Consume Bot AI)

| System | How It Consumes Bot AI | Notes |
|---|---|---|
| **Matchmaking Engine** | Creates bot stubs (`{ playerId: "bot-<uuid>", mmr: avg_human_mmr, isBot: true }`) and passes them to Session Manager's `createSession` call. The Bot AI system attaches agents to these stubs when the Match Server initializes. | Matchmaking Engine does not call Bot AI directly. The linkage is through the `MatchConfig.players` array — the Match Server's initialization step detects `isBot: true` slots and instantiates `BotAgent` instances. |
| **Disconnect Handler** | Calls the Bot AI system's `createBotForSlot(slotIndex, matchId)` API after `BOT_FILL_DELAY_MS` to fill a vacated FFA slot mid-match. | Bot AI exposes a `createBotForSlot` function that the Disconnect Handler calls. The function performs character assignment (§3.5), creates the `BotAgent`, and inserts it into the active match's bot registry. |
| **Match Flow** | Receives bot elimination events from the Match Server's win condition path identically to human eliminations. Bot deaths are counted by the Game Mode System's elimination handler (score increments, win condition evaluation). | Match Flow is not aware of whether an elimination was a human or a bot — it receives the `WinConditionResult` and `finalState` from Match Server. The `isBot` flag on `PlayerState` is available for post-match analytics. |
| **In-Match HUD** | Reads `PlayerState.isBot` to render `(Bot)` indicator next to bot player names. Reads bot name (display format: `BOT_{CharacterName}`) from `PlayerState`. | HUD client-side rendering concern — Bot AI does not call HUD. HUD reads from `MatchState` as delivered via `state_delta` / `state_snapshot`. |
| **Analytics / Telemetry** | Match Flow emits analytics events that include `isBot` flags on player entries. Bot elimination events, bot survival time, and bot damage dealt are captured in the same event stream as human data. | Enables A/B testing of bot difficulty tiers and measurement of how bot presence affects human engagement (queue fill rate, retention). |

---

## 7. Tuning Knobs

All constants in the `botAI.*` namespace are Remote Config (Cold) unless marked as code constants. Code constants require a deployment to change.

| Knob | Config Key / Location | Default | Safe Range | What It Affects |
|---|---|---|---|---|
| `ENGAGE_RANGE_LGU` | Code constant | 15.0 LGU | 8–25 LGU | Distance at which a bot detects and engages an enemy. Lower = bot only notices close-range threats (less aggressive); higher = bot chases enemies across much of the arena (more aggressive). |
| `RETREAT_HP_THRESHOLD_PCT` | `botAI.retreatHpThresholdPct` | 0.25 (25%) | 0.10–0.40 | HP fraction at which bot retreats. Lower = bot fights longer before retreating; higher = bot retreats frequently (making it feel very defensive). |
| `WAYPOINT_UPDATE_MS` | Code constant | 2000ms | 500–5000ms | How often the bot generates a new roaming waypoint. Lower = more erratic movement; higher = bots move in long straight lines (predictable). |
| `WAYPOINT_INSET` | Code constant | 0.15 | 0.05–0.30 | Fraction of zone radius kept as inset for waypoint selection. Higher = bots stay well inside zone; lower = bots risk edge proximity. |
| `ABILITY_USE_PROBABILITY` (Easy) | `botAI.abilityUseProbabilityEasy` | 0.05 | 0.01–0.20 | Per-tick probability that an Easy bot fires an off-cooldown ability. Higher = more frequent ability use. |
| `ABILITY_USE_PROBABILITY` (Medium) | `botAI.abilityUseProbabilityMedium` | 0.15 | 0.05–0.40 | Per-tick probability for Medium bot. Higher = more decisive ability use. |
| `REACTION_DELAY_MS` (Easy) | `botAI.reactionDelayMsEasy` | 500ms | 200–1000ms | How long before an Easy bot detects a nearby threat. Higher = bot feels slower to react. |
| `REACTION_DELAY_MS` (Medium) | `botAI.reactionDelayMsMedium` | 200ms | 100–500ms | Reaction delay for Medium bot. |
| `ACCURACY_MISS_RATE` (Easy) | `botAI.accuracyMissRateEasy` | 0.20 | 0.00–0.50 | Fraction of attack ticks where the Easy bot aims with a deflected direction. Higher = bot misses more often. |
| `BOT_FILL_DELAY_MS` | Owned by Disconnect Handler GDD | 5000ms | 1000–15000ms | Delay between player disconnect and bot fill trigger. Owned by Disconnect Handler; documented here for reference. |
| `BOT_REPLACED_HP_FRACTION` | `botAI.replacedHpFraction` | 0.50 | 0.25–1.00 | HP fraction at which a human player's slot is restored upon reconnect after bot fill. Lower = greater penalty for disconnecting. |
| `difficultyTier` | `botAI.difficultyTier` | `"easy"` | `"easy"`, `"medium"` | Sets difficulty tier for all bots in new matches. Change only takes effect on new matches (Cold key). |

---

## 8. Acceptance Criteria

All criteria are written as Given/When/Then. Each maps to an automated or manual test.

### AC-BOT-01: State Machine — ROAMING to ENGAGING Transition [automated]

```
GIVEN an FFA match contains a bot in ROAMING state
AND an enemy human player moves to within ENGAGE_RANGE_LGU of the bot
AND the bot's reactionCooldownRemainingMs has counted down to 0

WHEN the next bot AI tick runs

THEN the bot transitions to ENGAGING state
AND lastEnemySeenPlayerId is set to the nearby enemy's playerId
AND the bot submits an InputMove directed toward the enemy
```

---

### AC-BOT-02: State Machine — ENGAGING to RETREATING Transition [automated]

```
GIVEN a bot is in ENGAGING state
AND the bot's current HP is simulated to drop below RETREAT_HP_THRESHOLD_PCT * maxHp

WHEN the bot AI tick runs

THEN the bot transitions to RETREATING state
AND the submitted InputMove direction is away from the enemy (toward zone center)
AND no offensive ability is submitted this tick (unless a defensive ability is available)
```

---

### AC-BOT-03: State Machine — RETREATING to ROAMING Transition [automated]

```
GIVEN a bot is in RETREATING state
AND all enemy players have moved beyond ENGAGE_RANGE_LGU * 2 from the bot

WHEN the bot AI tick runs

THEN the bot transitions to ROAMING state
AND reactionCooldownRemainingMs is reset to REACTION_DELAY_MS for the bot's difficulty tier
```

---

### AC-BOT-04: ROAMING Zone Awareness — Bot Inside Zone [automated]

```
GIVEN a bot is in ROAMING state
AND the bot's position is within zone.currentRadius

WHEN WAYPOINT_UPDATE_MS has elapsed since the last waypoint update

THEN a new waypoint is generated within safeR = zone.currentRadius * (1 - WAYPOINT_INSET)
AND waypointX and waypointY fall within the zone boundary
AND the bot's submitted InputMove is directed toward the new waypoint
```

---

### AC-BOT-05: ROAMING Zone Awareness — Bot Outside Zone Moves to Center [automated]

```
GIVEN a bot in any non-DEAD state
AND the bot's position is outside zone.currentRadius

WHEN the bot AI tick runs

THEN the bot's InputMove is directed toward zone.centerX, zone.centerY
AND this zone-correcting move overrides any other movement decision
```

---

### AC-BOT-06: ENGAGING Attack Behavior Within Attack Range [automated]

```
GIVEN a bot is in ENGAGING state
AND the bot's position is within attackRange of its target enemy
AND the difficulty tier is Medium (ACCURACY_MISS_RATE = 0.00)

WHEN the bot AI tick runs

THEN the submitted InputMove dx and dy are the normalized direction toward the enemy
AND the direction error (angle between submitted vector and true direction) is 0 degrees
```

---

### AC-BOT-07: Easy Bot Miss Rate [automated — statistical]

```
GIVEN a bot is in ENGAGING state with Easy difficulty
AND the bot is within attackRange of its target for 1000 consecutive ticks

WHEN the submitted InputMove dx/dy vectors are compared to the true aim direction

THEN approximately 20% (±5% statistical tolerance over 1000 samples) of submitted vectors
     deviate from the true aim direction by a nonzero angle
AND all deviating vectors use angles from the set { -45, -30, -20, 20, 30, 45 } degrees
```

---

### AC-BOT-08: Bot Labelling — Display Name Format [manual / automated]

```
GIVEN a bot is assigned character "character:vex" (display name "Vex")

WHEN the bot's PlayerState is serialized into MatchState

THEN PlayerState.displayName === "BOT_Vex"
AND PlayerState.isBot === true
AND the In-Match HUD renders "(Bot)" next to "BOT_Vex" in the player list
AND the elimination feed shows "BOT_Vex (Bot)" in elimination entries
```

---

### AC-BOT-09: Kill Credit — Killing a Bot Awards Score [automated]

```
GIVEN a human player eliminates a bot in an FFA match

WHEN the Match Server processes the elimination event

THEN the human player's score increments by 1 (elimination credit)
AND any player who damaged the bot within ASSIST_WINDOW_MS receives an assist credit
AND the bot's elimination is counted toward the FFA win condition (alive player count decrements)
```

---

### AC-BOT-10: Human Reconnect — Bot Removed, No Kill Credit [automated]

```
GIVEN a human player disconnected from FFA
AND a bot was inserted to fill their slot (bot is alive, in ENGAGING state)
AND the human player reconnects within RECONNECT_GRACE_PERIOD_S

WHEN the Disconnect Handler processes the reconnect

THEN the bot's HP is set to 0 (eliminated)
AND the elimination event for the bot has killCredit = false
AND no human player's kill count increments
AND the human player's PlayerState slot is restored with HP = maxHp * BOT_REPLACED_HP_FRACTION
AND the BotAgent instance for that slot is destroyed
```

---

### AC-BOT-11: All Humans Disconnect — Match Abandoned, No Bot Winner [automated]

```
GIVEN an FFA match contains 4 human players and 4 bots
AND all 4 human players disconnect
AND no human player reconnects within ALL_PLAYERS_DISCONNECTED_GRACE_MS

WHEN ALL_PLAYERS_DISCONNECTED_GRACE_MS elapses

THEN the Match Server emits match_abandoned { reason: "all_players_disconnected" }
AND no match_ended signal is emitted with a winner
AND no MMR delta is applied to any human player
AND all BotAgent instances are discarded
```

---

### AC-BOT-12: Difficulty Tier Differences — Measurable in Reaction Time [automated]

```
GIVEN two otherwise identical FFA matches:
  Match A: all bots are Easy tier (REACTION_DELAY_MS = 500ms)
  Match B: all bots are Medium tier (REACTION_DELAY_MS = 200ms)

WHEN a human player enters ENGAGE_RANGE_LGU of a bot in each match
AND the tick count until the bot transitions to ENGAGING is measured

THEN Match A bots transition to ENGAGING after an average of 10 ticks (500ms ÷ 50ms)
AND Match B bots transition to ENGAGING after an average of 4 ticks (200ms ÷ 50ms)
AND the difference (6 ticks = 300ms) is statistically significant across 100 trials
```

---

### AC-BOT-13: Difficulty Tier Differences — Measurable in Average Survival Time [manual / playtest]

```
GIVEN two cohorts of 10 human players each playing bot-padded FFA matches:
  Cohort A: matches use Easy tier bots
  Cohort B: matches use Medium tier bots

WHEN average survival time (seconds from match start to first elimination) is measured
     across 20 matches per cohort

THEN Cohort A average survival time is at least 10 seconds lower than Cohort B
     (Easy bots are eliminated faster because they miss more and use abilities less)
AND no human player reports feeling that Medium bots are unfairly overpowered
     (exit survey: < 20% of Cohort B players rate bots as "too hard" on 5-point scale)
```

---

### AC-BOT-14: Anti-Cheat — Bot Cannot Submit Ability Outside Its Deck [automated]

```
GIVEN a bot is assigned character "character:vex" with default deck containing only
      abilities ["ability_dash", "ability_shockwave"]

WHEN the bot's USING_ABILITY logic runs

THEN only ability IDs in { "ability_dash", "ability_shockwave" } are submitted
AND any InputAbility submitted by the bot passes the Match Server's deck membership check
AND no INVALID_ABILITY_ID security event is logged for any bot input in the match
```

---

### AC-BOT-15: Bot Inputs Routed Through Standard Pipeline [automated]

```
GIVEN a bot submits an InputMove in a given tick

WHEN the Match Server's Phase 2 (Input Validation) runs

THEN the bot's input passes ownership check (playerId matches the bot's assigned playerId)
AND the input passes staleness check (timestamp is current tick's serverNow)
AND the input passes rate check (at most 2 inputs per tick submitted by bot)
AND the bot's PlayerState.position updates identically to a human player submitting the
    same InputMove
```

---

*End of Document*
