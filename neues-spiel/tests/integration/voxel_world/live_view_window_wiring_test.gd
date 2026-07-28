## Integration test -- Voxel World story vox-018 (live Valley view-window
## wiring + the milestone-criterion-#12 60-FPS-with-culling measurement
## unlock; ADR-0014 primary, ADR-0015 secondary; TR-voxel-world-025/026).
##
## BLOCKING half of this story's Test Evidence (per
## `production/qa/qa-plan-sprint-8-2026-07-25.md`'s Automated Tests Required
## section) -- proves the WIRING this story adds, against the REAL
## `GameWorld.tscn`/`Valley.tscn` boot chain (mirrors
## `gameworld_e2e_loop_test.gd`'s established real-scene precedent, not a
## hand-assembled stand-in, since the fact under test IS the scene-file
## wiring itself):
##
## 1. AC-1 (live wiring, TR-voxel-world-025): [VoxelWorldMeshStreamer] is a
##    hosted child of [Valley], cross-wired to the SAME [VoxelWorldGrid]/
##    [VoxelWorldMesher] instances Valley itself hosts; its own `setup()` is
##    reached ONLY via [GameWorld]'s injected-tier sweep (ADR-0005) --
##    [Valley]'s own source never calls it a second time.
## 2. Boot-timing edge case (AC-1, the specific regression this test must
##    catch per the QA plan): [method VoxelWorldMeshStreamer.build_initial_window]
##    runs synchronously during boot -- its result is already present the
##    INSTANT [method Node.add_child] returns, before a single
##    `await get_tree().process_frame` -- never deferred to a later, visible
##    frame.
## 3. AC-1 (live per-frame loop) + AC-2 (window-bounded draw calls,
##    TR-voxel-world-025): [Valley]'s own [method Valley._process] calls
##    [method VoxelWorldMeshStreamer.update_view_window] EVERY frame with the
##    CURRENT [CameraInput] focus (never a stale/initial one) -- moving the
##    camera's orbit target streams the window to follow it (entering chunks
##    build, the old window's chunks unload), and the tracked chunk count
##    (this test's headless draw-call proxy -- a real windowed FPS/draw-call
##    measurement is a SEPARATE Advisory tool run, `tools/vox018_...`, not
##    this file's job) stays far below the world's own ~15,625-chunk extent
##    and within the architectural 2000 ceiling throughout.
##
## Godot 4.7-stable engine risk note: no rendering API is exercised in this
## file (headless cannot render a viewport texture -- see class doc comment
## of `tools/vox018_60fps_culling_measurement.gd` for the real-GPU
## measurement); this suite only proves the DI/timing/tracking facts that
## ARE headless-testable.
class_name LiveViewWindowWiringTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


# ---------------------------------------------------------------------------
# Test helpers (kept ABOVE every test function)
# ---------------------------------------------------------------------------

## Boots a real [GameWorld]/[Valley] pair through the ADR-0005 gate (a
## Ready-immediately mock database) and returns the resulting [Valley].
## `auto_free`s the [GameWorld] root -- freeing it also frees the attached
## [Valley] and every hosted child, per Godot's own tree-ownership rules.
func _boot_valley() -> Valley:
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	return valley


## Repeatedly advances one real engine frame at a time (so [Valley]'s own
## [method Valley._process] actually runs, driven by the real per-frame
## budgets [VoxelWorldConfig.mesh_build_budget_ms]/`mesh_unload_budget_ms`
## default to) until [param mesher]'s tracked-chunk set exactly matches
## [param desired] (both entering-chunk builds AND leaving-chunk unloads
## fully settled), or [param max_frames] real frames have elapsed --
## mirrors `mesh_view_window_streaming_test.gd`'s own "settle" convergence
## loop, adapted to real awaited frames instead of direct budgeted calls
## (this file is proving the LIVE per-frame loop, not the streamer's own
## budgeting logic, which that suite already covers in isolation).
func _await_window_settled(mesher: VoxelWorldMesher, desired: Array[Vector2i], max_frames: int) -> void:
	var desired_set: Dictionary[Vector2i, bool] = {}
	for key: Vector2i in desired:
		desired_set[key] = true
	var frames: int = 0
	while frames < max_frames:
		var tracked: Array[Vector2i] = mesher.get_tracked_chunk_keys()
		if tracked.size() == desired.size():
			var matches: bool = true
			for key: Vector2i in tracked:
				if not desired_set.has(key):
					matches = false
					break
			if matches:
				return
		await get_tree().process_frame
		frames += 1


# ---------------------------------------------------------------------------
# AC-1 -- streamer hosted, cross-wired, setup() reached only via GameWorld
# ---------------------------------------------------------------------------

func test_streamer_is_hosted_child_wired_to_grid_and_mesher_and_setup_via_gameworld_only() -> void:
	# Act
	var valley: Valley = _boot_valley()

	# Assert -- hosted, non-null, cross-wired to the SAME sibling instances.
	var streamer: VoxelWorldMeshStreamer = valley.get_voxel_world_mesh_streamer()
	assert_object(streamer).is_not_null()
	assert_object(streamer.grid).is_same(valley.get_voxel_world())
	assert_object(streamer.mesher).is_same(valley.get_voxel_world_mesher())
	assert_object(streamer.get_parent()).is_same(valley)

	# Assert -- setup() was reached (ONLY GameWorld's injected-tier sweep can
	# have done this -- Valley itself never calls setup(), grep-proven by
	# test_valley_source_never_calls_setup_on_the_hosted_mesh_streamer below).
	assert_bool(streamer.is_set_up()).is_true()

	# Assert -- fed into GameWorld's own setup() sweep, positioned right after
	# the mesher it depends on (Valley.get_injected_tier_modules' documented
	# DI order).
	var modules: Array[Node] = valley.get_injected_tier_modules()
	var mesher_index: int = modules.find(valley.get_voxel_world_mesher())
	var streamer_index: int = modules.find(streamer)
	assert_int(streamer_index).is_equal(mesher_index + 1)


func test_valley_source_never_calls_setup_on_the_hosted_mesh_streamer() -> void:
	# Grep companion (ADR-0005: the sole setup() call site is
	# GameWorld._setup_injected_tier) -- mirrors
	# `world_root_valley_attach_test.gd`'s own established comment-stripped
	# source-scan precedent so this class's own doc comments (which
	# legitimately discuss `setup()`) are never mistaken for a violation.
	var text: String = FileAccess.get_file_as_string("res://src/scene_world_management/valley.gd")
	var code_only: String = ""
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			code_only += line
			code_only += "\n"
	assert_bool(code_only.contains("_voxel_world_mesh_streamer.setup(")).is_false()


# ---------------------------------------------------------------------------
# Boot-timing edge case -- build_initial_window() is synchronous, pre-frame
# ---------------------------------------------------------------------------

func test_build_initial_window_runs_synchronously_during_boot_before_any_process_frame() -> void:
	# Act -- no `await get_tree().process_frame` anywhere before this assert;
	# the regression this test must catch is build_initial_window() being
	# deferred to Valley's own first _process call (a visible frozen frame)
	# instead of GameWorld's own synchronous boot/WIRING sequence.
	var valley: Valley = _boot_valley()
	var mesher: VoxelWorldMesher = valley.get_voxel_world_mesher()

	# Story vox-021 (TD ruling Addendum D / D2): build_initial_window() is
	# threaded with config.boot_mesh_radius_chunks (the boot-scoped radius),
	# NEVER config.view_radius_chunks (get_desired_window_keys' own
	# steady-state radius, AC-STEADY-STATE-UNCHANGED -- deliberately not
	# reused here) -- so this test computes the expected boot window directly
	# from the boot radius instead of the previous vox-018-era shortcut of
	# comparing against get_desired_window_keys().
	#
	# Story scene-005 (World genesis in the boot sequence, AC-ONE-START-FOCUS)
	# changed the PRECONDITION this test was written against: world genesis
	# now calls CameraInput.set_target() with the config-derived world-CENTER
	# cell (VillagerRosterSpawner.world_center_cell) BEFORE this initial mesh
	# window ever builds -- CameraInput's former default Vector3.ZERO "world
	# corner" starting orbit target (this test's own former precondition, the
	# exact bug AC-ONE-START-FOCUS names and fixes) no longer holds by the
	# time build_initial_window runs. The window is therefore centered on that
	# interior cell, clear of every world edge at this radius, and survives
	# with NO lower-bound clipping -- a full (2*radius+1)^2 square. Updated
	# consciously, not incidentally, per scene-005's own dev-story instructions
	# to flag this file.
	var boot_radius: int = valley.get_voxel_world().config.boot_mesh_radius_chunks
	var focus_cell: Vector3i = VillagerRosterSpawner.world_center_cell(valley.get_voxel_world().config)
	var focus_chunk: Vector2i = valley.get_voxel_world().chunk_key_for_cell(focus_cell)
	var expected_keys: Array[Vector2i] = []
	for dz in range(-boot_radius, boot_radius + 1):
		for dx in range(-boot_radius, boot_radius + 1):
			expected_keys.append(Vector2i(focus_chunk.x + dx, focus_chunk.y + dz))

	assert_int(expected_keys.size()).is_greater(0)
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(expected_keys.size())
	for key: Vector2i in expected_keys:
		assert_bool(mesher.is_chunk_tracked(key)).is_true()


# ---------------------------------------------------------------------------
# AC-1 (live per-frame loop) + AC-2 (window-bounded, not world-size-bounded)
# ---------------------------------------------------------------------------

func test_valley_process_tracks_moving_camera_focus_and_stays_window_bounded() -> void:
	# Arrange -- boot, then confirm the initial window is live.
	#
	# Story scene-005 (World genesis in the boot sequence, AC-ONE-START-FOCUS)
	# changed the PRECONDITION this test was written against: world genesis
	# now calls CameraInput.set_target() with the config-derived world-CENTER
	# cell BEFORE the initial mesh window ever builds -- CameraInput's former
	# default Vector3.ZERO "world corner" starting orbit target (this test's
	# own former precondition, the exact bug AC-ONE-START-FOCUS names and
	# fixes) no longer holds. The initial window is therefore centered on that
	# interior cell, clear of every world edge at this radius -- NOT
	# world-edge-clipped. Story vox-021 (TD ruling Addendum D / D2): the boot
	# window is still sized by `config.boot_mesh_radius_chunks` (8), NOT
	# `config.view_radius_chunks` (12, get_desired_window_keys' own
	# steady-state radius). This is a real, empirically-landed characteristic
	# of the CURRENT mesher (an empty/un-generated chunk's build cost is
	# bounded by [VoxelWorldConfig.mesh_build_budget_ms]'s 4.0 ms default per
	# call, so the budgeted per-frame path integrates at least the
	# progress-guaranteed FIRST item per call; a landed vox-007/vox-015/
	# vox-020 characteristic). This test's own pan distance is chosen small
	# enough (2 chunks) that the real per-frame live loop settles well within
	# this suite's own frame budget. Updated consciously, not incidentally,
	# per scene-005's own dev-story instructions to flag this file.
	var valley: Valley = _boot_valley()
	var mesher: VoxelWorldMesher = valley.get_voxel_world_mesher()
	var streamer: VoxelWorldMeshStreamer = valley.get_voxel_world_mesh_streamer()
	var camera_input: CameraInput = valley.get_camera_input()
	var original_focus: Vector3i = VoxelWorldGrid.world_to_cell(camera_input.get_target())
	var boot_radius: int = valley.get_voxel_world().config.boot_mesh_radius_chunks
	var original_focus_chunk: Vector2i = valley.get_voxel_world().chunk_key_for_cell(original_focus)
	var original_window: Array[Vector2i] = []
	for dz in range(-boot_radius, boot_radius + 1):
		for dx in range(-boot_radius, boot_radius + 1):
			original_window.append(Vector2i(original_focus_chunk.x + dx, original_focus_chunk.y + dz))
	assert_int(mesher.get_tracked_chunk_keys().size()).is_equal(original_window.size())

	# Act -- move the camera's orbit target a SMALL distance (2 chunks
	# diagonally, 32 world units) via the GDD-sanctioned WASD pan formula
	# (CameraInput's own established direct-method-call test convention --
	# camera_input.gd's class doc comment; `_apply_pan` is the ONE sanctioned
	# mutator of `_target`). Each call's delta is clamped to
	# `config.max_delta_time` internally, so several small calls (not one
	# huge one) is the correct way to accumulate this displacement -- a real
	# player would produce the same accumulation by briefly holding a pan key.
	for _i in range(20):
		camera_input._apply_pan(1.0, Vector3(1.0, 0.0, 1.0))
	var new_focus: Vector3i = VoxelWorldGrid.world_to_cell(camera_input.get_target())
	assert_bool(new_focus != original_focus).is_true()
	var new_window: Array[Vector2i] = streamer.get_desired_window_keys(new_focus)

	# Genuinely new ("entering") chunk keys this pan introduces. Story
	# scene-005: since the original window is now centered on the world-center
	# cell (no longer corner-clipped, see this test's own updated Arrange
	# comment above), a small pan genuinely shifts the window -- some chunks
	# leave, some enter -- rather than the former corner-start's pure-growth
	# special case. Unload-on-leaving is already proven, from a genuinely
	# non-overlapping pair of windows, by `mesh_view_window_streaming_test.gd`'s
	# own `test_moving_camera_focus_builds_entering_chunks_and_unloads_leaving_chunks`
	# (re-run as part of this story's own full suite pass); this test's own
	# job is proving the LIVE per-frame WIRING drives the SAME mechanism, not
	# re-proving the mechanism itself.
	var original_set: Dictionary[Vector2i, bool] = {}
	for key: Vector2i in original_window:
		original_set[key] = true
	var entering: Array[Vector2i] = []
	for key: Vector2i in new_window:
		if not original_set.has(key):
			entering.append(key)
	assert_int(entering.size()).is_greater(0)

	# Act -- let Valley's own live _process loop (never called directly --
	# this drives it exactly the way the real engine does) stream the window
	# to the new focus across enough real frames to fully settle. Story
	# scene-005: the boot window (radius 8, unclipped from the world-center
	# start, 17x17=289 chunks) must ALSO grow to the FULL unclipped
	# steady-state view_radius_chunks=12 window (25x25=625 chunks) even before
	# accounting for the pan -- a genuinely larger convergence than the former
	# corner-clipped start (whose OWN steady window was equally clipped and
	# therefore small). At ~1 chunk/frame (the shared mesh_build_budget_ms
	# progress guarantee), settling needs on the order of (625-289)=336+
	# frames; 250 (this test's former, corner-start-tuned bound) is no longer
	# enough. Updated consciously, not incidentally, per scene-005's own
	# dev-story instructions to flag this file.
	await _await_window_settled(mesher, new_window, 700)

	# Assert -- AC-1: the new window -- including every entering chunk -- is
	# fully built, tracking the CURRENT camera focus, not the stale initial
	# one.
	for key: Vector2i in new_window:
		assert_bool(mesher.is_chunk_tracked(key)).is_true()

	# Assert -- AC-2: tracked-chunk count (this headless suite's draw-call
	# proxy -- the real GPU draw-call measurement is the separate windowed
	# tool run) stays window-bounded, nowhere near the world's full chunk
	# extent (125 x 125 = 15,625 possible chunks at this config's default
	# 2000-cell width/depth and 16-cell chunk size), and within the
	# architectural <= 2000 ceiling.
	var tracked_count: int = mesher.get_tracked_chunk_keys().size()
	assert_int(tracked_count).is_equal(new_window.size())
	assert_int(tracked_count).is_less_equal(2000)
	assert_int(tracked_count).is_less(15625)
