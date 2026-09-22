extends RefCounted

# Pixel-space adapter for the current Stage; one world unit = 60 pixels.
const FSM = preload("res://src/gameplay/boss/boss_state_machine.gd")
const Geometry = preload("res://src/gameplay/battle/combat_geometry.gd")
const SCALE := 60.0
enum Action { TRACK, TELEGRAPH, BITE, RECOVER }
var fsm = FSM.new()
var action := Action.TRACK
var slot := 0
var ticks := 0
var generation := 0
var segment := 0
var axis := Vector2.RIGHT
var bite_hit := false
var fan_release := false
var ring_release := false
var summon_release := false
var movement := Vector2.ZERO
var bite_active := false

func initialize(hp: float) -> void:
	fsm.initialize(hp)

func advance(position: Vector2, player_position: Vector2) -> void:
	fan_release = false
	ring_release = false
	summon_release = false
	bite_active = false
	movement = Vector2.ZERO
	# Finish an already committed bite segment before the phase transition.
	if action == Action.BITE and fsm.phase_transition_pending:
		fsm.active_age_ticks += 1
	else:
		fsm.run_active_tick(player_position)
	if fsm.state == FSM.State.DEATH_LATCHED:
		return
	if fsm.state == FSM.State.PHASE_SHIFT:
		action = Action.TRACK
		slot = 0
		ticks = 0
		return
	if fsm.state == FSM.State.ARRIVAL_LOCK:
		movement = position.direction_to(player_position) * 150.0 / 60.0
		return
	if action == Action.TRACK:
		if position.distance_to(player_position) > 9.0 * SCALE:
			movement = position.direction_to(player_position) * 150.0 / 60.0
			return
		action = Action.TELEGRAPH
		ticks = 0
		segment = 0
		generation += 1
		_lock_axis(position, player_position)
	ticks += 1
	if action == Action.TELEGRAPH:
		var duration: int = [42, 48, 60, 45][slot] if segment == 0 else 24
		if ticks >= duration:
			ticks = 0
			if slot == 0:
				action = Action.BITE
				bite_hit = false
			else:
				fan_release = slot == 1
				ring_release = slot == 2
				summon_release = slot == 3
				action = Action.RECOVER
	elif action == Action.BITE:
		bite_active = true
		movement = axis * 18.0 * SCALE / 60.0
		if ticks >= 18:
			ticks = 0
			if fsm.phase_code == 2 and segment == 0:
				segment = 1
				action = Action.TELEGRAPH
				_lock_axis(position + movement, player_position)
			else:
				action = Action.RECOVER
	elif action == Action.RECOVER:
		if ticks >= [36, 48, 60, 45][slot]:
			slot = (slot + 1) % (4 if fsm.phase_code == 2 else 3)
			action = Action.TRACK
			ticks = 0

func _lock_axis(position: Vector2, target: Vector2) -> void:
	if not position.is_equal_approx(target):
		axis = position.direction_to(target)

func fan_hits(origin: Vector2, target: Vector2, radius: float) -> bool:
	return Geometry.sector_hits(origin, axis, 7.0 * SCALE, deg_to_rad(35.0), target, radius)
