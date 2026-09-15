extends SceneTree
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Catalog=preload("res://src/campaign/campaign_catalog.gd")
const Profile=preload("res://src/campaign/campaign_profile.gd")
const Storage=preload("res://src/persistence/save_system.gd")
func _initialize() -> void:
    _run.call_deferred()
func normalized(v:Variant) -> Variant:
    if v is Dictionary:
        var out:Dictionary={}
        for key in v: out[str(key)]=normalized(v[key])
        return out
    if v is Array:
        var out:Array=[]
        for item in v: out.append(normalized(item))
        return out
    return v
func difference(a:Variant,b:Variant,path:String="") -> String:
    if a is Dictionary and b is Dictionary:
        if a.size()!=b.size(): return path+" dictionary size"
        for key in a:
            if not b.has(key): return path+" missing "+str(key)
            var d:=difference(a[key],b[key],path+"."+str(key))
            if d!="": return d
        return ""
    if a is Array and b is Array:
        if a.size()!=b.size(): return path+" array size "+str(a.size())+" vs "+str(b.size())
        for i in a.size():
            var d:=difference(a[i],b[i],path+"["+str(i)+"]")
            if d!="": return d
        return ""
    if (a is int or a is float) and (b is int or b is float):
        return "" if float(a)==float(b) else path+": "+JSON.stringify(a,"",true,true)+" vs "+JSON.stringify(b,"",true,true)
    return "" if a==b else path+": "+str(a)+" vs "+str(b)
func resolve(a) -> void:
    if not a.state.offered.is_empty(): assert(a.choose_upgrade(str(a.state.offered[0])))
    elif a.state.event_id!="": assert(a.choose_event(false))
func _run() -> void:
    var c:Dictionary=Catalog.load_catalog()
    var nonce:=str(OS.get_process_id())
    var path_a:="/tmp/campaign_review_disk_"+nonce+"_a.save"
    var path_b:="/tmp/campaign_review_disk_"+nonce+"_b.save"
    var storage=Storage.new()
    assert(storage.initialize(path_a,path_b,{})==0)
    var profile=Profile.new()
    assert(profile.initialize(c,storage))
    assert(profile.begin_run(0).status=="OK")
    var run:Dictionary=profile.data.current_run
    var a=Arena.new()
    assert(a.configure(c,c.missions[0],run.loadout,int(run.seed)))
    for i in 237:
        resolve(a)
        a.advance(1.0/60.0,Vector2(cos(i*0.031),sin(i*0.031))*0.4)
    var before:Dictionary=a.snapshot()
    var success:bool=profile.save_run(before)
    print("REVIEW_DISK_WRITE "+JSON.stringify({"ok":success,"error":profile.error,"tick":a.state.tick,"paths":[path_a,path_b]}))
    if not success:
        a.free()
        storage.free()
        quit(1)
        return
    var storage2=Storage.new()
    assert(storage2.initialize(path_a,path_b,{})==0)
    var profile2=Profile.new()
    assert(profile2.initialize(c,storage2))
    var persisted:Dictionary=profile2.data.current_run
    var before_diff:=difference(normalized(before),normalized(persisted.snapshot))
    var b=Arena.new()
    var accepted:bool=b.configure(c,c.missions[0],persisted.loadout,int(persisted.seed),persisted.snapshot)
    var restored_diff:=difference(normalized(before),normalized(b.snapshot())) if accepted else "rejected"
    print("REVIEW_DISK_RESTORE "+JSON.stringify({"accepted":accepted,"decimal_mirror_difference":before_diff,"restored_state_difference":restored_diff,"rng_original":before.rng_state,"rng_restored":persisted.snapshot.get("rng_state","missing")}))
    var bad_tick:=-1
    var leaf:=""
    if accepted:
        for i in 200:
            resolve(a)
            resolve(b)
            var movement:=Vector2(cos(i*0.057),sin(i*0.057))*0.7
            a.advance(1.0/60.0,movement)
            b.advance(1.0/60.0,movement)
            leaf=difference(normalized(a.snapshot()),normalized(b.snapshot()))
            if leaf!="":
                bad_tick=i+1
                break
    print("REVIEW_DISK_CONTINUATION "+JSON.stringify({"pass":accepted and bad_tick==-1 and restored_diff=="","requested_ticks":200,"first_divergent_tick":bad_tick,"difference":leaf,"original_tick":a.state.tick,"restored_tick":b.state.get("tick",-1),"scope":"Real ProductionSaveSystem disk slots and new Storage/Profile, exact numeric equality after int/float normalization; no direct fullprecision-only shortcut"}))
    a.free()
    b.free()
    storage.free()
    storage2.free()
    quit(0 if accepted and bad_tick==-1 and restored_diff=="" else 1)
