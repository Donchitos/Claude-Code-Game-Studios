## Unit test — Resource & Item Database Story rid-008 (furniture footprint
## field + boot validation).
##
## Proves the real ResourceItemDatabase script's category<->footprint
## pairing/presence checks (GDD Core Rule 10, Edge Cases 10/11,
## TR-resource-item-database-052/053/054): a `furniture_fixture` entry with
## a valid footprint is accepted and queryable exactly as authored (AC30); a
## `furniture_fixture` entry with a non-positive dimension halts naming the
## entry and the violated dimension (AC31b); a non-`furniture_fixture` entry
## with an authored footprint halts naming the entry (AC32). Each scenario
## uses its own isolated fixture directory
## (`fixtures/footprint/<scenario>/`), mirroring
## `ResourceItemDatabaseValidationSchemaChecksTest`'s preloaded-`GDScript`
## instantiation pattern — zero scene tree, zero Autoload registration.
##
## Story rid-008 does NOT own: the `footprint` field/getter itself (Story
## 001, already structurally present on `ItemDefinitionResource`/
## `ItemDefinition`); the base validation pipeline these checks extend
## (Story 004); authoring the `bed` entry's `(1, 2)` content value
## (Story 009).
class_name ResourceItemDatabaseFootprintValidationTest
extends GdUnitTestSuite

const ResourceItemDatabaseScript: GDScript = preload("res://src/resource_item_database/resource_item_database.gd")
const _FIXTURE_ROOT: String = "res://tests/integration/resource_item_database/fixtures/footprint/"


## Returns a fresh, never-autoloaded ResourceItemDatabase-script instance.
## Untyped return — the script deliberately carries no `class_name` (see
## its own doc comment) — mirroring
## `ResourceItemDatabaseValidationSchemaChecksTest._new_database()`.
func _new_database() -> Object:
	return ResourceItemDatabaseScript.new()


## Runs `setup()` against the named fixture scenario subdirectory and
## returns the raw `{"success": bool, "issues": Array}` result.
func _run_setup_against_scenario(scenario: String) -> Dictionary:
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join(scenario) + "/"
	@warning_ignore("unsafe_method_access")
	return db.setup() as Dictionary


## Returns the subset of [param issues] whose `"check"` matches [param check].
func _issues_with_check(issues: Array, check: StringName) -> Array:
	var matches: Array = []
	for issue: Dictionary in issues:
		if issue["check"] == check:
			matches.append(issue)
	return matches


# ---------------------------------------------------------------------------
# AC-1 / GDD AC30 — valid footprint accepted, queryable exactly (TR-052)
# ---------------------------------------------------------------------------

func test_furniture_fixture_with_valid_footprint_is_accepted_and_queryable_exactly() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join("valid_footprint") + "/"

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert
	assert_bool(bool(result["success"])).is_true()
	assert_array(result["issues"] as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	var entry: ItemDefinition = db.get_by_id(&"rid008_valid_footprint")
	assert_object(entry).is_not_null()
	assert_vector(entry.get_footprint()).is_equal(Vector2i(1, 2))


# ---------------------------------------------------------------------------
# AC-2 / GDD AC31b — non-positive dimension halts naming the entry and the
# violated dimension (TR-054)
# ---------------------------------------------------------------------------

func test_furniture_fixture_with_zero_width_halts_naming_entry_and_width_dimension() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("furniture_missing_width")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_INVALID_FOOTPRINT
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid008_missing_width")
	assert_str(String(issue["field"])).is_equal("footprint")
	assert_str(String(issue["dimension"])).is_equal("width_cells")


func test_furniture_fixture_with_negative_depth_halts_naming_entry_and_depth_dimension() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("furniture_missing_depth")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_INVALID_FOOTPRINT
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid008_missing_depth")
	assert_str(String(issue["field"])).is_equal("footprint")
	assert_str(String(issue["dimension"])).is_equal("depth_cells")


func test_furniture_fixture_with_both_dimensions_invalid_names_both_not_just_the_first() -> void:
	# Act — proves the pipeline's "never short-circuit" discipline extends
	# to a single entry with two violations of the SAME check.
	var result: Dictionary = _run_setup_against_scenario("furniture_both_dimensions_invalid")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_INVALID_FOOTPRINT
	)
	assert_array(matches).has_size(2)
	var dimensions: Array = []
	for issue: Dictionary in matches:
		assert_str(String(issue["entry_id"])).is_equal("rid008_both_invalid")
		dimensions.append(String(issue["dimension"]))
	assert_array(dimensions).contains_exactly_in_any_order(["width_cells", "depth_cells"])


# ---------------------------------------------------------------------------
# AC-3 / GDD AC32 — footprint authored on a non-furniture_fixture entry
# halts naming the entry (TR-053)
# ---------------------------------------------------------------------------

func test_building_material_with_authored_footprint_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("non_furniture_with_footprint")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_CATEGORY_FOOTPRINT_PAIRING
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid008_building_with_footprint")
	assert_str(String(issue["field"])).is_equal("footprint")


# ---------------------------------------------------------------------------
# Engine-fact regression (GDD sub-case 31a) — see this script's class doc
# comment and `resource_item_database.gd`'s Story rid-008 scope note: a
# furniture_fixture entry that OMITS footprint entirely deserializes to the
# schema's own `Vector2i(1, 1)` default, which already satisfies "both dims
# >= 1" — structurally indistinguishable from an explicitly-authored valid
# (1, 1) footprint, so it correctly succeeds rather than halting. Mirrors
# `ResourceItemDatabaseValidationSchemaChecksTest`'s tier non-integer
# coercion regression test.
# ---------------------------------------------------------------------------

func test_furniture_fixture_omitting_footprint_defaults_to_valid_one_by_one_and_succeeds() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join("furniture_omitted_footprint_defaults_valid") + "/"

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert — boot succeeds; no invalid_footprint issue is (or could be)
	# raised for the omitted-property entry.
	assert_bool(bool(result["success"])).is_true()
	assert_array(result["issues"] as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	var entry: ItemDefinition = db.get_by_id(&"rid008_omitted_footprint")
	assert_object(entry).is_not_null()
	assert_vector(entry.get_footprint()).is_equal(Vector2i(1, 1))


# ---------------------------------------------------------------------------
# Regression guard — existing pre-rid-008 fixture sets remain green under
# the extended pipeline (every fixture already carries an explicit,
# schema-compliant footprint value — see rid-008 implementation notes).
# ---------------------------------------------------------------------------

func test_existing_valid_fixture_set_still_reaches_ready_under_the_extended_pipeline() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = "res://tests/integration/resource_item_database/fixtures/valid/"

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert
	assert_bool(bool(result["success"])).is_true()
	assert_array(result["issues"] as Array).is_empty()


func test_existing_lookup_fixture_set_still_reaches_ready_under_the_extended_pipeline() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = "res://tests/integration/resource_item_database/fixtures/lookup/"

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert
	assert_bool(bool(result["success"])).is_true()
	assert_array(result["issues"] as Array).is_empty()
