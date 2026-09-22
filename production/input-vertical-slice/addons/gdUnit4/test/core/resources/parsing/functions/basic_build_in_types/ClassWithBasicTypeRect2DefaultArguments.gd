class_name  ClassWithBasicTypeRect2DefaultArguments
extends RefCounted


func on_rect2_case1(value: Rect2) -> Rect2:
	return value


func on_rect2_case2(value: Rect2 = Rect2()) -> Rect2:
	return value


func on_rect2_case3(value := Rect2()) -> Rect2:
	return value


func on_rect2_case4(value := Rect2(Vector2.ONE, Vector2.ZERO)) -> Rect2:
	return value


func on_rect2_case5(value := Rect2(0, 1, 2, 3)) -> Rect2:
	return value
