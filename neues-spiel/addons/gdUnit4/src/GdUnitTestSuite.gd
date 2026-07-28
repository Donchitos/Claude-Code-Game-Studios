## The main class for all GdUnit test suites[br]
## This class is the main class to implement your unit tests[br]
## You have to extend and implement your test cases as described[br]
## e.g MyTests.gd [br]
## [codeblock]
##    extends GdUnitTestSuite
##    # testcase
##    func test_case_a():
##       assert_that("value").is_equal("value")
## [/codeblock]
## @tutorial:  https://mikeschulze.github.io/gdUnit4/faq/test-suite/

@icon("res://addons/gdUnit4/src/ui/settings/logo.png")
class_name GdUnitTestSuite
extends Node


### internal runtime variables that must not be overwritten!!!
@warning_ignore("unused_private_class_variable")
var __is_skipped := false
@warning_ignore("unused_private_class_variable")
var __skip_reason := "Unknow."
var __active_test_case: String
var __awaiter := __gdunit_awaiter()


### We now load all used asserts and tool scripts into the cache according to the principle of "lazy loading"
### in order to noticeably reduce the loading time of the test suite.
# We go this hard way to increase the loading performance to avoid reparsing all the used scripts
# for more detailed info -> https://github.com/godotengine/godot/issues/67400
func __lazy_load(script_path: String) -> GDScript:
	return GdUnitAssertions.__lazy_load(script_path)


func __gdunit_assert() -> GDScript:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitAssertImpl.gd")


func __gdunit_tools() -> GDScript:
	return __lazy_load("res://addons/gdUnit4/src/core/GdUnitTools.gd")


func __gdunit_file_access() -> GDScript:
	return __lazy_load("res://addons/gdUnit4/src/core/GdUnitFileAccess.gd")


func __gdunit_awaiter() -> Object:
	return __lazy_load("res://addons/gdUnit4/src/GdUnitAwaiter.gd").new()


func __gdunit_argument_matchers() -> GDScript:
	return __lazy_load("res://addons/gdUnit4/src/matchers/GdUnitArgumentMatchers.gd")


func __gdunit_object_interactions() -> GDScript:
	return __lazy_load("res://addons/gdUnit4/src/doubler/GdUnitObjectInteractions.gd")


## This function is called before a test suite starts[br]
## You can overwrite to prepare test data or initalizize necessary variables
func before() -> void:
	pass


## This function is called at least when a test suite is finished[br]
## You can overwrite to cleanup data created during test running
func after() -> void:
	pass


## This function is called before a test case starts[br]
## You can overwrite to prepare test case specific data
func before_test() -> void:
	pass


## This function is called after the test case is finished[br]
## You can overwrite to cleanup your test case specific data
func after_test() -> void:
	pass


func is_failure() -> bool:
	return Engine.get_meta("GD_TEST_FAILURE") if Engine.has_meta("GD_TEST_FAILURE") else false


func set_active_test_case(test_case: String) -> void:
	__active_test_case = test_case


# === Tools ====================================================================
# Mapps Godot error number to a readable error message. See at ERROR
# https://docs.godotengine.org/de/stable/classes/class_@globalscope.html#enum-globalscope-error
func error_as_string(error_number: int) -> String:
	return error_string(error_number)


## A litle helper to auto freeing your created objects after test execution
func auto_free(obj: Variant) -> Variant:
	var execution_context := GdUnitThreadManager.get_current_context().get_execution_context()

	assert(execution_context != null, "INTERNAL ERROR: The current execution_context is null! Please report this as bug.")
	return execution_context.register_auto_free(obj)


@warning_ignore("native_method_override")
func add_child(node: Node, force_readable_name := false, internal := Node.INTERNAL_MODE_DISABLED) -> void:
	super.add_child(node, force_readable_name, internal)
	var execution_context := GdUnitThreadManager.get_current_context().get_execution_context()
	if execution_context != null:
		execution_context.orphan_monitor_start()


## Discard the error message triggered by a timeout (interruption).[br]
## By default, an interrupted test is reported as an error.[br]
## This function allows you to change the message to Success when an interrupted error is reported.
func discard_error_interupted_by_timeout() -> void:
	@warning_ignore("unsafe_method_access")
	__gdunit_tools().register_expect_interupted_by_timeout(self, __active_test_case)


## Creates a new directory under the temporary directory *user://tmp*[br]
## Useful for storing data during test execution. [br]
## The directory is automatically deleted after test suite execution
func create_temp_dir(relative_path: String) -> String:
	@warning_ignore("unsafe_method_access")
	return __gdunit_file_access().create_temp_dir(relative_path)


## Deletes the temporary base directory[br]
## Is called automatically after each execution of the test suite
func clean_temp_dir() -> void:
	@warning_ignore("unsafe_method_access")
	__gdunit_file_access().clear_tmp()


## Creates a new file under the temporary directory *user://tmp* + <relative_path>[br]
## with given name <file_name> and given file <mode> (default = File.WRITE)[br]
## If success the returned File is automatically closed after the execution of the test suite
func create_temp_file(relative_path: String, file_name: String, mode := FileAccess.WRITE) -> FileAccess:
	@warning_ignore("unsafe_method_access")
	return __gdunit_file_access().create_temp_file(relative_path, file_name, mode)


## Reads a resource by given path <resource_path> into a PackedStringArray.
func resource_as_array(resource_path: String) -> PackedStringArray:
	@warning_ignore("unsafe_method_access")
	return __gdunit_file_access().resource_as_array(resource_path)


## Reads a resource by given path <resource_path> and returned the content as String.
func resource_as_string(resource_path: String) -> String:
	@warning_ignore("unsafe_method_access")
	return __gdunit_file_access().resource_as_string(resource_path)


## Reads a resource by given path <resource_path> and return Variand translated by str_to_var
func resource_as_var(resource_path: String) -> Variant:
	@warning_ignore("unsafe_method_access", "unsafe_cast")
	return str_to_var(__gdunit_file_access().resource_as_string(resource_path) as String)


## Waits for given signal to be emitted by <source> until a specified timeout to fail[br]
## source: the object from which the signal is emitted[br]
## signal_name: signal name[br]
## args: the expected signal arguments as an array[br]
## timeout: the timeout in ms, default is set to 2000ms
func await_signal_on(source: Object, signal_name: String, args: Array = [], timeout: int = 2000) -> Variant:
	@warning_ignore("unsafe_method_access")
	return await __awaiter.await_signal_on(source, signal_name, args, timeout)


## Waits until the next idle frame
func await_idle_frame() -> void:
	@warning_ignore("unsafe_method_access")
	await __awaiter.await_idle_frame()


## Waits for a given amount of milliseconds[br]
## example:[br]
## [codeblock]
##    # waits for 100ms
##    await await_millis(myNode, 100).completed
## [/codeblock][br]
## use this waiter and not `await get_tree().create_timer().timeout to prevent errors when a test case is timed out
func await_millis(timeout: int) -> void:
	@warning_ignore("unsafe_method_access")
	await __awaiter.await_millis(timeout)


## Collects detailed information about orphaned nodes for debugging purposes.[br]
##
## This function gathers comprehensive details about nodes that remain in memory
## after test execution (orphans). It provides debugging information to help
## identify the source of memory leaks in tests. Must be manually called in
## tests when orphan nodes are detected.[br]
## [br]
## [b]When to Use:[/b][br]
## - When GdUnit4 reports orphan nodes after test execution[br]
## - For debugging memory leaks in test scenarios[br]
## - To get detailed information about unreleased nodes[br]
## [br]
## [b]Usage Pattern:[/b][br]
## Add this call at the end of tests that are suspected to create orphans,
## or when the test runner reports orphan detection.[br]
## [br]
## [b]Examples:[/b]
## [codeblock]
## func test_scene_management():
##     # Test code that might create orphan nodes
##     var scene = preload("res://TestScene.tscn").instantiate()
##     add_child(scene)
##
##     # Do test operations
##     scene.some_method()
##
##     # Clean up (but might miss some nodes)
##     scene.queue_free()
##
##     # Collect orphan details if any are detected
##     collect_orphan_node_details()
## [/codeblock]
## [br]
## [b]Note:[/b] This is a debugging utility function that should be removed
## or commented out once orphan issues are resolved.
func collect_orphan_node_details() -> void:
	GdUnitThreadManager.get_current_context().get_execution_context().orphan_monitor_collect()


## Creates a new scene runner to allow simulate interactions checked a scene.[br]
## The runner will manage the scene instance and release after the runner is released[br]
## example:[br]
## [codeblock]
##    # creates a runner by using a instanciated scene
##    var scene = load("res://foo/my_scne.tscn").instantiate()
##    var runner := scene_runner(scene)
##
##    # or simply creates a runner by using the scene resource path
##    var runner := scene_runner("res://foo/my_scne.tscn")
## [/codeblock]
func scene_runner(scene: Variant, verbose := false) -> GdUnitSceneRunner:
	return auto_free(__lazy_load("res://addons/gdUnit4/src/core/GdUnitSceneRunnerImpl.gd").new(scene, verbose))


# === Mocking  & Spy ===========================================================

## do return a default value for primitive types or null
const RETURN_DEFAULTS = GdUnitMock.RETURN_DEFAULTS
## do call the real implementation
const CALL_REAL_FUNC = GdUnitMock.CALL_REAL_FUNC
## do return a default value for primitive types and a fully mocked value for Object types
## builds full deep mocked object
const RETURN_DEEP_STUB = GdUnitMock.RETURN_DEEP_STUB


## Creates a mock for given class name
func mock(clazz: Variant, mock_mode := RETURN_DEFAULTS) -> Variant:
	@warning_ignore("unsafe_method_access")
	return __lazy_load("res://addons/gdUnit4/src/mocking/GdUnitMockBuilder.gd").build(clazz, mock_mode)


## Creates a spy checked given object instance
func spy(instance: Variant) -> Variant:
	@warning_ignore("unsafe_method_access")
	return __lazy_load("res://addons/gdUnit4/src/spy/GdUnitSpyBuilder.gd").build(instance)


## Configures a return value for the specified function and used arguments.[br]
## [b]Example:
## 	[codeblock]
## 		# overrides the return value of myMock.is_selected() to false
## 		do_return(false).on(myMock).is_selected()
## 	[/codeblock]
func do_return(value: Variant) -> GdUnitMock:
	return GdUnitMock.new(value)


## Verifies certain behavior happened at least once or exact number of times
func verify(obj: Variant, times := 1) -> Variant:
	@warning_ignore("unsafe_method_access")
	return __gdunit_object_interactions().verify(obj, times)


## Verifies no interactions is happen checked this mock or spy
func verify_no_interactions(obj: Variant) -> GdUnitAssert:
	@warning_ignore("unsafe_method_access")
	return __gdunit_object_interactions().verify_no_interactions(obj)


## Verifies the given mock or spy has any unverified interaction.
func verify_no_more_interactions(obj: Variant) -> GdUnitAssert:
	@warning_ignore("unsafe_method_access")
	return __gdunit_object_interactions().verify_no_more_interactions(obj)


## Resets the saved function call counters checked a mock or spy
func reset(obj: Variant) -> void:
	@warning_ignore("unsafe_method_access")
	__gdunit_object_interactions().reset(obj)


## Starts monitoring the specified source to collect all transmitted signals.[br]
## The collected signals can then be checked with 'assert_signal'.[br]
## By default, the specified source is automatically released when the test ends.
## You can control this behavior by setting auto_free to false if you do not want the source to be automatically freed.[br]
## Usage:
##	[codeblock]
##		var emitter := monitor_signals(MyEmitter.new())
##		# call the function to send the signal
##		emitter.do_it()
##		# verify the signial is emitted
##		await assert_signal(emitter).is_emitted('my_signal')
##	[/codeblock]
func monitor_signals(source: Object, _auto_free := true) -> Object:
	@warning_ignore("unsafe_method_access")
	__lazy_load("res://addons/gdUnit4/src/core/thread/GdUnitThreadManager.gd")\
		.get_current_context()\
		.get_signal_collector()\
		.register_emitter(source, true) # force recreate to start with a fresh monitoring
	return auto_free(source) if _auto_free else source


# === Argument matchers ========================================================
## Argument matcher to match any argument
func any() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().any()


## Argument matcher to match any boolean value
func any_bool() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_BOOL)


## Argument matcher to match any integer value
func any_int() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_INT)


## Argument matcher to match any float value
func any_float() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_FLOAT)


## Argument matcher to match any String value
func any_string() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_STRING)


## Argument matcher to match any Color value
func any_color() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_COLOR)


## Argument matcher to match any Vector typed value
func any_vector() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_types([
		TYPE_VECTOR2,
		TYPE_VECTOR2I,
		TYPE_VECTOR3,
		TYPE_VECTOR3I,
		TYPE_VECTOR4,
		TYPE_VECTOR4I,
	])


## Argument matcher to match any Vector2 value
func any_vector2() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_VECTOR2)


## Argument matcher to match any Vector2i value
func any_vector2i() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_VECTOR2I)


## Argument matcher to match any Vector3 value
func any_vector3() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_VECTOR3)


## Argument matcher to match any Vector3i value
func any_vector3i() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_VECTOR3I)


## Argument matcher to match any Vector4 value
func any_vector4() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_VECTOR4)


## Argument matcher to match any Vector4i value
func any_vector4i() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_VECTOR4I)


## Argument matcher to match any Rect2 value
func any_rect2() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_RECT2)


## Argument matcher to match any Plane value
func any_plane() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PLANE)


## Argument matcher to match any Quaternion value
func any_quat() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_QUATERNION)


## Argument matcher to match any AABB value
func any_aabb() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_AABB)


## Argument matcher to match any Basis value
func any_basis() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_BASIS)


## Argument matcher to match any Transform2D value
func any_transform_2d() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_TRANSFORM2D)


## Argument matcher to match any Transform3D value
func any_transform_3d() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_TRANSFORM3D)


## Argument matcher to match any NodePath value
func any_node_path() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_NODE_PATH)


## Argument matcher to match any RID value
func any_rid() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_RID)


## Argument matcher to match any Object value
func any_object() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_OBJECT)


## Argument matcher to match any Dictionary value
func any_dictionary() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_DICTIONARY)


## Argument matcher to match any Array value
func any_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_ARRAY)


## Argument matcher to match any PackedByteArray value
func any_packed_byte_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_BYTE_ARRAY)


## Argument matcher to match any PackedInt32Array value
func any_packed_int32_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_INT32_ARRAY)


## Argument matcher to match any PackedInt64Array value
func any_packed_int64_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_INT64_ARRAY)


## Argument matcher to match any PackedFloat32Array value
func any_packed_float32_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_FLOAT32_ARRAY)


## Argument matcher to match any PackedFloat64Array value
func any_packed_float64_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_FLOAT64_ARRAY)


## Argument matcher to match any PackedStringArray value
func any_packed_string_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_STRING_ARRAY)


## Argument matcher to match any PackedVector2Array value
func any_packed_vector2_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_VECTOR2_ARRAY)


## Argument matcher to match any PackedVector3Array value
func any_packed_vector3_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_VECTOR3_ARRAY)


## Argument matcher to match any PackedColorArray value
func any_packed_color_array() -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().by_type(TYPE_PACKED_COLOR_ARRAY)


## Argument matcher to match any instance of given class
func any_class(clazz :Object) -> GdUnitArgumentMatcher:
	@warning_ignore("unsafe_method_access")
	return __gdunit_argument_matchers().any_class(clazz)


# === value extract utils ======================================================
## Builds an extractor by given function name and optional arguments
func extr(func_name: String, args := Array()) -> GdUnitValueExtractor:
	return __lazy_load("res://addons/gdUnit4/src/extractors/GdUnitFuncValueExtractor.gd").new(func_name, args)


## Creates a GdUnitTuple from the provided arguments for use in test assertions.
## [br]
## This is the primary helper function for creating tuples in GdUnit4 tests.
## It provides a convenient way to group multiple expected values when using
## [method extractv] assertions. The function enforces that tuples must contain
## at least two values, as single-value extractions don't require tuple grouping.
## [br]
## [b]Parameters:[/b] [br]
## - [code]...args[/code]: Variable number of arguments (minimum 2) to group into a tuple.
##   Each argument represents a value to be compared in assertions.
## [br]
## [b]Returns:[/b] [br]
## A [GdUnitTuple] containing the provided values, or an empty tuple if fewer than
## 2 arguments are provided (with an error message).
## [br]
## [b]Error Handling:[/b] [br]
## [codeblock]
## # This will push an error and return empty tuple
## var invalid = tuple("single_value")  # Error: requires at least 2 arguments
## [br]
## # Correct usage - minimum 2 arguments
## var valid = tuple("name", "value")
## var valid_multi = tuple(1, 2, 3, 4, 5)  # Can have many values
## [/codeblock]
func tuple(...args: Array) -> GdUnitTuple:
	if args.size() < 2:
		push_error("Tuple requires at least two arguments.")
		return GdUnitTuple.new()
	return GdUnitTuple.new.callv(args)


# === Asserts ==================================================================

## The common assertion tool to verify values.
## It checks the given value by type to fit to the best assert
func assert_that(current: Variant) -> GdUnitAssert:
	match typeof(current):
		TYPE_BOOL:
			return assert_bool(current)
		TYPE_INT:
			return assert_int(current)
		TYPE_FLOAT:
			return assert_float(current)
		TYPE_STRING:
			return assert_str(current)
		TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_VECTOR4I:
			return assert_vector(current, false)
		TYPE_DICTIONARY:
			return assert_dict(current)
		TYPE_ARRAY, TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY,\
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY,\
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY:
			return assert_array(current, false)
		TYPE_OBJECT, TYPE_NIL:
			return assert_object(current)
		_:
			return __gdunit_assert().new(current)


## An assertion tool to verify boolean values.
func assert_bool(current: Variant) -> GdUnitBoolAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitBoolAssertImpl.gd").new(current)


## An assertion tool to verify String values.
func assert_str(current: Variant) -> GdUnitStringAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitStringAssertImpl.gd").new(current)


## An assertion tool to verify integer values.
func assert_int(current: Variant) -> GdUnitIntAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitIntAssertImpl.gd").new(current)


## An assertion tool to verify float values.
func assert_float(current: Variant) -> GdUnitFloatAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFloatAssertImpl.gd").new(current)


## An assertion tool to verify Vector values.[br]
## This assertion supports all vector types.[br]
## Usage:
##     [codeblock]
##		assert_vector(Vector2(1.2, 1.000001)).is_equal(Vector2(1.2, 1.000001))
##     [/codeblock]
func assert_vector(current: Variant, type_check := true) -> GdUnitVectorAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitVectorAssertImpl.gd").new(current, type_check)


## An assertion tool to verify arrays.
func assert_array(current: Variant, type_check := true) -> GdUnitArrayAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitArrayAssertImpl.gd").new(current, type_check)


## An assertion tool to verify dictionaries.
func assert_dict(current: Variant) -> GdUnitDictionaryAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitDictionaryAssertImpl.gd").new(current)


## An assertion tool to verify FileAccess.
func assert_file(current: Variant) -> GdUnitFileAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFileAssertImpl.gd").new(current)


## An assertion tool to verify Objects.
func assert_object(current: Variant) -> GdUnitObjectAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitObjectAssertImpl.gd").new(current)


func assert_result(current: Variant) -> GdUnitResultAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitResultAssertImpl.gd").new(current)


## An assertion tool that waits until a certain time for an expected function return value
func assert_func(instance: Object, func_name: String, args := Array()) -> GdUnitFuncAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFuncAssertImpl.gd").new(instance, func_name, args)


## An assertion tool to verify for emitted signals until a certain time.
func assert_signal(instance: Object) -> GdUnitSignalAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitSignalAssertImpl.gd").new(instance)


## An assertion tool to test for failing assertions.[br]
## This assert is only designed for internal use to verify failing asserts working as expected.[br]
## Usage:
##     [codeblock]
##		assert_failure(func(): assert_bool(true).is_not_equal(true)) \
##		    .has_message("Expecting:\n 'true'\n not equal to\n 'true'")
##     [/codeblock]
func assert_failure(assertion: Callable) -> GdUnitFailureAssert:
	@warning_ignore("unsafe_method_access")
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFailureAssertImpl.gd").new().execute(assertion)


## An assertion tool to test for failing assertions.[br]
## This assert is only designed for internal use to verify failing asserts working as expected.[br]
## Usage:
##     [codeblock]
##		await assert_failure_await(func(): assert_bool(true).is_not_equal(true)) \
##		    .has_message("Expecting:\n 'true'\n not equal to\n 'true'")
##     [/codeblock]
func assert_failure_await(assertion: Callable) -> GdUnitFailureAssert:
	@warning_ignore("unsafe_method_access")
	return await __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFailureAssertImpl.gd").new().execute_and_await(assertion)


## An assertion tool to verify Godot errors.[br]
## You can use to verify certain Godot errors like failing assertions, push_error, push_warn.[br]
## Usage:
##     [codeblock]
##		# tests no error occurred during execution of the code
##		await assert_error(func (): return 0 )\
##		    .is_success()
##
##		# tests a push_error('test error') occured during execution of the code
##		await assert_error(func (): push_error('test error') )\
##		    .is_push_error('test error')
##     [/codeblock]
func assert_error(current: Callable) -> GdUnitGodotErrorAssert:
	return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd").new(current)


## Explicitly fails the current test indicating that the feature is not yet implemented.[br]
## This function is useful during development when you want to write test cases before implementing the actual functionality.[br]
## It provides a clear indication that the test failure is expected because the feature is still under development.[br]
## Usage:
##     [codeblock]
##		# Test for a feature that will be implemented later
##		func test_advanced_ai_behavior():
##		    assert_not_yet_implemented()
##
##     [/codeblock]
func assert_not_yet_implemented() -> void:
	@warning_ignore("unsafe_method_access")
	__gdunit_assert().new(null).do_fail()


## Explicitly fails the current test with a custom error message.[br]
## This function reports an error but does not terminate test execution automatically.[br]
## You must use 'return' after calling fail() to stop the test since GDScript has no exception support.[br]
## Useful for complex conditional testing scenarios where standard assertions are insufficient.[br]
## Usage:
##     [codeblock]
##		# Fail test when conditions are not met
##		if !custom_check(player):
##		    fail("Player should be alive but has %d health" % player.health)
##		    return
##
##		# Continue with test if conditions pass
##		assert_that(player.health).is_greater(0)
##     [/codeblock]
func fail(message: String) -> void:
	@warning_ignore("unsafe_method_access")
	__gdunit_assert().new(null).report_error(message)


# --- internal stuff do not override!!!
func ResourcePath() -> String:
	return get_script().resource_path
