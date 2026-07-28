## Integration test — Villager AI story villager-ai-016 (Seal prevention
## negative-write gate & livelock escape, GDD Rule 16/F6, ADR-0009 slice
## propagation Sec.2b). Sprint 8 QA plan Call-out 1's own addition: the
## anti-stuck chain's real-write seal-prevention test — this sprint's
## headline gate for M01 criterion #7's literal "without getting stuck"
## promise.
##
## Uses REAL Building System components throughout, no mocked queue, no
## mocked `would_trap_builder` predicate standing in for the real write call
## site — mirrors `build_job_cycle_test.gd`'s own established "real
## [VoxelWorldGrid]/[ConstructionTickLoop]/[ConstructionJobQueue], hand-poked
## claim/position for an isolated on-site-gate-composition fixture" precedent
## (that file's own AC12/AC33 tests), extended here with the new
## [VillagerSealPreventionGate] wired alongside [VillagerOnSiteGate] behind
## [ConstructionTickLoop]'s two independent predicate seams.
##
## - AC54: a trapped BUILD completion is refused against the REAL
##   [method VoxelWorldGrid.bulk_write] call site — the cell never actually
##   writes, the claim releases back to the REAL [ConstructionJobQueue], and
##   a different villager, approaching from a non-trapping position, claims
##   and completes it for real.
## - AC55: a DIG/DEMOLISH-typed completion proceeds unconditionally through
##   the SAME real write call site, even when trapped.
## - AC56: after `seal_prevention_abandon_limit` real refusals of the SAME
##   (job, villager) pair, the next real attempt writes unconditionally.
## - A fully real claim -> F2 selection -> AStar3D travel -> on-site ->
##   completion run (mirrors `build_job_cycle_test.gd`'s own AC40 crown)
##   proves the self-seal exception (ADR-0009's "one deliberate exception")
##   fires correctly for NORMAL construction — the ordinary case where a
##   villager ends up standing exactly on its own job cell — and that normal
##   gameplay is completely unaffected by wiring this new gate in.
class_name SealPreventionRealBuildWriteTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures (helpers ABOVE every test function, this codebase's own
# convention)
# ---------------------------------------------------------------------------

## The real Building-System half of one test's environment — a grid, a REAL
## [ConstructionTickLoop], a REAL [ConstructionJobQueue], the established
## [VillagerOnSiteGate] (Rule 5), AND this story's new
## [VillagerSealPreventionGate] (Rule 16/F6), both wired behind
## [ConstructionTickLoop]'s two independent predicate seams.
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


## A flat, fully-connected NxN standable platform at y=0 (mirrors
## `build_job_cycle_test.gd`'s own established fixture) — villagers occupy
## y=1.
func _fill_flat_platform(grid: VoxelWorldGrid, size: int) -> void:
	for x in range(size):
		for z in range(size):
			grid.set_cell(Vector3i(x, 0, z), _solid())


## Builds a 1-cell sealed-room fixture on top of an already-flat platform
## (GDD F6's own worked example): walls at y=1 on three sides of
## [param room_interior]; the fourth side ([param doorway]) stays empty —
## the only legal exit, and this test's own target job cell. A ceiling plate
## one cell above [constant VillagerAi.VILLAGER_CLEARANCE]'s own clearance
## span (see `seal_prevention_test.gd`'s own `_make_sealed_room_grid` doc
## comment for why this is load-bearing, not decorative: without it,
## [constant VillagerAi.MAX_STEP_HEIGHT] = 1 lets a villager simply step UP
## onto the top of a single newly-solid wall/doorway cell in an otherwise
## vertically-open world).
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


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


func _released_project(id: int, cells: Array[Vector3i]) -> BuildProject:
	var project := BuildProject.new(id)
	for cell: Vector3i in cells:
		project.add_cell(_planned_cell(cell))
	project.release()
	return project


func _make_environment(
	tick_source: Object, platform_size: int, loop_config: ConstructionTickLoopConfig = null
) -> _Environment:
	var env := _Environment.new()
	env.grid = _new_grid()
	_fill_flat_platform(env.grid, platform_size)
	env.loop = auto_free(ConstructionTickLoop.new())
	env.loop.voxel_world = env.grid
	env.loop_config = loop_config if loop_config != null else ConstructionTickLoopConfig.new()
	env.loop.config = env.loop_config
	env.loop.time_tick_system = tick_source
	env.loop.setup()
	env.queue = ConstructionJobQueue.new(env.loop)
	env.onsite_gate = VillagerOnSiteGate.new(env.queue)
	env.ai_config = VillagerAIConfig.new()
	env.seal_gate = VillagerSealPreventionGate.new(env.queue, env.ai_config)
	return env


## A bare, tick-independent [VillagerAi] — hand-poked position/claim (this
## codebase's own established isolated-fixture convention,
## `build_job_cycle_test.gd`'s own `_make_bare_villager`).
func _make_bare_villager(grid: VoxelWorldGrid, villager_id: int) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.voxel_world = grid
	villager.villager_id = villager_id
	return villager


func _place(villager: VillagerAi, cell: Vector3i) -> void:
	villager.current_cell = cell
	villager._from_cell = cell
	villager._to_cell = cell


## Directly claims [param target] for [param villager_id] against the REAL
## queue and hand-pokes [param villager]'s own claim bookkeeping to match
## (mirrors `build_job_cycle_test.gd`'s own `_claim_directly` exactly, widened
## with an explicit [param job_type]).
func _claim_directly(
	env: _Environment,
	project: BuildProject,
	target: Vector3i,
	villager: VillagerAi,
	job_type: ConstructionTickLoop.JobType = ConstructionTickLoop.JobType.BUILD
) -> void:
	assert_bool(env.queue.claim_job(target, villager.villager_id, job_type)).is_true()
	villager.job_queue = env.queue
	villager._claimed_blueprint_cell = project.cells[target]
	villager._pursued_activity = VillagerAi.PursuedActivity.WORK
	villager._state = VillagerAi.State.WORKING
	env.onsite_gate.register_villager(villager)
	env.seal_gate.register_villager(villager)


func _fire_full_build_cycle(tick_source: MockTimeTickSystem, env: _Environment) -> void:
	for _i in range(env.loop_config.base_build_ticks_block):
		tick_source.fire_tick()


# ---------------------------------------------------------------------------
# AC54 — trapped BUILD completion refused against the REAL write call site
# ---------------------------------------------------------------------------

func test_ac54_real_write_refused_when_trapped_claim_requeued_reclaimable_by_another_villager() -> void:
	# Arrange — a 1-cell sealed room; the worker stands INSIDE, on-site
	# (orthogonally adjacent, Rule 5) to the doorway job it is building, not
	# standing ON it — so completing the doorway genuinely traps the worker
	# without hitting the self-seal exception.
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var env := _make_environment(tick_source, 8, loop_config)
	var interior := Vector3i(3, 1, 3)
	var doorway := Vector3i(2, 1, 3)
	_wall_off_room(env.grid, interior, doorway)
	var project: BuildProject = _released_project(1, [doorway])
	env.queue.add_project(project)

	var worker: VillagerAi = _make_bare_villager(env.grid, 1)
	_claim_directly(env, project, doorway, worker)
	_place(worker, interior)

	# Act
	_fire_full_build_cycle(tick_source, env)

	# Assert — refused: the REAL bulk_write never landed, the cell stays
	# empty, the claim released back to the REAL queue.
	assert_int(project.cells[doorway].state).is_equal(BlueprintCell.MicroState.PLANNED)
	assert_bool(env.grid.get_cell(doorway).is_empty()).is_true()
	assert_bool(env.queue.has_claim(1)).is_false()
	assert_int(env.seal_gate.get_abandon_count(doorway)).is_equal(1)

	# A different villager, approaching from OUTSIDE the sealed room (its own
	# current_cell is unaffected by the doorway becoming solid), claims and
	# completes the SAME real job.
	var outside_worker: VillagerAi = _make_bare_villager(env.grid, 2)
	_claim_directly(env, project, doorway, outside_worker)
	_place(outside_worker, Vector3i(0, 1, 0))
	_fire_full_build_cycle(tick_source, env)
	assert_int(project.cells[doorway].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(doorway).is_empty()).is_false()


# ---------------------------------------------------------------------------
# AC55 — dig/demolition completions proceed unconditionally through the SAME
# real write call site, even when trapped
# ---------------------------------------------------------------------------

func test_ac55_real_write_dig_job_type_proceeds_unconditionally_even_when_trapped() -> void:
	# Arrange — identical trapping geometry to AC54, but claimed as a DIG job.
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var env := _make_environment(tick_source, 8, loop_config)
	var interior := Vector3i(3, 1, 3)
	var doorway := Vector3i(2, 1, 3)
	_wall_off_room(env.grid, interior, doorway)
	var project: BuildProject = _released_project(1, [doorway])
	env.queue.add_project(project)

	var worker: VillagerAi = _make_bare_villager(env.grid, 1)
	_claim_directly(env, project, doorway, worker, ConstructionTickLoop.JobType.DIG)
	_place(worker, interior)

	# Act
	_fire_full_build_cycle(tick_source, env)

	# Assert — the REAL write proceeds unconditionally despite the trap.
	assert_int(project.cells[doorway].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(doorway).is_empty()).is_false()
	assert_int(env.seal_gate.get_abandon_count(doorway)).is_equal(0)


func test_ac55_real_write_demolish_job_type_proceeds_unconditionally_even_when_trapped() -> void:
	# Arrange — identical trapping geometry to AC54, but claimed as a
	# DEMOLISH job (ADR-0016 makes demolition job-based and uniform with
	# construction — the SAME real ConstructionTickLoop/ConstructionJobQueue
	# write call site AC54 exercises, cross-checked here with the other
	# exempt job_type value; no dedicated dig/demolition project ENTITY has
	# landed yet in this codebase — see this story's own Dependencies — so
	# `job_type` is supplied directly at the real [method
	# ConstructionJobQueue.claim_job] call site, the actual seam a future
	# dig-project story will drive for real).
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var env := _make_environment(tick_source, 8, loop_config)
	var interior := Vector3i(3, 1, 3)
	var doorway := Vector3i(2, 1, 3)
	_wall_off_room(env.grid, interior, doorway)
	var project: BuildProject = _released_project(1, [doorway])
	env.queue.add_project(project)

	var worker: VillagerAi = _make_bare_villager(env.grid, 1)
	_claim_directly(env, project, doorway, worker, ConstructionTickLoop.JobType.DEMOLISH)
	_place(worker, interior)

	# Act
	_fire_full_build_cycle(tick_source, env)

	# Assert
	assert_int(project.cells[doorway].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(doorway).is_empty()).is_false()
	assert_int(env.seal_gate.get_abandon_count(doorway)).is_equal(0)


# ---------------------------------------------------------------------------
# AC56 — livelock escape against the real write call site
# ---------------------------------------------------------------------------

func test_ac56_real_write_proceeds_after_abandon_limit_reached() -> void:
	# Arrange
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var env := _make_environment(tick_source, 8, loop_config)
	var interior := Vector3i(3, 1, 3)
	var doorway := Vector3i(2, 1, 3)
	_wall_off_room(env.grid, interior, doorway)
	var project: BuildProject = _released_project(1, [doorway])
	env.queue.add_project(project)
	var worker: VillagerAi = _make_bare_villager(env.grid, 1)
	env.onsite_gate.register_villager(worker)
	env.seal_gate.register_villager(worker)
	_place(worker, interior)
	var limit: int = env.ai_config.seal_prevention_abandon_limit

	# Act — refused `limit` times, the SAME villager re-claiming each time
	# (mirrors GDD F6's own worked example: "the same villager, being
	# nearest, re-claims").
	for i in range(limit):
		assert_bool(env.queue.claim_job(doorway, 1)).is_true()
		_fire_full_build_cycle(tick_source, env)
		assert_int(project.cells[doorway].state).is_equal(BlueprintCell.MicroState.PLANNED)
		assert_int(env.seal_gate.get_abandon_count(doorway)).is_equal(i + 1)

	# Assert — the (limit + 1)-th real attempt writes unconditionally.
	assert_bool(env.queue.claim_job(doorway, 1)).is_true()
	_fire_full_build_cycle(tick_source, env)
	assert_int(project.cells[doorway].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(doorway).is_empty()).is_false()
	assert_int(env.seal_gate.get_abandon_count(doorway)).is_equal(limit)


# ---------------------------------------------------------------------------
# Self-seal exception — the fully real claim -> F2 -> travel -> on-site ->
# completion cycle, proving normal construction is unaffected
# ---------------------------------------------------------------------------

func test_self_seal_real_end_to_end_claim_travel_onsite_completion_proceeds_unconditionally() -> void:
	# Arrange — mirrors `build_job_cycle_test.gd`'s own AC40 crown assembly
	# exactly, with both gates wired: real F2 selection, real AStar3D travel,
	# real on-site crediting, real completion write.
	var tick_source: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var env := _make_environment(tick_source, 5, loop_config)
	var target := Vector3i(4, 1, 0)
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)

	var predicate_source: VillagerAi = _make_bare_villager(env.grid, -1)
	var nav_graph := VillagerNavGraph.new()
	nav_graph.subscribe_to_voxel_world(env.grid, predicate_source)
	nav_graph.build(env.grid, predicate_source, Vector3i(2, 1, 2), 5)
	var scheduler := VillagerDecidingScheduler.new()

	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.config = env.ai_config
	villager.voxel_world = env.grid
	villager.scheduler = scheduler
	villager.nav_graph = nav_graph
	villager.time_tick_system = tick_source
	villager.job_queue = env.queue
	villager.villager_id = 1
	villager.setup()
	env.onsite_gate.register_villager(villager)
	env.seal_gate.register_villager(villager)
	_place(villager, Vector3i(0, 1, 0))

	# Act — claim (real F2 + real atomic claim), travel (real AStar3D), work
	# (real on-site crediting), completion (real bulk_write) — the villager
	# ends up standing EXACTLY on its own job cell throughout, this
	# codebase's own established normal-case behavior.
	tick_source.fire_tick()
	var ticks_elapsed: int = 0
	while villager.get_current_cell() != target and ticks_elapsed < 20:
		villager.advance_travel_progress(1000.0)
		tick_source.fire_tick()
		ticks_elapsed += 1
	assert_vector(Vector3(villager.get_current_cell())).is_equal(Vector3(target))

	var completion_ticks: int = 0
	while project.cells[target].state != BlueprintCell.MicroState.BUILT and completion_ticks < 20:
		tick_source.fire_tick()
		completion_ticks += 1

	# Assert — the self-seal exception let this ordinary completion proceed
	# unconditionally; never refused, never counted.
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(target).is_empty()).is_false()
	assert_int(env.seal_gate.get_abandon_count(target)).is_equal(0)
