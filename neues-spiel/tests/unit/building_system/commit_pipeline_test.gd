## Unit test — Building System Story building-021 (Commit pipeline:
## click-vs-drag discrimination + bounds clamp, pick -> preview -> commit).
## ADR-0016 primary (blueprint cells, not grid writes); ADR-0010 secondary
## (drag-ownership release as the commit trigger).
##
## Proves:
## 1. GDD Formula F4 [TR-building-system-081] (AC6): [method
##    PlacementPick.is_drag]'s pure threshold comparison, including the
##    exactly-at-threshold edge case, PLUS the same discrimination live
##    through a real press/release input flow.
## 2. AC4 [TR-building-system-002]: [method CommitPipeline.commit] creates
##    EXACTLY the candidate cells it's given as [BlueprintCell]s, and never
##    calls a Voxel World write API.
## 3. AC9 [TR-building-system-083] (Edge Case 1): a candidate set straddling
##    world bounds commits only the in-bounds portion; an entirely
##    out-of-bounds set commits nothing.
## 4. AC38 [TR-building-system-086] (Edge Case 4): no valid pick -> commit is
##    a no-op, regardless of the candidate cells supplied.
## 5. The default (placeholder) per-tool cell-set resolver's click/drag
##    branches, and that a custom resolver ([method
##    CommitPipeline.set_cell_set_resolver]) overrides it entirely.
## 6. [signal PlacementPick.build_committed] never fires on an aborted drag
##    (Suspended/cancel/re-arm mid-drag) -- no commit results.
class_name CommitPipelineTest
extends GdUnitTestSuite

const BUILDING_SYSTEM_DIR: String = "res://src/building_system/"
const COMMIT_PIPELINE_SOURCE_PATH: String = "res://src/building_system/commit_pipeline.gd"


# ---------------------------------------------------------------------------
# Test helpers (mirrors dda_placement_pick_test.gd's established precedent)
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_grid_with_solid_cell(cell: Vector3i) -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _new_grid()
	grid.set_cell(cell, CellContents.new(1, 0))
	return grid


func _new_machine_armed() -> ToolStateMachine:
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"wall")
	return machine


func _new_pick(grid: VoxelWorldGrid, machine: ToolStateMachine) -> PlacementPick:
	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = auto_free(CameraInput.new())
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	return pick


func _new_pipeline(pick: PlacementPick, grid: VoxelWorldGrid) -> CommitPipeline:
	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	# Story building-022's material-selection gate (AC42) is out of THIS
	# story's own scope -- select a placeholder item so every pre-existing
	# 021 test keeps exercising discrimination/clamp behavior unaffected.
	# `resource_item_database` stays unwired (null) here -- see
	# `CommitPipeline._is_selected_item_available`'s documented MVP fallback:
	# a non-empty selection is trusted at face value when no RID reference is
	# reachable, exactly the case for this bare test construction.
	pipeline.set_selected_item(&"placeholder_material")
	return pipeline


## Reads a single `.gd` source file, stripping full-line `#`/`##` doc-comment
## lines first -- mirrors this codebase's established
## `_read_gd_source_without_comments` precedent (`dda_placement_pick_test.gd`)
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
# GDD Formula F4 -- click-vs-drag discrimination [TR-building-system-081]
# ---------------------------------------------------------------------------

func test_is_drag_below_threshold_is_a_click() -> void:
	assert_bool(PlacementPick.is_drag(5.0, 6.0)).is_false()


func test_is_drag_exactly_at_threshold_takes_the_drag_path() -> void:
	# AC6 edge case -- exactly-at-threshold is a drag, never a click.
	assert_bool(PlacementPick.is_drag(6.0, 6.0)).is_true()


func test_is_drag_above_threshold_is_a_drag() -> void:
	assert_bool(PlacementPick.is_drag(50.0, 6.0)).is_true()


# ---------------------------------------------------------------------------
# AC4 -- commit matches the candidate set exactly; zero grid writes
# ---------------------------------------------------------------------------

func test_commit_creates_exactly_the_candidate_cells() -> void:
	# Arrange -- a valid pick is required (AC38 gate); the candidate cell set
	# is supplied directly, mirroring how a future tool story (024-028) would
	# call this same entry point with its own real formula's output.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var candidates: Array[Vector3i] = [Vector3i(1, 0, 1), Vector3i(2, 0, 1), Vector3i(3, 0, 1)]

	# Act
	var created: Array[BlueprintCell] = pipeline.commit(candidates)

	# Assert -- exactly N cells created, matching the candidate set exactly,
	# and no cell was actually written into the grid (blueprint cells stay
	# invisible to Voxel World's data layer, Core Rule 11).
	assert_int(created.size()).is_equal(3)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(3)
	for cell: Vector3i in candidates:
		assert_bool(pipeline.has_blueprint_cell(cell)).is_true()
		assert_bool(grid.get_cell(cell).is_empty()).is_true()


func test_commit_emits_blueprint_cells_created_with_the_created_cells() -> void:
	# Arrange -- direct signal listener (GdUnitSignalAssert is unreliable for
	# a sole-Array-param signal; this project's established workaround).
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var received: Array = []
	pipeline.blueprint_cells_created.connect(func(cells: Array[BlueprintCell]) -> void: received.append(cells))

	# Act
	pipeline.commit([Vector3i(1, 0, 1)])

	# Assert
	assert_int(received.size()).is_equal(1)
	var cells: Array = received[0]
	assert_int(cells.size()).is_equal(1)
	var created_cell: BlueprintCell = cells[0]
	assert_bool(created_cell.cell == Vector3i(1, 0, 1)).is_true()
	assert_int(created_cell.state).is_equal(BlueprintCell.MicroState.PLANNED)


# ---------------------------------------------------------------------------
# AC9 -- bounds clamp (Edge Case 1) [TR-building-system-083]
# ---------------------------------------------------------------------------

func test_commit_clamps_to_only_the_in_bounds_portion() -> void:
	# Arrange -- one in-bounds cell, one structurally out-of-bounds cell
	# (negative x is always invalid regardless of any config clamp range,
	# Core Rule 1 "no negative cell coordinates ever exist").
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(2, 0, 2), Vector3i(-4, 0, -4)])

	# Assert -- only the in-bounds portion is created (Edge Case 1).
	assert_int(created.size()).is_equal(1)
	assert_bool(pipeline.has_blueprint_cell(Vector3i(2, 0, 2))).is_true()
	assert_bool(pipeline.has_blueprint_cell(Vector3i(-4, 0, -4))).is_false()


func test_commit_entirely_out_of_bounds_creates_nothing() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var received: Array = []
	pipeline.blueprint_cells_created.connect(func(cells: Array[BlueprintCell]) -> void: received.append(cells))

	# Act -- a drag entirely out of bounds.
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(-1, 0, -1), Vector3i(-2, 0, -2)])

	# Assert -- commits nothing at all: no cell, no signal.
	assert_int(created.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)
	assert_int(received.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC38 -- no valid pick is a no-op (Edge Case 4) [TR-building-system-086]
# ---------------------------------------------------------------------------

func test_commit_with_no_valid_pick_is_a_no_op() -> void:
	# Arrange -- an entirely empty grid; [method PlacementPick.resolve_pick]
	# is never called, so `_current_pick` stays the default explicit miss.
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var received: Array = []
	pipeline.blueprint_cells_created.connect(func(cells: Array[BlueprintCell]) -> void: received.append(cells))

	# Act -- even a perfectly in-bounds candidate set is rejected.
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1)])

	# Assert
	assert_int(created.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)
	assert_int(received.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Default (placeholder) per-tool cell-set resolver + override seam
# ---------------------------------------------------------------------------

func test_default_resolver_click_path_commits_only_the_press_cell() -> void:
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)

	pipeline._on_build_committed(false, Vector3i(1, 0, 1), Vector3i(9, 0, 9))

	assert_int(pipeline.get_blueprint_cells().size()).is_equal(1)
	assert_bool(pipeline.has_blueprint_cell(Vector3i(1, 0, 1))).is_true()
	assert_bool(pipeline.has_blueprint_cell(Vector3i(9, 0, 9))).is_false()


func test_default_resolver_drag_path_commits_press_and_release_cells() -> void:
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)

	pipeline._on_build_committed(true, Vector3i(1, 0, 1), Vector3i(9, 0, 9))

	assert_int(pipeline.get_blueprint_cells().size()).is_equal(2)
	assert_bool(pipeline.has_blueprint_cell(Vector3i(1, 0, 1))).is_true()
	assert_bool(pipeline.has_blueprint_cell(Vector3i(9, 0, 9))).is_true()


func test_custom_cell_set_resolver_overrides_the_default() -> void:
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	pipeline.set_cell_set_resolver(
		func(_is_drag: bool, _press_cell: Vector3i, _release_cell: Vector3i) -> Array[Vector3i]:
			return [Vector3i(7, 0, 7), Vector3i(8, 0, 8)]
	)

	pipeline._on_build_committed(false, Vector3i(1, 0, 1), Vector3i(1, 0, 1))

	assert_int(pipeline.get_blueprint_cells().size()).is_equal(2)
	assert_bool(pipeline.has_blueprint_cell(Vector3i(7, 0, 7))).is_true()
	assert_bool(pipeline.has_blueprint_cell(Vector3i(8, 0, 8))).is_true()
	assert_bool(pipeline.has_blueprint_cell(Vector3i(1, 0, 1))).is_false()


# ---------------------------------------------------------------------------
# Full live flow -- real press/release through PlacementPick, proving the
# actual [signal PlacementPick.build_committed] wiring end-to-end
# ---------------------------------------------------------------------------

## Shared rig mirroring dda_placement_pick_test.gd's own
## `test_press_with_valid_pick_starts_drag_then_release_completes_it` --
## a real [CameraInput] inside a fixed-size [SubViewport], rotated to a
## reproducible yaw so a screen-center ray reliably hits a filled slab.
func _new_live_rig() -> Dictionary:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 100
	config.world_depth_cells = 100
	grid.config = config
	grid.setup()
	var changes: Dictionary[Vector3i, CellContents] = {}
	for x in 100:
		for z in 100:
			changes[Vector3i(x, 0, z)] = CellContents.new(1, 0)
	grid.bulk_write(changes)

	var machine: ToolStateMachine = _new_machine_armed()

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1000, 1000)
	add_child(viewport)
	auto_free(viewport)

	var camera: CameraInput = CameraInput.new()
	var camera_config := CameraInputConfig.new()
	camera.config = camera_config
	camera.setup()
	viewport.add_child(camera)
	var yaw_delta: float = PI - camera_config.start_yaw
	var rotate_event := InputEventMouseMotion.new()
	rotate_event.relative = Vector2(yaw_delta / camera_config.mouse_drag_sensitivity, 0.0)
	rotate_event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	camera._unhandled_input(rotate_event)

	var pick := PlacementPick.new()
	pick.camera_input = camera
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	viewport.add_child(pick)
	auto_free(pick)

	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	# See `_new_pipeline`'s own comment -- Story building-022's material gate
	# is out of this file's scope; select a placeholder so the live-flow
	# tests below keep proving discrimination/commit wiring unaffected.
	pipeline.set_selected_item(&"placeholder_material")

	return {"grid": grid, "machine": machine, "pick": pick, "pipeline": pipeline}


func test_full_flow_click_below_threshold_commits_the_click_path() -> void:
	# Arrange
	var rig: Dictionary = _new_live_rig()
	var pick: PlacementPick = rig["pick"]
	var pipeline: CommitPipeline = rig["pipeline"]
	var received: Array = []
	pipeline.blueprint_cells_created.connect(func(cells: Array[BlueprintCell]) -> void: received.append(cells))

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(500, 500)

	# Act -- press then release at the SAME screen position (a click, 0px
	# travel, well below the default 6px threshold).
	pick._unhandled_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(500, 500)
	pick._input(release)

	# Assert -- exactly one blueprint cell created (the default resolver's
	# click path -- one cell only), never the two-cell drag path.
	assert_int(received.size()).is_equal(1)
	var cells: Array = received[0]
	assert_int(cells.size()).is_equal(1)


func test_full_flow_drag_at_or_above_threshold_reports_is_drag_true() -> void:
	# Arrange -- listens directly to [signal PlacementPick.build_committed]
	# (rather than through the pipeline's created-cell COUNT): the picked
	# CELL at release time tracks [CameraInput]'s live ray, which in this
	# headless rig is a function of camera orientation only (never updated
	# here, matching the click test's own press==release cell outcome) --
	# NOT of the synthetic screen `.position` on a manually constructed
	# [InputEventMouseButton]. `is_drag` itself, however, is computed purely
	# from those two screen positions (this story's own F4 formula) and is
	# exactly what this test proves, independent of that ray-tracking
	# limitation.
	var rig: Dictionary = _new_live_rig()
	var pick: PlacementPick = rig["pick"]
	var received: Array = []
	pick.build_committed.connect(
		func(is_drag: bool, _press_cell: Vector3i, _release_cell: Vector3i) -> void: received.append(is_drag)
	)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(500, 500)

	# Act -- press then release far enough away to exceed the default 6px
	# drag_threshold_px.
	pick._unhandled_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(600, 600)
	pick._input(release)

	# Assert -- the live wiring correctly reports a drag, not a click.
	assert_int(received.size()).is_equal(1)
	assert_bool(received[0]).is_true()


func test_full_flow_aborted_drag_never_commits() -> void:
	# Arrange -- a press starts the drag, then the tool machine aborts it
	# directly (mirrors Suspended entry / cancel / re-arm mid-drag) BEFORE
	# any release reaches [method PlacementPick._input] -- [signal
	# PlacementPick.build_committed] must never fire.
	var rig: Dictionary = _new_live_rig()
	var machine: ToolStateMachine = rig["machine"]
	var pick: PlacementPick = rig["pick"]
	var pipeline: CommitPipeline = rig["pipeline"]
	var received: Array = []
	pipeline.blueprint_cells_created.connect(func(cells: Array[BlueprintCell]) -> void: received.append(cells))

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(500, 500)

	# Act
	pick._unhandled_input(press)
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.DRAGGING)
	machine.cancel()

	# Assert -- no commit of any kind resulted from the aborted drag.
	assert_int(received.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)


# ---------------------------------------------------------------------------
# Zero grid-write / zero physics guardrail (mirrors Story 020's own
# `dda_placement_pick_test.gd` precedent)
# ---------------------------------------------------------------------------

func test_commit_pipeline_never_calls_a_voxel_world_write_api() -> void:
	# The commit pipeline MUST stay a blueprint-only write path -- Core Rule
	# 11: blueprint cells are "invisible to Voxel World's data layer."
	var source: String = _read_gd_source_without_comments(COMMIT_PIPELINE_SOURCE_PATH)

	assert_bool(source.contains("set_cell(")).is_false()
	assert_bool(source.contains("bulk_write(")).is_false()
	assert_bool(source.contains("clear_cell(")).is_false()


func test_no_physics_apis_anywhere_in_building_system_source() -> void:
	# Grep-verifiable AC (Control Manifest / ADR-0004): zero physics API
	# usage anywhere in this system's source, including the new files this
	# story adds.
	var banned_substrings: Array[String] = [
		"intersect_ray",
		"PhysicsServer3D",
		"RayCast3D",
		"PhysicsDirectSpaceState3D",
		"PhysicsRayQueryParameters3D",
	]
	var dir := DirAccess.open(BUILDING_SYSTEM_DIR)
	assert_object(dir).is_not_null()
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var checked_at_least_one_file: bool = false
	while file_name != "":
		if file_name.ends_with(".gd"):
			checked_at_least_one_file = true
			var source: String = _read_gd_source_without_comments(BUILDING_SYSTEM_DIR + file_name)
			for banned: String in banned_substrings:
				assert_bool(source.contains(banned)).is_false()
		file_name = dir.get_next()
	dir.list_dir_end()
	assert_bool(checked_at_least_one_file).is_true()


# ---------------------------------------------------------------------------
# Config (ADR-0002 two-tier policy) -- drag_threshold_px (this story's own
# new tuning knob on PlacementPickConfig)
# ---------------------------------------------------------------------------

func test_drag_threshold_px_out_of_range_clamps_with_warning() -> void:
	# Arrange
	var config := PlacementPickConfig.new()
	config.drag_threshold_px = 1.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_float(config.drag_threshold_px).is_equal_approx(
		PlacementPickConfig.DRAG_THRESHOLD_PX_MIN, 0.0001
	)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("drag_threshold_px"))).is_true()
