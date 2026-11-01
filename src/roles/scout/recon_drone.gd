class_name ReconDrone
extends CharacterBody3D
## Piloted reconnaissance drone deployed by the Scout role.
## Fast, quiet flight; player body remains vulnerable while piloting.

signal recalled()

@export var flight_speed: float = 8.5
@export var max_battery: float = 12.0

var battery_remaining: float
var parent_player: Node3D

var _visual: Node3D
var _light: OmniLight3D


func _ready() -> void:
	battery_remaining = max_battery

	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	collider.shape = sphere
	add_child(collider)

	_visual = Node3D.new()
	add_child(_visual)

	# Drone chassis
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.12, 0.5)
	body.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("2c3e50")
	mat.metallic = 0.8
	body.material_override = mat
	_visual.add_child(body)

	# Sensor eye
	var eye := MeshInstance3D.new()
	var eye_box := BoxMesh.new()
	eye_box.size = Vector3(0.18, 0.08, 0.12)
	eye.mesh = eye_box
	var eye_mat := StandardMaterial3D.new()
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_mat.albedo_color = Color("66e0c2")
	eye.material_override = eye_mat
	eye.position = Vector3(0.0, -0.04, -0.22)
	_visual.add_child(eye)

	_light = OmniLight3D.new()
	_light.light_color = Color("66e0c2")
	_light.light_energy = 1.5
	_light.omni_range = 5.0
	add_child(_light)


func _physics_process(delta: float) -> void:
	battery_remaining -= delta
	if battery_remaining <= 0.0:
		recall_drone()
		return

	# Subtle hover bobbing
	_visual.position.y = sin(Time.get_ticks_msec() * 0.006) * 0.04


## Drive drone motion with camera-relative inputs.
func drive(input_vector: Vector2, camera_basis: Basis, delta: float) -> void:
	var right := Vector3(camera_basis.x.x, 0.0, camera_basis.x.z).normalized()
	var forward := Vector3(-camera_basis.z.x, 0.0, -camera_basis.z.z).normalized()
	var move_dir := (right * input_vector.x + forward * -input_vector.y).normalized()

	velocity.x = move_toward(velocity.x, move_dir.x * flight_speed, 28.0 * delta)
	velocity.z = move_toward(velocity.z, move_dir.z * flight_speed, 28.0 * delta)
	velocity.y = 0.0

	if not move_dir.is_zero_approx():
		rotation.y = lerp_angle(rotation.y, atan2(-move_dir.x, -move_dir.z), 1.0 - exp(-16.0 * delta))

	move_and_slide()


func recall_drone() -> void:
	recalled.emit()
	queue_free()
