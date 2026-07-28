## Torch/lantern flicker via light-energy noise (Presentation Experience
## story presentation-001 Sub-scope A; art-bible SS6.5 + the accessibility
## requirement A5 restated there verbatim: "Must respect A5 (sub-3Hz) -- no
## free pass on flicker rate"). Drives an externally-assigned [Light3D]'s
## [member Light3D.light_energy] from a small, DETERMINISTIC sum-of-sines
## waveform -- no [RandomNumberGenerator]/`randf()` anywhere in this class,
## per this project's test-determinism rule (coding-standards.md: "no random
## seeds, no time-dependent assertions" for automated tests) and so the
## sub-3Hz cap is a provable property of [method compute_energy], never a
## visual "eyeball" check (art-bible SS6.5: "asserted, not eyeballed").
##
## Works for BOTH the "carried" (lantern) and "fixed" (wall torch) cases the
## AC names -- this class does not own or create the [Light3D] itself
## ([member light] is assigned externally to whichever [OmniLight3D]/
## [SpotLight3D] a carried-item or fixed-fixture scene already has), so the
## SAME driver attaches to either.
##
## Presentation-only (Control Manifest Presentation layer Required:
## "ambient motion is presentation-only"): this class computes a light
## intensity curve, nothing else -- no gameplay state, no simulation.
class_name TorchFlicker
extends Node

## Tuning-config dependency (ADR-0001 injected-tier / ADR-0002). Wired via a
## scene file's Inspector in production, or assigned directly in a headless
## test/tool -- never read inside `_ready()` (see [method setup]).
@export var config: AmbientLifeConfig

## The driven light -- a carried lantern's or a fixed torch's [Light3D],
## assigned externally (class doc comment). Never constructed by this class.
@export var light: Light3D

## True once [method setup] has completed.
var _is_set_up: bool = false

## Elapsed time (raw engine delta, never [code]game_delta[/code] --
## Control Manifest Global Rules: "camera/UI/overlays run on raw engine
## delta; simulation runs on Time & Tick's game_delta" -- a torch's visual
## flicker is presentation, not simulation, exactly like a [Tween]/UI timer,
## so it keeps flickering through game pause instead of freezing mid-frame
## on the darkest/brightest sample) since [method setup] last ran.
var _elapsed_time: float = 0.0


## Explicitly-callable wiring entry point (ADR-0001). Asserts [member config]
## and [member light] are wired, resets the elapsed-time clock, and applies
## the very first sample immediately so the light does not default to
## engine-default energy for one frame before [method _process] first runs.
func setup() -> void:
	assert(config != null, "TorchFlicker.config not wired")
	assert(light != null, "TorchFlicker.light not wired")
	_elapsed_time = 0.0
	light.light_energy = compute_energy(_elapsed_time)
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


func _process(delta: float) -> void:
	if not _is_set_up:
		return
	_elapsed_time += delta
	light.light_energy = compute_energy(_elapsed_time)


## Returns elapsed presentation time since [method setup] -- test-facing.
func get_elapsed_time() -> float:
	return _elapsed_time


## Pure, deterministic light-energy sample at [param time_seconds] --
## callable directly (headless, no [Light3D]/scene tree needed) for
## automated frequency verification. Sums [member
## AmbientLifeConfig.torch_flicker_frequencies_hz]'s components as equal-
## weighted sine waves, averaged (never summed raw) so the combined
## waveform's peak deviation never exceeds [member
## AmbientLifeConfig.torch_flicker_amplitude] regardless of how many
## components there are -- each component individually clamped sub-3Hz by
## [method AmbientLifeConfig.validate], which is what keeps the WHOLE
## waveform's fastest oscillation sub-3Hz too: a sum of finitely many sine
## waves, each with angular frequency below a bound, has no Fourier
## component above that same bound (linearity of the sum) -- so bounding
## every component individually is sufficient to bound the combined
## waveform, not merely necessary. [method maxf] clamps the result at 0.0 as
## a defense-in-depth backstop against a negative [member
## Light3D.light_energy] (should never trigger given [member
## AmbientLifeConfig.validate]'s own amplitude-vs-base-energy ranges, but a
## cheap guard against a future config-value change beyond this class's
## control).
func compute_energy(time_seconds: float) -> float:
	assert(config != null, "TorchFlicker.config not wired")
	var frequencies: Array[float] = config.torch_flicker_frequencies_hz
	assert(not frequencies.is_empty(), "AmbientLifeConfig.torch_flicker_frequencies_hz is empty")
	var sum_of_sines: float = 0.0
	for frequency_hz: float in frequencies:
		sum_of_sines += sin(TAU * frequency_hz * time_seconds)
	var averaged: float = sum_of_sines / float(frequencies.size())
	var energy: float = config.torch_flicker_base_energy + config.torch_flicker_amplitude * averaged
	return maxf(energy, 0.0)
