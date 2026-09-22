extends RefCounted
## Chapter-specific state owned and committed by CampaignEncounter, never by UI.
const Combat = preload("res://src/campaign/campaign_combat.gd")

## New runs hold bounded counters and pending attacks, including unspawned hunt identity.
static func create() -> Dictionary:
	return {"clues":0,"hunt_spawned":false,"retry":0,"root_mask":0,"boss_phase":0,
		"first_warning":[-1,-1,-1],"attacks":[0,0,0],"hits":[0,0,0],"kill_tick":-1,"landings":[],"error":""}

## End-of-step objective effects precede stage scheduling and the next snapshot.
static func advance(a) -> void:
	var c: Dictionary = a.state.encounter.chapter
	if a.mission.has("clues") and not a.state.objective.finished:
		if c.clues < a.mission.clues.size():
			var q: Array = a.mission.clues[int(c.clues)]
			if a.player_world_position().distance_to(Vector2(q[0],q[1])) <= a.mission.clue_radius:
				c.clues += 1
				a.drop_xp(Vector2(q[0],q[1]),float(a.mission.get("clue_xp",0)))
		if c.clues == 3 and not c.hunt_spawned:
			var e: Dictionary = a.spawn_enemy(a.mission.hunt_enemy_id,a.spawn_position(),"elite")
			if not e.is_empty():
				e.target_id = a.mission.target_ids[0]
				e.phase = 0
				e.timer = 0
				c.hunt_spawned = true
			else:
				c.retry += 1
				if c.retry >= a.mission.hunt_retry_ticks: c.error = "HUNT_CAPACITY_RETRY_EXHAUSTED"
	if a.mission.get("close_roots",false):
		c.root_mask = (1 << int(a.state.objective.progress))-1
		for i in range(a.state.zones.size()-1,-1,-1):
			var z: Dictionary = a.state.zones[i]
			if z.has("layout_root") and int(c.root_mask) & (1 << int(z.layout_root)): a.state.zones.remove_at(i)
	if a.mission.has("boss_chapter") and a.state.target_deaths.has(a.mission.boss_id):
		c.kill_tick = a.state.tick if c.kill_tick < 0 else c.kill_tick
		c.landings.clear()

## Publish first-clue encounter only after all pending upgrades are resolved.
static func offer_event(a) -> void:
	if not a.mission.has("clues") or a.state.encounter.chapter.clues == 0 or a.state.event_done or a.state.finished or not a.state.offered.is_empty(): return
	if a.state.event_id != "" or a.queued_upgrades() > 0: return
	var eligible: Array = []
	for id in a.mission.event_ids:
		if a.tables.events[id].unlock_after <= a.loadout.completed: eligible.append(id)
	if not eligible.is_empty(): a.state.event_id = eligible[a.rng.randi_range(0,eligible.size()-1)]

## Hunt charge freezes its heading through warning, rush and stationary recovery.
static func hunt_velocity(a, e: Dictionary, direction: Vector2) -> Vector2:
	var cfg: Dictionary = a.mission.hunt_charge
	if e.timer <= 0:
		match int(e.phase):
			0:
				e.phase = 1
				e.aim = direction.angle()
				e.timer = cfg.warning_ticks/60.0
				var z: Dictionary = Combat.zone(a,a.pos(e),5,0,0.05,e.color,"line",true,e.timer)
				if not z.is_empty():
					z.angle = e.aim
					z.length = cfg.speed*cfg.rush_ticks/60.0
			1:
				e.phase = 2
				e.timer = cfg.rush_ticks/60.0
			2:
				e.phase = 3
				e.timer = cfg.rest_ticks/60.0
			3:
				e.phase = 0
				e.timer = 0
	return Vector2.from_angle(e.aim)*cfg.speed if e.phase == 2 else Vector2.ZERO

## Boss warnings and delayed physical landings share persisted tick/position records.
static func boss(a, e: Dictionary, target: Vector2) -> void:
	var c: Dictionary = a.state.encounter.chapter
	var cfg: Dictionary = a.mission.boss_chapter
	var phase := maxi(int(c.boss_phase),mini(2,int((1.0-maxf(0,e.hp)/e.max_hp)*3)))
	for crossed in range(int(c.boss_phase),phase):
		a.drop_xp(a.pos(e),float(a.mission.get("boss_phase_xp",0)))
	c.boss_phase = phase
	e.phase = phase
	for i in range(c.landings.size()-1,-1,-1):
		var landing: Dictionary = c.landings[i]
		if a.state.tick >= landing.tick:
			a.set_pos(e,a.constrain(Vector2(landing.x,landing.y),e.radius))
			c.landings.remove_at(i)
	if e.timer > 0: return
	# Never queue an attack whose telegraph cannot fit in the bounded zone pool.
	var required := 4 if phase == 2 else (2 if phase == 1 else 1)
	if a.state.zones.size()+required > 128: return
	e.timer = cfg.cooldown_ticks/60.0
	if c.first_warning[phase] < 0: c.first_warning[phase] = a.state.tick
	c.attacks[phase] += 1
	for i in (2 if phase == 1 else 1):
		var at: Vector2 = a.constrain(target+Vector2.from_angle(float(a.state.player.facing))*cfg.root_distance*i,e.radius)
		var delay: float = (cfg.warning_ticks+cfg.second_delay_ticks*i)/60.0
		Combat.zone(a,at,cfg.impact_radius,e.damage*1.5,0.2,e.color,"blast",true,delay)
		c.landings.append({"tick":int(a.state.tick)+int(cfg.warning_ticks)+int(cfg.second_delay_ticks)*i,"x":at.x,"y":at.y})
	if phase == 2:
		for i in 3:
			var at: Vector2 = a.constrain(target+Vector2.from_angle(TAU*i/3)*cfg.root_distance,cfg.root_radius)
			Combat.zone(a,at,cfg.root_radius,e.damage*0.5,cfg.root_duration_ticks/60.0,e.color,"poison",true,cfg.warning_ticks/60.0)

## Joint validation ties optional chapter state to mission progress and target identity.
static func valid(m: Dictionary, s: Dictionary) -> bool:
	var c = s.encounter.get("chapter")
	if not c is Dictionary or c.size() != 11: return false
	for k in ["clues","retry","root_mask","boss_phase","kill_tick"]:
		if not c.get(k) is float and not c.get(k) is int: return false
		if not is_finite(c[k]) or floorf(c[k]) != c[k]: return false
	if c.clues < 0 or c.clues > 3 or c.root_mask < 0 or c.root_mask > 7 or c.boss_phase < 0 or c.boss_phase > 2: return false
	if not c.get("hunt_spawned") is bool or not c.get("error") is String: return false
	if c.error != "" or c.retry < 0 or c.retry >= m.get("hunt_retry_ticks",1): return false
	for k in ["first_warning","attacks","hits"]:
		if not c.get(k) is Array or c[k].size() != 3: return false
		for v in c[k]:
			if not (v is int or v is float) or not is_finite(v) or floorf(v) != v or v < (-1 if k=="first_warning" else 0) or v > s.tick: return false
	for i in 3:
		if (c.first_warning[i] >= 0) != (c.attacks[i] > 0): return false
	if not c.get("landings") is Array or c.landings.size() > 2: return false
	for q in c.landings:
		if not q is Dictionary or q.size()!=3: return false
		for k in ["tick","x","y"]:
			if not (q.get(k) is int or q.get(k) is float) or not is_finite(q[k]): return false
		if q.tick <= s.tick or q.tick > s.tick+120 or floorf(q.tick)!=q.tick or absf(q.x)>960 or absf(q.y)>640: return false
	if c.kill_tick < -1 or c.kill_tick > s.tick: return false
	if m.has("clues"):
		if c.hunt_spawned and c.clues != 3: return false
		var live := 0
		for e in s.entities:
			if e.target_id == m.target_ids[0]:
				if e.id != m.hunt_enemy_id or e.family != "elite" or e.phase > 3: return false
				live += 1
		var dead: bool = s.target_deaths.has(m.target_ids[0])
		if (live+int(dead)) != int(c.hunt_spawned): return false
		if c.clues < 3 and c.retry != 0: return false
		if c.clues == 3 and not c.hunt_spawned and c.retry == 0: return false
		if c.clues > 0 and not s.event_done and not s.finished and s.event_id == "" and s.offered.is_empty():
			# A queued upgrade owns precedence while its active-tick interval runs.
			var waiting: bool = s.player.level < 100 and s.player.xp >= m.xp_base+m.xp_step*(s.player.level-1) and s.encounter.last_upgrade_tick >= 0 and s.tick-s.encounter.last_upgrade_tick < m.upgrade_interval_ticks
			if not waiting: return false
		if c.clues == 0 and (s.event_done or s.event_id != ""): return false
		if s.event_id != "" and not m.event_ids.has(s.event_id): return false
		if int(s.statistics.events_taken) != int(s.event_done): return false
	else:
		if c.clues != 0 or c.hunt_spawned or c.retry != 0: return false
	var mask := (1<<int(s.objective.progress))-1 if m.get("close_roots",false) else 0
	if c.root_mask != mask: return false
	for z in s.zones:
		if z.has("layout_root"):
			if not (z.layout_root is int or z.layout_root is float) or z.layout_root < 0 or z.layout_root > 2 or floorf(z.layout_root)!=z.layout_root: return false
			if mask & (1<<int(z.layout_root)): return false
	if m.has("boss_chapter"):
		if (c.kill_tick>=0) != s.target_deaths.has(m.boss_id): return false
		if c.kill_tick>=0 and not c.landings.is_empty(): return false
	else:
		if c.kill_tick != -1 or c.boss_phase != 0 or not c.landings.is_empty() or c.attacks != [0,0,0] or c.hits != [0,0,0] or c.first_warning != [-1,-1,-1]: return false
	return true
