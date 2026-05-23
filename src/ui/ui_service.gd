## UIService — autoload SECOND. Theme + Reduced Motion gateway + announce_text SSOT.
##
## Story 001 scope: Theme instance + viewport_resized signal + ui_service_initialized signal.
## Stories 003/004/005 populate Theme variations, add tween_property gateway, announce_text API.
##
## [b]Registration[/b]: Add to [code]project.godot[/code] [autoload] section as
## [code]UIService="*res://src/ui/ui_service.gd"[/code] SECOND position
## (after LibraryService, before CaseService).
##
## [b]Class binding note[/b]: class_name is [code]UIServiceClass[/code] (not UIService)
## because Godot 4.6 rejects scripts where class_name equals the autoload node name
## ("Class X hides an autoload singleton" error). The autoload registration publishes
## the [code]UIService[/code] global symbol independently.
##
## [b]Theme access[/b]: [member theme] is a read-only property. Direct assignment is
## rejected with [code]push_error[/code] and no mutation (Option C guard pattern —
## same as WorkspaceData.state). Story 003 populates type variations via UIService
## API methods; story 001 registers an empty Theme as the cascade root.
##
## [b]Viewport reflow[/b]: [signal viewport_reflow_needed] is debounced by
## [constant VIEWPORT_REFLOW_DEBOUNCE_MS] milliseconds. Multiple [code]size_changed[/code]
## fires within the debounce window coalesce into exactly one [signal viewport_reflow_needed]
## emit (timer.start() resets an already-running timer).
##
## ADR: docs/architecture/adr-0010-ui-foundation-architecture.md
## TR:  TR-ui-001
class_name UIServiceClass extends Node


# ─── Constants ────────────────────────────────────────────────────────────────

## Debounce window in milliseconds for viewport size changes.
##
## AC-1.4: Multiple [code]size_changed[/code] fires within this window coalesce
## into exactly one [signal viewport_reflow_needed] emit.
## GDD §7.1 source value: 50 ms.
const VIEWPORT_REFLOW_DEBOUNCE_MS := 50


# ─── Signals ──────────────────────────────────────────────────────────────────

## Emitted once at the end of [method _ready], after Theme instantiation and
## viewport signal connection. Downstream autoloads (CaseService THIRD) and
## scene Controls should await or connect to this to confirm UIService is live.
##
## AC-1: Fires synchronously before any Controls _ready() because UIService is
## autoload SECOND (LibraryService FIRST → UIService SECOND → CaseService THIRD).
signal ui_service_initialized()

## Emitted after the debounce timer expires following a viewport size change.
##
## AC-1.3: Coalesces rapid [code]size_changed[/code] fires into one emit.
## KrCustomControl (story 002) and layout nodes connect to this to trigger reflow.
signal viewport_reflow_needed()


# ─── Private state ────────────────────────────────────────────────────────────

## Backing variable for the public [member theme] property.
## Written once in [method _ready]. Story 003 mutates via Theme API (set_font_size,
## set_color, add_type) — never reassigns this reference.
var _theme: Theme = Theme.new()

## One-shot debounce timer. Created in [method _ready], added as child so it
## participates in the scene tree and its [signal Timer.timeout] fires correctly.
var _viewport_debounce_timer: Timer


# ─── Public read-only property ────────────────────────────────────────────────

## Current theme instance. Read-only via public API.
##
## AC-1.2: The setter rejects direct assignment with [code]push_error[/code] and
## returns without mutation (Option C guard — identical to WorkspaceData.state).
## Use Theme mutation methods (Theme.set_font_size, Theme.set_color, etc.) to
## modify the theme; call those through UIService API methods added in story 003.
var theme: Theme:
	get:
		return _theme
	set(_value):
		push_error(
			"UIService.theme is read-only. " +
			"Use Theme.set_font_size/set_color via UIService methods (story 003)."
		)


# ─── Built-in virtual methods ─────────────────────────────────────────────────

## Initializes the UIService: creates the Theme instance, sets up the debounce
## Timer, connects the viewport [code]size_changed[/code] signal, and emits
## [signal ui_service_initialized].
##
## AC-1: All setup completes in _ready() before any scene Control nodes initialize.
func _ready() -> void:
	_viewport_debounce_timer = Timer.new()
	_viewport_debounce_timer.wait_time = VIEWPORT_REFLOW_DEBOUNCE_MS / 1000.0
	_viewport_debounce_timer.one_shot = true
	_viewport_debounce_timer.timeout.connect(_on_viewport_debounce_timeout)
	add_child(_viewport_debounce_timer)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	ui_service_initialized.emit()


# ─── Signal callbacks ──────────────────────────────────────────────────────────

## Starts (or resets if already running) the debounce timer on every viewport
## size change.
##
## AC-1.3: Calling [method Timer.start] on an already-running timer resets it,
## so rapid [code]size_changed[/code] fires within [constant VIEWPORT_REFLOW_DEBOUNCE_MS]
## coalesce into a single [signal viewport_reflow_needed] emit.
func _on_viewport_size_changed() -> void:
	_viewport_debounce_timer.start()


## Emits [signal viewport_reflow_needed] after the debounce window expires.
##
## Called by the one-shot [member _viewport_debounce_timer] timeout. Consumers
## (KrCustomControl, layout nodes) recalculate layout in response to this signal.
func _on_viewport_debounce_timeout() -> void:
	viewport_reflow_needed.emit()


# ─── Reduced Motion + animation gateway (story 004) ──────────────────────────

## Whether Reduced Motion is active. When true, [method tween_property] applies the
## final value immediately and creates no Tween.
##
## AC-10: Defaults to [code]false[/code] (animations play) — the safe default when
## SettingsService is not yet integrated. The real value is driven by the
## SettingsService [code]display.reduced_motion[/code] signal subscription, wired in
## story 005 / workspace 009. This state field is the integration seam: the settings
## subscriber sets it; [method tween_property] reads it.
##
## NOTE (deviation from story-004 pseudo-code): the story queried
## [code]Engine.has_singleton("SettingsService")[/code] + [code]SettingsService.get(...)[/code]
## synchronously on each call. Autoloads are scene-tree nodes at [code]/root[/code], not
## Engine singletons, so [code]Engine.has_singleton[/code] is an unreliable presence check
## for them (story 005/009 to resolve). A settable state field driven by the settings
## signal is both correct and testable, and avoids a per-call lookup.
var reduced_motion: bool = false

## Animation gateway — the single sanctioned way to create property tweens.
##
## AC-15: With [member reduced_motion] false, creates a [Tween], chains a
## [code]tween_property[/code] toward [param final_value] over [param duration] seconds,
## and returns the Tween (callers may chain further on it).
## AC-16: With [member reduced_motion] true, sets [param property] on [param target]
## to [param final_value] immediately via [method Object.set_indexed] and returns
## [code]null[/code] — no Tween is created (zero animation, zero allocation per the
## performance budget).
##
## Forbidden pattern [code]direct_create_tween_bypassing_reduced_motion[/code]
## (docs/registry/architecture.yaml): all UI animation MUST route through this gateway;
## never call [method Node.create_tween] directly in UI code.
func tween_property(
	target: Object,
	property: NodePath,
	final_value: Variant,
	duration: float
) -> Tween:
	if target == null:
		push_error("UIService.tween_property: target must not be null")
		return null
	if reduced_motion:
		target.set_indexed(property, final_value)
		return null
	var tween: Tween = create_tween()
	tween.tween_property(target, property, final_value, duration)
	return tween
