# base interface for assert value provider
class_name ValueProvider
extends RefCounted

func get_value() -> Variant:
	return null


func dispose() -> void:
	pass
