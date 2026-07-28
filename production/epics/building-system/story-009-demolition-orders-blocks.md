# Story 009: Demolition orders — block teardown job contract

> **Epic**: Building System
> **Status: Complete (2026-07-27 — 1404/1404 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-114`, `TR-building-system-115`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0009 (Deterministic Movement & Occupancy Ordering) — secondary
**ADR Decision Summary**: Demolition is job-based and uniform; demolition orders queue worker-executed jobs (one cell = one job, same on-site rules, `base_demolition_ticks` per cell). On completion this system issues the Voxel World clear; `restore_value` is written back for demolished floor-replace cells, never left empty.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW; ADR-0009 occupancy seam)
**Engine Notes**: The Voxel World clear uses the batched bulk-write API (one batched signal per frame for N simultaneous clears). Occupancy/seal reads are the discrete `current_cell`/body-column (ADR-0009), never `_visual_position`.

**Control Manifest Rules (this layer — Core)**:
- Required: built cells mutate ONLY via worker-executed jobs; demolition orders are created already released and executed block by block, taking `base_demolition_ticks` per cell; on completion issue the Voxel World clear; write back `restore_value` for demolished floor-replace cells.
- Forbidden: never mutate built cells via undo or a direct edit; never an instant removal of a Built cell; state colors never on committed materials.
- Guardrail: N cells cleared in one frame use the bulk-write API — exactly ONE batched signal, never one per cell.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC65: GIVEN a Built cell targeted by the removal tool, WHEN it fires, THEN a demolition order is created already in released/BUILDING state — no separate "Bau starten" step is needed for teardown (Rule 14j). [TR-114/115]
- [ ] AC66: GIVEN a demolition job fed `base_demolition_ticks` worth of on-site tick events via a mocked claim (mirrors AC20's mocked-job pattern), WHEN the last tick applies, THEN the Voxel World clear occurs and the cell is gone (Rule 14j). [TR-115]
- [ ] Edge 17: a second demolition request on an already-queued demolition cell is a no-op — exactly one demolition job exists per cell, never a duplicate. [TR-114]
- [ ] On a demolished floor-excavation cell, the terrain `restore_value` is written back instead of leaving an empty cell. [TR-115]

---

## Implementation Notes

*Derived from ADR-0016 Decision §1 + building-system Rules 14j, TR-114/115; F3 demolition addendum:*

- A demolition order is created **already released** — no staging step (tearing down needs no blueprint to reconsider). It is executed by villagers block by block, mirroring the construction job contract in reverse: one cell = one job; on-site rules per Rule 12 unchanged; `cell_demolition_ticks = base_demolition_ticks[category]`, same burst rule and warp-invariance as F3. (`base_demolition_ticks[block]` default 4 — an `[assumption]`, tune later.)
- Once a cell's demolition completes, issue the Voxel World clear (bulk-write API). If the cell was a floor-excavation replacement of terrain (Story 012), write the original terrain's `restore_value` back instead of leaving an empty cell.
- Duplicate guard (Edge 17): a second demolition request on an already-queued demolition cell is a no-op (mirrors Core Rule 3's "already holds a blueprint cell" invalid-commit rule applied to the demolition queue).
- Test the tick loop with a mocked on-site claim (AC20 pattern) — the real villager claim/on-site mechanic is Villager AI's; occupancy/seal reads use the discrete `current_cell` per ADR-0009.
- This story handles BLOCK demolition. Furniture demolition (job-gated, atomic multi-cell, revocation timing) is Story 017; Abriss (project-wide) is Story 010.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 010: project-wide cancel/Abriss (converts a whole project).
- Story 012: capturing `restore_value` at floor-excavation commit (this story consumes it on demolish).
- Story 015: the removal-tool micro-state branch that DECIDES Built→demolition vs Draft→instant-cancel (this story implements the Built branch's order).
- Story 017: furniture demolition (job-gated, atomic footprint, revocation event).

---

## QA Test Cases

**AC65 — demolition order created already released**
- Given: a Built cell.
- When: the removal tool targets it.
- Then: a demolition order exists in released/BUILDING state; the cell is NOT cleared yet; no "Bau starten" is required.
- Edge cases: the source project is not deleted while the cell awaits demolition.

**AC66 — demolition completes on tick budget (mocked claim)**
- Given: a demolition job fed `base_demolition_ticks` on-site tick events (mocked claim).
- When: the last tick applies.
- Then: the Voxel World clear occurs (via bulk-write) and the cell is gone.
- Edge cases: fewer than `base_demolition_ticks` leaves the cell standing; warp changes wall-clock but not tick count; a floor-excavation cell writes back `restore_value` instead of empty.

**Edge 17 — duplicate demolition is a no-op**
- Given: a Built cell already having a queued demolition order.
- When: a second removal (or Abriss) targets the same cell.
- Then: no duplicate job is created — exactly one demolition job per cell.

**Batching**
- Given: N demolition completions in one frame.
- When: the clears issue.
- Then: one batched Voxel World signal fires, not N.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/building_system/demolition_orders_blocks_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (project entity + built-cell model).
- Unlocks: Story 010 (Abriss), Story 012 (floor-excavation restore on demolish), Story 015 (removal-tool branch), Story 017 (furniture demolition reuses this contract).
