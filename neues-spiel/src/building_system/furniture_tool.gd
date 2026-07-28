## Building System's furniture tool (Story building-028, ADR-0016 primary --
## a valid commit creates blueprint cells grouped into a project; GDD Rule 8,
## [TR-building-system-048]).
##
## Owns exactly GDD Core Rule 8's single-cell furniture-place formula
## ("furniture occupies its cells like blocks do -- one cell = one
## occupant") and the furniture-support predicate -- and the seam that
## registers both into [CommitPipeline] -- nothing else, mirroring
## [BlockTool]/[WallTool]/[FloorTool]/[RoofTool]'s own established per-tool
## shape (Stories building-024/025/026/027).
##
## **Always the ATTACH cell as anchor, always ignores drag** (mirrors
## [BlockTool]'s own established precedent exactly): [method resolve_cell_set]
## ignores both its own `is_drag` parameter and `release_cell` entirely --
## only the press matters, now as the FOOTPRINT's anchor cell (Story
## building-016, GDD Core Rule 8/F5): [method furniture_cell_set] expands the
## anchor into the currently selected item's full `width_cells x depth_cells`
## footprint (MVP: `bed` = 1x2), queried fresh per resolve via [method
## CommitPipeline.get_selected_item_footprint] -- Story building-028's
## single-cell-only scope generalizes here byte-for-byte, since a `(1, 1)`
## footprint degenerates to exactly the one anchor cell.
##
## **Furniture support** (Rule 8/TR-building-system-050, AC16/AC49): [method
## is_cell_supported] is the REAL predicate [CommitPipeline]'s own
## `_furniture_support_predicate` seam was built to receive (that class's own
## doc comment names this exact story as the future real caller). A cell is
## supported iff the cell directly below it is EITHER (a) occupied in the raw
## Voxel World grid (ground, or an already-Built floor/block), OR (b) tracked
## by [CommitPipeline] as a Draft/UnderConstruction/Built blueprint cell (AC49:
## "a blueprint floor cell counts as support for a furniture blueprint") -- a
## CANCELED entry never counts (mirrors [method
## CommitPipeline._is_cell_available]'s own "canceled cells free up their
## address" precedent). This is COMMIT-TIME (planning) support only --
## whether the bed's OWN construction may actually START once claimed is a
## separate, STRICTER check [ConstructionTickLoop.claim_job] performs directly
## against the raw grid (AC49's second half: "construction cannot start until
## the support cell is Built") -- this class has no claim-time concept of its
## own.
##
## **Grep-guard invariant** (mirrors every other tool's established
## precedent): this file never constructs a [BlueprintCell] directly and
## never calls [method VoxelWorldGrid.set_cell]/[method
## VoxelWorldGrid.bulk_write]/[method VoxelWorldGrid.clear_cell] --
## [CommitPipeline.commit] remains the sole creator/writer.
##
## Injected-tier module (ADR-0001): [member voxel_world]/[member
## commit_pipeline] are wired via a scene file's Inspector in production
## (once a future scene-assembly story attaches this node and wires [method
## resolve_cell_set]/[method is_cell_supported] into a live
## [CommitPipeline]), or assigned directly in a headless test; all
## wiring/validation lives in [method setup], never `_ready()`.
class_name FurnitureTool
extends Node

## Read-only bounds/occupancy dependency (ADR-0001) -- the raw grid half of
## [method is_cell_supported]'s combined-view support check. This tool never
## writes to it (see class doc comment's grep-guard invariant).
@export var voxel_world: VoxelWorldGrid

## The SAME [CommitPipeline] instance this tool registers [method
## resolve_cell_set]/[method is_cell_supported] into (ADR-0001) -- also read
## for the blueprint half of [method is_cell_supported]'s combined-view
## support check ([method CommitPipeline.get_blueprint_cell_at]).
@export var commit_pipeline: CommitPipeline

## True once [method setup] has completed at least once.
var _is_set_up: bool = false


## Explicitly callable wiring entry point (ADR-0001). Asserts both
## dependencies were wired.
func setup() -> void:
	assert(voxel_world != null, "FurnitureTool.voxel_world not wired")
	assert(commit_pipeline != null, "FurnitureTool.commit_pipeline not wired")
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## The [method CommitPipeline.set_cell_set_resolver]-compatible bound entry
## point (`Callable(is_drag: bool, press_cell: Vector3i, release_cell:
## Vector3i) -> Array[Vector3i]`) -- a future scene-assembly story wires this
## via `commit_pipeline.set_cell_set_resolver(furniture_tool.resolve_cell_set)`.
## Ignores [param _is_drag] and [param _release_cell] entirely -- see class
## doc comment for why only the press matters (now as the footprint anchor,
## Story building-016). Queries [method CommitPipeline.get_selected_item_footprint]
## fresh on every call, matching [PlacementPick]'s own live-preview-friendly
## "re-derive every frame" convention -- never cached.
func resolve_cell_set(_is_drag: bool, press_cell: Vector3i, _release_cell: Vector3i) -> Array[Vector3i]:
	return FurnitureTool.furniture_cell_set(press_cell, commit_pipeline.get_selected_item_footprint())


## GDD Core Rule 8/F5 (pure, stateless -- exercisable directly with arbitrary
## values, mirroring [method BlockTool.block_cell_set]'s established
## testable-pure-function shape): a furniture-tool commit is a FIXED list of
## cell offsets from the picked anchor cell (Story building-016) -- the
## item's `width_cells x depth_cells` footprint (RID's own "anchored at its
## origin cell" contract, `design/gdd/resource-item-database.md` Core Rule
## 10), filled out as a purely horizontal rectangle on the anchor's own
## y-level: [param footprint].x cells along world X, [param footprint].y
## cells along world Z, with [param anchor] itself as the rectangle's
## minimum (0, 0) corner. Story building-028's single-cell-only scope
## generalizes here byte-for-byte: `footprint == Vector2i(1, 1)` degenerates
## to exactly one cell (the anchor itself), matching this story's own
## pre-016 behavior exactly.
static func furniture_cell_set(anchor: Vector3i, footprint: Vector2i) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for x: int in range(footprint.x):
		for z: int in range(footprint.y):
			cells.append(anchor + Vector3i(x, 0, z))
	return cells


## The [method CommitPipeline.set_furniture_support_predicate]-compatible
## bound entry point (`Callable(cell: Vector3i) -> bool`) -- a future
## scene-assembly story wires this via
## `commit_pipeline.set_furniture_support_predicate(furniture_tool.is_cell_supported)`.
## See class doc comment for the exact combined-view rule.
func is_cell_supported(cell: Vector3i) -> bool:
	assert(is_set_up(), "FurnitureTool.is_cell_supported called before setup()")
	var support_cell: Vector3i = cell + Vector3i(0, -1, 0)
	# An out-of-bounds support cell (e.g. targeting the world floor) is never
	# solid -- [method VoxelWorldGrid.get_cell] returns `null` (not an empty
	# [CellContents]) for an out-of-bounds address, so bounds must be checked
	# FIRST to avoid a null-call crash.
	if voxel_world.is_in_bounds(support_cell) and not voxel_world.get_cell(support_cell).is_empty():
		return true
	var tracked: BlueprintCell = commit_pipeline.get_blueprint_cell_at(support_cell)
	return tracked != null and tracked.state != BlueprintCell.MicroState.CANCELED
