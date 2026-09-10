class_name ProductionStageRuntime
extends Node2D

const ENEMY_BEETLE := 0
const ENEMY_WOLF := 1

var _rng := RandomNumberGenerator.new()
var _waves: Array
var _beetle: Dictionary
var _wolf: Dictionary

var _projectile_speed: float
var _projectile_radius: float
var _projectile_despawn_radius_squared: float
var _xp_radius: float
var _xp_magnet_speed: float
var _grid_size: float

var _enemy_positions := PackedVector2Array()
var _enemy_hp := PackedInt32Array()
var _enemy_kind := PackedByteArray()
var _enemy_count: int = 0

var _projectile_positions := PackedVector2Array()
var _projectile_velocities := PackedVector2Array()
var _projectile_damage := PackedInt32Array()
var _projectile_count: int = 0

var _pickup_positions := PackedVector2Array()
var _pickup_count: int = 0

var _spawn_left: float = 0.2
var _attack_left: float = 0.1
var _focus_position := Vector2.ZERO

var xp_gained_this_tick: int = 0
var kills_gained_this_tick: int = 0
var dropped_enemy_spawns: int = 0
var dropped_projectiles: int = 0
var dropped_pickups: int = 0


## Preallocates all run-time storage and loads combat values from configuration.
## Example: `stage.configure(config, 20260910)`.
func configure(config: Dictionary, seed: int) -> void:
	var combat: Dictionary = config["combat"]
	var capacities: Dictionary = config["capacities"]
	_waves = config["waves"]
	_beetle = config["enemies"]["beetle"]
	_wolf = config["enemies"]["wolf"]
	_projectile_speed = float(combat["projectile_speed"])
	_projectile_radius = float(combat["projectile_radius"])
	_projectile_despawn_radius_squared = pow(float(combat["projectile_despawn_radius"]), 2.0)
	_xp_radius = float(combat["xp_radius"])
	_xp_magnet_speed = float(combat["xp_magnet_speed"])
	_grid_size = float(combat["grid_size"])
	_enemy_positions.resize(int(capacities["enemies"]))
	_enemy_hp.resize(int(capacities["enemies"]))
	_enemy_kind.resize(int(capacities["enemies"]))
	_projectile_positions.resize(int(capacities["projectiles"]))
	_projectile_velocities.resize(int(capacities["projectiles"]))
	_projectile_damage.resize(int(capacities["projectiles"]))
	_pickup_positions.resize(int(capacities["pickups"]))
	if seed > 0:
		_rng.seed = seed
	else:
		_rng.randomize()
	reset_run()

## Clears counters while retaining preallocated buffers. Example: `stage.reset_run()`.
func reset_run() -> void:
	_enemy_count = 0
	_projectile_count = 0
	_pickup_count = 0
	_spawn_left = 0.2
	_attack_left = 0.1
	xp_gained_this_tick = 0
	kills_gained_this_tick = 0
	dropped_enemy_spawns = 0
	dropped_projectiles = 0
	dropped_pickups = 0
	queue_redraw()

## Runs spawning, attacks, collision, damage, and pickup phases without growing arrays.
## Example: `stage.run_phase(&"STAGE_SIMULATE", delta, elapsed, player)`.
func run_phase(phase: StringName, delta: float, elapsed: float, player: ProductionPlayerController) -> bool:
	if phase != &"STAGE_SIMULATE" or delta < 0.0 or player == null:
		return false
	xp_gained_this_tick = 0
	kills_gained_this_tick = 0
	_focus_position = player.position
	_update_spawning(delta, elapsed, player.position)
	_update_attacks(delta, player)
	_update_projectiles(delta, player)
	_update_enemies(delta, player)
	_update_pickups(delta, player)
	queue_redraw()
	return true

## Computes a deterministic survival direction for headless smoke validation.
## Example: `direction = stage.smoke_move_direction(elapsed, player.position)`.
func smoke_move_direction(elapsed: float, player_position: Vector2) -> Vector2:
	var direction := Vector2(sin(elapsed * 0.83), cos(elapsed * 0.61))
	var nearest_distance := INF
	var nearest_pickup := Vector2.ZERO
	for index in _pickup_count:
		var distance := player_position.distance_squared_to(_pickup_positions[index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_pickup = player_position.direction_to(_pickup_positions[index])
	var escape := Vector2.ZERO
	for index in _enemy_count:
		var distance := player_position.distance_to(_enemy_positions[index])
		if distance < 430.0:
			escape += _enemy_positions[index].direction_to(player_position) * (1.0 - distance / 430.0) * 4.0
	var combined := direction * 0.45 + nearest_pickup * 1.35 + escape
	return combined.normalized() if not combined.is_zero_approx() else direction.normalized()

## Returns the wave display name without transferring ownership. Example: `stage.wave_name(elapsed)`.
func wave_name(elapsed: float) -> String:
	return String((_waves[_wave_index(elapsed)] as Dictionary)["name"])

## Returns the live enemy count for diagnostics. Example: `stage.enemy_count()`.
func enemy_count() -> int:
	return _enemy_count

func _update_spawning(delta: float, elapsed: float, player_position: Vector2) -> void:
	_spawn_left -= delta
	if _spawn_left > 0.0:
		return
	var wave: Dictionary = _waves[_wave_index(elapsed)]
	_spawn_left += float(wave["spawn_interval"])
	if _enemy_count >= _enemy_positions.size():
		dropped_enemy_spawns += 1
		return
	var kind := ENEMY_WOLF if _rng.randf() < float(wave["wolf_probability"]) else ENEMY_BEETLE
	var enemy: Dictionary = _wolf if kind == ENEMY_WOLF else _beetle
	var radius := float(enemy["radius"])
	var half_view := get_viewport_rect().size * 0.5
	var horizontal_edge := half_view.x + radius + 65.0
	var vertical_edge := half_view.y + radius + 65.0
	var offset := Vector2.ZERO
	match _rng.randi_range(0, 3):
		0:
			offset = Vector2(_rng.randf_range(-horizontal_edge, horizontal_edge), -vertical_edge)
		1:
			offset = Vector2(horizontal_edge, _rng.randf_range(-vertical_edge, vertical_edge))
		2:
			offset = Vector2(_rng.randf_range(-horizontal_edge, horizontal_edge), vertical_edge)
		_:
			offset = Vector2(-horizontal_edge, _rng.randf_range(-vertical_edge, vertical_edge))
	_enemy_positions[_enemy_count] = player_position + offset
	_enemy_hp[_enemy_count] = int(enemy["hp"])
	_enemy_kind[_enemy_count] = kind
	_enemy_count += 1

func _update_attacks(delta: float, player: ProductionPlayerController) -> void:
	_attack_left -= delta
	if _attack_left > 0.0 or _enemy_count == 0:
		return
	_attack_left += player.attack_interval
	var nearest_position := _enemy_positions[0]
	var nearest_distance := player.position.distance_squared_to(nearest_position)
	for index in _enemy_count:
		var distance := player.position.distance_squared_to(_enemy_positions[index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_position = _enemy_positions[index]
	var base_direction := player.position.direction_to(nearest_position)
	for sword_index in player.sword_count:
		if _projectile_count >= _projectile_positions.size():
			dropped_projectiles += player.sword_count - sword_index
			return
		var spread := (float(sword_index) - float(player.sword_count - 1) * 0.5) * 0.14
		_projectile_positions[_projectile_count] = player.position
		_projectile_velocities[_projectile_count] = base_direction.rotated(spread) * _projectile_speed
		_projectile_damage[_projectile_count] = player.sword_damage
		_projectile_count += 1

func _update_projectiles(delta: float, player: ProductionPlayerController) -> void:
	var projectile_index := _projectile_count - 1
	while projectile_index >= 0:
		_projectile_positions[projectile_index] += _projectile_velocities[projectile_index] * delta
		var projectile_position := _projectile_positions[projectile_index]
		if projectile_position.distance_squared_to(player.position) > _projectile_despawn_radius_squared:
			_remove_projectile(projectile_index)
			projectile_index -= 1
			continue
		var hit_index := -1
		for enemy_index in _enemy_count:
			var enemy := _enemy_data(_enemy_kind[enemy_index])
			var collision_radius := _projectile_radius + float(enemy["radius"])
			if projectile_position.distance_squared_to(_enemy_positions[enemy_index]) <= collision_radius * collision_radius:
				hit_index = enemy_index
				break
		if hit_index >= 0:
			_enemy_hp[hit_index] -= _projectile_damage[projectile_index]
			_remove_projectile(projectile_index)
			if _enemy_hp[hit_index] <= 0:
				_defeat_enemy(hit_index)
		projectile_index -= 1

func _update_enemies(delta: float, player: ProductionPlayerController) -> void:
	for index in _enemy_count:
		var enemy: Dictionary = _enemy_data(_enemy_kind[index])
		_enemy_positions[index] += _enemy_positions[index].direction_to(player.position) * float(enemy["speed"]) * delta
		var collision_radius := player.radius + float(enemy["radius"])
		if _enemy_positions[index].distance_squared_to(player.position) <= collision_radius * collision_radius:
			player.apply_contact_damage(float(enemy["contact_damage"]))

func _update_pickups(delta: float, player: ProductionPlayerController) -> void:
	var index := _pickup_count - 1
	while index >= 0:
		var distance := _pickup_positions[index].distance_to(player.position)
		if distance <= player.pickup_radius * 2.4:
			_pickup_positions[index] = _pickup_positions[index].move_toward(player.position, _xp_magnet_speed * delta)
		if _pickup_positions[index].distance_to(player.position) <= player.radius + _xp_radius:
			_remove_pickup(index)
			xp_gained_this_tick += 1
		index -= 1

func _defeat_enemy(index: int) -> void:
	var defeated_position := _enemy_positions[index]
	_remove_enemy(index)
	kills_gained_this_tick += 1
	if _pickup_count >= _pickup_positions.size():
		dropped_pickups += 1
		return
	_pickup_positions[_pickup_count] = defeated_position
	_pickup_count += 1

func _remove_enemy(index: int) -> void:
	_enemy_count -= 1
	if index != _enemy_count:
		_enemy_positions[index] = _enemy_positions[_enemy_count]
		_enemy_hp[index] = _enemy_hp[_enemy_count]
		_enemy_kind[index] = _enemy_kind[_enemy_count]

func _remove_projectile(index: int) -> void:
	_projectile_count -= 1
	if index != _projectile_count:
		_projectile_positions[index] = _projectile_positions[_projectile_count]
		_projectile_velocities[index] = _projectile_velocities[_projectile_count]
		_projectile_damage[index] = _projectile_damage[_projectile_count]

func _remove_pickup(index: int) -> void:
	_pickup_count -= 1
	if index != _pickup_count:
		_pickup_positions[index] = _pickup_positions[_pickup_count]

func _enemy_data(kind: int) -> Dictionary:
	return _wolf if kind == ENEMY_WOLF else _beetle

func _wave_index(elapsed: float) -> int:
	for index in _waves.size():
		if elapsed < float((_waves[index] as Dictionary)["until_seconds"]):
			return index
	return _waves.size() - 1

func _draw() -> void:
	var visible_size := get_viewport_rect().size
	var visible_world := Rect2(_focus_position - visible_size * 0.62, visible_size * 1.24)
	draw_rect(visible_world, Color("102c2d"), true)
	var x := floorf(visible_world.position.x / _grid_size) * _grid_size
	while x <= visible_world.end.x:
		draw_line(Vector2(x, visible_world.position.y), Vector2(x, visible_world.end.y), Color(0.18, 0.32, 0.28, 0.22), 1.0)
		x += _grid_size
	var y := floorf(visible_world.position.y / _grid_size) * _grid_size
	while y <= visible_world.end.y:
		draw_line(Vector2(visible_world.position.x, y), Vector2(visible_world.end.x, y), Color(0.18, 0.32, 0.28, 0.22), 1.0)
		y += _grid_size
	for index in _pickup_count:
		draw_circle(_pickup_positions[index], _xp_radius + 5.0, Color(0.20, 0.95, 0.78, 0.18))
		draw_circle(_pickup_positions[index], _xp_radius, Color("55edbe"))
	for index in _enemy_count:
		var enemy: Dictionary = _enemy_data(_enemy_kind[index])
		var position_value := _enemy_positions[index]
		var radius := float(enemy["radius"])
		if _enemy_kind[index] == ENEMY_WOLF:
			draw_line(position_value + Vector2(0.0, -radius), position_value + Vector2(radius, 0.0), Color("e17a45"), 9.0)
			draw_line(position_value + Vector2(radius, 0.0), position_value + Vector2(0.0, radius), Color("e17a45"), 9.0)
			draw_line(position_value + Vector2(0.0, radius), position_value + Vector2(-radius, 0.0), Color("e17a45"), 9.0)
			draw_line(position_value + Vector2(-radius, 0.0), position_value + Vector2(0.0, -radius), Color("e17a45"), 9.0)
		else:
			draw_circle(position_value, radius + 4.0, Color(0.0, 0.0, 0.0, 0.3))
			draw_circle(position_value, radius, Color("a93d49"))
	for index in _projectile_count:
		var velocity := _projectile_velocities[index]
		var direction := velocity.normalized()
		draw_line(_projectile_positions[index] - direction * 16.0, _projectile_positions[index] + direction * 12.0, Color("d6f5ff"), 7.0)
		draw_circle(_projectile_positions[index], _projectile_radius, Color("80d9ef"))

