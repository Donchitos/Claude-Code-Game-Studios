class_name CampaignArena
extends Node2D
## Production campaign simulation. The owning root is the only clock/input owner.
const Combat = preload("res://src/campaign/campaign_combat.gd")
const Mission = preload("res://src/campaign/campaign_mission.gd")
const Rendering = preload("res://src/campaign/campaign_arena_render.gd")
const Validation = preload("res://src/campaign/campaign_arena_validation.gd")
const Codec = preload("res://src/campaign/campaign_arena_codec.gd")
const FORMAT := "CAMPAIGN_GAMEPLAY_V1"
## Presentation-only preference; never changes simulation or RNG.
var reduce_motion := false
var state: Dictionary = {}
var sound_events: Array[String] = []
var catalog: Dictionary = {}
var mission: Dictionary = {}
var loadout: Dictionary = {}
var tables: Dictionary = {}
var tuning: Dictionary = {}
var rng := RandomNumberGenerator.new()
var ready_for_play := false

## Initializes a fresh mission or atomically rejects an invalid saved run.
func configure(p_catalog: Dictionary, mission_definition: Dictionary, p_loadout: Dictionary, run_seed: int, saved: Dictionary = {}) -> bool:
	ready_for_play = false
	if p_catalog.get("skills", []).is_empty() or mission_definition.is_empty() or not Validation.valid_loadout(p_catalog, mission_definition, p_loadout):
		return false
	if not saved.is_empty() and (not validate_snapshot(p_catalog, mission_definition, saved) or not Validation.same_values(saved.get("loadout", {}), p_loadout) or str(saved.get("rng_seed", "")) != str(run_seed)):
		return false
	catalog = p_catalog.duplicate(true)
	mission = mission_definition.duplicate(true)
	loadout = Codec.normalize(p_loadout)
	for key in ["difficulty", "completed"]:
		if loadout.has(key): loadout[key] = int(loadout[key])
	if loadout.get("branches") is Array:
		for i in loadout.branches.size(): loadout.branches[i] = int(loadout.branches[i])
	tables.clear()
	for key in ["skills", "passives", "evolutions", "characters", "enemies", "elites", "bosses", "pills", "events", "challenges"]:
		tables[key] = {}
		for row in catalog.get(key, []):
			tables[key][row.id] = row
	var raw: Variant = catalog.get("tuning", {})
	tuning = raw.duplicate(true) if raw is Dictionary else {}
	if raw is Array:
		for row in raw:
			if row is Dictionary:
				tuning.merge(row, true)
	if not tables.characters.has(str(loadout.get("character_id", ""))):
		return false
	if not saved.is_empty():
		state = Codec.restore(saved.state, saved.numeric_bits)
		rng.seed = str(saved.rng_seed).to_int()
		rng.state = str(saved.rng_state).to_int()
	else:
		rng.seed = run_seed
		_new_run()
	sound_events.clear()
	ready_for_play = true
	queue_redraw()
	return true

## Advances only when explicitly called; choice overlays freeze the entire simulation.
func advance(delta: float, movement: Vector2) -> void:
	if not ready_for_play or state.finished or not state.offered.is_empty() or state.event_id != "":
		return
	if not is_finite(delta) or delta <= 0.0 or delta > 0.25 or not movement.is_finite():
		return
	_step(delta, movement.limit_length())
	queue_redraw()

## Returns a detached JSON-safe snapshot, including pending work and RNG bit patterns.
func snapshot() -> Dictionary:
	if not ready_for_play:
		return {}
	return {"schema": FORMAT, "content_hash": str(catalog.get("content_hash", "")), "definition_hash": definition_hash(catalog, mission), "mission_id": mission.id,
		"loadout": Codec.normalize(loadout), "rng_seed": str(rng.seed), "rng_state": str(rng.state), "state": Codec.normalize(state), "numeric_bits": Codec.bits(state)}

## Read-only preflight used by profile/root before constructing a battle.
static func validate_snapshot(p_catalog: Dictionary, p_mission: Dictionary, saved: Dictionary) -> bool:
	if saved.get("schema") != FORMAT or saved.get("mission_id") != p_mission.get("id"):
		return false
	if saved.get("definition_hash") != definition_hash(p_catalog, p_mission):
		return false
	return Validation.validate(p_catalog, p_mission, saved)

## Stable content binding survives JSON numeric int/float round trips.
static func definition_hash(p_catalog: Dictionary, p_mission: Dictionary) -> String:
	return (str(p_catalog.get("content_hash", "")) + "|" + str(p_mission.get("id", ""))).sha256_text()

## Accepts only the already persisted draft candidate; illegal input has zero effects.
func choose_upgrade(id: String) -> bool:
	return _choose_upgrade(id)

## Resolves the pending event once with actual safe/risk modifiers.
func choose_event(risk: bool) -> bool:
	return _choose_event(risk)

## Localized mission progress for the root HUD.
func objective_text(locale: String) -> String:
	var o: Dictionary = state.get("objective", {})
	var en := locale.begins_with("en")
	var kind := str(mission.get("kind", "SURVIVE")).to_upper()
	match kind:
		"SURVIVE":
			return ("Reach extraction" if en else "前往撤离符阵") if float(state.get("elapsed", 0)) >= float(mission.get("target_seconds", 60)) else ("Survive %.0f / %.0fs" if en else "存活 %.0f / %.0f秒") % [state.get("elapsed", 0), mission.get("target_seconds", 60)]
		"ESCORT":
			return ("Escort %d/%d · HP %.0f" if en else "护送 %d/%d · 灵舟生命 %.0f") % [o.get("progress", 0), mission.get("target_positions", []).size(), o.get("escort_hp", 0)]
		"BOSS": return "Defeat the boss" if en else "击败首领"
		"CLEANSE": return ("Cleanse %d/%d · %.0f%%" if en else "净化 %d/%d · %.0f%%") % [o.get("progress", 0), mission.get("target_count", 1), 100.0 * float(o.get("hold", 0)) / maxf(1, float(mission.get("target_seconds", 12)))]
		_: return ("Targets %d / %d" if en else "目标 %d / %d") % [o.get("progress", 0), mission.get("target_count", 1)]

## Detached settlement statistics; no UI access to mutable internals is needed.
func stats() -> Dictionary:
	var result: Dictionary = state.get("statistics", {}).duplicate(true)
	for key in ["level", "kills"]:
		result[key] = state.get("player", {}).get(key, 0)
	result.event_reward = state.get("event_reward", 0)
	result.evolution_ids = state.get("evolved", []).duplicate()
	result.elapsed = state.get("elapsed", 0.0)
	return Codec.normalize(result)

## Camera target in scene world coordinates.
func player_world_position() -> Vector2:
	return pos(state.get("player", {}))

## JSON entity coordinates to a transient engine vector.
static func pos(entity: Dictionary) -> Vector2:
	return Vector2(float(entity.get("x", 0)), float(entity.get("y", 0)))

func _new_run() -> void:
	var c: Dictionary = tables.characters[loadout.character_id]
	var hp := float(tuning.get("player_hp", 100)) * float(c.get("hp_multiplier", 1))
	state = {"player": {"x": 0.0, "y": 0.0, "hp": hp, "max_hp": hp, "level": 1, "xp": 0.0, "kills": 0, "invulnerable": 0.0, "facing": 0.0},
		"elapsed": 0.0, "objective": {},
		"skills": {str(c.start_skill): 1}, "passives": {}, "offered": [], "event_id": "", "finished": false, "victory": false, "reason": "",
		"entities": [], "projectiles": [], "zones": [], "pickups": [], "effects": [], "obstacles": [], "cooldowns": {}, "evolved": [],
		"spawn_clock": 0.0, "elite_clock": 0.0, "event_clock": 0.0, "event_done": false, "next_id": 1, "tick": 0,
		"modifiers": {}, "statistics": {"damage_taken": 0.0, "elite_kills": 0, "boss_kills": 0, "evolutions": 0, "skills_used": [], "events_taken": 0, "safe_choices": 0, "risk_choices": 0, "damage_dealt": 0.0}, "pending_levels": 0, "rerolls": 0, "event_pressure": 0.0, "event_reward": 0, "pill_remaining": 0.0, "pill_stat": "", "pill_amount": 0.0, "active_cap": 4, "enemy_multiplier": 1.0, "hazard_multiplier": 1.0}
	_apply_starting_stats()
	_make_map()

func _step(delta: float, movement: Vector2) -> void:
	state.tick += 1
	_advance_pill(delta)
	state.elapsed += delta
	var p: Dictionary = state.player
	p.invulnerable = maxf(0, float(p.invulnerable) - delta)
	var speed := float(tuning.get("player_speed", 280)) * float(tables.characters[loadout.character_id].get("speed_multiplier", 1)) * (1.0 + modifier("move_speed"))
	var next := pos(p) + movement * speed * delta
	if movement.length_squared() > 0.01:
		p.facing = movement.angle()
	set_pos(p, constrain(next, 16.0))
	state.spawn_clock -= delta
	if state.spawn_clock <= 0:
		state.spawn_clock += maxf(0.12, float(mission.get("spawn_interval", tuning.get("spawn_interval", 0.8))) / ((1.0 + state.elapsed / 180.0 + state.event_pressure + float(state.objective.pressure)) * state.enemy_multiplier))
		var ids: Array = mission.get("enemy_ids", tables.enemies.keys())
		if not ids.is_empty():
			for i in 1 + mini(3, int(state.elapsed / 90.0)):
				spawn_enemy(str(ids[rng.randi_range(0, ids.size() - 1)]), spawn_position())
	state.elite_clock += delta
	if state.elite_clock >= float(tuning.get("elite_interval", 40)):
		state.elite_clock = 0.0
		if not tables.elites.is_empty():
			var ids: Array = tables.elites.keys()
			spawn_enemy(ids[rng.randi_range(0, ids.size() - 1)], spawn_position(), "elite")
	Combat.advance_skills(self, delta)
	Combat.advance_enemies(self, delta)
	Combat.advance_projectiles(self, delta)
	Combat.advance_zones(self, delta)
	_reap()
	_pickups(delta)
	_advance_objective(delta)
	for i in range(state.effects.size() - 1, -1, -1):
		state.effects[i].ttl -= delta
		if state.effects[i].ttl <= 0:
			state.effects.remove_at(i)
	# Mission is the single terminal authority, including death and deadline precedence.
	if state.objective.finished:
		_finish(state.objective.victory, state.objective.reason)
	if not state.finished:
		_check_levels()
		if state.offered.is_empty() and not state.event_done and state.elapsed >= float(tuning.get("event_interval", 35)) and not tables.events.is_empty():
			var eligible: Array = []
			for row in catalog.events:
				if int(row.get("unlock_after", 0)) <= int(loadout.get("completed", 0)):
					eligible.append(row.id)
			if not eligible.is_empty():
				state.event_id = eligible[rng.randi_range(0, eligible.size() - 1)]

func _make_map() -> void:
	state.target_deaths = []
	state.objective = Mission.create(mission)
	state.objective.x = 0.0
	state.objective.y = 0.0
	state.boss_spawned = false
	var half := half_size()
	# Alternating inner/outer landmark arcs keep all target-to-target routes open.
	var scene := int(mission.get("ordinal", 1)) + int(mission.get("chapter", 1)) * 2
	for i in 8:
		var angle := TAU * float(i) / 8.0 + float(scene % 2) * 0.17
		var point := Vector2(cos(angle) * half.x * 0.62, sin(angle) * half.y * 0.65)
		var clear := point.length() > 150
		for target in mission.get("target_positions", []):
			if point.distance_to(Vector2(target[0], target[1])) < 180:
				clear = false
		if clear:
			state.obstacles.append({"x": point.x, "y": point.y, "radius": 28.0 + float((i + scene) % 3) * 8.0})
	var kind := str(mission.kind).to_upper()
	if kind == "BREAK":
		for i in int(mission.get("target_count", 1)):
			var q := target_position(i)
			var e := spawn_enemy("", q, "target")
			if not e.is_empty():
				e.target_id = str(mission.id) + ":T" + str(i + 1)
				e.hp = float(mission.get("target_hp", 180))
				e.max_hp = e.hp
				e.ordinal = i
	elif kind == "HUNT":
		var ids: Array = tables.elites.keys()
		var e := spawn_enemy(str(ids[0]) if not ids.is_empty() else str(mission.enemy_ids[0]), target_position(0), "elite")
		if not e.is_empty():
			e.target_id = str(mission.id) + ":HUNT"
	elif kind == "BOSS":
		spawn_enemy(str(mission.get("boss_id", "")), target_position(0), "boss")
		state.boss_spawned = true
	elif kind == "ESCORT":
		set_pos(state.objective, Vector2(-half.x * 0.65, 0))

func _apply_starting_stats() -> void:
	var c: Dictionary = tables.characters[loadout.character_id]
	if c.has("passive_stat"):
		state.modifiers[c.passive_stat] = float(c.get("passive_amount", 0))
	var branches: Array = loadout.get("branches", [0, 0, 0])
	state.modifiers.damage = float(state.modifiers.get("damage", 0)) + int(branches[0]) * float(tuning.get("progression_damage_per_level", 0.08))
	state.modifiers.pickup_radius = float(state.modifiers.get("pickup_radius", 0)) + int(branches[2]) * float(tuning.get("progression_pickup_per_level", 15))
	state.player.max_hp += int(branches[1]) * float(tuning.get("progression_hp_per_level", 10))
	var pill: Dictionary = tables.pills.get(str(loadout.get("pill_id", "")), {})
	if not pill.is_empty():
		state.pill_stat = str(pill.stat)
		state.pill_amount = float(pill.amount)
		state.pill_remaining = float(pill.duration)
		if pill.stat == "rerolls": state.rerolls = int(pill.amount)
		if pill.stat == "max_hp": state.player.max_hp += float(pill.amount)
	state.player.max_hp += modifier("max_hp")
	state.player.hp = state.player.max_hp
	var challenge: Dictionary = tables.challenges.get(str(loadout.get("challenge_id", "")), {})
	if not challenge.is_empty():
		state.active_cap = mini(4, int(challenge.max_skills))
		state.enemy_multiplier = float(challenge.enemy_multiplier)
		state.hazard_multiplier = float(challenge.hazard_multiplier)

func _advance_pill(delta: float) -> void:
	if state.pill_remaining <= 0: return
	state.pill_remaining = maxf(0, state.pill_remaining - delta)
	if state.pill_remaining == 0:
		if state.pill_stat == "max_hp":
			state.player.max_hp -= state.pill_amount
			state.player.hp = minf(state.player.hp, state.player.max_hp)
		if state.pill_stat == "rerolls": state.rerolls = 0
	elif state.pill_stat == "regeneration" and state.player.hp > 0:
		state.player.hp = minf(state.player.max_hp, state.player.hp + state.pill_amount * delta)

## Aggregated build stat; passive ranks and event modifiers have immediate effects.
func modifier(key: String) -> float:
	var value := float(state.modifiers.get(key, 0))
	if state.pill_remaining > 0 and state.pill_stat == key and key not in ["max_hp", "rerolls"]: value += state.pill_amount
	var passive_ids: Array = state.passives.keys()
	passive_ids.sort()
	for id in passive_ids:
		var row: Dictionary = tables.passives[id]
		if row.get("stat", "") == key:
			value += float(row.get("amount", row.get("per_rank", 0.1))) * int(state.passives[id])
	return value

func _apply_modifiers(row: Dictionary) -> void:
	if row.has("stat"):
		var key := str(row.stat)
		state.modifiers[key] = float(state.modifiers.get(key, 0)) + float(row.get("amount", 0))
	var mods: Dictionary = row.get("modifiers", {})
	for key in mods:
		state.modifiers[key] = float(state.modifiers.get(key, 0)) + float(mods[key])

func _check_levels() -> void:
	var required := float(tuning.get("xp_base", 6)) + float(tuning.get("xp_step", 4)) * (int(state.player.level) - 1)
	if state.player.xp >= required and int(state.player.level) < 100:
		state.player.xp -= required
		state.player.level += 1
		state.player.hp = minf(state.player.max_hp, state.player.hp + state.player.max_hp * 0.08)
		_offer()
		sound("level")

func _offer() -> void:
	var options: Array[String] = []
	for family in ["skills", "passives"]:
		for row in catalog[family]:
			var rank := int(state[family].get(row.id, 0))
			if int(row.get("unlock_after", 0)) <= int(loadout.get("completed", 0)) and rank < 5 and (rank > 0 or state[family].size() < (int(state.active_cap) if family == "skills" else 4)):
				options.append(row.id)
	for row in catalog.evolutions:
		if int(state.skills.get(row.skill_id, 0)) == 5 and int(state.passives.get(row.passive_id, 0)) >= int(row.get("required_passive_level", 5)) and not state.evolved.has(row.id):
			options.append(row.id)
	state.offered.clear()
	# One build-continuation slot and one compatible ingredient slot make evolution
	# attainable in a single mission while the remaining choice preserves diversity.
	var evolution_options: Array[String] = []
	var owned_options: Array[String] = []
	var ingredient_options: Array[String] = []
	for id in options:
		if tables.evolutions.has(id): evolution_options.append(id)
		elif state.skills.has(id) or state.passives.has(id): owned_options.append(id)
	for row in catalog.evolutions:
		if state.skills.has(row.skill_id) and options.has(row.passive_id) and not ingredient_options.has(row.passive_id): ingredient_options.append(row.passive_id)
	for bank in [evolution_options, owned_options, ingredient_options]:
		if state.offered.size() >= 3: break
		var remaining: Array = []
		for id in bank:
			if not state.offered.has(id): remaining.append(id)
		if not remaining.is_empty():
			var id: String = remaining[rng.randi_range(0, remaining.size() - 1)]
			state.offered.append(id)
			options.erase(id)
	while state.offered.size() < 3 and not options.is_empty():
		var selected := rng.randi_range(0, options.size() - 1)
		state.offered.append(options[selected])
		options.remove_at(selected)

func _choose_upgrade(id: String) -> bool:
	if not ready_for_play or state.finished or not state.offered.has(id):
		return false
	for family in ["skills", "passives"]:
		if tables[family].has(id):
			var rank := int(state[family].get(id, 0))
			if rank >= 5 or (rank == 0 and state[family].size() >= (int(state.active_cap) if family == "skills" else 4)):
				return false
			state[family][id] = rank + 1
			if family == "passives" and tables.passives[id].get("stat") == "max_hp":
				var extra := float(tables.passives[id].get("amount", 0.1))
				state.player.max_hp += extra
				state.player.hp += extra
			state.offered.clear()
			_check_levels()
			return true
	if tables.evolutions.has(id):
		var recipe: Dictionary = tables.evolutions[id]
		if int(state.skills.get(recipe.skill_id, 0)) != 5 or int(state.passives.get(recipe.passive_id, 0)) < int(recipe.get("required_passive_level", 5)) or state.evolved.has(id):
			return false
		state.evolved.append(id)
		state.statistics.evolutions += 1
		state.offered.clear()
		_check_levels()
		return true
	return false

func _choose_event(risk: bool) -> bool:
	if not ready_for_play or state.finished or not tables.events.has(state.event_id):
		return false
	var row: Dictionary = tables.events[state.event_id]
	var choice: Dictionary = row.get("risk" if risk else "safe", {})
	state.event_reward += int(choice.get("reward", 0))
	state.event_pressure += float(choice.get("pressure", 0))
	state.player.hp = maxf(0, state.player.hp - float(choice.get("damage", 0)))
	if state.player.hp <= 0:
		state.objective.player_alive = false
		Mission.advance(state.objective, mission, 0.0, player_world_position(), [], [], pos(state.objective))
		_finish(false, state.objective.reason)
	state.statistics.events_taken += 1
	state.statistics["risk_choices" if risk else "safe_choices"] += 1
	state.event_done = true
	state.event_id = ""
	return true

func _advance_objective(delta: float) -> void:
	var o: Dictionary = state.objective
	o.player_alive = state.player.hp > 0
	if str(mission.kind) == "ESCORT" and int(o.waypoint) < mission.target_positions.size():
		if player_world_position().distance_to(pos(o)) <= float(mission.escort_radius):
			set_pos(o, pos(o).move_toward(target_position(int(o.waypoint)), float(mission.escort_speed) * delta))
	var enemy_positions: Array = []
	for e in state.entities:
		if e.hp > 0: enemy_positions.append(pos(e))
	Mission.advance(o, mission, delta, player_world_position(), enemy_positions, state.target_deaths, pos(o))
	state.event_clock += delta
	if state.event_clock >= float(tuning.get("hazard_interval", 7)):
		state.event_clock = 0.0
		Combat.environment_pattern(self)

func _finish(won: bool, reason: String) -> void:
	state.finished = true
	state.victory = won
	state.reason = reason
	state.offered.clear()
	state.event_id = ""
	sound("win" if won else "lose")

## World bounds are catalog-driven; obstacles apply only to actors, never mission boats.
func half_size() -> Vector2:
	var half: Array = tuning.get("arena_half_size", [960, 640])
	return Vector2(half[0], half[1])

## Resolves actor-circle penetration without engine physics ownership.
func constrain(point: Vector2, radius: float) -> Vector2:
	var half := half_size()
	var q := point.clamp(-half + Vector2.ONE * radius, half - Vector2.ONE * radius)
	for rock in state.obstacles:
		var offset := q - pos(rock)
		var separation := radius + float(rock.radius)
		if offset.length_squared() < separation * separation:
			q = pos(rock) + (offset.normalized() if offset.length_squared() > 0.01 else Vector2.RIGHT) * separation
	return q.clamp(-half + Vector2.ONE * radius, half - Vector2.ONE * radius)

## Converts mission target ordinal to its fixed position.
func target_position(index: int) -> Vector2:
	var points: Array = mission.get("target_positions", [])
	if points.is_empty():
		return Vector2(half_size().x * 0.65, 0)
	var q: Array = points[mini(index, points.size() - 1)]
	return Vector2(q[0], q[1])

## Writes primitive coordinates only; Vector2 never enters persisted state.
static func set_pos(entity: Dictionary, point: Vector2) -> void:
	entity.x = point.x
	entity.y = point.y

## Deterministic perimeter spawn, away from the player's immediate footprint.
func spawn_position() -> Vector2:
	var angle := rng.randf() * TAU
	var half := half_size()
	return Vector2(cos(angle) * half.x * 0.92, sin(angle) * half.y * 0.92)

## Allocates a bounded entity; target IDs remain stable independently of runtime serials.
func spawn_enemy(id: String, point: Vector2, family: String = "enemy") -> Dictionary:
	if state.entities.size() >= mini(180, int(tuning.get("enemy_cap", 180))):
		return {}
	var row: Dictionary = tables.bosses.get(id, {}) if family == "boss" else tables.elites.get(id, tables.enemies.get(id, {}))
	if row.is_empty() and family != "target":
		return {}
	var scale := float(tuning.get("difficulty_multipliers", [1.0, 1.3, 1.65])[int(loadout.get("difficulty", 0))]) * float(state.enemy_multiplier) * float(mission.get("enemy_scaling", 1.0 + int(mission.get("ordinal", 1)) * float(tuning.get("mission_enemy_scaling", 0.008))))
	var hp := float(row.get("hp", 40)) * scale
	var e := {"uid": int(state.next_id), "id": id, "family": family, "target_id": id if family == "boss" else "", "ordinal": -1,
		"x": point.x, "y": point.y, "hp": hp, "max_hp": hp, "radius": float(row.get("radius", 18)), "speed": float(row.get("speed", 75)),
		"damage": float(row.get("damage", 8)) * scale, "behavior": str(row.get("behavior", "chase")), "pattern": str(row.get("pattern", "")),
		"timer": 0.5 + rng.randf(), "age": 0.0, "phase": 0, "aim": 0.0, "vx": 0.0, "vy": 0.0, "slow": 0.0, "root": 0.0, "flash": 0.0,
		"mark": 0, "mark_timer": 0.0, "shield": 0.0, "color": str(row.get("color", "#cf6878")), "cooldown": float(row.get("attack_cooldown", row.get("cooldown", 2.4))), "range": float(row.get("range", 300))}
	if family == "boss":
		e.radius = float(row.get("radius", 48))
		sound("boss")
	if family == "target":
		e.radius = 32.0
		e.speed = 0.0
	state.next_id += 1
	state.entities.append(e)
	return e

## Damage is applied only by actual geometry intersections from combat primitives.
func damage_enemy(e: Dictionary, amount: float, control: String = "", strength: float = 1.0) -> void:
	if e.hp <= 0 or amount <= 0:
		return
	if e.family == "target" and str(mission.get("order_mode", "FIXED")).to_upper() == "FIXED" and int(e.ordinal) != int(state.objective.progress):
		return
	if e.behavior == "burrow" and int(e.phase) == 1:
		return
	var damage := amount * (0.35 if float(e.shield) > 0 else 1.0)
	if rng.randf() < clampf(modifier("critical_chance"), 0, 0.8):
		damage *= 2.0
	if float(e.root) > 0 or float(e.slow) > 0:
		damage *= 1.0 + modifier("control_damage")
	if int(e.mark) > 0:
		damage *= 1.0 + 0.08 * int(e.mark)
	e.hp -= damage
	e.flash = 0.12
	state.statistics.damage_dealt += damage
	match control:
		"slow": e.slow = maxf(float(e.slow), strength * (1 + modifier("slow_strength")))
		"root": e.root = maxf(float(e.root), strength)
		"mark":
			e.mark = mini(int(e.mark) + 1, 3 + int(modifier("mark_capacity")))
			e.mark_timer = 5.0
	sound("hit")

## Player damage has a shared invulnerability window; lethal damage cannot be healed this tick.
func damage_player(amount: float) -> void:
	if amount <= 0 or state.player.hp <= 0 or float(state.player.invulnerable) > 0:
		return
	var actual := maxf(1.0, amount - modifier("armor"))
	state.player.hp = maxf(0, state.player.hp - actual)
	state.player.invulnerable = float(tuning.get("invulnerability_seconds", 0.65))
	state.statistics.damage_taken += actual
	sound("hit")

func _reap() -> void:
	for i in range(state.entities.size() - 1, -1, -1):
		var e: Dictionary = state.entities[i]
		if e.hp > 0:
			continue
		if e.target_id != "" and not state.target_deaths.has(e.target_id):
			state.target_deaths.append(e.target_id)
		state.player.kills += 1
		if e.family == "elite":
			state.statistics.elite_kills += 1
		if e.family == "boss":
			state.statistics.boss_kills += 1
		if int(e.mark) > 0 and state.player.hp > 0:
			state.player.hp = minf(state.player.max_hp, state.player.hp + modifier("mark_heal") * float(e.mark))
			if modifier("mark_spread") > 0:
				for other in state.entities:
					if other.hp > 0 and pos(other).distance_to(pos(e)) < 120 * (1 + modifier("mark_spread")):
						other.mark = maxi(int(other.mark), 1)
		if state.pickups.size() < mini(300, int(tuning.get("pickup_cap", 300))):
			state.pickups.append({"x": e.x, "y": e.y, "xp": float(tuning.get({"boss": "boss_xp", "elite": "elite_enemy_xp", "target": "target_xp"}.get(e.family, "normal_enemy_xp"), 1.0)), "ttl": 120.0})
		else:
			state.pickups[0].xp += 1.0
		fx(pos(e), float(e.radius) * 1.6, str(e.color), "burst", 0.35)
		state.entities.remove_at(i)
		sound("kill")

func _pickups(delta: float) -> void:
	for i in range(state.pickups.size() - 1, -1, -1):
		var item: Dictionary = state.pickups[i]
		item.ttl -= delta
		if pos(item).distance_to(player_world_position()) < float(tuning.get("pickup_radius", 70)) + modifier("pickup_radius"):
			set_pos(item, pos(item).move_toward(player_world_position(), 450 * delta))
		if pos(item).distance_to(player_world_position()) < 22:
			state.player.xp += item.xp
			state.pickups.remove_at(i)
		elif item.ttl <= 0:
			state.pickups.remove_at(i)

## Deduplicated bounded audio receipts, cleared by the root after consumption.
func sound(id: String) -> void:
	if not sound_events.has(id) and sound_events.size() < 8:
		sound_events.append(id)

## Bounded visual-only effects, persisted so resume preserves telegraph appearance.
func fx(point: Vector2, radius: float, color: String, kind: String = "ring", duration: float = 0.22, angle: float = 0.0) -> void:
	if state.effects.size() < 128:
		state.effects.append({"x": point.x, "y": point.y, "radius": radius, "color": color, "kind": kind, "ttl": duration, "duration": duration, "angle": angle})

## Consumes a persisted reroll charge and advances the same RNG stream as all draft draws.
func reroll_upgrades() -> bool:
	if not ready_for_play or state.finished or state.offered.is_empty() or int(state.rerolls) <= 0:
		return false
	state.rerolls -= 1
	_offer()
	return true

func _draw() -> void:
	if ready_for_play: Rendering.draw_arena(self)
