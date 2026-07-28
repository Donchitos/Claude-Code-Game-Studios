## Unit test — Voxel World story vox-006 (procedural terrain generation +
## single batched gen signal, ADR-0002 config / ADR-0014 chunked storage).
##
## Proves, all against [VoxelWorldGrid.generate_terrain] / [VoxelWorldConfig]:
## 1. AC-1/AC-4 (TR-voxel-world-029): [method VoxelWorldGrid.get_state]
##    transitions [enum VoxelWorldGrid.GridState] UNINITIALIZED -> GENERATED,
##    and every in-bounds cell ends up either terrain (contiguous from
##    `min_y` up through the column's height) or empty (above the height) —
##    "terrain or empty," never a gap.
## 2. AC-10 (TR-voxel-world-038/039): every computed terrain height stays
##    within `[min_y, max_y]` across a whole test extent, including an
##    extreme-amplitude stress case standing in for "noise2D returning ±1"
##    (QA plan AC-1 edge case) — the height formula's own `clamp()` is the
##    only thing relied on, never a second special-cased bound.
## 3. AC-11 (TR-voxel-world-046): `base_height > max_y` logs exactly one
##    `push_warning` and the entire terrain clamps flat at `max_y` — no
##    crash.
## 4. AC-19 (TR-voxel-world-044): generation over a 64×64 test extent emits
##    [signal VoxelWorldGrid.cells_changed_batch] at most once and
##    [signal VoxelWorldGrid.cell_changed] zero times — the same direct
##    listener-capture pattern `bulk_write_batched_signal_test.gd` uses, not
##    `GdUnitSignalAssert.is_emitted()`.
## 5. Determinism (TR-voxel-world-039, ADR-0015 §5's deterministic-seeded-
##    regen premise): two separate [VoxelWorldGrid] instances generated with
##    the same [member VoxelWorldConfig.terrain_seed] produce byte-identical
##    terrain; two different seeds produce terrain that differs somewhere in
##    the sampled extent. Both fixed, hardcoded seed values — never
##    `randi()`/time-based (coding-standards.md's no-random-seeds rule is
##    about non-reproducible test inputs, not about the seed *value* under
##    test here).
## 6. Edge case: a zero-size world extent emits no batch signal (bulk_write's
##    existing "no batch of zero" contract) but still transitions state to
##    GENERATED.
##
## NOTE (accumulated pitfall): signal-fire counters use a captured [Array]
## with `.append()`/`.size()`, never a captured scalar `+= 1` inside a
## lambda — GDScript closures do not write back captured scalars.
class_name ProceduralTerrainGenerationTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Shared test helper — rederives a column's height from written cell data
# (topmost non-empty y), never duplicating VoxelWorldGrid's private height
# formula. Returns `config.min_y - 1` if the column is entirely empty
# (should never happen post-generation; a sentinel makes a bug loud instead
# of silently mis-comparing).
# ---------------------------------------------------------------------------

func _topmost_solid_y(grid: VoxelWorldGrid, config: VoxelWorldConfig, x: int, z: int) -> int:
	for y in range(config.max_y, config.min_y - 1, -1):
		if not grid.get_cell(Vector3i(x, y, z)).is_empty():
			return y
	return config.min_y - 1


# ---------------------------------------------------------------------------
# AC-1/AC-4 (TR-voxel-world-029) — state transition + terrain-or-empty fill
# ---------------------------------------------------------------------------

func test_generate_terrain_transitions_state_and_fills_columns_terrain_or_empty() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 16
	config.world_depth_cells = 16
	config.terrain_seed = 42
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	assert_int(grid.get_state()).is_equal(VoxelWorldGrid.GridState.UNINITIALIZED)

	# Act
	grid.generate_terrain()

	# Assert — state transition (AC-4).
	assert_int(grid.get_state()).is_equal(VoxelWorldGrid.GridState.GENERATED)

	# Assert — every column: contiguous terrain from min_y up through its
	# height, empty above (AC-1).
	for x in 16:
		for z in 16:
			var height: int = _topmost_solid_y(grid, config, x, z)
			assert_bool(height >= config.min_y).is_true()
			assert_bool(height <= config.max_y).is_true()
			for y in range(config.min_y, height + 1):
				assert_bool(grid.get_cell(Vector3i(x, y, z)).is_empty()).is_false()
			for y in range(height + 1, config.max_y + 1):
				assert_bool(grid.get_cell(Vector3i(x, y, z)).is_empty()).is_true()


# ---------------------------------------------------------------------------
# AC-10 (TR-voxel-world-038/039) — height always within [min_y, max_y]
# ---------------------------------------------------------------------------

func test_generate_terrain_height_always_within_min_y_max_y_bounds() -> void:
	# Arrange — QA plan AC-1 given values.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 40
	config.world_depth_cells = 40
	config.base_height = 4
	config.amplitude = 3.0
	config.frequency = 0.05
	config.min_y = 0
	config.max_y = 16
	config.terrain_seed = 2026
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act
	grid.generate_terrain()

	# Assert
	for x in 40:
		for z in 40:
			var height: int = _topmost_solid_y(grid, config, x, z)
			assert_bool(height >= config.min_y).is_true()
			assert_bool(height <= config.max_y).is_true()


func test_generate_terrain_extreme_amplitude_stress_case_stays_within_clamp() -> void:
	# Arrange — QA plan AC-1 edge case ("noise2D returning ±1 stays within
	# clamp"): amplitude=100 deliberately far beyond the GDD safe range
	# (0-8) forces `base_height + amplitude*noise` to swing far outside
	# [min_y, max_y] for most of the extent — every column relies entirely
	# on the formula's own clamp() to stay in bounds, nothing else.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 24
	config.world_depth_cells = 24
	config.base_height = 4
	config.amplitude = 100.0
	config.frequency = 0.05
	config.min_y = 0
	config.max_y = 16
	config.terrain_seed = 55
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act
	grid.generate_terrain()

	# Assert
	for x in 24:
		for z in 24:
			var height: int = _topmost_solid_y(grid, config, x, z)
			assert_bool(height >= config.min_y).is_true()
			assert_bool(height <= config.max_y).is_true()


# ---------------------------------------------------------------------------
# AC-11 (TR-voxel-world-046) — base_height > max_y clamps flat, one warning
# ---------------------------------------------------------------------------

func test_generate_terrain_misconfig_base_height_above_max_y_clamps_flat_and_warns() -> void:
	# Arrange — QA plan AC-2 given values; amplitude stays at the GDD
	# default (3.0), so `base_height - amplitude` (17) still exceeds `max_y`
	# (16) for every possible noise value in [-1, 1] — flatness at max_y is
	# guaranteed by the clamp alone, not a coincidence of this seed.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 8
	config.world_depth_cells = 8
	config.min_y = 0
	config.max_y = 16
	config.base_height = 20
	config.terrain_seed = 111
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config

	# Act + Assert — exactly the diagnostic warning, no crash.
	await assert_error(func() -> void: grid.generate_terrain()).is_push_warning(
		"VoxelWorldGrid.generate_terrain: base_height (20) exceeds max_y (16) -- terrain clamps flat at max_y"
	)

	# Assert — every column is flat at max_y (16).
	for x in 8:
		for z in 8:
			assert_int(_topmost_solid_y(grid, config, x, z)).is_equal(16)
	assert_int(grid.get_state()).is_equal(VoxelWorldGrid.GridState.GENERATED)


# ---------------------------------------------------------------------------
# AC-19 (TR-voxel-world-044) — at most one batched signal, zero per-cell
# ---------------------------------------------------------------------------

func test_generate_terrain_64x64_extent_emits_batch_signal_once_and_cell_changed_zero_times() -> void:
	# Arrange — listener attached BEFORE generation (QA plan AC-3).
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 64
	config.world_depth_cells = 64
	config.terrain_seed = 8
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var batch_received: Array = []
	var single_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))
	grid.cell_changed.connect(func(p_cell: Vector3i, before: CellContents, after: CellContents) -> void:
		single_received.append(p_cell))

	# Act
	grid.generate_terrain()

	# Assert
	assert_int(batch_received.size()).is_equal(1)
	assert_int(single_received.size()).is_equal(0)
	var payload: Array[CellChangeRecord] = batch_received[0]
	assert_bool(payload.size() > 0).is_true()


# ---------------------------------------------------------------------------
# Determinism — same seed byte-identical, different seed differs
# ---------------------------------------------------------------------------

func test_generate_terrain_same_seed_produces_byte_identical_terrain() -> void:
	# Arrange — two independent grids/configs, identical terrain_seed.
	var config_a := VoxelWorldConfig.new()
	config_a.world_width_cells = 20
	config_a.world_depth_cells = 20
	config_a.terrain_seed = 777
	var grid_a: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_a.config = config_a

	var config_b := VoxelWorldConfig.new()
	config_b.world_width_cells = 20
	config_b.world_depth_cells = 20
	config_b.terrain_seed = 777
	var grid_b: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_b.config = config_b

	# Act
	grid_a.generate_terrain()
	grid_b.generate_terrain()

	# Assert — byte-identical per cell across the whole extent.
	for x in 20:
		for z in 20:
			for y in range(config_a.min_y, config_a.max_y + 1):
				var cell := Vector3i(x, y, z)
				var a: CellContents = grid_a.get_cell(cell)
				var b: CellContents = grid_b.get_cell(cell)
				assert_int(a.block_type_id).is_equal(b.block_type_id)
				assert_int(a.material_id).is_equal(b.material_id)


func test_generate_terrain_different_seed_produces_different_terrain() -> void:
	# Arrange — two independent grids/configs, different (fixed, hardcoded)
	# terrain_seed values -- deterministic, not a random-seed test input.
	var config_a := VoxelWorldConfig.new()
	config_a.world_width_cells = 32
	config_a.world_depth_cells = 32
	config_a.terrain_seed = 111
	var grid_a: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_a.config = config_a

	var config_b := VoxelWorldConfig.new()
	config_b.world_width_cells = 32
	config_b.world_depth_cells = 32
	config_b.terrain_seed = 999
	var grid_b: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid_b.config = config_b

	# Act
	grid_a.generate_terrain()
	grid_b.generate_terrain()

	# Assert — at least one sampled column's height differs between seeds.
	var any_difference := false
	for x in 32:
		for z in 32:
			if _topmost_solid_y(grid_a, config_a, x, z) != _topmost_solid_y(grid_b, config_b, x, z):
				any_difference = true
				break
		if any_difference:
			break
	assert_bool(any_difference).is_true()


# ---------------------------------------------------------------------------
# Edge case — zero-size extent emits no signal but still transitions state
# ---------------------------------------------------------------------------

func test_generate_terrain_zero_extent_emits_no_signal_but_still_transitions_state() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 0
	config.world_depth_cells = 0
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = config
	var batch_received: Array = []
	grid.cells_changed_batch.connect(func(records: Array[CellChangeRecord]) -> void:
		batch_received.append(records))

	# Act
	grid.generate_terrain()

	# Assert
	assert_int(batch_received.size()).is_equal(0)
	assert_int(grid.get_state()).is_equal(VoxelWorldGrid.GridState.GENERATED)
