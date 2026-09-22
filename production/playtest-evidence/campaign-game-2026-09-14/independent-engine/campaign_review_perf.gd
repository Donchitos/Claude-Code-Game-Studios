extends SceneTree
const Arena = preload("res://src/campaign/campaign_arena.gd")
const Combat = preload("res://src/campaign/campaign_combat.gd")
const Catalog = preload("res://src/campaign/campaign_catalog.gd")
const WARMUP = 120
const SAMPLES = 600
func _initialize() -> void:
    _run.call_deferred()
func _run() -> void:
    var c: Dictionary = Catalog.load_catalog()
    assert(not c.is_empty())
    for scenario in ["distributed", "clustered"]:
        var a = Arena.new()
        var m: Dictionary = c.missions[0].duplicate(true)
        m.target_seconds = 9000.0
        m.timeout_seconds = 10000.0
        var loadout = {"character_id": c.characters[0].id, "difficulty": 0, "branches": [0,0,0], "completed": 64, "pill_id": "", "challenge_id": ""}
        assert(a.configure(c,m,loadout,72018))
        a.state.skills = {"S1-A01":5,"S1-A04":5,"S1-A07":5,"S1-A13":5}
        a.state.passives = {"S1-P01":5,"S1-P02":5,"S1-P03":5,"S1-P14":5}
        a.state.player.hp = 100000.0
        a.state.player.max_hp = 100000.0
        a.state.event_done = true
        a.state.spawn_clock = 10000.0
        a.state.entities.clear()
        var samples: Array[float] = []
        var max_zones := 0
        var serial := 0
        for frame in WARMUP + SAMPLES:
            a.state.offered.clear()
            a.state.player.xp = 0.0
            a.state.player.hp = 100000.0
            a.state.elite_clock = 0.0
            while a.state.entities.size() < 180:
                var idx: int = a.state.entities.size()
                var pos := Vector2((idx % 18 - 8.5) * 90, (idx / 18 - 4.5) * 90)
                if scenario == "clustered": pos *= 0.22
                var e: Dictionary = a.spawn_enemy(c.enemies[idx % 24].id,pos)
                assert(not e.is_empty())
                e.hp = 1000000.0
                e.max_hp = 1000000.0
            while a.state.projectiles.size() < 400:
                var angle: float = serial * 2.399963
                var pos := Vector2(cos(angle)*650,sin(angle)*420)
                if scenario == "clustered": pos *= 0.22
                var velocity := (a.player_world_position()-pos).normalized()*450
                var p: Dictionary = Combat.projectile(a,pos,velocity,12,10,4,"#6ae8ed","pierce",16)
                assert(not p.is_empty())
                serial += 1
            assert(a.state.entities.size()==180 and a.state.projectiles.size()==400)
            var tick_before: int = a.state.tick
            var started := Time.get_ticks_usec()
            a.advance(1.0/60.0,Vector2.from_angle(frame*0.035)*0.25)
            var elapsed := float(Time.get_ticks_usec()-started)/1000.0
            assert(a.state.tick==tick_before+1 and not a.state.finished)
            a.sound_events.clear()
            if frame >= WARMUP: samples.append(elapsed)
            max_zones = maxi(max_zones,a.state.zones.size())
        samples.sort()
        print("REVIEW_PERF "+JSON.stringify({"scenario":scenario,"engine":Engine.get_version_info().string,"cpu":OS.get_processor_name(),"samples":SAMPLES,"warmup":WARMUP,"enemies_at_tick_start":180,"projectiles_at_tick_start":400,"p50_ms":samples[int(ceil(SAMPLES*0.50))-1],"p95_ms":samples[int(ceil(SAMPLES*0.95))-1],"max_ms":samples[-1],"max_zones":max_zones,"scope":"CPU elapsed duration of actual Arena.advance(1/60); off-tree no rendering, no storage IO; fixture replenishment excluded; mixed 24 AI; 4 rank5 skills and passives; synthetic saturation, not FPS"}))
        a.free()
    quit()
