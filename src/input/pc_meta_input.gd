class_name PcMetaInput
extends RefCounted

## Exact PC bindings. The two shortcut rows share the same app-root dispatcher.
const ROWS := {
	&"ui_focus_next": [[KEY_TAB, false], JOY_BUTTON_DPAD_DOWN],
	&"ui_focus_previous": [[KEY_TAB, true], JOY_BUTTON_DPAD_UP],
	&"ui_focus_left": [[KEY_LEFT, false], JOY_BUTTON_DPAD_LEFT],
	&"ui_focus_right": [[KEY_RIGHT, false], JOY_BUTTON_DPAD_RIGHT],
	&"ui_activate": [[KEY_ENTER, false], JOY_BUTTON_A, [KEY_SPACE, false]],
	&"ui_back": [[KEY_ESCAPE, false], JOY_BUTTON_B],
	&"ui_increment": [[KEY_EQUAL, false], JOY_BUTTON_RIGHT_SHOULDER, [KEY_PLUS, false]],
	&"ui_decrement": [[KEY_MINUS, false], JOY_BUTTON_LEFT_SHOULDER],
	&"pc_pause": [[KEY_P, false], JOY_BUTTON_START],
	&"pc_resume": [[KEY_R, false]],
}

## Installs the frozen mapping at BOOT before any input target is active.
static func install() -> void:
	# Control defaults must not bypass the explicit PC navigation/activation table.
	for action: StringName in [&"ui_accept", &"ui_select", &"ui_cancel", &"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_page_up", &"ui_page_down", &"ui_home", &"ui_end"]:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
	for action: StringName in ROWS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.0)
		InputMap.action_erase_events(action)
		InputMap.action_set_deadzone(action, 0.0)
		for binding: Variant in ROWS[action]:
			if binding is Array:
				var key := InputEventKey.new()
				key.keycode = binding[0]
				key.shift_pressed = binding[1]
				InputMap.action_add_event(action, key)
			else:
				var button := InputEventJoypadButton.new()
				button.device = -1 # Match every mapped controller; action_for rejects unknown devices.
				button.button_index = binding
				InputMap.action_add_event(action, button)

## Returns one action for a physical press; repeats cannot activate a second time.
static func action_for(event: InputEvent) -> StringName:
	if not event.is_pressed() or event.is_echo():
		return &""
	if event is InputEventJoypadButton and not Input.is_joy_known(event.device):
		return &""
	for action: StringName in ROWS:
		if event.is_action_pressed(action, false, true):
			return action
	return &""
