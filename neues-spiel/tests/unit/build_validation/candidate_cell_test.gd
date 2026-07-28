## Unit test — Build Validation & Navigability story build-validation-002
## (candidate interior cell predicate, standable + roofed, furniture-
## transparent; ADR-0007 primary, TD rulings BV-1/BV-4 --
## `production/architecture-decisions-m02-preflight-2026-07-26.md`).
##
## Proves:
## 1. AC6 (Rule 1 boundary): a roof exactly `max_room_height` above an
##    interior cell -> candidate; one cell higher -> not.
## 2. AC23 (Rule 7, built-only): a blueprint-only would-be roof (never
##    written to the grid, by construction) does not count as solid -> not
##    roofed, not a candidate.
## 3. Furniture transparency (BV-1, proof-by-construction, [TR-build-
##    validation-navigability-022]): a cell recorded as furniture-occupied in
##    a stub registry, but absent from [VoxelWorldGrid] per BV-1, reads as a
##    candidate identically to the unoccupied case; furniture recorded at a
##    cell a structural role (here: the roof) would need never satisfies that
##    role, because it never reaches the grid. No `building-028` code is
##    required to run this test.
## 4. AC24 (Rule 2 verbatim-consumption): [CandidateCellRules] holds no local
##    copy of [VillagerWalkabilityRules]'s constants and delegates
##    standability to it exactly -- a non-standable fixture cell is never a
##    candidate, regardless of what sits above it.
## 5. Edge cases (QA Test Cases): a world-boundary cell is never a candidate;
##    a crawlspace (roof 2 above the floor) yields zero candidates; open sky
##    above an otherwise-standable cell is not a candidate.
class_name BuildValidationCandidateCellTest
extends GdUnitTestSuite


## Minimal duck-typed furniture-registry stub (BV-1 §5 shape: a nil-safe
## `Object` dependency exposing placed-item cells) -- `building-028` does not
## exist yet; this test-local stub exists purely to demonstrate the
## proof-by-construction property, never to be treated as the real registry's
## contract.
class _StubFurnitureRegistry:
	var occupied_cells: Array[Vector3i] = []


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

const MAX_ROOM_HEIGHT: int = 8


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _solid_contents() -> CellContents:
	return CellContents.new(1, 0)


# ---------------------------------------------------------------------------
# AC6 — roof-height boundary (both directions)
# ---------------------------------------------------------------------------

func test_roof_exactly_max_room_height_above_is_candidate() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(0, 1, 0)
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid_contents())  # floor
	grid.set_cell(cell + Vector3i(0, MAX_ROOM_HEIGHT, 0), _solid_contents())  # roof at the boundary

	# Act + Assert
	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, cell, MAX_ROOM_HEIGHT)
	).is_true()


func test_roof_one_cell_higher_than_max_room_height_is_not_candidate() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(0, 1, 0)
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid_contents())  # floor
	grid.set_cell(cell + Vector3i(0, MAX_ROOM_HEIGHT + 1, 0), _solid_contents())  # one cell too high

	# Act + Assert
	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, cell, MAX_ROOM_HEIGHT)
	).is_false()


# ---------------------------------------------------------------------------
# AC23 — blueprint-only would-be roof is never solid (built-only, Rule 7)
# ---------------------------------------------------------------------------

func test_blueprint_only_would_be_roof_is_not_roofed_or_candidate() -> void:
	# Arrange — a Planned blueprint cell is never written to VoxelWorldGrid
	# (Building System Core Rule 14b; the identical mechanism BV-1 relies on
	# for furniture). This test models the "would-be roof" a Planned blueprint
	# occupies by deliberately leaving that cell untouched in the grid, and
	# proves it therefore does not count as solid.
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(0, 1, 0)
	var would_be_roof_cell: Vector3i = cell + Vector3i(0, 3, 0)
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid_contents())  # floor only

	# Act + Assert
	assert_bool(grid.get_cell(would_be_roof_cell).is_empty()).is_true()
	assert_bool(CandidateCellRules.is_roofed(grid, cell, MAX_ROOM_HEIGHT)).is_false()
	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, cell, MAX_ROOM_HEIGHT)
	).is_false()


# ---------------------------------------------------------------------------
# Furniture transparency — proof by construction (BV-1)
# ---------------------------------------------------------------------------

func test_furniture_occupied_cell_reads_identical_to_unoccupied_cell() -> void:
	# Arrange — a valid interior candidate cell.
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(2, 1, 2)
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid_contents())  # floor
	grid.set_cell(cell + Vector3i(0, MAX_ROOM_HEIGHT, 0), _solid_contents())  # roof

	var without_furniture_recorded: bool = CandidateCellRules.is_candidate_interior_cell(
		grid, cell, MAX_ROOM_HEIGHT
	)

	# Act — record the SAME cell as furniture-occupied in a stub registry.
	# Per BV-1, furniture never enters VoxelWorldGrid, so the grid read at
	# this cell is unaffected, and CandidateCellRules has no furniture-aware
	# parameter to even consult.
	var registry := _StubFurnitureRegistry.new()
	registry.occupied_cells = [cell]
	assert_bool(grid.get_cell(cell).is_empty()).is_true()

	var with_furniture_recorded: bool = CandidateCellRules.is_candidate_interior_cell(
		grid, cell, MAX_ROOM_HEIGHT
	)

	# Assert — identical candidate status, and both are candidates.
	assert_bool(with_furniture_recorded).is_equal(without_furniture_recorded)
	assert_bool(with_furniture_recorded).is_true()


func test_furniture_placed_at_a_required_roof_cell_does_not_satisfy_the_roof_role() -> void:
	# Arrange — furniture "placed" (per stub bookkeeping only) at exactly the
	# cell a roof would need to occupy, well within max_room_height.
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(4, 1, 4)
	var roof_cell: Vector3i = cell + Vector3i(0, 3, 0)
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid_contents())  # floor only

	var registry := _StubFurnitureRegistry.new()
	registry.occupied_cells = [roof_cell]

	# Act + Assert — the registry's bookkeeping never reaches the grid (BV-1),
	# so the roof role is NOT satisfied and the cell below stays uncandidate.
	assert_bool(grid.get_cell(roof_cell).is_empty()).is_true()
	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, cell, MAX_ROOM_HEIGHT)
	).is_false()


# ---------------------------------------------------------------------------
# AC24 — verbatim consumption of shared walkability rules (no local copy)
# ---------------------------------------------------------------------------

func test_standability_delegates_to_shared_walkability_rules_exactly() -> void:
	# Arrange — a fixture set including a non-standable cell (nothing solid
	# below) and an out-of-bounds cell, each given a roof so ONLY the
	# standability half of the predicate can be responsible for a "not
	# candidate" verdict.
	var grid: VoxelWorldGrid = _make_grid()
	var non_standable_cell := Vector3i(0, 4, 0)  # nothing solid below at y=3.
	var out_of_bounds_cell := Vector3i(-1, 1, 0)
	for cell: Vector3i in [non_standable_cell, out_of_bounds_cell]:
		grid.set_cell(cell + Vector3i(0, MAX_ROOM_HEIGHT, 0), _solid_contents())

	# Act + Assert — every fixture cell fails VillagerWalkabilityRules.
	# is_standable(), and CandidateCellRules must agree exactly (proving
	# delegation, not a local re-implementation with its own constants).
	for cell: Vector3i in [non_standable_cell, out_of_bounds_cell]:
		assert_bool(VillagerWalkabilityRules.is_standable(grid, cell)).is_false()
		assert_bool(
			CandidateCellRules.is_candidate_interior_cell(grid, cell, MAX_ROOM_HEIGHT)
		).is_false()


func test_no_villager_clearance_or_max_step_height_literal_in_candidate_cell_rules() -> void:
	# This story's own dedicated verbatim-consumption guard (QA plan):
	# CandidateCellRules must never DECLARE a local copy of either shared
	# walkability constant. Doc comments legitimately NAME both identifiers
	# to document that no local copy exists (this class's own doc comments
	# do exactly that) -- so, mirroring
	# `tests/integration/build_validation/config_and_scaffold_test.gd`'s
	# established `_read_all_gd_source` precedent, comment lines are
	# stripped before scanning; a naive raw-text scan would flag the
	# compliance documentation itself as a violation.
	var source: String = _read_source_stripped_of_comments(
		"res://src/build_validation/candidate_cell_rules.gd"
	)

	assert_bool(source.contains("VILLAGER_CLEARANCE")).is_false()
	assert_bool(source.contains("MAX_STEP_HEIGHT")).is_false()


func test_no_villager_ai_type_reference_in_candidate_cell_rules() -> void:
	# BV-4: the walkability call form is VillagerWalkabilityRules.<fn>(...),
	# never an injected VillagerAi reference of any kind. Comment-stripped
	# for the same reason as the guard above.
	var source: String = _read_source_stripped_of_comments(
		"res://src/build_validation/candidate_cell_rules.gd"
	)

	assert_bool(source.contains("VillagerAi")).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads [param file_path], STRIPPING full-line `#`/`##` doc-comment lines
## first -- mirrors
## `tests/integration/build_validation/config_and_scaffold_test.gd`'s
## `_read_all_gd_source` helper (this codebase's established precedent).
func _read_source_stripped_of_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


# ---------------------------------------------------------------------------
# Edge cases — world boundary, crawlspace, open sky
# ---------------------------------------------------------------------------

func test_world_boundary_cell_is_never_a_candidate() -> void:
	# Arrange — an out-of-bounds cell: never solid, never passable.
	var grid: VoxelWorldGrid = _make_grid()
	var out_of_bounds_cell := Vector3i(-1, 1, 0)

	# Act + Assert
	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, out_of_bounds_cell, MAX_ROOM_HEIGHT)
	).is_false()


func test_crawlspace_roof_two_above_floor_yields_zero_candidates() -> void:
	# Arrange — Edge Case 13: a roof sitting 1-2 cells above the floor fails
	# standability's clearance check before the roof scan ever runs.
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(0, 1, 0)
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())  # floor
	grid.set_cell(Vector3i(0, 2, 0), _solid_contents())  # roof only 2 above the floor

	# Act + Assert
	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, cell, MAX_ROOM_HEIGHT)
	).is_false()


func test_open_sky_above_standable_cell_is_not_candidate() -> void:
	# Arrange — a standable cell with nothing solid anywhere above it.
	var grid: VoxelWorldGrid = _make_grid()
	var cell := Vector3i(0, 1, 0)
	grid.set_cell(Vector3i(0, 0, 0), _solid_contents())  # floor only

	# Act + Assert
	assert_bool(VillagerWalkabilityRules.is_standable(grid, cell)).is_true()
	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, cell, MAX_ROOM_HEIGHT)
	).is_false()
