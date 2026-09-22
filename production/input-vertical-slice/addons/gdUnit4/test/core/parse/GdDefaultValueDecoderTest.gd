# GdUnit generated TestSuite
class_name GdDefaultValueDecoderTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/parse/GdDefaultValueDecoder.gd'


var _tested_types := {}


func after() -> void:
	# we verify we have covered all variant types
	for type_id in TYPE_MAX:
		if type_id == TYPE_OBJECT:
			continue
		@warning_ignore("unsafe_method_access")
		assert_that(_tested_types.get(type_id))\
			.override_failure_message("Missing Variant type '%s'" % GdObjects.type_as_string(type_id))\
			.is_not_null()


func test_decode_Primitives(variant_type: int, value: Variant, expected: String, _test_parameters := [
	[TYPE_NIL, null, "null"],
	[TYPE_BOOL, true, "true"],
	[TYPE_BOOL, false, "false"],
	[TYPE_INT, -100, "-100"],
	[TYPE_INT, 0, "0"],
	[TYPE_INT, 100, "100"],
	[TYPE_FLOAT, -100.123, "-100.123000"],
	[TYPE_FLOAT, 0.00, "0.000000"],
	[TYPE_FLOAT, 100, "100.000000"],
	[TYPE_FLOAT, 100.123, "100.123000"],
	[TYPE_STRING, "hello", '"hello"'],
	[TYPE_STRING, "", '""'],
	[TYPE_STRING_NAME, StringName("hello"), 'StringName("hello")'],
	[TYPE_STRING_NAME, StringName(""), 'StringName()'],
	]) -> void:

	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Vectors(variant_type: int, value: Variant, expected: String, _test_parameters := [
	[TYPE_VECTOR2, Vector2(), "Vector2()"],
	[TYPE_VECTOR2, Vector2(1,2), "Vector2" + str(Vector2(1, 2))],
	[TYPE_VECTOR2I, Vector2i(), "Vector2i()"],
	[TYPE_VECTOR2I, Vector2i(1,2), "Vector2i(1, 2)"],
	[TYPE_VECTOR3, Vector3(), "Vector3()"],
	[TYPE_VECTOR3, Vector3(1,2,3), "Vector3" +str(Vector3(1, 2, 3))],
	[TYPE_VECTOR3I, Vector3i(), "Vector3i()"],
	[TYPE_VECTOR3I, Vector3i(1,2,3), "Vector3i(1, 2, 3)"],
	[TYPE_VECTOR4, Vector4(), "Vector4()"],
	[TYPE_VECTOR4, Vector4(1,2,3,4), "Vector4" + str(Vector4(1, 2, 3, 4))],
	[TYPE_VECTOR4I, Vector4i(), "Vector4i()"],
	[TYPE_VECTOR4I, Vector4i(1,2,3,4), "Vector4i(1, 2, 3, 4)"],
	]) -> void:

	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Rect2(variant_type: int, value: Variant, expected: String, _test_parameters := [
	[TYPE_RECT2, Rect2(), "Rect2()"],
	[TYPE_RECT2, Rect2(1,2, 10,20), "Rect2(Vector2"+str(Vector2(1, 2))+", Vector2"+str(Vector2(10, 20))+")"],
	[TYPE_RECT2I, Rect2i(), "Rect2i()"],
	[TYPE_RECT2I, Rect2i(1,2, 10,20), "Rect2i(Vector2i(1, 2), Vector2i(10, 20))"],
	]) -> void:

	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Transforms(variant_type: int, value: Variant, expected: String, _test_parameters := [
	[TYPE_TRANSFORM2D, Transform2D(),
		"Transform2D()"],
	[TYPE_TRANSFORM2D, Transform2D(2.0, Vector2(1,2)),
		"Transform2D(Vector2(-0.416147, 0.909297), Vector2(-0.909297, -0.416147), Vector2"+str(Vector2(1, 2))+")"],
	[TYPE_TRANSFORM2D, Transform2D(2.0, Vector2(1,2), 2.0, Vector2(3,4)),
		"Transform2D(Vector2(-0.416147, 0.909297), Vector2(1.513605, -1.307287), Vector2"+str(Vector2(3, 4))+")"],
	[TYPE_TRANSFORM2D, Transform2D(Vector2(1,2), Vector2(3,4), Vector2.ONE),
		"Transform2D(Vector2"+str(Vector2(1, 2))+", Vector2"+str(Vector2(3, 4))+", Vector2"+str(Vector2(1, 1))+")"],
	[TYPE_TRANSFORM3D, Transform3D(),
		"Transform3D()"],
	[TYPE_TRANSFORM3D, Transform3D(Basis.FLIP_X, Vector3.ONE),
		"Transform3D(Vector3"+str(Vector3(-1, 0, 0))+", Vector3"+str(Vector3(0, 1, 0))
		+", Vector3"+str(Vector3(0, 0, 1))+", Vector3"+str(Vector3(1, 1, 1))+")"],
	[TYPE_TRANSFORM3D, Transform3D(Vector3(1,2,3), Vector3(4,5,6), Vector3(7,8,9), Vector3.ONE),
		"Transform3D(Vector3"+str(Vector3(1, 2, 3))+", Vector3"+str(Vector3(4, 5, 6))
		+", Vector3"+str(Vector3(7, 8, 9))+", Vector3"+str(Vector3(1, 1, 1))+")"],
	[TYPE_PROJECTION, Projection(), "Projection(Vector4%s, Vector4%s, Vector4%s, Vector4%s)"
		 % [Vector4(1, 0, 0, 0), Vector4(0, 1, 0, 0), Vector4(0, 0, 1, 0), Vector4(0, 0, 0, 1)]],
	[TYPE_PROJECTION, Projection(Vector4.ONE, Vector4.ONE*2, Vector4.ONE*3, Vector4.ZERO),
		"Projection(Vector4%s, Vector4%s, Vector4%s, Vector4%s)" %
		[Vector4.ONE, Vector4.ONE*2, Vector4.ONE*3, Vector4.ZERO]]
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Plane(variant_type: int, value: Plane, expected: String, _test_parameters := [
	[TYPE_PLANE, Plane(), "Plane()"],
	[TYPE_PLANE, Plane(1,2,3,4), "Plane(1, 2, 3, 4)"],
	[TYPE_PLANE, Plane(Vector3.ONE, Vector3.ZERO), "Plane(1, 1, 1, 0)"],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Quaternion(variant_type: int, value: Quaternion, expected: String, _test_parameters := [
	[TYPE_QUATERNION, Quaternion(), "Quaternion()"],
	[TYPE_QUATERNION, Quaternion(1,2,3,4), "Quaternion(1, 2, 3, 4)"],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_AABB(variant_type: int, value: AABB, expected: String, _test_parameters := [
	[TYPE_AABB, AABB(), "AABB()"],
	[TYPE_AABB, AABB(Vector3.ONE, Vector3(10,20,30)), "AABB(Vector3"+str(Vector3(1, 1, 1))+", Vector3"+str(Vector3(10, 20, 30))+")"],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Basis(variant_type: int, value: Basis, expected: String, _test_parameters := [
	[TYPE_BASIS, Basis(), "Basis()"],
	[TYPE_BASIS, Basis(Vector3(0.1,0.2,0.3).normalized(), .1),
		"Basis(Vector3(0.995361, 0.080758, -0.052293), Vector3(-0.079331, 0.996432, 0.028823), Vector3(0.054434, -0.024541, 0.998216))"],
	[TYPE_BASIS, Basis(Vector3.ONE, Vector3.ONE*2, Vector3.ONE*3),
		"Basis(Vector3"+str(Vector3(1, 1, 1))+", Vector3"+str(Vector3(2, 2, 2))+", Vector3"+str(Vector3(3, 3, 3))+")"],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Color(variant_type: int, value: Color, expected: String, _test_parameters := [
	[TYPE_COLOR, Color(), "Color()"],
	[TYPE_COLOR, Color.RED, "Color"+str(Color(1, 0, 0, 1))],
	[TYPE_COLOR, Color(1,.2,.5,.5), "Color"+str(Color(1, 0.2, 0.5, 0.5))],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_NodePath(variant_type: int, value: NodePath, expected: String, _test_parameters := [
	[TYPE_NODE_PATH, NodePath(), 'NodePath()'],
	[TYPE_NODE_PATH, NodePath("/foo/bar"), 'NodePath("/foo/bar")'],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_RID(variant_type: int, value: RID, expected: String, _test_parameters := [
	[TYPE_RID, RID(), 'RID()'],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func _test_decode_Object(variant_type: int, value: Node, expected: String, _test_parameters := [
	[TYPE_OBJECT, Node.new(), 'Node.new()'],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Callable(variant_type: int, value: Callable, expected: String, _test_parameters := [
	[TYPE_CALLABLE, Callable(), 'Callable()'],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Signal(variant_type: int, value: Signal, expected: String, _test_parameters := [
	[TYPE_SIGNAL, Signal(), 'Signal()'],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Dictionary(variant_type: int, value: Dictionary, expected: String, _test_parameters := [
	[TYPE_DICTIONARY, {}, '{}'],
	[TYPE_DICTIONARY, Dictionary(), '{}'],
	[TYPE_DICTIONARY, {1:2, 2:3}, '{ 1: 2, 2: 3 }'],
	[TYPE_DICTIONARY, {"aa":2, "bb":"cc"}, '{ "aa": 2, "bb": "cc" }'],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_Array(variant_type: int, value: Array, expected: String, _test_parameters := [
	[TYPE_ARRAY, [], '[]'],
	[TYPE_ARRAY, Array(), '[]'],
	[TYPE_ARRAY, [1,2,3], '[1, 2, 3]'],
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1


func test_decode_typedArrays(variant_type: int, value: Variant, expected: String, _test_parameters := [
	[TYPE_PACKED_BYTE_ARRAY, PackedByteArray(),
		'PackedByteArray()'],
	[TYPE_PACKED_BYTE_ARRAY, PackedByteArray([1, 2, 3]),
		'PackedByteArray([1, 2, 3])'],
	[TYPE_PACKED_COLOR_ARRAY, PackedColorArray(),
		'PackedColorArray()'],
	[TYPE_PACKED_COLOR_ARRAY, PackedColorArray([Color.RED, Color.BLUE]),
		'PackedColorArray([Color'+str(Color(1, 0, 0, 1))+', Color'+str(Color(0, 0, 1, 1))+'])'],
	[TYPE_PACKED_FLOAT32_ARRAY, PackedFloat32Array(),
		'PackedFloat32Array()'],
	[TYPE_PACKED_FLOAT32_ARRAY, PackedFloat32Array([1.2, 2.3]),
		'PackedFloat32Array([1.20000004768372, 2.29999995231628])'],
	[TYPE_PACKED_FLOAT64_ARRAY, PackedFloat64Array(),
		'PackedFloat64Array()'],
	[TYPE_PACKED_FLOAT64_ARRAY, PackedFloat64Array([1.2, 2.3]),
		'PackedFloat64Array([1.2, 2.3])'],
	[TYPE_PACKED_INT32_ARRAY, PackedInt32Array(),
		'PackedInt32Array()'],
	[TYPE_PACKED_INT32_ARRAY, PackedInt32Array([1, 2]),
		'PackedInt32Array([1, 2])'],
	[TYPE_PACKED_INT64_ARRAY, PackedInt64Array(),
		'PackedInt64Array()'],
	[TYPE_PACKED_INT64_ARRAY, PackedInt64Array([1, 2]),
		'PackedInt64Array([1, 2])'],
	[TYPE_PACKED_STRING_ARRAY, PackedStringArray(),
		'PackedStringArray()'],
	[TYPE_PACKED_STRING_ARRAY, PackedStringArray(["aa", "bb"]),
		'PackedStringArray(["aa", "bb"])'],
	[TYPE_PACKED_VECTOR2_ARRAY, PackedVector2Array(),
		'PackedVector2Array()'],
	[TYPE_PACKED_VECTOR2_ARRAY, PackedVector2Array([Vector2.ONE, Vector2.ONE*2]),
		'PackedVector2Array([Vector2'+str(Vector2.ONE)+', Vector2'+str(Vector2.ONE*2)+'])'],
	[TYPE_PACKED_VECTOR3_ARRAY, PackedVector3Array(),
		'PackedVector3Array()'],
	[TYPE_PACKED_VECTOR3_ARRAY, PackedVector3Array([Vector3.ONE, Vector3.ONE*2]),
		'PackedVector3Array([Vector3'+str(Vector3.ONE)+', Vector3'+str(Vector3.ONE*2)+'])'],
	[TYPE_PACKED_VECTOR4_ARRAY, PackedVector4Array(),
		'PackedVector4Array()'],
	[TYPE_PACKED_VECTOR4_ARRAY, PackedVector4Array([Vector4.ONE, Vector4.ONE*2]),
		'PackedVector4Array([Vector4'+str(Vector4.ONE)+', Vector4'+str(Vector4.ONE*2)+'])']
	]) -> void:
	assert_that(GdDefaultValueDecoder.decode_typed(variant_type, value)).is_equal(expected)
	_tested_types[variant_type] = 1
