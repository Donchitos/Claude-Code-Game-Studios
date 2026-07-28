# Voxel World / Grid Data System

> **Status**: Approved (2026-07-10 — full review APPROVED-with-patches, applied; see design/gdd/reviews/voxel-world-review-log.md)
> **Author**: user + Claude Code Game Studios agents
> **Last Updated**: 2026-07-23
> **Last Verified**: 2026-07-09
> **Implements Pillar**: None directly — Foundation infrastructure for Pillar 1 (The building IS the game)
> **Slice Revision (2026-07-23)**: user-confirmed vertical-slice findings applied
> — terrain-removal exceptions (floor terrain-replace, terrain dig orders),
> a mesher winding/culling hard requirement, and a 16k world-size scope note.
> Source: `prototypes/last-seal-vertical-slice/REPORT.md`. All touched
> passages are marked "(Slice revision 2026-07-23)" inline.

## Summary

Voxel World / Grid Data System is the single source of truth for the
block-level composition of the entire game world — both the procedurally
generated valley terrain (ground, hills) and every player-placed building
block, sharing one bounded grid data structure. It owns not just storage but
every read query other systems need (what block is at a cell, raycast
picking, neighbor lookups), so Building System, Villager AI, and every other
consumer query through one consistent interface instead of reinventing grid
logic.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Voxel World is the foundational data layer that represents the game world as
a bounded 3D grid of typed cells. At world creation, the valley's terrain —
its ground, hills, and natural shape — is procedurally generated and written
into this same grid; from that point on, every block the player places
(walls, floors, roofs, fixtures) lives in the identical data structure,
addressed the same way. The world has a finite extent (a "hand-shaped
valley," not an infinite/streaming terrain) even though its specific shape is
generated rather than hand-authored. This system owns two responsibilities:
(1) storing which cell holds which block type/material, and (2) answering
every read query about that data — "what's at this cell," "what does this
ray hit first," "what are this cell's neighbors" — so every other system
(Building, Villager AI, Combat) queries through one consistent interface
rather than each implementing its own grid logic. It does NOT decide what's
allowed to be placed, when placement is valid, or how a cell's content
renders — those are the Building System's and the (not-yet-decided)
rendering ADR's concerns respectively.

## Player Fantasy

The player never perceives Voxel World as a system in its own right — they
only feel its effects through the Building System (does building feel
structured and consistent?) and through the valley feeling like a real,
"hand-shaped" place rather than a flat plane. Success means the grid never
leaks into player awareness — no visible seams between terrain and
player-placed blocks, no inconsistency in how picking/placement behaves
across different parts of the world.

*(`creative-director` not consulted — Lean mode skips non-high-risk sections.)*

## Detailed Design

*(`systems-designer` / `godot-specialist` not consulted — Lean mode skips
non-high-risk sections. Review manually before production.)*

### Core Rules

1. The world is represented as a bounded 3D grid of cells, addressed by
   integer coordinates (`Vector3i`), with a minimum and maximum extent set at
   world generation. [TR-voxel-world-016] **The grid origin is fixed at (0,0,0) and no
   negative cell coordinates ever exist** — bounds checks are simple
   non-negative comparisons [TR-voxel-world-027] *(invariant promoted from AC4 by the
   2026-07-10 review; the Formulas section's `floor()` requirement is
   defensive hardening for near-zero world positions, not support for
   negative cells)*.
2. Every cell holds exactly one of: empty (no block), or a block record
   containing a block-type identifier and a material identifier. There is no
   "layering" — one cell = one occupant. [TR-voxel-world-003] The identifiers are ids defined by
   the Resource & Item Database; this system stores them as opaque values
   and never resolves their meaning (no runtime dependency in either
   direction — see that GDD's Interactions section). [TR-voxel-world-028]
3. At world generation, terrain cells (ground, hills) are populated
   procedurally within the bounded extent; every cell not part of generated
   terrain starts empty and is available for player building. [TR-voxel-world-029]
4. Terrain cells and player-placed cells are stored identically — there is no
   data-level flag distinguishing "natural" from "built." [TR-voxel-world-030] *(→ Open Question:
   do consuming systems need this distinction for gameplay purposes, e.g.
   "can't build directly on undisturbed terrain without clearing it first"?
   → hand off to the Building System GDD.)*
5. This system exposes a read API (get cell contents, raycast against
   occupied cells, get a cell's neighbors) [TR-voxel-world-031] and a low-level write API (set
   cell contents, clear a cell) [TR-voxel-world-007] — it does NOT expose whether a placement is
   valid, or undo of the last action; those are the Building System's
   responsibility, composed on top of these primitives.
6. Every write emits a signal identifying the changed cell and its
   before/after contents, so dependent systems (rendering, the Building
   System's undo stack, Villager AI navigation) can react without polling. [TR-voxel-world-032]
7. **Floor terrain-replace** (slice-validated exception to the terrain
   permanence described in the Open Questions resolution below): when a
   Building System floor blueprint is placed starting on a terrain top-surface
   cell, the write API replaces that terrain cell flush with the floor block
   — it does NOT stack the floor on top of or leave the terrain cell
   untouched — and the write record stores the terrain cell's original value
   as `restore_value`, so a later undo, cancel, or demolition of that floor
   restores the original terrain cell exactly. The cell must never be left
   as empty/AIR as a side effect of this exchange. [TR-voxel-world-050]
   *(Slice revision 2026-07-23)*
8. **Terrain dig orders** (slice-validated second exception): a bounded set
   of terrain block-type values — terrain bands and sand, informally "the
   1..5 value family," explicitly EXCLUDING water and EXCLUDING trunk/leaves
   values — may be fully removed (the cell becomes empty) via a released dig
   order executed by a villager. This removal goes through the SAME
   batched write API used for every other removal in this system (no special
   dig-order API surface); it emits the standard change signal so downstream
   consumers (Build Validation & Navigability, in particular) observe the
   `cells_removed` change like any other write and re-evaluate room/shelter
   analysis correctly. Values outside the 1..5 family (water, trunk, leaves)
   are not eligible for removal via a dig order. [TR-voxel-world-051]
   *(Slice revision 2026-07-23)*

### States and Transitions

*(System lifecycle, not per-cell state.)*

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|-----------------|----------|
| Uninitialized | Before terrain generation runs | Terrain generation completes | No query is valid; the grid is empty/unallocated |
| Generated | Terrain generation completes | Never (persists for the session) | Grid holds terrain; ready for player mutation and queries |
| Mutating | A write operation is in progress | Write completes | Very brief; no concurrent writes (mutations are serialized one at a time) [TR-voxel-world-033] |

### Interactions with Other Systems

- **Scene/World Management** (Foundation sibling): hosting relationship —
  this system's root lives inside the scene Scene/World Management loads
  (same pattern as that GDD's Interactions section). [TR-voxel-world-034]
- **Building System** (MVP, downstream, primary consumer): calls the write
  API to place/remove blocks, and the read API (raycast picking) to
  determine what's under the cursor. Building System owns: placement
  validity rules, drag-to-area logic, undo/redo composition, ghost-preview
  rendering. Voxel World owns: the actual data mutation and raw picking.
  *(Slice revision 2026-07-23)*: this now includes two slice-validated
  exception write paths — floor terrain-replace (Core Rule 7) and terrain
  dig-order removal (Core Rule 8) — both routed through the same write API;
  Building System still owns deciding WHEN these apply (e.g. which cells are
  dig-orderable, when a floor blueprint is release-worthy), Voxel World still
  only owns the mechanical data exchange and its signal.
- **Villager AI & Behavior** (MVP, downstream): queries the read API for
  pathfinding-relevant occupancy (which cells are solid/walkable) — does NOT
  mutate the grid.
- **Squad & Combat System / Wave Defense** (Vertical Slice, downstream):
  query occupancy for line-of-sight, cover, and collision; do not mutate the
  grid directly (whether/how a wave can destroy a wall is open — see Open
  Questions).
- **Save/Load & World Persistence** (Vertical Slice, downstream): needs to
  serialize/deserialize the grid's full cell contents. Interface: this
  system exposes an iteration API over occupied (non-empty) cells, so
  Save/Load doesn't need to know internal storage details. [TR-voxel-world-021]
- **Resource & Item Database** (Foundation sibling, shared vocabulary): the
  block-type/material identifiers stored in cells (Core Rule 2) are ids
  defined by the Resource & Item Database. This system treats them as
  opaque values and never queries that database; consumers that need
  meaning (Building System, rendering) resolve the ids there. No runtime
  dependency in either direction. [TR-voxel-world-028]
- **Build Validation & Navigability** (MVP, downstream): reads physical
  occupancy for its room/region analysis (read-only, event-driven on the
  Building System's signals) — does NOT mutate the grid.

## Formulas

*(`systems-designer` and `godot-specialist` consulted — mandatory for this
high-risk section even in Lean mode.)*

### Cell-Coordinate ↔ World-Position Conversion

`world_pos = Vector3(cell.x, cell.y, cell.z) * cell_size + Vector3(0.5, 0.5, 0.5) * cell_size` [TR-voxel-world-035]

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| cell | `cell` | Vector3i | bounded by world extent (see Tuning Knobs) | Integer cell address |
| cell_size | `cell_size` | float | fixed = `1.0` (locked, Visual Direction Note) | Edge length of one cell; blocks are flush, no gap [TR-voxel-world-012] |
| world_pos | `world_pos` | Vector3 | practically bounded by world extent × cell_size | Cell **center** point in world space |

**Output range**: unbounded by the formula itself; practically bounded because
`cell` always lies within the world's extent.
**Example**: `cell = (2, 0, 5)` → `world_pos = (2.5, 0.5, 5.5)`.

Inverse — **World → Cell**:
`cell = Vector3i(floor(world_pos.x / cell_size), floor(world_pos.y / cell_size), floor(world_pos.z / cell_size))` [TR-voxel-world-036]

Uses `floor()`, not truncation — Core Rule 1 guarantees no negative cell
coordinates exist, but truncation and `floor()` diverge for world positions
fractionally below 0.0 (e.g. a ray grazing the world edge at x = −0.001),
and `floor()` maps those cleanly to an out-of-bounds cell instead of
aliasing them into cell 0 *(reworded 2026-07-10 review — the old text
implied negative cells were possible, contradicting AC4)*. If the result
falls outside the world's
bounds, the API must return an explicit "outside grid" result, NOT silently
clamp to the edge (see Edge Cases). [TR-voxel-world-037]

### Raycast / Cell-Picking — deliberately NOT a Formula

Raycast picking is a stepping search (a DDA-style grid walk), not an
input→output value-table case. It stays at the level already set in Core
Rule 5: "raycast against occupied cells" is part of the read API's
behavioral contract. Two technically distinct implementations are possible
(native physics collision vs. a manual DDA algorithm, as the concept
prototype used) — WHICH one is used is deliberately left to the future
rendering ADR, not decided in this GDD. [TR-voxel-world-017]

### Procedural Terrain Height (`procedural_terrain_height`)

`h(x, z) = clamp(round(base_height + amplitude * noise2D(x * frequency, z * frequency)), min_y, max_y)` [TR-voxel-world-038]

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| x, z | `x, z` | int | within the world's horizontal extent | Horizontal cell coordinates |
| base_height | `base_height` | int | Tuning Knob | Valley-floor cell height |
| amplitude | `amplitude` | float | Tuning Knob, ≥ 0 | Max height variation from noise |
| frequency | `frequency` | float | Tuning Knob, > 0 | Noise scale (lower = broader hills) |
| noise2D | function | — | returns [-1, 1] | Deterministic, seeded 2D noise [TR-voxel-world-039] |
| min_y, max_y | `min_y, max_y` | int | = world's vertical bounds | Clamp range |
| h | `h` | int | `[min_y, max_y]` | Resulting terrain height at (x, z) |

**Output range**: hard-clamped to `[min_y, max_y]`.
**Example**: `base_height=4, amplitude=3, frequency=0.05, noise2D(...)=0.6` →
`h = clamp(round(4 + 1.8), 0, 16) = 6` *(bounds corrected 2026-07-10 review — the example previously showed a stale `max_y` of 15)*.

*(This defines only the height mechanism — the specific "hand-shaped valley"
silhouette is a later level-design decision via `amplitude`/`frequency` or an
added radial falloff term → see Open Questions.)*

### World Bounds Sizing — deliberately NOT a Formula

World extent is not a derived value — it's an authored choice trading scope
against memory/draw-call budget. See Tuning Knobs.

### Supporting Godot 4.7 facts

- `Vector3i` hashes correctly as a `Dictionary` key (value-equality hashing)
  and computes with exact integer arithmetic — neighbor-lookup offsets and
  bounds checks are exact comparisons, not epsilon-tolerant ones. Godot 4.4+
  typed Dictionaries (`Dictionary[Vector3i, ...]`) give static-type safety
  at negligible cost — use them [TR-voxel-world-040] *(2026-07-10 review note)*.
- Memory back-of-envelope *(revised 2026-07-11, large-world decision)*: the
  original sparse-Dictionary note assumed the old ~100×32×100 bound. At the
  new 2000×2000×32 target, Dictionary storage (~500 B/cell measured) is
  infeasible (>16 GB); storage is **chunked packed arrays** (~1–4 B/cell,
  full world ~172 MB measured in `prototypes/chunked-mesher/`) behind the
  UNCHANGED public accessor API (O(1) `get`/`set` by `Vector3i`,
  `cell_changed`, `raycast_cells`). [TR-voxel-world-041] See ADR-0014. The `Dictionary[Vector3i]`
  guidance above remains valid for small lookup tables, not bulk cell storage.
  *(Slice revision 2026-07-23)*: the 2000×2000×32 figure above (~172 MB
  packed) is now the **slice-validated baseline** — the vertical slice built
  and held 60 FPS at this scale (ADR-0014). The production target is now
  **16,000×16,000×32** (see Tuning Knobs) — an 8x linear / ~64x areal jump.
  A naive linear projection of packed-chunk storage at that scale is
  ≈11 GB of resident chunk data at boot (172 MB × ~64), roughly 3x over the
  project's 4 GB memory ceiling (`.claude/docs/technical-preferences.md`) —
  a **storage/residency problem, not a rendering problem**: draw calls are
  already decoupled from world size via the streamed view window, so this
  does not reopen the rendering/FPS question, only whether all 16k×16k×32
  cell data can stay resident at once. This gates the 16,000×16,000
  production target behind a dedicated storage/streaming spike (a successor
  to ADR-0014) that must resolve one of: paged/on-demand chunk loading,
  sparse storage for far/unvisited regions, or a reduced persisted
  footprint. Save files scale with the same ~64x factor and need the same
  resolution (see Dependencies, Save/Load row). [TR-voxel-world-053]
- Collider strategy is a rendering-ADR concern *(2026-07-10 review note)*:
  if raycast picking is implemented via physics (rather than manual DDA),
  per-cell colliders for tens of thousands of terrain cells are a known
  Jolt/scene-tree scalability trap — the ADR must decide picking mechanism
  and collider granularity together, not separately. [TR-voxel-world-018]
- **Mesher winding/culling — hard engine requirement** *(Slice revision
  2026-07-23)*: Godot 4.7's front-face convention is **clockwise (CW)**, and
  the engine expects backface culling **ENABLED** — this is an engine fact,
  not a project convention, and the mesher (wherever it is finally owned —
  see the rendering ADR) must wind generated triangles CW and ship with
  culling enabled. [TR-voxel-world-052] The vertical slice shipped **CCW
  winding + `CULL_DISABLED`** as a documented, deliberate mitigation (see
  Edge Cases) after a multi-session "missing faces" investigation — doubling
  overdraw was an accepted slice-only cost (60 FPS held with ~10x headroom on
  the 2000×2000×32 window), but the rewind to CW + culling-enabled must land
  before asset counts scale beyond slice levels, since the 2x overdraw
  headroom will not survive a large jump in scene complexity. **Lesson**:
  face-winding geometry audits must validate against the ENGINE's actual
  convention, never a self-stored or assumed convention — the slice's
  "missing faces" reports survived multiple internal audits precisely
  because those audits checked consistency with the project's own (incorrect)
  assumption, not against Godot's documented behavior.
- A single read or write must be O(1) relative to grid size (see Acceptance
  Criteria). [TR-voxel-world-019]
- Bulk-write operations (drag-to-area placement) should emit ONE batched
  signal, not one per cell — otherwise the Building System's undo stack and
  any rendering listener are thrashed (see Edge Cases). [TR-voxel-world-042]

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|-------------------|-----------|
| Query/write for a cell outside the world's bounds | The API returns an explicit "outside grid" result — it does NOT silently clamp to the edge [TR-voxel-world-037] | Prevents silent bugs at boundary cases (see Formulas) |
| A bulk write operation (e.g., dragging a wall across many cells) | Exactly ONE batched change signal is emitted, not one per cell [TR-voxel-world-042] — and the batched payload (and the bulk-write API's return value) carries the per-cell previous contents for EVERY affected cell [TR-voxel-world-043] *(added 2026-07-10 review: Building's undo stack must restore each cell individually; a batch without per-cell before-states is un-undoable)* | Prevents thrashing the Building System's undo stack and rendering listeners while keeping undo lossless |
| Terrain generation populates the initial grid | The batched-signal mandate applies here too: generation emits at most ONE batched signal (or none, if listeners attach only after the Generated state) — never one signal per terrain cell [TR-voxel-world-044] *(added 2026-07-10 review)* | A valley floor is tens of thousands of cells; per-cell signals at boot would stall the Booting state |
| Writing to an already-occupied cell (terrain or another block) | Always overwrites and returns the previous contents; whether overwriting SHOULD be allowed is the caller's (Building System's) decision [TR-voxel-world-045] | This layer stays a pure primitive, not a rules check |
| `base_height` is misconfigured above `max_y` | The entire terrain clamps flat at `max_y` (no crash, but visibly wrong) [TR-voxel-world-046] | The formula clamps correctly; the designer must notice the tuning mistake — documented as a warning |
| Read/raycast queries are called very frequently per frame (e.g., every mouse-move for hover picking) | Never mutate grid state; remain cheap (O(1)) regardless of call frequency [TR-voxel-world-047] | Hover-picking is the most frequent query pattern in the Building System |
| Save/Load iterates occupied cells while a write is in progress | Iteration only observes fully-committed cell states, never a write in progress [TR-voxel-world-048] | Mutations are serialized (see States) — no torn reads |
| *(Slice revision 2026-07-23)* A floor blueprint is placed starting on a terrain top-surface cell | The terrain cell is replaced flush with the floor block; the write record stores the terrain cell's original value as `restore_value`; the cell is never left empty/AIR [TR-voxel-world-050] | Prevents floor construction from either stacking on terrain or leaving holes; keeps the exchange reversible |
| *(Slice revision 2026-07-23)* A floor built via terrain-replace is undone, cancelled, or demolished | The stored `restore_value` replaces the floor block, restoring the original terrain cell exactly — never left empty [TR-voxel-world-050] | Terrain must never be permanently lost as a side effect of a reversed build action |
| *(Slice revision 2026-07-23)* A released dig order targets a cell whose value is water, trunk, or leaves | The cell is NOT eligible for removal via a dig order — only the terrain-band/sand "1..5 family" is removable this way [TR-voxel-world-051] | Keeps the terrain-removal exception narrow and intentional; prevents accidental removal of water bodies or trees through the dig-order path |
| *(Slice revision 2026-07-23)* A terrain dig order removes a cell that changes an enclosed room's shelter status | The standard `cells_removed`-class change signal fires exactly as it would for any other removal (Core Rule 6/8), so Build Validation & Navigability re-evaluates room/shelter analysis on the same event path | Terrain removal must not create a blind spot for room/shelter analysis just because the removed cell was terrain |
| *(Slice revision 2026-07-23)* Mesher ships with non-engine-native winding (CCW) + `CULL_DISABLED` as a mitigation | Accepted ONLY as a documented, temporary mitigation — doubles overdraw, and the rewind to Godot's native CW winding + culling-enabled must land before asset counts scale beyond vertical-slice levels [TR-voxel-world-052] | Prevents the "missing faces" failure class from recurring silently; geometry audits must check against the engine's actual convention, not a self-stored assumption |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|----------------------|
| *(none)* | This system depends on | Foundation layer — zero upstream dependencies |
| Scene/World Management | Depended on by (structural) | This system's root attaches under the scene Scene/World Management loads (hosting, not data) |
| Save/Load & World Persistence | Depended on by | Iterates occupied cells via the read API to serialize world state. *(Slice revision 2026-07-23)*: at the 16,000×16,000×32 production target, the persisted payload scales with the same ~64x areal factor as chunk storage (see Formulas Memory back-of-envelope note) — gated by the same storage/streaming spike, not yet resolved. |
| Building System | Depended on by | Primary consumer — calls the write API to place/remove blocks, the read API for picking |
| Villager AI & Behavior | Depended on by | Queries the read API for pathfinding-relevant occupancy. *(Slice revision 2026-07-23)*: a villager's completion of a released terrain dig order (Core Rule 8) is the trigger for a write to this grid, but the write call itself is still made through the Building System's order-execution path, not directly by Villager AI — see Core Rule 8 and the Building System row above. |
| Squad & Combat System | Depended on by (Vertical Slice) | Queries occupancy for line-of-sight/collision |
| Wave Defense | Depended on by (Vertical Slice) | Queries occupancy; may need to mutate the grid if waves can destroy blocks (see Open Questions) |
| Build Validation & Navigability | Depended on by | Reads physical occupancy for room/region analysis — read-only, event-driven (added 2026-07-10, cross-review bidirectional fix) |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|---------------|------------|---------------------|---------------------|
| `world_width_cells` | 2000 *(large-world decision 2026-07-11; slice-validated 2026-07-23 — held 60 FPS in the vertical slice's view window, ADR-0014)*. **Production target: 16,000** *(Slice revision 2026-07-23 — gated on a storage/streaming spike, see Formulas Memory back-of-envelope note and Open Questions; NOT yet safe to set beyond the validated range below)* | 256–2048 validated; up to 16,000 is the target but UNVALIDATED pending the storage/streaming spike | Larger world, more room to explore; longer initial window build; beyond 2048, resident chunk memory is the binding constraint, not FPS | Smaller world, faster full mesh; loses the expedition feel |
| `world_depth_cells` | 2000 *(same)*. **Production target: 16,000** *(same gating as width — Slice revision 2026-07-23)* | 256–2048 validated; up to 16,000 is the target but UNVALIDATED | Same as width | Same as width |
| `min_y` | 0 | fixed at 0 (recommended) | Shifts all coordinates, rarely useful | — |
| `max_y` | 16 | 8–32 | Taller hills/multi-story buildings possible; more vertical cells to store | Flatter valley, less room for tall structures |
| `base_height` | 4 | 0 to max_y−1 | Higher valley floor overall | Lower valley floor, deeper basin feel |
| `amplitude` | 3 | 0–8 | More dramatic hills; risk of terrain interfering with flat buildable areas | Flatter, gentler terrain; risk of feeling featureless |
| `frequency` | 0.05 | 0.01–0.2 | More, smaller hills (busier terrain) | Broader, smoother hills |

*(All values are provisional starting points — final size/performance limits
depend on the still-open performance spike before Vertical Slice, see Open
Questions.)*

*(Slice revision 2026-07-23)*: the performance spike referenced above is now
PARTIALLY resolved — the 2000×2000×32 window is built and 60-FPS-validated
(vertical slice, ADR-0014). What remains open is the 2000 → 16,000 jump
specifically, which is a storage/memory-residency question, not an FPS
question (draw calls are decoupled from world size via the streamed view
window). See the new storage/streaming spike Open Question below.

## Visual/Audio Requirements

This system has no visual/audio events of its own. All visible/audible
feedback about blocks (placement, textures, sounds) belongs to the Building
System and the still-open rendering ADR — Voxel World only provides data and
signals, never presentation. The one near-exception would be a loading
indicator during terrain generation, but Scene/World Management already
established there was no loading screen at the old world bound — terrain generation must
therefore run synchronously before the first visible scene. [TR-voxel-world-026] *(Revised
2026-07-11, ADR-0014 large world: the initial view-window mesh build is
~2.6 s and runs behind Scene/World Management's transition overlay - the
"near-instant, no indicator" expectation is superseded at this scale.)*

## Game Feel

N/A — no player input touches this system directly (the Building System owns
all input). One indirect link is worth noting: the O(1) read/write
requirement (Acceptance Criterion 16) is the technical foundation that lets
building feel "instant" and "snappy" in the Building System — this system
supplies the speed, the Building System supplies the feel.

## UI Requirements

N/A — no direct UI. Any UI element that displays Voxel World data (build
preview, cell highlight) belongs to Building UI, not here.

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|---------------------------|-----------|-------------------------------|--------|
| "Building System owns placement validity, drag-to-area logic, undo/redo" | `design/gdd/building-system.md` (not yet authored) | Placement-rule ownership boundary | Rule dependency |
| "Villager AI queries the read API for pathfinding-relevant occupancy" | `design/gdd/villager-ai-behavior.md` (not yet authored) | Occupancy query usage | Data dependency |
| "cell_size = 1.0, flush blocks, no gap" | `design/art/visual-direction-note.md` | §2b Classic blocky shape language | Rule dependency |
| "batched write signal feeds the Building System's undo stack" | `design/gdd/building-system.md` (not yet authored) | Undo composition | Data dependency |

*(Both target GDDs do not exist yet — marked as provisional assumptions, to be
cross-checked when each is authored.)*

## Acceptance Criteria

*(`qa-lead` consulted — mandatory for this high-risk section even in Lean
mode. Verdict: GAPS on first draft → 5 missing/underspecified criteria added:
terrain/player-cell indistinguishability, torn-read prevention, base_height
misconfiguration, raycast correctness, Save/Load iteration contents.)*

1. **GIVEN** the game boots, **WHEN** terrain generation completes, **THEN**
   every cell within the world bounds holds either a terrain block or is
   empty, and the system transitions Uninitialized → Generated. [TR-voxel-world-029] *[Logic]*
2. **GIVEN** a valid cell coordinate within bounds, **WHEN** the read API is
   queried, **THEN** it returns the correct occupant matching the last write
   to that cell. [TR-voxel-world-031] *[Logic]*
3. **GIVEN** a cell coordinate outside the world bounds, **WHEN** the read or
   write API is called, **THEN** it returns an explicit "outside grid"
   result — never a silent clamp or crash. [TR-voxel-world-037] *[Logic]*
4. **GIVEN** a world-space point, **WHEN** converted via World→Cell, **THEN**
   `floor()` is used; the grid origin is fixed at (0,0,0) and no negative
   cell coordinates exist, so bounds checks are simple non-negative
   comparisons. [TR-voxel-world-027] [TR-voxel-world-036] *[Logic]*
5. **GIVEN** a cell coordinate, **WHEN** converted via Cell→World, **THEN**
   the result is the cell's center point. [TR-voxel-world-035] *[Logic]*
6. **GIVEN** a single cell write, **WHEN** it completes, **THEN** exactly one
   change signal is emitted identifying the cell and its before/after
   contents. [TR-voxel-world-032] *[Logic]*
7. **GIVEN** a bulk write affecting N cells, **WHEN** it completes, **THEN**
   exactly ONE batched change signal is emitted. [TR-voxel-world-042] *[Logic]*
8. **GIVEN** a write to an already-occupied cell, **WHEN** it completes,
   **THEN** it overwrites and returns the previous contents to the caller.
   [TR-voxel-world-045] *[Logic]*
9. **GIVEN** a terrain cell and a player-placed cell with identical
   block-type/material, **WHEN** read via the API, **THEN** the results are
   indistinguishable — no hidden origin flag. [TR-voxel-world-030] *[Logic]*
10. **GIVEN** the terrain height formula, **WHEN** evaluated at any (x,z)
    within bounds, **THEN** the output is always within `[min_y, max_y]`.
    [TR-voxel-world-038] *[Logic]*
11. **GIVEN** `base_height` > `max_y` (misconfiguration), **WHEN** terrain
    generates, **THEN** it clamps flat at `max_y`, no crash, and a warning
    is logged. [TR-voxel-world-046] *[Logic]*
12. **GIVEN** a raycast against placed cells, **WHEN** cast, **THEN** it
    correctly returns the first occupied cell along the ray (or none) —
    independent of the eventual rendering mechanism. [TR-voxel-world-049] *[Integration]*
13. **GIVEN** a raycast, **WHEN** called repeatedly (e.g., every frame during
    hover), **THEN** it never mutates grid state. [TR-voxel-world-047] *[Logic]*
14. **GIVEN** an iteration over occupied cells (Save/Load), **WHEN** a write
    occurs concurrently, **THEN** the iteration observes only
    fully-committed states, never a partial write. [TR-voxel-world-048] *[Integration]*
15. **GIVEN** the Save/Load iteration API is called, **WHEN** it runs,
    **THEN** it returns only non-empty (occupied) cells. [TR-voxel-world-021] *[Logic]*
16. **Performance**: a single cell read/write completes in O(1) time
    relative to grid size. [TR-voxel-world-019] *[Performance, Advisory — milestone-gated:
    verified at the pre-VS spike, not per-story; re-tiered 2026-07-10
    review (an algorithmic-complexity claim isn't per-commit testable)]*
17. No hardcoded values in implementation — world bounds, `base_height`,
    `amplitude`, `frequency` are read from config, not literals in code.
    [TR-voxel-world-023] *[Config/Data, Advisory]*

**Added by the 2026-07-10 design review:**
18. **GIVEN** a bulk write affecting N cells, **WHEN** the batched signal is emitted, **THEN** its payload contains the before/after contents for ALL N affected cells (per-cell granularity inside the single signal), and the bulk-write API's return value carries the same per-cell previous contents. [TR-voxel-world-043] *[Logic]*
19. **GIVEN** terrain generation at boot, **WHEN** the grid is populated, **THEN** at most one batched change signal is observed by any listener — never per-cell signals. [TR-voxel-world-044] *[Integration]*

**Added by the 2026-07-23 slice revision (user-confirmed vertical-slice findings):**
20. **GIVEN** a floor blueprint placed starting on a terrain top-surface cell, **WHEN** the write completes, **THEN** the terrain cell is replaced flush by the floor block, the write record stores the original terrain value as `restore_value`, and no empty/AIR gap is created. [TR-voxel-world-050] *[Logic]*
21. **GIVEN** a floor built via terrain-replace is later undone, cancelled, or demolished, **WHEN** the reverting write completes, **THEN** the cell's stored `restore_value` replaces the floor block, restoring the original terrain exactly — never left empty. [TR-voxel-world-050] *[Integration]*
22. **GIVEN** a released dig order targeting a cell whose value is in the terrain-band/sand "1..5 family," **WHEN** a villager executes the order, **THEN** the cell becomes empty via the standard batched write API and the standard change signal fires (observable by Build Validation & Navigability as a `cells_removed`-class event). [TR-voxel-world-051] *[Integration]*
23. **GIVEN** a released dig order targeting a water, trunk, or leaves cell, **WHEN** validated, **THEN** the cell is NOT eligible for removal via a dig order. [TR-voxel-world-051] *[Logic]*
24. **GIVEN** the mesher generates faces for any cell, **WHEN** the mesh is submitted to the renderer, **THEN** triangle winding matches Godot's clockwise (CW) front-face convention with backface culling enabled, verified against the engine's actual documented behavior — not a self-stored assumption. [TR-voxel-world-052] *[Performance, Advisory — milestone-gated: must land before asset counts scale beyond vertical-slice levels; the slice's CCW + `CULL_DISABLED` mitigation is tracked as a known, temporary, accepted deviation, not a pass]*

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Do terrain and player-placed cells need a gameplay distinction after all (e.g. "can't build directly on undisturbed terrain")? | game-designer (Building System GDD) | When the Building System GDD is authored | **RESOLVED 2026-07-09: YES** — Building System Core Rule 15: terrain is not removable, built cells are; the game must distinguish them. Mechanism (data flag here vs. Building's own record) deferred to the building ADR (see building-system.md Open Question 3). ***(Slice revision 2026-07-23)***: two slice-validated, user-confirmed EXCEPTIONS to this resolution now exist — Core Rule 7 (floor terrain-replace) and Core Rule 8 (terrain dig orders on the 1..5 terrain-band/sand family, excluding water/trunk/leaves). Terrain remains protected from removal in the general case; these two narrow, bounded paths are the only removals. No new API surface was needed — both route through the existing write API. |
| Can Wave Defense destroy cells (e.g. breach a wall), and if so, through which API? | game-designer (Wave Defense GDD) | After the `/prototype wave-defense` spike | — |
| What is the concrete "hand-shaped valley" silhouette beyond the base height formula (basin shape, radial falloff)? | level-designer / art-director | Before Vertical Slice | — |
| Which rendering implementation is used (GridMap vs. MultiMeshInstance3D vs. chunked mesher) — directly determines world-extent and performance limits? [TR-voxel-world-025] | technical-director | At `/create-architecture` (building ADR) | **PARTIALLY RESOLVED** *(Slice revision 2026-07-23)*: chunked mesher chosen and validated at 2000×2000×32 (ADR-0014); 16,000×16,000×32 production target remains open pending the storage/streaming spike below. |
| Which picking mechanism is used (native physics collision vs. manual DDA)? | godot-specialist | At `/create-architecture` (building ADR) | — |
| *(Slice revision 2026-07-23)* 16,000×16,000×32 storage/streaming spike: which strategy resolves the ~11 GB naive-projection residency problem — paged/on-demand chunk loading, sparse storage for far/unvisited regions, or a reduced persisted footprint (also needed for save-file scaling)? | technical-director | Before the 16,000×16,000×32 production target can be committed to any world-size-dependent epic | — |
