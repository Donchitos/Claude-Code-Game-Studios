# Story 022: max_deciding_per_tick production re-tune (TECH DEBT 2)

> **Epic**: Villager AI & Behavior
> **Status: Complete (2026-07-25 — 849/849 suite + 7/7 perf green, parent-verified; criterion #4 AI half, coordinated with tick-007)
> **Layer**: Core
> **Type**: Config/Data
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-ai-behavior.md`
**Requirement**: `TR-villager-ai-behavior-041` (performance budget at population ceiling; partial — this story owns the `max_deciding_per_tick` knob half)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary; ADR-0008 (owns the knob)
**ADR Decision Summary**: `max_deciding_per_tick` is a `VillagerAIConfig` knob (spike-tuned initial value 1). Milestone-01 Must-Ship "Per-tick re-tuning pass done" — this epic owns the `max_deciding_per_tick` portion, re-tuned against production load. The tick-budget / base-tick-rate half is owned by the `time-tick-system` epic — ONE coordinated config change spanning both, recorded once with shared rationale.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Base tick rate = 4.0 ticks/sec (time-tick-system authoritative). More Deciding passes fire per second than at earlier rates, but the per-tick budget still bounds them — no FSM/staggering change. Spike reference: p95 16.7 ms at 3x warp with `max_deciding_per_tick = 1`.

**Control Manifest Rules (this layer)**:
- Required (Feature): re-tune via the config `.tres` (data-driven); record the change with rationale via the Foundation Spine `.tres` discipline.
- Forbidden: changing FSM or staggering mechanics to achieve the re-tune (it is a config value); making the change without recording the coordinated rationale.
- Guardrail: frame budget must hold at 1x AND warp at the 20–30 population ceiling.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-ai-behavior.md`, scoped to this story:*

- [ ] `max_deciding_per_tick` is re-tuned against production load (not just the spike stand-in), with the chosen value backed by a measurement.
- [ ] The change is recorded as a config change with rationale, coordinated as ONE change with the `time-tick-system` base-tick-rate / tick-budget re-tune (shared rationale documented once).
- [ ] After the re-tune, the frame budget holds at 1x and warp at the population ceiling (smoke/perf check — see Story 025 for the stress harness).
- [ ] No FSM or staggering code changes — the re-tune is purely a config value.

---

## Implementation Notes

*Derived from ADR-0002/0008 Implementation Guidelines:*

- Measure the Deciding-pass cost against production code (not the GDScript stand-in) at the 30-villager ceiling under 1x/3x.
- Coordinate with the time-tick-system rate story so the base-tick-rate and `max_deciding_per_tick` land together with a single shared rationale record.
- Update the `.tres` config value only; document the before/after and the measurement basis.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: the scheduler mechanism itself (this story only sets the value).
- Story 025: the stress harness that produces the measurement.
- The time-tick-system base-tick-rate story (different epic — coordinated, not owned here).

---

## QA Test Cases

*Config/Data story — verified via smoke check, not automated unit test:*

- **Smoke check**: With the re-tuned `max_deciding_per_tick`, run the 30-villager stress at 1x and 3x; confirm frame budget holds and the value is recorded with rationale. Pass condition: budget held + config change documented + coordinated with time-tick rate change.

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: smoke check pass — `production/qa/smoke-*.md` referencing the re-tune measurement and the coordinated config change.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 005 (scheduler), and an integrated build to measure production load (Milestone-01 integration); coordinate with the time-tick-system base-tick-rate re-tune
- Unlocks: None
- **NEEDS-DECISION**: the coordinated single config change with the time-tick-system rate story requires cross-epic sequencing — confirm both land in the same change with shared rationale before closing.
