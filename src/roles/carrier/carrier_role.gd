class_name CarrierRole
extends Node
## Carrier (Yük) role controller: Smoke Decoy and Power Throw abilities.

signal decoy_deployed(point: Vector3)
signal power_throw_executed(throwable: Node3D, velocity: Vector3)

var cooldown_q: float = 0.0
var cooldown_f: float = 0.0

const THROW_BOOST_MULTIPLIER: float = 1.55 # 55% farther throw
const DECOY_DURATION: float = 7.0


func _process(delta: float) -> void:
	if cooldown_q > 0.0:
		cooldown_q = maxf(cooldown_q - delta, 0.0)
	if cooldown_f > 0.0:
		cooldown_f = maxf(cooldown_f - delta, 0.0)


## Q: Deploy distraction smoke decoy canister.
func deploy_decoy(player: CharacterBody3D, parent_node: Node) -> Node3D:
	if cooldown_q > 0.0 or not is_instance_valid(player) or not is_instance_valid(parent_node):
		return null

	var decoy := Node3D.new()
	decoy.name = "SmokeDecoy"
	decoy.position = player.global_position + (-player.global_basis.z.normalized() * 2.5)
	parent_node.add_child(decoy)

	cooldown_q = 9.0
	decoy_deployed.emit(decoy.position)
	return decoy


## F: Power throw heavy prop with 55% extra velocity.
func execute_power_throw(throwable: Node3D, base_direction: Vector3, base_speed: float = 12.0) -> bool:
	if cooldown_f > 0.0 or not is_instance_valid(throwable):
		return false

	var boosted_vel: Vector3 = (base_direction + Vector3.UP * 0.35).normalized() * (base_speed * THROW_BOOST_MULTIPLIER)
	if throwable.has_method(&"throw_object"):
		throwable.throw_object(boosted_vel)
		cooldown_f = 4.0
		power_throw_executed.emit(throwable, boosted_vel)
		return true

	return false


func reset_role() -> void:
	cooldown_q = 0.0
	cooldown_f = 0.0
