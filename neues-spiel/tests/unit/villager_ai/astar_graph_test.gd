## Unit test — Villager AI story 007 (AStar3D graph build & shortest-path
## query, ADR-0007 Decision Section 2).
##
## Proves, all against [VillagerNavGraph]:
## 1. **Build** (QA plan): a point exists for every standable cell in the
##    bounded region (via [VillagerAi.is_standable]), and none for cells
##    outside the region bound (AC5: "scoped to the settlement-core region,
##    never the full world") or non-standable cells inside it.
## 2. **Connections** (QA plan): a direct connection exists for every
##    legal-step pair (via [VillagerAi.is_step_legal]) and NONE for an
##    illegal one -- both illegality reasons (height difference > 1, a
##    blocked diagonal flanker/corner-cut) are covered independently.
## 3. **Deterministic IDs** (AC): [VillagerNavGraph.cell_to_astar_id] always
##    returns the identical id for the same cell, distinct ids for distinct
##    cells, and round-trips through [VillagerNavGraph.astar_id_to_cell].
## 4. **Path cost** (AC): [VillagerNavGraph.find_path]/[VillagerNavGraph.
##    path_length_cells] reflect F1's ~1.0 orthogonal / ~1.4 diagonal
##    weighting (AStar3D's own Euclidean cost between cell-center positions,
##    no `_compute_cost` override, per ADR-0007's own Key Interfaces note); a
##    target on the current/adjacent cell yields length `0.0`.
## 5. **F1 formulas** (AC): [VillagerNavGraph.travel_time_game_seconds] --
##    `path_length_cells / move_speed`, with `0` length short-circuiting to
##    immediate arrival regardless of `move_speed`.
## 6. **Edge cases** (QA plan): an unreachable target (no connecting path)
##    returns an empty path.
class_name AstarGraphTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _make_villager_ai(grid: VoxelWorldGrid) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.voxel_world = grid
	return villager_ai


func _solid() -> CellContents:
	return CellContents.new(1, 0)


## Fills a flat, uniform-height standable platform: solid ground at y=0 for
## every (x, z) in `[0, size)` x `[0, size)`, leaving y=1 (and above, up to
## the config default `max_y`) empty -- every (x, 1, z) in that footprint is
## standable by construction (full 3-cell clearance, nothing else placed
## anywhere in the grid).
func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), _solid())


# ---------------------------------------------------------------------------
# Build — points for every standable cell, none for out-of-bound/non-
# standable cells
# ---------------------------------------------------------------------------

func test_build_adds_point_for_every_standable_cell_in_a_flat_platform() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()

	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)

	for x in range(3):
		for z in range(3):
			assert_bool(graph.has_point(Vector3i(x, 1, z))).override_failure_message(
				"expected a point at (%s,1,%s)" % [x, z]
			).is_true()
	assert_bool(graph.is_built()).is_true()


func test_build_excludes_a_column_with_no_ground_below() -> void:
	# Arrange — a 3x3 platform with one column's ground missing: (1,0,1) is
	# never written, so (1,1,1) fails "solid below" and is not standable.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	grid.clear_cell(Vector3i(1, 0, 1))
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()

	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)

	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_false()
	assert_bool(graph.has_point(Vector3i(0, 1, 0))).is_true()


func test_build_scopes_points_to_the_region_bound_never_the_full_world() -> void:
	# Arrange — AC5: a 5x5 platform (every column standable), but the graph is
	# built over only the inner 3x3 window (region_size=3, centered at
	# (2,0,2), covering x/z in [1,3]) — a standable cell just OUTSIDE that
	# window must be excluded even though it IS standable in the underlying
	# world.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 5)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()

	graph.build(grid, villager_ai, Vector3i(2, 0, 2), 3)

	# Inside the bound (region edge, inclusive) — included.
	assert_bool(graph.has_point(Vector3i(1, 1, 1))).is_true()
	assert_bool(graph.has_point(Vector3i(3, 1, 3))).is_true()
	# Outside the bound — excluded, despite being standable in the world.
	assert_bool(graph.has_point(Vector3i(0, 1, 0))).is_false()
	assert_bool(graph.has_point(Vector3i(4, 1, 4))).is_false()


# ---------------------------------------------------------------------------
# Connections — legal-step pairs connected, illegal pairs are not
# ---------------------------------------------------------------------------

func test_build_connects_orthogonal_and_diagonal_legal_steps() -> void:
	# Arrange — a fully open, uniform-height 3x3 platform: every diagonal's
	# flanking cells are standable, so every orthogonal AND diagonal
	# neighbor pair is legal (GDD Rule 9).
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()

	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)

	# Orthogonal
	assert_bool(graph.has_direct_connection(Vector3i(0, 1, 0), Vector3i(1, 1, 0))).is_true()
	# Diagonal (both flankers standable)
	assert_bool(graph.has_direct_connection(Vector3i(0, 1, 0), Vector3i(1, 1, 1))).is_true()


func test_build_omits_connection_for_height_difference_of_two() -> void:
	# Arrange — two isolated standable cells, adjacent horizontally, but 2
	# cells apart vertically (illegal, GDD Rule 9's max_step_height=1).
	# Nothing else in the grid is standable, so the pair is also fully
	# unreachable via any indirect route.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid())  # -> (0,1,0) standable
	grid.set_cell(Vector3i(1, 2, 0), _solid())  # -> (1,3,0) standable
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()

	graph.build(grid, villager_ai, Vector3i(0, 0, 0), 4)

	var cell_a := Vector3i(0, 1, 0)
	var cell_b := Vector3i(1, 3, 0)
	assert_bool(graph.has_point(cell_a)).is_true()
	assert_bool(graph.has_point(cell_b)).is_true()
	assert_bool(graph.has_direct_connection(cell_a, cell_b)).is_false()
	assert_array(graph.find_path(cell_a, cell_b)).is_empty()


func test_build_omits_diagonal_connection_when_a_flanker_is_blocked() -> void:
	# Arrange — two standable cells diagonal to each other; one of the two
	# flanking corner cells has no ground below it at all (not standable),
	# so the diagonal is corner-cutting and illegal (GDD Rule 9) even though
	# both endpoints themselves are standable and become points.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid())  # -> (0,1,0) standable (from)
	grid.set_cell(Vector3i(1, 0, 1), _solid())  # -> (1,1,1) standable (to)
	grid.set_cell(Vector3i(0, 0, 1), _solid())  # -> flanker (0,1,1) standable
	# flanker (1,1,0) has no ground at (1,0,0) -- not standable, blocks the
	# diagonal corner.
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()

	graph.build(grid, villager_ai, Vector3i(0, 0, 0), 4)

	var from_cell := Vector3i(0, 1, 0)
	var to_cell := Vector3i(1, 1, 1)
	assert_bool(graph.has_point(from_cell)).is_true()
	assert_bool(graph.has_point(to_cell)).is_true()
	assert_bool(graph.has_direct_connection(from_cell, to_cell)).is_false()


# ---------------------------------------------------------------------------
# Deterministic IDs — same cell -> same id, distinct cells -> distinct ids,
# round-trips
# ---------------------------------------------------------------------------

func test_cell_to_astar_id_repeated_calls_yield_identical_id() -> void:
	var cell := Vector3i(12, 3, 47)
	var first: int = VillagerNavGraph.cell_to_astar_id(cell)
	var second: int = VillagerNavGraph.cell_to_astar_id(cell)
	assert_int(first).is_equal(second)


func test_cell_to_astar_id_distinct_cells_across_region_bound_yield_distinct_ids() -> void:
	# Arrange — a representative sample spanning the ADR-0007 measured
	# nav_region_size ceiling (200) plus a couple of boundary/high-Y values.
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0),
		Vector3i(199, 199, 16),
		Vector3i(100, 8, 50),
		Vector3i(0, 16, 199),
		Vector3i(199, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, 0, 1),
	]
	var seen_ids: Dictionary = {}
	for cell: Vector3i in cells:
		var id: int = VillagerNavGraph.cell_to_astar_id(cell)
		assert_bool(seen_ids.has(id)).override_failure_message(
			"id collision for cell %s (id %s)" % [cell, id]
		).is_false()
		seen_ids[id] = cell


func test_astar_id_round_trips_back_to_the_originating_cell() -> void:
	var cells: Array[Vector3i] = [
		Vector3i(0, 0, 0),
		Vector3i(199, 16, 199),
		Vector3i(42, 7, 13),
	]
	for cell: Vector3i in cells:
		var id: int = VillagerNavGraph.cell_to_astar_id(cell)
		var round_tripped: Vector3i = VillagerNavGraph.astar_id_to_cell(id)
		assert_vector(Vector3(round_tripped)).override_failure_message(
			"round-trip mismatch for cell %s (id %s) -> %s" % [cell, id, round_tripped]
		).is_equal(Vector3(cell))


# ---------------------------------------------------------------------------
# Path cost — ~1.0 orthogonal / ~1.4 diagonal weighting; zero-length =
# immediate arrival; unreachable = empty path
# ---------------------------------------------------------------------------

func test_find_path_prefers_diagonal_shortcut_and_length_reflects_1_4_weighting() -> void:
	# Arrange — a fully open 3x3 platform: the diagonal shortcut from corner
	# to corner (2 diagonal steps, length ~2.8) is strictly cheaper than the
	# orthogonal Manhattan route (4 steps, length 4.0), so AStar3D's own
	# default Euclidean cost (no _compute_cost override, ADR-0007) must
	# choose it.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)

	var path: Array[Vector3i] = graph.find_path(Vector3i(0, 1, 0), Vector3i(2, 1, 2))

	assert_array(path).contains_exactly([
		Vector3i(0, 1, 0), Vector3i(1, 1, 1), Vector3i(2, 1, 2),
	])
	assert_float(VillagerNavGraph.path_length_cells(path)).is_equal_approx(2.8, 0.01)


func test_find_path_same_cell_returns_single_element_path_with_zero_length() -> void:
	# Arrange — F1: "target is the current/adjacent cell -> immediate
	# arrival," path_length_cells == 0.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)

	var same_cell := Vector3i(1, 1, 1)
	var path: Array[Vector3i] = graph.find_path(same_cell, same_cell)

	assert_array(path).contains_exactly([same_cell])
	assert_float(VillagerNavGraph.path_length_cells(path)).is_equal(0.0)


func test_find_path_unreachable_target_returns_empty_path() -> void:
	# Arrange — two standable cells with no legal step and no other cells
	# to route through (same fixture as the height-difference connection
	# test) — QA plan edge case: "unreachable target returns an empty path."
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid())
	grid.set_cell(Vector3i(1, 2, 0), _solid())
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(0, 0, 0), 4)

	var path: Array[Vector3i] = graph.find_path(Vector3i(0, 1, 0), Vector3i(1, 3, 0))

	assert_array(path).is_empty()
	assert_float(VillagerNavGraph.path_length_cells(path)).is_equal(0.0)


func test_find_path_returns_empty_when_an_endpoint_was_never_a_point() -> void:
	# Arrange — a cell that is never standable anywhere in the grid (no
	# ground at all) was never added as a point.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, Vector3i(1, 0, 1), 3)

	var path: Array[Vector3i] = graph.find_path(Vector3i(0, 1, 0), Vector3i(50, 1, 50))

	assert_array(path).is_empty()


# ---------------------------------------------------------------------------
# F1 formulas — path_length_cells summation, travel_time_game_seconds
# ---------------------------------------------------------------------------

func test_path_length_cells_empty_path_returns_zero() -> void:
	var empty_path: Array[Vector3i] = []
	assert_float(VillagerNavGraph.path_length_cells(empty_path)).is_equal(0.0)


func test_path_length_cells_sums_mixed_orthogonal_and_diagonal_steps() -> void:
	var path: Array[Vector3i] = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(2, 1, 1),
	]
	# Step 1: (0,0,0)->(1,0,0) orthogonal = 1.0. Step 2: (1,0,0)->(2,1,1)
	# diagonal (dx=1, dz=1; dy irrelevant to F1) = 1.4. Total = 2.4.
	assert_float(VillagerNavGraph.path_length_cells(path)).is_equal_approx(2.4, 0.001)


func test_travel_time_game_seconds_zero_length_yields_immediate_arrival() -> void:
	assert_float(VillagerNavGraph.travel_time_game_seconds(0.0, 3.0)).is_equal(0.0)


func test_travel_time_game_seconds_computes_length_over_move_speed() -> void:
	# 12-step path at move_speed 3.0 -> 4.0 game-seconds (F1 worked example).
	assert_float(VillagerNavGraph.travel_time_game_seconds(12.0, 3.0)).is_equal_approx(4.0, 0.0001)
