extends SceneTree
## Independent acceptance probe: synthetic short/low-HP configs, NOT production balance
## or a complete campaign playthrough. Never writes Arena state or settlement flags.
const Arena = preload("res://src/campaign/campaign_arena.gd")
var EVIDENCE: String = preload("res://tests/fixtures/campaign_evidence.gd").create("campaign-qa")
var failures := 0
var checks := 0
var observations: Array = []

func _initialize() -> void:
	_run.call_deferred()

func expect(ok: bool, label: String, detail: Variant = {}) -> void:
	checks += 1
	observations.append({"case": label, "pass": ok, "detail": detail})
	if not ok:
		failures += 1
		push_error("QA_CAMPAIGN " + label + " " + str(detail))

func finish(suite: String) -> void:
	var result := {"suite": suite, "engine": Engine.get_version_info().string, "checks": checks, "failures": failures,
		"scope": "Headless synthetic short/low-HP acceptance; not production balance, 64 mission completion, device or release evidence", "cases": observations}
	if suite in ["production-chapter", "production-sequential"]:
		result.scope = "Unmodified production catalog bot diagnosis; independent prescribed unlock counts; not player playtest, sequential profile clear, 20h or release evidence"
	if suite == "production-sequential":
		result.scope = "Unmodified production catalog, real new-profile sequential unlock, actual rewards and legal branch purchases; not human playtime or release evidence"
	var f := FileAccess.open(EVIDENCE + "qa-" + suite + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "\t"))
	f.close()
	print("QA_CAMPAIGN_%s_%s checks=%d failures=%d" % [suite.to_upper(), "PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func catalog_fixture() -> Dictionary:
	var path := "res://assets/config/campaign_game.json"
	if not FileAccess.file_exists(path):
		expect(false, "catalog is available")
		return {}
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	return c

func loadout(c: Dictionary) -> Dictionary:
	return {"character_id": c.characters[0].id, "difficulty": 0, "branches": [0, 0, 0], "pill_id": "", "completed": 64}

func short_catalog(c: Dictionary) -> Dictionary:
	var result := c.duplicate(true)
	result.tuning.player_hp = 10000.0
	result.tuning.event_interval = 100000.0
	result.tuning.event_time = 100000.0
	result.tuning.spawn_interval = 10.0
	for group in ["enemies", "elites", "bosses"]:
		for row in result.get(group, []):
			row.hp = 2.0
			row.damage = 0.1
	return result

func short_mission(original: Dictionary) -> Dictionary:
	var m := original.duplicate(true)
	m.target_seconds = 0.5
	m.hold_seconds = 0.5
	m.timeout_seconds = 120.0
	m.target_hp = 2.0 if m.kind == "BREAK" else 10000.0
	m.escort_hp = 10000.0
	m.escort_speed = 120.0
	m.spawn_interval = 10.0
	var points: Array = []
	for i in int(m.target_count):
		points.append([120.0 + 65.0 * i, 0.0])
	m.target_positions = points
	return m

## All production chapters now have encounters. Keep the generic objective matrix
## on explicitly preserved undecorated fixtures; full_journey tests real missions.
func generic_mission(_c: Dictionary, kind: String = "") -> Dictionary:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/campaign_generic_missions.json"))
	for row in fixture.missions:
		if kind == "" or row.kind == kind: return row.duplicate(true)
	return {}

func make_arena(c: Dictionary, m: Dictionary, seed_value: int = 711, saved: Dictionary = {}):
	var a = Arena.new()
	root.add_child(a)
	var configured: bool = a.configure(c, m, loadout(c), seed_value, saved)
	expect(configured, "configure " + str(m.id))
	if not configured:
		quit(1)
	return a

func resolve(a) -> void:
	if not a.state.get("offered", []).is_empty():
		var id := str(a.state.offered[0])
		expect(a.choose_upgrade(id), "legal persisted choice", id)
	elif a.state.get("event_id", "") != "":
		expect(a.choose_event(false), "legal safe event")

func resolve_all(a) -> void:
	# A burst of earned levels can legitimately keep presenting choices without a tick.
	# Drain the same legal choices on both branches before counting a simulation tick.
	for i in 120:
		if a.state.get("offered", []).is_empty() and a.state.get("event_id", "") == "":
			break
		resolve(a)

func movement_to_objective(a, m: Dictionary) -> Vector2:
	var player: Vector2 = Arena.pos(a.state.player)
	var target := Vector2.ZERO
	if m.kind == "ESCORT":
		target = Arena.pos(a.state.objective)
	else:
		var index := mini(int(a.state.objective.get("waypoint", a.state.objective.get("index", 0))), m.target_positions.size() - 1)
		if index >= 0:
			target = Vector2(m.target_positions[index][0], m.target_positions[index][1])
		if m.kind in ["HUNT", "BOSS", "BREAK"]:
			for entity in a.state.get("entities", []):
				if entity.get("target_id", "") != "":
					target = Arena.pos(entity)
					break
	if m.kind == "SURVIVE" and float(a.state.elapsed) < float(m.target_seconds) + 0.05:
		target = Vector2(-150.0, 0.0)
	var offset := target - player
	return offset.normalized() if offset.length() > 12.0 else Vector2.ZERO

func _run() -> void:
	var c := catalog_fixture()
	if c.is_empty():
		finish("journey")
		return
	if "--qa-production-chapter" in OS.get_cmdline_user_args() or "--qa-production-all" in OS.get_cmdline_user_args() or "--qa-production-evolution" in OS.get_cmdline_user_args() or "--qa-production-sequential" in OS.get_cmdline_user_args():
		await _run_production_chapter(c)
		return
	if "--qa-root-only" in OS.get_cmdline_user_args():
		await _test_root_disk(c)
		finish("root-only")
		return
	var short := short_catalog(c)
	for kind in ["SURVIVE", "ESCORT", "HUNT", "CLEANSE", "BREAK", "BOSS"]:
		var base := generic_mission(c, kind)
		var m: Dictionary = short_mission(base) if not base.is_empty() else {}
		expect(not m.is_empty(), "objective fixture exists " + kind)
		if m.is_empty():
			continue
		install_mission(short, m)
		var a = make_arena(short, m)
		var idle = make_arena(short, m)
		# Inert elapsed-only implementation must fail spatial objective acceptance.
		for i in 90:
			idle.advance(1.0 / 60.0, Vector2.ZERO)
		if kind in ["SURVIVE", "ESCORT", "CLEANSE"]:
			expect(not idle.state.victory, kind + " cannot win by time alone away from objective")
		idle.free()
		for i in 7200:
			if a.state.finished:
				break
			resolve(a)
			a.advance(1.0 / 60.0, movement_to_objective(a, m))
		expect(a.state.finished and a.state.victory, "actual advance objective " + kind,
			{"objective": a.state.objective, "stats": a.stats(), "reason": a.state.reason, "player": a.state.player})
		expect(a.state.tick > 0, kind + " consumed simulation ticks")
		expect(Arena.validate_snapshot(short, m, JSON.parse_string(JSON.stringify(a.snapshot(), "", true, true))), kind + " actual terminal snapshot validates")
		a.free()
	_test_active_effects(c)
	_test_passive_consumption(c)
	_test_build_and_events(c)
	await _test_root_disk(c)
	finish("journey")

func bind_fixture(c: Dictionary) -> void:
	# Synthetic catalog gets its own explicit identity, never the production hash.
	c.erase("content_hash")
	var normalized: Dictionary = JSON.parse_string(JSON.stringify(c, "", true, true))
	c.clear()
	c.merge(normalized)
	c["content_hash"] = JSON.stringify(c, "", true, true).sha256_text()

func growth_fixture(c: Dictionary) -> Dictionary:
	var d := short_catalog(c)
	d.tuning.xp_base = 0.01
	d.tuning.xp_step = 0.0
	d.tuning.pickup_radius = 3000.0
	# This synthetic standing growth fixture owns attraction, independent of mission balance.
	for mission in d.missions:
		mission.erase("pickup_attract_radius")
		mission.erase("pickup_attract_speed")
	d.tuning.spawn_interval = 0.12
	d.characters[0].passive_stat = "pickup_radius"
	d.characters[0].passive_amount = 100.0
	for skill in d.skills:
		skill.damage = 1000.0
		skill.range = 2400.0
		skill.speed = 4000.0
		skill.cooldown = 0.1
	bind_fixture(d)
	return d

func _test_build_and_events(c: Dictionary) -> void:
	var d := growth_fixture(c)
	var m: Dictionary = generic_mission(d, "SURVIVE")
	if m.is_empty():
		expect(false, "generic SURVIVE fixture exists")
		return
	m.target_seconds = 900.0
	m.timeout_seconds = 1000.0
	install_mission(d, m)
	var a = make_arena(d, m)
	var choices := 0
	var ranks_ok := true
	var capacities_ok := true
	var offers_ok := true
	var frozen_checked := false
	var recipes: Dictionary = {}
	for recipe in d.evolutions:
		recipes[recipe.id] = recipe
	for i in 12000:
		if a.state.finished:
			break
		if not a.state.offered.is_empty():
			offers_ok = offers_ok and a.state.offered.size() <= 3 and a.state.offered.size() == _unique(a.state.offered).size()
			if not frozen_checked:
				var frozen := JSON.stringify(a.snapshot(), "", true, true)
				for j in 100:
					a.advance(0.1, Vector2.RIGHT)
				expect(JSON.stringify(a.snapshot(), "", true, true) == frozen, "pending upgrade freezes RNG and all work")
				frozen_checked = true
			for id in a.state.offered:
				if recipes.has(id):
					var recipe: Dictionary = recipes[id]
					expect(int(a.state.skills.get(recipe.skill_id, 0)) >= int(recipe.required_skill_level) and int(a.state.passives.get(recipe.passive_id, 0)) >= int(recipe.required_passive_level), "evolution respects both catalog rank prerequisites " + str(id), {"active": a.state.skills.get(recipe.skill_id, 0), "passive": a.state.passives.get(recipe.passive_id, 0)})
			var selected := str(a.state.offered[0])
			# Prefer own active ranks and matching auxiliary, then evolution.
			for id in a.state.offered:
				if a.state.skills.has(id):
					selected = id
				for recipe in d.evolutions:
					if a.state.skills.has(recipe.skill_id) and recipe.passive_id == id:
						selected = id
				if recipes.has(id):
					selected = id
					break
			expect(a.choose_upgrade(selected), "draft applies offered candidate " + selected)
			choices += 1
		for family in ["skills", "passives"]:
			capacities_ok = capacities_ok and a.state[family].size() <= 4
			for rank in a.state[family].values():
				ranks_ok = ranks_ok and int(rank) <= 5
		a.advance(1.0 / 60.0, Vector2.ZERO)
		if a.state.player.level >= 99:
			break
	expect(choices >= 40 and capacities_ok and ranks_ok and offers_ok, "real draft saturates without 4+4 or rank5 overflow", {"choices": choices, "skills": a.state.skills, "passives": a.state.passives})
	expect(frozen_checked, "actual upgrade trigger reached")
	expect(a.state.statistics.evolutions > 0 and not a.state.evolved.is_empty(), "actual evolution selected with rank5 active and auxiliary", a.state.evolved)
	a.free()
	var event_catalog := short_catalog(c)
	event_catalog.tuning.event_time = 0.05
	event_catalog.tuning.event_interval = 0.05
	install_mission(event_catalog, m)
	var safe = make_arena(event_catalog, m)
	var risk = make_arena(event_catalog, m)
	for i in 20:
		safe.advance(0.05, Vector2.ZERO)
		risk.advance(0.05, Vector2.ZERO)
	var pending := JSON.stringify(safe.snapshot(), "", true, true)
	expect(safe.state.event_id != "" and safe.state.event_id == risk.state.event_id, "same seeded event genuinely triggered")
	for i in 100:
		safe.advance(0.1, Vector2.RIGHT)
	expect(JSON.stringify(safe.snapshot(), "", true, true) == pending, "pending event freezes RNG and all work")
	expect(safe.choose_event(false) and risk.choose_event(true), "safe and risk legal resolution")
	expect(safe.state.player.hp != risk.state.player.hp or safe.state.modifiers != risk.state.modifiers or safe.state.entities.size() != risk.state.entities.size(), "safe/risk cause actual different resource or pressure", {"safe": safe.state.modifiers, "risk": risk.state.modifiers, "safe_hp": safe.state.player.hp, "risk_hp": risk.state.player.hp})
	var after := JSON.stringify(risk.snapshot(), "", true, true)
	expect(not risk.choose_event(true) and JSON.stringify(risk.snapshot(), "", true, true) == after, "event cannot be consumed twice")
	safe.free()
	risk.free()

func _unique(values: Array) -> Dictionary:
	var result := {}
	for value in values:
		result[value] = true
	return result

func _test_root_disk(c: Dictionary) -> void:
	var path := "res://src/campaign/campaign_game_root.gd"
	if not ResourceLoader.exists(path):
		expect(false, "root integration available")
		return
	var d := growth_fixture(c)
	d.missions[0] = short_mission(d.missions[0])
	# Reach a real draft before extraction; no state injection.
	d.missions[0].target_seconds = 8.0
	bind_fixture(d)
	var slots := [EVIDENCE + "qa-root-a.save", EVIDENCE + "qa-root-b.save"]
	for slot in slots:
		if FileAccess.file_exists(slot):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(slot))
	var game = load(path).new()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	if game.profile == null:
		expect(false, "root boots before injected isolated fixture", game.error)
		game.audio.shutdown()
		game.free()
		return
	var storage = load("res://src/persistence/save_system.gd").new()
	game.add_child(storage)
	expect(storage.initialize(slots[0], slots[1]) == 0, "root real double-slot storage initialize")
	game.catalog = d
	game.storage = storage
	game.profile = load("res://src/campaign/campaign_profile.gd").new()
	expect(game.profile.initialize(d, storage), "root injected synthetic catalog profile", game.profile.error)
	game.modal = ""
	expect(game.start_mission(0), "root begin real first mission")
	if game.arena == null:
		expect(false, "root arena created", game.error)
		game.audio.shutdown()
		game.free()
		return
	for i in 1800:
		game.arena.advance(1.0 / 60.0, Vector2.ZERO)
		game._sync_battle()
		if game.modal in ["upgrade", "error"] or game.arena == null:
			break
	expect(game.arena != null and game.modal == "upgrade", "root observes real pending upgrade")
	if game.arena == null or game.modal == "error":
		expect(false, "root snapshot persistence precondition", game.error)
		game.audio.shutdown()
		game.free()
		return
	var before: Dictionary = game.arena.snapshot()
	var live = Arena.new()
	root.add_child(live)
	var run_identity: Dictionary = game.profile.data.current_run
	expect(live.configure(d, d.missions[0], run_identity.loadout, int(run_identity.seed), before), "unserialized reference branch before disk exit")
	expect(game.save_and_home() and game.arena == null, "root save exit preserves unresolved choice")
	game.audio.shutdown()
	game.free()
	await process_frame
	game = load(path).new()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	storage = load("res://src/persistence/save_system.gd").new()
	game.add_child(storage)
	expect(storage.initialize(slots[0], slots[1]) == 0, "fresh storage reads actual disk")
	game.catalog = d
	game.storage = storage
	game.profile = load("res://src/campaign/campaign_profile.gd").new()
	expect(game.profile.initialize(d, storage), "fresh profile reads disk domain")
	game.modal = ""
	expect(game.continue_run(), "fresh root continues saved run")
	if game.arena == null:
		expect(false, "root restored arena", game.error)
		game.audio.shutdown()
		game.free()
		return
	expect(JSON.stringify(game.arena.snapshot(), "", true, true) == JSON.stringify(before, "", true, true), "exit/new root restores exact pending choice and RNG")
	var disk_equal := true
	var first_difference := -1
	for i in 200:
		resolve_all(live)
		for choice_index in 120:
			if game.modal == "upgrade":
				game.choose(str(game.arena.state.offered[0]))
			elif game.modal == "event":
				game.choose(false)
			else:
				break
		live.advance(1.0 / 60.0, Vector2.ZERO)
		game.arena.advance(1.0 / 60.0, Vector2.ZERO)
		game._sync_battle()
		if JSON.stringify(live.snapshot(), "", true, true) != JSON.stringify(game.arena.snapshot(), "", true, true):
			disk_equal = false
			first_difference = i
			var diff_file := FileAccess.open(EVIDENCE + "qa-diff-disk.json", FileAccess.WRITE)
			diff_file.store_string(JSON.stringify({"live": live.snapshot(), "disk": game.arena.snapshot()}, "\t", true, true))
			diff_file.close()
			break
	expect(disk_equal and live.state.tick == before.state.tick + 200, "real disk root resume next200 exact", {"first_divergence": first_difference})
	live.free()
	for i in 7200:
		if game.arena == null:
			break
		if game.modal == "upgrade":
			game.choose(str(game.arena.state.offered[0]))
		elif game.modal == "event":
			game.choose(false)
		if game.arena != null:
			game.arena.advance(1.0 / 60.0, movement_to_objective(game.arena, d.missions[0]))
			game._sync_battle()
	expect(game.arena == null and game.page == "result" and game.profile.data.completed == 1, "real first objective settles through root", game.last_result)
	if game.arena != null or game.profile.data.completed != 1:
		game.audio.shutdown()
		game.free()
		await process_frame
		return
	var settled: Dictionary = game.profile.data
	expect(game.profile.finish_run(true, {}).status == "ERROR" and game.profile.data == settled, "duplicate finish adds no rewards or unlocks")
	expect(game.start_mission(1), "actual first settlement unlocks next mission")
	expect(game.save_and_home(), "next mission clean save exit tears down input lifecycle")
	game.audio.shutdown()
	game.free()
	await create_timer(0.1).timeout

func install_mission(c: Dictionary, m: Dictionary) -> void:
	for i in c.missions.size():
		if c.missions[i].id == m.id:
			c.missions[i] = m.duplicate(true)
			break
	bind_fixture(c)

func _test_active_effects(c: Dictionary) -> void:
	# Individually start each catalog skill against a real configured marked target.
	# HP/speed are a fixture; geometry/timers/damage remain production code.
	for skill in c.skills:
		var d := short_catalog(c)
		d.characters[0].start_skill = skill.id
		d.tuning.spawn_interval = 100000.0
		for elite in d.elites:
			elite.hp = 10000.0
			elite.speed = 0.0
			elite.behavior = "chase"
		var hunt_base := generic_mission(c, "HUNT")
		var m: Dictionary = short_mission(hunt_base) if not hunt_base.is_empty() else {}
		if m.is_empty():
			expect(false, "generic HUNT fixture exists")
			return
		m.target_positions = [[85.0, 0.0]]
		install_mission(d, m)
		var a = make_arena(d, m)
		for i in 360:
			resolve(a)
			a.advance(1.0 / 60.0, Vector2.ZERO)
		var damage := float(a.stats().get("damage_dealt", 0))
		expect(damage > 0, "active real damage " + str(skill.id) + " " + str(skill.mode), {"damage": damage, "projectiles": a.state.projectiles.size(), "zones": a.state.zones.size()})
		a.free()

func _test_passive_consumption(c: Dictionary) -> void:
	var modes := {"duration": "roots", "projectile_speed": "fan", "summon_damage": "turret", "summon_range": "turret", "summon_duration": "turret", "chain_count": "chain", "return_damage": "return_arc", "slow_strength": "ice_arrow", "explosion_radius": "fireball", "control_damage": "roots", "charge_speed": "sword", "reflect_count": "shield", "trail_width": "winter", "mark_capacity": "ink", "mark_heal": "ink", "mark_spread": "ink"}
	for passive in c.passives:
		var pair: Array = []
		var acquired := true
		for enabled in [false, true]:
			var d := growth_fixture(c)
			# One legal passive card fixture avoids probabilistic coverage claims.
			d.passives = [passive.duplicate(true)]
			d.passives[0].amount = passive.amount if enabled else 0.0
			d.passives[0].unlock_after = 0
			d.evolutions = []
			var skill: Dictionary = d.skills[0]
			for row in d.skills:
				if row.mode == modes.get(passive.stat, "sword"):
					skill = row
					break
			# Keep production attack shape; only early XP comes from dedicated weak spawn.
			for original in c.skills:
				if original.id == skill.id:
					skill = original.duplicate(true)
			d.skills = [skill]
			d.characters[0].start_skill = skill.id
			d.tuning.spawn_interval = 100000.0
			for enemy_index in range(1, d.enemies.size()):
				d.enemies[enemy_index].hp = 600.0
				d.enemies[enemy_index].damage = 8.0
				if passive.stat in ["summon_range", "trail_width"]:
					d.enemies[enemy_index].speed = 0.0
					d.enemies[enemy_index].behavior = "chase"
			d.tuning.xp_step = 1000000.0
			d.tuning.pickup_radius = 70.0
			d.characters[0].passive_amount = 0.0
			var m: Dictionary = generic_mission(d, "SURVIVE")
			if m.is_empty():
				expect(false, "generic SURVIVE fixture exists")
				return
			m.target_seconds = 900.0
			m.timeout_seconds = 1000.0
			install_mission(d, m)
			var a = make_arena(d, m)
			# Spawn a test enemy via public factory; never alter arena state/finished.
			# The dedicated weak spawn is the hp-2 first table row, not the fixture
			# mission's enemy_ids[0] — generic missions may list a later 600hp row.
			a.spawn_enemy(str(d.enemies[0].id), Vector2(65, 0))
			for i in 1800:
				if not a.state.offered.is_empty():
					break
				a.advance(1.0 / 60.0, Vector2.ZERO)
			var selected: bool = a.state.offered.has(passive.id) and a.choose_upgrade(passive.id)
			acquired = acquired and selected
			pair.append(a)
		expect(acquired, "passive acquired through real XP/choice " + str(passive.id))
		if acquired:
			# Both arenas receive identical spatial stimuli, including contact/ranged threats.
			for a in pair:
				if passive.stat == "summon_range":
					a.spawn_enemy(str(c.enemies[1].id), Vector2(535, 0))
					continue
				if passive.stat == "trail_width":
					# Enemy radius18: center at114 is outside90+18, inside103.5+18.
					a.spawn_enemy(str(c.enemies[1].id), Vector2(0, 114))
					continue
				if passive.stat == "pickup_radius":
					a.spawn_enemy(str(c.enemies[0].id), Vector2(85, 0))
					continue
				for j in 12:
					a.spawn_enemy(str(c.enemies[j % c.enemies.size()].id), Vector2(35 + 45 * j, (j % 3 - 1) * 30))
			var changed := false
			for i in 420:
				for a in pair:
					a.advance(1.0 / 60.0, Vector2.RIGHT if i < 40 and passive.stat not in ["pickup_radius", "summon_range", "trail_width"] else Vector2.ZERO)
				# Exclude catalog/declared modifier totals: compare actual simulation output.
				var left: Dictionary = pair[0].snapshot().state.duplicate(true)
				var right: Dictionary = pair[1].snapshot().state.duplicate(true)
				left.erase("modifiers")
				right.erase("modifiers")
				if JSON.stringify(left, "", true, true) != JSON.stringify(right, "", true, true):
					changed = true
			expect(changed, "passive changes real simulation " + str(passive.id) + " " + str(passive.stat), {"zero_effect_stats": pair[0].stats(), "effect_stats": pair[1].stats(), "scope": "paired synthetic acquisition/stimulus; a failure can require a more targeted stimulus"})
		for a in pair:
			a.free()

func _run_production_chapter(c: Dictionary) -> void:
	var wins := 0
	var matrix: Array = []
	var sequential := "--qa-production-sequential" in OS.get_cmdline_user_args()
	var count := 64 if "--qa-production-all" in OS.get_cmdline_user_args() or sequential else 8
	var storage = null
	var profile = null
	var sequential_slots := [EVIDENCE + "qa-sequential-a.save", EVIDENCE + "qa-sequential-b.save"]
	if sequential:
		for slot in sequential_slots:
			if FileAccess.file_exists(slot):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(slot))
		storage = load("res://src/persistence/save_system.gd").new()
		expect(storage.initialize(sequential_slots[0], sequential_slots[1]) == 0, "new sequential real disk storage")
		profile = load("res://src/campaign/campaign_profile.gd").new()
		expect(profile.initialize(c, storage), "new sequential production profile")
		seed(711) # Deterministic seed source, not rewriting any persisted run identity.
	var indices: Array = range(count)
	if "--qa-production-evolution" in OS.get_cmdline_user_args():
		indices = [0, 7, 16, 32, 56]
	for mission_index in indices:
		var m: Dictionary = c.missions[mission_index]
		var options := loadout(c)
		options.completed = 64 if "--qa-production-evolution" in OS.get_cmdline_user_args() else mission_index
		var a = Arena.new()
		root.add_child(a)
		var initial_seed: int = 711 + int(mission_index)
		if sequential:
			# Only spend rewards already earned by prior real mission victories.
			for branch in [0, 1, 2]:
				if int(profile.data.branches[branch]) < 5:
					profile.purchase_branch(branch)
			var begun: Dictionary = profile.begin_run(mission_index)
			expect(begun.get("status") == "OK", "sequential actual unlock begins " + str(m.id), begun.get("reason", ""))
			if begun.get("status") != "OK":
				a.free()
				break
			options = begun.run.loadout
			initial_seed = int(begun.run.seed)
		var configured: bool = a.configure(c, m, options, initial_seed)
		expect(configured, "production mission config " + str(m.id))
		if not configured:
			a.free()
			continue
		var choices: Array = []
		var start := Time.get_ticks_msec()
		for i in int(float(m.timeout_seconds) * 60) + 120:
			if a.state.finished:
				break
			if not a.state.offered.is_empty():
				var selected := _bot_choice(a, c)
				if a.choose_upgrade(selected):
					choices.append(selected)
			elif a.state.event_id != "":
				a.choose_event(false)
			a.advance(1.0 / 60.0, _bot_direction(a, m, i))
			if i % 600 == 0:
				await process_frame
		var row := {"mission": m.id, "kind": m.kind, "seed": initial_seed, "victory": a.state.victory, "finished": a.state.finished, "reason": a.state.reason,
			"elapsed": a.state.elapsed, "wall_ms": Time.get_ticks_msec() - start, "stats": a.stats(), "player": a.state.player.duplicate(true), "objective": a.state.objective.duplicate(true), "skills": a.state.skills.duplicate(true), "passives": a.state.passives.duplicate(true), "choices": choices,
			"scope": "Unmodified production catalog, independent mission at prescribed unlock count; failures do not count as campaign progression"}
		if sequential:
			row.scope = "Unmodified production catalog, real new-profile sequential unlock and earned branch purchases"
			row.loadout = options
			if a.state.finished:
				var settled: Dictionary = profile.finish_run(bool(a.state.victory), a.stats())
				expect(settled.get("status") == "OK", "sequential actual outcome settles " + str(m.id), settled)
			row.persisted_completed = profile.data.completed
		matrix.append(row)
		if a.state.victory:
			wins += 1
		expect(a.state.finished and a.state.victory, "production bot objective " + str(m.id), row)
		print("QA_PRODUCTION_MISSION ", JSON.stringify(row))
		var f := FileAccess.open(EVIDENCE + ("qa-sequential-matrix.json" if sequential else "qa-production-matrix.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify({"catalog_hash": c.content_hash, "wins": wins, "attempted": matrix.size(), "matrix": matrix}, "\t"))
		f.close()
		a.free()
		if sequential:
			if not row.victory:
				break
			if (mission_index + 1) % 8 == 0:
				var before: Dictionary = profile.data
				storage.free()
				storage = load("res://src/persistence/save_system.gd").new()
				expect(storage.initialize(sequential_slots[0], sequential_slots[1]) == 0, "chapter checkpoint disk reload")
				profile = load("res://src/campaign/campaign_profile.gd").new()
				expect(profile.initialize(c, storage) and preload("res://src/campaign/campaign_arena_validation.gd").same_values(profile.data,JSON.parse_string(JSON.stringify(before,"",true,true))), "chapter checkpoint preserves real progression")
	if sequential:
		expect(profile.data.completed == 64 and profile.data.ending_seen, "real sequential 64 missions reach persistent ending", {"completed": profile.data.completed})
		storage.free()
	finish("production-sequential" if sequential else "production-chapter")

func _bot_choice(a, c: Dictionary) -> String:
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

func _bot_direction(a, m: Dictionary, tick_value: int) -> Vector2:
	# Clue hunts need their executable navigation target before a prey exists.
	if m.has("clues"): return preload("res://tests/fixtures/campaign_c_bot.gd").direction(a,m,tick_value)
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

func _segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var edge := end - start
	if edge.length_squared() <= 0.0001:
		return point.distance_to(start)
	return point.distance_to(start + edge * clampf((point - start).dot(edge) / edge.length_squared(), 0.0, 1.0))
