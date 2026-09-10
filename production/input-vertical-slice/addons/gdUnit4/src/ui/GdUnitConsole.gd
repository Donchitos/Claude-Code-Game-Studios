@tool
extends Control

const GdUnitUpdateClient = preload("res://addons/gdUnit4/src/update/GdUnitUpdateClient.gd")
const TITLE = "gdUnit4 ${version} Console"

@onready var header := $VBoxContainer/Header
@onready var title: RichTextLabel = $VBoxContainer/Header/header_title
@onready var output: RichTextLabel = $VBoxContainer/Console/TextEdit


var _test_reporter: GdUnitConsoleTestReporter


func _ready() -> void:
	GdUnitFonts.init_fonts(output)
	output.add_theme_constant_override("line_separation", 3)
	GdUnit4Version.init_version_label(title)
	GdUnitSignals.instance().gdunit_event.connect(_on_gdunit_event)
	GdUnitSignals.instance().gdunit_message.connect(_on_gdunit_message)
	GdUnitSignals.instance().gdunit_client_connected.connect(_on_gdunit_client_connected)
	GdUnitSignals.instance().gdunit_client_disconnected.connect(_on_gdunit_client_disconnected)
	_test_reporter = GdUnitConsoleTestReporter.new(GdUnitRichTextMessageWriter.new(output))


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var instance := GdUnitSignals.instance()
		if instance.gdunit_event.is_connected(_on_gdunit_event):
			instance.gdunit_event.disconnect(_on_gdunit_event)
		if instance.gdunit_message.is_connected(_on_gdunit_event):
			instance.gdunit_message.disconnect(_on_gdunit_message)
		if instance.gdunit_client_connected.is_connected(_on_gdunit_event):
			instance.gdunit_client_connected.disconnect(_on_gdunit_client_connected)
		if instance.gdunit_client_disconnected.is_connected(_on_gdunit_event):
			instance.gdunit_client_disconnected.disconnect(_on_gdunit_client_disconnected)


func setup_update_notification(control: Button) -> void:
	if not GdUnitSettings.is_update_notification_enabled():
		_test_reporter.println_message("The search for updates is deactivated.", Color.CORNFLOWER_BLUE)
		return

	_test_reporter.print_message("Searching for updates... ", Color.CORNFLOWER_BLUE)
	var update_client := GdUnitUpdateClient.new()
	add_child(update_client)
	var response :GdUnitUpdateClient.HttpResponse = await update_client.request_latest_version()
	if response.status() != 200:
		_test_reporter.println_message("Information cannot be retrieved from GitHub!", GdUnitEditorColorTheme.state_failure)
		_test_reporter.println_message("Error:  %s" % response.response(), GdUnitEditorColorTheme.state_failure)
		return
	var latest_version := update_client.extract_latest_version(response)
	if not latest_version.is_greater(GdUnit4Version.current()):
		_test_reporter.println_message("GdUnit4 is up-to-date.", GdUnitEditorColorTheme.state_success)
		return

	_test_reporter.println_message("A new update is available %s" % latest_version, GdUnitEditorColorTheme.state_warning)
	_test_reporter.println_message("Open the GdUnit4 settings and check the update tab.", GdUnitEditorColorTheme.state_warning)

	control.icon = GdUnitUiTools.get_icon("Notification", GdUnitEditorColorTheme.state_warning)
	var tween := create_tween()
	tween.tween_property(control, "self_modulate", Color.VIOLET, .2).set_trans(Tween.TransitionType.TRANS_LINEAR)
	tween.tween_property(control, "self_modulate", GdUnitEditorColorTheme.state_warning, .2).set_trans(Tween.TransitionType.TRANS_BOUNCE)
	tween.parallel()
	tween.tween_property(control, "scale", Vector2.ONE*1.05, .4).set_trans(Tween.TransitionType.TRANS_LINEAR)
	tween.tween_property(control, "scale", Vector2.ONE, .4).set_trans(Tween.TransitionType.TRANS_BOUNCE)
	tween.set_loops(-1)
	tween.play()


func _on_gdunit_event(event: GdUnitEvent) -> void:
	match event.type():
		GdUnitEvent.SESSION_START:
			_test_reporter.test_session = GdUnitTestSession.new(GdUnitTestDiscoverGuard.instance().get_discovered_tests(), "")
		GdUnitEvent.SESSION_CLOSE:
			_test_reporter.test_session = null


func _on_gdunit_client_connected(client_id: int) -> void:
	_test_reporter.clear()
	_test_reporter.println_message("GdUnit Test Client connected with id: %d" % client_id, GdUnitEditorColorTheme.folder_color)


func _on_gdunit_client_disconnected(client_id: int) -> void:
	_test_reporter.println_message("GdUnit Test Client disconnected with id: %d" % client_id, GdUnitEditorColorTheme.folder_color)


func _on_gdunit_message(message: String) -> void:
	_test_reporter.println_message(message, GdUnitEditorColorTheme.folder_color)
