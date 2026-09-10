@tool
extends Control

signal select_failure_next()
signal select_failure_prevous()
signal select_error_next()
signal select_error_prevous()
signal select_flaky_next()
signal select_flaky_prevous()
signal select_skipped_next()
signal select_skipped_prevous()
signal select_orphan_next()
signal select_orphan_prevous()

@warning_ignore("unused_signal")
signal tree_view_mode_changed(flat :bool)


@onready var _button_sync: Button = %btn_tree_sync
@onready var _button_view_mode: MenuButton = %btn_tree_mode
@onready var _button_sort_mode: MenuButton = %btn_tree_sort
@onready var _icon_template: SpinBox = %icon_template
@onready var time_value: Label = %time_value
@onready var time_icon: TextureRect = %time_icon

const STATE = GdUnitInspectorTreeConstants.STATE

var total_failed := 0
var total_errors := 0
var total_flaky := 0
var total_skipped := 0
var total_orphans := 0
var _timer: LocalTime


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
	_button_sync.icon = GdUnitUiTools.get_icon("Loop")
	_set_sort_mode_menu_options()
	_set_view_mode_menu_options()
	_init_status_pannels()
	time_value.text = "0ms"
	time_icon.texture = GdUnitUiTools.get_icon("Time")

	GdUnitSignals.instance().gdunit_event.connect(_on_gdunit_event)
	GdUnitSignals.instance().gdunit_settings_changed.connect(_on_settings_changed)


func _process(_delta: float) -> void:
	if _timer:
		time_value.text = _timer.elapsed_since()


func _init_status_pannels() -> void:
	_init_statistic_panels(STATE.FAILED)
	_init_statistic_panels(STATE.ERROR)
	_init_statistic_panels(STATE.FLAKY)
	_init_statistic_panels(STATE.SKIPPED)
	_init_statistic_panels(STATE.ORPHAN)


func _notification(what: int) -> void:
	if what == EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED:
		_init_status_pannels()


func _init_statistic_panels(state: STATE) -> void:
	var panel: Control = find_child(str(STATE.keys()[state]), true, false)
	var icon: TextureRect = panel.find_child("icon")
	if icon.texture == null:
		icon.texture = GdUnitUiTools.get_state_icon(state)
		icon.tooltip_text = panel.get_tooltip_text()
	var value: LineEdit = panel.find_child("value")
	value.text = "0"
	value.tooltip_text = panel.get_tooltip_text()
	var btn_up: TextureButton = panel.find_child("up")
	var btn_down: TextureButton = panel.find_child("down")
	var up_icon := _icon_template.get_theme_icon("up_hover")
	var texture_normal := ImageTexture.create_from_image(
		GdUnitUiTools._modulate_image(up_icon.get_image(),
		Color.GRAY)
		)
	var texture_hover := ImageTexture.create_from_image(
		GdUnitUiTools._modulate_image(up_icon.get_image(),
		Color.WHITE)
		)
	var texture_pressed := ImageTexture.create_from_image(
		GdUnitUiTools._modulate_image(up_icon.get_image(),
		Color.SKY_BLUE)
		)

	btn_up.texture_normal = texture_normal
	btn_up.texture_hover = texture_hover
	btn_up.texture_pressed = texture_pressed
	btn_down.texture_normal = texture_normal
	btn_down.texture_hover = texture_hover
	btn_down.texture_pressed = texture_pressed
	if not btn_up.pressed.is_connected(_on_button_up):
		btn_up.pressed.connect(_on_button_up.bind(state))
	if not btn_down.pressed.is_connected(_on_button_down):
		btn_down.pressed.connect(_on_button_down.bind(state))


func _on_button_up(state: STATE) -> void:
	match state:
		STATE.FAILED:
			select_failure_prevous.emit()
		STATE.ERROR:
			select_error_prevous.emit()
		STATE.FLAKY:
			select_flaky_prevous.emit()
		STATE.SKIPPED:
			select_skipped_prevous.emit()
		STATE.ORPHAN:
			select_orphan_prevous.emit()


func _on_button_down(state: STATE) -> void:
	match state:
		STATE.FAILED:
			select_failure_next.emit()
		STATE.ERROR:
			select_error_next.emit()
		STATE.FLAKY:
			select_flaky_next.emit()
		STATE.SKIPPED:
			select_skipped_next.emit()
		STATE.ORPHAN:
			select_orphan_next.emit()


func _update_statistics(state: STATE, count: int) -> void:
	var panel: Node = find_child(str(STATE.keys()[state]), true, false)
	var value: LineEdit = panel.find_child("value")
	value.text = str(count)


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


func status_changed(errors: int, failed: int, flaky: int, skipped: int, orphans: int) -> void:
	total_failed += failed
	total_errors += errors
	total_flaky += flaky
	total_skipped += skipped
	total_orphans += orphans
	_update_statistics(STATE.FAILED, total_failed)
	_update_statistics(STATE.ERROR, total_errors)
	_update_statistics(STATE.FLAKY, total_flaky)
	_update_statistics(STATE.SKIPPED, total_skipped)
	_update_statistics(STATE.ORPHAN, total_orphans)


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
			total_orphans = 0
			status_changed(total_errors, total_failed, total_flaky, total_skipped, total_orphans)

		GdUnitEvent.TESTCASE_AFTER:
			status_changed(event.error_count(), event.failed_count(), event.is_flaky(), event.is_skipped(), event.orphan_nodes())

		GdUnitEvent.TESTSUITE_AFTER:
			status_changed(event.error_count(), event.failed_count(),  event.is_flaky(), 0, event.orphan_nodes())

		GdUnitEvent.SESSION_START:
			disable_buttons(true)
			_timer = LocalTime.now()

		GdUnitEvent.SESSION_CLOSE, GdUnitEvent.STOP:
			disable_buttons(false)
			_timer = null


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


func _on_btn_orphan_up_pressed() -> void:
	select_orphan_prevous.emit()


func _on_btn_orphan_down_pressed() -> void:
	select_orphan_next.emit()


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
