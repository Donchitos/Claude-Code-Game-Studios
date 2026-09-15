extends RefCounted
## World-space procedural campaign presentation. No font glyphs substitute for combat actors.

## Draws themed terrain, objectives, tells, actors and hit effects under the root camera.
static func draw_arena(a) -> void:
	var half: Vector2 = a.half_size()
	var theme := _theme(a)
	var ground := theme.darkened(0.83)
	a.draw_rect(Rect2(-half, half * 2), ground)
	for x in range(-int(half.x), int(half.x), 80):
		a.draw_line(Vector2(x, -half.y), Vector2(x, half.y), Color(theme, 0.07), 1)
	for y in range(-int(half.y), int(half.y), 80):
		a.draw_line(Vector2(-half.x, y), Vector2(half.x, y), Color(theme, 0.07), 1)
	var scene := int(a.mission.get("ordinal", 1))
	for i in 64:
		var q := Vector2(sin(i * 7.13 + scene) * half.x * 0.92, cos(i * 4.72 + scene) * half.y * 0.9)
		a.draw_arc(q, 12 + i % 7, i * 0.7, i * 0.7 + 1.8, 8, Color(theme, 0.14), 2)
	a.draw_rect(Rect2(-half, half * 2), Color(theme, 0.7), false, 5)
	a.draw_rect(Rect2(-half + Vector2.ONE * 14, half * 2 - Vector2.ONE * 28), Color(theme, 0.17), false, 1)
	for rock in a.state.obstacles:
		var q: Vector2 = a.pos(rock)
		var r := float(rock.radius)
		a.draw_circle(q + Vector2(5, 9), r + 5, Color(0, 0, 0, 0.3))
		var points := _polygon(q, r, 6, 0.3)
		a.draw_colored_polygon(points, theme.darkened(0.62))
		points.append(points[0])
		a.draw_polyline(points, Color(theme, 0.6), 2, true)
		a.draw_line(q - Vector2(r * 0.4, 0), q + Vector2(r * 0.4, -r * 0.4), Color(theme, 0.8), 3)
	_objectives(a, theme)
	for pickup in a.state.pickups:
		var q: Vector2 = a.pos(pickup)
		a.draw_circle(q, 8, Color(0.3, 1, 0.65, 0.12))
		a.draw_colored_polygon(_polygon(q, 4.5, 4, 0), Color(0.5, 1, 0.75))
	for z in a.state.zones:
		_zone(a, z)
	for e in a.state.entities:
		_enemy(a, e)
	for p in a.state.projectiles:
		var q: Vector2 = a.pos(p)
		var v := Vector2(p.vx, p.vy).normalized()
		var c := Color(str(p.color))
		if p.hostile: c = Color(1, 0.4, 0.32)
		a.draw_line(q - v * 18, q, Color(c, 0.45), maxf(3, p.radius * 0.6), true)
		if p.mode in ["disc", "return", "arc"]:
			a.draw_arc(q, p.radius, (0.0 if a.reduce_motion else p.age * 10), (0.0 if a.reduce_motion else p.age * 10) + 4.8, 18, c, 3, true)
		elif p.mode == "mark":
			a.draw_colored_polygon(_polygon(q, 9, 4, (0.0 if a.reduce_motion else p.age * 6)), c)
		else:
			a.draw_circle(q, maxf(3, p.radius), c)
			a.draw_circle(q, maxf(2, p.radius * 0.35), Color(1, 1, 0.95))
	_player(a)
	for effect in a.state.effects:
		var q: Vector2 = a.pos(effect)
		var life := 1.0 if a.reduce_motion else clampf(float(effect.ttl) / maxf(0.01, effect.duration), 0, 1)
		var color := Color(str(effect.color), life)
		var radius := float(effect.radius)
		match str(effect.kind):
			"beam":
				a.draw_line(q, q + Vector2.from_angle(effect.angle) * radius, color, 4, true)
			"slash":
				a.draw_arc(q, radius * (0.85 + 0.15 * (1-life)), effect.angle - 0.85, effect.angle + 0.85, 20, color, 8 * life + 1, true)
			"burst":
				for i in 7:
					var direction := Vector2.from_angle(TAU * i / 7)
					a.draw_line(q + direction * radius * (1-life), q + direction * radius * (1-life + 0.3), color, 3, true)
			_: a.draw_arc(q, radius * (1.1 - life * 0.2), 0, TAU, 36, color, 3, true)

static func _theme(a) -> Color:
	var themes: Array = []
	for m in a.catalog.missions:
		if not themes.has(m.theme): themes.append(m.theme)
	var index := maxi(0, themes.find(a.mission.theme)) % 8
	return [Color("75bd91"), Color("d6b17a"), Color("6ca9d9"), Color("e28457"), Color("68ccc3"), Color("bd8ce3"), Color("8899dd"), Color("da7999")][index]

static func _polygon(q: Vector2, radius: float, sides: int, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		points.append(q + Vector2.from_angle(angle + TAU * i / sides) * radius)
	return points

static func _objectives(a, theme: Color) -> void:
	var kind := str(a.mission.kind)
	var o: Dictionary = a.state.objective
	var index := int(o.waypoint) if kind in ["CLEANSE", "ESCORT"] else int(o.progress)
	var target: Vector2 = a.target_position(index)
	if kind in ["SURVIVE", "CLEANSE", "ESCORT"]:
		var radius := float(a.mission.get("target_radius", 90))
		var active: bool = kind != "SURVIVE" or bool(o.extraction_ready)
		var c := Color(theme, 0.8 if active else 0.25)
		a.draw_circle(target, radius, Color(theme, 0.06))
		a.draw_arc(target, radius, 0, TAU, 48, c, 3, true)
		a.draw_arc(target, radius * 0.82, 0, TAU, 40, c, 1, true)
		for i in 8:
			var q := target + Vector2.from_angle(TAU * i / 8) * radius
			a.draw_colored_polygon(_polygon(q, 5, 4, i), c)
		if kind == "CLEANSE":
			var ratio := float(o.hold) / maxf(0.1, float(a.mission.hold_seconds))
			a.draw_arc(target, radius + 7, -PI/2, -PI/2 + ratio * TAU, 48, Color("c9fff4"), 5, true)
	if kind == "ESCORT":
		var q: Vector2 = a.pos(o)
		a.draw_line(q, target, Color(theme, 0.2), 2)
		a.draw_colored_polygon(PackedVector2Array([q+Vector2(-30, 0),q+Vector2(-18,-20),q+Vector2(28,0),q+Vector2(-18,20)]), theme.darkened(0.25))
		a.draw_arc(q, 35, 0, TAU, 24, Color(theme, 0.6), 2)
		a.draw_rect(Rect2(q + Vector2(-30, -36), Vector2(60, 5)), Color("20232b"))
		a.draw_rect(Rect2(q + Vector2(-30, -36), Vector2(60 * maxf(0, o.escort_hp) / maxf(1, a.mission.escort_hp), 5)), Color("82e5c0"))
	if kind in ["HUNT", "BOSS", "BREAK"]:
		for e in a.state.entities:
			if e.target_id != "" and (kind != "BREAK" or a.mission.order_mode != "FIXED" or int(e.ordinal) == int(o.progress)):
				target = a.pos(e)
				break
	var offset: Vector2 = target - a.player_world_position()
	if offset.length() > 110:
		var q: Vector2 = a.player_world_position() + offset.normalized() * 70
		var v := offset.normalized()
		a.draw_colored_polygon(PackedVector2Array([q+v*11,q-v*7+v.orthogonal()*7,q-v*7-v.orthogonal()*7]), Color(theme, 0.9))

static func _zone(a, z: Dictionary) -> void:
	var q: Vector2 = a.pos(z)
	var hostile := bool(z.hostile)
	var warning := float(z.delay) > 0
	var c := Color("ff7157") if hostile else Color(str(z.color))
	var radius := float(z.radius)
	var alpha := 0.08 if warning else 0.17
	if z.kind == "flame":
		var points := PackedVector2Array([q])
		for i in 15: points.append(q + Vector2.from_angle(z.angle - 0.65 + i * 1.3 / 14) * float(z.length))
		a.draw_colored_polygon(points, Color(c, alpha))
		a.draw_arc(q, z.length, z.angle-0.65, z.angle+0.65, 20, c, 3)
	elif z.kind in ["line", "ink"]:
		var end := q + Vector2.from_angle(z.angle) * float(z.length)
		a.draw_line(q, end, Color(c, alpha), radius * 2)
		a.draw_line(q, end, Color(c, 0.8), 2 if warning else 5, true)
	elif z.kind in ["turret", "drone"]:
		a.draw_circle(q, 17, Color(c, 0.1))
		a.draw_colored_polygon(_polygon(q, 13, 3 if z.kind == "drone" else 6, z.angle), c.darkened(0.3))
		a.draw_arc(q, 18, (0.0 if a.reduce_motion else z.age * 2), (0.0 if a.reduce_motion else z.age * 2) + PI, 14, c, 2)
	else:
		if z.kind != "ring": a.draw_circle(q, radius, Color(c, alpha))
		a.draw_arc(q, radius, 0, TAU, 36, Color(c, 0.7), 2 if warning else 3, true)
		if warning:
			for i in 8:
				var v := Vector2.from_angle(TAU * i / 8)
				a.draw_line(q + v * radius * 0.75, q + v * radius, Color(c, 0.85), 3)
		elif z.kind in ["roots", "thorns", "spores", "winter", "void"]:
			for i in 6:
				var v := Vector2.from_angle(i * TAU / 6 + (0.0 if a.reduce_motion else float(z.age) * 0.7))
				a.draw_line(q + v * radius * 0.3, q + v.rotated(0.35) * radius * 0.8, Color(c, 0.6), 3)

static func _enemy(a, e: Dictionary) -> void:
	var q: Vector2 = a.pos(e)
	var radius := float(e.radius)
	var color := Color(str(e.color))
	if e.flash > 0: color = Color("fff4d9")
	if e.behavior == "burrow" and e.phase == 1:
		a.draw_arc(q, radius, 0, TAU, 20, Color(color, 0.3), 2)
		return
	a.draw_circle(q + Vector2(3, 7), radius, Color(0, 0, 0, 0.25))
	var direction: Vector2 = (a.player_world_position() - q).normalized()
	var angle := direction.angle()
	var modes := ["chase", "spitter", "flanker", "trail", "strafe", "charger", "crab", "jet", "burrow", "reflector", "fan_shooter", "bouncer", "slider", "buffer", "spike_line", "exploder", "rooter", "decoy", "diver", "anchor", "barrier", "shield", "channeler", "absorber"]
	var index := maxi(0, modes.find(e.behavior))
	if e.family == "target":
		a.draw_colored_polygon(_polygon(q, radius, 4, PI/4), color.darkened(0.35))
		a.draw_arc(q, radius+8, 0, TAU, 32, color, 3)
		var locked: bool = a.mission.order_mode == "FIXED" and int(e.ordinal) != int(a.state.objective.progress)
		if locked:
			a.draw_line(q-Vector2(12,12),q+Vector2(12,12),Color("8c8c9b"),5)
			a.draw_line(q-Vector2(-12,12),q+Vector2(-12,12),Color("8c8c9b"),5)
	elif e.family == "boss":
		var points := _polygon(q, radius, 9, (0.0 if a.reduce_motion else e.age * 0.15))
		a.draw_colored_polygon(points, color.darkened(0.3))
		for i in 6:
			var v := Vector2.from_angle(TAU * i / 6 + (0.0 if a.reduce_motion else e.age * 0.2))
			a.draw_line(q + v * radius * 0.7, q + v * radius * 1.45, color, 7, true)
		a.draw_arc(q, radius * 1.3, 0, TAU, 40, color, 2)
	else:
		var sides := 3 + index % 5
		a.draw_colored_polygon(_polygon(q, radius, sides, angle), color.darkened(0.15))
		# Silhouette appendages communicate locomotion/weapon family.
		if index in [0, 2, 5, 7, 18]:
			for sign_value in [-1,1]:
				var tip := q + direction.rotated(sign_value * 0.8) * radius * 1.5
				a.draw_line(q + direction.orthogonal() * sign_value * radius * 0.5, tip, color, 4)
		elif index in [1,4,10,22]:
			a.draw_line(q, q+direction*radius*1.5, color.lightened(0.3), 7)
		elif index in [6,11,12]:
			for side in [-1,1]:
				for i in 3:
					a.draw_line(q + Vector2((i-1)*radius*0.6,side*radius*0.6),q+Vector2((i-1)*radius,side*radius*1.4),color,2)
		else:
			a.draw_arc(q, radius*0.7, 0 if a.reduce_motion else e.age, 4 if a.reduce_motion else e.age+4, 16,color.lightened(0.4),2)
		a.draw_circle(q + direction * radius * 0.4, 3, Color("fff1ba"))
	if e.shield > 0: a.draw_arc(q, radius+6,0,TAU,24,Color("b3dfff"),3)
	if e.root > 0: a.draw_line(q-Vector2(radius,0),q+Vector2(radius,0),Color("92d46a"),4)
	if e.mark > 0: a.draw_colored_polygon(_polygon(q+Vector2(0,-radius-12),5,4,0),Color("db9aed"))
	if e.family in ["boss","elite","target"] or e.hp < e.max_hp:
		a.draw_rect(Rect2(q+Vector2(-radius,-radius-8),Vector2(radius*2,4)),Color("302936"))
		a.draw_rect(Rect2(q+Vector2(-radius,-radius-8),Vector2(radius*2*maxf(0,e.hp)/e.max_hp,4)),color)

static func _player(a) -> void:
	var q: Vector2 = a.player_world_position()
	var color := Color(str(a.tables.characters[a.loadout.character_id].get("color", "#a8eee5")))
	var facing := float(a.state.player.facing)
	if a.state.player.invulnerable > 0: color = Color("fff7d1")
	a.draw_circle(q+Vector2(0,9),19,Color(0,0,0,0.35))
	a.draw_arc(q, 24, (0.0 if a.reduce_motion else -a.state.elapsed), (0.0 if a.reduce_motion else -a.state.elapsed)+5,24,Color(color,0.5),2)
	var forward := Vector2.from_angle(facing)
	var side := forward.orthogonal()
	a.draw_colored_polygon(PackedVector2Array([q+forward*15,q-forward*18+side*14,q-forward*10,q-forward*18-side*14]),color.darkened(0.35))
	a.draw_circle(q,10,color)
	a.draw_line(q+side*10,q+side*14+forward*26,Color("efffff"),3,true)
	a.draw_circle(q+forward*4,4,Color("fff3d7"))
