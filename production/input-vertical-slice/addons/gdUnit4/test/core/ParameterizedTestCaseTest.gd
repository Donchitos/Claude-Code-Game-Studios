#warning-ignore-all:unused_argument
class_name ParameterizedTestCaseTest
extends GdUnitTestSuite

var _collected_tests: Dictionary[String, Array] = {}
var _expected_tests := {
	"test_parameterized_bool_value" : [
		[0, false],
		[1, true]
	],
	"test_parameterized_int_values" : [
		[1, 2, 3, 6],
		[3, 4, 5, 12],
		[6, 7, 8, 21]
	],
	"test_parameterized_float_values" : [
		[2.2, 2.2, 4.4],
		[2.2, 2.3, 4.5],
		[3.3, 2.2, 5.5]
	],
	"test_parameterized_string_values" : [
		["2.2", "2.2", "2.22.2"],
		["foo", "bar", "foobar"],
		["a", "b", "ab"]
	],
	"test_parameterized_Vector2_values" : [
		[Vector2.ONE, Vector2.ONE, Vector2(2, 2)],
		[Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO],
		[Vector2.ZERO, Vector2.LEFT, Vector2.LEFT]
	],
	"test_parameterized_Vector3_values" : [
		[Vector3.ONE, Vector3.ONE, Vector3(2, 2, 2)],
		[Vector3.LEFT, Vector3.RIGHT, Vector3.ZERO],
		[Vector3.ZERO, Vector3.LEFT, Vector3.LEFT]
	],
	"test_parameterized_obj_values" : [
		[TestObj.new("abc"), TestObj.new("def"), "abcdef"]
	],
	"test_parameterized_dict_values" : [
		[{"key_a":"value_a"}, '{"key_a":"value_a"}'],
		[{"key_b":"value_b"}, '{"key_b":"value_b"}']
	],
	"test_parameterized_untyped_array" : [
		[[42]]
	],
	"test_parameterized_typed_array" : [
		[[42]]
	],
	"test_with_dynamic_paramater_resolving" : [
		["test_a"],
		["test_b"],
		["test_c"],
		["test_d"]
	],
	"test_with_dynamic_paramater_resolving2" : [
		["test_a"],
		["test_b"],
		["test_c"]
	],
	"test_with_extern_parameter_set" : [
		["test_a"],
		["test_b"],
		["test_c"]
	],
	"test_with_extern_const_parameter_set" : [
		["aa"],
		["bb"]
	]
}


var _test_node_before: Node
var _test_node_before_test: Node


func before() -> void:
	_test_node_before = auto_free(SubViewport.new())


func before_test() -> void:
	_test_node_before_test = auto_free(SubViewport.new())


func after() -> void:
	for test_name: String in _expected_tests.keys():
		if _collected_tests.has(test_name):
			var current_values: Variant = _collected_tests[test_name]
			var expected_values: Variant = _expected_tests[test_name]
			assert_that(current_values)\
				.override_failure_message("Expecting '%s' called with parameters:\n %s\n but was\n %s" % [test_name, expected_values, current_values])\
				.is_equal(expected_values)
		else:
			fail("Missing test '%s' executed!" % test_name)


func collect_test_call(test_name: String, values: Array) -> void:
	if not _collected_tests.has(test_name):
		_collected_tests[test_name] = Array()
	_collected_tests[test_name].append(values)


func test_parameterized_bool_value(a: int, expected: bool, _test_parameters := [
	[0, false],
	[1, true]]) -> void:
	collect_test_call("test_parameterized_bool_value", [a, expected])
	assert_that(bool(a)).is_equal(expected)
	# The test call should replace the defaults with an empty array
	assert_array(_test_parameters).is_empty()


func test_parameterized_int_values(a: int, b: int, c: int, expected: int, _test_parameters := [
	[1, 2, 3, 6],
	[3, 4, 5, 12],
	[6, 7, 8, 21] ]) -> void:

	collect_test_call("test_parameterized_int_values", [a, b, c, expected])
	assert_that(a+b+c).is_equal(expected)
	# The test call should replace the defaults with an empty array
	assert_array(_test_parameters).is_empty()


func test_parameterized_float_values(a: float, b: float, expected: float, _test_parameters := [
	[2.2, 2.2, 4.4],
	[2.2, 2.3, 4.5],
	[3.3, 2.2, 5.5] ]) -> void:

	collect_test_call("test_parameterized_float_values", [a, b, expected])
	assert_float(a+b).is_equal(expected)
	# The test call should replace the defaults with an empty array
	assert_array(_test_parameters).is_empty()


func test_parameterized_string_values(a: String, b: String, expected: String, _test_parameters := [
	["2.2", "2.2", "2.22.2"],
	["foo", "bar", "foobar"],
	["a", "b", "ab"] ]) -> void:

	collect_test_call("test_parameterized_string_values", [a, b, expected])
	assert_that(a+b).is_equal(expected)
	# The test call should replace the defaults with an empty array
	assert_array(_test_parameters).is_empty()


func test_parameterized_Vector2_values(a: Vector2, b: Vector2, expected: Vector2, _test_parameters := [
	[Vector2.ONE, Vector2.ONE, Vector2(2, 2)],
	[Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO],
	[Vector2.ZERO, Vector2.LEFT, Vector2.LEFT] ]) -> void:

	collect_test_call("test_parameterized_Vector2_values", [a, b, expected])
	assert_that(a+b).is_equal(expected)
	# The test call should replace the defaults with an empty array
	assert_array(_test_parameters).is_empty()


func test_parameterized_Vector3_values(a: Vector3, b: Vector3, expected: Vector3, _test_parameters := [
	[Vector3.ONE, Vector3.ONE, Vector3(2, 2, 2)],
	[Vector3.LEFT, Vector3.RIGHT, Vector3.ZERO],
	[Vector3.ZERO, Vector3.LEFT, Vector3.LEFT] ]) -> void:

	collect_test_call("test_parameterized_Vector3_values", [a, b, expected])
	assert_that(a+b).is_equal(expected)


class TestObj extends RefCounted:
	var _value: String

	func _init(value: String) -> void:
		_value = value

	func _to_string() -> String:
		return _value


func test_parameterized_obj_values(a: Object, b: Object, expected: String, _test_parameters := [
	[TestObj.new("abc"), TestObj.new("def"), "abcdef"]]) -> void:

	collect_test_call("test_parameterized_obj_values", [a, b, expected])
	assert_that(a.to_string()+b.to_string()).is_equal(expected)


func test_parameterized_dict_values(data: Dictionary, expected: String, _test_parameters := [
	[{"key_a" : "value_a"}, '{"key_a":"value_a"}'],
	[{"key_b" : "value_b"}, '{"key_b":"value_b"}']
	]) -> void:
	collect_test_call("test_parameterized_dict_values", [data, expected])
	assert_that(str(data).replace(" ", "")).is_equal(expected)


func test_dictionary_div_number_types(
	value: Dictionary,
	expected: Dictionary,
	_test_parameters: Array = [
		[{ "top" : 50.0,	"bottom" : 50.0,	"left" : 50.0,	"right" : 50.0},	{ "top" : 50, 	"bottom" : 50,	"left" : 50,  	"right" : 50}],
		[{ "top" : 50.0,	"bottom" : 50.0,	"left" : 50.0,	"right" : 50.0},	{ "top" : 50.0,	"bottom" : 50.0,	"left" : 50.0,	"right" : 50.0}],
		[{ "top" : 50,	"bottom" : 50,	"left" : 50,  	"right" : 50},	{ "top" : 50.0,	"bottom" : 50.0,	"left" : 50.0,	"right" : 50.0}],
		[{ "top" : 50,	"bottom" : 50,	"left" : 50,  	"right" : 50},	{ "top" : 50, 	"bottom" : 50,	"left" : 50,  	"right" : 50}],
	]
) -> void:
	# allow to compare type unsave
	ProjectSettings.set_setting(GdUnitSettings.REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE, false)
	assert_that(value).is_equal(expected)
	ProjectSettings.set_setting(GdUnitSettings.REPORT_ASSERT_STRICT_NUMBER_TYPE_COMPARE, true)


func test_parameterized_untyped_array(items: Array, _test_parameters := [
		[[42]]
	]
) -> void:
	collect_test_call("test_parameterized_untyped_array", [items])
	assert_array(items).contains_exactly([42])


func test_parameterized_typed_array(items: Array[int], _test_parameters := [
		[[42]]
	]
) -> void:
	collect_test_call("test_parameterized_typed_array", [items])
	assert_array(items).contains_exactly([42])


func test_with_string_paramset(
	values: Array,
	expected: String,
	_test_parameters : Array = [
		[ ["a"], "a" ],
		[ ["a", "very", "long", "argument"], "a very long argument" ],
	]
) -> void:
	var current := " ".join(values)
	assert_that(current.strip_edges()).is_equal(expected)


# https://github.com/MikeSchulze/gdUnit4/issues/213
func test_with_string_contains_brackets(
	test_index: int,
	value: String,
	_test_parameters := [
		[1, "flowchart TD\nid>This is a flag shaped node]"],
		[2, "flowchart TD\nid(((This is a double circle node)))"],
		[3, "flowchart TD\nid((This is a circular node))"],
		[4, "flowchart TD\nid>This is a flag shaped node]"],
		[5, "flowchart TD\nid{'This is a rhombus node'}"],
		[6, 'flowchart TD\nid((This is a circular node))'],
		[7, 'flowchart TD\nid>This is a flag shaped node]'],
		[8, 'flowchart TD\nid{"This is a rhombus node"}'],
		[9, """
			flowchart TD
			id{"This is a rhombus node"}
			""".dedent()],
	]
) -> void:
	match test_index:
		1: assert_str(value).is_equal("flowchart TD\nid>This is a flag shaped node]")
		2: assert_str(value).is_equal("flowchart TD\nid(((This is a double circle node)))")
		3: assert_str(value).is_equal("flowchart TD\nid((This is a circular node))")
		4: assert_str(value).is_equal("flowchart TD\nid>" + "This is a flag shaped node]")
		5: assert_str(value).is_equal("flowchart TD\nid{'This is a rhombus node'}")
		6: assert_str(value).is_equal('flowchart TD\nid((This is a circular node))')
		7: assert_str(value).is_equal('flowchart TD\nid>This is a flag shaped node]')
		8: assert_str(value).is_equal('flowchart TD\nid{"This is a rhombus node"}')
		9: assert_str(value).is_equal("""
			flowchart TD
			id{"This is a rhombus node"}
			""".dedent())


func test_with_dynamic_parameter_resolving(name_: String, value: Variant, expected: Variant, _test_parameters := [
	["test_a", auto_free(Node2D.new()), Node2D],
	["test_b", auto_free(Node3D.new()), Node3D],
	["test_c", _test_node_before, SubViewport],
	["test_d", _test_node_before_test, SubViewport],
]) -> void:
	# all values must be resolved
	assert_object(value).is_not_null().is_instanceof(expected)
	if name_ == "test_c":
		assert_object(value).is_same(_test_node_before)
	if name_ == "test_d":
		assert_object(value).is_same(_test_node_before_test)
	# the argument '_test_parameters' must be replaced by <null> set to avoid re-instantiate of test arguments
	assert_array(_test_parameters).is_empty()
	collect_test_call("test_with_dynamic_paramater_resolving", [name_])


@warning_ignore("unused_parameter")
func test_with_dynamic_parameter_resolving2(
	name_: String,
	type: Variant,
	log_level: Variant,
	expected_logs: Dictionary,
	_test_parameters := [
		["test_a", null, "LOG", {}],
		[
			"test_b",
			Node2D,
			null,
			{Node2D: "ERROR"}
		],
		[
			"test_c",
			Node2D,
			"LOG",
			{Node2D: "LOG"}
		]
	]
) -> void:
	# the argument '_test_parameters' must be replaced by <null> set to avoid re-instantiate of test arguments
	assert_array(_test_parameters).is_empty()
	collect_test_call("test_with_dynamic_paramater_resolving2", [name_])


var _test_set := [
	["test_a"],
	["test_b"],
	["test_c"]
]


func test_with_extern_parameter_set(value: String, _test_parameters := _test_set) -> void:
	assert_str(value).is_not_empty()
	assert_array(_test_parameters).is_empty()
	collect_test_call("test_with_extern_parameter_set", [value])


const _data1 := ["aa"]
const _data2 := ["bb"]


func test_with_extern_const_parameter_set(value: String, _test_parameters := [_data1, _data2]) -> void:
	assert_str(value).is_not_empty()
	assert_array(_test_parameters).is_empty()
	collect_test_call("test_with_extern_const_parameter_set", [value])
