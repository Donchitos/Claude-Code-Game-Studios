# Story 005: Resolution cascade — evaluation_completed → casebook + revert guard

> **Epic**: Save/Load
> **Status**: Ready
> **Layer**: Core / Feature
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 3h (M)
> **Performance**: casebook write immediate (0ms debounce); active_case delete atomic

## Context

**GDD**: `design/gdd/save-load.md` (§3.1 Core Rules — Rule 4 resolution cascade + Rule 4.3 revert guard, §3.3 signals, §10.1 AC-3/4, §10.5, EC-5)
**Requirement**: `TR-save-*` (resolution cascade + Anti-Pillar revert guard — read fresh from `tr-registry.yaml`)

**ADR Governing Implementation**: ADR-0011 (+ ADR-0007 evaluation contract — see TD-001)
**ADR Decision Summary**: On `evaluation_completed`, append a `CasebookEntry`, write `casebook.tres` immediately (0ms), delete `active_case.tres`, emit `casebook_entry_added`. `save_active_case()` when the case_id already exists in the Casebook → `push_error` + return false + no write (Anti-Pillar `save_load_revert_resolved`, Pillar 1 irreversibility).

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `evaluation_completed(result: EvaluationResult)` is emitted by EvaluationService — **NOT yet implemented** (TD-001: ADR-0007 `submit(PlayerSubmission)` vs control-manifest `submit(chain_data)` signature conflict unresolved). AC-3's trigger is therefore deferred; the casebook-append + revert-guard LOGIC is implementable and unit-testable by invoking the cascade handler directly. `DirAccess.remove_absolute` for active_case deletion.

**Control Manifest Rules (Core/Feature)**:
- Required: resolution writes casebook immediately (0ms, not debounced); revert guard on `save_active_case`
- Forbidden: `save_load_revert_resolved` (re-saving an active_case whose case_id is already Resolved/in Casebook)
- Guardrail: casebook write + active_case delete are sequenced (write casebook BEFORE deleting active_case)

---

## Acceptance Criteria

- [ ] AC-3 (Logic) — `evaluation_completed` received, When Rule 4 cascade, Then `Casebook.entries.append` + `casebook.tres` immediate serialize + `active_case.tres` deleted + `casebook_entry_added` emitted. Test: `test_save_load_service_evaluation_completed_cascade`.
- [ ] AC-4 (Logic) — `save_active_case()` with case_id already in Casebook, When Rule 4.3 guard, Then `push_error` + return false + `active_case.tres` unchanged (EC-5). Test: `test_save_load_service_revert_resolved_blocked`.

---

## Implementation Notes

Per ADR-0011 §Decision (resolution cascade):

```gdscript
func _on_evaluation_completed(result) -> void:   # subscribed if EvaluationService present
    var entry := CasebookEntry.new()
    entry.case_id = result.case_id
    entry.verdict = result.verdict
    entry.final_score = result.final_score
    _casebook.entries.append(entry)
    _save_resource_atomic(_casebook, CASEBOOK_FILE)        # immediate (0ms)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ACTIVE_CASE_FILE))
    casebook_entry_added.emit(entry)

func save_active_case() -> bool:
    if _casebook_has(_active_case.case_id):
        push_error("save_load_revert_resolved: case '%s' is Resolved" % _active_case.case_id)
        return false                                        # AC-4 (EC-5)
    return _save_resource_atomic(_active_case, ACTIVE_CASE_FILE)
```

- **DEFERRED**: the `evaluation_completed` SUBSCRIPTION (EvaluationService doesn't exist; TD-001 must reconcile the submit signature first). Implement `_on_evaluation_completed` as a directly-callable handler + guard the `.connect` with presence; test the handler directly. Forward-claim comment at the connect site.
- Register forbidden_pattern `save_load_revert_resolved` in `architecture.yaml` if not already present (verify first).

---

## Out of Scope

- EvaluationService implementation + the real `evaluation_completed` wiring (Submission/Evaluation epic; TD-001 reconcile first)
- Story 006: crash-recovery auto-resubmit (different cascade)
- Casebook trim policy at >100 entries (EC-13 — v1+)

---

## QA Test Cases

- **AC-3**: Given a SaveLoadService with an active_case + empty casebook, When `_on_evaluation_completed(result)` is invoked directly with a mock result, Then casebook has 1 entry with matching fields, `casebook.tres` exists, `active_case.tres` is deleted, and `casebook_entry_added` fired (listener). Edge: write casebook BEFORE delete (if delete fails, casebook still has the entry).
- **AC-4**: Given a casebook already containing `case:X`, When `save_active_case()` is called with `_active_case.case_id == "case:X"`, Then it returns false, `push_error` fired, and `active_case.tres` is byte-unchanged. Edge: case_id NOT in casebook → save proceeds normally.

---

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/save_load/resolution_cascade_test.gd` (gdunit4) — AC-3 (handler-direct), AC-4.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (atomic write), Story 002 (Casebook/CasebookEntry), Story 004 (casebook loaded)
- Unlocks: #11 Career, #14 Retrospective Replay (consume casebook entries)
