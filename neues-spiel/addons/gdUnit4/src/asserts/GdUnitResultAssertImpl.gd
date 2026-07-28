extends GdUnitResultAssert

var _base: GdUnitAssertImpl


func _init(current :Variant) -> void:
	_base = GdUnitAssertImpl.new(current)
	# save the actual assert instance on the current thread context
	GdUnitThreadManager.get_current_context().set_assert(self)
	if not validate_value_type(current):
		@warning_ignore("return_value_discarded")
		report_error("GdUnitResultAssert inital error, unexpected type <%s>" % GdObjects.typeof_as_string(current))


func _notification(event :int) -> void:
	if event == NOTIFICATION_PREDELETE:
		if _base != null:
			_base.notification(event)
			_base = null


func validate_value_type(value :Variant) -> bool:
	return value == null or value is GdUnitResult


func current_value() -> GdUnitResult:
	return _base.current_value()


func report_success() -> GdUnitResultAssert:
	@warning_ignore("return_value_discarded")
	_base.report_success()
	return self


func report_error(error :String) -> GdUnitResultAssert:
	@warning_ignore("return_value_discarded")
	_base.report_error(error)
	return self


func failure_message() -> String:
	return _base.failure_message()


func override_failure_message(message: String) -> GdUnitResultAssert:
	@warning_ignore("return_value_discarded")
	_base.override_failure_message(message)
	return self


func append_failure_message(message: String) -> GdUnitResultAssert:
	@warning_ignore("return_value_discarded")
	_base.append_failure_message(message)
	return self


func is_null() -> GdUnitResultAssert:
	@warning_ignore("return_value_discarded")
	_base.is_null()
	return self


func is_not_null() -> GdUnitResultAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_null()
	return self


func is_equal(expected: Variant) -> GdUnitResultAssert:
	return is_value(expected)


func is_not_equal(expected: Variant) -> GdUnitResultAssert:
	var result := current_value()
	var value :Variant = null if result == null else result.value()
	if GdObjects.equals(value, expected):
		return report_error(GdAssertMessages.error_not_equal(value, expected))
	return report_success()


func is_empty() -> GdUnitResultAssert:
	var result := current_value()
	if result == null or not result.is_empty():
		return report_error(GdAssertMessages.error_result_is_empty(result))
	return report_success()


func is_success() -> GdUnitResultAssert:
	var result := current_value()
	if result == null or not result.is_success():
		return report_error(GdAssertMessages.error_result_is_success(result))
	return report_success()


func is_warning() -> GdUnitResultAssert:
	var result := current_value()
	if result == null or not result.is_warn():
		return report_error(GdAssertMessages.error_result_is_warning(result))
	return report_success()


func is_error() -> GdUnitResultAssert:
	var result := current_value()
	if result == null or not result.is_error():
		return report_error(GdAssertMessages.error_result_is_error(result))
	return report_success()


func contains_message(expected :String) -> GdUnitResultAssert:
	var result := current_value()
	if result == null:
		return report_error(GdAssertMessages.error_result_has_message("<null>", expected))
	if result.is_success():
		return report_error(GdAssertMessages.error_result_has_message_on_success(expected))
	if result.is_error() and result.error_message() != expected:
		return report_error(GdAssertMessages.error_result_has_message(result.error_message(), expected))
	if result.is_warn() and result.warn_message() != expected:
		return report_error(GdAssertMessages.error_result_has_message(result.warn_message(), expected))
	return report_success()


func is_value(expected: Variant) -> GdUnitResultAssert:
	var result := current_value()
	var value :Variant = null if result == null else result.value()
	if not GdObjects.equals(value, expected):
		return report_error(GdAssertMessages.error_result_is_value(value, expected))
	return report_success()
