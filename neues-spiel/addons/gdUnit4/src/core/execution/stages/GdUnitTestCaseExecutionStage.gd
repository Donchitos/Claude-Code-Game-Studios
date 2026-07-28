## The test case execution stage.[br]
class_name GdUnitTestCaseExecutionStage
extends IGdUnitExecutionStage


var _stage_single_test: IGdUnitExecutionStage = GdUnitTestCaseSingleExecutionStage.new()
var _stage_fuzzer_test: IGdUnitExecutionStage = GdUnitTestCaseFuzzedExecutionStage.new()


## Executes the test case 'test_<name>()'.[br]
## It executes synchronized following stages[br]
##  -> test_before() [br]
##  -> test_case() [br]
##  -> test_after() [br]
@warning_ignore("redundant_await")
func _execute(context :GdUnitExecutionContext) -> void:
	var test_case := context.test_case

	context.save_project_settings()
	context.error_monitor_start()

	if test_case.is_fuzzed():
		await _stage_fuzzer_test.execute(context)
	else:
		await _stage_single_test.execute(context)

	await context.gc()
	context.error_monitor_stop()
	context.restore_project_settings()

	# finally free the test instance
	if is_instance_valid(context.test_case):
		context.test_case.dispose()


func set_debug_mode(debug_mode :bool = false) -> void:
	super.set_debug_mode(debug_mode)
	_stage_single_test.set_debug_mode(debug_mode)
	_stage_fuzzer_test.set_debug_mode(debug_mode)
