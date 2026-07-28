class_name DoubledSpyClassSourceClassName

const __INSTANCE_ID := "gdunit_doubler_instance_id_{instance_id}"


class GdUnitSpyDoublerState:
	const __SOURCE_CLASS := "{gdunit_source_class}"

	var excluded_methods := PackedStringArray()

	func _init(excluded_methods__ := PackedStringArray()) -> void:
		excluded_methods = excluded_methods__


var __spy_state := GdUnitSpyDoublerState.new()
@warning_ignore("unused_private_class_variable")
var __verifier_instance := GdUnitObjectInteractionsVerifier.new()


func __init(__excluded_methods := PackedStringArray()) -> void:
	__init_doubler()
	__spy_state.excluded_methods = __excluded_methods


static func __doubler_state() -> GdUnitSpyDoublerState:
	if Engine.has_meta(__INSTANCE_ID):
		return Engine.get_meta(__INSTANCE_ID).__spy_state
	return null


func __init_doubler() -> void:
	Engine.set_meta(__INSTANCE_ID, self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and Engine.has_meta(__INSTANCE_ID):
		Engine.remove_meta(__INSTANCE_ID)


static func __get_verifier() -> GdUnitObjectInteractionsVerifier:
	return Engine.get_meta(__INSTANCE_ID).__verifier_instance


static func __do_call_real_func(__func_name: String) -> bool:
	@warning_ignore("unsafe_method_access")
	return not __doubler_state().excluded_methods.has(__func_name)
