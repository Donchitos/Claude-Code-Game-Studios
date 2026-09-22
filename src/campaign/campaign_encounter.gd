extends RefCounted
## Arena-owned, bounded encounter schedule. All durable state lives in its snapshot.
const Chapter = preload("res://src/campaign/campaign_chapter_one.gd")
const Thermal = preload("res://src/campaign/campaign_chapter_two.gd")
const Tide = preload("res://src/campaign/campaign_chapter_three.gd")
const Late = preload("res://src/campaign/campaign_late_chapters.gd")
const FORMAT := "CAMPAIGN_CHAPTER1_V3"

## Layout resolution is by stable scene ID, never by mission ordinal.
static func schema(m: Dictionary) -> String:
	if m.get("late_chapter",false): return Late.FORMAT
	if m.get("chapter_three",false): return Tide.FORMAT
	return Thermal.FORMAT if m.get("chapter_two",false) else FORMAT

static func layout(c: Dictionary, m: Dictionary) -> Dictionary:
	for row in c.get("scenes", []):
		if row is Dictionary and row.get("id") == m.get("scene_layout_id"):
			return row.get("layout", {}) if row.get("layout") is Dictionary else {}
	return {}

## Reject unimplemented triggers, malformed rows, unsafe coordinates and excess capacity.
static func valid_definition(c: Dictionary, m: Dictionary) -> bool:
	if not m.has("scene_layout_id"): return not m.has("encounter_stages")
	if not c.get("scenes") is Array or not m.get("scene_layout_id") is String or m.scene_layout_id != m.get("scene_id"): return false
	if not m.get("enemy_ids") is Array or not integer(m.get("target_count"),1,16) or not m.get("kind") is String: return false
	if not m.get("chapter_c",false):
		for key in ["clues","clue_radius","hunt_retry_ticks","hunt_charge","event_ids","close_roots","boss_chapter"]:
			if m.has(key): return false
	if m.get("late_chapter",false):
		if not Late.valid_definition(m): return false
	elif m.get("chapter_two",false):
		if not Thermal.valid_definition(m): return false
	elif m.get("chapter_three",false):
		if not Tide.valid_definition(m): return false
	elif m.has("furnace_boss") or m.has("thermal_anchors") or m.has("rest_waypoint") or m.has("tide_boss") or m.has("tide_flats") or (m.has("hunt_enemy_id") and not m.get("chapter_c",false)): return false
	var l := layout(c, m)
	if not keys(l,["start","route","obstacles","winds","roots"]): return false
	if l.is_empty() or not l.get("obstacles") is Array or l.obstacles.size() > 16: return false
	if not point(l.get("start")) or not l.get("route") is Array or l.route.size() < 2 or l.route.size() > 8: return false
	for q in l.route:
		if not point(q): return false
	for rock in l.obstacles:
		if not rock is Dictionary or not keys(rock,["x","y","radius"]) or not point([rock.get("x"),rock.get("y")]) or not number(rock.get("radius"),1,100): return false
	if not l.get("winds") is Array or l.winds.size() > 4 or not l.get("roots") is Array or l.roots.size() > 3: return false
	var last := ""
	for w in l.winds:
		if not w is Dictionary or not w.get("id") is String or w.id <= last: return false
		if not keys(w,["id","center","size","direction","forward","backward"]): return false
		last = w.id
		if not point(w.get("center")) or not point(w.get("size")) or float(w.size[0]) <= 0 or float(w.size[1]) <= 0: return false
		if absf(w.center[0])+float(w.size[0])/2 > 935 or absf(w.center[1])+float(w.size[1])/2 > 615: return false
		if not number(w.get("direction"),-1,1) or absf(float(w.direction)) != 1: return false
		if not number(w.get("forward"),1,1.5) or not number(w.get("backward"),0.5,1): return false
	for r in l.roots:
		if not r is Dictionary or not point(r.get("center")) or not number(r.get("radius"),1,100): return false
		if not keys(r,["center","radius","warning_ticks","active_ticks","rest_ticks","offset_ticks","damage"]): return false
		for k in ["warning_ticks","active_ticks","rest_ticks"]:
			if not integer(r.get(k),1,3600): return false
		if not integer(r.get("offset_ticks"),0,3600) or not number(r.get("damage"),0,100): return false
	if not integer(m.get("wind_start_tick"),0,60000) or not m.get("tutorial") is bool: return false
	if not m.get("encounter_stages", []) is Array or m.get("encounter_stages", []).size() > 16: return false
	var seen := {}
	for stage in m.get("encounter_stages", []):
		if not stage is Dictionary or not keys(stage,["id","trigger","value","rows"]) or not stage.get("id") is String or stage.id.is_empty() or seen.has(stage.id): return false
		seen[stage.id] = true
		if stage.get("trigger") not in ["ACTIVE_TICK","ANCHOR_PROGRESS","WAYPOINT","CLUE_PROGRESS","CLEANSE_HALF"] or not integer(stage.get("value"),0,60000): return false
		if stage.trigger == "ANCHOR_PROGRESS" and (m.kind != "BREAK" or stage.value >= m.target_count): return false
		if stage.trigger == "WAYPOINT" and (m.kind != "ESCORT" or stage.value >= m.target_count): return false
		if not stage.get("rows") is Array or stage.rows.is_empty() or stage.rows.size() > 4: return false
		for row in stage.rows:
			if not row is Dictionary or not integer(row.get("count"),1,8) or not integer(row.get("interval"),15,3600) or not integer(row.get("offset"),0,3600) or not integer(row.get("sector"),0,3): return false
			if not keys(row,["enemy_ids","sector","count","interval","offset"]): return false
			if not row.get("enemy_ids") is Array or row.enemy_ids.is_empty() or row.enemy_ids.size() > 3: return false
			for id in row.enemy_ids:
				if not id is String or not id in m.enemy_ids+m.get("elite_ids",[]): return false
	if not m.get("elite_ids") is Array or (not m.elite_ids.is_empty() and (m.kind != "SURVIVE" or m.elite_ids != ["S1-E01"])): return false
	var elite_count := 0
	for stage in m.get("encounter_stages",[]):
		for row in stage.rows:
			if "S1-E01" in row.enemy_ids: elite_count += int(row.count)
	if elite_count != (1 if not m.elite_ids.is_empty() else 0): return false
	if m.get("chapter_c",false) and not valid_chapter_definition(c,m): return false
	for stage in m.get("encounter_stages",[]):
		if stage.trigger == "CLUE_PROGRESS" and (not m.has("clues") or stage.value < 1 or stage.value > 3): return false
		if stage.trigger == "CLEANSE_HALF" and (m.kind != "CLEANSE" or stage.value >= m.target_count*2): return false
	if not number(m.get("spawn_safe_radius"),100,900) or not integer(m.get("spawn_attempts"),1,32): return false
	if not integer(m.get("xp_base"),1,100) or not integer(m.get("xp_step"),1,100) or not integer(m.get("upgrade_interval_ticks"),1,3600): return false
	if not m.get("spawn_view_size") is Array or m.spawn_view_size.size() != 2: return false
	if not number(m.spawn_view_size[0],640,1280) or not number(m.spawn_view_size[1],360,720) or not number(m.get("spawn_visual_margin"),80,120): return false
	var dynamic_ids: Array = m.enemy_ids + m.elite_ids
	if m.has("hunt_enemy_id"): dynamic_ids.append(m.hunt_enemy_id)
	for row in c.get("enemies",[]) + c.get("elites",[]):
		if row.get("id") in dynamic_ids:
			if not number(row.get("radius"),1,100) or float(row.radius)*1.5+10 > float(m.spawn_visual_margin): return false
	for field in ["pickup_attract_radius","pickup_attract_speed"]:
		if m.has(field) and not number(m[field],1,800): return false
	if m.has("clue_xp") and (not m.has("clues") or not integer(m.clue_xp,1,100)): return false
	if m.has("boss_phase_entry_warning") and (not m.boss_phase_entry_warning is bool or not m.has("boss_chapter")): return false
	if m.has("boss_phase_xp") and (not m.has("boss_chapter") or not integer(m.boss_phase_xp,1,100)): return false
	return true

## Creates bounded counters, activating initial stages without spawning in setup.
static func create(a) -> Dictionary:
	var result := {"stage_ticks":[], "counts":[], "skipped":0, "tutorial":0, "last_tick":0, "last_upgrade_tick":-1}
	for stage in a.mission.get("encounter_stages", []):
		result.stage_ticks.append(0 if reached(stage,a.state,a.mission) else -1)
		var counts: Array = []
		for row in stage.rows: counts.append(0)
		result.counts.append(counts)
	if a.mission.get("chapter_c",false): result.chapter = Chapter.create()
	return result

static func reached(stage: Dictionary, s: Dictionary, m: Dictionary) -> bool:
	match stage.trigger:
		"ACTIVE_TICK": return int(s.tick) >= int(stage.value)
		"ANCHOR_PROGRESS": return int(s.objective.progress) >= int(stage.value)
		"CLUE_PROGRESS": return s.encounter.chapter.clues >= stage.value if s.has("encounter") else false
		"CLEANSE_HALF":
			var zone := int(stage.value)/2
			return int(s.objective.waypoint)>zone or (int(s.objective.waypoint)==zone and float(s.objective.hold)>0 and (int(stage.value)%2==0 or float(s.objective.hold)>=float(m.hold_seconds)*0.5))
		"WAYPOINT": return int(s.objective.waypoint) >= int(stage.value)
	return false

static func due(row: Dictionary, trigger: int, tick: int) -> int:
	var first := maxi(1, trigger + int(row.offset))
	if tick < first: return 0
	return mini(int(row.count), 1 + int((tick-first)/int(row.interval)))

## Trigger and spawn at the end of the same simulation step as mission progress.
static func advance(a) -> void:
	var e: Dictionary = a.state.encounter
	if int(e.last_tick) == int(a.state.tick): return
	e.last_tick = int(a.state.tick)
	if a.mission.get("chapter_c",false): Chapter.advance(a)
	var stages: Array = a.mission.get("encounter_stages", [])
	for i in stages.size():
		var stage: Dictionary = stages[i]
		if int(e.stage_ticks[i]) < 0 and reached(stage,a.state,a.mission): e.stage_ticks[i] = int(a.state.tick)
		if int(e.stage_ticks[i]) < 0: continue
		for j in stage.rows.size():
			var row: Dictionary = stage.rows[j]
			var target := due(row,int(e.stage_ticks[i]),int(a.state.tick))
			while int(e.counts[i][j]) < target:
				var id: String = row.enemy_ids[a.rng.randi_range(0,row.enemy_ids.size()-1)]
				var at := spawn_point(a,int(row.sector))
				if not at.is_finite() or a.state.objective.finished or a.spawn_enemy(id,at,"elite" if id in a.mission.elite_ids else "enemy").is_empty(): e.skipped += 1
				e.counts[i][j] += 1
	if a.mission.get("chapter_two",false): Thermal.advance(a)
	var roots: Array = layout(a.catalog,a.mission).roots
	for root_index in roots.size():
		var row: Dictionary = roots[root_index]
		if a.mission.get("late_chapter",false) and Late.field_closed(a.mission,a.state,root_index): continue
		if a.mission.get("chapter_two",false) and Thermal.vent_closed(a.mission,a.state,root_index): continue
		if a.mission.get("close_roots",false) and int(e.chapter.root_mask) & (1<<root_index): continue
		var flooded: bool = a.mission.get("chapter_three",false) and Tide.flat_flooded(a.mission,a.state,root_index)
		var cycle := int(row.warning_ticks)+int(row.active_ticks)+(0 if flooded else int(row.rest_ticks))
		var live := false
		for z in a.state.zones:
			if int(z.get("tide_flat",-1)) == root_index: live = true; break
		# A flooded flat re-arms as soon as its previous surge ends — never on top of a
		# live zone, whose damage would stack with the new surge for a double drain.
		# Sealed flats keep the offset warning/rest grid; a live zone can only ever
		# block the first post-break slot, where the shortened cycle first bites.
		if not a.state.objective.finished and a.state.tick > row.offset_ticks and not live and (flooded or (int(a.state.tick)-int(row.offset_ticks)-1)%cycle == 0):
			a.emit_layout_root(row,root_index)

## Deterministic perimeter candidates in a player-relative direction; no foot spawning.
static func spawn_point(a, sector: int) -> Vector2:
	var half: Vector2 = a.half_size()*0.92
	var player: Vector2 = a.player_world_position()
	var axis := [Vector2.UP,Vector2.DOWN,Vector2.RIGHT,Vector2.LEFT][sector] as Vector2
	for i in int(a.mission.spawn_attempts):
		var angle: float = a.rng.randf()*TAU
		var q := Vector2(cos(angle)*half.x,sin(angle)*half.y)
		var offset := q-player
		if offset.length() < float(a.mission.spawn_safe_radius) or offset.normalized().dot(axis) < 0.25: continue
		var clear := true
		for rock in a.state.obstacles:
			if q.distance_to(a.pos(rock)) < float(rock.radius)+30: clear = false
		if clear and a.spawn_outside_view(q): return q
	return Vector2(INF,INF)

## Only active movement is scaled; first matching stable wind ID wins.
static func wind_multiplier(a, movement: Vector2) -> float:
	if a.state.tick < a.mission.wind_start_tick or movement.is_zero_approx(): return 1.0
	for w in layout(a.catalog,a.mission).winds:
		var center := Vector2(w.center[0],w.center[1])
		var size := Vector2(w.size[0],w.size[1])
		if Rect2(center-size*0.5,size).has_point(a.player_world_position()):
			a.state.encounter.tutorial |= 8
			var projection: float = movement.normalized().x*float(w.direction)
			return float(w.forward) if projection > 0.25 else (float(w.backward) if projection < -0.25 else 1.0)
	return 1.0

## Strict counter shapes and progress coupling prevent restoring a pending stage twice.
static func valid_state(c: Dictionary, m: Dictionary, s: Dictionary) -> bool:
	if not valid_definition(c,m) or not s.get("encounter") is Dictionary: return false
	if absf(float(s.elapsed)*60.0-float(s.tick)) > 0.001 or absf(float(s.objective.elapsed)-float(s.elapsed)) > 0.00001: return false
	var e: Dictionary = s.encounter
	if e.size() != (7 if m.get("chapter_c",false) else 6) or not e.get("stage_ticks") is Array or not e.get("counts") is Array: return false
	if not integer(e.get("last_tick"),s.tick,s.tick): return false
	if not integer(e.get("last_upgrade_tick"),-1,s.tick): return false
	if e.last_upgrade_tick >= 0 and (int(s.player.level) < 2 or (not s.offered.is_empty() and s.tick-e.last_upgrade_tick < m.upgrade_interval_ticks)): return false
	var stages: Array = m.get("encounter_stages",[])
	if e.stage_ticks.size() != stages.size() or e.counts.size() != stages.size() or not integer(e.get("tutorial"),0,15): return false
	if bool(int(e.tutorial) & 4) != (e.last_upgrade_tick >= 0): return false
	var total := 0
	for i in stages.size():
		var stage: Dictionary = stages[i]
		if not integer(e.stage_ticks[i],-1,s.tick) or not e.counts[i] is Array or e.counts[i].size() != stage.rows.size(): return false
		var trigger := int(e.stage_ticks[i])
		if (trigger >= 0) != reached(stage,s,m): return false
		if stage.trigger == "ACTIVE_TICK" and trigger >= 0 and trigger != int(stage.value): return false
		if stage.value == 0 and stage.trigger != "CLEANSE_HALF" and trigger != 0: return false
		for j in stage.rows.size():
			var expected := 0 if trigger < 0 else due(stage.rows[j],trigger,int(s.tick))
			if not integer(e.counts[i][j],expected,expected): return false
			total += expected
	if not integer(e.get("skipped"),0,total): return false
	var expected_rocks: Array = layout(c,m).obstacles
	if s.obstacles.size() != expected_rocks.size(): return false
	for i in expected_rocks.size():
		for key in ["x","y","radius"]:
			if s.obstacles[i].get(key) != expected_rocks[i][key]: return false
	if m.get("chapter_c",false) and not Chapter.valid(m,s): return false
	if m.get("chapter_two",false) and not Thermal.valid_state(m,s,layout(c,m)): return false
	if m.get("chapter_three",false) and not Tide.valid_state(m,s,layout(c,m)): return false
	if m.get("late_chapter",false) and not Late.valid_state(m,s,layout(c,m)): return false
	return true

static func number(v: Variant, low: float, high: float) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v >= low and v <= high
static func integer(v: Variant, low: float, high: float) -> bool:
	return number(v,low,high) and float(v) == floorf(float(v))
static func point(v: Variant) -> bool:
	return v is Array and v.size() == 2 and number(v[0],-900,900) and number(v[1],-580,580)
static func keys(d: Dictionary, expected: Array) -> bool:
	if d.size() != expected.size(): return false
	for key in expected:
		if not d.has(key): return false
	return true

## Chapter C fields are admitted only with the corresponding executable objective.
static func valid_chapter_definition(c: Dictionary,m: Dictionary) -> bool:
	if m.chapter_c != true or not m.has("encounter_stages"): return false
	if m.has("clues"):
		if m.kind != "HUNT" or not m.clues is Array or m.clues.size()!=3 or m.get("hunt_enemy_id") != "S1-E01": return false
		for q in m.clues:
			if not point(q): return false
		if not number(m.get("clue_radius"),20,100) or not integer(m.get("hunt_retry_ticks"),1,60): return false
		if not m.get("event_ids") is Array or m.event_ids.size()!=3: return false
		if m.event_ids != ["S1-RISK01","S1-RISK02","S1-RISK03"]: return false
		for id in m.event_ids:
			var found := false
			for row in c.events:
				if row.id == id and row.unlock_after <= m.ordinal-1: found = true
			if not found: return false
		if not m.get("hunt_charge") is Dictionary or not keys(m.hunt_charge,["warning_ticks","rush_ticks","rest_ticks","speed"]): return false
		for k in ["warning_ticks","rush_ticks","rest_ticks"]:
			if not integer(m.hunt_charge[k],15,180): return false
		if not number(m.hunt_charge.speed,100,800): return false
	if m.kind == "HUNT" and not m.has("clues"): return false
	if m.has("close_roots") and (m.kind != "BREAK" or m.close_roots != true): return false
	if m.kind == "BOSS" and not m.has("boss_chapter"): return false
	if m.has("boss_chapter"):
		if m.kind != "BOSS" or not m.boss_chapter is Dictionary: return false
		if not keys(m.boss_chapter,["warning_ticks","cooldown_ticks","impact_radius","second_delay_ticks","root_radius","root_duration_ticks","root_distance"]): return false
		for k in m.boss_chapter:
			if not integer(m.boss_chapter[k],1,600): return false
		if m.boss_chapter.warning_ticks+m.boss_chapter.second_delay_ticks > 120 or m.boss_chapter.cooldown_ticks <= m.boss_chapter.warning_ticks+m.boss_chapter.second_delay_ticks: return false
	return true
