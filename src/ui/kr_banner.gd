## KrBanner — non-editable banner / notification strip primitive.
##
## Extends [PanelContainer] directly (not a common KrCustomControl base — see ADR-0010
## §Decision Note on composition + static-helper pattern). Shared behavior is
## provided via [KrControlHelper.setup].
##
## [b]Theme type variation[/b]: [code]&"Banner"[/code] — 32px height + 잉크블랙
## background + 흰 텍스트 (story 003 populates the actual Theme variation). Subclass
## variations (ReadOnlyBanner / CriticalBanner / ToastBanner) use more specific tags.
##
## [b]AccessKit role[/b]: [code]DisplayServer.AccessibilityRole.ROLE_STATIC_TEXT[/code] (=4).
## Godot 4.6 has no WAI-ARIA [code]role=status[/code] or [code]role=alert[/code]
## equivalent in [code]AccessibilityRole[/code]. Live-region semantics are handled
## separately via [code]UIService.announce_text()[/code] (ADR-0010 amend-1 §G2/§G3).
## Dynamic banners MUST call [code]UIService.announce_text()[/code] on appearance —
## see forbidden pattern [code]kr_banner_dynamic_show_without_announce[/code] in
## [code]docs/registry/architecture.yaml[/code].
##
## [b]Role API note (Godot 4.6 deviation)[/b]: There is no [code]Control.set_accessibility_role()[/code]
## or [code]accessibility_role[/code] property in Godot 4.6. See [constant ACCESSIBILITY_ROLE].
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
## TR:  TR-ui-005
class_name KrBanner extends PanelContainer

## Preloaded to avoid class_name global cache dependency in headless runs.
const _KrControlHelper: Script = preload("res://src/ui/kr_control_helper.gd")


# ─── Constants ────────────────────────────────────────────────────────────────

## Intended AccessKit role integer for this class.
##
## [code]DisplayServer.AccessibilityRole.ROLE_STATIC_TEXT[/code] = 4.
## Godot 4.6 has no [code]ROLE_STATUS[/code] or [code]ROLE_ALERT[/code]
## (hallucinated names — see ADR-0010 amend-1 §G1). ROLE_STATIC_TEXT is the
## correct cap for all KrBanner family members.
const ACCESSIBILITY_ROLE: int = 4  # DisplayServer.AccessibilityRole.ROLE_STATIC_TEXT


# ─── Built-in virtual methods ─────────────────────────────────────────────────

## Applies the [code]&"Banner"[/code] theme type variation and calls
## [method KrControlHelper.setup], which queues [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code].
func _ready() -> void:
	theme_type_variation = &"Banner"
	_KrControlHelper.setup(self)


## Handles [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code] by calling
## [method _apply_access_kit_role] at the correct engine notification cycle.
func _notification(what: int) -> void:
	if what == NOTIFICATION_ACCESSIBILITY_UPDATE:
		_apply_access_kit_role()


# ─── Public methods ────────────────────────────────────────────────────────────

## Assigns the AccessKit role [code]ROLE_STATIC_TEXT[/code] (=4) via
## [code]DisplayServer.accessibility_update_set_role[/code].
##
## Called from [method _notification] when [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code]
## fires (the RID from [method Control.get_accessibility_element] is only valid inside
## that notification cycle). The call is silently skipped if the RID is invalid
## (headless / editor-only contexts). Override in subclasses if a different
## non-interactive text role is appropriate.
func _apply_access_kit_role() -> void:
	var rid: RID = get_accessibility_element()
	if rid.is_valid():
		DisplayServer.accessibility_update_set_role(rid, DisplayServer.AccessibilityRole.ROLE_STATIC_TEXT)
