## Integration test — Villager AI Story villager-ai-012 (On-site work & full
## claim->build->report cycle — THE CROWN of Sprint 7, Milestone 01
## criterion #2 full-depth integration). ADR-0016 primary, ADR-0009
## secondary.
##
## Uses REAL Building System components throughout — no mocked queue, no
## mocked project entity (Sprint 7 QA plan's own bar for this file): real
## [VoxelWorldGrid], [BuildProject]/[BlueprintCell], [ConstructionTickLoop],
## [ConstructionJobQueue], and the new [VillagerOnSiteGate] this story adds
## to wire Rule 5's on-site gate (GDD [TR-villager-ai-behavior-054]) for the
## first time — only the tick source is a test double ([MockTimeTickSystem],
## reused from `mock_time_tick_system.gd`, this codebase's own established
## precedent).
##
## **Wiring-order discipline** (load-bearing throughout this file, see
## [VillagerAi]'s own `_tick_working` doc comment): [ConstructionTickLoop]
## connects to the shared tick source BEFORE any [VillagerAi] — [method
## _make_environment]/[method _make_full_villager] enforce this ordering so
## AC13's never-partial-credit guarantee holds in every test below.
##
## Each acceptance criterion is its own independently-diagnosable test
## function (Sprint 7 QA plan discipline, mirrors Sprint 6's scene-004 crown)
## — a half-failure reads as a distinct red, never folded into one pass/fail
## line:
## - AC12 (on-site gate): off-site accrues zero progress; on-site accrues.
## - AC13 (tick-boundary rule): arrival between ticks credits the first
##   increment at the NEXT tick boundary, never partially.
## - AC40 (the full cycle, closes Building AC21): claim -> travel -> ticks ->
##   Built -> queue no longer offers it -> villager re-enters Deciding.
## - AC40b (closes Building AC36b): occupied target defers construction even
##   while the assigned worker is genuinely on-site; resumes once the
##   occupant vacates, WITHOUT re-claiming (same claim throughout).
## - AC33 (Edge Case 4): a job revoked mid-work stops cleanly, no failure
##   reaction, re-enters Deciding without error.
## - Three named race/ordering assertions (Sprint 7 QA plan Smoke Scope item
##   3, not named in any individual story's own Test Evidence): deterministic
##   winner + clean loser re-decide against the REAL queue; claim released on
##   abandon genuinely re-offered by the REAL queue; completion reported
##   exactly once under a multi-tick burst.
##
## building-005's `worker_ids` attribution field has now landed
## (`BuildProject.on_job_claimed`/`BuildProject.worker_ids`) — per Sprint 7
## QA plan Call-out 3's recommendation, [method
## test_ac40_full_claim_travel_build_report_cycle_real_components] asserts
## the claiming villager's id appears in the real project's `worker_ids`
## after the real claim, closing building-005's PROVISIONAL tag alongside
## AC40 at negligible extra cost (dedicated coverage otherwise lives in
## `tests/integration/building_system/worker_attribution_test.gd`).
class_name BuildJobCycleTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures (helpers ABOVE every test function, per this codebase's own
# convention)
# ---------------------------------------------------------------------------

## The real Building-System half of one test's environment — a grid, a
## REAL [ConstructionTickLoop], a REAL [ConstructionJobQueue], and the
## [VillagerOnSiteGate] this story adds to wire Rule 5 for real.
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


## A flat, fully-connected NxN standable platform at y=0 (mirrors
## `traveling_repath_test.gd`'s own established fixture) — villagers occupy
## y=1.
func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), CellContents.new(1, 0))


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


## A DRAFT project with [param cells] added and immediately released
## (BUILDING, every cell job-eligible) -- mirrors
## `construction_job_queue_test.gd`'s own established helper shape.
func _released_project(id: int, cells: Array[Vector3i]) -> BuildProject:
	var project := BuildProject.new(id)
	for cell: Vector3i in cells:
		project.add_cell(_planned_cell(cell))
	project.release()
	return project


## Builds one test's full Building-System-side environment, wired in the
## load-bearing order AC13's never-partial-credit guarantee depends on: the
## tick loop connects to [param tick_source] BEFORE any villager does (see
## [VillagerAi]'s own `_tick_working` doc comment; [VillagerOnSiteGate]'s own
## doc comment point about connection ordering).
func _make_environment(
	tick_source: Object, platform_size: int, loop_config: ConstructionTickLoopConfig = null
) -> _Environment:
	var env := _Environment.new()
	env.grid = _new_grid()
	_fill_flat_platform(env.grid, platform_size)
	env.loop = auto_free(ConstructionTickLoop.new())
	env.loop.voxel_world = env.grid
	env.loop.config = loop_config if loop_config != null else ConstructionTickLoopConfig.new()
	env.loop.time_tick_system = tick_source
	env.loop.setup()
	env.queue = ConstructionJobQueue.new(env.loop)
	env.gate = VillagerOnSiteGate.new(env.queue)
	return env


## A bare, tick-independent [VillagerAi] -- used as a nav-graph predicate
## source, an isolated-fixture claim holder (state hand-poked directly, this
## codebase's own established convention -- `job_claim_attribution_test.gd`'s
## own `_make_bare_villager_ai`/direct `_pursued_activity` pokes), or an
## occupant stand-in (AC40b). Never itself connected to any tick signal.
func _make_bare_villager(grid: VoxelWorldGrid, villager_id: int) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.voxel_world = grid
	villager.villager_id = villager_id
	return villager


## A fully wired, real [VillagerAi] -- `setup()`-ed and registered with
## [param env]'s [VillagerOnSiteGate] -- connected to [param tick_source]
## AFTER [param env]'s own [ConstructionTickLoop] (see [method
## _make_environment]'s own doc comment for why that order is load-bearing).
func _make_full_villager(
	env: _Environment,
	nav_graph: VillagerNavGraph,
	scheduler: VillagerDecidingScheduler,
	tick_source: Object,
	villager_id: int,
) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = VillagerAIConfig.new()
	villager.voxel_world = env.grid
	villager.scheduler = scheduler
	villager.nav_graph = nav_graph
	villager.time_tick_system = tick_source
	villager.job_queue = env.queue
	villager.villager_id = villager_id
	villager.setup()
	env.gate.register_villager(villager)
	return villager


func _place(villager: VillagerAi, cell: Vector3i) -> void:
	villager.current_cell = cell
	villager._from_cell = cell
	villager._to_cell = cell


## Directly claims [param target] for [param villager_id] against the REAL
## queue and hand-pokes [param villager]'s own claim bookkeeping to match
## (this codebase's established "poke private fields for an isolated
## fixture" convention) -- used by tests whose own focus is the on-site
## gate/occupied-defer/revocation behavior, not F2 selection or travel.
func _claim_directly(env: _Environment, project: BuildProject, target: Vector3i, villager: VillagerAi) -> void:
	assert_bool(env.queue.claim_job(target, villager.villager_id)).is_true()
	villager.job_queue = env.queue
	villager._claimed_blueprint_cell = project.cells[target]
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	villager._state = VillagerAi.State.WORKING
	env.gate.register_villager(villager)


# ---------------------------------------------------------------------------
# AC12 — off-site accrues zero progress; on-site accrues
# ---------------------------------------------------------------------------

func test_ac12_off_site_zero_progress_on_site_progress_accrues() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 5)
	var target := Vector3i(2, 1, 2)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	var villager: VillagerAi = _make_bare_villager(env.grid, 1)
	_claim_directly(env, project, target, villager)

	# Off-site -- two cells away, not even orthogonally adjacent.
	_place(villager, target + Vector3i(2, 0, 0))
	for _i in range(3):
		tick_source.fire_tick()
	assert_int(env.loop.get_progress_ticks(target)).is_equal(0)
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)

	# On-site -- standing exactly on the target cell.
	_place(villager, target)
	tick_source.fire_tick()
	assert_int(env.loop.get_progress_ticks(target)).is_equal(1)


func test_ac12_orthogonally_adjacent_including_above_below_counts_as_on_site() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 5)
	var target := Vector3i(2, 1, 2)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	var villager: VillagerAi = _make_bare_villager(env.grid, 1)
	_claim_directly(env, project, target, villager)

	# Directly above the target cell -- still on-site per Rule 5.
	_place(villager, target + Vector3i(0, 1, 0))
	tick_source.fire_tick()
	assert_int(env.loop.get_progress_ticks(target)).is_equal(1)


# ---------------------------------------------------------------------------
# AC13 — arrival between ticks credits the first increment at the NEXT tick
# boundary, never partially
# ---------------------------------------------------------------------------

func test_ac13_arrival_between_ticks_credits_first_increment_at_next_boundary_never_partial() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 5)
	# A pure-diagonal target: AStar3D's shortest path here is 4 diagonal
	# steps (cost ~5.66) vs. any orthogonal detour (cost 8.0), so EVERY cell
	# along the route -- including the second-to-last -- differs from the
	# target on BOTH the x and z axes until the exact final step. Rule 5's
	# on-site predicate explicitly excludes a diagonal difference, so
	# on-site becomes true only at the tick current_cell first equals
	# target -- unlike a straight orthogonal approach, whose
	# second-to-last cell is already orthogonally adjacent (on-site) one
	# tick early. This isolates AC13's own claim (never partial, never
	# same-tick) from Rule 5's separate on-site geometry.
	var target := Vector3i(4, 1, 4)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	var predicate_source: VillagerAi = _make_bare_villager(env.grid, -1)
	var nav_graph := VillagerNavGraph.new()
	nav_graph.subscribe_to_voxel_world(env.grid, predicate_source)
	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = _make_full_villager(env, nav_graph, scheduler, tick_source, 1)
	nav_graph.build(env.grid, predicate_source, Vector3i(2, 1, 2), 5)
	_place(villager, Vector3i(0, 1, 0))

	# Real Deciding pass -- claims + begins traveling toward the real job.
	tick_source.fire_tick()
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)

	# Drive travel to the exact tick of arrival.
	var ticks_elapsed: int = 0
	while villager.get_current_cell() != target and ticks_elapsed < 20:
		villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()
		ticks_elapsed += 1

	# The villager just arrived THIS tick boundary -- because
	# ConstructionTickLoop connected to the shared tick source FIRST, its own
	# crediting pass THIS tick already ran (and saw the villager still
	# off-site, as of the START of this tick) before the villager's own
	# arrival-crediting assignment ran -- zero progress, never partial.
	assert_vector(Vector3(villager.get_current_cell())).is_equal(Vector3(target))
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WORKING)
	assert_int(env.loop.get_progress_ticks(target)).is_equal(0)

	# The NEXT tick boundary credits the first (and only the first) increment.
	tick_source.fire_tick()
	assert_int(env.loop.get_progress_ticks(target)).is_equal(1)


# ---------------------------------------------------------------------------
# AC40 — THE full claim -> travel -> build -> report cycle (closes Building
# AC21)
# ---------------------------------------------------------------------------

func test_ac40_full_claim_travel_build_report_cycle_real_components() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var env := _make_environment(tick_source, 5, loop_config)
	var target := Vector3i(4, 1, 0)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	var predicate_source: VillagerAi = _make_bare_villager(env.grid, -1)
	var nav_graph := VillagerNavGraph.new()
	nav_graph.subscribe_to_voxel_world(env.grid, predicate_source)
	var scheduler := VillagerDecidingScheduler.new()
	var villager: VillagerAi = _make_full_villager(env, nav_graph, scheduler, tick_source, 1)
	nav_graph.build(env.grid, predicate_source, Vector3i(2, 1, 2), 5)
	_place(villager, Vector3i(0, 1, 0))
	assert_bool(scheduler.is_queued(villager.villager_id)).is_true()

	# Stage 1 -- claim: real F2 selection (010) + real atomic claim (011)
	# against the REAL ConstructionJobQueue.
	tick_source.fire_tick()
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
	assert_bool(env.queue.has_claim(1)).is_true()
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_int(villager.get_state()).is_equal(VillagerAi.State.TRAVELING)
	# building-005 (Sprint 7 QA plan Call-out 3): the real claim above already
	# recorded worker attribution as its own side effect -- closes
	# building-005's PROVISIONAL tag against a REAL claim, not just the
	# mocked-claim proof in worker_attribution_test.gd.
	assert_bool(project.worker_ids.has(1)).is_true()
	assert_int(project.cells[target].claimed_by_villager_id).is_equal(1)

	# Stage 2 -- travel: real AStar3D path (007), cell-by-cell (008/009), to
	# `current_cell` arrival.
	var ticks_elapsed: int = 0
	while villager.get_current_cell() != target and ticks_elapsed < 20:
		villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()
		ticks_elapsed += 1
	assert_vector(Vector3(villager.get_current_cell())).is_equal(Vector3(target))
	assert_int(villager.get_state()).is_equal(VillagerAi.State.WORKING)

	# Stage 3/4 -- tick-boundary progress while genuinely on-site (Rule 5)
	# through to the Built-state write (the REAL ConstructionTickLoop
	# completion, a real Voxel World cell mutation). Credit may begin as
	# early as the tick the villager first reads on-site (Rule 5 counts an
	# orthogonally-adjacent cell, not only the exact target cell, so a
	# straight orthogonal approach like this one becomes on-site one tick
	# before `current_cell` literally equals `target` -- AC13's own test
	# isolates and proves the never-partial/next-boundary claim precisely;
	# this stage only bounds the wait to completion, never hardcoding a
	# tick count tied to path geometry).
	var completion_ticks: int = 0
	while project.cells[target].state != BlueprintCell.MicroState.BUILT and completion_ticks < 20:
		tick_source.fire_tick()
		completion_ticks += 1
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(target).is_empty()).is_false()

	# Stage 5 -- the job is removed from the REAL queue.
	assert_bool(env.queue.has_available_job()).is_false()
	var still_offered: bool = false
	for job: BlueprintCell in env.queue.get_available_jobs():
		if job.cell == target:
			still_offered = true
	assert_bool(still_offered).is_false()

	# Stage 6 -- the villager re-enters the decision loop (its own
	# `_tick_working` detects BUILT the SAME tick the completion write
	# landed, since VillagerAi connects to the shared tick source AFTER
	# ConstructionTickLoop). The exact terminal FSM snapshot depends on
	# whether Rule 2's own periodic `decision_interval` re-check (Story
	# villager-ai-006, unrelated to this story) ALSO happens to land on
	# this same tick: if it does, the villager's own `was_deciding` guard
	# runs a second real Deciding pass within the same tick and -- correctly,
	# since no other job exists yet -- falls straight through to Wandering
	# rather than idling in Deciding. Either outcome proves the closed loop
	# (claim released, no longer pursuing this job, re-decided) -- the
	# state-independent facts below are this stage's real assertions.
	var re_decided: bool = (
		villager.get_state() == VillagerAi.State.DECIDING
		or villager.get_state() == VillagerAi.State.WANDERING
	)
	assert_bool(re_decided).is_true()
	assert_int(villager.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_bool(env.queue.has_claim(1)).is_false()
	assert_bool(villager.get_claimed_job_cell() == null).is_true()


# ---------------------------------------------------------------------------
# AC40b — occupied target deferred, resumes after the occupant vacates,
# WITHOUT re-claiming (closes Building AC36b)
# ---------------------------------------------------------------------------

func test_ac40b_occupied_target_deferred_resumes_after_vacate_without_reclaim() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var env := _make_environment(tick_source, 5, loop_config)
	var target := Vector3i(2, 1, 2)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	# The assigned worker -- already ON-SITE (standing exactly on the target
	# cell), claim already held (isolated fixture -- this test's own focus is
	# the occupied-cell defer/resume behavior, not F2/travel).
	var worker: VillagerAi = _make_bare_villager(env.grid, 1)
	_claim_directly(env, project, target, worker)
	_place(worker, target)

	# An occupant standing exactly on the SAME target cell -- blocks
	# construction (Building System Edge Case 6/AC36) even though the
	# assigned worker itself IS on-site.
	var occupant: VillagerAi = _make_bare_villager(env.grid, 2)
	_place(occupant, target)
	env.gate.register_villager(occupant)

	tick_source.fire_tick()
	assert_int(env.loop.get_progress_ticks(target)).is_equal(0)
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)

	# The occupant vacates (F4's own vacate-step mechanics are Story
	# villager-ai-013's scope, out of this story -- this test asserts only
	# the RESUME behavior once the target cell reads clear again).
	_place(occupant, Vector3i(9, 1, 9))

	for _i in range(loop_config.base_build_ticks_block):
		tick_source.fire_tick()

	# Resumed WITHOUT re-claiming -- the SAME single claim throughout (never
	# claim -> release -> re-claim).
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.queue.has_claim(1)).is_true()


# ---------------------------------------------------------------------------
# AC33 — job revoked mid-work: stops cleanly, no failure reaction,
# re-enters Deciding without error (Edge Case 4)
# ---------------------------------------------------------------------------

func test_ac33_job_revoked_mid_work_stops_cleanly_redecides_no_error() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 5)
	var target := Vector3i(2, 1, 2)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	var worker: VillagerAi = _make_bare_villager(env.grid, 1)
	worker.scheduler = VillagerDecidingScheduler.new()
	_claim_directly(env, project, target, worker)
	_place(worker, target)

	tick_source.fire_tick()
	assert_int(env.loop.get_progress_ticks(target)).is_equal(1)

	# External revocation (player undo/removal) -- the SAME primitive a
	# Building-System-side revoke/pause action would call (ADR-0016: "graceful
	# claim revoke"). Clears bookkeeping itself, per this story's own
	# Implementation Notes.
	env.queue.release_claim(1)
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.PLANNED)

	# The villager notices at the tick boundary and re-enters Deciding — no
	# failure reaction, no error.
	worker._tick_working()

	assert_int(worker.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_int(worker.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)
	assert_bool(worker.get_claimed_job_cell() == null).is_true()
	assert_bool(project.cells[target].is_unreachable).is_false()
	assert_bool(worker.scheduler.is_queued(worker.villager_id)).is_true()


# ---------------------------------------------------------------------------
# Race/ordering assertions (Sprint 7 QA plan Smoke Scope item 3) — named
# explicitly, re-verified here against the REAL ConstructionJobQueue
# ---------------------------------------------------------------------------

func test_race_deterministic_winner_and_clean_loser_redecide_against_real_queue() -> void:
	# Repeated across several fresh runs to prove determinism, not "usually
	# the same villager" (mirrors job_claim_attribution_test.gd's own
	# established repeated-run discipline for this exact assertion).
	for _run in range(3):
		var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
		var env := _make_environment(tick_source, 5)
		var target := Vector3i(4, 1, 0)
		var project: BuildProject = _released_project(1, [target])
		env.queue.add_project(project)

		var predicate_source: VillagerAi = _make_bare_villager(env.grid, -1)
		var nav_graph := VillagerNavGraph.new()
		nav_graph.subscribe_to_voxel_world(env.grid, predicate_source)
		nav_graph.build(env.grid, predicate_source, Vector3i(2, 1, 2), 5)
		var scheduler := VillagerDecidingScheduler.new()

		var villager0: VillagerAi = _make_full_villager(env, nav_graph, scheduler, tick_source, 0)
		var villager1: VillagerAi = _make_full_villager(env, nav_graph, scheduler, tick_source, 1)
		_place(villager0, Vector3i(0, 1, 0))
		_place(villager1, Vector3i(0, 1, 0))

		# Stable processing order -- villager 0 decides before villager 1,
		# both contending for the SAME real queued job.
		villager0._tick_deciding()
		villager1._tick_deciding()

		# Deterministic winner.
		assert_bool(env.queue.has_claim(0)).is_true()
		assert_int(villager0.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.WORK)
		assert_int(villager0.get_state()).is_equal(VillagerAi.State.TRAVELING)

		# The loser cleanly falls through -- a single-job queue, no second
		# candidate -- never stuck in Deciding, never throws.
		assert_bool(env.queue.has_claim(1)).is_false()
		assert_int(villager1.get_state()).is_equal(VillagerAi.State.WANDERING)
		assert_int(villager1.get_pursued_activity()).is_equal(VillagerAi.PursuedActivity.NONE)


func test_race_claim_released_on_abandon_reoffered_by_real_queue_reclaimable_by_second_villager() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var env := _make_environment(tick_source, 5)
	var target := Vector3i(2, 1, 2)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	assert_bool(env.queue.claim_job(target, 1)).is_true()

	# Abandon (Rule 6 pathing-failure release, or this story's own AC33
	# revocation -- the SAME primitive either way,
	# ConstructionJobQueue.release_claim) -- the load-bearing regression
	# check for villager-ai-009's AC19 (Sprint 6, proven against a mocked
	# queue) now that a REAL queue exists.
	env.queue.release_claim(1)

	assert_bool(env.queue.has_available_job()).is_true()
	assert_bool(env.queue.claim_job(target, 2)).is_true()
	assert_bool(env.queue.has_claim(2)).is_true()
	assert_bool(env.queue.has_claim(1)).is_false()


func test_race_completion_reported_exactly_once_under_multi_tick_burst() -> void:
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var env := _make_environment(tick_source, 5, loop_config)
	var target := Vector3i(2, 1, 2)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	var worker: VillagerAi = _make_bare_villager(env.grid, 1)
	worker.scheduler = VillagerDecidingScheduler.new()
	_claim_directly(env, project, target, worker)
	_place(worker, target)

	var cell_changed_count: Array = [0]
	var batch_count: Array = [0]
	env.grid.cell_changed.connect(
		func(_cell: Vector3i, _before: CellContents, _after: CellContents) -> void:
			cell_changed_count[0] += 1
	)
	env.grid.cells_changed_batch.connect(
		func(_changes: Array[CellChangeRecord]) -> void:
			batch_count[0] += 1
	)

	# A burst well past the completion threshold in ONE go (building-029's
	# own AC25/AC45 burst rule) -- no double-credit, no duplicate completion
	# signal, even though the villager's own `_tick_working` keeps observing
	# state every tick of the burst (mirrors production's own per-tick
	# dispatch, restricted to while it is genuinely still WORKING). Story
	# building-033: the completion write now goes through the batched
	# `cells_changed_batch` path, never the single-cell `cell_changed` path.
	for _i in range(loop_config.base_build_ticks_block + 10):
		tick_source.fire_tick()
		if worker.get_state() == VillagerAi.State.WORKING:
			worker._tick_working()

	assert_int(cell_changed_count[0]).is_equal(0)
	assert_int(batch_count[0]).is_equal(1)
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(env.queue.get_available_jobs().size()).is_equal(0)
	# The villager's own completion path ran exactly once too -- re-entering
	# Deciding, claim released, never re-triggered by the burst's remaining
	# ticks.
	assert_int(worker.get_state()).is_equal(VillagerAi.State.DECIDING)
	assert_bool(env.queue.has_claim(1)).is_false()
