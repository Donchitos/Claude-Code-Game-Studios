class_name GodotGdErrorMonitor
extends GdUnitMonitor


var _logger: GdUnitLogger


class GdUnitLogger extends Logger:
	var _entries: Array[ErrorLogEntry] = []
	var _line_number: int
	var _is_report_push_errors: bool
	var _is_report_script_errors: bool


	func _init(is_report_push_errors: bool, is_report_script_errors: bool) -> void:
		_is_report_push_errors = is_report_push_errors
		_is_report_script_errors = is_report_script_errors
		OS.add_logger(self)


	func entries() -> Array[ErrorLogEntry]:
		return _entries

	func erase_log_entry(log_entry: ErrorLogEntry) -> void:
		for entry in _entries:
			if entry._type == log_entry._type and entry._message == log_entry._message:
				_entries.erase(entry)
				return


	func _log_error(
		_function: String,
		_file: String,
		_line: int,
		message: String,
		_rationale: String,
		_editor_notify: bool,
		error_type: int,
		script_backtraces: Array[ScriptBacktrace]
		) -> void:
		match error_type:
			ErrorType.ERROR_TYPE_WARNING:
				if _is_report_push_errors:
					var stack_trace := _build_stack_trace(script_backtraces)
					_entries.append(ErrorLogEntry.of_push_warning(_line_number, message, stack_trace))

			ErrorType.ERROR_TYPE_ERROR:
				if _is_report_push_errors:
					var stack_trace := _build_stack_trace(script_backtraces)
					_entries.append(ErrorLogEntry.of_push_error(_line_number, message, stack_trace))

			ErrorType.ERROR_TYPE_SCRIPT:
				if _is_report_script_errors:
					var stack_trace := _build_stack_trace(script_backtraces)
					_entries.append(ErrorLogEntry.of_script_error(_line_number, message, stack_trace))

			ErrorType.ERROR_TYPE_SHADER:
				pass
			_:
				prints("Unknwon log type", message)

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func _build_stack_trace(script_backtraces: Array[ScriptBacktrace]) -> PackedStringArray:
		for sb in script_backtraces:
			for frame in sb.get_frame_count():
				# Find start of test stack
				if sb.get_frame_file(frame) == "res://addons/gdUnit4/src/core/_TestCase.gd":
					var stack_trace := PackedStringArray()
					for test_case_frame in range(0, frame):
						_line_number = sb.get_frame_line(test_case_frame)
						stack_trace.append("	at %s:%s" % [sb.get_frame_file(test_case_frame), sb.get_frame_line(test_case_frame)])
					return stack_trace
		# if no stack trace collected, we in an await function call
		var sb := script_backtraces[0]
		return ["	at %s:%s" % [sb.get_frame_file(0), sb.get_frame_line(0)]]


func _init() -> void:
	super("GdUnitLoggerMonitor")
	_logger = GdUnitLogger.new(GdUnitSettings.is_report_push_errors(), GdUnitSettings.is_report_script_errors())


func start() -> void:
	clear_logs()


func stop() -> void:
	pass


func log_entries() -> Array[ErrorLogEntry]:
	return _logger.entries()


func erase_log_entry(log_entry: ErrorLogEntry) -> void:
	_logger.erase_log_entry(log_entry)


func to_reports() -> Array[GdUnitReport]:
	var reports_: Array[GdUnitReport] = []

	reports_.assign(log_entries().map(_to_report))

	return reports_


static func _to_report(errorLog: ErrorLogEntry) -> GdUnitReport:
	var failure := """
		%s
		%s %s
		%s""".dedent().trim_prefix("\n") % [
		GdAssertMessages._error("Godot Runtime Error !"),
		GdAssertMessages._error("Error:"),
		GdAssertMessages._colored_value(errorLog._message),
		GdAssertMessages._colored(errorLog._details, GdAssertMessages.VALUE_COLOR)]
	return GdUnitReport.new().create(GdUnitReport.ABORT, errorLog._line, failure)


func clear_logs() -> void:
	log_entries().clear()
