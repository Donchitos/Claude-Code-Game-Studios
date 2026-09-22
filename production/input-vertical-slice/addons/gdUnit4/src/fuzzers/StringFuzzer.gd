## A fuzzer that generates random strings with configurable length and character sets.[br]
##
## It supports custom character sets defined by patterns or ranges,
## making it ideal for testing input validation, text processing, parsers, or any
## code that handles string data.[br]
##
## The fuzzer uses a pattern syntax to define allowed characters:[br]
## - Single characters: [code]abc[/code] allows 'a', 'b', 'c'[br]
## - Ranges: [code]a-z[/code] allows lowercase letters[br]
## - Special patterns: [code]\\w[/code] (word chars), [code]\\p{L}[/code] (letters), [code]\\p{N}[/code] (numbers)[br]
##
## [b]Usage example:[/b]
## [codeblock]
## # Test with alphanumeric strings
## func test_username(fuzzer := StringFuzzer.new(3, 20, "a-zA-Z0-9"), _fuzzer_iterations := 100):
##     var username _= fuzzer.next_value()
##     assert_bool(validate_username(username)).is_true()
##
## # Test with special characters
## func test_password(fuzzer := StringFuzzer.new(8, 32, "a-zA-Z0-9!@#$%"), _fuzzer_iterations := 100) -> void:
##     var password := fuzzer.next_value()
##     assert_str(password).has_length(8, Comparator.GREATER_EQUAL).has_length(32, Comparator.LESS_EQUAL)
## [/codeblock]
class_name StringFuzzer
extends Fuzzer

## Default character set pattern including word characters, letters, numbers, and common symbols.[br]
## Includes: word characters (\\w), Unicode letters (\\p{L}), Unicode numbers (\\p{N}),
## and the characters: +, -, _, '
const DEFAULT_CHARSET = "\\w\\p{L}\\p{N}+-_'"

## Minimum length for generated strings (inclusive).
var _min_length: int
## Maximum length for generated strings (inclusive).
var _max_length: int
## Array of character codes that can be used in generated strings.
var _charset: PackedInt32Array


func _init(min_length: int, max_length: int, pattern: String = DEFAULT_CHARSET) -> void:
	_min_length = min_length
	_max_length = max_length + 1 # +1 for inclusive
	assert(not null or not pattern.is_empty())
	assert(_min_length > 0 and _min_length < _max_length)
	_charset = _extract_charset(pattern)


## Generates a random string based on configured parameters.[br]
##
## Creates a string with random length between [member _min_length] and
## [member _max_length], using only characters from the configured charset.
## Each character is selected randomly and independently.[br]
##
## [b]Example:[/b]
## [codeblock]
## var fuzzer = StringFuzzer.new(5, 10, "ABC")
## for i in range(5):
##     var str = fuzzer.next_value()
##     print("Generated: ", str)
##     # Possible outputs: "ABCAB", "BCAABCA", "CCCBAA", etc.
##     assert(str.length() >= 5 and str.length() <= 10)
##     for c in str:
##         assert(c in ["A", "B", "C"])
## [/codeblock]
##
## @returns A random string matching the configured constraints.
func next_value() -> String:
	var value := PackedInt32Array()
	var max_char := len(_charset)
	var length: int = max(_min_length, randi() % _max_length)
	for i in length:
		@warning_ignore("return_value_discarded")
		value.append(_charset[randi() % max_char])
	return value.to_byte_array().get_string_from_utf32()


static func _extract_charset(pattern: String) -> PackedInt32Array:
	var reg := RegEx.new()
	if reg.compile(pattern) != OK:
		push_error("Invalid pattern to generate Strings! Use e.g  '\\w\\p{L}\\p{N}+-_'")
		return PackedInt32Array()

	var charset := PackedInt32Array()
	var char_before := -1
	var index := 0
	while index < pattern.length():
		var char_current := pattern.unicode_at(index)
		# - range token at first or last pos?
		if char_current == 45 and (index == 0 or index == pattern.length()-1):
			charset.append(char_current)
			index += 1
			continue
		index += 1
		# range starts
		if char_current == 45 and char_before != -1:
			var char_next := pattern.unicode_at(index)
			var characters := _build_chars(char_before, char_next)
			for character in characters:
				charset.append(character)
			char_before = -1
			index += 1
			continue
		char_before = char_current
		charset.append(char_current)
	return charset


static func _build_chars(from: int, to: int) -> PackedInt32Array:
	var characters := PackedInt32Array()
	for character in range(from+1, to+1):
		characters.append(character)
	return characters
