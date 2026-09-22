# GdUnit generated TestSuite
class_name GdUnitFloatAssertImplTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitFloatAssertImpl.gd'


func test_is_null() -> void:
	assert_float(null).is_null()

	assert_failure(func() -> void: assert_float(23.2).is_null()) \
		.is_failed() \
		.starts_with_message("Expecting: '<null>' but was 23.200000")


func test_is_not_null() -> void:
	assert_float(23.2).is_not_null()

	assert_failure(func() -> void: assert_float(null).is_not_null()) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_equal() -> void:
	assert_float(23.2).is_equal(23.2)

	assert_failure(func() -> void: assert_float(23.2).is_equal(23.4)) \
		.is_failed() \
		.has_message("Expecting:\n 23.400000\n but was\n 23.200000")
	assert_failure(func() -> void: assert_float(null).is_equal(23.4)) \
		.is_failed() \
		.has_message("Expecting:\n 23.400000\n but was\n '<null>'")


func test_is_not_equal() -> void:
	assert_float(null).is_not_equal(23.4)
	assert_float(23.2).is_not_equal(23.4)

	assert_failure(func() -> void: assert_float(23.2).is_not_equal(23.2)) \
		.is_failed() \
		.has_message("Expecting:\n 23.200000\n not equal to\n 23.200000")


func test_is_equal_approx() -> void:
	assert_float(23.2).is_equal_approx(23.2, 0.01)
	assert_float(23.19).is_equal_approx(23.2, 0.01)
	assert_float(23.20).is_equal_approx(23.2, 0.01)
	assert_float(23.21).is_equal_approx(23.2, 0.01)

	assert_failure(func() -> void: assert_float(23.18).is_equal_approx(23.2, 0.01)) \
		.is_failed() \
		.has_message("Expecting:\n 23.180000\n in range between\n 23.190000 <> 23.210000")
	assert_failure(func() -> void: assert_float(23.22).is_equal_approx(23.2, 0.01)) \
		.is_failed() \
		.has_message("Expecting:\n 23.220000\n in range between\n 23.190000 <> 23.210000")
	assert_failure(func() -> void: assert_float(null).is_equal_approx(23.2, 0.01)) \
		.is_failed() \
		.has_message("Expecting:\n '<null>'\n in range between\n 23.190000 <> 23.210000")



func test_is_less_() -> void:
	assert_failure(func() -> void: assert_float(23.2).is_less(23.2)) \
		.is_failed() \
		.has_message("Expecting to be less than:\n 23.200000 but was 23.200000")

func test_is_less() -> void:
	assert_float(23.2).is_less(23.4)
	assert_float(23.2).is_less(26.0)

	assert_failure(func() -> void: assert_float(23.2).is_less(23.2)) \
		.is_failed() \
		.has_message("Expecting to be less than:\n 23.200000 but was 23.200000")
	assert_failure(func() -> void: assert_float(null).is_less(23.2)) \
		.is_failed() \
		.has_message("Expecting to be less than:\n 23.200000 but was '<null>'")


func test_is_less_equal() -> void:
	assert_float(23.2).is_less_equal(23.4)
	assert_float(23.2).is_less_equal(23.2)

	assert_failure(func() -> void: assert_float(23.2).is_less_equal(23.1)) \
		.is_failed() \
		.has_message("Expecting to be less than or equal:\n 23.100000 but was 23.200000")
	assert_failure(func() -> void: assert_float(null).is_less_equal(23.1)) \
		.is_failed() \
		.has_message("Expecting to be less than or equal:\n 23.100000 but was '<null>'")


func test_is_greater() -> void:
	assert_float(23.2).is_greater(23.0)
	assert_float(23.4).is_greater(22.1)

	assert_failure(func() -> void: assert_float(23.2).is_greater(23.2)) \
		.is_failed() \
		.has_message("Expecting to be greater than:\n 23.200000 but was 23.200000")
	assert_failure(func() -> void: assert_float(null).is_greater(23.2)) \
		.is_failed() \
		.has_message("Expecting to be greater than:\n 23.200000 but was '<null>'")


func test_is_greater_equal() -> void:
	assert_float(23.2).is_greater_equal(20.2)
	assert_float(23.2).is_greater_equal(23.2)

	assert_failure(func() -> void: assert_float(23.2).is_greater_equal(23.3)) \
		.is_failed() \
		.has_message("Expecting to be greater than or equal:\n 23.300000 but was 23.200000")
	assert_failure(func() -> void: assert_float(null).is_greater_equal(23.3)) \
		.is_failed() \
		.has_message("Expecting to be greater than or equal:\n 23.300000 but was '<null>'")


func test_is_negative() -> void:
	assert_float(-13.2).is_negative()

	assert_failure(func() -> void: assert_float(13.2).is_negative()) \
		.is_failed() \
		.has_message("Expecting:\n 13.200000 be negative")
	assert_failure(func() -> void: assert_float(null).is_negative()) \
		.is_failed() \
		.has_message("Expecting:\n '<null>' be negative")


func test_is_not_negative() -> void:
	assert_float(13.2).is_not_negative()

	assert_failure(func() -> void: assert_float(-13.2).is_not_negative()) \
		.is_failed() \
		.has_message("Expecting:\n -13.200000 be not negative")
	assert_failure(func() -> void: assert_float(null).is_not_negative()) \
		.is_failed() \
		.has_message("Expecting:\n '<null>' be not negative")


func test_is_zero() -> void:
	assert_float(0.0).is_zero()

	assert_failure(func() -> void: assert_float(0.00001).is_zero()) \
		.is_failed() \
		.has_message("Expecting:\n equal to 0 but is 0.000010")
	assert_failure(func() -> void: assert_float(null).is_zero()) \
		.is_failed() \
		.has_message("Expecting:\n equal to 0 but is '<null>'")


func test_is_not_zero() -> void:
	assert_float(0.00001).is_not_zero()

	assert_failure(func() -> void: assert_float(0.000001).is_not_zero()) \
		.is_failed() \
		.has_message("Expecting:\n not equal to 0")
	assert_failure(func() -> void: assert_float(null).is_not_zero()) \
		.is_failed() \
		.has_message("Expecting:\n not equal to 0")


func test_is_in() -> void:
	assert_float(5.2).is_in([5.1, 5.2, 5.3, 5.4])
	# this assertion fail because 5.5 is not in [5.1, 5.2, 5.3, 5.4]
	assert_failure(func() -> void: assert_float(5.5).is_in([5.1, 5.2, 5.3, 5.4])) \
		.is_failed() \
		.has_message("Expecting:\n 5.500000\n is in\n '[5.1, 5.2, 5.3, 5.4]'")
	assert_failure(func() -> void: assert_float(null).is_in([5.1, 5.2, 5.3, 5.4])) \
		.is_failed() \
		.has_message("Expecting:\n '<null>'\n is in\n '[5.1, 5.2, 5.3, 5.4]'")


func test_is_not_in() -> void:
	assert_float(null).is_not_in([5.1, 5.3, 5.4])
	assert_float(5.2).is_not_in([5.1, 5.3, 5.4])
	# this assertion fail because 5.2 is not in [5.1, 5.2, 5.3, 5.4]
	assert_failure(func() -> void: assert_float(5.2).is_not_in([5.1, 5.2, 5.3, 5.4])) \
		.is_failed() \
		.has_message("Expecting:\n 5.200000\n is not in\n '[5.1, 5.2, 5.3, 5.4]'")


func test_is_between() -> void:
	assert_float(-20.0).is_between(-20.0, 20.9)
	assert_float(10.0).is_between(-20.0, 20.9)
	assert_float(20.9).is_between(-20.0, 20.9)


func test_is_between_must_fail() -> void:
	assert_failure(func() -> void: assert_float(-10.0).is_between(-9.0, 0.0)) \
		.is_failed() \
		.has_message("Expecting:\n -10.000000\n in range between\n -9.000000 <> 0.000000")
	assert_failure(func() -> void: assert_float(0.0).is_between(1, 10)) \
		.is_failed() \
		.has_message("Expecting:\n 0.000000\n in range between\n 1.000000 <> 10.000000")
	assert_failure(func() -> void: assert_float(10.0).is_between(11, 21)) \
		.is_failed() \
		.has_message("Expecting:\n 10.000000\n in range between\n 11.000000 <> 21.000000")
	assert_failure(func() -> void: assert_float(null).is_between(11, 21)) \
		.is_failed() \
		.has_message("Expecting:\n '<null>'\n in range between\n 11.000000 <> 21.000000")


func test_must_fail_has_invlalid_type() -> void:
	assert_failure(func() -> void: assert_float(1)) \
		.is_failed() \
		.has_message("GdUnitFloatAssert inital error, unexpected type <int>")
	assert_failure(func() -> void: assert_float(true)) \
		.is_failed() \
		.has_message("GdUnitFloatAssert inital error, unexpected type <bool>")
	assert_failure(func() -> void: assert_float("foo")) \
		.is_failed() \
		.has_message("GdUnitFloatAssert inital error, unexpected type <String>")
	assert_failure(func() -> void: assert_float(Resource.new())) \
		.is_failed() \
		.has_message("GdUnitFloatAssert inital error, unexpected type <Object>")


func test_override_failure_message() -> void:
	assert_object(assert_float(3.14).override_failure_message("error")).is_instanceof(GdUnitFloatAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_float(3.14) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_float(3.14).append_failure_message("error")).is_instanceof(GdUnitFloatAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_float(3.14) \
			.append_failure_message("custom failure data") \
			.is_zero()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 equal to 0 but is 3.140000
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))


# tests if an assert fails the 'is_failure' reflects the failure status
func test_is_failure() -> void:
	# initial is false
	assert_bool(is_failure()).is_false()

	# checked success assert
	assert_float(0.0).is_zero()
	assert_bool(is_failure()).is_false()

	# checked faild assert
	assert_failure(func() -> void: assert_float(1.0).is_zero()) \
		.is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_float(0.0).is_zero()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()

	# should abort here because we had an failing assert
	if is_failure():
		return
	assert_bool(true).override_failure_message("This line shold never be called").is_false()
