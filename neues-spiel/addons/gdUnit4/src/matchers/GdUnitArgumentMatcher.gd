## The base class of all argument matchers
class_name GdUnitArgumentMatcher
extends RefCounted


@warning_ignore("unused_parameter")
func is_match(value: Variant) -> bool:
	return true


func _to_string() -> String:
	assert(false, "`_to_string()` Is not implemented!")
	return ""
