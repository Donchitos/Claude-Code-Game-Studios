## Story `building-034` -- [ScaffoldRegistry] (TD ruling D1).
class_name ScaffoldRegistryTest
extends GdUnitTestSuite


func test_add_marks_cell_scaffold_and_emits_signal() -> void:
	var registry := ScaffoldRegistry.new()
	var cell := Vector3i(1, 2, 3)
	var emitted: Array[Vector3i] = []
	registry.scaffold_changed.connect(func(c: Vector3i) -> void: emitted.append(c))

	assert_bool(registry.add(cell)).is_true()
	assert_bool(registry.has_scaffold(cell)).is_true()
	assert_array(emitted).is_equal([cell])


func test_add_same_cell_twice_is_idempotent_no_second_signal() -> void:
	var registry := ScaffoldRegistry.new()
	var cell := Vector3i(1, 2, 3)
	# Array, not an int: GDScript lambdas capture scalars BY VALUE, so an
	# `emit_count += 1` inside the closure increments a copy and the assertion
	# below would read 0 forever — passing or failing for reasons that have
	# nothing to do with the registry. An Array is captured by reference.
	var emissions: Array[Vector3i] = []
	registry.scaffold_changed.connect(func(c: Vector3i) -> void: emissions.append(c))

	registry.add(cell)
	assert_bool(registry.add(cell)).is_false()
	assert_int(emissions.size()).is_equal(1)


func test_remove_clears_membership_and_emits_signal() -> void:
	var registry := ScaffoldRegistry.new()
	var cell := Vector3i(1, 2, 3)
	registry.add(cell)

	assert_bool(registry.remove(cell)).is_true()
	assert_bool(registry.has_scaffold(cell)).is_false()


func test_remove_nonexistent_cell_is_noop() -> void:
	var registry := ScaffoldRegistry.new()
	assert_bool(registry.remove(Vector3i(9, 9, 9))).is_false()


func test_has_scaffold_false_for_never_added_cell() -> void:
	var registry := ScaffoldRegistry.new()
	assert_bool(registry.has_scaffold(Vector3i(1, 1, 1))).is_false()


func test_is_empty_and_get_cells() -> void:
	var registry := ScaffoldRegistry.new()
	assert_bool(registry.is_empty()).is_true()
	registry.add(Vector3i(1, 1, 1))
	registry.add(Vector3i(2, 2, 2))
	assert_bool(registry.is_empty()).is_false()
	assert_int(registry.get_cells().size()).is_equal(2)
