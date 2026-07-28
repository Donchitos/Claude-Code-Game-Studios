class_name GdUnitCommandInspectorRerunTestsUntilFailure
extends GdUnitBaseCommand


signal session_closed()


const InspectorTreeMainPanel := preload("res://addons/gdUnit4/src/ui/parts/InspectorTreeMainPanel.gd")
const ID := "Rerun Inspector Tests Until Failure"


var _test_session_command: GdUnitCommandTestSession
var _current_execution_count := 0


func _init(test_session_command: GdUnitCommandTestSession) -> void:
	super(ID, GdUnitShortcut.ShortCut.RERUN_TESTS_UNTIL_FAILURE)
	icon = GdUnitUiTools.get_icon("Play")
	_test_session_command = test_session_command


func is_running() -> bool:
	return _test_session_command.is_running()


func execute(..._parameters: Array) -> void:
	var base_control := EditorInterface.get_base_control()
	var inspector: InspectorTreeMainPanel = base_control.get_meta("GdUnit4Inspector")
	var selected_item := inspector._tree.get_selected()
	var tests_to_execute := inspector.collect_test_cases(selected_item)
	var rerun_until_failure_count := GdUnitSettings.get_rerun_max_retries()
	var saved_settings: bool = ProjectSettings.get_setting(GdUnitSettings.TEST_FLAKY_CHECK)
	ProjectSettings.set_setting(GdUnitSettings.TEST_FLAKY_CHECK, false)

	GdUnitSignals.instance().gdunit_event.connect(_on_test_event)
	_current_execution_count = 0

	_test_session_command._is_fail_fast = true
	while _current_execution_count < rerun_until_failure_count:
		_test_session_command.execute(tests_to_execute, true)
		await session_closed
	_test_session_command._is_fail_fast = false

	ProjectSettings.set_setting(GdUnitSettings.TEST_FLAKY_CHECK, saved_settings)
	GdUnitSignals.instance().gdunit_event.disconnect(_on_test_event)


func _on_test_event(event: GdUnitEvent) -> void:
	if event.type() == GdUnitEvent.SESSION_START:
		_current_execution_count += 1
		GdUnitSignals.instance().gdunit_message.emit("[color=RED]Execution Mode: ReRun until failure! (iteration %d)[/color]" % _current_execution_count)
	if event.type() == GdUnitEvent.SESSION_CLOSE:
		session_closed.emit()
	if event.type() == GdUnitEvent.TESTCASE_AFTER:
		if not event.is_success():
			GdUnitSignals.instance().gdunit_message.emit(" [color=RED](iteration: %d)[/color]" % _current_execution_count)
			_current_execution_count = 9999
