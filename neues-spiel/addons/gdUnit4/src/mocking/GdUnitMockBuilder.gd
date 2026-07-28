class_name GdUnitMockBuilder
extends GdUnitClassDoubler

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")
const MOCK_TEMPLATE :GDScript = preload("res://addons/gdUnit4/src/mocking/GdUnitMockImpl.gd")


static func is_push_errors() -> bool:
	return GdUnitSettings.is_report_push_errors()


static func build(clazz :Variant, mock_mode :String, debug_write := false) -> Variant:
	var push_errors := is_push_errors()
	if not is_mockable(clazz, push_errors):
		return null
	# mocking a scene?
	if GdObjects.is_scene(clazz):
		var packed_scene: PackedScene = clazz
		return mock_on_scene(packed_scene, debug_write)
	elif typeof(clazz) == TYPE_STRING and str(clazz).ends_with(".tscn"):
		var packed_scene: PackedScene = load(str(clazz))
		return mock_on_scene(packed_scene, debug_write)
	# mocking a script
	var instance := create_instance(clazz)
	if instance == null:
		push_error("Can't create instance of class %s" % clazz)
	var mock := mock_on_script(instance, clazz, [ "get_script"], debug_write)
	if not instance is RefCounted:
		instance.free()
	if mock == null:
		return null
	var mock_instance: Object = mock.new()
	@warning_ignore("unsafe_method_access")
	mock_instance.__init(mock, mock_mode)
	return register_auto_free(mock_instance)


static func create_instance(clazz: Variant) -> Object:
	match typeof(clazz):
		TYPE_OBJECT:
			var obj: Object = clazz
			if clazz is GDScript:
				var script: GDScript = clazz
				var args := GdObjects.build_function_default_arguments(script, "_init")
				return script.callv("new", args)
			elif obj.is_class("GDScriptNativeClass"):
				@warning_ignore("unsafe_method_access")
				return obj.new()
		TYPE_STRING:
			var clazz_name: String = clazz
			if clazz_name.ends_with(".gd"):
				var script: GDScript = load(clazz_name)
				var args := GdObjects.build_function_default_arguments(script, "_init")
				return script.callv("new", args)
			elif ClassDB.can_instantiate(clazz_name):
				return ClassDB.instantiate(clazz_name)

	push_error("Can't create a mock validation instance from class: `%s`" % clazz)
	return null


static func mock_on_scene(scene: PackedScene, debug_write: bool) -> Variant:
	var push_errors := is_push_errors()
	if not scene.can_instantiate():
		if push_errors:
			push_error("Can't instanciate scene '%s'" % scene.resource_path)
		return null
	var scene_instance := scene.instantiate()
	# we can only mock checked a scene with attached script
	var scene_script: Script = scene_instance.get_script()
	if scene_script == null:
		if push_errors:
			push_error("Can't create a mockable instance for a scene without script '%s'" % scene.resource_path)
		@warning_ignore("return_value_discarded")
		GdUnitTools.free_instance(scene_instance)
		return null

	var script_path := scene_script.get_path()
	var mock := mock_on_script(scene_instance, script_path, GdUnitClassDoubler.EXLCUDE_SCENE_FUNCTIONS, debug_write)
	if mock == null:
		return null
	scene_instance.set_script(mock)
	@warning_ignore("unsafe_method_access")
	scene_instance.__init(mock, GdUnitMock.CALL_REAL_FUNC)
	return register_auto_free(scene_instance)


static func get_class_info(clazz :Variant) -> Dictionary:
	var clazz_name :String = GdObjects.extract_class_name(clazz).value()
	var clazz_path := GdObjects.extract_class_path(clazz)
	return {
		"class_name" : clazz_name,
		"class_path" : clazz_path
	}


static func mock_on_script(instance :Object, clazz :Variant, function_excludes :PackedStringArray, debug_write :bool) -> GDScript:
	var function_doubler := GdUnitMockFunctionDoubler.new()
	var class_info := get_class_info(clazz)
	var clazz_name :String = class_info.get("class_name")
	var clazz_path :PackedStringArray = class_info.get("class_path", [clazz_name])
	var mock_template := MOCK_TEMPLATE.source_code.format({
		"instance_id" : abs(instance.get_instance_id()),
		"gdunit_source_class": clazz_name if clazz_path.is_empty() else clazz_path[0]
	})
	var lines := load_template(mock_template, class_info)
	lines += double_functions(instance, clazz_name, clazz_path, function_doubler, function_excludes)
	# We disable warning/errors for inferred_declaration
	if Engine.get_version_info().hex >= 0x40400:
		lines.insert(0, '@warning_ignore_start("inferred_declaration")')
		lines.append('@warning_ignore_restore("inferred_declaration")')

	var mock := GDScript.new()
	mock.source_code = "\n".join(lines)
	mock.resource_name =  "Mock%s_%d.gd" % [clazz_name, Time.get_ticks_msec()]
	mock.resource_path = "%s/%s"  % [GdUnitFileAccess.create_temp_dir("mock"), mock.resource_name]

	if debug_write:
		@warning_ignore("return_value_discarded")
		DirAccess.remove_absolute(mock.resource_path)
		@warning_ignore("return_value_discarded")
		ResourceSaver.save(mock, mock.resource_path)
	var error := mock.reload(true)
	if error != OK:
		push_error("Critical!!!, MockBuilder error, please contact the developer.")
		return null
	return mock


static func is_mockable(clazz :Variant, push_errors :bool=false) -> bool:
	var clazz_type := typeof(clazz)
	if clazz_type != TYPE_OBJECT and clazz_type != TYPE_STRING:
		push_error("Invalid clazz type is used")
		return false
	# is PackedScene
	if GdObjects.is_scene(clazz):
		return true
	if GdObjects.is_native_class(clazz):
		return true
	# verify class type
	if GdObjects.is_object(clazz):
		if GdObjects.is_instance(clazz):
			if push_errors:
				push_error("It is not allowed to mock an instance '%s', use class name instead, Read 'Mocker' documentation for details" % clazz)
			return false

		if not GdObjects.can_be_instantiate(clazz):
			if push_errors:
				push_error("Can't create a mockable instance for class '%s'" % clazz)
			return false
		return true
	# verify by class name checked registered classes
	var clazz_name: String = clazz
	if ClassDB.class_exists(clazz_name):
		if Engine.has_singleton(clazz_name):
			if push_errors:
				push_error("Mocking a singelton class '%s' is not allowed!  Read 'Mocker' documentation for details" % clazz_name)
			return false
		if not ClassDB.can_instantiate(clazz_name):
			if push_errors:
				push_error("Mocking class '%s' is not allowed it cannot be instantiated!" % clazz_name)
			return false
		# exclude classes where name starts with a underscore
		if clazz_name.find("_") == 0:
			if push_errors:
				push_error("Can't create a mockable instance for protected class '%s'" % clazz_name)
			return false
		return true
	# at least try to load as a script
	var clazz_path := clazz_name
	if not FileAccess.file_exists(clazz_path):
		if push_errors:
			push_error("'%s' cannot be mocked for the specified resource path, the resource does not exist" % clazz_name)
		return false
	# finally verify is a script resource
	var resource := load(clazz_path)
	if resource == null:
		if push_errors:
			push_error("'%s' cannot be mocked the script cannot be loaded." % clazz_name)
			return false
	# finally check is extending from script
	return GdObjects.is_script(resource) or GdObjects.is_scene(resource)


static func register_auto_free(obj :Variant) -> Variant:
	return GdUnitThreadManager.get_current_context().get_execution_context().register_auto_free(obj)
