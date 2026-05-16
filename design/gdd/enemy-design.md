# GDD: Enemy Design

**Status:** Draft  
**Layer:** Feature  
**Last Updated:** 2026-05-16  
**Dependencies:** Noise System, Audio Perception System, Chase System, Ritual System

---

## 1. Overview

Enemies in this game are not primarily obstacles to be defeated — they are acoustic hazards that reshape how the player navigates space. Each enemy type has a distinct hearing profile, movement behavior, and response pattern. Some can be killed in normal combat. Others cannot. The player's job is to learn what each entity hears, how it moves, and how to exploit the gap between what it knows and where the player actually is. Enemy design is the game's primary teaching mechanism for how the audio systems work.

---

## 2. Player Fantasy

The player feels like a naturalist studying dangerous animals. Each new entity type encountered is a puzzle: what does it hear? What does it ignore? Can it be fooled? Can it be stopped? Enemies that cannot be killed are not frustrating — they are the most interesting puzzle in the game.

---

## 3. Detailed Rules

### 3.1 Enemy Classification

| Class | Killable? | Role |
|---|---|---|
| **Normal** | Yes | Combat target; primary XP / resource source |
| **Dangerous** | Yes | Killable but high risk; recommend avoidance |
| **Presence** | No | Chase trigger; upper predator; rhythm-changer |
| **Echo** | Ambiguous | May or may not be real; audio deception |
| **Ritual** | Conditional | Appears under specific conditions; bound to ritual logic |

### 3.2 Audio Sensitivity Profile

Each enemy has an audio sensitivity profile defining which sounds they react to and at what threshold.

| Profile Field | Description |
|---|---|
| `hearing_threshold` | Noise value that triggers investigation |
| `frequency_sensitivity` | Which frequency classes cause heightened reaction |
| `ritual_breaker` | Boolean — does this entity passively interrupt rituals |
| `lhp_tracking` | Boolean — does this entity track Last-Heard-Position or true position |
| `sight_range` | How many tiles of line-of-sight this enemy has |

---

### 3.3 Enemy Profiles

---

#### Blind Listener

**Class:** Normal  
**Description:** A humanoid figure with no functional eyes. It navigates entirely by sound, moving toward the source of any noise above its threshold. It has no visual detection. If the player is silent and unmoving, it will pass within 1 tile without reacting.

| Stat | Value |
|---|---|
| `hearing_threshold` | 2 |
| `frequency_sensitivity` | All equally (no specialization) |
| `sight_range` | 0 |
| `lhp_tracking` | Yes |
| `ritual_breaker` | No |
| HP | Low |
| Movement Speed | 1 tile/turn |
| `killable` | Yes |

**Behavior:**
- Patrols a fixed route when not alerted.
- On noise ≥ 2: moves to LHP, searches for `search_turns` turns, returns to patrol.
- During active pursuit: moves directly toward LHP each turn; updates LHP if new noise heard.
- Cannot be confused by sight-based tricks (fake torches, visual decoys).
- Can be confused by sound decoys (thrown objects, remote sonar).

**Design Role:** Teaches the player that silence is a valid movement strategy. Demonstrates LHP mechanics in a low-stakes context.

---

#### Coffin Thing

**Class:** Dangerous  
**Description:** Something that lives inside coffins. It does not move until awakened. Awakening triggers require significant noise (opening the coffin, a large noise nearby) or prolonged proximity. Once awake, it is slow but persistent.

| Stat | Value |
|---|---|
| `hearing_threshold` | 10 |
| `frequency_sensitivity` | None (does not use sonar response) |
| `sight_range` | 3 tiles |
| `lhp_tracking` | Yes |
| `ritual_breaker` | No |
| HP | Medium-High |
| Movement Speed | 0.5 tiles/turn (rounds every 2 turns) |
| `killable` | Yes (but difficult) |

**Behavior:**
- Dormant until: coffin is opened, or Noise ≥ 10 within 4 tiles, or player spends 5 turns within 3 tiles.
- On wake: generates a loud noise event (Noise 8) and begins pursuing LHP.
- Very slow but never gives up pursuit within a floor. Does not return to patrol until player is out of range for 20 consecutive turns.
- Coffins that have been activated but the Coffin Thing was not awakened (player passed by quietly) will not re-seal.

**Design Role:** Teaches players to check coffins before making noise near them. Introduces the concept of conditionally dormant threats.

---

#### Choir Ghost

**Class:** Presence  
**Description:** A spectral figure associated with chapels, ritual spaces, and reverberant rooms. It imitates the player's audio signature, creating false sonar returns and misleading echo glyphs. It is drawn to MID and RITUAL frequency sounds.

| Stat | Value |
|---|---|
| `hearing_threshold` | 4 |
| `frequency_sensitivity` | MID (×2 reaction range), RITUAL (×3 reaction range) |
| `sight_range` | 6 tiles |
| `lhp_tracking` | No — tracks true position once in sight range |
| `ritual_breaker` | Yes |
| HP | N/A (unkillable) |
| Movement Speed | 1.5 tiles/turn |
| `killable` | No |

**Behavior:**
- Generates fake MID-frequency echo glyphs 2–4 tiles from its position to mislead the player.
- If the player's sonar hits it, it responds with a mirrored sonar return from a false position (1d4 tiles displaced from true position).
- If the player uses a RITUAL frequency action within 15 tiles, it enters chase mode immediately.
- Cannot be physically blocked by doors (passes through).
- Can be temporarily suppressed by a successful binding ritual (8–12 turns).

**Design Role:** Undermines trust in audio information. Forces players to cross-reference multiple glyph types. Teaches the player that not every echo is real.

---

#### Heavy Presence

**Class:** Presence  
**Description:** Something very large that has never been fully seen. It announces itself through low-frequency vibrations before it becomes a danger. Direct contact is lethal. It cannot be stopped, slowed, or significantly impeded by normal means.

| Stat | Value |
|---|---|
| `hearing_threshold` | 20 |
| `frequency_sensitivity` | LOW (immediate reaction), any Noise ≥ 20 |
| `sight_range` | 2 tiles (poor vision) |
| `lhp_tracking` | Yes |
| `ritual_breaker` | Yes (passively) |
| HP | N/A (unkillable) |
| Movement Speed | 1.5 tiles/turn |
| `killable` | No |

**Behavior:**
- Emits low-frequency warning glyphs at 15–30 tile range passively each turn.
- On hearing Noise ≥ 20 or any LOW-frequency sonar: enters chase mode.
- During chase: all objects in its path are destroyed (breakable terrain, doors). It cannot be rerouted by sound decoys once in active chase — it continues toward last LHP regardless.
- Exception: A Tier 3+ suppression ritual can halt it for `silence_suppress_turns` turns.
- After the chase, it returns to its home area (2–3 specific rooms per floor).

**Design Role:** Teaches avoidance over engagement. Establishes that some things should not be provoked. Demonstrates that LOW-frequency sonar is double-edged.

---

#### Static Apparition

**Class:** Echo  
**Description:** A figure that appears and disappears inconsistently in sonar returns. It may or may not be physically present. Its glyph type is the glitch / broken-waveform pattern.

| Stat | Value |
|---|---|
| `hearing_threshold` | N/A |
| `frequency_sensitivity` | NOISE frequency only |
| `sight_range` | 0 (no physical sight) |
| `lhp_tracking` | No |
| `ritual_breaker` | No |
| HP | None (no physical form by default) |
| Movement Speed | N/A |
| `killable` | Conditional (see below) |

**Behavior:**
- Appears in sonar returns at random positions near the player (1 in 5 sonar pings generates a Static Apparition glyph, regardless of true entity presence).
- Actual Static Apparitions exist as rare spawns in high-Corruption zones. When physically present, contact applies Fear +20 and Corruption +3 to the player (one-time) then disappears.
- Can only be detected reliably at Corruption ≥ 10 (the new spirit glyph type unlocks).
- Cannot be killed while in phantom state. When physically manifested (rare), it can be banished by a Tier 2+ ritual.

**Design Role:** Provides noise and uncertainty in the audio data stream. Teaches players that not everything they see on the audio map is real. Rewards high-Corruption players with the ability to distinguish it.

---

#### Masked Cultist

**Class:** Normal  
**Description:** A human who has joined the occult workings of this place. Performs rituals, patrols, and can call other entities to their location using chant.

| Stat | Value |
|---|---|
| `hearing_threshold` | 6 |
| `frequency_sensitivity` | MID, RITUAL |
| `sight_range` | 6 tiles |
| `lhp_tracking` | Yes |
| `ritual_breaker` | No |
| HP | Medium |
| Movement Speed | 1 tile/turn |
| `killable` | Yes |

**Behavior:**
- Patrols ritual rooms and altars.
- On alert: uses chant action (RITUAL frequency, room-wide) to call one additional entity from an adjacent room. Called entity arrives in `call_response_turns` turns.
- If the player kills a Masked Cultist while it is mid-chant, the call is interrupted (no entity arrives).
- Masked Cultists do not chase — they call and then defend.
- Can initiate minor rituals on altars if left alone for 5 turns (increases room's Corruption-generation rate by 1).

**Design Role:** Introduces the concept of enemies that escalate the situation rather than directly attacking. Teaches players to prioritize targets based on threat multiplication.

---

## 4. Formulas

### Frequency-Sensitive Hearing Range

```
effective_range = base_range
if sound.frequency_class in enemy.frequency_sensitivity:
    effective_range = base_range × sensitivity_multiplier[frequency_class]

sensitivity_multiplier = {high: 2.0 for RITUAL class (Choir Ghost),
                         2.0 for MID class (Choir Ghost),
                         immediate for LOW ≥ 10 (Heavy Presence)}
```

### Cultist Call Response Time

```
call_response_turns = distance_to_nearest_other_entity / other_entity_speed + 1
```

---

## 5. Edge Cases

- **Blind Listener in anechoic room:** The Blind Listener's hearing threshold is 2, but in an anechoic room all sound propagation is suppressed. The Blind Listener can only hear sounds generated on the exact tile it occupies, not propagated sounds. This is the one place the player can move near it more freely.
- **Choir Ghost imitates a RITUAL sonar:** If the Choir Ghost generates a false return that the player interprets as a RITUAL response, and the player then uses RITUAL frequency, the Choir Ghost enters chase because the player used RITUAL within 15 tiles. The trap is intentional.
- **Coffin Thing: two coffins in one room:** Each coffin has an independent Coffin Thing. Both can be awakened by the same noise event. Both will pursue simultaneously as independent entities.
- **Masked Cultist chant interrupted by death:** If the player kills the Cultist on turn 3 of a 5-turn chant, the call does not go through. If killed on turn 5 (last turn of chant), the call resolves — it has already been sent.
- **Heavy Presence + decoy:** Unlike other entities, the Heavy Presence does not update its LHP mid-chase. It goes to the LHP that was set when the chase began. Decoys thrown after the chase starts are ignored.
- **Static Apparition false positive at low Corruption:** A player at Corruption 5 cannot distinguish a false Static Apparition glyph from a real one. This is intentional — Corruption provides the tool to manage the noise it also generates.

---

## 6. Dependencies

| System | Relationship |
|---|---|
| Noise System | Each entity's `hearing_threshold` integrates with Noise System aggro checks |
| Audio Perception System | Each entity generates or manipulates audio glyphs (Choir Ghost) |
| Chase System | Presence-class entities use Chase System rules when alerted |
| Ritual System | `ritual_breaker` entities interrupt active rituals; Cultist initiates rituals |
| Fear / Corruption System | Entity proximity generates Fear; Static Apparition contact generates Corruption |

---

## 7. Tuning Knobs

| Knob | Draft Value | Notes |
|---|---|---|
| `blind_listener_threshold` | 2 | Most sensitive |
| `coffin_thing_threshold` | 10 | |
| `choir_ghost_threshold` | 4 | |
| `heavy_presence_threshold` | 20 | |
| `masked_cultist_threshold` | 6 | |
| `choir_ghost_mid_multiplier` | 2.0 | MID range multiplier |
| `choir_ghost_ritual_multiplier` | 3.0 | RITUAL range multiplier |
| `heavy_presence_chase_speed` | 1.5 tiles/turn | |
| `coffin_thing_wake_proximity_turns` | 5 turns | Turns near coffin before passive wake |
| `cultist_call_action_turns` | 5 turns | Turns to complete a chant |
| `cultist_call_response_turns` | 3 turns base | Entity arrival time after call |
| `static_apparition_false_rate` | 20% | Per sonar ping below Corruption 10 |
| `choir_ghost_suppress_duration` | 10 turns | Binding ritual suppression |
| `coffin_thing_no_return_turns` | 20 turns | Turns out of range before it returns to patrol |

---

## 8. Acceptance Criteria

- [ ] A Blind Listener does not react to a player standing still (Noise 0) at 1-tile distance.
- [ ] A Blind Listener reacts (moves to LHP) when the player takes a normal walk step (Noise 2 × stone floor 1.2 = 2.4 ≥ 2).
- [ ] A Coffin Thing does not wake when the player slow-walks (Noise 1) past a coffin at 5-tile distance (1 × 1.0 path attenuation decays below 10 at that range).
- [ ] A Choir Ghost enters chase mode immediately when the player uses a RITUAL-frequency sonar within 15 tiles.
- [ ] A Choir Ghost generates a false sonar return (displaced by 1–4 tiles from true position) when a sonar ping hits it.
- [ ] A Heavy Presence begins emitting low-frequency warning glyphs that the player can detect at 15+ tiles range.
- [ ] A Heavy Presence enters chase after receiving Noise ≥ 20; it destroys breakable doors in its path.
- [ ] A Heavy Presence does not update its LHP mid-chase when a decoy is thrown.
- [ ] A Masked Cultist successfully calls a nearby entity after 5 turns of uninterrupted chant.
- [ ] Killing a Masked Cultist before its 5-turn chant completes prevents the called entity from arriving.
- [ ] A Static Apparition glyph appears in approximately 20% of sonar pings in a controlled no-entity-present test room (verified over 50 pings ±7).
- [ ] At Corruption ≥ 10, the player can distinguish a Static Apparition's spirit glyph from a normal echo glyph via distinct visual type.
