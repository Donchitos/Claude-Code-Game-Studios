## Unit test — Building System Story building-025 (Floor tool: GDD Formula F2
## cell-set resolver + registration into CommitPipeline's per-tool seam).
## ADR-0016 primary (blueprint cells grouped into a project, not a grid
## write).
##
## Proves:
## 1. AC7 [TR-building-system-078]: a floor drag of 3 cells in x and 4 in z
##    yields exactly 20 blueprint cells (4 x 5).
## 2. Edge case: a zero-length drag degenerates to a single 1x1 tile.
## 3. The locked-plane Y-anchor discipline: every returned cell uses
##    press_cell's OWN Y, never release_cell's -- mirrors
##    [WallTool.rasterize_run]'s identical precedent.
## 4. One-cell-thick on the locked plane -- never stacked, never on the
##    ground plane by default (QA plan edge case).
## 5. Reversed drag direction (release below/behind press in x/z) yields the
##    identical cell set -- the rectangle is direction-agnostic.
## 6. [method FloorTool.resolve_cell_set] ignores its own `is_drag`
##    parameter -- click and drag paths agree, mirroring [WallTool]'s AC6b
##    precedent.
## 7. One-action fill, wired live into [CommitPipeline]: a single
##    [method CommitPipeline.commit] call creates every cell at once (never
##    row-by-row), and Story 022's own `max_cells_per_command` cap rejects an
##    oversized floor outright (re-exercised here, not re-implemented).
## 8. Grep-guards (QA plan Sprint 8, Call-out 3): `floor_tool.gd` never
##    constructs a [BlueprintCell] directly and never calls a
##    [VoxelWorldGrid] write API.
class_name FloorToolTest
extends GdUnitTestSuite

const FLOOR_TOOL_SOURCE_PATH: String = "res://src/building_system/floor_tool.gd"


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads a single `.gd` source file, stripping full-line `#`/`##` doc-comment
## lines first -- mirrors this codebase's established
## `_read_gd_source_without_comments` precedent (`wall_tool_test.gd`,
## `commit_pipeline_test.gd`) so a file's own doc comments (which legitimately
## NAME the banned APIs to document their absence) are never mistaken for a
## violation.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


# ---------------------------------------------------------------------------
# F2 -- pure static formula [TR-building-system-078]
# ---------------------------------------------------------------------------

func test_floor_cell_set_3_in_x_and_4_in_z_yields_20_cells() -> void:
	# AC7 / GDD's own worked example: "dragging 3 cells in x and 4 in z ->
	# 4 x 5 = 20 blueprint cells."
	var cells: Array[Vector3i] = FloorTool.floor_cell_set(Vector3i(0, 4, 0), Vector3i(3, 4, 4))

	assert_int(cells.size()).is_equal(20)
	for x: int in range(4):
		for z: int in range(5):
			assert_bool(cells.has(Vector3i(x, 4, z))).is_true()


func test_floor_cell_set_zero_length_drag_yields_single_1x1_tile() -> void:
	var cells: Array[Vector3i] = FloorTool.floor_cell_set(Vector3i(5, 2, 5), Vector3i(5, 2, 5))

	assert_array(cells).is_equal([Vector3i(5, 2, 5)])


func test_floor_cell_set_locked_to_press_cell_y_never_release_cell_y() -> void:
	# The run's Y is always anchored to press_cell's OWN Y (4), never
	# release_cell's (9) -- Core Rule 3's single-locked-plane guarantee,
	# mirroring WallTool.rasterize_run's identical precedent.
	var cells: Array[Vector3i] = FloorTool.floor_cell_set(Vector3i(0, 4, 0), Vector3i(2, 9, 2))

	assert_int(cells.size()).is_equal(9)
	for cell: Vector3i in cells:
		assert_int(cell.y).is_equal(4)


func test_floor_cell_set_one_cell_thick_never_stacked_and_never_on_ground_plane_by_default() -> void:
	# QA plan edge case: "all cells lie one-thick on that plane, never
	# stacked or on the ground plane" -- exercised at y > 0 (a drag started
	# on a block, not the ground).
	var cells: Array[Vector3i] = FloorTool.floor_cell_set(Vector3i(0, 5, 0), Vector3i(2, 5, 1))

	assert_int(cells.size()).is_equal(6)
	var distinct_y: Array[int] = []
	for cell: Vector3i in cells:
		if not distinct_y.has(cell.y):
			distinct_y.append(cell.y)
	assert_array(distinct_y).is_equal([5])
	assert_int(distinct_y[0]).is_not_equal(0)


func test_floor_cell_set_reversed_drag_direction_yields_the_same_rectangle() -> void:
	# The rectangle is built from min/max, not press-as-origin -- a drag
	# ending up-and-left of its start yields the identical cell set as the
	# AC7 example dragged the other way.
	var cells: Array[Vector3i] = FloorTool.floor_cell_set(Vector3i(3, 4, 4), Vector3i(0, 4, 0))

	assert_int(cells.size()).is_equal(20)
	for x: int in range(4):
		for z: int in range(5):
			assert_bool(cells.has(Vector3i(x, 4, z))).is_true()


# ---------------------------------------------------------------------------
# resolve_cell_set -- ignores is_drag entirely
# ---------------------------------------------------------------------------

func test_resolve_cell_set_ignores_is_drag_flag_click_and_drag_agree() -> void:
	# A genuine click (is_drag=false) and a real drag (is_drag=true) supply
	# the SAME press/release pair -- the formula must resolve identically
	# either way, with no separate click-path branch inside this class
	# (mirrors WallTool's identical AC6b precedent).
	var tool: FloorTool = auto_free(FloorTool.new())

	var click_path: Array[Vector3i] = tool.resolve_cell_set(false, Vector3i(0, 4, 0), Vector3i(2, 4, 3))
	var drag_path: Array[Vector3i] = tool.resolve_cell_set(true, Vector3i(0, 4, 0), Vector3i(2, 4, 3))

	assert_array(click_path).is_equal(drag_path)
	assert_int(click_path.size()).is_equal(12)


# ---------------------------------------------------------------------------
# One-action fill, wired live into CommitPipeline's seam
# ---------------------------------------------------------------------------

func test_wired_into_commit_pipeline_creates_all_cells_in_one_commit_call() -> void:
	# Proves the "one commit, one undo step" invariant structurally,
	# mirroring wall_tool_test.gd's own precedent: a single
	# CommitPipeline.commit() call (Story building-021/022's own established
	# entry point) creates every one of the floor's cells at once, never a
	# row-by-row sequence.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	grid.set_cell(Vector3i(5, 3, 5), CellContents.new(1, 0))

	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"floor")

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

	var floor_tool: FloorTool = auto_free(FloorTool.new())
	pipeline.set_cell_set_resolver(floor_tool.resolve_cell_set)

	var received: Array = []
	pipeline.blueprint_cells_created.connect(func(cells: Array[BlueprintCell]) -> void: received.append(cells))

	# Act -- a single drag-release trigger at the GDD's own F2 example: 3
	# cells in x, 4 in z.
	pipeline._on_build_committed(true, Vector3i(0, 4, 0), Vector3i(3, 4, 4))

	# Assert -- exactly one signal emission (one commit, one undo step) with
	# all 20 cells present (AC7), never a partial or per-row sequence.
	assert_int(received.size()).is_equal(1)
	var cells: Array = received[0]
	assert_int(cells.size()).is_equal(20)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(20)


func test_wired_into_commit_pipeline_drag_exceeding_cap_is_rejected_with_zero_cells_created() -> void:
	# Story 022's own max_cells_per_command cap (default 512), re-exercised
	# here through FloorTool's real F2 rectangle -- not re-implemented. A
	# 23x23 rectangle (529 cells) exceeds the default cap by 17.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	grid.set_cell(Vector3i(5, 3, 5), CellContents.new(1, 0))

	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"floor")

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

	var floor_tool: FloorTool = auto_free(FloorTool.new())
	pipeline.set_cell_set_resolver(floor_tool.resolve_cell_set)

	var rejected_reasons: Array[int] = []
	pipeline.commit_rejected.connect(
		func(reason: CommitPipeline.RejectReason, _cells: Array[Vector3i]) -> void: rejected_reasons.append(reason)
	)

	pipeline._on_build_committed(true, Vector3i(0, 4, 0), Vector3i(22, 4, 22))

	assert_int(rejected_reasons.size()).is_equal(1)
	assert_int(rejected_reasons[0]).is_equal(CommitPipeline.RejectReason.CELL_COUNT_EXCEEDS_CAP)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)


# ---------------------------------------------------------------------------
# Grep-guards (QA plan Sprint 8, Call-out 3)
# ---------------------------------------------------------------------------

func test_floor_tool_never_constructs_a_blueprint_cell_directly() -> void:
	var source: String = _read_gd_source_without_comments(FLOOR_TOOL_SOURCE_PATH)

	assert_bool(source.contains("BlueprintCell.new(")).is_false()


func test_floor_tool_never_calls_a_voxel_world_write_api() -> void:
	var source: String = _read_gd_source_without_comments(FLOOR_TOOL_SOURCE_PATH)

	assert_bool(source.contains("set_cell(")).is_false()
	assert_bool(source.contains("bulk_write(")).is_false()
	assert_bool(source.contains("clear_cell(")).is_false()
