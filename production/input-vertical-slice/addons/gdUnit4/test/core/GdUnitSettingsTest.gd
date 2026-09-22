# GdUnit generated TestSuite
class_name GdUnitSettingsTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://addons/gdUnit4/src/core/GdUnitSettings.gd'

const IGNORE := GdUnitSettings.GdScriptWarningMode.IGNORE
const WARN := GdUnitSettings.GdScriptWarningMode.WARN
const ERROR := GdUnitSettings.GdScriptWarningMode.ERROR
const EXCLUDE := GdUnitSettings.GdScriptWarningDirectoryMode.EXCLUDE
const INCLUDE := GdUnitSettings.GdScriptWarningDirectoryMode.INCLUDE


static func get_godot_property_info(property_name: String) -> Dictionary:
	for property: Dictionary in ProjectSettings.get_property_list():
		if property["name"] == property_name:
			return property
	return {}


#region list_settings
func test_list_settings() -> void:
	var report_errors := "unit_test/settings/report_errors"
	var report_warnings := "unit_test/settings/report_warnings"
	var max_retries := "unit_test/settings/max_retries"
	var enable_logging := "unit_test/network/enable_logging"
	var verbose_output := "unit_test/network/verbose_output"
	var log_path := "unit_test/network/log_path"
	var timeout_seconds := "unit_test/network/timeout_seconds"
	GdUnitSettings.create_property_if_need(report_errors, true, "Report errors as failures")
	GdUnitSettings.create_property_if_need(report_warnings, false, "Report warnings as failures")
	GdUnitSettings.create_property_if_need(max_retries, 3, "Maximum retry count on test failure")
	GdUnitSettings.create_property_if_need(enable_logging, true, "Enable test run logging")
	GdUnitSettings.create_property_if_need(verbose_output, false, "Show verbose test output")
	GdUnitSettings.create_property_if_need(log_path, "logs/", "Path to store log files")
	GdUnitSettings.create_property_if_need(timeout_seconds, 30, "Connection timeout in seconds")

	var settings_settings := GdUnitSettings.list_settings("unit_test/settings")
	assert_array(settings_settings)\
		.extractv(extr("name"), extr("type"), extr("value"), extr("default"), extr("help"), extr("value_set"))\
		.contains_exactly_in_any_order([
			tuple(report_errors, TYPE_BOOL, true, true, "Report errors as failures", PackedStringArray()),
			tuple(report_warnings, TYPE_BOOL, false, false, "Report warnings as failures", PackedStringArray()),
			tuple(max_retries, TYPE_INT, 3, 3, "Maximum retry count on test failure", PackedStringArray()),
		])
	var settings_network := GdUnitSettings.list_settings("unit_test/network")
	assert_array(settings_network)\
		.extractv(extr("name"), extr("type"), extr("value"), extr("default"), extr("help"), extr("value_set"))\
		.contains_exactly_in_any_order([
			tuple(enable_logging, TYPE_BOOL, true, true, "Enable test run logging", PackedStringArray()),
			tuple(verbose_output, TYPE_BOOL, false, false, "Show verbose test output", PackedStringArray()),
			tuple(log_path, TYPE_STRING, "logs/", "logs/", "Path to store log files", PackedStringArray()),
			tuple(timeout_seconds, TYPE_INT, 30, 30, "Connection timeout in seconds", PackedStringArray()),
		])
#endregion


#region property info
func test_property_bool_info() -> void:
	var property_name := "unit_test/property/update_notification_enabled"
	GdUnitSettings.create_property_if_need(property_name, true, "Show notification when a new version is found")

	var property := GdUnitSettings.get_property(property_name)
	assert_bool(property.value()).is_true()
	assert_bool(property.default()).is_true()
	assert_int(property.type()).is_equal(TYPE_BOOL)
	assert_array(property.value_set()).is_empty()
	assert_str(property.help()).is_equal("Show notification when a new version is found")
	# verify Godot property API
	var info := get_godot_property_info(property_name)
	assert_dict(info)\
		.contains_key_value("type", TYPE_BOOL)\
		.contains_key_value("hint", PROPERTY_HINT_NONE)\
		.contains_key_value("hint_string", "")
	assert_that(ProjectSettings.property_get_revert(property_name)).is_equal(true)


func test_property_int_info() -> void:
	var property_name := "unit_test/property/server_timeout_minutes"
	GdUnitSettings.create_property_if_need(property_name, 30, "Server connection timeout in minutes")

	var property := GdUnitSettings.get_property(property_name)
	assert_int(property.value()).is_equal(30)
	assert_int(property.default()).is_equal(30)
	assert_int(property.type()).is_equal(TYPE_INT)
	assert_array(property.value_set()).is_empty()
	assert_str(property.help()).is_equal("Server connection timeout in minutes")
	# verify Godot property API
	var info := get_godot_property_info(property_name)
	assert_dict(info)\
		.contains_key_value("type", TYPE_INT)\
		.contains_key_value("hint", PROPERTY_HINT_NONE)\
		.contains_key_value("hint_string", "")
	assert_that(ProjectSettings.property_get_revert(property_name)).is_equal(30)


func test_property_string_info() -> void:
	var property_name := "unit_test/property/test_lookup_folder"
	GdUnitSettings.create_property_if_need(property_name, "test", "Subfolder where test suites are located")

	var property := GdUnitSettings.get_property(property_name)
	assert_str(property.value()).is_equal("test")
	assert_str(property.default()).is_equal("test")
	assert_int(property.type()).is_equal(TYPE_STRING)
	assert_array(property.value_set()).is_empty()
	assert_str(property.help()).is_equal("Subfolder where test suites are located")
	# verify Godot property API
	var info := get_godot_property_info(property_name)
	assert_dict(info)\
		.contains_key_value("type", TYPE_STRING)\
		.contains_key_value("hint", PROPERTY_HINT_NONE)\
		.contains_key_value("hint_string", "")
	assert_that(ProjectSettings.property_get_revert(property_name)).is_equal("test")


func test_property_enum_info() -> void:
	var property_name := "unit_test/property/naming_convention"
	var value_set: PackedStringArray = GdUnitSettings.NAMING_CONVENTIONS.keys()
	GdUnitSettings.create_property_if_need(property_name, GdUnitSettings.NAMING_CONVENTIONS.AUTO_DETECT, "Naming convention for test suite generation", value_set)

	var property := GdUnitSettings.get_property(property_name)
	assert_int(property.value()).is_equal(GdUnitSettings.NAMING_CONVENTIONS.AUTO_DETECT)
	assert_int(property.default()).is_equal(GdUnitSettings.NAMING_CONVENTIONS.AUTO_DETECT)
	assert_int(property.type()).is_equal(TYPE_INT)
	assert_array(property.value_set()).is_equal(value_set)
	assert_str(property.help()).is_equal("Naming convention for test suite generation")
	# verify Godot property API
	var info := get_godot_property_info(property_name)
	assert_dict(info)\
		.contains_key_value("type", TYPE_INT)\
		.contains_key_value("hint", PROPERTY_HINT_ENUM)\
		.contains_key_value("hint_string", ",".join(value_set))
	assert_that(ProjectSettings.property_get_revert(property_name)).is_equal(GdUnitSettings.NAMING_CONVENTIONS.AUTO_DETECT)
#endregion


#region migrate_property
func test_migrate_property_change_key() -> void:
	var old_property_X := "/category_patch/migrate_key/old_name"
	var new_property_X := "/category_patch/migrate_key/new_name"
	GdUnitSettings.create_property_if_need(old_property_X, "foo")
	assert_str(GdUnitSettings.get_setting(old_property_X, null)).is_equal("foo")
	assert_str(GdUnitSettings.get_setting(new_property_X, null)).is_null()
	var old_property := GdUnitSettings.get_property(old_property_X)

	GdUnitSettings.migrate_property(old_property.name(),\
		new_property_X,\
		old_property.default(),\
		old_property.help())

	var new_property := GdUnitSettings.get_property(new_property_X)
	assert_str(GdUnitSettings.get_setting(old_property_X, null)).is_null()
	assert_str(GdUnitSettings.get_setting(new_property_X, null)).is_equal("foo")
	assert_object(new_property).is_not_equal(old_property)
	assert_str(new_property.value()).is_equal(old_property.value())
	assert_array(new_property.value_set()).is_equal(old_property.value_set())
	assert_int(new_property.type()).is_equal(old_property.type())
	assert_str(new_property.default()).is_equal(old_property.default())
	assert_str(new_property.help()).is_equal(old_property.help())


func test_migrate_property_change_value() -> void:
	var old_property_X := "/category_patch/migrate_value/old_name"
	var new_property_X := "/category_patch/migrate_value/new_name"
	GdUnitSettings.create_property_if_need(old_property_X, "foo", "help to foo")
	assert_str(GdUnitSettings.get_setting(old_property_X, null)).is_equal("foo")
	assert_str(GdUnitSettings.get_setting(new_property_X, null)).is_null()
	var old_property := GdUnitSettings.get_property(old_property_X)

	GdUnitSettings.migrate_property(old_property.name(),\
		new_property_X,\
		old_property.default(),\
		old_property.help(),\
		func(_value :Variant) -> String: return "bar")

	var new_property := GdUnitSettings.get_property(new_property_X)
	assert_str(GdUnitSettings.get_setting(old_property_X, null)).is_null()
	assert_str(GdUnitSettings.get_setting(new_property_X, null)).is_equal("bar")
	assert_object(new_property).is_not_equal(old_property)
	assert_str(new_property.value()).is_equal("bar")
	assert_array(new_property.value_set()).is_equal(old_property.value_set())
	assert_int(new_property.type()).is_equal(old_property.type())
	assert_str(new_property.default()).is_equal(old_property.default())
	assert_str(new_property.help()).is_equal(old_property.help())
#endregion


#region validate_is_inferred_declaration_enabled
func test_validate_is_inferred_declaration_enabled_when_disabled() -> void:
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, IGNORE)
	assert_result(GdUnitSettings.validate_is_inferred_declaration_enabled())\
		.is_success()


func test_validate_is_inferred_declaration_enabled_when_warning_and_addon_excluded() -> void:
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, WARN)
	if Engine.get_version_info().hex >= 0x40600:
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES, {"res://addons/gdUnit4": EXCLUDE})
	else:
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_EXCLUDE_ADDONS, true)
	assert_result(GdUnitSettings.validate_is_inferred_declaration_enabled())\
		.is_success()


func test_validate_is_inferred_declaration_enabled_when_warning_and_parent_dir_excluded() -> void:
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, WARN)
	if Engine.get_version_info().hex >= 0x40600:
		# Godot's default: all plugins are excluded, covers gdUnit4 via parent path
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES, {"res://addons": EXCLUDE})
	else:
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_EXCLUDE_ADDONS, true)
	assert_result(GdUnitSettings.validate_is_inferred_declaration_enabled())\
		.is_success()


func test_validate_is_inferred_declaration_enabled_when_warning_and_addon_excluded_but_parent_included() -> void:
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, WARN)
	if Engine.get_version_info().hex >= 0x40600:
		# parent addons dir is included (warnings active) but gdUnit4 is specifically excluded
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES, {"res://addons": INCLUDE, "res://addons/gdUnit4": EXCLUDE})
	else:
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_EXCLUDE_ADDONS, true)
	assert_result(GdUnitSettings.validate_is_inferred_declaration_enabled())\
		.is_success()


func test_validate_is_inferred_declaration_enabled_when_warning_and_only_parent_included() -> void:
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, WARN)
	var expected_message: String
	if Engine.get_version_info().hex >= 0x40600:
		# only "res://addons" is included (warnings active), gdUnit4 has no explicit exclusion
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES, {"res://addons": INCLUDE})
		expected_message = """
			GdUnit4: 'inferred_declaration' is set to Warning/Error!
			GdUnit4 is not 'inferred_declaration' safe, you have to exclude the addon (debug/gdscript/warnings/directory_rules)
			""".dedent().strip_edges()
	else:
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_EXCLUDE_ADDONS, false)
		expected_message = """
			GdUnit4: 'inferred_declaration' is set to Warning/Error!
			GdUnit4 is not 'inferred_declaration' safe, you have to exclude addons (debug/gdscript/warnings/exclude_addons)
			""".dedent().strip_edges()
	assert_result(GdUnitSettings.validate_is_inferred_declaration_enabled())\
		.is_error()\
		.contains_message(expected_message)


func test_validate_is_inferred_declaration_enabled_when_warning_and_addon_not_excluded() -> void:
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, WARN)
	var expected_message: String
	if Engine.get_version_info().hex >= 0x40600:
		# default + gdUnit4 explicitly re-included: addon is not excluded from warnings
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES, {"res://addons": EXCLUDE, "res://addons/gdUnit4": INCLUDE})
		expected_message = """
			GdUnit4: 'inferred_declaration' is set to Warning/Error!
			GdUnit4 is not 'inferred_declaration' safe, you have to exclude the addon (debug/gdscript/warnings/directory_rules)
			""".dedent().strip_edges()
	else:
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_EXCLUDE_ADDONS, false)
		expected_message = """
			GdUnit4: 'inferred_declaration' is set to Warning/Error!
			GdUnit4 is not 'inferred_declaration' safe, you have to exclude addons (debug/gdscript/warnings/exclude_addons)
			""".dedent().strip_edges()
	assert_result(GdUnitSettings.validate_is_inferred_declaration_enabled())\
		.is_error()\
		.contains_message(expected_message)


func test_validate_is_inferred_declaration_enabled_when_error_and_addon_not_excluded() -> void:
	ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION, ERROR)
	var expected_message: String
	if Engine.get_version_info().hex >= 0x40600:
		# default + gdUnit4 explicitly re-included: addon is not excluded from warnings
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_DIRECTORY_RULES, {"res://addons": EXCLUDE, "res://addons/gdUnit4": INCLUDE})
		expected_message = """
			GdUnit4: 'inferred_declaration' is set to Warning/Error!
			GdUnit4 is not 'inferred_declaration' safe, you have to exclude the addon (debug/gdscript/warnings/directory_rules)
			""".dedent().strip_edges()
	else:
		ProjectSettings.set_setting(GdUnitSettings.GDSCRIPT_WARNINGS_EXCLUDE_ADDONS, false)
		expected_message = """
			GdUnit4: 'inferred_declaration' is set to Warning/Error!
			GdUnit4 is not 'inferred_declaration' safe, you have to exclude addons (debug/gdscript/warnings/exclude_addons)
			""".dedent().strip_edges()
	assert_result(GdUnitSettings.validate_is_inferred_declaration_enabled())\
		.is_error()\
		.contains_message(expected_message)
#endregion
