extends SceneTree
## Unit tests for AlarmController & BossEncounter: 0-4 alarms, lockdown, rear weak point, and Phase 2 transition.

const AlarmScript = preload("res://src/world/alarm/alarm_controller.gd")
const BossScript = preload("res://src/ai/boss_encounter.gd")

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
	var alarm = AlarmScript.new()

	# 1. Alarm levels and escalation
	_check(alarm.current_level == 0, "Starts at Alarm Level 0 (Quiet)")

	var lockdown_seen := [false]
	alarm.lockdown_triggered.connect(func(locked): lockdown_seen[0] = locked)

	alarm.raise_alarm(1)
	_check(alarm.current_level == 1 and not lockdown_seen[0], "Level 1 (Suspicious) does not trigger lockdown")

	alarm.raise_alarm(2)
	_check(alarm.current_level == 2 and lockdown_seen[0], "Level 2 (Alert) triggers security lockdown")

	# 2. Terminal reduction
	alarm.reduce_alarm_at_terminal() # 2 -> 1
	_check(alarm.current_level == 1 and not lockdown_seen[0], "Terminal reduction releases lockdown")

	# 3. Boss Encounter mechanics
	var boss = BossScript.new()
	boss.position = Vector3(0.0, 0.0, 0.0)
	root.add_child(boss)
	await process_frame

	_check(boss.current_phase == 1 and not boss.is_berserk, "Boss starts in Phase 1")
	_check(boss.health == 300.0, "Boss starts with 300 max health")

	# Frontal hit absorption (100 dmg * 0.20 = 20 effective dmg)
	var front_pos := Vector3(0.0, 0.0, -2.0) # in front of boss (-Z)
	boss.receive_hit_directional(100.0, front_pos, 0)
	_check(boss.health == 280.0, "Frontal hit absorbs 80% damage (takes 20 dmg)")

	# Rear weak-point hit (40 dmg * 2.5 = 100 effective dmg)
	var rear_pos := Vector3(0.0, 0.0, 2.0) # behind boss (+Z)
	boss.receive_hit_directional(40.0, rear_pos, 0)
	_check(boss.health == 180.0, "Rear hit on power cell deals 2.5x critical damage")

	# Phase 2 transition at <= 150 HP
	var phase_seen := [0]
	boss.phase_changed.connect(func(p): phase_seen[0] = p)
	boss.receive_hit_directional(20.0, rear_pos, 0) # 20 * 2.5 = 50 dmg -> 130 HP
	_check(boss.health <= 150.0, "Health drops below 50% threshold")
	_check(boss.current_phase == 2 and boss.is_berserk and phase_seen[0] == 2, "Transitioned into Berserk Phase 2")

	# Reset
	boss.reset_boss()
	_check(boss.current_phase == 1 and boss.health == 300.0 and not boss.is_berserk, "Boss reset restores Phase 1 and 300 HP")

	alarm.reset_alarm()
	_check(alarm.current_level == 0, "Alarm reset restores Level 0")

	boss.queue_free()
	await process_frame

	print("Alarm & Boss tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
