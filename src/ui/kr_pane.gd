## KrPane — layout panel primitive for 3-pane and section container usage.
##
## Extends [Container] directly (not a common KrCustomControl base — see ADR-0010
## §Decision Note on composition + static-helper pattern). Shared behavior is
## provided via [KrControlHelper.setup].
##
## [b]Theme type variation[/b]: [code]&"Pane"[/code] — PanelContainer + 16px padding
## + 판결지 #F5F2EC background (story 003 populates the actual Theme variation).
##
## [b]AccessKit role[/b]: [code]DisplayServer.AccessibilityRole.ROLE_PANEL[/code] (=6).
## Maps to WAI-ARIA [code]role=group[/code] — closest available in Godot 4.6 (ROLE_REGION
## is absent; see ADR-0010 amend-1 §G1 for the corrected mapping rationale).
##
## [b]Role API note (Godot 4.6 — runtime-verified)[/b]: Role assignment requires
## [code]DisplayServer.accessibility_update_set_role(rid, role)[/code] which MUST be
## called inside [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code] (=3000). The method
## [code]Control.set_accessibility_role()[/code] and property [code]accessibility_role[/code]
## do NOT exist in Godot 4.6. [method KrControlHelper.setup] calls
## [method Control.queue_accessibility_update]; this class handles the notification in
## [method _notification]. The constant [constant ACCESSIBILITY_ROLE] exposes the
## intended role integer for testability without requiring a live display.
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
## TR:  TR-ui-005
class_name KrPane extends Container

## Preloaded to avoid class_name global cache dependency in headless runs.
const _KrControlHelper: Script = preload("res://src/ui/kr_control_helper.gd")


# ─── Constants ────────────────────────────────────────────────────────────────

## Intended AccessKit role integer for this class.
##
## [code]DisplayServer.AccessibilityRole.ROLE_PANEL[/code] = 6.
## Exposed as a constant so unit tests can verify the intended role without
## requiring a live display (the RID-based API is only available inside
## [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code]).
## ADR-0010 amend-1 §G1 corrected mapping: was ROLE_REGION (absent in Godot 4.6).
const ACCESSIBILITY_ROLE: int = 6  # DisplayServer.AccessibilityRole.ROLE_PANEL


# ─── Built-in virtual methods ─────────────────────────────────────────────────

## Applies the [code]&"Pane"[/code] theme type variation and calls
## [method KrControlHelper.setup], which queues [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code].
func _ready() -> void:
	theme_type_variation = &"Pane"
	_KrControlHelper.setup(self)


## Handles [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code] by calling
## [method _apply_access_kit_role] at the correct engine notification cycle.
func _notification(what: int) -> void:
	if what == NOTIFICATION_ACCESSIBILITY_UPDATE:
		_apply_access_kit_role()


# ─── Public methods ────────────────────────────────────────────────────────────

## Assigns the AccessKit role [code]ROLE_PANEL[/code] (=6) via
## [code]DisplayServer.accessibility_update_set_role[/code].
##
## Called from [method _notification] when [code]NOTIFICATION_ACCESSIBILITY_UPDATE[/code]
## fires. The RID is valid inside this notification cycle. Override in subclasses
## to assign a more specific role.
func _apply_access_kit_role() -> void:
	var rid: RID = get_accessibility_element()
	if rid.is_valid():
		DisplayServer.accessibility_update_set_role(rid, DisplayServer.AccessibilityRole.ROLE_PANEL)
