class_name CampaignMission
extends RefCounted
## Pure, JSON-safe objective authority. Arena owns entities, movement and damage.

## Creates state for a validated catalog definition. No Vector2/Object is persisted.
static func create(definition: Dictionary) -> Dictionary:
	return {"kind": str(definition.get("kind", "")), "elapsed": 0.0, "progress": 0,
		"completed_ids": [], "completion_order": [], "hold": 0.0, "waypoint": 0,
		"escort_hp": float(definition.get("escort_hp", 0.0)), "player_alive": true,
		"finished": false, "victory": false, "reason": "", "extraction_ready": false,
		"extraction_was_inside": false, "pressure": 0.0}

## Mutates only state. delta is active simulation time; paused callers do not call.
## enemy_positions contains live Vector2 positions, target_deaths contains stable
## strings from definition.target_ids (real death events, never retire/despawn IDs).
## Arena writes player_alive and escort_hp BEFORE this call; death wins same-tick ties.
## FIXED anchors must be invulnerable before activation; early deaths are ignored.
## For HUNT multiple target_ids are supported and all are required, in any order.
## Escort movement belongs to Arena; proximity confirms one ordered waypoint/tick.
static func advance(state: Dictionary, definition: Dictionary, delta: float,
		player_position: Vector2, enemy_positions: Array, target_deaths: Array,
		escort_position: Vector2) -> void:
	if bool(state.get("finished", false)):
		return
	if not is_finite(delta) or delta < 0.0:
		return
	if not bool(state.get("player_alive", true)):
		_finish(state, false, "player_dead")
		return
	var kind := str(definition.get("kind", ""))
	if kind == "ESCORT" and float(state.get("escort_hp", 0.0)) <= 0.0:
		_finish(state, false, "escort_destroyed")
		return
	if not kind in ["SURVIVE", "BREAK", "CLEANSE", "HUNT", "ESCORT", "BOSS"]:
		_finish(state, false, "invalid_definition")
		return
	state.elapsed = float(state.elapsed) + delta
	# Deadline is inclusive: no success can be introduced at/after timeout.
	if float(state.elapsed) >= float(definition.timeout_seconds):
		_finish(state, false, "timeout")
		return
	var positions: Array = definition.target_positions
	var ids: Array = definition.target_ids
	var count := int(definition.target_count)
	if positions.size() != count or ids.size() != count or count < 1:
		_finish(state, false, "invalid_definition")
		return
	match kind:
		"SURVIVE":
			var ready := float(state.elapsed) >= float(definition.target_seconds)
			var inside := player_position.distance_to(_position(positions[0])) <= float(definition.target_radius)
			# Waiting inside the exit before the window does not count as entering it.
			if ready and not bool(state.extraction_ready):
				state.extraction_ready = true
				state.extraction_was_inside = inside
			elif ready and inside and not bool(state.extraction_was_inside):
				_record(state, str(ids[0]))
				_finish(state, true, "extracted")
			state.extraction_was_inside = inside
		"BREAK":
			for value: Variant in target_deaths:
				if not value is String or not value in ids or value in state.completed_ids:
					continue
				if definition.order_mode == "FIXED" and value != ids[int(state.progress)]:
					continue
				_record(state, value)
				# PLAYER_CHOICE order produces a persisted pressure modifier for Arena.
				if definition.order_mode == "PLAYER_CHOICE":
					state.pressure = float(ids.find(value) + 1) / float(count) * float(definition.get("order_pressure_max", 0.0))
				if int(state.progress) == count:
					_finish(state, true, "anchors_destroyed")
					break
		"HUNT", "BOSS":
			for value: Variant in target_deaths:
				if value is String and value in ids and not value in state.completed_ids:
					_record(state, value)
			if int(state.progress) == count:
				_finish(state, true, "boss_defeated" if kind == "BOSS" else "targets_hunted")
		"CLEANSE":
			var index := int(state.waypoint)
			if index < 0 or index >= count:
				_finish(state, false, "invalid_state")
				return
			var center := _position(positions[index])
			var legal := player_position.distance_to(center) <= float(definition.target_radius)
			for enemy: Variant in enemy_positions:
				if enemy is Vector2 and enemy.distance_to(center) <= float(definition.cleanse_enemy_radius):
					legal = false
					break
			if legal:
				state.hold = minf(float(definition.hold_seconds), float(state.hold) + delta)
			if float(state.hold) >= float(definition.hold_seconds):
				_record(state, str(ids[index]))
				state.hold = 0.0
				state.waypoint = index + 1
				if int(state.progress) == count:
					_finish(state, true, "zones_cleansed")
		"ESCORT":
			var index := int(state.waypoint)
			if index < 0 or index >= count:
				_finish(state, false, "invalid_state")
				return
			if player_position.distance_to(escort_position) <= float(definition.escort_radius) and escort_position.distance_to(_position(positions[index])) <= float(definition.target_radius):
				_record(state, str(ids[index]))
				state.waypoint = index + 1
				if int(state.progress) == count:
					_finish(state, true, "escort_arrived")

static func _position(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

static func _record(state: Dictionary, id: String) -> void:
	state.completed_ids.append(id)
	state.completion_order.append(id)
	state.progress = state.completed_ids.size()

static func _finish(state: Dictionary, victory: bool, reason: String) -> void:
	state.finished = true
	state.victory = victory
	state.reason = reason
