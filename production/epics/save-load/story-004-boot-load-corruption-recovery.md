# Story 004: Boot load + corruption→backup recovery + casebook/session-meta load

> **Epic**: Save/Load
> **Status**: Complete (2026-05-23)
> **Layer**: Core / Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 3-4h (M)
> **Performance**: boot load < 100ms typical; casebook eager load (≤100 entries) within budget

## Context

**GDD**: `design/gdd/save-load.md` (§3.1 Core Rules — load path + Rule 6 corruption recovery, §10.2 AC-7, §10.6 AC-15/16, EC-2/3)
**Requirement**: `TR-save-*` (boot load + corruption recovery + casebook/session-meta — read fresh from `tr-registry.yaml`)

**ADR Governing Implementation**: ADR-0011
**ADR Decision Summary**: `_ready()` boot loads `active_case.tres`, `casebook.tres`, `session_meta.cfg`. Load failure/corruption → rename to `.backup` + `push_error` + emit `save_corrupted` (consumer shows CriticalBanner). Casebook eager-loaded (nested `BriefArchiveData` deserialization). `active_case_recovered` emitted as the single recovery entry point (its subscribers are story 005/006).

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `ResourceLoader.load(path, "", CACHE_MODE_IGNORE)` for fresh deserialization. Corrupt `.tres` → load returns null / error → must be caught (don't assume non-null). `ConfigFile.load()` for session_meta (returns Error). `DirAccess.rename_absolute` for `.backup`. CriticalBanner display needs `UIService.announce_text` (UI Foundation story-005 — NOT yet implemented) → emit the signal; banner display is deferred.

**Control Manifest Rules (Core/Foundation)**:
- Required: catch load errors (null/Error) before use; corruption → `.backup` + `save_corrupted` emit; never overwrite a corrupt file in place
- Forbidden: assuming `ResourceLoader.load` succeeds without a null/error check
- Guardrail: boot load < 100ms typical

---

## Acceptance Criteria

- [x] AC-7 (Logic) — corrupt `active_case.tres` → `.backup` + `save_corrupted("active_case")` emit + load returns null (EC-3) — **DONE** (`test_corrupt_active_case_renamed_to_backup_and_signals`; CriticalBanner display deferred to UI announce_text)
- [x] AC-15 (Integration) — 5-entry casebook → `_load_casebook()` returns 5 entries — **DONE** (`test_casebook_loads_five_entries`)
- [x] AC-16 (Integration) — `session_meta.cfg` read back → `last_active_case_id` + `workspace_f2_hint_seen` exposed — **DONE** (`test_session_meta_values_read_back`)

---

## Implementation Notes

Per ADR-0011 §Decision (boot load path):

```gdscript
func _ready() -> void:
    # ... story 001 bootstrap + story 003 timer/subscriptions ...
    _load_casebook()                       # eager
    _load_session_meta()                   # ConfigFile
    var active := _load_active_case_or_recover()
    await get_tree().process_frame         # ADR-0001 amend-2 §C3 — let subscribers' _ready run
    if active != null:
        active_case_recovered.emit(active.workspace_data, active.brief_editor_data)

func _load_active_case_or_recover() -> ActiveCaseSaveData:
    if not FileAccess.file_exists(ACTIVE_CASE_FILE): return null   # EC-2 — fresh start
    var res := ResourceLoader.load(ACTIVE_CASE_FILE, "", ResourceLoader.CACHE_MODE_IGNORE)
    if res == null or not (res is ActiveCaseSaveData) or res.save_file_version > CURRENT_SAVE_VERSION:
        _rename_to_backup(ACTIVE_CASE_FILE)        # → .backup
        save_corrupted.emit("active_case")          # consumer shows CriticalBanner (deferred UI)
        return null
    return res
```

- AC-7 banner: emit `save_corrupted` only; the CriticalBanner display goes through `UIService.announce_text` which is NOT yet implemented (UI Foundation story-005) → display is DEFERRED. Test the signal emit + `.backup` creation.
- AC-15 casebook eager load: `_load_casebook()` loads `casebook.tres` (or empty Casebook if absent — EC-2). Nested entry deserialization verified.
- AC-16 session_meta: `ConfigFile.load(session_meta.cfg)`; expose `last_active_case_id` / `workspace_f2_hint_seen` via getters. Consumers (Browser, Workspace toast) deferred.
- `active_case_recovered` is emitted here but its SUBSCRIBERS (auto-resubmit) are story 005/006.

---

## Out of Scope

- Story 005/006: `active_case_recovered` subscribers (auto-resubmit cascades)
- CriticalBanner visual display (UI Foundation story-005 `announce_text` — emit signal only here)
- Browser auto-entry + F2 toast suppression (consumer systems — this story only persists/exposes session_meta)
- Story 003: the save path (this story = load path)

---

## QA Test Cases

- **AC-7**: Given a deliberately-corrupted `active_case.tres` (garbage bytes), When boot load runs, Then `<file>.backup` exists, the load returns null, and `save_corrupted("active_case")` was emitted (connect a listener). Edge: file absent → no backup, no emit, fresh start (EC-2).
- **AC-15**: Given a `casebook.tres` written with 5 CasebookEntry, When `_load_casebook`, Then `Casebook.entries.size() == 5` and a sampled entry's `case_id`/`verdict`/`final_score` match. Edge: casebook absent → empty Casebook, no error.
- **AC-16**: Given a `session_meta.cfg` with the two keys, When `_load_session_meta`, Then the getters return `"case:2026-001"` and `true`. Edge: cfg absent → defaults (empty id, false).

---

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/save_load/boot_load_recovery_test.gd` (gdunit4) — AC-7, AC-15, AC-16. Write fixtures to `user://` temp, clean up.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (atomic write/dir), Story 002 (Resource classes + version check)
- Unlocks: Story 005 + 006 (consume `active_case_recovered`)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: 3/3 passing (AC-7, AC-15, AC-16) + absent-file edge cases.
**Files**:
- `src/services/save_load_service.gd` — `save_corrupted` + `active_case_recovered` signals; `CASEBOOK_FILE`/`SESSION_META_FILE` consts; `_casebook` + `last_active_case_id` + `workspace_f2_hint_seen` fields; `_boot_load()` (called from `_ready` via await); `_load_active_case_or_recover()`, `_load_casebook()`, `_load_session_meta()`, `_rename_to_backup()`.
- `tests/integration/save_load/boot_load_recovery_test.gd` — 6 tests.
**Test Evidence**: boot_load_recovery 6/6 PASS; full unit+integration **376 cases / 359 executed / 17 skipped / 0 failures, exit 0** (autoload `_boot_load` runs in every test boot without regression — absent files → safe no-op).
**Notes**:
- Corruption detection covers load failure / wrong type / unsupported `save_file_version` (reuses story-002 `_is_save_version_supported`). Corrupt file → `.backup` (preserved for diagnostics, not overwritten).
- CriticalBanner display for AC-7 is DEFERRED — needs `UIService.announce_text` (UI Foundation story-005, not yet implemented). This story emits `save_corrupted`; the banner is the consumer's job.
- `active_case_recovered` is emitted here (single recovery entry point); its auto-resubmit SUBSCRIBERS are story 006 (deferred — controllers + EvaluationService).
- `_boot_load` emit is deferred one frame (`await get_tree().process_frame`) per ADR-0001 amend-2 §C3.
**Code Review**: Implemented + reviewed directly by orchestrator. ConfigFile/ResourceLoader/DirAccess.rename verified against engine-reference + ADR-0011 boot-load diagram.
