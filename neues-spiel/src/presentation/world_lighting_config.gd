## Typed tuning-config Resource (ADR-0002) for Presentation Experience story
## presentation-004 ("The world has no sun") -- the art bible's SS2.1
## "permanent golden-hour bias" recipe, made DATA instead of a literal copied
## into every tool script (`tools/settlement_overview_capture.gd`,
## `tools/m01_c4_valley_ambient_capture.gd`, `tools/camera_sandbox.gd` all
## hand-rolled this exact recipe before this story -- see [WorldLighting]'s
## own class doc comment for the hosting side of this fix).
##
## A matching `.tres` instance lives at
## `res://data/config/world_lighting_config.tres` (ADR-0002: text file, never
## `.res`).
##
## **PROVISIONAL VALUES -- AC3 taste call, not yet art-director-ratified.**
## [member light_energy] (0.95) and [member ambient_light_energy] (0.28) are
## the two fields this story's own AC3 explicitly defers to the art director,
## signed off against the REAL meshed terrain, not a prototype. They are
## shipped now (story presentation-004 cannot host nothing while waiting on a
## taste call the user was unavailable for) with a recorded rationale: at the
## art bible's own literal recipe values (1.7 / 0.5), the real meshed
## terrain's single material -- the mesher's `9CAD6E` lowland-olive tint,
## [WorldLightingConfig] has no reference to that value itself, it is
## `voxel_world_mesher.gd`'s own constant -- blows out to a near-white pale
## yellow (see `production/qa/evidence/settlement-overview-eyelevel-2.png`).
## Dropping only the exposure to 0.95 / 0.28 makes the same terrain read
## plainly (`production/qa/evidence/settlement-overview-eyelevel-dimmed-5.png`).
## Every OTHER field below is the art bible's own recipe verbatim, unchanged,
## not part of this provisional note. Because this recipe now lives in a
## config [Resource] (ADR-0002) rather than scattered script literals,
## overturning this provisional call later is a `.tres` NUMBER EDIT, not a
## code change -- exactly the property ADR-0002 exists to buy.
class_name WorldLightingConfig
extends ConfigResource

## Safe range for [member light_energy] -- generous enough that both this
## story's provisional 0.95 AND the art bible's own literal 1.7 (kept on
## record as the pre-dimming reference point, see class doc comment) remain
## valid, unclamped values; this is a safety bound, not a taste opinion.
const LIGHT_ENERGY_MIN: float = 0.0
const LIGHT_ENERGY_MAX: float = 5.0

## Safe range for [member ambient_light_energy] -- same rationale as
## [constant LIGHT_ENERGY_MIN]/[constant LIGHT_ENERGY_MAX].
const AMBIENT_LIGHT_ENERGY_MIN: float = 0.0
const AMBIENT_LIGHT_ENERGY_MAX: float = 2.0

## Safe range for [member shadow_max_distance] -- bounded well above
## ADR-0015's ~380m streamed view radius (so the whole streamed window can
## shadow-cast) and well below the 2000x2000-cell world extent (ADR-0014),
## which would be a wasteful shadow-frustum depth for a single cascade.
const SHADOW_MAX_DISTANCE_MIN: float = 10.0
const SHADOW_MAX_DISTANCE_MAX: float = 1000.0

## Safe range for [member shadow_blur].
const SHADOW_BLUR_MIN: float = 0.0
const SHADOW_BLUR_MAX: float = 5.0

## PROVISIONAL (class doc comment, AC3) -- [member Light3D.light_energy] for
## the hosted sun. Art bible SS2.1 literal is 1.7; this ships dimmed pending
## art-director sign-off against real terrain.
@export var light_energy: float = 0.95

## Art bible SS2.1 recipe verbatim -- a warm, never-neutral-white key light
## colour (permanent golden-hour bias).
@export var light_color: Color = Color(1.0, 0.93, 0.80)

## Art bible SS2.1 recipe verbatim -- the sun's fixed pitch/yaw. No day/night
## cycle exists at MVP (Out of Scope); this is a single, permanent angle.
@export var light_rotation_degrees: Vector3 = Vector3(-42.0, -35.0, 0.0)

## Art bible SS2.1 recipe verbatim -- warm ambient fill colour.
@export var ambient_light_color: Color = Color(0.98, 0.94, 0.86)

## PROVISIONAL (class doc comment, AC3) -- [member Environment.ambient_light_energy].
## Art bible SS2.1 literal is 0.5; this ships dimmed pending art-director
## sign-off against real terrain.
@export var ambient_light_energy: float = 0.28

## Art bible SS2.1 recipe verbatim -- a warm dusk-leaning sky background,
## never a cool neutral.
@export var background_color: Color = Color(0.85, 0.68, 0.5)

## Art bible SS2.1 recipe verbatim -- shadows on, soft/high-ambient-fill
## (never dramatic), per SS2.1's own "soft, high-ambient-fill shadows, not
## dramatic ones" wording.
@export var shadow_enabled: bool = true

## Shadow-frustum depth -- see [constant SHADOW_MAX_DISTANCE_MIN]/
## [constant SHADOW_MAX_DISTANCE_MAX]'s doc comment for the ADR-0014/0015
## rationale behind the 400.0 default.
@export var shadow_max_distance: float = 400.0

## Shadow edge softness, matching every tool script's own pre-existing value
## for this knob (never itself re-tuned by this story).
@export var shadow_blur: float = 1.0


## See [ConfigResource.validate]. Clamps every ranged scalar field in place
## and returns a warning for each; this config has no GDD-declared BLOCKING
## cross-value invariant (unlike e.g. needs-mood's ladder ordering), so every
## issue here is single-field clamp-and-warn, ADR-0002's non-blocking tier.
func validate() -> Array[String]:
	var issues: Array[String] = []

	if light_energy < LIGHT_ENERGY_MIN or light_energy > LIGHT_ENERGY_MAX:
		issues.append(
			"light_energy out of range [%s, %s], got %s -- clamped" %
			[LIGHT_ENERGY_MIN, LIGHT_ENERGY_MAX, light_energy]
		)
		light_energy = clampf(light_energy, LIGHT_ENERGY_MIN, LIGHT_ENERGY_MAX)

	if ambient_light_energy < AMBIENT_LIGHT_ENERGY_MIN or ambient_light_energy > AMBIENT_LIGHT_ENERGY_MAX:
		issues.append(
			"ambient_light_energy out of range [%s, %s], got %s -- clamped" %
			[AMBIENT_LIGHT_ENERGY_MIN, AMBIENT_LIGHT_ENERGY_MAX, ambient_light_energy]
		)
		ambient_light_energy = clampf(ambient_light_energy, AMBIENT_LIGHT_ENERGY_MIN, AMBIENT_LIGHT_ENERGY_MAX)

	if shadow_max_distance < SHADOW_MAX_DISTANCE_MIN or shadow_max_distance > SHADOW_MAX_DISTANCE_MAX:
		issues.append(
			"shadow_max_distance out of range [%s, %s], got %s -- clamped" %
			[SHADOW_MAX_DISTANCE_MIN, SHADOW_MAX_DISTANCE_MAX, shadow_max_distance]
		)
		shadow_max_distance = clampf(shadow_max_distance, SHADOW_MAX_DISTANCE_MIN, SHADOW_MAX_DISTANCE_MAX)

	if shadow_blur < SHADOW_BLUR_MIN or shadow_blur > SHADOW_BLUR_MAX:
		issues.append(
			"shadow_blur out of range [%s, %s], got %s -- clamped" %
			[SHADOW_BLUR_MIN, SHADOW_BLUR_MAX, shadow_blur]
		)
		shadow_blur = clampf(shadow_blur, SHADOW_BLUR_MIN, SHADOW_BLUR_MAX)

	return issues
