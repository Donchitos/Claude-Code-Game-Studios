## Pins TR-voxel-world-052's HARD QA requirement -- Godot 4.7's front-face
## winding convention, established from FIRST PRINCIPLES inside the engine
## (never from memory, from `docs/engine-reference/godot/`, or from a
## self-stored assumption) via a native [BoxMesh]'s own index/normal data --
## plus [VoxelWorldMesher]'s conformance to the exact same derived rule.
##
## Part 1 reproduces the derivation performed against this engine install: a
## native [BoxMesh] renders correctly (solid, no holes) under Godot's default
## backface-culling material settings, so its own
## stored-index-order-vs-stored-normal relationship IS Godot's front-face
## convention, empirically. For every one of the box's 12 triangles, taken in
## stored index order `(v0,v1,v2)`, `(v1-v0).cross(v2-v0)` must point
## OPPOSITE the triangle's own stored vertex normal -- i.e. Godot's
## front-facing winding is CLOCKWISE when viewed from the outward-normal
## side, NOT the OpenGL/CCW-front convention the vertical slice wrongly
## assumed (`prototypes/last-seal-vertical-slice/voxel_world.gd`'s documented
## "missing faces" root cause, TR-voxel-world-052). A future engine upgrade
## that silently changed this convention would fail Part 1 here BEFORE it
## could silently reintroduce missing faces via Part 2's mesher conformance
## check.
##
## Part 2 asserts [VoxelWorldMesher.FACE_CORNERS] conforms to the SAME rule,
## for both fan-triangulated triangles of all 6 face directions -- the actual
## winding table the production mesher ships.
class_name MesherWindingDerivationTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Part 1 -- first-principles engine derivation (BoxMesh, never from memory)
# ---------------------------------------------------------------------------

func test_boxmesh_front_face_winding_is_clockwise_from_outward_normal() -> void:
	# Arrange -- a native Godot primitive mesh, never hand-authored geometry.
	var box := BoxMesh.new()
	var arrays: Array = box.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	# Act + Assert -- every one of BoxMesh's 12 triangles, taken in its own
	# stored index order, produces a winding-derived normal OPPOSITE its own
	# stored vertex normal (dot product strongly negative -- CW-front).
	assert_int(indices.size()).is_equal(36)
	for tri in range(indices.size() / 3):
		var v0: Vector3 = verts[indices[tri * 3]]
		var v1: Vector3 = verts[indices[tri * 3 + 1]]
		var v2: Vector3 = verts[indices[tri * 3 + 2]]
		var stored_normal: Vector3 = normals[indices[tri * 3]]
		var winding_normal: Vector3 = (v1 - v0).cross(v2 - v0).normalized()
		assert_float(winding_normal.dot(stored_normal)).is_less(-0.9)


# ---------------------------------------------------------------------------
# Part 2 -- VoxelWorldMesher.FACE_CORNERS conforms to the derived rule
# ---------------------------------------------------------------------------

func test_face_corners_table_matches_derived_cw_front_convention_for_every_face() -> void:
	# Arrange + Act + Assert -- for each of the 6 faces, BOTH fan-triangulated
	# triangles ((0,1,2) and (0,2,3), matching VoxelWorldMesher._append_face's
	# actual triangulation) must wind opposite the face's own normal, exactly
	# like Part 1's engine-derived rule.
	assert_int(VoxelWorldMesher.FACE_NORMALS.size()).is_equal(6)
	assert_int(VoxelWorldMesher.FACE_CORNERS.size()).is_equal(6)
	for face_index in VoxelWorldMesher.FACE_NORMALS.size():
		var normal := Vector3(VoxelWorldMesher.FACE_NORMALS[face_index])
		var corners: Array = VoxelWorldMesher.FACE_CORNERS[face_index]
		assert_int(corners.size()).is_equal(4)
		var p0 := Vector3(corners[0])
		var p1 := Vector3(corners[1])
		var p2 := Vector3(corners[2])
		var p3 := Vector3(corners[3])
		var winding_tri1: Vector3 = (p1 - p0).cross(p2 - p0).normalized()
		var winding_tri2: Vector3 = (p2 - p0).cross(p3 - p0).normalized()
		assert_float(winding_tri1.dot(normal)).is_less(-0.9)
		assert_float(winding_tri2.dot(normal)).is_less(-0.9)
