## Regression guard for Story vox-019 (mesher chunk-build read-loop
## optimization, ADR-0014 Decision §2 optimization-reserve note; TR-voxel-
## world-025/052) -- proves [method VoxelWorldMesher._build_chunk_arrays]'s
## NEW bulk-[VoxelWorldGrid.ChunkSnapshot]-based read path emits
## BYTE-IDENTICAL `ARRAY_VERTEX`/`ARRAY_NORMAL`/`ARRAY_COLOR`/`ARRAY_INDEX`
## arrays to the PRE-OPTIMIZATION per-cell [method VoxelWorldGrid.get_cell]
## path, reconstructed here (`_legacy_build_chunk_arrays`) rather than kept
## as a second, dead production code path -- "THE ONE mesher construction
## site" contract (`voxel_world_mesher.gd`'s own class doc comment,
## grep-guarded by `mesher_material_contract_test.gd`) forbids a second
## `ArrayMesh`-adjacent geometry-assembly path from surviving in
## `src/voxel_world/`, so the OLD algorithm's reference implementation lives
## ONLY in this test file, hand-reconstructed from the exact pre-vox-019
## source (same loop order, same [VoxelWorldMesher.FACE_NORMALS]/
## [VoxelWorldMesher.FACE_CORNERS] tables, same fan-triangulation) -- never
## re-derived or approximated. Story vox-023: the colour source is now the
## SAME [BlockAppearanceConfig] instance the mesher under test was wired
## with (see [method _legacy_build_chunk_arrays]), not the retired
## `DEBUG_BLOCK_COLORS` constant.
##
## Fixture (AC2's own requirement): a 2-chunk-wide, 1-chunk-deep grid with
## mixed solid/air, terrain height variation ACROSS the chunk-0/chunk-1
## border (so a cross-chunk neighbor air-test is genuinely exercised in BOTH
## directions), plus one deliberate interior air pocket (mixed solid/air
## away from any border). Both the new production path
## ([method VoxelWorldMesher._build_chunk_arrays], called directly -- a
## private method, but this project's established test convention already
## calls private mesher/grid methods directly, e.g.
## `mesher_winding_derivation_test.gd`) and the legacy reconstruction below
## read the SAME grid, so any divergence can only come from the read-loop
## rewrite itself, never from fixture drift between two separately-built
## grids.
##
## Comparison uses [PackedVector3Array]/[PackedColorArray]/[PackedInt32Array]'s
## own `==` operator -- exact ELEMENT-WISE value equality (no epsilon), the
## strongest available "byte-identical" proof for these packed types, and
## deliberately does NOT round-trip through an [ArrayMesh]/`surface_get_arrays`
## (Godot's default mesh vertex compression could introduce floating-point
## drift unrelated to this story's own read-loop change -- comparing the raw
## arrays [method VoxelWorldMesher._build_chunk_arrays] itself returns is the
## correct, narrower scope for THIS regression guard).
class_name MesherBulkReadEquivalenceTest
extends GdUnitTestSuite

## Chunk-local air-pocket coordinates (Story vox-019 fixture) -- deliberately
## interior (not on the chunk-0/chunk-1 border at global x=15/16), so the
## fixture separately exercises BOTH "interior mixed solid/air" and "border
## cross-chunk neighbor" cases.
const AIR_POCKET_X: int = 6
const AIR_POCKET_Z: int = 8


# ---------------------------------------------------------------------------
# Test helpers (kept ABOVE every test function)
# ---------------------------------------------------------------------------

## Builds a small, deterministic grid: 2 chunks along X (world_width_cells=32,
## VoxelWorldGrid.CHUNK_SIZE=16), 1 chunk along Z (world_depth_cells=16),
## min_y=0/max_y=4 (height=5 local_y slots -- small enough for a fast test,
## wide enough for real terrain-height variation within [0, height]).
## Per-column height = `(x % 3) + 1` (1..3) -- varies specifically ACROSS the
## x=15/x=16 chunk border (15 % 3 = 0 -> height 1; 16 % 3 = 1 -> height 2),
## so the two chunks' shared boundary is never a flat, untested match. One
## column ([constant AIR_POCKET_X]/[constant AIR_POCKET_Z]) is left entirely
## unfilled -- a deliberate interior air pocket surrounded by solid terrain.
func _make_fixture_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 32
	config.world_depth_cells = 16
	config.min_y = 0
	config.max_y = 4
	grid.config = config

	var changes: Dictionary[Vector3i, CellContents] = {}
	for x in config.world_width_cells:
		for z in config.world_depth_cells:
			if x == AIR_POCKET_X and z == AIR_POCKET_Z:
				continue
			var height: int = (x % 3) + 1
			for y in range(0, height + 1):
				changes[Vector3i(x, y, z)] = CellContents.new(VoxelWorldGrid.TERRAIN_BLOCK_TYPE_ID, VoxelWorldGrid.TERRAIN_MATERIAL_ID)
	grid.bulk_write(changes)
	return grid


func _make_mesher(grid: VoxelWorldGrid) -> VoxelWorldMesher:
	var mesher: VoxelWorldMesher = auto_free(VoxelWorldMesher.new())
	mesher.grid = grid
	# Story vox-023: VoxelWorldMesher.setup() now asserts appearance is wired
	# (AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL) -- a fresh, valid config satisfies
	# that assert without affecting this file's own equivalence assertions.
	mesher.appearance = BlockAppearanceConfig.new()
	mesher.setup()
	return mesher


## Pre-vox-019 reference reconstruction of [method
## VoxelWorldMesher._build_chunk_arrays] -- see this file's own class doc
## comment for why this lives here rather than as a second production code
## path. Identical loop order/triangulation to the pre-optimization source,
## reusing [VoxelWorldMesher]'s own public winding tables so no magic number
## is duplicated (the ONLY thing under test is the READ mechanism,
## get_cell-per-cell here vs. the bulk snapshot in production). Story vox-023:
## the colour source is now [param appearance] (the SAME config instance the
## production mesher under test was wired with, via [param appearance]) rather
## than the retired `DEBUG_BLOCK_COLORS` constant -- both algorithms must read
## the SAME colour source for this test's byte-identity comparison to remain
## meaningful.
func _legacy_build_chunk_arrays(grid: VoxelWorldGrid, chunk_coord: Vector2i, appearance: BlockAppearanceConfig) -> Array:
	var chunk_size: int = VoxelWorldGrid.CHUNK_SIZE
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for local_x in chunk_size:
		var global_x: int = chunk_coord.x * chunk_size + local_x
		for local_z in chunk_size:
			var global_z: int = chunk_coord.y * chunk_size + local_z
			for global_y in range(grid.config.min_y, grid.config.max_y + 1):
				var cell := Vector3i(global_x, global_y, global_z)
				var contents: CellContents = grid.get_cell(cell)
				if contents == null or contents.is_empty():
					continue
				var color: Color = appearance.get_color(contents.block_type_id, VoxelWorldMesher.DEBUG_UNKNOWN_COLOR)
				for face_index in VoxelWorldMesher.FACE_NORMALS.size():
					var neighbor: Vector3i = cell + VoxelWorldMesher.FACE_NORMALS[face_index]
					var neighbor_contents: CellContents = grid.get_cell(neighbor)
					var is_air: bool = neighbor_contents == null or neighbor_contents.is_empty()
					if is_air:
						_legacy_append_face(verts, normals, colors, indices, cell, face_index, color)
	if verts.is_empty():
		return []
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


## Legacy fan-triangulation -- byte-for-byte identical to [method
## VoxelWorldMesher._append_face] (same corner order, same `(0,1,2)+(0,2,3)`
## triangulation, same [VoxelWorldConfig.CELL_SIZE] scale).
func _legacy_append_face(
		verts: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array,
		cell: Vector3i, face_index: int, color: Color
) -> void:
	var base: int = verts.size()
	var normal := Vector3(VoxelWorldMesher.FACE_NORMALS[face_index])
	var corners: Array = VoxelWorldMesher.FACE_CORNERS[face_index]
	for corner: Vector3i in corners:
		verts.append((Vector3(cell) + Vector3(corner)) * VoxelWorldConfig.CELL_SIZE)
		normals.append(normal)
		colors.append(color)
	indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])


# ---------------------------------------------------------------------------
# AC2 -- byte-identical mesh output, old vs. new, interior + border chunks
# ---------------------------------------------------------------------------

func test_optimized_path_matches_legacy_path_for_chunk_with_interior_air_pocket() -> void:
	# Arrange -- chunk (0,0) contains the interior air pocket AND one edge of
	# the chunk-0/chunk-1 height-step border.
	var grid: VoxelWorldGrid = _make_fixture_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	var optimized: Array = mesher._build_chunk_arrays(Vector2i(0, 0))
	var legacy: Array = _legacy_build_chunk_arrays(grid, Vector2i(0, 0), mesher.appearance)

	# Assert -- byte-identical, element-wise, for every emitted array.
	assert_bool(optimized.is_empty()).is_false()
	assert_bool(legacy.is_empty()).is_false()
	assert_int((optimized[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()).is_equal((legacy[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	assert_bool(optimized[Mesh.ARRAY_VERTEX] == legacy[Mesh.ARRAY_VERTEX]).is_true()
	assert_bool(optimized[Mesh.ARRAY_NORMAL] == legacy[Mesh.ARRAY_NORMAL]).is_true()
	assert_bool(optimized[Mesh.ARRAY_COLOR] == legacy[Mesh.ARRAY_COLOR]).is_true()
	assert_bool(optimized[Mesh.ARRAY_INDEX] == legacy[Mesh.ARRAY_INDEX]).is_true()


func test_optimized_path_matches_legacy_path_for_neighbor_chunk_across_the_border() -> void:
	# Arrange -- chunk (1,0) shares the SAME border (global x=16's local_x=0
	# neighbor is global x=15, chunk (0,0)'s local_x=15) -- the reverse
	# direction of the previous test's cross-chunk read.
	var grid: VoxelWorldGrid = _make_fixture_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	var optimized: Array = mesher._build_chunk_arrays(Vector2i(1, 0))
	var legacy: Array = _legacy_build_chunk_arrays(grid, Vector2i(1, 0), mesher.appearance)

	# Assert
	assert_bool(optimized.is_empty()).is_false()
	assert_bool(legacy.is_empty()).is_false()
	assert_bool(optimized[Mesh.ARRAY_VERTEX] == legacy[Mesh.ARRAY_VERTEX]).is_true()
	assert_bool(optimized[Mesh.ARRAY_NORMAL] == legacy[Mesh.ARRAY_NORMAL]).is_true()
	assert_bool(optimized[Mesh.ARRAY_COLOR] == legacy[Mesh.ARRAY_COLOR]).is_true()
	assert_bool(optimized[Mesh.ARRAY_INDEX] == legacy[Mesh.ARRAY_INDEX]).is_true()


func test_optimized_path_for_never_touched_chunk_returns_empty_array_matching_legacy() -> void:
	# Arrange -- a chunk coordinate entirely outside this fixture's 2x1 world
	# (world spans chunk x in {0,1}, z in {0} only) -- never resident.
	var grid: VoxelWorldGrid = _make_fixture_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	var optimized: Array = mesher._build_chunk_arrays(Vector2i(5, 5))
	var legacy: Array = _legacy_build_chunk_arrays(grid, Vector2i(5, 5), mesher.appearance)

	# Assert -- both the empty-Array contract (not a populated-but-empty one).
	assert_int(optimized.size()).is_equal(0)
	assert_int(legacy.size()).is_equal(0)


# ---------------------------------------------------------------------------
# AC1 -- get_chunk_snapshot read-purity + direct value correctness
# ---------------------------------------------------------------------------

func test_get_chunk_snapshot_returns_matching_bytes_for_resident_chunk() -> void:
	# Arrange -- x=0 column has height (0 % 3) + 1 = 1 -> local_y 0,1 solid,
	# local_y 2+ air.
	var grid: VoxelWorldGrid = _make_fixture_grid()

	# Act
	var snapshot: VoxelWorldGrid.ChunkSnapshot = grid.get_chunk_snapshot(Vector2i(0, 0))

	# Assert
	assert_object(snapshot).is_not_null()
	assert_int(snapshot.min_y).is_equal(0)
	assert_int(snapshot.height).is_equal(5)  # max_y(4) - min_y(0) + 1
	var offset_solid: int = VoxelWorldGrid.local_offset(0, 1, 0)
	var offset_air: int = VoxelWorldGrid.local_offset(0, 2, 0)
	assert_int(snapshot.block_type_ids[offset_solid]).is_equal(VoxelWorldGrid.TERRAIN_BLOCK_TYPE_ID)
	assert_int(snapshot.block_type_ids[offset_air]).is_equal(CellContents.EMPTY_BLOCK_TYPE_ID)


func test_get_chunk_snapshot_returns_null_for_non_resident_chunk_without_mutating_resident_set() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_fixture_grid()
	var before: Array[Vector2i] = grid.get_resident_chunk_keys()

	# Act -- a chunk key entirely outside this fixture's world extent.
	var snapshot: VoxelWorldGrid.ChunkSnapshot = grid.get_chunk_snapshot(Vector2i(5, 5))

	# Assert -- explicit "not resident" result, no allocation side effect.
	assert_object(snapshot).is_null()
	assert_bool(grid.is_chunk_resident(Vector2i(5, 5))).is_false()
	var after: Array[Vector2i] = grid.get_resident_chunk_keys()
	assert_int(after.size()).is_equal(before.size())


func test_mesher_build_chunk_for_never_touched_chunk_produces_no_mesh_and_no_grid_allocation() -> void:
	# Arrange -- end-to-end read-purity through the mesher's own public API,
	# not just the grid accessor in isolation.
	var grid: VoxelWorldGrid = _make_fixture_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	var before: Array[Vector2i] = grid.get_resident_chunk_keys()

	# Act
	mesher.build_chunk(Vector2i(5, 5))

	# Assert
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(Vector2i(5, 5))
	assert_object(mesh_instance).is_not_null()
	assert_object(mesh_instance.mesh).is_null()
	assert_int(grid.get_resident_chunk_keys().size()).is_equal(before.size())
