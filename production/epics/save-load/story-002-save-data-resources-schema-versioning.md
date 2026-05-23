# Story 002: Save-data Resource classes + schema versioning + migration fallback

> **Epic**: Save/Load
> **Status**: Complete (2026-05-23)
> **Layer**: Core / Foundation
> **Type**: Logic
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 3-4h (M)
> **Performance**: No runtime cost — Resource definitions + load-time version check

## Context

**GDD**: `design/gdd/save-load.md` (§3.1 Core Rules — 6-Resource tree, §10.4 AC-10/11 schema migration, EC-8/12)
**Requirement**: `TR-save-*` (Resource serialization + schema versioning — read fresh from `tr-registry.yaml`)

**ADR Governing Implementation**: ADR-0011
**ADR Decision Summary**: 6-Resource typed tree — `ActiveCaseSaveData` (wraps WorkspaceData + BriefEditorData), `Casebook` + `CasebookEntry`, `CareerData` (MVP placeholder) + session-meta `.cfg`. Each save Resource carries `save_file_version: int`. Missing-field load → Godot `@export` default fallback. Future version (> current) → corruption cascade.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Godot `@export` fields default-fill on load when absent (AC-10 relies on this — verified pattern, ADR-0001 amend-2 nested-resource deser PASSED 2026-05-13). 4.5 `Resource.duplicate()` deprecation context — do NOT rely on deep `Resource.duplicate()`; chain_data is Dictionary (`.duplicate(true)` safe). `class_name` for each Resource.

**Control Manifest Rules (Core/Foundation)**:
- Required: every save Resource declares `@export var save_file_version: int = 1`; typed `@export` fields only
- Forbidden: storing Object/Resource refs where primitives suffice in chain_data (ADR-0007 amend-1)
- Guardrail: load-time version check before deserialization use

---

## Acceptance Criteria

- [x] AC-10 (Logic) — save Resource missing a field → field takes its `@export` default (EC-8) — **DONE** (`test_loading_resource_with_missing_field_uses_export_default` — strips a field line from a real `.tres`, reloads, asserts default)
- [x] AC-11 (Logic) — `save_file_version` > current → treated as unsupported/corruption (EC-12) — **DONE** (`test_future_save_version_is_unsupported` + `test_loaded_future_version_resource_reports_its_version` via `_is_save_version_supported`)

---

## Implementation Notes

Per ADR-0011 §Decision (Resource tree):

```gdscript
# src/data/active_case_save_data.gd
class_name ActiveCaseSaveData extends Resource
@export var save_file_version: int = 1
@export var case_id: String = ""
@export var workspace_data: WorkspaceData            # story-001/002/007 — exists
@export var brief_editor_data: Resource              # BriefEditorData (Brief epic) — typed loosely until that class lands
# src/data/casebook.gd
class_name Casebook extends Resource
@export var save_file_version: int = 1
@export var entries: Array[CasebookEntry] = []
# src/data/casebook_entry.gd
class_name CasebookEntry extends Resource
@export var save_file_version: int = 1
@export var case_id: String
@export var verdict: String
@export var final_score: float
# src/data/career_data.gd  (MVP placeholder)
class_name CareerData extends Resource
@export var save_file_version: int = 1
@export var completed_case_ids: Array[String] = []
@export var reputation: float = 0.0
```

- `const CURRENT_SAVE_VERSION := 1` on SaveLoadService. Version check helper: `if loaded.save_file_version > CURRENT_SAVE_VERSION: push_error + corruption cascade`.
- AC-10 missing-field default is automatic via Godot `@export` defaults — the test writes a Resource with fewer fields (or an older serialized form) and confirms load fills the default.
- `BriefEditorData` exact class is owned by the Brief Editor epic (ADR-0001 amend-2) — type the field as `Resource` (or forward-declare) until that class exists; do NOT block this story on it.

---

## Out of Scope

- Story 001: atomic write wrapper (this story defines the Resources it serializes)
- Story 003/004: when/how these are saved/loaded (this story = class definitions + version semantics only)
- Full BriefEditorData class definition (Brief Editor epic)
- CareerData full behaviour (#11 Career epic — MVP placeholder only here)

---

## QA Test Cases

- **AC-10**: Given a serialized ActiveCaseSaveData missing a field that exists in the current class, When `ResourceLoader.load`, Then load succeeds and the missing field equals its `@export` default. Edge: empty/minimal Resource → all defaults.
- **AC-11**: Given a save Resource with `save_file_version` = CURRENT+1, When the version check runs, Then `push_error` fires and the loader treats it as corruption (returns null / triggers recovery), NOT a silent load. Edge: version == CURRENT → loads normally; version < CURRENT → migration path (forward-compat default fill).

---

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/save_load/save_data_schema_test.gd` (gdunit4) — AC-10, AC-11.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (uses `_save_resource_atomic`/load for round-trip tests) — soft; class defs can precede
- Unlocks: Stories 003/004/005/006 (all serialize these Resources)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: 2/2 passing (AC-10, AC-11).
**Files**:
- `src/data/casebook_entry.gd`, `src/data/casebook.gd`, `src/data/career_data.gd`, `src/data/active_case_save_data.gd` — 4 save Resource classes, each with `@export var save_file_version: int = 1`.
- `src/services/save_load_service.gd` — added `_is_save_version_supported(version) -> bool` (>=1 and <= CURRENT) version gate.
- `tests/unit/save_load/save_data_schema_test.gd` — 4 tests.
**Test Evidence**: save_data_schema 4/4 PASS; full unit+integration **365 cases / 348 executed / 17 skipped / 0 failures, exit 0**.
**Notes**:
- AC-10 tested robustly by serializing a real CasebookEntry, stripping the `final_score` line from the `.tres` text, reloading → field returns to its `@export` default (genuine forward-compat / missing-field behavior, not a hand-crafted fixture).
- AC-11: future version detected via `_is_save_version_supported`; the full corruption→`.backup` recovery cascade is story-004 (this story owns the version semantics + predicate).
- `BriefEditorData` class doesn't exist yet (Brief epic) → `ActiveCaseSaveData.brief_editor_data` typed as `Resource` until it lands.
- Test type annotations use base `Resource` (not the `class_name` globals) — `class_name` globals don't resolve in headless gdunit4 runs; instances created via preloaded Script consts (same pattern as ui_service_test).
**Code Review**: Implemented + reviewed directly by orchestrator. Resource serialization + `@export` default behavior verified against ADR-0001 amend-2 nested-resource deser (PASSED 2026-05-13).
