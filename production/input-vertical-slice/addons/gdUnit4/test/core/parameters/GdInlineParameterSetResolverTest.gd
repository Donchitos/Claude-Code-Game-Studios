# GdUnit generated TestSuite
extends GdUnitTestSuite


const DATA1 := ["aa"]
const DATA2 := ["bb"]


var example_parameters := [
	'[auto_free(Node.new()), Node]',
	'[auto_free(Node3D.new()), Node3D]',
	'["abc", "String"]',
	'[_x, "Integer"]',
	'[_obj, Node2D]',
	'[TestObj.new(), TestObj]',
	'[Vector3(1,1,1), Vector2(2,2)]',
	'[Color(1,1,1), _color]',
	'_test_set_a]'
	]

func parameters_as_array(index: int, arg1: String, arg2: String) -> Array[Variant]:
	return [index, arg1, arg2]

class TestObj:

	func _init() -> void:
		pass


class TestObjNamed extends RefCounted:
	var _value: String

	func _init(value: String) -> void:
		_value = value

	func _to_string() -> String:
		return _value


@warning_ignore_start("unused_private_class_variable")
var _x := 42
var _obj: Node2D
var _color := Color.RED
var _test_set_a := [Color(1,1,1), Color(.1,.1,.1)]
var _test_param1 := 10
var _test_param2 := 20
@warning_ignore_restore("unused_private_class_variable")

func before() -> void:
	_obj = auto_free(Node2D.new())
	_test_param1 = 11


#region test data
func before_test() -> void:
	_test_param2 = 22


func build_param(value: float) -> Vector3:
	return Vector3(value, value, value)


func using_parameters_static_int_values(_a: int, _b: int, _test_parameters := [
	[1, 2], [3, 4]
	]) -> void:
	pass


func using_parameters_function_values(_a: Vector3, _b: Vector3, _test_parameters := [
	[build_param(1), build_param(3)],
	[Vector3.BACK, Vector3.UP]
	]) -> void:
	pass


func using_parameters_static_vector2_values(_a: Vector2, _b: Vector2, _test_parameters := [
	[Vector2.ZERO, Vector2.ONE], [Vector2(1.1, 3.2), Vector2.DOWN]
	]) -> void:
	pass


func using_parameters_static_object_values(_a: Object, _b: Object, _test_parameters := [
	[Resource.new(), Resource.new()],
	[Resource.new(), null]
	]) -> void:
	pass


func using_parameters_static_custom_object_values(_a: Object, _b: Object, _expected: String, _test_parameters := [
	[TestObjNamed.new("abc"), TestObjNamed.new("def"), "abcdef"]
	]) -> void:
	pass


func using_parameters_static_values(_a: int, _b: int, _test_parameters := [
	[1, 10],
	[2, 20]
	]) -> void:
	pass


func using_parameters_with_properties(_a: int, _b: int, _test_parameters := [
	[1, _test_param1],
	[2, _test_param2],
	[3, 30]
	]) -> void:
	pass


func using_parameters_with_const_values(_value: String, _test_parameters := [DATA1, DATA2]) -> void:
	pass


func using_parameters_with_script_constants(_func_name: String, _expected_type: int, _test_parameters := [
	["bool", TYPE_BOOL],
	["double", TYPE_FLOAT],
	["array", TYPE_ARRAY],
	["packed_array", TYPE_PACKED_BYTE_ARRAY]
	]) -> void:
	pass


func using_parameters_with_comments(_a: int, _b: int, _c: String, _expected: int, _test_parameters := [
	# before data set
	[1, 2, '3', 6], # after data set
	# between data sets
	[3, 4, '5', 11],
	[6, 7, 'string #ABCD', 21], # dataset with [comment] sign
	[6, 7, "string #ABCD", 21] # dataset with "comment" sign
	#eof
]) -> void:
	pass


func using_typed_array_parameter(_items: Array[int], _test_parameters := [
	[[42, 99]],
	[[1, 2, 3]],
	]) -> void:
	pass


func using_array_types_paramater(_value: Variant, _test_parameters := [
	[[1, 2]],
	[Array([1, 2], TYPE_INT, "", null)],
	[PackedByteArray([1, 2])],
	[PackedInt32Array([1, 2])],
	[PackedInt64Array([1, 2])],
	[PackedFloat32Array([1.0, 2])],
	[PackedFloat64Array([1.0, 2])],
	[PackedStringArray(["1", "2"])],
	[PackedVector2Array([Vector2.ZERO, Vector2.ONE])],
	[PackedVector3Array([Vector3.ZERO, Vector3.ONE])],
	[PackedColorArray([Color.RED, Color.GREEN])]
	]) -> void:
	pass


func using_untyped_dictionary_parameter(
		_value : Dictionary,
		_expected : Dictionary,
		_test_parameters : Array = [
			[{ "top" : 10.0},	{ "down" : 20.0}],
		]
	) -> void:
	pass


func using_typed_key_dictionary_parameter(_items: Dictionary[String, Variant], _test_parameters := [
	[{"foo" : 10}],
	[{"bar" : 20}],
	]) -> void:
	pass


func using_typed_dictionary_parameter(_items: Dictionary[String, int], _test_parameters := [
	[{"foo" : 10}],
	[{"bar" : 20}],
	]) -> void:
	pass
#endregion

#region get_parameters

func test_get_parameters() -> void:
	var resolver := GdInlineParameterSetResolver.new(example_parameters, "", "")

	assert_int(resolver.get_max_index()).is_equal(9)

	# We test here a parameter resolver for a test function signature like
	# `func test_foo(arg1, arg2, _test_parameters := [[a,b],[a,b]) -> void:`
	# The result of `get_parameters` must match the function signature
	# - first arg is extracted from the orignal _test_parameters array
	# - second arg is extracted from the orignal _test_parameters array
	# - third argument is a empty placeholder to replace the defaults of `_test_parameters` argument
	#   to avoid reinitalization of the complete parameter set

	var parameters := resolver.get_parameters(self, 0)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_instanceof(Node).is_valid()
	assert_object(parameters[1]).is_equal(Node)
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 1)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_instanceof(Node3D).is_valid()
	assert_object(parameters[1]).is_equal(Node3D)
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 2)
	assert_array(parameters).has_size(3)
	assert_str(parameters[0]).is_equal("abc")
	assert_str(parameters[1]).is_equal("String")
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 3)
	assert_array(parameters).has_size(3)
	assert_int(parameters[0]).is_equal(_x)
	assert_str(parameters[1]).is_equal("Integer")
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 4)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_equal(_obj).is_valid()
	assert_object(parameters[1]).is_equal(Node2D)
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 5)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_instanceof(TestObj).is_valid()
	assert_object(parameters[1]).is_equal(TestObj)
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 6)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_equal(Vector3(1,1,1))
	assert_object(parameters[1]).is_equal(Vector2(2,2))
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 7)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_equal(Color(1,1,1))
	assert_object(parameters[1]).is_equal(_color)
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 8)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_equal(_test_set_a[0])
	assert_object(parameters[1]).is_equal(_test_set_a[1])
	assert_object(parameters[2]).is_equal(_test_set_a[2])


func test_get_parameters_with_constants() -> void:
	var test_parameters := [
		'[Vector2.ONE, "Vector2"]',
		'[Vector3.ZERO, "Vector3"]',
		'[Color.RED, "Color"]',
	]

	var resolver := GdInlineParameterSetResolver.new(test_parameters, "", "")

	assert_int(resolver.get_max_index()).is_equal(3)

	var parameters := resolver.get_parameters(self, 0)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_equal(Vector2.ONE)
	assert_str(parameters[1]).is_equal("Vector2")
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 1)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_equal(Vector3.ZERO)
	assert_str(parameters[1]).is_equal("Vector3")
	assert_object(parameters[2]).is_equal([])

	parameters = resolver.get_parameters(self, 2)
	assert_array(parameters).has_size(3)
	assert_object(parameters[0]).is_equal(Color.RED)
	assert_str(parameters[1]).is_equal("Color")
	assert_object(parameters[2]).is_equal([])


func test_get_parameters_with_constants_uses_fast_path() -> void:
	var test_parameters := [
		'[Vector2.ZERO, Vector2.ONE, Vector2.DOWN, Vector2.INF]',
		'[Vector3.ZERO, Vector3.ONE, Vector3.DOWN, Vector3.INF]',
		'[Vector4.ZERO, Vector4.ONE, Vector4.INF]',
		'[Color.RED, Color.WEB_GRAY]',
	]
	var resolver := GdInlineParameterSetResolver.new(test_parameters, "", "")

	for index in resolver.get_max_index():
		assert_object(resolver._preparsed_expressions[index]).is_not_null()

	assert_array(resolver.get_parameters(self, 0)).contains_exactly(Vector2.ZERO, Vector2.ONE, Vector2.DOWN, Vector2.INF, [])
	assert_array(resolver.get_parameters(self, 1)).contains_exactly(Vector3.ZERO, Vector3.ONE, Vector3.DOWN, Vector3.INF, [])
	assert_array(resolver.get_parameters(self, 2)).contains_exactly(Vector4.ZERO, Vector4.ONE, Vector4.INF, [])
	assert_array(resolver.get_parameters(self, 3)).contains_exactly(Color.RED, Color.WEB_GRAY, [])


func test_get_parameters_binds_user_classes_on_fast_path() -> void:
	var test_parameters := [
		'[GdUnitBoolAssert, "bool"]',
		'[GdUnitStringAssert, "string"]',
	]
	var resolver := GdInlineParameterSetResolver.new(test_parameters, "", "")

	for index in resolver.get_max_index():
		assert_object(resolver._preparsed_expressions[index]).is_not_null()

	assert_array(resolver.get_parameters(self, 0)).contains_exactly(GdUnitBoolAssert, "bool", [])
	assert_array(resolver.get_parameters(self, 1)).contains_exactly(GdUnitStringAssert, "string", [])


func test_fallback_warning_includes_source_context() -> void:
	var test_parameters := ["[Array([1, 2, 3, 1]) as Array[int], TYPE_ARRAY]"]

	assert_error(func() -> void:
		GdInlineParameterSetResolver.new(test_parameters, "res://foo/bar.gd", "test_broken_expression")
	).is_push_warning("""
		Avoid type-casting with `as Array` in parameter sets; use the typed `Array(...)` constructor instead.
			test: 'test_broken_expression' (res://foo/bar.gd)
			expression: '%s'
		Falling back to slower script-based resolver.
		""".dedent() % [test_parameters[0]])

#endregion
#region _resolve_parameters

func test_resolve_parameters_with_different_types() -> void:
	assert_array(_resolve_parameters("using_parameters_static_int_values")) \
		.is_equal([[1, 2, []], [3, 4, []]])

	assert_array(_resolve_parameters("using_parameters_static_vector2_values")) \
		.is_equal([[Vector2.ZERO, Vector2.ONE, []], [Vector2(1.1, 3.2), Vector2.DOWN, []]])

	assert_array(_resolve_parameters("using_parameters_static_object_values")) \
		.is_equal([[Resource.new(), Resource.new(), []], [Resource.new(), null, []]])

	assert_array(_resolve_parameters("using_parameters_function_values")) \
		.is_equal([[Vector3(1, 1, 1), Vector3(3, 3, 3), []], [Vector3.BACK, Vector3.UP, []]])

	assert_array(_resolve_parameters("using_parameters_static_custom_object_values")) \
		.is_equal([[TestObjNamed.new("abc"), TestObjNamed.new("def"), "abcdef", []]])


func test_resolve_parameters_with_static_values() -> void:
	var params := _resolve_parameters("using_parameters_static_values")
	assert_that(params).is_not_null()
	assert_array(params) \
		.is_equal([
			[1, 10, []],
			[2, 20, []]
		])


func test_resolve_parameters_with_properties() -> void:
	var params := _resolve_parameters("using_parameters_with_properties")
	assert_that(params).is_not_null()
	assert_array(params) \
		.is_equal([
			# the value `_test_param1` is changed from 10 to 11 on `before` stage
			[1, 11, []],
			# the value `_test_param2` is changed from 20 to 22 on `test_before` stage
			[2, 22, []],
			# the value is static initial `30`
			[3, 30, []]])


func test_resolve_parameters_with_comments() -> void:
	var params := _resolve_parameters("using_parameters_with_comments")
	assert_that(params).is_not_null()
	assert_array(params) \
		.is_equal([
			[1, 2, '3', 6, []],
			[3, 4, '5', 11, []],
			[6, 7, 'string #ABCD', 21, []],
			[6, 7, "string #ABCD", 21, []]])


func test_resolve_parameters_with_array_types() -> void:
	var params := _resolve_parameters("using_array_types_paramater")

	prints(params)



func test_resolve_parameters_with_typed_array() -> void:
	var params := _resolve_parameters("using_typed_array_parameter")

	assert_array(params).contains_exactly(
		[[42, 99], []],
		[[1, 2, 3], []]
	)

	var first: Array = params[0][0]
	assert_bool(first.is_typed()).is_true()
	assert_int(first.get_typed_builtin()).is_equal(TYPE_INT)

	var second: Array = params[1][0]
	assert_bool(second.is_typed()).is_true()
	assert_int(second.get_typed_builtin()).is_equal(TYPE_INT)


func test_resolve_parameters_with_untyped_dictionary() -> void:
	var params := _resolve_parameters("using_untyped_dictionary_parameter")

	assert_array(params).is_equal(
		[
			[{"top" : 10.0}, {"down" : 20.0}, []]
		]
	)

	var value: Dictionary = params[0][0]
	assert_bool(value.is_typed()).is_false()
	assert_dict(value).contains_key_value("top", 10.0)

	var expected: Dictionary = params[0][1]
	assert_bool(expected.is_typed()).is_false()
	assert_dict(expected).contains_key_value("down", 20.0)


# TODO needs to be enabled when typed dictionary support is implemented
func test_resolve_parameters_with_typed_key_dictionary(_do_skip := true, _skip_reason  := "typed dictionary not support") -> void:
	var params := _resolve_parameters("using_typed_key_dictionary_parameter")

	assert_dict(params).is_equal(
		[
			[{"foo" : 10}, []],
			[{"bar" : 20}, []],
		]
	)

	var first: Dictionary = params[0][0]
	assert_bool(first.is_typed()).is_true()
	assert_int(first.get_typed_key_builtin()).is_equal(TYPE_STRING)
	assert_int(first.get_typed_value_builtin()).is_equal(TYPE_NIL)

	var second: Dictionary = params[1][0]
	assert_bool(second.is_typed()).is_true()
	assert_int(second.get_typed_key_builtin()).is_equal(TYPE_STRING)
	assert_int(second.get_typed_value_builtin()).is_equal(TYPE_NIL)


# TODO needs to be enabled when typed dictionary support is implemented
func test_resolve_parameters_with_typed_dictionary(_do_skip := true, _skip_reason  := "typed dictionary not support") -> void:
	var params := _resolve_parameters("using_typed_dictionary_parameter")

	assert_dict(params).is_equal(
		[
			[{"foo" : 10}, []],
			[{"bar" : 20}, []],
		]
	)

	var first: Dictionary = params[0][0]
	assert_bool(first.is_typed()).is_true()
	assert_int(first.get_typed_key_builtin()).is_equal(TYPE_STRING)
	assert_int(first.get_typed_value_builtin()).is_equal(TYPE_INT)

	var second: Dictionary = params[1][0]
	assert_bool(second.is_typed()).is_true()
	assert_int(second.get_typed_key_builtin()).is_equal(TYPE_STRING)
	assert_int(second.get_typed_value_builtin()).is_equal(TYPE_INT)


func test_resolve_parameters_with_const_values() -> void:
	var params := _resolve_parameters("using_parameters_with_const_values")
	assert_that(params).is_not_null()
	assert_array(params) \
		.is_equal([
			["aa", []],
			["bb", []]
			])


func test_resolve_parameters_with_scrip_constans() -> void:
	var params := _resolve_parameters("using_parameters_with_script_constants")
	assert_that(params).is_not_null()
	assert_array(params) \
		.is_equal([
			["bool", TYPE_BOOL, []],
			["double", TYPE_FLOAT, []],
			["array", TYPE_ARRAY, []],
			["packed_array", TYPE_PACKED_BYTE_ARRAY, []]
			])


func test_resolve_parameters_with_array_functions(index: int, arg1: String, arg2: String, _test_parameters := [
	[0, "abc", "d,ef"],
	[1, "xxx", "foo(y)"],
	[2, 'y"yy', "d\"ef"],
	[3, "z'zz", 'd\'ef'],
	]) -> void:
	if index == 0:
		assert_str(arg1).is_equal("abc")
		assert_str(arg2).is_equal("d,ef")
	elif index == 1:
		assert_str(arg1).is_equal("xxx")
		assert_str(arg2).is_equal("foo(y)")
	elif index == 2:
		assert_str(arg1).is_equal('y"yy')
		assert_str(arg2).is_equal("d\"ef")
	elif index == 3:
		assert_str(arg1).is_equal("z'zz")
		assert_str(arg2).is_equal('d\'ef')


func _resolve_parameters(child_name: String) -> Array[Array]:
	var script: GDScript = self.get_script()
	var function_descriptors := GdScriptParser.new().get_function_descriptors(script, [child_name])
	var fd: GdFunctionDescriptor = function_descriptors.front()

	var parameter_set_argument := GdFunctionArgument.get_parameter_set(fd.args())
	var parameter_sets := parameter_set_argument.parameter_sets()
	var resolver := GdInlineParameterSetResolver.new(parameter_sets, fd.source_path(), fd.name(), fd.args())
	if resolver == null:
		return []
	var result: Array[Array] = []
	for i in resolver.get_max_index():
		result.append(resolver.get_parameters(self, i))
	return result
#endregion


#region performance

func test_performance_single() -> void:
	const ITERATIONS := 1000
	var resolver := GdInlineParameterSetResolver.new(example_parameters, "", "")

	var t1 := Time.get_ticks_usec()
	for _i in ITERATIONS:
		resolver.get_parameters(self, 0)
	var elapsed_time := Time.get_ticks_usec() - t1

	@warning_ignore_start("integer_division")
	prints("--- GdInlineParameterSetResolver:single performance (%d iterations) ---" % ITERATIONS)
	prints("	%8d µs  (%d µs/iteration)" % [elapsed_time, elapsed_time / ITERATIONS])
	assert_int(elapsed_time/ITERATIONS).is_less(20)
	@warning_ignore_restore("integer_division")


func test_performance_get_parameters_overall() -> void:
	const ITERATIONS := 1000
	var resolver := GdInlineParameterSetResolver.new(example_parameters, "", "")

	var t1 := Time.get_ticks_usec()
	for _i in ITERATIONS:
		for index in resolver.get_max_index():
			resolver.get_parameters(self, index)
	var elapsed_time := Time.get_ticks_usec() - t1

	@warning_ignore_start("integer_division")
	prints("--- GdInlineParameterSetResolver:overall performance (%d iterations) ---" % ITERATIONS)
	prints("	%8d µs  (%d µs/iteration)" % [elapsed_time, elapsed_time / ITERATIONS])
	assert_int(elapsed_time/ITERATIONS).is_less(60)
	@warning_ignore_restore("integer_division")

#endregion


#region _get_native_class_mapping

func test_get_native_class_mapping() -> void:
	var expected_count := 0
	for clazz_name in ClassDB.get_class_list():
		if ClassDB.class_get_api_type(clazz_name) != 0 or not ClassDB.can_instantiate(clazz_name):
			continue
		expected_count += 1

	assert_dict(GdInlineParameterSetResolver._get_native_class_mapping()).has_size(expected_count)
	assert_dict(GdInlineParameterSetResolver._get_native_class_mapping()).has_size(expected_count)

#endregion
