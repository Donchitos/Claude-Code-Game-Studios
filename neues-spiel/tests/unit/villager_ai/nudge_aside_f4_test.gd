## Unit test — Villager AI story villager-ai-013 (Nudge-aside vacate, F4
## target selection; GDD Rule 7 / F4, [TR-villager-ai-behavior-056]/
## [TR-villager-ai-behavior-079]/[TR-villager-ai-behavior-034], ADR-0009
## Decision Section 2).
##
## Proves, against [VillagerNudgeAsideSelector.select_vacate_target] (pure
## algorithm, real [VillagerAi]/[VoxelWorldGrid] predicate fixtures, no
## mocked walkability — mirrors rescue_target_bfs_test.gd's own "no mocked
## pathfinding" precedent) and [VillagerAi.request_vacate] (the real
## eligibility/state-transition wiring):
##
## 1. **Formula**: `argmin(height_difference)` takes priority over
##    `argMAX(Chebyshev distance to requester)` — a farther, height-stepped
##    candidate loses to a nearer, flat one.
## 2. **AC50**: given a strictly-closer and a strictly-farther flat standable
##    neighbor, the chosen cell strictly INCREASES Chebyshev distance to the
##    requester — never decreases.
## 3. **AC35**: a full tie on height + distance resolves via the fixed
##    N/E/S/W scan order, identically across repeated calls.
## 4. **Edge case**: no standable orthogonal neighbor at all returns `null`
##    (the vacate request fails, GDD Rule 7).
## 5. **Determinism**: repeated calls with identical inputs yield an
##    identical chosen cell.
## 6. **AC34**: a `WANDERING` occupant steps toward the F4 target (state
##    transitions to `TRAVELING`, discrete `current_cell` unchanged mid-step
##    per ADR-0009); a `WORKING`/`SLEEPING`/`BREATHER`/`TRAVELING`/`DECIDING`
##    occupant is NOT interrupted — the request is a no-op, state unchanged.
## 7. **AC42**: a builder requesting a vacate on a villager mid-work on its
##    own claimed job is deferred — the occupant's claim is never touched.
## 8. **Idempotency**: a repeated request while already mid-vacate-step is a
##    harmless no-op (no re-selection, no redundant travel restart).
class_name NudgeAsideF4Test
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures (declared above the test functions, this codebase's own
# GdUnit4 convention — see rescue_target_bfs_test.gd/unstuck_watchdog_test.gd).
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
## it — mirrors rescue_target_bfs_test.gd's own "sparse grid, only
## explicitly-placed cells are ever standable" convention.
func _make_standable(grid: VoxelWorldGrid, cell: Vector3i) -> void:
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid())


## A flat, fully-connected NxN standable platform at y=0 (mirrors
## build_job_cycle_test.gd's own established fixture) — villagers occupy y=1.
func _flat_platform_grid(size: int) -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _make_grid()
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))
	return grid


## A bare, tick-independent [VillagerAi] wired with a real, built
## [VillagerNavGraph] over `grid` — required by [method VillagerAi.
## start_traveling] (and therefore [method VillagerAi.request_vacate]'s own
## eligible-state branch), mirrors priority_decision_loop_test.gd's own
## `_make_travel_capable_villager_ai` fixture shape.
func _make_travel_capable_villager(grid: VoxelWorldGrid, cell: Vector3i, region_size: int) -> VillagerAi:
	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, cell, region_size)
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.voxel_world = grid
	villager.nav_graph = graph
	villager.current_cell = cell
	villager._from_cell = cell
	villager._to_cell = cell
	return villager


# ---------------------------------------------------------------------------
# Formula — argmin(height_difference) takes priority over argMAX(distance)
# ---------------------------------------------------------------------------

func test_select_vacate_target_prefers_flat_neighbor_over_farther_stepped_one() -> void:
	# Arrange — occupant at (10,1,10). North neighbor (10,2,9) is standable but
	# ONE CELL HIGHER (height_difference = 1); south neighbor (10,1,11) is
	# flat (height_difference = 0). The requester sits far south, so the
	# stepped north candidate is actually FARTHER from the requester than the
	# flat south one — yet the flat candidate must still win, since
	# argmin(height_difference) is evaluated first.
	var grid: VoxelWorldGrid = _make_grid()
	var occupant_cell := Vector3i(10, 1, 10)
	var stepped_candidate := Vector3i(10, 2, 9)  # height_difference = 1, farther from requester.
	var flat_candidate := Vector3i(10, 1, 11)    # height_difference = 0, nearer to requester.
	_make_standable(grid, stepped_candidate)
	_make_standable(grid, flat_candidate)
	var predicate_source: VillagerAi = _make_villager_ai(grid)
	var requester_cell := Vector3i(10, 1, 20)

	# Act
	var result: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		predicate_source, occupant_cell, requester_cell
	)

	# Assert
	assert_bool(result == null).is_false()
	assert_vector(result).is_equal(flat_candidate)


# ---------------------------------------------------------------------------
# AC50 — among same-height candidates, the FARTHER one from the requester wins
# ---------------------------------------------------------------------------

func test_select_vacate_target_picks_strictly_farther_flat_neighbor_never_closer() -> void:
	# Arrange — occupant at (10,1,10); only N and S neighbors are standable,
	# both flat. The requester sits north of the N neighbor, so N is CLOSER
	# to the requester (distance 3) and S is FARTHER (distance 5) — the
	# chosen cell must be S, strictly increasing distance to the requester.
	var grid: VoxelWorldGrid = _make_grid()
	var occupant_cell := Vector3i(10, 1, 10)
	var closer_candidate := Vector3i(10, 1, 9)   # N — closer to the requester.
	var farther_candidate := Vector3i(10, 1, 11)  # S — farther from the requester.
	_make_standable(grid, closer_candidate)
	_make_standable(grid, farther_candidate)
	var predicate_source: VillagerAi = _make_villager_ai(grid)
	var requester_cell := Vector3i(10, 1, 6)

	# Act
	var result: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		predicate_source, occupant_cell, requester_cell
	)

	# Assert — the FARTHER cell wins; never the closer one.
	assert_vector(result).is_equal(farther_candidate)
	assert_bool(result == closer_candidate).is_false()


# ---------------------------------------------------------------------------
# AC35 — a full tie on height + distance breaks via the fixed N/E/S/W order
# ---------------------------------------------------------------------------

func test_select_vacate_target_tie_break_uses_fixed_north_first_scan_order() -> void:
	# Arrange — all 4 orthogonal neighbors are standable and flat; the
	# requester sits exactly on the occupant's own cell, so every neighbor is
	# tied at Chebyshev distance 1 and height_difference 0. N must win.
	var grid: VoxelWorldGrid = _make_grid()
	var occupant_cell := Vector3i(10, 1, 10)
	var north := Vector3i(10, 1, 9)
	var east := Vector3i(11, 1, 10)
	var south := Vector3i(10, 1, 11)
	var west := Vector3i(9, 1, 10)
	for candidate: Vector3i in [north, east, south, west]:
		_make_standable(grid, candidate)
	var predicate_source: VillagerAi = _make_villager_ai(grid)

	# Act
	var first: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		predicate_source, occupant_cell, occupant_cell
	)
	var second: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		predicate_source, occupant_cell, occupant_cell
	)

	# Assert — N wins, deterministically across repeated calls.
	assert_vector(first).is_equal(north)
	assert_vector(second).is_equal(north)


func test_select_vacate_target_tie_break_falls_through_to_east_when_north_unavailable() -> void:
	# Arrange — same full tie as above, but N is NOT standable this time —
	# proves the winner is genuinely determined by scan ORDER, not merely
	# "always the first array element" by coincidence.
	var grid: VoxelWorldGrid = _make_grid()
	var occupant_cell := Vector3i(10, 1, 10)
	var east := Vector3i(11, 1, 10)
	var south := Vector3i(10, 1, 11)
	var west := Vector3i(9, 1, 10)
	for candidate: Vector3i in [east, south, west]:
		_make_standable(grid, candidate)
	var predicate_source: VillagerAi = _make_villager_ai(grid)

	# Act
	var result: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		predicate_source, occupant_cell, occupant_cell
	)

	# Assert
	assert_vector(result).is_equal(east)


# ---------------------------------------------------------------------------
# Edge case — no standable orthogonal neighbor at all: the request fails
# ---------------------------------------------------------------------------

func test_select_vacate_target_returns_null_when_no_adjacent_standable_cell() -> void:
	# Arrange — a completely sparse grid; nothing anywhere is standable.
	var grid: VoxelWorldGrid = _make_grid()
	var occupant_cell := Vector3i(10, 1, 10)
	var predicate_source: VillagerAi = _make_villager_ai(grid)

	# Act
	var result: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		predicate_source, occupant_cell, Vector3i(0, 1, 0)
	)

	# Assert
	assert_bool(result == null).is_true()


# ---------------------------------------------------------------------------
# Determinism — repeated calls with identical inputs yield an identical cell
# ---------------------------------------------------------------------------

func test_select_vacate_target_is_deterministic_across_repeated_calls() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var occupant_cell := Vector3i(10, 1, 10)
	_make_standable(grid, Vector3i(10, 1, 9))
	_make_standable(grid, Vector3i(10, 1, 11))
	var predicate_source: VillagerAi = _make_villager_ai(grid)
	var requester_cell := Vector3i(10, 1, 6)

	var first: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		predicate_source, occupant_cell, requester_cell
	)
	var second: Variant = VillagerNudgeAsideSelector.select_vacate_target(
		predicate_source, occupant_cell, requester_cell
	)

	assert_vector(first).is_equal(second)


# ---------------------------------------------------------------------------
# AC34 — a WANDERING occupant steps to the F4 target within one tick
# ---------------------------------------------------------------------------

func test_request_vacate_wandering_occupant_steps_away_toward_farther_target() -> void:
	# Arrange — a flat 5x5 platform; occupant at the center (2,1,2), every
	# orthogonal neighbor standable. The requester sits at the north edge, so
	# the occupant must step SOUTH — away from the requester.
	var grid: VoxelWorldGrid = _flat_platform_grid(5)
	var occupant_cell := Vector3i(2, 1, 2)
	var villager: VillagerAi = _make_travel_capable_villager(grid, occupant_cell, 5)
	villager._state = VillagerAi.State.WANDERING
	var requester_cell := Vector3i(2, 1, 0)
	var expected_target := Vector3i(2, 1, 3)  # south — farthest from the requester.

	# Act
	var vacated: bool = villager.request_vacate(requester_cell)

	# Assert
	assert_bool(vacated).is_true()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_vector(villager.get_current_cell()).is_equal(occupant_cell)  # unchanged mid-step (ADR-0009).
	assert_vector(villager._to_cell).is_equal(expected_target)

	# Idempotency — a repeated request while already mid-vacate-step is a
	# harmless no-op: ineligible state now (TRAVELING), no re-selection.
	var repeated: bool = villager.request_vacate(Vector3i(2, 1, 4))
	assert_bool(repeated).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_vector(villager._to_cell).is_equal(expected_target)


# ---------------------------------------------------------------------------
# AC34/AC42 — mid-activity occupants are NOT interrupted; claim never touched
# ---------------------------------------------------------------------------

func test_request_vacate_working_occupant_is_deferred_claim_never_revoked() -> void:
	# Arrange — a villager mid-work on its own claimed job (AC42).
	var grid: VoxelWorldGrid = _flat_platform_grid(5)
	var villager: VillagerAi = _make_travel_capable_villager(grid, Vector3i(2, 1, 2), 5)
	villager._state = VillagerAi.State.WORKING
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	var claimed_cell := BlueprintCell.new(Vector3i(9, 1, 9), BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	villager._claimed_blueprint_cell = claimed_cell

	# Act
	var vacated: bool = villager.request_vacate(Vector3i(2, 1, 0))

	# Assert — deferred: no state change, claim untouched.
	assert_bool(vacated).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WORKING)
	assert_vector(villager.get_current_cell()).is_equal(Vector3i(2, 1, 2))
	assert_vector(villager.get_claimed_job_cell()).is_equal(Vector3i(9, 1, 9))
	assert_int(claimed_cell.state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)


func test_request_vacate_sleeping_occupant_is_deferred() -> void:
	var grid: VoxelWorldGrid = _flat_platform_grid(5)
	var villager: VillagerAi = _make_travel_capable_villager(grid, Vector3i(2, 1, 2), 5)
	villager._state = VillagerAi.State.SLEEPING

	var vacated: bool = villager.request_vacate(Vector3i(2, 1, 0))

	assert_bool(vacated).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_vector(villager.get_current_cell()).is_equal(Vector3i(2, 1, 2))


func test_request_vacate_breather_occupant_is_deferred() -> void:
	var grid: VoxelWorldGrid = _flat_platform_grid(5)
	var villager: VillagerAi = _make_travel_capable_villager(grid, Vector3i(2, 1, 2), 5)
	villager._state = VillagerAi.State.BREATHER

	var vacated: bool = villager.request_vacate(Vector3i(2, 1, 0))

	assert_bool(vacated).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.BREATHER)


func test_request_vacate_traveling_occupant_is_deferred() -> void:
	var grid: VoxelWorldGrid = _flat_platform_grid(5)
	var villager: VillagerAi = _make_travel_capable_villager(grid, Vector3i(2, 1, 2), 5)
	villager._state = VillagerAi.State.TRAVELING

	var vacated: bool = villager.request_vacate(Vector3i(2, 1, 0))

	assert_bool(vacated).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)


func test_request_vacate_deciding_occupant_is_deferred() -> void:
	var grid: VoxelWorldGrid = _flat_platform_grid(5)
	# A freshly-constructed villager defaults to State.DECIDING (loop start).
	var villager: VillagerAi = _make_travel_capable_villager(grid, Vector3i(2, 1, 2), 5)

	var vacated: bool = villager.request_vacate(Vector3i(2, 1, 0))

	assert_bool(vacated).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)


# ---------------------------------------------------------------------------
# Edge case — no adjacent standable cell: the vacate request fails
# ---------------------------------------------------------------------------

func test_request_vacate_returns_false_when_no_adjacent_standable_cell() -> void:
	# Arrange — an isolated standable island: only the occupant's own cell is
	# standable, nothing adjacent to it.
	var grid: VoxelWorldGrid = _make_grid()
	var occupant_cell := Vector3i(10, 1, 10)
	_make_standable(grid, occupant_cell)
	var villager: VillagerAi = _make_villager_ai(grid)
	villager.current_cell = occupant_cell
	villager._from_cell = occupant_cell
	villager._to_cell = occupant_cell
	villager._state = VillagerAi.State.WANDERING

	# Act
	var vacated: bool = villager.request_vacate(Vector3i(0, 1, 0))

	# Assert
	assert_bool(vacated).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WANDERING)
	assert_vector(villager.get_current_cell()).is_equal(occupant_cell)
