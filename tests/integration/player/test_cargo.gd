extends SceneTree
## Real cargo/lab regression: ownership, physics, utilities and reset boundaries.

const LabScene = preload("res://src/lab/mechanics_lab.tscn")
const Item = preload("res://src/roles/cargo_item.gd")
var checks := 0
var failures := 0
var lab: Node3D

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

func run_tests() -> void:
	lab = LabScene.instantiate()
	root.add_child(lab)
	lab.set_process(false)
	lab._player.set_physics_process(false)
	lab._camera.set_process(false)
	lab.roles.select_role(3)
	var cargo = lab.cargo
	var player = lab._player
	player.reset_to(Vector3(0, 0.75, 5))
	await settle()
	cargo.advance(0.01, player, Vector3(0, 0.75, 0))
	check(cargo.carried.is_empty(), "World cargo ticks without inventing ownership")
	var parcel = cargo.items[0]
	var core = cargo.items[1]
	check(cargo.pickup(parcel), "Yük can pick up a physical parcel")
	check(not cargo.pickup(parcel) and cargo.carried.size() == 1, "Duplicate pickup cannot duplicate cargo")
	check(parcel.freeze and parcel.collision_layer == 0 and not parcel.visible, "Held parcel stops physics and collision")
	check(cargo.pickup(core) and cargo.carrying_core(), "Core ownership is tracked")
	for index in range(7):
		var item = Item.new()
		item.position = Vector3(4 + index, 0.4, 12)
		cargo.add_child(item)
		cargo.items.append(item)
		check(cargo.pickup(item) == (index < 6), "Capacity admits exactly eight items (%d)" % index)
	check(cargo.carried.size() == 8 and cargo.carried.back() == core, "Core remains the first item released from a full bag")
	check(cargo.begin_aim(), "Q starts aim with carried cargo")
	cargo.cancel_aim()
	check(not cargo.aiming and cargo.carried.size() == 8, "Cancelling aim preserves ownership")
	cargo.reset_cargo()
	check(cargo.carried.is_empty() and not cargo.carrying_core(), "Reset clears every carried slot")
	check(core.visible and not core.freeze and core.collision_layer == 1, "Reset restores world core physics")

	# Ballistic aim must meet the cursor-plane height, not the release height.
	var origin := Vector3(0, 1.35, 5)
	var desired := Vector3(0, 0.75, 1)
	var speed: Vector3 = cargo.launch_velocity(origin, desired)
	var time: float = cargo.profile.throw_flight_time
	var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	var end := origin + speed * time + Vector3.DOWN * gravity * time * time * 0.5
	check(end.distance_to(desired) < 0.001, "Ballistic release reaches the actual cursor plane at flight time")
	var limited: Vector3 = cargo.launch_velocity(origin, Vector3(0, 0.75, -100))
	check(Vector2(limited.x, limited.z).length() * time <= cargo.profile.throw_reach + 0.001, "Throw range is clamped")
	cargo.pickup(core)
	cargo.begin_aim()
	check(cargo.throw_item(player, desired), "Throw releases real rigid body")
	check(not core.carried and not cargo.carrying_core() and not cargo.aiming, "Throw removes core restrictions and aim")
	check(core.linear_velocity.length() > 0 and core.get_collision_exceptions().has(player), "Launch has velocity and temporary thrower exclusion")
	check(not cargo.begin_aim(), "Throw cooldown blocks another launch")
	core.global_position = Vector3(4, 1, 5)
	cargo.advance(0.01, player, desired)
	check(not core.get_collision_exceptions().has(player), "Thrower collision is restored after separation")
	core.global_position = Vector3(0, 0.7, 12)
	cargo.advance(0.01, player, desired)
	check(cargo.catches == 1 and core.carried and cargo.carried.is_empty(), "Receiver catches without adding to player bag")
	cargo.advance(0.01, player, desired)
	check(cargo.catches == 1, "A receiver cannot count the same item twice")

	cargo.reset_cargo()
	parcel.linear_velocity = Vector3(2, 3, 4)
	cargo.set_paused(true)
	cargo.set_paused(true)
	cargo.set_paused(false)
	check(parcel.linear_velocity.is_equal_approx(Vector3(2, 3, 4)), "Repeated pause preserves the original flight velocity")
	cargo.set_paused(true)
	cargo.reset_cargo()
	cargo.set_paused(false)
	check(parcel.linear_velocity.is_zero_approx(), "Reset does not resurrect pre-reset flight velocity")
	cargo.pickup(parcel)
	cargo.advance(0.01, player, desired)
	lab.roles.select_role(0)
	check(cargo.carried.is_empty() and not parcel.carried, "Leaving Yük releases owned cargo")
	check(parcel.global_position.distance_to(player.global_position) < 1.5, "Role switch releases cargo near its carrier, not the pickup location")
	check(not cargo.pickup(core) and not cargo.begin_aim() and not cargo.use_utility(player, desired), "Other roles cannot use Yük commands")

	lab.roles.select_role(3)
	cargo.reset_cargo()
	await settle()
	check(cargo.use_utility(player, Vector3(0, 0.75, 2)), "Smoke can be deployed in clear space")
	check(cargo.blocks_sight(Vector3(-3, 0.75, 2), Vector3(3, 0.75, 2)), "Smoke blocks a segment crossing its real volume")
	check(not cargo.blocks_sight(Vector3(-3, 0.75, 9), Vector3(3, 0.75, 9)), "Smoke does not block distant segments")
	check(not cargo.use_utility(player, desired), "Utility cooldown rejects repeated activation")
	cargo.advance(cargo.profile.utility_duration + 0.01, player, desired)
	check(not cargo.blocks_sight(Vector3(-3, 0.75, 2), Vector3(3, 0.75, 2)), "Expired smoke no longer blocks vision")
	cargo.reset_cargo()
	cargo.toggle_utility()
	var noises: Array = []
	cargo.noise_emitted.connect(func(point, radius): noises.append([point, radius]))
	check(cargo.use_utility(player, Vector3(0, 0.75, 3)), "Bait can be placed")
	cargo.advance(0.1, player, desired)
	check(noises.size() == 1 and noises[0][1] == cargo.profile.bait_noise_radius, "Bait emits its configured world noise")
	cargo.advance(0.2, player, desired)
	check(noises.size() == 1, "Bait does not emit every frame")
	cargo.advance(1.0, player, desired)
	check(noises.size() == 2, "Bait emits another spaced pulse")
	cargo.reset_cargo()
	var prior := noises.size()
	cargo.advance(10, player, desired)
	check(noises.size() == prior and cargo.catches == 0, "Reset removes bait pulses and catch counts")

	# Reproduce reset while paused and the data-driven core movement contract.
	cargo.pickup(core)
	cargo.begin_aim()
	lab.set_paused(true)
	check(not cargo.aiming and not lab.try_fire(), "Pause cancels aiming and blocks fire")
	lab._reset_lab()
	check(core.freeze and cargo.carried.is_empty(), "F5 while paused keeps world cargo frozen")
	lab.set_paused(false)
	lab._player.set_physics_process(false)
	lab._camera.set_process(false)
	var original: Resource = cargo.profile
	var original_factor: float = original.core_speed_multiplier
	original.core_speed_multiplier = 0.5
	cargo.pickup(core)
	lab._update_role_abilities(0.01, false)
	check(is_equal_approx(player.cargo_speed_multiplier, 0.5), "Core speed consumes the injected role tuning")
	check(not lab.try_fire(), "Core blocks firing without consuming ammunition")
	original.core_speed_multiplier = original_factor
	lab._reset_lab()
	check(player.cargo_speed_multiplier == 1.0, "Reset restores unladen movement")
	lab.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("CARGO: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
