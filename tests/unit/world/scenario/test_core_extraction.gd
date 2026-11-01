extends SceneTree
## Unit tests for CoreExtractionScenario: 5-step mission loop, terminal hack, core transport, evac hold and wipe.

const ScenarioScript = preload("res://src/world/scenario/core_extraction_scenario.gd")

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
	var scenario = ScenarioScript.new()

	# 1. Starts in INFILTRATE
	_check(scenario.current_step == ScenarioScript.Step.INFILTRATE, "Scenario starts at Step 1: INFILTRATE")

	# 2. Step 1 -> Step 2: Terminal Hacked
	var step_observed := [-1, -1]
	scenario.step_changed.connect(func(o, n, d):
		step_observed[0] = o
		step_observed[1] = n
	)
	var hack_ok: bool = scenario.report_terminal_hacked()
	_check(hack_ok and scenario.current_step == ScenarioScript.Step.SECURE_CORE, "Hacking terminal advances to SECURE_CORE")
	_check(step_observed[1] == ScenarioScript.Step.SECURE_CORE, "Step changed signal emitted")

	# 3. Step 2 -> Step 3: Core Secured
	var core_ok: bool = scenario.report_core_secured()
	_check(core_ok and scenario.current_step == ScenarioScript.Step.DEFEND_CARRIER, "Securing core advances to DEFEND_CARRIER")

	# 4. Step 3 -> Step 4: Evacuation Hold
	scenario.advance(15.0) # 15s elapsed
	scenario.enemies_defeated = 4
	scenario.damage_taken = 30.0

	# Hold on evac pad
	_check(scenario.evac_hold_progress == 0.0, "Evac hold starts at 0%")
	scenario.step_evacuation_hold(2.5, true) # Half hold
	_check(scenario.evac_hold_progress > 0.45, "Holding evac pad advances progress")

	# Step off pad decays progress
	scenario.step_evacuation_hold(1.0, false)
	_check(scenario.evac_hold_progress < 0.5, "Stepping off evac pad decays hold progress")

	# Complete evac hold (5.0s)
	var summary_observed := [{}]
	scenario.mission_completed.connect(func(s): summary_observed[0] = s)
	var finished: bool = scenario.step_evacuation_hold(6.0, true)
	_check(finished and scenario.current_step == ScenarioScript.Step.COMPLETED, "Full evac hold completes mission")
	_check(summary_observed[0].has("seed") and summary_observed[0].has("elapsed_time"), "Summary contains metrics")
	_check(summary_observed[0]["enemies_defeated"] == 4, "Summary records 4 enemies defeated")

	# 5. Failure test
	scenario.reset()
	_check(scenario.current_step == ScenarioScript.Step.INFILTRATE, "Reset restores INFILTRATE step")

	var failed_seen := [false]
	scenario.mission_failed.connect(func(r): failed_seen[0] = true)
	scenario.report_squad_wiped()
	_check(scenario.current_step == ScenarioScript.Step.FAILED and failed_seen[0], "Squad wipe triggers FAILED state")

	print("CoreExtraction tests: %d checks; %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
