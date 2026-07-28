## Integration test — Camera & Input story cam-002 (ADR-0010 primary,
## ADR-0001 secondary; TR-camera-input-032/027/039).
##
## Proves:
## 1. AC-1 [TR-camera-input-032]: every entry in [constant CameraInput
##    .OWNED_ACTIONS] -- the union of actions any downstream GDD references
##    -- is registered in the InputMap at project scope (`project.godot`)
##    and queryable at boot without error.
## 2. AC-2 [TR-camera-input-027]: [signal CameraInput.action_fired]'s payload
##    is only the action-name string, and the SAME emitting code path
##    ([method CameraInput._unhandled_input]) handles a placement action
##    (`build_place`) and an unrelated camera action (`camera_rotate_left`)
##    identically -- proving there is no per-action special-casing. Also
##    proves "fired" means a press transition, not a release, and that an
##    event mapped to nothing this system owns emits nothing.
## 3. AC-3 [TR-camera-input-039]: the source never reads `event.device`
##    anywhere (a stronger, automatable form of the GDD's "no hardcoded
##    device id" grep check) — this doubles as an automated check for the
##    "no branch on the action name" half of AC-2, since both are phrased in
##    the story as code-review/grep checks; this suite makes them
##    regression-proof instead of manual-only.
##
## Note on event-delivery scope (accumulated pitfall — headless input
## testing): [method CameraInput._unhandled_input] is called DIRECTLY with a
## synthesized [InputEvent] in most cases below — deterministic, and proves
## the handler logic and the opaque-passthrough contract exactly.
## [method test_real_scene_tree_dispatch_delivers_build_place_via_input_map]
## additionally proves genuine engine-level dispatch
## (`Input.parse_input_event` + a live [SceneTree] node, per the accumulated
## pitfall's suggested verification path) for at least one action, so the
## real routing path is empirically covered, not just asserted by
## inspection.
class_name CameraInputInputmapRegistrationTest
extends GdUnitTestSuite

const CAMERA_INPUT_SOURCE_PATH: String = "res://src/camera_input/camera_input.gd"


func _make_key_event(keycode: int, is_pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = is_pressed
	return event


func _make_mouse_event(button_index: int, is_pressed: bool = true) -> InputEventMouseButton:
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
# AC-1 — every downstream-referenced action registered [TR-camera-input-032]
# ---------------------------------------------------------------------------

func test_every_owned_action_is_registered_in_input_map() -> void:
	# Arrange + Act + Assert — queries every owned action; none may error or
	# be missing (AC18's "no consumer ever queries an unregistered action").
	for action_name: StringName in CameraInput.OWNED_ACTIONS:
		assert_bool(InputMap.has_action(action_name)).override_failure_message(
			"Missing InputMap action (project.godot out of sync with CameraInput.OWNED_ACTIONS): %s" % action_name
		).is_true()


func test_owned_actions_covers_every_action_name_downstream_gdds_reference() -> void:
	# Arrange — the explicit examples camera-input.md AC18 and building-ui.md
	# Rule 12 name by identifier (a representative, not exhaustive, sample —
	# full coverage is proven by the loop above against the SAME list this
	# asserts a sample of).
	var expected: Array[StringName] = [
		&"build_place", &"build_remove",
		&"camera_rotate_left", &"camera_rotate_right",
		&"tool_select_1", &"tool_select_2", &"tool_select_3",
		&"tool_select_4", &"tool_select_5",
		&"time_pause", &"time_speed_up", &"time_speed_down",
		&"toast_focus_cycle", &"toast_dismiss", &"toggle_issues",
		&"palette_next", &"palette_prev",
		&"formation_next", &"formation_prev",
		&"height_step_up", &"height_step_down",
		&"build_mode_toggle", &"slice_up", &"slice_down", &"slice_reset",
	]

	# Act + Assert
	for action_name: StringName in expected:
		assert_array(CameraInput.OWNED_ACTIONS).contains([action_name])


func test_setup_with_fully_registered_actions_does_not_raise() -> void:
	# Arrange + Act — setup()'s own boot-time guard (_assert_owned_actions_
	# registered) must pass silently against the real project.godot.
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()

	# Assert — no assertion error raised.
	camera.setup()
	assert_bool(camera.is_set_up()).is_true()


# ---------------------------------------------------------------------------
# AC-2 — opaque passthrough, no branch on action name [TR-camera-input-027]
# ---------------------------------------------------------------------------

func test_unhandled_input_emits_only_the_action_name_for_build_place() -> void:
	# Arrange
	var camera: CameraInput = _new_camera()
	var received: Array[StringName] = []
	camera.action_fired.connect(func(action_name: StringName) -> void: received.append(action_name))

	# Act — left mouse button, project.godot's build_place binding.
	camera._unhandled_input(_make_mouse_event(MOUSE_BUTTON_LEFT))

	# Assert
	assert_int(received.size()).is_equal(1)
	assert_str(received[0]).is_equal("build_place")


func test_unhandled_input_emits_camera_rotate_left_via_the_identical_code_path() -> void:
	# Arrange — proves the SAME method handles an unrelated, non-placement
	# action identically to build_place above (no per-action special-casing).
	var camera: CameraInput = _new_camera()
	var received: Array[StringName] = []
	camera.action_fired.connect(func(action_name: StringName) -> void: received.append(action_name))

	# Act — Q key, project.godot's camera_rotate_left binding.
	camera._unhandled_input(_make_key_event(KEY_Q))

	# Assert
	assert_int(received.size()).is_equal(1)
	assert_str(received[0]).is_equal("camera_rotate_left")


func test_unhandled_input_emits_build_mode_toggle_via_the_identical_code_path() -> void:
	# Arrange — a third, structurally different action (Slice-revision set)
	# through the same handler, reinforcing "uniform treatment, no branch."
	var camera: CameraInput = _new_camera()
	var received: Array[StringName] = []
	camera.action_fired.connect(func(action_name: StringName) -> void: received.append(action_name))

	# Act — B key, project.godot's build_mode_toggle binding.
	camera._unhandled_input(_make_key_event(KEY_B))

	# Assert
	assert_int(received.size()).is_equal(1)
	assert_str(received[0]).is_equal("build_mode_toggle")


func test_unhandled_input_with_event_mapped_to_no_owned_action_emits_nothing() -> void:
	# Arrange — F12 is bound to nothing this system owns.
	var camera: CameraInput = _new_camera()
	var received: Array[StringName] = []
	camera.action_fired.connect(func(action_name: StringName) -> void: received.append(action_name))

	# Act
	camera._unhandled_input(_make_key_event(KEY_F12))

	# Assert
	assert_array(received).is_empty()


func test_unhandled_input_release_event_does_not_emit_action_fired() -> void:
	# Arrange — "fired" means a press transition (is_action_pressed
	# semantics), never a release.
	var camera: CameraInput = _new_camera()
	var received: Array[StringName] = []
	camera.action_fired.connect(func(action_name: StringName) -> void: received.append(action_name))

	# Act
	camera._unhandled_input(_make_mouse_event(MOUSE_BUTTON_LEFT, false))

	# Assert
	assert_array(received).is_empty()


func test_unhandled_input_body_never_branches_on_action_identity() -> void:
	# Arrange — a source-level regression guard for the story's "verify by
	# code review + grep" instruction. Updated by story cam-007: the uniform
	# is_action_pressed check inside the filter() lambda still applies
	# identically to every action (not a per-action branch), and story
	# cam-007 additionally prepends exactly ONE early-return guard — a
	# Suspended STATE gate (`if _state == State.SUSPENDED: return`), which
	# governs WHETHER dispatch happens at all this call, never WHICH action
	# fired. The assertion below narrows from "no `if` at all" to "the
	# exactly-one permitted `if` is the Suspended-state guard, never a branch
	# that reads an action name/identity."
	var source: String = FileAccess.get_file_as_string(CAMERA_INPUT_SOURCE_PATH)
	var start: int = source.find("func _unhandled_input")
	var next_func: int = source.find("\nfunc ", start + 1)
	var body: String = source.substr(start, next_func - start) if next_func != -1 else source.substr(start)

	# Act + Assert -- indentation in this file is tabs, not spaces, so the
	# permitted-count check greps "if " (no leading-space assumption) rather
	# than " if " (cam-002's original space-indented assumption, stale now).
	assert_int(start).is_greater(-1)
	assert_bool(body.contains("match ")).is_false()
	assert_int(body.count("if ")).is_equal(1)
	assert_bool(body.contains("if _state == State.SUSPENDED")).is_true()
	assert_bool(body.contains("action_name ==")).is_false()
	assert_bool(body.contains("action_name.")).is_false()


# ---------------------------------------------------------------------------
# AC-3 — no device-identity branching, no hardcoded device id [TR-camera-input-039]
# ---------------------------------------------------------------------------

func test_source_never_reads_event_device_anywhere() -> void:
	# Arrange — the whole file, not just _unhandled_input: this system must
	# never branch on input device identity anywhere, not only in the
	# passthrough method.
	var source: String = FileAccess.get_file_as_string(CAMERA_INPUT_SOURCE_PATH)

	# Act + Assert
	assert_bool(source.contains(".device")).is_false()


# ---------------------------------------------------------------------------
# Real engine dispatch (empirical check for the accumulated headless-input
# pitfall) — proves genuine InputMap routing delivers at least one owned
# action through a live SceneTree, not just a direct method call.
# ---------------------------------------------------------------------------

func test_real_scene_tree_dispatch_delivers_build_place_via_input_map() -> void:
	# Arrange
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	add_child(camera)
	camera.setup()
	var received: Array[StringName] = []
	camera.action_fired.connect(func(action_name: StringName) -> void: received.append(action_name))

	# Act — genuine engine dispatch: parse_input_event feeds the same
	# pipeline a real mouse click would, routed via the registered
	# build_place InputMap action (project.godot).
	Input.parse_input_event(_make_mouse_event(MOUSE_BUTTON_LEFT))
	await get_tree().process_frame
	await get_tree().process_frame

	# Assert
	assert_array(received).contains([&"build_place"])
