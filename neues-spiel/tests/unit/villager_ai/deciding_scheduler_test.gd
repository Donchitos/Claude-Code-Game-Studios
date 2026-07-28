## Unit test — Villager AI story 005 (Deciding scheduler: FIFO queue +
## `max_deciding_per_tick` budget, ADR-0008 Decision §2).
##
## Proves, against [VillagerDecidingScheduler] directly (ADR-0008's own
## Validation Criteria: "A unit test enqueues more villagers than
## `max_deciding_per_tick` in a single tick and asserts only the budgeted
## count runs a Deciding pass that tick, the rest remain queued in stable
## order, and are processed on subsequent ticks"):
## 1. **Budget caps new passes per tick** — enqueuing more villagers than the
##    budget leaves only the budgeted count runnable; the rest stay queued.
## 2. **Stable FIFO order** — dequeue order matches ENQUEUE order (villager
##    index / GDD Edge Case 3 convention), never sorted by id value.
## 3. **Idempotent enqueue** — a villager already queued is never appended a
##    second time, and never bumped to the back of the FIFO by a redundant
##    trigger (this story's own `decision_interval` re-check, e.g., could
##    otherwise fire every tick while still queued).
## 4. **No mid-pass interruption** — `advance_tick` only ever touches ids
##    still sitting in the pending queue; it structurally cannot reach an id
##    that has already been dequeued (this class's whole reason for
##    existing, per its own class doc comment).
## 5. **Tick-burst framing (AC36)** — repeated `advance_tick` calls (each
##    standing in for one processed tick) drain at most `budget` per call,
##    never more, in FIFO order, across a burst of several calls.
## 6. **End-to-end wiring through real [VillagerAi] instances** sharing one
##    [VillagerDecidingScheduler] — proves the population-wide staggering
##    ADR-0008 requires actually happens through the real `setup()`/
##    `_on_tick()` seam, not just the isolated scheduler class, and that
##    [VillagerAi._tick_deciding] is invoked exactly when (and only when) the
##    scheduler marks that villager runnable — never more than once per
##    runnable tick (AC5: "Deciding is instantaneous within a tick").
## 7. **Sprint 8 re-tune determinism (Story villager-ai-022, quick-spec
##    AC5)** — the synchronized-mass-Deciding scenario (30 villagers,
##    `max_deciding_per_tick=5`) run twice from independent populations
##    produces an IDENTICAL per-tick dequeue-order sequence both times, and
##    the drain completes in exactly `ceil(30/5) = 6` ticks (quick-spec
##    F-retune-1's worst-case bound).
class_name DecidingSchedulerTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test doubles (declared above the test functions per this codebase's own
# GdUnit4 convention for inner helper classes)
# ---------------------------------------------------------------------------

## Spy subclass overriding the (still-stub, story 006's scope) Deciding pass
## body so a test can observe exactly how many times it was actually
## invoked, rather than only inferring correctness from the scheduler's own
## bookkeeping. Never used for anything beyond this counter.
class SpyVillagerAi:
	extends VillagerAi

	var deciding_pass_count: int = 0

	func _tick_deciding() -> void:
		deciding_pass_count += 1


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

func _make_scheduler() -> VillagerDecidingScheduler:
	return VillagerDecidingScheduler.new()


## A villager whose periodic `decision_interval` re-check is pushed far
## outside any test's short tick window, isolating the SPECIFIC eligibility
## trigger a given test exercises (usually the initial at-`setup()`
## enqueue) from the independent, always-on periodic re-check this story
## also owns.
func _make_villager(
	villager_id: int, scheduler: VillagerDecidingScheduler, mock_tick: MockTimeTickSystem
) -> VillagerAi:
	var villager: VillagerAi = auto_free(SpyVillagerAi.new())
	villager.villager_id = villager_id
	villager.config = VillagerAIConfig.new()
	villager.config.decision_interval = 1000
	villager.voxel_world = auto_free(VoxelWorldGrid.new())
	villager.scheduler = scheduler
	villager.time_tick_system = mock_tick
	return villager


# ---------------------------------------------------------------------------
# 1. Budget caps new passes started per tick (ADR-0008 Validation Criteria)
# ---------------------------------------------------------------------------

func test_advance_tick_with_budget_one_dequeues_only_the_first_enqueued() -> void:
	# Arrange — three villagers become eligible before any tick is processed
	# (a mass-Deciding event), budget is the spike-tuned default of 1.
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	scheduler.enqueue(5)
	scheduler.enqueue(2)
	scheduler.enqueue(8)

	# Act
	scheduler.advance_tick(1)

	# Assert — only the budgeted count (1) is runnable this tick; the rest
	# remain queued, in their original stable order.
	assert_bool(scheduler.is_runnable_this_tick(5)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(2)).is_false()
	assert_bool(scheduler.is_runnable_this_tick(8)).is_false()
	assert_int(scheduler.queue_length()).is_equal(2)
	assert_bool(scheduler.is_queued(2)).is_true()
	assert_bool(scheduler.is_queued(8)).is_true()


func test_advance_tick_with_budget_greater_than_one_dequeues_up_to_budget() -> void:
	# Arrange
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	scheduler.enqueue(1)
	scheduler.enqueue(2)
	scheduler.enqueue(3)
	scheduler.enqueue(4)

	# Act
	scheduler.advance_tick(3)

	# Assert
	assert_bool(scheduler.is_runnable_this_tick(1)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(2)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(3)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(4)).is_false()
	assert_int(scheduler.queue_length()).is_equal(1)


func test_queued_villagers_are_processed_fifo_on_subsequent_ticks() -> void:
	# Arrange — budget = 1 (spike default): 3 enqueued, drained one per tick.
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	scheduler.enqueue(10)
	scheduler.enqueue(20)
	scheduler.enqueue(30)

	# Act + Assert — tick 1
	scheduler.advance_tick(1)
	assert_bool(scheduler.is_runnable_this_tick(10)).is_true()
	assert_int(scheduler.queue_length()).is_equal(2)

	# Act + Assert — tick 2
	scheduler.advance_tick(1)
	assert_bool(scheduler.is_runnable_this_tick(20)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(10)).is_false()
	assert_int(scheduler.queue_length()).is_equal(1)

	# Act + Assert — tick 3
	scheduler.advance_tick(1)
	assert_bool(scheduler.is_runnable_this_tick(30)).is_true()
	assert_int(scheduler.queue_length()).is_equal(0)


# ---------------------------------------------------------------------------
# 2. Stable FIFO order — enqueue order, never sorted by id value
# ---------------------------------------------------------------------------

func test_dequeue_order_matches_enqueue_order_not_id_value() -> void:
	# Arrange — enqueued out of numeric order; FIFO must still win.
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	scheduler.enqueue(7)
	scheduler.enqueue(1)
	scheduler.enqueue(4)

	# Act + Assert — one at a time, in the ORIGINAL enqueue order (7, 1, 4),
	# never ascending/descending numeric order.
	scheduler.advance_tick(1)
	assert_bool(scheduler.is_runnable_this_tick(7)).is_true()

	scheduler.advance_tick(1)
	assert_bool(scheduler.is_runnable_this_tick(1)).is_true()

	scheduler.advance_tick(1)
	assert_bool(scheduler.is_runnable_this_tick(4)).is_true()


# ---------------------------------------------------------------------------
# 3. Idempotent enqueue — no duplicate entries, no FIFO-order corruption
# ---------------------------------------------------------------------------

func test_enqueue_already_queued_villager_does_not_duplicate_or_reorder() -> void:
	# Arrange — A enqueued, then B, then A is enqueued AGAIN (simulating a
	# redundant eligibility trigger firing while A is still waiting).
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	scheduler.enqueue(100)
	scheduler.enqueue(200)
	scheduler.enqueue(100)

	# Assert — the redundant enqueue did not add a second entry.
	assert_int(scheduler.queue_length()).is_equal(2)

	# Act + Assert — A (100) is still FIRST, not bumped behind B by the
	# redundant call.
	scheduler.advance_tick(1)
	assert_bool(scheduler.is_runnable_this_tick(100)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(200)).is_false()


func test_is_queued_reflects_pending_membership() -> void:
	# Arrange
	var scheduler: VillagerDecidingScheduler = _make_scheduler()

	# Assert — never enqueued
	assert_bool(scheduler.is_queued(1)).is_false()

	# Act
	scheduler.enqueue(1)

	# Assert — queued, not yet dequeued
	assert_bool(scheduler.is_queued(1)).is_true()

	# Act
	scheduler.advance_tick(1)

	# Assert — dequeued villagers no longer sit in the pending queue.
	assert_bool(scheduler.is_queued(1)).is_false()


# ---------------------------------------------------------------------------
# 4. No mid-pass interruption — advance_tick only ever affects queued ids
# ---------------------------------------------------------------------------

func test_advance_tick_never_marks_an_unqueued_id_runnable() -> void:
	# Arrange — id 1 is queued and gets dequeued THIS tick; id 2 was never
	# enqueued at all.
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	scheduler.enqueue(1)

	# Act
	scheduler.advance_tick(5)

	# Assert — a budget far larger than the queue never fabricates a
	# runnable id out of nothing.
	assert_bool(scheduler.is_runnable_this_tick(1)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(2)).is_false()


func test_advance_tick_runnable_window_is_exactly_one_tick_never_carried_over() -> void:
	# Arrange — id 1 is dequeued (runnable) on tick 1, per this story's own
	# AC ("the budget caps how many NEW passes START per tick, never
	# interrupts an in-progress pass") — a LATER tick's budget check must
	# never retroactively touch a pass that already started and (being
	# synchronous, single-threaded GDScript) already finished; this class
	# structurally cannot do so, since the id is no longer in its queue.
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	scheduler.enqueue(1)
	scheduler.advance_tick(1)
	assert_bool(scheduler.is_runnable_this_tick(1)).is_true()

	# Act — a second, later tick's budget check, nothing new enqueued.
	scheduler.advance_tick(1)

	# Assert — id 1's one-tick runnable window has closed; it is not
	# "re-interrupted" or resurrected by this call, and the empty queue
	# produces no runnable ids at all.
	assert_bool(scheduler.is_runnable_this_tick(1)).is_false()
	assert_bool(scheduler.is_queued(1)).is_false()


func test_advance_tick_on_empty_queue_marks_nothing_runnable() -> void:
	# Arrange
	var scheduler: VillagerDecidingScheduler = _make_scheduler()

	# Act — no crash on an empty queue.
	scheduler.advance_tick(1)

	# Assert
	assert_int(scheduler.queue_length()).is_equal(0)
	assert_bool(scheduler.is_runnable_this_tick(0)).is_false()


# ---------------------------------------------------------------------------
# 5. Tick-burst framing (AC36) — at most budget drained per processed tick,
# never more, across a burst of several advance_tick calls
# ---------------------------------------------------------------------------

func test_tick_burst_drains_exactly_budget_per_call_never_more() -> void:
	# Arrange — 4 villagers eligible, budget = 2, simulating a
	# `max_ticks_per_frame`-style burst of two processed ticks in one frame.
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	scheduler.enqueue(1)
	scheduler.enqueue(2)
	scheduler.enqueue(3)
	scheduler.enqueue(4)

	# Act — processed tick 1 of the burst.
	scheduler.advance_tick(2)
	# Assert — exactly 2 runnable, in order, never all 4 at once.
	assert_bool(scheduler.is_runnable_this_tick(1)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(2)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(3)).is_false()
	assert_bool(scheduler.is_runnable_this_tick(4)).is_false()

	# Act — processed tick 2 of the burst.
	scheduler.advance_tick(2)
	# Assert — the remaining 2 drain now, tick 1's pair no longer runnable.
	assert_bool(scheduler.is_runnable_this_tick(3)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(4)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(1)).is_false()
	assert_int(scheduler.queue_length()).is_equal(0)


# ---------------------------------------------------------------------------
# 6. End-to-end through real VillagerAi instances sharing one scheduler
# ---------------------------------------------------------------------------

func test_population_sharing_one_scheduler_staggers_across_ticks_in_stable_order() -> void:
	# Arrange — 3 villagers (ids 0, 1, 2, the stable creation order), one
	# shared scheduler, one shared config with the spike default
	# max_deciding_per_tick = 1, one shared mock tick source. Each villager's
	# own setup() call enqueues it (initial Deciding-eligible-at-boot,
	# story's own trigger) in that same stable order.
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var villager_0: VillagerAi = _make_villager(0, scheduler, mock_tick)
	var villager_1: VillagerAi = _make_villager(1, scheduler, mock_tick)
	var villager_2: VillagerAi = _make_villager(2, scheduler, mock_tick)
	villager_0.config.max_deciding_per_tick = 1
	villager_1.config = villager_0.config
	villager_2.config = villager_0.config

	villager_0.setup()
	villager_1.setup()
	villager_2.setup()

	# Assert — all three queued, none dequeued yet (no tick has fired).
	assert_int(scheduler.queue_length()).is_equal(3)

	# Act — tick 1.
	mock_tick.fire_tick()
	# Assert — only villager 0 (earliest stable order) is runnable.
	assert_bool(scheduler.is_runnable_this_tick(0)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(1)).is_false()
	assert_bool(scheduler.is_runnable_this_tick(2)).is_false()
	assert_int(scheduler.queue_length()).is_equal(2)

	# Act — tick 2.
	mock_tick.fire_tick()
	# Assert — villager 1 next, FIFO within the stable order.
	assert_bool(scheduler.is_runnable_this_tick(1)).is_true()
	assert_bool(scheduler.is_runnable_this_tick(0)).is_false()
	assert_bool(scheduler.is_runnable_this_tick(2)).is_false()
	assert_int(scheduler.queue_length()).is_equal(1)

	# Act — tick 3.
	mock_tick.fire_tick()
	# Assert — villager 2 last.
	assert_bool(scheduler.is_runnable_this_tick(2)).is_true()
	assert_int(scheduler.queue_length()).is_equal(0)


func test_tick_deciding_pass_runs_exactly_once_when_runnable_never_when_not() -> void:
	# Arrange — a single spy villager; budget = 1 (default), decision
	# interval pushed far out so only the initial setup()-time enqueue is in
	# play (this test's own single trigger, isolated).
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var spy: SpyVillagerAi = _make_villager(0, scheduler, mock_tick) as SpyVillagerAi
	spy.setup()
	assert_int(spy.deciding_pass_count).is_equal(0)

	# Act — tick 1: the scheduler dequeues id 0 (enqueued by setup()) this
	# same tick, so the DECIDING branch's gate lets the real (spy) pass body
	# run.
	mock_tick.fire_tick()

	# Assert — the pass body ran exactly once (AC5: instantaneous within the
	# tick it runs, never partial, never repeated).
	assert_int(spy.deciding_pass_count).is_equal(1)

	# Act — tick 2: nothing re-enqueued (decision_interval is pushed far
	# beyond this test's tick count), queue is empty, so the villager is NOT
	# runnable this tick.
	mock_tick.fire_tick()

	# Assert — the pass body is NOT invoked again — a villager sitting in
	# DECIDING but not currently dequeued does nothing this tick.
	assert_int(spy.deciding_pass_count).is_equal(1)


func test_request_deciding_pass_is_the_generic_reusable_enqueue_entry_point() -> void:
	# Arrange — a villager whose initial setup()-time enqueue has already
	# been drained (simulating "already ran its first pass, now idle in
	# DECIDING with nothing queued").
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var villager: VillagerAi = _make_villager(0, scheduler, mock_tick)
	villager.setup()
	mock_tick.fire_tick()
	assert_bool(scheduler.is_queued(0)).is_false()

	# Act — a future story's own trigger (need-urgent, job-complete) calling
	# this SAME public method, independent of the periodic decision_interval
	# check this story also owns.
	villager.request_deciding_pass()

	# Assert — the villager is queued again via the one shared entry point.
	assert_bool(scheduler.is_queued(0)).is_true()


# ---------------------------------------------------------------------------
# Sprint 8 coordinated re-tune (Story villager-ai-022, quick-spec AC5,
# ADR-0009) — determinism at the new max_deciding_per_tick=5 budget: the
# same synchronized-mass-Deciding scenario (all N villagers force-re-enqueued
# in the same tick, GDD Rule 10c) run TWICE, from two structurally identical
# but fully independent populations/schedulers, must dequeue in IDENTICAL
# order both times. This is not a new mechanism -- [VillagerDecidingScheduler]
# uses a plain `Array`/`Dictionary` FIFO with no randomness anywhere, so this
# is a regression guard (a future change introducing e.g. hash-order
# iteration would be caught here), not a change to the scheduler itself.
# `decision_interval` is pushed far outside this test's short tick window
# (this file's own isolation convention, see `_make_villager`) so only the
# one-off mass-event trigger is exercised, matching the quick-spec's own
# framing of F-retune-1 as independent of `decision_interval`.
# ---------------------------------------------------------------------------

## Runs the full 30-villager synchronized-mass-Deciding scenario at
## `max_deciding_per_tick=5` against a FRESH scheduler/population and returns
## the per-tick sequence of runnable villager ids (one inner Array per tick,
## in stable-order-within-tick form) across the whole drain -- the exact
## shape two independent runs must match identically.
func _run_synchronized_mass_deciding_and_record_dequeue_order(budget: int, population: int) -> Array:
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var villagers: Array[VillagerAi] = []
	for villager_id in range(population):
		var villager: VillagerAi = _make_villager(villager_id, scheduler, mock_tick)
		villager.config = VillagerAIConfig.new()
		villager.config.max_deciding_per_tick = budget
		villager.setup()
		# Set AFTER setup() -- setup()'s own config.validate() call clamps
		# decision_interval to its GDD safe range (max 10), so a "push far
		# outside this test's tick window" isolation value must be assigned
		# only once validate() has already run (matches this file's own
		# _make_full_villager precedent in stress_30_villager_test.gd).
		villager.config.decision_interval = 1000
		villagers.append(villager)

	# Drain the initial at-setup() enqueue first, so the recorded sequence
	# below reflects ONLY the synthetic mass-event spike, not boot ordering.
	while scheduler.queue_length() > 0:
		mock_tick.fire_tick()

	# The synthetic mass event: every villager force-re-enqueued in the SAME
	# tick (GDD Rule 10c's own worked scenario).
	for villager: VillagerAi in villagers:
		villager.request_deciding_pass()

	var dequeue_order_per_tick: Array = []
	while scheduler.queue_length() > 0:
		mock_tick.fire_tick()
		var runnable_this_tick: Array[int] = []
		for villager: VillagerAi in villagers:
			if scheduler.is_runnable_this_tick(villager.get_villager_id()):
				runnable_this_tick.append(villager.get_villager_id())
		dequeue_order_per_tick.append(runnable_this_tick)
	return dequeue_order_per_tick


func test_synchronized_mass_deciding_scenario_run_twice_at_k5_produces_identical_dequeue_order() -> void:
	var first_run: Array = _run_synchronized_mass_deciding_and_record_dequeue_order(5, 30)
	var second_run: Array = _run_synchronized_mass_deciding_and_record_dequeue_order(5, 30)

	assert_int(first_run.size()).is_equal(second_run.size())
	for tick_index in range(first_run.size()):
		var first_tick_ids: Array = first_run[tick_index]
		var second_tick_ids: Array = second_run[tick_index]
		assert_array(first_tick_ids).override_failure_message(
			"tick %d: dequeue order diverged between runs -- first=%s second=%s" %
			[tick_index, first_tick_ids, second_tick_ids]
		).is_equal(second_tick_ids)

	# Worst-case ticks-to-decide bound (quick-spec F-retune-1): ceil(30/5) = 6.
	assert_int(first_run.size()).is_equal(6)


func test_check_decision_interval_trigger_re_enqueues_on_cadence() -> void:
	# Arrange — a short decision_interval so the periodic re-check trigger
	# (this story's own concrete eligibility trigger, GDD Rule 2) fires
	# within a small, easily-asserted tick count.
	var scheduler: VillagerDecidingScheduler = _make_scheduler()
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.villager_id = 0
	villager.config = VillagerAIConfig.new()
	villager.config.decision_interval = 2
	villager.config.max_deciding_per_tick = 1
	villager.voxel_world = auto_free(VoxelWorldGrid.new())
	villager.scheduler = scheduler
	villager.time_tick_system = mock_tick
	villager.setup()

	# Act — tick 1 drains the initial setup()-time enqueue; the periodic
	# counter is now at 1, not yet at decision_interval (2).
	mock_tick.fire_tick()
	assert_bool(scheduler.is_queued(0)).is_false()

	# Act — tick 2: the periodic counter reaches decision_interval (2) and
	# re-enqueues, but that re-enqueue happens AFTER this tick's own dequeue
	# already ran (this story's documented one-tick latency), so it is
	# queued, not yet runnable, at the end of tick 2.
	mock_tick.fire_tick()

	# Assert — the periodic trigger fired: the villager is queued again
	# without anything external calling request_deciding_pass() itself.
	assert_bool(scheduler.is_queued(0)).is_true()
