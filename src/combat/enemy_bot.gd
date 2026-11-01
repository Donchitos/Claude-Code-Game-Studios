class_name EnemyBot
extends CharacterBody3D
## Pursuing enemy bot: chases the player, attacks on contact, takes damage, stuns, and respects physics.

signal hit_received(damage: float)
signal attack_dealt(amount: float)
signal defeated()
signal flinched()
signal suppressed()

@export var max_health: float = 60.0
@export var move_speed: float = 3.6
@export var attack_range: float = 1.3
@export var attack_damage: float = 12.0
@export var attack_cooldown: float = 1.2
@export var team: int = 1
@export var spawn_position := Vector3.ZERO

var health: float
var stun_remaining := 0.0
var target: Node3D
var active := true
var flinch_timer: float = 0.0
var suppression: float = 0.0
var is_suppressed: bool = false

var _attack_timer := 0.0
var _visual_root: Node3D
var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _eye_mesh: MeshInstance3D
var _label: Label3D
var _collision: CollisionShape3D
var _flash := 0.0
var _knockback := Vector3.ZERO
var _lunge := 0.0

const GRAVITY: float = 24.0
const ENEMY_COLOR := Color("b83c40")
const ENEMY_EYE_COLOR := Color("ffaa33")
const ENEMY_ARMOR_COLOR := Color("2a3240")


func _ready() -> void:
	_collision = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.4
	_collision.shape = shape
	add_child(_collision)

	_visual_root = Node3D.new()
	_visual_root.name = "VisualRoot"
	add_child(_visual_root)

	# Body Capsule
	_body_mesh = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.4
	_body_mesh.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ENEMY_COLOR
	mat.roughness = 0.5
	_body_mesh.material_override = mat
	_visual_root.add_child(_body_mesh)

	# Head armor
	_head_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.42, 0.35, 0.45)
	_head_mesh.mesh = box
	var armor_mat := StandardMaterial3D.new()
	armor_mat.albedo_color = ENEMY_ARMOR_COLOR
	armor_mat.roughness = 0.4
	_head_mesh.material_override = armor_mat
	_head_mesh.position = Vector3(0.0, 0.52, -0.05)
	_visual_root.add_child(_head_mesh)

	# Glowing eye visor
	_eye_mesh = MeshInstance3D.new()
	var eye_box := BoxMesh.new()
	eye_box.size = Vector3(0.28, 0.08, 0.06)
	_eye_mesh.mesh = eye_box
	var eye_mat := StandardMaterial3D.new()
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye_mat.albedo_color = ENEMY_EYE_COLOR
	_eye_mesh.material_override = eye_mat
	_eye_mesh.position = Vector3(0.0, 0.54, -0.28)
	_visual_root.add_child(_eye_mesh)

	# 3D Overhead Status Label
	_label = Label3D.new()
	_label.position = Vector3(0.0, 1.15, 0.0)
	_label.font_size = 32
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color("ffdd88")
	add_child(_label)

	if spawn_position.is_zero_approx():
		spawn_position = global_position
	reset_bot()


func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return

	_flash = maxf(_flash - delta, 0.0)
	if is_instance_valid(_body_mesh):
		var target_color: Color = Color.WHITE if _flash > 0.0 else ENEMY_COLOR
		if stun_remaining > 0.0 and int(Time.get_ticks_msec() / 100) % 2 == 0:
			target_color = Color("66e0c2") # Stunned electric cyan flash
		_body_mesh.material_override.albedo_color = target_color

	if health <= 0.0:
		_label.text = tr("[YIKILDI]")
		_label.modulate = Color("888888")
		velocity = velocity.move_toward(Vector3.ZERO, 15.0 * delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	stun_remaining = maxf(stun_remaining - delta, 0.0)
	flinch_timer = maxf(flinch_timer - delta, 0.0)
	suppression = maxf(suppression - delta * 22.0, 0.0)
	is_suppressed = suppression > 15.0
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_lunge = maxf(_lunge - delta * 4.0, 0.0)

	# Update status label
	if stun_remaining > 0.0:
		_label.text = tr("[DÜŞMAN] SERSEM (%.1fs)") % stun_remaining
		_label.modulate = Color("66e0c2")
	elif flinch_timer > 0.0:
		_label.text = tr("[DÜŞMAN] SENDELEDİ!")
		_label.modulate = Color("ffaa44")
	elif is_suppressed:
		_label.text = tr("[DÜŞMAN] BASKI ALTINDA (%d)") % int(health)
		_label.modulate = Color("e0a96d")
	elif _attack_timer > attack_cooldown * 0.7:
		_label.text = tr("[DÜŞMAN] ! SALDIRI !")
		_label.modulate = Color("ff4444")
	else:
		_label.text = tr("[DÜŞMAN] %d / %d") % [int(health), int(max_health)]
		_label.modulate = Color("ffdd88")

	# If stunned, flinching, or inactive, cannot pursue or attack normally
	if not active or stun_remaining > 0.0 or flinch_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	# Handle chase and attack logic toward target
	if is_instance_valid(target) and target.is_inside_tree():
		var to_target: Vector3 = target.global_position - global_position
		var horizontal_dist: float = Vector2(to_target.x, to_target.z).length()
		var move_dir := Vector3(to_target.x, 0.0, to_target.z).normalized()
		var current_speed: float = move_speed * (0.60 if is_suppressed else 1.0)

		if not move_dir.is_zero_approx():
			var desired_yaw := atan2(-move_dir.x, -move_dir.z)
			rotation.y = lerp_angle(rotation.y, desired_yaw, 1.0 - exp(-12.0 * delta))

		if horizontal_dist > attack_range:
			# Chase player
			velocity.x = move_toward(velocity.x, move_dir.x * current_speed, 20.0 * delta)
			velocity.z = move_toward(velocity.z, move_dir.z * current_speed, 20.0 * delta)
		else:
			# In melee range: strike!
			velocity.x = move_toward(velocity.x, 0.0, 25.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 25.0 * delta)
			if _attack_timer <= 0.0:
				_attack_timer = attack_cooldown
				_lunge = 0.25
				attack_dealt.emit(attack_damage)

	if _lunge > 0.0 and is_instance_valid(_visual_root):
		_visual_root.position.z = -sin(_lunge * PI / 0.25) * 0.22
	elif is_instance_valid(_visual_root):
		_visual_root.position.z = 0.0

	# Apply knockback
	if not _knockback.is_zero_approx():
		velocity += _knockback
		_knockback = _knockback.move_toward(Vector3.ZERO, 35.0 * delta)

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -1.0

	move_and_slide()


## Standard damage interface: weapon controller and damage queries call receive_hit.
func receive_hit(amount: float, source_team: int, stun: float = 0.0) -> bool:
	if source_team == team or health <= 0.0 or not is_finite(amount) or amount <= 0.0:
		return false
	health = maxf(health - amount, 0.0)
	if is_finite(stun) and stun > 0.0:
		stun_remaining = maxf(stun_remaining, stun)
	_flash = 0.08
	# Knockback and Flinch on impactful hits (>=18 damage)
	if amount >= 18.0:
		flinch_timer = 0.28
		_lunge = 0.0
		_attack_timer = maxf(_attack_timer, 0.35)
		flinched.emit()
	suppression = minf(suppression + amount * 1.5, 100.0)
	if suppression >= 45.0 and not is_suppressed:
		is_suppressed = true
		suppressed.emit()
	# Knockback slightly away from incoming hit
	if is_instance_valid(target):
		var push_dir: Vector3 = (global_position - target.global_position).normalized()
		_knockback = Vector3(push_dir.x, 0.2, push_dir.z) * minf(amount * 0.15, 4.0)
	hit_received.emit(amount)
	if health <= 0.0:
		if is_instance_valid(_collision):
			_collision.set_deferred(&"disabled", true)
			_collision.disabled = true
		defeated.emit()
	return true


## Reset position, health, timers, and collision for laboratory resets.
func reset_bot() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	health = maxf(max_health, 0.0)
	stun_remaining = 0.0
	flinch_timer = 0.0
	suppression = 0.0
	is_suppressed = false
	_attack_timer = 0.0
	_flash = 0.0
	_lunge = 0.0
	visible = true
	if is_instance_valid(_collision):
		_collision.set_deferred(&"disabled", false)
		_collision.disabled = false
	if is_instance_valid(_visual_root):
		_visual_root.position = Vector3.ZERO
