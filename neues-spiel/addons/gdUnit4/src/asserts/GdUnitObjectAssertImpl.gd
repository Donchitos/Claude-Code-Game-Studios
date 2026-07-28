extends GdUnitObjectAssert

var _base: GdUnitAssertImpl


func _init(current: Variant) -> void:
	_base = GdUnitAssertImpl.new(current)
	# save the actual assert instance on the current thread context
	GdUnitThreadManager.get_current_context().set_assert(self)
	if (current != null
		and (GdUnitAssertions.validate_value_type(current, TYPE_BOOL)
		or GdUnitAssertions.validate_value_type(current, TYPE_INT)
		or GdUnitAssertions.validate_value_type(current, TYPE_FLOAT)
		or GdUnitAssertions.validate_value_type(current, TYPE_STRING))):
			@warning_ignore("return_value_discarded")
			report_error("GdUnitObjectAssert inital error, unexpected type <%s>" % GdObjects.typeof_as_string(current))


func _notification(event: int) -> void:
	if event == NOTIFICATION_PREDELETE:
		if _base != null:
			_base.notification(event)
			_base = null


func current_value() -> Variant:
	return _base.current_value()


func report_success() -> GdUnitObjectAssert:
	@warning_ignore("return_value_discarded")
	_base.report_success()
	return self


func report_error(error: String) -> GdUnitObjectAssert:
	@warning_ignore("return_value_discarded")
	_base.report_error(error)
	return self


func failure_message() -> String:
	return _base.failure_message()


func override_failure_message(message: String) -> GdUnitObjectAssert:
	@warning_ignore("return_value_discarded")
	_base.override_failure_message(message)
	return self


func append_failure_message(message: String) -> GdUnitObjectAssert:
	@warning_ignore("return_value_discarded")
	_base.append_failure_message(message)
	return self


func is_equal(expected: Variant) -> GdUnitObjectAssert:
	@warning_ignore("return_value_discarded")
	_base.is_equal(expected)
	return self


func is_not_equal(expected: Variant) -> GdUnitObjectAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_equal(expected)
	return self


func is_null() -> GdUnitObjectAssert:
	@warning_ignore("return_value_discarded")
	_base.is_null()
	return self


func is_not_null() -> GdUnitObjectAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_null()
	return self


@warning_ignore("shadowed_global_identifier")
func is_same(expected: Variant) -> GdUnitObjectAssert:
	var current: Variant = current_value()
	if not is_same(current, expected):
		return report_error(GdAssertMessages.error_is_same(current, expected))
	return report_success()


func is_not_same(expected: Variant) -> GdUnitObjectAssert:
	var current: Variant = current_value()
	if is_same(current, expected):
		return report_error(GdAssertMessages.error_not_same(current, expected))
	return report_success()


func is_instanceof(type: Variant) -> GdUnitObjectAssert:
	var current: Variant = current_value()
	if current == null or not is_instance_of(current, type):
		var result_expected := GdObjects.extract_class_name(type)
		var result_current := GdObjects.extract_class_name(current)
		return report_error(GdAssertMessages.error_is_instanceof(result_current, result_expected))
	return report_success()


func is_not_instanceof(type: Variant) -> GdUnitObjectAssert:
	var current: Variant = current_value()
	if is_instance_of(current, type):
		var result := GdObjects.extract_class_name(type)
		if result.is_success():
			return report_error("Expected not be a instance of <%s>" % str(result.value()))

		push_error("Internal ERROR: %s" % result.error_message())
		return self
	return report_success()


## Checks whether the current object inherits from the specified type.
func is_inheriting(type: Variant) -> GdUnitObjectAssert:
	var current: Variant = current_value()
	if not is_instance_of(current, TYPE_OBJECT):
		return report_error("Expected '%s' to inherit from at least Object." % str(current))
	var result := _inherits(current, type)
	if result.is_success():
		return report_success()
	return report_error(result.error_message())


## Checks whether the current object does NOT inherit from the specified type.
func is_not_inheriting(type: Variant) -> GdUnitObjectAssert:
	var current: Variant = current_value()
	if not is_instance_of(current, TYPE_OBJECT):
		return report_error("Expected '%s' to inherit from at least Object." % str(current))
	var result := _inherits(current, type)
	if result.is_success():
		return report_error("Expected type to not inherit from <%s>" % _extract_class_type(type))
	return report_success()


func _inherits(current: Variant, type: Variant) -> GdUnitResult:
	var type_as_string := _extract_class_type(type)
	if type_as_string == "Object":
		return GdUnitResult.success("")

	var obj: Object = current
	for p in obj.get_property_list():
		var clazz_name :String = p["name"]
		if p["usage"] == PROPERTY_USAGE_CATEGORY and clazz_name == p["hint_string"] and clazz_name == type_as_string:
			return GdUnitResult.success("")
	var script: Script = obj.get_script()
	if script != null:
		while script != null:
			var result := GdObjects.extract_class_name(script)
			if result.is_success() and result.value() == type_as_string:
				return GdUnitResult.success("")
			script = script.get_base_script()
	return GdUnitResult.error("Expected type to inherit from <%s>" % type_as_string)


func _extract_class_type(type: Variant) -> String:
	if type is String:
		return type
	var result := GdObjects.extract_class_name(type)
	if result.is_error():
		return ""
	return result.value()
