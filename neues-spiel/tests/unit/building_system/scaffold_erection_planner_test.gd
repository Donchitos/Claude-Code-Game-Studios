## Story `building-034` -- [ScaffoldErectionPlanner] (TD ruling D8/D9, AC4).
class_name ScaffoldErectionPlannerTest
extends GdUnitTestSuite


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))


func test_direct_support_plan_reaches_target_at_zero_cantilever() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 12)
	var target := Vector3i(5, 3, 5)

	var plan: ScaffoldPlan = ScaffoldErectionPlanner.plan_for_target(grid, null, null, null, target, 6)

	assert_bool(plan.has_plan()).override_failure_message(
		"a flat-ground target with room on every side must always find a direct-support plan"
	).is_true()
	assert_int(plan.cantilever_distance).is_equal(0)
	# Every planned cell must be orthogonally adjacent to the target (D8.1)
	# and empty in the raw grid (D9).
	for cell: Vector3i in plan.cells:
		var contents: CellContents = grid.get_cell(cell)
		assert_bool(contents.is_empty()).is_true()


func test_ac4_cantilever_limit_blocks_then_raising_the_knob_reaches_target() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	# Solid ground ONLY at x = 0 (a single supported column strip); every
	# other x is a chasm -- no direct support anywhere else.
	var z0 := 10
	for z in range(z0 - 10, z0 + 10):
		grid.set_cell(Vector3i(0, 0, z), CellContents.new(1, 0))

	# Target 8 cells out over the chasm -- nearest staging candidate (7
	# cells out) is 7 cells (Chebyshev, horizontal) from the only supported
	# column at x = 0.
	var target := Vector3i(8, 3, z0)

	var blocked_plan: ScaffoldPlan = ScaffoldErectionPlanner.plan_for_target(grid, null, null, null, target, 6)
	assert_bool(blocked_plan.has_plan()).override_failure_message(
		"cantilever_limit=6 must NOT reach a target whose nearest support is 7 cells away"
	).is_false()

	var raised_plan: ScaffoldPlan = ScaffoldErectionPlanner.plan_for_target(grid, null, null, null, target, 7)
	assert_bool(raised_plan.has_plan()).override_failure_message(
		"raising scaffold_max_cantilever_cells to 7 must reach the SAME target"
	).is_true()
	assert_int(raised_plan.cantilever_distance).is_equal(7)


func test_d9_forbids_overlap_never_plans_a_cell_already_owned_by_a_non_scaffold_project() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 12)
	var target := Vector3i(5, 3, 5)
	var blocked_cell := target + Vector3i(1, 0, 0)

	var registry := BuildProjectRegistry.new()
	var blueprint_cell := BlueprintCell.new(blocked_cell, BlueprintCell.MicroState.PLANNED)
	registry.assign_cells([blueprint_cell], BuildProject.Kind.BUILD)

	var plan: ScaffoldPlan = ScaffoldErectionPlanner.plan_for_target(grid, null, registry, null, target, 6)

	assert_bool(plan.has_plan()).is_true()
	assert_array(plan.cells).override_failure_message(
		"D9 forbids ever creating a scaffold cell at an address a non-SCAFFOLD project already owns"
	).not_contains([blocked_cell])
	assert_vector(plan.staging_cell).is_not_equal(blocked_cell)
