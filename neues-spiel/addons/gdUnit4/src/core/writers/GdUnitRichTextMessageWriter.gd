@tool
class_name GdUnitRichTextMessageWriter
extends GdUnitMessageWriter
## A message writer implementation using [RichTextLabel] for the test report UI.[br]
## [br]
## This writer implementation writes formatted messages to a [RichTextLabel] using BBCode.[br]
## It supports:[br]
## - Text formatting using BBCode (bold, italic, underline)[br]
## - Text coloring using push colors[br]
## - Text indentation using push indent[br]
## - Text effects like wave[br]
## - Basic cursor positioning[br]
## [br]
## Used to format test reports in the editor UI.


## The [RichTextLabel] instance to write formatted messages
var _output: RichTextLabel

## Tracks current position in characters from line start
var _current_pos := 0


## Creates a new message writer for the given [RichTextLabel].[br]
## [br]
## [param output] The [RichTextLabel] used for output.
func _init(output: RichTextLabel) -> void:
	_output = output


## Applies text style flags by wrapping text in BBCode tags.[br]
## [br]
## Available styles:[br]
## - BOLD: [b]text[/b][br]
## - ITALIC: [i]text[/i][br]
## - UNDERLINE: [u]text[/u][br]
## [br]
## [param message] The text to format.[br]
## [param flags] The text style flags to apply.
func _apply_flags(message: String, flags: int) -> String:
	if flags & BOLD:
		message = "[b]%s[/b]" % message
	if flags & ITALIC:
		message = "[i]%s[/i]" % message
	if flags & UNDERLINE:
		message = "[u]%s[/u]" % message
	return message


## Writes a message with formatting.[br]
## [br]
## [param message] The text to write.[br]
## [param _color] The color to use.[br]
## [param _indent] The indentation level.[br]
## [param flags] The text style flags to apply.
func _print_message(message: String, _color: Color, _indent: int, flags: int) -> void:
	for i in _indent:
		_output.push_indent(1)
	_output.push_color(_color)
	message = _apply_flags(message, flags)
	_output.append_text(message)
	_output.pop()
	for i in _indent:
		_output.pop()
	_current_pos += _indent * 2 + message.length()


## Writes a message with formatting followed by a line break.[br]
## [br]
## [param message] The text to write.[br]
## [param _color] The color to use.[br]
## [param _indent] The indentation level.[br]
## [param flags] The text style flags to apply.
func _println_message(message: String, _color: Color, _indent: int, flags: int) -> void:
	_print_message(message, _color, _indent, flags)
	_output.newline()
	_current_pos = 0


## Writes a message at a specific column position.[br]
## [br]
## [param message] The text to write.[br]
## [param cursor_pos] The column position from line start.[br]
## [param _color] The color to use.[br]
## [param _effect] The text effect to apply (e.g. wave).[br]
## [param _align] The text alignment (left or right).[br]
## [param flags] The text style flags to apply.
func _print_at(message: String, cursor_pos: int, _color: Color, _effect: GdUnitMessageWriter.Effect, _align: Align, flags: int) -> void:
	if _align == Align.RIGHT:
		cursor_pos = cursor_pos - message.length()

	var spaces := cursor_pos - _current_pos
	if spaces > 0:
		_output.append_text("".lpad(spaces))
		_current_pos += spaces
	else:
		_output.append_text(" ")
		_current_pos += 1

	_output.push_color(_color)
	message = _apply_flags(message, flags)
	match _effect:
		Effect.NONE:
			pass
		Effect.WAVE:
			message = "[wave]%s[/wave]" % message
	_output.append_text(message)
	_output.pop()
	_current_pos += message.length()


## Clears all written content from the [RichTextLabel].
func clear() -> void:
	_output.clear()
	_current_pos = 0
