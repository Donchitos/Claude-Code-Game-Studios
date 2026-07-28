## Reusable base for every module's typed tuning-config `Resource` (ADR-0002).
##
## Establishes ONE pattern every `<System>Config` class in the project
## follows: typed `@export` fields (one per GDD Tuning Knob), backed by a
## `.tres` text file (never `.res`), with a single `validate() -> Array[String]`
## entry point the owning module calls exactly once at boot, in its own
## `setup()` (ADR-0001/ADR-0005).
##
## Two-tier validation policy (ADR-0002 Decision), both expressed through the
## SAME `validate()` return value -- no second severity model is invented:
## - Single out-of-range scalar: [method validate] clamps the field to its
##   nearest valid bound (the ONE sanctioned runtime write to a config field,
##   performed by the config's own `validate()`) and appends a plain warning
##   string. Boot proceeds -- never halts for an isolated scalar.
## - Cross-value invariant a GDD marks BLOCKING: [method validate] appends a
##   string tagged via [method format_blocking] instead of clamping (there is
##   no single "nearest bound" fix for a relationship between two fields).
##   The owning module's `setup()` checks [method has_blocking_issue] on the
##   returned array and, if true, reuses ADR-0005's terminal boot-halt path
##   (see `ReferenceConfigConsumer` for the demonstrated wiring) -- the same
##   severity model Resource & Item Database's Failed state already
##   established, never a new one.
##
## Config is read-only from every consumer's perspective once [method
## validate] has run at boot; the clamp write above is the sole exception,
## and it lives inside the config class's own `validate()`, never in a
## consumer (grep-verifiable: `config\.\w* *=` outside a config class's own
## `validate()` must be zero).
##
## This class is marked `@abstract` -- it exists to be extended, never
## instantiated directly. Every concrete `<System>Config` subclass overrides
## [method validate] with its own fields' checks; there is no generic
## implementation because valid ranges and blocking invariants are entirely
## config-specific.
@abstract
class_name ConfigResource
extends Resource

## Prefix marking a [method validate] issue string as a GDD-declared BLOCKING
## cross-value invariant failure rather than a clamped single-field warning.
## Plain strings (no prefix) are warnings; callers distinguish the two tiers
## with [method has_blocking_issue] instead of a second return type or a new
## severity enum.
const BLOCKING_PREFIX: String = "BLOCKING: "


## Returns human-readable problems found in this config's current field
## values, clamping any single-field range issue to its nearest valid bound
## as a side effect (the sole sanctioned config-field write). Cross-value
## BLOCKING invariants are reported via [method format_blocking] instead of
## being clamped -- there is no value to clamp to for a relationship between
## two fields. An empty return means fully valid; boot proceeds untouched.
@abstract
func validate() -> Array[String]


## Tags [param message] as a GDD-declared BLOCKING cross-value invariant
## failure. Subclasses call this when appending to their [method validate]
## result instead of hand-writing the prefix, keeping the convention in one
## place.
static func format_blocking(message: String) -> String:
	return BLOCKING_PREFIX + message


## Returns true if [param issues] (a [method validate] result) contains at
## least one BLOCKING-tagged entry. This is the shared two-tier decision
## point every owning module's `setup()` calls: a single-field warning alone
## clamps and proceeds; any BLOCKING entry -- even alongside warnings --
## dominates and halts (ADR-0002 QA plan edge case).
static func has_blocking_issue(issues: Array[String]) -> bool:
	for issue: String in issues:
		if issue.begins_with(BLOCKING_PREFIX):
			return true
	return false
