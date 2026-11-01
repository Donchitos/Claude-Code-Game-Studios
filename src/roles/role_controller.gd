extends Node
## Role admission, Kilit channel/cooldowns and cone ability; no input or UI ownership.

signal role_changed(profile: Resource)
signal fuse_cast(origin: Vector3, direction: Vector3, reach: float, angle: float)

const PROFILES = [
	preload("res://assets/data/roles/operator.tres"),
	preload("res://assets/data/roles/kilit.tres"),
	preload("res://assets/data/roles/kirici.tres"),
	preload("res://assets/data/roles/yuk.tres"),
	preload("res://assets/data/roles/goz.tres")]
const ShieldWall = preload("res://src/roles/shield_wall.gd")
signal noise_emitted(point: Vector3, radius: float)
var break_cooldown_remaining: float = 0.0
var shield_cooldown_remaining: float = 0.0
var active_shield: Node3D
var _footstep_wait: float = 0.0

var selected: int = 0
var hack_target: Node3D
var hack_progress: float = 0.0
var hack_cooldown_remaining: float = 0.0
var fuse_cooldown_remaining: float = 0.0
var message: String = ""
var _elapsed: float = 0.0

## Return the selected role data. Only implemented roles are selectable.
func current_profile() -> Resource:
	return PROFILES[selected]

## Changing roles cancels a channel; cooldowns are not reset by switching.
func select_role(index: int) -> void:
	if index < 0 or index >= PROFILES.size() or index == selected:
		return
	cancel_hack()
	_remove_shield()
	selected = index
	message = ""
	role_changed.emit(current_profile())

## Start a hack only on a valid, visible, reachable system while standing on the floor.
func begin_hack(target: Node3D, player: CharacterBody3D, clear_los: bool) -> bool:
	if current_profile().role_id != &"kilit" or is_hacking():
		return false
	if hack_cooldown_remaining > 0.0:
		message = tr("Hack beklemede")
		return false
	if not _valid_hack_target(target):
		message = tr("Terminal, kapı veya kamera hedefle")
		return false
	if not player.is_on_floor():
		message = tr("Hack için yere bas")
		return false
	if not clear_los or player.global_position.distance_to(target.global_position) > current_profile().hack_reach:
		message = tr("Hack hedefi uzak veya görüş engelli")
		return false
	hack_target = target
	_elapsed = 0.0
	hack_progress = 0.0
	message = ""
	return true

## Advance a channel; target changes, focus/pause, damage or movement intent cancel via caller.
func advance(delta: float, player: CharacterBody3D, aimed_target: Node3D, clear_los: bool) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	break_cooldown_remaining = maxf(break_cooldown_remaining - delta, 0.0)
	shield_cooldown_remaining = maxf(shield_cooldown_remaining - delta, 0.0)
	_footstep_wait = maxf(_footstep_wait - delta, 0.0)
	if is_instance_valid(active_shield):
		active_shield.advance(delta)
	if current_profile().role_id == &"kirici" and player.is_on_floor():
		if Vector2(player.velocity.x, player.velocity.z).length() > 0.1 and _footstep_wait <= 0.0:
			var volume: float = 0.7 if player.is_slow_walking else 1.0
			noise_emitted.emit(player.global_position, current_profile().footstep_noise_radius * volume)
			_footstep_wait = 0.45
	hack_cooldown_remaining = maxf(hack_cooldown_remaining - delta, 0.0)
	fuse_cooldown_remaining = maxf(fuse_cooldown_remaining - delta, 0.0)
	if not is_hacking():
		return
	if not _valid_hack_target(hack_target) or aimed_target != hack_target or not clear_los:
		cancel_hack(tr("Hack iptal: hedef kayboldu"))
		return
	if player.global_position.distance_to(hack_target.global_position) > current_profile().hack_reach:
		cancel_hack(tr("Hack iptal: menzil aşıldı"))
		return
	_elapsed += delta
	hack_progress = clampf(_elapsed / maxf(current_profile().hack_duration, 0.001), 0.0, 1.0)
	if hack_progress >= 1.0:
		var target: Node3D = hack_target
		cancel_hack()
		if target.activate():
			hack_cooldown_remaining = current_profile().hack_cooldown
			message = tr("Hack tamamlandı")

## Apply temporary electrical redirection and stun only to targets inside the aimed cone.
func cast_fuse(player: CharacterBody3D, direction: Vector3, electrical: Array, targets: Array) -> bool:
	if current_profile().role_id != &"kilit" or fuse_cooldown_remaining > 0.0 or is_hacking():
		return false
	var forward := Vector3(direction.x, 0.0, direction.z).normalized()
	if forward.is_zero_approx():
		return false
	var profile: Resource = current_profile()
	for device in electrical:
		if is_instance_valid(device) and _inside_cone(player.global_position, device.global_position, forward) and _clear_effect_sight(player, device):
			device.redirect_for(profile.fuse_duration)
	for target in targets:
		if is_instance_valid(target) and target.team != 0 and target.health > 0.0:
			if _inside_cone(player.global_position, target.global_position, forward) and _clear_effect_sight(player, target):
				target.apply_stun(profile.fuse_duration)
	fuse_cooldown_remaining = profile.fuse_cooldown
	fuse_cast.emit(player.global_position, forward, profile.fuse_reach, profile.fuse_angle_degrees)
	message = tr("Sigorta Ağı etkin")
	return true

## Cancel never completes the old target or consumes a successful-use cooldown.
func cancel_hack(reason: String = "") -> void:
	hack_target = null
	hack_progress = 0.0
	_elapsed = 0.0
	if not reason.is_empty():
		message = reason

## Treat a freed target as inactive so the movement lock is released immediately.
func is_hacking() -> bool:
	return is_instance_valid(hack_target)

## F5 clears temporary role actions and cooldowns while preserving selected role.
func reset_role() -> void:
	cancel_hack()
	hack_cooldown_remaining = 0.0
	fuse_cooldown_remaining = 0.0
	break_cooldown_remaining = 0.0
	shield_cooldown_remaining = 0.0
	_footstep_wait = 0.0
	_remove_shield()
	message = ""

## Close-range first-hit attack; never moves/dashes the player or hits through walls.
func strike(player: CharacterBody3D, direction: Vector3) -> bool:
	if current_profile().role_id != &"kirici" or break_cooldown_remaining > 0.0:
		return false
	var forward := Vector3(direction.x, 0.0, direction.z).normalized()
	if forward.is_zero_approx():
		return false
	var profile: Resource = current_profile()
	var origin := player.global_position + Vector3.UP * 0.25
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * profile.break_reach)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	break_cooldown_remaining = profile.break_cooldown
	noise_emitted.emit(origin, profile.ability_noise_radius)
	if not hit.is_empty():
		var target: Object = hit.collider
		if target.has_method(&"receive_strike"):
			target.receive_strike(profile.break_damage, forward, profile.break_push, profile.break_stun)
	message = tr("Kırma darbesi")
	return true


## Spawn a new wall only in clear space; failed placements do not consume cooldown.
func deploy_shield(player: CharacterBody3D, direction: Vector3) -> bool:
	if current_profile().role_id != &"kirici" or shield_cooldown_remaining > 0.0:
		return false
	var forward := Vector3(direction.x, 0.0, direction.z).normalized()
	if forward.is_zero_approx() or not player.is_on_floor():
		return false
	var point := player.global_position + forward * 1.7 + Vector3.UP * 0.32
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.6, 2.0, 0.18)
	var transform := Transform3D(Basis(Vector3.UP, atan2(-forward.x, -forward.z)), point)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.transform = transform
	query.exclude = [player.get_rid()]
	if not player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		message = tr("Kalkan için yer yok")
		return false
	_remove_shield()
	var wall = ShieldWall.new()
	wall.remaining = current_profile().shield_duration
	wall.health = current_profile().shield_health
	player.get_parent().add_child(wall)
	wall.global_transform = transform
	active_shield = wall
	shield_cooldown_remaining = current_profile().shield_cooldown
	noise_emitted.emit(point, current_profile().ability_noise_radius)
	message = tr("Kalkan Duvarı kuruldu")
	return true


func _exit_tree() -> void:
	_remove_shield()


func _remove_shield() -> void:
	if is_instance_valid(active_shield):
		active_shield.expire()
	active_shield = null


func _valid_hack_target(target: Node3D) -> bool:
	return is_instance_valid(target) and target.has_method(&"activate") \
		and target.has_method(&"can_hack") and target.can_hack()

func _clear_effect_sight(player: CharacterBody3D, target: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(player.global_position, target.global_position)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target


func _inside_cone(origin: Vector3, point: Vector3, forward: Vector3) -> bool:
	var offset := point - origin
	offset.y = 0.0
	if offset.length() > current_profile().fuse_reach:
		return false
	return offset.is_zero_approx() or forward.dot(offset.normalized()) >= cos(deg_to_rad(current_profile().fuse_angle_degrees * 0.5))
