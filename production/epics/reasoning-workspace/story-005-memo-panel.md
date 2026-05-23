# Story 005: MemoPanel layout (A inline + B fixed) + 0.15s fade transition

> **Epic**: Reasoning Workspace
> **Status**: Ready
> **Layer**: Feature (Gameplay)
> **Type**: UI + Visual/Feel (UI primary)
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§9.3 Memo Panel Position, §10.7 UI Visual / Interaction partial)
**Requirement**: `TR-WORKSPACE-LAYOUT-003`

**ADR Governing Implementation**: ADR-0008 §3 (MemoPanel layout) + amend-1 §A4 (default reframe to B fixed bottom-right) + ADR-0010 KrPane (panel root role = ROLE_PANEL per amend-1 §G1)
**ADR Decision Summary**: MemoPanel default position = (B) fixed bottom-right. (A) inline next to selected node enabled when `root_count ≤ 2 AND DeskPane.size.x ≥ 720`. 0.15s opacity fade transition; Reduced Motion → immediate snap. Memo TextEdit enforces char cap per story 003.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `UIService.tween_property()` gateway for fade (Reduced Motion check inside per ADR-0010). `theme_type_variation = &"MemoLabel"` / `&"MemoEdit"` per ADR-0004 amend-1.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.7 UI Visual / Interaction (MemoPanel-related ACs).

- [ ] AC-33 — MemoPanel default position (B) fixed bottom-right of DeskPane viewport; min 320×240px
- [ ] AC-34 — (A) inline mode activated when `WorkspaceData.roots().size() ≤ 2 AND DeskPane.size.x ≥ 720`; panel anchored next to selected HypothesisNode, top edge aligned to node
- [ ] AC-35 — Transition between A↔B layouts: 0.15s opacity fade via `UIService.tween_property()`; Reduced Motion (settings) → immediate snap
- [ ] AC-36 — Selected node deselected → MemoPanel fade out (0.15s); new node selected → fade in to new position
- [ ] AC-38 — Memo TextEdit type variation `&"MemoEdit"` applied (per ADR-0004 amend-1); char cap enforcement delegated to story 003 HypothesisNode invariant
- [ ] AC-40 — `display.reduced_motion = true` → all opacity fades replaced with instant set (verifies UIService.tween_property gateway path)

---

## Implementation Notes

Per ADR-0008 §3 + amend-1 §A4 + ADR-0010 UIService gateway:

```gdscript
class_name MemoPanel extends PanelContainer

@onready var _memo_edit: TextEdit = $MemoEdit
var _current_node: HypothesisNode = null
var _is_inline_eligible: bool:
    get: return WorkspaceData.roots().size() <= 2 and DeskPane.size.x >= 720

func _ready() -> void:
    theme_type_variation = &"Pane"
    accessibility_role = AccessibilityRole.ROLE_PANEL   # =6 per amend-1 §G1
    _memo_edit.theme_type_variation = &"MemoEdit"
    _memo_edit.accessibility_role = AccessibilityRole.ROLE_MULTILINE_TEXT_FIELD   # =19
    WorkspaceData.node_selected.connect(_on_node_selected)
    WorkspaceData.node_deselected.connect(_on_node_deselected)

func _on_node_selected(node: HypothesisNode) -> void:
    _current_node = node
    if _is_inline_eligible:
        _position_inline_next_to(node)
    else:
        _position_fixed_bottom_right()
    _fade_in()

func _fade_in() -> void:
    modulate.a = 0.0
    visible = true
    UIService.tween_property(self, "modulate:a", 1.0, 0.15)  # Reduced Motion gateway inside

func _fade_out() -> void:
    UIService.tween_property(self, "modulate:a", 0.0, 0.15).finished.connect(func(): visible = false)
```

- `UIService.tween_property` ADR-0010 §Decision returns null when reduced_motion → set immediately (no tween created)
- MemoPanel root = KrPane (ROLE_PANEL per amend-1 §G1 corrected mapping)
- 720px threshold + 2-root threshold from amend-1 §A4 reframe — magic numbers NOT in code; use entities.yaml constants if registered or local consts referencing amend-1 §A4 comment

---

## Out of Scope

- Story 003: Memo char cap enforcement (HypothesisNode invariant — this story doesn't re-enforce)
- Story 009: Settings subscription wiring (UIService subscribe; this story consumes `display.reduced_motion` via UIService.tween_property gateway only)
- Story 010: AccessKit role audit (this story applies KrPane + MemoEdit roles inline; cross-cutting audit is story 010)
- Story 011: Visual polish for fade animation curve (this story only sets duration; bezier curve + easing in story 011)

---

## QA Test Cases

- **AC-33 Manual**: Open Workspace, no node selected → MemoPanel not visible. Select node → MemoPanel appears at bottom-right (B mode) with min 320×240
- **AC-34 Manual**: Workspace with 1 root, DeskPane width ≥ 720px → MemoPanel anchored inline next to selected node; widen window → toggle to inline mode
- **AC-35 Manual**: Transition between A and B (e.g., delete a root to drop below 3) → 0.15s opacity fade observable; check `production/qa/evidence/` screenshot
- **AC-36 Manual**: Click node → fade in; click empty area → fade out (0.15s each)
- **AC-38 Manual**: Inspect MemoPanel scene tree → `theme_type_variation == &"Pane"`; MemoEdit `== &"MemoEdit"`
- **AC-40 Manual**: Set `display.reduced_motion = true` in Settings, repeat AC-35 → no fade animation (instant set)

---

## Test Evidence

**Story Type**: UI + Visual/Feel
**Required**: `production/qa/evidence/workspace-memo-panel-evidence.md` — manual walkthrough screenshots + sign-off (ux-designer + art-director)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (WorkspaceData), Story 003 (HypothesisNode), Story 009 (Settings subscription via UIService)
- Unlocks: Story 011 (visual polish curve + easing tuning)
