extends SceneTree
const Snapshot = preload("res://src/persistence/steam_battle_snapshot.gd")
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const LIMITS = {"max_bytes": 8000000, "max_depth": 48} # test ceiling, not product budget
var checks := 0
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func fresh(config: Dictionary, generation: int) -> ProductionBattleScope:
	var scope = load("res://src/gameplay/battle/BattleScope.tscn").instantiate()
	root.add_child(scope)
	var context := PcMovementContext.new()
	context.battle_generation = generation
	check(scope.configure(config, 82345, false, ProductionMovementIntentCarrier.new(), context), "configure")
	return scope
func _run() -> void:
	Input.set_use_accumulated_input(false)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/config/production_defaults.json"))
	var a := fresh(config, 1)
	check(a.activate(), "activate")
	check(Snapshot.capture(a, LIMITS).status != "OK", "active capture rejected")
	for i in 120:
		check(a.run_gameplay_phase(1.0 / 60.0), "initial tick")
	# Swap removal makes SoA order differ from identity order.
	for pos: Vector2 in [Vector2(200, 0), Vector2(-200, 0), Vector2(200, 200)]:
		check(a.stage._spawn_enemy(0, pos), "spawn")
	check(a.stage._remove_enemy(1), "middle removal")
	a.stage._spatial_grid.sync()
	a.stage._rng.state = -3456789123456
	a.stage._weapon_pending_count = 1
	a.stage._weapon_pending_positions[0] = Vector2.ZERO
	a.stage._weapon_pending_velocities[0] = Vector2(680, 0)
	a.stage._weapon_pending_damage[0] = 1.0
	a.stage._weapon_due_tick = a.completed_active_ticks + 1
	check(a.lock_for_pause(a.movement_context.tick), "pause")
	var result := Snapshot.capture(a, LIMITS)
	check(result.status == "OK", "capture")
	if result.status != "OK":
		print(result)
		quit(1)
		return
	var b := fresh(config, 2)
	check(Snapshot.restore(b, result.value, LIMITS).status == "OK", "restore hidden")
	check(Snapshot.capture(b, LIMITS).value == result.value, "roundtrip exact logical state")
	for key in result.value.keys():
		var bad: Dictionary = result.value.duplicate(true)
		bad.erase(key)
		check(Snapshot.validate(bad, config, LIMITS).status != "OK", "missing owner " + key)
	var bad: Dictionary = result.value.duplicate(true)
	bad.stage._simulation_tick = "0"
	check(Snapshot.validate(bad, config, LIMITS).status != "OK", "mixed tick")
	bad = result.value.duplicate(true)
	bad.enemies[1].entity_id = bad.enemies[0].entity_id
	check(Snapshot.validate(bad, config, LIMITS).status != "OK", "duplicate ID")
	bad = result.value.duplicate(true)
	bad.player.hp = "7ff0000000000000"
	check(Snapshot.validate(bad, config, LIMITS).status != "OK", "nonfinite")
	for mutation: String in ["zero_id", "outside", "free_choice", "forged_swords", "fsm", "receipt", "huge_velocity", "missing_late_boss", "spawn_timer", "attack_timer"]:
		bad = result.value.duplicate(true)
		match mutation:
			"zero_id": bad.stage._snapshot_next_entity_id = "0"
			"outside": bad.player.position = [Codec.float_to_hex(2000000.0).value, Codec.float_to_hex(0.0).value]
			"free_choice": bad.scope.pending_upgrade = true
			"forged_swords": bad.player.sword_count = "1000000"
			"fsm": bad.fsm.state = "4"; bad.fsm.phase_code = "2"
			"huge_velocity": bad.weapon.rows[0].velocity = [Codec.float_to_hex(Vector2(3e38, 0).x).value, Codec.float_to_hex(0.0).value]
			"missing_late_boss": bad.scope.completed_active_ticks = "44000"; bad.stage._simulation_tick = "44000"; bad.weapon.due_tick = "44001"
			"spawn_timer": bad.stage._spawn_left = Codec.float_to_hex(1e100).value
			"attack_timer": bad.stage._attack_left = Codec.float_to_hex(1e100).value
			"receipt": bad.stage._damage_receipt = Codec.U63_MAX; bad.fsm._last_damage_receipt_id = Codec.U63_MAX
		check(Snapshot.validate(bad, config, LIMITS).status != "OK", "causal rejection " + mutation)
	check(a.resume() and b.resume(), "fresh neutral resume")
	for i in 600:
		check(a.run_gameplay_phase(1.0 / 60.0) and b.run_gameplay_phase(1.0 / 60.0), "continuation")
		if a.pending_upgrade or b.pending_upgrade:
			check(a.lock_for_pause(a.movement_context.tick) and b.lock_for_pause(b.movement_context.tick), "choice pause")
			check(a.apply_upgrade(i % 3) and b.apply_upgrade(i % 3), "same choice")
			check(a.resume() and b.resume(), "choice resume")
	check(a.lock_for_pause(a.movement_context.tick) and b.lock_for_pause(b.movement_context.tick), "final pause")
	check(Snapshot.capture(a, LIMITS).value == Snapshot.capture(b, LIMITS).value, "600 tick deterministic continuation")
	check(a.teardown() and b.teardown(), "no pool/grid leaks")
	a.queue_free()
	b.queue_free()
	await process_frame
	print("STEAM_SNAPSHOT_TEST checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
