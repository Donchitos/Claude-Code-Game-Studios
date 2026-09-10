class_name GdUnitObjectInteractions
extends RefCounted


static func verify(interaction_object: Object, interactions_times: int) -> Variant:
	if not _is_mock_or_spy(interaction_object):
		return interaction_object

	_get_verifier(interaction_object).do_verify_interactions(interactions_times)
	return interaction_object


static func verify_no_interactions(interaction_object: Object) -> GdUnitAssert:
	var assert_tool := GdUnitAssertImpl.new("")
	if not _is_mock_or_spy(interaction_object):
		return assert_tool.report_success()

	var summary := _get_verifier(interaction_object).verify_no_interactions()
	if summary.is_empty():
		return assert_tool.report_success()
	return assert_tool.report_error(GdAssertMessages.error_no_more_interactions(summary))


static func verify_no_more_interactions(interaction_object: Object) -> GdUnitAssert:
	var assert_tool := GdUnitAssertImpl.new("")
	if not _is_mock_or_spy(interaction_object):
		return assert_tool

	var summary := _get_verifier(interaction_object).verify_no_more_interactions()
	if summary.is_empty():
		return assert_tool
	return assert_tool.report_error(GdAssertMessages.error_no_more_interactions(summary))


static func reset(interaction_object: Object) -> Object:
	if not _is_mock_or_spy(interaction_object):
		return interaction_object

	_get_verifier(interaction_object).reset_interactions()
	return interaction_object


static func _is_mock_or_spy(instance: Object) -> bool:
	if instance != null and instance.has_method("__get_verifier"):
		return true

	push_error("Error: The given object '%s' is not a mock or spy instance!" % instance)
	return false


static func _get_verifier(interaction_object: Object) -> GdUnitObjectInteractionsVerifier:
	@warning_ignore("unsafe_method_access")
	return interaction_object.__get_verifier()
