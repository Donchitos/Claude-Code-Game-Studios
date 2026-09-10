extends GdUnitTestSuite


func test_equals_string() -> void:
	var a := ""
	var b := ""
	var c := "abc"
	var d := "abC"

	assert_bool(GdObjects.equals("", "")).is_true()
	assert_bool(GdObjects.equals(a, "")).is_true()
	assert_bool(GdObjects.equals("", a)).is_true()
	assert_bool(GdObjects.equals(a, a)).is_true()
	assert_bool(GdObjects.equals(a, b)).is_true()
	assert_bool(GdObjects.equals(b, a)).is_true()
	assert_bool(GdObjects.equals(c, c)).is_true()
	assert_bool(GdObjects.equals(c, String(c))).is_true()

	assert_bool(GdObjects.equals(a, null)).is_false()
	assert_bool(GdObjects.equals(null, a)).is_false()
	assert_bool(GdObjects.equals("", c)).is_false()
	assert_bool(GdObjects.equals(c, "")).is_false()
	assert_bool(GdObjects.equals(c, d)).is_false()
	assert_bool(GdObjects.equals(d, c)).is_false()
	# against diverent type
	assert_bool(GdObjects.equals(d, Array())).is_false()
	assert_bool(GdObjects.equals(d, Dictionary())).is_false()
	assert_bool(GdObjects.equals(d, Vector2.ONE)).is_false()
	assert_bool(GdObjects.equals(d, Vector3.ONE)).is_false()


func test_equals_string_case_insensitive() -> void:
	assert_bool(GdObjects.equals("abc", "abC", false)).is_true()
	assert_bool(GdObjects.equals("abc", "ABC", false)).is_true()
	assert_bool(GdObjects.equals("abc", "abd", false)).is_false()


func test_equals_stringname() -> void:
	assert_bool(GdObjects.equals("",  &"")).is_true()
	assert_bool(GdObjects.equals("abc", &"abc")).is_true()
	assert_bool(GdObjects.equals("abc", &"abC")).is_false()


func test_equals_array() -> void:
	var a := []
	var b := []
	var c := Array()
	var d := [1,2,3,4,5]
	var e := [1,2,3,4,5]
	var x := [1,2,3,6,4,5]

	assert_bool(GdObjects.equals(a, a)).is_true()
	assert_bool(GdObjects.equals(a, b)).is_true()
	assert_bool(GdObjects.equals(b, a)).is_true()
	assert_bool(GdObjects.equals(a, c)).is_true()
	assert_bool(GdObjects.equals(c, b)).is_true()
	assert_bool(GdObjects.equals(d, d)).is_true()
	assert_bool(GdObjects.equals(d, e)).is_true()
	assert_bool(GdObjects.equals(e, d)).is_true()

	assert_bool(GdObjects.equals(a, null)).is_false()
	assert_bool(GdObjects.equals(null, a)).is_false()
	assert_bool(GdObjects.equals(a, d)).is_false()
	assert_bool(GdObjects.equals(d, a)).is_false()
	assert_bool(GdObjects.equals(d, x)).is_false()
	assert_bool(GdObjects.equals(x, d)).is_false()
	# against diverent type
	assert_bool(GdObjects.equals(a, "")).is_false()
	assert_bool(GdObjects.equals(a, Dictionary())).is_false()
	assert_bool(GdObjects.equals(a, Vector2.ONE)).is_false()
	assert_bool(GdObjects.equals(a, Vector3.ONE)).is_false()


func test_equals_dictionary() -> void:
	var a := {}
	var b := {}
	var c := {"a":"foo"}
	var d := {"a":"foo"}
	var e1 := {"a":"foo", "b":"bar"}
	var e2 := {"b":"bar", "a":"foo"}

	assert_bool(GdObjects.equals(a, a)).is_true()
	assert_bool(GdObjects.equals(a, b)).is_true()
	assert_bool(GdObjects.equals(b, a)).is_true()
	assert_bool(GdObjects.equals(c, c)).is_true()
	assert_bool(GdObjects.equals(c, d)).is_true()
	assert_bool(GdObjects.equals(e1, e2)).is_true()
	assert_bool(GdObjects.equals(e2, e1)).is_true()

	assert_bool(GdObjects.equals(a, null)).is_false()
	assert_bool(GdObjects.equals(null, a)).is_false()
	assert_bool(GdObjects.equals(a, c)).is_false()
	assert_bool(GdObjects.equals(c, a)).is_false()
	assert_bool(GdObjects.equals(a, e1)).is_false()
	assert_bool(GdObjects.equals(e1, a)).is_false()
	assert_bool(GdObjects.equals(c, e1)).is_false()
	assert_bool(GdObjects.equals(e1, c)).is_false()


class TestClass extends Resource:

	enum {
		A,
		B
	}

	var _a:int
	var _b:String
	var _c:Array

	func _init(a:int = 0, b:String = "", c:Array = []) -> void:
		_a = a
		_b = b
		_c = c


func test_equals_class() -> void:
	var a := TestClass.new()
	var b := TestClass.new()
	var c := TestClass.new(1, "foo", ["bar", "xxx"])
	var d := TestClass.new(1, "foo", ["bar", "xxx"])
	var x := TestClass.new(1, "foo", ["bar", "xsxx"])

	assert_bool(GdObjects.equals(a, a)).is_true()
	assert_bool(GdObjects.equals(a, b)).is_true()
	assert_bool(GdObjects.equals(b, a)).is_true()
	assert_bool(GdObjects.equals(c, d)).is_true()
	assert_bool(GdObjects.equals(d, c)).is_true()

	assert_bool(GdObjects.equals(a, null)).is_false()
	assert_bool(GdObjects.equals(null, a)).is_false()
	assert_bool(GdObjects.equals(a, c)).is_false()
	assert_bool(GdObjects.equals(c, a)).is_false()
	assert_bool(GdObjects.equals(d, x)).is_false()
	assert_bool(GdObjects.equals(x, d)).is_false()


func test_equals_with_stack_deep() -> void:
	# more extended version
	var x2 := TestClass.new(1, "foo", [TestClass.new(22, "foo"), TestClass.new(22, "foo")])
	var x3 := TestClass.new(1, "foo", [TestClass.new(22, "foo"), TestClass.new(23, "foo")])
	assert_bool(GdObjects.equals(x2, x3)).is_false()


func test_equals_Node_with_deep_check() -> void:
	var nodeA :Node = auto_free(Node.new())
	var nodeB :Node = auto_free(Node.new())

	# compares by default with deep parameter ckeck
	assert_bool(GdObjects.equals(nodeA, nodeA)).is_true()
	assert_bool(GdObjects.equals(nodeB, nodeB)).is_true()
	assert_bool(GdObjects.equals(nodeA, nodeB)).is_true()
	assert_bool(GdObjects.equals(nodeB, nodeA)).is_true()
	# compares by object reference
	assert_bool(GdObjects.equals(nodeA, nodeA, false, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)).is_true()
	assert_bool(GdObjects.equals(nodeB, nodeB, false, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)).is_true()
	assert_bool(GdObjects.equals(nodeA, nodeB, false, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)).is_false()
	assert_bool(GdObjects.equals(nodeB, nodeA, false, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)).is_false()


func test_is_primitive_type() -> void:
	assert_bool(GdObjects.is_primitive_type(false)).is_true()
	assert_bool(GdObjects.is_primitive_type(true)).is_true()
	assert_bool(GdObjects.is_primitive_type(0)).is_true()
	assert_bool(GdObjects.is_primitive_type(0.1)).is_true()
	assert_bool(GdObjects.is_primitive_type("")).is_true()
	assert_bool(GdObjects.is_primitive_type(Vector2.ONE)).is_false()


class TestClassForIsType:
	var x :int


func test_is_type() -> void:
	# check build-in types
	assert_bool(GdObjects.is_type(1)).is_false()
	assert_bool(GdObjects.is_type(1.3)).is_false()
	assert_bool(GdObjects.is_type(true)).is_false()
	assert_bool(GdObjects.is_type(false)).is_false()
	assert_bool(GdObjects.is_type([])).is_false()
	assert_bool(GdObjects.is_type("abc")).is_false()

	assert_bool(GdObjects.is_type(null)).is_false()
	# an object type
	assert_bool(GdObjects.is_type(Node)).is_true()
	# an reference type
	assert_bool(GdObjects.is_type(AStar3D)).is_true()
	# an script type
	assert_bool(GdObjects.is_type(GDScript)).is_true()
	# an custom type
	assert_bool(GdObjects.is_type(TestClassForIsType)).is_true()
	# checked inner class type
	assert_bool(GdObjects.is_type(CustomClass.InnerClassA)).is_true()
	assert_bool(GdObjects.is_type(CustomClass.InnerClassC)).is_true()

	# for instances must allways endup with false
	assert_bool(GdObjects.is_type(auto_free(Node.new()))).is_false()
	assert_bool(GdObjects.is_type(AStar3D.new())).is_false()
	assert_bool(GdObjects.is_type(Dictionary())).is_false()
	assert_bool(GdObjects.is_type(PackedColorArray())).is_false()
	assert_bool(GdObjects.is_type(GDScript.new())).is_false()
	assert_bool(GdObjects.is_type(TestClassForIsType.new())).is_false()
	assert_bool(GdObjects.is_type(auto_free(CustomClass.InnerClassC.new()))).is_false()


func test_is_singleton() -> void:
	for singleton_name in Engine.get_singleton_list():
		var singleton := Engine.get_singleton(singleton_name)
		assert_bool(GdObjects.is_singleton(singleton)) \
			.override_failure_message("Expect to a singleton: '%s' Instance: %s, Class: %s" % [singleton_name, singleton, singleton.get_class()]) \
			.is_true()
	# false tests
	assert_bool(GdObjects.is_singleton(10)).is_false()
	assert_bool(GdObjects.is_singleton(true)).is_false()
	assert_bool(GdObjects.is_singleton(Node)).is_false()
	assert_bool(GdObjects.is_singleton(auto_free(Node.new()))).is_false()


func _is_instance(value :Variant) -> bool:
	return GdObjects.is_instance(auto_free(value))


func test_is_instance_true() -> void:
	assert_bool(_is_instance(RefCounted.new())).is_true()
	assert_bool(_is_instance(Node.new())).is_true()
	assert_bool(_is_instance(AStar3D.new())).is_true()
	assert_bool(_is_instance(PackedScene.new())).is_true()
	assert_bool(_is_instance(GDScript.new())).is_true()
	assert_bool(_is_instance(Person.new())).is_true()
	assert_bool(_is_instance(CustomClass.new())).is_true()
	assert_bool(_is_instance(CustomNodeTestClass.new())).is_true()
	assert_bool(_is_instance(TestClassForIsType.new())).is_true()
	assert_bool(_is_instance(CustomClass.InnerClassC.new())).is_true()


func test_is_instance_false() -> void:
	assert_bool(_is_instance(RefCounted)).is_false()
	assert_bool(_is_instance(Node)).is_false()
	assert_bool(_is_instance(AStar3D)).is_false()
	assert_bool(_is_instance(PackedScene)).is_false()
	assert_bool(_is_instance(GDScript)).is_false()
	assert_bool(_is_instance(Dictionary())).is_false()
	assert_bool(_is_instance(PackedColorArray())).is_false()
	assert_bool(_is_instance(Person)).is_false()
	assert_bool(_is_instance(CustomClass)).is_false()
	assert_bool(_is_instance(CustomNodeTestClass)).is_false()
	assert_bool(_is_instance(TestClassForIsType)).is_false()
	assert_bool(_is_instance(CustomClass.InnerClassC)).is_false()


# shorter helper func to extract class name and using auto_free
func extract_class_name(value :Variant) -> GdUnitResult:
	return GdObjects.extract_class_name(auto_free(value))


func test_get_class_name_from_class_path() -> void:
	# extract class name by resoure path
	assert_result(extract_class_name("res://addons/gdUnit4/test/resources/core/Person.gd"))\
		.is_success().is_value("Person")
	assert_result(extract_class_name("res://addons/gdUnit4/test/resources/core/CustomClass.gd"))\
		.is_success().is_value("CustomClass")
	assert_result(extract_class_name("res://addons/gdUnit4/test/mocker/resources/CustomNodeTestClass.gd"))\
		.is_success().is_value("CustomNodeTestClass")
	assert_result(extract_class_name("res://addons/gdUnit4/test/mocker/resources/CustomResourceTestClass.gd"))\
		.is_success().is_value("CustomResourceTestClass")
	assert_result(extract_class_name("res://addons/gdUnit4/test/mocker/resources/OverridenGetClassTestClass.gd"))\
		.is_success().is_value("OverridenGetClassTestClass")


func test_get_class_name_from_snake_case_class_path() -> void:
	assert_result(extract_class_name("res://addons/gdUnit4/test/core/resources/naming_conventions/snake_case_with_class_name.gd"))\
		.is_success().is_value("SnakeCaseWithClassName")
	# without class_name
	assert_result(extract_class_name("res://addons/gdUnit4/test/core/resources/naming_conventions/snake_case_without_class_name.gd"))\
		.is_success().is_value("SnakeCaseWithoutClassName")


func test_get_class_name_from_pascal_case_class_path() -> void:
	assert_result(extract_class_name("res://addons/gdUnit4/test/core/resources/naming_conventions/PascalCaseWithClassName.gd"))\
		.is_success().is_value("PascalCaseWithClassName")
	# without class_name
	assert_result(extract_class_name("res://addons/gdUnit4/test/core/resources/naming_conventions/PascalCaseWithoutClassName.gd"))\
		.is_success().is_value("PascalCaseWithoutClassName")


func test_get_class_name_from_type() -> void:
	assert_result(extract_class_name(Animation)).is_success().is_value("Animation")
	assert_result(extract_class_name(GDScript)).is_success().is_value("GDScript")
	assert_result(extract_class_name(Camera3D)).is_success().is_value("Camera3D")
	assert_result(extract_class_name(Node)).is_success().is_value("Node")
	assert_result(extract_class_name(Tree)).is_success().is_value("Tree")
	# extract class name from custom classes
	assert_result(extract_class_name(Person)).is_success().is_value("Person")
	assert_result(extract_class_name(CustomClass)).is_success().is_value("CustomClass")
	assert_result(extract_class_name(CustomNodeTestClass)).is_success().is_value("CustomNodeTestClass")
	assert_result(extract_class_name(CustomResourceTestClass)).is_success().is_value("CustomResourceTestClass")
	assert_result(extract_class_name(OverridenGetClassTestClass)).is_success().is_value("OverridenGetClassTestClass")
	assert_result(extract_class_name(AdvancedTestClass)).is_success().is_value("AdvancedTestClass")


func test_get_class_name_from_inner_class() -> void:
	assert_result(extract_class_name(CustomClass))\
		.is_success().is_value("CustomClass")
	assert_result(extract_class_name(CustomClass.InnerClassA))\
		.is_success().is_value("CustomClass.InnerClassA")
	assert_result(extract_class_name(CustomClass.InnerClassB))\
		.is_success().is_value("CustomClass.InnerClassB")
	assert_result(extract_class_name(CustomClass.InnerClassC))\
		.is_success().is_value("CustomClass.InnerClassC")
	assert_result(extract_class_name(CustomClass.InnerClassD))\
		.is_success().is_value("CustomClass.InnerClassD")
	assert_result(extract_class_name(AdvancedTestClass.SoundData))\
		.is_success().is_value("AdvancedTestClass.SoundData")
	assert_result(extract_class_name(AdvancedTestClass.AtmosphereData))\
		.is_success().is_value("AdvancedTestClass.AtmosphereData")
	assert_result(extract_class_name(AdvancedTestClass.Area4D))\
		.is_success().is_value("AdvancedTestClass.Area4D")


func test_extract_class_name_from_instance() -> void:
	assert_result(extract_class_name(Camera3D.new())).is_equal("Camera3D")
	assert_result(extract_class_name(GDScript.new())).is_equal("GDScript")
	assert_result(extract_class_name(Node.new())).is_equal("Node")

	# extract class name from custom classes
	assert_result(extract_class_name(Person.new())).is_equal("Person")
	assert_result(extract_class_name(ClassWithNameA.new())).is_equal("ClassWithNameA")
	assert_result(extract_class_name(ClassWithNameB.new())).is_equal("ClassWithNameB")
	var classWithoutNameA: GDScript = load("res://addons/gdUnit4/test/mocker/resources/ClassWithoutNameA.gd")
	assert_result(extract_class_name(classWithoutNameA.new())).is_equal("ClassWithoutNameA")
	assert_result(extract_class_name(CustomNodeTestClass.new())).is_equal("CustomNodeTestClass")
	assert_result(extract_class_name(CustomResourceTestClass.new())).is_equal("CustomResourceTestClass")
	assert_result(extract_class_name(OverridenGetClassTestClass.new())).is_equal("OverridenGetClassTestClass")
	assert_result(extract_class_name(AdvancedTestClass.new())).is_equal("AdvancedTestClass")
	# extract inner class name
	assert_result(extract_class_name(AdvancedTestClass.SoundData.new())).is_equal("AdvancedTestClass.SoundData")
	assert_result(extract_class_name(AdvancedTestClass.AtmosphereData.new())).is_equal("AdvancedTestClass.AtmosphereData")
	assert_result(extract_class_name(AdvancedTestClass.Area4D.new(0))).is_equal("AdvancedTestClass.Area4D")
	assert_result(extract_class_name(CustomClass.InnerClassC.new())).is_equal("CustomClass.InnerClassC")


# verify enigne class names are not converted by configured naming convention
@warning_ignore("unused_parameter")
func test_extract_class_name_from_class_path(fuzzer := GodotClassNameFuzzer.new(true, true), fuzzer_iterations := 100) -> void:
	var clazz_name :String = fuzzer.next_value()
	assert_str(GdObjects.extract_class_name_from_class_path(PackedStringArray([clazz_name]))).is_equal(clazz_name)


@warning_ignore("unused_parameter")
func test_extract_class_name_godot_classes(fuzzer := GodotClassNameFuzzer.new(true, true), fuzzer_iterations := 100) -> void:
	var extract_class_name_ := fuzzer.next_value() as String
	var instance :Variant = ClassDB.instantiate(extract_class_name_)
	assert_result(extract_class_name(instance)).is_equal(extract_class_name_)


func test_extract_class_path_by_clazz() -> void:
	# engine classes has no class path
	assert_array(GdObjects.extract_class_path(Animation)).is_empty()
	assert_array(GdObjects.extract_class_path(GDScript)).is_empty()
	assert_array(GdObjects.extract_class_path(Camera3D)).is_empty()
	assert_array(GdObjects.extract_class_path(Tree)).is_empty()
	assert_array(GdObjects.extract_class_path(Node)).is_empty()

	# script classes
	assert_array(GdObjects.extract_class_path(Person))\
		.contains_exactly(["res://addons/gdUnit4/test/resources/core/Person.gd"])
	assert_array(GdObjects.extract_class_path(CustomClass))\
		.contains_exactly(["res://addons/gdUnit4/test/resources/core/CustomClass.gd"])
	assert_array(GdObjects.extract_class_path(CustomNodeTestClass))\
		.contains_exactly(["res://addons/gdUnit4/test/mocker/resources/CustomNodeTestClass.gd"])
	assert_array(GdObjects.extract_class_path(CustomResourceTestClass))\
		.contains_exactly(["res://addons/gdUnit4/test/mocker/resources/CustomResourceTestClass.gd"])
	assert_array(GdObjects.extract_class_path(OverridenGetClassTestClass))\
		.contains_exactly(["res://addons/gdUnit4/test/mocker/resources/OverridenGetClassTestClass.gd"])

	# script inner classes
	assert_array(GdObjects.extract_class_path(CustomClass.InnerClassA))\
		.contains_exactly(["res://addons/gdUnit4/test/resources/core/CustomClass.gd", "InnerClassA"])
	assert_array(GdObjects.extract_class_path(CustomClass.InnerClassB))\
		.contains_exactly(["res://addons/gdUnit4/test/resources/core/CustomClass.gd", "InnerClassB"])
	assert_array(GdObjects.extract_class_path(CustomClass.InnerClassC))\
		.contains_exactly(["res://addons/gdUnit4/test/resources/core/CustomClass.gd", "InnerClassC"])
	assert_array(GdObjects.extract_class_path(AdvancedTestClass.SoundData))\
		.contains_exactly(["res://addons/gdUnit4/test/mocker/resources/AdvancedTestClass.gd", "SoundData"])
	assert_array(GdObjects.extract_class_path(AdvancedTestClass.AtmosphereData))\
		.contains_exactly(["res://addons/gdUnit4/test/mocker/resources/AdvancedTestClass.gd", "AtmosphereData"])
	assert_array(GdObjects.extract_class_path(AdvancedTestClass.Area4D))\
	.contains_exactly(["res://addons/gdUnit4/test/mocker/resources/AdvancedTestClass.gd", "Area4D"])

	# inner inner class
	assert_array(GdObjects.extract_class_path(CustomClass.InnerClassD.InnerInnerClassA))\
		.contains_exactly(["res://addons/gdUnit4/test/resources/core/CustomClass.gd", "InnerClassD", "InnerInnerClassA"])


#func __test_can_instantiate():
#	assert_bool(GdObjects.can_instantiate(GDScript)).is_true()
#	assert_bool(GdObjects.can_instantiate(Node)).is_true()
#	assert_bool(GdObjects.can_instantiate(Tree)).is_true()
#	assert_bool(GdObjects.can_instantiate(Camera3D)).is_true()
#	assert_bool(GdObjects.can_instantiate(Person)).is_true()
#	assert_bool(GdObjects.can_instantiate(CustomClass.InnerClassA)).is_true()
#	assert_bool(GdObjects.can_instantiate(TreeItem)).is_true()
#
# creates a test instance by given class name or resource path
# instances created with auto free
func create_instance(clazz :Variant) -> Object:
	var result := GdObjects.create_instance(clazz)
	if result.is_success():
		return auto_free(result.value())
	return null


func test_create_instance_by_class_name() -> void:
	# instance of engine classes
	assert_object(create_instance(Node))\
		.is_not_null()\
		.is_instanceof(Node)
	assert_object(create_instance(Camera3D))\
		.is_not_null()\
		.is_instanceof(Camera3D)
	# instance of custom classes
	assert_object(create_instance(Person))\
		.is_not_null()\
		.is_instanceof(Person)
	# instance of inner classes
	assert_object(create_instance(CustomClass.InnerClassA))\
		.is_not_null()\
		.is_instanceof(CustomClass.InnerClassA)


func test_extract_class_name_on_null_value() -> void:
	# we can't extract class name from a null value
	assert_result(GdObjects.extract_class_name(null))\
		.is_error()\
		.contains_message("Can't extract class name form a null value.")


func test_is_public_script_class() -> void:
	# snake case format class names
	assert_bool(GdObjects.is_public_script_class("ScriptWithClassName")).is_true()
	assert_bool(GdObjects.is_public_script_class("script_without_class_name")).is_false()
	assert_bool(GdObjects.is_public_script_class("CustomClass")).is_true()
	# inner classes not listed as public classes
	assert_bool(GdObjects.is_public_script_class("CustomClass.InnerClassA")).is_false()


func test_is_instance_scene() -> void:
	# checked none scene objects
	assert_bool(GdObjects.is_instance_scene(RefCounted.new())).is_false()
	assert_bool(GdObjects.is_instance_scene(CustomClass.new())).is_false()
	assert_bool(GdObjects.is_instance_scene(auto_free(Control.new()))).is_false()

	# now check checked a loaded scene
	var resource: PackedScene = load("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	assert_bool(GdObjects.is_instance_scene(resource)).is_false()
	# checked a instance of a scene
	assert_bool(GdObjects.is_instance_scene(auto_free(resource.instantiate()))).is_true()


func test_is_scene_resource_path() -> void:
	assert_bool(GdObjects.is_scene_resource_path(RefCounted.new())).is_false()
	assert_bool(GdObjects.is_scene_resource_path(CustomClass.new())).is_false()
	assert_bool(GdObjects.is_scene_resource_path(auto_free(Control.new()))).is_false()

	# check checked a loaded scene
	var resource := load("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	assert_bool(GdObjects.is_scene_resource_path(resource)).is_false()
	# checked resource path
	assert_bool(GdObjects.is_scene_resource_path("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")).is_true()


func test_extract_class_functions() -> void:
	var functions := GdObjects.extract_class_functions("Resource", [""])
	for f :Dictionary in functions:
		if f["name"] == "get_path":
			assert_str(GdFunctionDescriptor.extract_from(f)._to_string()).is_equal("[Line:(-1,-1)] func get_path() -> String:")

	functions = GdObjects.extract_class_functions("CustomResourceTestClass", ["res://addons/gdUnit4/test/mocker/resources/CustomResourceTestClass.gd"])
	for f :Dictionary in functions:
		if f["name"] == "get_path":
			assert_str(GdFunctionDescriptor.extract_from(f)._to_string()).is_equal("[Line:(-1,-1)] func get_path() -> String:")


func test_all_types() -> void:
	var expected_types :Array[int] = []
	for type_index in TYPE_MAX:
		expected_types.append(type_index)

	expected_types.append(GdObjects.TYPE_VOID)
	expected_types.append(GdObjects.TYPE_VARARG)
	expected_types.append(GdObjects.TYPE_FUNC)
	expected_types.append(GdObjects.TYPE_FUZZER)
	expected_types.append(GdObjects.TYPE_VARIANT)
	assert_array(GdObjects.all_types()).contains_exactly_in_any_order(expected_types)


func test_to_camel_case() -> void:
	assert_str(GdObjects.to_camel_case("MyClassName")).is_equal("myClassName")
	assert_str(GdObjects.to_camel_case("my_class_name")).is_equal("myClassName")
	assert_str(GdObjects.to_camel_case("myClassName")).is_equal("myClassName")


func test_to_pascal_case() -> void:
	assert_str(GdObjects.to_pascal_case("MyClassName")).is_equal("MyClassName")
	assert_str(GdObjects.to_pascal_case("my_class_name")).is_equal("MyClassName")
	assert_str(GdObjects.to_pascal_case("myClassName")).is_equal("MyClassName")


func test_to_snake_case() -> void:
	assert_str(GdObjects.to_snake_case("MyClassName")).is_equal("my_class_name")
	assert_str(GdObjects.to_snake_case("my_class_name")).is_equal("my_class_name")
	assert_str(GdObjects.to_snake_case("myClassName")).is_equal("my_class_name")


func test_is_snake_case() -> void:
	assert_bool(GdObjects.is_snake_case("my_class_name")).is_true()
	assert_bool(GdObjects.is_snake_case("myclassname")).is_true()
	assert_bool(GdObjects.is_snake_case("MyClassName")).is_false()
	assert_bool(GdObjects.is_snake_case("my_class_nameTest")).is_false()


class ObjectWithSceneReferece:
	var _node: Node

	func _init(node: Node) -> void:
		_node = node


func test_is_equal_on_scene_embedded_script() -> void:
	@warning_ignore("unsafe_method_access")
	var node: Node = auto_free(load("res://addons/gdUnit4/test/core/resources/scenes/SceneWithEmbeddedScript.tscn").instantiate())

	GdObjects.equals(ObjectWithSceneReferece.new(node), ObjectWithSceneReferece.new(node), false)
	assert_object(ObjectWithSceneReferece.new(node)).is_equal(ObjectWithSceneReferece.new(node))
