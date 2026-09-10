class_name GdScriptTestHelper
extends RefCounted


static func build_tmp_script(source_code: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = source_code.dedent()
	script.resource_path = GdUnitFileAccess.temp_dir() + "/tmp_%d.gd" % script.get_instance_id()
	var file := FileAccess.open(script.resource_path, FileAccess.WRITE)
	file.store_string(script.source_code)
	file.close()

	var unsafe_method_access: Variant = ProjectSettings.get_setting("debug/gdscript/warnings/unsafe_method_access")
	var unused_parameter: Variant = ProjectSettings.get_setting("debug/gdscript/warnings/unused_parameter")
	ProjectSettings.set_setting("debug/gdscript/warnings/unsafe_method_access", 0)
	ProjectSettings.set_setting("debug/gdscript/warnings/unused_parameter", 0)
	var error := script.reload()
	ProjectSettings.set_setting("debug/gdscript/warnings/unsafe_method_access", unsafe_method_access)
	ProjectSettings.set_setting("debug/gdscript/warnings/unused_parameter", unused_parameter)
	if error:
		push_error("Can't load temp script '%s', error: %s" % [source_code, error_string(error)])
		return null
	return script


static func get_class_method_descriptor(clazz_name: String, method_name: String) -> Dictionary:
	for descriptor: Dictionary in ClassDB.class_get_method_list(clazz_name):
		if descriptor["name"] == method_name:
			return descriptor
	return {}


static func get_script_method_descriptor(script: GDScript, method_name: String) -> Dictionary:
	for descriptor: Dictionary in script.get_script_method_list():
		if descriptor["name"] == method_name:
			return descriptor
	return {}
