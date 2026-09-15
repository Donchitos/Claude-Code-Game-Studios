extends SceneTree
## Deterministic local campaign simulation evidence; not a commercial playtime/platform certification.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Combat = preload("res://src/campaign/campaign_combat.gd")
var catalog: Dictionary
var loadout: Dictionary
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var raw := FileAccess.get_file_as_string("res://assets/config/campaign_game.json")
	catalog = JSON.parse_string(raw)
	catalog.content_hash = raw.sha256_text()
	loadout = {"character_id": catalog.characters[0].id, "difficulty": 0, "branches": [0, 0, 0], "pill_id": "", "completed": 64}
	_test_resume_and_reject()
	_test_skills()
	_test_ai()
	_test_bosses()
	_test_objectives()
	_test_build_events_and_caps()
	_test_natural_evolution()
	for failure in failures: printerr(failure)
	print("CAMPAIGN_COMBAT_", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures.size(), " modes=24 behaviors=24 bosses=9 objectives=6")
	quit(0 if failures.is_empty() else 1)

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _arena(mission: Dictionary = {}, override_loadout: Dictionary = {}) -> Node2D:
	var a = Arena.new()
	root.add_child(a)
	_check(a.configure(catalog, catalog.missions[0] if mission.is_empty() else mission, loadout if override_loadout.is_empty() else override_loadout, 42), "configure")
	return a

func _roundtrip(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value, "", true, true))

func _quiet(a) -> void:
	a.state.entities.clear()
	a.state.projectiles.clear()
	a.state.zones.clear()
	a.state.obstacles.clear()
	a.state.spawn_clock = 10000.0
	a.state.elite_clock = -10000.0
	a.state.event_done = true

func _test_resume_and_reject() -> void:
	var a = _arena()
	# Deliberately acquire in reverse ID order; serialization sorts dictionary keys.
	a.state.skills.clear()
	for index in [3, 2, 1, 0]: a.state.skills[catalog.skills[index].id] = 1
	for i in 120: a.advance(1.0 / 60, Vector2.RIGHT)
	var saved := _roundtrip(a.snapshot())
	_check(Arena.validate_snapshot(catalog, a.mission, saved), "valid snapshot preflight")
	var b = Arena.new()
	root.add_child(b)
	_check(b.configure(catalog, a.mission, loadout, 42, saved), "restore")
	for i in 240:
		if not a.state.offered.is_empty():
			var id: String = a.state.offered[0]
			_check(a.choose_upgrade(id) and b.choose_upgrade(id), "identical offered")
		a.advance(1.0 / 60, Vector2.UP)
		b.advance(1.0 / 60, Vector2.UP)
	_check(Arena.Validation.same_values(a.snapshot(), b.snapshot()), "reverse-order full precision resume exact")
	var bad := saved.duplicate(true)
	bad.state.player.hp = -1
	_check(not Arena.validate_snapshot(catalog, a.mission, bad), "negative hp")
	bad = saved.duplicate(true)
	bad.rng_state = "999999999999999999999"
	_check(not Arena.validate_snapshot(catalog, a.mission, bad), "RNG overflow")
	bad = saved.duplicate(true)
	bad.state.player.x = INF
	_check(not Arena.validate_snapshot(catalog, a.mission, bad), "infinite coordinates")
	bad = saved.duplicate(true)
	bad.state.offered = ["not-real"]
	_check(not Arena.validate_snapshot(catalog, a.mission, bad), "forged offer")
	bad = saved.duplicate(true)
	bad.content_hash = "wrong"
	_check(not Arena.validate_snapshot(catalog, a.mission, bad), "catalog binding")
	var other := loadout.duplicate(true)
	other.branches[0] = 1
	_check(not b.configure(catalog, a.mission, other, 42, saved), "loadout substitution")
	_check(not b.configure(catalog, a.mission, loadout, 43, saved), "seed substitution")
	var before: Dictionary = a.snapshot()
	a.advance(0.0, Vector2.ONE)
	_check(Arena.Validation.same_values(before, a.snapshot()), "zero delta freeze")
	a.free()
	b.free()

func _test_skills() -> void:
	for skill in catalog.skills:
		var a = _arena()
		_quiet(a)
		a.state.skills = {str(skill.id): 3}
		a.state.player.hp = a.state.player.max_hp
		for i in 10:
			var point := Vector2.from_angle(TAU * i / 10) * (146 if skill.mode == "orbit" else (45 if skill.mode in ["shield","winter"] else 100))
			var e: Dictionary = a.spawn_enemy(catalog.enemies[0].id, point)
			e.hp = 10000.0
			e.max_hp = 10000.0
			e.speed = 0.0
			e.damage = 0.0
		var damage_before: float = a.state.statistics.damage_dealt
		for tick in 240: a.advance(1.0 / 60, Vector2.ZERO)
		_check(a.state.statistics.damage_dealt > damage_before, "skill actual hit: " + str(skill.mode))
		_check(a.state.statistics.skills_used.has(skill.id), "skill receipt: " + str(skill.mode))
		a.free()
	# Swept projectile crosses an actor in one frame; a point test would miss.
	var a = _arena()
	_quiet(a)
	var e: Dictionary = a.spawn_enemy(catalog.enemies[0].id, Vector2(100, 0))
	var hp: float = e.hp
	Combat.projectile(a, Vector2.ZERO, Vector2(12000, 0), 10, 3, 1, "#ffffff")
	Combat.advance_projectiles(a, 1.0 / 60)
	_check(e.hp < hp, "swept collision")
	var before: float = a.state.player.hp
	a.damage_player(0)
	_check(a.state.player.hp == before and a.state.player.invulnerable == 0, "zero warning damage has no iframe")
	var p: Dictionary = Combat.projectile(a, Vector2.ZERO, Vector2.ZERO, 20, 20, 1, "#ffffff", "straight", 1, 0, true)
	p.ttl = 0.0
	Combat.advance_projectiles(a, 0.01)
	_check(a.state.player.hp == before, "expired reflected shot cannot hurt")
	a.free()

func _test_ai() -> void:
	var traces: Dictionary = {}
	for enemy in catalog.enemies:
		var a = _arena()
		_quiet(a)
		a.state.skills.clear()
		var e: Dictionary = a.spawn_enemy(enemy.id, Vector2(160, 0))
		e.timer = 0.0
		e.hp = 10000
		e.max_hp = 10000
		for i in 90:
			Combat.advance_enemies(a, 1.0 / 60)
		var changed: bool = a.pos(e) != Vector2(160, 0) or not a.state.projectiles.is_empty() or not a.state.zones.is_empty() or e.shield > 0
		_check(changed, "AI changes world: " + str(enemy.behavior))
		traces[enemy.behavior] = [e.x,e.y,e.phase,e.shield,a.state.projectiles.size(),a.state.zones.size()]
		a.free()
	var unique: Dictionary = {}
	for trace in traces.values(): unique[JSON.stringify(trace)] = true
	_check(unique.size() >= 20, "AI has distinct spatial/combat traces " + str(unique.size()))

func _test_bosses() -> void:
	var signatures: Dictionary = {}
	for row in catalog.bosses:
		var a = _arena()
		_quiet(a)
		var e: Dictionary = a.spawn_enemy(row.id, Vector2(220, 0), "boss")
		for phase in 3:
			e.hp = e.max_hp * (1.0 - phase * 0.34)
			e.timer = 0.0
			a.state.zones.clear()
			a.state.projectiles.clear()
			Combat.advance_enemies(a, 0.01)
			_check(not a.state.zones.is_empty() or not a.state.projectiles.is_empty(), "boss phase attacks " + str(row.id) + ":" + str(phase))
			var fingerprint: Array = []
			for z in a.state.zones: fingerprint.append([z.kind,z.x,z.y,z.radius,z.length,z.delay])
			signatures[JSON.stringify(fingerprint) + str(a.state.projectiles.size())] = true
		a.free()
	_check(signatures.size() >= 9, "nine boss pattern geometry signatures")

func _test_objectives() -> void:
	for kind in ["SURVIVE","BREAK","CLEANSE","HUNT","ESCORT","BOSS"]:
		var m: Dictionary = {}
		for row in catalog.missions:
			if row.kind == kind:
				m = row
				break
		var a = _arena(m)
		a.state.spawn_clock = 10000.0
		a.state.elite_clock = -10000.0
		a.state.event_done = true
		a.state.obstacles.clear()
		a.state.skills.clear()
		if kind == "SURVIVE":
			a.state.elapsed = m.target_seconds
			a.state.objective.elapsed = m.target_seconds
			a.advance(0.01, Vector2.ZERO)
			a.set_pos(a.state.player, a.target_position(0))
			a.advance(0.01, Vector2.ZERO)
		elif kind == "CLEANSE":
			for i in int(m.target_count):
				a.set_pos(a.state.player, a.target_position(i))
				for j in int(ceil(float(m.hold_seconds) * 60)) + 2: a.advance(1.0 / 60, Vector2.ZERO)
		elif kind == "ESCORT":
			for i in int(m.target_count):
				a.set_pos(a.state.player, a.target_position(i))
				a.set_pos(a.state.objective, a.target_position(i))
				a.advance(0.01, Vector2.ZERO)
		else:
			for i in int(m.target_count):
				var target: Dictionary = {}
				for e in a.state.entities:
					if e.target_id == m.target_ids[i]: target = e
				_check(not target.is_empty(), "spawned mission target " + kind)
				if target.is_empty(): continue
				Combat.projectile(a, a.pos(target) - Vector2(35,0), Vector2(4200,0), target.max_hp * 3, 4, 1, "#ffffff")
				a.advance(1.0 / 60, Vector2.ZERO)
		_check(a.state.finished and a.state.victory, "real advance objective " + kind)
		a.free()

func _test_build_events_and_caps() -> void:
	var a = _arena()
	var before: Dictionary = a.snapshot()
	_check(not a.choose_upgrade("invalid"), "illegal upgrade rejected")
	_check(Arena.Validation.same_values(before, a.snapshot()), "illegal upgrade no effects")
	var recipe: Dictionary = catalog.evolutions[0]
	a.state.skills = {str(recipe.skill_id): 5}
	a.state.passives = {str(recipe.passive_id): 4}
	a._offer()
	_check(not a.state.offered.has(recipe.id), "evolution requires passive five")
	a.state.passives[recipe.passive_id] = 5
	a.state.offered = [recipe.id]
	_check(a.choose_upgrade(recipe.id), "evolution legal")
	_check(a.stats().evolution_ids.has(recipe.id), "evolution IDs receipt")
	a.state.offered.clear()
	a.state.event_id = catalog.events[0].id
	var event_hp: float = a.state.player.hp
	_check(a.choose_event(true), "risk event accepted")
	_check(a.state.player.hp == event_hp - catalog.events[0].risk.damage and a.stats().risk_choices == 1 and a.stats().event_reward == catalog.events[0].risk.reward, "risk consequences")
	_check(not a.choose_event(false), "event cannot replay")
	for i in 500: a.spawn_enemy(catalog.enemies[0].id, Vector2(100,100))
	_check(a.state.entities.size() == 180, "enemy capacity")
	for i in 500: Combat.projectile(a, Vector2.ZERO, Vector2.ONE, 1, 2, 1, "#ffffff")
	_check(a.state.projectiles.size() == 400, "projectile capacity")
	for i in 200: Combat.zone(a, Vector2.ZERO, 20, 1, 1, "#ffffff", "blast", false, 1)
	_check(a.state.zones.size() == 128, "delayed work capacity")
	a.free()
	for pill in catalog.pills:
		var l := loadout.duplicate(true)
		l.pill_id = pill.id
		a = _arena({}, l)
		var stat := str(pill.stat)
		var amount_before: float = a.modifier(stat)
		a._advance_pill(pill.duration)
		_check(a.state.pill_remaining == 0, "pill expiration " + stat)
		if stat not in ["max_hp","rerolls"]: _check(a.modifier(stat) == amount_before - pill.amount, "pill modifier removed " + stat)
		a.free()
	for challenge in catalog.challenges:
		var l := loadout.duplicate(true)
		l.challenge_id = challenge.id
		var m: Dictionary = {}
		for row in catalog.missions:
			if row.id == challenge.mission_id: m = row
		a = _arena(m,l)
		_check(a.state.active_cap == challenge.max_skills and a.state.enemy_multiplier == challenge.enemy_multiplier and a.state.hazard_multiplier == challenge.hazard_multiplier, "challenge runtime " + str(challenge.id))
		a.free()

func _test_natural_evolution() -> void:
	# Real catalog, fresh starting character, no stat/XP/entity mutation. Input and choices only.
	var l := loadout.duplicate(true)
	l.completed = 0
	var a = _arena({}, l)
	var recipe: Dictionary = catalog.evolutions[0]
	for tick in 60 * 150:
		if a.state.finished: break
		if not a.state.offered.is_empty():
			var chosen: String = a.state.offered[0]
			for id in [recipe.id, recipe.skill_id, recipe.passive_id]:
				if a.state.offered.has(id):
					chosen = id
					break
			a.choose_upgrade(chosen)
		if a.state.event_id != "": a.choose_event(false)
		var player: Vector2 = a.player_world_position()
		var destination := Vector2.ZERO
		var nearest_distance := INF
		for pickup in a.state.pickups:
			var d: float = player.distance_squared_to(a.pos(pickup))
			if d < nearest_distance:
				nearest_distance = d
				destination = a.pos(pickup)
		if nearest_distance == INF:
			var target: Dictionary = Combat.nearest(a, player, 1400)
			if not target.is_empty(): destination = a.pos(target)
		var movement := (destination - player).normalized()
		var avoid := Vector2.ZERO
		for e in a.state.entities:
			var offset: Vector2 = player - a.pos(e)
			if offset.length() < 110: avoid += offset.normalized() * (110 - offset.length()) / 70
		movement = (movement + avoid * 1.8).limit_length()
		if not a.state.evolved.is_empty() and a.state.elapsed > a.mission.target_seconds:
			movement = (a.target_position(0) - player).normalized()
		a.advance(1.0 / 60, movement)
		if not a.state.evolved.is_empty(): break
	_check(not a.state.evolved.is_empty(), "natural fresh-run evolution")
	print("NATURAL_EVOLUTION ", JSON.stringify({"evolved":a.state.evolved,"elapsed":a.state.elapsed,"kills":a.state.player.kills,"level":a.state.player.level,"hp":a.state.player.hp,"skills":a.state.skills,"passives":a.state.passives}))
	a.free()
