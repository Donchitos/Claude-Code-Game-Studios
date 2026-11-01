class_name PlayerCombat
extends Resource
## Per-player health and seven-shot magazine; the lab duplicates the tuning asset.

signal health_changed(current: float, maximum: float)
signal ammo_changed(current: int, capacity: int)
signal fired()
signal shield_changed(current: float, maximum: float)
signal damaged(amount: float)
signal reload_changed(remaining: float)
signal active_reload_evaluated(success: bool, bonus_rounds: int)

@export var max_health: float = 100.0
@export var magazine_capacity: int = 7
@export var health_animation_duration: float = 0.25
@export var recoil_duration: float = 0.14
@export var recoil_distance: float = 0.10
@export var recoil_angle: float = 12.0
@export var flash_duration: float = 0.055

@export var reload_duration: float = 2.0
@export var max_shield: float = 40.0
@export var shield_recharge_delay: float = 3.0
@export var shield_recharge_rate: float = 12.0

var health: float = 0.0
var ammo: int = 0
var shield: float = 0.0
var stun_remaining: float = 0.0
## Negative reserve means the default unlimited laboratory supply.
var reserve_ammo: int = -1
var reload_remaining: float = 0.0
var active_reload_bonus_shots: int = 0
var active_reload_window_start: float = 0.45
var active_reload_window_end: float = 0.75
var _recharge_wait: float = 0.0


## Restore initial health and ammunition, notifying any attached presentation.
func reset() -> void:
	health = maxf(max_health, 0.0)
	ammo = maxi(magazine_capacity, 0)
	shield = 0.0
	stun_remaining = 0.0
	active_reload_bonus_shots = 0
	cancel_reload()
	_recharge_wait = maxf(shield_recharge_delay, 0.0)
	shield_changed.emit(shield, max_shield)
	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo, magazine_capacity)


## Consume exactly one round and emit effects only for accepted shots.
func try_fire() -> bool:
	if ammo <= 0 or health <= 0.0 or stun_remaining > 0.0 or reload_remaining > 0.0:
		return false
	ammo -= 1
	ammo_changed.emit(ammo, magazine_capacity)
	fired.emit()
	if ammo == 0:
		reload()
	return true


## Start a timed reload; ammunition is supplied only when the full delay expires.
func reload() -> bool:
	if reload_remaining > 0.0 or ammo >= magazine_capacity or reserve_ammo == 0:
		return false
	if health <= 0.0 or stun_remaining > 0.0:
		return false
	reload_remaining = maxf(reload_duration, 0.001)
	reload_changed.emit(reload_remaining)
	return true


## Cancelling for a weapon switch/reset never creates rounds or consumes reserve.
func cancel_reload() -> void:
	reload_remaining = 0.0
	reload_changed.emit(0.0)


## Evaluate an active reload attempt (Synthetik sweet-spot mechanic).
## Returns true on perfect timing (instant reload + 3 bonus rounds); false on mistimed jam.
func attempt_active_reload() -> bool:
	if reload_remaining <= 0.0 or health <= 0.0 or stun_remaining > 0.0:
		return false
	var progress: float = 1.0 - clampf(reload_remaining / maxf(reload_duration, 0.001), 0.0, 1.0)
	if progress >= active_reload_window_start and progress <= active_reload_window_end:
		# Sweet spot hit! Instant refill + damage boost
		reload_remaining = 0.0
		var supplied: int = maxi(magazine_capacity - ammo, 0)
		if reserve_ammo >= 0:
			supplied = mini(supplied, reserve_ammo)
			reserve_ammo -= supplied
		ammo += supplied
		active_reload_bonus_shots = 3
		ammo_changed.emit(ammo, magazine_capacity)
		reload_changed.emit(0.0)
		active_reload_evaluated.emit(true, active_reload_bonus_shots)
		return true
	else:
		# Jam penalty: adds 0.5s delay
		reload_remaining = minf(reload_remaining + 0.5, reload_duration + 0.5)
		reload_changed.emit(reload_remaining)
		active_reload_evaluated.emit(false, 0)
		return false


## Damage entry point for future gameplay; invalid amounts never heal or poison state.
func apply_damage(amount: float, source_team: int = -1) -> void:
	if not is_finite(amount) or amount <= 0.0 or source_team == 0 or health <= 0.0:
		return
	_recharge_wait = maxf(shield_recharge_delay, 0.0)
	var absorbed: float = minf(shield, amount)
	shield -= absorbed
	if absorbed > 0.0:
		shield_changed.emit(shield, max_shield)
	var next: float = maxf(health - (amount - absorbed), 0.0)
	if not is_equal_approx(next, health):
		health = next
		if health <= 0.0:
			cancel_reload()
		health_changed.emit(health, max_health)
	damaged.emit(amount)


## Advance regeneration and status timers only while the lab is running.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	stun_remaining = maxf(stun_remaining - delta, 0.0)
	if reload_remaining > 0.0:
		reload_remaining = maxf(reload_remaining - delta, 0.0)
		if reload_remaining <= 0.000001:
			reload_remaining = 0.0
			var supplied: int = maxi(magazine_capacity - ammo, 0)
			if reserve_ammo >= 0:
				supplied = mini(supplied, reserve_ammo)
				reserve_ammo -= supplied
			ammo += supplied
			ammo_changed.emit(ammo, magazine_capacity)
		reload_changed.emit(reload_remaining)
	var recharge_step: float = maxf(delta - _recharge_wait, 0.0)
	_recharge_wait = maxf(_recharge_wait - delta, 0.0)
	if recharge_step > 0.0 and health > 0.0 and shield < max_shield:
		shield = minf(shield + maxf(shield_recharge_rate, 0.0) * recharge_step, max_shield)
		shield_changed.emit(shield, max_shield)


## Supply a full shield from an interaction station.
func refill_shield() -> void:
	shield = maxf(max_shield, 0.0)
	shield_changed.emit(shield, max_shield)


## Extend, never shorten, a finite stun duration.
func apply_stun(duration: float) -> void:
	if is_finite(duration):
		stun_remaining = maxf(stun_remaining, maxf(duration, 0.0))
