class_name AnyBuildInTypeArgumentMatcher
extends GdUnitArgumentMatcher

var _type : PackedInt32Array = []


func _init(type :PackedInt32Array) -> void:
	_type = type


func is_match(value :Variant) -> bool:
	return _type.has(typeof(value))


func _to_string() -> String:
	match _type[0]:
		TYPE_BOOL: return "any_bool()"
		TYPE_STRING, TYPE_STRING_NAME: return "any_string()"
		TYPE_INT: return "any_int()"
		TYPE_FLOAT: return "any_float()"
		TYPE_COLOR: return "any_color()"
		TYPE_VECTOR2: return "any_vector2()" if _type.size() == 1 else "any_vector()"
		TYPE_VECTOR2I: return "any_vector2i()"
		TYPE_VECTOR3: return "any_vector3()"
		TYPE_VECTOR3I: return "any_vector3i()"
		TYPE_VECTOR4: return "any_vector4()"
		TYPE_VECTOR4I: return "any_vector4i()"
		TYPE_RECT2: return "any_rect2()"
		TYPE_RECT2I: return "any_rect2i()"
		TYPE_PLANE: return "any_plane()"
		TYPE_QUATERNION: return "any_quat()"
		TYPE_AABB: return "any_aabb()"
		TYPE_BASIS: return "any_basis()"
		TYPE_TRANSFORM2D: return "any_transform_2d()"
		TYPE_TRANSFORM3D: return "any_transform_3d()"
		TYPE_NODE_PATH: return "any_node_path()"
		TYPE_RID: return "any_rid()"
		TYPE_OBJECT: return "any_object()"
		TYPE_DICTIONARY: return "any_dictionary()"
		TYPE_ARRAY: return "any_array()"
		TYPE_PACKED_BYTE_ARRAY: return "any_packed_byte_array()"
		TYPE_PACKED_INT32_ARRAY: return "any_packed_int32_array()"
		TYPE_PACKED_INT64_ARRAY: return "any_packed_int64_array()"
		TYPE_PACKED_FLOAT32_ARRAY: return "any_packed_float32_array()"
		TYPE_PACKED_FLOAT64_ARRAY: return "any_packed_float64_array()"
		TYPE_PACKED_STRING_ARRAY: return "any_packed_string_array()"
		TYPE_PACKED_VECTOR2_ARRAY: return "any_packed_vector2_array()"
		TYPE_PACKED_VECTOR3_ARRAY: return "any_packed_vector3_array()"
		TYPE_PACKED_COLOR_ARRAY: return "any_packed_color_array()"
		_: return "any()"
