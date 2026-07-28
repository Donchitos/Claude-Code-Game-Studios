## Unit test — Building System Story building-020 (DDA placement pick +
## surface-aware targeting + picked-block highlight). ADR-0004 primary
## (zero-physics manual DDA); ADR-0014 §4 secondary (`extra_solid`
## ghost-anchoring overlay); ADR-0010 secondary (drag-ownership input switch).
##
## Proves, all against [PlacementPick]:
## 1. AC8 [TR-building-system-043]: the locked working plane holds regardless
##    of where the ray subsequently points (including a location with nothing
##    built there, "off the original block's edge") — both the pure
##    [method PlacementPick.derive_drag_plane_hit] derivation and the
##    instance-level dispatch reached via a real Dragging transition.
## 2. Surface-aware attach/replace: a picked block resolves to the adjacent
##    face cell (attach, [method PlacementPick.derive_attach_cell]) or the
##    picked cell itself (replace, [method PlacementPick.get_replace_cell]);
##    a pick on terrain top attaches to its face (same formula, no special
##    case).
## 3. Zero physics in the pick path (BLOCKING grep, story + control-manifest):
##    `intersect_ray|PhysicsDirectSpaceState3D|RayCast3D` — zero matches
##    across every `.gd` file in `src/building_system/`.
## 4. Pick never mutates voxel state: `set_cell(`/`bulk_write(` never appear
##    in `placement_pick.gd`'s own source (this story's explicit non-goal —
##    building-021's commit pipeline is Nice/not committed this sprint per the
##    Sprint 5 QA plan; the pick MUST stay side-effect-free until it lands).
## 5. Edge case: a ray that misses all geometry (no valid pick) — no crash,
##    highlight clears; an Idle/Suspended tool state always resolves to an
##    explicit miss regardless of the underlying ray.
## 6. Ghost-anchored pick predicate boundary (ADR-0014 §4): a supplied
##    [param extra_solid] `Callable` marks an otherwise-empty cell as solid —
##    the additive overlay [method VoxelWorldGrid.raycast_cells] already
##    supports, forwarded unchanged (no second pick path added here).
## 7. ADR-0010 §3 drag-ownership input switch: a press with a valid pick
##    starts the drag (locks the plane, switches release-listening to
##    `_input()`); a release completes it back to ToolArmed; a press with NO
##    valid pick never starts a drag.
class_name DdaPlacementPickTest
extends GdUnitTestSuite

const BUILDING_SYSTEM_DIR: String = "res://src/building_system/"
const PLACEMENT_PICK_SOURCE_PATH: String = "res://src/building_system/placement_pick.gd"


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

func _new_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	grid.setup()
	return grid


func _new_grid_with_solid_cell(cell: Vector3i) -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = _new_grid()
	grid.set_cell(cell, CellContents.new(1, 0))
	return grid


func _new_machine_armed() -> ToolStateMachine:
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())
	machine.arm_tool(&"wall")
	return machine


## Wires a [PlacementPick] against [param grid]/[param machine], with a
## bare, never-`setup()`'d [CameraInput] placeholder (satisfies the
## wiring assert; every test here drives geometry via [method
## PlacementPick.resolve_pick]'s explicit-ray parameter, never
## [method PlacementPick.update_pick]'s camera-driven path, except the
## dedicated input-dispatch section below).
func _new_pick(grid: VoxelWorldGrid, machine: ToolStateMachine) -> PlacementPick:
	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = auto_free(CameraInput.new())
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	return pick


## A [CameraInput] test double whose [method get_world_ray] returns a fixed,
## test-controlled ray rather than deriving one from real camera/viewport
## state (Story building-023 regression test) -- lets a real press-then-move
## Dragging sequence be driven with two precisely known rays without the
## heavier SubViewport + camera-rotation rigging this file's own
## `test_press_with_valid_pick_starts_drag_then_release_completes_it` uses
## (that test only needs a same-position click; this one needs a genuinely
## DIFFERENT second ray).
class _FixedRayCamera:
	extends CameraInput
	var ray: WorldRay = WorldRay.new(Vector3.ZERO, Vector3.DOWN)
	func get_world_ray() -> WorldRay:
		return ray


## Reads a single `.gd` source file, stripping full-line `#`/`##` doc-comment
## lines first — mirrors this codebase's established
## `_read_gd_source_without_comments` precedent (`mouse_world_ray_test.gd`,
## `dda_raycast_test.gd`) so a file's own doc comments (which legitimately
## NAME banned APIs to document their absence) are never mistaken for a
## violation.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


# ---------------------------------------------------------------------------
# AC8 — locked working plane [TR-building-system-043]
# ---------------------------------------------------------------------------

func test_derive_drag_plane_hit_locks_y_regardless_of_xz_drift() -> void:
	# Arrange — two rays straight down at very different XZ locations, one of
	# them ("off the block's edge") over a location with nothing built there.
	var locked_y := 3

	# Act
	var near: RaycastHitResult = PlacementPick.derive_drag_plane_hit(
		Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0), locked_y
	)
	var far_off_edge: RaycastHitResult = PlacementPick.derive_drag_plane_hit(
		Vector3(50.5, 20.0, 50.5), Vector3(0.0, -1.0, 0.0), locked_y
	)

	# Assert — both resolve on the SAME locked plane; XZ differs freely.
	assert_bool(near.hit).is_true()
	assert_bool(far_off_edge.hit).is_true()
	assert_int(near.cell.y).is_equal(locked_y)
	assert_int(far_off_edge.cell.y).is_equal(locked_y)
	assert_bool(near.cell.x == far_off_edge.cell.x).is_false()


func test_derive_drag_plane_hit_normal_always_faces_up() -> void:
	# Arrange + Act — the locked plane always represents the upward-facing
	# working surface a drag builds ON, never a re-derived block face.
	var result: RaycastHitResult = PlacementPick.derive_drag_plane_hit(
		Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0), 3
	)

	# Assert
	assert_bool(result.normal == Vector3i(0, 1, 0)).is_true()


func test_derive_drag_plane_hit_ray_parallel_to_plane_is_a_miss() -> void:
	# Arrange — a horizontal ray never touches a horizontal locked plane.
	var horizontal := Vector3(1.0, 0.0, 0.0)

	# Act
	var result: RaycastHitResult = PlacementPick.derive_drag_plane_hit(
		Vector3(5.5, 3.5, 5.5), horizontal, 3
	)

	# Assert — explicit miss, no crash.
	assert_bool(result.hit).is_false()


func test_dragging_state_dispatches_through_the_locked_plane_not_a_fresh_raycast() -> void:
	# Arrange — a block at (5,3,5); the hover pick (ToolArmed) attaches above
	# it at y=4. Locking the plane at that attach height, then dragging the
	# ray toward a completely different, unbuilt XZ location must still
	# resolve on y=4 — proving the DRAGGING dispatch branch, not just the
	# pure formula in isolation.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	assert_int(pick.get_attach_cell().y).is_equal(4)
	# Simulate the locked-plane state a valid press would have set (this
	# story's own input handlers set these two fields together — see
	# `_unhandled_input`); reached here directly since exercising the full
	# input dispatch is covered separately below with its own geometry rig.
	pick._locked_plane_cell_y = pick.get_attach_cell().y
	pick._has_locked_plane = true
	machine.start_drag()

	# Act — a ray at a far-away, never-built XZ location.
	var result: RaycastHitResult = pick.resolve_pick(Vector3(80.5, 20.0, 80.5), Vector3(0.0, -1.0, 0.0))

	# Assert
	assert_bool(result.hit).is_true()
	assert_int(result.cell.y).is_equal(4)


# ---------------------------------------------------------------------------
# Surface-aware attach/replace targeting [TR-building-system-043]
# ---------------------------------------------------------------------------

func test_hover_pick_on_a_block_top_attaches_to_its_face() -> void:
	# Arrange — a solid cell at (5,3,5); a straight-down ray hits its top
	# face (normal (0,1,0)).
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)

	# Act
	var result: RaycastHitResult = pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	# Assert — attach target is the empty cell directly above the hit block;
	# a pick on a flat top surface (terrain or block, this layer draws no
	# distinction) attaches to its face the same way.
	assert_bool(result.hit).is_true()
	assert_bool(result.cell == Vector3i(5, 3, 5)).is_true()
	assert_bool(result.normal == Vector3i(0, 1, 0)).is_true()
	assert_bool(pick.get_attach_cell() == Vector3i(5, 4, 5)).is_true()


func test_replace_target_is_the_picked_cell_itself() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	# Act + Assert — removal targets the hit cell, never an offset.
	assert_bool(pick.get_replace_cell() == Vector3i(5, 3, 5)).is_true()


func test_derive_attach_cell_offsets_by_the_entry_face_normal() -> void:
	# Arrange + Act + Assert — pure formula, arbitrary values, no instance.
	assert_bool(PlacementPick.derive_attach_cell(Vector3i(2, 4, 6), Vector3i(-1, 0, 0)) == Vector3i(1, 4, 6)).is_true()
	assert_bool(PlacementPick.derive_attach_cell(Vector3i(2, 4, 6), Vector3i(0, 0, 1)) == Vector3i(2, 4, 7)).is_true()


# ---------------------------------------------------------------------------
# Ghost-anchored pick predicate (ADR-0014 §4) — additive overlay, no second
# pick path
# ---------------------------------------------------------------------------

func test_extra_solid_predicate_marks_an_empty_cell_as_solid() -> void:
	# Arrange — an entirely EMPTY grid; the predicate alone makes (5,3,5)
	# pick as solid, simulating a Planned blueprint cell (no real Building
	# System project data exists in this codebase yet to wire a concrete
	# predicate against — this proves the pass-through hook itself).
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.set_extra_solid(func(cell: Vector3i) -> bool: return cell == Vector3i(5, 3, 5))

	# Act
	var result: RaycastHitResult = pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	# Assert
	assert_bool(result.hit).is_true()
	assert_bool(result.cell == Vector3i(5, 3, 5)).is_true()


func test_no_extra_solid_predicate_behaves_as_a_plain_raycast() -> void:
	# Arrange — default `Callable()`, never set — identical behavior to
	# every other test that never calls [method PlacementPick.set_extra_solid].
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)

	# Act
	var result: RaycastHitResult = pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	# Assert
	assert_bool(result.hit).is_false()


# ---------------------------------------------------------------------------
# Edge cases — no valid pick, Idle/Suspended always miss, highlight clears
# ---------------------------------------------------------------------------

func test_ray_missing_all_geometry_is_a_miss_no_crash_highlight_clears() -> void:
	# Arrange — an empty grid, no predicate.
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)

	# Act — reaching this line without a crash IS part of the proof.
	var result: RaycastHitResult = pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	# Assert
	assert_bool(result.hit).is_false()
	assert_bool(pick.is_highlight_visible()).is_false()


func test_idle_state_always_resolves_to_a_miss_regardless_of_the_ray() -> void:
	# Arrange — a solid block directly under a hit-guaranteed ray, but no
	# tool armed (Idle) -- camera-only mode, nothing to pick.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = auto_free(ToolStateMachine.new())  # stays Idle
	var pick: PlacementPick = _new_pick(grid, machine)

	# Act
	var result: RaycastHitResult = pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))

	# Assert
	assert_bool(result.hit).is_false()
	assert_bool(pick.is_highlight_visible()).is_false()


func test_highlight_visible_while_armed_with_a_hit_and_clears_on_cancel() -> void:
	# Arrange
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = _new_pick(grid, machine)
	pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	assert_bool(pick.is_highlight_visible()).is_true()
	assert_vector(pick.get_highlight_world_position()).is_equal_approx(
		VoxelWorldGrid.cell_to_world(Vector3i(5, 3, 5)), Vector3.ONE * 0.0001
	)

	# Act — cancel returns to Idle; the highlight must clear IMMEDIATELY
	# (via the state_changed reaction), not wait for a later pick call.
	machine.cancel()

	# Assert
	assert_bool(pick.is_highlight_visible()).is_false()


# ---------------------------------------------------------------------------
# ADR-0010 §3 drag-ownership input switch
# ---------------------------------------------------------------------------

func test_press_with_valid_pick_starts_drag_then_release_completes_it() -> void:
	# Arrange — a wired PlacementPick with a REAL CameraInput inside a fixed-
	# size SubViewport (deterministic aspect + a (0,0) default mouse
	# position, since no motion event has fired yet). Yaw is rotated to
	# exactly PI via the existing middle-mouse-drag rotation path (an exact,
	# reproducible value derived analytically so the mouse-(0,0) corner ray
	# lands solidly inside a generous positive-quadrant slab regardless of
	# the small floating-point slack in that derivation) [TR-camera-input-022].
	var grid: VoxelWorldGrid = _new_grid()
	var config := VoxelWorldConfig.new()
	config.world_width_cells = 100
	config.world_depth_cells = 100
	grid.config = config
	grid.setup()
	var changes: Dictionary[Vector3i, CellContents] = {}
	for x in 100:
		for z in 100:
			changes[Vector3i(x, 0, z)] = CellContents.new(1, 0)
	grid.bulk_write(changes)

	var machine: ToolStateMachine = _new_machine_armed()

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1000, 1000)
	add_child(viewport)
	auto_free(viewport)

	var camera: CameraInput = CameraInput.new()
	var camera_config := CameraInputConfig.new()
	camera.config = camera_config
	camera.setup()
	viewport.add_child(camera)
	var yaw_delta: float = PI - camera_config.start_yaw
	var rotate_event := InputEventMouseMotion.new()
	rotate_event.relative = Vector2(yaw_delta / camera_config.mouse_drag_sensitivity, 0.0)
	rotate_event.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	camera._unhandled_input(rotate_event)

	var pick: PlacementPick = PlacementPick.new()
	pick.camera_input = camera
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	viewport.add_child(pick)  # a live Viewport is required so `_input`'s
	# `get_viewport().set_input_as_handled()` resolves non-null.

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true

	# Act — press.
	pick._unhandled_input(press)

	# Assert — the drag started (a valid pick was found on the slab).
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.DRAGGING)

	# Act — release.
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	pick._input(release)

	# Assert — the SM transition completed back to ToolArmed with the same
	# tool still armed (Story building-019's own established contract); the
	# actual commit is Story 021's separate, not-yet-built concern.
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)
	assert_str(String(machine.get_armed_tool())).is_equal("wall")


func test_input_release_cell_matches_locked_plane_after_a_mid_drag_cursor_move() -> void:
	# Regression (Story building-023 discovery): `_input()`'s emitted
	# `release_cell` must read the locked-plane pick's cell DIRECTLY, never
	# through `get_attach_cell()` — that method's `+normal` offset is only
	# correct for a FRESH raycast hit (a genuine solid block needing the
	# adjacent-empty-cell offset), and double-counts it against
	# `derive_drag_plane_hit`'s already-surface-level cell (fixed `(0,1,0)`
	# normal convention, not a real face normal — see that method's own doc
	# comment). This ONLY manifests once at least one pick update happens
	# WHILE Dragging, after the press (a same-frame click, as in this file's
	# own `test_press_with_valid_pick_starts_drag_then_release_completes_it`,
	# never advances `_current_pick` past the press-time fresh-raycast value
	# before release runs, so it could never have caught this) — reproduced
	# here via a fixed-ray test double so the mid-drag cursor move is
	# deterministic.
	var grid: VoxelWorldGrid = _new_grid_with_solid_cell(Vector3i(5, 3, 5))
	var machine: ToolStateMachine = _new_machine_armed()
	var camera := _FixedRayCamera.new()
	camera.ray = WorldRay.new(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = auto_free(camera)
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()
	# A live Viewport is required — `_input()`'s release handler calls
	# `get_viewport().set_input_as_handled()` (mirrors this file's own
	# `test_press_with_valid_pick_starts_drag_then_release_completes_it`
	# rigging).
	var viewport := SubViewport.new()
	add_child(viewport)
	auto_free(viewport)
	viewport.add_child(pick)

	var received: Array = []
	pick.build_committed.connect(func(is_drag: bool, press_cell: Vector3i, release_cell: Vector3i) -> void:
		received.append([is_drag, press_cell, release_cell])
	)

	# Act — press at (5,4,5)'s attach height (4), locking the plane.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	pick._unhandled_input(press)
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.DRAGGING)

	# Act — cursor moves to a DIFFERENT XZ location while still Dragging, via
	# a real per-frame `_process()` tick (exactly what a live drag does every
	# engine frame — the shape no pre-existing test in this file exercised).
	camera.ray = WorldRay.new(Vector3(20.5, 20.0, 20.5), Vector3(0.0, -1.0, 0.0))
	pick._process(0.0)

	# Act — release.
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	pick._input(release)

	# Assert — the locked plane holds at y=4 (the press's attach height)
	# regardless of the moved XZ location; the pre-fix bug returned y=5.
	assert_int(received.size()).is_equal(1)
	var emitted: Array = received[0]
	var release_cell: Vector3i = emitted[2]
	assert_vector(release_cell).is_equal(Vector3i(20, 4, 20))


func test_press_with_no_valid_pick_does_not_start_a_drag() -> void:
	# Arrange — an entirely empty grid: no matter where the ray points, it
	# can never hit anything, so this test needs no camera-geometry rigging
	# at all to guarantee a miss.
	var grid: VoxelWorldGrid = _new_grid()
	var machine: ToolStateMachine = _new_machine_armed()
	var pick: PlacementPick = auto_free(PlacementPick.new())
	pick.camera_input = auto_free(CameraInput.new())
	pick.camera_input.config = CameraInputConfig.new()
	pick.camera_input.setup()
	add_child(pick.camera_input)
	pick.voxel_world = grid
	pick.tool_state_machine = machine
	pick.config = PlacementPickConfig.new()
	pick.setup()

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true

	# Act
	pick._unhandled_input(press)

	# Assert — still ToolArmed, never entered Dragging.
	assert_int(machine.get_state()).is_equal(ToolStateMachine.State.TOOL_ARMED)


# ---------------------------------------------------------------------------
# Zero physics + read-only pick path (BLOCKING grep, story + control-manifest)
# ---------------------------------------------------------------------------

func test_no_physics_apis_anywhere_in_building_system_source() -> void:
	# Grep-verifiable AC: `rg --glob "*.gd" "intersect_ray|PhysicsDirectSpaceState3D|
	# RayCast3D" src/building_system/` → zero matches. Comment-stripped (this
	# file's own doc comments legitimately NAME the banned APIs to document
	# their absence — see class doc comment item 3).
	var banned_substrings: Array[String] = [
		"intersect_ray",
		"PhysicsServer3D",
		"RayCast3D",
		"PhysicsDirectSpaceState3D",
		"PhysicsRayQueryParameters3D",
	]
	var dir := DirAccess.open(BUILDING_SYSTEM_DIR)
	assert_object(dir).is_not_null()
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var checked_at_least_one_file: bool = false
	while file_name != "":
		if file_name.ends_with(".gd"):
			checked_at_least_one_file = true
			var source: String = _read_gd_source_without_comments(BUILDING_SYSTEM_DIR + file_name)
			for banned: String in banned_substrings:
				assert_bool(source.contains(banned)).is_false()
		file_name = dir.get_next()
	dir.list_dir_end()
	assert_bool(checked_at_least_one_file).is_true()


func test_pick_path_never_calls_a_voxel_world_write_api() -> void:
	# The pick MUST stay side-effect-free until Story 021 lands (Sprint 5 QA
	# plan's own explicit non-goal for this story).
	var source: String = _read_gd_source_without_comments(PLACEMENT_PICK_SOURCE_PATH)

	assert_bool(source.contains("set_cell(")).is_false()
	assert_bool(source.contains("bulk_write(")).is_false()
	assert_bool(source.contains("clear_cell(")).is_false()


# ---------------------------------------------------------------------------
# Config (ADR-0002 two-tier policy)
# ---------------------------------------------------------------------------

func test_max_pick_distance_out_of_range_clamps_with_warning() -> void:
	# Arrange
	var config := PlacementPickConfig.new()
	config.max_pick_distance = -5.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_float(config.max_pick_distance).is_equal_approx(
		PlacementPickConfig.MAX_PICK_DISTANCE_MIN, 0.0001
	)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("max_pick_distance"))).is_true()
