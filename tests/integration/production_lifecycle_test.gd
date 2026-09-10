extends SceneTree

var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://src/core/GameRoot.tscn") as PackedScene
	_expect(scene != null, "GameRoot scene must load")
	if scene == null:
		_finish()
		return
	var game_root := scene.instantiate() as ProductionGameRoot
	root.add_child(game_root)
	await game_root.boot_completed
	var root_id := game_root.get_instance_id()
	var viewport_id := game_root.get_viewport().get_instance_id()
	_expect(game_root.state == ProductionGameRoot.State.HOME, "boot must activate HOME")
	_expect(not game_root.viewport_gate_held, "boot must release the viewport gate")

	(game_root.current_page as ProductionHomeScreen).start_requested.emit()
	await process_frame
	await process_frame
	_expect(game_root.state == ProductionGameRoot.State.BATTLE_ACTIVE, "HOME start signal must activate battle")
	_expect(game_root.state == ProductionGameRoot.State.BATTLE_ACTIVE, "battle must be active")
	_expect(game_root.current_battle.input_system.state == ProductionInputSystem.State.ACTIVE, "input must be active")
	_expect(game_root.current_battle.joystick_host.active_joystick_count() == 1, "exactly one joystick must exist")
	var first_scope_ref: WeakRef = weakref(game_root.current_battle)

	_expect(game_root.request_pause(false) == ProductionGameRoot.Status.OK, "pause must succeed")
	_expect(paused, "SceneTree must be paused by GameRoot")
	_expect(game_root.state == ProductionGameRoot.State.BATTLE_PAUSED, "battle must enter paused state")
	_expect(game_root.request_resume() == ProductionGameRoot.Status.OK, "resume must succeed")
	_expect(not paused, "SceneTree must resume")

	var replace_status: int = await game_root.request_replace_battle(202, true)
	_expect(replace_status == ProductionGameRoot.Status.OK, "battle replacement must succeed")
	await process_frame
	_expect(first_scope_ref.get_ref() == null, "replaced scope must be destroyed after frame barrier")
	_expect(game_root.battle_generation == 2, "battle generation must advance")
	_expect(game_root.get_instance_id() == root_id, "GameRoot identity must persist")
	_expect(game_root.get_viewport().get_instance_id() == viewport_id, "root Viewport identity must persist")

	var second_scope_ref: WeakRef = weakref(game_root.current_battle)
	var end_status: int = await game_root.request_end_battle(true)
	_expect(end_status == ProductionGameRoot.Status.OK, "battle end must succeed")
	await process_frame
	_expect(second_scope_ref.get_ref() == null, "ended scope must be destroyed after frame barrier")
	_expect(game_root.state == ProductionGameRoot.State.SETTLEMENT, "settlement must be active")
	_expect(game_root.current_battle == null, "settlement must not retain a battle scope")
	_expect(not paused, "SceneTree must be running in settlement")
	_expect(not game_root.viewport_gate_held, "settlement activation must release the gate")
	_expect(game_root.get_instance_id() == root_id, "GameRoot identity must survive settlement")
	_expect(game_root.get_viewport().get_instance_id() == viewport_id, "Viewport identity must survive settlement")
	game_root.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("PRODUCTION_LIFECYCLE_ASSERTION_FAILED %s" % message)

func _finish() -> void:
	if _failures == 0:
		print("PRODUCTION_LIFECYCLE_PASS root_persistent=true viewport_persistent=true replacements=1")
		quit(0)
	else:
		print("PRODUCTION_LIFECYCLE_FAIL failures=%d" % _failures)
		quit(1)
