## Integration test — Building System Story building-005 (Worker attribution
## on job claim). ADR-0016 primary ("When a villager claims a project's job,
## the claim records the villager id; the project exposes `worker_ids`
## aggregating its builders. Attribution is read/display + save state, never
## a control channel." Decision Sec.4); ADR-0007 secondary. GDD Rule 12/14f,
## [TR-building-system-109], AC58.
##
## Covers this story's own accepted evidence bar -- a mocked claim (real
## [ConstructionJobQueue.claim_job], no real Villager AI travel) plus direct
## [BuildProject.on_job_claimed] calls, mirroring
## `construction_job_queue_test.gd`'s own established real-components style
## (real [VoxelWorldGrid]/[ConstructionTickLoop]/[BuildProject]/
## [BlueprintCell] throughout; only the tick source is a test double):
## - AC58: a successful claim records the villager id against the claimed
##   cell ([member BlueprintCell.claimed_by_villager_id]) and rolls it up
##   into the project's de-duplicated [member BuildProject.worker_ids].
## - De-duplication: the same villager claiming two cells (sequentially --
##   TR-054's "one job per villager at a time" forbids a simultaneous second
##   claim) appears once in `worker_ids`; two villagers on distinct cells
##   both appear.
## - `serialize()` contract shape includes `worker_ids` (shape-only, per this
##   story's own Out of Scope: full save/load round-trip is VS-tier).
## - Not-a-control-channel: clearing/altering `worker_ids` changes no
##   scheduling/claiming outcome.
## - Edge case: attribution recording never blocks or delays a subsequent
##   claim on a different cell of the same project.
class_name WorkerAttributionTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test helpers (above every test function, per this codebase's convention)
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_loop(grid: VoxelWorldGrid, tick_source: Object) -> ConstructionTickLoop:
	var loop: ConstructionTickLoop = auto_free(ConstructionTickLoop.new())
	loop.voxel_world = grid
	loop.config = ConstructionTickLoopConfig.new()
	loop.time_tick_system = tick_source
	loop.setup()
	return loop


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


# ---------------------------------------------------------------------------
# AC58 — a successful claim records the villager against the cell and rolls
# up onto the project's worker_ids
# ---------------------------------------------------------------------------

func test_claim_job_records_villager_against_cell_and_rolls_up_worker_ids() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)

	# Act — the mocked claim: a real ConstructionJobQueue.claim_job call, no
	# real Villager AI travel (this story's own accepted evidence bar).
	var claimed: bool = queue.claim_job(Vector3i(0, 0, 0), 7)

	# Assert
	assert_bool(claimed).is_true()
	assert_int(project.cells[Vector3i(0, 0, 0)].claimed_by_villager_id).is_equal(7)
	assert_int(project.worker_ids.size()).is_equal(1)
	assert_bool(project.worker_ids.has(7)).is_true()


func test_on_job_claimed_direct_call_records_cell_and_worker_ids() -> void:
	# Arrange — BuildProject.on_job_claimed exercised directly (the
	# per-instance seam ConstructionJobQueue.claim_job delegates to).
	var project := BuildProject.new(1)
	var cell := Vector3i(2, 0, 2)
	project.add_cell(_planned_cell(cell))

	# Act
	var recorded: bool = project.on_job_claimed(cell, 3)

	# Assert
	assert_bool(recorded).is_true()
	assert_int(project.cells[cell].claimed_by_villager_id).is_equal(3)
	assert_array(project.worker_ids).is_equal([3])


func test_on_job_claimed_on_untracked_cell_is_noop() -> void:
	# Arrange
	var project := BuildProject.new(1)

	# Act
	var recorded: bool = project.on_job_claimed(Vector3i(9, 9, 9), 1)

	# Assert — no-op; nothing to record against, worker_ids stays empty.
	assert_bool(recorded).is_false()
	assert_array(project.worker_ids).is_empty()


# ---------------------------------------------------------------------------
# De-duplication — same villager on two cells appears once; two villagers on
# distinct cells both appear
# ---------------------------------------------------------------------------

func test_same_villager_claiming_two_cells_sequentially_appears_once_in_worker_ids() -> void:
	# Arrange — TR-054 forbids a SIMULTANEOUS second claim by one villager,
	# so "the same villager claiming two cells" is modeled sequentially:
	# claim, release (job finished/abandoned), claim again.
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0), Vector3i(1, 0, 0)])
	queue.add_project(project)

	# Act
	assert_bool(queue.claim_job(Vector3i(0, 0, 0), 5)).is_true()
	queue.release_claim(5)
	assert_bool(queue.claim_job(Vector3i(1, 0, 0), 5)).is_true()

	# Assert — villager 5 appears exactly once, even though it claimed two
	# distinct cells over time; each cell's own attribution is still correct.
	assert_array(project.worker_ids).is_equal([5])
	assert_int(project.cells[Vector3i(0, 0, 0)].claimed_by_villager_id).is_equal(5)
	assert_int(project.cells[Vector3i(1, 0, 0)].claimed_by_villager_id).is_equal(5)


func test_two_villagers_on_distinct_cells_both_appear_in_worker_ids() -> void:
	# Arrange — TR-055 per-cell parallelism: two villagers, two cells of the
	# SAME project, claimed simultaneously (no release needed).
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0), Vector3i(1, 0, 0)])
	queue.add_project(project)

	# Act
	var first_claimed: bool = queue.claim_job(Vector3i(0, 0, 0), 1)
	var second_claimed: bool = queue.claim_job(Vector3i(1, 0, 0), 2)

	# Assert — attribution recording never blocked or delayed the second,
	# distinct-cell claim (this story's own edge case).
	assert_bool(first_claimed).is_true()
	assert_bool(second_claimed).is_true()
	assert_int(project.worker_ids.size()).is_equal(2)
	assert_bool(project.worker_ids.has(1)).is_true()
	assert_bool(project.worker_ids.has(2)).is_true()


# ---------------------------------------------------------------------------
# serialize() contract shape includes worker_ids (shape-only, VS-tier
# defers the full round-trip)
# ---------------------------------------------------------------------------

func test_serialize_contract_shape_includes_worker_ids() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(1, [Vector3i(0, 0, 0)])
	queue.add_project(project)
	queue.claim_job(Vector3i(0, 0, 0), 9)

	# Act
	var data: Dictionary = project.serialize()

	# Assert — contract shape only; a full round-trip (cells, restore_value,
	# pending orders, deserialize()) is explicitly VS-tier, not this story's
	# job.
	assert_bool(data.has("worker_ids")).is_true()
	var serialized_worker_ids: Array = data["worker_ids"]
	assert_bool(serialized_worker_ids.has(9)).is_true()
	assert_int(data["id"]).is_equal(1)


# ---------------------------------------------------------------------------
# Not a control channel — worker_ids never gates or influences scheduling/
# claiming/lifecycle outcomes
# ---------------------------------------------------------------------------

func test_clearing_worker_ids_does_not_affect_subsequent_claim_or_eligibility() -> void:
	# Arrange
	var loop: ConstructionTickLoop = _new_loop(_new_grid(), auto_free(MockTimeTickSystem.new()))
	var queue := ConstructionJobQueue.new(loop)
	var project: BuildProject = _released_project(
		1, [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(2, 0, 0)]
	)
	queue.add_project(project)
	assert_bool(queue.claim_job(Vector3i(0, 0, 0), 1)).is_true()
	assert_int(project.worker_ids.size()).is_equal(1)

	# Act — forcibly clear the attribution record (simulates "altering it").
	project.worker_ids.clear()

	# Assert — scheduling/eligibility/claiming are completely unaffected: the
	# two still-Planned cells remain eligible, and a second villager can
	# still claim one of them exactly as if worker_ids had never been
	# touched.
	assert_int(project.get_building_eligible_cells().size()).is_equal(2)
	assert_bool(queue.claim_job(Vector3i(1, 0, 0), 2)).is_true()
	assert_int(project.get_building_eligible_cells().size()).is_equal(1)


func test_empty_worker_ids_project_still_releases_and_offers_jobs_normally() -> void:
	# Arrange — a project that has NEVER had a claim (worker_ids stays
	# empty) behaves identically to one that has -- release/eligibility
	# never read worker_ids.
	var project := BuildProject.new(1)
	project.add_cell(_planned_cell(Vector3i(0, 0, 0)))

	# Act
	var released: bool = project.release()

	# Assert
	assert_bool(released).is_true()
	assert_array(project.worker_ids).is_empty()
	assert_int(project.get_building_eligible_cells().size()).is_equal(1)
