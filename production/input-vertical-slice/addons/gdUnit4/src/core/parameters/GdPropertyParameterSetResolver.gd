class_name GdPropertyParameterSetResolver
extends GdParameterSetResolver

var _parameters: Array[Array]
var _property_name: String


func _init(instance: Node, property_name: String, args: Array[GdFunctionArgument] = []) -> void:
	super(args)
	_parameters = _resolve_property(instance, property_name)
	_property_name = property_name


func get_max_index() -> int:
	return _parameters.size()


func get_parameters(instance: Node, index: int) -> Array:
	return _resolve_property(instance, _property_name)[index]


func _resolve_property(instance: Node, property_name: String) -> Array[Array]:
	var result: Variant = instance.get(property_name)

	if result == null:
		prints("The property `%s` do not exists." % property_name)
		return []
	if not result is Array:
		prints("The property `%s` must be an Array" % property_name)
		return []

	var parameter_set: Array = result
	parameter_set = parameter_set.duplicate(true)
	for parameters: Array in parameter_set:
		_finalize_parameter_set(parameters)

	# We want to use allways typed arrays
	if not parameter_set.is_typed():
		return Array(parameter_set, TYPE_ARRAY, "", null)
	return parameter_set
