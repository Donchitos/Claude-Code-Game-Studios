class_name GdUnitExpressionRunner
extends RefCounted

const CLASS_TEMPLATE = """
class_name _ExpressionRunner extends '${clazz_path}'

func __run_expression() -> Variant:
	return $expression

"""

var constructor_args_regex := RegEx.create_from_string("new\\((?<args>.*)\\)")


func execute(src_script: GDScript, value: Variant) -> Variant:
	if typeof(value) != TYPE_STRING:
		return value

	var expression: String = value
	var parameter_map := src_script.get_script_constant_map()
	for key: String in parameter_map.keys():
		var parameter_value: Variant = parameter_map[key]
		# check we need to construct from inner class
		# we need to use the original class instance from the script_constant_map otherwise we run into a runtime error
		if expression.begins_with(key + ".new") and parameter_value is GDScript:
			var object: GDScript = parameter_value
			var args := build_constructor_arguments(parameter_map, expression.substr(expression.find("new")))
			if args.is_empty():
				return object.new()
			return object.callv("new", args)

	var script := GDScript.new()
	var resource_path := "res://addons/gdUnit4/src/Fuzzers.gd" if src_script.resource_path.is_empty() else src_script.resource_path
	script.source_code = CLASS_TEMPLATE.dedent()\
		.replace("${clazz_path}", resource_path)\
		.replace("$expression", expression)
	#script.take_over_path(resource_path)
	@warning_ignore("return_value_discarded")
	script.reload(true)
	var runner: Object = script.new()
	if runner.has_method("queue_free"):
		(runner as Node).queue_free()
	@warning_ignore("unsafe_method_access")
	return runner.__run_expression()


func build_constructor_arguments(parameter_map: Dictionary, expression: String) -> Array[Variant]:
	var result := constructor_args_regex.search(expression)
	var extracted_arguments := result.get_string("args").strip_edges()
	if extracted_arguments.is_empty():
		return []
	var arguments :Array = extracted_arguments.split(",")
	return arguments.map(func(argument: String) -> Variant:
		var value := argument.strip_edges()

		# is argument an constant value
		if parameter_map.has(value):
			return parameter_map[value]
		# is typed named value like Vector3.ONE
		for type:int in GdObjects.TYPE_AS_STRING_MAPPINGS:
			var type_as_string:String = GdObjects.TYPE_AS_STRING_MAPPINGS[type]
			if value.begins_with(type_as_string):
				return type_convert(value, type)
		# is value a string
		if value.begins_with("'") or value.begins_with('"'):
			return value.trim_prefix("'").trim_suffix("'").trim_prefix('"').trim_suffix('"')
		# fallback to default value converting
		return str_to_var(value)
	)


func to_fuzzer(src_script: GDScript, expression: String) -> Fuzzer:
	@warning_ignore("unsafe_cast")
	return execute(src_script, expression) as Fuzzer
