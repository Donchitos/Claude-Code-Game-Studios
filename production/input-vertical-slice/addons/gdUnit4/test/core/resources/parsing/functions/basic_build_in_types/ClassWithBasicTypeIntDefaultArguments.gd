class_name  ClassWithBasicTypeIntDefaultArguments
extends RefCounted


func on_int_case1(value: int) -> int:
	return value


func on_int_case2(value: int = 42) -> int:
	return value


func on_int_case3(value := 42) -> int:
	return value
