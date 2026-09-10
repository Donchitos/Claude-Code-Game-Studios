# GdUnit generated TestSuite
class_name GdUnitProjectSettingsAutoSaveTest
extends GdUnitTestSuite


const __source = "res://addons/gdUnit4/src/GdUnitTestSuite.gd"

const IGNORE := GdUnitSettings.GdScriptWarningMode.IGNORE
const ERROR := GdUnitSettings.GdScriptWarningMode.ERROR

const MUTATION_SUITE := "res://addons/gdUnit4/test/core/resources/testsuites/TestSuiteProjectSettingsMutation.gd"
const PROBE_KEY := "application/config/name"


#region auto save flag

func test_is_project_settings_auto_save_defaults_true() -> void:
	assert_bool(GdUnitSettings.is_project_settings_auto_save()).is_true()


func test_is_project_settings_auto_save_reflects_disabled_flag() -> void:
	var original: Variant = ProjectSettings.get_setting(GdUnitSettings.TEST_PROJECT_SETTINGS_AUTO_SAVE, true)
	ProjectSettings.set_setting(GdUnitSettings.TEST_PROJECT_SETTINGS_AUTO_SAVE, false)
	assert_bool(GdUnitSettings.is_project_settings_auto_save()).is_false()
	# restore the flag so the change never leaves this test
	ProjectSettings.set_setting(GdUnitSettings.TEST_PROJECT_SETTINGS_AUTO_SAVE, original)

#endregion

#region explicit save / restore

func test_save_restore_isolates_setting_change() -> void:
	var key := GdUnitSettings.GDSCRIPT_WARNINGS_INFERRED_DECLARATION
	var original: Variant = ProjectSettings.get_setting(key, IGNORE)
	# snapshot, mutate, restore — the mutation must not survive restore
	save_project_settings()
	ProjectSettings.set_setting(key, ERROR)
	restore_project_settings()
	assert_that(ProjectSettings.get_setting(key)).is_equal(original)

#endregion

#region execution stage gating

# Runs a suite through the real executor in an isolated thread context with a chosen
# auto-save flag, so the execution stages decide whether to snapshot the settings.
func run_isolated(tests: Array[GdUnitTestCase], auto_save: bool) -> void:
	await GdUnitThreadManager.run("auto_save_probe_%d" % randi(), func() -> void:
		var previous: Variant = ProjectSettings.get_setting(GdUnitSettings.TEST_PROJECT_SETTINGS_AUTO_SAVE, true)
		ProjectSettings.set_setting(GdUnitSettings.TEST_PROJECT_SETTINGS_AUTO_SAVE, auto_save)
		var executor := GdUnitTestSuiteExecutor.new(true)
		await get_tree().process_frame
		await executor.run_and_wait(tests)
		ProjectSettings.set_setting(GdUnitSettings.TEST_PROJECT_SETTINGS_AUTO_SAVE, previous)
	)


func test_execution_stage_snapshot_is_gated_by_flag() -> void:
	var loaded := GdUnitTestResourceLoader.load_tests(MUTATION_SUITE)
	var tests: Array[GdUnitTestCase] = Array(loaded.values(), TYPE_OBJECT, "RefCounted", GdUnitTestCase)
	var original: Variant = ProjectSettings.get_setting(PROBE_KEY)

	# auto save on: the stage snapshots around the test, so the mutation is rolled back
	await run_isolated(tests, true)
	assert_str(str(ProjectSettings.get_setting(PROBE_KEY))).is_equal(str(original))

	# auto save off: the stage skips the snapshot, so the mutation leaks past the run
	await run_isolated(tests, false)
	assert_str(str(ProjectSettings.get_setting(PROBE_KEY))).is_equal("__auto_save_probe__")

	# clean up the mutation that leaked from the off run
	ProjectSettings.set_setting(PROBE_KEY, original)

#endregion
