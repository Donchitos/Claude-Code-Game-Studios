# Story 012: Floor excavation flush-replace + restore_value

> **Epic**: Building System
> **Status: Complete (2026-07-27 — 1418/1418 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-120` (secondary: `TR-voxel-world-050`)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: `restore_value` is carried on the project entity and written back for demolished floor-replace cells, never left empty; captured at commit as a snapshot and restored on cancel/undo/demolish.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: The terrain read/replace uses Voxel World's write API (TR-voxel-world-050 owns the flush-replace + restore_value on the data side). `restore_value` is a snapshot captured at replacement, never a live re-query.

**Control Manifest Rules (this layer — Core)**:
- Required: floor excavation replaces the terrain cell flush; the original terrain value is captured as `restore_value` on the project entity and restored on cancel, undo, or demolition — never left empty; `restore_value` is included in `serialize()`.
- Forbidden: never remove terrain outside a job/tracked path; never leave a demolished/undone floor-replace cell empty; never re-derive terrain state on restore (snapshot only).
- Guardrail: `restore_value` is a small per-cell value on the project entity — negligible memory.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC69: GIVEN a floor-tool drag started on a terrain top surface, WHEN committed, THEN the terrain cell is replaced flush (not stacked into a step) and its original value is captured as `restore_value` on the blueprint entry (Rule 14l). [TR-120]
- [ ] AC70: GIVEN such an entry is later canceled, undone while still pending, or demolished, WHEN resolved, THEN the captured `restore_value` is written back in place of the cell — never left empty (Rule 14l, Edge Case 18). [TR-120]
- [ ] Edge 18: `restore_value` writes back exactly the value captured at replacement, not a re-derived "current" terrain state — restoration is a snapshot, never a live query. [TR-120]

---

## Implementation Notes

*Derived from ADR-0016 Decision §1/§7 + building-system Rule 14l, TR-120; TR-voxel-world-050:*

- A floor-tool drag that starts on a terrain top surface replaces the terrain cell **flush** (Stonehearth-style) rather than stacking a floor cell on top of it (which would create an unwanted step).
- Because Core Rule 15 forbids terrain removal outside a job, this is a narrow, tracked exception: capture the original terrain cell's value as `restore_value` on the blueprint entry **at commit** — a snapshot, never a live query.
- Restoration paths — all write back the captured `restore_value` instead of leaving the cell empty:
  - Cancel (Draft): Story 015 removal-tool Draft branch / Story 010 Abriss.
  - Undo (still-pending): Story 011.
  - Demolition (Built): Story 009's completion writeback.
- Carry `restore_value` on the project entity and include it in `serialize()` (Story 002's entity is extended here).
- The Voxel World data-side flush-replace + restore is TR-voxel-world-050 (Voxel World epic) — coordinate the write API; this story owns the Building-System capture/tracking/writeback orchestration.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Voxel World's data-layer flush-replace primitive (TR-voxel-world-050) — Voxel World epic.
- The generic floor tool drag/preview/commit pipeline — pre-slice foundation (this story adds the terrain-start branch + restore tracking).
- Dig-order terrain removal (Story 013) — a different terrain-removal path.

---

## QA Test Cases

**AC69 — flush replace + capture**
- Given: a floor-tool drag whose start cell is a terrain top surface.
- When: committed.
- Then: the terrain cell is replaced flush (no step) and its original value is captured as `restore_value` on the blueprint entry.
- Edge cases: a floor drag starting on a built floor (not terrain) does NOT capture `restore_value` (normal stacking); only the terrain-start branch excavates.

**AC70 / Edge 18 — snapshot restore on all three paths**
- Given: a floor-excavation entry with captured `restore_value`.
- When: it is (a) canceled while Draft, (b) undone while still pending, (c) demolished after Built.
- Then: in every case the captured `restore_value` is written back — never an empty cell.
- Edge cases: restore writes the value captured at replacement, not a re-derived current terrain value (verify with a divergent mocked "current" terrain state).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/floor_excavation_restore_value_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (project entity, extended with `restore_value`), Story 009 (demolition writeback), Story 011 (undo restore). Coordinates with Voxel World TR-voxel-world-050.
- Unlocks: safe, reversible floor-over-terrain building.
