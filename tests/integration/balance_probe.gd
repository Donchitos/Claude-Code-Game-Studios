extends SceneTree

# Diagnostic simulation, not a player playtest or a pass/fail balance oracle.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	for seed_value in [101, 202, 303]:
		await game.request_start_battle(seed_value, false)
		var battle = game.current_battle
		var min_hp := 100.0
		while not battle.terminal_pending:
			battle.input_system.carrier.direction = battle.stage.smoke_move_direction(battle.elapsed_time, battle.player.position)
			if "--dodge" in OS.get_cmdline_user_args() and battle.stage.boss_spawn_count > 0:
				battle.input_system.carrier.direction = _dodge_direction(battle)
			if not battle.run_gameplay_phase(1.0 / 60.0):
				push_error("BALANCE_PROBE simulation fault")
				quit(1)
				return
			min_hp = minf(min_hp, battle.player.hp)
			if battle.pending_upgrade:
				game.request_pause(true)
				battle.apply_upgrade((battle.level - 2) % 3)
				game.request_resume()
		print("BALANCE_PROBE ", JSON.stringify({"policy": "dodge" if "--dodge" in OS.get_cmdline_user_args() else "stand_at_boss", "seed": seed_value, "seconds": battle.elapsed_time, "level": battle.level, "kills": battle.kills, "victory": battle.victory, "hp": battle.player.hp, "min_hp": min_hp, "first_upgrade_seconds": battle.first_upgrade_time, "speed": battle.player.move_speed, "boss_hp": battle.stage.boss_hp()}))
		await game.request_end_battle(battle.victory)
	game.queue_free()
	await process_frame
	quit()

func _dodge_direction(battle) -> Vector2:
	var stage = battle.stage
	var boss = stage.boss_combat
	var index: int = stage._enemy_index_for_grid_handle(stage._boss_handle)
	if index < 0:
		return Vector2.ZERO
	var toward: Vector2 = stage._enemy_positions[index] - battle.player.position
	if boss.fsm.phase_code == 2:
		var center: Vector2 = boss.fsm.fog_anchor - battle.player.position
		if center.length() > boss.fsm.fog_safe_radius() * 60.0 - 80.0:
			return center.normalized()
	if boss.action == boss.Action.TELEGRAPH or boss.action == boss.Action.BITE:
		if boss.slot == 0:
			return boss.axis.orthogonal()
		if boss.slot == 1:
			return -toward.normalized()
	if stage._hostile_count > 0:
		return toward.orthogonal().normalized()
	return toward.normalized() if toward.length() > 280.0 else Vector2.ZERO
