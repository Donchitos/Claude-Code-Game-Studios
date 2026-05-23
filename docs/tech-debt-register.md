# Tech Debt Register

Tracked technical debt across the codebase. Each entry: ID, date logged, severity,
description, origin, and recommended repayment trigger. Maintained via `/tech-debt`.

| Severity | Meaning |
|----------|---------|
| HIGH | Will block or break a near-term story if unaddressed |
| MEDIUM | Causes drift/risk; address within the milestone |
| LOW | Cosmetic / standards hygiene; address opportunistically |

---

## Open

### TD-001 — EvaluationService.submit() signature conflict (ADR-0007 vs control-manifest)
- **Logged**: 2026-05-23
- **Severity**: HIGH (blocks story #9 / submission-evaluation epic)
- **Description**: `ADR-0007 §Decision` specifies `EvaluationService.submit(submission: PlayerSubmission)` where `PlayerSubmission` is a typed Resource carrying `case_id` / `player_disposition` / `player_citations` / `chain_data` / `submission_time_ms`. The `control-manifest.md` Feature Layer rule specifies `submit(chain_data: Dictionary)`. These signatures are incompatible.
- **Origin**: Surfaced during story-007 data-layer implementation (2026-05-23). EvaluationService does not exist yet, so the conflict is currently harmless. A forward-claim comment in `src/data/workspace_data.gd` `submit()` flags it.
- **Repayment trigger**: MUST reconcile before story #9 (submission-evaluation) begins. Resolution requires an explicit decision (ADR-0007 amendment OR control-manifest correction) — do not resolve by guessing. PlayerSubmission's `player_disposition` + `player_citations` come from the Brief Editor submit dialog, which informs which signature is correct.

### TD-002 — Untyped `Array` in WorkspaceData (static-typing standard)
- **Logged**: 2026-05-23
- **Severity**: LOW (standards hygiene; no runtime correctness impact)
- **Description**: In `src/data/workspace_data.gd`: `const ALLOWED_NODE_FIELDS: Array` should be `Array[String]`; `_roots()` and `_children_of()` return untyped `-> Array` (could be `-> Array[HypothesisNodeData]`). technical-preferences.md requires typed arrays everywhere.
- **Origin**: Pre-existing code from story-002 / story-003a. Flagged by godot-gdscript-specialist during story-007 code review (MINOR-3/MINOR-4); not introduced by story-007.
- **Repayment trigger**: Opportunistic — fold into the next WorkspaceData-touching story, or a dedicated typing-hygiene pass.

### TD-003 — engine-reference ui.md line 94 AccessKit role API may be inaccurate
- **Logged**: 2026-05-23
- **Severity**: MEDIUM (misleads UI Foundation / accessibility stories)
- **Description**: `docs/engine-reference/godot/modules/ui.md` line 94 states `DisplayServer.AccessibilityRole` is "set via `Control.set_accessibility_role()`" (marked "Verified ... 2026-05-17"). Runtime investigation during story-002 (UI Foundation) found Godot 4.6 `Control` has **no `accessibility_role` property and no `set_accessibility_role()` method**; the working API is `DisplayServer.accessibility_update_set_role(rid, role)` with `rid = Control.get_accessibility_element()`, callable only inside `NOTIFICATION_ACCESSIBILITY_UPDATE` (=3000). The Kr* classes were implemented against the working API (tests pass).
- **Origin**: story-002 implementation (godot-gdscript-specialist runtime finding, 2026-05-23).
- **Repayment trigger**: Verify against actual Godot 4.6 source/docs. If confirmed, correct ui.md line 94 + the AccessibilityRole section's "set via" sentence so future stories use the RID + notification pattern from the start. If `set_accessibility_role()` does exist as a convenience wrapper, document both. Until resolved, follow the working pattern in `src/ui/kr_pane.gd`.

### TD-004 — current-best-practices.md atomic-write snippet uses an invalid temp extension
- **Logged**: 2026-05-23
- **Severity**: MEDIUM (would silently break any atomic save built from the snippet)
- **Description**: `docs/engine-reference/godot/current-best-practices.md` (§File I/O — Atomic Write Pattern, ~line 132) writes the temp file as `"user://settings.tres.tmp"`. `ResourceSaver.save()` selects its format from the file EXTENSION, and a bare `.tmp` extension yields `ERR_FILE_UNRECOGNIZED` (error 15) — the save fails and the atomic write never works. Verified during story-001 (Save/Load) implementation: the temp path must keep a recognized extension. `SaveLoadService._save_resource_atomic` uses `name.tres` → `name.tmp.tres` instead.
- **Origin**: story-001 (Save/Load) implementation + test, 2026-05-23.
- **Repayment trigger**: Correct the snippet in current-best-practices.md to insert `.tmp` before the extension (e.g. `settings.tmp.tres`) so future code copied from it works. Low effort, do opportunistically.

### TD-005 — CI must regenerate the global class cache before gdunit4 runs
- **Logged**: 2026-05-23
- **Severity**: MEDIUM (green locally, would fail CI for any new class_name used in autoload code)
- **Description**: New `class_name` scripts are not registered in `.godot/global_script_class_cache.cfg` until an editor scan runs. When an AUTOLOAD (parsed at boot, before any test preload) references a brand-new `class_name` as a type (e.g. `SaveLoadService` referencing `ActiveCaseSaveData`), the autoload fails to parse in a headless test run and every test errors. Worked around locally by running `godot --headless --import` once to regenerate the cache. The project CI command (`godot --headless --script tests/gdunit4_runner.gd`) does NOT pre-import, so it would hit this on a clean checkout (`.godot/` is typically gitignored).
- **Origin**: story-003 (Save/Load) — `SaveLoadService._active_case: ActiveCaseSaveData`, 2026-05-23.
- **Repayment trigger**: Add a `godot --headless --import` (or `--editor --quit`) step to the CI workflow BEFORE the gdunit4 run so global class names resolve. Verify the gdunit4 GitHub Action does this; if not, add it. Until then, run `--import` after adding any new `class_name` referenced by autoload code.

---

## Resolved

_(none yet)_
