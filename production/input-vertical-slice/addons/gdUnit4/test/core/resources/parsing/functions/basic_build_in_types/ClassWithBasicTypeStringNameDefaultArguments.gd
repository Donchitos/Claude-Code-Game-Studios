class_name  ClassWithBasicTypeStringNameDefaultArguments
extends RefCounted


func on_string_name_case1(value: StringName) -> StringName:
	return value


func on_string_name_case2(value: StringName = &"foo") -> StringName:
	return value


func on_string_name_case3(value := &"foo") -> StringName:
	return value
