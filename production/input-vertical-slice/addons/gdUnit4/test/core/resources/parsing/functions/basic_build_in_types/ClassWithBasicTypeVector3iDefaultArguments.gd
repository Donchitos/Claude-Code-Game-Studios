class_name  ClassWithBasicTypeVector3iDefaultArguments
extends RefCounted


func on_vector3i_case1(value: Vector3i) -> Vector3i:
	return value


func on_vector3i_case2(value: Vector3i = Vector3i.ONE) -> Vector3i:
	return value


func on_vector3i_case3(value := Vector3i.ONE) -> Vector3i:
	return value
