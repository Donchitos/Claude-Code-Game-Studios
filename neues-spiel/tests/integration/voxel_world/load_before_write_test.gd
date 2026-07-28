## Integration test — Voxel World story vox-014 (load-before-write for
## far-world/non-resident mutations, ADR-0015 Decision §3; TR-voxel-world-051/
## 053).
##
## Proves, all against [VoxelWorldGrid.set_cell] / [VoxelWorldGrid.get_cell] /
## [VoxelWorldGrid.update_residency] (public API only — no private-member
## reads, matching this codebase's own established precedent in
## `region_file_residency_test.gd`/`read_through_inflight_cache_test.gd`):
## 1. AC-1 (TR-voxel-world-053): a write targeting a cell in a chunk that was
##    previously persisted to disk but is NOT currently resident pages that
##    chunk's region in FIRST, applies the write onto the loaded resident
##    copy, and marks it dirty — proven by asserting the write is NEVER
##    applied blind: a DIFFERENT, already-persisted cell in the SAME chunk
##    survives the round trip untouched (a blind write, i.e. one that
##    lazily allocated a fresh EMPTY chunk instead of loading the persisted
##    one, would have silently erased it). Eventual staggered eviction then
##    flushes the merged (persisted + new) chunk back to disk, verified via a
##    brand-new grid instance reading both cells back from the region file.
## 2. AC-2 (TR-voxel-world-053): a far write arriving while its page-in is
##    still in flight is deferred (never applied to disk blind, never
##    dropped) — `set_cell` returns `null` for that call (the same "nothing
##    happened yet" signature as an out-of-bounds write, but for a different
##    reason: queued, not discarded) and the chunk becomes resident and
##    correct only once the async settle completes.
## 3. Edge case (QA plan, AC-1's own named edge case): two far writes to the
##    SAME non-resident chunk, issued before either settles, coalesce onto
##    ONE page-in dispatch (the shared in-flight async task count never grows
##    past 1 for this chunk) and both writes land once it resolves.
## 4. AC-3 (TR-voxel-world-051, the single-location rule): [method
##    VoxelWorldGrid._apply_write] is the SOLE place implementing the
##    load-before-write check — [method VoxelWorldGrid.set_cell] and [method
##    VoxelWorldGrid.bulk_write] both fall through to it with no residency
##    code of their own (grep-verifiable, this codebase's own established
##    structural-check precedent from `read_through_inflight_cache_test.gd`).
##    A plain [method VoxelWorldGrid.set_cell] call — the exact same entry
##    point a future dig-order (Story vox-009) or Building System write would
##    use — already exhibits the full load-before-write behavior with zero
##    caller-side residency awareness, demonstrated directly by test 1/2/3
##    above using nothing but that one public method.
##
## Test isolation (accumulated pitfall): every test gets its OWN region
## directory under `user://` (never `res://`, never shared across tests,
## never committed) via [method _make_temp_region_dir], removed recursively in
## [method after_test]. Every grid is settled via [method
## VoxelWorldGrid.wait_for_async_residency_idle] before the test ends
## (belt-and-suspenders alongside [method VoxelWorldGrid._notification]'s own
## PREDELETE safety net), except where a test's own assertions REQUIRE the
## page-in to remain deliberately un-settled — those tests settle at the very
## end, after every un-settled assertion has already run.
class_name LoadBeforeWriteTest
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
	var dir_path: String = "user://vox014_test_regions/%s_%d" % [suffix, Time.get_ticks_usec()]
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


func _make_config(region_dir: String) -> VoxelWorldConfig:
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	config.world_depth_cells = 256
	config.region_size_chunks = 4
	config.view_radius_chunks = 1
	config.settlement_radius_chunks = 1
	config.region_directory = region_dir
	return config


# ---------------------------------------------------------------------------
# AC-1 (TR-voxel-world-053) — page-in merges onto the persisted copy, never
# a blind write; eventual eviction flushes the merged result
# ---------------------------------------------------------------------------

func test_set_cell_on_evicted_previously_persisted_chunk_merges_with_disk_data_never_blind() -> void:
	# Arrange — persist ONE cell, then evict + settle so the chunk is genuinely
	# non-resident (not merely mid-flush/in-flight-write-cached — that racier
	# window is vox-013's own scope, not this story's).
	var config: VoxelWorldConfig = _make_config(_make_temp_region_dir("ac1_merge_not_blind"))
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var original_cell := Vector3i(64, 2, 64)  # chunk (4, 4)
	var new_cell := Vector3i(65, 3, 64)       # same chunk (4, 4), different cell
	grid.set_cell(original_cell, CellContents.new(42, 7))
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))
	grid.wait_for_async_residency_idle()
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_false()

	# Act — a far write targeting a DIFFERENT cell in the SAME now-evicted chunk.
	var immediate_result: CellContents = grid.set_cell(new_cell, CellContents.new(99, 3))

	# Assert — deferred this call: never applied blind, not yet resident.
	assert_object(immediate_result).is_null()
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_false()

	# Act — settle the page-in and the now-queued write's application. Uses
	# drain_pending_async_reads (NEVER wait_for_async_residency_idle) because
	# chunk (4,4) sits OUTSIDE the (9999,9999)-anchored desired window:
	# wait_for_async_residency_idle's own re-drive of update_residency would
	# otherwise evict this chunk again the instant it becomes resident, before
	# this test observes it (the exact KNOWN LIMITATION that method's own doc
	# comment names) — drain_pending_async_reads never touches update_residency
	# or eviction at all.
	grid.drain_pending_async_reads()

	# Assert — BOTH the original persisted cell AND the new write are present:
	# proof the write merged onto the loaded copy rather than a blind fresh
	# (empty) chunk allocation, which would have silently erased the original.
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_true()
	var original_read_back: CellContents = grid.get_cell(original_cell)
	assert_int(original_read_back.block_type_id).is_equal(42)
	assert_int(original_read_back.material_id).is_equal(7)
	var new_read_back: CellContents = grid.get_cell(new_cell)
	assert_int(new_read_back.block_type_id).is_equal(99)
	assert_int(new_read_back.material_id).is_equal(3)

	# Act — evict again (flushes the merged chunk) and settle.
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))
	grid.wait_for_async_residency_idle()

	# Assert — a brand-new grid instance (no in-memory carry-over at all) reads
	# BOTH cells back from the region file, proving the merged data — not a
	# blind overwrite of the original — is what actually landed on disk.
	var config2: VoxelWorldConfig = _make_config(config.region_directory)
	var grid2: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid2.config = config2
	grid2.update_residency(original_cell, original_cell)
	grid2.wait_for_async_residency_idle()
	var disk_original: CellContents = grid2.get_cell(original_cell)
	var disk_new: CellContents = grid2.get_cell(new_cell)
	assert_int(disk_original.block_type_id).is_equal(42)
	assert_int(disk_original.material_id).is_equal(7)
	assert_int(disk_new.block_type_id).is_equal(99)
	assert_int(disk_new.material_id).is_equal(3)


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-053) — a write racing an in-flight page-in is deferred,
# never dropped, never blind; applies once the resident copy exists
# ---------------------------------------------------------------------------

func test_set_cell_on_pristine_never_touched_far_chunk_defers_until_page_in_settles() -> void:
	# Arrange — a chunk NEVER touched by this or any grid: residency must be
	# engaged (so _apply_write actually checks it) but the target chunk must
	# sit outside the desired camera/settlement window, so the write's own
	# page-in dispatch is the only thing that ever brings it in.
	var config: VoxelWorldConfig = _make_config(_make_temp_region_dir("ac2_defer_pristine"))
	config.base_height = 4
	config.amplitude = 3.0
	config.frequency = 0.05
	config.min_y = 0
	config.max_y = 16
	config.terrain_seed = 99
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))  # engages residency; empty desired set
	var far_cell := Vector3i(64, 2, 64)  # chunk (4, 4) — never touched, outside the desired window above

	# Act — the far write.
	var immediate_result: CellContents = grid.set_cell(far_cell, CellContents.new(55, 2))

	# Assert — deferred, not dropped, not written blind: no immediate record,
	# the chunk is still not resident, and the page-in was genuinely
	# dispatched (never a synchronous fallback).
	assert_object(immediate_result).is_null()
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_false()
	assert_int(grid.get_in_flight_async_task_count()).is_equal(1)

	# Act — settle. drain_pending_async_reads (NOT wait_for_async_residency_idle
	# — see the AC-1 test's own note above): chunk (4,4) is outside the
	# (9999,9999)-anchored desired window, so a re-drive of update_residency
	# would evict it again the instant it resolves, before this test observes it.
	grid.drain_pending_async_reads()

	# Assert — the write landed correctly, never dropped.
	assert_bool(grid.is_chunk_resident(Vector2i(4, 4))).is_true()
	var read_back: CellContents = grid.get_cell(far_cell)
	assert_int(read_back.block_type_id).is_equal(55)
	assert_int(read_back.material_id).is_equal(2)


func test_cells_changed_batch_fires_once_deferred_write_settles() -> void:
	# Arrange — same shape as above, but asserting the SIGNAL side: a deferred
	# write emits cells_changed_batch (never cell_changed) once it actually
	# lands, and emits NOTHING at the moment of the original (deferred) call.
	var config: VoxelWorldConfig = _make_config(_make_temp_region_dir("ac2_signal_on_settle"))
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))
	var far_cell := Vector3i(32, 1, 32)  # chunk (2, 2)
	var batch_received: Array = []
	var single_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))
	grid.cell_changed.connect(func(p_cell: Vector3i, before: CellContents, after: CellContents) -> void:
		single_received.append(p_cell))

	# Act — the deferred far write.
	grid.set_cell(far_cell, CellContents.new(8, 4))

	# Assert — no signal at all yet; the write has not been applied.
	assert_int(batch_received.size()).is_equal(0)
	assert_int(single_received.size()).is_equal(0)

	# Act — settle.
	grid.wait_for_async_residency_idle()

	# Assert — exactly one batched signal once the deferred write actually
	# applies, never the single per-cell signal.
	assert_int(batch_received.size()).is_equal(1)
	assert_int(single_received.size()).is_equal(0)
	var payload: Array[CellChangeRecord] = batch_received[0]
	assert_int(payload.size()).is_equal(1)
	assert_vector(Vector3(payload[0].cell)).is_equal(Vector3(far_cell))
	assert_int(payload[0].after.block_type_id).is_equal(8)
	assert_int(payload[0].after.material_id).is_equal(4)


# ---------------------------------------------------------------------------
# Edge case (QA plan, AC-1) — two far writes to the same non-resident chunk
# coalesce onto ONE page-in dispatch
# ---------------------------------------------------------------------------

func test_two_far_writes_to_same_non_resident_chunk_coalesce_onto_one_page_in() -> void:
	# Arrange
	var config: VoxelWorldConfig = _make_config(_make_temp_region_dir("ac1_edge_coalesce"))
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))
	var cell_a := Vector3i(32, 1, 32)  # chunk (2, 2)
	var cell_b := Vector3i(33, 2, 33)  # same chunk (2, 2)

	# Act — two writes to the same non-resident chunk, before either settles.
	var result_a: CellContents = grid.set_cell(cell_a, CellContents.new(11, 0))
	var in_flight_after_first: int = grid.get_in_flight_async_task_count()
	var result_b: CellContents = grid.set_cell(cell_b, CellContents.new(22, 1))
	var in_flight_after_second: int = grid.get_in_flight_async_task_count()

	# Assert — both deferred; the SECOND write dispatched NO new task (the
	# in-flight count is unchanged — proof of coalescing onto the one page-in
	# already in flight for this chunk, not a redundant second dispatch).
	assert_object(result_a).is_null()
	assert_object(result_b).is_null()
	assert_int(in_flight_after_first).is_equal(1)
	assert_int(in_flight_after_second).is_equal(in_flight_after_first)

	# Act — settle. drain_pending_async_reads (NOT wait_for_async_residency_idle
	# — see load_before_write_test.gd's other AC-1/AC-2 tests for why): chunk
	# (2,2) sits outside the (9999,9999)-anchored desired window.
	grid.drain_pending_async_reads()

	# Assert — both writes landed, in their original call order.
	var read_a: CellContents = grid.get_cell(cell_a)
	var read_b: CellContents = grid.get_cell(cell_b)
	assert_int(read_a.block_type_id).is_equal(11)
	assert_int(read_b.block_type_id).is_equal(22)


# ---------------------------------------------------------------------------
# Opt-in behavior — a grid that never calls update_residency writes exactly
# as before this story (unaffected by the load-before-write path entirely)
# ---------------------------------------------------------------------------

func test_grid_that_never_calls_update_residency_still_applies_writes_synchronously() -> void:
	# Arrange — pre-existing behavior (Story vox-002/003) must be byte-for-
	# byte unchanged for a caller that never engages residency.
	var config: VoxelWorldConfig = _make_config(_make_temp_region_dir("opt_in_untouched"))
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var cell := Vector3i(120, 4, 120)  # a chunk far from any default window

	# Act
	var result: CellContents = grid.set_cell(cell, CellContents.new(6, 2))

	# Assert — applied immediately (never deferred): result is the (empty)
	# previous contents, and the cell reads back correctly right away.
	assert_object(result).is_not_null()
	assert_bool(result.is_empty()).is_true()
	assert_int(grid.get_cell(cell).block_type_id).is_equal(6)
	assert_bool(grid.is_chunk_resident(grid.chunk_key_for_cell(cell))).is_true()


# ---------------------------------------------------------------------------
# AC-3 (TR-voxel-world-051) — the single-location rule
# ---------------------------------------------------------------------------

func test_apply_write_is_the_sole_load_before_write_call_site() -> void:
	# Grep-verifiable AC (ADR-0015 Decision §3: "this rule lives in ONE
	# place — Voxel World's single batched write path — not in every
	# caller"): _apply_write's own body must reference the residency-request/
	# queue machinery, and it must be the ONLY function in this file that
	# calls _queue_pending_write — proving no second, caller-specific
	# residency check exists anywhere (dig-order, Building System, or
	# otherwise) — every caller inherits this purely by routing through
	# set_cell/bulk_write's shared _apply_write core.
	var source: String = FileAccess.get_file_as_string("res://src/voxel_world/voxel_world_grid.gd")

	var apply_write_start: int = source.find("func _apply_write(")
	assert_int(apply_write_start).is_greater(-1)
	var apply_write_next_func: int = source.find("\nfunc ", apply_write_start + 1)
	assert_int(apply_write_next_func).is_greater(-1)
	var apply_write_body: String = source.substr(apply_write_start, apply_write_next_func - apply_write_start)

	assert_bool(apply_write_body.contains("_request_resident")).is_true()
	assert_bool(apply_write_body.contains("_queue_pending_write")).is_true()

	# "_queue_pending_write(" appears in exactly TWO places in the whole file:
	# its own definition, and the one call site inside _apply_write's body
	# asserted above. A third occurrence would mean a second, duplicated
	# residency-queuing call site living outside the single batched write
	# path — exactly what TR-voxel-world-051 AC-3 forbids.
	var total_occurrences: int = 0
	var search_from: int = 0
	while true:
		var found: int = source.find("_queue_pending_write(", search_from)
		if found == -1:
			break
		total_occurrences += 1
		search_from = found + 1
	assert_int(total_occurrences).is_equal(2)  # 1 definition + 1 call (inside _apply_write)


func test_set_cell_public_entry_point_alone_exhibits_full_load_before_write_behavior() -> void:
	# Behavioral companion to the structural check above: a bare set_cell
	# call — the exact same entry point a future dig-order (Story vox-009) or
	# Building System write would use, with NO residency-specific code of its
	# own — already exhibits deferred load-before-write on a non-resident
	# chunk. This demonstrates the "inherits for free" guarantee directly,
	# without needing Story 009's own (not-yet-built) dig-order code to exist.
	var config: VoxelWorldConfig = _make_config(_make_temp_region_dir("ac3_inherits_for_free"))
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	grid.update_residency(Vector3i(9999, 0, 9999), Vector3i(9999, 0, 9999))
	var far_cell := Vector3i(16, 0, 16)  # chunk (1, 1)

	# Act — a plain set_cell call, nothing dig-order-specific about it.
	# drain_pending_async_reads (NOT wait_for_async_residency_idle — see this
	# file's other AC-1/AC-2 tests for why): chunk (1,1) sits outside the
	# (9999,9999)-anchored desired window.
	var immediate_result: CellContents = grid.set_cell(far_cell, CellContents.new(3, 0))
	grid.drain_pending_async_reads()

	# Assert
	assert_object(immediate_result).is_null()
	assert_int(grid.get_cell(far_cell).block_type_id).is_equal(3)
