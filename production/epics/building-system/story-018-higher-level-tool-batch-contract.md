# Story 018: Higher-level tool batch contract (system-side)

> **Epic**: Building System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-126`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: A single house-template stamp whose internal sub-shapes aren't all mutually adjacent is still merged into one project by the batch-merge guarantee — every resulting cell belongs to exactly one project.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: No post-cutoff APIs. Reuses Story 003's grouping/union-find over the batch.

**Control Manifest Rules (this layer — Core)**:
- Required: a single higher-level tool commit is always ONE batch for grouping purposes, regardless of how many primitive cell-sets it internally produces — guaranteeing one project even for non-mutually-26-adjacent sub-shapes; these tools emit a normal batch of Draft blueprint cells into exactly one project.
- Forbidden: higher-level tools add NO new system-level behavior beyond the grouping rules; the tool UX (room-rect, auto-roof, template picker) is Building UI's, not this system's.
- Guardrail: batch grouping bounded by the committed batch, not world size.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC77: GIVEN a house-template stamp whose internally-generated sub-shapes (walls/floor/roof) would not all be mutually 26-adjacent on their own, WHEN committed as one action, THEN every resulting cell belongs to exactly one project (Rule 14d) — the tool's own UX is Building UI's to design; this AC covers only this system's batch-merge guarantee. [TR-126]

---

## Implementation Notes

*Derived from ADR-0016 Decision §2 + building-system Rule 14d, TR-126:*

- Define the system-side contract that a single higher-level tool commit is **always one batch** for grouping purposes (Story 003's union-find), regardless of how many primitive cell-sets it internally produces (a house-template stamp emits walls + floor + roof in one pass).
- This guarantees one project even for a geometry where two sub-shapes would not otherwise be mutually 26-adjacent (e.g. a roof cap with a gap before its supporting wall completes) — the batch-merge guarantee treats the whole commit as one grouping unit.
- Room-rect, auto-roof, and house-template tools satisfy this contract by emitting a normal batch of Draft blueprint cells into exactly one project — they add NO new system-level behavior beyond Rules 14c/14d.
- The tool UX (how the player draws a room rect, picks a template) is entirely Building UI's domain (building-ui epic) — this story delivers ONLY the batch → one-project guarantee (a `commit_batch(cells, kind)` contract that forces single-project membership for the whole batch).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- The higher-level tool UX (room-rect drawing, template picker, auto-roof) — Building UI epic.
- Story 003: the general 26-adjacency grouping (this story extends it with the whole-batch-is-one-project guarantee).

---

## QA Test Cases

**AC77 — one commit batch → exactly one project**
- Given: a house-template stamp emitting walls + floor + roof whose sub-shapes are NOT all mutually 26-adjacent.
- When: committed as one action (one batch).
- Then: every resulting cell belongs to exactly one project.
- Edge cases: a roof cap separated by a gap from its wall still lands in the same project as the walls/floor; two SEPARATE commits (not one batch) that aren't adjacent remain two projects (contrast with the single-batch guarantee); a single-shape higher-level commit still yields one project.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/higher_level_tool_batch_contract_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (grouping/union-find over the batch).
- Unlocks: Building UI room-rect / auto-roof / house-template tools (they emit into this contract).
