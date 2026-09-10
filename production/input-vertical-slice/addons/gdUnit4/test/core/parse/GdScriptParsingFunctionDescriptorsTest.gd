extends GdUnitTestSuite

var _parser: GdScriptParser


func before() -> void:
	_parser = GdScriptParser.new()


func after() -> void:
	clean_temp_dir()


func test_default_args_dictionary() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/container_build_in_types/ClassWithDictionaryDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_dictionary_case1", script.resource_path, 5, 6, TYPE_ARRAY, [
				GdFunctionArgument.new("dict", TYPE_DICTIONARY, {}),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_dictionary_case2", script.resource_path, 9, 10, TYPE_ARRAY, [
				GdFunctionArgument.new("dict", TYPE_DICTIONARY, {}),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_dictionary_case3", script.resource_path, 13, 14, TYPE_ARRAY, [
				GdFunctionArgument.new("dict", TYPE_DICTIONARY, {}),
			])
		)
	assert_that(fds[3])\
		.is_equal(create("on_dictionary_case4", script.resource_path, 17, 18, TYPE_ARRAY, [
				GdFunctionArgument.new("dict", TYPE_DICTIONARY, {"a":"value_a", "b":"value_b"}),
			])
		)
	assert_that(fds[4])\
		.is_equal(create("on_dictionary_case5", script.resource_path, 21, 24, TYPE_ARRAY, [
				GdFunctionArgument.new("dict", TYPE_DICTIONARY, {"a":"value_a", "b":"value_b"}),
			])
		)
	assert_that(fds[5])\
		.is_equal(create("on_dictionary_case6", script.resource_path, 27, 28, TYPE_ARRAY, [
				GdFunctionArgument.new("dict", TYPE_DICTIONARY, {"a":"value_a", "b":"value_b"}),
			])
		)


func test_default_args_array() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/container_build_in_types/ClassWithArrayDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_array_case1", script.resource_path, 5, 6, TYPE_ARRAY, [
				GdFunctionArgument.new("values", TYPE_ARRAY, []),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_array_case2", script.resource_path, 9, 10, TYPE_ARRAY, [
				GdFunctionArgument.new("values", TYPE_ARRAY, []),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_array_case3", script.resource_path, 13, 14, TYPE_ARRAY, [
				GdFunctionArgument.new("values", TYPE_ARRAY, []),
			])
		)
	assert_that(fds[3])\
		.is_equal(create("on_array_case4", script.resource_path, 17, 18, TYPE_ARRAY, [
				GdFunctionArgument.new("values", TYPE_ARRAY, [1, "3", [], {}]),
			])
		)
	assert_that(fds[4])\
		.is_equal(create("on_array_case5", script.resource_path, 21, 26, TYPE_ARRAY, [
				GdFunctionArgument.new("values", TYPE_ARRAY, [1, "3", [], {}]),
			])
		)
	assert_that(fds[5])\
		.is_equal(create("on_array_case6", script.resource_path, 29, 30, TYPE_ARRAY, [
				GdFunctionArgument.new("values", TYPE_ARRAY, [1, "3", [], {}]),
			])
		)


func test_default_args_callable() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/container_build_in_types/ClassWithCallableDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_callable_case1", script.resource_path, 5, 6, TYPE_CALLABLE, [
				GdFunctionArgument.new("cb", TYPE_CALLABLE),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_callable_case2", script.resource_path, 9, 10, TYPE_CALLABLE, [
				GdFunctionArgument.new("cb", TYPE_CALLABLE, Callable()),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_callable_case3", script.resource_path, 13, 14, TYPE_CALLABLE, [
				GdFunctionArgument.new("cb", TYPE_CALLABLE, Callable()),
			])
		)
	assert_that(fds[3])\
		.is_equal(create("on_callable_case4", script.resource_path, 17, 18, TYPE_CALLABLE, [
				GdFunctionArgument.new("cb", TYPE_CALLABLE, Callable(null, "method_foo")),
			])
		)


func test_default_args_variant() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/ClassWithVariantTypeDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("add_button", script.resource_path, 4, 8, GdObjects.TYPE_VOID, [
				GdFunctionArgument.new("ucids", TYPE_ARRAY, GdFunctionArgument.UNDEFINED, TYPE_INT),
				GdFunctionArgument.new("position", TYPE_VECTOR2I),
				GdFunctionArgument.new("size", TYPE_VECTOR2I),
				GdFunctionArgument.new("style", TYPE_INT),
				GdFunctionArgument.new("text", GdObjects.TYPE_VARIANT, ""),
				GdFunctionArgument.new("button_name", TYPE_STRING, ""),
				GdFunctionArgument.new("type_in", TYPE_INT, 0),
				GdFunctionArgument.new("caption", TYPE_STRING, ""),
				GdFunctionArgument.new("show_everywhere", TYPE_BOOL, false),
			])
		)


# Basic build-in-types
func test_default_args_basic_type_int() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeIntDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_int_case1", script.resource_path, 5, 6, TYPE_INT, [
				GdFunctionArgument.new("value", TYPE_INT),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_int_case2", script.resource_path, 9, 10, TYPE_INT, [
				GdFunctionArgument.new("value", TYPE_INT, 42),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_int_case3", script.resource_path, 13, 14, TYPE_INT, [
				GdFunctionArgument.new("value", TYPE_INT, 42),
			])
		)


func test_default_args_basic_type_float() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeFloatDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_float_case1", script.resource_path, 5, 6, TYPE_FLOAT, [
				GdFunctionArgument.new("value", TYPE_FLOAT),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_float_case2", script.resource_path, 9, 10, TYPE_FLOAT, [
				GdFunctionArgument.new("value", TYPE_FLOAT, 42.1),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_float_case3", script.resource_path, 13, 14, TYPE_FLOAT, [
				GdFunctionArgument.new("value", TYPE_FLOAT, 42.1),
			])
		)


func test_default_args_basic_type_bool() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeBoolDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_bool_case1", script.resource_path, 5, 6, TYPE_BOOL, [
				GdFunctionArgument.new("value", TYPE_BOOL),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_bool_case2", script.resource_path, 9, 10, TYPE_BOOL, [
				GdFunctionArgument.new("value", TYPE_BOOL, true),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_bool_case3", script.resource_path, 13, 14, TYPE_BOOL, [
				GdFunctionArgument.new("value", TYPE_BOOL, true),
			])
		)


func test_default_args_basic_type_string() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeStringDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_string_case1", script.resource_path, 5, 6, TYPE_STRING, [
				GdFunctionArgument.new("value", TYPE_STRING),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_string_case2", script.resource_path, 9, 10, TYPE_STRING, [
				GdFunctionArgument.new("value", TYPE_STRING, "foo"),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_string_case3", script.resource_path, 13, 14, TYPE_STRING, [
				GdFunctionArgument.new("value", TYPE_STRING, "foo"),
			])
		)


func test_default_args_basic_type_string_name() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeStringNameDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_string_name_case1", script.resource_path, 5, 6, TYPE_STRING_NAME, [
				GdFunctionArgument.new("value", TYPE_STRING_NAME),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_string_name_case2", script.resource_path, 9, 10, TYPE_STRING_NAME, [
				GdFunctionArgument.new("value", TYPE_STRING_NAME, &"foo"),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_string_name_case3", script.resource_path, 13, 14, TYPE_STRING_NAME, [
				GdFunctionArgument.new("value", TYPE_STRING_NAME, &"foo"),
			])
		)


func test_default_args_basic_type_node_path() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeNodePathDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_node_path_case1", script.resource_path, 5, 6, TYPE_NODE_PATH, [
				GdFunctionArgument.new("value", TYPE_NODE_PATH),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_node_path_case2", script.resource_path, 9, 10, TYPE_NODE_PATH, [
				GdFunctionArgument.new("value", TYPE_NODE_PATH, NodePath("foo1")),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_node_path_case3", script.resource_path, 13, 14, TYPE_NODE_PATH, [
				GdFunctionArgument.new("value", TYPE_NODE_PATH, NodePath("foo2")),
			])
		)
	assert_that(fds[3])\
		.is_equal(create("on_node_path_case4", script.resource_path, 17, 18, TYPE_NODE_PATH, [
				GdFunctionArgument.new("value", TYPE_NODE_PATH, NodePath("foo3")),
			])
		)


func test_default_args_basic_type_vector2() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeVector2DefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_vector2_case1", script.resource_path, 5, 6, TYPE_VECTOR2, [
				GdFunctionArgument.new("value", TYPE_VECTOR2),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_vector2_case2", script.resource_path, 9, 10, TYPE_VECTOR2, [
				GdFunctionArgument.new("value", TYPE_VECTOR2, Vector2.ONE),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_vector2_case3", script.resource_path, 13, 14, TYPE_VECTOR2, [
				GdFunctionArgument.new("value", TYPE_VECTOR2, Vector2.ONE),
			])
		)


func test_default_args_basic_type_vector2i() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeVector2iDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_vector2i_case1", script.resource_path, 5, 6, TYPE_VECTOR2I, [
				GdFunctionArgument.new("value", TYPE_VECTOR2I),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_vector2i_case2", script.resource_path, 9, 10, TYPE_VECTOR2I, [
				GdFunctionArgument.new("value", TYPE_VECTOR2I, Vector2i.ONE),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_vector2i_case3", script.resource_path, 13, 14, TYPE_VECTOR2I, [
				GdFunctionArgument.new("value", TYPE_VECTOR2I, Vector2i.ONE),
			])
		)


func test_default_args_basic_type_vector3() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeVector3DefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_vector3_case1", script.resource_path, 5, 6, TYPE_VECTOR3, [
				GdFunctionArgument.new("value", TYPE_VECTOR3),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_vector3_case2", script.resource_path, 9, 10, TYPE_VECTOR3, [
				GdFunctionArgument.new("value", TYPE_VECTOR3, Vector3.ONE),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_vector3_case3", script.resource_path, 13, 14, TYPE_VECTOR3, [
				GdFunctionArgument.new("value", TYPE_VECTOR3, Vector3.ONE),
			])
		)


func test_default_args_basic_type_vector3i() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeVector3iDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_vector3i_case1", script.resource_path, 5, 6, TYPE_VECTOR3I, [
				GdFunctionArgument.new("value", TYPE_VECTOR3I),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_vector3i_case2", script.resource_path, 9, 10, TYPE_VECTOR3I, [
				GdFunctionArgument.new("value", TYPE_VECTOR3I, Vector3i.ONE),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_vector3i_case3", script.resource_path, 13, 14, TYPE_VECTOR3I, [
				GdFunctionArgument.new("value", TYPE_VECTOR3I, Vector3i.ONE),
			])
		)


func test_default_args_basic_type_vector4() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeVector4DefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_vector4_case1", script.resource_path, 5, 6, TYPE_VECTOR4, [
				GdFunctionArgument.new("value", TYPE_VECTOR4),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_vector4_case2", script.resource_path, 9, 10, TYPE_VECTOR4, [
				GdFunctionArgument.new("value", TYPE_VECTOR4, Vector4.ONE),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_vector4_case3", script.resource_path, 13, 14, TYPE_VECTOR4, [
				GdFunctionArgument.new("value", TYPE_VECTOR4, Vector4.ONE),
			])
		)


func test_default_args_basic_type_vector4i() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeVector4iDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_vector4i_case1", script.resource_path, 5, 6, TYPE_VECTOR4I, [
				GdFunctionArgument.new("value", TYPE_VECTOR4I),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_vector4i_case2", script.resource_path, 9, 10, TYPE_VECTOR4I, [
				GdFunctionArgument.new("value", TYPE_VECTOR4I, Vector4i.ONE),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_vector4i_case3", script.resource_path, 13, 14, TYPE_VECTOR4I, [
				GdFunctionArgument.new("value", TYPE_VECTOR4I, Vector4i.ONE),
			])
		)


func test_default_args_basic_type_rect2() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeRect2DefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_rect2_case1", script.resource_path, 5, 6, TYPE_RECT2, [
				GdFunctionArgument.new("value", TYPE_RECT2),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_rect2_case2", script.resource_path, 9, 10, TYPE_RECT2, [
				GdFunctionArgument.new("value", TYPE_RECT2, Rect2()),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_rect2_case3", script.resource_path, 13, 14, TYPE_RECT2, [
				GdFunctionArgument.new("value", TYPE_RECT2, Rect2()),
			])
		)
	assert_that(fds[3])\
		.is_equal(create("on_rect2_case4", script.resource_path, 17, 18, TYPE_RECT2, [
				GdFunctionArgument.new("value", TYPE_RECT2, Rect2(Vector2.ONE, Vector2.ZERO)),
			])
		)
	assert_that(fds[4])\
		.is_equal(create("on_rect2_case5", script.resource_path, 21, 22, TYPE_RECT2, [
				GdFunctionArgument.new("value", TYPE_RECT2, Rect2(Vector2(0, 1), Vector2(2, 3))),
			])
		)


func test_default_args_basic_type_transform2d() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/basic_build_in_types/ClassWithBasicTypeTransform2DDefaultArguments.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("on_transform2d_case1", script.resource_path, 5, 6, TYPE_TRANSFORM2D, [
				GdFunctionArgument.new("value", TYPE_TRANSFORM2D),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("on_transform2d_case2", script.resource_path, 9, 10, TYPE_TRANSFORM2D, [
				GdFunctionArgument.new("value", TYPE_TRANSFORM2D, Transform2D()),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("on_transform2d_case3", script.resource_path, 13, 14, TYPE_TRANSFORM2D, [
				GdFunctionArgument.new("value", TYPE_TRANSFORM2D, Transform2D()),
			])
		)
	assert_that(fds[3])\
		.is_equal(create("on_transform2d_case4", script.resource_path, 17, 18, TYPE_TRANSFORM2D, [
				GdFunctionArgument.new("value", TYPE_TRANSFORM2D, Transform2D(1.2, Vector2.ONE)),
			])
		)


func test_parse_fuzz_do_skip_param_GD_1157() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/parse/resources/TestSuiteWithFuzzers.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create("test_do_skip_as_first_param", script.resource_path, 4, 8, GdObjects.TYPE_VOID, [
				GdFunctionArgument.new("_do_skip", TYPE_BOOL, false),
				GdFunctionArgument.new("_fuzzer", GdObjects.TYPE_FUZZER, "Fuzzers.rangei(0, 10)"),
				GdFunctionArgument.new("_fuzzer_iterations", TYPE_INT, 3),
			])
		)
	assert_that(fds[1])\
		.is_equal(create("test_do_skip_in_middle", script.resource_path, 11, 15, GdObjects.TYPE_VOID, [
				GdFunctionArgument.new("_fuzzer_a", GdObjects.TYPE_FUZZER, "Fuzzers.rangei(0, 10)"),
				GdFunctionArgument.new("_do_skip", TYPE_BOOL, false),
				GdFunctionArgument.new("_fuzzer_iterations", TYPE_INT, 3),
			])
		)
	assert_that(fds[2])\
		.is_equal(create("test_do_skip_as_last_param", script.resource_path, 18, 22, GdObjects.TYPE_VOID, [
				GdFunctionArgument.new("_fuzzer", GdObjects.TYPE_FUZZER, "Fuzzers.rangei(0, 10)"),
				GdFunctionArgument.new("_fuzzer_iterations", TYPE_INT, 3),
				GdFunctionArgument.new("_do_skip", TYPE_BOOL, false),
			])
		)


func test_static_functions() -> void:
	var script: GDScript = load("res://addons/gdUnit4/test/core/resources/parsing/functions/ClassWithStaticFunctions.gd")

	var fds := _parser.get_function_descriptors(script, [])
	assert_that(fds[0])\
		.is_equal(create_static("_static_init", script.resource_path, 4, 5, GdObjects.TYPE_VOID, [])
		)
	assert_that(fds[1])\
		.is_equal(create_static("_static_init2", script.resource_path, 8, 9, GdObjects.TYPE_VOID, [])
		)


static func create(func_name: String, source_path: String, begin_line: int, end_line: int, return_type: int, args: Array[GdFunctionArgument] = []) -> GdFunctionDescriptor:
	var fd := GdFunctionDescriptor.new(func_name, false, false, false, return_type, "", args)
	fd.enrich_file_info(source_path, begin_line, end_line)
	return fd


static func create_static(func_name: String, source_path: String, begin_line: int, end_line: int, return_type: int, args: Array[GdFunctionArgument] = []) -> GdFunctionDescriptor:
	var fd := GdFunctionDescriptor.new(func_name, false, true, false, return_type, "", args)
	fd.enrich_file_info(source_path, begin_line, end_line)
	return fd
