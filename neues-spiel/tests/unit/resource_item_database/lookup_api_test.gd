## Unit test — Resource & Item Database Story rid-003 (read-only lookup API:
## get_by_id full implementation + listing/query methods).
##
## Proves the real ResourceItemDatabase script's lookup surface against a
## dedicated fixture set (5 entries: three tier-0 building materials across
## the three material families, one tier-1 building-material variant sharing
## the `stone` family, one tier-1 `furniture_fixture` entry) — API shape has
## no write/mutation method (AC-1), unknown-id queries return an explicit
## not-found result and log once without crashing (AC-2), a zero-entry
## category returns an empty list, not an error (AC-3), family filtering
## returns all and only that family across tiers (AC-4), and list-all returns
## every authored id exactly once (AC-5). The tier-0 query (GDD AC14) is also
## covered — the fixture's tier-1 stone variant and tier-1 bed prove the
## filter actually excludes non-tier-0 entries, not just that it doesn't
## error. Instantiated via a preloaded [GDScript]'s `.new()` directly — zero
## scene tree, zero Autoload registration (Test Evidence), mirroring
## `ResourceItemDatabaseBootGateTest`.
class_name ResourceItemDatabaseLookupApiTest
extends GdUnitTestSuite

const ResourceItemDatabaseScript: GDScript = preload("res://src/resource_item_database/resource_item_database.gd")
const _LOOKUP_FIXTURE_DIR: String = "res://tests/integration/resource_item_database/fixtures/lookup/"

const _UNKNOWN_ID_WARNING: String = (
	"ResourceItemDatabase.get_by_id(): unknown id 'rid003_does_not_exist' queried -- "
	+ "returning null (GDD Edge Case 2; missing_item fallback is Story 007's scope)"
)


## Returns a fresh, never-autoloaded ResourceItemDatabase-script instance.
## Untyped return — the script deliberately carries no `class_name` (see its
## own doc comment), so isolated instances are constructed via a preloaded
## [GDScript] and duck-typed at each access site, mirroring
## `ResourceItemDatabaseBootGateTest._new_database()`.
func _new_database() -> Object:
	return ResourceItemDatabaseScript.new()


## Returns a fresh database already resolved to Ready against the lookup
## fixture set. Shared arrange step for every test below.
func _new_ready_database() -> Object:
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _LOOKUP_FIXTURE_DIR
	@warning_ignore("unsafe_method_access")
	db.setup()
	return db


# ---------------------------------------------------------------------------
# AC-1 — API shape: no write/mutation method exposed anywhere (GDD Core
# Rule 8 / Control Manifest Forbidden: no write API)
# ---------------------------------------------------------------------------

func test_resource_item_database_exposes_no_write_or_mutation_method() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())

	# Act
	var method_names: Array[String] = []
	for method_info: Dictionary in db.get_script().get_script_method_list():
		method_names.append(method_info["name"] as String)

	# Assert — the read-only lookup surface exposes zero write/mutation-
	# shaped methods on its own declared API.
	assert_array(method_names).is_not_empty()
	var forbidden_prefixes: Array[String] = [
		"set_", "add_", "remove_", "delete_", "insert_", "update_", "clear_", "create_"
	]
	for method_name: String in method_names:
		for prefix: String in forbidden_prefixes:
			assert_bool(method_name.begins_with(prefix)).override_failure_message(
				"ResourceItemDatabase exposes a write/mutation-shaped method '%s' -- read-only lookup API forbids write methods" % method_name
			).is_false()


func test_list_ids_by_category_returns_all_and_only_matching_category_no_cross_leakage() -> void:
	# Arrange
	var db: Object = _new_ready_database()

	# Act
	@warning_ignore("unsafe_method_access")
	var building_material_ids: Array = db.list_ids_by_category(&"building_material")
	@warning_ignore("unsafe_method_access")
	var furniture_ids: Array = db.list_ids_by_category(&"furniture_fixture")

	# Assert — no cross-category leakage in either direction.
	assert_array(building_material_ids).contains_exactly_in_any_order([
		&"rid003_wood_block",
		&"rid003_stone_block",
		&"rid003_thatch_block",
		&"rid003_stone_block_variant",
	])
	assert_array(furniture_ids).contains_exactly_in_any_order([&"rid003_bed"])


# ---------------------------------------------------------------------------
# AC-2 — unknown id: explicit not-found result, logged once, no crash
# (GDD Edge Case 2 / AC8)
# ---------------------------------------------------------------------------

func test_get_by_id_for_unknown_id_returns_null_and_does_not_crash() -> void:
	# Arrange
	var db: Object = _new_ready_database()

	# Act
	@warning_ignore("unsafe_method_access")
	var result: ItemDefinition = db.get_by_id(&"rid003_does_not_exist")

	# Assert
	assert_object(result).is_null()


func test_get_by_id_for_unknown_id_logs_the_id_once() -> void:
	# Arrange
	var db: Object = _new_ready_database()

	# Act + Assert — the unknown id is logged (GDD Edge Case 2 / AC8), never
	# silently swallowed.
	await assert_error(
		func() -> void:
			@warning_ignore("unsafe_method_access", "return_value_discarded")
			db.get_by_id(&"rid003_does_not_exist")
	).is_push_warning(_UNKNOWN_ID_WARNING)


func test_get_by_id_for_known_id_returns_no_warning() -> void:
	# Arrange
	var db: Object = _new_ready_database()

	# Act + Assert — a known id produces zero runtime warnings/errors.
	await assert_error(
		func() -> void:
			@warning_ignore("unsafe_method_access", "return_value_discarded")
			db.get_by_id(&"rid003_wood_block")
	).is_success()


# ---------------------------------------------------------------------------
# AC-3 — zero-entry category returns an empty list, not an error
# (GDD Edge Case 8 / AC12)
# ---------------------------------------------------------------------------

func test_list_ids_by_category_for_zero_entry_category_returns_empty_list() -> void:
	# Arrange — the fixture set authors zero `raw_resource` entries, matching
	# MVP's real content shape.
	var db: Object = _new_ready_database()

	# Act
	@warning_ignore("unsafe_method_access")
	var ids: Array = db.list_ids_by_category(&"raw_resource")

	# Assert
	assert_array(ids).is_empty()


# ---------------------------------------------------------------------------
# AC-4 — family filter: all and only entries of that family, across tiers
# (GDD AC15)
# ---------------------------------------------------------------------------

func test_list_ids_by_material_family_returns_all_and_only_that_family() -> void:
	# Arrange — wood/stone/thatch families; stone appears at both tier 0 and
	# tier 1 to prove family filtering aggregates across tiers.
	var db: Object = _new_ready_database()

	# Act
	@warning_ignore("unsafe_method_access")
	var wood_ids: Array = db.list_ids_by_material_family(&"wood")
	@warning_ignore("unsafe_method_access")
	var stone_ids: Array = db.list_ids_by_material_family(&"stone")
	@warning_ignore("unsafe_method_access")
	var thatch_ids: Array = db.list_ids_by_material_family(&"thatch")

	# Assert
	assert_array(wood_ids).contains_exactly_in_any_order([&"rid003_wood_block"])
	assert_array(stone_ids).contains_exactly_in_any_order([
		&"rid003_stone_block", &"rid003_stone_block_variant"
	])
	assert_array(thatch_ids).contains_exactly_in_any_order([&"rid003_thatch_block"])


# ---------------------------------------------------------------------------
# AC-5 — list all: every authored id exactly once, none unauthored
# (GDD AC16)
# ---------------------------------------------------------------------------

func test_list_all_ids_returns_every_authored_id_exactly_once() -> void:
	# Arrange — five authored fixture entries.
	var db: Object = _new_ready_database()

	# Act
	@warning_ignore("unsafe_method_access")
	var ids: Array = db.list_all_ids()

	# Assert
	assert_array(ids).contains_exactly_in_any_order([
		&"rid003_wood_block",
		&"rid003_stone_block",
		&"rid003_thatch_block",
		&"rid003_stone_block_variant",
		&"rid003_bed",
	])


# ---------------------------------------------------------------------------
# GDD AC14 — tier-0 query logic proven on a fixture (content assertion
# against shipped MVP data is Story 009's scope)
# ---------------------------------------------------------------------------

func test_list_ids_by_tier_zero_excludes_tier_one_entries() -> void:
	# Arrange — three tier-0 building materials, plus a tier-1 building-
	# material variant AND a tier-1 furniture entry that must both be
	# excluded.
	var db: Object = _new_ready_database()

	# Act
	@warning_ignore("unsafe_method_access")
	var tier_zero_ids: Array = db.list_ids_by_tier(0)

	# Assert
	assert_array(tier_zero_ids).contains_exactly_in_any_order([
		&"rid003_wood_block",
		&"rid003_stone_block",
		&"rid003_thatch_block",
	])


# ---------------------------------------------------------------------------
# Non-Ready guard — listing queries share get_by_id's contract
# (TR-resource-item-database-034): never partial data outside Ready.
# ---------------------------------------------------------------------------

func test_listing_queries_before_setup_return_empty_lists_never_data() -> void:
	# Arrange — setup() never called (Unloaded state).
	var db: Object = auto_free(_new_database())

	# Act + Assert
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_ids_by_category(&"building_material") as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_ids_by_material_family(&"wood") as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_ids_by_tier(0) as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_all_ids() as Array).is_empty()
