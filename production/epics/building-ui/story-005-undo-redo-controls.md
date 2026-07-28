# Story 005: Undo/redo controls & the plan-only undo scope

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (element E2, zone Z6, P8)
**Requirement**: `TR-building-ui-048`, `TR-building-ui-068`, `TR-building-ui-088`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle)
**ADR Decision Summary**: Plan-only undo/redo — the undo stack governs the **plan ONLY** (draft cells and queued orders); redo re-creates only still-valid cells, dropping invalidated ones with feedback. Once a cell is Built, undo can never reach it; reverting built work is exclusively a demolition order, a worker-executed job, never an instant undo.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: The held-key repeat RATE is OS-configured (`InputEventKey.echo`) and is **deliberately neither asserted nor tested** — AC9 tests count-fidelity with **synthetic** events only. A repeat-velocity cap is GDD Open Question 6 (MVP playtest). `Ctrl+Z`/`Ctrl+Y` are the committed bindings (building-system).

**Control Manifest Rules (this layer)**:
- Required (Presentation): undo/redo buttons **mirror** `UndoRedoStack`'s state exactly — disabled when the corresponding stack is empty. One click = one step. The buttons are non-modal chrome, permanently present in Z6.
- Forbidden: the HUD deriving undo availability itself; the undo button ever listing or reaching a **demolition** step or a **Built** cell; an "undo my demolished house" affordance anywhere in the HUD.
- Guardrail: N synthetic action-press events produce exactly N undo intents — no debounce, no acceleration, none added, none dropped.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 7/23 + Edge Case 4, scoped to this story:*

- [ ] **AC8**: Given an empty undo stack (mocked), Then undo is disabled; Given a redo branch, Then redo enables — **mirroring only** (`TR-building-ui-048`).
- [ ] **AC9**: Given N synthetic undo action-pressed events in sequence, Then exactly N undo intents are emitted — none added, none dropped, no debounce, no acceleration (`TR-building-ui-048`).
- [ ] **AC18**: Given an undo click racing a same-frame disable signal, Then a **silent no-op** — no action emitted, no error, no noisy rejection from the source system (Edge Case 4, `TR-building-ui-068`).
- [ ] **AC68**: Given a Built cell (no surviving undo entry — already retired, or beyond `undo_stack_depth`), When undo fires, Then it is a **silent no-op** — Built cells are never reachable by undo regardless of stack state (Rule 23, `TR-building-ui-088`).
- [ ] **AC69**: Given a project queued for or undergoing demolition, Then **no undo entry for it exists at any point** in its demolition lifecycle — the undo button and its binding never list one (Rule 23, `TR-building-ui-088`).
- [ ] The buttons mirror `UndoRedoStack.can_undo()`/`can_redo()` and refresh on `command_undone`/`command_redone`/`redo_no_op`; the disabled state is a render of that query, never a cached count.
- [ ] `redo_cells_dropped` and `redo_no_op` produce player-visible feedback consistent with Rule 8's invalid-cue language — a redo that dropped cells is not silent (ADR-0016's "dropping invalidated ones **with feedback**").
- [ ] Both buttons are keyboard-operable via the committed `Ctrl+Z`/`Ctrl+Y` bindings with semantics identical to a click; a held key repeats at the OS rate, one step per repeat (Rule 7).
- [ ] `Ctrl+Z` never resolves an Esc-chain step and Esc never resolves an undo — the two input paths are disjoint.

---

## Implementation Notes

*Derived from the landed `UndoRedoStack` and ADR-0016:*

- The landed surface is exactly: `can_undo()`, `can_redo()`, `get_undo_stack_size()`, `get_redo_stack_size()`, `undo() -> bool`, `redo() -> bool`, `record_command(cells)`, `clear()`, plus signals `command_undone`, `command_redone`, `redo_cells_dropped`, `redo_no_op`. Mirror those; add nothing.
- **AC68/AC69 are enforced upstream, not here.** `UndoRedoStack`'s plan-only invariant is `building-011`'s job (it supplies a `cancel_cell_callable` that skips any cell already in `MicroState.BUILT`), and the class's own grep-guard proves it holds zero Voxel World write references. This story's ACs are therefore **absence assertions**: given a Built-cell or demolition scenario, the HUD emits an intent that resolves to a no-op and renders nothing misleading. Do not implement a second plan-only check in the UI.
- **Known Conflict 3 applies**: `UndoRedoStack` is a `Node` that exists in `src/building_system/` but is in no scene and has no `Valley` getter. Resolve hosting before wiring; drive the ACs against a mock until then.
- AC18's race: read `can_undo()` at the moment the intent is dispatched, not at the moment the button was drawn. A stale enabled button clicked one frame late must resolve to nothing, quietly.
- For AC9, feed the input path synthetic `InputEventAction`s in a loop and count emitted intents. Do **not** attempt to simulate OS key-repeat timing — the GDD explicitly scopes that out.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: the Projects Panel's **Verwerfen** button (which discards never-built plan cells and *is* undo-tracked) and its **Abriss/Abbrechen** buttons (which are not). This story only guarantees the undo control never lists a demolition.
- `building-011` (plan-only undo invariant) — a Building System story, milestone criterion #12.
- Story 009: the invalid-commit cue's presentation (this story reuses it for redo-drop feedback).

---

## QA Test Cases

- **AC8**: Given `can_undo()` false / `can_redo()` true (mocked), Then the undo button is disabled and the redo button enabled; flip the mock, Then the states flip on the next refresh.
- **AC9**: Given 25 synthetic undo action-presses, Then exactly 25 `undo()` calls were made.
- **AC18**: Given an enabled undo button and `can_undo()` mocked false at dispatch time, When clicked, Then zero calls, zero errors, zero pushed warnings.
- **AC68**: Given a mocked stack whose only entry's cells are all `BUILT`, When undo fires, Then the resulting cell-cancel count is 0 and the HUD shows no success feedback.
- **AC69**: Given a project transitioned through queue-demolition and demolition-complete (mocked), Then `get_undo_stack_size()` is unchanged at every step and no undo entry names any of its cells.
- **Feedback**: Given `redo_cells_dropped([c1, c2])`, Then the invalid/attention cue is shown once; Given `redo_no_op()`, Then likewise, and no state change is rendered.

---

## Test Evidence

**Story Type**: Logic (state mirror + event counting) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/undo_redo_controls_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001, 002; `building-011` (plan-only undo — Cluster 0, milestone criterion #12) for AC68/AC69 to be meaningful; **Known Conflict 3** (hosting).
- Unlocks: —
