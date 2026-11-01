extends StaticBody3D
## Timed Kırıcı cover: blocks hostile shots, lets allied weapon rays pass through.

var remaining: float = 8.0
var health: float = 200.0
var _expired := false
var _visual: MeshInstance3D
var _collision: CollisionShape3D
var _label: Label3D

func _ready() -> void:
	# A separate layer keeps the shield from becoming an invisible walking obstacle.
	collision_layer = 2
	collision_mask = 0
	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.6, 2.0, 0.18)
	_collision.shape = shape
	add_child(_collision)
	_visual = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	_visual.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.75, 0.9, 0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_visual.material_override = material
	add_child(_visual)
	_label = Label3D.new()
	_label.position.y = 1.3
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	_label.pixel_size = 0.012
	add_child(_label)

## The lab advances lifetime only during active gameplay, never while paused.
func advance(delta: float) -> void:
	if _expired or not is_finite(delta) or delta <= 0.0:
		return
	remaining = maxf(remaining - delta, 0.0)
	_label.text = tr("KALKAN") + " %.1f s" % remaining
	if remaining <= 0.0:
		expire()

## Allied rays ignore this collider; enemy rays terminate here and damage the wall.
func blocks_shot(source_team: int) -> bool:
	return not _expired and source_team != 0

func receive_hit(amount: float, source_team: int, _stun: float = 0.0) -> bool:
	if not blocks_shot(source_team) or not is_finite(amount) or amount <= 0.0:
		return false
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		expire()
	return true

## Immediately deactivate before deferred deletion, including reset and role switch.
func expire() -> void:
	if _expired:
		return
	_expired = true
	collision_layer = 0
	visible = false
	queue_free()
