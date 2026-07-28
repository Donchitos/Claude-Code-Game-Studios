## Reference/example config Resource (Foundation Spine Story 003, ADR-0002)
## demonstrating [ConfigResource]'s two-tier `validate()` policy: a
## single-field range clamp+warn tier ([member cadence_seconds]) and a
## cross-value BLOCKING invariant tier ([member lower_bound] /
## [member upper_bound]).
##
## Concrete per-module configs (`TimeTickConfig`, `VoxelWorldConfig`, ...)
## follow this exact shape in their own epics/stories, with real GDD-stated
## defaults and real tuning knobs -- this class is not one of them and must
## never gain real gameplay tuning values of its own. A matching `.tres`
## instance lives at `res://data/config/reference_module_config.tres`,
## demonstrating the required text-file backing (ADR-0002; never `.res`).
class_name ReferenceModuleConfig
extends ConfigResource

## Minimum valid value for [member cadence_seconds] (single-field tier).
const CADENCE_MIN: float = 0.1

## Maximum valid value for [member cadence_seconds] (single-field tier).
const CADENCE_MAX: float = 10.0

## Example tunable with a documented safe range -- a value outside
## [constant CADENCE_MIN]/[constant CADENCE_MAX] is clamped by [method
## validate], not halted.
@export var cadence_seconds: float = 1.0

## Example paired tunable (BLOCKING tier): the only requirement is
## [member lower_bound] < [member upper_bound]. There is no single-field
## "nearest bound" fix for a relationship between two fields, so a violation
## is tagged BLOCKING rather than clamped (ADR-0002 Decision).
@export var lower_bound: float = 0.0

## See [member lower_bound].
@export var upper_bound: float = 100.0


## See [ConfigResource.validate]. Clamps [member cadence_seconds] in place
## (the sole sanctioned runtime write to this config) and reports the
## [member lower_bound]/[member upper_bound] invariant as BLOCKING when
## violated -- both tiers can appear in the same call; the BLOCKING tier
## dominates the caller's clamp-or-halt decision either way.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if cadence_seconds < CADENCE_MIN or cadence_seconds > CADENCE_MAX:
		issues.append(
			"cadence_seconds out of range [%s, %s], got %s -- clamped" %
			[CADENCE_MIN, CADENCE_MAX, cadence_seconds]
		)
		cadence_seconds = clampf(cadence_seconds, CADENCE_MIN, CADENCE_MAX)
	if lower_bound >= upper_bound:
		issues.append(ConfigResource.format_blocking(
			"lower_bound (%s) must be < upper_bound (%s)" % [lower_bound, upper_bound]
		))
	return issues
