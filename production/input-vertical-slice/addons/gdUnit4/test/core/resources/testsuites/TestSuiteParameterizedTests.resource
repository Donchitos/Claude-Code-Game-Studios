extends GdUnitTestSuite

@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')


class TestCaseStatistics:
	var _testcase_before_called := 0
	var _testcase_after_called := 0
	var _expected_testcase_before :int
	var _expected_testcase_after :int

	func _init(testcase_before_calls := 0, testcase_after_calls := 0) -> void:
		_expected_testcase_before = testcase_before_calls
		_expected_testcase_after = testcase_after_calls

	func count_test_before_test() -> void:
		_testcase_before_called +=1

	func count_test_after_test() -> void:
		_testcase_after_called +=1


var _metrics := {
	"test_parameterized_bool_value" : TestCaseStatistics.new(2, 2),
	"test_parameterized_int_values" : TestCaseStatistics.new(3, 3)
}

var _before_called := 0
var _after_called := 0


func before() -> void:
	_before_called += 1


func after() -> void:
	_after_called += 1
	assert_that(_before_called)\
		.override_failure_message("Expecting 'before' is called only one times")\
		.is_equal(1)
	assert_that(_after_called)\
		.override_failure_message("Expecting 'after' is called only one times")\
		.is_equal(1)

	for test_case :String in _metrics.keys():
		var statistics: TestCaseStatistics = _metrics[test_case]
		assert_int(statistics._testcase_before_called)\
			.override_failure_message("Expect before_test called %s times but is %s for test case %s" % [statistics._expected_testcase_before, statistics._testcase_before_called, test_case])\
			.is_equal(statistics._expected_testcase_before)
		assert_int(statistics._testcase_after_called)\
			.override_failure_message("Expect after_test called %s times but is %s for test case %s" % [statistics._expected_testcase_after, statistics._testcase_after_called, test_case])\
			.is_equal(statistics._expected_testcase_after)


func before_test() -> void:
	if _metrics.has(__active_test_case):
		_metrics[__active_test_case].count_test_before_test()


func after_test() -> void:
	if _metrics.has(__active_test_case):
		_metrics[__active_test_case].count_test_after_test()


@warning_ignore('unused_parameter')
func test_parameterized_bool_value(a: int, expected :bool, test_parameters := [
	[0, false],
	[1, true]]) -> void:

	assert_that(bool(a)).is_equal(expected)

@warning_ignore('unused_parameter')
func test_parameterized_int_values(a: int, b :int, c :int, expected :int, test_parameters := [
	[1, 2, 3, 6],
	[3, 4, 5, 12],
	[6, 7, 8, 21] ]) -> void:

	assert_that(a+b+c).is_equal(expected)

@warning_ignore('unused_parameter')
func test_parameterized_int_values_fail(a: int, b :int, c :int, expected :int, test_parameters := [
	[1, 2, 3, 6],
	[3, 4, 5, 11],
	[6, 7, 8, 22] ]) -> void:

	assert_that(a+b+c).is_equal(expected)

@warning_ignore('unused_parameter')
func test_parameterized_float_values(a: float, b :float, expected :float, test_parameters := [
	[2.2, 2.2, 4.4],
	[2.2, 2.3, 4.5],
	[3.3, 2.2, 5.5] ]) -> void:

	assert_float(a+b).is_equal(expected)

@warning_ignore('unused_parameter')
func test_parameterized_string_values(a: String, b :String, expected :String, test_parameters := [
	["2.2", "2.2", "2.22.2"],
	["foo", "bar", "foobar"],
	["a", "b", "ab"] ]) -> void:

	assert_that(a+b).is_equal(expected)

@warning_ignore('unused_parameter')
func test_parameterized_Vector2_values(a: Vector2, b :Vector2, expected :Vector2, test_parameters := [
	[Vector2.ONE, Vector2.ONE, Vector2(2, 2)],
	[Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO],
	[Vector2.ZERO, Vector2.LEFT, Vector2.LEFT] ]) -> void:

	assert_that(a+b).is_equal(expected)

@warning_ignore('unused_parameter')
func test_parameterized_Vector3_values(a: Vector3, b :Vector3, expected :Vector3, test_parameters := [
	[Vector3.ONE, Vector3.ONE, Vector3(2, 2, 2)],
	[Vector3.LEFT, Vector3.RIGHT, Vector3.ZERO],
	[Vector3.ZERO, Vector3.LEFT, Vector3.LEFT] ]) -> void:

	assert_that(a+b).is_equal(expected)

class TestObj extends Resource:
	var _value :String

	func _init(value :String) -> void:
		_value = value

	func _to_string() -> String:
		return _value

@warning_ignore('unused_parameter')
func test_parameterized_obj_values(a: Object, b :Object, expected :String, test_parameters := [
	[TestObj.new("abc"), TestObj.new("def"), "abcdef"]]) -> void:

	assert_that(a.to_string()+b.to_string()).is_equal(expected)


@warning_ignore('unused_parameter')
func test_dictionary_div_number_types(
		value : Dictionary,
		expected : Dictionary,
		test_parameters : Array = [
			[{ "top" : 50.0,	"bottom" : 50.0,	"left" : 50.0,	"right" : 50.0},	{ "top" : 50, 	"bottom" : 50,	"left" : 50,  	"right" : 50}],
			[{ "top" : 50.0,	"bottom" : 50.0,	"left" : 50.0,	"right" : 50.0},	{ "top" : 50.0,	"bottom" : 50.0,	"left" : 50.0,	"right" : 50.0}],
			[{ "top" : 50,	"bottom" : 50,	"left" : 50,  	"right" : 50},	{ "top" : 50.0,	"bottom" : 50.0,	"left" : 50.0,	"right" : 50.0}],
			[{ "top" : 50,	"bottom" : 50,	"left" : 50,  	"right" : 50},	{ "top" : 50, 	"bottom" : 50,	"left" : 50,  	"right" : 50}],
		]
	) -> void:
		assert_that(value).is_equal(expected)
