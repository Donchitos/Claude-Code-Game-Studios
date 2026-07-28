# Story 001: Grid config + coordinate math + bounds

> **Epic**: Voxel World / Grid Data
> **Status: Complete (2026-07-23 — 112/112 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story)

## Context

**GDD**: `design/gdd/voxel-world.md`
**Requirement**: `TR-voxel-world-016`, `TR-voxel-world-027`, `TR-voxel-world-035`, `TR-voxel-world-036`, `TR-voxel-world-037`, `TR-voxel-world-012`, `TR-voxel-world-023`, `TR-voxel-world-040`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy) — primary; ADR-0001 (DI/reference pattern) secondary
**ADR Decision Summary**: One `Resource`-derived config class per module with typed `@export` fields (one per Tuning Knob), stored as `.tres`; `validate() -> Array[String]` called once at boot; injected-tier module wired in `GameWorld.tscn`.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `Vector3i` hashes with value-equality and computes with exact integer arithmetic — bounds checks are exact non-negative comparisons, never epsilon. Use Godot 4.4+ typed `Dictionary[Vector3i, ...]` only for small lookup tables, never bulk cell storage. `floor()` (not truncation) for World→Cell so near-zero positions map cleanly out-of-bounds.

**Control Manifest Rules (this layer)**:
- Required: config = one custom `Resource` class, typed `@export`, `.tres` text file; injected modules get config as an `@export`; every config class exposes `validate() -> Array[String]` called in `setup()`.
- Forbidden: never `ConfigFile`/JSON for tuning; never write a config field at runtime; no hardcoded tuning literals.
- Guardrail: config loads once at boot.

---

## Acceptance Criteria

*From GDD `design/gdd/voxel-world.md`, scoped to this story:*

- [ ] The world is a bounded 3D `Vector3i`-addressed grid with min/max extent set at generation; origin fixed at (0,0,0), no negative cell coordinates exist (AC4). [TR-voxel-world-016, -027]
- [ ] Cell→World returns the cell **center**: `Vector3(cell) * cell_size + Vector3(0.5,0.5,0.5) * cell_size` (AC5). [TR-voxel-world-035]
- [ ] World→Cell uses `floor()` per axis (AC4). [TR-voxel-world-036]
- [ ] A query/write for a cell outside bounds returns an explicit "outside grid" result — never a silent clamp or crash (AC3). [TR-voxel-world-037]
- [ ] `cell_size` is fixed at `1.0`. [TR-voxel-world-012]
- [ ] World bounds, `base_height`, `amplitude`, `frequency` are read from config, not literals (AC17). [TR-voxel-world-023]

---

## Implementation Notes

*Derived from ADR-0002 / ADR-0001:*

- Create `VoxelWorldConfig extends Resource` with typed `@export` fields for every Tuning Knob (`world_width_cells`, `world_depth_cells`, `min_y`, `max_y`, `base_height`, `amplitude`, `frequency`) with GDD default values; `cell_size` is a `const = 1.0`, not a knob.
- `validate() -> Array[String]`: single-field range issues warn+clamp+proceed; a GDD-declared BLOCKING cross-value invariant (e.g. `min_y <= max_y`) is a terminal boot-halt (RID Failed pattern) — do not invent a new severity scheme.
- Coordinate helpers are pure functions. World→Cell result outside `[0,width) × [min_y,max_y] × [0,depth)` returns a sentinel "outside grid" value (not a clamped edge cell). The `floor()` requirement is defensive hardening for near-zero positions — Core Rule 1 still guarantees no negative cells exist.
- Module is injected-tier: config arrives as an `@export`; validation runs in `setup()`, never `_ready()`.

---

## Out of Scope

- Story 002: the actual chunked cell storage and get/set accessors.
- Story 006: procedural terrain generation using these config fields.

---

## QA Test Cases

*Embedded from GDD acceptance criteria (lean mode — qa-lead gate skipped).*

- **AC-1 (bounds/out-of-grid)**: [TR-voxel-world-037]
  - Given: a configured world of width/depth W/D
  - When: World→Cell is queried for a point at x = −0.001 and for a point at x = W+1
  - Then: both return the explicit "outside grid" sentinel, never cell 0 and never a clamped edge cell
  - Edge cases: exactly x=0.0 (in), x = W*cell_size (out), y below min_y / above max_y
- **AC-2 (cell↔world round trip)**: [TR-voxel-world-035, -036]
  - Given: cell (2,0,5), cell_size 1.0
  - When: Cell→World then World→Cell
  - Then: Cell→World = (2.5,0.5,5.5); World→Cell of any point inside that cell returns (2,0,5)
  - Edge cases: cell (0,0,0); a point on a cell boundary (floor semantics)
- **AC-3 (config validate)**: [TR-voxel-world-023]
  - Given: a config with `min_y > max_y`
  - When: `validate()` runs
  - Then: returns a blocking-invariant record (terminal halt), not a silent clamp
  - Edge cases: single-field out-of-range value warns + clamps + proceeds

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/voxel_world/grid_config_and_coordinate_math_test.gd` — must exist and pass
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (module foundation)
- Unlocks: Story 002, Story 006
