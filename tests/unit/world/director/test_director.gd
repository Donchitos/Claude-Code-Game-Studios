extends SceneTree
## Unit tests for DirectorController: 4 pacing states, tension scoring, 120s grace rule, and event selection.

const DirectorScript = preload("res://src/world/director/director_controller.gd")

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
	var director = DirectorScript.new()

	# 1. Initialization
	_check(director.current_state == DirectorScript.PacingState.CALM, "Director starts in CALM state")
	_check(director.session_elapsed == 0.0, "Session elapsed timer starts at zero")

	# 2. Tension accumulation
	director.advance(1.0, 1.0, 1.0, 0) # Full health, full ammo, 0 alarm
	_check(director.tension < 10.0, "Calm baseline tension is low")

	director.advance(1.0, 0.4, 0.2, 3) # Damaged, low ammo, high alarm
	_check(director.tension > 60.0, "High threat conditions increase tension score")
	_check(director.current_state == DirectorScript.PacingState.BUILDUP, "High tension transitions to BUILDUP")

	# 3. 120s Grace Period: PEAK is blocked during first 120s
	director.advance(10.0, 0.3, 0.1, 4) # Extreme tension (>75), but elapsed is only ~12s
	_check(director.tension >= 75.0, "Extreme tension reaches >=75")
	_check(director.current_state == DirectorScript.PacingState.BUILDUP, "PEAK state is strictly BLOCKED during first 120 seconds")

	# Advance session past 120s
	director.session_elapsed = 125.0
	director.advance(1.0, 0.3, 0.1, 4)
	_check(director.current_state == DirectorScript.PacingState.PEAK, "PEAK state is admitted after 120s grace period")

	# 4. Critical Health Relief
	director.advance(1.0, 0.15, 0.5, 0) # Health dropped to 15% (<25%)
	_check(director.current_state == DirectorScript.PacingState.RECOVERY, "Critical player health forces RECOVERY relief state")

	# 5. Non-repeating Event Selection
	var pool: Array[String] = ["AirdropCrate", "PowerSurge", "AlarmDrone"]
	var ev1: String = director.pick_next_event(pool)
	var ev2: String = director.pick_next_event(pool)
	_check(ev1 != ev2, "Director never triggers the exact same event twice in a row")

	# 6. Reset
	director.reset()
	_check(director.current_state == DirectorScript.PacingState.CALM, "Reset restores CALM state")
	_check(director.session_elapsed == 0.0, "Reset clears session elapsed time")

	print("Director tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
