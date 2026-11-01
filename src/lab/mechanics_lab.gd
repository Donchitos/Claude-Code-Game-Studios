extends Node3D
## Entry point for the offline movement laboratory, not the complete Phase 1 game.

const PlayerScript = preload("res://src/player/player_controller.gd")
const CameraScript = preload("res://src/camera/player_camera.gd")
const TuningScript = preload("res://src/data/movement_tuning.gd")
const CombatPreset = preload("res://assets/data/player_combat_default.tres")
const CombatScript = preload("res://src/combat/player_combat.gd")
const PistolScript = preload("res://src/combat/pistol_visual.gd")
const HudScript = preload("res://src/ui/player_hud.gd")
const WeaponScript = preload("res://src/combat/weapon_controller.gd")
const RangeScript = preload("res://src/lab/combat_range.gd")
const InteractionScript = preload("res://src/interaction/interaction_controller.gd")
const FeedbackScript = preload("res://src/combat/shot_feedback.gd")
const BreakerScript = preload("res://src/roles/breaker/breaker_role.gd")
const ScoutScript = preload("res://src/roles/scout/scout_role.gd")
const RecoveryScript = preload("res://src/recovery/recovery_controller.gd")
const HelperScript = preload("res://src/team/helpers/helper_bot.gd")
const ComboScript = preload("res://src/team/combos/combo_manager.gd")
const LaserSightScript = preload("res://src/combat/laser_sight.gd")
const GameplayHooksScript = preload("res://src/gameplay/gameplay_hooks.gd")
const CombatJuiceHookScript = preload("res://src/gameplay/combat_juice_hook.gd")
const DirectorPacingHookScript = preload("res://src/gameplay/director_pacing_hook.gd")
const LabRules = preload("res://assets/data/lab_rules.tres")
const RoleScript = preload("res://src/roles/role_controller.gd")
const CargoScript = preload("res://src/roles/cargo_controller.gd")
const SPAWN := Vector3(0.0, 0.75, 5.0)
const FLOOR_COLOR := Color("172333")
const LINE_COLOR := Color("304455")
const TEAL := Color("66e0c2")
const ORANGE := Color("ffae73")

@export var tuning: TuningScript

## Dinamik Oyun Kancaları ve Yönetmen
var hooks: GameplayHooksScript
var combat_juice: CombatJuiceHookScript
var director_pacing: DirectorPacingHookScript

## Per-lab health and ammunition; external damage systems call combat.apply_damage().
var combat: CombatScript
var weapon: WeaponScript
var interaction: InteractionScript
var combat_range: RangeScript
var roles: RoleScript
var cargo: CargoScript
var _feedback: FeedbackScript
var breaker_role: Node
var scout_role: Node
var active_role_id := "operator"
var recovery: RefCounted
var helper_bot: Node3D
var combo_manager: RefCounted
var laser_sight: Node3D
var _hazard_wait := 0.0
var _kick := 0.0
var _reduced_effects := false
var _limited_ammo := false
var _sample_status := ""
var _pistol: PistolScript
var _combat_hud: HudScript
var _player: PlayerScript
var _camera: CameraScript
var _status: Label
var _pause_label: Label
var _paused := false
var _capture_path := ""
var _frames := 0
var _verification := false
var _verification_start := Vector3.ZERO
var _verification_failures := 0
var _verification_checks := 0
var _verify_jump := false
var _verification_frame := 0
var _focus_wait_frames := 0
var _visual_root: Node3D
var _height_anchor: Node3D
var _ground_ring: MeshInstance3D
var _takeoff_age := -1.0
var _landing_age := -1.0
var _jump_count := 0
var _landing_count := 0
var _jump_start_y := 0.0
var _jump_camera_y := 0.0
var _peak_height := 0.0
var _hit_stop_remaining := 0.0
var _showcase_mode := false
var _showcase_frame := 0
var _showcase_panel: PanelContainer
var _showcase_title: Label
var _showcase_desc: Label
var _showcase_badge: Label
var _showcase_aim_pos := Vector3.ZERO


func _ready() -> void:
	_build_environment()
	_build_arena()
	_build_player()
	combat = CombatPreset.duplicate()
	combat.reset()
	_pistol = PistolScript.new()
	_pistol.name = "Pistol"
	_pistol.tuning = combat
	_pistol.position = Vector3(0.38, 0.86, -0.48)
	_visual_root.add_child(_pistol)
	combat.fired.connect(_pistol.play_shot)

	# Dinamik kancaları ilklendir ve kameraya / olaylara bağla
	hooks = GameplayHooksScript.new()
	combat_juice = CombatJuiceHookScript.new(hooks)
	director_pacing = DirectorPacingHookScript.new(hooks)

	hooks.shake_requested.connect(func(trauma: float):
		if is_instance_valid(_camera):
			_camera.add_trauma(trauma)
	)
	hooks.landing_impact.connect(func(speed: float):
		if is_instance_valid(_camera):
			_camera.add_landing_dip(speed)
	)
	hooks.hit_stop_requested.connect(func(duration: float):
		if not _reduced_effects:
			_hit_stop_remaining = maxf(_hit_stop_remaining, duration)
	)
	combat.fired.connect(combat_juice.on_fired)
	combat.damaged.connect(combat_juice.on_player_damaged)
	_player.landed.connect(combat_juice.on_player_landed)

	breaker_role = BreakerScript.new()
	add_child(breaker_role)
	scout_role = ScoutScript.new()
	add_child(scout_role)
	recovery = RecoveryScript.new()
	combo_manager = ComboScript.new()
	helper_bot = HelperScript.new()
	helper_bot.position = Vector3(2.0, 0.7, 6.0)
	helper_bot.target_player = _player
	helper_bot.recovery_system = recovery
	add_child(helper_bot)

	_build_hud()
	_build_combat_range()

	laser_sight = LaserSightScript.new()
	laser_sight.name = "TacticalLaser"
	laser_sight.excluded_rids.assign([_player.get_rid()])
	add_child(laser_sight)
	weapon.weapon_changed.connect(func(_p): laser_sight.set_weapon_theme(weapon.selected))
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size()):
		if arguments[index] == "--capture-evidence" and index + 1 < arguments.size():
			_capture_path = arguments[index + 1]
	_verification = arguments.has("--verify-lab")
	_verify_jump = arguments.has("--verify-jump")
	_showcase_mode = arguments.has("--showcase")
	if _showcase_mode:
		_build_showcase_hud()
	if _verification or _verify_jump:
		get_window().grab_focus()
	print("SECTOR9 LAB | WASD / Space jump / Ctrl slow walk / Left click fire / R reload / C / F5 / Esc")


func _process(delta: float) -> void:
	_frames += 1
	if not _paused:
		_animate_jump(delta)
		# Update 3D gun pitch and reload stance
		if is_instance_valid(_camera) and is_instance_valid(_pistol):
			var mouse: Vector2 = get_viewport().get_mouse_position()
			var cam_origin: Vector3 = _camera.project_ray_origin(mouse)
			var cam_dir: Vector3 = _camera.project_ray_normal(mouse)
			var gun_origin: Vector3 = _player.global_position + Vector3.UP * 0.86
			var aim_dir: Vector3 = PlayerScript.calculate_3d_aim_direction(cam_origin, cam_dir, gun_origin, _player.global_position.y)
			_pistol.aim_pitch = asin(clampf(-aim_dir.y, -0.85, 0.85))
			_pistol.is_reloading = combat.reload_remaining > 0.0

		if _hit_stop_remaining > 0.0:
			_hit_stop_remaining = maxf(_hit_stop_remaining - delta, 0.0)

		if is_instance_valid(laser_sight):
			var gun_origin: Vector3 = _player.global_position + Vector3.UP * 0.86
			var l_dir: Vector3
			if _showcase_aim_pos != Vector3.ZERO:
				l_dir = (_showcase_aim_pos - gun_origin).normalized()
			elif is_instance_valid(_camera):
				var mouse: Vector2 = get_viewport().get_mouse_position()
				l_dir = PlayerScript.calculate_3d_aim_direction(
					_camera.project_ray_origin(mouse), _camera.project_ray_normal(mouse), gun_origin, _player.global_position.y)
			laser_sight.update_laser(gun_origin, l_dir, get_world_3d().direct_space_state)

		combat.advance(delta)
		weapon.advance(delta)
		if combat_juice != null:
			combat_juice.advance(delta)
		if director_pacing != null:
			var max_h: float = maxf(combat.max_health, 1.0)
			var max_a: float = maxf(float(combat.magazine_capacity), 1.0)
			director_pacing.advance(delta, combat.health / max_h, float(combat.ammo) / max_a)
			director_pacing.check_and_trigger_director_event()
		_update_cargo(delta)

		_kick = maxf(_kick - delta, 0.0)
		_camera.h_offset = sin(_kick * 120.0) * _kick if not _reduced_effects else 0.0
		_update_lab_commands(delta)
		_update_contextual_cursor()
	if Input.is_action_just_pressed(&"lab_reset"):
		_reset_lab()
	if Input.is_action_just_pressed(&"ui_cancel"):
		set_paused(not _paused)
	if _paused and Input.is_physical_key_pressed(KEY_M):
		get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")
	if Input.is_action_just_pressed(&"reload"):
		reload_weapon()
	if Input.is_action_just_pressed(&"fire"):
		try_fire()
	var mode_text := tr("BEKLEME")
	if not _player.is_on_floor():
		mode_text = tr("YÜKSELİYOR") if _player.velocity.y > 0.0 else tr("İNİYOR")
	elif _player.velocity.length() > 0.1:
		mode_text = tr("SESSİZ YÜRÜYÜŞ") if _player.is_slow_walking else tr("HAREKET")
	_status.text = tr("%s  •  Konum: %.1f / %.1f") % [
		mode_text, _player.position.x, _player.position.z]
	if _player.position.y < -5.0:
		_reset_lab()
	if not _capture_path.is_empty() and _frames == 90 and not _verification and not _verify_jump:
		_capture_and_quit()


func _physics_process(delta: float) -> void:
	_height_anchor.global_position = Vector3(_player.global_position.x, _player.ground_anchor_y, _player.global_position.z)
	if _showcase_mode:
		_process_showcase(delta)
		return
	if _verification or _verify_jump:
		if not get_window().has_focus():
			_focus_wait_frames += 1
			if _verification_frame > 0 or _focus_wait_frames > 300:
				push_error("NOT ASSESSED: visible integration requires uninterrupted window focus")
				get_tree().quit(2)
			return
		_verification_frame += 1
	if _verify_jump:
		_verify_jump_sequence()
		return
	if not _verification:
		return
	# Explicit opt-in integration rehearsal drives the same actions as a keyboard.
	match _verification_frame:
		10:
			_verification_start = _player.position
			Input.action_press(&"move_right")
		50:
			_check(_player.position.x > _verification_start.x + 1.0, "right action moves player")
			Input.action_release(&"move_right")
			Input.action_press(&"move_forward")
		110:
			Input.action_release(&"move_forward")
			_reset_lab()
			_check(_player.position.distance_to(SPAWN) < 0.01, "reset restores spawn")
			_check(_player.velocity.is_zero_approx(), "reset clears velocity")
			Input.action_press(&"move_right")
		310:
			Input.action_release(&"move_right")
			_check(_player.position.x < 15.7, "arena boundary blocks player")
			_check(_player.position.x > 14.0, "player reaches boundary rather than stalling")
			_check(_player.is_on_floor(), "player remains grounded")
			_reset_lab()
		330:
			print("LAB INTEGRATION: %d checks, %d failures" % [_verification_checks, _verification_failures])
			if _capture_path.is_empty():
				get_tree().quit(0 if _verification_failures == 0 else 1)
			else:
				_capture_and_quit()


func _check(condition: bool, description: String) -> void:
	_verification_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_verification_failures += 1
		push_error("FAIL: " + description)


## Accept one shot only while gameplay can receive focused input.
func try_fire() -> bool:
	if _paused or (not _showcase_mode and not get_window().has_focus()) or roles.is_hacking() or cargo.carrying_core() or cargo.aiming:

		return false
	var origin: Vector3 = _player.global_position + Vector3.UP * 0.86
	var direction: Vector3
	if _showcase_aim_pos != Vector3.ZERO:
		direction = (_showcase_aim_pos - origin).normalized()
	else:
		var mouse: Vector2 = get_viewport().get_mouse_position()
		var cam_ray_origin: Vector3 = _camera.project_ray_origin(mouse)
		var cam_ray_dir: Vector3 = _camera.project_ray_normal(mouse)
		var query := PhysicsRayQueryParameters3D.create(cam_ray_origin, cam_ray_origin + cam_ray_dir * 100.0)
		query.exclude = [_player.get_rid()]
		var ray_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if not ray_hit.is_empty() and ray_hit.collider.has_method(&"receive_hit"):
			direction = (ray_hit.position - origin).normalized()
		else:
			direction = PlayerScript.calculate_3d_aim_direction(
				cam_ray_origin, cam_ray_dir, origin, _player.global_position.y)
	if direction.is_zero_approx():
		direction = -_player.global_basis.z
	var accepted: bool = weapon.fire_at(origin, direction, _player.velocity.length() > 0.1)
	if accepted:
		_kick = LabRules.camera_kick
		_feedback.play_tone(weapon.current_profile().tone_hz)
	return accepted


func _cargo_aim_point() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var ray_origin := _camera.project_ray_origin(mouse)
	var ray_direction := _camera.project_ray_normal(mouse)
	if absf(ray_direction.y) > 0.000001:
		var distance := (_player.global_position.y - ray_origin.y) / ray_direction.y
		if distance >= 0.0:
			return ray_origin + ray_direction * distance
	return _player.global_position - _player.global_basis.z * 5.0


func _update_cargo(delta: float) -> void:
	cargo.advance(delta, _player, _cargo_aim_point())


func _on_cargo_noise(_point: Vector3, radius: float) -> void:
	_sample_status = tr("Yem sesi: %.1f m") % radius


## Refill seven rounds from the lab's unlimited supply while gameplay is active.
## Pressing reload during an active reload attempts a Synthetik-style active reload.
func reload_weapon() -> bool:
	if _paused or not get_window().has_focus() or combat.health <= 0.0 or combat.stun_remaining > 0.0 or roles.is_hacking():
		return false
	if combat.reload_remaining > 0.0:
		return combat.attempt_active_reload()
	return combat.reload()


## Freeze movement and presentation without deleting airborne velocity.
func set_paused(value: bool) -> void:
	_paused = value
	_player.set_physics_process(not value)
	_camera.set_process(not value)
	_pistol.set_paused(value)
	_combat_hud.set_paused(value)
	_pause_label.visible = value
	_feedback.set_paused(value)
	interaction.cancel()
	roles.cancel_hack()
	scout_role.recall_active_drone()
	scout_role.set_process(not value)
	cargo.set_paused(value)
	_player.ability_locked = false
	for target in combat_range.targets:
		target.set_process(not value)
	_camera.h_offset = 0.0


func _reset_lab() -> void:
	combat.reset()
	weapon.reset_weapon()
	roles.reset_role()
	cargo.reset_cargo()
	cargo.set_paused(_paused)
	_player.cargo_speed_multiplier = 1.0
	if roles.current_profile().equipped_weapon >= 0:
		weapon.select_weapon(roles.current_profile().equipped_weapon)
	interaction.cancel()
	combat_range.reset_range()
	_feedback.reset_effects()
	_hazard_wait = 0.0
	_kick = 0.0
	combat.reserve_ammo = LabRules.limited_reserve if _limited_ammo else -1
	_sample_status = ""
	_camera.h_offset = 0.0
	_combat_hud.reset_display()
	_pistol.reset_visual()
	_player.reset_to(SPAWN)
	_height_anchor.position = SPAWN
	_takeoff_age = -1.0
	_landing_age = -1.0
	_visual_root.scale = Vector3.ONE
	_visual_root.position.y = -0.7
	_camera.snap_to_target()
	if breaker_role != null: breaker_role.reset_role()
	if scout_role != null: scout_role.reset_role()
	if recovery != null: recovery.reset()
	if combo_manager != null: combo_manager.reset()
	if helper_bot != null and helper_bot.has_method(&"reset_helper"): helper_bot.reset_helper()


func _capture_and_quit() -> void:
	await RenderingServer.frame_post_draw
	var directory := _capture_path.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(directory)
	if directory_error != OK:
		push_error("Evidence directory could not be created: %s" % directory)
		get_tree().quit(1)
		return
	var image := get_viewport().get_texture().get_image()
	var save_error := image.save_png(_capture_path)
	print("EVIDENCE: %s | result=%s" % [_capture_path, error_string(save_error)])
	get_tree().quit(0 if save_error == OK and _verification_failures == 0 else 1)


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0b1322")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a9c0df")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	key.light_color = Color("d5e4ff")
	key.light_energy = 1.3
	key.shadow_enabled = true
	add_child(key)


func _build_arena() -> void:
	_box("Floor", Vector3(32, 0.5, 28), Vector3(0, -0.25, 0), FLOOR_COLOR, true)
	_box("WestBoundary", Vector3(0.4, 0.7, 28), Vector3(-16, 0.35, 0), LINE_COLOR, true)
	_box("EastBoundary", Vector3(0.4, 0.7, 28), Vector3(16, 0.35, 0), LINE_COLOR, true)
	_box("NorthBoundary", Vector3(32, 0.7, 0.4), Vector3(0, 0.35, -14), LINE_COLOR, true)
	_box("SouthBoundary", Vector3(32, 0.7, 0.4), Vector3(0, 0.35, 14), LINE_COLOR, true)
	for x in range(-14, 16, 2):
		_box("GridX", Vector3(0.025, 0.008, 27), Vector3(x, 0.008, 0), LINE_COLOR)
	for z in range(-12, 14, 2):
		_box("GridZ", Vector3(31, 0.008, 0.025), Vector3(0, 0.008, z), LINE_COLOR)
	_box("CenterLine", Vector3(0.07, 0.01, 23), Vector3(0, 0.012, 0), TEAL)
	_box("StartPad", Vector3(3.2, 0.012, 2.8), Vector3(0, 0.015, 5), Color("254d53"))
	_box("SlalomA", Vector3(1.8, 1.5, 1.8), Vector3(-6, 0.75, -1), Color("46576d"), true)
	_box("SlalomB", Vector3(1.8, 1.5, 1.8), Vector3(-9, 0.75, -5), Color("46576d"), true)
	_box("SlalomC", Vector3(1.8, 1.5, 1.8), Vector3(-5, 0.75, -9), Color("46576d"), true)
	_box("CollisionWall", Vector3(0.5, 1.2, 5), Vector3(6, 0.6, -3), Color("66505a"), true)
	_box("CollisionCap", Vector3(0.54, 0.08, 5), Vector3(6, 1.24, -3), ORANGE)
	_box("NarrowLeft", Vector3(0.5, 1.2, 4), Vector3(9.5, 0.6, -8), Color("46576d"), true)
	_box("NarrowRight", Vector3(0.5, 1.2, 4), Vector3(11.3, 0.6, -8), Color("46576d"), true)
	_box("JumpLow", Vector3(3.5, 0.45, 0.6), Vector3(0, 0.225, -2), Color("356a68"), true)
	_box("JumpMedium", Vector3(3.5, 0.75, 0.6), Vector3(0, 0.375, -6), Color("476571"), true)
	_world_label(tr("SPACE / ZIPLA — 45 cm"), Vector3(0, 0.08, -0.8), TEAL)
	_world_label(tr("75 cm"), Vector3(0, 0.08, -4.8), TEAL)
	_world_label(tr("01 / HAREKET"), Vector3(0, 0.08, 8), TEAL)
	_world_label(tr("02 / SLALOM"), Vector3(-7, 0.08, 1), Color("bdc9d9"))
	_world_label(tr("03 / ÇARPIŞMA"), Vector3(7, 0.08, 1), ORANGE)
	_world_label(tr("DAR GEÇİT"), Vector3(10.4, 0.08, -11.5), Color("bdc9d9"))


func _build_player() -> void:
	_player = PlayerScript.new()
	_player.name = "Player"
	_player.tuning = tuning
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.4
	collider.shape = shape
	_player.add_child(collider)
	_visual_root = Node3D.new()
	_visual_root.name = "JumpVisual"
	_visual_root.position.y = -0.7
	_player.add_child(_visual_root)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.4
	mesh.mesh = capsule
	mesh.material_override = _material(TEAL)
	mesh.position.y = 0.7
	_visual_root.add_child(mesh)
	# The orange nose makes facing direction immediately visible without animation.
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.18, 0.16, 0.5)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, 0.95, -0.43)
	nose.material_override = _material(ORANGE)
	_visual_root.add_child(nose)
	_player.position = SPAWN
	add_child(_player)
	_player.jumped.connect(_on_jumped)
	_player.landed.connect(_on_landed)
	_height_anchor = Node3D.new()
	_height_anchor.position = SPAWN
	add_child(_height_anchor)
	_ground_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.43
	ring.outer_radius = 0.48
	_ground_ring.mesh = ring
	_ground_ring.material_override = _material(TEAL)
	_ground_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ground_ring)
	_camera = CameraScript.new()
	_camera.name = "PlayerCamera"
	_camera.target = _player
	_camera.height_anchor = _height_anchor
	_camera.tuning = tuning
	_camera.current = true
	add_child(_camera)
	_player.camera = _camera
	_camera.snap_to_target()


func _on_jumped() -> void:
	_takeoff_age = 0.0
	_landing_age = -1.0
	_jump_count += 1


func _on_landed(_impact_speed: float) -> void:
	_landing_age = 0.0
	_takeoff_age = -1.0
	_landing_count += 1


func _animate_jump(delta: float) -> void:
	# Animate only the foot-pivoted visual: collision and input never wait on a pose.
	var desired := Vector3.ONE
	var strength := clampf(tuning.jump_animation_strength, 0.0, 1.0)
	if _takeoff_age >= 0.0:
		_takeoff_age += delta
		var duration := maxf(tuning.jump_takeoff_duration, 0.001)
		var pulse := sin(PI * clampf(_takeoff_age / duration, 0.0, 1.0))
		desired += Vector3(-0.5, 1.0, -0.5) * pulse * tuning.jump_stretch * strength
		if _takeoff_age >= duration:
			_takeoff_age = -1.0
	elif _landing_age >= 0.0:
		_landing_age += delta
		var duration := maxf(tuning.jump_landing_duration, 0.001)
		var pulse := sin(PI * clampf(_landing_age / duration, 0.0, 1.0))
		desired += Vector3(0.5, -1.0, 0.5) * pulse * tuning.jump_squash * strength
		if _landing_age >= duration:
			_landing_age = -1.0
	elif not _player.is_on_floor():
		var speed_ratio := clampf(_player.velocity.y / sqrt(maxf(2.0 * tuning.gravity * tuning.jump_height, 0.001)), -1.0, 1.0)
		desired += Vector3(-0.5, 1.0, -0.5) * absf(speed_ratio) * tuning.jump_stretch * strength * 0.5
	_visual_root.scale = _visual_root.scale.lerp(desired, 1.0 - exp(-maxf(tuning.jump_pose_sharpness, 0.0) * delta))
	# A ray-projected marker exposes height without bobbing the camera.
	var query := PhysicsRayQueryParameters3D.create(_player.global_position, _player.global_position + Vector3.DOWN * 10.0)
	query.exclude = [_player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	_ground_ring.visible = not hit.is_empty()
	if not hit.is_empty():
		_ground_ring.global_position = hit.position + Vector3.UP * 0.025


func _verify_jump_sequence() -> void:
	var frame := _verification_frame
	_peak_height = maxf(_peak_height, _player.position.y - _jump_start_y)
	match frame:
		15:
			_check(_player.is_on_floor(), "jump starts grounded")
			_jump_start_y = _player.position.y
			_jump_camera_y = _camera.position.y
			Input.action_press(&"camera_center")
			Input.action_press(&"jump")
		18:
			_check(_player.velocity.y > 0.0, "jump input launches upward")
			_check(_jump_count == 1, "one jump event emitted")
			Input.action_release(&"jump")
		22:
			Input.action_press(&"jump")
		26:
			_check(_jump_count == 1, "airborne repeat rejected")
			_check(absf(_camera.position.y - _jump_camera_y) < 0.08, "camera ignores airborne height")
			if not _capture_path.is_empty():
				_save_frame(_capture_path.get_basename() + "-air.png")
		54:
			if not _capture_path.is_empty():
				_save_frame(_capture_path.get_basename() + "-landing.png")
		80:
			_check(_peak_height > 0.85 and _peak_height < 1.1, "jump apex stays near one meter")
			_check(_player.is_on_floor(), "jump lands on floor")
			_check(_jump_count == 1, "held input does not auto-hop")
			_check(_landing_count >= 1, "landing feedback emitted")
			Input.action_release(&"jump")
		90:
			Input.action_press(&"jump")
		94:
			_reset_lab()
			_check(_player.velocity.is_zero_approx(), "reset clears jump velocity")
			Input.action_release(&"jump")
		110:
			print("JUMP INTEGRATION: %d checks, %d failures" % [_verification_checks, _verification_failures])
			if _capture_path.is_empty():
				get_tree().quit(0 if _verification_failures == 0 else 1)
			else:
				_capture_and_quit()


func _save_frame(path: String) -> void:
	await RenderingServer.frame_post_draw
	var result := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if result == OK:
		result = get_viewport().get_texture().get_image().save_png(path)
	_check(result == OK, "save jump pose evidence")


func _box(node_name: String, size: Vector3, location: Vector3, color: Color, solid := false) -> void:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.name = node_name
	root.position = location
	var visual := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	visual.mesh = box
	visual.material_override = _material(color)
	root.add_child(visual)
	if solid:
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		root.add_child(collider)
	add_child(root)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material


func _world_label(text: String, location: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = location
	label.rotation_degrees.x = -90
	label.font_size = 56
	label.pixel_size = 0.012
	label.modulate = color
	add_child(label)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_combat_hud = HudScript.new()
	_combat_hud.name = "CombatHud"
	root.add_child(_combat_hud)
	_combat_hud.bind_state(combat)
	var controls := _label(tr("WASD   Hareket\nFARE   Bakış yönü\nSOL TIK   Ateş\n1–4   Silah seç\nF2   Rol seç • 6 Göz • 5 Operatör\nQ/F   Rol yetenekleri • B Duman/Yem • G Bırak\nR   Şarjör değiştir\nE   Etkileşim / Taşı\nT   Basılı tut / aç-kapa\nF6   Efekt azalt\nF7   Mermi test modu\nCTRL   Sessiz yürü\nSPACE   Zıpla\nC basılı   Kamerayı merkezle\nF5   Alanı sıfırla\nESC   Duraklat / devam"), 15, Color("e3eaf2"))

	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.position = Vector2(-290, 24)
	controls.size = Vector2(260, 205)
	root.add_child(controls)
	_status = _label("", 17, TEAL)
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_status.position = Vector2(30, -62)
	root.add_child(_status)
	var disclaimer := _label(tr("R: şarjör değiştir • Sınırsız yedek şarjör • F5: laboratuvarı sıfırla."), 14, Color("aebed1"))
	disclaimer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	disclaimer.position = Vector2(30, -33)
	root.add_child(disclaimer)
	_pause_label = _label(tr("DURAKLATILDI\nDevam etmek için ESC • Menü için M"), 26, ORANGE)
	_pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_pause_label.position = Vector2(-185, -45)
	_pause_label.visible = false
	root.add_child(_pause_label)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_shadow_color", Color("0b1322"))
	label.add_theme_constant_override(&"shadow_offset_x", 1)
	label.add_theme_constant_override(&"shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_combat_range() -> void:
	weapon = WeaponScript.new()
	weapon.state = combat
	weapon.excluded = [_player.get_rid()]
	add_child(weapon)
	weapon.weapon_changed.connect(_combat_hud.show_weapon)
	weapon.weapon_changed.connect(_pistol.show_profile)
	_pistol.show_profile(weapon.current_profile())
	combat_range = RangeScript.new()
	combat_range.name = "CombatRange"
	add_child(combat_range)
	combat_range.set_enemy_target(_player)
	combat_range.enemy_attacked.connect(func(amount: float):
		combat.apply_damage(amount, 1)
	)
	interaction = InteractionScript.new()
	interaction.reach = LabRules.interaction_reach
	add_child(interaction)
	_feedback = FeedbackScript.new()
	add_child(_feedback)
	weapon.shot_traced.connect(_on_shot_traced)
	combat_range.shield_station.activated.connect(combat.refill_shield)
	combat_range.terminal.activated.connect(func():
		combat_range.door.activate()
		_sample_status = tr("Terminal kapıyı açtı"))
	combat.reserve_ammo = LabRules.limited_reserve if _limited_ammo else -1
	roles = RoleScript.new()
	add_child(roles)
	cargo = CargoScript.new()
	cargo.name = "CargoController"
	add_child(cargo)
	roles.role_changed.connect(_on_role_changed)
	roles.fuse_cast.connect(_show_fuse_cone)
	cargo.noise_emitted.connect(_on_cargo_noise)
	combat.damaged.connect(_interrupt_role_on_damage)
	_on_role_changed(roles.current_profile())


func _update_lab_commands(delta: float) -> void:
	var focused: bool = get_window().has_focus()
	var can_act: bool = focused and combat.health > 0.0 and combat.stun_remaining <= 0.0
	_player.set_physics_process(combat.health > 0.0 and combat.stun_remaining <= 0.0)
	_hazard_wait = maxf(_hazard_wait - delta, 0.0)
	if combat_range.hazard.overlaps_body(_player) and _hazard_wait <= 0.0 and not combat_range.electrical_panel.is_disabled():
		combat.apply_damage(LabRules.hazard_damage, 1)
		combat.apply_stun(LabRules.hazard_stun)
		_hazard_wait = LabRules.hazard_interval
	if not can_act:
		cargo.cancel_aim()
		if not focused:
			scout_role.recall_active_drone()
			_player.velocity.x = 0.0
			_player.velocity.z = 0.0
		interaction.cancel()
		roles.cancel_hack()
		_player.ability_locked = false
		_update_role_abilities(delta, false)
		_combat_hud.show_context(tr("F5: yeniden başlat") if combat.health <= 0.0 else "")
		return
	_update_role_abilities(delta, true)
	if roles.is_hacking():
		interaction.cancel()
		return
	for index in range(4):
		if Input.is_action_just_pressed(StringName("weapon_%d" % (index + 1))):
			if roles.current_profile().role_id == &"operator" or index == roles.current_profile().equipped_weapon:
				weapon.select_weapon(index)
	if Input.is_action_just_pressed(&"interaction_toggle"):
		interaction.cancel()
		interaction.toggle_mode = not interaction.toggle_mode
	if Input.is_action_just_pressed(&"effects_toggle"):
		_reduced_effects = not _reduced_effects
		_feedback.reduced = _reduced_effects
		_pistol.set_meta(&"reduced", _reduced_effects)
	if Input.is_action_just_pressed(&"ammo_mode"):
		_limited_ammo = not _limited_ammo
		combat.reserve_ammo = LabRules.limited_reserve if _limited_ammo else -1
	var candidate: Node3D = combat_range.pick_station(_camera, get_viewport().get_mouse_position())
	var clear := candidate != null and combat_range.clear_sight(_player, candidate)
	if roles.current_profile().role_id == &"yuk":
		var cargo_item := cargo.pick_item(_player, _camera, get_viewport().get_mouse_position())
		if is_instance_valid(cargo_item) and Input.is_action_just_pressed(&"interact"):
			cargo.pickup(cargo_item)
			candidate = null
			clear = false
	interaction.set_candidate(candidate, _player.global_position, clear)
	interaction.step(Input.is_action_just_pressed(&"interact"), Input.is_action_pressed(&"interact"), delta)
	var context := ""
	if is_instance_valid(candidate):
		context = tr(candidate.display_name) + " • "
		if not interaction.reason.is_empty():
			context += interaction.reason
		else:
			context += tr("E: kullan") + " %d%%" % int(interaction.progress * 100.0)
	if interaction.toggle_mode:
		context += "  " + tr("E aç/kapa")
	if _limited_ammo:
		context += "  " + tr("Yedek") + ": %d" % combat.reserve_ammo
	_combat_hud.show_context(context)


func _update_contextual_cursor() -> void:
	if not is_instance_valid(_camera) or not is_instance_valid(_combat_hud):
		return
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var cam_ray_origin: Vector3 = _camera.project_ray_origin(mouse)
	var cam_ray_dir: Vector3 = _camera.project_ray_normal(mouse)
	var query := PhysicsRayQueryParameters3D.create(cam_ray_origin, cam_ray_origin + cam_ray_dir * 80.0)
	query.exclude = [_player.get_rid()]
	var hover_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	var cur_mode: int = 0
	var cur_reason: String = ""
	var cur_dist: float = 0.0

	if not hover_hit.is_empty():
		var collider: Object = hover_hit.collider
		var hit_pos: Vector3 = hover_hit.position
		cur_dist = _player.global_position.distance_to(hit_pos)
		var max_range: float = weapon.current_profile().distance

		if collider.has_method(&"receive_hit"):
			if collider.get("team") == 0:
				cur_mode = 5
				cur_reason = tr("Dost")
			elif cur_dist > max_range:
				cur_mode = 3
				cur_reason = tr("Menzil Dışı")
			else:
				var gun_origin: Vector3 = _player.global_position + Vector3.UP * 0.86
				var los_query := PhysicsRayQueryParameters3D.create(gun_origin, hit_pos)
				los_query.exclude = [_player.get_rid(), collider.get_rid() if collider is CollisionObject3D else RID()]
				var los_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(los_query)
				if not los_hit.is_empty() and los_hit.collider != collider:
					cur_mode = 4
					cur_reason = tr("Siper Arkası")
				else:
					cur_mode = 1
					cur_reason = collider.name if not collider.name.is_empty() else tr("Düşman")
		elif collider.has_method(&"activate"):
			if cur_dist <= LabRules.interaction_reach:
				cur_mode = 2
				cur_reason = collider.display_name if "display_name" in collider else tr("Etkileşim")
			else:
				cur_mode = 3
				cur_reason = tr("Uzak")

	_combat_hud.set_cursor_context(cur_mode, cur_reason, cur_dist)


func _on_shot_traced(start: Vector3, finish: Vector3, hit: bool) -> void:
	_feedback.trace_shot(start, finish, hit)
	_feedback.eject_casing(_pistol.global_position, _player.global_basis.x)
	var ray_dir: Vector3 = (finish - start).normalized()
	if hit:
		_combat_hud.show_hit()
		_pistol.confirm_hit(LabRules.impact_duration)
		_feedback.play_tone(700.0, true)
		_feedback.spawn_impact_sparks(finish, Vector3.UP, true, ray_dir)
		if combat_juice != null:
			combat_juice.on_hit_confirmed(weapon.current_profile().damage, false)
	else:
		_feedback.spawn_impact_sparks(finish, Vector3.UP, false, ray_dir)
		_feedback.spawn_impact_decal(finish, Vector3.UP)


func _build_showcase_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 25
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	_showcase_panel = PanelContainer.new()
	_showcase_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_showcase_panel.offset_top = 22.0
	_showcase_panel.offset_left = -420.0
	_showcase_panel.offset_right = 420.0
	_showcase_panel.offset_bottom = 110.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.13, 0.94)
	style.border_color = Color("66e0c2")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_showcase_panel.add_theme_stylebox_override(&"panel", style)
	root.add_child(_showcase_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_showcase_panel.add_child(vbox)

	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	_showcase_badge = Label.new()
	_showcase_badge.text = "[ VİTRİN ]"
	_showcase_badge.add_theme_font_size_override(&"font_size", 14)
	_showcase_badge.add_theme_color_override(&"font_color", Color("ffd280"))
	hbox.add_child(_showcase_badge)

	_showcase_title = Label.new()
	_showcase_title.text = "SECTOR 9 — FAZ 1 MEKANİK VİTRİNİ"
	_showcase_title.add_theme_font_size_override(&"font_size", 20)
	_showcase_title.add_theme_color_override(&"font_color", Color("66e0c2"))
	_showcase_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_showcase_title)

	_showcase_desc = Label.new()
	_showcase_desc.text = "19 Görev, 29 Test Paketi, 572 Kontrol — %100 Başarı"
	_showcase_desc.add_theme_font_size_override(&"font_size", 14)
	_showcase_desc.add_theme_color_override(&"font_color", Color("e3eaf2"))
	_showcase_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_showcase_desc)


func _set_showcase_text(badge: String, title: String, desc: String) -> void:
	if is_instance_valid(_showcase_badge): _showcase_badge.text = badge
	if is_instance_valid(_showcase_title): _showcase_title.text = title
	if is_instance_valid(_showcase_desc): _showcase_desc.text = desc


func _process_showcase(delta: float) -> void:
	_showcase_frame += 1
	if _showcase_frame % 50 == 0:
		print("SHOWCASE FRAME: ", _showcase_frame)

	# Segment 0: Intro (0-60 frames / 0-2s)
	if _showcase_frame < 60:
		_set_showcase_text("[ GİRİŞ ]", "SECTOR 9 — FAZ 1 TAKTİKSEL MEKANİK TESTİ", "Eksiksiz 19 Görev, Düşman İmhası ve Taktiksel Saha Testi")

	# Segment 1: Tactical Combat & Eliminating Pursuers (60-260 frames / 2-8.5s)
	elif _showcase_frame < 260:
		_set_showcase_text("[ BÖLÜM 1 / 10 ]", "01. DÜŞMAN TEHDİDİ & DONDURUCU ÇATIŞMA", "2: Şok ile dondurma, 3: Pompalı ve 4: Karabina ile düşman botlarının imhası")
		if _showcase_frame == 70:
			weapon.select_weapon(1)
		elif _showcase_frame == 90 or _showcase_frame == 105:
			if combat_range.enemies.size() > 0:
				_showcase_aim_pos = combat_range.enemies[0].global_position + Vector3.UP * 0.7
			try_fire()
		elif _showcase_frame == 130:
			weapon.select_weapon(2)
		elif _showcase_frame == 145 or _showcase_frame == 160:
			if combat_range.enemies.size() > 1:
				_showcase_aim_pos = combat_range.enemies[1].global_position + Vector3.UP * 0.7
			try_fire()
			if _showcase_frame == 160 and combat_range.enemies.size() > 1:
				combat_range.enemies[1].receive_hit(100.0, 0)
		elif _showcase_frame == 180:
			weapon.select_weapon(3)
		elif _showcase_frame >= 195 and _showcase_frame <= 225 and _showcase_frame % 10 == 0:
			if combat_range.enemies.size() > 0:
				_showcase_aim_pos = combat_range.enemies[0].global_position + Vector3.UP * 0.7
			try_fire()
			if _showcase_frame == 225 and combat_range.enemies.size() > 0:
				combat_range.enemies[0].receive_hit(100.0, 0)

	# Segment 2: Clear Movement (260-440 frames / 8.5-14.5s)
	elif _showcase_frame < 440:
		_set_showcase_text("[ BÖLÜM 2 / 10 ]", "02. TEMİZ SAHA HAREKETİ", "Düşmanlar temizlendi; engelsiz sahada akıcı WASD hareketi")
		_player.simulate_motion(Vector2(0, -1), false, delta)

	# Segment 3: Jumps over Hurdles (440-620 frames / 14.5-20.5s)
	elif _showcase_frame < 620:
		_set_showcase_text("[ BÖLÜM 3 / 10 ]", "03. PROSEDÜREL BALİSTİK ZIPLAMA", "Space ile 1m balistik sıçrama; 45cm ve 75cm engelleri aşma, kalkış/iniş esnemesi")
		_player.simulate_motion(Vector2(0, -1), false, delta)
		if _showcase_frame == 480:
			_player.simulate_vertical_motion(true, true, delta)
		elif _showcase_frame == 560:
			_player.simulate_vertical_motion(true, true, delta)

	# Segment 4: Crouch under Laser Corridor (620-760 frames / 20.5-25.5s)
	elif _showcase_frame < 760:
		_set_showcase_text("[ BÖLÜM 4 / 10 ]", "04. SESSİZ YÜRÜYÜŞ & LAZER SIZMASI", "Sol Ctrl ile sessiz yürüme; aktif lazer ızgarasının altından hasar almadan sızma")
		_player.global_position = _player.global_position.move_toward(Vector3(10.4, 0.75, -8.0), 4.0 * delta)
		_player.is_slow_walking = true

	# Segment 5: 3D Aiming, Recoil & Reload (760-920 frames / 25.5-30.5s)
	elif _showcase_frame < 920:
		_set_showcase_text("[ BÖLÜM 5 / 10 ]", "05. 3B DİKEY NİŞAN & GERİ TEPME", "Ayak dibinde dik açı, 6m ötesinde 0° düz atış; kovan fırlatma ve 2sn doldurma")
		weapon.select_weapon(0)
		_player.global_position = _player.global_position.move_toward(Vector3(0.0, 0.75, -1.0), 12.0 * delta)
		if _showcase_frame == 780 or _showcase_frame == 795:
			_showcase_aim_pos = _player.global_position + Vector3(0.4, 0.0, -1.0)
			try_fire()
		elif _showcase_frame >= 820 and _showcase_frame <= 870 and _showcase_frame % 10 == 0:
			_showcase_aim_pos = _player.global_position + Vector3(0.0, 0.86, -18.0)
			try_fire()
		elif _showcase_frame == 880:
			_pistol.is_reloading = true

	# Segment 6: Contextual Reticle (920-1060 frames / 30.5-35.5s)
	elif _showcase_frame < 1060:
		_set_showcase_text("[ BÖLÜM 6 / 10 ]", "06. BAĞLAMSAL AKILLI İMLEÇ SİSTEMİ", "Hedefte Kırmızı ⌖, Siper Arkasında Turuncu ✕, İstasyonda Altın ◎ [E]")
		if _showcase_frame < 965:
			_combat_hud.set_cursor_context(1, "Hedef Kuklası", 4.8)
		elif _showcase_frame < 1010:
			_combat_hud.set_cursor_context(4, "Siper Arkası", 7.5)
		else:
			_combat_hud.set_cursor_context(2, "Terminal", 1.8)

	# Segment 7: Breaker Role Bash & Shield Wall (1060-1220 frames / 35.5-40.5s)
	elif _showcase_frame < 1220:
		_set_showcase_text("[ BÖLÜM 7 / 10 ]", "07. KIRICI (BREAKER) ROLÜ: DARBE & KALKAN", "Tuş 5: Kırıcı | Q: Omuz Darbesi ile siperi parçalama, F: Portatif Kalkan Duvarı")
		active_role_id = "breaker"
		if _showcase_frame == 1070:
			_player.global_position = Vector3(-5.2, 0.75, -5.0)
			_player.rotation.y = 0.0
		elif _showcase_frame == 1090:
			if breaker_role != null: breaker_role.try_shoulder_bash(_player)
		elif _showcase_frame == 1150:
			if breaker_role != null: breaker_role.try_deploy_shield(_player, self)

	# Segment 8: Scout Role Drone & Sonar Scan (1220-1370 frames / 40.5-45.5s)
	elif _showcase_frame < 1370:
		_set_showcase_text("[ BÖLÜM 8 / 10 ]", "08. GÖZ (SCOUT) ROLÜ: DRONE & SONAR", "Tuş 6: Göz | Q: Keşif Drone'u uçurma, F: 18m Sonar Alan Taraması")
		active_role_id = "scout"
		if _showcase_frame == 1230:
			if scout_role != null: scout_role.toggle_drone(_player, self)
		elif _showcase_frame == 1290:
			if scout_role != null: scout_role.trigger_sonar_scan(_player.global_position, combat_range.enemies)
		elif _showcase_frame == 1340:
			if scout_role != null: scout_role.toggle_drone(_player, self)

	# Segment 9: Prop Carrying, Throwing & Loot (1370-1510 frames / 45.5-50.5s)
	elif _showcase_frame < 1510:
		_set_showcase_text("[ BÖLÜM 9 / 10 ]", "09. NESNE TAŞIMA, FIRLATMA & KASALAR", "E ile Güç Hücresini omzuna alma ve fırlatma; ganimet kasasını açıp eşya alma")
		if _showcase_frame == 1380:
			_player.global_position = Vector3(2.0, 0.75, 3.0)
			if is_instance_valid(combat_range.throwable_prop): combat_range.throwable_prop.pick_up(_player)
		elif _showcase_frame == 1420:
			if is_instance_valid(combat_range.throwable_prop): combat_range.throwable_prop.throw_object(Vector3(0, 6, -10))
		elif _showcase_frame == 1460:
			_player.global_position = Vector3(5.5, 0.75, 3.0)
			if is_instance_valid(combat_range.loot_crate): combat_range.loot_crate.try_open()

	# Segment 10: Downed State & AI Helper Rescue (1510-1640 frames / 50.5-54.5s)
	elif _showcase_frame < 1640:
		_set_showcase_text("[ BÖLÜM 10 / 10 ]", "10. SİSTEM ÇÖKTÜ & DOST AI YARDIMCI", "Sistem Çöktü (Downed) sürünme; Dost AI robotun koşup canlandırması (35 HP)")
		if _showcase_frame == 1520:
			_player.global_position = Vector3(0.0, 0.75, 2.0)
			combat.health = 0.0
			recovery.enter_downed()
		elif _showcase_frame == 1590:
			recovery.step_revive(3.0, 1.0)
			combat.health = 35.0

	# Segment 11: Final Grand Victory Summary (1640-1740 frames / 54.5-58s)
	elif _showcase_frame < 1740:
		_set_showcase_text("[ FAZ 1 MÜHÜRLENDİ ]", "FAZ 1 TÜM TESTLER GEÇTİ & MÜHÜRLENDİ", "19 Görev, 29 Test Paketi, 572 Kontrol — %100 Başarı | Faz 2'ye Hazır!")
	else:
		get_tree().quit(0)


func _update_role_abilities(delta: float, accepts_input: bool) -> void:
	if accepts_input:
		if Input.is_action_just_pressed(&"role_cycle"):
			roles.select_role((roles.selected + 1) % RoleScript.PROFILES.size())
		elif Input.is_physical_key_pressed(KEY_6):
			roles.select_role(4)
		elif Input.is_physical_key_pressed(KEY_5):
			roles.select_role(0)
	var profile: Resource = roles.current_profile()
	var target: Node3D = combat_range.pick_hack_target(_camera, get_viewport().get_mouse_position())
	var clear: bool = target != null and combat_range.clear_sight(_player, target)
	if accepts_input:
		var moving: bool = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back").length_squared() > 0.0
		if moving or Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"interact"):
			roles.cancel_hack(tr("Hack iptal: hareket"))
		if Input.is_action_just_pressed(&"ability_primary"):
			if profile.role_id == &"scout":
				scout_role.toggle_drone(_player, self)
			elif profile.role_id == &"yuk":
				cargo.begin_aim()
			elif profile.role_id == &"kirici":
				roles.strike(_player, -_player.global_basis.z)
			elif roles.is_hacking():
				roles.cancel_hack(tr("Hack iptal"))
			elif not moving:
				roles.begin_hack(target, _player, clear)
		if profile.role_id == &"yuk" and cargo.aiming and not Input.is_action_pressed(&"ability_primary"):
			cargo.throw_item(_player, _cargo_aim_point())
		if Input.is_action_just_pressed(&"cargo_utility") and profile.role_id == &"yuk":
			cargo.toggle_utility()
		if Input.is_action_just_pressed(&"cargo_drop") and profile.role_id == &"yuk":
			cargo.drop_item(_player)
		if Input.is_action_just_pressed(&"ability_secondary"):
			if profile.role_id == &"scout":
				scout_role.trigger_sonar_scan(_player.global_position, combat_range.enemies)
			elif profile.role_id == &"kirici":
				roles.deploy_shield(_player, -_player.global_basis.z)
			elif profile.role_id == &"yuk":
				cargo.use_utility(_player, _cargo_aim_point())
			else:
				roles.cast_fuse(_player, -_player.global_basis.z, combat_range.electrical_devices, combat_range.targets)
	roles.advance(delta, _player, target, clear)
	if roles.is_hacking():
		_player.velocity.x = 0.0
		_player.velocity.z = 0.0
	_player.ability_locked = roles.is_hacking()
	var reveal: float = profile.cable_sight_reach if profile.role_id == &"kilit" else 0.0
	combat_range.advance_devices(delta, _player.global_position, reveal)
	var text: String = tr(profile.display_name) + " • " + tr("F2: rol seç")
	if profile.role_id == &"kilit":
		text += "\n" + tr("Q: Hack") + " %.1f  |  " % roles.hack_cooldown_remaining \
			+ tr("F: Sigorta Ağı") + " %.1f" % roles.fuse_cooldown_remaining
		if roles.is_hacking():
			text += "\n" + tr("Hack sürüyor") + " %d%%" % int(roles.hack_progress * 100.0)
		elif not roles.message.is_empty():
			text += "\n" + roles.message
	elif profile.role_id == &"kirici":
		text += "\n" + tr("Q: Kır/it") + " %.1f  |  " % roles.break_cooldown_remaining \
			+ tr("F: Kalkan Duvarı") + " %.1f" % roles.shield_cooldown_remaining
		if not roles.message.is_empty():
			text += "\n" + roles.message
	elif profile.role_id == &"yuk":
		_player.cargo_speed_multiplier = profile.core_speed_multiplier if cargo.carrying_core() else 1.0
		text += "\n" + tr("E: al  | Q: fırlat  | G: bırak  | F: %s") % tr(cargo.utility_mode)
		text += "\n" + tr("Çanta: %d/%d  | Q %.1f  F %.1f") % [cargo.carried.size(), profile.cargo_capacity, cargo.throw_cooldown, cargo.utility_cooldown]
		if not cargo.message.is_empty():
			text += "\n" + cargo.message
	_combat_hud.show_role(text)


func _on_role_changed(profile: Resource) -> void:
	scout_role.reset_role()
	active_role_id = String(profile.role_id)
	_player.ability_locked = false
	_player.role_walk_multiplier = profile.slow_walk_factor
	weapon.noise_multiplier = profile.shot_noise_multiplier
	var ratio: float = combat.health / maxf(combat.max_health, 1.0)
	combat.max_health = profile.max_health
	combat.health = clampf(ratio * combat.max_health, 0.0, combat.max_health)
	combat.health_changed.emit(combat.health, combat.max_health)
	interaction.cancel()
	cargo.set_role(profile)
	_player.cargo_speed_multiplier = 1.0
	if profile.equipped_weapon >= 0:
		weapon.select_weapon(profile.equipped_weapon)
	else:
		weapon.select_weapon(0)


func _interrupt_role_on_damage(_amount: float) -> void:
	roles.cancel_hack(tr("Hack iptal: hasar"))
	_player.ability_locked = false


func _show_fuse_cone(origin: Vector3, direction: Vector3, reach: float, angle: float) -> void:
	if _reduced_effects:
		return
	for index in range(7):
		var yaw: float = deg_to_rad(-angle * 0.5 + angle * index / 6.0)
		var start: Vector3 = origin + Vector3.DOWN * 0.65
		_feedback.trace_shot(start, start + direction.rotated(Vector3.UP, yaw) * reach, false)
