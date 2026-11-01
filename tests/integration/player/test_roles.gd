extends SceneTree
## Role regressions use a real floor, player, devices, targets and weapon rays.
const Player = preload("res://src/player/player_controller.gd")
const Roles = preload("res://src/roles/role_controller.gd")
const Device = preload("res://src/roles/electrical_device.gd")
const Station = preload("res://src/interaction/lab_interactable.gd")
const Prop = preload("res://src/combat/damageable_prop.gd")
const Weapon = preload("res://src/combat/weapon_controller.gd")
const Combat = preload("res://src/combat/player_combat.gd")
var checks := 0
var failures := 0
var world: Node3D
var player: Player
var roles: Node

func _initialize() -> void:
	call_deferred(&"run_tests")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + description)

func settle() -> void:
	await physics_frame
	await physics_frame

func box(point: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	body.position = point
	world.add_child(body)
	return body

func target(point: Vector3, friendly := false) -> Node3D:
	var body = Prop.new()
	body.position = point
	body.max_health = 500
	body.team = 0 if friendly else 1
	world.add_child(body)
	body.set_process(false)
	return body

func run_tests() -> void:
	world = Node3D.new()
	root.add_child(world)
	box(Vector3(0, -0.25, 0), Vector3(40, 0.5, 40))
	player = Player.new()
	player.tuning = load("res://assets/data/movement_default.tres")
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.4
	shape.radius = 0.4
	collision.shape = shape
	player.add_child(collision)
	player.position = Vector3(0, 0.7, 0)
	world.add_child(player)
	player.set_physics_process(false)
	roles = Roles.new()
	world.add_child(roles)
	await settle()
	player.velocity = Vector3.DOWN
	player.move_and_slide()
	check(player.is_on_floor(), "Fixture establishes actual floor contact")
	await test_hack()
	await test_fuse()
	await test_breaker()
	await test_shield()
	world.queue_free()
	await process_frame
	print("ROLES: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_hack() -> void:
	var terminal = Station.new()
	terminal.kind = "terminal"
	terminal.position = Vector3(0, 0.7, -3)
	world.add_child(terminal)
	var completions := [0]
	terminal.activated.connect(func(): completions[0] += 1)
	check(not roles.begin_hack(terminal, player, true), "Operator cannot start Kilit hack")
	roles.select_role(1)
	check(not roles.begin_hack(null, player, true), "Hack rejects absent target")
	check(not roles.begin_hack(terminal, player, false), "Hack rejects blocked LOS")
	terminal.position.z = -8
	check(not roles.begin_hack(terminal, player, true), "Hack rejects out-of-range target")
	terminal.position.z = -3
	player.position.y = 5
	player.velocity = Vector3.ZERO
	player.move_and_slide()
	check(not roles.begin_hack(terminal, player, true), "Hack rejects airborne player")
	player.position.y = 0.7
	await settle()
	player.velocity = Vector3.DOWN
	player.move_and_slide()
	check(roles.begin_hack(terminal, player, true), "Kilit starts reachable grounded hack")
	check(not roles.begin_hack(terminal, player, true), "An active channel cannot restart itself")
	roles.advance(1, player, terminal, true)
	check(roles.hack_progress > 0 and roles.hack_progress < 1 and not terminal.completed, "Partial channel never activates target early")
	roles.advance(0.1, player, terminal, false)
	check(not roles.is_hacking() and roles.hack_progress == 0 and completions[0] == 0, "LOS loss cancels without activation")
	check(roles.hack_cooldown_remaining == 0, "Cancellation does not consume success cooldown")
	roles.begin_hack(terminal, player, true)
	roles.advance(0.1, player, null, true)
	check(not roles.is_hacking(), "Changing aim cancels the old target")
	roles.begin_hack(terminal, player, true)
	terminal.position.z = -8
	roles.advance(0.1, player, terminal, true)
	check(not roles.is_hacking(), "Leaving hack reach cancels channel")
	terminal.position.z = -3
	roles.begin_hack(terminal, player, true)
	roles.select_role(2)
	check(not roles.is_hacking(), "Role switch cancels channel")
	roles.select_role(1)
	roles.begin_hack(terminal, player, true)
	roles.advance(roles.current_profile().hack_duration, player, terminal, true)
	check(terminal.completed and completions[0] == 1 and not roles.is_hacking(), "Complete channel activates target exactly once")
	check(roles.hack_cooldown_remaining > 0, "Successful hack consumes cooldown")
	terminal.reset_target()
	check(not roles.begin_hack(terminal, player, true), "Cooldown blocks a fresh target")
	roles.select_role(0)
	roles.select_role(1)
	check(not roles.begin_hack(terminal, player, true), "Role cycling cannot reset cooldown")
	roles.advance(roles.current_profile().hack_cooldown, player, null, true)
	check(roles.begin_hack(terminal, player, true), "Hack becomes available after cooldown")
	roles.reset_role()
	check(not roles.is_hacking() and roles.hack_cooldown_remaining == 0, "Reset cancels hack and clears cooldown")
	terminal.queue_free()
	await settle()

func test_fuse() -> void:
	roles.select_role(1)
	var panel = Device.new()
	panel.position = Vector3(0, 0.7, -3)
	world.add_child(panel)
	var outside = Device.new()
	outside.position = Vector3(4, 0.7, 0)
	world.add_child(outside)
	var enemy = target(Vector3(1, 0.7, -3))
	var friend = target(Vector3(-1, 0.7, -3), true)
	check(not panel.can_hack() and not panel.activate(), "Panel requires fuse rather than camera hack")
	check(not roles.cast_fuse(player, Vector3.ZERO, [panel], [enemy]), "Fuse rejects zero direction without cooldown")
	check(roles.cast_fuse(player, Vector3.FORWARD, [panel, outside], [enemy, friend]), "Kilit casts aimed fuse cone")
	check(panel.is_disabled() and not outside.is_disabled(), "Cone affects forward devices but not side devices")
	check(enemy.stun_remaining > 0 and friend.stun_remaining == 0 and enemy.health == 500, "Fuse stuns enemies without damage or friendly stun")
	check(not roles.cast_fuse(player, Vector3.FORWARD, [panel], []), "Fuse cooldown rejects repeated cast")
	panel.advance(2)
	panel.redirect_for(1)
	check(is_equal_approx(panel.redirected_remaining, 4), "Shorter redirect cannot reduce an active effect")
	panel.advance(4)
	check(not panel.is_disabled(), "Temporary panel redirection expires")
	panel.kind = "camera"
	check(panel.activate() and not panel.can_hack(), "Camera hack disables it persistently only once")
	panel.advance(20)
	check(panel.is_disabled(), "Hack disable outlasts temporary effect durations")
	panel.reset_target()
	check(not panel.is_disabled() and panel.can_hack(), "Reset restores camera admission")
	panel.redirect_for(3)
	panel.advance(INF)
	check(is_equal_approx(panel.redirected_remaining, 3), "Nonfinite elapsed time cannot expire a valid device effect")
	roles.reset_role()
	var blocked = target(Vector3(0, 0.7, -6))
	var wall := box(Vector3(0, 0.7, -4.5), Vector3(4, 2, 0.3))
	panel.position = Vector3(0, 0.7, -7)
	panel.reset_target()
	await settle()
	check(roles.cast_fuse(player, Vector3.FORWARD, [panel], [blocked]), "Fuse can cast toward obstructed cone")
	check(blocked.stun_remaining == 0 and not panel.is_disabled(), "World wall blocks fuse stun and electrical redirection")
	blocked.queue_free()
	wall.queue_free()
	roles.reset_role()
	for node in [panel, outside, enemy, friend]:
		node.queue_free()
	await settle()

func test_breaker() -> void:
	roles.select_role(2)
	var victim = target(Vector3(0, 0.75, -1.8))
	victim.pushable = true
	await settle()
	var start: Vector3 = player.position
	check(roles.strike(player, Vector3.FORWARD), "Kırıcı can strike a close physics target")
	check(victim.health == 400 and victim.stun_remaining > 0, "Strike deals configured damage and stun")
	check(victim.position.z < -1.8 and victim.position.z >= -2.61, "Surviving pushable target is moved by bounded push")
	check(player.position.is_equal_approx(start), "Strike never dashes the player")
	check(not roles.strike(player, Vector3.FORWARD) and victim.health == 400, "Strike cooldown prevents duplicate damage")
	victim.reset_target()
	roles.reset_role()
	var wall = box(Vector3(0, 1, -0.9), Vector3(2, 2, 0.2))
	await settle()
	roles.strike(player, Vector3.FORWARD)
	check(victim.health == 500, "First-hit wall blocks strike damage")
	wall.queue_free()
	await settle()
	roles.reset_role()
	var stop = box(Vector3(0, 1, -2.3), Vector3(2, 2, 0.2))
	roles.strike(player, Vector3.FORWARD)
	check(victim.position.z >= -2.06, "Push cannot clip a target through a blocking wall")
	stop.queue_free()
	victim.queue_free()
	await settle()
	roles.reset_role()
	var fragile = target(Vector3(0, 0.75, -1.8))
	fragile.breakable = true
	fragile.max_health = 80
	fragile.reset_target()
	await settle()
	roles.strike(player, Vector3.FORWARD)
	await settle()
	check(not fragile.visible and fragile.health == 0, "Strike breaks fragile cover")
	fragile.reset_target()
	await settle()
	check(fragile.visible and fragile.health == 80, "Reset restores broken cover and collision")
	var sounds: Array = []
	roles.noise_emitted.connect(func(_point, radius): sounds.append(radius))
	roles.reset_role()
	player.velocity = Vector3.RIGHT
	player.is_slow_walking = false
	roles.advance(0.1, player, null, true)
	check(sounds.size() == 1, "Grounded Kırıcı movement emits footsteps")
	roles.advance(0.1, player, null, true)
	check(sounds.size() == 1, "Footstep noise is interval limited")
	player.is_slow_walking = true
	roles.advance(0.5, player, null, true)
	check(sounds.size() == 2 and sounds[1] < sounds[0], "Slow walk reduces Kırıcı footstep noise")
	player.velocity = Vector3.ZERO
	fragile.queue_free()
	await settle()

func test_shield() -> void:
	roles.reset_role()
	var obstruction = box(Vector3(0, 1, -1.7), Vector3(3, 2, 0.4))
	await settle()
	check(not roles.deploy_shield(player, Vector3.FORWARD) and roles.shield_cooldown_remaining == 0, "Obstructed shield placement fails without consuming cooldown")
	obstruction.queue_free()
	await settle()
	check(roles.deploy_shield(player, Vector3.FORWARD), "Grounded Kırıcı places shield in clear space")
	var shield = roles.active_shield
	if not is_instance_valid(shield):
		printerr("Shield admission: floor=%s y=%.6f reason=%s" % [player.is_on_floor(), player.position.y, roles.message])
		return
	check(not roles.deploy_shield(player, Vector3.FORWARD), "Shield cooldown prevents duplicate placement")
	check(not shield.blocks_shot(0) and shield.blocks_shot(1), "Shield discriminates allied and hostile shots")
	check(not shield.receive_hit(50, 0) and shield.health == 200, "Allied hits cannot damage shield")
	check(shield.receive_hit(50, 1) and shield.health == 150, "Hostile hit damages shield")
	var remaining: float = shield.remaining
	await settle()
	check(shield.remaining == remaining, "Shield lifetime has no autonomous unpausable timer")
	var victim = target(Vector3(0, 1, -3.5))
	var weapon = Weapon.new()
	weapon.state = Combat.new()
	weapon.state.reset()
	weapon.excluded.append(player.get_rid())
	world.add_child(weapon)
	await settle()
	check(weapon.fire_at(Vector3(0, 1, 0), Vector3.FORWARD, false) and victim.health < 500, "Real allied weapon ray passes shield and damages target behind it")
	var query := PhysicsRayQueryParameters3D.create(Vector3(0, 1, 0), Vector3(0, 1, -5))
	query.exclude = [player.get_rid()]
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider == shield, "Hostile first-hit physics query encounters shield before target")
	roles.advance(remaining, player, null, true)
	check(not shield.visible and shield.collision_layer == 0, "Lifetime expiry immediately removes shield collision")
	await settle()
	roles.reset_role()
	check(roles.deploy_shield(player, Vector3.FORWARD), "Reset makes shield available again")
	shield = roles.active_shield
	shield.receive_hit(200, 1)
	check(not shield.visible and not shield.blocks_shot(1), "Lethal hit immediately disables shield")
	await settle()
	roles.reset_role()
	roles.deploy_shield(player, Vector3.FORWARD)
	shield = roles.active_shield
	roles.select_role(0)
	check(roles.active_shield == null and not shield.visible, "Role switch removes active shield")
	check(roles.shield_cooldown_remaining > 0, "Role switch retains shield cooldown")
	weapon.queue_free()
	victim.queue_free()
	await settle()
