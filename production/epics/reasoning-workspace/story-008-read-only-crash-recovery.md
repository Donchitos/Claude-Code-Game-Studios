# Story 008: READ_ONLY state + ReadOnlyIndicator + crash recovery cascade

> **Epic**: Reasoning Workspace
> **Status**: Ready
> **Layer**: Feature (Gameplay)
> **Type**: Integration
> **Manifest Version**: 2026-05-18

## Context

**GDD**: `design/gdd/reasoning-workspace.md` (§3.2 READ_ONLY transition, §5.4 Lifecycle, §10.4 AC-27, §10.6 Persistence)
**Requirement**: `TR-WORKSPACE-LAYOUT-001`

**ADR Governing Implementation**: ADR-0008 §1 (READ_ONLY state) + ADR-0011 (Save/Load atomic write + crash recovery cascade: `active_case_recovered` signal) + ADR-0008 amend-1 §A6 (chain_data_include_ephemeral_field forbidden)
**ADR Decision Summary**: READ_ONLY state activates on EvaluationResult arrival; tree visible + ReadOnlyIndicator banner shown; no mutations allowed. Crash recovery: SaveLoadService boot detects FROZEN snapshot in active_case.tres → auto-resubmits chain_data (bytes-equal per AC-27b) → on success transitions WorkspaceData to READ_ONLY.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: ReadOnlyIndicator = KrBanner subclass (ROLE_STATIC_TEXT per amend-1 §G1; live-region announce via UIService.announce_text per amend-1 §G3). SaveLoadService crash recovery cascade per ADR-0011 §3.

**Control Manifest Rules**: see `docs/architecture/control-manifest.md` v2026-05-18 — Feature Layer Required/Forbidden/Guardrails apply to this story

---

## Acceptance Criteria

Scope: §10.4 partial (AC-27 family crash recovery) + §10.6 Persistence.

- [ ] AC-19 (extends story 001) — `_transition_to_read_only()` triggered by `EvaluationService.evaluation_completed` signal arrival; tree visible, all mutations blocked
- [ ] AC-39 — ReadOnlyIndicator banner displays "평가 완료 — 읽기 전용" + verdict summary; KrBanner subclass with priority=POLITE announce via UIService.announce_text
- [ ] AC-40b — In READ_ONLY, attempted mutation (add node, drop evidence, edit memo) → silent reject + announce "읽기 전용 상태에서 변경할 수 없습니다" (POLITE)
- [ ] AC-27 (extends story 007) — Crash recovery: boot with active_case.tres containing FROZEN snapshot → SaveLoadService detects → emits `active_case_recovered(case_id, snapshot)` → auto-resubmit cascade fires (verified via AC-27b bytes-equality)
- [ ] AC-27e — Crash recovery cascade completes → WorkspaceData.state == READ_ONLY (or FROZEN if EvaluationResult still in flight) within 500ms of boot
- [ ] AC-27f — Crash recovery on schema_version mismatch → `submission_rejected("schema_version_mismatch")` + CriticalBanner via UIService.announce_text(priority=ASSERTIVE) + WorkspaceData reset to INACTIVE (case 재시작 권장 path)

---

## Implementation Notes

Per ADR-0008 §1 + ADR-0011 §3:

```gdscript
# WorkspaceData
func _transition_to_read_only() -> void:
    var old := state
    state = WorkspaceState.READ_ONLY
    workspace_state_changed.emit(old, state)
    _show_read_only_indicator()

# All mutation entry points
func add_node(...) -> bool:
    if state == WorkspaceState.READ_ONLY:
        UIService.announce_text(self, "읽기 전용 상태에서 변경할 수 없습니다", UIService.AnnouncePriority.POLITE)
        return false
    # ... rest of add logic

# ReadOnlyIndicator KrBanner subclass
class_name ReadOnlyIndicator extends PanelContainer
func _ready() -> void:
    theme_type_variation = &"ReadOnlyBanner"
    accessibility_role = AccessibilityRole.ROLE_STATIC_TEXT   # =4 per amend-1 §G1
    super._ready()
    UIService.announce_text(self, text, UIService.AnnouncePriority.POLITE)

# Boot path — SaveLoadService active_case_recovered signal subscriber
# (registered in workspace bootstrap autoload or scene tree root)
func _on_active_case_recovered(case_id: String, snapshot: Dictionary) -> void:
    workspace_data = SaveLoadService.load_workspace(case_id)
    if workspace_data.state == WorkspaceState.FROZEN:
        # Auto-resubmit cascade — AC-27b bytes-equal verified
        EvaluationService.submit(workspace_data.chain_data_snapshot)
```

- ADR-0011 §3 — `active_case_recovered` signal is single entry point for both Workspace FROZEN auto-resubmit + Brief SUBMITTING auto-resubmit cascades
- AC-27f schema mismatch → ASSERTIVE announce (per amend-1 §G3 priority enum) + UIService.announce_text crash recovery path mirror ADR-0009 §G3 settings recovery
- KrBanner family per amend-1 §G2 R9 — live-region absence mitigated by UIService.announce_text gateway
- ReadOnlyIndicator z-order: above tree canvas, below confirmation dialogs (per ADR-0008 §5 floating badge guidance)

---

## Out of Scope

- Story 001: state machine baseline (this story extends with READ_ONLY-specific mutation guards)
- Story 002: chain_data construction (this story uses persisted snapshot, doesn't rebuild)
- Story 007: freeze + submit happy path (this story extends crash recovery branch)
- Story 010: AccessKit role assignment (this story applies ROLE_STATIC_TEXT for ReadOnlyIndicator; cross-cutting audit is story 010)
- Story 011: Visual polish for ReadOnlyIndicator pulse (this story sets visibility + announce only)
- BriefEditor crash recovery (Brief Editor epic — though `active_case_recovered` signal is shared)

---

## QA Test Cases

- **AC-19 Logic**: Transition WorkspaceData ACTIVE→FROZEN; fire `EvaluationService.evaluation_completed` signal manually → `_transition_to_read_only()` fires + state == READ_ONLY
- **AC-39 Manual**: Trigger READ_ONLY entry → ReadOnlyIndicator banner appears + screen reader announces verdict (verify with VoiceOver / NVDA / Orca)
- **AC-40b Logic**: In READ_ONLY, attempt `add_node` / drop evidence / edit memo → all return false + announce called
- **AC-27 Integration**: Persist WorkspaceData with state=FROZEN + chain_data_snapshot; restart scene; verify auto-resubmit fires
- **AC-27e Manual**: Crash + reboot scenario; measure time from boot to state == READ_ONLY (or FROZEN if EvaluationResult mock-delayed) → ≤500ms
- **AC-27f Logic**: Persist WorkspaceData with chain_data_snapshot.schema_version=2 (mismatch); load → submission_rejected emitted + CriticalBanner + state reset to INACTIVE

Edge cases: active_case.tres present but workspace_data corrupt (per ADR-0011 .backup recovery cascade), READ_ONLY state with no chain_data_snapshot (impossible per AC-23 but defensive check), evaluation_completed signal arrives before FROZEN transition (race — should latch waiting for FROZEN).

---

## Test Evidence

**Story Type**: Integration
**Required**:
- `tests/integration/workspace/read_only_state_test.gd` — AC-19, AC-40b (gdunit4)
- `tests/integration/workspace/crash_recovery_test.gd` — AC-27, AC-27e, AC-27f
- `production/qa/evidence/workspace-read-only-banner.md` — AC-39 manual screen reader walkthrough

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (state machine), Story 002 (chain_data persisted snapshot), Story 007 (freeze cascade)
- Unlocks: Story 010 (ReadOnlyIndicator AccessKit + announce role audit), Story 012 (lifecycle edge cases extend)
