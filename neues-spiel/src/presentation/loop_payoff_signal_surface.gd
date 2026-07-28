## Loop-payoff communication signal surface (Presentation Experience epic,
## story presentation-002; ADR-0001 primary).
##
## Scaffolding-only event/signal surface representing core-loop "payoff"
## moments (a project completes, a villager's satisfied-state changes, ...).
## This module is deliberately thin: it defines and re-emits a single,
## stable, keyed signal shape. It contains NO payoff mechanic of any kind
## (no simulation formulas, no reward-feedback presentation, no UI) -- that
## is the Feature-layer mechanic's job, plugged into this exact surface
## later without the surface needing to change shape (milestone-01 exit
## criterion #10's scaffolding-vs-mechanic split).
##
## Injected-tier per ADR-0001: headless-mockable via [method setup], wired
## into whichever owning scene needs it once real emitters/consumers exist.
## This module currently has no upstream [code]@export[/code] dependencies
## of its own -- it IS the shared dependency later systems bind to -- but
## still exposes the same explicitly-callable [method setup] entry point so
## GameWorld's uniform injected-tier wiring loop applies to it identically
## to every other module, in production and in headless tests alike.
##
## Story build-validation-009 (this revision, milestone criterion #7; CD
## Ruling 2, `production/creative-decisions-m02-preflight-2026-07-26.md` --
## PROVISIONAL, pending user ratification) adds a typed, OPTIONAL detail
## sidecar ([PayoffDetail]) carried alongside a payoff -- [signal
## payoff_signaled]'s own parameter list stays byte-identical (the CD
## ruling's own binding constraint: "a new payoff kind is a new
## `payoff_type` value, never a new signal or a reshaped parameter list").
## [method emit_payoff]'s trailing OPTIONAL [param detail] parameter and the
## new [method get_payoff_detail] accessor are strictly additive -- the
## presentation-002 scaffolding's own two-arg [method emit_payoff] callers
## compile and behave verbatim (Additivity). The real production writer is
## [LoopPayoffAdapter] (Build Validation & Navigability -> Presentation
## Experience wiring); this class itself constructs no [PayoffDetail] of its
## own and performs no analysis -- it stays the pure, thin surface it always
## was.
class_name LoopPayoffSignalSurface
extends Node

## Emitted for every core-loop payoff moment. [param payoff_type] identifies
## the KIND of payoff (e.g. [code]&"project_completed"[/code],
## [code]&"villager_satisfied"[/code]); [param subject] identifies the
## specific instance it happened to (a project id, a villager id, ...).
## This is the SOLE signal shape for every payoff moment the Feature-layer
## mechanic will ever fire -- a new payoff kind is a new [param payoff_type]
## value, never a new signal or a reshaped parameter list.
signal payoff_signaled(payoff_type: StringName, subject: StringName)

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## Keyed by "[param payoff_type]:[param subject]" -> true. Tracks which
## payoff keys are currently live so re-emission of the SAME key is a
## refresh-in-place, never a second/duplicate entry -- the idempotent,
## level-triggered-safe discipline this story's AC-3 requires, mirroring the
## toast/anchor "keyed by (signal type, subject); re-emission of a live key
## refreshes in place" discipline already established
## (design/ux/interaction-patterns.md).
var _active_payoffs: Dictionary[String, bool] = {}

## Story build-validation-009: the typed detail sidecar per live payoff key,
## keyed identically to [member _active_payoffs] (same [method _make_key]).
## A value of [code]null[/code] means the key is live but was emitted without
## a detail (the pre-existing two-arg [method emit_payoff] call shape) --
## [method get_payoff_detail] returns that same [code]null[/code], never a
## sentinel/placeholder [PayoffDetail].
var _active_payoff_details: Dictionary[String, PayoffDetail] = {}


## Explicitly-callable wiring entry point (ADR-0001). This module has no
## dependencies to assert -- the call exists purely so the uniform
## injected-tier wiring loop treats every module identically. Never called
## from [method _ready].
func setup() -> void:
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Signals a loop-payoff moment for ([param payoff_type], [param subject]).
## Called by the real emitters -- [LoopPayoffAdapter] (Build Validation &
## Navigability's `room_recognized`/`shelter_status_changed`, story
## build-validation-009) is the first real production writer; Building
## System project-completion / Villager AI contentment changes remain future,
## out-of-scope emitters -- and, in production, ultimately observed by the
## Feature-layer mechanic (also out of scope here).
##
## Re-invoking with the same ([param payoff_type], [param subject]) pair
## does not grow or duplicate any internal state -- the key is simply marked
## (still) live -- and the signal still re-emits so bound consumers can
## refresh their own presentation in place, never treating it as a fresh
## occurrence requiring new state.
##
## Story build-validation-009's [param detail] is trailing and OPTIONAL
## (CD Ruling 2's own binding constraint 1): [member _active_payoffs] and
## [member _active_payoff_details] are both written BEFORE [signal
## payoff_signaled] fires, so a synchronous handler that calls [method
## get_payoff_detail] from inside its own [signal payoff_signaled] callback
## observes the CURRENT record, never [code]null[/code] and never the
## previous occurrence's stale detail (Ordering constraint 1, asserted by
## `loop_payoff_real_signal_test.gd`, not merely assumed).
func emit_payoff(payoff_type: StringName, subject: StringName, detail: PayoffDetail = null) -> void:
	var key: String = _make_key(payoff_type, subject)
	_active_payoffs[key] = true
	_active_payoff_details[key] = detail
	payoff_signaled.emit(payoff_type, subject)


## Returns whether ([param payoff_type], [param subject]) is currently a
## live (most-recently-signaled, not yet cleared) payoff key.
func is_payoff_active(payoff_type: StringName, subject: StringName) -> bool:
	return _active_payoffs.get(_make_key(payoff_type, subject), false)


## Story build-validation-009: returns the [PayoffDetail] most recently
## written for ([param payoff_type], [param subject]) by [method emit_payoff],
## or [code]null[/code] if the key is not currently live, or was last emitted
## without a detail. Never re-derives/re-queries anything -- this is a plain
## read of the sidecar [method emit_payoff] already wrote (CD Ruling 2
## constraint 4: "presentation holds no reference back to the analysis
## module").
func get_payoff_detail(payoff_type: StringName, subject: StringName) -> PayoffDetail:
	return _active_payoff_details.get(_make_key(payoff_type, subject), null)


## Clears a payoff key's live state (e.g. once a consumer's presentation of
## it has fully resolved). Provided for the later Feature-layer consumer's
## convenience -- not exercised by this scaffolding story itself.
##
## Story build-validation-009 (Ordering constraint 2, asserted): erases the
## detail sidecar alongside the key -- no orphaned [PayoffDetail] is ever
## left behind for a key [method is_payoff_active] would report as cleared.
func clear_payoff(payoff_type: StringName, subject: StringName) -> void:
	var key: String = _make_key(payoff_type, subject)
	_active_payoffs.erase(key)
	_active_payoff_details.erase(key)


## Returns the number of currently-live payoff keys. Test-facing: proves
## re-emitting the same key never grows this count (AC-3 idempotency).
func get_active_payoff_count() -> int:
	return _active_payoffs.size()


func _make_key(payoff_type: StringName, subject: StringName) -> String:
	return "%s:%s" % [payoff_type, subject]
