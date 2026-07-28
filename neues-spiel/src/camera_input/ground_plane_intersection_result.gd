## Explicit "hit or miss" result for [method CameraInput.get_ground_plane_intersection]
## / [method CameraInput.derive_ground_plane_intersection] (Story cam-006,
## TR-camera-input-050).
##
## Mirrors [RaycastHitResult]'s established precedent
## (`src/voxel_world/raycast_hit_result.gd`): an explicit boolean + payload,
## never a bare sentinel/null for a legitimate "no intersection" outcome (the
## ray parallel to -- or pointing away from -- the ground plane, e.g. a
## skyward mouse position, is an ordinary, expected outcome, not an error).
## `RefCounted`, matching that same shared precedent.
class_name GroundPlaneIntersectionResult
extends RefCounted

## True if the ray intersects the ground plane in front of the ray's own
## origin (`t >= 0`). Callers MUST check this before trusting [member
## position].
var hit: bool

## The intersection point -- meaningless when [member hit] is `false`.
var position: Vector3


func _init(p_hit: bool, p_position: Vector3 = Vector3.ZERO) -> void:
	hit = p_hit
	position = p_position
