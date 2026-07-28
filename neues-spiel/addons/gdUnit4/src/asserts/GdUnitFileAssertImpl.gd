extends GdUnitFileAssert

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

var _base: GdUnitAssertImpl


func _init(current :Variant) -> void:
	_base = GdUnitAssertImpl.new(current)
	# save the actual assert instance on the current thread context
	GdUnitThreadManager.get_current_context().set_assert(self)
	if not GdUnitAssertions.validate_value_type(current, TYPE_STRING):
		@warning_ignore("return_value_discarded")
		report_error("GdUnitFileAssert inital error, unexpected type <%s>" % GdObjects.typeof_as_string(current))


func _notification(event :int) -> void:
	if event == NOTIFICATION_PREDELETE:
		if _base != null:
			_base.notification(event)
			_base = null


func current_value() -> String:
	return _base.current_value()


func report_success() -> GdUnitFileAssert:
	@warning_ignore("return_value_discarded")
	_base.report_success()
	return self


func report_error(error :String) -> GdUnitFileAssert:
	@warning_ignore("return_value_discarded")
	_base.report_error(error)
	return self


func failure_message() -> String:
	return _base.failure_message()


func override_failure_message(message: String) -> GdUnitFileAssert:
	@warning_ignore("return_value_discarded")
	_base.override_failure_message(message)
	return self


func append_failure_message(message: String) -> GdUnitFileAssert:
	@warning_ignore("return_value_discarded")
	_base.append_failure_message(message)
	return self


func is_null() -> GdUnitFileAssert:
	@warning_ignore("return_value_discarded")
	_base.is_null()
	return self


func is_not_null() -> GdUnitFileAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_null()
	return self


func is_equal(expected: Variant) -> GdUnitFileAssert:
	@warning_ignore("return_value_discarded")
	_base.is_equal(expected)
	return self


func is_not_equal(expected: Variant) -> GdUnitFileAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_equal(expected)
	return self


func is_file() -> GdUnitFileAssert:
	var current := current_value()
	if FileAccess.open(current, FileAccess.READ) == null:
		return report_error("Is not a file '%s', error code %s" % [current, FileAccess.get_open_error()])
	return report_success()


func exists() -> GdUnitFileAssert:
	var current := current_value()
	if not FileAccess.file_exists(current):
		return report_error("The file '%s' not exists" %current)
	return report_success()


func is_script() -> GdUnitFileAssert:
	var current := current_value()
	if FileAccess.open(current, FileAccess.READ) == null:
		return report_error("Can't acces the file '%s'! Error code %s" % [current, FileAccess.get_open_error()])

	var script := load(current)
	if not script is GDScript:
		return report_error("The file '%s' is not a GdScript" % current)
	return report_success()


func contains_exactly(expected_rows: Array) -> GdUnitFileAssert:
	var current := current_value()
	if FileAccess.open(current, FileAccess.READ) == null:
		return report_error("Can't acces the file '%s'! Error code %s" % [current, FileAccess.get_open_error()])

	var script: GDScript = load(current)
	if script is GDScript:
		var source_code := GdScriptParser.to_unix_format(script.source_code)
		var rows := Array(source_code.split("\n"))
		@warning_ignore("return_value_discarded")
		GdUnitArrayAssertImpl.new(rows).contains_exactly(expected_rows)
	return self
