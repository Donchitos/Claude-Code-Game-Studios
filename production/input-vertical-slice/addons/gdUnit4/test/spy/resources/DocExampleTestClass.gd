# The class 'TestClass' used by the examples of the spy documentation page
# documentation/doc/_advanced_testing/spy.md
extends Node

var _value: int


func message() -> String:
	return "a message"


func set_value(value: int) -> void:
	_value = value
