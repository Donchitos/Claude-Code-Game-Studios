## Unit test — Building System Story building-002 (Build Project entity:
## lifecycle rollup + persistence-until-empty). ADR-0016 primary (persistent
## project entity, state as a rollup over cells, never an independent flag;
## a project entity is removed only when its cell set becomes empty).
##
## Proves:
## 1. AC60 [TR-building-system-111]: a project whose every cell is Built
##    rolls up to DONE and is never deleted on completion -- including the
##    single-cell edge case.
## 2. AC61 [TR-building-system-111]: a project's LAST remaining cell being
##    canceled (Draft/UnderConstruction) or demolished (Built) is the one
##    and only condition that empties the project entity -- including a
##    previously-DONE project, and confirming a remaining cell of ANY
##    micro-state keeps the project alive.
## 3. Rollup bullet [TR-building-system-108]: DRAFT while every cell is
##    still Planned; the rollup never demotes an already-BUILDING/PAUSED
##    project back toward DRAFT on its own; a mixed Built+Draft cell set
##    stays non-DONE; a DONE project regaining a not-yet-Built cell (a
##    future change order) falls back to BUILDING.
## 4. Job-eligibility bullet [TR-building-system-106]: a Draft cell is
##    invisible to the BUILDING-eligible queue; a PAUSED project offers
##    none either; only a BUILDING project's still-Planned cells are
##    offered, in commit (insertion) order, never already-claimed/Built
##    cells.
## 5. Blueprint-cell micro-state bullet [TR-building-system-108]/Rule 16-17:
##    a Built cell can never be canceled (Canceled is never reachable from
##    Built) -- only demolished; a not-yet-Built cell can never be
##    "demolished" -- only canceled.
class_name ProjectEntityLifecycleTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _new_project(p_id: int = 1) -> BuildProject:
	return BuildProject.new(p_id)


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


func _under_construction_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.UNDER_CONSTRUCTION)


func _built_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.BUILT)


# ---------------------------------------------------------------------------
# AC60 — every cell Built rolls up to DONE, entity persists
# ---------------------------------------------------------------------------

func test_all_built_cells_state_is_done() -> void:
	# Arrange
	var project: BuildProject = _new_project()

	# Act
	project.add_cell(_built_cell(Vector3i(0, 0, 0)))
	project.add_cell(_built_cell(Vector3i(1, 0, 0)))

	# Assert
	assert_int(project.state).is_equal(BuildProject.ProjectState.DONE)
	assert_bool(project.is_empty()).is_false()


func test_single_built_cell_no_pending_batch_is_done_not_deleted() -> void:
	# Arrange / Act — the AC60 edge case: exactly one Built cell.
	var project: BuildProject = _new_project()
	project.add_cell(_built_cell(Vector3i(5, 0, 5)))

	# Assert
	assert_int(project.state).is_equal(BuildProject.ProjectState.DONE)
	assert_bool(project.is_empty()).is_false()
	assert_int(project.get_cells().size()).is_equal(1)


# ---------------------------------------------------------------------------
# AC61 — the project entity is removed ONLY when its cell set becomes empty
# ---------------------------------------------------------------------------

func test_canceling_last_draft_cell_empties_project() -> void:
	# Arrange
	var project: BuildProject = _new_project()
	var cell := Vector3i(2, 0, 2)
	project.add_cell(_planned_cell(cell))

	# Act
	var canceled: bool = project.cancel_cell(cell)

	# Assert
	assert_bool(canceled).is_true()
	assert_bool(project.is_empty()).is_true()
	assert_bool(project.has_cell(cell)).is_false()


func test_demolishing_last_built_cell_empties_project() -> void:
	# Arrange
	var project: BuildProject = _new_project()
	var cell := Vector3i(3, 0, 3)
	project.add_cell(_built_cell(cell))
	assert_int(project.state).is_equal(BuildProject.ProjectState.DONE)

	# Act
	var demolished: bool = project.demolish_cell(cell)

	# Assert
	assert_bool(demolished).is_true()
	assert_bool(project.is_empty()).is_true()


func test_demolishing_done_projects_last_cell_via_demolition_empties_entity() -> void:
	# Arrange — AC61 edge case: deleting a DONE project's last cell via
	# demolition removes the entity (not just any old cancel path).
	var project: BuildProject = _new_project()
	var cell := Vector3i(4, 0, 4)
	project.add_cell(_built_cell(cell))
	assert_int(project.state).is_equal(BuildProject.ProjectState.DONE)

	# Act
	project.demolish_cell(cell)

	# Assert
	assert_bool(project.is_empty()).is_true()


func test_project_with_remaining_cell_of_any_micro_state_is_never_emptied() -> void:
	# Arrange — AC61 edge case: a project with any remaining cell of any
	# micro-state is never deleted, even after removing another of its cells.
	var project: BuildProject = _new_project()
	var planned_cell := Vector3i(0, 0, 0)
	var under_construction_cell := Vector3i(1, 0, 0)
	var built_cell := Vector3i(2, 0, 0)
	project.add_cell(_planned_cell(planned_cell))
	project.add_cell(_under_construction_cell(under_construction_cell))
	project.add_cell(_built_cell(built_cell))

	# Act — remove two of the three cells one at a time.
	project.cancel_cell(planned_cell)
	project.cancel_cell(under_construction_cell)

	# Assert — the Built cell alone keeps the project alive.
	assert_bool(project.is_empty()).is_false()
	assert_bool(project.has_cell(built_cell)).is_true()


# ---------------------------------------------------------------------------
# Rollup — DRAFT while all-Planned; no auto-demotion; mixed cells stay
# non-DONE; a DONE project regaining a cell falls back to BUILDING
# ---------------------------------------------------------------------------

func test_draft_state_when_every_cell_is_planned() -> void:
	# Arrange / Act
	var project: BuildProject = _new_project()
	project.add_cell(_planned_cell(Vector3i(0, 0, 0)))
	project.add_cell(_planned_cell(Vector3i(1, 0, 0)))

	# Assert
	assert_int(project.state).is_equal(BuildProject.ProjectState.DRAFT)


func test_recompute_does_not_demote_building_state_toward_draft() -> void:
	# Arrange — simulates a released project (a future story's own action
	# sets state directly, mirroring BlueprintCell.state's own established
	# "plain public var another module writes" precedent).
	var project: BuildProject = _new_project()
	project.state = BuildProject.ProjectState.BUILDING

	# Act — adding a still-Planned cell must not roll the state back to DRAFT.
	project.add_cell(_planned_cell(Vector3i(6, 0, 6)))

	# Assert
	assert_int(project.state).is_equal(BuildProject.ProjectState.BUILDING)


func test_recompute_does_not_move_a_paused_project_out_of_paused() -> void:
	# Arrange — Rule 14g: pausing/resuming never happens as a side effect of
	# a cell-state change (Story building-006 owns the real pause/resume
	# actions; this proves recompute_state() never second-guesses PAUSED).
	var project: BuildProject = _new_project()
	project.add_cell(_planned_cell(Vector3i(7, 0, 7)))
	project.state = BuildProject.ProjectState.PAUSED

	# Act
	project.add_cell(_planned_cell(Vector3i(8, 0, 8)))

	# Assert
	assert_int(project.state).is_equal(BuildProject.ProjectState.PAUSED)


func test_mixed_built_and_draft_cells_yields_non_done_rollup() -> void:
	# Arrange — edge case: mixing one Built and one Draft cell.
	var project: BuildProject = _new_project()
	project.state = BuildProject.ProjectState.BUILDING
	project.add_cell(_built_cell(Vector3i(0, 0, 0)))

	# Act
	project.add_cell(_planned_cell(Vector3i(1, 0, 0)))

	# Assert — not every cell is Built, so the rollup is not DONE.
	assert_int(project.state).is_not_equal(BuildProject.ProjectState.DONE)
	assert_int(project.state).is_equal(BuildProject.ProjectState.BUILDING)


func test_done_project_regaining_a_cell_falls_back_to_building() -> void:
	# Arrange — TR-112: a DONE project that gains a pending (future
	# change-order) cell is no longer fully DONE for rollup purposes.
	var project: BuildProject = _new_project()
	project.add_cell(_built_cell(Vector3i(0, 0, 0)))
	assert_int(project.state).is_equal(BuildProject.ProjectState.DONE)

	# Act
	project.add_cell(_planned_cell(Vector3i(1, 0, 0)))

	# Assert
	assert_int(project.state).is_equal(BuildProject.ProjectState.BUILDING)


# ---------------------------------------------------------------------------
# Job-eligibility gate [TR-building-system-106] — Draft invisible to
# claim_job; only a BUILDING project offers its still-Planned cells
# ---------------------------------------------------------------------------

func test_draft_project_offers_no_eligible_cells() -> void:
	# Arrange — "Given a project with all Draft cells. When claim_job
	# enumerates eligible work. Then none of the project's cells are
	# offered AND state == DRAFT" (QA Test Cases).
	var project: BuildProject = _new_project()
	project.add_cell(_planned_cell(Vector3i(0, 0, 0)))
	project.add_cell(_planned_cell(Vector3i(1, 0, 0)))

	# Act
	var eligible: Array[BlueprintCell] = project.get_building_eligible_cells()

	# Assert
	assert_array(eligible).is_empty()
	assert_int(project.state).is_equal(BuildProject.ProjectState.DRAFT)


func test_paused_project_offers_no_eligible_cells() -> void:
	# Arrange — Rule 14g: pausing stops offering new jobs even though queued
	# cells remain tracked and Planned.
	var project: BuildProject = _new_project()
	project.add_cell(_planned_cell(Vector3i(0, 0, 0)))
	project.state = BuildProject.ProjectState.PAUSED

	# Act
	var eligible: Array[BlueprintCell] = project.get_building_eligible_cells()

	# Assert
	assert_array(eligible).is_empty()


func test_building_project_offers_only_still_planned_cells() -> void:
	# Arrange — a released project with one still-Planned cell, one already
	# claimed (UnderConstruction), and one already Built.
	var project: BuildProject = _new_project()
	project.state = BuildProject.ProjectState.BUILDING
	var planned_cell := _planned_cell(Vector3i(0, 0, 0))
	project.add_cell(planned_cell)
	project.add_cell(_under_construction_cell(Vector3i(1, 0, 0)))
	project.add_cell(_built_cell(Vector3i(2, 0, 0)))

	# Act
	var eligible: Array[BlueprintCell] = project.get_building_eligible_cells()

	# Assert — only the still-Planned cell is offered.
	assert_int(eligible.size()).is_equal(1)
	assert_object(eligible[0]).is_same(planned_cell)


func test_eligible_cells_are_ordered_by_commit_time() -> void:
	# Arrange — Core Rule 12: "ordered by commit time" — proven via the
	# order add_cell() was called in.
	var project: BuildProject = _new_project()
	project.state = BuildProject.ProjectState.BUILDING
	var first_cell := Vector3i(0, 0, 0)
	var second_cell := Vector3i(1, 0, 0)
	var third_cell := Vector3i(2, 0, 0)
	project.add_cell(_planned_cell(second_cell))
	project.add_cell(_planned_cell(third_cell))
	project.add_cell(_planned_cell(first_cell))

	# Act
	var eligible: Array[BlueprintCell] = project.get_building_eligible_cells()

	# Assert — commit order preserved (second, third, first — the order they
	# were added, not sorted by address).
	assert_int(eligible.size()).is_equal(3)
	assert_vector(eligible[0].cell).is_equal(second_cell)
	assert_vector(eligible[1].cell).is_equal(third_cell)
	assert_vector(eligible[2].cell).is_equal(first_cell)


# ---------------------------------------------------------------------------
# Micro-state bullet — Canceled never reachable from Built; demolish only
# applies to Built
# ---------------------------------------------------------------------------

func test_cancel_cell_on_built_cell_fails() -> void:
	# Arrange — Rule 16/17: "Canceled... Never reachable from Built."
	var project: BuildProject = _new_project()
	var cell := Vector3i(0, 0, 0)
	var blueprint_cell := _built_cell(cell)
	project.add_cell(blueprint_cell)

	# Act
	var canceled: bool = project.cancel_cell(cell)

	# Assert — no-op; the cell stays Built and tracked.
	assert_bool(canceled).is_false()
	assert_int(blueprint_cell.state).is_equal(BlueprintCell.MicroState.BUILT)
	assert_bool(project.has_cell(cell)).is_true()


func test_cancel_cell_on_planned_cell_succeeds() -> void:
	# Arrange
	var project: BuildProject = _new_project()
	var cell := Vector3i(0, 0, 0)
	var blueprint_cell := _planned_cell(cell)
	project.add_cell(blueprint_cell)

	# Act
	var canceled: bool = project.cancel_cell(cell)

	# Assert
	assert_bool(canceled).is_true()
	assert_int(blueprint_cell.state).is_equal(BlueprintCell.MicroState.CANCELED)
	assert_bool(project.has_cell(cell)).is_false()


func test_cancel_cell_on_under_construction_cell_succeeds() -> void:
	# Arrange — Rule 16: "Queued/UnderConstruction... -> instant cancel."
	var project: BuildProject = _new_project()
	var cell := Vector3i(0, 0, 0)
	var blueprint_cell := _under_construction_cell(cell)
	project.add_cell(blueprint_cell)

	# Act
	var canceled: bool = project.cancel_cell(cell)

	# Assert
	assert_bool(canceled).is_true()
	assert_int(blueprint_cell.state).is_equal(BlueprintCell.MicroState.CANCELED)


func test_demolish_cell_on_planned_cell_fails() -> void:
	# Arrange — a not-yet-Built cell can only be canceled, never demolished.
	var project: BuildProject = _new_project()
	var cell := Vector3i(0, 0, 0)
	project.add_cell(_planned_cell(cell))

	# Act
	var demolished: bool = project.demolish_cell(cell)

	# Assert — no-op; still tracked and Planned.
	assert_bool(demolished).is_false()
	assert_bool(project.has_cell(cell)).is_true()


func test_demolish_cell_on_untracked_cell_fails() -> void:
	# Arrange
	var project: BuildProject = _new_project()

	# Act
	var demolished: bool = project.demolish_cell(Vector3i(9, 9, 9))

	# Assert
	assert_bool(demolished).is_false()
