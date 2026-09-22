################################################################################
# Provides access to a global accessible singleton
#
# This is a workarount to the existing auto load singleton because of some bugs
# around plugin handling
################################################################################
class_name GdUnitSingleton
extends Object


const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")
const MEATA_KEY := "GdUnitSingletons"


static func instance(name: String, clazz: Callable) -> Variant:
	if Engine.has_meta(name):
		return Engine.get_meta(name)
	var singleton: Variant = clazz.call()
	if  is_instance_of(singleton, RefCounted):
		@warning_ignore("unsafe_cast")
		push_error("Invalid singleton implementation detected for '%s' is `%s`!" % [name, (singleton as RefCounted).get_class()])
		return

	Engine.set_meta(name, singleton)
	GdUnitTools.prints_verbose("Register singleton '%s:%s'" % [name, singleton])
	var singletons: PackedStringArray = Engine.get_meta(MEATA_KEY, PackedStringArray())
	@warning_ignore("return_value_discarded")
	singletons.append(name)
	Engine.set_meta(MEATA_KEY, singletons)
	return singleton


static func unregister(p_singleton: String, use_call_deferred: bool = false) -> void:
	var singletons: PackedStringArray = Engine.get_meta(MEATA_KEY, PackedStringArray())
	if singletons.has(p_singleton):
		GdUnitTools.prints_verbose("\n	Unregister singleton '%s'" % p_singleton);
		var index := singletons.find(p_singleton)
		singletons.remove_at(index)
		var instance_: Object = Engine.get_meta(p_singleton)
		GdUnitTools.prints_verbose("	Free singleton instance '%s:%s'" % [p_singleton, instance_])
		@warning_ignore("return_value_discarded")
		GdUnitTools.free_instance(instance_, use_call_deferred)
		Engine.remove_meta(p_singleton)
		GdUnitTools.prints_verbose("	Successfully freed '%s'" % p_singleton)
	Engine.set_meta(MEATA_KEY, singletons)


static func dispose(use_call_deferred: bool = false) -> void:
	# use a copy because unregister is modify the singletons array
	var singletons: PackedStringArray = Engine.get_meta(MEATA_KEY, PackedStringArray())
	GdUnitTools.prints_verbose("----------------------------------------------------------------")
	GdUnitTools.prints_verbose("Cleanup singletons %s" % singletons)
	for singleton in PackedStringArray(singletons):
		unregister(singleton, use_call_deferred)
	Engine.remove_meta(MEATA_KEY)
	GdUnitTools.prints_verbose("----------------------------------------------------------------")
