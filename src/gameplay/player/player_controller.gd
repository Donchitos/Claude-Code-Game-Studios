class_name ProductionPlayerController
extends Node2D

var max_hp: float
var hp: float
var move_speed: float
var radius: float
var pickup_radius: float
var contact_cooldown: float
var attack_interval: float
var minimum_attack_interval: float
var sword_count: int
var sword_damage: int
var invulnerability_left: float = 0.0


## Configures player gameplay values from production_defaults.json.
## Example: `player.configure(config["player"])`.
func configure(player_config: Dictionary) -> void:
	max_hp = float(player_config["max_hp"])
	move_speed = float(player_config["speed"])
	radius = float(player_config["radius"])
	pickup_radius = float(player_config["pickup_radius"])
	contact_cooldown = float(player_config["contact_cooldown"])
	attack_interval = float(player_config["attack_interval"])
	minimum_attack_interval = float(player_config["minimum_attack_interval"])
	sword_count = int(player_config["sword_count"])
	sword_damage = int(player_config["sword_damage"])
	reset_run()

## Restores the player-owned run state. Example: `player.reset_run()`.
func reset_run() -> void:
	position = Vector2.ZERO
	hp = max_hp
	invulnerability_left = 0.0
	queue_redraw()

## Applies one movement phase. Called only by GameRoot through BattleScope.
## Example: `player.run_phase(&"PLAYER_MOVE", direction, delta)`.
func run_phase(phase: StringName, direction: Vector2, delta: float) -> bool:
	if phase != &"PLAYER_MOVE" or not direction.is_finite() or delta < 0.0:
		return false
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	position += direction.limit_length(1.0) * move_speed * delta
	return true

## Applies contact damage if the cooldown is clear. Example: `player.apply_contact_damage(12.0)`.
func apply_contact_damage(amount: float) -> bool:
	if amount <= 0.0 or invulnerability_left > 0.0 or hp <= 0.0:
		return false
	hp = maxf(0.0, hp - amount)
	invulnerability_left = contact_cooldown
	queue_redraw()
	return true

## Applies a deterministic level-up choice. Example: `player.apply_upgrade(0, upgrades)`.
func apply_upgrade(choice: int, upgrades: Dictionary) -> bool:
	match choice:
		0:
			sword_count += 1
		1:
			attack_interval = maxf(minimum_attack_interval, attack_interval * float(upgrades["attack_interval_multiplier"]))
		2:
			move_speed *= float(upgrades["movement_speed_multiplier"])
			pickup_radius *= float(upgrades["pickup_radius_multiplier"])
		_:
			return false
	return true

## Reports whether the player is alive. Example: `if player.is_alive(): ...`.
func is_alive() -> bool:
	return hp > 0.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, pickup_radius, Color(0.32, 0.75, 0.53, 0.055))
	draw_circle(Vector2.ZERO, radius + 5.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_circle(Vector2.ZERO, radius, Color("76d6a5"))
	draw_circle(Vector2(-7.0, -4.0), 3.0, Color("102c2d"))
	draw_circle(Vector2(7.0, -4.0), 3.0, Color("102c2d"))
	draw_line(Vector2(-8.0, 8.0), Vector2(8.0, 8.0), Color("102c2d"), 3.0)

