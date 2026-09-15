extends SceneTree
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Codec=preload("res://src/campaign/campaign_arena_codec.gd")
const Catalog=preload("res://src/campaign/campaign_catalog.gd")
var failures:=0
func _initialize() -> void:
    _run.call_deferred()
func next_float(value:float) -> float:
    var bytes:=PackedByteArray()
    bytes.resize(8)
    bytes.encode_double(0,value)
    bytes.encode_u64(0,bytes.decode_u64(0)+1)
    return bytes.decode_double(0)
func _run() -> void:
    var c:Dictionary=Catalog.load_catalog()
    var m:Dictionary=c.missions[0]
    var l:Dictionary={"character_id":c.characters[0].id,"difficulty":0,"branches":[0,0,0],"completed":64,"pill_id":"","challenge_id":""}
    var a=Arena.new()
    assert(a.configure(c,m,l,72018))
    var saved:Dictionary=a.snapshot()
    var cases:Dictionary={}
    var b:Dictionary=saved.duplicate(true)
    b.numeric_bits.erase("player")
    cases["missing bit node"]=b
    b=saved.duplicate(true)
    b.numeric_bits["extra"]=null
    cases["extra bit node"]=b
    b=saved.duplicate(true)
    b.numeric_bits.player.hp=Codec.bits(NAN)
    cases["NaN bits"]=b
    b=saved.duplicate(true)
    b.numeric_bits.player.hp=Codec.bits(INF)
    cases["Inf bits"]=b
    b=saved.duplicate(true)
    b.numeric_bits.player.hp=Codec.bits(float(b.state.player.hp)-1)
    cases["bits decimal mismatch"]=b
    b=saved.duplicate(true)
    b.state.player.hp=0.0
    b.state.objective.player_alive=false
    b.state.finished=true
    b.state.objective.finished=true
    b.state.reason="player_dead"
    b.state.objective.reason="player_dead"
    b.numeric_bits=Codec.bits(b.state)
    b.numeric_bits.player.hp=Codec.bits(-next_float(0.0))
    cases["near-zero negative hp decoded"]=b
    b=saved.duplicate(true)
    b.state.skills["S1-A01"]=5
    b.numeric_bits.skills["S1-A01"]=Codec.bits(next_float(5.0))
    cases["rank one ULP above max"]=b
    b=saved.duplicate(true)
    b.state.player.max_hp=100000.0
    b.numeric_bits.player.max_hp=Codec.bits(next_float(100000.0))
    cases["maxhp one ULP above cap"]=b
    b=saved.duplicate(true)
    b.state.tick=1
    b.numeric_bits.tick=Codec.bits(next_float(1.0))
    cases["int tick converted to fractional float"]=b
    b=saved.duplicate(true)
    b.numeric_bits.player.hp="i:00160"
    cases["noncanonical integer bits"]=b
    b=saved.duplicate(true)
    b.numeric_bits.projectiles=[null]
    cases["extra array bit node"]=b
    for label in cases:
        var candidate=Arena.new()
        var accepted:bool=candidate.configure(c,m,l,72018,cases[label])
        if accepted: failures+=1
        print("REVIEW_CODEC "+JSON.stringify({"case":label,"rejected":not accepted}))
        candidate.free()
    a.free()
    print("REVIEW_CODEC failures="+str(failures))
    quit(0 if failures==0 else 1)
