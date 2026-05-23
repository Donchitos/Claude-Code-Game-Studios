# Story 008: Close-request forced flush + full-session persistence

> **Epic**: Save/Load
> **Status**: Complete (2026-05-23)
> **Layer**: Core / Foundation
> **Type**: Integration
> **Manifest Version**: 2026-05-18
> **Estimated Effort**: 2-3h (M)
> **Performance**: close flush synchronous; if > 100ms a spinner is required (OQ-SL3) — measure

## Context

**GDD**: `design/gdd/save-load.md` (§3.4 Inter-system — game-exit forced flush, §10.6 AC-14, §4.4 atomic write time, EC-10)
**Requirement**: `TR-save-*` (close-request flush + full-session persistence — read fresh from `tr-registry.yaml`)

**ADR Governing Implementation**: ADR-0011
**ADR Decision Summary**: On `NOTIFICATION_WM_CLOSE_REQUEST`, drain any pending debounce queue and run a synchronous `_perform_save` before quit so the last edits are not lost (EC-10). Full 30-min session reconstructs from `active_case.tres` on restart (only the final < 250ms debounce window may be lost).

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `NOTIFICATION_WM_CLOSE_REQUEST` in `_notification`. Requires `get_tree().set_auto_accept_quit(false)` (or `Window.auto_accept_quit = false` on root) so the close can be intercepted, the save flushed synchronously, then `get_tree().quit()`. VR-SL3 (close-block time vs perception) is advisory — measure; > 100ms → spinner (OQ-SL3). On an autoload Node, `_notification` receives the WM close on the main window.

**Control Manifest Rules (Core/Foundation)**:
- Required: intercept close → synchronous flush of pending save → quit; drain debounce queue (don't drop the pending save)
- Forbidden: quitting without flushing a pending (dirty) save
- Guardrail: close flush synchronous; measure block time (VR-SL3)

---

## Acceptance Criteria

- [x] AC-14 (Integration) — full-session reconstruction: debounced edits recoverable after flush + reload (latest pending edit wins) — **DONE** (`test_full_session_reconstructs_latest_edits_after_flush`; true force-quit is a manual reproducer)
- [x] Close-request flush — pending dirty debounced save flushed synchronously (EC-10) — **DONE** (`test_flush_writes_pending_dirty_save` + no-op-when-clean); `NOTIFICATION_WM_CLOSE_REQUEST` → `_flush_pending_save` + quit wired (quit path not in-process testable)

---

## Implementation Notes

Per ADR-0011 §3.4 (game-exit forced flush):

```gdscript
func _ready() -> void:
    # ... story 001/003/004 ...
    get_tree().set_auto_accept_quit(false)   # intercept close to flush first

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _flush_pending_save()                 # drain debounce: if dirty, _perform_save now (synchronous)
        get_tree().quit()

func _flush_pending_save() -> void:
    if _autosave_timer != null and not _autosave_timer.is_stopped():
        _autosave_timer.stop()
        _perform_save("active_case")           # EC-10 — don't lose the queued edit
```

- `_flush_pending_save` checks whether the debounce timer (story 003) is running (= dirty) and, if so, performs the save immediately rather than waiting for the 250ms timeout.
- AC-14 is reconstruction: it relies on stories 001-004 (atomic write + load). The integration test simulates a sequence of edits + a flush + a reload and asserts the final state matches. Real "force-quit" is a manual reproducer; the automated test exercises `_flush_pending_save` + reload round-trip.
- Measure close-block time (VR-SL3); if a casebook of 100 entries pushes it > 100ms, note for the OQ-SL3 spinner decision (v1+).

---

## Out of Scope

- Spinner UI for slow flush (OQ-SL3 — v1+, needs UI Foundation)
- Stories 001-004 mechanics (this story adds the close-request hook + drives the full round-trip)
- Resolution/recovery cascades (stories 005/006)

---

## QA Test Cases

- **AC-14 (reconstruction)**: Given a SaveLoadService with an active_case mutated through several debounced edits, When `_flush_pending_save` is invoked (simulating close) then the Resource is reloaded, Then the reloaded active_case reflects the latest edits (not just the last-committed debounce). Edge: no pending edit → flush is a no-op (timer stopped), no spurious write.
- **Close-flush**: Given the debounce timer running (dirty), When `_flush_pending_save`, Then the timer is stopped and `_perform_save("active_case")` ran exactly once before quit. Edge: timer already stopped (clean) → no save.

---

## Test Evidence

**Story Type**: Integration
**Required**: `tests/integration/save_load/close_flush_persistence_test.gd` (gdunit4) — AC-14 + close-flush. Manual reproducer noted for true force-quit.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (atomic write), Story 003 (debounce timer to drain), Story 004 (load for round-trip)
- Unlocks: None (lifecycle completeness)

---

## Completion Notes
**Completed**: 2026-05-23
**Criteria**: AC-14 + close-flush passing.
**Files**:
- `src/services/save_load_service.gd` — `_ready` sets `get_tree().set_auto_accept_quit(false)`; `_notification(NOTIFICATION_WM_CLOSE_REQUEST)` → `_flush_pending_save` + `quit()`; `_flush_pending_save()` drains running per-category debounce timers (immediate save).
- `tests/integration/save_load/close_flush_persistence_test.gd` — 3 tests.
**Test Evidence**: close_flush_persistence 3/3 PASS; full unit+integration **384 cases / 367 executed / 17 skipped / 0 failures, exit 0** (`set_auto_accept_quit(false)` does not affect the test runner — gdunit4 quits explicitly, the setting only gates WM_CLOSE_REQUEST).
**Notes**:
- The `NOTIFICATION_WM_CLOSE_REQUEST` → quit path can't be exercised in-process (it quits the runner), so `_flush_pending_save` is tested directly; the notification wiring is by inspection.
- VR-SL3 (close-block time) advisory — measure on target; > 100ms casebook flush would need a spinner (OQ-SL3, v1+).
**Code Review**: Implemented + reviewed directly by orchestrator.
