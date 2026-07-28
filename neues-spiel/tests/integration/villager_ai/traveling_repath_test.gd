## Integration test — Villager AI story villager-ai-009 (Traveling state:
## path acquisition, step-by-step following, arrival, mid-travel re-path,
## unreachable abandonment; ADR-0009 primary, ADR-0007 secondary).
##
## Proves, against [VillagerAi.start_traveling]/[VillagerAi._tick_traveling]/
## [VillagerAi._on_repath_evaluation_requested]/
## [VillagerAi.get_remaining_movement_cells]:
## 1. **Path acquisition + step-by-step following + arrival**: a multi-step
##    path is followed cell-by-cell, tick-boundary by tick-boundary, and
##    arrival transitions to the caller-supplied arrival state
##    (Working/Sleeping — proving genericity, not a hardcoded state).
## 2. **F1 zero-length target**: `start_traveling` to the villager's own
##    current cell completes arrival immediately, no tick needed.
## 3. **get_remaining_movement_cells widened**: once actually traveling, the
##    ENTIRE remaining route is returned, not merely the in-flight step
##    (story 008's own reserved widening — zero lines changed there).
## 4. **AC18 (mid-travel re-path, detour available)**: a write at the
##    villager's very next step cell redirects it onto a fresh route,
##    synchronously, within the write's own call stack (race closure) —
##    proven by asserting the redirect is already visible immediately after
##    the write call returns, with no intervening `_process`/tick.
## 5. **AC19 (unreachable, no re-path possible → abandon)**: both the direct
##    (`start_traveling` to an ungraph-connected target) and the mid-travel
##    (a write severing the only route) flavors exit to `State.DECIDING`,
##    never keep traveling toward a dead target.
## 6. **Per-target fallback (GDD Edge Case 1)**: abandonment releases the
##    held job claim ONLY when `PursuedActivity.WORK` was being pursued —
##    never for `NEED`/`NONE`. Story villager-ai-018 (this revision) fills in
##    `NEED`'s own fallback for real: an unreachable owned bed falls back to
##    ground sleep (`State.SLEEPING`, still pursuing `NEED`, source enum
##    `ground_bed_unreachable`) rather than the pre-018 placeholder
##    (`State.DECIDING`/`PursuedActivity.NONE`) — `NONE` (wander-reselection)
##    remains Story 019's own future scope, unchanged.
##
## NOTE (accumulated pitfall): signal-fire counters use a captured [Array]
## with `.append()`/`.size()`, never a captured scalar `+= 1` inside a
## lambda — GDScript closures do not write back captured scalars.
class_name TravelingRepathTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles
# ---------------------------------------------------------------------------

## Minimal Building-System-job-queue-shaped test double (mocked boundary,
## mirrors `priority_decision_loop_test.gd`'s own `MockJobQueue` exactly) --
## counts `release_claim`/`report_unreachable` calls so the per-target-
## fallback tests can assert call-count precisely, not just "state didn't
## change." `report_unreachable` added by Story villager-ai-011 (Rule 6/AC9 --
## [method VillagerAi._abandon_travel]'s WORK branch now calls it).
class MockJobQueue:
	var available: bool = false
	var release_claim_call_count: int = 0
	var last_released_villager_id: int = -1
	var report_unreachable_call_count: int = 0
	var last_reported_unreachable_cell: Vector3i = Vector3i.ZERO

	func has_available_job() -> bool:
		return available

	func release_claim(villager_id: int) -> void:
		release_claim_call_count += 1
		last_released_villager_id = villager_id

	func report_unreachable(cell: Vector3i) -> bool:
		report_unreachable_call_count += 1
		last_reported_unreachable_cell = cell
		return true


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _solid() -> CellContents:
	return CellContents.new(1, 0)


## A flat, fully-connected NxN standable platform: solid ground at y=0 for
## every (x, z) in `[0, size) x [0, size)`, leaving (x, 1, z) standable
## everywhere in that footprint — every interior cell has a detour available
## around any single blocked neighbor.
func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), _solid())


## A 1-cell-WIDE corridor along +x at z=0 only (no ground at any other z) --
## blocking any interior cell severs the only route, with no lateral detour
## possible (proves the AC19 "no re-path possible" flavor via a live write).
func _fill_corridor(grid: VoxelWorldGrid, length: int) -> void:
	for x in range(length):
		grid.set_cell(Vector3i(x, 0, 0), _solid())


## A [VillagerAi] with only [member VillagerAi.voxel_world] wired -- enough
## to serve as [VillagerNavGraph]'s `predicate_source` (mirrors
## `graph_patching_test.gd`'s own `_make_bare_villager_ai` fixture).
func _make_bare_villager_ai(grid: VoxelWorldGrid) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.voxel_world = grid
	return villager_ai


## A villager wired for direct `start_traveling`/`_tick_traveling` exercise
## (config/voxel_world/scheduler/nav_graph) -- deliberately WITHOUT calling
## [method VillagerAi.setup] (no live signal wiring needed for these tests;
## they drive ticks directly).
func _make_traveling_villager(grid: VoxelWorldGrid, nav_graph: VillagerNavGraph) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = grid
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai.nav_graph = nav_graph
	return villager_ai


## A fully [method VillagerAi.setup]-ed villager with a shared
## [VillagerNavGraph] wired, for the LIVE mid-travel re-path tests (AC18/19,
## race closure). Follows this story's own documented wiring-order
## requirement: [method VillagerNavGraph.subscribe_to_voxel_world] is called
## BEFORE this villager's own [method VillagerAi.setup] so the graph patches
## a blocking write before this villager's own repath recompute reads it
## (Godot fires synchronous signal connections in connection order).
func _make_setup_traveling_villager(grid: VoxelWorldGrid, nav_graph: VillagerNavGraph) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = grid
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai.time_tick_system = auto_free(MockTimeTickSystem.new())
	villager_ai.nav_graph = nav_graph
	nav_graph.subscribe_to_voxel_world(grid, villager_ai)
	villager_ai.setup()
	return villager_ai


## Places [param villager] at [param cell] (both the discrete authoritative
## value and the stationary from/to pair) — the "spawn point" every test
## below starts from.
func _place_villager(villager: VillagerAi, cell: Vector3i) -> void:
	villager.current_cell = cell
	villager._from_cell = cell
	villager._to_cell = cell


## Drives exactly one Traveling step to completion: forces
## [method VillagerAi.advance_travel_progress] to `1.0` regardless of the
## current step's length (a deliberately huge `game_delta`), then calls
## [method VillagerAi._on_tick] once — crediting arrival for the just-
## completed step and letting [method VillagerAi._tick_traveling] advance to
## the next step (or complete arrival), exactly mirroring one real
## tick-boundary crossing.
func _drive_one_step(villager: VillagerAi) -> void:
	villager.advance_travel_progress(1000.0)
	villager._on_tick()


# ---------------------------------------------------------------------------
# Path acquisition + step-by-step following + arrival
# ---------------------------------------------------------------------------

func test_start_traveling_follows_multi_step_path_and_arrives_transitioning_state() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 5)
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_traveling_villager(grid, graph)
	_place_villager(villager, Vector3i(0, 1, 0))

	var started: bool = villager.start_traveling(Vector3i(4, 1, 0), VillagerAi.State.WORKING)

	assert_bool(started).is_true()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_vector(Vector3(villager._to_cell)).is_equal(Vector3(Vector3i(1, 1, 0)))

	for _i in range(4):
		_drive_one_step(villager)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.WORKING)
	assert_vector(Vector3(villager.get_current_cell())).is_equal(Vector3(Vector3i(4, 1, 0)))


func test_start_traveling_arrival_state_is_generic_supports_sleeping() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(1, 1, 1), 3)
	var villager: VillagerAi = _make_traveling_villager(grid, graph)
	_place_villager(villager, Vector3i(0, 1, 0))

	villager.start_traveling(Vector3i(1, 1, 0), VillagerAi.State.SLEEPING)
	_drive_one_step(villager)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)


func test_start_traveling_zero_length_target_completes_arrival_immediately() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(1, 1, 1), 3)
	var villager: VillagerAi = _make_traveling_villager(grid, graph)
	_place_villager(villager, Vector3i(1, 1, 1))

	var started: bool = villager.start_traveling(Vector3i(1, 1, 1), VillagerAi.State.WORKING)

	assert_bool(started).is_true()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WORKING)
	assert_bool(villager.is_moving()).is_false()


# ---------------------------------------------------------------------------
# get_remaining_movement_cells — widened to the FULL remaining path
# ---------------------------------------------------------------------------

func test_get_remaining_movement_cells_covers_full_remaining_path_once_traveling() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 5)
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_traveling_villager(grid, graph)
	_place_villager(villager, Vector3i(0, 1, 0))

	villager.start_traveling(Vector3i(3, 1, 0), VillagerAi.State.WORKING)

	assert_array(villager.get_remaining_movement_cells()).contains_exactly([
		Vector3i(0, 1, 0), Vector3i(1, 1, 0), Vector3i(2, 1, 0), Vector3i(3, 1, 0),
	])


# ---------------------------------------------------------------------------
# AC19 (direct) — unreachable target abandons, dispatched by pursued activity
# ---------------------------------------------------------------------------

## Two isolated 1-cell standable columns in the same bounded nav region, far
## enough apart (and with nothing standable between them) that no path can
## ever connect them -- `find_path` returns an empty array by construction.
func _make_disconnected_islands_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid())
	grid.set_cell(Vector3i(4, 0, 4), _solid())
	return grid


func test_start_traveling_unreachable_target_abandons_and_releases_work_claim() -> void:
	var grid: VoxelWorldGrid = _make_disconnected_islands_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_traveling_villager(grid, graph)
	var jobs := MockJobQueue.new()
	villager.job_queue = jobs
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	_place_villager(villager, Vector3i(0, 1, 0))

	var started: bool = villager.start_traveling(Vector3i(4, 1, 4), VillagerAi.State.WORKING)

	assert_bool(started).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_int(jobs.release_claim_call_count).is_equal(1)
	assert_int(jobs.last_released_villager_id).is_equal(villager.villager_id)
	# Story villager-ai-011 (Rule 6/AC9): the unreachable job is also
	# reported to the Building System.
	assert_int(jobs.report_unreachable_call_count).is_equal(1)
	assert_vector(Vector3(jobs.last_reported_unreachable_cell)).is_equal(Vector3(Vector3i(4, 1, 4)))


func test_start_traveling_unreachable_target_abandons_without_releasing_claim_when_pursuing_need() -> void:
	# Story villager-ai-018: an owned-but-unreachable bed's own AC24/Edge
	# Case 1 fallback is ground sleep, still pursuing NEED — not the pre-018
	# placeholder (abandon to Deciding, reset to NONE).
	var grid: VoxelWorldGrid = _make_disconnected_islands_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_traveling_villager(grid, graph)
	var jobs := MockJobQueue.new()
	villager.job_queue = jobs
	villager._pursued_activity = VillagerAi.PursuedActivity.NEED
	_place_villager(villager, Vector3i(0, 1, 0))

	villager.start_traveling(Vector3i(4, 1, 4), VillagerAi.State.SLEEPING)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NEED)
	assert_int(jobs.release_claim_call_count).is_equal(0)


func test_start_traveling_unreachable_target_abandons_without_releasing_claim_when_wandering() -> void:
	var grid: VoxelWorldGrid = _make_disconnected_islands_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_traveling_villager(grid, graph)
	var jobs := MockJobQueue.new()
	villager.job_queue = jobs
	villager._pursued_activity = VillagerAi.PursuedActivity.NONE
	_place_villager(villager, Vector3i(0, 1, 0))

	villager.start_traveling(Vector3i(4, 1, 4), VillagerAi.State.WANDERING)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(jobs.release_claim_call_count).is_equal(0)


# ---------------------------------------------------------------------------
# AC18 — mid-travel re-path: detour available, redirected synchronously
# ---------------------------------------------------------------------------

func test_write_at_next_step_cell_mid_travel_redirects_onto_a_detour() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 5)
	var graph := VillagerNavGraph.new()
	var villager: VillagerAi = _make_setup_traveling_villager(grid, graph)
	graph.build(grid, villager, Vector3i(2, 1, 2), 5)
	_place_villager(villager, Vector3i(0, 1, 0))
	villager.start_traveling(Vector3i(4, 1, 0), VillagerAi.State.WORKING)
	var original_to_cell: Vector3i = villager._to_cell
	assert_vector(Vector3(original_to_cell)).is_equal(Vector3(Vector3i(1, 1, 0)))

	# Act — a write directly at the villager's own next step cell, blocking
	# it (solid → non-standable). This is the SAME call that synchronously
	# patches the shared graph (subscribed first) AND triggers this
	# villager's own re-path recompute (subscribed second) -- both within
	# this single `set_cell` call.
	grid.set_cell(original_to_cell, _solid())

	# Assert — the redirect ALREADY happened, in the same call, with no
	# `_process`/tick call in between (race closure): a detour exists on the
	# fully-connected platform, so the villager keeps Traveling onto a
	# DIFFERENT next cell, with a freshly-reset step.
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_vector(Vector3(villager._to_cell)).is_not_equal(Vector3(original_to_cell))
	assert_float(villager._intra_tick_progress).is_equal_approx(0.0, 0.0001)


func test_repath_redirect_happens_synchronously_before_next_process_frame() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 5)
	var graph := VillagerNavGraph.new()
	var villager: VillagerAi = _make_setup_traveling_villager(grid, graph)
	graph.build(grid, villager, Vector3i(2, 1, 2), 5)
	_place_villager(villager, Vector3i(0, 1, 0))
	villager.start_traveling(Vector3i(4, 1, 0), VillagerAi.State.WORKING)
	var original_to_cell: Vector3i = villager._to_cell
	# Simulate being partway through the step BEFORE the write lands.
	villager._intra_tick_progress = 0.5
	villager._process(0.016)
	var position_mid_step_toward_blocked_cell: Vector3 = villager._visual_position

	# Act — the blocking write; the redirect (progress reset to 0.0, _to_cell
	# replaced) must already be visible the instant this call returns.
	grid.set_cell(original_to_cell, _solid())

	# Assert — no further _process()/tick call needed to observe the
	# redirect: the villager's OWN state already reflects a fresh step
	# targeting a different cell, before the caller ever calls _process()
	# again.
	assert_vector(Vector3(villager._to_cell)).is_not_equal(Vector3(original_to_cell))
	assert_float(villager._intra_tick_progress).is_equal_approx(0.0, 0.0001)

	# A subsequent _process() frame now lerps toward the NEW destination,
	# starting fresh from the villager's current (world) position -- never
	# continuing to advance toward the now-solid, abandoned cell.
	villager._process(0.016)
	assert_vector(villager._visual_position).is_not_equal(position_mid_step_toward_blocked_cell)


# ---------------------------------------------------------------------------
# AC19 (via mid-travel write) — no detour possible, abandon to Deciding
# ---------------------------------------------------------------------------

func test_write_severs_only_route_mid_travel_triggers_abandon_to_deciding() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_corridor(grid, 5)
	var graph := VillagerNavGraph.new()
	var villager: VillagerAi = _make_setup_traveling_villager(grid, graph)
	graph.build(grid, villager, Vector3i(2, 1, 2), 5)
	var jobs := MockJobQueue.new()
	villager.job_queue = jobs
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	_place_villager(villager, Vector3i(0, 1, 0))
	villager.start_traveling(Vector3i(4, 1, 0), VillagerAi.State.WORKING)
	var blocked_cell: Vector3i = villager._to_cell
	assert_vector(Vector3(blocked_cell)).is_equal(Vector3(Vector3i(1, 1, 0)))

	# Act — blocks the corridor's only route by writing the cell in ITS OWN
	# clearance column (one cell directly above it), never the movement cell
	# itself: writing (1,1,0) itself solid would give (1,2,0) a NEW "solid
	# below" support, creating a legal 1-height step-up-and-over bypass
	# (correct GDD Rule 9 staircase behaviour, but not what this test wants
	# to prove) — writing the clearance cell instead removes (1,1,0)'s own
	# standability (clearance column no longer fully empty) without ever
	# making (1,1,0) itself solid, so no new support surface is created
	# anywhere; still falls inside the re-path filter's envelope (movement
	# cell + the 2 cells directly above it, GDD Rule 10b), so the filter
	# still fires. No lateral detour exists either (`_fill_corridor` never
	# places ground at any other z) — the recomputed path from the
	# villager's current cell toward its original target is genuinely empty.
	grid.set_cell(blocked_cell + Vector3i(0, 1, 0), _solid())

	# Assert — graceful abandonment, never stuck traveling toward a dead
	# target; the held job claim released exactly once (WORK's own
	# per-target fallback).
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_int(jobs.release_claim_call_count).is_equal(1)
	# Story villager-ai-011 (Rule 6/AC9): the mid-travel redirect failure is
	# ALSO reported -- the SAME [method VillagerAi._abandon_travel] WORK
	# branch, regardless of which caller (direct or mid-travel recompute)
	# triggered it.
	assert_int(jobs.report_unreachable_call_count).is_equal(1)


# ---------------------------------------------------------------------------
# Defensive guard — a repath signal for a non-Traveling "moving" villager
# (e.g. a hand-constructed fixture that never wires nav_graph) is a no-op
# ---------------------------------------------------------------------------

func test_repath_signal_for_non_traveling_villager_with_no_nav_graph_is_a_noop() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.voxel_world = grid
	villager.scheduler = VillagerDecidingScheduler.new()
	villager.time_tick_system = auto_free(MockTimeTickSystem.new())
	villager.setup()
	# `_from_cell`/`_to_cell` set apart directly, WITHOUT ever calling
	# start_traveling() -- `_state` stays DECIDING (its construction
	# default) and `nav_graph` is left null, exactly mirroring story 008's
	# own `graph_patching_test.gd` fixtures.
	villager._from_cell = Vector3i(0, 0, 0)
	villager._to_cell = Vector3i(1, 0, 0)

	# Act — a write at the moving villager's own movement cell would
	# otherwise fire the repath filter; the internal handler must no-op
	# (State guard) rather than crash on a null nav_graph.
	grid.set_cell(Vector3i(1, 0, 0), _solid())

	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
