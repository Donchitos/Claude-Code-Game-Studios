extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	check(await game.request_start_battle(123, false) == 0, "start long run")
	var battle = game.current_battle
	# Advance the actual production simulation through the reward milestone.
	battle.player.hp = 1000000.0
	for tick in 5400:
		check(battle.run_tick(1.0 / 60.0, tick + 1), "fixed tick")
		if battle.pending_upgrade:
			game.request_pause(true)
			battle.apply_upgrade(0)
			game.request_resume()
	check(battle.completed_active_ticks == 5400, "90 second tick boundary")
	await game.request_end_battle(false)
	check(game.last_result_pages_granted == 1, "natural 90 second reward")
	var profile: Dictionary = game.save_system.profile_snapshot()
	check(int(profile["domains"]["progression"]["unspent_pages"]) == 1, "reward saved")
	await game.request_start_battle(456, false)
	battle = game.current_battle
	battle.player.hp = 1000000.0
	# Boundary fixture skips only earlier content; spawn/action code remains real.
	battle.completed_active_ticks = 43198
	battle.elapsed_time = 43198.0 / 60.0
	battle.run_tick(1.0 / 60.0, 1)
	check(battle.stage.boss_spawn_count == 0, "no early Boss")
	battle.run_tick(1.0 / 60.0, 2)
	check(battle.stage.boss_spawn_count == 1, "Boss exactly at tick 43200")
	game.request_pause(false)
	var frozen: int = battle.stage.boss_combat.fsm.active_age_ticks
	await process_frame
	check(battle.stage.boss_combat.fsm.active_age_ticks == frozen, "pause freezes Boss")
	game.request_resume()
	for tick in 500:
		battle.run_tick(1.0 / 60.0, tick + 3)
	check(battle.stage.boss_spawn_count == 1, "no duplicate Boss")
	check(battle.stage.boss_combat.generation > 0, "Boss starts actions after arrival")
	var stage = battle.stage
	stage._ring_pending = true
	stage._ring_source = stage._boss_handle + 999
	stage._ring_generation = stage.boss_combat.generation
	check(not stage._update_boss_schedule(battle.elapsed_time, battle.player.position), "stale projectile batch must be rejected")
	stage._ring_pending = false
	var before_summons: int = stage.enemy_count()
	stage._summon_pending = true
	stage._summon_source = stage._boss_handle
	stage._summon_generation = stage.boss_combat.generation
	check(stage._update_boss_schedule(battle.elapsed_time, battle.player.position), "summon delivery")
	check(stage.enemy_count() - before_summons in [0, 2], "summon cluster is zero or two")
	check(stage._summon_candidates.words_used == 48, "runtime summon consumes 48 words")
	check(stage.enemy_count() == stage.enemy_pool_borrowed_count(), "summon pool conservation")
	battle.player.sword_damage = 10000.0
	for tick in 1200:
		if battle.terminal_pending:
			break
		battle.run_tick(1.0 / 60.0, tick + 503)
	check(battle.stage.boss_defeated and battle.victory, "real projectile defeats Boss")
	await game.request_end_battle(battle.victory)
	check(game.last_result_pages_granted == 8, "Boss run grants capped pages")
	check(game.current_battle == null, "Boss scope cleaned up")
	await game.request_start_battle(789, false)
	battle = game.current_battle
	battle.completed_active_ticks = 53999
	battle.player.hp = 1000000.0
	battle.run_tick(1.0 / 60.0, 1)
	check(battle.terminal_pending and not battle.victory, "timeout cannot substitute for Boss kill")
	await game.request_end_battle(false)
	game.queue_free()
	await process_frame
	print("LONG_RUN_%s reward_boundary=true boss_boundary=true pause=true projectile_kill=true settlement=true" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
