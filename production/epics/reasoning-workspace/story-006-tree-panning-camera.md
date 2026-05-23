# Story 006: Tree panning Camera2D (mouse + gamepad + KB + scroll wheel)

> **Epic**: Reasoning Workspace
> **Status**: Ready
> **Layer**: Feature (Gameplay)
> **Type**: UI
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§9.7 Tree Panning, §9.4.3 Gamepad, §10.7 UI Visual / Interaction partial)
**Requirement**: `TR-WORKSPACE-LAYOUT-004`

**ADR Governing Implementation**: ADR-0008 §4 (Tree panning Camera2D)
**ADR Decision Summary**: Camera2D inside DeskCanvas SubViewport. Mouse middle-drag 1:1 pan, gamepad right-stick analog 600 px/s, D-pad/Tab/Arrow auto-center on focused node (0.2s lerp), scroll wheel vertical pan. Position clamped to HypothesisNodeRoot bounding box + 200px padding.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Camera2D.position_smoothing_enabled` for 0.2s lerp; `SubViewport.canvas_transform` for cross-viewport coordinate mapping. Settings `input.gamepad_stick_deadzone` (default 0.15, range [0.0, 0.5] per TR-settings-004).

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.7 UI Visual / Interaction (Tree panning subset).

- [ ] AC-41 — Mouse middle-drag pans canvas 1:1 (cursor moves 100px → canvas moves 100px in opposite direction)
- [ ] AC-42 — Gamepad right-stick pan velocity 600 px/s at full deflection; respects `input.gamepad_stick_deadzone` setting (default 0.15)
- [ ] AC-43 — Focus move via D-pad / Tab / Arrow keys auto-centers focused node within 0.2s lerp; verify lerp duration consistent with `display.reduced_motion` setting (instant snap when reduced)
- [ ] AC-44 — Scroll wheel vertical pan (configurable distance per scroll; default 80px per tick)
- [ ] AC-50 — Camera position clamped to HypothesisNodeRoot bounding box + 200px padding (can't pan into empty space beyond tree extent)
- [ ] AC-51 — 1366×768 floor + 4-deep + 3+ root tree fits viewport (panning + auto-center together cover full tree)

---

## Implementation Notes

Per ADR-0008 §4:

```gdscript
# DeskCanvas — SubViewportContainer + SubViewport + HypothesisNodeRoot Node2D + Camera2D
class_name DeskCanvas extends SubViewportContainer

@onready var _camera: Camera2D = $SubViewport/Camera2D
@onready var _node_root: Node2D = $SubViewport/HypothesisNodeRoot

const PAN_VELOCITY_PX_PER_SEC := 600.0   # gamepad right-stick at full deflection
const AUTO_CENTER_LERP_SEC := 0.2
const CLAMP_PADDING_PX := 200.0
const SCROLL_WHEEL_TICK_PX := 80.0

func _process(delta: float) -> void:
    # Gamepad right-stick pan
    var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
    var deadzone: float = SettingsService.get("input.gamepad_stick_deadzone", 0.15)
    if stick.length() > deadzone:
        var pan := stick * PAN_VELOCITY_PX_PER_SEC * delta
        _camera.position += pan
    _clamp_camera_to_bounds()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_MIDDLE:
            _middle_drag_active = event.pressed
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _camera.position.y -= SCROLL_WHEEL_TICK_PX
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _camera.position.y += SCROLL_WHEEL_TICK_PX
    elif event is InputEventMouseMotion and _middle_drag_active:
        _camera.position -= event.relative   # 1:1 pan opposite cursor direction
    _clamp_camera_to_bounds()

func auto_center_on(node: HypothesisNode) -> void:
    var target := node.position
    if SettingsService.get("display.reduced_motion", false):
        _camera.position = target
    else:
        var tween := UIService.tween_property(_camera, "position", target, AUTO_CENTER_LERP_SEC)
        # UIService gateway handles Reduced Motion null-tween case internally

func _clamp_camera_to_bounds() -> void:
    var bounds := _compute_node_root_bounding_box().grow(CLAMP_PADDING_PX)
    _camera.position = _camera.position.clamp(bounds.position, bounds.end)
```

- Uses ADR-0010 `UIService.tween_property` gateway (Reduced Motion uniform handling)
- Settings `input.gamepad_stick_deadzone` per ADR-0009 — story 009 wires subscriber (this story consumes via `SettingsService.get`)
- Auto-center triggered by focus events (D-pad/Tab/Arrow handled in story 011 focus traversal); this story exposes `auto_center_on()` API only
- Clamp box: `_compute_node_root_bounding_box` iterates all HypothesisNode positions → Rect2 + padding

---

## Out of Scope

- Story 003: HypothesisNode position (this story pans Camera, not nodes)
- Story 009: Settings subscription wiring
- Story 011: Focus traversal D-pad/Tab/Arrow — triggers `auto_center_on()` (this story exposes the call site)
- Story 012: Performance test (60fps with 30 nodes — AC-49) — this story doesn't enforce fps gate

---

## QA Test Cases

- **AC-41 Manual**: Middle-click + drag 100px → canvas pans 100px opposite direction; verify cursor stays fixed at screen position
- **AC-42 Manual**: Push right-stick fully right for 1 second → camera position += ~600px to right (with deadzone 0.15 default); test at deadzone=0.5 — small stick deflection ignored
- **AC-43 Manual**: D-pad navigate from node A to node B → camera lerps to B's position over 0.2s. Toggle reduced_motion ON → instant snap
- **AC-44 Manual**: Scroll wheel up/down → camera.y −= / += 80px per tick
- **AC-50 Manual**: Try to pan beyond rightmost node + 200px → camera clamps
- **AC-51 Manual**: Build worst-case tree (3 roots × 3 deep × 5 evidence per node) on 1366×768 → pan + auto-center together can reach all nodes

---

## Test Evidence

**Story Type**: UI
**Required**: `production/qa/evidence/workspace-tree-panning-evidence.md` — manual walkthrough with screenshots / video (ux-designer sign-off)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (WorkspaceData), Story 003 (HypothesisNode positions), Story 009 (Settings subscription)
- Unlocks: Story 011 (focus traversal triggers auto_center_on), Story 012 (performance test uses panning at worst-case tree)
