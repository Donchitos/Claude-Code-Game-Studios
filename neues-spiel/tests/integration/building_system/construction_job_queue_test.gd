## Integration test — Building System Story building-030 (Construction job
## queue: claim/report pipeline + on-site + occupied-cell defer + unreachable
## feedback). ADR-0016 primary; GDD Core Rule 12 / Edge Cases 5 & 6
## [TR-building-system-053]/[TR-building-system-054]/[TR-building-system-055]/
## [TR-building-system-056]/[TR-building-system-037]/[TR-building-system-087].
##
## Covers the Building-owned halves only (AC21/AC36b are PROVISIONAL,
## resolved by villager-ai-012's crown test per the Sprint 7 QA plan
## Call-out 2 -- NOT re-asserted here):
## - AC35: an unreached/unreachable job stays queued indefinitely; its ghost
##   is never auto-canceled, regardless of how many tick events pass.
## - AC36 (mocked occupied-cell defer): a mocked "target occupied" predicate
##   skips that cell's progress while every other active job in the same
##   tick burst still credits normally; deferral is per-cell, not
##   per-command.
## - AC48: a mocked unreachable report flags the ghost + emits a signal; a
##   successful re-claim clears the flag + emits the reachable signal.
## - On-site predicate ([ConstructionJobQueue.is_on_site]): the target cell
##   and its six orthogonal neighbours (incl. directly below/above) count as
##   on-site; diagonal and non-adjacent cells do not.
## - Queue aggregation/ordering across multiple [BuildProject]s, claim/
##   release bookkeeping (one job per villager, per-cell parallelism), and
##   [ConstructionJobQueue]'s exact match to [VillagerAi]'s duck-typed
##   `has_available_job()`/`release_claim(villager_id)` contract.
##
## Real [ConstructionTickLoop] + [BuildProject] + [BlueprintCell] objects
## throughout (Integration story type) -- only the tick source is a test
## double ([MockTimeTickSystem], reused from
## `tests/integration/villager_ai/mock_time_tick_system.gd` per
## `construction_tick_loop_test.gd`'s own established precedent) and the
## occupancy/unreachable "detections" are mocked Callables/direct calls,
## exactly as this story's own Implementation Notes prescribe ("unit-test
## the Building-owned halves... with mocks now").
class_name ConstructionJobQueueTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_loop(grid: VoxelWorldGrid, tick_source: Object, loop_config: ConstructionTickLoopConfig = null) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = loop_config if loop_config != null else ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	loop.setup()
	return loop


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


## A DRAFT project with [param cells] added and immediately released
## (BUILDING, every cell job-eligible) -- mirrors
## `release_job_eligibility_test.gd`'s own established helper shape.
func _released_project(id: int, cells: Array[Vector3i]) -> BuildProject:
	var project := BuildProject.new(id)
	for cell: Vector3i in cells:
		project.add_cell(_planned_cell(cell))
	project.release()
	return project


# ---------------------------------------------------------------------------
# Queue aggregation / ordering / villager-facing contract
# ---------------------------------------------------------------------------

func test_available_jobs_aggregate_across_multiple_building_projects_in_order() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project_a: BuildProject = _released_project(1, [Vector3i(0, 0, 0), Vector3i(1, 0, 0)])
	var project_b: BuildProject = _released_project(2, [Vector3i(5, 0, 5)])

	# Act
	queue.add_project(project_a)
	queue.add_project(project_b)
	var jobs: Array[BlueprintCell] = queue.get_available_jobs()

	# Assert — project_a's two cells (its own commit order) first, then
	# project_b's, in registration order.
	assert_int(jobs.size()).is_equal(3)
	assert_vector(jobs[0].cell).is_equal(Vector3i(0, 0, 0))
	assert_vector(jobs[1].cell).is_equal(Vector3i(1, 0, 0))
	assert_vector(jobs[2].cell).is_equal(Vector3i(5, 0, 5))
	assert_bool(queue.has_available_job()).is_true()


func test_has_available_job_false_with_no_projects_registered() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)

	# Act / Assert — matches VillagerAi._has_available_job's nil-safe-caller
	# expectation: an empty queue reads exactly like "no job," never errors.
	assert_bool(queue.has_available_job()).is_false()
	assert_array(queue.get_available_jobs()).is_empty()


func test_removed_project_no_longer_contributes_jobs() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)
	assert_bool(queue.has_available_job()).is_true()

	# Act
	queue.remove_project(project)

	# Assert
	assert_bool(queue.has_available_job()).is_false()


# ---------------------------------------------------------------------------
# Claim / release bookkeeping (TR-054 one job per villager; per-cell
# parallelism)
# ---------------------------------------------------------------------------

func test_claim_job_delegates_to_tick_loop_and_records_villager_claim() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)

	# Act
	var claimed: bool = queue.claim_job(Vector3i(0, 0, 0), 7)

	# Assert
	assert_bool(claimed).is_true()
	assert_bool(queue.has_claim(7)).is_true()
	assert_bool(loop.is_job_active(Vector3i(0, 0, 0))).is_true()
	assert_int(project.cells[Vector3i(0, 0, 0)].state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)


func test_claim_job_rejects_second_claim_while_villager_already_holds_one() -> void:
	# Arrange — TR-054: "a villager finishes or abandons its current job
	# before claiming another."
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0), Vector3i(1, 0, 0)])
	queue.add_project(project)
	assert_bool(queue.claim_job(Vector3i(0, 0, 0), 7)).is_true()

	# Act — villager 7 tries a SECOND cell without releasing the first.
	var second_claim: bool = queue.claim_job(Vector3i(1, 0, 0), 7)

	# Assert — rejected; the first claim is untouched, the second cell stays
	# Planned/available.
	assert_bool(second_claim).is_false()
	assert_bool(loop.is_job_active(Vector3i(1, 0, 0))).is_false()
	assert_int(project.cells[Vector3i(1, 0, 0)].state).is_equal(BlueprintCell.MicroState.PLANNED)


func test_claim_job_rejects_unknown_or_non_eligible_cell() -> void:
	# Arrange — an untracked cell, and a DRAFT (unreleased) project's cell.
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var draft_project := BuildProject.new(1)
	draft_project.add_cell(_planned_cell(Vector3i(9, 0, 9)))
	queue.add_project(draft_project)

	# Act
	var claimed_untracked: bool = queue.claim_job(Vector3i(99, 0, 99), 1)
	var claimed_draft: bool = queue.claim_job(Vector3i(9, 0, 9), 1)

	# Assert
	assert_bool(claimed_untracked).is_false()
	assert_bool(claimed_draft).is_false()
	assert_bool(queue.has_claim(1)).is_false()


func test_per_cell_claims_allow_parallelism_two_villagers_two_cells() -> void:
	# Arrange — TR-055: N villagers may simultaneously work N distinct cells
	# of the SAME command/project.
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0), Vector3i(1, 0, 0)])
	queue.add_project(project)

	# Act
	var first_claimed: bool = queue.claim_job(Vector3i(0, 0, 0), 1)
	var second_claimed: bool = queue.claim_job(Vector3i(1, 0, 0), 2)

	# Assert
	assert_bool(first_claimed).is_true()
	assert_bool(second_claimed).is_true()
	assert_bool(loop.is_job_active(Vector3i(0, 0, 0))).is_true()
	assert_bool(loop.is_job_active(Vector3i(1, 0, 0))).is_true()


func test_release_claim_returns_job_to_queue_and_reclaimable_by_another_villager() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)
	queue.claim_job(Vector3i(0, 0, 0), 7)

	# Act — villager 7 abandons; the SAME job must be genuinely re-offered,
	# claimable by a DIFFERENT villager, not merely "released" in name.
	queue.release_claim(7)
	var reoffered: bool = queue.has_available_job()
	var reclaimed_by_other: bool = queue.claim_job(Vector3i(0, 0, 0), 8)

	# Assert
	assert_bool(queue.has_claim(7)).is_false()
	assert_bool(reoffered).is_true()
	assert_bool(reclaimed_by_other).is_true()
	assert_bool(queue.has_claim(8)).is_true()
	assert_int(project.cells[Vector3i(0, 0, 0)].state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)


func test_release_claim_is_noop_when_villager_holds_no_claim() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)

	# Act / Assert — never errors, mirrors VillagerAi._release_job_claim's
	# nil-safe caller discipline.
	queue.release_claim(42)
	assert_bool(queue.has_claim(42)).is_false()


# ---------------------------------------------------------------------------
# AC35 — unreachable/unclaimed job stays queued indefinitely
# ---------------------------------------------------------------------------

func test_unclaimed_job_stays_queued_after_many_ticks_pass() -> void:
	# Arrange — a blueprint cell no villager ever claims (stands in for "no
	# villager can reach it").
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), mock_tick)
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)

	# Act — a large amount of game time passes; nothing ever claims the job.
	for i in range(200):
		mock_tick.fire_tick()

	# Assert — still queued, never auto-canceled, state untouched.
	assert_bool(queue.has_available_job()).is_true()
	assert_int(queue.get_available_jobs().size()).is_equal(1)
	assert_int(project.cells[Vector3i(0, 0, 0)].state).is_equal(BlueprintCell.MicroState.PLANNED)


func test_unreachable_flagged_job_stays_queued_after_many_ticks_pass() -> void:
	# Arrange — same as above, but the job has additionally been reported
	# unreachable (Edge Case 5's ghost-tint state).
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), mock_tick)
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)
	queue.report_unreachable(Vector3i(0, 0, 0))

	# Act
	for i in range(200):
		mock_tick.fire_tick()

	# Assert — still queued, still flagged, still Planned.
	assert_bool(queue.has_available_job()).is_true()
	var job: BlueprintCell = queue.get_available_jobs()[0]
	assert_bool(job.is_unreachable).is_true()
	assert_int(job.state).is_equal(BlueprintCell.MicroState.PLANNED)


# ---------------------------------------------------------------------------
# AC48 — unreachable report + re-claim feedback
# ---------------------------------------------------------------------------

func test_report_unreachable_sets_flag_and_emits_signal() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)
	var reported_cells: Array = []
	queue.job_reported_unreachable.connect(func(cell: Vector3i) -> void: reported_cells.append(cell))

	# Act
	var reported: bool = queue.report_unreachable(Vector3i(0, 0, 0))

	# Assert
	assert_bool(reported).is_true()
	assert_bool(project.cells[Vector3i(0, 0, 0)].is_unreachable).is_true()
	assert_int(reported_cells.size()).is_equal(1)
	assert_vector(reported_cells[0]).is_equal(Vector3i(0, 0, 0))


func test_report_unreachable_on_untracked_cell_is_noop() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)

	# Act / Assert
	assert_bool(queue.report_unreachable(Vector3i(0, 0, 0))).is_false()


func test_reclaim_after_unreachable_clears_flag_and_emits_reachable_signal() -> void:
	# Arrange — the obstruction is removed, and the job is claimed again.
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)
	queue.report_unreachable(Vector3i(0, 0, 0))
	assert_bool(project.cells[Vector3i(0, 0, 0)].is_unreachable).is_true()
	var became_reachable_cells: Array = []
	queue.job_became_reachable.connect(func(cell: Vector3i) -> void: became_reachable_cells.append(cell))

	# Act
	var claimed: bool = queue.claim_job(Vector3i(0, 0, 0), 3)

	# Assert — the ghost returns to normal Planned-equivalent (flag cleared);
	# the underlying micro-state still progresses to UnderConstruction as any
	# other successful claim would.
	assert_bool(claimed).is_true()
	assert_bool(project.cells[Vector3i(0, 0, 0)].is_unreachable).is_false()
	assert_int(became_reachable_cells.size()).is_equal(1)
	assert_vector(became_reachable_cells[0]).is_equal(Vector3i(0, 0, 0))


func test_claim_of_never_flagged_cell_never_emits_reachable_signal() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)
	var became_reachable_cells: Array = []
	queue.job_became_reachable.connect(func(cell: Vector3i) -> void: became_reachable_cells.append(cell))

	# Act
	queue.claim_job(Vector3i(0, 0, 0), 1)

	# Assert
	assert_int(became_reachable_cells.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC36 — occupied-cell defer (mocked), per-cell not per-command
# ---------------------------------------------------------------------------

func test_occupied_cell_defer_skips_progress_other_cells_process_normally() -> void:
	# Arrange — two claimed cells; a mocked occupancy predicate reports only
	# ONE of them occupied.
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), mock_tick, loop_config)
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0), Vector3i(1, 0, 0)])
	queue.add_project(project)
	queue.claim_job(Vector3i(0, 0, 0), 1)  # occupied target — deferred
	queue.claim_job(Vector3i(1, 0, 0), 2)  # free target — processes normally
	var occupied_cell := Vector3i(0, 0, 0)
	queue.set_occupancy_predicate(func(cell: Vector3i) -> bool: return cell == occupied_cell)

	# Act — a full burst of ticks, enough to complete the FREE cell's job if
	# it were never deferred at all.
	for i in range(loop_config.base_build_ticks_block):
		mock_tick.fire_tick()

	# Assert — the occupied cell never advanced at all; the free cell
	# completed normally, on schedule, unaffected by the other cell's defer.
	assert_int(loop.get_progress_ticks(occupied_cell)).is_equal(0)
	assert_int(project.cells[occupied_cell].state).is_equal(BlueprintCell.MicroState.UNDER_CONSTRUCTION)
	assert_int(project.cells[Vector3i(1, 0, 0)].state).is_equal(BlueprintCell.MicroState.BUILT)


func test_occupied_defer_clears_once_predicate_reports_clear() -> void:
	# Arrange
	var mock_tick: MockTimeTickSystem = auto_free(MockTimeTickSystem.new())
	var loop_config := ConstructionTickLoopConfig.new()
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), mock_tick, loop_config)
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)
	queue.claim_job(Vector3i(0, 0, 0), 1)
	# A GDScript lambda captures a scalar local BY VALUE at creation time, not
	# by reference -- a boxed single-element Array is this codebase's own
	# established mutable-capture idiom (mirrors every signal-listener
	# Array+append precedent elsewhere in this file) so later mutating
	# occupied_state[0] is actually visible inside the already-created
	# predicate Callable.
	var occupied_state: Array = [true]
	queue.set_occupancy_predicate(func(_cell: Vector3i) -> bool: return occupied_state[0])

	# Act — deferred while occupied; the occupant then vacates, and the SAME
	# claim (no re-claim) resumes progress on the next tick.
	mock_tick.fire_tick()
	assert_int(loop.get_progress_ticks(Vector3i(0, 0, 0))).is_equal(0)
	occupied_state[0] = false
	for i in range(loop_config.base_build_ticks_block):
		mock_tick.fire_tick()

	# Assert
	assert_int(project.cells[Vector3i(0, 0, 0)].state).is_equal(BlueprintCell.MicroState.BUILT)


# ---------------------------------------------------------------------------
# On-site predicate — target cell + orthogonal neighbours (incl. below/above)
# ---------------------------------------------------------------------------

func test_on_site_predicate_target_cell_itself_counts() -> void:
	var target := Vector3i(5, 2, 5)
	assert_bool(ConstructionJobQueue.is_on_site(target, target)).is_true()


func test_on_site_predicate_orthogonal_neighbours_including_vertical() -> void:
	var target := Vector3i(5, 2, 5)
	var neighbours: Array[Vector3i] = [
		target + Vector3i(1, 0, 0),
		target + Vector3i(-1, 0, 0),
		target + Vector3i(0, 0, 1),
		target + Vector3i(0, 0, -1),
		target + Vector3i(0, 1, 0),  # directly above
		target + Vector3i(0, -1, 0),  # directly below
	]
	for standing_cell: Vector3i in neighbours:
		assert_bool(ConstructionJobQueue.is_on_site(target, standing_cell)).is_true()


func test_on_site_predicate_rejects_diagonal_and_non_adjacent_cells() -> void:
	var target := Vector3i(5, 2, 5)
	var not_on_site: Array[Vector3i] = [
		target + Vector3i(1, 0, 1),  # horizontal diagonal
		target + Vector3i(1, 1, 0),  # vertical+horizontal diagonal
		target + Vector3i(2, 0, 0),  # two cells away, same axis
		target + Vector3i(0, 2, 0),  # two cells straight up
	]
	for standing_cell: Vector3i in not_on_site:
		assert_bool(ConstructionJobQueue.is_on_site(target, standing_cell)).is_false()
