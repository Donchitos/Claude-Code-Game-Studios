# GDD: Equipment System

**Status:** Draft  
**Layer:** Feature  
**Last Updated:** 2026-05-16  
**Dependencies:** Sonar System, Noise System, Fear/Corruption System

---

## 1. Overview

The Equipment System defines the gear the player carries to shape their acoustic capabilities. Equipment is organized into six slots: Sound Source, Resonator, Amplifier, Effect, Ritual Object, and Light Source. Each slot can hold one item. The combination of equipped items determines the player's sonar options, noise profile, and access to ritual capabilities. Equipment is not just stat bonuses — it determines which frequency classes the player can emit, which environments favour them, and what risks they carry.

---

## 2. Player Fantasy

The player feels like a scrounger assembling a rig out of rotten wood and old metal. A broken guitar through a dying amplifier in a stone corridor becomes a tool for survival. The right equipment in the right room turns a desperate ping into a tactical read. The wrong equipment in a reverberant chapel is a death sentence.

---

## 3. Detailed Rules

### 3.1 Equipment Slots

| Slot | Function | Max 1? |
|---|---|---|
| **Sound Source** | Determines available sonar actions and their base noise values | Yes |
| **Resonator** | Amplifies sonar return signal; adds +1 sonar tier when charged | Yes |
| **Amplifier** | Extends sonar range in matching room class; adds +1 tier in matched rooms | Yes |
| **Effect** | Modifies sonar signal character; changes frequency output or adds special effects | Yes |
| **Ritual Object** | Enables ritual actions and affects Corruption gain rate | Yes |
| **Light Source** | Grants sight radius bonus (see Vision System GDD) | Yes |

All slots are optional. A player with no Sound Source cannot perform active sonar and is limited to passive hearing.

### 3.2 Sound Source Types

| Item | Sonar Actions Available | Base Noise | Frequency Default |
|---|---|---|---|
| None (hands) | Hand clap, foot stomp | 3, 4 | MID |
| Bone flute | Bone flute sonar, hand clap | 6, 3 | MID / RITUAL light |
| Wind instrument | Bone flute, low drone (weak) | 6, 7 | MID |
| Guitar (acoustic) | Guitar sonar | 11 | NOISE light |
| Guitar (distorted) | Guitar / fuzz sonar | 14 | NOISE |
| Tape player | Preset loop sonar (delayed) | 8 | MID / variable |
| Metal rod | Metal strike | 5 | HIGH |
| Ritual horn | Sacred chant | Variable | RITUAL |
| Feedback unit | Feedback sonar | 16+ | NOISE (uncontrolled) |

A Sound Source that is damaged (from trap, enemy attack, or uncontrolled feedback) operates at 50% effectiveness until repaired at a workbench tile.

### 3.3 Resonator Types

Resonators are charged by surviving a turn in which a sound passes through the resonator's material type.

| Item | Charge Condition | Tier Bonus | Noise Reduction? |
|---|---|---|---|
| Metal canister | Metal-surface sound event in range | +1 sonar tier | No |
| Bone lattice | Bone / organic structure nearby | +1 sonar tier | No |
| Resonance stone | Used within 5 tiles of ritual circle | +1 sonar tier | Yes (−1 noise) |
| Crystal vial | HIGH frequency sound within range | +1 sonar tier | No |

Resonators lose their charge after one use. They recharge after 3 turns without being used.

### 3.4 Amplifier Types

Amplifiers only provide their bonus when the player is in a matching room class.

| Item | Matching Room Class | Sonar Range Bonus | Tier Bonus |
|---|---|---|---|
| Rusted PA speaker | Underground stage | +4 tiles | +1 tier |
| Altar resonator | Chapel | +3 tiles | +1 tier (RITUAL only) |
| Stone column mount | Stone chamber | +3 tiles | No tier bonus |
| Hollow log | Forest | +2 tiles | No tier bonus |
| Flooded cabinet | Swamp / water room | +3 tiles (LOW only) | No tier bonus |

Outside the matching room, an amplifier provides no bonus. It does not add noise.

### 3.5 Effect Pedals

Effect pedals modify the sonar signal after it leaves the Sound Source. Only one effect can be active at a time (though the player may carry one and swap it with another found in the dungeon).

| Effect | Benefit | Risk / Cost |
|---|---|---|
| **Fuzz** | +4 damage on sound-based attacks; +2 sonar tier for destructive detection | +3 noise on all actions |
| **Delay** | Entity glyphs from sonar persist 2 extra turns; moving entities can be re-tracked | Queued echo fires next turn, generating noise |
| **Reverb** | Sonar range +4 in any reverberant room; all glyphs linger 2 extra turns | False echo rate +5% |
| **Octaver** | LOW frequency sonar range +6; large entity detection tier +1 | Awakens large entities at lower threshold (−5 to their trigger noise) |
| **Chorus** | Generates 3 simultaneously displaced sonar pings; useful for entity confusion | Player themselves receives displaced glyphs — 20% chance of misread |
| **Gate** | Cuts residual noise by −2 after every action; suppresses echo lingering | Entity glyphs disappear 2 turns earlier than normal |
| **EQ** | Can boost or cut any one frequency class: +1 tier for chosen class, −1 tier for another | None beyond trade-off |
| **Feedback Unit** | Highest-range sonar (20 tiles, +1 tier); can stun entities briefly | +2 Corruption per use; 15% chance of uncontrolled second ping |

### 3.6 Ritual Objects

Ritual objects are required for ritual actions. Without one, the player cannot initiate any ritual.

| Item | Ritual Access | Corruption Modifier | Notes |
|---|---|---|---|
| Incense burner | Basic blessing / warding rituals | +0 | Low risk |
| Bone mask | Spirit communication rituals | +1 per ritual | Enhances spirit glyph clarity |
| Seal stone | Binding rituals | +0 | Required for entity-binding rituals |
| Sheet music | Chant-based resonance rituals | +1 per ritual | Amplifies RITUAL frequency sonar |
| Blood sigil | Most powerful ritual access | +2 per ritual | Enables forbidden rituals |

### 3.7 Equipment Interaction Rules

- The player may not use sonar if no Sound Source is equipped (hands count as a minimal default).
- Effect pedals are applied after frequency class is determined; they modify output, not source.
- Two effect pedals cannot be active simultaneously. Swapping takes one turn and generates Noise 1.
- A damaged Sound Source cannot be used for sonar (only passive hearing remains) until repaired.
- Ritual Objects are not consumed on use unless the ritual specifically states otherwise.

---

## 4. Formulas

### Effective Sonar Output (with Equipment)

```
effective_noise  = action_base_noise + fuzz_bonus
effective_range  = base_range × frequency_wall_modifier
                 × (1 + amplifier_bonus)
                 + octaver_low_bonus
                 + reverb_room_bonus

fuzz_bonus       = +3 if fuzz equipped, else 0
amplifier_bonus  = 0.3 if room matches amplifier, else 0
octaver_low_bonus= 6 if LOW frequency and octaver equipped, else 0
reverb_room_bonus= 4 if reverberant room and reverb equipped, else 0
```

### Sonar Tier (with Equipment)

```
final_tier = raw_tier
           + resonator_bonus
           + amplifier_tier_bonus
           + eq_class_bonus
           - eq_class_penalty
           - fear_penalty
           - corruption_penalty

resonator_bonus    = 1 if resonator charged, else 0
amplifier_tier_bonus = 1 if matching room + amplifier has tier bonus, else 0
eq_class_bonus     = 1 if current frequency matches EQ boost class
eq_class_penalty   = −1 if current frequency matches EQ cut class
```

---

## 5. Edge Cases

- **Feedback Unit uncontrolled second ping:** The secondary ping fires at `base_noise × 1.5` in a random cardinal direction. It is a full noise event and will trigger enemy reactions. The player cannot cancel it. The 15% roll is per use.
- **Chorus effect: player misread:** When Chorus fires 3 displaced pings, the player's own audio map receives glyphs for all 3 origins. The correct return is the center ping; the displaced ones are positionally ±3 tiles off. Players unfamiliar with Chorus should use it with caution.
- **EQ and frequency mismatch:** The player boosts LOW on EQ but fires a MID-frequency action (bone flute). The LOW boost does not apply; the MID penalty does not apply either — EQ only affects the stated chosen class and its cut class.
- **Damage to Sound Source:** An entity attack that hits the player's Sound Source (specific enemy ability) marks it as damaged. The player cannot use it for sonar. The Resonator and Effect still function as passive modifiers to passive hearing if applicable, but sonar is unavailable. Repair requires a dungeon workbench or a specific ritual.
- **No Ritual Object equipped but ritual circle activated:** The player stands on a ritual circle but cannot initiate a ritual. The circle still applies its `sound_multiplier = 2.0` and Corruption gain (+1 per 3 turns). The player gains nothing from the ritual aspect.
- **Light source in hand vs. in slot:** Light Source items generate Noise 0. But using a torch (open flame) in a room with gas / mist tiles causes an environmental explosion (room-specific rule, not equipment rule — flagged for level design).

---

## 6. Dependencies

| System | Relationship |
|---|---|
| Sonar System | Equipment modifies sonar tier, range, frequency, and duration of results |
| Noise System | Effect pedals and Source items modify noise values on actions |
| Fear / Corruption System | Ritual objects and effect pedals affect Corruption gain rate |
| Vision System | Light Source slot provides sight_radius bonus defined in Vision GDD |
| Ritual System | Ritual Objects are required for ritual initiation |
| Audio Perception System | Effect pedals modify glyph persistence and type on audio map |

---

## 7. Tuning Knobs

| Knob | Draft Value | Notes |
|---|---|---|
| `fuzz_noise_penalty` | +3 | Added to all actions when Fuzz equipped |
| `delay_glyph_extension` | +2 turns | Entity glyph duration bonus |
| `reverb_range_bonus` | +4 tiles | In reverberant rooms |
| `octaver_low_range_bonus` | +6 tiles | LOW frequency only |
| `chorus_misread_chance` | 20% | Probability player misreads chorus displacement |
| `gate_noise_reduction` | −2 | Cut from residual after each action |
| `feedback_control_fail_chance` | 15% | Per use, triggers uncontrolled second ping |
| `feedback_corruption_gain` | +2 | Per use |
| `resonator_charge_duration` | 3 turns | Turns before resonator recharges after use |
| `damaged_item_effectiveness` | 50% | Damaged source range/noise output |

---

## 8. Acceptance Criteria

- [ ] A player with no Sound Source equipped cannot initiate an active sonar action; passive hearing still functions.
- [ ] A Resonator provides exactly +1 sonar tier on the first use after charging; the bonus is not applied on the second consecutive use until recharged.
- [ ] An Amplifier provides its range and tier bonus only when the player is in the matching room class; confirmed by moving player between room types with Amplifier equipped.
- [ ] Fuzz equipped adds +3 to the noise value of all player actions; confirmed by comparing noise events with and without Fuzz.
- [ ] Feedback Unit has a 15% chance per use of firing an uncontrolled second ping; verified over 40-use controlled test (approximately 6 secondary pings ±3).
- [ ] A damaged Sound Source cannot generate sonar events; attempting the action displays a "damaged" indicator.
- [ ] Ritual Object is required to initiate any ritual; without one, the ritual option is unavailable on ritual circle tiles.
- [ ] EQ boost on LOW frequency correctly applies +1 tier to LOW sonar actions and has no effect on MID or HIGH actions.
