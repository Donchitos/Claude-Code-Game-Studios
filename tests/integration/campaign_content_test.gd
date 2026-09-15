extends SceneTree
## Headless production-content and pure mission integration coverage.
const Catalog = preload("res://src/campaign/campaign_catalog.gd")
const Mission = preload("res://src/campaign/campaign_mission.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _point(p: Array) -> Vector2:
	return Vector2(float(p[0]), float(p[1]))

func _roundtrip(state: Dictionary) -> Dictionary:
	var result: Dictionary = JSON.parse_string(JSON.stringify(state))
	_check(_same_json(result, state), "snapshot JSON roundtrip preserves all values")
	return result

func _same_json(left: Variant, right: Variant) -> bool:
	if (left is int or left is float) and (right is int or right is float):
		return is_equal_approx(float(left), float(right))
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size():
			return false
		for key: Variant in right:
			if not left.has(key) or not _same_json(left[key], right[key]):
				return false
		return true
	if left is Array and right is Array:
		if left.size() != right.size():
			return false
		for i in range(left.size()):
			if not _same_json(left[i], right[i]):
				return false
		return true
	return typeof(left) == typeof(right) and left == right

func _run() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	var errors := Catalog.validate(raw)
	_check(errors.is_empty(), "catalog validation " + str(errors))
	var data := Catalog.load_catalog()
	_check(not data.is_empty(), "load catalog")
	if data.is_empty():
		quit(1)
		return
	_check(data.content_hash == FileAccess.get_file_as_string(Catalog.PATH).sha256_text(), "exact source SHA256")
	_check(not raw.has("content_hash"), "hash is not serialized in content")
	_check(Catalog.validate(data).is_empty(), "derived hash ignored by validation")
	_check(Catalog.lookup(data, "skills", "missing").is_empty(), "unknown lookup")
	_check(Catalog.lookup(data, "missing", "S1-A01").is_empty(), "unknown collection lookup")
	_check(Catalog.localized({"name":"中文", "name_en":"English"}, "en-US") == "English", "English locale")
	_check(Catalog.localized({"name":"中文"}, "en") == "中文", "locale fallback")
	_check(Catalog.localized({"name":"中文", "name_en":"English"}, "zh_CN") == "中文", "Chinese locale")
	var reached: Dictionary = {"START":true}
	var scenes: Dictionary = {}
	var kinds: Dictionary = {}
	for index in range(64):
		var def: Dictionary = data.missions[index]
		_check(reached.has(def.prerequisite_id), "reachable " + def.id)
		_check(int(def.unlock_after) == index, "sequential unlock " + def.id)
		reached[def.id] = true
		scenes[def.scene_id] = true
		kinds[def.kind] = true
		for grant: String in def.first_grants:
			var found := false
			for collection: String in Catalog.COUNTS:
				var row := Catalog.lookup(data, collection, grant)
				if not row.is_empty():
					found = row.unlock_after == def.ordinal
			_check(found, "first grant unlock " + grant)
		_test_definition(def)
	_check(scenes.size() == 16 and kinds.size() == 6, "16 scenes / six objective types")
	_check(data.missions[62].boss_id == "S1-B08" and data.missions[63].boss_id == "S1-B09", "chapter eight does not prematurely end")
	_test_mutations(data)
	_test_multi_hunt(data)
	print("CAMPAIGN_CONTENT_TEST checks=%d failures=%d missions=64 scenes=16 objectives=6" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_definition(def: Dictionary) -> void:
	var state := Mission.create(def)
	var first := _point(def.target_positions[0])
	var away := Vector2(900, 600)
	# Wrong target and invalid deltas cannot progress any objective.
	Mission.advance(state, def, -1, away, [], ["unrelated"], away)
	_check(float(state.elapsed) == 0, "negative delta " + def.id)
	Mission.advance(state, def, NAN, away, [], [], away)
	_check(float(state.elapsed) == 0, "NaN delta " + def.id)
	Mission.advance(state, def, 0, away, [], ["unrelated"], away)
	_check(not state.finished, "unrelated death " + def.id)
	state = _roundtrip(state)
	match str(def.kind):
		"SURVIVE":
			Mission.advance(state, def, float(def.target_seconds), first, [], [], away)
			_check(state.extraction_ready and not state.finished, "cannot camp extraction " + def.id)
			Mission.advance(state, def, .1, first, [], [], away)
			_check(not state.finished, "must enter after readiness " + def.id)
			Mission.advance(state, def, .1, away, [], [], away)
			state = _roundtrip(state)
			Mission.advance(state, def, .1, first, [], [], away)
		"BREAK":
			if def.order_mode == "FIXED":
				Mission.advance(state, def, .1, first, [], [def.target_ids[1]], away)
				_check(state.progress == 0, "reject future anchor " + def.id)
			var order: Array = def.target_ids.duplicate()
			if def.order_mode == "PLAYER_CHOICE":
				order.reverse()
			for id: String in order:
				Mission.advance(state, def, .1, first, [], [id, id], away)
				state = _roundtrip(state)
			_check(state.completion_order == order, "actual anchor order preserved " + def.id)
		"CLEANSE":
			for i in range(int(def.target_count)):
				var p := _point(def.target_positions[i])
				Mission.advance(state, def, 1, p, [p + Vector2(float(def.cleanse_enemy_radius), 0)], [], away)
				_check(state.hold == 0, "enemy on boundary blocks cleanse " + def.id)
				Mission.advance(state, def, 1, p + Vector2(float(def.target_radius) + 1, 0), [], [], away)
				_check(state.hold == 0, "outside zone cannot cleanse " + def.id)
				Mission.advance(state, def, float(def.hold_seconds) / 2, p, [], [], away)
				var held := float(state.hold)
				Mission.advance(state, def, 1, p, [p], [], away)
				_check(is_equal_approx(float(state.hold), held), "interruption preserves hold " + def.id)
				state = _roundtrip(state)
				Mission.advance(state, def, float(def.hold_seconds) / 2, p, [], [], away)
		"HUNT", "BOSS":
			Mission.advance(state, def, .1, first, [], ["S1-B99"], away)
			_check(not state.finished, "specific target required " + def.id)
			Mission.advance(state, def, .1, first, [], def.target_ids, away)
		"ESCORT":
			Mission.advance(state, def, 1, first + Vector2(float(def.escort_radius)+1, 0), [], [], first)
			_check(state.waypoint == 0, "distant escort does not progress " + def.id)
			Mission.advance(state, def, 1, _point(def.target_positions[1]), [], [], _point(def.target_positions[1]))
			_check(state.waypoint == 0, "cannot skip escort waypoint " + def.id)
			for point: Array in def.target_positions:
				Mission.advance(state, def, .1, _point(point), [], [], _point(point))
				state = _roundtrip(state)
	_check(state.finished and state.victory, "positive completion " + def.id)
	_check(int(state.progress) == int(def.target_count), "all required targets " + def.id)
	var terminal := JSON.stringify(state)
	Mission.advance(state, def, 99999, away, [], def.target_ids, away)
	_check(JSON.stringify(state) == terminal, "terminal state immutable " + def.id)
	var dead := Mission.create(def)
	dead.player_alive = false
	Mission.advance(dead, def, .1, first, [], def.target_ids, first)
	_check(dead.finished and not dead.victory and dead.reason == "player_dead", "death wins tie " + def.id)
	var timeout := Mission.create(def)
	Mission.advance(timeout, def, float(def.timeout_seconds), first, [], def.target_ids, first)
	_check(timeout.finished and not timeout.victory and timeout.reason == "timeout", "inclusive timeout " + def.id)
	if def.kind == "ESCORT":
		var lost := Mission.create(def)
		lost.waypoint = int(def.target_count)-1
		lost.escort_hp = 0
		var last := _point(def.target_positions[-1])
		Mission.advance(lost, def, .1, last, [], [], last)
		_check(lost.finished and not lost.victory and lost.reason == "escort_destroyed", "escort death wins arrival tie " + def.id)

func _test_multi_hunt(data: Dictionary) -> void:
	var def: Dictionary = data.missions[3].duplicate(true)
	def.target_count = 2
	def.target_ids = ["hunt:one", "hunt:two"]
	def.target_positions = [[0,0], [100,100]]
	var state := Mission.create(def)
	Mission.advance(state, def, .1, Vector2.ZERO, [], ["hunt:one", "hunt:one"], Vector2.ZERO)
	_check(state.progress == 1 and not state.finished, "multi-hunt deduplicates partial kills")
	state = _roundtrip(state)
	Mission.advance(state, def, .1, Vector2.ZERO, [], ["hunt:two"], Vector2.ZERO)
	_check(state.victory and state.progress == 2, "multi-hunt requires every target")

func _test_mutations(data: Dictionary) -> void:
	for key: String in Catalog.COUNTS:
		var bad := data.duplicate(true)
		bad.erase(key)
		_check(not Catalog.validate(bad).is_empty(), "missing collection " + key)
		bad = data.duplicate(true)
		bad[key][0] = "not an object"
		_check(not Catalog.validate(bad).is_empty(), "malformed row " + key)
	for mutation: Array in [["ordinal", 2], ["unlock_after", 1], ["prerequisite_id", "S1-M08-08"], ["target_count", 0], ["target_ids", ["a","b"]], ["target_positions", [[99999, 0]]], ["enemy_ids", ["missing"]], ["kind", "UNKNOWN"], ["timeout_seconds", -1], ["target_hp", "100"], ["reward", true]]:
		var bad := data.duplicate(true)
		bad.missions[0][mutation[0]] = mutation[1]
		_check(not Catalog.validate(bad).is_empty(), "reject mission mutation " + str(mutation))
	var bad := data.duplicate(true)
	bad.skills[1].mode = bad.skills[0].mode
	_check(not Catalog.validate(bad).is_empty(), "duplicate mode")
	bad = data.duplicate(true)
	bad.passives[1].stat = bad.passives[0].stat
	_check(not Catalog.validate(bad).is_empty(), "duplicate passive mechanic")
	bad = data.duplicate(true)
	bad.characters[0].start_skill = "missing"
	_check(not Catalog.validate(bad).is_empty(), "bad starting skill")
	bad = data.duplicate(true)
	bad.evolutions[0].passive_id = "missing"
	_check(not Catalog.validate(bad).is_empty(), "bad evolution reference")
	bad = data.duplicate(true)
	bad.skills[0].damage = INF
	_check(not Catalog.validate(bad).is_empty(), "nonfinite tuning")

	for mutation: Array in [["enemies", "behavior", "unknown"], ["bosses", "phase_patterns", ["pounce", "unknown", "nexus"]], ["challenges", "mission_id", "missing"], ["challenges", "max_skills", 5], ["challenges", "allow_pills", "false"], ["challenges", "enemy_multiplier", 0], ["achievements", "rule", {"stat": "character_win", "id": "unknown", "target": 1}]]:
		bad = data.duplicate(true)
		bad[mutation[0]][0][mutation[1]] = mutation[2]
		_check(not Catalog.validate(bad).is_empty(), "invalid playable reference/restriction " + str(mutation))
