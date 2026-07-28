## Unit test — Villager AI story 006 (activity priority decision loop, GDD
## Rule 2/3, ADR-0008 Decision §1).
##
## Proves, against [VillagerAi._tick_deciding] / [VillagerAi._on_tick] /
## [VillagerAi.get_state] / [VillagerAi.get_pursued_activity]:
## 1. **AC1**: urgent need + available job -> the need is chosen (tier 1
##    wins over tier 2).
## 2. **AC2**: available job + no urgent need -> the job is chosen over
##    wandering (tier 2 wins over tier 3).
## 3. **AC3**: no jobs, no urgent needs -> the villager wanders, repeatedly,
##    with no error (tier 3 floor; also proves nil-safety of both mocked
##    boundaries when neither dependency is wired at all).
## 4. **AC4**: a Working villager whose need becomes urgent -> the
##    `decision_interval` re-check completes the current tick's work FIRST
##    (proven via a spy override snapshotting state mid-call), THEN releases
##    the claim and pursues the need -- graceful preemption, in that order,
##    within one [method VillagerAi._on_tick] call.
## 5. **AC41**: a Working villager with no urgent need -> the periodic
##    re-check leaves it Working, no state change, and never even consults
##    [member VillagerAi.job_queue] -- claims are sticky, never a job
##    re-selection against a held claim.
## 6. **AC5**: any activity ends -> the next state is fully assigned within
##    the SAME tick's decide() invocation -- one [method
##    MockTimeTickSystem.fire_tick] call is enough, no second tick needed.
## 7. **Edge Case 3b**: an urgent need firing while already Traveling to
##    satisfy that SAME need is a no-op -- no re-transition, no claim
##    release (there is none to release).
class_name PriorityDecisionLoopTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles (declared above the test functions per this codebase's own
# GdUnit4 convention for inner helper classes, see deciding_scheduler_test.gd)
# ---------------------------------------------------------------------------

## Minimal Needs & Mood-shaped test double (mocked boundary -- this story's
## Engine Notes: "Needs & Mood values are mocked at the need-is-urgent
## boundary"). Implements [VillagerAi._has_urgent_need]'s own dependency,
## plus Story villager-ai-018's own `start_recovery`/`stop_recovery`/
## `get_need_state` seam (no-op/stub bodies -- this file's own ACs are
## priority-list ordering, not sleep/recovery mechanics, which
## `sleep_and_home_test.gd` covers instead).
class MockNeedsProvider:
	var urgent: bool = false
	var recovering: bool = false

	func has_urgent_need(_villager_id: int) -> bool:
		return urgent

	func start_recovery(_villager_id: int, _need: StringName, _source_enum: NeedsMood.RecoverySource) -> void:
		pass

	func stop_recovery(_villager_id: int, _need: StringName, _reason: StringName) -> void:
		pass

	func get_need_state(_villager_id: int, _need: StringName) -> NeedsMood.NeedState:
		return NeedsMood.NeedState.RECOVERING if recovering else NeedsMood.NeedState.SATISFIED


## Minimal Building-System-job-queue-shaped test double (mocked boundary --
## Story 010/011 own the real queue). Implements the full duck-typed
## contract [VillagerAi]'s job_queue depends on as of Story villager-ai-011
## (`has_available_job`/`release_claim`, story 006, plus
## `get_available_jobs`/`claim_job`/`report_unreachable`, story 011) --
## counts calls so a test can assert AC41's "never even re-runs job
## selection against a held claim" precisely (call-count zero), not just
## "state didn't change."
class MockJobQueue:
	var available: bool = false
	var jobs: Array[BlueprintCell] = []
	var has_available_job_call_count: int = 0
	var release_claim_call_count: int = 0
	var last_released_villager_id: int = -1
	var _claimed_by: Dictionary[Vector3i, int] = {}

	func has_available_job() -> bool:
		has_available_job_call_count += 1
		return available

	func get_available_jobs() -> Array[BlueprintCell]:
		var result: Array[BlueprintCell] = []
		for job: BlueprintCell in jobs:
			if not _claimed_by.has(job.cell):
				result.append(job)
		return result

	func claim_job(cell: Vector3i, villager_id: int) -> bool:
		if _claimed_by.has(cell):
			return false
		_claimed_by[cell] = villager_id
		return true

	func release_claim(villager_id: int) -> void:
		release_claim_call_count += 1
		last_released_villager_id = villager_id

	func report_unreachable(_cell: Vector3i) -> bool:
		return true


## Spy subclass recording whether/when [method VillagerAi._tick_working]
## ran, and this villager's [member VillagerAi._state] at the EXACT moment
## it ran -- proving AC4's "current tick's work completes" happens BEFORE
## any preemption transition within the same [method VillagerAi._on_tick]
## call, not merely that both eventually occur.
class SpyWorkingVillagerAi:
	extends VillagerAi

	var tick_working_call_count: int = 0
	var state_during_tick_working: State = State.DECIDING

	func _tick_working() -> void:
		tick_working_call_count += 1
		state_during_tick_working = _state


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_villager_ai() -> VillagerAi:
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	return villager_ai


func _make_flat_grid(size: int) -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))
	return grid


## A villager capable of actually committing to and traveling toward a job
## site (Story villager-ai-011's own wiring of [VillagerJobSelector.
## select_job] + [method VillagerAi.start_traveling] into tier 2) -- a flat,
## fully-connected 3x3 platform + a shared [VillagerNavGraph], mirroring
## `traveling_repath_test.gd`'s own established fixture shape. Placed at
## (0, 1, 0); every job candidate this file's own tests offer sits 2+ cells
## away so a real multi-step path is acquired (never the immediate-arrival,
## `path.size() == 1` branch) -- keeping this file's pre-existing
## TRAVELING/WORK assertions (story 006) unchanged by story 011's real
## wiring.
func _make_travel_capable_villager_ai() -> VillagerAi:
	var grid: VoxelWorldGrid = _make_flat_grid(3)
	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(1, 1, 1), 3)
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = grid
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai.nav_graph = graph
	villager_ai.current_cell = Vector3i(0, 1, 0)
	villager_ai._from_cell = villager_ai.current_cell
	villager_ai._to_cell = villager_ai.current_cell
	return villager_ai


## A Working villager with a held job claim, its own scheduler already
## armed runnable this "tick" -- the shared precondition for the AC4/AC41
## preemption-check tests, which both drive the decision through [method
## VillagerAi._on_tick] (not a bare [method VillagerAi._tick_deciding] call)
## to prove the ordering/gating gate that only lives in `_on_tick`.
func _make_working_villager_runnable() -> SpyWorkingVillagerAi:
	var villager_ai: SpyWorkingVillagerAi = auto_free(SpyWorkingVillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai._state = VillagerAi.State.WORKING
	villager_ai._pursued_activity = VillagerAi.PursuedActivity.WORK
	villager_ai.scheduler.enqueue(villager_ai.villager_id)
	villager_ai.scheduler.advance_tick(1)
	return villager_ai


# ---------------------------------------------------------------------------
# AC1 — urgent need + available job: the need wins (tier 1 > tier 2)
# ---------------------------------------------------------------------------

func test_urgent_need_and_available_job_chooses_need() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	var needs: MockNeedsProvider = MockNeedsProvider.new()
	needs.urgent = true
	var jobs: MockJobQueue = MockJobQueue.new()
	jobs.available = true
	villager_ai.needs_provider = needs
	villager_ai.job_queue = jobs

	villager_ai._tick_deciding()

	# Story villager-ai-018: tier 1 (NEED) still wins over tier 2 (WORK) --
	# this test's own AC1 scope -- but with neither `nav_graph` nor
	# `bed_provider` wired, real target-selection (story 018's own scope,
	# a placeholder `State.TRAVELING` before this story landed) now falls
	# all the way through to the honest `ground_no_bed_owned` fallback:
	# `State.SLEEPING`, still pursuing `NEED`.
	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(villager_ai.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NEED)


# ---------------------------------------------------------------------------
# AC2 — available job, no urgent need: the job wins over wandering
# ---------------------------------------------------------------------------

func test_available_job_no_urgent_need_chooses_job_over_wandering() -> void:
	var villager_ai: VillagerAi = _make_travel_capable_villager_ai()
	var needs: MockNeedsProvider = MockNeedsProvider.new()
	needs.urgent = false
	var jobs: MockJobQueue = MockJobQueue.new()
	jobs.available = true
	jobs.jobs = [BlueprintCell.new(Vector3i(2, 1, 0))]
	villager_ai.needs_provider = needs
	villager_ai.job_queue = jobs

	villager_ai._tick_deciding()

	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_int(villager_ai.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)


func test_needs_provider_unwired_is_treated_as_no_urgent_need() -> void:
	# Nil-safety: only job_queue is wired -- needs_provider is left null.
	var villager_ai: VillagerAi = _make_travel_capable_villager_ai()
	var jobs: MockJobQueue = MockJobQueue.new()
	jobs.available = true
	jobs.jobs = [BlueprintCell.new(Vector3i(2, 1, 0))]
	villager_ai.job_queue = jobs

	villager_ai._tick_deciding()

	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_int(villager_ai.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)


# ---------------------------------------------------------------------------
# AC3 — no jobs, no urgent needs: wanders indefinitely, no error
# ---------------------------------------------------------------------------

func test_no_jobs_no_needs_wanders_repeatedly_without_error() -> void:
	# Neither needs_provider nor job_queue is wired at all -- proves both
	# mocked boundaries are nil-safe simultaneously, and that repeated
	# Deciding passes never error or drift out of Wandering (Edge Case 12).
	var villager_ai: VillagerAi = _make_villager_ai()

	for _i in range(5):
		villager_ai._tick_deciding()
		assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.WANDERING)
		assert_int(villager_ai.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)


# ---------------------------------------------------------------------------
# AC4 — Working + need becomes urgent: current tick's work completes FIRST,
# then the claim releases and the need is pursued (graceful preemption)
# ---------------------------------------------------------------------------

func test_working_villager_need_becomes_urgent_completes_tick_then_releases_claim_and_pursues_need() -> void:
	var villager_ai: SpyWorkingVillagerAi = _make_working_villager_runnable()
	var needs: MockNeedsProvider = MockNeedsProvider.new()
	needs.urgent = true
	var jobs: MockJobQueue = MockJobQueue.new()
	villager_ai.needs_provider = needs
	villager_ai.job_queue = jobs

	villager_ai._on_tick()

	# The current tick's work ran, and it ran WHILE still Working -- before
	# any preemption transition occurred.
	assert_int(villager_ai.tick_working_call_count).is_equal(1)
	assert_int(villager_ai.state_during_tick_working).is_equal(VillagerAi.State.WORKING)
	# The claim released exactly once, for this villager.
	assert_int(jobs.release_claim_call_count).is_equal(1)
	assert_int(jobs.last_released_villager_id).is_equal(villager_ai.villager_id)
	# The need is now pursued. Story villager-ai-018: with neither
	# `nav_graph` nor `bed_provider` wired, real target-selection falls
	# through to the honest `ground_no_bed_owned` fallback (State.SLEEPING),
	# not the pre-story-018 `State.TRAVELING` placeholder.
	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.SLEEPING)
	assert_int(villager_ai.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NEED)


# ---------------------------------------------------------------------------
# AC41 — Working, no urgent need: stays Working, no state change, no
# job re-selection against the held claim
# ---------------------------------------------------------------------------

func test_working_villager_no_urgent_need_stays_working_with_no_reselection() -> void:
	var villager_ai: SpyWorkingVillagerAi = _make_working_villager_runnable()
	var needs: MockNeedsProvider = MockNeedsProvider.new()
	needs.urgent = false
	var jobs: MockJobQueue = MockJobQueue.new()
	jobs.available = true  # a job IS available -- the held claim must stay sticky regardless
	villager_ai.needs_provider = needs
	villager_ai.job_queue = jobs

	villager_ai._on_tick()

	assert_int(villager_ai.tick_working_call_count).is_equal(1)
	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.WORKING)
	assert_int(villager_ai.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
	# The claim-sticky guarantee: job selection is never even RE-RUN.
	assert_int(jobs.has_available_job_call_count).is_equal(0)
	assert_int(jobs.release_claim_call_count).is_equal(0)


# ---------------------------------------------------------------------------
# AC5 — the next state is fully assigned within the SAME tick's decide()
# invocation; no second tick is needed
# ---------------------------------------------------------------------------

func test_decide_assigns_next_state_within_the_same_tick_no_extra_tick_needed() -> void:
	var grid: VoxelWorldGrid = _make_flat_grid(3)
	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	var graph := VillagerNavGraph.new()
	graph.build(grid, predicate_source, Vector3i(1, 1, 1), 3)
	var villager_ai: VillagerAi = auto_free(VillagerAi.new())
	villager_ai.config = VillagerAIConfig.new()
	villager_ai.voxel_world = grid
	villager_ai.scheduler = VillagerDecidingScheduler.new()
	villager_ai.nav_graph = graph
	villager_ai.current_cell = Vector3i(0, 1, 0)
	villager_ai._from_cell = villager_ai.current_cell
	villager_ai._to_cell = villager_ai.current_cell
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	villager_ai.time_tick_system = mock_tick
	var jobs: MockJobQueue = MockJobQueue.new()
	jobs.available = true
	jobs.jobs = [BlueprintCell.new(Vector3i(2, 1, 0))]
	villager_ai.job_queue = jobs
	villager_ai.setup()
	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.DECIDING)

	# Act — exactly one tick.
	mock_tick.fire_tick()

	# Assert — the decision fully completed within this single tick; no
	# second fire_tick() call is needed to observe the new state.
	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_int(villager_ai.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)


# ---------------------------------------------------------------------------
# Edge Case 3b — urgent need firing while already Traveling to satisfy that
# SAME need is a no-op
# ---------------------------------------------------------------------------

func test_urgent_need_while_already_traveling_for_same_need_is_noop() -> void:
	var villager_ai: VillagerAi = _make_villager_ai()
	var needs: MockNeedsProvider = MockNeedsProvider.new()
	needs.urgent = true
	var jobs: MockJobQueue = MockJobQueue.new()
	villager_ai.needs_provider = needs
	villager_ai.job_queue = jobs
	villager_ai._state = VillagerAi.State.TRAVELING
	villager_ai._pursued_activity = VillagerAi.PursuedActivity.NEED

	villager_ai._tick_deciding()

	assert_int(villager_ai.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_int(villager_ai.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NEED)
	assert_int(jobs.release_claim_call_count).is_equal(0)
