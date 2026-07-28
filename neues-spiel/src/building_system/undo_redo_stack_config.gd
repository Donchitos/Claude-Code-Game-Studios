## Typed tuning-config Resource for [UndoRedoStack] (ADR-0002) -- GDD Core
## Rule 17's `undo_stack_depth` knob (Story building-032, Edge Case 9,
## [TR-building-system-089]).
##
## Wired into [UndoRedoStack] (injected-tier, ADR-0001) as another typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/undo_redo_stack_config.tres`. Mirrors
## [CommitPipelineConfig]/[ConstructionTickLoopConfig]'s established
## one-config-per-module precedent.
class_name UndoRedoStackConfig
extends ConfigResource

## Safe range for [member undo_stack_depth] (`design/gdd/building-system.md`
## Tuning Knobs table: 10-200, default 50 -- "How far back a player can undo
## (Core Rule 17, Edge Case 9). Worst-case memory is now bounded and
## checkable: 200 commands x 512 cells x a small per-cell record ~= low
## single-digit MB -- negligible against the 4 GB ceiling. The cap exists
## for predictability").
const UNDO_STACK_DEPTH_MIN: int = 10
const UNDO_STACK_DEPTH_MAX: int = 200

## Hard cap on the number of commands [UndoRedoStack] retains simultaneously
## (Core Rule 17, Edge Case 9, AC30) -- beyond this depth the oldest command
## is discarded silently on the next new command.
@export var undo_stack_depth: int = 50


## See [ConfigResource.validate]. Clamps [member undo_stack_depth] to its
## GDD-documented safe range and appends a warning string if clamped -- no
## BLOCKING cross-value invariant exists for this config (ADR-0002 two-tier
## policy), mirroring [CommitPipelineConfig]'s own clamp-only precedent.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if undo_stack_depth < UNDO_STACK_DEPTH_MIN or undo_stack_depth > UNDO_STACK_DEPTH_MAX:
		issues.append(
			"undo_stack_depth out of range [%s, %s], got %s -- clamped" %
			[UNDO_STACK_DEPTH_MIN, UNDO_STACK_DEPTH_MAX, undo_stack_depth]
		)
		undo_stack_depth = clampi(undo_stack_depth, UNDO_STACK_DEPTH_MIN, UNDO_STACK_DEPTH_MAX)
	return issues
