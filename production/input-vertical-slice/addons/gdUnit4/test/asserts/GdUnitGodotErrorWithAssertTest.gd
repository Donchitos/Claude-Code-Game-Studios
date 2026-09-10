extends GdUnitTestSuite


var _catched_events: Array[GdUnitEvent] = []


func test_assert_method_with_enabled_global_error_report() -> void:
	ProjectSettings.set_setting(GdUnitSettings.REPORT_SCRIPT_ERRORS, true)
	assert_error(do_a_fail).is_runtime_error('Assertion failed: test')


func test_assert_method_with_disabled_global_error_report() -> void:
	ProjectSettings.set_setting(GdUnitSettings.REPORT_SCRIPT_ERRORS, false)
	assert_error(do_a_fail).is_runtime_error('Assertion failed: test')


func do_a_fail() -> void:
	@warning_ignore("assert_always_false")
	assert(3 == 1, 'test')


func catch_test_events(event :GdUnitEvent) -> void:
	_catched_events.append(event)


func before(
	_do_skip := Engine.is_embedded_in_editor() or OS.is_debug_build(),
	_skip_reason  := "Is skipped because the test will holt on script error in debug mode"
	) -> void:

	GdUnitSignals.instance().gdunit_event.connect(catch_test_events)


func after() -> void:
	# We expect no errors or failures, as we caught already the assert error by using the assert `assert_error` on the test case
	assert_array(_catched_events).extractv(extr("error_count"), extr("failed_count"))\
		.contains_exactly([tuple(0, 0), tuple(0,0), tuple(0,0), tuple(0,0)])
	GdUnitSignals.instance().gdunit_event.disconnect(catch_test_events)
