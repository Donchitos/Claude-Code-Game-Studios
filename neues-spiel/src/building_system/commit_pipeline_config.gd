## Typed tuning-config Resource for [CommitPipeline] (ADR-0002) -- GDD Core
## Rule 9's `max_cells_per_command` cap (Story building-022,
## [TR-building-system-049]).
##
## Wired into [CommitPipeline] (injected-tier, ADR-0001) as another typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/commit_pipeline_config.tres`. Mirrors
## [PlacementPickConfig]/[ConstructionTickLoopConfig]'s established
## one-config-per-module precedent -- created fresh here rather than folded
## into a not-yet-existing shared `BuildingSystemConfig`.
class_name CommitPipelineConfig
extends ConfigResource

## Safe range for [member max_cells_per_command] (`design/gdd/building-system.md`
## Tuning Knobs table: 128-2048, default 512 -- "Hard cap on blueprint cells
## per commit (Core Rule 9). 512 admits the longest possible wall (64-cell
## run x height 8); larger floors take multiple drags. Bounds preview draw
## calls, undo payload, and job-queue injection in one number"
## [TR-building-system-049]).
const MAX_CELLS_PER_COMMAND_MIN: int = 128
const MAX_CELLS_PER_COMMAND_MAX: int = 2048

## Hard cap on the number of blueprint cells a single [method
## CommitPipeline.commit] call may create (Core Rule 9, Story building-022,
## AC39) -- a commit whose post-bounds-clamp cell count exceeds this is
## rejected in full (zero cells created), never silently truncated the way
## the bounds clamp itself (Edge Case 1) is.
@export var max_cells_per_command: int = 512


## See [ConfigResource.validate]. Clamps [member max_cells_per_command] to
## its GDD-documented safe range and appends a warning string if clamped --
## no BLOCKING cross-value invariant exists for this config (ADR-0002
## two-tier policy), mirroring [PlacementPickConfig]/
## [ConstructionTickLoopConfig]'s clamp-only precedent.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if max_cells_per_command < MAX_CELLS_PER_COMMAND_MIN or max_cells_per_command > MAX_CELLS_PER_COMMAND_MAX:
		issues.append(
			"max_cells_per_command out of range [%s, %s], got %s -- clamped" %
			[MAX_CELLS_PER_COMMAND_MIN, MAX_CELLS_PER_COMMAND_MAX, max_cells_per_command]
		)
		max_cells_per_command = clampi(
			max_cells_per_command, MAX_CELLS_PER_COMMAND_MIN, MAX_CELLS_PER_COMMAND_MAX
		)
	return issues
