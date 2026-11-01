extends StaticBody3D
## Resettable hack/fuse sample. The camera is a lab system, not enemy AI.

@export var display_name: String = "Elektrik paneli"
@export var kind: String = "panel"
var completed := false
var redirected_remaining := 0.0
var _mesh: MeshInstance3D
var _label: Label3D
var _reveal: Label3D

func _ready() -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 1.0, 0.5)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	_mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("cc715b")
	_mesh.material_override = material
	add_child(_mesh)
	_label = Label3D.new()
	_label.position.y = 0.9
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 28
	_label.pixel_size = 0.012
	add_child(_label)
	_reveal = Label3D.new()
	_reveal.text = tr("◇ TESİSAT")
	_reveal.position.y = 1.25
	_reveal.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_reveal.no_depth_test = true
	_reveal.modulate = Color("66e0c2")
	_reveal.font_size = 36
	_reveal.pixel_size = 0.012
	_reveal.visible = false
	add_child(_reveal)
	_refresh()

## Called by the lab so electrical timers respect pause.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	redirected_remaining = maxf(redirected_remaining - delta, 0.0)
	_refresh()

## Cameras can be hacked; electrical panels/lazers use Sigorta Ağı instead.
func can_hack() -> bool:
	return kind == "camera" and not completed

## Persistently disable a hacked camera until the laboratory resets.
func activate() -> bool:
	if not can_hack():
		return false
	completed = true
	_refresh()
	return true

## Fuse redirection is temporary and never shortens an existing effect.
func redirect_for(duration: float) -> void:
	if is_finite(duration):
		redirected_remaining = maxf(redirected_remaining, maxf(duration, 0.0))
	_refresh()

## Hazards query this rather than maintaining a second copy of device state.
func is_disabled() -> bool:
	return completed or redirected_remaining > 0.0

## Kablo Gözü marks nearby circuitry through geometry for Kilit only.
func set_revealed(value: bool) -> void:
	_reveal.visible = value

func reset_target() -> void:
	completed = false
	redirected_remaining = 0.0
	set_revealed(false)
	_refresh()

func _refresh() -> void:
	_mesh.material_override.albedo_color = Color("66e0c2") if is_disabled() else Color("cc715b")
	_label.text = tr(display_name) + " • " + (tr("DEVRE DIŞI") if is_disabled() else tr("ETKİN"))
