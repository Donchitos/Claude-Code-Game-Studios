extends Resource
## Data for a playable lab role. Abilities remain in the injected role controller.

@export var role_id: StringName = &"operator"
@export var display_name: String = "Operatör"
@export var hack_duration: float = 3.0
@export var hack_reach: float = 5.0
@export var hack_cooldown: float = 4.0
@export var fuse_reach: float = 6.0
@export var fuse_angle_degrees: float = 70.0
@export var fuse_duration: float = 6.0
@export var fuse_cooldown: float = 12.0
@export var cable_sight_reach: float = 8.0
@export var equipped_weapon: int = -1
@export var max_health: float = 100.0
@export var slow_walk_factor: float = -1.0
@export var break_reach: float = 2.5
@export var break_damage: float = 100.0
@export var break_stun: float = 1.5
@export var break_push: float = 0.8
@export var break_cooldown: float = 4.0
@export var shield_duration: float = 8.0
@export var shield_health: float = 200.0
@export var shield_cooldown: float = 12.0
@export var ability_noise_radius: float = 22.0
@export var footstep_noise_radius: float = 8.0
@export var shot_noise_multiplier: float = 1.0
@export var cargo_capacity: int = 4
@export var pickup_reach: float = 2.5
@export var throw_reach: float = 10.0
@export var throw_flight_time: float = 0.8
@export var throw_cooldown: float = 0.6
@export var core_speed_multiplier: float = 0.75
@export var utility_reach: float = 7.0
@export var utility_duration: float = 6.0
@export var utility_cooldown: float = 8.0
@export var smoke_radius: float = 2.0
@export var bait_noise_radius: float = 15.0
