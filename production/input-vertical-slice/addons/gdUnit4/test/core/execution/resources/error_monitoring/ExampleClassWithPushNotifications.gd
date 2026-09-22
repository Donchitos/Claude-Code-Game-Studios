class_name ExampleClassWithPushNotifications
extends Node

const ERROR_NEGATIVE_VALUE := "Cannot get square root of negative value"
const WARN_UNCHANGED := "Text was not changed"


static func get_square_root(x: float) -> float:
	if x < 0:
		push_error(ERROR_NEGATIVE_VALUE)
		return 0
	return sqrt(x)


static func get_capitalized_text(text: String) -> String:
	var capitalized := text.capitalize()
	if capitalized == text:
		push_warning(WARN_UNCHANGED)
	return capitalized
