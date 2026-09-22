extends SceneTree
var game
func _initialize():
 run.call_deferred()
func settle():
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
func snap(name):
 await settle()
 root.get_texture().get_image().save_png('/tmp/g-ui-'+name+'.png')
func run():
 assert('--campaign-validation' in OS.get_cmdline_user_args())
 game=load('res://src/campaign/CampaignGame.tscn').instantiate()
 root.add_child(game)
 root.size=Vector2i(960,540)
 await settle()
 for locale in ['zh-CN','en']:
  assert(game.profile.update_settings({'font_scale':1.3,'locale':locale}))
  game.show_page('chapters')
  await settle()
  for ordinal in ['02','03','05','07']:
   var found=false
   for b in game.ui.buttons:
    if b.text.begins_with(ordinal+' '):
     b.disabled=false # only allow focus on a locked chapter-card fixture; do not activate.
     b.grab_focus()
     await snap(locale+'-'+ordinal)
     print('BRIEF ',locale,' ',ordinal,' size=',b.size,' minimum=',b.get_combined_minimum_size(),' text=',b.text)
     found=true
     break
   assert(found)
 assert(game.start_mission(0))
 game.set_physics_process(false)
 var c=game.catalog
 assert(game.arena.configure(c,c.missions[7],{'character_id':'S1-C01','completed':7,'branches':[0,0,0],'difficulty':0,'pill_id':'','challenge_id':''},42))
 var a=game.arena
 var e=a.state.entities[0]
 e.hp=e.max_hp*0.6
 a.Chapter.boss(a,e,a.player_world_position())
 assert(a.state.encounter.chapter.landings.size()==2)
 assert(a.state.zones.size()==2)
 for z in a.state.zones: assert(z.delay>=0.9)
 a.queue_redraw()
 game.ui.render('battle')
 await snap('boss-warning')
 print('BOSS_VISIBLE_WARNING ',JSON.stringify(a.state.zones),' pending=',JSON.stringify(a.state.encounter.chapter.landings))
 game.queue_free()
 await process_frame
 print('G_UI_PROBE_PASS')
 quit()
