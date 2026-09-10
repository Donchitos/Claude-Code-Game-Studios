# GdUnit generated TestSuite
class_name GdUnitVectorAssertImplTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitVectorAssertImpl.gd'


var _test_seta := [
	[null],
	[Vector2.ONE],
	[Vector2i.ONE],
	[Vector3.ONE],
	[Vector3i.ONE],
	[Vector4.ONE],
	[Vector4i.ONE],
]


@warning_ignore("unused_parameter")
func test_supported_types(value :Variant, test_parameters := _test_seta) -> void:
	assert_object(assert_vector(value))\
		.is_not_null()\
		.is_instanceof(GdUnitVectorAssert)


@warning_ignore("unused_parameter")
func test_unsupported_types(value :Variant, details :String, test_parameters :=[
	[true, 'bool'],
	[42, 'int'],
	[42.0, 'float'],
	['foo', 'String'],
] ) -> void:
	assert_failure(func() -> void: assert_vector(value))\
		.is_failed()\
		.has_message("GdUnitVectorAssert error, the type <%s> is not supported." % details)


@warning_ignore("unused_parameter")
func test_is_null(value :Variant, test_parameters := _test_seta) -> void:
	if value == null:
		assert_vector(null).is_null()
	else:
		assert_failure(func() -> void: assert_vector(value).is_null()) \
			.is_failed() \
			.starts_with_message("Expecting: '<null>' but was '%s'" % str(value))


@warning_ignore("unused_parameter")
func test_is_not_null(value :Variant, test_parameters := _test_seta) -> void:
	if value == null:
		assert_failure(func() -> void: assert_vector(null).is_not_null()) \
			.is_failed() \
			.has_message("Expecting: not to be '<null>'")
	else:
		assert_vector(value).is_not_null()


@warning_ignore("unused_parameter")
func test_is_equal() -> void:
	assert_vector(Vector2.ONE).is_equal(Vector2.ONE)
	assert_vector(Vector2.LEFT).is_equal(Vector2.LEFT)
	assert_vector(Vector2(1.2, 1.000001)).is_equal(Vector2(1.2, 1.000001))

	# is not equal
	assert_failure(func() -> void: assert_vector(Vector2.ONE).is_equal(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting:\n '$v0'\n but was\n '$v1'"
			.replace("$v0", str(Vector2(1.2, 1.000001)))
			.replace("$v1", str(Vector2.ONE))
			)
	# is null
	assert_failure(func() -> void: assert_vector(null).is_equal(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting:\n '$v0'\n but was\n '<null>'"
			.replace("$v0", str(Vector2(1.2, 1.000001)))
		)
	# comparing different vector types
	assert_failure(func() -> void: assert_vector(Vector2.ONE).is_equal(Vector3.ONE)) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")


@warning_ignore("unused_parameter")
func test_is_equal_over_all_types(value :Variant, test_parameters := _test_seta) -> void:
	assert_vector(value).is_equal(value)


func test_is_not_equal() -> void:
	assert_vector(null).is_not_equal(Vector2.LEFT)
	assert_vector(Vector2.ONE).is_not_equal(Vector2.LEFT)
	assert_vector(Vector2.LEFT).is_not_equal(Vector2.ONE)
	assert_vector(Vector2(1.2, 1.000001)).is_not_equal(Vector2(1.2, 1.000002))

	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000001)).is_not_equal(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting:\n '(1.2, 1.000001)'\n not equal to\n '(1.2, 1.000001)'")
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000001)).is_not_equal(Vector3(1.2, 1.000001, 1.0))) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")


@warning_ignore("unused_parameter")
func test_is_not_equal_over_all_types(value :Variant, test_parameters := _test_seta) -> void:
	var expected :Variant = Vector2.LEFT if value == null else value * 2
	assert_vector(value).is_not_equal(expected)


func test_is_equal_approx() -> void:
	assert_vector(Vector2.ONE).is_equal_approx(Vector2.ONE, Vector2(0.004, 0.004))
	assert_vector(Vector2(0.996, 0.996)).is_equal_approx(Vector2.ONE, Vector2(0.004, 0.004))
	assert_vector(Vector2(1.004, 1.004)).is_equal_approx(Vector2.ONE, Vector2(0.004, 0.004))

	var current := Vector2(1.005, 1)
	var approx_min := Vector2.ONE - Vector2(0.004, 0.004)
	var approx_max := Vector2.ONE + Vector2(0.004, 0.004)
	assert_failure(func() -> void: assert_vector(Vector2(1.005, 1)).is_equal_approx(Vector2.ONE, Vector2(0.004, 0.004))) \
		.is_failed() \
		.has_message("Expecting:\n '$v0'\n in range between\n '$v1' <> '$v2'"
			.replace("$v0", str(current))
			.replace("$v1", str(approx_min))
			.replace("$v2", str(approx_max))
		)

	current = Vector2(1, 0.995)
	approx_min = Vector2.ONE - Vector2(0, 0.004)
	approx_max = Vector2.ONE + Vector2(0, 0.004)
	assert_failure(func() -> void: assert_vector(current).is_equal_approx(Vector2.ONE, Vector2(0, 0.004))) \
		.is_failed() \
		.has_message("Expecting:\n '$v0'\n in range between\n '$v1' <> '$v2'"
			.replace("$v0", str(current))
			.replace("$v1", str(approx_min))
			.replace("$v2", str(approx_max))
		)

	assert_failure(func() -> void: assert_vector(null).is_equal_approx(Vector2.ONE, Vector2(0, 0.004))) \
		.is_failed() \
		.has_message("Expecting:\n '<null>'\n in range between\n '$v1' <> '$v2'"
			.replace("$v1", str(approx_min))
			.replace("$v2", str(approx_max))
		)
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000001)).is_equal_approx(Vector3.ONE, Vector3(1.2, 1.000001, 1.0))) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")
	assert_failure(func() -> void: assert_vector(Vector2(0.878431, 0.505882)).is_equal_approx(Vector2(0.878431, 0.105882), Vector2(0.000001, 0.000001))) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '(0.878431, 0.505882)'
			 in range between
			 '(0.87843, 0.105881)' <> '(0.878432, 0.105883)'"""
			.dedent().trim_prefix("\n")
		)
	var currentV3 := Vector3(0.0, 0.878431, 0.505882)
	assert_failure(func() -> void: assert_vector(currentV3).is_equal_approx(Vector3(0.0, 0.878431, 0.105882), Vector3(0.000001, 0.000001, 0.000001))) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '$v0'
			 in range between
			 '(-0.000001, 0.87843, 0.105881)' <> '(0.000001, 0.878432, 0.105883)'"""
			.dedent().trim_prefix("\n")
			.replace("$v0", str(currentV3))
		)


@warning_ignore("unused_parameter")
func test_is_equal_approx_over_all_types(value :Variant, expected :Variant, approx :Variant, test_parameters := [
	[Vector2(0.996, 1.004), Vector2.ONE, Vector2(0.004, 0.004)],
	[Vector2i(9, 11), Vector2i(10, 10), Vector2i(1, 1)],
	[Vector3(0.996, 0.996, 1.004), Vector3.ONE, Vector3(0.004, 0.004, 0.004)],
	[Vector3i(10, 9, 11), Vector3i(10, 10, 10), Vector3i(1, 1, 1)],
	[Vector4(0.996, 0.996, 1.004, 1.004), Vector4.ONE, Vector4(0.004, 0.004, 0.004, 0.004)],
	[Vector4i(10, 9, 11, 9), Vector4i(10, 10, 10, 10), Vector4i(1, 1, 1, 1)]
]) -> void:
	assert_vector(value).is_equal_approx(expected, approx)


func test_is_less() -> void:
	assert_vector(Vector2.LEFT).is_less(Vector2.ONE)
	assert_vector(Vector2(1.2, 1.000001)).is_less(Vector2(1.2, 1.000002))

	assert_failure(func() -> void: assert_vector(Vector2.ONE).is_less(Vector2.ONE)) \
		.is_failed() \
		.has_message("Expecting to be less than:\n '$v0' but was '$v1'"
			.replace("$v0", str(Vector2.ONE))
			.replace("$v1", str(Vector2.ONE))
		)
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000001)).is_less(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting to be less than:\n '(1.2, 1.000001)' but was '(1.2, 1.000001)'")
	assert_failure(func() -> void: assert_vector(null).is_less(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting to be less than:\n '(1.2, 1.000001)' but was '<null>'")
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000001)).is_less(Vector3(1.2, 1.000001, 1.0))) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")


@warning_ignore("unused_parameter")
func test_is_less_over_all_types(value :Variant, expected :Variant, test_parameters := [
	[Vector2(1.0, 1.0), Vector2(1.0001, 1.0001)],
	[Vector2i(1, 1), Vector2i(2, 1)],
	[Vector3(1.0, 1.0, 1.0), Vector3(1.0001, 1.0001, 1.0)],
	[Vector3i(1, 1, 1), Vector3i(2, 1, 1)],
	[Vector4(1.0, 1.0, 1.0, 1.0), Vector4(1.0001, 1.0001, 1.0, 1.0)],
	[Vector4i(1, 1, 1, 1), Vector4i(2, 1, 1, 1)],
]) -> void:
	assert_vector(value).is_less(expected)


func test_is_less_equal() -> void:
	assert_vector(Vector2.ONE).is_less_equal(Vector2.ONE)
	assert_vector(Vector2(1.2, 1.000001)).is_less_equal(Vector2(1.2, 1.000001))
	assert_vector(Vector2(1.2, 1.000001)).is_less_equal(Vector2(1.2, 1.000002))

	assert_failure(func() -> void: assert_vector(Vector2.ONE).is_less_equal(Vector2.ZERO)) \
		.is_failed() \
		.has_message("Expecting to be less than or equal:\n '$v0' but was '$v1'"
			.replace("$v0", str(Vector2.ZERO))
			.replace("$v1", str(Vector2.ONE))
		)
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000002)).is_less_equal(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting to be less than or equal:\n '(1.2, 1.000001)' but was '(1.2, 1.000002)'")
	assert_failure(func() -> void: assert_vector(null).is_less_equal(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting to be less than or equal:\n '(1.2, 1.000001)' but was '<null>'")
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000002)).is_less_equal(Vector3(1.2, 1.000001, 1.0))) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")


@warning_ignore("unused_parameter")
func test_is_less_equal_over_all_types(value :Variant, expected :Variant, test_parameters := [
	[Vector2(1.0, 1.0), Vector2(1.0001, 1.0001)],
	[Vector2(1.0, 1.0), Vector2(1.0, 1.0)],
	[Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(1, 1), Vector2i(1, 1)],
	[Vector3(1.0, 1.0, 1.0), Vector3(1.0001, 1.0001, 1.0)],
	[Vector3(1.0, 1.0, 1.0), Vector3(1.0, 1.0, 1.0)],
	[Vector3i(1, 1, 1), Vector3i(2, 1, 1)],
	[Vector3i(1, 1, 1), Vector3i(1, 1, 1)],
	[Vector4(1.0, 1.0, 1.0, 1.0), Vector4(1.0001, 1.0001, 1.0, 1.0)],
	[Vector4(1.0, 1.0, 1.0, 1.0), Vector4(1.0, 1.0, 1.0, 1.0)],
	[Vector4i(1, 1, 1, 1), Vector4i(2, 1, 1, 1)],
	[Vector4i(1, 1, 1, 1), Vector4i(1, 1, 1, 1)],
]) -> void:
	assert_vector(value).is_less_equal(expected)


func test_is_greater() -> void:
	assert_vector(Vector2.ONE).is_greater(Vector2.RIGHT)
	assert_vector(Vector2(1.2, 1.000002)).is_greater(Vector2(1.2, 1.000001))

	assert_failure(func() -> void: assert_vector(Vector2.ZERO).is_greater(Vector2.ONE)) \
		.is_failed() \
		.has_message("Expecting to be greater than:\n '$v0' but was '$v1'"
			.replace("$v0", str(Vector2.ONE))
			.replace("$v1", str(Vector2.ZERO))
		)
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000001)).is_greater(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting to be greater than:\n '(1.2, 1.000001)' but was '(1.2, 1.000001)'")
	assert_failure(func() -> void: assert_vector(null).is_greater(Vector2(1.2, 1.000001))) \
		.is_failed() \
		.has_message("Expecting to be greater than:\n '(1.2, 1.000001)' but was '<null>'")
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000001)).is_greater(Vector3(1.2, 1.000001, 1.0))) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")


@warning_ignore("unused_parameter")
func test_is_greater_over_all_types(value :Variant, expected :Variant, test_parameters := [
	[Vector2(1.0001, 1.0001), Vector2(1.0, 1.0)],
	[Vector2i(2, 1), Vector2i(1, 1)],
	[Vector3(1.0001, 1.0001, 1.0), Vector3(1.0, 1.0, 1.0)],
	[Vector3i(2, 1, 1), Vector3i(1, 1, 1)],
	[Vector4(1.0001, 1.0001, 1.0, 1.0), Vector4(1.0, 1.0, 1.0, 1.0)],
	[Vector4i(2, 1, 1, 1), Vector4i(1, 1, 1, 1)],
]) -> void:
	assert_vector(value).is_greater(expected)


func test_is_greater_equal() -> void:
	assert_vector(Vector2.ONE*2).is_greater_equal(Vector2.ONE)
	assert_vector(Vector2.ONE).is_greater_equal(Vector2.ONE)
	assert_vector(Vector2(1.2, 1.000001)).is_greater_equal(Vector2(1.2, 1.000001))
	assert_vector(Vector2(1.2, 1.000002)).is_greater_equal(Vector2(1.2, 1.000001))

	assert_failure(func() -> void: assert_vector(Vector2.ZERO).is_greater_equal(Vector2.ONE)) \
		.is_failed() \
		.has_message("Expecting to be greater than or equal:\n '$v0' but was '$v1'"
			.replace("$v0", str(Vector2.ONE))
			.replace("$v1", str(Vector2.ZERO))
		)
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000002)).is_greater_equal(Vector2(1.2, 1.000003))) \
		.is_failed() \
		.has_message("Expecting to be greater than or equal:\n '(1.2, 1.000003)' but was '(1.2, 1.000002)'")
	assert_failure(func() -> void: assert_vector(null).is_greater_equal(Vector2(1.2, 1.000003))) \
		.is_failed() \
		.has_message("Expecting to be greater than or equal:\n '(1.2, 1.000003)' but was '<null>'")
	assert_failure(func() -> void: assert_vector(Vector2(1.2, 1.000002)).is_greater_equal(Vector3(1.2, 1.000003, 1.0))) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")


@warning_ignore("unused_parameter")
func test_is_greater_equal_over_all_types(value :Variant, expected :Variant, test_parameters := [
	[Vector2(1.0001, 1.0001), Vector2(1.0, 1.0)],
	[Vector2(1.0, 1.0), Vector2(1.0, 1.0)],
	[Vector2i(2, 1), Vector2i(1, 1)],
	[Vector2i(1, 1), Vector2i(1, 1)],
	[Vector3(1.0001, 1.0001, 1.0), Vector3(1.0, 1.0, 1.0)],
	[Vector3(1.0, 1.0, 1.0), Vector3(1.0, 1.0, 1.0)],
	[Vector3i(2, 1, 1), Vector3i(1, 1, 1)],
	[Vector3i(1, 1, 1), Vector3i(1, 1, 1)],
	[Vector4(1.0001, 1.0001, 1.0, 1.0), Vector4(1.0, 1.0, 1.0, 1.0)],
	[Vector4(1.0, 1.0, 1.0, 1.0), Vector4(1.0, 1.0, 1.0, 1.0)],
	[Vector4i(2, 1, 1, 1), Vector4i(1, 1, 1, 1)],
	[Vector4i(1, 1, 1, 1), Vector4i(1, 1, 1, 1)],
]) -> void:
	assert_vector(value).is_greater_equal(expected)


@warning_ignore("unused_parameter")
func test_is_between(fuzzer := Fuzzers.rangev2(Vector2.ZERO, Vector2.ONE), fuzzer_iterations := 200) -> void:
	var value :Vector2 = fuzzer.next_value()
	assert_vector(value).is_between(Vector2.ZERO, Vector2.ONE)


func test_is_between_failed() -> void:
	var current := Vector2(1, 1.00001)
	assert_failure(func() -> void: assert_vector(current).is_between(Vector2.ZERO, Vector2.ONE)) \
		.is_failed() \
		.has_message("Expecting:\n '$v0'\n in range between\n '$v1' <> '$v2'"
			.replace("$v0", str(current))
			.replace("$v1", str(Vector2.ZERO))
			.replace("$v2", str(Vector2.ONE))
		)
	assert_failure(func() -> void: assert_vector(null).is_between(Vector2.ZERO, Vector2.ONE)) \
		.is_failed() \
		.has_message("Expecting:\n '<null>'\n in range between\n '$v0' <> '$v1'"
			.replace("$v0", str(Vector2.ZERO))
			.replace("$v1", str(Vector2.ONE))
		)
	assert_failure(func() -> void: assert_vector(current).is_between(Vector2.ZERO, Vector3.ONE)) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")


@warning_ignore("unused_parameter")
func test_is_between_over_all_types(value :Variant, from :Variant, to :Variant, test_parameters := [
	[Vector2(1.2, 1.2), Vector2(1.0, 1.0), Vector2(1.2, 1.2)],
	[Vector2i(1, 1), Vector2i(1, 1), Vector2i(2, 2)],
	[Vector3(1.2, 1.2, 1.2), Vector3(1.0, 1.0, 1.0), Vector3(1.2, 1.2, 1.2)],
	[Vector3i(1, 1, 1), Vector3i(1, 1, 1), Vector3i(2, 2, 2)],
	[Vector4(1.2, 1.2, 1.2, 1.2), Vector4(1.0, 1.0, 1.0, 1.0), Vector4(1.2, 1.2, 1.2, 1.2)],
	[Vector4i(1, 1, 1, 1), Vector4i(1, 1, 1, 1), Vector4i(2, 2, 2, 2)],
]) -> void:
	assert_vector(value).is_between(from, to)


@warning_ignore("unused_parameter")
func test_is_not_between(fuzzer := Fuzzers.rangev2(Vector2.ONE, Vector2.ONE*2), fuzzer_iterations := 200) -> void:
	var value :Vector2 = fuzzer.next_value()
	assert_vector(null).is_not_between(Vector2.ZERO, Vector2.ONE)
	assert_vector(value).is_not_between(Vector2.ZERO, Vector2.ONE)

	assert_failure(func() -> void: assert_vector(Vector2.ONE).is_not_between(Vector2.ZERO, Vector2.ONE)) \
		.is_failed() \
		.has_message("Expecting:\n '$v0'\n not in range between\n '$v1' <> '$v2'"
			.replace("$v0", str(Vector2.ONE))
			.replace("$v1", str(Vector2.ZERO))
			.replace("$v2", str(Vector2.ONE))
		)
	assert_failure(func() -> void: assert_vector(Vector2.ONE).is_not_between(Vector3.ZERO, Vector2.ONE)) \
		.is_failed() \
		.has_message("Unexpected type comparison:\n Expecting type 'Vector2' but is 'Vector3'")


@warning_ignore("unused_parameter")
func test_is_not_between_over_all_types(value :Variant, from :Variant, to :Variant, test_parameters := [
	[Vector2(3.2, 1.2), Vector2(1.0, 1.0), Vector2(1.2, 1.2)],
	[Vector2i(3, 1), Vector2i(1, 1), Vector2i(2, 2)],
	[Vector3(3.2, 1.2, 1.2), Vector3(1.0, 1.0, 1.0), Vector3(1.2, 1.2, 1.2)],
	[Vector3i(3, 1, 1), Vector3i(1, 1, 1), Vector3i(2, 2, 2)],
	[Vector4(3.2, 1.2, 1.2, 1.2), Vector4(1.0, 1.0, 1.0, 1.0), Vector4(1.2, 1.2, 1.2, 1.2)],
	[Vector4i(3, 1, 1, 1), Vector4i(1, 1, 1, 1), Vector4i(2, 2, 2, 2)],
]) -> void:
	assert_vector(value).is_not_between(from, to)


func test_override_failure_message() -> void:
	assert_object(assert_vector(Vector2.ONE).override_failure_message("error")).is_instanceof(GdUnitVectorAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_vector(Vector2.ONE) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_vector(Vector2.ONE).append_failure_message("error")).is_instanceof(GdUnitVectorAssert)
	@warning_ignore("unsafe_method_access")
	assert_failure(func() -> void: assert_vector(Vector2.ONE) \
			.append_failure_message("custom failure data") \
			.is_equal(Vector2.ZERO)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '$v0'
			 but was
			 '$v1'
			Additional info:
			 custom failure data"""
			.dedent()
			.trim_prefix("\n")
			.replace("$v0", str(Vector2.ZERO))
			.replace("$v1", str(Vector2.ONE)))


# tests if an assert fails the 'is_failure' reflects the failure status
func test_is_failure() -> void:
	# initial is false
	assert_bool(is_failure()).is_false()

	# checked success assert
	assert_vector(null).is_null()
	assert_bool(is_failure()).is_false()

	# checked faild assert
	assert_failure(func() -> void: assert_vector(RefCounted.new()).is_null()) \
		.is_failed()
	assert_bool(is_failure()).is_true()

	# checked next success assert
	assert_vector(null).is_null()
	# is true because we have an already failed assert
	assert_bool(is_failure()).is_true()
