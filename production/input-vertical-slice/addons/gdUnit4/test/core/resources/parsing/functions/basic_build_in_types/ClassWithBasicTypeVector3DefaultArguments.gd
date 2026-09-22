class_name  ClassWithBasicTypeVector3DefaultArguments
extends RefCounted


func on_vector3_case1(value: Vector3) -> Vector3:
	return value


func on_vector3_case2(value: Vector3 = Vector3.ONE) -> Vector3:
	return value


func on_vector3_case3(value := Vector3.ONE) -> Vector3:
	return value
