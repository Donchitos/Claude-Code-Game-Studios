## Integration test — Building System Story building-033 (Voxel World write
## seam: batched bulk-write + self-write exemption + undo-invalidation
## listener + Build Validation completion signal). ADR-0016 primary;
## ADR-0014 secondary (Voxel World's bulk-write API); ADR-0009 secondary
## (Godot's synchronous-signal fact is load-bearing for the self-write
## exemption).
##
## Proves:
## - AC47 / [TR-building-system-072]: N cells completing in the SAME
##   [ConstructionTickLoop] tick dispatch batch into exactly ONE
##   [VoxelWorldGrid] write call, firing exactly ONE
##   [signal VoxelWorldGrid.cells_changed_batch] and ZERO
##   [signal VoxelWorldGrid.cell_changed] — including the single-completion
##   case (this story's own design choice: every completion, always, goes
##   through the SAME batched path, never a conditional "batch only if >1").
## - [TR-building-system-075]: [signal ConstructionTickLoop.construction_completed]
##   fires exactly once per dispatch that completes at least one cell,
##   carrying every completed cell; never fires for a dispatch that
##   completes nothing.
## - AC46 / [TR-building-system-024]: a shared [BuildingSystemWriteTag]
##   between [ConstructionTickLoop] and [UndoRedoStack] means the tick
##   loop's own completion write is recognized as self-originated and
##   invalidates NOTHING in the undo stack's bookkeeping.
## - AC33 / [TR-building-system-071]: an EXTERNAL write (not bracketed by the
##   shared tag, simulating "another system") to a cell that is part of a
##   recorded undo command marks that cell invalidated; undoing that command
##   skips [method UndoRedoStack.cancel_cell_callable] for the stale cell
##   only, without error and without double-processing, while every other
##   (non-invalidated) cell in the SAME command still cancels normally.
class_name VoxelWriteSeamTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test helpers (kept ABOVE every test function, per this codebase's own
# convention)
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_loop(grid: VoxelWorldGrid, tick_source: Object, tag: BuildingSystemWriteTag = null) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	if tag != null:
		loop.write_tag = tag
	loop.setup()
	return loop


func _new_stack(tag: BuildingSystemWriteTag = null, write_source: Object = null) -> UndoRedoStack:
	var stack: UndoRedoStack = auto_free(UndoRedoStack.new())
	stack.config = UndoRedoStackConfig.new()
	if tag != null:
		stack.write_tag = tag
	if write_source != null:
		stack.voxel_world_write_source = write_source
	stack.setup()
	return stack


# ---------------------------------------------------------------------------
# AC47 / TR-072 — batched bulk-write, exactly one signal regardless of N
# ---------------------------------------------------------------------------

func test_ac47_two_cells_completing_same_tick_fire_exactly_one_batched_signal() -> void:
	# Arrange — two independently-claimed jobs, both one tick short.
	var grid: VoxelWorldGrid = _new_grid()
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_loop(grid, tick_source)
	var cell_a := BlueprintCell.new(Vector3i(1, 0, 1))
	var cell_b := BlueprintCell.new(Vector3i(2, 0, 2))
	loop.claim_job(cell_a, 1)
	loop.claim_job(cell_b, 2)
	for _i in range(loop.config.base_build_ticks_block - 1):
		tick_source.fire_tick()

	var cell_changed_count: Array = [0]
	var batch_count: Array = [0]
	var batch_sizes: Array = []
	grid.cell_changed.connect(
		func(_cell: Vector3i, _before: CellContents, _after: CellContents) -> void: cell_changed_count[0] += 1
	)
	grid.cells_changed_batch.connect(
		func(changes: Array[CellChangeRecord]) -> void:
			batch_count[0] += 1
			batch_sizes.append(changes.size())
	)

	# Act — the final tick completes BOTH cells in the SAME _on_tick dispatch.
	tick_source.fire_tick()

	# Assert
	assert_int(cell_a.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(cell_b.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(cell_changed_count[0]).is_equal(0)
	assert_int(batch_count[0]).is_equal(1)
	assert_int(batch_sizes[0]).is_equal(2)
	assert_bool(grid.get_cell(cell_a.cell).is_empty()).is_false()
	assert_bool(grid.get_cell(cell_b.cell).is_empty()).is_false()


func test_ac47_single_cell_completion_also_uses_the_batched_signal_never_cell_changed() -> void:
	# Arrange — this story's own design choice: even N=1 goes through
	# bulk_write, never the plain single-cell set_cell path.
	var grid: VoxelWorldGrid = _new_grid()
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_loop(grid, tick_source)
	var cell := BlueprintCell.new(Vector3i(3, 0, 3))
	loop.claim_job(cell, 1)

	var cell_changed_count: Array = [0]
	var batch_count: Array = [0]
	grid.cell_changed.connect(
		func(_cell: Vector3i, _before: CellContents, _after: CellContents) -> void: cell_changed_count[0] += 1
	)
	grid.cells_changed_batch.connect(func(_changes: Array[CellChangeRecord]) -> void: batch_count[0] += 1)

	# Act
	for _i in range(loop.config.base_build_ticks_block):
		tick_source.fire_tick()

	# Assert
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(cell_changed_count[0]).is_equal(0)
	assert_int(batch_count[0]).is_equal(1)


# ---------------------------------------------------------------------------
# TR-075 — construction_completed batched per frame/dispatch
# ---------------------------------------------------------------------------

func test_construction_completed_fires_once_per_dispatch_with_every_completed_cell() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_loop(grid, tick_source)
	var cell_a := BlueprintCell.new(Vector3i(1, 0, 1))
	var cell_b := BlueprintCell.new(Vector3i(2, 0, 2))
	loop.claim_job(cell_a, 1)
	loop.claim_job(cell_b, 2)

	var completed_events: Array = []
	loop.construction_completed.connect(func(cells: Array[Vector3i]) -> void: completed_events.append(cells))

	# Act
	for _i in range(loop.config.base_build_ticks_block):
		tick_source.fire_tick()

	# Assert
	assert_int(completed_events.size()).is_equal(1)
	assert_array(completed_events[0]).contains_exactly_in_any_order([cell_a.cell, cell_b.cell])


func test_construction_completed_never_fires_for_a_dispatch_that_completes_nothing() -> void:
	var grid: VoxelWorldGrid = _new_grid()
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_loop(grid, tick_source)
	var cell := BlueprintCell.new(Vector3i(1, 0, 1))
	loop.claim_job(cell, 1)

	var completed_events: Array = []
	loop.construction_completed.connect(func(cells: Array[Vector3i]) -> void: completed_events.append(cells))

	# Act — one tick short of completion (zero jobs finish).
	for _i in range(loop.config.base_build_ticks_block - 1):
		tick_source.fire_tick()

	# Assert
	assert_int(completed_events.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC46 / TR-024 — self-write exemption
# ---------------------------------------------------------------------------

func test_ac46_shared_tag_makes_completion_write_self_originated_invalidates_nothing() -> void:
	# Arrange — a shared BuildingSystemWriteTag wired into BOTH the tick loop
	# (the writer) and the undo stack (the listener, subscribed to the grid).
	var tag := BuildingSystemWriteTag.new()
	var grid: VoxelWorldGrid = _new_grid()
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_loop(grid, tick_source, tag)
	var stack: UndoRedoStack = _new_stack(tag, grid)
	# The undo stack has ALSO recorded a command referencing this exact cell
	# (mirrors the real sequence: commit records the undo entry long before
	# a villager's construction completes it).
	var target := Vector3i(4, 0, 4)
	stack.record_command([target])
	var cell := BlueprintCell.new(target)
	loop.claim_job(cell, 1)

	# Act — the tick loop's own batched completion write.
	for _i in range(loop.config.base_build_ticks_block):
		tick_source.fire_tick()

	# Assert — the write happened (sanity) but the listener never invalidated
	# the cell it just wrote itself.
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(stack.is_cell_invalidated(target)).is_false()

	# And undo() still cancels this cell normally (nothing was skipped).
	var canceled: Array[Vector3i] = []
	stack.set_cancel_cell_callable(func(c: Vector3i) -> bool:
		canceled.append(c)
		return true
	)
	stack.undo()
	assert_array(canceled).is_equal([target])


func test_unshared_tag_means_completion_write_reads_as_external_by_an_isolated_stack() -> void:
	# Regression lock for the wiring CONTRACT (this story's own class doc
	# comments): a stack that never receives the SAME tag instance the
	# writer uses sees every write as external -- correct only for an
	# isolated test of the stack alone, but proves sharing is REQUIRED, not
	# automatic.
	var grid: VoxelWorldGrid = _new_grid()
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_loop(grid, tick_source)
	var stack: UndoRedoStack = _new_stack(null, grid)
	var target := Vector3i(5, 0, 5)
	stack.record_command([target])
	var cell := BlueprintCell.new(target)
	loop.claim_job(cell, 1)

	# Act
	for _i in range(loop.config.base_build_ticks_block):
		tick_source.fire_tick()

	# Assert
	assert_bool(stack.is_cell_invalidated(target)).is_true()


# ---------------------------------------------------------------------------
# AC33 / TR-071 — stale entry skipped without error or double-removal
# ---------------------------------------------------------------------------

func test_ac33_external_write_invalidates_only_that_cell_undo_skips_it_cleanly() -> void:
	# Arrange — a shared tag (so we can prove the DISTINCTION between a
	# self-tagged write and a genuinely external one against the SAME grid).
	var tag := BuildingSystemWriteTag.new()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack(tag, grid)
	var stale_cell := Vector3i(1, 0, 1)
	var live_cell := Vector3i(2, 0, 1)
	stack.record_command([stale_cell, live_cell])

	var canceled: Array[Vector3i] = []
	stack.set_cancel_cell_callable(func(c: Vector3i) -> bool:
		canceled.append(c)
		return true
	)

	# Act — "another system" writes directly to the grid, untagged (no
	# write_tag.begin()/end() bracket) -- simulates a write this system did
	# NOT issue.
	grid.set_cell(stale_cell, CellContents.new(2, 0))
	assert_bool(stack.is_cell_invalidated(stale_cell)).is_true()
	assert_bool(stack.is_cell_invalidated(live_cell)).is_false()

	var result: bool = stack.undo()

	# Assert — undo still succeeds cleanly; the stale cell is skipped (no
	# cancel_cell_callable call, no error, no double-removal); the live cell
	# still cancels normally.
	assert_bool(result).is_true()
	assert_array(canceled).is_equal([live_cell])


func test_ac33_external_write_to_a_cell_outside_any_undo_entry_does_not_affect_unrelated_commands() -> void:
	var tag := BuildingSystemWriteTag.new()
	var grid: VoxelWorldGrid = _new_grid()
	var stack: UndoRedoStack = _new_stack(tag, grid)
	var unrelated_cell := Vector3i(9, 0, 9)
	var command_cell := Vector3i(1, 0, 1)
	stack.record_command([command_cell])

	# Act — an external write to a cell that is NOT part of any recorded
	# command.
	grid.set_cell(unrelated_cell, CellContents.new(2, 0))

	var canceled: Array[Vector3i] = []
	stack.set_cancel_cell_callable(func(c: Vector3i) -> bool:
		canceled.append(c)
		return true
	)
	stack.undo()

	# Assert — the unrelated command's own cell still cancels normally.
	assert_array(canceled).is_equal([command_cell])
