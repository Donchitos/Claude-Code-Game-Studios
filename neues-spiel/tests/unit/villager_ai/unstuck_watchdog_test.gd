## Unit test — Villager AI story villager-ai-015 (Unstuck Watchdog trigger,
## rescue teleport, and F3 telemetry; GDD Rule 15/15b/F5,
## [TR-villager-ai-behavior-099]/[TR-villager-ai-behavior-104]/
## [TR-villager-ai-behavior-080], ADR-0008 primary / ADR-0009 secondary).
##
## Proves, against [VillagerAi._on_tick]/[VillagerAi._update_unstuck_watchdog]/
## [VillagerAi._attempt_watchdog_rescue]/[VillagerAi._perform_watchdog_rescue],
## real [VoxelWorldGrid]/[VillagerRescueTargetSearch]/[VillagerUnstuckTelemetry]
## (never a re-derived fake BFS or telemetry stand-in -- mirrors
## job_claim_attribution_test.gd's own "no mocked pathfinding" precedent):
##
## 1. **AC51**: a Traveling villager stuck (zero legal step, walled in on an
##    otherwise-standable cell) for `unstuck_watchdog_threshold_ticks`
##    teleports to the F5 rescue cell, releases its held claim, and fires
##    both the per-villager and world-total telemetry counters.
## 2. **AC51b**: the SAME trigger also fires from the OTHER half of the OR
##    condition -- `current_cell` itself failing standability.
## 3. **AC52**: a held claim releases exactly once (no double-release, no
##    orphan); no held claim (traveling to a bed, `PursuedActivity.NEED`) has
##    zero claim-release side effect.
## 4. **Snap, no lerp**: the rescue sets `current_cell` atomically and snaps
##    `_visual_position` to the exact rescue-cell world position -- no
##    partial interpolation.
## 5. **AC32**: Wandering/Sleeping/Breather villagers with no legal step stay
##    put with the distress flag set, never teleport, never accumulate
##    `stuck_tick_count` (Edge Case 2's scope-boundary complement).
## 6. **Relief resets the counter**: `stuck_tick_count` drops back to 0 the
##    instant a legal step becomes available again, before ever reaching the
##    threshold -- no rescue fires.
## 7. **Once per episode**: after a successful rescue, the villager is not
##    rescued again on a later tick (state-scoped: no longer Traveling/
##    Working once rescued).
## 8. **Search exhaustion**: `unstuck_search_failed` fires exactly once
##    across a whole retry run when no rescue cell is ever found, never once
##    per tick (Edge Case 14 companion, story 015's own emission).
## 9. **QA binding assertion (no double-decide)**: a rescued villager
##    re-enters Deciding through the SAME FIFO-queue + budget path -- no
##    bonus unbudgeted immediate decide, no duplicate queue entry if already
##    queued at rescue time.
## 10. **M01 closure fix (`m01-closure-evidence-20260726.md` Scenario 1)**: a
##    self-sealed builder (own `current_cell` non-standable -- Rule 16's
##    self-seal exception) is rescued even though it left `WORKING` the same
##    tick the self-seal first became true and later sits in `DECIDING`/
##    `WANDERING` -- the fix's own state-independent carve-out for the
##    self-seal sub-condition, proven distinct from AC32's own untouched
##    "standable but walled-in" negative case (#5 above).
class_name UnstuckWatchdogTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles (declared above the test functions, this codebase's own
# GdUnit4 convention -- see job_claim_attribution_test.gd/priority_decision_
# loop_test.gd).
# ---------------------------------------------------------------------------

## Minimal claim-release-only test double -- this story's rescue path calls
## ONLY [method VillagerAi._release_job_claim] -> `job_queue.release_claim`,
## never `get_available_jobs`/`claim_job`/`report_unreachable`, so this
## double implements just that one member (unlike job_claim_attribution_
## test.gd's own fuller `MockJobQueue`, which that story's broader claim/
## travel pipeline needs).
class MockJobQueue:
	var release_claim_call_count: int = 0
	var last_released_villager_id: int = -1

	func release_claim(villager_id: int) -> void:
		release_claim_call_count += 1
		last_released_villager_id = villager_id


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _solid() -> CellContents:
	return CellContents.new(1, 0)


## Places a standable cell at `cell` by adding solid floor directly beneath it
## -- mirrors rescue_target_bfs_test.gd's own established "sparse grid, only
## explicitly-placed cells are ever standable" convention. Deliberately
## sparse: a villager placed on a lone standable cell with NOTHING else
## placed nearby is, by construction, walled in (zero legal step to any
## neighbor) -- exactly Rule 15/F5's own "walled in on an otherwise-fine
## cell" worked example, with no separate wall-placement code needed.
func _make_standable(grid: VoxelWorldGrid, cell: Vector3i) -> void:
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid())


## A bare, wired-but-not-yet-placed [VillagerAi] with a fast, isolated
## watchdog config (`unstuck_watchdog_threshold_ticks = 3`, a large
## `decision_interval` so the unrelated periodic re-check never interferes
## with this file's own scheduler-interaction assertions).
func _make_watchdog_villager(grid: VoxelWorldGrid, villager_id: int = 0) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.config.unstuck_watchdog_threshold_ticks = 3
	villager.config.decision_interval = 1000
	villager.voxel_world = grid
	villager.scheduler = VillagerDecidingScheduler.new()
	villager.villager_id = villager_id
	return villager


func _place_villager(villager: VillagerAi, cell: Vector3i) -> void:
	villager.current_cell = cell
	villager._from_cell = cell
	villager._to_cell = cell


## Drives [param villager] through exactly `unstuck_watchdog_threshold_ticks`
## raw [method VillagerAi._on_tick] calls -- fast enough (threshold = 3, see
## [method _make_watchdog_villager]) to reach the rescue deterministically
## without wiring a real [TimeTickSystem]/[MockTimeTickSystem], mirroring
## priority_decision_loop_test.gd's own direct-`_on_tick()`-call precedent.
func _tick_until_threshold(villager: VillagerAi) -> void:
	for _i in range(villager.config.unstuck_watchdog_threshold_ticks):
		villager._on_tick()


# ---------------------------------------------------------------------------
# AC51 -- stuck (zero legal step), Traveling, past threshold: rescue fires
# ---------------------------------------------------------------------------

func test_traveling_villager_walled_in_past_threshold_teleports_and_fires_telemetry() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)
	var rescue_cell := Vector3i(12, 1, 10)  # Chebyshev distance 2, F5 BFS finds it.
	_make_standable(grid, stuck_cell)
	_make_standable(grid, rescue_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.TRAVELING
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	var jobs := MockJobQueue.new()
	villager.job_queue = jobs
	villager._claimed_blueprint_cell = BlueprintCell.new(Vector3i(99, 1, 99))
	var telemetry := VillagerUnstuckTelemetry.new()
	villager.unstuck_telemetry = telemetry
	var rescued_cells: Array = []
	villager.unstuck_rescued.connect(func(cell: Vector3i) -> void: rescued_cells.append(cell))

	_tick_until_threshold(villager)

	assert_vector(villager.get_current_cell()).is_equal(rescue_cell)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_int(villager.get_stuck_tick_count()).is_equal(0)
	assert_bool(villager.is_distressed()).is_false()
	assert_int(jobs.release_claim_call_count).is_equal(1)
	assert_int(jobs.last_released_villager_id).is_equal(villager.villager_id)
	assert_int(villager.get_unstuck_count()).is_equal(1)
	assert_int(telemetry.get_world_total()).is_equal(1)
	assert_int(telemetry.get_villager_count(villager.villager_id)).is_equal(1)
	assert_array(rescued_cells).contains_exactly([rescue_cell])


# ---------------------------------------------------------------------------
# AC51b -- the OTHER half of the OR: current_cell itself fails standability
# ---------------------------------------------------------------------------

func test_working_villager_on_non_standable_cell_past_threshold_teleports() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)  # deliberately NEVER made standable.
	var rescue_cell := Vector3i(12, 1, 10)
	_make_standable(grid, rescue_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.WORKING
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	# Keeps _tick_working() a no-op (UNDER_CONSTRUCTION branch) for every
	# pre-rescue tick -- a null/BUILT/PLANNED claimed cell would otherwise
	# make _tick_working() itself abandon the job and exit WORKING before
	# the watchdog ever reaches its threshold, which is not what this test
	# is proving.
	villager._claimed_blueprint_cell = BlueprintCell.new(
		Vector3i(99, 1, 99), BlueprintCell.MicroState.UNDER_CONSTRUCTION
	)

	_tick_until_threshold(villager)

	assert_vector(villager.get_current_cell()).is_equal(rescue_cell)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)


# ---------------------------------------------------------------------------
# AC52 -- no held claim (traveling to a bed): zero claim-release side effect
# ---------------------------------------------------------------------------

func test_rescue_with_no_held_claim_has_zero_claim_release_side_effect() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)
	var rescue_cell := Vector3i(12, 1, 10)
	_make_standable(grid, stuck_cell)
	_make_standable(grid, rescue_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.TRAVELING
	villager._pursued_activity = VillagerAi.PursuedActivity.NEED  # e.g. traveling to a bed.
	var jobs := MockJobQueue.new()
	villager.job_queue = jobs

	_tick_until_threshold(villager)

	assert_vector(villager.get_current_cell()).is_equal(rescue_cell)
	assert_int(jobs.release_claim_call_count).is_equal(0)


# ---------------------------------------------------------------------------
# Snap, no lerp -- current_cell and _visual_position both jump atomically
# ---------------------------------------------------------------------------

func test_rescue_snaps_visual_position_to_the_rescue_cell_no_lerp() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)
	var rescue_cell := Vector3i(12, 1, 10)
	_make_standable(grid, stuck_cell)
	_make_standable(grid, rescue_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.TRAVELING

	_tick_until_threshold(villager)

	assert_vector(villager._visual_position).is_equal(VoxelWorldGrid.cell_to_world(rescue_cell))
	assert_float(villager._intra_tick_progress).is_equal(0.0)
	assert_vector(villager._from_cell).is_equal(rescue_cell)
	assert_vector(villager._to_cell).is_equal(rescue_cell)


# ---------------------------------------------------------------------------
# AC32 -- Wandering/Sleeping/Breather with no legal step: distress, no rescue
# ---------------------------------------------------------------------------

func test_non_rescuable_states_with_no_legal_step_stay_put_with_distress_never_teleport() -> void:
	var non_rescuable_states: Array[VillagerAi.State] = [
		VillagerAi.State.WANDERING, VillagerAi.State.SLEEPING, VillagerAi.State.BREATHER,
	]
	for state: VillagerAi.State in non_rescuable_states:
		var grid: VoxelWorldGrid = _make_grid()
		var stuck_cell := Vector3i(10, 1, 10)
		_make_standable(grid, stuck_cell)
		var villager: VillagerAi = _make_watchdog_villager(grid)
		_place_villager(villager, stuck_cell)
		villager._state = state

		# Ticked well past the threshold -- these states must NEVER be rescued
		# regardless of how long the stuck condition persists.
		for _i in range(villager.config.unstuck_watchdog_threshold_ticks * 5):
			villager._on_tick()

		assert_vector(villager.get_current_cell()).is_equal(stuck_cell)
		assert_int(villager.get_state()).is_equal(state)
		assert_bool(villager.is_distressed()).is_true()
		assert_int(villager.get_stuck_tick_count()).is_equal(0)
		assert_int(villager.get_unstuck_count()).is_equal(0)


# ---------------------------------------------------------------------------
# M01 closure fix -- self-seal recovery (BLOCKING regression;
# `production/qa/evidence/m01-closure-evidence-20260726.md` Scenario 1). A
# builder that seals itself into its own just-completed BUILD write (Rule
# 16's self-seal exception, [VillagerSealPreventionGate]'s own class doc
# comment point 1) must still get rescued, even though [method
# VillagerAi._tick_working]'s own completion handling leaves `WORKING` the
# SAME tick the self-seal first becomes true. Before the fix under test,
# [method VillagerAi._update_unstuck_watchdog] reset [member
# VillagerAi.stuck_tick_count] to `0` on every tick once the villager left
# `WORKING`/`TRAVELING` -- so a self-sealed builder could accumulate at most
# ONE stuck tick before leaving those states for good, structurally short of
# `unstuck_watchdog_threshold_ticks`, and stayed permanently distressed in
# `DECIDING`/`WANDERING` forever (the observation run's own reproduced
# `permanent_stuck_count = 15` finding at real population/tick scale).
# ---------------------------------------------------------------------------

func test_self_sealed_builder_recovers_after_completion_transitions_it_out_of_working() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var job_cell := Vector3i(10, 1, 10)  # the villager's OWN job cell -- it stands here.
	var rescue_cell := Vector3i(12, 1, 10)
	_make_standable(grid, job_cell)
	_make_standable(grid, rescue_cell)
	# An open neighbor next to the rescue cell -- without it, the rescue
	# cell itself would be a bare standable island (no legal step anywhere),
	# which would re-trip the OTHER ("walled in but standable") half of the
	# stuck predicate on the very next tick and confuse this test's own
	# distress assertion below with an unrelated, second stuck condition.
	_make_standable(grid, rescue_cell + Vector3i(1, 0, 0))
	# Blocks the cell directly above the job cell from accidentally becoming
	# a closer, unintended standable rescue candidate once `job_cell` itself
	# turns solid below (the self-seal write, further down) -- mirrors a
	# real sealed room's own wall extending more than 1 cell tall.
	grid.set_cell(job_cell + Vector3i(0, 1, 0), _solid())
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, job_cell)
	villager._state = VillagerAi.State.WORKING
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	var jobs := MockJobQueue.new()
	villager.job_queue = jobs
	var claimed_cell := BlueprintCell.new(job_cell, BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	villager._claimed_blueprint_cell = claimed_cell

	# The completion write itself, reproduced exactly as production commits
	# it within a single tick (ConstructionTickLoop connects to the shared
	# tick source BEFORE VillagerAi, so by the time the villager's own
	# _on_tick() runs, this write has already landed): the cell the
	# villager occupies turns solid, and its own claim record flips to
	# BUILT.
	grid.set_cell(job_cell, _solid())
	claimed_cell.state = BlueprintCell.MicroState.BUILT

	# Drive well past the threshold. Before this fix, _tick_working()'s own
	# completion handling left WORKING on tick 1 (the sole tick the
	# watchdog was permitted to count this villager's stuck-ness), after
	# which DECIDING never accumulated another tick and the villager stayed
	# permanently distressed.
	for _i in range(villager.config.unstuck_watchdog_threshold_ticks * 3):
		villager._on_tick()

	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_vector(villager.get_current_cell()).is_equal(rescue_cell)
	assert_bool(villager.is_distressed()).is_false()
	assert_int(villager.get_unstuck_count()).is_equal(1)
	assert_int(villager.get_stuck_tick_count()).is_equal(0)
	assert_int(jobs.release_claim_call_count).is_equal(1)


## Companion case: a villager that has ALREADY fallen through to `WANDERING`
## (Rule 2's normal Deciding fallback, e.g. no other reachable job) while
## self-sealed is rescued too -- proving the fix's scope is genuinely
## state-independent for the self-seal sub-condition, not merely a one-tick
## grace period tied to `WORKING`'s own exit. AC32's own negative case
## (Wandering/Sleeping/Breather with a STANDABLE current cell that is merely
## walled in) stays intact and unchanged, see the test directly above this
## section.
func test_self_sealed_villager_already_in_wandering_is_rescued() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)  # deliberately NEVER made standable -- self-sealed.
	var rescue_cell := Vector3i(12, 1, 10)
	_make_standable(grid, rescue_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.WANDERING

	_tick_until_threshold(villager)

	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_vector(villager.get_current_cell()).is_equal(rescue_cell)
	assert_bool(villager.is_distressed()).is_false()
	assert_int(villager.get_unstuck_count()).is_equal(1)


# ---------------------------------------------------------------------------
# Relief resets the counter before ever reaching the threshold -- no rescue
# ---------------------------------------------------------------------------

func test_stuck_tick_count_resets_to_zero_on_relief_before_threshold_no_rescue() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)
	_make_standable(grid, stuck_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.TRAVELING

	# Two stuck ticks -- below the threshold (3).
	villager._on_tick()
	villager._on_tick()
	assert_int(villager.get_stuck_tick_count()).is_equal(2)

	# Relief: a neighbor becomes standable and step-legal before the
	# threshold is ever reached.
	_make_standable(grid, Vector3i(11, 1, 10))

	villager._on_tick()

	assert_int(villager.get_stuck_tick_count()).is_equal(0)
	assert_bool(villager.is_distressed()).is_false()
	assert_vector(villager.get_current_cell()).is_equal(stuck_cell)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	assert_int(villager.get_unstuck_count()).is_equal(0)


# ---------------------------------------------------------------------------
# Once per stuck episode -- no second rescue on a later tick
# ---------------------------------------------------------------------------

func test_villager_is_rescued_only_once_per_stuck_episode() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)
	var rescue_cell := Vector3i(12, 1, 10)
	_make_standable(grid, stuck_cell)
	_make_standable(grid, rescue_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.TRAVELING

	_tick_until_threshold(villager)
	assert_int(villager.get_unstuck_count()).is_equal(1)

	# Continue ticking well past the rescue -- the villager is no longer
	# Traveling/Working (rescue transitioned it to Deciding), so it can never
	# accumulate a second episode or be rescued again within this same test.
	for _i in range(villager.config.unstuck_watchdog_threshold_ticks * 5):
		villager._on_tick()

	assert_int(villager.get_unstuck_count()).is_equal(1)
	assert_vector(villager.get_current_cell()).is_equal(rescue_cell)


# ---------------------------------------------------------------------------
# Search exhaustion -- unstuck_search_failed fires exactly once per episode
# ---------------------------------------------------------------------------

func test_search_exhaustion_fires_unstuck_search_failed_exactly_once_per_episode() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)
	_make_standable(grid, stuck_cell)  # standable, but nothing else anywhere.
	var villager: VillagerAi = _make_watchdog_villager(grid)
	villager.config.unstuck_rescue_search_radius = 3
	villager.config.unstuck_rescue_max_radius = 3  # exhausts immediately.
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.TRAVELING
	var failure_events: Array = []
	villager.unstuck_search_failed.connect(func() -> void: failure_events.append(true))

	# Threshold ticks to first fire the (failing) rescue attempt, then several
	# more retries -- Edge Case 14: "the search retries every tick until a
	# cell is found" -- while the villager remains stuck and un-rescued.
	for _i in range(villager.config.unstuck_watchdog_threshold_ticks + 5):
		villager._on_tick()

	assert_int(failure_events.size()).is_equal(1)
	assert_int(villager.get_unstuck_count()).is_equal(0)
	assert_vector(villager.get_current_cell()).is_equal(stuck_cell)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)


# ---------------------------------------------------------------------------
# QA binding assertion -- no double-decide: normal budget slot, no bonus
# ---------------------------------------------------------------------------

func test_rescued_villager_reenters_deciding_via_normal_budget_never_a_bonus_slot() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)
	var rescue_cell := Vector3i(12, 1, 10)
	_make_standable(grid, stuck_cell)
	_make_standable(grid, rescue_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.TRAVELING

	_tick_until_threshold(villager)

	# Re-entered the FIFO queue via the normal request_deciding_pass() path --
	# but the CURRENT tick's budget window was already computed before this
	# rescue happened (production's own scheduler-connects-before-villager
	# ordering, see VillagerAi's own class-doc "no double-decide" paragraph),
	# so it is NOT runnable this same tick -- no unbudgeted bonus decide.
	assert_bool(villager.scheduler.is_queued(villager.villager_id)).is_true()
	assert_bool(villager.scheduler.is_runnable_this_tick(villager.villager_id)).is_false()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.DECIDING)

	# A LATER tick's budget drain dequeues it exactly like any other queued
	# villager -- one ordinary budget slot, the same mechanism every other
	# Deciding-eligibility trigger uses.
	villager.scheduler.advance_tick(1)
	assert_bool(villager.scheduler.is_runnable_this_tick(villager.villager_id)).is_true()
	assert_bool(villager.scheduler.is_queued(villager.villager_id)).is_false()


func test_rescue_does_not_double_enqueue_a_villager_already_queued_at_rescue_time() -> void:
	var grid: VoxelWorldGrid = _make_grid()
	var stuck_cell := Vector3i(10, 1, 10)
	var rescue_cell := Vector3i(12, 1, 10)
	_make_standable(grid, stuck_cell)
	_make_standable(grid, rescue_cell)
	var villager: VillagerAi = _make_watchdog_villager(grid)
	_place_villager(villager, stuck_cell)
	villager._state = VillagerAi.State.TRAVELING
	# Already queued -- e.g. from an earlier decision_interval trigger, still
	# awaiting a future advance_tick() dequeue when the watchdog fires.
	villager.scheduler.enqueue(villager.villager_id)
	assert_int(villager.scheduler.queue_length()).is_equal(1)

	_tick_until_threshold(villager)

	# Still exactly one entry -- the rescue's own request_deciding_pass()
	# call found the villager already queued and was a no-op, never a
	# second, duplicate FIFO entry for the same villager.
	assert_int(villager.scheduler.queue_length()).is_equal(1)
	assert_bool(villager.scheduler.is_queued(villager.villager_id)).is_true()
