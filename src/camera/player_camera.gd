class_name PlayerCamera
extends Camera3D
## Fixed-angle exponential follow camera. The lab injects target and shared tuning.

const TuningScript = preload("res://src/data/movement_tuning.gd")

@export var target: Node3D
@export var tuning: TuningScript
## Optional ground reference: follow X/Z without bobbing with the airborne body.
@export var height_anchor: Node3D

## Dinamik Kamera Sarsıntısı (Trauma/Shake) ve İniş Çökmesi (Landing Dip)
var trauma: float = 0.0
var landing_dip: float = 0.0
var _shake_time: float = 0.0

const TRAUMA_DECAY: float = 1.4
const MAX_SHAKE_OFFSET: float = 0.25
const MAX_SHAKE_ROLL: float = 0.03
const DIP_RECOVERY_SPEED: float = 7.5


## Kamera sarsıntı travması ekler (0.0 - 1.0)
func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Sert inişlerde kamerayı hafifçe aşağı çöktürür
func add_landing_dip(speed: float) -> void:
	if speed > 2.0:
		landing_dip = minf(landing_dip + (speed * 0.035), 0.35)


func _ready() -> void:
	if tuning == null:
		push_error("PlayerCamera requires an injected MovementTuning resource.")
		set_process(false)
		return
	snap_to_target()


func _process(delta: float) -> void:
	if tuning == null or not is_instance_valid(target):
		return
	fov = clampf(tuning.camera_fov, 1.0, 179.0)
	var edge: Vector2 = Vector2.ZERO
	if get_window().has_focus() and not Input.is_action_pressed(&"camera_center"):
		edge = screen_edge_offset(get_viewport().get_mouse_position(),
			get_viewport().get_visible_rect().size)
	var right: Vector3 = Vector3(global_basis.x.x, 0.0, global_basis.x.z).normalized()
	if right.is_zero_approx():
		right = Vector3.RIGHT
	var back: Vector3 = right.cross(Vector3.UP).normalized()
	# Dinamik sarsıntı ve çökme güncellemesi
	if trauma > 0.0:
		_shake_time += delta * 32.0
		trauma = maxf(trauma - delta * TRAUMA_DECAY, 0.0)
	if landing_dip > 0.0:
		landing_dip = maxf(landing_dip - delta * DIP_RECOVERY_SPEED, 0.0)
	var shake_power: float = trauma * trauma
	var shake_offset: Vector3 = Vector3(
		sin(_shake_time * 1.3) * MAX_SHAKE_OFFSET * shake_power,
		-landing_dip + cos(_shake_time * 1.7) * (MAX_SHAKE_OFFSET * 0.5) * shake_power,
		sin(_shake_time * 0.8) * MAX_SHAKE_OFFSET * shake_power
	)
	var desired: Vector3 = follow_point() + _camera_offset() + right * edge.x + back * edge.y + shake_offset
	global_position = smooth_follow(global_position, desired,
		tuning.camera_follow_sharpness, delta)
	# Keep the inclination fixed while following/panning; mouse movement translates
	# the camera rather than orbiting or rotating the movement coordinate system.
	look_at(global_position - _camera_offset(), Vector3.UP)
	if shake_power > 0.001:
		rotation.z += sin(_shake_time * 1.9) * MAX_SHAKE_ROLL * shake_power


## Place the camera immediately over its target, clearing any accumulated edge pan.
## The offset (height, depth) gives a roughly 55-degree downward view toward -Z.
func snap_to_target() -> void:
	if tuning == null or not is_instance_valid(target) or not is_inside_tree():
		return
	fov = clampf(tuning.camera_fov, 1.0, 179.0)
	global_position = follow_point() + _camera_offset()
	look_at(follow_point(), Vector3.UP)
	reset_physics_interpolation()


## Return a ground-plane pan vector in meters: x is screen-right, y screen-down.
## No tree or Input access. Only outer edge bands pan; corners share one distance cap.
func screen_edge_offset(mouse: Vector2, size: Vector2) -> Vector2:
	if tuning == null or not tuning.camera_edge_pan_enabled or size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ZERO
	var threshold: float = clampf(tuning.camera_edge_threshold, 0.5, 0.99)
	var unit: Vector2 = Vector2(mouse.x / size.x, mouse.y / size.y)
	var edge: Vector2 = Vector2(_edge_axis(unit.x, threshold), _edge_axis(unit.y, threshold))
	return edge.limit_length(1.0) * maxf(tuning.camera_edge_pan, 0.0)


## Exponentially approach a fixed destination; independent of frame subdivision.
## Negative delta or sharpness are clamped so the position can never extrapolate.
static func smooth_follow(current: Vector3, desired: Vector3, sharpness: float, delta: float) -> Vector3:
	var weight: float = 1.0 - exp(-maxf(sharpness, 0.0) * maxf(delta, 0.0))
	return current.lerp(desired, weight)


## Resolve target X/Z and optional grounded Y; usable outside a scene for tests.
func follow_point() -> Vector3:
	if not is_instance_valid(target):
		return Vector3.ZERO
	var point := target.global_position if target.is_inside_tree() else target.position
	if is_instance_valid(height_anchor):
		point.y = height_anchor.global_position.y if height_anchor.is_inside_tree() else height_anchor.position.y
	return point


func _camera_offset() -> Vector3:
	return Vector3(0.0, maxf(tuning.camera_height, 0.001), maxf(tuning.camera_depth, 0.001))


static func _edge_axis(unit: float, threshold: float) -> float:
	if unit > threshold:
		return clampf((unit - threshold) / (1.0 - threshold), 0.0, 1.0)
	if unit < 1.0 - threshold:
		return -clampf((1.0 - threshold - unit) / (1.0 - threshold), 0.0, 1.0)
	return 0.0
