class_name  ClassWithBasicTypeStringDefaultArguments
extends RefCounted


func on_string_case1(value: String) -> String:
	return value


func on_string_case2(value: String = "foo") -> String:
	return value


func on_string_case3(value := "foo") -> String:
	return value
