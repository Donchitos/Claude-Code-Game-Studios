## Unit test — Building System Story building-022 (Placement validity:
## occupied-cell/terrain-replace rejection, the `max_cells_per_command` cap,
## material/furniture-selection availability, and the furniture-support
## predicate seam). ADR-0016 primary (combined-view planned occupancy owned
## by this system, never raw Voxel World state alone).
##
## Proves:
## 1. AC10/AC11/AC14 [TR-building-system-084]/[TR-building-system-085]
##    (Edge Cases 2/3): a commit targeting an already-occupied constructed/
##    terrain cell (non-replace), a cell already holding a Draft blueprint
##    cell, or a terrain cell via replace-in-place is rejected outright --
##    zero blueprint cells created, [signal CommitPipeline.commit_rejected]
##    fires with [constant CommitPipeline.RejectReason.CELL_OCCUPIED].
## 2. The two Edge Case 2 exceptions: replace-in-place of an already-BUILT
##    (player-constructed) cell IS valid; attaching to a terrain cell's face
##    (the adjacent EMPTY cell, never the terrain cell itself) IS valid.
## 3. Combined-view occupancy [TR-building-system-060]: a Draft blueprint
##    cell is invisible to raw Voxel World data (`grid.get_cell(...).is_empty()`
##    stays `true`) yet still blocks a second commit at the same address --
##    proving the combined view (blocks UNION blueprint cells), never raw
##    Voxel World state alone, is what [method CommitPipeline.commit] queries.
## 4. AC39 [TR-building-system-049]: a candidate set whose post-bounds-clamp
##    cell count exceeds `max_cells_per_command` is rejected in full (zero
##    cells created); exactly-at-the-cap still succeeds (boundary is `>`,
##    never `>=`).
## 5. AC42 [TR-building-system-049]: no material/furniture selected rejects
##    the commit; a selection that a wired [ResourceItemDatabase]-shaped
##    double reports unavailable also rejects it; a selection that double
##    reports available proceeds (Core Rule 9's full "selected AND
##    available" contract, not just the "nothing selected" half).
## 6. Furniture-support seam [TR-building-system-050]: an unsupported cell
##    (per a wired predicate) rejects the commit; a supported cell does not.
## 7. [signal CommitPipeline.commit_rejected] payload correctness (reason +
##    the full post-clamp candidate set) for a representative rejection.
class_name PlacementValidityTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles (inner helper classes — kept ABOVE every test function)
# ---------------------------------------------------------------------------

## Minimal RID-shaped test double proving [method
## CommitPipeline._is_selected_item_available]'s REAL palette-availability
## delegation (Core Rule 9) -- duck-typed against exactly the two members
## that method depends on: [method is_ready] and [method get_by_id].
class _MockItemDatabase:
	var _ready_state: bool = true
	var _available_ids: Dictionary[StringName, bool] = {}

	func mark_available(id: StringName) -> void:
		_available_ids[id] = true

	func set_ready(value: bool) -> void:
		_ready_state = value

	func is_ready() -> bool:
		return _ready_state

	func get_by_id(id: StringName) -> Variant:
		return true if _available_ids.has(id) else null


# ---------------------------------------------------------------------------
# Test helpers (mirrors commit_pipeline_test.gd's established precedent)
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


## Builds a pipeline with NO material selected and no [ResourceItemDatabase]
## reference wired -- every test opts in explicitly via [method
## _select_placeholder_material] or a wired [_MockItemDatabase], so the
## "nothing selected" default (AC42) is never accidentally masked.
func _new_pipeline(pick: PlacementPick, grid: VoxelWorldGrid) -> CommitPipeline:
	var pipeline: CommitPipeline = auto_free(CommitPipeline.new())
	pipeline.placement_pick = pick
	pipeline.voxel_world = grid
	pipeline.config = CommitPipelineConfig.new()
	pipeline.setup()
	return pipeline


## Selects a placeholder material via the documented MVP fallback (no
## [member CommitPipeline.resource_item_database] wired -- a non-empty
## selection is trusted at face value) -- used by every test that needs the
## material gate to pass without exercising its full availability contract
## (which the dedicated AC42 tests below cover separately with an explicit
## [_MockItemDatabase]).
func _select_placeholder_material(pipeline: CommitPipeline) -> void:
	pipeline.set_selected_item(&"placeholder_material")


func _connect_rejection_listener(pipeline: CommitPipeline) -> Array:
	var received: Array = []
	pipeline.commit_rejected.connect(
		func(reason: CommitPipeline.RejectReason, cells: Array[Vector3i]) -> void:
			received.append([reason, cells])
	)
	return received


# ---------------------------------------------------------------------------
# AC10/AC14 — occupied constructed/terrain cell (non-replace + replace-in-
# place both rejected) [TR-building-system-084]
# ---------------------------------------------------------------------------

func test_commit_targeting_an_occupied_terrain_cell_is_rejected() -> void:
	# Arrange — a terrain cell at (2,0,2): raw grid occupied, never tracked by
	# this pipeline (no commit ever ran through it) -- exactly how this class
	# distinguishes terrain from a cell it built itself.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	grid.set_cell(Vector3i(2, 0, 2), CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)
	var received: Array = _connect_rejection_listener(pipeline)

	# Act — AC14's exact scenario: replace-in-place targets the terrain cell
	# itself (the candidate cell IS the occupied terrain cell).
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(2, 0, 2)])

	# Assert — rejected in full; zero blueprint created.
	assert_int(created.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.CELL_OCCUPIED)
	var rejected_cells: Array = received[0][1]
	assert_int(rejected_cells.size()).is_equal(1)
	assert_bool(rejected_cells[0] == Vector3i(2, 0, 2)).is_true()


func test_commit_targeting_an_occupied_constructed_cell_non_replace_is_rejected() -> void:
	# Arrange — a cell this pipeline itself already built (tracked BUILT) is
	# still a valid replace-in-place target (Edge Case 2's own exception,
	# proven separately below) -- this test instead proves the general "any
	# OTHER already-occupied cell that is not a valid replace target" case
	# using a second, untracked terrain cell as the stand-in for "a
	# constructed block or terrain" AC10 names, distinct from AC14's own
	# dedicated replace-in-place framing above.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	grid.set_cell(Vector3i(3, 0, 3), CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)
	var received: Array = _connect_rejection_listener(pipeline)

	# Act — one occupied cell mixed with an otherwise-empty candidate; the
	# ALL-OR-NOTHING gate rejects the WHOLE commit, not just the bad cell.
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1), Vector3i(3, 0, 3)])

	# Assert
	assert_int(created.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)
	assert_bool(pipeline.has_blueprint_cell(Vector3i(1, 0, 1))).is_false()
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.CELL_OCCUPIED)


# ---------------------------------------------------------------------------
# AC11 — cell already holding a blueprint cell (Edge Case 3)
# [TR-building-system-085]
# ---------------------------------------------------------------------------

func test_commit_targeting_a_cell_holding_a_draft_blueprint_is_rejected() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)
	var first: Array[BlueprintCell] = pipeline.commit([Vector3i(4, 0, 4)])
	assert_int(first.size()).is_equal(1)
	assert_int(first[0].state).is_equal(BlueprintCell.MicroState.PLANNED)
	var received: Array = _connect_rejection_listener(pipeline)

	# Act — a second commit targets the SAME still-Draft cell.
	var second: Array[BlueprintCell] = pipeline.commit([Vector3i(4, 0, 4)])

	# Assert — rejected; the original Draft entry is untouched (still exactly
	# one tracked cell, not overwritten/duplicated).
	assert_int(second.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(1)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.CELL_OCCUPIED)


func test_draft_blueprint_cell_invisible_to_raw_voxel_world_still_blocks_combined_view() -> void:
	# QA Test Cases' own "combined-view occupancy" scenario -- proves this
	# system's own registry, NOT raw Voxel World data, is what a second
	# commit is checked against [TR-building-system-060].
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)
	pipeline.commit([Vector3i(6, 0, 6)])

	# Assert — invisible to Voxel World's own data layer...
	assert_bool(grid.get_cell(Vector3i(6, 0, 6)).is_empty()).is_true()

	# ...yet a second commit at the same address is still rejected.
	var second: Array[BlueprintCell] = pipeline.commit([Vector3i(6, 0, 6)])
	assert_int(second.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Edge Case 2 exceptions — replace-in-place of a BUILT cell IS valid; attach
# to a terrain face IS valid
# ---------------------------------------------------------------------------

func test_replace_in_place_of_an_already_built_cell_is_valid() -> void:
	# Arrange — commit, then simulate ConstructionTickLoop's own completion
	# contract directly on the shared BlueprintCell reference (mirrors
	# construction_tick_loop.gd's own `_complete_job`: write the grid, THEN
	# flip the microstate to BUILT) -- this pipeline's own tracked entry
	# becomes the "already-built" record this story's validity check reads.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)
	var built: Array[BlueprintCell] = pipeline.commit([Vector3i(7, 0, 7)])
	var built_cell: BlueprintCell = built[0]
	grid.set_cell(built_cell.cell, built_cell.contents)
	built_cell.state = BlueprintCell.MicroState.BUILT

	# Act — a fresh commit replaces the SAME now-Built cell.
	var replaced: Array[BlueprintCell] = pipeline.commit([Vector3i(7, 0, 7)])

	# Assert — valid: a new (second) BlueprintCell now tracks that address.
	assert_int(replaced.size()).is_equal(1)
	assert_int(replaced[0].state).is_equal(BlueprintCell.MicroState.PLANNED)


func test_attaching_to_a_terrain_cells_face_is_valid() -> void:
	# Arrange — a terrain cell at (2,0,2); the ATTACH target is the adjacent
	# EMPTY cell (2,1,2), never the terrain cell itself.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	grid.set_cell(Vector3i(2, 0, 2), CellContents.new(1, 0))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(2, 1, 2)])

	# Assert — valid.
	assert_int(created.size()).is_equal(1)
	assert_bool(pipeline.has_blueprint_cell(Vector3i(2, 1, 2))).is_true()


# ---------------------------------------------------------------------------
# AC39 — max_cells_per_command cap [TR-building-system-049]
# ---------------------------------------------------------------------------

func _sequential_cells(count: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for i in range(count):
		cells.append(Vector3i(i, 0, 0))
	return cells


func test_commit_exceeding_max_cells_per_command_is_rejected_with_zero_cells_created() -> void:
	# Arrange — the default cap is 512; 513 distinct, empty, in-bounds cells
	# exceed it by exactly one.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)
	var received: Array = _connect_rejection_listener(pipeline)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit(_sequential_cells(513))

	# Assert
	assert_int(created.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.CELL_COUNT_EXCEEDS_CAP)


func test_commit_exactly_at_the_cap_succeeds() -> void:
	# Boundary proof -- the comparison is `>`, never `>=`.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)

	var created: Array[BlueprintCell] = pipeline.commit(_sequential_cells(pipeline.config.max_cells_per_command))

	assert_int(created.size()).is_equal(pipeline.config.max_cells_per_command)


# ---------------------------------------------------------------------------
# AC42 — no material/furniture selected [TR-building-system-049]
# ---------------------------------------------------------------------------

func test_no_material_selected_rejects_an_otherwise_valid_commit() -> void:
	# Arrange — an otherwise perfectly valid pick + candidate cell, but
	# nothing selected (the default state -- `_select_placeholder_material`
	# deliberately never called here).
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var received: Array = _connect_rejection_listener(pipeline)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1)])

	# Assert
	assert_int(created.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.NO_MATERIAL_SELECTED)


func test_selected_item_reported_unavailable_by_rid_rejects_the_commit() -> void:
	# Arrange — a real RID-shaped double IS wired, but the selected id is not
	# among its available ids (Core Rule 9's "selected AND available" full
	# contract, not just the "nothing selected" half AC42 names literally).
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	pipeline.resource_item_database = _MockItemDatabase.new()
	pipeline.set_selected_item(&"unavailable_material")
	var received: Array = _connect_rejection_listener(pipeline)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1)])

	# Assert
	assert_int(created.size()).is_equal(0)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.NO_MATERIAL_SELECTED)


func test_selected_item_reported_available_by_rid_proceeds() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var database := _MockItemDatabase.new()
	database.mark_available(&"wood_wall")
	pipeline.resource_item_database = database
	pipeline.set_selected_item(&"wood_wall")

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1)])

	# Assert
	assert_int(created.size()).is_equal(1)


func test_rid_not_ready_rejects_the_commit_even_with_a_selection() -> void:
	# Arrange — the RID double reports NOT ready (mirrors a database still
	# validating at boot) -- Core Rule 9 requires "available," which a
	# not-yet-Ready database can never confirm.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	var database := _MockItemDatabase.new()
	database.mark_available(&"wood_wall")
	database.set_ready(false)
	pipeline.resource_item_database = database
	pipeline.set_selected_item(&"wood_wall")

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1)])

	# Assert
	assert_int(created.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Furniture-support predicate seam [TR-building-system-050]
# ---------------------------------------------------------------------------

func test_furniture_support_predicate_unsupported_cell_rejects_the_commit() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)
	pipeline.set_furniture_support_predicate(func(_cell: Vector3i) -> bool: return false)
	var received: Array = _connect_rejection_listener(pipeline)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1)])

	# Assert
	assert_int(created.size()).is_equal(0)
	assert_int(pipeline.get_blueprint_cells().size()).is_equal(0)
	assert_int(received.size()).is_equal(1)
	assert_int(received[0][0]).is_equal(CommitPipeline.RejectReason.FURNITURE_UNSUPPORTED)


func test_furniture_support_predicate_supported_cell_allows_the_commit() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)
	pipeline.set_furniture_support_predicate(func(_cell: Vector3i) -> bool: return true)

	# Act
	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1)])

	# Assert
	assert_int(created.size()).is_equal(1)


func test_no_furniture_support_predicate_wired_never_blocks_a_commit() -> void:
	# Default state -- no non-furniture tool ever wires this predicate.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pipeline: CommitPipeline = _new_pipeline(pick, grid)
	_select_placeholder_material(pipeline)

	var created: Array[BlueprintCell] = pipeline.commit([Vector3i(1, 0, 1)])

	assert_int(created.size()).is_equal(1)
