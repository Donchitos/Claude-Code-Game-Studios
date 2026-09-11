extends SceneTree

# Production renderer A/B probe. No simulation or save access.
const Stage = preload("res://src/gameplay/stage/stage_runtime.gd")
const WARMUP := 30
const SAMPLES := 180

func _initialize() -> void:
	_run.call_deferred()

func _stats(values: Array[float]) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in values:
		total += value
	return {"mean_ms": total / values.size(), "p95_ms": sorted[ceili(sorted.size() * 0.95) - 1]}

func _capture(path: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	result.save_png(ProjectSettings.globalize_path(path))
	return result

func _compare(left_image: Image, right_image: Image) -> Dictionary:
	left_image.convert(Image.FORMAT_RGBA8)
	right_image.convert(Image.FORMAT_RGBA8)
	var left := left_image.get_data()
	var right := right_image.get_data()
	var changed := 0
	var over_one := 0
	var over_eight := 0
	var maximum := 0
	for pixel in left_image.get_width() * left_image.get_height():
		var difference := 0
		for channel in 3:
			difference = maxi(difference, absi(int(left[pixel * 4 + channel]) - int(right[pixel * 4 + channel])))
		if difference > 0:
			changed += 1
		if difference > 1:
			over_one += 1
		if difference > 8:
			over_eight += 1
		maximum = maxi(maximum, difference)
	return {"changed_pixels": changed, "pixels_channel_delta_gt1": over_one, "pixels_channel_delta_gt8": over_eight, "max_channel_delta": maximum, "pixel_identical": changed == 0}

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run this graphical probe without --headless")
		quit(2)
		return
	OS.low_processor_usage_mode = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1280, 720)
	var stage := Stage.new()
	root.add_child(stage)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/config/production_defaults.json"))
	if not stage.configure(config, 101):
		quit(3)
		return
	stage._focus_position = Vector2(640, 360)
	stage.measure_draw_cpu = true
	var results: Array[Dictionary] = []
	var visual_pass := true
	for layout: String in ["spread", "overlap", "mixed_types"]:
		print("DENSE_BATCH_BEGIN layout=%s" % layout)
		for index in 319:
			var point := Vector2(50 + (index % 23) * 51, 60 + (index / 23) * 43)
			if layout != "spread":
				point = Vector2(460 + (index % 23) * 16, 240 + (index / 23) * 16)
			stage._enemy_positions[index] = point
			stage._enemy_kind[index] = [stage.ENEMY_BEETLE, stage.ENEMY_WOLF, stage.ENEMY_SUMMON][index % 3] if layout == "mixed_types" else stage.ENEMY_BEETLE
		for index in 392:
			var point := Vector2(45 + (index % 28) * 43, 75 + (index / 28) * 43)
			if layout == "mixed_types":
				point = Vector2(450 + (index % 28) * 13, 235 + (index / 28) * 16)
			var angle := 0.0 if layout == "spread" else (index % 16) * TAU / 16.0
			stage._projectile_positions[index] = point
			stage._projectile_velocities[index] = Vector2.RIGHT.rotated(angle)
		stage._enemy_count = 319
		stage._projectile_count = 392
		var row := {"layout": layout}
		var reference_image: Image
		for batched in [false, true]:
			print("DENSE_BATCH_MODE layout=%s batched=%s" % [layout, batched])
			stage.geometry_batch_enabled = batched
			var frame_times: Array[float] = []
			var draw_times: Array[float] = []
			for frame in WARMUP + SAMPLES:
				var start := Time.get_ticks_usec()
				stage.queue_redraw()
				await process_frame
				if frame >= WARMUP:
					frame_times.append((Time.get_ticks_usec() - start) / 1000.0)
					draw_times.append(stage.last_draw_cpu_usec / 1000.0)
			row["geometry" if batched else "reference"] = {"frame": _stats(frame_times), "stage_draw_cpu": _stats(draw_times)}
			var image_path := "res://production/playtest-evidence/batch-%s-%s.png" % [layout, "geometry" if batched else "reference"]
			var captured := await _capture(image_path)
			if not batched:
				reference_image = captured
			else:
				var comparison := _compare(reference_image, captured)
				row["image_comparison"] = comparison
				visual_pass = visual_pass and comparison.max_channel_delta <= 1 and comparison.pixels_channel_delta_gt1 == 0
		results.append(row)
		print("DENSE_BATCH_CASE ", JSON.stringify(row))
	var report := {"platform": OS.get_name(), "renderer": DisplayServer.get_name(), "warmup": WARMUP, "samples": SAMPLES, "enemy_count": 319, "sword_count": 392, "simulation_included": false, "production_enabled": true, "visual_pass": visual_pass, "cases": results}
	var file := FileAccess.open("res://production/playtest-evidence/dense-batch-probe.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	stage.queue_free()
	await process_frame
	print("DENSE_BATCH_PROBE_%s production_enabled=true" % ("PASS" if visual_pass else "FAIL"))
	quit(0 if visual_pass else 1)
