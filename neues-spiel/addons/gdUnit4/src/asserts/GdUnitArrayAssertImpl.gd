class_name GdUnitArrayAssertImpl
extends GdUnitArrayAssert


var _base: GdUnitAssertImpl
var _current_value_provider: ValueProvider
var _type_check: bool


func _init(current: Variant, type_check := true) -> void:
	_type_check = type_check
	_current_value_provider = DefaultValueProvider.new(current)
	_base = GdUnitAssertImpl.new(current)
	# save the actual assert instance on the current thread context
	GdUnitThreadManager.get_current_context().set_assert(self)
	if not _validate_value_type(current):
		@warning_ignore("return_value_discarded")
		report_error("GdUnitArrayAssert inital error, unexpected type <%s>" % GdObjects.typeof_as_string(current))


func _notification(event: int) -> void:
	if event == NOTIFICATION_PREDELETE:
		if _base != null:
			_base.notification(event)
			_base = null


func report_success() -> GdUnitArrayAssert:
	@warning_ignore("return_value_discarded")
	_base.report_success()
	return self


func report_error(error: String) -> GdUnitArrayAssert:
	@warning_ignore("return_value_discarded")
	_base.report_error(error)
	return self


func failure_message() -> String:
	return _base.failure_message()


func override_failure_message(message: String) -> GdUnitArrayAssert:
	@warning_ignore("return_value_discarded")
	_base.override_failure_message(message)
	return self


func append_failure_message(message: String) -> GdUnitArrayAssert:
	@warning_ignore("return_value_discarded")
	_base.append_failure_message(message)
	return self


func _validate_value_type(value: Variant) -> bool:
	return value == null or GdArrayTools.is_array_type(value)


func get_current_value() -> Variant:
	return _current_value_provider.get_value()


func max_length(left: Variant, right: Variant) -> int:
	var ls := str(left).length()
	var rs := str(right).length()
	return rs if ls < rs else ls


# gdlint: disable=function-name
func _toPackedStringArray(value: Variant) -> PackedStringArray:
	if GdArrayTools.is_array_type(value):
		@warning_ignore("unsafe_cast")
		return PackedStringArray(value as Array)
	return PackedStringArray([str(value)])


func _array_equals_div(current: Variant, expected: Variant, case_sensitive: bool = false) -> Array:
	var current_value := _toPackedStringArray(current)
	var expected_value := _toPackedStringArray(expected)
	var index_report := Array()
	for index in current_value.size():
		var c := current_value[index]
		if index < expected_value.size():
			var e := expected_value[index]
			if not GdObjects.equals(c, e, case_sensitive):
				var length := max_length(c, e)
				current_value[index] = GdAssertMessages.format_invalid(c.lpad(length))
				expected_value[index] = e.lpad(length)
				index_report.push_back({"index": index, "current": c, "expected": e})
		else:
			current_value[index] = GdAssertMessages.format_invalid(c)
			index_report.push_back({"index": index, "current": c, "expected": "<N/A>"})

	for index in range(current_value.size(), expected_value.size()):
		var value := expected_value[index]
		expected_value[index] = GdAssertMessages.format_invalid(value)
		index_report.push_back({"index": index, "current": "<N/A>", "expected": value})
	return [current_value, expected_value, index_report]


func _array_div(compare_mode: GdObjects.COMPARE_MODE, left: Array[Variant], right: Array[Variant], _same_order := false) -> Array[Variant]:
	var not_expect := left.duplicate(true)
	var not_found := right.duplicate(true)
	for index_c in left.size():
		var c: Variant = left[index_c]
		for index_e in right.size():
			var e: Variant = right[index_e]
			if GdObjects.equals(c, e, false, compare_mode):
				GdArrayTools.erase_value(not_expect, e)
				GdArrayTools.erase_value(not_found, c)
				break
	return [not_expect, not_found]


func _contains(expected: Array, compare_mode: GdObjects.COMPARE_MODE) -> GdUnitArrayAssert:
	var by_reference := compare_mode == GdObjects.COMPARE_MODE.OBJECT_REFERENCE
	var current_value: Variant = get_current_value()
	var expected_value: Variant = _extract_variadic_value(expected)
	if not _validate_value_type(expected_value):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected_value))

	if current_value == null:
		return report_error(GdAssertMessages.error_arr_contains(current_value, expected_value, [], expected_value, by_reference))
	@warning_ignore("unsafe_cast")
	var diffs := _array_div(compare_mode, current_value as Array[Variant], expected_value as Array[Variant])
	#var not_expect := diffs[0] as Array
	var not_found: Array = diffs[1]
	if not not_found.is_empty():
		return report_error(GdAssertMessages.error_arr_contains(current_value, expected_value, [], not_found, by_reference))
	return report_success()


func _contains_exactly(expected: Array, compare_mode: GdObjects.COMPARE_MODE) -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	var expected_value: Variant = _extract_variadic_value(expected)
	if not _validate_value_type(expected_value):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected_value))

	if current_value == null:
		return report_error(GdAssertMessages.error_arr_contains_exactly(null, expected_value, [], expected_value, compare_mode))
	# has same content in same order
	if _is_equal(current_value, expected_value, false, compare_mode):
		return report_success()
	# check has same elements but in different order
	if _is_equals_sorted(current_value, expected_value, false, compare_mode):
		return report_error(GdAssertMessages.error_arr_contains_exactly(current_value, expected_value, [], [], compare_mode))
	# find the difference
	@warning_ignore("unsafe_cast")
	var diffs := _array_div(compare_mode,
		current_value as Array[Variant],
		expected_value as Array[Variant],
		GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST)
	var not_expect: Array[Variant] = diffs[0]
	var not_found: Array[Variant] = diffs[1]
	return report_error(GdAssertMessages.error_arr_contains_exactly(current_value, expected_value, not_expect, not_found, compare_mode))


func _contains_exactly_in_any_order(expected: Array, compare_mode: GdObjects.COMPARE_MODE) -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	var expected_value: Variant = _extract_variadic_value(expected)
	if not _validate_value_type(expected_value):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected_value))

	if current_value == null:
		return report_error(GdAssertMessages.error_arr_contains_exactly_in_any_order(current_value, expected_value, [],
			expected_value, compare_mode))
	# find the difference
	@warning_ignore("unsafe_cast")
	var diffs := _array_div(compare_mode, current_value as Array[Variant], expected_value as Array[Variant], false)
	var not_expect: Array[Variant] = diffs[0]
	var not_found: Array[Variant] = diffs[1]
	if not_expect.is_empty() and not_found.is_empty():
		return report_success()
	return report_error(GdAssertMessages.error_arr_contains_exactly_in_any_order(current_value, expected_value, not_expect,
		not_found, compare_mode))


func _not_contains(expected: Array, compare_mode: GdObjects.COMPARE_MODE) -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	var expected_value: Variant = _extract_variadic_value(expected)
	if not _validate_value_type(expected_value):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected_value))
	if current_value == null:
		return report_error(GdAssertMessages.error_arr_contains_exactly_in_any_order(current_value, expected_value, [],
			expected_value, compare_mode))
	@warning_ignore("unsafe_cast")
	var diffs := _array_div(compare_mode, current_value as Array[Variant], expected_value as Array[Variant])
	var found: Array[Variant] = diffs[0]
	@warning_ignore("unsafe_cast")
	if found.size() == (current_value as Array).size():
		return report_success()
	@warning_ignore("unsafe_cast")
	var diffs2 := _array_div(compare_mode, expected_value as Array[Variant], diffs[1] as Array[Variant])
	return report_error(GdAssertMessages.error_arr_not_contains(current_value, expected_value, diffs2[0], compare_mode))


func is_null() -> GdUnitArrayAssert:
	@warning_ignore("return_value_discarded")
	_base.is_null()
	return self


func is_not_null() -> GdUnitArrayAssert:
	@warning_ignore("return_value_discarded")
	_base.is_not_null()
	return self


func is_equal(...expected: Array) -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	var expected_value: Variant= _extract_variadic_value(expected)
	if not _validate_value_type(expected_value):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected_value))
	if current_value == null and expected_value != null:
		return report_error(GdAssertMessages.error_equal(null, expected_value))

	if not _is_equal(current_value, expected_value):
		var diff := _array_equals_div(current_value, expected_value)
		var expected_as_list := GdArrayTools.as_string(diff[0], false)
		var current_as_list := GdArrayTools.as_string(diff[1], false)
		var index_report: Array = diff[2]
		return report_error(GdAssertMessages.error_equal(expected_as_list, current_as_list, index_report))
	return report_success()


# Verifies that the current Array is equal to the given one, ignoring case considerations.
func is_equal_ignoring_case(...expected: Array) -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	var expected_value: Variant = _extract_variadic_value(expected)
	if not _validate_value_type(expected_value):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected_value))
	if current_value == null and expected_value != null:
		@warning_ignore("unsafe_cast")
		return report_error(GdAssertMessages.error_equal(null, GdArrayTools.as_string(expected_value)))

	if not _is_equal(current_value, expected_value, true):
		@warning_ignore("unsafe_cast")
		var diff := _array_equals_div(current_value, expected_value, true)
		var expected_as_list := GdArrayTools.as_string(diff[0])
		var current_as_list := GdArrayTools.as_string(diff[1])
		var index_report: Array = diff[2]
		return report_error(GdAssertMessages.error_equal(expected_as_list, current_as_list, index_report))
	return report_success()


func is_not_equal(...expected: Array) -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	var expected_value: Variant = _extract_variadic_value(expected)
	if not _validate_value_type(expected_value):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected_value))

	if _is_equal(current_value, expected_value):
		return report_error(GdAssertMessages.error_not_equal(current_value, expected_value))
	return report_success()


func is_not_equal_ignoring_case(...expected: Array) -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	var expected_value: Variant = _extract_variadic_value(expected)
	if not _validate_value_type(expected_value):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected_value))

	if _is_equal(current_value, expected_value, true):
		@warning_ignore("unsafe_cast")
		var c := GdArrayTools.as_string(current_value as Array)
		@warning_ignore("unsafe_cast")
		var e := GdArrayTools.as_string(expected_value)
		return report_error(GdAssertMessages.error_not_equal_case_insensetiv(c, e))
	return report_success()


func is_empty() -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	@warning_ignore("unsafe_cast")
	if current_value == null or (current_value as Array).size() > 0:
		return report_error(GdAssertMessages.error_is_empty(current_value))
	return report_success()


func is_not_empty() -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	@warning_ignore("unsafe_cast")
	if current_value != null and (current_value as Array).size() == 0:
		return report_error(GdAssertMessages.error_is_not_empty())
	return report_success()


@warning_ignore("unused_parameter", "shadowed_global_identifier")
func is_same(expected: Variant) -> GdUnitArrayAssert:
	if not _validate_value_type(expected):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected))
	var current: Variant = get_current_value()
	if not is_same(current, expected):
		@warning_ignore("return_value_discarded")
		report_error(GdAssertMessages.error_is_same(current, expected))
	return self


func is_not_same(expected: Variant) -> GdUnitArrayAssert:
	if not _validate_value_type(expected):
		return report_error("ERROR: expected value: <%s>\n is not a Array Type!" % GdObjects.typeof_as_string(expected))
	var current: Variant = get_current_value()
	if is_same(current, expected):
		@warning_ignore("return_value_discarded")
		report_error(GdAssertMessages.error_not_same(current, expected))
	return self


func has_size(expected: int) -> GdUnitArrayAssert:
	var current_value: Variant = get_current_value()
	@warning_ignore("unsafe_cast")
	if current_value == null or (current_value as Array).size() != expected:
		return report_error(GdAssertMessages.error_has_size(current_value, expected))
	return report_success()


func contains(...expected: Array) -> GdUnitArrayAssert:
	return _contains(expected, GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST)


func contains_exactly(...expected: Array) -> GdUnitArrayAssert:
	return _contains_exactly(expected, GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST)


func contains_exactly_in_any_order(...expected: Array) -> GdUnitArrayAssert:
	return _contains_exactly_in_any_order(expected, GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST)


func contains_same(...expected: Array) -> GdUnitArrayAssert:
	return _contains(expected, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)


func contains_same_exactly(...expected: Array) -> GdUnitArrayAssert:
	return _contains_exactly(expected, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)


func contains_same_exactly_in_any_order(...expected: Array) -> GdUnitArrayAssert:
	return _contains_exactly_in_any_order(expected, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)


func not_contains(...expected: Array) -> GdUnitArrayAssert:
	return _not_contains(expected, GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST)


func not_contains_same(...expected: Array) -> GdUnitArrayAssert:
	return _not_contains(expected, GdObjects.COMPARE_MODE.OBJECT_REFERENCE)


func is_instanceof(expected: Variant) -> GdUnitAssert:
	@warning_ignore("unsafe_method_access")
	_base.is_instanceof(expected)
	return self


func extract(func_name: String, ...func_args: Array) -> GdUnitArrayAssert:
	var extracted_elements := Array()
	var args: Array = _extract_variadic_value(func_args)
	var extractor := GdUnitFuncValueExtractor.new(func_name, args)
	var current: Variant = get_current_value()
	if current == null:
		_current_value_provider = DefaultValueProvider.new(null)
	else:
		for element: Variant in current:
			extracted_elements.append(extractor.extract_value(element))
		_current_value_provider = DefaultValueProvider.new(extracted_elements)
	return self


func extractv(...extractors: Array) -> GdUnitArrayAssert:
	var extracted_elements := Array()
	var current: Variant = get_current_value()
	if current == null:
		_current_value_provider = DefaultValueProvider.new(null)
	else:
		for element: Variant in current:
			var ev: Array[Variant] = []
			for index: int in extractors.size():
				var extractor: GdUnitValueExtractor = extractors[index]
				ev.append(extractor.extract_value(element))
			if extractors.size() > 1:
				extracted_elements.append(GdUnitTuple.new.callv(ev))
			else:
				extracted_elements.append(ev[0])
		_current_value_provider = DefaultValueProvider.new(extracted_elements)
	return self


## Small helper to support the old expected arguments as single array and variadic arguments
func _extract_variadic_value(values: Variant) -> Variant:
	@warning_ignore("unsafe_method_access")
	if values != null and values.size() == 1 and GdArrayTools.is_array_type(values[0]):
		return values[0]
	return values


@warning_ignore("incompatible_ternary")
func _is_equal(
	left: Variant,
	right: Variant,
	case_sensitive := false,
	compare_mode := GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST) -> bool:

	@warning_ignore("unsafe_cast")
	return GdObjects.equals(
		(left as Array) if GdArrayTools.is_array_type(left) else left,
		(right as Array) if GdArrayTools.is_array_type(right) else right,
		case_sensitive,
		compare_mode
	)


func _is_equals_sorted(
	left: Variant,
	right: Variant,
	case_sensitive := false,
	compare_mode := GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST) -> bool:

	@warning_ignore("unsafe_cast")
	return GdObjects.equals_sorted(
		left as Array,
		right as Array,
		case_sensitive,
		compare_mode)
