## Unit test — Building System Story building-012 (Floor-excavation flush
## replace + `restore_value` capture, GDD Rule 14l, ADR-0016 primary).
## [TR-building-system-120].
##
## Proves:
## 1. AC69: a floor-tool drag whose press cell sits directly above raw,
##    untracked terrain is committed FLUSH at the terrain cell's own address
##    (never stacked one cell above it), and the terrain's exact original
##    contents are captured as `restore_value` on the fresh [BlueprintCell] --
##    a COPY, never the same [CellContents] instance [VoxelWorldGrid] still
##    holds (proven by mutating the grid afterward and observing
##    `restore_value` unaffected).
## 2. Edge case (own QA Test Cases): a floor drag starting on top of an
##    already-BUILT floor/block (not raw terrain) does NOT excavate -- normal
##    stacking, `restore_value` stays `null`.
## 3. AC70/Edge 18 (cancel/undo-while-pending path, [PlanOnlyUndoGate]): a
##    cancelled floor-excavation Draft cell's `restore_value` survives an
##    undo-then-redo round trip UNCHANGED when the underlying terrain has not
##    drifted; a DIVERGENT mocked "current" terrain state (simulating an
##    unrelated system altering the cell in the interim, Edge 18's own named
##    scenario) causes the redo to drop the cell rather than silently
##    recreate a stale excavation -- restoration is a snapshot, never a
##    re-derived "current" terrain state.
## 4. AC70/Edge 18 (demolish-after-Built path, connected end-to-end): a
##    committed floor-excavation cell, driven through a real
##    [ConstructionTickLoop] construction completion (Built) and then a real
##    demolition order to completion, writes back the ORIGINAL captured
##    terrain snapshot -- never the floor's own built contents, never empty.
class_name FloorExcavationRestoreValueTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_registry() -> BuildProjectRegistry:
	return BuildProjectRegistry.new()


func _new_stack() -> UndoRedoStack:
	var stack: UndoRedoStack = auto_free(UndoRedoStack.new())
	stack.config = UndoRedoStackConfig.new()
	stack.setup()
	return stack


## An address far from every cell any test in this file uses for its own
## terrain/blueprint fixtures -- exists ONLY to give [PlacementPick] a real
## raycast hit so [CommitPipeline]'s own "no valid pick is a no-op" gate
## (AC38) never rejects these tests; the actual candidate cells fed to
## [method CommitPipeline._on_build_committed] are always explicit, never
## derived from this anchor.
const _PICK_ANCHOR_CELL := Vector3i(50, 0, 50)


func _new_pipeline(grid: VoxelWorldGrid) -> CommitPipeline:
	grid.set_cell(_PICK_ANCHOR_CELL, CellContents.new(1, 0))
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"floor")
	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = auto_free(CameraInput.new())
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	pick.resolve_pick(Vector3(50.5, 20.0, 50.5), Vector3(0.0, -1.0, 0.0))

	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	pipeline.set_selected_item(&"placeholder_material")
	return pipeline


func _new_tick_loop(
	grid: VoxelWorldGrid, tick_source: Object, loop_config: ConstructionTickLoopConfig = null
) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = loop_config if loop_config != null else ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	loop.setup()
	return loop


# ---------------------------------------------------------------------------
# AC69 — terrain-start commit replaces flush + captures restore_value
# ---------------------------------------------------------------------------

func test_floor_commit_starting_on_terrain_replaces_flush_and_captures_restore_value() -> void:
	# Arrange — raw, untracked terrain at (5, 3, 5); the drag's own ATTACH
	# cell (what PlacementPick would resolve, one cell above the hit surface)
	# is (5, 4, 5).
	var grid: VoxelWorldGrid = _new_grid()
	var terrain_cell := Vector3i(5, 3, 5)
	var terrain_contents := CellContents.new(2, 1)
	grid.set_cell(terrain_cell, terrain_contents)
	var attach_cell: Vector3i = terrain_cell + Vector3i(0, 1, 0)

	var pipeline: CommitPipeline = _new_pipeline(grid)
	var floor_tool: FloorTool = auto_free(FloorTool.new())
	floor_tool.voxel_world = grid
	floor_tool.commit_pipeline = pipeline
	pipeline.set_cell_set_resolver(floor_tool.resolve_cell_set)
	pipeline.set_terrain_replace_resolver(floor_tool.resolve_terrain_replace_cells)

	# Act — a click (press == release) at the attach cell.
	pipeline._on_build_committed(false, attach_cell, attach_cell)

	# Assert — the blueprint cell lands FLUSH at the terrain cell's own
	# address, never stacked at the attach cell.
	assert_bool(pipeline.has_blueprint_cell(terrain_cell)).is_true()
	assert_bool(pipeline.has_blueprint_cell(attach_cell)).is_false()
	var created: BlueprintCell = pipeline.get_blueprint_cell_at(terrain_cell)
	assert_object(created.restore_value).is_not_null()
	assert_int(created.restore_value.block_type_id).is_equal(2)
	assert_int(created.restore_value.material_id).is_equal(1)

	# The snapshot is a COPY, never a live reference: mutating the grid's
	# current content afterward must not affect the already-captured value
	# (Edge 18: "a snapshot, never re-derived").
	grid.set_cell(terrain_cell, CellContents.new(77, 77))
	assert_int(created.restore_value.block_type_id).is_equal(2)
	assert_int(created.restore_value.material_id).is_equal(1)


func test_floor_drag_starting_on_terrain_shifts_the_whole_rectangle_flush() -> void:
	# Arrange — a 2x2 patch of terrain; the drag's attach cells sit one above
	# every terrain cell in the rectangle.
	var grid: VoxelWorldGrid = _new_grid()
	var terrain_y := 3
	for x: int in range(2):
		for z: int in range(2):
			grid.set_cell(Vector3i(x, terrain_y, z), CellContents.new(4, 0))
	var press_attach := Vector3i(0, terrain_y + 1, 0)
	var release_attach := Vector3i(1, terrain_y + 1, 1)

	var pipeline: CommitPipeline = _new_pipeline(grid)
	var floor_tool: FloorTool = auto_free(FloorTool.new())
	floor_tool.voxel_world = grid
	floor_tool.commit_pipeline = pipeline
	pipeline.set_cell_set_resolver(floor_tool.resolve_cell_set)
	pipeline.set_terrain_replace_resolver(floor_tool.resolve_terrain_replace_cells)

	# Act
	pipeline._on_build_committed(true, press_attach, release_attach)

	# Assert — all 4 cells land at the TERRAIN level (y = terrain_y), never
	# the attach level (y = terrain_y + 1); every one carries its own
	# restore_value.
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(4)
	for x: int in range(2):
		for z: int in range(2):
			var cell := Vector3i(x, terrain_y, z)
			assert_bool(pipeline.has_blueprint_cell(cell)).is_true()
			var bp: BlueprintCell = pipeline.get_blueprint_cell_at(cell)
			assert_int(bp.restore_value.block_type_id).is_equal(4)
			assert_bool(pipeline.has_blueprint_cell(Vector3i(x, terrain_y + 1, z))).is_false()


# ---------------------------------------------------------------------------
# Edge case — a drag starting on a BUILT floor (not terrain) does not excavate
# ---------------------------------------------------------------------------

func test_floor_drag_starting_on_a_built_floor_does_not_capture_restore_value() -> void:
	# Arrange — a cell this SAME pipeline already tracks as BUILT, and whose
	# raw grid content is non-empty (mirrors what a real completion write
	# would have already produced) -- this is "a built floor," not terrain.
	var grid: VoxelWorldGrid = _new_grid()
	var built_floor_cell := Vector3i(7, 3, 7)
	var pipeline: CommitPipeline = _new_pipeline(grid)
	pipeline._on_build_committed(false, built_floor_cell, built_floor_cell)
	var tracked: BlueprintCell = pipeline.get_blueprint_cell_at(built_floor_cell)
	assert_object(tracked).is_not_null()
	tracked.state = BlueprintCell.MicroState.BUILT
	grid.set_cell(built_floor_cell, CellContents.new(9, 2))

	var floor_tool: FloorTool = auto_free(FloorTool.new())
	floor_tool.voxel_world = grid
	floor_tool.commit_pipeline = pipeline
	pipeline.set_cell_set_resolver(floor_tool.resolve_cell_set)
	pipeline.set_terrain_replace_resolver(floor_tool.resolve_terrain_replace_cells)
	var attach_cell: Vector3i = built_floor_cell + Vector3i(0, 1, 0)

	# Act — a new floor drag starting directly above the built floor.
	pipeline._on_build_committed(false, attach_cell, attach_cell)

	# Assert — normal stacking: the new cell lands AT the attach cell, never
	# flush-replacing the built floor beneath it, and carries no restore_value.
	assert_bool(pipeline.has_blueprint_cell(attach_cell)).is_true()
	var new_cell: BlueprintCell = pipeline.get_blueprint_cell_at(attach_cell)
	assert_object(new_cell.restore_value).is_null()
	assert_int(pipeline.get_blueprint_cell_at(built_floor_cell).state).is_equal(BlueprintCell.MicroState.BUILT)


func test_starts_on_terrain_top_surface_false_when_dependencies_unwired() -> void:
	# A bare FloorTool (voxel_world/commit_pipeline both null, this class's
	# own "no setup() gate" precedent) never excavates -- every pre-012
	# caller/test keeps its exact original behavior.
	var floor_tool: FloorTool = auto_free(FloorTool.new())

	assert_bool(floor_tool.starts_on_terrain_top_surface(Vector3i(0, 4, 0))).is_false()
	assert_array(floor_tool.resolve_terrain_replace_cells(false, Vector3i(0, 4, 0), Vector3i(0, 4, 0))).is_empty()


# ---------------------------------------------------------------------------
# AC70 / Edge 18 — cancel/undo-while-pending: restore_value survives a
# cancel -> redo round trip, snapshot never re-derived
# ---------------------------------------------------------------------------

func test_cancel_then_redo_preserves_restore_value_when_terrain_unchanged() -> void:
	# Arrange — a floor-excavation Draft cell (its raw terrain still
	# physically occupies the grid -- nothing writes the grid until Built).
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var cell := Vector3i(9, 0, 9)
	var terrain_restore_value := CellContents.new(3, 1)
	grid.set_cell(cell, CellContents.new(3, 1))
	var blueprint := BlueprintCell.new(
		cell, BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.BLOCK, null, &"", terrain_restore_value
	)
	registry.assign_cells([blueprint])
	stack.record_command([cell])

	# Act — cancel (undo), then redo with the terrain UNCHANGED.
	stack.undo()
	assert_bool(gate.has_snapshot(cell)).is_true()
	var redo_result: bool = stack.redo()

	# Assert — recreated exactly, carrying the SAME captured restore_value.
	assert_bool(redo_result).is_true()
	var project_id: int = registry.project_at_cell(cell)
	assert_int(project_id).is_not_equal(-1)
	var recreated: BlueprintCell = registry.get_project(project_id).cells[cell]
	assert_object(recreated.restore_value).is_not_null()
	assert_int(recreated.restore_value.block_type_id).is_equal(3)
	assert_int(recreated.restore_value.material_id).is_equal(1)


func test_redo_drops_a_floor_excavation_cell_whose_terrain_diverged_since_capture() -> void:
	# Arrange — same setup, but the terrain is altered (a divergent "current"
	# state, Edge 18's own named scenario) AFTER the cancel and BEFORE redo.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var cell := Vector3i(11, 0, 11)
	var terrain_restore_value := CellContents.new(5, 2)
	grid.set_cell(cell, CellContents.new(5, 2))
	var blueprint := BlueprintCell.new(
		cell, BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.BLOCK, null, &"", terrain_restore_value
	)
	registry.assign_cells([blueprint])
	stack.record_command([cell])
	stack.undo()

	# Divergent mocked "current" terrain -- an unrelated system altered the
	# cell in the interim.
	grid.set_cell(cell, CellContents.new(6, 6))
	var dropped_received: Array = []
	stack.redo_cells_dropped.connect(func(dropped: Array[Vector3i]) -> void: dropped_received.append(dropped))

	# Act
	var redo_result: bool = stack.redo()

	# Assert — the redo is a no-op, the cell is dropped, never silently
	# recreated against the wrong (diverged) terrain.
	assert_bool(redo_result).is_false()
	assert_array(dropped_received[0]).is_equal([cell])
	assert_int(registry.project_at_cell(cell)).is_equal(-1)


# ---------------------------------------------------------------------------
# AC70 / Edge 18 — demolish-after-Built: connected end-to-end, capture ->
# construction completion -> demolition completion writes back the ORIGINAL
# captured snapshot
# ---------------------------------------------------------------------------

func test_capture_then_build_then_demolish_writes_back_the_original_terrain_snapshot() -> void:
	# Arrange — commit a terrain-start floor excavation for real (this
	# story's own capturing half), then drive it through a REAL
	# ConstructionTickLoop to Built (the pre-existing generic block-completion
	# write, unrelated to this story, correctly overwrites the terrain with
	# the floor's own contents by construction -- TR-voxel-world-045), then
	# through a real demolition order to completion ([ConstructionTickLoop]'s
	# already-landed Story building-009 consuming half).
	var grid: VoxelWorldGrid = _new_grid()
	var terrain_cell := Vector3i(13, 2, 13)
	var terrain_contents := CellContents.new(8, 3)
	grid.set_cell(terrain_cell, terrain_contents)
	var attach_cell: Vector3i = terrain_cell + Vector3i(0, 1, 0)

	var pipeline: CommitPipeline = _new_pipeline(grid)
	var floor_tool: FloorTool = auto_free(FloorTool.new())
	floor_tool.voxel_world = grid
	floor_tool.commit_pipeline = pipeline
	pipeline.set_cell_set_resolver(floor_tool.resolve_cell_set)
	pipeline.set_terrain_replace_resolver(floor_tool.resolve_terrain_replace_cells)
	pipeline._on_build_committed(false, attach_cell, attach_cell)
	var blueprint: BlueprintCell = pipeline.get_blueprint_cell_at(terrain_cell)
	assert_object(blueprint.restore_value).is_not_null()

	var loop_config := ConstructionTickLoopConfig.new()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_tick_loop(grid, mock_tick, loop_config)

	# Act 1 — build to completion (generic block-completion write; the floor
	# material overwrites the raw terrain, TR-voxel-world-045).
	assert_bool(loop.claim_job(blueprint, 1)).is_true()
	for i in range(loop_config.base_build_ticks_block):
		mock_tick.fire_tick()
	assert_int(blueprint.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(grid.get_cell(terrain_cell).is_empty()).is_false()
	assert_bool(
		grid.get_cell(terrain_cell).block_type_id == terrain_contents.block_type_id
		and grid.get_cell(terrain_cell).material_id == terrain_contents.material_id
	).is_false()

	# Act 2 — demolish to completion (Story building-009's already-landed
	# consuming half).
	assert_bool(loop.create_demolition_order(blueprint)).is_true()
	assert_bool(loop.claim_demolition_job(blueprint, 2)).is_true()
	for i in range(loop_config.base_demolition_ticks_block):
		mock_tick.fire_tick()

	# Assert — the ORIGINAL terrain snapshot is written back, never the
	# floor's own built contents, never empty.
	var restored: CellContents = grid.get_cell(terrain_cell)
	assert_bool(restored.is_empty()).is_false()
	assert_int(restored.block_type_id).is_equal(terrain_contents.block_type_id)
	assert_int(restored.material_id).is_equal(terrain_contents.material_id)
