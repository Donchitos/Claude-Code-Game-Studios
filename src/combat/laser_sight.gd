class_name TacticalLaserSight
extends Node3D
## Dynamic tactical laser sight projecting from weapon muzzle to 3D aim target or obstacle.
## Changes beam color based on weapon profile and renders an endpoint contact dot.

@export var max_distance: float = 35.0
@export var beam_thickness: float = 0.015
@export var is_enabled: bool = true

var current_color: Color = Color("ff4444")
var excluded_rids: Array[RID] = []

var _beam_mesh: MeshInstance3D
var _dot_mesh: MeshInstance3D
var _box: BoxMesh
var _mat: StandardMaterial3D
var _dot_mat: StandardMaterial3D


func _ready() -> void:
	_box = BoxMesh.new()
	_box.size = Vector3(beam_thickness, beam_thickness, 1.0)

	_beam_mesh = MeshInstance3D.new()
	_beam_mesh.name = "LaserBeam"
	_beam_mesh.mesh = _box

	var shader = load("res://assets/shaders/laser_beam.gdshader")
	if shader != null:
		var smat := ShaderMaterial.new()
		smat.shader = shader
		smat.set_shader_parameter("beam_color", current_color)
		_beam_mesh.material_override = smat
	else:
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = current_color
		_beam_mesh.material_override = _mat
	add_child(_beam_mesh)

	# Endpoint contact dot
	_dot_mesh = MeshInstance3D.new()
	_dot_mesh.name = "LaserDot"
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	_dot_mesh.mesh = sphere

	_dot_mat = StandardMaterial3D.new()
	_dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dot_mat.albedo_color = current_color
	_dot_mesh.material_override = _dot_mat
	add_child(_dot_mesh)

	set_weapon_theme(0)


## Update weapon color theme.
func set_weapon_theme(weapon_index: int) -> void:
	match weapon_index:
		0: current_color = Color(1.0, 0.25, 0.25, 0.65) # Red Pistol
		1: current_color = Color(0.25, 0.85, 1.0, 0.75) # Cyan Shock
		2: current_color = Color(1.0, 0.65, 0.20, 0.60) # Amber Shotgun
		3: current_color = Color(0.25, 1.0, 0.45, 0.75) # Emerald Carbine
		_: current_color = Color(1.0, 0.25, 0.25, 0.65)

	if is_instance_valid(_beam_mesh):
		if _beam_mesh.material_override is ShaderMaterial:
			_beam_mesh.material_override.set_shader_parameter("beam_color", current_color)
		elif _beam_mesh.material_override is StandardMaterial3D:
			_beam_mesh.material_override.albedo_color = current_color
	if is_instance_valid(_dot_mat):
		_dot_mat.albedo_color = current_color


## Update laser beam 3D raycast and alignment.
func update_laser(muzzle_pos: Vector3, aim_direction: Vector3, space: PhysicsDirectSpaceState3D) -> Vector3:
	if not is_enabled or not aim_direction.is_finite() or aim_direction.is_zero_approx():
		visible = false
		return muzzle_pos

	visible = true
	var dir := aim_direction.normalized()
	var finish_pos: Vector3 = muzzle_pos + dir * max_distance

	if space != null:
		var query := PhysicsRayQueryParameters3D.create(muzzle_pos, finish_pos)
		query.exclude = excluded_rids
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			finish_pos = hit.position

	var length: float = muzzle_pos.distance_to(finish_pos)
	if is_instance_valid(_box):
		_box.size.z = length

	if is_instance_valid(_beam_mesh):
		_beam_mesh.global_position = (muzzle_pos + finish_pos) * 0.5
		if length > 0.05:
			_beam_mesh.look_at(finish_pos)

	if is_instance_valid(_dot_mesh):
		_dot_mesh.global_position = finish_pos

	return finish_pos
