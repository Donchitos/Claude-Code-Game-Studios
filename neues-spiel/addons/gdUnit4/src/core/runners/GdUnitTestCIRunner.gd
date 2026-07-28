#warning-ignore-all:return_value_discarded
class_name GdUnitTestCIRunner
extends "res://addons/gdUnit4/src/core/runners/GdUnitTestSessionRunner.gd"
## Command line test runner implementation.[br]
## [br]
## This runner is designed for CI/CD pipelines and command line test execution.[br]
## Features:[br]
## - Command line options for test configuration[br]
## - HTML and JUnit report generation[br]
## - Console output with colored formatting[br]
## - Progress and error reporting[br]
## - Test history management[br]
## [br]
## Example usage:[br]
## [codeblock]
## # Run all tests in a directory
## runtest -a <directory>
##
## # Run specific test suite with ignored tests
## runtest -a <directory> -i <testsuite:test_name>
## [/codeblock]

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")

var _console := GdUnitCSIMessageWriter.new()
var _console_reporter: GdUnitConsoleTestReporter
var _headless_mode_ignore := false
var _runner_config_file := ""
var _debug_cmd_args := PackedStringArray()
var _included_tests := PackedStringArray()
var _excluded_tests := PackedStringArray()

## Command line options configuration
var _cmd_options := CmdOptions.new([
		CmdOption.new(
			"-a, --add",
			"-a <directory|path of testsuite>",
			"Adds the given test suite or directory to the execution pipeline.",
			TYPE_STRING
		),
		CmdOption.new(
			"-i, --ignore",
			"-i <testsuite_name|testsuite_name:test-name>",
			"Adds the given test suite or test case to the ignore list.",
			TYPE_STRING
		),
		CmdOption.new(
				"-c, --continue",
				"",
				"""By default GdUnit will abort checked first test failure to be fail fast,
				instead of stop after first failure you can use this option to run the complete test set.""".dedent()
		),
		CmdOption.new(
			"-conf, --config",
			"-conf [testconfiguration.cfg]",
			"Run all tests by given test configuration. Default is 'GdUnitRunner.cfg'",
			TYPE_STRING,
			true
		),
		CmdOption.new(
			"-help", "",
			"Shows this help message."
		),
		CmdOption.new("--help-advanced", "",
			"Shows advanced options."
		)
	],
	[
		# advanced options
		CmdOption.new(
			"-rd, --report-directory",
			"-rd <directory>",
			"Specifies the output directory in which the reports are to be written. The default is res://reports/.",
			TYPE_STRING,
			true
		),
		CmdOption.new(
			"-rc, --report-count",
			"-rc <count>",
			"Specifies how many reports are saved before they are deleted. The default is %s." % str(GdUnitConstants.DEFAULT_REPORT_HISTORY_COUNT),
			TYPE_INT,
			true
		),
		#CmdOption.new("--list-suites", "--list-suites [directory]", "Lists all test suites located in the given directory.", TYPE_STRING),
		#CmdOption.new("--describe-suite", "--describe-suite <suite name>", "Shows the description of selected test suite.", TYPE_STRING),
		CmdOption.new(
			"--info", "",
			"Shows the GdUnit version info"
		),
		CmdOption.new(
			"--selftest", "",
			"Runs the GdUnit self test"
		),
		CmdOption.new(
			"--ignoreHeadlessMode",
			"--ignoreHeadlessMode",
			"By default, running GdUnit4 in headless mode is not allowed. You can switch off the headless mode check by set this property."
		),
	])


func _init() -> void:
	super()


func _ready() -> void:
	super()
	# stop checked first test failure to fail fast
	_executor.fail_fast(true)
	_console_reporter = GdUnitConsoleTestReporter.new(_console, true)
	GdUnitSignals.instance().gdunit_message.connect(_on_send_message)


func _notification(what: int) -> void:
	super(what)
	if what == NOTIFICATION_PREDELETE:
		prints("Finallize .. done")


func init_runner() -> void:
	await init_gd_unit()


## Returns the exit code based on test results.[br]
## Maps test report status to process exit codes.
func get_exit_code() -> int:
	return report_exit_code()


## Cleanup and quit the runner.[br]
## [br]
## [param code] The exit code to return.
func quit(code: int) -> void:
	_state = EXIT
	GdUnitTools.dispose_all()
	await GdUnitMemoryObserver.gc_on_guarded_instances()
	await super(code)


## Prints info message to console.[br]
## [br]
## [param message] The message to print.[br]
## [param color] Optional color for the message.
func console_info(message: String, color: Color = Color.WHITE) -> void:
	_console.color(color).println_message(message)


## Prints error message to console.[br]
## [br]
## [param message] The error message to print.
func console_error(message: String) -> void:
	_console.prints_error(message)


## Prints warning message to console.[br]
## [br]
## [param message] The warning message to print.
func console_warning(message: String) -> void:
	_console.prints_warning(message)


## Sets the directory for test reports.[br]
## [br]
## [param path] The path where reports should be written.
func set_report_dir(path: String) -> void:
	report_base_path  = ProjectSettings.globalize_path(GdUnitFileAccess.make_qualified_path(path))
	console_info(
		"Set write reports to %s" % report_base_path,
		Color.DEEP_SKY_BLUE
	)


## Sets how many report files to keep.[br]
## [br]
## [param count] The number of reports to keep.
func set_report_count(count: String) -> void:
	var report_count := count.to_int()
	if report_count < 1:
		console_error(
			"Invalid report history count '%s' set back to default %d"
			% [count, GdUnitConstants.DEFAULT_REPORT_HISTORY_COUNT]
		)
		max_report_history = GdUnitConstants.DEFAULT_REPORT_HISTORY_COUNT
	else:
		console_info(
			"Set report history count to %s" % count,
			Color.DEEP_SKY_BLUE
		)
		max_report_history = report_count


## Disables fail-fast mode to run all tests.[br]
## By default tests stop on first failure.
func disable_fail_fast() -> void:
	console_info(
		"Disabled fail fast!",
		Color.DEEP_SKY_BLUE
	)
	@warning_ignore("unsafe_method_access")
	_executor.fail_fast(false)


func run_self_test() -> void:
	console_info(
		"Run GdUnit4 self tests.",
		Color.DEEP_SKY_BLUE
	)
	disable_fail_fast()



## Shows GdUnit and Godot version information.
func show_version() -> void:
	console_info(
		"Godot %s" % Engine.get_version_info().get("string") as String,
		Color.DARK_SALMON
	)
	var config := ConfigFile.new()
	config.load("addons/gdUnit4/plugin.cfg")
	console_info(
		"GdUnit4 %s" % config.get_value("plugin", "version") as String,
		Color.DARK_SALMON
	)
	quit(RETURN_SUCCESS)


## Ignores headless mode restrictions.[br]
## Allows tests to run in headless mode despite limitations.
func check_headless_mode() -> void:
	_headless_mode_ignore = true


## Shows available command line options.[br]
## [br]
## [param show_advanced] Whether to show advanced options.
func show_options(show_advanced: bool = false) -> void:
	console_info(
		"""
		Usage:
			runtest -a <directory|path of testsuite>
			runtest -a <directory> -i <path of testsuite|testsuite_name|testsuite_name:test_name>
			""".dedent(),
		Color.DARK_SALMON
	)
	console_info(
		"-- Options ---------------------------------------------------------------------------------------",
		Color.DARK_SALMON
	)
	for option in _cmd_options.default_options():
		descripe_option(option)
	if show_advanced:
		console_info(
			"-- Advanced options --------------------------------------------------------------------------",
			Color.DARK_SALMON
		)
		for option in _cmd_options.advanced_options():
			descripe_option(option)


## Describes a single command line option.[br]
## [br]
## [param cmd_option] The option to describe.
func descripe_option(cmd_option: CmdOption) -> void:
	console_info(
		"  %-40s" % str(cmd_option.commands()),
		Color.CORNFLOWER_BLUE
	)
	console_info(
		cmd_option.description(),
		Color.LIGHT_GREEN
	)
	if not cmd_option.help().is_empty():
		console_info(
			"%-4s %s" % ["", cmd_option.help()],
			Color.DARK_TURQUOISE
		)
	console_info("")


## Loads test configuration from file.[br]
## [br]
## [param path] Path to the configuration file.
func load_test_config(path := GdUnitRunnerConfig.CONFIG_FILE) -> void:
	console_info(
		"Loading test configuration %s\n" % path,
		Color.CORNFLOWER_BLUE
	)
	_runner_config_file = path
	_runner_config.load_config(path)


## Shows basic help and exits.
func show_help() -> void:
	show_options()
	quit(RETURN_SUCCESS)


## Shows advanced help and exits.
func show_advanced_help() -> void:
	show_options(true)
	quit(RETURN_SUCCESS)


## Gets command line arguments.[br]
## Returns debug args if set, otherwise actual command line args.
func get_cmdline_args() -> PackedStringArray:
	if _debug_cmd_args.is_empty():
		return OS.get_cmdline_args()
	return _debug_cmd_args


## Initializes the test runner and processes command line arguments.
func init_gd_unit() -> void:
	console_info(
		"""
		--------------------------------------------------------------------------------------------------
		GdUnit4 Comandline Tool
		--------------------------------------------------------------------------------------------------""".dedent(),
		Color.DARK_SALMON
	)

	var cmd_parser := CmdArgumentParser.new(_cmd_options, "GdUnitCmdTool.gd")
	var result := cmd_parser.parse(get_cmdline_args())
	if result.is_error():
		console_error(result.error_message())
		show_options()
		console_error("Abnormal exit with %d" % RETURN_ERROR)
		quit(RETURN_ERROR)
		return
	if result.is_empty():
		show_help()
		return
	# build runner config by given commands
	var commands :Array[CmdCommand] = []
	@warning_ignore("unsafe_cast")
	commands.append_array(result.value() as Array)
	result = (
		CmdCommandHandler.new(_cmd_options)
			.register_cb("-help", show_help)
			.register_cb("--help-advanced", show_advanced_help)
			.register_cb("-a", add_test_suite)
			.register_cbv("-a", add_test_suites)
			.register_cb("-i", skip_test_suite)
			.register_cbv("-i", skip_test_suites)
			.register_cb("-rd", set_report_dir)
			.register_cb("-rc", set_report_count)
			.register_cb("--selftest", run_self_test)
			.register_cb("-c", disable_fail_fast)
			.register_cb("-conf", load_test_config)
			.register_cb("--info", show_version)
			.register_cb("--ignoreHeadlessMode", check_headless_mode)
			.execute(commands)
	)
	if result.is_error():
		console_error(result.error_message())
		quit(RETURN_ERROR)
		return

	if DisplayServer.get_name() == "headless":
		if _headless_mode_ignore:
			console_warning("""
				Headless mode is ignored by option '--ignoreHeadlessMode'"

				Please note that tests that use UI interaction do not work correctly in headless mode.
				Godot 'InputEvents' are not transported by the Godot engine in headless mode and therefore
				have no effect in the test!
				""".dedent()
			)
		else:
			console_error("""
				Headless mode is not supported!

				Please note that tests that use UI interaction do not work correctly in headless mode.
				Godot 'InputEvents' are not transported by the Godot engine in headless mode and therefore
				have no effect in the test!

				You can run with '--ignoreHeadlessMode' to swtich off this check.
				""".dedent()
			)
			console_error(
				"Abnormal exit with %d" % RETURN_ERROR_HEADLESS_NOT_SUPPORTED
			)
			quit(RETURN_ERROR_HEADLESS_NOT_SUPPORTED)
			return

	var script_error_collector := GdUnitScriptErrorCollector.new()
	_test_cases = discover_tests()

	# Check for script errors captured during discovery
	if script_error_collector.has_errors():
		console_error("Script errors were detected during test discovery!")
		for error in script_error_collector.errors():
			console_info("  %s" % error)
		console_error("Abnormal exit with %d" % RETURN_ERROR_SCRIPT_ERRORS_DETECTED)
		await quit(RETURN_ERROR_SCRIPT_ERRORS_DETECTED)
		return

	if _test_cases.is_empty():
		console_info("No test cases found, abort test run!", Color.YELLOW)
		console_info("Exit code: %d" % RETURN_SUCCESS, Color.DARK_SALMON)
		await quit(RETURN_SUCCESS)
		return
	_state = RUN


func discover_tests() -> Array[GdUnitTestCase]:
	var gdunit_test_discover_added := GdUnitSignals.instance().gdunit_test_discover_added

	_test_cases = _runner_config.test_cases()
	var scanner := GdUnitTestSuiteScanner.new()
	for path in _included_tests:
		var scripts := scanner.scan(path)
		for script in scripts:
			GdUnitTestDiscoverer.discover_tests(script, func(test: GdUnitTestCase) -> void:
				if not is_skipped(test):
					#_console.println_message("discoverd %s" % test.display_name)
					_test_cases.append(test)
					gdunit_test_discover_added.emit(test)
			)

	return _test_cases


func add_test_suite(path: String) -> void:
	_included_tests.append(path)


func add_test_suites(paths: PackedStringArray) -> void:
	_included_tests.append_array(paths)


func skip_test_suite(path: String) -> void:
	_excluded_tests.append(path)


func skip_test_suites(paths: PackedStringArray) -> void:
	_excluded_tests.append_array(paths)


func is_skipped(test: GdUnitTestCase) -> bool:
	for skipped_info in _excluded_tests:

		# is suite skipped by full path or suite name
		if skipped_info == test.suite_name or test.source_file.contains(skipped_info):
			return true
		var skip_file := skipped_info.replace("res://", "")

		# check for skipped single test
		if not skip_file.contains(":"):
			continue
		var parts: PackedStringArray = skip_file.rsplit(":")
		var skipped_suite :=  parts[0]
		var skipped_test := parts[1]
		# is suite skipped by full path or suite name
		if (skipped_suite == test.suite_name or test.source_file.contains(skipped_suite)) and skipped_test == test.test_name:
			return true

	return false


func _on_send_message(message: String) -> void:
	_console.color(Color.CORNFLOWER_BLUE).println_message(message)


func _on_gdunit_event(event: GdUnitEvent) -> void:
	match event.type():
		GdUnitEvent.SESSION_START:
			_console_reporter.test_session = _test_session
		GdUnitEvent.SESSION_CLOSE:
			_console_reporter.test_session = null


func report_exit_code() -> int:
	if _console_reporter.total_error_count() + _console_reporter.total_failure_count() > 0:
		console_info("Exit code: %d" % RETURN_ERROR, Color.FIREBRICK)
		return RETURN_ERROR
	if _console_reporter.total_orphan_count() > 0:
		console_info("Exit code: %d" % RETURN_WARNING, Color.GOLDENROD)
		return RETURN_WARNING
	console_info("Exit code: %d" % RETURN_SUCCESS, Color.DARK_SALMON)
	return RETURN_SUCCESS
