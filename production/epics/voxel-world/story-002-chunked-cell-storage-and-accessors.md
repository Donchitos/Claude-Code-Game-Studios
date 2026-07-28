# Story 002: Chunked packed-array storage + O(1) accessors + single-cell change signal

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-23 — 180/180 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-003`, `TR-voxel-world-007`, `TR-voxel-world-031`, `TR-voxel-world-032`, `TR-voxel-world-041`, `TR-voxel-world-045`, `TR-voxel-world-047`, `TR-voxel-world-033`, `TR-voxel-world-019`, `TR-voxel-world-028`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014 (Chunked Voxel Rendering & Large-World Storage) — primary; ADR-0001 secondary
**ADR Decision Summary**: Bulk cell storage is chunked packed arrays (~1–4 B/cell) behind an UNCHANGED public accessor API (O(1) `get`/`set` by `Vector3i`, `cell_changed`, `raycast_cells`). GridMap is forbidden for blocks.

**Engine**: Godot 4.7-stable | **Risk**: HIGH
**Engine Notes**: Bulk storage must be packed arrays, NOT a `Dictionary[Vector3i,...]` (measured ~500 B/cell, >16 GB at scale). Chunk = 16×16 column. Block-type/material ids are opaque values — never resolve them against Resource & Item Database (no runtime dependency either direction).

**Control Manifest Rules (this layer)**:
- Required: chunked packed-array storage behind the O(1) accessor API; committed geometry is authoritative Voxel World data.
- Forbidden: never `GridMap` for committed-block storage; never `Dictionary` for bulk cell storage.
- Guardrail: a single read/write is O(1) relative to grid size; reads never mutate.

---

## Acceptance Criteria

- [ ] Every cell holds exactly one of: empty, or a block record (block-type id + material id); no layering (AC2 read correctness). [TR-voxel-world-003]
- [ ] `get_cell` returns the occupant matching the last write to that cell (AC2). [TR-voxel-world-031]
- [ ] `set_cell`/`clear_cell` low-level write API exists; placement validity/undo are NOT this layer's concern. [TR-voxel-world-007]
- [ ] A single cell write emits exactly one `cell_changed` signal identifying the cell and its before/after contents (AC6). [TR-voxel-world-032]
- [ ] Writing to an already-occupied cell overwrites and returns the previous contents (AC8). [TR-voxel-world-045]
- [ ] Repeated read/raycast queries never mutate grid state (AC13). [TR-voxel-world-047]
- [ ] Terrain-origin and player-placed cells with identical block-type/material read indistinguishably — no hidden origin flag (AC9). [TR-voxel-world-030]

---

## Implementation Notes

*Derived from ADR-0014:*

- Storage = chunked packed arrays keyed by chunk coordinate; each chunk holds a flat `PackedByteArray`-class buffer indexed by local offset. `get_cell`/`set_cell` translate `Vector3i` → (chunk, local offset) in O(1).
- Mutations are serialized one at a time (Mutating state is brief; no concurrent writes) — a `get_cell`/`set_cell` never observes a torn state.
- `set_cell` returns the previous occupant. Emit `cell_changed(cell, before, after)` exactly once per single write.
- Store ids as opaque integers/values; never call into Resource & Item Database.

---

## Out of Scope

- Story 003: bulk/batched writes and the batched signal.
- Story 004: neighbor lookup and DDA raycast.
- Story 010: paging chunks to region files (this story keeps all touched chunks resident in memory).

---

## QA Test Cases

- **AC-1 (write/read/overwrite)**: [TR-voxel-world-031, -045]
  - Given: an empty grid
  - When: `set_cell(c, block_A)` then `get_cell(c)`; then `set_cell(c, block_B)`
  - Then: first get returns block_A; second set returns block_A as previous contents and get returns block_B
  - Edge cases: `clear_cell` on an occupied cell returns prior contents and leaves empty
- **AC-2 (single signal)**: [TR-voxel-world-032]
  - Given: a listener on `cell_changed`
  - When: one `set_cell`
  - Then: exactly one emission carrying (cell, before, after)
- **AC-3 (read purity)**: [TR-voxel-world-047]
  - Given: a populated grid
  - When: 10,000 repeated `get_cell` calls
  - Then: grid contents unchanged (snapshot equality before/after)
- **AC-4 (indistinguishable origin)**: [TR-voxel-world-030]
  - Given: a terrain-written cell and a player-written cell with identical id/material
  - When: read via `get_cell`
  - Then: results are byte-identical — no origin discriminator

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/voxel_world/chunked_cell_storage_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (config + coordinate math)
- Unlocks: Story 003, Story 004, Story 005, Story 006, Story 007, Story 010
