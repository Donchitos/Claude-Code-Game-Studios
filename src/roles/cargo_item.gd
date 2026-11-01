extends RigidBody3D
## A reusable lab parcel/core. Physics stays active only while the item is in the world.

@export var is_core := false
var carried := false
var _spawn := Transform3D.IDENTITY

func _ready() -> void:
	_spawn = transform
	mass = 2.0 if is_core else 1.0
	continuous_cd = true
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.42, 0.42, 0.42)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("75d9e6") if is_core else Color("bb976c")
	visual.material_override = material
	add_child(visual)
	var label := Label3D.new()
	label.text = tr("ÇEKİRDEK") if is_core else tr("ÇANTA")
	label.position.y = 0.5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.pixel_size = 0.012
	add_child(label)

## Carried items cannot collide or independently simulate; their owner supplies the pose.
func set_carried(value: bool) -> void:
	carried = value
	freeze = value
	collision_layer = 0 if value else 1
	collision_mask = 0 if value else 1
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	visible = not value

## Release a physical item with an externally calculated launch velocity.
func launch(point: Vector3, speed: Vector3) -> void:
	set_carried(false)
	global_position = point
	linear_velocity = speed
	sleeping = false

## Restore the original world item without creating additional copies.
func reset_item() -> void:
	set_carried(false)
	transform = _spawn
	sleeping = false
