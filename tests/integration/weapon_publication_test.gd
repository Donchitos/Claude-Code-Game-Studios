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
	var battle = game.current_battle
	var stage = battle.stage
	stage._spawn_left = 999.0
	stage._attack_left = 0.0
	check(stage._spawn_enemy(stage.ENEMY_BEETLE, Vector2(500, 0)), "target")
	stage._spatial_grid.sync()
	check(battle.run_gameplay_phase(1.0 / 60.0), "publish tick")
	check(stage._weapon_pending_count == 1 and stage._projectile_count == 0, "not spawned on publication tick")
	var damage: float = stage._weapon_pending_damage[0]
	battle.player.sword_damage = 999.0
	check(game.request_pause(false) == 0, "pause")
	var frozen_tick: int = stage._simulation_tick
	await process_frame
	check(stage._simulation_tick == frozen_tick and stage._projectile_count == 0, "pause does not deliver")
	check(game.request_resume() == 0, "resume")
	check(battle.run_gameplay_phase(1.0 / 60.0), "delivery tick")
	check(stage._weapon_pending_count == 0 and stage._projectile_count == 1 and stage._projectile_damage[0] == damage, "next tick consumes frozen damage once")
	var snapshot: Dictionary = stage.hazard_snapshot(stage.get_instance_id(), stage._simulation_tick)
	check(not snapshot.is_empty(), "snapshot published")
	snapshot["bullets"].append({"position": Vector2.ZERO})
	check(stage.hazard_snapshot(stage.get_instance_id(), stage._simulation_tick)["bullets"].is_empty(), "consumer cannot mutate owner")
	check(stage.hazard_snapshot(stage.get_instance_id(), frozen_tick).is_empty(), "stale tick rejected")
	check(stage.hazard_snapshot(stage.get_instance_id() + 1, stage._simulation_tick).is_empty(), "foreign stage rejected")
	stage._hostile_count = 1
	stage._hostile_positions[0] = Vector2(300, 0)
	stage._hostile_velocities[0] = Vector2.RIGHT
	stage._hostile_life[0] = 1
	stage._publish_hazards()
	check(stage.hazard_snapshot(stage.get_instance_id(), stage._simulation_tick)["bullets"].size() == 1, "active bullet published")
	stage._update_hostile_projectiles(battle.player)
	stage._publish_hazards()
	check(stage.hazard_snapshot(stage.get_instance_id(), stage._simulation_tick)["bullets"].is_empty(), "expired bullet excluded")
	stage.boss_combat.fsm.phase_code = 2
	stage._publish_hazards()
	check(not stage.hazard_snapshot(stage.get_instance_id(), stage._simulation_tick)["fog"].is_empty(), "phase two fog published")
	stage.boss_defeated = true
	stage._publish_hazards()
	check(stage.hazard_snapshot(stage.get_instance_id(), stage._simulation_tick)["fog"].is_empty(), "defeated Boss contributes no fog")
	stage._projectile_count = stage._projectile_positions.size()
	stage._weapon_pending_count = 1
	stage._weapon_due_tick = stage._simulation_tick
	var dropped: int = stage.dropped_projectiles
	check(stage._deliver_weapon_pending() and stage._weapon_pending_count == 0 and stage.dropped_projectiles == dropped + 1, "full active capacity drops pending without retry")
	stage._weapon_pending_count = 1
	stage._weapon_due_tick = stage._simulation_tick - 1
	check(not stage._deliver_weapon_pending(), "late delivery fails closed")
	check(stage.teardown(), "teardown")
	check(stage._weapon_pending_count == 0 and stage.hazard_snapshot(stage.get_instance_id(), stage._simulation_tick).is_empty(), "teardown invalidates pending and snapshot")
	game.queue_free()
	await process_frame
	print("WEAPON_PUBLICATION_%s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
