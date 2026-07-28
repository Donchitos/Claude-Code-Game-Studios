## Unit test — Camera & Input story cam-003 (ADR-0002 primary; orbit
## rotation: middle-mouse-drag + Q/E, pitch pole-safety clamp, raw-delta
## contract).
##
## Proves:
## 1. AC-1 [TR-camera-input-022]: middle-mouse-drag changes yaw/pitch
##    proportional to `mouse_drag_sensitivity`, gated on the motion event's
##    own `button_mask` (no separate drag-state field to get stuck), and
##    does nothing when the middle button is not held.
## 2. AC-2 [TR-camera-input-023]: Q/E change yaw by -/+ `q_e_rotate_step`
##    per PRESS (never release), net zero for a Q-then-E pair, and the step
##    is read from config rather than hardcoded.
## 3. AC-3 [TR-camera-input-040]: a vertical drag that would push pitch
##    beyond `[pitch_min, pitch_max]` clamps silently to the boundary --
##    inherited for free from [CameraInput.set_pitch] (story cam-001).
## 4. AC-4 [TR-camera-input-030]: rotation is driven by raw engine delta --
##    proven structurally (the source never references `TimeTickSystem` or
##    `game_delta`) AND behaviorally (identical rotation input applied while
##    the real `TimeTickSystem` Autoload is paused and warped 3x produces
##    the identical yaw delta as unpaused/1x, per the story's QA Test Case).
class_name OrbitRotationTest
extends GdUnitTestSuite

const CAMERA_INPUT_SOURCE_PATH: String = "res://src/camera_input/camera_input.gd"


func _make_key_event(keycode: int, is_pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = is_pressed
	return event


func _make_middle_drag_motion(relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	return event


func _make_plain_motion(relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.button_mask = 0
	return event


func _new_camera() -> CameraInput:
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()
	return camera


# ---------------------------------------------------------------------------
# AC-1 — middle-mouse-drag rotation [TR-camera-input-022]
# ---------------------------------------------------------------------------

func test_middle_drag_horizontal_motion_changes_yaw_proportional_to_sensitivity() -> void:
	# Arrange
	var camera: CameraInput = _new_camera()
	var initial_yaw: float = camera.get_yaw()

	# Act — D=10px horizontal drag, middle button held.
	camera._unhandled_input(_make_middle_drag_motion(Vector2(10.0, 0.0)))

	# Assert — yaw changes by D * mouse_drag_sensitivity (0.008 default).
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw + 10.0 * 0.008, 0.0001)


func test_middle_drag_vertical_motion_changes_pitch_proportional_to_sensitivity() -> void:
	# Arrange
	var camera: CameraInput = _new_camera()
	var initial_pitch: float = camera.get_pitch()

	# Act — D=10px vertical drag, middle button held.
	camera._unhandled_input(_make_middle_drag_motion(Vector2(0.0, 10.0)))

	# Assert
	assert_float(camera.get_pitch()).is_equal_approx(initial_pitch + 10.0 * 0.008, 0.0001)


func test_middle_drag_combined_horizontal_then_vertical_matches_qa_test_case() -> void:
	# Arrange — story's QA Test Case AC-1: mouse_drag_sensitivity = 0.008,
	# a horizontal drag of D pixels then a vertical drag of D pixels.
	var camera: CameraInput = _new_camera()
	var initial_yaw: float = camera.get_yaw()
	var initial_pitch: float = camera.get_pitch()
	var d := 15.0

	# Act
	camera._unhandled_input(_make_middle_drag_motion(Vector2(d, 0.0)))
	camera._unhandled_input(_make_middle_drag_motion(Vector2(0.0, d)))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw + d * 0.008, 0.0001)
	assert_float(camera.get_pitch()).is_equal_approx(initial_pitch + d * 0.008, 0.0001)


func test_motion_without_any_button_held_does_not_rotate() -> void:
	# Arrange — plain mouse motion, no button held (idle cursor movement over
	# the viewport). Must not rotate the camera.
	var camera: CameraInput = _new_camera()
	var initial_yaw: float = camera.get_yaw()
	var initial_pitch: float = camera.get_pitch()

	# Act
	camera._unhandled_input(_make_plain_motion(Vector2(50.0, 50.0)))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw, 0.0001)
	assert_float(camera.get_pitch()).is_equal_approx(initial_pitch, 0.0001)


func test_motion_with_only_left_button_held_does_not_rotate() -> void:
	# Arrange — a build_place drag (left button) must not also rotate the
	# camera; only the middle button drives rotation.
	var camera: CameraInput = _new_camera()
	var initial_yaw: float = camera.get_yaw()
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(50.0, 0.0)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT

	# Act
	camera._unhandled_input(event)

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw, 0.0001)


func test_middle_drag_step_uses_configured_sensitivity_not_hardcoded() -> void:
	# Arrange — a config whose mouse_drag_sensitivity deliberately differs
	# from the GDD default, proving the rate is read from config.
	var camera: CameraInput = auto_free(CameraInput.new())
	var config := CameraInputConfig.new()
	config.mouse_drag_sensitivity = 0.015
	camera.config = config
	camera.setup()
	var initial_yaw: float = camera.get_yaw()

	# Act
	camera._unhandled_input(_make_middle_drag_motion(Vector2(10.0, 0.0)))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw + 10.0 * 0.015, 0.0001)


# ---------------------------------------------------------------------------
# AC-2 — Q/E fixed-step yaw [TR-camera-input-023]
# ---------------------------------------------------------------------------

func test_q_key_press_rotates_yaw_by_negative_step() -> void:
	# Arrange
	var camera: CameraInput = _new_camera()
	var initial_yaw: float = camera.get_yaw()

	# Act — Q, project.godot's camera_rotate_left binding.
	camera._unhandled_input(_make_key_event(KEY_Q))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw - camera.config.q_e_rotate_step, 0.0001)


func test_e_key_press_rotates_yaw_by_positive_step() -> void:
	# Arrange
	var camera: CameraInput = _new_camera()
	var initial_yaw: float = camera.get_yaw()

	# Act — E, project.godot's camera_rotate_right binding.
	camera._unhandled_input(_make_key_event(KEY_E))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw + camera.config.q_e_rotate_step, 0.0001)


func test_q_then_e_yields_net_zero_yaw_change() -> void:
	# Arrange — story's QA Test Case AC-2: q_e_rotate_step = 0.12 (GDD
	# default); Q then E pressed; yaw -0.12 then +0.12, net 0.
	var camera: CameraInput = _new_camera()
	var initial_yaw: float = camera.get_yaw()

	# Act
	camera._unhandled_input(_make_key_event(KEY_Q))
	camera._unhandled_input(_make_key_event(KEY_E))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw, 0.0001)


func test_q_key_release_does_not_rotate() -> void:
	# Arrange — "per press," never per release (mirrors cam-002's
	# is_action_pressed-only convention).
	var camera: CameraInput = _new_camera()
	var initial_yaw: float = camera.get_yaw()

	# Act
	camera._unhandled_input(_make_key_event(KEY_Q, false))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw, 0.0001)


func test_q_e_step_uses_configured_value_not_hardcoded() -> void:
	# Arrange — a config whose q_e_rotate_step deliberately differs from the
	# GDD default, proving the step is read from config, not hardcoded.
	var camera: CameraInput = auto_free(CameraInput.new())
	var config := CameraInputConfig.new()
	config.q_e_rotate_step = 0.2
	camera.config = config
	camera.setup()
	var initial_yaw: float = camera.get_yaw()

	# Act
	camera._unhandled_input(_make_key_event(KEY_E))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw + 0.2, 0.0001)


# ---------------------------------------------------------------------------
# AC-3 — pitch pole-safety clamp is silent [TR-camera-input-040]
# ---------------------------------------------------------------------------

func test_vertical_drag_exceeding_pitch_max_clamps_silently() -> void:
	# Arrange — GDD Edge Case: "mouse-drag would push pitch beyond its
	# bounds -- silently clamps, no error."
	var camera: CameraInput = _new_camera()

	# Act — a huge vertical drag, far beyond any single-event bound.
	camera._unhandled_input(_make_middle_drag_motion(Vector2(0.0, 100000.0)))

	# Assert — clamped to pitch_max; reaching this line already proves no
	# exception was raised.
	assert_float(camera.get_pitch()).is_equal_approx(camera.config.pitch_max, 0.0001)


func test_vertical_drag_exceeding_pitch_min_clamps_silently() -> void:
	# Arrange
	var camera: CameraInput = _new_camera()

	# Act — a huge negative vertical drag.
	camera._unhandled_input(_make_middle_drag_motion(Vector2(0.0, -100000.0)))

	# Assert
	assert_float(camera.get_pitch()).is_equal_approx(camera.config.pitch_min, 0.0001)


func test_repeated_drags_past_the_bound_stay_clamped_no_error() -> void:
	# Arrange — repeated pushes past the bound must not error or overshoot.
	var camera: CameraInput = _new_camera()

	# Act
	for i in range(5):
		camera._unhandled_input(_make_middle_drag_motion(Vector2(0.0, 100000.0)))

	# Assert
	assert_float(camera.get_pitch()).is_equal_approx(camera.config.pitch_max, 0.0001)


# ---------------------------------------------------------------------------
# AC-4 — raw-delta contract [TR-camera-input-030]
# ---------------------------------------------------------------------------

func test_rotation_source_never_references_time_tick_system_or_game_delta() -> void:
	# Arrange
	var source: String = FileAccess.get_file_as_string(CAMERA_INPUT_SOURCE_PATH)

	# Act + Assert — structural proof: rotation cannot be warp/pause-gated
	# if the file never reads the clock that warp/pause control.
	assert_bool(source.contains("TimeTickSystem")).is_false()
	assert_bool(source.contains("game_delta")).is_false()


func test_rotation_magnitude_identical_while_time_tick_system_paused_and_warped() -> void:
	# Arrange — story's QA Test Case AC-3: time-warp at 3x and pause
	# toggled; rotation magnitude per frame must be unaffected.
	var camera_a: CameraInput = _new_camera()
	var camera_b: CameraInput = _new_camera()
	var baseline_yaw_a: float = camera_a.get_yaw()
	var baseline_yaw_b: float = camera_b.get_yaw()
	var original_paused: bool = TimeTickSystem.paused
	var original_warp: int = TimeTickSystem.time_warp

	# Act — camera_a rotates while the real TimeTickSystem Autoload is
	# paused and warped 3x; camera_b is a control run at TimeTickSystem's
	# normal unpaused/1x state. Restore TimeTickSystem's original state
	# immediately after acting (Autoload state persists across tests in the
	# same run) rather than depending on assertions not short-circuiting.
	TimeTickSystem.pause()
	TimeTickSystem.set_warp(3)
	camera_a._unhandled_input(_make_middle_drag_motion(Vector2(20.0, 0.0)))
	TimeTickSystem.resume()
	TimeTickSystem.set_warp(1)
	camera_b._unhandled_input(_make_middle_drag_motion(Vector2(20.0, 0.0)))
	if original_paused:
		TimeTickSystem.pause()
	else:
		TimeTickSystem.resume()
	TimeTickSystem.set_warp(original_warp)

	# Assert — identical yaw delta regardless of TimeTickSystem's state.
	assert_float(camera_a.get_yaw() - baseline_yaw_a).is_equal_approx(
		camera_b.get_yaw() - baseline_yaw_b, 0.0001
	)
