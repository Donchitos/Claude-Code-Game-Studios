## Unit test — Building System Story building-027 (Block tool: GDD Core Rule
## 7 single-cell place formula + registration into CommitPipeline's per-tool
## seam). ADR-0016 primary (blueprint cells grouped into a project, not a
## grid write).
##
## **Sprint 8 scope: place mode only** (Call-out 2, Sprint 8 QA plan). AC2
## (remove mode -> Story 031/015 routing) is explicitly out-of-scope-by-design
## this sprint -- Story 031 is not scheduled and no removal-tool base exists
## in this codebase yet, so it is untested-by-design here, not a missing-
## evidence gap.
##
## Proves:
## 1. GDD Core Rule 7 [TR-building-system-047]: a valid pick places exactly
##    one blueprint cell -- the picked ATTACH cell, always.
## 2. [method BlockTool.resolve_cell_set] ignores its own `is_drag` parameter
##    AND `release_cell` entirely -- only `press_cell` (the ATTACH cell)
##    matters, mirroring [WallTool]/[FloorTool]'s established "click and drag
##    paths agree" precedent, extended here to also ignore `release_cell`.
## 3. Attach to a terrain cell's face is valid (Core Rule 3) -- re-exercised
##    through [BlockTool]'s own resolver wired into [CommitPipeline]
##    (Story building-022's existing validity gate, not re-implemented here).
## 4. Replace-in-place of an already-BUILT (player-constructed) cell is valid
##    -- re-exercised through [BlockTool]'s own resolver, mirroring
##    `placement_validity_test.gd`'s identical precedent.
## 5. Replace-in-place of terrain is rejected -- re-exercised through
##    [BlockTool]'s own resolver; zero blueprint cells created,
##    [signal CommitPipeline.commit_rejected] fires with
##    [constant CommitPipeline.RejectReason.CELL_OCCUPIED].
## 6. Grep-guards (QA plan Sprint 8, Call-out 3): `block_tool.gd` never
##    constructs a [BlueprintCell] directly and never calls a
##    [VoxelWorldGrid] write API.
class_name BlockToolTest
extends GdUnitTestSuite

const BLOCK_TOOL_SOURCE_PATH: String = "res://src/building_system/block_tool.gd"


# ---------------------------------------------------------------------------
# Test helpers (mirrors floor_tool_test.gd / placement_validity_test.gd's
# established precedent)
# ---------------------------------------------------------------------------

## Reads a single `.gd` source file, stripping full-line `#`/`##` doc-comment
## lines first -- mirrors this codebase's established
## `_read_gd_source_without_comments` precedent (`wall_tool_test.gd`,
## `floor_tool_test.gd`, `commit_pipeline_test.gd`) so a file's own doc
## comments (which legitimately NAME the banned APIs to document their
## absence) are never mistaken for a violation.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


func _new_grid_with_solid_cell(cell: Vector3i) -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	grid.set_cell(cell, CellContents.new(1, 0))
	return grid


func _new_machine_armed() -> ToolStateMachine:
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"block")
	return machine


func _new_pick(grid: VoxelWorldGrid, machine: ToolStateMachine) -> PlacementPick:
	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = auto_free(CameraInput.new())
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	return pick


## Builds a pipeline with [BlockTool]'s own resolver already registered
## (mirrors `wall_tool_test.gd`/`floor_tool_test.gd`'s "wired into commit
## pipeline" precedent) and a placeholder material selected (Core Rule 9's
## material-availability gate, orthogonal to this story's own scope).
func _new_pipeline_with_block_tool(pick: PlacementPick, grid: VoxelWorldGrid) -> CommitPipeline:
	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	pipeline.set_selected_item(&"placeholder_material")
	var block_tool: BlockTool = auto_free(BlockTool.new())
	pipeline.set_cell_set_resolver(block_tool.resolve_cell_set)
	return pipeline


func _connect_rejection_listener(pipeline: CommitPipeline) -> Array:
	var received: Array = []
	pipeline.commit_rejected.connect(
		func(reason: CommitPipeline.RejectReason, cells: Array[Vector3i]) -> void:
			received.append([reason, cells])
	)
	return received


# ---------------------------------------------------------------------------
# GDD Core Rule 7 -- pure static formula [TR-building-system-047]
# ---------------------------------------------------------------------------

func test_block_cell_set_returns_exactly_the_press_cell() -> void:
	var cells: Array[Vector3i] = BlockTool.block_cell_set(Vector3i(3, 4, 5))

	assert_array(cells).is_equal([Vector3i(3, 4, 5)])


func test_resolve_cell_set_ignores_is_drag_and_release_cell() -> void:
	# A block-tool "drag" carries no distinct meaning from a click -- only
	# press_cell (the ATTACH cell) matters, mirroring WallTool/FloorTool's
	# "click and drag paths agree" precedent, extended here to also ignore
	# release_cell entirely.
	var tool: BlockTool = auto_free(BlockTool.new())

	var click_path: Array[Vector3i] = tool.resolve_cell_set(false, Vector3i(1, 2, 3), Vector3i(1, 2, 3))
	var drag_path: Array[Vector3i] = tool.resolve_cell_set(true, Vector3i(1, 2, 3), Vector3i(9, 9, 9))

	assert_array(click_path).is_equal([Vector3i(1, 2, 3)])
	assert_array(drag_path).is_equal([Vector3i(1, 2, 3)])
	assert_array(click_path).is_equal(drag_path)


# ---------------------------------------------------------------------------
# Wired into CommitPipeline -- attach vs. replace-in-place (Core Rule 3),
# re-exercised (not re-implemented) through BlockTool's own resolver
# ---------------------------------------------------------------------------

func test_wired_into_commit_pipeline_attach_to_a_terrain_cells_face_is_valid() -> void:
	# Arrange -- a terrain cell at (2,0,2); the ATTACH target is the adjacent
	# EMPTY cell (2,1,2), never the terrain cell itself (mirrors
	# placement_validity_test.gd's identical precedent, re-exercised here
	# through BlockTool's own resolver).
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	grid.set_cell(Vector3i(2, 0, 2), CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline_with_block_tool(pick, grid)

	# Act -- a single click-release trigger, mirroring
	# CommitPipeline._on_build_committed's own live wiring.
	pipeline._on_build_committed(false, Vector3i(2, 1, 2), Vector3i(2, 1, 2))

	# Assert -- exactly one blueprint cell created at the attach cell.
	assert_bool(pipeline.has_blueprint_cell(Vector3i(2, 1, 2))).is_true()
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(1)


func test_wired_into_commit_pipeline_replace_in_place_of_an_already_built_cell_is_valid() -> void:
	# Arrange -- commit, then simulate ConstructionTickLoop's own completion
	# contract directly on the shared BlueprintCell reference (mirrors
	# construction_tick_loop.gd's own `_complete_job` and
	# placement_validity_test.gd's identical precedent).
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline_with_block_tool(pick, grid)
	pipeline._on_build_committed(false, Vector3i(7, 0, 7), Vector3i(7, 0, 7))
	var built_cell: BlueprintCell = pipeline.get_blueprint_cells()[0]
	grid.set_cell(built_cell.cell, built_cell.contents)
	built_cell.state = BlueprintCell.MicroState.BUILT

	# Act -- a fresh commit replaces the SAME now-Built cell.
	pipeline._on_build_committed(false, Vector3i(7, 0, 7), Vector3i(7, 0, 7))

	# Assert -- valid: a new (second) BlueprintCell now tracks that address,
	# in the PLANNED micro-state again.
	var replaced: BlueprintCell = pipeline.get_blueprint_cells().filter(
		func(cell: BlueprintCell) -> bool: return cell.cell == Vector3i(7, 0, 7)
	)[0]
	assert_int(replaced.state).is_equal(BlueprintCell.MicroState.PLANNED)


func test_wired_into_commit_pipeline_replace_in_place_of_terrain_is_rejected() -> void:
	# Arrange -- a terrain cell at (2,0,2), never tracked by this pipeline
	# (no commit ever ran through it) -- exactly how CommitPipeline
	# distinguishes terrain from a cell it built itself.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	grid.set_cell(Vector3i(2, 0, 2), CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline_with_block_tool(pick, grid)
	var rejected: Array = _connect_rejection_listener(pipeline)

	# Act -- replace-in-place targets the terrain cell itself.
	pipeline._on_build_committed(false, Vector3i(2, 0, 2), Vector3i(2, 0, 2))

	# Assert -- rejected in full; zero blueprint cells created.
	assert_int(rejected.size()).is_equal(1)
	assert_int(rejected[0][0]).is_equal(CommitPipeline.RejectReason.CELL_OCCUPIED)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)


# ---------------------------------------------------------------------------
# Grep-guards (QA plan Sprint 8, Call-out 3)
# ---------------------------------------------------------------------------

func test_block_tool_never_constructs_a_blueprint_cell_directly() -> void:
	var source: String = _read_gd_source_without_comments(BLOCK_TOOL_SOURCE_PATH)

	assert_bool(source.contains("BlueprintCell.new(")).is_false()


func test_block_tool_never_calls_a_voxel_world_write_api() -> void:
	var source: String = _read_gd_source_without_comments(BLOCK_TOOL_SOURCE_PATH)

	assert_bool(source.contains("set_cell(")).is_false()
	assert_bool(source.contains("bulk_write(")).is_false()
	assert_bool(source.contains("clear_cell(")).is_false()
