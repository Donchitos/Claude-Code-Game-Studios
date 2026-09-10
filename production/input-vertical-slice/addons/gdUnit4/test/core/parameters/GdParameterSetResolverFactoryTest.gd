extends GdUnitTestSuite

var _test_properties := [
	["test_a"],
	["test_b"],
	["test_c"]
]


func _static_parameters(_a: int, _b: int, _test_parameters := [[1, 2], [3, 4]]) -> void:
	pass


func _callable_parameters(_a: int, _b: int, _test_parameters := _build_params()) -> void:
	pass


func _callable_parameters_with_args(_a: int, _b: int, _test_parameters := _parameters_string_args("abc", "def")) -> void:
	pass

func _properties_parameters(_a: int, _b: int, _test_parameters := _test_properties) -> void:
	pass


func _no_parameters(_a: int, _b: int) -> void:
	pass


func _build_params() -> Array[Array]:
	return [[1, 2], [3, 4]]


func _parameters_string_args(arg1: String, arg2: String) ->  Array[Array]:
	return [[arg1, arg2]]


func _descriptor(func_name: String) -> GdFunctionDescriptor:
	var script: GDScript = get_script()
	return GdScriptParser.new().get_function_descriptors(script, [func_name]).front()


#region create

func test_create_returns_null_for_non_parameterized() -> void:
	var resolver := GdParameterSetResolverFactory.create(_descriptor("_no_parameters"), self)
	assert_that(resolver).is_null()


func test_create_returns_inline_resolver() -> void:
	var resolver := GdParameterSetResolverFactory.create(_descriptor("_static_parameters"), self)
	assert_object(resolver).is_instanceof(GdInlineParameterSetResolver)
	assert_int(resolver.get_max_index()).is_equal(2)


func test_create_returns_callable_resolver() -> void:
	var resolver := GdParameterSetResolverFactory.create(_descriptor("_callable_parameters"), self)
	assert_object(resolver).is_instanceof(GdCallableParameterSetResolver)
	assert_int(resolver.get_max_index()).is_equal(2)


func test_create_returns_callable_resolver_with_args() -> void:
	var resolver := GdParameterSetResolverFactory.create(_descriptor("_callable_parameters_with_args"), self)
	assert_object(resolver).is_instanceof(GdCallableParameterSetResolver)
	assert_int(resolver.get_max_index()).is_equal(1)


func test_create_returns_property_resolver() -> void:
	var resolver := GdParameterSetResolverFactory.create(_descriptor("_properties_parameters"), self)
	assert_object(resolver).is_instanceof(GdPropertyParameterSetResolver)
	assert_int(resolver.get_max_index()).is_equal(3)

#endregion
