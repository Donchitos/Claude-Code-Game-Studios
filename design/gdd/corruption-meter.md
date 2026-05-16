# Corruption Meter

> **Status**: Designed (pending /design-review)
> **Author**: Claude Code Game Studios (design-system)
> **Last Updated**: 2026-05-15
> **Implements Pillar**: Pillar 1 — The City Is the Enemy; Pillar 3 — Every Match Tells a Story

## Summary

The Corruption Meter is SYNTHFALL's shared tension engine — a 0–100% value that tracks AXIOM City's escalating Synth control over a sector. It drives match pacing for both factions simultaneously: Reclaimers fight to suppress it, the Hive Mind fights to maximize it, and the city's behaviour upgrades at four threshold events (25/50/75/100%).

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Networking Layer`

## Overview

The Corruption Meter is SYNTHFALL's tension engine: a server-authoritative 0–100% value that tracks how thoroughly AXIOM City's Synth intelligence has asserted control over a given sector. It is not a passive health bar — it is the pacing mechanism that makes every Reclaimer action consequential and gives the Hive Mind player a legible lever over the match's escalation arc. The meter rises passively over time (a slow baseline representing the city's ambient hostility), accelerates when Reclaimers make noise (gunfire, sensor triggers, downed teammates, failed objectives), and decelerates briefly when Reclaimers complete objectives — the only breathing room the city grants. The Hive Mind can actively push the meter through sustained unit pressure and environmental control activations. At the thresholds of 25%, 50%, 75%, and 100%, the city upgrades its response — more units, faster hazards, and environmental layout changes that make retreat and advance both harder. At 100%, AXIOM City fully activates and the Hive Mind wins. Both factions read the same meter but experience it oppositely: for Reclaimers, it is a creeping threat demanding discipline; for the Hive Mind, it is a resource to build and spend.

## Player Fantasy

**Reclaimers**: Every meter tick is information and pressure at the same time. You know where you stand — you can *see* the city getting angrier — and that visibility makes every squad decision carry weight. The fantasy is not helplessness: it's playing chess with something that's smarter than you, and knowing that discipline, not firepower, is how you survive. When the meter drops after a hard-won objective, the relief is earned. When it spikes from a bad firefight, the squad feels responsible. The meter is the squad's conscience.

**Hive Mind**: You are not fighting the Reclaimers — you are *shaping the space* until they collapse under the pressure. The meter is your score and your momentum. Every Reclaimer mistake is your resource. Every threshold unlocked is your city waking up. The fantasy is being the patient intelligence that turns a squad's noise into your power — and watching the moment they realize they're already losing.

**Shared experience**: Both factions watch the same value but read it as opposite quantities — Reclaimers see remaining time; the Hive Mind sees accumulated dominance. This shared-but-opposed reading is the core emotional engine of every match. The Corruption Meter is what makes SYNTHFALL feel like a tug-of-war rather than a hunt.

**Pillar alignment**: Directly serves Pillar 1 (The City Is the Enemy — the meter *is* the city's agency made legible) and Pillar 3 (Every Match Tells a Story — the meter's arc is the match's narrative spine: how fast it climbed, where the squad stumbled, when the HM struck).

## Detailed Design

### Core Rules

1. The Corruption value is a float in the range **[0.0, 100.0]**, owned and written exclusively by the server. All clients read it; no client may write it directly.
2. The meter is **global to the session** — one shared Corruption value per active sector, visible to all players simultaneously.
3. **Passive rise**: The meter increases at a baseline rate of `PASSIVE_RATE` (default: 1.0% per minute), applied continuously by a server-side tick regardless of player action.
4. **Event-driven inputs**: Specific Reclaimer and city actions emit Corruption Input Events with defined weights. Each event adds its weight to the meter immediately on the server. No input is queued or batched — the meter reflects the session state in real time.
5. **Objective completion reduction**: When a Reclaimer squad completes a defined objective, the meter decreases by `OBJECTIVE_REDUCTION` (default: 5%). Instantaneous. The only reliable Reclaimer tool for meter suppression.
6. **HM indirect input only**: The Hive Mind has no direct "push" action on the meter. All HM-originated corruption comes from actions that generate sensor or environmental events (unit deployment creating combat pressure, environmental control activations). The Sensor Grid and Environmental Controls own the event emission; the meter receives the output.
7. **Threshold events**: At 25%, 50%, 75%, and 100%, the Threshold Event System is notified. Thresholds are **one-directional** — crossing from below triggers the threshold event and locks in city upgrades. Dropping back below a threshold value does NOT reverse the upgrade or re-fire the event.
8. **Win condition**: When the meter reaches 100.0%, the Hive Mind wins. The match transitions immediately to resolution state. Win/Loss Conditions (#18) owns the termination logic; the meter only fires the `CorruptionMaxEvent`.
9. **Sector carry**: On sector transition, the meter's value is reduced to 50% of its current value before the new sector begins. This models the squad entering a new area compromised — the city "remembers" them.
10. **Ceiling**: The meter is clamped to 100.0 max. Any input that would push it past 100% is clamped and triggers the win condition immediately.
11. **Floor**: The meter is clamped to 0.0 min. No input or reduction can push it below zero.

---

### Corruption Input Event Table

| Event | Default Weight | Trigger Condition | Emitter |
|---|---|---|---|
| Gunfire (single shot) | +0.15% | Any Reclaimer fires any weapon | Reclaimer Combat (#6) |
| Gunfire (auto burst, per 3-shot tick) | +0.15% per tick | Sustained fire from automatic weapons | Reclaimer Combat (#6) |
| Sensor trigger — acoustic | +0.5% | Reclaimer footstep detected in acoustic sensor zone above noise threshold | Sensor Grid (#7) |
| Sensor trigger — visual | +1.0% | Reclaimer enters camera field of view, unmasked | Sensor Grid (#7) |
| Sensor trigger — biometric | +1.5% | Reclaimer passes through biometric scanner | Sensor Grid (#7) |
| Teammate downed | +5.0% | Any Reclaimer enters downed state | Health & Damage (#5) |
| Teammate eliminated (bled out) | +3.0% | Downed Reclaimer's bleedout timer expires with no revival | Knockdown & Revival (#12) |
| Objective failed | +4.0% | Objective expires or is abandoned | Objective System (#16) |
| HM unit in active combat (per second) | +0.25% per second | Synth unit engaged in combat with a Reclaimer | Sensor Grid (#7) — combat detection |
| Environmental control activated | +1.0% per activation | HM triggers any standard environmental hazard | Environmental Controls (#15) |
| Power grid surge activated | +2.0% per activation | HM triggers power grid surge specifically | Environmental Controls (#15) |
| Objective completed | −5.0% | Squad completes any defined objective | Objective System (#16) |

---

### States and Transitions

The Corruption value maps to five **city response states**, each unlocking additional Synth capabilities. States are progression-only: city upgrades do not revert when the meter value drops.

| State | Range | Entry | City Behavior Change |
|---|---|---|---|
| **CALM** | 0–24.9% | Match start | Baseline passive rise. HM can deploy Crawlers only. Sensor Grid at minimum sensitivity. No environmental controls available. |
| **ALERT** | 25–49.9% | Crosses 25% (first time) | Stalker deployment unlocked. 2 environmental control types available. Sensor Grid sensitivity +20%. Passive rise rate ×1.25. |
| **HOSTILE** | 50–74.9% | Crosses 50% (first time) | Pulse Drone deployment unlocked. 4 environmental control types available. Sensor Grid sensitivity +50%. Passive rise rate ×1.5. |
| **CRITICAL** | 75–99.9% | Crosses 75% (first time) | All HM unit types available. All 5 environmental controls available. Sensor Grid at maximum sensitivity. Passive rise rate ×1.75. Extraction blocked until meter drops below 75%. |
| **CONSUMED** | 100.0% | Meter reaches 100% | Hive Mind wins. Match ends. |

**State reversion rule**: If the meter drops from ALERT range (e.g., 27%) back to CALM range (e.g., 22%) via objective completion, the meter VALUE reflects 22%, but city capabilities remain at ALERT level. Objective reductions affect meter momentum, not city escalation state.

**Passive rate acceleration**: The ×1.25/1.5/1.75 multipliers at higher states mean the city becomes progressively harder to hold back. A squad at CRITICAL who completes an objective buys less time than a squad at CALM who does the same.

---

### Interactions with Other Systems

| System | Direction | Interface | Data |
|---|---|---|---|
| Sensor Grid (#7) | → Meter | Emits `CorruptionInputEvent(weight, eventType)` server-side on detection | Meter reads weight and applies. Sensor Grid owns detection and weight assignment for all movement/visibility events. |
| Reclaimer Combat (#6) | → Meter | Emits `GunfireEvent(shotCount)` on every weapon discharge | Meter applies +0.15% per shot. Combat system does not need to know the meter value. |
| Health & Damage (#5) | → Meter | Emits `ReclaimeDownedEvent` and `ReclaimerEliminatedEvent` | Meter applies +5.0% on downed, +3.0% on eliminated. |
| Knockdown & Revival (#12) | → Meter | Emits `ReclaimerEliminatedEvent` when bleedout timer expires | Meter applies +3.0%. |
| Objective System (#16) | ↔ Meter | Emits `ObjectiveCompletedEvent` and `ObjectiveFailedEvent`; meter applies ±5% / +4%. Meter value READ by Objective System to block extraction in CRITICAL state. | Bidirectional: meter receives event inputs AND Objective System polls current meter value. |
| Environmental Controls (#15) | → Meter | Emits `EnvironmentalHazardActivatedEvent(controlType)` on HM trigger | Meter applies weight by control type. Meter does not process spatial effects — that is Environmental Controls' domain. |
| Threshold Event System (#17) | Meter → | On first crossing of 25/50/75/100%, fires `ThresholdReachedEvent(thresholdValue)` | Threshold Event System is the sole consumer. Meter fires once per threshold per sector, never twice. |
| Win/Loss Conditions (#18) | Meter → | At 100.0%, fires `CorruptionMaxEvent()` | Win/Loss Conditions handles match termination. Meter does not manage end-state logic. |
| Reclaimer HUD (#20) | Meter → | HUD subscribes to `NetworkVariable<float>.OnValueChanged` | HUD owns all display logic. Meter provides value only. |
| Hive Mind Interface (#21) | Meter → | Interface subscribes to `NetworkVariable<float>` and `ThresholdReachedEvent` | Interface displays meter and threshold animations. Meter provides value and threshold events only. |
| Sector Transition System (#23) | ↔ Meter | Transition fires `SectorTransitionEvent`; meter applies carry logic (×0.5) and resets threshold-fired flags for the new sector | Meter notifies Sector Transition of the post-carry value so it can display the incoming corruption level to both factions. |
| Post-Match Debrief (#25) | Meter → | Debrief reads meter's complete event log: `(timestamp, eventType, weight, resultingValue)` per sector | Meter must persist a time-series event log for debrief rendering. This is the Corruption timeline in the post-match report. |
| Networking Layer (#1) *(provisional)* | Foundation | `CorruptionValue` is a `NetworkVariable<float>` with server-only write permission. All input events arrive via ServerRpc from respective system owners. | *(Authority model provisional — no Networking Layer GDD exists yet. Assumption: server-authoritative. All clients subscribe to OnValueChanged for real-time sync. Flag for resolution when Networking Layer GDD is authored.)* |

## Formulas

### Formula 1: Passive Corruption Tick

The server applies passive corruption on a fixed tick interval.

```
ΔC_passive = PASSIVE_RATE × STATE_MULTIPLIER / TICK_RATE
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Passive corruption delta | ΔC_passive | float | 0.0–0.035 | Amount of corruption added each tick from passive rise alone |
| Passive rate (per minute) | PASSIVE_RATE | float | 0.5–3.0 | Designer-adjustable baseline rise rate in %/min (default: 1.0) |
| State multiplier | STATE_MULTIPLIER | float | 1.0–1.75 | Multiplier based on current city response state (see table below) |
| Tick rate | TICK_RATE | int | 1–60 | Server ticks per minute (default: 60 — one tick per second) |

**State multiplier values:**

| State | STATE_MULTIPLIER |
|---|---|
| CALM | 1.0 |
| ALERT | 1.25 |
| HOSTILE | 1.5 |
| CRITICAL | 1.75 |

**Applied each tick:**
```
C_new = clamp(C_prev + ΔC_passive, 0.0, 100.0)
```

**Output range:** ΔC_passive ∈ [0.0083%, 0.0875%] per tick at default TICK_RATE=60.
**Full-minute output:** ΔC_per_min ∈ [0.5%, 5.25%] across all states at default PASSIVE_RATE.

**Example (CALM, defaults):**
ΔC_passive = 1.0 × 1.0 / 60 = 0.01667% per tick → 1.0%/min

**Example (CRITICAL, defaults):**
ΔC_passive = 1.0 × 1.75 / 60 = 0.02917% per tick → 1.75%/min

**Worked session scenario (defaults, moderate play):**
- 5 min CALM, no events: +5.0% passive
- 30 shots fired: +4.5% (30 × 0.15%)
- 2 sensor visual triggers: +2.0%
- 1 objective completed: −5.0%
- **Net at ~5 min: ~6.5%** — squad reaches ALERT around minute 18–20 under discipline. Undisciplined squads hit ALERT much sooner.

---

### Formula 2: Event Application

When a Corruption Input Event fires, it is applied to the meter immediately on the server, outside the tick loop.

```
C_new = clamp(C_prev + EVENT_WEIGHT(eventType), 0.0, 100.0)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Pre-event corruption | C_prev | float | 0.0–100.0 | Current meter value before the event |
| Event weight | EVENT_WEIGHT | float | −5.0 to +5.0 | Defined weight for the triggering event type (see Input Event Table in Detailed Design) |
| Post-event corruption | C_new | float | 0.0–100.0 | Meter value after applying the event, clamped to valid range |

**Output range:** C_new ∈ [0.0, 100.0]

**Example (teammate downed, meter at 67%):**
C_new = clamp(67.0 + 5.0, 0.0, 100.0) = 72.0

**Example (objective complete, meter at 78%):**
C_new = clamp(78.0 + (−5.0), 0.0, 100.0) = 73.0 → meter drops but CRITICAL state capabilities do NOT revert (state reversion rule)

---

### Formula 3: Sector Carry

On sector transition, the meter's value is reduced before the next sector begins.

```
C_carry = C_sector_end × SECTOR_CARRY_FACTOR
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Carry value | C_carry | float | 0.0–100.0 | Corruption value passed into the next sector |
| End-of-sector value | C_sector_end | float | 0.0–100.0 | Meter value at the moment the sector concludes |
| Carry factor | SECTOR_CARRY_FACTOR | float | 0.0–1.0 | Fraction of end value that carries forward (default: 0.5) |

**Output range:** C_carry ∈ [0.0, 50.0] at default SECTOR_CARRY_FACTOR=0.5

**Example (squad clears Sector 1 at 62% corruption):**
C_carry = 62.0 × 0.5 = 31.0 → Sector 2 begins at 31% (ALERT state already active)

**Example (squad clears Sector 1 at 18%):**
C_carry = 18.0 × 0.5 = 9.0 → Sector 2 begins at 9% (CALM, clean start)

**Note**: Threshold-fired flags reset at sector transition. Each sector tracks thresholds independently. A squad that reached CRITICAL in Sector 1 and begins Sector 2 at 31% has not yet triggered ALERT for Sector 2.

> *`systems-designer` not consulted — Lean mode. Review formulas manually before implementing. Priority for `/design-review` pass.*

## Edge Cases

- **If two Corruption Input Events fire in the same server tick**: Both are applied sequentially in arrival order. No batching or averaging. If the combined result pushes the meter past a threshold, the threshold event fires after the second application. If the combined result pushes the meter to 100%, the win condition fires immediately after the second application — no subsequent events are processed.

- **If a Corruption Input Event fires during the same tick as the passive tick**: The passive tick is applied first (beginning-of-tick), then events are applied in order of arrival within the tick. The resulting value is what fires threshold checks.

- **If the meter reaches exactly 100.0% from an event (not the passive tick)**: The win condition fires immediately — `CorruptionMaxEvent` is fired, `ThresholdReachedEvent(100)` fires simultaneously, and the match transitions to resolution. The passive tick does not fire again.

- **If the meter reaches 100.0% during the passive tick**: The passive tick clamps at 100.0, fires `ThresholdReachedEvent(100)` and `CorruptionMaxEvent`, and halts further ticking.

- **If an Objective Completion event (−5%) fires when the meter is below 5.0%**: The meter is clamped to 0.0%. It does not go negative. The Reclaimers still receive the benefit of completion (Objective System proceeds); the meter simply remains at 0.

- **If a Reclaimer completes an objective at exactly 25.0%** (reducing to 20.0%): The meter drops to 20.0%. The ALERT threshold is NOT re-triggered — it was already crossed. City capabilities remain at ALERT. Passive rate remains ×1.25.

- **If all 4 Reclaimers are simultaneously downed**: Four `ReclaimeDownedEvent` fire in sequence (+5.0% each = +20.0% total). Win/Loss Conditions (#18) handles the all-downed case — the win condition may trigger before corruption reaches 100% if all-downed is an independent loss condition. *(Provisional: Win/Loss Conditions GDD must specify whether full-squad-downed is an independent Hive Mind win condition or resolved through bleedout timers.)*

- **If a sector transition occurs while the meter is at exactly 99.9% (CRITICAL state)**: The carry value is 99.9% × 0.5 = 49.95%. The new sector begins at 49.95% — Threshold flags reset; ALERT and HOSTILE thresholds must be crossed again in the new sector. *(Flag as tuning priority: does 50% carry give a nearly-consumed squad too much relief?)*

- **If the Hive Mind disconnects mid-match**: The Corruption Meter continues passive ticking (server still runs). No HM unit or environmental inputs will fire. This is a networking edge case — flag for Networking Layer GDD.

- **If `TICK_RATE` is set to 1 (one tick per minute) for testing**: Each tick applies the full 1.0% in a single jump. Valid for testing but will cause visible meter jumps. HUD must handle non-smooth progression gracefully.

- **If `SECTOR_CARRY_FACTOR` is set to 0.0**: Each sector begins at 0% corruption. Valid for tutorial sector or difficulty assist mode.

## Dependencies

| System | Direction | Nature of Dependency | GDD Status |
|---|---|---|---|
| Networking Layer (#1) | This depends on Networking Layer | Server-authoritative `NetworkVariable<float>` requires the session authority model defined by Networking Layer | ⚠️ Not yet designed — provisional |
| Sensor Grid (#7) | Sensor Grid feeds INTO this | Sensor Grid emits `CorruptionInputEvent` for movement, visibility, and biometric detection events | Not yet designed |
| Reclaimer Combat (#6) | Reclaimer Combat feeds INTO this | Reclaimer Combat emits `GunfireEvent` on every weapon discharge | Not yet designed |
| Health & Damage (#5) | Health & Damage feeds INTO this | Health system emits `ReclaimeDownedEvent` on downed state entry | Not yet designed |
| Knockdown & Revival (#12) | Knockdown & Revival feeds INTO this | K&R emits `ReclaimerEliminatedEvent` on bleedout expiry | Not yet designed |
| Objective System (#16) | Bidirectional | Objective System feeds completion/failure events IN; reads corruption value OUT to determine extraction-block state | Not yet designed |
| Environmental Controls (#15) | Environmental Controls feeds INTO this | Environmental Controls emit `EnvironmentalHazardActivatedEvent` on HM trigger | Not yet designed |
| Threshold Event System (#17) | This feeds INTO Threshold Event System | Corruption Meter fires `ThresholdReachedEvent(25|50|75|100)` on first crossing of each threshold | Not yet designed |
| Win/Loss Conditions (#18) | This feeds INTO Win/Loss | Corruption Meter fires `CorruptionMaxEvent` at 100%; Win/Loss owns match termination | Not yet designed |
| Reclaimer HUD (#20) | This feeds INTO HUD | HUD subscribes to `NetworkVariable<float>` for display | Not yet designed |
| Hive Mind Interface (#21) | This feeds INTO HM Interface | Interface subscribes to value and threshold events for meter display and animations | Not yet designed |
| Sector Transition System (#23) | Bidirectional | Sector Transition triggers carry logic; Corruption Meter applies sector carry formula and resets threshold flags | Not yet designed |
| Post-Match Debrief (#25) | This feeds INTO Debrief | Debrief reads the meter's time-series event log for Corruption timeline rendering | Not yet designed |

**Hard dependencies** (system cannot function without): Networking Layer (#1)

**Soft dependencies** (meter logic works without, but sends events with no consumer): All other systems above — the meter is designed as a standalone server-side value; downstream consumers subscribe to its events.

## Tuning Knobs

| Parameter | Default | Safe Range | Effect of Increase | Effect of Decrease | Interacts With |
|---|---|---|---|---|---|
| `PASSIVE_RATE` | 1.0 %/min | 0.5–2.0 %/min | Faster baseline escalation — matches feel more like countdowns; less player agency over pacing | Slower escalation — players have more time, HM must work harder; risks matches feeling slow at low combat pace | `STATE_MULTIPLIER` values; total time-to-100% |
| `STATE_MULTIPLIER` (CALM) | 1.0× | 0.5–1.5× | Faster early escalation — ALERT arrives sooner | Slower start — more CALM time before city escalates | `PASSIVE_RATE` |
| `STATE_MULTIPLIER` (ALERT) | 1.25× | 1.0–2.0× | ALERT feels significantly more dangerous | ALERT feels similar to CALM — diminishes threshold impact | `PASSIVE_RATE`, feel of 25% threshold |
| `STATE_MULTIPLIER` (HOSTILE) | 1.5× | 1.1–2.5× | Mid-game crisis arrives quickly | More room to operate at HOSTILE — reduces mid-game pressure | `PASSIVE_RATE`, feel of 50% threshold |
| `STATE_MULTIPLIER` (CRITICAL) | 1.75× | 1.25–3.0× | CRITICAL is a crisis; near-impossible without immediate objective action | CRITICAL is survivable without objectives — risks HM feeling blocked at end-game | `PASSIVE_RATE`, feel of 75% threshold |
| `GUNFIRE_WEIGHT` | 0.15% | 0.05–0.5% | Gunfire is heavily punished — stealth becomes mandatory | Gunfire barely matters — Reclaimers can spam weapons freely | Reclaimer Combat, Ammo, squad noise budget |
| `TEAMMATE_DOWNED_WEIGHT` | 5.0% | 2.0–10.0% | Each downed teammate is a crisis; revives become frantic | Downed teammates are a minor inconvenience | Knockdown & Revival, squad cohesion feel |
| `OBJECTIVE_REDUCTION` | 5.0% | 3.0–10.0% | Objective completion gives major relief — Reclaimers feel rewarded | Completing objectives barely helps — feels futile | Objective System; total time extension per objective |
| `OBJECTIVE_FAIL_WEIGHT` | 4.0% | 2.0–8.0% | Missed objectives are costly — encourages aggressive objective focus | Missed objectives barely matter — reduces objective urgency | Objective System |
| `SECTOR_CARRY_FACTOR` | 0.5 | 0.0–0.8 | More carry — later sectors start harder; momentum compounds | Less carry — each sector feels fresh; reduces inter-sector tension | Sector Transition System |
| `TICK_INTERVAL` | 1.0 sec | 0.1–5.0 sec | Fewer ticks/min — meter jumps visibly; reduces responsiveness | More ticks/min — smoother meter progression; higher server load | Performance; HUD smoothness |

**Interaction warnings:**
- Raising `PASSIVE_RATE` AND `STATE_MULTIPLIER(CRITICAL)` simultaneously risks matches ending before Reclaimers reach Sector 3. Test in combination.
- Raising `TEAMMATE_DOWNED_WEIGHT` above 8.0% risks a single downed teammate triggering a threshold — may feel punishing beyond player control.
- Setting `SECTOR_CARRY_FACTOR` above 0.7 risks Sector 2 beginning in HOSTILE or CRITICAL from carry alone, leaving Reclaimers no recovery window.

## Visual/Audio Requirements

The Corruption Meter is a data system — it does not own visuals or audio directly. It emits the events that Reclaimer HUD (#20) and Hive Mind Interface (#21) must respond to with feedback. This section defines required feedback moments and urgency. Implementation belongs in the HUD and Interface GDDs.

**Art Bible references**: Section 7 specifies the meter display: vertical bar with "intruder grammar" (rises from bottom), Corruption Teal (#1AD9CC) fill, snap motion + 1-frame white flash on updates, threshold interrupt fires at 0.26 (just above the 25% threshold value to allow animation lead-in).

| Event | Required Feedback | Owner GDD | Priority |
|---|---|---|---|
| Passive rise (continuous) | Continuous slow meter fill. Both HUD and HM Interface show identical value in real time. | Reclaimer HUD, HM Interface | HIGH |
| Threshold 25% crossed | Threshold interrupt animation + audio sting distinct from ambient. Both factions receive visual feedback. | HUD, HM Interface, Threshold Event System | HIGH |
| Threshold 50% crossed | Same as 25%, escalated urgency. | HUD, HM Interface, Threshold Event System | HIGH |
| Threshold 75% crossed | Maximum urgency interrupt. HM Interface: all radial elements propagate outward. Reclaimer HUD: threshold interrupt + screen-edge Corruption Teal pulse. | HUD, HM Interface | HIGH |
| Threshold 100% (Hive Mind win) | Full match-end sequence. Owned by Win/Loss Conditions (#18). | Win/Loss Conditions | HIGH |
| Objective completion (−5% reduction) | Visible downward tick on meter. Brief audio relief beat. Reclaimers receive positive feedback cue. | Reclaimer HUD | MEDIUM |
| Teammate downed (+5.0% spike) | Abrupt upward meter spike animation, distinct from passive rise motion. | Reclaimer HUD | MEDIUM |
| Gunfire per-shot (+0.15%) | Subtle micro-tick. Must NOT distract at sustained-fire cadence — consider batching visual updates to 10-tick windows for gunfire-only inputs. | Reclaimer HUD | LOW |
| Extraction blocked (CRITICAL state) | Extraction UI blocked state + indicator explaining meter must drop below 75% to re-enable. | Reclaimer HUD | HIGH |

> 📌 **Asset Spec** — After art bible and HUD/Interface GDDs are authored, run `/asset-spec system:corruption-meter` to produce per-asset descriptions for the meter bar, threshold interrupt animation, and reduction tick.

## UI Requirements

UI display is owned by Reclaimer HUD (#20) and Hive Mind Interface (#21). This system provides the value; those systems own the display. See Visual/Audio Requirements above for the event list those GDDs must handle.

The Corruption Meter provides one primary output to both display systems:
- `NetworkVariable<float> CorruptionValue` — current meter value [0.0, 100.0]
- `ThresholdReachedEvent(thresholdValue)` — fires once per threshold per sector
- `CorruptionMaxEvent()` — fires at 100%

> 📌 **UX Flag — Corruption Meter**: The threshold interrupt behavior (0.26 trigger point, 1-frame white flash, vertical bar snap motion) is specified in Art Bible Section 7. When Reclaimer HUD and Hive Mind Interface GDDs are authored, the UX designer must validate that the threshold interrupt does not occlude critical HUD elements during a match-critical moment (e.g., a downed teammate and a threshold crossing simultaneously). Run `/ux-design` when both GDDs are authored.

## Acceptance Criteria

> *`qa-lead` not consulted — Lean mode. Validate these criteria with a QA lead before sprint authoring begins.*

**Core behavior:**

- **GIVEN** the match has just started and no player actions have occurred, **WHEN** 60 seconds pass, **THEN** the Corruption value has increased by exactly 1.0% (±0.01% tolerance for float precision).

- **GIVEN** the meter is in CALM state (below 25%), **WHEN** a Reclaimer fires a single shot, **THEN** the meter value increases by 0.15% within one server tick (≤1 second).

- **GIVEN** the meter is in any state, **WHEN** a Reclaimer teammate enters downed state, **THEN** the meter value increases by 5.0% within one server tick, and the new value is applied before any further tick.

- **GIVEN** the meter is at 24.9% and a teammate is downed (+5.0%), **WHEN** the event fires, **THEN** the meter reaches 29.9%, the ALERT threshold fires exactly once, and Stalker deployment becomes available to the Hive Mind.

- **GIVEN** the meter has crossed the 25% threshold, **WHEN** an objective completion reduces the meter from 27% to 22%, **THEN** the meter value is 22.0%, the Hive Mind retains Stalker deployment access, and the passive rate multiplier remains ×1.25.

- **GIVEN** the meter is in CRITICAL state (75%+), **WHEN** Reclaimers attempt to extract, **THEN** the extraction action is blocked and the Reclaimer HUD displays the extraction-blocked state.

- **GIVEN** the meter is in CRITICAL state (77%) and Reclaimers complete an objective (−5%), **WHEN** the meter drops to 72%, **THEN** the extraction block lifts and the HUD reflects the unblocked state.

- **GIVEN** the meter is at 98.0% and a downed teammate event fires (+5.0%), **WHEN** the event is applied, **THEN** the meter clamps to exactly 100.0%, `CorruptionMaxEvent` fires, `ThresholdReachedEvent(100)` fires, and the match transitions to Hive Mind win state within one server frame.

**Networking:**

- **GIVEN** a Reclaimer client and the Hive Mind client are both connected, **WHEN** the corruption value changes on the server, **THEN** both clients reflect the updated value within 100ms under normal LAN conditions.

- **GIVEN** a Reclaimer client fires a weapon, **WHEN** the shot fires locally, **THEN** the server's Corruption value reflects the +0.15% event within two server ticks (≤2 seconds).

**Sector carry:**

- **GIVEN** Sector 1 ends with Corruption at 60.0%, **WHEN** Sector 2 begins, **THEN** the Corruption value is exactly 30.0%, threshold-fired flags for 25/50/75% are reset, and the city is in CALM state.

**Formulas:**

- **GIVEN** PASSIVE_RATE=1.0, STATE_MULTIPLIER=1.75 (CRITICAL), and TICK_RATE=60, **WHEN** one tick fires, **THEN** the meter increases by exactly 0.02917% (±0.00001% tolerance).

- **GIVEN** the meter is at 0.0% and an objective completion event fires (−5.0%), **WHEN** the event is applied, **THEN** the meter remains at 0.0% (floor clamp active).

**Event log:**

- **GIVEN** a 10-minute match concludes, **WHEN** Post-Match Debrief requests the event log, **THEN** the log contains a time-series entry for every Corruption Input Event that fired, each with: timestamp, eventType, weight, and resultingValue.

## Open Questions

| Question | Owner | Priority | Resolution |
|---|---|---|---|
| Does full-squad-downed (all 4 Reclaimers in downed state simultaneously) trigger an independent Hive Mind win, or resolve through bleedout timers feeding into the Corruption Meter? | Win/Loss Conditions GDD | HIGH | Unresolved — must be defined before Win/Loss GDD (#18) is authored |
| Should sector carry reset threshold flags entirely, or should a squad entering Sector 2 at 31% be in ALERT state immediately without re-triggering the threshold event? | Design direction | MEDIUM | Current spec: flags reset, squad must re-cross thresholds. Revisit during playtesting. |
| At what granularity does the event log write entries for Post-Match Debrief? Every event (high fidelity) or sampled every N seconds? | Post-Match Debrief GDD | LOW | Defer to Post-Match Debrief GDD authoring |
| Networking Layer GDD must confirm: is `NetworkVariable<float>` correct for SYNTHFALL's asymmetric session model, or does the Hive Mind's god-view role require a different authority structure? | Networking Layer GDD | HIGH | Provisional assumption: server-authoritative. Resolve when Networking Layer GDD (#1) is authored. |
| Should Ghost class's sensor jammer reduce corruption weight from acoustic sensor triggers, or prevent the sensor event from firing entirely? | Reclaimer Class Abilities GDD | MEDIUM | Flag for Class Abilities GDD (#11) — Ghost jammer must specify whether it suppresses the Sensor Grid event or reduces the weight at the meter side. |
