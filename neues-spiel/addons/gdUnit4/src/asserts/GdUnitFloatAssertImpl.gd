extends GdUnitFloatAssert

var _base: GdUnitAssertImpl


func _init(current :Variant) -> void:
	_base = GdUnitAssertImpl.new(current)
	# save the actual assert instance on the current thread context
	GdUnitThreadManager.get_current_context().set_assert(self)
	if not GdUnitAssertions.validate_value_type(current, TYPE_FLOAT):
		@warning_ignore("return_value_discarded")
		report_error("GdUnitFloatAssert inital error, unexpected type <%s>" % GdObjects.typeof_as_string(current))


func _notification(event :int) -> void:
	if event == NOTIFICATION_PREDELETE:
		if _base != null:
			_base.notification(event)
			_base = null


func current_value() -> Variant:
	return _base.current_value()


func report_success() -> GdUnitFloatAssert:
	@warning_ignore("return_value_discarded")
	_base.report_success()
	return self


func report_error(error :String) -> GdUnitFloatAssert:
	@warning_ignore("return_value_discarded")
	_base.report_error(error)
	return self


func failure_message() -> String:
	return _base.failure_message()


func override_failure_message(message: String) -> GdUnitFloatAssert:
	@warning_ignore("return_value_discarded")
	_base.override_failure_message(message)
	return self


func append_failure_message(message: String) -> GdUnitFloatAssert:
	@warning_ignore("return_value_discarded")
	_base.append_failure_message(message)
	return self


func is_null() -> GdUnitFloatAssert:
	@warning_ignore("return_value_discarded")
	_base.is_null()
	return self


func is_not_null() -> GdUnitFloatAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_null()
	return self


func is_equal(expected: Variant) -> GdUnitFloatAssert:
	@warning_ignore("return_value_discarded")
	_base.is_equal(expected)
	return self


func is_not_equal(expected: Variant) -> GdUnitFloatAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_equal(expected)
	return self


@warning_ignore("shadowed_global_identifier")
func is_equal_approx(expected :float, approx :float) -> GdUnitFloatAssert:
	return is_between(expected-approx, expected+approx)


func is_less(expected :float) -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if current == null or current >= expected:
		return report_error(GdAssertMessages.error_is_value(Comparator.LESS_THAN, current, expected))
	return report_success()


func is_less_equal(expected :float) -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if current == null or current > expected:
		return report_error(GdAssertMessages.error_is_value(Comparator.LESS_EQUAL, current, expected))
	return report_success()


func is_greater(expected :float) -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if current == null or current <= expected:
		return report_error(GdAssertMessages.error_is_value(Comparator.GREATER_THAN, current, expected))
	return report_success()


func is_greater_equal(expected :float) -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if current == null or current < expected:
		return report_error(GdAssertMessages.error_is_value(Comparator.GREATER_EQUAL, current, expected))
	return report_success()


func is_negative() -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if current == null or current >= 0.0:
		return report_error(GdAssertMessages.error_is_negative(current))
	return report_success()


func is_not_negative() -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if current == null or current < 0.0:
		return report_error(GdAssertMessages.error_is_not_negative(current))
	return report_success()


func is_zero() -> GdUnitFloatAssert:
	var current :Variant = current_value()
	@warning_ignore("unsafe_cast")
	if current == null or not is_equal_approx(0.00000000, current as float):
		return report_error(GdAssertMessages.error_is_zero(current))
	return report_success()


func is_not_zero() -> GdUnitFloatAssert:
	var current :Variant = current_value()
	@warning_ignore("unsafe_cast")
	if current == null or is_equal_approx(0.00000000, current as float):
		return report_error(GdAssertMessages.error_is_not_zero())
	return report_success()


func is_in(expected :Array) -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if not expected.has(current):
		return report_error(GdAssertMessages.error_is_in(current, expected))
	return report_success()


func is_not_in(expected :Array) -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if expected.has(current):
		return report_error(GdAssertMessages.error_is_not_in(current, expected))
	return report_success()


func is_between(from :float, to :float) -> GdUnitFloatAssert:
	var current :Variant = current_value()
	if current == null or current < from or current > to:
		return report_error(GdAssertMessages.error_is_value(Comparator.BETWEEN_EQUAL, current, from, to))
	return report_success()
