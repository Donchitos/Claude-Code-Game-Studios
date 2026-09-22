extends SceneTree

# Explicit manual fixture: normal HP, Lv25, 24 cyclic upgrades, temporary profile.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	if await game.request_start_battle(101, false) != 0:
		quit(1)
		return
	var battle = game.current_battle
	battle.completed_active_ticks = 43199
	battle.elapsed_time = 43199.0 / 60.0
	battle.level = 25
	for choice in 24:
		battle.player.apply_upgrade(choice % 3, game._config["upgrades"])
	battle.battle_ui.update_hud(battle)
	game.request_pause(false)
	root.title = "Boss练习 · 普通血量 · 临时存档"
	print("BOSS_PRACTICE_READY hp=100 level=25 transient_profile=true")
