class_name GdUnitCommandScriptEditorCreateTest
extends GdUnitBaseCommand


const ID := "Create Test"


func _init() -> void:
	super(ID, GdUnitShortcut.ShortCut.CREATE_TEST)
	icon =  GdUnitUiTools.get_icon("New")


func is_running() -> bool:
	return false


func execute(..._parameters: Array) -> void:
	if not _is_active_script_editor():
		return
	var cursor_line := _active_base_editor().get_caret_line()
	var result := GdUnitTestSuiteBuilder.create(_active_script(), cursor_line)
	if result.is_error():
		# show error dialog
		push_error("Failed to create test case: %s" % result.error_message())
		return
	var info: Dictionary = result.value()
	var script_path: String = info.get("path")
	var script_line: int = info.get("line")
	ScriptEditorControls.edit_script(script_path, script_line)


func _is_active_script_editor() -> bool:
	return EditorInterface.get_script_editor().get_current_editor() != null


func _active_base_editor() -> TextEdit:
	return EditorInterface.get_script_editor().get_current_editor().get_base_editor()


func _active_script() -> Script:
	return EditorInterface.get_script_editor().get_current_script()
