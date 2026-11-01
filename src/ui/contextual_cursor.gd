class_name ContextualCursor
extends Control
## Contextual crosshair and targeting HUD.
## Dynamically updates reticle shape, color, symbol, and reason tags based on 3D hover targets.

enum Mode {
	DEFAULT,       # Neutral crosshair [+]
	ENEMY,         # Hostile enemy or damageable target [⌖] (Red)
	INTERACT,      # Interactable station within reach [E] (Gold/Teal)
	OUT_OF_RANGE,  # Target beyond weapon or interaction range [∅] (Muted Grey)
	BLOCKED,       # Target obstructed by solid cover/wall [✕] (Amber)
	FRIENDLY,      # Friendly team unit [🛡] (Teal)
}

const COLOR_DEFAULT := Color("e3eaf2")
const COLOR_ENEMY := Color("ff4d4d")
const COLOR_INTERACT := Color("ffd280")
const COLOR_OUT_OF_RANGE := Color("8596a6")
const COLOR_BLOCKED := Color("ff9944")
const COLOR_FRIENDLY := Color("66e0c2")

var current_mode: Mode = Mode.DEFAULT
var current_reason: String = ""
var current_distance: float = 0.0

var _reticle: Label
var _symbol: Label
var _tag: Label
var _pulse := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(40, 40)


func _ready() -> void:
	_reticle = Label.new()
	_reticle.name = "Reticle"
	_reticle.text = "+"
	_reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reticle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reticle.size = Vector2(32, 32)
	_reticle.position = Vector2(-16, -16)
	_reticle.add_theme_font_size_override(&"font_size", 24)
	_reticle.add_theme_color_override(&"font_color", COLOR_DEFAULT)
	_reticle.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_reticle.add_theme_constant_override(&"shadow_offset_x", 1)
	_reticle.add_theme_constant_override(&"shadow_offset_y", 1)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_reticle)

	_symbol = Label.new()
	_symbol.name = "Symbol"
	_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_symbol.position = Vector2(16, -18)
	_symbol.add_theme_font_size_override(&"font_size", 14)
	_symbol.add_theme_color_override(&"font_color", COLOR_DEFAULT)
	_symbol.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_symbol)

	_tag = Label.new()
	_tag.name = "Tag"
	_tag.position = Vector2(16, 2)
	_tag.add_theme_font_size_override(&"font_size", 12)
	_tag.add_theme_color_override(&"font_color", COLOR_DEFAULT)
	_tag.add_theme_color_override(&"font_shadow_color", Color.BLACK)
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tag)

	set_cursor_state(Mode.DEFAULT, "")


func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta * 6.0, 0.0)
		var scale_factor: float = 1.0 + _pulse * 0.25
		_reticle.scale = Vector2(scale_factor, scale_factor)
	else:
		_reticle.scale = Vector2.ONE


## Update cursor presentation based on context.
func set_cursor_state(mode: Mode, reason: String = "", distance: float = 0.0) -> void:
	if mode != current_mode:
		_pulse = 1.0
	current_mode = mode
	current_reason = reason
	current_distance = distance

	var reticle_text := "+"
	var symbol_text := ""
	var tag_text := reason
	var main_color := COLOR_DEFAULT

	match mode:
		Mode.DEFAULT:
			reticle_text = "+"
			main_color = COLOR_DEFAULT
			symbol_text = ""
		Mode.ENEMY:
			reticle_text = "⌖"
			main_color = COLOR_ENEMY
			symbol_text = "HEDEF"
			if distance > 0.0:
				tag_text = "%s (%.1fm)" % [reason if not reason.is_empty() else tr("DÜŞMAN"), distance]
		Mode.INTERACT:
			reticle_text = "◎"
			main_color = COLOR_INTERACT
			symbol_text = "[E]"
			tag_text = reason if not reason.is_empty() else tr("ETKİLEŞİM")
		Mode.OUT_OF_RANGE:
			reticle_text = "∅"
			main_color = COLOR_OUT_OF_RANGE
			symbol_text = "UZAK"
			tag_text = "%s (%.1fm)" % [tr("MENZİL DIŞI"), distance] if distance > 0.0 else tr("MENZİL DIŞI")
		Mode.BLOCKED:
			reticle_text = "✕"
			main_color = COLOR_BLOCKED
			symbol_text = "ENGEL"
			tag_text = tr("SİPER ARKASI")
		Mode.FRIENDLY:
			reticle_text = "◇"
			main_color = COLOR_FRIENDLY
			symbol_text = "DOST"
			tag_text = tr("DOST BİRİM")

	if is_instance_valid(_reticle):
		_reticle.text = reticle_text
		_reticle.add_theme_color_override(&"font_color", main_color)
	if is_instance_valid(_symbol):
		_symbol.text = symbol_text
		_symbol.add_theme_color_override(&"font_color", main_color)
		_symbol.visible = not symbol_text.is_empty()
	if is_instance_valid(_tag):
		_tag.text = tag_text
		_tag.add_theme_color_override(&"font_color", main_color)
		_tag.visible = not tag_text.is_empty()
