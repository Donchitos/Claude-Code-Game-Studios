## Unit test — Building System Story building-004 (Release ("Bau starten")
## + job-eligibility transition). ADR-0016 primary; GDD Rule 14f
## [TR-building-system-109] / [TR-building-system-106].
##
## Proves:
## 1. AC57: [method BuildProject.release] (this story's per-instance
##    realization of ADR-0016's `release_project(project_id)` Key Interface
##    -- see that method's own doc comment for why no registry-level id
##    lookup is needed yet, Story building-003 not landed) flips every
##    Draft cell in a DRAFT project to BUILDING/job-eligible, and none of
##    them were claimable ([method BuildProject.get_building_eligible_cells])
##    before the call.
## 2. `claim_job` gating (Rule 14f, TR-109): with DRAFT, BUILDING, and
##    PAUSED projects side by side, only the BUILDING project's still-
##    Planned cells are offered by [method
##    BuildProject.get_building_eligible_cells] -- the surface this story
##    exposes toward the future real `claim_job` (Story building-030's job
##    queue; per this story's own Implementation Notes, "it only flips
##    eligibility and exposes the queue"). An unreleased change-order batch
##    (Story building-007, not yet landed -- the data model has no separate
##    batch concept until then) is out of reach for this test file;
##    DRAFT/BUILDING/PAUSED cover every state this story can construct
##    today.
## 3. TR-106: the BUILDING-eligible queue is ordered by commit time
##    (insertion order) after release -- advisory for display/tie-break,
##    never forced servicing order (re-verified here in the release-driven
##    context; [ProjectEntityLifecycleTest] already covers the underlying
##    ordering mechanism directly, independent of release).
## 4. Edge cases: releasing an empty project is a no-op (no error, no
##    phantom jobs, state unchanged); releasing an already-BUILDING,
##    PAUSED, or DONE project is a no-op (release never resumes a paused
##    project -- Story building-006's own action -- and never re-releases a
##    project past DRAFT).
class_name ReleaseJobEligibilityTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _new_project(p_id: int = 1) -> BuildProject:
	return BuildProject.new(p_id)


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


# ---------------------------------------------------------------------------
# AC57 — release flips DRAFT -> BUILDING, all cells become job-eligible,
# none were claimable before the call
# ---------------------------------------------------------------------------

func test_release_transitions_draft_project_to_building() -> void:
	# Arrange
	var project: BuildProject = _new_project()
	project.add_cell(_planned_cell(Vector3i(0, 0, 0)))
	project.add_cell(_planned_cell(Vector3i(1, 0, 0)))
	project.add_cell(_planned_cell(Vector3i(2, 0, 0)))

	# Act
	var released: bool = project.release()

	# Assert
	assert_bool(released).is_true()
	assert_int(project.state).is_equal(BuildProject.ProjectState.BUILDING)


func test_cells_are_not_claimable_before_release_and_are_after() -> void:
	# Arrange — "none of them were claimable before that action" (AC57).
	var project: BuildProject = _new_project()
	var first_cell := Vector3i(0, 0, 0)
	var second_cell := Vector3i(1, 0, 0)
	project.add_cell(_planned_cell(first_cell))
	project.add_cell(_planned_cell(second_cell))

	# Act / Assert — before release, DRAFT offers nothing.
	assert_array(project.get_building_eligible_cells()).is_empty()

	project.release()

	# Assert — after release, both cells are offered.
	var eligible: Array[BlueprintCell] = project.get_building_eligible_cells()
	assert_int(eligible.size()).is_equal(2)


# ---------------------------------------------------------------------------
# claim_job gating (Rule 14f / TR-109) — DRAFT/BUILDING/PAUSED side by side
# ---------------------------------------------------------------------------

func test_only_building_project_offers_eligible_cells_among_draft_building_paused() -> void:
	# Arrange — three separate projects, one per state (Story building-007's
	# unreleased-change-order-batch case is out of reach — see file doc).
	var draft_project: BuildProject = _new_project(1)
	draft_project.add_cell(_planned_cell(Vector3i(0, 0, 0)))

	var building_project: BuildProject = _new_project(2)
	building_project.add_cell(_planned_cell(Vector3i(10, 0, 0)))
	building_project.release()

	var paused_project: BuildProject = _new_project(3)
	paused_project.add_cell(_planned_cell(Vector3i(20, 0, 0)))
	paused_project.state = BuildProject.ProjectState.PAUSED

	# Act
	var draft_eligible: Array[BlueprintCell] = draft_project.get_building_eligible_cells()
	var building_eligible: Array[BlueprintCell] = building_project.get_building_eligible_cells()
	var paused_eligible: Array[BlueprintCell] = paused_project.get_building_eligible_cells()

	# Assert — only the released (BUILDING) project offers its cell.
	assert_array(draft_eligible).is_empty()
	assert_int(building_eligible.size()).is_equal(1)
	assert_array(paused_eligible).is_empty()


func test_draft_project_cells_never_claimable_pre_release() -> void:
	# Arrange — negative case companion to AC57.
	var project: BuildProject = _new_project()
	project.add_cell(_planned_cell(Vector3i(0, 0, 0)))
	project.add_cell(_planned_cell(Vector3i(1, 0, 0)))
	project.add_cell(_planned_cell(Vector3i(2, 0, 0)))

	# Act
	var eligible: Array[BlueprintCell] = project.get_building_eligible_cells()

	# Assert
	assert_array(eligible).is_empty()
	assert_int(project.state).is_equal(BuildProject.ProjectState.DRAFT)


# ---------------------------------------------------------------------------
# TR-106 — BUILDING-eligible queue ordered by commit time after release
# ---------------------------------------------------------------------------

func test_eligible_queue_ordered_by_commit_time_after_release() -> void:
	# Arrange — cells committed in a specific order, released afterward.
	var project: BuildProject = _new_project()
	var first_cell := Vector3i(0, 0, 0)
	var second_cell := Vector3i(1, 0, 0)
	var third_cell := Vector3i(2, 0, 0)
	project.add_cell(_planned_cell(first_cell))
	project.add_cell(_planned_cell(second_cell))
	project.add_cell(_planned_cell(third_cell))

	# Act
	project.release()
	var eligible: Array[BlueprintCell] = project.get_building_eligible_cells()

	# Assert — commit order preserved, not forced-servicing (advisory only).
	assert_int(eligible.size()).is_equal(3)
	assert_vector(eligible[0].cell).is_equal(first_cell)
	assert_vector(eligible[1].cell).is_equal(second_cell)
	assert_vector(eligible[2].cell).is_equal(third_cell)


# ---------------------------------------------------------------------------
# Edge cases — no-op releases
# ---------------------------------------------------------------------------

func test_releasing_empty_project_is_noop() -> void:
	# Arrange — a DRAFT project with no cells at all.
	var project: BuildProject = _new_project()

	# Act
	var released: bool = project.release()

	# Assert — no error, no phantom jobs, state unchanged.
	assert_bool(released).is_false()
	assert_int(project.state).is_equal(BuildProject.ProjectState.DRAFT)
	assert_array(project.get_building_eligible_cells()).is_empty()


func test_releasing_already_building_project_is_noop() -> void:
	# Arrange
	var project: BuildProject = _new_project()
	project.add_cell(_planned_cell(Vector3i(0, 0, 0)))
	project.release()
	assert_int(project.state).is_equal(BuildProject.ProjectState.BUILDING)

	# Act — release again.
	var released_again: bool = project.release()

	# Assert
	assert_bool(released_again).is_false()
	assert_int(project.state).is_equal(BuildProject.ProjectState.BUILDING)


func test_releasing_paused_project_is_noop() -> void:
	# Arrange — release never resumes a paused project (Story building-006's
	# own action).
	var project: BuildProject = _new_project()
	project.add_cell(_planned_cell(Vector3i(0, 0, 0)))
	project.state = BuildProject.ProjectState.PAUSED

	# Act
	var released: bool = project.release()

	# Assert
	assert_bool(released).is_false()
	assert_int(project.state).is_equal(BuildProject.ProjectState.PAUSED)


func test_releasing_done_project_is_noop() -> void:
	# Arrange — a DONE project (every cell Built) is never re-released.
	var project: BuildProject = _new_project()
	project.add_cell(BlueprintCell.new(Vector3i(0, 0, 0), BlueprintCell.MicroState.BUILT))
	assert_int(project.state).is_equal(BuildProject.ProjectState.DONE)

	# Act
	var released: bool = project.release()

	# Assert
	assert_bool(released).is_false()
	assert_int(project.state).is_equal(BuildProject.ProjectState.DONE)
