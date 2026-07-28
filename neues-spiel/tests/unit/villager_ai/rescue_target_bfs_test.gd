## Unit test — Villager AI story villager-ai-014 (F5 rescue-target BFS,
## expanding-ring search, GDD F5 / Rule 15b / [TR-villager-ai-behavior-100]).
##
## Proves, against [VillagerRescueTargetSearch.find_rescue_target] (real
## [VillagerAi]/[VoxelWorldGrid] fixtures, no duck-typed predicate seam --
## mirrors job_selection_f2_test.gd's own "no mocked pathfinding" precedent):
## 1. **AC (nearest standable)**: a standable, unoccupied cell 2 rings away is
##    found when every ring-1 cell is non-standable.
## 2. **AC (tie-break)**: two equidistant valid cells resolve to the
##    lexicographically (y, x, z) smaller one, identically across repeated
##    calls (determinism, not "usually the same cell").
## 3. **Occupancy — body-column, not feet-only**: a candidate excluded by
##    body-column overlap with another villager's `current_cell` even when
##    the two FEET cells differ (the exact defect a feet-only `==` check
##    would miss, per GDD Rule 8a / this story's Implementation Notes).
## 4. **Determinism**: repeated calls with identical inputs yield an
##    identical chosen cell.
## 5. **Edge case — search exhausted**: no eligible cell anywhere within
##    `max_radius` returns a not-found result, never an error.
## 6. **Ring-0 exclusion (this story's own documented interpretation)**: the
##    stuck cell itself is never returned as its own rescue target, even when
##    it is itself standable and unoccupied.
class_name RescueTargetBfsTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures (declared above the test functions, this codebase's own
# GdUnit4 convention — see astar_graph_test.gd / job_selection_f2_test.gd).
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


## Places a standable cell at `cell` by adding solid floor directly beneath
## it — mirrors astar_graph_test.gd/job_selection_f2_test.gd's own "solid at
## y-1, empty above" convention, applied to one specific cell rather than a
## whole platform (this file deliberately keeps grids sparse so only the
## cells a test explicitly places are ever standable — see class doc comment
## on why that is load-bearing for the "2 rings away" fixture).
func _make_standable(grid: VoxelWorldGrid, cell: Vector3i) -> void:
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid())


# ---------------------------------------------------------------------------
# AC (nearest standable) — a standable, unoccupied cell 2 rings away is found
# ---------------------------------------------------------------------------

func test_find_rescue_target_returns_nearest_standable_unoccupied_cell_two_rings_away() -> void:
	# Arrange — a sparse grid: every ring-1 (Chebyshev distance 1) cell around
	# stuck_cell has no floor at all (never standable, by construction —
	# nothing else is placed there), and exactly one ring-2 cell has a floor.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(10, 1, 10)
	var target := Vector3i(12, 1, 10)  # Chebyshev distance 2 from stuck_cell.
	_make_standable(grid, target)

	# Act
	var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, [], 6, 24
	)

	# Assert
	assert_bool(result.has_target()).is_true()
	assert_vector(result.cell).is_equal(target)


# ---------------------------------------------------------------------------
# AC (tie-break) — lexicographic (y, x, z), deterministic across runs
# ---------------------------------------------------------------------------

func test_find_rescue_target_tie_break_uses_lexicographic_y_x_z_order() -> void:
	# Arrange — two standable, unoccupied cells at the SAME Chebyshev distance
	# (1) from stuck_cell. Same y; x=10 sorts before x=11, so the (10,1,9)
	# cell must win over (11,1,10) even though nothing about physical
	# distance distinguishes them.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(10, 1, 10)
	var lexicographically_smaller := Vector3i(10, 1, 9)
	var lexicographically_larger := Vector3i(11, 1, 10)
	_make_standable(grid, lexicographically_smaller)
	_make_standable(grid, lexicographically_larger)

	# Act
	var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, [], 6, 24
	)

	# Assert
	assert_bool(result.has_target()).is_true()
	assert_vector(result.cell).is_equal(lexicographically_smaller)


func test_find_rescue_target_is_deterministic_across_repeated_calls() -> void:
	# Arrange — same tie-break setup as above; call twice.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(10, 1, 10)
	_make_standable(grid, Vector3i(10, 1, 9))
	_make_standable(grid, Vector3i(11, 1, 10))

	# Act
	var first: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, [], 6, 24
	)
	var second: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, [], 6, 24
	)

	# Assert
	assert_vector(first.cell).is_equal(second.cell)
	assert_bool(first.found).is_equal(second.found)


# ---------------------------------------------------------------------------
# Occupancy — body-column overlap, not a feet-only `==` comparison
# ---------------------------------------------------------------------------

func test_find_rescue_target_excludes_a_cell_occupied_via_body_column_overlap_not_feet_equality() -> void:
	# Arrange — the nearest standable cell (11,1,10) is NOT occupied by a
	# feet-cell match (no other villager stands exactly there), but another
	# villager's OWN feet cell is (11,2,10) -- one cell directly ABOVE it.
	# That other villager's body-column ((11,2,10),(11,3,10),(11,4,10))
	# overlaps this candidate's own body-column ((11,1,10),(11,2,10),
	# (11,3,10)) at (11,2,10)/(11,3,10) -- a feet-only `==` check would wrongly
	# call this cell free. A second, farther standable+unoccupied cell proves
	# the search correctly moved past the occupied one.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(10, 1, 10)
	var occupied_via_body_column := Vector3i(11, 1, 10)  # Chebyshev distance 1.
	var free_cell := Vector3i(13, 1, 10)  # Chebyshev distance 3.
	_make_standable(grid, occupied_via_body_column)
	_make_standable(grid, free_cell)
	var other_villager_cells: Array[Vector3i] = [Vector3i(11, 2, 10)]

	# Act
	var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, other_villager_cells, 6, 24
	)

	# Assert — the feet-cell-only candidate is skipped; the farther free cell
	# wins instead.
	assert_bool(result.has_target()).is_true()
	assert_vector(result.cell).is_equal(free_cell)


# ---------------------------------------------------------------------------
# Edge case — search exhausted at max_radius, nothing anywhere is eligible
# ---------------------------------------------------------------------------

func test_find_rescue_target_returns_not_found_when_nothing_is_standable_within_max_radius() -> void:
	# Arrange — a completely empty grid: no cell anywhere is standable.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(10, 1, 10)

	# Act
	var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, [], 3, 6
	)

	# Assert
	assert_bool(result.has_target()).is_false()


# ---------------------------------------------------------------------------
# Ring-0 exclusion — the stuck cell itself is never its own rescue target
# ---------------------------------------------------------------------------

func test_find_rescue_target_never_returns_the_stuck_cell_itself() -> void:
	# Arrange — the stuck cell IS standable and unoccupied (the "walled in on
	# an otherwise-fine cell" case, GDD Rule 15's zero-legal-step trigger),
	# and nothing else anywhere is standable within the search bound. A
	# same-cell "rescue" would be a no-op that never actually frees a walled-in
	# villager (see VillagerRescueTargetSearch's own doc comment) -- the
	# search must report not-found here, not the stuck cell.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(10, 1, 10)
	_make_standable(grid, stuck_cell)

	# Act
	var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, [], 3, 6
	)

	# Assert
	assert_bool(result.has_target()).is_false()
