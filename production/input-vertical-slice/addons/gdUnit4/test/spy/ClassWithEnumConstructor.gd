class_name ClassWithEnumConstructor
extends RefCounted

enum MyEnumValue {
	ONE = 10,
	TWO = 20
}

var _value :MyEnumValue = MyEnumValue.ONE


# using an enum in the constructor
func _init(value :MyEnumValue, _second_parameter :PackedStringArray) -> void:
	_value = value


# using an enum as function argument
func set_value(value :MyEnumValue) -> void:
	_value = value
