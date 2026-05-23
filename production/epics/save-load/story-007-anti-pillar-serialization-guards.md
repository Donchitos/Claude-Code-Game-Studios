# Story 007: Anti-Pillar serialization guards (settings + ephemeral exclusion)

> **Epic**: Save/Load
> **Status**: Complete (2026-05-23)
> **Layer**: Core / Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 2h (S)
> **Performance**: validation at serialize time only — negligible

## Context

**GDD**: `design/gdd/save-load.md` (§2 Anti-Pillar guards, §3.4 Settings separation, §7.2 forbidden patterns, §10.5 AC-12/13)
**Requirement**: `TR-save-*` (Anti-Pillar serialization guards — read fresh from `tr-registry.yaml`)

**ADR Governing Implementation**: ADR-0011 (+ ADR-0008 amend-1 §A6 ephemeral-field ban, ADR-0009 settings separation)
**ADR Decision Summary**: `active_case.tres` MUST NOT include Settings values (Settings live in a separate `user://user_settings.cfg`, owned by ADR-0009) — `save_load_settings_inclusion`. chain_data MUST NOT include ephemeral fields (`last_touched_usec`, `memo_text`, etc.) — `chain_data_include_ephemeral_field` (already enforced by `WorkspaceData.validate_chain_data`, story-002 workspace).

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure data validation — no post-cutoff API. Reuse the canonical `WorkspaceData.validate_chain_data()` allow-list (do NOT duplicate it). The active_case Resource has no Settings `@export` fields by construction (structural guarantee + a test that asserts the field set).

**Control Manifest Rules (Core/Foundation)**:
- Required: single canonical chain_data allow-list validator (`WorkspaceData.validate_chain_data`); active_case excludes settings by construction
- Forbidden: `save_load_settings_inclusion`, `chain_data_include_ephemeral_field`, `chain_data_schema_allow_list_duplication`
- Guardrail: validate before atomic write

---

## Acceptance Criteria

- [x] AC-12 (Logic) — active_case carries no Settings fields (structural; `save_load_settings_inclusion`) — **DONE** (`test_active_case_save_data_has_no_settings_fields` + property-set shape test)
- [x] AC-13 (Logic) — chain_data with an ephemeral field (`last_touched_usec`) rejected via canonical validator (`chain_data_include_ephemeral_field`) — **DONE** (`test_active_case_with_ephemeral_chain_data_field_rejected`)

---

## Implementation Notes

Per ADR-0011 + ADR-0008 amend-1 §A6:

```gdscript
# Before atomic write of active_case, validate the embedded chain_data via the
# canonical workspace validator (NO duplicate allow-list here):
func _validate_active_case(active: ActiveCaseSaveData) -> bool:
    var cd: Dictionary = active.workspace_data.chain_data_snapshot
    if not active.workspace_data.validate_chain_data(cd):   # emits submission_rejected on violation
        return false                                        # AC-13
    return true
```

- **AC-12** is structural: `ActiveCaseSaveData` (story 002) has NO settings `@export` fields — Settings live in `user_settings.cfg` (ADR-0009). The test asserts the active_case Resource's serialized property set contains no `display.*` / `audio.*` / `input.*` keys.
- **AC-13** reuses `WorkspaceData.validate_chain_data()` (story-002 workspace) — the allow-list already rejects non-allowed node fields (including ephemeral ones like `last_touched_usec`, `memo_text`). Do NOT re-implement the allow-list (`chain_data_schema_allow_list_duplication` forbidden).
- Register/verify `save_load_settings_inclusion` in `architecture.yaml`.

---

## Out of Scope

- The allow-list validator itself (owned by WorkspaceData — story-002 workspace; reuse only)
- Settings serialization (separate system — ADR-0009 / Settings epic)
- Save/load mechanics (stories 001-006)

---

## QA Test Cases

- **AC-12**: Given an `ActiveCaseSaveData` instance, When its serialized property list is inspected, Then no Settings keys (`display.text_scale`, `display.reduced_motion`, `audio.*`, `input.*`) appear. Edge: confirm via the Resource's `get_property_list()` or a round-trip `.tres` text scan — no settings keys present.
- **AC-13**: Given a chain_data with `last_touched_usec` injected into a node dict, When `validate_chain_data` runs (via `_validate_active_case`), Then it returns false + `submission_rejected("schema_violation")` (cross-link workspace AC-10/52). Edge: clean chain_data → passes.

---

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/save_load/anti_pillar_guards_test.gd` (gdunit4) — AC-12, AC-13.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (ActiveCaseSaveData), WorkspaceData.validate_chain_data (workspace story-002 — Complete)
- Unlocks: None (guard layer)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: 2/2 passing (AC-12, AC-13) + null-safety + clean-data positive.
**Files**:
- `src/services/save_load_service.gd` — `_validate_active_case(active) -> bool` delegating to the canonical `WorkspaceData.validate_chain_data` (no allow-list duplication).
- `tests/unit/save_load/anti_pillar_guards_test.gd` — 5 tests.
**Test Evidence**: anti_pillar_guards 5/5 PASS; full unit+integration **381 cases / 364 executed / 17 skipped / 0 failures, exit 0**.
**Notes**:
- AC-12 is structural — `ActiveCaseSaveData` declares no Settings `@export` fields (Settings persist separately, ADR-0009). Test inspects `get_property_list()` for absence of `display.*`/`audio.*`/`input.*`/`accessibility.*` + verifies the declared script-variable set.
- AC-13 reuses the SINGLE canonical `WorkspaceData.validate_chain_data` (workspace story-002, Complete) — `chain_data_schema_allow_list_duplication` avoided. Both forbidden patterns confirmed registered (architecture.yaml lines 1433, 1808).
**Code Review**: Implemented + reviewed directly by orchestrator.
