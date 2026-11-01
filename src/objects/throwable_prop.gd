class_name ThrowableProp
extends CharacterBody3D
## Physical throwable and carriable prop for Sector 9 (e.g. power cell, canister, supply box).
## Manages carry attachment, ballistic throw velocity, arc prediction, and floor landing.

signal picked_up(carrier: Node3D)
signal thrown(initial_velocity: Vector3)
signal dropped()
signal landed_on_floor(point: Vector3)

enum State {
	IDLE_ON_GROUND,
	CARRIED,
	THROWN,
}

@export var prop_name: String = "Güç Hücresi"
@export var mass: float = 8.0
@export var gravity: float = 24.0
@export var dimensions := Vector3(0.6, 0.6, 0.6)

var current_state: State = State.IDLE_ON_GROUND
var carrier_node: Node3D

var _collision: CollisionShape3D
var _visual: MeshInstance3D
var _spawn_point := Vector3.ZERO


func _ready() -> void:
	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	_collision.shape = shape
	add_child(_collision)

	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	_visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ff9933")
	mat.metallic = 0.6
	mat.roughness = 0.4
	_visual.material_override = mat
	add_child(_visual)

	if _spawn_point.is_zero_approx():
		_spawn_point = global_position


func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return

	match current_state:
		State.CARRIED:
			if is_instance_valid(carrier_node):
				# Follow carrier hand/head anchor
				global_position = carrier_node.global_position + Vector3.UP * 1.6
				rotation = carrier_node.rotation
			else:
				drop_object()

		State.THROWN:
			velocity.y -= gravity * delta
			move_and_slide()
			if is_on_floor():
				current_state = State.IDLE_ON_GROUND
				velocity = Vector3.ZERO
				landed_on_floor.emit(global_position)

		State.IDLE_ON_GROUND:
			if not is_on_floor():
				velocity.y -= gravity * delta
				move_and_slide()


## Pick up prop; attaches to carrier and disables body collision.
func pick_up(carrier: Node3D) -> bool:
	if current_state == State.CARRIED or not is_instance_valid(carrier):
		return false

	carrier_node = carrier
	current_state = State.CARRIED
	velocity = Vector3.ZERO
	if is_instance_valid(_collision):
		_collision.set_deferred(&"disabled", true)
		_collision.disabled = true
	picked_up.emit(carrier)
	return true


## Throw prop along 3D velocity vector.
func throw_object(throw_velocity: Vector3) -> bool:
	if current_state != State.CARRIED:
		return false

	carrier_node = null
	current_state = State.THROWN
	velocity = throw_velocity
	if is_instance_valid(_collision):
		_collision.set_deferred(&"disabled", false)
		_collision.disabled = false
	thrown.emit(throw_velocity)
	return true


## Drop prop gently at current position.
func drop_object() -> void:
	carrier_node = null
	current_state = State.IDLE_ON_GROUND
	velocity = Vector3.DOWN * 0.5
	if is_instance_valid(_collision):
		_collision.set_deferred(&"disabled", false)
		_collision.disabled = false
	dropped.emit()


## Compute parabolic throw trajectory points for HUD/laser arc prediction.
static func calculate_throw_arc(start: Vector3, initial_vel: Vector3, grav: float = 24.0, steps: int = 30, dt: float = 0.05) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var pos := start
	var vel := initial_vel
	for i in range(steps):
		points.append(pos)
		vel.y -= grav * dt
		pos += vel * dt
		if pos.y <= 0.0:
			pos.y = 0.0
			points.append(pos)
			break
	return points


## Reset prop back to spawn location.
func reset_prop() -> void:
	drop_object()
	global_position = _spawn_point
	velocity = Vector3.ZERO
