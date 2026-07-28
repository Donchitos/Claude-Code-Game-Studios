## Unit test — Villager AI story villager-ai-010 (F2 job selection,
## nearest-reachable, bounded candidates, GDD F2 / ADR-0007 Decision
## Section 2).
##
## Proves, against [VillagerJobSelector.select_job] (real [VillagerNavGraph]
## / [VoxelWorldGrid] / [VillagerAi] fixtures, no duck-typed pathfinding
## seam per ADR-0007's "one shared graph, one consumer path"):
## 1. **AC6**: among the Chebyshev-nearest `job_candidate_count` candidates,
##    the true-path-nearest wins; a path-length TIE resolves by commit
##    order (original queue/array position), NOT by coordinate -- proven by
##    deliberately picking a queue order that DISAGREES with the
##    lexicographic order, so a coordinate-only comparator would pick the
##    wrong winner. Also proves determinism across two separate calls with
##    identical inputs.
## 2. **AC6 (lexicographic sub-clause)**: [VillagerJobSelector.
##    lexicographic_cell_less_than] itself -- GDD F2's "(y, then x, then z)"
##    same-command tie-break -- proven directly, since today's real
##    [ConstructionJobQueue] can never produce two candidates sharing one
##    queue-order key (see [VillagerJobSelector]'s own class doc comment for
##    why).
## 3. **AC7**: when a round's candidates all fail the true-path check, the
##    next round is tried, in order, until a reachable candidate is found or
##    the `max_selection_candidates` cap is spent -- `pathfind_attempt_count`
##    reflects exactly how many true-path checks ran, never more than the
##    cap.
## 4. **Edge case**: exactly `max_selection_candidates` candidates all fail
##    -> fall-through (`chosen == null`), and a candidate sitting just past
##    the cap is never attempted at all (attempt count stays AT the cap, not
##    cap + 1).
## 5. **Edge case**: a queue that is non-empty but every candidate is
##    unreachable -> fall-through, no error.
## 6. **"Available" contract** ([TR-villager-ai-behavior-053]): reachability
##    is never a pre-filter gate on the ranking -- a nearer-but-unreachable
##    candidate is still genuinely attempted (counted), never silently
##    skipped in favor of a farther reachable one.
## 7. **Edge case**: an empty candidate list short-circuits to no selection,
##    zero pathfind attempts.
class_name JobSelectionF2Test
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures (declared above the test functions, this codebase's own
# GdUnit4 convention -- see astar_graph_test.gd).
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
## every (x, z) in `[0, size) x [0, size)`, leaving y=1+ empty -- every
## (x, 1, z) in that footprint is standable (mirrors astar_graph_test.gd's
## own fixture).
func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), _solid())


## Adds an "unreachable island": a single standable column at
## `(cell.x, 5, cell.z)`, isolated from the main platform by a 4-cell height
## gap (well past `max_step_height=1`) with nothing else placed nearby, so
## it becomes a graph point with ZERO legal-step connections to anything --
## [method VillagerNavGraph.find_path] genuinely returns empty for it (a
## real "no path exists" case, not merely "never a point," mirroring
## astar_graph_test.gd's own height-difference-2 isolation fixture).
func _add_unreachable_island(grid: VoxelWorldGrid, cell: Vector3i) -> Vector3i:
	grid.set_cell(Vector3i(cell.x, 4, cell.z), _solid())
	return Vector3i(cell.x, 5, cell.z)


func _make_graph(grid: VoxelWorldGrid, villager_ai: VillagerAi, region_center: Vector3i, region_size: int) -> VillagerNavGraph:
	var graph := VillagerNavGraph.new()
	graph.build(grid, villager_ai, region_center, region_size)
	return graph


func _blueprint(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell)


# ---------------------------------------------------------------------------
# AC6 — true-path-nearest among the Chebyshev-nearest candidates wins;
# path-length ties resolve by commit (queue) order, not coordinate;
# deterministic across repeated calls
# ---------------------------------------------------------------------------

func test_select_job_path_length_tie_breaks_by_commit_order_not_coordinate() -> void:
	# Arrange — a 7x7 open platform; from_cell at the center. Two candidates,
	# symmetric north/south of center, both orthogonal path length 2.0 and
	# both Chebyshev distance 2 -- a genuine tie. Queue order deliberately
	# DISAGREES with lexicographic (y,x,z) order: index 0 is the
	# lexicographically LARGER cell (z=5), index 1 the smaller (z=1) -- if
	# the selector picked by coordinate instead of commit order, it would
	# choose the wrong candidate.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 7)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph: VillagerNavGraph = _make_graph(grid, villager_ai, Vector3i(3, 0, 3), 7)
	var from_cell := Vector3i(3, 1, 3)

	var older_commit := _blueprint(Vector3i(3, 1, 5))  # index 0 -- "older commit"
	var newer_commit := _blueprint(Vector3i(3, 1, 1))  # index 1 -- lexicographically smaller
	var candidates: Array[BlueprintCell] = [older_commit, newer_commit]

	var result: JobSelectionResult = VillagerJobSelector.select_job(candidates, from_cell, graph, 2, 6)

	assert_object(result.chosen).is_same(older_commit)


func test_select_job_is_deterministic_across_repeated_calls() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 7)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph: VillagerNavGraph = _make_graph(grid, villager_ai, Vector3i(3, 0, 3), 7)
	var from_cell := Vector3i(3, 1, 3)
	var candidates: Array[BlueprintCell] = [
		_blueprint(Vector3i(3, 1, 5)), _blueprint(Vector3i(3, 1, 1)), _blueprint(Vector3i(5, 1, 3)),
	]

	var first: JobSelectionResult = VillagerJobSelector.select_job(candidates, from_cell, graph, 2, 6)
	var second: JobSelectionResult = VillagerJobSelector.select_job(candidates, from_cell, graph, 2, 6)

	assert_object(first.chosen).is_same(second.chosen)
	assert_int(first.pathfind_attempt_count).is_equal(second.pathfind_attempt_count)


func test_select_job_true_path_nearest_wins_among_chebyshev_nearest() -> void:
	# Arrange — three candidates on an open platform, distinct distances; the
	# true-path-nearest (shortest path_length_cells) must win, not merely
	# the Chebyshev-nearest (they agree here, on a fully open platform, by
	# construction -- this asserts the selector actually runs the true-path
	# comparison, not just the pre-filter rank).
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 9)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph: VillagerNavGraph = _make_graph(grid, villager_ai, Vector3i(4, 0, 4), 9)
	var from_cell := Vector3i(4, 1, 4)

	var nearest := _blueprint(Vector3i(5, 1, 4))     # 1 step
	var middle := _blueprint(Vector3i(6, 1, 4))      # 2 steps
	var farthest := _blueprint(Vector3i(7, 1, 4))    # 3 steps
	var candidates: Array[BlueprintCell] = [farthest, middle, nearest]

	var result: JobSelectionResult = VillagerJobSelector.select_job(candidates, from_cell, graph, 3, 9)

	assert_object(result.chosen).is_same(nearest)


# ---------------------------------------------------------------------------
# AC6 (lexicographic sub-clause) — the same-command (y, x, z) tie-break,
# proven directly (see class doc comment for why select_job() itself can
# never reach this branch against a real, deduplicated candidate array)
# ---------------------------------------------------------------------------

func test_lexicographic_cell_less_than_breaks_ties_by_y_then_x_then_z() -> void:
	# y differs -- decides regardless of x/z.
	assert_bool(VillagerJobSelector.lexicographic_cell_less_than(
		Vector3i(5, 1, 9), Vector3i(2, 2, 0)
	)).is_true()
	# same y, x differs -- decides.
	assert_bool(VillagerJobSelector.lexicographic_cell_less_than(
		Vector3i(1, 3, 9), Vector3i(2, 3, 0)
	)).is_true()
	# same y and x, z differs -- decides.
	assert_bool(VillagerJobSelector.lexicographic_cell_less_than(
		Vector3i(4, 3, 1), Vector3i(4, 3, 5)
	)).is_true()
	# identical cells -- neither is strictly less than the other.
	assert_bool(VillagerJobSelector.lexicographic_cell_less_than(
		Vector3i(4, 3, 1), Vector3i(4, 3, 1)
	)).is_false()
	# asymmetry check.
	assert_bool(VillagerJobSelector.lexicographic_cell_less_than(
		Vector3i(4, 3, 5), Vector3i(4, 3, 1)
	)).is_false()


# ---------------------------------------------------------------------------
# AC7 — a round's total failure tries the next round, deterministically, up
# to max_selection_candidates; pathfind_attempt_count reflects exactly how
# many true-path checks ran
# ---------------------------------------------------------------------------

func test_select_job_advances_rounds_until_a_reachable_candidate_is_found() -> void:
	# Arrange — 4 unreachable islands (2 rounds of job_candidate_count=2,
	# both rounds entirely unreachable), then 1 reachable candidate on the
	# main platform in round 3 -- 5 true-path attempts total, well within
	# max_selection_candidates=6 (3 rounds of 2).
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 21)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph: VillagerNavGraph = _make_graph(grid, villager_ai, Vector3i(10, 0, 10), 21)
	var from_cell := Vector3i(10, 1, 10)

	var island1 := _blueprint(_add_unreachable_island(grid, Vector3i(11, 0, 10)))  # Chebyshev 1
	var island2 := _blueprint(_add_unreachable_island(grid, Vector3i(12, 0, 10)))  # Chebyshev 2
	var island3 := _blueprint(_add_unreachable_island(grid, Vector3i(13, 0, 10)))  # Chebyshev 3
	var island4 := _blueprint(_add_unreachable_island(grid, Vector3i(14, 0, 10)))  # Chebyshev 4
	var reachable := _blueprint(Vector3i(16, 1, 10))  # Chebyshev 6, on the main platform
	# Rebuild the graph now that the islands' ground cells are in place --
	# build() is idempotent/re-buildable (VillagerNavGraph's own doc comment).
	graph.build(grid, villager_ai, Vector3i(10, 0, 10), 21)
	var candidates: Array[BlueprintCell] = [island1, island2, island3, island4, reachable]

	var result: JobSelectionResult = VillagerJobSelector.select_job(candidates, from_cell, graph, 2, 6)

	assert_object(result.chosen).is_same(reachable)
	assert_int(result.pathfind_attempt_count).is_equal(5)


func test_select_job_exactly_at_cap_all_unreachable_falls_through_without_exceeding_the_cap() -> void:
	# Arrange — 6 unreachable islands (job_candidate_count=2,
	# max_selection_candidates=6 -> exactly 3 full rounds), plus a 7th
	# candidate that WOULD be reachable if ever attempted, sitting one round
	# past the cap -- it must never be attempted.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 21)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var from_cell := Vector3i(10, 1, 10)

	var islands: Array[BlueprintCell] = []
	for i in range(6):
		islands.append(_blueprint(_add_unreachable_island(grid, Vector3i(11 + i, 0, 10))))
	var never_attempted := _blueprint(Vector3i(18, 1, 10))
	var graph: VillagerNavGraph = _make_graph(grid, villager_ai, Vector3i(10, 0, 10), 21)
	var candidates: Array[BlueprintCell] = islands.duplicate()
	candidates.append(never_attempted)

	var result: JobSelectionResult = VillagerJobSelector.select_job(candidates, from_cell, graph, 2, 6)

	assert_object(result.chosen).is_null()
	assert_int(result.pathfind_attempt_count).is_equal(6)


# ---------------------------------------------------------------------------
# Edge case — queue non-empty, every candidate unreachable (fewer candidates
# than one full round's worth)
# ---------------------------------------------------------------------------

func test_select_job_all_candidates_unreachable_falls_through_cleanly() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 21)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var from_cell := Vector3i(10, 1, 10)

	var island1 := _blueprint(_add_unreachable_island(grid, Vector3i(11, 0, 10)))
	var island2 := _blueprint(_add_unreachable_island(grid, Vector3i(12, 0, 10)))
	var island3 := _blueprint(_add_unreachable_island(grid, Vector3i(13, 0, 10)))
	var graph: VillagerNavGraph = _make_graph(grid, villager_ai, Vector3i(10, 0, 10), 21)
	var candidates: Array[BlueprintCell] = [island1, island2, island3]

	var result: JobSelectionResult = VillagerJobSelector.select_job(candidates, from_cell, graph, 5, 15)

	assert_object(result.chosen).is_null()
	assert_int(result.pathfind_attempt_count).is_equal(3)
	assert_bool(result.has_selection()).is_false()


# ---------------------------------------------------------------------------
# "Available" contract — reachability is never a pre-filter gate; a
# nearer-but-unreachable candidate is still genuinely attempted
# ---------------------------------------------------------------------------

func test_select_job_attempts_the_nearer_unreachable_candidate_before_choosing_the_farther_reachable_one() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 21)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var from_cell := Vector3i(10, 1, 10)

	var near_unreachable := _blueprint(_add_unreachable_island(grid, Vector3i(11, 0, 10)))  # Chebyshev 1
	var far_reachable := _blueprint(Vector3i(14, 1, 10))  # Chebyshev 4, on the main platform
	var graph: VillagerNavGraph = _make_graph(grid, villager_ai, Vector3i(10, 0, 10), 21)
	var candidates: Array[BlueprintCell] = [near_unreachable, far_reachable]

	var result: JobSelectionResult = VillagerJobSelector.select_job(candidates, from_cell, graph, 2, 6)

	assert_object(result.chosen).is_same(far_reachable)
	# Both were attempted this round -- the unreachable-but-nearer candidate
	# was never silently skipped from ranking/attempting.
	assert_int(result.pathfind_attempt_count).is_equal(2)


# ---------------------------------------------------------------------------
# Edge case — empty candidate list
# ---------------------------------------------------------------------------

func test_select_job_empty_candidates_returns_no_selection_with_zero_attempts() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var graph: VillagerNavGraph = _make_graph(grid, villager_ai, Vector3i(1, 0, 1), 3)
	var empty_candidates: Array[BlueprintCell] = []

	var result: JobSelectionResult = VillagerJobSelector.select_job(empty_candidates, Vector3i(1, 1, 1), graph, 5, 15)

	assert_object(result.chosen).is_null()
	assert_int(result.pathfind_attempt_count).is_equal(0)
	assert_bool(result.has_selection()).is_false()
