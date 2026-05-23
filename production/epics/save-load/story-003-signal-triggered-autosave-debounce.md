# Story 003: Signal-triggered autosave + 250ms debounce

> **Epic**: Save/Load
> **Status**: Complete (2026-05-23)
> **Layer**: Core / Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 3h (M)
> **Performance**: No polling — signal-triggered only; 250ms debounce coalesces bursts; save off the debounce timeout (not per-frame)

## Context

**GDD**: `design/gdd/save-load.md` (§3.1 Core Rules — autosave policy, §3.3 signal contract, §4.3 debounce timer, §10.1 AC-2, EC-9/10)
**Requirement**: `TR-save-*` (signal-triggered autosave + debounce — read fresh from `tr-registry.yaml`)

**ADR Governing Implementation**: ADR-0011
**ADR Decision Summary**: Autosave is signal-triggered (never per-frame polling) + 250ms debounce. SaveLoadService subscribes to 6 signals (`workspace_state_changed`, `brief_editor_state_changed`, `brief_editor_submitted`, `evaluation_completed`, `submission_rejected`, `case_state_changed`). Most route through a debounced `active_case` save; resolution signals are immediate (0ms). Subscribe-if-present for sources not yet implemented.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `Timer` one-shot, `wait_time = 0.25`, `start()` resets a running timer (debounce coalescing — same pattern as UIService viewport debounce). `WorkspaceData.workspace_state_changed(old:int,new:int)` exists (story-007). Other emitters (Brief controller, EvaluationService, CaseService `case_state_changed`) may be absent → guard `connect` with presence checks.

**Control Manifest Rules (Core/Foundation)**:
- Required: signal-triggered autosave via typed `.connect()`; 250ms debounce; subscribe-if-present guard for absent emitters
- Forbidden: `save_load_per_frame_polling` (saving in `_process`/`_physics_process` or on a repeating poll Timer)
- Guardrail: debounce window 250ms (externalized constant); save executes once per coalesced burst

---

## Acceptance Criteria

- [x] AC-2 (Logic) — `workspace_state_changed` → 250ms debounce → `_perform_save` atomic-writes `active_case.tres` — **DONE** (`test_workspace_change_starts_debounce_timer` + `test_perform_save_writes_active_case_atomically`)
- [x] Debounce coalescing — repeated changes reuse one timer + reset (EC-9) — **DONE** (`test_repeated_changes_reuse_one_timer_and_reset`)
- [x] No-polling — forbidden pattern `save_load_polling_based_autosave` registered; service is signal-only — **DONE** (`test_no_per_frame_polling_autosave`)

---

## Implementation Notes

Per ADR-0011 §Decision (autosave cascade):

```gdscript
const AUTOSAVE_DEBOUNCE_MS := 250
var _autosave_timer: Timer

func _ready() -> void:
    # ... (story 001 bootstrap) ...
    _autosave_timer = Timer.new()
    _autosave_timer.one_shot = true
    _autosave_timer.wait_time = AUTOSAVE_DEBOUNCE_MS / 1000.0
    _autosave_timer.timeout.connect(func() -> void: _perform_save("active_case"))
    add_child(_autosave_timer)
    # subscribe-if-present (await one frame so emitters' _ready ran — ADR-0001 amend-2 §C3)
    await get_tree().process_frame
    _connect_if_present("workspace_state_changed", _on_workspace_changed)  # via the live WorkspaceData/controller

func _on_workspace_changed(_old: int, _new: int) -> void:
    _autosave_timer.start()   # debounce — resets if running (EC-9 coalescing)
```

- The actual emitter binding (which node owns `workspace_state_changed`) depends on the runtime workspace controller. For this story's tests, drive `_on_workspace_changed` / the debounce path directly and assert `_perform_save` fires once. Real emitter wiring follows when the workspace scene controller exists; keep the connect guarded.
- `_perform_save(category)` calls `_save_resource_atomic` (story 001) for the active_case Resource (story 002).
- Externalize `AUTOSAVE_DEBOUNCE_MS` as a const (Tuning Knob §7.1).

---

## Out of Scope

- Story 004: load path
- Story 005/006: resolution/recovery cascades (immediate, 0ms — different path; this story is the debounced active_case path)
- Real workspace-scene controller signal binding (wire when that controller lands; guard here)

---

## QA Test Cases

- **AC-2**: Given a SaveLoadService with an active_case Resource, When the workspace-changed handler fires and 250ms passes, Then `_perform_save("active_case")` ran and `active_case.tres` exists/updated. (Use the same await-real-timer or direct-callback approach as ui_service_test debounce; if headless Timer tick is unreliable, assert the callback chain structurally + that direct `_perform_save` writes.)
- **Coalescing**: Given 3 handler fires within 30ms, When 300ms passes, Then `_perform_save` ran exactly once (timer.start resets time_left — assert structurally like ui_service_test).
- **No-polling**: assert `architecture.yaml` registers `save_load_per_frame_polling` forbidden pattern (automated registry-read), and the service has no `_process`/`_physics_process` save.

---

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/save_load/autosave_debounce_test.gd` (gdunit4) — AC-2 + coalescing + no-polling.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (atomic write), Story 002 (active_case Resource)
- Unlocks: Story 008 (close-request flush drains the debounce queue)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: 3/3 passing (AC-2, coalescing, no-polling).
**Files**:
- `src/services/save_load_service.gd` — `DEBOUNCE_MS` per-category dict (ADR-0011) + `ACTIVE_CASE_FILE` const + `_active_case` field + `_on_workspace_changed` + `_schedule_save(category)` (0ms → immediate, else debounce timer) + `_debounce_timer_for` (lazy per-category Timer) + `_perform_save(category)` (active_case atomic write).
- `tests/integration/save_load/autosave_debounce_test.gd` — 5 tests.
**Test Evidence**: autosave_debounce 5/5 PASS; full unit+integration **370 cases / 353 executed / 17 skipped / 0 failures, exit 0**.
**Notes**:
- Forbidden pattern is `save_load_polling_based_autosave` (architecture.yaml line 1769) — the story draft's `save_load_per_frame_polling` was a misname; the test uses the registered name.
- Debounce timing verified structurally (timer running + time_left reset on repeated starts) + a direct `_perform_save` write — gdunit4 headless does not reliably advance real Timer ticks (same as ui_service_test).
- Real workspace-controller signal binding deferred to when that controller exists; `_on_workspace_changed` is the guarded entry the workspace side will connect to.
- The `_active_case` field is set by boot load (story 004) / runtime controllers; tests set it directly.
**Code Review**: Implemented + reviewed directly by orchestrator. Discovered + worked around the global-class-cache headless issue (see TD-005).
