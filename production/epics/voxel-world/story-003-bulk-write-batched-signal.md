# Story 003: Bulk write + single batched signal with per-cell before/after

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-23 — 215/215 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-042`, `TR-voxel-world-043`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 — primary
**ADR Decision Summary**: A bulk write emits ONE batched change signal, never one per cell; the batched payload AND the API return value carry the per-cell previous contents for every affected cell.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: Per-cell signals on a bulk write would thrash listeners and the Building System undo stack. The batched signal must be a single emission.

**Control Manifest Rules (this layer)**:
- Required: `bulk_write` emits exactly one batched signal; batched payload carries per-cell before/after for lossless undo.
- Forbidden: one signal per cell on a bulk operation.
- Guardrail: the batched write is the single write path (later extended by load-before-write, Story 014).

---

## Acceptance Criteria

- [ ] A bulk write affecting N cells emits exactly ONE batched change signal (AC7). [TR-voxel-world-042]
- [ ] The batched signal payload AND the `bulk_write` return value carry the before/after contents for ALL N affected cells — per-cell granularity inside the single signal (AC18). [TR-voxel-world-043]

---

## Implementation Notes

*Derived from ADR-0014:*

- `bulk_write(changes)` applies all cells under the serialized-mutation guarantee, collecting per-cell `(cell, before, after)`, then emits one `cells_changed_batch` signal with the full per-cell array. Return the same per-cell array so Building System's undo can restore each cell individually.
- Reuse the single-write mechanism internally but suppress per-cell `cell_changed` emissions during the batch; emit only the batched signal at the end.

---

## Out of Scope

- Story 006: terrain generation's use of the batched signal at boot.
- Story 007/008/009: floor-replace and dig-order write records built on top of this path.

---

## QA Test Cases

- **AC-1 (one batched signal)**: [TR-voxel-world-042]
  - Given: a listener on `cells_changed_batch` and on `cell_changed`
  - When: `bulk_write` of 50 cells
  - Then: `cells_changed_batch` fires exactly once; `cell_changed` fires zero times
- **AC-2 (per-cell before/after)**: [TR-voxel-world-043]
  - Given: a grid where 20 of 50 target cells were already occupied
  - When: `bulk_write` runs
  - Then: the payload and return value each contain 50 records; the 20 pre-occupied cells report their true previous contents
  - Edge cases: bulk write of 1 cell still uses the batched path; empty change list emits nothing

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/voxel_world/bulk_write_batched_signal_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (storage + single-cell write)
- Unlocks: Story 006, Story 007, Story 008, Story 009, Story 014
