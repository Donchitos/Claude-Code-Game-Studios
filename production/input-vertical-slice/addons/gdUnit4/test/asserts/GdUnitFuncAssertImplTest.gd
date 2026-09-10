# GdUnit generated TestSuite
class_name GdUnitFuncAssertImplTest
extends GdUnitTestSuite
@warning_ignore_start("redundant_await")


# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitFuncAssertImpl.gd'
const GdUnitTools = preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")


class TestValueProvider:
	var _max_iterations :int
	var _current_itteration := 0

	func _init(iterations := 0) -> void:
		_max_iterations = iterations

	func bool_value() -> bool:
		_current_itteration += 1
		if _current_itteration == _max_iterations:
			return true
		return false

	func int_value() -> int:
		return 0

	func float_value() -> float:
		return 0.0

	func string_value() -> String:
		return "value"

	func object_value() -> Object:
		return Resource.new()

	func array_value() -> Array:
		return []

	func dict_value() -> Dictionary:
		return {}

	func vec2_value() -> Vector2:
		return Vector2.ONE

	func vec3_value() -> Vector3:
		return Vector3.ONE

	func no_value() -> void:
		pass

	func unknown_value() -> Vector3:
		return Vector3.ONE


class ValueProvidersWithArguments:

	func is_type(_type :int) -> bool:
		return true

	func get_index(_instance :Object, _name :String) -> int:
		return 1

	func get_index2(_instance :Object, _name :String, _recursive := false) -> int:
		return 1


class TestIterativeValueProvider:
	var _max_iterations :int
	var _current_itteration := 0
	var _inital_value :Variant
	var _final_value :Variant

	func _init(inital_value :Variant, iterations :int, final_value :Variant) -> void:
		_max_iterations = iterations
		_inital_value = inital_value
		_final_value = final_value

	func bool_value() -> bool:
		_current_itteration += 1
		if _current_itteration >= _max_iterations:
			return _final_value
		return _inital_value

	func int_value() -> int:
		_current_itteration += 1
		if _current_itteration >= _max_iterations:
			return _final_value
		return _inital_value

	func obj_value() -> Variant:
		_current_itteration += 1
		if _current_itteration >= _max_iterations:
			return _final_value
		return _inital_value

	func has_type(type :int, _recursive :bool = true) -> int:
		_current_itteration += 1
		#await (Engine.get_main_loop() as SceneTree).idle_frame
		if type == _current_itteration:
			return _final_value
		return _inital_value

	func await_value() -> int:
		_current_itteration += 1
		await (Engine.get_main_loop() as SceneTree).process_frame
		prints("yielded_value", _current_itteration)
		if _current_itteration >= _max_iterations:
			return _final_value
		return _inital_value

	func reset() -> void:
		_current_itteration = 0

	func iteration() -> int:
		return _current_itteration


@warning_ignore("unused_parameter")
func test_is_null(timeout := 2000) -> void:
	var value_provider := TestIterativeValueProvider.new(RefCounted.new(), 5, null)
	# without default timeout od 2000ms
	assert_func(value_provider, "obj_value").is_not_null()
	await assert_func(value_provider, "obj_value").is_null()
	assert_int(value_provider.iteration()).is_equal(5)

	# with a timeout of 5s
	value_provider.reset()
	assert_func(value_provider, "obj_value").is_not_null()
	await assert_func(value_provider, "obj_value").wait_until(5000).is_null()
	assert_int(value_provider.iteration()).is_equal(5)

	# failure case
	value_provider = TestIterativeValueProvider.new(RefCounted.new(), 1, RefCounted.new())
	(
		await assert_failure_await(func() -> void: await assert_func(value_provider, "obj_value", []).wait_until(100).is_null())
	).has_message("Expected: is null but timed out after 100ms")


@warning_ignore("unused_parameter")
func test_is_not_null(timeout := 2000) -> void:
	var value_provider := TestIterativeValueProvider.new(null, 5, RefCounted.new())
	# without default timeout od 2000ms
	assert_func(value_provider, "obj_value").is_null()
	await assert_func(value_provider, "obj_value").is_not_null()
	assert_int(value_provider.iteration()).is_equal(5)

	# with a timeout of 5s
	value_provider.reset()
	assert_func(value_provider, "obj_value").is_null()
	await assert_func(value_provider, "obj_value").wait_until(5000).is_not_null()
	assert_int(value_provider.iteration()).is_equal(5)

	# failure case
	value_provider = TestIterativeValueProvider.new(null, 1, null)
	(
		await assert_failure_await(func() -> void: await assert_func(value_provider, "obj_value", []).wait_until(100).is_not_null())
	).has_message("Expected: is not null but timed out after 100ms")


@warning_ignore("unused_parameter")
func test_is_true(timeout := 2000) -> void:
	var value_provider := TestIterativeValueProvider.new(false, 5, true)
	# without default timeout od 2000ms
	assert_func(value_provider, "bool_value").is_false()
	await assert_func(value_provider, "bool_value").is_true()
	assert_int(value_provider.iteration()).is_equal(5)

	# with a timeout of 5s
	value_provider.reset()
	assert_func(value_provider, "bool_value").is_false()
	await assert_func(value_provider, "bool_value").wait_until(5000).is_true()
	assert_int(value_provider.iteration()).is_equal(5)

	# failure case
	value_provider = TestIterativeValueProvider.new(false, 1, false)
	(
		await assert_failure_await(func() -> void: await assert_func(value_provider, "bool_value", []).wait_until(100).is_true())
	).has_message("Expected: is true but timed out after 100ms")


@warning_ignore("unused_parameter")
func test_is_false(timeout := 2000) -> void:
	var value_provider := TestIterativeValueProvider.new(true, 5, false)
	# without default timeout od 2000ms
	assert_func(value_provider, "bool_value").is_true()
	await assert_func(value_provider, "bool_value").is_false()
	assert_int(value_provider.iteration()).is_equal(5)

	# with a timeout of 5s
	value_provider.reset()
	assert_func(value_provider, "bool_value").is_true()
	await assert_func(value_provider, "bool_value").wait_until(5000).is_false()
	assert_int(value_provider.iteration()).is_equal(5)

	# failure case
	value_provider = TestIterativeValueProvider.new(true, 1, true)
	(
		await assert_failure_await(func() -> void: await assert_func(value_provider, "bool_value", []).wait_until(100).is_false())
	).has_message("Expected: is false but timed out after 100ms")


@warning_ignore("unused_parameter")
func test_is_equal(timeout := 2000) -> void:
	var value_provider := TestIterativeValueProvider.new(42, 5, 23)
	# without default timeout od 2000ms
	assert_func(value_provider, "int_value").is_equal(42)
	await assert_func(value_provider, "int_value").is_equal(23)
	assert_int(value_provider.iteration()).is_equal(5)

	# with a timeout of 5s
	value_provider.reset()
	assert_func(value_provider, "int_value").is_equal(42)
	await assert_func(value_provider, "int_value").wait_until(5000).is_equal(23)
	assert_int(value_provider.iteration()).is_equal(5)

	# failing case
	value_provider = TestIterativeValueProvider.new(23, 1, 23)
	(
		await assert_failure_await(func() -> void: await assert_func(value_provider, "int_value", []).wait_until(100).is_equal(25))
	).has_message("Expected: is equal 25 but timed out after 100ms")


@warning_ignore("unused_parameter")
func test_is_not_equal(timeout := 2000) -> void:
	var value_provider := TestIterativeValueProvider.new(42, 5, 23)
	# without default timeout od 2000ms
	assert_func(value_provider, "int_value").is_equal(42)
	await assert_func(value_provider, "int_value").is_not_equal(42)
	assert_int(value_provider.iteration()).is_equal(5)

	# with a timeout of 5s
	value_provider.reset()
	assert_func(value_provider, "int_value").is_equal(42)
	await assert_func(value_provider, "int_value").wait_until(5000).is_not_equal(42)
	assert_int(value_provider.iteration()).is_equal(5)

	# failing case
	value_provider = TestIterativeValueProvider.new(23, 1, 23)
	(
		await assert_failure_await(func() -> void: await assert_func(value_provider, "int_value", []).wait_until(100).is_not_equal(23))
	).has_message("Expected: is not equal 23 but timed out after 100ms")


@warning_ignore("unused_parameter")
func test_is_equal_wiht_func_arg(timeout := 1300) -> void:
	var value_provider := TestIterativeValueProvider.new(42, 10, 23)
	# without default timeout od 2000ms
	assert_func(value_provider, "has_type", [1]).is_equal(42)
	await assert_func(value_provider, "has_type", [10]).is_equal(23)
	assert_int(value_provider.iteration()).is_equal(10)

	# with a timeout of 5s
	value_provider.reset()
	assert_func(value_provider, "has_type", [1]).is_equal(42)
	await assert_func(value_provider, "has_type", [10]).wait_until(5000).is_equal(23)
	assert_int(value_provider.iteration()).is_equal(10)


# abort test after 500ms to fail
@warning_ignore("unused_parameter")
func test_timeout_and_assert_fails(timeout := 500) -> void:
	# disable temporary the timeout errors for this test
	discard_error_interupted_by_timeout()
	var value_provider := TestIterativeValueProvider.new(1, 10, 10)
	# wait longer than test timeout, the value will be never '42'
	await assert_func(value_provider, "int_value").wait_until(1000).is_equal(42)
	fail("The test must be interrupted after 500ms")


func timed_function() -> Color:
	var color := Color.RED
	await await_millis(20)
	color = Color.GREEN
	await await_millis(20)
	color = Color.BLUE
	await await_millis(20)
	color = Color.BLACK
	return color


func test_timer_yielded_function() -> void:
	await assert_func(self, "timed_function").is_equal(Color.BLACK)
	# will be never red
	await assert_func(self, "timed_function").wait_until(100).is_not_equal(Color.RED)
	# failure case
	(
		await assert_failure_await(func() -> void: await assert_func(self, "timed_function", []).wait_until(100).is_equal(Color.RED))
	).has_message("Expected: is equal 'Color$v0' but timed out after 100ms"
		.replace("$v0", str(Color.RED))
	)


func test_timer_yielded_function_timeout() -> void:
	(
		await assert_failure_await(func() -> void: await assert_func(self, "timed_function", []).wait_until(40).is_equal(Color.BLACK))
	).has_message("Expected: is equal 'Color()' but timed out after 40ms")


func yielded_function() -> Color:
	var color := Color.RED
	await get_tree().process_frame
	color = Color.GREEN
	await get_tree().process_frame
	color = Color.BLUE
	await get_tree().process_frame
	color = Color.BLACK
	return color


func test_idle_frame_yielded_function() -> void:
	await assert_func(self, "yielded_function").is_equal(Color.BLACK)
	(
		await assert_failure_await(func() -> void: await assert_func(self, "yielded_function", []).wait_until(500).is_equal(Color.RED))
	).has_message("Expected: is equal 'Color$v0' but timed out after 500ms"
		.replace("$v0", str(Color.RED))
	)


func test_has_failure_message() -> void:
	var value_provider := TestIterativeValueProvider.new(10, 1, 10)
	(
		await assert_failure_await(func() -> void: await assert_func(value_provider, "int_value", []).wait_until(500).is_equal(42))
	).has_message("Expected: is equal 42 but timed out after 500ms")


func test_override_failure_message() -> void:
	assert_object(assert_func(RefCounted.new(), "get_reference_count").override_failure_message("error")).is_instanceof(GdUnitFuncAssert)
	var value_provider := TestIterativeValueProvider.new(10, 1, 20)
	(
		await assert_failure_await(func() -> void: await assert_func(value_provider, "int_value", []) \
			.override_failure_message("Custom failure message") \
			.wait_until(100) \
			.is_equal(42))
	).has_message("Custom failure message")


@warning_ignore("unsafe_method_access")
func test_append_failure_message() -> void:
	assert_object(assert_func(RefCounted.new(), "get_reference_count").append_failure_message("error")).is_instanceof(GdUnitFuncAssert)
	(
		await assert_failure_await(func() -> void: await assert_func(RefCounted.new(), "get_reference_count") \
			.append_failure_message("custom failure data") \
			.wait_until(10)\
			.is_equal(42))
	).is_failed() \
		.contains_message("Expected: is equal 42 but timed out after") \
		.contains_message("""
			Additional info:
			 custom failure data""".dedent().trim_prefix("\n"))


@warning_ignore("unused_parameter")
func test_invalid_function(timeout := 100) -> void:
	(
		await assert_failure_await(func() -> void: await assert_func(self, "invalid_func_name", [])\
		.wait_until(1000)\
		.is_equal(42))
	).starts_with_message("The function 'invalid_func_name' do not exists checked instance")
