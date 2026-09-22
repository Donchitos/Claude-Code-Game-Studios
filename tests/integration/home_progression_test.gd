extends SceneTree

const ProgressionSystem = preload("res://src/progression/progression_system.gd")
const SaveSystem = preload("res://src/persistence/save_system.gd")

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://src/core/GameRoot.tscn") as PackedScene
	var game_root := scene.instantiate() as ProductionGameRoot
	root.add_child(game_root)
	await game_root.boot_completed
	var income: Dictionary = game_root.progression_system.call("build_income_after_image", 21600, false)
	_expect(int(income["granted_pages"]) == 4, "four milestones must provide the first-node cost")
	var funded_domain: Dictionary = income["domain"]
	_expect(game_root.save_system.call("commit_domain_after_images", {ProgressionSystem.DOMAIN_KEY: funded_domain}) == SaveSystem.Status.OK, "funded domain must persist")
	_expect(game_root.progression_system.call("publish_after_image", funded_domain) == ProgressionSystem.Status.OK, "funded domain must publish")
	var home := game_root.current_page as ProductionHomeScreen
	home.present_progression(funded_domain)
	var branch_button := home.get_node("ProgressionBranch1Button") as Button
	_expect(not branch_button.disabled, "affordable branch must be enabled")
	branch_button.pressed.emit()
	var before_confirm: Dictionary = game_root.progression_system.call("domain_snapshot")
	_expect(int(before_confirm["branch_levels"][0]) == 0, "first press must only enter confirmation")
	branch_button.pressed.emit()
	var purchased: Dictionary = game_root.progression_system.call("domain_snapshot")
	_expect(int(purchased["branch_levels"][0]) == 1 and int(purchased["unspent_pages"]) == 0, "second press must persist Qingyuan L1")
	var saved_profile: Dictionary = game_root.save_system.call("profile_snapshot")
	_expect(int(saved_profile["generation"]) == 2 and int(saved_profile["total_runs"]) == 0, "income setup and purchase must be durable domain mutations without adding runs")
	_expect(await game_root.request_start_battle(20260910, false) == ProductionGameRoot.Status.OK, "battle must start after purchase")
	_expect(is_equal_approx(game_root.current_battle.player.sword_damage, 1.03), "durable Qingyuan purchase must affect the next battle")
	game_root.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("HOME_PROGRESSION_ASSERTION_FAILED %s" % message)

func _finish() -> void:
	if _failures == 0:
		print("HOME_PROGRESSION_PASS confirm=true durable=true next_run=true")
		quit(0)
	else:
		print("HOME_PROGRESSION_FAIL failures=%d" % _failures)
		quit(1)
