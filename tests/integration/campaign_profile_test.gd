extends SceneTree

const Profile = preload("res://src/campaign/campaign_profile.gd")
const Storage = preload("res://src/persistence/save_system.gd")

class FaultStorage extends Storage:
	var fail := false
	func commit_domain_after_images(images: Dictionary) -> int:
		return Status.IO_ERROR if fail else super.commit_domain_after_images(images)

class ReadbackFault extends Storage:
	var fail := false
	func _read_slot(path: String) -> Dictionary:
		var result := super._read_slot(path)
		if fail and result.get("valid", false):
			result.payload_sha256 = "mismatch"
		return result

var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func _catalog() -> Dictionary:
	var c := {"content_hash": "a".repeat(64), "missions": [], "characters": [{"id": "hero", "unlock_after": 0}, {"id": "sage", "unlock_after": 1}], "skills": [], "passives": [], "evolutions": [], "events": [], "pills": [{"id": "heal", "unlock_after": 0, "cost": 2, "stat": "max_hp", "amount": 10}], "achievements": [], "challenges": [], "tuning": {"progression_cost_base": 4, "progression_cost_step": 4, "profile_pill_cap": 99, "profile_replay_reward": 2, "profile_kills_per_page": 25, "profile_battle_reward_cap": 4, "profile_first_herbs": 3, "profile_kills_per_herb": 20, "profile_battle_herb_cap": 3}}
	for i in 64:
		c.missions.append({"id": "m%d" % i, "unlock_after": i, "reward": 8})
	for i in 60:
		c.achievements.append({"id": "a%d" % i, "unlock_after": 0, "rule": {"stat": "completed", "target": i + 1}})
	for i in 24:
		c.challenges.append({"id": "c%d" % i, "unlock_after": 0, "mission_id": "m0", "allow_pills": false, "reward": 10, "rule": {"stat": "challenge_wins", "id": "c%d" % i, "target": 1}})
	return c

func _expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN_PROFILE_ASSERT " + label)

func _run() -> void:
	var c := _catalog()
	var s := FaultStorage.new()
	s.initialize()
	var p := Profile.new()
	_expect(p.initialize(c, s) and not p.is_storage_locked(), "new independent domain")
	var original: Dictionary = p.data
	original.completed = 63
	_expect(p.data.completed == 0, "readers cannot mutate published state")
	_expect(not p.select_character("sage") and not p.set_difficulty(3), "locked character and invalid difficulty")
	_expect(not p.update_settings({"master": NAN}) and not p.update_settings({"unknown": 1}), "invalid settings")
	_expect(p.update_settings({"locale": "en", "music": 0.5, "reduce_motion": true}), "persist preferences")
	_expect(p.begin_run(1).status == "ERROR", "cannot skip prerequisites")
	_expect(p.begin_run(0).status == "OK", "begin mission")
	var first: Dictionary = p.data.current_run
	_expect(p.save_run({"elapsed": 1.25, "player": {"hp": 100}}), "checkpoint")
	var copy := Profile.new()
	_expect(copy.initialize(c, s), "session resume")
	_expect(copy.data.current_run.seed == first.seed and copy.data.current_run.run_id == first.run_id and copy.data.current_run.loadout == first.loadout and copy.data.current_run.snapshot.elapsed == 1.25, "resume metadata and snapshot")
	var result: Dictionary = copy.finish_run(true, {"kills": 40, "damage": 100})
	_expect(result.status == "OK" and result.first_clear and result.unlocks.has("sage"), "first clear and unlock")
	var settled: Dictionary = copy.data
	_expect(copy.finish_run(true, {}).status == "ERROR" and copy.data == settled, "duplicate finish adds nothing")
	p = copy
	_expect(p.cultivate("heal") and p.data.pills.heal == 1, "cultivation from earned herbs")
	_expect(p.begin_run(0, "heal").status == "OK" and p.data.pills.heal == 0, "pill debit atomic with run")
	_expect(p.finish_run(false, {}).status == "OK" and p.data.completed == 1 and p.data.pills.heal == 0, "failure retains progress no refund")
	_expect(p.begin_run(0).status == "OK", "replay")
	result = p.finish_run(true, {})
	_expect(not result.first_clear and p.data.completed == 1, "replay never increments progress")
	for i in range(1, 64):
		_expect(p.begin_run(i).status == "OK", "begin %d" % i)
		result = p.finish_run(true, {"kills": 40})
		_expect(result.status == "OK" and result.first_clear and p.data.completed == i + 1, "clear %d" % i)
	_expect(result.ending and p.data.ending_seen and p.data.achievements.size() == 60 and p.data.challenges.is_empty(), "64 missions ending and data driven awards")
	_expect(p.purchase_branch(0) and p.data.branches[0] == 1, "branch purchase")
	var before: Dictionary = p.data
	s.fail = true
	_expect(not p.purchase_branch(1) and p.is_storage_locked() and p.data == before, "IO failure does not publish")
	s.fail = false
	_expect(p.begin_run(0).status == "ERROR" and p.data == before, "IO failure blocks further navigation")
	s.free()
	_test_bad_domains(c, before)
	_test_disk(c)
	_test_boundaries(c)
	_test_challenges(c)
	_test_faults(c)
	_test_live_catalog()
	_test_event_rewards()
	_test_fullscreen()
	_test_fullscreen_migration()
	print("CAMPAIGN_PROFILE_%s checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_bad_domains(c: Dictionary, good: Dictionary) -> void:
	for key in ["schema", "completed", "branches", "settings", "pills", "current_run", "unknown_field", "stats"]:
		var bad := good.duplicate(true)
		bad[key] = {"schema": 2, "completed": 65, "branches": [0, 0, 6], "settings": {}, "pills": {"unknown": 1}, "current_run": {"run_id": 1}, "unknown_field": true, "stats": {"completed": 64}}[key]
		var s := Storage.new()
		s.initialize("", "", {"campaign_game": bad, "untouched": {"value": 7}})
		var before := s.profile_snapshot()
		var p := Profile.new()
		_expect(not p.initialize(c, s) and not p.error.is_empty(), "reject bad existing " + key)
		_expect(s.profile_snapshot() == before and not p.abandon_run(), "preserve bad domain " + key)
		s.free()

func _test_disk(c: Dictionary) -> void:
	var stem := OS.get_temp_dir() + "/campaign_profile_%d" % Time.get_ticks_usec()
	var a := stem + "_a.save"
	var b := stem + "_b.save"
	var s := Storage.new()
	s.initialize(a, b, {"untouched": {"legacy": 7}})
	var p := Profile.new()
	_expect(p.initialize(c, s) and p.begin_run(0).status == "OK", "real double slot begin")
	_expect(p.save_run({"elapsed": 3, "rng": "12345"}), "real checkpoint")
	var before: Dictionary = p.data
	s.free()
	s = Storage.new()
	_expect(s.initialize(a, b) == 0, "real reload")
	p = Profile.new()
	_expect(p.initialize(c, s) and p.data == before, "reload exact afterimage")
	_expect(p.save_run({"elapsed": 4}), "second durable checkpoint")
	s.free()
	var corrupt := FileAccess.open(b, FileAccess.WRITE)
	corrupt.store_string("corrupt newest slot")
	corrupt.close()
	s = Storage.new()
	_expect(s.initialize(a, b) == 0 and s.recovered_from_single_slot, "fallback from corrupt latest slot")
	p = Profile.new()
	_expect(p.initialize(c, s) and p.data == before, "previous durable checkpoint survives corrupt latest")
	var changed := c.duplicate(true)
	changed.content_hash = "b".repeat(64)
	var mismatch := Profile.new()
	_expect(not mismatch.initialize(changed, s), "catalog change rejects resumed run")
	_expect(p.abandon_run() and p.data.last_resolved_run_id == before.current_run.run_id, "abandon retires identity")
	_expect(s.profile_snapshot().domains.untouched.legacy == 7, "foreign domain preserved")
	s.free()
	for path in [a, b]:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string("bad")
		f.close()
	s = Storage.new()
	_expect(s.initialize(a, b) != 0, "corrupt storage refused")
	p = Profile.new()
	_expect(not p.initialize(c, s), "uninitialized corrupt storage not replaced")
	_expect(FileAccess.get_file_as_string(a) == "bad" and FileAccess.get_file_as_string(b) == "bad", "corrupt bytes retained")
	s.free()
	for path in [a, b]:
		DirAccess.remove_absolute(path)

func _test_boundaries(c: Dictionary) -> void:
	var s := Storage.new()
	s.initialize()
	var p := Profile.new()
	_expect(p.initialize(c, s), "boundary fixture")
	_expect(not p.purchase_branch(-1) and not p.purchase_branch(3) and not p.purchase_branch(0), "branch bounds and insufficient funds")
	_expect(not p.cultivate("heal") and not p.cultivate("unknown"), "cultivation funds and id")
	_expect(p.begin_run(0).status == "OK", "boundary begin")
	var before: Dictionary = p.data
	_expect(p.begin_run(0).status == "ERROR" and not p.save_run({"bad": Vector2.ZERO}) and not p.save_run({"bad": INF}), "active guard and JSON safety")
	var nested: Dictionary = {}
	for i in 34:
		nested = {"child": nested}
	_expect(not p.save_run(nested) and not p.save_run({"blob": "x".repeat(4194305)}), "snapshot depth and byte cap")
	_expect(p.finish_run(true, {"kills": -1}).status == "ERROR" and p.finish_run(true, {"level": 1.5}).status == "ERROR" and p.data == before, "invalid settlement unchanged")
	_expect(p.save_run({"elapsed": 5}), "last checkpoint")
	before = p.data
	var stale := Profile.new()
	stale.initialize(c, s)
	_expect(p.update_settings({"master": 0.2}), "another writer updates profile")
	_expect(not stale.save_run({"elapsed": 6}) and stale.data == before, "stale writer blocked")
	var result: Dictionary = p.finish_run(false, {"kills": 50, "elite_kills": 2, "boss_kills": 1, "evolutions": 2, "events_taken": 3, "damage_taken": 2.5, "elapsed": 12.5, "level": 7})
	_expect(result.status == "OK" and result.reward == 2 and p.data.completed == 0 and p.data.herbs == 2, "failure rewards actual contribution only")
	_expect(p.data.stats.total_kills == 50 and p.data.stats.max_level == 7 and p.data.stats.damage_taken == 2.5 and p.data.stats.events_taken == 3 and p.data.stats.total_runs == 1 and p.data.stats.victories == 0, "Arena stats aliases")
	for i in 10:
		p.begin_run(i)
		p.finish_run(true, {"kills": 100})
	for i in 5:
		var pages: int = p.data.pages
		_expect(p.purchase_branch(0) and p.data.pages == pages - 4 * (i + 1), "branch exact escalating price")
	_expect(not p.purchase_branch(0), "branch max five")
	var cap_catalog := c.duplicate(true)
	cap_catalog.tuning.profile_pill_cap = 1
	var capped := Profile.new()
	_expect(capped.initialize(cap_catalog, s) and capped.cultivate("heal"), "pill cap fixture")
	before = capped.data
	_expect(not capped.cultivate("heal") and capped.data == before, "inventory cap no herb debit")
	_expect(capped.begin_run(0, "heal").status == "OK" and capped.abandon_run() and capped.data.pills.heal == 0, "abandon never refunds consumed pill")
	s.free()

func _test_faults(c: Dictionary) -> void:
	for operation in ["initialize", "begin", "snapshot", "finish", "abandon", "cultivate", "settings"]:
		var s := FaultStorage.new()
		s.initialize()
		var p := Profile.new()
		if operation != "initialize":
			p.initialize(c, s)
		if operation in ["snapshot", "finish", "abandon", "cultivate", "begin"]:
			p.begin_run(0)
			p.finish_run(true, {"kills": 40})
		if operation == "begin":
			p.cultivate("heal")
		if operation in ["snapshot", "finish", "abandon"]:
			p.begin_run(1)
			p.save_run({"elapsed": 3})
		var before: Dictionary = p.data
		var disk_before := s.profile_snapshot()
		s.fail = true
		var failed := false
		match operation:
			"initialize": failed = not p.initialize(c, s)
			"begin": failed = p.begin_run(0, "heal").status == "ERROR"
			"snapshot": failed = not p.save_run({"elapsed": 4})
			"finish": failed = p.finish_run(true, {"kills": 100}).status == "ERROR"
			"abandon": failed = not p.abandon_run()
			"cultivate": failed = not p.cultivate("heal")
			"settings": failed = not p.update_settings({"master": 0.1})
		_expect(failed and p.is_storage_locked() and p.data == before and s.profile_snapshot() == disk_before, "atomic IO rollback " + operation)
		s.free()
	var missing := Storage.new()
	var missing_stem := OS.get_temp_dir() + "/campaign_missing_%d" % Time.get_ticks_usec()
	missing.initialize(missing_stem + "/a", missing_stem + "/b")
	var unavailable := Profile.new()
	_expect(not unavailable.initialize(c, missing) and unavailable.data.is_empty() and missing.profile_snapshot().generation == 0, "real missing directory IO no publication")
	missing.free()
	var stem := OS.get_temp_dir() + "/campaign_readback_%d" % Time.get_ticks_usec()
	var a := stem + "_a.save"
	var b := stem + "_b.save"
	var s := ReadbackFault.new()
	s.initialize(a, b)
	var p := Profile.new()
	p.initialize(c, s)
	p.begin_run(0)
	var before: Dictionary = p.data
	s.fail = true
	_expect(p.finish_run(true, {}).status == "ERROR" and p.data == before and p.finish_run(true, {}).status == "ERROR", "uncertain readback locks before publication")
	s.free()
	var restart := Storage.new()
	restart.initialize(a, b)
	p = Profile.new()
	_expect(p.initialize(c, restart) and p.data.completed == 1 and p.data.current_run == null and p.finish_run(true, {}).status == "ERROR", "reload reconciles durable uncertain settlement once")
	restart.free()
	for path in [a, b]:
		DirAccess.remove_absolute(path)

func _test_live_catalog() -> void:
	var loader = load("res://src/campaign/campaign_catalog.gd")
	var c: Dictionary = loader.load_catalog()
	if c.is_empty():
		print("CATALOG_ERRORS ", loader.validate(JSON.parse_string(FileAccess.get_file_as_string("res://assets/config/campaign_game.json"))))
	var s := Storage.new()
	s.initialize()
	var p := Profile.new()
	if not p.initialize(c, s):
		_expect(false, "production catalog compatibility " + p.error)
		s.free()
		return
	for i in 64:
		var begin: Dictionary = p.begin_run(i)
		_expect(begin.status == "OK", "production begin %d" % i)
		if begin.status != "OK":
			break
		_expect(begin.run.content_hash == c.content_hash, "production content hash passthrough")
		var result: Dictionary = p.finish_run(true, {"level": 10, "kills": 200, "elite_kills": 5, "boss_kills": 1, "evolutions": 1, "events_taken": 1, "skills_used": [c.skills[0].id], "damage_taken": 2.25, "elapsed": 60.5})
		_expect(result.status == "OK", "production settlement %d" % i)
	_expect(p.data.completed == 64 and p.data.ending_seen and p.data.stats.total_kills == 12800 and p.data.stats.max_level == 10 and not p.is_storage_locked() and p.data.seen.has(c.skills[0].id), "production ending and Arena stats")
	for challenge in c.challenges:
		var index := -1
		for i in 64:
			if c.missions[i].id == challenge.mission_id:
				index = i
		var begin: Dictionary = p.begin_run(index, "", challenge.id)
		_expect(begin.status == "OK" and begin.run.loadout.challenge_id == challenge.id, "production challenge launch " + challenge.id)
		var result: Dictionary = p.finish_run(true, {})
		_expect(result.status == "OK" and result.reward == int(challenge.reward) + 2 and p.data.challenges.has(challenge.id), "production challenge receipt " + challenge.id)
	var evolution_ids: Array[String] = []
	for evolution in c.evolutions:
		evolution_ids.append(evolution.id)
	for character in c.characters:
		_expect(p.select_character(character.id), "production character select")
		p.begin_run(0)
		p.finish_run(true, {"evolutions": evolution_ids.size(), "evolution_ids": evolution_ids, "safe_choices": 1, "risk_choices": 1})
	_expect(p.cultivate(c.pills[0].id), "production pill culture")
	_expect(p.begin_run(0, c.pills[0].id).status == "OK", "production pill use")
	p.finish_run(true, {})
	_expect(p.data.challenges.size() == 24 and p.data.achievements.size() == 60, "production 24 actual challenges and all original 60 achievements reachable")
	s.free()

func _test_challenges(c: Dictionary) -> void:
	var catalog := c.duplicate(true)
	catalog.evolutions.append({"id": "evo", "unlock_after": 0})
	catalog.achievements.append({"id": "character_award", "unlock_after": 0, "rule": {"stat": "character_wins", "id": "hero", "target": 1}})
	catalog.achievements.append({"id": "evolution_award", "unlock_after": 0, "rule": {"stat": "evolution_ids", "id": "evo", "target": 1}})
	catalog.achievements.append({"id": "challenge_award", "unlock_after": 0, "rule": {"stat": "challenge_wins", "id": "c0", "target": 1}})
	var s := Storage.new()
	s.initialize()
	var p := Profile.new()
	_expect(p.initialize(catalog, s), "id rule catalog")
	p.begin_run(0)
	p.finish_run(true, {"kills": 100, "evolutions": 1, "evolution_ids": ["evo"]})
	_expect(p.data.achievements.has("character_award") and p.data.achievements.has("evolution_award") and not p.data.achievements.has("challenge_award"), "id based character evolution awards")
	p.cultivate("heal")
	_expect(p.begin_run(0, "heal", "c0").status == "ERROR" and p.data.pills.heal == 1, "challenge no pills no debit")
	_expect(p.begin_run(1, "", "c0").status == "ERROR", "challenge mission binding")
	for i in 24:
		var id := "c%d" % i
		var run: Dictionary = p.begin_run(0, "", id)
		_expect(run.status == "OK" and run.run.loadout.challenge_id == id, "play actual challenge")
		var result: Dictionary = p.finish_run(true, {})
		_expect(result.reward == 12 and p.data.stats.challenge_wins[id] == 1, "challenge first reward receipt")
	_expect(p.data.challenges.size() == 24 and p.data.achievements.has("challenge_award"), "24 completed actual challenges")
	p.begin_run(0, "", "c0")
	var result: Dictionary = p.finish_run(true, {})
	_expect(result.reward == 2 and p.data.stats.challenge_wins.c0 == 2, "challenge repeat no first prize")
	p.begin_run(0, "", "c0")
	p.finish_run(false, {})
	_expect(p.data.stats.challenge_wins.c0 == 2, "failed challenge no victory count")
	var reload := Profile.new()
	_expect(reload.initialize(catalog, s) and reload.data == p.data, "ID counts and challenge receipts resume")
	s.free()

func _test_event_rewards() -> void:
	var c := _catalog()
	c.events = [{"id": "encounter", "unlock_after": 0, "safe": {"reward": 8}, "risk": {"reward": 25}}, {"id": "locked_encounter", "unlock_after": 64, "safe": {"reward": 100}, "risk": {"reward": 200}}]
	for choice: String in ["safe", "risk"]:
		var s := FaultStorage.new()
		s.initialize()
		var p := Profile.new()
		_expect(p.initialize(c, s), "event fixture initialization " + choice)
		_expect(p.begin_run(0).status == "OK", "event run " + choice)
		var stats := {"kills": 25, "events_taken": 1, "safe_choices": 1 if choice == "safe" else 0, "risk_choices": 1 if choice == "risk" else 0, "event_reward": 8 if choice == "safe" else 25}
		var before: Dictionary = p.data
		var result := p.finish_run(true, stats)
		_expect(result.status == "OK" and result.reward == 9 + stats.event_reward and result.event_reward == stats.event_reward, "event bonus included in victory total " + choice)
		_expect(p.data.pages == before.pages + result.reward and p.data.current_run == null and p.data.stats[choice + "_wins"] == 1, "event and retirement share afterimage " + choice)
		var settled: Dictionary = p.data
		_expect(p.finish_run(true, stats).status == "ERROR" and p.data == settled, "duplicate event settlement cannot pay again " + choice)
		var resumed := Profile.new()
		_expect(resumed.initialize(c, s) and resumed.data == settled and resumed.finish_run(true, stats).status == "ERROR", "reloaded settled event remains consumed " + choice)
		p = resumed
		p.begin_run(0)
		before = p.data
		result = p.finish_run(false, stats)
		_expect(result.status == "OK" and result.reward == 1 and result.event_reward == 0 and p.data.pages == before.pages + 1, "defeat loses promised event bonus " + choice)
		p.begin_run(0)
		before = p.data
		var disk_before := s.profile_snapshot()
		s.fail = true
		_expect(p.finish_run(true, stats).status == "ERROR" and p.data == before and s.profile_snapshot() == disk_before and p.is_storage_locked(), "failed event commit rolls back money and retirement " + choice)
		s.fail = false
		resumed = Profile.new()
		_expect(resumed.initialize(c, s) and resumed.data.current_run != null, "failed event reload retains run " + choice)
		result = resumed.finish_run(true, stats)
		_expect(result.status == "OK" and result.reward == 3 + stats.event_reward and resumed.data.pages == before.pages + result.reward, "reconciled old state consumes event once " + choice)
		s.free()
	var s := Storage.new()
	s.initialize()
	var p := Profile.new()
	p.initialize(c, s)
	p.begin_run(0)
	var before: Dictionary = p.data
	for malformed: Variant in [-1, 1.5, true, "8", INF, 9007199254740992, 9, 100]:
		_expect(p.finish_run(true, {"event_reward": malformed, "safe_choices": 1, "risk_choices": 0, "events_taken": 1}).status == "ERROR" and p.data == before, "event invalid range/type rejected " + str(malformed))
	for invalid: Dictionary in [{"event_reward": 8}, {"event_reward": 8, "safe_choices": 1, "events_taken": 0}, {"event_reward": 25, "safe_choices": 1, "risk_choices": 1, "events_taken": 2}, {"event_reward": 0, "safe_choices": 2, "events_taken": 2}, {"event_reward": 8, "safe_choices": -1, "events_taken": 1}]:
		_expect(p.finish_run(true, invalid).status == "ERROR" and p.data == before, "inconsistent event counters rejected")
	s.free()

func _test_fullscreen() -> void:
	var c := _catalog()
	var s := FaultStorage.new()
	s.initialize()
	var p := Profile.new()
	_expect(p.initialize(c, s) and p.data.settings.fullscreen == false, "fullscreen defaults to windowed")
	_expect(p.update_settings({"fullscreen": true}) and p.data.settings.fullscreen == true, "fullscreen setting persisted")
	var restored := Profile.new()
	_expect(restored.initialize(c, s) and restored.data.settings.fullscreen == true, "fullscreen survives profile reload")
	p = restored
	for value: Variant in [0, 1, "true", null, [], {}]:
		var before: Dictionary = p.data
		_expect(not p.update_settings({"fullscreen": value}) and p.data == before, "fullscreen rejects non-boolean")
	var before: Dictionary = p.data
	s.fail = true
	_expect(not p.update_settings({"fullscreen": false}) and p.data == before and p.is_storage_locked(), "fullscreen commit failure retains last setting")
	s.fail = false
	restored = Profile.new()
	_expect(restored.initialize(c, s) and restored.data.settings.fullscreen == true, "fullscreen failure reload preserves disk setting")
	_expect(restored.update_settings({"fullscreen": false}) and restored.data.settings.fullscreen == false, "return to windowed persisted")
	s.free()

func _test_fullscreen_migration() -> void:
	var c := _catalog()
	for inject_failure: bool in [false, true]:
		var stem := OS.get_temp_dir().path_join("campaign_settings_upgrade_%d_%s" % [Time.get_ticks_usec(), str(inject_failure)])
		var paths := [stem + "_a.save", stem + "_b.save"]
		var s := FaultStorage.new()
		_expect(s.initialize(paths[0], paths[1], {"untouched": {"legacy": 7}}) == 0, "migration real disk initialize")
		var p := Profile.new()
		p.initialize(c, s)
		p.begin_run(0)
		p.finish_run(true, {"kills": 40})
		p.begin_run(1)
		p.save_run({"elapsed": 3.125, "offered": ["offered-choice"], "chosen": ["chosen-choice"], "rng_state": "982341"})
		var old: Dictionary = p.data
		old.settings.erase("fullscreen")
		_expect(s.commit_domain_after_images({Profile.DOMAIN: old}) == 0, "persist valid former six-setting profile")
		s.free()
		s = FaultStorage.new()
		_expect(s.initialize(paths[0], paths[1]) == 0, "read former settings from disk")
		var before := s.profile_snapshot()
		s.fail = inject_failure
		var migrated := Profile.new()
		var success := migrated.initialize(c, s)
		if inject_failure:
			_expect(not success and migrated.data.is_empty() and migrated.is_storage_locked() and s.profile_snapshot() == before, "migration write failure publishes no domain or progress")
			s.fail = false
			migrated = Profile.new()
			success = migrated.initialize(c, s)
		var expected := old.duplicate(true)
		expected.settings["fullscreen"] = false
		_expect(success and migrated.data == expected, "migration preserves all progress seed loadout and offered choices")
		_expect(s.profile_snapshot().generation == before.generation + 1 and s.profile_snapshot().domains.untouched.legacy == 7, "migration one transaction preserves foreign domain")
		s.free()
		s = FaultStorage.new()
		s.initialize(paths[0], paths[1])
		migrated = Profile.new()
		_expect(migrated.initialize(c, s) and migrated.data == expected, "migrated seven-setting profile reloads from disk")
		var generation: Variant = s.profile_snapshot().generation
		var again := Profile.new()
		_expect(again.initialize(c, s) and s.profile_snapshot().generation == generation, "migration is not repeated on reload")
		for variant: int in [0, 1, 2]:
			var invalid := old.duplicate(true)
			if variant == 0: invalid.settings.unknown = true
			elif variant == 1: invalid.settings.locale = 17
			else: invalid.settings.erase("master")
			s.commit_domain_after_images({Profile.DOMAIN: invalid})
			var bad := Profile.new()
			before = s.profile_snapshot()
			_expect(not bad.initialize(c, s) and bad.data.is_empty() and s.profile_snapshot() == before, "migration rejects corrupt or unknown settings")
		s.free()
		for path: String in paths:
			DirAccess.remove_absolute(path)
