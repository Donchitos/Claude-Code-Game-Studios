extends SceneTree
const Arena=preload("res://src/campaign/campaign_arena.gd")
const Combat=preload("res://src/campaign/campaign_combat.gd")
const Catalog=preload("res://src/campaign/campaign_catalog.gd")
const Profile=preload("res://src/campaign/campaign_profile.gd")
const Storage=preload("res://src/persistence/save_system.gd")
var c: Dictionary
var failures:=0
func _initialize() -> void:
    _run.call_deferred()
func fresh(index:int=0):
    var a=Arena.new()
    assert(a.configure(c,c.missions[index],{"character_id":c.characters[0].id,"difficulty":0,"branches":[0,0,0],"completed":64,"pill_id":"","challenge_id":""},72018))
    a.state.entities.clear()
    return a
func result(label:String,passed:bool,detail:Dictionary={}) -> void:
    if not passed: failures+=1
    print("REVIEW_CASE "+JSON.stringify({"case":label,"pass":passed,"detail":detail}))
func _run() -> void:
    c=Catalog.load_catalog()
    assert(not c.is_empty())
    var a=fresh()
    var hp:float=a.state.player.hp
    Combat.zone(a,Vector2.ZERO,100,0,1,"#ffffff","shield",false,0)
    Combat.projectile(a,Vector2(50,0),Vector2(230,0),10,7,4,"#ffffff","straight",1,0,true)
    var erased:Dictionary=Combat.projectile(a,Vector2(25,0),Vector2(-230,0),10,7,4,"#ffffff","straight",1,0,true)
    Combat.advance_zones(a,1.0/60.0)
    var erased_ttl:float=erased.ttl
    Combat.advance_projectiles(a,1.0/60.0)
    result("shield erased projectile cannot damage",a.state.player.hp==hp,{"erased_ttl":erased_ttl,"before_hp":hp,"after_hp":a.state.player.hp})
    a.free()
    a=fresh()
    hp=a.state.player.hp
    Combat.zone(a,Vector2.ZERO,50,0,0.1,"#ffffff","line",true,0)
    Combat.advance_zones(a,1.0/60.0)
    result("zero-damage warning remains harmless",a.state.player.hp==hp,{"before_hp":hp,"after_hp":a.state.player.hp,"invulnerable":a.state.player.invulnerable})
    a.free()
    a=fresh()
    a.set_pos(a.state.player,Vector2(400,0))
    var boss:Dictionary=a.spawn_enemy("S1-B01",Vector2.ZERO,"boss")
    boss.timer=0
    Combat.advance_enemies(a,1.0/60.0)
    result("boss pounce movement survives tick",a.pos(boss).x>100,{"boss_x":a.pos(boss).x})
    a.free()
    a=fresh(8)
    Combat.environment_pattern(a)
    result("chapter2 has line hazard",a.state.zones[0].kind=="line",{"theme":a.mission.theme,"kind":a.state.zones[0].kind})
    a.free()
    a=fresh()
    a.state.passives={"S1-P11":1}
    a.spawn_enemy("S1-N01",Vector2(1000,0))
    Combat.zone(a,Vector2.ZERO,20,10,2,"#ffffff","turret",false,0)
    Combat.advance_zones(a,1.0/60.0)
    result("summon +50 does not acquire at1000",a.state.projectiles.is_empty(),{"projectiles":a.state.projectiles.size()})
    a.free()
    a=fresh()
    a.state.passives={"S1-P19":1}
    a.state.skills={"S1-A01":1}
    Combat.advance_skills(a,0)
    var expected:float=float(a.tables.skills["S1-A01"].cooldown)/1.15
    result("charge passive consumed",is_equal_approx(float(a.state.cooldowns["S1-A01"]),expected),{"actual":a.state.cooldowns["S1-A01"],"expected":expected})
    a.free()
    a=fresh()
    a.state.passives={"S1-P07":1}
    hp=a.state.player.hp
    a.damage_player(20)
    var rank1:float=hp-a.state.player.hp
    a.state.player.hp=hp
    a.state.player.invulnerable=0
    a.state.passives["S1-P07"]=2
    a.damage_player(20)
    var rank2:float=hp-a.state.player.hp
    result("armor rank2 improves rank1",rank2<rank1,{"damage_rank1":rank1,"damage_rank2":rank2})
    a.free()
    a=fresh()
    a.state.event_id=c.events[0].id
    assert(a.choose_event(false))
    var stats:Dictionary=a.stats()
    result("safe event receipts emitted",stats.get("safe_choices",0)==1 and stats.get("event_reward",0)==c.events[0].safe.reward,stats)
    var storage=Storage.new()
    assert(storage.initialize()==0)
    var profile=Profile.new()
    assert(profile.initialize(c,storage))
    for index in 3:
        assert(profile.begin_run(index).status=="OK")
        assert(profile.finish_run(true,{}).status=="OK")
    assert(profile.begin_run(3).status=="OK")
    var settled:Dictionary=profile.finish_run(true,stats)
    result("event reward reaches profile",settled.get("reward",0)==c.missions[3].reward+c.events[0].safe.reward,{"result":settled,"expected":c.missions[3].reward+c.events[0].safe.reward})
    storage.free()
    a.free()
    a=fresh()
    a.state.skills={"S1-A07":1,"S1-A04":1}
    var saved:Dictionary=JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true))
    var b=Arena.new()
    var restored:bool=b.configure(c,c.missions[0],saved.loadout,72018,saved)
    result("reverse skills snapshot accepted",restored)
    if restored:
        Combat.advance_skills(a,1.0/60.0)
        Combat.advance_skills(b,1.0/60.0)
        result("reverse skills same next execution",JSON.stringify(JSON.parse_string(JSON.stringify(a.snapshot(),"",true,true)),"",true,true)==JSON.stringify(JSON.parse_string(JSON.stringify(b.snapshot(),"",true,true)),"",true,true),{"original_skill_order":a.state.skills.keys(),"restored_skill_order":b.state.skills.keys(),"original_first_projectile":a.state.projectiles[0].mode,"restored_first_projectile":b.state.projectiles[0].mode})
    a.free()
    b.free()
    print("REVIEW_COUNTEREXAMPLES failures="+str(failures))
    quit(0 if failures==0 else 1)
