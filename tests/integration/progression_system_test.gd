extends SceneTree

const ProgressionSystem = preload("res://src/progression/progression_system.gd")
const SaveSystem = preload("res://src/persistence/save_system.gd")
const PlayerController = preload("res://src/gameplay/player/player_controller.gd")

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var progression := ProgressionSystem.new()
	root.add_child(progression)
	_expect(progression.initialize() == ProgressionSystem.Status.OK, "empty domain must initialize")
	var insufficient: Dictionary = progression.build_purchase_after_image(ProgressionSystem.QINGYUAN)
	_expect(int(insufficient["status"]) == ProgressionSystem.Status.INSUFFICIENT_PAGES, "purchase without pages must fail")

	var income: Dictionary = progression.build_income_after_image(37620, false)
	_expect(int(income["status"]) == ProgressionSystem.Status.OK and int(income["granted_pages"]) == 6, "10:27 must grant six pages")
	_expect(progression.publish_after_image(income["domain"]) == ProgressionSystem.Status.OK, "durable income after-image must publish")
	var purchase: Dictionary = progression.build_purchase_after_image(ProgressionSystem.QINGYUAN)
	_expect(int(purchase["status"]) == ProgressionSystem.Status.OK and int(purchase["cost_pages"]) == 4, "Qingyuan L1 must cost four pages")
	var purchase_domain: Dictionary = purchase["domain"]
	_expect(int(purchase_domain["unspent_pages"]) == 2 and int(purchase_domain["spent_pages_total"]) == 4, "purchase must conserve the wallet")

	var save := SaveSystem.new()
	root.add_child(save)
	var defaults := {ProgressionSystem.DOMAIN_KEY: ProgressionSystem.empty_domain()}
	_expect(save.initialize("", "", defaults) == SaveSystem.Status.OK, "save must inject a default progression domain")
	_expect(save.commit_domain_after_images({ProgressionSystem.DOMAIN_KEY: purchase_domain}) == SaveSystem.Status.OK, "generic domain mutation must commit")
	var persisted: Dictionary = save.profile_snapshot()["domains"][ProgressionSystem.DOMAIN_KEY]
	_expect(ProgressionSystem.is_valid_domain(persisted), "persisted progression after-image must remain valid")
	_expect(progression.publish_after_image(persisted) == ProgressionSystem.Status.OK, "published purchase must match durable profile")
	var projection: Dictionary = progression.battle_projection()
	_expect(int(projection["qingyuan_level"]) == 1 and is_equal_approx(float(projection["attack_bonus_ratio"]), 0.03), "next-run projection must reflect the durable purchase")

	var full_domain := ProgressionSystem.empty_domain()
	full_domain["domain_revision"] = 15
	full_domain["unspent_pages"] = 0
	full_domain["earned_pages_total"] = 180
	full_domain["spent_pages_total"] = 180
	full_domain["upgrade_sequence"] = 15
	full_domain["next_purchase_id"] = 16
	full_domain["branch_levels"] = [5, 5, 5]
	var full_progression := ProgressionSystem.new()
	root.add_child(full_progression)
	_expect(full_progression.initialize(full_domain) == ProgressionSystem.Status.OK, "full tree domain must satisfy invariants")
	var full_projection: Dictionary = full_progression.battle_projection()
	_expect(int(full_projection["qingyuan_extra_pierce"]) == 1, "Qingyuan L5 must project one extra pierce")
	_expect(int(full_projection["longchun_charge_count"]) == 1, "Longchun L5 must project one recovery charge")
	_expect(int(full_projection["extra_free_refreshes"]) == 1, "Dayan L5 must project one free refresh")

	var mixed_domain := ProgressionSystem.empty_domain()
	mixed_domain["domain_revision"] = 12
	mixed_domain["earned_pages_total"] = 124
	mixed_domain["spent_pages_total"] = 124
	mixed_domain["upgrade_sequence"] = 12
	mixed_domain["next_purchase_id"] = 13
	mixed_domain["branch_levels"] = [3, 5, 4]
	var mixed_progression := ProgressionSystem.new()
	root.add_child(mixed_progression)
	_expect(mixed_progression.initialize(mixed_domain) == ProgressionSystem.Status.OK, "mixed tree domain must satisfy invariants")
	var player := PlayerController.new()
	root.add_child(player)
	var player_config := {
		"max_hp": 100.0,
		"speed": 360.0,
		"radius": 24.0,
		"pickup_radius": 62.0,
		"contact_cooldown": 0.55,
		"attack_interval": 0.42,
		"minimum_attack_interval": 0.16,
		"sword_count": 1,
		"sword_damage": 1.0,
	}
	player.configure(player_config, mixed_progression.battle_projection())
	_expect(is_equal_approx(player.sword_damage, 1.09), "Qingyuan projection must modify attack once")
	_expect(is_equal_approx(player.max_hp, 115.0), "Longchun projection must modify maximum HP once")
	_expect(is_equal_approx(player.pickup_radius, 66.96), "Dayan projection must modify pickup radius once")
	player.hp = 40.0
	_expect(player.apply_contact_damage(10.0), "nonlethal threshold-crossing damage must apply")
	_expect(player.longchun_trigger_count == 1 and player.longchun_charge_count == 0 and is_equal_approx(player.hp, 41.5), "Longchun L5 must recover ten percent exactly once")

	progression.queue_free()
	save.queue_free()
	full_progression.queue_free()
	mixed_progression.queue_free()
	player.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("PROGRESSION_ASSERTION_FAILED %s" % message)

func _finish() -> void:
	if _failures == 0:
		print("PROGRESSION_SYSTEM_PASS income=true purchase=true conservation=true persistence=true projection=true")
		quit(0)
	else:
		print("PROGRESSION_SYSTEM_FAIL failures=%d" % _failures)
		quit(1)
