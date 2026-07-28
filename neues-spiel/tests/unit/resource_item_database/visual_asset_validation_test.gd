## Unit test — Resource & Item Database Story rid-006 (`visual_asset`
## resolution validation, two failure shapes).
##
## Proves the real ResourceItemDatabase script's `visual_asset` boot check
## (GDD AC22, TR-resource-item-database-023; ADR-0006 Decision §3 / Risk 2):
## an entry whose backing `.tres` fails to load entirely (a missing/broken
## `[ext_resource]`) halts naming the entry as "entry failed to load"
## ([constant CHECK_RESOURCE_LOAD_FAILED]) — NEVER as "visual_asset
## unresolved"; an entry that loads successfully but carries a null
## `visual_asset` field halts naming the entry as "visual_asset unresolved"
## ([constant CHECK_VISUAL_ASSET_UNRESOLVED]); an entry with a resolved
## `visual_asset` boots Ready and is queryable exactly as authored. Each
## scenario uses its own isolated fixture directory
## (`fixtures/visual_asset/<scenario>/`), mirroring
## `ResourceItemDatabaseFootprintValidationTest`'s preloaded-`GDScript`
## instantiation pattern — zero scene tree, zero Autoload registration.
##
## Story rid-006 does NOT own: the other schema/invariant checks and the
## terminal-halt machinery this feeds (Stories 004/005); authoring the actual
## tier-0 / bed meshes as shipped content (Story 009).
class_name ResourceItemDatabaseVisualAssetValidationTest
extends GdUnitTestSuite

const ResourceItemDatabaseScript: GDScript = preload("res://src/resource_item_database/resource_item_database.gd")
const _FIXTURE_ROOT: String = "res://tests/integration/resource_item_database/fixtures/visual_asset/"


## Returns a fresh, never-autoloaded ResourceItemDatabase-script instance.
## Untyped return — the script deliberately carries no `class_name` (see its
## own doc comment) — mirroring `ResourceItemDatabaseFootprintValidationTest._new_database()`.
func _new_database() -> Object:
	return ResourceItemDatabaseScript.new()


## Runs `setup()` against the named fixture scenario subdirectory and returns
## the raw `{"success": bool, "issues": Array}` result.
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
# AC-1 / QA AC-1 — broken backing .tres halts as "entry failed to load"
# (GDD AC22a, ADR-0006 Risk 2)
# ---------------------------------------------------------------------------

func test_entry_with_broken_ext_resource_halts_as_entry_failed_to_load() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("broken_ext_resource")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_RESOURCE_LOAD_FAILED
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["source_file"])).contains("rid006_broken.tres")


# ---------------------------------------------------------------------------
# AC-2 / QA AC-2 — loaded entry with null visual_asset halts as
# "visual_asset unresolved" (GDD AC22b)
# ---------------------------------------------------------------------------

func test_entry_with_null_visual_asset_halts_naming_entry_as_visual_asset_unresolved() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("null_visual_asset")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_VISUAL_ASSET_UNRESOLVED
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid006_null_visual")
	assert_str(String(issue["field"])).is_equal("visual_asset")


# ---------------------------------------------------------------------------
# AC-3 / QA AC-3 — order: a broken-load entry is reported as "entry failed
# to load", NEVER also as "visual_asset unresolved" (ADR-0006 Risk 2's
# ordering requirement — resource-load check must run BEFORE the
# visual_asset != null check, since a broken .tres has no readable
# visual_asset field at all)
# ---------------------------------------------------------------------------

func test_entry_with_broken_ext_resource_is_never_also_reported_as_visual_asset_unresolved() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("broken_ext_resource")

	# Assert — the broken-load entry is named by the resource-load diagnostic
	# (proven by the sibling test above); here we prove the negative: it is
	# NEVER additionally reported as "visual_asset unresolved" (the fixture
	# directory's lone entry also trips the unrelated tier-0 coverage-gap
	# cross-entry check, Story 005 -- irrelevant to this ordering proof, so
	# this assertion targets the visual_asset check specifically rather than
	# the total issue count).
	var issues: Array = result["issues"] as Array
	var load_failed_matches: Array = _issues_with_check(
		issues, ResourceItemDatabaseScript.CHECK_RESOURCE_LOAD_FAILED
	)
	assert_array(load_failed_matches).has_size(1)
	var unresolved_matches: Array = _issues_with_check(
		issues, ResourceItemDatabaseScript.CHECK_VISUAL_ASSET_UNRESOLVED
	)
	assert_array(unresolved_matches).is_empty()


# ---------------------------------------------------------------------------
# Regression — an entry with a resolved visual_asset boots Ready and is
# queryable exactly as authored (proves the check does not reject valid
# entries; mirrors ResourceItemDatabaseFootprintValidationTest's own
# "valid" positive-path proof).
# ---------------------------------------------------------------------------

func test_entry_with_resolved_visual_asset_is_accepted_and_queryable_exactly() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join("valid_visual_asset") + "/"

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert
	assert_bool(bool(result["success"])).is_true()
	assert_array(result["issues"] as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	var entry: ItemDefinition = db.get_by_id(&"rid006_valid_visual")
	assert_object(entry).is_not_null()
	assert_object(entry.get_visual_asset()).is_not_null()


# ---------------------------------------------------------------------------
# Regression guard — existing pre-rid-006 fixture sets (now carrying an
# authored visual_asset per this story's fixture-set update) remain green
# under the extended pipeline.
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
