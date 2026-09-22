class_name GdInlineParameterSetResolver
extends GdParameterSetResolver


const EXCLUDE_PROPERTIES_TO_COPY := [
	"script",
	"type",
	"Node",
	"_import_path"]


const EXPRESSION_TEMPLATE := """
extends '${clazz_path}'

func __run_expression() -> Array:
	return ${test_params}

"""

var _parameter_sets: PackedStringArray
var _preparsed_expressions: Array[Expression] = []
var _bound_input_values: Array[Array] = []
var _source_path := ""
var _function_name := ""


static var _native_class_mapping: Dictionary[String, Variant] = {}
static var _user_class_paths: Dictionary[String, String] = {}
static var _resolved_user_classes: Dictionary[String, Variant] = {}
static var _constant_token_regex: RegEx
static var _script_variant_type_regex: RegEx


func _init(
	parameter_sets: PackedStringArray,
	source_path: String,
	function_name: String,
	args: Array[GdFunctionArgument] = []
) -> void:
	super(args)
	_parameter_sets = parameter_sets
	_source_path = source_path
	_function_name = function_name

	var bound_class_names := _scan_bound_class_names(_parameter_sets)
	for index in _parameter_sets.size():
		_preparse_parameter_set(index, bound_class_names[index])


func get_max_index() -> int:
	return _parameter_sets.size()


func get_parameters(instance: Node, index: int) -> Array:
	var expression := _preparsed_expressions[index]
	if expression == null:
		return _run_expression_via_script(instance, _parameter_sets[index])

	var parameters: Variant = expression.execute(_bound_input_values[index], instance, false)
	if expression.has_execute_failed():
		prints("Expression execute error:", expression.get_error_text())
		return _run_expression_via_script(instance, _parameter_sets[index])
	if not parameters is Array:
		return _run_expression_via_script(instance, _parameter_sets[index])

	@warning_ignore("unsafe_call_argument")
	return _finalize_parameter_set(parameters)


static func _scan_bound_class_names(parameter_sets: PackedStringArray) -> Array[PackedStringArray]:
	var bound_class_names: Array[PackedStringArray] = []
	for index in bound_class_names.resize(parameter_sets.size()):
		bound_class_names[index] = PackedStringArray()

	var candidate_names := PackedStringArray()
	candidate_names.append_array(_get_native_class_mapping().keys())
	candidate_names.append_array(_get_user_class_paths().keys())
	for clazz_name: String in candidate_names:
		for index in parameter_sets.size():
			if parameter_sets[index].contains(clazz_name) and not bound_class_names[index].has(clazz_name):
				bound_class_names[index].append(clazz_name)
	return bound_class_names


func _preparse_parameter_set(index: int, bound_class_names: PackedStringArray) -> void:
	var input_names := bound_class_names
	var input_values: Array = []
	for clazz_name in bound_class_names:
		input_values.append(_class_value_of(clazz_name))

	var expression_source := _parameter_sets[index]
	for regex_match in _get_constant_token_regex().search_all(expression_source):
		var token := regex_match.get_string(0)
		var type_name := regex_match.get_string(1)
		var alias := token.replace(".", "__")
		if bound_class_names.has(type_name) or input_names.has(alias):
			continue
		if GdBuiltinConstants.is_known_constant(type_name, token):
			input_names.append(alias)
			input_values.append(GdBuiltinConstants.value_of(token))
			expression_source = expression_source.replace(token, alias)

	# Fix variant type resolving
	for regex_match in _get_script_variant_type_regex().search_all(expression_source):
		var constant_name := regex_match.get_string(0)
		input_names.append(constant_name)
		input_values.append(GdBuiltinConstants.to_ordinal_value(constant_name))

	var expression := Expression.new()
	if expression.parse(expression_source, input_names) != OK:
		_print_fallback_warning(_parameter_sets[index], expression.get_error_text(), _source_path, _function_name)
		_preparsed_expressions.append(null)
	else:
		_preparsed_expressions.append(expression)
	_bound_input_values.append(input_values)


static func _print_fallback_warning(parameter_set: String, error_text: String, source_path: String, function_name: String) -> void:
	if parameter_set.contains("as Array"):
		push_warning("""
		Avoid type-casting with `as Array` in parameter sets; use the typed `Array(...)` constructor instead.
			test: '%s' (%s)
			expression: '%s'
		Falling back to slower script-based resolver.
		""".dedent() % [function_name, source_path, parameter_set])
		return

	push_warning("""
		Parameter expression parsing failed (error: %s).
		Falling back to slower script-based resolver.
		Check for unsupported syntax or missing class bindings.
			test: '%s' (%s)
			expression: '%s'
		""".dedent() % [error_text, function_name, source_path, parameter_set])


static func _get_constant_token_regex() -> RegEx:
	if _constant_token_regex == null:
		_constant_token_regex = RegEx.new()
		_constant_token_regex.compile("([A-Za-z_][A-Za-z0-9_]*)\\.([A-Z][A-Z0-9_]*)\\b")
	return _constant_token_regex


static func _get_script_variant_type_regex() -> RegEx:
	if _script_variant_type_regex == null:
		_script_variant_type_regex = RegEx.new()
		_script_variant_type_regex.compile("TYPE_[A-Z0-9_]*\\b")
	return _script_variant_type_regex


# This is a fallback option to run the expression by kind of reflection
func _run_expression_via_script(instance: Node, expression: String) -> Array:
	var source_script: GDScript = instance.get_script()
	var script := GDScript.new()
	script.source_code = EXPRESSION_TEMPLATE \
		.replace("${clazz_path}", source_script.resource_path) \
		.replace("${test_params}", expression)
	var debug := false
	if debug == true:
		# enable these lines only for debugging
		script.resource_path = GdUnitFileAccess.create_temp_dir("parameter_extract") + "/%sExpression.gd" % source_script.resource_path.get_file()
		DirAccess.remove_absolute(script.resource_path)
		ResourceSaver.save(script, script.resource_path)
	var result := script.reload()
	if result != OK:
		prints("Extracting test parameters failed! Script loading error: %s" % error_string(result))
		return []

	var expression_runner: Node = script.new()
	copy_properties(instance, expression_runner)
	var parameters: Array = expression_runner.call("__run_expression")
	expression_runner.free()
	return _finalize_parameter_set(parameters)


## Returns the shared class-name-to-instance map, building it once on first access.
static func _get_native_class_mapping() -> Dictionary[String, Variant]:
	if _native_class_mapping.is_empty():
		_native_class_mapping = _build_native_class_mapping()
	return _native_class_mapping


static func _class_value_of(clazz_name: String) -> Variant:
	var native_classes := _get_native_class_mapping()
	if native_classes.has(clazz_name):
		return native_classes[clazz_name]
	return _lazily_loaded_user_class(clazz_name)


static func _lazily_loaded_user_class(clazz_name: String) -> Variant:
	if not _resolved_user_classes.has(clazz_name):
		_resolved_user_classes[clazz_name] = load(_get_user_class_paths()[clazz_name])
	return _resolved_user_classes[clazz_name]


static func _get_user_class_paths() -> Dictionary[String, String]:
	if _user_class_paths.is_empty():
		for entry in ProjectSettings.get_global_class_list():
			if entry["language"] == &"GDScript":
				var clazz_name: String = entry["class"]
				_user_class_paths[clazz_name] = entry["path"]
	return _user_class_paths


## Builds the class-name-to-instance map by generating and executing a GDScript that
## returns a dictionary literal — the only way to obtain live class references from
## [ClassDB] names, since GDScript has no eval or direct class-by-name lookup.
static func _build_native_class_mapping() -> Dictionary[String, Variant]:
	var source := """
		extends RefCounted

		func get_class_type_mappings() -> Dictionary[String, Variant]:
			return {
		""".dedent()

	for clazz_name in ClassDB.get_class_list():
		if ClassDB.class_get_api_type(clazz_name) != 0 or not ClassDB.can_instantiate(clazz_name):
			continue
		if clazz_name.is_valid_identifier():
			source += '\t\t"%s": %s,\n' % [clazz_name, clazz_name]
	source += "\t}"

	var script := GDScript.new()
	script.source_code = source
	var err := script.reload()
	if err != OK:
		prints("Failed to build class:type mappings: %s" % error_string(err))
		return {}

	@warning_ignore("unsafe_method_access")
	return script.new().get_class_type_mappings()


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
