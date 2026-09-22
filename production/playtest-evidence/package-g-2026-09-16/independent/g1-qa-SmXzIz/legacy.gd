extends SceneTree
const Profile=preload("res://src/campaign/campaign_profile.gd")
const Storage=preload("res://src/persistence/save_system.gd")
const Arena=preload("res://src/campaign/campaign_arena.gd")
func _initialize():
	_run.call_deferred()
func _run():
	var old:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://production/playtest-evidence/package-g-2026-09-16/baseline-f/assets/config/campaign_game.json"))
	old["content_hash"]=FileAccess.get_file_as_string("res://production/playtest-evidence/package-g-2026-09-16/baseline-f/assets/config/campaign_game.json").sha256_text()
	print("OLD_KEYS ",old.keys()," missions ",old.get("missions",[]).size())
	var current:Dictionary=load("res://src/campaign/campaign_catalog.gd").load_catalog()
	var s=Storage.new()
	assert(s.initialize("/tmp/g1-qa-SmXzIz/legacy4-a","/tmp/g1-qa-SmXzIz/legacy4-b")==0)
	var p=Profile.new()
	if not p.initialize(old,s):
		print("INIT_ERROR ",p.error)
		quit(1)
		return
	assert(p.begin_run(0).status=="OK")
	var r=p.data.current_run
	var a=Arena.new()
	root.add_child(a)
	assert(a.configure(old,old.missions[0],r.loadout,str(r.seed).to_int()))
	for i in 30:a.advance(1.0/60,Vector2.ZERO)
	assert(p.save_run(a.snapshot()))
	var bytes=[FileAccess.get_file_as_bytes("/tmp/g1-qa-SmXzIz/legacy4-a"),FileAccess.get_file_as_bytes("/tmp/g1-qa-SmXzIz/legacy4-b")]
	var q=Profile.new()
	assert(not q.initialize(current,s))
	assert(q.error=="LEGACY_ACTIVE_RUN_REQUIRES_PREVIOUS_VERSION")
	assert(bytes==[FileAccess.get_file_as_bytes("/tmp/g1-qa-SmXzIz/legacy4-a"),FileAccess.get_file_as_bytes("/tmp/g1-qa-SmXzIz/legacy4-b")])
	assert(p.abandon_run())
	q=Profile.new()
	assert(q.initialize(current,s))
	assert(q.data.current_run==null)
	print("G1_F_HASH_GUARD_PASS source/catalog fixture; zero-write reject and inactive profile load")
	a.free()
	s.free()
	quit()
