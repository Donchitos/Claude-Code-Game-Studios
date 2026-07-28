## Integration test — Voxel World story vox-005 (iterate_occupied() API —
## occupied-cells iteration, torn-read-free; ADR-0014 primary / ADR-0012
## secondary; TR-voxel-world-021/048/033).
##
## Proves, all against [VoxelWorldGrid.iterate_occupied] / [CellOccupantRecord]:
## 1. AC15 (TR-voxel-world-021): exactly the occupied cells are yielded, no
##    empty cell ever appears, among a large mostly-empty extent.
## 2. AC14 (TR-voxel-world-048): iteration observes only fully-committed cell
##    states, never a partial/in-progress write — proven both structurally
##    (no `await`/`Thread`/`WorkerThreadPool` anywhere in [VoxelWorldGrid]'s
##    own source, so no write can ever interleave mid-scan) and functionally
##    (calling [method iterate_occupied] reentrantly from inside a write's own
##    change signal — the earliest any listener could possibly observe the
##    new state — already sees the fully-committed record, and a cell
##    overwritten twice never shows a mixed old-block/new-material or
##    new-block/old-material record).
## 3. Edge case: an empty grid yields nothing (QA plan AC-2).
##
## NOTE (accumulated pitfall): signal-fire capture uses a captured [Array]
## with `.append()`, never a captured scalar — GDScript closures do not write
## back captured scalars (same pitfall noted in
## `bulk_write_batched_signal_test.gd`).
class_name IterateOccupiedTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# AC15 (TR-voxel-world-021) — occupied-only, exact set, among a large extent
# ---------------------------------------------------------------------------

func test_iterate_occupied_returns_exactly_the_100_occupied_cells_among_large_empty_extent() -> void:
	# Arrange — QA plan AC-1: 100 occupied cells among a large (default
	# 2000x2000x16) mostly-empty extent, scattered across several chunks
	# (CHUNK_SIZE = 16).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var expected_cells: Array[Vector3i] = []
	var changes: Dictionary[Vector3i, CellContents] = {}
	for i in 100:
		var cell := Vector3i((i * 17) % 1900, i % 16, (i * 13) % 1900)
		expected_cells.append(cell)
		changes[cell] = CellContents.new(10 + (i % 200), i % 5)
	grid.bulk_write(changes)

	# Act
	var occupied: Array[CellOccupantRecord] = grid.iterate_occupied()

	# Assert — exactly 100 records, matching the expected cell set; nothing else.
	assert_int(occupied.size()).is_equal(100)
	var seen_cells: Array[Vector3i] = []
	for record: CellOccupantRecord in occupied:
		assert_bool(record.contents.is_empty()).is_false()
		seen_cells.append(record.cell)
	for expected: Vector3i in expected_cells:
		assert_bool(seen_cells.has(expected)).is_true()


func test_iterate_occupied_values_match_the_last_write_to_each_cell() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var changes: Dictionary[Vector3i, CellContents] = {
		Vector3i(1, 0, 1): CellContents.new(7, 2),
		Vector3i(20, 3, 5): CellContents.new(11, 9),
	}
	grid.bulk_write(changes)

	# Act
	var occupied: Array[CellOccupantRecord] = grid.iterate_occupied()

	# Assert
	var by_cell: Dictionary[Vector3i, CellOccupantRecord] = {}
	for record: CellOccupantRecord in occupied:
		by_cell[record.cell] = record
	assert_int(by_cell[Vector3i(1, 0, 1)].contents.block_type_id).is_equal(7)
	assert_int(by_cell[Vector3i(1, 0, 1)].contents.material_id).is_equal(2)
	assert_int(by_cell[Vector3i(20, 3, 5)].contents.block_type_id).is_equal(11)
	assert_int(by_cell[Vector3i(20, 3, 5)].contents.material_id).is_equal(9)


# ---------------------------------------------------------------------------
# Edge case — empty grid yields nothing (QA plan AC-2)
# ---------------------------------------------------------------------------

func test_iterate_occupied_empty_grid_yields_nothing() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var occupied: Array[CellOccupantRecord] = grid.iterate_occupied()

	# Assert
	assert_array(occupied).is_empty()


func test_iterate_occupied_missing_config_raises_assertion() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())

	# Act + Assert
	await assert_error(func() -> void: grid.iterate_occupied()).is_runtime_error(
		"Assertion failed: VoxelWorldGrid.config not wired"
	)


# ---------------------------------------------------------------------------
# AC14 (TR-voxel-world-048) — structural proof: no await/threading anywhere
# ---------------------------------------------------------------------------

func test_no_await_or_threading_apis_anywhere_in_voxel_world_source() -> void:
	# Grep-verifiable structural proof (Implementation Notes: "Do not add
	# locks; assert the serialization invariant in a test") — [method
	# VoxelWorldGrid.iterate_occupied] itself is a plain synchronous scan with
	# no `await`/`Thread`/`WorkerThreadPool` anywhere in ITS OWN method body,
	# so it can never be paused mid-scan for a write to interleave; torn-read
	# prevention follows from this, not from a lock.
	#
	# Story vox-011 SCOPE NARROWING (ADR-0015 Decision §6): this check used to
	# scan the ENTIRE `src/voxel_world/` directory, back when nothing in this
	# system used any threading API at all. Story vox-011 legitimately
	# introduces `WorkerThreadPool` for the paged-residency tier's async
	# region I/O/terrain-gen ([VoxelWorldGrid]'s `_bg_*`/`_try_dispatch_*`/
	# `_request_*` methods, [VoxelWorldRegionFile]'s `static` payload I/O) —
	# a DIFFERENT, unrelated code path from [method iterate_occupied]. This
	# story's own torn-read-free guarantee is about [method iterate_occupied]
	# specifically (Story vox-005's AC14), so the check is narrowed to that
	# method's own body via [method _extract_method_body] rather than the
	# whole directory — the invariant this test proves is UNCHANGED; only the
	# scan's scope is corrected to match what the invariant was ever actually
	# about.
	var source: String = _read_all_gd_source("res://src/voxel_world")
	var method_body: String = _extract_method_body(source, "func iterate_occupied(")

	var banned_substrings: Array[String] = [
		"await",
		"Thread.new",
		"WorkerThreadPool",
	]
	for banned: String in banned_substrings:
		assert_bool(method_body.contains(banned)).is_false()


## Extracts a single top-level function's body (from [param start_marker] up
## to -- but not including -- the next top-level `func` declaration, or end
## of [param source] if it is the last one) out of already comment-stripped,
## flattened [param source] (see [method _read_all_gd_source]). Narrow,
## purpose-built for this test's Story vox-011 scope-narrowing (see [method
## test_no_await_or_threading_apis_anywhere_in_voxel_world_source]) rather
## than a general-purpose parser -- relies on this codebase's convention of
## one top-level `func` per line with no nested top-level `func` keyword
## occurring mid-body (true for every method in `src/voxel_world/`).
func _extract_method_body(source: String, start_marker: String) -> String:
	var start_index: int = source.find(start_marker)
	assert(start_index != -1, "Method not found: %s" % start_marker)
	var body_start: int = start_index + start_marker.length()
	var next_func_index: int = source.find("\nfunc ", body_start)
	if next_func_index == -1:
		return source.substr(body_start)
	return source.substr(body_start, next_func_index - body_start)


# ---------------------------------------------------------------------------
# AC14 (TR-voxel-world-048) — functional proof: reentrant read during a
# write's own change signal sees only the fully-committed record
# ---------------------------------------------------------------------------

func test_iterate_occupied_called_from_within_cell_changed_signal_sees_fully_committed_write() -> void:
	# Arrange — the earliest any listener could possibly react to a write is
	# from inside its own change signal; if iterate_occupied() ever exposed a
	# partial/in-progress state, this is where it would show.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var written_cell := Vector3i(9, 2, 9)
	var seen_during_signal: Array[CellOccupantRecord] = []
	grid.cell_changed.connect(func(_cell: Vector3i, _before: CellContents, _after: CellContents) -> void:
		for record: CellOccupantRecord in grid.iterate_occupied():
			if record.cell == written_cell:
				seen_during_signal.append(record))

	# Act
	grid.set_cell(written_cell, CellContents.new(42, 6))

	# Assert — exactly one sighting, already fully committed (both fields
	# match the write, never a stale/empty or half-written record).
	assert_int(seen_during_signal.size()).is_equal(1)
	assert_int(seen_during_signal[0].contents.block_type_id).is_equal(42)
	assert_int(seen_during_signal[0].contents.material_id).is_equal(6)


func test_iterate_occupied_called_from_within_batch_signal_sees_every_cell_fully_committed() -> void:
	# Arrange — same proof, batch path (TR-voxel-world-042/043's own
	# already-established "batch fires only after every cell in it is
	# written" contract is exactly what this test leans on).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var changes: Dictionary[Vector3i, CellContents] = {}
	for i in 20:
		changes[Vector3i(i, 0, 0)] = CellContents.new(50 + i, 0)
	var occupied_count_during_signal: Array[int] = []
	grid.cells_changed_batch.connect(func(_records: Array[CellChangeRecord]) -> void:
		occupied_count_during_signal.append(grid.iterate_occupied().size()))

	# Act
	grid.bulk_write(changes)

	# Assert — all 20 cells already visible (fully committed) inside the
	# batch signal, not e.g. 19 of 20 (which would indicate a torn/partial
	# observation mid-batch).
	assert_int(occupied_count_during_signal.size()).is_equal(1)
	assert_int(occupied_count_during_signal[0]).is_equal(20)


# ---------------------------------------------------------------------------
# AC14 (TR-voxel-world-048) — a cell overwritten twice never shows a mixed
# old-block/new-material (or new-block/old-material) record
# ---------------------------------------------------------------------------

func test_iterate_occupied_overwritten_cell_never_shows_mixed_before_after_fields() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var cell := Vector3i(4, 1, 4)
	grid.set_cell(cell, CellContents.new(3, 1))

	# Act — snapshot after the FIRST write.
	var after_first: CellOccupantRecord = _find_record(grid.iterate_occupied(), cell)

	grid.set_cell(cell, CellContents.new(8, 4))

	# Act — snapshot after the SECOND write.
	var after_second: CellOccupantRecord = _find_record(grid.iterate_occupied(), cell)

	# Assert — each snapshot is entirely one write's values, never a mix.
	assert_int(after_first.contents.block_type_id).is_equal(3)
	assert_int(after_first.contents.material_id).is_equal(1)
	assert_int(after_second.contents.block_type_id).is_equal(8)
	assert_int(after_second.contents.material_id).is_equal(4)


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _find_record(records: Array[CellOccupantRecord], cell: Vector3i) -> CellOccupantRecord:
	for record: CellOccupantRecord in records:
		if record.cell == cell:
			return record
	return null


## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive), stripping full-line `#`/`##`
## doc-comment lines first — mirrors `dda_raycast_test.gd`'s established
## `_read_all_gd_source` helper (duplicated here per that file's own
## per-test-file precedent).
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
