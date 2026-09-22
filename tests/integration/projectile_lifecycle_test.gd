extends SceneTree

const Geometry = preload("res://src/gameplay/battle/combat_geometry.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	_run.call_deferred()

func seed_projectile(stage, origin: Vector2, velocity: Vector2) -> void:
	stage._projectile_count = 1
	stage._projectile_positions[0] = origin
	stage._projectile_velocities[0] = velocity
	stage._projectile_damage[0] = 1.0

func _run() -> void:
	check(is_equal_approx(Geometry.retention_fraction(Vector2.ZERO, Vector2(200, 0), Vector2.ZERO, 10000), 0.5), "clip at exit")
	check(Geometry.retention_fraction(Vector2(101, 0), Vector2.ZERO, Vector2.ZERO, 10000) < 0, "outside origin cannot reenter")
	check(Geometry.retention_fraction(Vector2(100, 0), Vector2(200, 0), Vector2.ZERO, 10000) == 0, "outward boundary has zero segment")
	check(Geometry.retention_fraction(Vector2.ZERO, Vector2(100, 0), Vector2.ZERO, 10000) == 1, "closed endpoint retained")
	var game = load("res://src/core/GameRoot.tscn").instantiate()
	game.transient_profile = true
	root.add_child(game)
	await game.boot_completed
	game.set_physics_process(false)
	check(await game.request_start_battle(101, false) == 0, "start")
	var battle = game.current_battle
	var stage = battle.stage
	stage._projectile_despawn_radius_squared = 10000.0
	check(stage._spawn_enemy(stage.ENEMY_BEETLE, Vector2(90, 0)), "spawn target")
	stage._enemy_hp[0] = 100.0
	var initial_hp: float = stage._enemy_hp[0]
	seed_projectile(stage, Vector2.ZERO, Vector2(200, 0))
	check(stage._update_projectiles(1.0, battle.player), "final segment update")
	check(stage._enemy_hp[0] == initial_hp - 1.0 and stage._projectile_count == 0, "hit before exit then remove exactly once")
	stage._enemy_positions[0] = Vector2(200, 0)
	seed_projectile(stage, Vector2.ZERO, Vector2(300, 0))
	check(stage._update_projectiles(1.0, battle.player), "beyond boundary update")
	check(stage._enemy_hp[0] == initial_hp - 1.0 and stage._projectile_count == 0, "no hit beyond retained segment")
	# A target tangent to the retained endpoint still counts.
	stage._enemy_positions[0] = Vector2(100 + stage._projectile_radius + float(stage._beetle["radius"]), 0)
	seed_projectile(stage, Vector2.ZERO, Vector2(200, 0))
	check(stage._update_projectiles(1.0, battle.player), "tangent update")
	check(stage._enemy_hp[0] == initial_hp - 2.0, "closed boundary tangency hits")
	seed_projectile(stage, Vector2.ZERO, Vector2(20, 0))
	stage._hostile_count = 1
	stage._ring_pending = true
	stage._summon_pending = true
	check(stage.teardown(), "teardown releases ownership")
	check(stage._projectile_count == 0 and stage._hostile_count == 0 and not stage._ring_pending and not stage._summon_pending, "teardown clears all projectile channels")
	check(not stage.run_phase(&"STAGE_SIMULATE", 1.0 / 60.0, 1.0, battle.player), "closed stage rejects simulation")
	check(stage.teardown(), "teardown is idempotent")
	game.queue_free()
	await process_frame
	print("PROJECTILE_LIFECYCLE_%s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
