# Story 010: Project cancel / Abriss

> **Epic**: Building System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-117`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: A change-order/cancel on a project converts remaining Draft cells to a free cancel and every Built cell to a worker-executed demolition order — demolition is job-based, not instant, and uniform for blocks and furniture.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: No post-cutoff APIs. Reuses Story 009's demolition-order creation and Story 015's Draft-cancel path.

**Control Manifest Rules (this layer — Core)**:
- Required: Abriss converts an entire project at once — remaining Draft cells cancel for free, every Built cell becomes an already-released demolition order, in one action (no separate "Bau starten" to tear down).
- Forbidden: never instantly clear Built cells; never leave a project half-converted (Draft cancels and Built demolition-orders happen atomically in one action).
- Guardrail: the conversion is bounded by the project's own cell set.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC67: GIVEN a project with both remaining Draft cells and Built cells, WHEN Abriss (project cancel) fires, THEN the Draft cells cancel for free instantly AND every Built cell receives an already-released demolition order, all in one action (Rule 14k). [TR-117]
- [ ] Abriss includes any not-yet-released change-order batch's Draft cells in the free cancel. [TR-117]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Rule 14k, TR-117:*

- Project cancel ("Abriss") converts an entire project at once:
  - Every remaining Draft cell (including any not-yet-released change-order batch, Story 007) is canceled for free, exactly as a single Draft cancel already is (Story 015's Draft branch).
  - Every Built cell is converted to an already-released demolition order (Story 009) in the same action — the player does NOT additionally press "Bau starten" to tear a canceled project down.
- The two conversions happen in one atomic action.
- After Abriss, the project follows the persistence-until-empty rule (Story 002): it disappears only once every cell is canceled or demolished away.
- Furniture cells in the project demolish via Story 017's job-gated path (atomic footprint); Abriss enqueues those the same way.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: the block demolition-order tick execution (Abriss creates the orders; 009 runs them).
- Story 015: the single-cell removal-tool Draft-cancel branch (Abriss reuses it project-wide).
- Story 017: furniture-specific atomic demolition mechanics.

---

## QA Test Cases

**AC67 — Abriss converts whole project in one action**
- Given: a project with a mix of remaining Draft cells and Built cells (plus optionally an unreleased change-order batch).
- When: Abriss fires.
- Then: all Draft cells (including the unreleased batch) cancel for free instantly; every Built cell gains an already-released demolition order; all in one action; no "Bau starten" needed for teardown.
- Edge cases: a Built cell already having a demolition order is not double-queued (Edge 17 via Story 009); a fully-Draft project Abriss cancels everything for free and deletes the empty project; a fully-Built project Abriss queues demolition for all Built cells.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/project_cancel_abriss_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 009 (demolition orders), Story 015 (Draft-cancel path), Story 002 (project entity).
- Unlocks: Building UI Abriss control.
