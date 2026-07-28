## Unit test — [WorldLighting] (Presentation Experience story
## presentation-004, "The world has no sun"; ADR-0001 injected-tier
## `setup()` contract).
##
## Covers:
## 1. Headless setup() with no rendering, driving a real
##    [DirectionalLight3D]/[WorldEnvironment] pair.
## 2. Every field applied to the driven nodes comes from [member config],
##    not a literal (mirrors [WorldLightingConfig]'s own doc comment
##    discipline).
## 3. `setup()` asserts on missing dependencies rather than silently no-op'ing
##    (ADR-0001 convention, matches [TorchFlicker]'s own established shape).
class_name WorldLightingTest
extends GdUnitTestSuite


func test_setup_headless_drives_a_real_light_and_environment() -> void:
	var light: DirectionalLight3D = auto_free(DirectionalLight3D.new())
	var environment_host: WorldEnvironment = auto_free(WorldEnvironment.new())
	var lighting: WorldLighting = auto_free(WorldLighting.new())
	var config := WorldLightingConfig.new()
	lighting.config = config
	lighting.directional_light = light
	lighting.world_environment = environment_host
	assert_bool(lighting.is_set_up()).is_false()

	lighting.setup()

	assert_bool(lighting.is_set_up()).is_true()
	assert_float(light.light_energy).is_equal_approx(config.light_energy, 0.0001)
	assert_object(environment_host.environment).is_not_null()
	assert_float(environment_host.environment.ambient_light_energy).is_equal_approx(
		config.ambient_light_energy, 0.0001
	)


func test_applied_values_come_from_config_not_a_literal() -> void:
	# A non-default config, to prove the driven nodes reflect WHATEVER config
	# holds, never a baked-in literal recipe.
	var light: DirectionalLight3D = auto_free(DirectionalLight3D.new())
	var environment_host: WorldEnvironment = auto_free(WorldEnvironment.new())
	var lighting: WorldLighting = auto_free(WorldLighting.new())
	var config := WorldLightingConfig.new()
	config.light_energy = 2.3
	config.light_color = Color(0.2, 0.4, 0.6)
	config.light_rotation_degrees = Vector3(-10.0, 5.0, 0.0)
	config.ambient_light_color = Color(0.1, 0.2, 0.3)
	config.ambient_light_energy = 0.77
	config.background_color = Color(0.9, 0.1, 0.1)
	config.shadow_enabled = false
	config.shadow_max_distance = 123.0
	config.shadow_blur = 2.5
	lighting.config = config
	lighting.directional_light = light
	lighting.world_environment = environment_host

	lighting.setup()

	assert_float(light.light_energy).is_equal_approx(2.3, 0.0001)
	assert_bool(light.light_color.is_equal_approx(Color(0.2, 0.4, 0.6))).is_true()
	assert_vector(light.rotation_degrees).is_equal_approx(Vector3(-10.0, 5.0, 0.0), Vector3.ONE * 0.001)
	assert_bool(light.shadow_enabled).is_false()
	assert_float(light.directional_shadow_max_distance).is_equal_approx(123.0, 0.0001)
	assert_int(light.directional_shadow_mode).is_equal(DirectionalLight3D.SHADOW_ORTHOGONAL)
	assert_float(light.shadow_blur).is_equal_approx(2.5, 0.0001)

	var environment: Environment = environment_host.environment
	assert_bool(environment.background_color.is_equal_approx(Color(0.9, 0.1, 0.1))).is_true()
	assert_bool(environment.ambient_light_color.is_equal_approx(Color(0.1, 0.2, 0.3))).is_true()
	assert_float(environment.ambient_light_energy).is_equal_approx(0.77, 0.0001)
	assert_int(environment.background_mode).is_equal(Environment.BG_COLOR)
	assert_int(environment.ambient_light_source).is_equal(Environment.AMBIENT_SOURCE_COLOR)


func test_setup_asserts_when_config_not_wired() -> void:
	var lighting: WorldLighting = auto_free(WorldLighting.new())
	lighting.directional_light = auto_free(DirectionalLight3D.new())
	lighting.world_environment = auto_free(WorldEnvironment.new())

	await assert_error(func() -> void: lighting.setup()).is_runtime_error(
		"Assertion failed: WorldLighting.config not wired"
	)


func test_setup_asserts_when_lights_not_wired() -> void:
	var lighting: WorldLighting = auto_free(WorldLighting.new())
	lighting.config = WorldLightingConfig.new()

	await assert_error(func() -> void: lighting.setup()).is_runtime_error(
		"Assertion failed: WorldLighting.directional_light not wired"
	)
