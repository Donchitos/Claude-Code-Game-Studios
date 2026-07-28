@tool
extends PanelContainer

signal jump_to_orphan_nodes()

@onready var ICON_GREEN := GdUnitUiTools.get_icon("Unlinked", Color.WEB_GREEN)
@onready var ICON_RED := GdUnitUiTools.get_color_animated_icon("Unlinked", Color.YELLOW, Color.ORANGE_RED)

@onready var _button_time: Button = %btn_time
@onready var _time: Label = %time_value
@onready var _orphans: Label = %orphan_value
@onready var _orphan_button: Button = %btn_orphan

var total_elapsed_time := 0
var total_orphans := 0


func _ready() -> void:
	@warning_ignore("return_value_discarded")
	GdUnitSignals.instance().gdunit_event.connect(_on_gdunit_event)
	_time.text = ""
	_orphans.text = "0"
	_button_time.icon = GdUnitUiTools.get_icon("Time")
	_orphan_button.icon = ICON_GREEN


func status_changed(elapsed_time: int, orphan_nodes: int) -> void:
	total_elapsed_time += elapsed_time
	total_orphans += orphan_nodes
	_time.text = LocalTime.elapsed(total_elapsed_time)
	_orphans.text = str(total_orphans)
	if total_orphans > 0:
		_orphan_button.icon = ICON_RED


func _on_gdunit_event(event: GdUnitEvent) -> void:
	match event.type():
		GdUnitEvent.INIT:
			_orphan_button.icon = ICON_GREEN
			total_elapsed_time = 0
			total_orphans = 0
			status_changed(0, 0)
		GdUnitEvent.TESTCASE_BEFORE:
			pass
		GdUnitEvent.TESTCASE_AFTER:
			status_changed(0, event.orphan_nodes())
		GdUnitEvent.TESTSUITE_BEFORE:
			pass
		GdUnitEvent.TESTSUITE_AFTER:
			status_changed(event.elapsed_time(), event.orphan_nodes())


func _on_ToolButton_pressed() -> void:
	jump_to_orphan_nodes.emit()
