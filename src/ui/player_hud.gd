extends Control
## Minimal health/ammunition overlay; mouse-position crosshair preserves lab aiming.

const CombatScript = preload("res://src/combat/player_combat.gd")
const ContextualCursorScript = preload("res://src/ui/contextual_cursor.gd")
const ActiveReloadBarScript = preload("res://src/ui/active_reload_bar.gd")

var _state: CombatScript
var _bar: ProgressBar
var _ammo: Label
var _crosshair: Label
var _animation: Tween
var _paused := false
var _weapon_name := "Tabanca"
var _shield: Label
var _context: Label
var _hit_marker: Label
var _hit_age := 0.0
var _reload: Label
var _cursor: ContextualCursorScript
var _active_reload_bar: ActiveReloadBarScript
var _role: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar = ProgressBar.new()
	_bar.name = "HealthBar"
	_bar.position = Vector2(28, 24)
	_bar.size = Vector2(238, 24)
	_bar.show_percentage = false
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("291114")
	frame.border_color = Color.BLACK
	frame.set_border_width_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("e52b36")
	fill.content_margin_left = 3.0
	fill.content_margin_right = 3.0
	fill.content_margin_top = 3.0
	fill.content_margin_bottom = 3.0
	_bar.add_theme_stylebox_override(&"background", frame)
	_bar.add_theme_stylebox_override(&"fill", fill)
	add_child(_bar)
	_ammo = Label.new()
	_ammo.name = "Ammo"
	add_child(_ammo)
	_ammo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_ammo.offset_left = -210.0
	_ammo.offset_top = -100.0
	_ammo.offset_right = -28.0
	_ammo.offset_bottom = -24.0
	_ammo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ammo.add_theme_font_size_override(&"font_size", 26)
	_ammo.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_ammo.add_theme_constant_override(&"shadow_offset_x", 1)
	_ammo.add_theme_constant_override(&"shadow_offset_y", 2)
	_ammo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair = Label.new()
	_crosshair.name = "Crosshair"
	_crosshair.text = "+"
	_crosshair.size = Vector2(24, 28)
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crosshair.add_theme_font_size_override(&"font_size", 24)
	_crosshair.add_theme_color_override(&"font_color", Color.WHITE)
	_crosshair.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_crosshair.add_theme_constant_override(&"shadow_offset_x", 1)
	_crosshair.add_theme_constant_override(&"shadow_offset_y", 1)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)
	_shield = Label.new()
	_shield.add_theme_color_override(&"font_color", Color("66e0c2"))
	add_child(_shield)
	_shield.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_shield.offset_left = -230.0
	_shield.offset_right = -28.0
	_shield.offset_top = -132.0
	_shield.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_context = Label.new()
	_context.add_theme_font_size_override(&"font_size", 18)
	add_child(_context)
	_context.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_context.offset_left = -240.0
	_context.offset_right = 240.0
	_context.offset_top = -105.0
	_context.offset_bottom = -75.0
	_context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hit_marker = Label.new()
	_hit_marker.text = "×"
	_hit_marker.add_theme_font_size_override(&"font_size", 28)
	_hit_marker.add_theme_color_override(&"font_color", Color("ffae73"))
	_hit_marker.visible = false
	add_child(_hit_marker)
	_cursor = ContextualCursorScript.new()
	_cursor.name = "ContextualCursor"
	add_child(_cursor)
	_reload = Label.new()
	_reload.name = "ReloadStatus"
	_reload.add_theme_color_override(&"font_color", Color("ffae73"))
	add_child(_reload)
	_reload.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_reload.offset_left = -270.0
	_reload.offset_right = -28.0
	_reload.offset_top = -165.0
	_reload.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_active_reload_bar = ActiveReloadBarScript.new()
	_active_reload_bar.name = "ActiveReloadBar"
	add_child(_active_reload_bar)
	_active_reload_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_active_reload_bar.offset_left = -220.0
	_active_reload_bar.offset_right = -30.0
	_active_reload_bar.offset_top = -140.0
	_role = Label.new()
	_role.name = "RoleStatus"
	_role.add_theme_font_size_override(&"font_size", 16)
	_role.add_theme_color_override(&"font_color", Color("66e0c2"))
	_role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_role)
	_role.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_role.offset_left = -280.0
	_role.offset_right = 280.0
	_role.offset_top = -185.0
	_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _process(delta: float) -> void:
	if not _paused:
		_hit_age = maxf(_hit_age - delta, 0.0)
	_hit_marker.visible = _hit_age > 0.0
	_hit_marker.position = get_viewport().get_mouse_position() + Vector2(14, -22)
	var focused: bool = get_window().has_focus()
	var point: Vector2 = get_viewport().get_mouse_position()
	var visible_now: bool = focused and not _paused and get_viewport_rect().has_point(point)
	if is_instance_valid(_cursor):
		_cursor.visible = visible_now
		_cursor.position = point
	_crosshair.visible = false
	if focused:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if visible_now else Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Bind an individual player's state, not the shared resource asset.
func bind_state(state: CombatScript) -> void:
	if _state != null:
		_state.health_changed.disconnect(_on_health_changed)
		_state.ammo_changed.disconnect(_on_ammo_changed)
		_state.shield_changed.disconnect(_on_shield_changed)
		_state.reload_changed.disconnect(_on_reload_changed)
	_state = state
	_state.health_changed.connect(_on_health_changed)
	_state.ammo_changed.connect(_on_ammo_changed)
	_state.shield_changed.connect(_on_shield_changed)
	_state.reload_changed.connect(_on_reload_changed)
	if is_instance_valid(_active_reload_bar):
		_active_reload_bar.bind_state(_state)
	reset_display()


## Reset cancels outstanding damage animation instead of animating a refill.
func reset_display() -> void:
	if is_instance_valid(_animation):
		_animation.kill()
	_animation = null
	_bar.max_value = maxf(_state.max_health, 1.0)
	_bar.value = _state.health
	_on_ammo_changed(_state.ammo, _state.magazine_capacity)
	_on_shield_changed(_state.shield, _state.max_shield)
	_on_reload_changed(_state.reload_remaining)
	_hit_age = 0.0


## Freeze the current damage animation alongside the laboratory.
func set_paused(value: bool) -> void:
	_paused = value
	if is_instance_valid(_animation):
		if value:
			_animation.pause()
		else:
			_animation.play()


func set_cursor_context(mode: int, reason: String = "", distance: float = 0.0) -> void:
	if is_instance_valid(_cursor):
		_cursor.set_cursor_state(mode, reason, distance)


func _on_health_changed(current: float, maximum: float) -> void:
	if is_instance_valid(_animation):
		_animation.kill()
	_bar.max_value = maxf(maximum, 1.0)
	_animation = create_tween()
	_animation.finished.connect(func(): _animation = null)
	_animation.tween_property(_bar, "value", current, maxf(_state.health_animation_duration, 0.001)) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _paused:
		_animation.pause()


func _on_ammo_changed(current: int, capacity: int) -> void:
	_ammo.text = tr(_weapon_name) + "\n%d / %d" % [current, capacity]
	_ammo.add_theme_color_override(&"font_color", Color("ffae73") if current == 0 else Color.WHITE)


## Display profile changes without modifying the weapon state.
func show_weapon(profile: Resource) -> void:
	_weapon_name = profile.display_name
	_on_ammo_changed(_state.ammo, _state.magazine_capacity)


## Preserve the simple plus while showing contextual instruction separately.
func show_context(text: String) -> void:
	_context.text = text


## Confirm only damage-producing impacts, not misses or protected teammates.
func show_hit() -> void:
	_hit_age = 0.10


func _on_shield_changed(current: float, maximum: float) -> void:
	_shield.text = tr("Kalkan") + " ◇ %d / %d" % [int(current), int(maximum)]


func _on_reload_changed(remaining: float) -> void:
	_reload.text = tr("Şarjör değiştiriliyor") + " %.1f s" % remaining if remaining > 0.0 else ""
	_reload.visible = remaining > 0.0


## Present role/cooldown observations without owning ability state.
func show_role(text: String) -> void:
	_role.text = text
