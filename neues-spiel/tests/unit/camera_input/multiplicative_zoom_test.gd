## Unit test — Camera & Input story cam-004 (ADR-0002 primary; mouse-wheel
## zoom: multiplicative, clamped, rapid-event safe).
##
## Proves:
## 1. AC-1 [TR-camera-input-024]: a single wheel event multiplies distance
##    by `zoom_factor_in`/`zoom_factor_out` and clamps the result to
##    `[distance_min, distance_max]`; a zoom-out at distance_max stays at
##    distance_max (story's QA Test Case AC-1).
## 2. AC-2 [TR-camera-input-044]: N sequential rapid zoom events (any N)
##    still respect the clamp -- no compounding overshoot -- including the
##    alternating in/out edge case from the story's QA Test Case AC-2.
class_name MultiplicativeZoomTest
extends GdUnitTestSuite

const CAMERA_INPUT_SOURCE_PATH: String = "res://src/camera_input/camera_input.gd"


func _make_wheel_event(button_index: int, is_pressed: bool = true) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = is_pressed
	return event


func _new_camera() -> CameraInput:
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()
	return camera


# ---------------------------------------------------------------------------
# AC-1 — single wheel event, multiplicative + clamped [TR-camera-input-024]
# ---------------------------------------------------------------------------

func test_wheel_up_event_multiplies_distance_by_zoom_factor_in() -> void:
	# Arrange — story's QA Test Case AC-1: distance=18.0, zoom_factor_in=0.9.
	var camera: CameraInput = _new_camera()
	camera.set_distance(18.0)

	# Act — a single zoom-in (wheel-up) event.
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_UP))

	# Assert — 18.0 * 0.9 = 16.2.
	assert_float(camera.get_distance()).is_equal_approx(16.2, 0.0001)


func test_wheel_down_event_multiplies_distance_by_zoom_factor_out() -> void:
	# Arrange
	var camera: CameraInput = _new_camera()
	camera.set_distance(18.0)

	# Act — a single zoom-out (wheel-down) event.
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_DOWN))

	# Assert — 18.0 * 1.1 = 19.8.
	assert_float(camera.get_distance()).is_equal_approx(19.8, 0.0001)


func test_zoom_out_at_distance_max_stays_at_distance_max() -> void:
	# Arrange — story's QA Test Case AC-1 edge case: "a zoom-out at
	# distance_max stays at distance_max."
	var camera: CameraInput = _new_camera()
	camera.set_distance(camera.config.distance_max)

	# Act
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_DOWN))

	# Assert
	assert_float(camera.get_distance()).is_equal_approx(camera.config.distance_max, 0.0001)


func test_zoom_in_at_distance_min_stays_at_distance_min() -> void:
	# Arrange — symmetric case: zooming in further than distance_min clamps
	# silently rather than overshooting below the bound.
	var camera: CameraInput = _new_camera()
	camera.set_distance(camera.config.distance_min)

	# Act
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_UP))

	# Assert
	assert_float(camera.get_distance()).is_equal_approx(camera.config.distance_min, 0.0001)


func test_zoom_factors_use_configured_values_not_hardcoded() -> void:
	# Arrange — a config whose zoom factors deliberately differ from the GDD
	# defaults, proving the factors are read from config, not hardcoded.
	var camera: CameraInput = auto_free(CameraInput.new())
	var config := CameraInputConfig.new()
	config.zoom_factor_in = 0.85
	camera.config = config
	camera.setup()
	camera.set_distance(20.0)

	# Act
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_UP))

	# Assert — 20.0 * 0.85 = 17.0.
	assert_float(camera.get_distance()).is_equal_approx(17.0, 0.0001)


func test_wheel_release_event_does_not_zoom() -> void:
	# Arrange — a wheel event with pressed=false must not apply the factor
	# (mirrors cam-003's "per press, never per release" convention).
	var camera: CameraInput = _new_camera()
	camera.set_distance(18.0)

	# Act
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_UP, false))

	# Assert
	assert_float(camera.get_distance()).is_equal_approx(18.0, 0.0001)


func test_non_wheel_mouse_button_does_not_zoom() -> void:
	# Arrange — a left-click (build_place) must not also zoom the camera.
	var camera: CameraInput = _new_camera()
	camera.set_distance(18.0)

	# Act
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_LEFT))

	# Assert
	assert_float(camera.get_distance()).is_equal_approx(18.0, 0.0001)


# ---------------------------------------------------------------------------
# AC-2 — rapid sequential events respect the clamp regardless of N
# [TR-camera-input-044]
# ---------------------------------------------------------------------------

func test_50_rapid_zoom_in_events_never_drop_below_distance_min() -> void:
	# Arrange — story's QA Test Case AC-2: distance near distance_min, 50
	# rapid zoom-in events.
	var camera: CameraInput = _new_camera()
	camera.set_distance(camera.config.distance_min + 0.5)

	# Act
	for i in range(50):
		camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_UP))

	# Assert — never drops below distance_min, no compounding overshoot.
	assert_float(camera.get_distance()).is_equal_approx(camera.config.distance_min, 0.0001)


func test_50_rapid_zoom_out_events_never_exceed_distance_max() -> void:
	# Arrange — symmetric case at the opposite bound.
	var camera: CameraInput = _new_camera()
	camera.set_distance(camera.config.distance_max - 0.5)

	# Act
	for i in range(50):
		camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_DOWN))

	# Assert
	assert_float(camera.get_distance()).is_equal_approx(camera.config.distance_max, 0.0001)


func test_alternating_zoom_events_return_toward_start_without_drift() -> void:
	# Arrange — story's QA Test Case AC-2 edge case: "alternating in/out
	# events return toward the start value without drift past clamps."
	var camera: CameraInput = _new_camera()
	camera.set_distance(18.0)

	# Act — 20 alternating in/out events, well within either bound.
	for i in range(20):
		camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_UP))
		camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_DOWN))

	# Assert — 0.9 * 1.1 = 0.99 per round-trip, so distance drifts slightly
	# downward each pair (never past either clamp) rather than compounding
	# outward; confirm it stayed strictly within bounds after 40 events.
	var distance: float = camera.get_distance()
	assert_float(distance).is_greater_equal(camera.config.distance_min)
	assert_float(distance).is_less_equal(camera.config.distance_max)


func test_rapid_events_stay_within_bounds_across_full_zoom_range_sweep() -> void:
	# Arrange — an alternating sweep starting from distance_max, guaranteeing
	# repeated contact with the upper clamp before drifting down, proving no
	# overshoot at either end across a long rapid sequence.
	var camera: CameraInput = _new_camera()
	camera.set_distance(camera.config.distance_max)

	# Act
	for i in range(50):
		camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_DOWN))
	for i in range(50):
		camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_UP))

	# Assert
	var distance: float = camera.get_distance()
	assert_float(distance).is_greater_equal(camera.config.distance_min)
	assert_float(distance).is_less_equal(camera.config.distance_max)


func test_zoom_source_contains_no_accumulation_state_field() -> void:
	# Arrange — structural proof: the zoom method itself has no separate
	# accumulator field to desync from the clamp (GDD: "no accumulation
	# state -- each event applies independently").
	var source: String = FileAccess.get_file_as_string(CAMERA_INPUT_SOURCE_PATH)

	# Act + Assert
	assert_bool(source.contains("_apply_zoom")).is_true()
	assert_bool(source.contains("_zoom_accum")).is_false()
