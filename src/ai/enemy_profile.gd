class_name EnemyProfile
extends Resource
## Data resource configuring enemy combat stats and sensory parameters.

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var max_health: float = 60.0
@export var move_speed: float = 3.6
@export var attack_damage: float = 12.0
@export var attack_range: float = 1.3
@export var attack_cooldown: float = 1.2
@export var vision_range: float = 14.0
@export var vision_fov: float = 110.0
@export var hearing_range: float = 16.0
@export var has_shield: bool = false
@export var shield_health: float = 0.0
