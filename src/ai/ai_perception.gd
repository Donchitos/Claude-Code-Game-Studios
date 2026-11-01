class_name AIPerception
extends RefCounted
## Sensory perception system: Vision (FOV cone + LOS raycast) and Hearing (acoustic noise radius).
## Calculates continuous suspicion level (0.0 - 100.0) without omniscient telepathy.

var vision_range: float = 14.0
var vision_fov_degrees: float = 110.0
var hearing_range: float = 16.0
var suspicion: float = 0.0

const SUSPICION_THRESHOLD_AWARE: float = 35.0
const SUSPICION_THRESHOLD_ALERT: float = 75.0
const SUSPICION_DECAY_RATE: float = 12.0
const SUSPICION_GAIN_RATE: float = 55.0


func update_suspicion(delta: float, is_target_visible: bool, distance: float) -> float:
	if delta <= 0.0:
		return suspicion

	if is_target_visible and distance <= vision_range:
		var distance_factor: float = clampf(1.0 - (distance / vision_range), 0.25, 1.0)
		suspicion = minf(suspicion + delta * SUSPICION_GAIN_RATE * distance_factor, 100.0)
	else:
		suspicion = maxf(suspicion - delta * SUSPICION_DECAY_RATE, 0.0)

	return suspicion


## Check if a target point is within the horizontal sight cone.
func is_in_sight_cone(eye_pos: Vector3, eye_forward: Vector3, target_pos: Vector3) -> bool:
	var to_target: Vector3 = target_pos - eye_pos
	var dist: float = to_target.length()
	if dist > vision_range or dist <= 0.001:
		return false

	var dir_to_target: Vector3 = to_target.normalized()
	var forward: Vector3 = Vector3(eye_forward.x, 0.0, eye_forward.z).normalized()
	var angle_rad: float = forward.angle_to(dir_to_target)
	var max_angle_rad: float = deg_to_rad(vision_fov_degrees * 0.5)

	return angle_rad <= max_angle_rad


## Check if an emitted noise event is heard at this location.
func can_hear_noise(listener_pos: Vector3, noise_origin: Vector3, noise_radius: float) -> bool:
	var dist: float = listener_pos.distance_to(noise_origin)
	var effective_radius: float = minf(hearing_range, noise_radius)
	return dist <= effective_radius


func reset_perception() -> void:
	suspicion = 0.0
