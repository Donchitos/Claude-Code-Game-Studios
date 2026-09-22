extends RefCounted
## Existing 16-direction QA bot, extracted without changing its scoring.
const Arena = preload("res://src/campaign/campaign_arena.gd")
static func choice(a, c: Dictionary) -> String:
	var best := str(a.state.offered[0])
	var score := -INF
	for id in a.state.offered:
		var candidate := 0.0
		if a.state.skills.has(id):
			candidate = 80.0 + int(a.state.skills[id]) * 3.0
		for skill in c.skills:
			if skill.id == id and not a.state.skills.has(id):
				candidate = 35.0 if skill.mode in ["sword", "fan", "chain", "frost", "roots"] else 20.0
		for passive in c.passives:
			if passive.id == id:
				candidate = float({"damage": 60, "cooldown_reduction": 65, "area": 40, "max_hp": 35, "armor": 45, "pickup_radius": 48, "move_speed": 30}.get(passive.stat, 12))
		for recipe in c.evolutions:
			if recipe.id == id:
				candidate = 100.0
		if "--qa-production-evolution" in OS.get_cmdline_user_args():
			if id in ["S1-A01", "S1-P01"]:
				candidate = 95.0
		if candidate > score:
			score = candidate
			best = id
	return best

static func direction(a, m: Dictionary, tick_value: int) -> Vector2:
	var player: Vector2 = a.player_world_position()
	var target := Vector2.ZERO
	var kind := str(m.kind)
	if kind == "SURVIVE":
		if float(a.state.elapsed) < float(m.target_seconds) + 0.05:
			target = Vector2(cos(tick_value * 0.002), sin(tick_value * 0.002)) * 280.0
			var nearest := 600.0
			for pickup in a.state.pickups:
				var distance := player.distance_to(Arena.pos(pickup))
				if distance < nearest:
					nearest = distance
					target = Arena.pos(pickup)
		else:
			target = Vector2(m.target_positions[0][0], m.target_positions[0][1])
	elif kind == "ESCORT":
		target = Arena.pos(a.state.objective)
	elif kind == "CLEANSE":
		var index := mini(int(a.state.objective.get("waypoint", 0)), m.target_positions.size() - 1)
		target = Vector2(m.target_positions[index][0], m.target_positions[index][1])
	else:
		var index := mini(int(a.state.objective.get("progress", 0)), m.target_positions.size() - 1)
		target = Vector2(m.target_positions[index][0], m.target_positions[index][1])
		for entity in a.state.entities:
			if str(entity.get("target_id", "")) != "":
				if kind == "BREAK" and m.order_mode == "FIXED" and int(entity.ordinal) != index:
					continue
				target = Arena.pos(entity)
				break
		# Fight at melee-sector/ranged reach instead of colliding with the boss.
		var away := player - target
		if away.length() < 230.0:
			target += (away.normalized() if away.length() > 0 else Vector2.LEFT) * 250.0
	var speed: float = float(a.tuning.get("player_speed", 280)) * float(a.tables.characters[a.loadout.character_id].get("speed_multiplier", 1)) * (1.0 + a.modifier("move_speed"))
	var best_direction := Vector2.ZERO
	var best_score := -INF
	for candidate_index in 17:
		var direction := Vector2.from_angle(TAU * candidate_index / 16.0) if candidate_index < 16 else Vector2.ZERO
		var predicted: Vector2 = player + direction * speed * 0.5
		var score: float = (player.distance_to(target) - predicted.distance_to(target)) / 50.0
		var half: Vector2 = a.half_size()
		if absf(predicted.x) > half.x - 24 or absf(predicted.y) > half.y - 24:
			score -= 1000.0
		for rock in a.state.obstacles:
			var distance := _segment_distance(Arena.pos(rock), player, predicted)
			if distance < float(rock.radius) + 22.0:
				score -= 1000.0 + float(rock.radius) + 22.0 - distance
		for entity in a.state.entities:
			if entity.get("family") == "target":
				continue
			var location := Arena.pos(entity)
			var future_enemy := location + location.direction_to(player) * float(entity.speed) * 0.5
			var margin := float(entity.radius) + 18.0
			var endpoint_distance: float = predicted.distance_to(future_enemy)
			var swept_distance := _segment_distance(location, player, predicted)
			if endpoint_distance < margin + 90.0:
				score -= pow(maxf(0, margin + 90.0 - endpoint_distance) / 30.0, 2) * 5.0
			if swept_distance < margin and predicted.distance_to(location) < player.distance_to(location):
				score -= 400.0
		for projectile in a.state.projectiles:
			if not projectile.get("hostile", false):
				continue
			var q := Arena.pos(projectile)
			var velocity := Vector2(float(projectile.vx), float(projectile.vy))
			# Relative swept path predicts interception with the moving player.
			var relative_future: Vector2 = q + velocity * 0.5 - (predicted - player)
			var distance := _segment_distance(player, q, relative_future)
			var margin := float(projectile.radius) + 28.0
			if distance < margin:
				score -= 200.0 + (margin - distance) * 5.0
		for zone in a.state.zones:
			if not zone.get("hostile", false) or float(zone.get("delay", 0)) > 0.65:
				continue
			var q := Arena.pos(zone)
			var distance: float = predicted.distance_to(q)
			var margin := float(zone.radius) + 25.0
			if zone.kind in ["line", "ink", "flame"]:
				distance = _segment_distance(predicted, q, q + Vector2.from_angle(float(zone.angle)) * float(zone.length))
			elif zone.kind == "ring":
				distance = absf(distance - float(zone.radius))
				margin = 50.0
			if distance < margin:
				score -= 180.0 + (margin - distance) * 3.0
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

static func _segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var edge := end - start
	if edge.length_squared() <= 0.0001:
		return point.distance_to(start)
	return point.distance_to(start + edge * clampf((point - start).dot(edge) / edge.length_squared(), 0.0, 1.0))
