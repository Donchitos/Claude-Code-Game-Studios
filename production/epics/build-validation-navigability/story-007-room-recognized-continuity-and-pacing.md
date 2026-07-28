# Story 007: `room_recognized` continuity & celebration pacing

> **Epic**: Build Validation & Navigability
> **Status: Complete (2026-07-27 — 1320/1320 suite green 0 orphans, agent-verified; parent re-verifies with the concurrent scene-006)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/build-validation-navigability.md`
**Requirement**: `TR-build-validation-navigability-032`, `TR-build-validation-navigability-040`, `TR-build-validation-navigability-049`, `TR-build-validation-navigability-050`, `TR-build-validation-navigability-039`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0007 (room analysis + the transient snapshot's edge-detection role); ADR-0002 (`room_cue_cooldown_ticks` as a config knob)
**ADR Decision Summary**: The transient snapshot exists solely to edge-detect transitions — it is memory for eventing, never a compute cache. Pacing values are config-driven per ADR-0002, never hardcoded.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: The cooldown is measured in **ticks** (`room_cue_cooldown_ticks` = 20 ≈ 10 s at 1x), and the project's base tick rate is **4.0 ticks/sec** — a knob authored against an earlier rate means a different real-time window. Read ticks from the Time & Tick system; never wall-clock, never `Engine.time_scale`.

**Control Manifest Rules (this layer)**:
- Required: the snapshot is edge-detection memory only; emissions are synchronous within one pass.
- Forbidden: re-firing `room_recognized` on a re-analysis that keeps a room valid, or on merges/splits of existing valid rooms; `SceneTree.paused` / `Engine.time_scale` for the cooldown; hardcoded pacing values.
- Guardrail: at most one celebration EVENT per `room_cue_cooldown_ticks` — a same-pass group counts as one event.

**Note on the celebration beat**: the one-shot cue (warm highlight + soft chime)
is a **CD-protected presentation item** (Art Bible §5.6, loop-payoff
communication). This story owns the *signal contract and pacing*; the cue itself
is presentation-side. Building UI has ruled `room_recognized` has **no HUD
surface** (its Rule 9d) — the celebration is exclusively the in-world highlight
plus chime.

---

## Acceptance Criteria

*From GDD `design/gdd/build-validation-navigability.md`, scoped to this story:*

- [ ] `room_recognized` carries `(region cells, celebrate: bool, pass_group_id)` and fires when a region transitions non-Room → Room; all emissions from one analysis pass share one `pass_group_id`. [TR-040]
- [ ] **Region continuity**: a newly valid room fires `room_recognized` only if **NONE** of its interior cells belonged to a valid room in the previous snapshot — merges and splits of existing rooms never re-fire it. [TR-049]
- [ ] **AC21**: **GIVEN** a candidate region becomes a valid room, **WHEN** the transition occurs, **THEN** exactly one `room_recognized` fires — and does NOT re-fire on later re-analyses that keep the room valid, NOR when that room later merges with or splits from other valid rooms. [TR-049]
- [ ] **AC32**: **GIVEN** two distinct regions become valid rooms in DIFFERENT analysis passes within `room_cue_cooldown_ticks` of each other, **WHEN** the second transition occurs, **THEN** both emit `room_recognized`, the first with `celebrate = true` and the second with `celebrate = false` (pacing — sequential case). [TR-050]
- [ ] **AC32b**: **GIVEN** two distinct regions become valid rooms in the SAME analysis pass, **WHEN** the pass completes, **THEN** both emit `room_recognized` with `celebrate = true` and an identical `pass_group_id`, and no third signal fires — the same-pass group is one celebration event, never an arbitrary winner; a room recognized in a LATER pass within the cooldown window then emits `celebrate = false`. [TR-050]
- [ ] The cooldown window starts **after** the group; recognitions in later passes inside the window emit with `celebrate = false` (quiet status only). `room_cue_cooldown_ticks` = 0 means every pass celebrates. [TR-050]
- [ ] The confirmation is one of exactly four signals this system emits; **no other emissions exist**. [TR-039] [TR-032]
- [ ] Accepted MVP consequence: a previously-Sealed pocket merging into an existing valid room gets **no** celebration — the region as a whole was not "new"; its furniture's `shelter_status_changed` still fires correctly.

---

## Implementation Notes

*Derived from ADR-0007/0002 Implementation Guidelines:*

- Continuity test: for a region newly verdicted Room, look up each interior cell in the **previous** snapshot's classification map. Fire only if none was in a valid room. This single rule covers AC21's re-fire, merge, and split cases — do not write three branches.
- `pass_group_id` is minted once per analysis pass and stamped on every `room_recognized` emitted by that pass. It exists **for celebration grouping only** — the Warning/Info signals carry no pass id (Rule 10).
- Pacing state is a single "last celebration tick" value compared against `room_cue_cooldown_ticks`. Set it once per group, after the group's emissions, not per room.
- On the load pass, `room_recognized` is silent (story 005's silencing hook); AC31's assertion lives in story 008.
- All values from config (story 001). No literal 20 anywhere.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: `shelter_status_changed`.
- Story 008: the Warning/Info tiers and the load-pass emission assertions (AC31).
- Story 009: wiring the emission into the loop-payoff surface.
- Presentation: the highlight/chime treatment itself (Art Bible, CD-protected).

---

## QA Test Cases

- **AC21**: region becomes a Room → exactly one `room_recognized`; re-analyze while still valid → zero; merge it with another valid room → zero; split it → zero.
- **AC32**: two rooms recognized in different passes inside the cooldown → first `celebrate = true`, second `celebrate = false`.
- **AC32b**: two rooms recognized in the same pass → both `celebrate = true`, identical `pass_group_id`, exactly two emissions (no third grouping signal); a third room in a later pass inside the window → `celebrate = false`.
- **Cooldown boundary**: a recognition exactly `room_cue_cooldown_ticks` after the previous group → `celebrate = true`; one tick earlier → `false`. With `room_cue_cooldown_ticks` = 0, every pass celebrates.
- **Sealed-pocket merge**: a Sealed pocket merges into an existing valid room → zero `room_recognized`, and the pocket's furniture still emits `shelter_status_changed`.
- Edge cases: a room that goes Room → Sealed → Room fires again on the second transition (no interior cell was in a valid room in the immediately-previous snapshot); a pass that recognizes zero rooms mints no `pass_group_id` emission.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/build_validation/room_recognized_pacing_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 004 (Room verdict), 005 (pass + snapshot edge detection)
- Unlocks: 008, 009

