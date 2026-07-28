# Story 019: Tool state machine (Idle / ToolArmed / Dragging / Suspended)

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 446/446 suite green, parent-verified; Building epic OPENED)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-042`, `TR-building-system-067`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) — primary
**ADR Decision Summary**: A drag validly begun via `_unhandled_input()` switches release-listening to `_input()` for the drag's duration; `_input()` is actively listened to only during an in-progress drag window. Camera & Input enters Suspended on scene transition; Building System halts interaction with it.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Input routing order `_input()` → `_gui_input()` → `_unhandled_input()`; drag-release rule per ADR-0010 §3. Verify against `docs/engine-reference/godot/`.

**Control Manifest Rules (this layer — Core / input arbitration):**
- Required: drag ownership — a drag begun via `_unhandled_input()` switches release-listening to `_input()` (`set_process_input(true)`) for the drag's duration; on release `get_viewport().set_input_as_handled()` then revert to `_unhandled_input()`.
- Forbidden: never `MOUSE_MODE_CAPTURED` during placement drags; never restructure `mouse_filter` geometry to solve drag-release.
- Guardrail: `_input()` is actively listened to only during an in-progress drag window.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC2: GIVEN Tool A armed, WHEN Tool B is selected, THEN A deactivates and B arms — exactly one tool is ever active. [TR-042]
- [ ] AC3: GIVEN a tool armed, WHEN cancel fires (Esc/right-click), THEN the state returns to Idle and the ghost is hidden. [TR-042]
- [ ] AC37: GIVEN Suspended is entered mid-drag, WHEN the transition starts, THEN the drag aborts with no commit and no partial blueprint (Edge Case 12). [TR-067]
- [ ] AC44: GIVEN Dragging state, WHEN a different tool is selected mid-drag, THEN the drag aborts with no commit (Tool state table exit). [TR-067]

---

## Implementation Notes

*Derived from ADR-0010 + building-system Core Rule 1 + States and Transitions table:*

- States: `Idle` (no tool; camera-only; no ghost/commit) → `ToolArmed` (ghost preview follows the pick) → `Dragging` (drag threshold reached; preview re-rasterizes) → `Suspended` (Camera & Input transition; all interaction halted).
- Exactly one tool active at a time; activating a tool deactivates the previous; cancel (right-click/Esc) returns to Idle.
- Dragging aborts (no commit, no partial blueprint) on: cancel, Suspended entry, or another tool selected mid-drag.
- Suspended is driven by Camera & Input's Suspended state (scene transition) — enter/exit with it.
- This story owns the tool SM skeleton only; per-tool commit geometry (Stories 024–028), ghost rendering (023), and the outer Build Mode gate (Story 001) plug into it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: the outer Build Mode On/Off gate and Esc chain's final link.
- Story 023: ghost preview rendering (this SM just signals "show/hide ghost").
- Stories 024–028: per-tool drag/commit geometry.

---

## QA Test Cases

**AC2 — single active tool**
- Given: Tool A armed.
- When: Tool B is selected.
- Then: A deactivates, B arms; never two active tools.

**AC3 — cancel returns to Idle**
- Given: a tool armed.
- When: Esc or right-click fires.
- Then: state == Idle, ghost hidden.

**AC37 / AC44 — drag aborts**
- Given: Dragging state.
- When: (a) Suspended entered, (b) a different tool selected.
- Then: drag aborts, no commit, no partial blueprint.
- Edge cases: an aborted drag leaves the tool SM in a clean armed/idle state, not stuck in Dragging.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/tool_state_machine_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Camera & Input (action signals, Suspended state) — Foundation epic. None within this epic.
- Unlocks: Story 001 (Build Mode wraps this), Stories 020–028 (tools plug in).
