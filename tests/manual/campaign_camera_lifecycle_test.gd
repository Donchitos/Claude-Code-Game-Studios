extends SceneTree
var game
var evidence: String = preload("res://tests/fixtures/campaign_evidence.gd").create("camera-lifecycle")
var failures := 0
var rows := []
func _initialize():
 run.call_deferred()
func check(ok, label):
 if not ok:
  failures += 1
  push_error(label)
func settle():
 for i in 4: await process_frame
 await RenderingServer.frame_post_draw
func inspect(label):
 var rect = game.get_viewport_rect()
 var tx = game.arena.get_global_transform_with_canvas()
 var inv = tx.affine_inverse()
 var visible = (inv*rect.end-inv*rect.position).abs()
 var err = (tx*game.arena.player_world_position()).distance_to(rect.get_center())
 check(visible.x <= 1280.1 and visible.y <= 720.1, label+" visible")
 check(err < 1.0,label+" center")
 rows.append({"label":label,"visible":str(visible),"center_error":err,"zoom":str(game.camera.zoom),"paused":game.paused,"tick":game.arena.state.tick})
func run():
 assert("--campaign-validation" in OS.get_cmdline_user_args())
 game = load("res://src/campaign/CampaignGame.tscn").instantiate()
 root.add_child(game)
 await settle()
 check(game.start_mission(0),"start")
 await settle()
 inspect("started")
 game.pause_battle()
 check(game.paused,"pause entered")
 var snap = game.arena.snapshot()
 for dimensions in [Vector2i(1600,600),Vector2i(800,1000),Vector2i(960,540),Vector2i(1280,720)]:
  root.size = dimensions
  await settle()
  inspect("paused resize "+str(dimensions))
  check(game.arena.snapshot() == snap,"resize must not mutate simulation or RNG")
 game.focused = true
 var before_resume_tick = game.arena.state.tick
 game.resume_battle()
 await physics_frame
 await physics_frame
 await settle()
 check(not game.paused and game.arena.state.tick > before_resume_tick,"resume advances active simulation")
 inspect("resumed")
 game.pause_battle()
 check(game.paused,"pause before save")
 var saved_tick = game.arena.state.tick
 check(game.save_and_home(),"save home")
 root.size = Vector2i(1600,600)
 await settle()
 check(game.continue_run(),"continue")
 await physics_frame
 await physics_frame
 await settle()
 check(not game.paused and game.arena.state.tick > saved_tick,"continue advances active simulation")
 inspect("restored ultrawide")
 game.pause_battle()
 var file = FileAccess.open(evidence+"camera-lifecycle.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"failures":failures,"rows":rows},"\t"))
 file.close()
 print("CAMERA_LIFECYCLE ",JSON.stringify({"failures":failures,"rows":rows}))
 game.queue_free()
 await process_frame
 quit(failures)
