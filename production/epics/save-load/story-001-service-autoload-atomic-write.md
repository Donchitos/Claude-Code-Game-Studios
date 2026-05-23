# Story 001: SaveLoadService autoload + saves/ bootstrap + atomic write wrapper

> **Epic**: Save/Load
> **Status**: Complete (2026-05-23)
> **Layer**: Core / Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 3-4h (M)
> **Performance**: atomic write < 100ms typical (40KB case); no per-frame cost (signal-triggered)

## Context

**GDD**: `design/gdd/save-load.md` (§3.1 Core Rules, §10.1 AC-1, §10.3 AC-8/9, §4.4 atomic write time, EC-1/4/9/11)
**Requirement**: `TR-save-001` … (directory bootstrap + atomic write — read fresh from `tr-registry.yaml`)

**ADR Governing Implementation**: ADR-0011 (Save/Load Storage Format)
**ADR Decision Summary**: `SaveLoadService` autoload SIXTH; `user://saves/` directory; atomic write = `ResourceSaver.save(<tmp>)` → `DirAccess.rename_absolute(<tmp>, <target>)`. tmp-write failure → `push_error` + return false + target untouched.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `ResourceSaver.save()` is NOT guaranteed single-atomic (VR-SL2) → MUST use `.tmp`→rename wrapper. `DirAccess.rename_absolute` atomic on POSIX (Windows NTFS OS-dependent — advisory). `DirAccess.make_dir_recursive_absolute` for bootstrap. `FileAccess`/`DirAccess` return Error codes in 4.x — check them.

**Control Manifest Rules (Core/Foundation)**:
- Required: atomic write via tmp→rename wrapper (never raw `ResourceSaver.save` to the live target)
- Forbidden: `save_load_atomic_write_bypass` (writing directly to target without tmp)
- Guardrail: atomic write < 100ms typical; bootstrap in `_ready()` < 50ms

---

## Acceptance Criteria

- [x] AC-1 (Logic) — SaveLoadService autoload `_ready()` with `saves/` absent → directory auto-created, no `push_warning` (EC-1) — **DONE** (`test_ready_creates_saves_dir_when_absent` + idempotency test)
- [x] AC-8 (Logic) — `_save_resource_atomic(res, target)` success → target fully updated, tmp absent, round-trips — **DONE** (`test_save_resource_atomic_writes_target_and_removes_tmp`)
- [x] AC-9 (Logic) — `_save_resource_atomic` tmp-write failure → `push_error` + return false + target unchanged — **DONE** (`test_save_resource_atomic_failure_preserves_existing_target`)

---

## Implementation Notes

Per ADR-0011 §Decision + §Implementation:

```gdscript
# src/services/save_load_service.gd  (autoload SIXTH — class_name SaveLoadServiceClass)
const SAVES_DIR := "user://saves/"

func _ready() -> void:
    if not DirAccess.dir_exists_absolute(SAVES_DIR):
        DirAccess.make_dir_recursive_absolute(SAVES_DIR)   # EC-1 — silent

func _save_resource_atomic(res: Resource, target_path: String) -> bool:
    var tmp_path := target_path + ".tmp"
    var err := ResourceSaver.save(res, tmp_path)
    if err != OK:
        push_error("SaveLoadService: tmp write failed (%d) — target preserved" % err)
        return false                                        # AC-9 — target untouched
    var dir := DirAccess.open(SAVES_DIR)
    var rename_err := dir.rename_absolute(...) # tmp → target (atomic on POSIX)
    if rename_err != OK:
        push_error(...); return false
    return true                                             # AC-8
```

- Autoload registration: add `SaveLoadService="*res://src/services/save_load_service.gd"` SIXTH in `project.godot [autoload]` (after the locked order; intermediate autoloads may not exist yet — fine, ordering is positional intent).
- `class_name SaveLoadServiceClass` (NOT `SaveLoadService`) — avoid the autoload-name-collision error (same pattern as `UIServiceClass`).
- Use absolute path forms for rename; verify `rename_absolute` arg form against engine reference before use.

---

## Out of Scope

- Story 002: the Resource class definitions being saved (this story's tests use a minimal/dummy Resource or an existing one like WorkspaceData)
- Story 003: signal-triggered autosave + debounce (this story exposes `_save_resource_atomic` only)
- Story 004: load path + corruption recovery
- session_meta `.cfg` write (story 004/008)

---

## QA Test Cases

- **AC-1**: Given SaveLoadService autoload, When `_ready()` runs with `user://saves/` absent, Then the dir exists afterward and no warning was pushed. Edge: dir already exists → no error (idempotent).
- **AC-8**: Given a Resource + target path, When `_save_resource_atomic` succeeds, Then `FileAccess.file_exists(target)` true and `<target>.tmp` absent; loading the target round-trips the Resource. 
- **AC-9**: Given a tmp-write failure (inject an unwritable path or mock), When `_save_resource_atomic` runs, Then it returns false and a pre-existing target file is byte-unchanged. Edge: target did not previously exist → still no target created.

---

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/save_load/atomic_write_test.gd` (gdunit4) — AC-1, AC-8, AC-9. Tests write to `user://` temp paths and clean up.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Save/Load foundation entry point)
- Unlocks: Stories 002/003/004 (all SaveLoadService stories build on the atomic write + autoload)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: 3/3 passing (AC-1, AC-8, AC-9) + idempotency.
**Files**:
- `src/services/save_load_service.gd` — `class_name SaveLoadServiceClass extends Node`; `SAVES_DIR`/`CURRENT_SAVE_FILE_VERSION` consts; `_ready()`→`_ensure_saves_dir()`; `_save_resource_atomic(res, target) -> bool`.
- `project.godot` — `SaveLoadService` autoload registered (after CaseService; SIXTH positional intent).
- `tests/integration/save_load/atomic_write_test.gd` — 4 tests.
**Test Evidence**: atomic_write_test 4/4 PASS; full unit+integration suite **361 cases / 344 executed / 17 skipped / 0 failures, exit 0** (new autoload boots in all runs without regression).
**⚠️ ENGINE GOTCHA found + worked around (TD-004)**: `ResourceSaver.save()` picks format by file EXTENSION; a bare `.tmp` suffix → `ERR_FILE_UNRECOGNIZED` (error 15) and the save fails. The reference snippet (`current-best-practices.md` §Atomic Write, `settings.tres.tmp`) is therefore broken. Fixed by inserting `.tmp` BEFORE the extension: `name.tres` → `name.tmp.tres` (recognized). Logged TD-004 to correct the doc.
**Code Review**: Implemented + reviewed directly by orchestrator (foundational Integration story; verified DirAccess/ResourceSaver/rename_absolute against engine-reference; sub-agent delegation skipped this session due to repeated agent message-truncation). Atomic-write pattern matches current-best-practices.md (with the `.tmp` extension correction).
