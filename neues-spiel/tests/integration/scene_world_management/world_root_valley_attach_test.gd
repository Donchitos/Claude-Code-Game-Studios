## Integration test -- Scene/World Management Story 001 (ADR-0001 + ADR-0013,
## World Root + single-Valley attach topology).
##
## Proves: [GameWorld] (the World Root) attaches a real [Valley] instance as
## its child, unconditionally, at boot (AC1/TR-scene-world-management-034);
## Voxel World and Camera & Input -- the two hosted Foundation/Core systems
## that already have landed code -- are structural children of that Valley
## root and remain valid across several frames (AC2/TR-scene-world-management-036);
## the World Root's own instance identity is stable across frames (never
## freed, TR-scene-world-management-038); no MainMenu node exists anywhere in
## the tree (forward-conflict guard against the story's NEEDS-DECISION flag);
## and the banned scene-handoff APIs
## (change_scene_to_file/change_scene_to_packed/reload_current_scene/a direct
## current_scene assignment) are grep-absent from this system's own source
## (TR-scene-world-management-037).
##
## Time & Tick System (Autoload-tier, ADR-0001) and Villager AI & Behavior (no
## landed code yet) are deliberately NOT asserted as Valley children here --
## see [Valley]'s class doc comment for why that is by design, not a gap.
class_name WorldRootValleyAttachTest
extends GdUnitTestSuite

const ValleyScene: PackedScene = preload("res://src/scene_world_management/Valley.tscn")


# ---------------------------------------------------------------------------
# AC1 -- boot -> Valley active, no menu
# ---------------------------------------------------------------------------

func test_boot_attaches_valley_as_child_of_world_root() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene

	# Act -- entering the live tree fires GameWorld._ready().
	add_child(world)

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Node = world.get_valley()
	assert_object(valley).is_not_null()
	assert_bool(valley is Valley).is_true()
	assert_object(valley.get_parent()).is_same(world)
	assert_bool(valley.is_inside_tree()).is_true()


func test_boot_with_no_valley_scene_wired_still_reaches_active() -> void:
	# Arrange -- regression guard: existing DI/boot-gate-only suites predate
	# this story and never set valley_scene; that must remain a harmless
	# no-op, never an assertion failure.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database

	# Act
	add_child(world)

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	assert_object(world.get_valley()).is_null()


func test_no_main_menu_node_exists_anywhere_in_the_tree() -> void:
	# Arrange -- forward-conflict guard (QA plan edge case): the story's
	# NEEDS-DECISION flag records a future Main Menu conflict but the M01
	# behavior is boot-straight-to-Valley; no MainMenu node may exist yet.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene

	# Act
	add_child(world)

	# Assert
	assert_object(_find_descendant_named(world, &"MainMenu")).is_null()


# ---------------------------------------------------------------------------
# AC2 -- hosting topology
# ---------------------------------------------------------------------------

func test_hosted_voxel_world_and_camera_input_are_children_of_valley() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene

	# Act
	add_child(world)

	# Assert
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var camera_input: CameraInput = valley.get_camera_input()
	assert_object(voxel_world).is_not_null()
	assert_object(camera_input).is_not_null()
	assert_object(voxel_world.get_parent()).is_same(valley)
	assert_object(camera_input.get_parent()).is_same(valley)


func test_hosted_systems_remain_valid_instances_across_several_frames() -> void:
	# Arrange -- edge case (QA plan): each hosted system remains a valid
	# instance across several frames (session-lifetime check).
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	add_child(world)
	var valley: Valley = world.get_valley() as Valley
	var voxel_world: VoxelWorldGrid = valley.get_voxel_world()
	var camera_input: CameraInput = valley.get_camera_input()

	# Act
	for _i: int in range(3):
		await get_tree().process_frame

	# Assert
	assert_bool(is_instance_valid(valley)).is_true()
	assert_bool(is_instance_valid(voxel_world)).is_true()
	assert_bool(is_instance_valid(camera_input)).is_true()
	assert_bool(valley.is_inside_tree()).is_true()


func test_time_tick_system_autoload_is_never_a_valley_child() -> void:
	# Arrange -- regression guard for the ONE still-standing documented
	# absence (Valley's class doc comment): Time & Tick is Autoload-tier,
	# never a scene child of anything, including Valley. This is a standing
	# architectural fact, unaffected by Story scene-004's addition of the
	# remaining Foundation/Core hosted modules (Villager AI's own absence
	# from this list was retired by that story -- see
	# test_hosted_building_system_and_villager_ai_modules_are_children_of_valley
	# below for its own now-landed presence).
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene

	# Act
	add_child(world)

	# Assert
	var valley: Valley = world.get_valley() as Valley
	assert_object(_find_descendant_named(valley, &"TimeTickSystem")).is_null()


func test_hosted_building_system_and_villager_ai_modules_are_children_of_valley() -> void:
	# Arrange -- Story scene-004 (THE INTEGRATION CROWN) addition: the four
	# Building System modules and one Villager AI instance are now real,
	# landed hosted children of Valley (this test's own predecessor asserted
	# their absence when neither epic had landed code yet -- see
	# gameworld_e2e_loop_test.gd for this story's own dedicated, fuller
	# assembly proof; this is a light presence/count regression guard local
	# to this suite's own established child-topology coverage). Story
	# vox-018 adds a ninth hosted child, [VoxelWorldMeshStreamer] -- see
	# `live_view_window_wiring_test.gd` for that story's own dedicated
	# wiring/boot-timing proof. M01 condition C4 (`production/milestones/
	# milestone-01-review-2026-07-26.md`) adds two more --
	# [AmbientTorchLight]/[TorchFlicker], see [Valley]'s own class doc
	# comment for the full wiring rationale -- this count was 9 -> 11.
	# Story scene-005 (World genesis in the boot sequence) adds a TWELFTH --
	# not a new structural hosted module, but [method
	# GameWorld._run_world_genesis] now calls [method
	# Valley.spawn_starting_roster] exactly once during real boot
	# (AC-ROSTER-AFTER-WORLD), and that method add_child()s each spawned
	# [VillagerAi] directly onto this Valley instance (shipped MVP default
	# `starting_villager_count = 1`). Updated consciously, not incidentally
	# (11 -> 12). Story needs-mood-010 (THE CROWN's own production-wiring AC)
	# adds a THIRTEENTH -- the hosted [NeedsMood] instance [method
	# _wire_villager_population] assigns to every [VillagerAi]'s
	# `needs_provider` seam (12 -> 13). Story presentation-003 (Villager body
	# view, hit proxy & slice hook) adds a FOURTEENTH -- the hosted
	# [VillagerBodyPresenter], concurrent with needs-mood-010 in this same
	# sprint; updated consciously here, not incidentally (13 -> 14). Story
	# scene-007 (Build-tool & project-lifecycle hosting) adds EIGHT more --
	# [BuildEditorMode], [WallTool], [FloorTool], [RoofTool], [BlockTool],
	# [FurnitureTool], [GhostPreview], [UndoRedoStack] -- the entire
	# build-interaction tier that was, before this story, in no scene at all
	# (14 -> 22). [BuildProjectRegistry]/[ConstructionJobQueue]/[RemovalTool]/
	# [PlanOnlyUndoGate]/[FurnitureRegistry]/[FurnitureBedProvider] are
	# `RefCounted` collaborators, not scene children -- they do not affect
	# this count. Story cam-013 (Camera hosting in the shipped scene) adds TWO
	# more -- [ValleyCamera]/[CameraMirror] (22 -> 24) -- updated consciously,
	# not incidentally, per that story's own dev-story instructions to flag
	# this file. Story presentation-004 ("The world has no sun") adds THREE
	# more -- [Sun] (a plain [DirectionalLight3D]), [WorldEnvironment], and
	# [WorldLighting] (the driver module) -- (24 -> 27), updated consciously,
	# not incidentally. Story villager-ai-022 ("the stray villager at the
	# world corner") REMOVES the scene-005 TWELFTH counted above: villager 0
	# (the always-present default) now COUNTS toward the shipped
	# `starting_villager_count = 1` and is placed by the SAME genesis call,
	# so that call no longer add_child()s a SEPARATE roster member for the
	# MVP default count -- (27 -> 26), updated consciously, not incidentally.
	# Story scene-008 ("Hosting the gates that make work honest") adds ONE
	# more hosted child -- [BuildValidation] -- (26 -> 27), updated
	# consciously, not incidentally. [VillagerOnSiteGate]/
	# [VillagerSealPreventionGate] are `RefCounted` collaborators, not scene
	# children -- they do not affect this count, mirroring
	# [ConstructionJobQueue]'s own established precedent. Story
	# build-validation-009 ("Loop-payoff surface receives real signals,"
	# milestone criterion #7) adds TWO more hosted children --
	# [LoopPayoffSignalSurface] and [LoopPayoffAdapter] -- (27 -> 29), updated
	# consciously, not incidentally. Story presentation-005 ("A built bed
	# becomes visible" -- the furniture view layer, F7) adds ONE more hosted
	# child -- [FurniturePresenter] -- (29 -> 30), updated consciously, not
	# incidentally.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene

	# Act
	add_child(world)

	# Assert
	var valley: Valley = world.get_valley() as Valley
	assert_int(valley.get_child_count()).is_equal(31)  # +1: ScaffoldPresentation (building-034 occupancy tier)
	assert_object(valley.get_voxel_world_mesher()).is_not_null()
	assert_object(valley.get_voxel_world_mesh_streamer()).is_not_null()
	assert_object(valley.get_tool_state_machine()).is_not_null()
	assert_object(valley.get_placement_pick()).is_not_null()
	assert_object(valley.get_commit_pipeline()).is_not_null()
	assert_object(valley.get_construction_tick_loop()).is_not_null()
	assert_object(valley.get_villager_ai()).is_not_null()
	assert_object(valley.get_ambient_torch_light()).is_not_null()
	assert_object(valley.get_torch_flicker()).is_not_null()
	assert_object(valley.get_needs_mood()).is_not_null()
	assert_object(valley.get_villager_ai().needs_provider).is_same(valley.get_needs_mood())
	assert_object(valley.get_villager_body_presenter()).is_not_null()
	# Story scene-007's own new hosted children (presence only -- the
	# non-vacuous proof of what they actually DO lives in
	# build_tool_hosting_boot_test.gd, not here; see that file's own
	# AC-PROBE-IS-NON-VACUOUS discipline).
	assert_object(valley.get_build_editor_mode()).is_not_null()
	assert_object(valley.get_wall_tool()).is_not_null()
	assert_object(valley.get_floor_tool()).is_not_null()
	assert_object(valley.get_roof_tool()).is_not_null()
	assert_object(valley.get_block_tool()).is_not_null()
	assert_object(valley.get_furniture_tool()).is_not_null()
	assert_object(valley.get_ghost_preview()).is_not_null()
	assert_object(valley.get_undo_redo_stack()).is_not_null()
	assert_object(valley.get_build_project_registry()).is_not_null()
	assert_object(valley.get_construction_job_queue()).is_not_null()
	assert_object(valley.get_removal_tool()).is_not_null()
	assert_object(valley.get_plan_only_undo_gate()).is_not_null()
	# Story cam-013 (Camera hosting in the shipped scene) adds TWO more hosted
	# children -- ValleyCamera (a plain Camera3D) and CameraMirror (the driver
	# module) -- (22 -> 24). Updated consciously, not incidentally, per that
	# story's own dev-story instructions to flag this file.
	assert_object(valley.get_valley_camera()).is_not_null()
	assert_object(valley.get_camera_mirror()).is_not_null()
	assert_object(valley.get_furniture_registry()).is_not_null()
	assert_object(valley.get_furniture_bed_provider()).is_not_null()
	# Story presentation-004 ("The world has no sun") adds THREE more hosted
	# children -- Sun (a plain DirectionalLight3D), WorldEnvironment, and
	# WorldLighting (the driver module) -- (24 -> 27). Updated consciously,
	# not incidentally.
	assert_object(valley.get_sun_light()).is_not_null()
	assert_object(valley.get_world_environment()).is_not_null()
	assert_object(valley.get_world_lighting()).is_not_null()
	# Story scene-008 ("Hosting the gates that make work honest") adds ONE
	# more hosted child -- BuildValidation -- (26 -> 27). VillagerOnSiteGate/
	# VillagerSealPreventionGate are RefCounted collaborators, present but not
	# counted as scene children (mirrors ConstructionJobQueue's own precedent).
	assert_object(valley.get_build_validation()).is_not_null()
	assert_object(valley.get_villager_onsite_gate()).is_not_null()
	assert_object(valley.get_villager_seal_prevention_gate()).is_not_null()
	assert_object(valley.get_furniture_bed_provider().build_validation).is_same(valley.get_build_validation())
	# Story build-validation-009 ("Loop-payoff surface receives real signals")
	# adds TWO more hosted children -- LoopPayoffSignalSurface and
	# LoopPayoffAdapter -- (27 -> 29). The adapter's own two dependencies are
	# wired to the SAME real, hosted instances every other cross-reference in
	# this suite already checks.
	assert_object(valley.get_loop_payoff_signal_surface()).is_not_null()
	assert_object(valley.get_loop_payoff_adapter()).is_not_null()
	assert_object(valley.get_loop_payoff_adapter().build_validation).is_same(valley.get_build_validation())
	assert_object(valley.get_loop_payoff_adapter().payoff_surface).is_same(valley.get_loop_payoff_signal_surface())
	# Story presentation-005 ("A built bed becomes visible") adds ONE more
	# hosted child -- FurniturePresenter -- (29 -> 30).
	assert_object(valley.get_furniture_presenter()).is_not_null()
	assert_object(valley.get_furniture_presenter().furniture_registry).is_same(valley.get_furniture_registry())


# ---------------------------------------------------------------------------
# World Root never freed + banned APIs absent
# ---------------------------------------------------------------------------

func test_world_root_instance_identity_stable_across_frames() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	add_child(world)
	var boot_instance_id: int = world.get_instance_id()

	# Act
	for _i: int in range(3):
		await get_tree().process_frame

	# Assert -- same instance, never freed/replaced.
	assert_bool(is_instance_valid(world)).is_true()
	assert_int(world.get_instance_id()).is_equal(boot_instance_id)
	assert_object(instance_from_id(boot_instance_id)).is_same(world)


func test_banned_scene_transition_apis_absent_from_system_source() -> void:
	# Grep-verifiable AC: change_scene_to_file/change_scene_to_packed/
	# reload_current_scene/a direct "current_scene =" assignment must never
	# appear in this system's own source.
	var source: String = _read_all_gd_source("res://src/scene_world_management")

	var banned_substrings: Array[String] = [
		"change_scene_to_file",
		"change_scene_to_packed",
		"reload_current_scene",
	]
	for banned: String in banned_substrings:
		assert_bool(source.contains(banned)).is_false()

	# The property-form assignment is the quieter footgun (no auto-free/
	# auto-add, silently desyncs current_scene from the World Root) -- checked
	# separately via regex so "valley_scene = " (this story's own export) is
	# never mistaken for it.
	var current_scene_assignment: RegEx = RegEx.new()
	var compile_error: int = current_scene_assignment.compile("current_scene\\s*=(?!=)")
	assert_int(compile_error).is_equal(OK)
	assert_object(current_scene_assignment.search(source)).is_null()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Recursively searches [param root]'s descendants (not [param root] itself)
## for a node named [param node_name]. Returns the first match, or null.
func _find_descendant_named(root: Node, node_name: StringName) -> Node:
	for child: Node in root.get_children():
		if child.name == node_name:
			return child
		var found: Node = _find_descendant_named(child, node_name)
		if found != null:
			return found
	return null


## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive -- this system's directory is flat),
## STRIPPING full-line `#`/`##` doc-comment lines first. This system's own
## doc comments legitimately name the banned APIs (to document that they are
## forbidden -- see e.g. [GameWorld]'s and this file's own class doc
## comments) -- a naive raw-text scan would flag its own compliance
## documentation as a violation. Stripping comment lines means only actual
## CODE usage can trip the checks below.
func _read_all_gd_source(dir_path: String) -> String:
	var combined: String = ""
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Could not open directory: %s" % dir_path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd"):
			var text: String = FileAccess.get_file_as_string(dir_path.path_join(file_name))
			for line: String in text.split("\n"):
				if not line.strip_edges().begins_with("#"):
					combined += line
					combined += "\n"
		file_name = dir.get_next()
	dir.list_dir_end()
	return combined
