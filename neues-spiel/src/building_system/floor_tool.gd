## Building System's floor tool (Story building-025, ADR-0016 primary -- a
## valid commit creates blueprint cells grouped into a project).
##
## Owns exactly the GDD's Formula F2 cell-set (`design/gdd/building-system.md`
## "F2 -- Floor cell set from a drag", [TR-building-system-045]/
## [TR-building-system-078]) and the seam that registers it into
## [CommitPipeline] -- nothing else, mirroring [WallTool]'s established F1
## shape (Story building-024). Per this story's Out of Scope: floor-over-
## terrain flush-replace + `restore_value` capture is Story 012 (the slice's
## terrain-start branch, not built here); ghost preview RENDERING is Story
## 023 (not built); the click-vs-drag discrimination trigger, the bounds
## clamp, and the actual write/validity gate remain [CommitPipeline]'s own
## established job (Stories building-021/022).
##
## **F2 formula**: `floor_cell_count = (|dx| + 1) x (|dz| + 1)` -- a
## 1-cell-thick rectangle on the locked working plane (Core Rule 3: the plane
## is locked to the drag's START cell for its entire duration, mirroring
## [WallTool.rasterize_run]'s own Y-anchor discipline), filled via [method
## floor_cell_set]. Unlike F1, F2 has no vertical extrusion step (the
## rectangle IS already the complete 1-cell-thick formula) and no tunable
## knob of its own -- the GDD's own Tuning Knobs table
## (`design/gdd/building-system.md` "## Tuning Knobs") names only
## `wall_height` for the wall tool; per `CONTRACTS.md` §2's "one config per
## GDD Tuning Knob" rule, this tool intentionally carries no `.tres` config
## -- a documented deviation from [WallTool]'s config-driven shape, not an
## oversight.
##
## **Zero-length drag degenerates to a single 1x1 tile** (AC7's own
## documented edge case, F2's "Zero-length drag degenerates to a single 1x1
## tile"): [method floor_cell_set] naturally returns a single-element
## rectangle for identical endpoints -- this is also exactly what a genuine
## click resolves to (mirroring [WallTool]'s AC6b precedent), so [method
## resolve_cell_set] does not branch on its own `is_drag` parameter at all --
## the SAME formula call correctly resolves both the drag (AC7) and
## click/degenerate-drag cases with no branch.
##
## **Grep-guard invariant** (QA plan Sprint 8, Call-out 3): this file never
## constructs a [BlueprintCell] directly and never calls
## [method VoxelWorldGrid.set_cell]/[method VoxelWorldGrid.bulk_write]/
## [method VoxelWorldGrid.clear_cell] -- [CommitPipeline.commit] remains the
## sole creator/writer. [method resolve_cell_set] only ever returns an
## `Array[Vector3i]` candidate set; it is registered into [CommitPipeline] via
## [method CommitPipeline.set_cell_set_resolver], mirroring [WallTool]'s own
## documented "future tool story overrides this" seam exactly.
##
## Unlike [WallTool] (an injected-tier module per ADR-0001 with a `config`
## dependency to wire/validate in `setup()`), this class has no REQUIRED
## dependency -- there is nothing that must be wired for the plain F2 formula
## itself. [method resolve_cell_set] is callable immediately after
## construction with both new deps left `null` (every pre-012 caller/test
## behaves identically).
##
## Story scene-007 addition: a trivial [method setup]/[method is_set_up] pair
## is added SOLELY so [GameWorld]._setup_injected_tier()'s own
## `module.has_method(&"setup")` boot-gate contract (ADR-0005) can host this
## tool as a real [Valley]-reported injected-tier module -- see [Valley]'s own
## class doc comment. It validates/asserts nothing (there is still nothing
## REQUIRED to wire here; [member voxel_world]/[member commit_pipeline] stay
## fully optional, unasserted, exactly as before this story) and every
## pre-scene-007 bare `FloorTool.new()` construction (this project's own
## direct-construction test convention) continues to work identically whether
## or not `setup()` is ever called on it.
##
## **Story building-012 (this revision, ADR-0016 primary, GDD Rule 14l,
## [TR-building-system-120]): the terrain-start excavation branch.** [member
## voxel_world]/[member commit_pipeline] are two NEW, OPTIONAL (nullable, never
## asserted) dependencies -- mirrors [FurnitureTool]'s own combined-view
## support-check shape ([method FurnitureTool.is_cell_supported]) exactly,
## reused here for the SAME "raw grid OR blueprint-tracked" read, just to
## answer a different question. A `null` value on either restores this
## story's pre-012 behavior exactly (excavation never triggers, [method
## resolve_cell_set] behaves exactly as it always did) -- there is no
## `setup()` gate to enforce wiring because a bare `FloorTool.new()` (this
## project's own established direct-construction test convention, and every
## pre-012 test in `floor_tool_test.gd`) must keep working unchanged.
##
## [method starts_on_terrain_top_surface] answers Rule 14l's own trigger
## condition: does [param press_cell] (the drag's ATTACH cell, ALWAYS one cell
## above whatever [PlacementPick] actually hit -- see that class's own doc
## comment) sit directly above **raw, untracked terrain** -- raw Voxel World
## data that is non-empty AND carries no [CommitPipeline]-tracked
## [BlueprintCell] at all (a CANCELED entry counts as untracked too, mirroring
## [method CommitPipeline._is_cell_available]'s own "canceled cells free up
## their address" precedent)? [CommitPipeline]'s own doc comment already
## establishes the load-bearing fact this reuses without reinventing it: "a
## raw-grid-occupied cell this pipeline does NOT itself track... can only be
## terrain" (this system is the sole writer of every cell it ever tracks). A
## cell BELOW press_cell that IS tracked (Draft/UnderConstruction/Built, e.g.
## an existing floor or block THIS system already built) therefore fails this
## check -- exactly the QA plan's own named edge case: "a floor drag starting
## on a BUILT floor (not terrain) does NOT capture `restore_value` (normal
## stacking)."
##
## [method resolve_cell_set] consults this ONCE, against [param press_cell]
## only (Core Rule 3: the working plane -- and therefore this decision -- is
## locked to the drag's START cell for its entire duration, exactly mirroring
## the existing Y-anchor discipline this class's doc comment already
## documents): when it triggers, the WHOLE F2 rectangle is generated one cell
## LOWER (at the terrain cell's own Y, never the attach cell's) so the floor
## replaces the terrain flush instead of stacking a step on top of it. [method
## resolve_terrain_replace_cells] is the companion seam
## [CommitPipeline.set_terrain_replace_resolver] consumes (mirrors [method
## resolve_cell_set]'s own [method CommitPipeline.set_cell_set_resolver]
## registration precedent) -- it reports exactly WHICH of [method
## resolve_cell_set]'s own returned cells are eligible for [CommitPipeline]'s
## narrow, tracked terrain-replace-in-place exception (Rule 14l's own
## documented carve-out from Core Rule 15/Edge Case 2's general "terrain is
## never replace-in-place-able" rule): either ALL of them (the excavation
## branch triggered) or NONE (ordinary stacking, [TR-building-system-084]'s
## general rule applies unchanged). [CommitPipeline] is the sole place that
## actually reads raw terrain content and writes [member
## BlueprintCell.restore_value] -- this class only ever decides WHICH cells
## qualify, never touches [VoxelWorldGrid] itself (grep-guard, unchanged).
class_name FloorTool
extends Node

## Read-only occupancy dependency (ADR-0001, Story building-012) -- see class
## doc comment. This tool never writes to it (grep-guard, unchanged).
@export var voxel_world: VoxelWorldGrid = null

## The SAME [CommitPipeline] instance this tool registers [method
## resolve_cell_set]/[method resolve_terrain_replace_cells] into (ADR-0001,
## Story building-012) -- also read for the blueprint half of [method
## starts_on_terrain_top_surface]'s combined-view check ([method
## CommitPipeline.get_blueprint_cell_at]).
@export var commit_pipeline: CommitPipeline = null

## True once [method setup] has completed at least once (Story scene-007
## addition -- see class doc comment).
var _is_set_up: bool = false


## Story scene-007 addition -- a trivial wiring entry point with nothing to
## assert (see class doc comment: this tool has no REQUIRED dependency).
## Exists only so this class can be hosted as a real injected-tier module.
func setup() -> void:
	_is_set_up = true


## Returns whether [method setup] has completed (Story scene-007 addition).
func is_set_up() -> bool:
	return _is_set_up


## The [method CommitPipeline.set_cell_set_resolver]-compatible bound entry
## point (`Callable(is_drag: bool, press_cell: Vector3i, release_cell:
## Vector3i) -> Array[Vector3i]`) -- a future scene-assembly story wires this
## via `commit_pipeline.set_cell_set_resolver(floor_tool.resolve_cell_set)`.
## Ignores [param _is_drag] entirely -- see class doc comment for why the
## SAME F2 formula call correctly resolves both the drag (AC7) and
## click/degenerate-drag cases with no branch.
##
## Story building-012 addition: when [param press_cell] starts on a terrain
## top surface ([method starts_on_terrain_top_surface]), both endpoints are
## shifted one cell down BEFORE rasterizing (Rule 14l's "replaces the terrain
## cell flush... rather than stacking a floor cell on top of it") -- only
## [param press_cell]'s own Y actually drives [method floor_cell_set]'s
## `base_y` (see that method's own doc comment), so shifting
## [param release_cell] too is purely for symmetry/clarity, never load-bearing
## on its own.
func resolve_cell_set(_is_drag: bool, press_cell: Vector3i, release_cell: Vector3i) -> Array[Vector3i]:
	var effective_press: Vector3i = press_cell
	var effective_release: Vector3i = release_cell
	if starts_on_terrain_top_surface(press_cell):
		effective_press.y -= 1
		effective_release.y -= 1
	return FloorTool.floor_cell_set(effective_press, effective_release)


## Rule 14l's own trigger condition -- see class doc comment. `false`
## whenever [member voxel_world] is unwired (this story's pre-012 behavior is
## the correct fallback: no dependency, no excavation, ordinary stacking).
func starts_on_terrain_top_surface(press_cell: Vector3i) -> bool:
	if voxel_world == null:
		return false
	var support_cell: Vector3i = press_cell + Vector3i(0, -1, 0)
	if not voxel_world.is_in_bounds(support_cell):
		return false
	if voxel_world.get_cell(support_cell).is_empty():
		return false
	if commit_pipeline == null:
		return false
	var tracked: BlueprintCell = commit_pipeline.get_blueprint_cell_at(support_cell)
	return tracked == null or tracked.state == BlueprintCell.MicroState.CANCELED


## The [method CommitPipeline.set_terrain_replace_resolver]-compatible bound
## entry point (`Callable(is_drag: bool, press_cell: Vector3i, release_cell:
## Vector3i) -> Array[Vector3i]`, Story building-012) -- a future
## scene-assembly story wires this via
## `commit_pipeline.set_terrain_replace_resolver(floor_tool.resolve_terrain_replace_cells)`,
## alongside [method resolve_cell_set]'s own registration. Reports the exact
## SAME cell set [method resolve_cell_set] itself would return for this
## press/release pair when the terrain-start branch triggers (every returned
## cell was, by construction, a terrain cell at commit time -- the whole F2
## rectangle shifts as one unit, never a per-cell mix), or an empty array when
## it does not (ordinary stacking -- no cell of this commit is terrain-replace
## eligible).
func resolve_terrain_replace_cells(
	is_drag: bool, press_cell: Vector3i, release_cell: Vector3i
) -> Array[Vector3i]:
	if not starts_on_terrain_top_surface(press_cell):
		return []
	return resolve_cell_set(is_drag, press_cell, release_cell)


## GDD Formula F2 (pure, stateless -- exercisable directly with arbitrary
## values, mirroring [method WallTool.wall_cell_set]'s established
## testable-pure-function shape, and reusable as-is by a future ghost-preview
## call site, Story 023, per the QA plan's forward-compatibility note):
## `floor_cell_count = (|dx| + 1) x (|dz| + 1)`. Rasterizes a 1-cell-thick
## horizontal (X/Z) rectangle spanning [param press_cell] and [param
## release_cell]'s X/Z coordinates, inclusive of both corners regardless of
## drag direction. [param press_cell]'s OWN Y is used as the fixed height for
## every returned cell, never [param release_cell]'s Y (the working plane is
## locked to the drag's START cell for its entire duration, Core Rule 3,
## mirroring [WallTool.rasterize_run]'s identical Y-anchor discipline).
## `press_cell == release_cell` naturally returns a single-element rectangle
## (AC7's documented degenerate case, "a single 1x1 tile").
static func floor_cell_set(press_cell: Vector3i, release_cell: Vector3i) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var base_y: int = press_cell.y
	var min_x: int = mini(press_cell.x, release_cell.x)
	var max_x: int = maxi(press_cell.x, release_cell.x)
	var min_z: int = mini(press_cell.z, release_cell.z)
	var max_z: int = maxi(press_cell.z, release_cell.z)
	for z: int in range(min_z, max_z + 1):
		for x: int in range(min_x, max_x + 1):
			cells.append(Vector3i(x, base_y, z))
	return cells
