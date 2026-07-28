## World lighting/environment host (Presentation Experience story
## presentation-004, "The world has no sun" -- ADR-0001 injected-tier module,
## ADR-0002 config-driven recipe, ADR-0005 boot-gated `setup()`).
##
## Before this story, `Valley.tscn`/`game_world.tscn` hosted ZERO
## [DirectionalLight3D]/[WorldEnvironment] nodes anywhere -- counted directly
## at this story's own start. The shipped game's only light source was
## `AmbientTorchLight`, a single [OmniLight3D]; a player launching the real
## game got a near-black screen. Every screenshot that looked lit was lit by
## a TOOL (`tools/settlement_overview_capture.gd`,
## `tools/m01_c4_valley_ambient_capture.gd`, `tools/camera_sandbox.gd`), each
## hand-rolling the SAME art-bible SS2.1 golden-hour recipe as a script
## literal, independently, three times, never once in the product itself --
## the seventh instance of this project's "agreed behaviour the running game
## never calls" failure mode.
##
## This class does not own or create the [DirectionalLight3D]/
## [WorldEnvironment] it drives ([member directional_light]/
## [member world_environment] are assigned externally -- [Valley]'s own
## hosting-vs-DI convention, mirroring [TorchFlicker]'s identical
## externally-assigned-[Light3D] shape exactly). [method setup] is the
## SOLE place this recipe is ever applied -- a plain [Resource]-typed
## [member config] read once, never re-applied per-frame (unlike
## [TorchFlicker], this recipe has no time-varying component; the art bible
## commits to a PERMANENT golden hour, Out of Scope explicitly excludes a day/
## night cycle).
class_name WorldLighting
extends Node

## Tuning-config dependency (ADR-0001 injected-tier / ADR-0002). Wired via
## `Valley.tscn`'s Inspector in production, or assigned directly in a
## headless test/tool -- never read inside `_ready()` (see [method setup]).
@export var config: WorldLightingConfig

## The driven sun -- assigned externally (class doc comment). Never
## constructed by this class.
@export var directional_light: DirectionalLight3D

## The driven environment host -- assigned externally (class doc comment).
## Never constructed by this class; this class constructs and assigns the
## actual [Environment] RESOURCE onto it (see [method _apply]), since an
## empty [WorldEnvironment] node has no [member WorldEnvironment.environment]
## resource of its own to mutate in place.
@export var world_environment: WorldEnvironment

## True once [method setup] has completed.
var _is_set_up: bool = false


## Explicitly-callable wiring entry point (ADR-0001). Asserts every
## dependency is wired, runs [member config]'s ADR-0002 two-tier
## `validate()` pass (warnings pushed, never a boot-halt -- this config
## declares no GDD BLOCKING invariant, see [WorldLightingConfig.validate]'s
## own doc comment), then applies the recipe exactly once.
func setup() -> void:
	assert(config != null, "WorldLighting.config not wired")
	assert(directional_light != null, "WorldLighting.directional_light not wired")
	assert(world_environment != null, "WorldLighting.world_environment not wired")
	for issue: String in config.validate():
		push_warning(issue)
	_apply()
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Applies [member config]'s POST-validate/clamp values onto the hosted
## [DirectionalLight3D]/[WorldEnvironment] -- the art bible SS2.1 recipe,
## every field sourced from [member config], never a literal here (AC2's own
## grep guard covers `valley.gd`/`Valley.tscn`, not this class, but the same
## discipline holds: this method reads [member config] fields exclusively).
func _apply() -> void:
	directional_light.light_color = config.light_color
	directional_light.light_energy = config.light_energy
	directional_light.rotation_degrees = config.light_rotation_degrees
	directional_light.shadow_enabled = config.shadow_enabled
	directional_light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	directional_light.directional_shadow_max_distance = config.shadow_max_distance
	directional_light.shadow_blur = config.shadow_blur

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = config.background_color
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = config.ambient_light_color
	environment.ambient_light_energy = config.ambient_light_energy
	environment.ssao_enabled = false
	world_environment.environment = environment
