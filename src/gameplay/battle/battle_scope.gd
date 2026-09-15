class_name ProductionBattleScope
extends Node

signal pause_requested
signal upgrade_selected(choice: int)
signal battle_active_pause_command(command: Dictionary)

enum State {
	CREATED,
	ACTIVE,
	PAUSED,
	TERMINATED,
}

@onready var stage: ProductionStageRuntime = $StageRuntime
@onready var player: ProductionPlayerController = $PlayerController
@onready var input_system: ProductionInputSystem = $InputSystem
@onready var joystick_host: ProductionVirtualJoystickHost = $InputLayer/VirtualJoystickHost
@onready var battle_ui: ProductionBattleUI = $BattleUILayer/BattleUI

var state: State = State.CREATED
var duration_seconds: float
var elapsed_time: float = 0.0
var level: int = 1
var xp: int = 0
var kills: int = 0
var first_upgrade_time: float = -1.0
var pending_upgrade: bool = false
var terminal_pending: bool = false
var victory: bool = false
var smoke_mode: bool = false
var progression_projection: Dictionary = {}
var completed_active_ticks := 0
var _tick_accumulator := 0.0
var _snapshot_barrier_ready := true
var movement_context: PcMovementContext
var movement_carrier: ProductionMovementIntentCarrier

var _config: Dictionary
var _upgrades: Dictionary
var _xp_base: int
var _xp_per_level: int
var _smoke_speed_multiplier: float
var _hud_refresh_seconds: float
var _hud_left: float = 0.0


## Injects immutable run configuration and preallocates battle-owned systems.
## Example: `scope.configure(config, 1234, false)`.
func configure(config: Dictionary, seed: int, use_smoke_mode: bool,
		carrier: ProductionMovementIntentCarrier, context: PcMovementContext) -> bool:
	if state != State.CREATED or config.is_empty():
		return false
	_config = config
	progression_projection = (config.get("progression_projection", {}) as Dictionary).duplicate(true)
	_upgrades = config["upgrades"]
	_xp_base = int(_upgrades["xp_base"])
	_xp_per_level = int(_upgrades["xp_per_level"])
	var run_config: Dictionary = config["run"]
	duration_seconds = float(run_config["duration_seconds"])
	_smoke_speed_multiplier = float(run_config["smoke_speed_multiplier"])
	_hud_refresh_seconds = float(run_config["hud_refresh_seconds"])
	smoke_mode = use_smoke_mode
	player.configure(config["player"], progression_projection)
	if not stage.configure(config, seed):
		return false
	if smoke_mode:
		# Smoke mode validates lifecycle and settlement, not balance or movement UX.
		player.hp = 1000000000.0
	movement_carrier = carrier
	movement_context = context
	# The mobile Host stays uninitialized and hidden in the PC scene.
	joystick_host.hide()
	if input_system.initialize(config["input"], carrier, context) != ProductionInputSystem.Status.OK:
		return false
	player.bind_movement(carrier, context)
	battle_ui.configure_generation(context.battle_generation)
	battle_ui.battle_active_pause_command.connect(func(command: Dictionary) -> void: battle_active_pause_command.emit(command))
	battle_ui.upgrade_selected.connect(func(choice: int) -> void: upgrade_selected.emit(choice))
	battle_ui.update_hud(self)
	return true

## Opens this scope for GameRoot-driven physics phases. Example: `scope.activate()`.
func activate() -> bool:
	if state != State.CREATED:
		return false
	if input_system.activate() != ProductionInputSystem.Status.OK:
		return false
	state = State.ACTIVE
	return true

## Runs one production battle tick; this scope has no autonomous process callback.
## Example: `scope.run_tick(delta, tick)`.
func run_tick(delta: float, tick: int) -> bool:
	if tick < 1:
		return false
	return run_gameplay_phase(delta)

## GameRoot owns the phase schedule; this is the only production input phase entry.
func run_input_phase(tick: int) -> bool:
	if state != State.ACTIVE or terminal_pending:
		return false
	if not movement_context.begin(tick):
		return false
	if input_system.run_phase(&"MOVEMENT_COMMIT", movement_context, movement_context.lease_id) != ProductionInputSystem.Status.OK:
		return false
	return true

## GameRoot calls this after InputSystem's MOVEMENT_COMMIT has completed.
func run_gameplay_phase(delta: float) -> bool:
	if state != State.ACTIVE or terminal_pending or not is_finite(delta) or delta < 0.0:
		return false
	var step_delta := delta * (_smoke_speed_multiplier if smoke_mode else 1.0)
	_tick_accumulator += step_delta
	while _tick_accumulator + 0.000000001 >= 1.0 / 60.0 and not terminal_pending and not pending_upgrade:
		_tick_accumulator -= 1.0 / 60.0
		if not _run_fixed_tick():
			return false
	return true

func _run_fixed_tick() -> bool:
	_snapshot_barrier_ready = false
	if not run_input_phase(movement_context.tick + 1):
		return false
	var step_delta := 1.0 / 60.0
	elapsed_time = float(completed_active_ticks + 1) / 60.0
	if smoke_mode:
		# Explicit smoke mode supplies a deterministic test carrier, never the normal PC path.
		var direction := stage.smoke_move_direction(elapsed_time, player.position)
		if direction == Vector2.ZERO:
			movement_carrier.clear(movement_context.tick)
		else:
			movement_carrier.write(direction.normalized(), 1, movement_context.tick)
	if not player.consume_movement(movement_carrier, movement_context, movement_context.lease_id, step_delta):
		return false
	if not movement_context.finish():
		return false
	if not stage.run_phase(&"STAGE_SIMULATE", step_delta, elapsed_time, player):
		return false
	completed_active_ticks += 1
	kills += stage.kills_gained_this_tick
	if stage.xp_gained_this_tick > 0:
		xp += stage.xp_gained_this_tick
		_process_level_up()
	_hud_left -= step_delta
	if _hud_left <= 0.0:
		_hud_left += _hud_refresh_seconds
		battle_ui.update_hud(self)
	if stage.boss_defeated:
		victory = true
		terminal_pending = true
	elif not player.is_alive():
		victory = false
		terminal_pending = true
	elif elapsed_time >= duration_seconds:
		victory = not stage.boss_enabled
		terminal_pending = true
	if terminal_pending:
		pending_upgrade = false
	_snapshot_barrier_ready = true
	return true

## Locks input before GameRoot pauses SceneTree. Example: `scope.lock_for_pause(20)`.
func lock_for_pause(tick: int) -> bool:
	if state != State.ACTIVE:
		return false
	if input_system.lock_for_pause(tick) != ProductionInputSystem.Status.OK:
		return false
	if input_system.confirm_paused() != ProductionInputSystem.Status.OK:
		return false
	state = State.PAUSED
	return true

## Reopens the battle after the pause UI is closed. Example: `scope.resume()`.
func resume() -> bool:
	if state != State.PAUSED:
		return false
	if input_system.prepare_resume() != ProductionInputSystem.Status.OK:
		return false
	if input_system.activate() != ProductionInputSystem.Status.OK:
		return false
	state = State.ACTIVE
	return true

func service_pending_input_fault(tick: int) -> ProductionInputSystem.Status:
	return input_system.service_pending_input_fault(tick)

## Applies the selected upgrade while the scope remains paused.
## Example: `scope.apply_upgrade(2)`.
func apply_upgrade(choice: int) -> bool:
	if state != State.PAUSED or not pending_upgrade:
		return false
	if not player.apply_upgrade(choice, _upgrades):
		return false
	pending_upgrade = false
	battle_ui.update_hud(self)
	return true

## Closes battle-owned callbacks and input. Example: `scope.teardown()`.
func teardown() -> bool:
	if state == State.TERMINATED:
		return true
	input_system.teardown()
	state = State.TERMINATED
	var stage_clean := stage.teardown()
	return stage_clean

## Returns required XP for the current level. Example: `scope.xp_required()`.
func xp_required() -> int:
	return _xp_base + (level - 1) * _xp_per_level

func _process_level_up() -> void:
	if pending_upgrade or xp < xp_required():
		return
	xp -= xp_required()
	level += 1
	if first_upgrade_time < 0.0:
		first_upgrade_time = elapsed_time
	if smoke_mode:
		player.apply_upgrade((level - 2) % 3, _upgrades)
	else:
		pending_upgrade = true
