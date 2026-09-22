# GdUnit generated TestSuite
class_name GdUnitIntAssertImplTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitIntAssertImpl.gd'


func test_is_null() -> void:
	assert_int(null).is_null()

	assert_failure(func() -> void: assert_int(23).is_null()) \
		.is_failed() \
		.starts_with_message("Expecting: '<null>' but was 23")


func test_is_not_null() -> void:
	assert_int(23).is_not_null()

	assert_failure(func() -> void: assert_int(null).is_not_null()) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_equal() -> void:
	assert_int(23).is_equal(23)

	assert_failure(func() -> void: assert_int(23).is_equal(42)) \
		.is_failed() \
		.has_message("Expecting:\n 42\n but was\n 23")
	assert_failure(func() -> void: assert_int(null).is_equal(42)) \
		.is_failed() \
		.has_message("Expecting:\n 42\n but was\n '<null>'")


func test_is_not_equal() -> void:
	assert_int(null).is_not_equal(42)
	assert_int(23).is_not_equal(42)

	assert_failure(func() -> void: assert_int(23).is_not_equal(23)) \
		.is_failed() \
		.has_message("Expecting:\n 23\n not equal to\n 23")


func test_is_less() -> void:
	assert_int(23).is_less(42)
	assert_int(23).is_less(24)

	assert_failure(func() -> void: assert_int(23).is_less(23)) \
		.is_failed() \
		.has_message("Expecting to be less than:\n 23 but was 23")
	assert_failure(func() -> void: assert_int(null).is_less(23)) \
		.is_failed() \
		.has_message("Expecting to be less than:\n 23 but was '<null>'")


func test_is_less_equal() -> void:
	assert_int(23).is_less_equal(42)
	assert_int(23).is_less_equal(23)

	assert_failure(func() -> void: assert_int(23).is_less_equal(22)) \
		.is_failed() \
		.has_message("Expecting to be less than or equal:\n 22 but was 23")
	assert_failure(func() -> void: assert_int(null).is_less_equal(22)) \
		.is_failed() \
		.has_message("Expecting to be less than or equal:\n 22 but was '<null>'")


func test_is_greater() -> void:
	assert_int(23).is_greater(20)
	assert_int(23).is_greater(22)

	assert_failure(func() -> void: assert_int(23).is_greater(23)) \
		.is_failed() \
		.has_message("Expecting to be greater than:\n 23 but was 23")
	assert_failure(func() -> void: assert_int(null).is_greater(23)) \
		.is_failed() \
		.has_message("Expecting to be greater than:\n 23 but was '<null>'")


func test_is_greater_equal() -> void:
	assert_int(23).is_greater_equal(20)
	assert_int(23).is_greater_equal(23)

	assert_failure(func() -> void: assert_int(23).is_greater_equal(24)) \
		.is_failed() \
		.has_message("Expecting to be greater than or equal:\n 24 but was 23")
	assert_failure(func() -> void: assert_int(null).is_greater_equal(24)) \
		.is_failed() \
		.has_message("Expecting to be greater than or equal:\n 24 but was '<null>'")


func test_is_even() -> void:
	assert_int(12).is_even()

	assert_failure(func() -> void: assert_int(13).is_even()) \
		.is_failed() \
		.has_message("Expecting:\n 13 must be even")
	assert_failure(func() -> void: assert_int(null).is_even()) \
		.is_failed() \
		.has_message("Expecting:\n '<null>' must be even")


func test_is_odd() -> void:
	assert_int(13).is_odd()

	assert_failure(func() -> void: assert_int(12).is_odd()) \
		.is_failed() \
		.has_message("Expecting:\n 12 must be odd")
	assert_failure(func() -> void: assert_int(null).is_odd()) \
		.is_failed() \
		.has_message("Expecting:\n '<null>' must be odd")


func test_is_negative() -> void:
	assert_int(-13).is_negative()

	assert_failure(func() -> void: assert_int(13).is_negative()) \
		.is_failed() \
		.has_message("Expecting:\n 13 be negative")
	assert_failure(func() -> void: assert_int(null).is_negative()) \
		.is_failed() \
		.has_message("Expecting:\n '<null>' be negative")


func test_is_not_negative() -> void:
	assert_int(13).is_not_negative()

	assert_failure(func() -> void: assert_int(-13).is_not_negative()) \
		.is_failed() \
		.has_message("Expecting:\n -13 be not negative")
	assert_failure(func() -> void: assert_int(null).is_not_negative()) \
		.is_failed() \
		.has_message("Expecting:\n '<null>' be not negative")


func test_is_zero() -> void:
	assert_int(0).is_zero()

	assert_failure(func() -> void: assert_int(1).is_zero()) \
		.is_failed() \
		.has_message("Expecting:\n equal to 0 but is 1")
	assert_failure(func() -> void: assert_int(null).is_zero()) \
		.is_failed() \
		.has_message("Expecting:\n equal to 0 but is '<null>'")


func test_is_not_zero() -> void:
	assert_int(null).is_not_zero()
	assert_int(1).is_not_zero()

	assert_failure(func() -> void: assert_int(0).is_not_zero()) \
		.is_failed() \
		.has_message("Expecting:\n not equal to 0")


func test_is_in() -> void:
	assert_int(5).is_in([3, 4, 5, 6])
	# this assertion fail because 7 is not in [3, 4, 5, 6]
	assert_failure(func() -> void: assert_int(7).is_in([3, 4, 5, 6])) \
		.is_failed() \
		.has_message("Expecting:\n 7\n is in\n '[3, 4, 5, 6]'")
	assert_failure(func() -> void: assert_int(null).is_in([3, 4, 5, 6])) \
		.is_failed() \
		.has_message("Expecting:\n '<null>'\n is in\n '[3, 4, 5, 6]'")


func test_is_not_in() -> void:
	assert_int(null).is_not_in([3, 4, 6, 7])
	assert_int(5).is_not_in([3, 4, 6, 7])
	# this assertion fail because 7 is not in [3, 4, 5, 6]
	assert_failure(func() -> void: assert_int(5).is_not_in([3, 4, 5, 6])) \
		.is_failed() \
		.has_message("Expecting:\n 5\n is not in\n '[3, 4, 5, 6]'")


func test_is_between(fuzzer := Fuzzers.rangei(-20, 20)) -> void:
	var value: int = fuzzer.next_value()
	assert_int(value).is_between(-20, 20)


func test_is_between_must_fail() -> void:
	assert_failure(func() -> void: assert_int(-10).is_between(-9, 0)) \
		.is_failed() \
		.has_message("Expecting:\n -10\n in range between\n -9 <> 0")
	assert_failure(func() -> void: assert_int(0).is_between(1, 10)) \
		.is_failed() \
		.has_message("Expecting:\n 0\n in range between\n 1 <> 10")
	assert_failure(func() -> void: assert_int(10).is_between(11, 21)) \
		.is_failed() \
		.has_message("Expecting:\n 10\n in range between\n 11 <> 21")
	assert_failure(func() -> void: assert_int(null).is_between(11, 21)) \
		.is_failed() \
		.has_message("Expecting:\n '<null>'\n in range between\n 11 <> 21")


func test_must_fail_has_invlalid_type() -> void:
	assert_failure(func() -> void: assert_int(3.3)) \
		.is_failed() \
		.has_message("GdUnitIntAssert inital error, unexpected type <float>")
	assert_failure(func() -> void: assert_int(true)) \
		.is_failed() \
		.has_message("GdUnitIntAssert inital error, unexpected type <bool>")
	assert_failure(func() -> void: assert_int("foo")) \
		.is_failed() \
		.has_message("GdUnitIntAssert inital error, unexpected type <String>")
	assert_failure(func() -> void: assert_int(Resource.new())) \
		.is_failed() \
		.has_message("GdUnitIntAssert inital error, unexpected type <Object>")


func test_override_failure_message() -> void:
	assert_object(assert_int(314).override_failure_message("error")).is_instanceof(GdUnitIntAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_int(314)\
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_int(314).append_failure_message("error")).is_instanceof(GdUnitIntAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_int(314) \
			.append_failure_message("custom failure data") \
			.is_zero()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 equal to 0 but is 314
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))


# tests if an assert fails the 'is_failure' reflects the failure status
func test_is_failure() -> void:
	# initial is false
	assert_bool(is_failure()).is_false()

	# checked success assert
	assert_int(0).is_zero()
	assert_bool(is_failure()).is_false()

	# checked faild assert
	assert_failure(func() -> void: assert_int(1).is_zero()) \
		.is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_int(0).is_zero()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()

	# should abort here because we had an failing assert
	if is_failure():
		return
	assert_bool(true).override_failure_message("This line shold never be called").is_false()
