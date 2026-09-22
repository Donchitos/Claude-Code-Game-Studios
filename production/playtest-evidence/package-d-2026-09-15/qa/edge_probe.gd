extends SceneTree
const Arena=preload("res://src/campaign/campaign_arena.gd")
var c: Dictionary
var rows: Array=[]
func _initialize():
 _run.call_deferred()
func make(index):
 var a=Arena.new()
 root.add_child(a)
 assert(a.configure(c,c.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},42))
 return a
func _run():
 c=load("res://src/campaign/campaign_catalog.gd").load_catalog()
 var a=make(0)
 # Synthetic accumulated-XP fixture, not a legal journey or balance measurement.
 a.state.player.xp=12
 a.advance(1.0/60,Vector2.ZERO)
 var offered=a.state.offered.duplicate()
 var t=a.state.tick
 a.choose_upgrade(a.state.offered[0])
 rows.append({"case":"accumulated_xp","initial_offered":offered,"tick_before":t,"tick_after":a.state.tick,"immediate_next_offer":a.state.offered.duplicate()})
 a.free()
 for index in [0,3,4,5,6,7]:
  a=make(index)
  for tick in 30000:
   if a.state.finished:break
   if not a.state.offered.is_empty():a.choose_upgrade(a.state.offered[0])
   if a.state.event_id!="":a.choose_event(false)
   a.advance(1.0/60,Vector2.ZERO)
  rows.append({"case":"idle_legal_steps","mission":a.mission.id,"finished":a.state.finished,"reason":a.state.reason,"tick":a.state.tick,"snapshot_valid":Arena.validate_snapshot(c,a.mission,a.snapshot()),"hp":a.state.player.hp,"damage_taken":a.state.statistics.damage_taken,"chapter":a.state.encounter.get("chapter",{}).duplicate(true),"skills":a.state.skills.duplicate(true),"arena_elapsed":a.state.elapsed,"objective_elapsed":a.state.objective.elapsed})
  a.free()
 var f=FileAccess.open("res://production/playtest-evidence/package-d-2026-09-15/qa/edge-results.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(rows,"\t"))
 print(JSON.stringify(rows))
 quit()
