class_name SteamBattleSnapshot
extends RefCounted
## ADR-0006 recovery adapter for the existing single-stage runtime ONLY.
## No Mission/SkillDraft/Preparation owners are implied by this profile.
const Codec = preload("res://src/persistence/steam_canonical_codec.gd")
const Types = preload("res://src/persistence/steam_wire_types.gd")
const PROFILE := "LEGACY_STAGE_PC_V1"
const SCOPE = {"completed_active_ticks": "u63", "_tick_accumulator": "f64", "level": "u63", "xp": "u63", "kills": "u63", "first_upgrade_time": "f64", "pending_upgrade": "bool", "smoke_mode": "bool"}
const PLAYER = {"position": "vec2", "max_hp": "f64", "hp": "f64", "move_speed": "f64", "maximum_move_speed": "f64", "_initial_longchun_charges": "u63", "radius": "f64", "pickup_radius": "f64", "contact_cooldown": "f64", "attack_interval": "f64", "minimum_attack_interval": "f64", "sword_count": "u63", "sword_damage": "f64", "invulnerability_left": "f64", "longchun_charge_count": "u63", "longchun_threshold_ratio": "f64", "longchun_recovery_ratio": "f64", "longchun_trigger_count": "u63", "damage_event_count": "u63", "movement_consume_count": "u63"}
const STAGE = {"_simulation_tick": "u63", "_spawn_left": "f64", "_attack_left": "f64", "_spawn_viewport_size": "vec2", "_snapshot_next_entity_id": "u63", "_damage_receipt": "u63", "boss_spawn_count": "u63", "boss_defeated": "bool", "_ring_pending": "bool", "_ring_origin": "vec2", "_ring_generation": "u63", "_summon_pending": "bool", "_summon_generation": "u63", "dropped_enemy_spawns": "u63", "dropped_projectiles": "u63", "dropped_pickups": "u63"}
const BOSS = {"action": "u63", "slot": "u63", "ticks": "u63", "generation": "u63", "segment": "u63", "axis": "vec2", "bite_hit": "bool"}
const FSM = {"state": "u63", "state_ticks": "u63", "active_age_ticks": "u63", "phase_code": "u63", "phase_transition_pending": "bool", "phase_transition_generation": "u63", "fog_anchor": "vec2", "fog_elapsed_ticks": "u63", "fog_generation": "u63", "_resolved_max_hp": "f64", "_last_damage_receipt_id": "u63", "_schedule_claimed": "bool"}
const ENEMY = {"entity_id": "u63", "position": "vec2", "hp": "f32", "kind": "u63"}
const PROJECTILE = {"position": "vec2", "velocity": "vec2", "damage": "f32"}
const HOSTILE = {"position": "vec2", "velocity": "vec2", "life": "u63"}

## Returns the closed typed schema with array bounds from the actual config.
static func shape(config: Dictionary) -> Dictionary:
	var cap: Dictionary = config.capacities
	var friendly := int(cap.projectiles) - (8 if config.run.get("boss_enabled", false) else 0)
	return {"profile": "string", "engine": "string", "config_hash": "string", "scope": SCOPE, "player": PLAYER, "stage": STAGE, "boss": BOSS, "fsm": FSM,
		"rng": {"seed": "bits64", "state": "bits64"}, "references": {"boss": "u63", "ring": "u63", "summon": "u63"},
		"enemies": {"$array": ENEMY, "$max": int(cap.enemies)},
		"projectiles": {"$array": PROJECTILE, "$max": friendly},
		"pickups": {"$array": "vec2", "$max": int(cap.pickups)},
		"hostile": {"$array": HOSTILE, "$max": 8 if config.run.get("boss_enabled", false) else 0},
		"weapon": {"due_tick": "u63", "rows": {"$array": PROJECTILE, "$max": 32}}}

## Capture is synchronous at a fully consumed paused tick; output has no aliases.
static func capture(scope: ProductionBattleScope, limits: Dictionary) -> Dictionary:
	if scope.state != scope.State.PAUSED or not scope._snapshot_barrier_ready or scope.terminal_pending \
		or scope.movement_context.open or scope.stage._closed:
		return {"status": "WRONG_STATE"}
	var stage := scope.stage
	if scope.completed_active_ticks != stage._simulation_tick or (scope.completed_active_ticks > 0 and not stage._player_damage._committed):
		return {"status": "WRONG_BARRIER"}
	var value := {"profile": PROFILE, "engine": engine_identity(), "config_hash": config_hash(scope._config),
		"scope": _read(scope, SCOPE), "player": _read(scope.player, PLAYER), "stage": _read(stage, STAGE),
		"boss": _read(stage.boss_combat, BOSS), "fsm": _read(stage.boss_combat.fsm, FSM),
		"rng": {"seed": stage._rng.seed, "state": stage._rng.state},
		"references": {"boss": _logical(stage, stage._boss_handle), "ring": _logical(stage, stage._ring_source) if stage._ring_pending else 0, "summon": _logical(stage, stage._summon_source) if stage._summon_pending else 0},
		"enemies": [], "projectiles": [], "pickups": [], "hostile": [],
		"weapon": {"due_tick": stage._weapon_due_tick if stage._weapon_pending_count > 0 else 0, "rows": []}}
	for i: int in range(stage._enemy_count):
		value.enemies.append({"entity_id": stage._snapshot_entity_ids[i], "position": stage._enemy_positions[i], "hp": stage._enemy_hp[i], "kind": stage._enemy_kind[i]})
	for i: int in range(stage._projectile_count):
		value.projectiles.append({"position": stage._projectile_positions[i], "velocity": stage._projectile_velocities[i], "damage": stage._projectile_damage[i]})
	for i: int in range(stage._weapon_pending_count):
		value.weapon.rows.append({"position": stage._weapon_pending_positions[i], "velocity": stage._weapon_pending_velocities[i], "damage": stage._weapon_pending_damage[i]})
	for i: int in range(stage._pickup_count):
		value.pickups.append(stage._pickup_positions[i])
	for i: int in range(stage._hostile_count):
		value.hostile.append({"position": stage._hostile_positions[i], "velocity": stage._hostile_velocities[i], "life": stage._hostile_life[i]})
	var converted := Types.transform(value, shape(scope._config), true)
	if converted.status != "OK":
		return converted
	var validated := validate(converted.value, scope._config, limits)
	if validated.status != "OK":
		return validated
	return {"status": "OK", "value": converted.value}

## Validates all fields/references before any object allocation or mutation.
static func validate(wire: Variant, config: Dictionary, limits: Dictionary) -> Dictionary:
	var encoded := Codec.encode(wire, limits)
	if encoded.status != "OK":
		return encoded
	var result := Types.transform(wire, shape(config), false)
	if result.status != "OK":
		return result
	var v: Dictionary = result.value
	if v.profile != PROFILE or v.engine != engine_identity():
		return {"status": "UNSUPPORTED_SCHEMA"}
	if v.config_hash != config_hash(config):
		return {"status": "CONTENT_MISMATCH"}
	var s: Dictionary = v.stage
	var b: Dictionary = v.scope
	var p: Dictionary = v.player
	if b.completed_active_ticks != s._simulation_tick or b.completed_active_ticks >= int(float(config.run.duration_seconds) * 60.0) \
		or b.level < 1 or b.level > b.completed_active_ticks + 1 or b._tick_accumulator < -0.000000001 \
		or b.first_upgrade_time < -1.0 or b.first_upgrade_time > float(b.completed_active_ticks) / 60.0:
		return {"status": "INVALID", "path": "scope"}
	if p.hp <= 0 or (not b.smoke_mode and p.hp > p.max_hp) or p.max_hp <= 0 or p.sword_count < 1 \
		or p.move_speed <= 0 or p.move_speed > p.maximum_move_speed or p.radius <= 0 or p.pickup_radius <= 0 \
		or p.attack_interval < p.minimum_attack_interval or p.minimum_attack_interval <= 0 or p.sword_damage <= 0 \
		or p.invulnerability_left < 0 or p.contact_cooldown < 0 or p.longchun_charge_count > p._initial_longchun_charges \
		or p.longchun_trigger_count != p._initial_longchun_charges - p.longchun_charge_count \
		or p.longchun_threshold_ratio < 0 or p.longchun_threshold_ratio > 1 or p.longchun_recovery_ratio < 0 or p.longchun_recovery_ratio > 1:
		return {"status": "INVALID", "path": "player"}
	if s._spawn_viewport_size.x <= 0 or s._spawn_viewport_size.y <= 0 or s.boss_defeated or s.boss_spawn_count > 1:
		return {"status": "INVALID", "path": "stage"}
	var ids := {}
	var boss_id := 0
	var extent := float(config.combat.world_half_extent)
	for row: Dictionary in v.enemies:
		if row.entity_id < 1 or ids.has(row.entity_id) or row.entity_id >= s._snapshot_next_entity_id \
			or row.kind > 3 or row.hp <= 0 or absf(row.position.x) > extent or absf(row.position.y) > extent:
			return {"status": "INVALID", "path": "enemies"}
		ids[row.entity_id] = true
		if row.kind == 2:
			if boss_id != 0:
				return {"status": "INVALID", "path": "duplicate_boss"}
			boss_id = row.entity_id
	if v.references.boss != boss_id or s.boss_spawn_count != (1 if boss_id > 0 else 0):
		return {"status": "INVALID", "path": "boss_identity"}
	for kind: String in ["ring", "summon"]:
		if s["_" + kind + "_pending"]:
			if boss_id == 0 or v.references[kind] != boss_id or s["_" + kind + "_generation"] != v.boss.generation:
				return {"status": "INVALID", "path": kind}
		elif v.references[kind] != 0:
			return {"status": "INVALID", "path": kind}
	if s._ring_pending and not v.hostile.is_empty():
		return {"status": "INVALID", "path": "ring_hostile_overlap"}
	if v.boss.action > 3 or v.boss.slot > 3 or v.boss.segment > 1 or v.fsm.state > 4 or v.fsm.phase_code not in [1, 2] \
		or v.fsm._last_damage_receipt_id > s._damage_receipt:
		return {"status": "INVALID", "path": "boss_fsm"}
	if bool(config.run.get("boss_enabled", false)):
		if v.fsm._resolved_max_hp != float(config.enemies.boss.hp) or v.fsm.state == 0:
			return {"status": "INVALID", "path": "boss_config"}
	elif boss_id > 0 or v.fsm.state != 0 or not v.hostile.is_empty() or s._ring_pending or s._summon_pending:
		return {"status": "INVALID", "path": "disabled_boss"}
	if (v.weapon.rows.is_empty() and v.weapon.due_tick != 0) or (not v.weapon.rows.is_empty() and v.weapon.due_tick != s._simulation_tick + 1):
		return {"status": "INVALID", "path": "weapon_tick"}
	for row: Dictionary in v.projectiles + v.weapon.rows:
		if row.damage <= 0:
			return {"status": "INVALID", "path": "projectile_damage"}
	for row: Dictionary in v.hostile:
		if row.life < 1 or row.life > 120:
			return {"status": "INVALID", "path": "hostile_life"}
	if not _causal_state(v, config):
		return {"status": "INVALID", "path": "causal_state"}
	return result

## Restores only into a fresh CREATED scope owned by the caller's hidden build.
## Caller must discard this scope on failure; no old save or public battle mutates.
static func restore(scope: ProductionBattleScope, wire: Variant, limits: Dictionary) -> Dictionary:
	if scope.state != scope.State.CREATED or scope.completed_active_ticks != 0 or scope.stage._enemy_count != 0 \
		or scope.stage._simulation_tick != 0 or scope.stage._closed:
		return {"status": "WRONG_STATE"}
	var result := validate(wire, scope._config, limits)
	if result.status != "OK":
		return result
	var v: Dictionary = result.value
	var stage := scope.stage
	var sorted: Array = v.enemies.duplicate(true)
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.entity_id < b.entity_id)
	var bindings := {}
	for row: Dictionary in sorted:
		if not stage._spawn_enemy(row.kind, row.position):
			scope.teardown()
			return {"status": "RESTORE_FAILED"}
		var i := stage._enemy_count - 1
		bindings[row.entity_id] = [stage._enemy_borrow_ids[i], stage._enemy_grid_handles[i]]
	# Preserve SoA iteration order separately from logical allocation/tie order.
	for i: int in range(v.enemies.size()):
		var row: Dictionary = v.enemies[i]
		stage._snapshot_entity_ids[i] = row.entity_id
		stage._enemy_positions[i] = row.position
		stage._enemy_hp[i] = row.hp
		stage._enemy_kind[i] = row.kind
		stage._enemy_borrow_ids[i] = bindings[row.entity_id][0]
		stage._enemy_grid_handles[i] = bindings[row.entity_id][1]
	_write(scope, v.scope)
	_write(scope.player, v.player)
	_write(stage, v.stage)
	_write(stage.boss_combat, v.boss)
	_write(stage.boss_combat.fsm, v.fsm)
	stage._rng.seed = v.rng.seed
	stage._rng.state = v.rng.state
	stage._boss_handle = 0 if v.references.boss == 0 else bindings[v.references.boss][1]
	stage._ring_source = 0 if v.references.ring == 0 else bindings[v.references.ring][1]
	stage._summon_source = 0 if v.references.summon == 0 else bindings[v.references.summon][1]
	stage._projectile_count = v.projectiles.size()
	for i: int in range(stage._projectile_count):
		stage._projectile_positions[i] = v.projectiles[i].position
		stage._projectile_velocities[i] = v.projectiles[i].velocity
		stage._projectile_damage[i] = v.projectiles[i].damage
	stage._weapon_pending_count = v.weapon.rows.size()
	stage._weapon_due_tick = v.weapon.due_tick
	for i: int in range(stage._weapon_pending_count):
		stage._weapon_pending_positions[i] = v.weapon.rows[i].position
		stage._weapon_pending_velocities[i] = v.weapon.rows[i].velocity
		stage._weapon_pending_damage[i] = v.weapon.rows[i].damage
	stage._pickup_count = v.pickups.size()
	for i: int in range(stage._pickup_count):
		stage._pickup_positions[i] = v.pickups[i]
	stage._hostile_count = v.hostile.size()
	for i: int in range(stage._hostile_count):
		stage._hostile_positions[i] = v.hostile[i].position
		stage._hostile_velocities[i] = v.hostile[i].velocity
		stage._hostile_life[i] = v.hostile[i].life
	if stage._spatial_grid.sync() != stage.SpatialGrid.Status.OK:
		scope.teardown()
		return {"status": "RESTORE_FAILED"}
	stage._focus_position = scope.player.position
	stage._player_damage._committed = true
	scope.elapsed_time = float(scope.completed_active_ticks) / 60.0
	scope._snapshot_barrier_ready = true
	# Fresh process-owned input generation/leases; no saved physical held state.
	if not scope.activate() or not scope.lock_for_pause(scope.movement_context.tick):
		scope.teardown()
		return {"status": "RESTORE_FAILED"}
	stage._publish_hazards() # Rebuild current exposure/warnings in the fresh Stage epoch.
	stage.queue_redraw()
	scope.player.queue_redraw()
	return {"status": "OK"}

## Pins RNG compatibility to the exact engine commit, not only its marketing version.
static func engine_identity() -> String:
	var info := Engine.get_version_info()
	return str(info.string) + ":" + str(info.hash)

## Exact adapter config identity includes numeric types and build-resolved values.
## This is not the future ConfigDataSystem production content hash algorithm.
static func config_hash(config: Dictionary) -> String:
	return var_to_bytes(config).hex_encode().sha256_text()

static func _read(object: Object, fields: Dictionary) -> Dictionary:
	var result := {}
	for key: String in fields:
		result[key] = object.get(key)
	return result

static func _write(object: Object, values: Dictionary) -> void:
	for key: String in values:
		object.set(key, values[key])

static func _logical(stage: ProductionStageRuntime, handle: int) -> int:
	if handle == 0:
		return 0
	var index := stage._enemy_index_for_grid_handle(handle)
	return 0 if index < 0 else stage._snapshot_entity_ids[index]

# Profile-specific causal validation, separate from typed wire admission.
static func _causal_state(v: Dictionary, config: Dictionary) -> bool:
	var b: Dictionary = v.scope
	var p: Dictionary = v.player
	var s: Dictionary = v.stage
	var f: Dictionary = v.fsm
	var ticks: int = b.completed_active_ticks
	var extent: float = config.combat.world_half_extent
	if absf(p.position.x) > extent or absf(p.position.y) > extent or s._snapshot_next_entity_id < 1 \
		or s._snapshot_next_entity_id > ticks * 3 + 2 or s._damage_receipt > ticks * int(config.capacities.projectiles) \
		or v.boss.generation > ticks or f.active_age_ticks > ticks or f.state_ticks > ticks \
		or f.fog_elapsed_ticks > ticks or f.fog_generation > ticks or f.phase_transition_generation > 1:
		return false
	if (b.level == 1 and (b.pending_upgrade or b.first_upgrade_time != -1.0)) \
		or (b.level > 1 and b.first_upgrade_time <= 0.0) or (b.smoke_mode and b.pending_upgrade):
		return false
	if not _valid_build(v, config):
		return false
	if not _bounded_motion(v, config):
		return false
	if v.references.boss == 0:
		if config.run.get("boss_enabled", false) and ticks >= 43200:
			return false
		if v.boss != {"action": 0, "slot": 0, "ticks": 0, "generation": 0, "segment": 0, "axis": Vector2.RIGHT, "bite_hit": false}:
			return false
		if f.state != (1 if config.run.get("boss_enabled", false) else 0) or f.state_ticks != 0 or f.active_age_ticks != 0 \
			or f.phase_code != 1 or f.phase_transition_pending or f.fog_elapsed_ticks != 0 or s._damage_receipt != 0:
			return false
	else:
		if ticks < 43200 or f.state == 0 or (f.state in [1, 2] and f.phase_code != 1) \
			or (f.state == 4 and f.phase_code != 2) or v.boss.ticks > 60 or not is_equal_approx(v.boss.axis.length(), 1.0):
			return false
		if (s._ring_pending and (v.boss.slot != 2 or v.boss.action != 3 or v.boss.ticks != 0)) \
			or (s._summon_pending and (v.boss.slot != 3 or v.boss.action != 3 or v.boss.ticks != 0)):
			return false
		if f.phase_code == 1 and (v.boss.slot > 2 or v.boss.segment > 0):
			return false
	return true

static func _valid_build(v: Dictionary, config: Dictionary) -> bool:
	var p: Dictionary = v.player
	var b: Dictionary = v.scope
	var base: Dictionary = config.player
	var projection: Dictionary = config.get("progression_projection", {})
	if v.weapon.rows.size() > mini(32, int(p.sword_count)):
		return false
	var expected_hp := float(base.max_hp) * (1.0 + float(projection.get("max_hp_bonus_ratio", 0.0)))
	var expected_damage := float(base.sword_damage) * (1.0 + float(projection.get("attack_bonus_ratio", 0.0)))
	var charges := int(projection.get("longchun_charge_count", 0))
	if p.max_hp != expected_hp or p.sword_damage != expected_damage or p._initial_longchun_charges != charges \
		or p.radius != float(base.radius) or p.maximum_move_speed != float(base.maximum_speed) \
		or p.minimum_attack_interval != float(base.minimum_attack_interval) or p.contact_cooldown != float(base.contact_cooldown) \
		or p.longchun_threshold_ratio != float(projection.get("longchun_threshold_ratio", 0.30)) \
		or p.longchun_recovery_ratio != float(projection.get("longchun_recovery_ratio", 0.10)):
		return false
	var earned_upgrades: int = b.level - 1
	var applied: int = earned_upgrades - (1 if b.pending_upgrade else 0)
	var swords: int = p.sword_count - int(base.sword_count)
	if swords < 0 or swords > applied:
		return false
	# Each collected pickup is one XP and each ordinary kill creates at most one.
	var paid_xp: int = earned_upgrades * int(config.upgrades.xp_base) + earned_upgrades * (earned_upgrades - 1) / 2 * int(config.upgrades.xp_per_level)
	if b.kills > b.completed_active_ticks * int(config.capacities.enemies) or b.xp > b.kills or paid_xp > b.kills - b.xp:
		return false
	var attacks: Array[float] = [float(base.attack_interval)]
	var speeds: Array[float] = [float(base.speed)]
	var radii: Array[float] = [float(base.pickup_radius) * (1.0 + float(projection.get("pickup_bonus_ratio", 0.0)))]
	for i: int in range(applied - swords):
		attacks.append(maxf(float(base.minimum_attack_interval), attacks[-1] * float(config.upgrades.attack_interval_multiplier)))
		speeds.append(minf(float(base.maximum_speed), speeds[-1] * float(config.upgrades.movement_speed_multiplier)))
		radii.append(radii[-1] * float(config.upgrades.pickup_radius_multiplier))
	for attack_count: int in range(applied - swords + 1):
		var movement_count: int = applied - swords - attack_count
		if p.attack_interval == attacks[attack_count] and p.move_speed == speeds[movement_count] and p.pickup_radius == radii[movement_count]:
			return true
	return false

static func _bounded_motion(v: Dictionary, config: Dictionary) -> bool:
	var s: Dictionary = v.stage
	var p: Dictionary = v.player
	var elapsed := float(v.scope.completed_active_ticks) / 60.0
	var max_spawn := 0.2
	for wave: Dictionary in config.waves:
		max_spawn = maxf(max_spawn, float(wave.spawn_interval))
	if s._spawn_left > max_spawn + 0.000001 or s._spawn_left < -1.0 / 60.0 - 0.000001 \
		or s._attack_left > float(config.player.attack_interval) + 0.000001 or s._attack_left < -elapsed - 0.000001:
		return false
	var extent := float(config.combat.world_half_extent)
	var speed := float(config.combat.projectile_speed)
	var projectile_bound := extent + float(config.combat.projectile_despawn_radius) + speed / 60.0
	var reachable := float(config.player.maximum_speed) * elapsed + 0.01
	if absf(p.position.x) > reachable or absf(p.position.y) > reachable:
		return false
	# Freeze a spawn rectangle which can stay inside this profile's world even
	# under its maximum player travel; the current legacy profile starts at zero.
	var margin := float(config.player.maximum_speed) * float(config.run.duration_seconds) + 65.0
	for enemy: Dictionary in config.enemies.values():
		margin = maxf(margin, float(config.player.maximum_speed) * float(config.run.duration_seconds) + float(enemy.radius) + 65.0)
	if s._spawn_viewport_size.x * 0.5 + margin > extent or s._spawn_viewport_size.y * 0.5 + margin > extent:
		return false
	var damage := float(PackedFloat32Array([p.sword_damage])[0])
	for row: Dictionary in v.projectiles + v.weapon.rows:
		if not _box(row.position, projectile_bound) or absf(row.velocity.x) > speed * 1.00001 \
			or absf(row.velocity.y) > speed * 1.00001 or row.velocity.length() > speed * 1.00001 or row.damage != damage:
			return false
	for row: Dictionary in v.hostile:
		if not _box(row.position, extent + 720.0) or absf(row.velocity.x) > 360.01 or absf(row.velocity.y) > 360.01 or row.velocity.length() > 360.01:
			return false
	for pos: Vector2 in v.pickups:
		if not _box(pos, extent):
			return false
	return _box(s._ring_origin, extent) and _box(v.fsm.fog_anchor, extent)

static func _box(position: Vector2, limit: float) -> bool:
	return absf(position.x) <= limit and absf(position.y) <= limit
