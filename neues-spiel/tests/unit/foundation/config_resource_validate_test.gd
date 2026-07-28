## Unit test — Foundation Spine Story 003 (ADR-0002 Config Resource base
## pattern + validate() two-tier clamp/halt policy).
##
## Proves three layers of the pattern, all against [ReferenceModuleConfig] /
## [ReferenceConfigConsumer] (Foundation Spine's own reference/example
## classes -- concrete per-module configs are authored in their own epics):
## 1. [ConfigResource]'s shared [method ConfigResource.has_blocking_issue]
##    helper and [constant ConfigResource.BLOCKING_PREFIX] convention.
## 2. [ReferenceModuleConfig.validate]'s two tiers in isolation (AC-3
##    valid/clamp-warn, AC-4 blocking), constructed via [code].new()[/code] +
##    direct field assignment -- zero file I/O, per ADR-0002's testability
##    requirement.
## 3. The full wiring end-to-end: [ReferenceConfigConsumer.setup] applying
##    the two-tier policy, and [GameWorld]'s boot gate (ADR-0005) reusing its
##    terminal RID-Failed halt path for a GDD-declared BLOCKING config
##    invariant (AC-4's "same path as RID-Failed" requirement).
class_name ConfigResourceValidateTest
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# ConfigResource shared helpers
# ---------------------------------------------------------------------------

func test_config_resource_has_blocking_issue_empty_array_returns_false() -> void:
	# Arrange
	var issues: Array[String] = []

	# Act + Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()


func test_config_resource_has_blocking_issue_warnings_only_returns_false() -> void:
	# Arrange
	var issues: Array[String] = ["some_knob out of range, got 99 -- clamped"]

	# Act + Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()


func test_config_resource_has_blocking_issue_blocking_entry_returns_true() -> void:
	# Arrange
	var issues: Array[String] = [ConfigResource.format_blocking("lower must be < upper")]

	# Act + Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_config_resource_format_blocking_prefixes_message() -> void:
	# Arrange + Act
	var formatted: String = ConfigResource.format_blocking("lower must be < upper")

	# Assert
	assert_str(formatted).is_equal("BLOCKING: lower must be < upper")


# ---------------------------------------------------------------------------
# ReferenceModuleConfig.validate() — AC-3 (valid / single-field clamp+warn)
# ---------------------------------------------------------------------------

func test_reference_module_config_validate_gdd_defaults_returns_empty() -> void:
	# Arrange — trivially constructed via .new(), no file I/O (ADR-0002
	# testability requirement).
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_array(issues).is_empty()


func test_reference_module_config_validate_boundary_values_returns_empty() -> void:
	# Arrange — exactly at the safe-range edges.
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.cadence_seconds = ReferenceModuleConfig.CADENCE_MIN

	# Act
	var issues_at_min: Array[String] = config.validate()
	config.cadence_seconds = ReferenceModuleConfig.CADENCE_MAX
	var issues_at_max: Array[String] = config.validate()

	# Assert
	assert_array(issues_at_min).is_empty()
	assert_array(issues_at_max).is_empty()


func test_reference_module_config_validate_below_min_clamps_and_warns() -> void:
	# Arrange
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.cadence_seconds = -5.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert — warned, clamped to the min bound, no blocking tag, boot proceeds.
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.cadence_seconds).is_equal(ReferenceModuleConfig.CADENCE_MIN)


func test_reference_module_config_validate_above_max_clamps_and_warns() -> void:
	# Arrange
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.cadence_seconds = 500.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()
	assert_float(config.cadence_seconds).is_equal(ReferenceModuleConfig.CADENCE_MAX)


# ---------------------------------------------------------------------------
# ReferenceModuleConfig.validate() — AC-4 (BLOCKING cross-value invariant)
# ---------------------------------------------------------------------------

func test_reference_module_config_validate_blocking_invariant_violated_is_tagged() -> void:
	# Arrange
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.lower_bound = 50.0
	config.upper_bound = 10.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_reference_module_config_validate_blocking_invariant_equal_bounds_still_blocks() -> void:
	# Arrange — the invariant is strict "<"; equal bounds still violate it.
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.lower_bound = 10.0
	config.upper_bound = 10.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_reference_module_config_validate_warning_alongside_blocking_still_dominates() -> void:
	# Arrange — a single-field warning AND a blocking failure in the same
	# validate() call: blocking must still be detected (QA plan edge case).
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.cadence_seconds = -5.0
	config.lower_bound = 50.0
	config.upper_bound = 10.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(2)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()
	assert_float(config.cadence_seconds).is_equal(ReferenceModuleConfig.CADENCE_MIN)


# ---------------------------------------------------------------------------
# ReferenceConfigConsumer.setup() — the injected-tier wiring (AC-2/AC-3/AC-4)
# ---------------------------------------------------------------------------

func test_reference_config_consumer_setup_valid_config_no_blocking_issues() -> void:
	# Arrange
	var consumer: ReferenceConfigConsumer = auto_free(ReferenceConfigConsumer.new())
	consumer.config = ReferenceModuleConfig.new()

	# Act
	consumer.setup()

	# Assert
	assert_bool(consumer.is_set_up()).is_true()
	assert_array(consumer.get_boot_blocking_issues()).is_empty()


func test_reference_config_consumer_setup_out_of_range_scalar_clamps_no_blocking() -> void:
	# Arrange
	var consumer: ReferenceConfigConsumer = auto_free(ReferenceConfigConsumer.new())
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.cadence_seconds = -5.0
	consumer.config = config

	# Act
	consumer.setup()

	# Assert — clamp+warn tier: setup completes, no blocking issues reported.
	assert_bool(consumer.is_set_up()).is_true()
	assert_array(consumer.get_boot_blocking_issues()).is_empty()
	assert_float(config.cadence_seconds).is_equal(ReferenceModuleConfig.CADENCE_MIN)


func test_reference_config_consumer_setup_blocking_invariant_reports_issue() -> void:
	# Arrange
	var consumer: ReferenceConfigConsumer = auto_free(ReferenceConfigConsumer.new())
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.lower_bound = 50.0
	config.upper_bound = 10.0
	consumer.config = config

	# Act
	consumer.setup()

	# Assert
	assert_bool(consumer.is_set_up()).is_true()
	assert_bool(ConfigResource.has_blocking_issue(consumer.get_boot_blocking_issues())).is_true()


func test_reference_config_consumer_setup_missing_config_raises_assertion() -> void:
	# Arrange
	var consumer: ReferenceConfigConsumer = auto_free(ReferenceConfigConsumer.new())

	# Act + Assert
	await assert_error(func() -> void: consumer.setup()).is_runtime_error(
		"Assertion failed: ReferenceConfigConsumer.config not wired"
	)


# ---------------------------------------------------------------------------
# GameWorld boot gate — AC-4 end-to-end (reuses the RID-Failed terminal halt)
# ---------------------------------------------------------------------------

func test_game_world_boot_gate_config_blocking_invariant_halts_via_terminal_path() -> void:
	# Arrange — a Ready RID (config validation runs during WIRING, same as
	# ADR-0005 Decision §3) with one injected-tier module whose config has a
	# GDD-declared BLOCKING invariant violated.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	var consumer: ReferenceConfigConsumer = auto_free(ReferenceConfigConsumer.new())
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.lower_bound = 50.0
	config.upper_bound = 10.0
	consumer.config = config
	world.add_child(consumer)
	world.injected_tier_modules = [consumer]
	var received_calls: Array = []
	world.boot_halted.connect(func(issues: Array) -> void:
		received_calls.append(issues))

	# Act — entering the tree fires GameWorld._ready(); RID is already Ready,
	# so WIRING calls consumer.setup() synchronously in the same frame.
	add_child(world)

	# Assert — same terminal path as RID-Failed: HALTED, boot_halted fired,
	# never ACTIVE.
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_int(received_calls.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(received_calls[0])).is_true()


func test_game_world_boot_gate_config_valid_module_reaches_active() -> void:
	# Arrange — regression guard: a valid config must not prevent the
	# existing Ready path from reaching ACTIVE.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	var consumer: ReferenceConfigConsumer = auto_free(ReferenceConfigConsumer.new())
	consumer.config = ReferenceModuleConfig.new()
	world.add_child(consumer)
	world.injected_tier_modules = [consumer]

	# Act
	add_child(world)

	# Assert
	assert_bool(consumer.is_set_up()).is_true()
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
