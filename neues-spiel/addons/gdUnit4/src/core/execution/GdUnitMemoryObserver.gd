## The memory watcher for objects that have been registered and are released when 'gc' is called.
class_name GdUnitMemoryObserver
extends RefCounted

const TAG_OBSERVE_INSTANCE := "GdUnit4_observe_instance_"
const TAG_AUTO_FREE = "GdUnit4_marked_auto_free"
const GdUnitTools = preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")


var _store :Array[Variant] = []
# enable for debugging purposes
var _is_stdout_verbose := false
const _show_debug := false


## Registration of an instance to be released when an execution phase is completed
func register_auto_free(obj :Variant) -> Variant:
	if not is_instance_valid(obj):
		return obj
	# do not register on GDScriptNativeClass
	@warning_ignore("unsafe_cast")
	if typeof(obj) == TYPE_OBJECT and (obj as Object).is_class("GDScriptNativeClass") :
		return obj
	#if obj is GDScript or obj is ScriptExtension:
	#	return obj
	if obj is MainLoop:
		push_error("GdUnit4: Avoid to add mainloop to auto_free queue  %s" % obj)
		return
	if _is_stdout_verbose:
		print_verbose("GdUnit4:gc():register auto_free(%s)" % obj)
	# only register pure objects
	if obj is GdUnitSceneRunner:
		_store.push_back(obj)
	else:
		_store.append(obj)
	_tag_object(obj)
	return obj


# to disable instance guard when run into issues.
static func _is_instance_guard_enabled() -> bool:
	return false


static func debug_observe(name :String, obj :Object, indent :int = 0) -> void:
	if not _show_debug:
		return
	var script :GDScript= obj if obj is GDScript else obj.get_script()
	if script:
		var base_script :GDScript = script.get_base_script()
		@warning_ignore("unsafe_method_access")
		prints("".lpad(indent, "	"), name, obj, obj.get_class(), "reference_count:", obj.get_reference_count() if obj is RefCounted else 0, "script:", script, script.resource_path)
		if base_script:
			debug_observe("+", base_script, indent+1)
	else:
		@warning_ignore("unsafe_method_access")
		prints(name, obj, obj.get_class(), obj.get_name())


static func guard_instance(obj :Object) -> void:
	if not _is_instance_guard_enabled():
		return
	var tag := TAG_OBSERVE_INSTANCE + str(abs(obj.get_instance_id()))
	if Engine.has_meta(tag):
		return
	debug_observe("Gard on instance", obj)
	Engine.set_meta(tag, obj)


static func unguard_instance(obj :Object, verbose := true) -> void:
	if not _is_instance_guard_enabled():
		return
	var tag := TAG_OBSERVE_INSTANCE + str(abs(obj.get_instance_id()))
	if verbose:
		debug_observe("unguard instance", obj)
	if Engine.has_meta(tag):
		Engine.remove_meta(tag)


static func gc_guarded_instance(name :String, instance :Object) -> void:
	if not _is_instance_guard_enabled():
		return
	await (Engine.get_main_loop() as SceneTree).process_frame
	unguard_instance(instance, false)
	if is_instance_valid(instance) and instance is RefCounted:
		# finally do this very hacky stuff
		# we need to manually unreferece to avoid leaked scripts
		# but still leaked GDScriptFunctionState exists
		#var script :GDScript = instance.get_script()
		#if script:
		#	var base_script :GDScript = script.get_base_script()
		#	if base_script:
		#		base_script.unreference()
		debug_observe(name, instance)
		(instance as RefCounted).unreference()
		await (Engine.get_main_loop() as SceneTree).process_frame


static func gc_on_guarded_instances() -> void:
	if not _is_instance_guard_enabled():
		return
	for tag in Engine.get_meta_list():
		if tag.begins_with(TAG_OBSERVE_INSTANCE):
			var instance :Object = Engine.get_meta(tag)
			await gc_guarded_instance("Leaked instance detected:", instance)
			await GdUnitTools.free_instance(instance, false)


# store the object into global store aswell to be verified by 'is_marked_auto_free'
func _tag_object(obj :Variant) -> void:
	var tagged_object: Array = Engine.get_meta(TAG_AUTO_FREE, [])
	tagged_object.append(obj)
	Engine.set_meta(TAG_AUTO_FREE, tagged_object)


## Runs over all registered objects and releases them
func gc() -> void:
	if _store.is_empty():
		return
	# give engine time to free objects to process objects marked by queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	if _is_stdout_verbose:
		print_verbose("GdUnit4:gc():running", " freeing %d objects .." % _store.size())
	var tagged_objects: Array = Engine.get_meta(TAG_AUTO_FREE, [])
	while not _store.is_empty():
		var value :Variant = _store.pop_front()
		tagged_objects.erase(value)
		await GdUnitTools.free_instance(value, _is_stdout_verbose)
	assert(_store.is_empty(), "The memory observer has still entries in the store!")


## Checks whether the specified object is registered for automatic release
static func is_marked_auto_free(obj: Variant) -> bool:
	var tagged_objects: Array = Engine.get_meta(TAG_AUTO_FREE, [])
	return tagged_objects.has(obj)
