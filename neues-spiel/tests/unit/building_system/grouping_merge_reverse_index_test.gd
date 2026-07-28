## Unit test — Building System Story building-003 (26-neighborhood
## grouping/merge + cell->project reverse index). ADR-0016 primary (Decision
## Sec.2 grouping/merge, Sec.6 reverse index); GDD Rule 14c, F6,
## [TR-building-system-107].
##
## Proves:
## 1. AC55: two SEPARATE commits whose cells are 26-adjacent (F6) end up
##    belonging to exactly one [BuildProject] — including the purely
##    diagonal-touch case — and a one-cell gap between two commits does
##    NOT merge them (F6's own worked example).
## 2. AC56 / Edge Case 13: a single commit batch that bridges two (or
##    three) previously separate same-kind projects merges them all into
##    one project keyed by the LOWEST (earliest-created) id, absorbing the
##    others' cells AND worker-attribution history — deterministically,
##    regardless of the batch cell array's iteration order.
## 3. Reverse index: [method BuildProjectRegistry.project_at_cell] returns
##    the owning project id for every one of a project's cells in O(1), and
##    `-1` for a cell no project tracks.
## 4. Same-kind filter (Implementation Notes): an adjacent existing project
##    of a DIFFERENT [enum BuildProject.Kind] never merges — the future
##    dig-partition story's own edge-case coverage is out of reach here, but
##    the filter itself is this story's own contract.
## 5. Union-find correctness for a single batch: mutually-adjacent NEW
##    cells (touching no existing project) still land in one fresh project;
##    conversely, non-adjacent new cells that touch no shared project
##    deliberately land in SEPARATE projects (Rule 14d's full batch-force
##    guarantee is explicitly Story building-018's own future scope, not
##    this story's).
## 6. Registry-level wrappers ([method BuildProjectRegistry.release_project]/
##    [method BuildProjectRegistry.on_job_claimed]) delegate correctly to
##    the resolved project, and no-op (`false`) for an unknown id.
class_name GroupingMergeReverseIndexTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _new_registry() -> BuildProjectRegistry:
	return BuildProjectRegistry.new()


func _planned_cell(cell: Vector3i) -> BlueprintCell:
	return BlueprintCell.new(cell, BlueprintCell.MicroState.PLANNED)


func _planned_cells(cells: Array[Vector3i]) -> Array[BlueprintCell]:
	var result: Array[BlueprintCell] = []
	for cell: Vector3i in cells:
		result.append(_planned_cell(cell))
	return result


# ---------------------------------------------------------------------------
# AC55 — two separate commits whose cells are 26-adjacent merge into one
# project; a one-cell gap does not merge
# ---------------------------------------------------------------------------

func test_diagonal_adjacent_commits_merge_into_one_project() -> void:
	# Arrange — F6's own worked example: (4,1,4) and (5,1,5), a purely
	# diagonal touch, chebyshev distance 1.
	var registry: BuildProjectRegistry = _new_registry()
	var first_cell := Vector3i(4, 1, 4)
	var second_cell := Vector3i(5, 1, 5)

	# Act — two separate commits.
	registry.assign_cells(_planned_cells([first_cell]))
	registry.assign_cells(_planned_cells([second_cell]))

	# Assert — exactly one project tracks both cells.
	var owning_id: int = registry.project_at_cell(first_cell)
	assert_int(owning_id).is_greater(-1)
	assert_int(registry.project_at_cell(second_cell)).is_equal(owning_id)
	assert_int(registry.get_projects().size()).is_equal(1)
	assert_int(registry.get_project(owning_id).get_cells().size()).is_equal(2)


func test_one_cell_gap_between_commits_does_not_merge() -> void:
	# Arrange — F6's own worked example: (4,1,4) and (6,1,4), distance 2.
	var registry: BuildProjectRegistry = _new_registry()
	var first_cell := Vector3i(4, 1, 4)
	var second_cell := Vector3i(6, 1, 4)

	# Act
	registry.assign_cells(_planned_cells([first_cell]))
	registry.assign_cells(_planned_cells([second_cell]))

	# Assert — two distinct projects, no merge.
	var first_id: int = registry.project_at_cell(first_cell)
	var second_id: int = registry.project_at_cell(second_cell)
	assert_int(first_id).is_not_equal(second_id)
	assert_int(registry.get_projects().size()).is_equal(2)


# ---------------------------------------------------------------------------
# AC56 / Edge Case 13 — a single batch bridging existing projects merges
# deterministically into the lowest id, order-independent
# ---------------------------------------------------------------------------

func test_batch_bridging_two_projects_merges_into_lower_id() -> void:
	# Arrange — P1 at (0,0,0), P2 at (2,0,0) — 2 apart, not directly
	# adjacent — bridged by a single commit at (1,0,0).
	var registry: BuildProjectRegistry = _new_registry()
	var p1_cell := Vector3i(0, 0, 0)
	var p2_cell := Vector3i(2, 0, 0)
	var bridge_cell := Vector3i(1, 0, 0)

	var p1_result: Array[BuildProject] = registry.assign_cells(_planned_cells([p1_cell]))
	var p2_result: Array[BuildProject] = registry.assign_cells(_planned_cells([p2_cell]))
	var lower_id: int = mini(p1_result[0].id, p2_result[0].id)
	var higher_id: int = maxi(p1_result[0].id, p2_result[0].id)

	# Act — the bridging commit.
	registry.assign_cells(_planned_cells([bridge_cell]))

	# Assert — one surviving project, keyed by the lower id, owns all 3
	# cells; the higher id no longer exists.
	assert_int(registry.project_at_cell(p1_cell)).is_equal(lower_id)
	assert_int(registry.project_at_cell(p2_cell)).is_equal(lower_id)
	assert_int(registry.project_at_cell(bridge_cell)).is_equal(lower_id)
	assert_object(registry.get_project(higher_id)).is_null()
	assert_int(registry.get_project(lower_id).get_cells().size()).is_equal(3)


func test_bridging_merge_absorbs_worker_attribution_history() -> void:
	# Arrange — Rule 14c: "absorbs the others' cells and worker-attribution
	# records."
	var registry: BuildProjectRegistry = _new_registry()
	var p1_cell := Vector3i(0, 0, 0)
	var p2_cell := Vector3i(2, 0, 0)
	var bridge_cell := Vector3i(1, 0, 0)
	registry.assign_cells(_planned_cells([p1_cell]))
	registry.assign_cells(_planned_cells([p2_cell]))
	var p1_id: int = registry.project_at_cell(p1_cell)
	var p2_id: int = registry.project_at_cell(p2_cell)
	registry.on_job_claimed(p1_id, p1_cell, 42)
	registry.on_job_claimed(p2_id, p2_cell, 99)

	# Act
	registry.assign_cells(_planned_cells([bridge_cell]))
	var survivor_id: int = registry.project_at_cell(p1_cell)

	# Assert — the surviving project's worker_ids include both villagers.
	var worker_ids: Array[int] = registry.get_project(survivor_id).worker_ids
	assert_array(worker_ids).contains([42, 99])


func test_bridging_merge_is_order_independent_across_batch_shuffles() -> void:
	# Arrange — a 4-cell bridge chain connecting P1 at (0,0,0) to P2 at
	# (5,0,0); run twice with the bridge batch's cells in different orders.
	var bridge_cells: Array[Vector3i] = [
		Vector3i(1, 0, 0), Vector3i(2, 0, 0), Vector3i(3, 0, 0), Vector3i(4, 0, 0)
	]
	var shuffled_cells: Array[Vector3i] = [
		Vector3i(4, 0, 0), Vector3i(1, 0, 0), Vector3i(3, 0, 0), Vector3i(2, 0, 0)
	]

	var registry_a: BuildProjectRegistry = _new_registry()
	registry_a.assign_cells(_planned_cells([Vector3i(0, 0, 0)]))
	registry_a.assign_cells(_planned_cells([Vector3i(5, 0, 0)]))
	registry_a.assign_cells(_planned_cells(bridge_cells))

	var registry_b: BuildProjectRegistry = _new_registry()
	registry_b.assign_cells(_planned_cells([Vector3i(0, 0, 0)]))
	registry_b.assign_cells(_planned_cells([Vector3i(5, 0, 0)]))
	registry_b.assign_cells(_planned_cells(shuffled_cells))

	# Assert — identical surviving id and total membership regardless of
	# the bridging batch's internal cell order.
	var id_a: int = registry_a.project_at_cell(Vector3i(0, 0, 0))
	var id_b: int = registry_b.project_at_cell(Vector3i(0, 0, 0))
	assert_int(id_a).is_equal(id_b)
	assert_int(registry_a.get_projects().size()).is_equal(1)
	assert_int(registry_b.get_projects().size()).is_equal(1)
	assert_int(registry_a.get_project(id_a).get_cells().size()).is_equal(6)
	assert_int(registry_b.get_project(id_b).get_cells().size()).is_equal(6)


func test_three_way_bridge_merges_all_into_lowest_id() -> void:
	# Arrange — P1 (0,0,0), P2 (2,0,0), P3 (4,0,0) — each 2 apart, not
	# directly touching — bridged transitively through the shared hub P2 by
	# ONE batch: (1,0,0) links P1<->P2, (3,0,0) links P2<->P3. Proves
	# transitive merging via a shared existing project, not just a direct
	# pairwise bridge.
	var registry: BuildProjectRegistry = _new_registry()
	registry.assign_cells(_planned_cells([Vector3i(0, 0, 0)]))
	registry.assign_cells(_planned_cells([Vector3i(2, 0, 0)]))
	registry.assign_cells(_planned_cells([Vector3i(4, 0, 0)]))
	var lowest_id: int = mini(
		mini(
			registry.project_at_cell(Vector3i(0, 0, 0)),
			registry.project_at_cell(Vector3i(2, 0, 0))
		),
		registry.project_at_cell(Vector3i(4, 0, 0))
	)

	# Act
	registry.assign_cells(_planned_cells([Vector3i(1, 0, 0), Vector3i(3, 0, 0)]))

	# Assert — exactly one project remains, keyed by the lowest id, owning
	# all 5 cells.
	assert_int(registry.get_projects().size()).is_equal(1)
	assert_int(registry.project_at_cell(Vector3i(0, 0, 0))).is_equal(lowest_id)
	assert_int(registry.project_at_cell(Vector3i(2, 0, 0))).is_equal(lowest_id)
	assert_int(registry.project_at_cell(Vector3i(4, 0, 0))).is_equal(lowest_id)
	assert_int(registry.get_project(lowest_id).get_cells().size()).is_equal(5)


# ---------------------------------------------------------------------------
# Reverse index — O(1) owning-project lookup per cell; -1 for untracked
# ---------------------------------------------------------------------------

func test_project_at_cell_returns_owning_id_for_every_cell() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0)]

	# Act
	var result: Array[BuildProject] = registry.assign_cells(_planned_cells(cells))
	var project_id: int = result[0].id

	# Assert — every cell resolves back to the same owning project.
	for cell: Vector3i in cells:
		assert_int(registry.project_at_cell(cell)).is_equal(project_id)


func test_project_at_cell_returns_negative_one_for_untracked_cell() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()
	registry.assign_cells(_planned_cells([Vector3i(0, 0, 0)]))

	# Act / Assert — a cell no project has ever tracked.
	assert_int(registry.project_at_cell(Vector3i(99, 99, 99))).is_equal(-1)


# ---------------------------------------------------------------------------
# Same-kind filter — an adjacent project of a different kind never merges
# ---------------------------------------------------------------------------

func test_adjacent_different_kind_project_does_not_merge() -> void:
	# Arrange — a BUILD-kind project already occupies (0,0,0).
	var registry: BuildProjectRegistry = _new_registry()
	var build_cell := Vector3i(0, 0, 0)
	var dig_cell := Vector3i(1, 0, 0)
	registry.assign_cells(_planned_cells([build_cell]), BuildProject.Kind.BUILD)

	# Act — a DIG-kind commit 26-adjacent to the BUILD cell.
	registry.assign_cells(_planned_cells([dig_cell]), BuildProject.Kind.DIG)

	# Assert — two separate projects; the dig cell never joined the build
	# project despite being adjacent.
	var build_id: int = registry.project_at_cell(build_cell)
	var dig_id: int = registry.project_at_cell(dig_cell)
	assert_int(build_id).is_not_equal(dig_id)
	assert_int(registry.get_project(build_id).kind).is_equal(BuildProject.Kind.BUILD)
	assert_int(registry.get_project(dig_id).kind).is_equal(BuildProject.Kind.DIG)


# ---------------------------------------------------------------------------
# Union-find correctness within a single batch
# ---------------------------------------------------------------------------

func test_mutually_adjacent_new_cells_in_one_batch_form_one_project() -> void:
	# Arrange — two new cells, diagonally adjacent, touching no existing
	# project.
	var registry: BuildProjectRegistry = _new_registry()
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(1, 1, 1)]

	# Act
	var result: Array[BuildProject] = registry.assign_cells(_planned_cells(cells))

	# Assert
	assert_int(result.size()).is_equal(1)
	assert_int(result[0].get_cells().size()).is_equal(2)


func test_non_adjacent_new_cells_in_one_batch_form_separate_projects() -> void:
	# Arrange — two new cells, far apart, touching no existing project and
	# not mutually 26-adjacent. Rule 14d's full batch-force guarantee
	# (Story building-018) deliberately does not apply here (see class doc
	# comment) — pure F6 adjacency governs this story's own grouping.
	var registry: BuildProjectRegistry = _new_registry()
	var cells: Array[Vector3i] = [Vector3i(0, 0, 0), Vector3i(10, 10, 10)]

	# Act
	var result: Array[BuildProject] = registry.assign_cells(_planned_cells(cells))

	# Assert
	assert_int(result.size()).is_equal(2)
	assert_int(registry.get_projects().size()).is_equal(2)


# ---------------------------------------------------------------------------
# Registry-level wrappers (ADR-0016 Key Interfaces, delegated to the
# resolved BuildProject)
# ---------------------------------------------------------------------------

func test_release_project_wrapper_delegates_to_resolved_project() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()
	var result: Array[BuildProject] = registry.assign_cells(_planned_cells([Vector3i(0, 0, 0)]))
	var project_id: int = result[0].id

	# Act
	var released: bool = registry.release_project(project_id)

	# Assert
	assert_bool(released).is_true()
	assert_int(registry.get_project(project_id).state).is_equal(BuildProject.ProjectState.BUILDING)


func test_release_project_returns_false_for_unknown_id() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()

	# Act / Assert
	assert_bool(registry.release_project(999)).is_false()


func test_on_job_claimed_wrapper_delegates_to_resolved_project() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()
	var cell := Vector3i(0, 0, 0)
	var result: Array[BuildProject] = registry.assign_cells(_planned_cells([cell]))
	var project_id: int = result[0].id

	# Act
	var claimed: bool = registry.on_job_claimed(project_id, cell, 7)

	# Assert
	assert_bool(claimed).is_true()
	assert_array(registry.get_project(project_id).worker_ids).contains([7])


func test_on_job_claimed_returns_false_for_unknown_id() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()

	# Act / Assert
	assert_bool(registry.on_job_claimed(999, Vector3i(0, 0, 0), 7)).is_false()


func test_get_project_returns_null_for_unknown_id() -> void:
	# Arrange
	var registry: BuildProjectRegistry = _new_registry()

	# Act / Assert
	assert_object(registry.get_project(999)).is_null()
	assert_bool(registry.has_project(999)).is_false()
