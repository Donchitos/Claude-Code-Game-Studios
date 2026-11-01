extends SceneTree
## Timed reload contracts: automatic empty magazine, manual admission and finite supply.

var checks := 0
var failures := 0

func _initialize() -> void:
	var state = load("res://assets/data/player_combat_default.tres").duplicate()
	state.reset()
	check(state.get("reload_remaining") != null, "Combat exposes timed reload state")
	if state.get("reload_remaining") != null:
		for index in range(7):
			check(state.try_fire(), "Loaded shot %d accepted" % index)
		check(state.ammo == 0 and is_equal_approx(state.reload_remaining, 2.0), "Final round automatically starts two-second reload")
		check(not state.try_fire(), "Reload blocks shooting")
		state.advance(1.0)
		check(state.ammo == 0 and is_equal_approx(state.reload_remaining, 1.0), "One second is not enough to refill")
		check(not state.reload() and is_equal_approx(state.reload_remaining, 1.0), "Repeated R cannot restart or accelerate reload")
		state.advance(0.99)
		check(state.ammo == 0, "Magazine remains empty before two seconds")
		state.advance(0.01)
		check(state.ammo == 7 and state.reload_remaining == 0.0, "Magazine refills at two seconds")
		check(state.try_fire(), "Shooting resumes after reload")
		check(state.reload(), "R starts partial-magazine reload")
		check(state.ammo == 6 and not state.try_fire(), "Manual reload keeps old count but blocks shooting")
		state.advance(-1.0)
		state.advance(INF)
		check(is_equal_approx(state.reload_remaining, 2.0), "Invalid delta cannot advance reload")
		state.advance(2.0)
		check(state.ammo == 7 and not state.reload(), "Full magazine does not reload")
		state.ammo = 0
		state.reserve_ammo = 3
		check(state.reload(), "Finite reserve starts reload")
		check(state.reserve_ammo == 3, "Reserve is not charged before completion")
		state.advance(2.0)
		check(state.ammo == 3 and state.reserve_ammo == 0, "Completion consumes only available reserve")
		state.ammo = 0
		check(not state.reload() and state.reload_remaining == 0.0, "Empty reserve cannot start repeated automatic reload")
		state.reserve_ammo = -1
		state.reload()
		state.reset()
		check(state.ammo == 7 and state.reload_remaining == 0.0, "F5 state reset cancels reload")
		state.try_fire()
		state.reload()
		state.cancel_reload()
		check(state.ammo == 6 and state.reload_remaining == 0.0, "Switch cancellation never creates ammunition")
		state.apply_damage(1000.0, 1)
		check(not state.reload(), "Dead player cannot start reload")
	print("Reload tests: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
