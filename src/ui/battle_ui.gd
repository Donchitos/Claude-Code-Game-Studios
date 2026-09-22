class_name ProductionBattleUI
extends Control

signal pause_requested
signal upgrade_selected(choice: int)
signal battle_active_pause_command(command: Dictionary)

var _hud_label: Label
var _hud_background: ColorRect
var _hp_bar_background: ColorRect
var _hp_bar_fill: ColorRect
var _overlay: ColorRect
var _overlay_title: Label
var _overlay_subtitle: Label
var _pause_button: Button
var _hint: Label
var _damage_notice: Label
var _choice_buttons: Array[Button] = []
var _accessibility_command_id: int = 0
var _accessibility_input_event_id: int = 0
var _screen_generation := 0
var _neutral_waiting := false
var _modal_instruction := ""
const MOVEMENT_HINT := "WASD / 左摇杆移动 · P / Start 暂停 · 飞剑自动攻击"
const NEUTRAL_HINT := "松开方向键并让摇杆回中后，再重新移动。"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_build_overlay()
	get_viewport().size_changed.connect(_layout)
	_layout()

## Binds command identity to the persistent owner's current battle generation.
func configure_generation(generation: int) -> void:
	_screen_generation = generation
	_accessibility_command_id = 0
	_accessibility_input_event_id = 0

## Lists only currently reachable controls for the app-root focus dispatcher.
func focus_buttons() -> Array[Button]:
	if not _overlay.visible:
		return [_pause_button]
	var result: Array[Button] = []
	for button: Button in _choice_buttons:
		if button.visible and not button.disabled:
			result.append(button)
	return result

## Updates the battle presentation snapshot. Example: `ui.update_hud(scope)`.
func update_hud(scope: ProductionBattleScope) -> void:
	_hud_label.text = "韩立  Lv.%d    修为 %d/%d    体力 %d    剩余 %d秒\n飞剑 ×%d    击杀 %d    敌潮：%s" % [
		scope.level,
		scope.xp,
		scope.xp_required(),
		ceili(scope.player.hp),
		ceili(maxf(0.0, scope.duration_seconds - scope.elapsed_time)),
		scope.player.sword_count,
		scope.kills,
		scope.stage.wave_name(scope.elapsed_time),
	]
	if scope.stage.boss_spawn_count > 0 and not scope.stage.boss_defeated:
		_hud_label.text += "  首领 HP %d" % ceili(scope.stage.boss_hp())
	_hp_bar_fill.size.x = _hp_bar_background.size.x * clampf(scope.player.hp / scope.player.max_hp, 0.0, 1.0)
	_damage_notice.visible = scope.player.hit_feedback_left > 0.0
	_damage_notice.text = "受伤 -%s · %s" % [String.num(scope.player.last_damage_amount, 1), scope.player.last_damage_sources]

## Displays the input owner's barrier state without sampling or clearing input.
func set_neutral_waiting(waiting: bool) -> void:
	if waiting == _neutral_waiting:
		return
	_neutral_waiting = waiting
	_refresh_input_hint()

func _refresh_input_hint() -> void:
	_hint.text = NEUTRAL_HINT if _neutral_waiting else MOVEMENT_HINT
	_overlay_subtitle.text = _modal_instruction + ("\n" + NEUTRAL_HINT if _neutral_waiting else "")

## Presents a modal pause surface. Example: `ui.show_pause()`.
func show_pause() -> void:
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.disabled = true
	_overlay.visible = true
	_overlay_title.text = "试炼暂停"
	_modal_instruction = "点击继续、按 R 或确认键返回。"
	_refresh_input_hint()
	_choice_buttons[0].text = "继续试炼"
	_choice_buttons[0].visible = true
	_choice_buttons[1].visible = false
	_choice_buttons[2].visible = false

## Presents the three deterministic level-up choices. Example: `ui.show_upgrade()`.
func show_upgrade() -> void:
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.disabled = true
	_overlay.visible = true
	_overlay_title.text = "修为突破 · 选择一项"
	_modal_instruction = "战斗已暂停，选择后继续试炼"
	_refresh_input_hint()
	_choice_buttons[0].text = "青元剑诀\n飞剑数量 +1"
	_choice_buttons[1].text = "御剑术\n攻击间隔 -22%"
	_choice_buttons[2].text = "罗烟步\n移动速度 +20%"
	for button: Button in _choice_buttons:
		button.visible = true

## Closes any battle modal. Example: `ui.hide_modal()`.
func hide_modal() -> void:
	_overlay.visible = false
	_pause_button.disabled = false
	_pause_button.focus_mode = Control.FOCUS_ALL
	_pause_button.grab_focus()

func _build_hud() -> void:
	_hud_background = ColorRect.new()
	_hud_background.name = "HudBackground"
	_hud_background.position = Vector2.ZERO
	_hud_background.size = Vector2(1280.0, 112.0)
	_hud_background.color = Color(0.025, 0.10, 0.12, 0.92)
	_hud_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_background)
	_hud_label = Label.new()
	_hud_label.position = Vector2(32.0, 14.0)
	_hud_label.size = Vector2(1040.0, 64.0)
	_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_label.add_theme_font_size_override("font_size", 22)
	_hud_label.add_theme_color_override("font_color", Color("e9f6e5"))
	add_child(_hud_label)
	_hp_bar_background = ColorRect.new()
	_hp_bar_background.position = Vector2(32.0, 92.0)
	_hp_bar_background.size = Vector2(1216.0, 10.0)
	_hp_bar_background.color = Color("1b2425")
	_hp_bar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar_background)
	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.size = _hp_bar_background.size
	_hp_bar_fill.color = Color("d96955")
	_hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar_background.add_child(_hp_bar_fill)
	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "暂停"
	_pause_button.tooltip_text = "暂停试炼 (P)"
	_pause_button.pressed.connect(_on_battle_active_pause_pressed)
	add_child(_pause_button)
	_hint = Label.new()
	_hint.text = MOVEMENT_HINT
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72, 1.0))
	add_child(_hint)
	_damage_notice = Label.new()
	_damage_notice.name = "DamageNotice"
	_damage_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_notice.add_theme_font_size_override("font_size", 24)
	_damage_notice.add_theme_color_override("font_color", Color("ffd8af"))
	_damage_notice.add_theme_color_override("font_outline_color", Color("201311"))
	_damage_notice.add_theme_constant_override("outline_size", 6)
	_damage_notice.visible = false
	add_child(_damage_notice)

func _build_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "BattleModal"
	_overlay.color = Color(0.015, 0.03, 0.035, 0.93)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	_overlay_title = Label.new()
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_title.add_theme_font_size_override("font_size", 38)
	_overlay_title.add_theme_color_override("font_color", Color("f4d27a"))
	_overlay.add_child(_overlay_title)
	_overlay_subtitle = Label.new()
	_overlay_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_overlay_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay_subtitle.add_theme_font_size_override("font_size", 23)
	_overlay_subtitle.add_theme_color_override("font_color", Color("d6e8d1"))
	_overlay.add_child(_overlay_subtitle)
	for choice in 3:
		var button := Button.new()
		button.name = "Choice%d" % choice
		button.add_theme_font_size_override("font_size", 25)
		button.pressed.connect(_on_choice_pressed.bind(choice))
		_overlay.add_child(button)
		_choice_buttons.append(button)
	_overlay.visible = false

func _layout() -> void:
	if _overlay == null:
		return
	var viewport_size := get_viewport_rect().size
	var safe_margin := clampf(minf(viewport_size.x, viewport_size.y) * 0.04, 20.0, 48.0)
	var hud_height := clampf(viewport_size.y * 0.16, 96.0, 122.0)
	var pause_width := clampf(viewport_size.x * 0.09, 92.0, 124.0)
	_hud_background.size = Vector2(viewport_size.x, hud_height)
	_hud_label.position = Vector2(safe_margin, 12.0)
	_hud_label.size = Vector2(maxf(1.0, viewport_size.x - safe_margin * 2.0 - pause_width - 24.0), hud_height - 30.0)
	_hp_bar_background.position = Vector2(safe_margin, hud_height - 18.0)
	_hp_bar_background.size.x = maxf(1.0, viewport_size.x - safe_margin * 2.0)
	_pause_button.position = Vector2(viewport_size.x - safe_margin - pause_width, 14.0)
	_pause_button.size = Vector2(pause_width, maxf(48.0, hud_height - 42.0))
	_hint.position = Vector2(safe_margin, viewport_size.y - 44.0)
	_hint.size = Vector2(maxf(1.0, viewport_size.x - safe_margin * 2.0), 30.0)
	_damage_notice.position = Vector2(safe_margin, hud_height + 8.0)
	_damage_notice.size = Vector2(maxf(1.0, viewport_size.x - safe_margin * 2.0), 38.0)
	var content_width := minf(760.0, viewport_size.x - safe_margin * 2.0)
	var content_left := (viewport_size.x - content_width) * 0.5
	var modal_height := 500.0
	var content_top := maxf(hud_height + 20.0, (viewport_size.y - modal_height) * 0.5)
	_overlay.position = Vector2.ZERO
	_overlay.size = viewport_size
	_overlay_title.position = Vector2(content_left, content_top)
	_overlay_title.size = Vector2(content_width, 64.0)
	_overlay_subtitle.position = Vector2(content_left, content_top + 70.0)
	_overlay_subtitle.size = Vector2(content_width, 88.0)
	for choice in _choice_buttons.size():
		_choice_buttons[choice].position = Vector2(content_left, content_top + 174.0 + float(choice) * 102.0)
		_choice_buttons[choice].size = Vector2(content_width, 86.0)

func _on_choice_pressed(choice: int) -> void:
	upgrade_selected.emit(choice)

func _on_battle_active_pause_pressed() -> void:
	if _screen_generation < 1 or _accessibility_command_id == 9223372036854775807:
		return
	_accessibility_command_id += 1
	_accessibility_input_event_id += 1
	battle_active_pause_command.emit({
		"schema_version": 1,
		"command_id": _accessibility_command_id,
		"input_event_id": _accessibility_input_event_id,
		"screen_id": 8,
		"screen_generation": _screen_generation,
		"layout_generation": 1,
		"node_id": 7001,
		"command_kind": 1,
		"pause_reason": 1,
		"source": 1,
		"enabled": true,
	})
