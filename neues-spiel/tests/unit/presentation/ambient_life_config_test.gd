## Unit test — [AmbientLifeConfig] (Presentation Experience story
## presentation-001 Sub-scope A; ADR-0002 two-tier `validate()` policy).
##
## Covers:
## 1. Defaults are already valid (empty issues array).
## 2. Single-field clamp+warn tier: the SS8.9.5 particle budget
##    (chimney_smoke_particle_amount) and the A5 sub-3Hz flicker cap
##    (torch_flicker_frequencies_hz entries) both clamp in place with a
##    warning, never halt.
## 3. Cross-value BLOCKING tier: an empty torch_flicker_frequencies_hz array
##    has no scalar to clamp to.
class_name AmbientLifeConfigTest
extends GdUnitTestSuite


func test_default_config_validates_with_no_issues() -> void:
	var config := AmbientLifeConfig.new()
	var issues: Array[String] = config.validate()
	assert_array(issues).is_empty()


func test_chimney_smoke_particle_amount_over_budget_clamps_to_max() -> void:
	var config := AmbientLifeConfig.new()
	config.chimney_smoke_particle_amount = 500

	var issues: Array[String] = config.validate()

	assert_int(config.chimney_smoke_particle_amount).is_equal(
		AmbientLifeConfig.CHIMNEY_SMOKE_PARTICLE_AMOUNT_MAX
	)
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()


func test_chimney_smoke_particle_amount_below_min_clamps_to_min() -> void:
	var config := AmbientLifeConfig.new()
	config.chimney_smoke_particle_amount = -3

	config.validate()

	assert_int(config.chimney_smoke_particle_amount).is_equal(
		AmbientLifeConfig.CHIMNEY_SMOKE_PARTICLE_AMOUNT_MIN
	)


func test_torch_flicker_frequency_above_3hz_clamps_below_cap() -> void:
	var config := AmbientLifeConfig.new()
	config.torch_flicker_frequencies_hz = [0.6, 5.0, 1.2]

	var issues: Array[String] = config.validate()

	assert_float(config.torch_flicker_frequencies_hz[1]).is_less(3.0)
	assert_float(config.torch_flicker_frequencies_hz[1]).is_equal_approx(
		AmbientLifeConfig.TORCH_FLICKER_FREQUENCY_HZ_MAX, 0.0001
	)
	assert_int(issues.size()).is_equal(1)
	assert_bool(ConfigResource.has_blocking_issue(issues)).is_false()


func test_every_default_torch_flicker_frequency_is_sub_3hz() -> void:
	var config := AmbientLifeConfig.new()
	for frequency_hz: float in config.torch_flicker_frequencies_hz:
		assert_float(frequency_hz).is_less(3.0)


func test_empty_torch_flicker_frequencies_is_blocking() -> void:
	var config := AmbientLifeConfig.new()
	config.torch_flicker_frequencies_hz = []

	var issues: Array[String] = config.validate()

	assert_bool(ConfigResource.has_blocking_issue(issues)).is_true()


func test_chimney_smoke_lifetime_out_of_range_clamps() -> void:
	var config := AmbientLifeConfig.new()
	config.chimney_smoke_lifetime_seconds = 999.0

	config.validate()

	assert_float(config.chimney_smoke_lifetime_seconds).is_equal_approx(
		AmbientLifeConfig.CHIMNEY_SMOKE_LIFETIME_SECONDS_MAX, 0.0001
	)


func test_torch_flicker_amplitude_out_of_range_clamps() -> void:
	var config := AmbientLifeConfig.new()
	config.torch_flicker_amplitude = -1.0

	config.validate()

	assert_float(config.torch_flicker_amplitude).is_equal_approx(
		AmbientLifeConfig.TORCH_FLICKER_AMPLITUDE_MIN, 0.0001
	)
