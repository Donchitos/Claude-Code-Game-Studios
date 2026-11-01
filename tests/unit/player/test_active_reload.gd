extends SceneTree
## Unit tests for Active Reload (Synthetik style): sweet-spot timing, bonus damage rounds, and mistimed jam.

const CombatPreset = preload("res://assets/data/player_combat_default.tres")
const WeaponControllerScript = preload("res://src/combat/weapon_controller.gd")

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
	var state = CombatPreset.duplicate()
	state.reset()

	# 1. Start reload
	state.ammo = 0
	_check(state.reload(), "Reload started on empty magazine")
	_check(state.reload_remaining == 2.0, "Reload remaining starts at 2.0s")
	_check(state.active_reload_bonus_shots == 0, "No active reload bonus initially")

	# 2. Too early press (< 0.45 progress, i.e. elapsed < 0.9s)
	state.advance(0.4) # Elapsed 0.4s (progress 20% < 45%)
	var early_result: bool = state.attempt_active_reload()
	_check(not early_result, "Premature active reload attempt is rejected")
	_check(state.reload_remaining > 2.0, "Premature reload attempt adds +0.5s jam penalty")

	# Reset and start fresh reload
	state.reset()
	state.ammo = 0
	state.reload()

	# 3. Sweet-spot press (45% to 75% progress, e.g. at 55% -> elapsed 1.1s, remaining 0.9s)
	state.advance(1.1)
	var active_eval := [false, 0]
	state.active_reload_evaluated.connect(func(s, b):
		active_eval[0] = s
		active_eval[1] = b
	)
	var sweet_spot_result: bool = state.attempt_active_reload()
	_check(sweet_spot_result, "Sweet spot timing succeeds (active reload success)")
	_check(state.reload_remaining == 0.0, "Success immediately completes reload")
	_check(state.ammo == state.magazine_capacity, "Magazine refilled immediately")
	_check(state.active_reload_bonus_shots == 3, "Grants exactly 3 bonus damage shots")
	_check(active_eval[0] and active_eval[1] == 3, "Emitted active_reload_evaluated with 3 bonus rounds")

	# 4. Damage Boost in Weapon Controller (+25% damage on first 3 shots)
	var controller = WeaponControllerScript.new()
	controller.state = state
	root.add_child(controller)

	var target = load("res://src/combat/damageable_prop.gd").new()
	target.position = Vector3(0.0, 0.0, -3.0)
	target.max_health = 200.0
	root.add_child(target)
	await physics_frame
	await physics_frame

	var base_dmg: float = controller.current_profile().damage # 20.0 for pistol
	controller.fire_at(Vector3.ZERO, Vector3.FORWARD, false)
	# Target should take 20.0 * 1.25 = 25.0 damage
	_check(target.health == 175.0, "Active reload bonus shot deals +25% damage (25.0 instead of 20.0)")
	_check(state.active_reload_bonus_shots == 2, "Bonus round count decrements to 2")

	# Clean up
	target.queue_free()
	controller.queue_free()
	await process_frame

	print("Active Reload tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
