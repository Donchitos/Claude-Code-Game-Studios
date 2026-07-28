@tool
class_name GdUnitCSIMessageWriter
extends GdUnitMessageWriter
## A message writer implementation using ANSI/CSI escape codes for console output.[br]
## [br]
## This writer provides formatted message output using CSI (Control Sequence Introducer) codes.[br]
## It supports:[br]
## - Color using RGB values[br]
## - Text styles (bold, italic, underline)[br]
## - Cursor positioning and text alignment[br]
## [br]
## Used primarily for console-based test execution and CI/CD environments.


enum {
	COLOR_TABLE,
	COLOR_RGB
}

const CSI_BOLD = "[1m"
const CSI_ITALIC = "[3m"
const CSI_UNDERLINE = "[4m"
const CSI_RESET = "[0m"

# Control Sequence Introducer
var _debug_show_color_codes := false
var _color_mode := COLOR_TABLE

## Current cursor position in the line
var _current_pos := 0

# Pre-compiled regex patterns for tag matching
var _tag_regex: RegEx


## Constructs CSI style codes based on flags.[br]
## [br]
## [param flags] The style flags to apply (BOLD, ITALIC, UNDERLINE).[br]
## Returns the corresponding CSI codes.
func _apply_style_flags(flags: int) -> String:
	var _style := ""
	if flags & BOLD:
		_style += CSI_BOLD
	if flags & ITALIC:
		_style += CSI_ITALIC
	if flags & UNDERLINE:
		_style += CSI_UNDERLINE
	return _style


## Converts a color string (named or hex) to a Color object
func _parse_color(color_str: String) -> Color:
	return Color.from_string(color_str.strip_edges().to_lower(), Color.WHITE)


## Generates CSI color code for foreground color
func _color_to_csi_fg(c: Color) -> String:
	return "[38;2;%d;%d;%dm" % [c.r8 * c.a, c.g8 * c.a, c.b8 * c.a]


## Generates CSI color code for background color
func _color_to_csi_bg(c: Color) -> String:
	return "[48;2;%d;%d;%dm" % [c.r8 * c.a, c.g8 * c.a, c.b8 * c.a]


func _init_regex_patterns() -> void:
	if not _tag_regex:
		_tag_regex = RegEx.new()
		# Match all richtext tags: [tag], [tag=value], [/tag]
		_tag_regex.compile(r"\[/?(?:color|bgcolor|b|i|u)(?:=[^\]]+)?\]")


func _extract_color_from_tag(tag: String, tag_assign: String) -> Color:
	var tag_assign_length := tag_assign.length()
	var color_value := tag.substr(tag_assign_length, tag.length() - tag_assign_length - 1)
	return _parse_color(color_value)


## Optimized richtext to CSI conversion using regex and lookup processing
func _bbcode_tags_to_csi_codes(message: String) -> String:
	_init_regex_patterns()

	var result := ""
	var last_pos := 0
	var color_stack: Array[Color] = []
	var bgcolor_stack: Array[Color] = []

	# Find all richtext tags
	var matches := _tag_regex.search_all(message)

	for match in matches:
		var start_pos := match.get_start()
		var end_pos := match.get_end()
		var tag := match.get_string(0)

		# Add text before this tag
		result += message.substr(last_pos, start_pos - last_pos)

		# Process the tag
		if tag.begins_with("[color="):
			var fg_color := _extract_color_from_tag(tag, "[color=")
			color_stack.push_back(fg_color)
			result += _color_to_csi_fg(fg_color)
		elif tag.begins_with("[bgcolor="):
			var bg_color := _extract_color_from_tag(tag, "[bgcolor=")
			bgcolor_stack.push_back(bg_color)
			result += _color_to_csi_bg(bg_color)
		elif tag == "[b]":
			result += CSI_BOLD
		elif tag == "[i]":
			result += CSI_ITALIC
		elif tag == "[u]":
			result += CSI_UNDERLINE
		elif tag == "[/color]":
			result += CSI_RESET
			if color_stack.size() > 0:
				color_stack.pop_back()
			# Restore remaining styles and colors
			if color_stack.size() > 0:
				result += _color_to_csi_fg(color_stack[-1])
			if bgcolor_stack.size() > 0:
				result += _color_to_csi_bg(bgcolor_stack[-1])
		elif tag == "[/bgcolor]":
			result += CSI_RESET
			if bgcolor_stack.size() > 0:
				bgcolor_stack.pop_back()
			# Restore remaining styles and colors
			if color_stack.size() > 0:
				result += _color_to_csi_fg(color_stack[-1])
			if bgcolor_stack.size() > 0:
				result += _color_to_csi_bg(bgcolor_stack[-1])
		elif tag in ["[/b]", "[/i]", "[/u]"]:
			result += CSI_RESET
			# Restore remaining colors after style reset
			if color_stack.size() > 0:
				result += _color_to_csi_fg(color_stack[-1])
			if bgcolor_stack.size() > 0:
				result += _color_to_csi_bg(bgcolor_stack[-1])

		last_pos = end_pos

	# Add remaining text after last tag
	result += message.substr(last_pos)

	return result


## Implementation of basic message output with formatting.
func _print_message(_message: String, _color: Color, _indent: int, _flags: int) -> void:
	var text := _bbcode_tags_to_csi_codes(_message)
	var indent_text := "".lpad(_indent * 2)
	var _style := _apply_style_flags(_flags)
	printraw("%s[38;2;%d;%d;%dm%s%s[0m" % [indent_text, _color.r8, _color.g8, _color.b8, _style, text])
	_current_pos += _indent * 2 + text.length()


## Implementation of line-ending message output with formatting.
func _println_message(_message: String, _color: Color, _indent: int, _flags: int) -> void:
	_print_message(_message, _color, _indent, _flags)
	prints()
	_current_pos = 0


## Implementation of positioned message output with formatting.
func _print_at(_message: String, cursor_pos: int, _color: Color, _effect: GdUnitMessageWriter.Effect, _align: Align, _flags: int) -> void:
	if _align == Align.RIGHT:
		cursor_pos = cursor_pos - _message.length()

	if cursor_pos > _current_pos:
		printraw("[%dG" % cursor_pos) # Move cursor to absolute position
	else:
		_message = " " + _message

	var _style := _apply_style_flags(_flags)
	printraw("[38;2;%d;%d;%dm%s%s[0m" % [_color.r8, _color.g8, _color.b8, _style, _message])
	_current_pos = cursor_pos + _message.length()


## Writes a line break and returns self for chaining.
func new_line() -> GdUnitCSIMessageWriter:
	prints()
	return self


## Saves the current cursor position.[br]
## Returns self for chaining.
func save_cursor() -> GdUnitCSIMessageWriter:
	printraw("[s")
	return self


## Restores previously saved cursor position.[br]
## Returns self for chaining.
func restore_cursor() -> GdUnitCSIMessageWriter:
	printraw("[u")
	return self


## Clears screen content and resets cursor position.
func clear() -> void:
	printraw("[2J[H") # Clear screen and move cursor to home
	_current_pos = 0


## Debug method to display the available color table.[br]
## Shows both 6x6x6 color cube and RGB color modes.
@warning_ignore("return_value_discarded")
func _print_color_table() -> void:
	color(Color.ANTIQUE_WHITE).println_message("Color Table 6x6x6")
	_debug_show_color_codes = true
	for green in range(0, 6):
		for red in range(0, 6):
			for blue in range(0, 6):
				color(Color8(red * 42, green * 42, blue * 42)).println_message("████████ ")
			new_line()
		new_line()

	color(Color.ANTIQUE_WHITE).println_message("Color Table RGB")
	_color_mode = COLOR_RGB
	for green in range(0, 6):
		for red in range(0, 6):
			for blue in range(0, 6):
				color(Color8(red * 42, green * 42, blue * 42)).println_message("████████ ")
			new_line()
		new_line()
	_color_mode = COLOR_TABLE
	_debug_show_color_codes = false
