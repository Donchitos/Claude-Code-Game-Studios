@warning_ignore_start("unsafe_method_access")
class_name GdUnitMockerTest
extends GdUnitTestSuite


var resource_path := "res://addons/gdUnit4/test/mocker/resources/"

func before() -> void:
	# disable error pushing for testing
	ProjectSettings.set_setting(GdUnitSettings.REPORT_PUSH_ERRORS, false)


func test_mock_instance_id_is_unique() -> void:
	var m1: Variant = mock(RefCounted)
	var m2: Variant = mock(RefCounted)
	# test the internal instance id is unique
	assert_object(m1).is_not_same(m2)


func test_is_mockable_godot_classes() -> void:
	# verify enigne classes
	for clazz_name in ClassDB.get_class_list():
		# mocking is not allowed for:
		# singleton classes
		# unregistered classes in ClassDB
		# protected classes (name starts with underscore)
		var is_mockable :bool = not Engine.has_singleton(clazz_name) and ClassDB.can_instantiate(clazz_name) and clazz_name.find("_") != 0
		assert_bool(GdUnitMockBuilder.is_mockable(clazz_name)) \
			.override_failure_message("Class '%s' expect mockable %s" % [clazz_name, is_mockable]) \
			.is_equal(is_mockable)


func test_is_mockable_by_class_type() -> void:
	assert_bool(GdUnitMockBuilder.is_mockable(Node)).is_true()
	assert_bool(GdUnitMockBuilder.is_mockable(CSGBox3D)).is_true()


func test_is_mockable_custom_class_type() -> void:
	assert_bool(GdUnitMockBuilder.is_mockable(CustomResourceTestClass)).is_true()
	assert_bool(GdUnitMockBuilder.is_mockable(CustomNodeTestClass)).is_true()


func test_is_mockable_by_script_path() -> void:
	assert_bool(GdUnitMockBuilder.is_mockable(resource_path + "CustomResourceTestClass.gd")).is_true()
	assert_bool(GdUnitMockBuilder.is_mockable(resource_path + "CustomNodeTestClass.gd")).is_true()
	# verify for non scripts
	assert_bool(GdUnitMockBuilder.is_mockable(resource_path + "capsuleshape2d.tres")).is_false()


func test_is_mockable__overriden_func_get_class() -> void:
	# test with class type
	assert_bool(GdUnitMockBuilder.is_mockable(OverridenGetClassTestClass))\
		.override_failure_message("The class 'CustomResourceTestClass' should be mockable when 'func get_class()' is overriden")\
		.is_true()
	# test with resource path
	assert_bool(GdUnitMockBuilder.is_mockable(resource_path + "OverridenGetClassTestClass.gd"))\
		.override_failure_message("The class 'CustomResourceTestClass' should be mockable when 'func get_class()' is overriden")\
		.is_true()


func test_mock_godot_class_fullcheck(fuzzer := GodotClassNameFuzzer.new(), _fuzzer_iterations := 200) -> void:
	var clazz_name := fuzzer.next_value()
	# try to create a mock
	if GdUnitMockBuilder.is_mockable(clazz_name):
		var m: Variant = mock(clazz_name, CALL_REAL_FUNC)
		assert_that(m)\
			.override_failure_message("The class %s should be mockable" % clazz_name)\
			.is_not_null()


func test_mock_by_script_path() -> void:
	assert_that(mock(resource_path + "CustomResourceTestClass.gd")).is_not_null()
	assert_that(mock(resource_path + "CustomNodeTestClass.gd")).is_not_null()


func test_mock_class__overriden_func_get_class() -> void:
	assert_that(mock(OverridenGetClassTestClass)).is_not_null()
	assert_that(mock(resource_path + "OverridenGetClassTestClass.gd")).is_not_null()


func test_mock_fail() -> void:
	# not godot class
	assert_that(mock("CustomResourceTestClass")).is_null()
	# invalid path to script
	assert_that(mock("invalid/CustomResourceTestClass.gd")).is_null()
	# try to mocking an existing instance is not allowed
	assert_that(mock(CustomResourceTestClass.new())).is_null()


func test_mock_special_classes() -> void:
	var m: JavaClass = mock("JavaClass")
	assert_that(m).is_not_null()


func test_mock_Node() -> void:
	var mocked_node: Variant = mock(Node)
	assert_that(mocked_node).is_not_null()

	# test we have initial no interactions checked this mock
	verify_no_interactions(mocked_node)

	# verify we have never called 'get_child_count()'
	verify(mocked_node, 0).get_child_count()

	# call 'get_child_count()' once
	mocked_node.get_child_count()
	# verify we have called at once
	verify(mocked_node).get_child_count()

	# call function 'get_child_count' a second time
	mocked_node.get_child_count()
	# verify we have called at twice
	verify(mocked_node, 2).get_child_count()

	# test mocked function returns default typed value
	assert_that(mocked_node.get_child_count()).is_equal(0)
	# now mock return value for function 'foo' to 'overwriten value'
	do_return(24).on(mocked_node).get_child_count()
	# verify the return value is overwritten
	assert_that(mocked_node.get_child_count()).is_equal(24)


func test_mock_class_with_field_initializer_calling_overridden_method() -> void:
	# GD-1234: field initializer calls a method before `__init()` runs.
	var m: FieldInitCallTestClass = mock(FieldInitCallTestClass)

	assert_that(m).is_not_null()
	assert_str(m.greeting).is_equal("hello from the real function")


func test_mock_source_with_class_name_by_resource_path() -> void:
	var resource_path_ := 'res://addons/gdUnit4/test/mocker/resources/GD-256/world.gd'
	var m: Variant = mock(resource_path_)
	var head :String = m.get_script().source_code.substr(0, 500)
	assert_str(head)\
		.contains("class_name DoubledMockClassMunderwoodPathingWorld")\
		.contains("extends '%s'" % resource_path_)


func test_mock_source_with_class_name_by_class() -> void:
	var resource_path_ := 'res://addons/gdUnit4/test/mocker/resources/GD-256/world.gd'
	var m: Variant = mock(Munderwood_Pathing_World)
	var head :String = m.get_script().source_code.substr(0, 500)
	assert_str(head)\
		.contains("class_name DoubledMockClassMunderwoodPathingWorld")\
		.contains("extends '%s'" % resource_path_)


func test_mock_extends_godot_class() -> void:
	var m: Variant = mock(World3D)
	var head :String = m.get_script().source_code.substr(0, 500)
	assert_str(head)\
		.contains("class_name DoubledMockClassWorld")\
		.contains("extends World3D")


var _test_signal_args := Array()
func _emit_ready(...args: Array) -> void:
	if args.is_empty():
		return
	_test_signal_args = args


func test_mock_Node_func_vararg() -> void:
	# setup
	var mocked_node: Variant = mock(Node)

	# mock return value
	do_return(ERR_CANT_CONNECT).on(mocked_node).rpc("test", "arg1", "arg2", "invalid")
	do_return(ERR_CANT_OPEN).on(mocked_node).rpc("test", "arg1", "argX", any_string())
	do_return(ERR_CANT_CREATE).on(mocked_node).rpc("test", "arg1", "argX", any_int())
	do_return(OK).on(mocked_node).rpc("test", "arg1", "argX", "arg3")
	# verify
	assert_that(mocked_node.rpc("test", "arg1", "arg2", "arg3")).is_equal(OK)
	assert_that(mocked_node.rpc("test", "arg1", "arg2", "invalid")).is_equal(ERR_CANT_CONNECT)
	assert_that(mocked_node.rpc("test", "arg1", "argX", "arg3")).is_equal(OK)
	assert_that(mocked_node.rpc("test", "arg1", "argX", "other")).is_equal(ERR_CANT_OPEN)
	assert_that(mocked_node.rpc("test", "arg1", "argX", 42)).is_equal(ERR_CANT_CREATE)


func test_mock_Node_func_vararg_call_real_func() -> void:
	# setup
	var mocked_node: Variant = mock(Node, CALL_REAL_FUNC)
	assert_that(mocked_node).is_not_null()
	assert_that(_test_signal_args).is_empty()
	mocked_node.connect("ready", _emit_ready)

	# test emit it
	mocked_node.emit_signal("ready", "aa", "bb", "cc")

	# verify is emitted
	verify(mocked_node).emit_signal("ready", "aa", "bb", "cc")
	await get_tree().process_frame
	assert_that(_test_signal_args).is_equal(["aa", "bb", "cc"])

	# test emit it
	mocked_node.emit_signal("ready", "aa", "xxx")

	# verify is emitted
	verify(mocked_node).emit_signal("ready", "aa", "xxx")
	await get_tree().process_frame
	assert_that(_test_signal_args).is_equal(["aa", "xxx"])


class ClassWithSignal:
	signal test_signal_a
	signal test_signal_b

	func foo(arg :int) -> void:
		if arg == 0:
			emit_signal(test_signal_a.get_name(), "aa")
		else:
			emit_signal(test_signal_b.get_name(), "bb", true)

	func bar(arg :int) -> bool:
		if arg == 0:
			emit_signal(test_signal_a.get_name(), "aa")
		else:
			emit_signal(test_signal_b.get_name(), "bb", true)
		return true


func _test_mock_verify_emit_signal() -> void:
	var mocked_node: Variant = mock(ClassWithSignal, CALL_REAL_FUNC)
	assert_that(mocked_node).is_not_null()

	mocked_node.foo(0)
	verify(mocked_node, 1).emit_signal("test_signal_a", "aa")
	verify(mocked_node, 0).emit_signal("test_signal_b", "bb", true)
	reset(mocked_node)

	mocked_node.foo(1)
	verify(mocked_node, 0).emit_signal("test_signal_a", "aa")
	verify(mocked_node, 1).emit_signal("test_signal_b", "bb", true)
	reset(mocked_node)

	mocked_node.bar(0)
	verify(mocked_node, 1).emit_signal("test_signal_a", "aa")
	verify(mocked_node, 0).emit_signal("test_signal_b", "bb", true)
	reset(mocked_node)

	mocked_node.bar(1)
	verify(mocked_node, 0).emit_signal("test_signal_a", "aa")
	verify(mocked_node, 1).emit_signal("test_signal_b", "bb", true)


func test_mock_custom_class_by_class_name() -> void:
	var m: Variant = mock(CustomResourceTestClass)
	assert_that(m).is_not_null()

	# test we have initial no interactions checked this mock
	verify_no_interactions(m)
	# test mocked function returns default typed value
	assert_that(m.foo()).is_equal("")

	# now mock return value for function 'foo' to 'overwriten value'
	do_return("overriden value").on(m).foo()
	# verify the return value is overwritten
	assert_that(m.foo()).is_equal("overriden value")

	# now mock return values by custom arguments
	do_return("arg_1").on(m).bar(1)
	do_return("arg_2").on(m).bar(2)

	assert_that(m.bar(1)).is_equal("arg_1")
	assert_that(m.bar(2)).is_equal("arg_2")


func test_mock_custom_class_by_resource_path() -> void:
	var m: Variant = mock("res://addons/gdUnit4/test/mocker/resources/CustomResourceTestClass.gd")
	assert_that(m).is_not_null()

	# test we have initial no interactions checked this mock
	verify_no_interactions(m)
	# test mocked function returns default typed value
	assert_that(m.foo()).is_equal("")

	# now mock return value for function 'foo' to 'overwriten value'
	do_return("overriden value").on(m).foo()
	# verify the return value is overwritten
	assert_that(m.foo()).is_equal("overriden value")

	# now mock return values by custom arguments
	do_return("arg_1").on(m).bar(1)
	do_return("arg_2").on(m).bar(2)

	assert_that(m.bar(1)).is_equal("arg_1")
	assert_that(m.bar(2)).is_equal("arg_2")


func test_mock_custom_class_func_foo_use_real_func() -> void:
	var m: Variant = mock(CustomResourceTestClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()
	# test mocked function returns value from real function
	assert_that(m.foo()).is_equal("foo")
	# now mock return value for function 'foo' to 'overwriten value'
	do_return("overridden value").on(m).foo()
	# verify the return value is overwritten
	assert_that(m.foo()).is_equal("overridden value")


func test_mock_void_func_not_allowed() -> void:
	var m: Variant = mock(CustomResourceTestClass)
	assert_that(m).is_not_null()
	# test mocked void function returns null by default
	assert_that(m.foo_void()).is_null()

	# try now mock return value for a void function. results into an error
	assert_error(func() -> void:
		do_return("overridden value").on(m).foo_void()
	).is_push_error("Mocking functions with return type void is not allowed!")


func test_mock_void_call_real_func_not_allowed() -> void:
	var m: Variant = mock(CustomResourceTestClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()
	# test mocked void function returns null by default
	assert_that(m.foo_void()).is_null()

	# try now mock return value for a void function. results into an error
	assert_error(func() -> void:
		do_return("overridden value").on(m).foo_void()
	).is_push_error("Mocking functions with return type void is not allowed!")


func test_mock_custom_class_func_foo_call_times() -> void:
	var m: Variant = mock(CustomResourceTestClass)
	assert_that(m).is_not_null()
	verify(m, 0).foo()
	m.foo()
	verify(m, 1).foo()
	m.foo()
	verify(m, 2).foo()
	m.foo()
	m.foo()
	verify(m, 4).foo()


func test_mock_custom_class_func_foo_call_times_real_func() -> void:
	var m: Variant = mock(CustomResourceTestClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()
	verify(m, 0).foo()
	m.foo()
	verify(m, 1).foo()
	m.foo()
	verify(m, 2).foo()
	m.foo()
	m.foo()
	verify(m, 4).foo()


func test_mock_custom_class_func_foo_full_test() -> void:
	var m: Variant = mock(CustomResourceTestClass)
	assert_that(m).is_not_null()
	verify(m, 0).foo()
	assert_that(m.foo()).is_equal("")
	verify(m, 1).foo()
	do_return("new value").on(m).foo()
	verify(m, 1).foo()
	assert_that(m.foo()).is_equal("new value")
	verify(m, 2).foo()


func test_mock_custom_class_func_foo_full_test_real_func() -> void:
	var m: Variant = mock(CustomResourceTestClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()
	verify(m, 0).foo()
	assert_that(m.foo()).is_equal("foo")
	verify(m, 1).foo()
	do_return("new value").on(m).foo()
	verify(m, 1).foo()
	assert_that(m.foo()).is_equal("new value")
	verify(m, 2).foo()


func test_mock_custom_class_func_bar() -> void:
	var m: Variant = mock(CustomResourceTestClass)
	assert_that(m).is_not_null()
	assert_that(m.bar(10)).is_equal("")
	# verify 'bar' with args [10] is called one time at this point
	verify(m, 1).bar(10)
	# verify 'bar' with args [10, 20] is never called at this point
	verify(m, 0).bar(10, 29)
	# verify 'bar' with args [23] is never called at this point
	verify(m, 0).bar(23)

	# now mock return value for function 'bar' with args [10] to 'overwriten value'
	do_return("overridden value").on(m).bar(10)
	# verify the return value is overwritten
	assert_that(m.bar(10)).is_equal("overridden value")
	# finally verify function call times
	verify(m, 2).bar(10)
	verify(m, 0).bar(10, 29)
	verify(m, 0).bar(23)


func test_mock_custom_class_func_bar_real_func() -> void:
	var m: Variant = mock(CustomResourceTestClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()
	assert_that(m.bar(10)).is_equal("test_33")
	# verify 'bar' with args [10] is called one time at this point
	verify(m, 1).bar(10)
	# verify 'bar' with args [10, 20] is never called at this point
	verify(m, 0).bar(10, 29)
	# verify 'bar' with args [23] is never called at this point
	verify(m, 0).bar(23)

	# now mock return value for function 'bar' with args [10] to 'overwriten value'
	do_return("overridden value").on(m).bar(10)
	# verify the return value is overwritten
	assert_that(m.bar(10)).is_equal("overridden value")
	# verify the real implementation is used
	assert_that(m.bar(10, 29)).is_equal("test_39")
	assert_that(m.bar(10, 20, "other")).is_equal("other_30")
	# finally verify function call times
	verify(m, 2).bar(10)
	verify(m, 1).bar(10, 29)
	verify(m, 0).bar(10, 20)
	verify(m, 1).bar(10, 20, "other")


func test_mock_custom_class_func_return_type_enum() -> void:
	var m: Variant = mock(ClassWithEnumReturnTypes)
	assert_that(m).is_not_null()
	verify(m, 0).get_enum()

	# verify enum return default ClassWithEnumReturnTypes.TEST_ENUM.FOO
	assert_that(m.get_enum()).is_equal(ClassWithEnumReturnTypes.TEST_ENUM.FOO)
	do_return(ClassWithEnumReturnTypes.TEST_ENUM.BAR).on(m).get_enum()
	assert_that(m.get_enum()).is_equal(ClassWithEnumReturnTypes.TEST_ENUM.BAR)
	verify(m, 2).get_enum()

	# with call real functions
	var m2: Variant = mock(ClassWithEnumReturnTypes, CALL_REAL_FUNC)
	assert_that(m2).is_not_null()

	# verify enum return type
	assert_that(m2.get_enum()).is_equal(ClassWithEnumReturnTypes.TEST_ENUM.FOO)
	do_return(ClassWithEnumReturnTypes.TEST_ENUM.BAR).on(m2).get_enum()
	assert_that(m2.get_enum()).is_equal(ClassWithEnumReturnTypes.TEST_ENUM.BAR)


func test_mock_custom_class_func_return_type_internal_class_enum() -> void:
	var m: Variant = mock(ClassWithEnumReturnTypes)
	assert_that(m).is_not_null()
	verify(m, 0).get_inner_class_enum()

	# verify enum return default
	assert_that(m.get_inner_class_enum()).is_equal(ClassWithEnumReturnTypes.InnerClass.TEST_ENUM.FOO)
	do_return(ClassWithEnumReturnTypes.InnerClass.TEST_ENUM.BAR).on(m).get_inner_class_enum()
	assert_that(m.get_inner_class_enum()).is_equal(ClassWithEnumReturnTypes.InnerClass.TEST_ENUM.BAR)
	verify(m, 2).get_inner_class_enum()

	# with call real functions
	var m2: Variant = mock(ClassWithEnumReturnTypes, CALL_REAL_FUNC)
	assert_that(m2).is_not_null()

	# verify enum return type
	assert_that(m2.get_inner_class_enum()).is_equal(ClassWithEnumReturnTypes.InnerClass.TEST_ENUM.FOO)
	do_return(ClassWithEnumReturnTypes.InnerClass.TEST_ENUM.BAR).on(m2).get_inner_class_enum()
	assert_that(m2.get_inner_class_enum()).is_equal(ClassWithEnumReturnTypes.InnerClass.TEST_ENUM.BAR)


func test_mock_custom_class_func_return_type_external_class_enum() -> void:
	var m: Variant = mock(ClassWithEnumReturnTypes)
	assert_that(m).is_not_null()
	verify(m, 0).get_external_class_enum()

	# verify enum return default
	assert_that(m.get_external_class_enum()).is_equal(CustomEnums.TEST_ENUM.FOO)
	do_return(CustomEnums.TEST_ENUM.BAR).on(m).get_external_class_enum()
	assert_that(m.get_external_class_enum()).is_equal(CustomEnums.TEST_ENUM.BAR)
	verify(m, 2).get_external_class_enum()

	# with call real functions
	var m2: Variant = mock(ClassWithEnumReturnTypes, CALL_REAL_FUNC)
	assert_that(m2).is_not_null()

	# verify enum return type
	assert_that(m2.get_external_class_enum()).is_equal(CustomEnums.TEST_ENUM.FOO)
	do_return(CustomEnums.TEST_ENUM.BAR).on(m2).get_external_class_enum()
	assert_that(m2.get_external_class_enum()).is_equal(CustomEnums.TEST_ENUM.BAR)


func test_mock_custom_class_extends_Node() -> void:
	var m: Variant = mock(CustomNodeTestClass)
	assert_that(m).is_not_null()

	# test mocked function returns null as default
	assert_that(m.get_child_count()).is_equal(0)
	assert_that(m.get_children()).contains_exactly([])
	# test seters has no affect
	var node :Node = auto_free(Node.new())
	m.add_child(node)
	assert_that(m.get_child_count()).is_equal(0)
	assert_that(m.get_children()).contains_exactly([])
	verify(m, 1).add_child(node)
	verify(m, 2).get_child_count()
	verify(m, 2).get_children()


func test_mock_custom_class_extends_Node_real_func() -> void:
	var m: Variant = mock(CustomNodeTestClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()
	# test mocked function returns default mock value
	assert_that(m.get_child_count()).is_equal(0)
	assert_that(m.get_children()).is_equal([])
	# test real seters used
	var nodeA :Node = auto_free(Node.new())
	var nodeB :Node = auto_free(Node.new())
	var nodeC :Node = auto_free(Node.new())
	m.add_child(nodeA)
	m.add_child(nodeB)
	assert_that(m.get_child_count()).is_equal(2)
	assert_that(m.get_children()).contains_exactly([nodeA, nodeB])
	verify(m, 1).add_child(nodeA)
	verify(m, 1).add_child(nodeB)
	verify(m, 0).add_child(nodeC)
	verify(m, 2).get_child_count()
	verify(m, 2).get_children()


func test_mock_custom_class_extends_other_custom_class() -> void:
	var m: Variant = mock(CustomClassExtendsCustomClass)
	assert_that(mock).is_not_null()

	# foo() form parent class
	verify(m, 0).foo()
	# foo2() overriden
	verify(m, 0).foo2()
	# bar2() from class
	verify(m, 0).bar2()

	assert_that(m.foo()).is_empty()
	assert_that(m.foo2()).is_null()
	assert_that(m.bar2()).is_empty()

	verify(m, 1).foo()
	verify(m, 1).foo2()
	verify(m, 1).bar2()

	# override returns
	do_return("abc1").on(m).foo()
	do_return("abc2").on(m).foo2()
	do_return("abc3").on(m).bar2()

	assert_that(m.foo()).is_equal("abc1")
	assert_that(m.foo2()).is_equal("abc2")
	assert_that(m.bar2()).is_equal("abc3")


func test_mock_custom_class_extends_other_custom_class_call_real_func() -> void:
	var m: Variant = mock(CustomClassExtendsCustomClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()

	# foo() form parent class
	verify(m, 0).foo()
	# foo2() overriden
	verify(m, 0).foo2()
	# bar2() from class
	verify(m, 0).bar2()

	assert_that(m.foo()).is_equal("foo")
	assert_that(m.foo2()).is_equal("foo2 overriden")
	assert_that(m.bar2()).is_equal("test_65")

	verify(m, 1).foo()
	verify(m, 1).foo2()
	verify(m, 1).bar2()

	# override returns
	do_return("abc1").on(m).foo()
	do_return("abc2").on(m).foo2()
	do_return("abc3").on(m).bar2()

	assert_that(m.foo()).is_equal("abc1")
	assert_that(m.foo2()).is_equal("abc2")
	assert_that(m.bar2()).is_equal("abc3")


func test_mock_static_func() -> void:
	var m: Variant = mock(CustomNodeTestClass)
	assert_that(m).is_not_null()
	# initial not called
	verify(m, 0).static_test()
	verify(m, 0).static_test_void()

	assert_that(m.static_test()).is_equal("")
	assert_that(m.static_test_void()).is_null()

	verify(m, 1).static_test()
	verify(m, 1).static_test_void()
	m.static_test()
	m.static_test_void()
	m.static_test_void()
	verify(m, 2).static_test()
	verify(m, 3).static_test_void()


func test_mock_static_func_real_func() -> void:
	var m: Variant = mock(CustomNodeTestClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()
	# initial not called
	verify(m, 0).static_test()
	verify(m, 0).static_test_void()

	assert_that(m.static_test()).is_equal(CustomNodeTestClass.STATIC_FUNC_RETURN_VALUE)
	assert_that(m.static_test_void()).is_null()

	verify(m, 1).static_test()
	verify(m, 1).static_test_void()
	m.static_test()
	m.static_test_void()
	m.static_test_void()
	verify(m, 2).static_test()
	verify(m, 3).static_test_void()


func test_mock_custom_class_assert_has_no_side_affect() -> void:
	var m: Variant = mock(CustomNodeTestClass)
	assert_that(m).is_not_null()
	var node := Node.new()
	# verify the assertions has no side affect checked mocked object
	verify(m, 0).add_child(node)
	# expect no change checked childrens
	assert_that(m.get_children()).contains_exactly([])

	m.add_child(node)
	# try thre times 'assert_called' to see it has no affect to the mock
	verify(m, 1).add_child(node)
	verify(m, 1).add_child(node)
	verify(m, 1).add_child(node)
	assert_that(m.get_children()).contains_exactly([])
	# needs to be manually freed
	node.free()


func test_mock_custom_class_assert_has_no_side_affect_real_func() -> void:
	var m: Variant = mock(CustomNodeTestClass, CALL_REAL_FUNC)
	assert_that(m).is_not_null()
	var node := Node.new()
	# verify the assertions has no side affect checked mocked object
	verify(m, 0).add_child(node)
	# expect no change checked childrens
	assert_that(m.get_children()).contains_exactly([])

	m.add_child(node)
	# try thre times 'assert_called' to see it has no affect to the mock
	verify(m, 1).add_child(node)
	verify(m, 1).add_child(node)
	verify(m, 1).add_child(node)
	assert_that(m.get_children()).contains_exactly([node])


# This test verifies a function is calling other internally functions
# to collect the access times and the override return value is working as expected
func _test_mock_advanced_func_path() -> void:
	var m: Variant = mock(AdvancedTestClass, CALL_REAL_FUNC)
	# initial nothing is called
	verify(m, 0).select(AdvancedTestClass.A)
	verify(m, 0).select(AdvancedTestClass.B)
	verify(m, 0).select(AdvancedTestClass.C)
	verify(m, 0).a()
	verify(m, 0).b()
	verify(m, 0).c()

	# the function select() swiches based checked input argument to function a(), b() or c()
	# call select where called internally func a() and returned "a"
	assert_that(m.select(AdvancedTestClass.A)).is_equal("a")
	# verify when call select() is also calling original func a()
	verify(m, 1).select(AdvancedTestClass.A)
	verify(m, 1).a()

	# call select again wiht overriden return value for func a()
	do_return("overridden a func").on(m).a()
	assert_that(m.select(AdvancedTestClass.A)).is_equal("overridden a func")

	# verify at this time select() and a() is called two times
	verify(m, 2).select(AdvancedTestClass.A)
	verify(m, 0).select(AdvancedTestClass.B)
	verify(m, 0).select(AdvancedTestClass.C)
	verify(m, 2).a()
	verify(m, 0).b()
	verify(m, 0).c()

	# finally use select to switch to internally func c()
	assert_that(m.select(AdvancedTestClass.C)).is_equal("c")
	verify(m, 2).select(AdvancedTestClass.A)
	verify(m, 0).select(AdvancedTestClass.B)
	verify(m, 1).select(AdvancedTestClass.C)
	verify(m, 2).a()
	verify(m, 0).b()
	verify(m, 1).c()


func _test_mock_godot_class_calls_sub_function() -> void:
	var m: Variant = mock(MeshInstance3D, CALL_REAL_FUNC)
	verify(m, 0)._mesh_changed()
	m.set_mesh(QuadMesh.new())
	verify(m, 1).set_mesh(any_class(Mesh))
	verify(m, 1)._mesh_changed()


func test_mock_class_with_inner_class() -> void:
	var mock_advanced: Variant = mock(AdvancedTestClass)
	assert_that(mock_advanced).is_not_null()

	var mock_a: Variant = mock(AdvancedTestClass.SoundData)
	assert_object(mock_a).is_not_null()

	var mock_b: Variant = mock(AdvancedTestClass.AtmosphereData)
	assert_object(mock_b).is_not_null()

	var mock_c: Variant = mock(AdvancedTestClass.Area4D)
	assert_object(mock_c).is_not_null()


func test_mock_class_with_property_getter_and_setter() -> void:
	var c :Variant = mock(ClassWithParameterGetterSetter)

	# inital value
	assert_int(c._session_count).is_equal(42)

	# overwrite it by 10
	c._session_count = 10

	# verify the paramater is set to 10
	assert_int(c._session_count).is_equal(10)
	# verify the method still returns the default value
	assert_int(c.session_count()).is_equal(0)

	# mock the function to return a cutom value
	do_return(23).on(c).session_count()
	# verify the method now returns the new value
	assert_int(c.session_count()).is_equal(23)


func test_do_return() -> void:
	var mocked_node: Variant = mock(Node)

	# is return 0 by default
	mocked_node.get_child_count()
	# configure to return 10 when 'get_child_count()' is called
	do_return(10).on(mocked_node).get_child_count()
	# will now return 10
	assert_int(mocked_node.get_child_count()).is_equal(10)

	# is return 'null' by default
	var node: Node = mocked_node.get_child(0)
	assert_object(node).is_null()

	# configure to return a mocked 'Camera3D' for child 0
	do_return(mock(Camera3D)).on(mocked_node).get_child(0)
	# configure to return a mocked 'Area3D' for child 1
	do_return(mock(Area3D)).on(mocked_node).get_child(1)

	# will now return the Camera3D node
	var node0: Node = mocked_node.get_child(0)
	assert_object(node0).is_instanceof(Camera3D)
	# will now return the Area3D node
	var node1: Node = mocked_node.get_child(1)
	assert_object(node1).is_instanceof(Area3D)


func test_matching_is_sorted() -> void:
	var mocked_node: Variant = mock(Node)
	do_return(null).on(mocked_node).get_child(any(), false)
	do_return(null).on(mocked_node).get_child(1, false)
	do_return(null).on(mocked_node).get_child(10, false)
	do_return(null).on(mocked_node).get_child(any(), true)
	do_return(null).on(mocked_node).get_child(3, true)

	# get the sorted mocked args as array
	var mocked_args :Array = mocked_node.__doubler_state().return_values.get("get_child").keys()
	assert_array(mocked_args).has_size(5)

	# we expect all argument matchers are sorted to the end
	var first_arguments := mocked_args.map(func (v :Array) -> Variant: return v[0])
	assert_int(first_arguments[0]).is_equal(3)
	assert_int(first_arguments[1]).is_equal(10)
	assert_int(first_arguments[2]).is_equal(1)
	assert_object(first_arguments[3]).is_instanceof(GdUnitArgumentMatcher)
	assert_object(first_arguments[4]).is_instanceof(GdUnitArgumentMatcher)


func test_do_return_with_matchers() -> void:
	var mocked_node: Variant = mock(Node)
	var childN :Node = auto_free(Node2D.new())
	var child1 :Node = auto_free(Node2D.new())
	var child10 :Node = auto_free(Node2D.new())

	# for any index return childN by using any() matcher
	do_return(childN).on(mocked_node).get_child(any(), false)
	# for index 1 and 10 do return 'child1' and 'child10'
	do_return(child1).on(mocked_node).get_child(1, false)
	do_return(child10).on(mocked_node).get_child(10, false)
	# for any index and flag true, we return null by using the 'any_int' matcher
	do_return(null).on(mocked_node).get_child(any_int(), true)

	assert_that(mocked_node.get_child(0, true)).is_null()
	assert_that(mocked_node.get_child(1, true)).is_null()
	assert_that(mocked_node.get_child(2, true)).is_null()
	assert_that(mocked_node.get_child(10, true)).is_null()
	assert_that(mocked_node.get_child(0)).is_same(childN)
	assert_that(mocked_node.get_child(1)).is_same(child1)
	assert_that(mocked_node.get_child(2)).is_same(childN)
	assert_that(mocked_node.get_child(3)).is_same(childN)
	assert_that(mocked_node.get_child(4)).is_same(childN)
	assert_that(mocked_node.get_child(5)).is_same(childN)
	assert_that(mocked_node.get_child(6)).is_same(childN)
	assert_that(mocked_node.get_child(7)).is_same(childN)
	assert_that(mocked_node.get_child(8)).is_same(childN)
	assert_that(mocked_node.get_child(9)).is_same(childN)
	assert_that(mocked_node.get_child(10)).is_same(child10)


func test_example_verify() -> void:
	var mocked_node: Variant = mock(Node)

	# verify we have no interactions currently checked this instance
	verify_no_interactions(mocked_node)

	# call with different arguments
	mocked_node.set_process(false) # 1 times
	mocked_node.set_process(true) # 1 times
	mocked_node.set_process(true) # 2 times

	# verify how often we called the function with different argument
	verify(mocked_node, 2).set_process(true) # in sum two times with true
	verify(mocked_node, 1).set_process(false)# in sum one time with false

	# verify total sum by using an argument matcher
	verify(mocked_node, 3).set_process(any_bool())


func test_verify_fail() -> void:
	var mocked_node: Variant = mock(Node)

	# interact two time
	mocked_node.set_process(true) # 1 times
	mocked_node.set_process(true) # 2 times

	# verify we interacts two times
	verify(mocked_node, 2).set_process(true)

	# verify should fail because we interacts two times and not one
	var expected_error := """
		Expecting interaction on:
			'set_process(true :bool)'	1 time's
		But found interactions on:
			'set_process(true :bool)'	2 time's""" \
			.dedent().trim_prefix("\n").replace("\r", "")
	assert_failure(func() -> void: verify(mocked_node, 1).set_process(true)) \
		.is_failed() \
		.has_message(expected_error)


func test_verify_string_argument_mach_case_sensitive() -> void:
	var mocked_node: Variant = mock(Node)

	# Act
	mocked_node.set_name("foo")

	# Verify it fails by checking the arguments case sensitive
	var expected_error := """
		Expecting interaction on:
			'set_name(Foo :String)'	1 time's
		But found interactions on:
			'set_name(foo :String)'	1 time's""" \
		.dedent().trim_prefix("\n").replace("\r", "")
	assert_failure(func() -> void: verify(mocked_node).set_name("Foo")) \
		.is_failed() \
		.has_message(expected_error)

	# Finally we verify by using the correct lowercase argument
	verify(mocked_node).set_name("foo")
	verify_no_more_interactions(mocked_node)


func test_verify_func_interaction_wiht_PoolStringArray() -> void:
	var mocked: Variant = mock(ClassWithPoolStringArrayFunc)

	mocked.set_values(PackedStringArray())

	verify(mocked).set_values(PackedStringArray())
	verify_no_more_interactions(mocked)


func test_verify_func_interaction_wiht_PoolStringArray_fail() -> void:
	var mocked: Variant = mock(ClassWithPoolStringArrayFunc)

	mocked.set_values(PackedStringArray())

	# try to verify with default array type instead of PackedStringArray type
	var expected_error := """
		Expecting interaction on:
			'set_values([] :Array)'	1 time's
		But found interactions on:
			'set_values([] :PackedStringArray)'	1 time's""" \
			.dedent().trim_prefix("\n").replace("\r", "")
	assert_failure(func() -> void: verify(mocked, 1).set_values([])) \
		.is_failed() \
		.has_message(expected_error)

	reset(mocked)
	# try again with called two times and different args
	mocked.set_values(PackedStringArray())
	mocked.set_values(PackedStringArray(["a", "b"]))
	mocked.set_values([1, 2])
	expected_error = """
		Expecting interaction on:
			'set_values([] :Array)'	1 time's
		But found interactions on:
			'set_values([] :PackedStringArray)'	1 time's
			'set_values(["a", "b"] :PackedStringArray)'	1 time's
			'set_values([1, 2] :Array)'	1 time's""" \
			.dedent().trim_prefix("\n").replace("\r", "")
	assert_failure(func() -> void: verify(mocked, 1).set_values([])) \
		.is_failed() \
		.has_message(expected_error)


func test_reset() -> void:
	var mocked_node: Variant = mock(Node)

	# call with different arguments
	mocked_node.set_process(false) # 1 times
	mocked_node.set_process(true) # 1 times
	mocked_node.set_process(true) # 2 times

	verify(mocked_node, 2).set_process(true)
	verify(mocked_node, 1).set_process(false)

	# now reset the mock
	reset(mocked_node)
	# verify all counters have been reset
	verify_no_interactions(mocked_node)


func test_verify_no_interactions() -> void:
	var mocked_node: Variant = mock(Node)

	# verify we have no interactions checked this mock
	verify_no_interactions(mocked_node)


func test_verify_no_interactions_fails() -> void:
	var mocked_node: Variant = mock(Node)

	# interact
	mocked_node.set_process(false) # 1 times
	mocked_node.set_process(true) # 1 times
	mocked_node.set_process(true) # 2 times

	var expected_error :="""
		Expecting no more interactions!
		But found interactions on:
			'set_process(false :bool)'	1 time's
			'set_process(true :bool)'	2 time's""" \
			.dedent().trim_prefix("\n")
	# it should fail because we have interactions
	assert_failure(func() -> void: verify_no_interactions(mocked_node)) \
		.is_failed() \
		.has_message(expected_error)


func test_verify_no_more_interactions() -> void:
	var mocked_node: Variant = mock(Node)

	mocked_node.is_ancestor_of(null)
	mocked_node.set_process(false)
	mocked_node.set_process(true)
	mocked_node.set_process(true)

	# verify for called functions
	verify(mocked_node, 1).is_ancestor_of(null)
	verify(mocked_node, 2).set_process(true)
	verify(mocked_node, 1).set_process(false)

	# There should be no more interactions checked this mock
	verify_no_more_interactions(mocked_node)


func test_verify_no_more_interactions_but_has() -> void:
	var mocked_node: Variant = mock(Node)

	mocked_node.is_ancestor_of(null)
	mocked_node.set_process(false)
	mocked_node.set_process(true)
	mocked_node.set_process(true)

	# now we simulate extra calls that we are not explicit verify
	mocked_node.is_inside_tree()
	mocked_node.is_inside_tree()
	# a function with default agrs
	mocked_node.find_child("mask")
	# same function again with custom agrs
	mocked_node.find_child("mask", false, false)

	# verify 'all' exclusive the 'extra calls' functions
	verify(mocked_node, 1).is_ancestor_of(null)
	verify(mocked_node, 2).set_process(true)
	verify(mocked_node, 1).set_process(false)

	# now use 'verify_no_more_interactions' to check we have no more interactions checked this mock
	# but should fail with a collecion of all not validated interactions
	var expected_error :="""
		Expecting no more interactions!
		But found interactions on:
			'is_inside_tree()'	2 time's
			'find_child(mask :String, true :bool, true :bool)'	1 time's
			'find_child(mask :String, false :bool, false :bool)'	1 time's""" \
			.dedent().trim_prefix("\n")
	assert_failure(func() -> void: verify_no_more_interactions(mocked_node)) \
		.is_failed() \
		.has_message(expected_error)


func test_mock_snake_case_named_class_by_resource_path() -> void:
	var mock_a: Variant = mock("res://addons/gdUnit4/test/mocker/resources/snake_case.gd")
	assert_object(mock_a).is_not_null()

	mock_a.custom_func()
	verify(mock_a).custom_func()
	verify_no_more_interactions(mock_a)

	var mock_b: Variant = mock("res://addons/gdUnit4/test/mocker/resources/snake_case_class_name.gd")
	assert_object(mock_b).is_not_null()

	mock_b.custom_func()
	verify(mock_b).custom_func()
	verify_no_more_interactions(mock_b)


func test_mock_snake_case_named_godot_class_by_name() -> void:
	# try checked Godot class
	var mocked_tcp_server: Variant = mock("TCPServer")
	assert_object(mocked_tcp_server).is_not_null()

	mocked_tcp_server.is_listening()
	mocked_tcp_server.is_connection_available()
	verify(mocked_tcp_server).is_listening()
	verify(mocked_tcp_server).is_connection_available()
	verify_no_more_interactions(mocked_tcp_server)


func test_mock_snake_case_named_class_by_class() -> void:
	var m: Variant = mock(snake_case_class_name)
	assert_object(m).is_not_null()

	m.custom_func()
	verify(m).custom_func()
	verify_no_more_interactions(m)

	# try checked Godot class
	var mocked_tcp_server: Variant = mock(TCPServer)
	assert_object(mocked_tcp_server).is_not_null()

	mocked_tcp_server.is_listening()
	mocked_tcp_server.is_connection_available()
	verify(mocked_tcp_server).is_listening()
	verify(mocked_tcp_server).is_connection_available()
	verify_no_more_interactions(mocked_tcp_server)


func test_mock_func_with_default_build_in_type() -> void:
	var m: Variant = mock(ClassWithDefaultBuildIntTypes)
	assert_object(m).is_not_null()
	# call with default arg
	m.foo("abc")
	m.bar("def")
	verify(m).foo("abc", Color.RED)
	verify(m).bar("def", Vector3.FORWARD, AABB())
	verify_no_more_interactions(m)

	# call with custom color arg
	m.foo("abc", Color.BLUE)
	m.bar("def", Vector3.DOWN, AABB(Vector3.ONE, Vector3.ZERO))
	verify(m).foo("abc", Color.BLUE)
	verify(m).bar("def", Vector3.DOWN, AABB(Vector3.ONE, Vector3.ZERO))
	verify_no_more_interactions(m)


func test_mock_virtual_function_is_not_called_twice() -> void:
	# this test verifies the special handling of virtual functions by Godot
	# virtual functions are handeld in a special way
	# node.cpp
	# case NOTIFICATION_READY: {
	#
	#    if (get_script_instance()) {
	#
	#       Variant::CallError err;
	#       get_script_instance()->call_multilevel_reversed(SceneStringNames::get_singleton()->_ready,NULL,0);
	#    }

	var m: Variant = mock(ClassWithOverridenVirtuals, CALL_REAL_FUNC)
	assert_object(m).is_not_null()

	# inital constructor
	assert_that(m._x).is_equal("_init")

	# add_child calls internally by "default" _ready() where is a virtual function
	@warning_ignore("unsafe_cast")
	add_child(m as Node)

	# verify _ready func is only once called
	assert_that(m._x).is_equal("_ready")

	# now simulate an input event calls '_input'
	var action := InputEventKey.new()
	action.pressed = false
	action.keycode = KEY_ENTER
	get_tree().root.push_input(action)
	assert_that(m._x).is_equal("ui_accept")


func test_mock_scene_by_path() -> void:
	var mocked_scene: Variant = mock("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	assert_object(mocked_scene).is_not_null()
	assert_object(mocked_scene.get_script()).is_not_null()
	assert_str(mocked_scene.get_script().resource_name).starts_with("MockTestScene")
	# check is mocked scene registered for auto freeing
	assert_bool(GdUnitMemoryObserver.is_marked_auto_free(mocked_scene)).is_true()


func test_mock_scene_by_resource() -> void:
	var resource: Object = load("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	var mocked_scene: Variant = mock(resource)
	assert_object(mocked_scene).is_not_null()
	assert_object(mocked_scene.get_script()).is_not_null()
	assert_str(mocked_scene.get_script().resource_name).starts_with("MockTestScene")
	# check is mocked scene registered for auto freeing
	assert_bool(GdUnitMemoryObserver.is_marked_auto_free(mocked_scene)).is_true()


func test_mock_scene_by_instance() -> void:
	var resource := load("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	var instance :Control = auto_free(resource.instantiate())
	var mocked_scene: Variant = mock(instance)
	# must fail mock an instance is not allowed
	assert_object(mocked_scene).is_null()


func test_mock_scene_by_path_fail_has_no_script_attached() -> void:
	var mocked_scene: Variant = mock("res://addons/gdUnit4/test/mocker/resources/scenes/TestSceneWithoutScript.tscn")
	assert_object(mocked_scene).is_null()


func test_mock_scene_variables_is_set() -> void:
	var mocked_scene: Variant = mock("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	assert_object(mocked_scene).is_not_null()

	# Add as child to a node to trigger _ready to initalize all variables
	@warning_ignore("unsafe_cast")
	add_child(mocked_scene as Node)
	assert_object(mocked_scene._box1).is_not_null()
	assert_object(mocked_scene._box2).is_not_null()
	assert_object(mocked_scene._box3).is_not_null()

	# check signals are connected
	@warning_ignore("unsafe_cast")
	assert_bool(mocked_scene.is_connected("panel_color_change", Callable(mocked_scene as Object, "_on_panel_color_changed")))

	# check exports
	assert_str(mocked_scene._initial_color.to_html()).is_equal(Color.RED.to_html())


func test_mock_scene_execute_func_yielded() -> void:
	var mocked_scene: Variant = mock("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	assert_object(mocked_scene).is_not_null()
	@warning_ignore("unsafe_cast")
	add_child(mocked_scene as Node)
	# execute the 'color_cycle' func where emits three signals
	# using yield to wait for function is completed
	var result :String = await mocked_scene.color_cycle()
	# verify the return value of 'color_cycle'
	assert_str(result).is_equal("black")

	verify(mocked_scene)._on_panel_color_changed(mocked_scene._box1, Color.RED)
	verify(mocked_scene)._on_panel_color_changed(mocked_scene._box1, Color.BLUE)
	verify(mocked_scene)._on_panel_color_changed(mocked_scene._box1, Color.GREEN)


class Base:
	func _init(_value :String) -> void:
		pass


class Foo extends Base:
	func _init() -> void:
		super("test")


func test_mock_with_inheritance_method() -> void:
	var foo: Variant = mock(Foo)
	assert_object(foo).is_not_null()


func test_mock_func_default_arg_dict() -> void:
	var mock_obj :ClassWithDictionaryDefaultArguments = mock(ClassWithDictionaryDefaultArguments)

	do_return(["a", "b"]).on(mock_obj).on_dictionary_case1(any_dictionary())
	verify_no_interactions(mock_obj)

	assert_array(mock_obj.on_dictionary_case1({})).contains_exactly(["a", "b"])
	verify(mock_obj).on_dictionary_case1({})


func test_mock_with_variant_as_defaults() -> void:
	var mock_obj: Variant = mock(ClassWithVariantDefaultArguments)
	assert_object(mock_obj).is_not_null()


# https://github.com/MikeSchulze/gdUnit4/issues/742
func test_mock_with_await_function() -> void:
	@warning_ignore("unsafe_cast")
	var mocked_instance := mock(ClassWithAwaitFunc, CALL_REAL_FUNC) as ClassWithAwaitFunc
	add_child(mocked_instance)

	await mocked_instance.await_function()

	verify(mocked_instance, 1).await_function()
