class_name GdUnitError
extends RefCounted

var _message: String
var _line_number: int
var _stack_trace: GdUnitStackTrace


func _init(message: String, line_number: int, stack_trace: GdUnitStackTrace) -> void:
	_message = message
	_line_number = line_number
	_stack_trace = stack_trace
