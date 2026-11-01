extends Node3D
## Yük's lab cargo, trajectory preview and smoke/bait effects; not a general inventory.

signal noise_emitted(point: Vector3, radius: float)
const CargoItem = preload("res://src/roles/cargo_item.gd")

var profile: Resource
var items: Array[Node3D] = []
var carried: Array[Node3D] = []
var throw_cooldown := 0.0
var utility_cooldown := 0.0
var utility_mode := "smoke"
var message := ""
var aiming := false
var landing_point := Vector3.ZERO
var catches := 0
var _enabled := false
var _preview: MeshInstance3D
var _held_mesh: MeshInstance3D
var _utility_effects: Array[Dictionary] = []
var _receiver: Node3D
var _receiver_label: Label3D

func _ready() -> void:
	for sample in [[Vector3(2, 0.4, 10), false], [Vector3(3.5, 0.4, 10), true]]:
		var item = CargoItem.new()
		item.position = sample[0]
		item.is_core = sample[1]
		add_child(item)
		items.append(item)
	_preview = MeshInstance3D.new()
	_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_preview)
	_held_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.42, 0.42, 0.42)
	_held_mesh.mesh = box
	_held_mesh.material_override = _material(Color("75d9e6"))
	_held_mesh.visible = false
	add_child(_held_mesh)
	_receiver = Node3D.new()
	_receiver.position = Vector3(0, 0.1, 12)
	add_child(_receiver)
	var marker := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.8
	ring.outer_radius = 1.0
	marker.mesh = ring
	marker.material_override = _material(Color("66e0c2"))
	_receiver.add_child(marker)
	_receiver_label = Label3D.new()
	_receiver_label.position.y = 0.5
	_receiver_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_receiver_label.pixel_size = 0.012
	_receiver_label.text = tr("YAKALAMA HEDEFİ")
	_receiver.add_child(_receiver_label)

## Configure the selected role and safely release cargo when leaving Yük.
func set_role(role: Resource) -> void:
	if _enabled and (role == null or role.role_id != &"yuk"):
		release_carried()
	profile = role
	_enabled = profile != null and profile.role_id == &"yuk"
	cancel_aim()


## Release all carried items in place when a role switch removes cargo ownership.
func release_carried() -> void:
	for item in carried:
		item.launch(_held_mesh.global_position, Vector3.ZERO)
		item.set_meta(&"catchable", false)
	carried.clear()

## Core restrictions apply whenever the physical core is carried.
func carrying_core() -> bool:
	for item in carried:
		if item.is_core:
			return true
	return false

## Cursor/range admission for E pickup, using actual world occlusion.
func pick_item(player: CharacterBody3D, camera: Camera3D, mouse: Vector2) -> Node3D:
	if not _enabled:
		return null
	var best: Node3D
	var nearest := 55.0
	for item in items:
		if item.carried or camera.is_position_behind(item.global_position):
			continue
		if player.global_position.distance_to(item.global_position) > profile.pickup_reach:
			continue
		var distance: float = camera.unproject_position(item.global_position).distance_to(mouse)
		if distance >= nearest:
			continue
		var query := PhysicsRayQueryParameters3D.create(player.global_position, item.global_position)
		query.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider == item:
			nearest = distance
			best = item
	return best

## One physical item can occupy one slot exactly once; the core is placed last for Q/G.
func pickup(item: Node3D) -> bool:
	if not _enabled or not is_instance_valid(item) or item not in items or item.carried:
		return false
	if carried.size() >= profile.cargo_capacity:
		message = tr("Çanta dolu")
		return false
	if item.is_core and carrying_core():
		return false
	item.set_carried(true)
	if item.is_core or not carrying_core():
		carried.append(item)
	else:
		carried.push_front(item)
	message = tr("Çekirdek alındı") if item.is_core else tr("Çanta alındı")
	return true

## Hold Q to preview, release to throw. Cancelling never consumes or duplicates cargo.
func begin_aim() -> bool:
	if not _enabled or carried.is_empty() or throw_cooldown > 0.0:
		return false
	aiming = true
	return true

func cancel_aim() -> void:
	aiming = false
	if is_instance_valid(_preview):
		_preview.visible = false

## Same ballistic velocity is used by both preview and actual physical release.
func launch_velocity(origin: Vector3, desired: Vector3) -> Vector3:
	var offset := desired - origin
	var height: float = offset.y
	offset.y = 0.0
	offset = offset.limit_length(profile.throw_reach)
	var duration: float = maxf(profile.throw_flight_time, 0.1)
	return offset / duration + Vector3.UP * (height / duration + 0.5 * _gravity() * duration)

func throw_item(player: CharacterBody3D, desired: Vector3) -> bool:
	if not aiming or not _enabled or carried.is_empty() or throw_cooldown > 0.0:
		cancel_aim()
		return false
	var origin := player.global_position + Vector3.UP * 0.6
	var item: Node3D = carried.pop_back()
	item.launch(origin, launch_velocity(origin, desired))
	item.add_collision_exception_with(player)
	item.set_meta(&"thrower", player)
	item.set_meta(&"catchable", true)
	throw_cooldown = profile.throw_cooldown
	cancel_aim()
	message = tr("Fırlatıldı")
	return true

## G places cargo in free nearby space; it does not clear cargo through a wall.
func drop_item(player: CharacterBody3D) -> bool:
	if carried.is_empty():
		return false
	var point := player.global_position - player.global_basis.z * 0.9
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.46, 0.46, 0.46)
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, point)
	query.exclude = [player.get_rid()]
	if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		message = tr("Bırakmak için yer yok")
		return false
	var item: Node3D = carried.pop_back()
	item.launch(point, Vector3.ZERO)
	item.set_meta(&"catchable", false)
	cancel_aim()
	return true

## B changes only Yük's utility choice, never a weapon or another role's input.
func toggle_utility() -> void:
	utility_mode = "bait" if utility_mode == "smoke" else "smoke"

## F places the chosen effect at a clear point within reach; no AI is simulated here.
func use_utility(player: CharacterBody3D, desired: Vector3) -> bool:
	if not _enabled or utility_cooldown > 0.0:
		return false
	var start := player.global_position
	var offset := desired - start
	offset.y = 0.0
	var point := start + offset.limit_length(profile.utility_reach)
	point.y = start.y
	var query := PhysicsRayQueryParameters3D.create(start, point)
	query.exclude = [player.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		message = tr("Eşya hedefi engelli")
		return false
	var effect := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = profile.smoke_radius if utility_mode == "smoke" else 0.25
	sphere.height = sphere.radius * 2.0
	effect.mesh = sphere
	effect.material_override = _material(Color(0.6, 0.7, 0.75, 0.4) if utility_mode == "smoke" else Color("ffae73"))
	add_child(effect)
	effect.global_position = point
	var label := Label3D.new()
	label.text = tr("DUMAN") if utility_mode == "smoke" else tr("SES YEMİ")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = sphere.radius + 0.5
	label.pixel_size = 0.012
	effect.add_child(label)
	_utility_effects.append({"node": effect, "kind": utility_mode,
		"remaining": profile.utility_duration, "pulse": 0.0,
		"radius": profile.smoke_radius, "noise": profile.bait_noise_radius})
	utility_cooldown = profile.utility_cooldown
	return true

## Future perception queries can use real smoke volumes without a second smoke state.
func blocks_sight(start: Vector3, finish: Vector3) -> bool:
	for effect in _utility_effects:
		if effect.kind != "smoke":
			continue
		var closest := Geometry3D.get_closest_point_to_segment(effect.node.global_position, start, finish)
		if closest.distance_to(effect.node.global_position) < effect.radius:
			return true
	return false

## Advance only during gameplay; preview uses ray segments and stops at the first obstacle.
func advance(delta: float, player: CharacterBody3D, desired: Vector3) -> void:
	throw_cooldown = maxf(throw_cooldown - delta, 0.0)
	utility_cooldown = maxf(utility_cooldown - delta, 0.0)
	_held_mesh.visible = not carried.is_empty()
	_held_mesh.global_position = player.global_position + Vector3.UP * 0.8
	if aiming:
		_draw_preview(player, desired)
	for index in range(_utility_effects.size() - 1, -1, -1):
		var effect: Dictionary = _utility_effects[index]
		effect.remaining -= delta
		effect.pulse -= delta
		if effect.kind == "bait" and effect.pulse <= 0.0:
			noise_emitted.emit(effect.node.global_position, effect.noise)
			effect.pulse = 1.0
		if effect.remaining <= 0.0:
			effect.node.queue_free()
			_utility_effects.remove_at(index)
	for item in items:
		if item.carried:
			continue
		var thrower = item.get_meta(&"thrower") if item.has_meta(&"thrower") else null
		if is_instance_valid(thrower) and item.global_position.distance_to(thrower.global_position) > 1.0:
			item.remove_collision_exception_with(thrower)
			item.remove_meta(&"thrower")
		if item.has_meta(&"catchable") and item.get_meta(&"catchable"):
			var offset: Vector3 = item.global_position - _receiver.global_position
			if Vector2(offset.x, offset.z).length() < 1.0 and offset.y < 1.5:
				item.set_carried(true)
				item.set_meta(&"catchable", false)
				catches += 1
				_receiver_label.text = tr("YAKALANDI") + " %d" % catches
		if item.global_position.y < -5.0:
			item.reset_item()

## Freeze world cargo as well as cancelling previews when pausing.
func set_paused(value: bool) -> void:
	cancel_aim()
	for item in items:
		if not item.carried:
			if value:
				item.set_meta(&"paused_velocity", item.linear_velocity)
				item.set_meta(&"paused_spin", item.angular_velocity)
			item.freeze = value
			if not value:
				item.linear_velocity = item.get_meta(&"paused_velocity", Vector3.ZERO)
				item.angular_velocity = item.get_meta(&"paused_spin", Vector3.ZERO)

func reset_cargo() -> void:
	cancel_aim()
	carried.clear()
	for item in items:
		var thrower = item.get_meta(&"thrower") if item.has_meta(&"thrower") else null
		if is_instance_valid(thrower):
			item.remove_collision_exception_with(thrower)
			item.remove_meta(&"thrower")
		item.set_meta(&"catchable", false)
		item.set_meta(&"paused_velocity", Vector3.ZERO)
		item.set_meta(&"paused_spin", Vector3.ZERO)
		item.reset_item()
	for effect in _utility_effects:
		effect.node.queue_free()
	_utility_effects.clear()
	throw_cooldown = 0.0
	utility_cooldown = 0.0
	catches = 0
	_receiver_label.text = tr("YAKALAMA HEDEFİ")
	_held_mesh.visible = false
	message = ""

func _draw_preview(player: CharacterBody3D, desired: Vector3) -> void:
	var origin := player.global_position + Vector3.UP * 0.6
	var velocity := launch_velocity(origin, desired)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material(Color("ffae73")))
	var previous := origin
	for index in range(1, 31):
		var t: float = index * profile.throw_flight_time / 20.0
		var point := origin + velocity * t + Vector3.DOWN * 0.5 * _gravity() * t * t
		var query := PhysicsRayQueryParameters3D.create(previous, point)
		query.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			point = hit.position
		mesh.surface_add_vertex(to_local(previous))
		mesh.surface_add_vertex(to_local(point))
		landing_point = point
		previous = point
		if not hit.is_empty():
			break
	mesh.surface_end()
	_preview.mesh = mesh
	_preview.visible = true

func _gravity() -> float:
	return float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
