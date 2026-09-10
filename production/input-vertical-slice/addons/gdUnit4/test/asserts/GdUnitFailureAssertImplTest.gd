# GdUnit generated TestSuite
class_name GdUnitFailureAssertImplTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitFailureAssertImpl.gd'


func last_assert() -> Variant:
	return GdUnitThreadManager.get_current_context().get_assert()


func test_has_line() -> void:
	assert_failure(func() -> void: assert_bool(true).is_false()) \
		.is_failed() \
		.has_line(16)


func test_has_message() -> void:
	assert_failure(func() -> void: assert_bool(true).is_true()) \
		.is_success()
	assert_failure(func() -> void: assert_bool(true).is_false()) \
		.is_failed()\
		.has_message("Expecting: 'false' but is 'true'")


func test_starts_with_message() -> void:
	assert_failure(func() -> void: assert_bool(true).is_false()) \
		.is_failed()\
		.starts_with_message("Expecting: 'false' bu")


func test_assert_failure_on_invalid_cb() -> void:
	assert_failure(func() -> void: prints())\
		.is_failed()\
		.has_message("Invalid Callable! It must be a callable of 'GdUnitAssert'")


@warning_ignore("unused_parameter")
func test_assert_failure_on_assert(test_name :String, assert_type :Object, value :Variant, test_parameters := [
	["GdUnitBoolAssert", GdUnitBoolAssert, true],
	["GdUnitStringAssert", GdUnitStringAssert, "value"],
	["GdUnitIntAssert", GdUnitIntAssert, 42],
	["GdUnitFloatAssert", GdUnitFloatAssert, 42.0],
	["GdUnitObjectAssert", GdUnitObjectAssert, RefCounted.new()],
	["GdUnitVectorAssert", GdUnitVectorAssert, Vector2.ZERO],
	["GdUnitVectorAssert", GdUnitVectorAssert, Vector3.ZERO],
	["GdUnitArrayAssert", GdUnitArrayAssert, Array()],
	["GdUnitDictionaryAssert", GdUnitDictionaryAssert, {}],
]) -> void:
	var  instance := assert_failure(func() -> void: assert_that(value))
	assert_object(last_assert()).is_instanceof(assert_type)
	assert_object(instance).is_instanceof(GdUnitFailureAssert)


func test_assert_failure_on_assert_file() -> void:
	var  instance := assert_failure(func() -> void: assert_file("res://foo.gd"))
	assert_object(last_assert()).is_instanceof(GdUnitFileAssert)
	assert_object(instance).is_instanceof(GdUnitFailureAssert)


func test_assert_failure_on_assert_func() -> void:
	var  instance := assert_failure(func() -> void: assert_func(RefCounted.new(), "_to_string"))
	assert_object(last_assert()).is_instanceof(GdUnitFuncAssert)
	assert_object(instance).is_instanceof(GdUnitFailureAssert)


func test_assert_failure_on_assert_signal() -> void:
	var  instance := assert_failure(func() -> void: assert_signal(null))
	assert_object(last_assert()).is_instanceof(GdUnitSignalAssert)
	assert_object(instance).is_instanceof(GdUnitFailureAssert)


func test_assert_failure_on_assert_result() -> void:
	var  instance := assert_failure(func() -> void: assert_result(null))
	assert_object(last_assert()).is_instanceof(GdUnitResultAssert)
	assert_object(instance).is_instanceof(GdUnitFailureAssert)


#region has_stack_trace

func _stack_fail_1() -> void:
	assert_bool(true).is_false()


func _stack_fail_2() -> void:
	_stack_fail_1()


func _stack_fail_3() -> void:
	_stack_fail_2()


func test_has_stack_trace_depth_1() -> void:
	assert_failure(_stack_fail_1) \
		.is_failed() \
		.has_message("Expecting: 'false' but is 'true'") \
		.has_stack_trace([
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/asserts/GdUnitFailureAssertImplTest.gd", 85, "_stack_fail_1"),
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/asserts/GdUnitFailureAssertImplTest.gd", 97, "test_has_stack_trace_depth_1"),
		])


func test_has_stack_trace_depth_3() -> void:
	assert_failure(_stack_fail_3) \
		.is_failed() \
		.has_message("Expecting: 'false' but is 'true'") \
		.has_stack_trace([
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/asserts/GdUnitFailureAssertImplTest.gd", 85, "_stack_fail_1"),
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/asserts/GdUnitFailureAssertImplTest.gd", 89, "_stack_fail_2"),
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/asserts/GdUnitFailureAssertImplTest.gd", 93, "_stack_fail_3"),
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/asserts/GdUnitFailureAssertImplTest.gd", 107, "test_has_stack_trace_depth_3"),
		])

#endregion
