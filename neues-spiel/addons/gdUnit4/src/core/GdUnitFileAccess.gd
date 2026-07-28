class_name GdUnitFileAccess
extends RefCounted

const GDUNIT_TEMP := "user://tmp"


static func current_dir() -> String:
	return ProjectSettings.globalize_path("res://")


static func clear_tmp() -> void:
	delete_directory(GDUNIT_TEMP)


# Creates a new file under
static func create_temp_file(relative_path :String, file_name :String, mode := FileAccess.WRITE) -> FileAccess:
	var file_path := create_temp_dir(relative_path) + "/" + file_name
	var file := FileAccess.open(file_path, mode)
	if file == null:
		push_error("Error creating temporary file at: %s, %s" % [file_path, error_string(FileAccess.get_open_error())])
	return file


static func temp_dir() -> String:
	if not DirAccess.dir_exists_absolute(GDUNIT_TEMP):
		@warning_ignore("return_value_discarded")
		DirAccess.make_dir_recursive_absolute(GDUNIT_TEMP)
	return GDUNIT_TEMP


static func create_temp_dir(folder_name :String) -> String:
	var new_folder := temp_dir() + "/" + folder_name
	if not DirAccess.dir_exists_absolute(new_folder):
		@warning_ignore("return_value_discarded")
		DirAccess.make_dir_recursive_absolute(new_folder)
	return new_folder


static func copy_file(from_file :String, to_dir :String) -> GdUnitResult:
	var dir := DirAccess.open(to_dir)
	if dir != null:
		var to_file := to_dir + "/" + from_file.get_file()
		prints("Copy %s to %s" % [from_file, to_file])
		var error := dir.copy(from_file, to_file)
		if error != OK:
			return GdUnitResult.error("Can't copy file form '%s' to '%s'. Error: '%s'" % [from_file, to_file, error_string(error)])
		return GdUnitResult.success(to_file)
	return GdUnitResult.error("Directory not found: " + to_dir)


static func copy_directory(from_dir :String, to_dir :String, recursive :bool = false) -> bool:
	if not DirAccess.dir_exists_absolute(from_dir):
		push_error("Source directory not found '%s'" % from_dir)
		return false

	# check if destination exists
	if not DirAccess.dir_exists_absolute(to_dir):
		# create it
		var err := DirAccess.make_dir_recursive_absolute(to_dir)
		if err != OK:
			push_error("Can't create directory '%s'. Error: %s" % [to_dir, error_string(err)])
			return false
	var source_dir := DirAccess.open(from_dir)
	var dest_dir := DirAccess.open(to_dir)
	if source_dir != null:
		@warning_ignore("return_value_discarded")
		source_dir.list_dir_begin()
		var next := "."

		while next != "":
			next = source_dir.get_next()
			if next == "" or next == "." or next == "..":
				continue
			var source := source_dir.get_current_dir() + "/" + next
			var dest := dest_dir.get_current_dir() + "/" + next
			if source_dir.current_is_dir():
				if recursive:
					@warning_ignore("return_value_discarded")
					copy_directory(source + "/", dest, recursive)
				continue
			var err := source_dir.copy(source, dest)
			if err != OK:
				push_error("Error checked copy file '%s' to '%s'" % [source, dest])
				return false

		return true
	else:
		push_error("Directory not found: " + from_dir)
		return false


static func delete_directory(path :String, only_content := false) -> void:
	var dir := DirAccess.open(path)
	if dir != null:
		dir.include_hidden = true
		@warning_ignore("return_value_discarded")
		dir.list_dir_begin()
		var file_name := "."
		while file_name != "":
			file_name = dir.get_next()
			if file_name.is_empty() or file_name == "." or file_name == "..":
				continue
			var next := path + "/" +file_name
			if dir.current_is_dir():
				delete_directory(next)
			else:
				# delete file
				var err := dir.remove(next)
				if err:
					push_error("Delete %s failed: %s" % [next, error_string(err)])
		if not only_content:
			var err := dir.remove(path)
			if err:
				push_error("Delete %s failed: %s" % [path, error_string(err)])


static func delete_path_index_lower_equals_than(path :String, prefix :String, index :int) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	var deleted := 0
	@warning_ignore("return_value_discarded")
	dir.list_dir_begin()
	var next := "."
	while next != "":
		next = dir.get_next()
		if next.is_empty() or next == "." or next == "..":
			continue
		if next.begins_with(prefix):
			var current_index := next.split("_")[1].to_int()
			if current_index <= index:
				deleted += 1
				delete_directory(path + "/" + next)
	return deleted


# scans given path for sub directories by given prefix and returns the highest index numer
# e.g. <prefix_%d>
static func find_last_path_index(path :String, prefix :String) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	var last_iteration := 0
	@warning_ignore("return_value_discarded")
	dir.list_dir_begin()
	var next := "."
	while next != "":
		next = dir.get_next()
		if next.is_empty() or next == "." or next == "..":
			continue
		if next.begins_with(prefix):
			var iteration := next.split("_")[1].to_int()
			if iteration > last_iteration:
				last_iteration = iteration
	return last_iteration


static func as_resource_path(value: String) -> String:
	if value.begins_with("res://"):
		return value
	return "res://" + value.trim_prefix("//").trim_prefix("/").trim_suffix("/")


static func scan_dir(path :String) -> PackedStringArray:
	var dir := DirAccess.open(path)
	if dir == null or not dir.dir_exists(path):
		return PackedStringArray()
	var content := PackedStringArray()
	dir.include_hidden = true
	@warning_ignore("return_value_discarded")
	dir.list_dir_begin()
	var next := "."
	while next != "":
		next = dir.get_next()
		if next.is_empty() or next == "." or next == "..":
			continue
		@warning_ignore("return_value_discarded")
		content.append(next)
	return content


static func resource_as_array(resource_path :String) -> PackedStringArray:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("ERROR: Can't read resource '%s'. %s" % [resource_path, error_string(FileAccess.get_open_error())])
		return PackedStringArray()
	var file_content := PackedStringArray()
	while not file.eof_reached():
		@warning_ignore("return_value_discarded")
		file_content.append(file.get_line())
	return file_content


static func resource_as_string(resource_path :String) -> String:
	var file := FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("ERROR: Can't read resource '%s'. %s" % [resource_path, error_string(FileAccess.get_open_error())])
		return ""
	return file.get_as_text()


static func make_qualified_path(path :String) -> String:
	if path.begins_with("res://"):
		return path
	if path.begins_with("//"):
		return path.replace("//", "res://")
	if path.begins_with("/"):
		return "res:/" + path
	return path


static func extract_zip(zip_package :String, dest_path :String) -> GdUnitResult:
	var zip: ZIPReader = ZIPReader.new()
	var err := zip.open(zip_package)
	if err != OK:
		return GdUnitResult.error("Extracting `%s` failed! Please collect the error log and report this. Error Code: %s" % [zip_package, err])
	var zip_entries: PackedStringArray = zip.get_files()
	# Get base path and step over archive folder
	var archive_path := zip_entries[0]
	zip_entries.remove_at(0)

	for zip_entry in zip_entries:
		var new_file_path: String = dest_path + "/" + zip_entry.replace(archive_path, "")
		if zip_entry.ends_with("/"):
			@warning_ignore("return_value_discarded")
			DirAccess.make_dir_recursive_absolute(new_file_path)
			continue
		var file: FileAccess = FileAccess.open(new_file_path, FileAccess.WRITE)
		file.store_buffer(zip.read_file(zip_entry))
	@warning_ignore("return_value_discarded")
	zip.close()
	return GdUnitResult.success(dest_path)
