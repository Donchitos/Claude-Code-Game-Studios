# Reclaimer Movement

> **Status**: Designed (pending /design-review)
> **Author**: Claude Code Game Studios (design-system)
> **Last Updated**: 2026-05-15
> **Implements Pillar**: Pillar 2 — Asymmetry Is the Point; Pillar 4 — Identity Over Loadout

## Summary

FPS locomotion for all four Reclaimer classes — walk, sprint, crouch, and mantle through AXIOM City. Every movement state outputs a noise level that the Sensor Grid uses to evaluate corruption events, making movement decisions part of the game's central tension loop.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Networking Layer`

## Overview

Reclaimer Movement defines how all four Reclaimer operatives navigate AXIOM City: the physical rules of locomotion (walk, sprint, crouch, mantle), the noise output each movement state generates (which the Sensor Grid reads to evaluate corruption risk), and the per-class movement feel that makes Breacher, Medic, Ghost, and Engineer distinct identities in play. This is not parkour — Reclaimers move with military discipline, not superheroics. Every movement choice is a trade-off: sprinting covers ground faster but generates noise that feeds the Corruption Meter; crouching suppresses the acoustic signature but slows progress toward objectives; moving at all risks visual sensor detection. The movement system is the moment-to-moment physical language of survival in a city that is listening.

## Player Fantasy

Being a Reclaimer in AXIOM City doesn't feel like being a soldier in a war game — it feels like being a trespasser in something that's smarter than you. Movement is never casual. Every sprint down a corridor risks exposure to a sensor sweep. Every crouch through a dark junction is a deliberate choice to trade speed for silence. The fantasy isn't speed — it's *presence management*: the skill of moving through a living city without feeding its appetite for your noise.

The Ghost's movement fantasy is different from the Breacher's. Ghost moves like water — minimal contact, maximum awareness, passing through spaces the city barely notices. Breacher moves like a statement — fast, loud, committed, trusting the squad to handle the corruption spike their charge generates. Both feel right for who they are. Movement is where class identity starts.

At its best, a well-coordinated squad's movement through a sector should feel like a held breath — four people moving in sync, trading callouts, managing noise, knowing the city is counting every step. And when the sprint breaks — when someone slips into a camera angle or takes fire and the squad has to react — the scramble that follows is never random. It's the sound of the city waking up.

**Pillar alignment**: Pillar 2 (Asymmetry Is the Point — Reclaimer FPS locomotion is the physical opposite of the HM's omniscient god-view; one is embodied, the other is spatial). Pillar 4 (Identity Over Loadout — class movement feel is the first layer of class identity, expressed before any ability is used).

## Detailed Design

### Core Rules

1. Reclaimers have three primary **movement stances**: WALK, SPRINT, and CROUCH. IDLE is a sub-state (velocity = 0) while in any stance.
2. **Sprint stamina**: Sprinting drains `STAMINA` at `SPRINT_DRAIN_RATE` units/second. When stamina reaches 0, sprint degrades to SPRINT_EXHAUSTED — the Reclaimer continues moving but at reduced speed. The player cannot re-enter full sprint until stamina recovers to `SPRINT_RECOVERY_THRESHOLD`.
3. **Noise output**: Each movement state emits a `NOISE_LEVEL` float [0.0–1.0] representing footstep acoustics. This value is modified by the class-specific `NOISE_MULT` and broadcast to the Sensor Grid via `FootstepEvent(noiseLevel, position)` on a distance-based interval (`FOOTSTEP_INTERVAL`). The Sensor Grid owns all threshold evaluation — the movement system emits the value, not the trigger decision.
4. **Crouch height**: Crouching reduces the character collider from `STAND_HEIGHT` to `CROUCH_HEIGHT`. This affects visual sensor camera-coverage detection by the Sensor Grid.
5. **Mantle**: Pressing the Jump/Interact input while facing a ledge at height [MANTLE_MIN_HEIGHT, MANTLE_MAX_HEIGHT] above the Reclaimer's feet triggers a mantle sequence. The Reclaimer enters MANTLE state for the animation duration, then exits into WALK stance.
6. **Class multipliers**: All per-class movement stats derive from base values modified by per-class `MOVE_SPEED_MULT` and `NOISE_MULT`. No class has independent absolute values — only multipliers against shared base.
7. **Sprint constraint**: Sprint cannot be entered from CROUCH stance. The Reclaimer must return to WALK first.
8. **Crouch constraint**: Crouch cannot be entered during MANTLE. Crouch exit (standing up) requires headroom — if ceiling prevents it, crouch is locked until clear.
9. **Position authority**: Position is client-predicted locally for responsiveness; server validates and reconciles. *(Provisional — pending Networking Layer GDD.)*

---

### Movement Stance Table

| Stance | Base Speed | Noise Level | Stamina Effect | Collider Height |
|---|---|---|---|---|
| IDLE (any stance, velocity=0) | 0 m/s | 0.05 | Regen (+15/s after delay) | Stance-dependent |
| WALK | 3.5 m/s | 0.40 | Regen (+15/s) | STAND_HEIGHT (1.8m) |
| SPRINT | 6.0 m/s | 0.90 | Drain (−20/s) | STAND_HEIGHT (1.8m) |
| SPRINT_EXHAUSTED | 4.5 m/s | 0.90 | Stable (0) | STAND_HEIGHT (1.8m) |
| CROUCH | 2.0 m/s | 0.15 | Regen (+15/s) | CROUCH_HEIGHT (1.1m) |
| MANTLE | Animated (~2.0 m/s horizontal) | 0.40 | Regen (+15/s) | Transitional |

**Footstep interval**: `FootstepEvent` fires every `FOOTSTEP_INTERVAL` meters traveled (default: 0.8m for WALK, 0.6m for SPRINT, 1.2m for CROUCH). Shorter intervals at speed = more events = more potential sensor triggers.

---

### Class Movement Multipliers

| Class | MOVE_SPEED_MULT | NOISE_MULT | Design Intent |
|---|---|---|---|
| Breacher | 0.90× | 1.20× | Heavy loadout — slower and louder; every move costs more corruption risk |
| Medic | 1.00× | 1.00× | Baseline — the reference Reclaimer |
| Ghost | 1.10× | 0.70× | Faster and quieter — presence management specialist |
| Engineer | 0.95× | 0.95× | Equipment-laden — slight penalties, slight discipline reward |

**Effective examples:**
- Ghost sprint: 6.0 × 1.10 = 6.6 m/s — fastest Reclaimer
- Breacher sprint: 6.0 × 0.90 = 5.4 m/s — slowest Reclaimer
- Ghost sprint noise: 0.90 × 0.70 = 0.63 (vs. Medic baseline 0.90)

---

### States and Transitions

| From | To | Condition |
|---|---|---|
| Any grounded | WALK | Default; no sprint or crouch input held |
| WALK | SPRINT | Sprint hold input + stamina ≥ SPRINT_RECOVERY_THRESHOLD |
| SPRINT | SPRINT_EXHAUSTED | Stamina reaches 0 |
| SPRINT_EXHAUSTED | SPRINT | Stamina reaches SPRINT_RECOVERY_THRESHOLD (30 units) |
| SPRINT / SPRINT_EXHAUSTED | WALK | Sprint input released |
| WALK | CROUCH | Crouch toggle input pressed |
| CROUCH | WALK | Crouch toggle pressed again + headroom available |
| WALK / SPRINT / CROUCH | MANTLE | Jump input pressed + ledge in [MANTLE_MIN_HEIGHT, MANTLE_MAX_HEIGHT] range |
| MANTLE | WALK | Mantle animation completes |
| Any | IDLE | Velocity input = zero (sub-state of current stance) |

**Locked transitions:**
- CROUCH → SPRINT: not allowed. Must go CROUCH → WALK → SPRINT.
- MANTLE → CROUCH: not allowed during mantle animation.

**Stamina regeneration:**
- Regen begins `REGEN_DELAY` seconds after sprint input is released.
- Regen rate: +15 stamina/second.
- Regen is suspended while at max (100) or while sprinting.

---

### Interactions with Other Systems

| System | Direction | Interface | Data |
|---|---|---|---|
| Sensor Grid (#7) | Movement → | Emits `FootstepEvent(noiseLevel, position)` every `FOOTSTEP_INTERVAL` meters traveled | Sensor Grid evaluates noiseLevel against zone acoustic threshold to determine if `CorruptionInputEvent(+0.5%)` fires |
| Sensor Grid (#7) | Movement → | Provides current character collider bounds (height, position) each frame | Sensor Grid uses bounds for camera/visual detection coverage |
| Corruption Meter (#3) | Indirect via Sensor Grid | Acoustic sensor events produce +0.5% corruption only if FootstepEvent.noiseLevel exceeds zone threshold | Movement does NOT interact with Corruption Meter directly |
| Reclaimer Combat (#6) | Combat reads Movement | Combat reads `CurrentMovementState` to apply accuracy modifiers (sprint = reduced accuracy, crouch = improved stability) | Movement state is a readable property; Movement does not call Combat |
| Knockdown & Revival (#12) | K&R → Movement | Downed state disables normal locomotion. K&R GDD defines limited crawl movement (~0.5 m/s, constant noise). Movement must expose a `DisableLocomotion(bool)` flag. | Locomotion flag prevents stance transitions while downed |
| Objective System (#16) | Objective reads Position | Proximity detection for objective zone interaction | Position exposed via NetworkVariable (provisional) |
| Reclaimer Class Abilities (#11) | Abilities modify Movement | Ghost's cloaking suite may modify `NOISE_MULT` at runtime. Engineer deploy actions may impose a `MOVE_SPEED_MULT` penalty during deployment. | Class Abilities GDD owns all modifications; Movement exposes NOISE_MULT and MOVE_SPEED_MULT as modifiable fields |
| Networking Layer (#1) *(provisional)* | Foundation | NetworkTransform syncs position to all clients. Client-predicted for local Reclaimer, interpolated for remote players. | Provisional — authority model pending Networking Layer GDD |

## Formulas

### Formula 1: Effective Movement Speed

```
V_effective = BASE_SPEED[stance] × MOVE_SPEED_MULT[class]
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Effective movement speed | V_effective | float | 0.0–7.0 m/s | Actual movement speed applied to CharacterController each frame |
| Base stance speed | BASE_SPEED | float | 0.0–6.0 m/s | Stance-defined base speed (see Stance Table in Detailed Design) |
| Class speed multiplier | MOVE_SPEED_MULT | float | 0.90–1.10 | Per-class multiplier (Breacher 0.90, Medic 1.00, Ghost 1.10, Engineer 0.95) |

**Output range:** 0.0 m/s (IDLE) to 6.6 m/s (Ghost sprint). Expected play range: 2.0–6.6 m/s during active movement.

**Example (Ghost sprint):** V_effective = 6.0 × 1.10 = 6.6 m/s
**Example (Breacher crouch):** V_effective = 2.0 × 0.90 = 1.8 m/s

---

### Formula 2: Effective Noise Level (FootstepEvent output)

```
NOISE_OUT = clamp(BASE_NOISE[stance] × NOISE_MULT[class], 0.0, 1.0)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Noise output | NOISE_OUT | float | 0.0–1.0 | Noise level sent in FootstepEvent to Sensor Grid |
| Base stance noise | BASE_NOISE | float | 0.05–0.90 | Stance-defined base noise (see Stance Table in Detailed Design) |
| Class noise multiplier | NOISE_MULT | float | 0.70–1.20 | Per-class multiplier (Ghost 0.70, Medic 1.00, Breacher 1.20, Engineer 0.95) |

**Output range:** NOISE_OUT ∈ [0.0, 1.0] after clamping.

**Example (Breacher sprint):** NOISE_OUT = clamp(0.90 × 1.20, 0.0, 1.0) = 1.0 (maximum noise)
**Example (Ghost crouch):** NOISE_OUT = 0.15 × 0.70 = 0.105
**Example (Medic walk):** NOISE_OUT = 0.40 × 1.00 = 0.40

**Cross-reference**: Sensor Grid (#7) compares NOISE_OUT against zone acoustic thresholds. Sensor Grid GDD must define those thresholds to complete this interface.

---

### Formula 3: Stamina Drain and Regeneration

**During sprint:**
```
STAMINA_new = clamp(STAMINA_prev − SPRINT_DRAIN_RATE × Δt, 0.0, STAMINA_MAX)
```

**During regen (non-sprint, after REGEN_DELAY has elapsed):**
```
STAMINA_new = clamp(STAMINA_prev + REGEN_RATE × Δt, 0.0, STAMINA_MAX)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Stamina | STAMINA | float | 0.0–100.0 | Current stamina value |
| Maximum stamina | STAMINA_MAX | float | 100.0 | Constant cap |
| Sprint drain rate | SPRINT_DRAIN_RATE | float | 10–40 /sec | Stamina lost per second while sprinting (default: 20/sec) |
| Regen rate | REGEN_RATE | float | 5–30 /sec | Stamina recovered per second (default: 15/sec) |
| Regen delay | REGEN_DELAY | float | 0.5–3.0 sec | Seconds after sprint ends before regen begins (default: 1.5 sec) |
| Sprint recovery threshold | SPRINT_RECOVERY_THRESHOLD | float | 10–50 | Minimum stamina required to re-enter SPRINT from SPRINT_EXHAUSTED (default: 30) |
| Delta time | Δt | float | frame dt | Time since last frame (seconds) |

**Output range:** STAMINA ∈ [0.0, 100.0]

**Sprint duration (defaults):** 100 / 20 = **5 seconds** of continuous sprint before exhaustion.
**Recovery time (0 → sprint threshold):** 1.5s delay + 2.0s regen = **3.5 seconds total**.
**Full recovery (0 → 100):** 1.5 + (100/15) ≈ **8.2 seconds** from exhaustion to full stamina.

> *`systems-designer` not consulted — Lean mode. Validate stamina values against playtest targets before sprint-to-production.*

## Edge Cases

- **If a Reclaimer attempts to sprint while stamina is below `SPRINT_RECOVERY_THRESHOLD` (30 units)**: Sprint input is accepted but SPRINT state is not entered. The Reclaimer remains in WALK. Prevents confusing micro-exhaust UX.

- **If a Reclaimer inputs crouch while in SPRINT or SPRINT_EXHAUSTED**: Input is ignored. Player must release sprint (return to WALK) before crouch is accepted. SPRINT → CROUCH is a locked transition.

- **If stamina reaches exactly 0 mid-sprint**: Speed transitions to SPRINT_EXHAUSTED (4.5 m/s). Transition is interpolated over one frame — no velocity pop. Noise level remains 0.90; exhaustion is still loud.

- **If Ghost's cloaking ability sets `NOISE_MULT` to 0.0**: `NOISE_OUT` = clamp(BASE_NOISE × 0.0, 0, 1) = 0.0. FootstepEvents still fire at `FOOTSTEP_INTERVAL` but with 0.0 noise — no acoustic corruption input is generated. No special movement logic required.

- **If a Reclaimer attempts to mantle above `MANTLE_MAX_HEIGHT` (2.0m)**: Mantle input rejected. Reclaimers cannot free-jump — only mantle. The Reclaimer is blocked by geometry.

- **If a Reclaimer attempts to mantle below `MANTLE_MIN_HEIGHT` (0.3m)**: Input ignored. The obstacle is low enough to walk or crouch over; no mantle needed.

- **If a mantling Reclaimer is downed mid-mantle**: K&R GDD defines interrupt behavior. Movement must expose an interrupt point in the mantle sequence. *(Provisional — K&R GDD owns this.)*

- **If crouch exit (stand-up) is blocked by a low ceiling**: CROUCH → WALK transition is blocked. Player receives blocked-input feedback (UI indicator or rejected animation). Reclaimer remains in CROUCH until headroom clears.

- **If a Reclaimer walks off an unguarded platform edge**: No ledge grab or auto-correction. Reclaimers can fall. Fall damage is defined by Health & Damage GDD (#5).

- **If `FOOTSTEP_INTERVAL` is set very high (e.g., 10m) for testing**: Acoustic sensor events fire rarely. Valid for isolated testing of other Sensor Grid paths without noise pollution.

- **If two Reclaimers briefly overlap on network desync**: CharacterController collision resolution handles this locally. Server position is authoritative — clients interpolate back. No movement GDD logic required.

## Dependencies

| System | Direction | Nature | GDD Status |
|---|---|---|---|
| Networking Layer (#1) | This depends on | Server-authoritative position sync; CharacterController + NetworkTransform authority model | ⚠️ Not designed — provisional |
| Sensor Grid (#7) | Movement → Sensor Grid | Movement emits `FootstepEvent(noiseLevel, position)` and provides collider bounds each frame | Not yet designed |
| Corruption Meter (#3) | Indirect via Sensor Grid | Acoustic events feed corruption only if noiseLevel > zone threshold | ✅ Designed |
| Reclaimer Combat (#6) | Combat reads Movement | Combat reads `CurrentMovementState` for accuracy modifiers | Not yet designed |
| Knockdown & Revival (#12) | K&R → Movement | Downed state disables locomotion via `DisableLocomotion(bool)` flag | Not yet designed |
| Objective System (#16) | Objective reads Position | Position proximity detection for objective zone interaction | Not yet designed |
| Reclaimer Class Abilities (#11) | Abilities modify Movement | Abilities may modify `NOISE_MULT` and `MOVE_SPEED_MULT` at runtime | Not yet designed |

**Hard dependencies**: Networking Layer (#1)
**Soft dependencies**: All others — movement functions standalone; other systems subscribe to its events and readable state.

## Tuning Knobs

All tuning knobs are exposed as data-driven constants (no hardcoded values in script). Safe ranges represent tested playability bounds — outside these ranges, the movement feel degrades significantly or the noise-corruption feedback loop breaks.

| Knob | Default | Safe Range | Affects |
|---|---|---|---|
| BASE_SPEED[WALK] | 3.5 m/s | 2.0–5.0 m/s | Walk traversal pace; raise for faster tempo, lower for tighter tension |
| BASE_SPEED[SPRINT] | 6.0 m/s | 4.5–8.0 m/s | Sprint speed ceiling; should remain meaningfully faster than walk |
| BASE_SPEED[CROUCH] | 2.0 m/s | 1.0–3.0 m/s | Crouch traversal; too fast and the noise trade-off collapses |
| BASE_SPEED[SPRINT_EXHAUSTED] | 4.5 m/s | 3.5–5.5 m/s | Fallback speed at exhaustion; should stay above walk to reward partial sprint use |
| BASE_NOISE[WALK] | 0.40 | 0.20–0.60 | How often casual walking triggers acoustic sensors; core to ambient tension |
| BASE_NOISE[SPRINT] | 0.90 | 0.70–1.00 | Sprint acoustic baseline; keep high to preserve corruption risk of speed |
| BASE_NOISE[CROUCH] | 0.15 | 0.05–0.30 | Crouch reward — lower means more stealthy, but should not reach 0 |
| NOISE_MULT[Ghost] | 0.70× | 0.40–0.90× | Ghost class identity strength; lower = stronger stealth specialist |
| NOISE_MULT[Breacher] | 1.20× | 1.00–1.50× | Breacher corruption contribution; higher = more team-pressure cost to running Breacher |
| SPRINT_DRAIN_RATE | 20 /sec | 10–40 /sec | Stamina drain per second sprinting; lower = longer sprint windows, higher = more tactical resource |
| REGEN_RATE | 15 /sec | 5–30 /sec | Stamina recovery per second; higher = more forgiving sprint-rest rhythm |
| REGEN_DELAY | 1.5 sec | 0.5–3.0 sec | Seconds after sprint ends before regen begins; higher = sprint commitment punished more |
| SPRINT_RECOVERY_THRESHOLD | 30 | 10–50 | Stamina floor required to re-enter SPRINT; higher = longer forced-walk windows after exhaustion |
| FOOTSTEP_INTERVAL[WALK] | 0.8 m | 0.4–1.5 m | Distance between FootstepEvent firings at walk; lower = more acoustic sensitivity |
| FOOTSTEP_INTERVAL[SPRINT] | 0.6 m | 0.3–1.0 m | Distance between FootstepEvent firings at sprint; keep shorter than walk |
| FOOTSTEP_INTERVAL[CROUCH] | 1.2 m | 0.6–2.0 m | Distance between FootstepEvent firings while crouched; higher = more reward for stealth posture |
| MANTLE_MIN_HEIGHT | 0.3 m | 0.1–0.5 m | Minimum ledge height to trigger mantle; below this, walk/crouch over obstacle |
| MANTLE_MAX_HEIGHT | 2.0 m | 1.5–2.5 m | Maximum ledge height Reclaimers can mantle; above this, geometry is impassable |
| STAND_HEIGHT | 1.8 m | fixed | CharacterController capsule height while standing; drives visual sensor detection volume |
| CROUCH_HEIGHT | 1.1 m | fixed | CharacterController capsule height while crouched; change with caution — level geometry tuned to this |

## Visual/Audio Requirements

### Animation Requirements

| State / Transition | Animation | Notes |
|---|---|---|
| IDLE | Breathing idle cycle | Subtle weapon sway; distinct per class silhouette |
| WALK → SPRINT | Blend into sprint lean | ~0.2s blend; weapon raises closer to body |
| SPRINT → WALK / SPRINT_EXHAUSTED | Blend into recovery | Heavier for SPRINT_EXHAUSTED — visible exertion |
| WALK / SPRINT → CROUCH | Crouch drop transition | Must not clip geometry; collider height changes at frame 1 of animation |
| CROUCH → WALK | Rise transition | Blocked visually if ceiling present (no animation plays) |
| MANTLE | Grab-and-pull sequence | Timed to collider repositioning; ~0.6–0.8 sec |
| STAND → IDLE | Sub-state blend | All stance idles are sub-states of stance, not separate clips |

All first-person animations are local-only. Third-person (remote Reclaimer) animations are driven by replicated movement state + interpolated position.

### Audio Requirements

**Footstep audio** is the primary acoustic identity of movement. Audio design must reinforce the noise-level hierarchy:

| Stance | Audio Character | Mix Priority |
|---|---|---|
| CROUCH | Near-silent: soft cloth, minimal impact | Low — easy to miss in busy mix |
| WALK | Grounded, deliberate steps — boots on concrete/metal/dust | Medium — present but not intrusive |
| SPRINT | Heavy, urgent — footfall rhythm increases, gear rattle | High — should signal to squadmates nearby |
| SPRINT_EXHAUSTED | Heavier, labored — slight breathing overlay | High + exertion layer |
| MANTLE | Impact on vault, footfall landing | One-shot; medium-high priority |

**Surface material variants** (minimum required at launch):
- Concrete / pavement
- Metal grating / catwalks
- Gravel / debris
- Interior flooring (tile, composite)

**Class audio differentiation**: Ghost footsteps should be noticeably quieter than Breacher at the same stance — the audio mix must reflect the NOISE_MULT difference audibly so players can identify class from footstep sound alone.

**State-change feedback audio**:
- **Sprint exhaustion onset**: Short breath-catch cue at the moment stamina hits 0 (Reclaimer-POV only; not broadcast to others)
- **Sprint recovery** (stamina crossing SPRINT_RECOVERY_THRESHOLD): Subtle ready-state audio cue (optional — validate against UX noise floor)
- **Crouch-ceiling block**: A short muffled thud + denial audio when stand-up is blocked by ceiling

### UI / HUD Requirements

- **Stamina bar**: Persistent HUD element. Displays STAMINA [0–100] as a bar. Must:
  - Show depletion animation during sprint (smooth drain, not stepped)
  - Flash or pulse when entering SPRINT_EXHAUSTED state
  - Grey out or visually dim when below SPRINT_RECOVERY_THRESHOLD to communicate sprint is unavailable
- **Crouch state indicator**: A minimal visual indicator (icon or posture change to character silhouette in HUD) showing when CROUCH is active
- **Sprint-blocked feedback**: If sprint input is rejected (below threshold), the stamina bar should flash a "not ready" state — do not silently reject
- **MANTLE_MAX_HEIGHT interaction**: No UI prompt required; geometry is the affordance. If mantle fails (out of range), no tooltip. *Reclaimers read the geometry, not prompts.*

## UI Requirements

HUD requirements are covered in the Visual/Audio Requirements section above (Stamina bar, crouch indicator, sprint-blocked feedback).

**Additional UI notes:**
- The stamina bar must support both mouse/keyboard and gamepad navigation contexts — no hover-only states. The bar is always visible during play (not collapsed).
- Crouch indicator accessibility: must not rely on color alone. Use icon shape or posture silhouette change as the primary indicator; color is additive.
- All movement-state feedback audio must have a visual equivalent for players with hearing loss (screen flash, icon pulse, or caption-style feedback). This is non-blocking pre-launch but required for the accessibility pass.

## Acceptance Criteria

All criteria are written as Given-When-Then. Each must pass in both solo-play and networked (4-player) sessions. Automated unit tests cover criteria 1–8; criteria 9–12 require manual QA.

**AC-MOV-01: FootstepEvent emission at correct interval (walk)**
- **Given** a Medic Reclaimer walking on flat terrain
- **When** the Reclaimer travels 0.8 m from the last FootstepEvent position
- **Then** a `FootstepEvent` fires with `noiseLevel = 0.40 ± 0.01` and current world position

**AC-MOV-02: FootstepEvent noise scaled by class multiplier (sprint)**
- **Given** a Ghost Reclaimer sprinting
- **When** `FootstepEvent` fires
- **Then** `noiseLevel = clamp(0.90 × 0.70, 0, 1) = 0.63 ± 0.01`; interval is ≤ 0.6 m between events

**AC-MOV-03: Stamina drains to exhaustion at correct rate**
- **Given** a Breacher Reclaimer with full stamina (100) entering SPRINT
- **When** sprint is held continuously
- **Then** stamina reaches 0 after 5.0 sec ± 0.1 sec; movement state transitions to SPRINT_EXHAUSTED at that moment; speed drops to 5.4 × (4.5/6.0) = 4.05 m/s (Breacher SPRINT_EXHAUSTED)

**AC-MOV-04: Stamina regen begins after delay**
- **Given** a Reclaimer in SPRINT_EXHAUSTED who releases sprint input
- **When** 1.5 seconds have elapsed
- **Then** stamina begins increasing at +15/sec; before 1.5 sec, stamina does not increase

**AC-MOV-05: Sprint blocked below recovery threshold**
- **Given** a Reclaimer whose stamina is 25 (below SPRINT_RECOVERY_THRESHOLD = 30)
- **When** the sprint input is held
- **Then** the Reclaimer does not enter SPRINT; movement remains at WALK speed; no state transition occurs

**AC-MOV-06: Crouch-to-sprint transition is blocked**
- **Given** a Reclaimer in CROUCH stance
- **When** sprint input is held (without first releasing crouch)
- **Then** the Reclaimer does not enter SPRINT; crouch speed is maintained; no state transition occurs

**AC-MOV-07: Mantle succeeds for ledge in valid height range**
- **Given** a Reclaimer standing against a ledge at height 1.2 m above their feet
- **When** the Jump/Interact input is pressed
- **Then** the Reclaimer enters MANTLE state; mantle animation plays; upon completion Reclaimer stands atop the ledge in WALK stance

**AC-MOV-08: Mantle fails for ledge above max height**
- **Given** a Reclaimer standing against a wall section at height 3.0 m (above MANTLE_MAX_HEIGHT)
- **When** the Jump/Interact input is pressed
- **Then** no mantle is triggered; the Reclaimer remains stationary; wall is impassable

**AC-MOV-09: Crouch-ceiling lock prevents stand-up**
- **Given** a Reclaimer crouched in a space with a ceiling 1.3 m above the floor (below STAND_HEIGHT)
- **When** the crouch toggle is pressed to stand
- **Then** the Reclaimer remains in CROUCH; no height change occurs; a blocked-input feedback signal is sent (audio or UI indicator per Visual/Audio Requirements)

**AC-MOV-10: Ghost cloaking at NOISE_MULT = 0.0 produces zero-noise FootstepEvent**
- **Given** Ghost's cloaking ability has set `NOISE_MULT` to 0.0
- **When** Ghost walks and `FootstepEvent` fires at the normal interval
- **Then** `FootstepEvent.noiseLevel = 0.0`; event still fires (no suppression of emission); Sensor Grid receives the event with 0.0 noise value

**AC-MOV-11: Remote Reclaimer position interpolates smoothly**
- **Given** a networked 4-player session with variable simulated latency (50–150 ms)
- **When** a remote Reclaimer is observed walking and sprinting
- **Then** no visible position snap or teleport occurs; remote Reclaimer movement appears visually continuous; interpolation error does not exceed 0.3 m of visual offset at any frame *(manual QA — network simulation required)*

**AC-MOV-12: Gamepad control scheme mirrors Keyboard/Mouse behavior**
- **Given** a Reclaimer controlled via gamepad
- **When** all movement inputs are exercised (walk, sprint, crouch, mantle, idle)
- **Then** all state transitions, noise outputs, stamina effects, and FootstepEvent emissions match the Keyboard/Mouse results identically; no movement feature is unavailable or degraded on gamepad *(manual QA)*

## Open Questions

1. **Networking authority model for position** — Client-predicted locally, server-validated is the provisional model (Core Rule 9). This must be confirmed by the Networking Layer GDD (#1). If the authority model changes (e.g., server-authoritative with no client prediction), stamina and noise calculations may need to move to the server. Blocked on `networking-layer.md`.

2. **Fall damage threshold** — Movement defines that Reclaimers can fall from unguarded edges (Edge Case 9), but fall damage thresholds and death are owned by Health & Damage GDD (#5). At what fall height does damage begin? Does a Breacher's lower speed mean slightly different fall momentum? Flag for `health-damage.md`.

3. **Downed-state crawl movement** — K&R GDD (#12) owns the downed crawl mechanic (~0.5 m/s, constant noise). Does downed crawl emit FootstepEvents? At what noise level? Does crawl noise use the same NOISE_MULT or is it class-independent? Movement GDD exposes `DisableLocomotion(bool)` — K&R GDD must define whether "downed" means full disable or partial (crawl-only). Blocked on `knockdown-revival.md`.

4. **MOVE_SPEED_MULT and NOISE_MULT modification from Class Abilities** — Engineer's deploy-action penalty and Ghost's cloaking NOISE_MULT=0.0 are mentioned but not fully specified. Are these additive or override? Can multiple modifiers stack (e.g., Ghost cloaking + crouching — does NOISE_MULT compound or floor at 0.0)? Blocked on `reclaimer-class-abilities.md`.

5. **Mantle interrupt from external forces** — Edge Case 7 defers downed-during-mantle to K&R GDD. But what about being hit by a projectile mid-mantle (Combat, #6)? Can combat interrupt a mantle? If mantle is a locked animation state, hit reactions need to know this. Requires cross-referencing `reclaimer-combat.md`.

6. **Footstep audio occlusion for remote players** — Should remote Reclaimer footstep audio be spatially occluded by geometry (3D audio with physics raycasting)? This affects the perceived presence of other Reclaimers and has significant audio/performance implications. Not a movement GDD decision, but must be flagged for the Audio system GDD.
