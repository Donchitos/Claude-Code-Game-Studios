# GDD: Ritual System

**Status:** Draft  
**Layer:** Feature  
**Last Updated:** 2026-05-16  
**Dependencies:** Fear/Corruption System, Equipment System, Chase System, Noise System

---

## 1. Overview

The Ritual System lets the player interact with occult structures in the world — altars, circles, seals, and resonance points — to achieve effects not accessible through combat or movement. Rituals require the right location, the right conditions, and the willingness to spend Corruption and potentially Fear. Successful rituals range from unlocking sealed passages to temporarily stopping a pursuing entity. Failed rituals punish immediately with noise events, Fear spikes, Corruption gain, and sometimes a triggered chase. The system is designed so that rituals always feel consequential — cheap successes do not exist, and failures have real costs.

---

## 2. Player Fantasy

The player feels like they are touching something they do not fully understand. Every ritual is a gamble: the player knows what they are offering and roughly what they hope to receive, but the outcome is never guaranteed. A successful ritual feels like a reprieve from the dark. A failed one feels like a punishment for reaching too far. Over multiple runs, players learn which rituals are worth attempting and in which rooms.

---

## 3. Detailed Rules

### 3.1 Ritual Roles

Rituals can accomplish the following effects (subject to ritual tier and conditions):

| Category | Example Effects |
|---|---|
| Passage | Unseal a locked door; reveal a hidden staircase; open a warded gate |
| Suppression | Temporarily halt a pursuing entity (8–12 turns); reduce noise in the room |
| Revelation | Reveal the full layout of one adjacent room; expose a hidden entity |
| Consequence | Summon a boss; change the map (collapse a passage, open a new one) |
| Fortification | Bless an item; create a temporary binding circle; ward a room |
| Corruption Trade | Exchange HP or item for reduced Corruption; raise Corruption for power |
| Ending Branch | Certain rituals in specific rooms affect the available endings |

### 3.2 Ritual Conditions

Each ritual requires a combination of:

| Condition Type | Examples |
|---|---|
| **Location** | Must stand on an altar, ritual circle, or designated site |
| **Sound** | Specific frequency class emitted (MID chant, LOW drone, RITUAL sonar) |
| **Offering** | HP sacrifice, item consumed, Corruption accepted |
| **Time** | Must complete within a turn window (e.g., 5 turns of sustained action) |
| **Silence** | No noise generated for N turns before or during the ritual |
| **Witness** | An NPC, enemy, or neutral entity must be present in the room |
| **Equipment** | Specific Ritual Object required (see Equipment GDD) |

Not every ritual requires all condition types. Simpler rituals may require only location + sound. Powerful rituals typically require 4–5 conditions simultaneously.

### 3.3 Ritual Tiers

| Tier | Complexity | Corruption Cost | Typical Effect |
|---|---|---|---|
| 1 — Minor | 1–2 conditions | +1 | Bless item, ward a single tile, minor reveal |
| 2 — Standard | 3 conditions | +2 | Unseal door, partial map reveal, entity slow |
| 3 — Major | 4–5 conditions | +3 | Entity suppression, floor-wide effect, major passage |
| 4 — Forbidden | 5+ conditions + HP | +5 | Summon / banish entity, alter floor structure, ending branch |

Tier 4 rituals require a Blood Sigil ritual object. They cannot be performed with other Ritual Objects.

### 3.4 Ritual Execution

Rituals are multi-turn actions. The player initiates a ritual by activating a ritual site while holding the required Ritual Object. Each turn the player remains in the ritual:

1. The player cannot move (the ritual is interrupted if they move or are struck).
2. The ritual generates noise at the room level (all enemies in the room receive the noise event).
3. A progress indicator appears in the UI showing turns remaining.
4. The player may cancel at any time before completion (no success, no failure — but partial Corruption may still be gained based on turns spent).

### 3.5 Ritual Success Conditions

The ritual succeeds when:

- All conditions remain satisfied for the required number of turns.
- The player is not interrupted (struck by an enemy, or forced to move).
- The required offering has been made.

On success:
- Effect triggers immediately.
- Fear −15.
- Corruption +ritual_tier (see §3.3).

### 3.6 Ritual Failure Conditions

The ritual fails if:

- A required condition is broken before completion (enemy enters room, a sound is made when silence is required, etc.).
- An enemy strikes the player during the ritual.
- The player moves.
- A specific entity type enters the ritual radius (some entities break rituals passively).

On failure, consequences scale with how far the ritual progressed:

| Progress at Failure | Consequences |
|---|---|
| < 25% complete | No effect. Corruption +1. Fear +10. |
| 25–75% complete | Noise event (room-wide). Corruption +4. Fear +25. One random entity in adjacent rooms alerted. |
| > 75% complete | All of above + chase triggered. Corruption +4. Fear +25. Room structure may change. |

### 3.7 Ritual Interruption vs. Cancellation

- **Cancel** (player-initiated before failure): No success, no penalty. Corruption +1 for time spent (1 per tier of ritual, regardless of turns).
- **Interrupt** (external cause): Treated as failure with progress-based consequences above.

### 3.8 Special Ritual: Silence Ritual

The Silence Ritual requires zero noise for `silence_ritual_turns` consecutive turns at a specific resonance point. It cannot be combined with any active sonar. If successful, it reduces noise in the room permanently (all sound_multiplier values on tiles in the room halved for the rest of the run) and suppresses one entity's tracking for `silence_suppress_turns` turns.

The Silence Ritual is the hardest ritual to complete — the silence requirement means the player cannot use any equipment or perform any action other than wait. It is interrupted by any sound, including enemy sounds generated near the player.

---

## 4. Formulas

### Ritual Noise Level Per Turn

```
ritual_noise_per_turn = ritual_tier × 3 + sound_source_bonus

sound_source_bonus = {ritual_horn: +3, bone_flute: +1, else: 0}
```

This noise is room-wide and hits all enemies in the room simultaneously each turn the ritual is in progress.

### Partial Corruption on Cancel

```
corruption_on_cancel = ceil(ritual_tier × turns_completed / total_turns_required)
corruption_on_cancel = max(corruption_on_cancel, 1)
```

### Failure Consequence Threshold

```
progress_fraction = turns_completed / total_turns_required

if progress_fraction < 0.25: consequence = MINOR
if progress_fraction < 0.75: consequence = MODERATE
else:                         consequence = SEVERE
```

---

## 5. Edge Cases

- **Entity enters room mid-ritual (non-interrupting):** Not all entities interrupt rituals. Patrol enemies in the same room do not interrupt unless they detect the player. Only entities with the `ritual_breaker` flag interrupt passively.
- **Ritual at 99% progress, player struck:** Treated as failure at > 75% completion. Full severe consequence applies. There is no "almost made it" exception.
- **Ritual circle on water tile:** The ritual circle's `sound_multiplier = 2.0` applies, but water's low-frequency propagation also applies. LOW-frequency rituals on water circles broadcast at extreme range. Players should be aware this may wake deep entities.
- **Multiple rituals in sequence on same altar:** An altar can be reused after a cooldown of `altar_cooldown_turns` turns. Attempting to use it before cooldown expires simply fails to initiate with no penalty.
- **Ritual during chase:** If the player is in a chase state, ritual initiation is blocked. The UI displays a warning. Only the Silence Ritual (no-sound) can theoretically succeed during a chase, but the chase itself generates entity noise that may interrupt the silence requirement.
- **Corruption cap during ritual:** If Corruption reaches 50 during a ritual's Corruption gain (e.g., Tier 4 ritual when at 48), the possession event triggers mid-ritual. The ritual continues (or fails based on possession effects) — possession does not automatically interrupt the ritual.
- **Ending branch rituals:** These are locked to specific rooms and floor depths. The ritual UI indicates if an ending consequence is available. Players cannot undo an ending-branch ritual once completed.

---

## 6. Dependencies

| System | Relationship |
|---|---|
| Fear / Corruption System | Ritual success reduces Fear; all rituals gain Corruption; failure spikes both |
| Equipment System | Ritual Objects are required; Sound Source type affects ritual noise level |
| Chase System | Ritual failure at > 75% progress triggers a chase; some rituals terminate a chase |
| Noise System | Ritual actions generate room-wide noise events each turn |
| Enemy Design | Some entities have `ritual_breaker` flag that interrupts rituals passively |
| Audio Perception System | Ritual audio events render as RITUAL-class glyphs on the audio map |

---

## 7. Tuning Knobs

| Knob | Draft Value | Notes |
|---|---|---|
| `ritual_tier_1_corruption` | +1 | |
| `ritual_tier_2_corruption` | +2 | |
| `ritual_tier_3_corruption` | +3 | |
| `ritual_tier_4_corruption` | +5 | Forbidden tier |
| `ritual_success_fear_reduction` | −15 | |
| `ritual_failure_moderate_fear` | +25 | At 25–75% progress failure |
| `ritual_failure_moderate_corruption` | +4 | |
| `silence_ritual_turns` | 8 turns | Required silence duration |
| `silence_suppress_turns` | 10 turns | Duration of entity tracking suppression |
| `altar_cooldown_turns` | 5 turns | Per-altar reuse cooldown |
| `ritual_noise_per_turn_base` | tier × 3 | Room-wide noise per ritual turn |
| `cancel_corruption_floor` | 1 | Minimum Corruption on cancel |

---

## 8. Acceptance Criteria

- [ ] A Tier 1 ritual on a valid altar with correct conditions completes successfully; Fear −15 and Corruption +1 are applied on completion.
- [ ] A ritual interrupted at 80% completion triggers a chase and applies Corruption +4 and Fear +25.
- [ ] A ritual cancelled by the player at 50% completion applies Corruption +1 (floor) and no other penalty.
- [ ] Ritual noise (room-wide) is generated each turn the ritual is in progress; a Blind Listener (threshold 2) in the same room reacts to the first turn of a Tier 1 ritual (noise = 3 × 1 = 3 ≥ 2).
- [ ] An altar cannot be reused until `altar_cooldown_turns` turns have elapsed; attempting early use shows no initiation response.
- [ ] A Tier 4 ritual requires a Blood Sigil ritual object; attempting with any other object fails to initiate.
- [ ] The Silence Ritual is interrupted if any sound event above 0 occurs during its `silence_ritual_turns` duration.
- [ ] A successful Silence Ritual halves the `sound_multiplier` of all tiles in the room for the remainder of the run.
