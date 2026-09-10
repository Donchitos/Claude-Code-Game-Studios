# GdUnit generated TestSuite
class_name GdUnitGodotErrorAssertImplTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd'

# skip see https://github.com/godotengine/godot/issues/80292
func before() -> void:
	# disable default error reporting for testing
	ProjectSettings.set_setting(GdUnitSettings.REPORT_PUSH_ERRORS, false)
	ProjectSettings.set_setting(GdUnitSettings.REPORT_SCRIPT_ERRORS, false)


func after_test() -> void:
	# Cleanup report artifacts
	GdUnitThreadManager.get_current_context().get_execution_context().error_monitor.clear_logs()


func test_invalid_callable() -> void:
	assert_failure(func() -> void: assert_error(Callable()).is_success())\
		.is_failed()\
		.has_message("Invalid Callable 'null::null'")


func test_is_success() -> void:
	assert_error(produce_assert_success).is_success()

	assert_failure(func() -> void:
		assert_error(produce_push_warning).is_success()
	).is_failed().has_message("""
		Expecting: no error's are ocured.
			but found: 'this is an push_warning'
		""".dedent().trim_prefix("\n"))

	assert_failure(func() -> void:
		assert_error(produce_push_error).is_success()
	).is_failed().has_message("""
		Expecting: no error's are ocured.
			but found: 'this is an push_error'
		""".dedent().trim_prefix("\n"))


func test_is_assert_failed(
	_do_skip := Engine.is_embedded_in_editor() or OS.is_debug_build(),
	_skip_reason  := "Is skipped because the test will holt on script error in debug mode") -> void:

	assert_error(produce_assert_error)\
		.is_runtime_error('Assertion failed: this is an assert error')

	assert_failure(func() -> void:
		assert_error(produce_assert_success).is_runtime_error('Assertion failed: this is an assert error')
	).is_failed().has_message("""
		Expecting: a runtime error is triggered.
			expected: 'Assertion failed: this is an assert error'
			current: 'no errors'
		""".dedent().trim_prefix("\n"))


func test_is_push_warning() -> void:
	assert_error(produce_push_warning).is_push_warning('this is an push_warning')

	assert_failure(func() -> void:
		assert_error(produce_push_warning).is_push_warning('this is an error')
	).is_failed().has_message("""
		Expecting: push_warning() is called.
			expected: 'this is an error'
			current: 'this is an push_warning'
		""".dedent().trim_prefix("\n"))


func test_is_push_warning_using_argument_matcher() -> void:
	assert_error(produce_push_warning).is_push_warning(any())
	assert_error(produce_push_warning).is_push_warning(any_string())

	assert_failure(func() -> void:
		assert_error(produce_push_warning).is_push_warning(any_int())
	).is_failed().has_message("Only 'any()' and 'any_string()' argument matchers are allowed!")


func test_is_push_error() -> void:
	assert_error(produce_push_error).is_push_error('this is an push_error')

	assert_failure(func() -> void:
		assert_error(produce_assert_success).is_push_error('this is an push_error')
	).is_failed().has_message("""
		Expecting: push_error() is called.
			expected: 'this is an push_error'
			current: 'no errors'
		""".dedent().trim_prefix("\n"))

	assert_failure(func() -> void:
		assert_error(produce_push_warning).is_push_error('this is an push_error')
	).is_failed().has_message("""
		Expecting: push_error() is called.
			expected: 'this is an push_error'
			current: 'this is an push_warning'
		""".dedent().trim_prefix("\n"))


func test_is_push_error_using_argument_matcher() -> void:
	assert_error(produce_push_error).is_push_error(any())
	assert_error(produce_push_error).is_push_error(any_string())

	assert_failure(func() -> void:
		assert_error(produce_push_error).is_push_error(any_int())
	).is_failed().has_message("Only 'any()' and 'any_string()' argument matchers are allowed!")


func test_is_runtime_error(
	_do_skip := Engine.is_embedded_in_editor() or OS.is_debug_build(),
	_skip_reason  := "Is skipped because the test will holt on script error in debug mode") -> void:

	assert_error(produce_runtime_error).is_runtime_error("Division by zero error in operator '/'.")

	assert_failure(func() -> void:
		assert_error(produce_assert_success).is_runtime_error("Division by zero error in operator '/'.")
	).is_failed().has_message("""
		Expecting: a runtime error is triggered.
			expected: 'Division by zero error in operator '/'.'
			current: 'no errors'
		""".dedent().trim_prefix("\n"))


func test_is_runtime_error_using_argument_matcher(
	_do_skip := Engine.is_embedded_in_editor() or OS.is_debug_build(),
	_skip_reason  := "Is skipped because the test will holt on script error in debug mode") -> void:

	assert_error(produce_runtime_error).is_runtime_error(any())
	assert_error(produce_runtime_error).is_runtime_error(any_string())

	assert_failure(func() -> void:
		assert_error(produce_runtime_error).is_runtime_error(any_int())
	).is_failed().has_message("Only 'any()' and 'any_string()' argument matchers are allowed!")


func produce_assert_success() -> void:
	@warning_ignore("assert_always_true")
	assert(true, "no error" )


func produce_assert_error() -> void:
	assert(false, "this is an assert error" )


func produce_push_warning() -> void:
	push_warning('this is an push_warning')


func produce_push_error() -> void:
	push_error('this is an push_error')


func produce_runtime_error() -> void:
	var a := 0
	@warning_ignore("integer_division")
	@warning_ignore("unused_variable")
	var x := 1/a
