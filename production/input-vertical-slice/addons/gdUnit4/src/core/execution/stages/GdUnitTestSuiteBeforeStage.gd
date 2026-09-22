## The test suite startup hook implementation.[br]
## It executes the 'before()' block from the test-suite.
class_name GdUnitTestSuiteBeforeStage
extends IGdUnitExecutionStage


func _execute(context: GdUnitExecutionContext) -> void:
	var test_suite := context.test_suite

	fire_event(GdUnitEvent.new()\
		.suite_before(context.get_test_suite_path(), test_suite.get_name(), test_suite.get_child_count()))

	@warning_ignore("redundant_await")
	await test_suite.before()
