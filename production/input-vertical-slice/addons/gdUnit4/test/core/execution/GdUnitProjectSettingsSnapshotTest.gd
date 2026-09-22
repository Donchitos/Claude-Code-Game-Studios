# GdUnit generated TestSuite
class_name GdUnitProjectSettingsSnapshotTest
extends GdUnitTestSuite


const __source = "res://addons/gdUnit4/src/core/execution/GdUnitProjectSettingsSnapshot.gd"

const IGNORE := GdUnitSettings.GdScriptWarningMode.IGNORE
const WARN := GdUnitSettings.GdScriptWarningMode.WARN
const ERROR := GdUnitSettings.GdScriptWarningMode.ERROR
const EXCLUDE := GdUnitSettings.GdScriptWarningDirectoryMode.EXCLUDE
const INCLUDE := GdUnitSettings.GdScriptWarningDirectoryMode.INCLUDE


#region save / restore

func test_restore_restores_scalar_setting() -> void:
	# Setup
	var snapshot := GdUnitProjectSettingsSnapshot.new()
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, IGNORE)
	snapshot.save()
	# Act
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, ERROR)
	snapshot.restore()
	# Verify
	assert_int(ProjectSettings.get_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION))\
		.is_equal(IGNORE)


func test_restore_restores_dictionary_setting() -> void:
	# Setup
	var snapshot := GdUnitProjectSettingsSnapshot.new()
	var original_rules: Dictionary = {"res://addons": EXCLUDE}
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES, original_rules.duplicate())
	snapshot.save()
	# Act
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES, {"res://modified": INCLUDE})
	snapshot.restore()
	# Verify
	assert_dict(ProjectSettings.get_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES))\
		.is_equal(original_rules)


func test_restore_does_not_change_unmodified_settings() -> void:
	# Setup
	var snapshot := GdUnitProjectSettingsSnapshot.new()
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, IGNORE)
	snapshot.save()
	# Act
	snapshot.restore()
	# Verify
	assert_int(ProjectSettings.get_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION))\
		.is_equal(IGNORE)


func test_restore_without_save_does_nothing() -> void:
	# Setup
	var snapshot := GdUnitProjectSettingsSnapshot.new()
	# Act
	snapshot.restore()
	snapshot.restore()
	# Verify — no error, no crash
	assert_bool(true).is_true()

#endregion
