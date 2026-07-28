# Story 015: Draft eraser (removal-tool micro-state branch)

> **Epic**: Building System
> **Status: Complete (2026-07-27 — 1428/1428 suite green 0 orphans, agent-verified; also covers building-031's AC41 scope)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-27

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-123`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: The removal tool's behavior branches on the target cell's own micro-state: Draft → instant cancel (no job); Queued/UnderConstruction → instant cancel with claim revoke; Built → a demolition order. Built cells mutate only via worker jobs; plan editing is free.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: No post-cutoff APIs. The Built branch delegates to Story 009's demolition-order creation.

> **NOTE — registry vs GDD divergence**: `tr-registry.yaml` TR-123 text still contains a stale clause ("furniture is explicitly exempt and remains instantly removable"). This is SUPERSEDED by the GDD (Core Rule 16, AC17) and TR-127 (Story 017): furniture removal is now job-gated, NOT instant. Implement the GDD/TR-127 behavior; the registry text should be back-annotated. Flagged for producer.

**Control Manifest Rules (this layer — Core)**:
- Required: removal-tool branch — Draft → instant cancel, no job; Queued/UnderConstruction → instant cancel + claim revoke; Built → demolition order (Story 009).
- Forbidden: never create a job for a Draft-cell erase; never instantly clear a Built cell (route to demolition); Built cells mutate only via worker jobs.
- Guardrail: draft-erase is O(1) per cell — indistinguishable in cost from never having drawn the cell.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC73: GIVEN the removal tool targets a cell still in Draft micro-state, WHEN it fires, THEN the cell is erased instantly with no job created and no notification (Rule 16, Edge Case 16). [TR-123]
- [ ] AC74: GIVEN the removal tool targets a Queued/UnderConstruction (released but not yet Built) cell, WHEN it fires, THEN it cancels instantly and any claimed job is revoked — unchanged from the pre-slice behavior (Rule 16's micro-state branch). [TR-123]
- [ ] AC13/13b/AC65 seam: GIVEN a Built cell, WHEN the removal tool targets it, THEN a demolition order is created (delegates to Story 009) — the cell is NOT removed instantly. [TR-123/114]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Rule 16/17, TR-123:*

- The removal tool branches on the target cell's own micro-state:
  - **Draft** → instant cancel, no job, no notification (also reachable via undo). This is the "draft eraser" — plan editing, indistinguishable in cost from never having drawn the cells (Edge 16: carving a door gap out of an unreleased wall draft).
  - **Queued/UnderConstruction** (released but not yet Built) → instant cancel and the claiming villager's job is revoked (graceful abandon). Unchanged from pre-slice.
  - **Built** → a demolition order (Story 009). Do NOT remove instantly.
- If a canceled/erased cell was a floor-excavation entry (Story 012), write back its `restore_value` (do not leave empty).
- Furniture: per the GDD (Core Rule 16, AC17) and TR-127, Built furniture removal is ALSO job-gated (Story 017), NOT instantly removed — do not carve out furniture here despite the stale registry text (see NOTE above).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: the demolition-order tick execution (this story just routes Built → demolition).
- Story 013: removal targeting terrain → dig order (a separate terrain-target branch).
- Story 017: furniture-specific job-gated demolition (this story routes furniture Built removal into that path, does not implement it).
- Story 012: capturing `restore_value` at commit (this story consumes it on cancel).

---

## QA Test Cases

**AC73 — Draft erase is free and silent**
- Given: the removal tool targets a Draft-micro-state cell (e.g. a door gap in an unreleased wall draft).
- When: it fires.
- Then: the cell is erased instantly, no job is created, no notification.
- Edge cases: erasing the last cell of a Draft project deletes the empty project (Story 002); a floor-excavation Draft cell restores its `restore_value` on erase.

**AC74 — Queued/UnderConstruction cancel + revoke**
- Given: a released-but-unbuilt cell (Queued or UnderConstruction, possibly claimed).
- When: the removal tool fires.
- Then: instant cancel and any claimed job revoked (graceful).

**Built → demolition seam**
- Given: a Built cell.
- When: the removal tool fires.
- Then: a demolition order is created (Story 009) — the cell is not removed instantly.
- Edge cases: a second removal on an already-queued demolition cell is a no-op (Edge 17 via Story 009).

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/building_system/draft_eraser_removal_branch_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (cell micro-states), Story 009 (demolition-order Built branch), Story 012 (restore_value on cancel).
- Unlocks: Story 010 (Abriss reuses the Draft-cancel path), Story 017 (furniture Built removal routes here).
