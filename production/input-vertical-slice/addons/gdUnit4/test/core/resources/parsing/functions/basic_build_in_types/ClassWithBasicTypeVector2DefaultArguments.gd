class_name  ClassWithBasicTypeVector2DefaultArguments
extends RefCounted


func on_vector2_case1(value: Vector2) -> Vector2:
	return value


func on_vector2_case2(value: Vector2 = Vector2.ONE) -> Vector2:
	return value


func on_vector2_case3(value := Vector2.ONE) -> Vector2:
	return value
