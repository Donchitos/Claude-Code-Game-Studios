extends SceneTree
const Stage = preload("res://src/gameplay/stage/stage_runtime.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var view := Rect2(-100, -50, 200, 100)
	check(Stage.draw_footprint_visible(view, Vector2(121, 0), 21), "edge tail stays visible")
	check(not Stage.draw_footprint_visible(view, Vector2(122, 0), 21), "fully outside culled")
	check(Stage.draw_footprint_visible(view, Vector2(-121, 0), 21), "negative edge inclusive")
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	check(await game.request_start_battle(101, false) == 0, "start")
	var battle = game.current_battle
	var stage = battle.stage
	for index in 12:
		check(stage._spawn_enemy(stage.ENEMY_WOLF if index % 2 else stage.ENEMY_BEETLE, Vector2.ZERO), "fixture enemy")
	stage._projectile_count = 12
	stage._pickup_count = 12
	stage._hostile_count = 8
	var camera = battle.player.get_node("Camera2D")
	var graphic_cases := 0
	if DisplayServer.get_name() != "headless":
		for case_index in 3:
			root.size = Vector2i(960, 540) if case_index == 1 else Vector2i(1280, 720)
			camera.zoom = Vector2(0.75, 0.75) if case_index == 2 else Vector2.ONE
			camera.position = Vector2(180, -90) if case_index == 2 else Vector2.ZERO
			camera.force_update_scroll()
			await process_frame
			await process_frame
			var rect: Rect2 = stage.get_global_transform_with_canvas().affine_inverse() * stage.get_viewport_rect()
			for index in 12:
				var at := Vector2(rect.end.x + (index - 4) * 10, rect.get_center().y + (index - 6) * 22)
				stage._enemy_positions[index] = at
				stage._projectile_positions[index] = at - Vector2(0, 120)
				stage._projectile_velocities[index] = Vector2.RIGHT
				stage._pickup_positions[index] = at + Vector2(0, 120)
				if index < 8:
					stage._hostile_positions[index] = at + Vector2(-30, 220)
			stage.draw_culling_enabled = false
			stage.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var reference := root.get_texture().get_image()
			stage.draw_culling_enabled = true
			stage.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var culled := root.get_texture().get_image()
			check(reference.get_data() == culled.get_data(), "pixel equivalence case %d" % case_index)
			check(stage.draw_objects_culled > 0 and stage.draw_objects_submitted > 0, "both visible and hidden fixture objects exercised")
			graphic_cases += 1
			if case_index == 2:
				culled.save_png(ProjectSettings.globalize_path("res://production/playtest-evidence/draw-culling-edge.png"))
	game.queue_free()
	await process_frame
	print("DRAW_CULLING_%s graphical_cases=%d" % ["PASS" if failures == 0 else "FAIL", graphic_cases])
	quit(0 if failures == 0 else 1)
