## Unit test — Building System Story building-009 (Demolition orders: block
## teardown job contract, GDD Rule 14j, ADR-0016 primary).
##
## Proves:
## 1. AC65 [TR-building-system-114/115]: [method
##    ConstructionTickLoop.create_demolition_order] on a Built cell succeeds,
##    is created already job-eligible (no separate "Bau starten" step), and
##    leaves the cell NOT cleared yet -- both [member BlueprintCell.state]
##    and the Voxel World grid are untouched at order-creation time.
## 2. Edge 17 [TR-building-system-114]: a second demolition request on an
##    already-queued demolition cell is a no-op -- exactly one demolition
##    job exists per cell, never a duplicate.
## 3. AC66 [TR-building-system-115]: a demolition job fed
##    `base_demolition_ticks[category]` worth of on-site tick events via a
##    mocked claim (mirrors AC20's mocked-job pattern) -- on the last tick,
##    the Voxel World clear occurs (the cell reads empty) and the cell is
##    gone; fewer ticks than required leaves the cell standing untouched.
## 4. On a demolished floor-excavation cell (Rule 14l), the captured
##    `restore_value` is written back instead of an empty cell -- a snapshot,
##    never a re-derived "current" terrain value.
## 5. Batching (the Control Manifest's bulk-write guardrail): N demolition
##    completions in the SAME tick dispatch fire exactly ONE batched
##    [signal VoxelWorldGrid.cells_changed_batch], never N.
## 6. [signal ConstructionTickLoop.demolition_completed] fires exactly once
##    per completing dispatch, carrying every cell demolished in it, kept
##    distinct from [signal ConstructionTickLoop.construction_completed].
## 7. Warp invariance (mirrors `construction_tick_loop_test.gd`'s own AC24
##    precedent, proven against a REAL isolated [TimeTickSystem] instance):
##    time-warp halves the wall-clock needed, never the tick COUNT required
##    to complete a demolition job.
## 8. Scope guards: [method ConstructionTickLoop.create_demolition_order]
##    refuses a not-yet-Built cell; [method
##    ConstructionTickLoop.claim_demolition_job] refuses a cell with no
##    demolition order queued. (Story building-017, landed after this story,
##    widened [method create_demolition_order]'s own category guard to also
##    accept FURNITURE -- see that story's own `furniture_demolition_test.gd`
##    for the atomic multi-cell-footprint / deferred-revocation proof this
##    suite does not attempt; this suite keeps only a direct single-cell
##    regression for the changed guard, below.)
class_name DemolitionOrdersBlocksTest
extends GdUnitTestSuite

const TimeTickSystemScript: GDScript = preload("res://src/time_tick_system/time_tick_system.gd")


# ---------------------------------------------------------------------------
# Test helpers (mirrors `construction_tick_loop_test.gd`'s own precedent)
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_loop(grid: VoxelWorldGrid, tick_source: Object, loop_config: ConstructionTickLoopConfig = null) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = loop_config if loop_config != null else ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	loop.setup()
	return loop


## A Built BLOCK cell whose grid address already carries matching, non-empty
## contents -- the realistic "already-constructed" fixture every test in
## this file starts from.
func _new_built_cell(grid: VoxelWorldGrid, cell_address: Vector3i) -> BlueprintCell:
	var contents := CellContents.new(3, 1)
	grid.set_cell(cell_address, contents)
	return BlueprintCell.new(cell_address, BlueprintCell.MicroState.BUILT, BlueprintCell.Category.BLOCK, contents)


func _new_isolated_time_tick_system() -> Object:
	var system: Object = TimeTickSystemScript.new()
	@warning_ignore("unsafe_property_access")
	system.config = TimeTickConfig.new()
	@warning_ignore("unsafe_method_access")
	system.setup()
	return system


# ---------------------------------------------------------------------------
# AC65 — demolition order created already released/job-eligible; not cleared yet
# ---------------------------------------------------------------------------

func test_create_demolition_order_on_built_cell_succeeds_and_does_not_clear_yet() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var cell: BlueprintCell = _new_built_cell(grid, Vector3i(1, 0, 1))

	# Act
	var created: bool = loop.create_demolition_order(cell)

	# Assert — order exists (job-eligible immediately, no staging step); the
	# cell itself is untouched -- still BUILT, grid still shows its content.
	assert_bool(created).is_true()
	assert_bool(cell.is_demolition_queued).is_true()
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	var still_there: CellContents = grid.get_cell(cell.cell)
	assert_bool(still_there.is_empty()).is_false()
	assert_int(still_there.block_type_id).is_equal(cell.contents.block_type_id)


func test_create_demolition_order_on_not_yet_built_cell_fails() -> void:
	# Arrange — a Planned cell (never Built) cannot receive a demolition order.
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var cell := BlueprintCell.new(Vector3i(2, 0, 2))

	var created: bool = loop.create_demolition_order(cell)

	assert_bool(created).is_false()
	assert_bool(cell.is_demolition_queued).is_false()


func test_create_demolition_order_on_a_single_cell_furniture_cell_now_succeeds() -> void:
	# Story building-017 (this revision, landed after this story) widened
	# create_demolition_order to accept FURNITURE, reusing this SAME
	# mechanism -- see that story's own `furniture_demolition_test.gd` for
	# the full atomic multi-cell-footprint / deferred-revocation proof; this
	# suite keeps only the direct regression that THIS entry point's own
	# category guard changed. Furniture never enters VoxelWorldGrid (BV-1),
	# so this fixture -- unlike a BLOCK cell's -- deliberately never writes
	# anything into the grid at all.
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var contents := CellContents.new(4, 0)
	var cell := BlueprintCell.new(
		Vector3i(3, 0, 3), BlueprintCell.MicroState.BUILT, BlueprintCell.Category.FURNITURE, contents, &"bed"
	)

	var created: bool = loop.create_demolition_order(cell)

	assert_bool(created).is_true()
	assert_bool(cell.is_demolition_queued).is_true()


# ---------------------------------------------------------------------------
# Edge 17 — duplicate demolition request on an already-queued cell is a no-op
# ---------------------------------------------------------------------------

func test_second_demolition_order_on_already_queued_cell_is_a_no_op() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var cell: BlueprintCell = _new_built_cell(grid, Vector3i(1, 0, 1))
	assert_bool(loop.create_demolition_order(cell)).is_true()

	# Act — a second request on the SAME already-queued cell.
	var second: bool = loop.create_demolition_order(cell)

	# Assert — rejected; still exactly one order (the flag remains true, not
	# toggled/duplicated).
	assert_bool(second).is_false()
	assert_bool(cell.is_demolition_queued).is_true()


func test_claim_demolition_job_without_an_order_fails() -> void:
	# Arrange — a Built cell that never received a demolition order.
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var cell: BlueprintCell = _new_built_cell(grid, Vector3i(1, 0, 1))

	var claimed: bool = loop.claim_demolition_job(cell, 7)

	assert_bool(claimed).is_false()
	assert_bool(loop.is_job_active(cell.cell)).is_false()


func test_second_claim_on_an_already_claimed_demolition_job_fails() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var cell: BlueprintCell = _new_built_cell(grid, Vector3i(1, 0, 1))
	assert_bool(loop.create_demolition_order(cell)).is_true()
	assert_bool(loop.claim_demolition_job(cell, 7)).is_true()

	# Act — a second villager attempts to claim the SAME already-claimed job.
	var reclaimed: bool = loop.claim_demolition_job(cell, 9)

	assert_bool(reclaimed).is_false()


# ---------------------------------------------------------------------------
# AC66 — demolition completes after base_demolition_ticks[category] tick events
# ---------------------------------------------------------------------------

func test_demolition_completes_after_base_demolition_ticks_block_events() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell: BlueprintCell = _new_built_cell(grid, Vector3i(2, 0, 2))
	assert_bool(loop.create_demolition_order(cell)).is_true()
	assert_bool(loop.claim_demolition_job(cell, 1)).is_true()

	# Act — exactly base_demolition_ticks_block (default 4) tick events.
	for i in range(loop_config.base_demolition_ticks_block):
		mock_tick.fire_tick()

	# Assert — the Voxel World clear occurred; the cell is gone (empty).
	assert_bool(grid.get_cell(cell.cell).is_empty()).is_true()
	assert_bool(loop.is_job_active(cell.cell)).is_false()
	assert_bool(cell.is_demolition_queued).is_false()
	# The per-cell micro-state itself is untouched by demolition (stays
	# BUILT -- see class doc comment point 1; "gone" is the grid's own state).
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.BUILT)


func test_fewer_ticks_than_required_leaves_the_cell_standing() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell: BlueprintCell = _new_built_cell(grid, Vector3i(2, 0, 2))
	assert_bool(loop.create_demolition_order(cell)).is_true()
	assert_bool(loop.claim_demolition_job(cell, 1)).is_true()

	# Act — one tick short of the required total.
	for i in range(loop_config.base_demolition_ticks_block - 1):
		mock_tick.fire_tick()

	# Assert — still standing; nothing cleared, order still active.
	var still_there: CellContents = grid.get_cell(cell.cell)
	assert_bool(still_there.is_empty()).is_false()
	assert_int(still_there.block_type_id).is_equal(cell.contents.block_type_id)
	assert_bool(loop.is_job_active(cell.cell)).is_true()
	assert_bool(cell.is_demolition_queued).is_true()


func test_furniture_category_demolition_uses_the_furniture_tick_count() -> void:
	# Pure-function coverage of the demolition-side F3 addendum knob (mirrors
	# `required_ticks_for`'s own established coverage).
	var loop_config := ConstructionTickLoopConfig.new()
	loop_config.base_demolition_ticks_block = 5
	loop_config.base_demolition_ticks_furniture = 13

	assert_int(
		ConstructionTickLoop.required_demolition_ticks_for(BlueprintCell.Category.BLOCK, loop_config)
	).is_equal(5)
	assert_int(
		ConstructionTickLoop.required_demolition_ticks_for(BlueprintCell.Category.FURNITURE, loop_config)
	).is_equal(13)


# ---------------------------------------------------------------------------
# restore_value writeback (Rule 14l, coordinates with Story 012)
# ---------------------------------------------------------------------------

func test_demolished_floor_excavation_cell_writes_back_restore_value() -> void:
	# Arrange — a floor-excavation blueprint entry: its `restore_value`
	# carries the ORIGINAL terrain snapshot, distinct from both the floor's
	# own built contents and an empty cell.
	var grid: VoxelWorldGrid = _new_grid()
	var floor_contents := CellContents.new(9, 2)
	var terrain_restore_value := CellContents.new(2, 0)
	grid.set_cell(Vector3i(4, 0, 4), floor_contents)
	var cell := BlueprintCell.new(
		Vector3i(4, 0, 4),
		BlueprintCell.MicroState.BUILT,
		BlueprintCell.Category.BLOCK,
		floor_contents,
		&"",
		terrain_restore_value
	)
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	assert_bool(loop.create_demolition_order(cell)).is_true()
	assert_bool(loop.claim_demolition_job(cell, 1)).is_true()

	# Act
	for i in range(loop_config.base_demolition_ticks_block):
		mock_tick.fire_tick()

	# Assert — the ORIGINAL terrain snapshot is written back, never left
	# empty and never re-derived (this test's own grid state proves it: the
	# restored value differs from both the floor's own contents and empty).
	var restored: CellContents = grid.get_cell(cell.cell)
	assert_bool(restored.is_empty()).is_false()
	assert_int(restored.block_type_id).is_equal(terrain_restore_value.block_type_id)
	assert_int(restored.material_id).is_equal(terrain_restore_value.material_id)
	assert_bool(restored.block_type_id != floor_contents.block_type_id).is_true()


# ---------------------------------------------------------------------------
# Batching guardrail — N demolition completions in one frame, ONE signal
# ---------------------------------------------------------------------------

func test_n_demolition_completions_in_one_frame_fire_exactly_one_batched_signal() -> void:
	# Arrange — two independently-claimed demolition jobs, both one tick
	# short of completion, so the SAME next tick event completes both.
	var grid: VoxelWorldGrid = _new_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell_a: BlueprintCell = _new_built_cell(grid, Vector3i(1, 0, 1))
	var cell_b: BlueprintCell = _new_built_cell(grid, Vector3i(9, 0, 9))
	assert_bool(loop.create_demolition_order(cell_a)).is_true()
	assert_bool(loop.create_demolition_order(cell_b)).is_true()
	assert_bool(loop.claim_demolition_job(cell_a, 1)).is_true()
	assert_bool(loop.claim_demolition_job(cell_b, 2)).is_true()
	for i in range(loop_config.base_demolition_ticks_block - 1):
		mock_tick.fire_tick()

	# Story building-009's own PITFALLS note: a lambda captures a scalar
	# local (int/bool) BY VALUE at closure-creation time in GDScript, not by
	# reference -- an `int` counter incremented inside the closure would
	# silently mutate a private copy, never the outer variable. Use an
	# `Array` (mutable, captured by reference) and `.append()`/`.size()`
	# instead, mirroring `construction_tick_loop_test.gd`'s own established
	# `ticks_fired: Array = []` precedent.
	var batch_signals: Array = []
	grid.cells_changed_batch.connect(func(_changes: Array) -> void: batch_signals.append(true))
	var demolition_completed_payloads: Array = []
	loop.demolition_completed.connect(func(cells: Array) -> void: demolition_completed_payloads.append(cells))

	# Act — the final tick completes BOTH jobs in the SAME dispatch.
	mock_tick.fire_tick()

	# Assert — both cells cleared; exactly ONE batched Voxel World signal;
	# exactly ONE demolition_completed emission naming both cells.
	assert_bool(grid.get_cell(cell_a.cell).is_empty()).is_true()
	assert_bool(grid.get_cell(cell_b.cell).is_empty()).is_true()
	assert_int(batch_signals.size()).is_equal(1)
	assert_int(demolition_completed_payloads.size()).is_equal(1)
	var completed_cells: Array = demolition_completed_payloads[0]
	assert_int(completed_cells.size()).is_equal(2)
	assert_bool(completed_cells.has(cell_a.cell)).is_true()
	assert_bool(completed_cells.has(cell_b.cell)).is_true()


func test_demolition_completed_signal_stays_distinct_from_construction_completed() -> void:
	# A demolition completion must never also fire construction_completed.
	var grid: VoxelWorldGrid = _new_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell: BlueprintCell = _new_built_cell(grid, Vector3i(6, 0, 6))
	assert_bool(loop.create_demolition_order(cell)).is_true()
	assert_bool(loop.claim_demolition_job(cell, 1)).is_true()

	# Array-based counters -- see the batching test above's own doc comment
	# for why a plain `int` incremented inside a lambda would silently fail.
	var construction_completed_signals: Array = []
	loop.construction_completed.connect(func(_cells: Array) -> void: construction_completed_signals.append(true))
	var demolition_completed_signals: Array = []
	loop.demolition_completed.connect(func(_cells: Array) -> void: demolition_completed_signals.append(true))

	for i in range(loop_config.base_demolition_ticks_block):
		mock_tick.fire_tick()

	assert_int(demolition_completed_signals.size()).is_equal(1)
	assert_int(construction_completed_signals.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Warp invariance (mirrors construction_tick_loop_test.gd's AC24 precedent)
# ---------------------------------------------------------------------------

func test_warp_invariant_demolition_tick_count_to_complete_unchanged_wall_clock_halves() -> void:
	# Arrange — two independent, isolated TimeTickSystem instances (never the
	# registered Autoload), one at warp=1 and one at warp=2.
	var grid_1x: VoxelWorldGrid = _new_grid()
	var system_1x: Object = auto_free(_new_isolated_time_tick_system())
	var loop_1x: ConstructionTickLoop = _new_loop(grid_1x, system_1x)
	var cell_1x: BlueprintCell = _new_built_cell(grid_1x, Vector3i(1, 0, 1))
	assert_bool(loop_1x.create_demolition_order(cell_1x)).is_true()
	assert_bool(loop_1x.claim_demolition_job(cell_1x, 1)).is_true()

	var grid_2x: VoxelWorldGrid = _new_grid()
	var system_2x: Object = auto_free(_new_isolated_time_tick_system())
	@warning_ignore("unsafe_method_access")
	system_2x.set_warp(2)
	var loop_2x: ConstructionTickLoop = _new_loop(grid_2x, system_2x)
	var cell_2x: BlueprintCell = _new_built_cell(grid_2x, Vector3i(1, 0, 1))
	assert_bool(loop_2x.create_demolition_order(cell_2x)).is_true()
	assert_bool(loop_2x.claim_demolition_job(cell_2x, 1)).is_true()

	# Act — the SAME fixed raw per-frame delta drives both (mirrors
	# `construction_tick_loop_test.gd`'s own established magnitude: 4
	# physics-frame steps bank exactly one tick_interval at warp=1).
	for i in range(16):
		@warning_ignore("unsafe_method_access")
		system_1x._physics_process(0.0625)
	for i in range(8):
		@warning_ignore("unsafe_method_access")
		system_2x._physics_process(0.0625)

	# Assert — both cells cleared after exactly the SAME tick count (4); only
	# the wall-clock (physics-frame count: 16 vs 8) needed to reach it
	# differs, halved at warp=2.
	assert_bool(grid_1x.get_cell(Vector3i(1, 0, 1)).is_empty()).is_true()
	assert_bool(grid_2x.get_cell(Vector3i(1, 0, 1)).is_empty()).is_true()
