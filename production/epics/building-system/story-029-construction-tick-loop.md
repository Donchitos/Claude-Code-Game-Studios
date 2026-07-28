# Story 029: Blueprint-then-build — construction tick loop (Planned→UnderConstruction→Built, F3)

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 629/629 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-052`, `TR-building-system-057`, `TR-building-system-058`, `TR-building-system-068`, `TR-building-system-069`, `TR-building-system-079`, `TR-building-system-080`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0009 (Deterministic Movement & Occupancy Ordering) — secondary
**ADR Decision Summary**: A valid commit creates blueprint cells (not grid blocks); villager construction converts them to real blocks over game time; built cells mutate only via worker-executed jobs. Construction advances on Time & Tick's game ticks, warp-invariant.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Construction consumes **game ticks** (Time & Tick, base 4.0 ticks/sec — see manifest), never raw delta; pause halts construction; warp changes wall-clock, not tick count. `max_ticks_per_frame` burst bounds catch-up.

**Control Manifest Rules (this layer — Core):**
- Required: blueprint cells are planned cells invisible to Voxel World's data layer; a cell under active construction advances per game tick and, when build time elapses, this system issues the Voxel World write and retires the blueprint cell; built cells mutate ONLY via worker-executed jobs.
- Forbidden: never write a block into the grid at commit (blueprint only); never advance construction on raw delta (game ticks only); never roll a burst's excess ticks over to the next cell.
- Guardrail: per-villager/per-job burst — each working villager completes at most one cell per frame; excess ticks are not carried over.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC20: GIVEN a blueprint cell fed `base_build_ticks` worth of tick events via a mocked on-site job, WHEN the last tick applies, THEN the Voxel World write occurs and the cell is Built (F3 — unit-testable without Villager AI). [TR-079]
- [ ] AC22: GIVEN zero tick events over an interval, WHEN progress is checked, THEN UnderConstruction progress is unchanged (reacts only to ticks). [TR-058]
- [ ] AC24: GIVEN time-warp 2x, WHEN a cell builds, THEN wall-clock halves but the tick count to complete is unchanged (F3 warp-invariance). [TR-079]
- [ ] AC25: GIVEN a tick burst of 10, WHEN the current cell needs 2 more ticks, THEN that cell completes and no further queued cell receives leftover ticks that frame (F3 burst rule). [TR-080]
- [ ] AC26: GIVEN paused, WHEN a tool commits, THEN blueprint cells are created identically to the unpaused case; construction does not advance while paused. [TR-058]
- [ ] AC43: GIVEN a mocked job-claim for a Planned cell, WHEN the claim registers, THEN the cell transitions to UnderConstruction and its state is queryable as distinct from Planned. [TR-068]
- [ ] AC45: GIVEN two villagers with claimed jobs on distinct cells of the same command, WHEN a tick burst arrives, THEN each job's progress advances independently and at most one cell completes per villager that frame (F3 per-villager burst). [TR-080]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rules 11–13 + F3, TR-052/057/058/068/069/079/080:*

- A valid commit creates **blueprint (Planned) cells** — invisible to Voxel World's data layer, not grid blocks.
- Cell lifecycle: Planned → UnderConstruction (a villager claims its job and is on site) → Built (build time elapses → this system issues the Voxel World write and retires the blueprint cell).
- F3: `cell_build_ticks = base_build_ticks[category]` (`base_build_ticks[block]` = 4, `[furniture]` = 8). Tick counts are warp-invariant. Progress advances per game tick only while a claiming villager is on site.
- Burst rule (per villager/job): the tick budget applies independently per active job; a burst applies at most enough ticks to complete the current cell; excess does NOT roll over to that villager's next cell. N villagers complete at most N cells per frame.
- Building while paused: commits/blueprints work; only construction progress waits for game time.
- Test with a mocked on-site job (AC20 pattern) — the villager claim/path/arrival mechanic is Story 030 / Villager AI.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 030: the claim/report/on-site queue pipeline + occupied-cell defer + unreachable feedback (this story consumes a mocked claim).
- Story 033: the batched Voxel World write API usage (this story issues the write; 033 owns batching/signal contract).
- Story 002: the project-state rollup (this story drives cell micro-states the rollup reads).

---

## QA Test Cases

**AC20 — cell completes on tick budget (mocked)**
- Given: a Planned cell with a mocked on-site claim, fed `base_build_ticks` tick events.
- When: the last tick applies.
- Then: the Voxel World write occurs and the cell is Built.
- Edge cases: fewer ticks leaves it UnderConstruction.

**AC22 / AC26 — ticks only, paused halts**
- Given: zero tick events / paused game.
- When: time passes.
- Then: UnderConstruction progress unchanged; commits still create blueprints while paused.

**AC24 — warp invariance**
- Given: warp 2x.
- When: a cell builds.
- Then: wall-clock halves, tick count unchanged.

**AC25 / AC45 — burst rule**
- Given: a burst of 10 ticks; current cell needs 2 more; two villagers on distinct cells.
- When: the burst applies.
- Then: each villager completes at most one cell that frame; excess ticks do not roll over.

**AC43 — Planned→UnderConstruction distinct**
- Given: a mocked claim on a Planned cell.
- When: it registers.
- Then: the cell is UnderConstruction, queryable as distinct from Planned.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/construction_tick_loop_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 021 (blueprint creation), Time & Tick System (tick events) — Foundation.
- Unlocks: Story 030 (job queue), Story 002 (project rollup), the slice release/build lifecycle.
