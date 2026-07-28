@tool
class_name GdUnitMessageWriter
extends RefCounted
## Base interface class for writing formatted messages to different outputs.[br]
## [br]
## This class defines the interface and common functionality for writing formatted messages.[br]
## It provides a fluent API for message formatting and supports different output targets.[br]
## [br]
## The class provides formatting options for:[br]
## - Text colors[br]
## - Text styles (bold, italic, underline)[br]
## - Text effects (e.g., wave)[br]
## - Text alignment[br]
## - Indentation[br]
## [br]
## Two concrete implementations are available:[br]
## - [GdUnitRichTextMessageWriter] writing to a [RichTextLabel][br]
## - [GdUnitCSIMessageWriter] writing to console using CSI codes[br]
## [br]
## Example usage:[br]
## [codeblock]
## writer.color(Color.RED).style(BOLD).println_message("Test failed!")
## writer.color(Color.GREEN).align(Align.RIGHT).print_at("Success", 80)
## [/codeblock]


## Text style flag for bold formatting
const BOLD = 0x1
## Text style flag for italic formatting
const ITALIC = 0x2
## Text style flag for underline formatting
const UNDERLINE = 0x4


## Represents special text effects that can be applied to the output
enum Effect {
	## No special effect applied
	NONE,
	## Applies a wave animation to the text
	WAVE
}


## Controls text alignment at the specified cursor position
enum Align {
	## Aligns text to the left of the cursor position
	LEFT,
	## Aligns text to the right of the cursor position, accounting for text length
	RIGHT
}


## The current text color to be used for the next output operation
var _current_color := Color.WHITE

## The current indentation level to be used for the next output operation.[br]
## Each level represents two spaces of indentation.
var _current_indent := 0

## The current text style flags (BOLD, ITALIC, UNDERLINE) to be used for the next output operation
var _current_flags := 0

## The current text alignment to be used for the next output operation
var _current_align := Align.LEFT

## The current text effect to be used for the next output operation
var _current_effect := GdUnitMessageWriter.Effect.NONE


## Sets the text color for the next output operation.[br]
## [br]
## [param value] The color to be used for the text.
## Returns self for method chaining.
func color(value: Color) -> GdUnitMessageWriter:
	_current_color = value
	return self


## Sets the indentation level for the next output operation.[br]
## [br]
## [param value] The number of indentation levels, where each level equals two spaces.
## Returns self for method chaining.
func indent(value: int) -> GdUnitMessageWriter:
	_current_indent = value
	return self


## Sets text style flags for the next output operation.[br]
## [br]
## [param value] A combination of style flags (BOLD, ITALIC, UNDERLINE).
## Returns self for method chaining.
func style(value: int) -> GdUnitMessageWriter:
	_current_flags = value
	return self


## Sets text effect for the next output operation.[br]
## [br]
## [param value] The effect to apply to the text (NONE, WAVE).
## Returns self for method chaining.
func effect(value: GdUnitMessageWriter.Effect) -> GdUnitMessageWriter:
	_current_effect = value
	return self


## Sets text alignment for the next output operation.[br]
## [br]
## [param value] The alignment to use (LEFT, RIGHT).
## Returns self for method chaining.
func align(value: Align) -> GdUnitMessageWriter:
	_current_align = value
	return self


## Resets all formatting options to their default values.[br]
## [br]
## Defaults:[br]
## - color: Color.WHITE[br]
## - indent: 0[br]
## - flags: 0[br]
## - align: LEFT[br]
## - effect: NONE[br]
## Returns self for method chaining.
func reset() -> GdUnitMessageWriter:
	_current_color = Color.WHITE
	_current_indent = 0
	_current_flags = 0
	_current_align = Align.LEFT
	_current_effect = Effect.NONE
	return self


## Prints a warning message in golden color.[br]
## [br]
## [param message] The warning message to print.
func prints_warning(message: String) -> void:
	color(Color.GOLDENROD).println_message(message)


## Prints an error message in crimson color.[br]
## [br]
## [param message] The error message to print.
func prints_error(message: String) -> void:
	color(Color.CRIMSON).println_message(message)


## Prints a message with current formatting settings.[br]
## [br]
## [param message] The text to print.
func print_message(message: String) -> void:
	_print_message(message, _current_color, _current_indent, _current_flags)
	reset()


## Prints a message with current formatting settings followed by a newline.[br]
## [br]
## [param message] The text to print.
func println_message(message: String) -> void:
	_println_message(message, _current_color, _current_indent, _current_flags)
	reset()


## Prints a message at a specific column position with current formatting settings.[br]
## [br]
## [param message] The text to print.[br]
## [param cursor_pos] The column position where the text should start.
func print_at(message: String, cursor_pos: int) -> void:
	_print_at(message, cursor_pos, _current_color, _current_effect, _current_align, _current_flags)
	reset()


## Internal implementation of print_message.[br]
## [br]
## To be overridden by concrete formatters.[br]
## [br]
## [param message] The text to print.[br]
## [param color] The color to use.[br]
## [param indent] The indentation level.[br]
## [param flags] The style flags to apply.
func _print_message(_message: String, _color: Color, _indent: int, _flags: int) -> void:
	pass


## Internal implementation of println_message.[br]
## [br]
## To be overridden by concrete formatters.[br]
## [br]
## [param message] The text to print.[br]
## [param color] The color to use.[br]
## [param indent] The indentation level.[br]
## [param flags] The style flags to apply.
func _println_message(_message: String, _color: Color, _indent: int, _flags: int) -> void:
	pass


## Internal implementation of print_at.[br]
## [br]
## To be overridden by concrete formatters.[br]
## [br]
## [param message] The text to print.[br]
## [param cursor_pos] The column position.[br]
## [param color] The color to use.[br]
## [param effect] The effect to apply.[br]
## [param align] The text alignment.[br]
## [param flags] The style flags to apply.
func _print_at(_message: String, _cursor_pos: int, _color: Color, _effect: GdUnitMessageWriter.Effect, _align: Align, _flags: int) -> void:
	pass


## Clears all output content.[br]
## [br]
## To be overridden by concrete formatters.
func clear() -> void:
	pass
