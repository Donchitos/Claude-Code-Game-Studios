## The single test case execution stage.[br]
class_name GdUnitTestCaseSingleTestStage
extends IGdUnitExecutionStage


## Executes a single test case 'test_<name>()'.[br]
## It executes synchronized following stages[br]
##  -> test_case() [br]
func _execute(context: GdUnitExecutionContext) -> void:
	await context.test_case.execute()
	await context.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_CASE)
