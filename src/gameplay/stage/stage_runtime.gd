class_name ProductionStageRuntime
extends Node2D

const SpatialGrid = preload("res://src/gameplay/stage/spatial_grid.gd")
const SpatialHandleBuffer = preload("res://src/gameplay/stage/spatial_handle_buffer.gd")
const SpatialNearestBuffer = preload("res://src/gameplay/stage/spatial_nearest_buffer.gd")
const SpatialQueryBuffer = preload("res://src/gameplay/stage/spatial_query_buffer.gd")
var _projectile_candidates = SpatialQueryBuffer.new()
var projectile_candidates_this_tick := 0
var measure_draw_cpu := false
var last_draw_cpu_usec := 0
var draw_measurement_count := 0
var draw_culling_enabled := true
var draw_objects_submitted := 0
var draw_objects_culled := 0

# Inclusive conservative footprint check: touching the viewport is still visible.
static func draw_footprint_visible(view: Rect2, center: Vector2, radius: float) -> bool:
	return center.x + radius >= view.position.x and center.x - radius <= view.end.x \
		and center.y + radius >= view.position.y and center.y - radius <= view.end.y

func _keep_draw_object(view: Rect2, center: Vector2, radius: float) -> bool:
	if draw_culling_enabled and not draw_footprint_visible(view, center, radius):
		draw_objects_culled += 1
		return false
	draw_objects_submitted += 1
	return true
const ObjectPool = preload("res://src/gameplay/stage/object_pool.gd")
const PoolBorrowBuffer = preload("res://src/gameplay/stage/pool_borrow_buffer.gd")

const ENEMY_BEETLE := 0
const ENEMY_WOLF := 1
const ENEMY_BOSS := 2
const ENEMY_SUMMON := 3
const BossCombat = preload("res://src/gameplay/boss/boss_combat.gd")
const CombatGeometry = preload("res://src/gameplay/battle/combat_geometry.gd")
const PlayerDamageBatch = preload("res://src/gameplay/battle/player_damage_batch.gd")
var _player_damage = PlayerDamageBatch.new()
var boss_enabled := false
var boss_defeated := false
var boss_spawn_count := 0
var _boss: Dictionary
var boss_combat = BossCombat.new()
var _boss_handle := 0
var _damage_receipt := 0
var _hostile_positions := PackedVector2Array()
var _hostile_velocities := PackedVector2Array()
var _hostile_life := PackedInt32Array()
var _hostile_count := 0
var _ring_pending := false
var _ring_origin := Vector2.ZERO
var _ring_generation := 0
var _summon_pending := false
var _ring_source := 0
var _summon_source := 0
var _summon_generation := 0
var _world_half_extent := 0.0
const SpawnCandidates = preload("res://src/gameplay/boss/boss_spawn_candidates.gd")
var _summon_candidates = SpawnCandidates.new()

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
var _enemy_hp := PackedFloat32Array()
var _enemy_kind := PackedByteArray()
var _enemy_borrow_ids := PackedInt64Array()
var _enemy_grid_handles := PackedInt64Array()
var _enemy_count: int = 0

var _spatial_grid: Node
var _enemy_pool: Node
var _pool_borrow_buffer
var _spatial_handle_buffer
var _nearest_enemy_buffer

var _projectile_positions := PackedVector2Array()
var _projectile_velocities := PackedVector2Array()
var _projectile_damage := PackedFloat32Array()
var _projectile_count: int = 0
var _closed := false
const WEAPON_PENDING_CAPACITY := 32
var _weapon_pending_positions := PackedVector2Array()
var _weapon_pending_velocities := PackedVector2Array()
var _weapon_pending_damage := PackedFloat32Array()
var _weapon_pending_count := 0
var _weapon_due_tick := 0
var _simulation_tick := 0
var _hazard_snapshot: Dictionary = {}
var _boss_tick_hazards: Array[Dictionary] = []

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
func configure(config: Dictionary, seed: int) -> bool:
	if not valid_schedule(config):
		return false
	var combat: Dictionary = config["combat"]
	var capacities: Dictionary = config["capacities"]
	var enemy_capacity := int(capacities["enemies"])
	boss_enabled = bool(config["run"].get("boss_enabled", false))
	_boss = config["enemies"].get("boss", {})
	if boss_enabled and (_boss.is_empty() or enemy_capacity < 2):
		return false
	if boss_enabled:
		for field in ["hp", "radius", "speed", "contact_damage"]:
			var value := float(_boss.get(field, -1.0))
			if not is_finite(value) or value <= 0.0:
				return false
		boss_combat.initialize(float(_boss["hp"]))
	_hostile_positions.resize(8)
	_hostile_velocities.resize(8)
	_hostile_life.resize(8)
	_waves = config["waves"]
	_beetle = config["enemies"]["beetle"]
	_wolf = config["enemies"]["wolf"]
	_projectile_speed = float(combat["projectile_speed"])
	_projectile_radius = float(combat["projectile_radius"])
	_projectile_despawn_radius_squared = pow(float(combat["projectile_despawn_radius"]), 2.0)
	_xp_radius = float(combat["xp_radius"])
	_xp_magnet_speed = float(combat["xp_magnet_speed"])
	_grid_size = float(combat["grid_size"])
	_enemy_positions.resize(enemy_capacity)
	_enemy_hp.resize(enemy_capacity)
	_enemy_kind.resize(enemy_capacity)
	_enemy_borrow_ids.resize(enemy_capacity)
	_enemy_grid_handles.resize(enemy_capacity)
	var friendly_capacity := int(capacities["projectiles"]) - (8 if boss_enabled else 0)
	if friendly_capacity <= 0:
		return false
	_projectile_positions.resize(friendly_capacity)
	_projectile_velocities.resize(friendly_capacity)
	_projectile_damage.resize(friendly_capacity)
	_projectile_candidates.configure(enemy_capacity)
	_weapon_pending_positions.resize(WEAPON_PENDING_CAPACITY)
	_weapon_pending_velocities.resize(WEAPON_PENDING_CAPACITY)
	_weapon_pending_damage.resize(WEAPON_PENDING_CAPACITY)
	_pickup_positions.resize(int(capacities["pickups"]))
	_spatial_grid = SpatialGrid.new()
	_spatial_grid.name = "SpatialGrid"
	add_child(_spatial_grid)
	var world_half_extent := float(combat.get("world_half_extent", 16384.0))
	_world_half_extent = world_half_extent
	var max_query_cells := int(combat.get("max_query_cells", 262144))
	if _spatial_grid.call("initialize", world_half_extent, _grid_size, enemy_capacity, enemy_capacity, max_query_cells) != SpatialGrid.Status.OK:
		return false
	_enemy_pool = ObjectPool.new()
	_enemy_pool.name = "EnemyPool"
	add_child(_enemy_pool)
	if _enemy_pool.call("initialize", enemy_capacity, Callable(self, "_make_enemy_identity")) != ObjectPool.Status.OK:
		return false
	_pool_borrow_buffer = PoolBorrowBuffer.new()
	_spatial_handle_buffer = SpatialHandleBuffer.new()
	_nearest_enemy_buffer = SpatialNearestBuffer.new()
	if seed > 0:
		_rng.seed = seed
	else:
		_rng.randomize()
	reset_run()
	return true

## Clears counters while retaining preallocated buffers. Example: `stage.reset_run()`.
func reset_run() -> void:
	_weapon_pending_count = 0
	_simulation_tick = 0
	_hazard_snapshot.clear()
	_boss_tick_hazards.clear()
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
	for index in _enemy_borrow_ids.size():
		_enemy_borrow_ids[index] = 0
		_enemy_grid_handles[index] = 0
	queue_redraw()

## Removes Grid ownership before returning every enemy identity to its pool.
func teardown() -> bool:
	_boss_tick_hazards.clear()
	_closed = true
	_weapon_pending_count = 0
	_hazard_snapshot.clear()
	_projectile_count = 0
	_pickup_count = 0
	_player_damage.clear()
	_ring_pending = false
	_summon_pending = false
	_hostile_count = 0
	while _enemy_count > 0:
		if not _remove_enemy(_enemy_count - 1):
			return false
	return spatial_active_count() == 0 and enemy_pool_borrowed_count() == 0

## Runs spawning, attacks, collision, damage, and pickup phases without growing arrays.
## Example: `stage.run_phase(&"STAGE_SIMULATE", delta, elapsed, player)`.
func run_phase(phase: StringName, delta: float, elapsed: float, player: ProductionPlayerController) -> bool:
	if _closed or phase != &"STAGE_SIMULATE" or not is_finite(delta) or delta < 0.0 or not is_finite(elapsed) or player == null:
		return false
	xp_gained_this_tick = 0
	kills_gained_this_tick = 0
	_focus_position = player.position
	_simulation_tick += 1
	_boss_tick_hazards.clear()
	_hazard_snapshot.clear()
	_player_damage.clear()
	if not _deliver_weapon_pending():
		return false
	if not _update_boss_schedule(elapsed, player.position):
		return false
	if not _update_spawning(delta, elapsed, player.position):
		return false
	if not _update_attacks(delta, player):
		return false
	if not _update_projectiles(delta, player):
		return false
	if not _update_enemies(delta, player):
		return false
	if not boss_defeated:
		_update_hostile_projectiles(player)
	if not _player_damage.commit(player):
		return false
	if _spatial_grid.call("sync") != SpatialGrid.Status.OK:
		return false
	_update_pickups(delta, player)
	_publish_hazards()
	queue_redraw()
	return true

# Detached presentation/query adapter, not the full DamageSystem hazard ABI.
# A caller must match both this Stage identity and the published active tick.
func hazard_snapshot(stage_id: int, tick: int) -> Dictionary:
	if _closed or stage_id != get_instance_id() or tick != _simulation_tick or _hazard_snapshot.is_empty():
		return {}
	return _hazard_snapshot.duplicate(true)

func _publish_hazards() -> void:
	var contacts: Array[Dictionary] = []
	for index in _enemy_count:
		if _enemy_kind[index] != ENEMY_BOSS:
			contacts.append({"position": _enemy_positions[index], "radius": float(_enemy_data(_enemy_kind[index])["radius"]), "source_id": _enemy_grid_handles[index]})
	var attacks: Array = _boss_tick_hazards.duplicate(true) if not boss_defeated else []
	var boss_index := _enemy_index_for_grid_handle(_boss_handle)
	if not boss_defeated and boss_index >= 0 and boss_combat.action == BossCombat.Action.TELEGRAPH and boss_combat.slot in [0, 1]:
		var origin := _enemy_positions[boss_index]
		attacks.append({"kind": "bite" if boss_combat.slot == 0 else "fan", "warning": true, "origin": origin, "end": origin + boss_combat.axis * 324.0, "axis": boss_combat.axis, "radius": float(_boss["radius"])})
	var bullets: Array[Dictionary] = []
	if not boss_defeated:
		for index in _hostile_count:
			bullets.append({"position": _hostile_positions[index], "velocity": _hostile_velocities[index], "radius": 10.8, "remaining_ticks": _hostile_life[index]})
	var fog: Dictionary = {}
	if not boss_defeated and boss_combat.fsm.phase_code == 2:
		fog = {"center": boss_combat.fsm.fog_anchor, "safe_radius": boss_combat.fsm.fog_safe_radius() * 60.0, "damage_interval_ticks": 60, "elapsed_ticks": boss_combat.fsm.fog_elapsed_ticks}
	_hazard_snapshot = {"stage_id": get_instance_id(), "tick": _simulation_tick, "bullets": bullets, "fog": fog, "contacts": contacts, "attacks": attacks}

# Geometric exposure, never an authoritative damage receipt or a safe-revive proof.
func query_danger(stage_id: int, tick: int, position: Vector2, radius: float) -> Dictionary:
	if not position.is_finite() or not is_finite(radius) or radius < 0.0:
		return {"valid": false}
	var snapshot := hazard_snapshot(stage_id, tick)
	if snapshot.is_empty():
		return {"valid": false}
	var exposures: Array[String] = []
	var warnings: Array[String] = []
	for contact: Dictionary in snapshot["contacts"]:
		if position.distance_to(contact["position"]) <= radius + float(contact["radius"]):
			exposures.append("敌人接触")
	for bullet: Dictionary in snapshot["bullets"]:
		if position.distance_to(bullet["position"]) <= radius + float(bullet["radius"]):
			exposures.append("毒弹")
	var fog: Dictionary = snapshot["fog"]
	if not fog.is_empty() and position.distance_to(fog["center"]) + radius > float(fog["safe_radius"]):
		exposures.append("毒雾区域")
	for attack: Dictionary in snapshot["attacks"]:
		var hit: bool
		if attack["kind"] == "fan":
			hit = CombatGeometry.sector_hits(attack["origin"], attack["axis"], 420.0, deg_to_rad(35.0), position, radius)
		else:
			hit = Geometry2D.get_closest_point_to_segment(position, attack["origin"], attack["end"]).distance_to(position) <= radius + float(attack["radius"])
		if hit:
			var label := "扑咬" if attack["kind"] == "bite" else "扇毒"
			if attack["warning"]:
				warnings.append(label)
			else:
				exposures.append(label)
	return {"valid": true, "stage_id": stage_id, "tick": tick, "exposures": exposures, "warnings": warnings}

func _deliver_weapon_pending() -> bool:
	if _weapon_pending_count == 0:
		return true
	if _weapon_due_tick != _simulation_tick:
		return false
	for index in _weapon_pending_count:
		if _projectile_count >= _projectile_positions.size():
			dropped_projectiles += _weapon_pending_count - index
			break
		_projectile_positions[_projectile_count] = _weapon_pending_positions[index]
		_projectile_velocities[_projectile_count] = _weapon_pending_velocities[index]
		_projectile_damage[_projectile_count] = _weapon_pending_damage[index]
		_projectile_count += 1
	_weapon_pending_count = 0
	return true

## Computes a deterministic survival direction for headless smoke validation.
## Example: `direction = stage.smoke_move_direction(elapsed, player.position)`.
func smoke_move_direction(elapsed: float, player_position: Vector2) -> Vector2:
	if boss_spawn_count > 0 and not boss_defeated:
		var boss_index := _enemy_index_for_grid_handle(_boss_handle)
		if boss_index >= 0:
			var offset := _enemy_positions[boss_index] - player_position
			return offset.normalized() if offset.length() > 300.0 else Vector2.ZERO
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
	if boss_enabled and elapsed >= 720.0:
		return "守阵妖兽 · 二阶段" if boss_combat.fsm.phase_code == 2 else "守阵妖兽 · 决战"
	return String((_waves[_wave_index(elapsed)] as Dictionary)["name"])

## Returns the live enemy count for diagnostics. Example: `stage.enemy_count()`.
func enemy_count() -> int:
	return _enemy_count

func spatial_active_count() -> int:
	return 0 if _spatial_grid == null else int(_spatial_grid.call("active_count"))

func enemy_pool_borrowed_count() -> int:
	return 0 if _enemy_pool == null else int(_enemy_pool.call("borrowed_count"))

func _update_spawning(delta: float, elapsed: float, player_position: Vector2) -> bool:
	if boss_enabled and elapsed >= 720.0:
		return true
	_spawn_left -= delta
	if _spawn_left > 0.0:
		return true
	var wave: Dictionary = _waves[_wave_index(elapsed)]
	_spawn_left += float(wave["spawn_interval"])
	if _enemy_count >= _enemy_positions.size() - (1 if boss_enabled else 0):
		dropped_enemy_spawns += 1
		return true
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
	var spawn_position := player_position + offset
	return _spawn_enemy(kind, spawn_position)

func _spawn_enemy(kind: int, spawn_position: Vector2) -> bool:
	if _enemy_count >= _enemy_positions.size():
		return false
	var enemy := _enemy_data(kind)
	_pool_borrow_buffer.clear()
	var borrow_status := int(_enemy_pool.call("borrow", _pool_borrow_buffer))
	if borrow_status == ObjectPool.Status.POOL_EXHAUSTED:
		dropped_enemy_spawns += 1
		return kind != ENEMY_BOSS
	if borrow_status != ObjectPool.Status.OK:
		return false
	var borrow_id := int(_pool_borrow_buffer.borrow_id)
	var identity = _enemy_pool.call("node_for", borrow_id)
	_spatial_handle_buffer.handle_id = 0
	var insert_status := int(_spatial_grid.call("insert_into", identity, SpatialGrid.TYPE_ENEMY, spawn_position, _spatial_handle_buffer))
	if insert_status != SpatialGrid.Status.OK:
		_enemy_pool.call("release", borrow_id)
		if insert_status == SpatialGrid.Status.CAPACITY_EXCEEDED:
			dropped_enemy_spawns += 1
			return kind != ENEMY_BOSS
		return false
	var grid_handle := int(_spatial_handle_buffer.handle_id)
	if _enemy_pool.call("bind_spatial_handle", borrow_id, grid_handle) != ObjectPool.Status.OK:
		_spatial_grid.call("remove", grid_handle)
		_enemy_pool.call("release", borrow_id)
		return false
	_enemy_positions[_enemy_count] = spawn_position
	_enemy_hp[_enemy_count] = float(enemy["hp"])
	_enemy_kind[_enemy_count] = kind
	_enemy_borrow_ids[_enemy_count] = borrow_id
	_enemy_grid_handles[_enemy_count] = grid_handle
	if kind == ENEMY_BOSS:
		_boss_handle = grid_handle
		boss_spawn_count += 1
	_enemy_count += 1
	return true

func _update_attacks(delta: float, player: ProductionPlayerController) -> bool:
	_attack_left -= delta
	if _attack_left > 0.0 or _enemy_count == 0:
		return true
	_attack_left += player.attack_interval
	var max_radius := sqrt(_projectile_despawn_radius_squared)
	if _spatial_grid.call("query_nearest_into", player.position, max_radius, SpatialGrid.TYPE_ENEMY, _nearest_enemy_buffer) != SpatialGrid.Status.OK:
		return false
	if not _nearest_enemy_buffer.has_handle:
		return true
	var nearest_index := _enemy_index_for_grid_handle(int(_nearest_enemy_buffer.handle_id))
	if nearest_index < 0:
		return false
	var nearest_position := _enemy_positions[nearest_index]
	var base_direction := player.position.direction_to(nearest_position)
	if _weapon_pending_count != 0:
		return false
	_weapon_due_tick = _simulation_tick + 1
	for sword_index in player.sword_count:
		if _weapon_pending_count >= WEAPON_PENDING_CAPACITY:
			dropped_projectiles += player.sword_count - sword_index
			return true
		var spread := (float(sword_index) - float(player.sword_count - 1) * 0.5) * 0.14
		_weapon_pending_positions[_weapon_pending_count] = player.position
		_weapon_pending_velocities[_weapon_pending_count] = base_direction.rotated(spread) * _projectile_speed
		_weapon_pending_damage[_weapon_pending_count] = player.sword_damage
		_weapon_pending_count += 1
	return true

func _update_projectiles(delta: float, player: ProductionPlayerController) -> bool:
	projectile_candidates_this_tick = 0
	# Publish matching SoA positions, including newly spawned pending identities.
	# Keep this at the existing pre-enemy-movement collision phase.
	var maximum_enemy_radius := 0.0
	if _projectile_count > 0:
		for index in _enemy_count:
			maximum_enemy_radius = maxf(maximum_enemy_radius, float(_enemy_data(_enemy_kind[index])["radius"]))
			if _spatial_grid.stage_position(_enemy_grid_handles[index], _enemy_positions[index]) != SpatialGrid.Status.OK:
				return false
		if _spatial_grid.sync() != SpatialGrid.Status.OK:
			return false
	var projectile_index := _projectile_count - 1
	while projectile_index >= 0:
		var projectile_origin := _projectile_positions[projectile_index]
		var proposed := projectile_origin + _projectile_velocities[projectile_index] * delta
		if not proposed.is_finite() or not projectile_origin.is_finite():
			return false
		var retained := CombatGeometry.retention_fraction(projectile_origin, proposed, player.position, _projectile_despawn_radius_squared)
		if retained < 0.0:
			_remove_projectile(projectile_index)
			projectile_index -= 1
			continue
		var projectile_position := projectile_origin.lerp(proposed, retained)
		_projectile_positions[projectile_index] = projectile_position
		var hit_index := -1
		var first_fraction := INF
		var center := projectile_origin.lerp(projectile_position, 0.5)
		# Enclose the entire segment plus the largest collision footprint.
		# Padding is conservative for float32 vector midpoint rounding only.
		var query_radius := projectile_origin.distance_to(projectile_position) * 0.5 + _projectile_radius + maximum_enemy_radius + 0.25
		if _spatial_grid.query_circle_into(center, query_radius, SpatialGrid.TYPE_ENEMY, _projectile_candidates) != SpatialGrid.Status.OK:
			return false
		projectile_candidates_this_tick += _projectile_candidates.count
		for candidate in _projectile_candidates.count:
			var enemy_index := _enemy_index_for_grid_handle(_projectile_candidates.handle_ids[candidate])
			if enemy_index < 0:
				return false
			var enemy := _enemy_data(_enemy_kind[enemy_index])
			var collision_radius := _projectile_radius + float(enemy["radius"])
			var fraction := CombatGeometry.sweep_fraction(projectile_origin, projectile_position, _enemy_positions[enemy_index], collision_radius)
			if fraction >= 0.0 and (fraction < first_fraction or (fraction == first_fraction and (hit_index < 0 or _enemy_grid_handles[enemy_index] < _enemy_grid_handles[hit_index]))):
				hit_index = enemy_index
				first_fraction = fraction
		if hit_index >= 0:
			var before_hp := float(_enemy_hp[hit_index])
			_enemy_hp[hit_index] -= _projectile_damage[projectile_index]
			if _enemy_kind[hit_index] == ENEMY_BOSS:
				_damage_receipt += 1
				boss_combat.fsm.apply_hp_receipt(_damage_receipt, before_hp, maxf(0.0, _enemy_hp[hit_index]))
			_remove_projectile(projectile_index)
			if _enemy_hp[hit_index] <= 0:
				if not _defeat_enemy(hit_index):
					return false
		elif retained < 1.0:
			_remove_projectile(projectile_index)
		projectile_index -= 1
	return true

func _update_enemies(delta: float, player: ProductionPlayerController) -> bool:
	for index in range(_enemy_count - 1, -1, -1):
		var enemy: Dictionary = _enemy_data(_enemy_kind[index])
		if _enemy_kind[index] == ENEMY_BOSS:
			_update_boss(index, player)
			if _spatial_grid.call("stage_position", _enemy_grid_handles[index], _enemy_positions[index]) != SpatialGrid.Status.OK:
				return false
			continue
		if _enemy_positions[index].distance_squared_to(player.position) > 2200.0 * 2200.0:
			if not _remove_enemy(index):
				return false
			continue
		_enemy_positions[index] += _enemy_positions[index].direction_to(player.position) * float(enemy["speed"]) * delta
		if _spatial_grid.call("stage_position", _enemy_grid_handles[index], _enemy_positions[index]) != SpatialGrid.Status.OK:
			return false
		var collision_radius := player.radius + float(enemy["radius"])
		if _enemy_positions[index].distance_squared_to(player.position) <= collision_radius * collision_radius:
			_player_damage.add(float(enemy["contact_damage"]), true)
	return true

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

func _defeat_enemy(index: int) -> bool:
	var defeated_position := _enemy_positions[index]
	var defeated_kind := int(_enemy_kind[index])
	if not _remove_enemy(index):
		return false
	kills_gained_this_tick += 1
	if defeated_kind == ENEMY_BOSS:
		boss_defeated = true
		_hostile_count = 0
		_ring_pending = false
		_summon_pending = false
		return true
	if defeated_kind == ENEMY_SUMMON:
		return true
	if _pickup_count >= _pickup_positions.size():
		dropped_pickups += 1
		return true
	_pickup_positions[_pickup_count] = defeated_position
	_pickup_count += 1
	return true

func _remove_enemy(index: int) -> bool:
	if index < 0 or index >= _enemy_count:
		return false
	var grid_handle := int(_enemy_grid_handles[index])
	var borrow_id := int(_enemy_borrow_ids[index])
	if _spatial_grid.call("remove", grid_handle) != SpatialGrid.Status.OK:
		return false
	if _enemy_pool.call("unbind_spatial_handle", borrow_id, grid_handle) != ObjectPool.Status.OK:
		return false
	if _enemy_pool.call("release", borrow_id) != ObjectPool.Status.OK:
		return false
	_enemy_count -= 1
	if index != _enemy_count:
		_enemy_positions[index] = _enemy_positions[_enemy_count]
		_enemy_hp[index] = _enemy_hp[_enemy_count]
		_enemy_kind[index] = _enemy_kind[_enemy_count]
		_enemy_borrow_ids[index] = _enemy_borrow_ids[_enemy_count]
		_enemy_grid_handles[index] = _enemy_grid_handles[_enemy_count]
	_enemy_borrow_ids[_enemy_count] = 0
	_enemy_grid_handles[_enemy_count] = 0
	return true

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
	if kind == ENEMY_BOSS:
		return _boss
	return _wolf if kind == ENEMY_WOLF else _beetle

func boss_hp() -> float:
	var index := _enemy_index_for_grid_handle(_boss_handle)
	return float(_enemy_hp[index]) if index >= 0 else 0.0

static func valid_schedule(config: Dictionary) -> bool:
	var rows: Array = config.get("waves", [])
	if rows.is_empty():
		return false
	var previous := 0.0
	for row: Dictionary in rows:
		var end := float(row.get("until_seconds", -1))
		var interval := float(row.get("spawn_interval", -1))
		var wolves := float(row.get("wolf_probability", -1))
		if not is_finite(end) or end <= previous or not is_finite(interval) or interval < 1.0 / 60.0 or not is_finite(wolves) or wolves < 0 or wolves > 1:
			return false
		previous = end
	if bool(config["run"].get("boss_enabled", false)):
		var duration := float(config["run"].get("duration_seconds", 0))
		return previous == 720.0 and is_finite(duration) and duration > 720.0
	return true

func _update_boss_schedule(elapsed: float, player_position: Vector2) -> bool:
	if not boss_enabled or boss_defeated:
		return true
	if boss_spawn_count == 0 and elapsed >= 720.0:
		var offset := Vector2(get_viewport_rect().size.x * 0.5 + float(_boss["radius"]) + 65.0, 0.0)
		if not _spawn_enemy(ENEMY_BOSS, player_position + offset):
			return false
	if _ring_pending:
		if _hostile_count != 0 or _ring_source != _boss_handle or _enemy_index_for_grid_handle(_ring_source) < 0 or _ring_generation != boss_combat.generation:
			return false
		var directions: PackedVector2Array = boss_combat.fsm.ring_directions(_ring_generation)
		for i in 8:
			_hostile_positions[i] = _ring_origin
			_hostile_velocities[i] = directions[i] * 360.0
			_hostile_life[i] = 120
		_hostile_count = 8
		_ring_pending = false
	if _summon_pending:
		_summon_pending = false
		var index := _enemy_index_for_grid_handle(_summon_source)
		var source_valid: bool = index >= 0 and _summon_source == _boss_handle and _summon_generation == boss_combat.generation
		var origin := _enemy_positions[index] if source_valid else Vector2.ZERO
		var room := _enemy_positions.size() - _enemy_count if source_valid else 0
		_summon_candidates.sample_summons(_rng, origin, player_position, 100.0, float(_beetle["radius"]), _world_half_extent, room, boss_combat.fsm.fog_anchor, boss_combat.fsm.fog_safe_radius() * 60.0)
		if _summon_candidates.valid:
			var before_count := _enemy_count
			for child in 2:
				if not _spawn_enemy(ENEMY_SUMMON, _summon_candidates.positions[child]) or _enemy_count != before_count + child + 1:
					while _enemy_count > before_count:
						if not _remove_enemy(_enemy_count - 1):
							return false
					return false
	return true

func _update_boss(index: int, player: ProductionPlayerController) -> void:
	var origin := _enemy_positions[index]
	boss_combat.advance(origin, player.position)
	_enemy_positions[index] += boss_combat.movement
	if boss_combat.bite_active:
		_boss_tick_hazards.append({"kind": "bite", "warning": false, "origin": origin, "end": _enemy_positions[index], "radius": float(_boss["radius"])})
	if boss_combat.fan_release:
		_boss_tick_hazards.append({"kind": "fan", "warning": false, "origin": origin, "axis": boss_combat.axis})
	if boss_combat.bite_active and not boss_combat.bite_hit:
		var closest := Geometry2D.get_closest_point_to_segment(player.position, origin, _enemy_positions[index])
		if closest.distance_to(player.position) <= float(_boss["radius"]) + player.radius:
			_player_damage.add(float(_boss["contact_damage"]), false, "首领扑咬")
			boss_combat.bite_hit = true
	if boss_combat.fan_release and boss_combat.fan_hits(origin, player.position, player.radius):
		_player_damage.add(float(_boss["contact_damage"]) * 0.7, false, "首领扇毒")
	if boss_combat.ring_release:
		_ring_pending = true
		_ring_source = _boss_handle
		_ring_origin = origin
		_ring_generation = boss_combat.generation
	if boss_combat.summon_release:
		_summon_pending = true
		_summon_source = _boss_handle
		_summon_generation = boss_combat.generation
	if boss_combat.fsm.phase_code == 2 and boss_combat.fsm.fog_elapsed_ticks > 0 and boss_combat.fsm.fog_elapsed_ticks % 60 == 0:
		if player.position.distance_to(boss_combat.fsm.fog_anchor) + player.radius > boss_combat.fsm.fog_safe_radius() * 60.0:
			_player_damage.add(float(_boss["contact_damage"]) * 0.2, false, "毒雾：返回安全圈")

func _update_hostile_projectiles(player: ProductionPlayerController) -> void:
	var i := _hostile_count - 1
	while i >= 0:
		var origin := _hostile_positions[i]
		_hostile_positions[i] += _hostile_velocities[i] / 60.0
		_hostile_life[i] -= 1
		var closest := Geometry2D.get_closest_point_to_segment(player.position, origin, _hostile_positions[i])
		var hit := closest.distance_to(player.position) <= player.radius + 10.8
		if hit:
			_player_damage.add(float(_boss["contact_damage"]) * 0.25, false, "首领毒弹")
		if hit or _hostile_life[i] <= 0:
			_hostile_count -= 1
			_hostile_positions[i] = _hostile_positions[_hostile_count]
			_hostile_velocities[i] = _hostile_velocities[_hostile_count]
			_hostile_life[i] = _hostile_life[_hostile_count]
		i -= 1

func _enemy_index_for_grid_handle(handle_id: int) -> int:
	for index in _enemy_count:
		if _enemy_grid_handles[index] == handle_id:
			return index
	return -1

func _make_enemy_identity() -> Node:
	var identity := Node.new()
	identity.process_mode = Node.PROCESS_MODE_DISABLED
	return identity

func _wave_index(elapsed: float) -> int:
	for index in _waves.size():
		if elapsed < float((_waves[index] as Dictionary)["until_seconds"]):
			return index
	return _waves.size() - 1

func _draw() -> void:
	var draw_started := Time.get_ticks_usec() if measure_draw_cpu else 0
	draw_objects_submitted = 0
	draw_objects_culled = 0
	# Convert the viewport through the actual camera/canvas transform, not player position.
	var draw_view := (get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()).grow(1.0)
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
		if not _keep_draw_object(draw_view, _pickup_positions[index], _xp_radius + 6.0):
			continue
		draw_circle(_pickup_positions[index], _xp_radius + 5.0, Color(0.20, 0.95, 0.78, 0.18))
		draw_circle(_pickup_positions[index], _xp_radius, Color("55edbe"))
	if boss_spawn_count > 0 and not boss_defeated:
		var boss_index := _enemy_index_for_grid_handle(_boss_handle)
		if boss_combat.fsm.phase_code == 2 or boss_combat.fsm.state == boss_combat.FSM.State.PHASE_SHIFT:
			draw_arc(boss_combat.fsm.fog_anchor, boss_combat.fsm.fog_safe_radius() * 60.0, 0, TAU, 96, Color("cc88ee"), 5.0)
		if boss_index >= 0 and boss_combat.action == boss_combat.Action.TELEGRAPH:
			var origin := _enemy_positions[boss_index]
			if boss_combat.slot == 0:
				draw_line(origin, origin + boss_combat.axis * 324.0, Color(1, 0.5, 0.1, 0.3), 80.0)
			elif boss_combat.slot == 1:
				var angle: float = boss_combat.axis.angle()
				draw_arc(origin, 420.0, angle - deg_to_rad(35), angle + deg_to_rad(35), 32, Color.ORANGE, 5.0)
				for side in [-1, 1]:
					draw_line(origin, origin + boss_combat.axis.rotated(side * deg_to_rad(35)) * 420.0, Color.ORANGE, 3.0)
			elif boss_combat.slot == 2:
				var rays: PackedVector2Array = boss_combat.fsm.ring_directions(boss_combat.generation)
				for ray in rays:
					draw_line(origin, origin + ray * 160.0, Color.YELLOW, 3.0)
			else:
				for offset in [Vector2(0, 120), Vector2(0, -120)]:
					draw_arc(origin + offset, 24.0, 0, TAU, 24, Color.YELLOW, 4.0)
	for i in _hostile_count:
		if not _keep_draw_object(draw_view, _hostile_positions[i], 11.8):
			continue
		draw_circle(_hostile_positions[i], 10.8, Color("dd88ff"))
	for index in _enemy_count:
		var enemy: Dictionary = _enemy_data(_enemy_kind[index])
		var position_value := _enemy_positions[index]
		var radius := float(enemy["radius"])
		if not _keep_draw_object(draw_view, position_value, radius + 10.0):
			continue
		if _enemy_kind[index] == ENEMY_BOSS:
			draw_circle(position_value, radius, Color("77bb44"))
			draw_arc(position_value, radius + 6.0, 0, TAU * maxf(0.0, _enemy_hp[index]) / float(_boss["hp"]), 48, Color.YELLOW, 5.0)
		elif _enemy_kind[index] == ENEMY_WOLF:
			draw_line(position_value + Vector2(0.0, -radius), position_value + Vector2(radius, 0.0), Color("e17a45"), 9.0)
			draw_line(position_value + Vector2(radius, 0.0), position_value + Vector2(0.0, radius), Color("e17a45"), 9.0)
			draw_line(position_value + Vector2(0.0, radius), position_value + Vector2(-radius, 0.0), Color("e17a45"), 9.0)
			draw_line(position_value + Vector2(-radius, 0.0), position_value + Vector2(0.0, -radius), Color("e17a45"), 9.0)
		else:
			draw_circle(position_value, radius + 4.0, Color(0.0, 0.0, 0.0, 0.3))
			draw_circle(position_value, radius, Color("a93d49"))
	for index in _projectile_count:
		if not _keep_draw_object(draw_view, _projectile_positions[index], maxf(_projectile_radius + 1.0, 21.0)):
			continue
		var velocity := _projectile_velocities[index]
		var direction := velocity.normalized()
		draw_line(_projectile_positions[index] - direction * 16.0, _projectile_positions[index] + direction * 12.0, Color("d6f5ff"), 7.0)
		draw_circle(_projectile_positions[index], _projectile_radius, Color("80d9ef"))
	if measure_draw_cpu:
		last_draw_cpu_usec = Time.get_ticks_usec() - draw_started
		draw_measurement_count += 1
