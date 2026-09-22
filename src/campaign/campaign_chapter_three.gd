extends RefCounted
## ADR-0011: tidal mechanics derive from the existing authoritative tick/objective.
const FORMAT := "CAMPAIGN_CHAPTER3_V1"

## Exact sluice identity, independent of the order chosen by the player.
static func flat_flooded(m: Dictionary, s: Dictionary, index: int) -> bool:
	return m.get("tide_flats",false) and m.target_ids[index] in s.objective.completed_ids

## Hunt rewards are threshold-crossing events: the burrow elite owns its phase
## field, so no counter is stored and a restore cannot re-cross a threshold.
static func hunt_damage(a, e: Dictionary, before: float) -> void:
	if not a.mission.has("hunt_phase_xp") or e.target_id != a.mission.id+":HUNT" or e.hp <= 0: return
	var gained := mini(2,int((1.0-maxf(0.0,e.hp)/e.max_hp)*3.0)) - mini(2,int((1.0-maxf(0.0,before)/e.max_hp)*3.0))
	if gained <= 0: return
	a.drop_xp(a.player_world_position(),float(a.mission.hunt_phase_xp)*gained)
	e.timer = float(e.cooldown) # Interrupt: delay the next dive, extending the surfaced window.

## Commit phase and its XP at the damage boundary, including post-AI projectile hits.
## This does not issue attacks; pending warnings keep their original full duration.
static func boss_damage(a, e: Dictionary) -> void:
	if e.family != "boss" or not a.mission.has("tide_boss") or e.hp <= 0: return
	var phase := mini(2,int((1.0-maxf(0,e.hp)/e.max_hp)*3.0))
	if phase > int(e.phase):
		a.drop_xp(a.player_world_position(),float(a.mission.tide_boss.phase_xp)*(phase-int(e.phase)))
		e.phase = phase
		e.timer = 0.0

## Every attack emits full-warning walls; the aimed side alternates via the entity aim.
static func boss(a, e: Dictionary, target: Vector2) -> void:
	if e.hp <= 0 or a.state.player.hp <= 0: return
	boss_damage(a,e)
	var phase := int(e.phase)
	var config: Dictionary = a.mission.tide_boss
	var columns := 2 + phase
	var walls := 2 if phase >= 2 else 1
	var pools := 8 if phase >= 2 else 0
	if e.timer > 0 or a.state.zones.size()+columns*walls+pools > 128: return
	if phase >= 2 and a.state.projectiles.size()+12 > mini(400,int(a.tuning.projectile_cap)): return
	e.timer = float(config.cooldown_ticks)/60.0
	var side := -1.0 if e.aim < 0.0 else 1.0
	e.aim = -side
	var warn := float(config.warning_ticks)/60.0
	for wall in walls:
		var direction := side if wall == 0 else -side
		for i in columns:
			# Anchor mid-arena so the segment spans the full field height; a
			# midline anchor would only cover the half the boss itself guards from.
			var z: Dictionary = a.Combat.zone(a,Vector2(direction*(float(config.tooth_spacing)*float(i+1)-40.0),-float(config.arm_length)*0.5),float(config.tooth_radius),e.damage*1.2,0.8,"#72cbe8","line",true,warn)
			if not z.is_empty():
				z.angle = PI/2.0
				z.length = float(config.arm_length)
	if pools > 0:
		for i in pools:
			a.Combat.zone(a,a.pos(e)+Vector2.from_angle(TAU*float(i)/float(pools))*220.0,65,e.damage*0.5,4.0,"#72cbe8","poison",true,0.9)
		for i in 12:
			a.Combat.projectile(a,a.pos(e),Vector2.from_angle(TAU*float(i)/12.0+e.age)*170.0,e.damage,9,5,"#72cbe8","straight",1,0,true)

## Admit only the implemented chapter-three contracts and bounded tuning.
static func valid_definition(m: Dictionary) -> bool:
	if m.get("chapter_three") != true or m.get("chapter") != 3 or m.get("chapter_c",false) or m.get("chapter_two",false): return false
	if m.kind == "HUNT" and (m.get("hunt_enemy_id") != "S1-E03" or m.get("hunt_phase_xp") != 8): return false
	if m.has("hunt_enemy_id") and m.kind != "HUNT": return false
	if m.has("tide_flats") and (m.tide_flats != true or m.kind != "BREAK" or m.target_count != 3): return false
	if m.kind == "BREAK" and not m.get("tide_flats",false): return false
	if m.has("rest_waypoint") and (m.kind != "ESCORT" or m.get("rest_waypoint") != 2 or m.target_count != 4): return false
	if m.kind == "BOSS":
		if m.get("boss_id") != "S1-B03" or not m.get("tide_boss") is Dictionary: return false
		var expected := {"warning_ticks":78,"cooldown_ticks":150,"phase_xp":18,"tooth_radius":34,"tooth_spacing":215,"arm_length":1250}
		if m.tide_boss.size() != expected.size(): return false
		for key in expected:
			if not (m.tide_boss.get(key) is float or m.tide_boss.get(key) is int) or m.tide_boss[key] != expected[key]: return false
	elif m.has("tide_boss"): return false
	return true

## Bind durable target presence and tidal work back to authored sources.
static func valid_state(m: Dictionary, s: Dictionary, layout: Dictionary) -> bool:
	var seen_flats := {}
	for z in s.zones:
		if z.has("tide_flat"):
			var index: Variant = z.tide_flat
			if not (index is int or index is float) or index != floorf(index) or index < 0 or index > 2: return false
			if int(index) >= layout.roots.size() or seen_flats.has(int(index)): return false
			seen_flats[int(index)] = true
			if z.kind != "poison" or not z.hostile: return false
			var row: Dictionary = layout.roots[int(index)]
			if z.x != row.center[0] or z.y != row.center[1] or z.radius != row.radius or z.damage != row.damage or z.duration != float(row.active_ticks)/60.0: return false
	if m.kind in ["HUNT","BOSS","BREAK"]:
		for id in m.target_ids:
			var live := 0
			for entity in s.entities:
				if entity.target_id == id: live += 1
			if live != (0 if id in s.objective.completed_ids else 1): return false
	for e in s.entities:
		if m.kind == "BOSS" and e.target_id == m.boss_id and (e.id != m.boss_id or e.family != "boss"): return false
		if m.kind == "BREAK" and e.target_id in m.target_ids and e.family != "target": return false
		if e.family == "boss" and (e.id != "S1-B03" or e.phase < 0 or e.phase > 2 or e.phase != floorf(e.phase) or e.phase != mini(2,int((1.0-maxf(0,e.hp)/e.max_hp)*3.0)) or not [0.0,-1.0,1.0].has(e.aim)): return false
		if m.kind == "HUNT" and e.get("target_id","") == m.id+":HUNT" and (e.id != "S1-E03" or e.family != "elite"): return false
	if m.has("rest_waypoint") and (s.event_done or s.event_id != "") and s.objective.waypoint < m.rest_waypoint: return false
	return true

## Localized read-only explanation of the current objective and tide window.
static func teaching(a, en: bool) -> String:
	if a.mission.has("tide_boss"):
		return "Tide walls alternate sides; cross through the gaps between teeth." if en else "潮墙左右交替；从齿列之间的缺口穿越。"
	if a.mission.get("tide_flats",false):
		return ("Seals broken: %d/3. Each broken seal floods its flat for good." if en else "已拆闸印%d/3；每拆一座，对应潮池永久翻涌。") % a.state.objective.progress
	if a.mission.kind == "ESCORT":
		return ("Stay near the %s; stand off while a flat surges." % a.mission.escort_label_en) if en else ("靠近%s才能前进；潮池涨水时先离队等待。" % a.mission.escort_label)
	if a.mission.kind == "CLEANSE":
		return "Hold each circle; during a surge fall back to the far crescent." if en else "在圈内停留净化；涨水时退到潮池远端的月牙区。"
	if a.mission.kind == "HUNT": return "Strike while it surfaces; phase breaks stagger its dive." if en else "出水窗口内输出；阶段突破会打断它回潜。"
	return "Blue rings warn before the tide surges; leave the flat early." if en else "蓝色圆圈先预警，再涨水；提前离开潮池。"
