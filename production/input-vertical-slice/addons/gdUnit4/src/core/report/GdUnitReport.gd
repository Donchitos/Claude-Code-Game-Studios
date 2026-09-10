class_name GdUnitReport
extends Resource

# report type
enum {
	SUCCESS,
	WARN,
	FAILURE,
	ORPHAN,
	TERMINATED,
	INTERUPTED,
	ABORT,
	SKIPPED,
}

var _type :int
var _line_number :int
var _message :String
var _current_value: Variant
var _error: GdUnitError


func from_error(p_type: int, error: GdUnitError) -> GdUnitReport:
	_type = p_type
	_line_number = error._line_number
	_message = error._message
	_error = error
	return self


func create(p_type :int, p_line_number :int, p_message :String) -> GdUnitReport:
	_type = p_type
	_line_number = p_line_number
	_message = p_message
	return self


func with_current_value(value: Variant) -> GdUnitReport:
	_current_value = value
	return self


func type() -> int:
	return _type


func line_number() -> int:
	return _line_number


func message() -> String:
	return _message


func is_skipped() -> bool:
	return _type == SKIPPED


func is_warning() -> bool:
	return _type == WARN


func is_failure() -> bool:
	return _type == FAILURE


func is_error() -> bool:
	return _type == TERMINATED or _type == INTERUPTED or _type == ABORT


func is_orphan() -> bool:
	return _type == ORPHAN


func stack_trace() -> GdUnitStackTrace:
	if _error == null:
		return null
	return _error._stack_trace


func _to_string() -> String:
	if _line_number == -1:
		return "[color=green]line [/color][color=aqua]<n/a>:[/color] %s" % [_message]
	return "[color=green]line [/color][color=aqua]%d:[/color] %s" % [_line_number, _message]


func serialize() -> Dictionary:
	var serialized := {
		"type"        : _type,
		"line_number" : _line_number,
		"message"     : _message
	}
	var trace := stack_trace()
	if trace != null:
		serialized["stack_trace"] = trace.serialize()
	return serialized


func deserialize(serialized: Dictionary) -> GdUnitReport:
	_type        = serialized["type"]
	_line_number = serialized["line_number"]
	_message     = serialized["message"]
	if serialized.has("stack_trace"):
		@warning_ignore("unsafe_cast")
		var trace := GdUnitStackTrace.deserialize(serialized["stack_trace"] as String)
		_error = GdUnitError.new(_message, _line_number, trace)
	return self
