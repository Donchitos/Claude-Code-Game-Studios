# Story 025: Floor tool — drag→rectangle fill (F2)

> **Epic**: Building System
> **Status: Complete (2026-07-25 — 881/881 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-25

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-045`, `TR-building-system-078`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: A valid commit creates blueprint cells grouped into a project; the floor tool fills a one-cell-thick rectangle on the locked plane.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: No post-cutoff APIs. The floor-over-terrain flush-replace + `restore_value` capture is the slice story 012 (not here — this story is the base rectangle fill on the locked plane).

**Control Manifest Rules (this layer — Core):**
- Required: deterministic rectangle fill on the locked plane; blueprint cells only; bounded by `max_cells_per_command`.
- Forbidden: never write grid blocks on commit (blueprint cells only).
- Guardrail: floor cell count bounded by the cap (larger floors take multiple drags).

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC7: GIVEN a floor drag of 3 cells in x and 4 in z, WHEN committed, THEN exactly 20 blueprint cells exist (F2). [TR-078]
- [ ] A floor drag defines a rectangle on the picked plane; commit fills it one cell thick with the selected material. [TR-045]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 5 + F2, TR-045/078:*

- F2: `floor_cell_count = (|dx| + 1) × (|dz| + 1)` — a 1-cell-thick rectangle on the locked plane. Zero-length drag degenerates to a single 1×1 tile.
- The practical maximum is `max_cells_per_command` (512, Story 022); the world grid dimensions only bound the preview clamp (Edge 1, Story 021).
- Emit the cell set to the commit pipeline (Story 021) as blueprint cells on the plane locked at drag start (Story 020).
- Floor-over-terrain flush-replace + `restore_value` is Story 012 (slice) — this story handles the base rectangle fill only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: floor excavation flush-replace + restore_value (the terrain-start branch).
- Story 021/022/023: pipeline, validity, rendering.

---

## QA Test Cases

**AC7 — F2 cell count**
- Given: a floor drag of 3 cells in x and 4 in z.
- When: committed.
- Then: exactly 20 blueprint cells (4 × 5).
- Edge cases: a zero-length drag yields a single 1×1 tile; a drag exceeding the cap is rejected (Story 022).

**One-cell-thick on locked plane**
- Given: a floor drag on a plane at y > 0.
- When: committed.
- Then: all cells lie one-thick on that plane, never stacked or on the ground plane.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/floor_tool_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 021 (commit pipeline), Story 020 (pick/plane), Story 022 (validity + cap).
- Unlocks: the floor verb; Story 012 (floor excavation extends this).
