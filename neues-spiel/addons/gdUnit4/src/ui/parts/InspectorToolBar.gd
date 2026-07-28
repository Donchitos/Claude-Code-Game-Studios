@tool
extends PanelContainer


const  InspectorTreeMainPanel := preload("res://addons/gdUnit4/src/ui/parts/InspectorTreeMainPanel.gd")

@onready var _version_label: Control = %version
@onready var _button_wiki: Button = %help
@onready var _tool_button: Button = %tool
@onready var _button_run_overall: Button = %run_overall
@onready var _button_run: Button = %run
@onready var _button_run_debug: Button = %debug
@onready var _button_stop: Button = %stop


var inspector: InspectorTreeMainPanel
var command_handler: GdUnitCommandHandler


func _ready() -> void:
	command_handler = GdUnitCommandHandler.instance()
	inspector = get_parent().get_parent().find_child("MainPanel", false, false)
	if inspector == null:
		push_error("Internal error, can't connect to the test inspector!")
	else:
		inspector.tree_item_selected.connect(_on_inspector_selected)

	GdUnit4Version.init_version_label(_version_label)

	GdUnitSignals.instance().gdunit_event.connect(_on_gdunit_event)
	GdUnitSignals.instance().gdunit_settings_changed.connect(_on_settings_changed)
	_init_buttons()


func _init_buttons() -> void:
	_init_button(_button_run_overall, GdUnitCommandRunTestsOverall.ID)
	_init_button(_button_run, GdUnitCommandInspectorRunTests.ID)
	_init_button(_button_run_debug, GdUnitCommandInspectorDebugTests.ID)
	_init_button(_button_stop, GdUnitCommandStopTestSession.ID)

	_button_stop.icon = command_handler.command_icon(GdUnitCommandStopTestSession.ID)
	_tool_button.icon = GdUnitUiTools.get_icon("Tools")
	_button_wiki.icon = GdUnitUiTools.get_icon("HelpSearch")
	# Set run buttons initial disabled
	_button_run.disabled = true
	_button_run_debug.disabled = true


func _init_button(button: Button, comand_id: String) -> void:
	button.set_meta("GdUnitCommand", comand_id)
	button.icon = command_handler.command_icon(comand_id)
	button.shortcut = command_handler.command_shortcut(comand_id)
	if button == _button_run_overall:
		button.visible = GdUnitSettings.is_inspector_toolbar_button_show()


func _on_inspector_selected(item: TreeItem) -> void:
	var button_disabled := item == null
	_button_run.disabled = button_disabled
	_button_run_debug.disabled = button_disabled


func _on_gdunit_event(event: GdUnitEvent) -> void:
	if event.type() == GdUnitEvent.SESSION_START:
		_button_run_overall.disabled = true
		_button_run.disabled = true
		_button_run_debug.disabled = true
		_button_stop.disabled = false
		return
	if event.type() == GdUnitEvent.SESSION_CLOSE:
		_button_run_overall.disabled = false
		_button_stop.disabled = true


func _on_button_pressed(source: BaseButton) -> void:
	var command_id: String = source.get_meta("GdUnitCommand")
	await command_handler.command_execute(command_id)


func _on_wiki_pressed() -> void:
	var status := OS.shell_open("https://godot-gdunit-labs.github.io/gdUnit4/latest")
	if status != OK:
		push_error("Can't open GdUnit4 documentaion page: %s" % error_string(status))


func _on_btn_tool_pressed() -> void:
	var settings_dlg: Window = EditorInterface.get_base_control().find_child("GdUnitSettingsDialog", false, false)
	if settings_dlg == null:
		settings_dlg = preload("res://addons/gdUnit4/src/ui/settings/GdUnitSettingsDialog.tscn").instantiate()
		EditorInterface.get_base_control().add_child(settings_dlg, true)
	settings_dlg.popup_centered_ratio(.60)


func _on_settings_changed(property: GdUnitProperty) -> void:
	# needs to wait a frame to be command handler notified first for settings changes
	await get_tree().process_frame

	_button_run_overall.visible = GdUnitSettings.is_inspector_toolbar_button_show()

	if property.name().begins_with(GdUnitSettings.GROUP_SHORTCUT_INSPECTOR):
		_button_run.shortcut = command_handler.command_shortcut(GdUnitCommandInspectorRunTests.ID)
		_button_run_debug.shortcut = command_handler.command_shortcut(GdUnitCommandInspectorDebugTests.ID)
		_button_run_overall.shortcut = command_handler.command_shortcut(GdUnitCommandRunTestsOverall.ID)
		_button_stop.shortcut = command_handler.command_shortcut(GdUnitCommandStopTestSession.ID)
