## Camera & Input's spherical-orbit camera position derivation (Foundation
## Spine story cam-001, ADR-0002 + ADR-0001).
##
## Owns the derived camera position formula `target + spherical_offset
## (distance, yaw, pitch)` [TR-camera-input-021] and the fixed pole-safety
## pitch clamp [TR-camera-input-037]. Camera position is NEVER stored --
## [method get_camera_position] recomputes it from state on every call, per
## the GDD's "never independently stored" contract; [method derive_position]
## is the pure, stateless formula itself, callable without an instance.
##
## Injected-tier module (ADR-0001): [member config] is wired via a scene
## file's Inspector in production, or assigned directly in a headless test;
## all wiring/validation lives in [method setup], never `_ready()`.
##
## Story cam-002 (ADR-0010 primary, ADR-0001 secondary) additionally owns the
## InputMap action registrations (project.godot, project scope -- see
## [constant OWNED_ACTIONS]) and the opaque [signal action_fired] passthrough:
## this system reports "this action fired" and nothing more, never
## interpreting the action name or branching on input device identity
## [TR-camera-input-027] [TR-camera-input-032] [TR-camera-input-039].
##
## Story cam-003 (ADR-0002 primary) additionally owns orbit rotation: Q/E
## fixed-step yaw ([method _apply_qe_rotation], GDD Core Rule 3
## [TR-camera-input-023]) and middle-mouse-drag yaw/pitch
## ([method _apply_mouse_drag_rotation], GDD Core Rule 2
## [TR-camera-input-022]). Both are purely event-driven -- neither reads the
## Time & Tick Autoload nor any of its warp/pause-affected accumulator state
## anywhere -- so the raw-delta contract [TR-camera-input-030] holds
## structurally rather than by a conditional bypass. Pitch changes always
## route through the existing
## [method set_pitch] primitive (story cam-001), inheriting its silent
## pole-safety clamp [TR-camera-input-040] for free. Never sets
## `Input.mouse_mode = MOUSE_MODE_CAPTURED` during the drag -- the cursor
## stays visible and free, per the GDD/manifest.
##
## Story cam-004 (ADR-0002 primary) additionally owns mouse-wheel zoom
## ([method _apply_zoom], GDD Core Rule 4 [TR-camera-input-024]): each wheel
## event scales [member _distance] multiplicatively by
## `config.zoom_factor_in` (wheel-up, "zoom in") or `config.zoom_factor_out`
## (wheel-down, "zoom out"), then clamps the result to
## `[config.distance_min, config.distance_max]` via the new
## [method set_distance] primitive -- mirroring [method set_pitch]'s
## clamp-on-write shape from stories cam-001/003. There is no accumulator
## state: every wheel event applies the formula once, independently, so N
## rapid successive events (any N) still respect the clamp with no
## compounding overshoot [TR-camera-input-044]. Purely event-driven like the
## rest of this class's input handling, so the raw-delta contract holds
## structurally rather than by a conditional bypass.
##
## Story cam-005 (ADR-0002 primary) additionally owns WASD ground-plane pan
## (GDD Core Rule 5 [TR-camera-input-025]): [method _apply_pan], driven by
## [method _process]'s own per-frame delta -- this class's ONE sanctioned
## per-frame hook, since a held-key pan (unlike Q/E's discrete step or the
## wheel's discrete event) genuinely needs continuous per-frame movement
## while held. That frame delta is Godot's own engine-provided value; this
## class structurally never reads the Time & Tick Autoload nor any of its
## warp/pause-affected accumulator state anywhere, so the raw-delta contract
## [TR-camera-input-030] holds exactly as it does for rotation/zoom. The
## delta is clamped to `config.max_delta_time` BEFORE entering the pan
## formula [TR-camera-input-043], and the resulting target is clamped to the
## world extent via [method clamp_target_to_bounds] -- silently, with no
## error, and margin 0 (the default) is a fully valid configuration, not an
## edge case [TR-camera-input-026] [TR-camera-input-049]. [method
## derive_pan_delta] and [method clamp_target_to_bounds] are pure/stateless,
## mirroring [method derive_position]'s already-established testable-pure-
## function shape. WASD is read via `Input.get_vector` over
## [constant PAN_ACTIONS] -- deliberately NOT part of [constant
## OWNED_ACTIONS]/[signal action_fired]'s opaque one-shot passthrough (that
## list's semantics are "fired on press," which doesn't fit a continuously-
## held direction key); [constant PAN_ACTIONS] still gets its own boot-time
## registration guard, [method _assert_pan_actions_registered].
##
## Story cam-006 (ADR-0004 primary, pure-projection-math constraint; ADR-0014
## secondary, ghost-anchoring contract note) additionally owns the mouse
## world-ray + ground-plane intersection query (GDD Core Rule 8
## [TR-camera-input-028] [TR-camera-input-029] [TR-camera-input-038]
## [TR-camera-input-050]): [method get_world_ray] and
## [method get_ground_plane_intersection]. Per ADR-0004 this is PURE
## PROJECTION MATH -- zero physics API calls anywhere (no
## `PhysicsDirectSpaceState3D`/`intersect_ray`); block picking (ADR-0014's DDA)
## and villager picking (ADR-0004's `Area3D` query) are downstream consumers'
## concern -- this system only produces the ray, never calling Voxel World
## itself [TR-camera-input-036].
##
## This class has never held a live [Camera3D] (see `tools/camera_sandbox.gd`
## -- the real driven Camera3D lives in a SEPARATE node/scene that mirrors
## [method get_camera_position]/[method get_target] onto its own transform
## every frame). Rather than introduce one just for this query -- which would
## create an ordering hazard, since an external Camera3D's transform would
## need to already be synced to this instance's OWN derived state before every
## call -- [method get_world_ray] re-derives the identical projection math
## Godot's `Camera3D.project_ray_origin`/`project_ray_normal` would produce for
## a camera transform matching [method get_camera_position]/[method get_target]
## directly from this instance's OWN already-owned spherical state --
## self-contained, with no external-node synchronization to get wrong.
##
## Origin and direction are computed from the SAME sampled [Viewport] mouse
## position in the SAME call, never cached/recomputed separately
## [TR-camera-input-038]. Structurally ALWAYS computable -- every value
## [method get_world_ray] reads is a plain always-valid getter or a plain
## [Viewport] query, gated on no state flag whatsoever, so it remains valid
## unchanged once story cam-007's Suspended state freezes this instance's
## spherical state [TR-camera-input-029]. [method derive_ray_direction],
## [method derive_ground_plane_intersection], and
## [method derive_screen_position] are pure/stateless, mirroring [method
## derive_position]'s established testable-pure-function shape -- [method
## derive_screen_position] is the inverse projection, existing to PROVE the
## round-trip guarantee [TR-camera-input-050], not a general-purpose
## production API.
##
## Story cam-007 (ADR-0010 primary, cross-system input arbitration; ADR-0013
## secondary, the transition-signal contract surface) additionally owns the
## Active/Suspended state machine (GDD States and Transitions table
## [TR-camera-input-034] [TR-camera-input-033] [TR-camera-input-035]
## [TR-camera-input-042] [TR-camera-input-041] [TR-camera-input-031]):
## [enum State], [member game_world] (an OPTIONAL injected-tier dependency,
## ADR-0001 -- wired via a scene file's Inspector in production; nullable so
## every pre-existing cam-001..006 test/wiring that never sets it continues
## to construct/[method setup] a bare instance unaffected, mirroring
## [GameWorld]'s own `valley_scene` "deliberately optional" precedent), and
## [method setup]'s new [method _connect_transition_signals] call. THIS class
## is the consumer that connects itself to `game_world.transition_begun`/
## `transition_ended` -- [GameWorld] never calls into any consumer directly,
## by construction (its own class doc comment, TR-scene-world-management-049).
## A single connection call handles both end outcomes: `transition_ended`
## already covers transition-complete (`success=true`) AND transition-abort
## (`success=false`) in one signal, so there is no separate abort signal to
## forget -- the "never complete alone" guarantee [TR-camera-input-033] holds
## by construction of [GameWorld]'s own contract surface, not by anything
## extra this class does.
##
## Suspension freezes camera state WITHOUT a separate snapshot/restore copy
## of yaw/pitch/distance/target: every mutation path ([method
## _apply_qe_rotation], [method _apply_mouse_drag_rotation], [method
## _apply_zoom], [method _apply_pan]) is itself gated on [constant
## State.ACTIVE] (directly, or via [method _unhandled_input]'s single
## early-return gate), so none of them can touch [member _yaw]/[member
## _pitch]/[member _distance]/[member _target] while Suspended -- the "exact
## same value, no snap" restore guarantee [TR-camera-input-042] holds
## structurally, mirroring this class's already-established preference for
## structural guarantees over redundant tracked state (see [method
## get_world_ray]'s "always computable, no state-guard branch" precedent).
## [method _unhandled_input]'s Suspended check is a STATE gate, not a
## per-action branch, so [TR-camera-input-027]'s "no branch on action
## identity" guarantee (cam-002) is unaffected -- it governs branching on
## WHICH action fired, not whether dispatch happens at all this frame.
## [method Node.set_process]/[method Node.set_process_unhandled_input] are
## ALSO toggled false/true on suspend/resume -- the idiomatic Godot
## "disable when idle" engine opt-out -- kept alongside the body-level state
## checks: the checks are what make Suspended exercisable via this class's
## established direct-method-call test convention (a toggled-off engine
## callback is invisible to a test that calls the method directly, the same
## reasoning [WasdPanTest]'s doc comment already documents for headless
## `Input` polling).
##
## Edge case (GDD Edge Cases table [TR-camera-input-041]): a middle-mouse
## rotate drag already in progress when suspension begins is DROPPED, not
## merely paused. [method _on_transition_begun] reads [member
## _middle_button_held] -- tracked purely from InputEvents [method
## _apply_mouse_drag_rotation] already observes (an [InputEventMouseMotion]'s
## own `button_mask`, or an explicit [InputEventMouseButton] press/release),
## NEVER `Input` global-state polling, which this project's headless CLI test
## harness cannot reliably simulate (the same accumulated pitfall
## `wasd_pan_test.gd` documents for `Input.get_vector`/`action_press`) -- and,
## if the button was held at that moment, arms [member _rotate_drag_locked].
## The lock is independent of [enum State] itself: it survives the resume
## back to Active and is cleared ONLY by an explicit
## [InputEventMouseButton] release for `MOUSE_BUTTON_MIDDLE` reaching [method
## _apply_mouse_drag_rotation] -- requiring a genuine release-then-fresh-press
## before rotation resumes, per the GDD's "ignored until released and
## re-pressed."
class_name CameraInput
extends Node

## Active/Suspended state machine (story cam-007). [constant State.SUSPENDED]
## is EXCLUSIVELY the scene-transition state (GDD Core Rule 10,
## [TR-camera-input-031]) -- never reused for game pause (Story 009's
## separate, later contract).
enum State { ACTIVE, SUSPENDED }

## Opaque InputMap action passthrough (ADR-0010 Decision "New-click ownership
## is structural"; architecture.md API Boundaries:
## `signal action_fired(action_name: StringName)`). Payload is ONLY the
## action-name string -- this system never interprets what the action means;
## consumers (Building System, Building UI, Villager Info UI) own that.
## [TR-camera-input-027]
signal action_fired(action_name: StringName)

## The authoritative union of InputMap actions this system owns, registered
## in `project.godot` at project scope (never created at runtime)
## [TR-camera-input-032]. This is the single source of truth [method
## _unhandled_input] iterates over and [method setup] verifies against
## [constant InputMap] at boot -- keep in sync with `project.godot`'s
## `[input]` section by construction (both are hand-authored from the same
## downstream-GDD union; a mismatch fails loudly via [method setup]'s
## assertion rather than silently).
##
## Provenance: `build_place`/`build_remove` (camera-input.md Core Rule 7,
## building-system.md), `camera_rotate_left`/`camera_rotate_right`
## (camera-input.md Core Rule 3 -- Q/E), `tool_select_1..5`, `time_pause`,
## `time_speed_up`/`time_speed_down`, the Rule-9b keyboard-parity set
## (`toast_focus_cycle`, `toast_dismiss`, `toggle_issues`, `palette_next`,
## `palette_prev`, `formation_next`, `formation_prev`, `height_step_up`,
## `height_step_down`), and the Slice-revision set (`build_mode_toggle`,
## `slice_up`, `slice_down`, `slice_reset`) -- all building-ui.md Rule 12.
## `tool_select_room`/`tool_select_roof`/`tool_select_house` (the three
## higher-level tools, building-ui.md Rule 19) are named here as an
## authored `[assumption]` -- the GDD commits to these three actions
## existing but not yet to a specific identifier string; the underlying
## keys for every Rule-9b/Slice-revision/higher-level-tool action are
## themselves already documented `[assumption]`s pending `/ux-design`
## (Open Question 13) -- registering a placeholder default key here does
## not pre-empt that review.
const OWNED_ACTIONS: Array[StringName] = [
	&"build_place", &"build_remove",
	&"camera_rotate_left", &"camera_rotate_right",
	&"tool_select_1", &"tool_select_2", &"tool_select_3", &"tool_select_4", &"tool_select_5",
	&"tool_select_room", &"tool_select_roof", &"tool_select_house",
	&"time_pause", &"time_speed_up", &"time_speed_down",
	&"toast_focus_cycle", &"toast_dismiss", &"toggle_issues",
	&"palette_next", &"palette_prev",
	&"formation_next", &"formation_prev",
	&"height_step_up", &"height_step_down",
	&"build_mode_toggle",
	&"slice_up", &"slice_down", &"slice_reset",
]

## WASD ground-plane pan actions (story cam-005, GDD Core Rule 5)
## [TR-camera-input-025], registered in `project.godot` at project scope like
## every other action this system owns [TR-camera-input-032]. Kept OUT of
## [constant OWNED_ACTIONS] deliberately: that list drives [signal
## action_fired]'s one-shot "fired on press" passthrough (matching Q/E's
## discrete step), whereas pan is read every frame via `Input.get_vector`
## inside [method _apply_pan] while a key is HELD -- a continuously-polled
## direction, not a discrete press event. Re-emitting a one-shot
## `action_fired` for a held key would misrepresent it, so these get their
## own boot-time registration guard instead, [method
## _assert_pan_actions_registered], rather than joining the passthrough list.
const PAN_ACTIONS: Array[StringName] = [
	&"camera_pan_forward", &"camera_pan_back", &"camera_pan_left", &"camera_pan_right",
]

## Tuning config dependency (ADR-0002). Wired via a scene file's Inspector in
## production, or assigned directly in a headless test. Never read inside
## `_ready()` -- see [method setup].
@export var config: CameraInputConfig

## Optional injected-tier dependency (ADR-0001, story cam-007) on the World
## Root's transition-signal contract surface (ADR-0013's
## `transition_begun`/`transition_ended`, scene-world-management story 003).
## Wired via a scene file's Inspector in production, or assigned directly in
## a headless test; [method setup] connects to both signals when this is
## non-null (see [method _connect_transition_signals]). Deliberately
## nullable -- no scene-assembly story has wired a live [CameraInput] node
## into `GameWorld.tscn` yet, and every pre-existing cam-001..006 test never
## sets this field, so a null value MUST remain a no-op (mirrors
## [GameWorld]'s own `valley_scene` "deliberately optional" precedent) rather
## than an assertion failure.
@export var game_world: GameWorld = null

## Orbit target point (ground-plane look-at). Mutated by [method _apply_pan]
## (story cam-005); starts at the world origin. [TR-camera-input-021]
var _target: Vector3 = Vector3.ZERO

## Spherical radius from [member _target] to the camera. Mutated by the zoom
## formula (story cam-004, out of scope here). [TR-camera-input-021]
var _distance: float = 0.0

## Horizontal orbit angle, radians, unbounded/wraps. Mutated by mouse-drag/
## Q-E rotation (story cam-003, out of scope here). [TR-camera-input-021]
var _yaw: float = 0.0

## Vertical orbit angle, radians, always kept within
## `[config.pitch_min, config.pitch_max]` -- the fixed pole-safety margin.
## [TR-camera-input-037]
var _pitch: float = 0.0

## True once [method setup] has completed at least once.
var _is_set_up: bool = false

## Active/Suspended state (story cam-007). See [enum State].
var _state: State = State.ACTIVE

## Last-known held/released state of the middle-mouse rotate button, tracked
## purely from InputEvents [method _apply_mouse_drag_rotation] already
## observes -- never `Input` global-state polling (untestable headless, see
## that method's doc comment). Consulted by [method _on_transition_begun] to
## decide whether a drag was in progress at the moment suspension begins.
var _middle_button_held: bool = false

## True once a Suspended entry found the rotate button already held
## [TR-camera-input-041]; while true, [method _apply_mouse_drag_rotation]
## ignores drag motion entirely. Cleared ONLY by an explicit
## [InputEventMouseButton] release for `MOUSE_BUTTON_MIDDLE` -- requiring a
## genuine release-then-fresh-press before rotation resumes. Independent of
## [enum State] itself: survives the Suspended -> Active transition.
var _rotate_drag_locked: bool = false


## Explicitly callable wiring/validation entry point (ADR-0001). Asserts
## [member config] was wired, applies ADR-0002's clamp+warn `validate()`
## policy, and initializes the spherical state from the config's `start_*`
## knobs [TR-camera-input-019] -- never from a hardcoded literal.
func setup() -> void:
	assert(config != null, "CameraInput.config not wired")
	for issue: String in config.validate():
		if not issue.begins_with(ConfigResource.BLOCKING_PREFIX):
			push_warning(issue)
	_target = Vector3.ZERO
	_distance = config.start_distance
	_yaw = config.start_yaw
	_pitch = clampf(config.start_pitch, config.pitch_min, config.pitch_max)
	_assert_owned_actions_registered()
	_assert_pan_actions_registered()
	_connect_transition_signals()
	_is_set_up = true


## Boot-time guard for [TR-camera-input-032]: every entry in
## [constant OWNED_ACTIONS] must already exist in [InputMap] (registered via
## `project.godot` at project scope -- never created here at runtime). A
## missing action means `project.godot` has drifted out of sync with this
## list; fail loudly rather than let a downstream consumer silently query an
## action that was never registered.
func _assert_owned_actions_registered() -> void:
	var missing: Array[StringName] = OWNED_ACTIONS.filter(
		func(action_name: StringName) -> bool: return not InputMap.has_action(action_name)
	)
	assert(missing.is_empty(), "CameraInput owned actions missing from project.godot: %s" % [missing])


## Boot-time guard for [constant PAN_ACTIONS], mirroring [method
## _assert_owned_actions_registered]'s shape exactly but against the separate
## pan-action list (story cam-005) -- same fail-loudly-on-drift reasoning.
func _assert_pan_actions_registered() -> void:
	var missing: Array[StringName] = PAN_ACTIONS.filter(
		func(action_name: StringName) -> bool: return not InputMap.has_action(action_name)
	)
	assert(missing.is_empty(), "CameraInput pan actions missing from project.godot: %s" % [missing])


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Connects this instance to [member game_world]'s transition-signal contract
## surface (story cam-007, ADR-0001 injected-tier wiring). A no-op when
## [member game_world] is null (see that member's doc comment) -- every
## pre-existing test/wiring that never sets it continues unaffected. Guards
## each connection with [method Signal.is_connected] so a repeated [method
## setup] call (e.g. a test re-running setup on the same instance) never
## double-connects.
func _connect_transition_signals() -> void:
	if game_world == null:
		return
	if not game_world.transition_begun.is_connected(_on_transition_begun):
		game_world.transition_begun.connect(_on_transition_begun)
	if not game_world.transition_ended.is_connected(_on_transition_ended):
		game_world.transition_ended.connect(_on_transition_ended)


## Handles [signal GameWorld.transition_begun]: enters Suspended
## [TR-camera-input-034], arms [member _rotate_drag_locked] if [member
## _middle_button_held] shows the rotate button already down
## [TR-camera-input-041], and disables this node's own per-frame/input engine
## callbacks ([method Node.set_process] / [method
## Node.set_process_unhandled_input]) -- the idiomatic Godot "disable when
## idle" opt-out, kept alongside this class's body-level state checks (see
## class doc comment).
func _on_transition_begun() -> void:
	_rotate_drag_locked = _middle_button_held
	_state = State.SUSPENDED
	set_process(false)
	set_process_unhandled_input(false)


## Handles [signal GameWorld.transition_ended]: re-enters Active regardless of
## [param success] -- transition-complete (`true`) and transition-abort
## (`false`) release Suspended identically [TR-camera-input-033], never
## complete alone (an abort must never strand this system in Suspended).
## Re-enables [method Node.set_process] / [method
## Node.set_process_unhandled_input]. Deliberately does NOT touch [member
## _rotate_drag_locked] -- a drag held across the boundary stays ignored
## until an explicit release + fresh press [TR-camera-input-041], independent
## of this resume.
func _on_transition_ended(_success: bool) -> void:
	_state = State.ACTIVE
	set_process(true)
	set_process_unhandled_input(true)


## Returns the current Active/Suspended state (story cam-007).
func get_state() -> State:
	return _state


## Returns the camera's world position, recomputed fresh from current state
## on every call -- never cached or independently stored.
## [TR-camera-input-021]
func get_camera_position() -> Vector3:
	return CameraInput.derive_position(_target, _distance, _yaw, _pitch)


## Pure spherical-to-Cartesian derivation (GDD Formulas section):
## `target + Vector3(distance*sin(yaw)*cos(pitch), distance*sin(pitch),
## distance*cos(yaw)*cos(pitch))`. Stateless -- exercisable directly with
## arbitrary values, without an instance or [method setup].
## [TR-camera-input-021]
static func derive_position(target: Vector3, distance: float, yaw: float, pitch: float) -> Vector3:
	return target + Vector3(
		distance * sin(yaw) * cos(pitch),
		distance * sin(pitch),
		distance * cos(yaw) * cos(pitch)
	)


## Sets the vertical orbit angle, clamped to
## `[config.pitch_min, config.pitch_max]` -- the fixed pole-safety margin
## that prevents the spherical derivation from degenerating at the poles
## [TR-camera-input-037]. The rotation input handling that calls this
## (mouse-drag/Q-E) is story cam-003's scope; this is the shared clamp
## primitive that story builds on.
func set_pitch(value: float) -> void:
	assert(config != null, "CameraInput.config not wired")
	_pitch = clampf(value, config.pitch_min, config.pitch_max)


## Returns the current vertical orbit angle (radians).
func get_pitch() -> float:
	return _pitch


## Returns the current horizontal orbit angle (radians).
func get_yaw() -> float:
	return _yaw


## Sets the spherical radius, clamped to
## `[config.distance_min, config.distance_max]` -- the zoom clamp bound
## [TR-camera-input-024]. The zoom input handling that calls this
## (mouse-wheel, story cam-004) is this story's scope; this is the shared
## clamp primitive, mirroring [method set_pitch]'s shape, that any future
## distance-changing input can reuse without duplicating the clamp.
func set_distance(value: float) -> void:
	assert(config != null, "CameraInput.config not wired")
	_distance = clampf(value, config.distance_min, config.distance_max)


## Returns the current spherical radius.
func get_distance() -> float:
	return _distance


## Returns the current orbit target point.
## Small additive public surface (Story scene-005, AC-ONE-START-FOCUS; camera-
## input epic file). [method setup] resets [member _target] to
## [constant Vector3.ZERO] unconditionally (this class's own pre-existing
## behavior, unchanged) -- there was previously no public way for a caller to
## establish a DIFFERENT start-focus point afterward, which is exactly the
## "camera starts at cell (0,0,0) while the roster centers on the world
## center" bug this story's own Context names. World genesis calls this
## exactly once, AFTER [method setup] has already run (so this write is never
## clobbered by it), with the SAME start-focus cell the residency anchor,
## mesh-window centre and roster placement centre all use -- see
## [method GameWorld._run_world_genesis]. Never writes [member _target]
## itself from any logic path other than this explicit call and [method
## _apply_pan]'s own pre-existing per-frame pan mutation.
func set_target(value: Vector3) -> void:
	_target = value


func get_target() -> Vector3:
	return _target


## Opaque InputMap action passthrough (ADR-0010 Decision §1; architecture.md
## API Boundaries). Listens on `_unhandled_input` per ADR-0010 -- an event
## already consumed by an HUD Control (default `mouse_filter = STOP`) never
## reaches here, which is exactly what gives "exactly one owner per click"
## [TR-camera-input-020] without any code of this system's own dedicated to
## checking it.
##
## Deliberately implemented with [method Array.filter] rather than an
## `if`/`match` on [param event]'s action identity: every entry in
## [constant OWNED_ACTIONS] receives IDENTICAL treatment (a uniform
## `is_action_pressed` check), so there is no branch whose behavior differs
## per action name to grep for [TR-camera-input-027]. This method never
## reads the input device identity of [param event] anywhere
## [TR-camera-input-039].
##
## Story cam-003 additionally drives this system's OWN rotation behavior
## from the same event, via two unconditional call sites appended below the
## passthrough loop -- [method _apply_qe_rotation] and
## [method _apply_mouse_drag_rotation]. Neither call line itself branches on
## [param event]'s identity (the branching lives inside those methods, on
## this system's own two owned rotation actions / the middle-mouse button --
## never on the arbitrary [constant OWNED_ACTIONS] list this method's own
## loop still treats uniformly). [TR-camera-input-027]'s "no branch on
## action identity" guarantee is about the opaque re-emission of OTHER
## systems' actions and is unaffected.
##
## Story cam-004 similarly appends a third unconditional call site,
## [method _apply_zoom], for this system's own mouse-wheel zoom -- same
## reasoning: the branch lives inside that method, on the wheel event's own
## button index, never here on [constant OWNED_ACTIONS] identity.
##
## Story cam-007 prepends exactly ONE early-return guard: while [constant
## State.SUSPENDED], this method does nothing at all -- no [signal
## action_fired] emission, no rotation, no zoom [TR-camera-input-034]. This is
## a STATE gate, not a per-action branch: it does not distinguish WHICH action
## fired, only WHETHER any dispatch happens this call, so
## [TR-camera-input-027]'s "no branch on action identity" guarantee (verified
## by this suite's own grep check) is unaffected -- see class doc comment.
func _unhandled_input(event: InputEvent) -> void:
	if _state == State.SUSPENDED:
		return
	var fired: Array[StringName] = OWNED_ACTIONS.filter(
		func(action_name: StringName) -> bool: return event.is_action_pressed(action_name)
	)
	for action_name: StringName in fired:
		action_fired.emit(action_name)
	_apply_qe_rotation(event)
	_apply_mouse_drag_rotation(event)
	_apply_zoom(event)


## Mouse-wheel multiplicative zoom (GDD Core Rule 4) [TR-camera-input-024].
## Each wheel event is a discrete [InputEventMouseButton] with
## `pressed = true` -- never accumulated across frames and never scaled by
## delta-time (the GDD formula applies once per wheel event, matching how
## Q/E applies once per key press in [method _apply_qe_rotation], not once
## per frame). Wheel-up ([constant MOUSE_BUTTON_WHEEL_UP]) zooms in
## (`config.zoom_factor_in`, GDD default 0.9, shrinks distance); wheel-down
## ([constant MOUSE_BUTTON_WHEEL_DOWN]) zooms out (`config.zoom_factor_out`,
## GDD default 1.1, grows distance). Routes through [method set_distance],
## which owns the `[distance_min, distance_max]` clamp -- so any number of
## rapid successive events can never overshoot the bound regardless of event
## count [TR-camera-input-044]. Factors are read from [member config] --
## never a hardcoded literal [TR-camera-input-019].
func _apply_zoom(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_distance(_distance * config.zoom_factor_in)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_distance(_distance * config.zoom_factor_out)


## Q/E fixed-step yaw rotation (GDD Core Rule 3) [TR-camera-input-023].
## `camera_rotate_left` (Q) and `camera_rotate_right` (E) are already
## registered, owned actions (see [constant OWNED_ACTIONS]) -- this reacts to
## the SAME event the passthrough loop above already inspects, applying this
## system's own Core-Rule-3 behavior for its own owned actions. Distinct from
## [TR-camera-input-027]'s "no branch on action identity" guarantee, which
## governs only the opaque re-emission of OTHER systems' actions (build_place
## et al.) -- Camera & Input interpreting its OWN rotation actions for its
## OWN camera state is the GDD's explicitly assigned behavior, not a
## violation of that passthrough contract. Step size is read from
## [member config] -- never a hardcoded literal [TR-camera-input-019].
func _apply_qe_rotation(event: InputEvent) -> void:
	if event.is_action_pressed(&"camera_rotate_left"):
		_yaw -= config.q_e_rotate_step
	elif event.is_action_pressed(&"camera_rotate_right"):
		_yaw += config.q_e_rotate_step


## Middle-mouse-drag rotation (GDD Core Rule 2) [TR-camera-input-022].
## Horizontal drag changes yaw, vertical drag changes pitch -- both
## proportional to `config.mouse_drag_sensitivity`, applied per motion
## event's [member InputEventMouseMotion.relative] pixel delta (never a
## manually-tracked previous-position diff, and never delta-time-scaled --
## the GDD's formula is purely per-pixel-of-drag, not per-frame). Pitch
## changes always route through [method set_pitch], inheriting its pole-
## safety clamp [TR-camera-input-037] silently, with no error, at either
## bound [TR-camera-input-040].
##
## Gated on `MOUSE_BUTTON_MASK_MIDDLE` in the motion event's own
## `button_mask` -- a self-describing per-event check, not a separately
## tracked press/release drag-state field: there is nothing to get "stuck"
## if a press or release event is ever swallowed elsewhere (e.g. by an HUD
## Control under ADR-0010's routing), because no state survives between
## events. Never sets `Input.mouse_mode = MOUSE_MODE_CAPTURED` -- the cursor
## stays visible and free, per the GDD/manifest.
##
## Story cam-007 adds the ONE piece of cross-event state this method now
## tracks: [member _middle_button_held] (updated below from every event this
## method sees that carries evidence of the button's physical state -- an
## explicit [InputEventMouseButton] press/release, or a motion event's own
## `button_mask`), consulted by [method _on_transition_begun] to decide
## whether a drag was in progress at the moment suspension begins. When
## [member _rotate_drag_locked] is armed (a drag was dropped at suspension,
## [TR-camera-input-041]), this method ignores ALL drag motion until it
## observes an explicit [InputEventMouseButton] release for
## `MOUSE_BUTTON_MIDDLE` -- a genuine release, not merely a motion event
## showing the button no longer in `button_mask` -- so the same
## "release-then-fresh-press" contract holds even if a release happened
## invisibly during Suspended (see class doc comment's Edge case paragraph).
func _apply_mouse_drag_rotation(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_middle_button_held = event.pressed
	if _rotate_drag_locked:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
			_rotate_drag_locked = false
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_middle_button_held = true
		_yaw += event.relative.x * config.mouse_drag_sensitivity
		set_pitch(_pitch + event.relative.y * config.mouse_drag_sensitivity)


## Godot's per-frame engine callback -- this class's ONE sanctioned per-frame
## hook (story cam-005). [param delta] is Godot's own engine-provided frame
## delta, never a value read from this project's separate tick-warp/pause
## clock -- structurally, this class never reads that Autoload anywhere, so
## the raw-delta contract [TR-camera-input-030] holds the same way it does
## for rotation/zoom (both purely event-driven, this one purely frame-driven,
## neither ever touching the other clock).
##
## Reads [constant PAN_ACTIONS] via `Input.get_vector` every frame (a
## held-key, continuously-polled direction -- see [constant PAN_ACTIONS] for
## why this is distinct from the discrete [signal action_fired] passthrough)
## and forwards the resolved direction to [method _apply_pan]. This is
## deliberately the ONLY place this class reads the `Input` singleton for
## pan -- [method _apply_pan] takes the already-resolved direction as a
## parameter rather than querying `Input` itself, keeping the formula fully
## testable without depending on engine-level input dispatch (mirroring how
## [method _unhandled_input] takes a synthesizable [InputEvent] rather than
## reading global input state internally). `camera_pan_forward` is the
## `Input.get_vector` negative-Y parameter: at yaw=0 the camera sits at world
## +Z relative to the target (see [method derive_position]'s
## `distance*cos(yaw)` term), so "forward relative to view" -- the direction
## from camera to target -- is -Z before yaw rotation, matching `vec.y == -1`
## when the forward key is held.
func _process(delta: float) -> void:
	var input_vec: Vector2 = Input.get_vector(
		&"camera_pan_left", &"camera_pan_right", &"camera_pan_forward", &"camera_pan_back"
	)
	_apply_pan(delta, Vector3(input_vec.x, 0.0, input_vec.y))


## WASD ground-plane pan formula (GDD Core Rule 5) [TR-camera-input-025].
## [param input_dir] is the already-resolved, not-necessarily-normalized
## direction for this frame (see [method _process] for how it's read from
## [constant PAN_ACTIONS]) -- taking it as a parameter, rather than reading
## `Input` internally, is what makes this method exercisable directly in a
## headless test with an arbitrary direction, with no dependency on engine
## input dispatch.
##
## [param delta] is clamped to `config.max_delta_time` BEFORE entering the
## pan formula [TR-camera-input-043], preventing a large jump after a hitch/
## stall. The resulting delta vector is added to [member _target], then
## clamped to the world extent via [method clamp_target_to_bounds] --
## silently, with no error, and margin 0 (the config default) is a fully
## valid configuration, not an edge case [TR-camera-input-026]
## [TR-camera-input-049]. Input still registers at a bound; it simply
## produces zero further movement in that axis, never a blocked/ignored
## event.
##
## Story cam-007: gated on [constant State.ACTIVE] -- while [constant
## State.SUSPENDED] this is a no-op, freezing [member _target]
## [TR-camera-input-034]. Checked here (not only via [method
## Node.set_process]'s engine-level opt-out on [method _process]) so this
## guarantee holds for a direct call too, matching this class's established
## direct-method-call test convention (`wasd_pan_test.gd` exercises this
## method directly, never through `_process`).
func _apply_pan(delta: float, input_dir: Vector3) -> void:
	if _state == State.SUSPENDED:
		return
	var clamped_delta: float = clampf(delta, 0.0, config.max_delta_time)
	var pan_delta: Vector3 = CameraInput.derive_pan_delta(
		input_dir, _yaw, _distance, clamped_delta, config.pan_speed_factor
	)
	_target = CameraInput.clamp_target_to_bounds(
		_target + pan_delta,
		config.world_width_cells, config.world_depth_cells, config.cell_size, config.pan_bound_margin
	)


## Pure pan-formula derivation (GDD Formulas section, Pan):
## `input_dir.normalized().rotated(UP, yaw) * delta * distance * pan_speed_factor`.
## Stateless -- exercisable directly with arbitrary values, without an
## instance or [method setup], mirroring [method derive_position]'s testable-
## pure-function shape. [param input_dir] need not be pre-normalized -- a
## [constant Vector3.ZERO] input (no keys held) normalizes to zero safely, no
## division-by-zero. [TR-camera-input-025] [TR-camera-input-043]
static func derive_pan_delta(
	input_dir: Vector3, yaw: float, distance: float, delta: float, pan_speed_factor: float
) -> Vector3:
	return input_dir.normalized().rotated(Vector3.UP, yaw) * delta * distance * pan_speed_factor


## Pure world-extent bound clamp for the pan target (GDD Formulas section,
## Pan): clamps X to `[margin, world_width_cells * cell_size - margin]` and Z
## to `[margin, world_depth_cells * cell_size - margin]`; `target.y` passes
## through untouched (the orbit target lives on the ground plane, Y is never
## part of this clamp). Stateless, mirroring [method derive_position]'s
## testable-pure-function shape. Margin 0 (the config default) is a fully
## valid configuration -- `clampf` degenerates gracefully to the raw extent
## bounds, no special-case needed. [TR-camera-input-026] [TR-camera-input-049]
static func clamp_target_to_bounds(
	target: Vector3, world_width_cells: int, world_depth_cells: int, cell_size: float, margin: float
) -> Vector3:
	return Vector3(
		clampf(target.x, margin, world_width_cells * cell_size - margin),
		target.y,
		clampf(target.z, margin, world_depth_cells * cell_size - margin)
	)


# ---------------------------------------------------------------------------
# Story cam-006 -- mouse world-ray + ground-plane intersection
# (ADR-0004 primary: pure projection math, no physics API; ADR-0014
# secondary: this system produces the ray consumed by the DDA pick).
# See class doc comment for the "why no live Camera3D" rationale.
# ---------------------------------------------------------------------------

## Fixed pole/parallel-safety epsilon for [method
## derive_ground_plane_intersection]'s ray/ground-plane-parallel guard --
## division-by-near-zero on `ray_direction.y`, never a crash. Not a GDD tuning
## knob (it guards a pure math degeneracy, not a designer-facing value),
## mirroring [CameraInputConfig]'s own sanity-floor constants' non-tunable
## precedent.
const GROUND_PLANE_PARALLEL_EPSILON: float = 0.0001


## Returns the current mouse world-ray -- origin (always equal to [method
## get_camera_position] for this project's perspective-only camera) and
## direction, both computed from the SAME sampled [Viewport] mouse position
## in this SAME call [TR-camera-input-038]. ALWAYS computable, in every state
## including Suspended [TR-camera-input-029] -- see this method group's class
## doc comment; nothing here branches on any state flag. Never calls Voxel
## World or any other system [TR-camera-input-036] -- this is the sole
## producer downstream consumers (Building System's DDA pick, Villager Info
## UI's `Area3D` pick) forward this ray to.
func get_world_ray() -> WorldRay:
	assert(get_viewport() != null, "CameraInput.get_world_ray() called before this node entered the SceneTree")
	assert(config != null, "CameraInput.config not wired")
	var viewport: Viewport = get_viewport()
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	var camera_position: Vector3 = get_camera_position()
	var camera_target: Vector3 = get_target()
	return WorldRay.new(
		camera_position,
		CameraInput.derive_ray_direction(
			camera_position, camera_target, config.fov_degrees, viewport_size, mouse_pos
		)
	)


## Pure world-ray DIRECTION derivation through [param screen_pos], given a
## look-at basis built from [param camera_position]/[param camera_target]
## (fixed world-up [constant Vector3.UP], no roll -- matches [method
## derive_position]'s own spherical derivation) and a standard perspective
## frustum ([param fov_degrees] vertical FOV, [param viewport_size] aspect
## ratio). Stateless -- exercisable directly with arbitrary values, without an
## instance, [method setup], or a live [Viewport]/[Camera3D]
## [TR-camera-input-028] [TR-camera-input-038].
##
## Degenerates only when [param camera_position] sits (near-)directly above/
## below [param camera_target] -- the SAME pole-degeneracy [method
## derive_position]'s pitch clamp already prevents in practice for this
## class's own spherical state [TR-camera-input-037]; no additional guard is
## needed for that case here.
static func derive_ray_direction(
	camera_position: Vector3, camera_target: Vector3, fov_degrees: float,
	viewport_size: Vector2, screen_pos: Vector2
) -> Vector3:
	var forward: Vector3 = (camera_target - camera_position).normalized()
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	var up: Vector3 = right.cross(forward).normalized()
	var aspect: float = viewport_size.x / viewport_size.y
	var tan_half_fov: float = tan(deg_to_rad(fov_degrees) * 0.5)
	var raw_ndc_x: float = 2.0 * screen_pos.x / viewport_size.x - 1.0
	var raw_ndc_y: float = 1.0 - 2.0 * screen_pos.y / viewport_size.y
	var offset_x: float = raw_ndc_x * aspect * tan_half_fov
	var offset_y: float = raw_ndc_y * tan_half_fov
	return (forward + right * offset_x + up * offset_y).normalized()


## Convenience wrapper: [method get_world_ray] intersected with the ground
## plane (`y = 0.0`, matching [member _target]'s own ground-plane convention
## -- see the Pan formula) via [method derive_ground_plane_intersection].
func get_ground_plane_intersection() -> GroundPlaneIntersectionResult:
	var ray: WorldRay = get_world_ray()
	return CameraInput.derive_ground_plane_intersection(ray.origin, ray.direction)


## Pure ray/ground-plane (`y = ground_y`) intersection, mirroring
## [RaycastHitResult]'s established "explicit hit flag + payload, never a
## bare sentinel/null" precedent (`src/voxel_world/raycast_hit_result.gd`).
## `hit = false` (payload meaningless) when [param ray_direction]'s Y
## component is within [constant GROUND_PLANE_PARALLEL_EPSILON] of zero (ray
## parallel to the ground plane -- division-by-near-zero guarded explicitly,
## never a crash) OR when the computed intersection lies behind [param
## ray_origin] (`t < 0.0` -- e.g. a skyward mouse position looking away from
## the ground plane). Stateless, mirroring [method derive_position]'s
## testable-pure-function shape. [TR-camera-input-050]
static func derive_ground_plane_intersection(
	ray_origin: Vector3, ray_direction: Vector3, ground_y: float = 0.0
) -> GroundPlaneIntersectionResult:
	if absf(ray_direction.y) < GROUND_PLANE_PARALLEL_EPSILON:
		return GroundPlaneIntersectionResult.new(false)
	var t: float = (ground_y - ray_origin.y) / ray_direction.y
	if t < 0.0:
		return GroundPlaneIntersectionResult.new(false)
	return GroundPlaneIntersectionResult.new(true, ray_origin + ray_direction * t)


## Pure inverse of [method derive_ray_direction]: re-projects [param
## world_point] back to [Viewport] screen-pixel coordinates through the SAME
## look-at basis/perspective-frustum formula. Exists to PROVE
## [TR-camera-input-050]'s round-trip guarantee (ray -> ground intersection ->
## re-projected screen point lands within 1px of the original mouse position)
## against the SAME formula [method derive_ray_direction] uses -- not a
## general-purpose world-to-screen production API (no consumer needs one
## yet). Stateless, mirroring every other derivation in this class.
static func derive_screen_position(
	world_point: Vector3, camera_position: Vector3, camera_target: Vector3,
	fov_degrees: float, viewport_size: Vector2
) -> Vector2:
	var forward: Vector3 = (camera_target - camera_position).normalized()
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	var up: Vector3 = right.cross(forward).normalized()
	var relative: Vector3 = world_point - camera_position
	var depth: float = relative.dot(forward)
	var aspect: float = viewport_size.x / viewport_size.y
	var tan_half_fov: float = tan(deg_to_rad(fov_degrees) * 0.5)
	var raw_ndc_x: float = relative.dot(right) / (depth * aspect * tan_half_fov)
	var raw_ndc_y: float = relative.dot(up) / (depth * tan_half_fov)
	return Vector2(
		(raw_ndc_x + 1.0) * 0.5 * viewport_size.x,
		(1.0 - raw_ndc_y) * 0.5 * viewport_size.y
	)
