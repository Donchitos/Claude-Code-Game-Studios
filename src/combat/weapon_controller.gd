extends Node3D
## Shared shot admission, per-weapon magazines and actual world ray collisions.

const Profile = preload("res://src/combat/weapon_profile.gd")
const State = preload("res://src/combat/player_combat.gd")
signal shot_traced(start: Vector3, finish: Vector3, hit: bool)
signal noise_emitted(point: Vector3, radius: float)
signal weapon_changed(profile: Resource)

var state: State
var profiles: Array = [
	preload("res://assets/data/weapons/pistol.tres"),
	preload("res://assets/data/weapons/shock.tres"),
	preload("res://assets/data/weapons/shotgun.tres"),
	preload("res://assets/data/weapons/carbine.tres")]
var selected := 0
var excluded: Array[RID] = []
var noise_multiplier: float = 1.0
var _magazines: Dictionary = {}
var _cooldown := 0.0
var _bloom := 0.0
var _random := RandomNumberGenerator.new()

func _ready() -> void:
	_random.randomize()
	reset_weapon()

## Return the profile whose ammunition is shown by the current state.
func current_profile() -> Resource:
	return profiles[selected]

## Switch without refilling ammunition; unlimited refills remain an explicit R action.
func select_weapon(index: int) -> void:
	if index < 0 or index >= profiles.size() or index == selected:
		return
	state.cancel_reload()
	_magazines[selected] = state.ammo
	selected = index
	state.magazine_capacity = profiles[selected].capacity
	state.ammo = _magazines.get(selected, state.magazine_capacity)
	state.ammo_changed.emit(state.ammo, state.magazine_capacity)
	weapon_changed.emit(profiles[selected])
	if state.ammo == 0:
		state.reload()

## Advance fire cadence and spread recovery, independently of render rate.
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	_bloom = maxf(_bloom - profiles[selected].spread_recovery * delta, 0.0)

## Consume one round, raycast every pellet, and stop each ray at its first solid hit.
func fire_at(origin: Vector3, direction: Vector3, moving: bool) -> bool:
	if _cooldown > 0.0 or not origin.is_finite() or not direction.is_finite() or direction.is_zero_approx():
		return false
	if not state.try_fire():
		return false
	var profile: Resource = profiles[selected]
	_cooldown = maxf(profile.shot_interval, 0.0)
	var spread: float = profile.spread_degrees + _bloom
	if moving:
		spread += profile.moving_spread

	var final_damage: float = profile.damage
	if state != null and "active_reload_bonus_shots" in state and state.active_reload_bonus_shots > 0:
		final_damage *= 1.25

	for pellet in range(maxi(profile.pellets, 1)):
		var yaw := deg_to_rad(_random.randf_range(-spread, spread))
		var ray: Vector3 = direction.normalized().rotated(Vector3.UP, yaw)
		var finish: Vector3 = origin + ray * maxf(profile.distance, 0.0)
		var query := PhysicsRayQueryParameters3D.create(origin, finish)
		query.exclude = excluded.duplicate()
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		while not hit.is_empty() and hit.collider.has_method(&"blocks_shot"):
			if hit.collider.blocks_shot(0):
				break
			var ignored: Array[RID] = query.exclude
			ignored.append(hit.collider.get_rid())
			query.exclude = ignored
			hit = get_world_3d().direct_space_state.intersect_ray(query)
		var damaged := false
		if not hit.is_empty():
			finish = hit.position
			var collider: Object = hit.collider
			if collider.has_method(&"receive_hit"):
				damaged = collider.receive_hit(final_damage, 0, profile.stun_duration)
		shot_traced.emit(origin, finish, damaged)

	if state != null and "active_reload_bonus_shots" in state and state.active_reload_bonus_shots > 0:
		state.active_reload_bonus_shots -= 1

	_bloom = minf(_bloom + profile.recoil_spread, 8.0)
	noise_emitted.emit(origin, profile.noise_radius * noise_multiplier)
	return true

## Reset every magazine and spread/cadence while returning to the original pistol.
func reset_weapon() -> void:
	state.cancel_reload()
	_magazines.clear()
	selected = 0
	_cooldown = 0.0
	_bloom = 0.0
	state.magazine_capacity = profiles[0].capacity
	state.ammo = state.magazine_capacity
	state.ammo_changed.emit(state.ammo, state.magazine_capacity)
	weapon_changed.emit(profiles[0])
