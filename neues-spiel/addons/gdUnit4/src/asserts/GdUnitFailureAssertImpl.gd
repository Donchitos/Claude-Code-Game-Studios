extends GdUnitFailureAssert

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

var _is_failed := false
var _failure_message: String
var _current_failure_message := ""
var _custom_failure_message := ""
var _additional_failure_message := ""


func _set_do_expect_fail(enabled :bool = true) -> void:
	Engine.set_meta(GdUnitConstants.EXPECT_ASSERT_REPORT_FAILURES, enabled)


func execute_and_await(assertion :Callable, do_await := true) -> GdUnitFailureAssert:
	# do not report any failure from the original assertion we want to test
	_set_do_expect_fail(true)
	var thread_context := GdUnitThreadManager.get_current_context()
	thread_context.set_assert(null)
	@warning_ignore("return_value_discarded")
	GdUnitSignals.instance().gdunit_set_test_failed.connect(_on_test_failed)
	# execute the given assertion as callable
	if do_await:
		await assertion.call()
	else:
		assertion.call()
	_set_do_expect_fail(false)
	# get the assert instance from current tread context
	var current_assert := thread_context.get_assert()
	if not is_instance_of(current_assert, GdUnitAssert):
		_is_failed = true
		_failure_message = "Invalid Callable! It must be a callable of 'GdUnitAssert'"
		return self
	@warning_ignore("unsafe_method_access")
	_failure_message = current_assert.failure_message()
	return self


func execute(assertion :Callable) -> GdUnitFailureAssert:
	@warning_ignore("return_value_discarded")
	execute_and_await(assertion, false)
	return self


func _on_test_failed(value :bool) -> void:
	_is_failed = value


func is_equal(_expected: Variant) -> GdUnitFailureAssert:
	return _report_error("Not implemented")


func is_not_equal(_expected: Variant) -> GdUnitFailureAssert:
	return _report_error("Not implemented")


func is_null() -> GdUnitFailureAssert:
	return _report_error("Not implemented")


func is_not_null() -> GdUnitFailureAssert:
	return _report_error("Not implemented")


func override_failure_message(message: String) -> GdUnitFailureAssert:
	_custom_failure_message = message
	return self


func append_failure_message(message: String) -> GdUnitFailureAssert:
	_additional_failure_message = message
	return self


func is_success() -> GdUnitFailureAssert:
	if _is_failed:
		return _report_error("Expect: assertion ends successfully.")
	return self


func is_failed() -> GdUnitFailureAssert:
	if not _is_failed:
		return _report_error("Expect: assertion fails.")
	return self


func has_line(expected :int) -> GdUnitFailureAssert:
	var current := GdAssertReports.get_last_error_line_number()
	if current != expected:
		return _report_error("Expect: to failed on line '%d'\n but was '%d'." % [expected, current])
	return self


func has_message(expected :String) -> GdUnitFailureAssert:
	@warning_ignore("return_value_discarded")
	is_failed()
	var expected_error := GdUnitTools.normalize_text(GdUnitTools.richtext_normalize(expected))
	var current_error := GdUnitTools.normalize_text(GdUnitTools.richtext_normalize(_failure_message))
	if current_error != expected_error:
		var diffs := GdDiffTool.string_diff(current_error, expected_error)
		var current := GdAssertMessages.colored_array_div(diffs[1])
		return _report_error(GdAssertMessages.error_not_same_error(current, expected_error))
	return self


func contains_message(expected :String) -> GdUnitFailureAssert:
	var expected_error := GdUnitTools.normalize_text(expected)
	var current_error := GdUnitTools.normalize_text(GdUnitTools.richtext_normalize(_failure_message))
	if not current_error.contains(expected_error):
		var diffs := GdDiffTool.string_diff(current_error, expected_error)
		var current := GdAssertMessages.colored_array_div(diffs[1])
		return _report_error(GdAssertMessages.error_not_same_error(current, expected_error))
	return self


func starts_with_message(expected :String) -> GdUnitFailureAssert:
	var expected_error := GdUnitTools.normalize_text(expected)
	var current_error := GdUnitTools.normalize_text(GdUnitTools.richtext_normalize(_failure_message))
	if current_error.find(expected_error) != 0:
		var diffs := GdDiffTool.string_diff(current_error, expected_error)
		var current := GdAssertMessages.colored_array_div(diffs[1])
		return _report_error(GdAssertMessages.error_not_same_error(current, expected_error))
	return self


func _report_error(error_message :String, failure_line_number: int = -1) -> GdUnitAssert:
	var line_number := failure_line_number if failure_line_number != -1 else GdUnitAssertions.get_line_number()
	_current_failure_message = GdAssertMessages.build_failure_message(error_message, _additional_failure_message, _custom_failure_message)
	GdAssertReports.report_error(_current_failure_message, line_number)
	return self


func _report_success() -> GdUnitFailureAssert:
	GdAssertReports.report_success()
	return self
