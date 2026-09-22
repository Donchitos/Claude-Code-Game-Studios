extends SceneTree
func _initialize(): run.call_deferred()
func run():
 assert("--campaign-validation" in OS.get_cmdline_user_args())
 assert(DisplayServer.get_name() != "headless")
 for spec in [[39,"en",1280],[55,"en",1280],[62,"zh-CN",1280]]:
  var index: int=spec[0]
  root.size=Vector2i(spec[2],int(spec[2]*9/16))
  var game = load("res://src/campaign/CampaignGame.tscn").instantiate()
  root.add_child(game)
  await process_frame
  game.set_physics_process(false)
  assert(game.profile.update_settings({"locale":spec[1],"font_scale":1.3}))
  assert(game.start_mission(0))
  assert(game.arena.configure(game.catalog,game.catalog.missions[index],{"character_id":"S1-C01","completed":index,"branches":[0,0,0],"difficulty":0,"pill_id":"","challenge_id":""},711))
  game.ui.render("battle")
  game.arena.state.player.x=150.0
  game.arena.state.player.y=0.0
  if game.arena.mission.kind == "BOSS":
   var e:Dictionary=game.arena.state.entities[0]
   e.timer=0.0
   game.arena.Encounter.Late.boss(game.arena,e,Vector2(150,0))
  else:
   game.arena.emit_layout_root(game.arena.Encounter.layout(game.catalog,game.arena.mission).roots[0],0)
  game.camera.position=game.arena.player_world_position()
  game.camera.position_smoothing_enabled=false
  game._update_camera_view()
  game.camera.force_update_scroll()
  game.ui.update_hud()
  game.arena.queue_redraw()
  await process_frame
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/late-ui-tuned-%d-%s-%d.png"%[index,spec[1],spec[2]])
  print("UI_FIXTURE ",index," ",game.arena.teaching_text(game.profile.data.settings.locale))
  game.queue_free()
  await process_frame
  await process_frame
 quit()
