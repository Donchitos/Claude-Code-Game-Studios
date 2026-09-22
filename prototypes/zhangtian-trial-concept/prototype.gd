# PROTOTYPE - NOT FOR PRODUCTION
# Question: 玩家能否在75秒三段敌潮中，通过走位、自动飞剑与升级撑到胜利结算？
# Date: 2026-09-02

extends Node2D

const VIEW_SIZE := Vector2(720.0, 1280.0)
const PLAYER_RADIUS := 24.0
const BEETLE_RADIUS := 19.0
const WOLF_RADIUS := 15.0
const SWORD_RADIUS := 9.0
const XP_RADIUS := 10.0
const JOYSTICK_RADIUS := 92.0
const BASE_PLAYER_SPEED := 360.0
const BASE_ATTACK_INTERVAL := 0.42
const SWORD_SPEED := 680.0
const BEETLE_SPEED := 88.0
const WOLF_SPEED := 152.0
const BEETLE_CONTACT_DAMAGE := 12.0
const WOLF_CONTACT_DAMAGE := 18.0
const CONTACT_COOLDOWN := 0.55
const DEMO_DURATION_SECONDS := 75.0
const SMOKE_TIMEOUT_SECONDS := 80.0
const SMOKE_SPEED_MULTIPLIER := 5.0
const PROJECTILE_DESPAWN_RADIUS := 980.0
const GRID_SIZE := 72.0
const ENEMY_BEETLE := 0
const ENEMY_WOLF := 1

var rng := RandomNumberGenerator.new()
var player_position := Vector2.ZERO
var player_hp := 100.0
var player_speed := BASE_PLAYER_SPEED
var pickup_radius := 62.0
var invulnerability_left := 0.0

var enemies: Array[Dictionary] = []
var swords: Array[Dictionary] = []
var xp_orbs: Array[Vector2] = []

var elapsed_time := 0.0
var spawn_left := 0.2
var attack_left := 0.1
var attack_interval := BASE_ATTACK_INTERVAL
var sword_count := 1
var sword_damage := 1
var kills := 0
var level := 1
var xp := 0
var first_upgrade_time := -1.0

var touch_active := false
var touch_index := -1
var touch_origin := Vector2.ZERO
var touch_position := Vector2.ZERO
var choosing_upgrade := false
var game_over := false
var demo_complete := false
var smoke_test_mode := false

var hud_label: Label
var hint_label: Label
var hp_bar_background: ColorRect
var hp_bar_fill: ColorRect
var overlay: ColorRect
var overlay_title: Label
var overlay_subtitle: Label
var choice_buttons: Array[Button] = []
var camera: Camera2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	smoke_test_mode = "--smoke-test" in OS.get_cmdline_user_args()
	if smoke_test_mode:
		rng.seed = 20260902
	else:
		rng.randomize()
	_create_camera()
	_create_ui()
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	_reset_run()


func _physics_process(delta: float) -> void:
	if game_over or demo_complete or choosing_upgrade:
		queue_redraw()
		return

	var step_delta := delta * (SMOKE_SPEED_MULTIPLIER if smoke_test_mode else 1.0)
	elapsed_time += step_delta
	invulnerability_left = maxf(0.0, invulnerability_left - step_delta)
	_update_player(step_delta)
	_update_spawning(step_delta)
	_update_attacks(step_delta)
	_update_swords(step_delta)
	_update_enemies(step_delta)
	_update_xp_orbs(step_delta)
	_update_hud()
	queue_redraw()
	if elapsed_time >= DEMO_DURATION_SECONDS:
		_end_run(true)
		return

	if smoke_test_mode and elapsed_time >= SMOKE_TIMEOUT_SECONDS:
		print("SMOKE_FAIL timeout level=", level, " kills=", kills, " enemies=", enemies.size())
		get_tree().quit(1)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed and not touch_active:
			if game_over or demo_complete:
				_reset_run()
				return
			touch_active = true
			touch_index = touch_event.index
			touch_origin = touch_event.position
			touch_position = touch_event.position
		elif not touch_event.pressed and touch_event.index == touch_index:
			touch_active = false
			touch_index = -1
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if touch_active and drag_event.index == touch_index:
			touch_position = drag_event.position
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				if game_over or demo_complete:
					_reset_run()
					return
				touch_active = true
				touch_origin = mouse_button.position
				touch_position = mouse_button.position
			else:
				touch_active = false
	elif event is InputEventMouseMotion and touch_active:
		touch_position = (event as InputEventMouseMotion).position
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
			_reset_run()


func _update_player(delta: float) -> void:
	var direction := Vector2.ZERO
	if smoke_test_mode:
		direction = _smoke_move_direction()
	elif touch_active:
		direction = (touch_position - touch_origin).limit_length(JOYSTICK_RADIUS) / JOYSTICK_RADIUS
	else:
		direction.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		direction.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
		direction = direction.limit_length(1.0)

	player_position += direction * player_speed * delta
	camera.position = player_position


func _smoke_move_direction() -> Vector2:
	var flow := Vector2(sin(elapsed_time * 0.83), cos(elapsed_time * 0.61)).normalized()
	var escape := Vector2.ZERO
	for enemy: Dictionary in enemies:
		var enemy_position: Vector2 = enemy["position"]
		var away := enemy_position.direction_to(player_position)
		var distance := enemy_position.distance_to(player_position)
		if distance < 430.0:
			escape += away * (1.0 - distance / 430.0) * 4.0
	var loot_direction := Vector2.ZERO
	var nearest_loot_distance := INF
	for orb_position in xp_orbs:
		var loot_distance := player_position.distance_to(orb_position)
		if loot_distance < nearest_loot_distance:
			nearest_loot_distance = loot_distance
			loot_direction = player_position.direction_to(orb_position)
	var combined := flow * 0.45 + loot_direction * 1.35 + escape
	return combined.normalized() if combined.length_squared() > 0.0001 else flow


func _update_spawning(delta: float) -> void:
	spawn_left -= delta
	if spawn_left > 0.0:
		return
	spawn_left += _current_spawn_interval()
	_spawn_enemy()


func _spawn_enemy() -> void:
	var phase := _current_wave_phase()
	var wolf_probability := 0.0
	if phase == 2:
		wolf_probability = 0.24
	elif phase == 3:
		wolf_probability = 0.42
	var enemy_kind := ENEMY_WOLF if rng.randf() < wolf_probability else ENEMY_BEETLE
	var radius := WOLF_RADIUS if enemy_kind == ENEMY_WOLF else BEETLE_RADIUS
	var speed := WOLF_SPEED if enemy_kind == ENEMY_WOLF else BEETLE_SPEED
	var contact_damage := WOLF_CONTACT_DAMAGE if enemy_kind == ENEMY_WOLF else BEETLE_CONTACT_DAMAGE

	var half_view := get_viewport_rect().size * 0.5
	var horizontal_edge := half_view.x + radius + 65.0
	var vertical_edge := half_view.y + radius + 65.0
	var spawn_offset := Vector2.ZERO
	match rng.randi_range(0, 3):
		0:
			spawn_offset = Vector2(rng.randf_range(-horizontal_edge, horizontal_edge), -vertical_edge)
		1:
			spawn_offset = Vector2(horizontal_edge, rng.randf_range(-vertical_edge, vertical_edge))
		2:
			spawn_offset = Vector2(rng.randf_range(-horizontal_edge, horizontal_edge), vertical_edge)
		_:
			spawn_offset = Vector2(-horizontal_edge, rng.randf_range(-vertical_edge, vertical_edge))
	enemies.append({
		"position": player_position + spawn_offset,
		"hp": 1,
		"kind": enemy_kind,
		"radius": radius,
		"speed": speed,
		"contact_damage": contact_damage,
	})


func _current_wave_phase() -> int:
	if elapsed_time < 20.0:
		return 1
	if elapsed_time < 50.0:
		return 2
	return 3


func _current_spawn_interval() -> float:
	match _current_wave_phase():
		1:
			return 0.72
		2:
			return 0.46
		_:
			return 0.31


func _current_wave_name() -> String:
	match _current_wave_phase():
		1:
			return "试探"
		2:
			return "群狼混入"
		_:
			return "秘境崩塌"


func _update_attacks(delta: float) -> void:
	attack_left -= delta
	if attack_left > 0.0 or enemies.is_empty():
		return
	attack_left += attack_interval

	var nearest_position: Vector2 = enemies[0]["position"]
	var nearest_distance := player_position.distance_squared_to(nearest_position)
	for enemy: Dictionary in enemies:
		var enemy_position: Vector2 = enemy["position"]
		var distance := player_position.distance_squared_to(enemy_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_position = enemy_position

	var base_direction := player_position.direction_to(nearest_position)
	for index in sword_count:
		var offset := (float(index) - float(sword_count - 1) * 0.5) * 0.14
		swords.append({
			"position": player_position,
			"velocity": base_direction.rotated(offset) * SWORD_SPEED,
			"damage": sword_damage,
		})


func _update_swords(delta: float) -> void:
	for sword_index in range(swords.size() - 1, -1, -1):
		var sword: Dictionary = swords[sword_index]
		var sword_position: Vector2 = sword["position"]
		sword_position += (sword["velocity"] as Vector2) * delta
		sword["position"] = sword_position

		if sword_position.distance_squared_to(player_position) > PROJECTILE_DESPAWN_RADIUS * PROJECTILE_DESPAWN_RADIUS:
			swords.remove_at(sword_index)
			continue

		var hit_index := -1
		for enemy_index in enemies.size():
			var enemy_position: Vector2 = enemies[enemy_index]["position"]
			var enemy_radius := float(enemies[enemy_index]["radius"])
			if sword_position.distance_squared_to(enemy_position) <= pow(SWORD_RADIUS + enemy_radius, 2.0):
				hit_index = enemy_index
				break
		if hit_index < 0:
			continue

		enemies[hit_index]["hp"] = int(enemies[hit_index]["hp"]) - int(sword["damage"])
		swords.remove_at(sword_index)
		if int(enemies[hit_index]["hp"]) <= 0:
			_defeat_enemy(hit_index)


func _defeat_enemy(enemy_index: int) -> void:
	var defeated_position: Vector2 = enemies[enemy_index]["position"]
	enemies.remove_at(enemy_index)
	xp_orbs.append(defeated_position)
	kills += 1


func _update_enemies(delta: float) -> void:
	for enemy: Dictionary in enemies:
		var enemy_position: Vector2 = enemy["position"]
		enemy_position += enemy_position.direction_to(player_position) * float(enemy["speed"]) * delta
		enemy["position"] = enemy_position
		var enemy_radius := float(enemy["radius"])
		if invulnerability_left <= 0.0 and enemy_position.distance_squared_to(player_position) <= pow(PLAYER_RADIUS + enemy_radius, 2.0):
			player_hp -= float(enemy["contact_damage"])
			invulnerability_left = CONTACT_COOLDOWN
			if player_hp <= 0.0:
				_end_run(false)
				return


func _update_xp_orbs(delta: float) -> void:
	for orb_index in range(xp_orbs.size() - 1, -1, -1):
		var orb_position := xp_orbs[orb_index]
		var distance := orb_position.distance_to(player_position)
		if distance <= pickup_radius * 2.4:
			orb_position = orb_position.move_toward(player_position, 520.0 * delta)
			xp_orbs[orb_index] = orb_position
		if orb_position.distance_to(player_position) <= PLAYER_RADIUS + XP_RADIUS:
			xp_orbs.remove_at(orb_index)
			_gain_xp()


func _gain_xp() -> void:
	xp += 1
	var required := _xp_required()
	if xp < required:
		return
	xp -= required
	level += 1
	if first_upgrade_time < 0.0:
		first_upgrade_time = elapsed_time
	_begin_upgrade()


func _xp_required() -> int:
	return 10 + (level - 1) * 4


func _begin_upgrade() -> void:
	if smoke_test_mode:
		_apply_upgrade((level - 2) % 3)
		return
	choosing_upgrade = true
	overlay.visible = true
	overlay_title.text = "修为突破 · 选择一项"
	overlay_subtitle.text = "战斗已暂停，选择后继续试炼"
	choice_buttons[0].text = "青元剑诀\n飞剑数量 +1"
	choice_buttons[1].text = "御剑术\n攻击间隔 -22%"
	choice_buttons[2].text = "罗烟步\n移动速度 +20%"
	for button in choice_buttons:
		button.visible = true


func _on_choice_pressed(choice: int) -> void:
	if game_over or demo_complete:
		_reset_run()
		return
	if choosing_upgrade:
		_apply_upgrade(choice)


func _apply_upgrade(choice: int) -> void:
	match choice:
		0:
			sword_count += 1
		1:
			attack_interval = maxf(0.16, attack_interval * 0.78)
		2:
			player_speed *= 1.2
			pickup_radius *= 1.12
	choosing_upgrade = false
	overlay.visible = false


func _end_run(completed: bool) -> void:
	if completed:
		if smoke_test_mode and level < 4:
			print("SMOKE_FAIL progression level=", level, " kills=", kills, " first_upgrade=", snappedf(first_upgrade_time, 0.01))
			get_tree().quit(1)
			return
		demo_complete = true
		_show_terminal(
			"试炼完成",
			"你撑过了三段敌潮。\n等级 %d · 飞剑 ×%d · 击杀 %d\n\n点击“再试一局”重新挑战。" % [level, sword_count, kills]
		)
		if smoke_test_mode:
			print("SMOKE_PASS level=", level, " kills=", kills, " seconds=", snappedf(elapsed_time, 0.01), " first_upgrade=", snappedf(first_upgrade_time, 0.01))
			get_tree().quit(0)
	else:
		game_over = true
		_show_terminal(
			"试炼失败",
			"走位被妖兽逼入死角。\n用时 %.1f 秒 · 击杀 %d\n\n调整路线，再试一次。" % [elapsed_time, kills]
		)
		if smoke_test_mode:
			print("SMOKE_FAIL defeated level=", level, " kills=", kills, " seconds=", snappedf(elapsed_time, 0.01))
			get_tree().quit(1)


func _show_terminal(title: String, subtitle: String) -> void:
	overlay.visible = true
	overlay_title.text = title
	overlay_subtitle.text = subtitle
	choice_buttons[0].text = "再试一局"
	choice_buttons[0].visible = true
	choice_buttons[1].visible = false
	choice_buttons[2].visible = false


func _reset_run() -> void:
	player_position = Vector2.ZERO
	if is_instance_valid(camera):
		camera.position = player_position
	player_hp = 100.0
	player_speed = BASE_PLAYER_SPEED
	pickup_radius = 62.0
	invulnerability_left = 0.0
	enemies.clear()
	swords.clear()
	xp_orbs.clear()
	elapsed_time = 0.0
	spawn_left = 0.2
	attack_left = 0.1
	attack_interval = BASE_ATTACK_INTERVAL
	sword_count = 1
	sword_damage = 1
	kills = 0
	level = 1
	xp = 0
	first_upgrade_time = -1.0
	choosing_upgrade = false
	game_over = false
	demo_complete = false
	touch_active = false
	overlay.visible = false
	_update_hud()
	queue_redraw()


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	hud_label = Label.new()
	hud_label.position = Vector2(28.0, 22.0)
	hud_label.size = Vector2(664.0, 82.0)
	hud_label.add_theme_font_size_override("font_size", 27)
	hud_label.add_theme_color_override("font_color", Color("e9f6e5"))
	canvas.add_child(hud_label)

	hp_bar_background = ColorRect.new()
	hp_bar_background.color = Color("1b2425")
	canvas.add_child(hp_bar_background)
	hp_bar_fill = ColorRect.new()
	hp_bar_fill.color = Color("d96955")
	hp_bar_background.add_child(hp_bar_fill)

	hint_label = Label.new()
	hint_label.position = Vector2(35.0, 1205.0)
	hint_label.size = Vector2(650.0, 54.0)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.text = "视角跟随韩立 · 拖动移动 · WASD/方向键 · 飞剑自动攻击 · R 重开"
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72, 1.0))
	canvas.add_child(hint_label)

	overlay = ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = VIEW_SIZE
	overlay.color = Color(0.015, 0.03, 0.035, 0.91)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	overlay_title = Label.new()
	overlay_title.position = Vector2(55.0, 250.0)
	overlay_title.size = Vector2(610.0, 80.0)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 38)
	overlay_title.add_theme_color_override("font_color", Color("f4d27a"))
	overlay.add_child(overlay_title)

	overlay_subtitle = Label.new()
	overlay_subtitle.position = Vector2(70.0, 335.0)
	overlay_subtitle.size = Vector2(580.0, 150.0)
	overlay_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_subtitle.add_theme_font_size_override("font_size", 23)
	overlay_subtitle.add_theme_color_override("font_color", Color("d6e8d1"))
	overlay.add_child(overlay_subtitle)

	for choice in 3:
		var button := Button.new()
		button.position = Vector2(70.0, 510.0 + float(choice) * 145.0)
		button.size = Vector2(580.0, 112.0)
		button.add_theme_font_size_override("font_size", 25)
		button.pressed.connect(_on_choice_pressed.bind(choice))
		overlay.add_child(button)
		choice_buttons.append(button)
	overlay.visible = false
	_layout_ui()


func _layout_ui() -> void:
	if not is_instance_valid(overlay):
		return
	var viewport_size := get_viewport_rect().size
	var safe_margin := 28.0
	var content_width := minf(580.0, viewport_size.x - safe_margin * 2.0)
	var content_left := (viewport_size.x - content_width) * 0.5
	var title_width := minf(650.0, viewport_size.x - safe_margin * 2.0)
	var title_left := (viewport_size.x - title_width) * 0.5
	var content_height := 740.0
	var content_top := maxf(95.0, (viewport_size.y - content_height) * 0.5)

	hud_label.position = Vector2(safe_margin, 22.0)
	hud_label.size = Vector2(maxf(1.0, viewport_size.x - safe_margin * 2.0), 82.0)
	hp_bar_background.position = Vector2(safe_margin, 112.0)
	hp_bar_background.size = Vector2(maxf(1.0, viewport_size.x - safe_margin * 2.0), 14.0)
	hp_bar_fill.position = Vector2.ZERO
	hp_bar_fill.size = Vector2(hp_bar_background.size.x * clampf(player_hp / 100.0, 0.0, 1.0), hp_bar_background.size.y)
	hint_label.position = Vector2(safe_margin, viewport_size.y - 75.0)
	hint_label.size = Vector2(maxf(1.0, viewport_size.x - safe_margin * 2.0), 54.0)

	overlay.position = Vector2.ZERO
	overlay.size = viewport_size
	overlay_title.position = Vector2(title_left, content_top)
	overlay_title.size = Vector2(title_width, 80.0)
	overlay_subtitle.position = Vector2(content_left, content_top + 90.0)
	overlay_subtitle.size = Vector2(content_width, 150.0)
	for choice in choice_buttons.size():
		choice_buttons[choice].position = Vector2(content_left, content_top + 270.0 + float(choice) * 145.0)
		choice_buttons[choice].size = Vector2(content_width, 112.0)


func _create_camera() -> void:
	camera = Camera2D.new()
	camera.position = player_position
	camera.position_smoothing_enabled = false
	camera.enabled = true
	add_child(camera)


func _update_hud() -> void:
	if not is_instance_valid(hud_label):
		return
	var seconds_left := maxf(0.0, DEMO_DURATION_SECONDS - elapsed_time)
	hud_label.text = "韩立  Lv.%d    修为 %d/%d    体力 %d    剩余 %d秒\n飞剑 ×%d    击杀 %d    敌潮：%s" % [
		level,
		xp,
		_xp_required(),
		ceili(player_hp),
		ceili(seconds_left),
		sword_count,
		kills,
		_current_wave_name(),
	]
	if is_instance_valid(hp_bar_fill):
		hp_bar_fill.size = Vector2(hp_bar_background.size.x * clampf(player_hp / 100.0, 0.0, 1.0), hp_bar_background.size.y)


func _draw() -> void:
	var visible_size := get_viewport_rect().size
	var visible_world := Rect2(player_position - visible_size * 0.62, visible_size * 1.24)
	draw_rect(visible_world, Color("102c2d"), true)
	var grid_start_x := floorf(visible_world.position.x / GRID_SIZE) * GRID_SIZE
	var grid_start_y := floorf(visible_world.position.y / GRID_SIZE) * GRID_SIZE
	var x := grid_start_x
	while x <= visible_world.end.x:
		draw_line(Vector2(x, visible_world.position.y), Vector2(x, visible_world.end.y), Color(0.18, 0.32, 0.28, 0.22), 1.0)
		x += GRID_SIZE
	var y := grid_start_y
	while y <= visible_world.end.y:
		draw_line(Vector2(visible_world.position.x, y), Vector2(visible_world.end.x, y), Color(0.18, 0.32, 0.28, 0.22), 1.0)
		y += GRID_SIZE

	for orb_position in xp_orbs:
		draw_circle(orb_position, XP_RADIUS + 5.0, Color(0.20, 0.95, 0.78, 0.18))
		draw_circle(orb_position, XP_RADIUS, Color("55edbe"))
	for enemy: Dictionary in enemies:
		var enemy_position: Vector2 = enemy["position"]
		var enemy_radius := float(enemy["radius"])
		if int(enemy["kind"]) == ENEMY_WOLF:
			var wolf_shape := PackedVector2Array([
				enemy_position + Vector2(0.0, -enemy_radius - 5.0),
				enemy_position + Vector2(enemy_radius + 6.0, 4.0),
				enemy_position + Vector2(0.0, enemy_radius + 5.0),
				enemy_position + Vector2(-enemy_radius - 6.0, 4.0),
			])
			draw_colored_polygon(wolf_shape, Color("e17a45"))
			draw_line(enemy_position + Vector2(-7.0, -4.0), enemy_position + Vector2(7.0, -4.0), Color("fff0c2"), 3.0)
		else:
			draw_circle(enemy_position, enemy_radius + 4.0, Color(0.0, 0.0, 0.0, 0.3))
			draw_circle(enemy_position, enemy_radius, Color("a93d49"))
			draw_circle(enemy_position + Vector2(-6.0, -3.0), 2.5, Color("ffe3b0"))
			draw_circle(enemy_position + Vector2(6.0, -3.0), 2.5, Color("ffe3b0"))
	for sword: Dictionary in swords:
		var sword_position: Vector2 = sword["position"]
		var velocity: Vector2 = sword["velocity"]
		draw_line(sword_position - velocity.normalized() * 16.0, sword_position + velocity.normalized() * 12.0, Color("d6f5ff"), 7.0)
		draw_circle(sword_position, SWORD_RADIUS, Color("80d9ef"))

	draw_circle(player_position, pickup_radius, Color(0.32, 0.75, 0.53, 0.055))
	draw_circle(player_position, PLAYER_RADIUS + 5.0, Color(0.0, 0.0, 0.0, 0.35))
	var player_color := Color("f0c66e") if invulnerability_left <= 0.0 else Color("fff1c8")
	draw_circle(player_position, PLAYER_RADIUS, player_color)
	draw_line(player_position + Vector2(-10.0, 7.0), player_position + Vector2(10.0, 7.0), Color("2f3c32"), 4.0)

	if touch_active and not choosing_upgrade:
		var screen_to_world := get_canvas_transform().affine_inverse()
		var joystick_origin := screen_to_world * touch_origin
		var joystick_knob := screen_to_world * (touch_origin + (touch_position - touch_origin).limit_length(JOYSTICK_RADIUS))
		draw_circle(joystick_origin, JOYSTICK_RADIUS, Color(0.76, 0.90, 0.78, 0.13))
		draw_circle(joystick_knob, 32.0, Color(0.76, 0.90, 0.78, 0.42))
