class_name LootCrate
extends StaticBody3D
## Interactive loot crate supporting multiple types (Small, Locked, Heavy, Trapped, Airdrop)
## and access adapters (Direct, Hack, Breaker Bash, Key). Idempotent single-reward guarantee.

signal opened(loot_item: Resource, count: int)
signal trap_triggered(damage: float)

enum CrateType {
	SMALL,      # Instant open
	LOCKED,     # Requires key or hack
	HEAVY,      # Requires Breaker bash or high force
	TRAPPED,    # Explodes on open if not disarmed
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY,
}

@export var crate_type: CrateType = CrateType.SMALL
@export var rarity: Rarity = Rarity.COMMON
@export var is_opened: bool = false
@export var stored_item: Resource
@export var stored_count: int = 1

var _visual: MeshInstance3D
var _collision: CollisionShape3D
var _label: Label3D


func _ready() -> void:
	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.9, 1.0)
	_collision.shape = shape
	add_child(_collision)

	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, 0.9, 1.0)
	_visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_rarity_color()
	mat.roughness = 0.5
	_visual.material_override = mat
	add_child(_visual)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 0.75, 0.0)
	_label.font_size = 28
	_label.pixel_size = 0.012
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

	_update_presentation()


func _get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color("5c6b73")
		Rarity.UNCOMMON: return Color("2a9d8f")
		Rarity.RARE: return Color("3a86ff")
		Rarity.LEGENDARY: return Color("ffb703")
	return Color.WHITE


func _update_presentation() -> void:
	if is_opened:
		_label.text = tr("[AÇILDI]")
		_label.modulate = Color("777777")
		if is_instance_valid(_visual):
			_visual.material_override.albedo_color = Color("333333")
	else:
		_label.text = tr("KASA: %s") % _get_type_name()
		_label.modulate = _get_rarity_color()


func _get_type_name() -> String:
	match crate_type:
		CrateType.SMALL: return tr("Küçük Kasa")
		CrateType.LOCKED: return tr("Kilitli Kasa")
		CrateType.HEAVY: return tr("Ağır Kasa")
		CrateType.TRAPPED: return tr("Tuzaklı Kasa")
	return tr("Kasa")


## Attempt to open crate; returns true on successful single reward payout.
func try_open(has_key: bool = false, is_bash: bool = false) -> bool:
	if is_opened:
		return false # Single reward guarantee

	match crate_type:
		CrateType.LOCKED:
			if not has_key:
				return false
		CrateType.HEAVY:
			if not is_bash:
				return false
		CrateType.TRAPPED:
			trap_triggered.emit(35.0)

	is_opened = true
	_update_presentation()
	opened.emit(stored_item, stored_count)
	return true


func reset_crate() -> void:
	is_opened = false
	if is_instance_valid(_visual):
		_visual.material_override.albedo_color = _get_rarity_color()
	_update_presentation()
