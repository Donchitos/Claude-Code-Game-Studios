## Explicit "always-valid" world-ray result for [method CameraInput.get_world_ray]
## (Story cam-006, `design/gdd/camera-input.md` Core Rule 8, TR-camera-input-
## 028/029/038).
##
## Unlike [RaycastHitResult] (`src/voxel_world/raycast_hit_result.gd`), this
## value carries NO `hit`/miss flag -- the mouse world-ray itself is ALWAYS
## computable, in every [CameraInput] state including Suspended (a frozen but
## valid transform), by design [TR-camera-input-029]; callers never need an
## availability branch. `RefCounted`, not `Resource` -- a transient per-call
## value object, mirroring [RaycastHitResult]/`CellContents`'s shared
## precedent of a fresh lightweight wrapper per call, fields set once in
## [method _init] and treated as read-only by every consumer.
class_name WorldRay
extends RefCounted

## World-space ray origin -- for this project's perspective-only camera,
## always equal to the camera's own derived position ([method
## CameraInput.get_camera_position]), independent of the queried screen
## point [TR-camera-input-028].
var origin: Vector3

## World-space ray direction, normalized -- varies per queried screen point.
## Computed from the SAME sampled screen point as [member origin], in the
## same call [TR-camera-input-038].
var direction: Vector3


func _init(p_origin: Vector3, p_direction: Vector3) -> void:
	origin = p_origin
	direction = p_direction
