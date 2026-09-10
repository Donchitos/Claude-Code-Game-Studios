class_name GdUnitAssertImpl
extends GdUnitAssert


var _current :Variant
var _custom_failure_message :String = ""
var _additional_failure_message: String = ""


func _init(current :Variant) -> void:
	_current = current
	# save the actual assert instance on the current thread context
	GdUnitThreadManager.get_current_context().set_assert(self)
	GdAssertReports.reset_last_error_line_number()


func current_value() -> Variant:
	return _current


func report_success() -> GdUnitAssert:
	GdAssertReports.report_success()
	return self


func report_error(failure :String, failure_line_number: int = -1) -> GdUnitAssert:
	var stack_trace := GdUnitStackTrace.new()
	var line_number := failure_line_number if failure_line_number != -1 else stack_trace.get_line_number()
	GdAssertReports.set_last_error_line_number(line_number)
	var failure_message := GdAssertMessages.build_failure_message(failure, _additional_failure_message, _custom_failure_message)
	GdAssertReports.report_error(GdUnitError.new(failure_message, line_number, stack_trace))
	return self


func do_fail_not_implemented() -> GdUnitAssert:
	return report_error(GdAssertMessages.error_not_implemented())


func do_fail_with_message(message: String) -> GdUnitAssert:
	return report_error(GdAssertMessages.error_with_message(message))


func override_failure_message(message: String) -> GdUnitAssert:
	_custom_failure_message = message
	return self


func append_failure_message(message: String) -> GdUnitAssert:
	_additional_failure_message = message
	return self


func is_null() -> GdUnitAssert:
	var current :Variant = current_value()
	if current != null:
		return report_error(GdAssertMessages.error_is_null(current))
	return report_success()


func is_not_null() -> GdUnitAssert:
	var current :Variant = current_value()
	if current == null:
		return report_error(GdAssertMessages.error_is_not_null())
	return report_success()


func is_equal(expected: Variant) -> GdUnitAssert:
	var current: Variant = current_value()
	if not GdObjects.equals(current, expected):
		return report_error(GdAssertMessages.error_equal(current, expected))
	return report_success()


func is_not_equal(expected: Variant) -> GdUnitAssert:
	var current: Variant = current_value()
	if GdObjects.equals(current, expected):
		return report_error(GdAssertMessages.error_not_equal(current, expected))
	return report_success()
