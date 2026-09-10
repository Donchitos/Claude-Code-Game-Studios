class_name ProductionHomeScreen
extends Control

signal start_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("071a20")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var title := Label.new()
	title.text = "掌天试炼"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(40.0, 285.0)
	title.size = Vector2(640.0, 90.0)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("f4d27a"))
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "韩立 · 三段妖潮 · 七十五秒生存"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(40.0, 390.0)
	subtitle.size = Vector2(640.0, 60.0)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color("b8d5c5"))
	add_child(subtitle)
	var start_button := Button.new()
	start_button.name = "StartBattleButton"
	start_button.text = "进入试炼"
	start_button.tooltip_text = "开始掌天试炼"
	start_button.position = Vector2(110.0, 600.0)
	start_button.size = Vector2(500.0, 112.0)
	start_button.add_theme_font_size_override("font_size", 30)
	start_button.pressed.connect(func() -> void: start_requested.emit())
	add_child(start_button)

