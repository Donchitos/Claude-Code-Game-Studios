class_name  ClassWithBasicTypeBoolDefaultArguments
extends RefCounted


func on_bool_case1(value: bool) -> bool:
	return value


func on_bool_case2(value: bool = true) -> bool:
	return value


func on_bool_case3(value := true) -> bool:
	return value
