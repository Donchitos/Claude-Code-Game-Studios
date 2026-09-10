# GdUnit generated TestSuite
@warning_ignore_start("unsafe_method_access")
class_name GdUnitSpyBuilderTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/spy/GdUnitSpyBuilder.gd'


class NodeWithOutVirtualFunc extends Node:
	func _ready() -> void:
		pass

	#func _input(event :InputEvent) -> void:


func test_spy_on_script_respect_virtual_functions() -> void:
	var do_spy :Variant = auto_free(GdUnitSpyBuilder.spy_on_script(auto_free(NodeWithOutVirtualFunc.new()), [], true).new())

	do_spy.__init_doubler()
	do_spy.__init([])
	assert_bool(do_spy.has_method("_ready")).is_true()
	assert_bool(do_spy.has_method("_input")).is_false()


func test_spy_on_scene_with_onready_parameters() -> void:
	# setup a scene with holding parameters
	var scene: TestSceneWithProperties = load("res://addons/gdUnit4/test/spy/resources/TestSceneWithProperties.tscn").instantiate()
	add_child(scene)

	# precheck the parameters are original set
	var original_progress_value: Variant = scene.progress
	assert_object(original_progress_value).is_not_null()
	assert_object(scene._parameter_obj).is_not_null()
	assert_dict(scene._parameter_dict).is_equal({"key" : "value"})

	# create spy on scene
	var spy_scene :Variant = spy(scene)

	# verify the @onready property is set
	assert_object(spy_scene.progress).is_same(original_progress_value)
	# verify all properties are set
	assert_object(spy_scene._parameter_obj).is_not_null().is_same(scene._parameter_obj)
	assert_dict(spy_scene._parameter_dict).is_not_null().is_same(scene._parameter_dict)

	scene.free()
