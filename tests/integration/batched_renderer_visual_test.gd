extends SceneTree

const Renderer = preload("res://src/gameplay/stage/batched_combat_renderer.gd")
const BEETLE_RADIUS := 19.0
const WOLF_RADIUS := 15.0
const SWORD_RADIUS := 9.0

class ReferenceDrawing extends Node2D:
	var enemy_positions := PackedVector2Array()
	var enemy_kinds := PackedByteArray()
	var enemy_scales := PackedVector2Array()
	var projectile_positions := PackedVector2Array()
	var projectile_velocities := PackedVector2Array()
	var projectile_scales := PackedVector2Array()
	func _draw() -> void:
		for index in enemy_positions.size():
			draw_set_transform(enemy_positions[index], 0.0, enemy_scales[index])
			if enemy_kinds[index] == Renderer.KIND_WOLF:
				for pair in [[Vector2(0, -WOLF_RADIUS), Vector2(WOLF_RADIUS, 0)], [Vector2(WOLF_RADIUS, 0), Vector2(0, WOLF_RADIUS)], [Vector2(0, WOLF_RADIUS), Vector2(-WOLF_RADIUS, 0)], [Vector2(-WOLF_RADIUS, 0), Vector2(0, -WOLF_RADIUS)]]:
					draw_line(pair[0], pair[1], Color("e17a45"), 9.0)
			else:
				draw_circle(Vector2.ZERO, BEETLE_RADIUS + 4.0, Color(0, 0, 0, 0.3))
				draw_circle(Vector2.ZERO, BEETLE_RADIUS, Color("a93d49"))
		for index in projectile_positions.size():
			draw_set_transform(projectile_positions[index], projectile_velocities[index].angle(), projectile_scales[index])
			draw_line(Vector2(-16, 0), Vector2(12, 0), Color("d6f5ff"), 7.0)
			draw_circle(Vector2.ZERO, SWORD_RADIUS, Color("80d9ef"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _initialize() -> void:
	_run.call_deferred()

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
	var maximum := 0
	for pixel in left_image.get_width() * left_image.get_height():
		var difference := 0
		for channel in 3:
			difference = maxi(difference, absi(int(left[pixel * 4 + channel]) - int(right[pixel * 4 + channel])))
		if difference > 0:
			changed += 1
		if difference > 1:
			over_one += 1
		maximum = maxi(maximum, difference)
	return {"changed_pixels": changed, "pixels_channel_delta_gt1": over_one, "max_channel_delta": maximum}

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("BATCHED_RENDERER_VISUAL_SKIP graphical_required=true")
		quit()
		return
	root.size = Vector2i(1280, 720)
	var reference := ReferenceDrawing.new()
	root.add_child(reference)
	var renderer := Renderer.new()
	root.add_child(renderer)
	if not renderer.initialize(12, 12, BEETLE_RADIUS, WOLF_RADIUS, SWORD_RADIUS):
		quit(1)
		return
	for index in 12:
		var position_value := Vector2(120 + (index % 6) * 190, 120 + (index / 6) * 210)
		var kind: int = [Renderer.KIND_BEETLE, Renderer.KIND_WOLF, Renderer.KIND_SUMMON][index % 3]
		var scale_value: Vector2 = [Vector2(0.75, 0.75), Vector2.ONE, Vector2(1.25, 1.25)][index % 3]
		reference.enemy_positions.append(position_value)
		reference.enemy_kinds.append(kind)
		reference.enemy_scales.append(scale_value)
		var projectile_position := Vector2(100 + (index % 6) * 195, 230 + (index / 6) * 260)
		var velocity := Vector2.RIGHT.rotated(index * TAU / 12.0)
		var projectile_scale: Vector2 = [Vector2(0.75, 0.75), Vector2.ONE, Vector2(1.25, 1.25)][(index + 1) % 3]
		reference.projectile_positions.append(projectile_position)
		reference.projectile_velocities.append(velocity)
		reference.projectile_scales.append(projectile_scale)
		renderer.append_enemy(kind, position_value, scale_value)
		renderer.append_projectile(projectile_position, velocity, projectile_scale)
	renderer.finish_frame()
	renderer.visible = false
	var reference_image := await _capture("res://production/playtest-evidence/batch-geometry-transform-reference.png")
	reference.visible = false
	renderer.visible = true
	var candidate_image := await _capture("res://production/playtest-evidence/batch-geometry-transform-candidate.png")
	var comparison := _compare(reference_image, candidate_image)
	var passed: bool = comparison.max_channel_delta <= 1 and comparison.pixels_channel_delta_gt1 == 0
	print("BATCHED_RENDERER_VISUAL_%s %s" % ["PASS" if passed else "FAIL", JSON.stringify(comparison)])
	reference.queue_free()
	renderer.queue_free()
	await process_frame
	quit(0 if passed else 1)
