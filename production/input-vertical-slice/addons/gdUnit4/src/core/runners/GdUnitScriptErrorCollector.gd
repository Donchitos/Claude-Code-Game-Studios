## Collects GDScript parse errors.[br]
## [br]
## Installed via [method OS.add_logger] so it intercepts [constant ErrorType.ERROR_TYPE_SCRIPT]
## entries without triggering Godot's interactive CLI debugger.[br]
## Used by [class GdUnitTestCIRunner] to detect broken user test scripts early
## and exit with a meaningful error instead of silently skipping them.
class_name GdUnitScriptErrorCollector
extends Logger


## Holds information about a single captured script error.
class ScriptError extends RefCounted:
	var _message: String
	var _source_file: String
	var _source_line: int

	func _init(message: String, source_file: String, source_line: int) -> void:
		_message = message
		_source_file = source_file
		_source_line = source_line

	func _to_string() -> String:
		if _source_file.is_empty():
			return _message
		return "%s\n\tat %s:%d" % [_message, _source_file, _source_line]


var _errors: Array[ScriptError] = []


func _init() -> void:
	OS.add_logger(self)


func _log_error(
	_function: String,
	source_file: String,
	source_line: int,
	message: String,
	_rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtraces: Array[ScriptBacktrace]
	) -> void:
	if error_type != ErrorType.ERROR_TYPE_SCRIPT:
		return
	_errors.append(ScriptError.new(message, source_file, source_line))


func _log_message(_message: String, _error: bool) -> void:
	pass


## Returns true if any script errors were captured.
func has_errors() -> bool:
	return not _errors.is_empty()


## Returns all captured script errors.
func errors() -> Array[ScriptError]:
	return _errors


## Clears all captured errors.
func clear() -> void:
	_errors.clear()
