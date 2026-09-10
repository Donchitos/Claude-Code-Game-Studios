# GdUnit generated TestSuite
class_name GdArrayToolsTest
extends GdUnitTestSuite


# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdArrayTools.gd'


func test_as_string(_test: String, value: Variant, expected: String, _test_parameters := [
	['Array', Array([1, 2]), '[1, 2]'],
	['Array', Array([1.0, 2.212]), '[1.000000, 2.212000]'],
	['Array', Array([true, false]), '[true, false]'],
	['Array', Array(["1", "2"]), '["1", "2"]'],
	['Array', Array([Vector2.ZERO, Vector2.LEFT]), '[Vector2(), Vector2'+str(Vector2(-1, 0))+']'],
	['Array', Array([Vector3.ZERO, Vector3.LEFT]), '[Vector3(), Vector3'+str(Vector3(-1, 0, 0))+']'],
	['Array', Array([Color.RED, Color.GREEN]), '[Color'+str(Color(1, 0, 0, 1))+', Color'+str(Color(0, 1, 0, 1))+']'],
	['ArrayInt', Array([1, 2]) as Array[int], '[1, 2]'],
	['ArrayFloat', Array([1.0, 2.212]) as Array[float], '[1.000000, 2.212000]'],
	['ArrayBool', Array([true, false]) as Array[bool], '[true, false]'],
	['ArrayString', Array(["1", "2"]) as Array[String], '["1", "2"]'],
	['ArrayVector2', Array([Vector2.ZERO, Vector2.LEFT]) as Array[Vector2], '[Vector2(), Vector2'+str(Vector2(-1, 0))+']'],
	['ArrayVector2i', Array([Vector2i.ZERO, Vector2i.LEFT]) as Array[Vector2i], '[Vector2i(), Vector2i'+str(Vector2i(-1, 0))+']'],
	['ArrayVector3', Array([Vector3.ZERO, Vector3.LEFT]) as Array[Vector3], '[Vector3(), Vector3'+str(Vector3(-1, 0, 0))+']'],
	['ArrayVector3i', Array([Vector3i.ZERO, Vector3i.LEFT]) as Array[Vector3i], '[Vector3i(), Vector3i'+str(Vector3i(-1, 0, 0))+']'],
	['ArrayVector4', Array([Vector4.ZERO, Vector4.ONE]) as Array[Vector4], '[Vector4(), Vector4%s]' % Vector4(1, 1, 1, 1)],
	['ArrayVector4i', Array([Vector4i.ZERO, Vector4i.ONE]) as Array[Vector4i], '[Vector4i(), Vector4i(1, 1, 1, 1)]'],
	['ArrayColor', Array([Color.RED, Color.GREEN]) as Array[Color], '[Color'+str(Color(1, 0, 0, 1))+', Color'+str(Color(0, 1, 0, 1))+']'],
	['PackedByteArray', PackedByteArray([1, 2]), 'PackedByteArray[1, 2]'],
	['PackedInt32Array', PackedInt32Array([1, 2]), 'PackedInt32Array[1, 2]'],
	['PackedInt64Array', PackedInt64Array([1, 2]), 'PackedInt64Array[1, 2]'],
	['PackedFloat32Array', PackedFloat32Array([1, 2.212]), 'PackedFloat32Array[1.000000, 2.212000]'],
	['PackedFloat64Array', PackedFloat64Array([1, 2.212]), 'PackedFloat64Array[1.000000, 2.212000]'],
	['PackedStringArray', PackedStringArray([1, 2]), 'PackedStringArray["1", "2"]'],
	['PackedVector2Array', PackedVector2Array([Vector2.ZERO, Vector2.LEFT]), 'PackedVector2Array[Vector2(), Vector2'+str(Vector2(-1, 0))+']'],
	['PackedVector3Array', PackedVector3Array([Vector3.ZERO, Vector3.LEFT]), 'PackedVector3Array[Vector3(), Vector3'+str(Vector3(-1, 0, 0))+']'],
	['PackedColorArray', PackedColorArray([Color.RED, Color.GREEN]), 'PackedColorArray[Color'+str(Color(1, 0, 0, 1))+', Color'+str(Color(0, 1, 0, 1))+']'],
]) -> void:

	assert_that(GdArrayTools.as_string(value)).is_equal(expected)


func test_as_string_simple_format() -> void:
	var value := PackedStringArray(["a", "b"])

	assert_that(GdArrayTools.as_string(value, false)).is_equal('[a, b]')


func test_is_array_type(_test: String, value: Variant, expected: bool, _test_parameters := [
	['bool', true, false],
	['int', 42, false],
	['float', 1.21, false],
	['String', "abc", false],
	['Dictionary', {}, false],
	['RefCounted', RefCounted.new(), false],
	['Array', Array([1, 2]), true],
	['Array', Array([1.0, 2.212]), true],
	['Array', Array([true, false]), true],
	['Array', Array(["1", "2"]), true],
	['Array', Array([Vector2.ZERO, Vector2.LEFT]), true],
	['Array', Array([Vector3.ZERO, Vector3.LEFT]), true],
	['Array', Array([Color.RED, Color.GREEN]), true],
	['ArrayInt', Array([1, 2]) as Array[int], true],
	['ArrayFloat', Array([1.0, 2.212]) as Array[float], true],
	['ArrayBool', Array([true, false]) as Array[bool], true],
	['ArrayString', Array(["1", "2"]) as Array[String], true],
	['ArrayVector2', Array([Vector2.ZERO, Vector2.LEFT]) as Array[Vector2], true],
	['ArrayVector2i', Array([Vector2i.ZERO, Vector2i.LEFT]) as Array[Vector2i], true],
	['ArrayVector3', Array([Vector3.ZERO, Vector3.LEFT]) as Array[Vector3], true],
	['ArrayVector3i', Array([Vector3i.ZERO, Vector3i.LEFT]) as Array[Vector3i], true],
	['ArrayVector4', Array([Vector4.ZERO, Vector4.ONE]) as Array[Vector4], true],
	['ArrayVector4i', Array([Vector4i.ZERO, Vector4i.ONE]) as Array[Vector4i], true],
	['ArrayColor', Array([Color.RED, Color.GREEN]) as Array[Color], true],
	['PackedByteArray', PackedByteArray([1, 2]), true],
	['PackedInt32Array', PackedInt32Array([1, 2]), true],
	['PackedInt64Array', PackedInt64Array([1, 2]), true],
	['PackedFloat32Array', PackedFloat32Array([1, 2.212]), true],
	['PackedFloat64Array', PackedFloat64Array([1, 2.212]), true],
	['PackedStringArray', PackedStringArray([1, 2]), true],
	['PackedVector2Array', PackedVector2Array([Vector2.ZERO, Vector2.LEFT]), true],
	['PackedVector3Array', PackedVector3Array([Vector3.ZERO, Vector3.LEFT]), true],
	['PackedColorArray', PackedColorArray([Color.RED, Color.GREEN]), true],
]) -> void:

	assert_that(GdArrayTools.is_array_type(value)).is_equal(expected)


func test_is_type_array() -> void:
	for type :int in [TYPE_NIL, TYPE_MAX]:
		if type in [TYPE_ARRAY, TYPE_PACKED_COLOR_ARRAY]:
			assert_bool(GdArrayTools.is_type_array(type)).is_true()
		else:
			assert_bool(GdArrayTools.is_type_array(type)).is_false()


func test_filter_value(value: Variant, expected_type: int, _test_parameters := [
	[[1, 2, 3, 1], TYPE_ARRAY],
	[Array([1, 2, 3, 1], TYPE_INT, "", null), TYPE_ARRAY],
	[PackedByteArray([1, 2, 3, 1]), TYPE_PACKED_BYTE_ARRAY],
	[PackedInt32Array([1, 2, 3, 1]), TYPE_PACKED_INT32_ARRAY],
	[PackedInt64Array([1, 2, 3, 1]), TYPE_PACKED_INT64_ARRAY],
	[PackedFloat32Array([1.0, 2, 1.1, 1.0]), TYPE_PACKED_FLOAT32_ARRAY],
	[PackedFloat64Array([1.0, 2, 1.1, 1.0]), TYPE_PACKED_FLOAT64_ARRAY],
	[PackedStringArray(["1", "2", "3", "1"]), TYPE_PACKED_STRING_ARRAY],
	[PackedVector2Array([Vector2.ZERO, Vector2.ONE, Vector2.DOWN, Vector2.ZERO]), TYPE_PACKED_VECTOR2_ARRAY],
	[PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3.DOWN, Vector3.ZERO]), TYPE_PACKED_VECTOR3_ARRAY],
	[PackedColorArray([Color.RED, Color.GREEN, Color.BLUE, Color.RED]), TYPE_PACKED_COLOR_ARRAY]
	]) -> void:

	var value_to_remove :Variant = value[0]
	var result :Variant = GdArrayTools.filter_value(value, value_to_remove)
	assert_array(result).not_contains([value_to_remove]).has_size(2)
	assert_that(typeof(result)).is_equal(expected_type)


func test_filter_value_() -> void:
	assert_array(GdArrayTools.filter_value([], null)).is_empty()
	assert_array(GdArrayTools.filter_value([], "")).is_empty()

	var current :Array = [null, "a", "b", null, "c", null]
	var filtered :Variant= GdArrayTools.filter_value(current, null)
	assert_array(filtered).contains_exactly(["a", "b", "c"])
	# verify the source is not affected
	assert_array(current).contains_exactly([null, "a", "b", null, "c", null])

	current = [null, "a", "xxx", null, "xx", null]
	filtered = GdArrayTools.filter_value(current, "xxx")
	assert_array(filtered).contains_exactly([null, "a", null, "xx", null])
	# verify the source is not affected
	assert_array(current).contains_exactly([null, "a", "xxx", null, "xx", null])


func test_erase_value() -> void:
	var current := []
	GdArrayTools.erase_value(current, null)
	assert_array(current).is_empty()

	current = [null]
	GdArrayTools.erase_value(current, null)
	assert_array(current).is_empty()

	current = [null, "a", "b", null, "c", null]
	GdArrayTools.erase_value(current, null)
	# verify the source is affected
	assert_array(current).contains_exactly(["a", "b", "c"])


func test_scan_typed() -> void:
	assert_that(GdArrayTools.scan_typed([1, 2, 3])).is_equal(TYPE_INT)
	assert_that(GdArrayTools.scan_typed([1, 2.2, 3])).is_equal(GdObjects.TYPE_VARIANT)


class ExampleItem:
	var _name: String
	var _type: int

	func _init(name: String, type: int) -> void:
		_name = name
		_type = type


func test_group_by() -> void:
	var values := [
		ExampleItem.new("foo1", 0),
		ExampleItem.new("foo2", 0),
		ExampleItem.new("bar1", 1),
		ExampleItem.new("bar2", 1),
		ExampleItem.new("foo3", 0),
		ExampleItem.new("foo3", 1),
		ExampleItem.new("xxx", 2),
	]

	# We group by type
	var result := GdArrayTools.group_by(values, func(item: ExampleItem) -> int:
		return item._type
	)

	# Verify grouping result
	assert_dict(result).has_size(3)\
		.contains_key_value(0, [values[0], values[1], values[4]])\
		.contains_key_value(1, [values[2], values[3], values[5]])\
		.contains_key_value(2, [values[6]])\
