# Epic: Reasoning Workspace

> **Layer**: Feature (Gameplay — depends on Foundation #2 UI Foundation + #3 Save/Load + Core #4 Settings & Accessibility + Foundation #20 Library + #1 Case Data Schema)
> **GDD**: `design/gdd/reasoning-workspace.md`
> **Architecture Module**: DeskPane (Kr3PaneLayout center pane) + DeskCanvas (SubViewportContainer + SubViewport + HypothesisNodeRoot Node2D) + HypothesisNode × N (KrCard subclass per ADR-0010 §Architecture Diagram) + MemoPanel + SubmitButton + FreezeOverlay + ReadOnlyIndicator
> **Status**: Ready
> **Stories**: 12 created 2026-05-18 (run `/story-readiness` → `/dev-story` per story to implement)
> **Created**: 2026-05-18

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [WorkspaceData Resource + 4-state machine](story-001-workspace-state-machine.md) | Logic | **Complete (2026-05-18)** | ADR-0008 §1 |
| 002 | [chain_data Variant-only schema + 5 derivation formulas + BFS canonical ordering](story-002-chain-data-schema.md) | Logic | **Complete (2026-05-18)** | ADR-0007 amend-1 + ADR-0008 amend-1 §A6 |
| 003 | [HypothesisNode KrCard subclass + tree construction](story-003-hypothesis-node-tree-construction.md) | Logic (data-layer) / UI (deferred) | **Complete data-layer (2026-05-18)** / UI scene → story-003b (UI Foundation epic prerequisite) | ADR-0008 §1 + ADR-0010 KrCard |
| 004 | [Citation drop pipeline (mouse + KB + Gamepad)](story-004-citation-drop-pipeline.md) | Integration | Ready | ADR-0008 §2 + amend-1 §A3/A5 + amend-3 §E1/E3 |
| 005 | [MemoPanel layout (A inline + B fixed) + 0.15s fade](story-005-memo-panel.md) | UI + Visual/Feel | Ready | ADR-0008 §3 + amend-1 §A4 |
| 006 | [Tree panning Camera2D](story-006-tree-panning-camera.md) | UI | Ready | ADR-0008 §4 |
| 007 | [Freeze + submit cascade](story-007-freeze-submit-cascade.md) | Integration | Ready | ADR-0008 §1 + ADR-0007 + ADR-0001 amend-2 |
| 008 | [READ_ONLY state + ReadOnlyIndicator + crash recovery cascade](story-008-read-only-crash-recovery.md) | Integration | Ready | ADR-0008 §1 + ADR-0011 |
| 009 | [Settings subscription cascade — UIService auto-subscribe](story-009-settings-subscription.md) | Integration | Ready | ADR-0010 + amend-1 + ADR-0009 |
| 010 | [AccessKit roles per amend-4 §F1 corrected mapping + live-region announce cascade](story-010-accesskit-roles.md) | Logic + UI | Ready | ADR-0008 amend-4 §F1 + ADR-0010 amend-1 §G3 |
| 011 | [Visual + audio polish](story-011-visual-audio-polish.md) | Visual/Feel | Ready | ADR-0004 + amend-1 + ADR-0008 + ADR-0010 R8 |
| 012 | [Edge cases + performance gates](story-012-edge-cases-performance.md) | Logic + Visual/Feel | Ready | ADR-0008 §6 + amend-1 §A6 + ADR-0010 R6 |

## Overview

The Reasoning Workspace is the variable's *thinking desk* — the central gameplay system where the lawyer drags evidence (LibraryPane → DeskPane) to construct a hypothesis tree (max depth 3, max evidence-per-node 5), authors persistent memos per node, and freezes the snapshot to commit to a submission. The workspace is a 4-state machine (INACTIVE / ACTIVE / FROZEN / READ_ONLY) with strict ownership semantics: state mutates only via typed signal cascades, chain_data exports only Variant primitives (no Resource references), and the workspace's frozen snapshot is the canonical input to the Brief Editor and EvaluationService submission pipeline.

This epic implements all 10 GDD sections (Core Rules / States / Interactions / 5 formula categories / 24 edge cases / 7 sub-categories of tuning knobs / 8 visual+audio requirements / 9 UI requirements / 56 acceptance criteria) using the KrCustomControl tree (ADR-0010) + Theme type variations (ADR-0004 amend-1) + native Godot 4.6 drag-drop callbacks (VR-D6 confirmed cross-viewport dispatch). Implementation is unblocked: 14 ADR transactional bundle Accepted 2026-05-17 + ADR-0009 Accepted 2026-05-18.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Workspace Layout | DeskPane Control hierarchy + CitationDrop hybrid signal topology (native callbacks + LibraryService signal + WorkspaceData.pending_citation) + Tree panning (Camera2D middle-drag/right-stick/auto-center) + Gamepad CitationDrop two-step | LOW |
| ADR-0008 amend-1: Cycle 3·4 Carry-over Closure | AccessibilityRole pre-implementation verification gate (4 confirmed: ROLE_TREE/TREE_ITEM/DIALOG/BUTTON) + Cursor grab asset spec + chain_data hit-test tie-break + typed `.emit()` pattern + chain_data_include_ephemeral_field forbidden | LOW (sprint confirmed) |
| ADR-0008 amend-2: Brief Editor Godot 4.6 API + AccessKit 7-Enum | Dictionary.duplicate(true) Variant-only contract + AccessKit 7-enum gate (retroactively corrected in amend-4 §F1) | LOW (post-amend-4) |
| ADR-0008 amend-3: Architecture Review Cascade Closure | Drop target state guard scope + typed `.emit()` cascade + VR-D6 SubViewport drag-drop verification (now PASS) + 17-enum gate consolidation | LOW (VR-D6 CLOSED) |
| ADR-0008 amend-4: Verification Sprint FAIL Closure | AccessibilityRole 7 enum corrected mapping (ROLE_REGION→ROLE_PANEL etc.) + IME Path A removed + Path B-cross redesigned (_gui_input pattern) + VR-D3 guard policy lock | LOW |
| ADR-0001 amend-2: BriefEditorData Resource Lifecycle | workspace freeze export → BriefEditor IMPORTING (workspace_state_changed signal cascade) | LOW |
| ADR-0004: Korean Text Rendering MSDF Font | 3-font family lock (본명조 court_title + Pretendard body_sans + IBM Plex Mono code_mono) | LOW |
| ADR-0004 amend-1: Component Type Variations Expansion | 17 Theme type variations (Pane/Header/Card/HypothesisNode/MemoLabel/CommentLabel/CourtHeadline/CaptionLabel/Banner family 등) + text_scale runtime reload single-emit cascade | LOW (VR-UI1 PASS) |
| ADR-0007: Submission Evaluation Algorithm | EvaluationService autoload FOURTH + submit() pipeline contract | LOW |
| ADR-0007 amend-1: chain_data Variant Primitives Only | chain_data Dictionary는 String/int/float/bool/Array/Dict primitives only — no Resource refs | LOW |
| ADR-0007 amend-2: Disposition Enum MVP Scope Lock | 4-enum disposition (ACCEPT/REJECT/PARTIAL_ACCEPT/REMAND) + v1+ deferred extension policy | LOW |
| ADR-0010: UI Foundation Architecture | UIService autoload SECOND + KrCustomControl 21 클래스 트리 + Theme runtime reload + Reduced Motion gateway + dual focus ring composite | LOW (VR-UI1/UI2/UI4/UI6 CLOSED) |
| ADR-0010 amend-1: KrCustomControl Role Corrections + Live-Region | 7 enum corrected mapping (KrPane→ROLE_PANEL etc.) + UIService.announce_text(source, message, priority) API (VR-UI6 PASS path) | LOW |
| ADR-0011: Save/Load Storage Format | workspace_state_changed signal trigger + atomic write (write-to-temp + DirAccess.rename_absolute) + crash recovery cascade | LOW |
| ADR-0009: Settings Storage Format | reduced_motion + text_scale + focus_indicator_thickness signal subscribers (KrCustomControl auto-subscribe via UIService) | LOW |

## GDD Requirements

### Architectural TR coverage (5/5)

| TR-ID | Requirement (summary) | ADR Coverage |
|-------|----------------------|--------------|
| TR-WORKSPACE-LAYOUT-001 | DeskPane Control hierarchy 잠금 (DeskCanvas SubViewportContainer + HypothesisNode × N + MemoPanel + SubmitButton + FreezeOverlay + ReadOnlyIndicator) | ADR-0008 §1 ✅ |
| TR-WORKSPACE-LAYOUT-002 | CitationDrop hybrid signal topology (native drag-drop + LibraryService signal + pending_citation Variant) | ADR-0008 §2 + amend-1 §A3/A5 ✅ |
| TR-WORKSPACE-LAYOUT-003 | MemoPanel layout (B) fixed bottom-right default + (A) inline opt-in (root_count ≤ 2 + DeskPane.size.x ≥ 720) + 0.15s fade | ADR-0008 §3 + amend-1 §A4 ✅ |
| TR-WORKSPACE-LAYOUT-004 | Tree panning Camera2D (middle-drag 1:1 + right-stick 600 px/s + D-pad/Tab auto-center 0.2s + scroll wheel + clamp) | ADR-0008 §4 ✅ |
| TR-WORKSPACE-LAYOUT-005 | Gamepad CitationDrop discrete two-step (A→A attach + B cancel, FROZEN auto-cancel pending) | ADR-0008 §5 ✅ |

### Design-level requirements (story-decomposition scope)

GDD documents 56 Acceptance Criteria across 12 sub-categories (Core Behavior / Tree Construction / Citation Drop / Memo Authoring / Freeze + Submit / Read-Only Recovery / Settings Subscription / AccessKit / Visual + Audio / Gamepad / Edge Cases / Performance), 24 Edge Cases across 7 categories, 5 newly registered constants in `entities.yaml v8`:

- `workspace_max_tree_depth` = 3
- `workspace_evidence_per_node_cap` = 5
- `workspace_node_label_char_limit` = 60 chars
- `workspace_node_memo_char_limit` = 500 chars (UTF-8 codepoints)
- `workspace_delete_confirmation_subtree_threshold` = 0 (always show)

These map to story-level acceptance gates — decomposed in `/create-stories reasoning-workspace`.

### Untraced (carry-over OQs — not implementation blockers)

| OQ | Disposition |
|---|---|
| OQ-W3 (chain_data memo_text v1+) | Deferred to schema_version 2 bump |
| OQ-W4 (autosave 빈도 정책) | Already covered by ADR-0011 workspace_state_changed signal trigger — implementation cycle confirms cadence |
| OQ-W7 (AccessKit Godot 4.6 검증) | Partially closed via VR-UI6 dump + VR-S1 (settings) — fully resolved at implementation entry |
| OQ-W9 (gamepad CitationDrop discrete 대안) | Implementation cycle prototype (LB/RB pane switcher candidate per ADR-0008 §5) |
| OQ-W10 (tree canvas panning) | Closed by ADR-0008 §4 |
| OQ-W11 / OQ-W12 (≥10분 BGM / 비음성 사운드 시각 지시자) | v1+ playtest scope — out of MVP |
| OQ-QA-1 (AC-46 advisory gamepad CitationDrop) | Subsumed by OQ-W9 |
| OQ-QA-2 (AC-49 60fps Control class blocked) | Resolved by ADR-0010 KrCustomControl tree — implementation cycle measures actual fps |

## Definition of Done

This epic is complete when:

- All stories are implemented, reviewed, and closed via `/story-done`
- All 56 acceptance criteria from `design/gdd/reasoning-workspace.md` §10 are verified (story-level + integration-level)
- All 24 edge cases (`design/gdd/reasoning-workspace.md` §5) are tested or documented as deferred
- All Logic stories (chain_data derivations, tree invariants, evaluation_density formula, freeze snapshot semantics) have passing test files in `tests/unit/workspace/`
- All Integration stories (LibraryService citation_drag_started ↔ DeskPane drop, workspace_state_changed → SaveLoadService autosave, freeze export → BriefEditor IMPORTING) have passing test files in `tests/integration/workspace/`
- All Visual/Feel stories (KrCard hover/focus rings, MemoPanel fade transition, FreezeOverlay opacity, ReadOnlyIndicator pulse, drag preview, ToastBanner 등) have evidence docs with art-director + ux-designer sign-off in `production/qa/evidence/`
- All UI stories (KB shortcut catalog, gamepad two-step CitationDrop, MemoPanel A/B layout transition, Submit confirmation dialog focus default) have manual walkthrough docs or interaction tests in `production/qa/evidence/`
- VR-D7 (cross-platform IME) result documented (PASS lock or amend-5 platform branch cascade) — required for Brief Editor #7 implementation prerequisite confirmation (this epic itself does not block on VR-D7)
- entities.yaml v8 5 constants verified used in code (no magic numbers)

## Next Step

Run `/create-stories reasoning-workspace` to break this epic into implementable stories.

Recommended story-decomposition order (Logic → Integration → Visual/UI):
1. **State machine + workspace data primitives** (WorkspaceData Resource + 4-state machine + chain_data Variant-only schema + 5 derivation formulas)
2. **Tree construction** (HypothesisNode KrCard subclass + parent/child link + max depth=3 + max evidence=5 + label/memo char limits)
3. **Citation drop pipeline** (LibraryService signal subscribe + native drag-drop callbacks + KB Space-mark/attach + Gamepad A→A two-step)
4. **Memo authoring** (MemoPanel A/B layout + 0.15s fade + char cap + Reduced Motion snap)
5. **Tree panning camera** (Camera2D + middle-drag + right-stick + auto-center lerp + scroll wheel + clamp)
6. **Freeze + submit cascade** (workspace_state_changed signal + chain_data export Dictionary.duplicate(true) + EvaluationService.submit() + BriefEditor IMPORTING handoff)
7. **Read-only recovery** (READ_ONLY state + ReadOnlyIndicator + crash recovery from SaveLoadService)
8. **Settings subscription** (KrCustomControl auto-subscribe via UIService — reduced_motion + text_scale + focus_indicator_thickness)
9. **AccessKit roles** (KrPane ROLE_PANEL + HypothesisNode ROLE_TREE_ITEM + DeskCanvas ROLE_TREE per amend-4 §F1 corrected mapping)
10. **Visual + audio polish** (art-director 7 sub-categories + audio-director 21-event catalog)
11. **Gamepad full-path traversal** (focus walk + LB/RB pane switcher + OQ-W9 fallback)
12. **Edge case + performance gates** (24 EC + AC-49 60fps with 5 root × 3 deep × 5 evidence)
