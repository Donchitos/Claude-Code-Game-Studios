## Building System's block tool (Story building-027, ADR-0016 primary -- a
## valid commit creates blueprint cells grouped into a project).
##
## **Sprint 8 scope: place mode only.** AC2 (remove mode -- routing the block
## tool's remove action to the removal-tool micro-state branch, Story
## building-031 base + Story building-015's full Draft/Queued/Built
## branching) is explicitly deferred this sprint: `sprint-08.md`'s own
## Acceptance Criteria column states "remove mode OUT of M01 (routes to
## removal-tool 031 -> M02 per CD ruling)", and Story 031 is not scheduled --
## untested-by-design per the Sprint 8 QA plan's own Call-out 2, not a gap.
## This class implements NOTHING remove-related -- no `build_remove`
## handling, no stub, no branch -- there is no removal-tool base yet in this
## codebase to route to.
##
## Owns exactly GDD Core Rule 7's single-cell place formula
## (`design/gdd/building-system.md` "7. Block tool: single-cell place
## (attach/replace per Rule 3) or remove.", [TR-building-system-047]) and the
## seam that registers it into [CommitPipeline] -- nothing else, mirroring
## [WallTool]/[FloorTool]/[RoofTool]'s established per-tool shape (Stories
## building-024/025/026). Per this story's Out of Scope: the click-vs-drag
## discrimination trigger and the actual write/validity gate remain
## [CommitPipeline]'s own established job (Stories building-021/022); ghost
## preview RENDERING is Story 023 (not built); remove mode is Story 031/015
## (see above).
##
## **Single-cell place, always the ATTACH cell** (Core Rule 3,
## [TR-building-system-043]): unlike [WallTool]/[FloorTool]/[RoofTool] (which
## combine `press_cell`/`release_cell` into a multi-cell run/rectangle), the
## block tool commits exactly ONE cell -- [signal PlacementPick.build_committed]'s
## `press_cell` (the ATTACH cell resolved at press time, per that signal's own
## doc comment: "press_cell/release_cell are the ATTACH cell ... resolved at
## press time and at release time respectively"). [method resolve_cell_set]
## therefore ignores BOTH its own `is_drag` parameter AND `release_cell`
## entirely -- a block-tool "drag" carries no distinct meaning from a click;
## only the press matters. This is the simplest of the four MVP placement
## tools built so far: no rasterization, no rectangle, no formation dispatch.
##
## **Attach vs. replace-in-place is NOT decided here.** [PlacementPick]
## always resolves `press_cell` to the surface-aware ATTACH cell (the empty
## cell adjacent to whatever face was picked, [method PlacementPick.derive_attach_cell]);
## [CommitPipeline]'s own established combined-view validity gate (Story
## building-022 -- see `placement_validity_test.gd`'s "replace-in-place of an
## already-BUILT cell IS valid" / "attaching to a terrain cell's face IS
## valid" precedent, [method CommitPipeline._is_cell_available]) is what
## decides, per candidate cell, whether that SAME attach-cell address
## resolves to a fresh placement, a valid replace of a cell THIS SYSTEM
## already built, or an outright rejection (terrain/other-occupied). This
## class supplies only the ONE candidate cell; it carries no attach-vs-replace
## branch of its own -- Core Rule 3's "attach or replace" wording is fully
## satisfied by [CommitPipeline]'s existing generic rule, re-exercised (not
## re-implemented) through this tool's resolver.
##
## **Grep-guard invariant** (QA plan Sprint 8, Call-out 3): this file never
## constructs a [BlueprintCell] directly and never calls
## [method VoxelWorldGrid.set_cell]/[method VoxelWorldGrid.bulk_write]/
## [method VoxelWorldGrid.clear_cell] -- [CommitPipeline.commit] remains the
## sole creator/writer. [method resolve_cell_set] only ever returns an
## `Array[Vector3i]` candidate set; it is registered into [CommitPipeline] via
## [method CommitPipeline.set_cell_set_resolver], mirroring [WallTool]/
## [FloorTool]/[RoofTool]'s own documented "future tool story overrides this"
## seam exactly.
##
## **No config** (deviation from [WallTool]'s config-driven shape, mirroring
## [FloorTool]/[RoofTool]'s own established precedent and rationale): the
## GDD's Tuning Knobs table (`design/gdd/building-system.md` "## Tuning
## Knobs") names no block-tool-specific knob -- per `CONTRACTS.md` §2's "one
## config per GDD Tuning Knob" rule, this tool intentionally carries no
## `.tres` config, a documented deviation, not an oversight.
##
## Unlike [WallTool] (an injected-tier module per ADR-0001 with a `config`
## dependency to wire/validate in `setup()`), this class has no dependency of
## any kind -- there is nothing to wire and nothing to validate. [method
## resolve_cell_set] is callable immediately after construction.
##
## Story scene-007 addition: a trivial [method setup]/[method is_set_up] pair
## is added SOLELY so [GameWorld]._setup_injected_tier()'s own
## `module.has_method(&"setup")` boot-gate contract (ADR-0005) can host this
## tool as a real [Valley]-reported injected-tier module (see [FloorTool]/
## [RoofTool]'s own identical scene-007 addition/rationale) -- it validates/
## asserts nothing.
class_name BlockTool
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


## The [method CommitPipeline.set_cell_set_resolver]-compatible bound entry
## point (`Callable(is_drag: bool, press_cell: Vector3i, release_cell:
## Vector3i) -> Array[Vector3i]`) -- a future scene-assembly story wires this
## via `commit_pipeline.set_cell_set_resolver(block_tool.resolve_cell_set)`.
## Ignores [param _is_drag] and [param _release_cell] entirely -- see class
## doc comment for why only the press matters for a single-cell tool.
func resolve_cell_set(_is_drag: bool, press_cell: Vector3i, _release_cell: Vector3i) -> Array[Vector3i]:
	return BlockTool.block_cell_set(press_cell)


## GDD Core Rule 7 (pure, stateless -- exercisable directly with arbitrary
## values, mirroring [method FloorTool.floor_cell_set]'s established
## testable-pure-function shape, and reusable as-is by a future ghost-preview
## call site, Story 023, per the QA plan's forward-compatibility note):
## a block-tool commit is always exactly the one picked ATTACH cell.
static func block_cell_set(press_cell: Vector3i) -> Array[Vector3i]:
	return [press_cell]
