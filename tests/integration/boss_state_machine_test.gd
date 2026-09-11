extends SceneTree

const BossStateMachine = preload("res://src/gameplay/boss/boss_state_machine.gd")

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var boss := BossStateMachine.new()
	_expect(boss.initialize(12000.0) == BossStateMachine.Status.OK, "Boss must initialize with positive finite HP")
	var early: Dictionary = boss.consider_mandatory_spawn(43198, false, false)
	var due: Dictionary = boss.consider_mandatory_spawn(43199, false, false)
	var duplicate: Dictionary = boss.consider_mandatory_spawn(50000, false, false)
	_expect(not bool(early["spawn"]) and bool(due["spawn"]) and not bool(duplicate["spawn"]), "mandatory row must claim exactly once at executing tick 43200")

	for _tick in 119:
		boss.run_active_tick(Vector2(1.0, 2.0))
	_expect(boss.state == BossStateMachine.State.ARRIVAL_LOCK, "arrival lock must remain through tick 119")
	_expect(boss.apply_hp_receipt(1, 6100.0, 6000.0) == BossStateMachine.Status.OK, "exact threshold crossing must latch")
	_expect(boss.phase_transition_pending, "crossing during arrival must remain pending")
	boss.run_active_tick(Vector2(3.0, 4.0))
	_expect(boss.state == BossStateMachine.State.PHASE_SHIFT and boss.fog_anchor == Vector2(3.0, 4.0), "arrival completion must enter phase shift and freeze player anchor")
	var frozen_ticks := boss.state_ticks
	_expect(boss.state_ticks == frozen_ticks, "pause simulation must not advance without an Active tick call")
	for _tick in 89:
		boss.run_active_tick(Vector2(99.0, 99.0))
	_expect(boss.state == BossStateMachine.State.PHASE_SHIFT, "phase shift must last 90 Active ticks")
	boss.run_active_tick(Vector2(99.0, 99.0))
	_expect(boss.state == BossStateMachine.State.TRACK_P2 and boss.phase_code == 2, "phase shift completion must publish phase two")
	_expect(boss.fog_anchor == Vector2(3.0, 4.0), "fog anchor must not follow the player")
	for _tick in 1800:
		boss.run_active_tick(Vector2.ZERO)
	_expect(is_equal_approx(boss.fog_safe_radius(), 7.25), "fog radius must be 7.25 at half shrink duration")

	var even_directions := BossStateMachine.ring_directions(2)
	var odd_directions := BossStateMachine.ring_directions(3)
	_expect(even_directions.size() == 8 and odd_directions.size() == 8, "ring must contain exactly eight directions")
	_expect(even_directions[0].is_equal_approx(Vector2.RIGHT), "even generation must start at zero degrees")
	_expect(is_equal_approx(rad_to_deg(odd_directions[0].angle()), 22.5), "odd generation must start at 22.5 degrees")

	var lethal := BossStateMachine.new()
	lethal.initialize(12000.0)
	_expect(lethal.apply_hp_receipt(1, 6100.0, 0.0) == BossStateMachine.Status.OK, "lethal receipt must apply")
	_expect(lethal.state == BossStateMachine.State.DEATH_LATCHED and not lethal.phase_transition_pending, "lethal must win over phase transition")
	_expect(lethal.apply_hp_receipt(1, 6100.0, 0.0) == BossStateMachine.Status.DUPLICATE_RECEIPT, "duplicate receipt must not replay")
	_finish()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("BOSS_FSM_ASSERTION_FAILED %s" % message)

func _finish() -> void:
	if _failures == 0:
		print("BOSS_FSM_PASS schedule=true arrival=true phase=true pause=true fog=true ring=true lethal=true")
		quit(0)
	else:
		print("BOSS_FSM_FAIL failures=%d" % _failures)
		quit(1)
