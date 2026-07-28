class_name GdUnitTestSuiteBuilder
extends RefCounted


static func create(source :Script, line_number :int) -> GdUnitResult:
	var test_suite_path := GdUnitTestSuiteScanner.resolve_test_suite_path(source.resource_path, GdUnitSettings.test_root_folder())
	# we need to save and close the testsuite and source if is current opened before modify
	@warning_ignore("return_value_discarded")
	ScriptEditorControls.save_an_open_script(source.resource_path)
	@warning_ignore("return_value_discarded")
	ScriptEditorControls.save_an_open_script(test_suite_path, true)
	if source.get_class() == "CSharpScript":
		return GdUnit4CSharpApiLoader.create_test_suite(source.resource_path, line_number+1, test_suite_path)
	var parser := GdScriptParser.new()
	var lines := source.source_code.split("\n")
	var current_line := lines[line_number]
	var func_name := parser.parse_func_name(current_line)
	if func_name.is_empty():
		return GdUnitResult.error("No function found at line: %d." % line_number)
	return GdUnitTestSuiteScanner.create_test_case(test_suite_path, func_name, source.resource_path)
