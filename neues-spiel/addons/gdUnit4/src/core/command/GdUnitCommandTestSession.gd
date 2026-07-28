class_name GdUnitCommandTestSession
extends GdUnitBaseCommand


const ID := "Start Test Session"


var _current_runner_process_id: int
var _is_running: bool
var _is_debug: bool
var _is_fail_fast: bool


func _init() -> void:
	super(ID, GdUnitShortcut.ShortCut.NONE)
	_is_running = false
	_is_fail_fast = false


func is_running() -> bool:
	return _is_running


func stop() -> void:
	if not is_running():
		return
	_is_running = false

	if _is_debug:
		force_pause_scene()

	GdUnitSignals.instance().gdunit_test_session_terminate.emit()
	# Give the API time to commit terminate to the client
	await get_tree().create_timer(.5).timeout

	if _is_debug and EditorInterface.is_playing_scene():
		EditorInterface.stop_playing_scene()
	elif OS.is_process_running(_current_runner_process_id):
		var result := OS.kill(_current_runner_process_id)
		if result != OK:
			push_error("ERROR checked stopping GdUnit Test Runner. error code: %s" % result)
		_current_runner_process_id = -1
	# We need finaly to send the test session close event because the current run is hard aborted.
	GdUnitSignals.instance().gdunit_event.emit(GdUnitSessionClose.new())


## Forces the running scene to unpause when the debugger hits a breakpoint.[br]
## [br]
## When the Godot debugger stops at a breakpoint during test execution, it blocks[br]
## the main thread. This prevents signals and TCP communications from being processed,[br]
## which can cause GdUnit4 tests to hang or fail to communicate properly with the[br]
## test runner. This function programmatically unpauses the scene to restore[br]
## main thread execution while maintaining debugger functionality. [br]
## [br]
## [b]Technical Background:[/b][br]
## - Debugger breakpoints freeze the main thread to allow inspection[br]
## - Frozen main thread blocks signal processing and network communications[br]
## - GdUnit4 requires active signal/TCP processing for test coordination[br]
## - This function finds and triggers the editor's pause button to resume execution[br]
## [br]
## [b]How It Works:[/b][br]
## 1. Locates the EditorRunBar in the Godot editor UI hierarchy[br]
## 2. Searches for the pause button by matching its icon[br]
## 3. Unpresses the button if it's currently pressed (paused state)[br]
## 4. Manually triggers the button's connected callbacks to resume execution[br]
func force_pause_scene() -> bool:
	var nodes := EditorInterface.get_base_control().find_children("*", "EditorRunBar", true, false)
	if nodes.size() != 1:
		push_error("GdUnitCommandTestSession:force_pause_scene() Can't find Editor component 'EditorRunBar'")
		return false
	var editor_run_bar := nodes[0]
	var containers := editor_run_bar.find_children("*", "HBoxContainer", true, false)
	var pause_icon := GdUnitUiTools.get_icon("Pause")

	for container in containers:
		for child in container.get_children():
			if child is Button:
				var button: Button = child
				if pause_icon == button.icon:
					button.set_pressed(false)

					var connected_signals := button.get_signal_connection_list("pressed")
					if not connected_signals.is_empty():
						for signal_ in connected_signals:
							var cb: Callable = signal_["callable"]
							cb.call()
						return true
	push_error("GdUnitCommandTestSession:force_pause_scene() Can't find Editor component 'EditorRunBar'")
	return false


func execute(...parameters: Array) -> void:
	var tests_to_execute: Array[GdUnitTestCase] = parameters[0]
	_is_debug = parameters[1]

	_prepare_test_session(tests_to_execute)
	if _is_debug:
		EditorInterface.play_custom_scene("res://addons/gdUnit4/src/core/runners/GdUnitTestRunner.tscn")
	else:
		var arguments := Array()
		if OS.is_stdout_verbose():
			arguments.append("--verbose")
		arguments.append("--no-window")
		arguments.append("--path")
		arguments.append(ProjectSettings.globalize_path("res://"))
		arguments.append("res://addons/gdUnit4/src/core/runners/GdUnitTestRunner.tscn")
		_current_runner_process_id = OS.create_process(OS.get_executable_path(), arguments, false);
	_is_running = true


func _prepare_test_session(tests_to_execute: Array[GdUnitTestCase]) -> void:
	var server_port: int = Engine.get_meta("gdunit_server_port")
	var result := GdUnitRunnerConfig.new() \
		.set_server_port(server_port) \
		.do_fail_fast(_is_fail_fast) \
		.add_test_cases(tests_to_execute) \
		.save_config()
	if result.is_error():
		push_error(result.error_message())
		return
	# before start we have to save all scrpt changes
	ScriptEditorControls.save_all_open_script()
