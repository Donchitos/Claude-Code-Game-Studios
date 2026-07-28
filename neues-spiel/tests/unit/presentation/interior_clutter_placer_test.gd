## Unit test — [InteriorClutterPlacer] (Presentation Experience story
## presentation-001 Sub-scope A; art-bible SS6.5 "static props," "no motion
## cost").
##
## Covers:
## 1. headless setup() with no rendering.
## 2. one spawned prop per authored transform, in order.
## 3. determinism of spawn patterns: the SAME transforms array always
##    produces the SAME spawned transforms.
## 4. every spawned prop is structurally static (no _process/_physics_process).
## 5. placeholder mesh fallback when prop_mesh is left unassigned.
class_name InteriorClutterPlacerTest
extends GdUnitTestSuite


func test_setup_headless_completes_with_zero_transforms() -> void:
	var placer: InteriorClutterPlacer = auto_free(InteriorClutterPlacer.new())
	assert_bool(placer.is_set_up()).is_false()

	placer.setup()

	assert_bool(placer.is_set_up()).is_true()
	assert_int(placer.get_prop_count()).is_equal(0)


func test_one_prop_spawned_per_authored_transform() -> void:
	var placer: InteriorClutterPlacer = auto_free(InteriorClutterPlacer.new())
	placer.clutter_transforms = [
		Transform3D(Basis(), Vector3(1.0, 0.0, 2.0)),
		Transform3D(Basis(), Vector3(3.0, 0.0, 4.0)),
		Transform3D(Basis(), Vector3(5.0, 0.0, 6.0)),
	]

	placer.setup()

	assert_int(placer.get_prop_count()).is_equal(3)


func test_spawned_prop_transforms_match_authored_order_deterministically() -> void:
	var transforms: Array[Transform3D] = [
		Transform3D(Basis(), Vector3(1.0, 0.0, 2.0)),
		Transform3D(Basis(), Vector3(3.0, 0.0, 4.0)),
	]
	var placer: InteriorClutterPlacer = auto_free(InteriorClutterPlacer.new())
	placer.clutter_transforms = transforms

	placer.setup()

	assert_vector(placer.get_prop_transform(0).origin).is_equal_approx(
		Vector3(1.0, 0.0, 2.0), Vector3(0.0001, 0.0001, 0.0001)
	)
	assert_vector(placer.get_prop_transform(1).origin).is_equal_approx(
		Vector3(3.0, 0.0, 4.0), Vector3(0.0001, 0.0001, 0.0001)
	)


func test_same_input_transforms_produce_the_same_spawn_pattern_every_run() -> void:
	var transforms: Array[Transform3D] = [
		Transform3D(Basis(), Vector3(2.0, 0.0, 2.0)),
		Transform3D(Basis(), Vector3(9.0, 0.0, 1.0)),
	]

	var first_run: InteriorClutterPlacer = auto_free(InteriorClutterPlacer.new())
	first_run.clutter_transforms = transforms
	first_run.setup()

	var second_run: InteriorClutterPlacer = auto_free(InteriorClutterPlacer.new())
	second_run.clutter_transforms = transforms
	second_run.setup()

	for i in transforms.size():
		assert_vector(first_run.get_prop_transform(i).origin).is_equal_approx(
			second_run.get_prop_transform(i).origin, Vector3(0.0001, 0.0001, 0.0001)
		)


func test_every_spawned_prop_is_static_no_motion_cost() -> void:
	var placer: InteriorClutterPlacer = auto_free(InteriorClutterPlacer.new())
	placer.clutter_transforms = [Transform3D(Basis(), Vector3.ZERO)]

	placer.setup()

	assert_bool(placer.is_prop_static(0)).is_true()


func test_prop_mesh_falls_back_to_a_placeholder_when_unassigned() -> void:
	var placer: InteriorClutterPlacer = auto_free(InteriorClutterPlacer.new())
	placer.clutter_transforms = [Transform3D(Basis(), Vector3.ZERO)]
	assert_object(placer.prop_mesh).is_null()

	placer.setup()

	assert_object(placer.get_child(0).mesh).is_not_null()
