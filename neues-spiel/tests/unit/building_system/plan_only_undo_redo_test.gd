## Unit test — Building System Story building-011 (Plan-only undo/redo:
## wiring building-032/033's reserved [UndoRedoStack] cancel/recreate seams
## via [PlanOnlyUndoGate]). ADR-0016 primary (Rule 17: undo never touches a
## Built cell); [TR-building-system-119].
##
## Proves:
## 1. AC27/AC29: a command mixing still-pending and already-Built cells —
##    undo cancels every pending cell and leaves every Built cell standing
##    exactly as it is, no removal, no demolition order.
## 2. AC68: a command whose every cell already reached Built — undo has zero
##    effect (companion to AC27/AC29).
## 3. AC28/Edge Case 8: redo re-validates every cell independently — a cell
##    reoccupied since the undo is dropped with feedback; a still-free cell
##    is re-created as a fresh Draft blueprint, preserving its original
##    category/furniture id; a cell undo left standing as Built (no
##    snapshot) is always dropped, never duplicated.
## 4. Claim revocation: an UnderConstruction cell's active job/claim is
##    released through [ConstructionJobQueue]/[ConstructionTickLoop] before
##    the cell is cancelled — the villager and the tick loop both forget it.
## 5. Multi-cell furniture footprint: an all-pending footprint's siblings
##    cancel TOGETHER in one undo() call (never "half a bed"); a mixed
##    Built/pending footprint applies Rule 17 per cell (the Built sibling
##    stands, its pending twin cancels) — the story's own documented,
##    accepted outcome.
## 6. Registry-aware cleanup: cancelling a project's last cell frees the
##    reverse index AND drops the emptied project, so a later commit at the
##    same address succeeds as a brand-new project.
## 7. Structural paused/unpaused parity: [PlanOnlyUndoGate] never reads any
##    time/pause-state API, so undo/redo behave identically regardless of
##    Time & Tick System's pause state, by construction.
class_name PlanOnlyUndoRedoTest
extends GdUnitTestSuite

const GATE_SOURCE_PATH: String = "res://src/building_system/plan_only_undo_gate.gd"


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
	furniture_id: StringName = &""
) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED, category, null, furniture_id)


func _built_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.BUILT)


# ---------------------------------------------------------------------------
# AC27 / AC29 — undo cancels pending cells, leaves Built cells standing
# ---------------------------------------------------------------------------

func test_undo_leaves_built_cells_standing_and_cancels_pending_ones() -> void:
	# Arrange — a mixed command: one still-pending cell, one already Built.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var pending_cell := Vector3i(0, 0, 0)
	var built_cell := Vector3i(1, 0, 0)
	var cells: Array[BlueprintCell] = [_planned_cell(pending_cell), _built_cell(built_cell)]
	var result: Array[BuildProject] = registry.assign_cells(cells)
	var project: BuildProject = result[0]
	stack.record_command([pending_cell, built_cell])

	# Act
	stack.undo()

	# Assert — pending cancelled and unindexed; Built stands, untouched.
	assert_bool(project.has_cell(pending_cell)).is_false()
	assert_bool(project.has_cell(built_cell)).is_true()
	assert_int(project.cells[built_cell].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(registry.project_at_cell(pending_cell)).is_equal(-1)
	assert_int(registry.project_at_cell(built_cell)).is_equal(project.id)
	assert_bool(gate.has_snapshot(built_cell)).is_false()


# ---------------------------------------------------------------------------
# AC68 — undo of a fully-Built command is inert
# ---------------------------------------------------------------------------

func test_undo_of_fully_built_command_is_inert() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var cell_a := Vector3i(0, 0, 0)
	var cell_b := Vector3i(1, 0, 0)
	var cells: Array[BlueprintCell] = [_built_cell(cell_a), _built_cell(cell_b)]
	var result: Array[BuildProject] = registry.assign_cells(cells)
	var project: BuildProject = result[0]
	stack.record_command([cell_a, cell_b])

	# Act
	var undo_result: bool = stack.undo()

	# Assert — the stack itself popped a command (true), but nothing about
	# either cell changed: no removal, no demolition order.
	assert_bool(undo_result).is_true()
	assert_bool(project.has_cell(cell_a)).is_true()
	assert_bool(project.has_cell(cell_b)).is_true()
	assert_int(project.state).is_equal(BuildProject.ProjectState.DONE)


# ---------------------------------------------------------------------------
# Claim revocation — an active UnderConstruction job is released before cancel
# ---------------------------------------------------------------------------

func test_undo_revokes_active_claim_before_cancelling_under_construction_cell() -> void:
	# Arrange — a released, claimed cell (UnderConstruction, a real job active
	# through the queue/tick loop).
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_loop: ConstructionTickLoop = _new_tick_loop(grid)
	var job_queue := ConstructionJobQueue.new(tick_loop)
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid, job_queue, tick_loop)
	var cell := Vector3i(2, 0, 2)
	var cells: Array[BlueprintCell] = [_planned_cell(cell)]
	var result: Array[BuildProject] = registry.assign_cells(cells)
	var project: BuildProject = result[0]
	project.state = BuildProject.ProjectState.BUILDING
	job_queue.add_project(project)
	var claimed: bool = job_queue.claim_job(cell, 42)
	assert_bool(claimed).is_true()
	assert_bool(tick_loop.is_job_active(cell)).is_true()
	stack.record_command([cell])

	# Act
	stack.undo()

	# Assert — the claim and the active job are both gone; the cell itself
	# is cancelled out of the project.
	assert_bool(tick_loop.is_job_active(cell)).is_false()
	assert_bool(job_queue.has_claim(42)).is_false()
	assert_bool(project.has_cell(cell)).is_false()


# ---------------------------------------------------------------------------
# Multi-cell furniture footprint — never "half a bed"
# ---------------------------------------------------------------------------

func test_undo_cancels_all_pending_cells_of_a_multi_cell_footprint_together() -> void:
	# Arrange — a 2-cell bed footprint, both cells still pending.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var cell_a := Vector3i(0, 0, 0)
	var cell_b := Vector3i(1, 0, 0)
	var bp_a: BlueprintCell = _planned_cell(cell_a, BlueprintCell.Category.FURNITURE, &"bed")
	var bp_b: BlueprintCell = _planned_cell(cell_b, BlueprintCell.Category.FURNITURE, &"bed")
	var group := FurnitureFootprintGroup.new()
	group.cells = [bp_a, bp_b]
	bp_a.footprint_group = group
	bp_b.footprint_group = group
	var cells: Array[BlueprintCell] = [bp_a, bp_b]
	var result: Array[BuildProject] = registry.assign_cells(cells)
	var project: BuildProject = result[0]
	stack.record_command([cell_a, cell_b])

	# Act — one undo step.
	stack.undo()

	# Assert — both siblings gone together; no lone surviving half.
	assert_bool(project.has_cell(cell_a)).is_false()
	assert_bool(project.has_cell(cell_b)).is_false()
	assert_bool(project.is_empty()).is_true()


func test_undo_on_mixed_footprint_leaves_built_sibling_standing() -> void:
	# Arrange — one sibling of a 2-cell footprint already Built, the other
	# still pending (Rule 17 applies per cell, even within one footprint).
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var built_cell := Vector3i(0, 0, 0)
	var pending_cell := Vector3i(1, 0, 0)
	var bp_built := BlueprintCell.new(
		built_cell, BlueprintCell.MicroState.BUILT, BlueprintCell.Category.FURNITURE, null, &"bed"
	)
	var bp_pending: BlueprintCell = _planned_cell(pending_cell, BlueprintCell.Category.FURNITURE, &"bed")
	var group := FurnitureFootprintGroup.new()
	group.cells = [bp_built, bp_pending]
	bp_built.footprint_group = group
	bp_pending.footprint_group = group
	var cells: Array[BlueprintCell] = [bp_built, bp_pending]
	var result: Array[BuildProject] = registry.assign_cells(cells)
	var project: BuildProject = result[0]
	stack.record_command([built_cell, pending_cell])

	# Act
	stack.undo()

	# Assert — the Built sibling stands untouched; its pending twin cancels.
	assert_bool(project.has_cell(built_cell)).is_true()
	assert_int(project.cells[built_cell].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(project.has_cell(pending_cell)).is_false()


# ---------------------------------------------------------------------------
# AC28 / Edge Case 8 — redo re-validates every cell, drops the reoccupied one
# ---------------------------------------------------------------------------

func test_redo_recreates_valid_cells_and_drops_reoccupied_ones() -> void:
	# Arrange — a 2-cell command, undone; one cell is reoccupied afterward
	# (real terrain now sits there).
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var kept_cell := Vector3i(0, 0, 0)
	var reoccupied_cell := Vector3i(1, 0, 0)
	var cells: Array[BlueprintCell] = [_planned_cell(kept_cell), _planned_cell(reoccupied_cell)]
	registry.assign_cells(cells)
	stack.record_command([kept_cell, reoccupied_cell])
	stack.undo()
	grid.set_cell(reoccupied_cell, CellContents.new(1, 0))
	var dropped_received: Array = []
	var redone_received: Array = []
	stack.redo_cells_dropped.connect(func(dropped: Array[Vector3i]) -> void: dropped_received.append(dropped))
	stack.command_redone.connect(func(redone: Array[Vector3i]) -> void: redone_received.append(redone))

	# Act
	var result: bool = stack.redo()

	# Assert
	assert_bool(result).is_true()
	assert_array(dropped_received[0]).is_equal([reoccupied_cell])
	assert_array(redone_received[0]).is_equal([kept_cell])
	assert_int(registry.project_at_cell(kept_cell)).is_not_equal(-1)
	assert_int(registry.project_at_cell(reoccupied_cell)).is_equal(-1)


func test_redo_of_a_furniture_cell_preserves_category_and_furniture_id() -> void:
	# Arrange — a single-cell furniture blueprint, cancelled then redone.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var cell := Vector3i(3, 0, 3)
	var cells: Array[BlueprintCell] = [_planned_cell(cell, BlueprintCell.Category.FURNITURE, &"bed")]
	registry.assign_cells(cells)
	stack.record_command([cell])
	stack.undo()

	# Act
	stack.redo()

	# Assert — the recreated blueprint is a fresh Draft cell with the SAME
	# category/furniture id as the original.
	var project_id: int = registry.project_at_cell(cell)
	assert_int(project_id).is_not_equal(-1)
	var recreated: BlueprintCell = registry.get_project(project_id).cells[cell]
	assert_int(recreated.category).is_equal(BlueprintCell.Category.FURNITURE)
	assert_str(String(recreated.furniture_definition_id)).is_equal("bed")
	assert_int(recreated.state).is_equal(BlueprintCell.MicroState.PLANNED)


func test_redo_never_recreates_a_cell_undo_left_standing_as_built() -> void:
	# Arrange — a mixed command; the Built cell was never cancelled (Rule 17),
	# so it carries no snapshot at all.
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var pending_cell := Vector3i(0, 0, 0)
	var built_cell := Vector3i(1, 0, 0)
	var built_blueprint: BlueprintCell = _built_cell(built_cell)
	var cells: Array[BlueprintCell] = [_planned_cell(pending_cell), built_blueprint]
	var result: Array[BuildProject] = registry.assign_cells(cells)
	var project: BuildProject = result[0]
	stack.record_command([pending_cell, built_cell])
	stack.undo()
	var dropped_received: Array = []
	stack.redo_cells_dropped.connect(func(dropped: Array[Vector3i]) -> void: dropped_received.append(dropped))

	# Act — redo replays the FULL original command, including the Built cell.
	stack.redo()

	# Assert — the Built cell is dropped (never duplicated, never touched);
	# the pending cell alone is recreated and rejoins the SAME project via
	# 26-adjacency (the Built cell was never unindexed).
	assert_array(dropped_received[0]).is_equal([built_cell])
	assert_object(project.cells[built_cell]).is_same(built_blueprint)
	assert_bool(project.has_cell(pending_cell)).is_true()
	assert_int(project.get_cells().size()).is_equal(2)


# ---------------------------------------------------------------------------
# Registry-aware cleanup — an emptied project frees its address entirely
# ---------------------------------------------------------------------------

func test_cancel_cleans_up_registry_and_frees_address_for_a_new_project() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack()
	var gate: PlanOnlyUndoGate = PlanOnlyUndoGate.new(stack, registry, grid)
	var cell := Vector3i(5, 0, 5)
	var cells: Array[BlueprintCell] = [_planned_cell(cell)]
	var result: Array[BuildProject] = registry.assign_cells(cells)
	var original_id: int = result[0].id
	stack.record_command([cell])

	# Act
	stack.undo()

	# Assert — fully unindexed and the project entity itself is gone.
	assert_int(registry.project_at_cell(cell)).is_equal(-1)
	assert_object(registry.get_project(original_id)).is_null()

	# A brand-new commit at the same address must succeed as its own project.
	var new_cells: Array[BlueprintCell] = [_planned_cell(cell)]
	var new_result: Array[BuildProject] = registry.assign_cells(new_cells)
	assert_int(new_result.size()).is_equal(1)
	assert_int(registry.project_at_cell(cell)).is_equal(new_result[0].id)


# ---------------------------------------------------------------------------
# Structural paused/unpaused parity — no time/pause API is ever read
# ---------------------------------------------------------------------------

func test_gate_never_reads_time_or_pause_state() -> void:
	# Building-while-paused parity holds structurally: this file contains no
	# branch that could possibly differ between paused and unpaused.
	var source: String = FileAccess.get_file_as_string(GATE_SOURCE_PATH)

	assert_bool(source.contains("TimeTickSystem")).is_false()
	assert_bool(source.contains("get_game_delta")).is_false()
	assert_bool(source.contains("is_paused")).is_false()
