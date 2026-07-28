## Integration test -- Camera & Input story cam-013 ("Camera hosting in the
## shipped scene"; ADR-0010 primary reference only for the "no new input
## handler" claim, ADR-0001/ADR-0005 secondary).
##
## Before this story, `game_world.tscn` -> `Valley.tscn` hosted ZERO
## [Camera3D] nodes -- a human launching the real game saw nothing at all,
## despite [CameraInput]'s own orbit/pan/zoom math being fully landed and
## tested (this story's own Context: the sixth instance of ship-green-and-
## uncalled this project has hit, and the most visible one).
##
## Proves:
## - **AC1**: the real boot hosts exactly one [Camera3D] under [Valley].
## - **AC2 + the Anti-Vacuity Lever**: after boot, the hosted camera's
##   `global_position` equals [method CameraInput.get_camera_position]
##   exactly (never merely "a camera exists somewhere") -- AND mutating the
##   camera's transform directly afterward leaves [CameraInput]'s own
##   reported state completely unchanged, proving the dependency is
##   structurally one-way.
## - **AC3**: grep guard -- `camera_input.gd`'s actual code (comments
##   stripped) never mentions `Camera3D` anywhere; [CameraInput] was not
##   modified to hold one.
## - **AC4 + the Anti-Vacuity Lever**: the camera's position (via
##   [CameraInput]'s own target) sits within the starting roster's
##   neighbourhood -- the SAME world-center cell [VillagerRosterSpawner]
##   actually placed the roster around -- never at the world origin.
## - **AC5**: grep guard -- `valley.gd` (the one file this story modifies)
##   defines neither `_input(` nor `_unhandled_input(` -- no new input
##   handler is introduced outside [CameraInput].
## - **AC6**: covered by `world_genesis_boot_test.gd`'s own growing
##   boot-invariant assertion block (this story's own Test Evidence note) --
##   not duplicated here.
class_name CameraHostingTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


# ---------------------------------------------------------------------------
# Test isolation -- per-test temp region directories, cleaned up after each
# test (mirrors `world_genesis_boot_test.gd`'s own established precedent;
# the real production VoxelWorldConfig persists resident chunks to disk).
# ---------------------------------------------------------------------------

var _created_region_dirs: Array[String] = []


func after_test() -> void:
	for dir_path: String in _created_region_dirs:
		_remove_dir_recursive(dir_path)
	_created_region_dirs.clear()


func _remove_dir_recursive(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path: String = dir_path.path_join(entry)
			if dir.current_is_dir():
				_remove_dir_recursive(full_path)
			else:
				DirAccess.remove_absolute(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)


# ---------------------------------------------------------------------------
# Shared helper -- a real GameWorld/Valley boot through the ADR-0005 gate,
# mirroring `world_genesis_boot_test.gd`/`villager_need_seeding_boot_test.gd`'s
# own established fixture exactly (the only shape that can prove this story's
# claims against the ACTUAL shipped scene chain, not merely Valley's methods
# in isolation).
# ---------------------------------------------------------------------------

func _boot_real_game_world() -> GameWorld:
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	return world


func _count_camera3d_nodes(node: Node) -> int:
	var count: int = 1 if node is Camera3D else 0
	for child: Node in node.get_children():
		count += _count_camera3d_nodes(child)
	return count


# ---------------------------------------------------------------------------
# AC1 -- exactly one Camera3D hosted under Valley
# ---------------------------------------------------------------------------

func test_ac1_real_boot_hosts_exactly_one_camera3d_under_valley() -> void:
	var world: GameWorld = _boot_real_game_world()
	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	assert_int(_count_camera3d_nodes(valley)).is_equal(1)


# ---------------------------------------------------------------------------
# AC2 + AC4 + Anti-Vacuity Lever -- the load-bearing bundle, ONE real boot
# (mirrors `world_genesis_boot_test.gd`'s own "bundle everything a single
# real boot can prove into ONE test" rationale, avoiding a second ~2000x2000
# genesis + mesh cost).
# ---------------------------------------------------------------------------

func test_ac2_ac4_camera_mirrors_position_near_settlement_and_only_one_way() -> void:
	# Arrange + Act -- real boot; let at least one real engine frame elapse so
	# CameraMirror's own _process has run at least once beyond its setup()-time
	# initial pass (proving the PER-FRAME mirror, not merely the one-shot
	# initial framing).
	var world: GameWorld = _boot_real_game_world()
	var valley: Valley = world.get_valley() as Valley
	var camera_input: CameraInput = valley.get_camera_input()
	var camera: Camera3D = valley.get_valley_camera()
	await get_tree().process_frame

	# Assert -- AC2 + Anti-Vacuity Lever: the hosted camera's global_position
	# equals CameraInput's own derived position exactly -- not merely "a
	# camera exists somewhere in the scene."
	assert_vector(camera.global_position).is_equal(camera_input.get_camera_position())

	# Assert -- AC4 + Anti-Vacuity Lever: CameraInput's own target sits within
	# the roster's neighbourhood -- the SAME world-center cell
	# VillagerRosterSpawner actually placed the roster around -- never at the
	# world origin. Framed on the world centre / roster neighbourhood, NOT
	# averaged over every villager (the scene-hosted default villager, id 0,
	# sits at cell (0,0,0) -- a separate, known bug, story-022's job, not this
	# story's -- averaging over it would be the wrong anchor).
	var settlement_center_cell: Vector3i = VillagerRosterSpawner.world_center_cell(
		valley.get_voxel_world().config
	)
	var settlement_center: Vector3 = VoxelWorldGrid.cell_to_world(settlement_center_cell)
	assert_vector(camera_input.get_target()).is_not_equal(Vector3.ZERO)
	assert_float(camera_input.get_target().distance_to(settlement_center)).is_less(1.0)

	# Act + Assert -- the ONE-WAY proof (AC2/AC3): mutating the camera's
	# transform directly afterward leaves CameraInput's own reported state
	# completely unchanged -- the dependency only ever flows CameraInput ->
	# Camera3D, never the reverse.
	var camera_input_position_before: Vector3 = camera_input.get_camera_position()
	var camera_input_target_before: Vector3 = camera_input.get_target()
	camera.global_position = Vector3(9999.0, 9999.0, 9999.0)
	camera.rotation = Vector3(1.0, 2.0, 3.0)
	assert_vector(camera_input.get_camera_position()).is_equal(camera_input_position_before)
	assert_vector(camera_input.get_target()).is_equal(camera_input_target_before)


# ---------------------------------------------------------------------------
# AC3 -- grep guard: CameraInput's own code never mentions Camera3D
# ---------------------------------------------------------------------------

func test_ac3_camera_input_source_never_declares_a_camera3d_field_grep_guard() -> void:
	var text: String = FileAccess.get_file_as_string("res://src/camera_input/camera_input.gd")
	var offenders: Array[String] = []
	for line: String in text.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.begins_with("#"):
			continue
		if stripped.contains("Camera3D"):
			offenders.append(stripped)
	assert_array(offenders).is_empty()


# ---------------------------------------------------------------------------
# AC5 -- grep guard: no new _input()/_unhandled_input() handler in valley.gd
# ---------------------------------------------------------------------------

func test_ac5_valley_source_introduces_no_new_input_handler_grep_guard() -> void:
	var text: String = FileAccess.get_file_as_string("res://src/scene_world_management/valley.gd")
	var offenders: Array[String] = []
	for line: String in text.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.begins_with("#"):
			continue
		if stripped.begins_with("func _input(") or stripped.begins_with("func _unhandled_input("):
			offenders.append(stripped)
	assert_array(offenders).is_empty()


func test_ac5_camera_mirror_source_reads_no_input_event_grep_guard() -> void:
	var text: String = FileAccess.get_file_as_string("res://src/camera_input/camera_mirror.gd")
	var offenders: Array[String] = []
	for line: String in text.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.begins_with("#"):
			continue
		if (
			stripped.begins_with("func _input(")
			or stripped.begins_with("func _unhandled_input(")
			or stripped.contains("InputEvent")
		):
			offenders.append(stripped)
	assert_array(offenders).is_empty()
