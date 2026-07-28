@tool
extends Container

const GdUnitTools := preload("res://addons/gdUnit4/src/core/GdUnitTools.gd")
const GdUnitUpdateClient := preload("res://addons/gdUnit4/src/update/GdUnitUpdateClient.gd")
const GDUNIT_TEMP := "user://tmp"

@onready var _progress_content: RichTextLabel = %message
@onready var _progress_bar: TextureProgressBar = %progress
@onready var _cancel_btn: Button = %cancel
@onready var _update_btn: Button = %update
@onready var _spinner_img := GdUnitUiTools.get_spinner()


var _debug_mode := false
var _update_client :GdUnitUpdateClient
var _download_url :String


func _ready() -> void:
	init_progress(6)


func _process(_delta :float) -> void:
	if _progress_content != null and _progress_content.is_visible_in_tree():
		_progress_content.queue_redraw()


func init_progress(max_value: int) -> void:
	_cancel_btn.disabled = false
	_update_btn.disabled = false
	_progress_bar.max_value = max_value
	_progress_bar.value = 1
	message_h4("Press [Update] to start.", Color.GREEN, false)


func setup(update_client: GdUnitUpdateClient, download_url: String) -> void:
	_update_client = update_client
	_download_url = download_url


func update_progress(message: String, color := Color.GREEN) -> void:
	message_h4(message, color)
	_progress_bar.value += 1
	if _debug_mode:
		await get_tree().create_timer(3).timeout
	await get_tree().create_timer(.2).timeout


func _colored(message: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(), message]


func message_h4(message: String, color: Color, show_spinner := true) -> void:
	_progress_content.clear()
	if show_spinner:
		_progress_content.add_image(_spinner_img)
	_progress_content.append_text(" [font_size=16]%s[/font_size]" % _colored(message, color))
	if _debug_mode:
		prints(message)


@warning_ignore("return_value_discarded")
func run_update() -> void:
	_cancel_btn.disabled = true
	_update_btn.disabled = true

	await update_progress("Downloading the update.")
	await download_release()
	await update_progress("Extracting")
	var zip_file := temp_dir() + "/update.zip"
	var tmp_path := create_temp_dir("update")
	var result :Variant = extract_zip(zip_file, tmp_path)
	if result == null:
		await update_progress("Update failed! .. Rollback.", Color.INDIAN_RED)
		await get_tree().create_timer(3).timeout
		_cancel_btn.disabled = false
		_update_btn.disabled = false
		init_progress(5)
		hide()
		return

	await update_progress("Uninstall GdUnit4.")
	disable_gdUnit()
	if not _debug_mode:
		GdUnitFileAccess.delete_directory("res://addons/gdUnit4/")
	# give editor time to react on deleted files
	await get_tree().create_timer(1).timeout

	await update_progress("Install new GdUnit4 version.")
	if _debug_mode:
		copy_directory(tmp_path, "res://debug")
	else:
		copy_directory(tmp_path, "res://")

	await update_progress("Patch invalid UID's")
	await patch_uids()

	await rebuild_project()

	await update_progress("New GdUnit version successfully installed, Restarting Godot please wait.")
	await get_tree().create_timer(3).timeout
	enable_gdUnit()
	hide()
	GdUnitFileAccess.delete_directory("res://addons/.gdunit_update")
	restart_godot()


func patch_uids(path := "res://addons/gdUnit4/src/") -> void:
	var to_reimport: PackedStringArray
	for file in DirAccess.get_files_at(path):
		var file_path := path.path_join(file)
		var ext := file.get_extension()

		if ext == "tscn" or ext == "scn" or ext == "tres" or ext == "res":
			message_h4("Patch GdUnit4 scene: '%s'" % file, Color.WEB_GREEN)
			remove_uids_from_file(file_path)
		elif FileAccess.file_exists(file_path + ".import"):
			to_reimport.append(file_path)

	if not to_reimport.is_empty():
		message_h4("Reimport resources '%s'" % ", ".join(to_reimport), Color.WEB_GREEN)
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().reimport_files(to_reimport)

	for dir in DirAccess.get_directories_at(path):
		if not dir.begins_with("."):
			patch_uids(path.path_join(dir))
	await get_tree().process_frame


func remove_uids_from_file(file_path: String) -> bool:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to open file: ", file_path)
		return false

	var original_content := file.get_as_text()
	file.close()

	# Remove UIDs using regex
	var regex := RegEx.new()
	regex.compile("(\\[ext_resource[^\\]]*?)\\s+uid=\"uid://[^\"]*\"")

	var modified_content := regex.sub(original_content, "$1", true)

	# Check if any changes were made
	if original_content != modified_content:
		prints("Patched invalid uid's out in '%s'" % file_path)
		# Write the modified content back
		file = FileAccess.open(file_path, FileAccess.WRITE)
		if file == null:
			print("Failed to write to file: ", file_path)
			return false

		file.store_string(modified_content)
		file.close()
		return true

	return false


func restart_godot() -> void:
	prints("Force restart Godot")
	EditorInterface.restart_editor(true)


@warning_ignore("return_value_discarded")
func enable_gdUnit() -> void:
	var enabled_plugins := PackedStringArray()
	if ProjectSettings.has_setting("editor_plugins/enabled"):
		enabled_plugins = ProjectSettings.get_setting("editor_plugins/enabled")
	if not enabled_plugins.has("res://addons/gdUnit4/plugin.cfg"):
		enabled_plugins.append("res://addons/gdUnit4/plugin.cfg")
	ProjectSettings.set_setting("editor_plugins/enabled", enabled_plugins)
	ProjectSettings.save()


func disable_gdUnit() -> void:
	EditorInterface.set_plugin_enabled("gdUnit4", false)


func temp_dir() -> String:
	if not DirAccess.dir_exists_absolute(GDUNIT_TEMP):
		@warning_ignore("return_value_discarded")
		DirAccess.make_dir_recursive_absolute(GDUNIT_TEMP)
	return GDUNIT_TEMP


func create_temp_dir(folder_name :String) -> String:
	var new_folder := temp_dir() + "/" + folder_name
	GdUnitFileAccess.delete_directory(new_folder)
	if not DirAccess.dir_exists_absolute(new_folder):
		@warning_ignore("return_value_discarded")
		DirAccess.make_dir_recursive_absolute(new_folder)
	return new_folder


func copy_directory(from_dir: String, to_dir: String) -> bool:
	if not DirAccess.dir_exists_absolute(from_dir):
		printerr("Source directory not found '%s'" % from_dir)
		return false
	# check if destination exists
	if not DirAccess.dir_exists_absolute(to_dir):
		# create it
		var err := DirAccess.make_dir_recursive_absolute(to_dir)
		if err != OK:
			printerr("Can't create directory '%s'. Error: %s" % [to_dir, error_string(err)])
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
				@warning_ignore("return_value_discarded")
				copy_directory(source + "/", dest)
				continue
			var err := source_dir.copy(source, dest)
			if err != OK:
				printerr("Error checked copy file '%s' to '%s'" % [source, dest])
				return false
		return true
	else:
		printerr("Directory not found: " + from_dir)
		return false


func extract_zip(zip_package: String, dest_path: String) -> Variant:
	var zip: ZIPReader = ZIPReader.new()
	var err := zip.open(zip_package)
	if err != OK:
		printerr("Extracting `%s` failed! Please collect the error log and report this. Error Code: %s" % [zip_package, err])
		return null
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
	return dest_path


func download_release() -> void:
	var zip_file := GdUnitFileAccess.temp_dir() + "/update.zip"
	var response :GdUnitUpdateClient.HttpResponse
	if _debug_mode:
		response = GdUnitUpdateClient.HttpResponse.new(200, PackedByteArray())
		zip_file = "res://update.zip"
		return

	response = await _update_client.request_zip_package(_download_url, zip_file)
	if response.status() != 200:
		push_warning("Update information cannot be retrieved from GitHub! \n Error code: %d : %s" % [response.status(), response.response()])
		message_h4("Download the update failed! Try it later again.", Color.INDIAN_RED)
		await get_tree().create_timer(3).timeout


func rebuild_project() -> void:
	# Check if this is a Godot .NET runtime instance
	if not ClassDB.class_exists("CSharpScript"):
		return

	update_progress("Rebuild the project ...")
	await get_tree().process_frame

	var output := []
	var exit_code := OS.execute("dotnet", ["build"], output)
	if exit_code == -1:
		message_h4("Rebuild the project failed, check your project dependencies.", Color.INDIAN_RED)
		await get_tree().create_timer(3).timeout
		return

	for out: String in output:
		print_rich("[color=DEEP_SKY_BLUE] 		%s" % out.strip_edges())
	await get_tree().process_frame


func _on_confirmed() -> void:
	await run_update()


func _on_cancel_pressed() -> void:
	hide()


func _on_update_pressed() -> void:
	await run_update()
