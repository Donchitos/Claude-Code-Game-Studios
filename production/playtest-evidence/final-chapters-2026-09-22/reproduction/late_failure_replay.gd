extends SceneTree
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Bot=preload("res://tests/fixtures/campaign_c_bot.gd")
func _initialize():run.call_deferred()
func run():
	var c=load("res://src/campaign/campaign_catalog.gd").load_catalog()
	for row in [[39,1161096872,"S1-C03",3],[39,2911953361,"S1-C05",3],[62,773,"S1-C01",0]]:
		var a=Arena.new();root.add_child(a)
		assert(a.configure(c,c.missions[row[0]],{"character_id":row[2],"completed":row[0],"branches":[row[3],row[3],row[3]],"difficulty":0,"pill_id":"","challenge_id":""},row[1]))
		for tick in 30000:
			if a.state.finished:break
			if not a.state.offered.is_empty():a.choose_upgrade(Bot.choice(a,c))
			if a.state.event_id!="":a.choose_event(row[0]==39)
			a.advance(1.0/60,Bot.direction(a,a.mission,tick))
		print("EXACT_REPLAY ",JSON.stringify({"mission":a.mission.id,"seed":row[1],"character":row[2],"victory":a.state.victory,"hp":a.state.player.hp,"time":a.state.elapsed,"level":a.state.player.level}))
		a.free()
	quit()
