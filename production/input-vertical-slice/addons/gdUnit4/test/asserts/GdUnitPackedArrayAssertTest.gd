@warning_ignore_start("unsafe_method_access")
# GdUnit generated TestSuite
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitArrayAssertImpl.gd'


func test_is_array_assert(_test: String, array: Variant, _test_parameters := [
	["Array", Array()],
	["PackedByteArray", PackedByteArray()],
	["PackedInt32Array", PackedInt32Array()],
	["PackedInt64Array", PackedInt64Array()],
	["PackedFloat32Array", PackedFloat32Array()],
	["PackedFloat64Array", PackedFloat64Array()],
	["PackedStringArray", PackedStringArray()],
	["PackedVector2Array", PackedVector2Array()],
	["PackedVector3Array", PackedVector3Array()],
	["PackedColorArray", PackedColorArray()] ]
	) -> void:
	var assert_ := assert_that(array)
	assert_object(assert_).is_instanceof(GdUnitArrayAssert)


func test_is_null(_test: String, value: Variant, _test_parameters := [
	["Array", Array()],
	["PackedByteArray", PackedByteArray()],
	["PackedInt32Array", PackedInt32Array()],
	["PackedInt64Array", PackedInt64Array()],
	["PackedFloat32Array", PackedFloat32Array()],
	["PackedFloat64Array", PackedFloat64Array()],
	["PackedStringArray", PackedStringArray()],
	["PackedVector2Array", PackedVector2Array()],
	["PackedVector3Array", PackedVector3Array()],
	["PackedColorArray", PackedColorArray()] ]
	) -> void:
	assert_array(null).is_null()
	assert_failure(func() -> void: assert_array(value).is_null()) \
		.is_failed() \
		.has_message("Expecting: '<null>' but was '%s'" % GdDefaultValueDecoder.decode(value))


func test_is_not_null(_test: String, array: Variant, _test_parameters := [
	["Array", Array()],
	["PackedByteArray", PackedByteArray()],
	["PackedInt32Array", PackedInt32Array()],
	["PackedInt64Array", PackedInt64Array()],
	["PackedFloat32Array", PackedFloat32Array()],
	["PackedFloat64Array", PackedFloat64Array()],
	["PackedStringArray", PackedStringArray()],
	["PackedVector2Array", PackedVector2Array()],
	["PackedVector3Array", PackedVector3Array()],
	["PackedColorArray", PackedColorArray()] ]
	) -> void:
	assert_array(array).is_not_null()

	assert_failure(func() -> void: assert_array(null).is_not_null()) \
		.is_failed() \
		.has_message("Expecting: not to be '<null>'")


func test_is_equal(_test: String, array: Variant, _test_parameters := [
	["Array", Array([1, 2, 3, 4, 5])],
	["PackedByteArray", PackedByteArray([1, 2, 3, 4, 5])],
	["PackedInt32Array", PackedInt32Array([1, 2, 3, 4, 5])],
	["PackedInt64Array", PackedInt64Array([1, 2, 3, 4, 5])],
	["PackedFloat32Array", PackedFloat32Array([1, 2, 3, 4, 5])],
	["PackedFloat64Array", PackedFloat64Array([1, 2, 3, 4, 5])],
	["PackedStringArray", PackedStringArray([1, 2, 3, 4, 5])],
	["PackedVector2Array", PackedVector2Array([Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])],
	["PackedVector3Array", PackedVector3Array([Vector3.ZERO, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN])],
	["PackedColorArray", PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.BLACK])] ]
	) -> void:

	var other :Variant = array.duplicate()
	assert_array(array).is_equal(other)
	# should fail because the array not contains same elements and has diff size
	other.append(array[2])
	assert_failure(func() -> void: assert_array(array).is_equal(other)) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '%s'
			 but was
			 '%s'

			Differences found:
			Index	Current	Expected	5	<N/A>	$value	"""
			.dedent()
			.trim_prefix("\n")
			.replace("$value", str(array[2]) ) % [GdArrayTools.as_string(other, false), GdArrayTools.as_string(array, false)])


func test_is_not_equal(_test: String, array: Variant, _test_parameters := [
	["Array", Array([1, 2, 3, 4, 5])],
	["PackedByteArray", PackedByteArray([1, 2, 3, 4, 5])],
	["PackedInt32Array", PackedInt32Array([1, 2, 3, 4, 5])],
	["PackedInt64Array", PackedInt64Array([1, 2, 3, 4, 5])],
	["PackedFloat32Array", PackedFloat32Array([1, 2, 3, 4, 5])],
	["PackedFloat64Array", PackedFloat64Array([1, 2, 3, 4, 5])],
	["PackedStringArray", PackedStringArray([1, 2, 3, 4, 5])],
	["PackedVector2Array", PackedVector2Array([Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])],
	["PackedVector3Array", PackedVector3Array([Vector3.ZERO, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN])],
	["PackedColorArray", PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.BLACK])] ]
	) -> void:

	var other :Variant = array.duplicate()
	other.append(array[2])
	assert_array(array).is_not_equal(other)
	# should fail because the array  contains same elements
	assert_failure(func() -> void: assert_array(array).is_not_equal(array.duplicate())) \
		.is_failed() \
		.has_message("""
			Expecting:
			 '%s'
			 not equal to
			 '%s'"""
			.dedent()
			.trim_prefix("\n") % [GdDefaultValueDecoder.decode(array), GdDefaultValueDecoder.decode(array)])


func test_is_empty(_test: String, array: Variant, _test_parameters := [
	["Array", Array([1, 2, 3, 4, 5])],
	["PackedByteArray", PackedByteArray([1, 2, 3, 4, 5])],
	["PackedInt32Array", PackedInt32Array([1, 2, 3, 4, 5])],
	["PackedInt64Array", PackedInt64Array([1, 2, 3, 4, 5])],
	["PackedFloat32Array", PackedFloat32Array([1, 2, 3, 4, 5])],
	["PackedFloat64Array", PackedFloat64Array([1, 2, 3, 4, 5])],
	["PackedStringArray", PackedStringArray([1, 2, 3, 4, 5])],
	["PackedVector2Array", PackedVector2Array([Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])],
	["PackedVector3Array", PackedVector3Array([Vector3.ZERO, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN])],
	["PackedColorArray", PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.BLACK])] ]
	) -> void:

	var empty :Variant = array.duplicate()
	empty.clear()
	assert_array(empty).is_empty()
	# should fail because the array is not empty
	assert_failure(func() -> void: assert_array(array).is_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must be empty but was
			 '%s'"""
			.dedent()
			.trim_prefix("\n") % GdDefaultValueDecoder.decode(array))


func test_is_not_empty(_test: String, array: Variant, _test_parameters := [
	["Array", Array([1, 2, 3, 4, 5])],
	["PackedByteArray", PackedByteArray([1, 2, 3, 4, 5])],
	["PackedInt32Array", PackedInt32Array([1, 2, 3, 4, 5])],
	["PackedInt64Array", PackedInt64Array([1, 2, 3, 4, 5])],
	["PackedFloat32Array", PackedFloat32Array([1, 2, 3, 4, 5])],
	["PackedFloat64Array", PackedFloat64Array([1, 2, 3, 4, 5])],
	["PackedStringArray", PackedStringArray([1, 2, 3, 4, 5])],
	["PackedVector2Array", PackedVector2Array([Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])],
	["PackedVector3Array", PackedVector3Array([Vector3.ZERO, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN])],
	["PackedColorArray", PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.BLACK])] ]
	) -> void:

	assert_array(array).is_not_empty()
	# should fail because the array is empty
	var empty :Variant = array.duplicate()
	empty.clear()
	assert_failure(func() -> void: assert_array(empty).is_not_empty()) \
		.is_failed() \
		.has_message("Expecting:\n must not be empty")


func test_is_same(value: Variant, _test_parameters := [
	[[0]],
	[PackedByteArray([0])],
	[PackedFloat32Array([0.0])],
	[PackedFloat64Array([0.0])],
	[PackedInt32Array([0])],
	[PackedInt64Array([0])],
	[PackedStringArray([""])],
	[PackedColorArray([Color.RED])],
	[PackedVector2Array([Vector2.ZERO])],
	[PackedVector3Array([Vector3.ZERO])],
]) -> void:
	assert_array(value).is_same(value)

	var v := GdDefaultValueDecoder.decode(value)
	assert_failure(func() -> void: assert_array(value).is_same(value.duplicate()))\
		.is_failed()\
		.has_message("""
			Expecting:
			 '%s'
			 to refer to the same object
			 '%s'"""
			.dedent()
			.trim_prefix("\n") % [v, v])


func test_is_not_same(value: Variant, _test_parameters := [
	[[0]],
	[PackedByteArray([0])],
	[PackedFloat32Array([0.0])],
	[PackedFloat64Array([0.0])],
	[PackedInt32Array([0])],
	[PackedInt64Array([0])],
	[PackedStringArray([""])],
	[PackedColorArray([Color.RED])],
	[PackedVector2Array([Vector2.ZERO])],
	[PackedVector3Array([Vector3.ZERO])],
]) -> void:
	assert_array(value).is_not_same(value.duplicate())

	assert_failure(func() -> void: assert_array(value).is_not_same(value))\
		.is_failed()\
		.has_message("Expecting not same:\n '%s'" % GdDefaultValueDecoder.decode(value))


func test_has_size(_test: String, array: Variant, _test_parameters := [
	["Array", Array([1, 2, 3, 4, 5])],
	["PackedByteArray", PackedByteArray([1, 2, 3, 4, 5])],
	["PackedInt32Array", PackedInt32Array([1, 2, 3, 4, 5])],
	["PackedInt64Array", PackedInt64Array([1, 2, 3, 4, 5])],
	["PackedFloat32Array", PackedFloat32Array([1, 2, 3, 4, 5])],
	["PackedFloat64Array", PackedFloat64Array([1, 2, 3, 4, 5])],
	["PackedStringArray", PackedStringArray([1, 2, 3, 4, 5])],
	["PackedVector2Array", PackedVector2Array([Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])],
	["PackedVector3Array", PackedVector3Array([Vector3.ZERO, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN])],
	["PackedColorArray", PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.BLACK])] ]
	) -> void:

	assert_array(array).has_size(5)
	# should fail because the array has a size of 5
	assert_failure(func() -> void: assert_array(array).has_size(4)) \
		.is_failed() \
		.has_message("""
			Expecting size:
			 4
			 but was
			 5"""
			.dedent()
			.trim_prefix("\n"))


func test_contains(_test: String, array: Variant, _test_parameters := [
	["Array", Array([1, 2, 3, 4, 5])],
	["PackedByteArray", PackedByteArray([1, 2, 3, 4, 5])],
	["PackedInt32Array", PackedInt32Array([1, 2, 3, 4, 5])],
	["PackedInt64Array", PackedInt64Array([1, 2, 3, 4, 5])],
	["PackedFloat32Array", PackedFloat32Array([1, 2, 3, 4, 5])],
	["PackedFloat64Array", PackedFloat64Array([1, 2, 3, 4, 5])],
	["PackedStringArray", PackedStringArray([1, 2, 3, 4, 5])],
	["PackedVector2Array", PackedVector2Array([Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])],
	["PackedVector3Array", PackedVector3Array([Vector3.ZERO, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN])],
	["PackedColorArray", PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.BLACK])] ]
	) -> void:

	assert_array(array).contains([array[1], array[3], array[4]])
	# should fail because the array not contains 7 and 6
	var do_contains := [array[1], 7, 6]
	assert_failure(func() -> void: assert_array(array).contains(do_contains)) \
		.is_failed() \
		.has_message("""
			Expecting contains elements:
			 '$source'
			 do contains (in any order)
			 '$contains'
			but could not find elements:
			 '[7, 6]'"""
			.dedent()
			.trim_prefix("\n")
			.replace("$source", GdDefaultValueDecoder.decode(array))
			.replace("$contains", GdDefaultValueDecoder.decode(do_contains))
		)


func test_contains_exactly(_test: String, array: Variant, _test_parameters := [
	["Array", Array([1, 2, 3, 4, 5])],
	["PackedByteArray", PackedByteArray([1, 2, 3, 4, 5])],
	["PackedInt32Array", PackedInt32Array([1, 2, 3, 4, 5])],
	["PackedInt64Array", PackedInt64Array([1, 2, 3, 4, 5])],
	["PackedFloat32Array", PackedFloat32Array([1, 2, 3, 4, 5])],
	["PackedFloat64Array", PackedFloat64Array([1, 2, 3, 4, 5])],
	["PackedStringArray", PackedStringArray([1, 2, 3, 4, 5])],
	["PackedVector2Array", PackedVector2Array([Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN])],
	["PackedVector3Array", PackedVector3Array([Vector3.ZERO, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN])],
	["PackedColorArray", PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.BLACK])] ]
	) -> void:

	assert_array(array).contains_exactly(array.duplicate())
	# should fail because the array not contains same elements but in different order
	var shuffled :Variant = array.duplicate()
	shuffled[1] = array[3]
	shuffled[3] = array[1]
	assert_failure(func() -> void: assert_array(array).contains_exactly(shuffled)) \
		.is_failed() \
		.has_message("""
			Expecting contains exactly elements:
			 '$source'
			 do contains (in same order)
			 '$contains'
			 but has different order at position 1
			 '$A' vs '$B'"""
			.dedent()
			.trim_prefix("\n")
			.replace("$A", GdDefaultValueDecoder.decode(array[1]))
			.replace("$B", GdDefaultValueDecoder.decode(array[3]))
			.replace("$source", GdDefaultValueDecoder.decode(array))
			.replace("$contains", GdDefaultValueDecoder.decode(shuffled))
		)


func test_override_failure_message(_test: String, array: Variant, _test_parameters := [
	["Array", Array()],
	["PackedByteArray", PackedByteArray()],
	["PackedInt32Array", PackedInt32Array()],
	["PackedInt64Array", PackedInt64Array()],
	["PackedFloat32Array", PackedFloat32Array()],
	["PackedFloat64Array", PackedFloat64Array()],
	["PackedStringArray", PackedStringArray()],
	["PackedVector2Array", PackedVector2Array()],
	["PackedVector3Array", PackedVector3Array()],
	["PackedColorArray", PackedColorArray()] ]
	) -> void:

	assert_object(assert_array(array).override_failure_message("error")).is_instanceof(GdUnitArrayAssert)
	assert_failure(func() -> void: assert_array(array) \
			.override_failure_message("Custom failure message") \
			.is_null()) \
		.is_failed() \
		.has_message("Custom failure message")


func test_append_failure_message() -> void:
	assert_object(assert_array([]).append_failure_message("error")).is_instanceof(GdUnitArrayAssert)
	assert_failure(func() -> void: assert_array([]) \
			.append_failure_message("custom failure data") \
			.is_not_empty()) \
		.is_failed() \
		.has_message("""
			Expecting:
			 must not be empty
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))
