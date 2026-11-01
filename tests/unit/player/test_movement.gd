extends SceneTree
## Standalone deterministic movement tests; no scene, input polling, or addons.

const TuningScript = preload("res://src/data/movement_tuning.gd")
const PlayerScript = preload("res://src/player/player_controller.gd")
const CameraScript = preload("res://src/camera/player_camera.gd")
const EPSILON: float = 0.0001

var _assertion_count: int = 0
var _failure_count: int = 0


func _initialize() -> void:
	_test_diagonal_input_has_unit_length()
	_test_camera_relative_input_uses_ground_basis()
	_test_acceleration_and_deceleration_are_bounded()
	_test_slow_walk_uses_tuning_multiplier()
	_test_role_cargo_motion()
	_test_zero_delta_does_not_change_state()
	_test_reset_clears_motion_and_restores_facing()
	_test_focus_loss_cancels_horizontal_motion()
	_test_ray_aim_uses_player_height_and_handles_parallel_rays()
	_test_pan_center_and_inner_region_are_neutral()
	_test_pan_edges_and_corners_are_bounded()
	_test_pan_invalid_viewport_is_neutral()
	_test_exponential_follow_is_frame_rate_independent()
	_test_jump_and_turn_defaults_match_approved_tuning()
	var contract_probe: PlayerScript = _make_player()
	_expect(contract_probe.has_signal(&"jumped"), "Lab can connect its required jumped signal")
	_expect(contract_probe.has_signal(&"landed"), "Lab can connect its required landed signal")
	_expect(contract_probe.has_method(&"simulate_vertical_motion"),
		"Controller exposes pure vertical simulation")
	_expect(contract_probe.has_method(&"smooth_yaw"), "Controller exposes pure yaw smoothing")
	if contract_probe.has_method(&"simulate_vertical_motion"):
		_test_grounded_jump_uses_height_formula_and_preserves_horizontal_velocity()
		_test_airborne_jump_is_rejected_and_gravity_applies()
		_test_held_jump_does_not_auto_hop_or_buffer()
		_test_air_movement_preserves_vertical_velocity()
		_test_disabled_jump_values_and_nonpositive_delta_are_safe()
		_test_reset_clears_vertical_state_and_sets_anchor()
	if contract_probe.has_method(&"smooth_yaw"):
		_test_turn_response_is_sixty_percent_and_frame_rate_independent()
	contract_probe.free()
	print("Movement tests: %d assertions executed; %d failures." % [
		_assertion_count, _failure_count
	])
	quit(1 if _failure_count > 0 or _assertion_count == 0 else 0)


func _make_tuning() -> TuningScript:
	return TuningScript.new()


func _make_player() -> PlayerScript:
	var player: PlayerScript = PlayerScript.new()
	player.tuning = _make_tuning()
	return player


func _make_camera() -> CameraScript:
	var camera: CameraScript = CameraScript.new()
	camera.tuning = _make_tuning()
	return camera


func _expect(condition: bool, description: String) -> void:
	_assertion_count += 1
	if not condition:
		_failure_count += 1
		printerr("FAIL: " + description)


func _expect_float(actual: float, expected: float, description: String) -> void:
	_expect(absf(actual - expected) <= EPSILON, "%s (got %f; expected %f)" % [
		description, actual, expected
	])


func _expect_vector(actual: Vector3, expected: Vector3, description: String) -> void:
	_expect(actual.distance_to(expected) <= EPSILON, description)


func _test_diagonal_input_has_unit_length() -> void:
	var direction: Vector3 = PlayerScript.horizontal_input_direction(Vector2(1.0, -1.0))
	_expect_float(direction.length(), 1.0, "Diagonal movement is normalized")
	_expect(direction.x > 0.0 and direction.z < 0.0, "Forward-right has correct signs")
	_expect_vector(PlayerScript.horizontal_input_direction(Vector2.ZERO), Vector3.ZERO,
		"Zero input is safe")
	_expect_float(PlayerScript.horizontal_input_direction(Vector2(0.25, 0.0)).length(),
		0.25, "Analog input magnitude is retained")


func _test_camera_relative_input_uses_ground_basis() -> void:
	var camera_basis: Basis = Basis(Vector3.UP, PI / 2.0)
	_expect_vector(PlayerScript.horizontal_input_direction(Vector2(0.0, -1.0),
		camera_basis), Vector3.LEFT, "Camera yaw rotates forward movement")
	var vertical_basis: Basis = Basis(Vector3.RIGHT, -PI / 2.0)
	var direction: Vector3 = PlayerScript.horizontal_input_direction(Vector2.UP,
		vertical_basis)
	_expect_float(direction.length(), 1.0, "Vertical camera has a nonzero fallback")
	_expect_float(direction.y, 0.0, "Camera pitch never adds vertical movement")
	var player: PlayerScript = _make_player()
	var camera: CameraScript = _make_camera()
	camera.rotation.y = PI / 2.0
	player.camera = camera
	player.simulate_motion(Vector2.UP, false,
		player.tuning.move_speed / player.tuning.acceleration)
	_expect_vector(player.velocity, Vector3.LEFT * player.tuning.move_speed,
		"Injected camera is used by simulation outside the scene tree")
	player.free()
	camera.free()


func _test_acceleration_and_deceleration_are_bounded() -> void:
	var player: PlayerScript = _make_player()
	var step: float = player.tuning.move_speed / player.tuning.acceleration / 2.0
	player.simulate_motion(Vector2.RIGHT, false, step)
	_expect_float(player.velocity.x, player.tuning.move_speed / 2.0,
		"Velocity ramps up using acceleration")
	player.simulate_motion(Vector2.RIGHT, false, step * 4.0)
	_expect_float(player.velocity.x, player.tuning.move_speed, "Speed never overshoots")
	step = player.tuning.move_speed / player.tuning.deceleration / 2.0
	player.simulate_motion(Vector2.ZERO, false, step)
	_expect_float(player.velocity.x, player.tuning.move_speed / 2.0,
		"Released input decelerates")
	player.simulate_motion(Vector2.ZERO, false, step * 4.0)
	_expect_vector(player.velocity, Vector3.ZERO, "Deceleration reaches rest without reversal")
	player.free()


func _test_slow_walk_uses_tuning_multiplier() -> void:
	var player: PlayerScript = _make_player()
	player.simulate_motion(Vector2.RIGHT, true,
		player.tuning.move_speed / player.tuning.acceleration)
	_expect_float(player.velocity.length(),
		player.tuning.move_speed * player.tuning.walk_multiplier,
		"Slow walking obeys external tuning")
	_expect(player.is_slow_walking, "Slow-walk state is exposed")
	player.simulate_motion(Vector2.ZERO, true, 1.0)
	_expect(not player.is_slow_walking, "Idle is not reported as slow walking")
	player.free()


func _test_role_cargo_motion() -> void:
	var player: PlayerScript = _make_player()
	_expect(not InputMap.has_action(&"dash"), "General dash is not bound")
	player.cargo_speed_multiplier = 0.5
	player.simulate_motion(Vector2.RIGHT, false, 1.0)
	_expect_float(player.velocity.x, player.tuning.move_speed * 0.5, "Cargo reduces movement speed")
	player.role_walk_multiplier = 0.7
	player.simulate_motion(Vector2.RIGHT, true, 1.0)
	_expect_float(player.velocity.x, player.tuning.move_speed * 0.5 * 0.7, "Role and cargo multipliers compose")
	player.free()


func _test_zero_delta_does_not_change_state() -> void:
	var player: PlayerScript = _make_player()
	player.simulate_motion(Vector2.RIGHT, false, 0.0)
	_expect_vector(player.velocity, Vector3.ZERO, "Zero delta does not change velocity")
	player.simulate_motion(Vector2.RIGHT, false, -1.0)
	_expect_vector(player.velocity, Vector3.ZERO, "Negative delta is ignored")
	player.free()


func _test_reset_clears_motion_and_restores_facing() -> void:
	var player: PlayerScript = _make_player()
	player.simulate_motion(Vector2.RIGHT, true, 1.0 / 60.0)
	player.velocity.y = -player.tuning.gravity
	player.rotation.y = PI / 2.0
	var spawn: Vector3 = Vector3(3.0, 0.75, -2.0)
	player.reset_to(spawn)
	_expect_vector(player.position, spawn, "Reset places player at the requested point")
	_expect_vector(player.velocity, Vector3.ZERO, "Reset clears all velocity")
	_expect_float(player.rotation.y, 0.0, "Reset snaps facing to world forward")
	_expect(not player.is_slow_walking, "Reset clears slow-walk state")
	player.free()


func _test_focus_loss_cancels_horizontal_motion() -> void:
	var player: PlayerScript = _make_player()
	player.simulate_motion(Vector2.RIGHT, false, 1.0 / 60.0)
	player.velocity.y = -player.tuning.gravity
	player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect_float(player.velocity.x, 0.0, "Focus loss stops horizontal motion immediately")
	_expect_float(player.velocity.y, -player.tuning.gravity,
		"Focus loss does not cancel gravity")
	player.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	player.simulate_motion(Vector2.RIGHT, false, 1.0 / 60.0)
	_expect(player.velocity.x > 0.0, "Fresh movement works after focus regain")
	player.free()


func _test_ray_aim_uses_player_height_and_handles_parallel_rays() -> void:
	var player_point: Vector3 = Vector3(0.0, 0.75, 0.0)
	var ray_origin: Vector3 = Vector3(0.0, 10.75, 0.0)
	var ray_direction: Vector3 = Vector3(1.0, -1.0, 0.0).normalized()
	_expect_vector(PlayerScript.ray_plane_aim_direction(ray_origin, ray_direction,
		player_point), Vector3.RIGHT, "Aim ray intersects player-height horizontal plane")
	_expect_vector(PlayerScript.ray_plane_aim_direction(ray_origin, Vector3.RIGHT,
		player_point), Vector3.ZERO, "Parallel ray is safely rejected")
	_expect_vector(PlayerScript.ray_plane_aim_direction(ray_origin, Vector3.UP,
		player_point), Vector3.ZERO, "Behind-camera intersection is safely rejected")
	_expect_vector(PlayerScript.ray_plane_aim_direction(ray_origin, Vector3.DOWN,
		player_point), Vector3.ZERO, "Aim directly on player is safely rejected")


func _test_pan_center_and_inner_region_are_neutral() -> void:
	var camera: CameraScript = _make_camera()
	var size: Vector2 = Vector2(1000.0, 800.0)
	_expect(camera.screen_edge_offset(size / 2.0, size).is_zero_approx(),
		"Screen center has no edge pan")
	_expect(camera.screen_edge_offset(size * Vector2(0.7, 0.3), size).is_zero_approx(),
		"Inner screen remains neutral")
	_expect(camera.screen_edge_offset(size * Vector2(camera.tuning.camera_edge_threshold,
		0.5), size).is_zero_approx(), "Edge threshold itself remains neutral")
	camera.free()


func _test_pan_edges_and_corners_are_bounded() -> void:
	var camera: CameraScript = _make_camera()
	var size: Vector2 = Vector2(1000.0, 800.0)
	var limit: float = camera.tuning.camera_edge_pan
	_expect_float(camera.screen_edge_offset(Vector2(size.x, size.y / 2.0), size).x,
		limit, "Right edge reaches configured pan distance")
	_expect_float(camera.screen_edge_offset(Vector2(0.0, size.y / 2.0), size).x,
		-limit, "Left edge reaches negative configured distance")
	_expect_float(camera.screen_edge_offset(Vector2(size.x / 2.0, 0.0), size).y,
		-limit, "Top edge pans toward camera-ground forward")
	_expect_float(camera.screen_edge_offset(size, size).length(), limit,
		"Corner pan is length-clamped, not faster diagonally")
	_expect(camera.screen_edge_offset(size * 10.0, size).length() <= limit + EPSILON,
		"Offscreen pointer never exceeds maximum pan")
	camera.tuning.camera_edge_pan_enabled = false
	_expect(camera.screen_edge_offset(size, size).is_zero_approx(),
		"Edge pan can be disabled in tuning")
	camera.free()


func _test_pan_invalid_viewport_is_neutral() -> void:
	var camera: CameraScript = _make_camera()
	_expect(camera.screen_edge_offset(Vector2.ONE, Vector2.ZERO).is_zero_approx(),
		"Zero viewport does not divide by zero")
	_expect(camera.screen_edge_offset(Vector2.ONE, Vector2(-1.0, 1.0)).is_zero_approx(),
		"Negative viewport is rejected")
	camera.free()


func _test_exponential_follow_is_frame_rate_independent() -> void:
	var tuning: TuningScript = _make_tuning()
	var desired: Vector3 = Vector3(4.0, tuning.camera_height, tuning.camera_depth)
	var low_rate: Vector3 = Vector3.ZERO
	var high_rate: Vector3 = Vector3.ZERO
	for frame: int in range(30):
		low_rate = CameraScript.smooth_follow(low_rate, desired,
			tuning.camera_follow_sharpness, 1.0 / 30.0)
	for frame: int in range(120):
		high_rate = CameraScript.smooth_follow(high_rate, desired,
			tuning.camera_follow_sharpness, 1.0 / 120.0)
	_expect_vector(low_rate, high_rate, "Exponential camera follow agrees at 30 and 120 Hz")
	_expect_vector(CameraScript.smooth_follow(Vector3.ZERO, desired,
		tuning.camera_follow_sharpness, 0.0), Vector3.ZERO,
		"Zero delta leaves camera unchanged")
	_expect_vector(CameraScript.smooth_follow(Vector3.ZERO, desired,
		tuning.camera_follow_sharpness, -1.0), Vector3.ZERO,
		"Negative delta leaves camera unchanged")
	_expect(low_rate.distance_to(desired) < Vector3.ZERO.distance_to(desired),
		"Camera converges toward target without overshooting")


func _test_jump_and_turn_defaults_match_approved_tuning() -> void:
	# Arrange
	var tuning: TuningScript = _make_tuning()
	# Act / Assert — exact approved configuration is the boundary fixture.
	_expect_float(tuning.turn_sharpness, 13.2, "Character turn response is 40 percent slower")
	_expect_float(tuning.gravity, 24.0, "Jump leaves gravity unchanged")
	_expect(tuning.get(&"jump_height") == 1.0, "Default jump height is one meter")
	_expect(tuning.get(&"jump_takeoff_duration") == 0.10, "Takeoff animation duration is exposed")
	_expect(tuning.get(&"jump_landing_duration") == 0.16, "Landing animation duration is exposed")
	_expect(tuning.get(&"jump_stretch") == 0.16, "Takeoff stretch is exposed")
	_expect(tuning.get(&"jump_squash") == 0.18, "Landing squash is exposed")
	_expect(tuning.get(&"jump_pose_sharpness") == 16.0, "Pose response is exposed")
	_expect(tuning.get(&"jump_animation_strength") == 1.0, "Animation strength is exposed")


# Dynamic invocation lets this regression suite run to an assertion-based RED
# against the original controller, before the new methods or properties exist.
func _vertical(player: PlayerScript, wants_jump: bool, grounded: bool, delta: float) -> bool:
	return bool(player.call(&"simulate_vertical_motion", wants_jump, grounded, delta))


func _test_grounded_jump_uses_height_formula_and_preserves_horizontal_velocity() -> void:
	# Arrange
	var player: PlayerScript = _make_player()
	player.velocity = Vector3(player.tuning.move_speed, 0.0, -player.tuning.move_speed)
	var horizontal: Vector2 = Vector2(player.velocity.x, player.velocity.z)
	var step: float = 1.0 / 60.0
	# Act
	var accepted: bool = _vertical(player, true, true, step)
	# Assert
	var launch_speed: float = sqrt(2.0 * player.tuning.gravity * float(player.tuning.get(&"jump_height")))
	_expect(accepted, "Grounded rising edge accepts jump")
	_expect_float(player.velocity.y, launch_speed, "Jump uses sqrt(2*g*h) without takeoff gravity loss")
	_expect_float(player.velocity.y * player.velocity.y / (2.0 * player.tuning.gravity),
		1.0, "Ballistic launch energy targets one meter")
	_expect(Vector2(player.velocity.x, player.velocity.z) == horizontal,
		"Vertical simulation preserves horizontal velocity")
	player.free()


func _test_airborne_jump_is_rejected_and_gravity_applies() -> void:
	# Arrange
	var player: PlayerScript = _make_player()
	var step: float = 1.0 / 60.0
	_vertical(player, true, true, step)
	_vertical(player, false, false, step)
	var previous_y: float = player.velocity.y
	# Act
	var accepted: bool = _vertical(player, true, false, step)
	# Assert
	_expect(not accepted, "Airborne fresh press cannot double jump")
	_expect_float(player.velocity.y, previous_y - player.tuning.gravity * step,
		"Gravity continues while airborne jump is rejected")
	player.velocity.y = -player.tuning.gravity
	_vertical(player, false, true, step)
	_expect_float(player.velocity.y, -player.tuning.gravity * step,
		"Grounded contact retains a small downward step instead of alternating airborne")
	player.free()


func _test_held_jump_does_not_auto_hop_or_buffer() -> void:
	# Arrange
	var player: PlayerScript = _make_player()
	var step: float = 1.0 / 60.0
	_vertical(player, true, true, step)
	# Act / Assert
	_expect(not _vertical(player, true, false, step), "Held jump cannot jump in air")
	player.velocity.y = 0.0
	_expect(not _vertical(player, true, true, step), "Held jump cannot auto-hop on landing")
	_vertical(player, false, true, step)
	_expect(_vertical(player, true, true, step), "Release and fresh grounded press can jump")
	_vertical(player, false, false, step)
	_expect(not _vertical(player, true, false, step), "Fresh airborne press is rejected")
	player.velocity.y = 0.0
	_expect(not _vertical(player, true, true, step), "Airborne press is not buffered into landing")
	player.free()


func _test_air_movement_preserves_vertical_velocity() -> void:
	# Arrange
	var player: PlayerScript = _make_player()
	var step: float = 1.0 / 60.0
	_vertical(player, true, true, step)
	var previous_y: float = player.velocity.y
	# Act
	player.simulate_motion(Vector2.RIGHT, false, step)
	# Assert
	_expect(player.velocity.x > 0.0, "WASD retains air control")
	_expect_float(player.velocity.y, previous_y, "Air steering preserves vertical velocity")
	_expect(not _vertical(player, false, false, step), "Air steering does not trigger another jump")
	_expect_float(player.velocity.y, previous_y - player.tuning.gravity * step,
		"Air steering never suspends gravity")
	player.free()


func _test_disabled_jump_values_and_nonpositive_delta_are_safe() -> void:
	# Arrange
	var player: PlayerScript = _make_player()
	var step: float = 1.0 / 60.0
	var original_velocity: Vector3 = Vector3.ONE
	player.velocity = original_velocity
	# Act / Assert
	_expect(not _vertical(player, true, true, 0.0), "Zero delta rejects jump")
	_expect(not _vertical(player, true, true, -step), "Negative delta rejects jump")
	_expect_vector(player.velocity, original_velocity, "Nonpositive delta leaves all velocity unchanged")
	_expect(_vertical(player, true, true, step), "Ignored steps do not consume rising edge")
	for disabled: float in [0.0, -1.0]:
		_vertical(player, false, true, step)
		player.tuning.set(&"jump_height", disabled)
		_expect(not _vertical(player, true, true, step), "Nonpositive height disables jump")
	player.tuning.set(&"jump_height", 1.0)
	for disabled: float in [0.0, -1.0]:
		_vertical(player, false, true, step)
		player.tuning.gravity = disabled
		_expect(not _vertical(player, true, true, step), "Nonpositive gravity disables jump safely")
	player.tuning = null
	_expect(not _vertical(player, true, true, step), "Missing tuning safely rejects jump")
	player.free()


func _test_reset_clears_vertical_state_and_sets_anchor() -> void:
	# Arrange
	var player: PlayerScript = _make_player()
	var step: float = 1.0 / 60.0
	_vertical(player, true, true, step)
	var spawn: Vector3 = Vector3(3.0, 5.0, -2.0)
	# Act
	player.reset_to(spawn)
	# Assert
	_expect_vector(player.velocity, Vector3.ZERO, "Reset cancels jump velocity")
	_expect(player.get(&"ground_anchor_y") == spawn.y, "Reset snaps ground anchor to spawn height")
	_expect(not _vertical(player, true, false, step), "Reset in air cannot start another jump")
	_expect(player.velocity.y < 0.0, "Reset in air resumes falling")
	_expect(player.has_signal(&"jumped"), "Jump event is exposed for visual listeners")
	_expect(player.has_signal(&"landed"), "Landing impact event is exposed for visual listeners")
	player.free()


func _test_turn_response_is_sixty_percent_and_frame_rate_independent() -> void:
	# Arrange — exact previous/default coefficients define the approved change.
	var player: PlayerScript = _make_player()
	var tuning: TuningScript = player.tuning
	var step: float = 1.0 / 60.0
	var desired: float = PI / 2.0
	var low_rate: float = 0.0
	var high_rate: float = 0.0
	# Act
	var response: float = float(player.call(&"smooth_yaw", 0.0, desired, tuning.turn_sharpness, step))
	for frame: int in range(30):
		low_rate = float(player.call(&"smooth_yaw", low_rate, desired, tuning.turn_sharpness, 1.0 / 30.0))
	for frame: int in range(120):
		high_rate = float(player.call(&"smooth_yaw", high_rate, desired, tuning.turn_sharpness, 1.0 / 120.0))
	# Assert
	_expect_float(tuning.turn_sharpness / 22.0, 0.6, "New response coefficient is 60 percent of previous")
	_expect_float(response, desired * (1.0 - exp(-13.2 * step)), "Turning remains exponential, not an angular cap")
	_expect_float(low_rate, high_rate, "Yaw response agrees at 30 and 120 Hz")
	_expect_float(float(player.call(&"smooth_yaw", 0.0, desired, tuning.turn_sharpness, 0.0)),
		0.0, "Zero delta leaves yaw unchanged")
	_expect_float(float(player.call(&"smooth_yaw", 0.0, desired, tuning.turn_sharpness, -step)),
		0.0, "Negative delta leaves yaw unchanged")
	_expect_float(float(player.call(&"smooth_yaw", 0.0, desired, -1.0, step)),
		0.0, "Negative sharpness leaves yaw unchanged")
	var wrapped: float = float(player.call(&"smooth_yaw", PI - 0.1, -PI + 0.1, tuning.turn_sharpness, step))
	_expect(wrapped > PI - 0.1, "Yaw takes the shortest path across the angle seam")
	player.free()
