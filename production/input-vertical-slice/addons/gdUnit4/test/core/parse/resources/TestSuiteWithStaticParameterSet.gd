extends GdUnitTestSuite

var _test_node_before: Node
var _test_node_before_test: Node


func before() -> void:
	_test_node_before = auto_free(SubViewport.new())
	_test_node_before_test = auto_free(SubViewport.new())


class TestObj extends RefCounted:
	var _value: String

	func _init(value: String) -> void:
		_value = value


@warning_ignore("unused_parameter")
func test_parameterized_bool_value(a: int, expected: bool, _test_parameters := [
	[0, false],
	[1, true]]) -> void:
	pass


@warning_ignore("unused_parameter")
func test_parameterized_int_values(a: int, b: int, c: int, expected: int, _test_parameters := [
	[1, 2, 3, 6],
	[3, 4, 5, 12],
	[6, 7, 8, 21] ]) -> void:
	pass


@warning_ignore("unused_parameter")
func test_parameterized_float_values(a: float, b: float, expected: float, _test_parameters := [
	[2.2, 2.2, 4.4],
	[2.2, 2.3, 4.5],
	[3.3, 2.2, 5.5] ]) -> void:
	pass

@warning_ignore("unused_parameter")
func test_parameterized_string_values(a: String, b: String, expected: String, _test_parameters := [
	["2.2", "2.2", "2.22.2"],
	["foo", "bar", "foobar"],
	["a", "b", "ab"] ]) -> void:
	pass


@warning_ignore("unused_parameter")
func test_parameterized_Vector2_values(a: Vector2, b: Vector2, expected: Vector2, _test_parameters := [
	[Vector2.ONE, Vector2.ONE, Vector2(2, 2)],
	[Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO],
	[Vector2.ZERO, Vector2.LEFT, Vector2.LEFT] ]) -> void:
	pass


@warning_ignore("unused_parameter")
func test_with_instance_parameters(name_: String, value: Variant, expected: Variant, _test_parameters := [
	["test_a", auto_free(Node2D.new()), Node2D],
	["test_b", auto_free(Node3D.new()), Node3D],
	["test_c", _test_node_before, SubViewport],
	["test_d", _test_node_before_test, SubViewport],
	["test_e", TestObj.new("abc"), TestObj]
]) -> void:
	pass
