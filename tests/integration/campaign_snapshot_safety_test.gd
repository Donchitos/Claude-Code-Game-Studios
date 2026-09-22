extends "res://tests/integration/campaign_journey_test.gd"
## Counterexamples defined before implementation: atomic reject, RNG and work freeze,
## complete JSON round trip and 200 subsequent ticks with identical legal choices.

func canonical(value: Variant) -> String:
	return JSON.stringify(value, "", true, true)

func _run() -> void:
	var c := catalog_fixture()
	if c.is_empty():
		finish("snapshot-safety")
		return
	var m: Dictionary = c.missions[0].duplicate(true)
	m.target_seconds = 900.0
	m.timeout_seconds = 1000.0
	install_mission(c, m)
	var a = make_arena(c, m)
	for i in 240:
		resolve_all(a)
		a.advance(1.0 / 60.0, Vector2.RIGHT)
	var saved: Dictionary = JSON.parse_string(canonical(a.snapshot()))
	expect(Arena.validate_snapshot(c, m, saved), "accept complete JSON snapshot")
	var b = make_arena(c, m, 711, saved)
	var identical := true
	var diverged := -1
	for i in 200:
		resolve_all(a)
		resolve_all(b)
		var move := Vector2(cos(i * 0.07), sin(i * 0.07))
		a.advance(1.0 / 60.0, move)
		b.advance(1.0 / 60.0, move)
		if canonical(a.snapshot()) != canonical(b.snapshot()):
			identical = false
			diverged = i
			_save_difference("ordinary", a.snapshot(), b.snapshot())
			break
	expect(identical and a.state.tick > saved.state.tick, "restored next 200 ticks exact", {"first_divergence": diverged, "tick": a.state.tick})
	b.free()
	var before := canonical(a.snapshot())
	expect(not a.choose_upgrade("unknown-upgrade") and canonical(a.snapshot()) == before, "illegal choice has no effects")
	for delta in [-1.0, 0.0, NAN, INF, 0.5]:
		a.advance(delta, Vector2.RIGHT)
	expect(canonical(a.snapshot()) == before, "illegal deltas do not consume RNG or pending work")
	_test_corruption(c, m, saved)
	a.free()
	_test_pending_restore(c)
	_test_nonlexical_skill_restore(c)
	finish("snapshot-safety")

func _test_corruption(c: Dictionary, m: Dictionary, saved: Dictionary) -> void:
	var cases: Dictionary = {}
	for key in saved.keys():
		var bad := saved.duplicate(true)
		bad.erase(key)
		cases["missing " + key] = bad
	for key in ["definition_hash", "content_hash", "mission_id", "rng_state"]:
		if not saved.has(key):
			continue
		var bad := saved.duplicate(true)
		bad[key] = "wrong-or-not-a-number"
		cases["wrong " + key] = bad
	for key in saved.state:
		var bad := saved.duplicate(true)
		bad.state.erase(key)
		cases["missing state." + str(key)] = bad
	for value in [-1, NAN, INF, "not-a-number"]:
		var bad := saved.duplicate(true)
		bad.state.player.hp = value
		cases["invalid hp " + str(value)] = bad
	for field in ["level", "xp", "x", "kills"]:
		var bad := saved.duplicate(true)
		bad.state.player[field] = NAN
		cases["invalid player." + field] = bad
	for key in saved.state.player:
		var bad := saved.duplicate(true)
		bad.state.player.erase(key)
		cases["missing player." + str(key)] = bad
	for key in saved.state.objective:
		var bad := saved.duplicate(true)
		bad.state.objective.erase(key)
		cases["missing objective." + str(key)] = bad
	var numeric_rank := saved.duplicate(true)
	numeric_rank.state.skills[numeric_rank.state.skills.keys()[0]] = 1.5
	cases["fractional skill rank"] = numeric_rank
	var too_many := saved.duplicate(true)
	too_many.state.skills.clear()
	for i in 5:
		too_many.state.skills[c.skills[i].id] = 1
	cases["five active slots"] = too_many
	var negative_time := saved.duplicate(true)
	negative_time.state.elapsed = -1.0
	cases["negative elapsed"] = negative_time
	var wrong_pending := saved.duplicate(true)
	wrong_pending.state.offered = ["unknown"]
	cases["unknown pending choice"] = wrong_pending
	var other_character := saved.duplicate(true)
	other_character.loadout.character_id = c.characters[1].id
	cases["legal alternate character substitution"] = other_character
	var other_branch := saved.duplicate(true)
	other_branch.loadout.branches = [1, 0, 0]
	cases["legal alternate branch substitution"] = other_branch
	var other_seed := saved.duplicate(true)
	other_seed.rng_seed = "712"
	cases["valid numeric initial seed substitution"] = other_seed
	var over := saved.duplicate(true)
	over.state.skills[over.state.skills.keys()[0]] = 6
	cases["skill level overflow"] = over
	# Rebuild a matching sidecar for semantic attacks: rejection must check decoded state,
	# not merely catch an out-of-date mirror tree.
	var codec = load("res://src/campaign/campaign_arena_codec.gd")
	for label in cases:
		if cases[label].get("state") is Dictionary and cases[label].has("numeric_bits"):
			cases[label].numeric_bits = codec.bits(cases[label].state)
	var missing_bits := saved.duplicate(true)
	missing_bits.numeric_bits.player.erase("hp")
	cases["numeric bits missing node"] = missing_bits
	var extra_bits := saved.duplicate(true)
	extra_bits.numeric_bits.player["extra"] = null
	cases["numeric bits extra node"] = extra_bits
	for special in ["f:000000000000f87f", "f:000000000000f07f"]:
		var bad := saved.duplicate(true)
		bad.numeric_bits.player.hp = special
		cases["numeric bits nonfinite " + special] = bad
	var mismatch := saved.duplicate(true)
	mismatch.state.player.hp -= 1.0
	cases["numeric mirror disagrees with bits"] = mismatch
	var negative_subnormal := saved.duplicate(true)
	negative_subnormal.state.player.hp = 0.0
	negative_subnormal.numeric_bits.player.hp = "f:0100000000000080"
	cases["decoded negative ULP across hp zero boundary"] = negative_subnormal
	for label in cases:
		var candidate = Arena.new()
		root.add_child(candidate)
		var input_before := canonical(cases[label])
		var accepted: bool = candidate.configure(c, m, loadout(c), 711, cases[label])
		expect(not accepted and not candidate.ready_for_play and candidate.snapshot().is_empty(), "reject without fresh run: " + label)
		expect(canonical(cases[label]) == input_before, "reject preserves supplied bytes: " + label)
		candidate.free()

func _test_pending_restore(c: Dictionary) -> void:
	var d := growth_fixture(c)
	var m: Dictionary = d.missions[0].duplicate(true)
	m.target_seconds = 900.0
	m.timeout_seconds = 1000.0
	install_mission(d, m)
	var a = make_arena(d, m)
	for i in 1800:
		a.advance(1.0 / 60.0, Vector2.ZERO)
		if not a.state.offered.is_empty():
			break
	expect(not a.state.offered.is_empty(), "real pending upgrade checkpoint reached")
	var saved: Dictionary = JSON.parse_string(canonical(a.snapshot()))
	var b = make_arena(d, m, 711, saved)
	var frozen := canonical(b.snapshot())
	for i in 100:
		b.advance(0.1, Vector2.RIGHT)
	expect(canonical(b.snapshot()) == frozen, "restored pending choice freezes RNG/ticks")
	var equal := true
	var first_bad := -1
	for i in 200:
		resolve_all(a)
		resolve_all(b)
		a.advance(1.0 / 60.0, Vector2.UP)
		b.advance(1.0 / 60.0, Vector2.UP)
		if canonical(a.snapshot()) != canonical(b.snapshot()):
			equal = false
			first_bad = i
			_save_difference("pending", a.snapshot(), b.snapshot())
			break
	expect(equal and a.state.tick == saved.state.tick + 200, "restored pending choice next200 same input/choice exact", {"first_divergence": first_bad, "tick": a.state.tick})
	a.free()
	b.free()

func _test_nonlexical_skill_restore(c: Dictionary) -> void:
	var d := growth_fixture(c)
	d.skills = [d.skills[6], d.skills[3]] # A07 first, then A04, deliberately nonlexical.
	d.tuning.cooldown_floor = 0.01
	d.skills[0].cooldown = 0.13
	d.skills[1].cooldown = 0.17
	d.characters[0].start_skill = d.skills[0].id
	d.passives = []
	d.evolutions = []
	d.tuning.xp_step = 1000000.0
	var m: Dictionary = d.missions[0].duplicate(true)
	m.target_seconds = 900.0
	m.timeout_seconds = 1000.0
	install_mission(d, m)
	var a = make_arena(d, m)
	for i in 1800:
		a.advance(1.0 / 60.0, Vector2.ZERO)
		if not a.state.offered.is_empty():
			break
	var second := str(d.skills[1].id)
	expect(a.state.offered.has(second) and a.choose_upgrade(second), "nonlexical A07 then A04 legally acquired")
	expect(a.state.skills.keys() == [str(d.skills[0].id), second], "live skill insertion order is nonlexical", a.state.skills.keys())
	var same_due := false
	for i in 400:
		if float(a.state.cooldowns.get(d.skills[0].id, 0)) <= 1.0 / 60.0 and float(a.state.cooldowns.get(second, 0)) <= 1.0 / 60.0:
			same_due = true
			break
		a.advance(1.0 / 60.0, Vector2.ZERO)
	expect(same_due, "both acquired skills naturally due on next tick", a.state.cooldowns)
	var raw: Dictionary = a.snapshot()
	var sorted_save: Dictionary = JSON.parse_string(canonical(raw))
	expect(Arena.validate_snapshot(d, m, raw), "nonlexical raw checkpoint valid")
	expect(load("res://src/campaign/campaign_arena_codec.gd").valid(sorted_save.state, sorted_save.numeric_bits), "nonlexical numeric mirror roundtrip valid", _mirror_errors(sorted_save.state, sorted_save.numeric_bits))
	var raw_file := FileAccess.open(EVIDENCE + "qa-nonlexical-input.json", FileAccess.WRITE)
	raw_file.store_string(JSON.stringify({"catalog": d, "mission": m, "snapshot": raw}, "\t", true, true))
	raw_file.close()
	var b = make_arena(d, m, 711, sorted_save)
	var equal := true
	var first_bad := -1
	for i in 200:
		resolve_all(a)
		resolve_all(b)
		var move := Vector2(cos(i * 0.01), sin(i * 0.01))
		a.advance(1.0 / 60.0, move)
		b.advance(1.0 / 60.0, move)
		if canonical(a.snapshot()) != canonical(b.snapshot()):
			equal = false
			first_bad = i
			_save_difference("nonlexical", a.snapshot(), b.snapshot())
			break
	expect(equal and a.state.tick == raw.state.tick + 200, "nonlexical simultaneous cooldown JSON restore next200 exact", {"first_divergence": first_bad, "before_keys": raw.state.skills.keys(), "json_keys": sorted_save.state.skills.keys()})
	a.free()
	b.free()

func _save_difference(label: String, a: Dictionary, b: Dictionary) -> void:
	var f := FileAccess.open(EVIDENCE + "qa-diff-" + label + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"live": a, "restored": b}, "\t", true, true))
	f.close()

func _mirror_errors(value: Variant, encoded: Variant, path: String = "state") -> Array:
	var errors: Array = []
	if value is Dictionary and encoded is Dictionary:
		for key in value:
			errors.append_array(_mirror_errors(value[key], encoded.get(key), path + "." + str(key)))
	elif value is Array and encoded is Array:
		for i in value.size():
			errors.append_array(_mirror_errors(value[i], encoded[i], path + "[%d]" % i))
	elif not load("res://src/campaign/campaign_arena_codec.gd").valid(value, encoded):
		errors.append({"path": path, "mirror": JSON.stringify(value, "", true, true), "bits": encoded})
	return errors
