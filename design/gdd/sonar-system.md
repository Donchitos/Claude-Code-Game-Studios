# GDD: Sonar System

**Status:** Draft  
**Layer:** Core  
**Last Updated:** 2026-05-16  
**Dependencies:** Audio Perception System, Noise System, Equipment System

---

## 1. Overview

The Sonar System lets the player deliberately emit sound to probe the space around them and receive structured acoustic feedback about terrain, objects, and entities. Unlike passive hearing (always-on, reactive), sonar is a player-initiated trade: spend noise to gain information. Every sonar action generates a noise event processed by the Noise System, risking enemy reactions proportional to the sonar's power. The quality of information returned depends on the sonar action chosen, the player's equipped resonators and effect pedals, their current Corruption level, and the room's acoustic properties.

---

## 2. Player Fantasy

The player feels like a spelunker mapping a cave by clapping. A careful hand-clap near a doorway tells them roughly what's behind it. A deep resonant drone tells them something enormous is two rooms away — and also tells it that the player is here. Using sonar is a deliberate gamble, and the moment a powerful ping comes back wrong is terrifying.

---

## 3. Detailed Rules

### 3.1 Active Sonar Actions

| Action | Base Noise | Base Range | Frequency Class | Primary Use |
|---|---|---|---|---|
| Hand clap | 3 | 6 tiles | MID | Short-range structure near walls |
| Foot stomp | 4 | 8 tiles | LOW | Floor material, nearby creatures |
| Metal strike | 5 | 10 tiles | HIGH | Doors, metal objects, cages |
| Bone flute / wind instrument | 6 | 12 tiles | MID | Biological entities, spirits |
| Low drone | 10 | 18–20 tiles | LOW | Long-range structure, large entities |
| Guitar / fuzz tone | 14 | 16 tiles | NOISE | Hidden entities, illusions, unstable structures |
| Feedback unit | 16+ | 20 tiles | NOISE | Maximum range; risk of control loss |
| Sacred chant / ritual phrase | Variable | Variable | RITUAL | Occult objects, seals, spirits |

Noise values feed directly into the Noise System. Enemies within range will react based on their `audio_sensitivity` profile.

### 3.2 Frequency Classes

Each sonar action belongs to a frequency class. Frequency class determines what the ping can detect and what dangers it activates.

| Frequency | Strengths | Risks |
|---|---|---|
| LOW | Penetrates walls; detects large entities and underground spaces | Awakens deep / large presence-class entities |
| MID | Most reliable general-purpose detection; balanced range | No special risks; lower peak performance |
| HIGH | Precise on small objects, traps, metal; sharp edge detection | Does not penetrate walls well (range −30% through walls) |
| NOISE | Detects hidden entities, entities behind illusions, unstable structures | Increases false echoes; raises Corruption by 1 per use |
| RITUAL | Detects occult markers, sealed doors, spirit entities | Attracts spirit-class entities; may trigger ritual effects on target tiles |

### 3.3 Sonar Information Tiers

Sonar does not return precise information. The quality of what the player learns is determined by a tier calculation.

| Tier | Information Returned |
|---|---|
| 1 | "There is empty space in that direction." |
| 2 | Rough outline of walls, doors, large objects. |
| 3 | Presence and approximate size of moving entities. |
| 4 | Entity category (e.g., humanoid, large, spectral). |
| 5 | Exact position and entity type. |

Tier 5 is nearly never achieved in normal play — it requires powerful equipment, low Corruption, and a favorable acoustic environment.

### 3.4 Sonar Result Duration

After a sonar action resolves, the returned glyphs appear on the audio map. They persist for:

- Structural glyphs (walls, doors, large objects): `sonar_structural_turns` turns, then decay to faded outline.
- Entity glyphs: `sonar_entity_turns` turns, then disappear (entities move).
- Echo / reflection glyphs: `echo_decay_turns` turns (defined in Audio Perception GDD).

Structural glyphs that the player later enters current sight on are replaced by accurate memory.

### 3.5 Sonar Accuracy Modifiers

The information tier and the positional accuracy of entity glyphs are both modified:

| Modifier | Effect |
|---|---|
| +1 tier | Resonator equipped and charged |
| +1 tier | Amplifier equipped in matching room class |
| −1 tier | Fear state: High |
| −2 tiers | Fear state: Extreme |
| −1 tier per 5 Corruption above 10 | Corruption degrades signal clarity |
| −1 tier | Room class: Anechoic |
| +1 tier | Room class: Chapel (RITUAL frequency only) |
| ±1 tile position error | Base positional uncertainty at Tier 3–4 |

Position error means an entity glyph may be rendered up to ±1 tile from the entity's true position. Players should not expect sonar positions to be exact.

### 3.6 False Echoes

False echoes are sonar returns that do not correspond to real objects or entities. They occur when:

- Corruption ≥ 10: 10% chance per sonar action.
- Corruption ≥ 20: 25% chance per sonar action.
- NOISE frequency used: additional +10% per use.
- Fear: Extreme: +15% to false echo rate.

A false echo looks identical to a real echo glyph but responds to an empty tile. Players can test a suspicious glyph by approaching — if no entity or object is present, it was a false echo. The Static Apparition enemy (see Enemy Design GDD) also generates false sonar returns intentionally.

---

## 4. Formulas

### Sonar Tier Calculation

```
raw_tier = floor((sonar_range - distance_to_target) / sonar_range × 5)
         + resonator_bonus
         + amplifier_bonus
         - fear_penalty
         - corruption_penalty
         - anechoic_penalty

final_tier = clamp(raw_tier, 0, 5)

resonator_bonus    = 1 if resonator equipped and charged, else 0
amplifier_bonus    = 1 if amplifier room class matches, else 0
fear_penalty       = {high: 1, extreme: 2, else: 0}
corruption_penalty = floor(max(0, corruption - 10) / 5)
anechoic_penalty   = 1 if room_class == ANECHOIC, else 0
```

### Effective Sonar Range

```
effective_sonar_range = base_range
                      × frequency_wall_modifier
                      × (1 - room_absorption)
                      × (1 + amplifier_room_bonus)

frequency_wall_modifier = {LOW: 1.0, MID: 0.8, HIGH: 0.5, NOISE: 0.9, RITUAL: 0.7}
                          (applied per wall tile crossed; multiplied together)
room_absorption         = sum of absorbs_sound for all tiles on path / path_length
amplifier_room_bonus    = 0.3 if amplifier equipped and room matches, else 0
```

### False Echo Probability

```
false_echo_chance = base_rate
                  + (corruption_over_10 × 0.02)
                  + (corruption_over_20 × 0.01)
                  + (NOISE_frequency × 0.10)
                  + (extreme_fear × 0.15)

base_rate = 0.0 if corruption < 10, else 0.10
```

---

## 5. Edge Cases

- **Sonar in anechoic room:** Returns Tier 0 or 1 only. The player receives a suppressed glyph at their own position and a UI note. The room does not echo — the ping is swallowed.
- **Sonar targeting the player's own tile:** Sonar is centred on the player. The player does not receive self-ping information; only outward propagation is calculated.
- **Two sonar pings in one turn:** Not allowed. Only one active sonar action per turn. If an equipment item would cause a second ping (e.g., Delay pedal echo), it fires on the *next* turn as a scheduled event — it still generates noise and may cause reactions.
- **RITUAL frequency in non-ritual room:** The ping propagates normally but returns no ritual-specific information (sealed doors appear as ordinary doors, spirit entities may or may not appear depending on entity rules). No bonus or penalty compared to MID.
- **Feedback unit out of control:** If the player rolls a control-loss event (see Equipment GDD), the feedback unit fires a secondary uncontrolled ping at `base_noise × 1.5` in a random direction. This is not a player-initiated action and cannot be cancelled.
- **Structural glyph conflicts:** If a sonar glyph shows a wall where no wall exists (false echo), and the player later enters line of sight of that tile, the false glyph is erased and the tile renders normally. No explanation is given — the discrepancy is silent and potentially unsettling.

---

## 6. Dependencies

| System | Relationship |
|---|---|
| Audio Perception System | Sonar results are rendered as audio glyphs; propagation uses tile acoustic properties |
| Noise System | Every sonar action emits a noise event at the action's `base_noise` value |
| Equipment System | Resonators, amplifiers, and effect pedals modify sonar tier and range |
| Fear / Corruption | Both stat values apply penalties to sonar tier and false echo rate |
| Enemy Design | Large / presence-class enemies respond to LOW sonar; all enemies have `audio_sensitivity` thresholds |

---

## 7. Tuning Knobs

| Knob | Draft Value | Notes |
|---|---|---|
| `hand_clap_noise` | 3 | Minimum practical sonar cost |
| `foot_stomp_noise` | 4 | |
| `metal_strike_noise` | 5 | |
| `bone_flute_noise` | 6 | |
| `low_drone_noise` | 10 | High risk — awakens large entities |
| `fuzz_guitar_noise` | 14 | |
| `feedback_noise` | 16+ | Floor, scales with uncontrolled use |
| `sonar_structural_turns` | 5 turns | How long wall/door glyphs persist |
| `sonar_entity_turns` | 2 turns | Entity glyphs fade quickly |
| `false_echo_threshold_1` | 10 Corruption | First false echo rate kicks in |
| `false_echo_threshold_2` | 20 Corruption | Second rate increase |
| `false_echo_rate_base` | 10% | At first threshold |
| `position_error_range` | ±1 tile | At Tier 3–4 |
| `corruption_penalty_interval` | 5 Corruption | Each 5 above 10 = −1 tier |

---

## 8. Acceptance Criteria

- [ ] A hand clap (Noise 3, Range 6) at distance 6 from a wall returns at minimum Tier 2 information (wall outline visible) under default conditions with no modifiers.
- [ ] A low drone (Noise 10) in a stone room triggers a Large entity reaction if one exists within 15 tiles.
- [ ] Sonar inside an anechoic room returns Tier 0–1 only, regardless of action strength or equipment.
- [ ] Entity glyphs from sonar disappear after `sonar_entity_turns` turns.
- [ ] Structural glyphs from sonar persist for `sonar_structural_turns` turns then fade.
- [ ] With Corruption ≥ 10, at least 1 in 10 sonar pings generates a false echo in a controlled test (run 30 pings with a fixed seed).
- [ ] A Resonator equipped at full charge increases sonar tier by exactly 1.
- [ ] HIGH frequency sonar (metal strike) through 2 wall tiles returns at least 30% shorter effective range than LOW frequency through the same path.
- [ ] Only one sonar action is possible per player turn; queued equipment echoes fire on subsequent turns.
