# Story 007: Per-tick re-tuning pass (tick-budget / base-rate half) + per-frame cost measurement

> **Epic**: Time & Tick System
> **Status: Complete (2026-07-25 — 848/848 suite green, parent-verified; tick half of criterion #4)
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-25

> ⚠️ **NEEDS-DECISION + CROSS-EPIC COORDINATION** — this story records a deliberate
> re-tune of config values against production load. The re-tuned numbers are a
> balance decision owned by systems-designer / game-designer (GDD Open Question,
> "Open — tracked here, not yet actioned"). It is ONE coordinated config change
> spanning this epic (tick-budget / base-rate half) and the `villager-ai-behavior`
> epic (`max_deciding_per_tick` half), recorded once with shared rationale. Do not
> pick values unilaterally — surface to the owners and coordinate the paired story.

## Context

**GDD**: `design/gdd/time-tick-system.md`
**Requirement**: `TR-time-tick-system-020`, `TR-time-tick-system-044`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0008 (Villager AI Execution & Threading) — primary (base tick rate 4.0 ticks/sec; `max_deciding_per_tick` budget is the coordinated Villager-AI-owned half); ADR-0002 — secondary (config-change discipline: `.tres` edit + `validate()` + rationale)
**ADR Decision Summary**: Base tick rate = 4.0 ticks/sec (slice-validated, adopted). The per-tick re-tune records `ticks_per_second` / `max_ticks_per_frame` (this epic) and `max_deciding_per_tick` (villager-ai epic) as a single config change with rationale, measured against production load.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: The per-frame cost measurement (TR-044) requires a full build + profiling — it is DEFERRED in the GDD until the integrated build exists (Milestone 01 S3 integration). Measure `game_delta` + accumulator cost against the <0.5 ms/​physics-frame guardrail on the production window.

**Control Manifest Rules (this layer)**:
- Required: runtime-tunable values live in config `.tres`; a re-tune is a config edit with rationale, never a code constant.
- Required: base tick rate 4.0 ticks/sec is the authoritative value (time-tick-system.md); the `max_deciding_per_tick` budget still bounds per-tick Deciding passes (ADR-0008) — no FSM/staggering change.
- Guardrail: `game_delta` + tick-accumulator computation stays under 0.5 ms combined per physics frame.

---

## Acceptance Criteria

*From GDD `design/gdd/time-tick-system.md` + Milestone 01 Must-Ship, scoped to this story:*

- [ ] `ticks_per_second = 4.0` and `max_ticks_per_frame` are confirmed in config against production load; any change is recorded as a config `.tres` edit with written rationale (Milestone 01: "Per-tick re-tuning pass done"). [TR-time-tick-system-020]
- [ ] The tick-budget half is coordinated with the `villager-ai-behavior` epic's `max_deciding_per_tick` re-tune and recorded ONCE with shared rationale (Milestone 01 Notes — shared tech debt).
- [ ] `game_delta` + tick-accumulator per-frame cost is measured on the integrated build and stays under 0.5 ms combined (GDD AC17). [TR-time-tick-system-044]
- [ ] The re-tune's real-time-equivalent impact (doubling `ticks_per_second` 2.0→4.0 doubles downstream per-tick rates) is documented as an explicit flag for the Needs & Mood balance pass — NOT silently auto-corrected here (GDD Open Question). *(Documentation deliverable; the Needs & Mood re-tune itself is Milestone 02, out of scope.)*

---

## Implementation Notes

*Derived from ADR-0008 / ADR-0002 Implementation Guidelines:*

- Run this LAST in the epic, after Stories 001–006 land and the integrated build exists, so measurement reflects production load (population ceiling 20–30, warp 1x AND 3x).
- Coordinate with the `villager-ai-behavior` `max_deciding_per_tick` story before finalizing — one change record, shared rationale (spike-tuned initial `max_deciding_per_tick = 1`; p95 16.7 ms at 3x per the ADR-0008 spike).
- Record the change per the config-data discipline: edit the `.tres`, re-run `validate()`, write the rationale (what production load justified the values).
- Author the real-time-equivalent caveat note for the Needs & Mood balance pass owner (systems-designer / game-designer) — the per-tick decay/recovery rates now read ~2× faster in real time and must be re-tuned (not halved) in Milestone 02.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- `villager-ai-behavior` epic: the `max_deciding_per_tick` re-tune half (coordinated, recorded jointly here).
- Milestone 02: the actual Needs & Mood per-tick rate re-tune (this story only flags it).
- Stories 001–006: the mechanism being tuned.

---

## QA Test Cases

*Config/Data — smoke check + measurement evidence (not an automated logic test).*

- **Smoke-1 (config values)**: `ticks_per_second == 4.0`, `max_ticks_per_frame` at the agreed value; `validate()` returns empty (no clamps); rationale recorded.
- **Smoke-2 (per-frame cost)**: on the integrated production build, profiled `game_delta` + accumulator cost < 0.5 ms/​physics frame at 1x and 3x with 20–30 villagers.
- **Coordination check**: the `max_deciding_per_tick` change is recorded in the SAME change note as this half.

---

## Test Evidence

**Story Type**: Config/Data (with a deferred profiling/measurement gate — TR-044)
**Required evidence**: smoke check pass (`production/qa/smoke-*.md`) recording the config values, the shared re-tune rationale, and the profiled per-frame cost measurement. The real-time-equivalent caveat note is a written artifact referenced from the smoke doc.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001–006 (full mechanism) DONE + the integrated build existing (Milestone 01 S3) + the `villager-ai-behavior` `max_deciding_per_tick` re-tune story (coordination) + a systems-designer / game-designer decision on the values.
- Unlocks: None (closes the Time & Tick tech-debt item).
> **Note (2026-07-23, from tick-001):** time_warp_options shipped GDD-authoritative [1,2,3]; the slice's 10x/20x testing gears (user direction 2026-07-21) are NOT in production config yet — decide during this re-tune story whether they return as debug-only warps (data-driven, one-line .tres change).
