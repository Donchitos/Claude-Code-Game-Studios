extends SceneTree

var failures := 0
var checks := 0

# Contract oracle independent of PcMetaInput.ROWS: keycode, shift, joy button.
const EXPECTED := {
	"ui_focus_next": [[KEY_TAB, false], JOY_BUTTON_DPAD_DOWN],
	"ui_focus_previous": [[KEY_TAB, true], JOY_BUTTON_DPAD_UP],
	"ui_focus_left": [[KEY_LEFT, false], JOY_BUTTON_DPAD_LEFT],
	"ui_focus_right": [[KEY_RIGHT, false], JOY_BUTTON_DPAD_RIGHT],
	"ui_activate": [[KEY_ENTER, false], JOY_BUTTON_A, [KEY_SPACE, false]],
	"ui_back": [[KEY_ESCAPE, false], JOY_BUTTON_B],
	"ui_increment": [[KEY_EQUAL, false], JOY_BUTTON_RIGHT_SHOULDER, [KEY_PLUS, false]],
	"ui_decrement": [[KEY_MINUS, false], JOY_BUTTON_LEFT_SHOULDER],
	"pc_pause": [[KEY_P, false], JOY_BUTTON_START],
	"pc_resume": [[KEY_R, false]],
}

func verify_bindings() -> void:
	for action: String in EXPECTED:
		var actual := InputMap.action_get_events(action)
		var expected: Array = EXPECTED[action]
		check(actual.size() == expected.size(), "exact event count " + action)
		check(InputMap.action_get_deadzone(action) == 0.0, "no extra Meta deadzone " + action)
		for i in mini(actual.size(), expected.size()):
			var event: InputEvent = actual[i]
			if expected[i] is Array:
				check(event is InputEventKey, "keyboard binding type " + action)
				if not event is InputEventKey:
					continue
				var k := event as InputEventKey
				check(k.keycode == expected[i][0] and k.physical_keycode == 0 and k.unicode == 0 and k.key_label == 0 \
					and k.shift_pressed == expected[i][1] and not k.ctrl_pressed and not k.alt_pressed and not k.meta_pressed \
					and not k.command_or_control_autoremap and not k.pressed and not k.echo, "exact key/modifier tuple " + action)
				var press := k.duplicate() as InputEventKey
				press.pressed = true
				check(PcMetaInput.action_for(press) == action, "exact press routes " + action)
				press.ctrl_pressed = true
				check(PcMetaInput.action_for(press) == &"", "extra Ctrl rejected " + action)
			else:
				check(event is InputEventJoypadButton and event.button_index == expected[i] and event.device == -1, "exact mapped controller binding " + action)
				var probe := InputEventJoypadButton.new()
				probe.button_index = expected[i]
				probe.device = 919
				probe.pressed = true
				check(probe.is_action_pressed(action, false, true), "nonzero device matches wildcard " + action)
				check(PcMetaInput.action_for(probe) == &"", "unknown wildcard source still rejected " + action)
	for action: StringName in [&"ui_accept", &"ui_select", &"ui_cancel", &"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_page_up", &"ui_page_down", &"ui_home", &"ui_end"]:
		check(not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty(), "no default GUI bypass " + action)

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func key(code: Key, shift := false, echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.shift_pressed = shift
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	if not echo:
		var release := event.duplicate() as InputEventKey
		release.pressed = false
		Input.parse_input_event(release)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := load("res://src/core/GameRoot.tscn").instantiate() as ProductionGameRoot
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	verify_bindings()
	check(root.gui_get_focus_owner() == game.current_page._start_button, "initial Home focus")
	key(KEY_ENTER)
	await process_frame
	await process_frame
	check(game.state == ProductionGameRoot.State.BATTLE_ACTIVE, "engine Enter starts once")
	check(game.battle_generation == 1, "no duplicate start")
	var battle := game.current_battle
	check(battle.battle_ui.mouse_filter == Control.MOUSE_FILTER_IGNORE, "noninteractive battle root ignores GUI hit")
	key(KEY_P)
	check(game.state == ProductionGameRoot.State.BATTLE_PAUSED and paused, "P uses pause command gateway")
	key(KEY_ENTER, false, true)
	check(game.state == ProductionGameRoot.State.BATTLE_PAUSED, "echo cannot activate Continue")
	check(root.gui_get_focus_owner() == battle.battle_ui._choice_buttons[0], "modal initial focus")
	check(battle.battle_ui._pause_button.focus_mode == Control.FOCUS_NONE and battle.battle_ui._pause_button.disabled, "background pause not focusable")
	for code: Key in [KEY_UP, KEY_DOWN, KEY_KP_ENTER]:
		key(code)
		check(game.state == ProductionGameRoot.State.BATTLE_PAUSED and root.gui_get_focus_owner() == battle.battle_ui._choice_buttons[0], "default GUI input cannot escape or resume %s" % code)
	key(KEY_ESCAPE)
	check(game.state == ProductionGameRoot.State.BATTLE_ACTIVE and not paused, "Escape resumes ordinary pause")
	battle.pending_upgrade = true
	check(game.request_pause(true) == 0, "show upgrade")
	for code: Key in [KEY_UP, KEY_DOWN, KEY_KP_ENTER]:
		key(code)
		check(battle.pending_upgrade and root.gui_get_focus_owner() == battle.battle_ui._choice_buttons[0], "default GUI input cannot escape or choose %s" % code)
	var unknown := InputEventJoypadButton.new()
	unknown.device = 919
	unknown.button_index = JOY_BUTTON_DPAD_DOWN
	unknown.pressed = true
	check(not Input.is_joy_known(unknown.device), "unknown device fixture")
	Input.parse_input_event(unknown)
	unknown = unknown.duplicate()
	unknown.pressed = false
	Input.parse_input_event(unknown)
	check(root.gui_get_focus_owner() == battle.battle_ui._choice_buttons[0], "rejected device cannot use Control focus fallback")
	key(KEY_ESCAPE)
	check(game.state == ProductionGameRoot.State.BATTLE_PAUSED and battle.pending_upgrade, "Back cannot select upgrade")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == battle.battle_ui._choice_buttons[1], "Tab next choice")
	key(KEY_TAB, true)
	check(root.gui_get_focus_owner() == battle.battle_ui._choice_buttons[0], "ShiftTab previous choice")
	key(KEY_LEFT)
	check(root.gui_get_focus_owner() == battle.battle_ui._choice_buttons[2], "left wraps within modal")
	key(KEY_RIGHT)
	var swords_before := battle.player.sword_count
	key(KEY_ENTER)
	check(battle.player.sword_count == swords_before + 1 and not battle.pending_upgrade and not paused, "one event commits exactly one upgrade")
	check(not battle.battle_ui._pause_button.disabled and battle.battle_ui._pause_button.focus_mode == Control.FOCUS_ALL, "background focus restored on resume")
	await game.request_end_battle(true)
	check(root.gui_get_focus_owner() == game.current_page._retry, "settlement initial focus")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == game.current_page._home, "settlement next")
	key(KEY_ENTER)
	await process_frame
	await process_frame
	check(game.state == ProductionGameRoot.State.HOME, "keyboard complete journey returns Home")
	await game.request_start_battle(42, false)
	check(game.request_pause() == 0, "second battle modal")
	if DisplayServer.get_name() != "headless":
		var evidence_directory := "res://production/playtest-evidence/pc-input-r3-r8-2026-09-11"
		DirAccess.make_dir_recursive_absolute(evidence_directory)
		for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
			root.size = dimensions
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var ui := game.current_battle.battle_ui
			check(ui.get_viewport_rect().encloses(ui._choice_buttons[0].get_global_rect()), "Continue visible at %s" % dimensions)
			check(root.get_texture().get_image().save_png(evidence_directory + "/pc-pause-%dx%d.png" % [dimensions.x, dimensions.y]) == OK, "capture focus and neutral instructions")
	game.queue_free()
	await process_frame
	print("PC_META_INPUT_%s checks=%d event_route=true physical_device=false renderer=%s" % ["PASS" if failures == 0 else "FAIL", checks, DisplayServer.get_name()])
	quit(0 if failures == 0 else 1)
