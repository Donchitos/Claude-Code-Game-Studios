@tool
extends ScrollContainer


@onready var _hooks_list: VBoxContainer = %hook_list
@onready var _hook_row_template: Panel = %row_template
@onready var _hook_description: RichTextLabel = %hook_description
@onready var _btn_move_up: Button = %hook_actions/btn_move_up
@onready var _btn_move_down: Button = %hook_actions/btn_move_down
@onready var _btn_delete: Button = %hook_actions/btn_delete_hook
@onready var _select_hook_dlg: FileDialog = %select_hook_dlg
@onready var _error_msg_popup: AcceptDialog = %error_msg_popup


var _selected_row: Control = null
var selected_style := StyleBoxFlat.new()


func _ready() -> void:
	selected_style.set_border_color(Color.DODGER_BLUE)
	selected_style.set_border_width_all(2)
	selected_style.set_corner_radius_all(4)
	selected_style.set_draw_center(false)

	for hook: GdUnitTestSessionHook in GdUnitTestSessionHookService.instance().enigne_hooks:
		_create_hook_row(hook)

	_update_focus_relations()

	if _hooks_list.get_child_count() > 0:
		_select_row(_hooks_list.get_child(0))


func _update_focus_relations() -> void:
	var row_count := _hooks_list.get_child_count()
	for hook_index in row_count:
		var current_hook: Control = _hooks_list.get_child(hook_index)
		var previous_hook: Control = current_hook if hook_index == 0 else _hooks_list.get_child(hook_index - 1)
		var next_hook: Control = current_hook if hook_index >= row_count - 1 else _hooks_list.get_child(hook_index + 1)
		current_hook.focus_neighbor_top = previous_hook.get_path()
		current_hook.set_focus_previous(previous_hook.get_path())
		current_hook.focus_neighbor_bottom = next_hook.get_path()
		current_hook.set_focus_next(next_hook.get_path())


func _create_hook_row(hook: GdUnitTestSessionHook) -> Control:
	var is_system := _is_system_hook(hook)
	var panel: Panel = _hook_row_template.duplicate()

	panel.visible = true
	panel.set_meta("hook", hook)
	panel.tooltip_text = "System hook - (Read-only)" if is_system else "User hook"
	panel.focus_entered.connect(_select_row.bind(panel))
	panel.gui_input.connect(func(event: InputEvent) -> void:
		@warning_ignore("unsafe_property_access")
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_row(panel)
			panel.accept_event()
	)

	# Left color indicator border
	var indicator: ColorRect = panel.find_child("Indicator", true, false)
	indicator.color = Color(1.0, 0.76, 0.03, 1) if is_system else Color(0.26, 0.54, 0.89, 1)

	# Hook name
	var name_label: Label = panel.find_child("HookName", true, false)
	name_label.text = hook.name

	# System badge
	if is_system:
		var badge: Control = panel.find_child("SystemBadge", true, false)
		badge.visible = true

	# Enable/disable toggle
	var check: CheckButton = panel.find_child("Enabled", true, false)
	check.button_pressed = GdUnitTestSessionHookService.is_enabled(hook)
	check.toggled.connect(func(enabled: bool) -> void:
		GdUnitTestSessionHookService.instance().enable_hook(hook, enabled)
	)

	_hooks_list.add_child(panel)
	return panel


func _select_row(row: Node) -> void:
	if _selected_row == row:
		return

	if _selected_row != null and is_instance_valid(_selected_row):
		_selected_row.remove_theme_stylebox_override("panel")

	_selected_row = row

	if _selected_row != null:
		_selected_row.grab_focus()

		_selected_row.add_theme_stylebox_override("panel", selected_style)

	_update_hook_buttons()
	_update_hook_description()


func _update_hook_description() -> void:
	if _selected_row == null:
		_hook_description.text = "[i]Select a hook to view its description[/i]"
		return
	_hook_description.text = _get_hook(_selected_row).description


func _update_hook_buttons() -> void:
	if _selected_row == null:
		_btn_move_up.disabled = true
		_btn_move_down.disabled = true
		_btn_delete.disabled = true
		return

	var hook := _get_hook(_selected_row)
	if _is_system_hook(hook):
		_btn_move_up.disabled = true
		_btn_move_down.disabled = true
		_btn_delete.disabled = true
		return

	var idx := _selected_row.get_index()
	var count := _hooks_list.get_child_count()
	var prev: Control = _hooks_list.get_child(idx - 1) if idx > 0 else null
	var next: Control = _hooks_list.get_child(idx + 1) if idx + 1 < count else null

	_btn_move_up.disabled = prev == null or _is_system_hook(_get_hook(prev))
	_btn_move_down.disabled = next == null
	_btn_delete.disabled = false


static func _get_hook(row: Control) -> GdUnitTestSessionHook:
	return row.get_meta("hook")


static func _is_system_hook(hook: GdUnitTestSessionHook) -> bool:
	if hook == null:
		return false
	return hook.get_meta("SYSTEM_HOOK", false)


func _on_btn_add_hook_pressed() -> void:
	_select_hook_dlg.show()


func _on_select_hook_dlg_file_selected(path: String) -> void:
	_select_hook_dlg.set_current_path(path)
	_on_select_hook_dlg_confirmed()


func _on_select_hook_dlg_confirmed() -> void:
	_select_hook_dlg.hide()
	var result := GdUnitTestSessionHookService.instance().load_hook(_select_hook_dlg.get_current_path())
	if result.is_error():
		_error_msg_popup.dialog_text = result.error_message()
		_error_msg_popup.show()
		return

	var hook: GdUnitTestSessionHook = result.value()
	result = GdUnitTestSessionHookService.instance().register(hook)
	if result.is_error():
		_error_msg_popup.dialog_text = result.error_message()
		_error_msg_popup.show()
		return

	var row := _create_hook_row(hook)
	_update_focus_relations()
	_select_row(row)


func _on_btn_delete_hook_pressed() -> void:
	if _selected_row == null:
		return
	GdUnitTestSessionHookService.instance().unregister(_get_hook(_selected_row))

	_hooks_list.remove_child(_selected_row)
	_selected_row.queue_free()

	_update_focus_relations()
	_select_row(_hooks_list.find_next_valid_focus())


func _on_btn_move_up_pressed() -> void:
	if _selected_row == null:
		return
	var idx := _selected_row.get_index() - 1
	if idx <= 0:
		return
	var prev: Control = _hooks_list.get_child(idx)
	_hooks_list.move_child(_selected_row, idx)
	GdUnitTestSessionHookService.instance().move_before(_get_hook(_selected_row), _get_hook(prev))
	_update_focus_relations()
	_update_hook_buttons()


func _on_btn_move_down_pressed() -> void:
	if _selected_row == null:
		return
	var idx := _selected_row.get_index() + 1
	if idx >= _hooks_list.get_child_count():
		return
	var next: Control = _hooks_list.get_child(idx)
	_hooks_list.move_child(_selected_row, idx)
	GdUnitTestSessionHookService.instance().move_after(_get_hook(_selected_row), _get_hook(next))
	_update_focus_relations()
	_update_hook_buttons()
