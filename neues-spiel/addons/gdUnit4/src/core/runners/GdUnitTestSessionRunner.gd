extends Node
## The base test runner implementation.[br]
## [br]
## This class provides the core functionality to execute test suites with following features:[br]
## - Loading and initialization of test suites[br]
## - Executing test suites and managing test states[br]
## - Event dispatching and test reporting[br]
## - Support for headless mode[br]
## - Plugin version verification[br]
## [br]
## Supported by specialized runners:[br]
## - [b]GdUnitTestRunner[/b]: Used in the editor, connects via tcp to report test results[br]
## - [b]GdUnitCLRunner[/b]: A command line interface runner, writes test reports to file[br]
## The test runner runs checked default in fail-fast mode, it stops checked first test failure.

## Overall test run status codes used by the runners
const RETURN_SUCCESS = 0
const RETURN_ERROR = 100
const RETURN_ERROR_HEADLESS_NOT_SUPPORTED = 103
const RETURN_ERROR_GODOT_VERSION_NOT_SUPPORTED = 104
const RETURN_ERROR_SCRIPT_ERRORS_DETECTED = 105
const RETURN_WARNING = 101

## Specifies the Node name under which the runner is registered
const GDUNIT_RUNNER = "GdUnitRunner"

## The current runner configuration
@warning_ignore("unused_private_class_variable")
var _runner_config := GdUnitRunnerConfig.new()

## The test suite executor instance
var _executor: GdUnitTestSuiteExecutor
var _hooks : GdUnitTestSessionHookService

## Current runner state
var _state := READY

## Current tests to be processed
var _test_cases: Array[GdUnitTestCase] =  []


## Configured report base path (can be set on CI test runner)
var report_base_path: String = GdUnitFileAccess.current_dir() + "reports":
	get:
		return report_base_path


## Current session report path
var report_path: String:
	get:
		return "%s/%s%d" % [report_base_path, GdUnitConstants.REPORT_DIR_PREFIX, current_report_history_index]


## Current report history index, if max_report_history > 1 we scan for the next index over the existing reports
var current_report_history_index: int:
	get:
		if max_report_history > 1:
			return  GdUnitFileAccess.find_last_path_index(report_base_path, GdUnitConstants.REPORT_DIR_PREFIX) + 1
		else:
			return 1


## Controls how many report historys will be hold
var max_report_history: int = GdUnitConstants.DEFAULT_REPORT_HISTORY_COUNT:
	get:
		return max_report_history
	set(value):
		max_report_history = value


# holds the current test session context
var _test_session: GdUnitTestSession

## Runner state machine
enum {
	READY,
	INIT,
	RUN,
	STOP,
	EXIT
}

func _init() -> void:
	if OS.get_cmdline_args().size() == 1:
		DisplayServer.window_set_title("GdUnit4 Runner (Debug Mode)")
	else:
		DisplayServer.window_set_title("GdUnit4 Runner (Release Mode)")
	if not Engine.is_embedded_in_editor():
		# minimize scene window checked debug mode
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	# store current runner instance to engine meta data to can be access in as a singleton
	Engine.set_meta(GDUNIT_RUNNER, self)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.get_version_info().hex < 0x40300:
		printerr("The GdUnit4 plugin requires Godot version 4.3 or higher to run.")
		quit(RETURN_ERROR_GODOT_VERSION_NOT_SUPPORTED)
		return
	_executor = GdUnitTestSuiteExecutor.new()

	GdUnitSignals.instance().gdunit_event.connect(_on_gdunit_event)
	_state = INIT


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		Engine.remove_meta(GDUNIT_RUNNER)


## Main test runner loop. Is called every frame to manage the test execution.
func _process(_delta: float) -> void:
	match _state:
		INIT:
			await init_runner()
		RUN:
			_hooks = GdUnitTestSessionHookService.instance()
			_test_session = GdUnitTestSession.new(_test_cases, report_path)
			GdUnitSignals.instance().gdunit_event.emit(GdUnitSessionStart.new())
			# process next test suite
			set_process(false)
			var result := await _hooks.execute_startup(_test_session)
			if result.is_error():
				push_error(result.error_message())
			await _executor.run_and_wait(_test_cases)
			result = await _hooks.execute_shutdown(_test_session)
			if result.is_error():
				push_error(result.error_message())
			_state = STOP
			set_process(true)
			GdUnitSignals.instance().gdunit_event.emit(GdUnitSessionClose.new())
			cleanup_report_history()
		STOP:
			_state = EXIT
			# give the engine small amount time to finish the rpc
			await get_tree().create_timer(0.1).timeout
			await quit(get_exit_code())


## Used by the inheriting runners to initialize test execution
func init_runner() -> void:
	await get_tree().process_frame


func cleanup_report_history() -> int:
	return GdUnitFileAccess.delete_path_index_lower_equals_than(
		report_path.get_base_dir(),
		GdUnitConstants.REPORT_DIR_PREFIX,
		current_report_history_index-1-max_report_history)


## Returns the exit code when the test run is finished.[br]
## Abstract method to be implemented by the inheriting runners.
func get_exit_code() -> int:
	return RETURN_SUCCESS


## Quits the test runner with given exit code.
func quit(code: int) -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	get_tree().quit(code)


func prints_warning(message: String) -> void:
	prints(message)


## Default event handler to process test events.[br]
## Should be overridden by concrete runner implementation.
@warning_ignore("unused_parameter")
func _on_gdunit_event(event: GdUnitEvent) -> void:
	pass


## Event bridge from C# GdUnit4.ITestEventListener.cs[br]
## Used to handle test events from C# tests.
# gdlint: disable=function-name
func PublishEvent(data: Dictionary) -> void:
	_on_gdunit_event(GdUnitEvent.new().deserialize(data))
