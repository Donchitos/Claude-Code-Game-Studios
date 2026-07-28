class_name DoubledMockClassSourceClassName

################################################################################
# internal mocking stuff
################################################################################

const __INSTANCE_ID := "gdunit_doubler_instance_id_{instance_id}"


class GdUnitMockDoublerState:
	const __SOURCE_CLASS := "{gdunit_source_class}"

	var excluded_methods := PackedStringArray()
	var working_mode := GdUnitMock.RETURN_DEFAULTS
	var is_prepare_return := false
	var return_values := Dictionary()
	var return_value: Variant = null


	func _init(working_mode_ := GdUnitMock.RETURN_DEFAULTS) -> void:
		working_mode = working_mode_


var __mock_state := GdUnitMockDoublerState.new()
@warning_ignore("unused_private_class_variable")
var __verifier_instance := GdUnitObjectInteractionsVerifier.new()


func __init(__script: GDScript, mock_working_mode: String) -> void:
	super.set_script(__script)
	__init_doubler()
	__mock_state.working_mode = mock_working_mode


static func __doubler_state() -> GdUnitMockDoublerState:
	if Engine.has_meta(__INSTANCE_ID):
		return Engine.get_meta(__INSTANCE_ID).__mock_state
	return null


func __init_doubler() -> void:
	Engine.set_meta(__INSTANCE_ID, self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and Engine.has_meta(__INSTANCE_ID):
		Engine.remove_meta(__INSTANCE_ID)


static func __get_verifier() -> GdUnitObjectInteractionsVerifier:
	return Engine.get_meta(__INSTANCE_ID).__verifier_instance


static func __is_prepare_return_value() -> bool:
	return __doubler_state().is_prepare_return


static func __sort_by_argument_matcher(__left_args: Array, __right_args: Array) -> bool:
	for __index in __left_args.size():
		var __larg: Variant = __left_args[__index]
		if __larg is GdUnitArgumentMatcher:
			return false
	return true


# we need to sort by matcher arguments so that they are all at the end of the list
static func __sort_dictionary(__unsorted_args: Dictionary) -> Dictionary:
	# only need to sort if contains more than one entry
	if __unsorted_args.size() <= 1:
		return __unsorted_args
	var __sorted_args: Array = __unsorted_args.keys()
	__sorted_args.sort_custom(__sort_by_argument_matcher)
	var __sorted_result := {}
	for __index in __sorted_args.size():
		var key :Variant = __sorted_args[__index]
		__sorted_result[key] = __unsorted_args[key]
	return __sorted_result


static func __save_function_return_value(__func_name: String, __func_args: Array) -> void:
	var doubler_state := __doubler_state()
	var mocked_return_value_by_args: Dictionary = doubler_state.return_values.get(__func_name, {})

	mocked_return_value_by_args[__func_args] = doubler_state.return_value
	doubler_state.return_values[__func_name] = __sort_dictionary(mocked_return_value_by_args)
	doubler_state.return_value = null
	doubler_state.is_prepare_return = false


static func __is_mocked_args_match(__func_args: Array, __mocked_args: Array) -> bool:
	var __is_matching := false
	for __index in __mocked_args.size():
		var __fuction_args: Array = __mocked_args[__index]
		if __func_args.size() != __fuction_args.size():
			continue
		__is_matching = true
		for __arg_index in __func_args.size():
			var __func_arg: Variant = __func_args[__arg_index]
			var __mock_arg: Variant = __fuction_args[__arg_index]
			if __mock_arg is GdUnitArgumentMatcher:
				@warning_ignore("unsafe_method_access")
				__is_matching = __is_matching and __mock_arg.is_match(__func_arg)
			else:
				__is_matching = __is_matching and typeof(__func_arg) == typeof(__mock_arg) and __func_arg == __mock_arg
			if not __is_matching:
				break
		if __is_matching:
			break
	return __is_matching


static func __return_mock_value(__func_name: String, __func_args: Array, __default_return_value: Variant) -> Variant:
	var doubler_state := __doubler_state()
	if not doubler_state.return_values.has(__func_name):
		return __default_return_value
	@warning_ignore("unsafe_method_access")
	var __mocked_args: Array = doubler_state.return_values.get(__func_name).keys()
	for __index in __mocked_args.size():
		var __margs: Variant = __mocked_args[__index]
		if __is_mocked_args_match(__func_args, [__margs]):
			return doubler_state.return_values[__func_name][__margs]
	return __default_return_value


static func __is_do_not_call_real_func(__func_name: String, __func_args := []) -> bool:
	var doubler_state := __doubler_state()
	var __is_call_real_func: bool = doubler_state.working_mode == GdUnitMock.CALL_REAL_FUNC  and not doubler_state.excluded_methods.has(__func_name)
	# do not call real funcions for mocked functions
	if __is_call_real_func and doubler_state.return_values.has(__func_name):
		@warning_ignore("unsafe_method_access")
		var __mocked_args: Array = doubler_state.return_values.get(__func_name).keys()
		return __is_mocked_args_match(__func_args, __mocked_args)
	return !__is_call_real_func


func __exclude_method_call(exluded_methods: PackedStringArray) -> void:
	__doubler_state().excluded_methods.append_array(exluded_methods)


func __do_return(mock_do_return_value: Variant) -> Object:
	__doubler_state().return_value = mock_do_return_value
	__doubler_state().is_prepare_return = true
	return self
