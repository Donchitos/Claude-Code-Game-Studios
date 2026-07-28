class_name GdFunctionParameterSetResolver
extends RefCounted

const CLASS_TEMPLATE = """
class_name _ParameterExtractor extends '${clazz_path}'

func __extract_test_parameters() -> Array:
	return ${test_params}

"""

const EXCLUDE_PROPERTIES_TO_COPY = [
	"script",
	"type",
	"Node",
	"_import_path"]


var _fd: GdFunctionDescriptor
var _static_sets_by_index := {}
var _is_static := true

func _init(fd: GdFunctionDescriptor) -> void:
	_fd = fd


func resolve_test_cases(script: GDScript) -> Array[GdUnitTestCase]:
	if not is_parameterized():
		return [GdUnitTestCase.from(script.resource_path, _fd.source_path(), _fd.line_number(), _fd.name())]
	return extract_test_cases_by_reflection(script)


func is_parameterized() -> bool:
	return _fd.is_parameterized()


func is_parameter_sets_static() -> bool:
	return _is_static


func is_parameter_set_static(index: int) -> bool:
	return _is_static and _static_sets_by_index.get(index, false)


# validates the given arguments are complete and matches to required input fields of the test function
func validate(input_value_set: Array) -> String:
	var input_arguments := _fd.args()
	# check given parameter set with test case arguments
	var expected_arg_count := input_arguments.size() - 1
	for input_values :Variant in input_value_set:
		var parameter_set_index := input_value_set.find(input_values)
		if input_values is Array:
			var arr_values: Array = input_values
			var current_arg_count := arr_values.size()
			if current_arg_count != expected_arg_count:
				return "\n	The parameter set at index [%d] does not match the expected input parameters!\n	The test case requires [%d] input parameters, but the set contains [%d]" % [parameter_set_index, expected_arg_count, current_arg_count]
			var error := validate_parameter_types(input_arguments, arr_values, parameter_set_index)
			if not error.is_empty():
				return error
		else:
			return "\n	The parameter set at index [%d] does not match the expected input parameters!\n	Expecting an array of input values." % parameter_set_index
	return ""


static func validate_parameter_types(input_arguments: Array, input_values: Array, parameter_set_index: int) -> String:
	for i in input_arguments.size():
		var input_param: GdFunctionArgument = input_arguments[i]
		# only check the test input arguments
		if input_param.is_parameter_set():
			continue
		var input_param_type := input_param.type()
		var input_value :Variant = input_values[i]
		var input_value_type := typeof(input_value)
		# input parameter is not typed or is Variant we skip the type test
		if input_param_type == TYPE_NIL or input_param_type == GdObjects.TYPE_VARIANT:
			continue
		# is input type enum allow int values
		if input_param_type == GdObjects.TYPE_VARIANT and input_value_type == TYPE_INT:
			continue
		# allow only equal types and object == null
		if input_param_type == TYPE_OBJECT and input_value_type == TYPE_NIL:
			continue
		if input_param_type != input_value_type:
			return "\n	The parameter set at index [%d] does not match the expected input parameters!\n	The value '%s' does not match the required input parameter <%s>." % [parameter_set_index, input_value, input_param]
	return ""


func extract_test_cases_by_reflection(script: GDScript) -> Array[GdUnitTestCase]:
	var source: Node = script.new()
	source.queue_free()

	var fa := GdFunctionArgument.get_parameter_set(_fd.args())
	var parameter_sets := fa.parameter_sets()
	# if no parameter set detected we need to resolve it by using reflection
	if parameter_sets.size() == 0:
		_is_static = false
		return _extract_test_cases_by_reflection(source, script)
	else:
		var test_cases: Array[GdUnitTestCase] = []
		var property_names := _extract_property_names(source)
		for parameter_set_index in parameter_sets.size():
			var parameter_set := parameter_sets[parameter_set_index]
			_static_sets_by_index[parameter_set_index] = _is_static_parameter_set(parameter_set, property_names)
			@warning_ignore("return_value_discarded")
			test_cases.append(GdUnitTestCase.from(script.resource_path, _fd.source_path(), _fd.line_number(), _fd.name(), parameter_set_index, parameter_set))
			parameter_set_index += 1
		return test_cases


func _extract_property_names(source: Node) -> PackedStringArray:
	return source.get_property_list()\
		.map(func(property :Dictionary) -> String: return property["name"])\
		.filter(func(property :String) -> bool: return !EXCLUDE_PROPERTIES_TO_COPY.has(property))


# tests if the test property set contains an property reference by name, if not the parameter set holds only static values
func _is_static_parameter_set(parameters :String, property_names :PackedStringArray) -> bool:
	for property_name in property_names:
		if parameters.contains(property_name):
			_is_static = false
			return false
	return true


func _extract_test_cases_by_reflection(source: Node, script: GDScript) -> Array[GdUnitTestCase]:
	var parameter_sets := load_parameter_sets(source)
	var test_cases: Array[GdUnitTestCase] = []
	for index in parameter_sets.size():
		var parameter_set := str(parameter_sets[index])
		@warning_ignore("return_value_discarded")
		test_cases.append(GdUnitTestCase.from(script.resource_path, _fd.source_path(), _fd.line_number(), _fd.name(), index, parameter_set))
	return test_cases


# extracts the arguments from the given test case, using kind of reflection solution
# to restore the parameters from a string representation to real instance type
func load_parameter_sets(source: Node) -> Array:
	var source_script: GDScript = source.get_script()
	var parameter_arg := GdFunctionArgument.get_parameter_set(_fd.args())
	var source_code := CLASS_TEMPLATE \
		.replace("${clazz_path}", source_script.resource_path) \
		.replace("${test_params}", parameter_arg.value_as_string())
	var script := GDScript.new()
	script.source_code = source_code
	# enable this lines only for debuging
	#script.resource_path = GdUnitFileAccess.create_temp_dir("parameter_extract") + "/%s__.gd" % test_case.get_name()
	#DirAccess.remove_absolute(script.resource_path)
	#ResourceSaver.save(script, script.resource_path)
	var result := script.reload()
	if result != OK:
		push_error("Extracting test parameters failed! Script loading error: %s" % result)
		return []
	var instance: Node = script.new()
	GdFunctionParameterSetResolver.copy_properties(source, instance)
	instance.queue_free()
	var parameter_sets: Array = instance.call("__extract_test_parameters")
	return fixure_typed_parameters(parameter_sets, _fd.args())


func fixure_typed_parameters(parameter_sets: Array, arg_descriptors: Array[GdFunctionArgument]) -> Array:
	for parameter_set_index in parameter_sets.size():
		var parameter_set: Array = parameter_sets[parameter_set_index]
		# run over all function arguments
		for parameter_index in parameter_set.size():
			var parameter :Variant = parameter_set[parameter_index]
			var arg_descriptor: GdFunctionArgument = arg_descriptors[parameter_index]
			if parameter is Array:
				var as_array: Array = parameter
				# we need to convert the untyped array to the expected typed version
				if arg_descriptor.is_typed_array():
					parameter_set[parameter_index] = Array(as_array, arg_descriptor.type_hint(), "", null)
	return parameter_sets


static func copy_properties(source: Object, dest: Object) -> void:
	for property in source.get_property_list():
		var property_name :String = property["name"]
		var property_value :Variant = source.get(property_name)
		if EXCLUDE_PROPERTIES_TO_COPY.has(property_name):
			continue
		#if dest.get(property_name) == null:
		#	prints("|%s|" % property_name, source.get(property_name))

		# check for invalid name property
		if property_name == "name" and property_value == "":
			dest.set(property_name, "<empty>");
			continue
		dest.set(property_name, property_value)
