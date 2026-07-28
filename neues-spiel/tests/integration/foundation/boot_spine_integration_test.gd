## Integration test — Foundation Spine Story 004 (headless boot integration
## test; Milestone-01 Success Criterion #1).
##
## Proves the REAL boot path -- real registered Autoloads (TimeTickSystem,
## ResourceItemDatabase) already `_ready()`, a freshly constructed [GameWorld]
## resolving its Resource & Item Database dependency lazily against the real
## `/root/ResourceItemDatabase` singleton (never a mock), the boot gate
## (ADR-0005) resolving, and external config reads (ADR-0002) -- runs headless
## with zero script errors and reaches [constant GameWorld.BootState.ACTIVE]
## (TR-scene-world-management-004, TR-resource-item-database-007).
##
## Reuses Story 001's [ReferenceInjectedModule] and Story 003's
## [ReferenceConfigConsumer] / [ReferenceModuleConfig] as fixtures (per this
## story's Implementation Notes), exactly as the existing per-story suites
## ([GameworldDiScaffoldTest], [BootSequencingGateTest],
## [ConfigResourceValidateTest]) already do -- those suites prove the DI/gate/
## config MECHANISMS in isolation against a mock RID double
## ([MockResourceItemDatabase]); this suite is the one place that proves the
## REAL Autoload sits underneath that same mechanism end-to-end
## (TR-building-ui-038's "exercisable headless via mocked upstream signals AND
## real state" bar, applied here to the real state half).
##
## The Failed-path companion assertion (AC-4) necessarily still uses
## [MockResourceItemDatabase]: the real registered singleton resolves Ready
## once per process (load-once guard, rid-002) and is shared by every other
## suite in this same headless run, so reconfiguring it to Failed here would
## corrupt every other test's boot state. This mirrors the story's own AC-4
## wording ("a mock RID reporting Failed") and keeps this file a complete,
## self-contained record of the whole spine's boot contract.
class_name BootSpineIntegrationTest
extends GdUnitTestSuite


## Test-local counting injected-tier module (not a production class): counts
## [method setup] invocations so a test can assert "exactly once" precisely,
## mirroring [BootSequencingGateTest]'s `OrderTrackingModule` precedent.
class CountingModule:
	extends Node

	var setup_call_count: int = 0

	func setup() -> void:
		setup_call_count += 1


# ---------------------------------------------------------------------------
# AC-1/AC-2 — real boot reaches ACTIVE; DI wiring proven (N=0 and N=2 edge
# cases from the QA plan)
# ---------------------------------------------------------------------------

func test_real_boot_zero_injected_modules_still_reaches_active() -> void:
	# Arrange — resource_item_database is deliberately left null: GameWorld's
	# own _ready() resolves it lazily against the REAL registered
	# `/root/ResourceItemDatabase` Autoload (ADR-0005), never a mock.
	var world: GameWorld = auto_free(GameWorld.new())
	world.injected_tier_modules = []

	# Act — entering the live tree fires the real boot gate.
	add_child(world)

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)


func test_real_boot_reference_injected_modules_are_wired_and_set_up() -> void:
	# Arrange — two Story 001 reference fixtures, each with its own DI
	# dependencies assigned exactly as production Inspector-wiring would.
	var world: GameWorld = auto_free(GameWorld.new())
	var module_a: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module_a.dependency_one = auto_free(Node.new())
	module_a.dependency_two = auto_free(Node.new())
	var module_b: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module_b.dependency_one = auto_free(Node.new())
	module_b.dependency_two = auto_free(Node.new())
	world.add_child(module_a)
	world.add_child(module_b)
	world.injected_tier_modules = [module_a, module_b]

	# Act
	add_child(world)

	# Assert — real boot reaches ACTIVE and both modules' own DI-dependency
	# assertions passed (is_set_up() only flips true after those asserts).
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	assert_bool(module_a.is_set_up()).is_true()
	assert_bool(module_b.is_set_up()).is_true()


func test_real_boot_setup_is_called_exactly_once_per_injected_module() -> void:
	# Arrange — a precise call-count proof (module_a.is_set_up() alone cannot
	# distinguish "called once" from "called twice").
	var world: GameWorld = auto_free(GameWorld.new())
	var module_a: CountingModule = auto_free(CountingModule.new())
	var module_b: CountingModule = auto_free(CountingModule.new())
	world.add_child(module_a)
	world.add_child(module_b)
	world.injected_tier_modules = [module_a, module_b]

	# Act
	add_child(world)

	# Assert
	assert_int(module_a.setup_call_count).is_equal(1)
	assert_int(module_b.setup_call_count).is_equal(1)


# ---------------------------------------------------------------------------
# AC-3 — external config read proven against the real boot path
# ---------------------------------------------------------------------------

func test_real_boot_config_consumer_reads_injected_sentinel_value() -> void:
	# Arrange — a non-default, in-range sentinel (default cadence_seconds is
	# 1.0; CADENCE_MIN/MAX are 0.1/10.0, so 4.25 triggers no clamp/warn).
	var world: GameWorld = auto_free(GameWorld.new())
	var consumer: ReferenceConfigConsumer = auto_free(ReferenceConfigConsumer.new())
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.cadence_seconds = 4.25
	consumer.config = config
	world.add_child(consumer)
	world.injected_tier_modules = [consumer]

	# Act
	add_child(world)

	# Assert — real boot reached ACTIVE, the config-consuming module ran its
	# setup() with no blocking issues, and the observed value is the injected
	# sentinel, not the config class's own default literal (1.0).
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	assert_bool(consumer.is_set_up()).is_true()
	assert_array(consumer.get_boot_blocking_issues()).is_empty()
	assert_float(consumer.config.cadence_seconds).is_equal(4.25)


func test_real_boot_config_consumer_observed_value_tracks_a_different_injected_sentinel() -> void:
	# Arrange — edge case (QA plan): changing the injected config field before
	# boot must change the observed value. A different sentinel (8.5, still
	# in-range) and fresh instances throughout prove the value is read from
	# the injected Resource, never a hardcoded literal.
	var world: GameWorld = auto_free(GameWorld.new())
	var consumer: ReferenceConfigConsumer = auto_free(ReferenceConfigConsumer.new())
	var config: ReferenceModuleConfig = ReferenceModuleConfig.new()
	config.cadence_seconds = 8.5
	consumer.config = config
	world.add_child(consumer)
	world.injected_tier_modules = [consumer]

	# Act
	add_child(world)

	# Assert
	assert_float(consumer.config.cadence_seconds).is_equal(8.5)


# ---------------------------------------------------------------------------
# AC-4 — companion Failed-path assertion (mock RID; see class doc comment for
# why the real singleton cannot be used here)
# ---------------------------------------------------------------------------

func test_mock_rid_failed_results_in_halted_state_and_zero_setup_calls() -> void:
	# Arrange
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	var module: ReferenceInjectedModule = auto_free(ReferenceInjectedModule.new())
	module.dependency_one = auto_free(Node.new())
	module.dependency_two = auto_free(Node.new())
	world.add_child(module)
	world.injected_tier_modules = [module]
	add_child(world)

	# Act
	database.settle(false, ["boot spine integration test — forced Failed"])

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_bool(module.is_set_up()).is_false()


func test_mock_rid_failed_with_modules_present_none_are_ever_set_up() -> void:
	# Arrange — edge case (QA plan): modules present but never wired via
	# setup() -- the unified gate withholds ALL of them on Failed, not just
	# the first.
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	world.resource_item_database = database
	var module_a: CountingModule = auto_free(CountingModule.new())
	var module_b: CountingModule = auto_free(CountingModule.new())
	world.add_child(module_a)
	world.add_child(module_b)
	world.injected_tier_modules = [module_a, module_b]
	add_child(world)

	# Act
	database.settle(false, [])

	# Assert
	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.HALTED)
	assert_int(module_a.setup_call_count).is_equal(0)
	assert_int(module_b.setup_call_count).is_equal(0)
