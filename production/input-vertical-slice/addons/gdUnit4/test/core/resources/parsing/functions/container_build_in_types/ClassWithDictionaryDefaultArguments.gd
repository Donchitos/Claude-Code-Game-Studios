class_name ClassWithDictionaryDefaultArguments
extends RefCounted


func on_dictionary_case1(dict: Dictionary = {}) -> Array:
	return dict.keys()


func on_dictionary_case2(dict := Dictionary()) -> Array:
	return dict.keys()


func on_dictionary_case3(dict := {}) -> Array:
	return dict.keys()


func on_dictionary_case4(dict := {"a":"value_a", "b":"value_b"}) -> Array:
	return dict.keys()


func on_dictionary_case5(dict := {
	"a":"value_a",
	"b":"value_b"}) -> Array:
	return dict.keys()


func on_dictionary_case6(dict := Dictionary({"a":"value_a", "b":"value_b"})) -> Array:
	return dict.keys()
