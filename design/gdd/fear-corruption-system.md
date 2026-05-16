# GDD: Fear & Resonance Corruption System

**Status:** Draft  
**Layer:** Core  
**Last Updated:** 2026-05-16  
**Dependencies:** Vision System, Audio Perception System, Chase System, Ritual System

---

## 1. Overview

Two parallel meters track the player's psychological and occult exposure: Fear and Resonance Corruption. Fear is reactive — it rises with immediate threats and falls when the player is safe. Corruption is accumulative — it never resets within a run and grows with every use of powerful occult audio or ritual tools. Fear degrades information quality and increases vulnerability. Corruption is a double-edged stat: it opens occult perception while simultaneously poisoning it. High Corruption is a build path, not a failure state — but it carries real risks.

---

## 2. Player Fantasy

Fear makes the player feel genuinely unsafe: the walls close in, the sounds lie more often, and every glyph is suspect. Corruption makes the player feel like they are becoming something other — more attuned to the dark but also more contaminated by it. Players who lean into Corruption gain tools that cautious players never access, but they also risk losing the ability to trust their own senses.

---

## 3. Detailed Rules

### 3.1 Fear Meter

Fear is measured 0–100. It is capped at 100 and cannot go negative.

**Fear Increase Sources:**

| Source | Fear Gained |
|---|---|
| Presence-class entity within 5 tiles | +8 per turn |
| Presence-class entity within 10 tiles | +3 per turn |
| Chase state active | +5 per turn |
| False echo experienced (player followed it) | +10 one-time |
| Sudden loud noise (Noise ≥ 14) at close range (≤ 4 tiles) | +15 one-time |
| NPC or companion killed nearby | +20 one-time |
| Ritual failure | +25 one-time |
| HP below 30% | +5 per turn |
| Extended time in darkness (no sight >20 turns) | +2 per turn |

**Fear Decrease Sources:**

| Source | Fear Lost |
|---|---|
| Safe zone (no enemies within 15 tiles, lit area) | −5 per turn |
| HP above 80% | −2 per turn |
| Using a calming consumable (e.g., salted herbs) | −20 one-time |
| Completing a successful ritual | −15 one-time |
| Exiting a floor | −30 one-time |

### 3.2 Fear States and Effects

| State | Fear Range | Effects |
|---|---|---|
| **Calm** | 0–25 | No penalties. |
| **Tense** | 26–50 | Sight radius −0 (no change). Audio glyphs flicker slightly at edges. Mild visual vignette. |
| **High Fear** | 51–75 | Sight radius −1. False glyph rate +10%. Edge vignette becomes prominent. |
| **Extreme Fear** | 76–100 | Sight radius −2. False glyph rate +15%. Memory tiles visually swim (unreadable for 1–2 turns). Sonar tier −2. |

Visual effects are presentational and must not make the game unplayable — even at Extreme Fear, memory tile terrain must be legible within 1 turn of being viewed.

### 3.3 Resonance Corruption Meter

Corruption is measured 0–50 (hard cap). It accumulates from occult actions and never resets within a run. Some late-game rituals can reduce it at a cost.

**Corruption Increase Sources:**

| Source | Corruption Gained |
|---|---|
| NOISE frequency sonar use | +1 per use |
| RITUAL frequency sonar use | +1 per use |
| Standing on ritual circle | +1 per 3 turns |
| Activating a seal | +2 |
| Ritual completion (successful) | +1–3 (varies by ritual) |
| Ritual failure | +4 |
| Using a Feedback Unit sonar | +2 per use |
| Equipping a forbidden instrument | +1 per floor |

**Corruption Decrease Sources:**

| Source | Corruption Lost |
|---|---|
| Purification ritual (specific, rare) | −5 |
| Salted holy water consumable | −2 |
| Exiting a cursed floor | −1 |

### 3.4 Corruption Thresholds and Effects

Corruption provides both advantages and penalties. Players choose how much to accumulate.

| Threshold | Unlocked Benefit | Penalty Applied |
|---|---|---|
| 0–9 | None | None |
| 10–19 | Can perceive spirit entities via audio map (additional glyph type) | False echo chance +10% |
| 20–29 | Can use RITUAL sonar in non-ritual rooms; can read sealed-door glyphs | Sonar tier −1 (noise in signal); false echo chance +25% |
| 30–39 | Spirit entities may not immediately aggro on sight (50% chance) | Normal NPC interaction worsens; possession risk begins |
| 40–49 | Access to highest-tier ritual effects; can perceive corruption-only environmental clues | Possession risk +20%; some endings locked |
| 50 | Hard cap — possession event triggers | Run-altering consequence (see §3.5) |

### 3.5 Possession Event (Corruption 50)

If the player reaches Corruption 50, a possession event is triggered:

- One equipped item becomes "corrupted" and behaves unpredictably (may fire at wrong times, wrong frequency, or not at all).
- One audio glyph type becomes permanently inverted (e.g., silence zone glyphs appear where sound should be and vice versa) for the remainder of the run.
- The player's own footsteps begin generating a secondary ghost echo — enemies who hear the player's movements also hear a secondary false position.
- The possession event cannot be undone, only managed.

This is not an instant fail state — it is a significant setback that the player must adapt to.

---

## 4. Formulas

### Fear Per Turn (Net Change)

```
fear_delta = Σ(fear_increase_sources) - Σ(fear_decrease_sources)
fear_next  = clamp(fear_current + fear_delta, 0, 100)

state = CALM    if fear < 26
      = TENSE   if fear < 51
      = HIGH    if fear < 76
      = EXTREME if fear ≤ 100
```

### False Glyph Probability (Combined)

```
false_glyph_chance = fear_bonus + corruption_bonus

fear_bonus        = {HIGH: 0.10, EXTREME: 0.15, else: 0.0}
corruption_bonus  = {≥10: 0.10, ≥20: 0.25, else: 0.0}

max false_glyph_chance = 0.35 (at Extreme Fear + Corruption ≥ 20)
```

False glyph chance is checked once per sonar action and once per passive hearing event. It is not checked per turn — only when a new glyph would be generated.

### Possession Risk Check

```
possession_roll_per_floor = random(0, 1)

if corruption >= 30:
    possession_threshold = (corruption - 30) × 0.02
    if possession_roll < possession_threshold:
        possession_event = minor  # single item corrupted, no glyph inversion
if corruption >= 50:
    possession_event = major  # full possession event as defined in §3.5
```

---

## 5. Edge Cases

- **Fear recovery in combat:** The player is in a room with a dying (but not yet dead) cultist. Is the player "safe" for fear recovery purposes? No — enemy presence (any) within 15 tiles blocks safe-zone recovery. Fear does not decrease while any enemy is in detection range.
- **Corruption at exactly 10 after sonar use:** The benefit unlocks immediately. The player can use the new spirit glyph type on the same turn Corruption reaches 10.
- **Fear Extreme + Corruption ≥ 20:** Both penalties apply simultaneously. Sonar tier is reduced by 2 (Extreme Fear) and false echo rate is 25% (Corruption) + 15% (Extreme Fear) = 35% combined. This stack is intentional — playing recklessly is punished by a cascade of information degradation.
- **Calming consumable during chase:** Consumes the item and reduces fear by 20. Does not end the chase or affect the pursuing entity. It purely reduces the information degradation penalties during a high-stakes moment.
- **Corruption at cap (50) with further accumulation attempt:** No additional Corruption is gained. The possession event triggers once on reaching 50, not repeatedly.
- **Purification ritual when already at 0:** Corruption cannot go negative. The ritual effect is wasted.

---

## 6. Dependencies

| System | Relationship |
|---|---|
| Vision System | Fear state drives sight_radius penalties |
| Audio Perception System | Fear and Corruption drive false glyph rate; Corruption unlocks spirit glyphs |
| Sonar System | Fear and Corruption apply tier penalties to sonar results |
| Chase System | Chase state increases Fear per turn; Corruption above threshold can trigger chase |
| Ritual System | Ritual success reduces Fear; ritual failure increases both Fear and Corruption |
| Enemy Design | Possession event corrupts enemy attraction behavior for ghost-step mechanic |

---

## 7. Tuning Knobs

| Knob | Draft Value | Notes |
|---|---|---|
| `fear_max` | 100 | Hard cap |
| `corruption_max` | 50 | Hard cap; possession trigger |
| `fear_per_turn_presence_close` | +8 | Entity within 5 tiles |
| `fear_per_turn_presence_mid` | +3 | Entity within 10 tiles |
| `fear_per_turn_chase` | +5 | While in chase state |
| `fear_safe_zone_recovery` | −5 per turn | No enemies within 15 tiles |
| `fear_hp_recovery` | −2 per turn | HP > 80% |
| `corruption_noise_sonar` | +1 | Per NOISE frequency sonar use |
| `corruption_ritual_success_range` | +1–3 | Varies by ritual tier |
| `corruption_ritual_failure` | +4 | |
| `corruption_spirit_threshold` | 10 | Spirit glyph unlock |
| `corruption_possession_risk_start` | 30 | Possession roll begins |
| `corruption_possession_hard` | 50 | Full possession event |
| `false_glyph_high_fear` | +10% | Added to false glyph rate |
| `false_glyph_extreme_fear` | +15% | Added to false glyph rate |
| `false_glyph_corruption_10` | +10% | Added to false glyph rate |
| `false_glyph_corruption_20` | +25% | Replaces corruption_10 bonus |

---

## 8. Acceptance Criteria

- [ ] At Fear 0 (Calm), no sight penalty applies and no false glyphs are generated.
- [ ] At Fear 76–100 (Extreme), sight radius is reduced by exactly 2 tiles and sonar tier is reduced by 2.
- [ ] Fear decreases at the safe-zone rate (−5/turn) when no enemy is within 15 tiles.
- [ ] Fear does not decrease during an active chase.
- [ ] Corruption increases by 1 each time a NOISE-frequency sonar action is used; confirmed via stat display.
- [ ] At Corruption 10, spirit-entity audio glyphs appear that were previously invisible; confirmed by placing a Spirit entity in a controlled test scenario.
- [ ] At Corruption 50, the possession event triggers: one item is flagged corrupted and one glyph type is inverted.
- [ ] The possession event at Corruption 50 triggers only once per run.
- [ ] Combined false glyph chance at Extreme Fear + Corruption ≥ 20 is 35%, verifiable via a 100-ping controlled test (approximately 35 false returns ±5).
