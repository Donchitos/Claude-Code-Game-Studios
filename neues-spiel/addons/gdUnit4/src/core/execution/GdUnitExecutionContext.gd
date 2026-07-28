## The execution context
## It contains all the necessary information about the executed stage, such as memory observers, reports, orphan monitor
class_name GdUnitExecutionContext

enum GC_ORPHANS_CHECK {
	NONE,
	SUITE_HOOK_AFTER,
	TEST_HOOK_AFTER,
	TEST_CASE
}


var _parent_context: GdUnitExecutionContext
var _sub_context: Array[GdUnitExecutionContext] = []
var _orphan_monitor: GdUnitOrphanNodesMonitor
var _memory_observer: GdUnitMemoryObserver
var _report_collector: GdUnitTestReportCollector
var _timer: LocalTime
var _test_case_name: StringName
var _test_case_parameter_set: Array
var _name: String
var _test_execution_iteration: int = 0
var _flaky_test_check := GdUnitSettings.is_test_flaky_check_enabled()
var _flaky_test_retries := GdUnitSettings.get_flaky_max_retries()


var _settings_snapshot: GdUnitProjectSettingsSnapshot = null


var error_monitor: GodotGdErrorMonitor = null:
	get:
		if _parent_context != null:
			return _parent_context.error_monitor
		if error_monitor == null:
			error_monitor = GodotGdErrorMonitor.new()
		return error_monitor


var test_suite: GdUnitTestSuite = null:
	get:
		if _parent_context != null:
			return _parent_context.test_suite
		return test_suite


var test_case: _TestCase = null:
	get:
		if test_case == null and _parent_context != null:
			return _parent_context.test_case
		return test_case


func _init(name: StringName, parent_context: GdUnitExecutionContext = null) -> void:
	_name = name
	_parent_context = parent_context
	_timer = LocalTime.now()
	_orphan_monitor = GdUnitOrphanNodesMonitor.new(name)

	if parent_context != null:
		parent_context._orphan_monitor.add_child_monitor(_orphan_monitor)
		orphan_monitor_start()

	_memory_observer = GdUnitMemoryObserver.new()
	_report_collector = GdUnitTestReportCollector.new()
	if parent_context != null:
		parent_context._sub_context.append(self)


func dispose() -> void:
	if test_suite != null:
		test_suite.free()
	_timer = null
	_orphan_monitor = null
	_report_collector = null
	_memory_observer = null
	_parent_context = null
	test_suite = null
	test_case = null
	dispose_sub_contexts()


func dispose_sub_contexts() -> void:
	for context in _sub_context:
		context.dispose()
	_sub_context.clear()


func terminate() -> void:
	if test_case:
		test_case.do_terminate()


static func of(pe: GdUnitExecutionContext) -> GdUnitExecutionContext:
	var context := GdUnitExecutionContext.new(pe._test_case_name, pe)
	context._test_case_name = pe._test_case_name
	context._test_execution_iteration = pe._test_execution_iteration
	return context


static func of_test_case(pe: GdUnitExecutionContext, p_test_case: _TestCase) -> GdUnitExecutionContext:
	assert(p_test_case, "test_case is null")
	var context := GdUnitExecutionContext.new(p_test_case.test_name(), pe)
	context.test_case = p_test_case
	return context


static func of_parameterized_test(pe: GdUnitExecutionContext, test_case_name: String, test_case_parameter_set: Array) -> GdUnitExecutionContext:
	var context := GdUnitExecutionContext.new(test_case_name, pe)
	context._test_case_name = test_case_name
	context._test_case_parameter_set = test_case_parameter_set
	return context


func get_test_suite_path() -> String:
	return test_suite.get_script().resource_path


func get_test_suite_name() -> StringName:
	return test_suite.get_name()


func get_test_case_name() -> StringName:
	if _test_case_name.is_empty():
		return test_case._test_case.display_name
	return _test_case_name


func save_project_settings() -> void:
	if _settings_snapshot == null:
		_settings_snapshot = GdUnitProjectSettingsSnapshot.new()
	_settings_snapshot.save()


func restore_project_settings() -> void:
	if _settings_snapshot == null:
		return
	_settings_snapshot.restore()


func error_monitor_start() -> void:
	error_monitor.start()


func error_monitor_stop() -> void:
	error_monitor.stop()
	for error_report in error_monitor.to_reports():
		if error_report.is_error():
			_report_collector.push_back(error_report)


func orphan_monitor_start() -> void:
	_orphan_monitor.start()


func orphan_monitor_collect() -> void:
	_orphan_monitor.collect()


func orphan_monitor_stop() -> void:
	_orphan_monitor.stop()


func add_report(report: GdUnitReport) -> GdUnitReport:
	_report_collector.push_back(report)
	return report


func reports() -> Array[GdUnitReport]:
	return _report_collector.reports()


func collect_reports(recursive: bool) -> Array[GdUnitReport]:
	if not recursive:
		return reports()

	# we combine the reports of test_before(), test_after() and test() to be reported by `fire_test_ended`
	# we strictly need to copy the reports before adding sub context reports to avoid manipulation of the current context
	var current_reports := reports().duplicate()
	for sub_context in _sub_context:
		current_reports.append_array(sub_context.collect_reports(true))

	return current_reports


func calculate_statistics(reports_: Array[GdUnitReport]) -> Dictionary:
	var failed_count := GdUnitTestReportCollector.count_failures(reports_)
	var error_count := GdUnitTestReportCollector.count_errors(reports_)
	var warn_count := GdUnitTestReportCollector.count_warnings(reports_)
	var skip_count := GdUnitTestReportCollector.count_skipped(reports_)
	var orphan_count := GdUnitTestReportCollector.count_orphans(reports_)
	var is_failed := !is_success()
	var elapsed_time := _timer.elapsed_since_ms()
	var retries :=  1 if _parent_context == null else _sub_context.size()
	# Mark as flaky if it is successful, but errors were counted
	var is_flaky := retries > 1  and not is_failed
	# In the case of a flakiness test, we do not report an error counter, as an unreliable test is considered successful
	# after a certain number of repetitions.
	if is_flaky:
		failed_count = 0

	return {
		GdUnitEvent.RETRY_COUNT: retries,
		GdUnitEvent.ELAPSED_TIME: elapsed_time,
		GdUnitEvent.FAILED: is_failed,
		GdUnitEvent.ERRORS: error_count > 0,
		GdUnitEvent.WARNINGS: warn_count > 0,
		GdUnitEvent.FLAKY: is_flaky,
		GdUnitEvent.SKIPPED: skip_count > 0,
		GdUnitEvent.FAILED_COUNT: failed_count,
		GdUnitEvent.ERROR_COUNT: error_count,
		GdUnitEvent.SKIPPED_COUNT: skip_count,
		GdUnitEvent.ORPHAN_NODES: orphan_count,
	}


func is_success() -> bool:
	if _sub_context.is_empty():
		return not _report_collector.has_failures()
	# we on test suite level?
	if _parent_context == null:
		return not _report_collector.has_failures()

	return _sub_context[-1].is_success() and not _report_collector.has_failures()


func is_skipped() -> bool:
	return (
		_sub_context.any(func(c :GdUnitExecutionContext) -> bool:
			return c.is_skipped())
		or test_case.is_skipped() if test_case != null else false
	)


func is_interupted() -> bool:
	return false if test_case == null else test_case.is_interupted()


func sum(accum: int, number: int) -> int:
	return accum + number


func retry_execution() -> bool:
	var retry := _test_execution_iteration < 1 if not _flaky_test_check else _test_execution_iteration < _flaky_test_retries
	if retry:
		_test_execution_iteration += 1
	return retry


func register_auto_free(obj: Variant) -> Variant:
	return _memory_observer.register_auto_free(obj)


## Runs the gdunit garbage collector to free registered object and handle orphan node reporting
func gc(gc_orphan_check: GC_ORPHANS_CHECK = GC_ORPHANS_CHECK.NONE) -> void:
	# unreference last used assert form the test to prevent memory leaks
	GdUnitThreadManager.get_current_context().clear_assert()
	await _memory_observer.gc()
	orphan_monitor_stop()

	match(gc_orphan_check):
		GC_ORPHANS_CHECK.SUITE_HOOK_AFTER:
			_orphan_monitor.collect()
			var orphan_infos := _orphan_monitor.detected_orphans()
			if orphan_infos.is_empty():
				return
			reports().push_front(GdUnitReport.new() \
				.create(GdUnitReport.ORPHAN, 1, GdAssertMessages.orphan_detected_on_suite_setup(orphan_infos))
				.with_current_value(orphan_infos.size()))

		GC_ORPHANS_CHECK.TEST_HOOK_AFTER:
			_orphan_monitor.collect()
			var orphans := _orphan_monitor.detected_orphans()
			if not orphans.is_empty():
				reports().push_front(GdUnitReport.new()\
					.create(GdUnitReport.ORPHAN, 1, GdAssertMessages.orphan_detected_on_test_setup(orphans))
					.with_current_value(orphans.size()))

		GC_ORPHANS_CHECK.TEST_CASE:
			var orphans := _orphan_monitor.detected_orphans()
			if orphans.is_empty():
				var orphans_count := _orphan_monitor.orphans_count()
				if orphans_count > 0:
					reports().push_front(GdUnitReport.new() \
							.create(GdUnitReport.ORPHAN, test_case.line_number(), GdAssertMessages.orphan_warning(orphans_count))
							.with_current_value(orphans_count))
			else:
				reports().push_front(GdUnitReport.new()\
					.create(GdUnitReport.ORPHAN, test_case.line_number(), GdAssertMessages.orphan_detected_on_test(orphans))
					.with_current_value(orphans.size()))
