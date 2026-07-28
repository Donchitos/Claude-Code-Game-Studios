## Typed tuning-config Resource for [WallTool] (ADR-0002) -- GDD Formula F1's
## `wall_height` knob (`design/gdd/building-system.md` Tuning Knobs table:
## 1-8, default 3, [TR-building-system-091]).
##
## Wired into [WallTool] (injected-tier, ADR-0001) as another typed `@export`
## dependency; a matching `.tres` instance lives at
## `res://data/config/wall_tool_config.tres`. Mirrors [CommitPipelineConfig]/
## [PlacementPickConfig]'s established one-config-per-module precedent --
## created fresh here rather than folded into a not-yet-existing shared
## `BuildingSystemConfig`.
##
## The GDD's own cross-module Lockstep invariant ("Build Validation's
## `max_room_height` (8) must stay >= this knob's maximum") is validated by
## Build Validation's own config per ADR-0002's documented narrow exception
## (that module's `setup()` reads both configs) -- NOT re-checked here.
class_name WallToolConfig
extends ConfigResource

## Safe range for [member wall_height] (`design/gdd/building-system.md`
## Tuning Knobs table: 1-8, default 3 -- "How tall a one-action wall extrudes
## (F1). Prototype-validated default." [TR-building-system-091]).
const WALL_HEIGHT_MIN: int = 1
const WALL_HEIGHT_MAX: int = 8

## How many cells a wall run extrudes upward in one action (GDD Formula F1,
## [TR-building-system-077]/[TR-building-system-044]) -- the UI stepper
## clamps player input to this same [1, 8] range at the input layer; this
## field is [WallTool]'s own source of truth, never re-derived from a
## hardcoded literal in [WallTool] itself.
@export var wall_height: int = 3


## See [ConfigResource.validate]. Clamps [member wall_height] to its
## GDD-documented safe range and appends a warning string if clamped -- no
## BLOCKING cross-value invariant is owned by THIS config (the
## `max_room_height >= wall_height` lockstep invariant is Build Validation's
## own cross-module check, ADR-0002 Risks), mirroring
## [CommitPipelineConfig]/[PlacementPickConfig]'s clamp-only precedent.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if wall_height < WALL_HEIGHT_MIN or wall_height > WALL_HEIGHT_MAX:
		issues.append(
			"wall_height out of range [%s, %s], got %s -- clamped" %
			[WALL_HEIGHT_MIN, WALL_HEIGHT_MAX, wall_height]
		)
		wall_height = clampi(wall_height, WALL_HEIGHT_MIN, WALL_HEIGHT_MAX)
	return issues
