extends SceneTree

class FixtureSource extends PcInputSource:
	func refresh_devices() -> void:
		pass
	func poll(deadzone: float) -> void:
		valid = keyboard.is_finite() and stick.is_finite()
		all_sticks_neutral = stick.is_finite() and stick.length() <= deadzone

var failures := 0
var checks := 0
var config: Dictionary
var reader: FixtureSource
var movement: ProductionMovementIntentCarrier
var frame: PcMovementContext
var input: ProductionInputSystem

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func tick() -> int:
	check(frame.begin(frame.tick + 1), "open unique lease")
	var result := input.run_phase(&"MOVEMENT_COMMIT", frame, frame.lease_id)
	# Unit sampler has no player; integration below verifies actual consumption.
	frame.consumed = true
	check(frame.finish(), "close sample fixture")
	return result

func _run() -> void:
	Input.set_use_accumulated_input(false)
	config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/config/production_defaults.json"))["input"]
	for invalid: Variant in [0.0, 1.0, NAN, INF, 0.999999999, 1e-50]:
		var bad := config.duplicate(true)
		bad["stick_deadzone"] = invalid
		var rejected := ProductionInputSystem.new()
		var c := PcMovementContext.new()
		c.battle_generation = 1
		check(rejected.initialize(bad, ProductionMovementIntentCarrier.new(), c) == ProductionInputSystem.Status.INVALID_CONFIG, "invalid deadzone rejected")
		check(rejected.state == ProductionInputSystem.State.UNARMED and rejected.carrier == null and not rejected.callbacks_armed, "invalid rounded threshold has zero publication")
		rejected.free()
	var wrong := config.duplicate(true)
	wrong["active_profile"] = "MOBILE_TOUCH"
	var other := ProductionInputSystem.new()
	var other_frame := PcMovementContext.new()
	other_frame.battle_generation = 1
	check(other.initialize(wrong, ProductionMovementIntentCarrier.new(), other_frame) == ProductionInputSystem.Status.INVALID_CONFIG, "future profile fails closed")
	other.free()
	input = ProductionInputSystem.new()
	reader = FixtureSource.new()
	movement = ProductionMovementIntentCarrier.new()
	frame = PcMovementContext.new()
	frame.battle_generation = 12
	check(input.initialize(config, movement, frame, reader) == 0 and input.activate() == 0, "explicit PC initialization")
	for axis: float in [0.0, 0.01, 0.20, 0.2001, 1.0]:
		reader.stick = Vector2(axis, 0)
		check(tick() == 0, "axis sample")
		check(movement.direction == (Vector2.ZERO if axis <= 0.20 else Vector2.RIGHT), "inclusive radial deadzone %s" % axis)
	reader.keyboard = Vector2(1, -1).normalized()
	reader.keyboard_held = true
	reader.stick = Vector2.LEFT
	check(tick() == 0 and movement.direction.is_equal_approx(Vector2(1, -1).normalized()), "keyboard priority diagonal")
	var generation := input.generation
	reader.keyboard = Vector2.RIGHT
	check(tick() == 0 and input.generation == generation, "direction change preserves source generation")
	reader.keyboard = Vector2.ZERO
	check(tick() == 0 and movement.direction == Vector2.ZERO, "opposite keys suppress stick")
	check(input.generation == generation and input.source == ProductionInputSystem.Source.KEYBOARD, "opposing held keys retain keyboard epoch")
	reader.keyboard = Vector2.RIGHT
	check(tick() == 0 and movement.direction == Vector2.RIGHT and input.generation == generation, "W plus S then release S preserves generation")
	reader.keyboard = Vector2.ZERO
	reader.keyboard_held = false
	reader.stick = Vector2.ZERO
	check(tick() == 0 and input.source == ProductionInputSystem.Source.NONE, "complete neutral retires source")
	reader.keyboard = Vector2.RIGHT
	reader.keyboard_held = true
	check(tick() == 0 and input.generation == generation + 1, "fresh keyboard after full neutral increments exactly once")
	generation = input.generation
	reader.keyboard = Vector2.ZERO
	check(input.lock_for_pause(999) == 0 and input.cancel_input(&"PAUSE", 999) == 0 and input.confirm_paused() == 0, "repeat cancel is idempotent")
	check(not input.ingress_armed and not input.shield_bank_service_enabled and movement.direction == Vector2.ZERO, "closed tuple")
	check(input.prepare_resume() == 0 and input.activate() == 0, "held-only resume is not fault")
	reader.stick = Vector2.ZERO
	check(tick() == 0 and movement.direction == Vector2.ZERO and input.neutral_required, "opposite held keys are not neutral")
	reader.keyboard = Vector2.RIGHT
	check(tick() == 0 and movement.direction == Vector2.ZERO, "held key remains blocked")
	reader.keyboard = Vector2.ZERO
	reader.keyboard_held = false
	check(tick() == 0 and not input.neutral_required, "release admits future fresh input")
	reader.keyboard = Vector2.RIGHT
	reader.keyboard_held = true
	check(tick() == 0 and movement.direction == Vector2.RIGHT and input.generation > generation, "fresh press after resume")
	reader.keyboard = Vector2.ZERO
	reader.keyboard_held = false
	reader.stick = Vector2.DOWN
	input.invalidate_sources()
	check(tick() == 0 and movement.direction == Vector2.ZERO, "held axis after reconnect blocked")
	reader.stick = Vector2.ZERO
	tick()
	reader.stick = Vector2.DOWN
	check(tick() == 0 and movement.direction == Vector2.DOWN, "fresh stick after neutral")
	reader.stick = Vector2(NAN, 0)
	check(tick() == ProductionInputSystem.Status.NON_FINITE_INPUT and movement.direction == Vector2.ZERO, "NaN rejected before normalization")
	reader.stick = Vector2(INF, 0)
	check(tick() == ProductionInputSystem.Status.NON_FINITE_INPUT, "Inf rejected")
	input.teardown()
	check(frame.retired and not frame.begin(frame.tick + 1) and not input.callbacks_armed, "retired context refuses writer")
	input.free()
	await _integration()
	print("PC_INPUT_PROFILE_%s checks=%d synthetic=true physical_device=false" % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)

func _integration() -> void:
	var game := load("res://src/core/GameRoot.tscn").instantiate() as ProductionGameRoot
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	check(await game.request_start_battle(135, false) == 0, "production start")
	var battle := game.current_battle
	battle.stage._spawn_left = 999.0
	check(battle.joystick_host.active_joystick_count() == 0, "zero mobile instances")
	Input.action_press(&"move_right")
	game._physics_process(3.0 / 60.0)
	check(battle.completed_active_ticks == 3 and battle.input_system.sample_count == 3 and battle.player.movement_consume_count == 3, "hitch samples per actual simulation tick")
	var before := battle.player.position
	check(not battle.player.consume_movement(battle.movement_carrier, battle.movement_context, battle.movement_context.lease_id, 1.0/60.0) and battle.player.position == before, "closed lease replay zero effect")
	check(game.request_pause() == 0 and paused, "held pause")
	check(game.request_resume() == 0, "held resume")
	for i in 4:
		game._physics_process(1.0/60.0)
	check(battle.player.position == before, "real action held cannot resume movement")
	Input.action_release(&"move_right")
	game._physics_process(1.0/60.0)
	Input.action_press(&"move_right")
	game._physics_process(1.0/60.0)
	check(battle.player.position.x > before.x, "fresh action moves")
	Input.action_release(&"move_right")
	game._on_window_focus_exited()
	check(game.state == ProductionGameRoot.State.BATTLE_PAUSED and paused and game.request_resume() != 0, "focus loss freezes and rejects resume")
	game._on_window_focus_entered()
	check(game.state == ProductionGameRoot.State.BATTLE_PAUSED, "refocus does not auto resume")
	check(game.request_resume() == 0, "explicit refocus continue")
	var old_ui := battle.battle_ui
	old_ui._on_battle_active_pause_pressed()
	check(game.state == ProductionGameRoot.State.BATTLE_PAUSED, "first generation 7001")
	game.request_resume()
	var old_context := battle.movement_context
	check(await game.request_replace_battle(136, false) == 0 and old_context.retired, "replacement retires context")
	game.current_battle.battle_ui._on_battle_active_pause_pressed()
	check(game.state == ProductionGameRoot.State.BATTLE_PAUSED, "second generation first pause accepted")
	game.request_resume()
	var stale := {"schema_version":1,"command_id":2,"input_event_id":2,"screen_id":8,"screen_generation":1,"layout_generation":1,"node_id":7001,"command_kind":1,"pause_reason":1,"source":1,"enabled":true}
	check(game.submit_battle_active_pause_command(stale) != 0 and game.state == ProductionGameRoot.State.BATTLE_ACTIVE, "old generation rejected")
	stale["screen_generation"] = 2
	stale["command_id"] = 1
	stale["input_event_id"] = 1
	check(game.submit_battle_active_pause_command(stale) != 0, "current duplicate rejected")
	await game.request_end_battle(false)
	game.queue_free()
	await process_frame
