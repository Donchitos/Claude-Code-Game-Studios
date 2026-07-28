## Typed tuning-config Resource (ADR-0002) for Presentation Experience story
## presentation-001 Sub-scope A (ambient life wave 1). Backs the two ambient
## elements that carry an actual numeric tuning/safety budget --
## [ChimneySmokeEmitter] (art-bible SS8.9.5 particle budget) and
## [TorchFlicker] (art-bible A5 sub-3Hz flicker cap). The other two Sub-scope
## A elements (foliage sway, interior clutter) are tuned via their own
## natural Godot surface instead -- see each class's own doc comment for why
## a shared config field would be redundant there:
## - Foliage sway's wind_speed/wind_strength are [code]hint_range[/code]
##   shader uniforms on `res://assets/shaders/foliage_sway.gdshader` --
##   already Inspector-editable per-[ShaderMaterial] instance, the idiomatic
##   Godot mechanism for shader tuning (this codebase has no precedent for
##   routing shader uniform defaults through a [ConfigResource]).
## - Interior clutter's prop transforms are scene-authored composition data
##   ([InteriorClutterPlacer]'s own `@export var clutter_transforms`),
##   analogous to how `Valley.tscn` wires scene-specific structural children
##   directly rather than via a shared tuning-config -- there is no GDD
##   Tuning Knob here, only per-room authored layout.
##
## A matching `.tres` instance lives at
## `res://data/config/ambient_life_config.tres` (ADR-0002: text file, never
## `.res`).
class_name AmbientLifeConfig
extends ConfigResource

## Hard particle-count ceiling for any one ambient emitter (art-bible SS8.9.5:
## "ambient emitters <=50 particles" -- the debrief's #1 reserved VFX budget
## gap). [member chimney_smoke_particle_amount] is clamped to
## [1, CHIMNEY_SMOKE_PARTICLE_AMOUNT_MAX], never a BLOCKING invariant -- a
## budget overrun is exactly the single-field "nearest bound" case ADR-0002's
## clamp tier exists for.
const CHIMNEY_SMOKE_PARTICLE_AMOUNT_MAX: int = 50

## Sanity floor for [member chimney_smoke_particle_amount] -- zero particles
## would silently degrade to "no smoke ever," which is a config error, not a
## valid "occupied but no smoke" state (that state is expressed via [method
## ChimneySmokeEmitter.set_occupied_lit], never via a zeroed particle count).
const CHIMNEY_SMOKE_PARTICLE_AMOUNT_MIN: int = 1

## Safe range for [member chimney_smoke_lifetime_seconds] -- a plausible
## wisp-lifetime window for a small ambient emitter, not a GDD-documented
## figure (no dedicated GDD exists for this Art-Bible-traced story; see the
## story's own Context section).
const CHIMNEY_SMOKE_LIFETIME_SECONDS_MIN: float = 0.5
const CHIMNEY_SMOKE_LIFETIME_SECONDS_MAX: float = 12.0

## Safe range for [member chimney_smoke_rise_speed].
const CHIMNEY_SMOKE_RISE_SPEED_MIN: float = 0.1
const CHIMNEY_SMOKE_RISE_SPEED_MAX: float = 5.0

## Safe range for [member chimney_smoke_spread_degrees] -- a
## [ParticleProcessMaterial.spread] value, degrees.
const CHIMNEY_SMOKE_SPREAD_DEGREES_MIN: float = 0.0
const CHIMNEY_SMOKE_SPREAD_DEGREES_MAX: float = 45.0

## Hard flicker-rate ceiling (art-bible A5, restated verbatim at SS6.5:
## "Must respect A5 (sub-3Hz) -- no free pass on flicker rate"). Every entry
## in [member torch_flicker_frequencies_hz] is clamped BELOW 3.0, not merely
## at it -- a small safety margin so floating-point/engine jitter never
## rounds a "just under 3.0" value up to a flash-triggering rate.
const TORCH_FLICKER_FREQUENCY_HZ_MAX: float = 2.9

## Sanity floor for a flicker component's frequency -- near-zero would read
## as a slow fade, not a flicker.
const TORCH_FLICKER_FREQUENCY_HZ_MIN: float = 0.05

## Safe range for [member torch_flicker_base_energy] -- a plausible
## [Light3D.light_energy] baseline for a small beacon light.
const TORCH_FLICKER_BASE_ENERGY_MIN: float = 0.1
const TORCH_FLICKER_BASE_ENERGY_MAX: float = 5.0

## Safe range for [member torch_flicker_amplitude] -- kept below
## [member torch_flicker_base_energy]'s typical value so light_energy never
## goes negative (see [method TorchFlicker.compute_energy]'s clamp-at-zero
## note for the defense-in-depth backstop).
const TORCH_FLICKER_AMPLITUDE_MIN: float = 0.0
const TORCH_FLICKER_AMPLITUDE_MAX: float = 2.0

## Particle count for one [ChimneySmokeEmitter] instance (art-bible SS6.5:
## "small GPUParticles3D"). Default 24 -- comfortably inside the SS8.9.5
## budget, one draw call per emitter.
@export var chimney_smoke_particle_amount: int = 24

## Per-particle lifetime, seconds.
@export var chimney_smoke_lifetime_seconds: float = 4.0

## Upward initial-velocity magnitude for emitted smoke particles.
@export var chimney_smoke_rise_speed: float = 1.2

## Cone spread (degrees) applied to the emission direction -- a small spread
## reads as a soft wisp rather than a rigid single-file column.
@export var chimney_smoke_spread_degrees: float = 12.0

## The additive sine-component frequencies (Hz) [TorchFlicker.compute_energy]
## sums to derive the flicker waveform. THREE non-harmonic default
## frequencies (no small-integer ratio between them) so the combined
## waveform reads as organic flicker rather than a single regular pulse --
## every entry individually stays sub-3Hz (A5), which is sufficient for the
## sum to stay sub-3Hz too (see [method TorchFlicker.compute_energy]'s doc
## comment for why bounding each component bounds the whole waveform's
## fastest oscillation).
@export var torch_flicker_frequencies_hz: Array[float] = [0.6, 1.3, 2.1]

## Baseline [Light3D.light_energy] a torch/lantern flickers around.
@export var torch_flicker_base_energy: float = 1.0

## Peak deviation from [member torch_flicker_base_energy] the combined
## flicker waveform can reach (see [method TorchFlicker.compute_energy]).
@export var torch_flicker_amplitude: float = 0.25


## See [ConfigResource.validate]. Clamps every ranged scalar field in place
## (the sole sanctioned runtime write to this config) and flags the one
## cross-value invariant this config has as BLOCKING: an empty
## [member torch_flicker_frequencies_hz] has no single "nearest bound" to
## clamp to (there is no scalar to clamp -- the array itself is structurally
## invalid), so it is reported via [method ConfigResource.format_blocking]
## instead, per ADR-0002's two-tier policy.
func validate() -> Array[String]:
	var issues: Array[String] = []

	if chimney_smoke_particle_amount < CHIMNEY_SMOKE_PARTICLE_AMOUNT_MIN or chimney_smoke_particle_amount > CHIMNEY_SMOKE_PARTICLE_AMOUNT_MAX:
		issues.append(
			"chimney_smoke_particle_amount out of range [%s, %s], got %s -- clamped" %
			[CHIMNEY_SMOKE_PARTICLE_AMOUNT_MIN, CHIMNEY_SMOKE_PARTICLE_AMOUNT_MAX, chimney_smoke_particle_amount]
		)
		chimney_smoke_particle_amount = clampi(
			chimney_smoke_particle_amount, CHIMNEY_SMOKE_PARTICLE_AMOUNT_MIN, CHIMNEY_SMOKE_PARTICLE_AMOUNT_MAX
		)

	if chimney_smoke_lifetime_seconds < CHIMNEY_SMOKE_LIFETIME_SECONDS_MIN or chimney_smoke_lifetime_seconds > CHIMNEY_SMOKE_LIFETIME_SECONDS_MAX:
		issues.append(
			"chimney_smoke_lifetime_seconds out of range [%s, %s], got %s -- clamped" %
			[CHIMNEY_SMOKE_LIFETIME_SECONDS_MIN, CHIMNEY_SMOKE_LIFETIME_SECONDS_MAX, chimney_smoke_lifetime_seconds]
		)
		chimney_smoke_lifetime_seconds = clampf(
			chimney_smoke_lifetime_seconds, CHIMNEY_SMOKE_LIFETIME_SECONDS_MIN, CHIMNEY_SMOKE_LIFETIME_SECONDS_MAX
		)

	if chimney_smoke_rise_speed < CHIMNEY_SMOKE_RISE_SPEED_MIN or chimney_smoke_rise_speed > CHIMNEY_SMOKE_RISE_SPEED_MAX:
		issues.append(
			"chimney_smoke_rise_speed out of range [%s, %s], got %s -- clamped" %
			[CHIMNEY_SMOKE_RISE_SPEED_MIN, CHIMNEY_SMOKE_RISE_SPEED_MAX, chimney_smoke_rise_speed]
		)
		chimney_smoke_rise_speed = clampf(
			chimney_smoke_rise_speed, CHIMNEY_SMOKE_RISE_SPEED_MIN, CHIMNEY_SMOKE_RISE_SPEED_MAX
		)

	if chimney_smoke_spread_degrees < CHIMNEY_SMOKE_SPREAD_DEGREES_MIN or chimney_smoke_spread_degrees > CHIMNEY_SMOKE_SPREAD_DEGREES_MAX:
		issues.append(
			"chimney_smoke_spread_degrees out of range [%s, %s], got %s -- clamped" %
			[CHIMNEY_SMOKE_SPREAD_DEGREES_MIN, CHIMNEY_SMOKE_SPREAD_DEGREES_MAX, chimney_smoke_spread_degrees]
		)
		chimney_smoke_spread_degrees = clampf(
			chimney_smoke_spread_degrees, CHIMNEY_SMOKE_SPREAD_DEGREES_MIN, CHIMNEY_SMOKE_SPREAD_DEGREES_MAX
		)

	if torch_flicker_frequencies_hz.is_empty():
		issues.append(ConfigResource.format_blocking(
			"torch_flicker_frequencies_hz must contain at least one frequency"
		))
	else:
		for i in torch_flicker_frequencies_hz.size():
			var freq: float = torch_flicker_frequencies_hz[i]
			if freq < TORCH_FLICKER_FREQUENCY_HZ_MIN or freq > TORCH_FLICKER_FREQUENCY_HZ_MAX:
				issues.append(
					"torch_flicker_frequencies_hz[%s] out of range [%s, %s] (A5 sub-3Hz), got %s -- clamped" %
					[i, TORCH_FLICKER_FREQUENCY_HZ_MIN, TORCH_FLICKER_FREQUENCY_HZ_MAX, freq]
				)
				torch_flicker_frequencies_hz[i] = clampf(
					freq, TORCH_FLICKER_FREQUENCY_HZ_MIN, TORCH_FLICKER_FREQUENCY_HZ_MAX
				)

	if torch_flicker_base_energy < TORCH_FLICKER_BASE_ENERGY_MIN or torch_flicker_base_energy > TORCH_FLICKER_BASE_ENERGY_MAX:
		issues.append(
			"torch_flicker_base_energy out of range [%s, %s], got %s -- clamped" %
			[TORCH_FLICKER_BASE_ENERGY_MIN, TORCH_FLICKER_BASE_ENERGY_MAX, torch_flicker_base_energy]
		)
		torch_flicker_base_energy = clampf(
			torch_flicker_base_energy, TORCH_FLICKER_BASE_ENERGY_MIN, TORCH_FLICKER_BASE_ENERGY_MAX
		)

	if torch_flicker_amplitude < TORCH_FLICKER_AMPLITUDE_MIN or torch_flicker_amplitude > TORCH_FLICKER_AMPLITUDE_MAX:
		issues.append(
			"torch_flicker_amplitude out of range [%s, %s], got %s -- clamped" %
			[TORCH_FLICKER_AMPLITUDE_MIN, TORCH_FLICKER_AMPLITUDE_MAX, torch_flicker_amplitude]
		)
		torch_flicker_amplitude = clampf(
			torch_flicker_amplitude, TORCH_FLICKER_AMPLITUDE_MIN, TORCH_FLICKER_AMPLITUDE_MAX
		)

	return issues
