# GdUnit generated TestSuite
class_name GdUnitAssertImplTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitAssertImpl.gd'


func before() -> void:

	assert_failure(func() -> void: assert_int(10).is_equal(42)) \
		.is_failed() \
		.has_line(11) \
		.has_message("Expecting:\n 42\n but was\n 10")


func after() -> void:
	assert_failure(func() -> void: assert_int(10).is_equal(42)) \
		.is_failed() \
		.has_line(18) \
		.has_message("Expecting:\n 42\n but was\n 10")


func before_test() -> void:
	assert_failure(func() -> void: assert_int(10).is_equal(42)) \
		.is_failed() \
		.has_line(25) \
		.has_message("Expecting:\n 42\n but was\n 10")


func after_test() -> void:
	assert_failure(func() -> void: assert_int(10).is_equal(42)) \
		.is_failed() \
		.has_line(32) \
		.has_message("Expecting:\n 42\n but was\n 10")


func test_get_line_number() -> void:
	# test to return the current line number for an failure
	assert_failure(func() -> void: assert_int(10).is_equal(42)) \
		.is_failed() \
		.has_line(40) \
		.has_message("Expecting:\n 42\n but was\n 10")


func test_get_line_number_yielded() -> void:
	# test to return the current line number after using yield
	await get_tree().create_timer(0.100).timeout
	assert_failure(func() -> void: assert_int(10).is_equal(42)) \
		.is_failed() \
		.has_line(49) \
		.has_message("Expecting:\n 42\n but was\n 10")


func test_get_line_number_multiline() -> void:
	# test to return the current line number for an failure
	# https://github.com/godotengine/godot/issues/43326
	assert_failure(func() -> void: assert_int(10)\
			.is_not_negative()\
			.is_equal(42)) \
		.is_failed() \
		.has_line(58) \
		.has_message("Expecting:\n 42\n but was\n 10")


func test_get_line_number_verify() -> void:
	var obj :Variant = mock(RefCounted)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: verify(obj, 1).get_reference_count()) \
		.is_failed() \
		.has_line(69) \
		.has_message("Expecting interaction on:\n	'get_reference_count()'	1 time's\nBut found interactions on:\n")


func test_is_null() -> void:
	assert_that(null).is_null()

	assert_failure(func() -> void: assert_that(Color.RED).is_null()) \
		.is_failed() \
		.has_line(78) \
		.starts_with_message("Expecting: '<null>' but was 'Color$v0'"
			.replace("$v0", str(Color.RED))
		)


func test_is_not_null() -> void:
	assert_that(Color.RED).is_not_null()

	assert_failure(func() -> void: assert_that(null).is_not_null()) \
		.is_failed() \
		.has_line(89) \
		.has_message("Expecting: not to be '<null>'")


func test_is_equal() -> void:
	assert_that(Color.RED).is_equal(Color.RED)
	assert_that(Plane.PLANE_XY).is_equal(Plane.PLANE_XY)

	assert_failure(func() -> void: assert_that(Color.RED).is_equal(Color.GREEN)) \
		.is_failed() \
		.has_line(99) \
		.has_message("Expecting:\n 'Color$v0'\n but was\n 'Color$v1'"
			.replace("$v0", str(Color.GREEN))
			.replace("$v1", str(Color.RED))
		)


func test_is_not_equal() -> void:
	assert_that(Color.RED).is_not_equal(Color.GREEN)
	assert_that(Plane.PLANE_XY).is_not_equal(Plane.PLANE_XZ)

	assert_failure(func() -> void: assert_that(Color.RED).is_not_equal(Color.RED)) \
		.is_failed() \
		.has_line(112) \
		.has_message("Expecting:\n 'Color$v0'\n not equal to\n 'Color$v1'"
			.replace("$v0", str(Color.RED))
			.replace("$v1", str(Color.RED))
		)


func test_override_failure_message() -> void:
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_that(Color.RED) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_line(123) \
		.has_message("Custom failure message")


func test_assert_not_yet_implemented() -> void:
	assert_failure(func() -> void: assert_not_yet_implemented()) \
		.is_failed() \
		.has_line(132) \
		.has_message("Test not implemented!")


func test_append_failure_message() -> void:
	assert_object(assert_that(null).append_failure_message("error")).is_instanceof(GdUnitObjectAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_that(null) \
			.append_failure_message("custom failure data") \
			.is_not_null()) \
		.is_failed() \
		.has_message("""
			Expecting: not to be '<null>'
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))
