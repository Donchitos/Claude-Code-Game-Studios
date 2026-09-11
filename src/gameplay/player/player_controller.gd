class_name ProductionPlayerController
extends Node2D

var max_hp: float
var hp: float
var move_speed: float
var maximum_move_speed: float
var _initial_longchun_charges := 0
var radius: float
var pickup_radius: float
var contact_cooldown: float
var attack_interval: float
var minimum_attack_interval: float
var sword_count: int
var sword_damage: float
var invulnerability_left: float = 0.0
var longchun_charge_count: int = 0
var longchun_threshold_ratio: float = 0.30
var longchun_recovery_ratio: float = 0.10
var longchun_trigger_count: int = 0
const HIT_FLASH_SECONDS := 0.24
const HIT_NOTICE_SECONDS := 1.4
var hit_feedback_left := 0.0
var last_damage_amount := 0.0
var last_damage_sources := ""
var damage_event_count := 0


## Configures base values and consumes the immutable next-run Progression projection.
## Example: `player.configure(config["player"], progression_projection)`.
func configure(player_config: Dictionary, progression_projection: Dictionary = {}) -> void:
	var max_hp_bonus := float(progression_projection.get("max_hp_bonus_ratio", 0.0))
	var attack_bonus := float(progression_projection.get("attack_bonus_ratio", 0.0))
	var pickup_bonus := float(progression_projection.get("pickup_bonus_ratio", 0.0))
	max_hp = float(player_config["max_hp"]) * (1.0 + max_hp_bonus)
	move_speed = float(player_config["speed"])
	maximum_move_speed = float(player_config.get("maximum_speed", 600.0))
	radius = float(player_config["radius"])
	pickup_radius = float(player_config["pickup_radius"]) * (1.0 + pickup_bonus)
	contact_cooldown = float(player_config["contact_cooldown"])
	attack_interval = float(player_config["attack_interval"])
	minimum_attack_interval = float(player_config["minimum_attack_interval"])
	sword_count = int(player_config["sword_count"])
	sword_damage = float(player_config["sword_damage"]) * (1.0 + attack_bonus)
	longchun_charge_count = int(progression_projection.get("longchun_charge_count", 0))
	_initial_longchun_charges = longchun_charge_count
	longchun_threshold_ratio = float(progression_projection.get("longchun_threshold_ratio", 0.30))
	longchun_recovery_ratio = float(progression_projection.get("longchun_recovery_ratio", 0.10))
	reset_run()

## Restores the player-owned run state. Example: `player.reset_run()`.
func reset_run() -> void:
	position = Vector2.ZERO
	hp = max_hp
	invulnerability_left = 0.0
	longchun_trigger_count = 0
	longchun_charge_count = _initial_longchun_charges
	hit_feedback_left = 0.0
	last_damage_amount = 0.0
	last_damage_sources = ""
	damage_event_count = 0
	queue_redraw()

## Applies one movement phase. Called only by GameRoot through BattleScope.
## Example: `player.run_phase(&"PLAYER_MOVE", direction, delta)`.
func run_phase(phase: StringName, direction: Vector2, delta: float) -> bool:
	if phase != &"PLAYER_MOVE" or not direction.is_finite() or delta < 0.0:
		return false
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	if hit_feedback_left > 0.0:
		hit_feedback_left = maxf(0.0, hit_feedback_left - delta)
		queue_redraw()
	position += direction.limit_length(1.0) * move_speed * delta
	return true

## Applies contact damage if the cooldown is clear. Example: `player.apply_contact_damage(12.0)`.
func apply_contact_damage(amount: float) -> bool:
	if invulnerability_left > 0.0:
		return false
	if not apply_resolved_damage(amount):
		return false
	invulnerability_left = contact_cooldown
	return true

func apply_resolved_damage(amount: float, sources: String = "受击") -> bool:
	if not is_finite(amount) or amount <= 0.0 or hp <= 0.0:
		return false
	var hp_before := hp
	hp = maxf(0.0, hp - amount)
	last_damage_amount = hp_before - hp
	last_damage_sources = sources
	hit_feedback_left = HIT_NOTICE_SECONDS
	damage_event_count += 1
	var threshold_hp := max_hp * longchun_threshold_ratio
	if longchun_charge_count > 0 \
			and hp_before >= threshold_hp \
			and hp > 0.0 \
			and hp < threshold_hp:
		hp = minf(max_hp, hp + max_hp * longchun_recovery_ratio)
		longchun_charge_count -= 1
		longchun_trigger_count += 1
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
			move_speed = minf(maximum_move_speed, move_speed * float(upgrades["movement_speed_multiplier"]))
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
	var flash := hit_feedback_left > HIT_NOTICE_SECONDS - HIT_FLASH_SECONDS
	draw_circle(Vector2.ZERO, radius, Color("fff0da") if flash else Color("76d6a5"))
	if hit_feedback_left > 0.0:
		var alpha := minf(1.0, hit_feedback_left / 0.3)
		if flash:
			draw_arc(Vector2.ZERO, radius + 9.0, 0.0, TAU, 48, Color("ff725c"), 4.0, true)
		var text := "-%s" % String.num(last_damage_amount, 1)
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string(font, Vector2(-width * 0.5, -radius - 18.0 - (HIT_NOTICE_SECONDS - hit_feedback_left) * 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.85, 0.65, alpha))
	draw_circle(Vector2(-7.0, -4.0), 3.0, Color("102c2d"))
	draw_circle(Vector2(7.0, -4.0), 3.0, Color("102c2d"))
	draw_line(Vector2(-8.0, 8.0), Vector2(8.0, 8.0), Color("102c2d"), 3.0)
