class_name GdFunctionArgument
extends RefCounted


const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")
const UNDEFINED: String = "<-NO_ARG->"
const ARG_PARAMETERIZED_TEST := ["test_parameters", "_test_parameters"]

var _name: String
var _type: int
var _type_hint: int
var _default_value: Variant
var _parameter_sets: PackedStringArray = []

static var _fuzzer_regex: RegEx
static var _cleanup_leading_spaces := RegEx.create_from_string("(?m)^[ \t]+")
static var _fix_comma_space := RegEx.create_from_string(""", {0,}\t{0,}(?=(?:[^"]*"[^"]*")*[^"]*$)(?!\\s)""")


func _init(p_name: String, p_type: int, value: Variant = UNDEFINED, p_type_hint: int = TYPE_NIL) -> void:
	_init_static_variables()
	_name = p_name
	_type = p_type
	_type_hint = p_type_hint
	if value != null and p_name in ARG_PARAMETERIZED_TEST:
		_parameter_sets = _parse_parameters(str(value))
	_default_value = value
	# is argument a fuzzer?
	if _type == TYPE_OBJECT and _fuzzer_regex.search(_name):
		_type = GdObjects.TYPE_FUZZER


func _init_static_variables() -> void:
	if _fuzzer_regex == null:
		_fuzzer_regex = GdUnitTools.to_regex("((?!(fuzzer_(seed|iterations)))fuzzer?\\w+)( ?+= ?+| ?+:= ?+| ?+:Fuzzer ?+= ?+|)")
		_cleanup_leading_spaces = RegEx.create_from_string("(?m)^[ \t]+")
		_fix_comma_space = RegEx.create_from_string(""", {0,}\t{0,}(?=(?:[^"]*"[^"]*")*[^"]*$)(?!\\s)""")


func name() -> String:
	return _name


func default() -> Variant:
	return type_convert(_default_value, _type)


func set_value(value: String) -> void:
	# we onle need to apply default values for Objects, all others are provided by the method descriptor
	if _type == GdObjects.TYPE_FUZZER:
		_default_value = value
		return
	if _name in ARG_PARAMETERIZED_TEST:
		_parameter_sets = _parse_parameters(value)
		_default_value = value
		return

	if _type == TYPE_NIL or _type == GdObjects.TYPE_VARIANT:
		_type = _extract_value_type(value)
		if _type == GdObjects.TYPE_VARIANT and _default_value == null:
			_default_value = value
	if _default_value == null:
		match _type:
			TYPE_DICTIONARY:
				_default_value = as_dictionary(value)
			TYPE_ARRAY:
				_default_value = as_array(value)
			GdObjects.TYPE_FUZZER:
				_default_value = value
			_:
				_default_value = str_to_var(value)
				# if converting fails assign the original value without converting
				if _default_value == null and value != null:
					_default_value = value
		#prints("set default_value: ", _default_value, "with type %d" % _type, " from original: '%s'" % value)


func _extract_value_type(value: String) -> int:
	if value != UNDEFINED:
		if _fuzzer_regex.search(_name):
			return GdObjects.TYPE_FUZZER
		if value.rfind(")") == value.length()-1:
			return GdObjects.TYPE_FUNC
	return _type


func value_as_string() -> String:
	if has_default():
		return GdDefaultValueDecoder.decode_typed(_type, _default_value)
	return ""


func plain_value() -> Variant:
	return _default_value


func type() -> int:
	return _type


func type_hint() -> int:
	return _type_hint


func has_default() -> bool:
	return not is_same(_default_value, UNDEFINED)


func is_typed_array() -> bool:
	return _type == TYPE_ARRAY and _type_hint != TYPE_NIL


func is_parameter_set() -> bool:
	return _name in ARG_PARAMETERIZED_TEST


func parameter_sets() -> PackedStringArray:
	return _parameter_sets


static func get_parameter_set(parameters: Array[GdFunctionArgument]) -> GdFunctionArgument:
	for current in parameters:
		if current != null and current.is_parameter_set():
			return current
	return null


func _to_string() -> String:
	var s := _name
	if _type != TYPE_NIL:
		s += ": " + GdObjects.type_as_string(_type)
	if _type_hint != TYPE_NIL:
		s += "[%s]" % GdObjects.type_as_string(_type_hint)
	if has_default():
		s += "=" + value_as_string()
	return s


static func _parse_parameters(input: String) -> PackedStringArray:
	if not input.contains("["):
		return []

	input = _cleanup_leading_spaces.sub(input, "", true)
	input = input.strip_edges().trim_prefix("[").trim_suffix("]").trim_prefix("]")
	var single_quote := false
	var double_quote := false
	var output := PackedStringArray()
	var buf := input.to_utf8_buffer()

	if buf.size() == 0:
		return output

	var work := PackedByteArray()
	work.resize(buf.size())
	var wp := 0
	var array_depth := 0
	var func_call_depth := 0
	var after_comma := false
	var escape_next := false

	for c: int in buf:
		var in_string: bool = single_quote or double_quote

		# escaped character inside a string, e.g. `\"` or `\'`: copy through as-is and
		# do not let it toggle the quote state
		if escape_next:
			work[wp] = c; wp += 1
			escape_next = false
			continue

		# '\': mark the next character as escaped, only meaningful inside a quoted string
		if c == 92 and in_string:
			work[wp] = c; wp += 1
			escape_next = true
			continue

		# ' ': ignore spaces between array elements
		if c == 32:
			if in_string:
				work[wp] = c; wp += 1; after_comma = false
			elif (array_depth > 0 or func_call_depth > 0) and not after_comma:
				work[wp] = c; wp += 1

		# '\n': strip newlines outside quoted strings, preserve inside
		elif c == 10:
			if in_string:
				work[wp] = c; wp += 1

		# ',': step over array element seperator ','
		elif c == 44:
			if array_depth == 0 and func_call_depth == 0:
				if wp > 0:
					@warning_ignore("return_value_discarded")
					output.append(work.slice(0, wp).get_string_from_utf8())
					wp = 0
				after_comma = false
			else:
				work[wp] = c; wp += 1
				if not in_string:
					after_comma = true

		# '\'':
		elif c == 39:
			if not double_quote:
				single_quote = not single_quote
			if after_comma:
				work[wp] = 32; wp += 1; after_comma = false
			work[wp] = c; wp += 1

		# '"':
		elif c == 34:
			if not single_quote:
				double_quote = not double_quote
			if after_comma:
				work[wp] = 32; wp += 1; after_comma = false
			work[wp] = c; wp += 1

		# '['
		elif c == 91:
			if not in_string:
				array_depth += 1
			if after_comma:
				work[wp] = 32; wp += 1; after_comma = false
			work[wp] = c; wp += 1

		# ']'
		elif c == 93:
			if not in_string:
				array_depth -= 1
			after_comma = false
			work[wp] = c; wp += 1

		# '('
		elif c == 40:
			if not in_string:
				func_call_depth += 1
			if after_comma:
				work[wp] = 32; wp += 1; after_comma = false
			work[wp] = c; wp += 1

		# ')'
		elif c == 41:
			if not in_string:
				func_call_depth -= 1
			after_comma = false
			work[wp] = c; wp += 1
		else:
			if after_comma:
				work[wp] = 32; wp += 1; after_comma = false
			work[wp] = c; wp += 1

	if wp > 0:
		@warning_ignore("return_value_discarded")
		output.append(work.slice(0, wp).get_string_from_utf8())
	return output


## value converters
func as_array(value: String) -> Array:
	if value == "Array()" or value == "[]":
		return []

	if value.begins_with("Array("):
		value = value.lstrip("Array(").rstrip(")")
	if value.begins_with("["):
		return str_to_var(value)
	return []


func as_dictionary(value: String) -> Dictionary:
	if value == "Dictionary()":
		return {}
	if value.begins_with("Dictionary("):
		value = value.lstrip("Dictionary(").rstrip(")")
	if value.begins_with("{"):
		return str_to_var(value)
	return {}
