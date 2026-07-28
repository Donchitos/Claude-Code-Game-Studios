## Integration test — Resource & Item Database Story rid-002 (ADR-0005 boot
## gate; ADR-0001 Autoload-tier setup() convention).
##
## Proves the REAL ResourceItemDatabase script satisfies the boot-gate
## contract [GameWorld] already consumes via `MockResourceItemDatabase`
## (docs/architecture/adr-0005-boot-sequencing-initialization-gate.md):
## Ready on valid data (AC-1), load-once rejection (AC-2), the non-Ready
## query guard across all three non-Ready states (AC-3), and the
## check-then-connect `validation_complete` contract firing exactly once
## (AC-4). Instantiated via a preloaded [GDScript]'s `.new()` directly, with
## a fixture [code]data_dir[/code] assigned before [code]setup()[/code] is
## called — zero scene tree, zero Autoload registration (Test Evidence).
class_name ResourceItemDatabaseBootGateTest
extends GdUnitTestSuite

const ResourceItemDatabaseScript: GDScript = preload("res://src/resource_item_database/resource_item_database.gd")
const _VALID_FIXTURE_DIR: String = "res://tests/integration/resource_item_database/fixtures/valid/"
const _INVALID_FIXTURE_DIR: String = "res://tests/integration/resource_item_database/fixtures/invalid/"


## Returns a fresh, never-autoloaded ResourceItemDatabase-script instance.
## Untyped return — the script deliberately carries no `class_name` (see
## its own doc comment on the TimeTickSystem precedent), so isolated
## instances are constructed via a preloaded [GDScript] and duck-typed at
## each access site, mirroring `AutoloadConfigBootTest._new_system()`.
func _new_database() -> Object:
	return ResourceItemDatabaseScript.new()


# ---------------------------------------------------------------------------
# AC-1 — Ready on valid data (GDD AC1)
# ---------------------------------------------------------------------------

func test_setup_with_valid_fixture_data_reaches_ready_and_loads_definitions_once() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _VALID_FIXTURE_DIR

	# Act
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = db.setup()

	# Assert
	assert_bool(bool(result["success"])).is_true()
	assert_array(result["issues"] as Array).is_empty()
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_true()
	@warning_ignore("unsafe_method_access")
	var wood: ItemDefinition = db.get_by_id(&"rid002_wood_block")
	assert_object(wood).is_not_null()
	assert_str(wood.get_display_name()).is_equal("RID-002 Wood Block Fixture")
	@warning_ignore("unsafe_method_access")
	var stone: ItemDefinition = db.get_by_id(&"rid002_stone_block")
	assert_object(stone).is_not_null()
	assert_str(stone.get_display_name()).is_equal("RID-002 Stone Block Fixture")


# ---------------------------------------------------------------------------
# AC-2 — load-once guard (GDD AC28)
# ---------------------------------------------------------------------------

func test_setup_called_again_after_ready_is_rejected_and_contents_unchanged() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _VALID_FIXTURE_DIR
	@warning_ignore("unsafe_method_access")
	db.setup()
	@warning_ignore("unsafe_method_access")
	var first_wood: ItemDefinition = db.get_by_id(&"rid002_wood_block")

	# Act — a second setup() call, even pointed at a different directory,
	# must not re-scan.
	@warning_ignore("unsafe_property_access")
	db.data_dir = _INVALID_FIXTURE_DIR
	@warning_ignore("unsafe_method_access")
	var second_result: Dictionary = db.setup()

	# Assert
	assert_bool(bool(second_result["success"])).is_false()
	assert_array(second_result["issues"] as Array).is_not_empty()
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_true()
	@warning_ignore("unsafe_method_access")
	var second_wood: ItemDefinition = db.get_by_id(&"rid002_wood_block")
	assert_object(second_wood).is_not_null()
	assert_str(second_wood.get_display_name()).is_equal(first_wood.get_display_name())


func test_setup_called_again_after_failed_is_rejected() -> void:
	# Arrange — resolve to Failed first (invalid fixture: a `.tres` that
	# loads successfully but as the wrong Resource type).
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _INVALID_FIXTURE_DIR
	@warning_ignore("unsafe_method_access")
	db.setup()
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_false()

	# Act
	@warning_ignore("unsafe_method_access")
	var second_result: Dictionary = db.setup()

	# Assert — Failed is terminal; a second call is rejected exactly like
	# the Ready case, never a fresh re-validation attempt.
	assert_bool(bool(second_result["success"])).is_false()
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_false()


# ---------------------------------------------------------------------------
# AC-3 — non-Ready query guard: Unloaded / Validating / Failed (GDD AC17)
# ---------------------------------------------------------------------------

func test_get_by_id_in_unloaded_state_returns_explicit_error_never_data() -> void:
	# Arrange — setup() never called.
	var db: Object = auto_free(_new_database())

	# Act
	@warning_ignore("unsafe_method_access")
	var result: ItemDefinition = db.get_by_id(&"rid002_wood_block")

	# Assert
	assert_object(result).is_null()


func test_get_by_id_in_validating_state_returns_explicit_error_never_data() -> void:
	# Arrange — force the transient Validating state directly. GDScript's
	# `_` prefix is a naming convention, not enforced privacy (the same
	# residual-access shape ADR-0006 already documents for ItemDefinition's
	# `_source`), and the real pipeline resolves Validating synchronously
	# within one setup() call, so it is never otherwise externally
	# observable to construct this fixture.
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db._state = ResourceItemDatabaseScript.BootState.VALIDATING

	# Act
	@warning_ignore("unsafe_method_access")
	var result: ItemDefinition = db.get_by_id(&"rid002_wood_block")

	# Assert
	assert_object(result).is_null()


func test_get_by_id_in_failed_state_returns_explicit_error_never_data() -> void:
	# Arrange
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _INVALID_FIXTURE_DIR
	@warning_ignore("unsafe_method_access")
	db.setup()
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_false()

	# Act
	@warning_ignore("unsafe_method_access")
	var result: ItemDefinition = db.get_by_id(&"rid002_wood_block")

	# Assert
	assert_object(result).is_null()


# ---------------------------------------------------------------------------
# AC-4 — boot-gate signal contract: check-then-connect, no double-fire
# ---------------------------------------------------------------------------

func test_is_ready_reflects_synchronous_resolution_before_any_listener_connects() -> void:
	# Arrange — mirrors GameWorld's check-then-connect FIRST branch: by the
	# time a consumer calls is_ready(), setup() has already resolved
	# synchronously, in the same call.
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _VALID_FIXTURE_DIR
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_false()

	# Act
	@warning_ignore("unsafe_method_access")
	db.setup()

	# Assert
	@warning_ignore("unsafe_method_access")
	assert_bool(db.is_ready()).is_true()


func test_validation_complete_fires_exactly_once_for_a_connect_one_shot_listener() -> void:
	# Arrange — mirrors GameWorld's check-then-connect FALLBACK branch: a
	# consumer connects with CONNECT_ONE_SHOT before setup() resolves.
	var db: Object = auto_free(_new_database())
	@warning_ignore("unsafe_property_access")
	db.data_dir = _VALID_FIXTURE_DIR
	var received: Array = []
	@warning_ignore("unsafe_property_access")
	db.validation_complete.connect(
		func(result: Dictionary) -> void: received.append(result),
		CONNECT_ONE_SHOT
	)

	# Act
	@warning_ignore("unsafe_method_access")
	db.setup()
	@warning_ignore("unsafe_method_access")
	db.setup()  # rejected second call — must not refire the listener

	# Assert — exactly one emission, carrying a passing result.
	assert_int(received.size()).is_equal(1)
	assert_bool(bool((received[0] as Dictionary)["success"])).is_true()


# ---------------------------------------------------------------------------
# Autoload registration sanity (mirrors TimeTickSystem's own AC-4 test) —
# proves the real registered singleton is reachable and already resolved
# (Ready — populated with the real MVP content story rid-009 shipped to
# res://data/items/) by the time any test executes, matching ADR-0005's
# documented Autoload-before-Main-Scene ordering.
# ---------------------------------------------------------------------------

func test_resource_item_database_autoload_registered_and_ready_before_test_execution() -> void:
	assert_object(ResourceItemDatabase).is_not_null()
	@warning_ignore("unsafe_method_access")
	assert_bool(ResourceItemDatabase.is_ready()).is_true()
