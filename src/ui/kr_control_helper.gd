## KrControlHelper — static utility for shared Kr* Control setup behavior.
##
## All Kr* Control classes call [method setup] from their [code]_ready()[/code] to apply
## SettingsService signal subscriptions and queue the AccessKit role update.
##
## Design rationale (ADR-0010 §Decision Note): GDScript does not support multiple
## inheritance, so Kr* classes each extend their native Godot Control base directly
## (Container / PanelContainer / Button / …). Shared behavior is reused via this
## static-helper composition pattern instead of a common KrCustomControl base class.
##
## [b]SettingsService wiring[/b]: Real 3-signal subscription (text_scale /
## reduced_motion / focus_indicator_thickness_px) is deferred to story 005 /
## workspace 009. This story guards with [code]Engine.has_singleton("SettingsService")[/code]
## and skips if absent.
##
## [b]AccessKit role API (Godot 4.6 — runtime-verified)[/b]:
## [code]DisplayServer.accessibility_update_set_role()[/code] MUST be called inside
## [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code] (value 3000). Calling it outside that
## notification causes an engine ERROR. The correct pattern:
## [codeblock]
## # In _ready(): queue the update — engine fires NOTIFICATION_ACCESSIBILITY_UPDATE later
## func _ready() -> void:
##     theme_type_variation = &"Pane"
##     KrControlHelper.setup(self)         # calls queue_accessibility_update()
##
## # In _notification(): set the role when the engine requests it
## func _notification(what: int) -> void:
##     if what == NOTIFICATION_ACCESSIBILITY_UPDATE:
##         _apply_access_kit_role()
## [/codeblock]
## [method setup] calls [method Control.queue_accessibility_update] to schedule the
## notification. [method _apply_access_kit_role] is NOT dispatched directly from
## [method setup] — subclasses call it from [code]_notification[/code] override.
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
## TR:  TR-ui-005
class_name KrControlHelper extends RefCounted


## Sets up a Kr* Control instance.
##
## Call from [code]_ready()[/code] in every Kr* subclass after setting
## [member Control.theme_type_variation]:
## [codeblock]
## func _ready() -> void:
##     theme_type_variation = &"Pane"
##     KrControlHelper.setup(self)
## [/codeblock]
##
## Steps performed:
## 1. If [code]SettingsService[/code] autoload is registered, subscribes to the
##    3 settings signals (stub — real wiring in story 005 / workspace 009).
## 2. Calls [method Control.queue_accessibility_update] to schedule
##    [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code]. Subclasses respond to this
##    notification in [code]_notification()[/code] by calling [method _apply_access_kit_role].
##
## [param control]: The Kr* Control instance calling setup (pass [code]self[/code]).
static func setup(control: Control) -> void:
	if Engine.has_singleton("SettingsService"):
		pass  # SettingsService 3-signal subscription — real wiring in story 005 / workspace 009
	control.queue_accessibility_update()
