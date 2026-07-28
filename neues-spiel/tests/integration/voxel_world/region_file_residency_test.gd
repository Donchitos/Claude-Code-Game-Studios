## Integration test — Voxel World story vox-010 (region-file format + paged
## residency working set, ADR-0015 Decision §1/§2/§5/§6; TR-voxel-world-053/
## 041/021).
##
## Proves, all against [VoxelWorldGrid.update_residency] / [VoxelWorldGrid.get_cell]
## / [VoxelWorldRegionFile]:
## 1. AC-1 (TR-voxel-world-053): the resident working set is EXACTLY camera-
##    near [member VoxelWorldConfig.view_radius_chunks] union active-
##    settlement [member VoxelWorldConfig.settlement_radius_chunks] chunks —
##    a chunk outside both windows is evicted, even one written before
##    residency was ever engaged; overlapping windows count each chunk once;
##    resident chunk COUNT stays tiny on a large (2048-cell) world, proving
##    memory is bounded by footprint, not world size.
## 2. AC-2 (TR-voxel-world-041): a chunk written, evicted (flushed to its
##    region file), then re-approached round-trips losslessly through
##    [method VoxelWorldGrid.get_cell] — both via [method
##    VoxelWorldGrid.update_residency]'s own bulk page-in, and via a bare
##    [method VoxelWorldGrid.get_cell] call with no intervening
##    [method VoxelWorldGrid.update_residency] call (the accessor's OWN
##    transparent page-in). A never-touched (pristine) chunk pages in via
##    deterministic terrain regeneration from the seed (ADR-0015 Decision
##    §5) and, if evicted again without any write, creates NO region file at
##    all — "a region that never has a dirty chunk never gets a file on disk"
##    (Decision §5).
## 3. AC-3 (TR-voxel-world-053): per-region header I/O happens EXACTLY once
##    for a region touched repeatedly across many separate
##    [method VoxelWorldGrid.update_residency] calls (evict/page-in cycles),
##    never once per touch.
##
## Test isolation (accumulated pitfall): every test gets its OWN region
## directory under `user://` (never `res://`, never shared across tests,
## never committed) via [method _make_temp_region_dir], removed recursively
## in [method after_test].
##
## Story vox-011 ADAPTATION (ADR-0015 Decision §6): page-in/eviction is now
## dispatched on a [WorkerThreadPool] instead of running synchronously within
## a single [method VoxelWorldGrid.update_residency]/[method
## VoxelWorldGrid.get_cell] call -- exactly what this story's own doc
## comments forward-declared ("moving it onto a WorkerThreadPool is Story
## 011's explicit scope"). Every assertion below that depends on a page-in or
## eviction-flush having ACTUALLY completed (not merely been requested) now
## calls [method VoxelWorldGrid.wait_for_async_residency_idle] first -- a
## bounded, test-only settle helper (see that method's doc comment) that
## makes the otherwise multi-frame async settle deterministic in one call.
## The CORRECTNESS this file proves is unchanged; only the synchronous-same-
## call TIMING assumption is adapted to the async model.
class_name RegionFileResidencyTest
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
	var dir_path: String = "user://vox010_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
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
# AC-1 (TR-voxel-world-053) — resident set is exactly camera-near union
# settlement chunks; distant chunks (even previously-written ones) evicted
# ---------------------------------------------------------------------------

func test_update_residency_resident_set_is_exactly_camera_window_union_settlement_window() -> void:
	# Arrange — world larger than one region (32x32 chunks vs 8x8 regions).
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 512
	config.world_depth_cells = 512
	config.region_size_chunks = 8
	config.view_radius_chunks = 2
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("ac1_union")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var camera_focus := Vector3i(160, 0, 160)      # chunk (10, 10)
	var settlement_anchor := Vector3i(400, 0, 400) # chunk (25, 25) — far from camera window
	var distant_cell := Vector3i(256, 0, 256)      # chunk (16, 16) — neither window
	grid.set_cell(distant_cell, CellContents.new(9, 1))
	assert_bool(grid.is_chunk_resident(Vector2i(16, 16))).is_true()  # sanity — resident before residency ever ran

	# Act
	grid.update_residency(camera_focus, settlement_anchor)

	# Story vox-011 CORRECTION: eviction dispatch SHARES one concurrency
	# budget with page-in dispatch (ADR-0015 Decision §6 — "reads AND writes
	# SHARE one concurrency budget"). In this single call, the desired
	# window's 34 pristine chunks (25 camera + 9 settlement, no overlap) are
	# requested FIRST and saturate the default cap (32) with regen dispatches
	# before the eviction loop ever reaches chunk (16,16) -- so THIS
	# specific eviction can itself be a cap-miss and stay resident for a
	# call or two, exactly the same "stays queued, never a synchronous
	# fallback" contract as a page-in cap-miss (never a special case). A
	# bare same-call check here would be flaky/incorrect under the async
	# model; settling first (as every other assertion in this file now does)
	# is the correct fix, not a relaxation of the guarantee — the chunk IS
	# still evicted, just not necessarily within the exact call that first
	# requested it.
	grid.wait_for_async_residency_idle()

	# Assert — the distant, previously-written chunk was evicted once
	# settled.
	assert_bool(grid.is_chunk_resident(Vector2i(16, 16))).is_false()

	# Assert — resident set is EXACTLY the union, nothing more, nothing less.
	var expected: Dictionary[Vector2i, bool] = {}
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			expected[Vector2i(10 + dx, 10 + dz)] = true
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			expected[Vector2i(25 + dx, 25 + dz)] = true
	var resident: Array[Vector2i] = grid.get_resident_chunk_keys()
	assert_int(resident.size()).is_equal(expected.size())
	for key: Vector2i in resident:
		assert_bool(expected.has(key)).is_true()


func test_update_residency_overlapping_camera_and_settlement_windows_counted_once() -> void:
	# Arrange — edge case (QA plan AC-1): camera and settlement windows overlap.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 2
	config.settlement_radius_chunks = 2
	config.region_directory = _make_temp_region_dir("ac1_overlap")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var camera_focus := Vector3i(80, 0, 80)       # chunk (5, 5)
	var settlement_anchor := Vector3i(96, 0, 96)  # chunk (6, 6) — overlaps camera window

	# Act
	grid.update_residency(camera_focus, settlement_anchor)
	grid.wait_for_async_residency_idle()  # Story vox-011: page-in is async — settle first

	# Assert — resident count matches the UNION size, never the (larger) sum
	# of both windows' sizes counted separately.
	var expected: Dictionary[Vector2i, bool] = {}
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			expected[Vector2i(5 + dx, 5 + dz)] = true
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			expected[Vector2i(6 + dx, 6 + dz)] = true
	assert_int(grid.get_resident_chunk_keys().size()).is_equal(expected.size())


func test_update_residency_on_large_world_stays_bounded_by_footprint_not_world_size() -> void:
	# Arrange — the largest currently-validated world size (2048 cells/axis).
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 2048
	config.world_depth_cells = 2048
	config.region_size_chunks = 32
	config.view_radius_chunks = 4
	config.settlement_radius_chunks = 2
	config.region_directory = _make_temp_region_dir("ac1_bounded")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act — camera and settlement share the same anchor (world center).
	grid.update_residency(Vector3i(1024, 0, 1024), Vector3i(1024, 0, 1024))
	grid.wait_for_async_residency_idle()  # Story vox-011: page-in is async — settle first

	# Assert — resident count is tiny relative to the 128x128 = 16,384-chunk
	# world (a 9x9 window, footprint-bounded, TR-voxel-world-053).
	var resident_count: int = grid.get_resident_chunk_keys().size()
	assert_bool(resident_count > 0).is_true()
	assert_bool(resident_count <= 100).is_true()


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-041) — transparent page-in + lossless round trip
# ---------------------------------------------------------------------------

func test_get_cell_after_evict_and_reapproach_returns_originally_written_value() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("ac2_roundtrip")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var written_cell := Vector3i(160, 2, 160)  # chunk (10, 10)
	grid.set_cell(written_cell, CellContents.new(42, 7))

	# Act — move residency far away (evicts + dispatches chunk (10,10)'s
	# flush), then bring it back into view via update_residency's own bulk
	# page-in.
	grid.update_residency(Vector3i(0, 0, 0), Vector3i(0, 0, 0))
	assert_bool(grid.is_chunk_resident(Vector2i(10, 10))).is_false()  # dropped the instant the flush was DISPATCHED (Story vox-011)
	# Story vox-011: the eviction's flush is now async — settle it here so the
	# region file is DURABLE before the page-back-in reads it (without this,
	# the read could race the still-in-flight write, a real gap this story
	# defers to Story 013's read-through cache; settling avoids exercising it).
	grid.wait_for_async_residency_idle()
	grid.update_residency(written_cell, written_cell)
	grid.wait_for_async_residency_idle()  # Story vox-011: page-in is async — settle before reading back

	# Assert — lossless round trip; accessor signature/semantics unchanged.
	var read_back: CellContents = grid.get_cell(written_cell)
	assert_int(read_back.block_type_id).is_equal(42)
	assert_int(read_back.material_id).is_equal(7)


func test_get_cell_on_evicted_chunk_pages_in_transparently_without_explicit_update_residency() -> void:
	# Arrange — same shape, but this time prove get_cell ITSELF triggers the
	# page-in, with no update_residency call bringing the chunk back first.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("ac2_direct_read")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var written_cell := Vector3i(64, 3, 64)  # chunk (4, 4)
	grid.set_cell(written_cell, CellContents.new(15, 3))
	grid.update_residency(Vector3i(0, 0, 0), Vector3i(0, 0, 0))  # evicts + dispatches chunk (4,4)'s flush
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_false()
	# Story vox-011: settle the flush so the region file is DURABLE before a
	# bare get_cell dispatches its own read against it (same rationale as
	# test_get_cell_after_evict_and_reapproach_returns_originally_written_value
	# — avoids racing the read against a still-in-flight write, a real gap
	# this story defers to Story 013's read-through cache).
	grid.wait_for_async_residency_idle()

	# Act — a bare get_cell, no update_residency call in between. Story
	# vox-011: get_cell's own page-in is now NON-BLOCKING (ADR-0015 Decision
	# §6 — never a synchronous fallback), so the FIRST bare call only
	# DISPATCHES the background read and transparently serves an empty
	# result for now; it does not yet reflect the persisted data. Draining
	# that dispatched read (via the NARROW [method
	# VoxelWorldGrid.drain_pending_async_reads] — deliberately NOT [method
	# VoxelWorldGrid.wait_for_async_residency_idle], which would re-drive
	# update_residency toward the STALE (0,0,0) window used to evict this
	# chunk earlier and evict it again immediately, since chunk (4,4) is
	# outside that window and was only ever brought back by this bare
	# get_cell "side channel" — see that method's own doc comment) lets the
	# dispatched read complete, and a SECOND bare get_cell call then observes
	# it — this is the exact "stays queued until a later call" contract
	# ADR-0015 requires, not a regression from Story vox-010's synchronous
	# version.
	var first_read: CellContents = grid.get_cell(written_cell)
	assert_bool(first_read.is_empty()).is_true()
	grid.drain_pending_async_reads()
	var read_back: CellContents = grid.get_cell(written_cell)

	# Assert
	assert_int(read_back.block_type_id).is_equal(15)
	assert_int(read_back.material_id).is_equal(3)
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_true()  # page-in landed once the background read settled


func test_pristine_chunk_pages_in_via_terrain_regen_and_stays_unpersisted_when_evicted() -> void:
	# Arrange — Decision §5: a never-touched chunk regenerates from the seed
	# on page-in, and — having never been dirtied — creates NO region file at
	# all if evicted again without an intervening write.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.base_height = 4
	config.amplitude = 3.0
	config.frequency = 0.05
	config.min_y = 0
	config.max_y = 16
	config.terrain_seed = 99
	config.region_directory = _make_temp_region_dir("ac2_pristine_regen")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	# y = min_y = 0: the height formula's clamp guarantees height >= 0, so
	# this column's y=0 cell is ALWAYS terrain regardless of the noise value
	# actually sampled (base_height=4, amplitude=3 => worst case height = 1).
	var pristine_cell := Vector3i(64, 0, 64)  # chunk (4, 4), never written

	# Act — bring the never-touched chunk into residency.
	grid.update_residency(pristine_cell, pristine_cell)
	grid.wait_for_async_residency_idle()  # Story vox-011: regen dispatch is async — settle before asserting

	# Assert — resident, and reads back real (non-empty) regenerated terrain.
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_true()
	var contents: CellContents = grid.get_cell(pristine_cell)
	assert_bool(contents.is_empty()).is_false()

	# Act — evict it again with no writes in between. Chunk (4,4)'s OWN
	# eviction needs no I/O at all and is immediate (clean, never dirtied --
	# the same zero-I/O contract Story vox-010 already had), but this call
	# ALSO dispatches page-in for the NEW (0,0,0)-anchored window's own
	# pristine chunks as a side effect — settle so no task is left in flight
	# referencing this grid when it is freed at test end (a background task
	# holds a `Callable(self, ...)` into this Node; see [method
	# VoxelWorldGrid._notification]'s doc comment).
	grid.update_residency(Vector3i(0, 0, 0), Vector3i(0, 0, 0))
	grid.wait_for_async_residency_idle()

	# Assert — never dirtied, so its region file was never created at all.
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_false()
	var region_path: String = config.region_directory.path_join("r_1_1.bin")
	assert_bool(FileAccess.file_exists(region_path)).is_false()


# ---------------------------------------------------------------------------
# AC-3 (TR-voxel-world-053) — per-region header I/O happens exactly once
# ---------------------------------------------------------------------------

func test_region_header_io_happens_exactly_once_across_many_touches() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = _make_temp_region_dir("ac3_header_once")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var cell := Vector3i(32, 1, 32)  # chunk (2, 2)
	grid.set_cell(cell, CellContents.new(5, 0))

	# Act — repeatedly evict and re-page-in the SAME region across many
	# separate update_residency calls ("touched repeatedly over many ticks").
	# Story vox-011 NOTE: no settle call is needed between iterations here —
	# [VoxelWorldRegionFile]'s header bookkeeping ([method
	# VoxelWorldRegionFile._ensure_header]/[method has_chunk]/[method
	# offset_of]/[method reserve_offset_for_write]) runs SYNCHRONOUSLY on the
	# main thread by design (ADR-0015 Decision §6's one sanctioned
	# synchronous exception) regardless of whether the corresponding PAYLOAD
	# read/write is dispatched async — this assertion is about header I/O
	# count, not payload data correctness, so it is unaffected by the
	# eviction-flush/page-in timing this story changed elsewhere in this file.
	for i in 10:
		grid.update_residency(Vector3i(2000, 0, 2000), Vector3i(2000, 0, 2000))  # evict (out of world -> empty desired set)
		grid.update_residency(cell, cell)  # page back in

	# Story vox-011: the header-count assertion itself needs no settle (see
	# note above), but 20 rapid-fire update_residency calls with no delay
	# between them can leave a same-chunk read/write dispatch still in
	# flight at the moment this test function returns — drain before the
	# grid is freed at test end (belt-and-suspenders alongside [method
	# VoxelWorldGrid._notification]'s own PREDELETE safety net; a background
	# task actively executing at the exact moment of `free()` can race that
	# net, so tests drain explicitly rather than relying on it alone).
	grid.wait_for_async_residency_idle()

	# Assert — header I/O for chunk (2,2)'s region occurred exactly once.
	assert_int(grid.get_region_header_load_count(Vector2i(2, 2))).is_equal(1)


func test_region_header_load_count_is_zero_for_a_region_never_touched() -> void:
	# Arrange + Act — no update_residency/get_cell call at all, so no async
	# dispatch is ever engaged (Story vox-011 unaffected: nothing to settle).
	var config := VoxelWorldConfig.new()
	config.region_directory = _make_temp_region_dir("ac3_untouched")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Assert
	assert_int(grid.get_region_header_load_count(Vector2i(0, 0))).is_equal(0)


# ---------------------------------------------------------------------------
# Opt-in behavior — a grid that never calls update_residency is unaffected
# ---------------------------------------------------------------------------

func test_grid_that_never_calls_update_residency_never_evicts_a_written_chunk() -> void:
	# Arrange — pre-existing behavior (Story vox-002/003) must be byte-for-
	# byte unchanged for a caller that never engages residency. Story
	# vox-011 unaffected: [member VoxelWorldGrid._residency_active] gates
	# EVERY async dispatch path exactly as it gated the old synchronous one,
	# so a caller that never calls update_residency dispatches nothing.
	var config := VoxelWorldConfig.new()
	config.region_directory = _make_temp_region_dir("opt_in_untouched")
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var cell := Vector3i(1500, 4, 1500)  # a chunk far from any default window

	# Act
	grid.set_cell(cell, CellContents.new(3, 1))

	# Assert — still resident; nothing was ever evicted, since
	# update_residency was never called.
	assert_bool(grid.is_chunk_resident(grid.chunk_key_for_cell(cell))).is_true()
	assert_int(grid.get_cell(cell).block_type_id).is_equal(3)
