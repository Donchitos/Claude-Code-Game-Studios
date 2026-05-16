# GDD: Noise & Aggro System

**Status:** Draft  
**Layer:** Core  
**Last Updated:** 2026-05-16  
**Dependencies:** Audio Perception System, Enemy Design, Chase System

---

## 1. Overview

Every player and enemy action in the game produces a noise value. That noise propagates through the map according to tile acoustic properties, accumulates in a per-zone noise level, and is checked against each enemy's hearing threshold each turn. Enemies do not teleport to the player — they move toward the last tile where they heard a sound. This means the player can deceive enemies, lure them away, and manipulate their beliefs about where the player is. Noise is the resource the player is always spending, never earning, and must budget carefully.

---

## 2. Player Fantasy

The player feels like a thief who can hear the guard's footsteps but knows the guard can hear theirs too. Every action is weighed against its noise cost. Standing still is free. Running is loud and dangerous. Throwing a stone to create a decoy is satisfying precisely because it works the same way on both sides — sound is the universal currency of information in this world.

---

## 3. Detailed Rules

### 3.1 Player Action Noise Values

| Action | Noise Value |
|---|---|
| Wait / Hold still | 0 |
| Listen (Listening Mode) | 0 |
| Slow walk (half movement) | 1 |
| Normal movement | 2 |
| Sprint (double movement) | 4 |
| Open door (careful) | 2 |
| Open door (forced) | 8 |
| Break object (wood) | 6 |
| Break object (metal) | 9 |
| Pick up item | 1 |
| Attack (light weapon) | 3 |
| Attack (heavy weapon) | 6 |
| Throw object (soft landing) | 2 |
| Throw object (hard landing) | 5 |
| Hand clap sonar | 3 |
| Foot stomp sonar | 4 |
| Metal strike sonar | 5 |
| Bone flute / wind instrument sonar | 6 |
| Low drone sonar | 10 |
| Guitar / fuzz sonar | 14 |
| Feedback unit sonar | 16+ |
| Sacred chant / ritual phrase | Room-wide |

Movement noise is modified by the tile the player moves *onto* (multiplied by that tile's `sound_multiplier`).

### 3.2 Noise Decay

Noise does not stay at peak level. Each turn, ambient noise in a zone decreases by the `noise_decay_rate`. Some tiles have higher residual noise due to their reflective properties.

```
noise_next_turn = noise_current × (1 - noise_decay_rate)
```

Tiles with `echo = true` apply an additive residual:

```
residual_echo = reflected_strength × echo_persistence_factor
```

This means in reverberant rooms (stone chambers, chapels), noise lingers longer, giving enemies more time to react even after the player stops moving.

### 3.3 Aggro Thresholds

Enemies check the noise level at the sound's origin tile against their `hearing_threshold` each turn.

| Accumulated Noise | General Effect |
|---|---|
| 0–5 | Safe — no reaction from normal enemies |
| 6–12 | Investigation — aware enemies move toward source |
| 13–20 | Alert — dangerous enemies react; patrols converge |
| 21–30 | Danger — presence-class entities register the sound |
| 31+ | Critical — chase sequence probable if presence entity is in range |

These are aggregate values — the total noise generated in the current turn (or burst), not lifetime noise. Large single events (e.g., forced door, Noise 8) can jump directly into higher bands.

### 3.4 Enemy Hearing Thresholds by Type

| Enemy Type | Threshold | Notes |
|---|---|---|
| Human cultist / patrol | 6 | Investigates any noise above threshold |
| Blind Listener | 2 | Extremely sensitive; reacts to slow walk |
| Choir Ghost | 4 | Especially sensitive to MID and RITUAL frequency |
| Coffin Thing | 10 | Only awakened by significant noise or proximity |
| Masked Cultist | 6 | Also calls nearby entities on reaction |
| Heavy Presence | 20 | Only reacts to very loud events or sustained noise |
| Static Apparition | N/A | Does not react to noise; uses its own detection logic |

### 3.5 Last-Heard-Position (LHP)

Enemies do not track the player in real time unless the player is within their sight range. Instead, when an enemy reacts to a noise event, they move toward the *tile the noise originated from* — the Last-Heard-Position.

**LHP rules:**
- LHP is set to the noise origin tile, not the player's current position.
- If the player moves quietly after making a noise, the enemy investigates the old LHP.
- LHP is cleared when the enemy reaches the tile and finds nothing. The enemy then enters a search state (patrolling adjacent tiles for `search_turns` turns) before returning to normal patrol.
- A new, louder noise event overwrites the current LHP.
- The player can deliberately create false LHPs using thrown objects, broken doors, or remote sonar.

### 3.6 Creating False LHPs

The player can manipulate enemy beliefs by creating sounds away from their position:

| Method | Noise at Target | Notes |
|---|---|---|
| Throw rock (hard) | 5 at landing tile | Redirects patrol to landing tile |
| Throw bottle / container | 4–6 | Breaks; larger AOE |
| Close door from safe side | 3 at door tile | Enemy investigates door |
| Use sonar from another room | Full sonar noise value | Enemy moves toward sonar origin |
| Knock over object remotely | 4–7 | Requires line of interaction |
| Trigger trap intentionally | Trap noise value | Very effective; burns a trap |

---

## 4. Formulas

### Noise at Target Tile

```
noise_at_target = action_noise × tile_multiplier(origin_tile)
                              × path_attenuation(origin_to_target)

path_attenuation = Π(1 - tile.absorbs_sound) × wall_attenuation^(wall_count)

wall_attenuation = 0.6 per wall tile
```

### Noise Decay Per Turn

```
noise_t = noise_0 × (1 - decay_rate)^t

decay_rate    = 0.35 per turn (standard)
residual_echo = reflected_strength × 0.25 (added to noise_t if tile.echo = true)
```

### Enemy Reaction Check

```
if noise_at_enemy_position ≥ enemy.hearing_threshold:
    if enemy.state == PATROL:
        enemy.state = INVESTIGATING
        enemy.lhp   = noise_origin_tile
```

---

## 5. Edge Cases

- **Player standing still in noisy combat:** Player noise is 0 (Wait), but combat sounds from nearby enemies may still generate a noise event at the player's tile via propagation. This does not cause the player to aggro additional enemies unless the propagated value reaches the second enemy's threshold.
- **Forced door in an anechoic room:** The action still generates Noise 8 at the door tile. But the anechoic room suppresses propagation outward. Adjacent rooms receive significantly reduced noise. Enemies inside the anechoic room still hear it at full value.
- **Multiple simultaneous noise events:** If the player and an enemy both make noise in the same turn, each noise event is evaluated independently. A player who attacks (Noise 3) while a Coffin Thing (threshold 10) is already alerted does not additionally aggro — but a Blind Listener (threshold 2) reacts to the attack.
- **Thrown object that misses:** If the throw trajectory passes through an enemy's hearing range mid-arc, the enemy may react to the object's movement noise before it lands.
- **Search state duration:** An enemy in search state that receives a new noise event immediately exits search and sets a new LHP. Search state is effectively interruptible.
- **Noise from ritual chant:** Room-wide noise means all enemies in the current room receive the noise event simultaneously, each at full value regardless of distance within the room.

---

## 6. Dependencies

| System | Relationship |
|---|---|
| Audio Perception System | Noise events generate audio glyphs at the origin tile |
| Sonar System | Sonar actions are noise events; their values come from this GDD |
| Chase System | Aggro above critical threshold can trigger a chase via LHP resolution |
| Enemy Design | Each enemy type's `hearing_threshold` is defined in the Enemy Design GDD |
| Equipment System | Some equipment items reduce noise output (e.g., padded boots, noise gate pedal) |

---

## 7. Tuning Knobs

| Knob | Draft Value | Notes |
|---|---|---|
| `noise_decay_rate` | 0.35 per turn | Standard decay; lower = longer linger |
| `echo_persistence_factor` | 0.25 | Residual echo multiplier for reflective tiles |
| `wall_attenuation` | 0.6 | Per wall tile crossed |
| `aggro_investigate_threshold` | 6 | General enemies begin investigating |
| `aggro_alert_threshold` | 13 | Dangerous enemies react |
| `aggro_presence_threshold` | 21 | Presence-class entities register |
| `aggro_chase_threshold` | 31 | Chase sequence probable |
| `search_turns` | 5–8 turns | Enemy searches LHP before returning to patrol |
| `blind_listener_threshold` | 2 | Most sensitive enemy |
| `heavy_presence_threshold` | 20 | Hardest to accidentally trigger |

---

## 8. Acceptance Criteria

- [ ] A player standing still (Noise 0) for 10 consecutive turns causes no enemy reaction anywhere on the map.
- [ ] Normal movement (Noise 2) on a stone floor (multiplier 1.2) generates effective noise of 2.4 at the origin tile.
- [ ] A Blind Listener (threshold 2) reacts to a slow walk (Noise 1) on a stone floor because 1 × 1.2 = 1.2 < 2 — the listener should NOT react. A normal walk (2 × 1.2 = 2.4 ≥ 2) triggers reaction.
- [ ] After a Noise 8 door-break event, a patrolling human cultist (threshold 6) sets their LHP to the door tile and begins moving toward it.
- [ ] The player moves away quietly after the door break. The cultist reaches the door tile, finds nothing, enters search state, then returns to patrol after `search_turns` turns.
- [ ] A thrown rock landing 6 tiles away (Noise 5 at landing tile) redirects a cultist's attention to the landing tile rather than the player's position.
- [ ] Noise at a tile decays to < 10% of its initial value within 6 turns under standard conditions.
- [ ] Room-wide chant noise reaches all enemies in the room simultaneously, each at full threshold check value.
