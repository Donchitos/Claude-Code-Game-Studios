extends SceneTree
## Throwaway calibration sweep: M03-07 warden duel variants under alternate-route arrival.
## Tweak missions[22] in memory (re-hash like the journey test), 8 seeds per variant.
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Bot = preload("res://tests/fixtures/campaign_c_bot.gd")

func _initialize(): _run.call_deferred()

func build_variant(base: Dictionary, rear_count: int, rear_interval: int, duel_count: int) -> Dictionary:
	var m: Dictionary = base.duplicate(true)
	for stage in m.encounter_stages:
		if stage.id == "WARDEN_REAR":
			stage.rows[0].count = rear_count
			stage.rows[0].interval = rear_interval
		elif stage.id == "WARDEN_DUEL":
			stage.rows[0].count = duel_count
	return m

func run_mission(c: Dictionary, m: Dictionary, seed: int) -> Dictionary:
	var cc: Dictionary = c.duplicate(true)
	for i in cc.missions.size():
		if cc.missions[i].id == m.id:
			cc.missions[i] = m.duplicate(true)
			break
	cc.erase("content_hash")
	var normalized: Dictionary = JSON.parse_string(JSON.stringify(cc, "", true, true))
	cc.clear()
	cc.merge(normalized)
	cc["content_hash"] = JSON.stringify(cc, "", true, true).sha256_text()
	var a := Arena.new()
	root.add_child(a)
	var l := {"character_id": "S1-C03", "completed": 22, "branches": [2, 2, 2], "difficulty": 0, "pill_id": "", "challenge_id": ""}
	var out: Dictionary = {}
	if not a.configure(cc, m, l, seed):
		out["fail"] = "configure"
		a.free()
		return out
	for tick in 30000:
		if a.state.finished: break
		if not a.state.offered.is_empty(): a.choose_upgrade(Bot.choice(a, cc))
		if a.state.event_id != "": a.choose_event(true)
		a.advance(1.0 / 60.0, Bot.direction(a, m, tick))
	out["victory"] = a.state.victory
	out["hp"] = a.state.player.hp
	out["max_hp"] = a.state.player.max_hp
	out["elapsed"] = a.state.elapsed
	out["kills"] = a.stats().kills
	out["level"] = a.state.player.level
	a.free()
	return out

func _old_run():
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var base: Dictionary = c.missions[22]
	var variants := [
		{"name": "V0_base", "rear": 8, "ri": 45, "duel": 6},
		{"name": "V1_rear6", "rear": 6, "ri": 45, "duel": 6},
		{"name": "V2_rear5", "rear": 5, "ri": 45, "duel": 6},
		{"name": "V3_slowtrickle", "rear": 8, "ri": 90, "duel": 6},
		{"name": "V4_duel4", "rear": 8, "ri": 45, "duel": 4},
		{"name": "V5_rear6duel4", "rear": 6, "ri": 45, "duel": 4},
	]
	for v in variants:
		var m := build_variant(base, int(v.rear), int(v.ri), int(v.duel))
		var wins := 0
		var worst := 999.0
		var lines := []
		for s in [977, 101, 202, 303, 404, 505, 606, 707]:
			var r := run_mission(c, m, s)
			if r.has("fail"):
				lines.append(str(s) + ":CONFIG_FAIL")
				continue
			if r.victory: wins += 1
			var margin := 0.0
			if r.victory: margin = float(r.hp) / float(r.max_hp)
			if r.victory and margin < worst: worst = margin
			lines.append(str(s) + (":W" if r.victory else ":L") + " hp=" + str(roundf(float(r.hp))) + "/" + str(roundf(float(r.max_hp))) + " t=" + str(roundf(float(r.elapsed))) + " k=" + str(int(r.kills)) + " lv" + str(int(r.level)))
		var line := ""
		for entry in lines:
			line += entry + " | "
		print(v.name, " wins=", wins, "/8 worst_margin=", str(roundf(worst * 100.0)) + "%")
		print("  ", line)
	quit()

func _run():
	var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var variants = [{"offset":300,"interval":45,"count":5},{"offset":450,"interval":45,"count":5},{"offset":300,"interval":60,"count":5},{"offset":450,"interval":60,"count":5},{"offset":600,"interval":60,"count":5},{"offset":450,"interval":60,"count":4}]
	for v in variants:
		var m: Dictionary=c.missions[22].duplicate(true)
		m.encounter_stages[0].rows[0].offset=v.offset
		m.encounter_stages[0].rows[0].interval=v.interval
		m.encounter_stages[0].rows[0].count=v.count
		for actual in [1479748453,977,101,202,303,404,505,606,707,809,919,1031,1151,1277,1381,1493,1601,1723,1831,1949,2063,2179,2287,2399,2503]:
			var r=run_mission(c,m,actual)
			print("SWEEP ",JSON.stringify({"variant":v,"seed":actual,"result":r}))
	quit()
