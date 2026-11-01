class_name RoleBase
extends Resource
## Base data resource and contract for character roles in Sector 9.

@export var role_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

@export_group("Ability Q")
@export var ability_q_name: String = ""
@export var ability_q_cooldown: float = 6.0
@export var ability_q_icon: String = "Q"

@export_group("Ability F")
@export var ability_f_name: String = ""
@export var ability_f_cooldown: float = 12.0
@export var ability_f_icon: String = "F"

@export_group("Passives")
@export var bonus_shield: float = 0.0
@export var bonus_speed_multiplier: float = 1.0
@export var noise_multiplier: float = 1.0
