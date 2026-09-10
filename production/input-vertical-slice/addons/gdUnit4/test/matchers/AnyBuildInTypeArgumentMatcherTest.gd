# GdUnit generated TestSuite
class_name AnyBuildInTypeArgumentMatcherTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/matchers/AnyBuildInTypeArgumentMatcher.gd'


func test_is_match_bool() -> void:
	assert_object(any_bool()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_bool()
	assert_bool(matcher.is_match(true)).is_true()
	assert_bool(matcher.is_match(false)).is_true()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(0.2)).is_false()
	assert_bool(matcher.is_match(auto_free(Node.new()))).is_false()


func test_is_match_int() -> void:
	assert_object(any_int()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_int()
	assert_bool(matcher.is_match(0)).is_true()
	assert_bool(matcher.is_match(1000)).is_true()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match([])).is_false()
	assert_bool(matcher.is_match(0.2)).is_false()
	assert_bool(matcher.is_match(auto_free(Node.new()))).is_false()


func test_is_match_float() -> void:
	assert_object(any_float()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_float()
	assert_bool(matcher.is_match(.0)).is_true()
	assert_bool(matcher.is_match(0.0)).is_true()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match([])).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(auto_free(Node.new()))).is_false()


func test_is_match_string() -> void:
	assert_object(any_string()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_string()
	assert_bool(matcher.is_match("")).is_true()
	assert_bool(matcher.is_match("abc")).is_true()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match([])).is_false()
	assert_bool(matcher.is_match(0.2)).is_false()
	assert_bool(matcher.is_match(auto_free(Node.new()))).is_false()


func test_is_match_color() -> void:
	assert_object(any_color()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_color()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match("abc")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(Color.ALICE_BLUE)).is_true()
	assert_bool(matcher.is_match(Color.RED)).is_true()


func test_is_match_vector() -> void:
	assert_object(any_vector()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_vector()
	assert_bool(matcher.is_match(Vector2.ONE)).is_true()
	assert_bool(matcher.is_match(Vector2i.ONE)).is_true()
	assert_bool(matcher.is_match(Vector3.ONE)).is_true()
	assert_bool(matcher.is_match(Vector3i.ONE)).is_true()
	assert_bool(matcher.is_match(Vector4.ONE)).is_true()
	assert_bool(matcher.is_match(Vector4i.ONE)).is_true()

	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match("abc")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()


func test_is_match_vector2() -> void:
	assert_object(any_vector2()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_vector2()
	assert_bool(matcher.is_match(Vector2.ONE)).is_true()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match("abc")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(Vector2i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4i.ONE)).is_false()


func test_is_match_vector2i() -> void:
	assert_object(any_vector2i()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_vector2i()
	assert_bool(matcher.is_match(Vector2i.ONE)).is_true()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match("abc")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(Vector2.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4i.ONE)).is_false()


func test_is_match_vector3() -> void:
	assert_object(any_vector3()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_vector3()
	assert_bool(matcher.is_match(Vector3.ONE)).is_true()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match("abc")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(Vector2.ONE)).is_false()
	assert_bool(matcher.is_match(Vector2i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4i.ONE)).is_false()


func test_is_match_vector3i() -> void:
	assert_object(any_vector3i()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_vector3i()
	assert_bool(matcher.is_match(Vector3i.ONE)).is_true()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match("abc")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(Vector2.ONE)).is_false()
	assert_bool(matcher.is_match(Vector2i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4i.ONE)).is_false()


func test_is_match_vector4() -> void:
	assert_object(any_vector4()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_vector4()
	assert_bool(matcher.is_match(Vector4.ONE)).is_true()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match("abc")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(Vector2.ONE)).is_false()
	assert_bool(matcher.is_match(Vector2i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4i.ONE)).is_false()


func test_is_match_vector4i() -> void:
	assert_object(any_vector4i()).is_instanceof(AnyBuildInTypeArgumentMatcher)

	var matcher := any_vector4i()
	assert_bool(matcher.is_match(Vector4i.ONE)).is_true()
	assert_bool(matcher.is_match("")).is_false()
	assert_bool(matcher.is_match("abc")).is_false()
	assert_bool(matcher.is_match(0)).is_false()
	assert_bool(matcher.is_match(1000)).is_false()
	assert_bool(matcher.is_match(null)).is_false()
	assert_bool(matcher.is_match(Vector2.ONE)).is_false()
	assert_bool(matcher.is_match(Vector2i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3.ONE)).is_false()
	assert_bool(matcher.is_match(Vector3i.ONE)).is_false()
	assert_bool(matcher.is_match(Vector4.ONE)).is_false()


func test_to_string() -> void:
	assert_str(str(any_bool())).is_equal("any_bool()")
	assert_str(str(any_int())).is_equal("any_int()")
	assert_str(str(any_float())).is_equal("any_float()")
	assert_str(str(any_string())).is_equal("any_string()")
	assert_str(str(any_color())).is_equal("any_color()")
	assert_str(str(any_vector())).is_equal("any_vector()")
	assert_str(str(any_vector2())).is_equal("any_vector2()")
	assert_str(str(any_vector2i())).is_equal("any_vector2i()")
	assert_str(str(any_vector3())).is_equal("any_vector3()")
	assert_str(str(any_vector3i())).is_equal("any_vector3i()")
	assert_str(str(any_vector4())).is_equal("any_vector4()")
	assert_str(str(any_vector4i())).is_equal("any_vector4i()")
	assert_str(str(any_rect2())).is_equal("any_rect2()")
	assert_str(str(any_plane())).is_equal("any_plane()")
	assert_str(str(any_quat())).is_equal("any_quat()")
	assert_str(str(any_quat())).is_equal("any_quat()")
	assert_str(str(any_basis())).is_equal("any_basis()")
	assert_str(str(any_transform_2d())).is_equal("any_transform_2d()")
	assert_str(str(any_transform_3d())).is_equal("any_transform_3d()")
	assert_str(str(any_node_path())).is_equal("any_node_path()")
	assert_str(str(any_rid())).is_equal("any_rid()")
	assert_str(str(any_object())).is_equal("any_object()")
	assert_str(str(any_dictionary())).is_equal("any_dictionary()")
	assert_str(str(any_array())).is_equal("any_array()")
	assert_str(str(any_packed_byte_array())).is_equal("any_packed_byte_array()")
	assert_str(str(any_packed_int32_array())).is_equal("any_packed_int32_array()")
	assert_str(str(any_packed_int64_array())).is_equal("any_packed_int64_array()")
	assert_str(str(any_packed_float32_array())).is_equal("any_packed_float32_array()")
	assert_str(str(any_packed_float64_array())).is_equal("any_packed_float64_array()")
	assert_str(str(any_packed_string_array())).is_equal("any_packed_string_array()")
	assert_str(str(any_packed_vector2_array())).is_equal("any_packed_vector2_array()")
	assert_str(str(any_packed_vector3_array())).is_equal("any_packed_vector3_array()")
	assert_str(str(any_packed_color_array())).is_equal("any_packed_color_array()")
