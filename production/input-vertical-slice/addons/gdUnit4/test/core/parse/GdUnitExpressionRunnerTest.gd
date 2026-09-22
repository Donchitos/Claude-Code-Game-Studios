# GdUnit generated TestSuite
class_name GdUnitExpressionsTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/parse/GdUnitExpressionRunner.gd'

const TestFuzzers := preload("res://addons/gdUnit4/test/fuzzers/TestFuzzers.gd")


func test_create_fuzzer_argument_default() -> void:
	var fuzzer := GdUnitExpressionRunner.new().to_fuzzer(GDScript.new(), "Fuzzers.rangei(-10, 22)")
	assert_that(fuzzer).is_not_null()
	assert_object(fuzzer).is_instanceof(Fuzzer)
	assert_int(fuzzer.next_value()).is_between(-10, 22)


func test_create_fuzzer_argument_with_constants() -> void:
	var fuzzer := GdUnitExpressionRunner.new().to_fuzzer(TestFuzzers, "Fuzzers.rangei(-10, MAX_VALUE)")
	assert_that(fuzzer).is_not_null()
	assert_object(fuzzer).is_instanceof(Fuzzer)
	assert_int(fuzzer.next_value()).is_between(-10, 22)


func test_create_fuzzer_argument_with_custom_function() -> void:
	var fuzzer := GdUnitExpressionRunner.new().to_fuzzer(TestFuzzers, "get_fuzzer()")
	assert_that(fuzzer).is_not_null()
	assert_object(fuzzer).is_instanceof(Fuzzer)
	assert_int(fuzzer.next_value()).is_between(TestFuzzers.MIN_VALUE, TestFuzzers.MAX_VALUE)


func test_create_fuzzer_do_fail() -> void:
	var fuzzer := GdUnitExpressionRunner.new().to_fuzzer(TestFuzzers, "non_fuzzer()")
	assert_that(fuzzer).is_null()


func test_create_nested_fuzzer_do_fail() -> void:
	var fuzzer := GdUnitExpressionRunner.new().to_fuzzer(TestFuzzers, "NestedFuzzer.new()")
	assert_that(fuzzer).is_not_null()
	assert_bool(fuzzer is Fuzzer).is_true()
	assert_bool(fuzzer is TestFuzzers.NestedFuzzer).is_true()


func test_create_external_fuzzer() -> void:
	var fuzzer := GdUnitExpressionRunner.new().to_fuzzer(GDScript.new(), "TestExternalFuzzer.new()")
	assert_that(fuzzer).is_not_null()
	assert_bool(fuzzer is Fuzzer).is_true()
	assert_bool(fuzzer is TestExternalFuzzer).is_true()


func test_create_multipe_fuzzers() -> void:
	var fuzzer_a := GdUnitExpressionRunner.new().to_fuzzer(TestFuzzers, "Fuzzers.rangei(-10, MAX_VALUE)")
	var fuzzer_b := GdUnitExpressionRunner.new().to_fuzzer(GDScript.new(), "Fuzzers.rangei(10, 20)")
	assert_that(fuzzer_a).is_not_null()
	assert_object(fuzzer_a).is_instanceof(IntFuzzer)
	var a :IntFuzzer = fuzzer_a
	assert_int(a._from).is_equal(-10)
	assert_int(a._to).is_equal(TestFuzzers.MAX_VALUE)
	assert_that(fuzzer_b).is_not_null()
	assert_object(fuzzer_b).is_instanceof(IntFuzzer)
	var b :IntFuzzer = fuzzer_b
	assert_int(b._from).is_equal(10)
	assert_int(b._to).is_equal(20)


func test_create_fuzzer_with_args() -> void:
	var fuzzer := GdUnitExpressionRunner.new().to_fuzzer(TestFuzzers, "NestedFuzzerWithArgs.new(100, MAX_VALUE, Vector2.ONE)")
	assert_that(fuzzer).is_not_null()
	assert_bool(fuzzer is Fuzzer).is_true()
	assert_bool(fuzzer is TestFuzzers.NestedFuzzerWithArgs).is_true()
