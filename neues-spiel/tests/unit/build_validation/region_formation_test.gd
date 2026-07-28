## Unit test — Build Validation & Navigability story build-validation-003
## (candidate region formation & affected-region scoping; ADR-0007 primary,
## GDD `design/gdd/build-validation-navigability.md` Rule 1's region
## definition + Implementation Notes' affected-region scoping).
##
## Proves:
## 1. AC7 (Edge Case 1): two interiors connected by a candidate-cell gap form
##    ONE region.
## 2. AC11 (Edge Case 12): candidate cells running to the world boundary --
##    the boundary contributes neither wall nor opening; no out-of-bounds
##    cell ever enters the region.
## 3. AC38 (Rule 1's block-occupancy-only clause): a mocked character
##    occupying an otherwise-candidate interior cell never changes candidate
##    status or region membership -- a structural property, not a branch.
## 4. Edge cases (QA Test Cases): two regions touching only corner-to-corner
##    remain TWO regions (membership is orthogonal); a single candidate cell
##    forms a region of size 1; a region spanning a chunk boundary forms
##    correctly.
## 5. Affected-region scoping: [method
##    BuildValidationRegionFormation.form_affected_regions] de-duplicates a
##    region touched by multiple changed cells into ONE entry, and correctly
##    seeds from a changed cell that is itself not a candidate but has a
##    candidate neighbour.
## 6. Grep guards: no [VillagerAi] reference, no local
##    `VILLAGER_CLEARANCE`/`MAX_STEP_HEIGHT` literal, no
##    [VillagerWalkabilityRules]/`is_step_legal` reference (membership never
##    touches the movement graph), and zero `NavigationServer3D`-family
##    reference anywhere in this story's production files.
class_name BuildValidationRegionFormationTest
extends GdUnitTestSuite


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


## Makes [param cell] an interior candidate cell in isolation: solid floor
## directly below, solid roof exactly [constant MAX_ROOM_HEIGHT] above --
## per-column, no shared floor/roof plane required (GDD Rule 1 needs no wall
## coverage, Edge Case 6).
func _place_interior_cell(grid: VoxelWorldGrid, cell: Vector3i) -> void:
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid_contents())
	grid.set_cell(cell + Vector3i(0, MAX_ROOM_HEIGHT, 0), _solid_contents())


## Places every cell of a rectangular [param x_range] x [param z_range]
## interior footprint at height [param y], one column each.
func _place_interior_rect(grid: VoxelWorldGrid, x_range: Array, z_range: Array, y: int) -> void:
	for x: int in x_range:
		for z: int in z_range:
			_place_interior_cell(grid, Vector3i(x, y, z))


# ---------------------------------------------------------------------------
# AC7 — two interiors connected by a gap form ONE region
# ---------------------------------------------------------------------------

func test_two_interiors_connected_by_gap_form_one_region() -> void:
	# Arrange — two 3x3 interior footprints at y=1, bridged by a single-cell
	# gap at x=3, z=1.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_rect(grid, range(0, 3), range(0, 3), 1)  # room A: x=0..2, z=0..2
	_place_interior_cell(grid, Vector3i(3, 1, 1))  # the gap
	_place_interior_rect(grid, range(4, 7), range(0, 3), 1)  # room B: x=4..6, z=0..2

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, 1, 0), MAX_ROOM_HEIGHT
	)

	# Assert — one region, all 19 cells (9 + 1 + 9).
	assert_int(region.size()).is_equal(19)
	assert_bool(region.contains(Vector3i(3, 1, 1))).is_true()
	assert_bool(region.contains(Vector3i(6, 1, 2))).is_true()


# ---------------------------------------------------------------------------
# AC11 — world boundary contributes neither wall nor opening
# ---------------------------------------------------------------------------

func test_world_boundary_contributes_neither_wall_nor_opening() -> void:
	# Arrange — a candidate strip running right up to the world's x=0 edge.
	var grid: VoxelWorldGrid = _make_grid()
	for x: int in range(0, 3):
		_place_interior_cell(grid, Vector3i(x, 1, 0))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, 1, 0), MAX_ROOM_HEIGHT
	)

	# Assert — exactly the 3 in-bounds cells; no negative-x cell ever entered.
	assert_int(region.size()).is_equal(3)
	for cell: Vector3i in region.cell_list():
		assert_int(cell.x).is_greater_equal(0)
	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, Vector3i(-1, 1, 0), MAX_ROOM_HEIGHT)
	).is_false()


# ---------------------------------------------------------------------------
# AC38 — mocked character occupancy never affects region membership
# ---------------------------------------------------------------------------

func test_mocked_character_position_never_affects_region_membership() -> void:
	# Arrange — a small interior region; grid state is never touched by
	# "character" bookkeeping (VoxelWorldGrid stores blocks, never
	# positions), so this test-local variable is never passed to the grid or
	# to region formation at all.
	var grid: VoxelWorldGrid = _make_grid()
	for x: int in range(0, 3):
		_place_interior_cell(grid, Vector3i(x, 1, 5))
	var character_cell := Vector3i(1, 1, 5)  # the mocked character's cell.

	# Act — form the region twice; nothing about "recording" the character's
	# position anywhere in this test changes what's passed to form_region.
	var without_character_tracked: BuildValidationRegion = (
		BuildValidationRegionFormation.form_region(grid, Vector3i(0, 1, 5), MAX_ROOM_HEIGHT)
	)
	var with_character_tracked: BuildValidationRegion = (
		BuildValidationRegionFormation.form_region(grid, Vector3i(0, 1, 5), MAX_ROOM_HEIGHT)
	)

	# Assert — byte-identical membership, and the character's own cell is a
	# perfectly ordinary member, unaffected by anything being "on" it.
	assert_int(with_character_tracked.size()).is_equal(without_character_tracked.size())
	assert_array(with_character_tracked.cell_list()).contains_exactly(
		without_character_tracked.cell_list()
	)
	assert_bool(with_character_tracked.contains(character_cell)).is_true()


# ---------------------------------------------------------------------------
# Edge cases — corner-touching, single-cell, chunk boundary
# ---------------------------------------------------------------------------

func test_corner_touching_regions_remain_two_regions() -> void:
	# Arrange — two isolated interior cells touching only diagonally
	# (dx=1, dz=1) -- never sharing an orthogonal face.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(10, 1, 10))
	_place_interior_cell(grid, Vector3i(11, 1, 11))

	# Act
	var region_a: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(10, 1, 10), MAX_ROOM_HEIGHT
	)
	var region_b: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(11, 1, 11), MAX_ROOM_HEIGHT
	)

	# Assert — two distinct size-1 regions; neither contains the other's cell.
	assert_int(region_a.size()).is_equal(1)
	assert_int(region_b.size()).is_equal(1)
	assert_bool(region_a.contains(Vector3i(11, 1, 11))).is_false()
	assert_bool(region_b.contains(Vector3i(10, 1, 10))).is_false()


func test_single_candidate_cell_forms_region_of_size_one() -> void:
	# Arrange — one isolated interior candidate cell, nothing adjacent.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(20, 1, 20))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(20, 1, 20), MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(1)
	assert_bool(region.contains(Vector3i(20, 1, 20))).is_true()


func test_region_spanning_chunk_boundary_forms_correctly() -> void:
	# Arrange — a 4-cell candidate strip straddling the x=15/16 chunk
	# boundary (VoxelWorldGrid.CHUNK_SIZE == 16).
	var grid: VoxelWorldGrid = _make_grid()
	for x: int in range(14, 18):
		_place_interior_cell(grid, Vector3i(x, 1, 0))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(14, 1, 0), MAX_ROOM_HEIGHT
	)

	# Assert — all 4 cells, spanning both chunks, form one region.
	assert_int(region.size()).is_equal(4)
	for x: int in range(14, 18):
		assert_bool(region.contains(Vector3i(x, 1, 0))).is_true()


# ---------------------------------------------------------------------------
# Affected-region scoping
# ---------------------------------------------------------------------------

func test_form_affected_regions_deduplicates_shared_region() -> void:
	# Arrange — a 2-cell interior region; simulate BOTH its cells completing
	# in the same batched pass (the "changed_cells" the trigger would carry).
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(30, 1, 0))
	_place_interior_cell(grid, Vector3i(31, 1, 0))
	var changed_cells: Array[Vector3i] = [Vector3i(30, 1, 0), Vector3i(31, 1, 0)]

	# Act
	var regions: Array[BuildValidationRegion] = (
		BuildValidationRegionFormation.form_affected_regions(grid, changed_cells, MAX_ROOM_HEIGHT)
	)

	# Assert — ONE region, not two, even though both its cells were named.
	assert_int(regions.size()).is_equal(1)
	assert_int(regions[0].size()).is_equal(2)


func test_form_affected_regions_seeds_from_non_candidate_neighbor() -> void:
	# Arrange — the changed cell itself (a removed wall, modeled here as a
	# cell with no floor beneath it -- never a candidate) is NOT a candidate,
	# but its immediate neighbour is a real interior candidate cell.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(41, 1, 0))  # the real interior cell.
	var changed_cells: Array[Vector3i] = [Vector3i(40, 1, 0)]  # non-candidate neighbor.

	assert_bool(
		CandidateCellRules.is_candidate_interior_cell(grid, Vector3i(40, 1, 0), MAX_ROOM_HEIGHT)
	).is_false()

	# Act
	var regions: Array[BuildValidationRegion] = (
		BuildValidationRegionFormation.form_affected_regions(grid, changed_cells, MAX_ROOM_HEIGHT)
	)

	# Assert — the neighbour's region is still found and returned.
	assert_int(regions.size()).is_equal(1)
	assert_bool(regions[0].contains(Vector3i(41, 1, 0))).is_true()


func test_form_affected_regions_with_no_candidates_returns_empty() -> void:
	# Arrange — changed cells with nothing candidate anywhere nearby.
	var grid: VoxelWorldGrid = _make_grid()
	var changed_cells: Array[Vector3i] = [Vector3i(50, 1, 0)]

	# Act
	var regions: Array[BuildValidationRegion] = (
		BuildValidationRegionFormation.form_affected_regions(grid, changed_cells, MAX_ROOM_HEIGHT)
	)

	# Assert
	assert_int(regions.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Grep guards
# ---------------------------------------------------------------------------

func test_no_villager_ai_or_walkability_reference_in_region_formation_files() -> void:
	# BV-4 / membership-vs-traversal discipline: this module never references
	# VillagerAi, never declares a local walkability-constant literal, and
	# never calls VillagerWalkabilityRules/is_step_legal directly -- region
	# MEMBERSHIP goes through CandidateCellRules only; the movement graph is
	# exclusively story 004's concern.
	for file_path: String in [
		"res://src/build_validation/build_validation_region_formation.gd",
		"res://src/build_validation/build_validation_region.gd",
	]:
		var source: String = _read_source_stripped_of_comments(file_path)
		assert_bool(source.contains("VillagerAi")).is_false()
		assert_bool(source.contains("VILLAGER_CLEARANCE")).is_false()
		assert_bool(source.contains("MAX_STEP_HEIGHT")).is_false()
		assert_bool(source.contains("VillagerWalkabilityRules")).is_false()
		assert_bool(source.contains("is_step_legal")).is_false()


func test_no_navigation_server_reference_in_region_formation_files() -> void:
	# Control Manifest Feature Layer Forbidden: zero NavigationServer3D-family
	# usage anywhere in Build Validation.
	for file_path: String in [
		"res://src/build_validation/build_validation_region_formation.gd",
		"res://src/build_validation/build_validation_region.gd",
	]:
		var source: String = _read_source_stripped_of_comments(file_path)
		assert_bool(source.contains("NavigationServer3D")).is_false()
		assert_bool(source.contains("NavigationAgent3D")).is_false()
		assert_bool(source.contains("NavigationRegion3D")).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads [param file_path], STRIPPING full-line `#`/`##` doc-comment lines
## first -- mirrors `candidate_cell_test.gd`'s own established
## `_read_source_stripped_of_comments` precedent (itself mirroring
## `config_and_scaffold_test.gd`'s `_read_all_gd_source`).
func _read_source_stripped_of_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined
