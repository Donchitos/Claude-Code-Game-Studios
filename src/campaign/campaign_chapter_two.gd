extends RefCounted
## ADR-0010: thermal mechanics derive from the existing authoritative tick/objective.
const FORMAT := "CAMPAIGN_CHAPTER2_V1"

## Exact controller identity, independent of the order chosen by the player.
static func vent_closed(m: Dictionary, s: Dictionary, index: int) -> bool:
	return m.get("thermal_anchors",false) and m.target_ids[index] in s.objective.completed_ids

## A derived fixed-tick window; no second mutable clock enters the snapshot.
static func door_open(m: Dictionary, tick: int) -> bool:
	var config: Dictionary = m.furnace_boss
	return tick % (int(config.closed_ticks)+int(config.open_ticks)) >= int(config.closed_ticks)

## Remove both live heat and pending warnings when their exact controller is destroyed.
static func advance(a) -> void:
	if not a.mission.get("thermal_anchors",false): return
	for i in range(a.state.zones.size()-1,-1,-1):
		var zone: Dictionary = a.state.zones[i]
		if zone.has("thermal_vent") and vent_closed(a.mission,a.state,int(zone.thermal_vent)):
			a.state.zones.remove_at(i)

## Every phase emits a bounded set with a full warning, including phase transitions.
static func boss(a, e: Dictionary, target: Vector2) -> void:
	if e.hp <= 0 or a.state.player.hp <= 0: return
	var phase := mini(2,int((1.0-maxf(0,e.hp)/e.max_hp)*3.0))
	if phase > int(e.phase):
		a.drop_xp(a.player_world_position(),float(a.mission.furnace_boss.phase_xp)*(phase-int(e.phase)))
		e.phase = phase
		e.timer = 0.0
	if e.timer > 0 or a.state.zones.size()+phase+1 > 128: return
	var config: Dictionary = a.mission.furnace_boss
	e.timer = float(config.cooldown_ticks)/60.0
	for i in phase+1:
		var offset := Vector2.ZERO if i==0 else Vector2(-160 if i==1 else 160,100)
		a.Combat.zone(a,target+offset,75,e.damage*1.2,0.4,"#ff964f","blast",true,float(config.warning_ticks)/60.0)

## Hunt rewards are phase-bound, so save/resume cannot reissue a completed break.
static func hunt_damage(a, e: Dictionary) -> void:
	if not a.mission.has("hunt_phase_xp") or e.target_id != a.mission.id+":HUNT" or e.hp <= 0: return
	var phase := mini(2,int((1.0-e.hp/e.max_hp)*3.0))
	if phase > int(e.phase):
		a.drop_xp(a.player_world_position(),float(a.mission.hunt_phase_xp)*(phase-int(e.phase)))
		e.phase = phase

## Admit only the implemented chapter-two contracts and bounded tuning.
static func valid_definition(m: Dictionary) -> bool:
	if m.get("chapter_two") != true or m.get("chapter") != 2 or m.get("chapter_c",false) or m.get("chapter_three",false): return false
	if m.kind == "HUNT" and (m.get("hunt_enemy_id") != "S1-E02" or m.get("hunt_phase_xp") != 8): return false
	if m.has("hunt_enemy_id") and m.kind != "HUNT": return false
	if m.has("thermal_anchors") and (m.thermal_anchors != true or m.kind != "BREAK" or m.target_count != 3): return false
	if m.kind == "BREAK" and not m.get("thermal_anchors",false): return false
	if m.has("rest_waypoint") and (m.kind != "ESCORT" or m.get("rest_waypoint") != 3 or m.target_count != 5): return false
	if m.kind == "BOSS":
		if m.get("boss_id") != "S1-B02" or not m.get("furnace_boss") is Dictionary: return false
		var expected := {"closed_ticks":180,"open_ticks":150,"closed_multiplier":0.35,"warning_ticks":78,"cooldown_ticks":150,"phase_xp":18}
		if m.furnace_boss.size() != expected.size(): return false
		for key in expected:
			if not (m.furnace_boss.get(key) is float or m.furnace_boss.get(key) is int) or m.furnace_boss[key] != expected[key]: return false
	elif m.has("furnace_boss"): return false
	return true

## Bind durable target presence and thermal work back to authored sources.
static func valid_state(m: Dictionary, s: Dictionary, layout: Dictionary) -> bool:
	for z in s.zones:
		if z.has("thermal_vent"):
			var index: Variant = z.thermal_vent
			if not (index is int or index is float) or index != floorf(index) or index < 0 or index > 2: return false
			if vent_closed(m,s,int(index)) or z.kind != "poison" or not z.hostile: return false
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
		if e.family == "boss" and (e.id != "S1-B02" or e.phase < 0 or e.phase > 2 or e.phase != floorf(e.phase)): return false
		if m.kind == "HUNT" and e.get("target_id","") == m.id+":HUNT" and (e.id != "S1-E02" or e.family != "elite" or e.phase != mini(2,int((1.0-maxf(0,e.hp)/e.max_hp)*3.0))): return false
	if m.has("rest_waypoint") and (s.event_done or s.event_id != "") and s.objective.waypoint < m.rest_waypoint: return false
	return true

## Localized read-only explanation of the current objective and furnace window.
static func teaching(a, en: bool) -> String:
	if a.mission.has("furnace_boss"):
		if door_open(a.mission,int(a.state.tick)): return "Door OPEN: attack the bright core." if en else "炉门已开：攻击亮起的炉心，造成全额伤害。"
		return "Door CLOSED: reduced damage. Avoid vent warnings." if en else "炉门关闭：伤害降低，先避开喷口预警。"
	if a.mission.get("thermal_anchors",false):
		return ("Vents shut: %d/3. Each pipe closes its matching vent." if en else "喷口已关闭%d/3；拆除控制器关闭对应热区。") % a.state.objective.progress
	if a.mission.kind == "ESCORT":
		return ("Stay near %s; intercept enemies and return." % a.mission.escort_label_en) if en else ("靠近%s才能前进；拦截敌人后及时归队。" % a.mission.escort_label)
	if a.mission.kind == "HUNT": return "Defeat the marked Warden; avoid its heat trail." if en else "击败标记的熔脊行者，绕开沿途热迹。"
	return "Orange rings warn before heat erupts." if en else "橙色圆圈先预警，再喷发；留出绕行空间。"
