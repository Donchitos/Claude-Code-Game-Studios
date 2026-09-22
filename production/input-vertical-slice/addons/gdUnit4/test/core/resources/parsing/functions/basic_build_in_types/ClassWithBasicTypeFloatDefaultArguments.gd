class_name  ClassWithBasicTypeFloatDefaultArguments
extends RefCounted


func on_float_case1(value: float) -> float:
	return value


func on_float_case2(value: float = 42.1) -> float:
	return value


func on_float_case3(value := 42.1) -> float:
	return value
