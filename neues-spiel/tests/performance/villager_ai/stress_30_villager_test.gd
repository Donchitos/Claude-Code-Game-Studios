## Performance/stress harness — Story villager-ai-025 (30-villager perf stress
## validation), Sprint 7 (Nice, self-declared Advisory/Performance — see the
## story's own header + `production/qa/qa-plan-sprint-7-2026-07-24.md`
## Call-out 1). ADR-0008 primary (Deciding-pass staggering,
## `max_deciding_per_tick` budget), ADR-0007 secondary (AStar3D at scale).
##
## **Advisory, not a Done/smoke blocker** (Sprint 7 QA plan, Call-out 1 /
## Automated Tests Required / Definition of Done): `tests/run-tests.cmd` only
## globs `res://tests/unit` and `res://tests/integration` — this file lives
## under `res://tests/performance` deliberately, so it never joins the
## BLOCKING regression gate. It still must be REAL and reproducible headless
## (no synthetic/plausible-looking numbers) — every assertion below is
## structural/deterministic (queue lengths, completion counts, a generous
## non-flaky sanity ceiling), never a strict wall-clock pass/fail gate; the
## actual timing numbers are `print()`-ed for a human to transcribe into
## `production/qa/evidence/villager-ai-stress-evidence.md` (this class of
## story is measured, then reported, not gated — same posture as
## `prototypes/perf-spike-qq3/REPORT.md`).
##
## **Measurement methodology (documented proxy — no live renderer in headless
## GdUnit4)**: one measured "sample" = one rendered-frame equivalent:
## (a) once per sample, mimic the engine's own `VillagerAi._process()` call
## for every villager still travelling (`is_moving()` guard, matching
## `_process()`'s own real guard) via [method VillagerAi.advance_travel_progress]
## with a saturating `game_delta` (1000.0 -- an arbitrarily large value that
## only affects HOW MANY samples a real multi-cell path needs to complete,
## never the per-call CPU cost being measured, which is O(1) math
## independent of the delta's magnitude); (b) any injected "background
## construction elsewhere" write-storm for this sample; (c) `ticks_per_sample`
## consecutive `tick.emit()` calls via [MockTimeTickSystem] -- 1 for "1x", 3
## for "3x warp" (modeling "N global ticks can land within the same rendered
## frame under warp," matching `prototypes/perf-spike-qq3/REPORT.md`'s own S2
## warp1-vs-warp3 methodology). The whole (a)+(b)+(c) group is timed as ONE
## sample via `Time.get_ticks_usec()`.
##
## **Honest scope caveat**: the GDD's own pre-VS spike wishlist
## (villager-ai-behavior.md OQ3) also names Breather step-away and bed-drift
## pathing as stress axes. Neither exists as real behavior in this codebase
## yet -- [VillagerAi._tick_breather]/[VillagerAi._tick_wandering] are still
## empty stubs (later stories' scope; Needs & Mood and the Unstuck Watchdog
## are undesigned/unlanded too) -- so this harness cannot honestly exercise
## them against production code. Per this codebase's own crown-test precedent
## ("an honestly-red crown is better than a falsely-green one," Sprint 7 QA
## plan / `build_job_cycle_test.gd`'s own doc comment): this file measures
## exactly what IS real and landed today -- Deciding-pass staggering (005),
## F2 selection under an unreachable-job-dense queue (010), the real
## claim->travel->build->report cycle at population scale (011/012), and
## Voxel-World write-storm cost against the re-path filter (008/009) -- and
## says so explicitly here rather than silently padding coverage.
class_name Stress30VillagerTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Shared fixtures (helpers ABOVE every test function, this codebase's
# convention)
# ---------------------------------------------------------------------------

## One test's full real-component environment -- mirrors
## `build_job_cycle_test.gd`'s own `_Environment` shape exactly.
class _Environment:
	var grid: VoxelWorldGrid
	var loop: ConstructionTickLoop
	var queue: ConstructionJobQueue
	var gate: VillagerOnSiteGate


func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


## Fills a flat, fully-connected platform at y=0 (`x`/`z` in
## `[0, size)`) -- villagers/job targets occupy y=1, mirroring
## `build_job_cycle_test.gd`'s own established fixture.
func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))


## Places [param count] mutually-isolated 1x1 standable platforms (GDD F2's
## "unreachable-job-dense" stress axis) starting at `x = island_start_x`,
## spaced [constant _ISLAND_SPACING] cells apart in both axes -- far enough
## that [VillagerNavGraph.build]'s own immediate-neighbor connection pass
## (`HORIZONTAL_HALF_OFFSETS`) can never bridge one island to another, or to
## the main platform. Returns the y=1 target cell above each island (the
## walkable layer a job target occupies, matching `build_job_cycle_test.gd`'s
## own "target sits at the walkable layer" convention).
const _ISLAND_SPACING: int = 3
const _ISLANDS_PER_ROW: int = 8


func _build_isolated_islands(grid: VoxelWorldGrid, count: int, island_start_x: int) -> Array[Vector3i]:
	var targets: Array[Vector3i] = []
	for i in range(count):
		var row: int = i / _ISLANDS_PER_ROW
		var col: int = i % _ISLANDS_PER_ROW
		var x: int = island_start_x + col * _ISLAND_SPACING
		var z: int = row * _ISLAND_SPACING
		grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))
		targets.append(Vector3i(x, 1, z))
	return targets


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


## A released (BUILDING, job-eligible) project over [param cells] -- mirrors
## `build_job_cycle_test.gd`'s own `_released_project` helper.
func _released_project(id: int, cells: Array[Vector3i]) -> BuildProject:
	var project := BuildProject.new(id)
	for cell: Vector3i in cells:
		project.add_cell(_planned_cell(cell))
	project.release()
	return project


## Builds the real Building-System-side environment, wired in the
## load-bearing order (`ConstructionTickLoop` connects to the tick source
## BEFORE any villager) `build_job_cycle_test.gd`'s own doc comment
## establishes.
func _make_environment(tick_source: Object, platform_size: int) -> _Environment:
	var env := _Environment.new()
	env.grid = _new_grid()
	_fill_flat_platform(env.grid, platform_size)
	env.loop = auto_free(ConstructionTickLoop.new())
	env.loop.voxel_world = env.grid
	env.loop.config = ConstructionTickLoopConfig.new()
	env.loop.time_tick_system = tick_source
	env.loop.setup()
	env.queue = ConstructionJobQueue.new(env.loop)
	env.gate = VillagerOnSiteGate.new(env.queue)
	return env


## A fully wired, real [VillagerAi] -- connected to [param tick_source] AFTER
## [param env]'s own [ConstructionTickLoop] -- mirrors
## `build_job_cycle_test.gd`'s own `_make_full_villager` helper.
func _make_full_villager(
	env: _Environment,
	nav_graph: VillagerNavGraph,
	scheduler: VillagerDecidingScheduler,
	tick_source: Object,
	villager_id: int,
	spawn_cell: Vector3i,
) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.voxel_world = env.grid
	villager.scheduler = scheduler
	villager.nav_graph = nav_graph
	villager.time_tick_system = tick_source
	villager.job_queue = env.queue
	villager.villager_id = villager_id
	villager.current_cell = spawn_cell
	villager._from_cell = spawn_cell
	villager._to_cell = spawn_cell
	villager.setup()
	env.gate.register_villager(villager)
	return villager


## Spawn cells for [param count] villagers along `z in [0, 3)` of the
## platform -- distinct from the job-target rows below, purely for tidy,
## non-overlapping placement (overlap would not break anything -- occupancy
## exclusivity/nudge-aside is a later, unlanded story -- this is just clean
## fixture layout).
func _spawn_cells(count: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var per_row: int = 15
	for i in range(count):
		cells.append(Vector3i(i % per_row, 1, i / per_row))
	return cells


## Reachable job-target cells (the walkable y=1 layer, matching
## `build_job_cycle_test.gd`'s own convention) along `z in [4, platform_size)`
## of the SAME connected platform -- deliberately non-overlapping with
## [method _spawn_cells]'s own rows.
func _reachable_job_targets(count: int, platform_size: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var per_row: int = platform_size
	var start_z: int = 4
	for i in range(count):
		var z: int = start_z + i / per_row
		var x: int = i % per_row
		cells.append(Vector3i(x, 1, z))
	return cells


## Builds a shared [VillagerNavGraph] over a region large enough to cover both
## the main platform and (if [param include_islands]) the isolated-island
## strip -- one predicate-source villager, never one of the population's own
## (mirrors `build_job_cycle_test.gd`'s own `predicate_source` convention).
func _build_nav_graph(grid: VoxelWorldGrid, region_center: Vector3i, region_size: int) -> VillagerNavGraph:
	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	predicate_source.villager_id = -1
	var nav_graph := VillagerNavGraph.new()
	nav_graph.subscribe_to_voxel_world(grid, predicate_source)
	nav_graph.build(grid, predicate_source, region_center, region_size)
	return nav_graph


## Timing helper -- see this file's own class doc comment for the full
## "one sample = one rendered-frame equivalent" methodology. [param
## per_sample_extra] (optional) runs INSIDE the timed window once per sample,
## after the travel-progress pump and before the tick(s) -- the write-storm
## injection point for the construction-write-storm scenarios.
func _measure_samples_ms(
	tick_source: MockTimeTickSystem,
	villagers: Array[VillagerAi],
	sample_count: int,
	ticks_per_sample: int,
	per_sample_extra: Callable = Callable(),
) -> Array[float]:
	var costs: Array[float] = []
	for s in range(sample_count):
		var start_usec: int = Time.get_ticks_usec()
		for villager: VillagerAi in villagers:
			if villager.is_moving():
				villager.advance_travel_progress(1000.0)
		if per_sample_extra.is_valid():
			per_sample_extra.call(s)
		for _t in range(ticks_per_sample):
			tick_source.fire_tick()
		var elapsed_usec: int = Time.get_ticks_usec() - start_usec
		costs.append(elapsed_usec / 1000.0)
	return costs


## avg/p95/max over a cost array, plus its own size -- the "recorded
## envelope" this story's AC39 asks for.
func _stats(costs: Array[float]) -> Dictionary:
	var sorted_costs: Array[float] = costs.duplicate()
	sorted_costs.sort()
	var n: int = sorted_costs.size()
	var total: float = 0.0
	for c: float in sorted_costs:
		total += c
	var p95_index: int = clampi(int(ceil(0.95 * n)) - 1, 0, n - 1)
	return {
		"avg": total / n,
		"p95": sorted_costs[p95_index],
		"max": sorted_costs[n - 1],
		"n": n,
	}


## Prints one labeled envelope line -- transcribed by hand into
## `production/qa/evidence/villager-ai-stress-evidence.md` (this test file
## intentionally does not write that doc itself -- a human-reviewed report,
## not a silently-generated one, per this codebase's own reporting
## discipline).
func _report(label: String, stats: Dictionary) -> void:
	print(
		"[villager-ai-025] %s -- avg=%.3fms p95=%.3fms max=%.3fms n=%d" %
		[label, stats.avg, stats.p95, stats.max, stats.n]
	)


## A single, very generous, non-flaky sanity ceiling (catches a genuine
## O(n^2)/hang-class regression, never CI wall-clock noise) -- per this
## story's own Advisory posture the RECORDED envelope numbers are never
## gated, but a catastrophic outlier is still worth a hard failure. 1000 ms
## is roughly 60x the 16.6 ms budget and roughly 30x the pre-VS spike's own
## worst measured single-pass cost (35 ms p95, `prototypes/perf-spike-qq3/
## REPORT.md`).
const _SANITY_CEILING_MS: float = 1000.0


func _assert_sanity_ceiling(stats: Dictionary) -> void:
	assert_float(stats.max).is_less(_SANITY_CEILING_MS)


# ---------------------------------------------------------------------------
# Scenario 1 -- unreachable-job-dense Deciding stress (GDD F2's own worst
# case: up to `max_selection_candidates` = 15 fruitless pathfind attempts per
# villager per pass; every job in this scenario is unreachable, so the floor
# (Wandering) and the `decision_interval` periodic re-check keep regenerating
# this worst case every few ticks for the whole run -- sustained pressure,
# not a one-shot event).
# ---------------------------------------------------------------------------

func _run_unreachable_job_dense_scenario(population: int) -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 15)
	# 20 isolated islands -- comfortably exceeds `max_selection_candidates`
	# (15, default), guaranteeing every Deciding pass burns the FULL
	# candidate cap before falling through to Wandering (GDD F2's own
	# documented worst case), for every villager, every time it decides.
	var island_targets: Array[Vector3i] = _build_isolated_islands(env.grid, 20, 20)
	var project: BuildProject = _released_project(1, island_targets)
	env.queue.add_project(project)

	var nav_graph: VillagerNavGraph = _build_nav_graph(env.grid, Vector3i(25, 1, 25), 50)
	var scheduler := VillagerDecidingScheduler.new()
	var spawn_cells: Array[Vector3i] = _spawn_cells(population)
	var villagers: Array[VillagerAi] = []
	for i in range(population):
		villagers.append(_make_full_villager(env, nav_graph, scheduler, tick_source, i, spawn_cells[i]))

	# 1x -- 150 samples, one tick each.
	var costs_1x: Array[float] = _measure_samples_ms(tick_source, villagers, 150, 1)
	var stats_1x: Dictionary = _stats(costs_1x)
	_report("unreachable-job-dense pop=%d warp=1x" % population, stats_1x)
	_assert_sanity_ceiling(stats_1x)

	# 3x warp -- 150 samples, three ticks each (same population, same queue).
	var costs_3x: Array[float] = _measure_samples_ms(tick_source, villagers, 150, 3)
	var stats_3x: Dictionary = _stats(costs_3x)
	_report("unreachable-job-dense pop=%d warp=3x" % population, stats_3x)
	_assert_sanity_ceiling(stats_3x)

	# Structural correctness: with every candidate genuinely unreachable, no
	# villager ever holds a claim, and every villager eventually falls
	# through to the Wandering floor (Edge Case 12/GDD F2's own documented
	# fallback) -- never stuck in Deciding, never an error, at population
	# scale.
	for villager: VillagerAi in villagers:
		assert_bool(env.queue.has_claim(villager.get_villager_id())).is_false()
		assert_int(villager.get_state()).is_equal(VillagerAi.State.WANDERING)


func test_measured_unreachable_job_dense_deciding_cost_5_villagers() -> void:
	_run_unreachable_job_dense_scenario(5)


func test_measured_unreachable_job_dense_deciding_cost_30_villagers() -> void:
	_run_unreachable_job_dense_scenario(30)


# ---------------------------------------------------------------------------
# Scenario 2 -- real claim->travel->build->report cycle at population scale,
# PLUS a parallel "construction happening elsewhere" write-storm exercising
# the Rule 10b re-path filter's aggregate cost (GDD OQ3(a)/(c)).
# ---------------------------------------------------------------------------

## Fires one `bulk_write` batch of [constant _STORM_BATCH_SIZE] cells FAR from
## the main platform/job area (never intersecting any villager's clearance
## envelope -- Rule 10b's own negative case, AC49's "zero re-path
## evaluations," exercised here at population scale rather than for one
## villager) -- models unrelated background construction elsewhere in a
## larger settlement. Alternates solid/empty per call index so every batch is
## a genuine change (never a same-value no-op).
const _STORM_BATCH_SIZE: int = 10
const _STORM_FAR_X: int = 40


func _fire_background_write_storm(grid: VoxelWorldGrid, sample_index: int) -> void:
	var changes: Dictionary[Vector3i, CellContents] = {}
	var solid: bool = sample_index % 2 == 0
	for i in range(_STORM_BATCH_SIZE):
		var cell := Vector3i(_STORM_FAR_X + i, 0, sample_index % 40)
		changes[cell] = CellContents.new(1, 0) if solid else CellContents.new(0, 0)
	grid.bulk_write(changes)


func _run_construction_write_storm_scenario(population: int) -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 15)
	var job_targets: Array[Vector3i] = _reachable_job_targets(60, 15)
	var project: BuildProject = _released_project(1, job_targets)
	env.queue.add_project(project)

	var nav_graph: VillagerNavGraph = _build_nav_graph(env.grid, Vector3i(25, 1, 25), 50)
	var scheduler := VillagerDecidingScheduler.new()
	var spawn_cells: Array[Vector3i] = _spawn_cells(population)
	var villagers: Array[VillagerAi] = []
	for i in range(population):
		villagers.append(_make_full_villager(env, nav_graph, scheduler, tick_source, i, spawn_cells[i]))

	var storm: Callable = func(sample_index: int) -> void:
		_fire_background_write_storm(env.grid, sample_index)

	# 1x -- 150 samples, one tick each, with a write-storm batch every sample.
	var costs_1x: Array[float] = _measure_samples_ms(tick_source, villagers, 150, 1, storm)
	var stats_1x: Dictionary = _stats(costs_1x)
	_report("construction-write-storm pop=%d warp=1x" % population, stats_1x)
	_assert_sanity_ceiling(stats_1x)

	# 3x warp -- 150 more samples, three ticks each, storm continues.
	var costs_3x: Array[float] = _measure_samples_ms(tick_source, villagers, 150, 3, storm)
	var stats_3x: Dictionary = _stats(costs_3x)
	_report("construction-write-storm pop=%d warp=3x" % population, stats_3x)
	_assert_sanity_ceiling(stats_3x)

	# Structural correctness: the real cycle actually closes for at least
	# some jobs at this population/scale, under the write-storm -- proves the
	# claim->travel->build->report loop (011/012) survives the storm, not
	# merely that ticks fired.
	var built_count: int = 0
	for cell: Vector3i in job_targets:
		if project.cells[cell].state == BlueprintCell.MicroState.BUILT:
			built_count += 1
	assert_int(built_count).is_greater(0)


func test_measured_construction_write_storm_cost_5_villagers() -> void:
	_run_construction_write_storm_scenario(5)


func test_measured_construction_write_storm_cost_30_villagers() -> void:
	_run_construction_write_storm_scenario(30)


# ---------------------------------------------------------------------------
# Scenario 3 -- synchronized mass-Deciding spike (GDD Rule 10c / ADR-0008
# Decision Section 2's own validation criterion, "a mass-Deciding event
# cannot let every eligible villager run F2 in the same tick," extended here
# to the full 30-population stress scale instead of a small unit-test
# population).
# ---------------------------------------------------------------------------

func test_structural_stagger_holds_under_full_population_synchronized_mass_deciding_spike() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 15)
	var job_targets: Array[Vector3i] = _reachable_job_targets(60, 15)
	var project: BuildProject = _released_project(1, job_targets)
	env.queue.add_project(project)

	var nav_graph: VillagerNavGraph = _build_nav_graph(env.grid, Vector3i(25, 1, 25), 50)
	var scheduler := VillagerDecidingScheduler.new()
	var spawn_cells: Array[Vector3i] = _spawn_cells(30)
	var villagers: Array[VillagerAi] = []
	for i in range(30):
		villagers.append(_make_full_villager(env, nav_graph, scheduler, tick_source, i, spawn_cells[i]))

	# Let the initial at-setup() enqueue drain naturally first.
	for _i in range(40):
		for villager: VillagerAi in villagers:
			if villager.is_moving():
				villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()

	# The synthetic spike: simulate "a large command's completion frees many
	# jobs at once" (GDD Rule 10c's own worked scenario) by force-re-enqueuing
	# EVERY villager in the SAME tick, regardless of current state.
	for villager: VillagerAi in villagers:
		villager.request_deciding_pass()
	assert_int(scheduler.queue_length()).is_equal(30)

	# The load-bearing invariant, checked EVERY tick of the drain window
	# (ADR-0008's own Validation Criteria, extended from a small unit-test
	# population to this story's full 30-population stress scale): at most
	# `max_deciding_per_tick` (read LIVE from a fresh config -- Sprint 8
	# re-tune, Story villager-ai-022: 5, was 1) villager ids are ever runnable
	# in a single tick, however many are queued.
	var max_deciding_per_tick: int = VillagerAIConfig.new().max_deciding_per_tick
	var drain_costs_ms: Array[float] = []
	var queue_depth_samples: Array[float] = []
	var ticks_used: int = 0
	while ticks_used < 60:
		for villager: VillagerAi in villagers:
			if villager.is_moving():
				villager.advance_travel_progress(1000.0)
		var start_usec: int = Time.get_ticks_usec()
		tick_source.fire_tick()
		drain_costs_ms.append((Time.get_ticks_usec() - start_usec) / 1000.0)
		var runnable_count: int = 0
		for villager: VillagerAi in villagers:
			if scheduler.is_runnable_this_tick(villager.get_villager_id()):
				runnable_count += 1
		assert_int(runnable_count).is_less_equal(max_deciding_per_tick)
		# Structural boundedness: `_queued_ids`' own dedup guard (Story
		# villager-ai-005) means the queue can NEVER exceed the population,
		# however much re-enqueue pressure Rule 2's periodic
		# `decision_interval` recheck (which fires unconditionally every
		# tick for EVERY villager, regardless of state -- see
		# `_check_decision_interval_trigger`'s own doc comment) piles on.
		assert_int(scheduler.queue_length()).is_less_equal(30)
		queue_depth_samples.append(float(scheduler.queue_length()))
		ticks_used += 1

	# Sprint 8 re-tune re-run (Story villager-ai-022, quick-spec
	# design/quick-specs/tick-rate-retune-2026-07-25.md §4 F-retune-2): the
	# ORIGINAL Sprint 7 run of this exact test, at the OLD defaults
	# (`decision_interval = 2`, `max_deciding_per_tick = 1`), found the queue
	# reached a CHRONICALLY BUSY, bounded-but-never-quiet steady state (S7
	# baseline: avg 29.5 / p95 30.0 / max 30.0 of 30) -- demand
	# (~population/decision_interval ≈ 15/tick) far outpaced supply (1/tick).
	# At the NEW defaults (`decision_interval = 4`, `max_deciding_per_tick =
	# 5`, read LIVE above), supply_per_cycle (5*4=20) now exceeds
	# demand_per_cycle (ceil(30/4)=8) -- the queue is expected to reach
	# quiescence BETWEEN periodic-recheck cycles instead of sitting
	# chronically near-full. Asserted below as a measurably-lower average,
	# not merely "still bounded" (that safety property -- never a
	# synchronized all-at-once spike -- held at BOTH old and new values, and
	# is unaffected by this re-tune; it is the STANDING queue depth that
	# changes).
	var queue_depth_stats: Dictionary = _stats(queue_depth_samples)
	print(
		"[villager-ai-022] synchronized-mass-deciding-spike pop=30 queue-depth (AFTER re-tune) -- "
		+ "avg=%.1f p95=%.1f max=%.1f (of 30) over %d ticks -- BEFORE (S7 baseline, k=1/interval=2): avg=29.5 p95=30.0 max=30.0" %
		[queue_depth_stats.avg, queue_depth_stats.p95, queue_depth_stats.max, queue_depth_stats.n]
	)
	assert_float(queue_depth_stats.avg).is_less(29.5).override_failure_message(
		"expected the re-tuned queue-depth average to be measurably below the S7 chronic-backlog "
		+ "baseline of 29.5 (quiescence per F-retune-2), got %.2f" % queue_depth_stats.avg
	)
	var drain_stats: Dictionary = _stats(drain_costs_ms)
	_report("synchronized-mass-deciding-spike pop=30 per-tick-cost", drain_stats)
	_assert_sanity_ceiling(drain_stats)


# ---------------------------------------------------------------------------
# Sprint 8 coordinated re-tune re-run (Story villager-ai-022, quick-spec
# design/quick-specs/tick-rate-retune-2026-07-25.md) -- the specific NEW
# measurements the quick-spec's own Acceptance Criteria (§9) require against
# production code, replacing its [ESTIMATED] figures with measured ones.
# ---------------------------------------------------------------------------

## Quick-spec AC1/F-retune-1 -- worst-case Deciding-queue wait for the
## pathological synchronized mass-event case, measured against the SAME real
## production environment as Scenario 3 above (real job cycle, real
## `decision_interval=4` cadence -- no artificial isolation), per the QA
## plan's own framing ("Measured worst-case ticks-to-decide at pop 30,
## synchronized mass-Deciding (Scenario 3)"). Tracks the specific 30 villager
## ids force-enqueued by THIS test's own mass event -- not "when does the
## shared queue as a whole go empty," since real background traffic (the
## periodic recheck, job-cycle transitions) legitimately keeps adding
## unrelated entries to the same FIFO queue throughout the drain window;
## the quick-spec's F-retune-1 bound is about how long the mass-event's OWN
## members wait, which FIFO ordering keeps well-defined regardless of what
## joins behind them. The clean, fully isolated ceil(population/budget)=6
## bound (zero contention) is separately proven exactly in
## `tests/unit/villager_ai/deciding_scheduler_test.gd`'s own
## `test_synchronized_mass_deciding_scenario_run_twice_at_k5_produces_identical_dequeue_order`
## -- this test instead reports the REAL, contention-inclusive number.
func test_measured_worst_case_ticks_to_decide_synchronized_mass_deciding_pop30_k5() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 15)
	var job_targets: Array[Vector3i] = _reachable_job_targets(60, 15)
	var project: BuildProject = _released_project(1, job_targets)
	env.queue.add_project(project)

	var nav_graph: VillagerNavGraph = _build_nav_graph(env.grid, Vector3i(25, 1, 25), 50)
	var scheduler := VillagerDecidingScheduler.new()
	var spawn_cells: Array[Vector3i] = _spawn_cells(30)
	var villagers: Array[VillagerAi] = []
	for i in range(30):
		villagers.append(_make_full_villager(env, nav_graph, scheduler, tick_source, i, spawn_cells[i]))

	# Let the initial at-setup() enqueue drain naturally first (mirrors
	# Scenario 3's own warmup above).
	for _i in range(40):
		for villager: VillagerAi in villagers:
			if villager.is_moving():
				villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()

	# The synthetic mass event (GDD Rule 10c): every villager force-re-enqueued
	# in the SAME tick. Tracked by id, independent of the shared queue's other
	# (real-behavior-driven) traffic.
	for villager: VillagerAi in villagers:
		villager.request_deciding_pass()
	var pending_ids: Dictionary = {}
	for villager: VillagerAi in villagers:
		pending_ids[villager.get_villager_id()] = true
	assert_int(pending_ids.size()).is_equal(30)

	var max_deciding_per_tick: int = VillagerAIConfig.new().max_deciding_per_tick
	var ticks_used: int = 0
	while not pending_ids.is_empty() and ticks_used < 60:
		for villager: VillagerAi in villagers:
			if villager.is_moving():
				villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()
		ticks_used += 1
		for villager: VillagerAi in villagers:
			var id: int = villager.get_villager_id()
			if pending_ids.has(id) and scheduler.is_runnable_this_tick(id):
				pending_ids.erase(id)

	var isolated_bound: int = int(ceil(30.0 / max_deciding_per_tick))
	print(
		"[villager-ai-022] worst-case-ticks-to-decide (real env, contention-inclusive) pop=30 "
		+ "max_deciding_per_tick=%d -- measured=%d ticks (isolated bound=%d, quick-spec F-retune-1) -- " %
		[max_deciding_per_tick, ticks_used, isolated_bound]
		+ "BEFORE (k=1, S7 baseline, own isolated measure): 30 ticks"
	)
	assert_int(pending_ids.size()).is_equal(0)
	# Generous, non-flaky sanity bound (this file's own convention) -- real
	# background contention (periodic recheck + job-cycle re-enqueues) can
	# legitimately push this above the zero-contention isolated bound of 6,
	# but must stay well clear of the OLD k=1 worst case (30 ticks).
	assert_int(ticks_used).is_less_equal(20)


## Quick-spec §8 Risk 2 / QA plan Call-out 4 -- measures the burst-frame
## amplification case instead of leaving it [ESTIMATED]: a
## `max_ticks_per_frame=12` catch-up frame at the new `max_deciding_per_tick=5`
## can drain up to 12*5=60 Deciding passes in ONE frame -- more than the
## 30-villager population ceiling, so this single frame fully clears any
## mass-Deciding backlog. Measures the actual one-off cost AND confirms the
## pattern is a single isolated frame event, never recurring on consecutive
## frames (the quick-spec's own escalation trigger for further profiling, if
## it were ever observed recurring -- checked here as an explicit negative
## case).
func test_measured_burst_frame_12_tick_catchup_amplification_is_isolated_not_recurring() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 15)
	var job_targets: Array[Vector3i] = _reachable_job_targets(60, 15)
	var project: BuildProject = _released_project(1, job_targets)
	env.queue.add_project(project)

	var nav_graph: VillagerNavGraph = _build_nav_graph(env.grid, Vector3i(25, 1, 25), 50)
	var scheduler := VillagerDecidingScheduler.new()
	var spawn_cells: Array[Vector3i] = _spawn_cells(30)
	var villagers: Array[VillagerAi] = []
	for i in range(30):
		villagers.append(_make_full_villager(env, nav_graph, scheduler, tick_source, i, spawn_cells[i]))

	# Let the initial at-setup() enqueue drain first, at normal cadence.
	for _i in range(10):
		for villager: VillagerAi in villagers:
			if villager.is_moving():
				villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()

	# Simulate a post-stall resume: force-re-enqueue the full population (a
	# mass-event, matching Scenario 3 above), then drive ONE frame's worth of
	# `max_ticks_per_frame=12` catch-up ticks inside a SINGLE timed sample --
	# reuses `_measure_samples_ms`'s own "N ticks land in the same frame"
	# methodology (`ticks_per_sample=12` for exactly one sample).
	for villager: VillagerAi in villagers:
		villager.request_deciding_pass()
	assert_int(scheduler.queue_length()).is_equal(30)

	var burst_costs: Array[float] = _measure_samples_ms(tick_source, villagers, 1, 12)
	var burst_cost_ms: float = burst_costs[0]

	# Follow-up frames at normal cadence (1 tick each) -- must NOT reproduce
	# the same elevated cost, proving the burst is a single, isolated frame
	# event, never a sustained/recurring pattern.
	var followup_costs: Array[float] = _measure_samples_ms(tick_source, villagers, 10, 1)
	var followup_stats: Dictionary = _stats(followup_costs)

	print(
		"[villager-ai-022] burst-frame-amplification pop=30 max_ticks_per_frame=12 max_deciding_per_tick=5 -- "
		+ "burst_cost=%.3fms followup_avg=%.3fms followup_max=%.3fms (quick-spec estimate: ~37ms one-off)" %
		[burst_cost_ms, followup_stats.avg, followup_stats.max]
	)
	_assert_sanity_ceiling({"max": burst_cost_ms})
	# Isolation: every follow-up frame's cost stays well under the single
	# burst frame's own cost -- an elevated burst cost, IF it recurred on the
	# very next frames, would be the quick-spec's own documented signal to
	# profile further; this asserts it does NOT recur.
	assert_float(followup_stats.max).is_less(burst_cost_ms).override_failure_message(
		"burst-frame cost did not stay isolated -- follow-up frames measured "
		+ "max=%.3fms against the burst's own %.3fms" % [followup_stats.max, burst_cost_ms]
	)
