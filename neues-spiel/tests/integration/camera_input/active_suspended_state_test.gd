## Integration test — Camera & Input story cam-007 (ADR-0010 primary /
## ADR-0013 secondary; Active/Suspended state machine bound to Scene/World
## Management's transition_begun/transition_ended contract surface).
##
## Proves:
## 1. AC9 [TR-camera-input-034]: a transition-begin signal immediately enters
##    Suspended — no rotate/zoom/pan, no action_fired dispatch.
## 2. AC10 [TR-camera-input-033, -042]: transition_ended (success=true OR
##    success=false/abort) releases Suspended back to Active with the exact
##    same yaw/pitch/distance/target it had when frozen — proven structurally
##    (every mutation path is itself gated on Active, so nothing can drift
##    during the frozen window; no separate snapshot/restore copy is needed
##    to prove "no snap").
## 3. AC11 [TR-camera-input-041]: a rotate (middle-mouse) drag held across a
##    suspend/resume boundary is ignored until an explicit release + fresh
##    press.
## 4. TR-camera-input-031: Suspended and Pause are independent — this suite
##    never drives TimeTickSystem's pause/warp state and asserts it stays
##    untouched by begin/end_transition.
## 5. TR-camera-input-029 (carried from cam-006): [method
##    CameraInput.get_world_ray] stays fully computable while Suspended.
##
## Binding shape (per the story's Implementation Notes — "Connect BOTH end
## signals"): [CameraInput] itself owns the
## `game_world.transition_begun`/`transition_ended.connect(...)` calls inside
## [method CameraInput.setup] (ADR-0001 injected-tier wiring) —
## [GameWorld] never calls into this consumer directly (its own class doc
## comment: "this class makes no direct call into any consumer, by
## construction" [TR-scene-world-management-049]). This suite instantiates a
## bare [GameWorld] with `Node.new()` (no scene tree, no boot gate involved —
## [method GameWorld.begin_transition]/[method GameWorld.end_transition] touch
## neither [enum GameWorld.BootState] nor `resource_item_database`),
## mirroring this project's established zero-scene-tree DI test convention.
class_name ActiveSuspendedStateTest
extends GdUnitTestSuite

const CAMERA_INPUT_SOURCE_PATH: String = "res://src/camera_input/camera_input.gd"


func _make_middle_drag_motion(relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	return event


func _make_middle_button_event(is_pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_MIDDLE
	event.pressed = is_pressed
	return event


func _make_wheel_event(button_index: int) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	return event


func _make_key_event(keycode: int, is_pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = is_pressed
	return event


## Returns a [CameraInput] wired to a bare [GameWorld] (its `game_world`
## export set before [method CameraInput.setup] runs, so
## [method CameraInput._connect_transition_signals] connects both signals).
## The [GameWorld] instance itself is reachable afterward via
## `camera.game_world`.
func _new_wired_camera() -> CameraInput:
	var world: GameWorld = auto_free(GameWorld.new())
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.game_world = world
	camera.setup()
	return camera


# ---------------------------------------------------------------------------
# AC9 — suspend on transition-begin [TR-camera-input-034]
# ---------------------------------------------------------------------------

func test_transition_begun_enters_suspended() -> void:
	# Arrange
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world

	# Act
	world.begin_transition()

	# Assert
	assert_int(camera.get_state()).is_equal(CameraInput.State.SUSPENDED)


func test_suspended_middle_drag_produces_no_yaw_or_pitch_change() -> void:
	# Arrange
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	var initial_yaw: float = camera.get_yaw()
	var initial_pitch: float = camera.get_pitch()
	world.begin_transition()

	# Act
	camera._unhandled_input(_make_middle_drag_motion(Vector2(50.0, 50.0)))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw, 0.0001)
	assert_float(camera.get_pitch()).is_equal_approx(initial_pitch, 0.0001)


func test_suspended_zoom_wheel_produces_no_distance_change() -> void:
	# Arrange
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	var initial_distance: float = camera.get_distance()
	world.begin_transition()

	# Act
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_UP))

	# Assert
	assert_float(camera.get_distance()).is_equal_approx(initial_distance, 0.0001)


func test_suspended_pan_produces_no_target_change() -> void:
	# Arrange — mid-world start (established wasd_pan_test.gd convention, avoids
	# the origin-corner bound-clamp interaction).
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	camera._target = Vector3(1000.0, 0.0, 1000.0)
	var initial_target: Vector3 = camera.get_target()
	world.begin_transition()

	# Act — directly exercises _apply_pan (the established headless-pan
	# convention, wasd_pan_test.gd), not _process (untestable held-key polling).
	camera._apply_pan(0.1, Vector3(0.0, 0.0, -1.0))

	# Assert
	assert_vector(camera.get_target()).is_equal(initial_target)


func test_suspended_unhandled_input_does_not_emit_action_fired() -> void:
	# Arrange
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	var received: Array[StringName] = []
	camera.action_fired.connect(func(action_name: StringName) -> void: received.append(action_name))
	world.begin_transition()

	# Act — Q, project.godot's camera_rotate_left binding (an owned action).
	camera._unhandled_input(_make_key_event(KEY_Q))

	# Assert
	assert_array(received).is_empty()


func test_suspended_qe_key_produces_no_yaw_change() -> void:
	# Arrange
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	var initial_yaw: float = camera.get_yaw()
	world.begin_transition()

	# Act
	camera._unhandled_input(_make_key_event(KEY_Q))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw, 0.0001)


func test_process_and_unhandled_input_are_disabled_while_suspended() -> void:
	# Arrange — the idiomatic Godot "disable when idle" engine opt-out, not
	# just an internal branch. A live SceneTree is required for
	# is_processing()/is_processing_unhandled_input() to reflect the real
	# engine-driven flag (mirrors mouse_world_ray_test.gd's established
	# add_child(camera) pattern) -- a freestanding, not-yet-added Node reports
	# both as false regardless of state, since there is no tree to process it.
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	add_child(camera)
	assert_bool(camera.is_processing()).is_true()
	assert_bool(camera.is_processing_unhandled_input()).is_true()

	# Act
	world.begin_transition()

	# Assert
	assert_bool(camera.is_processing()).is_false()
	assert_bool(camera.is_processing_unhandled_input()).is_false()


# ---------------------------------------------------------------------------
# AC10 — release on complete OR abort, exact restore
# [TR-camera-input-033, -042]
# ---------------------------------------------------------------------------

func test_transition_ended_success_true_returns_to_active() -> void:
	# Arrange
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	world.begin_transition()

	# Act
	world.end_transition(true)

	# Assert
	assert_int(camera.get_state()).is_equal(CameraInput.State.ACTIVE)


func test_transition_ended_success_false_abort_also_returns_to_active() -> void:
	# Arrange — the abort path: a failed load must never strand this system
	# in Suspended [TR-camera-input-033].
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	world.begin_transition()

	# Act
	world.end_transition(false)

	# Assert
	assert_int(camera.get_state()).is_equal(CameraInput.State.ACTIVE)


func test_resumed_state_exactly_matches_pre_suspend_values_within_epsilon() -> void:
	# Arrange — distinctive, non-default yaw/pitch/distance/target immediately
	# before suspending.
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	camera._unhandled_input(_make_middle_drag_motion(Vector2(37.0, 21.0)))
	camera._unhandled_input(_make_wheel_event(MOUSE_BUTTON_WHEEL_DOWN))
	camera._target = Vector3(123.0, 0.0, 456.0)
	var expected_yaw: float = camera.get_yaw()
	var expected_pitch: float = camera.get_pitch()
	var expected_distance: float = camera.get_distance()
	var expected_target: Vector3 = camera.get_target()

	# Act
	world.begin_transition()
	world.end_transition(true)

	# Assert — TR-camera-input-048's 1e-4 precision tolerance.
	assert_float(camera.get_yaw()).is_equal_approx(expected_yaw, 0.0001)
	assert_float(camera.get_pitch()).is_equal_approx(expected_pitch, 0.0001)
	assert_float(camera.get_distance()).is_equal_approx(expected_distance, 0.0001)
	assert_vector(camera.get_target()).is_equal_approx(expected_target, Vector3.ONE * 0.0001)


func test_active_after_resume_processes_input_normally_again() -> void:
	# Arrange — proves resume is a clean re-entry, not a one-shot dead end.
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	world.begin_transition()
	world.end_transition(true)
	var initial_yaw: float = camera.get_yaw()

	# Act — a fresh middle-mouse drag; no button was ever held across the
	# suspend/resume boundary in this test.
	camera._unhandled_input(_make_middle_drag_motion(Vector2(10.0, 0.0)))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(
		initial_yaw + 10.0 * camera.config.mouse_drag_sensitivity, 0.0001
	)


func test_process_and_unhandled_input_re_enabled_after_resume() -> void:
	# Arrange
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	world.begin_transition()

	# Act
	world.end_transition(true)

	# Assert
	assert_bool(camera.is_processing()).is_true()
	assert_bool(camera.is_processing_unhandled_input()).is_true()


# ---------------------------------------------------------------------------
# AC11 — held rotate button dropped across suspend/resume
# [TR-camera-input-041]
# ---------------------------------------------------------------------------

func test_held_middle_drag_ignored_through_suspend_and_resume_until_release() -> void:
	# Arrange — the button was already mid-drag when the transition begins.
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	camera._unhandled_input(_make_middle_drag_motion(Vector2(5.0, 0.0)))
	world.begin_transition()
	world.end_transition(true)
	var yaw_after_resume: float = camera.get_yaw()

	# Act — the SAME physical drag continues (button never released) across
	# the resume boundary.
	camera._unhandled_input(_make_middle_drag_motion(Vector2(50.0, 0.0)))

	# Assert — still ignored; no rotation from the continued, never-released
	# drag.
	assert_float(camera.get_yaw()).is_equal_approx(yaw_after_resume, 0.0001)


func test_held_middle_drag_resumes_after_explicit_release_and_re_press() -> void:
	# Arrange — same setup as above, but this time the button is properly
	# released post-resume, then freshly re-pressed.
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	camera._unhandled_input(_make_middle_drag_motion(Vector2(5.0, 0.0)))
	world.begin_transition()
	world.end_transition(true)
	camera._unhandled_input(_make_middle_drag_motion(Vector2(50.0, 0.0)))  # still ignored
	var yaw_before_release: float = camera.get_yaw()

	# Act — release, then a fresh press + drag.
	camera._unhandled_input(_make_middle_button_event(false))
	camera._unhandled_input(_make_middle_button_event(true))
	camera._unhandled_input(_make_middle_drag_motion(Vector2(10.0, 0.0)))

	# Assert — rotation now applies normally.
	assert_float(camera.get_yaw()).is_equal_approx(
		yaw_before_release + 10.0 * camera.config.mouse_drag_sensitivity, 0.0001
	)


func test_no_drag_in_progress_at_suspend_does_not_lock_rotation() -> void:
	# Arrange — ordinary suspend/resume with no rotate button held at all;
	# rotation must work immediately post-resume without needing any
	# release/re-press cycle.
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	world.begin_transition()
	world.end_transition(true)
	var initial_yaw: float = camera.get_yaw()

	# Act
	camera._unhandled_input(_make_middle_drag_motion(Vector2(10.0, 0.0)))

	# Assert
	assert_float(camera.get_yaw()).is_equal_approx(
		initial_yaw + 10.0 * camera.config.mouse_drag_sensitivity, 0.0001
	)


# ---------------------------------------------------------------------------
# TR-camera-input-031 — Suspended and Pause are independent
# ---------------------------------------------------------------------------

func test_suspended_state_does_not_touch_time_tick_system_pause_or_warp() -> void:
	# Arrange — structural proof: this story's additions never reference
	# TimeTickSystem/game_delta, mirroring the existing raw-delta structural
	# guards in orbit_rotation_test.gd/wasd_pan_test.gd.
	var source: String = FileAccess.get_file_as_string(CAMERA_INPUT_SOURCE_PATH)

	# Act + Assert
	assert_bool(source.contains("TimeTickSystem")).is_false()
	assert_bool(source.contains("game_delta")).is_false()


func test_pause_state_is_untouched_by_transition_signals() -> void:
	# Arrange — firing a transition must never call TimeTickSystem.pause()/
	# resume(); captured by asserting TimeTickSystem's own paused flag is
	# unaffected by begin/end_transition.
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	var original_paused: bool = TimeTickSystem.paused

	# Act
	world.begin_transition()
	world.end_transition(true)

	# Assert
	assert_bool(TimeTickSystem.paused).is_equal(original_paused)


# ---------------------------------------------------------------------------
# TR-camera-input-029 (carried from cam-006) — world-ray stays computable
# ---------------------------------------------------------------------------

func test_world_ray_remains_computable_while_suspended() -> void:
	# Arrange — a live SceneTree is required for get_viewport() to resolve
	# (mirrors mouse_world_ray_test.gd's established add_child(camera) pattern).
	var camera: CameraInput = _new_wired_camera()
	var world: GameWorld = camera.game_world
	add_child(camera)
	world.begin_transition()

	# Act
	var ray: WorldRay = camera.get_world_ray()

	# Assert — a finite, normalized-direction ray, no error, no special-case
	# branch required (mouse_world_ray_test.gd's own structural guard on this
	# method's body is unaffected by this story).
	assert_float(ray.direction.length()).is_equal_approx(1.0, 0.001)
	assert_vector(ray.origin).is_equal_approx(camera.get_camera_position(), Vector3.ONE * 0.0001)


# ---------------------------------------------------------------------------
# Wiring — game_world is optional (pre-existing DI test convention unaffected)
# ---------------------------------------------------------------------------

func test_setup_without_game_world_wired_does_not_raise_and_stays_active() -> void:
	# Arrange — mirrors GameWorld.valley_scene's own "deliberately optional"
	# precedent: pre-existing tests that never wire game_world must continue
	# to construct/setup unaffected.
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()

	# Act
	camera.setup()

	# Assert
	assert_int(camera.get_state()).is_equal(CameraInput.State.ACTIVE)


func test_setup_called_twice_with_game_world_wired_does_not_double_connect() -> void:
	# Arrange — [method CameraInput._connect_transition_signals]'s
	# is_connected() guard must make a repeated setup() call idempotent.
	var world: GameWorld = auto_free(GameWorld.new())
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.game_world = world
	camera.setup()
	camera.setup()
	var initial_yaw: float = camera.get_yaw()

	# Act
	world.begin_transition()

	# Assert — reaching this line without a duplicate-connection error proves
	# idempotence; the state change itself still happened exactly once.
	assert_int(camera.get_state()).is_equal(CameraInput.State.SUSPENDED)
	assert_float(camera.get_yaw()).is_equal_approx(initial_yaw, 0.0001)
