## Unit test — Building System Story building-029 (Construction tick loop:
## Planned -> UnderConstruction -> Built, F3). ADR-0016 primary (blueprint
## cells convert to real blocks via worker-executed jobs only); Time & Tick
## System secondary (construction advances on game ticks, never raw delta).
##
## Proves:
## 1. AC43 [TR-building-system-068]: the mocked job-claim seam ([method
##    ConstructionTickLoop.claim_job]) transitions Planned -> UnderConstruction,
##    queryable as distinct from Planned; a non-Planned cell cannot be
##    (re-)claimed.
## 2. AC20 [TR-building-system-079]: a cell fed `base_build_ticks[category]`
##    tick events via a mocked on-site job completes -- the Voxel World write
##    occurs and the cell is Built; fewer ticks leaves it UnderConstruction.
##    Covers both the BLOCK and FURNITURE categories (F3's two knobs).
## 3. AC22 [TR-building-system-058]: zero tick events leave progress
##    unchanged (this system reacts only to ticks).
## 4. AC24 [TR-building-system-079]: warp invariance, proven against a REAL
##    (isolated, never-autoloaded) [TimeTickSystem] instance -- time-warp
##    halves the wall-clock (physics-frame count) needed, never the tick
##    COUNT required to complete.
## 5. AC26 [TR-building-system-058]: construction does not advance while a
##    REAL isolated [TimeTickSystem] instance is paused; resuming lets it
##    proceed again.
## 6. AC25 [TR-building-system-080]: a tick burst of 10 with the current
##    cell needing only 2 more completes it, and a separate, UNCLAIMED
##    queued cell receives none of that burst's leftover ticks.
## 7. AC45 [TR-building-system-080]: two independently-claimed jobs on
##    distinct cells advance independently within the same tick burst; a
##    job's completion never affects the other job's own progress.
## 8. Story building-028 (ADR-0016 BV-1 ruling): a FURNITURE-category claim
##    is refused without a Built support cell (AC49); a completing FURNITURE
##    job is BUILT as a job but NEVER written into VoxelWorldGrid, and is
##    routed to a wired [FurnitureRegistry] instead (or silently dropped when
##    none is wired — never a grid-write fallback).
##
## Per the tick-system test precedent (`tick_accumulator_test.gd`,
## `pause_warp_state_test.gd`): `time_tick_system.gd` deliberately carries no
## `class_name` (it would hide the "TimeTickSystem" Autoload singleton), so
## isolated instances are constructed via a preloaded [GDScript] and
## duck-typed at each access site. [MockTimeTickSystem]
## (`tests/integration/villager_ai/mock_time_tick_system.gd`) is reused
## directly for the tests that only need a manually-fired `tick` signal with
## no real accumulator math (mirrors `priority_decision_loop_test.gd`'s own
## established reuse of that double).
class_name ConstructionTickLoopTest
extends GdUnitTestSuite

const TimeTickSystemScript: GDScript = preload("res://src/time_tick_system/time_tick_system.gd")


# ---------------------------------------------------------------------------
# Test helpers
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


## Returns a fresh, never-autoloaded TimeTickSystem-script instance -- see
## class doc comment. Untyped return, mirroring `tick_accumulator_test.gd`'s
## established precedent.
func _new_isolated_time_tick_system() -> Object:
	var system: Object = TimeTickSystemScript.new()
	@warning_ignore("unsafe_property_access")
	system.config = TimeTickConfig.new()
	@warning_ignore("unsafe_method_access")
	system.setup()
	return system


# ---------------------------------------------------------------------------
# AC43 — mocked job-claim seam: Planned -> UnderConstruction, distinct state
# ---------------------------------------------------------------------------

func test_claim_job_transitions_planned_to_under_construction() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var cell := BlueprintCell.new(Vector3i(1, 0, 1))
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.PLANNED)

	# Act
	var claimed: bool = loop.claim_job(cell, 7)

	# Assert — distinct from Planned, queryable via the cell's own state.
	assert_bool(claimed).is_true()
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_int(cell.state).is_not_equal(BlueprintCell.MicroState.PLANNED)
	assert_bool(loop.is_job_active(cell.cell)).is_true()


func test_claim_job_on_already_under_construction_cell_fails() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var cell := BlueprintCell.new(Vector3i(1, 0, 1))
	assert_bool(loop.claim_job(cell, 1)).is_true()

	# Act — a second claim on the same (now UnderConstruction) cell.
	var reclaimed: bool = loop.claim_job(cell, 2)

	# Assert — rejected; the original claim is untouched.
	assert_bool(reclaimed).is_false()
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)


func test_claim_job_on_built_cell_fails() -> void:
	# Arrange — a cell already Built (terminal per-cell state).
	var cell := BlueprintCell.new(Vector3i(1, 0, 1), BlueprintCell.MicroState.BUILT)
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))

	# Act
	var claimed: bool = loop.claim_job(cell, 1)

	# Assert
	assert_bool(claimed).is_false()
	assert_bool(loop.is_job_active(cell.cell)).is_false()


# ---------------------------------------------------------------------------
# AC20 — cell completes after base_build_ticks[category] tick events
# ---------------------------------------------------------------------------

func test_cell_completes_after_base_build_ticks_block_events() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell := BlueprintCell.new(Vector3i(2, 0, 2))
	loop.claim_job(cell, 1)

	# Act — exactly base_build_ticks_block (default 4) tick events.
	for i in range(loop_config.base_build_ticks_block):
		mock_tick.fire_tick()

	# Assert — the Voxel World write occurred and the cell is Built.
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(loop.is_job_active(cell.cell)).is_false()
	var written: CellContents = grid.get_cell(cell.cell)
	assert_bool(written.is_empty()).is_false()
	assert_int(written.block_type_id).is_equal(cell.contents.block_type_id)
	assert_int(written.material_id).is_equal(cell.contents.material_id)


func test_fewer_ticks_than_required_leaves_cell_under_construction() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell := BlueprintCell.new(Vector3i(2, 0, 2))
	loop.claim_job(cell, 1)

	# Act — one tick short of the required total.
	for i in range(loop_config.base_build_ticks_block - 1):
		mock_tick.fire_tick()

	# Assert — still UnderConstruction; nothing written to the grid yet.
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_int(loop.get_progress_ticks(cell.cell)).is_equal(loop_config.base_build_ticks_block - 1)
	assert_bool(grid.get_cell(cell.cell).is_empty()).is_true()


func test_furniture_category_uses_the_furniture_tick_count() -> void:
	# Arrange — F3's separate `base_build_ticks[furniture]` knob (default 8).
	# A support cell directly below is required for `claim_job` to accept a
	# FURNITURE-category claim at all (Story building-028, AC49 — "construction
	# cannot start until the support cell is Built").
	var grid: VoxelWorldGrid = _new_grid()
	grid.set_cell(Vector3i(3, 0, 3), CellContents.new(1, 0))
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell := BlueprintCell.new(Vector3i(3, 1, 3), BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.FURNITURE)
	assert_bool(loop.claim_job(cell, 1)).is_true()

	# Act — one short of the furniture total; still UnderConstruction.
	for i in range(loop_config.base_build_ticks_furniture - 1):
		mock_tick.fire_tick()
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)

	# Act — the final tick completes it.
	mock_tick.fire_tick()

	# Assert — Story building-028 (ADR-0016 BV-1 ruling): a completing
	# FURNITURE-category job is BUILT as a job, but NEVER written into
	# VoxelWorldGrid — furniture is not voxel data. (Prior to building-028
	# this asserted the opposite; that was the pre-ruling behavior this story
	# was tasked with overturning.)
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(grid.get_cell(cell.cell).is_empty()).is_true()


func test_furniture_claim_without_a_built_support_cell_is_refused() -> void:
	# Story building-028, AC49 — the support cell below is EMPTY (never
	# built); claim_job must refuse a FURNITURE-category claim outright.
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var cell := BlueprintCell.new(Vector3i(9, 0, 9), BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.FURNITURE)

	var claimed: bool = loop.claim_job(cell, 1)

	assert_bool(claimed).is_false()
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.PLANNED)
	assert_bool(loop.is_job_active(cell.cell)).is_false()


func test_completing_furniture_job_routes_to_the_furniture_registry() -> void:
	# Story building-028 (ADR-0016 BV-1 ruling) — a completing FURNITURE cell
	# is routed to the furniture registry instead of VoxelWorldGrid.
	var grid: VoxelWorldGrid = _new_grid()
	grid.set_cell(Vector3i(4, 0, 4), CellContents.new(1, 0))
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var registry := FurnitureRegistry.new()
	loop.furniture_registry = registry
	var cell := BlueprintCell.new(
		Vector3i(4, 1, 4), BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.FURNITURE, null, &"bed"
	)
	assert_bool(loop.claim_job(cell, 3)).is_true()

	for i in range(loop_config.base_build_ticks_furniture):
		mock_tick.fire_tick()

	assert_bool(grid.get_cell(cell.cell).is_empty()).is_true()
	var placed: Array[Dictionary] = registry.get_placed_furniture()
	assert_int(placed.size()).is_equal(1)
	assert_str(String(placed[0]["definition_id"])).is_equal("bed")
	assert_bool((placed[0]["cells"] as Array).has(Vector3i(4, 1, 4))).is_true()


func test_completing_furniture_job_with_no_registry_wired_never_writes_the_grid() -> void:
	# Story building-028 — a null furniture_registry silently drops the
	# placement record; it never falls back to writing the grid.
	var grid: VoxelWorldGrid = _new_grid()
	grid.set_cell(Vector3i(5, 0, 5), CellContents.new(1, 0))
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell := BlueprintCell.new(Vector3i(5, 1, 5), BlueprintCell.MicroState.PLANNED, BlueprintCell.Category.FURNITURE)
	assert_bool(loop.claim_job(cell, 1)).is_true()

	for i in range(loop_config.base_build_ticks_furniture):
		mock_tick.fire_tick()

	assert_int(cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(grid.get_cell(cell.cell).is_empty()).is_true()


func test_required_ticks_for_reads_the_matching_config_field() -> void:
	# Pure-function coverage (mirrors PlacementPick.is_drag's precedent).
	var loop_config := ConstructionTickLoopConfig.new()
	loop_config.base_build_ticks_block = 5
	loop_config.base_build_ticks_furniture = 11

	assert_int(ConstructionTickLoop.required_ticks_for(BlueprintCell.Category.BLOCK, loop_config)).is_equal(5)
	assert_int(ConstructionTickLoop.required_ticks_for(BlueprintCell.Category.FURNITURE, loop_config)).is_equal(11)


# ---------------------------------------------------------------------------
# AC22 — zero tick events leave progress unchanged
# ---------------------------------------------------------------------------

func test_zero_tick_events_leaves_progress_unchanged() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var loop: ConstructionTickLoop = _new_loop(grid, auto_free(MockTimeTickSystem.new()))
	var cell := BlueprintCell.new(Vector3i(4, 0, 4))
	loop.claim_job(cell, 1)

	# Act — no tick events fired at all.

	# Assert
	assert_int(loop.get_progress_ticks(cell.cell)).is_equal(0)
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_bool(grid.get_cell(cell.cell).is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC24 — warp invariance (real isolated TimeTickSystem instances)
# ---------------------------------------------------------------------------

func test_warp_invariant_tick_count_to_complete_unchanged_wall_clock_halves() -> void:
	# Arrange — two independent, isolated TimeTickSystem instances (never the
	# registered Autoload), one at warp=1 and one at warp=2, each driving its
	# own ConstructionTickLoop + blueprint cell. ticks_per_second defaults to
	# 4.0 (tick_interval = 0.25s); base_build_ticks_block defaults to 4.
	var grid_1x: VoxelWorldGrid = _new_grid()
	var system_1x: Object = auto_free(_new_isolated_time_tick_system())
	var loop_1x: ConstructionTickLoop = _new_loop(grid_1x, system_1x)
	var cell_1x := BlueprintCell.new(Vector3i(1, 0, 1))
	loop_1x.claim_job(cell_1x, 1)

	var grid_2x: VoxelWorldGrid = _new_grid()
	var system_2x: Object = auto_free(_new_isolated_time_tick_system())
	@warning_ignore("unsafe_method_access")
	system_2x.set_warp(2)
	var loop_2x: ConstructionTickLoop = _new_loop(grid_2x, system_2x)
	var cell_2x := BlueprintCell.new(Vector3i(1, 0, 1))
	loop_2x.claim_job(cell_2x, 1)

	# Act — the SAME fixed raw per-frame delta (0.0625s, mirrors
	# `tick_accumulator_test.gd`'s own established magnitude) drives both.
	# At warp=1, 4 physics-frame steps bank exactly one tick_interval (4 x
	# 0.0625 = 0.25s) -- 16 steps therefore fire exactly 4 ticks (1
	# simulated second at 4.0 ticks/sec). At warp=2, game_delta doubles per
	# step, so the SAME 4 ticks fire in HALF as many steps (8).
	for i in range(16):
		@warning_ignore("unsafe_method_access")
		system_1x._physics_process(0.0625)
	for i in range(8):
		@warning_ignore("unsafe_method_access")
		system_2x._physics_process(0.0625)

	# Assert — both cells complete after exactly the SAME tick count (4);
	# only the wall-clock (physics-frame count: 16 vs 8) needed to reach it
	# differs, halved at warp=2 -- tick count to complete is unchanged.
	assert_int(cell_1x.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(cell_2x.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(grid_1x.get_cell(Vector3i(1, 0, 1)).is_empty()).is_false()
	assert_bool(grid_2x.get_cell(Vector3i(1, 0, 1)).is_empty()).is_false()


# ---------------------------------------------------------------------------
# AC26 — paused halts construction (real isolated TimeTickSystem instance)
# ---------------------------------------------------------------------------

func test_paused_real_time_tick_system_construction_does_not_advance() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid()
	var system: Object = auto_free(_new_isolated_time_tick_system())
	var loop: ConstructionTickLoop = _new_loop(grid, system)
	var cell := BlueprintCell.new(Vector3i(1, 0, 1))
	loop.claim_job(cell, 1)
	var ticks_fired: Array = []
	@warning_ignore("unsafe_property_access")
	system.tick.connect(func() -> void: ticks_fired.append(true))

	@warning_ignore("unsafe_method_access")
	system.pause()

	# Act — plenty of real physics frames' worth of nonzero raw delta while
	# paused (well over the 16 steps that would otherwise complete the cell).
	for i in range(20):
		@warning_ignore("unsafe_method_access")
		system._physics_process(0.0625)

	# Assert — zero ticks ever fired; construction progress untouched.
	# (Blueprint CREATION while paused is CommitPipeline's own concern,
	# already covered by that story's test -- this asserts only the
	# construction-progress half.)
	assert_int(ticks_fired.size()).is_equal(0)
	assert_int(loop.get_progress_ticks(cell.cell)).is_equal(0)
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_bool(grid.get_cell(cell.cell).is_empty()).is_true()

	# Act — resuming lets the SAME claimed job proceed normally afterward.
	@warning_ignore("unsafe_method_access")
	system.resume()
	for i in range(16):
		@warning_ignore("unsafe_method_access")
		system._physics_process(0.0625)

	# Assert
	assert_int(cell.state).is_equal(BlueprintCell.MicroState.BUILT)


# ---------------------------------------------------------------------------
# AC25 — burst of 10; current cell needs 2 more; no rollover to a queued cell
# ---------------------------------------------------------------------------

func test_burst_completes_current_cell_and_does_not_roll_over_to_a_queued_cell() -> void:
	# Arrange — a claimed cell already 2 ticks short of its 4-tick total,
	# and a SEPARATE, still-unclaimed (Planned) cell sitting in the queue.
	var grid: VoxelWorldGrid = _new_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var claimed_cell := BlueprintCell.new(Vector3i(1, 0, 1))
	loop.claim_job(claimed_cell, 1)
	for i in range(loop_config.base_build_ticks_block - 2):
		mock_tick.fire_tick()
	assert_int(loop.get_progress_ticks(claimed_cell.cell)).is_equal(loop_config.base_build_ticks_block - 2)
	var queued_cell := BlueprintCell.new(Vector3i(9, 0, 9))

	# Act — a burst of 10 tick events (mirrors TimeTickSystem's own
	# `max_ticks_per_frame` firing this signal 10 times synchronously in one
	# frame; this class has no burst loop of its own to distinguish "10
	# separate emissions in one frame" from "10 emissions across many
	# frames" -- both are simply 10 calls to _on_tick()).
	for i in range(10):
		mock_tick.fire_tick()

	# Assert — the claimed cell completed (used exactly its remaining 2
	# ticks); the other 8 ticks in the burst did nothing further to it
	# (no crash, no re-trigger, no double write); the unclaimed queued cell
	# received NONE of the leftover burst ticks -- still Planned, untouched.
	assert_int(claimed_cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(loop.is_job_active(claimed_cell.cell)).is_false()
	assert_int(loop.get_progress_ticks(claimed_cell.cell)).is_equal(0)
	assert_int(queued_cell.state).is_equal(BlueprintCell.MicroState.PLANNED)
	assert_bool(grid.get_cell(queued_cell.cell).is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC45 — two independently-claimed jobs advance independently in one burst
# ---------------------------------------------------------------------------

func test_two_villagers_distinct_cells_advance_independently_in_one_burst() -> void:
	# Arrange — job B is claimed first and pre-advanced to 1 tick short of
	# completion; job A is claimed fresh AFTER that (so job A's own progress
	# is unaffected by the ticks job B already consumed).
	var grid: VoxelWorldGrid = _new_grid()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(grid, mock_tick, loop_config)
	var cell_b := BlueprintCell.new(Vector3i(5, 0, 5))
	loop.claim_job(cell_b, 2)
	for i in range(loop_config.base_build_ticks_block - 1):
		mock_tick.fire_tick()
	assert_int(loop.get_progress_ticks(cell_b.cell)).is_equal(loop_config.base_build_ticks_block - 1)
	var cell_a := BlueprintCell.new(Vector3i(2, 0, 2))
	loop.claim_job(cell_a, 1)
	assert_int(loop.get_progress_ticks(cell_a.cell)).is_equal(0)

	# Act — the FIRST tick of the burst: villager 2's job (cell_b) reaches
	# its total and completes; villager 1's job (cell_a) merely advances by
	# one, in the SAME _on_tick() dispatch.
	mock_tick.fire_tick()

	# Assert — at most one cell completed this tick (cell_b); cell_a's own
	# progress advanced independently and did NOT also complete.
	assert_int(cell_b.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(cell_a.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_int(loop.get_progress_ticks(cell_a.cell)).is_equal(1)

	# Act — the remaining ticks of the burst let cell_a's own job finish on
	# its own schedule, independent of cell_b's already-completed job.
	for i in range(loop_config.base_build_ticks_block - 1):
		mock_tick.fire_tick()

	# Assert — both cells are now Built; neither job interfered with the
	# other's own tick count.
	assert_int(cell_a.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(loop.is_job_active(cell_a.cell)).is_false()
	assert_bool(loop.is_job_active(cell_b.cell)).is_false()
	assert_bool(grid.get_cell(cell_a.cell).is_empty()).is_false()
	assert_bool(grid.get_cell(cell_b.cell).is_empty()).is_false()


# ---------------------------------------------------------------------------
# Config (ADR-0002 two-tier policy) -- base_build_ticks_block/furniture
# ---------------------------------------------------------------------------

func test_base_build_ticks_block_out_of_range_clamps_with_warning() -> void:
	# Arrange
	var loop_config := ConstructionTickLoopConfig.new()
	loop_config.base_build_ticks_block = 0

	# Act
	var issues: Array[String] = loop_config.validate()

	# Assert
	assert_int(loop_config.base_build_ticks_block).is_equal(ConstructionTickLoopConfig.BASE_BUILD_TICKS_BLOCK_MIN)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("base_build_ticks_block"))).is_true()


func test_base_build_ticks_furniture_out_of_range_clamps_with_warning() -> void:
	# Arrange
	var loop_config := ConstructionTickLoopConfig.new()
	loop_config.base_build_ticks_furniture = 1000

	# Act
	var issues: Array[String] = loop_config.validate()

	# Assert
	assert_int(loop_config.base_build_ticks_furniture).is_equal(
		ConstructionTickLoopConfig.BASE_BUILD_TICKS_FURNITURE_MAX
	)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("base_build_ticks_furniture"))).is_true()
