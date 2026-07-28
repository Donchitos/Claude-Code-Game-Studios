## Reference/example injected-tier module (Foundation Spine Story 003,
## ADR-0002 + ADR-0001) demonstrating how a real module wires a
## [ConfigResource] and applies the two-tier clamp/halt policy in its own
## `setup()`.
##
## Mirrors `ReferenceInjectedModule`'s DI shape (Story 001): a typed
## `@export` dependency wired via a scene file's Inspector in production, or
## assigned directly after `Node.new()` in a headless test, with all
## wiring/validation living in the explicitly-callable [method setup] --
## never in `_ready()`. This class additionally demonstrates the config
## consumer half of ADR-0002: [method setup] calls `config.validate()`
## exactly once, logs any warnings, and records any BLOCKING issues for
## [GameWorld]'s boot gate to observe afterward.
##
## Concrete modules with real tuning knobs (Building System, Voxel World,
## ...) follow this exact shape in their own epics; this class is not one of
## them and must never gain gameplay behaviour of its own.
class_name ReferenceConfigConsumer
extends Node

## Config dependency (ADR-0002): wired via a scene file's Inspector in
## production, or assigned directly in a headless test. Never read inside
## `_ready()` -- see [method setup].
@export var config: ReferenceModuleConfig

## True once [method setup] has completed at least once. Lets callers (and
## tests) confirm the explicit wiring call actually ran, mirroring
## `ReferenceInjectedModule.is_set_up()`.
var _is_set_up: bool = false

## The BLOCKING-tagged subset of the most recent `config.validate()` result,
## if any. Populated by [method setup]; read by [GameWorld]'s boot gate via
## [method get_boot_blocking_issues] to decide whether to reuse the terminal
## halt path (ADR-0005). Empty whenever the config was fully valid or only
## carried clamped single-field warnings.
var _boot_blocking_issues: Array[String] = []


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts
## [member config] was wired, then applies ADR-0002's two-tier policy:
## every non-BLOCKING issue is a clamp+warn (already applied by `validate()`
## itself) and is logged via `push_warning`; any BLOCKING issue is recorded
## for [method get_boot_blocking_issues] instead of being treated as fatal
## here -- the actual halt decision and terminal-path reuse live in
## [GameWorld]'s boot gate (the single choke point ADR-0005 establishes),
## not in this module.
##
## This is the ONLY sanctioned call site for this method's logic: the owning
## root ([GameWorld]) calls it once, during the WIRING phase, after the boot
## gate has resolved RID's Ready outcome.
func setup() -> void:
	assert(config != null, "ReferenceConfigConsumer.config not wired")
	var issues: Array[String] = config.validate()
	_boot_blocking_issues = issues.filter(
		func(issue: String) -> bool: return issue.begins_with(ConfigResource.BLOCKING_PREFIX)
	)
	for issue: String in issues:
		if not issue.begins_with(ConfigResource.BLOCKING_PREFIX):
			push_warning(issue)
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Returns the BLOCKING-tagged issues (if any) found in the most recent
## `config.validate()` call. [GameWorld]'s boot gate duck-types this method
## on every injected-tier module after calling `setup()`; a non-empty result
## triggers the same terminal boot-halt path used for RID's Failed outcome
## (ADR-0002 Decision, ADR-0005 reuse) -- no new severity model, no new halt
## mechanism.
func get_boot_blocking_issues() -> Array[String]:
	return _boot_blocking_issues
