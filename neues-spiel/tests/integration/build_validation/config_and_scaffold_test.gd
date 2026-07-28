## Integration test — Build Validation & Navigability story
## build-validation-001 (config resource, DI scaffold, blocking lockstep
## invariant; ADR-0002 primary, ADR-0001/0005 secondary; TD ruling BV-4 —
## `production/architecture-decisions-m02-preflight-2026-07-26.md`).
##
## Proves:
## 1. [BuildValidationConfig] exports exactly the 4 Tuning Knobs this story's
##    AC list names, each at its GDD default, stored as a `.tres`.
## 2. AC27 (BLOCKING): `max_room_height` below the Building System's max
##    `wall_height` ([constant WallToolConfig.WALL_HEIGHT_MAX]) fails loudly,
##    naming the lockstep invariant; the boundary (equal) passes; the safe
##    range's floor IS the invariant, by construction (not a duplicated
##    literal).
## 3. `validate()` range-checks every other knob against its GDD safe range —
##    a single-field issue warns + clamps + proceeds (never BLOCKING); both
##    boundaries are inclusive.
## 4. The ladder-ordering invariant (`ground_penalty` < `unsheltered_bed_
##    multiplier` < 1.0) is checked as an ADVISORY courtesy duplicate only —
##    never a boot-halt, independent of (and in addition to) the ordinary
##    single-field clamp.
## 5. [BuildValidation] is instantiable headless via `Node.new()` with mocks
##    assigned directly (no scene tree, no Autoload registration); `setup()`
##    asserts `config`/`voxel_world` are wired, and NEVER asserts a
##    `furniture_registry` (BV-1 §5 — `null` is a valid state) or any
##    walkability provider (BV-4 — there is none to assert).
## 6. Grep guards (comment-stripped source scan, this codebase's established
##    precedent — see `tests/integration/villager_ai/config_and_scaffold_
##    test.gd`'s `_read_all_gd_source` helper): zero `VillagerAi` type
##    reference anywhere in `src/build_validation/` (BV-4); zero duplicated
##    `VILLAGER_CLEARANCE`/`MAX_STEP_HEIGHT` literal or declaration (Rule 2
##    verbatim-consumption); zero `NavigationServer3D`/`NavigationAgent3D`/
##    `NavigationRegion3D` (ADR-0007).
class_name BuildValidationConfigAndScaffoldTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# AC1 — config defaults match the GDD Tuning Knobs, .tres backing
# ---------------------------------------------------------------------------

func test_config_defaults_match_gdd_tuning_knobs() -> void:
	# Arrange + Act
	var config := BuildValidationConfig.new()

	# Assert — design/gdd/build-validation-navigability.md Tuning Knobs.
	assert_int(config.min_room_cells).is_equal(2)
	assert_int(config.max_room_height).is_equal(8)
	assert_float(config.unsheltered_bed_multiplier).is_equal_approx(0.7, 0.0001)
	assert_int(config.room_cue_cooldown_ticks).is_equal(20)

	# Every knob at its GDD default produces zero issues (edge case named in
	# the story's own QA Test Cases).
	assert_array(config.validate()).is_empty()


func test_build_validation_config_tres_loads_and_matches_script_defaults() -> void:
	# Arrange + Act — proves the "stored as a .tres" requirement against the
	# actual authored resource file, not just the script's own initializers.
	var config: BuildValidationConfig = load("res://data/config/build_validation_config.tres")

	# Assert
	assert_object(config).is_not_null()
	assert_int(config.min_room_cells).is_equal(2)
	assert_int(config.max_room_height).is_equal(8)
	assert_float(config.unsheltered_bed_multiplier).is_equal_approx(0.7, 0.0001)
	assert_int(config.room_cue_cooldown_ticks).is_equal(20)


# ---------------------------------------------------------------------------
# AC27 — the blocking lockstep invariant (max_room_height >= wall_height max)
# ---------------------------------------------------------------------------

func test_max_room_height_min_is_lockstep_with_wall_tool_config_by_construction() -> void:
	# Arrange + Act + Assert — the safe range's lower bound IS the invariant,
	# read from the Building System's own locked constant, never a duplicated
	# literal (GDD Tuning Knobs note).
	assert_int(BuildValidationConfig.MAX_ROOM_HEIGHT_MIN).is_equal(WallToolConfig.WALL_HEIGHT_MAX)


func test_validate_max_room_height_below_wall_height_max_is_blocking_and_names_it() -> void:
	# Arrange
	var config := BuildValidationConfig.new()
	config.max_room_height = 7

	# Act
	var issues: Array[String] = config.validate()

	# Assert — exactly one BLOCKING issue, naming the invariant; the field is
	# NOT clamped (the blocking path is reserved for this invariant alone).
	assert_int(issues.size()).is_equal(1)
	assert_bool(issues[0].begins_with(ConfigResource.BLOCKING_PREFIX)).is_true()
	assert_bool(issues[0].contains("wall_height")).is_true()
	assert_bool(issues[0].contains("max_room_height")).is_true()
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()
	assert_int(config.max_room_height).is_equal(7)


func test_validate_max_room_height_at_lockstep_boundary_passes() -> void:
	# Arrange — boundary is inclusive: 8 == WallToolConfig.WALL_HEIGHT_MAX.
	var config := BuildValidationConfig.new()
	config.max_room_height = 8

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_array(issues).is_empty()
	assert_int(config.max_room_height).is_equal(8)


func test_validate_max_room_height_above_safe_max_clamps_and_warns_not_blocking() -> void:
	# Arrange
	var config := BuildValidationConfig.new()
	config.max_room_height = 17

	# Act
	var issues: Array[String] = config.validate()

	# Assert — a single-field range issue at the UPPER bound is an ordinary
	# clamp+warn, never BLOCKING (only the lower/lockstep bound is BLOCKING).
	assert_int(issues.size()).is_equal(1)
	assert_bool(issues[0].begins_with(ConfigResource.BLOCKING_PREFIX)).is_false()
	assert_int(config.max_room_height).is_equal(16)


func test_validate_max_room_height_at_upper_safe_boundary_no_issues() -> void:
	# Arrange
	var config := BuildValidationConfig.new()
	config.max_room_height = 16

	# Act + Assert
	assert_array(config.validate()).is_empty()


func test_validate_blocking_issue_mixed_with_clamp_warnings_still_dominates() -> void:
	# Arrange — a BLOCKING invariant failure alongside an unrelated
	# single-field clamp warning; has_blocking_issue() must still read true.
	var config := BuildValidationConfig.new()
	config.max_room_height = 7
	config.min_room_cells = 0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(2)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


# ---------------------------------------------------------------------------
# Single-field range checks — min_room_cells / room_cue_cooldown_ticks
# (unsheltered_bed_multiplier is covered separately below, since its
# out-of-range cases interact with the advisory ladder check)
# ---------------------------------------------------------------------------

## One row per plain single-field knob: [field name, min, max, below, above].
const KNOB_CASES: Array[Array] = [
	["min_room_cells", BuildValidationConfig.MIN_ROOM_CELLS_MIN, BuildValidationConfig.MIN_ROOM_CELLS_MAX, 0, 10],
	["room_cue_cooldown_ticks", BuildValidationConfig.ROOM_CUE_COOLDOWN_TICKS_MIN, BuildValidationConfig.ROOM_CUE_COOLDOWN_TICKS_MAX, -1, 121],
]


func test_validate_every_plain_knob_below_min_clamps_and_warns() -> void:
	for case: Array in KNOB_CASES:
		var field: String = case[0]
		var min_value: Variant = case[1]
		var below_value: Variant = case[3]

		var config := BuildValidationConfig.new()
		config.set(field, below_value)

		var issues: Array[String] = config.validate()

		assert_int(issues.size()).is_equal(1).override_failure_message(
			"field '%s': expected exactly 1 issue, got %s" % [field, issues]
		)
		assert_int(config.get(field)).is_equal(int(min_value))


func test_validate_every_plain_knob_above_max_clamps_and_warns() -> void:
	for case: Array in KNOB_CASES:
		var field: String = case[0]
		var max_value: Variant = case[2]
		var above_value: Variant = case[4]

		var config := BuildValidationConfig.new()
		config.set(field, above_value)

		var issues: Array[String] = config.validate()

		assert_int(issues.size()).is_equal(1).override_failure_message(
			"field '%s': expected exactly 1 issue, got %s" % [field, issues]
		)
		assert_int(config.get(field)).is_equal(int(max_value))


func test_validate_every_plain_knob_at_min_boundary_is_inclusive_no_warning() -> void:
	for case: Array in KNOB_CASES:
		var field: String = case[0]
		var min_value: Variant = case[1]

		var config := BuildValidationConfig.new()
		config.set(field, min_value)

		var issues: Array[String] = config.validate()

		assert_array(issues).is_empty().override_failure_message(
			"field '%s' at min boundary %s produced issues: %s" % [field, min_value, issues]
		)


func test_validate_every_plain_knob_at_max_boundary_is_inclusive_no_warning() -> void:
	for case: Array in KNOB_CASES:
		var field: String = case[0]
		var max_value: Variant = case[2]

		var config := BuildValidationConfig.new()
		config.set(field, max_value)

		var issues: Array[String] = config.validate()

		assert_array(issues).is_empty().override_failure_message(
			"field '%s' at max boundary %s produced issues: %s" % [field, max_value, issues]
		)


# ---------------------------------------------------------------------------
# unsheltered_bed_multiplier — single-field range AND the advisory ladder
# check (independent, may both fire on the same out-of-range value)
# ---------------------------------------------------------------------------

func test_validate_unsheltered_bed_multiplier_below_min_clamps_and_triggers_advisory() -> void:
	# Arrange — mirrors the story's own QA Test Case: 0.3 with the module's
	# ground_penalty advisory reference (0.4).
	var config := BuildValidationConfig.new()
	config.unsheltered_bed_multiplier = 0.3

	# Act
	var issues: Array[String] = config.validate()

	# Assert — TWO issues: the ordinary clamp warning AND the advisory
	# ladder-order warning; neither is BLOCKING; the field is clamped.
	assert_int(issues.size()).is_equal(2)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	var has_advisory: bool = false
	for issue: String in issues:
		if issue.begins_with("ADVISORY: "):
			has_advisory = true
	assert_bool(has_advisory).is_true()
	assert_float(config.unsheltered_bed_multiplier).is_equal_approx(0.5, 0.0001)


func test_validate_unsheltered_bed_multiplier_above_max_clamps_no_advisory() -> void:
	# Arrange — above the safe range but still well inside the advisory
	# ordering (0.4 < 0.95 < 1.0 holds), so only the ordinary clamp warning
	# should fire.
	var config := BuildValidationConfig.new()
	config.unsheltered_bed_multiplier = 0.95

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(issues[0].begins_with("ADVISORY: ")).is_false()
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.unsheltered_bed_multiplier).is_equal_approx(0.9, 0.0001)


func test_validate_unsheltered_bed_multiplier_at_min_boundary_no_issues() -> void:
	var config := BuildValidationConfig.new()
	config.unsheltered_bed_multiplier = 0.5

	assert_array(config.validate()).is_empty()


func test_validate_unsheltered_bed_multiplier_at_max_boundary_no_issues() -> void:
	var config := BuildValidationConfig.new()
	config.unsheltered_bed_multiplier = 0.9

	assert_array(config.validate()).is_empty()


# ---------------------------------------------------------------------------
# Headless DI (Node.new() + mocks, zero scene tree, zero Autoload)
# ---------------------------------------------------------------------------

func test_build_validation_setup_headless_with_mocks_succeeds_no_scene_tree() -> void:
	# Arrange
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = auto_free(VoxelWorldGrid.new())
	assert_bool(bv.is_set_up()).is_false()

	# Act
	bv.setup()

	# Assert
	assert_bool(bv.is_set_up()).is_true()
	assert_array(bv.get_boot_blocking_issues()).is_empty()


func test_build_validation_setup_missing_config_raises_assertion() -> void:
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.voxel_world = auto_free(VoxelWorldGrid.new())

	await assert_error(func() -> void: bv.setup()).is_runtime_error(
		"Assertion failed: BuildValidation.config not wired"
	)


func test_build_validation_setup_missing_voxel_world_raises_assertion() -> void:
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()

	await assert_error(func() -> void: bv.setup()).is_runtime_error(
		"Assertion failed: BuildValidation.voxel_world not wired"
	)


func test_build_validation_setup_with_null_furniture_registry_succeeds() -> void:
	# Arrange — BV-1 §5: null means "no furniture exists," a valid default,
	# never asserted.
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = auto_free(VoxelWorldGrid.new())
	assert_object(bv.furniture_registry).is_null()

	# Act
	bv.setup()

	# Assert
	assert_bool(bv.is_set_up()).is_true()
	assert_object(bv.furniture_registry).is_null()


func test_build_validation_setup_records_blocking_issue_for_boot_gate_without_asserting() -> void:
	# Arrange — a BLOCKING config invariant must be RECORDED for GameWorld's
	# boot gate (ADR-0005), not thrown as an assertion inside setup() itself.
	var bv: BuildValidation = auto_free(BuildValidation.new())
	var config := BuildValidationConfig.new()
	config.max_room_height = 7
	bv.config = config
	bv.voxel_world = auto_free(VoxelWorldGrid.new())

	# Act
	bv.setup()

	# Assert — setup() itself completed (no thrown assertion); the BLOCKING
	# issue is queryable via get_boot_blocking_issues().
	assert_bool(bv.is_set_up()).is_true()
	var blocking: Array[String] = bv.get_boot_blocking_issues()
	assert_int(blocking.size()).is_equal(1)
	assert_bool(blocking[0].begins_with(ConfigResource.BLOCKING_PREFIX)).is_true()


func test_voxel_world_dependency_also_serves_as_the_structural_change_signal_source() -> void:
	# Arrange + Act + Assert — the same injected voxel_world reference is
	# capable of serving BOTH roles this story's AC names separately (no
	# second @export field exists, or is needed, for the signal source —
	# see class doc comment). Story 005 performs the actual subscription;
	# this only proves the single dependency is signal-capable.
	var bv: BuildValidation = auto_free(BuildValidation.new())
	bv.config = BuildValidationConfig.new()
	bv.voxel_world = auto_free(VoxelWorldGrid.new())
	bv.setup()

	assert_bool(bv.voxel_world.has_signal(&"cells_changed_batch")).is_true()


# ---------------------------------------------------------------------------
# Grep guards — no duplicated constants, no VillagerAi reference (BV-4),
# no NavigationServer3D family (ADR-0007)
# ---------------------------------------------------------------------------

func test_no_villager_clearance_or_max_step_height_literal_in_module() -> void:
	var source: String = _read_all_gd_source("res://src/build_validation")

	assert_bool(source.contains("VILLAGER_CLEARANCE")).is_false()
	assert_bool(source.contains("MAX_STEP_HEIGHT")).is_false()


func test_no_villager_ai_type_reference_anywhere_in_module() -> void:
	# Grep-verifiable AC (BV-4): the walkability call form is
	# VillagerWalkabilityRules.<fn>(voxel_world, ...), never an injected
	# VillagerAi reference of any kind.
	var source: String = _read_all_gd_source("res://src/build_validation")

	assert_bool(source.contains("VillagerAi")).is_false()


func test_no_navigation_server_apis_anywhere_in_module() -> void:
	var source: String = _read_all_gd_source("res://src/build_validation")

	var banned_substrings: Array[String] = [
		"NavigationServer3D",
		"NavigationAgent3D",
		"NavigationRegion3D",
	]
	for banned: String in banned_substrings:
		assert_bool(source.contains(banned)).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads and concatenates every `.gd` source file directly under
## [param dir_path] (non-recursive), STRIPPING full-line `#`/`##`
## doc-comment lines first. Mirrors
## `tests/integration/villager_ai/config_and_scaffold_test.gd`'s
## `_read_all_gd_source` helper (this codebase's established precedent) —
## this class's own doc comments legitimately name the banned APIs to
## document that they are forbidden, so a naive raw-text scan would flag its
## own compliance documentation as a violation.
func _read_all_gd_source(dir_path: String) -> String:
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
