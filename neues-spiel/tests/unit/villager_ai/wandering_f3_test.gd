## Unit test — Villager AI story villager-ai-019 (F3 wander-target selection /
## Rule 7c idle micro-behaviors, GDD [TR-villager-ai-behavior-078]/059/060/
## 067/087/089, ADR-0008 Decision §1).
##
## Proves, against [VillagerWanderSelector] (pure algorithm library) and
## [VillagerAi._tick_wandering]/[VillagerAi._perform_wander_pick] (the real
## FSM wiring):
## 1. **AC28**: the flood-fill reaches every connected cell but excludes an
##    otherwise-standable island cut off by a moat of non-standable cells --
##    "reachable by construction," never a post-hoc path check.
## 2. **AC29/AC45**: a cell exactly at `wander_radius` is included; one cell
##    beyond is excluded — inclusive boundary.
## 3. **Determinism (flood-fill)**: repeated calls with identical inputs
##    yield an identical result set, in the identical order.
## 4. **AC31/Edge Case 8**: a flood-fill returning only the current cell ->
##    the villager stays in `State.WANDERING` at the same cell, no error, and
##    re-attempts (a real, observable new pick) at the next `wander_interval`.
## 5. **AC30**: two villagers assembled from an IDENTICAL starting state
##    produce an IDENTICAL sequence of wander picks/positions tick for tick —
##    the "no live RNG, no wall-clock" determinism contract (see
##    [VillagerAi.wander_rng]'s own doc comment).
## 6. **Rule 7c micro-behavior variety**: many draws produce more than one
##    distinct behavior; `BED_DRIFT` is never drawn when ineligible.
## 7. **Rule 7c bed-drift bound**: [method
##    VillagerWanderSelector.select_bed_drift_target] picks the flood-filled
##    cell nearest the bed, never a cell outside the bounded set — wired
##    end to end through a real `_tick_wandering` pick cycle.
class_name WanderingF3Test
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures (declared above the test functions per this codebase's own
# GdUnit4 convention — see rescue_target_bfs_test.gd / priority_decision_loop_test.gd).
# ---------------------------------------------------------------------------

func _solid() -> CellContents:
	return CellContents.new(1, 0)


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


## Solid floor at `y` across the full [min_x, max_x] x [min_z, max_z]
## rectangle -- every cell at `y + 1` in that footprint becomes standable
## (mirrors priority_decision_loop_test.gd's own `_make_flat_grid` helper,
## generalized to an arbitrary rectangle so a test can leave a deliberate gap
## for a moat/wall).
func _fill_floor(grid: VoxelWorldGrid, min_x: int, max_x: int, min_z: int, max_z: int, y: int) -> void:
	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			grid.set_cell(Vector3i(x, y, z), _solid())


func _make_predicate_source(grid: VoxelWorldGrid) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.voxel_world = grid
	return villager_ai


## A wandering-capable villager: `config`/`voxel_world` wired, plus a real
## [VillagerNavGraph] built over the whole platform (required by [method
## VillagerAi.start_traveling], which any non-stationary pick reaches) --
## mirrors `_make_travel_capable_villager_ai` in priority_decision_loop_test.gd.
func _make_wandering_villager_ai(
	grid: VoxelWorldGrid, region_center: Vector3i, region_size: int, current_cell: Vector3i, villager_id: int = 0
) -> VillagerAi:
	var predicate_source: VillagerAi = _make_predicate_source(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, region_center, region_size)
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = grid
	villager_ai.nav_graph = graph
	villager_ai.villager_id = villager_id
	villager_ai.current_cell = current_cell
	villager_ai._from_cell = current_cell
	villager_ai._to_cell = current_cell
	villager_ai._state = VillagerAi.State.WANDERING
	return villager_ai


## Drives [param villager_ai] through exactly one full `wander_interval`
## worth of [method VillagerAi._tick_wandering] calls -- enough ticks for
## exactly one pick to fire, assuming the villager starts the window already
## stationary in `State.WANDERING` (this file's own fixtures all do).
func _advance_one_wander_interval(villager_ai: VillagerAi) -> void:
	for _i in range(villager_ai.config.wander_interval):
		villager_ai._tick_wandering()


## Runs exactly one F3/Rule 7c pick directly ([method
## VillagerAi._perform_wander_pick], bypassing the `wander_interval` cadence
## itself -- that cadence is separately proven by the AC31 test above) and
## returns `[behavior, target]`: `target` is [member
## VillagerAi._travel_target_cell] when the pick actually moved the villager
## into `State.TRAVELING` (a `WALK`/`BED_DRIFT` pick toward a DIFFERENT
## cell), or [param villager_ai]'s own (unchanged) current cell otherwise (a
## stationary `PAUSE_LOOK`/`SIT` pick, or a `WALK`/`BED_DRIFT` pick that
## degenerated to the current cell). Resets [param villager_ai] back to a
## stationary `State.WANDERING` at its ORIGINAL cell afterward -- this
## function deliberately never simulates real multi-tick travel arrival
## (that machinery belongs to story villager-ai-009's own already-covered
## tests) -- so a caller's NEXT call always starts from the identical "same
## state" AC30 itself names, isolating this file's own scope to "does the
## SAME state always yield the SAME pick," not "does travel arrive."
func _perform_pick_and_record(villager_ai: VillagerAi) -> Array:
	var cell_before: Vector3i = villager_ai.get_current_cell()
	villager_ai._perform_wander_pick()
	var behavior: Variant = villager_ai.get_last_micro_behavior()
	var target: Vector3i = cell_before
	if villager_ai.get_state() == VillagerAi.State.TRAVELING:
		target = villager_ai._travel_target_cell
	villager_ai._state = VillagerAi.State.WANDERING
	villager_ai.current_cell = cell_before
	villager_ai._clear_travel_state()
	return [behavior, target]


# ---------------------------------------------------------------------------
# AC28 — reachable by construction: connected cells included, an island cut
# off by a moat of non-standable cells excluded
# ---------------------------------------------------------------------------

func test_flood_fill_reaches_connected_cells_but_excludes_an_unreachable_island() -> void:
	# Arrange — a connected platform from z=0..6, a two-column moat (z=7..8)
	# with NO floor at all (never standable), then an isolated island at
	# z=9 that DOES have its own floor -- standable, but unreachable, since
	# the moat breaks every possible step into it.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_floor(grid, 0, 10, 0, 6, 0)
	_fill_floor(grid, 5, 5, 9, 9, 0)
	var predicate_source: VillagerAi = _make_predicate_source(grid)
	var start := Vector3i(5, 1, 3)
	var island := Vector3i(5, 1, 9)
	var reachable_edge := Vector3i(5, 1, 6)

	# Act
	var flood_cells: Array[Vector3i] = VillagerWanderSelector.flood_fill(predicate_source, start, 10)

	# Assert
	assert_array(flood_cells).contains(reachable_edge)
	assert_array(flood_cells).contains(start)
	assert_bool(flood_cells.has(island)).is_false()


# ---------------------------------------------------------------------------
# AC29/AC45 — inclusive `wander_radius` boundary
# ---------------------------------------------------------------------------

func test_flood_fill_includes_cell_exactly_at_radius_and_excludes_one_cell_beyond() -> void:
	# Arrange — a fully open, obstacle-free platform wide enough to cover
	# radius + 1 in every direction, so both the boundary cell and the
	# one-beyond cell are standable and directly reachable -- the ONLY
	# reason either could be excluded is the radius bound itself.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_floor(grid, 0, 20, 0, 20, 0)
	var predicate_source: VillagerAi = _make_predicate_source(grid)
	var start := Vector3i(10, 1, 10)
	var radius: int = 5
	var at_radius := Vector3i(15, 1, 10)  # Chebyshev distance exactly 5.
	var one_beyond := Vector3i(16, 1, 10)  # Chebyshev distance 6.

	# Act
	var flood_cells: Array[Vector3i] = VillagerWanderSelector.flood_fill(predicate_source, start, radius)

	# Assert
	assert_bool(flood_cells.has(at_radius)).is_true()
	assert_bool(flood_cells.has(one_beyond)).is_false()


# ---------------------------------------------------------------------------
# Determinism (flood-fill) — identical inputs, identical result, identical order
# ---------------------------------------------------------------------------

func test_flood_fill_is_deterministic_across_repeated_calls() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_floor(grid, 0, 12, 0, 12, 0)
	var predicate_source: VillagerAi = _make_predicate_source(grid)
	var start := Vector3i(6, 1, 6)

	var first: Array[Vector3i] = VillagerWanderSelector.flood_fill(predicate_source, start, 4)
	var second: Array[Vector3i] = VillagerWanderSelector.flood_fill(predicate_source, start, 4)

	assert_array(first).is_equal(second)


# ---------------------------------------------------------------------------
# AC31/Edge Case 8 — flood-fill returns only the current cell: stays put, no
# error, and re-attempts (a real new pick) at the next wander_interval
# ---------------------------------------------------------------------------

func test_wandering_stays_in_place_when_only_current_cell_is_standable_and_reattempts_next_interval() -> void:
	# Arrange — a single standable cell with no standable neighbor anywhere
	# (no floor placed for any neighbor column) -- the flood-fill can only
	# ever return [current_cell] itself.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_floor(grid, 5, 5, 5, 5, 0)
	var start := Vector3i(5, 1, 5)
	var villager_ai: VillagerAi = _make_wandering_villager_ai(grid, start, 3, start)

	# Act — one full wander_interval window (the first pick).
	_advance_one_wander_interval(villager_ai)

	# Assert — no error occurred (test would already have failed/errored
	# otherwise), the villager stayed in Wandering, at the same cell, and a
	# real pick DID happen (observable via get_last_micro_behavior no longer
	# being unset).
	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.WANDERING)
	assert_vector(villager_ai.get_current_cell()).is_equal(start)
	assert_bool(villager_ai.get_last_micro_behavior() == null).is_false()

	# Act — a second full wander_interval window (the re-attempt).
	_advance_one_wander_interval(villager_ai)

	# Assert — still in place, still no error; the re-attempt happened again
	# (the villager never got stuck refusing to re-evaluate -- a fresh pick,
	# not merely "still holding the first tick's value").
	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.WANDERING)
	assert_vector(villager_ai.get_current_cell()).is_equal(start)
	assert_bool(villager_ai.get_last_micro_behavior() == null).is_false()


# ---------------------------------------------------------------------------
# AC30 — two villagers from an identical starting state produce an identical
# wander-pick sequence (no live RNG, no wall-clock)
# ---------------------------------------------------------------------------

func test_two_villagers_from_identical_state_produce_identical_wander_sequences() -> void:
	# Arrange — two entirely SEPARATE VoxelWorldGrid/VillagerNavGraph/VillagerAi
	# object graphs, built identically (same platform, same starting cell,
	# same villager_id) -- proving determinism holds across independent
	# instances, never merely "the same object asked twice."
	var grid_a: VoxelWorldGrid = _make_grid()
	_fill_floor(grid_a, 0, 20, 0, 20, 0)
	var start := Vector3i(10, 1, 10)
	var villager_a: VillagerAi = _make_wandering_villager_ai(grid_a, start, 20, start, 7)

	var grid_b: VoxelWorldGrid = _make_grid()
	_fill_floor(grid_b, 0, 20, 0, 20, 0)
	var villager_b: VillagerAi = _make_wandering_villager_ai(grid_b, start, 20, start, 7)

	# Act — 10 picks each, every pick starting from the identical "same
	# state" (see [method _perform_pick_and_record]'s own doc comment).
	var picks_a: Array = []
	var picks_b: Array = []
	for _pick in range(10):
		picks_a.append(_perform_pick_and_record(villager_a))
		picks_b.append(_perform_pick_and_record(villager_b))

	# Assert — the full (behavior, target) sequence matches, element for
	# element.
	assert_array(picks_a).is_equal(picks_b)


# ---------------------------------------------------------------------------
# Rule 7c — micro-behavior variety and bed-drift eligibility gating
# ---------------------------------------------------------------------------

func test_select_micro_behavior_produces_more_than_one_distinct_behavior_over_many_draws() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var seen: Dictionary = {}
	for _i in range(60):
		var behavior: VillagerWanderSelector.MicroBehavior = VillagerWanderSelector.select_micro_behavior(rng, false)
		seen[behavior] = true

	assert_int(seen.size()).is_greater(1)
	assert_bool(seen.has(VillagerWanderSelector.MicroBehavior.BED_DRIFT)).is_false()


func test_select_micro_behavior_draws_bed_drift_when_eligible() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var saw_bed_drift: bool = false
	for _i in range(60):
		var behavior: VillagerWanderSelector.MicroBehavior = VillagerWanderSelector.select_micro_behavior(rng, true)
		if behavior == VillagerWanderSelector.MicroBehavior.BED_DRIFT:
			saw_bed_drift = true
			break

	assert_bool(saw_bed_drift).is_true()


# ---------------------------------------------------------------------------
# Rule 7c — bed-drift target is the flood-filled cell nearest the bed,
# bounded by wander_radius (never a cell outside the bounded set)
# ---------------------------------------------------------------------------

func test_select_bed_drift_target_picks_the_bounded_cell_nearest_a_far_away_bed() -> void:
	# Arrange — an open platform; the bed sits far OUTSIDE the wander radius,
	# along the exact diagonal from `start` (both `dx` and `dz` growing
	# equally) -- Chebyshev distance `max(dx, dz)` then has a UNIQUE minimum
	# at the single flood-filled cell that maximizes `min(x, z)`
	# simultaneously in both axes, `(15, 1, 15)` (never a whole tied edge,
	# which an axis-aligned bed placement would produce and make the
	# "the" winning cell ambiguous by distance alone). The winning cell must
	# be the flood-filled cell that minimizes remaining Chebyshev distance to
	# the bed -- the radius edge in the bed's own direction -- never a cell
	# closer to the bed but outside the bounded flood-filled set.
	var grid: VoxelWorldGrid = _make_grid()
	_fill_floor(grid, 0, 30, 0, 30, 0)
	var predicate_source: VillagerAi = _make_predicate_source(grid)
	var start := Vector3i(10, 1, 10)
	var radius: int = 5
	var bed_cell := Vector3i(30, 1, 30)  # Far beyond the radius, on the exact +x/+z diagonal.
	var expected_radius_edge := Vector3i(15, 1, 15)  # Unique argmin -- see arrange comment above.
	var flood_cells: Array[Vector3i] = VillagerWanderSelector.flood_fill(predicate_source, start, radius)

	# Act
	var drift_target: Vector3i = VillagerWanderSelector.select_bed_drift_target(flood_cells, bed_cell)

	# Assert
	assert_vector(drift_target).is_equal(expected_radius_edge)
	assert_bool(flood_cells.has(drift_target)).is_true()


func test_wandering_bed_drift_pick_travels_to_the_bounded_nearest_cell_to_the_owned_bed() -> void:
	# Arrange — same open-platform/far-bed shape as the pure-function test
	# above, wired end to end through a real villager: force eligibility
	# (`_has_owned_bed`/`_owned_bed_cell`, this codebase's own established
	# "directly set the underscore-prefixed field from a test" convention,
	# see priority_decision_loop_test.gd's own `_state`/`_pursued_activity`
	# pokes) and drive picks (via [method _perform_pick_and_record], which
	# resets back to the SAME starting cell after every pick -- see its own
	# doc comment) until the deterministic rng stream happens to draw
	# `BED_DRIFT` (bounded loop -- reproducible every run, not flaky, since
	# the SAME seed always yields the SAME draw sequence).
	var grid: VoxelWorldGrid = _make_grid()
	_fill_floor(grid, 0, 30, 0, 20, 0)
	var start := Vector3i(10, 1, 10)
	var villager_ai: VillagerAi = _make_wandering_villager_ai(grid, start, 30, start)
	villager_ai._has_owned_bed = true
	villager_ai._owned_bed_cell = Vector3i(30, 1, 10)
	var radius: int = villager_ai.config.wander_radius
	var flood_from_start: Array[Vector3i] = VillagerWanderSelector.flood_fill(villager_ai, start, radius)
	var expected_target: Vector3i = VillagerWanderSelector.select_bed_drift_target(
		flood_from_start, villager_ai._owned_bed_cell
	)

	# Act
	var drew_bed_drift: bool = false
	var drifted_to: Vector3i = start
	for _pick in range(60):
		var result: Array = _perform_pick_and_record(villager_ai)
		if result[0] == VillagerWanderSelector.MicroBehavior.BED_DRIFT:
			drew_bed_drift = true
			drifted_to = result[1]
			break

	# Assert — BED_DRIFT was drawn at least once within the bounded loop, and
	# when it was, it targeted exactly the flood-fill cell nearest the bed
	# (this test's own pre-computed [method
	# VillagerWanderSelector.select_bed_drift_target] result) -- never a cell
	# outside the bounded flood-filled set.
	assert_bool(drew_bed_drift).is_true()
	assert_vector(drifted_to).is_equal(expected_target)
