extends SceneTree
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Codec = preload("res://src/campaign/campaign_arena_codec.gd")
func _initialize() -> void:
 var c: Dictionary = load("res://src/campaign/campaign_catalog.gd").load_catalog()
 var a = Arena.new()
 var b = Arena.new()
 var l := {"character_id":"S1-C01","completed":0,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""}
 assert(a.configure(c,c.missions[0],l,42))
 a.state.player.xp = 100
 a.advance(1.0/60,Vector2.ZERO)
 assert(a.choose_upgrade(a.state.offered[0]))
 var s: Dictionary = a.snapshot()
 print("ORIGINAL last_upgrade_tick=",s.state.encounter.last_upgrade_tick," level=",s.state.player.level)
 s.state.encounter.last_upgrade_tick = -1
 s.numeric_bits = Codec.bits(s.state)
 print("MODIFIED_SENTINEL_VALID=",Arena.validate_snapshot(c,c.missions[0],s))
 print("RESTORE=",b.configure(c,c.missions[0],l,42,s))
 b.advance(1.0/60,Vector2.ZERO)
 print("NEXT_TICK level=",b.state.player.level," offered=",b.state.offered)
 a.free()
 b.free()
 quit()
