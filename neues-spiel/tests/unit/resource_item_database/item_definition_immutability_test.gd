## Unit test -- Resource & Item Database Story 001 (ADR-0006 two-type split).
##
## Proves the [ItemDefinitionResource]/[ItemDefinition] wrapping mechanism:
## full 11-field round-trip (AC-1), getter-only immutability shape (AC-2),
## and wrap-per-query cache integrity (AC-3). [code]get_by_id()[/code]
## itself is Story 003's scope -- this suite simulates RID's future
## internal lookup with a small local [code]Dictionary[/code] fixture to
## exercise the exact wrap-not-copy pattern ADR-0006 mandates, without
## depending on the not-yet-implemented Autoload.
##
## The [method Object.get]/[method Object.set] reflection bypass documented
## in ADR-0006 as a residual risk is deliberately NOT tested here (per the
## story's QA plan) -- it is an accepted, documented limitation, not a
## regression this suite guards against.
class_name ItemDefinitionImmutabilityTest
extends GdUnitTestSuite

const _FIXTURE_CATEGORY: StringName = &"block"
const _FIXTURE_MATERIAL_FAMILY: StringName = &"stone"
const _FIXTURE_TIER: int = 2
const _FIXTURE_STACKABLE: bool = true
const _FIXTURE_MAX_STACK_SIZE: int = 64
const _FIXTURE_HAULABLE: bool = true
const _FIXTURE_STORAGE_CATEGORY: StringName = &"raw_material"
const _FIXTURE_FOOTPRINT: Vector2i = Vector2i(2, 1)


## Builds a fully-populated [ItemDefinitionResource] fixture. Only
## [param id] and [param display_name] vary per call site (the fields the
## tests use to distinguish entries); every other field uses a fixed,
## non-default constant so a partial-field comparison could not
## accidentally pass.
func _build_fixture_resource(id: StringName, display_name: String) -> ItemDefinitionResource:
	var resource: ItemDefinitionResource = ItemDefinitionResource.new()
	resource.id = id
	resource.display_name = display_name
	resource.category = _FIXTURE_CATEGORY
	resource.material_family = _FIXTURE_MATERIAL_FAMILY
	resource.tier = _FIXTURE_TIER
	resource.visual_asset = BoxMesh.new()
	resource.stackable = _FIXTURE_STACKABLE
	resource.max_stack_size = _FIXTURE_MAX_STACK_SIZE
	resource.haulable = _FIXTURE_HAULABLE
	resource.storage_category = _FIXTURE_STORAGE_CATEGORY
	resource.footprint = _FIXTURE_FOOTPRINT
	return resource


func test_item_definition_full_field_round_trip_returns_authored_values() -> void:
	# Arrange
	var source: ItemDefinitionResource = _build_fixture_resource(&"wood_block", "Wood Block")

	# Act
	var definition: ItemDefinition = ItemDefinition.new(source)

	# Assert -- every one of the 11 schema fields, not a subset.
	assert_str(String(definition.get_id())).is_equal("wood_block")
	assert_str(definition.get_display_name()).is_equal("Wood Block")
	assert_str(String(definition.get_category())).is_equal(String(_FIXTURE_CATEGORY))
	assert_str(String(definition.get_material_family())).is_equal(String(_FIXTURE_MATERIAL_FAMILY))
	assert_int(definition.get_tier()).is_equal(_FIXTURE_TIER)
	assert_object(definition.get_visual_asset()).is_same(source.visual_asset)
	assert_bool(definition.get_stackable()).is_equal(_FIXTURE_STACKABLE)
	assert_int(definition.get_max_stack_size()).is_equal(_FIXTURE_MAX_STACK_SIZE)
	assert_bool(definition.get_haulable()).is_equal(_FIXTURE_HAULABLE)
	assert_str(String(definition.get_storage_category())).is_equal(String(_FIXTURE_STORAGE_CATEGORY))
	assert_vector(definition.get_footprint()).is_equal(_FIXTURE_FOOTPRINT)


func test_item_definition_exposes_zero_setter_methods() -> void:
	# Arrange
	var definition: ItemDefinition = ItemDefinition.new(
		_build_fixture_resource(&"stone_block", "Stone Block")
	)

	# Act -- only the script's OWN declared methods, not inherited RefCounted/
	# Object engine methods (several of which are themselves named set_*,
	# e.g. set_meta/set_script -- irrelevant to this class's custom surface).
	var method_names: Array[String] = []
	for method_info: Dictionary in definition.get_script().get_script_method_list():
		method_names.append(method_info["name"] as String)

	# Assert -- getter-only shape: no set_* method exists anywhere on the
	# custom API surface this class itself declares.
	assert_array(method_names).is_not_empty()
	for method_name: String in method_names:
		assert_bool(method_name.begins_with("set_")).is_false()


func test_item_definition_requeried_after_other_ids_returns_identical_values() -> void:
	# Arrange -- a local RID-shaped cache: Dictionary[StringName, ItemDefinitionResource],
	# mirroring the internal storage ADR-0006 describes (get_by_id() itself is
	# Story 003's scope, so this test builds its own minimal stand-in cache).
	var cache: Dictionary = {
		&"id_a": _build_fixture_resource(&"id_a", "Item A"),
		&"id_b": _build_fixture_resource(&"id_b", "Item B"),
		&"id_c": _build_fixture_resource(&"id_c", "Item C"),
	}

	# Act -- query A, then other ids in between, then A again (AC-3).
	var first_query: ItemDefinition = ItemDefinition.new(cache[&"id_a"])
	var first_display_name: String = first_query.get_display_name()
	var first_footprint: Vector2i = first_query.get_footprint()

	var _between_b: ItemDefinition = ItemDefinition.new(cache[&"id_b"])
	var _between_c: ItemDefinition = ItemDefinition.new(cache[&"id_c"])

	var second_query: ItemDefinition = ItemDefinition.new(cache[&"id_a"])

	# Assert -- the later, second query for A matches the first exactly, and
	# is a fresh wrapper (wraps, never copies -- ADR-0006 §2).
	assert_str(second_query.get_display_name()).is_equal(first_display_name)
	assert_vector(second_query.get_footprint()).is_equal(first_footprint)
	assert_object(second_query).is_not_same(first_query)
