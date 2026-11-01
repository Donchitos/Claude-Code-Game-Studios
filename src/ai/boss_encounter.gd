class_name BossEncounter
extends CharacterBody3D
## Phased Chief encounter: 2-phase boss with frontal armor, rear weak-point, and Phase 2 Berserk overdrive.

signal phase_changed(new_phase: int)
signal defeated()

@export var max_health: float = 300.0
@export var team: int = 1

var health: float
var current_phase: int = 1
var is_berserk: bool = false
var stun_remaining: float = 0.0

var _collision: CollisionShape3D
var _visual: MeshInstance3D
var _spawn_pos := Vector3.ZERO


func _ready() -> void:
	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 2.2, 1.4)
	_collision.shape = shape
	add_child(_collision)

	_visual = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 2.2, 1.4)
	_visual.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("8b0000") # Dark boss red
	_visual.material_override = mat
	add_child(_visual)

	if _spawn_pos.is_zero_approx():
		_spawn_pos = global_position
	reset_boss()


## Hit reception with directional weak-point calculation.
## Rear hits (behind boss) hit the power cell for 2.5x critical damage.
## Frontal hits in Phase 1 are absorbed by 80%.
func receive_hit_directional(amount: float, hit_position: Vector3, source_team: int, stun: float = 0.0) -> bool:
	if source_team == team or health <= 0.0 or not is_finite(amount) or amount <= 0.0:
		return false

	var to_hit: Vector3 = (hit_position - global_position).normalized()
	var forward: Vector3 = -global_basis.z.normalized()
	var dot_front: float = forward.dot(to_hit)

	var effective_damage: float = amount
	if current_phase == 1:
		if dot_front < -0.3:
			# Rear hit on power cell: Critical!
			effective_damage = amount * 2.5
		else:
			# Frontal armor absorption
			effective_damage = amount * 0.20
	else:
		# Phase 2: Armor broken, full damage
		effective_damage = amount

	health = maxf(health - effective_damage, 0.0)

	# Phase transition check at 50% health
	if current_phase == 1 and health <= max_health * 0.5:
		current_phase = 2
		is_berserk = true
		if is_instance_valid(_visual):
			_visual.material_override.albedo_color = Color("ff2200") # Berserk fiery red
		phase_changed.emit(2)

	if is_finite(stun) and stun > 0.0:
		# Boss has 60% stun resistance
		stun_remaining = maxf(stun_remaining, stun * 0.4)

	if health <= 0.0:
		defeated.emit()
		if is_instance_valid(_collision):
			_collision.set_deferred(&"disabled", true)
			_collision.disabled = true

	return true


## Standard receive_hit interface for universal weapon compatibility.
func receive_hit(amount: float, source_team: int, stun: float = 0.0) -> bool:
	return receive_hit_directional(amount, global_position + (-global_basis.z), source_team, stun)


func reset_boss() -> void:
	global_position = _spawn_pos
	health = max_health
	current_phase = 1
	is_berserk = false
	stun_remaining = 0.0
	if is_instance_valid(_collision):
		_collision.set_deferred(&"disabled", false)
		_collision.disabled = false
	if is_instance_valid(_visual):
		_visual.material_override.albedo_color = Color("8b0000")
