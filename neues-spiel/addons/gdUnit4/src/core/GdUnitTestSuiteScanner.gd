class_name GdUnitTestSuiteScanner
extends RefCounted

const TEST_FUNC_TEMPLATE ="""

func test_${func_name}() -> void:
	# remove this line and complete your test
	assert_not_yet_implemented()
"""


# we exclude the gdunit source directorys by default
const exclude_scan_directories = [
	"res://addons/gdUnit4/bin",
	"res://addons/gdUnit4/src",
	"res://reports"]


const ARGUMENT_TIMEOUT := "timeout"
const ARGUMENT_SKIP := "do_skip"
const ARGUMENT_SKIP_REASON := "skip_reason"
const ARGUMENT_PARAMETER_SET := "test_parameters"


var _script_parser := GdScriptParser.new()
var _included_resources: PackedStringArray = []
var _excluded_resources: PackedStringArray = []
var _expression_runner := GdUnitExpressionRunner.new()
var _regex_extends_clazz_name := RegEx.create_from_string("extends[\\s]+([\\S]+)")


func prescan_testsuite_classes() -> void:
	# scan and cache extends GdUnitTestSuite by class name an resource paths
	var script_classes: Array[Dictionary] = ProjectSettings.get_global_class_list()
	for script_meta in script_classes:
		var base_class: String = script_meta["base"]
		var resource_path: String = script_meta["path"]
		if base_class == "GdUnitTestSuite":
			@warning_ignore("return_value_discarded")
			_included_resources.append(resource_path)
		elif ClassDB.class_exists(base_class):
			@warning_ignore("return_value_discarded")
			_excluded_resources.append(resource_path)


func scan(resource_path: String) -> Array[Script]:
	prescan_testsuite_classes()
	# if single testsuite requested
	if FileAccess.file_exists(resource_path):
		var test_suite := _load_is_test_suite(resource_path)
		if test_suite != null:
			return [test_suite]
		return []
	return scan_directory(resource_path)


func scan_directory(resource_path: String) -> Array[Script]:
	prescan_testsuite_classes()
	# We use the global cache to fast scan for test suites.
	if _excluded_resources.has(resource_path):
		return []

	var base_dir := DirAccess.open(resource_path)
	if base_dir == null:
			prints("Given directory or file does not exists:", resource_path)
			return []

	prints("Scanning for test suites in:", resource_path)
	return _scan_test_suites_scripts(base_dir, [])


func _scan_test_suites_scripts(dir: DirAccess, collected_suites: Array[Script]) -> Array[Script]:
		# Skip excluded directories
	if dir.file_exists(".gdignore"):
		prints("Exclude directory %s, containing .gdignore file" % dir.get_current_dir())
		return []

	if exclude_scan_directories.has(dir.get_current_dir()):
		return collected_suites

	var err := dir.list_dir_begin()
	if err != OK:
		push_error("Error on scanning directory %s" % dir.get_current_dir(), error_string(err))
		return collected_suites
	var file_name := dir.get_next()
	while file_name != "":
		var resource_path := GdUnitTestSuiteScanner._file(dir, file_name)
		if dir.current_is_dir():
			var sub_dir := DirAccess.open(resource_path)
			if sub_dir != null:
				@warning_ignore("return_value_discarded")
				_scan_test_suites_scripts(sub_dir, collected_suites)
		else:
			var time := LocalTime.now()
			var test_suite := _load_is_test_suite(resource_path)
			if test_suite:
				collected_suites.append(test_suite)
			if OS.is_stdout_verbose() and time.elapsed_since_ms() > 300:
				push_warning("Scanning of test-suite '%s' took more than 300ms: " % resource_path, time.elapsed_since())
		file_name = dir.get_next()
	return collected_suites


static func _file(dir: DirAccess, file_name: String) -> String:
	var current_dir := dir.get_current_dir()
	if current_dir.ends_with("/"):
		return current_dir + file_name
	return current_dir + "/" + file_name


func _load_is_test_suite(resource_path: String) -> Script:
	if not GdUnitTestSuiteScanner._is_script_format_supported(resource_path):
		return null

	# We use the global cache to fast scan for test suites.
	if _excluded_resources.has(resource_path):
		return null
	# Check in the global class cache whether the GdUnitTestSuite class has been extended.
	if _included_resources.has(resource_path):
		return GdUnitTestSuiteScanner.load_with_disabled_warnings(resource_path)

	# Otherwise we need to scan manual, we need to exclude classes where direct extends form Godot classes
	# the resource loader can fail to load e.g. plugin classes with do preload other scripts
	#var extends_from := get_extends_classname(resource_path)
	# If not extends is defined or extends from a Godot class
	#if extends_from.is_empty() or ClassDB.class_exists(extends_from):
	#	return null
	# Finally, we need to load the class to determine it is a test suite
	var script := GdUnitTestSuiteScanner.load_with_disabled_warnings(resource_path)
	if not is_test_suite(script):
		return null
	return script


func load_suite(script: GDScript, tests: Array[GdUnitTestCase]) -> GdUnitTestSuite:
	var test_suite: GdUnitTestSuite = script.new()
	var first_test: GdUnitTestCase = tests.front()
	test_suite.set_name(first_test.suite_name)

	# We need to group first all parameterized tests together to load the parameter set once
	var grouped_by_test := GdArrayTools.group_by(tests, func(test: GdUnitTestCase) -> String:
		return test.test_name
	)
	# Extract function descriptors
	var test_names: PackedStringArray = grouped_by_test.keys()
	test_names.append("before")
	var function_descriptors := _script_parser.get_function_descriptors(script, test_names)

	# Convert to test
	for fd in function_descriptors:
		if fd.name() == "before":
			_handle_test_suite_arguments(test_suite, script, fd)
			continue

		# Build test attributes from test method
		var test_attribute := _build_test_attribute(script, fd)
		# Create test from descriptor and given attributes
		var test_group: Array = grouped_by_test[fd.name()]
		for test: GdUnitTestCase in test_group:
			# We need a copy, because of mutable state
			var attribute: TestCaseAttribute = test_attribute.clone()
			test_suite.add_child(_TestCase.new(test, attribute, fd))
	return test_suite


func _build_test_attribute(script: GDScript, fd: GdFunctionDescriptor) -> TestCaseAttribute:
	var collected_unknown_aruments := PackedStringArray()
	var attribute := TestCaseAttribute.new()

	# Collect test attributes
	for arg: GdFunctionArgument in fd.args():
		if arg.type() == GdObjects.TYPE_FUZZER:
			attribute.fuzzers.append(arg)
		else:
			# We allow underscore as prefix to prevent unused argument warnings
			match arg.name().trim_prefix("_"):
				ARGUMENT_TIMEOUT:
					attribute.timeout = type_convert(arg.default(), TYPE_INT)
				ARGUMENT_SKIP:
					var result: Variant = _expression_runner.execute(script, arg.plain_value())
					if result is bool:
						attribute.is_skipped = result
					else:
						push_error("Test expression '%s' cannot be evaluated because it is not of type bool!" % arg.plain_value())
				ARGUMENT_SKIP_REASON:
					attribute.skip_reason = arg.plain_value()
				Fuzzer.ARGUMENT_ITERATIONS:
					attribute.fuzzer_iterations = type_convert(arg.default(), TYPE_INT)
				Fuzzer.ARGUMENT_SEED:
					attribute.test_seed = type_convert(arg.default(), TYPE_INT)
				ARGUMENT_PARAMETER_SET:
					collected_unknown_aruments.clear()
					pass
				_:
					collected_unknown_aruments.append(arg.name())

	# Verify for unknown arguments
	if not collected_unknown_aruments.is_empty():
		attribute.is_skipped = true
		attribute.skip_reason = "Unknown test case argument's %s found." % collected_unknown_aruments

	return attribute


# We load the test suites with disabled unsafe_method_access to avoid spamming loading errors
# `unsafe_method_access` will happen when using `assert_that`
static func load_with_disabled_warnings(resource_path: String) -> Script:
	# grap current level
	var unsafe_method_access: Variant = ProjectSettings.get_setting("debug/gdscript/warnings/unsafe_method_access")

	# disable and load the script
	ProjectSettings.set_setting("debug/gdscript/warnings/unsafe_method_access", 0)

	var script: Script = (
		GdUnitTestResourceLoader.load_gd_script(resource_path) if resource_path.ends_with("resource")
		else ResourceLoader.load(resource_path))

	# restore
	ProjectSettings.set_setting("debug/gdscript/warnings/unsafe_method_access", unsafe_method_access)
	return script


static func is_test_suite(script: Script) -> bool:
	if script is GDScript:
		var stack := [script]
		while not stack.is_empty():
			var current: Script = stack.pop_front()
			var base: Script = current.get_base_script()
			if base != null:
				if base.resource_path.find("GdUnitTestSuite") != -1:
					return true
				stack.push_back(base)
	elif script != null and script.get_class() == "CSharpScript":
		return true
	return false


static func _is_script_format_supported(resource_path: String) -> bool:
	var ext := resource_path.get_extension()
	return ext == "gd" or ext == "cs"


static func parse_test_suite_name(script: Script) -> String:
	return script.resource_path.get_file().replace(".gd", "")


func _handle_test_suite_arguments(test_suite: GdUnitTestSuite, script: GDScript, fd: GdFunctionDescriptor) -> void:
	for arg in fd.args():
		# We allow underscore as prefix to prevent unused argument warnings
		match arg.name().trim_prefix("_"):
			ARGUMENT_SKIP:
				var result: Variant = _expression_runner.execute(script, arg.plain_value())
				if result is bool:
					test_suite.__is_skipped = result
				else:
					push_error("Test expression '%s' cannot be evaluated because it is not of type bool!" % arg.plain_value())
			ARGUMENT_SKIP_REASON:
				test_suite.__skip_reason = arg.plain_value()
			_:
				push_error("Unsuported argument `%s` found on before() at '%s'!" % [arg.name(), script.resource_path])


# converts given file name by configured naming convention
static func _to_naming_convention(file_name: String) -> String:
	var nc :int = GdUnitSettings.get_setting(GdUnitSettings.TEST_SUITE_NAMING_CONVENTION, 0)
	match nc:
		GdUnitSettings.NAMING_CONVENTIONS.AUTO_DETECT:
			if GdObjects.is_snake_case(file_name):
				return GdObjects.to_snake_case(file_name + "Test")
			return GdObjects.to_pascal_case(file_name + "Test")
		GdUnitSettings.NAMING_CONVENTIONS.SNAKE_CASE:
			return GdObjects.to_snake_case(file_name + "Test")
		GdUnitSettings.NAMING_CONVENTIONS.PASCAL_CASE:
			return GdObjects.to_pascal_case(file_name + "Test")
	push_error("Unexpected case")
	return "-<Unexpected>-"


static func resolve_test_suite_path(source_script_path: String, test_root_folder: String = "test") -> String:
	var file_name := source_script_path.get_basename().get_file()
	var suite_name := _to_naming_convention(file_name)
	if test_root_folder.is_empty() or test_root_folder == "/":
		return source_script_path.replace(file_name, suite_name)

	# is user tmp
	if source_script_path.begins_with("user://tmp"):
		return normalize_path(source_script_path.replace("user://tmp", "user://tmp/" + test_root_folder)).replace(file_name, suite_name)

	# at first look up is the script under a "src" folder located
	var test_suite_path: String
	var src_folder := source_script_path.find("/src/")
	if src_folder != -1:
		test_suite_path = source_script_path.replace("/src/", "/"+test_root_folder+"/")
	else:
		var paths := source_script_path.split("/", false)
		# is a plugin script?
		if paths[1] == "addons":
			test_suite_path = "%s//addons/%s/%s" % [paths[0], paths[2], test_root_folder]
			# rebuild plugin path
			for index in range(3, paths.size()):
				test_suite_path += "/" + paths[index]
		else:
			test_suite_path = paths[0] + "//" + test_root_folder
			for index in range(1, paths.size()):
				test_suite_path += "/" + paths[index]
	return normalize_path(test_suite_path).replace(file_name, suite_name)


static func normalize_path(path: String) -> String:
	return path.replace("///", "/")


static func create_test_suite(test_suite_path: String, source_path: String) -> GdUnitResult:
	# create directory if not exists
	if not DirAccess.dir_exists_absolute(test_suite_path.get_base_dir()):
		var error_ := DirAccess.make_dir_recursive_absolute(test_suite_path.get_base_dir())
		if error_ != OK:
			return GdUnitResult.error("Can't create directoy  at: %s. Error code %s" % [test_suite_path.get_base_dir(), error_])
	var script := GDScript.new()
	script.source_code = GdUnitTestSuiteTemplate.build_template(source_path)
	var error := ResourceSaver.save(script, test_suite_path)
	if error != OK:
		return GdUnitResult.error("Can't create test suite at: %s. Error code %s" % [test_suite_path, error])
	return GdUnitResult.success(test_suite_path)


static func get_test_case_line_number(resource_path: String, func_name: String) -> int:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file != null:
		var line_number := 0
		while not file.eof_reached():
			var row := file.get_line()
			line_number += 1
			# ignore comments and empty lines and not test functions
			if row.begins_with("#") || row.length() == 0 || row.find("func test_") == -1:
				continue
			# abort if test case name found
			if row.find("func") != -1 and row.find("test_" + func_name) != -1:
				return line_number
	return -1


func get_extends_classname(resource_path: String) -> String:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file != null:
		while not file.eof_reached():
			var row := file.get_line()
			# skip comments and empty lines
			if row.begins_with("#") || row.length() == 0:
				continue
			# Stop at first function
			if row.contains("func"):
				return ""
			var result := _regex_extends_clazz_name.search(row)
			if result != null:
				return result.get_string(1)
	return ""


static func add_test_case(resource_path: String, func_name: String)  -> GdUnitResult:
	var script := load_with_disabled_warnings(resource_path)
	# count all exiting lines and add two as space to add new test case
	var line_number := count_lines(script) + 2
	var func_body := TEST_FUNC_TEMPLATE.replace("${func_name}", func_name)
	if Engine.is_editor_hint():
		# NOTE: Avoid using EditorInterface and EditorSettings directly,
		#       as it causes compilation errors in exported projects.
		@warning_ignore_start("unsafe_method_access")
		var editor_interface: Object = Engine.get_singleton("EditorInterface")
		var settings: Object = editor_interface.get_editor_settings()
		var ident_type: int = settings.get_setting("text_editor/behavior/indent/type")
		var ident_size: int = settings.get_setting("text_editor/behavior/indent/size")
		@warning_ignore_restore("unsafe_method_access")
		if ident_type == 1:
			func_body = func_body.replace("	", "".lpad(ident_size, " "))
	script.source_code += func_body
	var error := ResourceSaver.save(script, resource_path)
	if error != OK:
		return GdUnitResult.error("Can't add test case at: %s to '%s'. Error code %s" % [func_name, resource_path, error])
	return GdUnitResult.success({ "path" : resource_path, "line" : line_number})


static func count_lines(script: Script) -> int:
	return script.source_code.split("\n").size()


static func test_suite_exists(test_suite_path: String) -> bool:
	return FileAccess.file_exists(test_suite_path)


static func test_case_exists(test_suite_path :String, func_name :String) -> bool:
	if not test_suite_exists(test_suite_path):
		return false
	var script := load_with_disabled_warnings(test_suite_path)
	for f in script.get_script_method_list():
		if f["name"] == "test_" + func_name:
			return true
	return false


static func create_test_case(test_suite_path: String, func_name: String, source_script_path: String) -> GdUnitResult:
	if test_case_exists(test_suite_path, func_name):
		var line_number := get_test_case_line_number(test_suite_path, func_name)
		return GdUnitResult.success({ "path" : test_suite_path, "line" : line_number})

	if not test_suite_exists(test_suite_path):
		var result := create_test_suite(test_suite_path, source_script_path)
		if result.is_error():
			return result
	return add_test_case(test_suite_path, func_name)
