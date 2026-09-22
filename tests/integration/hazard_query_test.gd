extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	check(await game.request_start_battle(101, false) == 0, "start")
	var stage = game.current_battle.stage
	var player = game.current_battle.player
	stage._spawn_enemy(stage.ENEMY_BEETLE, Vector2(1000, 0))
	stage._spawn_enemy(stage.ENEMY_BOSS, Vector2.ZERO)
	stage.boss_combat.action = stage.BossCombat.Action.TELEGRAPH
	stage.boss_combat.slot = 1
	stage.boss_combat.axis = Vector2.RIGHT
	stage._publish_hazards()
	var id: int = stage.get_instance_id()
	var result: Dictionary = stage.query_danger(id, 0, Vector2(200, 0), 24)
	check(result["warnings"].has("扇毒") and result["exposures"].is_empty(), "fan warning is not active exposure")
	check(stage.query_danger(id, 0, Vector2(-200, 0), 24)["warnings"].is_empty(), "behind fan safe geometrically")
	check(stage.query_danger(id, 0, Vector2(1000, 0), 24)["exposures"].has("敌人接触"), "contact included")
	stage.boss_combat.slot = 0
	stage._publish_hazards()
	check(stage.query_danger(id, 0, Vector2(300, 0), 24)["warnings"].has("扑咬"), "bite corridor warning")
	# Capture active geometry through the real Boss update path.
	stage.boss_combat.fsm.active_age_ticks = 200
	stage.boss_combat.fsm.state = stage.BossCombat.FSM.State.TRACK_P1
	stage.boss_combat.action = stage.BossCombat.Action.BITE
	stage.boss_combat.ticks = 0
	player.position = Vector2(1000, 1000)
	stage._update_boss(1, player)
	stage._publish_hazards()
	check(stage.query_danger(id, 0, Vector2(9, 0), 0)["exposures"].has("扑咬"), "active bite swept segment")
	stage._boss_tick_hazards.clear()
	stage.boss_combat.action = stage.BossCombat.Action.TELEGRAPH
	stage.boss_combat.slot = 1
	stage.boss_combat.ticks = 47
	stage._update_boss(1, player)
	stage._publish_hazards()
	check(stage.query_danger(id, 0, Vector2(200, 0), 24)["exposures"].has("扇毒"), "fan release captured")
	check(not stage.query_danger(id, 1, Vector2.ZERO, 24)["valid"], "wrong tick invalid, not safe")
	check(not stage.query_danger(id, 0, Vector2.ZERO, -1)["valid"], "invalid radius rejected")
	stage._spawn_left = 999.0
	stage._attack_left = 999.0
	check(stage.run_phase(&"STAGE_SIMULATE", 1.0 / 60.0, 1.0 / 60.0, player), "advance clears release")
	check(stage.query_danger(id, 1, Vector2(200, 0), 24)["exposures"].is_empty(), "fan release does not persist into recovery")
	stage.teardown()
	check(not stage.query_danger(id, 0, Vector2.ZERO, 24)["valid"], "closed query invalid")
	game.queue_free()
	await process_frame
	print("HAZARD_QUERY_%s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
