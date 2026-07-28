## Integration test — Voxel World story vox-004 (neighbor lookup + DDA
## cell-picking, ADR-0004 Decision + ADR-0014 Decision Section 4;
## TR-voxel-world-031/017/049/047/018).
##
## Proves, all against [VoxelWorldGrid.get_neighbors] / [VoxelWorldGrid.raycast_cells]
## / [RaycastHitResult]:
## 1. [method get_neighbors]: 6 face-adjacent offsets for an interior cell;
##    world-edge cells (origin corner, max_y ceiling) omit the out-of-bounds
##    offsets entirely rather than including an invalid/sentinel entry
##    (TR-voxel-world-031, Story 001's out-of-grid rule).
## 2. AC-1 (TR-voxel-world-049/017): a raycast from OUTSIDE the grid toward a
##    single occupied cell at (5,0,0) returns that cell as the first hit, with
##    the correct entry-face normal; a ray missing all cells returns a miss.
##    Edge cases: ray origin embedded in an occupied cell (immediate hit,
##    normal ZERO); a ray exiting world bounds without hitting anything
##    returns a miss; `max_distance` truncation before reaching a farther
##    solid cell returns a miss.
## 3. AC-2 (TR-voxel-world-047): 10,000 repeated raycasts against a populated
##    grid leave the grid snapshot byte-identical (read purity under load).
## 4. AC-3 (TR-voxel-world-018): grep `intersect_ray|PhysicsServer3D|RayCast3D`
##    over `src/voxel_world/` returns zero matches — asserted via a
##    comment-stripped source scan (this codebase's established precedent,
##    see `tests/integration/scene_world_management/world_root_valley_attach_test.gd`'s
##    `_read_all_gd_source` helper) so this file's OWN doc comments (which
##    legitimately name the banned APIs to document their absence) are never
##    mistaken for a violation.
## 5. The [param extra_solid] predicate hook (signature extensibility the
##    story requires, ADR-0014 Section 4): a supplied `Callable` can mark an
##    otherwise-empty cell as solid; omitting it (the default) behaves
##    identically to every other test in this file.
class_name DdaRaycastTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# get_neighbors — 6 face-adjacent offsets, bounds-filtered
# ---------------------------------------------------------------------------

func test_get_neighbors_interior_cell_returns_all_6_offsets() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var neighbors: Array[Vector3i] = grid.get_neighbors(Vector3i(100, 8, 100))

	# Assert
	assert_int(neighbors.size()).is_equal(6)
	var expected: Array[Vector3i] = [
		Vector3i(101, 8, 100), Vector3i(99, 8, 100),
		Vector3i(100, 9, 100), Vector3i(100, 7, 100),
		Vector3i(100, 8, 101), Vector3i(100, 8, 99),
	]
	for e: Vector3i in expected:
		assert_bool(neighbors.has(e)).is_true()


func test_get_neighbors_at_world_origin_omits_out_of_bounds_negative_offsets() -> void:
	# Arrange — cell (0, 0, 0): x-1, y-1, z-1 are all out of bounds (Core Rule 1
	# fixed origin, min_y = 0 default) — only 3 of 6 offsets survive.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var neighbors: Array[Vector3i] = grid.get_neighbors(Vector3i(0, 0, 0))

	# Assert
	assert_int(neighbors.size()).is_equal(3)
	assert_bool(neighbors.has(Vector3i(1, 0, 0))).is_true()
	assert_bool(neighbors.has(Vector3i(0, 1, 0))).is_true()
	assert_bool(neighbors.has(Vector3i(0, 0, 1))).is_true()
	assert_bool(neighbors.has(Vector3i(-1, 0, 0))).is_false()
	assert_bool(neighbors.has(Vector3i(0, -1, 0))).is_false()
	assert_bool(neighbors.has(Vector3i(0, 0, -1))).is_false()


func test_get_neighbors_at_max_y_ceiling_omits_plus_y_neighbor() -> void:
	# Arrange — GDD default max_y = 16 (inclusive upper bound).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var neighbors: Array[Vector3i] = grid.get_neighbors(Vector3i(50, 16, 50))

	# Assert
	assert_int(neighbors.size()).is_equal(5)
	assert_bool(neighbors.has(Vector3i(50, 17, 50))).is_false()
	assert_bool(neighbors.has(Vector3i(50, 15, 50))).is_true()


func test_get_neighbors_at_max_width_boundary_omits_plus_x_neighbor() -> void:
	# Arrange — width is an exclusive upper bound (valid indices 0..width-1).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 256
	grid.config = config

	# Act
	var neighbors: Array[Vector3i] = grid.get_neighbors(Vector3i(255, 8, 100))

	# Assert
	assert_bool(neighbors.has(Vector3i(256, 8, 100))).is_false()
	assert_bool(neighbors.has(Vector3i(254, 8, 100))).is_true()


func test_get_neighbors_missing_config_raises_assertion() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())

	# Act + Assert
	await assert_error(func() -> void: grid.get_neighbors(Vector3i.ZERO)).is_runtime_error(
		"Assertion failed: VoxelWorldGrid.config not wired"
	)


# ---------------------------------------------------------------------------
# AC-1 (TR-voxel-world-049/017) — raycast first-hit, from OUTSIDE the grid
# ---------------------------------------------------------------------------

func test_raycast_from_outside_grid_hits_first_occupied_cell_with_entry_normal() -> void:
	# Arrange — QA plan AC-1 worked example: single occupied cell at (5,0,0),
	# ray from (-1, 0.5, 0.5) toward +x. Origin's floored cell (-1,0,0) is
	# itself OUTSIDE the grid (x < 0) — the walk must still enter and hit.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(5, 0, 0), CellContents.new(11, 0))

	# Act
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(-1.0, 0.5, 0.5), Vector3(1.0, 0.0, 0.0), 200.0
	)

	# Assert
	assert_bool(result.hit).is_true()
	assert_vector(Vector3(result.cell)).is_equal(Vector3(5, 0, 0))
	assert_vector(Vector3(result.normal)).is_equal(Vector3(-1, 0, 0))


func test_raycast_missing_all_cells_returns_miss() -> void:
	# Arrange — QA plan AC-1: a ray missing all cells returns none. Same
	# occupied cell as above, but aimed away from it (-x direction).
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(5, 0, 0), CellContents.new(11, 0))

	# Act
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(50.5, 0.5, 0.5), Vector3(0.0, 1.0, 0.0), 200.0
	)

	# Assert
	assert_bool(result.hit).is_false()


func test_raycast_origin_embedded_in_occupied_cell_hits_immediately_with_zero_normal() -> void:
	# Arrange — edge case: ray origin inside an occupied cell.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(3, 3, 3), CellContents.new(11, 0))

	# Act
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(3.5, 3.5, 3.5), Vector3(1.0, 0.0, 0.0), 200.0
	)

	# Assert
	assert_bool(result.hit).is_true()
	assert_vector(Vector3(result.cell)).is_equal(Vector3(3, 3, 3))
	assert_vector(Vector3(result.normal)).is_equal(Vector3.ZERO)


func test_raycast_exiting_world_bounds_without_hit_returns_miss() -> void:
	# Arrange — edge case: ray exiting world bounds (traveling straight up
	# past max_y, an empty column) returns none rather than erroring.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(10.5, 0.5, 10.5), Vector3(0.0, 1.0, 0.0), 200.0
	)

	# Assert
	assert_bool(result.hit).is_false()


func test_raycast_grazing_cell_edge_uses_floor_semantics_consistently() -> void:
	# Arrange — edge case: a ray grazing exactly along a cell boundary plane
	# (y = 4.0 exactly, matching world_to_cell's floor()-into-next-cell
	# convention already established for the coordinate math, story vox-001)
	# still resolves deterministically to a single occupied cell.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(8, 4, 0), CellContents.new(11, 0))

	# Act — origin sits exactly on the y=4.0 boundary plane; traveling +x.
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(0.0, 4.0, 0.5), Vector3(1.0, 0.0, 0.0), 200.0
	)

	# Assert — floor(4.0) = 4, so the ray travels through cell-row y=4 and
	# hits the occupied cell there, exactly as world_to_cell's own boundary
	# convention predicts.
	assert_bool(result.hit).is_true()
	assert_vector(Vector3(result.cell)).is_equal(Vector3(8, 4, 0))


func test_raycast_max_distance_truncates_before_farther_solid_cell() -> void:
	# Arrange — a solid cell exists, but max_distance is too short to reach it.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(50, 0, 0), CellContents.new(11, 0))

	# Act
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(0.5, 0.5, 0.5), Vector3(1.0, 0.0, 0.0), 5.0
	)

	# Assert
	assert_bool(result.hit).is_false()


func test_raycast_zero_length_direction_returns_miss_without_crash() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()

	# Act
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(0.5, 0.5, 0.5), Vector3.ZERO, 200.0
	)

	# Assert
	assert_bool(result.hit).is_false()


func test_raycast_missing_config_raises_assertion() -> void:
	# Arrange
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())

	# Act + Assert
	await assert_error(func() -> void: grid.raycast_cells(Vector3.ZERO, Vector3(1, 0, 0), 10.0)).is_runtime_error(
		"Assertion failed: VoxelWorldGrid.config not wired"
	)


# ---------------------------------------------------------------------------
# extra_solid predicate hook — signature extensibility (ADR-0014 Section 4)
# ---------------------------------------------------------------------------

func test_raycast_extra_solid_predicate_marks_otherwise_empty_cell_as_solid() -> void:
	# Arrange — no real cell data at all; the predicate alone decides.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	var ghost_cell := Vector3i(4, 0, 0)
	var predicate := func(cell: Vector3i) -> bool: return cell == ghost_cell

	# Act
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(0.5, 0.5, 0.5), Vector3(1.0, 0.0, 0.0), 200.0, predicate
	)

	# Assert
	assert_bool(result.hit).is_true()
	assert_vector(Vector3(result.cell)).is_equal(Vector3(4, 0, 0))


func test_raycast_default_extra_solid_omitted_behaves_as_plain_dda() -> void:
	# Arrange — QA-plan-adjacent: not passing extra_solid at all must behave
	# identically to every other real-data-only test in this file.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(5, 0, 0), CellContents.new(11, 0))

	# Act
	var result: RaycastHitResult = grid.raycast_cells(
		Vector3(0.5, 0.5, 0.5), Vector3(1.0, 0.0, 0.0), 200.0
	)

	# Assert
	assert_bool(result.hit).is_true()
	assert_vector(Vector3(result.cell)).is_equal(Vector3(5, 0, 0))


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-047) — read purity across 10,000 repeated raycasts
# ---------------------------------------------------------------------------

func test_repeated_raycasts_do_not_mutate_grid_state() -> void:
	# Arrange — a small populated grid; snapshot several cells before the load.
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.set_cell(Vector3i(5, 0, 0), CellContents.new(11, 3))
	grid.set_cell(Vector3i(20, 4, 20), CellContents.new(9, 1))
	grid.set_cell(Vector3i(0, 0, 0), CellContents.new(5, 0))
	var probe_cells: Array[Vector3i] = [Vector3i(5, 0, 0), Vector3i(20, 4, 20), Vector3i(0, 0, 0)]
	var snapshot: Array[Dictionary] = []
	for cell: Vector3i in probe_cells:
		var contents: CellContents = grid.get_cell(cell)
		snapshot.append({"block_type_id": contents.block_type_id, "material_id": contents.material_id})

	# Act — 10,000 repeated raycasts (QA plan AC-2), a mix of hits and misses.
	for i in 10000:
		grid.raycast_cells(Vector3(-1.0, 0.5, 0.5), Vector3(1.0, 0.0, 0.0), 200.0)
		grid.raycast_cells(Vector3(0.5, 0.5, 0.5), Vector3(0.0, 1.0, 0.0), 200.0)
		if i % 1000 == 0:
			grid.raycast_cells(Vector3(500.5, 5.5, 500.5), Vector3(1.0, 1.0, 1.0), 50.0)

	# Assert — every probe cell's contents are still byte-identical.
	for i in probe_cells.size():
		var contents: CellContents = grid.get_cell(probe_cells[i])
		assert_int(contents.block_type_id).is_equal(snapshot[i]["block_type_id"])
		assert_int(contents.material_id).is_equal(snapshot[i]["material_id"])


# ---------------------------------------------------------------------------
# AC-3 (TR-voxel-world-018) — zero physics APIs anywhere in Voxel World
# ---------------------------------------------------------------------------

func test_no_physics_apis_anywhere_in_voxel_world_source() -> void:
	# Grep-verifiable AC: intersect_ray/PhysicsServer3D/RayCast3D must be
	# absent from src/voxel_world/'s own CODE (comment-stripped -- see class
	# doc comment for why raw-text scanning would false-positive on this
	# system's own compliance documentation, including this test file's own
	# doc comments naming these exact banned identifiers above).
	var source: String = _read_all_gd_source("res://src/voxel_world")

	var banned_substrings: Array[String] = [
		"intersect_ray",
		"PhysicsServer3D",
		"RayCast3D",
		"PhysicsDirectSpaceState3D",
	]
	for banned: String in banned_substrings:
		assert_bool(source.contains(banned)).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive -- Voxel World's directory is flat),
## STRIPPING full-line `#`/`##` doc-comment lines first. Mirrors
## `tests/integration/scene_world_management/world_root_valley_attach_test.gd`'s
## `_read_all_gd_source` helper (this codebase's established precedent) --
## this system's own doc comments legitimately name the banned APIs to
## document that they are forbidden, so a naive raw-text scan would flag its
## own compliance documentation as a violation. Stripping comment lines means
## only actual CODE usage can trip the checks above.
func _read_all_gd_source(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined
