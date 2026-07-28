# Story 002: Project entity + blueprint-cell lifecycle rollup + persistence

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 702/702 suite green, parent-verified)
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: 2026-07-24

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-106`, `TR-building-system-108`, `TR-building-system-111`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary
**ADR Decision Summary**: A persistent Building-System-owned project entity aggregating blueprint/built cells with state ∈ {DRAFT, BUILDING, PAUSED, DONE}; state is a rollup over cells, not an independent flag; the entity persists until its cell set becomes empty.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (ADR-0016 knowledge risk LOW — data-model/state-machine over settled primitives)
**Engine Notes**: Use typed collections (`Array[...]`, `Dictionary[Vector3i, ...]`). No post-cutoff APIs required.

**Control Manifest Rules (this layer — Core)**:
- Required: project entity lifecycle is Building-System-owned, injected-tier (ADR-0001); DRAFT → BUILDING ⇄ PAUSED → DONE; job eligibility gated on BUILDING; built cells mutate ONLY via worker-executed jobs.
- Forbidden: never mutate built cells via undo or a direct edit; state colors never render on committed-block materials (build-state coloring lives on ghost/overlay/Projects Panel).
- Guardrail: one entity per active project + a cell→project index proportional to built/draft cell count — modest at settlement scale.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC60: GIVEN a project whose every cell has reached Built/Removed, WHEN checked, THEN the project entity still exists as DONE — never deleted on completion (Rule 14i). [TR-111]
- [ ] AC61: GIVEN a project whose last remaining cell is canceled or demolished/excavated away, WHEN that resolves, THEN the project entity itself is deleted — the one and only condition under which a project disappears (Rule 14i). [TR-111]
- [ ] Project state is a rollup over its cells: DRAFT (every cell Draft; no jobs; villagers ignore it) → BUILDING → PAUSED → DONE (every cell Built/Removed, no pending Draft batch). [TR-108]
- [ ] A Draft cell generates no job and is invisible to `claim_job`; job-eligibility exists only once the project (or a change-order batch) is BUILDING. [TR-106]
- [ ] Blueprint-cell micro-states: Planned (=Draft), UnderConstruction, Built (terminal for the cell), Canceled (terminal; never reachable from Built). [TR-108]

---

## Implementation Notes

*Derived from ADR-0016 Decision §1 + building-system Rules 14e/14i, TR-106/108/111:*

- `enum ProjectState { DRAFT, BUILDING, PAUSED, DONE }`. Model a project as `{ id: int, kind, state, cells: [...], restore_value: {...}, worker_ids: [...], pending orders }` (this story establishes id/state/cells and the rollup; `restore_value`/`worker_ids`/orders are extended by later stories).
- State is DERIVED from the cells' micro-states, never a flag set independently — recompute the rollup on any cell-state change. DONE requires every cell Built/Removed AND no pending Draft batch.
- Job-eligibility gate: expose the BUILDING-eligible cell queue (ordered by commit time — defines availability for display/tie-breaking, not forced servicing order). A Draft cell must be structurally invisible to `claim_job`.
- Persistence-until-empty: reaching DONE does NOT delete the entity (it is the future carrier for costs/scaffolding/templates). The entity is removed ONLY when its cell set becomes empty (every cell canceled, or demolished/excavated away).
- Injected-tier per ADR-0001: wiring in an explicit `setup()`, not `_ready()`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: 26-neighborhood grouping/merge and the reverse index that assigns cells to projects on commit.
- Story 004: the release transition (Draft → BUILDING).
- Story 006: pause/resume claim-revocation.
- The pre-slice blueprint commit pipeline (pick → preview → commit that produces the cells) — assumed available.

---

## QA Test Cases

**AC60 — DONE persists**
- Given: a project whose cells are all Built.
- When: the rollup is evaluated.
- Then: state == DONE AND the entity is still present (not deleted).
- Edge cases: a project with one Built cell and no pending batch is DONE, not deleted.

**AC61 — delete only when empty**
- Given: a project with exactly one remaining cell.
- When: that last cell is canceled (Draft) or demolished/excavated away (Built/Removed).
- Then: the project entity is removed.
- Edge cases: deleting a DONE project's last cell via demolition removes the entity; a project with any remaining cell of any micro-state is never deleted.

**Rollup + job-gating**
- Given: a project with all Draft cells.
- When: `claim_job` enumerates eligible work.
- Then: none of the project's cells are offered (Draft is invisible to claim_job) AND state == DRAFT.
- Edge cases: mixing one Built and one Draft cell yields a non-DONE rollup; a Canceled cell is never reachable from Built.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: neues-spiel/`tests/unit/building_system/project_entity_lifecycle_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: pre-slice Building System commit pipeline (produces blueprint cells) — external prerequisite. None within this story set.
- Unlocks: Story 003, 004, 006, 007, 009, 011 (all read/mutate the entity).
