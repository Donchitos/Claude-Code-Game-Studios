class_name BreakerRole
extends Node
## Breaker role controller: Shoulder Bash and Shield Wall abilities.

signal bash_started()
signal bash_hit_target(target: Node3D)
signal bash_ended()
signal shield_deployed(wall: Node3D)

const ShieldWallScript = preload("res://src/roles/breaker/shield_wall.gd")

var is_bashing: bool = false
var bash_time_remaining: float = 0.0
var cooldown_q: float = 0.0
var cooldown_f: float = 0.0

var _bash_dir: Vector3 = Vector3.FORWARD
var _bash_speed: float = 16.0
var _bash_duration: float = 0.22
var _bash_damage: float = 40.0
var _bash_stun: float = 2.0
var _hit_objects: Array[Node3D] = []


func _process(delta: float) -> void:
	if cooldown_q > 0.0:
		cooldown_q = maxf(cooldown_q - delta, 0.0)
	if cooldown_f > 0.0:
		cooldown_f = maxf(cooldown_f - delta, 0.0)

	if is_bashing:
		bash_time_remaining -= delta
		if bash_time_remaining <= 0.0:
			end_bash()


## Execute Q: Omuz Darbesi (Shoulder Bash).
func try_shoulder_bash(player: CharacterBody3D) -> bool:
	if cooldown_q > 0.0 or is_bashing or not is_instance_valid(player):
		return false

	is_bashing = true
	bash_time_remaining = _bash_duration
	_bash_dir = -player.global_basis.z.normalized()
	_hit_objects.clear()
	cooldown_q = 5.0
	bash_started.emit()
	return true


## Step physical bash charge forward and detect collisions.
func step_bash(player: CharacterBody3D, delta: float) -> void:
	if not is_bashing or not is_instance_valid(player):
		return

	player.velocity.x = _bash_dir.x * _bash_speed
	player.velocity.z = _bash_dir.z * _bash_speed

	# Detect objects along charge path
	var space := player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3.UP * 0.5,
		player.global_position + Vector3.UP * 0.5 + _bash_dir * 1.2
	)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = space.intersect_ray(query)

	if not hit.is_empty():
		var collider: Object = hit.collider
		if collider is Node3D and not _hit_objects.has(collider):
			_hit_objects.append(collider)
			if collider.has_method(&"receive_hit"):
				collider.receive_hit(_bash_damage, 0, _bash_stun)
				bash_hit_target.emit(collider)


func end_bash() -> void:
	is_bashing = false
	bash_time_remaining = 0.0
	_hit_objects.clear()
	bash_ended.emit()


## Execute F: Kalkan Duvarı (Deploy Shield Wall).
func try_deploy_shield(player: CharacterBody3D, parent_node: Node) -> Node3D:
	if cooldown_f > 0.0 or not is_instance_valid(player) or not is_instance_valid(parent_node):
		return null

	var wall: Node3D = ShieldWallScript.new()
	var spawn_pos: Vector3 = player.global_position + (-player.global_basis.z.normalized() * 1.8)
	spawn_pos.y = player.global_position.y + 0.8
	wall.position = spawn_pos
	wall.rotation = player.rotation
	parent_node.add_child(wall)

	cooldown_f = 12.0
	shield_deployed.emit(wall)
	return wall


func reset_role() -> void:
	end_bash()
	cooldown_q = 0.0
	cooldown_f = 0.0
