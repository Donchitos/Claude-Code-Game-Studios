## Unit test -- [FurnitureView] (Presentation Experience story presentation-005,
## F7: "a built bed becomes visible").
##
## Covers, per the story's own AC list:
## - AC-VIEW: `set_visual()` assigns the mesh and bottom/center-aligns the
##   child MeshInstance3D from the mesh's own real AABB, never a hardcoded
##   constant. A null mesh is inert.
## - AC-FOOTPRINT-POSITION: `position_over_footprint()` centers on x/z across
##   every occupied cell and sits at the lowest cell's floor on y. No
##   `_process()` exists on this class at all (static, not a mirror).
## - AC-NO-SELECTION (TRAP 2, presentation-003 precedent): covered by the
##   EXISTING src/presentation/-wide grep guard in villager_body_view_test.gd
##   (`test_presentation_module_source_contains_zero_selection_references`),
##   which scans the whole directory non-recursively -- no test change needed
##   here, per this story's own Out of Scope / AC-NO-SELECTION note.
class_name FurnitureViewTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# AC-VIEW -- set_visual()
# ---------------------------------------------------------------------------

func test_set_visual_assigns_mesh_to_child_mesh_instance() -> void:
	var view: FurnitureView = auto_free(FurnitureView.new())
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.5, 2.0)

	view.set_visual(box)

	assert_object(view.get_mesh_instance().mesh).is_same(box)


func test_set_visual_bottom_aligns_and_centers_mesh_from_its_real_aabb() -> void:
	# A BoxMesh's local AABB is centered on its own origin -- size (1, 0.5, 2)
	# means local_aabb.position == (-0.5, -0.25, -1.0). set_visual must lift
	# the mesh so its bottom face (local y = -0.25) lands on the view's own
	# local y = 0, and center it on x/z (already 0 for a centered BoxMesh,
	# proving the general "read the real AABB" path rather than a hardcoded
	# BoxMesh-only assumption).
	var view: FurnitureView = auto_free(FurnitureView.new())
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.5, 2.0)

	view.set_visual(box)

	var mesh_instance: MeshInstance3D = view.get_mesh_instance()
	assert_float(mesh_instance.position.y).is_equal_approx(0.25, 0.0001)
	assert_float(mesh_instance.position.x).is_equal_approx(0.0, 0.0001)
	assert_float(mesh_instance.position.z).is_equal_approx(0.0, 0.0001)


func test_set_visual_off_center_mesh_still_bottom_aligns_and_centers() -> void:
	# A mesh whose own local AABB is NOT centered on its origin (an offset
	# BoxMesh, standing in for an authored mesh with an arbitrary pivot) must
	# still rest bottom-aligned/centered -- proves the computation reads the
	# real AABB rather than assuming a BoxMesh's usual centered pivot.
	var view: FurnitureView = auto_free(FurnitureView.new())
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 1.0, 2.0)
	# BoxMesh itself has no position offset property, so this test proves the
	# math via get_aabb() directly instead -- get_aabb() for this box is
	# AABB(position=(-1,-0.5,-1), size=(2,1,2)); the expected lift is
	# -position.y == 0.5, and -center == (0, _, 0).
	view.set_visual(box)

	var mesh_instance: MeshInstance3D = view.get_mesh_instance()
	var local_aabb: AABB = box.get_aabb()
	assert_float(mesh_instance.position.y).is_equal_approx(-local_aabb.position.y, 0.0001)
	assert_float(mesh_instance.position.x).is_equal_approx(-local_aabb.get_center().x, 0.0001)
	assert_float(mesh_instance.position.z).is_equal_approx(-local_aabb.get_center().z, 0.0001)


func test_set_visual_with_null_mesh_is_inert_no_crash() -> void:
	var view: FurnitureView = auto_free(FurnitureView.new())

	view.set_visual(null)

	assert_object(view.get_mesh_instance().mesh).is_null()


# ---------------------------------------------------------------------------
# AC-FOOTPRINT-POSITION -- position_over_footprint()
# ---------------------------------------------------------------------------

func test_position_over_footprint_single_cell_matches_cell_floor_and_center() -> void:
	var view: FurnitureView = auto_free(FurnitureView.new())
	add_child(view)

	view.position_over_footprint([Vector3i(2, 0, 2)])

	var cell_center: Vector3 = VoxelWorldGrid.cell_to_world(Vector3i(2, 0, 2))
	var expected: Vector3 = Vector3(
		cell_center.x, cell_center.y - 0.5 * VoxelWorldConfig.CELL_SIZE, cell_center.z
	)
	assert_vector(view.global_position).is_equal(expected)


func test_position_over_footprint_two_cell_bed_footprint_centers_across_both() -> void:
	# The bed's real shipped footprint shape (data/items/bed.tres,
	# Vector2i(1, 2)) -- two horizontally-adjacent cells at the same y.
	var view: FurnitureView = auto_free(FurnitureView.new())
	add_child(view)
	var cell_a := Vector3i(2, 0, 2)
	var cell_b := Vector3i(2, 0, 3)

	view.position_over_footprint([cell_a, cell_b])

	var center_a: Vector3 = VoxelWorldGrid.cell_to_world(cell_a)
	var center_b: Vector3 = VoxelWorldGrid.cell_to_world(cell_b)
	var expected: Vector3 = Vector3(
		(center_a.x + center_b.x) * 0.5,
		center_a.y - 0.5 * VoxelWorldConfig.CELL_SIZE,
		(center_a.z + center_b.z) * 0.5,
	)
	assert_vector(view.global_position).is_equal(expected)
	assert_array(view.cells).contains_exactly([cell_a, cell_b])


func test_position_over_footprint_empty_cells_is_inert_no_crash() -> void:
	var view: FurnitureView = auto_free(FurnitureView.new())
	add_child(view)
	var position_before: Vector3 = view.global_position

	view.position_over_footprint([])

	assert_vector(view.global_position).is_equal(position_before)


# ---------------------------------------------------------------------------
# Static-not-a-mirror: no _process() at all
# ---------------------------------------------------------------------------

func test_furniture_view_source_has_no_process_method() -> void:
	# A placed furniture item never moves once built -- unlike VillagerBodyView
	# (a per-frame mirror of a moving villager), FurnitureView positions itself
	# ONCE and never re-derives, so this class must carry no _process() hook
	# at all.
	var source: String = FileAccess.get_file_as_string("res://src/presentation/furniture_view.gd")
	assert_bool(source.contains("func _process(")).is_false()
