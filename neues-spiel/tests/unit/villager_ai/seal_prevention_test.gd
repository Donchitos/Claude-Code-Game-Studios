## Unit test — Villager AI story villager-ai-016 (Seal prevention negative-
## write gate & livelock escape, GDD Rule 16/F6, ADR-0009 slice propagation
## Sec.2b, [TR-villager-ai-behavior-101]/102/106/107) — the LAST story of the
## M01 criterion-#7 anti-stuck ladder (014 rescue-BFS -> 015 watchdog -> 016
## seal-prevention).
##
## Two collaborators under test, both against a MOCKED/hand-poked claim
## rather than a full real F2/travel/attribution production loop (that is
## `seal_prevention_real_build_write_test.gd`'s own job, per this sprint's QA
## plan Call-out 1):
##
## 1. [VillagerAi.would_trap_builder] — pure predicate, no Building System
##    involvement at all (Test Group A).
## 2. [VillagerSealPreventionGate] — the abandon-count bookkeeping, dig/
##    demolition exemption, and livelock-escape threshold, driven against a
##    real (but tiny, hand-poked) [ConstructionTickLoop]/[ConstructionJobQueue]
##    pair so the boundary-value logic is proven against the ACTUAL
##    `_on_tick` completion-check call site, not a re-implemented stand-in
##    (Test Group B).
##
## Covers AC54/AC55/AC56 exactly as the story's own QA Test Cases name them,
## plus the abandon_count reset-on-different-villager and monotonic-bound
## edge cases.
class_name SealPreventionTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test fixtures — Group A (pure would_trap_builder)
# ---------------------------------------------------------------------------

func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _solid() -> CellContents:
	return CellContents.new(1, 0)


## This fixture's fixed cell addresses (all non-negative — [method
## VoxelWorldGrid.is_in_bounds] requires x/z >= 0, GDD/ADR-0015's own world
## origin convention).
const _INTERIOR := Vector3i(5, 1, 5)
const _DOORWAY := Vector3i(4, 1, 5)


## A tiny sealed-room fixture (GDD F6's own worked example: "a 1x1 room whose
## only doorway was sealed"): floor solid under every relevant cell; walls
## solid at y=1 on three sides of the villager's standing cell ([constant
## _INTERIOR]); the fourth side ([constant _DOORWAY]) is the open doorway —
## still empty, still standable — the only legal exit before it gets written.
## A ceiling plate at y=4 (one cell above the villager's OWN [constant
## VillagerAi.VILLAGER_CLEARANCE]-tall clearance column, so it never affects
## the villager's own standability) covers the whole room footprint,
## including directly above the doorway -- WITHOUT it, [constant VillagerAi.
## MAX_STEP_HEIGHT] = 1 would let the villager simply step UP onto the top of
## a single newly-built 1-cell-tall wall/doorway segment (a real, correctly-
## implemented Rules 8/9 consequence in an otherwise vertically-open world --
## a lone block never truly traps anyone if you can just climb over it). The
## ceiling is what makes this fixture a genuinely SEALED room, not merely a
## walled one.
func _make_sealed_room_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _make_grid()
	# Floor under the standing cell, the doorway, and one cell beyond it.
	grid.set_cell(Vector3i(5, 0, 5), _solid())
	grid.set_cell(Vector3i(4, 0, 5), _solid())
	grid.set_cell(Vector3i(6, 0, 5), _solid())
	grid.set_cell(Vector3i(5, 0, 6), _solid())
	grid.set_cell(Vector3i(5, 0, 4), _solid())
	# Walls at y=1: east, north, south — the doorway (west) stays empty.
	grid.set_cell(Vector3i(6, 1, 5), _solid())
	grid.set_cell(Vector3i(5, 1, 6), _solid())
	grid.set_cell(Vector3i(5, 1, 4), _solid())
	# Ceiling at y=4 over the room footprint (own cell, all three walls, and
	# the doorway) — denies the "step up and over" escape (see doc comment).
	for x in range(4, 7):
		for z in range(4, 7):
			grid.set_cell(Vector3i(x, 4, z), _solid())
	# A small, unrelated open platform far from the sealed room — a
	# genuinely standable, non-trapped position for a "different villager,
	# unaffected by the doorway write" fixture (never solid above, always at
	# least one legal orthogonal neighbor).
	grid.set_cell(Vector3i(50, 0, 50), _solid())
	grid.set_cell(Vector3i(51, 0, 50), _solid())
	grid.set_cell(Vector3i(49, 0, 50), _solid())
	grid.set_cell(Vector3i(50, 0, 51), _solid())
	return grid


func _make_villager_at(grid: VoxelWorldGrid, cell: Vector3i) -> VillagerAi:
	var villager: VillagerAi = auto_free(VillagerAi.new())
	villager.voxel_world = grid
	villager.current_cell = cell
	return villager


# ---------------------------------------------------------------------------
# AC54 / F6 — would_trap_builder: sealing the only doorway traps
# ---------------------------------------------------------------------------

func test_would_trap_builder_true_when_only_doorway_is_written() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_sealed_room_grid()
	var villager: VillagerAi = _make_villager_at(grid, _INTERIOR)

	# Act
	var trapped: bool = villager.would_trap_builder(_DOORWAY)

	# Assert
	assert_bool(trapped).is_true()


func test_would_trap_builder_false_when_doorway_stays_open() -> void:
	# Arrange — a write far away, unrelated to the villager's only exit.
	var grid: VoxelWorldGrid = _make_sealed_room_grid()
	var villager: VillagerAi = _make_villager_at(grid, _INTERIOR)

	# Act
	var trapped: bool = villager.would_trap_builder(Vector3i(20, 1, 20))

	# Assert
	assert_bool(trapped).is_false()


func test_would_trap_builder_true_when_own_clearance_column_blocked() -> void:
	# Arrange — the doorway stays open, but the write lands directly in the
	# villager's OWN body-column (headroom cell), making current_cell itself
	# non-standable — trapped regardless of any open exit.
	var grid: VoxelWorldGrid = _make_sealed_room_grid()
	var villager: VillagerAi = _make_villager_at(grid, _INTERIOR)

	# Act
	var trapped: bool = villager.would_trap_builder(_INTERIOR + Vector3i(0, 1, 0))

	# Assert
	assert_bool(trapped).is_true()


func test_would_trap_builder_same_input_always_same_output() -> void:
	# Arrange — determinism (mirrors body_column_test.gd's own established
	# discipline).
	var grid: VoxelWorldGrid = _make_sealed_room_grid()
	var villager: VillagerAi = _make_villager_at(grid, _INTERIOR)

	# Act
	var first: bool = villager.would_trap_builder(_DOORWAY)
	var second: bool = villager.would_trap_builder(_DOORWAY)

	# Assert
	assert_bool(first).is_equal(second)


# ---------------------------------------------------------------------------
# Test fixtures — Group B (VillagerSealPreventionGate against a real, tiny
# ConstructionTickLoop/ConstructionJobQueue pair)
# ---------------------------------------------------------------------------

class _Environment:
	var grid: VoxelWorldGrid
	var loop: ConstructionTickLoop
	var loop_config: ConstructionTickLoopConfig
	var queue: ConstructionJobQueue
	var ai_config: VillagerAIConfig
	var gate: VillagerSealPreventionGate
	var tick_source: MockTimeTickSystem


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


func _released_project(id: int, cells: Array[Vector3i]) -> BuildProject:
	var project := BuildProject.new(id)
	for cell: Vector3i in cells:
		project.add_cell(_planned_cell(cell))
	project.release()
	return project


func _make_gate_environment() -> _Environment:
	var env := _Environment.new()
	env.tick_source = auto_free(MockTimeTickSystem.new())
	env.grid = _make_sealed_room_grid()
	env.loop = auto_free(ConstructionTickLoop.new())
	env.loop.voxel_world = env.grid
	env.loop_config = ConstructionTickLoopConfig.new()
	env.loop.config = env.loop_config
	env.loop.time_tick_system = env.tick_source
	env.loop.setup()
	env.queue = ConstructionJobQueue.new(env.loop)
	env.ai_config = VillagerAIConfig.new()
	env.gate = VillagerSealPreventionGate.new(env.queue, env.ai_config)
	return env


func _register_worker(env: _Environment, villager_id: int, cell: Vector3i) -> VillagerAi:
	var worker: VillagerAi = _make_villager_at(env.grid, cell)
	worker.villager_id = villager_id
	env.gate.register_villager(worker)
	return worker


## Fires enough ticks for one full construction pass ([member
## ConstructionTickLoopConfig.base_build_ticks_block]).
func _fire_full_build_cycle(env: _Environment) -> void:
	for _i in range(env.loop_config.base_build_ticks_block):
		env.tick_source.fire_tick()


# ---------------------------------------------------------------------------
# AC54 — trapped BUILD completion refused, claim released, abandon_count++
# ---------------------------------------------------------------------------

func test_ac54_trapped_build_completion_refused_claim_released_abandon_count_increments() -> void:
	# Arrange — the doorway cell is the job; the worker stands INSIDE, where
	# completing the doorway would trap it.
	var env := _make_gate_environment()
	var target := _DOORWAY
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)
	_register_worker(env, 1, _INTERIOR)
	assert_bool(env.queue.claim_job(target, 1)).is_true()

	# Act
	_fire_full_build_cycle(env)

	# Assert — refused: never BUILT, never actually written, claim released.
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.PLANNED)
	assert_bool(env.grid.get_cell(target).is_empty()).is_true()
	assert_bool(env.queue.has_claim(1)).is_false()
	assert_int(env.gate.get_abandon_count(target)).is_equal(1)

	# A different villager, approaching from a non-self-trapping position,
	# may claim and complete the SAME job (AC54's second half).
	var far_worker: VillagerAi = _register_worker(env, 2, Vector3i(50, 1, 50))
	assert_bool(env.queue.claim_job(target, 2)).is_true()
	_fire_full_build_cycle(env)
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(target).is_empty()).is_false()
	assert_object(far_worker).is_not_null()


# ---------------------------------------------------------------------------
# AC55 — dig/demolition completions are never refused for entrapment
# ---------------------------------------------------------------------------

func test_ac55_dig_job_type_completes_unconditionally_even_when_trapped() -> void:
	# Arrange
	var env := _make_gate_environment()
	var target := _DOORWAY
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)
	_register_worker(env, 1, _INTERIOR)
	assert_bool(env.queue.claim_job(target, 1, ConstructionTickLoop.JobType.DIG)).is_true()

	# Act
	_fire_full_build_cycle(env)

	# Assert — proceeds unconditionally, despite the trap.
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(target).is_empty()).is_false()
	assert_int(env.gate.get_abandon_count(target)).is_equal(0)


func test_ac55_demolish_job_type_completes_unconditionally_even_when_trapped() -> void:
	# Arrange
	var env := _make_gate_environment()
	var target := _DOORWAY
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)
	_register_worker(env, 1, _INTERIOR)
	assert_bool(env.queue.claim_job(target, 1, ConstructionTickLoop.JobType.DEMOLISH)).is_true()

	# Act
	_fire_full_build_cycle(env)

	# Assert
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(env.gate.get_abandon_count(target)).is_equal(0)


# ---------------------------------------------------------------------------
# AC56 — livelock escape: after seal_prevention_abandon_limit refusals, the
# next attempt proceeds unconditionally
# ---------------------------------------------------------------------------

func test_ac56_write_proceeds_unconditionally_after_abandon_limit_reached() -> void:
	# Arrange — the SAME (job, villager) pair re-claims and retries after
	# each refusal (this test's own hand-poked re-claim, mirroring GDD F6's
	# worked example: "the same villager, being nearest, re-claims").
	var env := _make_gate_environment()
	var target := _DOORWAY
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)
	_register_worker(env, 1, _INTERIOR)
	var limit: int = env.ai_config.seal_prevention_abandon_limit

	# Act — refused exactly `limit` times.
	for i in range(limit):
		assert_bool(env.queue.claim_job(target, 1)).is_true()
		_fire_full_build_cycle(env)
		assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.PLANNED)
		assert_int(env.gate.get_abandon_count(target)).is_equal(i + 1)

	# Assert — the NEXT attempt (limit + 1-th) proceeds unconditionally —
	# the builder is left sealed in (its own current_cell is unaffected —
	# only its future rescue, Story villager-ai-015, is out of this story's
	# scope).
	assert_bool(env.queue.claim_job(target, 1)).is_true()
	_fire_full_build_cycle(env)
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(env.gate.get_abandon_count(target)).is_equal(limit)


# ---------------------------------------------------------------------------
# Edge cases — abandon_count resets on a different-villager claim; monotonic
# bound
# ---------------------------------------------------------------------------

func test_abandon_count_resets_when_a_different_villager_claims_the_job() -> void:
	# Arrange
	var env := _make_gate_environment()
	var target := _DOORWAY
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)
	_register_worker(env, 1, _INTERIOR)
	assert_bool(env.queue.claim_job(target, 1)).is_true()
	_fire_full_build_cycle(env)
	assert_int(env.gate.get_abandon_count(target)).is_equal(1)

	# Act — a DIFFERENT villager, also trapped from the same position,
	# claims and is refused too.
	_register_worker(env, 2, _INTERIOR)
	assert_bool(env.queue.claim_job(target, 2)).is_true()
	_fire_full_build_cycle(env)

	# Assert — reset to 0 before this attempt, then incremented once: 1, not 2.
	assert_int(env.gate.get_abandon_count(target)).is_equal(1)


func test_abandon_count_is_zero_before_any_refusal() -> void:
	# Arrange
	var env := _make_gate_environment()

	# Act + Assert
	assert_int(env.gate.get_abandon_count(_DOORWAY)).is_equal(0)


func test_evaluate_allows_when_worker_not_registered_fails_open() -> void:
	# Arrange — this gate was never told about villager 1 at all (a wiring-
	# order gap, not a defect this class should mask by refusing
	# indefinitely — mirrors VillagerOnSiteGate's own "fails open" precedent).
	var env := _make_gate_environment()
	var target := _DOORWAY
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)
	assert_bool(env.queue.claim_job(target, 1)).is_true()

	# Act
	_fire_full_build_cycle(env)

	# Assert — allowed (fail-open), never refused over an unregistered worker.
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(env.gate.get_abandon_count(target)).is_equal(0)


## ADR-0009 slice propagation Sec.2b's "one deliberate exception" -- a
## builder standing exactly on its OWN completing cell (this codebase's own
## established Traveling mechanics route it there for the whole construction
## period, see `build_job_cycle_test.gd`'s own AC40 assertion) always
## proceeds unconditionally, never refused, never counted toward
## `abandon_count` -- otherwise every normal single-cell build job would be
## flagged as "trapping" its own worker.
func test_self_seal_exception_completes_unconditionally_and_never_counts() -> void:
	# Arrange — the worker stands EXACTLY on its own job cell (the doorway),
	# which would otherwise trap it per the sealed-room geometry.
	var env := _make_gate_environment()
	var target := _DOORWAY
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)
	_register_worker(env, 1, target)
	assert_bool(env.queue.claim_job(target, 1)).is_true()

	# Act
	_fire_full_build_cycle(env)

	# Assert — proceeds unconditionally, never refused.
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(env.grid.get_cell(target).is_empty()).is_false()
	assert_int(env.gate.get_abandon_count(target)).is_equal(0)


func test_evaluate_allows_normal_completion_when_not_trapped() -> void:
	# Arrange — the worker stands far from the sealed room entirely; its own
	# would_trap_builder check is unaffected by the doorway write.
	var env := _make_gate_environment()
	var target := _DOORWAY
	var project: BuildProject = _released_project(1, [target])
	env.queue.add_project(project)
	_register_worker(env, 1, Vector3i(50, 1, 50))
	assert_bool(env.queue.claim_job(target, 1)).is_true()

	# Act
	_fire_full_build_cycle(env)

	# Assert
	assert_int(project.cells[target].state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_int(env.gate.get_abandon_count(target)).is_equal(0)
