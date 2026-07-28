## The test case execution stage.[br]
class_name GdUnitTestCaseFuzzedExecutionStage
extends IGdUnitExecutionStage

var _stage_before :IGdUnitExecutionStage = GdUnitTestCaseBeforeStage.new(false)
var _stage_after :IGdUnitExecutionStage = GdUnitTestCaseAfterStage.new(false)
var _stage_test :IGdUnitExecutionStage = GdUnitTestCaseFuzzedTestStage.new()


func _execute(context :GdUnitExecutionContext) -> void:
	fire_event(GdUnitEvent.new().test_before(context.test_case.id()))

	while context.retry_execution():
		var test_context := GdUnitExecutionContext.of(context)
		await _stage_before.execute(test_context)
		if not context.test_case.is_skipped():
			await _stage_test.execute(GdUnitExecutionContext.of(test_context))
		await _stage_after.execute(test_context)
		if test_context.is_success() or test_context.is_skipped() or test_context.is_interupted():
			break

	context.gc()
	if context.is_skipped():
		fire_test_skipped(context)
	else:
		var reports: = context.collect_reports(true)
		var statistics := context.calculate_statistics(reports)
		fire_event(GdUnitEvent.new().test_after(context.test_case.id(), context.test_case.test_name(), statistics, reports))

func set_debug_mode(debug_mode :bool = false) -> void:
	super.set_debug_mode(debug_mode)
	_stage_before.set_debug_mode(debug_mode)
	_stage_after.set_debug_mode(debug_mode)
	_stage_test.set_debug_mode(debug_mode)


func fire_test_skipped(context: GdUnitExecutionContext) -> void:
	var test_case := context.test_case
	var statistics := {
		GdUnitEvent.ORPHAN_NODES: 0,
		GdUnitEvent.ELAPSED_TIME: 0,
		GdUnitEvent.WARNINGS: false,
		GdUnitEvent.ERRORS: false,
		GdUnitEvent.ERROR_COUNT: 0,
		GdUnitEvent.FAILED: false,
		GdUnitEvent.FAILED_COUNT: 0,
		GdUnitEvent.SKIPPED: true,
		GdUnitEvent.SKIPPED_COUNT: 1,
	}
	var report := GdUnitReport.new() \
		.create(GdUnitReport.SKIPPED, test_case.line_number(), GdAssertMessages.test_skipped(test_case.skip_info()))
	fire_event(GdUnitEvent.new().test_after(test_case.id(), test_case.test_name(), statistics, [report]))
