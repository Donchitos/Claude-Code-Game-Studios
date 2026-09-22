extends SceneTree

# Bounded idle PC adapter diagnostic. No Stage, physical controller or allocation gate.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	if await game.request_start_battle(101, false) != 0:
		quit(1)
		return
	var battle = game.current_battle
	var times: Array[float] = []
	var initial_bytes := OS.get_static_memory_usage()
	var failed := false
	for batch in 620:
		var start := Time.get_ticks_usec()
		for sample in 128:
			var frame = battle.movement_context
			if not frame.begin(frame.tick + 1) or battle.input_system.run_phase(&"MOVEMENT_COMMIT", frame, frame.lease_id) != 0:
				failed = true
			if not battle.player.consume_movement(battle.movement_carrier, frame, frame.lease_id, 1.0 / 60.0) or not frame.finish():
				failed = true
		if batch >= 20:
			times.append(float(Time.get_ticks_usec() - start) / 128.0)
	times.sort()
	var report := {
		"scope": "idle PC poll + context lease + Player consume; batched amortized CPU only",
		"platform": OS.get_name(), "cpu": OS.get_processor_name(),
		"godot": Engine.get_version_info()["string"],
		"mapped_device_count": battle.input_system.source_reader.devices.size(),
		"warmup_batches": 20, "sample_batches": 600, "ticks_per_batch": 128,
		"amortized_p50_us": times[299], "amortized_p95_us": times[569], "amortized_p99_us": times[593],
		"engine_static_before_bytes": initial_bytes, "engine_static_after_bytes": OS.get_static_memory_usage(),
		"input_samples": battle.input_system.sample_count, "player_consumptions": battle.player.movement_consume_count,
		"physical_input_verified": false, "allocation_verified": false, "passed_execution": not failed,
	}
	var file := FileAccess.open("res://production/playtest-evidence/pc-input-workload-macos.json", FileAccess.WRITE)
	if file == null:
		failed = true
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	await game.request_end_battle(false)
	game.queue_free()
	await process_frame
	print("PC_INPUT_WORKLOAD_%s " % ("FAIL" if failed else "PASS"), JSON.stringify(report))
	quit(1 if failed else 0)
