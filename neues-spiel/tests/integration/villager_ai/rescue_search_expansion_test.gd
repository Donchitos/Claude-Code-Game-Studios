## Integration test — Villager AI story villager-ai-014 (F5 rescue-target
## BFS, radius-expansion + once-per-episode failure event, GDD Edge Case 14 /
## AC53 / [TR-villager-ai-behavior-105]).
##
## Kept separate from `rescue_target_bfs_test.gd`'s pure-BFS unit coverage
## per this story's own Test Evidence split ("AC53 radius-expansion may use
## ... for the multi-cell fixture (integration-scale)") — this file's
## fixtures are larger (spanning multiple doubled radii) and combine
## [VillagerRescueTargetSearch] with its companion
## [RescueSearchFailureGate], modeling how the watchdog (Story
## villager-ai-015) will actually drive both together across repeated
## per-tick calls.
##
## Proves:
## 1. **AC53 (radius doubling)**: no cell within the initial
##    `unstuck_rescue_search_radius` — the radius doubles (possibly more than
##    once) up to `unstuck_rescue_max_radius` and finds a cell only reachable
##    at an EXPANDED radius.
## 2. **AC53 (search-failed fires exactly once per episode)**: a search that
##    keeps coming back empty across repeated calls (simulating "the search
##    retries every tick until a cell is found," GDD Edge Case 14) reports
##    `villager_unstuck_search_failed`-worthy exactly once via
##    [RescueSearchFailureGate.should_report_failure] — not once per call —
##    until [method RescueSearchFailureGate.reset_episode] re-arms it for a
##    new episode.
class_name RescueSearchExpansionTest
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


func _make_standable(grid: VoxelWorldGrid, cell: Vector3i) -> void:
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid())


# ---------------------------------------------------------------------------
# AC53 — radius doubling finds a cell only reachable beyond the initial bound
# ---------------------------------------------------------------------------

func test_find_rescue_target_expands_radius_beyond_initial_bound_to_find_a_far_cell() -> void:
	# Arrange — the ONLY standable cell in the whole grid sits at Chebyshev
	# distance 10 from the stuck cell. With an initial search_radius of 3,
	# the doubling sequence is 3 -> 6 -> 12 (capped at max_radius=24) --
	# distance 10 is only covered once the bound reaches 12, proving MORE
	# than a single doubling step is exercised, not merely "radius * 2 once."
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(20, 1, 20)
	var far_target := Vector3i(30, 1, 20)  # Chebyshev distance 10.
	_make_standable(grid, far_target)

	# Act
	var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, [], 3, 24
	)

	# Assert
	assert_bool(result.has_target()).is_true()
	assert_vector(result.cell).is_equal(far_target)


func test_find_rescue_target_expansion_still_respects_the_lexicographic_tie_break() -> void:
	# Arrange — two standable cells only reachable after the radius expands
	# past the initial bound, both at the SAME Chebyshev distance (5) from
	# the stuck cell (initial search_radius=3 misses both; the first
	# doubling step to 6 covers both) — the lexicographically smaller one
	# must still win, exactly as the un-expanded case does.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(20, 1, 20)
	var lexicographically_smaller := Vector3i(20, 1, 15)  # x=20 < 25.
	var lexicographically_larger := Vector3i(25, 1, 20)
	_make_standable(grid, lexicographically_smaller)
	_make_standable(grid, lexicographically_larger)

	# Act
	var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
		stuck_cell, villager_ai, [], 3, 24
	)

	# Assert
	assert_bool(result.has_target()).is_true()
	assert_vector(result.cell).is_equal(lexicographically_smaller)


# ---------------------------------------------------------------------------
# AC53 — villager_unstuck_search_failed fires exactly once per stuck episode
# ---------------------------------------------------------------------------

func test_search_failure_gate_reports_exactly_once_across_repeated_failed_ticks() -> void:
	# Arrange — a grid with nothing standable anywhere; every per-tick search
	# call (simulating the watchdog retrying every tick, GDD Edge Case 14)
	# comes back not-found.
	var grid: VoxelWorldGrid = _make_grid()
	var villager_ai: VillagerAi = _make_villager_ai(grid)
	var stuck_cell := Vector3i(20, 1, 20)
	var gate := RescueSearchFailureGate.new()

	var reported_on_tick: Array[bool] = []
	for _tick in range(4):
		var result: RescueSearchResult = VillagerRescueTargetSearch.find_rescue_target(
			stuck_cell, villager_ai, [], 3, 6
		)
		assert_bool(result.has_target()).is_false()
		reported_on_tick.append(gate.should_report_failure())

	# Assert — reported on the FIRST failed tick only, never again for the
	# same episode.
	assert_array(reported_on_tick).contains_exactly([true, false, false, false])


func test_search_failure_gate_re_arms_after_reset_episode() -> void:
	# Arrange — a fresh gate that has already reported once for episode A.
	var gate := RescueSearchFailureGate.new()
	assert_bool(gate.should_report_failure()).is_true()
	assert_bool(gate.should_report_failure()).is_false()

	# Act — the watchdog (Story villager-ai-015) resets the gate the instant
	# `stuck_tick_count` returns to 0 (a NEW episode begins).
	gate.reset_episode()

	# Assert — the new episode may report its own failure exactly once too.
	assert_bool(gate.should_report_failure()).is_true()
	assert_bool(gate.should_report_failure()).is_false()
