# Preloads all GdUnit assertions
class_name GdUnitAssertions
extends RefCounted


@warning_ignore("return_value_discarded")
func _init() -> void:
	# preload all gdunit assertions to speedup testsuite loading time
	# gdlint:disable=private-method-call
	@warning_ignore_start("return_value_discarded")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitBoolAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitStringAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitIntAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFloatAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitVectorAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitArrayAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitDictionaryAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFileAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitObjectAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitResultAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFuncAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitSignalAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitFailureAssertImpl.gd")
	GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnitGodotErrorAssertImpl.gd")
	@warning_ignore_restore("return_value_discarded")


### We now load all used asserts and tool scripts into the cache according to the principle of "lazy loading"
### in order to noticeably reduce the loading time of the test suite.
# We go this hard way to increase the loading performance to avoid reparsing all the used scripts
# for more detailed info -> https://github.com/godotengine/godot/issues/67400
# gdlint:disable=function-name
static func __lazy_load(script_path :String) -> GDScript:
	return ResourceLoader.load(script_path, "GDScript", ResourceLoader.CACHE_MODE_REUSE)


static func validate_value_type(value :Variant, type :Variant.Type) -> bool:
	return value == null or typeof(value) == type
