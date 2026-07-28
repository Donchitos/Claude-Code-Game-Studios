# Story 011: Plan-only undo/redo

> **Epic**: Building System
> **Status: Complete (2026-07-27 — 1355/1355 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-119`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: The undo stack governs the plan ONLY — draft cells and queued orders. Built cells are never mutated by undo; undo of a released-but-unbuilt cell removes the pending job; redo re-creates only still-valid cells, dropping invalidated ones with feedback. Planning/undo work identically paused or unpaused.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: No post-cutoff APIs. Undo works while paused (raw-delta input path). The undo stack is excluded from `serialize()` (ADR-0012, TR-033).

**Control Manifest Rules (this layer — Core)**:
- Required: plan-only undo/redo — the undo stack governs the plan (draft cells + queued orders); undo of a released-but-unbuilt cell removes the pending job; redo re-creates only still-valid cells, dropping invalidated ones with feedback; planning/undo identical paused or unpaused.
- Forbidden: never mutate built cells via undo — full undo of built geometry is rejected (it would make built geometry non-authoritative and bypass ADR-0009's occupancy/seal semantics and the worker-executed mutation contract); never save the undo/redo stack.
- Guardrail: the stack is bounded (`undo_stack_depth` default 50); worst-case memory is negligible against the ceiling.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC27: GIVEN a command with pending and already-built cells, WHEN undone, THEN pending cells are canceled and the already-Built cells are left standing untouched — no removal, no demolition order queued (Rule 17, Edge Case 7). [TR-119]
- [ ] AC29: GIVEN a 15-cell wall command with a mix of still-pending and already-Built cells, WHEN undo fires once, THEN all still-pending cells cancel in that single step and the Built cells are left standing (per-command granularity unchanged; Built-cell exclusion is new). [TR-119]
- [ ] AC68: GIVEN a command whose cells have all already reached Built (nothing pending remains), WHEN undo fires, THEN nothing happens to those cells — undo has zero effect on fully-Built work, not even queuing a demolition order (Rule 17, companion to AC27/29). [TR-119]
- [ ] AC28: GIVEN an undone command whose cells are now partially occupied, WHEN redone, THEN only still-valid cells are re-created; invalid ones are dropped with feedback (Edge Case 8). [TR-119]

---

## Implementation Notes

*Derived from ADR-0016 Decision §5 + building-system Rule 17, TR-119:*

- Undo/redo operate on player commands (one wall drag = one command = one undo step), and on **plan entries exclusively** — never a Built cell.
- Undo of a command: cancel only the cells still in Draft/Queued/UnderConstruction (for released-but-unbuilt cells, remove the pending job / revoke claim). Leave any Built cells standing exactly as they are — do NOT remove them and do NOT queue a demolition order for them. A player who wants Built cells torn down uses the removal tool or Abriss separately (Stories 009/010/015).
- Redo replays the command as new blueprint cells, re-validating every cell; cells no longer valid (occupied since undo) are dropped with the standard invalid-feedback; valid cells are re-created as blueprints. A redo where zero cells survive is a no-op with feedback.
- Planning/undo must work identically paused or unpaused (Game Feel — build-while-paused).
- The undo stack core (bounded depth 50; redo branch cleared on new command; cleared on transition-COMPLETE, never begin; never persisted) is the pre-slice Building System undo foundation — this story enforces the plan-only INVARIANT on top of it. If the stack core is not yet implemented, this story establishes the command/stack model with the plan-only invariant baked in.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: demolition orders (the deliberate teardown path undo must NOT trigger).
- Story 015: the removal tool's own micro-state branching (a separate player action from undo).

---

## QA Test Cases

**AC27 / AC29 — undo cancels pending, leaves Built standing**
- Given: a command (e.g. a 15-cell wall) with a mix of still-pending (Draft/Queued/UnderConstruction) and already-Built cells.
- When: undo fires once.
- Then: all still-pending cells cancel in that single step; the Built cells are left standing — no removal, no demolition order queued.
- Edge cases: an UnderConstruction cell mid-claim has its job revoked on cancel; per-command granularity is preserved (one command = one undo step).

**AC68 — undo of a fully-Built command is inert**
- Given: a command whose cells are all Built (nothing pending).
- When: undo fires.
- Then: nothing happens to those cells — not even a demolition order queued.

**AC28 — redo drops invalidated cells**
- Given: an undone command; some of its cells are now occupied.
- When: redo fires.
- Then: only still-valid cells are re-created as blueprints; invalid ones are dropped with feedback; zero-survivor redo is a no-op with feedback.

**Paused parity**
- Given: the game is paused.
- When: undo/redo fires.
- Then: the stack mutates and blueprints update exactly as when unpaused.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/plan_only_undo_redo_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (project entity + cell micro-states). Coordinates with the pre-slice undo-stack foundation.
- Unlocks: safe, authoritative built-geometry invariant across the whole system.
