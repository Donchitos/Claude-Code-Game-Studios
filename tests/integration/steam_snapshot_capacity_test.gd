extends SceneTree
const Snapshot = preload("res://src/persistence/steam_battle_snapshot.gd")
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const LIMITS = {"max_bytes": 8000000, "max_depth": 48}
const OUT = "res://production/playtest-evidence/steam-domains-2026-09-11/"
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
	check(scope.configure(config, 92345, false, ProductionMovementIntentCarrier.new(), context), "configure")
	return scope
func prepare(scope: ProductionBattleScope, kind: String) -> void:
	var s := scope.stage
	scope.completed_active_ticks = 44000
	scope.elapsed_time = 44000.0 / 60.0
	scope.level = 32
	scope.kills = 2170
	scope.first_upgrade_time = 10.0
	scope.player.sword_count = 32
	scope.player.movement_consume_count = 44000
	s._simulation_tick = 44000
	s._player_damage._committed = true
	for i in int(scope._config.capacities.enemies) - 1:
		check(s._spawn_enemy(0 if i % 2 == 0 else 1, Vector2(1500 + i * 2, 1200)), "fill enemies")
	check(s._spawn_enemy(2, Vector2(1800, 0)), "boss")
	s._enemy_hp[s._enemy_count - 1] = 100.0
	s._damage_receipt = 1
	s.boss_combat.fsm._last_damage_receipt_id = 1
	s.boss_combat.fsm.state = 4
	s.boss_combat.fsm.phase_code = 2
	s.boss_combat.fsm.phase_transition_generation = 1
	s.boss_combat.fsm.fog_generation = 1
	s.boss_combat.fsm.fog_anchor = Vector2.ZERO
	s.boss_combat.fsm.fog_elapsed_ticks = 59
	s.boss_combat.fsm.active_age_ticks = 800
	s.boss_combat.generation = 5
	s._projectile_count = s._projectile_positions.size()
	for i in s._projectile_count:
		s._projectile_positions[i] = Vector2(600, i % 50)
		s._projectile_velocities[i] = Vector2(680, 0)
		s._projectile_damage[i] = 1.0
	s._pickup_count = s._pickup_positions.size()
	for i in s._pickup_count:
		s._pickup_positions[i] = Vector2(-700, i % 50)
	s._weapon_pending_count = 32
	s._weapon_due_tick = 44001
	for i in 32:
		s._weapon_pending_positions[i] = Vector2.ZERO
		s._weapon_pending_velocities[i] = Vector2.RIGHT.rotated(float(i) * 0.01) * 680.0
		s._weapon_pending_damage[i] = 1.0
	s._hostile_count = 8
	for i in 8:
		s._hostile_positions[i] = Vector2(800, i * 10)
		s._hostile_velocities[i] = Vector2(0, 360)
		s._hostile_life[i] = 120
	match kind:
		"ring":
			s._hostile_count = 0
			s._ring_pending = true
			s._ring_origin = Vector2(1800, 0)
			s._ring_source = s._boss_handle
			s._ring_generation = 5
			s.boss_combat.slot = 2
			s.boss_combat.action = 3
		"summon":
			s._summon_pending = true
			s._summon_source = s._boss_handle
			s._summon_generation = 5
			s.boss_combat.slot = 3
			s.boss_combat.action = 3
		"bite":
			s.boss_combat.action = 2
			s.boss_combat.slot = 0
			s.boss_combat.ticks = 17
			s.boss_combat.bite_hit = true
		"phase_pending":
			s.boss_combat.action = 2
			s.boss_combat.slot = 0
			s.boss_combat.ticks = 17
			s.boss_combat.bite_hit = true
			s.boss_combat.fsm.state = 2
			s.boss_combat.fsm.phase_code = 1
			s.boss_combat.fsm.phase_transition_pending = true
			s.boss_combat.fsm.fog_elapsed_ticks = 0
			s.boss_combat.fsm.fog_generation = 0
	s._spatial_grid.sync()
	check(scope.activate() and scope.lock_for_pause(0), "paused checkpoint")
func _run() -> void:
	Input.set_use_accumulated_input(false)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/config/production_defaults.json"))
	var descriptor := FileAccess.open(OUT + "snapshot-shape.json", FileAccess.WRITE)
	descriptor.store_string(JSON.stringify(Snapshot.shape(config), "\t"))
	descriptor.close()
	var rows: Array = []
	for kind: String in ["full", "ring", "summon", "bite", "phase_pending"]:
		var a := fresh(config, 101)
		prepare(a, kind)
		var start := Time.get_ticks_usec()
		var captured := Snapshot.capture(a, LIMITS)
		var capture_us := Time.get_ticks_usec() - start
		check(captured.status == "OK", kind + " capture")
		if captured.status != "OK":
			print(captured)
			quit(1)
			return
		start = Time.get_ticks_usec()
		var encoded := Codec.encode(captured.value, LIMITS)
		var encode_us := Time.get_ticks_usec() - start
		start = Time.get_ticks_usec()
		var decoded := Codec.decode(encoded.text.to_utf8_buffer(), LIMITS)
		var decode_us := Time.get_ticks_usec() - start
		check(decoded.status == "OK", "canonical decode")
		var b := fresh(config, 102)
		start = Time.get_ticks_usec()
		check(Snapshot.restore(b, decoded.value, LIMITS).status == "OK", kind + " restore")
		var restore_us := Time.get_ticks_usec() - start
		check(Snapshot.capture(b, LIMITS).value == captured.value, kind + " exact roundtrip")
		var file := FileAccess.open(OUT + "snapshot-" + kind + ".json", FileAccess.WRITE)
		file.store_string(encoded.text)
		file.close()
		rows.append({"case": kind, "bytes": encoded.bytes, "capture_validate_us": capture_us, "encode_us": encode_us, "decode_reencode_us": decode_us, "restore_validate_us": restore_us})
		check(a.resume() and b.resume(), "resume")
		for i in 50:
			check(a.run_gameplay_phase(1.0 / 60.0) and b.run_gameplay_phase(1.0 / 60.0), "continue " + kind)
		check(a.lock_for_pause(a.movement_context.tick) and b.lock_for_pause(b.movement_context.tick), "pause")
		var left := Snapshot.capture(a, LIMITS)
		var right := Snapshot.capture(b, LIMITS)
		check(left.status == "OK" and right.status == "OK" and left.value == right.value, kind + " deterministic queues/boss/RNG/SoA")
		check(a.teardown() and b.teardown(), "clean")
		a.queue_free()
		b.queue_free()
		await process_frame
	var report := {"profile": Snapshot.PROFILE, "engine": Engine.get_version_info().string, "platform": OS.get_name(), "config_hash": Snapshot.config_hash(config), "cases": rows, "checks": checks, "failures": failures, "natural_reachability_proven": false, "commercial_budget_frozen": false, "limits_are_test_ceiling": true, "memory_static_peak_process_bytes": OS.get_static_memory_peak_usage()}
	var file := FileAccess.open(OUT + "snapshot-measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("STEAM_SNAPSHOT_CAPACITY_TEST checks=%d failures=%d" % [checks, failures])
	print(JSON.stringify(report))
	quit(0 if failures == 0 else 1)
