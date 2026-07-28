## Once-per-stuck-episode gate for the `villager_unstuck_search_failed` event
## (Story villager-ai-014, GDD Edge Case 14 / AC53 /
## [TR-villager-ai-behavior-105]): "a `villager_unstuck_search_failed` event
## fires exactly once for the stuck episode (not once per tick)" -- the search
## itself (Story villager-ai-014's own [VillagerRescueTargetSearch]) retries
## every tick while a villager remains stuck past `unstuck_rescue_max_radius`
## (GDD Edge Case 14: "the search retries every tick until a cell is found"),
## so SOMETHING must remember "have I already told the caller about this
## specific exhausted-search episode" across repeated per-tick calls -- a
## detail a pure, stateless function (like [VillagerRescueTargetSearch.
## find_rescue_target] itself) cannot hold on its own.
##
## Ownership split, per this story's own Implementation Notes ("the
## once-per-episode `villager_unstuck_search_failed` flag is owned here (the
## watchdog owns the per-episode lifecycle)"): THIS class owns the flag's
## storage and the "have I already reported" gating logic. The Unstuck
## Watchdog (Story villager-ai-015) owns the actual EPISODE lifecycle -- it
## decides when a stuck episode begins (creating/reusing an instance per
## villager) and ends (calling [method reset_episode] the instant
## `stuck_tick_count` resets to 0, GDD F5's own variable) -- and is the one
## that actually emits the `villager_unstuck_search_failed` signal/event,
## gated behind [method should_report_failure]'s return value. Emitting the
## real event, and deciding when a rescue's search should even run, are both
## Story villager-ai-015's scope (this story's Out of Scope: "the watchdog
## trigger... and success telemetry") -- this class supplies only the boolean
## gate primitive.
##
## `RefCounted`, one instance per villager (per stuck episode owner) --
## mirrors [VillagerAi]'s own per-villager-instance shape, NOT a shared
## population-wide singleton like [VillagerNavGraph]/[VillagerDecidingScheduler]
## (there is nothing to share here: each villager's stuck episode is its own
## independent history).
class_name RescueSearchFailureGate
extends RefCounted

## `true` once [method should_report_failure] has returned `true` for the
## CURRENT episode -- reset only by [method reset_episode].
var _already_reported: bool = false


## Returns `true` the FIRST time this is called since construction or the most
## recent [method reset_episode] call; every subsequent call returns `false`
## until the episode resets -- the exact "exactly once... not once per tick"
## gating this story's AC53 requires. Marks the flag as reported as a side
## effect of returning `true` (there is no separate "peek" -- a caller that
## calls this is committing to reporting the event now).
func should_report_failure() -> bool:
	if _already_reported:
		return false
	_already_reported = true
	return true


## Resets the gate for a NEW stuck episode (called by the watchdog, Story
## villager-ai-015, the instant `stuck_tick_count` returns to `0` -- GDD F5).
## Idempotent: resetting an already-fresh gate is a harmless no-op.
func reset_episode() -> void:
	_already_reported = false
