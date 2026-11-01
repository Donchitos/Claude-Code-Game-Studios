extends Node3D
## Procedural pistol: no assets required; recoil and flash follow accepted shots only.

const CombatScript = preload("res://src/combat/player_combat.gd")

var tuning: CombatScript
## Desired vertical pitch angle toward the 3D mouse cursor target (in radians).
var aim_pitch: float = 0.0
## True while reloading; applies procedural reload stance.
var is_reloading: bool = false

var _slide: Node3D
var _flash: MeshInstance3D
var _light: OmniLight3D
var _impact_remaining := 0.0
var _age := -1.0
var _paused := false


func _ready() -> void:
	_box(self, "Grip", Vector3(0.13, 0.24, 0.14), Vector3(0.0, -0.10, 0.06), Color("343e4b"))
	_slide = Node3D.new()
	_slide.name = "Slide"
	add_child(_slide)
	_box(_slide, "Barrel", Vector3(0.16, 0.13, 0.48), Vector3(0.0, 0.04, -0.14), Color("a4b1be"))
	_box(_slide, "Muzzle", Vector3(0.12, 0.09, 0.015), Vector3(0.0, 0.04, -0.385), Color("111318"))
	_box(_slide, "Sight", Vector3(0.035, 0.035, 0.04), Vector3(0.0, 0.12, -0.27), Color("ffae73"))
	_flash = _box(self, "MuzzleFlash", Vector3(0.10, 0.10, 0.22), Vector3(0.0, 0.04, -0.49), Color("ffdc90"))
	var material: StandardMaterial3D = _flash.material_override
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.visible = false
	_light = OmniLight3D.new()
	_light.name = "MuzzleLight"
	_light.position = Vector3(0, 0.1, -0.6)
	_light.light_color = Color("ffd28b")
	_light.light_energy = 2.0
	_light.omni_range = 4.0
	_light.visible = false
	add_child(_light)


func _process(delta: float) -> void:
	if _paused or tuning == null:
		return
	# Visual vertical pitch toward 3D cursor position
	rotation.x = lerp_angle(rotation.x, aim_pitch, 1.0 - exp(-24.0 * delta))
	# Procedural reload pose
	if is_reloading:
		_slide.rotation.z = lerp_angle(_slide.rotation.z, deg_to_rad(-18.0), 1.0 - exp(-12.0 * delta))
		_slide.position.y = lerpf(_slide.position.y, -0.06, 1.0 - exp(-12.0 * delta))
	else:
		_slide.rotation.z = lerp_angle(_slide.rotation.z, 0.0, 1.0 - exp(-16.0 * delta))
		_slide.position.y = lerpf(_slide.position.y, 0.0, 1.0 - exp(-16.0 * delta))

	if _age < 0.0:
		return
	if _impact_remaining > 0.0:
		_impact_remaining = maxf(_impact_remaining - delta, 0.0)
		return
	_age += maxf(delta, 0.0)
	var duration: float = maxf(tuning.recoil_duration, 0.001)
	var progress: float = clampf(_age / duration, 0.0, 1.0)
	var kick: float = sin(progress * PI) * (0.2 if get_meta(&"reduced", false) else 1.0)
	_slide.position.z = kick * maxf(tuning.recoil_distance, 0.0)
	_slide.rotation.x = kick * deg_to_rad(tuning.recoil_angle)
	_flash.visible = _age < tuning.flash_duration and not get_meta(&"reduced", false)
	_light.visible = _flash.visible
	if progress >= 1.0 and not _flash.visible:
		reset_visual()


## Animate an accepted shot; callers must not invoke this for an empty magazine.
func play_shot() -> void:
	_age = 0.0
	_impact_remaining = 0.0
	_flash.visible = tuning != null and tuning.flash_duration > 0.0 and not get_meta(&"reduced", false)
	_light.visible = _flash.visible


## Restore idle pose immediately when resetting the laboratory.
func reset_visual() -> void:
	_age = -1.0
	_impact_remaining = 0.0
	aim_pitch = 0.0
	is_reloading = false
	rotation.x = 0.0
	_light.visible = false
	_slide.position = Vector3.ZERO
	_slide.rotation = Vector3.ZERO
	_flash.visible = false


## Freeze recoil and muzzle flash with the rest of the lab.
func set_paused(value: bool) -> void:
	_paused = value


func _box(parent: Node3D, node_name: String, size: Vector3, point: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = point
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	visual.material_override = material
	parent.add_child(visual)
	return visual


## Distinct prototype silhouettes reuse the same recoil rig without changing aim.
func show_profile(profile: Resource) -> void:
	var barrel: MeshInstance3D = _slide.get_node("Barrel")
	var muzzle: MeshInstance3D = _slide.get_node("Muzzle")
	var box: BoxMesh = barrel.mesh
	var length := 0.48
	var width := 0.16
	var color := Color("a4b1be")
	if profile.pellets > 1:
		length = 0.82
		width = 0.23
		color = Color("ad8463")
	elif profile.stun_duration > 0.0:
		width = 0.24
		color = Color("66e0c2")
	elif profile.distance > 30.0:
		length = 1.0
		color = Color("596b7c")
	box.size = Vector3(width, 0.13, length)
	barrel.position.z = -length * 0.5 + 0.1
	muzzle.position.z = -length + 0.1
	_flash.position.z = muzzle.position.z - 0.1
	_light.position.z = _flash.position.z
	barrel.material_override.albedo_color = color


## Local hit-stop freezes only the weapon pose, never movement, input or world time.
func confirm_hit(duration: float) -> void:
	if not get_meta(&"reduced", false):
		_impact_remaining = maxf(duration, 0.0)
