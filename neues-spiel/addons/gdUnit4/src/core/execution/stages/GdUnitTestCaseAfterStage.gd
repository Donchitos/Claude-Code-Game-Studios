## The test case shutdown hook implementation.[br]
## It executes the 'test_after()' block from the test-suite.
class_name GdUnitTestCaseAfterStage
extends IGdUnitExecutionStage


var _call_stage: bool


func _init(call_stage := true) -> void:
	_call_stage = call_stage


func _execute(context: GdUnitExecutionContext) -> void:
	var test_suite := context.test_suite

	if _call_stage:
		@warning_ignore("redundant_await")
		await test_suite.after_test()

	await context.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_HOOK_AFTER)
	context.error_monitor_stop()
