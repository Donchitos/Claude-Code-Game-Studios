extends SceneTree
## Unit tests for ComboManager & PingWheel: role combos, 3s window, synergy meter, and team voting.

const ComboScript = preload("res://src/team/combos/combo_manager.gd")
const PingScript = preload("res://src/team/communication/ping_wheel.gd")

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
	# 1. Combos & 3.0s Window
	var combos = ComboScript.new()

	_check(combos.synergy == 0.0, "Synergy starts at 0")

	# Action 1: Breaker bash
	var res1: int = combos.record_action("bash")
	_check(res1 == ComboScript.ComboType.NONE, "Single action does not trigger combo")
	_check(combos.combo_window_remaining == 3.0, "Combo window opens for 3.0s")

	# Action 2: Shock weapon within window
	var combo_seen := ["", 0.0]
	combos.combo_triggered.connect(func(n, d, s):
		combo_seen[0] = n
		combo_seen[1] = s
	)
	var res2: int = combos.record_action("shock")
	_check(res2 == ComboScript.ComboType.BASH_AND_SHOCK, "Bash + Shock triggers BASH_AND_SHOCK combo")
	_check(combos.synergy == 25.0, "Combo awards +25 Synergy points")

	# 2. Window expiration prevents combo
	combos.record_action("shield")
	combos.advance(3.5) # Exceed 3.0s
	var res_late: int = combos.record_action("fire")
	_check(res_late == ComboScript.ComboType.NONE, "Action after 3.0s window does not trigger combo")

	# 3. Synergy Ultimate accumulation
	var ult_ready := [false]
	combos.team_ultimate_ready.connect(func(): ult_ready[0] = true)

	combos.add_synergy(75.0) # 25 + 75 = 100 max
	_check(combos.synergy == 100.0 and ult_ready[0], "100 Synergy activates Team Ultimate")

	var consumed: bool = combos.consume_team_ultimate()
	_check(consumed and combos.synergy == 0.0, "Consuming ultimate resets synergy to 0")

	# 4. Ping Wheel & Team Voting
	var ping = PingScript.new()
	var ping_observed := [false, ""]
	ping.ping_dispatched.connect(func(t, pos, lbl):
		ping_observed[0] = true
		ping_observed[1] = lbl
	)
	var label: String = ping.dispatch_ping(PingScript.PingType.DANGER, Vector3(5, 0, 5))
	_check(ping_observed[0] and label.contains("Tehlike"), "Dispatching DANGER ping emits correct label")

	# Team vote
	ping.start_team_vote()
	ping.cast_vote("player1", true)
	ping.cast_vote("player2", true)
	var passed: bool = ping.evaluate_vote(2)
	_check(passed and not ping.is_voting, "2 approvals pass team vote and close voting")

	combos.reset()
	_check(combos.synergy == 0.0, "Reset restores zero synergy")

	print("Combos & Ping tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
