## Unit test — Building System Story building-016 (Multi-cell furniture
## placement / footprint). ADR-0016 primary (Build Project Entity Lifecycle);
## ADR-0006 secondary (RID `footprint` field, getter-only [ItemDefinition]).
##
## Proves:
## 1. AC75 [TR-building-system-124]: a multi-cell footprint commit is
##    ALL-OR-NOTHING -- partial support, partial occupancy, and (Story
##    building-016's own strengthening) partial bounds all reject the WHOLE
##    commit, never a partial placement (Edge Case 19).
## 2. `furniture_cell_count = |footprint(item)|` (F5) -- generalized, not
##    hardcoded to 1: a 1x2 footprint yields 2 cells, a 2x2 footprint yields
##    4, and a 1x1 footprint (Story building-028's own pre-016 shape)
##    degenerates to exactly 1, unchanged.
## 3. AC76 [TR-building-system-124]: a valid multi-cell commit resolves, once
##    construction completes, to EXACTLY ONE furniture entity spanning every
##    footprint cell, each cell referencing the SAME occupant id -- proven
##    both when siblings complete in the SAME tick dispatch (dedup guard)
##    and when they complete at DIFFERENT dispatches/times, claimed by
##    different villagers (order-independence).
class_name MultiCellFurniturePlacementTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles (inner helper classes — kept ABOVE every test function)
# ---------------------------------------------------------------------------

## RID-shaped test double wrapping REAL [ItemDefinition]/[ItemDefinitionResource]
## value objects (mirrors `furniture_placement_base_test.gd`'s own
## `_MockItemDatabase` precedent exactly), extended with an explicit
## `footprint` parameter (Story building-016) -- every pre-016 call site that
## omits it keeps the RID schema's own `Vector2i(1, 1)` default, so this
## double's behavior for a plain single-cell entry is byte-for-byte
## unchanged from the pre-016 double.
class _MockItemDatabase:
	var _ready_state: bool = true
	var _entries: Dictionary[StringName, ItemDefinition] = {}

	func add_entry(
		id: StringName,
		category: StringName,
		tier: int,
		material_family: StringName = &"none",
		footprint: Vector2i = Vector2i(1, 1)
	) -> void:
		var resource := ItemDefinitionResource.new()
		resource.id = id
		resource.display_name = String(id)
		resource.category = category
		resource.material_family = material_family
		resource.tier = tier
		resource.storage_category = &"raw_material"
		resource.footprint = footprint
		_entries[id] = ItemDefinition.new(resource)

	func set_ready(value: bool) -> void:
		_ready_state = value

	func is_ready() -> bool:
		return _ready_state

	func get_by_id(id: StringName) -> Variant:
		return _entries.get(id)

	func list_ids_by_tier(tier: int) -> Array:
		var ids: Array = []
		for id: StringName in _entries:
			if _entries[id].get_tier() == tier:
				ids.append(id)
		return ids

	func list_ids_by_category(category: StringName) -> Array:
		var ids: Array = []
		for id: StringName in _entries:
			if _entries[id].get_category() == category:
				ids.append(id)
		return ids


# ---------------------------------------------------------------------------
# Test helpers (mirrors furniture_placement_base_test.gd's established
# precedent)
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_machine_armed() -> ToolStateMachine:
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"furniture")
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
	return pipeline


func _new_furniture_tool(grid: VoxelWorldGrid, pipeline: CommitPipeline) -> FurnitureTool:
	var tool: FurnitureTool = auto_free(FurnitureTool.new())
	tool.voxel_world = grid
	tool.commit_pipeline = pipeline
	tool.setup()
	return tool


## The reference solid cell every helper below aims [PlacementPick]'s own ray
## at -- mirrors `furniture_placement_base_test.gd`'s own established
## `_REFERENCE_SOLID_CELL` precedent: an entirely empty grid never registers
## a "hit" pick at all (AC38's gate), and [method CommitPipeline.commit]'s
## own candidate-cell parameter is completely independent of wherever the
## live pick itself points -- this reference cell only needs to exist
## somewhere far from every test's own cells.
const _REFERENCE_SOLID_CELL: Vector3i = Vector3i(50, 3, 50)


## Wires a fully-armed furniture commit pipeline (resolver + support
## predicate + a REAL bed-shaped RID double, footprint `(1, 2)` by default)
## with a currently-valid pick, AND registers [method
## FurnitureTool.resolve_cell_set] as the live cell-set resolver -- unlike
## `furniture_placement_base_test.gd`'s own wiring (which calls
## [method CommitPipeline.commit] directly with an explicit single-cell
## array), this story's own tests must exercise the resolver so the
## footprint is actually EXPANDED before [method CommitPipeline.commit]
## ever runs.
func _new_furniture_pipeline(grid: VoxelWorldGrid, footprint: Vector2i = Vector2i(1, 2)) -> Dictionary:
	grid.set_cell(_REFERENCE_SOLID_CELL, CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(
		Vector3(_REFERENCE_SOLID_CELL.x + 0.5, 20.0, _REFERENCE_SOLID_CELL.z + 0.5), Vector3(0.0, -1.0, 0.0)
	)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var database := _MockItemDatabase.new()
	database.add_entry(&"bed", &"furniture_fixture", 1, &"none", footprint)
	pipeline.resource_item_database = database
	pipeline.set_selected_item(&"bed")
	var tool: FurnitureTool = _new_furniture_tool(grid, pipeline)
	pipeline.set_furniture_support_predicate(tool.is_cell_supported)
	pipeline.set_cell_set_resolver(tool.resolve_cell_set)
	return {"pipeline": pipeline, "tool": tool, "database": database}


func _new_tick_loop(grid: VoxelWorldGrid, mock_tick: MockTimeTickSystem, registry: FurnitureRegistry) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = ConstructionTickLoopConfig.new()
	loop.time_tick_system = mock_tick
	loop.setup()
	loop.furniture_registry = registry
	return loop


# ---------------------------------------------------------------------------
# F5 generalization — furniture_cell_set is per-item, not hardcoded to 1
# ---------------------------------------------------------------------------

func test_furniture_cell_set_degenerates_to_one_cell_for_1x1_footprint() -> void:
	var anchor := Vector3i(2, 1, 2)

	var cells: Array[Vector3i] = FurnitureTool.furniture_cell_set(anchor, Vector2i(1, 1))

	assert_array(cells).contains_exactly([anchor])


func test_furniture_cell_set_expands_1x2_footprint_to_two_cells() -> void:
	var anchor := Vector3i(2, 1, 2)

	var cells: Array[Vector3i] = FurnitureTool.furniture_cell_set(anchor, Vector2i(1, 2))

	assert_array(cells).contains_exactly_in_any_order([anchor, anchor + Vector3i(0, 0, 1)])


func test_furniture_cell_set_expands_2x2_footprint_to_four_cells() -> void:
	var anchor := Vector3i(2, 1, 2)

	var cells: Array[Vector3i] = FurnitureTool.furniture_cell_set(anchor, Vector2i(2, 2))

	assert_array(cells).contains_exactly_in_any_order([
		anchor, anchor + Vector3i(1, 0, 0), anchor + Vector3i(0, 0, 1), anchor + Vector3i(1, 0, 1),
	])


# ---------------------------------------------------------------------------
# CommitPipeline.get_selected_item_footprint — resolution + fallback
# ---------------------------------------------------------------------------

func test_get_selected_item_footprint_returns_authored_dimensions_for_bed() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 2))
	var pipeline: CommitPipeline = wiring["pipeline"]

	assert_vector(pipeline.get_selected_item_footprint()).is_equal(Vector2i(1, 2))


func test_get_selected_item_footprint_defaults_to_1x1_when_database_unwired() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	pipeline.set_selected_item(&"bed")

	assert_vector(pipeline.get_selected_item_footprint()).is_equal(Vector2i(1, 1))


func test_get_selected_item_footprint_defaults_to_1x1_when_nothing_selected() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 2))
	var pipeline: CommitPipeline = wiring["pipeline"]
	pipeline.set_selected_item(&"")

	assert_vector(pipeline.get_selected_item_footprint()).is_equal(Vector2i(1, 1))


# ---------------------------------------------------------------------------
# AC75 — no partial placement of a multi-cell footprint [TR-building-system-124]
# ---------------------------------------------------------------------------

func test_multi_cell_commit_valid_when_both_footprint_cells_supported_and_free() -> void:
	# Arrange — solid ground under BOTH of the bed's two footprint cells.
	var grid: VoxelWorldGrid = _new_grid()
	var anchor := Vector3i(2, 1, 2)
	var second_cell: Vector3i = anchor + Vector3i(0, 0, 1)
	grid.set_cell(anchor + Vector3i(0, -1, 0), CellContents.new(1, 0))
	grid.set_cell(second_cell + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 2))
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]

	# Act
	var created: Array[BlueprintCell] = pipeline.commit(tool.resolve_cell_set(false, anchor, anchor))

	# Assert — exactly one BlueprintCell per footprint cell, both FURNITURE,
	# both sharing the SAME group.
	assert_int(created.size()).is_equal(2)
	assert_int(created[0].category).is_equal(BlueprintCell.Category.FURNITURE)
	assert_int(created[1].category).is_equal(BlueprintCell.Category.FURNITURE)
	assert_object(created[0].footprint_group).is_not_null()
	assert_object(created[0].footprint_group).is_same(created[1].footprint_group)


func test_multi_cell_commit_rejected_when_one_footprint_cell_is_unsupported() -> void:
	# Arrange — only the ANCHOR cell has ground below it; the second
	# footprint cell floats over nothing.
	var grid: VoxelWorldGrid = _new_grid()
	var anchor := Vector3i(3, 1, 3)
	grid.set_cell(anchor + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 2))
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]
	var received: Array = []
	pipeline.commit_rejected.connect(
		func(reason: CommitPipeline.RejectReason, cells: Array[Vector3i]) -> void:
			received.append([reason, cells])
	)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit(tool.resolve_cell_set(false, anchor, anchor))

	# Assert — the ENTIRE commit is rejected, not just the unsupported cell.
	assert_int(created.size()).is_equal(0)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.FURNITURE_UNSUPPORTED)
	assert_bool(pipeline.has_blueprint_cell(anchor)).is_false()


func test_multi_cell_commit_rejected_when_one_footprint_cell_overlaps_existing_blueprint() -> void:
	# Arrange — a plain (BLOCK-category) blueprint already occupies the
	# SECOND footprint cell before the bed is committed.
	var grid: VoxelWorldGrid = _new_grid()
	var anchor := Vector3i(4, 1, 4)
	var second_cell: Vector3i = anchor + Vector3i(0, 0, 1)
	grid.set_cell(anchor + Vector3i(0, -1, 0), CellContents.new(1, 0))
	grid.set_cell(second_cell + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 2))
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]
	var database: _MockItemDatabase = wiring["database"]
	database.add_entry(&"placeholder_floor_material", &"building_material", 0, &"wood")
	pipeline.set_selected_item(&"placeholder_floor_material")
	var blocking_created: Array[BlueprintCell] = pipeline.commit([second_cell])
	assert_int(blocking_created.size()).is_equal(1)
	pipeline.set_selected_item(&"bed")

	# Act
	var created: Array[BlueprintCell] = pipeline.commit(tool.resolve_cell_set(false, anchor, anchor))

	# Assert
	assert_int(created.size()).is_equal(0)
	assert_bool(pipeline.has_blueprint_cell(anchor)).is_false()


func test_multi_cell_commit_rejected_when_one_footprint_cell_is_out_of_bounds() -> void:
	# Arrange — anchor sits one cell short of the world's Z edge, so the
	# bed's second footprint cell falls outside world bounds.
	var grid: VoxelWorldGrid = _new_grid()
	var config: VoxelWorldConfig = grid.config
	var anchor := Vector3i(5, 1, config.world_depth_cells - 1)
	grid.set_cell(anchor + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 2))
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]
	var received: Array = []
	pipeline.commit_rejected.connect(
		func(reason: CommitPipeline.RejectReason, cells: Array[Vector3i]) -> void:
			received.append([reason, cells])
	)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit(tool.resolve_cell_set(false, anchor, anchor))

	# Assert — rejected outright, with visible feedback (never silently),
	# unlike a drag tool's partial bounds-clamp (Edge Case 1).
	assert_int(created.size()).is_equal(0)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.FOOTPRINT_OUT_OF_BOUNDS)


func test_multi_cell_commit_valid_when_one_cell_supported_by_draft_blueprint_floor() -> void:
	# Arrange — the anchor's support is a real ground cell; the second
	# footprint cell's support is a Draft (not-yet-Built) floor blueprint --
	# AC49's "a blueprint floor cell counts as support for a furniture
	# blueprint" generalized to a multi-cell footprint.
	var grid: VoxelWorldGrid = _new_grid()
	var anchor := Vector3i(6, 1, 6)
	var second_cell: Vector3i = anchor + Vector3i(0, 0, 1)
	var second_support: Vector3i = second_cell + Vector3i(0, -1, 0)
	grid.set_cell(anchor + Vector3i(0, -1, 0), CellContents.new(1, 0))
	grid.set_cell(_REFERENCE_SOLID_CELL, CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(
		Vector3(_REFERENCE_SOLID_CELL.x + 0.5, 20.0, _REFERENCE_SOLID_CELL.z + 0.5), Vector3(0.0, -1.0, 0.0)
	)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var database := _MockItemDatabase.new()
	database.add_entry(&"placeholder_floor_material", &"building_material", 0, &"wood")
	database.add_entry(&"bed", &"furniture_fixture", 1, &"none", Vector2i(1, 2))
	pipeline.resource_item_database = database
	var tool: FurnitureTool = _new_furniture_tool(grid, pipeline)
	pipeline.set_selected_item(&"placeholder_floor_material")
	var floor_created: Array[BlueprintCell] = pipeline.commit([second_support])
	assert_int(floor_created.size()).is_equal(1)
	assert_int(floor_created[0].state).is_equal(BlueprintCell.MicroState.PLANNED)
	pipeline.set_furniture_support_predicate(tool.is_cell_supported)
	pipeline.set_cell_set_resolver(tool.resolve_cell_set)
	pipeline.set_selected_item(&"bed")

	# Act
	var created: Array[BlueprintCell] = pipeline.commit(tool.resolve_cell_set(false, anchor, anchor))

	# Assert
	assert_int(created.size()).is_equal(2)


# ---------------------------------------------------------------------------
# AC76 — exactly one furniture entity, shared occupant id [TR-building-system-124]
# ---------------------------------------------------------------------------

func test_1x1_footprint_still_yields_furniture_cell_count_one() -> void:
	# Regression guard: the generalized footprint path must not change
	# Story building-028's own single-cell behavior.
	var grid: VoxelWorldGrid = _new_grid()
	var anchor := Vector3i(7, 1, 7)
	grid.set_cell(anchor + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 1))
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]

	var created: Array[BlueprintCell] = pipeline.commit(tool.resolve_cell_set(false, anchor, anchor))

	assert_int(created.size()).is_equal(1)
	assert_object(created[0].footprint_group).is_null()

	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var registry := FurnitureRegistry.new()
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_tick_loop(grid, mock_tick, registry)
	assert_bool(loop.claim_job(created[0], 1)).is_true()
	for i in range(loop_config.base_build_ticks_furniture):
		mock_tick.fire_tick()

	var placed: Array[Dictionary] = registry.get_placed_furniture()
	assert_int(placed.size()).is_equal(1)
	assert_int((placed[0]["cells"] as Array).size()).is_equal(1)


func test_multi_cell_completion_in_the_same_tick_dispatch_registers_exactly_one_entity() -> void:
	# Both footprint cells claimed by DIFFERENT villagers before any tick
	# fires, so both reach their completion threshold in the SAME
	# [method ConstructionTickLoop._on_tick] dispatch -- proves the
	# is_registered dedup guard (two siblings completing at once must not
	# create two entities).
	var grid: VoxelWorldGrid = _new_grid()
	var anchor := Vector3i(8, 1, 8)
	var second_cell: Vector3i = anchor + Vector3i(0, 0, 1)
	grid.set_cell(anchor + Vector3i(0, -1, 0), CellContents.new(1, 0))
	grid.set_cell(second_cell + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 2))
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]
	var created: Array[BlueprintCell] = pipeline.commit(tool.resolve_cell_set(false, anchor, anchor))
	assert_int(created.size()).is_equal(2)

	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var registry := FurnitureRegistry.new()
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_tick_loop(grid, mock_tick, registry)
	var emit_count: Array[int] = [0]
	registry.furniture_changed.connect(func() -> void: emit_count[0] += 1)

	# Act — claim BOTH cells first (different villagers), then tick.
	assert_bool(loop.claim_job(created[0], 1)).is_true()
	assert_bool(loop.claim_job(created[1], 2)).is_true()
	for i in range(loop_config.base_build_ticks_furniture):
		mock_tick.fire_tick()

	# Assert — exactly ONE registry entry, spanning both cells, exactly one
	# furniture_changed emission (never two).
	var placed: Array[Dictionary] = registry.get_placed_furniture()
	assert_int(placed.size()).is_equal(1)
	assert_int(emit_count[0]).is_equal(1)
	var cells: Array = placed[0]["cells"]
	assert_int(cells.size()).is_equal(2)
	assert_bool(cells.has(anchor)).is_true()
	assert_bool(cells.has(second_cell)).is_true()
	assert_str(String(placed[0]["definition_id"])).is_equal("bed")


func test_multi_cell_completion_across_different_tick_dispatches_still_registers_one_entity() -> void:
	# The two footprint cells are claimed and completed at DIFFERENT times
	# (cellA finishes fully BEFORE cellB is even claimed) -- proves grouping
	# is order-independent, not just same-dispatch-safe. Villager AI's own
	# per-cell claim parallelism (Core Rule 12) means this is a realistic
	# outcome, not a contrived one.
	var grid: VoxelWorldGrid = _new_grid()
	var anchor := Vector3i(9, 1, 9)
	var second_cell: Vector3i = anchor + Vector3i(0, 0, 1)
	grid.set_cell(anchor + Vector3i(0, -1, 0), CellContents.new(1, 0))
	grid.set_cell(second_cell + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, Vector2i(1, 2))
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]
	var created: Array[BlueprintCell] = pipeline.commit(tool.resolve_cell_set(false, anchor, anchor))
	assert_int(created.size()).is_equal(2)

	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var registry := FurnitureRegistry.new()
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_tick_loop(grid, mock_tick, registry)

	# Act — cell A is claimed and fully completed FIRST, alone.
	assert_bool(loop.claim_job(created[0], 1)).is_true()
	for i in range(loop_config.base_build_ticks_furniture):
		mock_tick.fire_tick()
	assert_int(created[0].state).is_equal(BlueprintCell.MicroState.BUILT)

	# Assert (mid-point) — nothing registered yet; the other sibling is
	# still un-claimed (PLANNED), so the group is not yet complete.
	assert_bool(registry.is_empty()).is_true()

	# Act — cell B is claimed and completed LATER, by a different villager.
	assert_bool(loop.claim_job(created[1], 2)).is_true()
	for i in range(loop_config.base_build_ticks_furniture):
		mock_tick.fire_tick()

	# Assert — exactly ONE entity now exists, spanning both cells; either
	# footprint cell resolves to the SAME occupant id.
	var placed: Array[Dictionary] = registry.get_placed_furniture()
	assert_int(placed.size()).is_equal(1)
	var item_id: String = placed[0]["item_id"]
	assert_str(registry.get_occupant_at(anchor)).is_equal(item_id)
	assert_str(registry.get_occupant_at(second_cell)).is_equal(item_id)
