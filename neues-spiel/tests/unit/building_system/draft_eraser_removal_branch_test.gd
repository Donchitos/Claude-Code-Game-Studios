## Unit test — Building System Story building-015 (Draft eraser / removal
## branch, GDD Core Rule 16, ADR-0016 primary). [TR-building-system-123]
## [TR-building-system-063] [TR-building-system-114] [TR-building-system-115].
## Third link of the demolition chain 009 -> 012 -> 015 -> 017.
##
## Also covers building-031's own scope (Planned -> Canceled + job revoke,
## AC41 [TR-building-system-068]) -- see `removal_tool.gd`'s own class doc
## comment for why that story's base is implemented in this SAME file (031
## is not a dependency of this story and has not landed).
##
## Proves:
## 1. AC73: a Draft-micro-state cell is erased instantly -- no job created,
##    no notification emitted anywhere in this Building-System slice.
## 2. Edge case (own QA Test Cases): erasing the last cell of a Draft project
##    deletes the empty project entity (Story 002/Rule 14i).
## 3. AC74/AC41: a released-but-unclaimed (Queued) cell cancels instantly; a
##    claimed (UnderConstruction) cell cancels instantly AND revokes the
##    claiming villager's job through the real [ConstructionJobQueue]/
##    [ConstructionTickLoop] pair.
## 4. AC13/13b/AC65 seam: a Built cell routes to Story 009's demolition-order
##    contract instead of being removed instantly -- the delegation is
##    asserted directly (`create_demolition_order` was actually called and its
##    own effects hold), never a reimplementation.
## 5. Edge 17 (via 009, re-verified at this seam): a second removal on an
##    already-queued demolition cell is a no-op.
## 6. A floor-excavation Draft cell's captured terrain is untouched by an
##    erase -- the raw grid was never written for a not-yet-Built cell, so
##    "restoring restore_value on erase" holds by construction.
## 7. An untracked cell (no owning project) is a no-op.
## 8. Scope boundary (own QA Test Cases): a Built FURNITURE cell routes to
##    Story 009/017's demolition-order contract exactly like a BLOCK cell --
##    never carved out or instantly removed here. (Story building-017,
##    landed after this story, widened Story 009's own category guard to
##    accept FURNITURE; this class needed no change of its own, since it
##    already only ever forwards to [method
##    ConstructionTickLoop.create_demolition_order] regardless of category.)
class_name DraftEraserRemovalBranchTest
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


func _new_tick_loop(grid: VoxelWorldGrid) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = ConstructionTickLoopConfig.new()
	loop.time_tick_system = auto_free(MockTimeTickSystem.new())
	loop.setup()
	return loop


func _planned_cell(
	cell: Vector3i,
	category: BlueprintCell.Category = BlueprintCell.Category.BLOCK,
	furniture_id: StringName = &"",
	restore_value: CellContents = null
) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED, category, null, furniture_id, restore_value)


func _built_cell(
	cell: Vector3i,
	contents: CellContents,
	category: BlueprintCell.Category = BlueprintCell.Category.BLOCK,
	furniture_id: StringName = &""
) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.BUILT, category, contents, furniture_id)


# ---------------------------------------------------------------------------
# AC73 — Draft erase is instant, free, silent
# ---------------------------------------------------------------------------

func test_remove_cell_erases_draft_cell_instantly_with_no_job_or_notification() -> void:
	# Arrange — a Draft (unreleased, project.state == DRAFT) cell.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var tool := RemovalTool.new(registry, tick_loop)
	var cell := Vector3i(0, 0, 0)
	var result: Array[BuildProject] = registry.assign_cells([_planned_cell(cell)])
	var project: BuildProject = result[0]
	assert_int(project.state).is_equal(BuildProject.ProjectState.DRAFT)

	# Observe every signal this slice could plausibly fire as a "notification".
	var construction_completed_signals: Array = []
	tick_loop.construction_completed.connect(func(_cells: Array) -> void: construction_completed_signals.append(true))
	var demolition_completed_signals: Array = []
	tick_loop.demolition_completed.connect(func(_cells: Array) -> void: demolition_completed_signals.append(true))

	# Act
	var removed: bool = tool.remove_cell(cell)

	# Assert — erased instantly, no job, no notification of any kind.
	assert_bool(removed).is_true()
	assert_bool(project.has_cell(cell)).is_false()
	assert_int(registry.project_at_cell(cell)).is_equal(-1)
	assert_bool(tick_loop.is_job_active(cell)).is_false()
	assert_int(construction_completed_signals.size()).is_equal(0)
	assert_int(demolition_completed_signals.size()).is_equal(0)


func test_remove_cell_erasing_last_draft_cell_deletes_the_empty_project() -> void:
	# Arrange — a single-cell Draft project.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var tool := RemovalTool.new(registry, tick_loop)
	var cell := Vector3i(1, 0, 1)
	var result: Array[BuildProject] = registry.assign_cells([_planned_cell(cell)])
	var project_id: int = result[0].id

	# Act
	var removed: bool = tool.remove_cell(cell)

	# Assert — the project entity itself is gone (Rule 14i/AC61).
	assert_bool(removed).is_true()
	assert_object(registry.get_project(project_id)).is_null()

	# A brand-new commit at the same address succeeds as its own project.
	var new_result: Array[BuildProject] = registry.assign_cells([_planned_cell(cell)])
	assert_int(new_result.size()).is_equal(1)
	assert_int(registry.project_at_cell(cell)).is_equal(new_result[0].id)


# ---------------------------------------------------------------------------
# AC74/AC41 — Queued/UnderConstruction cancel + graceful claim revoke
# ---------------------------------------------------------------------------

func test_remove_cell_cancels_a_released_unclaimed_queued_cell() -> void:
	# Arrange — released (BUILDING) but never claimed: "Queued".
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var tool := RemovalTool.new(registry, tick_loop)
	var cell := Vector3i(2, 0, 2)
	var result: Array[BuildProject] = registry.assign_cells([_planned_cell(cell)])
	var project: BuildProject = result[0]
	project.state = BuildProject.ProjectState.BUILDING

	# Act
	var removed: bool = tool.remove_cell(cell)

	# Assert
	assert_bool(removed).is_true()
	assert_bool(project.has_cell(cell)).is_false()
	assert_int(registry.project_at_cell(cell)).is_equal(-1)


func test_remove_cell_cancels_and_revokes_a_real_claimed_under_construction_cell() -> void:
	# Arrange — a real claim through ConstructionJobQueue/ConstructionTickLoop
	# (mirrors PlanOnlyUndoGate's own established claim-revoke test fixture).
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var job_queue := ConstructionJobQueue.new(tick_loop)
	var tool := RemovalTool.new(registry, tick_loop, job_queue)
	var cell := Vector3i(3, 0, 3)
	var result: Array[BuildProject] = registry.assign_cells([_planned_cell(cell)])
	var project: BuildProject = result[0]
	project.state = BuildProject.ProjectState.BUILDING
	job_queue.add_project(project)
	assert_bool(job_queue.claim_job(cell, 42)).is_true()
	assert_bool(tick_loop.is_job_active(cell)).is_true()
	assert_int(project.cells[cell].state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)

	# Act
	var removed: bool = tool.remove_cell(cell)

	# Assert — the claim and the active job are both gone; the cell itself is
	# cancelled out of the project (graceful abandon).
	assert_bool(removed).is_true()
	assert_bool(tick_loop.is_job_active(cell)).is_false()
	assert_bool(job_queue.has_claim(42)).is_false()
	assert_bool(project.has_cell(cell)).is_false()


# ---------------------------------------------------------------------------
# AC13/13b/AC65 seam — Built cell routes to Story 009's demolition contract
# ---------------------------------------------------------------------------

func test_remove_cell_on_built_cell_creates_a_demolition_order_not_an_instant_removal() -> void:
	# Arrange — a Built BLOCK cell, still physically present in the grid.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var tool := RemovalTool.new(registry, tick_loop)
	var cell := Vector3i(4, 0, 4)
	var contents := CellContents.new(3, 1)
	grid.set_cell(cell, contents)
	var result: Array[BuildProject] = registry.assign_cells([_built_cell(cell, contents)])
	var project: BuildProject = result[0]

	# Act
	var removed: bool = tool.remove_cell(cell)

	# Assert — a demolition order exists; the cell is NOT removed instantly:
	# state stays BUILT, project membership is untouched, the grid still
	# shows the cell's contents.
	assert_bool(removed).is_true()
	var blueprint_cell: BlueprintCell = project.cells[cell]
	assert_bool(blueprint_cell.is_demolition_queued).is_true()
	assert_int(blueprint_cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(project.has_cell(cell)).is_true()
	assert_bool(grid.get_cell(cell).is_empty()).is_false()
	assert_int(grid.get_cell(cell).block_type_id).is_equal(3)


func test_remove_cell_second_removal_on_already_queued_demolition_cell_is_a_no_op() -> void:
	# Arrange — a Built cell already carrying a demolition order.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var tool := RemovalTool.new(registry, tick_loop)
	var cell := Vector3i(5, 0, 5)
	var contents := CellContents.new(4, 0)
	grid.set_cell(cell, contents)
	registry.assign_cells([_built_cell(cell, contents)])
	assert_bool(tool.remove_cell(cell)).is_true()

	# Act — a second removal on the SAME already-queued cell.
	var second: bool = tool.remove_cell(cell)

	# Assert — rejected; exactly one order (flag stays true, not toggled).
	assert_bool(second).is_false()
	var project: BuildProject = registry.get_project(registry.project_at_cell(cell))
	assert_bool(project.cells[cell].is_demolition_queued).is_true()


# ---------------------------------------------------------------------------
# Floor-excavation Draft cell — untouched terrain on erase (Story 012 seam)
# ---------------------------------------------------------------------------

func test_remove_cell_on_a_floor_excavation_draft_cell_leaves_the_grid_terrain_untouched() -> void:
	# Arrange — a floor-excavation blueprint entry (its raw terrain still
	# physically occupies the grid -- nothing writes the grid until Built,
	# mirroring PlanOnlyUndoGate's own established fixture for this exact
	# invariant).
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var tool := RemovalTool.new(registry, tick_loop)
	var cell := Vector3i(6, 0, 6)
	var terrain_restore_value := CellContents.new(2, 1)
	grid.set_cell(cell, CellContents.new(2, 1))
	registry.assign_cells([_planned_cell(cell, BlueprintCell.Category.BLOCK, &"", terrain_restore_value)])

	# Act
	var removed: bool = tool.remove_cell(cell)

	# Assert — erased from the project/registry, but the raw grid terrain is
	# completely untouched (it was never written in the first place).
	assert_bool(removed).is_true()
	assert_int(registry.project_at_cell(cell)).is_equal(-1)
	var terrain_now: CellContents = grid.get_cell(cell)
	assert_bool(terrain_now.is_empty()).is_false()
	assert_int(terrain_now.block_type_id).is_equal(2)
	assert_int(terrain_now.material_id).is_equal(1)


# ---------------------------------------------------------------------------
# Untracked cell — no-op
# ---------------------------------------------------------------------------

func test_remove_cell_on_an_untracked_cell_is_a_no_op() -> void:
	# Arrange — no project tracks this address at all (e.g. raw terrain).
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var tool := RemovalTool.new(registry, tick_loop)

	var removed: bool = tool.remove_cell(Vector3i(99, 0, 99))

	assert_bool(removed).is_false()


# ---------------------------------------------------------------------------
# Scope boundary — Built furniture is never instantly removed here (Story 017)
# ---------------------------------------------------------------------------

func test_remove_cell_on_built_furniture_cell_creates_a_demolition_order_story_017() -> void:
	# Story building-017 (landed after this story) widened Story 009's own
	# create_demolition_order to accept FURNITURE, reusing this SAME
	# mechanism -- this class needed no change of its own (it only ever
	# forwards). See `furniture_demolition_test.gd` for the full atomic
	# multi-cell-footprint / deferred-revocation proof; this suite keeps only
	# the direct regression that THIS seam's own delegation still holds for
	# furniture now that the category guard downstream has changed. Furniture
	# never enters VoxelWorldGrid (BV-1), so -- unlike the BLOCK fixture
	# above -- nothing is ever written into the grid for this cell.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var tool := RemovalTool.new(registry, tick_loop)
	var cell := Vector3i(7, 0, 7)
	var contents := CellContents.new(5, 0)
	var result: Array[BuildProject] = registry.assign_cells(
		[_built_cell(cell, contents, BlueprintCell.Category.FURNITURE, &"bed")]
	)
	var project: BuildProject = result[0]

	# Act
	var removed: bool = tool.remove_cell(cell)

	# Assert — a demolition order now exists (not instant, not refused); the
	# blueprint cell's own state/project membership are untouched (mirrors the
	# BLOCK case above -- AC65's "not removed instantly" applies uniformly).
	assert_bool(removed).is_true()
	assert_bool(project.cells[cell].is_demolition_queued).is_true()
	assert_int(project.cells[cell].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(project.has_cell(cell)).is_true()


# ---------------------------------------------------------------------------
# Grep guard — this class never writes to VoxelWorldGrid directly
# ---------------------------------------------------------------------------

func test_removal_tool_never_calls_a_voxel_world_write_api_directly() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/building_system/removal_tool.gd")

	assert_bool(source.contains("voxel_world.set_cell")).is_false()
	assert_bool(source.contains("voxel_world.bulk_write")).is_false()
	assert_bool(source.contains("voxel_world.clear_cell")).is_false()
	assert_bool(source.contains(".set_cell(")).is_false()
	assert_bool(source.contains(".bulk_write(")).is_false()
	assert_bool(source.contains(".clear_cell(")).is_false()
