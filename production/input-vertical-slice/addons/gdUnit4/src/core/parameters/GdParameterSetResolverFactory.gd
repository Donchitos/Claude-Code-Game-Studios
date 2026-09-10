## Factory that selects and constructs the correct [GdParameterSetResolver] for a
## parameterized test function based on how the [code]_test_parameters[/code] default
## value is expressed: inline array literals, a callable, or a property reference.
class_name GdParameterSetResolverFactory
extends RefCounted


## Returns the appropriate resolver for [param fd], or null when the function is not parameterized.
static func create(fd: GdFunctionDescriptor, instance: Node) -> GdParameterSetResolver:
	if not fd.is_parameterized():
		return null
	var parameter_set_argument := GdFunctionArgument.get_parameter_set(fd.args())
	var parameter_sets := parameter_set_argument.parameter_sets()

	if not parameter_sets.is_empty():
		return GdInlineParameterSetResolver.new(parameter_sets, fd.source_path(), fd.name(), fd.args())

	# A parenthesis signals a callable expression, e.g. "my_provider()".
	var expression: String = parameter_set_argument._default_value
	if expression.contains("("):
		return GdCallableParameterSetResolver.new(instance, expression, fd.args())
	return GdPropertyParameterSetResolver.new(instance, expression, fd.args())
