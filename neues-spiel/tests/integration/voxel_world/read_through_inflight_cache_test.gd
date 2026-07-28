## Integration test — Voxel World story vox-013 (read-through in-flight-write
## cache, ADR-0015 Decision §3; TR-voxel-world-053).
##
## Proves, all against [VoxelWorldGrid.get_cell] / [VoxelWorldGrid.update_residency]
## (public API only — no private-member reads, matching this codebase's own
## established precedent in `region_file_residency_test.gd`/
## `async_region_io_test.gd`):
## 1. AC-1: once a dirty chunk's eviction flush has been DISPATCHED but not
##    yet REAPED (i.e. [method VoxelWorldGrid._reap_finished_async_writes] has
##    not run since — never called except from [method
##    VoxelWorldGrid.update_residency]/[method
##    VoxelWorldGrid.wait_for_async_residency_idle]), a re-need on that chunk
##    (`get_cell`) is served from the in-flight bytes: the correct value comes
##    back IMMEDIATELY (no async settle needed) and the shared in-flight task
##    count never grows — proving no region-file read was ever dispatched.
##    This is deterministic regardless of how fast the background flush
##    thread actually runs: [member VoxelWorldGrid._write_in_flight_data] is
##    only ever cleared by an explicit reap, which this test never triggers
##    between the eviction dispatch and the `get_cell` call.
## 2. AC-1 edge case (consistency, no torn read at the boundary): repeated
##    `get_cell` calls against the still-outstanding flush all resolve to the
##    identical correct value — there is no partial/half-integrated state to
##    observe, since [method VoxelWorldGrid._try_serve_from_in_flight_write]
##    either fully resolves or does nothing (no lock needed, matching this
##    codebase's [method VoxelWorldGrid.iterate_occupied] "torn-read-free by
##    construction" precedent).
## 3. AC-2: once the flush actually settles (durable + reaped, via [method
##    VoxelWorldGrid.wait_for_async_residency_idle]), a BRAND-NEW grid
##    instance pointed at the SAME region directory — which has no in-flight
##    cache of its own at all, by construction — reads back the identical
##    value. Since a fresh instance cannot possibly be served from ANY
##    in-memory carry-over, this proves the flushed bytes genuinely landed on
##    disk, matching Story vox-013's own AC-2 text ("a later page-in reads
##    from the region file, matching the flushed bytes").
## 4. Grep-verifiable structural backing: [method VoxelWorldGrid._request_resident]'s
##    body references [member VoxelWorldGrid._write_in_flight_data] — the
##    textual proof the read-through check actually sits in the page-in path,
##    backing the behavioral tests above (Control Manifest's own
##    grep-verifiable-check precedent).
##
## Test isolation (accumulated pitfall): every test gets its OWN region
## directory under `user://` (never `res://`, never shared across tests,
## never committed) via [method _make_temp_region_dir], removed recursively in
## [method after_test]. Every grid is settled via [method
## VoxelWorldGrid.wait_for_async_residency_idle] before the test ends
## (belt-and-suspenders alongside [method VoxelWorldGrid._notification]'s own
## PREDELETE safety net), except where a test's own assertions REQUIRE the
## flush to remain deliberately un-settled — those tests settle at the very
## end, after every un-settled assertion has already run.
class_name ReadThroughInflightCacheTest
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
	var dir_path: String = "user://vox013_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
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
# AC-1 (TR-voxel-world-053) — served from the in-flight cache, no region read
# ---------------------------------------------------------------------------

func test_get_cell_serves_in_flight_bytes_while_flush_outstanding_and_dispatches_no_region_read() -> void:
	# Arrange — a dirty chunk, then an eviction dispatched toward an
	# out-of-world focus so the desired set is EMPTY (nothing else gets
	# dispatched in the same call — the only in-flight task after this is the
	# one eviction-flush).
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("ac1_serve_in_flight")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var written_cell := Vector3i(64, 2, 64)  # chunk (4, 4)
	grid.set_cell(written_cell, CellContents.new(42, 7))

	# Act — evict (dispatches the flush; the resident copy is dropped
	# immediately and its bytes now live in the in-flight cache). Deliberately
	# NEVER call update_residency/wait_for_async_residency_idle again before
	# the read below — those are the ONLY two call sites that ever reap a
	# finished flush, so the in-flight entry is guaranteed to still be present
	# regardless of how fast the background write thread actually completes.
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_false()  # dropped the instant the flush was dispatched
	var in_flight_count_before_read: int = grid.get_in_flight_async_task_count()
	assert_int(in_flight_count_before_read).is_equal(1)  # exactly the one flush task; empty desired set dispatched nothing else

	# Act — the re-need. No settle call precedes this.
	var read_back: CellContents = grid.get_cell(written_cell)

	# Assert — served correctly, IMMEDIATELY (no async wait needed at all —
	# the read-through cache resolves synchronously), and re-hydrated into
	# the resident set directly from the in-flight bytes.
	assert_int(read_back.block_type_id).is_equal(42)
	assert_int(read_back.material_id).is_equal(7)
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_true()

	# Assert — no NEW region-file read was ever dispatched: the shared
	# in-flight task count is UNCHANGED by the get_cell call above. If the
	# read-through cache were absent (the story's own documented prior gap),
	# get_cell would instead have dispatched a fresh background read
	# (incrementing this count) and returned an EMPTY result for now (a
	# freshly-dispatched task cannot complete within the same synchronous
	# call that dispatched it) — the exact regression this assertion guards
	# against.
	assert_int(grid.get_in_flight_async_task_count()).is_equal(in_flight_count_before_read)

	# Cleanup — let the still-outstanding flush settle before the grid frees.
	grid.wait_for_async_residency_idle()


func test_get_cell_repeated_calls_while_flush_outstanding_stay_consistent() -> void:
	# Arrange — same shape as above: a dirty chunk, evicted toward an
	# out-of-world focus so nothing else gets dispatched.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("ac1_edge_repeated_reads")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var written_cell := Vector3i(32, 3, 32)  # chunk (2, 2)
	grid.set_cell(written_cell, CellContents.new(19, 5))
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))
	assert_bool(grid.is_chunk_resident(Vector2i(2, 2))).is_false()

	# Act + Assert — repeated re-needs against the SAME still-outstanding
	# flush (no reap call anywhere in this loop) must all resolve to the
	# identical correct value — no torn/half-integrated state ever observable
	# at any point along the way.
	for i in 20:
		var read_back: CellContents = grid.get_cell(written_cell)
		assert_int(read_back.block_type_id).is_equal(19)
		assert_int(read_back.material_id).is_equal(5)

	# Cleanup
	grid.wait_for_async_residency_idle()


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-053) — after settle, reads resume from the region file
# ---------------------------------------------------------------------------

func test_get_cell_after_flush_settles_reads_correct_value_from_region_file_on_a_fresh_grid_instance() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("ac2_resumes_from_disk")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var written_cell := Vector3i(48, 4, 48)  # chunk (3, 3)
	grid.set_cell(written_cell, CellContents.new(21, 6))

	# Act — evict and let the flush FULLY settle: durable on disk AND reaped
	# (the in-flight entry cleared).
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))
	grid.wait_for_async_residency_idle()

	# Act — a BRAND-NEW grid instance pointed at the SAME region directory has
	# no in-flight cache of its own at all (a fresh, empty
	# _write_in_flight_data by construction) — any correct value it serves
	# MUST come from the region file on disk, never from any in-memory
	# carry-over, proving the flush genuinely landed durably.
	var config2 := VoxelWorldConfig.new()
	config2.world_width_cells = config.world_width_cells
	config2.world_depth_cells = config.world_depth_cells
	config2.region_size_chunks = config.region_size_chunks
	config2.view_radius_chunks = config.view_radius_chunks
	config2.settlement_radius_chunks = config.settlement_radius_chunks
	config2.region_directory = config.region_directory
	var grid2: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid2.config = config2
	grid2.update_residency(written_cell, written_cell)
	grid2.wait_for_async_residency_idle()

	# Assert
	var read_back: CellContents = grid2.get_cell(written_cell)
	assert_int(read_back.block_type_id).is_equal(21)
	assert_int(read_back.material_id).is_equal(6)


# ---------------------------------------------------------------------------
# Structural backing — the read-through check sits in the page-in path
# ---------------------------------------------------------------------------

func test_request_resident_body_checks_write_in_flight_cache() -> void:
	# Grep-verifiable AC (ADR-0015 Decision §3, Control Manifest Forbidden:
	# "never re-read an evicting dirty chunk from its region file before its
	# flush completes"): _request_resident's own body must reference
	# _write_in_flight_data — the textual proof the read-through check
	# actually sits in the page-in path, backing the behavioral tests above.
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")
	var start: int = source.find("func _request_resident(")
	assert_int(start).is_greater(-1)
	var next_func: int = source.find("\nfunc ", start + 1)
	assert_int(next_func).is_greater(-1)
	var body: String = source.substr(start, next_func - start)

	assert_bool(body.contains("_write_in_flight_data")).is_true()
