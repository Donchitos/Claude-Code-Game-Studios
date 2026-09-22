# GdUnit generated TestSuite
class_name GdUnitBoolAssertImplTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitBoolAssertImpl.gd'


func test_is_true() -> void:
	assert_bool(true).is_true()

	assert_failure(func() -> void: assert_bool(false).is_true())\
		.is_failed() \
		.has_message("Expecting: 'true' but is 'false'")
	assert_failure(func() -> void: assert_bool(null).is_true()) \
		.is_failed() \
		.has_message("Expecting: 'true' but is '<null>'")


func test_isFalse() -> void:
	assert_bool(false).is_false()

	assert_failure(func() -> void: assert_bool(true).is_false()) \
		.is_failed() \
		.has_message("Expecting: 'false' but is 'true'")
	assert_failure(func() -> void: assert_bool(null).is_false()) \
		.is_failed() \
		.has_message("Expecting: 'false' but is '<null>'")


func test_is_null() -> void:
	assert_bool(null).is_null()
	# should fail because the current is not null
	assert_failure(func() -> void: assert_bool(true).is_null())\
		.is_failed() \
		.starts_with_message("Expecting: '<null>' but was 'true'")


func test_is_not_null() -> void:
	assert_bool(true).is_not_null()
	# should fail because the current is null
	assert_failure(func() -> void: assert_bool(null).is_not_null())\
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_equal() -> void:
	assert_bool(true).is_equal(true)
	assert_bool(false).is_equal(false)

	assert_failure(func() -> void: assert_bool(true).is_equal(false)) \
		.is_failed() \
		.has_message("Expecting:\n 'false'\n but was\n 'true'")
	assert_failure(func() -> void: assert_bool(null).is_equal(false)) \
		.is_failed() \
		.has_message("Expecting:\n 'false'\n but was\n '<null>'")


func test_is_not_equal() -> void:
	assert_bool(null).is_not_equal(false)
	assert_bool(true).is_not_equal(false)
	assert_bool(false).is_not_equal(true)

	assert_failure(func() -> void: assert_bool(true).is_not_equal(true)) \
		.is_failed() \
		.has_message("Expecting:\n 'true'\n not equal to\n 'true'")


func test_fluent() -> void:
	assert_bool(true).is_true().is_equal(true).is_not_equal(false)


func test_must_fail_has_invlalid_type() -> void:
	assert_failure(func() -> void: assert_bool(1)) \
		.is_failed() \
		.has_message("GdUnitBoolAssert inital error, unexpected type <int>")
	assert_failure(func() -> void: assert_bool(3.13)) \
		.is_failed() \
		.has_message("GdUnitBoolAssert inital error, unexpected type <float>")
	assert_failure(func() -> void: assert_bool("foo")) \
		.is_failed() \
		.has_message("GdUnitBoolAssert inital error, unexpected type <String>")
	assert_failure(func() -> void: assert_bool(Resource.new())) \
		.is_failed() \
		.has_message("GdUnitBoolAssert inital error, unexpected type <Object>")


func test_override_failure_message() -> void:
	assert_object(assert_bool(true).override_failure_message("error")).is_instanceof(GdUnitBoolAssert)
	assert_failure(func() -> void: assert_bool(true) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_bool(true).append_failure_message("error")).is_instanceof(GdUnitBoolAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_bool(true) \
			.append_failure_message("custom failure data") \
			.is_false()) \
		.is_failed() \
		.has_message("""
			Expecting: 'false' but is 'true'
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))


# tests if an assert fails the 'is_failure' reflects the failure status
func test_is_failure() -> void:
	# initial is false
	assert_bool(is_failure()).is_false()

	# checked success assert
	assert_bool(true).is_true()
	assert_bool(is_failure()).is_false()

	# checked faild assert
	assert_failure(func() -> void: assert_bool(true).is_false()).is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_bool(true).is_true()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()

	# should abort here because we had an failing assert
	if is_failure():
		return
	assert_bool(true).override_failure_message("This line shold never be called").is_false()
