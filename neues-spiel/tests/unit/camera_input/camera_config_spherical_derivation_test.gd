## Unit test — Camera & Input story cam-001 (ADR-0002 config Resource +
## ADR-0001 injected-tier DI, spherical position derivation).
##
## Proves:
## 1. AC-1 [TR-camera-input-021]: [CameraInput.derive_position] (the pure,
##    stateless formula) and [CameraInput.get_camera_position] (the instance
##    method) always equal `target + spherical offset`, are never
##    independently stored (recomputing yields the identical value), respect
##    yaw's 2*PI wrap equivalence, and stay exactly on a sphere of radius
##    `distance` regardless of distance_min/distance_max (a trig identity
##    stronger than eyeballing rounded numbers).
## 2. AC-2 [TR-camera-input-037]: [CameraInput.set_pitch] silently clamps to
##    `[pitch_min, pitch_max]`, the fixed pole-safety margin, and the
##    resulting derivation never degenerates at either bound.
## 3. AC-3 [TR-camera-input-019]: every [CameraInputConfig] tuning knob
##    defaults to its GDD-stated value, [CameraInput.setup] reads the
##    `start_*` knobs from whatever config it is given (not a hardcoded
##    literal), and [CameraInputConfig.validate]'s clamp+warn tier fires for
##    out-of-range knobs.
##
## Note on the GDD's worked example: `design/gdd/camera-input.md` quotes
## `target=(32,0,32), distance=18.0, yaw=0.7, pitch=0.95 ->
## camera_position ~= (38.75, 14.63, 40.02)`. Evaluating the exact formula
## with double precision yields (38.7451..., 14.6415..., 40.0081...) — the
## doc's hand-quoted Y/Z digits are off by ~0.01 from the formula it itself
## specifies (an authoring rounding slip, not a formula ambiguity — X does
## round-match at 2 decimals). This suite asserts against the doc's own
## formula, evaluated exactly, per TR-camera-input-048's clarification that
## "exact value" comparisons are precision-based, not literal-digit-based;
## the doc's quoted digits are additionally checked at doc-precision
## (0.02) so a future formula regression is still caught either way.
class_name CameraConfigSphericalDerivationTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# AC-1 — derived position, never independently stored [TR-camera-input-021]
# ---------------------------------------------------------------------------

func test_derive_position_gdd_worked_example_matches_exact_formula() -> void:
	# Arrange — GDD Formulas worked example.
	var target := Vector3(32.0, 0.0, 32.0)

	# Act
	var position: Vector3 = CameraInput.derive_position(target, 18.0, 0.7, 0.95)

	# Assert — exact double-precision evaluation of the same formula.
	assert_vector(position).is_equal_approx(
		Vector3(38.74515, 14.64148, 40.00812), Vector3(0.0001, 0.0001, 0.0001)
	)


func test_derive_position_gdd_worked_example_matches_doc_quoted_digits() -> void:
	# Arrange — same worked example, checked against the doc's own quoted
	# (rounded) digits at the doc's own display precision.
	var target := Vector3(32.0, 0.0, 32.0)

	# Act
	var position: Vector3 = CameraInput.derive_position(target, 18.0, 0.7, 0.95)

	# Assert
	assert_vector(position).is_equal_approx(
		Vector3(38.75, 14.63, 40.02), Vector3(0.02, 0.02, 0.02)
	)


func test_derive_position_recomputed_twice_yields_identical_value() -> void:
	# Arrange + Act — same inputs, two separate calls (no caching anywhere).
	var first: Vector3 = CameraInput.derive_position(Vector3(32.0, 0.0, 32.0), 18.0, 0.7, 0.95)
	var second: Vector3 = CameraInput.derive_position(Vector3(32.0, 0.0, 32.0), 18.0, 0.7, 0.95)

	# Assert
	assert_vector(first).is_equal(second)


func test_derive_position_yaw_wraps_by_two_pi_equivalence() -> void:
	# Arrange + Act
	var at_yaw: Vector3 = CameraInput.derive_position(Vector3.ZERO, 18.0, 0.7, 0.95)
	var at_yaw_plus_tau: Vector3 = CameraInput.derive_position(Vector3.ZERO, 18.0, 0.7 + TAU, 0.95)

	# Assert
	assert_vector(at_yaw_plus_tau).is_equal_approx(at_yaw, Vector3(0.0001, 0.0001, 0.0001))


func test_derive_position_stays_on_sphere_of_radius_distance_at_min() -> void:
	# Arrange — target at origin isolates the offset; distance_min (4.0) per
	# GDD Tuning Knobs. sin^2+cos^2=1 guarantees |offset| == distance exactly,
	# regardless of yaw/pitch — a stronger check than the rounded worked
	# example.
	var offset: Vector3 = CameraInput.derive_position(Vector3.ZERO, 4.0, 1.234, 0.6)

	# Act + Assert
	assert_float(offset.length()).is_equal_approx(4.0, 0.0001)


func test_derive_position_stays_on_sphere_of_radius_distance_at_max() -> void:
	# Arrange — distance_max (60.0) per GDD Tuning Knobs.
	var offset: Vector3 = CameraInput.derive_position(Vector3.ZERO, 60.0, -2.5, 0.2)

	# Act + Assert
	assert_float(offset.length()).is_equal_approx(60.0, 0.0001)


func test_camera_input_get_camera_position_matches_static_derivation_after_setup() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()

	# Act
	camera.setup()
	var expected: Vector3 = CameraInput.derive_position(
		camera.get_target(), camera.get_distance(), camera.get_yaw(), camera.get_pitch()
	)

	# Assert
	assert_vector(camera.get_camera_position()).is_equal(expected)


func test_camera_input_get_camera_position_called_twice_returns_identical_value() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()

	# Act
	var first: Vector3 = camera.get_camera_position()
	var second: Vector3 = camera.get_camera_position()

	# Assert — proves position is recomputed, not cached in an independent field.
	assert_vector(first).is_equal(second)


# ---------------------------------------------------------------------------
# AC-2 — pitch pole-safety clamp [TR-camera-input-037]
# ---------------------------------------------------------------------------

func test_set_pitch_zero_clamps_to_pitch_min() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()

	# Act
	camera.set_pitch(0.0)

	# Assert
	assert_float(camera.get_pitch()).is_equal_approx(CameraInputConfig.START_PITCH_MIN, 0.0001)


func test_set_pitch_half_pi_clamps_to_pitch_max() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()

	# Act
	camera.set_pitch(PI / 2.0)

	# Assert
	assert_float(camera.get_pitch()).is_equal_approx(CameraInputConfig.START_PITCH_MAX, 0.0001)


func test_set_pitch_within_range_is_not_clamped() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()

	# Act
	camera.set_pitch(0.5)

	# Assert
	assert_float(camera.get_pitch()).is_equal_approx(0.5, 0.0001)


func test_set_pitch_at_clamped_min_bound_position_does_not_degenerate() -> void:
	# Arrange — pitch driven to the lower pole-safety bound; the horizontal
	# offset component must stay meaningfully non-zero (cos(pitch_min) is far
	# from zero at 0.15 rad).
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()
	camera.set_pitch(0.0)

	# Act
	var position: Vector3 = camera.get_camera_position()
	var horizontal := Vector2(position.x - camera.get_target().x, position.z - camera.get_target().z)

	# Assert
	assert_float(horizontal.length()).is_greater(1.0)


func test_set_pitch_at_clamped_max_bound_position_does_not_degenerate() -> void:
	# Arrange — pitch driven to the upper pole-safety bound (1.5 rad, ~86 deg
	# -- still 3.4 deg shy of the true pole where the derivation degenerates).
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()
	camera.set_pitch(PI / 2.0)

	# Act
	var position: Vector3 = camera.get_camera_position()
	var horizontal := Vector2(position.x - camera.get_target().x, position.z - camera.get_target().z)

	# Assert — non-zero, not collapsed to a single point above the target.
	assert_float(horizontal.length()).is_greater(0.5)


func test_set_pitch_missing_config_raises_assertion() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())

	# Act + Assert
	await assert_error(func() -> void: camera.set_pitch(0.5)).is_runtime_error(
		"Assertion failed: CameraInput.config not wired"
	)


# ---------------------------------------------------------------------------
# AC-3 — config-driven, no hardcoded literals [TR-camera-input-019]
# ---------------------------------------------------------------------------

func test_camera_input_config_defaults_match_gdd_tuning_knobs() -> void:
	# Arrange + Act
	var config := CameraInputConfig.new()

	# Assert — design/gdd/camera-input.md Tuning Knobs section.
	assert_float(config.start_distance).is_equal_approx(18.0, 0.0001)
	assert_float(config.start_yaw).is_equal_approx(0.7, 0.0001)
	assert_float(config.start_pitch).is_equal_approx(0.95, 0.0001)
	assert_float(config.distance_min).is_equal_approx(4.0, 0.0001)
	assert_float(config.distance_max).is_equal_approx(60.0, 0.0001)
	assert_float(config.zoom_factor_in).is_equal_approx(0.9, 0.0001)
	assert_float(config.zoom_factor_out).is_equal_approx(1.1, 0.0001)
	assert_float(config.pitch_min).is_equal_approx(0.15, 0.0001)
	assert_float(config.pitch_max).is_equal_approx(1.5, 0.0001)
	assert_float(config.q_e_rotate_step).is_equal_approx(0.12, 0.0001)
	assert_float(config.mouse_drag_sensitivity).is_equal_approx(0.008, 0.0001)
	assert_float(config.pan_speed_factor).is_equal_approx(0.7, 0.0001)
	assert_float(config.max_delta_time).is_equal_approx(0.1, 0.0001)


func test_camera_input_config_validate_gdd_defaults_returns_empty() -> void:
	# Arrange
	var config := CameraInputConfig.new()

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_array(issues).is_empty()


func test_camera_input_config_validate_start_distance_below_min_clamps_and_warns() -> void:
	# Arrange
	var config := CameraInputConfig.new()
	config.start_distance = -5.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_float(config.start_distance).is_equal_approx(CameraInputConfig.START_DISTANCE_MIN, 0.0001)


func test_camera_input_config_validate_zoom_factor_in_above_max_clamps_and_warns() -> void:
	# Arrange
	var config := CameraInputConfig.new()
	config.zoom_factor_in = 5.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_float(config.zoom_factor_in).is_equal_approx(CameraInputConfig.ZOOM_FACTOR_IN_MAX, 0.0001)


func test_camera_input_config_validate_max_delta_time_above_max_clamps_and_warns() -> void:
	# Arrange
	var config := CameraInputConfig.new()
	config.max_delta_time = 10.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_float(config.max_delta_time).is_equal_approx(CameraInputConfig.MAX_DELTA_TIME_MAX, 0.0001)


func test_camera_input_setup_reads_start_values_from_config_not_hardcoded() -> void:
	# Arrange — deliberately distinct from GDD defaults, to prove setup()
	# reads whatever config it is given rather than a hardcoded literal.
	var camera: CameraInput = auto_free(CameraInput.new())
	var config := CameraInputConfig.new()
	config.start_distance = 42.0
	config.start_yaw = 1.23
	config.start_pitch = 1.1
	camera.config = config

	# Act
	camera.setup()

	# Assert
	assert_float(camera.get_distance()).is_equal_approx(42.0, 0.0001)
	assert_float(camera.get_yaw()).is_equal_approx(1.23, 0.0001)
	assert_float(camera.get_pitch()).is_equal_approx(1.1, 0.0001)


func test_camera_input_setup_clamps_start_pitch_to_config_pole_safety_bounds() -> void:
	# Arrange — a config whose start_pitch itself sits outside its own
	# pitch_min/pitch_max (e.g. authored by hand, or clamped by a prior
	# validate() pass on a different field); setup() must still guarantee the
	# invariant on its own internal state.
	var camera: CameraInput = auto_free(CameraInput.new())
	var config := CameraInputConfig.new()
	config.start_pitch = 1.5
	config.pitch_max = 1.2
	camera.config = config

	# Act
	camera.setup()

	# Assert
	assert_float(camera.get_pitch()).is_equal_approx(1.2, 0.0001)


func test_camera_input_setup_missing_config_raises_assertion() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())

	# Act + Assert
	await assert_error(func() -> void: camera.setup()).is_runtime_error(
		"Assertion failed: CameraInput.config not wired"
	)


func test_camera_input_setup_completes_and_reports_not_set_up_before() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	assert_bool(camera.is_set_up()).is_false()

	# Act
	camera.setup()

	# Assert
	assert_bool(camera.is_set_up()).is_true()
