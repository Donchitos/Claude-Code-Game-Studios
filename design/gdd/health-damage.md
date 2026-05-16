# Health & Damage

> **Status**: Designed (pending /design-review)
> **Author**: Claude Code Game Studios (design-system)
> **Last Updated**: 2026-05-15
> **Implements Pillar**: Pillar 2 — Asymmetry Is the Point; Pillar 3 — Every Match Tells a Story

## Overview

Health & Damage is the server-authoritative system that tracks, applies, and resolves all damage events in SYNTHFALL. It maintains HP pools for all combatants — Reclaimers (individual HP per operative) and Synth units (per-unit HP pools sized to unit tier) — applies incoming damage against an armor state modifier, evaluates the result against threshold conditions (Downed, Eliminated), and broadcasts state changes to all subscribed systems.

Reclaimer HP is backed by three armor states — **Operational** (full capability), **Compromised** (partial damage taken), and **Critical** (near-downed, impaired) — that degrade as HP falls through defined thresholds. When HP reaches the Downed threshold, the Reclaimer cannot fight; locomotion is suspended and the K&R window opens. When HP reaches zero, the operative is Eliminated. Synth units have no armor-state progression — they have HP pools and a single death threshold per unit type.

Damage inputs are typed — **Ballistic** (weapon fire, explosions), **Environmental** (fall, toxin flooding, floor collapse), and **Synth** (direct ability damage) — with per-type modifiers applied before the armor calculation. All damage application is server-authoritative: clients register hits and request damage via the damage interface; the server validates, applies, and synchronizes results via `NetworkVariable`.

This system has no direct player interaction surface — Reclaimers never consciously "use" health. Its player fantasy (the weight of every hit, the clarity of how close to gone you are) is expressed entirely through the armor state feedback loop and the downed moment. That fantasy is defined in Section B.

## Player Fantasy

Reclaimers are not soldiers with regenerating shields. They are people inside a city that is actively trying to remove them. Every hit lands with permanence — armor doesn't regenerate between firefights, and the visual and audio feedback of each armor state transition makes the player viscerally aware of how much runway they have left.

**The armor state is a mood.** Operational feels like controlled aggression — you can push, take risks, cover ground. Compromised shifts the calculus: every engagement is now a question of whether it's worth it. Critical is a countdown. A Critical Reclaimer doesn't stop playing, but they stop leading — they become someone the squad has to manage, protect, route around. The moment a squadmate calls out "I'm Critical" is the moment the mission's tone shifts.

**Going downed is the game's highest-drama beat.** You hit the ground, locomotion stops, the world doesn't — Synth units keep coming, the Corruption meter climbs, your teammates have to decide in real-time whether they can reach you or have to push the objective anyway. The downed moment is where squads either crystallize into something extraordinary or fracture under pressure. It's the moment every match remembers.

**Synth units die differently.** There are no armor states, no Compromised warnings — a Stalker keeps coming at full capability until it doesn't. This asymmetry is deliberate: Reclaimers are fragile and legible; Synth units are opaque threats. Killing a Stalker feels final. Being hit by one does not feel survivable by default.

**Pillar alignment**: Pillar 2 (Asymmetry Is the Point — the survival economy of Reclaimers is nothing like the death economy of Synth units; the gap is the design). Pillar 3 (Every Match Tells a Story — the downed moment is where stories are made; health state degradation is the pacing engine for those stories).

> *`creative-director` not consulted — Lean mode. Review manually before production.*

## Detailed Design

### Core Rules

1. **Unified Reclaimer HP pool**: All four Reclaimer classes share the same max HP (`HP_MAX`). Class differentiation is expressed through movement feel and abilities, not survivability. No class has more HP than another.
2. **HP range**: Reclaimer HP tracks as a float `[0.0, HP_MAX]`, displayed to players as integers. HP can only be modified server-side.
3. **Armor states**: As Reclaimer HP drops through defined thresholds, the Reclaimer transitions through three named states — **Operational**, **Compromised**, **Critical** — each triggering visual, audio, and HUD feedback. Armor states are feedback layers; they do not themselves reduce incoming damage (the damage type modifier handles that).
4. **Downed state**: When HP reaches 0.0, the Reclaimer enters **Downed** — incapacitated but alive. Locomotion is disabled. A bleedout timer begins. K&R (#12) governs the revival window.
5. **Eliminated**: A Downed Reclaimer becomes **Eliminated** when the bleedout timer expires without revival. There is no instant-kill protection below Downed — any damage to a Downed Reclaimer is absorbed (HP cannot go below 0 while awaiting K&R). Elimination is the final, session-impactful event — not Downed.
6. **No passive regeneration**: HP does not recover on its own. All healing is applied through the Medic's trauma kit and revival injectors (Reclaimer Class Abilities #11 governs exact heal values). Item pickups may also restore HP (defined by Ammo & Resource Management #10).
7. **Synth unit HP pools**: Synth units have HP pools defined by unit type (see Unit HP Table below). Synth units have no armor states — they operate at full capability until HP reaches 0, at which point they are immediately Eliminated.
8. **`IDamageable` interface**: All damageable entities (Reclaimers and Synth units) implement `IDamageable.TakeDamage(float baseAmount, DamageType type)`. The interface handles type-modifier lookup, HP clamping, and state transition evaluation. External systems never write HP directly.
9. **Server authority**: All `TakeDamage()` calls are processed on the server. Clients submit `DamageRequestServerRpc(targetId, baseAmount, type)` — the server validates the request, applies the damage, and synchronizes the resulting HP via `NetworkVariable<float>`. *(Provisional — authority model pending Networking Layer GDD #1.)*
10. **Corruption events on state change**: On entering Downed, the server fires `CorruptionInputEvent(+TEAMMATE_DOWNED_WEIGHT)` = +5.0%. On Elimination, the server fires `CorruptionInputEvent(+TEAMMATE_ELIMINATED_WEIGHT)` = +3.0%. These match the registered constants from the Corruption Meter GDD.

---

### Damage Type Modifiers

Incoming damage is modified by the Reclaimer's current armor state and the damage type:

```
HP_new = clamp(HP_prev − (baseDamage × ARMOR_MULT[damageType][armorState]), 0, HP_MAX)
```

| Damage Type | Description | Operational | Compromised | Critical |
|---|---|---|---|---|
| **Ballistic** | Weapon fire, explosions | 0.80× | 1.00× | 1.10× |
| **Environmental** | Fall, toxin, floor collapse, power surge | 1.00× | 1.00× | 1.00× |
| **Synth** | Direct unit ability damage, Synth trap activation | 1.00× | 1.00× | 1.00× |

**Design rationale**:
- **Ballistic** is reduced by intact armor (0.80× at Operational) — the squad's protective gear matters early. As armor degrades, bullets hit harder.
- **Environmental** bypasses armor state — the city's hazards are equally dangerous regardless of armor integrity. A freshly spawned Reclaimer takes full toxin damage.
- **Synth** ignores armor state — Synth-tier technology is designed to punch through human defensive systems. Consistent threat regardless of health state.

---

### Reclaimer Armor State Table

| State | HP Range | Trigger | Player Communication |
|---|---|---|---|
| **Operational** | HP > COMPROMISED_THRESHOLD (60) | Default start state | Full-color HUD, normal movement, no overlay |
| **Compromised** | HP ∈ (CRITICAL_THRESHOLD, COMPROMISED_THRESHOLD] | HP drops through 60 | Amber HUD tint, armor-crack audio sting, squad pips update |
| **Critical** | HP ∈ (0, CRITICAL_THRESHOLD] | HP drops through 30 | Red pulsing HUD vignette, labored audio, squad pips update |
| **Downed** | HP = 0 | HP reaches 0 | Screen desaturates, crawl view, K&R overlay |
| **Eliminated** | Post-bleedout | Bleedout timer expires | Final death screen, squad notified |

State transitions are **one-directional downward** without healing. Healing reverses the transition (e.g., Medic restores HP from Critical back to Compromised or Operational).

---

### Synth Unit HP Table

| Unit | HP Pool | Death Threshold | Armor State | Design Intent |
|---|---|---|---|---|
| **Crawler** | 40 HP | 0 HP | None | Fragile swarm unit — 1–2 Ballistic hits; dies fast, applies pressure through numbers |
| **Stalker** | 250 HP | 0 HP | None | Tanky single-target — requires sustained squad focus fire; does not telegraph weakness |
| **Pulse Drone** | 75 HP | 0 HP | None | Aerial; moderate durability; prioritized target but not trivial to kill |

*Synth unit HP values are defined here as the authoritative source. Synth Unit Roster GDD (#13) may add further unit types — each must register an HP value in this GDD's Tuning Knobs table.*

---

### Fall Damage (Environmental sub-type)

Fall damage is classified as Environmental damage type and applies the 1.00× armor modifier at all states.

```
FALL_DAMAGE = clamp(max(0, fall_distance − FALL_SAFE_DISTANCE) × FALL_DAMAGE_RATE, 0, FALL_DAMAGE_CAP)
```

Delivered as a single `TakeDamage(FALL_DAMAGE, DamageType.Environmental)` call on landing.

---

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| Knockdown & Revival (#12) | H&D → K&R | Fires `DownedEvent(reclaimer_id)` when HP = 0; K&R opens bleedout timer and revival window. Movement receives `DisableLocomotion(true)` simultaneously. |
| Corruption Meter (#3) via event | H&D → Corruption | Server fires `CorruptionInputEvent(+5.0%)` on Downed; `CorruptionInputEvent(+3.0%)` on Elimination. Values match `TEAMMATE_DOWNED_WEIGHT` and `TEAMMATE_ELIMINATED_WEIGHT` in registry. |
| Reclaimer Combat (#6) | Combat → H&D | Combat calls `TakeDamage(amount, DamageType.Ballistic)` on confirmed hit. H&D is the receiver; Combat does not write HP. |
| Reclaimer Movement (#4) | H&D → Movement | On Downed, sends `DisableLocomotion(true)` flag. On revival (via K&R), sends `DisableLocomotion(false)`. |
| Reclaimer HUD (#20) | H&D → HUD | HP value and `ArmorState` enum published via `NetworkVariable`; HUD subscribes to `OnValueChanged` for real-time display. |
| Win/Loss Conditions (#18) | H&D → Win/Loss | Fires `EliminationEvent(reclaimer_id)` on Elimination; Win/Loss tracks squad-wide elimination count for loss condition. |
| Level / Environmental Controls (#15) | Level → H&D | Toxin ticks, floor collapse events, power surge traps call `TakeDamage(amount, DamageType.Environmental)` on Reclaimers in affected zones. H&D is the receiver. |
| Synth Unit Roster (#13) | Roster → H&D | Synth units call `TakeDamage(amount, DamageType.Synth)` on Reclaimers within range. Unit death events from H&D (HP = 0) are consumed by the Synth AI system for despawn. |

## Formulas

### Formula 1: Reclaimer Damage Application

```
HP_new = clamp(HP_prev − (BASE_DAMAGE × ARMOR_MULT[damageType][armorState]), 0.0, HP_MAX)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Previous HP | HP_prev | float | 0.0–HP_MAX | Reclaimer HP before this damage event |
| Maximum HP | HP_MAX | float | 100.0 | Constant cap. All Reclaimer classes share this value. |
| Base incoming damage | BASE_DAMAGE | float | 0.0–∞ | Raw damage value supplied by the damaging system (weapon, hazard, unit) before modifiers |
| Armor state multiplier | ARMOR_MULT | float | 0.80–1.10 | Per (DamageType, ArmorState) lookup (see table below) |
| Resulting HP | HP_new | float | 0.0–HP_MAX | HP after clamping; triggers armor state re-evaluation |

**ARMOR_MULT Lookup Table:**

| | Operational | Compromised | Critical |
|---|---|---|---|
| Ballistic | 0.80 | 1.00 | 1.10 |
| Environmental | 1.00 | 1.00 | 1.00 |
| Synth | 1.00 | 1.00 | 1.00 |

**Output range:** HP_new ∈ [0.0, 100.0]

**Examples:**
- Ballistic hit (20 base) on Operational Reclaimer: HP_new = HP_prev − (20 × 0.80) = HP_prev − 16
- Ballistic hit (20 base) on Critical Reclaimer: HP_new = HP_prev − (20 × 1.10) = HP_prev − 22
- Environmental hit (toxin, 10 base) on Operational Reclaimer: HP_new = HP_prev − (10 × 1.00) = HP_prev − 10

**Post-application:** After HP_new is computed, the armor state is re-evaluated:
- HP_new > 60 → Operational
- HP_new ∈ (30, 60] → Compromised
- HP_new ∈ (0, 30] → Critical
- HP_new = 0 → Downed

---

### Formula 2: Fall Damage (Environmental sub-type)

```
FALL_DAMAGE = clamp(max(0, fall_distance − FALL_SAFE_DISTANCE) × FALL_DAMAGE_RATE, 0, FALL_DAMAGE_CAP)
```

Applied as `TakeDamage(FALL_DAMAGE, DamageType.Environmental)` on landing frame.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Fall distance | fall_distance | float | 0.0–∞ m | Vertical distance fallen (from last grounded position to landing) |
| Safe fall threshold | FALL_SAFE_DISTANCE | float | 1.0–5.0 m | Falls below this distance deal no damage (default: 3.0 m) |
| Damage per meter | FALL_DAMAGE_RATE | float | 5–30 HP/m | HP lost per meter of fall above FALL_SAFE_DISTANCE (default: 10 HP/m) |
| Fall damage cap | FALL_DAMAGE_CAP | float | HP_MAX | Maximum fall damage in a single fall; capped at 100 HP (any fall above cap sends Reclaimer directly to Downed) |

**Output range:** FALL_DAMAGE ∈ [0.0, 100.0]

**Examples:**
- Fall from 2m: FALL_DAMAGE = max(0, 2.0 − 3.0) × 10 = 0 (no damage — within safe range)
- Fall from 5m: FALL_DAMAGE = (5.0 − 3.0) × 10 = 20 HP
- Fall from 15m: FALL_DAMAGE = clamp((15.0 − 3.0) × 10, 0, 100) = 100 HP → Downed regardless of current HP

---

### Formula 3: Armor State Evaluation

Not a calculation — a threshold comparison run server-side after every HP change:

```
if   HP_new > COMPROMISED_THRESHOLD:  ArmorState = Operational
elif HP_new > CRITICAL_THRESHOLD:     ArmorState = Compromised
elif HP_new > 0:                      ArmorState = Critical
else:                                  ArmorState = Downed
```

**Variables:**

| Variable | Type | Value | Description |
|---|---|---|---|
| COMPROMISED_THRESHOLD | float | 60.0 | HP floor of Operational state; below this → Compromised |
| CRITICAL_THRESHOLD | float | 30.0 | HP floor of Compromised state; below this → Critical |

**Transition events fired**: State change from any state to a lower state fires the appropriate visual/audio feedback event to the HUD and audio system. State change to Downed additionally fires `DownedEvent` and the Corruption input event.

> *`systems-designer` not consulted — Lean mode. Validate Ballistic ARMOR_MULT values (0.80/1.00/1.10), unit HP pools (Crawler 40, Stalker 250, Pulse Drone 75), and fall damage rate (10 HP/m) against playtest targets before production.*

## Edge Cases

- **If a Reclaimer receives damage that would reduce HP to exactly 0.0**: Reclaimer enters Downed state. HP does not go negative. `clamp(..., 0.0, HP_MAX)` handles this — the Downed event fires at 0.0, not at a negative value.

- **If a Reclaimer receives damage while already Downed**: Damage is silently absorbed — `TakeDamage()` returns immediately with no HP change (HP is already 0.0 and cannot go lower). No additional Corruption event fires. The bleedout timer is not reset by further damage. Reclaimers cannot be "confirmed killed" by continued shooting while Downed — only bleedout timer expiry triggers Elimination.

- **If two damage events arrive at the server in the same frame targeting the same Reclaimer**: Process in the order received. Each event evaluates against the HP value left by the previous event. Race condition is resolved by server tick order — clients do not guarantee simultaneous hit delivery. If both would independently cause a Downed transition, only one `DownedEvent` fires (state was already Downed after the first).

- **If fall distance is measured on geometry that moves** (floor collapse triggers mid-fall): Fall distance is measured from the last confirmed grounded position at launch frame. If the floor moved after the Reclaimer left it, the measurement origin does not update. This keeps fall damage calculations deterministic.

- **If a Medic heals a Downed Reclaimer**: Downed Reclaimers cannot receive healing through normal HP writes (HP is 0.0 and the Downed state blocks standard `TakeDamage()` reversal). K&R GDD (#12) owns the revival mechanic — revival restores a defined HP amount and explicitly exits Downed state. The transition from Downed to any active armor state must go through K&R's revival path, not a direct HP add.

- **If HP heals across an armor state threshold in one event**: State re-evaluation runs after every HP change, including healing. If Medic heals a Critical Reclaimer from 25 HP to 65 HP in one event, the resulting state is Operational (65 > 60). The intermediate Compromised state is never communicated — only the final state is broadcast. The armor state transition audio/visual plays for the destination state only.

- **If `COMPROMISED_THRESHOLD` and `CRITICAL_THRESHOLD` are tuned to equal values**: One armor state collapses — no HP range maps to it. This is a degenerate configuration. Tuning validation must enforce `CRITICAL_THRESHOLD < COMPROMISED_THRESHOLD < HP_MAX`. If equal values are detected at runtime, default values (60/30) are restored with a console warning.

- **If a Synth unit's HP is set to 0 in tuning** (e.g., during test configuration): Unit spawns in Eliminated state immediately. Valid test scenario; server-side spawn validation should log a warning and block 0-HP spawns in non-test environments.

- **If a level hazard deals 0 base damage** (e.g., inactive toxin zone): `TakeDamage(0.0, Environmental)` is a no-op. HP_new = HP_prev. No state change event fires. No performance concern.

- **If the server loses authority mid-damage application** (network partition): *(Provisional — Networking Layer GDD #1 must define authority recovery. Current assumption: in-flight damage events are dropped; HP state at reconnect reflects the last server-authoritative value.)*

## Dependencies

| System | Direction | Nature | GDD Status |
|---|---|---|---|
| Networking Layer (#1) | This depends on | Server-authoritative HP sync via `NetworkVariable<float>`; `DamageRequestServerRpc` pattern; late-join HP initialization | ⚠️ Not designed — provisional |
| Reclaimer Combat (#6) | Combat → H&D | Combat calls `TakeDamage(amount, Ballistic)` on confirmed hits; H&D defines HP_MAX and damage response | Not yet designed |
| Knockdown & Revival (#12) | H&D ↔ K&R | H&D fires `DownedEvent` on HP=0; K&R opens revival window and calls revival HP restore on success; K&R triggers `DisableLocomotion(true/false)` via Movement | Not yet designed |
| Corruption Meter (#3) | H&D → Corruption | H&D fires `CorruptionInputEvent(+5.0%)` on Downed and `CorruptionInputEvent(+3.0%)` on Elimination | ✅ Designed |
| Reclaimer Movement (#4) | H&D → Movement | H&D sends `DisableLocomotion(true)` on Downed, `DisableLocomotion(false)` on revival | ✅ Designed |
| Win/Loss Conditions (#18) | H&D → Win/Loss | H&D fires `EliminationEvent(reclaimer_id)`; Win/Loss tracks squad-wide elimination count for loss condition | Not yet designed |
| Reclaimer HUD (#20) | H&D → HUD | HP float and `ArmorState` enum published via `NetworkVariable`; HUD subscribes to `OnValueChanged` for real-time display | Not yet designed |
| Level / Environmental Controls (#15) | Level → H&D | Environmental hazards deliver `TakeDamage(amount, Environmental)` to Reclaimers in affected zones | Not yet designed |
| Synth Unit Roster (#13) | Roster → H&D | Synth units register HP pools here (Crawler 40, Stalker 250, Pulse Drone 75); unit death events trigger despawn logic in Roster | Not yet designed |
| Reclaimer Class Abilities (#11) | Abilities → H&D | Medic healing applies HP restoration via H&D interface; exact heal values owned by Class Abilities GDD | Not yet designed |
| Ammo & Resource Management (#10) | Resources → H&D | Item pickups may restore HP; pickup values owned by Resource Management GDD | Not yet designed |

**Hard dependencies**: Networking Layer (#1)
**Soft dependencies**: All others — Health & Damage can function standalone for isolated testing; other systems call its interface.

## Tuning Knobs

| Knob | Default | Safe Range | Affects |
|---|---|---|---|
| HP_MAX | 100.0 HP | 60–150 HP | All Reclaimer survivability; changes cascade to all threshold calculations |
| COMPROMISED_THRESHOLD | 60.0 HP | 40–80 HP | Where the "in trouble" state begins; must remain > CRITICAL_THRESHOLD |
| CRITICAL_THRESHOLD | 30.0 HP | 10–50 HP | Where "countdown" state begins; must remain < COMPROMISED_THRESHOLD |
| ARMOR_MULT[Ballistic][Operational] | 0.80× | 0.50–1.00× | Early-fight Ballistic resistance; lower = easier opener, higher = same as Compromised |
| ARMOR_MULT[Ballistic][Critical] | 1.10× | 1.00–1.50× | Extra vulnerability at Critical; below 1.0 makes Critical feel safer than Compromised |
| Crawler HP | 40 HP | 20–80 HP | Crawler fragility; lower = more swarm-deletable, higher = requires more ammo-per-kill |
| Stalker HP | 250 HP | 150–400 HP | Stalker threat duration; lower = squad can burst it down quickly, higher = sustained horror |
| Pulse Drone HP | 75 HP | 40–120 HP | Aerial target durability; keep lower than Stalker to make air superiority achievable |
| FALL_SAFE_DISTANCE | 3.0 m | 1.0–5.0 m | Minimum fall height for damage; higher = more forgiveness for vertical level design |
| FALL_DAMAGE_RATE | 10.0 HP/m | 5–30 HP/m | Damage per meter above safe distance; higher = verticality becomes a genuine threat |
| FALL_DAMAGE_CAP | 100.0 HP | HP_MAX | Maximum fall damage; always capped at HP_MAX unless single-fall lethality is desired |
| TEAMMATE_ELIMINATED_WEIGHT | 3.0% | 1.0–8.0% | Corruption added on Elimination; source of truth in Corruption Meter GDD — tune there |

**Constraint**: `CRITICAL_THRESHOLD < COMPROMISED_THRESHOLD < HP_MAX` must hold at all times. Runtime validation enforces this — if violated, defaults (60/30) are restored with a console warning.

**Synth unit HP extensibility**: Additional Synth unit types beyond Crawler/Stalker/Pulse Drone are registered by Synth Unit Roster GDD (#13). Each new unit type should be added as a row to this table when designed.

## Visual/Audio Requirements

> *`art-director` not consulted — Lean mode. Validate against art bible (Dark Martian Brutalism) before implementing.*

### Armor State Visual Feedback

Each armor state transition must communicate the new state within one frame of the HP threshold crossing. Visual feedback is layered: screen-space overlays for the local Reclaimer's POV; squad pip color changes for remote Reclaimers.

| Transition | Screen FX (local POV) | Audio (local POV) | Squad Pip (remote) |
|---|---|---|---|
| Any → Compromised | Amber vignette bleeds in at screen edges; armor-crack texture overlay fades in on HUD | Short metallic fracture sting; suit system alert tone | Pip color shifts from green → amber |
| Compromised → Critical | Red pulsing vignette; heartbeat rhythm begins; HUD elements desaturate partially | Labored breath audio layer; urgent system alarm | Pip color shifts amber → red with slow pulse |
| Any → Downed | Full screen desaturation; FOV narrows to crawl-height perspective; K&R overlay appears | Heavy impact thud; suit failure tone; ambient becomes muffled | Pip color shifts to grey with blinking dot; "DOWNED" label appears |
| Downed → Eliminated | Flash to black; mission log updates | Squad-wide audio sting ("[Callsign] eliminated") | Pip goes dark; X marker |

**Art bible alignment**: Reclaimer HUD elements are warm amber/orange (established in art bible Color System). Synth-controlled threat indicators are electric blue/violet. Armor degradation moves from amber → red — consistent with the established warm-to-emergency palette.

### Damage Received Feedback

- **Directional hit indicator**: When taking Ballistic or Synth damage, a directional indicator on the screen edge points toward the damage source. Active for 1.5 seconds after last hit. Consistent with art bible UI language (icon-based, not text).
- **Hit flash**: Brief (<0.1s) full-screen red tint on any HP-reducing damage event. Intensity scales with damage amount (light flash for 5 HP, heavy flash for 30+ HP).
- **Environmental damage**: No directional indicator (hazards are area effects). Pulsing edge tint while in a damaging zone (toxin = violet tint aligning with Synth corruption color palette; fall = single red flash on landing).

### Synth Unit Death Visual

Health & Damage fires the death event; Synth Unit Roster GDD (#13) and the VFX system own the death animation. H&D requirement: death event must be broadcast with enough lead time for a death-in-progress animation to complete before entity despawns (minimum 1.0s delay between HP=0 and actual GameObject despawn).

### Audio Priority

- All damage audio runs at HIGH mix priority to ensure hits are not lost in ambient and music
- Downed state audio (muffled ambient + heartbeat) overrides ambient music layer for the downed player only
- Squad pip audio callouts ("Operative downed") run at CRITICAL priority — must not be ducked by any other system

> **📌 Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:health-damage` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## UI Requirements

> **📌 UX Flag — Health & Damage**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the HP bar and squad pip elements before writing implementation epics.

### HP Bar (Local Reclaimer)

- Always-visible HUD element showing current HP as a bar [0–HP_MAX]
- Color matches current armor state: green (Operational) → amber (Compromised) → red (Critical)
- Must NOT rely on color alone for accessibility — bar segment count or icon shape changes as secondary indicator
- Drained smoothly (not stepped) as damage events arrive
- Does not display numeric HP value by default (preserve the "feel don't count" design intent); numeric display may be offered as an accessibility/preference toggle

### Squad Health Pips (Remote Reclaimers)

- Four pip icons in HUD corner, one per Reclaimer
- Color matches their armor state (green/amber/red/grey)
- Downed state adds a blinking animation + "DOWNED" text label
- Eliminated state renders the pip as a dark X
- Must work at a glance — legible while in motion during a firefight

### Synth Unit Health (Hive Mind side)

- Not covered by this GDD — Hive Mind God-View GDD (#19) owns the HM perspective HUD, which may or may not display Synth unit HP to the HM player. That GDD should reference Synth HP values from this GDD's Tuning Knobs.

### Accessibility Requirements

- All armor state changes must have a non-color visual signal (vignette shape, icon change, or text overlay)
- Downed state must have a caption-style text indicator in addition to the grey pip (for players with color vision deficiency)
- Hit indicator directional arrows must be shape-distinct, not color-only

## Acceptance Criteria

> *`qa-lead` not consulted — Lean mode. Validate criteria coverage manually before sprint-to-production.*

**AC-HD-01: Ballistic damage applies armor state modifier correctly**
- **Given** a Reclaimer at 100 HP (Operational state)
- **When** they receive 20 base Ballistic damage
- **Then** HP decreases by 16 (20 × 0.80); HP_new = 84; ArmorState remains Operational

**AC-HD-02: Ballistic damage is amplified at Critical state**
- **Given** a Reclaimer at 20 HP (Critical state)
- **When** they receive 20 base Ballistic damage
- **Then** HP_new = clamp(20 − (20 × 1.10), 0, 100) = 0.0; Reclaimer enters Downed state

**AC-HD-03: Environmental damage bypasses armor modifier**
- **Given** a Reclaimer at full HP (Operational state)
- **When** they receive 10 base Environmental damage (toxin tick)
- **Then** HP decreases by exactly 10 (1.00× at all states); HP_new = 90; ArmorState remains Operational

**AC-HD-04: Armor state transitions fire at correct HP thresholds**
- **Given** a Reclaimer at 65 HP (Operational)
- **When** they receive a damage event bringing HP to 55
- **Then** ArmorState transitions to Compromised; Compromised visual/audio feedback fires; squad pips update

**AC-HD-05: Downed state entered at HP = 0**
- **Given** a Reclaimer at 10 HP (Critical)
- **When** they receive a damage event reducing HP to 0
- **Then** HP clamps to 0.0; Reclaimer enters Downed; `DownedEvent` fires; `DisableLocomotion(true)` sent to Movement; `CorruptionInputEvent(+5.0%)` fires exactly once

**AC-HD-06: Damage to Downed Reclaimer is absorbed**
- **Given** a Reclaimer in Downed state (HP = 0)
- **When** they receive any damage event
- **Then** HP remains 0.0; no state change fires; no additional Corruption event fires; bleedout timer is unaffected

**AC-HD-07: Fall damage is zero within safe range**
- **Given** a Reclaimer falls 2.0m (below FALL_SAFE_DISTANCE of 3.0m)
- **When** they land
- **Then** FALL_DAMAGE = 0; no `TakeDamage()` call is made; HP unchanged

**AC-HD-08: Fall damage applies correctly above safe range**
- **Given** a Reclaimer falls 5.0m
- **When** they land
- **Then** FALL_DAMAGE = (5.0 − 3.0) × 10 = 20 HP; `TakeDamage(20, Environmental)` fires; HP decreases by 20

**AC-HD-09: Fall damage caps at HP_MAX**
- **Given** a Reclaimer falls 15.0m (any height producing damage > 100 HP)
- **When** they land
- **Then** FALL_DAMAGE = clamp((15 − 3) × 10, 0, 100) = 100 HP; Reclaimer enters Downed regardless of current HP

**AC-HD-10: Downed Corruption event fires exactly once per Downed transition**
- **Given** a Reclaimer who transitions from Critical to Downed
- **When** HP reaches 0
- **Then** `CorruptionInputEvent(+5.0%)` fires exactly once; not on subsequent damage while Downed; not retroactively at Compromised or Critical transitions

**AC-HD-11: HP synchronized to all clients in networked session**
- **Given** a 4-player networked session
- **When** one Reclaimer takes 25 damage
- **Then** all four clients' HUD displays show the updated HP within one network tick; ArmorState displayed matches the server-calculated state *(manual QA — network session required)*

**AC-HD-12: Synth unit Eliminated at HP = 0 with no bleedout**
- **Given** a Crawler at 40 HP
- **When** it receives damage totaling ≥ 40 HP
- **Then** HP clamps to 0; Crawler is immediately Eliminated (despawn trigger fires); no bleedout timer opens; no Reclaimer-type Downed or Corruption events fire

## Open Questions

1. **Bleedout timer duration** — K&R GDD (#12) owns the bleedout timer value (time from Downed to Elimination without revival). This GDD fires the `DownedEvent`; K&R defines how long the window lasts. What is the target bleedout time? Too short forces the squad to stop everything; too long makes being Downed inconsequential. Blocked on `knockdown-revival.md`.

2. **Revival HP restore amount** — When the Medic revives a Downed teammate, how much HP is restored? A flat amount (e.g., 30 HP → Critical state)? A percentage of HP_MAX? Does it differ between a fast field revival vs. a full trauma kit revive? This value needs to be locked in K&R and Class Abilities GDDs before H&D's interface is fully specified. Blocked on `knockdown-revival.md` and `reclaimer-class-abilities.md`.

3. **Medic self-heal capability** — Can the Medic heal themselves with the trauma kit, or only teammates? If they can self-heal, does it use the same HP restore amount? This affects the solo survivability of the Medic class significantly. To be answered by `reclaimer-class-abilities.md`.

4. **Corruption event routing** — The downed/eliminated Corruption events (+5.0% and +3.0%) are currently described as fired by Health & Damage directly. Should these route through the Sensor Grid (#7) event bus (consistent with all other Corruption inputs), or does H&D fire them directly to the Corruption Meter? The Corruption Meter GDD established the Sensor Grid as the hub for environmental/sensor events, but teammate state changes are arguably different. Requires alignment with `networking-layer.md` and `sensor-grid.md` design.

5. **Late-join HP initialization** — If a player joins a networked session mid-match, their Reclaimer's HP and armor state must initialize to the server-authoritative values, not HP_MAX. How does NGO 2.X handle this for `NetworkVariable<float>` initial sync? The Networking Layer GDD (#1) must specify the authority recovery pattern for late-joiners.

6. **Toxin damage tick rate** — Environmental Controls GDD (#15) will own how often a toxin zone applies damage ticks to Reclaimers inside it. The tick BASE_DAMAGE amount and tick rate are not defined in this GDD — they belong to Environmental Controls. This GDD's `TakeDamage(amount, Environmental)` interface is ready to receive them whenever. Flag for `environmental-controls.md`.
