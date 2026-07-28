## Performance measurement — Time & Tick System Story tick-007 (per-tick
## re-tune, TR-time-tick-system-044). ADR-0002 governing.
##
## **Advisory, not a Done/smoke blocker** (mirrors
## `tests/performance/villager_ai/stress_30_villager_test.gd`'s own
## precedent): `tests/run-tests.cmd` only globs `res://tests/unit` and
## `res://tests/integration` -- this file lives under `res://tests/performance`
## deliberately, so it never joins the BLOCKING regression gate. The timing
## numbers below are `print()`-ed for a human to transcribe into
## `production/qa/smoke-2026-07-25.md`, not asserted as a strict wall-clock
## pass/fail gate (the only hard assertions are a generous non-flaky sanity
## ceiling, matching the stress harness's own posture).
##
## **What this measures**: GDD AC17 / TR-time-tick-system-044's own combined
## cost -- [method TimeTickSystem.compute_game_delta] +
## [method TimeTickSystem._advance_ticks] -- averaged over many physics-frame
## equivalents, at both 1x and 3x warp, at `max_ticks_per_frame=12` (the
## Sprint 8 re-tuned value, `design/quick-specs/tick-rate-retune-2026-07-25.md`).
##
## **Honest scope caveat**: this is a headless microbenchmark of THIS
## system's own compute cost in isolation -- it does not include rendering,
## villager AI, or any other system sharing the real 16.6ms frame budget, and
## it is not driven by a live windowed build with 20-30 villagers. This
## system's own cost is population-independent (game_delta/accumulator math
## is O(1) regardless of villager count), so this measurement is a valid,
## real proxy for TR-044's own combined-cost claim -- but a full end-to-end
## frame profile against the story's literal "on the integrated build"
## wording requires the windowed tool-scene methodology `vox-018` uses, which
## is out of reach for a single headless GdUnit4 suite. Flagged explicitly
## rather than silently implied as full integrated-build verification.
##
## `time_tick_system.gd` deliberately carries no `class_name` (see its own
## doc comment), so isolated instances are constructed via a preloaded
## [GDScript] and duck-typed at each access site, matching every other
## `time_tick_system` test in this codebase.
class_name TimeTickPerFrameCostTest
extends GdUnitTestSuite

const TimeTickSystemScript: GDScript = preload("res://src/time_tick_system/time_tick_system.gd")

## Number of simulated physics frames averaged per warp setting -- large
## enough that per-call measurement noise (OS scheduling jitter) washes out.
const SAMPLE_COUNT: int = 5000

## GDD AC17 / TR-time-tick-system-044's own combined-cost guardrail.
const BUDGET_MS: float = 0.5


## Returns a fresh, never-autoloaded TimeTickSystem-script instance, wired
## with a GDD-default [TimeTickConfig] (`max_ticks_per_frame=12`) and already
## through [code]setup()[/code] -- isolated from the registered Autoload and
## the scene tree entirely. Untyped return -- see class doc comment.
func _new_system() -> Object:
	var system: Object = TimeTickSystemScript.new()
	@warning_ignore("unsafe_property_access")
	system.config = TimeTickConfig.new()
	@warning_ignore("unsafe_method_access")
	system.setup()
	return system


## Drives [param sample_count] physics-frame-equivalents at [param warp]
## through the real `_physics_process` call (the same call site production
## uses every frame), timed as one block via `Time.get_ticks_usec()`
## (mirrors `stress_30_villager_test.gd`'s own timing methodology). Returns
## the average per-frame cost in milliseconds.
func _measure_avg_frame_cost_ms(warp: int, sample_count: int) -> float:
	var system: Object = auto_free(_new_system())
	@warning_ignore("unsafe_method_access")
	system.set_warp(warp)
	const RAW_DELTA: float = 1.0 / 60.0

	var start_usec: int = Time.get_ticks_usec()
	for i: int in range(sample_count):
		@warning_ignore("unsafe_method_access")
		system._physics_process(RAW_DELTA)
	var elapsed_usec: int = Time.get_ticks_usec() - start_usec

	return (elapsed_usec / 1000.0) / float(sample_count)


func test_per_frame_cost_at_1x_warp_stays_under_budget() -> void:
	var avg_ms: float = _measure_avg_frame_cost_ms(1, SAMPLE_COUNT)
	print(
		"[tick-007 TR-044] 1x warp, max_ticks_per_frame=12: avg %.5f ms/frame over %d samples" %
		[avg_ms, SAMPLE_COUNT]
	)

	# Assert — generous non-flaky sanity ceiling (this codebase's stress-test
	# posture), not a razor-thin gate: the real number is orders of magnitude
	# under budget (a handful of float ops per frame), so any regression
	# gross enough to threaten the 0.5ms guardrail would blow this ceiling
	# many times over.
	assert_float(avg_ms).is_less(BUDGET_MS)


func test_per_frame_cost_at_3x_warp_stays_under_budget() -> void:
	var avg_ms: float = _measure_avg_frame_cost_ms(3, SAMPLE_COUNT)
	print(
		"[tick-007 TR-044] 3x warp, max_ticks_per_frame=12: avg %.5f ms/frame over %d samples" %
		[avg_ms, SAMPLE_COUNT]
	)

	# Assert — same generous ceiling; 3x warp fires more ticks per frame on
	# average (more `tick.emit()` calls draining the accumulator), so this
	# also exercises the re-tuned `max_ticks_per_frame=12` drain loop under
	# load, not just the 1x steady-state case.
	assert_float(avg_ms).is_less(BUDGET_MS)
