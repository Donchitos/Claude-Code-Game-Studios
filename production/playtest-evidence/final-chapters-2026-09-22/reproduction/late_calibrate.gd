extends SceneTree
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Bot=preload("res://tests/fixtures/campaign_c_bot.gd")
func _initialize():run.call_deferred()
func run():
	var c=load("res://src/campaign/campaign_catalog.gd").load_catalog()
	for index in [39,44]:
		for variant in [0,1]:
			for seed_value in [2228242853,197682660,977]:
				var m=c.missions[index].duplicate(true)
				if variant==1:
					for stage in m.encounter_stages:
						stage.rows[0].enemy_ids=["S1-N13"] if index==39 else ["S1-N16","S1-N18"]
				var a=Arena.new();root.add_child(a)
				assert(a.configure(c,m,{"character_id":"S1-C03","completed":index,"branches":[3,3,3] if index<40 else [4,4,4],"difficulty":0,"pill_id":"","challenge_id":""},seed_value))
				for tick in 24000:
					if a.state.finished:break
					if not a.state.offered.is_empty():a.choose_upgrade(Bot.choice(a,c))
					if a.state.event_id!="":a.choose_event(true)
					a.advance(1.0/60,Bot.direction(a,m,tick))
				print(JSON.stringify({"mission":m.id,"variant":variant,"seed":seed_value,"win":a.state.victory,"time":a.state.elapsed,"hp":a.state.player.hp,"kills":a.state.player.kills,"level":a.state.player.level}))
				a.free()
	quit()
