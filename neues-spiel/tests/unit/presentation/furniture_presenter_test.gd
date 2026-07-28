## Unit test -- [FurniturePresenter] (Presentation Experience story
## presentation-005, F7: "a built bed becomes visible").
##
## Uses a REAL [FurnitureRegistry] instance throughout (a concrete,
## already-`class_name`d `RefCounted` -- mirrors [FurnitureBedProvider]'s own
## established "typed, not duck-typed" precedent for this exact
## collaborator), never a mock -- this class's own hard constraint is that it
## calls almost nothing on the registry, so the real thing is cheap and more
## honest than a stand-in.
##
## Covers, per the story's own AC list:
## - AC-PRESENTER: create/free lifecycle diffed against the registry's
##   current contents, keyed by `item_id`.
## - AC-SELF-RESYNCING: `setup()` subscribes to `furniture_changed` so a
##   later `place()`/`remove()` re-syncs with no external caller.
## - AC-READ-ONLY-BY-CONSTRUCTION: grep guard -- the ENTIRE `src/presentation/`
##   directory calls at most `get_placed_furniture()` on `furniture_registry`,
##   never `place()`/`remove()`/any other mutating member.
## - AC-HOSTED nil-safety: a `null` registry creates zero views, connects
##   nothing, never crashes.
class_name FurniturePresenterTest
extends GdUnitTestSuite


func _real_bed_id() -> StringName:
	return &"bed"


# ---------------------------------------------------------------------------
# AC-PRESENTER -- create/free lifecycle
# ---------------------------------------------------------------------------

func test_setup_creates_one_view_per_placed_item_from_a_real_registry() -> void:
	var registry := FurnitureRegistry.new()
	registry.place(&"bed", [Vector3i(0, 0, 0), Vector3i(0, 0, 1)])

	var presenter: FurniturePresenter = auto_free(FurniturePresenter.new())
	presenter.furniture_registry = registry
	add_child(presenter)

	assert_bool(presenter.is_set_up()).is_false()
	presenter.setup()

	assert_bool(presenter.is_set_up()).is_true()
	assert_int(presenter.get_view_count()).is_equal(1)


func test_setup_with_null_registry_creates_zero_views_no_crash() -> void:
	var presenter: FurniturePresenter = auto_free(FurniturePresenter.new())
	add_child(presenter)

	presenter.setup()

	assert_int(presenter.get_view_count()).is_equal(0)


func test_view_is_positioned_over_its_own_footprint_cells() -> void:
	var registry := FurnitureRegistry.new()
	var cell_a := Vector3i(3, 0, 3)
	var cell_b := Vector3i(3, 0, 4)
	var item_id: String = registry.place(&"bed", [cell_a, cell_b])

	var presenter: FurniturePresenter = auto_free(FurniturePresenter.new())
	presenter.furniture_registry = registry
	add_child(presenter)
	presenter.setup()

	var view: FurnitureView = presenter.get_view_for(item_id)
	assert_object(view).is_not_null()
	var center_a: Vector3 = VoxelWorldGrid.cell_to_world(cell_a)
	var center_b: Vector3 = VoxelWorldGrid.cell_to_world(cell_b)
	var expected: Vector3 = Vector3(
		(center_a.x + center_b.x) * 0.5,
		center_a.y - 0.5 * VoxelWorldConfig.CELL_SIZE,
		(center_a.z + center_b.z) * 0.5,
	)
	assert_vector(view.global_position).is_equal(expected)


func test_view_gets_the_real_visual_asset_mesh_from_resource_item_database() -> void:
	# Real RID content (data/items/bed.tres) -- proves _create_view resolves
	# through ResourceItemDatabase.get_by_id, not a hardcoded mesh, mirroring
	# BuildValidationConfig.is_need_functional's own established call-site
	# precedent for this exact Autoload lookup.
	var registry := FurnitureRegistry.new()
	var item_id: String = registry.place(_real_bed_id(), [Vector3i(0, 0, 0), Vector3i(0, 0, 1)])

	var presenter: FurniturePresenter = auto_free(FurniturePresenter.new())
	presenter.furniture_registry = registry
	add_child(presenter)
	presenter.setup()

	var view: FurnitureView = presenter.get_view_for(item_id)
	var definition: ItemDefinition = ResourceItemDatabase.get_by_id(_real_bed_id())
	assert_object(view.get_mesh_instance().mesh).is_same(definition.get_visual_asset())


# ---------------------------------------------------------------------------
# AC-SELF-RESYNCING -- signal-driven, no external refresh() call needed
# ---------------------------------------------------------------------------

func test_placing_a_new_item_after_setup_creates_a_view_via_the_signal_alone() -> void:
	var registry := FurnitureRegistry.new()
	var presenter: FurniturePresenter = auto_free(FurniturePresenter.new())
	presenter.furniture_registry = registry
	add_child(presenter)
	presenter.setup()
	assert_int(presenter.get_view_count()).is_equal(0)

	# No explicit presenter.refresh() call below -- the registry's own signal
	# must drive the re-sync by itself.
	registry.place(&"bed", [Vector3i(5, 0, 5), Vector3i(5, 0, 6)])

	assert_int(presenter.get_view_count()).is_equal(1)


func test_removing_an_item_after_setup_frees_its_view_via_the_signal_alone() -> void:
	var registry := FurnitureRegistry.new()
	var item_id: String = registry.place(&"bed", [Vector3i(1, 0, 1), Vector3i(1, 0, 2)])
	var presenter: FurniturePresenter = auto_free(FurniturePresenter.new())
	presenter.furniture_registry = registry
	add_child(presenter)
	presenter.setup()
	var removed_view: FurnitureView = presenter.get_view_for(item_id)

	registry.remove(item_id)
	await get_tree().process_frame

	assert_int(presenter.get_view_count()).is_equal(0)
	assert_object(presenter.get_view_for(item_id)).is_null()
	assert_bool(is_instance_valid(removed_view)).is_false()


func test_refresh_frees_the_view_for_a_removed_item_without_touching_others() -> void:
	# Direct refresh() call (never mutating), mirroring
	# VillagerBodyPresenter's own refresh-diff test shape.
	var registry := FurnitureRegistry.new()
	var kept_id: String = registry.place(&"bed", [Vector3i(0, 0, 0), Vector3i(0, 0, 1)])
	var removed_id: String = registry.place(&"bed", [Vector3i(9, 0, 9), Vector3i(9, 0, 10)])
	var presenter: FurniturePresenter = auto_free(FurniturePresenter.new())
	presenter.furniture_registry = registry
	add_child(presenter)
	presenter.setup()
	assert_int(presenter.get_view_count()).is_equal(2)

	registry.remove(removed_id)
	presenter.refresh()

	assert_int(presenter.get_view_count()).is_equal(1)
	assert_object(presenter.get_view_for(kept_id)).is_not_null()
	assert_object(presenter.get_view_for(removed_id)).is_null()


# ---------------------------------------------------------------------------
# AC-READ-ONLY-BY-CONSTRUCTION -- grep guard (mirrors
# villager_body_view_test.gd's own zero-mutating-calls allowlist pattern)
# ---------------------------------------------------------------------------

func test_presentation_module_makes_zero_mutating_calls_into_furniture_registry() -> void:
	var source: String = _read_gd_source_no_comments("res://src/presentation")
	var allowed_calls: Array[String] = ["get_placed_furniture"]
	var pattern := RegEx.new()
	var compile_error: int = pattern.compile("furniture_registry\\.(\\w+)\\s*\\(")
	assert_int(compile_error).is_equal(OK)
	for match_result: RegExMatch in pattern.search_all(source):
		var called: String = match_result.get_string(1)
		assert_bool(allowed_calls.has(called)).is_true()


func test_presentation_module_source_never_calls_place_or_remove_on_furniture_registry() -> void:
	var source: String = _read_gd_source_no_comments("res://src/presentation")
	assert_bool(source.contains("furniture_registry.place(")).is_false()
	assert_bool(source.contains("furniture_registry.remove(")).is_false()


# ---------------------------------------------------------------------------
# Test helpers (kept below the tests that use them, mirrors
# villager_body_view_test.gd's own established file layout)
# ---------------------------------------------------------------------------

## Reads and concatenates every `.gd` file directly under [param dir_path]
## (non-recursive -- `src/presentation` is a flat directory), stripping
## full-line `#`/`##` doc-comment lines first -- mirrors
## villager_body_view_test.gd's own `_read_gd_source_no_comments` helper
## exactly (duplicated here rather than shared, matching this suite's own
## no-shared-test-utility convention).
func _read_gd_source_no_comments(dir_path: String) -> String:
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
