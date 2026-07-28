# Story 008: Floor terrain-replace write path (restore_value)

> **Epic**: Voxel World / Grid Data
> **Status**: Ready
> **Layer**: Core (write path)
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-050`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 (Voxel World write path) — primary; ADR-0016 (Build-Project Entity Lifecycle) secondary
**ADR Decision Summary**: A floor blueprint placed on a terrain top-surface cell replaces that terrain cell flush with the floor block (never stacked, never left empty/AIR); the write record stores the terrain cell's original value as `restore_value` so a later undo/cancel/demolition restores it exactly. Building System decides WHEN this applies; Voxel World owns the mechanical exchange and its signal.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Slice-validated exception to terrain permanence (Core Rule 7). Routes through the SAME batched write API — no new API surface.

**Control Manifest Rules (this layer)**:
- Required: `restore_value` is written back for demolished/undone floor-replace cells, never left empty; built cells mutate ONLY via worker-executed jobs (ADR-0016) — the reversal is a job/undo, not a direct edit.
- Forbidden: leaving the cell empty/AIR as a side effect of the exchange; a separate dig/replace API surface.
- Guardrail: reversibility is lossless via the stored `restore_value`.

---

## Acceptance Criteria

- [ ] A floor blueprint placed starting on a terrain top-surface cell replaces that terrain cell flush with the floor block; the write record stores the original terrain value as `restore_value`; no empty/AIR gap is created (AC20). [TR-voxel-world-050]
- [ ] When a floor built via terrain-replace is later undone, cancelled, or demolished, the stored `restore_value` replaces the floor block, restoring the original terrain exactly — never left empty (AC21). [TR-voxel-world-050]

---

## Implementation Notes

*Derived from ADR-0014 / ADR-0016:*

- Extend the batched write path (Story 003) so a floor-replace write captures the pre-existing terrain occupant as `restore_value` on the write record (the per-cell before-state already carried in the batched payload is the natural home for this).
- The reverse operation (undo/cancel/demolition) writes `restore_value` back through the same batched path, emitting the standard change signal. Never write AIR as an intermediate.
- Voxel World owns only the mechanical exchange + signal; Building System decides which cells are floor-replace-eligible.

---

## Out of Scope

- Building System's decision logic for which floor blueprints trigger a replace (later epic).
- Story 009: dig-order removal (a different terrain-removal exception).

---

## QA Test Cases

- **AC-1 (replace + restore_value capture)**: [TR-voxel-world-050]
  - Given: a terrain top-surface cell holding terrain value T
  - When: a floor-replace write places floor value F on that cell
  - Then: the cell holds F; the write record's `restore_value` == T; the cell is never empty at any observable point
  - Edge cases: replacing a cell that is already empty (no terrain) — no `restore_value` needed / empty semantics
- **AC-2 (lossless reverse)**: [TR-voxel-world-050]
  - Given: a floor-replace cell (floor F, restore_value T)
  - When: the floor is undone / cancelled / demolished
  - Then: the cell holds T exactly; standard change signal fires; the cell is never left empty
  - Edge cases: repeated place→revert→place cycles preserve T

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/voxel_world/floor_terrain_replace_test.gd` OR documented playtest — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (batched write + per-cell before/after)
- Unlocks: Building System floor tool + demolition (later epic)
