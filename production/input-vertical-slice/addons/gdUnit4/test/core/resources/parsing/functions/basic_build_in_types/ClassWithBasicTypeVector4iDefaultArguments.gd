class_name  ClassWithBasicTypeVector4iDefaultArguments
extends RefCounted


func on_vector4i_case1(value: Vector4i) -> Vector4i:
	return value


func on_vector4i_case2(value: Vector4i = Vector4i.ONE) -> Vector4i:
	return value


func on_vector4i_case3(value := Vector4i.ONE) -> Vector4i:
	return value
