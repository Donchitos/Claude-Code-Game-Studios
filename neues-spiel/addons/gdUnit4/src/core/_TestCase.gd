class_name _TestCase
extends Node

signal completed()


var _test_case: GdUnitTestCase
var _attribute: TestCaseAttribute
var _current_iteration: int = -1
var _expect_to_interupt := false
var _timer: Timer
var _interupted := false
var _terminated := false
var _failed := false
var _parameter_set_resolver: GdUnitTestParameterSetResolver
var _is_disposed := false
var _func_state: Variant


func _init(test_case: GdUnitTestCase, attribute: TestCaseAttribute, fd: GdFunctionDescriptor) -> void:
	_test_case = test_case
	_attribute = attribute
	set_function_descriptor(fd)


func execute(p_test_parameter := Array(), p_iteration := 0) -> void:
	_failure_received(false)
	_current_iteration = p_iteration - 1
	if _current_iteration == - 1:
		_set_failure_handler()
		set_timeout()

	if is_parameterized():
		execute_parameterized()
	elif not p_test_parameter.is_empty():
		update_fuzzers(p_test_parameter, p_iteration)
		_execute_test_case(test_name(), p_test_parameter)
	else:
		_execute_test_case(test_name(), [])
	await completed


func execute_parameterized() -> void:
	_failure_received(false)
	set_timeout()

	# Resolve parameter set at runtime to include runtime variables
	var test_parameters := await _resolve_test_parameters(_test_case.attribute_index)
	if test_parameters.is_empty():
		return

	await _execute_test_case(test_name(), test_parameters)


func _resolve_test_parameters(attribute_index: int) -> Array:
	var result := _parameter_set_resolver.load_parameter_sets(get_parent())
	if result.is_error():
		do_skip(true, result.error_message())
		await (Engine.get_main_loop() as SceneTree).process_frame
		completed.emit()
		return []

	# validate the parameter set
	var parameter_sets: Array = result.value()
	result = _parameter_set_resolver.validate(parameter_sets, attribute_index)
	if result.is_error():
		do_skip(true, result.error_message())
		await (Engine.get_main_loop() as SceneTree).process_frame
		completed.emit()
		return []

	@warning_ignore("unsafe_method_access")
	var test_parameters: Array = parameter_sets[attribute_index].duplicate()
	# We need here to add a empty array to override the `test_parameters` to prevent initial "default" parameters from being used.
	# This prevents objects in the argument list from being unnecessarily re-instantiated.
	test_parameters.append([])

	return test_parameters


func dispose() -> void:
	if _is_disposed:
		return
	_is_disposed = true
	Engine.remove_meta("GD_TEST_FAILURE")
	stop_timer()
	_remove_failure_handler()
	_attribute.fuzzers.clear()


@warning_ignore("shadowed_variable_base_class", "redundant_await")
func _execute_test_case(name: String, test_parameter: Array) -> void:
	# save the function state like GDScriptFunctionState to dispose at test timeout to prevent orphan state
	_func_state = get_parent().callv(name, test_parameter)
	await _func_state
	# needs at least on await otherwise it breaks the awaiting chain
	await (Engine.get_main_loop() as SceneTree).process_frame
	completed.emit()


func update_fuzzers(input_values: Array, iteration: int) -> void:
	for fuzzer :Variant in input_values:
		if fuzzer is Fuzzer:
			fuzzer._iteration_index = iteration + 1


func set_timeout() -> void:
	if is_instance_valid(_timer):
		return
	var time: float = _attribute.timeout / 1000.0
	_timer = Timer.new()
	add_child(_timer)
	_timer.set_name("gdunit_test_case_timer_%d" % _timer.get_instance_id())
	@warning_ignore("return_value_discarded")
	_timer.timeout.connect(do_interrupt, CONNECT_DEFERRED)
	_timer.set_one_shot(true)
	_timer.set_wait_time(time)
	_timer.set_autostart(false)
	_timer.start()


func do_interrupt() -> void:
	_interupted = true
	# We need to dispose manually the function state here
	GdObjects.dispose_function_state(_func_state)
	if not is_expect_interupted():
		var execution_context := GdUnitThreadManager.get_current_context().get_execution_context()
		if is_fuzzed():
			execution_context.add_report(GdUnitReport.new()\
				.create(GdUnitReport.INTERUPTED, line_number(), GdAssertMessages.fuzzer_interuped(_current_iteration, "timedout")))
		else:
			execution_context.add_report(GdUnitReport.new()\
				.create(GdUnitReport.INTERUPTED, line_number(), GdAssertMessages.test_timeout(_attribute.timeout)))
	completed.emit()


func do_terminate() -> void:
	_terminated = true
	# We need to dispose manually the function state here
	GdObjects.dispose_function_state(_func_state)
	var execution_context := GdUnitThreadManager.get_current_context().get_execution_context()
	execution_context.add_report(GdUnitReport.new()\
		.create(GdUnitReport.TERMINATED, line_number(), GdAssertMessages.test_session_terminated()))
	completed.emit()


func _set_failure_handler() -> void:
	if not GdUnitSignals.instance().gdunit_set_test_failed.is_connected(_failure_received):
		@warning_ignore("return_value_discarded")
		GdUnitSignals.instance().gdunit_set_test_failed.connect(_failure_received)


func _remove_failure_handler() -> void:
	if GdUnitSignals.instance().gdunit_set_test_failed.is_connected(_failure_received):
		GdUnitSignals.instance().gdunit_set_test_failed.disconnect(_failure_received)


func _failure_received(is_failed: bool) -> void:
	# is already failed?
	if _failed:
		return
	_failed = is_failed
	Engine.set_meta("GD_TEST_FAILURE", is_failed)


func stop_timer() -> void:
	# finish outstanding timeouts
	if is_instance_valid(_timer):
		_timer.stop()
		_timer.call_deferred("free")
		_timer = null


func expect_to_interupt() -> void:
	_expect_to_interupt = true


func is_interupted() -> bool:
	return _interupted


func is_expect_interupted() -> bool:
	return _expect_to_interupt


func is_terminated() -> bool:
	return _terminated


func is_parameterized() -> bool:
	return _parameter_set_resolver.is_parameterized()


func is_skipped() -> bool:
	return _attribute.is_skipped


func skip_info() -> String:
	return _attribute.skip_reason


func id() -> GdUnitGUID:
	return _test_case.guid


func test_name() -> String:
	return _test_case.test_name


func line_number() -> int:
	return _test_case.line_number


func iterations() -> int:
	return _attribute.fuzzer_iterations


func seed_value() -> int:
	return _attribute.test_seed


func is_fuzzed() -> bool:
	return not _attribute.fuzzers.is_empty()


func fuzzer_arguments() -> Array[GdFunctionArgument]:
	return _attribute.fuzzers


func script_path() -> String:
	return _test_case.source_file


func ResourcePath() -> String:
	return _test_case.source_file


func generate_seed() -> void:
	if _attribute.test_seed != -1:
		seed(_attribute.test_seed)


func do_skip(skipped: bool, reason: String="") -> void:
	_attribute.is_skipped = skipped
	_attribute.skip_reason = reason


func set_function_descriptor(fd: GdFunctionDescriptor) -> void:
	_parameter_set_resolver = GdUnitTestParameterSetResolver.new(fd)


func _to_string() -> String:
	return "%s :%d (%dms)" % [get_name(), _test_case.line_number, _attribute.timeout]
