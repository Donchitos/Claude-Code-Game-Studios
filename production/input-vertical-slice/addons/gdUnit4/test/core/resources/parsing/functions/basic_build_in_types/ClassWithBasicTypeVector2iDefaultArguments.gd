class_name  ClassWithBasicTypeVector2iDefaultArguments
extends RefCounted


func on_vector2i_case1(value: Vector2i) -> Vector2i:
	return value


func on_vector2i_case2(value: Vector2i = Vector2i.ONE) -> Vector2i:
	return value


func on_vector2i_case3(value := Vector2i.ONE) -> Vector2i:
	return value
