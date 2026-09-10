class_name ProductionGameRoot
extends Control

signal boot_completed

enum State {
	BOOT,
	HOME,
	BATTLE_LOADING,
	BATTLE_ACTIVE,
	PAUSE_PENDING,
	BATTLE_PAUSED,
	RESUME_PREPARING,
	BATTLE_ENDING,
	SETTLEMENT,
	CONTROLLED_FAULT,
}

enum Status {
	OK,
	WRONG_STATE,
	CONFIG_ERROR,
	VIEWPORT_GATE_ERROR,
	BATTLE_CREATE_ERROR,
}

const CONFIG_PATH := "res://assets/config/production_defaults.json"
const ACTIVATION_SUCCESS := &"ACTIVATION_SUCCESS"
const BATTLE_ACTIVE_PAUSE_SCREEN_ID := 8
const BATTLE_ACTIVE_PAUSE_NODE_ID := 7001
const BATTLE_ACTIVE_PAUSE_COMMAND_KIND := 1
const BATTLE_ACTIVE_PAUSE_REASON := 1
const BATTLE_ACTIVE_PAUSE_SOURCE := 1
const BattleScopeScene := preload("res://src/gameplay/battle/BattleScope.tscn")
const HomeScreenScene := preload("res://src/ui/HomeScreen.tscn")
const SettlementScreenScene := preload("res://src/ui/SettlementScreen.tscn")

@onready var page_host: Node = $PageHost

var state: State = State.BOOT
var current_battle: ProductionBattleScope
var current_page: Control
var battle_generation: int = 0
var physics_tick: int = 0
var viewport_gate_held: bool = false
var root_viewport: Viewport
var root_identity: int = 0
var viewport_identity: int = 0
var last_result_victory: bool = false
var last_result_level: int = 0
var last_result_kills: int = 0
var last_result_elapsed: float = 0.0

var _config: Dictionary
var _touch_trace_enabled: bool = false
var _touch_trace_count: int = 0
var _transition_pending: bool = false
var _accessibility_screen_generation: int = 1
var _accessibility_layout_generation: int = 1
var _last_battle_active_pause_command_id: int = 0
var _last_battle_active_pause_input_event_id: int = 0
var _input_bootstrap_valid: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_install_production_theme()
	Input.set_use_accumulated_input(false)
	root_viewport = get_viewport()
	root_identity = get_instance_id()
	viewport_identity = root_viewport.get_instance_id()
	_input_bootstrap_valid = not Input.is_using_accumulated_input() \
			and not bool(ProjectSettings.get_setting("input_devices/buffering/agile_event_flushing", true))
	Input.flush_buffered_events()
	_touch_trace_enabled = "--touch-trace" in OS.get_cmdline_user_args()
	call_deferred("_boot")

func _exit_tree() -> void:
	get_tree().paused = false
	if is_instance_valid(root_viewport):
		root_viewport.gui_disable_input = false

func _physics_process(delta: float) -> void:
	if state != State.BATTLE_ACTIVE or current_battle == null or _transition_pending:
		return
	physics_tick += 1
	if not current_battle.run_input_phase(physics_tick):
		_enter_fault("INPUT_MOVEMENT_COMMIT_FAILED")
		return
	if not current_battle.run_gameplay_phase(delta):
		_enter_fault("BATTLE_TICK_FAILED")
		return
	if current_battle.pending_upgrade:
		request_pause(true)
		return
	if current_battle.terminal_pending:
		_transition_pending = true
		state = State.BATTLE_ENDING
		_complete_battle_end.call_deferred(current_battle.victory)

func _process(_delta: float) -> void:
	if current_battle == null or (state != State.BATTLE_PAUSED and state != State.RESUME_PREPARING):
		return
	var input_status := current_battle.service_pending_input_fault(physics_tick)
	if input_status != ProductionInputSystem.Status.OK:
		_enter_fault("INPUT_CALLBACK_FAILURE_%d" % input_status)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P and state == State.BATTLE_ACTIVE:
			request_pause(false)
		elif event.keycode == KEY_R and state == State.BATTLE_PAUSED:
			request_resume()

func _input(event: InputEvent) -> void:
	if not _touch_trace_enabled or _touch_trace_count >= 256:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_touch_trace_count += 1
		print("TOUCH_TRACE seq=%d type=touch index=%d pressed=%s pos=%s state=%s" % [_touch_trace_count, touch.index, touch.pressed, touch.position, State.keys()[state]])
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_touch_trace_count += 1
		print("TOUCH_TRACE seq=%d type=drag index=%d pos=%s relative=%s state=%s" % [_touch_trace_count, drag.index, drag.position, drag.relative, State.keys()[state]])

func _install_production_theme() -> void:
	var cjk_font := SystemFont.new()
	cjk_font.font_names = PackedStringArray(["PingFang SC", "Heiti SC", "Arial Unicode MS"])
	cjk_font.allow_system_fallback = true
	var production_theme := Theme.new()
	production_theme.default_font = cjk_font
	theme = production_theme

## Starts a production battle while retaining GameRoot and the root Viewport.
## Example: `await game_root.request_start_battle(1234, false)`.
func request_start_battle(seed: int = 0, use_smoke_mode: bool = false) -> Status:
	if state != State.HOME and state != State.SETTLEMENT:
		return Status.WRONG_STATE
	state = State.BATTLE_LOADING
	_transition_pending = true
	if acquire_viewport_input_gate() != Status.OK:
		return _enter_fault("START_GATE_ACQUIRE_FAILED")
	await _detach_current_child()
	var result := _create_battle(seed, use_smoke_mode)
	if result != Status.OK:
		return _enter_fault("BATTLE_CREATE_FAILED")
	state = State.BATTLE_ACTIVE
	_transition_pending = false
	get_tree().paused = false
	if release_viewport_input_gate(ACTIVATION_SUCCESS) != Status.OK:
		return _enter_fault("START_GATE_RELEASE_FAILED")
	return Status.OK

## Pauses the active battle after input cancellation. Example: `game_root.request_pause(false)`.
func request_pause(for_upgrade: bool = false) -> Status:
	if state != State.BATTLE_ACTIVE or current_battle == null:
		return Status.WRONG_STATE
	state = State.PAUSE_PENDING
	if acquire_viewport_input_gate() != Status.OK:
		return _enter_fault("PAUSE_GATE_ACQUIRE_FAILED")
	if not current_battle.lock_for_pause(physics_tick):
		return _enter_fault("PAUSE_INPUT_LOCK_FAILED")
	get_tree().paused = true
	state = State.BATTLE_PAUSED
	if for_upgrade:
		current_battle.battle_ui.show_upgrade()
	else:
		current_battle.battle_ui.show_pause()
	if release_viewport_input_gate(ACTIVATION_SUCCESS) != Status.OK:
		return _enter_fault("PAUSE_GATE_RELEASE_FAILED")
	return Status.OK

## Sole owner/reducer for BattleActivePauseCommandV1. The presenter and bridge
## may validate and enqueue this typed payload, but never pause the tree.
func submit_battle_active_pause_command(command: Dictionary) -> Status:
	if state != State.BATTLE_ACTIVE or current_battle == null:
		return Status.WRONG_STATE
	if int(command.get("schema_version", 0)) != 1 \
			or int(command.get("screen_id", 0)) != BATTLE_ACTIVE_PAUSE_SCREEN_ID \
			or int(command.get("node_id", 0)) != BATTLE_ACTIVE_PAUSE_NODE_ID \
			or int(command.get("screen_generation", 0)) != _accessibility_screen_generation \
			or int(command.get("layout_generation", 0)) != _accessibility_layout_generation \
			or int(command.get("command_kind", 0)) != BATTLE_ACTIVE_PAUSE_COMMAND_KIND \
			or int(command.get("pause_reason", 0)) != BATTLE_ACTIVE_PAUSE_REASON \
			or int(command.get("source", 0)) != BATTLE_ACTIVE_PAUSE_SOURCE \
			or not bool(command.get("enabled", false)):
		return Status.WRONG_STATE
	var command_id := int(command.get("command_id", 0))
	var input_event_id := int(command.get("input_event_id", 0))
	if command_id <= _last_battle_active_pause_command_id or input_event_id <= _last_battle_active_pause_input_event_id:
		return Status.WRONG_STATE
	_last_battle_active_pause_command_id = command_id
	_last_battle_active_pause_input_event_id = input_event_id
	return request_pause(false)

## Resumes only after the battle modal and old carrier are cleared.
## Example: `game_root.request_resume()`.
func request_resume() -> Status:
	if state != State.BATTLE_PAUSED or current_battle == null or current_battle.pending_upgrade:
		return Status.WRONG_STATE
	state = State.RESUME_PREPARING
	if acquire_viewport_input_gate() != Status.OK:
		return _enter_fault("RESUME_GATE_ACQUIRE_FAILED")
	current_battle.battle_ui.hide_modal()
	if not current_battle.resume():
		return _enter_fault("RESUME_INPUT_OPEN_FAILED")
	get_tree().paused = false
	state = State.BATTLE_ACTIVE
	if release_viewport_input_gate(ACTIVATION_SUCCESS) != Status.OK:
		return _enter_fault("RESUME_GATE_RELEASE_FAILED")
	return Status.OK

## Replaces only the battle child and preserves persistent-root identities.
## Example: `await game_root.request_replace_battle(5678, true)`.
func request_replace_battle(seed: int = 0, use_smoke_mode: bool = false) -> Status:
	if state != State.BATTLE_ACTIVE and state != State.BATTLE_PAUSED:
		return Status.WRONG_STATE
	_transition_pending = true
	state = State.BATTLE_LOADING
	if acquire_viewport_input_gate() != Status.OK:
		return _enter_fault("REPLACE_GATE_ACQUIRE_FAILED")
	get_tree().paused = false
	await _detach_current_child()
	var result := _create_battle(seed, use_smoke_mode)
	if result != Status.OK:
		return _enter_fault("REPLACEMENT_CREATE_FAILED")
	state = State.BATTLE_ACTIVE
	_transition_pending = false
	if release_viewport_input_gate(ACTIVATION_SUCCESS) != Status.OK:
		return _enter_fault("REPLACE_GATE_RELEASE_FAILED")
	return Status.OK

## Ends a battle and opens settlement after the frame-end destruction barrier.
## Example: `await game_root.request_end_battle(true)`.
func request_end_battle(victory_value: bool) -> Status:
	if state != State.BATTLE_ACTIVE and state != State.BATTLE_PAUSED:
		return Status.WRONG_STATE
	state = State.BATTLE_ENDING
	_transition_pending = true
	return await _complete_battle_end(victory_value)

## Returns from settlement to HOME without replacing GameRoot.
## Example: `await game_root.request_home()`.
func request_home() -> Status:
	if state != State.SETTLEMENT:
		return Status.WRONG_STATE
	_transition_pending = true
	if acquire_viewport_input_gate() != Status.OK:
		return _enter_fault("HOME_GATE_ACQUIRE_FAILED")
	await _detach_current_child()
	_create_home()
	state = State.HOME
	_transition_pending = false
	if release_viewport_input_gate(ACTIVATION_SUCCESS) != Status.OK:
		return _enter_fault("HOME_GATE_RELEASE_FAILED")
	return Status.OK

## Acquires the physical root Viewport gate. GameRoot is its only writer.
## Example: `assert(game_root.acquire_viewport_input_gate() == Status.OK)`.
func acquire_viewport_input_gate() -> Status:
	if root_viewport == null or root_viewport != get_viewport() or viewport_gate_held:
		return Status.VIEWPORT_GATE_ERROR
	root_viewport.gui_disable_input = true
	viewport_gate_held = root_viewport.gui_disable_input
	return Status.OK if viewport_gate_held else Status.VIEWPORT_GATE_ERROR

## Releases the gate only after destination activation succeeds.
## Example: `game_root.release_viewport_input_gate(ACTIVATION_SUCCESS)`.
func release_viewport_input_gate(reason: StringName) -> Status:
	if reason != ACTIVATION_SUCCESS or not viewport_gate_held:
		return Status.VIEWPORT_GATE_ERROR
	root_viewport.gui_disable_input = false
	if root_viewport.gui_disable_input:
		return Status.VIEWPORT_GATE_ERROR
	viewport_gate_held = false
	return Status.OK

func _boot() -> void:
	if not _input_bootstrap_valid:
		_enter_fault("INPUT_BOOTSTRAP_INVALID")
		return
	if acquire_viewport_input_gate() != Status.OK:
		_enter_fault("BOOT_GATE_ACQUIRE_FAILED")
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		_enter_fault("CONFIG_OPEN_FAILED")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int((parsed as Dictionary).get("schema_version", 0)) != 1:
		_enter_fault("CONFIG_SCHEMA_INVALID")
		return
	_config = parsed
	_create_home()
	state = State.HOME
	if release_viewport_input_gate(ACTIVATION_SUCCESS) != Status.OK:
		_enter_fault("BOOT_GATE_RELEASE_FAILED")
		return
	boot_completed.emit()
	print("PRODUCTION_BOOT_OK root=%d viewport=%d state=HOME" % [root_identity, viewport_identity])
	if "--production-smoke" in OS.get_cmdline_user_args():
		_run_production_smoke.call_deferred()

func _create_home() -> void:
	current_page = HomeScreenScene.instantiate() as Control
	current_page.name = "HomeScreen"
	current_page.theme = theme
	(current_page as ProductionHomeScreen).start_requested.connect(_on_start_requested)
	page_host.add_child(current_page)

func _create_battle(seed: int, use_smoke_mode: bool) -> Status:
	battle_generation += 1
	current_battle = BattleScopeScene.instantiate() as ProductionBattleScope
	current_battle.name = "BattleScope_%03d" % battle_generation
	page_host.add_child(current_battle)
	if not current_battle.configure(_config, seed, use_smoke_mode):
		return Status.BATTLE_CREATE_ERROR
	current_battle.battle_ui.theme = theme
	current_battle.pause_requested.connect(_on_pause_requested)
	current_battle.battle_active_pause_command.connect(_on_battle_active_pause_command)
	current_battle.upgrade_selected.connect(_on_upgrade_selected)
	if not current_battle.activate():
		return Status.BATTLE_CREATE_ERROR
	return Status.OK

func _create_settlement() -> void:
	current_page = SettlementScreenScene.instantiate() as Control
	current_page.name = "SettlementScreen"
	current_page.theme = theme
	page_host.add_child(current_page)
	var settlement := current_page as ProductionSettlementScreen
	settlement.present(last_result_victory, last_result_level, last_result_kills, last_result_elapsed)
	settlement.retry_requested.connect(_on_retry_requested)
	settlement.home_requested.connect(_on_home_requested)

func _detach_current_child() -> void:
	var old_child: Node = current_battle if current_battle != null else current_page
	if old_child == null:
		return
	if current_battle != null:
		current_battle.teardown()
		current_battle = null
	else:
		current_page = null
	page_host.remove_child(old_child)
	old_child.queue_free()
	await get_tree().process_frame

func _complete_battle_end(victory_value: bool) -> Status:
	if current_battle == null:
		return _enter_fault("END_WITHOUT_BATTLE")
	if acquire_viewport_input_gate() != Status.OK:
		return _enter_fault("END_GATE_ACQUIRE_FAILED")
	last_result_victory = victory_value
	last_result_level = current_battle.level
	last_result_kills = current_battle.kills
	last_result_elapsed = minf(current_battle.elapsed_time, current_battle.duration_seconds)
	get_tree().paused = false
	await _detach_current_child()
	_create_settlement()
	state = State.SETTLEMENT
	_transition_pending = false
	if release_viewport_input_gate(ACTIVATION_SUCCESS) != Status.OK:
		return _enter_fault("END_GATE_RELEASE_FAILED")
	return Status.OK

func _on_start_requested() -> void:
	request_start_battle.call_deferred(0, false)

func _on_retry_requested() -> void:
	request_start_battle.call_deferred(0, false)

func _on_home_requested() -> void:
	request_home.call_deferred()

func _on_pause_requested() -> void:
	request_pause(false)

func _on_battle_active_pause_command(command: Dictionary) -> void:
	var status := submit_battle_active_pause_command(command)
	if status != Status.OK:
		push_error("BATTLE_ACTIVE_PAUSE_COMMAND_REJECTED status=%d" % status)

func _on_upgrade_selected(choice: int) -> void:
	if state != State.BATTLE_PAUSED or current_battle == null:
		return
	if current_battle.pending_upgrade:
		if not current_battle.apply_upgrade(choice):
			_enter_fault("UPGRADE_APPLY_FAILED")
			return
		request_resume()
	elif choice == 0:
		request_resume()

func _enter_fault(reason: String) -> Status:
	get_tree().paused = false
	state = State.CONTROLLED_FAULT
	_transition_pending = false
	push_error("PRODUCTION_CONTROLLED_FAULT reason=%s" % reason)
	return Status.CONFIG_ERROR

func _run_production_smoke() -> void:
	var start_status := await request_start_battle(20260910, true)
	if start_status != Status.OK:
		print("PRODUCTION_SMOKE_FAIL phase=start status=%d" % start_status)
		get_tree().quit(1)
		return
	await get_tree().process_frame
	var pause_command := {
		"schema_version": 1,
		"command_id": 1,
		"input_event_id": 1,
		"screen_id": BATTLE_ACTIVE_PAUSE_SCREEN_ID,
		"screen_generation": 1,
		"layout_generation": 1,
		"node_id": BATTLE_ACTIVE_PAUSE_NODE_ID,
		"command_kind": BATTLE_ACTIVE_PAUSE_COMMAND_KIND,
		"pause_reason": BATTLE_ACTIVE_PAUSE_REASON,
		"source": BATTLE_ACTIVE_PAUSE_SOURCE,
		"enabled": true,
	}
	if submit_battle_active_pause_command(pause_command) != Status.OK \
			or request_resume() != Status.OK \
			or submit_battle_active_pause_command(pause_command) == Status.OK:
		print("PRODUCTION_SMOKE_FAIL phase=pause_resume")
		get_tree().quit(1)
		return
	var replace_status := await request_replace_battle(20260911, true)
	if replace_status != Status.OK:
		print("PRODUCTION_SMOKE_FAIL phase=replace status=%d" % replace_status)
		get_tree().quit(1)
		return
	var deadline := Time.get_ticks_msec() + 25000
	while state != State.SETTLEMENT and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if state != State.SETTLEMENT or not last_result_victory or last_result_level < 1:
		print("PRODUCTION_SMOKE_FAIL phase=gameplay state=%s victory=%s level=%d kills=%d" % [State.keys()[state], last_result_victory, last_result_level, last_result_kills])
		get_tree().quit(1)
		return
	print("PRODUCTION_SMOKE_PASS generation=%d level=%d kills=%d seconds=%.2f root=%d viewport=%d" % [battle_generation, last_result_level, last_result_kills, last_result_elapsed, root_identity, viewport_identity])
	get_tree().quit(0)
