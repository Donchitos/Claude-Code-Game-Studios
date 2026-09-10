class_name GdUnitObjectInteractionsVerifier

var expected_interactions: int = -1
var saved_interactions := Dictionary()
var verified_interactions := Array()


func save_function_interaction(func_name: String, args :Array[Variant]) -> void:
	var function_args := [func_name] + args
	var matcher := GdUnitArgumentMatchers.to_matcher(function_args, true)
	for index in saved_interactions.keys().size():
		var key: Variant = saved_interactions.keys()[index]
		if matcher.is_match(key):
			saved_interactions[key] += 1
			return
	saved_interactions[function_args] = 1


func is_verify_interactions() -> bool:
	return expected_interactions != -1


func do_verify_interactions(interactions_times: int = 1) -> void:
	expected_interactions = interactions_times


func verify_interactions(func_name: String, args: Array[Variant]) -> void:
	var summary := Dictionary()
	var total_interactions := 0
	var function_args := [func_name] + args
	var matcher := GdUnitArgumentMatchers.to_matcher(function_args, true)
	for index in saved_interactions.keys().size():
		var key: Variant = saved_interactions.keys()[index]
		if matcher.is_match(key):
			var interactions: int = saved_interactions.get(key, 0)
			total_interactions += interactions
			summary[key] = interactions
			# add as verified
			verified_interactions.append(key)

	var assert_tool := GdUnitAssertImpl.new("")
	if total_interactions != expected_interactions:
		var __expected_summary := {function_args : expected_interactions}
		var error_message: String
		# if no interactions macht collect not verified interactions for failure report
		if summary.is_empty():
			var __current_summary := verify_no_more_interactions()
			error_message = GdAssertMessages.error_validate_interactions(__current_summary, __expected_summary)
		else:
			error_message = GdAssertMessages.error_validate_interactions(summary, __expected_summary)
		@warning_ignore("return_value_discarded")
		assert_tool.report_error(error_message)
	else:
		@warning_ignore("return_value_discarded")
		assert_tool.report_success()
	expected_interactions = -1


func verify_no_interactions() -> Dictionary:
	var summary := Dictionary()
	if not saved_interactions.is_empty():
		for index in saved_interactions.keys().size():
			var func_call: Variant = saved_interactions.keys()[index]
			summary[func_call] = saved_interactions[func_call]
	return summary


func verify_no_more_interactions() -> Dictionary:
	var summary := Dictionary()
	var called_functions: Array[Variant] = saved_interactions.keys()
	if called_functions != verified_interactions:
		# collect the not verified functions
		var called_but_not_verified := called_functions.duplicate()
		for index in verified_interactions.size():
			called_but_not_verified.erase(verified_interactions[index])

		for index in called_but_not_verified.size():
			var not_verified: Variant = called_but_not_verified[index]
			summary[not_verified] = saved_interactions[not_verified]
	return summary


func reset_interactions() -> void:
	saved_interactions.clear()
