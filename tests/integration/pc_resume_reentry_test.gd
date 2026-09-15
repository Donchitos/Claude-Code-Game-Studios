extends SceneTree

class GateHook extends ProductionGameRoot:
	var inject_at := &""
	var tick_escaped := false
	func acquire_viewport_input_gate() -> ProductionGameRoot.Status:
		var result := super.acquire_viewport_input_gate()
		if _resume_in_progress and inject_at == &"acquire":
			inject_at = &""
			_on_window_focus_exited()
		return result
	func release_viewport_input_gate(reason: StringName) -> ProductionGameRoot.Status:
		var result := super.release_viewport_input_gate(reason)
		if _resume_in_progress and inject_at == &"release":
			inject_at = &""
			var before := current_battle.completed_active_ticks
			_physics_process(1.0 / 60.0)
			tick_escaped = current_battle.completed_active_ticks != before
			_on_window_focus_exited()
		return result

class UnpauseHook extends Node:
	var callback: Callable
	var armed := false
	func _notification(what: int) -> void:
		if what == NOTIFICATION_UNPAUSED and armed:
			armed = false
			callback.call()

var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _run() -> void:
	for boundary: String in ["acquire", "unpause", "visibility", "focus", "loss_gain", "release"]:
		await run_case(boundary)
	print("PC_RESUME_REENTRY_%s checks=%d synthetic_focus=true physical_device=false" % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)

func run_case(boundary: String) -> void:
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.set_script(GateHook)
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	check(await game.request_start_battle(135, false) == 0, boundary + " start")
	var battle: ProductionBattleScope = game.current_battle
	battle.stage._spawn_left = 999.0
	var hook := UnpauseHook.new()
	hook.process_mode = Node.PROCESS_MODE_PAUSABLE
	hook.callback = game._on_window_focus_exited
	game.add_child(hook)
	check(game.request_pause() == 0, boundary + " initial pause")
	var observed := {"fired": false, "early_ingress": false, "nested_result": -1}
	var invalidate := func() -> void:
		observed.fired = true
		observed.early_ingress = battle.input_system.ingress_armed
		game._on_window_focus_exited()
		if boundary == "loss_gain":
			game._on_window_focus_entered()
	match boundary:
		"acquire", "release":
			game.inject_at = StringName(boundary)
		"unpause":
			hook.callback = invalidate
			hook.armed = true
		"visibility", "loss_gain":
			battle.battle_ui._overlay.visibility_changed.connect(invalidate, CONNECT_ONE_SHOT)
			if boundary == "loss_gain":
				battle.battle_ui._overlay.visibility_changed.connect(func() -> void:
					if battle.battle_ui._overlay.visible:
						observed.nested_result = game.request_resume())
		"focus":
			battle.battle_ui._pause_button.focus_entered.connect(invalidate, CONNECT_ONE_SHOT)
	var before_position := battle.player.position
	var before_ticks := battle.completed_active_ticks
	check(game.request_resume() == ProductionGameRoot.Status.WRONG_STATE, boundary + " invalidation rejects resume")
	if boundary not in ["acquire", "release"]:
		check(observed.fired and not observed.early_ingress, boundary + " callback ran with input frozen")
	check(game.state == ProductionGameRoot.State.BATTLE_PAUSED and paused, boundary + " root remains paused")
	check(battle.state == ProductionBattleScope.State.PAUSED and battle.input_system.state == ProductionInputSystem.State.FROZEN, boundary + " scope and input frozen")
	check(not battle.input_system.ingress_armed and battle.movement_carrier.direction == Vector2.ZERO and not battle.movement_context.open, boundary + " no movement lease")
	check(not game.viewport_gate_held and not root.gui_disable_input and battle.battle_ui._overlay.visible, boundary + " paused UI remains usable")
	check(not game.tick_escaped, boundary + " no reentrant active tick")
	if boundary == "loss_gain":
		check(observed.nested_result == ProductionGameRoot.Status.WRONG_STATE, "rollback cannot recursively continue")
	game._on_window_focus_entered()
	for i in 3:
		game._physics_process(1.0 / 60.0)
	check(battle.completed_active_ticks == before_ticks and battle.player.position == before_position, boundary + " refocus alone does not simulate")
	check(game.request_resume() == 0, boundary + " new explicit Continue succeeds")
	game._physics_process(1.0 / 60.0)
	check(battle.completed_active_ticks == before_ticks + 1, boundary + " new Continue resumes ticks")
	game.queue_free()
	await process_frame
