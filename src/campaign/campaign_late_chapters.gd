extends RefCounted
## ADR-0012: chapters four-eight share durable encounter counters, not another clock.
const FORMAT := "CAMPAIGN_LATE_CHAPTERS_V1"
const PATTERNS := ["mirror","dive","spore_tide","anchors","seals","nexus"]

## Completing the matching stable target stops future field emission, not live warnings.
static func field_closed(m: Dictionary, s: Dictionary, index: int) -> bool:
	return m.get("late_close_fields",false) and m.target_ids[index] in s.objective.completed_ids

## Phase changes happen at actual damage time, including post-AI damage.
static func damage(a, e: Dictionary, before: float) -> void:
	if e.hp <= 0: return
	var phase := mini(2,int((1.0-maxf(0,e.hp)/e.max_hp)*3.0))
	if e.family == "boss" and a.mission.has("late_boss"):
		if phase > int(e.phase):
			a.drop_xp(a.player_world_position(),float(a.mission.late_boss.phase_xp)*(phase-int(e.phase)))
			e.phase = phase
			e.timer = 0.0
	elif e.target_id == a.mission.id+":HUNT" and a.mission.has("late_hunt_xp"):
		var previous := mini(2,int((1.0-maxf(0,before)/e.max_hp)*3.0))
		if phase > previous: a.drop_xp(a.player_world_position(),float(a.mission.late_hunt_xp)*(phase-previous))

## All attacks reserve their entire zone and projectile capacity before any mutation.
static func boss(a, e: Dictionary, target: Vector2) -> void:
	if e.hp <= 0 or a.state.player.hp <= 0 or e.timer > 0: return
	var cfg: Dictionary = a.mission.late_boss
	var phase := int(e.phase)
	var count := 3+phase
	var shots := (10+phase*4) if cfg.pattern == "nexus" else 0
	var zones := 1 if cfg.pattern == "nexus" else count
	if a.state.zones.size()+zones > 128 or a.state.projectiles.size()+shots > mini(400,int(a.tuning.projectile_cap)): return
	e.timer = float(cfg.cooldown_ticks)/60.0
	var side := -1.0 if e.aim < 0 else 1.0
	e.aim = -side
	var warn := float(cfg.warning_ticks)/60.0
	var q: Vector2 = a.pos(e)
	var aim := (target-q).normalized()
	for i in zones:
		var at: Vector2 = target+Vector2((i-float(count-1)/2.0)*float(cfg.spacing),side*70)
		var kind := "blast"
		var duration := 0.3
		var radius := float(cfg.radius)
		if cfg.pattern == "dive": at=q+aim.orthogonal()*(i-float(count-1)/2.0)*float(cfg.spacing); kind="line"
		elif cfg.pattern == "spore_tide": at=q+Vector2.from_angle(TAU*i/count+side)*220; kind="poison"; duration=2.0
		elif cfg.pattern == "anchors": at=q+Vector2.from_angle(TAU*i/count)*180; kind="ring"; radius=100
		elif cfg.pattern == "seals": at=target+Vector2.from_angle(TAU*i/count)*220; kind="line"; radius=20
		elif cfg.pattern == "nexus": at=q; kind="ring"; radius=180+phase*40
		var z: Dictionary = a.Combat.zone(a,at,radius,e.damage,duration,e.color,kind,true,warn)
		if kind == "line":
			z.angle = aim.angle() if cfg.pattern == "dive" else TAU*i/count+PI
			z.length = float(cfg.length) if cfg.pattern == "dive" else 300.0
	# Leave an aimed two-shot gap. Projectile delay is part of its persisted schema.
	for i in shots:
		var angle := aim.angle()+TAU*float(i+1)/float(shots+2)
		var p: Dictionary = a.Combat.projectile(a,q,Vector2.from_angle(angle)*float(cfg.projectile_speed),e.damage,9,5,e.color,"straight",1,0,true)
		p.delay = warn

## Strict authored vocabulary; shared Encounter validates layouts and stage bounds.
static func valid_definition(m: Dictionary) -> bool:
	if m.get("late_chapter") != true or not (m.get("chapter") is int or m.get("chapter") is float) or m.chapter < 4 or m.chapter > 8 or m.chapter != floorf(m.chapter): return false
	if m.get("chapter_c",false) or m.get("chapter_two",false) or m.get("chapter_three",false): return false
	for key in ["late_hint","late_hint_en","late_hazard_color"]:
		if not m.get(key) is String or m[key].is_empty(): return false
	if m.kind == "HUNT":
		if m.get("hunt_enemy_id") != "S1-E%02d" % int(m.chapter) or m.get("late_hunt_xp") != 10: return false
	elif m.has("hunt_enemy_id") or m.has("late_hunt_xp"): return false
	if m.kind == "BREAK":
		if m.get("late_close_fields") != true or m.target_count != 3: return false
	elif m.has("late_close_fields"): return false
	if m.kind == "ESCORT":
		if m.get("rest_waypoint") != 2 or m.get("late_waypoint_xp") != 12: return false
	elif m.has("rest_waypoint") or m.has("late_waypoint_xp"): return false
	if m.kind == "BOSS":
		var b: Variant = m.get("late_boss")
		if not b is Dictionary or b.size()!=8 or not b.get("pattern") in PATTERNS: return false
		var expected := {"warning_ticks":90,"cooldown_ticks":180,"phase_xp":18,"radius":55,"spacing":150,"length":700,"projectile_speed":150}
		if b.pattern == "dive": expected.radius=28; expected.cooldown_ticks=210
		if b.pattern in ["anchors","seals"]: expected.cooldown_ticks=240; expected.warning_ticks=120
		for key in expected:
			if b.get(key) != expected[key]: return false
		var id := int(m.boss_id.trim_prefix("S1-B"))
		if id < 4 or id > 9 or b.pattern != PATTERNS[id-4]: return false
	elif m.has("late_boss"): return false
	return true

## Target identities and source-bound zones are checked even after terminal snapshots.
static func valid_state(m: Dictionary,s: Dictionary,l: Dictionary) -> bool:
	if m.kind in ["BREAK","HUNT","BOSS"]:
		if s.target_deaths.size()!=s.objective.completed_ids.size(): return false
		for id in s.target_deaths:
			if not id in s.objective.completed_ids: return false
		for id in m.target_ids:
			var live := 0
			for e in s.entities:
				if e.target_id != id: continue
				live += 1
				if m.kind == "BREAK":
					var ordinal: int = m.target_ids.find(id)
					if e.family != "target" or e.ordinal != ordinal or e.max_hp != m.target_hp: return false
				if m.kind == "HUNT" and (e.id != m.hunt_enemy_id or e.family != "elite"): return false
				if m.kind == "BOSS" and (e.id != m.boss_id or e.family != "boss"): return false
			if live != (0 if id in s.objective.completed_ids else 1): return false
	for e in s.entities:
		if e.family == "boss" and (e.id != m.boss_id or e.phase != mini(2,int((1.0-maxf(0,e.hp)/e.max_hp)*3.0)) or not [0.0,-1.0,1.0].has(e.aim)): return false
	var seen := {}
	for z in s.zones:
		if not z.has("late_field"): continue
		var i: Variant = z.late_field
		if not (i is int or i is float) or i!=floorf(i) or i<0 or i>=l.roots.size() or seen.has(int(i)): return false
		seen[int(i)]=true
		var row: Dictionary=l.roots[int(i)]
		if not z.hostile or z.kind!="poison" or z.x!=row.center[0] or z.y!=row.center[1] or z.radius!=row.radius or z.damage!=row.damage or z.duration!=float(row.active_ticks)/60.0: return false
	if m.has("rest_waypoint") and (s.event_done or s.event_id!="") and s.objective.waypoint<m.rest_waypoint: return false
	return true
