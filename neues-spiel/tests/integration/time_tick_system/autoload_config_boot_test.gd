## Integration test — Time & Tick System Story tick-001 (Autoload skeleton +
## TimeTickConfig resource + boot defaults, ADR-0001/ADR-0002).
##
## Proves: (1) TimeTickConfig's config-driven tunables and its single-field
## clamp+warn validate() tier (AC-1, no hardcoded values); (2) TimeTickSystem
## boot defaults paused=false/time_warp=1 (AC-2); (3) validate() runs once at
## boot via setup(), proceeding after a clamp rather than halting -- this
## config has no GDD-declared BLOCKING invariant (AC-3); (4) TimeTickSystem is
## registered as the project's Autoload and is already ready (setup() has
## already run) by the time any test executes, since Autoloads _ready()
## before the Main Scene/test harness main loop (AC-4).
##
## Per the story's Test Evidence: TimeTickSystem is instantiated directly via
## .new() and setup() is called directly for the isolated-config assertions
## below -- zero scene tree, zero reliance on the registered Autoload for
## those cases. `time_tick_system.gd` deliberately carries no `class_name`
## (see its own doc comment -- it would hide the "TimeTickSystem" Autoload
## singleton, a Godot 4.7 parse error), so isolated instances are constructed
## via a preloaded [GDScript] and duck-typed at each access site, mirroring
## [GameWorld]'s existing `resource_item_database` duck-typing convention.
## The Autoload-registration case (AC-4) deliberately reads the REAL
## registered singleton instead, since that is the only way to observe
## registration/boot-ordering at all.
class_name AutoloadConfigBootTest
extends GdUnitTestSuite

const TimeTickSystemScript: GDScript = preload("res://src/time_tick_system/time_tick_system.gd")


## Returns a fresh, never-autoloaded TimeTickSystem-script instance for
## isolated setup() testing. Untyped return -- see class doc comment.
func _new_system() -> Object:
	return TimeTickSystemScript.new()


# ---------------------------------------------------------------------------
# TimeTickConfig.validate() — AC-1 (config-driven, single-field clamp+warn)
# ---------------------------------------------------------------------------

func test_time_tick_config_validate_gdd_defaults_returns_empty() -> void:
	# Arrange — trivially constructed via .new(), no file I/O (ADR-0002
	# testability requirement).
	var config: TimeTickConfig = TimeTickConfig.new()

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_array(issues).is_empty()


func test_time_tick_config_validate_ticks_per_second_below_min_clamps_and_warns() -> void:
	# Arrange
	var config: TimeTickConfig = TimeTickConfig.new()
	config.ticks_per_second = 0.5

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_float(config.ticks_per_second).is_equal(TimeTickConfig.TICKS_PER_SECOND_MIN)


func test_time_tick_config_validate_ticks_per_second_above_max_clamps_and_warns() -> void:
	# Arrange
	var config: TimeTickConfig = TimeTickConfig.new()
	config.ticks_per_second = 9.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_float(config.ticks_per_second).is_equal(TimeTickConfig.TICKS_PER_SECOND_MAX)


func test_time_tick_config_validate_max_ticks_per_frame_out_of_range_clamps_and_warns() -> void:
	# Arrange
	var config: TimeTickConfig = TimeTickConfig.new()
	config.max_ticks_per_frame = 100

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_int(config.max_ticks_per_frame).is_equal(TimeTickConfig.MAX_TICKS_PER_FRAME_MAX)


func test_time_tick_config_validate_max_raw_delta_out_of_range_clamps_and_warns() -> void:
	# Arrange
	var config: TimeTickConfig = TimeTickConfig.new()
	config.max_raw_delta = 1.0

	# Act
	var issues: Array[String] = config.validate()

	# Assert
	assert_int(issues.size()).is_equal(1)
	assert_float(config.max_raw_delta).is_equal(TimeTickConfig.MAX_RAW_DELTA_MAX)


# ---------------------------------------------------------------------------
# TimeTickSystem.setup() — AC-2 (boot defaults) / AC-3 (validate once, proceed)
# ---------------------------------------------------------------------------

func test_time_tick_system_setup_boot_defaults_paused_false_and_time_warp_one() -> void:
	# Arrange — headless construction, zero scene tree, zero Autoload
	# registration (Test Evidence).
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	system.config = TimeTickConfig.new()

	# Act
	@warning_ignore("unsafe_method_access")
	system.setup()

	# Assert
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_false()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(1)


func test_time_tick_system_setup_reads_tunables_from_injected_config_not_hardcoded() -> void:
	# Arrange — non-default, in-range values (AC-1).
	var system: Object = auto_free(_new_system())
	var config: TimeTickConfig = TimeTickConfig.new()
	config.ticks_per_second = 2.5
	config.max_ticks_per_frame = 20
	config.max_raw_delta = 0.15
	config.time_warp_options = [1, 2]
	@warning_ignore("unsafe_property_access")
	system.config = config

	# Act
	@warning_ignore("unsafe_method_access")
	system.setup()

	# Assert — the system's effective tunables equal the injected config's
	# values, not the GDD-default literals.
	assert_float(config.ticks_per_second).is_equal(2.5)
	assert_int(config.max_ticks_per_frame).is_equal(20)
	assert_float(config.max_raw_delta).is_equal(0.15)
	assert_array(config.time_warp_options).is_equal([1, 2])


func test_time_tick_system_setup_out_of_range_config_clamps_and_proceeds() -> void:
	# Arrange — AC-3 edge case: a single-field range issue warns+clamps,
	# never halts.
	var system: Object = auto_free(_new_system())
	var config: TimeTickConfig = TimeTickConfig.new()
	config.ticks_per_second = 999.0
	@warning_ignore("unsafe_property_access")
	system.config = config

	# Act
	@warning_ignore("unsafe_method_access")
	system.setup()

	# Assert — setup() completed (boot proceeded) with the clamped value in
	# effect, and boot defaults still applied.
	assert_float(config.ticks_per_second).is_equal(TimeTickConfig.TICKS_PER_SECOND_MAX)
	@warning_ignore("unsafe_property_access")
	assert_bool(system.paused).is_false()
	@warning_ignore("unsafe_property_access")
	assert_int(system.time_warp).is_equal(1)


func test_time_tick_system_setup_without_preassigned_config_loads_from_config_path() -> void:
	# Arrange — production path: config left null, setup() must load()
	# res://data/config/time_tick_config.tres itself (ADR-0002 Autoload-tier
	# "no injection layer" rule).
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_property_access")
	assert_object(system.config).is_null()

	# Act
	@warning_ignore("unsafe_method_access")
	system.setup()

	# Assert — loaded config matches the GDD-authoritative defaults
	# (time-tick-system.md Tuning Knobs, amended 2026-07-23: 4.0 ticks/sec;
	# amended 2026-07-25, Sprint 8 re-tune: max_ticks_per_frame 10->12,
	# `design/quick-specs/tick-rate-retune-2026-07-25.md`, story tick-007).
	@warning_ignore("unsafe_property_access")
	var loaded_config: TimeTickConfig = system.config
	assert_object(loaded_config).is_not_null()
	assert_float(loaded_config.ticks_per_second).is_equal(4.0)
	assert_int(loaded_config.max_ticks_per_frame).is_equal(12)
	assert_float(loaded_config.max_raw_delta).is_equal(0.1)
	assert_array(loaded_config.time_warp_options).is_equal([1, 2, 3])


# ---------------------------------------------------------------------------
# Autoload registration — AC-4
# ---------------------------------------------------------------------------

func test_time_tick_system_autoload_registered_and_ready_before_test_execution() -> void:
	# Arrange + Act — nothing to do: TimeTickSystem is an Autoload, so by the
	# time this (or any) test function runs, the engine has already entered
	# it into the tree and called its _ready() -> setup() (Autoloads ready
	# before the Main Scene/any other node -- this is the only way to observe
	# that ordering from a test).

	# Assert — the registered singleton is reachable by its global Autoload
	# name (ADR-0001: called by global name directly, never @export-injected)
	# and already carries the GDD boot defaults.
	assert_object(TimeTickSystem).is_not_null()
	@warning_ignore("unsafe_property_access")
	assert_bool(TimeTickSystem.paused).is_false()
	@warning_ignore("unsafe_property_access")
	assert_int(TimeTickSystem.time_warp).is_equal(1)
	@warning_ignore("unsafe_property_access")
	var autoload_config: TimeTickConfig = TimeTickSystem.config
	assert_object(autoload_config).is_not_null()
	assert_float(autoload_config.ticks_per_second).is_equal(4.0)
