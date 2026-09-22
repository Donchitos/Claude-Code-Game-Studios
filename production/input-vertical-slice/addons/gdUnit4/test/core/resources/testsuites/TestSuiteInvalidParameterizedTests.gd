class_name TestSuiteInvalidParameterizedTests
extends GdUnitTestSuite

func test_no_parameters() -> void:
	assert_that(true).is_equal(true)

@warning_ignore('unused_parameter')
func test_parameterized_success(a: int, b :int, c :int, expected :int, test_parameters := [
	[1, 2, 3, 6],
	[3, 4, 5, 12],
	[6, 7, 8, 21] ]) -> void:

	assert_that(a+b+c).is_equal(expected)

@warning_ignore('unused_parameter')
func test_parameterized_failed(a: int, b :int, c :int, expected :int, test_parameters := [
	[1, 2, 3, 6],
	[3, 4, 5, 11],
	[6, 7, 8, 21] ]) -> void:

	assert_that(a+b+c).is_equal(expected)

@warning_ignore('unused_parameter')
func test_parameterized_to_less_args(a: int, b :int, expected :int, test_parameters := [
	[1, 2, 3, 6],
	[3, 4, 5, 11],
	[6, 7, 8, 21] ]) -> void:
	pass

@warning_ignore('unused_parameter')
func test_parameterized_to_many_args(a: int, b :int, c :int, d :int, expected :int, test_parameters := [
	[1, 2, 3, 6],
	[3, 4, 5, 11],
	[6, 7, 8, 21] ]) -> void:
	pass

@warning_ignore('unused_parameter')
func test_parameterized_to_less_args_at_index_1(a: int, b :int, expected :int, test_parameters := [
	[1, 2, 6],
	[3, 4, 5, 11],
	[6, 7, 21] ]) -> void:
	pass

@warning_ignore('unused_parameter')
func test_parameterized_invalid_struct(a: int, b :int, expected :int, test_parameters := [
	[1, 2, 6],
	["foo"],
	[6, 7, 21] ]) -> void:
	pass

@warning_ignore('unused_parameter')
func test_parameterized_invalid_args(a: int, b :int, expected :int, test_parameters := [
	[1, 2, 6],
	[3, "4", 11],
	[6, 7, 21] ]) -> void:
	pass


const _data1 := ["aa"]
const _data2 := ["bb"]


@warning_ignore('unused_parameter')
func test_with_extern_const_parameter_set(value: String, _test_parameters := [_data1, _data2]) -> void:
	pass
