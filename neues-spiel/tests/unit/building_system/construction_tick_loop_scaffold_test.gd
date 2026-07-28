## Story `building-034` -- [ConstructionTickLoop]'s SCAFFOLD-category routing
## (AC2, D1/D3).
class_name ConstructionTickLoopScaffoldTest
extends GdUnitTestSuite


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _make_loop(grid: VoxelWorldGrid, tick_source: MockTimeTickSystem) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	loop.scaffold_registry = ScaffoldRegistry.new()
	loop.setup()
	return loop


## AC2: the scaffold cell completes strictly faster than a block cell, and
## neither completes in zero ticks.
func test_ac2_scaffold_ticks_strictly_fewer_than_block_never_zero() -> void:
	var config := ConstructionTickLoopConfig.new()
	var scaffold_ticks: int = ConstructionTickLoop.required_ticks_for(BlueprintCell.Category.SCAFFOLD, config)
	var block_ticks: int = ConstructionTickLoop.required_ticks_for(BlueprintCell.Category.BLOCK, config)
	assert_int(scaffold_ticks).is_greater_equal(1)
	assert_int(scaffold_ticks).is_less(block_ticks)


func test_scaffold_construction_completion_routes_to_scaffold_registry_not_grid() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var grid: VoxelWorldGrid = _make_grid()
	var loop: ConstructionTickLoop = _make_loop(grid, tick_source)
	var cell := Vector3i(5, 5, 5)
	var blueprint_cell := BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.SCAFFOLD)

	assert_bool(loop.claim_job(blueprint_cell, 1)).is_true()
	for _i in range(loop.config.base_build_ticks_scaffold):
		tick_source.fire_tick()

	assert_bool(blueprint_cell.state == BlueprintCell.MicroState.BUILT).is_true()
	assert_bool(loop.scaffold_registry.has_scaffold(cell)).override_failure_message(
		"a completing SCAFFOLD job must route to ScaffoldRegistry"
	).is_true()
	assert_bool(grid.get_cell(cell).is_empty()).override_failure_message(
		"a SCAFFOLD completion must NEVER write to VoxelWorldGrid (D1: not voxel data)"
	).is_true()


func test_scaffold_demolition_completion_removes_from_registry_never_writes_grid() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var grid: VoxelWorldGrid = _make_grid()
	var loop: ConstructionTickLoop = _make_loop(grid, tick_source)
	var cell := Vector3i(5, 5, 5)
	var blueprint_cell := BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.SCAFFOLD)
	loop.claim_job(blueprint_cell, 1)
	for _i in range(loop.config.base_build_ticks_scaffold):
		tick_source.fire_tick()
	assert_bool(loop.scaffold_registry.has_scaffold(cell)).is_true()

	assert_bool(loop.create_demolition_order(blueprint_cell)).is_true()
	assert_bool(loop.claim_demolition_job(blueprint_cell, 1)).is_true()
	for _i in range(loop.config.base_demolition_ticks_scaffold):
		tick_source.fire_tick()

	assert_bool(loop.scaffold_registry.has_scaffold(cell)).override_failure_message(
		"a completed SCAFFOLD demolition must remove the cell from ScaffoldRegistry"
	).is_false()
	assert_bool(grid.get_cell(cell).is_empty()).is_true()
