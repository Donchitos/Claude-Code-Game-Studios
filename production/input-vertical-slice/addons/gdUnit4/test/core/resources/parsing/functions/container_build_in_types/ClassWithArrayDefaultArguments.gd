class_name ClassWithArrayDefaultArguments
extends RefCounted


func on_array_case1(values: Array = []) -> Array:
	return values


func on_array_case2(values := Array()) -> Array:
	return values


func on_array_case3(values := []) -> Array:
	return values


func on_array_case4(values := [1, "3", [], {}]) -> Array:
	return values


func on_array_case5(values := [
	1,
	"3",
	[],
	{}]) -> Array:
	return values


func on_array_case6(values := Array([1, "3", [], {}])) -> Array:
	return values


func on_packed_byte_array(values := PackedByteArray()) -> Array:
	return values


func on_packed_color_array(values := PackedColorArray()) -> Array:
	return values


func on_packed_float32_array(values := PackedFloat32Array()) -> Array:
	return values


func on_packed_float64_array(values := PackedFloat64Array()) -> Array:
	return values


func on_packed_int32_array(values := PackedInt32Array()) -> Array:
	return values


func on_packed_int64_array(values := PackedInt64Array()) -> Array:
	return values


func on_packed_string_array(values := PackedStringArray()) -> Array:
	return values


func on_packed_vector2_array(values := PackedVector2Array()) -> Array:
	return values


func on_packed_vector3_array(values := PackedVector3Array()) -> Array:
	return values


func on_packed_vector4_array(values := PackedVector4Array()) -> Array:
	return values
