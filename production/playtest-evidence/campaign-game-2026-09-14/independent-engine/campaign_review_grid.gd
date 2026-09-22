extends SceneTree
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Combat=preload("res://src/campaign/campaign_combat.gd")
const Catalog=preload("res://src/campaign/campaign_catalog.gd")
var failures:=0
func _initialize() -> void:
    _run.call_deferred()
func ordered_hit_ids(a,entities:Array,start:Vector2,end:Vector2,radius:float) -> Array:
    var hits:Array=[]
    for e in entities:
        if e.hp>0 and Combat.segment_distance(a.pos(e),start,end)<=radius+e.radius: hits.append(e)
    hits.sort_custom(func(x,y):
        var dx:float=start.distance_squared_to(a.pos(x))
        var dy:float=start.distance_squared_to(a.pos(y))
        return dx<dy or (dx==dy and int(x.uid)<int(y.uid)))
    var ids:Array=[]
    for e in hits: ids.append(int(e.uid))
    return ids
func _run() -> void:
    var c:Dictionary=Catalog.load_catalog()
    var a=Arena.new()
    assert(a.configure(c,c.missions[0],{"character_id":c.characters[0].id,"difficulty":0,"branches":[0,0,0],"completed":64,"pill_id":"","challenge_id":""},72018))
    a.state.entities.clear()
    var rng:=RandomNumberGenerator.new()
    rng.seed=839201
    for i in 180:
        var e:Dictionary=a.spawn_enemy(c.enemies[i%24].id,Vector2(rng.randf_range(-900,900),rng.randf_range(-600,600)))
        e.radius=[1.0,18.0,48.0,96.0,150.0][i%5]
    var grid:Dictionary=Combat._enemy_grid(a)
    for i in 1000:
        var start:=Vector2(rng.randf_range(-1000,1000),rng.randf_range(-700,700))
        var end:=start+Vector2(rng.randf_range(-1200,1200),rng.randf_range(-800,800))
        if i%5==0: start=Vector2((i%10-5)*96,0)
        if i%7==0: end=start
        var radius:float=[1.0,7.0,18.0,96.0,150.0][i%5]
        var candidates:Array=Combat._swept_candidates(grid,start,end,radius)
        var unique:Dictionary={}
        for e in candidates: unique[int(e.uid)]=true
        var got:Array=ordered_hit_ids(a,candidates,start,end,radius)
        var expected:Array=ordered_hit_ids(a,a.state.entities,start,end,radius)
        if unique.size()!=candidates.size() or got!=expected:
            failures+=1
            print("GRID_MISMATCH ",i," ",got," ",expected)
    a.state.entities.clear()
    var large:Dictionary=a.spawn_enemy(c.enemies[0].id,Vector2(250,0))
    large.radius=150.0
    var candidates:Array=Combat._swept_candidates(Combat._enemy_grid(a),Vector2.ZERO,Vector2(100,0),1)
    var large_hit:bool=ordered_hit_ids(a,candidates,Vector2.ZERO,Vector2(100,0),1)==[int(large.uid)]
    if not large_hit: failures+=1
    a.state.entities.clear()
    var low:Dictionary=a.spawn_enemy(c.enemies[0].id,Vector2(100,10))
    var high:Dictionary=a.spawn_enemy(c.enemies[0].id,Vector2(100,-10))
    a.state.entities.reverse()
    var hp_low:float=low.hp
    var hp_high:float=high.hp
    Combat.projectile(a,Vector2.ZERO,Vector2(6000,0),1,7,1,"#ffffff","straight",1)
    Combat.advance_projectiles(a,1.0/60.0)
    var tie_ok:bool=low.hp<hp_low and high.hp==hp_high
    if not tie_ok: failures+=1
    print("REVIEW_GRID "+JSON.stringify({"queries":1000,"enemy_count":180,"radius_max":150,"negative_cell_edges":true,"zero_length_sweeps":true,"no_duplicate_candidates":failures==0,"same_fullscan_narrowphase_order":failures==0,"large_enemy_tangent":large_hit,"actual_collision_uid_tie":tie_ok,"failures":failures}))
    a.free()
    quit(0 if failures==0 else 1)
