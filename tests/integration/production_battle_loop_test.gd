extends SceneTree

var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://src/core/GameRoot.tscn") as PackedScene
	_expect(scene != null, "GameRoot scene must load")
	if scene == null:
		_finish()
		return
	var game_root := scene.instantiate() as ProductionGameRoot
	root.add_child(game_root)
	await game_root.boot_completed

	var test_config: Dictionary = game_root._config.duplicate(true)
	test_config["run"]["duration_seconds"] = 6.0
	test_config["run"]["boss_enabled"] = false
	test_config["run"]["smoke_speed_multiplier"] = 1.0
	test_config["player"]["attack_interval"] = 0.08
	test_config["player"]["pickup_radius"] = 1000.0
	test_config["player"]["sword_damage"] = 100
	test_config["combat"]["projectile_speed"] = 5000.0
	for wave: Dictionary in test_config["waves"]:
		wave["spawn_interval"] = 0.08
		wave["wolf_probability"] = 0.0
	for enemy_key: String in ["beetle", "wolf"]:
		test_config["enemies"][enemy_key]["speed"] = 0.0
		test_config["enemies"][enemy_key]["contact_damage"] = 0.0
	game_root._config = test_config

	_expect(await game_root.request_start_battle(20260910, false) == ProductionGameRoot.Status.OK, "normal battle must start")
	var saw_upgrade := false
	var saw_resume := false
	var saw_integrated_enemy := false
	var ownership_conserved := true
	var deadline := Time.get_ticks_msec() + 20000
	while game_root.state != ProductionGameRoot.State.SETTLEMENT and Time.get_ticks_msec() < deadline:
		await process_frame
		if game_root.current_battle != null:
			var stage := game_root.current_battle.stage
			if stage.enemy_count() > 0:
				saw_integrated_enemy = true
			ownership_conserved = ownership_conserved \
					and stage.enemy_count() == stage.spatial_active_count() \
					and stage.enemy_count() == stage.enemy_pool_borrowed_count()
		if game_root.state == ProductionGameRoot.State.BATTLE_PAUSED and game_root.current_battle != null and game_root.current_battle.pending_upgrade:
			saw_upgrade = true
			game_root.current_battle.upgrade_selected.emit(0)
			await process_frame
			saw_resume = game_root.state == ProductionGameRoot.State.BATTLE_ACTIVE

	_expect(saw_upgrade, "normal battle must reach an interactive upgrade pause")
	_expect(saw_resume, "upgrade selection must resume the battle")
	_expect(saw_integrated_enemy, "normal battle must publish at least one pooled Grid enemy")
	_expect(ownership_conserved, "enemy, Grid and Pool active counts must remain equal")
	_expect(game_root.state == ProductionGameRoot.State.SETTLEMENT, "normal battle must end in settlement")
	_expect(game_root.last_result_victory, "normal battle must report victory")
	_expect(game_root.last_result_level >= 2, "upgrade must be reflected in settlement level")
	game_root.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("PRODUCTION_BATTLE_LOOP_ASSERTION_FAILED %s" % message)

func _finish() -> void:
	if _failures == 0:
		print("PRODUCTION_BATTLE_LOOP_PASS normal_start=true upgrade_pause=true upgrade_resume=true settlement=true")
		quit(0)
	else:
		print("PRODUCTION_BATTLE_LOOP_FAIL failures=%d" % _failures)
		quit(1)
