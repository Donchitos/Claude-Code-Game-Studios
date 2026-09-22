class_name  ClassWithBasicTypeVector4DefaultArguments
extends RefCounted


func on_vector4_case1(value: Vector4) -> Vector4:
	return value


func on_vector4_case2(value: Vector4 = Vector4.ONE) -> Vector4:
	return value


func on_vector4_case3(value := Vector4.ONE) -> Vector4:
	return value
