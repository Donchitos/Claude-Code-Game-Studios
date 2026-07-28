# Story 001: Ambient-life wave 1 — chimney smoke, foliage sway, idle-behaviors hook, interior clutter, torch flicker

> **Epic**: Presentation Experience
> **Status: Sub-scope A Complete (2026-07-24 — 819/819 suite green, parent-verified; CD sign-off pass pending; Sub-B awaits villager-ai-019)
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: ~2.5 days (sub-scope A environmental ~1.5d + sub-scope B villager-idle hook ~1d) — split-schedulable per its two different dependency gates
> **Manifest Version**: 2026-07-23
> **Last Updated**: —
> **M01 tag**: Should-Ship (CD-protected — exit criterion #9)

## Context

**GDD**: N/A — source is `design/art/art-bible.md` §6.5 (Ambient Life & Motion, CONFIRMED user decision 2026-07-23) + §5.6 (Expression & Personality Without Faces). §8.9 sets the technical budgets.
**Requirement**: Art-Bible-traced (no TR-ID — see epic "Requirements" note).

**ADR Governing Implementation**: N/A — Art-Bible-driven. ADR-0014 (rendering) and ADR-0008 (villager FSM) are **integration context only**, not decision sources.
**ADR Decision Summary**: n/a — the "what and how warm" is a CD/AD call captured in §6.5; this story presents motion on top of the slice-validated static foundation without touching committed-block materials or adding simulation.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: GPUParticles3D (smoke, leaf/pollen drift), vertex-shader wind (foliage sway), and light-energy noise (torch flicker) all sit on the post-cutoff rendering domain — cross-reference `docs/engine-reference/godot/` before any API. **Torch/lantern flicker MUST respect Art Bible A5: sub-3Hz** — no free pass on flicker rate. Particle/VFX budget is the debrief's #1 reserved-budget gap (§8.9.5) — stay inside the technical-artist's per-frame allowance.

**Control Manifest Rules (this layer — Presentation):**
- Required: ambient motion is presentation-only, added on top of the static foundation; smoke only on *occupied/lit* buildings (absence is a readable "nobody home" tell, §6.5 + Principle 1); flicker sub-3Hz.
- Forbidden: baking any ambient motion or state color into committed-block materials (ADR-0014); introducing new simulation for idle behaviors (they are presentation of existing FSM state).
- Guardrail: cheap cost classes only for wave 1 (vertex-shader wind, small GPUParticles3D, static clutter props, light-energy noise); stay inside the §8.9 VFX/particle budget.

---

## Acceptance Criteria

*From Art Bible §6.5 (CONFIRMED first production wave) + §5.6, scoped to this story:*

**Sub-scope A — environmental ambient motion (gated on the mesher):**
- [ ] Chimney/hearth smoke wisps render as small GPUParticles3D, **only on occupied/lit buildings** (smoke absence = "nobody home"). [§6.5]
- [ ] Grass/foliage sways via vertex-shader wind (vegetation is the sanctioned "soft" shape exception, §3.2). [§6.5]
- [ ] Interior warm-detail clutter appears as static props implying recent use (cheapest life win). [§6.5]
- [ ] Torch/lantern flicker (carried + fixed) via light-energy noise, **verified sub-3Hz (A5)**. [§6.5 + A5]

**Sub-scope B — villager idle-behaviors hook (gated on the villager FSM/movement):**
- [ ] The villager Idle/Wandering FSM state drives visible idle behaviors — stretching, glancing at an unfinished build, sitting at a furnished table, brief exchanges between bonded villagers — **reusing the existing FSM, adding no new simulation** (§5.6, §6.5 "highest mood-value-per-cost item"). [§5.6]
- [ ] Idle behaviors are presentation of existing state only — grep/review confirms no new simulation, no needs/mood logic added here. [§5.6]

**Whole-story:**
- [ ] Nothing bakes into committed-block materials; the slice-validated static foundation is untouched. [ADR-0014 context]
- [ ] Art-director / creative-director sign-off on the mood result (the binding CD-protected acceptance gate).

---

## Implementation Notes

*Derived from Art Bible §6.5 / §5.6 (no ADR guidelines exist — this is art direction):*

- **Split by dependency gate.** Sub-scope A (smoke, foliage sway, interior clutter, torch flicker) needs only the mesher rendering a world — implementable as soon as vox-007 lands. Sub-scope B (villager idle behaviors) needs the villager FSM's Idle/Wandering state and movement to exist — implementable only after the villager wandering/idle-micro-behaviors story lands. Schedule the two halves independently; do not block A on B.
- Smoke gating on occupied/lit buildings is a deliberate readable signal (Principle 1) — wire the emit condition to the building's lit/occupied state, do not emit unconditionally.
- The idle-behaviors hook **reads** FSM state (Idle/Wandering) and plays presentation; it must not add decisions, needs, or scheduling — those live in Villager AI (ADR-0008). Treat it as an observer of existing state.
- Torch flicker: light-energy noise clamped below 3Hz — assert the rate, don't eyeball it.
- Keep every element in its §6.5 "Cheap" cost class for wave 1; weather and day/night behavioral cues are explicitly the second wave (out of scope here).

---

## Out of Scope

*Handled elsewhere / later waves — do not implement here:*

- Wave 2 items (§6.5): weather states, day/night behavioral cues, distant birds, leaf/pollen drift, water shimmer, horizon-fog drift, squad banner/cape motion, ambient wildlife.
- The villager FSM itself and its Idle/Wandering micro-behaviors (Villager AI epic — this story only *presents* them).
- The mesher and world rendering (Voxel World epic).
- Any new simulation, needs, or mood logic (Needs & Mood, Feature layer).

---

## QA Test Cases

*Visual/Feel — manual verification (screenshot + art-director/CD sign-off). CD sign-off is the binding gate for these CD-protected items.*

- **AC-A (smoke on occupied/lit only)**: Setup: one occupied/lit building + one empty building side by side. Verify: screenshot. Pass condition: smoke wisps on the occupied/lit one, none on the empty one (the "nobody home" tell reads).
- **AC-A (foliage sway)**: Setup: a vegetated area under wind. Verify: capture over several frames. Pass condition: grass/foliage sways via the vertex shader; static foundation (terrain, buildings) is unaffected.
- **AC-A (torch flicker sub-3Hz)**: Setup: a fixed torch + a carried lantern. Verify: sample light-energy over time. Pass condition: flicker frequency is below 3Hz (A5) — asserted, not eyeballed.
- **AC-A (interior clutter)**: Setup: a furnished interior. Verify: screenshot. Pass condition: warm static clutter reads as "recently used", no motion cost.
- **AC-B (idle behaviors, no new sim)**: Setup: villagers with zero jobs + zero urgent needs (Idle/Wandering). Verify: observe behaviors + grep/review the diff. Pass condition: idle behaviors play (stretch/glance/sit/exchange), driven by existing FSM state; no new simulation, needs, or scheduling code was added.
- **AC-whole (materials untouched)**: Verify: grep committed-block materials. Pass condition: no ambient motion or state color baked into committed-block materials.

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/ambient-life-wave-1-evidence.md` + art-director/creative-director sign-off (CD-protected — sign-off is mandatory, not advisory). Torch-flicker sub-3Hz check may carry a small automated assertion alongside the screenshots.
**Status**: [ ] Not yet created

---

## Dependencies

- **Sub-scope A (environmental)** Depends on: `voxel-world` story-007 (mesher CW+culling — world must render for ambient motion to attach to / be seen against); benefits from story-006 (terrain geometry) and story-015 (view-window streaming) being present so it survives at scale.
- **Sub-scope B (villager idle behaviors)** Depends on: `villager-ai-behavior` story-019 (wandering micro-behaviors) + the FSM/movement chain it sits on (story-001 scaffold ✓ S3, plus the Deciding/Traveling/Idle states — story-006/009). The hook cannot play idle behaviors until an Idle/Wandering state exists to read.
- Unlocks: Ambient-life wave 2 (§6.5 weather/day-night pass).
- **Not schedulable in Sprint 4** — its gates (mesher, villager wandering) land across Sprint 4/5; this is Presentation-pass (Sprint 5+) work.

---

## Sub-B Scope Gap (2026-07-27, flagged not hidden)

Sub-B delivers the idle behaviours that existing FSM state can actually
drive: a SIT draw settles the figure into a lower seated posture, a
PAUSE_LOOK draw tilts the head back as a stretch/glance. Walking,
bed-drifting and working villagers read as before.

Two behaviours named in the art bible were deliberately NOT implemented:
"glancing at an unfinished build" needs build-target awareness, and "brief
exchanges between bonded villagers" needs a villager-bond concept. Neither
exists anywhere in villager_ai, and inventing either would be new
Core-layer simulation — which this story's own guardrail forbids
(presentation reads existing state, it never invents state).

DECISION OWED (producer/CD): either accept Sub-B as the two FSM-backed
behaviours, or open a follow-on story once build-awareness and bonding
exist as simulation. Also outstanding: the CD sign-off and the written
ambient-life evidence entry for milestone criterion #9.
