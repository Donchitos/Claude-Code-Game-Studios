## Building System's roof tool (Story building-026, ADR-0016 primary -- a
## valid commit creates blueprint cells grouped into a project).
##
## **Sprint 8 scope: Flat formation MVP only.** Gable/Hip/Shed are VS-tier
## (the shape algorithm is game-designer/art-director's roof shape spec, not
## yet authored) -- this class exposes the formation-picker seam (a settable
## [enum Formation] plus a per-formation dispatch in [method resolve_cell_set])
## WITHOUT building their geometry, per this story's own Implementation Notes:
## "Do NOT build those three algorithms in M01." AC15b is PROVISIONAL and not
## exercised by this sprint's test suite.
##
## Owns exactly the GDD's Formula F5 Flat cell-set (`design/gdd/building-system.md`
## "F5 -- Roof and furniture cell counts", [TR-building-system-046]/
## [TR-building-system-082]) and the seam that registers it into
## [CommitPipeline] -- nothing else, mirroring [WallTool]/[FloorTool]'s
## established per-tool shape (Stories building-024/025). Per this story's Out
## of Scope: Gable/Hip/Shed shape algorithms (VS-tier, a future story once the
## roof shape spec lands); Building UI's formation-picker widget (building-ui
## epic -- this class only exposes [method set_formation]/[method
## get_formation] for that future widget to call); ghost preview rendering
## (Story 023, not built); the click-vs-drag discrimination trigger, the
## bounds clamp, and the actual write/validity gate remain [CommitPipeline]'s
## own established job (Stories building-021/022).
##
## **F5 Flat formula**: `flat_roof_cell_count = (|dx| + 1) x (|dz| + 1)` --
## "identical to F2, one cell thick on the plane above the footprint's
## highest picked surface." [method flat_roof_cell_set] rasterizes the same
## X/Z rectangle shape as [method FloorTool.floor_cell_set] (Core Rule 3: the
## working plane is locked to the drag's START cell for its entire duration,
## mirroring [WallTool.rasterize_run]/[FloorTool.floor_cell_set]'s identical
## Y-anchor discipline) but at [param press_cell]'s Y **plus one plane** --
## the roof sits one cell above the surface picked at drag start. There is no
## second, independently-picked "highest" cell to compare against: the locked
## plane (press_cell's own Y) IS the footprint's highest picked surface by
## construction, exactly as [param release_cell]'s Y is already ignored by
## [WallTool]/[FloorTool] for the identical reason.
##
## **Zero-length drag degenerates to a single 1x1 tile one plane up** (this
## story's own documented edge case, mirroring [FloorTool.floor_cell_set]'s
## AC7 precedent exactly): [method flat_roof_cell_set] naturally returns a
## single-element rectangle for identical X/Z endpoints -- also exactly what
## a genuine click resolves to, so [method resolve_cell_set] does not branch
## on its own `is_drag` parameter for the Flat formation.
##
## **Grep-guard invariant** (QA plan Sprint 8, Call-out 3): this file never
## constructs a [BlueprintCell] directly and never calls
## [method VoxelWorldGrid.set_cell]/[method VoxelWorldGrid.bulk_write]/
## [method VoxelWorldGrid.clear_cell] -- [CommitPipeline.commit] remains the
## sole creator/writer. [method resolve_cell_set] only ever returns an
## `Array[Vector3i]` candidate set; it is registered into [CommitPipeline] via
## [method CommitPipeline.set_cell_set_resolver], mirroring [WallTool]/
## [FloorTool]'s own documented "future tool story overrides this" seam
## exactly.
##
## **No config** (deviation from [WallTool]'s config-driven shape, mirroring
## [FloorTool]'s own established precedent and rationale): the GDD's Tuning
## Knobs table (`design/gdd/building-system.md` "## Tuning Knobs") names no
## roof-specific knob -- per `CONTRACTS.md` §2's "one config per GDD Tuning
## Knob" rule, this tool intentionally carries no `.tres` config, a documented
## deviation, not an oversight.
##
## Unlike [WallTool] (an injected-tier module per ADR-0001 with a `config`
## dependency to wire/validate in `setup()`), this class has no dependency of
## any kind -- there is nothing to wire and nothing to validate. [method
## resolve_cell_set] is callable immediately after construction (formation
## defaults to [constant Formation.FLAT]).
##
## Story scene-007 addition: a trivial [method setup]/[method is_set_up] pair
## is added SOLELY so [GameWorld]._setup_injected_tier()'s own
## `module.has_method(&"setup")` boot-gate contract (ADR-0005) can host this
## tool as a real [Valley]-reported injected-tier module (see [FloorTool]'s
## own identical scene-007 addition/rationale) -- it validates/asserts
## nothing.
class_name RoofTool
extends Node

## True once [method setup] has completed at least once (Story scene-007
## addition).
var _is_set_up: bool = false


## Story scene-007 addition -- a trivial wiring entry point with nothing to
## assert. Exists only so this class can be hosted as a real injected-tier
## module.
func setup() -> void:
	_is_set_up = true


## Returns whether [method setup] has completed (Story scene-007 addition).
func is_set_up() -> bool:
	return _is_set_up

## The four MVP roof formations named by GDD Core Rule 6 (Flach/Sattel/Walm/
## Pult). **Only [constant Formation.FLAT] has a built cell-set formula this
## sprint** -- [constant Formation.GABLE]/[constant Formation.HIP]/
## [constant Formation.SHED] are the VS-tier reserve named in this story's
## Implementation Notes; [method resolve_cell_set] asserts on them rather
## than silently fabricating geometry that doesn't exist yet.
enum Formation { FLAT, GABLE, HIP, SHED }

## The formation the NEXT drag/commit resolves against (Core Rule 6: "the
## player picks one of four formations ... and drags a footprint"). Defaults
## to [constant Formation.FLAT] -- the only MVP-complete formation this
## sprint. A future Building UI story (out of scope here) calls
## [method set_formation] from its roof-formation picker widget before the
## player starts dragging.
var _formation: Formation = Formation.FLAT


## Sets the formation the next drag/commit will resolve against -- the
## formation-picker seam this story exposes for Building UI (out of scope
## here) to wire once its widget exists.
func set_formation(formation: Formation) -> void:
	_formation = formation


## Returns the currently-selected formation.
func get_formation() -> Formation:
	return _formation


## The [method CommitPipeline.set_cell_set_resolver]-compatible bound entry
## point (`Callable(is_drag: bool, press_cell: Vector3i, release_cell:
## Vector3i) -> Array[Vector3i]`) -- a future scene-assembly story wires this
## via `commit_pipeline.set_cell_set_resolver(roof_tool.resolve_cell_set)`.
## Ignores [param _is_drag] entirely for the Flat formation -- see class doc
## comment for why the SAME F5 formula call correctly resolves both the drag
## (AC15) and click/degenerate-drag cases with no branch. Dispatches on
## [member _formation]: Gable/Hip/Shed are this story's own named VS-tier
## reserve -- calling this with one of them selected is a programmer error
## this sprint (no Building UI widget can select them yet, since that widget
## is itself out of scope) and fails loudly via `assert()` rather than
## fabricating geometry that doesn't exist.
func resolve_cell_set(_is_drag: bool, press_cell: Vector3i, release_cell: Vector3i) -> Array[Vector3i]:
	match _formation:
		Formation.FLAT:
			return RoofTool.flat_roof_cell_set(press_cell, release_cell)
		_:
			assert(
				false,
				"RoofTool.resolve_cell_set: formation %s has no cell-set geometry yet -- Gable/Hip/Shed are VS-tier (story building-026 Out of Scope), Flat is the only MVP formation" % Formation.keys()[_formation]
			)
			return []


## GDD Formula F5 Flat (pure, stateless -- exercisable directly with
## arbitrary values, mirroring [method FloorTool.floor_cell_set]'s established
## testable-pure-function shape, and reusable as-is by a future ghost-preview
## call site, Story 023, per the QA plan's forward-compatibility note):
## `flat_roof_cell_count = (|dx| + 1) x (|dz| + 1)`, one cell thick, one plane
## ABOVE the footprint's picked surface. Rasterizes a 1-cell-thick horizontal
## (X/Z) rectangle spanning [param press_cell] and [param release_cell]'s X/Z
## coordinates, inclusive of both corners regardless of drag direction, at
## [param press_cell]'s OWN Y plus one (never [param release_cell]'s Y -- the
## working plane is locked to the drag's START cell for its entire duration,
## Core Rule 3, mirroring [WallTool.rasterize_run]/[FloorTool.floor_cell_set]'s
## identical Y-anchor discipline). `press_cell == release_cell` naturally
## returns a single-element rectangle (a 1x1 footprint yields 1 cell, this
## story's own documented edge case).
static func flat_roof_cell_set(press_cell: Vector3i, release_cell: Vector3i) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var base_y: int = press_cell.y + 1
	var min_x: int = mini(press_cell.x, release_cell.x)
	var max_x: int = maxi(press_cell.x, release_cell.x)
	var min_z: int = mini(press_cell.z, release_cell.z)
	var max_z: int = maxi(press_cell.z, release_cell.z)
	for z: int in range(min_z, max_z + 1):
		for x: int in range(min_x, max_x + 1):
			cells.append(Vector3i(x, base_y, z))
	return cells
