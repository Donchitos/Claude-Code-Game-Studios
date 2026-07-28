## Typed tuning-config Resource for [PlacementPick] (ADR-0002), storing the one
## tuning knob this story's DDA pick needs.
##
## Wired into [PlacementPick] (injected-tier, ADR-0001) as another typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/placement_pick_config.tres`. Mirrors
## [CameraInputConfig]/[VoxelWorldConfig]'s established one-config-per-module
## precedent -- created fresh here rather than folded into a not-yet-existing
## shared `BuildingSystemConfig`, matching [ToolStateMachine]'s own doc-comment
## precedent ("no tuning knob is introduced by the state machine itself").
class_name PlacementPickConfig
extends ConfigResource

## Sanity floor for [member max_pick_distance] -- a non-positive pick distance
## would make every raycast an instant miss, which is nonsensical. Mirrors
## [CameraInputConfig]'s "sanity floor, not a GDD-documented tuning range"
## precedent (`FOV_DEGREES_MIN` doc comment) for a value the GDD's Tuning
## Knobs table does not yet list.
const MAX_PICK_DISTANCE_MIN: float = 1.0

## Maximum ray length, world units, for [method VoxelWorldGrid.raycast_cells]
## calls in the placement pick path. `[assumption]` -- building-system.md's
## Tuning Knobs table does not yet list a pick-distance knob; this default
## (200.0) comfortably exceeds [CameraInputConfig.distance_max]'s 60.0 zoom
## ceiling plus reasonable off-center screen-ray travel, so a valid on-screen
## pick is never truncated by this bound in ordinary play. Flagged for the GDD
## to adopt explicitly at its next revision, mirroring [CameraInputConfig
## .fov_degrees]'s own `[assumption]` precedent.
@export var max_pick_distance: float = 200.0

## Safe range for [member drag_threshold_px] (`design/gdd/building-system.md`
## Tuning Knobs: 4-12, default 6 -- "Prototype-validated"; Story
## building-021, GDD Formula F4, [TR-building-system-081]).
const DRAG_THRESHOLD_PX_MIN: float = 4.0
const DRAG_THRESHOLD_PX_MAX: float = 12.0

## Click-vs-drag screen-space pixel threshold (GDD Formula F4): `is_drag =
## cursor_travel_px >= drag_threshold_px` while `build_place` is held --
## [PlacementPick] (Story building-021's extension to that class) is the sole
## consumer, via [method PlacementPick.is_drag]. Default 6 -- prototype-
## validated (GDD Tuning Knobs). [TR-building-system-081]
@export var drag_threshold_px: float = 6.0


## See [ConfigResource.validate]. Clamps [member max_pick_distance] and
## [member drag_threshold_px] to their respective bounds and appends a
## warning string per clamped field -- no BLOCKING cross-value invariant
## exists for this config (ADR-0002 two-tier policy), mirroring
## [CameraInputConfig]'s clamp-only precedent.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if max_pick_distance < MAX_PICK_DISTANCE_MIN:
		issues.append(
			"max_pick_distance must be >= %s, got %s -- clamped" %
			[MAX_PICK_DISTANCE_MIN, max_pick_distance]
		)
		max_pick_distance = MAX_PICK_DISTANCE_MIN
	if drag_threshold_px < DRAG_THRESHOLD_PX_MIN or drag_threshold_px > DRAG_THRESHOLD_PX_MAX:
		issues.append(
			"drag_threshold_px out of range [%s, %s], got %s -- clamped" %
			[DRAG_THRESHOLD_PX_MIN, DRAG_THRESHOLD_PX_MAX, drag_threshold_px]
		)
		drag_threshold_px = clampf(drag_threshold_px, DRAG_THRESHOLD_PX_MIN, DRAG_THRESHOLD_PX_MAX)
	return issues
