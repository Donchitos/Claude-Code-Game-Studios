class_name GdFunctionArgument
extends RefCounted


const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")
const UNDEFINED: String = "<-NO_ARG->"
const ARG_PARAMETERIZED_TEST := ["test_parameters", "_test_parameters"]

static var _fuzzer_regex: RegEx
static var _cleanup_leading_spaces: RegEx
static var _fix_comma_space: RegEx

var _name: String
var _type: int
var _type_hint: int
var _default_value: Variant
var _parameter_sets: PackedStringArray = []


func _init(p_name: String, p_type: int, value: Variant = UNDEFINED, p_type_hint: int = TYPE_NIL) -> void:
	_init_static_variables()
	_name = p_name
	_type = p_type
	_type_hint = p_type_hint
	if value != null and p_name in ARG_PARAMETERIZED_TEST:
		_parameter_sets = _parse_parameter_set(str(value))
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
		_parameter_sets = _parse_parameter_set(value)
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


static func get_parameter_set(parameters :Array[GdFunctionArgument]) -> GdFunctionArgument:
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


func _parse_parameter_set(input :String) -> PackedStringArray:
	if not input.contains("["):
		return []

	input = _cleanup_leading_spaces.sub(input, "", true)
	input = input.replace("\n", "").strip_edges().trim_prefix("[").trim_suffix("]").trim_prefix("]")
	var single_quote := false
	var double_quote := false
	var array_end := 0
	var current_index := 0
	var output :PackedStringArray = []
	var buf := input.to_utf8_buffer()
	var collected_characters: = PackedByteArray()
	var matched :bool = false

	for c in buf:
		current_index += 1
		matched = current_index == buf.size()
		@warning_ignore("return_value_discarded")
		collected_characters.push_back(c)

		match c:
			# ' ': ignore spaces between array elements
			32: if array_end == 0 and (not double_quote and not single_quote):
					collected_characters.remove_at(collected_characters.size()-1)
			# ',': step over array element seperator ','
			44: if array_end == 0:
					matched = true
					collected_characters.remove_at(collected_characters.size()-1)
			# '`':
			39: single_quote = !single_quote
			# '"':
			34: if not single_quote: double_quote = !double_quote
			# '['
			91: if not double_quote and not single_quote: array_end +=1 # counts array open
			# ']'
			93: if not double_quote and not single_quote: array_end -=1 # counts array closed

		# if array closed than collect the element
		if matched:
			var parameters := _fix_comma_space.sub(collected_characters.get_string_from_utf8(), ", ", true)
			if not parameters.is_empty():
				@warning_ignore("return_value_discarded")
				output.append(parameters)
			collected_characters.clear()
			matched = false
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
