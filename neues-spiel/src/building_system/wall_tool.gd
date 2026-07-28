## Building System's wall tool (Story building-024, ADR-0016 primary -- a
## valid commit creates blueprint cells grouped into a project, ADR-0002
## secondary -- `wall_height` comes from this module's own typed `.tres`
## config, never a hardcoded literal).
##
## Owns exactly the GDD's Formula F1 cell-set (`design/gdd/building-system.md`
## "F1 -- Wall cell set from a drag", [TR-building-system-044]/
## [TR-building-system-077]) and the seam that registers it into
## [CommitPipeline] -- nothing else. Per this story's Out of Scope: the
## click-vs-drag discrimination trigger and the actual write/validity gate
## are [CommitPipeline]'s own established job (Stories building-021/022);
## ghost preview RENDERING is Story 023 (not built); the wall-height stepper
## widget is Building UI's (this class only READS the config value).
##
## **F1 formula**: `wall_cell_count = line_length(start_cell, end_cell) x
## wall_height`. [method wall_cell_set] rasterizes the dragged segment's
## horizontal (X/Z) run via [method rasterize_run] (Bresenham-style stepping
## -- deterministic, equal displacements always yield equal run lengths) on
## the locked working plane (Core Rule 3: the plane is locked to the drag's
## START cell for its entire duration, AC8) and extrudes each run cell
## [member WallToolConfig.wall_height] cells upward from the picked surface
## via [method extrude_column] -- one action, one array, never a
## layer-by-layer sequence of separate commits (TR-building-system-044's
## "in one action -- never layer-by-layer slabs").
##
## **`start_cell == end_cell` degenerate case** (AC6b, F1's own documented
## degenerate: "start == end degenerates to a single column of wall_height
## cells"): [method rasterize_run] naturally returns a single-element run for
## identical endpoints, so this collapses to one column with NO separate
## code branch -- this is also exactly what a genuine click (AC6, GDD Formula
## F4) resolves to, since [signal PlacementPick.build_committed]'s
## `press_cell`/`release_cell` are equal for a click too ([PlacementPick]'s
## own doc comment: "a click never enters a second frame of the drag-plane
## pick before release"). [method resolve_cell_set] therefore does not branch
## on its own `is_drag` parameter at all -- the SAME formula call correctly
## produces both AC5's multi-cell run and AC6b's single-column degenerate.
##
## **Grep-guard invariant** (QA plan Sprint 8, Call-out 3): this file never
## constructs a [BlueprintCell] directly and never calls
## [method VoxelWorldGrid.set_cell]/[method VoxelWorldGrid.bulk_write]/
## [method VoxelWorldGrid.clear_cell] -- [CommitPipeline.commit] remains the
## sole creator/writer. [method resolve_cell_set] only ever returns an
## `Array[Vector3i]` candidate set; it is registered into [CommitPipeline] via
## [method CommitPipeline.set_cell_set_resolver], mirroring that class's own
## documented "future tool story overrides this" seam exactly.
##
## Injected-tier module (ADR-0001): [member config] is wired via a scene
## file's Inspector in production (once a future scene-assembly story
## attaches this node and wires [method resolve_cell_set] into a live
## [CommitPipeline]), or assigned directly in a headless test; all
## wiring/validation lives in [method setup], never `_ready()`.
class_name WallTool
extends Node

## Tuning config dependency (ADR-0002) -- the sole source of
## [member WallToolConfig.wall_height] this tool ever reads. Wired via a
## scene file's Inspector in production, or assigned directly in a headless
## test. Never read inside `_ready()` -- see [method setup].
@export var config: WallToolConfig

## True once [method setup] has completed at least once.
var _is_set_up: bool = false


## Explicitly callable wiring entry point (ADR-0001). Asserts [member config]
## was wired and applies ADR-0002's clamp+warn `validate()` policy to it.
func setup() -> void:
	assert(config != null, "WallTool.config not wired")
	for issue: String in config.validate():
		push_warning(issue)
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## The [method CommitPipeline.set_cell_set_resolver]-compatible bound entry
## point (`Callable(is_drag: bool, press_cell: Vector3i, release_cell:
## Vector3i) -> Array[Vector3i]`) -- a future scene-assembly story wires this
## via `commit_pipeline.set_cell_set_resolver(wall_tool.resolve_cell_set)`.
## Ignores [param _is_drag] entirely -- see class doc comment for why the
## SAME F1 formula call correctly resolves both the drag (AC5) and
## click/degenerate-drag (AC6/AC6b) cases with no branch.
func resolve_cell_set(_is_drag: bool, press_cell: Vector3i, release_cell: Vector3i) -> Array[Vector3i]:
	assert(is_set_up(), "WallTool.resolve_cell_set called before setup()")
	return WallTool.wall_cell_set(press_cell, release_cell, config.wall_height)


## GDD Formula F1 (pure, stateless -- exercisable directly with arbitrary
## values, mirroring [method PlacementPick.derive_attach_cell]'s established
## testable-pure-function shape, and reusable as-is by a future ghost-preview
## call site, Story 023, per the QA plan's forward-compatibility note):
## `wall_cell_count = line_length(press_cell, release_cell) x wall_height`.
## Combines [method rasterize_run]'s horizontal line with
## [method extrude_column]'s vertical extrusion for every run cell.
static func wall_cell_set(
	press_cell: Vector3i, release_cell: Vector3i, wall_height: int
) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for run_cell: Vector3i in WallTool.rasterize_run(press_cell, release_cell):
		cells.append_array(WallTool.extrude_column(run_cell, wall_height))
	return cells


## Pure Bresenham-style horizontal (X/Z) line rasterization (F1, Core Rule 3):
## steps from [param press_cell] to [param release_cell]'s X/Z coordinates
## only -- [param press_cell]'s OWN Y is used as the fixed base height for
## every returned run cell, never [param release_cell]'s Y (the working
## plane is locked to the drag's START cell for its entire duration, AC8, so
## the start's height is the only correct anchor regardless of whatever
## Y a caller's [param release_cell] happens to carry). Deterministic:
## `run_length = max(|dx|, |dz|) + 1` (Chebyshev-style dominant-axis
## stepping) -- a diagonal drag of equal |dx|/|dz| yields the identical run
## length as an axis-aligned drag of the same displacement (QA plan edge
## case). `press_cell == release_cell` naturally returns a single-element
## run (AC6b's degenerate case, F1's own documented "start == end
## degenerates to 1").
static func rasterize_run(press_cell: Vector3i, release_cell: Vector3i) -> Array[Vector3i]:
	var run: Array[Vector3i] = []
	var base_y: int = press_cell.y
	var x: int = press_cell.x
	var z: int = press_cell.z
	var end_x: int = release_cell.x
	var end_z: int = release_cell.z
	var dx: int = absi(end_x - x)
	var dz: int = absi(end_z - z)
	var step_x: int = 1 if x < end_x else -1
	var step_z: int = 1 if z < end_z else -1
	var err: int = dx - dz
	while true:
		run.append(Vector3i(x, base_y, z))
		if x == end_x and z == end_z:
			break
		var err2: int = err * 2
		if err2 > -dz:
			err -= dz
			x += step_x
		if err2 < dx:
			err += dx
			z += step_z
	return run


## Pure vertical extrusion (F1: "each run cell extrudes wall_height cells
## upward from the picked surface"): [param wall_height] cells starting at
## [param base_cell] itself and stacking upward -- one action's worth of
## cells returned in a single array, never a per-layer sequence (Core Rule 4
## / TR-building-system-044's "never layer-by-layer slabs").
static func extrude_column(base_cell: Vector3i, wall_height: int) -> Array[Vector3i]:
	var column: Array[Vector3i] = []
	for h: int in wall_height:
		column.append(Vector3i(base_cell.x, base_cell.y + h, base_cell.z))
	return column
