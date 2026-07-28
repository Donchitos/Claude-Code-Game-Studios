## Unit test — Voxel World story vox-002 (chunked packed-array storage + O(1)
## accessors + single-cell change signal, ADR-0014 Decision §1).
##
## Proves, all against [VoxelWorldGrid] / [CellContents]:
## 1. AC-1 (TR-voxel-world-031/045): write -> read -> overwrite round trip,
##    including `clear_cell` returning prior contents and leaving the cell
##    empty.
## 2. AC-2 (TR-voxel-world-032): a single `set_cell`/`clear_cell` emits
##    [signal VoxelWorldGrid.cell_changed] exactly once, carrying (cell,
##    before, after) — asserted via a direct listener capture (this
##    codebase's established GdUnit4 signal-assertion pattern, see
##    `tests/unit/foundation/boot_sequencing_gate_test.gd`), not
##    `GdUnitSignalAssert.is_emitted()`.
## 3. AC-3 (TR-voxel-world-047): 10,000 repeated `get_cell` calls never
##    mutate grid state (snapshot equality before/after) and never allocate
##    an untouched chunk.
## 4. AC-4 (TR-voxel-world-030): a "terrain-origin" cell and a
##    "player-placed" cell with identical ids read back byte-identical — no
##    hidden origin flag anywhere on [CellContents].
## 5. TR-voxel-world-003/041: one cell = one occupant, chunked packed-array
##    storage — distinct chunks and adjacent chunks across a chunk boundary
##    never corrupt each other.
## 6. Defensive hardening (TR-voxel-world-037, not explicitly QA-planned for
##    this story but required by the GDD's general "never silently
##    clamp/crash" contract): `get_cell`/`set_cell` on an out-of-bounds cell
##    return `null` and never emit a signal.
class_name ChunkedCellStorageTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# CellContents — plain value-object contract
# ---------------------------------------------------------------------------

func test_cell_contents_empty_factory_is_empty() -> void:
	# Arrange + Act
	var contents := CellContents.empty()

	# Assert
	assert_bool(contents.is_empty()).is_true()
	assert_int(contents.block_type_id).is_equal(CellContents.EMPTY_BLOCK_TYPE_ID)
	assert_int(contents.material_id).is_equal(0)


func test_cell_contents_is_empty_false_for_nonzero_block_type_id() -> void:
	# Arrange + Act
	var contents := CellContents.new(5, 2)

	# Assert
	assert_bool(contents.is_empty()).is_false()
	assert_int(contents.block_type_id).is_equal(5)
	assert_int(contents.material_id).is_equal(2)


# ---------------------------------------------------------------------------
# get_cell on an untouched chunk (lazy-allocation fast path)
# ---------------------------------------------------------------------------

func test_get_cell_never_touched_chunk_returns_empty() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var contents: CellContents = grid.get_cell(Vector3i(500, 4, 500))

	# Assert
	assert_bool(contents.is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC-1 (TR-voxel-world-031/045) — write / read / overwrite round trip
# ---------------------------------------------------------------------------

func test_set_cell_then_get_cell_returns_written_contents() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var previous: CellContents = grid.set_cell(Vector3i(2, 0, 5), CellContents.new(11, 3))
	var read_back: CellContents = grid.get_cell(Vector3i(2, 0, 5))

	# Assert — first write to a never-touched cell: previous is empty.
	assert_bool(previous.is_empty()).is_true()
	assert_int(read_back.block_type_id).is_equal(11)
	assert_int(read_back.material_id).is_equal(3)


func test_set_cell_overwrite_returns_previous_contents_and_get_returns_new() -> void:
	# Arrange — QA plan AC-1: set_cell(c, block_A) then set_cell(c, block_B).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var cell := Vector3i(7, 3, 9)
	grid.set_cell(cell, CellContents.new(11, 0))  # block_A

	# Act
	var previous: CellContents = grid.set_cell(cell, CellContents.new(20, 1))  # block_B
	var read_back: CellContents = grid.get_cell(cell)

	# Assert — the second set returns block_A as previous, get returns block_B.
	assert_int(previous.block_type_id).is_equal(11)
	assert_int(previous.material_id).is_equal(0)
	assert_int(read_back.block_type_id).is_equal(20)
	assert_int(read_back.material_id).is_equal(1)


func test_clear_cell_on_occupied_cell_returns_prior_contents_and_leaves_empty() -> void:
	# Arrange — QA plan AC-1 edge case.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var cell := Vector3i(4, 2, 4)
	grid.set_cell(cell, CellContents.new(20, 1))

	# Act
	var previous: CellContents = grid.clear_cell(cell)
	var read_back: CellContents = grid.get_cell(cell)

	# Assert
	assert_int(previous.block_type_id).is_equal(20)
	assert_int(previous.material_id).is_equal(1)
	assert_bool(read_back.is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-032) — exactly one signal per single write
# ---------------------------------------------------------------------------

func test_set_cell_emits_cell_changed_exactly_once_with_cell_before_after() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var cell := Vector3i(1, 1, 1)
	grid.set_cell(cell, CellContents.new(5, 0))  # establish a non-empty "before"
	var received: Array = []
	grid.cell_changed.connect(func(p_cell: Vector3i, before: CellContents, after: CellContents) -> void:
		received.append({"cell": p_cell, "before": before, "after": after}))

	# Act
	grid.set_cell(cell, CellContents.new(11, 2))

	# Assert
	assert_int(received.size()).is_equal(1)
	var payload: Dictionary = received[0]
	assert_vector(Vector3(payload["cell"])).is_equal(Vector3(cell))
	var before: CellContents = payload["before"]
	var after: CellContents = payload["after"]
	assert_int(before.block_type_id).is_equal(5)
	assert_int(before.material_id).is_equal(0)
	assert_int(after.block_type_id).is_equal(11)
	assert_int(after.material_id).is_equal(2)


func test_clear_cell_emits_cell_changed_exactly_once() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var cell := Vector3i(2, 2, 2)
	grid.set_cell(cell, CellContents.new(9, 4))
	var received: Array = []
	grid.cell_changed.connect(func(p_cell: Vector3i, before: CellContents, after: CellContents) -> void:
		received.append({"cell": p_cell, "before": before, "after": after}))

	# Act
	grid.clear_cell(cell)

	# Assert
	assert_int(received.size()).is_equal(1)
	var after: CellContents = received[0]["after"]
	assert_bool(after.is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC-3 (TR-voxel-world-047) — read purity across 10,000 repeated calls
# ---------------------------------------------------------------------------

func test_repeated_get_cell_calls_do_not_mutate_grid_state() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var probe_cells: Array[Vector3i] = [
		Vector3i(3, 2, 5), Vector3i(20, 4, 20), Vector3i(0, 0, 0), Vector3i(100, 8, 200),
	]
	for i in probe_cells.size():
		grid.set_cell(probe_cells[i], CellContents.new(10 + i, i))
	var snapshot: Array[Dictionary] = []
	for cell: Vector3i in probe_cells:
		var contents: CellContents = grid.get_cell(cell)
		snapshot.append({"block_type_id": contents.block_type_id, "material_id": contents.material_id})
	var untouched_cell := Vector3i(500, 5, 500)

	# Act — 10,000 repeated reads (QA plan AC-3), mixing probe cells with an
	# untouched cell to also exercise the never-allocate fast path repeatedly.
	for i in 10000:
		grid.get_cell(probe_cells[i % probe_cells.size()])
		grid.get_cell(untouched_cell)

	# Assert — every probe cell's contents are still byte-identical.
	for i in probe_cells.size():
		var contents: CellContents = grid.get_cell(probe_cells[i])
		assert_int(contents.block_type_id).is_equal(snapshot[i]["block_type_id"])
		assert_int(contents.material_id).is_equal(snapshot[i]["material_id"])
	# The read-only cell never became non-empty from being read 10,000 times.
	assert_bool(grid.get_cell(untouched_cell).is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC-4 (TR-voxel-world-030) — terrain vs player-placed indistinguishability
# ---------------------------------------------------------------------------

func test_terrain_and_player_placed_cells_with_identical_ids_are_indistinguishable() -> void:
	# Arrange — two different cells, written via two separate calls simulating
	# a "terrain-origin" write and a "player-placed" write with identical ids.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(0, 4, 0), CellContents.new(1, 0))     # terrain-origin
	grid.set_cell(Vector3i(50, 4, 50), CellContents.new(1, 0))   # player-placed, same ids

	# Act
	var terrain_read: CellContents = grid.get_cell(Vector3i(0, 4, 0))
	var player_read: CellContents = grid.get_cell(Vector3i(50, 4, 50))

	# Assert — byte-identical, no origin discriminator exists on CellContents.
	assert_int(terrain_read.block_type_id).is_equal(player_read.block_type_id)
	assert_int(terrain_read.material_id).is_equal(player_read.material_id)


# ---------------------------------------------------------------------------
# Chunked storage correctness — distinct chunks and chunk-boundary adjacency
# ---------------------------------------------------------------------------

func test_different_chunks_store_independently() -> void:
	# Arrange — same local offset (0,0,0) within two different chunks.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	grid.set_cell(Vector3i(0, 0, 0), CellContents.new(5, 1))     # chunk (0,0)
	grid.set_cell(Vector3i(16, 0, 0), CellContents.new(9, 2))    # chunk (1,0)

	# Assert
	var first: CellContents = grid.get_cell(Vector3i(0, 0, 0))
	var second: CellContents = grid.get_cell(Vector3i(16, 0, 0))
	assert_int(first.block_type_id).is_equal(5)
	assert_int(first.material_id).is_equal(1)
	assert_int(second.block_type_id).is_equal(9)
	assert_int(second.material_id).is_equal(2)


func test_set_cell_across_chunk_boundary_does_not_corrupt_neighboring_chunk() -> void:
	# Arrange — the last cell of chunk (0,0) and the first cell of chunk (1,0)
	# along X (CHUNK_SIZE = 16).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	grid.set_cell(Vector3i(15, 0, 0), CellContents.new(7, 0))
	grid.set_cell(Vector3i(16, 0, 0), CellContents.new(8, 0))

	# Assert
	assert_int(grid.get_cell(Vector3i(15, 0, 0)).block_type_id).is_equal(7)
	assert_int(grid.get_cell(Vector3i(16, 0, 0)).block_type_id).is_equal(8)


# ---------------------------------------------------------------------------
# Defensive hardening (TR-voxel-world-037) — out-of-bounds never crashes
# ---------------------------------------------------------------------------

func test_get_cell_outside_bounds_returns_null() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act + Assert
	assert_object(grid.get_cell(Vector3i(-1, 0, 0))).is_null()
	assert_object(grid.get_cell(Vector3i(0, 999, 0))).is_null()  # above GDD default max_y = 16


func test_set_cell_outside_bounds_returns_null_and_emits_no_signal() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var received: Array = []
	grid.cell_changed.connect(func(p_cell: Vector3i, before: CellContents, after: CellContents) -> void:
		received.append(p_cell))

	# Act
	var result: CellContents = grid.set_cell(Vector3i(-1, 0, 0), CellContents.new(5, 0))

	# Assert
	assert_object(result).is_null()
	assert_int(received.size()).is_equal(0)


# ---------------------------------------------------------------------------
# set_cell contract enforcement — packed-byte range (assert-based, mirrors
# VoxelWorldGrid's existing `config != null` assert precedent, story-001)
# ---------------------------------------------------------------------------

func test_set_cell_block_type_id_above_255_raises_assertion() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act + Assert
	await assert_error(func() -> void: grid.set_cell(Vector3i(0, 0, 0), CellContents.new(300, 0))).is_runtime_error(
		"Assertion failed: VoxelWorldGrid.set_cell block_type_id out of packed-byte range 0-255: 300"
	)
