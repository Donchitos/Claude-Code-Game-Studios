extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
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
	battle.player.apply_resolved_damage(16.8, "首领扇毒")
	battle.battle_ui.update_hud(battle)
	check(battle.battle_ui._damage_notice.visible and "首领扇毒" in battle.battle_ui._damage_notice.text, "HUD renders cause")
	check(game.request_pause(false) == 0, "pause")
	var remaining: float = battle.player.hit_feedback_left
	await process_frame
	await process_frame
	check(battle.player.hit_feedback_left == remaining, "pause freezes notice")
	check(game.request_resume() == 0, "resume")
	battle.player.apply_resolved_damage(1000.0, "首领扑咬")
	check(await game.request_end_battle(false) == 0, "settle")
	check(game.last_result_reason == "致命伤害：首领扑咬", "fatal cause survives teardown")
	check("首领扑咬" in game.current_page._summary.text, "settlement displays fatal cause")
	game.queue_free()
	await process_frame
	print("HIT_FEEDBACK_%s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
