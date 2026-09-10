## Provides editor theme colors sourced from [EditorSettings].
## Add this node to the scene tree so it auto-refreshes colors when the
## editor theme changes ([constant EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED]).
@tool
class_name GdUnitEditorColorTheme
extends Node


# Literal value of EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED.
# The editor classes must not be referenced by name anywhere in this script:
# they do not exist in template builds (exported games, CLI runners), where a
# direct reference fails to PARSE this script and every script depending on
# it - the runtime Engine.is_editor_hint() guard never gets a chance.
const _NOTIFICATION_EDITOR_SETTINGS_CHANGED := 10000

static var text_color := Color.WEB_GRAY
static var folder_color := Color.LIGHT_SKY_BLUE
static var function_definition_color := Color.ANTIQUE_WHITE
static var engine_type_color := Color.ANTIQUE_WHITE
static var value_color := Color.DODGER_BLUE

# test state colors
static var state_initial := Color.LIGHT_GRAY
static var state_success := Color.WEB_GREEN
static var state_warning := Color.DARK_GOLDENROD
static var state_flaky := Color.GREEN_YELLOW
static var state_failure := Color.ORANGE_RED
static var state_error := Color.DARK_RED
static var state_skipped := Color.WEB_GRAY
static var state_orphan := Color.DARK_GOLDENROD


func _ready() -> void:
	setup()


func _notification(what: int) -> void:
	if what == _NOTIFICATION_EDITOR_SETTINGS_CHANGED:
		setup()


static func setup() -> void:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return
	# Resolved via the singleton registry instead of naming EditorInterface -
	# see the parse-time note above; on template builds the defaults apply.
	var editor_interface: Object = Engine.get_singleton("EditorInterface")
	var settings: Object = editor_interface.call("get_editor_settings")
	text_color = settings.call("get_setting", "text_editor/theme/highlighting/text_color")
	folder_color = settings.call("get_setting", "text_editor/theme/highlighting/member_variable_color")
	function_definition_color = settings.call("get_setting", "text_editor/theme/highlighting/gdscript/function_definition_color")
	engine_type_color = settings.call("get_setting", "text_editor/theme/highlighting/engine_type_color")
	value_color = settings.call("get_setting", "text_editor/theme/highlighting/function_color")
	# init test state colors
	state_initial = text_color
	state_success = settings.call("get_setting", "editors/animation/onion_layers_future_color")
	state_warning = settings.call("get_setting", "text_editor/theme/highlighting/comment_markers/warning_color")
	state_flaky = settings.call("get_setting", "text_editor/theme/highlighting/gdscript/node_reference_color")
	state_failure = settings.call("get_setting", "text_editor/theme/highlighting/comment_markers/critical_color")
	state_error = settings.call("get_setting", "editors/2d/smart_snapping_line_color")
	state_orphan = settings.call("get_setting", "text_editor/theme/highlighting/string_placeholder_color")
