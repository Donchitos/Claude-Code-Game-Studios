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
var _choice_buttons: Array[Button] = []
var _accessibility_command_id: int = 0
var _accessibility_input_event_id: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_hud()
	_build_overlay()
	get_viewport().size_changed.connect(_layout)
	_layout()

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
	_hp_bar_fill.size.x = _hp_bar_background.size.x * clampf(scope.player.hp / scope.player.max_hp, 0.0, 1.0)

## Presents a modal pause surface. Example: `ui.show_pause()`.
func show_pause() -> void:
	_overlay.visible = true
	_overlay_title.text = "试炼暂停"
	_overlay_subtitle.text = "移动输入已关闭。继续后只接受新的触摸。"
	_choice_buttons[0].text = "继续试炼"
	_choice_buttons[0].visible = true
	_choice_buttons[1].visible = false
	_choice_buttons[2].visible = false

## Presents the three deterministic level-up choices. Example: `ui.show_upgrade()`.
func show_upgrade() -> void:
	_overlay.visible = true
	_overlay_title.text = "修为突破 · 选择一项"
	_overlay_subtitle.text = "战斗已暂停，选择后继续试炼"
	_choice_buttons[0].text = "青元剑诀\n飞剑数量 +1"
	_choice_buttons[1].text = "御剑术\n攻击间隔 -22%"
	_choice_buttons[2].text = "罗烟步\n移动速度 +20%"
	for button: Button in _choice_buttons:
		button.visible = true

## Closes any battle modal. Example: `ui.hide_modal()`.
func hide_modal() -> void:
	_overlay.visible = false

func _build_hud() -> void:
	_hud_background = ColorRect.new()
	_hud_background.name = "HudBackground"
	_hud_background.position = Vector2.ZERO
	_hud_background.size = Vector2(720.0, 138.0)
	_hud_background.color = Color(0.025, 0.10, 0.12, 0.92)
	_hud_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_background)
	_hud_label = Label.new()
	_hud_label.position = Vector2(28.0, 22.0)
	_hud_label.size = Vector2(585.0, 82.0)
	_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_label.add_theme_font_size_override("font_size", 27)
	_hud_label.add_theme_color_override("font_color", Color("e9f6e5"))
	add_child(_hud_label)
	_hp_bar_background = ColorRect.new()
	_hp_bar_background.position = Vector2(28.0, 112.0)
	_hp_bar_background.size = Vector2(664.0, 14.0)
	_hp_bar_background.color = Color("1b2425")
	_hp_bar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bar_background)
	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.size = _hp_bar_background.size
	_hp_bar_fill.color = Color("d96955")
	_hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar_background.add_child(_hp_bar_fill)
	var pause_button := Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = "暂停"
	pause_button.tooltip_text = "暂停试炼"
	pause_button.position = Vector2(612.0, 24.0)
	pause_button.size = Vector2(80.0, 66.0)
	pause_button.pressed.connect(_on_battle_active_pause_pressed)
	add_child(pause_button)
	var hint := Label.new()
	hint.text = "拖动左侧区域移动 · 飞剑自动攻击"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(28.0, 1190.0)
	hint.size = Vector2(664.0, 52.0)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 19)
	hint.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72, 1.0))
	add_child(hint)

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
	var safe_margin := 28.0
	var content_width := minf(580.0, viewport_size.x - safe_margin * 2.0)
	var content_left := (viewport_size.x - content_width) * 0.5
	var content_top := maxf(95.0, (viewport_size.y - 740.0) * 0.5)
	_hud_background.size.x = viewport_size.x
	_hp_bar_background.size.x = maxf(1.0, viewport_size.x - safe_margin * 2.0)
	_overlay.position = Vector2.ZERO
	_overlay.size = viewport_size
	_overlay_title.position = Vector2(content_left, content_top)
	_overlay_title.size = Vector2(content_width, 80.0)
	_overlay_subtitle.position = Vector2(content_left, content_top + 90.0)
	_overlay_subtitle.size = Vector2(content_width, 150.0)
	for choice in _choice_buttons.size():
		_choice_buttons[choice].position = Vector2(content_left, content_top + 270.0 + float(choice) * 145.0)
		_choice_buttons[choice].size = Vector2(content_width, 112.0)

func _on_choice_pressed(choice: int) -> void:
	upgrade_selected.emit(choice)

func _on_battle_active_pause_pressed() -> void:
	_accessibility_command_id += 1
	_accessibility_input_event_id += 1
	battle_active_pause_command.emit({
		"schema_version": 1,
		"command_id": _accessibility_command_id,
		"input_event_id": _accessibility_input_event_id,
		"screen_id": 8,
		"screen_generation": 1,
		"layout_generation": 1,
		"node_id": 7001,
		"command_kind": 1,
		"pause_reason": 1,
		"source": 1,
		"enabled": true,
	})
