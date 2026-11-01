class_name HazardObstacle
extends Area3D
## Environmental hazard and dynamic obstacle system for Sector 9:
## Laser Grid, Slippery Floor, Electric Water, Collapsing Shelf, and Gas Chamber.

signal hazard_triggered(body: Node3D, damage: float, stun: float)
signal obstacle_cleared()

enum HazardType {
	LASER_GRID,      # Laser beam: damage on cross, disarmable via terminal or crawl under
	SLIPPERY_FLOOR,  # Low friction zone: player slides
	ELECTRIC_WATER,  # Electrified puddle: periodic shock damage + stun
	COLLAPSING_SHELF,# Destructible shelf: collapses on impact, blocking pursuers
	GAS_CHAMBER,     # Poisonous air: damage over time
}

@export var hazard_type: HazardType = HazardType.LASER_GRID
@export var damage_rate: float = 20.0
@export var stun_duration: float = 0.5
@export var is_active: bool = true
@export var can_be_bridged: bool = true

var _tick_timer := 0.0
var _visual: MeshInstance3D
var _collision: CollisionShape3D


func _ready() -> void:
	_collision = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.5, 0.4, 2.5)
	_collision.shape = shape
	add_child(_collision)

	_visual = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.5, 0.08, 2.5)
	_visual.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_hazard_color()
	_visual.material_override = mat
	add_child(_visual)

	body_entered.connect(_on_body_entered)


func _get_hazard_color() -> Color:
	match hazard_type:
		HazardType.LASER_GRID: return Color("ff2a2a")
		HazardType.SLIPPERY_FLOOR: return Color("a8dadc")
		HazardType.ELECTRIC_WATER: return Color("e9c46a")
		HazardType.COLLAPSING_SHELF: return Color("6c757d")
		HazardType.GAS_CHAMBER: return Color("55a630")
	return Color.RED


func _physics_process(delta: float) -> void:
	if delta <= 0.0 or not is_active:
		return

	_tick_timer += delta
	if _tick_timer >= 0.5:
		_tick_timer = 0.0
		for body in get_overlapping_bodies():
			_apply_hazard_effect(body)


func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	_apply_hazard_effect(body)


func _apply_hazard_effect(body: Node3D) -> void:
	if not is_active:
		return

	match hazard_type:
		HazardType.LASER_GRID:
			# If player is crawling (slow walk/crouch), laser is passed under safely!
			if body.get("is_slow_walking") == true:
				return
			hazard_triggered.emit(body, damage_rate * 0.5, 0.0)

		HazardType.ELECTRIC_WATER:
			hazard_triggered.emit(body, damage_rate * 0.4, stun_duration)

		HazardType.GAS_CHAMBER:
			hazard_triggered.emit(body, damage_rate * 0.25, 0.0)

		HazardType.COLLAPSING_SHELF:
			# Breaker bash or explosives collapse the shelf
			collapse_shelf()


func collapse_shelf() -> void:
	if hazard_type == HazardType.COLLAPSING_SHELF and is_active:
		is_active = false
		obstacle_cleared.emit()
		if is_instance_valid(_visual):
			_visual.material_override.albedo_color = Color("333333")


## Terminal hack or switch disarms hazard.
func disarm() -> void:
	is_active = false
	obstacle_cleared.emit()
	if is_instance_valid(_visual):
		_visual.material_override.albedo_color = Color("444444")


func reset_hazard() -> void:
	is_active = true
	_tick_timer = 0.0
	if is_instance_valid(_visual):
		_visual.material_override.albedo_color = _get_hazard_color()
