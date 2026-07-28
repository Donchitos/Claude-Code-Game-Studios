@tool
extends MarginContainer

#signal request_completed(response)

const GdMarkDownReader = preload("res://addons/gdUnit4/src/update/GdMarkDownReader.gd")
const GdUnitUpdateClient = preload("res://addons/gdUnit4/src/update/GdUnitUpdateClient.gd")
const GdUnitUpdateProgress = preload("res://addons/gdUnit4/src/update/GdUnitUpdate.gd")

@onready var _md_reader: GdMarkDownReader = GdMarkDownReader.new()
@onready var _update_client: GdUnitUpdateClient = $GdUnitUpdateClient
@onready var _header: Label = $Panel/GridContainer/PanelContainer/header
@onready var _update_button: Button = $Panel/GridContainer/Panel/HBoxContainer/update
@onready var _content: RichTextLabel = $Panel/GridContainer/PanelContainer2/ScrollContainer/MarginContainer/content
@onready var _update_progress :GdUnitUpdateProgress = %update_banner

var _debug_mode := false
var _patcher := GdUnitPatcher.new()
var _current_version := GdUnit4Version.current()


func _ready() -> void:
	_update_button.set_disabled(false)
	_md_reader.set_http_client(_update_client)
	@warning_ignore("return_value_discarded")
	#GdUnitFonts.init_fonts(_content)
	_update_progress.set_visible(false)
	_update_progress.hidden.connect(func() -> void:
		_update_button.set_disabled(false)
	)


func request_releases() -> bool:
	if _debug_mode:
		_update_progress._debug_mode = _debug_mode
		_header.text = "A new version 'v4.4.4' is available"
		_update_button.set_disabled(false)
		return true

	var response :GdUnitUpdateClient.HttpResponse = await _update_client.request_latest_version()
	if response.status() != 200:
		_header.text = "Update information cannot be retrieved from GitHub!"
		message_h4("\n\nError: %s" % response.response(), Color.INDIAN_RED)
		return false
	var latest_version := _update_client.extract_latest_version(response)
	# if same version exit here no update need
	if latest_version.is_greater(_current_version):
		_patcher.scan(_current_version)
		_header.text = "A new version '%s' is available" % latest_version
		var download_zip_url := extract_zip_url(response)
		_update_progress.setup(_update_client, download_zip_url)
		_update_button.set_disabled(false)
		return true
	else:
		_header.text = "No update is available."
		_update_button.set_disabled(true)
		return false


func _colored(message_: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(), message_]


func message_h4(message_: String, color: Color, clear := true) -> void:
	if clear:
		_content.clear()
	_content.append_text("[font_size=16]%s[/font_size]" % _colored(message_, color))


func message(message_: String, color: Color) -> void:
	_content.clear()
	_content.append_text(_colored(message_, color))


func _process(_delta: float) -> void:
	if _content != null and _content.is_visible_in_tree():
		_content.queue_redraw()


func show_update() -> void:
	if not GdUnitSettings.is_update_notification_enabled():
		_header.text = "No update is available."
		message_h4("The search for updates is deactivated.", Color.CORNFLOWER_BLUE)
		_update_button.set_disabled(true)
		return

	if not await request_releases():
		return
	_update_button.set_disabled(true)

	prints("Scan for GdUnit4 Update ...")
	message_h4("\n\n\nRequest release infos ... ", Color.SNOW)
	_content.add_image(GdUnitUiTools.get_spinner(), 32, 32)

	var content: String
	if _debug_mode:
		await get_tree().create_timer(.2).timeout
		var template := FileAccess.open("res://addons/gdUnit4/test/update/resources/http_response_releases.txt", FileAccess.READ).get_as_text()
		content = await _md_reader.to_bbcode(template)
	else:
		var response :GdUnitUpdateClient.HttpResponse = await _update_client.request_releases()
		if response.status() == 200:
			content = await extract_releases(response, _current_version)
		else:
			message_h4("\n\n\nError checked request available releases!", Color.INDIAN_RED)
			return

	# finally force rescan to import images as textures
	if Engine.is_editor_hint():
		await rescan()
	message(content, Color.CADET_BLUE)
	_update_button.set_disabled(false)



func extract_zip_url(response: GdUnitUpdateClient.HttpResponse) -> String:
	var body :Array = response.response()
	return body[0]["zipball_url"]


func extract_releases(response: GdUnitUpdateClient.HttpResponse, current_version: GdUnit4Version) -> String:
	await get_tree().process_frame
	var result := ""
	for release :Dictionary in response.response():
		var release_version := str(release["tag_name"])
		if GdUnit4Version.parse(release_version).equals(current_version):
			break
		var release_description := _colored("<h1>GdUnit Release %s</h1>" % release_version, Color.CORNFLOWER_BLUE)
		release_description += "\n"
		release_description += release["body"]
		release_description += "\n\n"
		result += await _md_reader.to_bbcode(release_description)
	return result


func rescan() -> void:
	if Engine.is_editor_hint():
		if OS.is_stdout_verbose():
			prints(".. reimport release resources")
		var fs := EditorInterface.get_resource_filesystem()
		fs.scan()
		while fs.is_scanning():
			if OS.is_stdout_verbose():
				progressBar(fs.get_scanning_progress() * 100 as int)
			await get_tree().process_frame
		await get_tree().process_frame
	await get_tree().create_timer(1).timeout


func progressBar(p_progress: int) -> void:
	if p_progress < 0:
		p_progress = 0
	if p_progress > 100:
		p_progress = 100
	printraw("scan [%-50s] %-3d%%\r" % ["".lpad(int(p_progress/2.0), "#").rpad(50, "-"), p_progress])


@warning_ignore("return_value_discarded")
func _on_update_pressed() -> void:
	_update_button.set_disabled(true)
	# close all opend scripts before start the update
	if not _debug_mode:
		ScriptEditorControls.close_open_editor_scripts()
	# copy update source to a temp because the update is deleting the whole gdUnit folder
	DirAccess.make_dir_absolute("res://addons/.gdunit_update")
	DirAccess.copy_absolute("res://addons/gdUnit4/src/update/GdUnitUpdate.tscn", "res://addons/.gdunit_update/GdUnitUpdate.tscn")
	DirAccess.copy_absolute("res://addons/gdUnit4/src/update/GdUnitUpdate.gd", "res://addons/.gdunit_update/GdUnitUpdate.gd")
	var source := FileAccess.open("res://addons/gdUnit4/src/update/GdUnitUpdate.tscn", FileAccess.READ)
	var content := source.get_as_text().replace("res://addons/gdUnit4/src/update/GdUnitUpdate.gd", "res://addons/.gdunit_update/GdUnitUpdate.gd")
	var dest := FileAccess.open("res://addons/.gdunit_update/GdUnitUpdate.tscn", FileAccess.WRITE)
	dest.store_string(content)
	_update_progress.set_visible(true)


func _on_show_next_toggled(enabled: bool) -> void:
	GdUnitSettings.set_update_notification(enabled)


func _on_cancel_pressed() -> void:
	hide()


func _on_content_meta_clicked(meta: String) -> void:
	var properties: Dictionary = str_to_var(meta)
	if properties.has("url"):
		@warning_ignore("return_value_discarded")
		OS.shell_open(str(properties.get("url")))


func _on_content_meta_hover_started(meta: String) -> void:
	var properties: Dictionary = str_to_var(meta)
	if properties.has("tool_tip"):
		_content.set_tooltip_text(str(properties.get("tool_tip")))


@warning_ignore("unused_parameter")
func _on_content_meta_hover_ended(meta: String) -> void:
	_content.set_tooltip_text("")


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	if _update_progress != null:
		_update_progress.set_visible(false)
	await show_update()
