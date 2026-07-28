@tool
extends PanelContainer

signal select_failure_next()
signal select_failure_prevous()
signal select_error_next()
signal select_error_prevous()
signal select_flaky_next()
signal select_flaky_prevous()
signal select_skipped_next()
signal select_skipped_prevous()

@warning_ignore("unused_signal")
signal tree_view_mode_changed(flat :bool)

@onready var _errors: Label = %error_value
@onready var _failures: Label = %failure_value
@onready var _flaky_value: Label = %flaky_value
@onready var _skipped_value: Label = %skipped_value
#@onready var _button_failure_up: Button = %btn_failure_up
#@onready var _button_failure_down: Button = %btn_failure_down
@onready var _button_sync: Button = %btn_tree_sync
@onready var _button_view_mode: MenuButton = %btn_tree_mode
@onready var _button_sort_mode: MenuButton = %btn_tree_sort

@onready var _icon_errors: TextureRect = %icon_errors
@onready var _icon_failures: TextureRect = %icon_failures
@onready var _icon_flaky: TextureRect = %icon_flaky
@onready var _icon_skipped: TextureRect = %icon_skipped

var total_failed := 0
var total_errors := 0
var total_flaky := 0
var total_skipped := 0


var icon_mappings := {
	# tree sort modes
	0x100 + GdUnitInspectorTreeConstants.SORT_MODE.UNSORTED : GdUnitUiTools.get_icon("TripleBar"),
	0x100 + GdUnitInspectorTreeConstants.SORT_MODE.NAME_ASCENDING : GdUnitUiTools.get_icon("Sort"),
	0x100 + GdUnitInspectorTreeConstants.SORT_MODE.NAME_DESCENDING : GdUnitUiTools.get_flipped_icon("Sort"),
	0x100 + GdUnitInspectorTreeConstants.SORT_MODE.EXECUTION_TIME : GdUnitUiTools.get_icon("History"),
	# tree view modes
	0x200 + GdUnitInspectorTreeConstants.TREE_VIEW_MODE.TREE : GdUnitUiTools.get_icon("Tree", Color.GHOST_WHITE),
	0x200 + GdUnitInspectorTreeConstants.TREE_VIEW_MODE.FLAT : GdUnitUiTools.get_icon("AnimationTrackGroup", Color.GHOST_WHITE)
}


@warning_ignore("return_value_discarded")
func _ready() -> void:
	_failures.text = "0"
	_errors.text = "0"
	_flaky_value.text = "0"
	_skipped_value.text = "0"
	_icon_failures.texture = GdUnitUiTools.get_icon("StatusError", Color.SKY_BLUE)
	_icon_errors.texture = GdUnitUiTools.get_icon("StatusError", Color.DARK_RED)
	_icon_flaky.texture = GdUnitUiTools.get_icon("CheckBox", Color.GREEN_YELLOW)
	_icon_skipped.texture = GdUnitUiTools.get_icon("CheckBox", Color.WEB_GRAY)

	#_button_failure_up.icon = GdUnitUiTools.get_icon("ArrowUp")
	#_button_failure_down.icon = GdUnitUiTools.get_icon("ArrowDown")
	_button_sync.icon = GdUnitUiTools.get_icon("Loop")
	_set_sort_mode_menu_options()
	_set_view_mode_menu_options()
	GdUnitSignals.instance().gdunit_event.connect(_on_gdunit_event)
	GdUnitSignals.instance().gdunit_settings_changed.connect(_on_settings_changed)


func _set_sort_mode_menu_options() -> void:
	_button_sort_mode.icon = GdUnitUiTools.get_icon("Sort")
	# construct context sort menu according to the available modes
	var context_menu :PopupMenu = _button_sort_mode.get_popup()
	context_menu.clear()

	if not context_menu.index_pressed.is_connected(_on_sort_mode_changed):
		@warning_ignore("return_value_discarded")
		context_menu.index_pressed.connect(_on_sort_mode_changed)

	var configured_sort_mode := GdUnitSettings.get_inspector_tree_sort_mode()
	for sort_mode: String in GdUnitInspectorTreeConstants.SORT_MODE.keys():
		var enum_value :int =  GdUnitInspectorTreeConstants.SORT_MODE.get(sort_mode)
		var icon :Texture2D = icon_mappings[0x100 + enum_value]
		context_menu.add_icon_check_item(icon, normalise(sort_mode), enum_value)
		context_menu.set_item_checked(enum_value, configured_sort_mode == enum_value)


func _set_view_mode_menu_options() -> void:
	_button_view_mode.icon = GdUnitUiTools.get_icon("Tree", Color.GHOST_WHITE)
	# construct context tree view menu according to the available modes
	var context_menu :PopupMenu = _button_view_mode.get_popup()
	context_menu.clear()

	if not context_menu.index_pressed.is_connected(_on_tree_view_mode_changed):
		@warning_ignore("return_value_discarded")
		context_menu.index_pressed.connect(_on_tree_view_mode_changed)

	var configured_tree_view_mode := GdUnitSettings.get_inspector_tree_view_mode()
	for tree_view_mode: String in GdUnitInspectorTreeConstants.TREE_VIEW_MODE.keys():
		var enum_value :int =  GdUnitInspectorTreeConstants.TREE_VIEW_MODE.get(tree_view_mode)
		var icon :Texture2D = icon_mappings[0x200 + enum_value]
		context_menu.add_icon_check_item(icon, normalise(tree_view_mode), enum_value)
		context_menu.set_item_checked(enum_value, configured_tree_view_mode == enum_value)


func normalise(value: String) -> String:
	var parts := value.to_lower().split("_")
	parts[0] = parts[0].capitalize()
	return " ".join(parts)


func status_changed(errors: int, failed: int, flaky: int, skipped: int) -> void:
	total_failed += failed
	total_errors += errors
	total_flaky += flaky
	total_skipped += skipped
	_failures.text = str(total_failed)
	_errors.text = str(total_errors)
	_flaky_value.text = str(total_flaky)
	_skipped_value.text = str(total_skipped)


func disable_buttons(value :bool) -> void:
	_button_sync.set_disabled(value)
	_button_sort_mode.set_disabled(value)
	_button_view_mode.set_disabled(value)


func _on_gdunit_event(event: GdUnitEvent) -> void:
	match event.type():
		GdUnitEvent.DISCOVER_START:
			disable_buttons(true)

		GdUnitEvent.DISCOVER_END:
			disable_buttons(false)

		GdUnitEvent.INIT:
			total_errors = 0
			total_failed = 0
			total_flaky = 0
			total_skipped = 0
			status_changed(total_errors, total_failed, total_flaky, total_skipped)

		GdUnitEvent.TESTCASE_AFTER:
			status_changed(event.error_count(), event.failed_count(), event.is_flaky(), event.is_skipped())

		GdUnitEvent.TESTSUITE_AFTER:
			status_changed(event.error_count(), event.failed_count(),  event.is_flaky(), 0)

		GdUnitEvent.SESSION_START:
			disable_buttons(true)

		GdUnitEvent.SESSION_CLOSE:
			disable_buttons(false)


func _on_btn_error_up_pressed() -> void:
	select_error_prevous.emit()


func _on_btn_error_down_pressed() -> void:
	select_error_next.emit()


func _on_failure_up_pressed() -> void:
	select_failure_prevous.emit()


func _on_failure_down_pressed() -> void:
	select_failure_next.emit()


func _on_btn_flaky_up_pressed() -> void:
	select_flaky_prevous.emit()


func _on_btn_flaky_down_pressed() -> void:
	select_flaky_next.emit()


func _on_btn_skipped_up_pressed() -> void:
	select_skipped_prevous.emit()


func _on_btn_skipped_down_pressed() -> void:
	select_skipped_next.emit()


func _on_btn_tree_sync_pressed() -> void:
	await GdUnitTestDiscoverer.run()


func _on_sort_mode_changed(index: int) -> void:
	var selected_sort_mode :GdUnitInspectorTreeConstants.SORT_MODE = GdUnitInspectorTreeConstants.SORT_MODE.values()[index]
	GdUnitSettings.set_inspector_tree_sort_mode(selected_sort_mode)


func _on_tree_view_mode_changed(index: int) ->void:
	var selected_tree_mode :GdUnitInspectorTreeConstants.TREE_VIEW_MODE = GdUnitInspectorTreeConstants.TREE_VIEW_MODE.values()[index]
	GdUnitSettings.set_inspector_tree_view_mode(selected_tree_mode)


################################################################################
# external signal receiver
################################################################################
func _on_settings_changed(property :GdUnitProperty) -> void:
	if property.name() == GdUnitSettings.INSPECTOR_TREE_SORT_MODE:
		_set_sort_mode_menu_options()
	if property.name() == GdUnitSettings.INSPECTOR_TREE_VIEW_MODE:
		_set_view_mode_menu_options()
