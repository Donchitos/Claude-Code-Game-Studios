extends StaticBody3D
## Resettable target/cover with team filtering and a visible damage/stun response.

signal hit_received(damage: float)

@export var max_health: float = 100.0
@export var team: int = 1
@export var breakable: bool = false
@export var dimensions := Vector3(1.1, 1.5, 0.3)
@export var tint := Color("d58363")
@export var pushable: bool = false
@export var display_name: String = "HEDEF"

var health: float
var stun_remaining := 0.0
var _visual: MeshInstance3D
var _label: Label3D
var _collision: CollisionShape3D
var _flash := 0.0
var _spawn_position: Vector3

func _ready() -> void:
	_spawn_position = position
	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	_collision.shape = shape
	add_child(_collision)
	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	_visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	_visual.material_override = material
	add_child(_visual)
	_label = Label3D.new()
	_label.position.y = dimensions.y * 0.5 + 0.3
	_label.font_size = 32
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	reset_target()

func _process(delta: float) -> void:
	stun_remaining = maxf(stun_remaining - delta, 0.0)
	_flash = maxf(_flash - delta, 0.0)
	_visual.material_override.albedo_color = Color.WHITE if _flash > 0.0 else tint
	_label.text = tr(display_name) + " %d" % int(health)
	if stun_remaining > 0.0:
		_label.text += " • " + tr("SERSEM")

## Friendly shots and invalid damage cannot affect health or stun.
func receive_hit(amount: float, source_team: int, stun: float = 0.0) -> bool:
	if source_team == team or health <= 0.0 or not is_finite(amount) or amount <= 0.0:
		return false
	health = maxf(health - amount, 0.0)
	if is_finite(stun):
		stun_remaining = maxf(stun_remaining, stun)
	_flash = 0.08
	hit_received.emit(amount)
	if breakable and health <= 0.0:
		visible = false
		_collision.set_deferred(&"disabled", true)
	return true

## Kırıcı breaks fragile cover or stuns/pushes a surviving target without clipping walls.
func receive_strike(amount: float, direction: Vector3, distance: float, stun: float) -> bool:
	if not receive_hit(amount, 0, stun):
		return false
	if pushable and health > 0.0 and distance > 0.0:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = _collision.shape
		query.transform = _collision.global_transform
		query.motion = direction.normalized() * distance
		query.exclude = [get_rid()]
		var fractions: PackedFloat32Array = get_world_3d().direct_space_state.cast_motion(query)
		if not fractions.is_empty():
			global_position += query.motion * maxf(fractions[0] - 0.01, 0.0)
	return true


## Role effects can stun a hostile target without manufacturing damage.
func apply_stun(duration: float) -> void:
	if team != 0 and health > 0.0 and is_finite(duration):
		stun_remaining = maxf(stun_remaining, maxf(duration, 0.0))


## Restore collision, health and effects without recreating the world node.
func reset_target() -> void:
	position = _spawn_position
	health = maxf(max_health, 0.0)
	stun_remaining = 0.0
	_flash = 0.0
	visible = true
	if is_instance_valid(_collision):
		_collision.set_deferred(&"disabled", false)
