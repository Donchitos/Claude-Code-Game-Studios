extends SceneTree

# Isolated rendering candidate. No production rendering switch or save access.
const Stage = preload("res://src/gameplay/stage/stage_runtime.gd")
const WARMUP := 30
const SAMPLES := 180
class Stamp extends Node2D:
	var sword := false
	func _draw() -> void:
		if sword:
			draw_line(Vector2(16, 32), Vector2(44, 32), Color("d6f5ff"), 7.0)
			draw_circle(Vector2(32, 32), 9.0, Color("80d9ef"))
		else:
			draw_circle(Vector2(32, 32), 23.0, Color(0, 0, 0, 0.3))
			draw_circle(Vector2(32, 32), 19.0, Color("a93d49"))

func _initialize() -> void:
	_run.call_deferred()
func stats(values: Array[float]) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in values:
		total += value
	return {"mean_ms": total / values.size(), "p95_ms": sorted[ceili(sorted.size() * 0.95) - 1]}
func make_batch(texture: Texture2D, count: int) -> MultiMeshInstance2D:
	var node := MultiMeshInstance2D.new()
	node.texture = texture
	var mesh := QuadMesh.new()
	mesh.size = Vector2(64, 64)
	node.multimesh = MultiMesh.new()
	node.multimesh.transform_format = MultiMesh.TRANSFORM_2D
	node.multimesh.mesh = mesh
	node.multimesh.instance_count = count
	return node
func upload(batch: MultiMeshInstance2D, positions: PackedVector2Array) -> void:
	for index in positions.size():
		batch.multimesh.set_instance_transform_2d(index, Transform2D(0.0, positions[index]))
func capture(path: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	result.save_png(ProjectSettings.globalize_path(path))
	return result
func compare(a: Image, b: Image) -> Dictionary:
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var left := a.get_data()
	var right := b.get_data()
	var changed := 0
	var over_eight := 0
	var maximum := 0
	for pixel in a.get_width() * a.get_height():
		var difference := 0
		for channel in 3:
			difference = maxi(difference, absi(int(left[pixel * 4 + channel]) - int(right[pixel * 4 + channel])))
		if difference > 0:
			changed += 1
		if difference > 8:
			over_eight += 1
		maximum = maxi(maximum, difference)
	return {"changed_pixels": changed, "pixels_channel_delta_gt8": over_eight, "max_channel_delta": maximum, "pixel_identical": changed == 0}
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run this graphical probe without --headless")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	var textures: Array[ImageTexture] = []
	for sword in [false, true]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(64, 64)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var stamp := Stamp.new()
		stamp.sword = sword
		viewport.add_child(stamp)
		await process_frame
		await RenderingServer.frame_post_draw
		textures.append(ImageTexture.create_from_image(viewport.get_texture().get_image()))
		viewport.queue_free()
		await process_frame
	var stage := Stage.new()
	root.add_child(stage)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/config/production_defaults.json"))
	if not stage.configure(config, 101):
		quit(3)
		return
	stage._focus_position = Vector2(640, 360)
	stage.measure_draw_cpu = true
	var enemies := make_batch(textures[0], 319)
	var swords := make_batch(textures[1], 392)
	stage.add_child(enemies)
	stage.add_child(swords)
	enemies.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	swords.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var results: Array[Dictionary] = []
	for layout: String in ["spread", "overlap", "mixed"]:
		var enemy_positions := PackedVector2Array()
		var sword_positions := PackedVector2Array()
		for index in 319:
			var point := Vector2(50 + (index % 23) * 51, 60 + (index / 23) * 43)
			if layout != "spread":
				point = Vector2(460 + (index % 23) * 16, 240 + (index / 23) * 16)
			enemy_positions.append(point)
			stage._enemy_positions[index] = point
			stage._enemy_kind[index] = stage.ENEMY_BEETLE
		for index in 392:
			var point := Vector2(45 + (index % 28) * 43, 75 + (index / 28) * 43)
			if layout == "mixed":
				point = Vector2(450 + (index % 28) * 13, 235 + (index / 28) * 16)
			sword_positions.append(point)
			stage._projectile_positions[index] = point
			stage._projectile_velocities[index] = Vector2.RIGHT
		stage._enemy_count = 319
		stage._projectile_count = 392
		enemies.visible = false
		swords.visible = false
		stage.queue_redraw()
		var original := await capture("res://production/playtest-evidence/batch-%s-reference.png" % layout)
		var row := {"layout": layout}
		for batched in [false, true]:
			stage._enemy_count = 0 if batched else 319
			stage._projectile_count = 0 if batched else 392
			enemies.visible = batched
			swords.visible = batched
			var frame_times: Array[float] = []
			var update_times: Array[float] = []
			var draw_times: Array[float] = []
			for frame in WARMUP + SAMPLES:
				var start := Time.get_ticks_usec()
				if batched:
					upload(enemies, enemy_positions)
					upload(swords, sword_positions)
				stage.queue_redraw()
				var submitted := Time.get_ticks_usec()
				await process_frame
				if frame >= WARMUP:
					frame_times.append((Time.get_ticks_usec() - start) / 1000.0)
					update_times.append((submitted - start) / 1000.0)
					draw_times.append(stage.last_draw_cpu_usec / 1000.0)
			row["batched" if batched else "reference"] = {"frame": stats(frame_times), "upload_cpu": stats(update_times), "stage_draw_cpu": stats(draw_times)}
		var candidate := await capture("res://production/playtest-evidence/batch-%s-candidate.png" % layout)
		row["image_comparison"] = compare(original, candidate)
		if layout == "overlap":
			var reversed := enemy_positions.duplicate()
			reversed.reverse()
			upload(enemies, reversed)
			var reversed_image := await capture("res://production/playtest-evidence/batch-overlap-reversed-control.png")
			row["order_negative_control"] = compare(candidate, reversed_image)
		results.append(row)
		print("DENSE_BATCH_CASE ", JSON.stringify(row))
	var report := {"platform": OS.get_name(), "renderer": DisplayServer.get_name(), "warmup": WARMUP, "samples": SAMPLES, "enemy_count": 319, "sword_count": 392, "simulation_included": false, "production_enabled": false, "cases": results}
	var file := FileAccess.open("res://production/playtest-evidence/dense-batch-probe.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	stage.queue_free()
	await process_frame
	print("DENSE_BATCH_PROBE_COMPLETED visual_acceptance_separate=true")
	quit()
