class_name GdUnitSpyBuilder
extends GdUnitClassDoubler

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")
const SPY_TEMPLATE :GDScript = preload("res://addons/gdUnit4/src/spy/GdUnitSpyImpl.gd")
const EXCLUDE_PROPERTIES_TO_COPY = ["script", "type"]


static func build(to_spy: Variant, debug_write := false) -> Variant:
	if GdObjects.is_singleton(to_spy):
		@warning_ignore("unsafe_cast")
		push_error("Spy on a Singleton is not allowed! '%s'" % (to_spy as Object).get_class())
		return null

	# if resource path load it before
	if GdObjects.is_scene_resource_path(to_spy):
		var scene_resource_path :String = to_spy
		if not FileAccess.file_exists(scene_resource_path):
			push_error("Can't build spy on scene '%s'! The given resource not exists!" % scene_resource_path)
			return null
		var scene_to_spy: PackedScene = load(scene_resource_path)
		return spy_on_scene(scene_to_spy.instantiate() as Node, debug_write)
	# spy checked PackedScene
	if GdObjects.is_scene(to_spy):
		var scene_to_spy: PackedScene = to_spy
		return spy_on_scene(scene_to_spy.instantiate() as Node, debug_write)
	# spy checked a scene instance
	if GdObjects.is_instance_scene(to_spy):
		@warning_ignore("unsafe_cast")
		return spy_on_scene(to_spy as Node, debug_write)

	var excluded_functions := []
	if to_spy is Callable:
		@warning_ignore("unsafe_cast")
		to_spy = CallableDoubler.new(to_spy as Callable)
		excluded_functions = CallableDoubler.excluded_functions()

	var spy := spy_on_script(to_spy, excluded_functions, debug_write)
	if spy == null:
		return null
	var spy_instance: Object = spy.new()
	@warning_ignore("unsafe_method_access")
	# we do not call the original implementation for _ready and all input function, this is actualy done by the engine
	spy_instance.__init(["_input", "_gui_input", "_input_event", "_unhandled_input"])
	@warning_ignore("unsafe_cast")
	copy_properties(to_spy as Object, spy_instance)
	@warning_ignore("return_value_discarded")
	GdUnitObjectInteractions.reset(spy_instance)
	return register_auto_free(spy_instance)


static func get_class_info(clazz :Variant) -> Dictionary:
	var clazz_path := GdObjects.extract_class_path(clazz)
	var clazz_name :String = GdObjects.extract_class_name(clazz).value()
	return {
		"class_name" : clazz_name,
		"class_path" : clazz_path
	}


static func spy_on_script(instance: Variant, function_excludes: PackedStringArray, debug_write: bool) -> GDScript:
	if GdArrayTools.is_array_type(instance):
		if GdUnitSettings.is_verbose_assert_errors():
			push_error("Can't build spy checked type '%s'! Spy checked Container Built-In Type not supported!" % type_string(typeof(instance)))
		return null
	var class_info := get_class_info(instance)
	var clazz_name :String = class_info.get("class_name")
	var clazz_path :PackedStringArray = class_info.get("class_path", [clazz_name])
	if not GdObjects.is_instance(instance):
		if GdUnitSettings.is_verbose_assert_errors():
			push_error("Can't build spy for class type '%s'! Using an instance instead e.g. 'spy(<instance>)'" % [clazz_name])
		return null

	@warning_ignore("unsafe_method_access")
	var spy_template := SPY_TEMPLATE.source_code.format({
		"instance_id" : abs(instance.get_instance_id()),
		"gdunit_source_class": clazz_name if clazz_path.is_empty() else clazz_path[0]
	})
	@warning_ignore("unsafe_cast")
	var lines := load_template(spy_template, class_info)
	@warning_ignore("unsafe_cast")
	lines += double_functions(instance as Object, clazz_name, clazz_path, GdUnitSpyFunctionDoubler.new(), function_excludes)
	# We disable warning/errors for inferred_declaration
	if Engine.get_version_info().hex >= 0x40400:
		lines.insert(0, '@warning_ignore_start("inferred_declaration")')
		lines.append('@warning_ignore_restore("inferred_declaration")')

	var spy := GDScript.new()
	spy.source_code = "\n".join(lines)
	spy.resource_name = "Spy%s.gd" % clazz_name
	spy.resource_path = GdUnitFileAccess.create_temp_dir("spy") + "/Spy%s_%d.gd" % [clazz_name, Time.get_ticks_msec()]

	if debug_write:
		@warning_ignore("return_value_discarded")
		DirAccess.remove_absolute(spy.resource_path)
		@warning_ignore("return_value_discarded")
		ResourceSaver.save(spy, spy.resource_path)
	var error := spy.reload(true)
	if error != OK:
		push_error("Unexpected Error!, SpyBuilder error, please contact the developer.")
		return null
	return spy


static func spy_on_scene(scene :Node, debug_write :bool) -> Object:
	if scene.get_script() == null:
		if GdUnitSettings.is_verbose_assert_errors():
			push_error("Can't create a spy checked a scene without script '%s'" % scene.get_scene_file_path())
		return null
	# buils spy checked original script
	@warning_ignore("unsafe_cast")
	var scene_script :Object = (scene.get_script() as GDScript).new()
	var spy := spy_on_script(scene_script, GdUnitClassDoubler.EXLCUDE_SCENE_FUNCTIONS, debug_write)
	scene_script.free()
	if spy == null:
		return null

	# we need to restore the original script properties to apply after script exchange
	var original_properties := {}
	for p in scene.get_property_list():
		var property_name: String = p["name"]
		var usage: int = p["usage"]
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == PROPERTY_USAGE_SCRIPT_VARIABLE:
			original_properties[property_name] = scene.get(property_name)

	# exchage with spy
	scene.set_script(spy)
	# apply original script properties to the spy
	for property_name: String in original_properties.keys():
		scene.set(property_name, original_properties[property_name])

	@warning_ignore("unsafe_method_access")
	scene.__init()
	return register_auto_free(scene)


static func copy_properties(source :Object, dest :Object) -> void:
	for property in source.get_property_list():
		var property_name :String = property["name"]
		var property_value :Variant = source.get(property_name)
		if EXCLUDE_PROPERTIES_TO_COPY.has(property_name):
			continue
		#if dest.get(property_name) == null:
		#	prints("|%s|" % property_name, source.get(property_name))

		# check for invalid name property
		if property_name == "name" and property_value == "":
			dest.set(property_name, "<empty>");
			continue
		dest.set(property_name, property_value)


static func register_auto_free(obj :Variant) -> Variant:
	return GdUnitThreadManager.get_current_context().get_execution_context().register_auto_free(obj)
