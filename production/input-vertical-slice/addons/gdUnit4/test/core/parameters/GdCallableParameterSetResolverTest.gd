# GdUnit generated TestSuite
extends GdUnitTestSuite


var _x := 42
var _obj: Node2D
var _color := Color.RED
var _test_set_a := ["test_8", Color(1,1,1), Color(.1,.1,.1)]


class TestObj:

	func _init() -> void:
		pass


func _dynamic_parameterset(count: int) -> Array[Array]:
	var iterations: Array[Array] = []
	for i in range(count):
		iterations.append(["test_%s"%i, i])
	return iterations


func _parameters_typed() -> Array[Array]:
	return [
		["test_0", auto_free(Node2D.new()), Node2D],
		["test_1", auto_free(Node3D.new()), Node3D],
		["test_2", auto_free(Node.new()), Node],
		["test_3", auto_free(RefCounted.new()), RefCounted],
	]


func _parameters_untyped() -> Array:
	return [
		["test_0", auto_free(Node2D.new()), Node2D],
		["test_1", auto_free(Node3D.new()), Node3D],
		["test_2", auto_free(Node.new()), Node],
		["test_3", auto_free(RefCounted.new()), RefCounted],
	]


func _parameters_with_references_typed() -> Array[Array]:
	return [
		["test_0", auto_free(Node.new()), Node],
		["test_1", auto_free(Node3D.new()), Node3D],
		["test_2", "abc", "String"],
		["test_3", _x, "Integer"],
		["test_4", _obj, Node2D],
		["test_5", TestObj.new(), TestObj],
		["test_6", Vector3(1,1,1), Vector2(2,2)],
		["test_7", Color(1,1,1), _color],
		_test_set_a
	]


func _parameters_string_arg(arg1: String, arg2: String) -> Array[Array]:
	return [[arg1, arg2]]


func _parameters_string_args(arg1: String, arg2: String) ->  Array[Array]:
	return [[arg1, arg2]]


func before() -> void:
	_obj = auto_free(Node2D.new())


func test_get_parameters_dynamic_created() -> void:
	var resolver := GdCallableParameterSetResolver.new(self, "_dynamic_parameterset(4)")

	# We used the function `_dynamic_parameterset(4)` to pre-build a parameter set with size 4
	assert_int(resolver.get_max_index()).is_equal(4)

	# We test here a parameter resolver for a test function signature like
	# `func test_foo(arg1, arg2, _test_parameters := _dynamic_parameterset(5) -> void:`
	# The result of `get_parameters` must match the function signature
	# - first arg is extracted from the orignal _test_parameters using the `_dynamic_parameterset()` function
	# - second arg is extracted from the orignal _test_parameters using the `_dynamic_parameterset()` function
	# - third argument is a empty placeholder to replace the defaults of `_test_parameters` argument
	#   to avoid reinitalization of the complete parameter set
	assert_array(resolver.get_parameters(self, 0)) \
		.has_size(3) \
		.contains_exactly("test_0", 0, [])
	assert_array(resolver.get_parameters(self, 1)) \
		.has_size(3) \
		.contains_exactly("test_1", 1, [])
	assert_array(resolver.get_parameters(self, 2)) \
		.has_size(3) \
		.contains_exactly("test_2", 2, [])
	assert_array(resolver.get_parameters(self, 3)) \
		.has_size(3) \
		.contains_exactly("test_3", 3, [])


func test_get_parameters_typed_static_created() -> void:
	var resolver := GdCallableParameterSetResolver.new(self, "_parameters_typed()")

	# We used the function `_parameters_typed()` that builds a parameter set with size 4
	assert_int(resolver.get_max_index()).is_equal(4)

	# We test here a parameter resolver for a test function signature like
	# `func test_foo(arg1, arg2, _test_parameters := _parameters_typed() -> void:`
	# The result of `get_parameters` must match the function signature
	# - first arg is extracted from the orignal _test_parameters using the `_parameters_typed()` function
	# - second arg is extracted from the orignal _test_parameters using the `_parameters_typed()` function
	# - third argument is a empty placeholder to replace the defaults of `_test_parameters` argument
	#   to avoid reinitalization of the complete parameter set
	var parameters := resolver.get_parameters(self, 0)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_0")
	assert_object(parameters[1]).is_instanceof(Node2D).is_valid()
	assert_object(parameters[2]).is_equal(Node2D)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 1)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_1")
	assert_object(parameters[1]).is_instanceof(Node3D).is_valid()
	assert_object(parameters[2]).is_equal(Node3D)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 2)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_2")
	assert_object(parameters[1]).is_instanceof(Node).is_valid()
	assert_object(parameters[2]).is_equal(Node)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 3)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_3")
	assert_object(parameters[1]).is_instanceof(RefCounted).is_valid()
	assert_object(parameters[2]).is_equal(RefCounted)
	assert_object(parameters[3]).is_equal([])


func test_get_parameters_untyped() -> void:
	var resolver := GdCallableParameterSetResolver.new(self, "_parameters_untyped()")

	# We used the function `_parameters_typed()` that builds a parameter set with size 4
	assert_int(resolver.get_max_index()).is_equal(4)

	# We test here a parameter resolver for a test function signature like
	# `func test_foo(arg1, arg2, _test_parameters := _parameters_typed() -> void:`
	# The result of `get_parameters` must match the function signature
	# - first arg is extracted from the orignal _test_parameters using the `_parameters_typed()` function
	# - second arg is extracted from the orignal _test_parameters using the `_parameters_typed()` function
	# - third argument is a empty placeholder to replace the defaults of `_test_parameters` argument
	#   to avoid reinitalization of the complete parameter set
	var parameters := resolver.get_parameters(self, 0)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_0")
	assert_object(parameters[1]).is_instanceof(Node2D).is_valid()
	assert_object(parameters[2]).is_equal(Node2D)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 1)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_1")
	assert_object(parameters[1]).is_instanceof(Node3D).is_valid()
	assert_object(parameters[2]).is_equal(Node3D)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 2)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_2")
	assert_object(parameters[1]).is_instanceof(Node).is_valid()
	assert_object(parameters[2]).is_equal(Node)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 3)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_3")
	assert_object(parameters[1]).is_instanceof(RefCounted).is_valid()
	assert_object(parameters[2]).is_equal(RefCounted)


func test_get_parameters_dynamic_referenced() -> void:
	var resolver := GdCallableParameterSetResolver.new(self, "_parameters_with_references_typed()")

	# We used the function `_parameters_with_references_typed()` that builds a parameter set with size 9
	assert_int(resolver.get_max_index()).is_equal(9)


func test_get_parameters_string_values() -> void:
	# Using double qoutas
	var resolver := GdCallableParameterSetResolver.new(self, """_parameters_string_arg("abc", "def")""")

	var parameters := resolver.get_parameters(self, 0)
	assert_array(parameters).has_size(3)
	assert_str(parameters[0]).is_equal("abc")
	assert_str(parameters[1]).is_equal("def")
	assert_object(parameters[2]).is_equal([])

	# Using single qoutas see https://github.com/godot-gdunit-labs/gdUnit4/issues/1302
	resolver = GdCallableParameterSetResolver.new(self, """_parameters_string_arg('abc', 'd'ef')""")

	parameters = resolver.get_parameters(self, 0)
	assert_array(parameters).has_size(3)
	assert_str(parameters[0]).is_equal("abc")
	assert_str(parameters[1]).is_equal("d'ef")
	assert_object(parameters[2]).is_equal([])


func test_get_parameters_string_values_with_comma() -> void:
	# Using comma in strings
	var resolver := GdCallableParameterSetResolver.new(self, """_parameters_string_arg("abc", "d,ef")""")

	var parameters := resolver.get_parameters(self, 0)
	assert_array(parameters).has_size(3)
	assert_str(parameters[0]).is_equal("abc")
	assert_str(parameters[1]).is_equal("d,ef")
	assert_object(parameters[2]).is_equal([])


func test_split_argumens1(arg1: String, arg2: String, _test_parameters := _parameters_string_arg("abc", "d,ef")) -> void:
	assert_str(arg1).is_equal("abc")
	assert_str(arg2).is_equal("d,ef")


func test_split_argumens2(arg1: String, arg2: String, _test_parameters := _parameters_string_arg('abc', 'd"ef')) -> void:
	assert_str(arg1).is_equal("abc")
	assert_str(arg2).is_equal("d\"ef")


func test_split_argumens3(arg1: String, arg2: String, _test_parameters := _parameters_string_arg('abc', "d\"ef")) -> void:
	assert_str(arg1).is_equal("abc")
	assert_str(arg2).is_equal("d\"ef")


func test_split_argumens4(arg1: String, arg2: String, _test_parameters := _parameters_string_arg('abc', 'd\'ef')) -> void:
	assert_str(arg1).is_equal("abc")
	assert_str(arg2).is_equal("d'ef")


func test_split_argumens() -> void:
	assert_array(GdCallableParameterSetResolver._split_argumens('"abc", "d,ef"'))\
		.contains_exactly([
			'"abc"',
			'"d,ef"'
		])
	assert_array(GdCallableParameterSetResolver._split_argumens('"abc", "d\"ef"'))\
		.contains_exactly([
			'"abc"',
			'"d\"ef"'
		])
	assert_array(GdCallableParameterSetResolver._split_argumens("'abc', 'd,ef'"))\
		.contains_exactly([
			"'abc'",
			"'d,ef'"
		])
	assert_array(GdCallableParameterSetResolver._split_argumens("'abc', 'd\"ef'"))\
		.contains_exactly([
			"'abc'",
			"'d\"ef'"
		])
	assert_array(GdCallableParameterSetResolver._split_argumens('12, Node3d.new(), true, "d,ef"'))\
		.contains_exactly([
			"12",
			'Node3d.new()',
			"true",
			'"d,ef"'
		])

#region performance

func test_performance_single() -> void:
	const ITERATIONS := 1000
	var resolver := GdCallableParameterSetResolver.new(self, "_dynamic_parameterset(5)")

	var t1 := Time.get_ticks_usec()
	for _i in ITERATIONS:
		resolver.get_parameters(self, 0)
	var elapsed_time := Time.get_ticks_usec() - t1

	@warning_ignore_start("integer_division")
	prints("--- GdCallableParameterSetResolver:single performance (%d iterations) ---" % ITERATIONS)
	prints("	%8d µs  (%d µs/iteration)" % [elapsed_time, elapsed_time / ITERATIONS])
	assert_int(elapsed_time/ITERATIONS).is_less(5)
	@warning_ignore_restore("integer_division")


func test_performance_get_parameters_overall() -> void:
	const ITERATIONS := 1000
	var resolver := GdCallableParameterSetResolver.new(self, "_dynamic_parameterset(5)")

	var t1 := Time.get_ticks_usec()
	for _i in ITERATIONS:
		for index in resolver.get_max_index():
			resolver.get_parameters(self, index)
	var elapsed_time := Time.get_ticks_usec() - t1

	@warning_ignore_start("integer_division")
	prints("--- GdCallableParameterSetResolver:overall performance (%d iterations) ---" % ITERATIONS)
	prints("	%8d µs  (%d µs/iteration)" % [elapsed_time, elapsed_time / ITERATIONS])
	assert_int(elapsed_time/ITERATIONS).is_less(10)
	@warning_ignore_restore("integer_division")

#endregion
