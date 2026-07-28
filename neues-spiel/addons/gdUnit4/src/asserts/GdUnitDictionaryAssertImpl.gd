extends GdUnitDictionaryAssert

var _base: GdUnitAssertImpl


func _init(current :Variant) -> void:
	_base = GdUnitAssertImpl.new(current)
	# save the actual assert instance on the current thread context
	GdUnitThreadManager.get_current_context().set_assert(self)
	if not GdUnitAssertions.validate_value_type(current, TYPE_DICTIONARY):
		@warning_ignore("return_value_discarded")
		report_error("GdUnitDictionaryAssert inital error, unexpected type <%s>" % GdObjects.typeof_as_string(current))


func _notification(event :int) -> void:
	if event == NOTIFICATION_PREDELETE:
		if _base != null:
			_base.notification(event)
			_base = null


func report_success() -> GdUnitDictionaryAssert:
	@warning_ignore("return_value_discarded")
	_base.report_success()
	return self


func report_error(error :String) -> GdUnitDictionaryAssert:
	@warning_ignore("return_value_discarded")
	_base.report_error(error)
	return self


func failure_message() -> String:
	return _base.failure_message()


func override_failure_message(message: String) -> GdUnitDictionaryAssert:
	@warning_ignore("return_value_discarded")
	_base.override_failure_message(message)
	return self


func append_failure_message(message: String) -> GdUnitDictionaryAssert:
	@warning_ignore("return_value_discarded")
	_base.append_failure_message(message)
	return self


func current_value() -> Variant:
	return _base.current_value()


func is_null() -> GdUnitDictionaryAssert:
	@warning_ignore("return_value_discarded")
	_base.is_null()
	return self


func is_not_null() -> GdUnitDictionaryAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_null()
	return self


func is_equal(expected: Variant) -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	if current == null:
		return report_error(GdAssertMessages.error_equal(null, GdAssertMessages.format_dict(expected)))
	if not GdObjects.equals(current, expected):
		var c := GdAssertMessages.format_dict(current)
		var e := GdAssertMessages.format_dict(expected)
		return report_error(GdAssertMessages.error_equal(c, e))
	return report_success()


func is_not_equal(expected: Variant) -> GdUnitDictionaryAssert:
	var current: Variant = current_value()
	if GdObjects.equals(current, expected):
		return report_error(GdAssertMessages.error_not_equal(current, expected))
	return report_success()


@warning_ignore("unused_parameter", "shadowed_global_identifier")
func is_same(expected :Variant) -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	if current == null:
		return report_error(GdAssertMessages.error_equal(null, GdAssertMessages.format_dict(expected)))
	if not is_same(current, expected):
		var c := GdAssertMessages.format_dict(current)
		var e := GdAssertMessages.format_dict(expected)
		return report_error(GdAssertMessages.error_is_same(c, e))
	return report_success()


@warning_ignore("unused_parameter", "shadowed_global_identifier")
func is_not_same(expected :Variant) -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	if is_same(current, expected):
		return report_error(GdAssertMessages.error_not_same(current, expected))
	return report_success()


func is_empty() -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	@warning_ignore("unsafe_cast")
	if current == null or not (current as Dictionary).is_empty():
		return report_error(GdAssertMessages.error_is_empty(current))
	return report_success()


func is_not_empty() -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	@warning_ignore("unsafe_cast")
	if current == null or (current as Dictionary).is_empty():
		return report_error(GdAssertMessages.error_is_not_empty())
	return report_success()


func has_size(expected: int) -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	if current == null:
		return report_error(GdAssertMessages.error_is_not_null())
	@warning_ignore("unsafe_cast")
	if (current as Dictionary).size() != expected:
		return report_error(GdAssertMessages.error_has_size(current, expected))
	return report_success()


func _contains_keys(expected: Array, compare_mode: GdObjects.COMPARE_MODE) -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	var expected_value: Array = _extract_variadic_value(expected)
	if current == null:
		return report_error(GdAssertMessages.error_is_not_null())
	# find expected keys
	@warning_ignore("unsafe_cast")
	var keys_not_found :Array = expected_value.filter(_filter_by_key.bind((current as Dictionary).keys(), compare_mode))
	if not keys_not_found.is_empty():
		@warning_ignore("unsafe_cast")
		return report_error(GdAssertMessages.error_contains_keys((current as Dictionary).keys() as Array, expected_value,
			keys_not_found, compare_mode))
	return report_success()


func _contains_key_value(key :Variant, value :Variant, compare_mode :GdObjects.COMPARE_MODE) -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	var expected := [key]
	if current == null:
		return report_error(GdAssertMessages.error_is_not_null())
	var dict_current: Dictionary = current
	var keys_not_found :Array = expected.filter(_filter_by_key.bind(dict_current.keys(), compare_mode))
	if not keys_not_found.is_empty():
		return report_error(GdAssertMessages.error_contains_keys(dict_current.keys() as Array, expected, keys_not_found, compare_mode))
	if not GdObjects.equals(dict_current[key], value, false, compare_mode):
		return report_error(GdAssertMessages.error_contains_key_value(key, value, dict_current[key], compare_mode))
	return report_success()


func _not_contains_keys(expected: Array, compare_mode: GdObjects.COMPARE_MODE) -> GdUnitDictionaryAssert:
	var current :Variant = current_value()
	var expected_value: Array = _extract_variadic_value(expected)
	if current == null:
		return report_error(GdAssertMessages.error_is_not_null())
	var dict_current: Dictionary = current
	var keys_found :Array = dict_current.keys().filter(_filter_by_key.bind(expected_value, compare_mode, true))
	if not keys_found.is_empty():
		return report_error(GdAssertMessages.error_not_contains_keys(dict_current.keys() as Array, expected_value, keys_found, compare_mode))
	return report_success()


func contains_keys(...expected: Array) -> GdUnitDictionaryAssert:
	return _contains_keys(expected, GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST)


func contains_key_value(key :Variant, value :Variant) -> GdUnitDictionaryAssert:
	return _contains_key_value(key, value, GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST)


func not_contains_keys(...expected: Array) -> GdUnitDictionaryAssert:
	return _not_contains_keys(expected, GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST)


func contains_same_keys(expected :Array) -> GdUnitDictionaryAssert:
	return _contains_keys(expected, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)


func contains_same_key_value(key :Variant, value :Variant) -> GdUnitDictionaryAssert:
	return _contains_key_value(key, value, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)


func not_contains_same_keys(...expected: Array) -> GdUnitDictionaryAssert:
	return _not_contains_keys(expected, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)


func _filter_by_key(element :Variant, values :Array, compare_mode :GdObjects.COMPARE_MODE, is_not :bool = false) -> bool:
	for key :Variant in values:
		if GdObjects.equals(key, element, false, compare_mode):
			return is_not
	return !is_not


## Small helper to support the old expected arguments as single array and variadic arguments
func _extract_variadic_value(values: Variant) -> Variant:
	@warning_ignore("unsafe_method_access")
	if values != null and values.size() == 1 and GdArrayTools.is_array_type(values[0]):
		return values[0]
	return values
