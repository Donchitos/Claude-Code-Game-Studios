class_name GdAssertMessages
extends Resource

const WARN_COLOR = "#EFF883"
const ERROR_COLOR = "#CD5C5C"
const VALUE_COLOR = "#1E90FF"
const SUB_COLOR :=  Color(1, 0, 0, .15)
const ADD_COLOR :=  Color(0, 1, 0, .15)


# Dictionary of control characters and their readable representations
const CONTROL_CHARS = {
	"\n": "<LF>",   # Line Feed
	"\r": "<CR>",   # Carriage Return
	"\t": "<TAB>",  # Tab
	"\b": "<BS>",   # Backspace
	"\f": "<FF>",   # Form Feed
	"\v": "<VT>",   # Vertical Tab
	"\a": "<BEL>",  # Bell
	"": "<ESC>"   # Escape
}


static func format_dict(value :Variant) -> String:
	if not value is Dictionary:
		return str(value)

	var dict_value: Dictionary = value
	if dict_value.is_empty():
		return "{ }"
	var as_rows := var_to_str(value).split("\n")
	for index in range( 1, as_rows.size()-1):
		as_rows[index] = "	" + as_rows[index]
	as_rows[-1] = "  " + as_rows[-1]
	return "\n".join(as_rows)


# improved version of InputEvent as text
static func input_event_as_text(event :InputEvent) -> String:
	var text := ""
	if event is InputEventKey:
		var key_event := event as InputEventKey
		text += """
			InputEventKey : keycode=%s (%s) pressed: %s
				physical_keycode: %s
				location: %s
				echo: %s""" % [
					key_event.keycode,
					key_event.as_text_keycode(),
					key_event.pressed,
					key_event.physical_keycode,
					key_event.location,
					key_event.echo]
	else:
		text += event.as_text()
	if event is InputEventMouse:
		var mouse_event := event as InputEventMouse
		text += """
				global_position: %s""" % mouse_event.global_position
	if event is InputEventWithModifiers:
		var mouse_event := event as InputEventWithModifiers
		text += """
				--------
				mods: %s
				shift: %s
				alt: %s
				control: %s
				meta: %s
				command: %s""" % [
					mouse_event.get_modifiers_mask(),
					mouse_event.shift_pressed,
					mouse_event.alt_pressed,
					mouse_event.ctrl_pressed,
					mouse_event.meta_pressed,
					mouse_event.command_or_control_autoremap]
	return text.dedent()


static func _colored_string_div(characters: String) -> String:
	return colored_array_div(characters.to_utf32_buffer().to_int32_array())


static func colored_array_div(characters: PackedInt32Array) -> String:
	if characters.is_empty():
		return "<empty>"
	var result := PackedInt32Array()
	var index := 0
	var missing_chars := PackedInt32Array()
	var additional_chars := PackedInt32Array()

	while index < characters.size():
		var character := characters[index]
		match character:
			GdDiffTool.DIV_ADD:
				index += 1
				@warning_ignore("return_value_discarded")
				additional_chars.append(characters[index])
			GdDiffTool.DIV_SUB:
				index += 1
				@warning_ignore("return_value_discarded")
				missing_chars.append(characters[index])
			_:
				if not missing_chars.is_empty():
					result.append_array(format_chars(missing_chars, SUB_COLOR))
					missing_chars = PackedInt32Array()
				if not additional_chars.is_empty():
					result.append_array(format_chars(additional_chars, ADD_COLOR))
					additional_chars = PackedInt32Array()
				@warning_ignore("return_value_discarded")
				result.append(character)
		index += 1

	result.append_array(format_chars(missing_chars, SUB_COLOR))
	result.append_array(format_chars(additional_chars, ADD_COLOR))
	return result.to_byte_array().get_string_from_utf32()


static func _typed_value(value :Variant) -> String:
	return GdDefaultValueDecoder.decode(value)


static func _warning(error :String) -> String:
	return "[color=%s]%s[/color]" % [WARN_COLOR, error]


static func _error(error :String) -> String:
	return "[color=%s]%s[/color]" % [ERROR_COLOR, error]


static func _nerror(number :Variant) -> String:
	match typeof(number):
		TYPE_INT:
			return "[color=%s]%d[/color]" % [ERROR_COLOR, number]
		TYPE_FLOAT:
			return "[color=%s]%f[/color]" % [ERROR_COLOR, number]
		_:
			return "[color=%s]%s[/color]" % [ERROR_COLOR, str(number)]


static func _colored(value: Variant, color: Color) -> String:
	return "[color=%s]%s[/color]" % [color.to_html(), value]


static func _colored_value(value :Variant) -> String:
	match typeof(value):
		TYPE_STRING, TYPE_STRING_NAME:
			return "'[color=%s]%s[/color]'" % [VALUE_COLOR, _colored_string_div(str(value))]
		TYPE_INT:
			return "'[color=%s]%d[/color]'" % [VALUE_COLOR, value]
		TYPE_FLOAT:
			return "'[color=%s]%s[/color]'" % [VALUE_COLOR, _typed_value(value)]
		TYPE_COLOR:
			return "'[color=%s]%s[/color]'" % [VALUE_COLOR, _typed_value(value)]
		TYPE_OBJECT:
			if value == null:
				return "'[color=%s]<null>[/color]'" % [VALUE_COLOR]
			if value is InputEvent:
				var ie: InputEvent = value
				return "[color=%s]<%s>[/color]" % [VALUE_COLOR, input_event_as_text(ie)]
			var obj_value: Object = value
			if obj_value.has_method("_to_string"):
				return "[color=%s]<%s>[/color]" % [VALUE_COLOR, str(value)]
			return "[color=%s]<%s>[/color]" % [VALUE_COLOR, obj_value.get_class()]
		TYPE_DICTIONARY:
			return "'[color=%s]%s[/color]'" % [VALUE_COLOR, format_dict(value)]
		_:
			if GdArrayTools.is_array_type(value):
				return "'[color=%s]%s[/color]'" % [VALUE_COLOR, _typed_value(value)]
			return "'[color=%s]%s[/color]'" % [VALUE_COLOR, value]



static func _index_report_as_table(index_reports :Array) -> String:
	var table := "[table=3]$cells[/table]"
	var header := "[cell][right][b]$text[/b][/right]\t[/cell]"
	var cell := "[cell][right]$text[/right]\t[/cell]"
	var cells := header.replace("$text", "Index") + header.replace("$text", "Current") + header.replace("$text", "Expected")
	for report :Variant in index_reports:
		var index :String = str(report["index"])
		var current :String = str(report["current"])
		var expected :String = str(report["expected"])
		cells += cell.replace("$text", index) + cell.replace("$text", current) + cell.replace("$text", expected)
	return table.replace("$cells", cells)



static func orphan_warning(orphans_count: int) -> String:
	return """
		%s: Found %s possible orphan nodes.
			Add %s to the end of the test to collect details.""".dedent().trim_prefix("\n") % [
		_warning("WARNING:"),
		_nerror(orphans_count),
		_colored_value("collect_orphan_node_details()")
	]

static func orphan_detected_on_suite_setup(orphans: Array[GdUnitOrphanNodeInfo]) -> String:
	return """
		%s Detected %s orphan nodes!
			[b]Verify your test suite setup.[/b]
		%s""".dedent().trim_prefix("\n") % [
		_warning("WARNING:"),
		_nerror(orphans.size()),
		_build_orphan_node_stacktrace(orphans)]


static func orphan_detected_on_test_setup(orphans: Array[GdUnitOrphanNodeInfo]) -> String:
	return """
			%s Detected %s orphan nodes on test setup!
				[b]Check before_test() and after_test()![/b]
			%s""".dedent().trim_prefix("\n") % [
				_warning("WARNING:"),
				_nerror(orphans.size()),
				_build_orphan_node_stacktrace(orphans)
			]


static func orphan_detected_on_test(orphans: Array[GdUnitOrphanNodeInfo]) -> String:
	return """
		%s Detected %s orphan nodes!
		%s""".dedent().trim_prefix("\n") % [
			_warning("WARNING:"),
			_nerror(orphans.size()),
			_build_orphan_node_stacktrace(orphans)
		]


static func _build_orphan_node_stacktrace(orphans: Array[GdUnitOrphanNodeInfo]) -> String:
	var stack_trace := "\n"
	for orphan in orphans:
		stack_trace += orphan.as_trace(orphan, true) + "\n"
	return stack_trace.indent("    ")



static func fuzzer_interuped(iterations: int, error: String) -> String:
	return "%s %s %s\n %s" % [
		_error("Found an error after"),
		_colored_value(iterations + 1),
		_error("test iterations"),
		error]


static func test_timeout(timeout :int) -> String:
	return "%s\n %s" % [_error("Timeout !"), _colored_value("Test timed out after %s" %  LocalTime.elapsed(timeout))]


static func test_session_terminated() -> String:
	return "%s" % _error("Test Session Terminated")


# gdlint:disable = mixed-tabs-and-spaces
static func test_suite_skipped(hint :String, skip_count :int) -> String:
	return """
		%s
		  Skipped %s tests
		  Reason: %s
		""".dedent().trim_prefix("\n")\
		% [_error("The Entire test-suite is skipped!"), _colored_value(skip_count), _colored_value(hint)]


static func test_skipped(hint :String) -> String:
	return """
		%s
		  Reason: %s
		""".dedent().trim_prefix("\n")\
		% [_error("This test is skipped!"), _colored_value(hint)]


static func error_not_implemented() -> String:
	return _error("Test not implemented!")


static func error_is_null(current :Variant) -> String:
	return "%s %s but was %s" % [_error("Expecting:"), _colored_value(null), _colored_value(current)]


static func error_is_not_null() -> String:
	return "%s %s" % [_error("Expecting: not to be"), _colored_value(null)]


static func error_equal(current :Variant, expected :Variant, index_reports :Array = []) -> String:
	var report := """
		%s
		 %s
		 but was
		 %s""".dedent().trim_prefix("\n") % [_error("Expecting:"), _colored_value(expected), _colored_value(current)]
	if not index_reports.is_empty():
		report += "\n\n%s\n%s" % [_error("Differences found:"), _index_report_as_table(index_reports)]
	return report


static func error_not_equal(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n not equal to\n %s" % [_error("Expecting:"), _colored_value(expected), _colored_value(current)]


static func error_not_equal_case_insensetiv(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n not equal to (case insensitiv)\n %s" % [
			_error("Expecting:"), _colored_value(expected), _colored_value(current)]


static func error_is_empty(current :Variant) -> String:
	return "%s\n must be empty but was\n %s" % [_error("Expecting:"), _colored_value(current)]


static func error_is_not_empty() -> String:
	return "%s\n must not be empty" % [_error("Expecting:")]


static func error_is_same(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n to refer to the same object\n %s" % [_error("Expecting:"), _colored_value(expected), _colored_value(current)]


@warning_ignore("unused_parameter")
static func error_not_same(_current :Variant, expected :Variant) -> String:
	return "%s\n %s" % [_error("Expecting not same:"), _colored_value(expected)]


static func error_not_same_error(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n but was\n %s" % [_error("Expecting error message:"), _colored_value(expected), _colored_value(current)]


static func error_is_instanceof(current: GdUnitResult, expected :GdUnitResult) -> String:
	return "%s\n %s\n But it was %s" % [_error("Expected instance of:"),\
		_colored_value(expected.or_else(null)), _colored_value(current.or_else(null))]


# -- Boolean Assert specific messages -----------------------------------------------------
static func error_is_true(current :Variant) -> String:
	return "%s %s but is %s" % [_error("Expecting:"), _colored_value(true), _colored_value(current)]


static func error_is_false(current :Variant) -> String:
	return "%s %s but is %s" % [_error("Expecting:"), _colored_value(false), _colored_value(current)]


# - Integer/Float Assert specific messages -----------------------------------------------------

static func error_is_even(current :Variant) -> String:
	return "%s\n %s must be even" % [_error("Expecting:"), _colored_value(current)]


static func error_is_odd(current :Variant) -> String:
	return "%s\n %s must be odd" % [_error("Expecting:"), _colored_value(current)]


static func error_is_negative(current :Variant) -> String:
	return "%s\n %s be negative" % [_error("Expecting:"), _colored_value(current)]


static func error_is_not_negative(current :Variant) -> String:
	return "%s\n %s be not negative" % [_error("Expecting:"), _colored_value(current)]


static func error_is_zero(current :Variant) -> String:
	return "%s\n equal to 0 but is %s" % [_error("Expecting:"), _colored_value(current)]


static func error_is_not_zero() -> String:
	return "%s\n not equal to 0" % [_error("Expecting:")]


static func error_is_wrong_type(current_type :Variant.Type, expected_type :Variant.Type) -> String:
	return "%s\n Expecting type %s but is %s" % [
		_error("Unexpected type comparison:"),
		_colored_value(GdObjects.type_as_string(current_type)),
		_colored_value(GdObjects.type_as_string(expected_type))]


static func error_is_value(operation :int, current :Variant, expected :Variant, expected2 :Variant = null) -> String:
	match operation:
		Comparator.EQUAL:
			return "%s\n %s but was '%s'" % [_error("Expecting:"), _colored_value(expected), _nerror(current)]
		Comparator.LESS_THAN:
			return "%s\n %s but was '%s'" % [_error("Expecting to be less than:"), _colored_value(expected), _nerror(current)]
		Comparator.LESS_EQUAL:
			return "%s\n %s but was '%s'" % [_error("Expecting to be less than or equal:"), _colored_value(expected), _nerror(current)]
		Comparator.GREATER_THAN:
			return "%s\n %s but was '%s'" % [_error("Expecting to be greater than:"), _colored_value(expected), _nerror(current)]
		Comparator.GREATER_EQUAL:
			return "%s\n %s but was '%s'" % [_error("Expecting to be greater than or equal:"), _colored_value(expected), _nerror(current)]
		Comparator.BETWEEN_EQUAL:
			return "%s\n %s\n in range between\n %s <> %s" % [
					_error("Expecting:"), _colored_value(current), _colored_value(expected), _colored_value(expected2)]
		Comparator.NOT_BETWEEN_EQUAL:
			return "%s\n %s\n not in range between\n %s <> %s" % [
					_error("Expecting:"), _colored_value(current), _colored_value(expected), _colored_value(expected2)]
	return "TODO create expected message"


static func error_is_in(current :Variant, expected :Array) -> String:
	return "%s\n %s\n is in\n %s" % [_error("Expecting:"), _colored_value(current), _colored_value(str(expected))]


static func error_is_not_in(current :Variant, expected :Array) -> String:
	return "%s\n %s\n is not in\n %s" % [_error("Expecting:"), _colored_value(current), _colored_value(str(expected))]


# - StringAssert ---------------------------------------------------------------------------------
static func error_equal_ignoring_case(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n but was\n %s (ignoring case)" % [_error("Expecting:"), _colored_value(expected), _colored_value(current)]


static func error_contains(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n do contains\n %s" % [_error("Expecting:"), _colored_value(current), _colored_value(expected)]


static func error_not_contains(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n not do contain\n %s" % [_error("Expecting:"), _colored_value(current), _colored_value(expected)]


static func error_contains_ignoring_case(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n contains\n %s\n (ignoring case)" % [_error("Expecting:"), _colored_value(current), _colored_value(expected)]


static func error_not_contains_ignoring_case(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n not do contains\n %s\n (ignoring case)" % [_error("Expecting:"), _colored_value(current), _colored_value(expected)]


static func error_starts_with(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n to start with\n %s" % [_error("Expecting:"), _colored_value(current), _colored_value(expected)]


static func error_ends_with(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n to end with\n %s" % [_error("Expecting:"), _colored_value(current), _colored_value(expected)]


static func error_has_length(current :Variant, expected: int, compare_operator :int) -> String:
	@warning_ignore("unsafe_method_access")
	var current_length :Variant = current.length() if current != null else null
	match compare_operator:
		Comparator.EQUAL:
			return "%s\n %s but was '%s' in\n %s" % [
					_error("Expecting size:"), _colored_value(expected), _nerror(current_length), _colored_value(current)]
		Comparator.LESS_THAN:
			return "%s\n %s but was '%s' in\n %s" % [
					_error("Expecting size to be less than:"), _colored_value(expected), _nerror(current_length), _colored_value(current)]
		Comparator.LESS_EQUAL:
			return "%s\n %s but was '%s' in\n %s" % [
					_error("Expecting size to be less than or equal:"), _colored_value(expected),
					_nerror(current_length), _colored_value(current)]
		Comparator.GREATER_THAN:
			return "%s\n %s but was '%s' in\n %s" % [
					_error("Expecting size to be greater than:"), _colored_value(expected),
					_nerror(current_length), _colored_value(current)]
		Comparator.GREATER_EQUAL:
			return "%s\n %s but was '%s' in\n %s" % [
					_error("Expecting size to be greater than or equal:"), _colored_value(expected),
					_nerror(current_length), _colored_value(current)]
	return "TODO create expected message"


# - ArrayAssert specific messgaes ---------------------------------------------------

static func error_arr_contains(current: Variant, expected: Variant, not_expect: Variant, not_found: Variant, by_reference: bool) -> String:
	var failure_message := "Expecting contains SAME elements:" if by_reference else "Expecting contains elements:"
	var error := "%s\n %s\n do contains (in any order)\n %s" % [
					_error(failure_message), _colored_value(current), _colored_value(expected)]
	if not is_empty(not_expect):
		error += "\nbut some elements where not expected:\n %s" % _colored_value(not_expect)
	if not is_empty(not_found):
		var prefix := "but" if is_empty(not_expect) else "and"
		error += "\n%s could not find elements:\n %s" % [prefix, _colored_value(not_found)]
	return error


static func error_arr_contains_exactly(
	current: Variant,
	expected: Variant,
	not_expect: Variant,
	not_found: Variant, compare_mode: GdObjects.COMPARE_MODE) -> String:
	var failure_message := (
		"Expecting contains exactly elements:" if compare_mode == GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST
		else "Expecting contains SAME exactly elements:"
	)
	if is_empty(not_expect) and is_empty(not_found):
		var arr_current: Array = current
		var arr_expected: Array = expected
		var diff := _find_first_diff(arr_current, arr_expected)
		return "%s\n %s\n do contains (in same order)\n %s\n but has different order %s"  % [
					_error(failure_message), _colored_value(current), _colored_value(expected), diff]

	var error := "%s\n %s\n do contains (in same order)\n %s" % [
					_error(failure_message), _colored_value(current), _colored_value(expected)]
	if not is_empty(not_expect):
		error += "\nbut some elements where not expected:\n %s" % _colored_value(not_expect)
	if not is_empty(not_found):
		var prefix := "but" if is_empty(not_expect) else "and"
		error += "\n%s could not find elements:\n %s" % [prefix, _colored_value(not_found)]
	return error


static func error_arr_contains_exactly_in_any_order(
	current: Variant,
	expected: Variant,
	not_expect: Variant,
	not_found: Variant,
	compare_mode: GdObjects.COMPARE_MODE) -> String:

	var failure_message := (
		"Expecting contains exactly elements:" if compare_mode == GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST
		else "Expecting contains SAME exactly elements:"
	)
	var error := "%s\n %s\n do contains exactly (in any order)\n %s" % [
					_error(failure_message), _colored_value(current), _colored_value(expected)]
	if not is_empty(not_expect):
		error += "\nbut some elements where not expected:\n %s" % _colored_value(not_expect)
	if not is_empty(not_found):
		var prefix := "but" if is_empty(not_expect) else "and"
		error += "\n%s could not find elements:\n %s" % [prefix, _colored_value(not_found)]
	return error


static func error_arr_not_contains(current: Variant, expected: Variant, found: Variant, compare_mode: GdObjects.COMPARE_MODE) -> String:
	var failure_message := "Expecting:" if compare_mode == GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST else "Expecting SAME:"
	var error := "%s\n %s\n do not contains\n %s" % [
					_error(failure_message), _colored_value(current), _colored_value(expected)]
	if not is_empty(found):
		error += "\n but found elements:\n %s" % _colored_value(found)
	return error


# - DictionaryAssert specific messages ----------------------------------------------
static func error_contains_keys(current :Array, expected :Array, keys_not_found :Array, compare_mode :GdObjects.COMPARE_MODE) -> String:
	var failure := (
		"Expecting contains keys:" if compare_mode == GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST
		else "Expecting contains SAME keys:"
	)
	return "%s\n %s\n to contains:\n %s\n but can't find key's:\n %s" % [
			_error(failure), _colored_value(current), _colored_value(expected), _colored_value(keys_not_found)]


static func error_not_contains_keys(current :Array, expected :Array, keys_not_found :Array, compare_mode :GdObjects.COMPARE_MODE) -> String:
	var failure := (
		"Expecting NOT contains keys:" if compare_mode == GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST
		else "Expecting NOT contains SAME keys"
	)
	return "%s\n %s\n do not contains:\n %s\n but contains key's:\n %s" % [
			_error(failure), _colored_value(current), _colored_value(expected), _colored_value(keys_not_found)]


static func error_contains_key_value(key :Variant, value :Variant, current_value :Variant, compare_mode :GdObjects.COMPARE_MODE) -> String:
	var failure := (
		"Expecting contains key and value:" if compare_mode == GdObjects.COMPARE_MODE.PARAMETER_DEEP_TEST
		else "Expecting contains SAME key and value:"
	)
	return "%s\n %s : %s\n but contains\n %s : %s" % [
			_error(failure), _colored_value(key), _colored_value(value), _colored_value(key), _colored_value(current_value)]


# - ResultAssert specific errors ----------------------------------------------------
static func error_result_is_empty(current :GdUnitResult) -> String:
	return _result_error_message(current, GdUnitResult.EMPTY)


static func error_result_is_success(current :GdUnitResult) -> String:
	return _result_error_message(current, GdUnitResult.SUCCESS)


static func error_result_is_warning(current :GdUnitResult) -> String:
	return _result_error_message(current, GdUnitResult.WARN)


static func error_result_is_error(current :GdUnitResult) -> String:
	return _result_error_message(current, GdUnitResult.ERROR)


static func error_result_has_message(current :String, expected :String) -> String:
	return "%s\n %s\n but was\n %s." % [_error("Expecting:"), _colored_value(expected), _colored_value(current)]


static func error_result_has_message_on_success(expected :String) -> String:
	return "%s\n %s\n but the GdUnitResult is a success." % [_error("Expecting:"), _colored_value(expected)]


static func error_result_is_value(current :Variant, expected :Variant) -> String:
	return "%s\n %s\n but was\n %s." % [_error("Expecting to contain same value:"), _colored_value(expected), _colored_value(current)]


static func _result_error_message(current :GdUnitResult, expected_type :int) -> String:
	if current == null:
		return _error("Expecting the result must be a %s but was <null>." % result_type(expected_type))
	if current.is_success():
		return _error("Expecting the result must be a %s but was SUCCESS." % result_type(expected_type))
	var error := "Expecting the result must be a %s but was %s:" % [result_type(expected_type), result_type(current._state)]
	return "%s\n %s" % [_error(error), _colored_value(result_message(current))]


static func error_interrupted(func_name :String, expected :Variant, elapsed :String) -> String:
	func_name = humanized(func_name)
	if expected == null:
		return "%s %s but timed out after %s" % [_error("Expected:"), func_name, elapsed]
	return "%s %s %s but timed out after %s" % [_error("Expected:"), func_name, _colored_value(expected), elapsed]


static func error_wait_signal(signal_name :String, args :Array, elapsed :String) -> String:
	if args.is_empty():
		return "%s %s but timed out after %s" % [
				_error("Expecting emit signal:"), _colored_value(signal_name + "()"), elapsed]
	return "%s %s but timed out after %s" % [
			_error("Expecting emit signal:"), _colored_value(signal_name + "(" + str(args) + ")"), elapsed]


static func error_signal_emitted(signal_name :String, args :Array, elapsed :String) -> String:
	if args.is_empty():
		return "%s %s but is emitted after %s" % [
				_error("Expecting do not emit signal:"), _colored_value(signal_name + "()"), elapsed]
	return "%s %s but is emitted after %s" % [
			_error("Expecting do not emit signal:"), _colored_value(signal_name + "(" + str(args) + ")"), elapsed]


static func error_await_signal_on_invalid_instance(source :Variant, signal_name :String, args :Array) -> String:
	return "%s\n await_signal_on(%s, %s, %s)" % [
			_error("Invalid source! Can't await on signal:"), _colored_value(source), signal_name, args]


static func result_type(type :int) -> String:
	match type:
		GdUnitResult.SUCCESS: return "SUCCESS"
		GdUnitResult.WARN: return "WARNING"
		GdUnitResult.ERROR: return "ERROR"
		GdUnitResult.EMPTY: return "EMPTY"
	return "UNKNOWN"


static func result_message(result :GdUnitResult) -> String:
	match result._state:
		GdUnitResult.SUCCESS: return ""
		GdUnitResult.WARN: return result.warn_message()
		GdUnitResult.ERROR: return result.error_message()
		GdUnitResult.EMPTY: return ""
	return "UNKNOWN"
# -----------------------------------------------------------------------------------

# - Spy|Mock specific errors ----------------------------------------------------
static func error_no_more_interactions(summary :Dictionary) -> String:
	var interactions := PackedStringArray()
	for args :Array in summary.keys():
		var times :int = summary[args]
		@warning_ignore("return_value_discarded")
		interactions.append(_format_arguments(args, times))
	return "%s\n%s\n%s" % [_error("Expecting no more interactions!"), _error("But found interactions on:"), "\n".join(interactions)]


static func error_validate_interactions(current_interactions: Dictionary, expected_interactions: Dictionary) -> String:
	var collected_interactions := PackedStringArray()
	for args: Array in current_interactions.keys():
		var times: int = current_interactions[args]
		@warning_ignore("return_value_discarded")
		collected_interactions.append(_format_arguments(args, times))

	var arguments: Array = expected_interactions.keys()[0]
	var interactions: int = expected_interactions.values()[0]
	var expected_interaction := _format_arguments(arguments, interactions)
	return "%s\n%s\n%s\n%s" % [
			_error("Expecting interaction on:"), expected_interaction, _error("But found interactions on:"), "\n".join(collected_interactions)]


static func _format_arguments(args :Array, times :int) -> String:
	var fname :String = args[0]
	var fargs := args.slice(1) as Array
	var typed_args := _to_typed_args(fargs)
	var fsignature := _colored_value("%s(%s)" % [fname, ", ".join(typed_args)])
	return "	%s	%d time's" % [fsignature, times]


static func _to_typed_args(args :Array) -> PackedStringArray:
	var typed := PackedStringArray()
	for arg :Variant in args:
		@warning_ignore("return_value_discarded")
		typed.append(_format_arg(arg) + " :" + GdObjects.type_as_string(typeof(arg)))
	return typed


static func _format_arg(arg :Variant) -> String:
	if arg is InputEvent:
		var ie: InputEvent = arg
		return input_event_as_text(ie)
	return str(arg)


static func _find_first_diff(left :Array, right :Array) -> String:
	for index in left.size():
		var l :Variant = left[index]
		var r :Variant = "<no entry>" if index >= right.size() else right[index]
		if not GdObjects.equals(l, r):
			return "at position %s\n '%s' vs '%s'" % [_colored_value(index), _typed_value(l), _typed_value(r)]
	return ""


static func error_has_size(current :Variant, expected: int) -> String:
	@warning_ignore("unsafe_method_access")
	var current_size :Variant = null if current == null else current.size()
	return "%s\n %s\n but was\n %s" % [_error("Expecting size:"), _colored_value(expected), _colored_value(current_size)]


static func error_contains_exactly(current: Array, expected: Array) -> String:
	return "%s\n %s\n but was\n %s" % [_error("Expecting exactly equal:"), _colored_value(expected), _colored_value(current)]


static func format_chars(characters: PackedInt32Array, type: Color) -> PackedInt32Array:
	if characters.size() == 0:# or characters[0] == 10:
		return characters

	# Replace each control character with its readable form
	var formatted_text := characters.to_byte_array().get_string_from_utf32()
	for control_char: String in CONTROL_CHARS:
		var replace_text: String = CONTROL_CHARS[control_char]
		formatted_text = formatted_text.replace(control_char, replace_text)

	# Handle special ASCII control characters (0x00-0x1F, 0x7F)
	var ascii_text := ""
	for i in formatted_text.length():
		var character := formatted_text[i]
		var code := character.unicode_at(0)
		if code < 0x20 and not CONTROL_CHARS.has(character):  # Control characters not handled above
			ascii_text += "<0x%02X>" % code
		elif code == 0x7F:  # DEL character
			ascii_text += "<DEL>"
		else:
			ascii_text += character

	var message := "[bgcolor=#%s][color=white]%s[/color][/bgcolor]" % [
		type.to_html(),
		ascii_text
	]

	var result := PackedInt32Array()
	result.append_array(message.to_utf32_buffer().to_int32_array())
	return result


static func format_invalid(value :String) -> String:
	return "[bgcolor=#%s][color=with]%s[/color][/bgcolor]" % [SUB_COLOR.to_html(), value]


static func humanized(value :String) -> String:
	return value.replace("_", " ")


static func build_failure_message(failure :String, additional_failure_message: String, custom_failure_message: String) -> String:
	var message := failure if custom_failure_message.is_empty() else custom_failure_message
	if additional_failure_message.is_empty():
		return message
	return """
		%s
		[color=LIME_GREEN][b]Additional info:[/b][/color]
		 %s""".dedent().trim_prefix("\n") % [message, additional_failure_message]


static func is_empty(value: Variant) -> bool:
	var arry_value: Array = value
	return arry_value != null and arry_value.is_empty()
