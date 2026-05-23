# Epic: Save/Load

> **Layer**: Core / Foundation
> **GDD**: design/gdd/save-load.md
> **Architecture Module**: `SaveLoadService` autoload (SIXTH position) + `user://saves/` directory + 6-Resource serialization tree
> **Status**: In Progress
> **Stories**: 8 created 2026-05-23
> **Created**: 2026-05-23

## Overview

Save/Load owns persistence of a 60–120 minute case session plus the casebook and career progression. A single `SaveLoadService` autoload (SIXTH position) is the SSOT that serializes four categories — (1) in-progress case work (`WorkspaceData` chain_data + state, `BriefEditorData` grounds/memo/citations + state), (2) casebook (Resolved case results: verdict + final_score + archive), (3) career progression (`CareerData` — MVP placeholder: completed case IDs + reputation), (4) session meta (last_active_case_id + UI hints) — to `user://saves/` via **atomic write** (`.tres` for Resource categories, `.cfg` for session meta). Autosave is **signal-triggered with 250ms debounce** (never per-frame polling), aligned with Reasoning Workspace §3.1 Rule 8. Crash recovery routes both the **Workspace FROZEN auto-resubmit** and **Brief SUBMITTING auto-resubmit** cascades through a single `active_case_recovered` signal entry point. Settings are explicitly NOT serialized here (separate `user://user_settings.cfg`, owned by Settings #4 / ADR-0009).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| **ADR-0011: Save/Load Storage Format** (Accepted 2026-05-17) | `SaveLoadService` autoload SIXTH; atomic write via `ResourceSaver.save(.tmp)` → `DirAccess.rename_absolute`; `.tres` (3 Resource categories) + `.cfg` (session meta); signal-trigger autosave + 250ms debounce; crash-recovery cascade via single `active_case_recovered` entry point; `NOTIFICATION_WM_CLOSE_REQUEST` forced flush; schema versioning + migration framework; 6 signal subscribe / 7 signal emit | MEDIUM (cross-platform atomic rename POSIX vs Windows `ReplaceFile`; 4.5 `Resource.duplicate()` deprecation context — VR-SL1/SL2/SL3 advisory) |
| ADR-0001 amend-2 (dependency) | `BriefEditorData` lifecycle + `active_case_recovered` interface contract (SaveLoadService = transient boot owner → signal emit → controller runtime owner) | LOW |
| ADR-0007 amend-1 (dependency) | `PlayerSubmission` / chain_data Variant-primitives-only (serialization safety) | LOW |
| ADR-0008 amend-1 (dependency) | `WorkspaceData` serialization (chain_data_snapshot primitives-only — story-007 freeze persistence) | LOW |

## GDD Requirements

22 `TR-save-001` … `TR-save-022` in `docs/architecture/tr-registry.yaml` — **all 22 covered by ADR-0011 (0 untraced)** (systems-index #3: "22 TR-save 전체 covered"). Thematic grouping (individual TR-IDs are pulled per story by `/create-stories`):

| Theme | Coverage |
|-------|----------|
| `user://saves/` directory structure + `make_dir_recursive_absolute` bootstrap (EC-1) | ADR-0011 ✅ |
| Atomic write wrapper (`.tmp` → `rename_absolute`; corruption → `.backup` + `save_corrupted` emit) | ADR-0011 ✅ |
| 6-Resource typed serialization (`ActiveCaseSaveData` / `WorkspaceData` / `BriefEditorData` / `Casebook`+`CasebookEntry` / `CareerData` + session-meta `.cfg`) | ADR-0011 ✅ |
| Signal-trigger autosave + 250ms debounce (no polling) | ADR-0011 ✅ |
| Crash-recovery cascade — Workspace FROZEN + Brief SUBMITTING auto-resubmit via single `active_case_recovered` | ADR-0011 ✅ |
| Casebook eager load (nested `BriefArchiveData` deserialization) + casebook_entry_added | ADR-0011 ✅ |
| Schema versioning + migration framework | ADR-0011 ✅ |
| `NOTIFICATION_WM_CLOSE_REQUEST` forced synchronous flush | ADR-0011 ✅ |
| 6 signal subscribe / 7 signal emit topology | ADR-0011 ✅ |
| Forbidden patterns (e.g. `save_load_revert_resolved`, atomic-write bypass) | ADR-0011 ✅ |

## Engine / Cross-System Notes

- **Engine risk MEDIUM**: VR-SL2 (cross-platform atomic rename) + VR-SL3 (close-request flush time) are advisory — POSIX atomic guaranteed; Windows NTFS depends on OS (ADR-0011 advisory note pending). Stories touching atomic write must follow ADR-0011's `.tmp`→rename wrapper, not raw `ResourceSaver.save`.
- **Autoload ordering**: SaveLoadService is SIXTH. Several upstream signal sources are not yet implemented (EvaluationService THIRD, SettingsService FIFTH; Brief Editor controller). Stories must guard signal subscriptions for absent sources (subscribe-if-present) and wire incrementally as those systems land — mirrors the graceful-degradation pattern already used in UIService/KrControlHelper.
- **Unblocks**: reasoning-workspace story-008 (READ_ONLY + crash recovery cascade) once `active_case_recovered` + atomic persistence exist; Brief Editor epic persistence; #11 Career, #14 Retrospective Replay, #17 Meta-Frame.
- **TD-001 awareness**: the `EvaluationService.submit()` signature conflict (ADR-0007 PlayerSubmission vs control-manifest chain_data:Dictionary) intersects the FROZEN auto-resubmit cascade — reconcile before wiring the evaluation hand-off (see docs/tech-debt-register.md).

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/save-load.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- Atomic-write + crash-recovery cascade have integration tests (round-trip + corruption + recovery)
- Forbidden patterns are registered in `docs/registry/architecture.yaml` and gated by tests

## Stories

| # | Story | Type | Status | ADR | ACs |
|---|-------|------|--------|-----|-----|
| 001 | [SaveLoadService autoload + saves/ bootstrap + atomic write wrapper](story-001-service-autoload-atomic-write.md) | Integration | Complete | ADR-0011 | AC-1/8/9 |
| 002 | [Save-data Resource classes + schema versioning + migration](story-002-save-data-resources-schema-versioning.md) | Logic | Complete | ADR-0011 | AC-10/11 |
| 003 | [Signal-triggered autosave + 250ms debounce](story-003-signal-triggered-autosave-debounce.md) | Integration | Complete | ADR-0011 | AC-2 |
| 004 | [Boot load + corruption→backup recovery + casebook/session-meta](story-004-boot-load-corruption-recovery.md) | Integration | Complete | ADR-0011 | AC-7/15/16 |
| 005 | [Resolution cascade — evaluation→casebook + revert guard](story-005-resolution-cascade-revert-guard.md) | Integration | Complete (core; evaluation_completed subscription deferred — TD-001) | ADR-0011 | AC-3/4 |
| 006 | [Crash-recovery auto-resubmit cascade (active_case_recovered)](story-006-crash-recovery-auto-resubmit.md) | Integration | Complete (decision contract; end-to-end resubmit deferred — controllers + EvaluationService) | ADR-0011 | AC-5/6 |
| 007 | [Anti-Pillar serialization guards](story-007-anti-pillar-serialization-guards.md) | Logic | Complete | ADR-0011 | AC-12/13 |
| 008 | [Close-request forced flush + full-session persistence](story-008-close-request-flush-session-persistence.md) | Integration | Complete | ADR-0011 | AC-14 |

**Implementation order**: 001 (atomic write foundation) → 002 (Resource classes) → 003 (autosave) → 004 (boot load) → 007 (guards) → 005/006 (cross-service cascades — partially deferred on EvaluationService/controllers, TD-001) → 008 (close flush + full round-trip). Stories 005/006 lock + unit-test their decision/guard logic now; end-to-end resubmit re-opens when EvaluationService + Workspace/Brief controllers land.

## Next Step

Run `/story-readiness production/epics/save-load/story-001-service-autoload-atomic-write.md` then `/dev-story` to begin implementation.
