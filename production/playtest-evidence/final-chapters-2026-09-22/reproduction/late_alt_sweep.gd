extends SceneTree
## Fixed seeds, declared zero-growth fixture, no profile grants or human claims.
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Bot=preload("res://tests/fixtures/campaign_c_bot.gd")
func _initialize(): _run.call_deferred()
func _run():
	var c=load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var wins=0
	var rows=[]
	for index in range(24,64):
		for run_seed in [2228242853,197682660,977]:
			var a=Arena.new();root.add_child(a)
			var l={"character_id":"S1-C03","completed":index,"branches":[3,3,3] if index<40 else [4,4,4] if index<56 else [5,5,5],"difficulty":0,"pill_id":"","challenge_id":""}
			assert(a.configure(c,c.missions[index],l,run_seed))
			for tick in 30000:
				if a.state.finished:break
				if not a.state.offered.is_empty():assert(a.choose_upgrade(Bot.choice(a,c)))
				if a.state.event_id!="":assert(a.choose_event(false))
				a.advance(1.0/60,Bot.direction(a,a.mission,tick))
			var row={"mission":a.mission.id,"seed":run_seed,"victory":a.state.victory,"reason":a.state.reason,"seconds":a.state.elapsed,"level":a.state.player.level,"hp":a.state.player.hp}
			rows.append(row)
			if a.state.victory:wins+=1
			print("LATE_SWEEP ",JSON.stringify(row))
			a.free()
	FileAccess.open("res://production/playtest-evidence/final-chapters-2026-09-22/alt-sweep.json",FileAccess.WRITE).store_string(JSON.stringify({"hash":c.content_hash,"rows":rows,"wins":wins,"scope":"zero growth C01 bot fixtures, not human"},"\t"))
	print("LATE_SWEEP_RESULT ",wins,"/120")
	quit(0 if wins==120 else 1)
