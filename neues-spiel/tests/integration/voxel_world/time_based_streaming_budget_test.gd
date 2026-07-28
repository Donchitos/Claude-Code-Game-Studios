## Integration test — Voxel World story vox-012 (time-based per-frame page-in
## / eviction budget, ADR-0015 Decision §1; TR-voxel-world-053).
##
## Proves, all against [VoxelWorldGrid.update_residency] / [VoxelWorldGrid._drain_budgeted]:
## 1. AC-1 (time-based, not count-based): with a deterministic injected fake
##    clock ([method VoxelWorldGrid.set_time_source_for_test]), the SAME
##    49-chunk desired "mass approach" set is bounded to a DIFFERENT number
##    of dispatched items per single [method VoxelWorldGrid.update_residency]
##    call depending on the fake clock's simulated per-item cost -- a fixed
##    items-per-frame count would stop at the same item count regardless of
##    per-item cost, so two different counts from the identical list/config
##    (only the clock's step differs) is direct, deterministic proof the
##    cutoff is TIME-driven, not a hardcoded N. The edge case (a single item
##    whose own simulated cost alone exceeds the budget) still gets
##    integrated/dispatched before the loop stops (progress guarantee).
## 2. AC-2 (per-item re-check bounds bursts): a burst of many stale, dirty,
##    resident chunks (an eviction "mass approach") is bounded to the SAME
##    small per-call count the fake clock predicts on the FIRST call (never
##    the full burst at once), and the excess — left resident and dirty,
##    exactly as before this story, never lost or corrupted — is fully
##    processed across enough LATER calls (via [method
##    VoxelWorldGrid.wait_for_async_residency_idle]'s own repeated re-drive),
##    converging to zero.
##
## Determinism (QA rule: no time-dependent assertions): every assertion here
## is against ITEM COUNTS resulting from a deterministic fake clock, never
## against measured real elapsed time or a real sleep/wait duration. The fake
## clock advances by a fixed, test-chosen microsecond step EVERY call,
## regardless of real wall-clock time, so "how many items fit in the budget"
## is fully controlled and reproducible.
##
## Test isolation (accumulated pitfall): every test gets its OWN region
## directory under `user://` (never `res://`, never shared across tests,
## never committed) via [method _make_temp_region_dir], removed recursively
## in [method after_test]. Every grid is settled via [method
## VoxelWorldGrid.wait_for_async_residency_idle] before the test ends
## (belt-and-suspenders alongside [method VoxelWorldGrid._notification]'s own
## PREDELETE safety net — a background task actively executing at the exact
## moment of `free()` can race that net).
class_name TimeBasedStreamingBudgetTest
extends GdUnitTestSuite


## Test-local deterministic fake clock (not a production class): returns a
## controlled, monotonically increasing microsecond value each call,
## advancing by a fixed [member step_usec] EVERY call regardless of real
## wall-clock time. Bound into [VoxelWorldGrid] via
## [method VoxelWorldGrid.set_time_source_for_test] so [method
## VoxelWorldGrid._drain_budgeted]'s per-item elapsed-time check becomes
## fully deterministic and test-controlled — no real sleep, no wall-clock
## read, satisfying the QA determinism rule.
class _FakeClock:
	var value: int = 0
	var step_usec: int = 0

	func tick() -> int:
		value += step_usec
		return value


# ---------------------------------------------------------------------------
# Test isolation — per-test temp region directories, cleaned up after each test
# ---------------------------------------------------------------------------

var _created_region_dirs: Array[String] = []


func after_test() -> void:
	for dir_path: String in _created_region_dirs:
		_remove_dir_recursive(dir_path)
	_created_region_dirs.clear()


func _make_temp_region_dir(suffix: String) -> String:
	var dir_path: String = "user://vox012_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
	_created_region_dirs.append(dir_path)
	return dir_path


func _remove_dir_recursive(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path: String = dir_path.path_join(entry)
			if dir.current_is_dir():
				_remove_dir_recursive(full_path)
			else:
				DirAccess.remove_absolute(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)


# ---------------------------------------------------------------------------
# AC-1 (TR-voxel-world-053) — time-based, not count-based
# ---------------------------------------------------------------------------

func test_update_residency_page_in_dispatch_count_varies_with_simulated_per_item_cost_not_fixed() -> void:
	# Arrange — the IDENTICAL "mass approach" shape (49 desired pristine
	# chunks: view_radius_chunks=3 -> 7x7) and the IDENTICAL page_budget_ms
	# (4.0 ms -> 4000 us) for BOTH grids below; ONLY the fake clock's
	# simulated per-item cost differs. A fixed items-per-frame count could
	# never explain two different results from this identical setup.
	var camera_focus := Vector3i(160, 0, 160)  # chunk (10, 10)

	# Grid A — simulated cost 1 ms/item -> expect exactly 4 items processed
	# (4 x 1000 us = 4000 us == the 4000 us budget; the loop stops the
	# instant elapsed reaches the budget, after the 4th item).
	var config_a := VoxelWorldConfig.new()
	config_a.world_width_cells = 512
	config_a.world_depth_cells = 512
	config_a.region_size_chunks = 8
	config_a.view_radius_chunks = 3
	config_a.settlement_radius_chunks = 0
	config_a.max_concurrent_async_tasks = 64  # far above 49 -- the concurrency cap is deliberately NOT the limiter here
	config_a.page_budget_ms = 4.0
	config_a.region_directory = _make_temp_region_dir("ac1_cost_1ms")
	var grid_a: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_a.config = config_a
	var clock_a := _FakeClock.new()
	clock_a.step_usec = 1000
	grid_a.set_time_source_for_test(Callable(clock_a, "tick"))

	# Grid B — SAME 49-item desired set, SAME 4.0 ms budget, only a DIFFERENT
	# simulated per-item cost (2 ms/item) -> expect exactly 2 items processed.
	var config_b := VoxelWorldConfig.new()
	config_b.world_width_cells = 512
	config_b.world_depth_cells = 512
	config_b.region_size_chunks = 8
	config_b.view_radius_chunks = 3
	config_b.settlement_radius_chunks = 0
	config_b.max_concurrent_async_tasks = 64
	config_b.page_budget_ms = 4.0
	config_b.region_directory = _make_temp_region_dir("ac1_cost_2ms")
	var grid_b: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_b.config = config_b
	var clock_b := _FakeClock.new()
	clock_b.step_usec = 2000
	grid_b.set_time_source_for_test(Callable(clock_b, "tick"))

	# Act — ONE update_residency call each (the "one frame" the QA plan
	# describes). Checked IMMEDIATELY, no wait: a freshly-dispatched task
	# cannot complete within the same synchronous call that dispatched it, so
	# this is deterministic, never a timing race.
	grid_a.update_residency(camera_focus, camera_focus)
	grid_b.update_residency(camera_focus, camera_focus)

	# Assert — different processed counts from the IDENTICAL list/budget,
	# explained ONLY by the differing simulated per-item cost: proof the
	# cutoff is time-driven, not a hardcoded item count.
	assert_int(grid_a.get_in_flight_async_task_count()).is_equal(4)
	assert_int(grid_a.get_resident_chunk_keys().size()).is_equal(0)  # nothing settled yet this call
	assert_int(grid_b.get_in_flight_async_task_count()).is_equal(2)
	assert_int(grid_b.get_resident_chunk_keys().size()).is_equal(0)

	# Cleanup — switch back to the REAL time source before settling: the
	# budget-mandated assertions above are already made, and continuing to
	# settle under the fake clock would (a) re-process the SAME already-
	# resident leading items every re-drive (each still costs one simulated
	# tick under this test's uniform-cost fake clock, so the budget trips at
	# the same point every call and convergence would stall), and (b) risk
	# the fake clock's local RefCounted instance being torn down by GdUnit4's
	# own end-of-test memory sweep before this grid's own
	# NOTIFICATION_PREDELETE settle runs (a real background task can still be
	# in flight at that point). The real clock has no such lifetime
	# dependency and settles near-instantly (real per-item cost is
	# microseconds, well under either budget).
	grid_a.set_time_source_for_test(Callable(Time, "get_ticks_usec"))
	grid_b.set_time_source_for_test(Callable(Time, "get_ticks_usec"))
	grid_a.wait_for_async_residency_idle()
	grid_b.wait_for_async_residency_idle()
	assert_int(grid_a.get_resident_chunk_keys().size()).is_equal(49)
	assert_int(grid_b.get_resident_chunk_keys().size()).is_equal(49)


func test_update_residency_page_in_single_item_exceeding_budget_still_integrates_then_stops() -> void:
	# Arrange — QA plan AC-1 edge case: "a single item that alone exceeds the
	# budget is integrated (progress guaranteed) but the loop then stops."
	# Desired set of 9 pristine chunks (view_radius_chunks=1 -> 3x3), but the
	# fake clock's simulated per-item cost (10 ms) alone blows the 4.0 ms
	# budget.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 0
	config.max_concurrent_async_tasks = 64
	config.page_budget_ms = 4.0
	config.region_directory = _make_temp_region_dir("ac1_single_item_progress")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var clock := _FakeClock.new()
	clock.step_usec = 10000  # 10 ms/item -- alone exceeds the 4.0 ms budget
	grid.set_time_source_for_test(Callable(clock, "tick"))

	# Act
	grid.update_residency(Vector3i(32, 0, 32), Vector3i(32, 0, 32))

	# Assert — progress guaranteed: exactly ONE item was still processed, not
	# zero; the loop then stopped rather than processing any of the remaining
	# 8 candidates.
	assert_int(grid.get_in_flight_async_task_count()).is_equal(1)

	# Cleanup — switch back to the REAL time source before settling (same
	# rationale as the companion dispatch-count-varies test above).
	grid.set_time_source_for_test(Callable(Time, "get_ticks_usec"))
	grid.wait_for_async_residency_idle()
	assert_int(grid.get_resident_chunk_keys().size()).is_equal(9)


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-053) — per-item re-check bounds bursts; excess defers
# to a later frame, nothing lost
# ---------------------------------------------------------------------------

func test_update_residency_eviction_burst_bounded_per_call_and_fully_settles_across_later_calls() -> void:
	# Arrange — an eviction "mass approach": 81 dirty, resident chunks (a 9x9
	# window), matching async_region_io_test.gd's own established shape.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 512
	config.world_depth_cells = 512
	config.region_size_chunks = 8
	config.view_radius_chunks = 4
	config.settlement_radius_chunks = 0
	config.max_concurrent_async_tasks = 128  # far above the burst -- the concurrency cap is deliberately NOT the limiter here
	config.evict_budget_ms = 4.0
	config.region_directory = _make_temp_region_dir("ac2_evict_burst")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Dirty every chunk in a 9x9 window (81 chunks) around a near-origin
	# focus, using the REAL (default) time source for this setup phase --
	# only the ACT phase below engages the fake clock.
	var original_keys: Array[Vector2i] = []
	for dz in range(-4, 5):
		for dx in range(-4, 5):
			var cell := Vector3i(160 + dx * VoxelWorldGrid.CHUNK_SIZE, 0, 160 + dz * VoxelWorldGrid.CHUNK_SIZE)
			grid.set_cell(cell, CellContents.new(7, 2))
			original_keys.append(grid.chunk_key_for_cell(cell))
	assert_int(_count_resident(grid, original_keys)).is_equal(81)  # sanity -- all resident before residency ever ran

	# Switch to the fake, controllable clock only NOW, and move residency far
	# away from the dirtied window in one call -- all 81 chunks become stale
	# (outside the new desired window) AND dirty in the SAME call: an
	# eviction burst.
	var clock := _FakeClock.new()
	clock.step_usec = 1000  # simulated 1 ms/item
	grid.set_time_source_for_test(Callable(clock, "tick"))
	config.view_radius_chunks = 0
	config.settlement_radius_chunks = 0
	var far_focus := Vector3i(0, 0, 0)  # chunk (0, 0) -- well outside the 9x9 window around chunk (10, 10)

	# Act — frame 1: the evict-budget loop stops after exactly 4
	# (budget_usec 4000 / step_usec 1000) -- never the full 81-item burst at
	# once, and never coincidentally a fixed count (the companion AC-1 test
	# proves the SAME budget/step math yields a DIFFERENT count for a
	# different step).
	grid.update_residency(far_focus, far_focus)

	# Assert — checked IMMEDIATELY: exactly 4 evicted this call, 77 still
	# resident/dirty, untouched -- nothing lost, nothing corrupted, simply
	# deferred.
	assert_int(_count_resident(grid, original_keys)).is_equal(81 - 4)

	# Act — settle: switch back to the REAL time source first (same
	# rationale as the companion page-in tests -- avoids both a stalled
	# convergence under this test's uniform-cost fake clock and a dangling
	# reference to the test-local fake clock instance at the grid's own
	# eventual NOTIFICATION_PREDELETE), then let wait_for_async_residency_idle
	# repeatedly re-drive update_residency until nothing is left in flight --
	# proving the deferred excess is fully processed across enough LATER
	# calls, never lost.
	grid.set_time_source_for_test(Callable(Time, "get_ticks_usec"))
	grid.wait_for_async_residency_idle()

	# Assert — every one of the original 81 chunks eventually evicted; the
	# per-call budget was never exceeded along the way (proven by the
	# frame-1 assertion above), and the burst fully converges.
	assert_int(_count_resident(grid, original_keys)).is_equal(0)
	assert_int(grid.get_in_flight_async_task_count()).is_equal(0)


## Counts how many of [param keys] are CURRENTLY resident on [param grid] --
## test helper avoiding pollution from any OTHER chunk (e.g. the destination
## focus cell's own incidental page-in) that
## [method VoxelWorldGrid.get_resident_chunk_keys]'s raw total would include.
func _count_resident(grid: VoxelWorldGrid, keys: Array[Vector2i]) -> int:
	var count: int = 0
	for key: Vector2i in keys:
		if grid.is_chunk_resident(key):
			count += 1
	return count
