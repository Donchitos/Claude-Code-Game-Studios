# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GodotGdErrorMonitorTest
extends GdUnitTestSuite


func before() -> void:
	# disable default error reporting for testing
	ProjectSettings.set_setting(GdUnitSettings.REPORT_PUSH_ERRORS, false)
	ProjectSettings.set_setting(GdUnitSettings.REPORT_SCRIPT_ERRORS, false)


func test_monitor_push_error() -> void:
	var monitor := GodotGdErrorMonitor.new()
	monitor._logger._is_report_push_errors = true
	# no errors reported
	monitor.start()
	monitor.stop()
	assert_array(monitor.to_reports()).is_empty()

	# push error
	monitor.start()
	force_push_error()
	monitor.stop()

	var reports := monitor.to_reports()
	assert_array(reports).has_size(1)
	var report := reports[0]
	assert_str(report.message()) \
		.contains("Test GodotGdErrorMonitor 'push_error' reporting")
	assert_object(report.stack_trace()) \
		.is_equal(GdUnitStackTrace.new([
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/monitor/GodotGdErrorMonitorTest.gd", 74, "force_push_error2"),
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/monitor/GodotGdErrorMonitorTest.gd", 69, "force_push_error"),
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/monitor/GodotGdErrorMonitorTest.gd", 24, "test_monitor_push_error")
		]))
	assert_int(report.line_number()).is_equal(74)


func test_monitor_push_waring() -> void:
	var monitor := GodotGdErrorMonitor.new()
	monitor._logger._is_report_push_errors = true

	# push error
	monitor.start()
	push_warning("Test GodotGdErrorMonitor 'push_warning' reporting")
	monitor.stop()

	var reports := monitor.to_reports()
	assert_array(reports).has_size(1)
	var report := reports[0]
	assert_str(report.message())\
		.contains("Test GodotGdErrorMonitor 'push_warning' reporting")
	assert_object(report.stack_trace()) \
		.is_equal(GdUnitStackTrace.new([
			GdUnitStackTraceElement.new("res://addons/gdUnit4/test/monitor/GodotGdErrorMonitorTest.gd", 47, "test_monitor_push_waring")
		]))
	assert_int(report.line_number()).is_equal(47)


func test_fail_by_push_error(_do_skip := true, _skip_reason := "disabled to not produce errors, enable only for direct testing") -> void:
	GdUnitThreadManager.get_current_context().get_execution_context().error_monitor._logger._is_report_push_errors = true
	push_error("test error")


func force_push_error() -> void:
	@warning_ignore("redundant_await")
	await force_push_error2()


func force_push_error2() -> void:
	#await get_tree().process_frame
	push_error("Test GodotGdErrorMonitor 'push_error' reporting")
