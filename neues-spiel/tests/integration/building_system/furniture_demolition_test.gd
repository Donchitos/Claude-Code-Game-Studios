## Integration test — Building System Story building-017 (Furniture
## demolition: job-gated, atomic multi-cell, ADR-0016 primary). Fourth and
## final link of the demolition chain 009 -> 012 -> 015 -> 017.
##
## Proves, at the Building-System layer (the revocation CONSUMPTION seam
## itself is PROVISIONAL per this story's own Implementation Notes -- the
## non-vacuous real-demolition-driven revocation proof against the REAL
## [FurnitureBedProvider]/[VillagerAi] pair lives in
## `tests/integration/needs_mood/shelter_recovery_live_pair_test.gd`, not
## here, per this story's own QA plan):
##
## 1. AC17 [TR-building-system-064/127]: a Built bed's demolition order is
##    created IMMEDIATELY via [RemovalTool] (never blocked by "in use" --
##    this layer has no such concept at all, only Villager AI/Needs do), and
##    the item stays fully registered/functional until a claimed job actually
##    completes.
## 2. The order attaches to its owning [BuildProject] when one exists, and
##    works identically as a STANDALONE order (Rule 14j mechanics, no project
##    at all) when one does not.
## 3. Atomicity [TR-building-system-127]: a 1x2 footprint demolishes as
##    exactly ONE job -- a second claim attempt against the OTHER footprint
##    cell while the first is active fails; on completion, BOTH cells clear
##    from [FurnitureRegistry] together, named together in ONE [signal
##    ConstructionTickLoop.demolition_completed] emission.
## 4. BV-1 extended to removal: a completing FURNITURE demolition NEVER
##    writes to [VoxelWorldGrid] (no [method VoxelWorldGrid.bulk_write] call
##    at all for an all-furniture completion batch, mirroring
##    `multi_cell_furniture_placement_test.gd`'s own construction-side proof
##    in reverse).
## 5. Event-timing contract (GDD Rule 17b, [TR-building-system-064]): [member
##    ConstructionTickLoop._furniture_demolished_callback] fires exactly once
##    per completed FURNITURE demolition, strictly AFTER [method
##    FurnitureRegistry.remove] has already taken effect -- never at order
##    creation, never before the registry write.
## 6. Not-yet-Built furniture removal is UNCHANGED (Story 015's own branch,
##    re-verified at this story's own furniture-specific seam): Draft ->
##    instant cancel; Queued/UnderConstruction -> instant cancel + claim
##    revoked, no demolition order either way.
## 7. The revocation-consumption SHAPE (an unowned item's demolition implies
##    no revocation, an owned item's does) is proven with a local,
##    Villager-AI-agnostic ownership stand-in -- this suite never references
##    `FurnitureBedProvider`/`VillagerAi` (that real, non-vacuous proof lives
##    in `shelter_recovery_live_pair_test.gd`, per this story's own QA plan).
class_name FurnitureDemolitionTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test helpers (mirrors demolition_orders_blocks_test.gd's own precedent)
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_registry() -> BuildProjectRegistry:
	return BuildProjectRegistry.new()


func _new_loop(
	grid: VoxelWorldGrid, tick_source: Object, loop_config: ConstructionTickLoopConfig = null
) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = loop_config if loop_config != null else ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	loop.setup()
	return loop


## A Built 1x2 furniture footprint (mirrors `multi_cell_furniture_placement_test.gd`'s
## own construction-side fixture, but already-completed: BUILT from the
## start, sharing one [FurnitureFootprintGroup], registered in [param
## registry] exactly as [method ConstructionTickLoop._complete_jobs] would
## have left it after a real construction completion).
func _new_built_bed_footprint(
	registry: FurnitureRegistry, cell_a: Vector3i, cell_b: Vector3i
) -> Array[BlueprintCell]:
	var group := FurnitureFootprintGroup.new()
	var contents := CellContents.new(1, 0)
	var bp_a := BlueprintCell.new(cell_a, BlueprintCell.MicroState.BUILT, BlueprintCell.Category.FURNITURE, contents, &"bed")
	var bp_b := BlueprintCell.new(cell_b, BlueprintCell.MicroState.BUILT, BlueprintCell.Category.FURNITURE, contents, &"bed")
	group.cells = [bp_a, bp_b]
	group.is_registered = true
	bp_a.footprint_group = group
	bp_b.footprint_group = group
	registry.place(&"bed", [cell_a, cell_b])
	return [bp_a, bp_b]


# ---------------------------------------------------------------------------
# AC17 — order created immediately; not removed until completion
# ---------------------------------------------------------------------------

func test_ac17_removal_tool_creates_demolition_order_immediately_bed_stays_functional_until_completion() -> void:
	# Arrange — a Built 1x2 bed, registered as normal (this layer has no
	# "in use" concept at all -- that proof, with a real sleeping owner,
	# lives in shelter_recovery_live_pair_test.gd).
	var grid: VoxelWorldGrid = _new_grid()
	var project_registry: BuildProjectRegistry = _new_registry()
	var furniture_registry := FurnitureRegistry.new()
	var cell_a := Vector3i(1, 1, 1)
	var cell_b := Vector3i(1, 1, 2)
	var cells: Array[BlueprintCell] = _new_built_bed_footprint(furniture_registry, cell_a, cell_b)
	project_registry.assign_cells(cells)
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	loop.furniture_registry = furniture_registry
	var tool := RemovalTool.new(project_registry, loop)

	# Act — target ONE footprint cell with the removal tool.
	var removed: bool = tool.remove_cell(cell_a)

	# Assert — order created immediately; both cells flagged atomically;
	# the item is STILL fully registered and functional (not removed).
	assert_bool(removed).is_true()
	assert_bool(cells[0].is_demolition_queued).is_true()
	assert_bool(cells[1].is_demolition_queued).is_true()
	assert_bool(furniture_registry.has_occupant(cell_a)).is_true()
	assert_bool(furniture_registry.has_occupant(cell_b)).is_true()
	assert_int(furniture_registry.get_placed_furniture().size()).is_equal(1)
	assert_int(cells[0].state).is_equal(BlueprintCell.MicroState.BUILT)


# ---------------------------------------------------------------------------
# Owning project vs. standalone order — both use the identical mechanics
# ---------------------------------------------------------------------------

func test_demolition_order_on_furniture_attaches_to_its_owning_project() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var project_registry: BuildProjectRegistry = _new_registry()
	var furniture_registry := FurnitureRegistry.new()
	var cell_a := Vector3i(2, 1, 2)
	var cell_b := Vector3i(2, 1, 3)
	var cells: Array[BlueprintCell] = _new_built_bed_footprint(furniture_registry, cell_a, cell_b)
	var result: Array[BuildProject] = project_registry.assign_cells(cells)
	var project: BuildProject = result[0]
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	loop.furniture_registry = furniture_registry
	var tool := RemovalTool.new(project_registry, loop)

	tool.remove_cell(cell_a)

	# The order attaches to (never replaces or detaches from) the owning
	# project -- membership is completely untouched at order-creation time.
	assert_bool(project.has_cell(cell_a)).is_true()
	assert_bool(project.has_cell(cell_b)).is_true()
	assert_int(project_registry.project_at_cell(cell_a)).is_equal(project.id)


func test_demolition_order_on_furniture_with_no_owning_project_is_standalone() -> void:
	# Arrange — a Built bed footprint NEVER registered into any
	# BuildProjectRegistry at all (Rule 14j's own "standalone order" case) --
	# the tick loop's create_demolition_order/claim_demolition_job contract
	# needs no project of any kind.
	var grid: VoxelWorldGrid = _new_grid()
	var furniture_registry := FurnitureRegistry.new()
	var cell_a := Vector3i(3, 1, 3)
	var cell_b := Vector3i(3, 1, 4)
	var cells: Array[BlueprintCell] = _new_built_bed_footprint(furniture_registry, cell_a, cell_b)
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	loop.furniture_registry = furniture_registry

	# Act — direct call into the same Rule 14j mechanics Story 009 already
	# established (mirrors that story's own AC66 mocked-claim pattern), no
	# RemovalTool/project registry involved at all.
	assert_bool(loop.create_demolition_order(cells[0])).is_true()
	assert_bool(loop.claim_demolition_job(cells[0], 1)).is_true()
	for i in range(loop_config.base_demolition_ticks_furniture):
		mock_tick.fire_tick()

	# Assert — completes correctly with no project anywhere in the picture.
	assert_bool(furniture_registry.is_empty()).is_true()


# ---------------------------------------------------------------------------
# Atomicity — ONE job for the whole 1x2 footprint
# ---------------------------------------------------------------------------

func test_second_claim_against_the_other_footprint_cell_while_job_active_fails() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var furniture_registry := FurnitureRegistry.new()
	var cell_a := Vector3i(4, 1, 4)
	var cell_b := Vector3i(4, 1, 5)
	var cells: Array[BlueprintCell] = _new_built_bed_footprint(furniture_registry, cell_a, cell_b)
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	loop.furniture_registry = furniture_registry
	assert_bool(loop.create_demolition_order(cells[0])).is_true()
	assert_bool(loop.claim_demolition_job(cells[0], 1)).is_true()

	# Act — a SECOND villager attempts to claim the OTHER footprint cell's
	# own (already-queued) demolition, while the first is still active.
	var second_claim: bool = loop.claim_demolition_job(cells[1], 2)

	# Assert — refused: this is ONE job for the whole entity, never two.
	assert_bool(second_claim).is_false()
	assert_bool(loop.is_job_active(cell_b)).is_false()


func test_atomic_multi_cell_footprint_demolishes_as_one_job_both_cells_clear_together() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var furniture_registry := FurnitureRegistry.new()
	var cell_a := Vector3i(5, 1, 5)
	var cell_b := Vector3i(5, 1, 6)
	var cells: Array[BlueprintCell] = _new_built_bed_footprint(furniture_registry, cell_a, cell_b)
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	loop.furniture_registry = furniture_registry
	assert_bool(loop.create_demolition_order(cells[0])).is_true()
	assert_bool(loop.claim_demolition_job(cells[0], 1)).is_true()

	var demolition_completed_payloads: Array = []
	loop.demolition_completed.connect(func(demolished: Array) -> void: demolition_completed_payloads.append(demolished))

	# Act — one tick short of completion: nothing happened yet, for EITHER
	# cell (never "half torn down").
	for i in range(loop_config.base_demolition_ticks_furniture - 1):
		mock_tick.fire_tick()
	assert_bool(furniture_registry.has_occupant(cell_a)).is_true()
	assert_bool(furniture_registry.has_occupant(cell_b)).is_true()

	# Act — the final tick.
	mock_tick.fire_tick()

	# Assert — BOTH cells clear together, in ONE demolition_completed
	# emission naming both.
	assert_bool(furniture_registry.is_empty()).is_true()
	assert_bool(furniture_registry.has_occupant(cell_a)).is_false()
	assert_bool(furniture_registry.has_occupant(cell_b)).is_false()
	assert_int(demolition_completed_payloads.size()).is_equal(1)
	var completed_cells: Array = demolition_completed_payloads[0]
	assert_int(completed_cells.size()).is_equal(2)
	assert_bool(completed_cells.has(cell_a)).is_true()
	assert_bool(completed_cells.has(cell_b)).is_true()
	assert_bool(cells[0].is_demolition_queued).is_false()
	assert_bool(cells[1].is_demolition_queued).is_false()


# ---------------------------------------------------------------------------
# BV-1 extended to removal — never a VoxelWorldGrid write
# ---------------------------------------------------------------------------

func test_furniture_demolition_never_writes_to_voxel_world_grid() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var furniture_registry := FurnitureRegistry.new()
	var cell_a := Vector3i(6, 1, 6)
	var cell_b := Vector3i(6, 1, 7)
	var cells: Array[BlueprintCell] = _new_built_bed_footprint(furniture_registry, cell_a, cell_b)
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	loop.furniture_registry = furniture_registry
	assert_bool(loop.create_demolition_order(cells[0])).is_true()
	assert_bool(loop.claim_demolition_job(cells[0], 1)).is_true()

	var batch_signals: Array = []
	grid.cells_changed_batch.connect(func(_changes: Array) -> void: batch_signals.append(true))

	for i in range(loop_config.base_demolition_ticks_furniture):
		mock_tick.fire_tick()

	# Assert — an all-furniture completion batch never even calls
	# bulk_write (mirrors the construction-side proof in reverse); both
	# cell addresses read exactly as before (empty -- furniture never wrote
	# there in the first place).
	assert_int(batch_signals.size()).is_equal(0)
	assert_bool(grid.get_cell(cell_a).is_empty()).is_true()
	assert_bool(grid.get_cell(cell_b).is_empty()).is_true()


# ---------------------------------------------------------------------------
# Event-timing contract — fires exactly once, strictly after registry removal
# ---------------------------------------------------------------------------

func test_furniture_demolished_callback_fires_exactly_once_strictly_after_registry_removal() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var furniture_registry := FurnitureRegistry.new()
	var cell_a := Vector3i(7, 1, 7)
	var cell_b := Vector3i(7, 1, 8)
	var cells: Array[BlueprintCell] = _new_built_bed_footprint(furniture_registry, cell_a, cell_b)
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	loop.furniture_registry = furniture_registry

	var callback_calls: Array = []
	var registry_was_already_empty_at_callback_time: Array[bool] = []
	loop.set_furniture_demolished_callback(
		func(definition_id: StringName, cell_list: Array[Vector3i]) -> void:
			registry_was_already_empty_at_callback_time.append(furniture_registry.is_empty())
			callback_calls.append([definition_id, cell_list])
	)

	assert_bool(loop.create_demolition_order(cells[0])).is_true()
	assert_bool(loop.claim_demolition_job(cells[0], 1)).is_true()

	# Never fires before completion.
	for i in range(loop_config.base_demolition_ticks_furniture - 1):
		mock_tick.fire_tick()
	assert_int(callback_calls.size()).is_equal(0)

	# Fires exactly once, on completion, strictly AFTER the registry removal.
	mock_tick.fire_tick()
	assert_int(callback_calls.size()).is_equal(1)
	assert_bool(registry_was_already_empty_at_callback_time[0]).is_true()
	assert_str(String(callback_calls[0][0])).is_equal("bed")
	var named_cells: Array = callback_calls[0][1]
	assert_int(named_cells.size()).is_equal(2)
	assert_bool(named_cells.has(cell_a)).is_true()
	assert_bool(named_cells.has(cell_b)).is_true()


# ---------------------------------------------------------------------------
# Not-yet-Built furniture removal — unchanged (Story 015's own branch)
# ---------------------------------------------------------------------------

func test_draft_furniture_cell_removal_is_still_instant_cancel_no_demolition_order() -> void:
	var project_registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var tool := RemovalTool.new(project_registry, loop)
	var cell := Vector3i(8, 1, 8)
	var draft_cell := BlueprintCell.new(
		cell, BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.FURNITURE, null, &"bed"
	)
	project_registry.assign_cells([draft_cell])

	var removed: bool = tool.remove_cell(cell)

	assert_bool(removed).is_true()
	assert_int(project_registry.project_at_cell(cell)).is_equal(-1)


func test_under_construction_furniture_cell_removal_cancels_and_revokes_claim() -> void:
	var project_registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var job_queue := ConstructionJobQueue.new(loop)
	var tool := RemovalTool.new(project_registry, loop, job_queue)
	var cell := Vector3i(9, 1, 9)
	# A FURNITURE claim (unlike a demolition claim) is gated on a Built
	# support cell directly below (Story building-028, AC49) -- provide one
	# so `claim_job` itself succeeds; this test's own subject is the
	# removal/revoke seam, not the support gate.
	grid.set_cell(cell + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var draft_cell := BlueprintCell.new(
		cell, BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.FURNITURE, null, &"bed"
	)
	var result: Array[BuildProject] = project_registry.assign_cells([draft_cell])
	var project: BuildProject = result[0]
	project.state = BuildProject.ProjectState.BUILDING
	job_queue.add_project(project)
	assert_bool(job_queue.claim_job(cell, 42)).is_true()
	assert_int(draft_cell.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)

	var removed: bool = tool.remove_cell(cell)

	assert_bool(removed).is_true()
	assert_bool(loop.is_job_active(cell)).is_false()
	assert_bool(job_queue.has_claim(42)).is_false()
	assert_bool(project.has_cell(cell)).is_false()


# ---------------------------------------------------------------------------
# Revocation-consumption SHAPE — unowned fires nothing, owned fires (local
# stand-in, never FurnitureBedProvider/VillagerAi -- see class doc comment)
# ---------------------------------------------------------------------------

func test_unowned_item_demolition_triggers_no_revocation_owned_item_does() -> void:
	# A tiny, LOCAL ownership stand-in -- exactly the shape a future
	# Villager-AI-side bridge would supply to `set_furniture_demolished_callback`,
	# without this suite depending on FurnitureBedProvider/VillagerAi at all
	# (that real, non-vacuous proof lives in shelter_recovery_live_pair_test.gd).
	var owned_canonical_cells: Dictionary[Vector3i, int] = {}
	var revocation_signals: Array = []

	var _make_scenario := func(grid: VoxelWorldGrid, canonical_cell: Vector3i, other_cell: Vector3i) -> Dictionary:
		var furniture_registry := FurnitureRegistry.new()
		var cells: Array[BlueprintCell] = _new_built_bed_footprint(furniture_registry, canonical_cell, other_cell)
		var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
		var loop_config := ConstructionTickLoopConfig.new()
		var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
		loop.furniture_registry = furniture_registry
		loop.set_furniture_demolished_callback(
			func(definition_id: StringName, cell_list: Array[Vector3i]) -> void:
				if definition_id != &"bed":
					return
				var group_canonical: Vector3i = cell_list[0]
				for c: Vector3i in cell_list:
					if c.x < group_canonical.x or (c.x == group_canonical.x and c.z < group_canonical.z):
						group_canonical = c
				if owned_canonical_cells.has(group_canonical):
					revocation_signals.append(owned_canonical_cells[group_canonical])
		)
		assert_bool(loop.create_demolition_order(cells[0])).is_true()
		assert_bool(loop.claim_demolition_job(cells[0], 1)).is_true()
		for i in range(loop_config.base_demolition_ticks_furniture):
			mock_tick.fire_tick()
		return {"canonical": canonical_cell}

	# Unowned bed -- never recorded in owned_canonical_cells.
	_make_scenario.call(_new_grid(), Vector3i(10, 1, 10), Vector3i(10, 1, 11))
	assert_int(revocation_signals.size()).is_equal(0)

	# Owned bed -- recorded as claimed by villager 7 BEFORE demolition.
	var owned_canonical := Vector3i(11, 1, 11)
	owned_canonical_cells[owned_canonical] = 7
	_make_scenario.call(_new_grid(), owned_canonical, Vector3i(11, 1, 12))
	assert_int(revocation_signals.size()).is_equal(1)
	assert_int(revocation_signals[0]).is_equal(7)
