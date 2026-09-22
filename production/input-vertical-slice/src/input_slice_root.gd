class_name GameRootSlice
extends Control

const InputSystemScript := preload("res://src/input_system.gd")
const HostScript := preload("res://src/virtual_joystick_host.gd")
const BattleUiScript := preload("res://src/battle_ui_slice.gd")

const STATUS_OK := 0
const STATUS_WRONG_STATE := 5
const STATUS_VIEWPORT_MISMATCH := 6
const ACTIVATION_SUCCESS := &"ACTIVATION_SUCCESS"

var input_system: InputSystem
var host: VirtualJoystickHost
var player_position := Vector2(360.0, 520.0)
var tick: int = 0
var status_label: Label
var carrier_label: Label
var state_label: Label
var battle_ui: BattleUiSlice
var battle_ui_layer: CanvasLayer
var battle_scope: Control
var battle_scope_generation: int = 0
var root_viewport: Viewport
var viewport_gate_held: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(720.0, 1280.0)
	root_viewport = get_viewport()
	if acquire_viewport_input_gate() != STATUS_OK:
		push_error("GAME_ROOT_VIEWPORT_GATE_ACQUIRE_FAILED")
		return
	queue_redraw()
	if _create_battle_scope() != STATUS_OK:
		return
	_build_overlay()
	input_system.publish_runtime_state(InputSystem.State.ACTIVE)
	_set_status("ACTIVE — drag the joystick or use the buttons")
	if release_viewport_input_gate(ACTIVATION_SUCCESS) != STATUS_OK:
		_set_status("VIEWPORT RELEASE FAILED")
		return
	print("INPUT_VERTICAL_SLICE_RUNTIME_OK state=ACTIVE active_vj_count=%s carrier=%s" % [host.registered_active_vj_count(), input_system.carrier.direction])

func _exit_tree() -> void:
	if is_instance_valid(root_viewport):
		root_viewport.gui_disable_input = false

## GameRoot owns the physical root-Viewport input gate.
func acquire_viewport_input_gate() -> int:
	if root_viewport == null or root_viewport != get_viewport():
		return STATUS_VIEWPORT_MISMATCH
	if viewport_gate_held:
		return STATUS_WRONG_STATE
	root_viewport.gui_disable_input = true
	viewport_gate_held = root_viewport.gui_disable_input
	return STATUS_OK if viewport_gate_held else STATUS_WRONG_STATE

## Only the successful activation release opens physical input delivery.
func release_viewport_input_gate(reason: StringName) -> int:
	if reason != ACTIVATION_SUCCESS or not viewport_gate_held:
		return STATUS_WRONG_STATE
	root_viewport.gui_disable_input = false
	if root_viewport.gui_disable_input:
		return STATUS_WRONG_STATE
	viewport_gate_held = false
	return STATUS_OK

func _create_battle_scope() -> int:
	if battle_scope != null:
		return STATUS_WRONG_STATE
	battle_scope_generation += 1
	battle_scope = Control.new()
	battle_scope.name = "BattleScope_%03d" % battle_scope_generation
	battle_scope.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_scope.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(battle_scope)

	input_system = InputSystemScript.new()
	input_system.name = "InputSystem"
	battle_scope.add_child(input_system)
	host = HostScript.new()
	host.name = "VirtualJoystickHost"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_PASS
	battle_scope.add_child(host)
	if not host.initialize():
		_set_status("HOST INIT FAILED")
		return STATUS_WRONG_STATE
	var init_status := input_system.initialize(host)
	if init_status != InputSystem.InputStatus.OK:
		_set_status("INPUT INIT FAILED: %s" % init_status)
		return init_status
	battle_ui_layer = CanvasLayer.new()
	battle_ui_layer.name = "BattleUICanvasLayer"
	battle_ui_layer.layer = 10
	battle_scope.add_child(battle_ui_layer)
	battle_ui = BattleUiScript.new()
	battle_ui.name = "BattleUI"
	battle_ui_layer.add_child(battle_ui)
	battle_ui.build()
	return STATUS_OK

## Replaces only the battle child scope while retaining this GameRoot and root Viewport.
func replace_battle_scope() -> int:
	if battle_scope == null:
		return STATUS_WRONG_STATE
	if acquire_viewport_input_gate() != STATUS_OK:
		return STATUS_WRONG_STATE
	var old_scope := battle_scope
	if input_system != null:
		input_system.teardown()
	remove_child(old_scope)
	old_scope.queue_free()
	battle_scope = null
	input_system = null
	host = null
	battle_ui = null
	battle_ui_layer = null
	if _create_battle_scope() != STATUS_OK:
		return STATUS_WRONG_STATE
	if input_system.publish_runtime_state(InputSystem.State.ACTIVE) != InputSystem.InputStatus.OK:
		return STATUS_WRONG_STATE
	return release_viewport_input_gate(ACTIVATION_SUCCESS)

func pause_battle_scope() -> int:
	if input_system == null:
		return STATUS_WRONG_STATE
	var status := input_system.cancel_input(tick)
	if status != InputSystem.InputStatus.OK:
		return status
	return input_system.publish_runtime_state(InputSystem.State.RESUME_LOCKED)

func resume_battle_scope() -> int:
	if input_system == null:
		return STATUS_WRONG_STATE
	return input_system.publish_runtime_state(InputSystem.State.ACTIVE)

## Detaches the battle child and intentionally keeps the physical gate held for the next page owner.
func teardown_battle_scope() -> int:
	if battle_scope == null:
		return STATUS_WRONG_STATE
	if acquire_viewport_input_gate() != STATUS_OK:
		return STATUS_WRONG_STATE
	var old_scope := battle_scope
	if input_system != null:
		input_system.teardown()
	remove_child(old_scope)
	old_scope.queue_free()
	battle_scope = null
	input_system = null
	host = null
	battle_ui = null
	battle_ui_layer = null
	return STATUS_OK

func _physics_process(_delta: float) -> void:
	if input_system == null or input_system.state != InputSystem.State.ACTIVE:
		return
	tick += 1
	var sampled := Input.get_vector(&"touch_move_left", &"touch_move_right", &"touch_move_up", &"touch_move_down", 0.0)
	var status := input_system.run_phase(&"MOVEMENT_COMMIT", sampled, tick)
	if status == InputSystem.InputStatus.OK:
		player_position += input_system.carrier.direction * 4.5
		player_position.x = clampf(player_position.x, 32.0, 688.0)
		player_position.y = clampf(player_position.y, 180.0, 1060.0)
		_update_labels()
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			_pause_input()
		elif event.keycode == KEY_R:
			_resume_input()
		elif event.keycode == KEY_B:
			_rebuild_input()

func _pause_input() -> void:
	if input_system.cancel_input(tick) == InputSystem.InputStatus.OK:
		input_system.publish_runtime_state(InputSystem.State.RESUME_LOCKED)
		_set_status("RESUME_LOCKED — press R to resume")

func _resume_input() -> void:
	if input_system.publish_runtime_state(InputSystem.State.ACTIVE) == InputSystem.InputStatus.OK:
		_set_status("ACTIVE — fresh movement input accepted")

func _rebuild_input() -> void:
	var status := input_system.ensure_rebuilt_after_invalidation(tick + 1)
	_set_status("REBUILD status=%s, active_vj_count=%s" % [status, host.registered_active_vj_count()])

func _build_overlay() -> void:
	var title := Label.new()
	title.text = "INPUT VERTICAL SLICE"
	title.position = Vector2(32.0, 28.0)
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	state_label = Label.new()
	state_label.position = Vector2(32.0, 78.0)
	add_child(state_label)
	status_label = Label.new()
	status_label.position = Vector2(32.0, 108.0)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size = Vector2(650.0, 58.0)
	add_child(status_label)
	carrier_label = Label.new()
	carrier_label.position = Vector2(32.0, 172.0)
	add_child(carrier_label)
	var hint := Label.new()
	hint.text = "P: pause   R: resume   B: rebuild   |   movement source: empty InputMap actions"
	hint.position = Vector2(32.0, 1120.0)
	add_child(hint)
	_update_labels()

func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text

func _update_labels() -> void:
	if input_system == null or state_label == null:
		return
	state_label.text = "state=%s  callbacks=%s  ingress=%s  shield=%s" % [input_system.State.keys()[input_system.state], input_system.callbacks_armed, input_system.runtime_ingress_armed, input_system.shield_bank_service_enabled]
	carrier_label.text = "carrier.direction=%s  active=%s  generation=%s  tick=%s\nplayer=%s" % [input_system.carrier.direction, input_system.carrier.is_active, input_system.carrier.press_generation, input_system.carrier.written_tick, player_position]

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07141a"))
	draw_circle(player_position, 24.0, Color("76d6a5"))
	draw_circle(Vector2(360.0, 620.0), 210.0, Color(0.16, 0.28, 0.31, 0.2), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(260.0, 870.0), "Dynamic VirtualJoystick", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9bb8be"))
