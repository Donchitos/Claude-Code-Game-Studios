extends RefCounted

const MIN_VALUE := -10
const MAX_VALUE := 22

class NestedFuzzer extends Fuzzer:

	func _init() -> void:
		pass

	func next_value() -> Variant:
		return {}

	static func _s_max_value() -> int:
		return MAX_VALUE


class NestedFuzzerWithArgs extends Fuzzer:

	var _value: Variant

	func _init(value: int, _max_value := MAX_VALUE, _vec := Vector2.ONE) -> void:
		_value = value

	func next_value() -> Variant:
		return _value


func min_value() -> int:
	return MIN_VALUE


func get_fuzzer() -> Fuzzer:
	return Fuzzers.rangei(min_value(), NestedFuzzer._s_max_value())


func non_fuzzer() -> Resource:
	return Image.new()
