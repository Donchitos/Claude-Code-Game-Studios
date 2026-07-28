class_name GdUnitPatcher
extends RefCounted


const _base_dir := "res://addons/gdUnit4/src/update/patches/"

var _patches := Dictionary()


func scan(current :GdUnit4Version) -> void:
	_scan(_base_dir, current)


func _scan(scan_path :String, current :GdUnit4Version) -> void:
	_patches = Dictionary()
	var patch_paths := _collect_patch_versions(scan_path, current)
	for path in patch_paths:
		prints("scan for patches checked '%s'" % path)
		_patches[path] = _scan_patches(path)


func patch_count() -> int:
	var count := 0
	for key :String in _patches.keys():
		@warning_ignore("unsafe_method_access")
		count += _patches[key].size()
	return count


func execute() -> void:
	for key :String in _patches.keys():
		for path :String in _patches[key]:
			var patch :GdUnitPatch = (load(key + "/" + path) as GDScript).new()
			if patch:
				prints("execute patch", patch.version(), patch.get_script().resource_path)
				if not patch.execute():
					prints("error checked execution patch %s" % key + "/" + path)


func _collect_patch_versions(scan_path :String, current :GdUnit4Version) -> PackedStringArray:
	if not DirAccess.dir_exists_absolute(scan_path):
		return PackedStringArray()
	var patches := Array()
	var dir := DirAccess.open(scan_path)
	if dir != null:
		@warning_ignore("return_value_discarded")
		dir.list_dir_begin() # TODO GODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := "."
		while next != "":
			next = dir.get_next()
			if next.is_empty() or next == "." or next == "..":
				continue
			var version := GdUnit4Version.parse(next)
			if version.is_greater(current):
				patches.append(scan_path + next)
	patches.sort()
	return PackedStringArray(patches)


func _scan_patches(path :String) -> PackedStringArray:
	var patches := Array()
	var dir := DirAccess.open(path)
	if dir != null:
		@warning_ignore("return_value_discarded")
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var next := "."
		while next != "":
			next = dir.get_next()
			# step over directory links and .uid files
			if next.is_empty() or next == "." or next == ".." or next.ends_with(".uid"):
				continue
			patches.append(next)
	# make sorted from lowest to high version
	patches.sort()
	return PackedStringArray(patches)
