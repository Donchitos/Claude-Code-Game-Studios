## Unit test -- Building System Story building-023 (Ghost preview rendering +
## drag re-rasterization + degradation + state tint). ADR-0014 primary
## (pooled MeshInstance3D + material_override tint, never per-instance
## custom-data plumbing); ADR-0010 secondary (the preview updates on the
## raw-input path).
##
## Proves:
## 1. AC1/AC3 [TR-building-system-026]/[TR-building-system-042]: the live
##    preview is hidden at Idle/Suspended, visible while a valid pick exists
##    during ToolArmed/Dragging, and shows IMMEDIATELY on a visibility
##    transition without waiting for a further pick change.
## 2. TR-003: the preview re-rasterizes as the cursor moves (a
##    [signal PlacementPick.pick_changed] event), never frozen at drag start.
## 3. TR-093: valid = State Blue tint, invalid = State Orange tint (never
##    red-green).
## 4. AC50 [TR-building-system-035]/[TR-building-system-039]: above
##    `preview_degradation_threshold` cells the preview degrades to a single
##    outline; at or below it, per-cell ghosts render.
## 5. AC2: re-arming a DIFFERENT tool while already ToolArmed (no
##    `ghost_visibility_changed` re-fire) still recomputes the preview.
## 6. TR-069: PERSISTENT blueprint-cell ghosts (Planned vs UnderConstruction)
##    read distinctly via two alpha tiers, and are pruned once Built.
## 7. [GhostPreviewConfig]'s two-tier clamp+warn (+BLOCKING) `validate()`
##    policy.
## 8. Grep-guards: this class never calls a [VoxelWorldGrid] write API, never
##    touches a physics API, and never uses per-instance custom-data
##    plumbing for ghost tint (ADR-0014 Forbidden).
class_name GhostPreviewTest
extends GdUnitTestSuite

const GHOST_PREVIEW_SOURCE_PATH: String = "res://src/building_system/ghost_preview.gd"


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Bundles every collaborator a live [GhostPreview] scenario needs, mirroring
## `wall_tool_test.gd`'s established "build the whole pipeline inline" shape,
## factored into one reusable harness since this suite needs it repeatedly.
class _Harness:
	var grid: VoxelWorldGrid
	var machine: ToolStateMachine
	var pick: PlacementPick
	var pipeline: CommitPipeline
	var preview: GhostPreview


func _new_harness() -> _Harness:
	var h := _Harness.new()

	h.grid = auto_free(VoxelWorldGrid.new())
	h.grid.config = VoxelWorldConfig.new()
	h.grid.setup()
	h.grid.set_cell(Vector3i(5, 3, 5), CellContents.new(1, 0))

	h.machine = auto_free(ToolStateMachine.new())

	h.pick = auto_free(PlacementPick.new())
	h.pick.camera_input = auto_free(CameraInput.new())
	h.pick.voxel_world = h.grid
	h.pick.tool_state_machine = h.machine
	h.pick.config = PlacementPickConfig.new()
	h.pick.setup()

	h.pipeline = auto_free(CommitPipeline.new())
	h.pipeline.placement_pick = h.pick
	h.pipeline.voxel_world = h.grid
	h.pipeline.config = CommitPipelineConfig.new()
	h.pipeline.setup()
	h.pipeline.set_selected_item(&"placeholder_material")

	h.preview = auto_free(GhostPreview.new())
	h.preview.tool_state_machine = h.machine
	h.preview.placement_pick = h.pick
	h.preview.commit_pipeline = h.pipeline
	h.preview.config = GhostPreviewConfig.new()
	h.preview.setup()

	return h


## Resolves a pick straight down onto the harness's one solid cell
## (`Vector3i(5, 3, 5)`) -- the attach cell resolves to `Vector3i(5, 4, 5)`.
func _resolve_valid_pick(h: _Harness) -> void:
	h.pick.resolve_pick(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))


## A [CameraInput] test double whose [method get_world_ray] returns a fixed,
## test-controlled ray rather than deriving one from real camera/viewport
## state -- lets a real press-then-move Dragging sequence
## ([method PlacementPick._unhandled_input] + [method PlacementPick._process])
## be driven with two precisely known rays, without the heavier SubViewport +
## camera-rotation rigging `dda_placement_pick_test.gd`'s own drag test uses
## (this test only needs TWO deterministic screen points, not a mouse-driven
## one).
class _FixedRayCamera:
	extends CameraInput
	var ray: WorldRay = WorldRay.new(Vector3.ZERO, Vector3.DOWN)
	func get_world_ray() -> WorldRay:
		return ray


## Mirrors `wall_tool_test.gd`'s established comment-stripped source read, so
## a file's own doc comments (which legitimately NAME banned APIs to document
## their absence) are never mistaken for a violation.
func _read_gd_source_without_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined


# ---------------------------------------------------------------------------
# AC1/AC3 -- visibility gated by ToolStateMachine state
# ---------------------------------------------------------------------------

func test_hidden_at_idle() -> void:
	var h := _new_harness()

	assert_bool(h.preview.is_live_preview_visible()).is_false()


func test_hidden_while_armed_with_no_valid_pick_yet() -> void:
	var h := _new_harness()

	h.machine.arm_tool(&"block")

	assert_bool(h.preview.is_live_preview_visible()).is_false()


func test_visible_once_a_valid_pick_resolves_while_armed() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"block")

	_resolve_valid_pick(h)

	assert_bool(h.preview.is_live_preview_visible()).is_true()


func test_hidden_on_cancel() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"block")
	_resolve_valid_pick(h)
	assert_bool(h.preview.is_live_preview_visible()).is_true()

	h.machine.cancel()

	assert_bool(h.preview.is_live_preview_visible()).is_false()


func test_hidden_on_suspended() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"block")
	_resolve_valid_pick(h)
	assert_bool(h.preview.is_live_preview_visible()).is_true()

	h.machine.enter_suspended()

	assert_bool(h.preview.is_live_preview_visible()).is_false()


func test_shows_immediately_on_rearm_without_a_new_pick_changed_event() -> void:
	# AC1: "a ghost preview follows the pick each frame" -- a re-arm that does
	# NOT change the underlying pick (no new PlacementPick.pick_changed event)
	# must still show the preview the SAME frame ghost_visibility_changed
	# fires, not wait for an incidental future pick change.
	var h := _new_harness()
	h.machine.arm_tool(&"block")
	_resolve_valid_pick(h)
	assert_bool(h.preview.is_live_preview_visible()).is_true()

	h.machine.cancel()
	assert_bool(h.preview.is_live_preview_visible()).is_false()

	h.machine.arm_tool(&"block")

	assert_bool(h.preview.is_live_preview_visible()).is_true()


# ---------------------------------------------------------------------------
# TR-003 -- re-rasterizes as the cursor moves
# ---------------------------------------------------------------------------

func test_recomputes_cells_when_pick_changes_during_hover() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"block")
	_resolve_valid_pick(h)
	var first_cells: Array[Vector3i] = h.preview.get_live_preview_cells()
	assert_array(first_cells).is_equal([Vector3i(5, 4, 5)])

	# Add a second solid cell and pick it instead -- the preview must move
	# WITH the cursor, never stay frozen on the first resolved cell.
	h.grid.set_cell(Vector3i(7, 3, 7), CellContents.new(1, 0))
	h.pick.resolve_pick(Vector3(7.5, 20.0, 7.5), Vector3(0.0, -1.0, 0.0))

	assert_array(h.preview.get_live_preview_cells()).is_equal([Vector3i(7, 4, 7)])


func test_dragging_uses_frozen_press_cell_and_live_release_cell() -> void:
	var h := _new_harness()
	var fake_camera := _FixedRayCamera.new()
	fake_camera.ray = WorldRay.new(Vector3(5.5, 20.0, 5.5), Vector3(0.0, -1.0, 0.0))
	h.pick.camera_input = auto_free(fake_camera)
	h.machine.arm_tool(&"wall")

	# Register a resolver that mirrors the pick's press/release directly, so
	# this test can assert on exactly which two cells GhostPreview supplied.
	var seen: Array = []
	h.pipeline.set_cell_set_resolver(func(is_drag: bool, press_cell: Vector3i, release_cell: Vector3i) -> Array[Vector3i]:
		seen.append([is_drag, press_cell, release_cell])
		return [press_cell, release_cell]
	)

	# Real press via PlacementPick's own `_unhandled_input` (mirrors
	# `dda_placement_pick_test.gd`'s established direct-input-event
	# precedent) -- this is what actually locks the plane, records
	# `_press_cell`, and transitions the machine into Dragging; calling
	# `ToolStateMachine.start_drag()` directly would skip all of that.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	h.pick._unhandled_input(press)
	assert_int(h.machine.get_state()).is_equal(ToolStateMachine.State.DRAGGING)
	assert_array(h.preview.get_live_preview_cells()).is_equal([Vector3i(5, 4, 5), Vector3i(5, 4, 5)])

	# Cursor moves to a DIFFERENT screen point while still Dragging -- the
	# locked-plane pick (Core Rule 3/AC8) resolves purely geometrically at
	# the SAME locked height (4), never touching VoxelWorldGrid; the release
	# half must track this live cursor while the press half stays frozen at
	# the original (5,4,5). `_process` is called directly (this codebase's
	# established engine-callback-invoked-directly test convention) since no
	# live SceneTree frame loop is running in this headless suite.
	fake_camera.ray = WorldRay.new(Vector3(7.5, 20.0, 7.5), Vector3(0.0, -1.0, 0.0))
	h.pick._process(0.0)
	assert_array(h.preview.get_live_preview_cells()).is_equal([Vector3i(5, 4, 5), Vector3i(7, 4, 7)])

	var last_call: Array = seen[seen.size() - 1]
	assert_bool(last_call[0]).is_true()  # is_drag always true while Dragging
	assert_vector(last_call[1]).is_equal(Vector3i(5, 4, 5))


# ---------------------------------------------------------------------------
# TR-093 -- colorblind-safe blue (valid) / orange (invalid) state axis
# ---------------------------------------------------------------------------

func test_valid_candidate_tints_state_blue() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"block")

	_resolve_valid_pick(h)

	var material: StandardMaterial3D = h.preview.get_live_preview_material()
	assert_bool(h.preview.is_live_preview_valid()).is_true()
	assert_that(material.albedo_color).is_equal(
		GhostPreview._with_alpha(GhostPreview.STATE_BLUE, GhostPreview.LIVE_PREVIEW_ALPHA)
	)


func test_invalid_candidate_tints_state_orange() -> void:
	var h := _new_harness()
	h.pipeline.set_selected_item(&"")  # AC42: nothing selected -> always rejected
	h.machine.arm_tool(&"block")

	_resolve_valid_pick(h)

	var material: StandardMaterial3D = h.preview.get_live_preview_material()
	assert_bool(h.preview.is_live_preview_valid()).is_false()
	assert_that(material.albedo_color).is_equal(
		GhostPreview._with_alpha(GhostPreview.STATE_ORANGE, GhostPreview.LIVE_PREVIEW_ALPHA)
	)


func test_state_blue_and_state_orange_are_never_red_or_green() -> void:
	# Colorblind-safe axis, never red-green (TR-093's explicit prohibition).
	assert_float(GhostPreview.STATE_BLUE.r).is_less(0.5)
	assert_float(GhostPreview.STATE_ORANGE.g).is_less(0.6)
	assert_bool(GhostPreview.STATE_BLUE.g < GhostPreview.STATE_BLUE.b).is_true()  # reads blue, not green


# ---------------------------------------------------------------------------
# AC50 -- degrades to an outline above preview_degradation_threshold
# ---------------------------------------------------------------------------

func test_stays_per_cell_at_exactly_the_threshold() -> void:
	var h := _new_harness()
	var threshold: int = h.preview.config.preview_degradation_threshold
	var big_cells: Array[Vector3i] = []
	for i: int in threshold:
		big_cells.append(Vector3i(i, 4, 0))
	h.pipeline.set_cell_set_resolver(func(_d: bool, _p: Vector3i, _r: Vector3i) -> Array[Vector3i]: return big_cells)
	h.machine.arm_tool(&"wall")

	_resolve_valid_pick(h)

	assert_bool(h.preview.is_live_preview_degraded()).is_false()
	assert_bool(h.preview.is_outline_visible()).is_false()
	assert_int(h.preview.get_visible_live_ghost_count()).is_equal(threshold)


func test_degrades_to_outline_above_the_threshold() -> void:
	var h := _new_harness()
	var threshold: int = h.preview.config.preview_degradation_threshold
	var big_cells: Array[Vector3i] = []
	for i: int in (threshold + 1):
		big_cells.append(Vector3i(i, 4, 0))
	h.pipeline.set_cell_set_resolver(func(_d: bool, _p: Vector3i, _r: Vector3i) -> Array[Vector3i]: return big_cells)
	h.machine.arm_tool(&"wall")

	_resolve_valid_pick(h)

	assert_bool(h.preview.is_live_preview_degraded()).is_true()
	assert_bool(h.preview.is_outline_visible()).is_true()
	assert_int(h.preview.get_visible_live_ghost_count()).is_equal(0)


func test_outline_never_lands_a_frame_budget_hitch_via_pool_growth() -> void:
	# The degraded path must not grow the per-cell pool at all -- protecting
	# the frame budget on a large drag is the entire point of AC50.
	var h := _new_harness()
	var big_cells: Array[Vector3i] = []
	for i: int in 300:
		big_cells.append(Vector3i(i, 4, 0))
	h.pipeline.set_cell_set_resolver(func(_d: bool, _p: Vector3i, _r: Vector3i) -> Array[Vector3i]: return big_cells)
	h.machine.arm_tool(&"wall")

	_resolve_valid_pick(h)

	assert_int(h.preview.get_visible_live_ghost_count()).is_equal(0)


func test_compute_bounds_pure_function() -> void:
	var bounds: Dictionary = GhostPreview.compute_bounds([
		Vector3i(2, 4, 2), Vector3i(5, 4, 2), Vector3i(2, 6, 8),
	])

	assert_vector(bounds["min"]).is_equal(Vector3i(2, 4, 2))
	assert_vector(bounds["max"]).is_equal(Vector3i(5, 6, 8))


func test_wireframe_unit_cube_mesh_has_12_edges_24_vertices() -> void:
	var mesh: ArrayMesh = GhostPreview._build_wireframe_unit_cube_mesh()

	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	assert_int(verts.size()).is_equal(24)


# ---------------------------------------------------------------------------
# AC2 -- re-arming a different tool recomputes even with no state change
# ---------------------------------------------------------------------------

func test_switching_armed_tool_recomputes_the_preview() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"wall")
	_resolve_valid_pick(h)
	# No resolver registered yet -- CommitPipeline's own placeholder default
	# (`_default_cell_set`) applies: a click (`is_drag=false`, the ToolArmed
	# hover path) always resolves to the single press cell alone.
	assert_array(h.preview.get_live_preview_cells()).is_equal([Vector3i(5, 4, 5)])

	# Register a distinct resolver representing "the newly-armed tool" and
	# re-arm WITHOUT changing state (TOOL_ARMED -> TOOL_ARMED) -- no
	# ghost_visibility_changed re-fire, so this only works if tool_armed
	# itself triggers a recompute.
	h.pipeline.set_cell_set_resolver(func(_d: bool, press_cell: Vector3i, _r: Vector3i) -> Array[Vector3i]:
		return [press_cell, press_cell + Vector3i(0, 1, 0)]
	)
	h.machine.arm_tool(&"floor")

	assert_array(h.preview.get_live_preview_cells()).is_equal([Vector3i(5, 4, 5), Vector3i(5, 5, 5)])


# ---------------------------------------------------------------------------
# TR-069 -- persistent Planned vs UnderConstruction ghost distinctness
# ---------------------------------------------------------------------------

func test_persistent_ghost_created_at_planned_alpha_on_commit() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"block")
	_resolve_valid_pick(h)
	var attach: Vector3i = h.pick.get_attach_cell()

	var created: Array[BlueprintCell] = h.pipeline.commit([attach])

	assert_int(created.size()).is_equal(1)
	assert_bool(h.preview.is_blueprint_ghost_visible(attach)).is_true()
	var material: StandardMaterial3D = h.preview.get_blueprint_ghost_material(attach)
	assert_float(material.albedo_color.a).is_equal_approx(h.preview.config.draft_ghost_alpha, 0.0001)


func test_persistent_ghost_switches_to_under_construction_alpha() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"block")
	_resolve_valid_pick(h)
	var attach: Vector3i = h.pick.get_attach_cell()
	var created: Array[BlueprintCell] = h.pipeline.commit([attach])

	created[0].state = BlueprintCell.MicroState.UNDER_CONSTRUCTION
	h.preview._refresh_blueprint_ghosts()

	var material: StandardMaterial3D = h.preview.get_blueprint_ghost_material(attach)
	assert_float(material.albedo_color.a).is_equal_approx(h.preview.config.queued_ghost_alpha, 0.0001)
	assert_bool(h.preview.config.queued_ghost_alpha > h.preview.config.draft_ghost_alpha).is_true()


func test_persistent_ghost_pruned_once_built() -> void:
	var h := _new_harness()
	h.machine.arm_tool(&"block")
	_resolve_valid_pick(h)
	var attach: Vector3i = h.pick.get_attach_cell()
	var created: Array[BlueprintCell] = h.pipeline.commit([attach])

	created[0].state = BlueprintCell.MicroState.BUILT
	h.preview._refresh_blueprint_ghosts()

	assert_bool(h.preview.get_blueprint_ghost_cells().has(attach)).is_false()
	assert_bool(h.preview.is_blueprint_ghost_visible(attach)).is_false()


# ---------------------------------------------------------------------------
# GhostPreviewConfig -- two-tier clamp+warn (+BLOCKING) validate() policy
# ---------------------------------------------------------------------------

func test_config_defaults() -> void:
	var config := GhostPreviewConfig.new()

	assert_int(config.preview_degradation_threshold).is_equal(128)
	assert_float(config.draft_ghost_alpha).is_equal_approx(0.5, 0.0001)
	assert_float(config.queued_ghost_alpha).is_equal_approx(0.7, 0.0001)
	assert_array(config.validate()).is_empty()


func test_config_clamps_threshold_out_of_range() -> void:
	var config := GhostPreviewConfig.new()
	config.preview_degradation_threshold = 5000

	var issues: Array[String] = config.validate()

	assert_int(config.preview_degradation_threshold).is_equal(GhostPreviewConfig.PREVIEW_DEGRADATION_THRESHOLD_MAX)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("preview_degradation_threshold"))).is_true()


func test_config_clamps_draft_ghost_alpha_out_of_range() -> void:
	var config := GhostPreviewConfig.new()
	config.draft_ghost_alpha = 0.05

	var issues: Array[String] = config.validate()

	assert_float(config.draft_ghost_alpha).is_equal_approx(GhostPreviewConfig.DRAFT_GHOST_ALPHA_MIN, 0.0001)
	assert_bool(issues.any(func(issue: String) -> bool: return issue.contains("draft_ghost_alpha"))).is_true()


func test_config_blocking_when_queued_alpha_not_greater_than_draft() -> void:
	var config := GhostPreviewConfig.new()
	config.draft_ghost_alpha = 0.6
	config.queued_ghost_alpha = 0.6

	var issues: Array[String] = config.validate()

	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_config_no_blocking_when_queued_greater_than_draft() -> void:
	var config := GhostPreviewConfig.new()

	var issues: Array[String] = config.validate()

	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()


# ---------------------------------------------------------------------------
# Grep-guards (ADR-0014 Forbidden patterns)
# ---------------------------------------------------------------------------

func test_ghost_preview_never_calls_a_voxel_world_write_api() -> void:
	var source: String = _read_gd_source_without_comments(GHOST_PREVIEW_SOURCE_PATH)

	assert_bool(source.contains("set_cell(")).is_false()
	assert_bool(source.contains("bulk_write(")).is_false()
	assert_bool(source.contains("clear_cell(")).is_false()


func test_ghost_preview_never_touches_a_physics_api() -> void:
	var source: String = _read_gd_source_without_comments(GHOST_PREVIEW_SOURCE_PATH)

	assert_bool(source.contains("intersect_ray")).is_false()
	assert_bool(source.contains("PhysicsDirectSpaceState3D")).is_false()
	assert_bool(source.contains("RayCast3D")).is_false()


func test_ghost_preview_never_uses_per_instance_custom_data_plumbing() -> void:
	# ADR-0014 Forbidden: "never per-instance custom-data plumbing for ghost
	# tint" -- this class must always assign a SHARED material_override, never
	# a MultiMesh INSTANCE_CUSTOM_DATA channel.
	var source: String = _read_gd_source_without_comments(GHOST_PREVIEW_SOURCE_PATH)

	assert_bool(source.contains("INSTANCE_CUSTOM_DATA")).is_false()
	assert_bool(source.contains("MultiMesh")).is_false()
