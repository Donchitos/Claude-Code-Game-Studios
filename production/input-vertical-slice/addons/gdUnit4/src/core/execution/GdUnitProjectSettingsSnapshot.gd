## Captures and restores all in-memory [ProjectSettings] values around a single
## stage of test execution.[br]
## Each [GdUnitExecutionContext] owns one instance. Suite-level and test-level
## isolation are achieved by the two separate contexts rather than by stacking:[br]
## [codeblock]
##   GdUnitTestSuiteExecutionStage  -> save()   (before before())
##     GdUnitTestCaseExecutionStage -> save()   (before before_test())
##     GdUnitTestCaseExecutionStage -> restore() (after after_test())
##   GdUnitTestSuiteExecutionStage  -> restore() (after after())
## [/codeblock]
class_name GdUnitProjectSettingsSnapshot
extends RefCounted


var _snapshot: Dictionary = {}


func save() -> void:
	_snapshot.clear()
	for property: Dictionary in ProjectSettings.get_property_list():
		var name: String = property["name"]
		if ProjectSettings.has_setting(name):
			var value: Variant = ProjectSettings.get_setting(name)
			@warning_ignore("unsafe_method_access")
			_snapshot[name] = value.duplicate() if (value is Dictionary or value is Array) else value


func restore() -> void:
	for name: String in _snapshot:
		if not ProjectSettings.has_setting(name):
			continue
		var current: Variant = ProjectSettings.get_setting(name)
		var original: Variant = _snapshot[name]
		if current != original:
			ProjectSettings.set_setting(name, original)
	_snapshot.clear()
