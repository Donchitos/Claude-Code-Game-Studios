## Unit test -- Voxel World story vox-007 (chunked face-culled mesher, CW
## winding + backface culling ENABLED; ADR-0014 Decision Section 2;
## TR-voxel-world-025/052).
##
## Proves, all against [VoxelWorldMesher] / [VoxelWorldGrid]:
## 1. AC-1/AC-3 (TR-voxel-world-052, "no missing-face regressions"): an
##    isolated solid cell emits all 6 faces; two adjacent solid cells cull
##    their shared internal face on BOTH sides; a fully-solid 3x3x3 block
##    emits exactly its surface area (54 faces) and zero interior faces; a
##    solid cell at the world edge still emits its boundary-facing face
##    (out-of-bounds neighbor counts as air).
## 2. AC-1 (TR-voxel-world-025, "faces only where a cell borders air"): a
##    fully-buried cell (solid on all 6 sides) emits zero faces.
## 3. AC-2 (TR-voxel-world-025, "whole-chunk rebuild on cell_changed /
##    cells_changed_batch"): a tracked chunk is marked DIRTY (Story vox-020,
##    TD ruling Addendum D §D7 -- no longer rebuilt synchronously inside
##    signal dispatch) when a cell inside it changes (single write and batched
##    write), and a change at a chunk's border also marks an already-tracked
##    neighbor chunk dirty. A chunk vox-007 was never asked to [method
##    VoxelWorldMesher.build_chunk] is left alone (Scope: Story 015 owns
##    chunk-membership decisions). Draining the dirty set into an actual
##    rebuild is [VoxelWorldMeshStreamer]'s job (`mesh_invalidation_budget_
##    test.gd` covers the budgeted-drain/ordering contract); this file proves
##    only that the mesher marks the RIGHT keys dirty and does not itself
##    rebuild during dispatch.
class_name ChunkedMesherFaceCullingTest
extends GdUnitTestSuite


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _make_mesher(grid: VoxelWorldGrid) -> VoxelWorldMesher:
	var mesher: VoxelWorldMesher = auto_free(VoxelWorldMesher.new())
	mesher.grid = grid
	# Story vox-023: VoxelWorldMesher.setup() now asserts appearance is wired
	# (AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL) -- a fresh, valid config satisfies
	# that assert without affecting this file's own face-culling assertions.
	mesher.appearance = BlockAppearanceConfig.new()
	mesher.setup()
	return mesher


# ---------------------------------------------------------------------------
# Face-culling correctness (AC-1/AC-3, TR-voxel-world-025/052)
# ---------------------------------------------------------------------------

func test_isolated_solid_cell_emits_all_6_faces() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(5, 5, 5), CellContents.new(1, 0))
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	mesher.build_chunk(Vector2i(0, 0))

	# Assert -- 6 faces * 4 verts = 24 verts, 6 faces * 2 tris * 3 indices = 36 indices.
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(Vector2i(0, 0))
	var mesh: ArrayMesh = mesh_instance.mesh
	assert_object(mesh).is_not_null()
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_int(verts.size()).is_equal(24)
	assert_int(indices.size()).is_equal(36)


func test_fully_buried_cell_emits_zero_faces() -> void:
	# Arrange -- a solid cell with all 6 face-neighbors also solid.
	var grid: VoxelWorldGrid = _make_grid()
	var center := Vector3i(5, 5, 5)
	grid.set_cell(center, CellContents.new(1, 0))
	for offset: Vector3i in VoxelWorldGrid.NEIGHBOR_OFFSETS:
		grid.set_cell(center + offset, CellContents.new(1, 0))
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	mesher.build_chunk(Vector2i(0, 0))

	# Assert -- the whole cluster still has an OUTER surface, but the CENTER
	# cell itself is fully buried and contributes zero of its own faces.
	# Isolate this by checking no vertex sits on the center cell's own
	# boundary planes (x/y/z in {5,6}) that would only come from the center
	# cell's faces -- simpler: assert the mesh is non-empty (outer surface
	# exists) and that a SECOND identical cluster with the center cell
	# missing (i.e. hollow) would differ. Direct isolation: compare face
	# count of the 7-cell cluster against 6 independently-meshed single
	# cells minus double-counted shared faces is complex; instead assert the
	# simpler, direct contract -- an isolated single solid cell surrounded
	# on all 6 sides by MORE solid cells (this cluster) never exposes the
	# center cell's own 6 faces, by checking total face count stays far
	# below the naive "7 cells * 6 faces" (42) upper bound.
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(Vector2i(0, 0))
	var mesh: ArrayMesh = mesh_instance.mesh
	assert_object(mesh).is_not_null()
	var arrays: Array = mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	# A "plus" of 7 cells (1 center + 6 face-neighbors) exposes exactly
	# 30 faces (each arm's outward tip face + 4 side faces, minus the
	# 6 internal faces the center cell would have had) -- assert the
	# EXACT count, which only holds if the center cell contributes zero.
	assert_int(indices.size() / 6).is_equal(30)


func test_two_adjacent_solid_cells_cull_shared_internal_face() -> void:
	# Arrange -- two cells adjacent along +X, both within chunk (0,0).
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(5, 0, 5), CellContents.new(1, 0))
	grid.set_cell(Vector3i(6, 0, 5), CellContents.new(1, 0))
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	mesher.build_chunk(Vector2i(0, 0))

	# Assert -- 12 faces naively, minus 2 (both sides of the shared internal
	# face) = 10 faces = 40 verts, 60 indices.
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(Vector2i(0, 0))
	var mesh: ArrayMesh = mesh_instance.mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_int(verts.size()).is_equal(40)
	assert_int(indices.size()).is_equal(60)


func test_fully_solid_3x3x3_block_emits_exactly_surface_area_faces() -> void:
	# Arrange -- a 3x3x3 solid cube: surface area = 6 * 3*3 = 54 faces
	# (well-known cube surface formula, n=3) if and only if the single
	# interior cell (the exact center) contributes zero faces.
	var grid: VoxelWorldGrid = _make_grid()
	for x in range(4, 7):
		for y in range(4, 7):
			for z in range(4, 7):
				grid.set_cell(Vector3i(x, y, z), CellContents.new(1, 0))
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	mesher.build_chunk(Vector2i(0, 0))

	# Assert
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(Vector2i(0, 0))
	var mesh: ArrayMesh = mesh_instance.mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_int(verts.size()).is_equal(54 * 4)
	assert_int(indices.size()).is_equal(54 * 6)


func test_solid_cell_at_world_edge_emits_boundary_face_toward_out_of_bounds() -> void:
	# Arrange -- a solid cell at x=0 (world edge, Core Rule 1 fixed origin):
	# its -X neighbor is out of bounds (get_cell returns null), which must
	# count as air, not as "no face" or a crash.
	var grid: VoxelWorldGrid = _make_grid()
	grid.set_cell(Vector3i(0, 5, 5), CellContents.new(1, 0))
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	mesher.build_chunk(Vector2i(0, 0))

	# Assert -- an isolated solid cell still emits all 6 faces even though
	# one neighbor is out-of-bounds rather than merely empty.
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(Vector2i(0, 0))
	var mesh: ArrayMesh = mesh_instance.mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	assert_int(verts.size()).is_equal(24)


func test_empty_chunk_produces_null_mesh() -> void:
	# Arrange -- no cells written anywhere in this chunk.
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act
	mesher.build_chunk(Vector2i(3, 3))

	# Assert -- the MeshInstance3D exists (tracked) but has no mesh.
	assert_bool(mesher.is_chunk_tracked(Vector2i(3, 3))).is_true()
	var mesh_instance: MeshInstance3D = mesher.get_chunk_mesh_instance(Vector2i(3, 3))
	assert_object(mesh_instance).is_not_null()
	assert_object(mesh_instance.mesh).is_null()


# ---------------------------------------------------------------------------
# AC-2 (TR-voxel-world-025) -- whole-chunk rebuild on cell_changed
# ---------------------------------------------------------------------------

func test_cell_changed_marks_already_tracked_chunk_dirty_not_rebuilt_immediately() -> void:
	# Arrange -- build the (empty) chunk once so it becomes "tracked".
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	mesher.build_chunk(Vector2i(0, 0))
	assert_object(mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh).is_null()

	# Act -- place a block inside the tracked chunk.
	grid.set_cell(Vector3i(5, 5, 5), CellContents.new(1, 0))

	# Assert -- Story vox-020: marked dirty, NOT rebuilt synchronously inside
	# signal dispatch (the mesh is still the stale, pre-write null).
	assert_array(mesher.get_dirty_chunk_keys()).contains([Vector2i(0, 0)])
	assert_object(mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh).is_null()

	# Act -- drain the dirty set (what [VoxelWorldMeshStreamer]'s rebuild phase
	# does every call).
	mesher.build_chunk(Vector2i(0, 0))
	mesher.clear_dirty(Vector2i(0, 0))

	# Assert -- now correctly reflects the write.
	var mesh: ArrayMesh = mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh
	assert_object(mesh).is_not_null()
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_int(verts.size()).is_equal(24)
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()

	# Act -- remove it again (marks dirty again).
	grid.clear_cell(Vector3i(5, 5, 5))
	assert_array(mesher.get_dirty_chunk_keys()).contains([Vector2i(0, 0)])
	mesher.build_chunk(Vector2i(0, 0))
	mesher.clear_dirty(Vector2i(0, 0))

	# Assert -- back to an empty mesh once drained.
	assert_object(mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh).is_null()


func test_cells_changed_batch_marks_already_tracked_chunk_dirty_exactly_once() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	mesher.build_chunk(Vector2i(0, 0))

	# Act -- a bulk write touching two cells in the same tracked chunk.
	grid.bulk_write({
		Vector3i(1, 0, 1): CellContents.new(1, 0),
		Vector3i(2, 0, 1): CellContents.new(1, 0),
	})

	# Assert -- Story vox-020: exactly ONE dirty key (deduped), mesh not yet
	# rebuilt.
	var dirty: Array[Vector2i] = mesher.get_dirty_chunk_keys()
	assert_int(dirty.size()).is_equal(1)
	assert_array(dirty).contains([Vector2i(0, 0)])
	assert_object(mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh).is_null()

	# Act -- drain.
	mesher.build_chunk(Vector2i(0, 0))
	mesher.clear_dirty(Vector2i(0, 0))

	# Assert -- both cells' faces are present (adjacent along +X, so 10
	# faces = 40 verts, matching the two-adjacent-cells case above).
	var mesh: ArrayMesh = mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh
	assert_object(mesh).is_not_null()
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_int(verts.size()).is_equal(40)


func test_cell_changed_in_untracked_chunk_does_not_build_it() -> void:
	# Arrange -- no build_chunk call for chunk (5,5) at all.
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)

	# Act -- write into a cell that lives in chunk (5,5) (CHUNK_SIZE=16 -> cell x=80).
	grid.set_cell(Vector3i(80, 0, 80), CellContents.new(1, 0))

	# Assert -- Story 015's scope, not this mesher's: no chunk was built.
	assert_bool(mesher.is_chunk_tracked(Vector2i(5, 5))).is_false()


func test_change_at_chunk_border_also_marks_tracked_neighbor_chunk_dirty() -> void:
	# Arrange -- two ADJACENT tracked chunks (0,0) and (1,0), CHUNK_SIZE=16:
	# chunk (0,0) covers local x 0..15, chunk (1,0) covers x 16..31.
	var grid: VoxelWorldGrid = _make_grid()
	var mesher: VoxelWorldMesher = _make_mesher(grid)
	mesher.build_chunk(Vector2i(0, 0))
	mesher.build_chunk(Vector2i(1, 0))
	# A solid cell just inside chunk (1,0)'s border (x=16) so chunk (0,0)'s
	# border cell at x=15 has a solid neighbor across the boundary.
	grid.set_cell(Vector3i(16, 0, 0), CellContents.new(1, 0))
	mesher.build_chunk(Vector2i(1, 0))
	mesher.clear_dirty(Vector2i(1, 0))
	assert_object(mesher.get_chunk_mesh_instance(Vector2i(1, 0)).mesh).is_not_null()
	assert_object(mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh).is_null()  # nothing solid in chunk 0 yet

	# Act -- place a solid cell at x=15 (chunk (0,0)'s edge, touching x=16).
	grid.set_cell(Vector3i(15, 0, 0), CellContents.new(1, 0))

	# Assert -- Story vox-020: BOTH the owning chunk AND the seam neighbor are
	# marked dirty, NEITHER mesh is rebuilt yet.
	var dirty: Array[Vector2i] = mesher.get_dirty_chunk_keys()
	assert_int(dirty.size()).is_equal(2)
	assert_array(dirty).contains([Vector2i(0, 0), Vector2i(1, 0)])
	assert_object(mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh).is_null()

	# Act -- drain both (what the streamer's rebuild phase does).
	mesher.build_chunk(Vector2i(0, 0))
	mesher.clear_dirty(Vector2i(0, 0))
	mesher.build_chunk(Vector2i(1, 0))
	mesher.clear_dirty(Vector2i(1, 0))

	# Assert -- BOTH chunks' meshes now reflect the shared boundary being
	# culled: each of the two cells has 5 exposed faces (their mutual +X/-X
	# face is hidden), not 6 -- 20 verts each, not 24.
	var mesh0: ArrayMesh = mesher.get_chunk_mesh_instance(Vector2i(0, 0)).mesh
	var mesh1: ArrayMesh = mesher.get_chunk_mesh_instance(Vector2i(1, 0)).mesh
	assert_object(mesh0).is_not_null()
	assert_object(mesh1).is_not_null()
	var verts0: PackedVector3Array = mesh0.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var verts1: PackedVector3Array = mesh1.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_int(verts0.size()).is_equal(20)
	assert_int(verts1.size()).is_equal(20)
	assert_array(mesher.get_dirty_chunk_keys()).is_empty()
