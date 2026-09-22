extends SceneTree
const Geometry = preload("res://src/gameplay/battle/combat_geometry.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	check(await game.request_start_battle(101, false) == 0, "start")
	var stage = game.current_battle.stage
	var player = game.current_battle.player
	var rng := RandomNumberGenerator.new()
	rng.seed = 7089
	for index in 80:
		check(stage._spawn_enemy(stage.ENEMY_BEETLE, Vector2.ZERO), "spawn pending target")
	for trial in 160:
		for index in stage._enemy_count:
			stage._enemy_positions[index] = Vector2(rng.randf_range(-700, 700), rng.randf_range(-700, 700))
			stage._enemy_hp[index] = 100.0
		var origin := Vector2(rng.randf_range(-300, 300), rng.randf_range(-300, 300))
		var target := Vector2(rng.randf_range(-1600, 1600), rng.randf_range(-1600, 1600))
		if trial == 0:
			# Same position, different stable handles: lowest handle wins.
			origin = Vector2.ZERO
			target = Vector2.ZERO
			stage._enemy_positions[0] = Vector2.ZERO
			stage._enemy_positions[1] = Vector2.ZERO
		var retained := Geometry.retention_fraction(origin, target, player.position, stage._projectile_despawn_radius_squared)
		var end := origin.lerp(target, retained)
		var expected := -1
		var first := INF
		for index in stage._enemy_count:
			var radius: float = stage._projectile_radius + float(stage._enemy_data(stage._enemy_kind[index])["radius"])
			var fraction := Geometry.sweep_fraction(origin, end, stage._enemy_positions[index], radius)
			if fraction >= 0 and (fraction < first or (fraction == first and (expected < 0 or stage._enemy_grid_handles[index] < stage._enemy_grid_handles[expected]))):
				expected = index
				first = fraction
		stage._projectile_count = 1
		stage._projectile_positions[0] = origin
		stage._projectile_velocities[0] = target - origin
		stage._projectile_damage[0] = 1.0
		check(stage._update_projectiles(1.0, player), "spatial update")
		for index in stage._enemy_count:
			check(stage._enemy_hp[index] == (99.0 if index == expected else 100.0), "brute-force oracle trial=%d enemy=%d" % [trial, index])
	game.queue_free()
	await process_frame
	print("PROJECTILE_SPATIAL_EQUIVALENCE_%s trials=160 targets=80" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
