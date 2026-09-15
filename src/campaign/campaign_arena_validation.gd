extends RefCounted
## Strict JSON snapshot validator. Validation never mutates input or silently restarts RNG.
const Codec = preload("res://src/campaign/campaign_arena_codec.gd")
const BEHAVIORS := ["chase","spitter","flanker","trail","strafe","charger","crab","jet","burrow","reflector","fan_shooter","bouncer","slider","buffer","spike_line","exploder","rooter","decoy","diver","anchor","barrier","shield","channeler","absorber"]

## Rejects malformed/capacity-exceeding snapshots before any arena state is published.
static func validate(c: Dictionary, m: Dictionary, saved: Dictionary) -> bool:
	if not _json(saved, 0) or str(c.get("content_hash", "")).length() != 64 or saved.get("content_hash") != c.content_hash:
		return false
	for key in ["rng_seed", "rng_state"]:
		if not saved.get(key) is String or not _integer_string(saved[key]): return false
	if not saved.get("loadout") is Dictionary or not saved.get("state") is Dictionary: return false
	var l: Dictionary = saved.loadout
	if not valid_loadout(c, m, l): return false
	if not saved.has("numeric_bits") or not Codec.valid(saved.state, saved.numeric_bits): return false
	var s: Dictionary = Codec.restore(saved.state, saved.numeric_bits)
	var character_ids := _ids(c.get("characters", []))
	if not character_ids.has(l.get("character_id")) or not _integer(l.get("difficulty"), 0, 2): return false
	if not l.get("branches") is Array or l.branches.size() != 3: return false
	for rank in l.branches:
		if not _integer(rank, 0, int(c.tuning.get("progression_max_level", 5))): return false
	if not l.get("pill_id", "") is String or not _integer(l.get("completed", 0), 0, c.missions.size()): return false
	if l.get("pill_id", "") != "" and not _ids(c.pills).has(l.pill_id): return false
	var active_cap := 4
	if str(l.get("challenge_id", "")) != "":
		var challenges := _rows(c.challenges)
		if not challenges.has(l.challenge_id): return false
		var ch: Dictionary = challenges[l.challenge_id]
		if ch.mission_id != m.id or (not ch.allow_pills and l.get("pill_id", "") != ""): return false
		active_cap = int(ch.max_skills)
	for key in ["player","objective","skills","passives","cooldowns","modifiers","statistics"]:
		if not s.get(key) is Dictionary: return false
	for key in ["offered","evolved","entities","projectiles","zones","pickups","effects","obstacles","target_deaths"]:
		if not s.get(key) is Array: return false
	for key in ["finished","victory","event_done","boss_spawned"]:
		if not s.get(key) is bool: return false
	for key in ["reason","event_id","pill_stat"]:
		if not s.get(key) is String: return false
	for key in ["elapsed","spawn_clock","elite_clock","event_clock","event_pressure","event_reward","pill_remaining","pill_amount","enemy_multiplier","hazard_multiplier"]:
		if not _number(s.get(key), -1 if key == "spawn_clock" else 0, 1000000): return false
	for key in ["next_id","tick","pending_levels","rerolls","active_cap"]:
		if not _integer(s.get(key), 0, 100000000): return false
	if int(s.active_cap) != active_cap or s.elapsed > float(m.timeout_seconds) + 0.25 or int(s.next_id) < 1: return false
	var p: Dictionary = s.player
	if not _position(p, c, 0) or not _number(p.get("max_hp"), 1, 100000) or not _number(p.get("hp"), 0, p.max_hp): return false
	if not _integer(p.get("level"), 1, 100) or not _integer(p.get("kills"), 0, 10000000) or not _number(p.get("xp"), 0, 1000000): return false
	if not _number(p.get("invulnerable"), 0, 10) or not _number(p.get("facing"), -100, 100): return false
	var skills := _rows(c.skills)
	var passives := _rows(c.passives)
	var recipes := _rows(c.evolutions)
	for family in ["skills", "passives"]:
		var rows: Dictionary = skills if family == "skills" else passives
		if s[family].size() > (active_cap if family == "skills" else 4): return false
		for id in s[family]:
			if not rows.has(id) or not _integer(s[family][id], 1, 5): return false
	if s.skills.is_empty(): return false
	if s.offered.size() > 3 or s.evolved.size() > 4: return false
	var unique: Array = []
	for id in s.offered:
		if not id is String or unique.has(id): return false
		unique.append(id)
		if skills.has(id):
			if int(s.skills.get(id, 0)) >= 5 or (not s.skills.has(id) and s.skills.size() >= active_cap): return false
		elif passives.has(id):
			if int(s.passives.get(id, 0)) >= 5 or (not s.passives.has(id) and s.passives.size() >= 4): return false
		elif recipes.has(id):
			if not _recipe(s, recipes[id]) or s.evolved.has(id): return false
		else: return false
	unique.clear()
	for id in s.evolved:
		if not id is String or not recipes.has(id) or unique.has(id) or not _recipe(s, recipes[id]): return false
		unique.append(id)
	for id in s.cooldowns:
		if not s.skills.has(id) or not _number(s.cooldowns[id], -0.25, 1000): return false
	if s.event_id != "" and not _ids(c.events).has(s.event_id): return false
	if s.finished and (not s.offered.is_empty() or s.event_id != ""): return false
	var limits := {"entities": mini(180, int(c.tuning.enemy_cap)), "projectiles": mini(400, int(c.tuning.projectile_cap)), "pickups": mini(300, int(c.tuning.pickup_cap)), "zones": 128, "effects": 128, "obstacles": 8}
	for key in limits:
		if s[key].size() > limits[key]: return false
	var enemies := _rows(c.enemies)
	enemies.merge(_rows(c.elites))
	enemies.merge(_rows(c.bosses))
	var uids: Array = []
	var live_targets: Array = []
	for e in s.entities:
		if not e is Dictionary or not _position(e, c, 0): return false
		if not _integer(e.get("uid"), 1, s.next_id - 1) or uids.has(int(e.uid)): return false
		uids.append(int(e.uid))
		if not e.get("family") in ["enemy","elite","boss","target"] or not e.get("behavior") in BEHAVIORS: return false
		if not e.get("id") is String or not e.get("target_id") is String or not e.get("pattern") is String or not e.get("color") is String: return false
		if e.family != "target" and not enemies.has(e.id): return false
		if e.target_id != "":
			if not m.target_ids.has(e.target_id) or live_targets.has(e.target_id): return false
			live_targets.append(e.target_id)
		for key in ["x","y","vx","vy","aim","timer","ordinal"]:
			if not _number(e.get(key), -100000, 100000): return false
		for key in ["hp","max_hp","radius","speed","damage","age","phase","slow","root","flash","mark","mark_timer","shield","cooldown","range"]:
			if not _number(e.get(key), 0, 10000000): return false
		if e.hp > e.max_hp or e.max_hp <= 0 or e.radius <= 0 or e.radius > 150: return false
	for q in s.projectiles:
		if not q is Dictionary or not _position(q, c, 100): return false
		for key in ["vx","vy"]:
			if not _number(q.get(key), -100000, 100000): return false
		for key in ["damage","radius","ttl","duration","explosion","age"]:
			if not _number(q.get(key), 0, 100000): return false
		if not q.get("hostile") is bool or not q.get("returning") is bool or not q.get("color") is String: return false
		if not q.get("mode") in ["straight","pierce","explode","disc","return","arc","ice","mark"]: return false
		if not _integer(q.get("pierce"), 0, 32) or not q.get("hits") is Array or q.hits.size() > 32: return false
		for uid in q.hits:
			if not _integer(uid, 1, s.next_id - 1): return false
	for z in s.zones:
		if not z is Dictionary or not _position(z, c, 2500): return false
		if not z.get("kind") in ["orbit","flame","blast","shield","turret","drone","lightning","roots","thorns","spores","winter","ink","seal","void","line","poison","ring"]: return false
		if not z.get("color") is String or not z.get("hostile") is bool: return false
		for key in ["radius","damage","ttl","duration","delay","pulse","angle","length","orbit_radius","age"]:
			if not _number(z.get(key), -100000 if key in ["delay","pulse","angle"] else 0, 100000): return false
	for item in s.pickups:
		if not item is Dictionary or not _position(item, c, 0) or not _number(item.get("xp"), 0, 1000000) or not _number(item.get("ttl"), 0, 120): return false
	for rock in s.obstacles:
		if not rock is Dictionary or not _position(rock, c, 0) or not _number(rock.get("radius"), 1, 100): return false
	for fx in s.effects:
		if not fx is Dictionary or not _position(fx, c, 2500) or not fx.get("color") is String or not fx.get("kind") is String: return false
		for key in ["radius","ttl","duration","angle"]:
			if not _number(fx.get(key), -10000 if key == "angle" else 0, 10000): return false
	var o: Dictionary = s.objective
	if not _position(o, c, 0) or o.get("kind") != m.kind: return false
	for key in ["player_alive","finished","victory","extraction_ready","extraction_was_inside"]:
		if not o.get(key) is bool: return false
	if not o.get("reason") is String: return false
	for key in ["elapsed","hold","escort_hp","pressure"]:
		if not _number(o.get(key), 0, 1000000): return false
	for key in ["waypoint","progress"]:
		if not _integer(o.get(key), 0, int(m.target_count)): return false
	for key in ["completed_ids","completion_order"]:
		if not o.get(key) is Array or not _unique_targets(o[key], m.target_ids): return false
	if not _unique_targets(s.target_deaths, m.target_ids): return false
	if o.completed_ids.size() != int(o.progress) or o.completed_ids.size() != o.completion_order.size(): return false
	for id in o.completed_ids:
		if not o.completion_order.has(id): return false
	if m.kind == "BREAK" and m.order_mode == "FIXED":
		for i in o.completion_order.size():
			if o.completion_order[i] != m.target_ids[i]: return false
	if bool(s.finished) != bool(o.finished) or bool(s.victory) != bool(o.victory) or s.reason != o.reason: return false
	if bool(o.player_alive) != (p.hp > 0): return false
	if not s.finished and (p.hp <= 0 or (m.kind == "ESCORT" and o.escort_hp <= 0)): return false
	var stats: Dictionary = s.statistics
	for key in ["damage_taken","damage_dealt","elite_kills","boss_kills","evolutions","events_taken","safe_choices","risk_choices"]:
		if not _number(stats.get(key), 0, 1000000000): return false
	if not stats.get("skills_used") is Array or stats.skills_used.size() > 24: return false
	for id in stats.skills_used:
		if not skills.has(id): return false
	return true

static func _recipe(s: Dictionary, r: Dictionary) -> bool:
	return int(s.skills.get(r.skill_id, 0)) >= int(r.get("required_skill_level", 5)) and int(s.passives.get(r.passive_id, 0)) >= int(r.get("required_passive_level", 5))

static func _rows(rows: Array) -> Dictionary:
	var result := {}
	for row in rows: result[row.id] = row
	return result

static func _ids(rows: Array) -> Array:
	return _rows(rows).keys()

static func _number(v: Variant, low: float, high: float) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v) >= low and float(v) <= high

static func _integer(v: Variant, low: float, high: float) -> bool:
	return _number(v, low, high) and float(v) == floorf(float(v))

static func _integer_string(v: String) -> bool:
	return not v.is_empty() and v.length() <= 20 and v.is_valid_int() and str(v.to_int()) == v

static func _position(d: Dictionary, c: Dictionary, margin: float) -> bool:
	return _number(d.get("x"), -float(c.tuning.arena_half_size[0])-margin, float(c.tuning.arena_half_size[0])+margin) and _number(d.get("y"), -float(c.tuning.arena_half_size[1])-margin, float(c.tuning.arena_half_size[1])+margin)

static func _unique_targets(values: Array, ids: Array) -> bool:
	var seen: Array = []
	for id in values:
		if not id is String or not ids.has(id) or seen.has(id): return false
		seen.append(id)
	return true

static func _json(value: Variant, depth: int) -> bool:
	if depth > 12: return false
	if value == null or value is bool: return true
	if value is int or value is float: return is_finite(float(value)) and absf(float(value)) <= 9007199254740991.0
	if value is String: return value.length() <= 512
	if value is Array:
		if value.size() > 400: return false
		for child in value:
			if not _json(child, depth + 1): return false
		return true
	if value is Dictionary:
		if value.size() > 80: return false
		for key in value:
			if not key is String or not _json(value[key], depth + 1): return false
		return true
	return false

## Structural comparison treats JSON integer/float representations as the same numeric value.
static func same_values(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key in a:
			if not b.has(key) or not same_values(a[key], b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not same_values(a[i], b[i]): return false
		return true
	if (a is float or a is int) and (b is float or b is int): return float(a) == float(b)
	return typeof(a) == typeof(b) and a == b

## Input contract for fresh runs as well as restore; fractional ranks are never truncated.
static func valid_loadout(c: Dictionary, m: Dictionary, l: Dictionary) -> bool:
	if not _json(Codec.normalize(l), 0): return false
	if not l.get("character_id") is String or not _integer(l.get("difficulty"), 0, 2): return false
	if not _integer(l.get("completed", 0), 0, c.get("missions", []).size()): return false
	var characters := _rows(c.get("characters", []))
	if not characters.has(l.character_id): return false
	if int(characters[l.character_id].get("unlock_after", 0)) > int(l.get("completed", 0)): return false
	if not l.get("branches") is Array or l.branches.size() != 3: return false
	for rank in l.branches:
		if not _integer(rank, 0, int(c.get("tuning", {}).get("progression_max_level", 5))): return false
	var pill_id: Variant = l.get("pill_id", "")
	if not pill_id is String: return false
	if pill_id != "":
		var pills := _rows(c.get("pills", []))
		if not pills.has(pill_id) or int(pills[pill_id].get("unlock_after", 0)) > int(l.get("completed", 0)): return false
	var challenge_id: Variant = l.get("challenge_id", "")
	if not challenge_id is String: return false
	if challenge_id != "":
		var challenges := _rows(c.get("challenges", []))
		if not challenges.has(challenge_id): return false
		var row: Dictionary = challenges[challenge_id]
		if row.mission_id != m.id or (not row.allow_pills and pill_id != "") or int(row.unlock_after) > int(l.get("completed", 0)): return false
	return true
