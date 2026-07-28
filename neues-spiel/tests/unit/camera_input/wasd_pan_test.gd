## Unit test — Camera & Input story cam-005 (ADR-0002 primary; WASD pan:
## yaw-relative, distance-scaled, world-bound clamp, delta clamp, raw-delta).
##
## Proves:
## 1. AC6/AC-1 [TR-camera-input-025]: pan moves the target in the
##    yaw-rotated input direction, scaled by delta-time and current distance
##    (faster when zoomed out) — proven via the pure formula directly and via
##    [method CameraInput._apply_pan] with an explicit resolved direction.
## 2. AC7/AC-2 [TR-camera-input-026]: at a world bound, further outward pan
##    yields zero further delta, no error, input still registers.
## 3. AC13/AC-3 [TR-camera-input-043]: a very large raw delta (post-hitch) is
##    clamped to `max_delta_time` before entering the pan formula.
## 4. AC20 [TR-camera-input-049]: margin 0 (the default) still clamps
##    correctly at the exact world edge — not an edge case, a valid config.
## 5. Raw-delta contract [TR-camera-input-030]: reinforces the existing
##    structural guard (`camera_input.gd` never references the Time & Tick
##    Autoload or its warp/pause clock by name) after this story's edits to
##    the same file.
## 6. Registration: every entry in [constant CameraInput.PAN_ACTIONS] is
##    registered in the InputMap (project.godot).
## 7. `pan_speed_factor`/`max_delta_time` are read from config, not hardcoded.
##
## Note on test shape (accumulated pitfall — headless input simulation):
## [method CameraInput._apply_pan] takes the already-resolved `input_dir` as
## an explicit parameter rather than reading `Input.get_vector` itself (see
## camera_input.gd's doc comment on [method CameraInput._process] for the
## architectural reasoning) — this suite exercises [method
## CameraInput._apply_pan] directly with a literal [Vector3], never
## `Input.action_press`/`get_vector`. GdUnit4's own CLI banner warns headless
## `InputEvents` "have no effect in the test," and this held-key polling path
## measurably does not register in this project's headless CLI harness
## (confirmed empirically: a prior draft using `Input.action_press` measured
## zero movement and silently truncated the remaining tests in this suite).
## `_unhandled_input`'s synthesized-[InputEvent] path (used by
## orbit_rotation_test.gd/multiplicative_zoom_test.gd) is unaffected — this
## note applies specifically to continuous `Input.get_vector` polling.
class_name WasdPanTest
extends GdUnitTestSuite

const CAMERA_INPUT_SOURCE_PATH: String = "res://src/camera_input/camera_input.gd"

## "Forward" direction before yaw rotation (W held, nothing else) — see
## camera_input.gd's [method CameraInput._process] doc comment for the -Z
## derivation from [method CameraInput.derive_position].
const FORWARD_INPUT_DIR := Vector3(0.0, 0.0, -1.0)


func _new_camera() -> CameraInput:
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()
	return camera


# ---------------------------------------------------------------------------
# AC6/AC-1 — yaw-relative, distance-scaled pan formula [TR-camera-input-025]
# ---------------------------------------------------------------------------

func test_derive_pan_delta_forward_at_yaw_zero_moves_along_negative_z() -> void:
	# Arrange — story's QA Test Case AC-1: yaw=0, distance=18, pan_speed_factor
	# =0.7 (GDD default), forward (W) held.

	# Act
	var pan_delta: Vector3 = CameraInput.derive_pan_delta(FORWARD_INPUT_DIR, 0.0, 18.0, 0.1, 0.7)

	# Assert — magnitude = delta * distance * pan_speed_factor = 0.1*18*0.7=1.26,
	# entirely on -Z, zero on X.
	assert_float(pan_delta.z).is_equal_approx(-1.26, 0.0001)
	assert_float(pan_delta.x).is_equal_approx(0.0, 0.0001)


func test_derive_pan_delta_rotates_input_direction_by_yaw() -> void:
	# Arrange — a quarter-turn yaw (PI/2) should rotate "forward" (-Z) onto
	# the -X axis (Vector3.rotated uses the right-hand rule around +Y).

	# Act
	var pan_delta: Vector3 = CameraInput.derive_pan_delta(FORWARD_INPUT_DIR, PI / 2.0, 10.0, 1.0, 1.0)

	# Assert
	assert_float(pan_delta.x).is_equal_approx(-10.0, 0.001)
	assert_float(pan_delta.z).is_equal_approx(0.0, 0.001)


func test_derive_pan_delta_is_proportionally_larger_at_greater_distance() -> void:
	# Arrange — GDD: "panning feels proportionally faster when zoomed out."
	# Act
	var near_delta: Vector3 = CameraInput.derive_pan_delta(FORWARD_INPUT_DIR, 0.0, 10.0, 0.1, 0.7)
	var far_delta: Vector3 = CameraInput.derive_pan_delta(FORWARD_INPUT_DIR, 0.0, 40.0, 0.1, 0.7)

	# Assert — 4x the distance yields exactly 4x the movement magnitude.
	assert_float(far_delta.length()).is_equal_approx(near_delta.length() * 4.0, 0.0001)


func test_derive_pan_delta_zero_input_yields_zero_delta_no_error() -> void:
	# Arrange — no keys held; Vector3.ZERO.normalized() must not error.
	# Act
	var pan_delta: Vector3 = CameraInput.derive_pan_delta(Vector3.ZERO, 0.7, 18.0, 0.1, 0.7)

	# Assert — reaching this line already proves no exception was raised.
	assert_float(pan_delta.length()).is_equal_approx(0.0, 0.0001)


func test_apply_pan_with_forward_direction_moves_target_forward() -> void:
	# Arrange — full instance path: CameraInput._apply_pan with an explicit
	# resolved direction (see class doc comment on headless input polling).
	# Start at a mid-world target, not the world-corner origin cam-001 sets by
	# default -- at the origin corner, "forward" at the default yaw (0.7) can
	# point outward past the [0, world_extent] bound and get clamped straight
	# back to zero (that is exactly the AC7 bound-clamp behavior under test
	# separately below, not a defect here -- this test isolates ordinary
	# mid-world movement instead).
	var camera: CameraInput = _new_camera()
	camera._target = Vector3(1000.0, 0.0, 1000.0)
	var initial_target: Vector3 = camera.get_target()

	# Act — one simulated frame of 0.1s with "forward" held.
	camera._apply_pan(0.1, FORWARD_INPUT_DIR)

	# Assert — target moved (yaw=0.7 default rotates it slightly off pure -Z,
	# so just confirm it moved and did not stay put).
	assert_float(camera.get_target().distance_to(initial_target)).is_greater(0.0)


func test_apply_pan_magnitude_scales_with_distance() -> void:
	# Arrange — two cameras, same starting mid-world target/yaw, different
	# distance. Mid-world (see test above) so neither hits the bound clamp.
	var camera_near: CameraInput = _new_camera()
	var camera_far: CameraInput = _new_camera()
	camera_near._target = Vector3(1000.0, 0.0, 1000.0)
	camera_far._target = Vector3(1000.0, 0.0, 1000.0)
	camera_far.set_distance(camera_far.config.distance_max)
	camera_near.set_distance(camera_near.config.distance_min)

	# Act — identical held direction/delta on both.
	camera_near._apply_pan(0.05, FORWARD_INPUT_DIR)
	camera_far._apply_pan(0.05, FORWARD_INPUT_DIR)

	# Assert — zoomed-out camera (distance_max) travels farther per frame than
	# the zoomed-in one (distance_min) for the identical held key/delta.
	var near_travel: float = camera_near.get_target().distance_to(Vector3(1000.0, 0.0, 1000.0))
	var far_travel: float = camera_far.get_target().distance_to(Vector3(1000.0, 0.0, 1000.0))
	assert_float(far_travel).is_greater(near_travel)


# ---------------------------------------------------------------------------
# AC7/AC-2 — bound clamp, no block [TR-camera-input-026]
# ---------------------------------------------------------------------------

func test_clamp_target_to_bounds_clamps_x_and_z_independently() -> void:
	# Arrange — a target pushed past both the min and max bound on X and Z.
	var over_target := Vector3(-5.0, 3.0, 2005.0)

	# Act
	var clamped: Vector3 = CameraInput.clamp_target_to_bounds(over_target, 2000, 2000, 1.0, 0.0)

	# Assert — clamped to [0, 2000] on X/Z; Y passes through untouched.
	assert_float(clamped.x).is_equal_approx(0.0, 0.0001)
	assert_float(clamped.z).is_equal_approx(2000.0, 0.0001)
	assert_float(clamped.y).is_equal_approx(3.0, 0.0001)


func test_repeated_outward_pan_at_a_bound_yields_zero_further_delta_no_error() -> void:
	# Arrange — camera target already pinned to the world's lower corner
	# (origin, both X and Z at their [0, extent] lower bound). Yaw pinned to
	# 0 so the push direction below maps directly onto world axes, not
	# rotated by the default start_yaw (see test_apply_pan_with_forward_
	# direction_moves_target_forward for that rotation-interaction pitfall).
	var camera: CameraInput = _new_camera()
	camera._yaw = 0.0
	assert_float(camera.get_target().length()).is_equal_approx(0.0, 0.0001)

	# Act — push further outward past BOTH lower bounds (negative X, negative
	# Z) repeatedly, several frames in a row. Input still registers (no
	# exception raised reaching this line); the target simply cannot move
	# further outward.
	for i in range(5):
		camera._apply_pan(0.1, Vector3(-1.0, 0.0, -1.0))

	# Assert — still pinned at the world-extent corner, never negative.
	assert_float(camera.get_target().x).is_equal_approx(0.0, 0.0001)
	assert_float(camera.get_target().z).is_equal_approx(0.0, 0.0001)


# ---------------------------------------------------------------------------
# AC13/AC-3 — delta clamp before the pan formula [TR-camera-input-043]
# ---------------------------------------------------------------------------

func test_apply_pan_clamps_a_huge_hitch_delta_to_max_delta_time() -> void:
	# Arrange — story's QA Test Case AC-3: a very large raw_delta (post-hitch).
	# Mid-world start (see test_apply_pan_with_forward_direction_moves_target_
	# forward for why the origin corner is avoided here).
	var camera: CameraInput = _new_camera()
	var start_target := Vector3(1000.0, 0.0, 1000.0)
	camera._target = start_target
	var expected_delta: Vector3 = CameraInput.derive_pan_delta(
		FORWARD_INPUT_DIR, camera.get_yaw(), camera.get_distance(),
		camera.config.max_delta_time, camera.config.pan_speed_factor
	)

	# Act — a 5-second hitch delta, far beyond max_delta_time (0.1s default).
	camera._apply_pan(5.0, FORWARD_INPUT_DIR)

	# Assert — movement matches the max_delta_time-clamped formula exactly,
	# not the raw 5.0s delta (which would be 50x larger).
	assert_float(camera.get_target().distance_to(start_target)).is_equal_approx(
		expected_delta.length(), 0.01
	)


# ---------------------------------------------------------------------------
# AC20 — margin 0 is a valid configuration, not an edge case [TR-camera-input-049]
# ---------------------------------------------------------------------------

func test_margin_zero_still_clamps_hard_against_the_exact_world_edge() -> void:
	# Arrange — default margin (0.0); target starts already pinned to the
	# exact far edge (the bound-clamp's own responsibility, exercised
	# directly here since reaching it via many small pan steps is exactly
	# what test_repeated_outward_pan_at_a_bound_yields_zero_further_delta_no_
	# error already covers at the near/origin edge -- this test covers the
	# far edge instead, per AC20's explicit "margin 0" emphasis).
	var camera: CameraInput = _new_camera()
	camera._yaw = 0.0
	assert_float(camera.config.pan_bound_margin).is_equal_approx(0.0, 0.0001)
	var far_edge: float = camera.config.world_width_cells * camera.config.cell_size
	camera._target = Vector3(far_edge, 0.0, far_edge)

	# Act — push further outward past BOTH upper bounds (positive X, positive
	# Z) repeatedly.
	for i in range(3):
		camera._apply_pan(0.1, Vector3(1.0, 0.0, 1.0))

	# Assert — no error raised reaching this line; stays pinned to the exact
	# edge value, never overshoots past it.
	assert_float(camera.get_target().x).is_equal_approx(far_edge, 0.0001)
	assert_float(camera.get_target().z).is_equal_approx(far_edge, 0.0001)


# ---------------------------------------------------------------------------
# Raw-delta contract [TR-camera-input-030] — structural reinforcement
# ---------------------------------------------------------------------------

func test_camera_input_source_still_never_references_time_tick_system_or_game_delta() -> void:
	# Arrange
	var source: String = FileAccess.get_file_as_string(CAMERA_INPUT_SOURCE_PATH)

	# Act + Assert — same structural guard orbit_rotation_test.gd already
	# established (cam-003), reinforced here after this story's edits to the
	# same file.
	assert_bool(source.contains("TimeTickSystem")).is_false()
	assert_bool(source.contains("game_delta")).is_false()


# ---------------------------------------------------------------------------
# Registration [TR-camera-input-032] — pan actions exist in project.godot
# ---------------------------------------------------------------------------

func test_every_pan_action_is_registered_in_input_map() -> void:
	# Arrange + Act + Assert
	for action_name: StringName in CameraInput.PAN_ACTIONS:
		assert_bool(InputMap.has_action(action_name)).override_failure_message(
			"Missing InputMap pan action (project.godot out of sync with CameraInput.PAN_ACTIONS): %s" % action_name
		).is_true()


func test_setup_with_fully_registered_pan_actions_does_not_raise() -> void:
	# Arrange + Act
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()

	# Assert — no assertion error raised.
	camera.setup()
	assert_bool(camera.is_set_up()).is_true()


# ---------------------------------------------------------------------------
# Config-driven, not hardcoded
# ---------------------------------------------------------------------------

func test_pan_uses_configured_pan_speed_factor_not_hardcoded() -> void:
	# Arrange — a config whose pan_speed_factor deliberately differs from the
	# GDD default, proving the factor is read from config. Mid-world start
	# (see test_apply_pan_with_forward_direction_moves_target_forward for why
	# the origin corner is avoided here).
	var camera: CameraInput = auto_free(CameraInput.new())
	var config := CameraInputConfig.new()
	config.pan_speed_factor = 1.2
	camera.config = config
	camera.setup()
	var start_target := Vector3(1000.0, 0.0, 1000.0)
	camera._target = start_target
	var expected_delta: Vector3 = CameraInput.derive_pan_delta(
		FORWARD_INPUT_DIR, camera.get_yaw(), camera.get_distance(), 0.1, 1.2
	)

	# Act
	camera._apply_pan(0.1, FORWARD_INPUT_DIR)

	# Assert
	assert_float(camera.get_target().distance_to(start_target)).is_equal_approx(
		expected_delta.length(), 0.0001
	)


func test_pan_uses_configured_max_delta_time_not_hardcoded() -> void:
	# Arrange — a config whose max_delta_time deliberately differs from the
	# GDD default, proving the clamp ceiling is read from config. Mid-world
	# start (see test_apply_pan_with_forward_direction_moves_target_forward).
	var camera: CameraInput = auto_free(CameraInput.new())
	var config := CameraInputConfig.new()
	config.max_delta_time = 0.05
	camera.config = config
	camera.setup()
	var start_target := Vector3(1000.0, 0.0, 1000.0)
	camera._target = start_target
	var expected_delta: Vector3 = CameraInput.derive_pan_delta(
		FORWARD_INPUT_DIR, camera.get_yaw(), camera.get_distance(), 0.05, camera.config.pan_speed_factor
	)

	# Act — a large delta, far beyond the configured 0.05s ceiling.
	camera._apply_pan(2.0, FORWARD_INPUT_DIR)

	# Assert
	assert_float(camera.get_target().distance_to(start_target)).is_equal_approx(
		expected_delta.length(), 0.01
	)
