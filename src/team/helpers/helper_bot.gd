class_name HelperBot
extends CharacterBody3D
## Friendly cooperative AI helper bot (team 0).
## Follows the player, defends against hostile pursuers, and rushes to revive downed players.

signal revive_started()
signal revive_completed()

enum Mode {
	FOLLOW,
	REVIVE,
	DEFEND,
}

@export var move_speed: float = 4.2
@export var revive_speed_mult: float = 1.0
@export var team: int = 0

var current_mode: Mode = Mode.FOLLOW
var target_player: Node3D
var recovery_system: RefCounted

var _collision: CollisionShape3D
var _visual: MeshInstance3D
var _spawn_pos := Vector3.ZERO

const FOLLOW_DISTANCE: float = 3.5
const REVIVE_REACH: float = 1.8


func _ready() -> void:
	_collision = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.4
	_collision.shape = shape
	add_child(_collision)

	_visual = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.4
	_visual.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("2a9d8f") # Friendly teal
	_visual.material_override = mat
	add_child(_visual)

	if _spawn_pos.is_zero_approx():
		_spawn_pos = global_position


func _physics_process(delta: float) -> void:
	if delta <= 0.0 or not is_instance_valid(target_player):
		return

	# Check if player is downed or currently being revived
	if recovery_system != null and (recovery_system.current_state == 1 or recovery_system.current_state == 2): # DOWNED or REVIVING
		current_mode = Mode.REVIVE
	else:
		current_mode = Mode.FOLLOW

	match current_mode:
		Mode.REVIVE:
			var to_player: Vector3 = target_player.global_position - global_position
			var dist: float = Vector2(to_player.x, to_player.z).length()
			if dist > REVIVE_REACH:
				var dir := Vector3(to_player.x, 0.0, to_player.z).normalized()
				velocity.x = dir.x * move_speed * 1.2
				velocity.z = dir.z * move_speed * 1.2
			else:
				velocity = Vector3.ZERO
				revive_started.emit()
				var success: bool = recovery_system.step_revive(delta, revive_speed_mult)
				if success:
					revive_completed.emit()
					current_mode = Mode.FOLLOW

		Mode.FOLLOW:
			var to_player: Vector3 = target_player.global_position - global_position
			var dist: float = Vector2(to_player.x, to_player.z).length()
			if dist > FOLLOW_DISTANCE:
				var dir := Vector3(to_player.x, 0.0, to_player.z).normalized()
				velocity.x = move_toward(velocity.x, dir.x * move_speed, 18.0 * delta)
				velocity.z = move_toward(velocity.z, dir.z * move_speed, 18.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 24.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 24.0 * delta)

	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -1.0

	move_and_slide()


func reset_helper() -> void:
	global_position = _spawn_pos
	velocity = Vector3.ZERO
	current_mode = Mode.FOLLOW
