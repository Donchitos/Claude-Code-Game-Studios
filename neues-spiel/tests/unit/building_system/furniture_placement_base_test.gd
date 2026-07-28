## Unit test — Building System Story building-028 (Furniture placement base:
## single-cell support + palette query). ADR-0016 primary (BV-1 ruling,
## `production/architecture-decisions-m02-preflight-2026-07-26.md`: furniture
## is not voxel data, never enters VoxelWorldGrid); ADR-0006 secondary (RID
## opaque-id palette query).
##
## Proves:
## 1. AC16 [TR-building-system-048]: an unsupported furniture cell (empty
##    below) is rejected (FURNITURE_UNSUPPORTED); a supported one (occupied
##    below, raw grid) is valid.
## 2. AC49 [TR-building-system-050]: a bed blueprint targeting a cell
##    supported by a Draft (not-yet-Built) blueprint FLOOR cell is a VALID
##    commit (the claim-time "construction cannot start until Built" half of
##    AC49 is covered by `construction_tick_loop_test.gd`'s own dedicated
##    tests, alongside the routing/never-bulk_writes regression).
## 3. AC18 [TR-building-system-074]: the palette is exactly the tier-0
##    `building_material` set UNION `furniture_fixture` (never tier-gated for
##    furniture) — a tier-1 material variant and an unrelated other-tier
##    entry are both excluded from the materials half.
## 4. AC19 [TR-building-system-059]: no resource is consumed by a furniture
##    commit or its completion — grep-guard (no resource/inventory/economy
##    consumption API referenced anywhere in this story's own new source
##    files) plus a behavioral proof that the full commit -> claim ->
##    complete cycle succeeds with zero resource-consuming collaborator
##    wired anywhere.
## 5. BV-1 inherited AC (a): a FURNITURE-category commit that completes
##    construction leaves `voxel_world.get_cell()` empty at that cell,
##    proven end-to-end through the real [FurnitureTool]/[CommitPipeline]/
##    [ConstructionTickLoop] pipeline (not just `ConstructionTickLoop` in
##    isolation, which `construction_tick_loop_test.gd` already covers).
## 6. BV-1 inherited AC (b): [FurnitureRegistry] exposes the exact duck-typed
##    provider shape `build_validation.gd` documents itself as consuming --
##    `get_placed_furniture() -> Array[Dictionary]` shaped `{"item_id":
##    String, "definition_id": StringName, "cells": Array[Vector3i]}`, and a
##    zero-argument `furniture_changed` signal firing once per placement.
class_name FurniturePlacementBaseTest
extends GdUnitTestSuite

const BUILDING_SYSTEM_DIR: String = "res://src/building_system/"
const FURNITURE_TOOL_SOURCE_PATH: String = "res://src/building_system/furniture_tool.gd"
const FURNITURE_REGISTRY_SOURCE_PATH: String = "res://src/building_system/furniture_registry.gd"


# ---------------------------------------------------------------------------
# Test doubles (inner helper classes — kept ABOVE every test function)
# ---------------------------------------------------------------------------

## RID-shaped test double wrapping REAL [ItemDefinition]/[ItemDefinitionResource]
## value objects (never a bare bool/null like `placement_validity_test.gd`'s
## own `_MockItemDatabase` — this story's category/tier detection genuinely
## needs a real `ItemDefinition` to query, see [method
## CommitPipeline._selected_item_is_furniture]'s own doc comment for why a
## bare `bool`/`null` double safely falls through to BLOCK instead).
class _MockItemDatabase:
	var _ready_state: bool = true
	var _entries: Dictionary[StringName, ItemDefinition] = {}

	func add_entry(id: StringName, category: StringName, tier: int, material_family: StringName = &"none") -> void:
		var resource := ItemDefinitionResource.new()
		resource.id = id
		resource.display_name = String(id)
		resource.category = category
		resource.material_family = material_family
		resource.tier = tier
		resource.storage_category = &"raw_material"
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
# Test helpers (mirrors placement_validity_test.gd's established precedent)
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
## at -- mirrors `placement_validity_test.gd`'s own established
## `_new_grid_with_solid_cell(Vector3i(5, 3, 5))` precedent exactly: an
## entirely empty grid never registers a "hit" pick at all (AC38's gate), and
## [method CommitPipeline.commit]'s own candidate-cell parameter is
## completely independent of wherever the live pick itself points -- so this
## reference cell only needs to exist somewhere far from every test's own
## cells, never at the cell under test.
const _REFERENCE_SOLID_CELL: Vector3i = Vector3i(20, 3, 20)


## Wires a fully-armed furniture commit pipeline (resolver + support
## predicate + a real bed-shaped RID double selected) with a currently-valid
## pick (see [constant _REFERENCE_SOLID_CELL]'s own doc comment) -- the
## shared arrangement every commit-time test below starts from.
func _new_furniture_pipeline(grid: VoxelWorldGrid, _press_cell: Vector3i) -> Dictionary:
	grid.set_cell(_REFERENCE_SOLID_CELL, CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(
		Vector3(_REFERENCE_SOLID_CELL.x + 0.5, 20.0, _REFERENCE_SOLID_CELL.z + 0.5), Vector3(0.0, -1.0, 0.0)
	)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var database := _MockItemDatabase.new()
	database.add_entry(&"bed", &"furniture_fixture", 1)
	pipeline.resource_item_database = database
	pipeline.set_selected_item(&"bed")
	var tool: FurnitureTool = _new_furniture_tool(grid, pipeline)
	pipeline.set_furniture_support_predicate(tool.is_cell_supported)
	return {"pipeline": pipeline, "tool": tool, "database": database}


# ---------------------------------------------------------------------------
# AC16 — furniture support requirement [TR-building-system-048]
# ---------------------------------------------------------------------------

func test_furniture_commit_targeting_an_unsupported_cell_is_rejected() -> void:
	# Arrange — nothing below the target cell at all.
	var grid: VoxelWorldGrid = _new_grid()
	var press_cell := Vector3i(2, 0, 2)
	var wiring: Dictionary = _new_furniture_pipeline(grid, press_cell)
	var pipeline: CommitPipeline = wiring["pipeline"]
	var received: Array = []
	pipeline.commit_rejected.connect(
		func(reason: CommitPipeline.RejectReason, cells: Array[Vector3i]) -> void:
			received.append([reason, cells])
	)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([press_cell])

	# Assert
	assert_int(created.size()).is_equal(0)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.FURNITURE_UNSUPPORTED)


func test_furniture_commit_targeting_a_supported_cell_is_valid() -> void:
	# Arrange — a solid ground cell directly below the target.
	var grid: VoxelWorldGrid = _new_grid()
	var press_cell := Vector3i(2, 1, 2)
	grid.set_cell(press_cell + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, press_cell)
	var pipeline: CommitPipeline = wiring["pipeline"]

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([press_cell])

	# Assert
	assert_int(created.size()).is_equal(1)
	assert_int(created[0].category).is_equal(BlueprintCell.Category.FURNITURE)
	assert_str(String(created[0].furniture_definition_id)).is_equal("bed")


# ---------------------------------------------------------------------------
# AC49 — a blueprint (not-yet-Built) floor cell counts as commit-time support
# [TR-building-system-050]
# ---------------------------------------------------------------------------

## Builds a bare commit pipeline (mirrors [method _new_pipeline], with a
## currently-valid pick and a mock RID double carrying both a plain
## `placeholder_floor_material` (`building_material`, tier 0) and `bed`
## entry) with NO furniture-support predicate wired yet -- exactly the state
## while a NON-furniture tool (e.g. the floor tool) is armed. [FurnitureTool]
## is constructed but its predicate is deliberately NOT registered into
## [param pipeline] until the caller "arms" it (mirrors production: arming a
## different tool would not carry the furniture tool's own predicate along
## with it -- a plain BLOCK commit must never be support-gated).
func _new_pipeline_before_furniture_armed(grid: VoxelWorldGrid) -> Dictionary:
	grid.set_cell(_REFERENCE_SOLID_CELL, CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(
		Vector3(_REFERENCE_SOLID_CELL.x + 0.5, 20.0, _REFERENCE_SOLID_CELL.z + 0.5), Vector3(0.0, -1.0, 0.0)
	)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var database := _MockItemDatabase.new()
	database.add_entry(&"placeholder_floor_material", &"building_material", 0, &"wood")
	database.add_entry(&"bed", &"furniture_fixture", 1)
	pipeline.resource_item_database = database
	var tool: FurnitureTool = _new_furniture_tool(grid, pipeline)
	return {"pipeline": pipeline, "tool": tool}


func test_furniture_commit_supported_by_a_draft_blueprint_floor_cell_is_valid() -> void:
	# Arrange — commit a plain (BLOCK-category) blueprint cell directly below
	# the furniture target FIRST, with NO furniture-support predicate wired
	# yet (the floor tool, not the furniture tool, is "armed") — it stays
	# PLANNED (never Built), yet must still count as valid support once the
	# furniture tool arms and commits on top of it.
	var grid: VoxelWorldGrid = _new_grid()
	var press_cell := Vector3i(3, 1, 3)
	var floor_cell: Vector3i = press_cell + Vector3i(0, -1, 0)
	var wiring: Dictionary = _new_pipeline_before_furniture_armed(grid)
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]
	pipeline.set_selected_item(&"placeholder_floor_material")
	var floor_created: Array[BlueprintCell] = pipeline.commit([floor_cell])
	assert_int(floor_created.size()).is_equal(1)
	assert_int(floor_created[0].state).is_equal(BlueprintCell.MicroState.PLANNED)

	# Act — arm the furniture tool (wire its support predicate NOW, exactly
	# as arming would in production) and commit the bed on top.
	pipeline.set_furniture_support_predicate(tool.is_cell_supported)
	pipeline.set_selected_item(&"bed")
	var furniture_created: Array[BlueprintCell] = pipeline.commit([press_cell])

	# Assert — valid despite the floor cell never having reached Built.
	assert_int(furniture_created.size()).is_equal(1)
	assert_int(furniture_created[0].category).is_equal(BlueprintCell.Category.FURNITURE)


func test_furniture_commit_supported_by_a_canceled_blueprint_floor_cell_is_rejected() -> void:
	# A CANCELED floor cell frees up its address (CommitPipeline's own
	# established combined-view rule) -- it must NOT count as support.
	var grid: VoxelWorldGrid = _new_grid()
	var press_cell := Vector3i(4, 1, 4)
	var floor_cell: Vector3i = press_cell + Vector3i(0, -1, 0)
	var wiring: Dictionary = _new_pipeline_before_furniture_armed(grid)
	var pipeline: CommitPipeline = wiring["pipeline"]
	var tool: FurnitureTool = wiring["tool"]
	pipeline.set_selected_item(&"placeholder_floor_material")
	var floor_created: Array[BlueprintCell] = pipeline.commit([floor_cell])
	assert_int(floor_created.size()).is_equal(1)
	floor_created[0].state = BlueprintCell.MicroState.CANCELED

	pipeline.set_furniture_support_predicate(tool.is_cell_supported)
	pipeline.set_selected_item(&"bed")
	var furniture_created: Array[BlueprintCell] = pipeline.commit([press_cell])

	assert_int(furniture_created.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC18 — palette contents [TR-building-system-074]
# ---------------------------------------------------------------------------

func test_palette_offers_exactly_tier0_materials_and_bed() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var database := _MockItemDatabase.new()
	database.add_entry(&"wood_wall", &"building_material", 0, &"wood")
	database.add_entry(&"stone_block", &"building_material", 0, &"stone")
	database.add_entry(&"stone_block_variant", &"building_material", 1, &"stone")
	database.add_entry(&"bed", &"furniture_fixture", 1)
	pipeline.resource_item_database = database

	# Act
	var palette: Array[StringName] = pipeline.get_available_palette()

	# Assert — exactly the two tier-0 materials plus bed; the tier-1 variant
	# is excluded even though it shares its family with a tier-0 entry, and
	# bed is included despite being tier 1 (furniture is never tier-gated).
	assert_array(palette).contains_exactly_in_any_order([&"wood_wall", &"stone_block", &"bed"])


func test_palette_is_empty_when_resource_item_database_is_unwired() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)

	var palette: Array[StringName] = pipeline.get_available_palette()

	assert_array(palette).is_empty()


func test_palette_is_empty_when_resource_item_database_is_not_ready() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var database := _MockItemDatabase.new()
	database.add_entry(&"bed", &"furniture_fixture", 1)
	database.set_ready(false)
	pipeline.resource_item_database = database

	var palette: Array[StringName] = pipeline.get_available_palette()

	assert_array(palette).is_empty()


# ---------------------------------------------------------------------------
# AC19 — no resource is consumed [TR-building-system-059]
# ---------------------------------------------------------------------------

func test_no_resource_or_inventory_consumption_api_referenced_in_furniture_source() -> void:
	# Grep-verifiable AC: neither of this story's own new source files
	# references any resource-consumption/inventory-deduction API -- there is
	# structurally nothing here THAT COULD consume a resource.
	var banned_substrings: Array[String] = [
		"Inventory",
		"Economy",
		"consume_resource",
		"deduct",
	]
	for path: String in [FURNITURE_TOOL_SOURCE_PATH, FURNITURE_REGISTRY_SOURCE_PATH]:
		var source: String = _read_gd_source_without_comments(path)
		for banned: String in banned_substrings:
			assert_bool(source.contains(banned)).is_false()


func test_furniture_commit_and_completion_succeed_with_no_resource_collaborator_wired() -> void:
	# Behavioral half of AC19 -- the full commit -> claim -> complete cycle
	# succeeds with ONLY voxel_world/RID/furniture_registry wired anywhere;
	# no economy/inventory collaborator exists to wire in the first place.
	var grid: VoxelWorldGrid = _new_grid()
	var press_cell := Vector3i(6, 1, 6)
	grid.set_cell(press_cell + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, press_cell)
	var pipeline: CommitPipeline = wiring["pipeline"]
	var created: Array[BlueprintCell] = pipeline.commit([press_cell])
	assert_int(created.size()).is_equal(1)

	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = loop_config
	loop.time_tick_system = mock_tick
	loop.setup()
	var registry := FurnitureRegistry.new()
	loop.furniture_registry = registry

	assert_bool(loop.claim_job(created[0], 1)).is_true()
	for i in range(loop_config.base_build_ticks_furniture):
		mock_tick.fire_tick()

	assert_int(created[0].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(registry.get_placed_furniture().size()).is_equal(1)


# ---------------------------------------------------------------------------
# BV-1 inherited AC (a) — end-to-end: a completed furniture commit never
# touches VoxelWorldGrid
# ---------------------------------------------------------------------------

func test_end_to_end_furniture_commit_completion_never_writes_the_grid() -> void:
	# Arrange — full pipeline: FurnitureTool + CommitPipeline + ConstructionTickLoop
	# + FurnitureRegistry, exactly as a future scene-assembly story would wire it.
	var grid: VoxelWorldGrid = _new_grid()
	var press_cell := Vector3i(7, 1, 7)
	grid.set_cell(press_cell + Vector3i(0, -1, 0), CellContents.new(1, 0))
	var wiring: Dictionary = _new_furniture_pipeline(grid, press_cell)
	var pipeline: CommitPipeline = wiring["pipeline"]
	var created: Array[BlueprintCell] = pipeline.commit([press_cell])
	assert_int(created.size()).is_equal(1)

	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = loop_config
	loop.time_tick_system = mock_tick
	loop.setup()
	var registry := FurnitureRegistry.new()
	loop.furniture_registry = registry

	# Act
	assert_bool(loop.claim_job(created[0], 42)).is_true()
	for i in range(loop_config.base_build_ticks_furniture):
		mock_tick.fire_tick()

	# Assert — BUILT as a job, never written into VoxelWorldGrid, and
	# enumerable through the registry with the correct definition id/cell.
	assert_int(created[0].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(grid.get_cell(press_cell).is_empty()).is_true()
	var placed: Array[Dictionary] = registry.get_placed_furniture()
	assert_int(placed.size()).is_equal(1)
	assert_str(String(placed[0]["definition_id"])).is_equal("bed")
	assert_bool((placed[0]["cells"] as Array).has(press_cell)).is_true()


# ---------------------------------------------------------------------------
# BV-1 inherited AC (b) — FurnitureRegistry's duck-typed provider shape
# (`build_validation.gd`'s own documented consumer contract)
# ---------------------------------------------------------------------------

func test_furniture_registry_place_assigns_a_fresh_item_id_and_emits_furniture_changed() -> void:
	var registry := FurnitureRegistry.new()
	# GDScript lambda closures capture a scalar local BY VALUE, not by
	# reference -- an `int`/`bool` incremented/assigned inside the lambda
	# never mutates the outer variable. A single-element `Array` is captured
	# by reference (mirrors this codebase's own established workaround for
	# exactly this pitfall), so the count is genuinely observable afterward.
	var emit_count: Array[int] = [0]
	registry.furniture_changed.connect(func() -> void: emit_count[0] += 1)

	var first_id: String = registry.place(&"bed", [Vector3i(1, 0, 1)])
	var second_id: String = registry.place(&"bed", [Vector3i(2, 0, 2)])

	assert_str(first_id).is_not_equal(second_id)
	assert_int(emit_count[0]).is_equal(2)


func test_get_placed_furniture_shape_matches_build_validations_documented_contract() -> void:
	# `build_validation.gd`'s own doc comment documents this EXACT shape:
	# {"item_id": String, "definition_id": StringName, "cells": Array[Vector3i]}.
	var registry := FurnitureRegistry.new()
	var item_id: String = registry.place(&"bed", [Vector3i(5, 0, 5)])

	var placed: Array[Dictionary] = registry.get_placed_furniture()

	assert_int(placed.size()).is_equal(1)
	var record: Dictionary = placed[0]
	assert_bool(record["item_id"] is String).is_true()
	assert_str(record["item_id"]).is_equal(item_id)
	assert_bool(record["definition_id"] is StringName).is_true()
	assert_str(String(record["definition_id"])).is_equal("bed")
	assert_bool(record["cells"] is Array).is_true()
	assert_bool((record["cells"] as Array).has(Vector3i(5, 0, 5))).is_true()


func test_empty_registry_returns_empty_enumeration_without_ever_emitting() -> void:
	var registry := FurnitureRegistry.new()
	# See the previous test's own doc comment -- a boxed `Array[bool]`, never
	# a bare `bool`, so the lambda's write is genuinely observable.
	var emitted: Array[bool] = [false]
	registry.furniture_changed.connect(func() -> void: emitted[0] = true)

	assert_bool(registry.is_empty()).is_true()
	assert_array(registry.get_placed_furniture()).is_empty()
	assert_bool(emitted[0]).is_false()


func test_one_occupant_per_cell_reverse_index_reports_the_placed_item() -> void:
	var registry := FurnitureRegistry.new()
	assert_bool(registry.has_occupant(Vector3i(8, 0, 8))).is_false()
	assert_str(registry.get_occupant_at(Vector3i(8, 0, 8))).is_equal("")

	var item_id: String = registry.place(&"bed", [Vector3i(8, 0, 8)])

	assert_bool(registry.has_occupant(Vector3i(8, 0, 8))).is_true()
	assert_str(registry.get_occupant_at(Vector3i(8, 0, 8))).is_equal(item_id)


# ---------------------------------------------------------------------------
# Shared helper (mirrors `dda_placement_pick_test.gd`'s established
# grep-guard precedent)
# ---------------------------------------------------------------------------

## Reads a single `.gd` source file, stripping full-line `#`/`##` doc-comment
## lines first -- mirrors this codebase's established
## `_read_gd_source_without_comments` precedent (`dda_placement_pick_test.gd`)
## so a file's own doc comments (which legitimately reason about resource
## consumption to document its absence) are never mistaken for a violation.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined
