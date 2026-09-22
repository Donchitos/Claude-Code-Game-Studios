extends GdUnitTestSuite


func _test_parameters_untyped() -> Array:
	return [
		["test_a", auto_free(Node2D.new()), Node2D],
		["test_b", auto_free(Node3D.new()), Node3D],
	]


func _test_parameters_typed() -> Array[Array]:
	return [
		["test_a", auto_free(Node2D.new()), Node2D],
		["test_b", auto_free(Node3D.new()), Node3D],
	]


func _dynamic_parameterset(count: int) -> Array[Array]:
	var iterations: Array[Array] = []
	for i in range(count):
		iterations.append(["name_%s"%i, i, i])
	return iterations


func test_with_dynamic_parameters_typed_array(_name: String, _value: Variant, _expected: Variant, _test_parameters := _test_parameters_typed()) -> void:
	pass


func test_with_dynamic_parameters_untyped_array(_name: String, _value: Variant, _expected: Variant, _test_parameters := _test_parameters_untyped()) -> void:
	pass


func test_with_dynamic_parameterset(_name: String, _value: Variant, _expected: Variant, _test_parameters := _dynamic_parameterset(10)) -> void:
	pass
