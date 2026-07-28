## Typed tuning-config Resource for Time & Tick System (ADR-0002), storing
## every knob from design/gdd/time-tick-system.md's Tuning Knobs section.
##
## `time_tick_system.gd` (Autoload-tier, ADR-0001) `load()`s a `.tres`
## instance of this class directly via its own `const CONFIG_PATH` -- there
## is no injected-tier `@export` wiring for Autoload-tier modules. [method
## validate] applies [ConfigResource]'s single-field clamp+warn tier to all
## three ranged knobs; this config has no GDD-declared BLOCKING cross-value
## invariant, so the BLOCKING tier is never exercised here (story tick-001
## scope).
class_name TimeTickConfig
extends ConfigResource

## Safe range for [member ticks_per_second] (GDD Tuning Knobs).
const TICKS_PER_SECOND_MIN: float = 1.0
const TICKS_PER_SECOND_MAX: float = 5.0

## Safe range for [member max_ticks_per_frame] (GDD Tuning Knobs).
const MAX_TICKS_PER_FRAME_MIN: int = 5
const MAX_TICKS_PER_FRAME_MAX: int = 30

## Safe range for [member max_raw_delta] (GDD Tuning Knobs).
const MAX_RAW_DELTA_MIN: float = 0.05
const MAX_RAW_DELTA_MAX: float = 0.2

## Base tick rate at 1x time-warp. GDD default: 4.0 (Slice revision
## 2026-07-23, raised from 2.0 -- the vertical slice ran at 4.0 throughout).
## Time-warp itself is multiplied in separately by the game_delta formula
## (story tick-002, out of scope here).
@export var ticks_per_second: float = 4.0

## Upper bound on ticks fired in one frame after a stall (GDD default: 12 --
## re-tuned 10->12, Sprint 8 coordinated re-tune,
## `design/quick-specs/tick-rate-retune-2026-07-25.md`: ~50% margin over the
## 8 ticks strictly needed to keep a `max_raw_delta`-clamped frame "honest"
## under the debug 20x warp gear, still mid-range in the GDD's documented
## 5-30 safe band; story tick-007).
@export var max_ticks_per_frame: int = 12

## Clamp ceiling applied to raw engine delta before any use (GDD default:
## 0.1s).
@export var max_raw_delta: float = 0.1

## Fixed set of selectable time-warp speeds (GDD: {1, 2, 3}). Not
## range-validated below -- the GDD documents this as a fixed set, not a
## tunable numeric range (see GDD Open Questions for future step additions).
@export var time_warp_options: Array[int] = [1, 2, 3]


## See [ConfigResource.validate]. Clamps each ranged knob to its GDD-stated
## safe bound in place (the sole sanctioned runtime write to this config) and
## appends a warning string per clamped field. No BLOCKING cross-value
## invariant exists for this config (ADR-0002 two-tier policy) -- an
## out-of-range single field always clamps and proceeds, never halts boot.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if ticks_per_second < TICKS_PER_SECOND_MIN or ticks_per_second > TICKS_PER_SECOND_MAX:
		issues.append(
			"ticks_per_second out of range [%s, %s], got %s -- clamped" %
			[TICKS_PER_SECOND_MIN, TICKS_PER_SECOND_MAX, ticks_per_second]
		)
		ticks_per_second = clampf(ticks_per_second, TICKS_PER_SECOND_MIN, TICKS_PER_SECOND_MAX)
	if max_ticks_per_frame < MAX_TICKS_PER_FRAME_MIN or max_ticks_per_frame > MAX_TICKS_PER_FRAME_MAX:
		issues.append(
			"max_ticks_per_frame out of range [%s, %s], got %s -- clamped" %
			[MAX_TICKS_PER_FRAME_MIN, MAX_TICKS_PER_FRAME_MAX, max_ticks_per_frame]
		)
		max_ticks_per_frame = clampi(max_ticks_per_frame, MAX_TICKS_PER_FRAME_MIN, MAX_TICKS_PER_FRAME_MAX)
	if max_raw_delta < MAX_RAW_DELTA_MIN or max_raw_delta > MAX_RAW_DELTA_MAX:
		issues.append(
			"max_raw_delta out of range [%s, %s], got %s -- clamped" %
			[MAX_RAW_DELTA_MIN, MAX_RAW_DELTA_MAX, max_raw_delta]
		)
		max_raw_delta = clampf(max_raw_delta, MAX_RAW_DELTA_MIN, MAX_RAW_DELTA_MAX)
	return issues
