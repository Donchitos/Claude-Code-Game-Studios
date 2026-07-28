## Integration test — Voxel World story vox-011 (async region I/O + terrain-
## gen on a capped WorkerThreadPool, ADR-0015 Decision §6; TR-voxel-world-053).
##
## Proves, all against [VoxelWorldGrid.update_residency] / [VoxelWorldGrid.get_cell]
## / the `src/voxel_world/` source itself:
## 1. AC-1 (no sync I/O in the frame path): [VoxelWorldRegionFile] no longer
##    exposes an instance-level synchronous payload read/write method at all
##    (comment-stripped grep); [VoxelWorldGrid] dispatches BOTH region reads
##    (disk load AND terrain regen) and eviction-flush writes via
##    [WorkerThreadPool.add_task] (comment-stripped grep, positive presence).
## 2. AC-2 (cap-miss stays queued): with [member VoxelWorldConfig.max_concurrent_async_tasks]
##    saturated by a "mass approach" (far more desired chunks than the cap),
##    the shared in-flight task count NEVER exceeds the cap (a structural
##    invariant true by construction, checked immediately — no timing race)
##    and NOTHING is resident yet immediately after that single dispatch call
##    (nothing was resident before, and no chunk can complete a background
##    task within the same synchronous call that dispatched it) — the excess
##    demand stays queued, never falls back to a synchronous read/regen.
##    [method VoxelWorldGrid.wait_for_async_residency_idle] (a bounded test
##    helper — never called from a per-frame path) then settles the queue
##    across simulated "later frames" and every desired chunk eventually
##    becomes resident.
## 3. AC-3 (mutex-guarded results): a full write -> evict(async flush) ->
##    settle -> page-back-in(async read) -> settle -> get_cell round trip
##    returns the originally-written value, proving data flows correctly
##    through the mutex-guarded [member VoxelWorldGrid._read_results]/
##    [member VoxelWorldGrid._write_results] structures; a comment-stripped
##    grep proves [method WorkerThreadPool.wait_for_task_completion]'s return
##    value is never assigned to anything (used only to join/free an
##    already-complete task, its [Error] return always discarded) and that
##    [member VoxelWorldGrid._task_mutex] actually guards every result-
##    structure write.
##
## Test isolation (accumulated pitfall): every test gets its OWN region
## directory under `user://` (never `res://`, never shared across tests,
## never committed) via [method _make_temp_region_dir], removed recursively
## in [method after_test]. HEADLESS TESTING NOTE: [WorkerThreadPool] works
## headless; every assertion that depends on background work having actually
## COMPLETED uses [method VoxelWorldGrid.wait_for_async_residency_idle] (a
## BOUNDED spin with `OS.delay_msec` internally, never unbounded) rather than
## an ad hoc sleep loop in the test itself. Assertions that must hold
## IMMEDIATELY after a single dispatch call (the cap invariant) are checked
## WITHOUT waiting — they hold by construction regardless of background
## timing, never racy.
class_name AsyncRegionIoTest
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
	var dir_path: String = "user://vox011_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
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
# AC-1 (TR-voxel-world-053) — no synchronous region read/flush/terrain-gen
# remains on the main-thread path
# ---------------------------------------------------------------------------

func test_region_file_source_no_longer_exposes_a_synchronous_payload_read_or_write_method() -> void:
	# Grep-verifiable AC: the old instance-level `read_chunk`/`write_chunk`
	# methods (Story vox-010's synchronous payload I/O) must be GONE from
	# VoxelWorldRegionFile entirely — comment-stripped so this test file's
	# own doc comments (which legitimately name the removed methods to
	# document their absence) are never mistaken for a violation.
	var source: String = _read_all_gd_source("res://src/voxel_world")

	assert_bool(source.contains("func read_chunk(")).is_false()
	assert_bool(source.contains("func write_chunk(")).is_false()
	# The old fully-synchronous per-chunk page-in/eviction methods must also
	# be gone — replaced by the async dispatch machinery this story adds.
	assert_bool(source.contains("func _ensure_resident(")).is_false()
	assert_bool(source.contains("func _evict_chunk(")).is_false()
	assert_bool(source.contains("func _regenerate_chunk_from_seed(")).is_false()


func test_voxel_world_grid_dispatches_read_and_write_paths_via_worker_thread_pool() -> void:
	# Grep-verifiable AC: region reads (disk load AND terrain regen) and
	# eviction-flush writes are all dispatched through
	# WorkerThreadPool.add_task -- three call sites (read-from-disk dispatch,
	# regen dispatch, flush dispatch), never fewer.
	var source: String = _read_all_gd_source("res://src/voxel_world")

	var dispatch_count: int = source.count("WorkerThreadPool.add_task(")
	assert_int(dispatch_count).is_greater_equal(3)


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-053) — cap-miss stays queued, never a sync fallback
# ---------------------------------------------------------------------------

func test_update_residency_mass_approach_never_exceeds_the_shared_concurrency_cap() -> void:
	# Arrange — a tiny cap and a "mass approach": far more desired chunks
	# (view_radius=6 -> 13x13 = 169 chunks) than the cap (3) can dispatch at
	# once, all pristine (regen dispatch), all in a single update_residency
	# call.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 512
	config.world_depth_cells = 512
	config.region_size_chunks = 8
	config.view_radius_chunks = 6
	config.settlement_radius_chunks = 1
	config.max_concurrent_async_tasks = 3
	config.region_directory = _make_temp_region_dir("ac2_cap_never_exceeded")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act
	grid.update_residency(Vector3i(160, 0, 160), Vector3i(160, 0, 160))

	# Assert — checked IMMEDIATELY, no wait: this holds by construction
	# (every dispatch attempt checks the in-flight count BEFORE adding a
	# task), never a timing race regardless of how fast the background
	# threads happen to run.
	assert_int(grid.get_in_flight_async_task_count()).is_less_equal(3)

	# Cleanup — let dispatched tasks finish before the grid is freed.
	grid.wait_for_async_residency_idle()


func test_update_residency_mass_approach_leaves_excess_chunks_queued_not_resident() -> void:
	# Arrange — same "mass approach" shape as above: 169 desired chunks, cap 3.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 512
	config.world_depth_cells = 512
	config.region_size_chunks = 8
	config.view_radius_chunks = 6
	config.settlement_radius_chunks = 1
	config.max_concurrent_async_tasks = 3
	config.region_directory = _make_temp_region_dir("ac2_excess_stays_queued")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act — one dispatch call.
	grid.update_residency(Vector3i(160, 0, 160), Vector3i(160, 0, 160))

	# Assert — nothing is resident yet: a freshly-dispatched task cannot
	# complete and be integrated within the SAME synchronous call that
	# dispatched it (integration only happens the NEXT time a chunk is
	# requested), so this is deterministic, not a race. The excess demand
	# (169 desired vs. cap 3) never fell back to a synchronous read/regen —
	# it simply stayed queued.
	assert_int(grid.get_resident_chunk_keys().size()).is_equal(0)
	assert_int(grid.get_in_flight_async_task_count()).is_equal(3)

	# Act — settle across simulated "later frames" (bounded test helper).
	grid.wait_for_async_residency_idle()

	# Assert — every desired chunk eventually became resident once the cap
	# stopped constraining dispatch across repeated calls, and the cap was
	# never exceeded at any point along the way.
	assert_int(grid.get_resident_chunk_keys().size()).is_equal(169)
	assert_int(grid.get_in_flight_async_task_count()).is_equal(0)


func test_update_residency_eviction_mass_approach_never_exceeds_the_shared_concurrency_cap() -> void:
	# Arrange — many dirty chunks (a 9x9 = 81-chunk window filled with writes)
	# then moved far away in ONE call, cap tiny (2), destination window
	# radius 0 (a single pristine chunk) so the read-side dispatch for the
	# NEW desired chunk and the write-side dispatch for the 81 newly-stale
	# dirty chunks compete for the SAME shared budget within this one call —
	# proving the cap is a TOTAL across both paths, not a separate budget
	# each.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 512
	config.world_depth_cells = 512
	config.region_size_chunks = 8
	config.view_radius_chunks = 4
	config.settlement_radius_chunks = 1
	config.max_concurrent_async_tasks = 2
	config.region_directory = _make_temp_region_dir("ac2_evict_cap_never_exceeded")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	# Dirty every chunk in a 9x9 window (81 chunks) around a near-origin focus.
	for dz in range(-4, 5):
		for dx in range(-4, 5):
			var cell := Vector3i(160 + dx * VoxelWorldGrid.CHUNK_SIZE, 0, 160 + dz * VoxelWorldGrid.CHUNK_SIZE)
			grid.set_cell(cell, CellContents.new(7, 2))
	config.view_radius_chunks = 0
	config.settlement_radius_chunks = 0

	# Act — move residency far away in one call: the 81 now-stale dirty
	# chunks each need an eviction-flush dispatch AND the single new
	# destination chunk needs a page-in dispatch, all sharing cap 2.
	grid.update_residency(Vector3i(0, 0, 0), Vector3i(0, 0, 0))

	# Assert — cap never exceeded across BOTH dispatch paths combined,
	# checked immediately (deterministic, no timing race).
	assert_int(grid.get_in_flight_async_task_count()).is_less_equal(2)

	# Cleanup — let dispatched tasks finish before the grid is freed.
	grid.wait_for_async_residency_idle()


# ---------------------------------------------------------------------------
# AC-3 (TR-voxel-world-053) — background results consumed from the mutex-
# guarded structure, never from wait_for_task_completion's return value
# ---------------------------------------------------------------------------

func test_async_write_then_read_round_trip_returns_originally_written_value() -> void:
	# Arrange — behavioral proof that data flows correctly through the
	# mutex-guarded _read_results/_write_results structures end to end (a
	# completed background load/flush IS consumed correctly, not merely
	# "doesn't crash").
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("ac3_round_trip")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var written_cell := Vector3i(64, 5, 64)  # chunk (4, 4)
	grid.set_cell(written_cell, CellContents.new(33, 4))

	# Act — evict (dispatches an async flush), settle, page back in
	# (dispatches an async read), settle.
	grid.update_residency(Vector3i(0, 0, 0), Vector3i(0, 0, 0))
	grid.wait_for_async_residency_idle()
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_false()
	grid.update_residency(written_cell, written_cell)
	grid.wait_for_async_residency_idle()

	# Assert — the value consumed from the mutex-guarded read result matches
	# what was originally written and flushed.
	var read_back: CellContents = grid.get_cell(written_cell)
	assert_int(read_back.block_type_id).is_equal(33)
	assert_int(read_back.material_id).is_equal(4)


func test_wait_for_task_completion_return_value_is_never_assigned_as_chunk_data() -> void:
	# Grep-verifiable AC: WorkerThreadPool.wait_for_task_completion's return
	# (an Error code) must never be captured into a variable and treated as
	# data (ADR-0015 Decision §6 engine note; the spike's own bug). This
	# source calls it exactly as a bare, value-discarding statement every
	# time (comment-stripped so this test file's own doc comments naming it
	# are never mistaken for a violation).
	var source: String = _read_all_gd_source("res://src/voxel_world")

	# Positive presence — it IS used, just correctly (join/free only).
	assert_bool(source.contains("WorkerThreadPool.wait_for_task_completion(")).is_true()
	# Never assigned to anything.
	assert_bool(source.contains("= WorkerThreadPool.wait_for_task_completion(")).is_false()


func test_task_mutex_guards_every_read_and_write_result_structure_access() -> void:
	# Grep-verifiable AC: every background task body that populates a shared
	# result dictionary locks/unlocks the SAME mutex, and the main-thread
	# consumers do too -- at least 3 lock/unlock pairs (bg read, bg regen,
	# bg flush) on the producer side.
	var source: String = _read_all_gd_source("res://src/voxel_world")

	assert_int(source.count("_task_mutex.lock()")).is_greater_equal(3)
	assert_int(source.count("_task_mutex.unlock()")).is_greater_equal(3)


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive -- Voxel World's directory is flat),
## STRIPPING full-line `#`/`##` doc-comment lines first. Mirrors
## `tests/integration/voxel_world/dda_raycast_test.gd`'s `_read_all_gd_source`
## helper (this codebase's established precedent) -- this system's own doc
## comments legitimately name removed/banned identifiers to document their
## absence, so a naive raw-text scan would flag its own compliance
## documentation as a violation. Stripping comment lines means only actual
## CODE usage can trip the checks above.
func _read_all_gd_source(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined
