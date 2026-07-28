## Unit test — Camera & Input story cam-006 (ADR-0004 primary: pure
## projection math, no physics API; ADR-0014 secondary: this system produces
## the ray consumed by the DDA pick).
##
## Proves:
## 1. AC12/AC-1 [TR-camera-input-029]: [method CameraInput.get_world_ray] is
##    computable once this node is inside a live [SceneTree] (a [Viewport] is
##    required to sample mouse position/size) with no availability branch --
##    proven structurally (no state-guard keyword gates the method body) and
##    functionally (returns a valid, finite, normalized-direction ray).
## 2. AC14/AC-2 [TR-camera-input-038]: origin and direction are sampled from
##    the SAME screen point in the SAME call -- proven structurally (the
##    [Viewport] mouse position is read into a single local exactly once per
##    call, never re-queried for direction separately).
## 3. AC21/AC-3 [TR-camera-input-050]: round-trip correctness -- a world-ray
##    intersected with the ground plane and re-projected to screen space
##    lands within 1px of the original screen point, both for the exact
##    screen-center case (hand-verifiable: the center ray points exactly at
##    `camera_target`, so the ground intersection is `camera_target` itself)
##    and an arbitrary off-center point (proving the pair of pure functions
##    are true algebraic inverses, not just correct at one special value).
##    Edge case: a ray parallel to the ground plane (and a ray pointing away
##    from it) resolves to `hit = false` without crashing.
## 4. AC-4 [TR-camera-input-036]: `camera_input.gd`'s source contains no
##    reference to Voxel World anywhere.
## 5. ADR-0004 pure-projection-math constraint: `camera_input.gd`'s source
##    contains no physics-API identifier anywhere (mirrors
##    `dda_raycast_test.gd`'s established banned-substrings grep guard for
##    Voxel World, applied here for the same reason -- picking must never
##    route through Godot physics in this system either).
## 6. Config-driven, not hardcoded: [CameraInputConfig.fov_degrees] is read
##    from config (a non-default value measurably changes the projection),
##    and out-of-range values clamp with a warning (ADR-0002 two-tier policy).
class_name MouseWorldRayTest
extends GdUnitTestSuite

const CAMERA_INPUT_SOURCE_PATH: String = "res://src/camera_input/camera_input.gd"

## A representative viewport size + camera pose used across the round-trip
## cases below -- arbitrary but fixed, so every test in this suite reasons
## about the same concrete numbers.
const VIEWPORT_SIZE := Vector2(1920.0, 1080.0)
const FOV_DEGREES: float = 75.0
const CAMERA_POSITION := Vector3(0.0, 10.0, 10.0)
const CAMERA_TARGET := Vector3(0.0, 0.0, 0.0)  # on the ground plane (y=0)


func _new_camera() -> CameraInput:
	var camera: CameraInput = auto_free(CameraInput.new())
	camera.config = CameraInputConfig.new()
	camera.setup()
	return camera


# ---------------------------------------------------------------------------
# AC12/AC-1 — always computable, no availability branch [TR-camera-input-029]
# ---------------------------------------------------------------------------

func test_get_world_ray_returns_a_valid_ray_once_in_scene_tree() -> void:
	# Arrange — a live SceneTree is required for get_viewport() to resolve
	# (mirrors inputmap_registration_test.gd's established
	# add_child(camera)-for-a-live-Viewport pattern).
	var camera: CameraInput = _new_camera()
	add_child(camera)

	# Act
	var ray: WorldRay = camera.get_world_ray()

	# Assert — a finite, normalized-direction ray, no error reaching this line.
	assert_float(ray.direction.length()).is_equal_approx(1.0, 0.001)
	assert_bool(is_nan(ray.origin.x) or is_nan(ray.origin.y) or is_nan(ray.origin.z)).is_false()
	assert_vector(ray.origin).is_equal_approx(camera.get_camera_position(), Vector3.ONE * 0.0001)


func test_get_world_ray_source_has_no_state_guard_branch() -> void:
	# Arrange
	var source: String = FileAccess.get_file_as_string(CAMERA_INPUT_SOURCE_PATH)
	var method_start: int = source.find("func get_world_ray()")
	var method_end: int = source.find("static func derive_ray_direction")
	var method_body: String = source.substr(method_start, method_end - method_start)

	# Act + Assert — no "is_set_up"/Suspended-style availability check inside
	# get_world_ray()'s own body; the only gates are wiring asserts (config,
	# viewport), which are unconditional across every state.
	assert_bool(method_body.contains("is_set_up")).is_false()
	assert_bool(method_body.contains("Suspended")).is_false()


# ---------------------------------------------------------------------------
# AC14/AC-2 — same screen point, same frame [TR-camera-input-038]
# ---------------------------------------------------------------------------

func test_get_world_ray_samples_mouse_position_exactly_once() -> void:
	# Arrange
	var source: String = FileAccess.get_file_as_string(CAMERA_INPUT_SOURCE_PATH)
	var method_start: int = source.find("func get_world_ray()")
	var method_end: int = source.find("static func derive_ray_direction")
	var method_body: String = source.substr(method_start, method_end - method_start)

	# Act — count occurrences of the Viewport mouse-position query.
	var occurrences: int = method_body.count("get_mouse_position()")

	# Assert — sampled into a single local exactly once; both origin and
	# direction are derived from that one sample, never re-queried.
	assert_int(occurrences).is_equal(1)


# ---------------------------------------------------------------------------
# AC21/AC-3 — round-trip projection correctness [TR-camera-input-050]
# ---------------------------------------------------------------------------

func test_screen_center_ray_hits_ground_exactly_at_camera_target() -> void:
	# Arrange — the screen-center ray points exactly along `forward`
	# (camera_target - camera_position), by construction: raw NDC (0,0) at
	# viewport center zeroes both offset terms. Since camera_target.y == 0
	# (on the ground plane), the ground intersection must be camera_target
	# itself -- a hand-verifiable exact case, not just a generic property.
	var screen_center: Vector2 = VIEWPORT_SIZE / 2.0

	# Act
	var direction: Vector3 = CameraInput.derive_ray_direction(
		CAMERA_POSITION, CAMERA_TARGET, FOV_DEGREES, VIEWPORT_SIZE, screen_center
	)
	var intersection: GroundPlaneIntersectionResult = CameraInput.derive_ground_plane_intersection(
		CAMERA_POSITION, direction
	)

	# Assert
	assert_bool(intersection.hit).is_true()
	assert_vector(intersection.position).is_equal_approx(CAMERA_TARGET, Vector3.ONE * 0.001)


func test_round_trip_screen_center_reprojects_within_one_pixel() -> void:
	# Arrange — story's QA Test Case AC-3: mouse at P, ray ∩ ground, re-project
	# → within 1px of P.
	var screen_center: Vector2 = VIEWPORT_SIZE / 2.0
	var direction: Vector3 = CameraInput.derive_ray_direction(
		CAMERA_POSITION, CAMERA_TARGET, FOV_DEGREES, VIEWPORT_SIZE, screen_center
	)
	var intersection: GroundPlaneIntersectionResult = CameraInput.derive_ground_plane_intersection(
		CAMERA_POSITION, direction
	)
	assert_bool(intersection.hit).is_true()

	# Act
	var reprojected: Vector2 = CameraInput.derive_screen_position(
		intersection.position, CAMERA_POSITION, CAMERA_TARGET, FOV_DEGREES, VIEWPORT_SIZE
	)

	# Assert — within 1 pixel on both axes.
	assert_float(absf(reprojected.x - screen_center.x)).is_less_equal(1.0)
	assert_float(absf(reprojected.y - screen_center.y)).is_less_equal(1.0)


func test_round_trip_off_center_screen_point_reprojects_within_one_pixel() -> void:
	# Arrange — an arbitrary off-center screen point, proving the pair of
	# pure functions are true algebraic inverses generally, not just at the
	# screen-center special case.
	var screen_pos: Vector2 = VIEWPORT_SIZE / 2.0 + Vector2(133.0, -87.0)
	var direction: Vector3 = CameraInput.derive_ray_direction(
		CAMERA_POSITION, CAMERA_TARGET, FOV_DEGREES, VIEWPORT_SIZE, screen_pos
	)
	var intersection: GroundPlaneIntersectionResult = CameraInput.derive_ground_plane_intersection(
		CAMERA_POSITION, direction
	)
	assert_bool(intersection.hit).is_true()

	# Act
	var reprojected: Vector2 = CameraInput.derive_screen_position(
		intersection.position, CAMERA_POSITION, CAMERA_TARGET, FOV_DEGREES, VIEWPORT_SIZE
	)

	# Assert
	assert_float(absf(reprojected.x - screen_pos.x)).is_less_equal(1.0)
	assert_float(absf(reprojected.y - screen_pos.y)).is_less_equal(1.0)


func test_ray_parallel_to_ground_plane_yields_no_intersection_no_crash() -> void:
	# Arrange — story's QA Test Case AC-3 edge case: a horizontal ray
	# (direction.y == 0) never touches the ground plane.
	var horizontal_direction := Vector3(1.0, 0.0, 0.0)

	# Act
	var intersection: GroundPlaneIntersectionResult = CameraInput.derive_ground_plane_intersection(
		CAMERA_POSITION, horizontal_direction
	)

	# Assert — no crash reaching this line; explicit miss, not a bare null.
	assert_bool(intersection.hit).is_false()


func test_ray_pointing_away_from_ground_plane_yields_no_intersection_no_crash() -> void:
	# Arrange — a ray pointing straight up (skyward mouse position) intersects
	# the ground-plane MATH behind the ray's own origin (t < 0) -- must not be
	# reported as a hit.
	var skyward_direction := Vector3(0.0, 1.0, 0.0)

	# Act
	var intersection: GroundPlaneIntersectionResult = CameraInput.derive_ground_plane_intersection(
		CAMERA_POSITION, skyward_direction
	)

	# Assert
	assert_bool(intersection.hit).is_false()


# ---------------------------------------------------------------------------
# AC-4 [TR-camera-input-036] + ADR-0004 pure-projection-math constraint
# ---------------------------------------------------------------------------

func test_no_voxel_world_reference_anywhere_in_camera_input_source() -> void:
	# Grep-verifiable AC: Camera & Input only provides the ray, it never calls
	# Voxel World itself (Building System forwards the ray). Comment-stripped
	# for the same reason as [method test_no_physics_apis_anywhere_in_camera_
	# input_source] -- see [method _read_gd_source_without_comments].
	var source: String = _read_gd_source_without_comments(CAMERA_INPUT_SOURCE_PATH)

	assert_bool(source.contains("VoxelWorld")).is_false()


func test_no_physics_apis_anywhere_in_camera_input_source() -> void:
	# ADR-0004: the ray math must be pure projection math -- zero physics API
	# calls, mirroring dda_raycast_test.gd's established banned-substrings
	# grep guard for the same reason (block/villager picking are downstream
	# consumers' concern, never this producer's). Comment-stripped -- see
	# [method _read_gd_source_without_comments]: this class's own doc comment
	# legitimately NAMES these banned APIs to document that they are
	# forbidden (see camera_input.gd's cam-006 class doc comment), so a naive
	# raw-text scan would flag its own compliance documentation as a
	# violation.
	var source: String = _read_gd_source_without_comments(CAMERA_INPUT_SOURCE_PATH)

	var banned_substrings: Array[String] = [
		"intersect_ray",
		"PhysicsServer3D",
		"RayCast3D",
		"PhysicsDirectSpaceState3D",
		"PhysicsRayQueryParameters3D",
	]
	for banned: String in banned_substrings:
		assert_bool(source.contains(banned)).is_false()


# ---------------------------------------------------------------------------
# Config-driven, not hardcoded
# ---------------------------------------------------------------------------

func test_ray_direction_uses_configured_fov_not_hardcoded() -> void:
	# Arrange — two distinct fov_degrees values through the same screen point;
	# a wider FOV must change the resolved direction (proving fov_degrees is
	# actually consumed, not a hardcoded literal in the formula).
	var off_center: Vector2 = VIEWPORT_SIZE / 2.0 + Vector2(200.0, 0.0)

	# Act
	var narrow_fov_direction: Vector3 = CameraInput.derive_ray_direction(
		CAMERA_POSITION, CAMERA_TARGET, 40.0, VIEWPORT_SIZE, off_center
	)
	var wide_fov_direction: Vector3 = CameraInput.derive_ray_direction(
		CAMERA_POSITION, CAMERA_TARGET, 100.0, VIEWPORT_SIZE, off_center
	)

	# Assert
	assert_vector(narrow_fov_direction).is_not_equal(wide_fov_direction)


func test_fov_degrees_out_of_range_clamps_with_warning() -> void:
	# Arrange — ADR-0002 two-tier policy: single-field range issue clamps and
	# proceeds, mirroring every other ranged knob's validate() test.
	var config := CameraInputConfig.new()
	config.fov_degrees = 250.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_float(config.fov_degrees).is_equal_approx(CameraInputConfig.FOV_DEGREES_MAX, 0.0001)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("fov_degrees"))).is_true()


func test_default_fov_degrees_matches_godots_own_camera3d_default() -> void:
	# Arrange + Act
	var config := CameraInputConfig.new()

	# Assert — 75.0, Godot's own Camera3D engine default (see camera_input_
	# config.gd's [assumption] doc comment on this knob).
	assert_float(config.fov_degrees).is_equal_approx(75.0, 0.0001)


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads a single `.gd` source file, STRIPPING full-line `#`/`##` doc-comment
## lines first. Mirrors `dda_raycast_test.gd`'s `_read_all_gd_source` helper
## (this codebase's established precedent for this exact pitfall) --
## `camera_input.gd`'s own cam-006 class doc comment legitimately NAMES the
## banned physics APIs to document that they are forbidden, so a naive
## raw-text scan would flag its own compliance documentation as a violation.
## Stripping comment lines means only actual CODE usage can trip the check.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined
