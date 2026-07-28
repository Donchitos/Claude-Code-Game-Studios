## Unit test — Voxel World story vox-003 (bulk write + single batched signal
## with per-cell before/after, ADR-0014 Implementation Notes).
##
## Proves, all against [VoxelWorldGrid.bulk_write] / [CellChangeRecord]:
## 1. AC-1 (TR-voxel-world-042): a bulk write affecting N cells emits
##    [signal VoxelWorldGrid.cells_changed_batch] exactly once and
##    [signal VoxelWorldGrid.cell_changed] zero times — asserted via a direct
##    listener capture (this codebase's established GdUnit4 signal-assertion
##    pattern, see `chunked_cell_storage_test.gd`), not
##    `GdUnitSignalAssert.is_emitted()`.
## 2. AC-2 (TR-voxel-world-043): the batched signal payload AND the
##    `bulk_write` return value each carry per-cell before/after
##    [CellContents] for every affected cell, including pre-occupied cells
##    reporting their true previous contents.
## 3. Edge cases (QA plan): a bulk write of 1 cell still uses the batched
##    path; an empty change list emits nothing and returns an empty array.
## 4. Defensive hardening (consistent with [VoxelWorldGrid.set_cell]'s
##    established out-of-bounds contract, TR-voxel-world-037): an
##    out-of-bounds cell inside a bulk write is skipped — no record, no
##    crash — while in-bounds cells in the same batch still apply and the
##    batch signal still fires for them.
## 5. Determinism: record order in both the return value and the signal
##    payload matches the [Dictionary] insertion order of [param changes].
##
## NOTE (accumulated pitfall): signal-fire counters use a captured [Array]
## with `.append()`/`.size()`, never a captured scalar `+= 1` inside a
## lambda — GDScript closures do not write back captured scalars.
class_name BulkWriteBatchedSignalTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# AC-1 (TR-voxel-world-042) — exactly one batched signal, zero per-cell signals
# ---------------------------------------------------------------------------

func test_bulk_write_50_cells_emits_batch_signal_once_and_cell_changed_zero_times() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var changes: Dictionary[Vector3i, CellContents] = {}
	for i in 50:
		changes[Vector3i(i, 0, 0)] = CellContents.new(10 + (i % 200), 1)
	var batch_received: Array = []
	var single_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))
	grid.cell_changed.connect(func(p_cell: Vector3i, before: CellContents, after: CellContents) -> void:
		single_received.append(p_cell))

	# Act
	grid.bulk_write(changes)

	# Assert
	assert_int(batch_received.size()).is_equal(1)
	assert_int(single_received.size()).is_equal(0)
	var payload: Array[CellChangeRecord] = batch_received[0]
	assert_int(payload.size()).is_equal(50)


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-043) — per-cell before/after, payload + return value
# ---------------------------------------------------------------------------

func test_bulk_write_50_cells_20_preoccupied_payload_and_return_carry_true_before_after() -> void:
	# Arrange — 50 target cells; 20 of them pre-occupied via individual
	# set_cell calls before the bulk write runs (QA plan AC-2).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var target_cells: Array[Vector3i] = []
	for i in 50:
		target_cells.append(Vector3i(i, 0, 0))
	var preoccupied_before: Dictionary[Vector3i, CellContents] = {}
	for i in 20:
		var cell: Vector3i = target_cells[i]
		var prior := CellContents.new(1 + i, 0)
		grid.set_cell(cell, prior)
		preoccupied_before[cell] = prior
	var changes: Dictionary[Vector3i, CellContents] = {}
	for i in 50:
		changes[target_cells[i]] = CellContents.new(100 + i, 5)
	var batch_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))

	# Act
	var result: Array[CellChangeRecord] = grid.bulk_write(changes)

	# Assert — return value carries 50 records.
	assert_int(result.size()).is_equal(50)
	# Assert — signal payload is the same 50 records.
	assert_int(batch_received.size()).is_equal(1)
	var payload: Array[CellChangeRecord] = batch_received[0]
	assert_int(payload.size()).is_equal(50)

	for record: CellChangeRecord in result:
		var expected_after: CellContents = changes[record.cell]
		assert_int(record.after.block_type_id).is_equal(expected_after.block_type_id)
		assert_int(record.after.material_id).is_equal(expected_after.material_id)
		if preoccupied_before.has(record.cell):
			var expected_before: CellContents = preoccupied_before[record.cell]
			assert_bool(record.before.is_empty()).is_false()
			assert_int(record.before.block_type_id).is_equal(expected_before.block_type_id)
			assert_int(record.before.material_id).is_equal(expected_before.material_id)
		else:
			assert_bool(record.before.is_empty()).is_true()

	for record: CellChangeRecord in payload:
		var expected_after: CellContents = changes[record.cell]
		assert_int(record.after.block_type_id).is_equal(expected_after.block_type_id)
		assert_int(record.after.material_id).is_equal(expected_after.material_id)


# ---------------------------------------------------------------------------
# Edge case — bulk write of 1 cell still uses the batched path
# ---------------------------------------------------------------------------

func test_bulk_write_single_cell_still_emits_batch_signal_not_cell_changed() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var cell := Vector3i(3, 1, 3)
	var changes: Dictionary[Vector3i, CellContents] = {cell: CellContents.new(7, 2)}
	var batch_received: Array = []
	var single_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))
	grid.cell_changed.connect(func(p_cell: Vector3i, before: CellContents, after: CellContents) -> void:
		single_received.append(p_cell))

	# Act
	var result: Array[CellChangeRecord] = grid.bulk_write(changes)

	# Assert
	assert_int(batch_received.size()).is_equal(1)
	assert_int(single_received.size()).is_equal(0)
	assert_int(result.size()).is_equal(1)
	assert_vector(Vector3(result[0].cell)).is_equal(Vector3(cell))
	assert_int(result[0].after.block_type_id).is_equal(7)


# ---------------------------------------------------------------------------
# Edge case — empty change list emits nothing
# ---------------------------------------------------------------------------

func test_bulk_write_empty_change_list_emits_nothing_and_returns_empty_array() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var changes: Dictionary[Vector3i, CellContents] = {}
	var batch_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))

	# Act
	var result: Array[CellChangeRecord] = grid.bulk_write(changes)

	# Assert
	assert_array(result).is_empty()
	assert_int(batch_received.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Defensive hardening — out-of-bounds cell inside a batch is skipped
# ---------------------------------------------------------------------------

func test_bulk_write_skips_out_of_bounds_cell_but_still_applies_and_batches_valid_cells() -> void:
	# Arrange — two valid cells and one out-of-bounds cell in the same batch.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var changes: Dictionary[Vector3i, CellContents] = {
		Vector3i(1, 0, 1): CellContents.new(4, 0),
		Vector3i(-1, 0, 0): CellContents.new(9, 0),  # negative x -- out of bounds
		Vector3i(2, 0, 2): CellContents.new(6, 0),
	}
	var batch_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))

	# Act
	var result: Array[CellChangeRecord] = grid.bulk_write(changes)

	# Assert — only the 2 in-bounds cells produced a record.
	assert_int(result.size()).is_equal(2)
	assert_int(batch_received.size()).is_equal(1)
	var cells_written: Array[Vector3i] = []
	for record: CellChangeRecord in result:
		cells_written.append(record.cell)
	assert_bool(cells_written.has(Vector3i(1, 0, 1))).is_true()
	assert_bool(cells_written.has(Vector3i(2, 0, 2))).is_true()
	assert_bool(cells_written.has(Vector3i(-1, 0, 0))).is_false()
	# The out-of-bounds cell truly never got written.
	assert_object(grid.get_cell(Vector3i(-1, 0, 0))).is_null()


func test_bulk_write_all_cells_out_of_bounds_emits_nothing_and_returns_empty_array() -> void:
	# Arrange — QA-plan-adjacent edge case: a batch that changes zero cells
	# behaves exactly like an empty change list (no "batch of zero" signal).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var changes: Dictionary[Vector3i, CellContents] = {
		Vector3i(-1, 0, 0): CellContents.new(5, 0),
		Vector3i(0, -5, 0): CellContents.new(5, 0),
	}
	var batch_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))

	# Act
	var result: Array[CellChangeRecord] = grid.bulk_write(changes)

	# Assert
	assert_array(result).is_empty()
	assert_int(batch_received.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Determinism — record order matches Dictionary insertion order
# ---------------------------------------------------------------------------

func test_bulk_write_record_order_matches_changes_insertion_order() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var ordered_cells: Array[Vector3i] = [
		Vector3i(9, 0, 0), Vector3i(3, 0, 0), Vector3i(6, 0, 0),
	]
	var changes: Dictionary[Vector3i, CellContents] = {}
	for cell: Vector3i in ordered_cells:
		changes[cell] = CellContents.new(1, 0)

	# Act
	var result: Array[CellChangeRecord] = grid.bulk_write(changes)

	# Assert
	assert_int(result.size()).is_equal(3)
	for i in ordered_cells.size():
		assert_vector(Vector3(result[i].cell)).is_equal(Vector3(ordered_cells[i]))


# ---------------------------------------------------------------------------
# bulk_write contract enforcement — packed-byte range (mirrors set_cell's
# existing assert precedent, story vox-002)
# ---------------------------------------------------------------------------

func test_bulk_write_block_type_id_above_255_raises_assertion() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var changes: Dictionary[Vector3i, CellContents] = {
		Vector3i(0, 0, 0): CellContents.new(300, 0),
	}

	# Act + Assert
	await assert_error(func() -> void: grid.bulk_write(changes)).is_runtime_error(
		"Assertion failed: VoxelWorldGrid.bulk_write block_type_id out of packed-byte range 0-255: 300"
	)


# ---------------------------------------------------------------------------
# CellChangeRecord — plain construction contract
# ---------------------------------------------------------------------------

func test_cell_change_record_stores_cell_before_after_from_init() -> void:
	# Arrange + Act
	var before := CellContents.new(1, 0)
	var after := CellContents.new(2, 1)
	var record := CellChangeRecord.new(Vector3i(4, 4, 4), before, after)

	# Assert
	assert_vector(Vector3(record.cell)).is_equal(Vector3(4, 4, 4))
	assert_int(record.before.block_type_id).is_equal(1)
	assert_int(record.after.block_type_id).is_equal(2)
