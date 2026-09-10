# GdUnit generated TestSuite
class_name GdUnitShortcutTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source: String = 'res://addons/gdUnit4/src/core/command/GdUnitShortcut.gd'


func test_default_keys() -> void:
	match OS.get_name().to_lower():
		'windows':
			assert_array(GdUnitShortcut.default_keys(GdUnitShortcut.ShortCut.NONE)).is_empty()
			assert_array(GdUnitShortcut.default_keys(GdUnitShortcut.ShortCut.RUN_TESTSUITE_DEBUG)).contains_exactly(Key.KEY_ALT, Key.KEY_SHIFT, Key.KEY_F6)
