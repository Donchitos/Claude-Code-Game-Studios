# GDD: Chase & Evasion System

**Status:** Draft  
**Layer:** Core  
**Last Updated:** 2026-05-16  
**Dependencies:** Noise System, Audio Perception System, Fear/Corruption System

---

## 1. Overview

A chase sequence is the game's highest-stakes state. When a presence-class entity or alerted enemy actively pursues the player, the game shifts from cautious exploration to acoustic crisis management. The player must evade using the same tools they use to explore — sound manipulation, terrain knowledge, and LHP misdirection — without simply running in a straight line. Chases are designed to be survivable with good decision-making and lethal with poor ones. They always have visible warnings before they begin, and they always have a defined set of escape conditions.

---

## 2. Player Fantasy

The player feels a controlled dread: they heard the warnings, they made a mistake, and now something is coming. There is a path out — there is always a path — but it requires reading audio glyphs, remembering the map, and not panicking. Surviving a chase should feel like threading a needle in the dark. Dying in a chase should feel like a consequence the player saw coming.

---

## 3. Detailed Rules

### 3.1 Chase Trigger Conditions

A chase can be triggered by:

| Condition | Notes |
|---|---|
| Presence-class entity detects Noise ≥ 20 | Most common trigger |
| Ritual failure (see Ritual GDD) | Immediate chase; no warning phase |
| Player enters a forbidden room | Room-specific flags on certain map areas |
| Player breaks a seal or binding | Also triggers presence reaction |
| Specific occult objects used inappropriately | Item-level flags |
| Active sonar used ≥ 3 times in 5 turns | Sustained noise pattern |
| Resonance Corruption reaches `corruption_chase_threshold` | Passive accumulation trigger |
| Player follows a false echo into a trap area | Map-specific condition |

A chase triggered by a presence-class entity is different from an investigation triggered by a patrol enemy. Patrols investigate and may de-escalate; presence-class entities in chase state do not de-escalate until the termination conditions are met.

### 3.2 Chase Telegraph (Warning Phase)

A chase does not begin instantly. The player receives a structured warning sequence:

| Warning Signal | Timing |
|---|---|
| Slow, thick low-frequency ripple at long range | Chase entity is "aware" — 4–6 turns before chase |
| Ripple interval shortens each turn | Entity is approaching |
| Ambient reverb in the room disappears | Entity has entered silent hunt state |
| Walls and objects begin to visually tremble | Entity is very close (1–2 rooms away) |
| Player's own audio glyphs receive an "echo answer" | Player's position is confirmed to the entity |
| Red waveform bends toward the player's direction | Chase has officially begun |

A player who recognizes the warning phase and takes evasive action may be able to avoid the chase entirely by becoming silent before the final confirmation.

### 3.3 Player Flight Options

During a chase, the player has the following tactical options:

| Action | Noise Generated | Effect | Risk |
|---|---|---|---|
| Sprint | 4 | Gains distance quickly | High noise attracts other enemies |
| Quiet walk | 1–2 | Maintains noise discipline | Slow; entity may close distance |
| Close door | 3 at door | Blocks entity's path for 1–3 turns | Door-close noise; entity may break through |
| Throw object | 4–6 at landing | Redirects entity to landing tile | Consumes item |
| Low drone sonar | 10 | Entity briefly stunned if hit (1–2 turns) | Attracts other large entities |
| Enter silence zone | 0 | Disrupts entity's acoustic tracking | Loses all audio information; player is also blind |
| Move through trap | Trap noise | Entity may be hindered | Player also takes trap effect |
| Activate seal / altar | Variable | Temporarily blocks entity | Corruption +2; may summon spirit entities |
| Climb to next floor | 0 | Ends this floor's chase entirely | Only at staircase / escape point |

Actions available during a chase use the same noise rules as normal play. The entity's pursuit logic is still LHP-based — if the player stops making noise, the entity moves toward the last confirmed position.

### 3.4 Entity Chase Behavior

Presence-class entities during a chase:

- Move toward the player's last confirmed audio position, not the player's true position.
- Each turn the player makes noise, the entity's LHP updates.
- If the player stays silent for `entity_lose_threshold` consecutive turns, the entity slows and begins a search pattern around the last LHP.
- During search, the entity's audio sensitivity doubles — small noises the player would normally make safely will re-confirm the LHP.
- Presence entities cannot be killed during a chase. Combat against them deals no meaningful damage and generates additional noise.

### 3.5 Chase Termination Conditions

A chase ends when any of the following occurs:

| Condition | Notes |
|---|---|
| Player silent for `chase_lose_turns` consecutive turns | Most reliable; hardest to execute |
| Entity's LHP misdirected to a false location for `misdirect_turns` turns | Player must sustain the decoy |
| Player enters a sealed room or binding circle | Some rooms block presence entities |
| Player uses a specific ritual to ward the entity | One-time use; see Ritual GDD |
| Player reaches the floor exit / staircase | Ends all chases on that floor |
| Player uses a binding glyph item (consumable) | Temporary; entity re-enters area after `binding_duration` turns |
| Entity triggered a trap or blocking event | Entity is halted; player must still escape sonic range |

When a chase ends, the entity enters a `post_chase_patrol_turns` heightened alert period. During this time, its hearing threshold is halved and it moves faster than normal. The player is not safe just because the chase ended.

### 3.6 Multi-Entity Chases

Multiple entities can be in chase state simultaneously but are not coordinated. Each entity tracks its own LHP independently. A player who successfully misdirects one entity may still be tracked by another.

---

## 4. Formulas

### Entity Closing Rate

```
entity_gain_per_turn = entity_speed - player_speed

entity_speed = base_entity_speed (tiles per turn)
player_speed = {sprint: 2, normal: 1, quiet: 0.5}
```

Presence-class entities have `base_entity_speed = 1.5` tiles per turn (rounds to 2 every other turn). The player sprinting at 2 tiles per turn barely keeps pace. Walking at 1 tile per turn slowly loses ground.

### Silent Duration Check

```
turns_silent += 1 if player_noise_this_turn == 0
turns_silent = 0  if player_noise_this_turn > 0

if turns_silent >= chase_lose_turns:
    entity.state = SEARCH
```

### Entity Search Timeout

```
if entity.state == SEARCH and search_turns_elapsed >= post_search_timeout:
    entity.state = PATROL
    entity.sensitivity = base_sensitivity  # restore normal threshold
```

---

## 5. Edge Cases

- **Player enters silence zone during chase:** The entity loses acoustic tracking immediately. However, the player also loses all audio map information. If the player exits the silence zone while the entity is still searching nearby, they re-enter normal chase rules — the entity's LHP updates to the silence zone exit tile.
- **Multiple false LHPs stacked:** If the player throws two objects in sequence, the entity's LHP updates to the second landing tile. Only the most recent LHP is tracked.
- **Chase triggered while already in search state:** If a second noise event during the entity's search phase meets the trigger threshold, a new chase begins immediately from the current search position — closer to the player than the original start.
- **Player killed during chase:** Death is instant upon entity contact. There is no "chase death" timer — contact ends the run.
- **Sealed room collision:** If the player enters a sealed room that blocks the entity, the entity stops at the boundary and returns to heightened patrol. The player cannot exit the sealed room safely for `entity_wait_turns` turns — if they open the door too soon, the entity re-enters chase state.
- **Chase during ritual:** If a ritual is in progress (player is committed to a multi-turn ritual action) and a chase begins, the ritual is interrupted and fails. See Ritual GDD for failure consequences.

---

## 6. Dependencies

| System | Relationship |
|---|---|
| Noise System | Chase trigger relies on noise crossing presence threshold; LHP is set by Noise System |
| Audio Perception System | Chase warning glyphs are rendered through audio map overlay |
| Fear / Corruption System | Fear increases during chase; Corruption above threshold can auto-trigger a chase |
| Enemy Design | Entity speeds, chase behaviors, and sensitivity multipliers defined per entity type |
| Ritual System | Ritual failure triggers immediate chase; some rituals terminate a chase |
| Vision System | Entity is visible only if within current sight radius; otherwise only audio glyphs indicate position |

---

## 7. Tuning Knobs

| Knob | Draft Value | Notes |
|---|---|---|
| `chase_duration_min` | 20 turns | Minimum expected chase length |
| `chase_duration_max` | 40 turns | Design target ceiling |
| `entity_base_speed` | 1.5 tiles/turn | Presence entity movement rate |
| `chase_lose_turns` | 5 turns | Silent turns needed to drop to search state |
| `entity_search_threshold_multiplier` | 0.5× | Hearing threshold during search (doubled sensitivity) |
| `post_search_timeout` | 15 turns | Search→Patrol transition |
| `post_chase_alert_turns` | 10 turns | Heightened patrol after chase ends |
| `binding_duration` | 8 turns | How long a binding glyph halts an entity |
| `entity_lose_threshold` | 5 turns | Same as `chase_lose_turns` — consolidate at implementation |
| `misdirect_turns` | 8 turns | Turns of sustained false LHP needed to end chase |
| `entity_wait_turns` | 4 turns | Turns entity waits outside sealed room before returning to patrol |

---

## 8. Acceptance Criteria

- [ ] A presence-class entity receiving Noise ≥ 20 enters warning phase; the low-frequency warning glyph appears on the player's audio map.
- [ ] During the warning phase, if the player makes no noise for 3 consecutive turns, the entity returns to patrol and the chase does not begin.
- [ ] During an active chase, sprinting (Noise 4) updates the entity's LHP to the player's current tile each turn.
- [ ] If the player is silent for `chase_lose_turns` consecutive turns, the entity enters search state and its hearing sensitivity doubles.
- [ ] A thrown object landing 8 tiles away from the player causes the entity to pursue the landing tile rather than the player's true position.
- [ ] The chase ends when the entity completes its search pattern and finds no new noise for `post_search_timeout` turns.
- [ ] After a chase ends, the entity patrols with doubled sensitivity for `post_chase_alert_turns` turns.
- [ ] A player who reaches the floor exit during a chase exits successfully; the entity does not follow to the next floor.
- [ ] Contact with a presence-class entity during a chase ends the run immediately.
