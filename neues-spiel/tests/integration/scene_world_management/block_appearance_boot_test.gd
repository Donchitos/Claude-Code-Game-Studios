## Integration test -- Voxel World story vox-023 ("Block appearance becomes
## DATA"), AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL's positive half: the real,
## unmodified `game_world.tscn` -> `Valley.tscn` chain boots to ACTIVE with
## [VoxelWorldMesher.appearance] wired and validated.
##
## Lever 3 itself (removing `Valley.tscn`'s appearance Inspector assignment,
## rebooting, and observing the loud failure) is a manual deletion probe
## recorded in the commit body per the `scene-007`/`scene-008`
## deletion-probe discipline -- not automated here, since the failure mode IS
## "the scene file itself is missing a line," which this suite cannot express
## without literally mutating `Valley.tscn` out from under every other test in
## this file.
class_name BlockAppearanceBootTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


func _boot_real_game_world() -> GameWorld:
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	return world


func test_real_boot_reaches_active_with_appearance_wired_and_validated() -> void:
	var world: GameWorld = _boot_real_game_world()

	# The real boot gate must reach ACTIVE -- if the appearance config were
	# unwired, VoxelWorldMesher.setup()'s assert would abort this boot before
	# ACTIVE is ever reached (AC-NEVER-OPTIONAL-AND-CONSEQUENTIAL).
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)

	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()

	var mesher: VoxelWorldMesher = valley.get_voxel_world_mesher()
	assert_object(mesher).is_not_null()
	assert_bool(mesher.is_set_up()).is_true()
	assert_object(mesher.appearance).is_not_null()

	# The shipped .tres carries the art bible's own hexes -- id 1 stays
	# Lowland (AC-SHIPPED-VALUES-ARE-THE-ART-BIBLE'S, AC-ID-1-STAYS-LOWLAND).
	assert_that(mesher.appearance.get_color(1, Color.MAGENTA)).is_equal(Color("9CAD6E"))

	# validate() ran exactly once, at boot, and found no BLOCKING issue --
	# the shipped config is valid by construction.
	assert_array(mesher.get_boot_blocking_issues()).is_empty()
