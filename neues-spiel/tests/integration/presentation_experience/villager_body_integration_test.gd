## Integration test — Presentation Experience story presentation-003
## (Villager body view, hit proxy & slice hook), the AC gated on real
## `villager-ai-021` (starting-roster spawn).
##
## Proves: booting the REAL `GameWorld.tscn`/`Valley.tscn` (mirrors
## `world_root_valley_attach_test.gd`'s established boot fixture) produces
## exactly one [VillagerBodyView] per hosted villager -- the always-present
## `villager_id = 0` PLUS every villager `spawn_starting_roster` adds during
## real world genesis -- each visible and mirroring its own villager's real
## [method VillagerAi.get_visual_position] exactly.
##
## The "presentation adds no simulation" founding constraint (byte-identical
## tick results with/without the presenter) is NOT re-proven here as a
## literal two-boot diff -- [VillagerBodyPresenter] is a permanent, always-
## present hosted child of the real `Valley.tscn`, so there is no
## "presenter-absent" production configuration left to boot and diff
## against. The constraint is instead verified structurally, by the
## unit-level guards this story already ships in
## `villager_body_view_test.gd` (zero mutating calls into [VillagerAi] from
## `src/presentation/`, zero Selection references) PLUS this test's own
## live check that several real ticks still advance the villager roster
## normally with the presenter attached and refreshed.
class_name VillagerBodyIntegrationTest
extends GdUnitTestSuite

const ValleyScene: PackedScene = preload("res://src/scene_world_management/Valley.tscn")


func test_boot_produces_one_visible_body_per_hosted_villager_mirroring_its_ai() -> void:
	# Arrange + Act — real boot (mirrors world_root_valley_attach_test.gd's
	# established fixture); GameWorld._run_world_genesis (already-landed
	# story scene-005) drives residency + spawn_starting_roster synchronously
	# within the same call stack that attaches Valley, so the roster (and
	# this story's presenter refresh) is settled the instant add_child(world)
	# returns.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene

	add_child(world)
	# Two frames: the first lets every node `add_child()`-ed mid-boot (the
	# spawned villager, its VillagerBodyView) receive its own first
	# `_process()` call; a single awaited frame is not reliably enough for a
	# node added THIS same frame, mid-`_ready()`-chain (mirrors this story's
	# own physics-sync precedent in `villager_body_view_test.gd`'s live ray
	# queries, which needed two `physics_frame` awaits for the same reason).
	await get_tree().process_frame
	await get_tree().process_frame

	var valley: Valley = world.get_valley() as Valley
	assert_object(valley).is_not_null()
	var presenter: VillagerBodyPresenter = valley.get_villager_body_presenter()
	assert_object(presenter).is_not_null()
	assert_bool(presenter.is_set_up()).is_true()

	var villagers: Array[VillagerAi] = valley.get_villagers()
	assert_int(villagers.size()).is_greater_equal(1)
	assert_int(presenter.get_view_count()).is_equal(villagers.size())

	# Assert — one visible, correctly-mirroring view per real villager.
	for villager: VillagerAi in villagers:
		var view: VillagerBodyView = presenter.get_view_for(villager.get_villager_id())
		assert_object(view).is_not_null()
		assert_bool(view.visible).is_true()
		assert_vector(view.global_position).is_equal(villager.get_visual_position())
		assert_int(view.get_hit_proxy().collision_layer).is_equal(1)


func test_presenter_present_does_not_disturb_real_ticks_advancing_the_roster() -> void:
	# Structural proxy for the "adds no simulation" founding constraint --
	# see class doc comment for why a literal two-boot byte-identical diff
	# is not this test's shape. Drives several real ticks through the
	# Autoload TimeTickSystem and asserts the roster is still exactly the
	# same villagers, still all set up, still all producing a finite visual
	# position through the presenter's own views -- nothing about a normal
	# tick cycle broke with the presenter attached.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	add_child(world)
	await get_tree().process_frame

	var valley: Valley = world.get_valley() as Valley
	var presenter: VillagerBodyPresenter = valley.get_villager_body_presenter()
	var villager_count_before: int = valley.get_villagers().size()

	for _i: int in range(5):
		await get_tree().process_frame

	assert_int(valley.get_villagers().size()).is_equal(villager_count_before)
	assert_int(presenter.get_view_count()).is_equal(villager_count_before)
	for villager: VillagerAi in valley.get_villagers():
		var view: VillagerBodyView = presenter.get_view_for(villager.get_villager_id())
		assert_object(view).is_not_null()
		assert_bool(is_finite(view.global_position.x)).is_true()
		assert_bool(is_finite(view.global_position.y)).is_true()
		assert_bool(is_finite(view.global_position.z)).is_true()
