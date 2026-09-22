class_name  ClassWithBasicTypeTransform2DDefaultArguments
extends RefCounted


func on_transform2d_case1(value: Transform2D) -> Transform2D:
	return value


func on_transform2d_case2(value: Transform2D = Transform2D()) -> Transform2D:
	return value


func on_transform2d_case3(value := Transform2D()) -> Transform2D:
	return value


func on_transform2d_case4(value := Transform2D(1.2, Vector2.ONE)) -> Transform2D:
	return value
