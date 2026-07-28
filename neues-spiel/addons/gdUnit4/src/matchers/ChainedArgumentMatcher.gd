class_name ChainedArgumentMatcher
extends GdUnitArgumentMatcher

var _matchers :Array


func _init(matchers :Array) -> void:
	_matchers = matchers


func is_match(arguments :Variant) -> bool:
	var arg_array: Array = arguments
	if arg_array == null or arg_array.size() != _matchers.size():
		return false

	for index in arg_array.size():
		var arg: Variant = arg_array[index]
		var matcher: GdUnitArgumentMatcher = _matchers[index]

		if not matcher.is_match(arg):
			return false
	return true
