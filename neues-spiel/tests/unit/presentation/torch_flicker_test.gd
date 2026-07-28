## Unit test — [TorchFlicker] (Presentation Experience story
## presentation-001 Sub-scope A; art-bible A5 restated at SS6.5: "Must
## respect A5 (sub-3Hz) -- no free pass on flicker rate. ... asserted, not
## eyeballed").
##
## Covers:
## 1. headless setup() with no rendering, driving a real [OmniLight3D].
## 2. compute_energy() is a pure, deterministic function of elapsed time --
##    the SAME input time always produces the SAME energy, no RNG anywhere.
## 3. THE sub-3Hz assertion itself: samples compute_energy() over a long
##    window at a fine time-step and counts zero-crossings around the
##    baseline energy to estimate the waveform's actual oscillation
##    frequency -- a numeric measurement, not a screenshot judgment call.
## 4. light_energy never goes negative.
##
## NOTE (accumulated pitfall): frequency estimation here is a TEST-side
## helper, not a second production API -- [TorchFlicker] itself only needs
## to expose the pure [method TorchFlicker.compute_energy] sample function
## for this to be measurable at all.
class_name TorchFlickerTest
extends GdUnitTestSuite

## Sample window and step for the numeric frequency-estimation check --
## long enough to span several periods of the slowest default component
## (0.6 Hz -> ~1.67s period) and fine enough (200 Hz sample rate) to resolve
## zero-crossings accurately up to several times the 3 Hz cap.
const SAMPLE_WINDOW_SECONDS: float = 10.0
const SAMPLE_STEP_SECONDS: float = 0.005


func test_setup_headless_drives_a_real_light() -> void:
	var light: OmniLight3D = auto_free(OmniLight3D.new())
	var flicker: TorchFlicker = auto_free(TorchFlicker.new())
	flicker.config = AmbientLifeConfig.new()
	flicker.light = light
	assert_bool(flicker.is_set_up()).is_false()

	flicker.setup()

	assert_bool(flicker.is_set_up()).is_true()
	assert_float(light.light_energy).is_equal_approx(flicker.compute_energy(0.0), 0.0001)


func test_compute_energy_is_deterministic_for_the_same_time() -> void:
	var flicker: TorchFlicker = auto_free(TorchFlicker.new())
	flicker.config = AmbientLifeConfig.new()

	var first: float = flicker.compute_energy(3.7)
	var second: float = flicker.compute_energy(3.7)

	assert_float(first).is_equal_approx(second, 0.00001)


func test_compute_energy_matches_hand_derived_formula_at_t_zero() -> void:
	# At t=0.0, every sin(...) term is 0.0, so the averaged sway is 0.0 and
	# the result must equal base_energy exactly -- a hand-computable ground
	# truth, not just "same value twice."
	var config := AmbientLifeConfig.new()
	var flicker: TorchFlicker = auto_free(TorchFlicker.new())
	flicker.config = config

	assert_float(flicker.compute_energy(0.0)).is_equal_approx(config.torch_flicker_base_energy, 0.00001)


func test_compute_energy_never_goes_negative_across_a_sample_window() -> void:
	var config := AmbientLifeConfig.new()
	config.torch_flicker_base_energy = 0.05
	config.torch_flicker_amplitude = 2.0
	config.validate()
	var flicker: TorchFlicker = auto_free(TorchFlicker.new())
	flicker.config = config

	var t: float = 0.0
	while t < SAMPLE_WINDOW_SECONDS:
		assert_float(flicker.compute_energy(t)).is_greater_equal(0.0)
		t += SAMPLE_STEP_SECONDS


func test_default_flicker_waveform_dominant_frequency_is_sub_3hz() -> void:
	# THE A5 assertion: measure, do not eyeball. Estimates the combined
	# waveform's oscillation rate via zero-crossing counting around the
	# baseline energy over a long sample window, then asserts it is under
	# 3.0 Hz -- both against the codebase's default config AND against a
	# deliberately worst-case config (every component pinned at the config's
	# own clamp ceiling, the fastest waveform this class can ever produce).
	var flicker: TorchFlicker = auto_free(TorchFlicker.new())
	flicker.config = AmbientLifeConfig.new()

	var estimated_hz: float = _estimate_dominant_frequency_hz(flicker, flicker.config.torch_flicker_base_energy)

	assert_float(estimated_hz).is_less(3.0)


func test_worst_case_all_components_at_clamp_ceiling_is_still_sub_3hz() -> void:
	var config := AmbientLifeConfig.new()
	config.torch_flicker_frequencies_hz = [
		AmbientLifeConfig.TORCH_FLICKER_FREQUENCY_HZ_MAX,
		AmbientLifeConfig.TORCH_FLICKER_FREQUENCY_HZ_MAX,
		AmbientLifeConfig.TORCH_FLICKER_FREQUENCY_HZ_MAX,
	]
	config.validate()
	var flicker: TorchFlicker = auto_free(TorchFlicker.new())
	flicker.config = config

	var estimated_hz: float = _estimate_dominant_frequency_hz(flicker, config.torch_flicker_base_energy)

	assert_float(estimated_hz).is_less(3.0)


func test_config_rejects_above_cap_before_flicker_ever_sees_it() -> void:
	# Defense in depth: a caller that forgets to call validate() on a
	# hand-built config would otherwise feed TorchFlicker an above-cap
	# frequency directly -- proving the REAL production path (setup() calls
	# validate() at boot per ADR-0002/0005) is what keeps this sub-3Hz, not
	# an accidental property of compute_energy() itself.
	var config := AmbientLifeConfig.new()
	config.torch_flicker_frequencies_hz = [10.0]

	var issues: Array[String] = config.validate()

	assert_float(config.torch_flicker_frequencies_hz[0]).is_less(3.0)
	assert_bool(issues.is_empty()).is_false()


## Estimates the dominant oscillation frequency (Hz) of [param
## flicker].compute_energy() over [constant SAMPLE_WINDOW_SECONDS] by
## counting zero-crossings of (energy - [param baseline_energy]) and
## dividing by 2 (a full period crosses the baseline twice), then dividing
## by the window length.
func _estimate_dominant_frequency_hz(flicker: TorchFlicker, baseline_energy: float) -> float:
	var crossing_count: int = 0
	var previous_sign: float = signf(flicker.compute_energy(0.0) - baseline_energy)
	var t: float = SAMPLE_STEP_SECONDS
	while t < SAMPLE_WINDOW_SECONDS:
		var current_sign: float = signf(flicker.compute_energy(t) - baseline_energy)
		if current_sign != 0.0 and previous_sign != 0.0 and current_sign != previous_sign:
			crossing_count += 1
			previous_sign = current_sign
		elif current_sign != 0.0:
			previous_sign = current_sign
		t += SAMPLE_STEP_SECONDS
	var period_count: float = float(crossing_count) / 2.0
	return period_count / SAMPLE_WINDOW_SECONDS
