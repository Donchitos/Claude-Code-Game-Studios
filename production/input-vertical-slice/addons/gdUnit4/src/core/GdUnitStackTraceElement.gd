## Represents a single frame in a GDScript call stack.[br]
## Stores the source file, line number, and function name at the point of capture.
class_name GdUnitStackTraceElement
extends RefCounted


## The resource path of the source file (e.g. [code]res://addons/my_plugin/foo.gd[/code]).
var _source: String
## The line number within [member _source].
var _line: int
## The name of the function at this frame.
var _function: String


## Creates a new stack trace element from the given [param source] path, [param line] number, and [param function] name.
func _init(source: String, line: int, function: String) -> void:
	_source = source
	_line = line
	_function = function


## Creates a [GdUnitStackTraceElement] from a dictionary with keys [code]source[/code], [code]line[/code], and [code]function[/code].
static func of(data: Dictionary) -> GdUnitStackTraceElement:
	var source: String = data["source"]
	var line: int = data["line"]
	var function: String = data["function"]
	return GdUnitStackTraceElement.new(source, line, function)


## Returns a human-readable representation in the form [code]basename.function(file:line)[/code].
func _to_string() -> String:
	return "%s.%s(%s:%d)" % [_source.get_basename(), _function, _source.get_file(), _line]
