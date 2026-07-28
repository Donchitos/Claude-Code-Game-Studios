## Unit test — Building System Story building-024 (Wall tool: GDD Formula F1
## cell-set resolver + registration into CommitPipeline's per-tool seam).
## ADR-0016 primary (blueprint cells grouped into a project, not a grid
## write); ADR-0002 secondary (`wall_height` sourced from a typed `.tres`
## config, never hardcoded).
##
## Proves:
## 1. AC5 [TR-building-system-077]: a 5-cell axis-aligned wall drag at
##    `wall_height=3` yields exactly 15 cells.
## 2. AC6b [TR-building-system-077]: `start_cell == end_cell` via the
##    Dragging path (`is_drag=true`) yields exactly 1 column of
##    `wall_height` cells -- the SAME formula call as AC5, no separate
##    branch.
## 3. Edge case: a diagonal drag of equal |dx|/|dz| yields the identical run
##    length as an axis-aligned drag of the same displacement (Bresenham
##    determinism).
## 4. Edge case: `wall_height=1` yields exactly `line_length` cells.
## 5. `wall_height` is read from [WallToolConfig], never a hardcoded literal
##    in `wall_tool.gd` (ADR-0002).
## 6. [WallToolConfig]'s two-tier clamp+warn `validate()` policy.
## 7. One-action full-height extrude: [method WallTool.resolve_cell_set]
##    registered into [CommitPipeline] via
##    [method CommitPipeline.set_cell_set_resolver] creates every cell in a
##    SINGLE [method CommitPipeline.commit] call (one undo step, never
##    layer-by-layer).
## 8. Grep-guards (QA plan Sprint 8, Call-out 3): `wall_tool.gd` never
##    constructs a [BlueprintCell] directly, never calls a
##    [VoxelWorldGrid] write API, and carries no hardcoded `wall_height`
##    literal of its own.
class_name WallToolTest
extends GdUnitTestSuite

const WALL_TOOL_SOURCE_PATH: String = "res://src/building_system/wall_tool.gd"


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _new_tool(wall_height: int = 3) -> WallTool:
	var tool: WallTool = auto_free(WallTool.new())
	var config := WallToolConfig.new()
	config.wall_height = wall_height
	tool.config = config
	tool.setup()
	return tool


## Reads a single `.gd` source file, stripping full-line `#`/`##` doc-comment
## lines first -- mirrors this codebase's established
## `_read_gd_source_without_comments` precedent (`commit_pipeline_test.gd`)
## so a file's own doc comments (which legitimately NAME the banned APIs to
## document their absence) are never mistaken for a violation.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


# ---------------------------------------------------------------------------
# F1 -- pure static formula [TR-building-system-077]
# ---------------------------------------------------------------------------

func test_rasterize_run_axis_aligned_5_cell_drag_yields_5_cells() -> void:
	var run: Array[Vector3i] = WallTool.rasterize_run(Vector3i(0, 4, 0), Vector3i(4, 9, 0))

	# The run's Y is always anchored to press_cell's OWN Y (4), never
	# release_cell's (9) -- Core Rule 3's single-locked-plane guarantee.
	assert_array(run).is_equal([
		Vector3i(0, 4, 0), Vector3i(1, 4, 0), Vector3i(2, 4, 0), Vector3i(3, 4, 0), Vector3i(4, 4, 0),
	])


func test_rasterize_run_diagonal_equal_displacement_yields_same_run_length_as_axis_aligned() -> void:
	var axis_aligned: Array[Vector3i] = WallTool.rasterize_run(Vector3i(0, 4, 0), Vector3i(4, 4, 0))
	var diagonal: Array[Vector3i] = WallTool.rasterize_run(Vector3i(0, 4, 0), Vector3i(4, 4, 4))

	assert_int(diagonal.size()).is_equal(axis_aligned.size())
	assert_int(diagonal.size()).is_equal(5)


func test_rasterize_run_degenerate_start_equals_end_yields_single_cell() -> void:
	var run: Array[Vector3i] = WallTool.rasterize_run(Vector3i(2, 4, 2), Vector3i(2, 4, 2))

	assert_array(run).is_equal([Vector3i(2, 4, 2)])


func test_extrude_column_stacks_wall_height_cells_upward_from_the_base() -> void:
	var column: Array[Vector3i] = WallTool.extrude_column(Vector3i(1, 4, 1), 3)

	assert_array(column).is_equal([Vector3i(1, 4, 1), Vector3i(1, 5, 1), Vector3i(1, 6, 1)])


func test_wall_cell_set_5_cell_drag_at_height_3_yields_15_cells() -> void:
	# AC5: "a 5-cell wall drag at wall_height 3, WHEN committed, THEN exactly
	# 15 blueprint cells exist."
	var cells: Array[Vector3i] = WallTool.wall_cell_set(Vector3i(0, 4, 0), Vector3i(4, 4, 0), 3)

	assert_int(cells.size()).is_equal(15)
	# Every run cell contributes exactly wall_height=3 stacked cells.
	for x: int in range(5):
		for h: int in range(3):
			assert_bool(cells.has(Vector3i(x, 4 + h, 0))).is_true()


func test_wall_cell_set_height_1_yields_exactly_line_length_cells() -> void:
	var cells: Array[Vector3i] = WallTool.wall_cell_set(Vector3i(0, 4, 0), Vector3i(6, 4, 0), 1)

	assert_int(cells.size()).is_equal(7)


func test_wall_cell_set_degenerate_drag_yields_single_column_of_wall_height_cells() -> void:
	# F1's own documented degenerate: "start == end degenerates to 1 (single
	# column)".
	var cells: Array[Vector3i] = WallTool.wall_cell_set(Vector3i(5, 2, 5), Vector3i(5, 2, 5), 3)

	assert_array(cells).is_equal([Vector3i(5, 2, 5), Vector3i(5, 3, 5), Vector3i(5, 4, 5)])


# ---------------------------------------------------------------------------
# AC6b -- degenerate drag via the Dragging path, distinct from the click path
# ---------------------------------------------------------------------------

func test_resolve_cell_set_degenerate_drag_via_dragging_path_yields_single_column() -> void:
	# AC6b: "GIVEN a drag where cursor_travel_px >= drag_threshold_px but
	# start_cell == end_cell, WHEN committed, THEN exactly 1 column of
	# wall_height cells is created via the Dragging path."
	var tool: WallTool = _new_tool(3)

	var cells: Array[Vector3i] = tool.resolve_cell_set(true, Vector3i(5, 2, 5), Vector3i(5, 2, 5))

	assert_int(cells.size()).is_equal(3)
	assert_array(cells).is_equal([Vector3i(5, 2, 5), Vector3i(5, 3, 5), Vector3i(5, 4, 5)])


func test_resolve_cell_set_ignores_is_drag_flag_click_and_drag_agree() -> void:
	# A genuine click ([signal PlacementPick.build_committed]'s is_drag=false)
	# and the AC6b degenerate drag (is_drag=true) supply the SAME
	# press_cell==release_cell pair -- the formula must resolve identically
	# either way, with no separate click-path branch inside this class.
	var tool: WallTool = _new_tool(3)

	var click_path: Array[Vector3i] = tool.resolve_cell_set(false, Vector3i(5, 2, 5), Vector3i(5, 2, 5))
	var drag_path: Array[Vector3i] = tool.resolve_cell_set(true, Vector3i(5, 2, 5), Vector3i(5, 2, 5))

	assert_array(click_path).is_equal(drag_path)


# ---------------------------------------------------------------------------
# ADR-0002 -- wall_height is config-driven, never hardcoded
# ---------------------------------------------------------------------------

func test_resolve_cell_set_reads_wall_height_from_config() -> void:
	var tool: WallTool = _new_tool(5)

	var cells: Array[Vector3i] = tool.resolve_cell_set(true, Vector3i(0, 0, 0), Vector3i(0, 0, 0))

	assert_int(cells.size()).is_equal(5)


func test_wall_tool_config_wall_height_out_of_range_clamps_with_warning() -> void:
	var config := WallToolConfig.new()
	config.wall_height = 20

	var issues: Array[String] = config.validate()

	assert_int(config.wall_height).is_equal(WallToolConfig.WALL_HEIGHT_MAX)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("wall_height"))).is_true()


func test_wall_tool_config_default_wall_height_is_3() -> void:
	var config := WallToolConfig.new()

	assert_int(config.wall_height).is_equal(3)


# ---------------------------------------------------------------------------
# One-action full-height extrude, wired live into CommitPipeline's seam
# ---------------------------------------------------------------------------

func test_wired_into_commit_pipeline_creates_all_cells_in_one_commit_call() -> void:
	# Proves the "never layer-by-layer" requirement structurally: a single
	# CommitPipeline.commit() call (Story building-021/022's own established
	# entry point) creates every one of the wall's cells at once, mirroring
	# commit_pipeline_test.gd's own "custom resolver overrides the default"
	# precedent.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	grid.set_cell(Vector3i(5, 3, 5), CellContents.new(1, 0))

	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"wall")

	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = auto_free(CameraInput.new())
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	pipeline.set_selected_item(&"placeholder_material")

	var wall_tool: WallTool = _new_tool(3)
	pipeline.set_cell_set_resolver(wall_tool.resolve_cell_set)

	var received: Array = []
	pipeline.blueprint_cells_created.connect(func(cells: Array[BlueprintCell]) -> void: received.append(cells))

	# Act -- a single drag-release trigger, mirroring
	# CommitPipeline._on_build_committed's own live wiring.
	pipeline._on_build_committed(true, Vector3i(0, 4, 0), Vector3i(4, 4, 0))

	# Assert -- exactly one signal emission (one commit, one undo step) with
	# all 15 cells present (5-cell run x wall_height 3), never a partial or
	# per-layer sequence.
	assert_int(received.size()).is_equal(1)
	var cells: Array = received[0]
	assert_int(cells.size()).is_equal(15)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(15)


# ---------------------------------------------------------------------------
# Grep-guards (QA plan Sprint 8, Call-out 3)
# ---------------------------------------------------------------------------

func test_wall_tool_never_constructs_a_blueprint_cell_directly() -> void:
	var source: String = _read_gd_source_without_comments(WALL_TOOL_SOURCE_PATH)

	assert_bool(source.contains("BlueprintCell.new(")).is_false()


func test_wall_tool_never_calls_a_voxel_world_write_api() -> void:
	var source: String = _read_gd_source_without_comments(WALL_TOOL_SOURCE_PATH)

	assert_bool(source.contains("set_cell(")).is_false()
	assert_bool(source.contains("bulk_write(")).is_false()
	assert_bool(source.contains("clear_cell(")).is_false()


func test_wall_tool_carries_no_hardcoded_wall_height_literal() -> void:
	# ADR-0002: wall_height is [WallToolConfig]'s own field -- wall_tool.gd
	# must only ever READ config.wall_height, never declare/default one
	# itself.
	var source: String = _read_gd_source_without_comments(WALL_TOOL_SOURCE_PATH)

	assert_bool(source.contains("var wall_height")).is_false()
	assert_bool(source.contains("const WALL_HEIGHT")).is_false()
	assert_bool(source.contains("config.wall_height")).is_true()
