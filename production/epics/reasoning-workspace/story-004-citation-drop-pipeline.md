# Story 004: Citation drop pipeline (mouse + KB + Gamepad)

> **Epic**: Reasoning Workspace
> **Status**: Ready
> **Layer**: Feature (Gameplay)
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§3.3 Interactions, §5.3 Evidence drop edge cases, §9.4.2 Space-mark/attach KB, §9.4.3 Gamepad A→A two-step, §10.5 CitationDrop)
**Requirement**: `TR-WORKSPACE-LAYOUT-002` (CitationDrop hybrid signal topology) + `TR-WORKSPACE-LAYOUT-005` (Gamepad two-step)

**ADR Governing Implementation**: ADR-0008 §2 (CitationDrop hybrid signal topology) + amend-1 §A3 (hit-test tie-break) + amend-1 §A5 (typed `.emit()`) + amend-3 §E1 (drop target state guard scope to DeskPane only) + amend-3 §E3 (VR-D6 CLOSED — native cross-viewport dispatch confirmed)
**ADR Decision Summary**: Hybrid signal topology — Godot 4.6 native drag-drop callbacks (`_get_drag_data` / `_can_drop_data` / `_drop_data`) + LibraryService autoload signal `citation_drag_started(library_id)` (typed) + application-level `WorkspaceData.pending_citation: String` for KB Space-mark/attach + Gamepad A→A two-step. State guard: drop blocked when `state != ACTIVE`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: VR-D6 prototype confirmed cross-viewport dispatch (4/4 drags PASS). `_can_drop_data` / `_drop_data` fire on root viewport target from SubViewport-internal drag source. DragManager fallback UNUSED.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.5 CitationDrop (AC-28 ~ AC-32) — 5 AC.

- [ ] AC-28 — Mouse drag from LibraryPane card onto DeskPane HypothesisNode attaches evidence_id; `citation_drag_started(library_id)` signal emits at drag start; `_drop_data` resolves on node hit
- [ ] AC-29 — KB Space on focused LibraryPane card → `WorkspaceData.pending_citation = library_id` + status bar "[library_id] 인용 대기 중. 노드 포커스 후 Space로 첨부" + 좌상단 floating 배지
- [ ] AC-30 — Evidence cap reached, 6th drop rejected with "이 노드에는 인용을 5개까지만 첨부할 수 있습니다" hint (UI path mirror of AC-14)
- [ ] AC-31 — Mouse drag threshold = `input.mouse_drag_threshold_px` (default 8, range [4,32] per ADR-0009 TR-settings-004) — drag starts only when cursor moves ≥ threshold from press point
- [ ] AC-32 — Hit-test tie-break (overlapping nodes): topmost node (highest z-index then latest add) receives drop per ADR-0008 amend-1 §A3
- [ ] AC-46 — Gamepad CitationDrop discrete two-step (A on LibraryPane → A on DeskPane node → attach, B → cancel; FROZEN auto-cancels pending) — ADVISORY per OQ-W9 carry-over

---

## Implementation Notes

Per ADR-0008 §2 + amend-1 §A3/A5 + amend-3 §E1/E3:

```gdscript
# LibraryPane card — drag source
class_name LibraryCard extends PanelContainer
@export var library_id: String

func _get_drag_data(_pos: Vector2) -> Variant:
    LibraryService.citation_drag_started.emit(library_id)  # typed .emit() per amend-1 §A5
    var preview := _build_drag_preview()
    set_drag_preview(preview)
    return {"type": "citation", "library_id": library_id}

# DeskPane HypothesisNode — drop target (within SubViewport — VR-D6 confirmed dispatch)
func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
    if WorkspaceData.state != WorkspaceState.ACTIVE:
        return false   # DeskPane drop only — Brief CitationPanel is independent guard (amend-3 §E1)
    return data is Dictionary and data.get("type") == "citation"

func _drop_data(_pos: Vector2, data: Variant) -> void:
    var library_id: String = data["library_id"]
    if not _hypothesis_data.can_add_evidence():
        UIService.announce_text(self, "이 노드에는 인용을 5개까지만 첨부할 수 있습니다", UIService.AnnouncePriority.POLITE)
        return
    _hypothesis_data.evidence.append(library_id)
    AudioService.play("weight-stamp")
    WorkspaceData.pending_citation = ""

# KB Space pattern (Workspace LibraryPane focused)
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("workspace_citation_pending"):
        if _is_library_card_focused():
            WorkspaceData.pending_citation = _focused_library_id()
            UIService.show_status_bar("%s 인용 대기 중. 노드 포커스 후 Space로 첨부" % WorkspaceData.pending_citation)
        elif _is_hypothesis_node_focused() and WorkspaceData.pending_citation != "":
            _attach_pending_to_focused_node()

# Gamepad A→A pattern mirror KB (FROZEN auto-cancel)
func _on_workspace_state_changed(_old: int, new: int) -> void:
    if new == WorkspaceState.FROZEN:
        WorkspaceData.pending_citation = ""
```

- Native cross-viewport dispatch confirmed by VR-D6 (4/4 PASS) — no DragManager autoload needed
- LibraryService autoload FIRST per ADR-0008 §2 — `citation_drag_started` typed signal subscriber chain
- ADR-0008 amend-3 §E2 typed `.emit()` cascade — string-keyed `emit_signal` forbidden
- Gamepad two-step: button mapping defers to ADR-0008 §5 + OQ-W9 prototype (UI Foundation epic). AC-46 ADVISORY until OQ-W9 ratify.

---

## Out of Scope

- Story 003: Tree structure invariants (AC-12 max depth, AC-14 evidence cap — this story triggers cap rejection via call, doesn't re-enforce limit)
- Story 005: MemoPanel (separate from CitationDrop)
- Story 006: Tree panning camera (focus management is story 011)
- Story 008: Crash recovery cascade (pending_citation auto-clear on FROZEN is here but auto-resubmit is story 008)
- Story 009: Settings subscription for `mouse_drag_threshold_px` — this story consumes the value, story 009 wires the subscriber
- Story 010: AccessKit role for LibraryCard (= ROLE_LIST_ITEM per amend-1 §G1)

---

## QA Test Cases

- **AC-28 Integration**: Spawn LibraryCard + HypothesisNode, simulate `_get_drag_data` + `_drop_data` programmatically, verify `citation_drag_started` signal fired + evidence array updated
- **AC-29**: Press `workspace_citation_pending` action with LibraryCard focused → `WorkspaceData.pending_citation == library_id`; press again with HypothesisNode focused → evidence attached, pending cleared
- **AC-30**: Node with 5 evidence; simulate drop → `can_add_evidence()` false → hint announced via UIService.announce_text
- **AC-31**: Settings `input.mouse_drag_threshold_px = 16`; mouse press + move 12px → no drag; move 18px → drag starts
- **AC-32**: Two overlapping nodes; drop on overlap region → topmost (highest z-index then latest add) receives drop
- **AC-46 Manual**: Gamepad A on LibraryPane → A on DeskPane node → attached + audio cue + pending badge cleared; B → cancel

Edge cases: drag in non-ACTIVE state (rejected), drop on empty DeskPane (no node hit → silent), pending_citation set then state→FROZEN (auto-clear).

---

## Test Evidence

**Story Type**: Integration
**Required**:
- `tests/integration/workspace/citation_drop_test.gd` — AC-28/29/30/31/32 (gdunit4)
- `production/qa/evidence/workspace-gamepad-citation-drop.md` — AC-46 manual walkthrough (ADVISORY status per OQ-W9)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (WorkspaceData state), Story 003 (HypothesisNode + can_add_evidence)
- Unlocks: Story 011 (focus + visual feedback for drag preview), Story 012 (edge cases — evidence drop in non-ACTIVE state)
