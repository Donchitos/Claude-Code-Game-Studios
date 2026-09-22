# GdUnit generated TestSuite
class_name StringFuzzerTest
extends GdUnitTestSuite


func test_extract_charset() -> void:
	assert_str(StringFuzzer._extract_charset("abc").to_byte_array().get_string_from_utf32()).is_equal("abc")
	assert_str(StringFuzzer._extract_charset("abcDXG").to_byte_array().get_string_from_utf32()).is_equal("abcDXG")
	assert_str(StringFuzzer._extract_charset("a-c").to_byte_array().get_string_from_utf32()).is_equal("abc")
	assert_str(StringFuzzer._extract_charset("a-z").to_byte_array().get_string_from_utf32()).is_equal("abcdefghijklmnopqrstuvwxyz")
	assert_str(StringFuzzer._extract_charset("A-Z").to_byte_array().get_string_from_utf32()).is_equal("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	# unicode
	assert_str(StringFuzzer._extract_charset("abc日本語DXG").to_byte_array().get_string_from_utf32()).is_equal("abc日本語DXG")

	# range token at start
	assert_str(StringFuzzer._extract_charset("-a-dA-D2-8+_").to_byte_array().get_string_from_utf32()).is_equal("-abcdABCD2345678+_")
	# range token at end
	assert_str(StringFuzzer._extract_charset("a-dA-D2-8+_-").to_byte_array().get_string_from_utf32()).is_equal("abcdABCD2345678+_-")
	# range token in the middle
	assert_str(StringFuzzer._extract_charset("a-d-A-D2-8+_").to_byte_array().get_string_from_utf32()).is_equal("abcd-ABCD2345678+_")


func test_next_value() -> void:
	var pattern := "a-cD-X+2-5"
	var fuzzer := StringFuzzer.new(4, 128, pattern)
	var r := RegEx.new()
	r.compile("[%s]+" % pattern)
	for i in 100:
		var value := fuzzer.next_value()
		# verify the generated value has a length in the configured min/max range
		assert_int(value.length()).is_between(4, 128)
		# using regex to remove_at all expected chars to verify the value only containing expected chars by is empty
		assert_str(r.sub(value, "")).is_empty()


func test_next_value_min_max_boundaries() -> void:
	var boundaries := {}
	var fuzzer := StringFuzzer.new(2, 3, "A")
	for i in 200:
		var value := fuzzer.next_value()
		boundaries[value.length()] = boundaries.get_or_add(value.length(), 0)

	# verify it contains only values with length 2 or 3
	assert_dict(boundaries)\
		.is_not_empty()\
		.has_size(2)\
		.contains_keys(2, 3)


func test_next_value_min_max_same_boundaries() -> void:
	var boundaries := {}
	var fuzzer := StringFuzzer.new(2, 2, "A")
	for i in 200:
		var value :String = fuzzer.next_value()
		boundaries[value.length()] = boundaries.get_or_add(value.length(), 0)

	# verify it contains only values with length 2 or 3
	assert_dict(boundaries)\
		.is_not_empty()\
		.has_size(1)\
		.contains_keys(2)


func test_password(fuzzer := StringFuzzer.new(8, 32, "a-zA-Z0-9!@#$%"), _fuzzer_iterations := 100) -> void:
	var password := fuzzer.next_value()
	assert_str(password).has_length(8, Comparator.GREATER_EQUAL).has_length(32, Comparator.LESS_EQUAL)
