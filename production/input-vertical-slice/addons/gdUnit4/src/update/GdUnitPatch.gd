class_name GdUnitPatch
extends RefCounted

const PATCH_VERSION = "patch_version"

var _version :GdUnit4Version


func _init(version_ :GdUnit4Version) -> void:
	_version = version_


func version() -> GdUnit4Version:
	return _version


# this function needs to be implement
func execute() -> bool:
	push_error("The function 'execute()' is not implemented at %s" % self)
	return false
