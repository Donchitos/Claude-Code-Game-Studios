class_name ProductionHomeScreen
extends Control

signal start_requested
signal progression_purchase_requested(branch_id: int)

var _title: Label
var _subtitle: Label
var _start_button: Button
var _wallet_label: Label
var _progression_status: Label
var _branch_buttons: Array[Button] = []
var _pending_branch_id := 0

const BRANCH_NAMES := ["青元剑诀", "长春功", "大衍诀"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("071a20")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_title = Label.new()
	var title := _title
	title.text = "掌天试炼"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(40.0, 285.0)
	title.size = Vector2(640.0, 90.0)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("f4d27a"))
	add_child(title)
	_subtitle = Label.new()
	var subtitle := _subtitle
	subtitle.text = "八段妖潮 · 十二分钟守阵妖兽 · 击败首领通关"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(40.0, 390.0)
	subtitle.size = Vector2(640.0, 60.0)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color("b8d5c5"))
	add_child(subtitle)
	_wallet_label = Label.new()
	_wallet_label.name = "ProgressionWalletLabel"
	_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wallet_label.add_theme_font_size_override("font_size", 22)
	_wallet_label.add_theme_color_override("font_color", Color("f4d27a"))
	add_child(_wallet_label)
	for branch_index in 3:
		var branch_button := Button.new()
		branch_button.name = "ProgressionBranch%dButton" % (branch_index + 1)
		branch_button.add_theme_font_size_override("font_size", 19)
		var branch_id := branch_index + 1
		branch_button.pressed.connect(func() -> void: _on_branch_pressed(branch_id))
		_branch_buttons.append(branch_button)
		add_child(branch_button)
	_progression_status = Label.new()
	_progression_status.name = "ProgressionStatusLabel"
	_progression_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progression_status.add_theme_font_size_override("font_size", 18)
	_progression_status.add_theme_color_override("font_color", Color("b8d5c5"))
	add_child(_progression_status)
	_start_button = Button.new()
	var start_button := _start_button
	start_button.name = "StartBattleButton"
	start_button.text = "进入试炼"
	start_button.tooltip_text = "开始掌天试炼"
	start_button.position = Vector2(110.0, 600.0)
	start_button.size = Vector2(500.0, 112.0)
	start_button.add_theme_font_size_override("font_size", 30)
	start_button.pressed.connect(func() -> void: start_requested.emit())
	add_child(start_button)
	get_viewport().size_changed.connect(_layout)
	_layout()
	present_progression({})

## Refreshes Home presentation from the durable Progression domain snapshot.
func present_progression(domain: Dictionary, message: String = "") -> void:
	if _wallet_label == null:
		return
	var balance := int(domain.get("unspent_pages", 0))
	var levels_value: Variant = domain.get("branch_levels", [0, 0, 0])
	var levels: Array = levels_value as Array if levels_value is Array and (levels_value as Array).size() == 3 else [0, 0, 0]
	_wallet_label.text = "功法残页：%d" % balance
	for branch_index in 3:
		var level := int(levels[branch_index])
		var button := _branch_buttons[branch_index]
		if level >= 5:
			button.text = "%s  L5 · 圆满" % BRANCH_NAMES[branch_index]
			button.disabled = true
			button.tooltip_text = "%s已修炼圆满" % BRANCH_NAMES[branch_index]
		else:
			var cost := 4 * (level + 1)
			button.text = "%s  L%d→L%d · %d页" % [BRANCH_NAMES[branch_index], level, level + 1, cost]
			button.disabled = balance < cost
			button.tooltip_text = "购买%s下一层，需要%d页" % [BRANCH_NAMES[branch_index], cost]
	_pending_branch_id = 0
	_progression_status.text = message if not message.is_empty() else "点击功法后再次确认购买；加成从下一局生效"

func _on_branch_pressed(branch_id: int) -> void:
	if branch_id < 1 or branch_id > _branch_buttons.size() or _branch_buttons[branch_id - 1].disabled:
		return
	if _pending_branch_id != branch_id:
		_pending_branch_id = branch_id
		_progression_status.text = "再次点击确认修炼「%s」" % BRANCH_NAMES[branch_id - 1]
		return
	_pending_branch_id = 0
	progression_purchase_requested.emit(branch_id)

func _layout() -> void:
	if _start_button == null:
		return
	var viewport_size := get_viewport_rect().size
	var content_width := minf(760.0, viewport_size.x - 48.0)
	var left := (viewport_size.x - content_width) * 0.5
	_title.position = Vector2(left, viewport_size.y * 0.12)
	_title.size = Vector2(content_width, 90.0)
	_subtitle.position = Vector2(left, viewport_size.y * 0.23)
	_subtitle.size = Vector2(content_width, 60.0)
	_wallet_label.position = Vector2(left, viewport_size.y * 0.34)
	_wallet_label.size = Vector2(content_width, 42.0)
	var button_gap := 12.0
	var branch_width := (content_width - button_gap * 2.0) / 3.0
	for branch_index in _branch_buttons.size():
		_branch_buttons[branch_index].position = Vector2(left + (branch_width + button_gap) * branch_index, viewport_size.y * 0.42)
		_branch_buttons[branch_index].size = Vector2(branch_width, 68.0)
	_progression_status.position = Vector2(left, viewport_size.y * 0.54)
	_progression_status.size = Vector2(content_width, 40.0)
	_start_button.position = Vector2(left + content_width * 0.15, viewport_size.y * 0.68)
	_start_button.size = Vector2(content_width * 0.70, 96.0)
