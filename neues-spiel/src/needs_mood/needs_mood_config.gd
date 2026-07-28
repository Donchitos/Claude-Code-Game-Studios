## Typed tuning-config Resource for the Needs & Mood System (ADR-0002),
## storing every knob `design/gdd/needs-mood-system.md`'s Tuning Knobs table
## names for story needs-mood-001: [member decay_per_tick_sleep],
## [member base_recovery_per_tick_sleep], [member ground_penalty],
## [member unsheltered_bed_multiplier], [member urgency_threshold],
## [member satisfied_threshold], [member mood_smoothing_ticks],
## [member mood_band_happy], [member mood_band_content],
## [member band_display_hysteresis].
##
## Wired into [NeedsMood] (injected-tier, ADR-0001) as another typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/needs_mood_config.tres`.
##
## Per CD Ruling 1 (`production/creative-decisions-m02-preflight-
## 2026-07-26.md`, Option B unmodified): [member decay_per_tick_sleep],
## [member base_recovery_per_tick_sleep], and [member mood_smoothing_ticks]
## ship at their GDD-stated defaults VERBATIM (0.07 / 0.5 / 40.0) -- no
## retune. A dedicated literal-value regression test guards against a silent
## future in-range retune (`production/qa/qa-plan-sprint-9-2026-07-26.md`
## Content Requirement 4).
##
## **AC29 -- this project's first genuine BLOCKING cross-value invariant**
## (GDD Core Rule 4, TR-needs-mood-system-020; per TD ruling NM-3, Core
## Rule 4's THREE-rung recovery ladder is authoritative over the GDD's own
## stale two-multiplier F2 variable-table row -- never implement the
## two-multiplier form anywhere in this module or its consumers): the sleep
## recovery ladder ordering `ground_penalty < unsheltered_bed_multiplier <
## 1.0` must hold. A violation is reported via [method
## ConfigResource.format_blocking] and is deliberately NEVER clamped -- there
## is no single "nearest bound" fix for a relationship between two fields
## (ADR-0002 Decision). The check runs against the RAW, pre-clamp field
## values (mirrors `BuildValidationConfig`'s advisory-check-before-clamp
## ordering), so an out-of-safe-range value can trip BOTH the ordinary
## single-field clamp warning AND the BLOCKING invariant in the same call --
## `has_blocking_issue()` still dominates either way.
class_name NeedsMoodConfig
extends ConfigResource

## Safe range for [member decay_per_tick_sleep] (GDD Tuning Knobs: 0.03-0.2).
const DECAY_PER_TICK_SLEEP_MIN: float = 0.03
const DECAY_PER_TICK_SLEEP_MAX: float = 0.2

## Safe range for [member base_recovery_per_tick_sleep] (GDD Tuning Knobs:
## 0.2-2.0).
const BASE_RECOVERY_PER_TICK_SLEEP_MIN: float = 0.2
const BASE_RECOVERY_PER_TICK_SLEEP_MAX: float = 2.0

## Safe range for [member ground_penalty] (GDD Tuning Knobs: 0.1-0.8).
const GROUND_PENALTY_MIN: float = 0.1
const GROUND_PENALTY_MAX: float = 0.8

## Safe range for [member unsheltered_bed_multiplier] (GDD Tuning Knobs:
## 0.5-0.9). See class doc comment's AC29 note -- the ladder invariant is
## checked independently of, and in addition to, this range.
const UNSHELTERED_BED_MULTIPLIER_MIN: float = 0.5
const UNSHELTERED_BED_MULTIPLIER_MAX: float = 0.9

## Safe range for [member urgency_threshold] (GDD Tuning Knobs: 10-40).
const URGENCY_THRESHOLD_MIN: float = 10.0
const URGENCY_THRESHOLD_MAX: float = 40.0

## Safe range for [member satisfied_threshold] (GDD Tuning Knobs: 80-100).
const SATISFIED_THRESHOLD_MIN: float = 80.0
const SATISFIED_THRESHOLD_MAX: float = 100.0

## Safe range for [member mood_smoothing_ticks] (GDD Tuning Knobs: 10-120).
const MOOD_SMOOTHING_TICKS_MIN: float = 10.0
const MOOD_SMOOTHING_TICKS_MAX: float = 120.0

## Safe range for [member band_display_hysteresis] (GDD Tuning Knobs: 0-3,
## Edge Case 10 anti-flapping reserve).
const BAND_DISPLAY_HYSTERESIS_MIN: float = 0.0
const BAND_DISPLAY_HYSTERESIS_MAX: float = 3.0

## Per-tick sleep decay (GDD F1, Tuning Knobs default: 0.07). CD Ruling 1:
## ships verbatim, no retune.
@export var decay_per_tick_sleep: float = 0.07

## Full-rate (sheltered bed, ×1.0) per-tick sleep recovery (GDD F2, Tuning
## Knobs default: 0.5). CD Ruling 1: ships verbatim, no retune.
@export var base_recovery_per_tick_sleep: float = 0.5

## Bottom rung of the sleep recovery ladder -- ground (no bed) rate
## multiplier (GDD Core Rule 4, Tuning Knobs default: 0.4).
@export var ground_penalty: float = 0.4

## Middle rung of the sleep recovery ladder -- owned bed, unsheltered (no
## valid room) rate multiplier (GDD Core Rule 4, Tuning Knobs default: 0.7).
## Invariant: [member ground_penalty] < this < 1.0 (AC29, class doc comment).
@export var unsheltered_bed_multiplier: float = 0.7

## Downward-cross threshold that emits "need urgent" and flips queryable
## state to Urgent (GDD Core Rule 3, Tuning Knobs default: 25).
@export var urgency_threshold: float = 25.0

## Upward-cross threshold, during Recovering, that emits "need satisfied"
## and ends recovery (GDD Core Rule 3, Tuning Knobs default: 95).
@export var satisfied_threshold: float = 95.0

## Mood EMA smoothing window, in ticks (GDD F3, Tuning Knobs default: 40.0).
## CD Ruling 1: ships verbatim, no retune (Alternative 3's carve-out was
## considered and rejected).
@export var mood_smoothing_ticks: float = 40.0

## Mood band boundary -- Happy at/above this value (GDD Core Rule 7, Tuning
## Knobs default: 70). Shared verbatim with Villager Info UI's display
## contract -- no safe-range clamp is defined for this knob (a UI-coupled
## design change, not a tunable scalar), so [method validate] does not
## range-check it.
@export var mood_band_happy: float = 70.0

## Mood band boundary -- Content at/above this value, below
## [member mood_band_happy] (GDD Core Rule 7, Tuning Knobs default: 40). Same
## no-range-check status as [member mood_band_happy].
@export var mood_band_content: float = 40.0

## Anti-flapping display reserve around the mood band boundaries (GDD Edge
## Case 10, Tuning Knobs default: 0 -- off).
@export var band_display_hysteresis: float = 0.0


## See [ConfigResource.validate]. Clamps every single-field range issue to
## its documented safe bound in place (the sole sanctioned runtime write to
## this config) and appends a warning string per clamped field, EXCEPT the
## AC29 ladder-ordering invariant, which is reported as BLOCKING instead of
## clamped (see class doc comment) and is checked against the RAW,
## pre-clamp values of [member ground_penalty]/
## [member unsheltered_bed_multiplier] before either field's own range clamp
## runs below -- so an out-of-safe-range value can trip both the ordinary
## clamp warning and the BLOCKING invariant in the same call.
func validate() -> Array[String]:
	var issues: Array[String] = []

	if decay_per_tick_sleep < DECAY_PER_TICK_SLEEP_MIN or decay_per_tick_sleep > DECAY_PER_TICK_SLEEP_MAX:
		issues.append(
			"decay_per_tick_sleep out of range [%s, %s], got %s -- clamped" %
			[DECAY_PER_TICK_SLEEP_MIN, DECAY_PER_TICK_SLEEP_MAX, decay_per_tick_sleep]
		)
		decay_per_tick_sleep = clampf(decay_per_tick_sleep, DECAY_PER_TICK_SLEEP_MIN, DECAY_PER_TICK_SLEEP_MAX)

	if (
		base_recovery_per_tick_sleep < BASE_RECOVERY_PER_TICK_SLEEP_MIN
		or base_recovery_per_tick_sleep > BASE_RECOVERY_PER_TICK_SLEEP_MAX
	):
		issues.append(
			"base_recovery_per_tick_sleep out of range [%s, %s], got %s -- clamped" %
			[BASE_RECOVERY_PER_TICK_SLEEP_MIN, BASE_RECOVERY_PER_TICK_SLEEP_MAX, base_recovery_per_tick_sleep]
		)
		base_recovery_per_tick_sleep = clampf(
			base_recovery_per_tick_sleep, BASE_RECOVERY_PER_TICK_SLEEP_MIN, BASE_RECOVERY_PER_TICK_SLEEP_MAX
		)

	# AC29 (BLOCKING) -- checked against the RAW, pre-clamp values (mirrors
	# BuildValidationConfig's advisory-before-clamp ordering). There is no
	# single "nearest bound" fix for a relationship between two fields, so a
	# violation is tagged BLOCKING rather than clamped (ADR-0002 Decision).
	if not (ground_penalty < unsheltered_bed_multiplier and unsheltered_bed_multiplier < 1.0):
		issues.append(ConfigResource.format_blocking(
			(
				"ground_penalty (%s) must be < unsheltered_bed_multiplier (%s) < 1.0 --"
				+ " the sleep recovery ladder invariant (GDD Core Rule 4, Tuning Knobs)"
			) % [ground_penalty, unsheltered_bed_multiplier]
		))

	if ground_penalty < GROUND_PENALTY_MIN or ground_penalty > GROUND_PENALTY_MAX:
		issues.append(
			"ground_penalty out of range [%s, %s], got %s -- clamped" %
			[GROUND_PENALTY_MIN, GROUND_PENALTY_MAX, ground_penalty]
		)
		ground_penalty = clampf(ground_penalty, GROUND_PENALTY_MIN, GROUND_PENALTY_MAX)

	if unsheltered_bed_multiplier < UNSHELTERED_BED_MULTIPLIER_MIN or unsheltered_bed_multiplier > UNSHELTERED_BED_MULTIPLIER_MAX:
		issues.append(
			"unsheltered_bed_multiplier out of range [%s, %s], got %s -- clamped" %
			[UNSHELTERED_BED_MULTIPLIER_MIN, UNSHELTERED_BED_MULTIPLIER_MAX, unsheltered_bed_multiplier]
		)
		unsheltered_bed_multiplier = clampf(
			unsheltered_bed_multiplier, UNSHELTERED_BED_MULTIPLIER_MIN, UNSHELTERED_BED_MULTIPLIER_MAX
		)

	if urgency_threshold < URGENCY_THRESHOLD_MIN or urgency_threshold > URGENCY_THRESHOLD_MAX:
		issues.append(
			"urgency_threshold out of range [%s, %s], got %s -- clamped" %
			[URGENCY_THRESHOLD_MIN, URGENCY_THRESHOLD_MAX, urgency_threshold]
		)
		urgency_threshold = clampf(urgency_threshold, URGENCY_THRESHOLD_MIN, URGENCY_THRESHOLD_MAX)

	if satisfied_threshold < SATISFIED_THRESHOLD_MIN or satisfied_threshold > SATISFIED_THRESHOLD_MAX:
		issues.append(
			"satisfied_threshold out of range [%s, %s], got %s -- clamped" %
			[SATISFIED_THRESHOLD_MIN, SATISFIED_THRESHOLD_MAX, satisfied_threshold]
		)
		satisfied_threshold = clampf(satisfied_threshold, SATISFIED_THRESHOLD_MIN, SATISFIED_THRESHOLD_MAX)

	if mood_smoothing_ticks < MOOD_SMOOTHING_TICKS_MIN or mood_smoothing_ticks > MOOD_SMOOTHING_TICKS_MAX:
		issues.append(
			"mood_smoothing_ticks out of range [%s, %s], got %s -- clamped" %
			[MOOD_SMOOTHING_TICKS_MIN, MOOD_SMOOTHING_TICKS_MAX, mood_smoothing_ticks]
		)
		mood_smoothing_ticks = clampf(mood_smoothing_ticks, MOOD_SMOOTHING_TICKS_MIN, MOOD_SMOOTHING_TICKS_MAX)

	if band_display_hysteresis < BAND_DISPLAY_HYSTERESIS_MIN or band_display_hysteresis > BAND_DISPLAY_HYSTERESIS_MAX:
		issues.append(
			"band_display_hysteresis out of range [%s, %s], got %s -- clamped" %
			[BAND_DISPLAY_HYSTERESIS_MIN, BAND_DISPLAY_HYSTERESIS_MAX, band_display_hysteresis]
		)
		band_display_hysteresis = clampf(
			band_display_hysteresis, BAND_DISPLAY_HYSTERESIS_MIN, BAND_DISPLAY_HYSTERESIS_MAX
		)

	return issues
