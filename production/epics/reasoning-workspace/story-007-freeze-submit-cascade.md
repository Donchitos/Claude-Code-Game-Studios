# Story 007: Freeze + submit cascade

> **Epic**: Reasoning Workspace
> **Status**: Complete (data-layer scope, 2026-05-23) / UI dialog + BriefEditor integration deferred to story-007b (UI Foundation epic prerequisite)
> **Layer**: Feature (Gameplay)
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 4-5h (M)

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§3.2 ACTIVE→FROZEN transition, §3.3 cycle 3 Decision 2 submit confirmation, §10.4 Freeze Forward-Constraint, §10.11 Cross-System Interaction)
**Requirement**: `TR-WORKSPACE-LAYOUT-001` (state machine FROZEN) + ADR-0007 §1 (submit pipeline)

**ADR Governing Implementation**: ADR-0008 §1 (workspace_state_changed signal cascade) + ADR-0007 (EvaluationService.submit) + ADR-0007 amend-1 (chain_data Variant primitives) + ADR-0001 amend-2 (BriefEditorData lifecycle — workspace freeze → BriefEditor IMPORTING transition) + ADR-0011 (SaveLoadService SIXTH atomic write on signal cascade)
**ADR Decision Summary**: `_transition_to_frozen()` snapshots chain_data via `build_chain_data()` (story 002), assigns to `chain_data_snapshot` field, emits `workspace_state_changed(ACTIVE, FROZEN)`. Subscribers: SaveLoadService → atomic write of WorkspaceData.tres; BriefEditor → INACTIVE→IMPORTING auto-transition (per ADR-0001 amend-2). Submit confirmation dialog blocks freeze pending Pillar 3 commit anchor.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `Dictionary.duplicate(true)` 4.0+ stable; per ADR-0008 amend-2 §D3 disambiguation, deep-copy semantics on Variant primitives only (no Resource refs). KrDialog (`ROLE_DIALOG` = 44 per amend-1 §G1) for confirmation dialog.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.4 Freeze Forward-Constraint (AC-24 ~ AC-27d) + §10.11 partial.

- [x] AC-24 — chain_data immutable post-freeze: 4-step verification (JSON.stringify deep-equality + reference identity option + mutation blocking + instance distinctness) — **DONE** (`freeze_contract_test.gd`; step 1 timestamp-stripped deterministic compare)
- [ ] AC-25 — Submit confirmation dialog (KrDialog) blocks freeze pending. Default focus = [취소] (Pillar 3 commit anchor — cycle 3 Decision 2). Esc/취소 → ACTIVE retained; 제출 → FROZEN transition — **DEFERRED → story-007b** (KrDialog = UI Foundation epic)
- [x] AC-26 — `workspace_state_changed(ACTIVE, FROZEN)` signal emits exactly once on submit; subscribers (SaveLoadService, BriefEditor IMPORTING auto-trigger) receive — **DONE (emit exactly-once)** (`freeze_contract_test.gd`); subscriber receipt (SaveLoadService/BriefEditor) deferred to integration story-007b
- [ ] AC-27 — BriefEditor INACTIVE→IMPORTING auto-transition completes within 150ms of FROZEN signal per ADR-0001 amend-2 + TR-brief-001 — **DEFERRED → story-007b** (BriefEditor epic dependency)
- [x] AC-27b — Crash recovery preserved snapshot bytes-equality: auto-resubmit uses chain_data byte-identical to pre-crash snapshot (JSON.stringify equality verify mirror AC-24 protocol) — **DONE** (`freeze_recovery_test.gd::test_auto_resubmit_snapshot_byte_equality`)
- [ ] AC-27c — Esc from submit-confirm cancels (no state change, tree re-editable) — Pillar 3 cancel branch KB-only verified — **DEFERRED → story-007b** (KrDialog manual)
- [ ] AC-27d — Confirmation dialog opens via Ctrl+Enter KB shortcut; close (Esc or 취소 button) returns focus to last-focused node before dialog opened — **DEFERRED → story-007b** (KrDialog manual)

---

## Implementation Notes

Per ADR-0008 §1 + ADR-0007 + ADR-0001 amend-2:

```gdscript
# WorkspaceData
signal workspace_state_changed(old: int, new: int)
signal submission_rejected(reason: String)
var chain_data_snapshot: Dictionary = {}   # populated at freeze

func request_submit() -> void:
    if state != WorkspaceState.ACTIVE:
        push_error("submit requires ACTIVE state")
        return
    _show_submit_confirmation_dialog()   # KrDialog popup_exclusive

func _on_submit_confirmed() -> void:
    chain_data_snapshot = build_chain_data()        # story 002 — returns new Dict
    if not validate_chain_data(chain_data_snapshot):   # allow-list validator
        return                                       # submission_rejected already emitted
    _transition_to_frozen()
    # SaveLoadService (signal subscriber per ADR-0011) auto-persists
    # BriefEditor (signal subscriber per ADR-0001 amend-2) auto-transitions to IMPORTING
    EvaluationService.submit(chain_data_snapshot)

func _transition_to_frozen() -> void:
    var old := state
    state = WorkspaceState.FROZEN
    workspace_state_changed.emit(old, state)   # typed emit per amend-1 §A5
```

- AC-24 verification: 4-step protocol with `JSON.stringify(snapshot, "", true)` and `JSON.stringify(submitted.chain_data, "", true)` (sort_keys=true; empty-string indent) — per GDD §10.4 cycle 3 indent collision risk closure
- AC-25 KrDialog: `popup_exclusive=true` per ADR-0008 amend-2 §D2; default focus = [취소] button (NOT [제출]) — cycle 3 Decision 2 Pillar 3 commit anchor
- AC-27b: Crash recovery cascade — SaveLoadService loads persisted WorkspaceData.tres → `chain_data_snapshot` field intact → auto-resubmit uses snapshot directly (no rebuild). bytes-equality verifies snapshot integrity round-trip.
- ADR-0008 amend-3 §E2 typed `.emit()` cascade — `EvaluationService.evaluation_completed.emit(...)` etc.
- **Performance budget**: signal cascade is debounce-free direct emit (synchronous subscriber dispatch, no per-frame polling); KrDialog `popup_exclusive` opens via native window <50ms; no frame budget impact — this is a non-gameplay UI transition, not a 60fps hot path. AC-27 BriefEditor handoff ≤150ms is the only timed contract.

---

## Out of Scope

- Story 001: state machine (this story implements ACTIVE→FROZEN transition specifically; story 001 defines the transition function skeleton)
- Story 002: chain_data construction (this story calls `build_chain_data()`)
- Story 008: READ_ONLY transition + ReadOnlyIndicator + crash recovery scene loading (this story only handles freeze-time persistence trigger, not READ_ONLY state)
- Story 010: KrDialog AccessKit role (this story applies; cross-cutting audit is story 010)
- BriefEditor IMPORTING internals (story is in Brief Editor epic, not this epic)

---

## QA Test Cases

- **AC-24 Logic**: Build chain_data, freeze, attempt `workspace_data.add_node(...)` → blocked + `submission_rejected("schema_violation")` emitted; 4-step JSON.stringify protocol passes
- **AC-25 Manual**: Click Submit button → dialog opens, default focus on [취소]; press Esc → dialog closes + state ACTIVE
- **AC-26 Logic**: Connect test listener to `workspace_state_changed`; complete submit → exactly one emit with (ACTIVE, FROZEN)
- **AC-27 Integration**: Workspace freeze → measure time until BriefEditor.state == IMPORTING; assert ≤150ms
- **AC-27b Logic**: Save WorkspaceData (with chain_data_snapshot populated) → load → JSON.stringify of loaded `chain_data_snapshot` == JSON.stringify of original snapshot
- **AC-27c Manual**: Submit confirmation dialog open → Esc → state remains ACTIVE, tree editable
- **AC-27d Manual**: Focus on node A → Ctrl+Enter → dialog opens; Esc → dialog closes + focus returns to node A

Edge cases: submit with INACTIVE state (rejected), submit with empty tree (empty chain_data — schema_version=1 with nodes=[]), schema_violation injection (story 002 fuzz test cross-link).

---

## Test Evidence

**Story Type**: Integration
**Required**:
- `tests/unit/workspace/freeze_contract_test.gd` — AC-24, AC-26 (gdunit4)
- `tests/integration/workspace/freeze_submit_test.gd` — AC-27 BriefEditor handoff (gdunit4)
- `tests/unit/workspace/freeze_recovery_test.gd::test_auto_resubmit_snapshot_byte_equality` — AC-27b
- `production/qa/evidence/workspace-submit-confirmation-dialog.md` — AC-25, AC-27c, AC-27d manual

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (state machine), Story 002 (chain_data builder + validator), Story 009 (UIService for KrDialog if it uses Theme/announce)
- Unlocks: Story 008 (READ_ONLY + crash recovery cascade extends freeze persistence), Story 010 (KrDialog AccessKit role audit), Story 012 (Pillar compliance verification)

---

## Completion Notes
**Completed**: 2026-05-23 (data-layer scope)
**Criteria**: 3/3 in-scope passing (AC-24, AC-26 emit-side, AC-27b). Deferred → story-007b: AC-25, AC-27, AC-27c, AC-27d (KrDialog submit dialog + BriefEditor IMPORTING handoff — both UI Foundation epic dependent).
**Scope split rationale**: KrDialog belongs to UI Foundation epic (design-phase); ADR-0007 `PlayerSubmission` (submit handoff) requires `player_disposition` + `player_citations` captured by the deferred Brief Editor dialog. Mirrors story-003 data-layer/UI split precedent.
**Files**:
- `src/data/workspace_data.gd` — `submit() -> bool` (build_chain_data → validate → snapshot 할당 → `_transition_to_frozen`); `_transition_to_frozen()` placeholder 갱신. EvaluationService.submit() handoff = forward-claim comment (no stub created by design).
- `tests/unit/workspace/freeze_contract_test.gd` (10 tests — AC-24/26 + state-guard branches + empty-tree edge case)
- `tests/unit/workspace/freeze_recovery_test.gd` (1 test — AC-27b)
**Test Evidence**: workspace suite 98/98 PASS, 0 flaky, exit 0 (independently re-run). Integration test (`tests/integration/workspace/freeze_submit_test.gd` AC-27) + manual evidence (`production/qa/evidence/workspace-submit-confirmation-dialog.md` AC-25/27c/27d) = deferred to story-007b.
**Code Review**: Complete (godot-gdscript-specialist + qa-tester, 2026-05-23). Initial CHANGES REQUIRED → all closed: line-177 flaky time-dependent assertion fixed (timestamp-stripped compare), + Gap B/D/E/F coverage added. Final APPROVED.
**Deviations (ADVISORY, logged as tech debt)**:
1. ADR-0007 `submit(PlayerSubmission)` vs control-manifest `submit(chain_data: Dictionary)` signature conflict — must reconcile before story #9 (submission-evaluation).
2. `ALLOWED_NODE_FIELDS` / `_roots()` / `_children_of()` untyped `Array` (story 002/003a pre-existing static-typing debt).
