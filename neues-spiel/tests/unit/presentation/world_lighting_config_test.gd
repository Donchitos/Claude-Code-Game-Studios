## Unit test — [WorldLightingConfig] (Presentation Experience story
## presentation-004, "The world has no sun"; ADR-0002 two-tier `validate()`
## policy).
##
## Covers:
## 1. Defaults (the shipped, provisional AC3 values -- see that class's own
##    doc comment) are already valid (empty issues array).
## 2. Single-field clamp+warn tier for every ranged scalar knob. This config
##    declares no GDD BLOCKING cross-value invariant (unlike e.g.
##    needs-mood's ladder ordering), so every issue here is non-blocking.
class_name WorldLightingConfigTest
extends GdUnitTestSuite


func test_default_config_validates_with_no_issues() -> void:
	var config := WorldLightingConfig.new()
	var issues: Array[String] = config.validate()
	assert_array(issues).is_empty()


func test_default_light_energy_and_ambient_light_energy_match_the_provisional_ac3_values() -> void:
	# Regression guard for this story's own provisional taste call (class doc
	# comment) -- 0.95 / 0.28, not the art bible's own literal 1.7 / 0.5
	# (which blows the real meshed terrain out, per this story's own Context).
	var config := WorldLightingConfig.new()
	assert_float(config.light_energy).is_equal_approx(0.95, 0.0001)
	assert_float(config.ambient_light_energy).is_equal_approx(0.28, 0.0001)


func test_light_energy_over_max_clamps_to_max() -> void:
	var config := WorldLightingConfig.new()
	config.light_energy = 999.0

	var issues: Array[String] = config.validate()

	assert_float(config.light_energy).is_equal_approx(WorldLightingConfig.LIGHT_ENERGY_MAX, 0.0001)
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()


func test_light_energy_below_min_clamps_to_min() -> void:
	var config := WorldLightingConfig.new()
	config.light_energy = -5.0

	config.validate()

	assert_float(config.light_energy).is_equal_approx(WorldLightingConfig.LIGHT_ENERGY_MIN, 0.0001)


func test_ambient_light_energy_over_max_clamps_to_max() -> void:
	var config := WorldLightingConfig.new()
	config.ambient_light_energy = 999.0

	var issues: Array[String] = config.validate()

	assert_float(config.ambient_light_energy).is_equal_approx(WorldLightingConfig.AMBIENT_LIGHT_ENERGY_MAX, 0.0001)
	assert_int(issues.size()).is_equal(1)


func test_shadow_max_distance_out_of_range_clamps() -> void:
	var config := WorldLightingConfig.new()
	config.shadow_max_distance = 50000.0

	config.validate()

	assert_float(config.shadow_max_distance).is_equal_approx(WorldLightingConfig.SHADOW_MAX_DISTANCE_MAX, 0.0001)


func test_shadow_blur_out_of_range_clamps() -> void:
	var config := WorldLightingConfig.new()
	config.shadow_blur = -1.0

	config.validate()

	assert_float(config.shadow_blur).is_equal_approx(WorldLightingConfig.SHADOW_BLUR_MIN, 0.0001)


func test_art_bible_literal_recipe_values_remain_unclamped() -> void:
	# The art bible's own SS2.1 literal recipe (1.7 / 0.5) is kept on record
	# as the pre-dimming reference point (class doc comment) -- it must stay
	# a VALID, un-clamped config value (a safety range, not a taste opinion),
	# so an art director reverting to it later is a pure `.tres` edit.
	var config := WorldLightingConfig.new()
	config.light_energy = 1.7
	config.ambient_light_energy = 0.5

	var issues: Array[String] = config.validate()

	assert_array(issues).is_empty()
	assert_float(config.light_energy).is_equal_approx(1.7, 0.0001)
	assert_float(config.ambient_light_energy).is_equal_approx(0.5, 0.0001)
