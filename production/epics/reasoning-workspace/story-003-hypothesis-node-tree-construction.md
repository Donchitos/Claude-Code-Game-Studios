# Story 003: HypothesisNode KrCard subclass + tree construction

> **Epic**: Reasoning Workspace
> **Status**: Complete (data-layer scope, 2026-05-18) / UI scene wrapping deferred to story-003b (UI Foundation epic prerequisite)
> **Layer**: Feature (Gameplay)
> **Type**: Logic (data-layer) / UI (deferred)
> **Manifest Version**: 2026-05-18
> **Estimate**: 4 hours (M-L) data-layer scope
> **Performance**: No expected impact — user-event triggered (< 100x/session), O(D≤3) depth check + O(N≤30) BFS cycle detection — sub-millisecond
> **Completed (data-layer)**: 2026-05-18
> **Scope split**: AC-12/13/14/15/16 invariants implemented as WorkspaceData mutation API + HypothesisNodeData `memo` field. AC-13b (UI ease-back) + `class_name HypothesisNode extends PanelContainer` (KrCard composition) + `theme_type_variation = &"HypothesisNode"` + AccessKit role assignment deferred to story-003b after UI Foundation epic.

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§3.1 Core Rules, §4.2 tree structural invariants, §5.2 tree-structural violations, §10.2 Tree Structural Invariants, entities.yaml v8 constants)
**Requirement**: `TR-WORKSPACE-LAYOUT-001`

**ADR Governing Implementation**: ADR-0008 §1 (DeskPane Control hierarchy) + ADR-0010 KrCard subclass (HypothesisNode → ROLE_TREE_ITEM per amend-1 §G1) + ADR-0008 amend-3 §E3 (HypothesisNode redefine to KrCard inheritance)
**ADR Decision Summary**: HypothesisNode is a `KrCard` subclass (per ADR-0010 §Architecture Diagram + amend-3 §E3) with explicit limits enforced at construction/mutation time: max tree depth 3, evidence cap 5 per node, label ≤ 60 chars, memo ≤ 500 UTF-8 codepoints. Cycle detection blocks self-or-ancestor reparenting.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: KrCard uses composition + static helper pattern (godot-specialist 2026-05-17 — multiple-inheritance bypass per ADR-0010 §Decision Note). `theme_type_variation = &"HypothesisNode"` per ADR-0004 amend-1.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.2 Tree Structural Invariants (AC-12 ~ AC-16, AC-13b) — 5 AC + AC-13b sub.

- [ ] AC-12 — Max tree depth = `workspace_max_tree_depth` (=3, entities.yaml v8). Attempted child add at depth=3 rejected with `push_error("max tree depth 3 exceeded")` + hint "이 분기는 더 깊이 추론할 수 없습니다 (최대 3단계)"
- [ ] AC-13 — Cycle detection: `reparent(B, A)` where A is descendant of B rejected; tree state unchanged; emits `tree_invariant_violation("cycle")`
- [ ] AC-13b — Cycle detection UI integration: plain drag of parent node A onto child B → drag controller rejects + ease-back animation + hint "노드를 자신의 하위 노드로 이동할 수 없습니다"
- [ ] AC-14 — Evidence cap: each node holds at most `workspace_evidence_per_node_cap` (=5) evidence_ids. Attempted 6th drop rejected with hint "이 노드에는 인용을 5개까지만 첨부할 수 있습니다"
- [ ] AC-15 — Label char limit: `workspace_node_label_char_limit` (=60) — input truncated at 60 chars with hint "노드 레이블은 60자까지만"
- [ ] AC-16 — Memo char limit: `workspace_node_memo_char_limit` (=500 UTF-8 codepoints) — TextEdit enforces via cross-platform IME pattern (per ADR-0008 amend-4 §F3 — VR-D7 pending for IME composition handling)

---

## Implementation Notes

Per ADR-0008 §1 + ADR-0010 §Decision + amend-3 §E3:

```gdscript
# HypothesisNode — KrCard subclass via composition+helper per ADR-0010 §Decision Note
class_name HypothesisNode extends PanelContainer  # KrCard base = PanelContainer

const MAX_DEPTH := 3              # entities.yaml workspace_max_tree_depth
const EVIDENCE_CAP := 5           # entities.yaml workspace_evidence_per_node_cap
const LABEL_CHAR_LIMIT := 60      # entities.yaml workspace_node_label_char_limit
const MEMO_CHAR_LIMIT := 500      # entities.yaml workspace_node_memo_char_limit

@export var data: HypothesisNodeData

func _ready() -> void:
    theme_type_variation = &"HypothesisNode"
    KrControlHelper.setup(self)   # auto-subscribe settings + accessibility_role
    accessibility_role = AccessibilityRole.ROLE_TREE_ITEM   # =28 per amend-4 §F1

func add_child_hypothesis(child_label: String) -> bool:
    if data.depth >= MAX_DEPTH:
        push_error("max tree depth %d exceeded" % MAX_DEPTH)
        UIService.announce_text(self, "이 분기는 더 깊이 추론할 수 없습니다 (최대 %d단계)" % MAX_DEPTH, UIService.AnnouncePriority.POLITE)
        return false
    # ... create child node, depth = self.depth + 1
    return true

func can_add_evidence() -> bool:
    return data.evidence.size() < EVIDENCE_CAP

func reparent_to(new_parent: HypothesisNode) -> bool:
    if _is_descendant_of(new_parent):
        push_error("cycle detected: cannot reparent to descendant")
        WorkspaceData.tree_invariant_violation.emit("cycle")
        return false
    # ... perform reparent
    return true
```

- entities.yaml v8 5 constants — load via SettingsService or const file; no magic numbers in story 003 code
- HypothesisNode label uses `KrLineEdit` (`ROLE_TEXT_FIELD` = 18 per amend-1 §G1) with `LABEL_CHAR_LIMIT`
- Memo uses `KrTextEdit` (`ROLE_MULTILINE_TEXT_FIELD` = 19 per amend-1 §G1 — corrected from earlier ROLE_TEXT_FIELD) with `MEMO_CHAR_LIMIT` and amend-4 §F3 cross-platform IME `_gui_input` pattern (VR-D7 confirms; non-blocking)
- Drag-drop attachment is story 004 scope; this story only defines HypothesisNode structure + invariant enforcement

---

## Out of Scope

- Story 001: WorkspaceData state machine + Resource definition
- Story 002: chain_data export (this story builds tree; story 002 serializes)
- Story 004: CitationDrop pipeline (this story enforces evidence cap but doesn't handle drag-drop)
- Story 005: MemoPanel layout (this story enforces memo cap but doesn't lay out the panel)
- Story 010: AccessKit role assignment is partially in this story (HypothesisNode = ROLE_TREE_ITEM) but cross-cutting role audit is story 010
- Story 012: Edge cases beyond AC-12~16 (this story covers structural invariants only)

---

## QA Test Cases

- **AC-12**: Build tree to depth 3, attempt add at depth 3 → false + error + hint emitted
- **AC-13**: Tree A→B→C; attempt `reparent(B, C)` → rejected + `tree_invariant_violation` signal emitted
- **AC-13b**: Manual UI walkthrough — drag parent onto child → ease-back animation + hint
- **AC-14**: Add 5 evidence to node; attempt 6th → `can_add_evidence()` false + hint
- **AC-15**: Try to set label to 65-char string → truncated to 60 + hint
- **AC-16**: TextEdit `text` setter input 600 chars → truncated at 500; verify with composition (Korean IME compose mid-string — defers cap check until composition complete per amend-4 §F3)

Edge cases: depth=0 root, single-child tree, reparent root to its own descendant via deep chain.

---

## Test Evidence

**Story Type**: Logic (with UI verification for AC-13b)
**Required**:
- `tests/unit/workspace/tree_invariants_test.gd` — gdunit4 logic tests for AC-12/13/14/15/16
- `tests/integration/workspace/tree_invariants_test.gd::test_cycle_detection_ui_path` — AC-13b UI path

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (WorkspaceData Resource + HypothesisNodeData type)
- Unlocks: Stories 004 (CitationDrop), 005 (MemoPanel), 010 (AccessKit role audit), 011 (visual polish), 012 (edge cases)
