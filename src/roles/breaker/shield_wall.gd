class_name ShieldWall
extends StaticBody3D
## Directional energy shield wall deployed by the Breaker role.
## Absorbs enemy attacks from the front; allows friendly fire from behind.

signal destroyed()

@export var max_health: float = 180.0
@export var lifetime: float = 9.0
@export var team: int = 0 # Friendly to player

var health: float
var remaining_time: float
var _visual: MeshInstance3D
var _collision: CollisionShape3D
var _flash := 0.0

const SHIELD_COLOR := Color("40a0ff88")
const HIT_COLOR := Color("ffffffaa")


func _ready() -> void:
	health = max_health
	remaining_time = lifetime

	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 1.6, 0.25)
	_collision.shape = shape
	add_child(_collision)

	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.4, 1.6, 0.15)
	_visual.mesh = mesh
	var shader = load("res://assets/shaders/shield_energy.gdshader")
	if shader != null:
		var smat := ShaderMaterial.new()
		smat.shader = shader
		smat.set_shader_parameter("shield_color", Color(0.2, 0.65, 1.0, 0.75))
		smat.set_shader_parameter("rim_color", Color(0.5, 0.85, 1.0, 1.0))
		_visual.material_override = smat
	else:
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = SHIELD_COLOR
		mat.emission_enabled = true
		mat.emission = Color("2080ff")
		mat.emission_energy_multiplier = 1.2
		_visual.material_override = mat
	add_child(_visual)


func _process(delta: float) -> void:
	remaining_time -= delta
	_flash = maxf(_flash - delta, 0.0)

	if is_instance_valid(_visual):
		if _visual.material_override is ShaderMaterial:
			_visual.material_override.set_shader_parameter("hit_flash", clampf(_flash / 0.08, 0.0, 1.0))
		elif _visual.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = _visual.material_override
			mat.albedo_color = HIT_COLOR if _flash > 0.0 else SHIELD_COLOR

	if remaining_time <= 0.0 or health <= 0.0:
		destroyed.emit()
		queue_free()


## Receive incoming hit. Frontal hits absorb damage.
func receive_hit(amount: float, source_team: int, _stun: float = 0.0) -> bool:
	if source_team == team or health <= 0.0:
		return false # Friendly shots pass through or wall already down
	health = maxf(health - amount, 0.0)
	_flash = 0.08
	if health <= 0.0:
		destroyed.emit()
		queue_free()
	return true
