## GdUnit4CSharpApiLoader
##
## A bridge class that handles communication between GDScript and C# for the GdUnit4 testing framework.
## This loader acts as a compatibility layer to safely access the .NET API and ensure that calls
## only proceed when the .NET environment is properly configured and available.
## [br]
## The class handles:
## - Verification of .NET runtime availability
## - Loading the C# wrapper script
## - Checking for the GdUnit4Api assembly
## - Providing proxy methods to access GdUnit4 functionality in C#
@static_unload
class_name GdUnit4CSharpApiLoader
extends RefCounted

## Cached reference to the loaded C# wrapper script
static var _gdUnit4NetWrapper: Script

## Cached instance of the API (singleton pattern)
static var _api_instance: RefCounted


class TestEventListener extends RefCounted:

	func publish_event(event: Dictionary) -> void:
		var test_event := GdUnitEvent.new().deserialize(event)
		GdUnitSignals.instance().gdunit_event.emit(test_event)

static var _test_event_listener := TestEventListener.new()


## Returns an instance of the GdUnit4CSharpApi wrapper.[br]
## @return Script: The loaded C# wrapper or null if .NET is not supported
static func instance() -> Script:
	if not GdUnit4CSharpApiLoader.is_api_loaded():
		return null

	return _gdUnit4NetWrapper


## Returns or creates a single instance of the API [br]
## This improves performance by reusing the same object
static func api_instance() -> RefCounted:
	if _api_instance == null and is_api_loaded():
		@warning_ignore("unsafe_method_access")
		_api_instance = instance().new()
	return _api_instance


static func is_engine_version_supported(engine_version: int = Engine.get_version_info().hex) -> bool:
	return engine_version >= 0x40200


## Checks if the .NET environment is properly configured and available.[br]
## @return bool: True if .NET is fully supported and the assembly is found
static func is_api_loaded() -> bool:
	# If the wrapper is already loaded we don't need to check again
	if _gdUnit4NetWrapper != null:
		return true

	# First we check if this is a Godot .NET runtime instance
	if not ClassDB.class_exists("CSharpScript") or not is_engine_version_supported():
		return false
	# Second we check the C# project file exists
	var assembly_name: String = ProjectSettings.get_setting("dotnet/project/assembly_name")
	if assembly_name.is_empty() or not FileAccess.file_exists("res://%s.csproj" % assembly_name):
		return false

	# Finally load the wrapper and check if the GdUnit4 assembly can be found
	_gdUnit4NetWrapper = load("res://addons/gdUnit4/src/dotnet/GdUnit4CSharpApi.cs")
	@warning_ignore("unsafe_method_access")
	return _gdUnit4NetWrapper.call("IsApiLoaded")


## Returns the version of the GdUnit4 .NET assembly.[br]
## @return String: The version string or "unknown" if .NET is not supported
static func version() -> String:
	if not GdUnit4CSharpApiLoader.is_api_loaded():
		return "unknown"
	@warning_ignore("unsafe_method_access")
	return instance().Version()


static func discover_tests(source_script: Script) -> Array[GdUnitTestCase]:
	var tests: Array = _gdUnit4NetWrapper.call("DiscoverTests", source_script)

	return Array(tests.map(GdUnitTestCase.from_dict), TYPE_OBJECT, "RefCounted", GdUnitTestCase)


static func execute(tests: Array[GdUnitTestCase]) -> void:
	var net_api := api_instance()
	if net_api == null:
		push_warning("Execute C# tests not supported!")
		return
	var tests_as_dict: Array[Dictionary] = Array(tests.map(GdUnitTestCase.to_dict), TYPE_DICTIONARY, "", null)

	net_api.call("ExecuteAsync", tests_as_dict, _test_event_listener.publish_event)
	@warning_ignore("unsafe_property_access")
	await net_api.ExecutionCompleted


static func create_test_suite(source_path: String, line_number: int, test_suite_path: String) -> GdUnitResult:
	if not GdUnit4CSharpApiLoader.is_api_loaded():
		return  GdUnitResult.error("Can't create test suite. No .NET support found.")
	@warning_ignore("unsafe_method_access")
	var result: Dictionary = instance().CreateTestSuite(source_path, line_number, test_suite_path)
	if result.has("error"):
		return GdUnitResult.error(str(result.get("error")))
	return  GdUnitResult.success(result)


static func is_csharp_file(resource_path: String) -> bool:
	var ext := resource_path.get_extension()
	return ext == "cs" and GdUnit4CSharpApiLoader.is_api_loaded()
