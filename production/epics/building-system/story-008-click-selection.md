# Story 008: Click-selection via cell→project reverse index

> **Epic**: Building System
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-113`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0010 (Cross-System UI/World Input Arbitration) §4 — primary; ADR-0016 (Build-Project Entity Lifecycle) — secondary
**ADR Decision Summary**: A world press that survives hover-suppression routes to Selection when no tool consumes the pick; Selection resolves to at most one of a villager (Area3D hit-test) or a project (DDA block pick → owning project via reverse index); clicking a project cell selects it regardless of tool-armed state.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Selection's project resolution is the DDA→owning-project path (ADR-0014 §4 pick → `project_at_cell`). The villager arm uses `intersect_ray` with `collide_with_areas = true, collide_with_bodies = false` — but that is ADR-0004/ADR-0010's arm; Building System's contribution here is the project resolution only. Verify pick precedence (`pick_tie_epsilon`, villager-wins-ties) against ADR-0010 §4.

**Control Manifest Rules (this layer — Core / input arbitration surface)**:
- Required: selection via cell→project reverse index — a world click on any cell selects the whole project regardless of tool-armed state; this is the DDA→owning-project resolution ADR-0010 §4 calls into.
- Forbidden: zero physics API in the block-pick path (project resolution is DDA-only); state colors never render on committed geometry.
- Guardrail: reverse-index lookup is O(1) per cell; villager-hit query runs once per click (event-driven).

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC62: GIVEN any project in any state (DRAFT/BUILDING/PAUSED/DONE) and no tool armed, WHEN one of its cells is clicked, THEN the project is selected — this works in Build Mode Off too, the sole exception to AC54 (Rule 14i/8d). [TR-113]

---

## Implementation Notes

*Derived from ADR-0016 Decision §6 + ADR-0010 §4 + building-system Rule 14i/8d, TR-113:*

- Expose the DDA→owning-project resolution: a world block-pick (ADR-0014 §4 DDA, zero physics) resolves the picked cell to its owning project via `project_at_cell` (Story 003) and selects it.
- Clicking any project cell selects the whole project regardless of tool-armed state — and it must work even while Build Mode is Off (the one sanctioned exception to Story 001's AC54 "no world-click consumption while Off").
- Selection routing precedence (villager vs project, nearest-wins with villager-winning ties, empty terrain/water clears) is ADR-0010 §4's arbitration — Building System supplies the project arm; the arbitration/Selection state is Building UI's per ADR-0010 §4. This story delivers the project-resolution seam and the Build-Mode-Off exception; verify the arbitration integration with the input arbitration owner.
- The selection surface (the project info panel) is Building UI's — this story emits/exposes the selected project id, not the panel.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: the general "no world-click consumption while Off" rule (this story is its documented exception).
- Building UI's project info panel rendering.
- The villager-selection arm (ADR-0004/ADR-0010) — not Building System's cell/project resolution.

---

## QA Test Cases

**AC62 — click selects owning project in any mode**
- Given: projects in each of DRAFT/BUILDING/PAUSED/DONE, no tool armed.
- When: a world click resolves (DDA) to one of a project's cells.
- Then: that project id is selected — including while Build Mode is Off.
- Edge cases: clicking a Built cell, a Draft cell, or an UnderConstruction cell of the same project all select the same project; clicking empty terrain/water clears selection; with a tool armed, project cells still resolve to selection when no placement pick consumes them (per ADR-0010 §4 precedence).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/building_system/click_selection_test.gd` OR documented playtest (project-resolution unit-testable now; full arbitration integration verified with the input arbitration owner).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (reverse index), Story 001 (Build Mode — this is its AC54 exception).
- Unlocks: Building UI project selection panel; ADR-0010 §4 Selection routing integration.
