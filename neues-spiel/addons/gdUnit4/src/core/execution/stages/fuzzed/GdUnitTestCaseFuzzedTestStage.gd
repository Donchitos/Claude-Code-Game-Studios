## The fuzzed test case execution stage.[br]
class_name GdUnitTestCaseFuzzedTestStage
extends IGdUnitExecutionStage

var _expression_runner := GdUnitExpressionRunner.new()


## Executes a test case with given fuzzers 'test_<name>(<fuzzer>)' iterative.[br]
## It executes synchronized following stages[br]
##  -> test_case() [br]
func _execute(context :GdUnitExecutionContext) -> void:
	var test_suite := context.test_suite
	var test_case := context.test_case
	var fuzzers := create_fuzzers(test_suite, test_case)

	# guard on fuzzers
	for fuzzer in fuzzers:
		@warning_ignore("return_value_discarded")
		GdUnitMemoryObserver.guard_instance(fuzzer)

	for iteration in test_case.iterations():
		@warning_ignore("redundant_await")
		await test_suite.before_test()
		await test_case.execute(fuzzers, iteration)
		@warning_ignore("redundant_await")
		await test_suite.after_test()
		if test_case.is_interupted():
			break
		# interrupt at first failure
		var reports := context.reports()
		if not reports.is_empty():
			var report :GdUnitReport = reports.pop_front()
			reports.append(GdUnitReport.new() \
				.create(GdUnitReport.FAILURE, report.line_number(), GdAssertMessages.fuzzer_interuped(iteration, report.message())))
			break
	await context.gc(GdUnitExecutionContext.GC_ORPHANS_CHECK.TEST_CASE)

	# unguard on fuzzers
	if not test_case.is_interupted():
		for fuzzer in fuzzers:
			GdUnitMemoryObserver.unguard_instance(fuzzer)


func create_fuzzers(test_suite :GdUnitTestSuite, test_case :_TestCase) -> Array[Fuzzer]:
	if not test_case.is_fuzzed():
		return Array()
	test_case.generate_seed()
	var fuzzers :Array[Fuzzer] = []
	for fuzzer_arg in test_case.fuzzer_arguments():
		@warning_ignore("unsafe_cast")
		var fuzzer := _expression_runner.to_fuzzer(test_suite.get_script() as GDScript, fuzzer_arg.plain_value() as String)
		fuzzer._iteration_index = 0
		fuzzer._iteration_limit = test_case.iterations()
		fuzzers.append(fuzzer)
	return fuzzers
