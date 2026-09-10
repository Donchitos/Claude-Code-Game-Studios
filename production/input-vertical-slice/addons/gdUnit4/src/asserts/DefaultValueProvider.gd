# default value provider, simple returns the initial value
class_name DefaultValueProvider
extends ValueProvider

var _value: Variant


func _init(value: Variant) -> void:
	_value = value


func get_value() -> Variant:
	return _value
