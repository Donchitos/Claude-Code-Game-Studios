# GdUnit generated TestSuite
extends GdUnitTestSuite


var _x := 42
var _obj: Node2D
var _color := Color.RED
var _test_set_a := ["test_8", Color(1,1,1), Color(.1,.1,.1)]


class TestObj:

	func _init() -> void:
		pass


@warning_ignore("unused_private_class_variable")
var _parameters_with_references_typed: Array


func before() -> void:
	_obj = auto_free(Node2D.new())
	_parameters_with_references_typed = [
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


func test_get_parameters() -> void:
	var resolver := GdPropertyParameterSetResolver.new(self, "_parameters_with_references_typed")

	assert_int(resolver.get_max_index()).is_equal(9)
	# We test here a parameter resolver for a class property
	# `func test_foo(arg1, arg2, _test_parameters := _parameters_with_references_typed) -> void:`
	# The result of `get_parameters` must match the function signature
	# - first arg is extracted from the orignal _test_parameters array
	# - second arg is extracted from the orignal _test_parameters array
	# - third argument is a empty placeholder to replace the defaults of `_test_parameters` argument
	#   to avoid reinitalization of the complete parameter set

	var parameters := resolver.get_parameters(self, 0)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_0")
	assert_object(parameters[1]).is_instanceof(Node).is_valid()
	assert_object(parameters[2]).is_equal(Node)
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
	assert_str(parameters[1]).is_equal("abc")
	assert_str(parameters[2]).is_equal("String")
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 3)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_3")
	assert_int(parameters[1]).is_equal(_x)
	assert_str(parameters[2]).is_equal("Integer")
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 4)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_4")
	assert_object(parameters[1]).is_equal(_obj).is_valid()
	assert_object(parameters[2]).is_equal(Node2D)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 5)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_5")
	assert_object(parameters[1]).is_instanceof(TestObj).is_valid()
	assert_object(parameters[2]).is_equal(TestObj)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 6)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_6")
	assert_object(parameters[1]).is_equal(Vector3(1,1,1))
	assert_object(parameters[2]).is_equal(Vector2(2,2))
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 7)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal("test_7")
	assert_object(parameters[1]).is_equal(Color(1,1,1))
	assert_object(parameters[2]).is_equal(_color)
	assert_object(parameters[3]).is_equal([])

	parameters = resolver.get_parameters(self, 8)
	assert_array(parameters).has_size(4)
	assert_str(parameters[0]).is_equal(_test_set_a[0])
	assert_object(parameters[1]).is_equal(_test_set_a[1])
	assert_object(parameters[2]).is_equal(_test_set_a[2])
	assert_object(parameters[3]).is_equal([])


#region performance

func test_performance_single() -> void:
	const ITERATIONS := 1000
	var resolver := GdPropertyParameterSetResolver.new(self, "_parameters_with_references_typed")

	var t1 := Time.get_ticks_usec()
	for _i in ITERATIONS:
		resolver.get_parameters(self, 0)
	var elapsed_time := Time.get_ticks_usec() - t1

	@warning_ignore_start("integer_division")
	prints("--- GdPropertyParameterSetResolver:single performance (%d iterations) ---" % ITERATIONS)
	prints("	%8d µs  (%d µs/iteration)" % [elapsed_time, elapsed_time / ITERATIONS])
	assert_int(elapsed_time/ITERATIONS).is_less(10)
	@warning_ignore_restore("integer_division")


func test_performance_get_parameters_overall() -> void:
	const ITERATIONS := 1000
	var resolver := GdPropertyParameterSetResolver.new(self, "_parameters_with_references_typed")

	var t1 := Time.get_ticks_usec()
	for _i in ITERATIONS:
		for index in resolver.get_max_index():
			resolver.get_parameters(self, index)
	var elapsed_time := Time.get_ticks_usec() - t1

	@warning_ignore_start("integer_division")
	prints("--- GdPropertyParameterSetResolver:overall performance (%d iterations) ---" % ITERATIONS)
	prints("	%8d µs  (%d µs/iteration)" % [elapsed_time, elapsed_time / ITERATIONS])
	assert_int(elapsed_time/ITERATIONS).is_less(70)
	@warning_ignore_restore("integer_division")

#endregion
