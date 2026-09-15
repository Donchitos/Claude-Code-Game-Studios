class_name CampaignCombat
extends RefCounted
## Deterministic combat primitives and pattern execution for CampaignArena.
## Executes the 24 catalog modes; every timer and delayed attack is in arena.state.
static func advance_skills(a, dt: float) -> void:
	var skill_ids: Array = a.state.skills.keys()
	skill_ids.sort()
	for id in skill_ids:
		var remaining := float(a.state.cooldowns.get(id, 0)) - dt
		a.state.cooldowns[id] = remaining
		if remaining > 0:
			continue
		var row: Dictionary = a.tables.skills[id]
		var rank := int(a.state.skills[id])
		var cooldown := maxf(float(a.tuning.get("cooldown_floor", 0.2)), float(row.get("cooldown", 1.0)) * (1.0 - clampf(a.modifier("cooldown_reduction"), 0, 0.75)))
		if str(row.mode) in ["sword", "stomp", "lightning"]: cooldown /= 1.0 + a.modifier("charge_speed")
		a.state.cooldowns[id] = cooldown
		var damage: float = float(row.get("damage", 12)) * (1 + (rank - 1) * 0.24) * (1 + a.modifier("damage")) * float(a.tables.characters[a.loadout.character_id].get("damage_multiplier", 1))
		var reach: float = float(row.get("range", 300)) * (1 + a.modifier("area"))
		var radius: float = float(row.get("radius", 24)) * (1 + a.modifier("area"))
		var count := maxi(1, int(row.get("count", 1)) + (rank - 1) / 2)
		var duration: float = float(row.get("duration", 2.0)) * (1 + a.modifier("duration"))
		var speed: float = float(row.get("speed", 450)) * (1 + a.modifier("projectile_speed"))
		for evolved_id in a.state.evolved:
			var recipe: Dictionary = a.tables.evolutions[evolved_id]
			if recipe.skill_id == id:
				var factor := float(recipe.get("effect_multiplier", 1.6))
				damage *= factor
				reach *= factor
				count = mini(16, maxi(count + 1, int(count * factor)))
		var origin: Vector2 = a.player_world_position()
		var target := nearest(a, origin, reach * 2)
		var aim: Vector2 = (a.pos(target) - origin).normalized() if not target.is_empty() else Vector2.from_angle(float(a.state.player.facing))
		var mode := str(row.mode)
		var color := str(row.get("color", "#6ae8ed"))
		if not a.state.statistics.skills_used.has(id):
			a.state.statistics.skills_used.append(id)
		a.sound("shot")
		match mode:
			"sword":
				for i in count:
					projectile(a, origin + aim.orthogonal() * (i - (count - 1) * 0.5) * 12, aim * speed, damage, 6, reach / maxf(1, speed), color, "pierce", 2 + rank)
			"fan":
				for i in count + 2:
					projectile(a, origin, aim.rotated((float(i) - (count + 1) * 0.5) * 0.16) * speed, damage, radius, reach / maxf(1, speed), color, "pierce", 2)
			"orbit":
				for i in count:
					var z := zone(a, origin, radius, damage, duration, color, "orbit", false, 0)
					z.orbit_radius = minf(reach, 110 + rank * 12)
					z.angle = float(i) * TAU / count
			"fireball":
				for i in count:
					projectile(a, origin, aim.rotated((i - (count - 1) * 0.5) * 0.16) * speed, damage, maxf(8, radius * 0.2), reach / maxf(speed, 1), color, "explode", 1, radius * (1 + a.modifier("explosion_radius")))
			"flame":
				var z := zone(a, origin, radius, damage * 0.25 * count, duration, color, "flame", false, 0)
				z.angle = aim.angle()
				z.length = reach
			"meteor":
				for i in count:
					var impact: Vector2 = a.pos(target) if i == 0 and not target.is_empty() else origin + aim.rotated(a.rng.randf_range(-0.7, 0.7)) * a.rng.randf_range(80, reach)
					zone(a, impact, radius, damage * 2.0, 0.15, color, "blast", false, 0.65)
			"disc":
				for i in count:
					projectile(a, origin, aim.rotated(i * TAU / count) * speed, damage * 0.6, maxf(10, radius), duration, color, "disc", 12)
			"boomerang":
				for i in count:
					projectile(a, origin, aim.rotated((i - (count - 1) * 0.5) * 0.3) * speed, damage, maxf(10, radius), duration, color, "return", 16)
			"shield":
				zone(a, origin, radius + 32, damage, duration, color, "shield", false, 0)
			"turret":
				for i in count:
					zone(a, origin + aim.rotated(i * TAU / count) * 60, radius, damage * (1 + a.modifier("summon_damage")), duration * (1 + a.modifier("summon_duration")), color, "turret", false, 0)
			"drone":
				for i in count:
					var z := zone(a, origin, radius, damage * (1 + a.modifier("summon_damage")), duration * (1 + a.modifier("summon_duration")), color, "drone", false, 0)
					z.angle = float(i) * TAU / count
			"stomp":
				area(a, origin, reach, damage, color, "", 0, 65)
				for i in range(1, count): zone(a, origin, reach * (1 + i * 0.15), damage * 0.5, 0.1, color, "blast", false, i * 0.2)
			"chain":
				var hit: Array = []
				var q := origin
				for i in count + 2 + int(a.modifier("chain_count")):
					var e := nearest(a, q, reach, hit)
					if e.is_empty(): break
					a.fx(q, q.distance_to(a.pos(e)), color, "beam", 0.18, (a.pos(e) - q).angle())
					a.damage_enemy(e, damage * pow(0.85, i))
					hit.append(int(e.uid))
					q = a.pos(e)
			"lightning":
				var hit: Array = []
				for i in count + 1:
					var e := nearest(a, origin, reach, hit)
					if e.is_empty(): break
					zone(a, a.pos(e), radius, damage, 0.12, color, "lightning", false, 0.28)
					hit.append(int(e.uid))
			"return_arc":
				for i in count + 1:
					projectile(a, origin, aim.rotated((i - count * 0.5) * 0.3) * speed, damage * (1 + a.modifier("return_damage")), radius, duration, color, "arc", 16)
			"roots":
				for i in count:
					zone(a, (a.pos(target) if not target.is_empty() else origin + aim * 80) + aim.orthogonal() * (i - (count - 1) * 0.5) * radius, radius, damage * 0.4, duration, color, "roots", false, 0.25)
			"thorns":
				sector(a, origin, aim.angle(), reach, 0.65, damage, color)
			"spores":
				for i in count:
					zone(a, origin + aim.rotated(float(i) * 0.6) * minf(reach, 140), radius, damage * 0.4, duration, color, "spores", false, 0.4)
			"ice_arrow":
				for i in count:
					projectile(a, origin, aim.rotated((i - (count - 1) * 0.5) * 0.12) * speed, damage, 7, reach / maxf(1, speed), color, "ice", 3)
			"frost":
				for i in 6 + count:
					projectile(a, origin, Vector2.from_angle(TAU * i / (6 + count)) * speed, damage, 6, reach / maxf(1, speed), color, "ice", 1 + int(a.modifier("reflect_count")))
			"winter":
				zone(a, origin, radius * (1 + a.modifier("trail_width")), damage * 0.25, duration, color, "winter", false, 0)
			"ink":
				for i in count:
					projectile(a, origin, aim.rotated((i - (count - 1) * 0.5) * 0.18) * speed, damage * 0.5, 10, reach / maxf(1, speed), color, "mark", 1)
			"seal":
				for i in count:
					zone(a, (a.pos(target) if not target.is_empty() else origin + aim * 80) + aim.orthogonal() * (i - (count - 1) * 0.5) * radius, radius, damage * 0.35, duration, color, "seal", false, 0.45)
			"void":
				for i in count:
					projectile(a, origin + aim.orthogonal() * (i - (count - 1) * 0.5) * 16, aim * speed, damage, 4, reach / maxf(1, speed), color, "pierce", 16)

## Stable nearest target selection excludes inactive break anchors and already visited IDs.
static func nearest(a, origin: Vector2, distance: float, excluded: Array = []) -> Dictionary:
	var found: Dictionary = {}
	var best := distance * distance
	for e in a.state.entities:
		if e.hp <= 0 or excluded.has(int(e.uid)):
			continue
		if e.family == "target" and str(a.mission.get("order_mode", "FIXED")).to_upper() == "FIXED" and int(e.ordinal) != int(a.state.objective.get("progress", 0)):
			continue
		var d := origin.distance_squared_to(a.pos(e))
		if d < best:
			best = d
			found = e
	return found

## Sector melee uses angle and distance; actors behind the blade remain unharmed.
static func sector(a, origin: Vector2, angle: float, reach: float, half_angle: float, damage: float, color: String, hostile: bool = false) -> void:
	a.fx(origin, reach, color, "slash", 0.24, angle)
	if hostile:
		var v: Vector2 = a.player_world_position() - origin
		if v.length() < reach + 16 and absf(wrapf(v.angle() - angle, -PI, PI)) < half_angle:
			a.damage_player(damage)
		return
	for e in a.state.entities:
		var v: Vector2 = a.pos(e) - origin
		if v.length() <= reach + e.radius and absf(wrapf(v.angle() - angle, -PI, PI)) <= half_angle:
			a.damage_enemy(e, damage)

## Circle impact with optional control and knockback.
static func area(a, origin: Vector2, radius: float, damage: float, color: String, control: String = "", strength: float = 0, knockback: float = 0) -> void:
	a.fx(origin, radius, color, "ring", 0.3)
	for e in a.state.entities:
		if a.pos(e).distance_to(origin) <= radius + e.radius:
			a.damage_enemy(e, damage, control, strength)
			if knockback > 0 and e.family != "target":
				a.set_pos(e, a.constrain(a.pos(e) + (a.pos(e) - origin).normalized() * knockback, e.radius))

## Bounded projectile record, including hit history to prevent repeat pierce damage.
static func projectile(a, origin: Vector2, velocity: Vector2, damage: float, radius: float, ttl: float, color: String, mode: String = "straight", pierce: int = 1, explosion: float = 0, hostile: bool = false) -> Dictionary:
	if a.state.projectiles.size() >= mini(400, int(a.tuning.get("projectile_cap", 400))):
		return {}
	var p := {"x": origin.x, "y": origin.y, "vx": velocity.x, "vy": velocity.y, "damage": damage, "radius": radius, "ttl": maxf(0.1, ttl), "duration": maxf(0.1, ttl), "color": color, "mode": mode, "pierce": pierce, "explosion": explosion, "hostile": hostile, "age": 0.0, "hits": [], "returning": false}
	a.state.projectiles.append(p)
	return p

## Bounded delayed/persistent work shares serializable records with its warning geometry.
static func zone(a, origin: Vector2, radius: float, damage: float, duration: float, color: String, kind: String, hostile: bool, delay: float) -> Dictionary:
	if a.state.zones.size() >= 128:
		return {}
	var z := {"x": origin.x, "y": origin.y, "radius": maxf(4, radius), "damage": damage, "ttl": maxf(0.1, duration), "duration": maxf(0.1, duration), "color": color, "kind": kind, "hostile": hostile, "delay": delay, "pulse": 0.0, "angle": 0.0, "length": radius, "orbit_radius": 80.0, "age": 0.0}
	a.state.zones.append(z)
	return z

## Swept circle-segment collision prevents high-speed tunneling.
static func segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var v := end - start
	var t := clampf((point - start).dot(v) / maxf(v.length_squared(), 0.0001), 0, 1)
	return point.distance_to(start + v * t)

## Advances projectiles deterministically, testing collisions along the entire traveled segment.
static func advance_projectiles(a, dt: float) -> void:
	var grid := _enemy_grid(a)
	for i in range(a.state.projectiles.size() - 1, -1, -1):
		var p: Dictionary = a.state.projectiles[i]
		if p.ttl <= 0:
			a.state.projectiles.remove_at(i)
			continue
		var start: Vector2 = a.pos(p)
		p.age += dt
		p.ttl -= dt
		var velocity := Vector2(p.vx, p.vy)
		if p.mode in ["return", "arc"] and p.age >= p.duration * 0.45:
			if not p.returning:
				p.returning = true
				p.hits.clear()
			velocity = (a.player_world_position() - start).normalized() * maxf(240, velocity.length())
			if start.distance_to(a.player_world_position()) < 18:
				p.ttl = 0
		elif p.mode == "arc":
			velocity = velocity.rotated(dt * 1.4)
		elif p.mode == "disc":
			velocity = velocity.rotated(dt * 0.75)
		p.vx = velocity.x
		p.vy = velocity.y
		var end := start + velocity * dt
		a.set_pos(p, end)
		if p.hostile:
			if segment_distance(a.player_world_position(), start, end) <= p.radius + 16:
				a.damage_player(p.damage)
				p.ttl = 0
			if str(a.mission.kind).to_upper() == "ESCORT" and segment_distance(a.pos(a.state.objective), start, end) < p.radius + 24:
				a.state.objective.escort_hp = maxf(0, a.state.objective.escort_hp - p.damage)
				p.ttl = 0
		else:
			# Sort intersections by segment parameter, not mutable entity insertion order.
			var hits: Array = []
			for e in _swept_candidates(grid, start, end, float(p.radius)):
				if e.hp > 0 and not p.hits.has(int(e.uid)) and segment_distance(a.pos(e), start, end) <= p.radius + e.radius:
					hits.append(e)
			hits.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
				var dx := start.distance_squared_to(a.pos(x))
				var dy := start.distance_squared_to(a.pos(y))
				return dx < dy or (dx == dy and int(x.uid) < int(y.uid)))
			for e in hits:
				if e.behavior == "reflector" and float(e.shield) > 0:
					p.hostile = true
					p.vx *= -1
					p.vy *= -1
					break
				var control := "slow" if p.mode == "ice" else ("mark" if p.mode == "mark" else "")
				a.damage_enemy(e, p.damage, control, 2.0)
				p.hits.append(int(e.uid))
				p.pierce -= 1
				if p.mode == "explode":
					area(a, a.pos(e), p.explosion, p.damage * 0.7, p.color)
				if p.pierce <= 0:
					p.ttl = 0
					break
		if absf(end.x) > a.half_size().x + 100 or absf(end.y) > a.half_size().y + 100:
			p.ttl = 0
		if p.ttl <= 0:
			a.state.projectiles.remove_at(i)

## Persistent skills: summons fire; orbit/shield follow; roots freeze; void pulls; ink marks.
static func advance_zones(a, dt: float) -> void:
	for i in range(a.state.zones.size() - 1, -1, -1):
		var z: Dictionary = a.state.zones[i]
		z.age += dt
		if z.delay > 0:
			z.delay -= dt
			continue
		z.ttl -= dt
		var kind := str(z.kind)
		if kind in ["shield", "thorns"]:
			a.set_pos(z, a.player_world_position())
		elif kind in ["orbit", "drone"]:
			z.angle += dt * (3.5 if kind == "orbit" else 1.6)
			a.set_pos(z, a.player_world_position() + Vector2.from_angle(z.angle) * z.orbit_radius)
		if kind == "void":
			for e in a.state.entities:
				if e.family != "target" and a.pos(e).distance_to(a.pos(z)) < z.radius * 1.4:
					a.set_pos(e, a.pos(e).move_toward(a.pos(z), 90 * dt))
		if kind == "shield":
			var reflected := 0
			for p in a.state.projectiles:
				if p.hostile and a.pos(p).distance_to(a.pos(z)) < z.radius:
					if reflected < 1 + int(a.modifier("reflect_count")):
						p.hostile = false
						p.vx *= -1
						p.vy *= -1
						reflected += 1
					else:
						p.ttl = 0
		z.pulse -= dt
		if z.pulse <= 0:
			z.pulse += 0.35
			if kind in ["turret", "drone"]:
				var e := nearest(a, a.pos(z), 450 + a.modifier("summon_range"))
				if not e.is_empty():
					projectile(a, a.pos(z), (a.pos(e) - a.pos(z)).normalized() * 550, z.damage, 6, 1.2, z.color)
			elif z.hostile:
				var hit := _zone_contains(a.player_world_position(), z, 16)
				if hit:
					a.damage_player(z.damage)
				if str(a.mission.kind).to_upper() == "ESCORT" and _zone_contains(a.pos(a.state.objective), z, 24):
					a.state.objective.escort_hp = maxf(0, a.state.objective.escort_hp - z.damage)
			else:
				for e in a.state.entities:
					if _zone_contains(a.pos(e), z, e.radius):
						var control := "root" if kind == "roots" else ("slow" if kind in ["winter", "spores"] else ("mark" if kind in ["ink", "seal"] else ""))
						a.damage_enemy(e, z.damage, control, 0.75)
				if kind in ["blast", "lightning"]:
					a.fx(a.pos(z), z.radius, z.color, "burst", 0.35)
		if z.ttl <= 0:
			a.state.zones.remove_at(i)

static func _zone_contains(point: Vector2, z: Dictionary, radius: float) -> bool:
	var center := Vector2(z.x, z.y)
	if z.kind == "flame":
		var offset := point - center
		return offset.length() <= z.length + radius and absf(wrapf(offset.angle() - z.angle, -PI, PI)) < 0.65
	if z.kind in ["line", "ink"]:
		return segment_distance(point, center, center + Vector2.from_angle(z.angle) * z.length) <= z.radius + radius
	if z.kind == "ring":
		return absf(point.distance_to(center) - z.radius) <= 22 + radius
	return point.distance_to(center) <= z.radius + radius
## 24 distinct stateful AI behaviors; contact, volleys, channels and tells share bounded primitives.
static func advance_enemies(a, dt: float) -> void:
	# Capture population length: summons cannot recursively advance in their birth tick.
	var population: int = a.state.entities.size()
	for index in population:
		var e: Dictionary = a.state.entities[index]
		if e.hp <= 0 or e.family == "target": continue
		e.age += dt
		e.timer -= dt
		e.root = maxf(0, e.root - dt)
		e.slow = maxf(0, e.slow - dt)
		e.flash = maxf(0, e.flash - dt)
		e.shield = maxf(0, e.shield - dt)
		e.mark_timer = maxf(0, e.mark_timer - dt)
		if e.mark_timer == 0: e.mark = 0
		var q: Vector2 = a.pos(e)
		var target: Vector2 = a.player_world_position()
		if str(a.mission.kind).to_upper() == "ESCORT" and index % 3 == 0:
			target = a.pos(a.state.objective)
		var offset := target - q
		var direction := offset.normalized()
		var velocity: Vector2 = direction * e.speed
		var distance := offset.length()
		var behavior := str(e.behavior)
		if e.family == "boss":
			_boss(a, e, target)
			q = a.pos(e)
			velocity *= 0.4
		else:
			match behavior:
				"chase": pass
				"spitter":
					velocity *= clampf((distance - 230) / 80, -1, 1)
					if e.timer <= 0: _volley(a, e, direction, 1, 0)
				"flanker": velocity = direction.rotated(0.9 if int(e.uid) % 2 else -0.9) * e.speed * 1.3
				"trail":
					velocity = direction.rotated(sin(e.age * 1.5) * 1.2) * e.speed
					if e.timer <= 0:
						zone(a, q, 26, e.damage * 0.5, 4, e.color, "poison", true, 0.35)
						e.timer = e.cooldown * 0.5
				"strafe":
					velocity = direction.rotated(PI * 0.5) * e.speed + direction * (distance - 240) * 0.4
					if e.timer <= 0: _volley(a, e, direction, 2, 0.16)
				"charger":
					velocity = _charge(a, e, direction, 3.8, 0.65)
				"crab":
					velocity = Vector2(signf(offset.x), 0) * e.speed if int(e.age * 1.4) % 2 == 0 else Vector2(0, signf(offset.y)) * e.speed
				"jet":
					velocity = _charge(a, e, direction.rotated(0.3), 5.2, 0.35)
					if int(e.phase) == 2:
						a.fx(q, 12, e.color, "burst", 0.1)
				"burrow":
					if e.timer <= 0:
						e.phase = (int(e.phase) + 1) % 2
						e.timer = 1.6
						if e.phase == 0: zone(a, q, 70, e.damage, 0.15, e.color, "blast", true, 0.45)
					velocity *= 1.8 if e.phase == 1 else 0.5
				"reflector":
					velocity *= 0.45
					if e.timer <= 0:
						e.shield = 1.0
						e.timer = e.cooldown
				"fan_shooter":
					velocity *= 0.4
					if e.timer <= 0: _volley(a, e, direction, 5, 0.24)
				"bouncer":
					if Vector2(e.vx, e.vy).length_squared() < 1:
						e.vx = direction.x * e.speed * 1.8
						e.vy = direction.y * e.speed * 1.8
					if absf(q.x) >= a.half_size().x - e.radius - 5: e.vx *= -1
					if absf(q.y) >= a.half_size().y - e.radius - 5: e.vy *= -1
					velocity = Vector2(e.vx, e.vy)
				"slider": velocity = direction * e.speed + Vector2.from_angle(e.age * 3) * e.speed * 0.8
				"buffer":
					velocity *= 0.35
					if e.timer <= 0:
						for other in a.state.entities:
							if a.pos(other).distance_to(q) < 170 and other.family != "target": other.shield = 1.8
						a.fx(q, 170, e.color, "ring", 0.5)
						e.timer = e.cooldown
				"spike_line":
					velocity *= 0.6
					if e.timer <= 0:
						for n in 5: zone(a, q + direction * (60 + n * 55), 25, e.damage, 0.2, e.color, "blast", true, 0.5 + n * 0.13)
						e.timer = e.cooldown
				"exploder":
					velocity *= 1.4
					if distance < 110 and int(e.phase) == 0:
						e.phase = 1
						e.timer = 0.9
						zone(a, q, 105, e.damage * 2, 0.2, e.color, "blast", true, 0.8)
					if e.phase == 1:
						velocity = Vector2.ZERO
						if e.timer <= 0: e.hp = 0
				"rooter":
					velocity *= clampf((distance - 180) / 100, -0.5, 1)
					if e.timer <= 0:
						zone(a, target, 65, e.damage, 2, e.color, "roots", true, 0.85)
						e.timer = e.cooldown
				"decoy":
					velocity *= -0.7 if distance < 160 else 0.6
					if e.timer <= 0:
						zone(a, q, 80, e.damage, 0.2, e.color, "blast", true, 1.2)
						a.set_pos(e, a.constrain(q + direction.orthogonal() * 140, e.radius))
						q = a.pos(e)
						e.timer = e.cooldown
				"diver":
					velocity = _charge(a, e, direction, 4.5, 1.0)
					if e.phase == 2 and e.timer < 0.1: zone(a, q, 65, e.damage, 0.2, e.color, "blast", true, 0.25)
				"anchor":
					velocity = Vector2.ZERO
					if e.timer <= 0:
						zone(a, q, 170, e.damage, 0.4, e.color, "ring", true, 0.8)
						e.timer = e.cooldown
				"barrier":
					velocity *= 0.3
					if e.timer <= 0:
						var z := zone(a, q, 18, e.damage, 2.5, e.color, "line", true, 0.7)
						z.angle = direction.angle() + PI / 2
						z.length = 200
						e.timer = e.cooldown
				"shield":
					e.shield = 0.2 if cos(direction.angle() - float(e.aim)) > 0.5 else 0.0
					e.aim = move_toward(float(e.aim), direction.angle(), dt * 0.5)
					velocity *= 0.65
				"channeler":
					velocity = Vector2.ZERO
					if e.timer <= 0:
						var z := zone(a, q, 20, e.damage, 1.2, e.color, "line", true, 1)
						z.angle = direction.angle()
						z.length = e.range
						e.timer = e.cooldown + 1
				"absorber":
					velocity *= 0.55
					if e.timer <= 0:
						for item in a.state.pickups:
							if a.pos(item).distance_to(q) < 110:
								e.hp = minf(e.max_hp, e.hp + item.xp * 2)
								item.ttl = 0
						zone(a, q, 100, e.damage * 0.5, 0.3, e.color, "ring", true, 0.4)
						e.timer = e.cooldown
		if e.root > 0: velocity = Vector2.ZERO
		elif e.slow > 0: velocity *= 0.45
		a.set_pos(e, a.constrain(q + velocity * dt, e.radius))
		if a.pos(e).distance_to(a.player_world_position()) < e.radius + 16 and not (behavior == "burrow" and e.phase == 1):
			a.damage_player(e.damage)
		if str(a.mission.kind).to_upper() == "ESCORT" and a.pos(e).distance_to(a.pos(a.state.objective)) < e.radius + 24:
			a.state.objective.escort_hp = maxf(0, a.state.objective.escort_hp - e.damage * dt)

static func _volley(a, e: Dictionary, direction: Vector2, count: int, spread: float) -> void:
	e.timer = e.cooldown
	for i in count:
		projectile(a, a.pos(e), direction.rotated((i - (count - 1) * 0.5) * spread) * 230, e.damage, 7, 4, e.color, "straight", 1, 0, true)
	a.fx(a.pos(e), 25, e.color, "burst", 0.2)

static func _charge(a, e: Dictionary, direction: Vector2, multiplier: float, tell: float) -> Vector2:
	if e.timer <= 0:
		match int(e.phase):
			0:
				e.phase = 1
				e.aim = direction.angle()
				e.timer = tell
				var z := zone(a, a.pos(e), 5, 0, 0.05, e.color, "line", true, tell)
				z.angle = e.aim
				z.length = e.speed * multiplier * 0.6
			1:
				e.phase = 2
				e.timer = 0.6
			2:
				e.phase = 0
				e.timer = e.cooldown
	if e.phase == 1: return Vector2.ZERO
	if e.phase == 2: return Vector2.from_angle(e.aim) * e.speed * multiplier
	return direction * e.speed * 0.7

static func _boss(a, e: Dictionary, target: Vector2) -> void:
	if e.timer > 0: return
	var row: Dictionary = a.tables.bosses.get(e.id, {})
	var phase := mini(2, int((1.0 - maxf(0, e.hp) / e.max_hp) * 3.0))
	e.phase = phase
	var patterns: Array = row.get("phase_patterns", [e.pattern, e.pattern, e.pattern])
	var pattern := str(patterns[mini(phase, patterns.size() - 1)])
	e.timer = maxf(1.0, float(row.get("attack_cooldown", 3.2)) * (1.0 - phase * 0.18))
	var q: Vector2 = a.pos(e)
	var aim := (target - q).normalized()
	var color := str(e.color)
	match pattern:
		"pounce":
			zone(a, target, 95 + phase * 15, e.damage * 1.5, 0.2, color, "blast", true, 0.9)
			var z := zone(a, q, 24, e.damage, 0.2, color, "line", true, 0.7)
			z.angle = aim.angle()
			z.length = q.distance_to(target)
			a.set_pos(e, a.constrain(q.move_toward(target, 160), e.radius))
		"eruption":
			for i in 5 + phase * 2:
				var point := target + Vector2.from_angle(TAU * i / (5 + phase * 2)) * (70 + phase * 35)
				zone(a, point, 65, e.damage, 0.3, color, "blast", true, 0.65 + i * 0.15)
		"cross_tide":
			for i in 4:
				var z := zone(a, q, 26 + phase * 5, e.damage, 0.6, color, "line", true, 0.9)
				z.angle = PI * i / 2 + e.age * 0.12
				z.length = 800
		"mirror":
			e.shield = 1.2
			for i in 2 + phase:
				zone(a, target + Vector2((i - 1) * 110, 0), 65, e.damage, 0.25, color, "blast", true, 0.9)
			_volley(a, e, aim, 7, 0.2)
		"dive":
			for i in 3 + phase:
				var z := zone(a, q + aim.orthogonal() * (i - 1) * 100, 32, e.damage, 0.25, color, "line", true, 0.7 + i * 0.2)
				z.angle = aim.angle()
				z.length = 650
		"spore_tide":
			for i in 6 + phase * 2:
				zone(a, q + Vector2.from_angle(TAU * i / (6 + phase * 2) + e.age) * 220, 65, e.damage * 0.5, 4, color, "poison", true, 0.9)
		"anchors":
			for i in 3 + phase:
				var at := q + Vector2.from_angle(TAU * i / (3 + phase)) * 160
				zone(a, at, 135, e.damage, 0.5, color, "ring", true, 0.8 + i * 0.2)
			var ids: Array = a.mission.get("enemy_ids", [])
			if not ids.is_empty(): a.spawn_enemy(ids[0], a.spawn_position())
		"seals":
			for i in 4 + phase:
				var z := zone(a, target + Vector2.from_angle(TAU * i / (4 + phase)) * 180, 15, e.damage, 1.5, color, "line", true, 1.0)
				z.angle = TAU * i / (4 + phase) + PI
				z.length = 360
		"nexus":
			zone(a, q, 180 + phase * 40, e.damage, 0.4, color, "ring", true, 0.9)
			for i in 12 + phase * 4:
				projectile(a, q, Vector2.from_angle(TAU * i / (12 + phase * 4) + e.age) * 170, e.damage, 9, 5, color, "straight", 1, 0, true)

## Eight theme hazards preserve navigable safe sectors and use clear delayed warning shapes.
static func environment_pattern(a) -> void:
	var theme: Variant = a.mission.get("theme", 0)
	var themes: Array = []
	for row in a.catalog.get("missions", []):
		if not themes.has(row.theme): themes.append(row.theme)
	var index := maxi(0, themes.find(theme)) % 8
	var q: Vector2 = a.player_world_position()
	var damage: float = float(a.tuning.get("environment_damage", 8)) * float(a.state.get("hazard_multiplier", 1))
	match index:
		0: zone(a, q + Vector2(90, 0), 65, damage, 2, "#79b85c", "poison", true, 1.2)
		1:
			var z := zone(a, Vector2(-a.half_size().x, q.y), 24, damage, 0.3, "#dc9566", "line", true, 1.3)
			z.length = a.half_size().x * 2
		2: zone(a, q, 100, damage, 0.3, "#74bce8", "ring", true, 1.0)
		3:
			for i in 3: zone(a, q + Vector2((i - 1) * 130, 0), 50, damage, 0.3, "#e89c46", "blast", true, 0.9 + i * 0.3)
		4:
			var z := zone(a, q - Vector2(140, 140), 18, damage, 1.0, "#65dbd2", "line", true, 1.4)
			z.angle = PI / 4
			z.length = 400
		5: zone(a, q, 70, damage, 0.3, "#c9a4f1", "lightning", true, 1.5)
		6:
			for i in 4: zone(a, q + Vector2.from_angle(i * PI / 2) * 130, 60, damage, 1.0, "#9da1ee", "blast", true, 1.3)
		7:
			zone(a, q, 160, damage, 0.6, "#ed7898", "ring", true, 1.6)

# Transient broad phase. No index enters a snapshot, and hit sorting has a stable UID tie.
static func _enemy_grid(a) -> Dictionary:
	var grid: Dictionary = {}
	for e in a.state.entities:
		if e.hp <= 0: continue
		if e.family == "target" and a.mission.order_mode == "FIXED" and int(e.ordinal) != int(a.state.objective.progress): continue
		var min_x := int(floorf((float(e.x) - float(e.radius)) / 96.0))
		var max_x := int(floorf((float(e.x) + float(e.radius)) / 96.0))
		var min_y := int(floorf((float(e.y) - float(e.radius)) / 96.0))
		var max_y := int(floorf((float(e.y) + float(e.radius)) / 96.0))
		for x in range(min_x, max_x + 1):
			for y in range(min_y, max_y + 1):
				var cell := Vector2i(x, y)
				if not grid.has(cell): grid[cell] = []
				grid[cell].append(e)
	return grid

static func _swept_candidates(grid: Dictionary, start: Vector2, end: Vector2, radius: float) -> Array:
	var candidates: Array = []
	var seen: Dictionary = {}
	var minimum := start.min(end) - Vector2.ONE * radius
	var maximum := start.max(end) + Vector2.ONE * radius
	for x in range(int(floorf(minimum.x / 96.0)), int(floorf(maximum.x / 96.0)) + 1):
		for y in range(int(floorf(minimum.y / 96.0)), int(floorf(maximum.y / 96.0)) + 1):
			for e in grid.get(Vector2i(x,y), []):
				if not seen.has(int(e.uid)):
					seen[int(e.uid)] = true
					candidates.append(e)
	return candidates
