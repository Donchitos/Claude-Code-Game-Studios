## Unit test — Resource & Item Database Story rid-007 (`missing_item`
## built-in fallback resolution + exclusion from all listing queries).
##
## Proves the real ResourceItemDatabase script's [method resolve_or_missing]
## against the existing rid-003 lookup fixture set (5 authored entries,
## none named `missing_item`/category `missing` -- boot validation already
## rejects that, Story 005): an unknown/retired id resolves to the fully
## inert built-in fallback with every Edge Case 1 field (AC-1); the SAME
## missing id resolved repeatedly logs exactly once per load event, while a
## DISTINCT missing id logs its own, independent entry (AC-2); and
## `missing_item` never appears in any listing query -- category, family,
## tier, or list-all (AC-3) -- reachable only via direct resolution.
## Instantiated via a preloaded [GDScript]'s `.new()` directly -- zero scene
## tree, zero Autoload registration (Test Evidence), mirroring
## `ResourceItemDatabaseLookupApiTest`.
class_name ResourceItemDatabaseMissingItemFallbackTest
extends GdUnitTestSuite

const ResourceItemDatabaseScript: GDScript = preload("res://src/resource_item_database/resource_item_database.gd")
const _LOOKUP_FIXTURE_DIR: String = "res://tests/integration/resource_item_database/fixtures/lookup/"


## Returns a fresh, never-autoloaded ResourceItemDatabase-script instance.
## Untyped return -- the script deliberately carries no `class_name` (see
## its own doc comment), so isolated instances are constructed via a
## preloaded [GDScript] and duck-typed at each access site, mirroring
## `ResourceItemDatabaseLookupApiTest._new_database()`.
func _new_database() -> Object:
	return ResourceItemDatabaseScript.new()


## Returns a fresh database already resolved to Ready against the rid-003
## lookup fixture set. Shared arrange step for every test below.
func _new_ready_database() -> Object:
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _LOOKUP_FIXTURE_DIR
	@warning_ignore("unsafe_method_access")
	db.setup()
	return db


## Builds the exact `resolve_or_missing()` push_warning message for
## [param id] -- mirrors the production string in `resource_item_database.gd`
## so a drifted message surfaces as a failing assertion, not a silent typo.
func _missing_id_warning(id: String) -> String:
	return (
		"ResourceItemDatabase.resolve_or_missing(): unknown/retired id "
		+ "'%s' resolved to the built-in missing_item fallback (GDD "
		+ "Edge Case 1) -- logged once per load event"
	) % id


# ---------------------------------------------------------------------------
# AC-1 — inert fallback: every Edge Case 1 field, exactly
# (GDD AC9a / TR-resource-item-database-038)
# ---------------------------------------------------------------------------

func test_resolve_or_missing_for_unknown_id_returns_fully_inert_definition() -> void:
	# Arrange
	var db: Object = _new_ready_database()

	# Act
	@warning_ignore("unsafe_method_access")
	var missing: ItemDefinition = db.resolve_or_missing(&"rid007_does_not_exist")

	# Assert — every Edge Case 1 field, exactly.
	assert_object(missing).is_not_null()
	assert_str(String(missing.get_id())).is_equal("missing_item")
	assert_str(missing.get_display_name()).is_equal("Missing Item")
	assert_str(String(missing.get_category())).is_equal("missing")
	assert_str(String(missing.get_material_family())).is_equal("none")
	assert_int(missing.get_tier()).is_equal(0)
	assert_bool(missing.get_stackable()).is_false()
	assert_int(missing.get_max_stack_size()).is_equal(1)
	assert_bool(missing.get_haulable()).is_false()
	assert_str(String(missing.get_storage_category())).is_equal("none")
	assert_vector(missing.get_footprint()).is_equal(Vector2i(1, 1))

	# Assert — a deliberately conspicuous magenta placeholder visual, not a
	# null/unresolved mesh (distinct from Story 006's authored-entry
	# visual_asset validation, out of this story's scope).
	var visual: Variant = missing.get_visual_asset()
	assert_object(visual).is_not_null()
	assert_bool(visual is PrimitiveMesh).is_true()
	var material: Material = (visual as PrimitiveMesh).material
	assert_object(material).is_not_null()
	assert_bool(material is StandardMaterial3D).is_true()
	assert_bool((material as StandardMaterial3D).albedo_color == Color(1.0, 0.0, 1.0)).override_failure_message(
		"missing_item's placeholder visual must be magenta (GDD Edge Case 1's deliberately conspicuous error visual)"
	).is_true()


func test_resolve_or_missing_before_setup_still_returns_fully_inert_definition() -> void:
	# Arrange — Unloaded state; setup() never called. Same non-Ready guard
	# as get_by_id's own contract (TR-034) -- never a partial read, and the
	# fallback is itself an explicit, safe result rather than data.
	var db: Object = auto_free(_new_database())

	# Act
	@warning_ignore("unsafe_method_access")
	var missing: ItemDefinition = db.resolve_or_missing(&"rid007_before_ready")

	# Assert
	assert_object(missing).is_not_null()
	assert_str(String(missing.get_id())).is_equal("missing_item")
	assert_str(String(missing.get_category())).is_equal("missing")


# ---------------------------------------------------------------------------
# AC-2 — dedup: each distinct missing id logged exactly once per load event
# (GDD Edge Case 1)
# ---------------------------------------------------------------------------

func test_resolve_or_missing_same_id_resolved_three_times_logs_exactly_once() -> void:
	# Arrange
	var db: Object = _new_ready_database()

	# Act + Assert — 1st resolution of this id: logs once.
	await assert_error(
		func() -> void:
			@warning_ignore("unsafe_method_access", "return_value_discarded")
			db.resolve_or_missing(&"rid007_repeat_missing")
	).is_push_warning(_missing_id_warning("rid007_repeat_missing"))

	# Act + Assert — 2nd AND 3rd resolutions of the SAME id: zero further
	# warnings (dedup within this instance's one load event).
	await assert_error(
		func() -> void:
			@warning_ignore("unsafe_method_access", "return_value_discarded")
			db.resolve_or_missing(&"rid007_repeat_missing")
			@warning_ignore("unsafe_method_access", "return_value_discarded")
			db.resolve_or_missing(&"rid007_repeat_missing")
	).is_success()


func test_resolve_or_missing_two_distinct_missing_ids_each_log_their_own_entry() -> void:
	# Arrange
	var db: Object = _new_ready_database()

	# Act + Assert — each distinct id logs its own, independent first entry.
	await assert_error(
		func() -> void:
			@warning_ignore("unsafe_method_access", "return_value_discarded")
			db.resolve_or_missing(&"rid007_distinct_a")
	).is_push_warning(_missing_id_warning("rid007_distinct_a"))

	await assert_error(
		func() -> void:
			@warning_ignore("unsafe_method_access", "return_value_discarded")
			db.resolve_or_missing(&"rid007_distinct_b")
	).is_push_warning(_missing_id_warning("rid007_distinct_b"))


func test_resolve_or_missing_for_a_known_id_returns_no_warning() -> void:
	# Arrange
	var db: Object = _new_ready_database()

	# Act + Assert — a known id resolves via the real entry, not the
	# fallback, and produces zero warnings.
	await assert_error(
		func() -> void:
			@warning_ignore("unsafe_method_access", "return_value_discarded")
			db.resolve_or_missing(&"rid003_wood_block")
	).is_success()


# ---------------------------------------------------------------------------
# AC-3 — exclusion: missing_item never appears in ANY listing query
# (GDD AC27 / TR-resource-item-database-033)
# ---------------------------------------------------------------------------

func test_missing_item_never_appears_in_category_family_tier_or_list_all_queries() -> void:
	# Arrange — resolve an unknown id first, proving a resolution never
	# leaks the fallback into subsequent listing results.
	var db: Object = _new_ready_database()
	@warning_ignore("unsafe_method_access", "return_value_discarded")
	db.resolve_or_missing(&"rid007_unknown_before_listing")

	# Act + Assert — the reserved category itself returns empty (no entry is
	# ever authored with it — Story 005 rejects that at boot).
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_ids_by_category(&"missing") as Array).is_empty()

	# Act + Assert — the reserved family value is also missing_item's own
	# `material_family` (Edge Case 1), but it is NOT empty in this fixture
	# set: `rid003_bed` (furniture_fixture) legitimately carries `none` too
	# (Story 008's category<->material_family pairing requires it for every
	# non-`building_material` category) -- so the correct proof is exclusion
	# of `missing_item` specifically, not emptiness of the whole list.
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_ids_by_material_family(&"none") as Array).not_contains(&"missing_item")

	# Act + Assert — tier 0 (missing_item's own tier) never includes it
	# alongside the real tier-0 fixture entries.
	@warning_ignore("unsafe_method_access")
	var tier_zero_ids: Array = db.list_ids_by_tier(0)
	assert_array(tier_zero_ids).not_contains(&"missing_item")
	assert_array(tier_zero_ids).contains_exactly_in_any_order([
		&"rid003_wood_block", &"rid003_stone_block", &"rid003_thatch_block",
	])

	# Act + Assert — list-all never includes it either.
	@warning_ignore("unsafe_method_access")
	var all_ids: Array = db.list_all_ids()
	assert_array(all_ids).not_contains(&"missing_item")
	assert_array(all_ids).contains_exactly_in_any_order([
		&"rid003_wood_block",
		&"rid003_stone_block",
		&"rid003_thatch_block",
		&"rid003_stone_block_variant",
		&"rid003_bed",
	])


func test_missing_item_reachable_only_via_direct_resolution_not_via_get_by_id() -> void:
	# Arrange — get_by_id (Story 003) keeps its own null-on-unknown contract;
	# only resolve_or_missing (this story) ever returns the fallback.
	var db: Object = _new_ready_database()

	# Act
	@warning_ignore("unsafe_method_access")
	var via_get_by_id: ItemDefinition = db.get_by_id(&"rid007_only_reachable_via_fallback")
	@warning_ignore("unsafe_method_access")
	var via_fallback: ItemDefinition = db.resolve_or_missing(&"rid007_only_reachable_via_fallback")

	# Assert
	assert_object(via_get_by_id).is_null()
	assert_object(via_fallback).is_not_null()
	assert_str(String(via_fallback.get_id())).is_equal("missing_item")
