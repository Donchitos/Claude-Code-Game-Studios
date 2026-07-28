## Integration test — Villager AI story villager-ai-011 (Job claim/release
## pipeline with worker attribution; ADR-0016 primary, ADR-0008 secondary).
##
## Proves, against [VillagerAi._tick_deciding]/[VillagerAi.
## _attempt_claim_and_travel_to_job]/[VillagerAi.start_traveling]/[VillagerAi.
## _abandon_travel], using real [VoxelWorldGrid]/[VillagerNavGraph]/
## [VillagerJobSelector] and a mocked, duck-typed [ConstructionJobQueue]-
## shaped job queue (this story's own declared dependency set is 010 + 006
## only, not building-030 -- Sprint 7 QA plan, "necessarily exercises a
## mocked/duck-typed job queue"):
##
## 1. **AC8 / Edge Case 3**: two villagers racing the same job resolve to
##    exactly one deterministic winner (stable processing order), repeatable
##    across runs; the loser cleanly proceeds to its next F2 candidate in the
##    SAME Deciding pass -- never stalls in Deciding, never throws.
## 2. **Edge case (3 contenders)**: the same winner-determinism holds with a
##    THIRD villager racing the SAME single job; both losers fall cleanly to
##    Wandering (no second candidate exists).
## 3. **AC9**: pathing failure to a just-claimed job reports the failure to
##    the Building System, releases the claim, and returns the villager to
##    Deciding (Rule 6) -- the next candidate is tried on a later pass via
##    the existing abandon/re-queue mechanism (story 009), unchanged here.
## 4. **AC10**: a cell this villager itself reported unreachable is not
##    re-attempted until `unreachable_retry_ticks` have elapsed (this
##    villager's own per-cell retry cooldown), then IS retried successfully
##    once the cooldown expires.
## 5. **AC11**: every available job unreachable in one pass -> falls through
##    to Wandering, never stuck in Deciding.
## 6. **AC58**: a successful claim records the claiming villager's id,
##    retrievable for the Building System's `worker_ids` aggregation.
## 7. **Claim stickiness**: a periodic re-check against an already-held claim
##    never even touches `get_available_jobs`/`claim_job`.
## 8. **AC43's shared primitive**: the SAME atomic [method
##    ConstructionJobQueue.claim_job] two contenders call for one resource
##    (this story's own Implementation Notes: "reuse the same atomic-claim
##    primitive for bed ownership contention, Story 018 consumes it") --
##    exercised directly against the REAL [ConstructionJobQueue] (building-030
##    already landed in this codebase), proving the primitive itself, not
##    bed semantics (Story 018's own, explicitly out-of-scope, future job).
## 9. **Edge case**: a released claim is immediately re-offerable to any
##    villager, including the one that just released it.
##
## NOTE (accumulated pitfall): private `_`-prefixed fields are poked directly
## in several tests below (`_unreachable_retry_after_tick`, `_tick_count`) --
## an established convention in this codebase's own test suite (see
## `traveling_repath_test.gd`'s own direct `_from_cell`/`_to_cell` pokes).
class_name JobClaimAttributionTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles
# ---------------------------------------------------------------------------

## A [ConstructionJobQueue]-shaped mocked/duck-typed job queue (this story's
## own declared dependency set, Sprint 7 QA plan). Mirrors the REAL
## [ConstructionJobQueue]'s own eligibility contract closely enough for this
## story's own tests: a claimed cell is excluded from a subsequent
## [method get_available_jobs] call (exactly as the real queue's
## [method BuildProject.get_building_eligible_cells] excludes a
## non-`PLANNED` cell), and [method claim_job] is atomic -- exactly one
## caller ever wins a given cell.
class MockJobQueue:
	var _cells: Array[BlueprintCell] = []
	var _claimant_by_cell: Dictionary[Vector3i, int] = {}
	var get_available_jobs_call_count: int = 0
	var claim_job_call_count: int = 0
	var report_unreachable_call_count: int = 0
	var reported_unreachable_cells: Array[Vector3i] = []
	var release_claim_call_count: int = 0
	var last_released_villager_id: int = -1

	func add_job(cell: Vector3i) -> void:
		_cells.append(BlueprintCell.new(cell))

	func has_available_job() -> bool:
		return not get_available_jobs().is_empty()

	func get_available_jobs() -> Array[BlueprintCell]:
		get_available_jobs_call_count += 1
		var available: Array[BlueprintCell] = []
		for cell_data: BlueprintCell in _cells:
			if not _claimant_by_cell.has(cell_data.cell):
				available.append(cell_data)
		return available

	func claim_job(cell: Vector3i, villager_id: int) -> bool:
		claim_job_call_count += 1
		if _claimant_by_cell.has(cell):
			return false
		_claimant_by_cell[cell] = villager_id
		return true

	func release_claim(villager_id: int) -> void:
		release_claim_call_count += 1
		last_released_villager_id = villager_id
		var claimed_cell: Vector3i = Vector3i.ZERO
		var found: bool = false
		for cell_key: Vector3i in _claimant_by_cell:
			if _claimant_by_cell[cell_key] == villager_id:
				claimed_cell = cell_key
				found = true
				break
		if found:
			_claimant_by_cell.erase(claimed_cell)

	func report_unreachable(cell: Vector3i) -> bool:
		report_unreachable_call_count += 1
		reported_unreachable_cells.append(cell)
		return true

	func get_claimant(cell: Vector3i) -> int:
		return _claimant_by_cell.get(cell, -1)


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _solid() -> CellContents:
	return CellContents.new(1, 0)


## A flat, fully-connected NxN standable platform (mirrors
## `traveling_repath_test.gd`'s own established fixture).
func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), _solid())


## Two isolated 1-cell standable columns with nothing standable between them
## -- `find_path` returns empty by construction (mirrors
## `traveling_repath_test.gd`'s own `_make_disconnected_islands_grid`).
func _make_disconnected_islands_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 0, 0), _solid())
	grid.set_cell(Vector3i(4, 0, 4), _solid())
	return grid


func _make_bare_villager_ai(grid: VoxelWorldGrid) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.voxel_world = grid
	return villager_ai


func _make_deciding_villager(grid: VoxelWorldGrid, nav_graph: VillagerNavGraph, villager_id: int) -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = grid
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai.nav_graph = nav_graph
	villager_ai.villager_id = villager_id
	return villager_ai


func _place_villager(villager: VillagerAi, cell: Vector3i) -> void:
	villager.current_cell = cell
	villager._from_cell = cell
	villager._to_cell = cell


# ---------------------------------------------------------------------------
# AC8 / Edge Case 3 -- deterministic winner, loser proceeds to next candidate
# ---------------------------------------------------------------------------

func test_two_villagers_race_same_job_deterministic_winner_loser_falls_to_next_candidate() -> void:
	# Repeated across several fresh runs to prove determinism, not "usually
	# the same villager" (Edge Case 3's own wording).
	for _run in range(5):
		var grid: VoxelWorldGrid = _make_grid()
		_fill_flat_platform(grid, 5)
		var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
		var graph := VillagerNavGraph.new()
		graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)

		var villager0: VillagerAi = _make_deciding_villager(grid, graph, 0)
		var villager1: VillagerAi = _make_deciding_villager(grid, graph, 1)
		_place_villager(villager0, Vector3i(0, 1, 0))
		_place_villager(villager1, Vector3i(0, 1, 0))

		var jobs := MockJobQueue.new()
		jobs.add_job(Vector3i(4, 1, 0))  # A -- nearer to both
		jobs.add_job(Vector3i(4, 1, 2))  # B -- farther, the loser's fallback
		villager0.job_queue = jobs
		villager1.job_queue = jobs

		# Act -- stable processing order: villager 0 decides before villager 1.
		villager0._tick_deciding()
		villager1._tick_deciding()

		# Assert -- deterministic winner: villager 0 (earlier in stable order)
		# claimed the nearer job (A), every single run.
		assert_int(jobs.get_claimant(Vector3i(4, 1, 0))).is_equal(0)
		assert_int(villager0.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
		assert_int(villager0.get_state()).is_equal(VillagerAi.State.TRAVELING)

		# The loser (villager 1) cleanly proceeded to its next candidate (B)
		# in the SAME pass -- never stalled in Deciding, never threw.
		assert_int(jobs.get_claimant(Vector3i(4, 1, 2))).is_equal(1)
		assert_int(villager1.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
		assert_int(villager1.get_state()).is_equal(VillagerAi.State.TRAVELING)


func test_three_villagers_race_same_single_job_exactly_one_wins_others_fall_to_wandering() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 5)
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)

	var villagers: Array[VillagerAi] = []
	for i in range(3):
		var villager: VillagerAi = _make_deciding_villager(grid, graph, i)
		_place_villager(villager, Vector3i(0, 1, 0))
		villagers.append(villager)

	var jobs := MockJobQueue.new()
	jobs.add_job(Vector3i(4, 1, 0))  # exactly one job -- no fallback candidate
	for villager: VillagerAi in villagers:
		villager.job_queue = jobs

	# Act -- stable order: 0, 1, 2.
	for villager: VillagerAi in villagers:
		villager._tick_deciding()

	# Assert -- exactly one winner, deterministically the earliest.
	assert_int(jobs.get_claimant(Vector3i(4, 1, 0))).is_equal(0)
	assert_int(villagers[0].get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
	assert_int(villagers[0].get_state()).is_equal(VillagerAi.State.TRAVELING)

	# Both losers cleanly fall through to Wandering -- never stuck in
	# Deciding, never throw, no double-claim confusion.
	for i in [1, 2]:
		assert_int(villagers[i].get_state()).is_equal(VillagerAi.State.WANDERING)
		assert_int(villagers[i].get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)


# ---------------------------------------------------------------------------
# AC9 -- pathing failure to a claimed job: report + release + re-enter Deciding
# ---------------------------------------------------------------------------

func test_pathing_failure_to_claimed_job_reports_releases_and_records_retry_cooldown() -> void:
	var grid: VoxelWorldGrid = _make_disconnected_islands_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_deciding_villager(grid, graph, 0)
	_place_villager(villager, Vector3i(0, 1, 0))
	var jobs := MockJobQueue.new()
	villager.job_queue = jobs
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK

	var target := Vector3i(4, 1, 4)
	var started: bool = villager.start_traveling(target, VillagerAi.State.WORKING)

	# Rule 6/AC9: reported, released, back to Deciding -- never left stuck
	# traveling toward a dead target.
	assert_bool(started).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_int(jobs.release_claim_call_count).is_equal(1)
	assert_int(jobs.report_unreachable_call_count).is_equal(1)
	assert_array(jobs.reported_unreachable_cells).contains_exactly([target])
	# AC10's own cooldown bookkeeping is recorded against the SAME cell.
	assert_bool(villager._unreachable_retry_after_tick.has(target)).is_true()


# ---------------------------------------------------------------------------
# AC10 -- unreachable-job retry cooldown: suppressed, then retried on cadence
# ---------------------------------------------------------------------------

func test_unreachable_job_not_retried_until_unreachable_retry_ticks_elapse_then_retried() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 5)
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_deciding_villager(grid, graph, 0)
	_place_villager(villager, Vector3i(0, 1, 0))
	villager.config.unreachable_retry_ticks = 5
	var target := Vector3i(4, 1, 0)
	# This villager itself reported `target` unreachable at tick 0 -- still
	# cooling down until tick 5.
	villager._unreachable_retry_after_tick[target] = 5
	villager._tick_count = 0
	var jobs := MockJobQueue.new()
	jobs.add_job(target)
	villager.job_queue = jobs

	# Still cooling down -- the only candidate is excluded, so the pass falls
	# through to Wandering; the claim is never even attempted.
	villager._tick_deciding()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WANDERING)
	assert_int(jobs.claim_job_call_count).is_equal(0)

	# Advance past the cooldown threshold (AC10: "a retry attempt occurs").
	villager._tick_count = 5
	villager._tick_deciding()

	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
	assert_int(jobs.get_claimant(target)).is_equal(0)


# ---------------------------------------------------------------------------
# AC11 -- every available job unreachable: fall through to Wandering
# ---------------------------------------------------------------------------

func test_all_available_jobs_unreachable_falls_through_to_wandering_not_stuck_deciding() -> void:
	var grid: VoxelWorldGrid = _make_disconnected_islands_grid()
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(2, 1, 2), 5)
	var villager: VillagerAi = _make_deciding_villager(grid, graph, 0)
	_place_villager(villager, Vector3i(0, 1, 0))
	var jobs := MockJobQueue.new()
	jobs.add_job(Vector3i(4, 1, 4))  # the second, disconnected island
	villager.job_queue = jobs

	villager._tick_deciding()

	assert_int(villager.get_state()).is_equal(VillagerAi.State.WANDERING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)


# ---------------------------------------------------------------------------
# AC58 -- claim attribution recorded and retrievable
# ---------------------------------------------------------------------------

func test_successful_claim_records_claiming_villager_id_retrievable_for_attribution() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	_fill_flat_platform(grid, 3)
	var predicate_source: VillagerAi = _make_bare_villager_ai(grid)
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(1, 1, 1), 3)
	var villager: VillagerAi = _make_deciding_villager(grid, graph, 7)
	_place_villager(villager, Vector3i(0, 1, 0))
	var jobs := MockJobQueue.new()
	jobs.add_job(Vector3i(2, 1, 0))
	villager.job_queue = jobs

	villager._tick_deciding()

	assert_int(jobs.get_claimant(Vector3i(2, 1, 0))).is_equal(7)


# ---------------------------------------------------------------------------
# Claim stickiness -- periodic re-check never touches get_available_jobs/claim_job
# ---------------------------------------------------------------------------

func test_sticky_claim_periodic_recheck_never_touches_get_available_jobs_or_claim_job() -> void:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.scheduler = VillagerDecidingScheduler.new()
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	var jobs := MockJobQueue.new()
	jobs.add_job(Vector3i(4, 1, 0))
	villager.job_queue = jobs

	villager._tick_deciding()

	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
	assert_int(jobs.get_available_jobs_call_count).is_equal(0)
	assert_int(jobs.claim_job_call_count).is_equal(0)


# ---------------------------------------------------------------------------
# AC43 -- the SAME atomic-claim primitive bed contention will reuse
# ---------------------------------------------------------------------------

func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


func _released_project(id: int, cells: Array[Vector3i]) -> BuildProject:
	var project := BuildProject.new(id)
	for cell: Vector3i in cells:
		project.add_cell(_planned_cell(cell))
	project.release()
	return project


func test_atomic_claim_primitive_generalizes_ac43_bed_contention_analog() -> void:
	# Reuses the REAL Building System ConstructionJobQueue.claim_job as the
	# SAME atomic primitive Story 018 will apply unchanged to bed ownership
	# contention (this story's own Implementation Notes: "reuse the same
	# atomic-claim primitive for bed ownership contention") -- proves the
	# PRIMITIVE itself: two contenders for ONE resource, first caller (stable
	# order) wins, atomically, deterministically. Real bed semantics remain
	# Story 018's own, explicitly out-of-scope, future job.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	var tick_loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	tick_loop.voxel_world = grid
	tick_loop.config = ConstructionTickLoopConfig.new()
	tick_loop.time_tick_system = auto_free(MockTimeTickSystem.new())
	tick_loop.setup()
	var queue := ConstructionJobQueue.new(tick_loop)
	var cell := Vector3i(9, 9, 9)
	var project: BuildProject = _released_project(1, [cell])
	queue.add_project(project)

	var contender_a_won: bool = queue.claim_job(cell, 100)
	var contender_b_won: bool = queue.claim_job(cell, 200)

	assert_bool(contender_a_won).is_true()
	assert_bool(contender_b_won).is_false()
	assert_bool(queue.has_claim(100)).is_true()
	assert_bool(queue.has_claim(200)).is_false()


# ---------------------------------------------------------------------------
# Edge case -- a released claim is immediately re-offerable, incl. to the
# releasing villager itself
# ---------------------------------------------------------------------------

func test_released_claim_is_immediately_reofferable_including_to_the_releasing_villager() -> void:
	var jobs := MockJobQueue.new()
	var cell := Vector3i(1, 2, 3)
	jobs.add_job(cell)

	assert_bool(jobs.claim_job(cell, 5)).is_true()
	jobs.release_claim(5)
	assert_bool(jobs.claim_job(cell, 5)).is_true()
