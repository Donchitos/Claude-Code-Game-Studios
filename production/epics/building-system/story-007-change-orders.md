# Story 007: Change orders (attach to BUILDING/PAUSED/DONE projects)

> **Epic**: Building System
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-112`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: An edit targeting an already-released or done project attaches as a change order (added cells → new jobs; removed cells → demolition orders) without recreating the project entity — the entity is stable across its whole lifetime.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW)
**Engine Notes**: No post-cutoff APIs. Reuses F6 26-adjacency (Story 003) and per-batch release (Story 004).

**Control Manifest Rules (this layer — Core)**:
- Required: change orders attach to released/done projects (added cells → new jobs) WITHOUT recreating the project entity; a DONE project with a pending batch is no longer fully DONE for rollup.
- Forbidden: never start a new project for a commit 26-adjacent to an existing BUILDING/PAUSED/DONE project of the same kind; never disturb the project's already-Built cells or attribution history.
- Guardrail: batch attach/release is bounded by the committed batch, not world size.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC63: GIVEN a DONE project, WHEN a new 26-adjacent commit is made, THEN it attaches as a pending "Änderungen geplant" batch on the SAME project (not a new project) and the project's already-Built cells are unaffected (Rule 14h). [TR-112]
- [ ] AC64: GIVEN that pending batch, WHEN it alone is released, THEN only its cells become job-eligible BUILDING work — the project's other, already-Built cells are untouched by that release (Rule 14f/14h). [TR-112]
- [ ] Edge 15: a change-order batch drawn against a DONE project leaves DONE and shows "Änderungen geplant" until the new batch is separately released; already-Built cells and worker-attribution history are untouched. [TR-112]

---

## Implementation Notes

*Derived from ADR-0016 Decision §3 + building-system Rule 14h, TR-112:*

- A new commit whose cells are 26-adjacent (F6, Story 003) to an existing project that is BUILDING, PAUSED, or DONE does NOT start a new project — it attaches as a new **pending batch** on that project, displayed as "Änderungen geplant" until the player releases that batch specifically.
- Per-batch release (extend Story 004's `release_project` to accept a batch): releasing a batch makes only its cells job-eligible, leaving already-Built cells untouched.
- Rollup interaction: a DONE project that gains a pending change-order batch is no longer fully DONE for rollup purposes (Story 002) until the batch reaches Built or is canceled — the overall state reflects whichever cells/batches are least-finished.
- Do not disturb the project's already-Built cells or worker-attribution history when attaching or releasing a batch.
- Distinguish "attach as change order" (target project is BUILDING/PAUSED/DONE) from "merge into Draft project" (Story 003) — the branch is on the target project's state.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- The "removed cells → demolition orders" half of a change order — Story 009 (demolition) + Story 015 (removal-tool branching) own that path.
- The pure Draft-project grouping/merge (Story 003).

---

## QA Test Cases

**AC63 — change order attaches, not new project**
- Given: a DONE project P with all cells Built.
- When: a new commit 26-adjacent to P's cells is made.
- Then: the new cells attach to P as a pending "Änderungen geplant" batch (same project id, not a new project); P's Built cells are unchanged.
- Edge cases: same behavior when the target is BUILDING or PAUSED; a commit NOT 26-adjacent to any project starts a fresh Draft project instead.

**AC64 — per-batch release isolation**
- Given: a DONE project with a pending change-order batch.
- When: that batch alone is released.
- Then: only the batch's cells become BUILDING/job-eligible; already-Built cells are untouched.
- Edge cases: releasing the batch does not re-queue already-Built cells; project rollup returns toward DONE only after the batch reaches Built.

**Edge 15 — DONE leaves DONE on pending batch**
- Given: a DONE project.
- When: a change-order batch is drawn (not yet released).
- Then: rollup state is no longer fully DONE ("Änderungen geplant"); Built cells + attribution history untouched.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/building_system/change_orders_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (adjacency + reverse index), Story 004 (release), Story 002 (rollup).
- Unlocks: Building UI "Änderungen geplant" affordance; full change-order teardown path via Story 009/015.
