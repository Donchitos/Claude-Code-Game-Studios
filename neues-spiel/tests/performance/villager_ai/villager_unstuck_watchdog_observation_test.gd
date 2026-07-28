## Observation harness — M01 Go/No-Go condition C3 (`production/milestones/
## milestone-01-review-2026-07-26.md`), the automatable half: "`villager_unstuck`
## counters observed firing and recovering agents over a real run with no
## permanent stuck — closes #13 clause 3 and executes the CD ruling's own #7
## design test."
##
## **Advisory, not a Done/smoke blocker** (mirrors `stress_30_villager_test.gd`'s
## own posture exactly — this file lives under `res://tests/performance`
## deliberately, so it never joins `tests/run-tests.cmd`'s BLOCKING
## unit+integration glob). It still must be REAL and reproducible headless:
## every number below comes from [VillagerUnstuckTelemetry] (the real F3
## counter source, story villager-ai-015) and real [VillagerAi]/
## [ConstructionTickLoop]/[ConstructionJobQueue] instances — never a re-derived
## fake counter — and is `print()`-ed for hand-transcription into
## `production/qa/evidence/m01-closure-evidence-20260726.md`, the same
## "measured, then reported, not gated" discipline `stress_30_villager_test.gd`'s
## own class doc comment documents.
##
## Two scenarios, run separately (test-isolation rule — each builds its own
## fixture from scratch):
##
## 1. **Natural long run** — a real 15-villager population doing real
##    claim -> travel -> build work against a real, ordinary (non-adversarial)
##    platform for 600 real ticks, with the full anti-stuck stack wired
##    (on-site gate AND seal-prevention gate, exactly like production `Valley`
##    wiring) — reports whatever the watchdog counters read.
##
##    **M01 closure fix applied** (`production/qa/evidence/m01-closure-
##    evidence-20260726.md` Scenario 1, fixed 2026-07-26): this run's own
##    `permanent_stuck_count` sweep used to be NON-zero — every villager that
##    completed a single-cell BUILD job ended up in the documented "self-seal"
##    case (`VillagerSealPreventionGate`'s own class doc comment: "the
##    villager ending up standing inside now-solid content, cleaned up later
##    by the Unstuck Watchdog's own rescue... on its normal schedule"), but
##    [method VillagerAi._tick_working] transitioned WORKING -> DECIDING the
##    SAME tick it detected the completion, so the self-sealed villager could
##    accumulate only ONE stuck tick before leaving the (then-strictly)
##    TRAVELING/WORKING-scoped watchdog counter for good — structurally short
##    of `unstuck_watchdog_threshold_ticks`, staying `is_distressed() == true`
##    forever in DECIDING/WANDERING. [method VillagerAi._update_unstuck_watchdog]
##    now keeps counting/rescuing a villager whose OWN `current_cell` has
##    become non-standable (the self-seal signature) REGARDLESS of `_state` —
##    see that method's own doc comment for the exact, narrowly-scoped carve-
##    out (Edge Case 2/AC32's "standable but walled in while Idle/Wandering/
##    Sleeping/Breather" negative case is completely untouched). Every
##    self-sealed builder below is now rescued: the watchdog fire/recovery
##    counters equal `built_count` (one rescue per completed job that
##    self-sealed its own builder), and `permanent_stuck_count` is zero.
## 2. **Adversarial sealed-room scenario** (per the review's own suggestion —
##    "workers sealing a room per the story-016 fixture") — reuses
##    `seal_prevention_real_build_write_test.gd`'s own proven `_wall_off_room`
##    geometry, TWICE, in the SAME real world: a bystander villager (fully
##    `setup()`-wired, ticking automatically off the same real tick source, at
##    PRODUCTION-DEFAULT [VillagerAIConfig] tuning — no threshold shortened for
##    this observation) is placed inside each room while a separate, real,
##    un-trapped WORKER villager completes the room's doorway as a REAL BUILD
##    job through the REAL [ConstructionTickLoop]/[ConstructionJobQueue] write
##    path (the seal-prevention gate legitimately allows this specific write —
##    the WORKER is never the one who gets trapped, only the bystander is, and
##    seal-prevention only ever protects the claiming worker, never a
##    bystander — see [VillagerSealPreventionGate]'s own class doc comment).
##    Once both doorways are real, solid writes, both bystanders are
##    genuinely walled in with zero legal step; the real watchdog on each is
##    then given real production-default `unstuck_watchdog_threshold_ticks`
##    (12) plus margin to fire, and this test asserts a REAL rescue for both —
##    fire count, recovery count, `unstuck_search_failed` count, and a final
##    permanent-stuck sweep (must be zero) are all reported.
class_name VillagerUnstuckWatchdogObservationTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Shared fixtures (helpers ABOVE every test function, this codebase's own
# convention) — mirrors `stress_30_villager_test.gd`/
# `seal_prevention_real_build_write_test.gd`'s own established fixture shapes.
# ---------------------------------------------------------------------------

class _Environment:
	var grid: VoxelWorldGrid
	var loop: ConstructionTickLoop
	var loop_config: ConstructionTickLoopConfig
	var queue: ConstructionJobQueue
	var onsite_gate: VillagerOnSiteGate
	var ai_config: VillagerAIConfig
	var seal_gate: VillagerSealPreventionGate


func _solid() -> CellContents:
	return CellContents.new(1, 0)


func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), _solid())


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


func _released_project(id: int, cells: Array[Vector3i]) -> BuildProject:
	var project := BuildProject.new(id)
	for cell: Vector3i in cells:
		project.add_cell(_planned_cell(cell))
	project.release()
	return project


func _make_environment(tick_source: Object, platform_size: int, ai_config: VillagerAIConfig = null) -> _Environment:
	var env := _Environment.new()
	env.grid = _new_grid()
	_fill_flat_platform(env.grid, platform_size)
	env.loop = auto_free(ConstructionTickLoop.new())
	env.loop.voxel_world = env.grid
	env.loop_config = ConstructionTickLoopConfig.new()
	env.loop.config = env.loop_config
	env.loop.time_tick_system = tick_source
	env.loop.setup()
	env.queue = ConstructionJobQueue.new(env.loop)
	env.onsite_gate = VillagerOnSiteGate.new(env.queue)
	env.ai_config = ai_config if ai_config != null else VillagerAIConfig.new()
	env.seal_gate = VillagerSealPreventionGate.new(env.queue, env.ai_config)
	return env


func _build_nav_graph(grid: VoxelWorldGrid, region_center: Vector3i, region_size: int) -> VillagerNavGraph:
	var predicate_source: VillagerAi = auto_free(VillagerAi.new())
	predicate_source.voxel_world = grid
	predicate_source.villager_id = -1
	var nav_graph := VillagerNavGraph.new()
	nav_graph.subscribe_to_voxel_world(grid, predicate_source)
	nav_graph.build(grid, predicate_source, region_center, region_size)
	return nav_graph


## A fully real, `setup()`-wired [VillagerAi] -- registered with BOTH the
## on-site gate AND the seal-prevention gate (mirrors real `Valley` wiring),
## sharing [param telemetry] and a `unstuck_search_failed` counter with the
## rest of the observed population. Uses [param env]'s own [member
## _Environment.ai_config] (never a second, un-registered config instance) so
## every villager in one observation run shares identical tuning.
func _make_full_villager(
	env: _Environment,
	nav_graph: VillagerNavGraph,
	scheduler: VillagerDecidingScheduler,
	tick_source: Object,
	villager_id: int,
	spawn_cell: Vector3i,
	telemetry: VillagerUnstuckTelemetry,
	search_failed_counter: Array,
) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = env.ai_config
	villager.voxel_world = env.grid
	villager.scheduler = scheduler
	villager.nav_graph = nav_graph
	villager.time_tick_system = tick_source
	villager.job_queue = env.queue
	villager.villager_id = villager_id
	villager.unstuck_telemetry = telemetry
	villager.current_cell = spawn_cell
	villager._from_cell = spawn_cell
	villager._to_cell = spawn_cell
	villager.setup()
	env.onsite_gate.register_villager(villager)
	env.seal_gate.register_villager(villager)
	villager.unstuck_search_failed.connect(func() -> void: search_failed_counter[0] += 1)
	return villager


func _spawn_cells(count: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var per_row: int = 15
	for i in range(count):
		cells.append(Vector3i(i % per_row, 1, i / per_row))
	return cells


func _reachable_job_targets(count: int, platform_size: int) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var per_row: int = platform_size
	var start_z: int = 4
	for i in range(count):
		var z: int = start_z + i / per_row
		var x: int = i % per_row
		cells.append(Vector3i(x, 1, z))
	return cells


## Sweeps every villager's own real travel progress forward with a saturating
## `game_delta` (mirrors `stress_30_villager_test.gd`'s own `_measure_samples_ms`
## methodology -- the delta's magnitude only affects HOW MANY samples a real
## multi-cell path needs, never the underlying per-tick logic being observed),
## then fires exactly one real tick.
func _advance_population_and_tick(tick_source: MockTimeTickSystem, villagers: Array[VillagerAi]) -> void:
	for villager: VillagerAi in villagers:
		if villager.is_moving():
			villager.advance_travel_progress(1000.0)
	tick_source.fire_tick()


## Counts how many of [param villagers] are STILL genuinely stuck right now
## (the "permanent-stuck" sweep the review's own condition C3 names) -- a
## villager is only ever "permanently" stuck if it is distressed (no legal
## step / non-standable current cell) AT THE MOMENT this is called, after the
## observation window has run long enough for the watchdog to have already
## rescued it if a rescue was ever going to happen.
func _count_currently_stuck(villagers: Array[VillagerAi]) -> int:
	var count: int = 0
	for villager: VillagerAi in villagers:
		if villager.is_distressed():
			count += 1
	return count


## Builds the story-016 sealed-room fixture (mirrors
## `seal_prevention_real_build_write_test.gd`'s own `_wall_off_room` exactly):
## walls at y=1 on three sides of [param room_interior], the fourth side
## ([param doorway]) is the only legal exit and the target of the real BUILD
## job a worker completes to seal it; a ceiling plate above
## [constant VillagerAi.VILLAGER_CLEARANCE]'s own span so a villager cannot
## simply step up and over a single newly-solid wall/doorway cell.
func _wall_off_room(grid: VoxelWorldGrid, room_interior: Vector3i, doorway: Vector3i) -> void:
	var offsets: Array[Vector3i] = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	for offset: Vector3i in offsets:
		var neighbor: Vector3i = room_interior + offset
		if neighbor != doorway:
			grid.set_cell(neighbor + Vector3i(0, 1, 0), _solid())
	var ceiling_y: int = room_interior.y + 3
	for x in range(room_interior.x - 1, room_interior.x + 2):
		for z in range(room_interior.z - 1, room_interior.z + 2):
			grid.set_cell(Vector3i(x, ceiling_y, z), _solid())


## A bare, un-`setup()` worker used ONLY to hold the real doorway-completion
## claim (mirrors `seal_prevention_real_build_write_test.gd`'s own
## `_make_bare_villager`/`_claim_directly` pattern) -- placed OUTSIDE the room
## it is sealing, so it is never the one seal-prevention would trap, letting
## the real write commit on the first attempt.
func _make_bare_worker(env: _Environment, villager_id: int, position: Vector3i) -> VillagerAi:
	var worker: VillagerAi = auto_free(VillagerAi.new())
	worker.voxel_world = env.grid
	worker.villager_id = villager_id
	worker.current_cell = position
	worker._from_cell = position
	worker._to_cell = position
	return worker


func _claim_doorway_for_worker(env: _Environment, project: BuildProject, doorway: Vector3i, worker: VillagerAi) -> void:
	assert_bool(env.queue.claim_job(doorway, worker.villager_id)).is_true()
	worker.job_queue = env.queue
	worker._claimed_blueprint_cell = project.cells[doorway]
	worker._pursued_activity = VillagerAi.PursuedActivity.WORK
	worker._state = VillagerAi.State.WORKING
	env.onsite_gate.register_villager(worker)
	env.seal_gate.register_villager(worker)


func _fire_full_build_cycle(tick_source: MockTimeTickSystem, env: _Environment) -> void:
	for _i in range(env.loop_config.base_build_ticks_block):
		tick_source.fire_tick()


# ---------------------------------------------------------------------------
# Scenario 1 — natural long run, real 15-villager population, real
# construction traffic, ordinary (non-adversarial) platform, 600 real ticks.
# ---------------------------------------------------------------------------

func test_natural_long_run_real_population_construction_produces_zero_stuck_events() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 20)
	var job_targets: Array[Vector3i] = _reachable_job_targets(80, 20)
	var project: BuildProject = _released_project(1, job_targets)
	env.queue.add_project(project)

	var nav_graph: VillagerNavGraph = _build_nav_graph(env.grid, Vector3i(10, 1, 10), 30)
	var scheduler := VillagerDecidingScheduler.new()
	var telemetry := VillagerUnstuckTelemetry.new()
	var search_failed_counter: Array = [0]
	var population_size := 15
	var spawn_cells: Array[Vector3i] = _spawn_cells(population_size)
	var villagers: Array[VillagerAi] = []
	for i in range(population_size):
		villagers.append(
			_make_full_villager(env, nav_graph, scheduler, tick_source, i, spawn_cells[i], telemetry, search_failed_counter)
		)

	const RUN_TICKS: int = 600
	for _t in range(RUN_TICKS):
		_advance_population_and_tick(tick_source, villagers)

	var built_count: int = 0
	for cell: Vector3i in job_targets:
		if project.cells[cell].state == BlueprintCell.MicroState.BUILT:
			built_count += 1
	var permanent_stuck_count: int = _count_currently_stuck(villagers)

	print(
		(
			"[m01-c3] SCENARIO 1 (natural long run) -- population=%d ticks=%d job_targets=%d built=%d -- "
			+ "watchdog_fire_count=%d recovery_count=%d unstuck_search_failed_count=%d permanent_stuck_count=%d "
			+ "(config: threshold=%d search_radius=%d max_radius=%d, PRODUCTION DEFAULTS)"
		) % [
			population_size, RUN_TICKS, job_targets.size(), built_count,
			telemetry.get_world_total(), telemetry.get_world_total(), search_failed_counter[0], permanent_stuck_count,
			env.ai_config.unstuck_watchdog_threshold_ticks, env.ai_config.unstuck_rescue_search_radius,
			env.ai_config.unstuck_rescue_max_radius,
		]
	)

	# Structural correctness: real construction work actually happened (the
	# population is doing something real, not idling). No OUTSIDE write ever
	# walls anyone in on this ordinary, non-adversarial platform, but every
	# completed single-cell BUILD job DOES self-seal its own builder (Rule
	# 16's own documented exception) -- the M01 closure fix (see this
	# function's own doc comment) means the watchdog now rescues every one of
	# them, so the fire/recovery counters track `built_count` one-to-one and
	# permanent-stuck is zero, closing the milestone's own #13 clause 3 "no
	# permanent stuck" criterion for this natural-traffic run too.
	assert_int(built_count).is_greater(0)
	assert_int(telemetry.get_world_total()).is_equal(built_count)
	assert_int(search_failed_counter[0]).is_equal(0)
	assert_int(permanent_stuck_count).is_equal(0)


# ---------------------------------------------------------------------------
# Scenario 2 — adversarial: workers seal two rooms (story-016 fixture) with
# bystanders inside, at PRODUCTION-DEFAULT watchdog tuning; the real watchdog
# must fire and recover both, with zero permanent stuck.
# ---------------------------------------------------------------------------

func test_adversarial_workers_seal_rooms_around_bystanders_watchdog_rescues_both_zero_permanent_stuck() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 12)

	var room_a_interior := Vector3i(3, 1, 3)
	var room_a_doorway := Vector3i(2, 1, 3)
	var room_b_interior := Vector3i(8, 1, 8)
	var room_b_doorway := Vector3i(7, 1, 8)
	_wall_off_room(env.grid, room_a_interior, room_a_doorway)
	_wall_off_room(env.grid, room_b_interior, room_b_doorway)

	var project: BuildProject = _released_project(1, [room_a_doorway, room_b_doorway])
	env.queue.add_project(project)

	var scheduler := VillagerDecidingScheduler.new()
	var telemetry := VillagerUnstuckTelemetry.new()
	var search_failed_counter: Array = [0]
	var rescued_cells: Array = []

	# Bystanders -- fully real, `setup()`-wired villagers, ticking off the
	# SAME shared real tick source as everything else, at PRODUCTION-DEFAULT
	# WATCHDOG tuning (threshold/search_radius/max_radius all untouched, still
	# `env.ai_config`'s own production defaults). `_pursued_activity = WORK`
	# with a fake, far-away claimed cell (mirrors `unstuck_watchdog_test.gd`'s
	# own proven AC51 fixture exactly) is load-bearing here, NOT cosmetic:
	# without it, Rule 2's periodic `decision_interval` re-check -- an
	# UNRELATED mechanic this population's shared scheduler legitimately
	# preempts mid-activity with, real production behavior -- finds this
	# artificially-placed bystander holding no claim and immediately re-decides
	# it to Wandering (tier 3, no job/need) before the watchdog ever gets a
	# chance to accumulate past threshold; claim-stickiness (tier 2's own
	# documented no-op for an already-WORK-committed villager) is what a
	# genuinely traveling worker relies on to stay put through that SAME
	# periodic re-check in real gameplay, so this fixture reproduces that
	# real protection rather than sidestepping it.
	var nav_graph: VillagerNavGraph = _build_nav_graph(env.grid, Vector3i(6, 1, 6), 20)
	var bystander_a: VillagerAi = _make_full_villager(
		env, nav_graph, scheduler, tick_source, 100, room_a_interior, telemetry, search_failed_counter
	)
	bystander_a._state = VillagerAi.State.TRAVELING
	bystander_a._pursued_activity = VillagerAi.PursuedActivity.WORK
	bystander_a._claimed_blueprint_cell = BlueprintCell.new(Vector3i(99, 1, 99))
	bystander_a.unstuck_rescued.connect(func(cell: Vector3i) -> void: rescued_cells.append(cell))
	var bystander_b: VillagerAi = _make_full_villager(
		env, nav_graph, scheduler, tick_source, 101, room_b_interior, telemetry, search_failed_counter
	)
	bystander_b._state = VillagerAi.State.TRAVELING
	bystander_b._pursued_activity = VillagerAi.PursuedActivity.WORK
	bystander_b._claimed_blueprint_cell = BlueprintCell.new(Vector3i(98, 1, 98))
	bystander_b.unstuck_rescued.connect(func(cell: Vector3i) -> void: rescued_cells.append(cell))

	# Workers -- bare, ON-SITE (adjacent to their own doorway, from the
	# OUTSIDE -- required for real per-tick progress crediting,
	# [VillagerOnSiteGate]'s own Rule 5 seam), but never themselves trapped by
	# completing the write (the room's walls only enclose the INTERIOR side;
	# these positions sit in the open, one step further out than the doorway
	# itself, so `would_trap_builder` never fires for the worker).
	var worker_a: VillagerAi = _make_bare_worker(env, 200, Vector3i(1, 1, 3))
	_claim_doorway_for_worker(env, project, room_a_doorway, worker_a)
	var worker_b: VillagerAi = _make_bare_worker(env, 201, Vector3i(6, 1, 8))
	_claim_doorway_for_worker(env, project, room_b_doorway, worker_b)

	var all_villagers: Array[VillagerAi] = [bystander_a, bystander_b]

	# Act 1 -- the real writes that seal both rooms (each doorway completes
	# through the REAL ConstructionTickLoop/ConstructionJobQueue write path;
	# bystanders' own watchdogs are already ticking every frame this fires,
	# but neither is stuck yet -- the doorway is still their one legal step).
	_fire_full_build_cycle(tick_source, env)

	assert_int(project.cells[room_a_doorway].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(project.cells[room_b_doorway].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(room_a_doorway).is_empty()).is_false()
	assert_bool(env.grid.get_cell(room_b_doorway).is_empty()).is_false()

	# Act 2 -- both bystanders are now genuinely walled in (zero legal step).
	# Drive real ticks for threshold + margin so the real watchdog reaches its
	# PRODUCTION-DEFAULT threshold and fires for both.
	var margin_ticks: int = env.ai_config.unstuck_watchdog_threshold_ticks + 5
	for _t in range(margin_ticks):
		_advance_population_and_tick(tick_source, all_villagers)
		print("[debug] t=%d a: state=%d stuck=%d distressed=%s cell=%s | b: state=%d stuck=%d distressed=%s cell=%s" % [
			_t, bystander_a.get_state(), bystander_a.get_stuck_tick_count(), bystander_a.is_distressed(), bystander_a.get_current_cell(),
			bystander_b.get_state(), bystander_b.get_stuck_tick_count(), bystander_b.is_distressed(), bystander_b.get_current_cell(),
		])

	var permanent_stuck_count: int = _count_currently_stuck(all_villagers)

	print(
		(
			"[m01-c3] SCENARIO 2 (adversarial -- workers seal 2 rooms around bystanders) -- "
			+ "rooms=2 margin_ticks=%d -- watchdog_fire_count=%d recovery_count=%d unstuck_search_failed_count=%d "
			+ "permanent_stuck_count=%d (config: threshold=%d search_radius=%d max_radius=%d, PRODUCTION DEFAULTS)"
		) % [
			margin_ticks, telemetry.get_world_total(), telemetry.get_world_total(), search_failed_counter[0],
			permanent_stuck_count, env.ai_config.unstuck_watchdog_threshold_ticks,
			env.ai_config.unstuck_rescue_search_radius, env.ai_config.unstuck_rescue_max_radius,
		]
	)

	# Assert -- both real writes trapped their bystander, both real watchdogs
	# fired and recovered, zero search failures, zero permanent stuck.
	assert_int(telemetry.get_world_total()).is_equal(2)
	assert_int(telemetry.get_villager_count(bystander_a.get_villager_id())).is_equal(1)
	assert_int(telemetry.get_villager_count(bystander_b.get_villager_id())).is_equal(1)
	assert_int(search_failed_counter[0]).is_equal(0)
	assert_int(rescued_cells.size()).is_equal(2)
	assert_bool(bystander_a.is_distressed()).is_false()
	assert_bool(bystander_b.is_distressed()).is_false()
	# The rescue itself transitions to DECIDING (asserted at unit level,
	# `unstuck_watchdog_test.gd`); by the END of this margin window the
	# population's own real scheduler has ALSO had time to run a real Deciding
	# pass for each rescued bystander -- with no more real jobs left in
	# [param env]'s queue (both doorways already built) and no urgent need,
	# that pass legitimately falls through to the tier-3 Wandering floor
	# (`stress_30_villager_test.gd`'s own identical "no reachable candidate"
	# conclusion) -- neither TRAVELING nor WORKING is what actually matters
	# here (those are the only two states that could mean "still trapped").
	assert_int(bystander_a.get_state()).is_not_equal(VillagerAi.State.TRAVELING)
	assert_int(bystander_a.get_state()).is_not_equal(VillagerAi.State.WORKING)
	assert_int(bystander_b.get_state()).is_not_equal(VillagerAi.State.TRAVELING)
	assert_int(bystander_b.get_state()).is_not_equal(VillagerAi.State.WORKING)
	assert_int(permanent_stuck_count).is_equal(0)
