class_name GdUnitSpyTest  # gdlint: ignore=max-public-methods
extends GdUnitTestSuite


func before() -> void:
	# we disable the error reporting to do not spam the logs
	ProjectSettings.set_setting(GdUnitSettings.REPORT_ASSERT_ERRORS, false)


func test_spy_instance_id_is_unique() -> void:
	var m1  :Variant = spy(RefCounted.new())
	var m2  :Variant = spy(RefCounted.new())
	# test the internal instance id is unique
	assert_object(m1).is_not_same(m2)


func test_cant_spy_is_not_a_instance() -> void:
	# returns null because spy needs an 'real' instance to by spy checked
	var spy_node :Variant = spy(Node)
	assert_object(spy_node).is_null()


func test_spy_on_Node() -> void:
	var instance :Node = auto_free(Node.new())
	var spy_node :Variant = spy(instance)

	# verify we have no interactions currently checked this instance
	verify_no_interactions(spy_node)

	assert_object(spy_node)\
		.is_not_null()\
		.is_instanceof(Node)\
		.is_not_same(instance)

	# call first time
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(false)

	# verify is called one times@warning_ignore("unsafe_method_access")
	@warning_ignore("unsafe_method_access")
	verify(spy_node).set_process(false)
	# just double check that verify has no affect to the counter
	@warning_ignore("unsafe_method_access")
	verify(spy_node).set_process(false)

	# call a scond time
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(false)
	# verify is called two times
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 2).set_process(false)
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 2).set_process(false)


func test_spy_source_with_class_name_by_resource_path() -> void:
	var instance :Object = auto_free(_load('res://addons/gdUnit4/test/mocker/resources/GD-256/world.gd').new())
	var m :Variant = spy(instance)
	@warning_ignore("unsafe_method_access")
	var head :String = m.get_script().source_code.substr(0, 500)
	assert_str(head)\
		.contains("class_name DoubledSpyClassMunderwoodPathingWorld")\
		.contains("extends 'res://addons/gdUnit4/test/mocker/resources/GD-256/world.gd'")


func test_spy_source_with_class_name_by_class() -> void:
	var m :Variant = spy(auto_free(Munderwood_Pathing_World.new()))
	@warning_ignore("unsafe_method_access")
	var head :String = m.get_script().source_code.substr(0, 500)
	assert_str(head)\
		.contains("class_name DoubledSpyClassMunderwoodPathingWorld")\
		.contains("extends 'res://addons/gdUnit4/test/mocker/resources/GD-256/world.gd'")


func test_spy_extends_godot_class() -> void:
	var m :Variant = spy(auto_free(World3D.new()))
	@warning_ignore("unsafe_method_access")
	var head :String = m.get_script().source_code.substr(0, 500)
	assert_str(head)\
		.contains("class_name DoubledSpyClassWorld")\
		.contains("extends World3D")


func test_spy_on_custom_class() -> void:
	var instance :AdvancedTestClass = auto_free(AdvancedTestClass.new())
	var spy_instance :Variant = spy(instance)

	# verify we have currently no interactions
	verify_no_interactions(spy_instance)

	assert_object(spy_instance)\
		.is_not_null()\
		.is_instanceof(AdvancedTestClass)\
		.is_not_same(instance)

	@warning_ignore("unsafe_method_access")
	spy_instance.setup_local_to_scene()
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).setup_local_to_scene()

	# call first time script func with different arguments
	@warning_ignore("unsafe_method_access")
	spy_instance.get_area("test_a")
	@warning_ignore("unsafe_method_access")
	spy_instance.get_area("test_b")
	@warning_ignore("unsafe_method_access")
	spy_instance.get_area("test_c")

	# verify is each called only one time for different arguments
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).get_area("test_a")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).get_area("test_b")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).get_area("test_c")
	# an second call with arg "test_c"
	@warning_ignore("unsafe_method_access")
	spy_instance.get_area("test_c")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).get_area("test_a")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).get_area("test_b")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 2).get_area("test_c")

	# verify if a not used argument not counted
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 0).get_area("test_no")


# GD-291 https://github.com/MikeSchulze/gdUnit4/issues/291
func test_spy_class_with_custom_formattings() -> void:
	var resource := _load("res://addons/gdUnit4/test/mocker/resources/ClassWithCustomFormattings.gd")
	var do_spy :Variant = spy(auto_free(resource.new("test")))
	@warning_ignore("unsafe_method_access")
	do_spy.a1("set_name", "", true)
	@warning_ignore("unsafe_method_access")
	verify(do_spy, 1).a1("set_name", "", true)
	verify_no_more_interactions(do_spy)
	assert_failure(func() -> void: verify_no_interactions(do_spy))\
		.is_failed() \
		.has_line(140)


func test_spy_copied_class_members() -> void:
	var instance: TestPerson = auto_free(_load("res://addons/gdUnit4/test/mocker/resources/TestPerson.gd").new("user-x", "street", 56616))
	assert_that(instance._name).is_equal("user-x")
	assert_that(instance._value).is_equal(1024)
	assert_that(instance._address._street).is_equal("street")
	assert_that(instance._address._code).is_equal(56616)

	# spy it
	var spy_instance :Variant = spy(instance)
	reset(spy_instance)

	# verify members are inital copied
	assert_that(spy_instance._name).is_equal("user-x")
	assert_that(spy_instance._value).is_equal(1024)
	assert_that(spy_instance._address._street).is_equal("street")
	assert_that(spy_instance._address._code).is_equal(56616)

	spy_instance._value = 2048
	assert_that(instance._value).is_equal(1024)
	assert_that(spy_instance._value).is_equal(2048)


func test_spy_copied_class_members_on_node() -> void:
	var node :Node = auto_free(Node.new())
	# checked a fresh node the name is empty and results into a error when copied at spy
	# E 0:00:01.518   set_name: Condition "name == """ is true.
	# C++ Source>  scene/main/node.cpp:934 @ set_name()
	# we set a placeholder instead
	assert_that(spy(node).name).is_equal("<empty>")

	node.set_name("foo")
	assert_that(spy(node).name).is_equal("foo")


func test_spy_on_inner_class() -> void:
	var instance :AdvancedTestClass.AtmosphereData = auto_free(AdvancedTestClass.AtmosphereData.new())
	var spy_instance :AdvancedTestClass.AtmosphereData = spy(instance)

	# verify we have currently no interactions
	verify_no_interactions(spy_instance)

	assert_object(spy_instance)\
		.is_not_null()\
		.is_instanceof(AdvancedTestClass.AtmosphereData)\
		.is_not_same(instance)

	spy_instance.set_data(AdvancedTestClass.AtmosphereData.SMOKY, 1.2)
	spy_instance.set_data(AdvancedTestClass.AtmosphereData.SMOKY, 1.3)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).set_data(AdvancedTestClass.AtmosphereData.SMOKY, 1.2)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).set_data(AdvancedTestClass.AtmosphereData.SMOKY, 1.3)


func test_spy_on_singleton() -> void:
	assert_error(func () -> void:
		var spy_node_ :Variant = spy(Input)
		assert_object(spy_node_).is_null()
	).is_push_error("Spy on a Singleton is not allowed! 'Input'")


func test_example_verify() -> void:
	var instance :Node = auto_free(Node.new())
	var spy_node :Variant = spy(instance)

	# verify we have no interactions currently checked this instance
	verify_no_interactions(spy_node)

	# call with different arguments
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(false) # 1 times
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true) # 1 times
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true) # 2 times

	# verify how often we called the function with different argument
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 2).set_process(true) # in sum two times with true
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 1).set_process(false)# in sum one time with false

	# verify total sum by using an argument matcher
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 3).set_process(any_bool())


func test_verify_fail() -> void:
	var instance :Node = auto_free(Node.new())
	var spy_node :Variant = spy(instance)

	# interact two time
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true) # 1 times
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true) # 2 times

	# verify we interacts two times
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 2).set_process(true)

	# verify should fail because we interacts two times and not one
	var expected_error := """
		Expecting interaction on:
			'set_process(true :bool)'	1 time's
		But found interactions on:
			'set_process(true :bool)'	2 time's""" \
			.dedent().trim_prefix("\n")
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: verify(spy_node, 1).set_process(true)) \
		.is_failed() \
		.has_line(254) \
		.has_message(expected_error)


func test_verify_func_interaction_wiht_PoolStringArray() -> void:
	var spy_instance :ClassWithPoolStringArrayFunc = spy(ClassWithPoolStringArrayFunc.new())

	spy_instance.set_values(PackedStringArray())

	@warning_ignore("unsafe_method_access")
	verify(spy_instance).set_values(PackedStringArray())
	verify_no_more_interactions(spy_instance)


func test_verify_func_interaction_wiht_PackedStringArray_fail() -> void:
	var spy_instance :ClassWithPoolStringArrayFunc = spy(ClassWithPoolStringArrayFunc.new())

	spy_instance.set_values(PackedStringArray())

	# try to verify with default array type instead of PackedStringArray type
	var expected_error := """
		Expecting interaction on:
			'set_values([] :Array)'	1 time's
		But found interactions on:
			'set_values([] :PackedStringArray)'	1 time's""" \
			.dedent().trim_prefix("\n")
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: verify(spy_instance, 1).set_values([])) \
		.is_failed() \
		.has_line(283) \
		.has_message(expected_error)

	reset(spy_instance)
	# try again with called two times and different args
	spy_instance.set_values(PackedStringArray())
	spy_instance.set_values(PackedStringArray(["a", "b"]))
	spy_instance.set_values([1, 2])
	expected_error = """
		Expecting interaction on:
			'set_values([] :Array)'	1 time's
		But found interactions on:
			'set_values([] :PackedStringArray)'	1 time's
			'set_values(["a", "b"] :PackedStringArray)'	1 time's
			'set_values([1, 2] :Array)'	1 time's""" \
			.dedent().trim_prefix("\n")
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: verify(spy_instance, 1).set_values([])) \
		.is_failed() \
		.has_line(302) \
		.has_message(expected_error)


func test_reset() -> void:
	var instance :Node = auto_free(Node.new())
	var spy_node :Variant = spy(instance)

	# call with different arguments
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(false) # 1 times
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true) # 1 times
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true) # 2 times

	@warning_ignore("unsafe_method_access")
	verify(spy_node, 2).set_process(true)
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 1).set_process(false)

	# now reset the spy
	reset(spy_node)
	# verify all counters have been reset
	verify_no_interactions(spy_node)


func test_verify_no_interactions() -> void:
	var instance :Node = auto_free(Node.new())
	var spy_node :Variant = spy(instance)

	# verify we have no interactions checked this mock
	verify_no_interactions(spy_node)


func test_verify_no_interactions_fails() -> void:
	var instance :Node = auto_free(Node.new())
	var spy_node :Variant = spy(instance)

	# interact
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(false) # 1 times
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true) # 1 times
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true) # 2 times

	var expected_error :="""
		Expecting no more interactions!
		But found interactions on:
			'set_process(false :bool)'	1 time's
			'set_process(true :bool)'	2 time's""" \
			.dedent().trim_prefix("\n")
	# it should fail because we have interactions
	assert_failure(func() -> void: verify_no_interactions(spy_node)) \
		.is_failed() \
		.has_line(358) \
		.has_message(expected_error)


func test_verify_no_more_interactions() -> void:
	var instance :Node = auto_free(Node.new())
	var spy_node :Variant = spy(instance)

	@warning_ignore("unsafe_method_access")
	spy_node.is_ancestor_of(instance)
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(false)
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true)
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true)

	# verify for called functions
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 1).is_ancestor_of(instance)
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 2).set_process(true)
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 1).set_process(false)

	# There should be no more interactions checked this mock
	verify_no_more_interactions(spy_node)


func test_verify_no_more_interactions_but_has() -> void:
	var instance :Node = auto_free(Node.new())
	var spy_node :Variant = spy(instance)

	@warning_ignore("unsafe_method_access")
	spy_node.is_ancestor_of(instance)
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(false)
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true)
	@warning_ignore("unsafe_method_access")
	spy_node.set_process(true)

	# now we simulate extra calls that we are not explicit verify
	@warning_ignore("unsafe_method_access")
	spy_node.is_inside_tree()
	@warning_ignore("unsafe_method_access")
	spy_node.is_inside_tree()
	# a function with default agrs
	@warning_ignore("unsafe_method_access")
	spy_node.find_child("mask")
	# same function again with custom agrs
	@warning_ignore("unsafe_method_access")
	spy_node.find_child("mask", false, false)

	# verify 'all' exclusive the 'extra calls' functions
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 1).is_ancestor_of(instance)
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 2).set_process(true)
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 1).set_process(false)

	# now use 'verify_no_more_interactions' to check we have no more interactions checked this mock
	# but should fail with a collecion of all not validated interactions
	var expected_error :="""
		Expecting no more interactions!
		But found interactions on:
			'is_inside_tree()'	2 time's
			'find_child(mask :String, true :bool, true :bool)'	1 time's
			'find_child(mask :String, false :bool, false :bool)'	1 time's""" \
			.dedent().trim_prefix("\n")
	assert_failure(func() -> void: verify_no_more_interactions(spy_node)) \
		.is_failed() \
		.has_line(431) \
		.has_message(expected_error)


class ClassWithStaticFunctions:

	static func _static_init() -> void:
		return

	static func foo() -> void:
		pass

	static func bar() -> void:
		pass


func test_create_spy_static_func_untyped() -> void:
	var instance :Variant = spy(ClassWithStaticFunctions.new())
	assert_object(instance).is_not_null()


func test_spy_snake_case_named_class_by_resource_path() -> void:
	var instance_a :Object = _load("res://addons/gdUnit4/test/mocker/resources/snake_case.gd").new()
	var spy_a :Variant = spy(instance_a)
	assert_object(spy_a).is_not_null()

	@warning_ignore("unsafe_method_access")
	spy_a.custom_func()
	@warning_ignore("unsafe_method_access")
	verify(spy_a).custom_func()
	verify_no_more_interactions(spy_a)

	var instance_b :Object = _load("res://addons/gdUnit4/test/mocker/resources/snake_case_class_name.gd").new()
	var spy_b :Variant = spy(instance_b)
	assert_object(spy_b).is_not_null()

	@warning_ignore("unsafe_method_access")
	spy_b.custom_func()
	@warning_ignore("unsafe_method_access")
	verify(spy_b).custom_func()
	verify_no_more_interactions(spy_b)


func test_spy_snake_case_named_class_by_class() -> void:
	var do_spy :Variant = spy(snake_case_class_name.new())
	assert_object(do_spy).is_not_null()

	@warning_ignore("unsafe_method_access")
	do_spy.custom_func()
	@warning_ignore("unsafe_method_access")
	verify(do_spy).custom_func()
	verify_no_more_interactions(do_spy)

	# try checked Godot class
	var spy_tcp_server :Variant = spy(TCPServer.new())
	assert_object(spy_tcp_server).is_not_null()

	@warning_ignore("unsafe_method_access")
	spy_tcp_server.is_listening()
	@warning_ignore("unsafe_method_access")
	spy_tcp_server.is_connection_available()
	@warning_ignore("unsafe_method_access")
	verify(spy_tcp_server).is_listening()
	@warning_ignore("unsafe_method_access")
	verify(spy_tcp_server).is_connection_available()
	verify_no_more_interactions(spy_tcp_server)


const Issue = preload("res://addons/gdUnit4/test/resources/issues/gd-166/issue.gd")
const Type = preload("res://addons/gdUnit4/test/resources/issues/gd-166/types.gd")


func test_spy_preload_class_GD_166() -> void:
	var instance :Object = auto_free(Issue.new())
	var spy_instance :Variant = spy(instance)

	spy_instance.type = Type.FOO
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1)._set_type_name(Type.FOO)
	assert_int(spy_instance.type).is_equal(Type.FOO)
	assert_str(spy_instance.type_name).is_equal("FOO")


# https://github.com/MikeSchulze/gdUnit4/issues/38
func test_spy_Node_use_real_func_vararg() -> void:
	# setup
	var instance :Variant = auto_free(Node.new())

	@warning_ignore("unsafe_method_access")
	var spy_node :Variant = spy(instance)
	assert_that(spy_node).is_not_null()

	# test emit it
	@warning_ignore("unsafe_method_access")
	spy_node.emit_signal("ready", "aa", "bb", "cc")

	# verify is emitted
	@warning_ignore("unsafe_method_access")
	verify(spy_node).emit_signal("ready", "aa", "bb", "cc")

	# test emit it
	@warning_ignore("unsafe_method_access")
	spy_node.emit_signal("ready", "aa", "xxx")
	# verify is emitted
	@warning_ignore("unsafe_method_access")
	verify(spy_node).emit_signal("ready", "aa", "xxx")


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

	@warning_ignore("unused_parameter")
	func do_call(name: String, ...varargs: Array) -> void:
		pass


func test_spy_verify_variadic_args() -> void:
	var spy_instance :Variant = spy(ClassWithSignal.new())

	@warning_ignore("unsafe_method_access")
	spy_instance.do_call("foo", 1, 2, 3)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).do_call("foo", 1, 2, 3)


# https://github.com/MikeSchulze/gdUnit4/issues/14
func _test_spy_verify_emit_signal() -> void:
	var spy_instance :Variant = spy(ClassWithSignal.new())
	assert_that(spy_instance).is_not_null()

	@warning_ignore("unsafe_method_access")
	spy_instance.foo(0)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).emit_signal(spy_instance.test_signal_a.get_name(), "aa")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 0).emit_signal(spy_instance.test_signal_b.get_name(), "bb", true)
	reset(spy_instance)

	@warning_ignore("unsafe_method_access")
	spy_instance.foo(1)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 0).emit_signal(spy_instance.test_signal_a.get_name(), "aa")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).emit_signal(spy_instance.test_signal_b.get_name(), "bb", true)
	reset(spy_instance)

	@warning_ignore("unsafe_method_access")
	spy_instance.bar(0)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).emit_signal(spy_instance.test_signal_a.get_name(), "aa")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 0).emit_signal(spy_instance.test_signal_b.get_name(), "bb", true)
	reset(spy_instance)

	@warning_ignore("unsafe_method_access")
	spy_instance.bar(1)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 0).emit_signal(spy_instance.test_signal_a.get_name(), "aa")
	@warning_ignore("unsafe_method_access")
	verify(spy_instance, 1).emit_signal(spy_instance.test_signal_b.get_name(), "bb", true)


func test_spy_func_with_default_build_in_type() -> void:
	var spy_instance :ClassWithDefaultBuildIntTypes = spy(ClassWithDefaultBuildIntTypes.new())
	assert_object(spy_instance).is_not_null()
	# call with default arg
	spy_instance.foo("abc")
	spy_instance.bar("def")

	@warning_ignore("unsafe_method_access")
	verify(spy_instance).foo("abc", Color.RED)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance).bar("def", Vector3.FORWARD, AABB())
	verify_no_more_interactions(spy_instance)

	# call with custom args
	spy_instance.foo("abc", Color.BLUE)
	spy_instance.bar("def", Vector3.DOWN, AABB(Vector3.ONE, Vector3.ZERO))
	@warning_ignore("unsafe_method_access")
	verify(spy_instance).foo("abc", Color.BLUE)
	@warning_ignore("unsafe_method_access")
	verify(spy_instance).bar("def", Vector3.DOWN, AABB(Vector3.ONE, Vector3.ZERO))
	verify_no_more_interactions(spy_instance)


func test_spy_scene_by_resource_path() -> void:
	var spy_scene :Variant = spy("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	assert_object(spy_scene)\
		.is_not_null()\
		.is_not_instanceof(PackedScene)\
		.is_instanceof(Control)
	@warning_ignore("unsafe_method_access")
	assert_str(spy_scene.get_script().resource_name).is_equal("SpyTestScene.gd")
	# check is spyed scene registered for auto freeing
	assert_bool(GdUnitMemoryObserver.is_marked_auto_free(spy_scene)).is_true()


func test_spy_on_PackedScene() -> void:
	var resource := load("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	var original_script :Script = resource.get_script()
	assert_object(resource).is_instanceof(PackedScene)

	var spy_scene :Variant = spy(resource)

	assert_object(spy_scene)\
		.is_not_null()\
		.is_not_instanceof(PackedScene)\
		.is_not_same(resource)
	@warning_ignore("unsafe_method_access")
	assert_object(spy_scene.get_script())\
		.is_not_null()\
		.is_instanceof(GDScript)\
		.is_not_same(original_script)
	@warning_ignore("unsafe_method_access")
	assert_str(spy_scene.get_script().resource_name).is_equal("SpyTestScene.gd")
	# check is spyed scene registered for auto freeing
	assert_bool(GdUnitMemoryObserver.is_marked_auto_free(spy_scene)).is_true()


func test_spy_scene_by_instance() -> void:
	var resource: PackedScene = load("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	var instance :Control = resource.instantiate()
	var original_script :Script = instance.get_script()
	var spy_scene :Variant = spy(instance)

	assert_object(spy_scene)\
		.is_not_null()\
		.is_same(instance)\
		.is_instanceof(Control)
	@warning_ignore("unsafe_method_access")
	assert_object(spy_scene.get_script())\
		.is_not_null()\
		.is_instanceof(GDScript)\
		.is_not_same(original_script)
	@warning_ignore("unsafe_method_access")
	assert_str(spy_scene.get_script().resource_name).is_equal("SpyTestScene.gd")
	# check is mocked scene registered for auto freeing
	assert_bool(GdUnitMemoryObserver.is_marked_auto_free(spy_scene)).is_true()


func test_spy_scene_by_path_fail_has_no_script_attached() -> void:
	var resource: PackedScene = load("res://addons/gdUnit4/test/mocker/resources/scenes/TestSceneWithoutScript.tscn")
	var instance :Control = auto_free(resource.instantiate())

	# has to fail and return null
	var spy_scene :Variant = spy(instance)
	assert_object(spy_scene).is_null()


func test_spy_scene_initalize() -> void:
	var spy_scene :Variant = spy("res://addons/gdUnit4/test/mocker/resources/scenes/TestScene.tscn")
	assert_object(spy_scene).is_not_null()

	# Add as child to a scene tree to trigger _ready to initalize all variables
	@warning_ignore("unsafe_cast")
	add_child(spy_scene as Node)
	# ensure _ready is recoreded and onyl once called
	@warning_ignore("unsafe_method_access")
	verify(spy_scene, 1)._ready()
	@warning_ignore("unsafe_method_access")
	verify(spy_scene, 1).only_one_time_call()
	assert_object(spy_scene._box1).is_not_null()
	assert_object(spy_scene._box2).is_not_null()
	assert_object(spy_scene._box3).is_not_null()

	# check signals are connected
	@warning_ignore("unsafe_cast", "unsafe_method_access")
	assert_bool(spy_scene.is_connected("panel_color_change", Callable(spy_scene as Node, "_on_panel_color_changed")))

	# check exports
	@warning_ignore("unsafe_method_access")
	assert_str(spy_scene._initial_color.to_html()).is_equal(Color.RED.to_html())


class CustomNode extends Node:

	func _ready() -> void:
		# we call this function to verify the _ready is only once called
		# this is need to verify `add_child` is calling the original implementation only once
		only_one_time_call()

	func only_one_time_call() -> void:
		pass


func test_spy_ready_called_once() -> void:
	var spy_node :Variant = spy(auto_free(CustomNode.new()))

	# Add as child to a scene tree to trigger _ready to initalize all variables
	@warning_ignore("unsafe_cast")
	add_child(spy_node as Node)

	# ensure _ready is recoreded and onyl once called
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 1)._ready()
	@warning_ignore("unsafe_method_access")
	verify(spy_node, 1).only_one_time_call()


func test_spy_on_object_is_registered_for_auto_free() -> void:
	var instance: Node = Node.new()
	var spy_node: Variant = spy(instance)

	# check the returned spy is a new instance and is registered for auto freeing
	assert_bool(GdUnitMemoryObserver.is_marked_auto_free(spy_node)).is_true()
	# check the original instance is NOT registered for auto freeing, it remains under the ownership of the caller
	assert_bool(GdUnitMemoryObserver.is_marked_auto_free(instance)).is_false()

	# finally register the original instance for freeing after the test to avoid an orphan node
	@warning_ignore("return_value_discarded")
	auto_free(instance)


func test_spy_on_scene_instance_is_registered_for_auto_free() -> void:
	var resource: PackedScene = load("res://addons/gdUnit4/test/spy/resources/TestSceneWithProperties.tscn")
	var instance: Node2D = resource.instantiate()
	var spy_scene: Variant = spy(instance)

	# check in contrast to spy on an object, the spy on a scene instance is not a new instance,
	# the script is exchanged on the original scene instance
	assert_object(spy_scene).is_same(instance)
	# check the original scene instance is registered for auto freeing, no manual `auto_free` is needed
	assert_bool(GdUnitMemoryObserver.is_marked_auto_free(instance)).is_true()


func test_spy_with_enum_in_constructor() -> void:
	# this test uses a class with an enum in the constructor
	var unit := ClassWithEnumConstructor.new(ClassWithEnumConstructor.MyEnumValue.TWO, [])
	var s  :Variant = spy(unit)
	@warning_ignore("unsafe_method_access")
	s.set_value(ClassWithEnumConstructor.MyEnumValue.ONE)
	# test
	@warning_ignore("unsafe_method_access")
	verify(s, 1).set_value(ClassWithEnumConstructor.MyEnumValue.ONE)


#region documented examples
# The following tests verify the examples of the spy documentation page
# documentation/doc/_advanced_testing/spy.md
const TestClass := preload("res://addons/gdUnit4/test/spy/resources/DocExampleTestClass.gd")  # gdlint: ignore=class-definitions-order


func test_doc_verify_example() -> void:
	var spyed_instance: TestClass = spy(auto_free(TestClass.new()))

	# Verify we have no interactions currently on this instance
	verify_no_interactions(spyed_instance)

	# Call with different arguments
	spyed_instance.set_value(0) # 1 time
	spyed_instance.set_value(100) # 1 time
	spyed_instance.set_value(100) # 2 times

	# Verify how often we called the function with different arguments
	@warning_ignore("unsafe_method_access")
	verify(spyed_instance, 1).set_value(0) # in sum one time with 0
	@warning_ignore("unsafe_method_access")
	verify(spyed_instance, 2).set_value(100) # in sum two times with 100

	# Verify will fail because we expect the function `set_value(100)` to be called 3 times but it was only called 2 times
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: verify(spyed_instance, 3).set_value(100)).is_failed()


func test_doc_verify_no_interactions_example() -> void:
	var spyed_instance: TestClass = spy(auto_free(TestClass.new()))

	# Test that we have no initial interactions on this spy
	verify_no_interactions(spyed_instance)

	# Interact by calling `message()`
	spyed_instance.message()

	# Now this verification will fail because we have interacted on this spy by calling `message`
	assert_failure(func() -> void: verify_no_interactions(spyed_instance)).is_failed()


func test_doc_verify_no_more_interactions_example() -> void:
	var spyed_instance: TestClass = spy(auto_free(TestClass.new()))

	# Interact on two functions
	spyed_instance.message()
	spyed_instance.set_value(42)

	# Verify that the spy interacts as expected
	@warning_ignore("unsafe_method_access")
	verify(spyed_instance).message()
	@warning_ignore("unsafe_method_access")
	verify(spyed_instance).set_value(42)

	# Check that there are no further interactions with the spy
	verify_no_more_interactions(spyed_instance)

	# Simulate an unexpected interaction by calling `set_value` with a not yet verified argument
	spyed_instance.set_value(100)

	# Verify that there are no further interactions with the spy
	# and that the previous unexpected interaction is detected (the test will fail here)
	assert_failure(func() -> void: verify_no_more_interactions(spyed_instance)).is_failed()


func test_doc_reset_example() -> void:
	var spyed_instance: TestClass = spy(auto_free(TestClass.new()))

	# First, we test by interacting with two functions
	spyed_instance.message()
	spyed_instance.set_value(42)

	# Verify if the interactions were recorded; at this point, two interactions are recorded
	@warning_ignore("unsafe_method_access")
	verify(spyed_instance).message()
	@warning_ignore("unsafe_method_access")
	verify(spyed_instance).set_value(42)

	# Now, we want to test a different scenario and we need to reset the current recorded interactions
	reset(spyed_instance)
	# Verify that the previously recorded interactions have been removed
	verify_no_more_interactions(spyed_instance)

	# Continue testing
	spyed_instance.set_value(100)
	@warning_ignore("unsafe_method_access")
	verify(spyed_instance).set_value(100)
	verify_no_more_interactions(spyed_instance)


func test_doc_argument_matchers_example() -> void:
	var spyed_instance: TestClass = spy(auto_free(TestClass.new()))

	# Call the function with different arguments
	spyed_instance.set_value(0) # Called 1 time
	spyed_instance.set_value(100) # Called 1 time
	spyed_instance.set_value(100) # Called 2 times

	# Verify that the function was called with any integer value 3 times
	@warning_ignore("unsafe_method_access")
	verify(spyed_instance, 3).set_value(any_int())
#endregion


func test_spy_class_with_field_initializer_calling_overridden_method() -> void:
	# GD-1234: field initializer calls a method before `__init()` runs.
	var instance: FieldInitCallTestClass = auto_free(FieldInitCallTestClass.new())
	var spy_instance: FieldInitCallTestClass = spy(instance)

	assert_that(spy_instance).is_not_null()
	assert_str(spy_instance.greeting).is_equal("hello from the real function")


func _load(resource_path: String) -> GDScript:
	return load(resource_path)
