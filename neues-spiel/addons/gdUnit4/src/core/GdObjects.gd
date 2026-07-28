# This is a helper class to compare two objects by equals
class_name GdObjects
extends Resource

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")


# introduced with Godot 4.3.beta1
const TYPE_VOID 	= 1000
const TYPE_VARARG 	= 1001
const TYPE_VARIANT	= 1002
const TYPE_FUNC 	= 1003
const TYPE_FUZZER 	= 1004
# missing Godot types
const TYPE_NODE 	= 2001
const TYPE_CONTROL	= 2002
const TYPE_CANVAS	= 2003
const TYPE_ENUM		= 2004


const TYPE_AS_STRING_MAPPINGS := {
	TYPE_NIL: "null",
	TYPE_BOOL: "bool",
	TYPE_INT: "int",
	TYPE_FLOAT: "float",
	TYPE_STRING: "String",
	TYPE_VECTOR2: "Vector2",
	TYPE_VECTOR2I: "Vector2i",
	TYPE_RECT2: "Rect2",
	TYPE_RECT2I: "Rect2i",
	TYPE_VECTOR3: "Vector3",
	TYPE_VECTOR3I: "Vector3i",
	TYPE_TRANSFORM2D: "Transform2D",
	TYPE_VECTOR4: "Vector4",
	TYPE_VECTOR4I: "Vector4i",
	TYPE_PLANE: "Plane",
	TYPE_QUATERNION: "Quaternion",
	TYPE_AABB: "AABB",
	TYPE_BASIS: "Basis",
	TYPE_TRANSFORM3D: "Transform3D",
	TYPE_PROJECTION: "Projection",
	TYPE_COLOR: "Color",
	TYPE_STRING_NAME: "StringName",
	TYPE_NODE_PATH: "NodePath",
	TYPE_RID: "RID",
	TYPE_OBJECT: "Object",
	TYPE_CALLABLE: "Callable",
	TYPE_SIGNAL: "Signal",
	TYPE_DICTIONARY: "Dictionary",
	TYPE_ARRAY: "Array",
	TYPE_PACKED_BYTE_ARRAY: "PackedByteArray",
	TYPE_PACKED_INT32_ARRAY: "PackedInt32Array",
	TYPE_PACKED_INT64_ARRAY: "PackedInt64Array",
	TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array",
	TYPE_PACKED_FLOAT64_ARRAY: "PackedFloat64Array",
	TYPE_PACKED_STRING_ARRAY: "PackedStringArray",
	TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array",
	TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array",
	TYPE_PACKED_VECTOR4_ARRAY: "PackedVector4Array",
	TYPE_PACKED_COLOR_ARRAY: "PackedColorArray",
	TYPE_VOID: "void",
	TYPE_VARARG: "VarArg",
	TYPE_FUNC: "Func",
	TYPE_FUZZER: "Fuzzer",
	TYPE_VARIANT: "Variant"
}


class EditorNotifications:
	# NOTE: Hardcoding to avoid runtime errors in exported projects when editor
	#       classes are not available. These values are unlikely to change.
	# See: EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED
	const NOTIFICATION_EDITOR_SETTINGS_CHANGED := 10000


const NOTIFICATION_AS_STRING_MAPPINGS := {
	TYPE_OBJECT: {
		Object.NOTIFICATION_POSTINITIALIZE : "POSTINITIALIZE",
		Object.NOTIFICATION_PREDELETE: "PREDELETE",
		EditorNotifications.NOTIFICATION_EDITOR_SETTINGS_CHANGED: "EDITOR_SETTINGS_CHANGED",
	},
	TYPE_NODE: {
		Node.NOTIFICATION_ENTER_TREE : "ENTER_TREE",
		Node.NOTIFICATION_EXIT_TREE: "EXIT_TREE",
		Node.NOTIFICATION_CHILD_ORDER_CHANGED: "CHILD_ORDER_CHANGED",
		Node.NOTIFICATION_READY: "READY",
		Node.NOTIFICATION_PAUSED: "PAUSED",
		Node.NOTIFICATION_UNPAUSED: "UNPAUSED",
		Node.NOTIFICATION_PHYSICS_PROCESS: "PHYSICS_PROCESS",
		Node.NOTIFICATION_PROCESS: "PROCESS",
		Node.NOTIFICATION_PARENTED: "PARENTED",
		Node.NOTIFICATION_UNPARENTED: "UNPARENTED",
		Node.NOTIFICATION_SCENE_INSTANTIATED: "INSTANCED",
		Node.NOTIFICATION_DRAG_BEGIN: "DRAG_BEGIN",
		Node.NOTIFICATION_DRAG_END: "DRAG_END",
		Node.NOTIFICATION_PATH_RENAMED: "PATH_CHANGED",
		Node.NOTIFICATION_INTERNAL_PROCESS: "INTERNAL_PROCESS",
		Node.NOTIFICATION_INTERNAL_PHYSICS_PROCESS: "INTERNAL_PHYSICS_PROCESS",
		Node.NOTIFICATION_POST_ENTER_TREE: "POST_ENTER_TREE",
		Node.NOTIFICATION_WM_MOUSE_ENTER: "WM_MOUSE_ENTER",
		Node.NOTIFICATION_WM_MOUSE_EXIT: "WM_MOUSE_EXIT",
		Node.NOTIFICATION_APPLICATION_FOCUS_IN: "WM_FOCUS_IN",
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT: "WM_FOCUS_OUT",
		#Node.NOTIFICATION_WM_QUIT_REQUEST: "WM_QUIT_REQUEST",
		Node.NOTIFICATION_WM_GO_BACK_REQUEST: "WM_GO_BACK_REQUEST",
		Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT: "WM_UNFOCUS_REQUEST",
		Node.NOTIFICATION_OS_MEMORY_WARNING: "OS_MEMORY_WARNING",
		Node.NOTIFICATION_TRANSLATION_CHANGED: "TRANSLATION_CHANGED",
		Node.NOTIFICATION_WM_ABOUT: "WM_ABOUT",
		Node.NOTIFICATION_CRASH: "CRASH",
		Node.NOTIFICATION_OS_IME_UPDATE: "OS_IME_UPDATE",
		Node.NOTIFICATION_APPLICATION_RESUMED: "APP_RESUMED",
		Node.NOTIFICATION_APPLICATION_PAUSED: "APP_PAUSED",
		Node3D.NOTIFICATION_TRANSFORM_CHANGED: "TRANSFORM_CHANGED",
		Node3D.NOTIFICATION_ENTER_WORLD: "ENTER_WORLD",
		Node3D.NOTIFICATION_EXIT_WORLD: "EXIT_WORLD",
		Node3D.NOTIFICATION_VISIBILITY_CHANGED: "VISIBILITY_CHANGED",
		Skeleton3D.NOTIFICATION_UPDATE_SKELETON: "UPDATE_SKELETON",
		CanvasItem.NOTIFICATION_DRAW: "DRAW",
		CanvasItem.NOTIFICATION_VISIBILITY_CHANGED: "VISIBILITY_CHANGED",
		CanvasItem.NOTIFICATION_ENTER_CANVAS: "ENTER_CANVAS",
		CanvasItem.NOTIFICATION_EXIT_CANVAS: "EXIT_CANVAS",
		#Popup.NOTIFICATION_POST_POPUP: "POST_POPUP",
		#Popup.NOTIFICATION_POPUP_HIDE: "POPUP_HIDE",
	},
	TYPE_CONTROL : {
		Object.NOTIFICATION_PREDELETE: "PREDELETE",
		Container.NOTIFICATION_SORT_CHILDREN: "SORT_CHILDREN",
		Control.NOTIFICATION_RESIZED: "RESIZED",
		Control.NOTIFICATION_MOUSE_ENTER: "MOUSE_ENTER",
		Control.NOTIFICATION_MOUSE_EXIT: "MOUSE_EXIT",
		Control.NOTIFICATION_FOCUS_ENTER: "FOCUS_ENTER",
		Control.NOTIFICATION_FOCUS_EXIT: "FOCUS_EXIT",
		Control.NOTIFICATION_THEME_CHANGED: "THEME_CHANGED",
		#Control.NOTIFICATION_MODAL_CLOSE: "MODAL_CLOSE",
		Control.NOTIFICATION_SCROLL_BEGIN: "SCROLL_BEGIN",
		Control.NOTIFICATION_SCROLL_END: "SCROLL_END",
	}
}


enum COMPARE_MODE {
	OBJECT_REFERENCE,
	PARAMETER_DEEP_TEST
}


# prototype of better object to dictionary
static func obj2dict(obj: Object, hashed_objects := Dictionary()) -> Dictionary:
	if obj == null:
		return {}
	var clazz_name := obj.get_class()
	var dict := Dictionary()
	var clazz_path := ""

	if is_instance_valid(obj) and obj.get_script() != null:
		var script: Script = obj.get_script()
		# handle build-in scripts
		if script.resource_path != null and script.resource_path.contains(".tscn"):
			var path_elements := script.resource_path.split(".tscn")
			clazz_name = path_elements[0].get_file()
			clazz_path = script.resource_path
		else:
			var d := inst_to_dict(obj)
			clazz_path = d["@path"]
			if d["@subpath"] != NodePath(""):
				clazz_name = d["@subpath"]
				dict["@inner_class"] = true
			else:
				clazz_name = clazz_path.get_file().replace(".gd", "")
	dict["@path"] = clazz_path

	for property in obj.get_property_list():
		var property_name :String = property["name"]
		var property_type :int = property["type"]
		var property_value :Variant = obj.get(property_name)
		if property_value is GDScript or property_value is Callable or property_value is RegEx:
			continue
		if (property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_DEFAULT
			and not property["usage"] & PROPERTY_USAGE_CATEGORY
			and not property["usage"] == 0):
			if property_type == TYPE_OBJECT:
				# prevent recursion
				if hashed_objects.has(obj):
					dict[property_name] = str(property_value)
					continue
				hashed_objects[obj] = true
				@warning_ignore("unsafe_cast")
				dict[property_name] = obj2dict(property_value as Object, hashed_objects)
			else:
				dict[property_name] = property_value
	if obj is Node:
		var childrens :Array = (obj as Node).get_children()
		dict["childrens"] = childrens.map(func (child :Object) -> Dictionary: return obj2dict(child, hashed_objects))
	if obj is TreeItem:
		var childrens :Array = (obj as TreeItem).get_children()
		dict["childrens"] = childrens.map(func (child :Object) -> Dictionary: return obj2dict(child, hashed_objects))

	return {"%s" % clazz_name : dict}


static func equals(obj_a :Variant, obj_b :Variant, case_sensitive :bool = false, compare_mode :COMPARE_MODE = COMPARE_MODE.PARAMETER_DEEP_TEST) -> bool:
	return _equals(obj_a, obj_b, case_sensitive, compare_mode, [], 0)


static func equals_sorted(obj_a: Array[Variant], obj_b: Array[Variant], case_sensitive: bool = false, compare_mode: COMPARE_MODE = COMPARE_MODE.PARAMETER_DEEP_TEST) -> bool:
	var a: Array[Variant] = obj_a.duplicate()
	var b: Array[Variant] = obj_b.duplicate()
	a.sort()
	b.sort()
	return equals(a, b, case_sensitive, compare_mode)


static func _equals(obj_a :Variant, obj_b :Variant, case_sensitive :bool, compare_mode :COMPARE_MODE, deep_stack :Array, stack_depth :int ) -> bool:
	var type_a := typeof(obj_a)
	var type_b := typeof(obj_b)
	if stack_depth > 32:
		prints("stack_depth", stack_depth, deep_stack)
		push_error("GdUnit equals has max stack deep reached!")
		return false

	# use argument matcher if requested
	if is_instance_valid(obj_a) and obj_a is GdUnitArgumentMatcher:
		@warning_ignore("unsafe_cast")
		return (obj_a as GdUnitArgumentMatcher).is_match(obj_b)
	if is_instance_valid(obj_b) and obj_b is GdUnitArgumentMatcher:
		@warning_ignore("unsafe_cast")
		return (obj_b as GdUnitArgumentMatcher).is_match(obj_a)

	stack_depth += 1
	# fast fail is different types
	if not _is_type_equivalent(type_a, type_b):
		return false
	# is same instance
	if obj_a == obj_b:
		return true
	# handle null values
	if obj_a == null and obj_b != null:
		return false
	if obj_b == null and obj_a != null:
		return false

	match type_a:
		TYPE_OBJECT:
			if deep_stack.has(obj_a) or deep_stack.has(obj_b):
				return true
			deep_stack.append(obj_a)
			deep_stack.append(obj_b)
			if compare_mode == COMPARE_MODE.PARAMETER_DEEP_TEST:
				# fail fast
				if not is_instance_valid(obj_a) or not is_instance_valid(obj_b):
					return false
				@warning_ignore("unsafe_method_access")
				if obj_a.get_class() != obj_b.get_class():
					return false
				@warning_ignore("unsafe_cast")
				var a := obj2dict(obj_a as Object)
				@warning_ignore("unsafe_cast")
				var b := obj2dict(obj_b as Object)
				return _equals(a, b, case_sensitive, compare_mode, deep_stack, stack_depth)
			return obj_a == obj_b

		TYPE_ARRAY:
			@warning_ignore("unsafe_method_access")
			if obj_a.size() != obj_b.size():
				return false
			@warning_ignore("unsafe_method_access")
			for index :int in obj_a.size():
				if not _equals(obj_a[index], obj_b[index], case_sensitive, compare_mode, deep_stack, stack_depth):
					return false
			return true

		TYPE_DICTIONARY:
			@warning_ignore("unsafe_method_access")
			if obj_a.size() != obj_b.size():
				return false
			@warning_ignore("unsafe_method_access")
			for key :Variant in obj_a.keys():
				@warning_ignore("unsafe_method_access")
				var value_a :Variant = obj_a[key] if obj_a.has(key) else null
				@warning_ignore("unsafe_method_access")
				var value_b :Variant = obj_b[key] if obj_b.has(key) else null
				if not _equals(value_a, value_b, case_sensitive, compare_mode, deep_stack, stack_depth):
					return false
			return true

		TYPE_STRING:
			if case_sensitive:
				@warning_ignore("unsafe_method_access")
				return obj_a.to_lower() == obj_b.to_lower()
			else:
				return obj_a == obj_b
	return obj_a == obj_b


@warning_ignore("shadowed_variable_base_class")
static func notification_as_string(instance :Variant, notification :int) -> String:
	var error := "Unknown notification: '%s' at instance:  %s" % [notification, instance]
	if instance is Node and NOTIFICATION_AS_STRING_MAPPINGS[TYPE_NODE].has(notification):
		return NOTIFICATION_AS_STRING_MAPPINGS[TYPE_NODE].get(notification, error)
	if instance is Control and NOTIFICATION_AS_STRING_MAPPINGS[TYPE_CONTROL].has(notification):
		return NOTIFICATION_AS_STRING_MAPPINGS[TYPE_CONTROL].get(notification, error)
	return NOTIFICATION_AS_STRING_MAPPINGS[TYPE_OBJECT].get(notification, error)


static func string_to_type(value :String) -> int:
	for type :int in TYPE_AS_STRING_MAPPINGS.keys():
		if TYPE_AS_STRING_MAPPINGS.get(type) == value:
			return type
	return TYPE_NIL


static func to_camel_case(value :String) -> String:
	var p := to_pascal_case(value)
	if not p.is_empty():
		p[0] = p[0].to_lower()
	return p


static func to_pascal_case(value :String) -> String:
	return value.capitalize().replace(" ", "")


@warning_ignore("return_value_discarded")
static func to_snake_case(value :String) -> String:
	var result := PackedStringArray()
	for ch in value:
		var lower_ch := ch.to_lower()
		if ch != lower_ch and result.size() > 1:
			result.append('_')
		result.append(lower_ch)
	return ''.join(result)


static func is_snake_case(value :String) -> bool:
	for ch in value:
		if ch == '_':
			continue
		if ch == ch.to_upper():
			return false
	return true


static func type_as_string(type :int) -> String:
	if type < TYPE_MAX:
		return type_string(type)
	return TYPE_AS_STRING_MAPPINGS.get(type, "Variant")


static func typeof_as_string(value :Variant) -> String:
	return TYPE_AS_STRING_MAPPINGS.get(typeof(value), "Unknown type")


static func all_types() -> PackedInt32Array:
	return PackedInt32Array(TYPE_AS_STRING_MAPPINGS.keys())


static func string_as_typeof(type_name :String) -> int:
	var type :Variant = TYPE_AS_STRING_MAPPINGS.find_key(type_name)
	return type if type != null else TYPE_VARIANT


static func is_primitive_type(value :Variant) -> bool:
	return typeof(value) in [TYPE_BOOL, TYPE_STRING, TYPE_STRING_NAME, TYPE_INT, TYPE_FLOAT]


static func _is_type_equivalent(type_a :int, type_b :int) -> bool:
	# don't test for TYPE_STRING_NAME equivalenz
	if type_a == TYPE_STRING_NAME or type_b == TYPE_STRING_NAME:
		return true
	if GdUnitSettings.is_strict_number_type_compare():
		return type_a == type_b
	return (
		(type_a == TYPE_FLOAT and type_b == TYPE_INT)
		or (type_a == TYPE_INT and type_b == TYPE_FLOAT)
		or type_a == type_b)


static func is_engine_type(value :Variant) -> bool:
	if value is GDScript or value is ScriptExtension:
		return false
	var obj: Object = value
	if is_instance_valid(obj) and obj.has_method("is_class"):
		return obj.is_class("GDScriptNativeClass")
	return false


static func is_type(value :Variant) -> bool:
	# is an build-in type
	if typeof(value) != TYPE_OBJECT:
		return false
	# is a engine class type
	if is_engine_type(value):
		return true
	# is a custom class type
	@warning_ignore("unsafe_cast")
	if value is GDScript and (value as GDScript).can_instantiate():
		return true
	return false


static func _is_same(left :Variant, right :Variant) -> bool:
	var left_type := -1 if left == null else typeof(left)
	var right_type := -1 if right == null else typeof(right)

	# if typ different can't be the same
	if left_type != right_type:
		return false
	if left_type == TYPE_OBJECT and right_type == TYPE_OBJECT:
		@warning_ignore("unsafe_cast")
		return (left as Object).get_instance_id() == (right as Object).get_instance_id()
	return equals(left, right)


static func is_object(value :Variant) -> bool:
	return typeof(value) == TYPE_OBJECT


static func is_script(value :Variant) -> bool:
	return is_object(value) and value is Script


static func is_native_class(value :Variant) -> bool:
	return is_object(value) and is_engine_type(value)


static func is_scene(value :Variant) -> bool:
	return is_object(value) and value is PackedScene


static func is_scene_resource_path(value :Variant) -> bool:
	@warning_ignore("unsafe_cast")
	return value is String and (value as String).ends_with(".tscn")


static func is_singleton(value: Variant) -> bool:
	if not is_instance_valid(value) or is_native_class(value):
		return false
	for name in Engine.get_singleton_list():
		@warning_ignore("unsafe_cast")
		if (value as Object).is_class(name):
			return true
	return false


static func is_instance(value :Variant) -> bool:
	if not is_instance_valid(value) or is_native_class(value):
		return false
	@warning_ignore("unsafe_cast")
	if is_script(value) and (value as Script).get_instance_base_type() == "":
		return true
	if is_scene(value):
		return true
	@warning_ignore("unsafe_cast")
	return not (value as Object).has_method('new') and not (value as Object).has_method('instance')


# only object form type Node and attached filename
static func is_instance_scene(instance :Variant) -> bool:
	if instance is Node:
		var node: Node = instance
		return node.get_scene_file_path() != null and not node.get_scene_file_path().is_empty()
	return false


static func can_be_instantiate(obj :Variant) -> bool:
	if not obj or is_engine_type(obj):
		return false
	@warning_ignore("unsafe_cast")
	return (obj as Object).has_method("new")


static func create_instance(clazz :Variant) -> GdUnitResult:
	match typeof(clazz):
		TYPE_OBJECT:
			# test is given clazz already an instance
			if is_instance(clazz):
				return GdUnitResult.success(clazz)
			@warning_ignore("unsafe_method_access")
			return GdUnitResult.success(clazz.new())
		TYPE_STRING:
			var clazz_name: String = clazz
			if ClassDB.class_exists(clazz_name):
				if Engine.has_singleton(clazz_name):
					return GdUnitResult.error("Not allowed to create a instance for singelton '%s'." % clazz_name)
				if not ClassDB.can_instantiate(clazz_name):
					return  GdUnitResult.error("Can't instance Engine class '%s'." % clazz_name)
				return GdUnitResult.success(ClassDB.instantiate(clazz_name))
			else:
				var clazz_path :String = extract_class_path(clazz_name)[0]
				if not FileAccess.file_exists(clazz_path):
					return GdUnitResult.error("Class '%s' not found." % clazz_name)
				var script: GDScript = load(clazz_path)
				if script != null:
					return GdUnitResult.success(script.new())
				else:
					return GdUnitResult.error("Can't create instance for '%s'." % clazz_name)
	return GdUnitResult.error("Can't create instance for class '%s'." % str(clazz))


## We do dispose 'GDScriptFunctionState' in a kacky style because the class is not visible anymore
static func dispose_function_state(func_state: Variant) -> void:
	if func_state != null and str(func_state).contains("GDScriptFunctionState"):
		@warning_ignore("unsafe_method_access")
		func_state.completed.emit()


@warning_ignore("return_value_discarded")
static func extract_class_path(clazz :Variant) -> PackedStringArray:
	var clazz_path := PackedStringArray()
	if clazz is String:
		@warning_ignore("unsafe_cast")
		clazz_path.append(clazz as String)
		return clazz_path
	if is_instance(clazz):
		# is instance a script instance?
		var script: GDScript = clazz.script
		if script != null:
			return extract_class_path(script)
		return clazz_path

	if clazz is GDScript:
		var script: GDScript = clazz
		if not script.resource_path.is_empty():
			clazz_path.append(script.resource_path)
			return clazz_path
		# if not found we go the expensive way and extract the path form the script by creating an instance
		var arg_list := build_function_default_arguments(script, "_init")
		var instance: Object = script.callv("new", arg_list)
		var clazz_info := inst_to_dict(instance)
		GdUnitTools.free_instance(instance)
		@warning_ignore("unsafe_cast")
		clazz_path.append(clazz_info["@path"] as String)
		if clazz_info.has("@subpath"):
			var sub_path :String = clazz_info["@subpath"]
			if not sub_path.is_empty():
				var sub_paths := sub_path.split("/")
				clazz_path += sub_paths
		return clazz_path
	return clazz_path


static func extract_class_name_from_class_path(clazz_path :PackedStringArray) -> String:
	var base_clazz := clazz_path[0]
	# return original class name if engine class
	if ClassDB.class_exists(base_clazz):
		return base_clazz
	var clazz_name := to_pascal_case(base_clazz.get_basename().get_file())
	for path_index in range(1, clazz_path.size()):
		clazz_name += "." + clazz_path[path_index]
	return  clazz_name


static func extract_class_name(clazz :Variant) -> GdUnitResult:
	if clazz == null:
		return GdUnitResult.error("Can't extract class name form a null value.")

	if is_instance(clazz):
		# is instance a script instance?
		var script: GDScript = clazz.script
		if script != null:
			return extract_class_name(script)
		@warning_ignore("unsafe_cast")
		return GdUnitResult.success((clazz as Object).get_class())

	# extract name form full qualified class path
	if clazz is String:
		var clazz_name: String = clazz
		if ClassDB.class_exists(clazz_name):
			return GdUnitResult.success(clazz_name)
		var source_script :GDScript = load(clazz_name)
		clazz_name = GdScriptParser.new().get_class_name(source_script)
		return GdUnitResult.success(to_pascal_case(clazz_name))

	if is_primitive_type(clazz):
		return GdUnitResult.error("Can't extract class name for an primitive '%s'" % type_as_string(typeof(clazz)))

	if is_script(clazz):
		@warning_ignore("unsafe_cast")
		if (clazz as Script).resource_path.is_empty():
			var class_path := extract_class_name_from_class_path(extract_class_path(clazz))
			return GdUnitResult.success(class_path);
		return extract_class_name(clazz.resource_path)

	# need to create an instance for a class typ the extract the class name
	@warning_ignore("unsafe_method_access")
	var instance :Variant = clazz.new()
	if instance == null:
		return GdUnitResult.error("Can't create a instance for class '%s'" % str(clazz))
	var result := extract_class_name(instance)
	@warning_ignore("return_value_discarded")
	GdUnitTools.free_instance(instance)
	return result


static func extract_inner_clazz_names(clazz_name :String, script_path :PackedStringArray) -> PackedStringArray:
	var inner_classes := PackedStringArray()

	if ClassDB.class_exists(clazz_name):
		return inner_classes
	var script :GDScript = load(script_path[0])
	var map := script.get_script_constant_map()
	for key :String in map.keys():
		var value :Variant = map.get(key)
		if value is GDScript:
			var class_path := extract_class_path(value)
			@warning_ignore("return_value_discarded")
			inner_classes.append(class_path[1])
	return inner_classes


static func extract_class_functions(clazz_name :String, script_path :PackedStringArray) -> Array:
	if ClassDB.class_get_method_list(clazz_name):
		return ClassDB.class_get_method_list(clazz_name)

	if not FileAccess.file_exists(script_path[0]):
		return Array()
	var script :GDScript = load(script_path[0])
	if script is GDScript:
		# if inner class on class path we have to load the script from the script_constant_map
		if script_path.size() == 2 and script_path[1] != "":
			var inner_classes := script_path[1]
			var map := script.get_script_constant_map()
			script = map[inner_classes]
		var clazz_functions :Array = script.get_method_list()
		var base_clazz :String = script.get_instance_base_type()
		if base_clazz:
			return extract_class_functions(base_clazz, script_path)
		return clazz_functions
	return Array()


# scans all registert script classes for given <clazz_name>
# if the class is public in the global space than return true otherwise false
# public class means the script class is defined by 'class_name <name>'
static func is_public_script_class(clazz_name :String) -> bool:
	var script_classes:Array[Dictionary] = ProjectSettings.get_global_class_list()
	for class_info in script_classes:
		if class_info.has("class"):
			if class_info["class"] == clazz_name:
				return true
	return false


static func build_function_default_arguments(script :GDScript, func_name :String) -> Array:
	var arg_list := Array()
	for func_sig in script.get_script_method_list():
		if func_sig["name"] == func_name:
			var args :Array[Dictionary] = func_sig["args"]
			for arg in args:
				var value_type :int = arg["type"]
				var default_value :Variant = default_value_by_type(value_type)
				arg_list.append(default_value)
			return arg_list
	return arg_list


static func default_value_by_type(type :int) -> Variant:
	assert(type < TYPE_MAX)
	assert(type >= 0)

	match type:
		TYPE_NIL: return null
		TYPE_BOOL: return false
		TYPE_INT: return 0
		TYPE_FLOAT: return 0.0
		TYPE_STRING: return ""
		TYPE_VECTOR2: return Vector2.ZERO
		TYPE_VECTOR2I: return Vector2i.ZERO
		TYPE_VECTOR3: return Vector3.ZERO
		TYPE_VECTOR3I: return Vector3i.ZERO
		TYPE_VECTOR4: return Vector4.ZERO
		TYPE_VECTOR4I: return Vector4i.ZERO
		TYPE_RECT2: return Rect2()
		TYPE_RECT2I: return Rect2i()
		TYPE_TRANSFORM2D: return Transform2D()
		TYPE_PLANE: return Plane()
		TYPE_QUATERNION: return Quaternion()
		TYPE_AABB: return AABB()
		TYPE_BASIS: return Basis()
		TYPE_TRANSFORM3D: return Transform3D()
		TYPE_COLOR: return Color()
		TYPE_NODE_PATH: return NodePath()
		TYPE_RID: return RID()
		TYPE_OBJECT: return null
		TYPE_CALLABLE: return Callable()
		TYPE_ARRAY: return []
		TYPE_DICTIONARY: return {}
		TYPE_PACKED_BYTE_ARRAY: return PackedByteArray()
		TYPE_PACKED_COLOR_ARRAY: return PackedColorArray()
		TYPE_PACKED_INT32_ARRAY: return PackedInt32Array()
		TYPE_PACKED_INT64_ARRAY: return PackedInt64Array()
		TYPE_PACKED_FLOAT32_ARRAY: return PackedFloat32Array()
		TYPE_PACKED_FLOAT64_ARRAY: return PackedFloat64Array()
		TYPE_PACKED_STRING_ARRAY: return PackedStringArray()
		TYPE_PACKED_VECTOR2_ARRAY: return PackedVector2Array()
		TYPE_PACKED_VECTOR3_ARRAY: return PackedVector3Array()

	push_error("Can't determine a default value for type: '%s', Please create a Bug issue and attach the stacktrace please." % type)
	return null


static func find_nodes_by_class(root: Node, cls: String, recursive: bool = false) -> Array[Node]:
	if not recursive:
		return _find_nodes_by_class_no_rec(root, cls)
	return _find_nodes_by_class(root, cls)


static func _find_nodes_by_class_no_rec(parent: Node, cls: String) -> Array[Node]:
	var result :Array[Node] = []
	for ch in parent.get_children():
		if ch.get_class() == cls:
			result.append(ch)
	return result


static func _find_nodes_by_class(root: Node, cls: String) -> Array[Node]:
	var result :Array[Node] = []
	var stack  :Array[Node] = [root]
	while stack:
		var node :Node = stack.pop_back()
		if node.get_class() == cls:
			result.append(node)
		for ch in node.get_children():
			stack.push_back(ch)
	return result
