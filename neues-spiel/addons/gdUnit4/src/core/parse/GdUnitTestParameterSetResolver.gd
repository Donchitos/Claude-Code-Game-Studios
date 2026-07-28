## @deprecated see GdFunctionParameterSetResolver
class_name GdUnitTestParameterSetResolver
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


func is_parameterized() -> bool:
	return _fd.is_parameterized()


func is_parameter_sets_static() -> bool:
	return _is_static


func is_parameter_set_static(index: int) -> bool:
	return _is_static and _static_sets_by_index.get(index, false)


# validates the given arguments are complete and matches to required input fields of the test function
func validate(parameter_sets: Array, parameter_set_index: int) -> GdUnitResult:
	if parameter_sets.size() < parameter_set_index:
		return GdUnitResult.error("Internal error: the resolved paremeterset has invalid size.")

	var input_values: Array = parameter_sets[parameter_set_index]
	if input_values == null:
		return GdUnitResult.error("The parameter set '%s' must be an Array!" % parameter_sets[parameter_set_index])

	# check given parameter set with test case arguments
	var input_arguments := _fd.args()
	var expected_arg_count := input_arguments.size() - 1 #(-1 we exclude the parameter set itself)
	var current_arg_count := input_values.size()
	if current_arg_count != expected_arg_count:
		var arg_names := input_arguments\
			.filter(func(arg: GdFunctionArgument) -> bool: return not arg.is_parameter_set())\
			.map(func(arg: GdFunctionArgument) -> String: return str(arg))

		return  GdUnitResult.error("""
			The test data set at index (%d) does not match the expected test arguments:
				test function: [color=snow]func test...(%s)[/color]
				test input values: [color=snow]%s[/color]
			"""
			.dedent() % [parameter_set_index, ",".join(arg_names), input_values])
	return GdUnitTestParameterSetResolver.validate_parameter_types(input_arguments, input_values)


static func validate_parameter_types(input_arguments: Array[GdFunctionArgument], input_values: Array) -> GdUnitResult:
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
			return GdUnitResult.error("""
				The test data value does not match the expected input type!
					input value: [color=snow]'%s', <%s>[/color]
					expected argument: [color=snow]%s[/color]
				"""
				.dedent() % [input_value, type_string(input_value_type), str(input_param)])
	return GdUnitResult.success("No errors found.")


func _extract_property_names(node :Node) -> PackedStringArray:
	return node.get_property_list()\
		.map(func(property :Dictionary) -> String: return property["name"])\
		.filter(func(property :String) -> bool: return !EXCLUDE_PROPERTIES_TO_COPY.has(property))


# tests if the test property set contains an property reference by name, if not the parameter set holds only static values
func _is_static_parameter_set(parameters :String, property_names :PackedStringArray) -> bool:
	for property_name in property_names:
		if parameters.contains(property_name):
			_is_static = false
			return false
	return true


# extracts the arguments from the given test case, using kind of reflection solution
# to restore the parameters from a string representation to real instance type
func load_parameter_sets(test_suite: Node) -> GdUnitResult:
	var source_script: Script = test_suite.get_script()
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
		return GdUnitResult.error("Extracting test parameters failed! Script loading error: %s" % error_string(result))
	var instance :Object = script.new()
	GdUnitTestParameterSetResolver.copy_properties(test_suite, instance)
	(instance as Node).queue_free()
	var parameter_sets: Array = instance.call("__extract_test_parameters")
	fixure_typed_parameters(parameter_sets, _fd.args())
	return GdUnitResult.success(parameter_sets)


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
