# Story 006: Crash-recovery auto-resubmit cascade (active_case_recovered)

> **Epic**: Save/Load
> **Status**: Ready
> **Layer**: Core / Feature
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 3h (M)
> **Performance**: recovery cascade completes within boot budget (≤500ms to recovered state — workspace story-008 AC-27e)

## Context

**GDD**: `design/gdd/save-load.md` (§3.1 Core Rules — crash recovery cascade, §10.2 AC-5/6)
**Requirement**: `TR-save-*` (crash recovery auto-resubmit — read fresh from `tr-registry.yaml`)

**ADR Governing Implementation**: ADR-0011 (+ ADR-0001 amend-2 `active_case_recovered` contract)
**ADR Decision Summary**: Both crash-recovery cascades route through one `active_case_recovered(workspace_data, brief_editor_data)` signal (emitted by story 004 boot load). Subscribers: Workspace controller (if `workspace_data.state == FROZEN` → auto `EvaluationService.submit`); Brief controller (if `brief_editor_data.state == SUBMITTING` → auto `EvaluationService.submit(pending_submission)`).

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: This story owns the SaveLoadService SIDE (the single `active_case_recovered` emit — already in story 004) and the **subscriber contract**. The actual subscribers live in the Workspace controller (workspace story-008) and Brief controller (Brief epic) — **neither exists yet**, and both call `EvaluationService.submit()` which is **not implemented** (TD-001). So AC-5/AC-6 end-to-end are DEFERRED; this story locks + tests the recovery-decision contract (which state triggers which resubmit) in isolation.

**Control Manifest Rules (Core/Feature)**:
- Required: single `active_case_recovered` entry point for BOTH cascades; recovery decision keyed on persisted state (FROZEN / SUBMITTING)
- Forbidden: duplicate/parallel recovery paths (two separate recovery signals)
- Guardrail: recovery cascade ≤500ms boot-to-recovered (workspace story-008 AC-27e)

---

## Acceptance Criteria

- [ ] AC-5 (Integration) — Workspace freeze (state=FROZEN) → quit → restart, When `active_case_recovered` emit, Then Workspace controller auto-calls `EvaluationService.submit()` + recovery banner. **DEFERRED end-to-end** (needs Workspace controller + EvaluationService); this story tests the recovery-decision contract: given a recovered `workspace_data.state == FROZEN`, the cascade selects the workspace-resubmit branch.
- [ ] AC-6 (Integration) — Brief Editor SUBMITTING → quit → restart, When `active_case_recovered` emit, Then Brief controller auto-calls `EvaluationService.submit(brief_editor_data.pending_submission)`. **DEFERRED end-to-end**; this story tests: given recovered `brief_editor_data.state == SUBMITTING`, the cascade selects the brief-resubmit branch.
- [ ] Single entry point — both cascades dispatch from one `active_case_recovered` signal (no second recovery signal).

---

## Implementation Notes

Per ADR-0011 §Decision (recovery cascade) + ADR-0001 amend-2 §C3:

```gdscript
# SaveLoadService emits (story 004): active_case_recovered(workspace_data, brief_editor_data)
#
# Recovery-decision contract (this story locks + tests it). A small pure helper
# makes the branch selection unit-testable without the (absent) controllers:
func recovery_branch_for(workspace_data, brief_editor_data) -> String:
    if workspace_data != null and workspace_data.state == WorkspaceData.WorkspaceState.FROZEN:
        return "workspace_resubmit"
    if brief_editor_data != null and brief_editor_data.get("state") == BRIEF_SUBMITTING:
        return "brief_resubmit"
    return "none"
```

- **DEFERRED**: the actual subscribers (Workspace controller `_on_active_case_recovered` → `EvaluationService.submit`; Brief controller → `EvaluationService.submit(pending_submission)`) — both controllers + EvaluationService are unimplemented (TD-001 first). Forward-claim comments where the subscribers will attach.
- This story's testable deliverable: the `recovery_branch_for(...)` pure decision helper + confirmation that story-004 emits exactly one `active_case_recovered`. End-to-end AC-5/6 re-open when Workspace/Brief controllers + EvaluationService land.
- BriefEditorData state enum/`SUBMITTING` is owned by the Brief epic — type loosely until that class exists.

---

## Out of Scope

- Workspace controller `_on_active_case_recovered` (workspace story-008)
- Brief controller `_on_active_case_recovered` (Brief Editor epic)
- EvaluationService.submit (Submission/Evaluation epic; TD-001 reconcile first)
- Recovery banner display (UIService.announce_text — UI Foundation story-005)

---

## QA Test Cases

- **AC-5 (contract)**: Given a recovered `workspace_data` with `state == FROZEN` (and brief null/INACTIVE), When `recovery_branch_for`, Then returns `"workspace_resubmit"`. Edge: workspace ACTIVE (not frozen) → not this branch.
- **AC-6 (contract)**: Given a recovered `brief_editor_data` with `state == SUBMITTING` (workspace not FROZEN), When `recovery_branch_for`, Then returns `"brief_resubmit"`. Edge: both FROZEN + SUBMITTING → workspace branch wins (deterministic priority — document the precedence).
- **Single entry point**: assert story-004 boot emits exactly one `active_case_recovered` (one listener, count == 1).
- Neither / null → `"none"`.

---

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/save_load/crash_recovery_cascade_test.gd` (gdunit4) — recovery-branch contract + single-emit. End-to-end AC-5/6 deferred (note in story when EvaluationService + controllers land).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 (`active_case_recovered` emit)
- Unlocks: workspace story-008 (Workspace-side subscriber), Brief Editor epic (Brief-side subscriber)
