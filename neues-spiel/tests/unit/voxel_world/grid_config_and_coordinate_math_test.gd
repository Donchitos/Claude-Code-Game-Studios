## Unit test — Voxel World story vox-001 (grid config + coordinate math +
## bounds, ADR-0002 + ADR-0001).
##
## Proves, all against [VoxelWorldConfig] / [VoxelWorldGrid] / [CellQueryResult]:
## 1. AC (TR-voxel-world-012/016/023): [VoxelWorldConfig]'s fixed `cell_size`
##    constant, every knob's GDD default, and [method VoxelWorldConfig.validate]'s
##    two-tier clamp+warn / BLOCKING policy (`min_y <= max_y`).
## 2. AC (TR-voxel-world-035/036): [VoxelWorldGrid.cell_to_world] (cell
##    center) and [VoxelWorldGrid.world_to_cell] (`floor()` per axis, not
##    truncation) as pure, stateless, mutually-inverse functions.
## 3. AC (TR-voxel-world-027/037): [VoxelWorldGrid.is_in_bounds] (exact
##    non-negative integer comparisons, Core Rule 1) and
##    [VoxelWorldGrid.query_world_to_cell]'s explicit [CellQueryResult] —
##    never a silent clamp to the edge, never cell 0 for a negative
##    near-zero position.
## 4. The injected-tier wiring: [VoxelWorldGrid.setup] applying the two-tier
##    policy and reporting BLOCKING issues the same way
##    `ReferenceConfigConsumer` demonstrates (ADR-0002/ADR-0005).
class_name GridConfigAndCoordinateMathTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# VoxelWorldConfig — fixed cell_size + GDD defaults [TR-voxel-world-012/023]
# ---------------------------------------------------------------------------

func test_voxel_world_config_cell_size_is_fixed_constant_one() -> void:
	# Assert — TR-voxel-world-012: locked, not a knob (no @export on the class).
	assert_float(VoxelWorldConfig.CELL_SIZE).is_equal_approx(1.0, 0.0001)


func test_voxel_world_config_defaults_match_gdd_tuning_knobs() -> void:
	# Arrange + Act
	var config := VoxelWorldConfig.new()

	# Assert — design/gdd/voxel-world.md Tuning Knobs section.
	assert_int(config.world_width_cells).is_equal(2000)
	assert_int(config.world_depth_cells).is_equal(2000)
	assert_int(config.min_y).is_equal(0)
	assert_int(config.max_y).is_equal(16)
	assert_int(config.base_height).is_equal(4)
	assert_float(config.amplitude).is_equal_approx(3.0, 0.0001)
	assert_float(config.frequency).is_equal_approx(0.05, 0.0001)


func test_voxel_world_config_validate_gdd_defaults_returns_empty() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_array(issues).is_empty()


# ---------------------------------------------------------------------------
# VoxelWorldConfig.validate() — single-field clamp+warn tier
# ---------------------------------------------------------------------------

func test_voxel_world_config_validate_width_below_min_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 10

	# Act
	var issues: Array[String] = config.validate()

	# Assert — clamp+warn, boot proceeds, no blocking tag.
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_int(config.world_width_cells).is_equal(VoxelWorldConfig.WORLD_WIDTH_CELLS_MIN)


func test_voxel_world_config_validate_depth_above_max_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.world_depth_cells = 999999

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_int(config.world_depth_cells).is_equal(VoxelWorldConfig.WORLD_DEPTH_CELLS_MAX)


func test_voxel_world_config_validate_min_y_negative_clamps_to_floor_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.min_y = -5

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_int(config.min_y).is_equal(VoxelWorldConfig.MIN_Y_FLOOR)


func test_voxel_world_config_validate_max_y_out_of_range_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.max_y = 999

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_int(config.max_y).is_equal(VoxelWorldConfig.MAX_Y_MAX)


func test_voxel_world_config_validate_base_height_above_max_y_minus_one_clamps_and_warns() -> void:
	# Arrange — base_height's safe upper bound is dynamic (max_y - 1).
	var config := VoxelWorldConfig.new()
	config.max_y = 16
	config.base_height = 50

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_int(config.base_height).is_equal(15)


func test_voxel_world_config_validate_amplitude_below_min_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.amplitude = -1.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_float(config.amplitude).is_equal_approx(VoxelWorldConfig.AMPLITUDE_MIN, 0.0001)


func test_voxel_world_config_validate_frequency_above_max_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.frequency = 5.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_float(config.frequency).is_equal_approx(VoxelWorldConfig.FREQUENCY_MAX, 0.0001)


# ---------------------------------------------------------------------------
# VoxelWorldConfig — page_budget_ms/evict_budget_ms (Story vox-012,
# ADR-0015 Decision §1) defaults + validate() clamp+warn tier
# ---------------------------------------------------------------------------

func test_voxel_world_config_stream_budget_defaults_match_spike_validated_4ms() -> void:
	# Arrange + Act
	var config := VoxelWorldConfig.new()

	# Assert — ADR-0015 Decision §1: "validated at 4.0 ms each."
	assert_float(config.page_budget_ms).is_equal_approx(4.0, 0.0001)
	assert_float(config.evict_budget_ms).is_equal_approx(4.0, 0.0001)


func test_voxel_world_config_validate_page_budget_ms_below_min_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.page_budget_ms = -1.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.page_budget_ms).is_equal_approx(VoxelWorldConfig.STREAM_BUDGET_MS_MIN, 0.0001)


func test_voxel_world_config_validate_evict_budget_ms_above_max_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.evict_budget_ms = 999999.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.evict_budget_ms).is_equal_approx(VoxelWorldConfig.STREAM_BUDGET_MS_MAX, 0.0001)


# ---------------------------------------------------------------------------
# VoxelWorldConfig — mesh_build_budget_ms/mesh_unload_budget_ms (Story
# vox-015, ADR-0014 Decision §3 / ADR-0015 Decision §1) defaults + validate()
# clamp+warn tier
# ---------------------------------------------------------------------------

func test_voxel_world_config_mesh_stream_budget_defaults_match_spike_validated_4ms() -> void:
	# Arrange + Act
	var config := VoxelWorldConfig.new()

	# Assert — reuses the data tier's own spike-validated 4.0 ms as the
	# initial mesh-tier value, pending Story 016's own tuning pass.
	assert_float(config.mesh_build_budget_ms).is_equal_approx(4.0, 0.0001)
	assert_float(config.mesh_unload_budget_ms).is_equal_approx(4.0, 0.0001)


func test_voxel_world_config_validate_mesh_build_budget_ms_below_min_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.mesh_build_budget_ms = -1.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.mesh_build_budget_ms).is_equal_approx(VoxelWorldConfig.STREAM_BUDGET_MS_MIN, 0.0001)


func test_voxel_world_config_validate_mesh_unload_budget_ms_above_max_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.mesh_unload_budget_ms = 999999.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.mesh_unload_budget_ms).is_equal_approx(VoxelWorldConfig.STREAM_BUDGET_MS_MAX, 0.0001)


# ---------------------------------------------------------------------------
# VoxelWorldConfig — max_concurrent_async_tasks (Story vox-011, re-measured
# Story vox-016, ADR-0015 Decision §6 / carried tuning item C1) and
# max_chunk_generation_cost_ms (Story vox-016, new field) defaults +
# validate() clamp+warn tier
# ---------------------------------------------------------------------------

func test_voxel_world_config_max_concurrent_async_tasks_default_matches_vox016_measured_value() -> void:
	# Arrange + Act
	var config := VoxelWorldConfig.new()

	# Assert — Story vox-016 re-measured both spike caps (32, 64) against
	# production code and kept 32 (see the field's own doc comment for the
	# measured worst-frame numbers backing this decision).
	assert_int(config.max_concurrent_async_tasks).is_equal(32)


func test_voxel_world_config_validate_max_concurrent_async_tasks_below_min_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.max_concurrent_async_tasks = 0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_int(config.max_concurrent_async_tasks).is_equal(VoxelWorldConfig.MAX_CONCURRENT_ASYNC_TASKS_MIN)


func test_voxel_world_config_validate_max_concurrent_async_tasks_above_max_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.max_concurrent_async_tasks = 999999

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_int(config.max_concurrent_async_tasks).is_equal(VoxelWorldConfig.MAX_CONCURRENT_ASYNC_TASKS_MAX)


func test_voxel_world_config_max_chunk_generation_cost_ms_default_matches_vox016_measured_bound() -> void:
	# Arrange + Act
	var config := VoxelWorldConfig.new()

	# Assert — Story vox-016 recorded regression-guard bound (~4.7x headroom
	# over the measured p95 compute-only per-chunk cost of 0.212 ms; see the
	# field's own doc comment).
	assert_float(config.max_chunk_generation_cost_ms).is_equal_approx(1.0, 0.0001)


func test_voxel_world_config_validate_max_chunk_generation_cost_ms_below_min_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.max_chunk_generation_cost_ms = -1.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.max_chunk_generation_cost_ms).is_equal_approx(VoxelWorldConfig.CHUNK_GENERATION_COST_MS_MIN, 0.0001)


func test_voxel_world_config_validate_max_chunk_generation_cost_ms_above_max_clamps_and_warns() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.max_chunk_generation_cost_ms = 999999.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.max_chunk_generation_cost_ms).is_equal_approx(VoxelWorldConfig.CHUNK_GENERATION_COST_MS_MAX, 0.0001)


# ---------------------------------------------------------------------------
# VoxelWorldConfig.validate() — BLOCKING cross-value invariant (min_y <= max_y)
# ---------------------------------------------------------------------------

func test_voxel_world_config_validate_min_y_greater_than_max_y_is_blocking() -> void:
	# Arrange
	var config := VoxelWorldConfig.new()
	config.min_y = 20
	config.max_y = 16

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_voxel_world_config_validate_min_y_equal_max_y_is_not_blocking() -> void:
	# Arrange — the invariant is "<=", so equal bounds are valid (single-height
	# world), unlike ReferenceModuleConfig's strict "<" precedent.
	#
	# Fixture sweep (story vox-022): the GDD-defaulted band_boundaries ([2, 4,
	# 5]) are absolute Y literals computed against the SHIPPED [0, 16] extent
	# -- a degenerate single-Y-height world (min_y == max_y == 8) can never
	# host 3 strictly-increasing boundaries inside a single point, so this
	# fixture now ALSO reduces to one band (band_ids=[1], no boundaries) —
	# the sprint's own descope-ladder shape ("reduce the band count, never
	# the mechanism") — to isolate the min_y<=max_y invariant this test
	# actually targets from the new, unrelated band cross-value check.
	var config := VoxelWorldConfig.new()
	config.min_y = 8
	config.max_y = 8
	config.band_ids = [1]
	config.band_boundaries = []

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()


func test_voxel_world_config_validate_warning_alongside_blocking_still_dominates() -> void:
	# Arrange — a single-field warning AND a blocking failure in the same
	# validate() call: blocking must still be detected (QA plan edge case).
	#
	# Fixture sweep (story vox-022): the GDD-defaulted band_boundaries ([2, 4,
	# 5]) fall outside this fixture's deliberately-invalid `min_y=20` -- also
	# reduced to one band (band_ids=[1], no boundaries) so the issue COUNT
	# this test asserts stays scoped to exactly the two invariants under
	# test (the width clamp + the min_y > max_y blocking), never inflated by
	# an unrelated band-boundary-range violation this fixture never intended
	# to exercise.
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 10
	config.min_y = 20
	config.max_y = 16
	config.band_ids = [1]
	config.band_boundaries = []

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(2)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()
	assert_int(config.world_width_cells).is_equal(VoxelWorldConfig.WORLD_WIDTH_CELLS_MIN)


# ---------------------------------------------------------------------------
# Cell->World (AC-5, TR-voxel-world-035) — cell center, pure + stateless
# ---------------------------------------------------------------------------

func test_cell_to_world_gdd_worked_example() -> void:
	# Arrange + Act — GDD Formulas worked example: cell (2,0,5).
	var world_pos: Vector3 = VoxelWorldGrid.cell_to_world(Vector3i(2, 0, 5))

	# Assert
	assert_vector(world_pos).is_equal_approx(Vector3(2.5, 0.5, 5.5), Vector3(0.0001, 0.0001, 0.0001))


func test_cell_to_world_origin_cell_returns_center_offset_by_half() -> void:
	# Arrange + Act
	var world_pos: Vector3 = VoxelWorldGrid.cell_to_world(Vector3i(0, 0, 0))

	# Assert
	assert_vector(world_pos).is_equal_approx(Vector3(0.5, 0.5, 0.5), Vector3(0.0001, 0.0001, 0.0001))


func test_cell_to_world_recomputed_twice_yields_identical_value() -> void:
	# Arrange + Act — same input, two separate calls (no caching anywhere).
	var first: Vector3 = VoxelWorldGrid.cell_to_world(Vector3i(2, 0, 5))
	var second: Vector3 = VoxelWorldGrid.cell_to_world(Vector3i(2, 0, 5))

	# Assert
	assert_vector(first).is_equal(second)


# ---------------------------------------------------------------------------
# World->Cell (AC-4, TR-voxel-world-036) — floor() per axis, not truncation
# ---------------------------------------------------------------------------

func test_world_to_cell_uses_floor_not_truncation_near_zero() -> void:
	# Arrange + Act — a ray grazing the world edge at x = -0.001 (GDD example).
	var cell: Vector3i = VoxelWorldGrid.world_to_cell(Vector3(-0.001, 0.5, 0.5))

	# Assert — floor() maps this to -1, never aliased into cell 0.
	assert_int(cell.x).is_equal(-1)


func test_world_to_cell_round_trip_center_point_returns_same_cell() -> void:
	# Arrange + Act — GDD worked example: Cell->World of (2,0,5) is (2.5,0.5,5.5).
	var cell: Vector3i = VoxelWorldGrid.world_to_cell(Vector3(2.5, 0.5, 5.5))

	# Assert
	assert_vector(Vector3(cell)).is_equal(Vector3(2, 0, 5))


func test_world_to_cell_round_trip_lower_boundary_point_returns_same_cell() -> void:
	# Arrange + Act — a point exactly on the cell's lower boundary.
	var cell: Vector3i = VoxelWorldGrid.world_to_cell(Vector3(2.0, 0.0, 5.0))

	# Assert
	assert_vector(Vector3(cell)).is_equal(Vector3(2, 0, 5))


func test_world_to_cell_round_trip_near_upper_boundary_point_returns_same_cell() -> void:
	# Arrange + Act — a point just shy of the next cell's boundary.
	var cell: Vector3i = VoxelWorldGrid.world_to_cell(Vector3(2.999, 0.999, 5.999))

	# Assert
	assert_vector(Vector3(cell)).is_equal(Vector3(2, 0, 5))


func test_world_to_cell_upper_boundary_point_floors_into_next_cell() -> void:
	# Arrange + Act — a point exactly ON the next cell's boundary — floor()
	# semantics put it in cell 3, not cell 2.
	var cell: Vector3i = VoxelWorldGrid.world_to_cell(Vector3(3.0, 0.0, 5.0))

	# Assert
	assert_int(cell.x).is_equal(3)


func test_world_to_cell_origin_cell_round_trips() -> void:
	# Arrange + Act
	var cell: Vector3i = VoxelWorldGrid.world_to_cell(VoxelWorldGrid.cell_to_world(Vector3i(0, 0, 0)))

	# Assert
	assert_vector(Vector3(cell)).is_equal(Vector3.ZERO)


func test_world_to_cell_recomputed_twice_yields_identical_value() -> void:
	# Arrange + Act
	var first: Vector3i = VoxelWorldGrid.world_to_cell(Vector3(2.5, 0.5, 5.5))
	var second: Vector3i = VoxelWorldGrid.world_to_cell(Vector3(2.5, 0.5, 5.5))

	# Assert
	assert_vector(Vector3(first)).is_equal(Vector3(second))


# ---------------------------------------------------------------------------
# is_in_bounds (Core Rule 1, TR-voxel-world-027) — exact, non-negative
# ---------------------------------------------------------------------------

func test_is_in_bounds_origin_cell_is_in_bounds() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act + Assert
	assert_bool(grid.is_in_bounds(Vector3i(0, 0, 0))).is_true()


func test_is_in_bounds_negative_x_is_out_of_bounds() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act + Assert
	assert_bool(grid.is_in_bounds(Vector3i(-1, 0, 0))).is_false()


func test_is_in_bounds_x_equal_width_is_out_of_bounds() -> void:
	# Arrange — width is an exclusive upper bound (valid indices 0..width-1).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	grid.config = config

	# Act + Assert
	assert_bool(grid.is_in_bounds(Vector3i(256, 0, 0))).is_false()


func test_is_in_bounds_x_just_below_width_is_in_bounds() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	grid.config = config

	# Act + Assert
	assert_bool(grid.is_in_bounds(Vector3i(255, 0, 0))).is_true()


func test_is_in_bounds_y_below_min_y_is_out_of_bounds() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act + Assert
	assert_bool(grid.is_in_bounds(Vector3i(0, -1, 0))).is_false()


func test_is_in_bounds_y_above_max_y_is_out_of_bounds() -> void:
	# Arrange — GDD default max_y = 16.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act + Assert
	assert_bool(grid.is_in_bounds(Vector3i(0, 17, 0))).is_false()


func test_is_in_bounds_y_equal_max_y_is_in_bounds() -> void:
	# Arrange — max_y is an inclusive upper bound (matches the terrain height
	# formula's own inclusive clamp range).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act + Assert
	assert_bool(grid.is_in_bounds(Vector3i(0, 16, 0))).is_true()


func test_is_in_bounds_missing_config_raises_assertion() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())

	# Act + Assert
	await assert_error(func() -> void: grid.is_in_bounds(Vector3i.ZERO)).is_runtime_error(
		"Assertion failed: VoxelWorldGrid.config not wired"
	)


# ---------------------------------------------------------------------------
# query_world_to_cell (AC-1/AC-3, TR-voxel-world-037) — explicit sentinel
# ---------------------------------------------------------------------------

func test_query_world_to_cell_x_zero_is_in_bounds() -> void:
	# Arrange — QA plan edge case: exactly x=0.0 is in.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var result: CellQueryResult = grid.query_world_to_cell(Vector3(0.0, 0.5, 0.5))

	# Assert
	assert_bool(result.in_bounds).is_true()
	assert_vector(Vector3(result.cell)).is_equal(Vector3.ZERO)


func test_query_world_to_cell_x_negative_epsilon_returns_outside_grid_never_cell_zero() -> void:
	# Arrange — QA plan AC-1: x = -0.001 must return the explicit outside-grid
	# result, never cell 0.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var result: CellQueryResult = grid.query_world_to_cell(Vector3(-0.001, 0.5, 0.5))

	# Assert
	assert_bool(result.in_bounds).is_false()
	assert_int(result.cell.x).is_equal(-1)
	assert_int(result.cell.x).is_not_equal(0)


func test_query_world_to_cell_x_at_world_width_returns_outside_grid_never_clamped_edge() -> void:
	# Arrange — QA plan AC-1: x = W+1 (well past the edge) must return the
	# explicit outside-grid result, never a clamped edge cell (width-1).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	grid.config = config

	# Act
	var result: CellQueryResult = grid.query_world_to_cell(Vector3(257.0, 0.5, 0.5))

	# Assert
	assert_bool(result.in_bounds).is_false()
	assert_int(result.cell.x).is_equal(257)
	assert_int(result.cell.x).is_not_equal(255)


func test_query_world_to_cell_x_exactly_at_width_boundary_returns_outside_grid() -> void:
	# Arrange — QA plan AC-1 edge case: x = W*cell_size is out (exclusive
	# upper bound).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	grid.config = config

	# Act
	var result: CellQueryResult = grid.query_world_to_cell(Vector3(256.0, 0.5, 0.5))

	# Assert
	assert_bool(result.in_bounds).is_false()


func test_query_world_to_cell_y_below_min_y_returns_outside_grid() -> void:
	# Arrange — QA plan AC-1 edge case: y below min_y.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var result: CellQueryResult = grid.query_world_to_cell(Vector3(0.5, -1.0, 0.5))

	# Assert
	assert_bool(result.in_bounds).is_false()


func test_query_world_to_cell_y_above_max_y_returns_outside_grid() -> void:
	# Arrange — QA plan AC-1 edge case: y above max_y.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var result: CellQueryResult = grid.query_world_to_cell(Vector3(0.5, 17.0, 0.5))

	# Assert
	assert_bool(result.in_bounds).is_false()


func test_query_world_to_cell_inside_cell_returns_correct_cell_and_in_bounds_true() -> void:
	# Arrange — QA plan AC-2: any point inside cell (2,0,5) resolves back to it.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var result: CellQueryResult = grid.query_world_to_cell(Vector3(2.5, 0.5, 5.5))

	# Assert
	assert_bool(result.in_bounds).is_true()
	assert_vector(Vector3(result.cell)).is_equal(Vector3(2, 0, 5))


# ---------------------------------------------------------------------------
# CellQueryResult — plain construction contract
# ---------------------------------------------------------------------------

func test_cell_query_result_stores_in_bounds_and_cell_from_init() -> void:
	# Arrange + Act
	var result := CellQueryResult.new(true, Vector3i(2, 0, 5))

	# Assert
	assert_bool(result.in_bounds).is_true()
	assert_vector(Vector3(result.cell)).is_equal(Vector3(2, 0, 5))


# ---------------------------------------------------------------------------
# VoxelWorldGrid.setup() — the injected-tier wiring
# ---------------------------------------------------------------------------

func test_voxel_world_grid_setup_valid_config_no_blocking_issues() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	grid.setup()

	# Assert
	assert_bool(grid.is_set_up()).is_true()
	assert_array(grid.get_boot_blocking_issues()).is_empty()


func test_voxel_world_grid_setup_out_of_range_scalar_clamps_no_blocking() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.frequency = 5.0
	grid.config = config

	# Act
	grid.setup()

	# Assert — clamp+warn tier: setup completes, no blocking issues reported.
	assert_bool(grid.is_set_up()).is_true()
	assert_array(grid.get_boot_blocking_issues()).is_empty()
	assert_float(config.frequency).is_equal_approx(VoxelWorldConfig.FREQUENCY_MAX, 0.0001)


func test_voxel_world_grid_setup_blocking_invariant_reports_issue() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.min_y = 20
	config.max_y = 16
	grid.config = config

	# Act
	grid.setup()

	# Assert
	assert_bool(grid.is_set_up()).is_true()
	assert_bool(ConfigResource.has_blocking_issue(grid.get_boot_blocking_issues())).is_true()


func test_voxel_world_grid_setup_missing_config_raises_assertion() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())

	# Act + Assert
	await assert_error(func() -> void: grid.setup()).is_runtime_error(
		"Assertion failed: VoxelWorldGrid.config not wired"
	)
