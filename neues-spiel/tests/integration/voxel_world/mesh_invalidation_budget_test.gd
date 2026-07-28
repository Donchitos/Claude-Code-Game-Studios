## Integration test -- Voxel World story vox-020 (mesh invalidation: dirty-set
## marking, budgeted rebuild-first drain, and [signal
## VoxelWorldGrid.chunk_became_resident]; TD ruling
## `production/architecture-decisions-m02-preflight-2026-07-26.md` Addendum D
## / D7; ADR-0014 amendment Decision Section 2/3, ADR-0015 amendment;
## TR-voxel-world-025/053/023).
##
## Proves, against the REAL production [VoxelWorldMesher] / [VoxelWorldGrid] /
## [VoxelWorldMeshStreamer] (never a reimplementation):
## 1. AC-DIRTY-NOT-REBUILD: a [method VoxelWorldGrid.bulk_write] spanning N
##    tracked chunks performs ZERO [method VoxelWorldMesher.build_chunk] calls
##    during signal dispatch and leaves exactly N dirty keys.
## 2. AC-BUDGETED-DRAIN: at the shipped [member
##    VoxelWorldConfig.mesh_build_budget_ms] (4.0 -- simulated via a
##    deterministic fake clock at a per-item cost that alone dwarfs it, the
##    same 7.7 ms/chunk-vs-4.0 ms-budget shape vox-019 measured for real),
##    given BOTH a dirty tracked chunk AND a newly-desired chunk, ONE
##    `_sync_window` call performs AT MOST ONE meshing operation total
##    (rebuild XOR build, never both) -- proving the combined-list, single
##    shared-timestamp mechanism, not two independent progress guarantees.
##    Also a grep guard: no new rebuild-budget knob exists in
##    `voxel_world_config.gd`.
## 3. AC-REBUILD-FIRST: an instrumented [VoxelWorldMesher] subclass's ordered
##    call log proves a dirty chunk's rebuild precedes any new-chunk build,
##    which precedes any unload, all in the SAME `_sync_window` call.
## 4. AC-UNLOAD-CLEARS-DIRTY: [method VoxelWorldMesher.unload_chunk] erases
##    the dirty entry; re-entering the chunk later produces a mesh identical
##    to one built fresh from current grid state -- no stale key survives.
## 5. AC-UNTRACKED-NO-BOOKKEEPING: a write to an untracked chunk's cell leaves
##    the dirty set's size and contents unchanged.
## 6. AC-SEAM-NEIGHBOUR (regression pin, `_chunk_keys_touched_by` UNCHANGED):
##    a seam write marks BOTH the owning chunk and its cross-chunk X neighbor
##    dirty, and the neighbor's rebuilt geometry actually differs (not merely
##    marked) from its pre-write geometry; an interior write marks exactly one
##    key.
## 7. AC-PAGEIN-SIGNAL: [signal VoxelWorldGrid.chunk_became_resident] fires
##    exactly once per residency integration -- both at [method
##    VoxelWorldGrid._integrate_one_finished_read] (fresh async page-in) and
##    [method VoxelWorldGrid._try_serve_from_in_flight_write] (re-need while a
##    flush is outstanding) -- marks a tracked chunk dirty, and one budgeted
##    `_sync_window`/`update_view_window` call produces correct geometry for a
##    chunk that was meshed while non-resident. Never fires on eviction.
## 8. AC-NO-STREAMER-SUBSCRIPTION (grep guard): `voxel_world_mesh_streamer.gd`
##    contains zero `cell_changed`/`cells_changed_batch`/
##    `chunk_became_resident` occurrences at all -- the streamer subscribes to
##    no grid signal.
## 9. AC-BOOT-UNBOUNDED: [method VoxelWorldMeshStreamer.build_initial_window]
##    gives the rebuild phase the SAME unbounded contract as the build phase,
##    proven under a crushing simulated per-item cost; the dirty set is empty
##    at boot.
##
## Determinism (QA rule: no time-dependent assertions): every budget
## assertion here is against ITEM COUNTS / mesh-content resulting from a
## deterministic fake clock ([method
## VoxelWorldMeshStreamer.set_time_source_for_test]) or from the terrain
## formula's own unconditional floor-clamp (`y = min_y` is ALWAYS solid by
## construction, [method VoxelWorldGrid._pure_terrain_height]'s `clampi`) --
## never against measured real elapsed time or noise-dependent terrain shape.
##
## Test isolation (accumulated pitfall, matching `completion_driven_drain_test.gd`
## / `read_through_inflight_cache_test.gd`): every residency-active test gets
## its OWN region directory under `user://`, removed recursively in [method
## after_test]. Every residency-active grid is settled via [method
## VoxelWorldGrid.wait_for_async_residency_idle] before the test ends.
class_name MeshInvalidationBudgetTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Inner helpers (above all test functions, per this codebase's own convention)
# ---------------------------------------------------------------------------

## Test-local deterministic fake clock (not a production class) -- matches
## `mesh_view_window_streaming_test.gd`'s identical helper. Advances by a
## fixed [member step_usec] EVERY call regardless of real wall-clock time.
class _FakeClock:
	var value: int = 0
	var step_usec: int = 0

	func tick() -> int:
		value += step_usec
		return value


## Test-local instrumented [VoxelWorldMesher] subclass (not a production
## class) -- records every [method build_chunk]/[method unload_chunk] call,
## in order, into [member call_log], and counts [method build_chunk] calls
## separately in [member build_call_count]. Used ONLY to prove call
## count/ordering; every other behavior is the REAL, unmodified base class
## (`super.*` delegates immediately).
class _InstrumentedMesher extends VoxelWorldMesher:
	var call_log: Array[String] = []
	var build_call_count: int = 0

	func build_chunk(chunk_coord: Vector2i) -> void:
		build_call_count += 1
		call_log.append("build:%s" % str(chunk_coord))
		super.build_chunk(chunk_coord)

	func unload_chunk(chunk_coord: Vector2i) -> void:
		call_log.append("unload:%s" % str(chunk_coord))
		super.unload_chunk(chunk_coord)


func _make_grid(world_size: int = 512) -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = world_size
	config.world_depth_cells = world_size
	grid.config = config
	return grid


func _make_mesher(grid: VoxelWorldGrid) -> VoxelWorldMesher:
	var mesher: VoxelWorldMesher = auto_free(VoxelWorldMesher.new())
	mesher.grid = grid
	# Story vox-023: VoxelWorldMesher.setup() now asserts appearance is wired
	# (AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL) -- a fresh, valid config satisfies
	# that assert without affecting this file's own dirty-set assertions.
	mesher.appearance = BlockAppearanceConfig.new()
	mesher.setup()
	return mesher


func _make_instrumented_mesher(grid: VoxelWorldGrid) -> _InstrumentedMesher:
	var mesher: _InstrumentedMesher = auto_free(_InstrumentedMesher.new())
	mesher.grid = grid
	mesher.appearance = BlockAppearanceConfig.new()
	mesher.setup()
	return mesher


func _make_streamer(grid: VoxelWorldGrid, mesher: VoxelWorldMesher) -> VoxelWorldMeshStreamer:
	var streamer: VoxelWorldMeshStreamer = auto_free(VoxelWorldMeshStreamer.new())
	streamer.grid = grid
	streamer.mesher = mesher
	streamer.setup()
	return streamer


func _log_index(log: Array[String], entry: String) -> int:
	for i in log.size():
		if log[i] == entry:
			return i
	return -1


# ---------------------------------------------------------------------------
# Test isolation -- per-test temp region directories, cleaned up after each test
# ---------------------------------------------------------------------------

var _created_region_dirs: Array[String] = []


func after_test() -> void:
	for dir_path: String in _created_region_dirs:
		_remove_dir_recursive(dir_path)
	_created_region_dirs.clear()


func _make_temp_region_dir(suffix: String) -> String:
	var dir_path: String = "user://vox020_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
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
# AC-DIRTY-NOT-REBUILD (TR-voxel-world-025)
# ---------------------------------------------------------------------------

func test_bulk_write_across_n_tracked_chunks_performs_zero_build_calls_and_leaves_n_dirty() -> void:
	# Arrange -- 3 tracked chunks (CHUNK_SIZE=16 -> x=0,16,32 land in chunks
	# (0,0),(1,0),(2,0)).
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: _InstrumentedMesher = _make_instrumented_mesher(grid)
	mesher.build_chunk(Vector2i(0, 0))
	mesher.build_chunk(Vector2i(1, 0))
	mesher.build_chunk(Vector2i(2, 0))
	mesher.build_call_count = 0  # reset -- only the bulk_write dispatch below is under test

	# Act -- a single bulk_write touching all 3 tracked chunks.
	var changes: Dictionary[Vector3i, CellContents] = {
		Vector3i(0, 0, 0): CellContents.new(1, 0),
		Vector3i(16, 0, 0): CellContents.new(1, 0),
		Vector3i(32, 0, 0): CellContents.new(1, 0),
	}
	grid.bulk_write(changes)

	# Assert -- ZERO build_chunk calls during dispatch (the ~69 ms 9-chunk
	# frame-spike defect ceases to exist as a code path); exactly 3 dirty keys.
	assert_int(mesher.build_call_count).is_equal(0)
	var dirty: Array[Vector2i] = mesher.get_dirty_chunk_keys()
	assert_int(dirty.size()).is_equal(3)
	assert_array(dirty).contains([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])


# ---------------------------------------------------------------------------
# AC-BUDGETED-DRAIN (TR-voxel-world-023/025)
# ---------------------------------------------------------------------------

func test_sync_window_performs_at_most_one_meshing_operation_when_both_dirty_and_new_desired_exist() -> void:
	# Arrange -- the shipped default mesh_build_budget_ms (4.0), and a fake
	# clock whose simulated per-item cost (5 ms) alone dwarfs it -- the same
	# shape vox-019 measured for real (~7.7 ms/chunk vs a 4.0 ms budget).
	var grid: VoxelWorldGrid = _make_grid(512)
	grid.config.view_radius_chunks = 1  # 3x3 = 9 desired
	assert_float(grid.config.mesh_build_budget_ms).is_equal(4.0)  # shipped default, unchanged by this story
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var focus := Vector3i(256, 0, 256)
	var center_key: Vector2i = grid.chunk_key_for_cell(focus)

	# One tracked, dirty chunk (the player's own edit) -- and 8 more desired
	# chunks in the same window that are NOT yet tracked (new-chunk builds).
	mesher.build_chunk(center_key)
	grid.set_cell(focus, CellContents.new(1, 0))
	assert_array(mesher.get_dirty_chunk_keys()).contains([center_key])

	var clock := _FakeClock.new()
	clock.step_usec = 5000  # 5 ms/item -- alone exceeds the 4.0 ms budget
	streamer.set_time_source_for_test(Callable(clock, "tick"))

	# Act -- ONE call.
	streamer.update_view_window(focus)

	# Assert -- AT MOST ONE meshing operation total: either the dirty chunk got
	# rebuilt (cleared) XOR exactly one new chunk got built -- never both, and
	# never neither (the progress guarantee still fires once).
	var still_dirty: bool = mesher.get_dirty_chunk_keys().has(center_key)
	var new_tracked_count: int = mesher.get_tracked_chunk_keys().size() - 1  # minus the pre-existing center
	var total_processed: int = (0 if still_dirty else 1) + new_tracked_count
	assert_int(total_processed).is_equal(1)


func test_no_new_rebuild_budget_knob_exists_in_voxel_world_config() -> void:
	# Grep guard (AC-BUDGETED-DRAIN's own binding rationale: an independent
	# rebuild budget would regress vox-019's measured p95 -- see this story's
	# doc comments in voxel_world_mesh_streamer.gd for the full rationale).
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_config.gd")
	assert_bool(source.to_lower().contains("rebuild_budget")).is_false()


# ---------------------------------------------------------------------------
# AC-REBUILD-FIRST
# ---------------------------------------------------------------------------

func test_rebuild_precedes_new_build_precedes_unload_in_ordered_call_log() -> void:
	# Arrange -- track a 3x3 window at focus_a, dirty its center chunk.
	var grid: VoxelWorldGrid = _make_grid(2048)
	grid.config.view_radius_chunks = 1  # 3x3 = 9
	grid.config.boot_mesh_radius_chunks = 1  # Story vox-021: build_initial_window now reads THIS, not view_radius_chunks -- match it so this pre-vox-021 test's own 3x3 scenario is unaffected
	var mesher: _InstrumentedMesher = _make_instrumented_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)
	var focus_a := Vector3i(160, 0, 160)  # chunk (10, 10)
	streamer.build_initial_window(focus_a)
	var center_a: Vector2i = grid.chunk_key_for_cell(focus_a)
	grid.set_cell(focus_a, CellContents.new(1, 0))
	assert_array(mesher.get_dirty_chunk_keys()).contains([center_a])
	mesher.call_log.clear()  # isolate the call log to the ACT call below

	# Act -- move far away (focus_a's whole window, including the dirty center,
	# leaves the desired set -- forcing an unload -- while a brand-new window
	# needs building), under a fake clock with a tiny per-item step so a
	# generous budget deterministically fits every item (no real-timing
	# reliance, per the QA determinism rule).
	var clock := _FakeClock.new()
	clock.step_usec = 1  # negligible -- the 4.0 ms default budget fits all ~19 items easily
	streamer.set_time_source_for_test(Callable(clock, "tick"))
	var focus_b := Vector3i(1600, 0, 1600)  # chunk (100, 100) -- far from A's window
	streamer.update_view_window(focus_b)

	# Assert -- the rebuild of center_a precedes EVERY new-chunk build, which
	# precedes EVERY unload, all in this ONE call's log.
	var rebuild_entry: String = "build:%s" % str(center_a)
	var rebuild_index: int = _log_index(mesher.call_log, rebuild_entry)
	assert_int(rebuild_index).is_greater_equal(0)

	var last_build_index: int = -1
	for i in mesher.call_log.size():
		var log_entry: String = mesher.call_log[i]
		if log_entry.begins_with("build:"):
			last_build_index = i
			if log_entry != rebuild_entry:
				assert_int(i).is_greater(rebuild_index)
	for i in mesher.call_log.size():
		if mesher.call_log[i].begins_with("unload:"):
			assert_int(i).is_greater(last_build_index)

	assert_array(mesher.call_log).contains(["unload:%s" % str(center_a)])
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()


# ---------------------------------------------------------------------------
# AC-UNLOAD-CLEARS-DIRTY
# ---------------------------------------------------------------------------

func test_unload_clears_dirty_and_reentry_matches_fresh_build() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var key := Vector2i(0, 0)
	mesher.build_chunk(key)
	grid.set_cell(Vector3i(5, 5, 5), CellContents.new(1, 0))
	assert_array(mesher.get_dirty_chunk_keys()).contains([key])

	# Act -- unload.
	mesher.unload_chunk(key)

	# Assert -- dirty entry erased along with tracking; no bookkeeping built.
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()
	assert_bool(mesher.is_chunk_tracked(key)).is_false()

	# Act -- re-enter via the window (a later build_chunk call, matching what
	# VoxelWorldMeshStreamer does when a chunk re-enters).
	mesher.build_chunk(key)

	# Assert -- the resulting mesh matches a chunk built fresh from current
	# grid state (24 verts -- the established isolated-solid-cell fixture from
	# `chunked_mesher_face_culling_test.gd`), and the dirty set never held a
	# stale key.
	var mesh: ArrayMesh = mesher.get_chunk_mesh_instance(key).mesh
	assert_object(mesh).is_not_null()
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_int(verts.size()).is_equal(24)
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()


# ---------------------------------------------------------------------------
# AC-UNTRACKED-NO-BOOKKEEPING
# ---------------------------------------------------------------------------

func test_write_to_untracked_chunk_leaves_dirty_set_unchanged() -> void:
	# Arrange -- track an UNRELATED chunk so the dirty set's baseline is
	# established as empty, not merely "never initialized".
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	mesher.build_chunk(Vector2i(0, 0))
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()

	# Act -- write into chunk (5,5) (CHUNK_SIZE=16 -> cell x=80), never tracked.
	grid.set_cell(Vector3i(80, 0, 80), CellContents.new(1, 0))

	# Assert -- dirty set unchanged in size AND content.
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()
	assert_bool(mesher.is_chunk_tracked(Vector2i(5, 5))).is_false()


# ---------------------------------------------------------------------------
# AC-SEAM-NEIGHBOUR (regression pin -- _chunk_keys_touched_by UNCHANGED)
# ---------------------------------------------------------------------------

func test_seam_write_marks_both_chunks_dirty_and_interior_write_marks_exactly_one() -> void:
	# Arrange -- two ADJACENT tracked chunks, CHUNK_SIZE=16: chunk (0,0) covers
	# local x 0..15, chunk (1,0) covers x 16..31.
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	mesher.build_chunk(Vector2i(0, 0))
	mesher.build_chunk(Vector2i(1, 0))
	# A solid cell just inside chunk (1,0)'s border (x=16).
	grid.set_cell(Vector3i(16, 0, 0), CellContents.new(1, 0))
	mesher.build_chunk(Vector2i(1, 0))
	mesher.clear_dirty(Vector2i(1, 0))
	var pre_write_verts: PackedVector3Array = mesher.get_chunk_mesh_instance(Vector2i(1, 0)).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_int(pre_write_verts.size()).is_equal(24)  # isolated so far -- x=15 still empty

	# Act -- write chunk (0,0)'s outer edge cell at x=15 (the X seam).
	grid.set_cell(Vector3i(15, 0, 0), CellContents.new(1, 0))

	# Assert -- BOTH the owning chunk (0,0) AND the seam neighbor (1,0) dirty.
	var seam_dirty: Array[Vector2i] = mesher.get_dirty_chunk_keys()
	assert_int(seam_dirty.size()).is_equal(2)
	assert_array(seam_dirty).contains([Vector2i(0, 0), Vector2i(1, 0)])

	# Drain both and prove the seam neighbor's geometry actually re-resolved
	# (not merely marked) -- its shared +X/-X face is now culled: 24 -> 20 verts.
	mesher.build_chunk(Vector2i(0, 0))
	mesher.clear_dirty(Vector2i(0, 0))
	mesher.build_chunk(Vector2i(1, 0))
	mesher.clear_dirty(Vector2i(1, 0))
	var post_write_verts: PackedVector3Array = mesher.get_chunk_mesh_instance(Vector2i(1, 0)).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_int(post_write_verts.size()).is_equal(20)
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()

	# Act -- an INTERIOR write (not on any chunk edge) marks exactly ONE key.
	grid.set_cell(Vector3i(5, 5, 5), CellContents.new(1, 0))
	var interior_dirty: Array[Vector2i] = mesher.get_dirty_chunk_keys()
	assert_int(interior_dirty.size()).is_equal(1)
	assert_array(interior_dirty).contains([Vector2i(0, 0)])


# ---------------------------------------------------------------------------
# AC-PAGEIN-SIGNAL (TR-voxel-world-053)
# ---------------------------------------------------------------------------

func test_fresh_pagein_via_completion_driven_read_fires_signal_once_marks_dirty_and_sync_window_produces_geometry() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 0
	config.settlement_radius_chunks = 0
	config.region_directory = _make_temp_region_dir("pagein_read")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)

	# y = min_y (0) is ALWAYS solid by construction -- VoxelWorldGrid.
	# _pure_terrain_height clamps its result to >= min_y, so the generated
	# height is never below min_y regardless of noise -- deterministic, not
	# terrain-shape-dependent.
	var probe_cell := Vector3i(64, 0, 64)  # chunk (4, 4)
	var probe_key: Vector2i = grid.chunk_key_for_cell(probe_cell)

	var resident_events: Array[Vector2i] = []
	grid.chunk_became_resident.connect(func(key: Vector2i) -> void: resident_events.append(key))

	# Track the chunk BEFORE its data is resident -- meshed while non-resident
	# (mesh null), exactly this AC's precondition.
	mesher.build_chunk(probe_key)
	assert_object(mesher.get_chunk_mesh_instance(probe_key).mesh).is_null()
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()

	# Act -- dispatch the async page-in (view_radius_chunks=0/settlement_
	# radius_chunks=0 -- exactly ONE desired chunk, probe_key itself) and let
	# it settle.
	grid.update_residency(probe_cell, probe_cell)
	grid.wait_for_async_residency_idle()

	# Assert -- fired exactly once, and the tracked chunk is now dirty.
	assert_int(resident_events.size()).is_equal(1)
	assert_array(resident_events).contains([probe_key])
	assert_array(mesher.get_dirty_chunk_keys()).contains([probe_key])

	# Act -- ONE budgeted _sync_window call.
	streamer.update_view_window(probe_cell)

	# Assert -- the permanent-hole class is closed: correct, non-null geometry
	# now that real data has landed.
	var mesh_after: ArrayMesh = mesher.get_chunk_mesh_instance(probe_key).mesh
	assert_object(mesh_after).is_not_null()
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()


func test_pagein_via_in_flight_write_cache_fires_once_and_eviction_itself_never_fires() -> void:
	# Arrange -- matches read_through_inflight_cache_test.gd's own established
	# shape.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("pagein_inflight_write")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	var written_cell := Vector3i(64, 2, 64)  # chunk (4, 4)
	var chunk_key: Vector2i = grid.chunk_key_for_cell(written_cell)
	grid.set_cell(written_cell, CellContents.new(42, 7))
	mesher.build_chunk(chunk_key)
	mesher.clear_dirty(chunk_key)

	var resident_events: Array[Vector2i] = []
	grid.chunk_became_resident.connect(func(key: Vector2i) -> void: resident_events.append(key))

	# Act -- evict toward an out-of-world focus (dispatches the flush; the
	# resident copy drops immediately; the desired set is empty so nothing
	# else dispatches).
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))

	# Assert -- eviction itself NEVER fires the signal.
	assert_bool(grid.is_chunk_resident(chunk_key)).is_false()
	assert_int(resident_events.size()).is_equal(0)
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()

	# Act -- re-need it. No settle call precedes this -- served from the
	# in-flight-write cache ([method VoxelWorldGrid._try_serve_from_in_flight_write]),
	# the OTHER emit site.
	var read_back: CellContents = grid.get_cell(written_cell)
	assert_int(read_back.block_type_id).is_equal(42)

	# Assert -- fired exactly once, and the tracked chunk is dirty again.
	assert_int(resident_events.size()).is_equal(1)
	assert_array(resident_events).contains([chunk_key])
	assert_array(mesher.get_dirty_chunk_keys()).contains([chunk_key])

	grid.wait_for_async_residency_idle()  # settle the still-outstanding flush before the grid frees


# ---------------------------------------------------------------------------
# AC-NO-STREAMER-SUBSCRIPTION (grep guard)
# ---------------------------------------------------------------------------

func test_streamer_subscribes_to_no_grid_signal() -> void:
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_mesh_streamer.gd")
	assert_bool(source.contains("cell_changed")).is_false()
	assert_bool(source.contains("cells_changed_batch")).is_false()
	assert_bool(source.contains("chunk_became_resident")).is_false()


# ---------------------------------------------------------------------------
# AC-BOOT-UNBOUNDED
# ---------------------------------------------------------------------------

func test_build_initial_window_rebuild_phase_also_unbounded_and_dirty_set_empty_at_boot() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid(1024)
	grid.config.view_radius_chunks = 1  # 3x3 = 9
	grid.config.boot_mesh_radius_chunks = 1  # Story vox-021: build_initial_window now reads THIS, not view_radius_chunks -- match it so this pre-vox-021 test's own 3x3 scenario is unaffected
	grid.config.mesh_build_budget_ms = 4.0
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var streamer: VoxelWorldMeshStreamer = _make_streamer(grid, mesher)

	# Dirty set is empty at boot -- nothing has been marked dirty yet.
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()

	var chunk_size: int = VoxelWorldGrid.CHUNK_SIZE
	var focus_a := Vector3i(16 * chunk_size, 0, 16 * chunk_size)  # window: chunks x/z 15..17
	streamer.build_initial_window(focus_a)
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(9)

	# Dirty every one of the 9 tracked chunks (write each one's own origin cell).
	for key: Vector2i in mesher.get_tracked_chunk_keys():
		grid.set_cell(Vector3i(key.x * chunk_size, 0, key.y * chunk_size), CellContents.new(1, 0))
	assert_int(mesher.get_dirty_chunk_keys().size()).is_equal(9)

	# Move to a PARTIALLY overlapping window: chunks x 17..19, z 15..17 --
	# overlap = {(17,15),(17,16),(17,17)} stay tracked+dirty (must be
	# REBUILT, never unloaded); (18/19,*) are new (must be BUILT);
	# (15/16,*) leave the window (unloaded -- NOT the mechanism under test,
	# since unload_chunk clears dirty on its own).
	var focus_b := Vector3i(18 * chunk_size, 0, 16 * chunk_size)
	var clock := _FakeClock.new()
	clock.step_usec = 100000  # 100 ms/item -- dwarfs the 4.0 ms budget many times over
	streamer.set_time_source_for_test(Callable(clock, "tick"))
	streamer.build_initial_window(focus_b)

	# Assert -- the whole combined rebuild+build list processed regardless of
	# the crushing simulated per-item cost (UNBOUNDED, matching the pre-
	# existing build-only boot contract): the 3 overlap chunks were actually
	# REBUILT (their just-written solid cell is now visible -- a chunk merely
	# marked dirty but never rebuilt would still show its STALE null mesh from
	# focus_a's own pre-write initial build).
	for z in range(15, 18):
		var overlap_key := Vector2i(17, z)
		assert_bool(mesher.is_chunk_tracked(overlap_key)).is_true()
		assert_object(mesher.get_chunk_mesh_instance(overlap_key).mesh).is_not_null()
	# All 6 new chunks built too.
	for x in range(18, 20):
		for z in range(15, 18):
			assert_bool(mesher.is_chunk_tracked(Vector2i(x, z))).is_true()
	# Dirty set fully drained.
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()
