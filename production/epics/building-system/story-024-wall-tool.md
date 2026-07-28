# Story 024: Wall tool — drag→line rasterization + wall-height extrude (F1)

> **Epic**: Building System
> **Status: Complete (2026-07-25 — 871/871 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-044`, `TR-building-system-077`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0002 (Tuning/Config Data Strategy) — secondary
**ADR Decision Summary**: A valid commit creates blueprint cells grouped into a project; tunables (`wall_height`) come from a typed `.tres` config on the injected-tier module.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Bresenham-style stepping for diagonals — equal displacements always yield equal cell counts. `wall_height` clamped at the input layer (UI stepper 1–8, default 3), not re-clamped in F1.

**Control Manifest Rules (this layer — Core):**
- Required: gameplay values are data-driven — `wall_height` from typed `.tres` config (ADR-0002), never hardcoded; deterministic rasterization (equal displacements → equal cell counts).
- Forbidden: never write config fields at runtime; never build walls layer-by-layer (one-action full-height objects).
- Guardrail: wall cell count bounded by `max_cells_per_command` (Story 022 cap).

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC5: GIVEN a 5-cell wall drag at `wall_height` 3, WHEN committed, THEN exactly 15 blueprint cells exist (F1). [TR-077]
- [ ] AC6b: GIVEN a drag where `cursor_travel_px >= drag_threshold_px` but `start_cell == end_cell`, WHEN committed, THEN exactly 1 column of `wall_height` cells is created via the Dragging path (F1 degenerate). [TR-077]
- [ ] A wall drag defines a line segment; on commit it extrudes upright to `wall_height` in one action (never layer-by-layer). [TR-044]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 4 + F1, TR-044/077:*

- F1: `wall_cell_count = line_length(start_cell, end_cell) × wall_height`. Rasterize the dragged segment into a deterministic run of cells on the locked working plane (Bresenham stepping for diagonals — equal displacements yield equal counts); each run cell extrudes `wall_height` cells upward from the picked surface.
- `start == end` degenerates to a single column of `wall_height` cells (AC6b — a distinct code path from the click path AC6).
- Walls are one-action full-height objects — never layer-by-layer slabs.
- `wall_height` (default 3, range 1–8) is read from the module's typed `.tres` config; the UI stepper clamps it (not F1). Emit the cell-set to the commit pipeline (Story 021) as blueprint cells.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 021: click-vs-drag discrimination + blueprint creation trigger (this story supplies the cell set).
- Story 023: rendering the wall ghost.
- Building UI's wall-height stepper widget — building-ui epic (this story reads the config value).

---

## QA Test Cases

**AC5 — F1 cell count**
- Given: a 5-cell wall drag at `wall_height` 3.
- When: committed.
- Then: exactly 15 blueprint cells exist.
- Edge cases: a diagonal drag of equal displacement yields the same run length as an axis-aligned one; `wall_height` 1 yields `line_length` cells.

**AC6b — degenerate drag = single column**
- Given: `cursor_travel_px >= drag_threshold_px` but `start_cell == end_cell`.
- When: committed via the Dragging path.
- Then: exactly 1 column of `wall_height` cells (distinct path from the click path AC6).

**One-action full height**
- Given: a wall commit.
- When: cells are created.
- Then: the full height extrudes in one command (one undo step), never per-layer.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/wall_tool_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 021 (commit pipeline), Story 020 (pick/plane), Story 022 (validity + cap).
- Unlocks: the wall verb; feeds grouping (Story 003) and construction (Story 029).
