## Unit test — Resource & Item Database Story rid-005 (boot validation:
## reserved ids/category, retired-ids ledger, tier-0 family coverage,
## aggregate report + terminal Failed exposure).
##
## Proves the real ResourceItemDatabase script's CROSS-CATALOG invariants
## layered on top of rid-004's per-entry pipeline: authored `missing_item`
## (10a) / category `missing` (10b) halt boot (GDD AC10, TR-030); a new
## entry whose id appears in the retired-ids ledger halts naming the entry
## and the ledger conflict (GDD AC11, TR-042); a data set whose tier-0
## `building_material` entries do not cover every material family halts
## naming the uncovered family (GDD AC25, TR-031); THREE independent
## invalid entries of three different violation classes are ALL named, not
## just the first (GDD AC7, TR-035); and on Failed, the database exposes
## the structured validation result as PERSISTENT state, stays permanently
## non-Ready for the session, and never partially answers a query (GDD
## AC26, TR-006/007). Each scenario uses its own isolated fixture directory
## (`fixtures/invariants/<scenario>/`), mirroring
## `ResourceItemDatabaseValidationSchemaChecksTest`'s pattern — zero scene
## tree, zero Autoload registration.
##
## Story rid-005 does NOT own: per-entry schema checks (Story 004);
## `visual_asset` resolution (Story 006); the `missing_item` fallback
## definition (Story 007); `footprint` validation (Story 008).
class_name ResourceItemDatabaseValidationInvariantsTerminalTest
extends GdUnitTestSuite

const ResourceItemDatabaseScript: GDScript = preload("res://src/resource_item_database/resource_item_database.gd")
const _FIXTURE_ROOT: String = "res://tests/integration/resource_item_database/fixtures/invariants/"


## Returns a fresh, never-autoloaded ResourceItemDatabase-script instance.
## Untyped return — the script deliberately carries no `class_name` (see its
## own doc comment), so isolated instances are constructed via a preloaded
## [GDScript] and duck-typed at each access site, mirroring
## `ResourceItemDatabaseValidationSchemaChecksTest._new_database()`.
func _new_database() -> Object:
	return ResourceItemDatabaseScript.new()


## Runs `setup()` against the named fixture scenario subdirectory (an
## entries-only scenario — no ledger override) and returns the raw
## `{"success": bool, "issues": Array}` result.
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
# AC-1 — reserved id `missing_item` (10a) / reserved category `missing`
# (10b) each independently halt boot (GDD AC10) — TR-030
# ---------------------------------------------------------------------------

func test_authored_missing_item_id_halts_naming_reserved_id() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("reserved_id")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_RESERVED_ID
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("missing_item")
	assert_str(String(issue["field"])).is_equal("id")


func test_authored_missing_category_halts_naming_reserved_category() -> void:
	# Act
	var result: Dictionary = _run_setup_against_scenario("reserved_category")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_RESERVED_CATEGORY
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("rid005_reserved_category_entry")
	assert_str(String(issue["field"])).is_equal("category")
	# The reserved-category check is exclusive with the unknown-category
	# check for the same root cause (see the script's doc comment) — never
	# double-reported.
	var unknown_category_matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_UNKNOWN_CATEGORY
	)
	assert_array(unknown_category_matches).is_empty()


# ---------------------------------------------------------------------------
# AC-2 — a new entry whose id appears in the retired-ids ledger halts,
# naming the entry and the ledger conflict (GDD AC11) — TR-042
# ---------------------------------------------------------------------------

func test_new_entry_matching_retired_ledger_id_halts_naming_entry_and_ledger_conflict() -> void:
	# Arrange — synthetic ledger listing `old_plank`; a new entry also
	# authored with id `old_plank` (the shipped MVP ledger itself is empty —
	# this fixture ledger exists only for this test, per the GDD/QA plan).
	var scenario_dir: String = _FIXTURE_ROOT.path_join("retired_ledger_conflict")
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = scenario_dir.path_join("entries") + "/"
	@warning_ignore("unsafe_property_access")
	db.ledger_path = scenario_dir.path_join("ledger").path_join("rid005_retired_ledger.tres")

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_RETIRED_ID_CONFLICT
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["entry_id"])).is_equal("old_plank")
	assert_str(String(issue["field"])).is_equal("id")
	assert_str(issue["source_file"] as String).contains("old_plank")


func test_missing_or_unauthored_ledger_path_degrades_to_zero_retired_ids_not_a_failure() -> void:
	# Arrange — a valid data_dir but a ledger_path that resolves to nothing
	# (mirrors production before any ledger content is authored — GDD: "the
	# shipped MVP ledger is empty").
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join("tier0_coverage_missing_family") + "/"
	@warning_ignore("unsafe_property_access")
	db.ledger_path = "res://tests/integration/resource_item_database/fixtures/invariants/does_not_exist.tres"

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert — no retired_id_conflict issue is even possible; whatever
	# issues exist come from elsewhere (this scenario's own tier-0 coverage
	# gap), never from the missing ledger file itself.
	var ledger_matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_RETIRED_ID_CONFLICT
	)
	assert_array(ledger_matches).is_empty()


# ---------------------------------------------------------------------------
# AC-3 — tier-0 `building_material` family coverage gap halts, naming the
# uncovered family (GDD AC25 / Core Rule 6) — TR-031
# ---------------------------------------------------------------------------

func test_tier0_coverage_gap_halts_naming_the_uncovered_family() -> void:
	# Act — wood + stone tier-0 building materials authored, no thatch.
	var result: Dictionary = _run_setup_against_scenario("tier0_coverage_missing_family")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var matches: Array = _issues_with_check(
		result["issues"] as Array, ResourceItemDatabaseScript.CHECK_TIER0_COVERAGE_GAP
	)
	assert_array(matches).has_size(1)
	var issue: Dictionary = matches[0]
	assert_str(String(issue["field"])).is_equal("material_family")
	assert_str(String(issue["missing_family"])).is_equal("thatch")


# ---------------------------------------------------------------------------
# AC-4 — THREE independent invalid entries of three different violation
# classes are ALL named, not just the first (GDD AC7) — TR-035
# ---------------------------------------------------------------------------

func test_three_independent_violation_classes_all_named_in_aggregate_result() -> void:
	# Act — missing display_name + unknown category + duplicate id (across
	# 2 files), plus one clean filler entry that only exists to keep tier-0
	# family coverage satisfied so the coverage check doesn't add a fourth,
	# unintended violation class to this specific proof.
	var result: Dictionary = _run_setup_against_scenario("aggregate_three_violations")

	# Assert
	assert_bool(bool(result["success"])).is_false()
	var issues: Array = result["issues"] as Array

	var missing_field_matches: Array = _issues_with_check(
		issues, ResourceItemDatabaseScript.CHECK_MISSING_REQUIRED_FIELD
	)
	assert_array(missing_field_matches).has_size(1)
	assert_str(String((missing_field_matches[0] as Dictionary)["entry_id"])).is_equal("rid005_agg_missing_field")

	var unknown_category_matches: Array = _issues_with_check(
		issues, ResourceItemDatabaseScript.CHECK_UNKNOWN_CATEGORY
	)
	assert_array(unknown_category_matches).has_size(1)
	assert_str(String((unknown_category_matches[0] as Dictionary)["entry_id"])).is_equal("rid005_agg_unknown_category")

	var duplicate_matches: Array = _issues_with_check(
		issues, ResourceItemDatabaseScript.CHECK_DUPLICATE_ID
	)
	assert_array(duplicate_matches).has_size(2)
	for issue: Dictionary in duplicate_matches:
		assert_str(String(issue["entry_id"])).is_equal("rid005_agg_dup_block")

	# No incidental tier-0-coverage noise — the filler entry keeps the
	# fixture's exact violation-class count provable.
	var coverage_matches: Array = _issues_with_check(
		issues, ResourceItemDatabaseScript.CHECK_TIER0_COVERAGE_GAP
	)
	assert_array(coverage_matches).is_empty()


# ---------------------------------------------------------------------------
# AC-5 — on Failed, the database exposes the structured validation result
# as PERSISTENT state, stays permanently non-Ready, and never partially
# answers a query (GDD AC26) — TR-006/007
# ---------------------------------------------------------------------------

func test_get_validation_result_before_setup_returns_neutral_result() -> void:
	# Arrange — setup() never called.
	var db: Object = auto_free(_new_database())

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.get_validation_result()

	# Assert
	assert_bool(bool(result["success"])).is_false()
	assert_array(result["issues"] as Array).is_empty()


func test_get_validation_result_exposes_structured_result_after_failed_and_stays_non_ready() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join("terminal_failed") + "/"

	# Act — setup()'s own return value is intentionally NOT captured here;
	# the point of this test is that the result is independently EXPOSED as
	# state afterward, not merely returned once.
	@warning_ignore("unsafe_method_access", "return_value_discarded")
	db.setup()

	# Assert
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_false()
	@warning_ignore("unsafe_method_access")
	var exposed: Dictionary = db.get_validation_result()
	assert_bool(bool(exposed["success"])).is_false()
	var issues: Array = exposed["issues"] as Array
	assert_array(issues).is_not_empty()
	var record: Dictionary = issues[0]
	assert_bool(record.has("entry_id")).is_true()
	assert_bool(record.has("source_file")).is_true()
	assert_bool(record.has("check")).is_true()
	assert_bool(record.has("field")).is_true()
	assert_str(String(record["entry_id"])).is_equal("rid005_terminal_invalid")


func test_after_failed_every_query_returns_explicit_error_never_partial_data() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _FIXTURE_ROOT.path_join("terminal_failed") + "/"
	@warning_ignore("unsafe_method_access")
	db.setup()
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_false()

	# Act + Assert — every read surface refuses, never a partial answer.
	@warning_ignore("unsafe_method_access")
	assert_object(db.get_by_id(&"rid005_terminal_invalid") as ItemDefinition).is_null()
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_ids_by_category(&"building_material") as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_ids_by_material_family(&"wood") as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_ids_by_tier(0) as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	assert_array(db.list_all_ids() as Array).is_empty()

	# The Failed state is terminal for the session — a second setup() call
	# is rejected and the originally-exposed result is left untouched.
	@warning_ignore("unsafe_method_access")
	var first_exposed: Dictionary = db.get_validation_result()
	@warning_ignore("unsafe_method_access")
	db.setup()
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_false()
	@warning_ignore("unsafe_method_access")
	var second_exposed: Dictionary = db.get_validation_result()
	assert_array(second_exposed["issues"] as Array).is_equal(first_exposed["issues"] as Array)


func test_get_validation_result_reflects_ready_state_when_setup_succeeds() -> void:
	# Arrange — the rid-003 lookup fixture set already carries full tier-0
	# family coverage (wood/stone/thatch), so it stays Ready under the
	# extended pipeline (regression-proven in
	# ResourceItemDatabaseValidationSchemaChecksTest).
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = "res://tests/integration/resource_item_database/fixtures/lookup/"

	# Act
	@warning_ignore("unsafe_method_access")
	db.setup()

	# Assert
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_true()
	@warning_ignore("unsafe_method_access")
	var exposed: Dictionary = db.get_validation_result()
	assert_bool(bool(exposed["success"])).is_true()
	assert_array(exposed["issues"] as Array).is_empty()
