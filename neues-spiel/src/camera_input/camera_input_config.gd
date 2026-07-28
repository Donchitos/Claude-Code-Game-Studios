## Typed tuning-config Resource for Camera & Input (ADR-0002), storing every
## knob from design/gdd/camera-input.md's Tuning Knobs section.
##
## Wired into [CameraInput] (injected-tier, ADR-0001) as another typed
## `@export` dependency; a matching `.tres` instance lives at
## `res://data/config/camera_input_config.tres`. [method validate] applies
## [ConfigResource]'s single-field clamp+warn tier to every knob that carries
## a documented GDD safe range. `pitch_min`/`pitch_max` are the fixed
## pole-safety margin the GDD Formulas section calls out
## [TR-camera-input-037] and `start_yaw` is unbounded (wraps) per the GDD
## Tuning Knobs table, so neither is range-checked here. This config carries
## no GDD-declared BLOCKING cross-value invariant (story cam-001 scope) --
## mirrors `TimeTickConfig`'s precedent of a clamp-only config.
class_name CameraInputConfig
extends ConfigResource

## Safe range for [member start_distance] (GDD Tuning Knobs: 4.0-60.0).
const START_DISTANCE_MIN: float = 4.0
const START_DISTANCE_MAX: float = 60.0

## Safe range for [member start_pitch] (GDD Tuning Knobs: 0.15-1.5).
const START_PITCH_MIN: float = 0.15
const START_PITCH_MAX: float = 1.5

## Safe range for [member zoom_factor_in] (GDD Tuning Knobs: 0.8-0.95).
const ZOOM_FACTOR_IN_MIN: float = 0.8
const ZOOM_FACTOR_IN_MAX: float = 0.95

## Safe range for [member zoom_factor_out] (GDD Tuning Knobs: 1.05-1.2).
const ZOOM_FACTOR_OUT_MIN: float = 1.05
const ZOOM_FACTOR_OUT_MAX: float = 1.2

## Safe range for [member q_e_rotate_step] (GDD Tuning Knobs: 0.05-0.3).
const Q_E_ROTATE_STEP_MIN: float = 0.05
const Q_E_ROTATE_STEP_MAX: float = 0.3

## Safe range for [member mouse_drag_sensitivity] (GDD Tuning Knobs:
## 0.003-0.02).
const MOUSE_DRAG_SENSITIVITY_MIN: float = 0.003
const MOUSE_DRAG_SENSITIVITY_MAX: float = 0.02

## Safe range for [member pan_speed_factor] (GDD Tuning Knobs: 0.3-1.5).
const PAN_SPEED_FACTOR_MIN: float = 0.3
const PAN_SPEED_FACTOR_MAX: float = 1.5

## Safe range for [member max_delta_time] (GDD Tuning Knobs: 0.05-0.2).
const MAX_DELTA_TIME_MIN: float = 0.05
const MAX_DELTA_TIME_MAX: float = 0.2

## Sanity floor for [member world_width_cells] -- not a GDD-stated tuning
## range (that range, 256-2048 validated / 16,000 production target, belongs
## to voxel-world.md's OWN config and is that module's own concern to
## enforce). This is only a positivity guard so story cam-005's pan-bound
## clamp formula never divides/multiplies against a zero or negative extent.
const WORLD_WIDTH_CELLS_MIN: int = 1

## Sanity floor for [member world_depth_cells]. See [constant WORLD_WIDTH_CELLS_MIN].
const WORLD_DEPTH_CELLS_MIN: int = 1

## Sanity floor for [member cell_size]. See [constant WORLD_WIDTH_CELLS_MIN].
const CELL_SIZE_MIN: float = 0.01

## Sanity floor for [member pan_bound_margin] -- a negative margin would push
## the pan-bound clamp outside the world extent, which is nonsensical; margin
## 0 (the GDD default) is the valid floor. [TR-camera-input-049]
const PAN_BOUND_MARGIN_MIN: float = 0.0

## Sanity range for [member fov_degrees] -- NOT a GDD-documented tuning knob
## (camera-input.md's Tuning Knobs table has no fov row yet). Story cam-006's
## world-ray projection math needs a vertical FOV value from somewhere; per
## ADR-0002/TR-camera-input-019's "no hardcoded values" rule it is exposed as
## a config knob rather than a literal in `camera_input.gd`, defaulted to
## Godot's own `Camera3D` engine default (75.0) -- `[assumption]`, flagged for
## the GDD to adopt explicitly at its next revision (see [member fov_degrees]).
const FOV_DEGREES_MIN: float = 1.0
const FOV_DEGREES_MAX: float = 179.0

## Starting spherical radius (GDD default: 18.0). [TR-camera-input-021]
@export var start_distance: float = 18.0

## Starting horizontal orbit angle, radians, unbounded/wraps (GDD default:
## 0.7). [TR-camera-input-021]
@export var start_yaw: float = 0.7

## Starting vertical orbit angle, radians (GDD default: 0.95).
## [TR-camera-input-021]
@export var start_pitch: float = 0.95

## Minimum spherical radius (GDD default: 4.0). Consumed by the zoom clamp
## (story cam-004, out of scope here).
@export var distance_min: float = 4.0

## Maximum spherical radius (GDD default: 60.0). Consumed by the zoom clamp
## (story cam-004, out of scope here).
@export var distance_max: float = 60.0

## Multiplicative zoom-in factor per wheel event (GDD default: 0.9). Consumed
## by story cam-004, out of scope here.
@export var zoom_factor_in: float = 0.9

## Multiplicative zoom-out factor per wheel event (GDD default: 1.1).
## Consumed by story cam-004, out of scope here.
@export var zoom_factor_out: float = 1.1

## Fixed pole-safety minimum for pitch, radians (GDD default: 0.15) -- the
## derivation degenerates as pitch approaches the poles (+-90 deg); this is
## the documented safety margin, not a free tunable. [TR-camera-input-037]
@export var pitch_min: float = 0.15

## Fixed pole-safety maximum for pitch, radians (GDD default: 1.5). See
## [member pitch_min]. [TR-camera-input-037]
@export var pitch_max: float = 1.5

## Yaw step per Q/E key press, radians (GDD default: 0.12). Consumed by
## [CameraInput._apply_qe_rotation] (story cam-003).
@export var q_e_rotate_step: float = 0.12

## Yaw/pitch change per pixel of middle-mouse-drag (GDD default: 0.008).
## Consumed by [CameraInput._apply_mouse_drag_rotation] (story cam-003).
@export var mouse_drag_sensitivity: float = 0.008

## Pan speed multiplier applied to `delta * distance` (GDD default: 0.7).
## Consumed by story cam-005, out of scope here.
@export var pan_speed_factor: float = 0.7

## Clamp ceiling applied to raw engine delta-time before it enters the pan
## formula, seconds (GDD default: 0.1). Consumed by
## [CameraInput._apply_pan] (story cam-005). [TR-camera-input-043]
@export var max_delta_time: float = 0.1

## Mirrored copy of Voxel World's `world_width_cells` tuning knob
## (voxel-world.md Tuning Knobs, GDD default: 2000) -- Camera & Input reads
## this as a plain config value and never calls Voxel World directly
## (camera-input.md Interactions + Cross-References). Bounds the pan target's
## X axis: `[pan_bound_margin, world_width_cells * cell_size - pan_bound_margin]`.
## [TR-camera-input-026]
@export var world_width_cells: int = 2000

## Mirrored copy of Voxel World's `world_depth_cells` tuning knob (GDD
## default: 2000). See [member world_width_cells]. Bounds the pan target's Z
## axis. [TR-camera-input-026]
@export var world_depth_cells: int = 2000

## Mirrored copy of Voxel World's fixed `cell_size` (voxel-world.md
## TR-voxel-world-012, locked at 1.0 -- flush blocks, no gap). [TR-camera-input-026]
@export var cell_size: float = 1.0

## Small margin subtracted from the world-extent pan-bound clamp on every
## side (GDD default: 0.0 -- RESOLVED in camera-input.md Open Questions: no
## building-driven extra margin needed, keep 0 until playtest says otherwise).
## Margin 0 is a valid, fully-supported configuration, not an edge case.
## [TR-camera-input-049]
@export var pan_bound_margin: float = 0.0

## Vertical field-of-view, degrees, for [CameraInput.get_world_ray]'s
## projection math (story cam-006). `[assumption]` -- Godot's own `Camera3D`
## engine default (75.0); camera-input.md's Tuning Knobs table does not yet
## list this knob, see [constant FOV_DEGREES_MIN] doc comment.
@export var fov_degrees: float = 75.0


## See [ConfigResource.validate]. Clamps every ranged knob to its GDD-stated
## safe bound in place (the sole sanctioned runtime write to this config) and
## appends a warning string per clamped field. `pitch_min`/`pitch_max` are the
## fixed pole-safety margin and `start_yaw` is unbounded, so neither is
## range-checked. No BLOCKING cross-value invariant exists for this config
## (ADR-0002 two-tier policy) -- an out-of-range single field always clamps
## and proceeds, never halts boot.
func validate() -> Array[String]:
	var issues: Array[String] = []
	if start_distance < START_DISTANCE_MIN or start_distance > START_DISTANCE_MAX:
		issues.append(
			"start_distance out of range [%s, %s], got %s -- clamped" %
			[START_DISTANCE_MIN, START_DISTANCE_MAX, start_distance]
		)
		start_distance = clampf(start_distance, START_DISTANCE_MIN, START_DISTANCE_MAX)
	if start_pitch < START_PITCH_MIN or start_pitch > START_PITCH_MAX:
		issues.append(
			"start_pitch out of range [%s, %s], got %s -- clamped" %
			[START_PITCH_MIN, START_PITCH_MAX, start_pitch]
		)
		start_pitch = clampf(start_pitch, START_PITCH_MIN, START_PITCH_MAX)
	if zoom_factor_in < ZOOM_FACTOR_IN_MIN or zoom_factor_in > ZOOM_FACTOR_IN_MAX:
		issues.append(
			"zoom_factor_in out of range [%s, %s], got %s -- clamped" %
			[ZOOM_FACTOR_IN_MIN, ZOOM_FACTOR_IN_MAX, zoom_factor_in]
		)
		zoom_factor_in = clampf(zoom_factor_in, ZOOM_FACTOR_IN_MIN, ZOOM_FACTOR_IN_MAX)
	if zoom_factor_out < ZOOM_FACTOR_OUT_MIN or zoom_factor_out > ZOOM_FACTOR_OUT_MAX:
		issues.append(
			"zoom_factor_out out of range [%s, %s], got %s -- clamped" %
			[ZOOM_FACTOR_OUT_MIN, ZOOM_FACTOR_OUT_MAX, zoom_factor_out]
		)
		zoom_factor_out = clampf(zoom_factor_out, ZOOM_FACTOR_OUT_MIN, ZOOM_FACTOR_OUT_MAX)
	if q_e_rotate_step < Q_E_ROTATE_STEP_MIN or q_e_rotate_step > Q_E_ROTATE_STEP_MAX:
		issues.append(
			"q_e_rotate_step out of range [%s, %s], got %s -- clamped" %
			[Q_E_ROTATE_STEP_MIN, Q_E_ROTATE_STEP_MAX, q_e_rotate_step]
		)
		q_e_rotate_step = clampf(q_e_rotate_step, Q_E_ROTATE_STEP_MIN, Q_E_ROTATE_STEP_MAX)
	if mouse_drag_sensitivity < MOUSE_DRAG_SENSITIVITY_MIN or mouse_drag_sensitivity > MOUSE_DRAG_SENSITIVITY_MAX:
		issues.append(
			"mouse_drag_sensitivity out of range [%s, %s], got %s -- clamped" %
			[MOUSE_DRAG_SENSITIVITY_MIN, MOUSE_DRAG_SENSITIVITY_MAX, mouse_drag_sensitivity]
		)
		mouse_drag_sensitivity = clampf(
			mouse_drag_sensitivity, MOUSE_DRAG_SENSITIVITY_MIN, MOUSE_DRAG_SENSITIVITY_MAX
		)
	if pan_speed_factor < PAN_SPEED_FACTOR_MIN or pan_speed_factor > PAN_SPEED_FACTOR_MAX:
		issues.append(
			"pan_speed_factor out of range [%s, %s], got %s -- clamped" %
			[PAN_SPEED_FACTOR_MIN, PAN_SPEED_FACTOR_MAX, pan_speed_factor]
		)
		pan_speed_factor = clampf(pan_speed_factor, PAN_SPEED_FACTOR_MIN, PAN_SPEED_FACTOR_MAX)
	if max_delta_time < MAX_DELTA_TIME_MIN or max_delta_time > MAX_DELTA_TIME_MAX:
		issues.append(
			"max_delta_time out of range [%s, %s], got %s -- clamped" %
			[MAX_DELTA_TIME_MIN, MAX_DELTA_TIME_MAX, max_delta_time]
		)
		max_delta_time = clampf(max_delta_time, MAX_DELTA_TIME_MIN, MAX_DELTA_TIME_MAX)
	if world_width_cells < WORLD_WIDTH_CELLS_MIN:
		issues.append(
			"world_width_cells must be >= %s, got %s -- clamped" %
			[WORLD_WIDTH_CELLS_MIN, world_width_cells]
		)
		world_width_cells = WORLD_WIDTH_CELLS_MIN
	if world_depth_cells < WORLD_DEPTH_CELLS_MIN:
		issues.append(
			"world_depth_cells must be >= %s, got %s -- clamped" %
			[WORLD_DEPTH_CELLS_MIN, world_depth_cells]
		)
		world_depth_cells = WORLD_DEPTH_CELLS_MIN
	if cell_size < CELL_SIZE_MIN:
		issues.append(
			"cell_size must be >= %s, got %s -- clamped" % [CELL_SIZE_MIN, cell_size]
		)
		cell_size = CELL_SIZE_MIN
	if pan_bound_margin < PAN_BOUND_MARGIN_MIN:
		issues.append(
			"pan_bound_margin must be >= %s, got %s -- clamped" %
			[PAN_BOUND_MARGIN_MIN, pan_bound_margin]
		)
		pan_bound_margin = PAN_BOUND_MARGIN_MIN
	if fov_degrees < FOV_DEGREES_MIN or fov_degrees > FOV_DEGREES_MAX:
		issues.append(
			"fov_degrees out of range [%s, %s], got %s -- clamped" %
			[FOV_DEGREES_MIN, FOV_DEGREES_MAX, fov_degrees]
		)
		fov_degrees = clampf(fov_degrees, FOV_DEGREES_MIN, FOV_DEGREES_MAX)
	return issues
