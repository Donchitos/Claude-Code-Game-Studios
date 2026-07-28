## Integration test — Voxel World story vox-017 (ADR-0015 §6 production note —
## completion-driven residency drain loop; TR-voxel-world-053).
##
## Proves, against the REAL production `src/voxel_world/voxel_world_grid.gd`
## (never a reimplementation):
## 1. AC-1 (completion-driven, not polled) — GREP-VERIFIABLE, matching this
##    codebase's own established precedent
##    (`read_through_inflight_cache_test.gd`'s
##    `test_request_resident_body_checks_write_in_flight_cache`): the two
##    per-tick reap bodies ([method VoxelWorldGrid._reap_finished_async_writes]/
##    [method VoxelWorldGrid._reap_finished_async_reads]) and [method
##    VoxelWorldGrid._request_resident] (the page-in request [method
##    VoxelWorldGrid.update_residency] calls every tick) never reference
##    [method WorkerThreadPool.is_task_completed] — completion is detected
##    exclusively via the mutex-guarded [member VoxelWorldGrid._read_results]/
##    [member VoxelWorldGrid._write_results] dictionaries' own key presence,
##    populated once by the completing background task itself, never polled
##    from the calling thread. [method VoxelWorldGrid._try_integrate_read]
##    (used ONLY by the explicit, bounded, non-per-frame test/sync helpers
##    [method VoxelWorldGrid.wait_for_async_residency_idle]/[method
##    VoxelWorldGrid.drain_pending_async_reads]) is DELIBERATELY EXCLUDED from
##    this "never polls" claim — the ADR's own production note names "the
##    [per-tick] drain loop" specifically, not a test sync helper.
## 2. AC-1 edge case (zero completions -> no per-item work) and AC-2
##    (functional correctness preserved at both a small and a "mass approach"
##    large queue size) — behavioral, deterministic, no timing assertions
##    (QA determinism rule: measurement variance belongs in evidence, not in
##    an assertion) — using ONLY the already-established "a freshly-dispatched
##    background task cannot complete and be integrated within the SAME
##    synchronous call that dispatched it" causality convention this
##    codebase's OWN existing tests already rely on (`async_region_io_test.gd`,
##    `time_based_streaming_budget_test.gd`), never a real elapsed-time
##    assertion between two separate calls (which WOULD be racy — real
##    background completion timing is inherently non-deterministic across
##    calls, which is precisely why the quantitative "cost scales with
##    completions, not queue size" claim (QA plan AC-2) is measured instead in
##    `tools/vox017_completion_driven_drain_measurement.gd`'s own dedicated
##    headless tool, per this project's QA determinism rule, not asserted here).
##
## Test isolation (accumulated pitfall): every test gets its OWN region
## directory under `user://` (never `res://`, never shared across tests,
## never committed) via [method _make_temp_region_dir], removed recursively
## in [method after_test]. Every grid is settled via [method
## VoxelWorldGrid.wait_for_async_residency_idle] before the test ends
## (belt-and-suspenders alongside [method VoxelWorldGrid._notification]'s own
## PREDELETE safety net).
class_name CompletionDrivenDrainTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test isolation — per-test temp region directories, cleaned up after each test
# ---------------------------------------------------------------------------

var _created_region_dirs: Array[String] = []


func after_test() -> void:
	for dir_path: String in _created_region_dirs:
		_remove_dir_recursive(dir_path)
	_created_region_dirs.clear()


func _make_temp_region_dir(suffix: String) -> String:
	var dir_path: String = "user://vox017_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
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


## Extracts a single top-level function's source body (from its `func` line
## up to, but not including, the NEXT top-level `\nfunc `) — the same
## grep-verifiable technique `read_through_inflight_cache_test.gd`'s own
## `test_request_resident_body_checks_write_in_flight_cache` established.
func _extract_function_body(source: String, func_signature_prefix: String) -> String:
	var start: int = source.find(func_signature_prefix)
	assert_int(start).is_greater(-1)
	var next_func: int = source.find("\nfunc ", start + 1)
	assert_int(next_func).is_greater(-1)
	return source.substr(start, next_func - start)


# ---------------------------------------------------------------------------
# AC-1 (TR-voxel-world-053) — completion-driven, never polled: grep-verifiable
# ---------------------------------------------------------------------------

func test_reap_finished_async_writes_body_never_polls_is_task_completed() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")
	var body: String = _extract_function_body(source, "func _reap_finished_async_writes(")

	assert_bool(body.contains("is_task_completed")).is_false()
	assert_bool(body.contains("_write_results.keys()")).is_true()


func test_reap_finished_async_reads_body_never_polls_is_task_completed() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")
	var body: String = _extract_function_body(source, "func _reap_finished_async_reads(")

	assert_bool(body.contains("is_task_completed")).is_false()
	assert_bool(body.contains("_read_results.keys()")).is_true()


func test_request_resident_body_never_polls_is_task_completed() -> void:
	# _request_resident is what update_residency's per-tick pending-write-retry
	# and desired-window page-in phases call for every requested chunk, every
	# tick — this is the exact call site that used to re-poll a not-yet-ready
	# chunk's completion status on every tick it stayed desired (ADR-0015 §6
	# production note's "re-scans every not-yet-ready queued item every
	# tick"). Story vox-017 removes that poll entirely from this method.
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")
	var body: String = _extract_function_body(source, "func _request_resident(")

	assert_bool(body.contains("is_task_completed")).is_false()
	# Still correctly composes with the write-in-flight read-through cache
	# (Story vox-013) and still dispatches fresh work (Story vox-011) — this
	# story only removes the completion POLL, nothing else about this
	# method's other responsibilities.
	assert_bool(body.contains("_try_serve_from_in_flight_write")).is_true()
	assert_bool(body.contains("_try_dispatch_read")).is_true()


func test_try_integrate_read_still_polls_for_explicit_test_sync_helpers_only() -> void:
	# Documents the deliberate exception: _try_integrate_read is NOT part of
	# update_residency's own per-tick call graph any more (see the three tests
	# above) — it still polls is_task_completed, but is used ONLY by
	# wait_for_async_residency_idle/drain_pending_async_reads, explicit,
	# bounded, non-per-frame sync helpers the ADR's production note does not
	# target.
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")
	var body: String = _extract_function_body(source, "func _try_integrate_read(")

	assert_bool(body.contains("is_task_completed")).is_true()

	# And update_residency's own body must never call it directly.
	var update_residency_body: String = _extract_function_body(source, "func update_residency(")
	assert_bool(update_residency_body.contains("_try_integrate_read")).is_false()


# ---------------------------------------------------------------------------
# AC-1 edge case + AC-2 (TR-voxel-world-053) — behavioral, deterministic
# ---------------------------------------------------------------------------

func test_update_residency_write_reap_mass_approach_settles_correctly_at_scale() -> void:
	# Arrange — a "mass approach" write burst (81 dirty chunks, a 9x9 window,
	# matching this codebase's own established shape in
	# time_based_streaming_budget_test.gd/async_region_io_test.gd), cap high
	# enough every flush dispatches in ONE call.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 512
	config.world_depth_cells = 512
	config.region_size_chunks = 8
	config.view_radius_chunks = 0
	config.settlement_radius_chunks = 0
	config.max_concurrent_async_tasks = 128
	# A generous one-shot dispatch budget (Story vox-012's own per-item time
	# budget is orthogonal to this story's completion-driven reap and would
	# otherwise cap how many of the 81 flushes dispatch in the ONE call below
	# to whatever fits in the default 4.0 ms window -- a real, measured, non-
	# deterministic count depending on disk/OS overhead, not the fixed 81 this
	# test wants to guarantee dispatches together).
	config.evict_budget_ms = 500.0
	config.region_directory = _make_temp_region_dir("write_mass_approach")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	var original_keys: Array[Vector2i] = []
	for dz in range(-4, 5):
		for dx in range(-4, 5):
			var cell := Vector3i(160 + dx * VoxelWorldGrid.CHUNK_SIZE, 0, 160 + dz * VoxelWorldGrid.CHUNK_SIZE)
			grid.set_cell(cell, CellContents.new(9, 3))
			original_keys.append(grid.chunk_key_for_cell(cell))
	assert_int(_count_resident(grid, original_keys)).is_equal(81)

	# Act — evict all 81 in one call. Focus is OUT OF WORLD BOUNDS (matching
	# `load_before_write_test.gd`/`region_file_residency_test.gd`'s own
	# established `Vector3i(9999, 0, 9999)` convention) so the desired window
	# is genuinely EMPTY -- an in-bounds far focus like (0,0,0) would itself
	# be a pristine desired chunk and add one extra, unrelated page-in
	# dispatch on top of the 81 eviction flushes this test isolates. The
	# completion-driven write-reap phase has nothing to reap yet (nothing
	# dispatched before this call), so this call only DISPATCHES the 81
	# flushes.
	var far_focus := Vector3i(9999, 0, 9999)
	grid.update_residency(far_focus, far_focus)
	assert_int(_count_resident(grid, original_keys)).is_equal(0)  # dropped the instant each flush dispatched
	assert_int(grid.get_in_flight_async_task_count()).is_equal(81)

	# Act — settle across simulated later frames (bounded test helper): the
	# completion-driven reap phase integrates each flush's result the instant
	# it actually reports done, never polling the full in-flight set.
	grid.wait_for_async_residency_idle()

	# Assert — every one of the 81 flushes eventually reaped; nothing lost.
	assert_int(grid.get_in_flight_async_task_count()).is_equal(0)

	# Assert — a fresh grid pointed at the same region directory reads back
	# every originally-written value, proving the completion-driven reap
	# genuinely persisted the data (not merely "stopped polling").
	var config2 := VoxelWorldConfig.new()
	config2.world_width_cells = config.world_width_cells
	config2.world_depth_cells = config.world_depth_cells
	config2.region_size_chunks = config.region_size_chunks
	config2.view_radius_chunks = config.view_radius_chunks
	config2.settlement_radius_chunks = config.settlement_radius_chunks
	config2.max_concurrent_async_tasks = config.max_concurrent_async_tasks
	config2.region_directory = config.region_directory
	var grid2: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid2.config = config2
	var probe_cell := Vector3i(160, 0, 160)
	grid2.update_residency(probe_cell, probe_cell)
	grid2.wait_for_async_residency_idle()
	assert_int(grid2.get_cell(probe_cell).block_type_id).is_equal(9)
	assert_int(grid2.get_cell(probe_cell).material_id).is_equal(3)


func test_update_residency_read_reap_mass_approach_settles_correctly_at_scale() -> void:
	# Arrange — a "mass approach" pristine page-in burst (49 desired chunks, a
	# 7x7 window around a camera focus), cap high enough every regen dispatches
	# in ONE call.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 512
	config.world_depth_cells = 512
	config.region_size_chunks = 8
	config.view_radius_chunks = 3
	config.settlement_radius_chunks = 0
	config.max_concurrent_async_tasks = 64
	# Generous one-shot dispatch budget -- see the write-side companion test's
	# own comment for why the default 4.0 ms is not safe to rely on for "all
	# 49 dispatch in exactly one call" (region-file/header creation cost is a
	# real, measured, non-deterministic variable).
	config.page_budget_ms = 500.0
	config.region_directory = _make_temp_region_dir("read_mass_approach")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act — dispatch call: nothing resident yet (a freshly-dispatched task
	# cannot complete within the same synchronous call that dispatched it —
	# deterministic, not a race).
	var camera_focus := Vector3i(160, 0, 160)
	grid.update_residency(camera_focus, camera_focus)
	assert_int(grid.get_resident_chunk_keys().size()).is_equal(0)
	assert_int(grid.get_in_flight_async_task_count()).is_equal(49)

	# Act — settle: the completion-driven read-reap phase integrates each
	# regen result the instant it actually reports done.
	grid.wait_for_async_residency_idle()

	# Assert — every one of the 49 desired chunks eventually became resident,
	# and the in-flight set fully drained — nothing lost.
	assert_int(grid.get_resident_chunk_keys().size()).is_equal(49)
	assert_int(grid.get_in_flight_async_task_count()).is_equal(0)


func test_update_residency_write_reap_zero_completions_immediately_after_dispatch_reaps_nothing() -> void:
	# AC-1 edge case ("zero completions this tick -> drain does no per-item
	# work") — deterministic via the SAME-call dispatch causality convention
	# (never a real elapsed-time assertion across two separate calls, which
	# would be racy): checked in the SAME call that performs the dispatch, a
	# freshly-dispatched flush cannot yet be reaped, so the completion-driven
	# write-reap phase (which ran at the TOP of this very call, before any
	# dispatch happened) provably did zero per-item work this call.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 512
	config.world_depth_cells = 512
	config.region_size_chunks = 8
	config.view_radius_chunks = 0
	config.settlement_radius_chunks = 0
	config.max_concurrent_async_tasks = 32
	# Generous one-shot dispatch budget -- see the companion mass-approach
	# test's own comment for why this must not be left at the default 4.0 ms
	# (region-file/header creation cost is a real, measured, non-deterministic
	# variable this test does not want to depend on).
	config.evict_budget_ms = 500.0
	config.region_directory = _make_temp_region_dir("write_zero_completions")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var cell := Vector3i(160 + dx * VoxelWorldGrid.CHUNK_SIZE, 0, 160 + dz * VoxelWorldGrid.CHUNK_SIZE)
			grid.set_cell(cell, CellContents.new(5, 1))

	# Act — the dispatch call itself. Focus is OUT OF WORLD BOUNDS (see the
	# companion mass-approach test's own comment -- an in-bounds far focus
	# would add one extra, unrelated page-in dispatch for its own pristine
	# chunk). Its OWN write-reap phase (running first, before this call's
	# dispatch work happens) sees an empty _write_results (nothing was ever
	# dispatched before this call) and therefore reaps exactly zero items —
	# provable by construction, not timing.
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))

	# Assert — all 25 dirty chunks got dispatched (none reaped this same
	# call, since none could have completed before their own dispatch).
	assert_int(grid.get_in_flight_async_task_count()).is_equal(25)

	grid.wait_for_async_residency_idle()


## Counts how many of [param keys] are CURRENTLY resident on [param grid] --
## avoids pollution from any other incidental page-in, matching
## `time_based_streaming_budget_test.gd`'s own established helper.
func _count_resident(grid: VoxelWorldGrid, keys: Array[Vector2i]) -> int:
	var count: int = 0
	for key: Vector2i in keys:
		if grid.is_chunk_resident(key):
			count += 1
	return count
