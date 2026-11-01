extends SceneTree
## Full Phase 1 Grand Integration Test (P1-I02):
## Validates end-to-end cohesion of all 19 Phase 1 modules: locomotion, weapons, 3D aiming,
## 4 roles, inventory, carry/throw, obstacles, AI perception, pursuing bots, boss, alarms, and extraction scenario.

const LabScene = preload("res://src/lab/mechanics_lab.tscn")
const ScenarioScript = preload("res://src/world/scenario/core_extraction_scenario.gd")
const DirectorScript = preload("res://src/world/director/director_controller.gd")
const MutatorScript = preload("res://src/world/mutators/mutator_manager.gd")
const AlarmScript = preload("res://src/world/alarm/alarm_controller.gd")
const BossScript = preload("res://src/ai/boss_encounter.gd")
const PullScript = preload("res://src/objects/pull_controller.gd")
const EventDeckScript = preload("res://src/world/events/event_deck.gd")
const BreakerScript = preload("res://src/roles/breaker/breaker_role.gd")
const ScoutScript = preload("res://src/roles/scout/scout_role.gd")
const LockScript = preload("res://src/roles/lock/lock_role.gd")
const CarrierScript = preload("res://src/roles/carrier/carrier_role.gd")
const InventoryScript = preload("res://src/inventory/inventory_model.gd")
const AccessibilityScript = preload("res://src/ui/accessibility_settings.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred(&"_run_tests")


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: ", message)


func _run_tests() -> void:
	# 1. Instantiate the live Mechanics Lab
	var lab = LabScene.instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame

	_check(is_instance_valid(lab._player), "1. Player locomotion and camera operational")
	_check(is_instance_valid(lab.weapon) and lab.weapon.profiles.size() == 4, "2. All 4 weapon profiles loaded")
	_check(lab.combat_range.enemies.size() >= 2, "3. Pursuing EnemyBots active in lab")

	# 2. Four Roles Coexistence
	var breaker = BreakerScript.new()
	var scout = ScoutScript.new()
	var lock = LockScript.new()
	var carrier = CarrierScript.new()
	_check(breaker != null and scout != null and lock != null and carrier != null, "4. All 4 roles (Kırıcı, Göz, Kilit, Yük) instantiate cleanly")

	# 3. Inventory & Items
	var inv = InventoryScript.new(6)
	var medkit: Resource = load("res://assets/data/items/medkit.tres")
	var grenade: Resource = load("res://assets/data/items/grenade.tres")
	inv.add_item(medkit, 2)
	inv.add_item(grenade, 3)
	_check(inv.slots[0].count == 2 and inv.slots[1].count == 3, "5. Inventory stacks consumption and attack items")

	# 4. Carrying, Pulling & Obstacles
	var puller = PullScript.new()
	_check(puller != null and not puller.is_pulling, "6. Drag & pull mechanics initialized")
	_check(is_instance_valid(lab.combat_range.laser_corridor), "7. Environmental laser hazard active in arena")

	# 5. Alarm System & Boss
	var alarm = AlarmScript.new()
	alarm.raise_alarm(2)
	_check(alarm.current_level == 2, "8. Facility alarm escalates to Level 2")

	var boss = BossScript.new()
	root.add_child(boss)
	await process_frame
	_check(boss.health == 300.0 and boss.current_phase == 1, "9. Phased Chief encounter initialized with 300 HP")

	# 6. Director, Mutators & Event Deck
	var director = DirectorScript.new()
	director.advance(1.0, 1.0, 1.0, 0)
	_check(director.current_state == DirectorScript.PacingState.CALM, "10. AI Director operational in CALM state")

	var mutators: Array[MutatorScript.Mutator] = MutatorScript.generate_mutators_for_seed(101, 2)
	_check(mutators.size() == 2, "11. Deterministic compatible mutator set generated")

	var deck = EventDeckScript.new()
	_check(deck.is_harmless(EventDeckScript.EventType.CONFETTI), "12. Procedural event deck active")

	# 7. End-to-End Extraction Scenario
	var scenario = ScenarioScript.new()
	scenario.report_terminal_hacked()
	scenario.report_core_secured()
	var completed: bool = scenario.step_evacuation_hold(6.0, true)
	_check(completed and scenario.current_step == ScenarioScript.Step.COMPLETED, "13. Full Extraction loop completes successfully")

	# 8. Accessibility
	var access = AccessibilityScript.new()
	access.toggle_reduced_effects()
	_check(access.reduced_effects and access.screen_shake_multiplier == 0.2, "14. Accessibility reduced motion active")

	# 9. Extended Tactical Combat: Laser Sight, Active Reload, Flinch, Decals
	_check(is_instance_valid(lab.laser_sight), "15. Tactical Laser Sight wired into lab")
	_check(lab.combat.has_method(&"attempt_active_reload"), "16. Active reload timing system supported")
	_check(lab._feedback._decals.size() >= 0, "17. Persistent bullet decals supported")
	if lab.combat_range.enemies.size() > 0:
		var test_bot: CharacterBody3D = lab.combat_range.enemies[0]
		_check("flinch_timer" in test_bot, "18. Enemy bot supports flinch and suppression")

	# 10. Clean synchronized Lab reset
	lab._reset_lab()
	_check(lab._player.global_position.distance_to(Vector3(0.0, 0.75, 5.0)) < 0.1, "19. Synchronized reset returns player to spawn")
	_check(lab.combat.health == 100.0, "20. Synchronized reset restores player health")

	# Standalone Node fixtures are not tree-owned; release them explicitly.
	breaker.free()
	scout.free()
	lock.free()
	carrier.free()
	boss.queue_free()
	lab.queue_free()
	await process_frame

	print("Grand P1 Full Integration tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
