## Unit test — Resource & Item Database Story rid-004 (boot validation:
## per-entry schema checks).
##
## Proves the real ResourceItemDatabase script's schema-check pipeline
## (extended from rid-002's placeholder load-only check): every check
## appends a STRUCTURED record — entry id, source file, violated check,
## offending field — never a log string, and the pipeline never
## short-circuits on the first failure. Each scenario uses its own
## isolated fixture directory (`fixtures/schema_checks/<scenario>/`) so a
## test asserts on exactly the violation(s) it's proving, mirroring
## `ResourceItemDatabaseBootGateTest`/`ResourceItemDatabaseLookupApiTest`'s
## preloaded-`GDScript` instantiation pattern — zero scene tree, zero
## Autoload registration.
##
## Story rid-004 does NOT own: reserved-id/-category rejection, the
## retired-ids ledger, tier-0 family coverage, the >=3-violation aggregate
## report, or the terminal-Failed exposure contract (all Story 005);
## `visual_asset` resolution (Story 006); the `missing_item` fallback
## (Story 007); `footprint` validation (Story 008).
class_name ResourceItemDatabaseValidationSchemaChecksTest
extends GdUnitTestSuite

const ResourceItemDatabaseScript: GDScript = preload("res://src/resource_item_database/resource_item_database.gd")
const _FIXTURE_ROOT: String = "res://tests/integration/resource_item_database/fixtures/schema_checks/"


## Returns a fresh, never-autoloaded ResourceItemDatabase-script instance.
## Untyped return — the script deliberately carries no `class_name` (see
## its own doc comment), so isolated instances are constructed via a
## preloaded [GDScript] and duck-typed at each access site, mirroring
## `ResourceItemDatabaseBootGateTest._new_database()`.
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
# AC — id snake_case format (GDD AC6, sub-cases 6a/6b/6c) — TR-024
# ---------------------------------------------------------------------------

func test_id_with_uppercase_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("id_uppercase")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_INVALID_ID_FORMAT
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("WoodBlock")
	assert_str(String(issue["field"])).is_equal("id")
	assert_str(issue["source_file"] as String).contains("id_uppercase")


func test_id_with_spaces_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("id_spaces")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_INVALID_ID_FORMAT
	)
	assert_array(matches).has_size(1)
	assert_str(String((matches[0] as Dictionary)["entry_id"])).is_equal("wood block")


func test_id_with_hyphens_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("id_hyphens")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_INVALID_ID_FORMAT
	)
	assert_array(matches).has_size(1)
	assert_str(String((matches[0] as Dictionary)["entry_id"])).is_equal("wood-block")


# ---------------------------------------------------------------------------
# AC — duplicate id across files halts naming BOTH entries AND both source
# files (GDD AC3) — TR-040
# ---------------------------------------------------------------------------

func test_duplicate_id_across_two_files_halts_naming_both_entries_and_both_files() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("duplicate_id")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_DUPLICATE_ID
	)
	assert_array(matches).has_size(2)
	var source_files: Array = []
	for issue: Dictionary in matches:
		assert_str(String(issue["entry_id"])).is_equal("rid004_dup_block")
		source_files.append(issue["source_file"])
	var scenario_dir: String = _FIXTURE_ROOT.path_join("duplicate_id") + "/"
	assert_array(source_files).contains_exactly_in_any_order([
		scenario_dir.path_join("rid004_dup_a.tres"),
		scenario_dir.path_join("rid004_dup_b.tres"),
	])


# ---------------------------------------------------------------------------
# AC — unknown category (4a) / unknown material_family (4b) — TR-041
# ---------------------------------------------------------------------------

func test_unknown_category_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("unknown_category")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_UNKNOWN_CATEGORY
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid004_widget")
	assert_str(String(issue["field"])).is_equal("category")


func test_unknown_material_family_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("unknown_material_family")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_UNKNOWN_MATERIAL_FAMILY
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid004_crystal")
	assert_str(String(issue["field"])).is_equal("material_family")


# ---------------------------------------------------------------------------
# AC — missing required field halts naming entry + field: 5a always-consumed
# (display_name), 5b Alpha-deferred (storage_category) — TR-028
# ---------------------------------------------------------------------------

func test_missing_display_name_halts_naming_entry_and_field() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("missing_display_name")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_MISSING_REQUIRED_FIELD
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid004_no_name")
	assert_str(String(issue["field"])).is_equal("display_name")


func test_missing_storage_category_halts_naming_entry_and_field() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("missing_storage_category")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_MISSING_REQUIRED_FIELD
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid004_no_storage")
	assert_str(String(issue["field"])).is_equal("storage_category")


# ---------------------------------------------------------------------------
# AC — category<->material_family pairing: building_material + family none
# (24a), non-building-material + family set (24b) — TR-051
# ---------------------------------------------------------------------------

func test_building_material_with_family_none_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("pairing_building_material_family_none")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_CATEGORY_FAMILY_PAIRING
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid004_family_none")
	assert_str(String(issue["field"])).is_equal("material_family")


func test_non_building_material_with_family_set_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("pairing_non_building_family_set")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_CATEGORY_FAMILY_PAIRING
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid004_furniture_with_family")
	assert_str(String(issue["field"])).is_equal("material_family")


# ---------------------------------------------------------------------------
# AC — negative or non-integer tier halts naming the entry (GDD AC23) —
# TR-050
# ---------------------------------------------------------------------------

func test_negative_tier_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("tier_negative")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_INVALID_TIER
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid004_negative_tier")
	assert_str(String(issue["field"])).is_equal("tier")


## Deviation regression test (see this story's implementation report and
## the class doc comment on `resource_item_database.gd`): a fixture
## authoring `tier = 1.5` against the schema's statically `int`-typed
## `@export var tier: int` field is silently coerced (truncated) to `1` by
## Godot's resource deserializer BEFORE this pipeline ever inspects the
## value — there is no runtime code path by which a non-integer tier can
## reach the validation pipeline. This test proves that engine fact (rather
## than silently omitting AC23's non-integer sub-case): boot SUCCEEDS, the
## loaded tier is exactly `1`, and no `invalid_tier` issue is (or could be)
## raised for it.
func test_tier_authored_as_non_integer_is_coerced_to_int_by_the_engine_before_validation_runs() -> void:
	# Act
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join("tier_non_integer") + "/"
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert — boot succeeds; the fractional value never reaches validation.
	assert_bool(bool(result["success"])).is_true()
	assert_array(result["issues"] as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	var coerced: ItemDefinition = db.get_by_id(&"rid004_fractional_tier")
	assert_object(coerced).is_not_null()
	assert_int(coerced.get_tier()).is_equal(1)


# ---------------------------------------------------------------------------
# AC — stackable entry with max_stack_size < 1 halts (GDD AC20) — TR-049;
# non-stackable entry with max_stack_size authored succeeds SILENTLY, no
# warning (GDD AC21) — TR-043
# ---------------------------------------------------------------------------

func test_stackable_entry_with_max_stack_size_zero_halts_naming_the_entry() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("stack_zero")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_INVALID_MAX_STACK_SIZE
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid004_stack_zero")
	assert_str(String(issue["field"])).is_equal("max_stack_size")


func test_non_stackable_entry_with_max_stack_size_authored_succeeds_silently_no_warning() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join("stack_non_stackable_authored") + "/"

	# Act + Assert — zero runtime warnings/errors during setup(), and the
	# structured result carries zero issues (GDD Edge Case 7 / AC21: a
	# warning here would be guaranteed noise, since max_stack_size is
	# required-present on every entry). The result is captured via an
	# Array `append` from inside the closure -- a plain scalar assignment
	# to an outer `var` from within a lambda does not write back in
	# GDScript (only in-place mutation of a captured reference does).
	var captured: Array = []
	await assert_error(
		func() -> void:
			@warning_ignore("unsafe_method_access")
			captured.append(db.setup())
	).is_success()
	var result: Dictionary = captured[0]
	assert_bool(bool(result["success"])).is_true()
	assert_array(result["issues"] as Array).is_empty()


# ---------------------------------------------------------------------------
# AC — the pipeline runs over ALL entries and does not short-circuit on the
# first failure (GDD "Validating" pipeline / TR-005; a lighter 2-violation-
# class proof feeding the same invariant story 005 proves at N=3)
# ---------------------------------------------------------------------------

func test_pipeline_reports_every_invalid_entry_not_just_the_first() -> void:
	# Act — two entries violating two DIFFERENT check classes in the same
	# data_dir (unknown category vs. missing display_name).
	var result: Dictionary = _run_setup_against_scenario("no_short_circuit")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var issues: Array = result["issues"] as Array
	var category_matches: Array = _issues_with_check(
		issues, ResourceItemDatabaseScript.CHECK_UNKNOWN_CATEGORY
	)
	var missing_field_matches: Array = _issues_with_check(
		issues, ResourceItemDatabaseScript.CHECK_MISSING_REQUIRED_FIELD
	)
	assert_array(category_matches).has_size(1)
	assert_str(String((category_matches[0] as Dictionary)["entry_id"])).is_equal("rid004_bad_category")
	assert_array(missing_field_matches).has_size(1)
	assert_str(String((missing_field_matches[0] as Dictionary)["entry_id"])).is_equal("rid004_bad_display_name")


# ---------------------------------------------------------------------------
# Structured-result shape — every record carries entry id, source file,
# violated check, and offending field (GDD Validation-result contract /
# TR-007) — never a log string.
# ---------------------------------------------------------------------------

func test_every_issue_record_is_a_structured_dictionary_never_a_string() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("id_uppercase")

	# Assert
	for issue: Variant in (result["issues"] as Array):
		assert_bool(issue is Dictionary).is_true()
		var record: Dictionary = issue as Dictionary
		assert_bool(record.has("entry_id")).is_true()
		assert_bool(record.has("source_file")).is_true()
		assert_bool(record.has("check")).is_true()
		assert_bool(record.has("field")).is_true()


# ---------------------------------------------------------------------------
# Existing (rid-002) fixture sets remain green under the extended pipeline
# — regression guard proving the new checks don't reject already-valid
# authored data.
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
