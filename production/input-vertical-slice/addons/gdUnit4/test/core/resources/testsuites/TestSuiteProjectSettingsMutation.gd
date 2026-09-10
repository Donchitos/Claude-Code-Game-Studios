# Inner suite for GdUnitProjectSettingsAutoSaveTest.
# A single test mutates an existing project setting. Whether the change survives the run
# tells us whether the execution stages snapshotted around it:
#   auto save on  -> the stage restores the setting, the mutation is gone after the run
#   auto save off -> the stage skips the snapshot, the mutation leaks past the run
extends GdUnitTestSuite

func test_mutates_project_setting() -> void:
	ProjectSettings.set_setting("application/config/name", "__auto_save_probe__")
	assert_str(str(ProjectSettings.get_setting("application/config/name"))).is_equal("__auto_save_probe__")
