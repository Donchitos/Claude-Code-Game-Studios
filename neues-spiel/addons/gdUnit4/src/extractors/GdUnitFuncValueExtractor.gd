# This class defines a value extractor by given function name and args
class_name GdUnitFuncValueExtractor
extends GdUnitValueExtractor

var _func_names :PackedStringArray
var _args :Array

func _init(func_name :String, p_args :Array) -> void:
	_func_names = func_name.split(".")
	_args = p_args


func func_names() -> PackedStringArray:
	return _func_names


func args() -> Array:
	return _args


# Extracts a value by given `func_name` and `args`,
# Allows to use a chained list of functions setarated ba a dot.
#  e.g. "func_a.func_b.name"
#  do calls instance.func_a().func_b().name() and returns finally the name
# If a function returns an array, all elements will by collected in a array
#  e.g. "get_children.get_name" checked a node
#  do calls node.get_children() for all childs get_name() and returns all names in an array
#
# if the value not a Object or not accesible be `func_name` the value is converted to `"n.a."`
# expecing null values
func extract_value(value: Variant) -> Variant:
	if value == null:
		return null
	for func_name in func_names():
		if GdArrayTools.is_array_type(value):
			var values := Array()
			@warning_ignore("unsafe_cast")
			for element: Variant in (value as Array):
				values.append(_call_func(element, func_name))
			value = values
		else:
			value = _call_func(value, func_name)
		var type := typeof(value)
		if type == TYPE_STRING_NAME:
			return str(value)
		if type == TYPE_STRING and value == "n.a.":
			return value
	return value


func _call_func(value :Variant, func_name :String) -> Variant:
	# for array types we need to call explicit by function name, using funcref is only supported for Objects
	# TODO extend to all array functions
	if GdArrayTools.is_array_type(value) and func_name == "empty":
		@warning_ignore("unsafe_cast")
		return (value as Array).is_empty()

	if is_instance_valid(value):
		# extract from function
		var obj_value: Object = value
		if obj_value.has_method(func_name):
			var extract := Callable(obj_value, func_name)
			if extract.is_valid():
				return obj_value.call(func_name) if args().is_empty() else obj_value.callv(func_name, args())
		else:
			# if no function exists than try to extract form parmeters
			var parameter: Variant = obj_value.get(func_name)
			if parameter != null:
				return parameter
	# nothing found than return 'n.a.'
	if GdUnitSettings.is_verbose_assert_warnings():
		push_warning("Extracting value from element '%s' by func '%s' failed! Converting to \"n.a.\"" % [value, func_name])
	return "n.a."
