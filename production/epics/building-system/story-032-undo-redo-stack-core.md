# Story 032: Undo/redo stack core (command model, bounded depth, redo-branch clear, transition-complete clear)

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 786/786 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-065`, `TR-building-system-066`, `TR-building-system-088`, `TR-building-system-089`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0012 (Save/Load Serialization) — secondary
**ADR Decision Summary**: Undo/redo operates on player commands (one drag = one command = one undo step). The undo stack governs the plan only and is excluded from serialization; it clears on transition-COMPLETE (never begin).

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Ctrl+Z/Ctrl+Y bindings; a held key repeats at OS key-repeat rate, each repeat = exactly one undo step (no custom acceleration). The stack clears on the transition-COMPLETE signal, never transition-begin.

**Control Manifest Rules (this layer — Core):**
- Required: undo/redo operate on player commands (one wall drag = one undo step); the stack is bounded (`undo_stack_depth` default 50); a new command clears the redo branch; the stack clears on transition-COMPLETE (never begin — a failed load must leave it intact).
- Forbidden: never save the undo/redo stack (excluded from serialization); never clear the stack on transition-begin.
- Guardrail: worst-case memory bounded (≤200 commands × 512 cells × small record ≈ low single-digit MB) — negligible against the ceiling.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC28: GIVEN an undone command whose cells are now partially occupied, WHEN redone, THEN only still-valid cells are re-created; invalid ones are dropped with feedback (Edge Case 8). [TR-088]
- [ ] AC30: GIVEN the stack holds `undo_stack_depth` commands, WHEN a new command commits, THEN the oldest is discarded silently (Edge Case 9). [TR-089]
- [ ] AC31: GIVEN any undo has occurred, WHEN a new command commits, THEN the redo branch is cleared. [TR-089]
- [ ] AC32: GIVEN a scene transition, WHEN it completes, THEN the undo stack is empty. [TR-066]
- [ ] AC32b: GIVEN a 3-command undo stack, WHEN a transition is triggered but ABORTS (target scene fails to load), THEN all 3 commands remain undoable — no begin-signal side effect touched the stack. [TR-066]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Core Rule 17 + Edge Cases 8/9, TR-065/066/088/089:*

- Model each player command as one undo step (one wall drag = one command). Record enough per command to cancel its still-pending blueprint cells and to replay it as new blueprints (redo).
- Bounded stack (`undo_stack_depth` default 50): beyond depth, the oldest command is discarded silently (becomes permanent). Any new command clears the redo branch (standard undo semantics).
- Redo re-validates every cell (Story 022): cells no longer valid (occupied since undo) are dropped with the standard invalid-feedback; valid cells re-created as blueprints. A redo where zero cells survive is a no-op with feedback.
- Clear the stack on the transition-COMPLETE signal ONLY (never transition-begin — an aborted/failed transition must leave the stack untouched, per Scene/World Management's side-effect discipline).
- The stack is never serialized (ADR-0012, TR-033).
- **Plan-only invariant** (undo never touches Built cells) is the slice story 011 — this story provides the stack mechanics that 011 constrains. Build the command model with the plan-only invariant hook in place.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: the plan-only invariant (undo never reaches Built cells) — the slice-scoped behavior layered on this stack.
- Story 033: the self-write-exemption / batched-write listener (undo bookkeeping honesty).
- Building UI's undo/redo buttons + Ctrl+Z/Ctrl+Y widget — building-ui epic.

---

## QA Test Cases

**AC28 — redo drops invalidated cells**
- Given: an undone command; some cells now occupied.
- When: redone.
- Then: only still-valid cells re-created; invalid dropped with feedback; zero-survivor redo is a no-op with feedback.

**AC30 / AC31 — bounded + redo-branch clear**
- Given: a full stack (`undo_stack_depth` commands); a prior undo.
- When: a new command commits.
- Then: the oldest is discarded silently AND the redo branch is cleared.

**AC32 / AC32b — transition clear vs abort**
- Given: a 3-command stack.
- When: a transition COMPLETES → stack empty; when a transition ABORTS (load fails) → all 3 remain undoable (no begin-signal side effect).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/undo_redo_stack_core_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 021 (commands/blueprints), Story 022 (redo re-validation), Scene/World Management (transition-COMPLETE/abort signals) — Foundation.
- Unlocks: Story 011 (plan-only invariant), Story 033 (self-write exemption).
