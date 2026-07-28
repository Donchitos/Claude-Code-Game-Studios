## Unit test — Voxel World story vox-023 ("Block appearance becomes DATA").
##
## Proves [BlockAppearanceConfig]'s own [method BlockAppearanceConfig.validate]
## coverage (ADR-0002 two-tier policy — every issue this config can return is
## BLOCKING, per its own class doc comment): an empty table, a
## length mismatch, an out-of-family id, a duplicate id, and a malformed hex
## string each report a `BLOCKING:`-prefixed issue; a valid, shipped-shape
## config reports none. Also proves [method BlockAppearanceConfig.get_color]'s
## lookup/fallback contract directly (AC-DATA-ONLY-CHANGE-CHANGES-THE-WORLD's
## own underlying mechanism), independent of the mesher.
class_name BlockAppearanceConfigTest
extends GdUnitTestSuite


func _make_valid_config() -> BlockAppearanceConfig:
	var config := BlockAppearanceConfig.new()
	config.block_type_ids = [1, 2, 3, 4]
	config.block_colors_hex = ["9CAD6E", "A98F5E", "7C818A", "C9D3D8"]
	return config


# ---------------------------------------------------------------------------
# validate() — the valid, shipped-shape case
# ---------------------------------------------------------------------------

func test_validate_shipped_shape_config_returns_no_issues() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	assert_array(config.validate()).is_empty()


func test_validate_default_constructed_config_returns_no_issues() -> void:
	# The class's own field defaults ARE the shipped art-bible values — a
	# freshly-constructed config must already be valid, with no .tres needed.
	var config := BlockAppearanceConfig.new()
	assert_array(config.validate()).is_empty()


# ---------------------------------------------------------------------------
# validate() — every BLOCKING case (Test Evidence requirement, verbatim)
# ---------------------------------------------------------------------------

func test_validate_empty_table_is_blocking() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	config.block_type_ids = []
	config.block_colors_hex = []
	var issues: Array[String] = config.validate()
	assert_int(issues.size()).is_greater(0)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_validate_mismatched_array_lengths_is_blocking() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	config.block_colors_hex = ["9CAD6E", "A98F5E"]  # 2 hexes, 4 ids
	var issues: Array[String] = config.validate()
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_validate_out_of_range_id_is_blocking() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	config.block_type_ids = [1, 2, 3, 9]  # 9 is outside the 1..5 family
	var issues: Array[String] = config.validate()
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_validate_duplicate_id_is_blocking() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	config.block_type_ids = [1, 2, 2, 4]
	var issues: Array[String] = config.validate()
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_validate_malformed_hex_is_blocking() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	config.block_colors_hex = ["9CAD6E", "NOT-A-HEX", "7C818A", "C9D3D8"]
	var issues: Array[String] = config.validate()
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_validate_short_hex_is_blocking() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	config.block_colors_hex = ["9CAD6E", "ABC", "7C818A", "C9D3D8"]
	var issues: Array[String] = config.validate()
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


# ---------------------------------------------------------------------------
# get_color() — the lookup this story's whole mechanism rests on
# ---------------------------------------------------------------------------

func test_get_color_resolves_mapped_id_to_its_configured_colour() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	var resolved: Color = config.get_color(2, Color(1.0, 0.0, 1.0))
	assert_that(resolved).is_equal(Color("A98F5E"))


func test_get_color_returns_fallback_for_unmapped_id() -> void:
	var config: BlockAppearanceConfig = _make_valid_config()
	var fallback := Color(1.0, 0.0, 1.0)
	var resolved: Color = config.get_color(99, fallback)
	assert_that(resolved).is_equal(fallback)


func test_get_color_edit_one_hex_changes_only_that_ids_colour() -> void:
	# AC-DATA-ONLY-CHANGE-CHANGES-THE-WORLD's own underlying unit: editing
	# ONE entry's hex string changes ONLY that id's resolved colour.
	var config: BlockAppearanceConfig = _make_valid_config()
	var before: Color = config.get_color(1, Color.MAGENTA)
	config.block_colors_hex[0] = "FF0000"
	var after: Color = config.get_color(1, Color.MAGENTA)
	assert_that(before).is_not_equal(after)
	assert_that(after).is_equal(Color("FF0000"))
	# Every OTHER id's colour is untouched by the single-field edit.
	assert_that(config.get_color(2, Color.MAGENTA)).is_equal(Color("A98F5E"))
