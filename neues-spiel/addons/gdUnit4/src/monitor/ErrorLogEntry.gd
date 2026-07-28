extends RefCounted
class_name ErrorLogEntry


enum TYPE {
	SCRIPT_ERROR,
	PUSH_ERROR,
	PUSH_WARNING
}


const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")


var _type: TYPE
var _line: int
var _message: String
var _details: String


func _init(type: TYPE, line: int, message: String, details: String) -> void:
	_type = type
	_line = line
	_message = message
	_details = details


func _to_string() -> String:
	return _message


static func of_push_warning(line: int, message: String, stack_trace: PackedStringArray) -> ErrorLogEntry:
	return ErrorLogEntry.new(TYPE.PUSH_WARNING, line, message, "\n".join(stack_trace))


static func of_push_error(line: int, message: String, stack_trace: PackedStringArray) -> ErrorLogEntry:
	return ErrorLogEntry.new(TYPE.PUSH_ERROR, line, message, "\n".join(stack_trace))


static func of_script_error(line: int, message: String, stack_trace: PackedStringArray) -> ErrorLogEntry:
	return ErrorLogEntry.new(TYPE.SCRIPT_ERROR, line, message, "\n".join(stack_trace))
