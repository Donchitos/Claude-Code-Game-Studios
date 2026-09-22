# fuzzer to get available godot class names
class_name GodotClassNameFuzzer
extends Fuzzer

var class_names :Array[String] = []

const EXCLUDED_CLASSES = [
	"JavaClass",
	"GDScript",
	"_ClassDB",
	"MainLoop",
	"JNISingleton",
	"SceneTree",
	"WebRTC",
	"WebRTCPeerConnection",
	"Tween",
	"TextServerAdvanced",
	"InputEventShortcut",
	"FramebufferCacheRD",
	"UniformSetCacheRD",
	# GD-110 - missing enum `Vector3.Axis`
	"Sprite3D", "AnimatedSprite3D", "LookAtModifier3D",
	# Godot-4-4_dev5 unknown classes
	"AnimationNodeStartState",
	"AnimationNodeEndState",
	# Godot-4-4_dev7 get_class issues
	"UPNPDevice",
	"UPNP"
]


func _init(no_singleton :bool = false, only_instancialbe :bool = false) -> void:
	#class_names = ClassDB.get_class_list()
	for clazz_name in ClassDB.get_class_list():
		#https://github.com/godotengine/godot/issues/67643
		if clazz_name.contains("Extension"):
			continue
		if no_singleton and Engine.has_singleton(clazz_name):
			continue
		if only_instancialbe and not ClassDB.can_instantiate(clazz_name):
			continue
		# exclude special classes
		if EXCLUDED_CLASSES.has(clazz_name):
			continue
		# exlude Godot 3.5 *Tweener classes where produces and error
		# `ERROR: Can't create empty IntervalTweener. Use get_tree().tween_property() or tween_property() instead.`
		if clazz_name.find("Tweener") != -1:
			continue
		class_names.push_back(clazz_name)


func next_value() -> String:
	return class_names[randi() % class_names.size()]
