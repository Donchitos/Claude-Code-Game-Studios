extends SceneTree

# Diagnostic fixture, not a production workload or target-device performance gate.
const WARMUP := 120
const SAMPLES := 600
var failed := false
func _initialize() -> void:
	_run.call_deferred()
func percentile(values: Array[float], fraction: float) -> float:
	var ordered := values.duplicate()
	ordered.sort()
	return ordered[clampi(ceili(ordered.size() * fraction) - 1, 0, ordered.size() - 1)]
func _run() -> void:
	var graphical := DisplayServer.get_name() != "headless"
	var split := "--split" in OS.get_cmdline_user_args()
	var dense := "--dense" in OS.get_cmdline_user_args()
	var disable_vsync := "--no-vsync" in OS.get_cmdline_user_args()
	if graphical and disable_vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(1280, 720)
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	var results: Array[Dictionary] = []
	var modes := ["capacity_stress_dense"] if dense else (["capacity_stress", "capacity_stress_no_stage", "capacity_stress_no_canvas"] if split else ["ordinary", "capacity_stress", "boss_phase2"])
	for mode: String in modes:
		if await game.request_start_battle(101, false) != 0:
			failed = true
			break
		var battle = game.current_battle
		var stage = battle.stage
		stage.measure_draw_cpu = split
		if mode in ["capacity_stress_no_stage", "capacity_stress_no_canvas"]:
			stage.visible = false
		if mode == "capacity_stress_no_canvas":
			battle.player.visible = false
			battle.battle_ui.visible = false
			battle.joystick_host.visible = false
		battle.player.hp = 1.0e9
		if mode.begins_with("capacity_stress"):
			stage._spawn_left = 9999.0
			for index in 319:
				if not stage._spawn_enemy(stage.ENEMY_BEETLE, Vector2.RIGHT.rotated(index * TAU / 319.0) * 350.0):
					failed = true
				stage._enemy_hp[index] = 1.0e8
			stage._spatial_grid.sync()
		if mode == "boss_phase2":
			battle.completed_active_ticks = 43199
			battle.run_gameplay_phase(1.0 / 60.0)
			var boss_index: int = stage._enemy_index_for_grid_handle(stage._boss_handle)
			stage._enemy_hp[boss_index] = 128.0
			stage.boss_combat.fsm.apply_hp_receipt(1, 320.0, 128.0)
			battle.player.sword_damage = 0.0
		var durations: Array[float] = []
		var frames: Array[float] = []
		var fills: Array[float] = []
		var bookkeeping: Array[float] = []
		var waits: Array[float] = []
		var draw_cpu: Array[float] = []
		var totals: Array[float] = []
		var memory_samples: Array[int] = []
		var peak_enemies := 0
		var peak_friendly := 0
		var peak_hostile := 0
		var over_budget := 0
		var previous_frame := Time.get_ticks_usec()
		for tick in WARMUP + SAMPLES:
			var loop_started := Time.get_ticks_usec()
			# Fill fixtures outside the measured production simulation call.
			if mode.begins_with("capacity_stress"):
				stage._projectile_count = stage._projectile_positions.size()
				for index in stage._projectile_count:
					if mode == "capacity_stress_dense":
						stage._projectile_positions[index] = battle.player.position + Vector2(-580 + (index % 28) * 43, -280 + (index / 28) * 40)
						stage._projectile_velocities[index] = Vector2.RIGHT.rotated((index % 16) * TAU / 16.0)
					else:
						stage._projectile_positions[index] = Vector2(0, -700)
						stage._projectile_velocities[index] = Vector2.RIGHT
					stage._projectile_damage[index] = 0.0
			var start := Time.get_ticks_usec()
			var ok: bool = battle.run_gameplay_phase(1.0 / 60.0)
			var elapsed_ms := (Time.get_ticks_usec() - start) / 1000.0
			var simulation_ended := Time.get_ticks_usec()
			if not ok:
				failed = true
				break
			if battle.pending_upgrade:
				game.request_pause(true)
				battle.apply_upgrade((battle.level - 2) % 3)
				game.request_resume()
			if tick >= WARMUP:
				durations.append(elapsed_ms)
				if elapsed_ms > 1000.0 / 60.0:
					over_budget += 1
				peak_enemies = maxi(peak_enemies, stage._enemy_count)
				peak_friendly = maxi(peak_friendly, stage._projectile_count)
				peak_hostile = maxi(peak_hostile, stage._hostile_count)
				if tick % 60 == 0:
					memory_samples.append(OS.get_static_memory_usage())
			if graphical:
				var before_wait := Time.get_ticks_usec()
				var draw_count_before: int = stage.draw_measurement_count
				await process_frame
				var now := Time.get_ticks_usec()
				if split and tick >= WARMUP:
					fills.append((start - loop_started) / 1000.0)
					bookkeeping.append((before_wait - simulation_ended) / 1000.0)
					waits.append((now - before_wait) / 1000.0)
					totals.append((now - loop_started) / 1000.0)
					if stage.draw_measurement_count > draw_count_before:
						draw_cpu.append(stage.last_draw_cpu_usec / 1000.0)
				if tick > WARMUP:
					frames.append((now - previous_frame) / 1000.0)
				previous_frame = now
		if durations.is_empty():
			failed = true
			break
		var row := {"mode": mode, "samples": durations.size(), "simulation_p50_ms": percentile(durations, 0.5), "simulation_p95_ms": percentile(durations, 0.95), "simulation_p99_ms": percentile(durations, 0.99), "simulation_max_ms": durations.max(), "simulation_over_16_67ms": over_budget, "peak_enemies": peak_enemies, "peak_friendly": peak_friendly, "peak_hostile": peak_hostile, "engine_static_bytes_samples": memory_samples}
		if not frames.is_empty():
			row["frame_interval_p95_ms"] = percentile(frames, 0.95)
			row["frame_interval_p99_ms"] = percentile(frames, 0.99)
		if not totals.is_empty():
			row["split"] = {}
			var groups := {"fixture_fill": fills, "simulation": durations, "bookkeeping": bookkeeping, "wait_next_frame": waits, "loop_total": totals, "stage_draw_cpu": draw_cpu}
			for key: String in groups:
				var values: Array[float] = groups[key]
				if not values.is_empty():
					var total := 0.0
					for value in values:
						total += value
					row["split"][key] = {"count": values.size(), "mean_ms": total / values.size(), "p95_ms": percentile(values, 0.95)}
		results.append(row)
		row["input_samples"] = battle.input_system.sample_count
		row["player_consumptions"] = battle.player.movement_consume_count
		await game.request_end_battle(false)
		await process_frame
		row["engine_static_after_teardown_bytes"] = OS.get_static_memory_usage()
		print("PERFORMANCE_CASE ", JSON.stringify(row))
	var report := {"platform": OS.get_name(), "cpu": OS.get_processor_name(), "godot": Engine.get_version_info()["string"], "renderer": DisplayServer.get_name(), "warmup_ticks": WARMUP, "temporary_profile": true, "passed_execution": not failed, "cases": results}
	var path := "res://production/playtest-evidence/performance-%s.json" % ("graphical" if graphical else "headless")
	if split:
		path = path.trim_suffix(".json") + ("-split-no-vsync.json" if disable_vsync else "-split.json")
		report["vsync_mode"] = DisplayServer.window_get_vsync_mode() if graphical else -1
		report["engine_max_fps"] = Engine.max_fps
	if "--optimized" in OS.get_cmdline_user_args():
		path = path.trim_suffix(".json") + "-optimized.json"
	if "--culled" in OS.get_cmdline_user_args():
		path = path.trim_suffix(".json") + "-culled.json"
	if dense:
		path = path.trim_suffix(".json") + "-dense.json"
	if "--pc-input" in OS.get_cmdline_user_args():
		path = path.trim_suffix(".json") + "-pc-input.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failed = true
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	game.queue_free()
	await process_frame
	print("PERFORMANCE_PROBE_%s" % ("PASS" if not failed else "FAIL"))
	quit(1 if failed else 0)
