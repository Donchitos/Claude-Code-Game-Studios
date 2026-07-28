## Integration test -- Presentation Experience story presentation-005, F7
## ("a built bed becomes visible"). ADR-0001 primary (hosting/DI), ADR-0016
## primary (BV-1 transparency), ADR-0006 secondary (`visual_asset`).
##
## ⚑ THE ANTI-VACUITY LEVER (sprint-12.md's Must table, carried verbatim into
## this story's own Test Evidence section): boots the REAL `GameWorld`, then
## places a bed through the hosted, real `FurnitureRegistry` -- the exact
## call shape `ConstructionTickLoop._complete_jobs` already uses in
## production (proven end-to-end, including the tick-driven completion path
## itself, by `multi_cell_furniture_placement_test.gd`; this test's own new
## code under test is `FurniturePresenter`/`FurnitureView`'s REACTION to a
## real placement, not the construction chain that produces one, which is
## already covered elsewhere and would only add an unrelated MockTimeTickSystem
## dependency here) -- and counts the furniture view nodes in the LIVE scene
## tree. Today (pre-story, recorded in the story file / commit body): zero.
## After this story: exactly one, per placed footprint (never one per cell --
## BV-1's "one footprint, one entity" rule, on the view side too).
##
## Also covers AC-HOSTED / AC-BOOT-INVARIANT: `FurniturePresenter` is a real
## hosted child of `Valley`, reported through `get_injected_tier_modules()`,
## `setup()`-wired, and its `furniture_registry` cross-reference points at
## the SAME instance `Valley.get_furniture_registry()` returns.
class_name FurnitureViewLayerBootTest
extends GdUnitTestSuite

const GameWorldScene: PackedScene = preload("res://src/scene_world_management/game_world.tscn")


func _boot_active_world() -> GameWorld:
	var world: GameWorld = auto_free(GameWorldScene.instantiate())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	add_child(world)
	return world


# ---------------------------------------------------------------------------
# AC-HOSTED / AC-BOOT-INVARIANT
# ---------------------------------------------------------------------------

func test_furniture_presenter_is_hosted_setup_and_wired_to_the_real_registry() -> void:
	var world: GameWorld = _boot_active_world()

	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	var valley: Valley = world.get_valley() as Valley
	var presenter: FurniturePresenter = valley.get_furniture_presenter()

	assert_object(presenter).is_not_null()
	assert_bool(presenter.is_set_up()).is_true()
	assert_array(valley.get_injected_tier_modules()).contains([presenter])
	assert_object(presenter.furniture_registry).is_same(valley.get_furniture_registry())


# ---------------------------------------------------------------------------
# ⚑ THE LEVER -- live-tree furniture-view count
# ---------------------------------------------------------------------------

func test_lever_zero_furniture_views_before_any_placement_in_the_real_booted_game() -> void:
	# The recorded pre-story observation, pinned as a live regression guard:
	# a freshly booted real game starts with zero placed furniture, so it
	# must start with zero furniture views too.
	var world: GameWorld = _boot_active_world()
	var valley: Valley = world.get_valley() as Valley

	assert_int(valley.get_furniture_presenter().get_view_count()).is_equal(0)


func test_lever_exactly_one_furniture_view_after_a_bed_is_placed_in_the_real_booted_game() -> void:
	# Arrange
	var world: GameWorld = _boot_active_world()
	var valley: Valley = world.get_valley() as Valley
	var registry: FurnitureRegistry = valley.get_furniture_registry()

	# Act -- the real, hosted FurnitureRegistry.place() call, the exact shape
	# ConstructionTickLoop._complete_jobs uses on a completed footprint.
	var item_id: String = registry.place(&"bed", [Vector3i(4, 0, 4), Vector3i(4, 0, 5)])

	# Assert -- exactly ONE furniture view exists (one footprint, one entity
	# -- never two, one per occupied cell).
	var presenter: FurniturePresenter = valley.get_furniture_presenter()
	assert_int(presenter.get_view_count()).is_equal(1)
	assert_object(presenter.get_view_for(item_id)).is_not_null()


func test_lever_furniture_view_is_actually_findable_in_the_live_scene_tree() -> void:
	# The lever's own literal wording: "count the furniture view nodes in the
	# live scene tree" -- proven by walking the real tree from Valley, not
	# only by asking the presenter's own bookkeeping.
	var world: GameWorld = _boot_active_world()
	var valley: Valley = world.get_valley() as Valley
	var registry: FurnitureRegistry = valley.get_furniture_registry()

	registry.place(&"bed", [Vector3i(6, 0, 6), Vector3i(6, 0, 7)])

	var found: Array[Node] = valley.find_children("FurnitureView_*", "FurnitureView", true, false)
	assert_int(found.size()).is_equal(1)


func test_lever_removing_the_item_frees_its_view_back_to_zero_in_the_live_tree() -> void:
	var world: GameWorld = _boot_active_world()
	var valley: Valley = world.get_valley() as Valley
	var registry: FurnitureRegistry = valley.get_furniture_registry()
	var item_id: String = registry.place(&"bed", [Vector3i(8, 0, 8), Vector3i(8, 0, 9)])
	assert_int(valley.get_furniture_presenter().get_view_count()).is_equal(1)

	registry.remove(item_id)
	await get_tree().process_frame

	assert_int(valley.get_furniture_presenter().get_view_count()).is_equal(0)
	var found: Array[Node] = valley.find_children("FurnitureView_*", "FurnitureView", true, false)
	assert_int(found.size()).is_equal(0)


# ---------------------------------------------------------------------------
# The real mesh actually reaches the view (visual proof, headless)
# ---------------------------------------------------------------------------

func test_placed_bed_view_carries_the_real_bed_mesh_from_rid() -> void:
	var world: GameWorld = _boot_active_world()
	var valley: Valley = world.get_valley() as Valley
	var registry: FurnitureRegistry = valley.get_furniture_registry()
	var item_id: String = registry.place(&"bed", [Vector3i(10, 0, 10), Vector3i(10, 0, 11)])

	var view: FurnitureView = valley.get_furniture_presenter().get_view_for(item_id)
	assert_object(view).is_not_null()
	var definition: ItemDefinition = ResourceItemDatabase.get_by_id(&"bed")
	assert_object(view.get_mesh_instance().mesh).is_same(definition.get_visual_asset())
