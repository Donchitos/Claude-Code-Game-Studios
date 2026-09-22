extends SceneTree
## Real catalog, real movement/choices and real dual-slot restore. No player saves.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Encounter = preload("res://src/campaign/campaign_encounter.gd")
const Codec = preload("res://src/campaign/campaign_arena_codec.gd")
const Storage = preload("res://src/persistence/save_system.gd")
var checks := 0
var failures := 0
var c: Dictionary
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PACKAGE_B " + label)
func make_arena(index: int) -> Node2D:
	var a := Arena.new()
	root.add_child(a)
	check(a.configure(c, c.missions[index], {"character_id":"S1-C01", "completed":index, "branches":[0,0,0], "difficulty":0, "pill_id":"", "challenge_id":""}, 42), "configure")
	return a
func step(a, motion := Vector2.ZERO) -> void:
	if not a.state.offered.is_empty(): a.choose_upgrade(a.state.offered[0])
	if a.state.event_id != "": a.choose_event(false)
	a.advance(1.0 / 60, motion)
func _run() -> void:
	c = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	check(not c.is_empty(), "catalog")
	for index in [0,1,2,4]:
		var a := make_arena(index)
		for i in 180: step(a, Vector2.RIGHT)
		check(Arena.validate_snapshot(c, c.missions[index], a.snapshot()), "self snapshot")
		var stem := OS.get_temp_dir() + "/b_restore_%d_%d" % [index, Time.get_ticks_usec()]
		var s := Storage.new()
		s.initialize(stem+"a", stem+"b")
		check(s.commit_domain_after_images({"probe":a.snapshot()}) == 0, "real disk save")
		s.free()
		s = Storage.new()
		s.initialize(stem+"a", stem+"b")
		var saved: Dictionary = s.profile_snapshot().domains.probe
		var b := Arena.new()
		root.add_child(b)
		check(b.configure(c,c.missions[index],a.loadout,42,saved), "fresh storage restore")
		for i in 200:
			step(a, Vector2.DOWN)
			step(b, Vector2.DOWN)
		check(JSON.stringify(a.snapshot(), "", true, true) == JSON.stringify(b.snapshot(), "", true, true), "200 tick exact continuation")
		var corrupt: Dictionary = a.snapshot()
		corrupt.state.encounter.skipped = 9999
		corrupt.numeric_bits = Codec.bits(corrupt.state)
		check(not Arena.validate_snapshot(c,c.missions[index],corrupt), "semantic counter rejection")
		a.free()
		b.free()
		s.free()
		DirAccess.remove_absolute(stem+"a")
		if FileAccess.file_exists(stem+"b"): DirAccess.remove_absolute(stem+"b")
	var a := make_arena(0)
	var before: Dictionary = a.snapshot()
	a.advance(0, Vector2.RIGHT)
	check(a.snapshot() == before, "no clock on zero delta")
	for i in 1199: step(a)
	for e in a.state.entities: check(e.id == "S1-N01", "first teaching pool only chase")
	check(a.state.encounter.stage_ticks[1] == -1, "20s stage not early")
	step(a)
	check(a.state.encounter.stage_ticks[1] == 1200, "20s stage exact")
	var saved: Dictionary = a.snapshot()
	saved.state.encounter.stage_ticks[1] = -1
	saved.numeric_bits = Codec.bits(saved.state)
	check(not Arena.validate_snapshot(c,c.missions[0],saved), "retrigger forgery rejected")
	a.free()
	_test_wind_and_bounds()
	var roots := make_arena(4)
	step(roots)
	var root_snapshot: Dictionary = roots.snapshot()
	Encounter.advance(roots)
	check(roots.snapshot() == root_snapshot, "same tick root cannot repeat")
	root_snapshot.state.encounter.last_tick = 0
	root_snapshot.numeric_bits = Codec.bits(root_snapshot.state)
	check(not Arena.validate_snapshot(c,c.missions[4],root_snapshot), "wrong encounter commit tick rejected")
	roots.free()
	_test_invalid_definitions()
	print("PACKAGE_B_%s checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)

func _test_wind_and_bounds() -> void:
	var a := make_arena(1)
	a.set_pos(a.state.player,Vector2(-240,-180)) # Geometry fixture, not a playthrough.
	check(is_equal_approx(Encounter.wind_multiplier(a,Vector2.RIGHT),1.15), "forward wind")
	check(is_equal_approx(Encounter.wind_multiplier(a,Vector2.LEFT),0.9), "reverse wind")
	check(Encounter.wind_multiplier(a,Vector2.UP) == 1.0, "crosswind")
	var at: Vector2 = a.player_world_position()
	a.advance(1.0/60,Vector2.ZERO)
	check(a.player_world_position() == at, "wind never drifts idle player")
	for sector in 4:
		for i in 20:
			var q := Encounter.spawn_point(a,sector)
			check(not q.is_finite() or (q.distance_to(a.player_world_position()) >= a.mission.spawn_safe_radius and absf(q.x)<960 and absf(q.y)<640), "legal spawn candidate")
	while a.state.entities.size() < 180: a.spawn_enemy("S1-N01",Vector2(880,500))
	a.state.tick = 76
	a.state.elapsed = 76.0/60
	a.state.objective.elapsed = a.state.elapsed
	Encounter.advance(a)
	check(a.state.encounter.skipped > 0 and a.state.entities.size() == 180, "cap skips once")
	var snapshot: Dictionary = a.snapshot()
	check(Arena.validate_snapshot(c,c.missions[1],snapshot), "cap state can resume")
	var before := JSON.stringify(a.state.encounter)
	Encounter.advance(a)
	check(JSON.stringify(a.state.encounter) == before, "same tick schedule cannot spawn twice")
	a.free()
	var escort := make_arena(2)
	var origin: Vector2 = escort.pos(escort.state.objective)
	escort.set_pos(escort.state.player,Vector2(700,500))
	step(escort)
	check(escort.pos(escort.state.objective) == origin, "escort pauses out of range")
	escort.set_pos(escort.state.player,origin)
	step(escort)
	step(escort)
	check(escort.pos(escort.state.objective) != origin, "escort resumes on return")
	escort.free()

func _test_invalid_definitions() -> void:
	for mode in ["trigger","count","id","extra","layout","clock"]:
		var m: Dictionary = c.missions[0].duplicate(true)
		var config := c.duplicate(true)
		match mode:
			"trigger": m.encounter_stages[0].trigger = "CLUE_PROGRESS"
			"count": m.encounter_stages[0].rows[0].count = 9
			"id": m.encounter_stages[0].rows[0].enemy_ids = ["S1-N24"]
			"extra": m.encounter_stages[0].unknown = true
			"layout": config.scenes[0].layout.obstacles[0].radius = 101
			"clock": m.encounter_stages[0].rows[0].interval = 14
		check(not Encounter.valid_definition(config,m), "definition rejects " + mode)
