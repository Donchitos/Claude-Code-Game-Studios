## F5 rescue-target search outcome (Story villager-ai-014, GDD F5 / Rule 15b /
## [TR-villager-ai-behavior-100]).
##
## `RefCounted`, not `Resource` -- a transient per-call value object, mirroring
## [JobSelectionResult]'s own "fresh lightweight wrapper per call, explicit
## hit-or-miss rather than a bare nullable return" precedent (that class's own
## doc comment). A bare `Vector3i` return has no way to distinguish "found
## cell (0,0,0)" from "search exhausted, nothing found" -- the explicit
## [member found] flag is what [method has_target] and every caller checks
## before trusting [member cell].
class_name RescueSearchResult
extends RefCounted

## Whether [method VillagerRescueTargetSearch.find_rescue_target] found a
## standable, unoccupied cell within its search bound. `false` means the
## search was exhausted up to `unstuck_rescue_max_radius` with no eligible
## cell found (GDD Edge Case 14) -- [member cell] is meaningless in that case.
var found: bool = false

## The chosen rescue cell (GDD F5's `rescue_target`), the nearest standable,
## unoccupied cell to the search origin -- meaningless when [member found] is
## `false`. Callers MUST check [method has_target] (or [member found] directly)
## before treating this as a valid teleport destination.
var cell: Vector3i = Vector3i.ZERO


func _init(p_found: bool = false, p_cell: Vector3i = Vector3i.ZERO) -> void:
	found = p_found
	cell = p_cell


## Whether this result carries a usable rescue target -- the explicit
## "hit or miss" check (see class doc comment); `false` means the watchdog
## (Story villager-ai-015) must defer the rescue to the next tick (GDD Edge
## Case 14).
func has_target() -> bool:
	return found
