# Story 006: Procedural terrain generation + single batched gen signal

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-24 — 319/319 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-029`, `TR-voxel-world-038`, `TR-voxel-world-039`, `TR-voxel-world-046`, `TR-voxel-world-044`, `TR-voxel-world-026`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (config) — primary; ADR-0014 (chunked storage) secondary
**ADR Decision Summary**: Terrain height is `h(x,z) = clamp(round(base_height + amplitude*noise2D(x*frequency, z*frequency)), min_y, max_y)`; tunables from config. Generation writes into the same chunked grid as player blocks and emits at most one batched signal.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `noise2D` must be deterministic and seeded (FastNoiseLite with a fixed seed). Terrain generation runs synchronously before the first visible scene; at 2000×2000×32 the initial view-window mesh build (~2.6 s, Story 007/015) runs behind Scene/World Management's transition overlay.

**Control Manifest Rules (this layer)**:
- Required: terrain-gen tunables from config; generation emits at most ONE batched signal (or none if listeners attach after Generated).
- Forbidden: per-cell signals at boot (a valley floor is tens of thousands of cells).
- Guardrail: `base_height > max_y` misconfiguration clamps flat at `max_y` with a warning, no crash.

---

## Acceptance Criteria

- [ ] At world generation every cell within bounds holds either a terrain block or empty, and the system transitions Uninitialized → Generated (AC1). [TR-voxel-world-029]
- [ ] Terrain height output is always within `[min_y, max_y]` for any (x,z) (AC10). [TR-voxel-world-038, -039]
- [ ] `base_height > max_y` clamps flat at `max_y`, no crash, warning logged (AC11). [TR-voxel-world-046]
- [ ] Terrain generation emits at most ONE batched change signal — never per-cell (AC19). [TR-voxel-world-044]

---

## Implementation Notes

*Derived from ADR-0002 / ADR-0014:*

- Read `base_height`, `amplitude`, `frequency`, `min_y`, `max_y`, `world_width_cells`, `world_depth_cells` from `VoxelWorldConfig` (Story 001). Seed the noise deterministically.
- Fill terrain via the batched write path (Story 003) so at most one batched signal is emitted; alternatively populate before any listener attaches (Generated-state entry) and emit none.
- On `base_height > max_y`, `push_warning` and let the `clamp` in the height formula flatten to `max_y` — the designer must notice the tuning mistake.
- Terrain cells are stored identically to player cells (no origin flag — Story 002 AC).

---

## Out of Scope

- Story 007/015: meshing/streaming the generated terrain.
- Story 009: removing terrain via dig orders.

---

## QA Test Cases

- **AC-1 (height bounds)**: [TR-voxel-world-038]
  - Given: config `base_height=4, amplitude=3, frequency=0.05, min_y=0, max_y=16`
  - When: height evaluated across the whole (x,z) extent
  - Then: every result ∈ [0,16]; deterministic across runs with the fixed seed
  - Edge cases: `noise2D` returning ±1 stays within clamp
- **AC-2 (misconfig clamp)**: [TR-voxel-world-046]
  - Given: `base_height=20, max_y=16`
  - When: terrain generates
  - Then: all terrain clamps flat at 16, no crash, exactly one warning logged
- **AC-3 (single batched gen signal)**: [TR-voxel-world-044]
  - Given: a listener attached before generation
  - When: terrain generates over a 64×64 test extent
  - Then: at most one `cells_changed_batch` emission observed; zero `cell_changed`
- **AC-4 (state transition)**: [TR-voxel-world-029]
  - Given: an Uninitialized grid
  - When: generation completes
  - Then: state == Generated; every in-bounds cell is terrain-or-empty

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/voxel_world/procedural_terrain_generation_test.gd` — must exist and pass
**Status**: [x] Created — 8 test functions, full suite green (see `/dev-story` implementation summary)

---

## Dependencies

- Depends on: Story 001 (config), Story 002 (storage), Story 003 (batched write)
- Unlocks: Story 007 (mesher has geometry to mesh), Story 011 (async terrain-gen for far regions)
