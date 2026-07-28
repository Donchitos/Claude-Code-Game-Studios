## Integration test — Presentation Experience story presentation-004
## ("The world has no sun"; ADR-0001 primary, ADR-0002/0005 secondary).
##
## Before this story, `Valley.tscn`/`game_world.tscn` hosted ZERO
## [DirectionalLight3D]/[WorldEnvironment] nodes -- counted directly, see the
## story's own Context. The shipped game's only light source was
## `AmbientTorchLight`, a single [OmniLight3D]; a player launching the real
## game got a near-black screen. Every "lit" screenshot this project ever
## produced was lit by a TOOL supplying its own throwaway recipe -- the
## seventh instance of this project's "agreed behaviour the running game
## never calls" failure mode.
##
## Covers:
## - **AC1/AC5**: the real boot hosts exactly one [DirectionalLight3D] and
##   one [WorldEnvironment] under [Valley], active once boot reaches ACTIVE.
## - **AC2**: the recipe is DATA -- grep guard, no literal light energy/
##   ambient colour in `valley.gd`/`Valley.tscn`.
## - **AC4**: the torch's lit neighbourhood is measurably brighter than the
##   shipped ambient.
## - **AC6**: the three tool scenes no longer hand-roll their own lighting
##   recipe -- grep guard against the old literal values reappearing.
## - **Anti-Vacuity Lever**: a deterministic, headless-computable luminance
##   estimate (NOT a GPU render -- see [method _estimate_terrain_luminance]'s
##   own doc comment for why, and `production/qa/evidence/
##   player-view-on-launch-*.png`, captured via the windowed
##   `tools/settlement_overview_capture.gd` tool per this story's own
##   dev-story instructions, for the real rendered confirmation this
##   headless suite cannot itself produce) proves the shipped recipe reads
##   inside a stated band, while the art bible's own literal 1.7/0.5 recipe
##   fails the UPPER bound (blown out) and a near-zero recipe fails the LOWER
##   bound (near-black) -- so this check cannot pass vacuously either
##   direction, matching the story's own Anti-Vacuity Lever wording.
class_name WorldLightingAndEnvironmentHostingTest
extends GdUnitTestSuite

const ValleyScene: PackedScene = preload("res://src/scene_world_management/Valley.tscn")

## Rec. 709 perceptual-luminance weights, applied by [method
## _estimate_terrain_luminance] -- standard, not this story's own invention.
const LUMA_R: float = 0.2126
const LUMA_G: float = 0.7152
const LUMA_B: float = 0.0722

## The voxel mesher's own single terrain material tint (`9CAD6E` lowland
## olive, `src/voxel_world/voxel_world_mesher.gd`'s own constant) -- named
## here, not imported, since [WorldLightingConfig] itself has no reference to
## terrain colour (Out of Scope: this story does not touch the mesher). A
## `const Color` anchor so the luminance-band check below is traceable to a
## real, named value, never a magic number.
const TERRAIN_BASE_COLOR: Color = Color(0x9C / 255.0, 0xAD / 255.0, 0x6E / 255.0)

## Luminance band this story's AC3 sign-off (provisional -- see
## [WorldLightingConfig]'s own doc comment) is expected to fall inside:
## bright enough to prove a sun exists (not near-black), dark enough to prove
## the terrain is not blown out. Calibrated against the two real captured
## references the story's own Context cites (`settlement-overview-eyelevel-2.png`
## at 1.7/0.5, well above the upper bound below, vs
## `settlement-overview-eyelevel-dimmed-5.png` at 0.95/0.28, inside it).
const LUMINANCE_BAND_MIN: float = 0.20
const LUMINANCE_BAND_MAX: float = 0.80


func _boot_valley() -> Dictionary:
	var world: GameWorld = auto_free(GameWorld.new())
	var database: MockResourceItemDatabase = auto_free(MockResourceItemDatabase.new())
	database.configure_ready_immediately()
	world.resource_item_database = database
	world.valley_scene = ValleyScene
	add_child(world)
	return {"world": world, "valley": world.get_valley() as Valley}


# ---------------------------------------------------------------------------
# AC1/AC5 -- exactly one sun, one environment, active at boot
# ---------------------------------------------------------------------------

func test_boot_hosts_exactly_one_directional_light_and_one_world_environment_active() -> void:
	var booted: Dictionary = _boot_valley()
	var world: GameWorld = booted["world"]
	var valley: Valley = booted["valley"]

	assert_int(world.get_boot_state()).is_equal(GameWorld.BootState.ACTIVE)
	assert_object(valley).is_not_null()

	var sun_count: int = _count_type(valley, "DirectionalLight3D")
	var environment_count: int = _count_type(valley, "WorldEnvironment")
	assert_int(sun_count).is_equal(1)
	assert_int(environment_count).is_equal(1)

	assert_object(valley.get_sun_light()).is_not_null()
	assert_object(valley.get_world_environment()).is_not_null()
	assert_object(valley.get_world_lighting()).is_not_null()
	assert_bool(valley.get_world_lighting().is_set_up()).is_true()
	assert_object(valley.get_world_environment().environment).is_not_null()


func test_shipped_light_and_environment_values_match_the_wired_config() -> void:
	var booted: Dictionary = _boot_valley()
	var valley: Valley = booted["valley"]
	var config: WorldLightingConfig = valley.get_world_lighting().config
	assert_object(config).is_not_null()

	var sun: DirectionalLight3D = valley.get_sun_light()
	assert_float(sun.light_energy).is_equal_approx(config.light_energy, 0.0001)

	var environment: Environment = valley.get_world_environment().environment
	assert_float(environment.ambient_light_energy).is_equal_approx(config.ambient_light_energy, 0.0001)


# ---------------------------------------------------------------------------
# AC2 -- the recipe is data, no literals in valley.gd / Valley.tscn
# ---------------------------------------------------------------------------

func test_no_literal_light_energy_or_ambient_colour_in_valley_source() -> void:
	var source: String = _read_comment_stripped_file("res://src/scene_world_management/valley.gd")
	assert_bool(source.contains("light_energy")).is_false()
	assert_bool(source.contains("ambient_light_energy")).is_false()
	assert_bool(source.contains("ambient_light_color")).is_false()


func test_no_literal_light_energy_or_ambient_colour_in_valley_scene_file() -> void:
	var text: String = FileAccess.get_file_as_string("res://src/scene_world_management/Valley.tscn")
	assert_bool(text.contains("light_energy")).is_false()
	assert_bool(text.contains("ambient_light_energy")).is_false()
	assert_bool(text.contains("ambient_light_color")).is_false()


func test_changing_config_values_changes_the_rendered_result() -> void:
	# "changing its values changes the rendered result" (AC2's own QA Test
	# Cases wording) -- proven directly against a fresh WorldLighting
	# instance, headless, no scene tree needed.
	var light: DirectionalLight3D = auto_free(DirectionalLight3D.new())
	var environment_host: WorldEnvironment = auto_free(WorldEnvironment.new())
	var lighting: WorldLighting = auto_free(WorldLighting.new())
	var config := WorldLightingConfig.new()
	config.light_energy = 0.1
	lighting.config = config
	lighting.directional_light = light
	lighting.world_environment = environment_host
	lighting.setup()
	assert_float(light.light_energy).is_equal_approx(0.1, 0.0001)

	config.light_energy = 3.0
	lighting._apply()

	assert_float(light.light_energy).is_equal_approx(3.0, 0.0001)


# ---------------------------------------------------------------------------
# AC4 -- the torch still reads against the new ambient
# ---------------------------------------------------------------------------

func test_torch_lit_neighbourhood_is_measurably_brighter_than_shipped_ambient() -> void:
	var booted: Dictionary = _boot_valley()
	var valley: Valley = booted["valley"]

	var torch_light: Light3D = valley.get_ambient_torch_light()
	var ambient_energy: float = valley.get_world_environment().environment.ambient_light_energy

	# TorchFlicker's own compute_energy() range (base_energy +/- amplitude,
	# torch_flicker_test.gd's own established pure-function precedent) never
	# dips below base_energy - amplitude; the shipped AmbientLifeConfig
	# defaults (base 1.0, amplitude 0.25) put even the DARKEST flicker sample
	# at 0.75 -- comfortably, measurably above the shipped 0.28 ambient.
	var torch_flicker: TorchFlicker = valley.get_torch_flicker()
	var darkest_sample: float = torch_flicker.config.torch_flicker_base_energy - torch_flicker.config.torch_flicker_amplitude

	assert_float(torch_light.light_energy).is_greater(ambient_energy)
	assert_float(darkest_sample).is_greater(ambient_energy)


# ---------------------------------------------------------------------------
# AC6 -- the three tool scenes stop supplying their own lighting
# ---------------------------------------------------------------------------

func test_tool_scripts_no_longer_hand_roll_the_golden_hour_recipe() -> void:
	var tool_paths: Array[String] = [
		"res://tools/settlement_overview_capture.gd",
		"res://tools/m01_c4_valley_ambient_capture.gd",
		"res://tools/camera_sandbox.gd",
	]
	for path: String in tool_paths:
		var source: String = _read_comment_stripped_file(path)
		# The old hand-rolled recipe's own exact literals -- regression guard.
		assert_bool(source.contains("light_energy = 1.7")).is_false()
		assert_bool(source.contains("ambient_light_energy = 0.5")).is_false()
		assert_bool(source.contains("_apply_golden_hour_lighting")).is_false()


func test_settlement_overview_and_m01_capture_no_longer_host_their_own_lighting_nodes() -> void:
	for path: String in [
		"res://tools/settlement_overview_capture.tscn",
		"res://tools/m01_c4_valley_ambient_capture.tscn",
	]:
		var text: String = FileAccess.get_file_as_string(path)
		assert_bool(text.contains("DirectionalLight3D")).is_false()
		assert_bool(text.contains("WorldEnvironment")).is_false()


func test_camera_sandbox_reuses_the_real_world_lighting_class() -> void:
	var source: String = _read_comment_stripped_file("res://tools/camera_sandbox.gd")
	assert_bool(source.contains("WorldLighting.new()")).is_true()
	assert_bool(source.contains("res://data/config/world_lighting_config.tres")).is_true()


# ---------------------------------------------------------------------------
# Anti-Vacuity Lever -- luminance band
# ---------------------------------------------------------------------------

func test_shipped_config_luminance_estimate_falls_inside_the_reads_band() -> void:
	var config := WorldLightingConfig.new()  # shipped defaults (provisional AC3)
	var luminance: float = _estimate_terrain_luminance(config)
	assert_float(luminance).is_greater(LUMINANCE_BAND_MIN)
	assert_float(luminance).is_less(LUMINANCE_BAND_MAX)


func test_art_bible_literal_recipe_fails_the_upper_bound_blown_out() -> void:
	# "a naive add-a-light-at-the-tool's-1.7-energy fix fails the upper
	# bound" -- the Anti-Vacuity Lever's own wording, proven directly.
	var config := WorldLightingConfig.new()
	config.light_energy = 1.7
	config.ambient_light_energy = 0.5
	var luminance: float = _estimate_terrain_luminance(config)
	assert_float(luminance).is_greater(LUMINANCE_BAND_MAX)


func test_near_zero_config_fails_the_lower_bound_near_black() -> void:
	# "On today's build the frame is near-black, so it cannot pass
	# vacuously" -- the Anti-Vacuity Lever's own wording, proven directly.
	var config := WorldLightingConfig.new()
	config.light_energy = 0.0
	config.ambient_light_energy = 0.0
	var luminance: float = _estimate_terrain_luminance(config)
	assert_float(luminance).is_less(LUMINANCE_BAND_MIN)


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Deterministic, physically-motivated ESTIMATE of a lit terrain pixel's
## luminance under [param config]'s recipe -- ambient + a single Lambertian
## directional term (N.L for a flat, up-facing terrain face lit by a
## directional light pitched [member WorldLightingConfig.light_rotation_degrees].x
## degrees below horizontal), Rec. 709 weighted. This is DELIBERATELY NOT a
## GPU render: this project's own `coding-standards.md` explicitly excludes
## "visual fidelity (shader output...)" and "platform-specific rendering"
## from automation, and no headless-pixel-capture precedent exists anywhere
## in this test suite (grep-verified at authoring time). This function is
## instead the same kind of pure, deterministic, headless-computable PROXY
## [TorchFlicker.compute_energy] already established for the sub-3Hz check
## ("asserted, not eyeballed") -- calibrated against this story's own two
## real captured references (class doc comment) so it discriminates the
## exact real regression this story fixes (a naive 1.7/0.5 relight blowing
## the real terrain out) from the shipped, dimmed recipe. The REAL rendered
## confirmation this proxy cannot itself provide is the windowed
## `tools/settlement_overview_capture.gd` capture this story's own dev-story
## instructions require running separately.
func _estimate_terrain_luminance(config: WorldLightingConfig) -> float:
	var n_dot_l: float = clampf(sin(deg_to_rad(-config.light_rotation_degrees.x)), 0.0, 1.0)
	var ambient_term: Color = config.ambient_light_color * config.ambient_light_energy
	var directional_term: Color = config.light_color * config.light_energy * n_dot_l
	var lit: Color = TERRAIN_BASE_COLOR * (ambient_term + directional_term)
	return LUMA_R * lit.r + LUMA_G * lit.g + LUMA_B * lit.b


## Recursively counts descendants of [param root] (INCLUDING [param root]
## itself) whose class name equals [param type_name] -- string-compared
## since the caller only has the type as a name, not the built-in class
## itself, for the two engine-native types this test checks.
func _count_type(root: Node, type_name: String) -> int:
	var count: int = 1 if root.get_class() == type_name else 0
	for child: Node in root.get_children():
		count += _count_type(child, type_name)
	return count


## Reads a single `.gd` file's source, stripping full-line `#`/`##`
## doc-comment lines first -- mirrors `world_root_valley_attach_test.gd`'s
## established `_read_all_gd_source` precedent (generalized to a single file
## rather than a directory sweep, since this check targets three specific
## tool scripts, not a whole directory).
func _read_comment_stripped_file(path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined
